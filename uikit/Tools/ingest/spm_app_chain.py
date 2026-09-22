#!/usr/bin/env python3
"""Emit a SwiftPM census package for an app that lives in LOCAL Swift packages.

`xcodeproj_to_package.py` reads the PBX application target. ios-oss keeps two
Swift files in that target; the other 1,800 live in local packages
(Kickstarter-Framework -> Library -> KsApi -> GraphAPI, KDS, ServerDrivenUI,
Experimentation) whose manifests pull iOS-only binary SDKs. This tool takes a
chain spec (JSON, one entry per module in dependency order), and writes a
package whose targets point at the UNCHANGED upstream source directories and
depend on OpenUIKit's products instead of the Apple SDK. Nothing under the
corpus or the checkouts is written.

Spec shape (see docs/agent_reports/ios-oss-launch-chain.json):

    {
      "name": "KickstarterChain",
      "swift_language_mode": "5",
      "targets": [
        {"name": "Prelude", "root": "checkouts",
         "path": "Kickstarter-Prelude/Sources/Prelude",
         "deps": [], "openuikit": [], "resources": [], "exclude": []},
        ...
      ],
      "shims": [{"name": "Statsig", "root": "openuikit",
                 "path": "Sources/KickstarterServiceShims/Statsig"}]
    }

`root` is one of corpus | checkouts | openuikit (the three --roots). Targets
are linked by default (a symlink under Sources/<name>) so the package builds
against the frozen corpus without a copy; --copy materialises the files and
writes PROVENANCE.json with SHA-256 per file, the way Eidolon's ingest did.

A target may carry `"generated": [{"file": "Secrets.swift", "root": "corpus",
"path": "Configs/Secrets.swift.example", "replace": [["a", "b"]]}]` for a file
the upstream build GENERATES into the module (ios-oss's Makefile `secrets`
target copies the public Secrets example into KsApi). Such a target is
materialised as a real directory of per-entry symlinks plus the generated
file, so the upstream tree is still not written; every generated file is
listed in GENERATED.json with its source, substitutions and SHA-256. A
substitution that does not match, or a generated name that already exists
upstream, is a spec error.

`"packages": [{"name": N, "root": R, "path": P}]` adds local packages to the
manifest; a dependency written `{"product": X, "package": N, "alias": M}`
links product X from package N and, with "alias", imports it as module M
(SwiftPM module aliasing).

`"openuikit_manifest_filter": [[old, new], ...]` depends on a FILTERED view
of the OpenUIKit package instead of the package itself: a directory
(OpenUIKitFiltered/) of per-entry symlinks to the OpenUIKit root plus a copy
of its Package.swift with the substitutions applied (each must match; all are
recorded in GENERATED.json). ios-oss needs it because SwiftPM target names
are unique across a package graph and OpenUIKit's manifest declares Eidolon's
fail-closed `Stripe` shim, while Kickstarter needs its own `Stripe` module;
module aliasing does not avoid the collision (the aliased module is checked
under its new name). OpenUIKit's own manifest is not changed.

Exit 0 on success, 1 on a spec/path error.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys

ROOTS = ("corpus", "checkouts", "openuikit")
# Port products whose Apple module the curated iOS SDK keeps
# (Tools/ingest/ios_target_sdk.py): linked off iOS only, so the iOS triple
# sees Apple's declarations. Same set as xcodeproj_to_package.py.
IOS_SDK_SUPPLIED_PRODUCTS = {"MobileCoreServices"}


def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def swift_string_list(items: list[str]) -> str:
    return ", ".join(json.dumps(i) for i in items)


def render_target(t: dict, shims: set[str]) -> str:
    deps = []
    for d in t.get("deps", []):
        if isinstance(d, dict):
            # {"product": P, "package": K, "alias": M}: a product of an extra
            # local package, optionally imported under module name M.
            alias = ""
            if d.get("alias"):
                alias = f", moduleAliases: [{json.dumps(d['product'])}: {json.dumps(d['alias'])}]"
            deps.append(f'.product(name: {json.dumps(d["product"])}, package: {json.dumps(d["package"])}{alias})')
        else:
            deps.append(json.dumps(d))
    for p in t.get("openuikit", []):
        condition = (", condition: .when(platforms: [.macOS, .linux])"
                     if p in IOS_SDK_SUPPLIED_PRODUCTS else "")
        deps.append(f'.product(name: {json.dumps(p)}, package: "OpenUIKit"{condition})')
    lines = [
        "        .target(",
        f"            name: {json.dumps(t['name'])},",
        f"            dependencies: [{', '.join(deps)}],",
        f"            path: {json.dumps('Sources/' + t['name'])},",
    ]
    if t.get("exclude"):
        lines.append(f"            exclude: [{swift_string_list(t['exclude'])}],")
    if t.get("resources"):
        res = ", ".join(f".process({json.dumps(r)})" for r in t["resources"])
        lines.append(f"            resources: [{res}],")
    settings = list(t.get("swift_settings", []))
    if t.get("swift_language_mode"):
        settings.append(f".swiftLanguageMode(.v{t['swift_language_mode']})")
    for d in t.get("defines", []):
        settings.append(f".define({json.dumps(d)})")
    for f in t.get("unsafe_flags", []):
        settings.append(f".unsafeFlags([{json.dumps(f)}])")
    if settings:
        lines.append(f"            swiftSettings: [{', '.join(settings)}],")
    lines[-1] = lines[-1].rstrip(",")
    lines.append("        ),")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("spec")
    ap.add_argument("--out", required=True)
    ap.add_argument("--corpus", required=True, help="frozen app checkout")
    ap.add_argument("--checkouts", required=True, help="SwiftPM checkouts dir resolved from the app's own Package.resolved")
    ap.add_argument("--openuikit", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    ap.add_argument("--copy", action="store_true", help="copy sources (with PROVENANCE.json) instead of symlinking")
    args = ap.parse_args()

    spec = json.load(open(args.spec))
    roots = {"corpus": os.path.abspath(args.corpus), "checkouts": os.path.abspath(args.checkouts),
             "openuikit": os.path.abspath(args.openuikit)}
    out = os.path.abspath(args.out)
    os.makedirs(os.path.join(out, "Sources"), exist_ok=True)

    targets = list(spec.get("shims", [])) + list(spec["targets"])
    names = set()
    provenance = {}
    generated: dict[str, list] = {}
    for t in targets:
        if t["name"] in names:
            print(f"duplicate target {t['name']}", file=sys.stderr)
            return 1
        names.add(t["name"])
        if t.get("root", "corpus") not in ROOTS:
            print(f"{t['name']}: root must be one of {ROOTS}", file=sys.stderr)
            return 1
        src = os.path.join(roots[t.get("root", "corpus")], t["path"])
        if not os.path.isdir(src):
            print(f"{t['name']}: no such directory {src}", file=sys.stderr)
            return 1
        dst = os.path.join(out, "Sources", t["name"])
        if os.path.islink(dst) or os.path.isfile(dst):
            os.unlink(dst)
        elif os.path.isdir(dst):
            shutil.rmtree(dst)
        if args.copy:
            shutil.copytree(src, dst, symlinks=False)
            files = {}
            for dp, _, fns in os.walk(dst):
                for fn in fns:
                    p = os.path.join(dp, fn)
                    files[os.path.relpath(p, dst)] = sha256(p)
            provenance[t["name"]] = {"source": src, "files": files}
        elif t.get("generated"):
            os.makedirs(dst)
            for entry in sorted(os.listdir(src)):
                os.symlink(os.path.join(src, entry), os.path.join(dst, entry))
        else:
            os.symlink(src, dst)
        for g in t.get("generated", []):
            gsrc = os.path.join(roots[g.get("root", "corpus")], g["path"])
            if not os.path.isfile(gsrc):
                print(f"{t['name']}: no such generator source {gsrc}", file=sys.stderr)
                return 1
            gdst = os.path.join(dst, g["file"])
            if os.path.lexists(gdst):
                print(f"{t['name']}: generated file {g['file']} already exists upstream", file=sys.stderr)
                return 1
            text = open(gsrc).read()
            for old, new in g.get("replace", []):
                if old not in text:
                    print(f"{t['name']}: substitution {old!r} not found in {gsrc}", file=sys.stderr)
                    return 1
                text = text.replace(old, new)
            with open(gdst, "w") as f:
                f.write(text)
            generated.setdefault(t["name"], []).append(
                {"file": g["file"], "source": gsrc, "replace": g.get("replace", []), "sha256": sha256(gdst)})
        for d in t.get("deps", []):
            if isinstance(d, dict):
                if d.get("package") not in {pk["name"] for pk in spec.get("packages", [])}:
                    print(f"{t['name']}: package {d.get('package')} is not declared in 'packages'", file=sys.stderr)
                    return 1
                continue
            if d not in names:
                print(f"{t['name']}: dependency {d} is not declared before it", file=sys.stderr)
                return 1

    shim_names = {s["name"] for s in spec.get("shims", [])}
    products = ",\n".join(f'        .library(name: {json.dumps(t["name"])}, targets: [{json.dumps(t["name"])}])'
                          for t in targets)
    openuikit_path = roots["openuikit"]
    if spec.get("openuikit_manifest_filter"):
        filtered = os.path.join(out, "OpenUIKitFiltered")
        if os.path.isdir(filtered):
            shutil.rmtree(filtered)
        os.makedirs(filtered)
        for entry in sorted(os.listdir(roots["openuikit"])):
            if entry in ("Package.swift", "Package.resolved", ".build", ".swiftpm"):
                continue
            os.symlink(os.path.join(roots["openuikit"], entry), os.path.join(filtered, entry))
        manifest_src = os.path.join(roots["openuikit"], "Package.swift")
        text = open(manifest_src).read()
        for old, new in spec["openuikit_manifest_filter"]:
            if old not in text:
                print(f"openuikit_manifest_filter: {old!r} not found in {manifest_src}", file=sys.stderr)
                return 1
            text = text.replace(old, new)
        with open(os.path.join(filtered, "Package.swift"), "w") as f:
            f.write(text)
        generated["__openuikit_manifest__"] = [{"file": "OpenUIKitFiltered/Package.swift", "source": manifest_src,
                                               "replace": spec["openuikit_manifest_filter"],
                                               "sha256": sha256(os.path.join(filtered, "Package.swift"))}]
        openuikit_path = filtered
    rendered = "\n".join(render_target(t, shim_names) for t in targets)
    extra_packages = "".join(
        f'        .package(name: {json.dumps(pk["name"])}, path: {json.dumps(os.path.join(roots[pk.get("root", "openuikit")], pk["path"]))}),\n'
        for pk in spec.get("packages", []))
    manifest = f"""// swift-tools-version:6.0
