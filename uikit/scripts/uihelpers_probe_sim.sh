#!/bin/zsh
# Build and run the real-iOS oracle for Focus's UIHelpers API cluster.
# Usage: scripts/uihelpers_probe_sim.sh <outdir>
set -e
cd "$(dirname "$0")/.."

OUTDIR=${1:?usage: uihelpers_probe_sim.sh <outdir>}
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP="$OUTDIR/UIHelpersProbe.app"
UDID=${UIHELPERS_SIMULATOR_UDID:-booted}

mkdir -p "$OUTDIR" "$APP"
rm -f "$OUTDIR/uihelpers.txt" "$OUTDIR"/label-*.png(N)
xcrun --sdk iphonesimulator swiftc \
  -O -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/uihelpersprobe/main.swift -o "$APP/uihelpersprobe"
cp Tools/oracle2/UIHelpersProbe-Info.plist "$APP/Info.plist"

xcrun simctl bootstatus "$UDID"
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.uihelpersprobe data)
rm -f "$CONTAINER/Documents/uihelpers.txt" "$CONTAINER/Documents"/label-*.png(N)
xcrun simctl launch --console-pty "$UDID" com.openuikit.uihelpersprobe
cp "$CONTAINER/Documents/uihelpers.txt" "$OUTDIR/uihelpers.txt"
cp "$CONTAINER/Documents"/label-*.png "$OUTDIR/"
echo "measurement in $OUTDIR/uihelpers.txt"
