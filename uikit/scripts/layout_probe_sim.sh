#!/bin/zsh
# layout_probe_sim.sh <outdir> — build Tools/oracle2/layoutprobe for the iOS 26
# simulator, run it, and collect layoutprobe.json (the Auto Layout tie-break
# oracle; see the probe's header). Same device/runtime as realapp_probe_sim.sh.
set -e
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: layout_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/LayoutProbe.app
rm -rf "$APP"; mkdir -p "$APP"
swiftc -O -swift-version 5 -Xfrontend -default-isolation -Xfrontend MainActor -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  -module-name layoutprobe Tools/oracle2/layoutprobe/main.swift Tools/oracle2/layoutprobe/Scenarios.swift -o "$APP/layoutprobe"
cp Tools/oracle2/LayoutProbe-Info.plist "$APP/Info.plist"
DEVNAME="OpenUIKit-Chrome"
DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
UDID=$(xcrun simctl list devices | grep "$DEVNAME" | grep -o '[0-9A-F-]\{36\}' | head -1)
if [[ -z "$UDID" ]]; then UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME"); fi
STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o '(Booted)' || true)
if [[ -z "$STATE" ]]; then xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID"; fi
xcrun simctl uninstall "$UDID" com.openuikit.layoutprobe 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.layoutprobe data)
rm -f "$CONTAINER"/Documents/* 2>/dev/null || true
xcrun simctl launch --console-pty "$UDID" com.openuikit.layoutprobe >/dev/null || true
for i in {1..60}; do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
[[ -f "$CONTAINER/Documents/DONE" ]] || { echo "layout_probe_sim: no DONE marker"; exit 1; }
cp "$CONTAINER"/Documents/layoutprobe.json "$OUTDIR"/
echo "layoutprobe.json in $OUTDIR"
