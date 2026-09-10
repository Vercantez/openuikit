#!/bin/bash
# Run from uikit/: scripts/contentoffset_order_probe_sim.sh /tmp/output
# Measures the contentOffset entry-point ordering (setContentOffset animated
# false/true, contentOffset, bounds, scrollRectToVisible, scrollToItem /
# scrollToRow, a synthetic drag) for a base layout, a flow layout and a
# table view on a private iPhone 16 / iOS 26.1. Output: offset-order.json.
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: contentoffset_order_probe_sim.sh /tmp/output}
mkdir -p "$out/OffsetOrderProbe.app"
app="$out/OffsetOrderProbe.app"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.0-simulator -sdk "$sdk" Tools/oracle2/signalrowsprobe/offset.swift -o "$app/probe"
python3 - "$app/Info.plist" <<'PY'
import plistlib,sys
plistlib.dump({'CFBundleIdentifier':'com.openuikit.offsetorderprobe','CFBundleExecutable':'probe','CFBundleName':'OffsetOrderProbe','CFBundleDevelopmentRegion':'en','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1,2],'UILaunchScreen':{}},open(sys.argv[1],'wb'))
PY
name="OpenUIKit-Offset-order${SIM_DEVICE_SUFFIX:--uikit-offset-order}"
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-26-1);fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
trap 'xcrun simctl terminate "$device" com.openuikit.offsetorderprobe >/dev/null 2>&1 || true; xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" com.openuikit.offsetorderprobe data)
rm -f "$container"/Documents/*.marker "$container/Documents/offset-order.json"
xcrun simctl launch "$device" com.openuikit.offsetorderprobe
for _ in $(seq 1 600); do [ -f "$container/Documents/done.marker" ] && break; sleep 0.2; done
[ -f "$container/Documents/done.marker" ] || { echo "timeout waiting for done" >&2; exit 1; }
cp "$container/Documents/offset-order.json" "$out/"
echo "Measured iOS 26.1 state: $out/offset-order.json"
