#!/bin/bash
# Run from uikit/: scripts/nsobject_value_probe_sim.sh /tmp/output
# Measures, on a private iPhone 16 / iOS 26.1, the runtime class chain and
# protocol conformances of the NSObject-derived UIKit value classes
# (CALayer, UIBarItem, UIBarButtonItem, UITabBarItem, UINavigationItem,
# NSParagraphStyle, NSMutableParagraphStyle), the UIAccessibility informal
# protocol's defaults on a bare NSObject, UIBarItem's inherited defaults and
# NSParagraphStyle's equality/copy semantics. Output: nsobject-value.json.
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: nsobject_value_probe_sim.sh /tmp/output}
mkdir -p "$out/NSObjectValueProbe.app"
app="$out/NSObjectValueProbe.app"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.1-simulator -sdk "$sdk" \
  Tools/oracle2/nsobjectvalueprobe/main.swift -o "$app/probe"
python3 - "$app/Info.plist" <<'PY'
import plistlib,sys
plistlib.dump({'CFBundleIdentifier':'com.openuikit.nsobjectvalueprobe','CFBundleExecutable':'probe','CFBundleName':'NSObjectValueProbe','CFBundleDevelopmentRegion':'en','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1,2],'UILaunchScreen':{}},open(sys.argv[1],'wb'))
PY
name="OpenUIKit-NSObjectValue${SIM_DEVICE_SUFFIX:--nsobject-value-classes}"
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-26-1);fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
trap 'xcrun simctl terminate "$device" com.openuikit.nsobjectvalueprobe >/dev/null 2>&1 || true; xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" com.openuikit.nsobjectvalueprobe data)
rm -f "$container"/Documents/*.marker "$container/Documents/nsobject-value.json"
xcrun simctl launch "$device" com.openuikit.nsobjectvalueprobe
for _ in $(seq 1 600); do [ -f "$container/Documents/done.marker" ] && break; sleep 0.2; done
[ -f "$container/Documents/done.marker" ] || { echo "timeout waiting for done" >&2; exit 1; }
cp "$container/Documents/nsobject-value.json" "$out/"
echo "Measured iOS 26.1 state: $out/nsobject-value.json"
