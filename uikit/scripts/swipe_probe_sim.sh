#!/bin/bash
# Real UIKit swipe behavior; a private device and an app entirely under <out>.
set -euo pipefail
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: swipe_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"
OUTDIR=$(cd "$OUTDIR" && pwd)
APP="$OUTDIR/BlockingTypesSwipeProbe.app"
mkdir -p "$APP"
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
xcrun --sdk iphonesimulator swiftc -Onone \
  -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/swipeprobe/main.swift -o "$APP/swipeprobe"
cp Tools/oracle2/swipeprobe/Info.plist "$APP/Info.plist"
DEVNAME="OpenUIKit-2x${SIM_DEVICE_SUFFIX:--uikit-blocking-types-swipe}"
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
xcrun simctl launch --console-pty "$UDID" com.openuikit.blockingtypesswipe
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.blockingtypesswipe data)
cp "$CONTAINER/Documents/swipe.txt" "$OUTDIR/swipe.txt"
xcrun simctl shutdown "$UDID"
echo "Measured iOS 26.1 swipe behavior in $OUTDIR/swipe.txt"
