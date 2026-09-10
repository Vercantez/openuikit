#!/usr/bin/env python3
"""Per-app TARGET SCOPE for the ladder census -- one Xcode target, not the repo.

WHY. `ladder_census.py` walks the WHOLE repository of every corpus app. That is
the right denominator for a single-platform app and the wrong one for a repo
that ships a Mac app and an iOS app from one tree: NetNewsWire's top BLOCKING
row on 2026-09-16 was `NSToolbarItem` (48 uses), every one of them in `Mac/`
or inside `#if os(macOS)` in a shared package. A whole-repo walk cannot tell
Catalyst/AppKit demand from phone demand. This script produces the file list
the iOS target actually compiles, and `ladder_census.py --target-scope=FILE`
restricts its per-file walks to that list for the apps named in it.

WHAT THE SCOPE IS, stated so it can be argued with:

  1. The named PBXNativeTarget's PBXSourcesBuildPhase files plus its
     PBXFileSystemSynchronizedRootGroup members minus that target's
     membership exceptions -- read by the port's own project parser
     (uikit/Tools/ingest/xcodeproj_to_package.py: ProjectGraph.target_inputs).
     Test targets, other app targets and app extensions are NOT in scope;
     the extension targets' counts are recorded in `siblings` for the record.
  2. Every LOCAL Swift package the target depends on, TRANSITIVELY through
     `.package(path:)` edges, contributes its `Sources/` tree. Products are
     resolved to packages by scanning the repo's Package.swift files for the
     product name (Xcode 16 omits `package =` on unique product names and
     NetNewsWire's Modules/ is a synchronized folder, not an
     XCLocalSwiftPackageReference, so the ingest parser's local map is empty).
     Package `Tests/` are not sources. Remote packages are listed, not walked
     (they are not in the corpus clone).
  3. WHOLE-FILE PLATFORM GUARD. A file whose first code line is
     `#if os(macOS)` / `#if os(OSX)` / `#if canImport(AppKit)` /
     `#if targetEnvironment(macCatalyst)` and whose last code line is the
     matching `#endif`, with no `#else`/`#elseif` at depth 0, does not
     compile on iOS and is excluded. Recorded per file with the guard text.
     BLINDNESS: a PARTIAL guard inside a file (`#if os(macOS) ... #else ...
     #endif` around one method) is NOT stripped -- the census counts the
     whole file, same as before. The residual is measured separately by
     `partial_guard_uses` below so it is a number, not a footnote.

  ./target_scope.py <app-root> <xcodeproj> <target-name> <out.json> \\
        [--app-name NAME] [--merge EXISTING.json]

  --app-name  key under "apps" (default: the corpus directory name)
  --merge     start from an existing scope file so several apps share one

Output shape, honoured by ladder_census.py:

  {"apps": {NAME: {"files": [relpaths...], ...provenance...}}}

Paths are POSIX, relative to the app root, and the census matches them
exactly against `os.path.relpath(path, root)`.
"""
import json, os, posixpath, re, sys
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
INGEST = HERE.parent.parent / "uikit" / "Tools" / "ingest"
sys.path.insert(0, str(INGEST))
from xcodeproj_to_package import ProjectGraph  # noqa: E402

SOURCE_EXT = {".swift", ".m", ".mm", ".h", ".c", ".cc", ".cpp"}
PKG_SKIP = {".git", ".build", "Tests", "TestsSupport", "Pods", "Carthage", "DerivedData"}

MAC_GUARD = re.compile(
    r'^#if\s+(?:os\(macOS\)|os\(OSX\)|canImport\(AppKit\)|targetEnvironment\(macCatalyst\))\s*$')
LIBRARY_RE = re.compile(r'\.library\s*\(\s*name\s*:\s*"([^"]+)"')
LOCAL_DEP_RE = re.compile(r'\.package\s*\(\s*(?:name\s*:\s*"[^"]*"\s*,\s*)?path\s*:\s*"([^"]+)"')
REMOTE_DEP_RE = re.compile(r'\.package\s*\(\s*(?:name\s*:\s*"[^"]*"\s*,\s*)?url\s*:\s*"([^"]+)"')
PKG_NAME_RE = re.compile(r'Package\s*\(\s*name\s*:\s*"([^"]+)"')


