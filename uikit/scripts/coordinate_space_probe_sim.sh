#!/bin/bash
# Real UIKit coordinate-space behavior; a private device and an app entirely under <out>.
set -euo pipefail
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: coordinate_space_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"
OUTDIR=$(cd "$OUTDIR" && pwd)
APP="$OUTDIR/BlockingTypesCoordinateProbe.app"
mkdir -p "$APP"
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
xcrun --sdk iphonesimulator swiftc -Onone \
  -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/coordinatespaceprobe/main.swift -o "$APP/coordinatespaceprobe"
cp Tools/oracle2/coordinatespaceprobe/Info.plist "$APP/Info.plist"
DEVNAME="OpenUIKit-2x${SIM_DEVICE_SUFFIX:--uikit-blocking-types-coordinate}"
UDID=$(xcrun simctl list devices available -j | python3 -c \
  'import json,sys; name=sys.argv[1]; print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"] == name), ""))' "$DEVNAME")
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "$DEVNAME" \
    com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation \
    com.apple.CoreSimulator.SimRuntime.iOS-26-1)
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch --console-pty "$UDID" com.openuikit.blockingtypescoordinate
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.blockingtypescoordinate data)
cp "$CONTAINER/Documents/coordinate-space.txt" "$OUTDIR/coordinate-space.txt"
xcrun simctl shutdown "$UDID"
echo "Measured iOS 26.1 coordinate-space behavior in $OUTDIR/coordinate-space.txt"
