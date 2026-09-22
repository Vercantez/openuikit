#!/bin/bash
# Run from uikit/: scripts/iososslibrary_probe_sim.sh OUTDIR
# Builds Tools/oracle2/iososslibraryprobe as an iOS 26.1 simulator command-line
# binary, runs it with `simctl spawn` on a private iPhone 16, and writes the
# key=value transcript to OUTDIR/iososslibrary.txt. The device is shut down
# afterwards; delete it with `xcrun simctl delete` when done.
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: iososslibrary_probe_sim.sh OUTDIR}
fonts=.
mkdir -p "$out"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.1-simulator -sdk "$sdk" \
  -swift-version 5 Tools/oracle2/iososslibraryprobe/main.swift -o "$out/iososslibraryprobe"
name="OpenUIKit-IosOssLibrary${SIM_DEVICE_SUFFIX:--ios-oss-launch3}"
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-26-1); fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b >/dev/null
trap 'xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl spawn "$device" "$PWD/$out/iososslibraryprobe" "$fonts" > "$out/iososslibrary.txt" 2> "$out/iososslibrary.stderr" || \
  xcrun simctl spawn "$device" "$out/iososslibraryprobe" "$fonts" > "$out/iososslibrary.txt" 2> "$out/iososslibrary.stderr"
grep -q '^done=1$' "$out/iososslibrary.txt" || { echo "probe did not finish; see $out/iososslibrary.stderr" >&2; exit 1; }
echo "device=$device"
echo "Measured iOS 26.1: $out/iososslibrary.txt"