def code_lines(text):
    """Source lines with line comments, block comments and blanks removed."""
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    out = []
    for line in text.splitlines():
        line = re.sub(r'//.*$', '', line).strip()
        if line:
            out.append(line)
    return out


def whole_file_mac_guard(text):
    """Return the guard line if the WHOLE file sits under one macOS-only #if."""
    lines = code_lines(text)
    if len(lines) < 2 or not MAC_GUARD.match(lines[0]) or lines[-1] != "#endif":
        return None
    depth = 0
    for i, line in enumerate(lines):
        if line.startswith("#if"):
            depth += 1
        elif line.startswith("#endif"):
            depth -= 1
            if depth == 0 and i != len(lines) - 1:
                return None          # outer block closes before the end
        elif depth == 1 and line.startswith(("#else", "#elseif")):
            return None              # the file has an iOS branch
    return lines[0] if depth == 0 else None


def partial_guard_regions(text):
    """(start, end) character spans of `#if <mac>` ... [#else|#endif] blocks.

    Only the macOS branch of a partial guard is returned, so a caller can ask
    how many of a symbol's uses would vanish under a region-aware census.
    """
    spans, stack = [], []
    for m in re.finditer(r'^[ \t]*#(if|elseif|else|endif)\b([^\n]*)$', text, re.M):
        kw, rest = m.group(1), m.group(2)
        if kw == "if":
            stack.append([bool(MAC_GUARD.match("#if" + rest)), m.start()])
        elif not stack:
            continue
        elif kw in ("else", "elseif"):
            if stack[-1][0]:
                spans.append((stack[-1][1], m.start()))
                stack[-1][0] = False
        else:  # endif
            mac, start = stack.pop()
            if mac:
                spans.append((start, m.end()))
    return spans


def read(path):
    try:
        return open(path, encoding="utf-8", errors="ignore").read()
    except OSError:
        return ""


def find_packages(root):
    """{product-or-package-name: package relpath} over every Package.swift."""
    by_name, meta = {}, {}
    for dp, dn, fn in os.walk(root):
        dn[:] = [d for d in dn if d not in PKG_SKIP]
        if "Package.swift" in fn:
            rel = os.path.relpath(dp, root).replace(os.sep, "/")
            text = read(os.path.join(dp, "Package.swift"))
            name = (PKG_NAME_RE.search(text) or [None, posixpath.basename(rel)])[1]
            products = LIBRARY_RE.findall(text)
            meta[rel] = {"name": name, "products": products,
                         "local_deps": [posixpath.normpath(posixpath.join(rel, d))
                                        for d in LOCAL_DEP_RE.findall(text)],
                         "remote_deps": REMOTE_DEP_RE.findall(text)}
            for key in [name, posixpath.basename(rel)] + products:
                by_name.setdefault(key, rel)
            dn[:] = []  # a package's subtree is its own; do not nest
    return by_name, meta


def package_sources(root, rel):
    src = os.path.join(root, rel, "Sources")
    out = []
    for dp, dn, fn in os.walk(src):
        dn[:] = [d for d in dn if d not in PKG_SKIP]
        for f in fn:
            if os.path.splitext(f)[1] in SOURCE_EXT:
                out.append(os.path.relpath(os.path.join(dp, f), root).replace(os.sep, "/"))
    return sorted(out)


