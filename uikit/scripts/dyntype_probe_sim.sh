#!/bin/zsh
# Runs Tools/oracle2/dyntypeprobe in the iOS 26 simulator and copies
# <Documents>/dynamic_type_ios.json to <outdir>. See the probe's header for what it
# measures (alert label fonts + CoreText glyph positions).
set -e
setopt null_glob
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: font_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"

SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/DynTypeProbe.app
mkdir -p "$APP"
swiftc -O -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/dyntypeprobe/main.swift -o "$APP/dyntypeprobe"
cp Tools/oracle2/DynTypeProbe-Info.plist "$APP/Info.plist"

DEVNAME="OpenUIKit-Chrome"
DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
UDID=$(xcrun simctl list devices | grep "$DEVNAME" | grep -o '[0-9A-F-]\{36\}' | head -1)
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME")
fi
STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o '(Booted)' || true)
if [[ -z "$STATE" ]]; then
  xcrun simctl boot "$UDID"
  xcrun simctl bootstatus "$UDID"
fi
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.dyntypeprobe data)
rm -f "$CONTAINER"/Documents/*.json "$CONTAINER"/Documents/DONE
xcrun simctl launch --console-pty "$UDID" com.openuikit.dyntypeprobe >/dev/null || true
cp "$CONTAINER"/Documents/*.json "$OUTDIR"/
echo "measurements in $OUTDIR"
