#!/bin/bash
# Run from uikit/: scripts/swiftuia11y_probe_sim.sh OUTDIR
# Builds Tools/oracle2/swiftuia11yprobe as an iOS 26.1 simulator command-line
# binary, runs it with `simctl spawn` on a private iPhone 16, and writes the
# key=value transcript to OUTDIR/swiftuia11y.txt. The device is shut down
# afterwards; delete it with `xcrun simctl delete` when done.
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: swiftuia11y_probe_sim.sh OUTDIR}
fonts=.
mkdir -p "$out"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.1-simulator -sdk "$sdk" \
  -swift-version 5 Tools/oracle2/swiftuia11yprobe/main.swift -o "$out/swiftuia11yprobe"
name="OpenUIKit-SwiftUIA11y${SIM_DEVICE_SUFFIX:--ios-oss-launch3}"
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-26-1); fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b >/dev/null
trap 'xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl spawn "$device" "$PWD/$out/swiftuia11yprobe" "$fonts" > "$out/swiftuia11y.txt" 2> "$out/swiftuia11y.stderr" || \
  xcrun simctl spawn "$device" "$out/swiftuia11yprobe" "$fonts" > "$out/swiftuia11y.txt" 2> "$out/swiftuia11y.stderr"
grep -q '^done=1$' "$out/swiftuia11y.txt" || { echo "probe did not finish; see $out/swiftuia11y.stderr" >&2; exit 1; }
echo "device=$device"
echo "Measured iOS 26.1: $out/swiftuia11y.txt"
