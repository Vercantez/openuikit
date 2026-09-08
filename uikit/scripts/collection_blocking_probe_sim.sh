#!/bin/bash
# Run from uikit/: scripts/collection_blocking_probe_sim.sh /tmp/output
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: collection_blocking_probe_sim.sh /tmp/output}
mkdir -p "$out/CollectionBlockingProbe.app"
app="$out/CollectionBlockingProbe.app"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.0-simulator -sdk "$sdk" Tools/oracle2/collectionblockingprobe/main.swift -o "$app/probe"
python3 - "$app/Info.plist" <<'PY'
import plistlib,sys
plistlib.dump({'CFBundleIdentifier':'com.openuikit.collectionblockingprobe','CFBundleExecutable':'probe','CFBundleName':'CollectionBlockingProbe','CFBundleDevelopmentRegion':'en','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1,2],'UILaunchScreen':{}},open(sys.argv[1],'wb'))
PY
name="OpenUIKit-Blocking-collection${SIM_DEVICE_SUFFIX:--uikit-blocking-types-collection}"
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-26-1);fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
trap 'xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" com.openuikit.collectionblockingprobe data)
rm -f "$container/Documents/collection.json"
xcrun simctl launch --console-pty "$device" com.openuikit.collectionblockingprobe
cp "$container/Documents/collection.json" "$out/collection.json"
echo "Measured iOS 26.1 state: $out/collection.json"