def build_scope(root, xcodeproj, target_name):
    root = os.path.abspath(root)
    g = ProjectGraph(Path(xcodeproj))
    tid, target = g.pick_app_target(target_name)
    inputs = g.target_inputs(tid, target)
    target_files = sorted({s["path"] for s in inputs["sources"]
                           if s.get("path") and os.path.splitext(s["path"])[1] in SOURCE_EXT})
    by_name, meta = find_packages(root)

    # closure over local packages, starting from the target's product deps
    products = g.package_products(target)
    remote = [p for p in products if p.get("origin") == "remote"]
    unresolved, seeds = [], []
    for p in products:
        if p.get("origin") == "remote":
            continue
        rel = p.get("relative_path") or by_name.get(p["name"])
        (seeds.append(rel) if rel else unresolved.append(p["name"]))
    closure, todo = [], list(dict.fromkeys(seeds))
    while todo:
        rel = todo.pop(0)
        if rel in closure or rel not in meta:
            continue
        closure.append(rel)
        todo.extend(d for d in meta[rel]["local_deps"] if d not in closure)
    closure.sort()

    files, excluded, per_pkg = list(target_files), [], {}
    for rel in closure:
        srcs = package_sources(root, rel)
        per_pkg[rel] = len(srcs)
        files.extend(srcs)
    files = sorted(set(files))
    kept = []
    for f in files:
        guard = whole_file_mac_guard(read(os.path.join(root, f))) if f.endswith(".swift") else None
        (excluded.append({"file": f, "guard": guard}) if guard else kept.append(f))

    # siblings: every other native target's own source count, for the record
    siblings = []
    for stid, st in g.native_targets():
        if stid == tid:
            continue
        n = len({s["path"] for s in g.target_inputs(stid, st)["sources"]
                 if s.get("path") and s["path"].endswith(".swift")})
        siblings.append({"target": st.get("name"), "product_type": st.get("productType"),
                         "swift_files": n})

    return {
        "target": target.get("name"), "target_id": tid,
        "product_type": target.get("productType"),
        "xcodeproj": os.path.relpath(os.path.abspath(xcodeproj), root),
        "rule": ("PBXSourcesBuildPhase + synchronized groups minus membership "
                 "exceptions; + Sources/ of the transitive local-package closure; "
                 "- whole-file macOS guards (target_scope.py docstring)"),
        "target_sources": len(target_files),
        "target_swift": sum(1 for f in target_files if f.endswith(".swift")),
        "local_packages": closure,
        "package_sources": per_pkg,
        "remote_packages": sorted({p["name"] for p in remote}
                                  | {d for r in closure for d in meta[r]["remote_deps"]}),
        "unresolved_products": unresolved,
        "excluded_whole_file_guard": excluded,
        "siblings": siblings,
        "files": kept,
        "swift_files": sum(1 for f in kept if f.endswith(".swift")),
    }


def main():
    args = sys.argv[1:]
    app_name = merge = None
    if "--app-name" in args:
        i = args.index("--app-name"); app_name = args[i + 1]; del args[i:i + 2]
    if "--merge" in args:
        i = args.index("--merge"); merge = args[i + 1]; del args[i:i + 2]
    if len(args) != 4:
        sys.exit(__doc__)
    root, xcodeproj, target_name, out = args
    app_name = app_name or os.path.basename(os.path.abspath(root))
    doc = json.load(open(merge)) if merge else {"apps": {}}
    doc["_note"] = ("TARGET SCOPE for ladder_census.py --target-scope. Paths are "
                    "relative to the corpus app root. See target_scope.py.")
    doc["apps"][app_name] = build_scope(root, xcodeproj, target_name)
    json.dump(doc, open(out, "w"), indent=1)
    s = doc["apps"][app_name]
    print(f"{app_name}: target {s['target']} -> {s['target_swift']} target swift files, "
          f"{len(s['local_packages'])} local packages "
          f"({sum(s['package_sources'].values())} package sources), "
          f"{len(s['excluded_whole_file_guard'])} excluded by whole-file macOS guard, "
          f"scope = {s['swift_files']} swift / {len(s['files'])} source files",
          file=sys.stderr)
    if s["unresolved_products"]:
        print(f"  UNRESOLVED products (not walked): {s['unresolved_products']}", file=sys.stderr)


if __name__ == "__main__":
    main()