// Generated by Tools/ingest/spm_app_chain.py — do not edit by hand.
// Spec: {os.path.relpath(os.path.abspath(args.spec), roots['openuikit'])}
// Targets point at unchanged upstream sources ({'copied' if args.copy else 'symlinked'}).
import PackageDescription

let package = Package(
    name: {json.dumps(spec['name'])},
    defaultLocalization: {json.dumps(spec.get('default_localization', 'en'))},
    platforms: [.macOS({json.dumps(spec.get("macos_deployment", "13.0"))}), .iOS("26.0")],
    products: [
{products}
    ],
    dependencies: [
        .package(name: "OpenUIKit", path: {json.dumps(openuikit_path)}),
{extra_packages}    ],
    targets: [
{rendered}
    ]
)
"""
    with open(os.path.join(out, "Package.swift"), "w") as f:
        f.write(manifest)
    if generated:
        with open(os.path.join(out, "GENERATED.json"), "w") as f:
            json.dump(generated, f, indent=1, sort_keys=True)
    if args.copy:
        with open(os.path.join(out, "PROVENANCE.json"), "w") as f:
            json.dump(provenance, f, indent=1, sort_keys=True)
    print(f"wrote {out}/Package.swift ({len(targets)} targets, {'copied' if args.copy else 'linked'})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
