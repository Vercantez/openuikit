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

`root` is one of corpus | checkouts | openuikit | generated (the --roots;
--generated is optional and holds files the app's own build generates, e.g.
NetNewsWire's SecretKey.swift from its .gyb). A target is a directory
(`path`) or an explicit file list (`files`, root-relative, mirrored into
Sources/<name>/ as per-file symlinks -- an Xcode app target spanning several
folders minus membership exceptions). `overlay` adds files into the target
({"Name.swift": {"root": ..., "path": ...}}), which turns the target into a
real directory of per-entry symlinks so the upstream tree is never written.
`c_settings` are raw SwiftPM cSettings; spec-level `platforms` replaces the
default [.macOS(.v13)]. Targets
are linked by default (a symlink under Sources/<name>) so the package builds
against the frozen corpus without a copy; --copy materialises the files and
writes PROVENANCE.json with SHA-256 per file, the way Eidolon's ingest did.

Exit 0 on success, 1 on a spec/path error.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys

ROOTS = ("corpus", "checkouts", "openuikit", "generated")


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
        deps.append(json.dumps(d))
    for p in t.get("openuikit", []):
        deps.append(f'.product(name: {json.dumps(p)}, package: "OpenUIKit")')
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
    if t.get("c_settings"):
        lines.append(f"            cSettings: [{', '.join(t['c_settings'])}],")
    lines[-1] = lines[-1].rstrip(",")
    lines.append("        ),")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("spec")
    ap.add_argument("--out", required=True)
    ap.add_argument("--corpus", required=True, help="frozen app checkout")
    ap.add_argument("--checkouts", required=True, help="SwiftPM checkouts dir resolved from the app's own Package.resolved")
    ap.add_argument("--generated", help="directory of files the app's own build generates (root 'generated')")
    ap.add_argument("--openuikit", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    ap.add_argument("--copy", action="store_true", help="copy sources (with PROVENANCE.json) instead of symlinking")
    args = ap.parse_args()

    spec = json.load(open(args.spec))
    roots = {"corpus": os.path.abspath(args.corpus), "checkouts": os.path.abspath(args.checkouts),
             "openuikit": os.path.abspath(args.openuikit)}
    if args.generated:
        roots["generated"] = os.path.abspath(args.generated)
    out = os.path.abspath(args.out)
    os.makedirs(os.path.join(out, "Sources"), exist_ok=True)

    targets = list(spec.get("shims", [])) + list(spec["targets"])
    names = set()
    provenance = {}
    for t in targets:
        if t["name"] in names:
            print(f"duplicate target {t['name']}", file=sys.stderr)
            return 1
        names.add(t["name"])
        if t.get("root", "corpus") not in ROOTS:
            print(f"{t['name']}: root must be one of {ROOTS}", file=sys.stderr)
            return 1
        root = t.get("root", "corpus")
        if root not in roots:
            print(f"{t['name']}: root {root} needs --{root}", file=sys.stderr)
            return 1
        base = roots[root]
        src = os.path.join(base, t["path"]) if "path" in t else None
        if src is not None and not os.path.isdir(src):
            print(f"{t['name']}: no such directory {src}", file=sys.stderr)
            return 1
        if src is None and not t.get("files"):
            print(f"{t['name']}: needs 'path' or 'files'", file=sys.stderr)
            return 1
        entries = {}  # dst-relative -> absolute source
        if src is None:
            for rel in t["files"]:
                entries[rel] = os.path.join(base, rel)
        elif t.get("overlay"):
            for e in sorted(os.listdir(src)):
                entries[e] = os.path.join(src, e)
        for name, o in (t.get("overlay") or {}).items():
            if o.get("root", "corpus") not in roots:
                print(f"{t['name']}: overlay root {o.get('root')} needs --{o.get('root')}", file=sys.stderr)
                return 1
            entries[name] = os.path.join(roots[o.get("root", "corpus")], o["path"])
        for rel, s_abs in entries.items():
            if not os.path.exists(s_abs):
                print(f"{t['name']}: no such file {s_abs}", file=sys.stderr)
                return 1
        dst = os.path.join(out, "Sources", t["name"])
        if os.path.islink(dst) or os.path.isfile(dst):
            os.unlink(dst)
        elif os.path.isdir(dst):
            shutil.rmtree(dst)
        if entries:
            for rel, s_abs in entries.items():
                d = os.path.join(dst, rel)
                os.makedirs(os.path.dirname(d), exist_ok=True)
                if args.copy:
                    (shutil.copytree if os.path.isdir(s_abs) else shutil.copy2)(s_abs, d)
                else:
                    os.symlink(s_abs, d)
            if args.copy:
                files = {}
                for dp, _, fns in os.walk(dst):
                    for fn in fns:
                        fp = os.path.join(dp, fn)
                        files[os.path.relpath(fp, dst)] = sha256(fp)
                provenance[t["name"]] = {"source": src or base, "files": files}
        elif args.copy:
            shutil.copytree(src, dst, symlinks=False)
            files = {}
            for dp, _, fns in os.walk(dst):
                for fn in fns:
                    p = os.path.join(dp, fn)
                    files[os.path.relpath(p, dst)] = sha256(p)
            provenance[t["name"]] = {"source": src, "files": files}
        else:
            os.symlink(src, dst)
        for d in t.get("deps", []):
            if d not in names:
                print(f"{t['name']}: dependency {d} is not declared before it", file=sys.stderr)
                return 1

    shim_names = {s["name"] for s in spec.get("shims", [])}
    products = ",\n".join(f'        .library(name: {json.dumps(t["name"])}, targets: [{json.dumps(t["name"])}])'
                          for t in targets)
    rendered = "\n".join(render_target(t, shim_names) for t in targets)
    manifest = f"""// swift-tools-version:6.0
// Generated by Tools/ingest/spm_app_chain.py — do not edit by hand.
// Spec: {os.path.relpath(os.path.abspath(args.spec), roots['openuikit'])}
// Targets point at unchanged upstream sources ({'copied' if args.copy else 'symlinked'}).
import PackageDescription

let package = Package(
    name: {json.dumps(spec['name'])},
    defaultLocalization: {json.dumps(spec.get('default_localization', 'en'))},
    platforms: [{', '.join(spec.get('platforms', ['.macOS(.v13)']))}],
    products: [
{products}
    ],
    dependencies: [
        .package(name: "OpenUIKit", path: {json.dumps(roots["openuikit"])}),
    ],
    targets: [
{rendered}
    ]
)
"""
    with open(os.path.join(out, "Package.swift"), "w") as f:
        f.write(manifest)
    if args.copy:
        with open(os.path.join(out, "PROVENANCE.json"), "w") as f:
            json.dump(provenance, f, indent=1, sort_keys=True)
    print(f"wrote {out}/Package.swift ({len(targets)} targets, {'copied' if args.copy else 'linked'})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
