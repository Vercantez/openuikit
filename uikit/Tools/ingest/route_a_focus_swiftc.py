#!/usr/bin/env python3
"""Direct Linux swiftc reproduction using one unchanged Focus selector file.

Run in the already-built isolated /work-route-a/uikit container copy:
  python3 Tools/ingest/route_a_focus_swiftc.py

Reads release UIKit/OpenUIKit modules and the original Focus cell, PaddedSwitch,
and SystemThemeDelegate. The existing explicit colors/localization fixture is
the only dependency substitution. No Package.swift mutation or SwiftPM command
is involved. All new compiler cache, generated source and logs live under
/work-route-a/direct-focus. Runtime delivery is proved by route_a_focus_probe.py.
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def main():
    package = Path(__file__).resolve().parents[2]
    if sys.platform != "linux" or package != Path("/work-route-a/uikit"):
        raise SystemExit("run only from the isolated Linux /work-route-a/uikit copy")
    out = Path("/work-route-a/direct-focus")
    out.mkdir(parents=True, exist_ok=True)
    app = package / "Sources/Blockzilla/Blockzilla"
    original = app / "Theme/ThemeCells/ThemeTableViewToggleCell.swift"
    dependencies = [app / "Lib/PaddedSwitch.swift", app / "Theme/SystemThemeDelegate.swift",
                    package / "Tools/ingest/fixtures/route_a_selector/Support.swift"]
    maps = [package / "Sources/CQuartz/include/module.modulemap",
            package / ".build/release/CPortableIO.build/module.modulemap",
            package / ".build/release/CSTBTrueType.build/module.modulemap"]
    for path in [original, *dependencies, *maps, package / ".build/release/Modules/UIKit.swiftmodule"]:
        if not path.exists():
            raise SystemExit(f"missing existing build input: {path}")

    inputs = [original, *dependencies]
    hashes = {str(path): hashlib.sha256(path.read_bytes()).hexdigest() for path in inputs}
    results = {
        "scope": "Direct swiftc typecheck of one actual Focus cell against existing OpenUIKit modules",
        "source_sha256": hashes,
        "working_directory": str(out),
        "commands": [],
    }

    def run(name, command):
        completed = subprocess.run(command, cwd=out, text=True, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, timeout=60)
        (out / f"{name}.log").write_text(completed.stdout)
        results["commands"].append({"name": name, "command": command, "exit": completed.returncode,
                                    "output": completed.stdout})
        (out / "result.json").write_text(json.dumps(results, indent=2) + "\n")
        print(f"{name}: exit={completed.returncode}", flush=True)
        return completed

    compiler = run("toolchain", ["swiftc", "--version"])
    assert compiler.returncode == 0
    common = ["swiftc", "-typecheck", "-swift-version", "5", "-module-name", "RouteAFocusDirect",
              "-module-cache-path", str(out / "module-cache"),
              "-I", str(package / ".build/release/Modules")]
    for module_map in maps:
        common += ["-Xcc", f"-fmodule-map-file={module_map}"]
    for target in ["CQuartz", "CPortableIO", "CSTBTrueType"]:
        common += ["-Xcc", "-I" + str(package / "Sources" / target / "include")]

    original_commands = [
        ("original-default", []),
        ("original-experimental-objcinterop", ["-enable-experimental-feature", "ObjCInterop"]),
        ("original-frontend-objc-interop", ["-Xfrontend", "-enable-objc-interop"]),
    ]
    for name, flags in original_commands:
        result = run(name, common + flags + [str(original)] + [str(path) for path in dependencies])
        assert result.returncode != 0, f"{name}: original source unexpectedly typechecks"
        if name != "original-frontend-objc-interop":
            assert "error: Objective-C interoperability is disabled" in result.stdout
            assert "error: '#selector' can only be used with the Objective-C runtime" in result.stdout
        else:
            assert "type of the parameter cannot be represented in Objective-C" in result.stdout
            assert "error: import the 'ObjectiveC' module to use '#selector'" in result.stdout
        # Diagnostic excerpts repeat each error in the annotated source.
        actual_errors = [line for line in result.stdout.splitlines() if ": error:" in line]
        assert len(actual_errors) == 2, result.stdout
    lowered = out / original.name
    rewrite = run("rewrite", ["python3", str(package / "Tools/ingest/route_a_selectors.py"),
                              "rewrite", "--route-a", str(original), "--output", str(lowered)])
    assert rewrite.returncode == 0, rewrite.stdout
    after = run("lowered-default", common + [str(lowered)] + [str(path) for path in dependencies])
    assert after.returncode == 0, after.stdout
    assert not after.stdout.strip(), after.stdout
    results["original_sources_unchanged"] = all(hashlib.sha256(Path(path).read_bytes()).hexdigest() == digest
                                                 for path, digest in hashes.items())
    assert results["original_sources_unchanged"]
    results["result"] = "DIRECT_FOCUS_SWIFTC_PASS original_errors=2 lowered_errors=0"
    (out / "result.json").write_text(json.dumps(results, indent=2) + "\n")
    print(results["result"])


if __name__ == "__main__":
    main()
