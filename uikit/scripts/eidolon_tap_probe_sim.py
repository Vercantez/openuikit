#!/usr/bin/env python3
"""Measure Eidolon's pinned RxCocoa UIButton.tap on a private iOS 26.1 device.

Run from uikit/: SIM_DEVICE_SUFFIX=-eidolon-launch2 python3
scripts/eidolon_tap_probe_sim.py /tmp/eidolon-tap-oracle

Builds the unchanged RxSwift module and the unchanged RxCocoa slice needed
by UIControl/UIButton (Foundation, traits, runtime and their shared helpers).
This is an event/lifetime oracle, not an Eidolon app build or pixel capture.
"""
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys


def main():
    root = Path(__file__).resolve().parents[1]
    out = Path(sys.argv[1]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    rx = root / "Sources/EidolonDependencies/RxSwift"
    cocoa = rx / "RxCocoa"
    probe = root / "Sources/ConformanceApps/EidolonTap"
    commands = []

    def read(*args):
        return subprocess.check_output(args, text=True).strip()

    def run(label, args):
        print(label, flush=True)
        commands.append({"step": label, "argv": list(map(str, args))})
        (out / "commands.json").write_text(json.dumps(commands, indent=2) + "\n")
        with (out / (label + ".log")).open("w") as log:
            subprocess.run(args, cwd=root, stdout=log, stderr=subprocess.STDOUT, check=True)

    sdk = read("xcrun", "--sdk", "iphonesimulator", "--show-sdk-path")
    triple = "arm64-apple-ios26.0-simulator"
    swift_flags = ["-O", "-wmo", "-swift-version", "4", "-target", triple, "-sdk", sdk]
    module = out / "Runtime"
    module.mkdir(exist_ok=True)
    headers = cocoa / "Runtime/include"
    (module / "module.modulemap").write_text(
        f'module RxCocoaRuntime {{ umbrella header "{headers}/RxCocoaRuntime.h" export * }}\n')
    runtime_sources = sorted((cocoa / "Runtime").glob("*.m"))
    objects = []
    for source in runtime_sources:
        obj = out / (source.stem + ".o")
        objects.append(str(obj))
        run(source.stem, ["xcrun", "clang", "-target", triple, "-isysroot", sdk,
                         "-fobjc-arc", "-fmodules", "-I", str(headers),
                         "-c", str(source), "-o", str(obj)])
    swift_sources = sorted((rx / "RxSwift").rglob("*.swift"))
    cocoa_sources = [cocoa / "RxCocoa.swift"]
    for folder in ["Platform", "Traits", "Foundation"]:
        cocoa_sources.extend(sorted((cocoa / folder).rglob("*.swift")))
    cocoa_sources.extend(cocoa / name for name in [
        "Common/Binder.swift", "Common/Observable+Bind.swift", "Common/RxTarget.swift",
        "Common/ControlTarget.swift", "Common/RxCocoaObjCRuntimeError+Extensions.swift",
        "iOS/UIControl+Rx.swift", "iOS/UIButton+Rx.swift"])
    for name, sources, extra in [
        ("RxSwift", swift_sources, []),
        ("RxCocoa", cocoa_sources, ["-D", "SWIFT_PACKAGE", "-I", str(module),
                                  "-I", str(out), "-L", str(out), "-lRxSwift", *objects])
    ]:
        run(name, ["xcrun", "swiftc", *swift_flags, "-emit-library", "-emit-module",
                   "-module-name", name, "-emit-module-path", str(out / (name + ".swiftmodule")),
                   "-o", str(out / ("lib" + name + ".dylib")),
                   "-Xlinker", "-install_name", "-Xlinker",
                   "@executable_path/Frameworks/lib" + name + ".dylib",
                   *map(str, sources), *extra])
    app = out / "EidolonTap.app"
    (app / "Frameworks").mkdir(parents=True, exist_ok=True)
    probe_sources = [probe / "TapScenarios.swift", probe / "OracleMain.swift"]
    run("app-build", ["xcrun", "swiftc", *swift_flags, "-I", str(out), "-I", str(module),
                      "-L", str(out), "-lRxSwift", "-lRxCocoa", *map(str, probe_sources),
                      "-o", str(app / "EidolonTap")])
    for name in ["RxSwift", "RxCocoa"]:
        shutil.copy2(out / ("lib" + name + ".dylib"), app / "Frameworks")
    identifier = "com.openuikit.eidolontap"
    info = {"CFBundleExecutable": "EidolonTap", "CFBundleIdentifier": identifier,
            "CFBundleName": "EidolonTap", "CFBundlePackageType": "APPL", "CFBundleVersion": "1",
            "CFBundleSupportedPlatforms": ["iPhoneSimulator"], "MinimumOSVersion": "26.0",
            "UIDeviceFamily": [1], "UILaunchScreen": {}}
    (app / "Info.plist").write_bytes(plistlib.dumps(info))
    run("sign", ["codesign", "--force", "--deep", "--sign", "-", str(app)])
    runtime = "com.apple.CoreSimulator.SimRuntime.iOS-26-1"
    name = "OpenUIKit-EidolonTap" + os.environ.get("SIM_DEVICE_SUFFIX", "-eidolon-launch2")
    devices = json.loads(read("xcrun", "simctl", "list", "devices", "available", "-j"))["devices"]
    device = next((d for d in devices.get(runtime, []) if d["name"] == name), None)
    udid = device["udid"] if device else read(
        "xcrun", "simctl", "create", name, "com.apple.CoreSimulator.SimDeviceType.iPhone-16", runtime)
    booted_here = device is None or device["state"] != "Booted"
    if booted_here:
        run("boot", ["xcrun", "simctl", "boot", udid])
    try:
        run("bootstatus", ["xcrun", "simctl", "bootstatus", udid, "-b"])
        run("install", ["xcrun", "simctl", "install", udid, str(app)])
        container = Path(read("xcrun", "simctl", "get_app_container", udid, identifier, "data"))
        capture = container / "Documents/eidolon-tap.json"
        capture.unlink(missing_ok=True)
        run("launch", ["xcrun", "simctl", "launch", "--console-pty", udid, identifier])
        shutil.copy2(capture, out / "eidolon-tap.json")
    finally:
        if booted_here:
            subprocess.run(["xcrun", "simctl", "shutdown", udid], check=False)
    inputs = swift_sources + cocoa_sources + runtime_sources + sorted(headers.glob("*.h")) + probe_sources
    provenance = {
        "compiler": read("xcrun", "swiftc", "--version"), "xcode": read("xcodebuild", "-version"),
        "sdk": sdk, "triple": triple, "device": {"name": name, "udid": udid, "runtime": runtime},
        "rxswift_source_count": len(swift_sources), "rxcocoa_source_count": len(cocoa_sources),
        "runtime_source_count": len(runtime_sources),
        "inputs": {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs},
        "capture_sha256": hashlib.sha256((out / "eidolon-tap.json").read_bytes()).hexdigest(),
    }
    (out / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")
    print("Measurement:", out / "eidolon-tap.json")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: eidolon_tap_probe_sim.py /tmp/output")
    main()
