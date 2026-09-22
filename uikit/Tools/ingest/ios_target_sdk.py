#!/usr/bin/env python3
"""Curated iOS SDK for route (b): Apple's SDK with Apple's UI stack removed.

Route (b) compiles unmodified app source with Xcode's toolchain. Building for
the macOS triple takes every dependency's `os(macOS)` / `canImport(AppKit)`
branch (docs/agent_reports/ios-target-route.md). Building for
`arm64-apple-ios26.1-simulator` against the stock iPhoneSimulator SDK takes
the iOS branches, and `import UIKit` already resolves to OpenUIKit's `UIKit`
module (SwiftPM's -I module search precedes the SDK). But Apple's UIKit still
reaches the module graph through any SDK framework that imports it
(MEASURED: `import AVKit` / `import MessageUI` then
`let c: UIViewController = AVPlayerViewController()` fails with "cannot
convert value of type 'AVPlayerViewController' to specified type
'UIViewController'": AVKit's superclass is Apple's UIViewController, a
second class universe).

This tool builds a symlink farm of the SDK that omits UIKit, SwiftUI and
every framework or Swift module whose public headers or Swift interfaces
import them, transitively. What remains (Foundation, CoreGraphics,
QuartzCore, AVFAudio, ...) is Apple's iOS declarations; what is removed is
either supplied by the port (UIKit, SwiftUI, WebKit, MessageUI, ...) or
becomes an explicit "no such module" wall instead of a silent second UIKit.

    python3 ios_target_sdk.py --out DIR [--sdk PATH]      # build, print DIR
    python3 ios_target_sdk.py --out DIR --report          # removed modules
    python3 ios_target_sdk.py --out DIR --build PKG [--target T]
                                  # swift build PKG for the iOS triple

The SDK itself is never modified.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

# The UI stack OpenUIKit replaces. AppKit is not in an iOS SDK; listed so a
# macCatalyst/macOS SDK passed by mistake still cannot leak it.
ROOT_MODULES = ("UIKit", "SwiftUI", "AppKit")
TRIPLE_VARIANT = "arm64-apple-ios-simulator"
DEFAULT_TRIPLE = "arm64-apple-ios26.1-simulator"
FORMAT_VERSION = 1

_HEADER_IMPORT = re.compile(r"^\s*#\s*(?:import|include)\s*<([A-Za-z_][A-Za-z0-9_]*)/", re.M)
_AT_IMPORT = re.compile(r"^\s*@import\s+([A-Za-z_][A-Za-z0-9_]*)", re.M)
_SWIFT_IMPORT = re.compile(
    r"^\s*(?:@_exported\s+|@_implementationOnly\s+|@preconcurrency\s+|public\s+|internal\s+|private\s+)*"
    r"import\s+(?:(?:struct|class|enum|protocol|typealias|func|var|let)\s+)?"
    r"([A-Za-z_][A-Za-z0-9_]*)",
    re.M,
)


def default_sdk() -> Path:
    out = subprocess.run(
        ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"],
        check=True, capture_output=True, text=True,
    ).stdout.strip()
    return Path(out)


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def header_imports(text: str) -> set[str]:
    return set(_HEADER_IMPORT.findall(text)) | set(_AT_IMPORT.findall(text))


def swift_imports(text: str) -> set[str]:
    return set(_SWIFT_IMPORT.findall(text))


def _interfaces(module_dir: Path) -> list[Path]:
    """The iOS-simulator .swiftinterface files of one .swiftmodule dir."""
    if not module_dir.is_dir():
        return []
    return sorted(p for p in module_dir.glob(f"{TRIPLE_VARIANT}*.swiftinterface"))


def framework_imports(framework: Path) -> set[str]:
    deps: set[str] = set()
    for sub in ("Headers", "PrivateHeaders"):
        d = framework / sub
        if d.is_dir():
            for h in d.rglob("*.h"):
                deps |= header_imports(_read(h))
    modules = framework / "Modules"
    if modules.is_dir():
        for m in modules.glob("*.swiftmodule"):
            for i in _interfaces(m):
                deps |= swift_imports(_read(i))
    return deps


def scan_sdk(sdk: Path) -> dict[str, dict]:
    """module name -> {"kind", "path" (SDK-relative), "deps"}."""
    graph: dict[str, dict] = {}
    fw_root = sdk / "System/Library/Frameworks"
    for fw in sorted(fw_root.glob("*.framework")):
        name = fw.name[: -len(".framework")]
        graph[name] = {
            "kind": "framework",
            "path": str(fw.relative_to(sdk)),
            "deps": sorted(framework_imports(fw) - {name}),
        }
    swift_root = sdk / "usr/lib/swift"
    for m in sorted(swift_root.glob("*.swiftmodule")):
        name = m.name[: -len(".swiftmodule")]
        deps: set[str] = set()
        for i in _interfaces(m):
            deps |= swift_imports(_read(i))
        entry = graph.get(name)
        if entry is None:
            graph[name] = {"kind": "swiftmodule", "path": str(m.relative_to(sdk)),
                           "deps": sorted(deps - {name})}
        else:
            # A Swift overlay of a framework shares the framework's name;
            # removing the name removes both.
            entry.setdefault("overlay", str(m.relative_to(sdk)))
            entry["deps"] = sorted((set(entry["deps"]) | deps) - {name})
    return graph


def removal_closure(graph: dict[str, dict], roots=ROOT_MODULES) -> dict[str, str]:
    """name -> reason, for every module that imports a root, transitively."""
    removed: dict[str, str] = {r: "port-replaced UI stack" for r in roots if r in graph}
    for r in roots:
        removed.setdefault(r, "port-replaced UI stack")
    changed = True
    while changed:
        changed = False
        for name in sorted(graph):
            if name in removed:
                continue
            hit = sorted(d for d in graph[name]["deps"] if d in removed)
            if hit:
                # Name a root when the module imports one directly.
                direct = [d for d in hit if d in roots]
                removed[name] = "imports " + (direct or hit)[0]
                changed = True
    return removed


def _link(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    os.symlink(src, dst)


def _farm(src_dir: Path, dst_dir: Path, skip: set[str], descend: dict[str, callable]) -> None:
    dst_dir.mkdir(parents=True, exist_ok=True)
    for entry in sorted(os.listdir(src_dir)):
        if entry in skip:
            continue
        if entry in descend:
            descend[entry](src_dir / entry, dst_dir / entry)
        else:
            _link(src_dir / entry, dst_dir / entry)


def sdk_identity(sdk: Path) -> str:
    settings = _read(sdk / "SDKSettings.json")
    return hashlib.sha256((str(sdk.resolve()) + "\n" + settings).encode()).hexdigest()[:16]


def curate(sdk: Path, out: Path, roots=ROOT_MODULES) -> dict:
    """Build (or reuse) the curated SDK at out/<name of sdk>; return manifest."""
    name = sdk.name  # keep the versioned spelling (iPhoneSimulator26.1.sdk)
    sdk = sdk.resolve()
    graph = scan_sdk(sdk)
    removed = removal_closure(graph, roots)
    fw_skip = {f"{n}.framework" for n in removed}
    swift_skip = {f"{n}.swiftmodule" for n in removed}
    identity = sdk_identity(sdk)
    root = out / name
    manifest_path = out / "ios-target-sdk.json"
    if manifest_path.is_file() and root.is_dir():
        old = json.loads(manifest_path.read_text())
        if old.get("identity") == identity and old.get("removed") == removed \
                and old.get("format") == FORMAT_VERSION:
            return old
    if root.exists():
        _rmtree_links(root)
    frameworks = lambda s, d: _farm(s, d, fw_skip, {})
    swift = lambda s, d: _farm(s, d, swift_skip, {})
    _farm(sdk, root, set(), {
        "System": lambda s, d: _farm(s, d, set(), {
            "Library": lambda s2, d2: _farm(s2, d2, set(), {"Frameworks": frameworks}),
        }),
        "usr": lambda s, d: _farm(s, d, set(), {
            "lib": lambda s2, d2: _farm(s2, d2, set(), {"swift": swift}),
        }),
    })
    manifest = {
        "format": FORMAT_VERSION,
        "sdk": str(sdk),
        "curated_sdk": str(root),
        "identity": identity,
        "triple": DEFAULT_TRIPLE,
        "roots": list(roots),
        "removed": removed,
        "kept_frameworks": sorted(n for n, e in graph.items()
                                  if e["kind"] == "framework" and n not in removed),
    }
    manifest_path.write_text(json.dumps(manifest, indent=1, sort_keys=True) + "\n")
    return manifest


def _rmtree_links(root: Path) -> None:
    """Remove a symlink farm without following links into the real SDK."""
    for dirpath, dirnames, filenames in os.walk(root, topdown=False, followlinks=False):
        for f in filenames:
            os.unlink(os.path.join(dirpath, f))
        for d in dirnames:
            p = os.path.join(dirpath, d)
            if os.path.islink(p):
                os.unlink(p)
            else:
                os.rmdir(p)
    os.rmdir(root)


def swift_build_flags(manifest: dict) -> list[str]:
    return ["--triple", manifest["triple"], "--sdk", manifest["curated_sdk"]]


def _run(cmd: list[str], cwd: str) -> int:
    return subprocess.run(cmd, cwd=cwd).returncode


def main(argv=None, runner=_run) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--sdk", type=Path, help="iPhoneSimulator SDK (default: xcrun)")
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--report", action="store_true", help="print removed modules and reasons")
    ap.add_argument("--flags", action="store_true", help="print the swift build flags")
    ap.add_argument("--build", metavar="PKG", help="run swift build in PKG for the iOS triple")
    ap.add_argument("--target", help="with --build: one target")
    args = ap.parse_args(argv)
    manifest = curate(args.sdk or default_sdk(), args.out)
    if args.build:
        cmd = ["swift", "build"] + (["--target", args.target] if args.target else [])
        return runner(cmd + swift_build_flags(manifest), args.build)
    if args.report:
        for name, why in sorted(manifest["removed"].items()):
            print(f"{name}\t{why}")
    elif args.flags:
        print(" ".join(swift_build_flags(manifest)))
    else:
        print(manifest["curated_sdk"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
