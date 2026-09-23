#!/bin/zsh
# break_probe_sim.sh <outdir> — build Tools/oracle2/breakprobe for the iOS 26.1
# simulator (iPhone SE 3rd gen), run it, collect breakprobe.json: which
# required constraint UIKit breaks in each unsatisfiable scenario of
# Tools/oracle2/breakprobe/scenarios.json, and the resulting frames.
set -e
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: break_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/BreakProbe.app
rm -rf "$APP"; mkdir -p "$APP"
swiftc -O -swift-version 5 -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  -module-name breakprobe Tools/oracle2/breakprobe/main.swift -o "$APP/breakprobe"
sed 's/layoutprobe/breakprobe/g; s/LayoutProbe/BreakProbe/g' Tools/oracle2/LayoutProbe-Info.plist > "$APP/Info.plist"
cp Tools/oracle2/breakprobe/scenarios.json "$APP/"
. scripts/sim_session.inc
sim_session_lock
DEVNAME="OpenUIKit-2x${SIM_DEVICE_SUFFIX:-}"
DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation"
RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
UDID=$(xcrun simctl list devices | grep "$DEVNAME (" | grep -o '[0-9A-F-]\{36\}' | head -1)
if [[ -z "$UDID" ]]; then UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME"); fi
SIM_SESSION_UDID=$UDID
STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o '(Booted)' || true)
if [[ -z "$STATE" ]]; then xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID"; fi
xcrun simctl uninstall "$UDID" com.openuikit.breakprobe 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.breakprobe data)
rm -f "$CONTAINER"/Documents/* 2>/dev/null || true
xcrun simctl launch "$UDID" com.openuikit.breakprobe >/dev/null || true
for i in {1..120}; do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
[[ -f "$CONTAINER/Documents/DONE" ]] || { echo "break_probe_sim: no DONE marker"; exit 1; }
cp "$CONTAINER"/Documents/breakprobe.json "$OUTDIR"/
echo "breakprobe.json in $OUTDIR"
