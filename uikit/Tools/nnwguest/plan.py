#!/usr/bin/env python3
"""MEASUREMENT ONLY. Emit the real (no allow-errors) guest build of
NetNewsWire's chain as bash for the diagnostic build_full copy:

  * C / Objective-C targets: every .c / .m compiled with compile_app_objc
    (ARC, modules, the guest's Objective-C Foundation), plus a Clang module map
    over the public headers for Swift importers;
  * Swift targets: compile_app_module with the target's settings, the guest's
    Objective-C bridge flags, and the Clang maps of the C/ObjC targets;
    a SwiftPM resource target gets Xcode's Bundle.module accessor
    (full/xcodeplan/swiftpm_resource_accessor.py) and its resource directory is
    copied to <Package>_<Target>.bundle;
  * a module that fails is compiled again with allow-errors (recorded as
    BLOCKED) so the modules after it still have an interface to import.

Every result is one `NNWG <target> <status> errors=<n>` line.
"""
import json
import os
import sys

spec_path, pkg, out = sys.argv[1], sys.argv[2], sys.argv[3]
spec = json.load(open(spec_path))
maps = os.path.join(out, "maps")
gen = os.path.join(out, "gen")
os.makedirs(maps, exist_ok=True)
os.makedirs(gen, exist_ok=True)


def q(a):
    return "'" + a.replace("'", "'\\''") + "'"


lines = []
clang_flags = []
for t in spec["targets"]:
    name = t["name"]
    src = os.path.join(pkg, "Sources", name)
    files = []
    for root, dirs, fs in os.walk(src, followlinks=True):
        for f in fs:
            files.append(os.path.join(root, f))
    swift = sorted(f for f in files if f.endswith(".swift"))
    if not swift:
        inc = os.path.join(src, "include")
        headers = sorted(f for f in files if f.endswith(".h") and f.startswith(inc + "/"))
        if not headers:
            headers = sorted(f for f in files if f.endswith(".h"))
        d = os.path.join(maps, name)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "module.modulemap"), "w") as m:
            m.write(f"module {name} {{\n")
            for h in headers:
                m.write(f'    header "{h}"\n')
            m.write("    export *\n}\n")
        incdirs = [inc] if os.path.isdir(inc) else []
        incdirs.append(src)
        sources = sorted(f for f in files if f.endswith(".m") or f.endswith(".c"))
        cflags = []
        for i in incdirs:
            cflags += ["-I", i]
        lines.append(f"nnwg_clang {q(name)} {len(sources)} " + " ".join(q(a) for a in cflags)
                     + " -- " + " ".join(q(s) for s in sources))
        clang_flags += ["-Xcc", f"-fmodule-map-file={d}/module.modulemap"]
        for i in incdirs:
            clang_flags += ["-Xcc", f"-I{i}"]
        continue
    flags = ["-swift-version", str(t.get("swift_language_mode", "6")).split(".")[0]]
    for s in t.get("swift_settings", []) or []:
        if s.startswith(".enableUpcomingFeature("):
            flags += ["-enable-upcoming-feature", s.split('"')[1]]
        elif s.startswith(".define("):
            flags += ["-D", s.split('"')[1]]
    flags += t.get("unsafe_flags", []) or []
    extra = []
    for r in t.get("resources", []) or []:
        parts = t["path"].split("/")
        package = parts[parts.index("Modules") + 1] if "Modules" in parts else name
        stem = f"{package}_{name}".replace("-", "_")
        acc = os.path.join(gen, name, "resource_bundle_accessor.swift")
        os.makedirs(os.path.dirname(acc), exist_ok=True)
        lines.append(f"nnwg_bundle {q(stem)} {q(acc)} {q(os.path.join(src, r))}")
        extra.append(acc)
    lines.append(f"nnwg_swift {q(name)} " + " ".join(q(a) for a in flags + clang_flags + swift + extra))
print("\n".join(lines))
