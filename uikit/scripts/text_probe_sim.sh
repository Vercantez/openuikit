#!/bin/zsh
# text_probe_sim.sh <outdir> — build Tools/oracle2/textprobe for the iOS 26
# simulator, run it, and collect textprobe.json (the Auto Layout tie-break
# oracle; see the probe's header). Same device/runtime as realapp_probe_sim.sh.
set -e
setopt null_glob
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: text_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/TextProbe.app
rm -rf "$APP"; mkdir -p "$APP"
swiftc -O -swift-version 5 -Xfrontend -default-isolation -Xfrontend MainActor -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  -module-name textprobe Tools/oracle2/textprobe/main.swift -o "$APP/textprobe"
cp Tools/oracle2/TextProbe-Info.plist "$APP/Info.plist"
DEVNAME="OpenUIKit-Chrome"
DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
UDID=$(xcrun simctl list devices | grep "$DEVNAME" | grep -o '[0-9A-F-]\{36\}' | head -1)
if [[ -z "$UDID" ]]; then UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME"); fi
STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o '(Booted)' || true)
if [[ -z "$STATE" ]]; then xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID"; fi
xcrun simctl uninstall "$UDID" com.openuikit.textprobe 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.textprobe data)
rm -f "$CONTAINER"/Documents/* 2>/dev/null || true
xcrun simctl launch --console-pty "$UDID" com.openuikit.textprobe >/dev/null || true
for i in {1..60}; do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
[[ -f "$CONTAINER/Documents/DONE" ]] || { echo "text_probe_sim: no DONE marker"; exit 1; }
cp "$CONTAINER"/Documents/text_positions_ios.json "$CONTAINER"/Documents/diag_*.png "$OUTDIR"/
echo "text_positions_ios.json in $OUTDIR"
