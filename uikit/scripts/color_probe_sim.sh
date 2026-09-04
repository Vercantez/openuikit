#!/bin/zsh
# color_probe_sim.sh <outdir> — build Tools/oracle2/colorprobe for the iOS 26
# simulator, run it, and collect colorprobe.json (the Auto Layout tie-break
# oracle; see the probe's header). Same device/runtime as realapp_probe_sim.sh.
set -e
setopt null_glob
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: color_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/ColorProbe.app
rm -rf "$APP"; mkdir -p "$APP"
swiftc -O -swift-version 5 -Xfrontend -default-isolation -Xfrontend MainActor -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  -module-name colorprobe Tools/oracle2/colorprobe/main.swift -o "$APP/colorprobe"
cp Tools/oracle2/ColorProbe-Info.plist "$APP/Info.plist"; cp Sources/OpenUIKit/Resources/system_colors.json "$APP/"
# SIM_DEVICE=2x selects a 2x device (iPhone SE 3rd generation, 375 x 667):
# the honest oracle for scale-2 scenes — a 3x device captured at 2x
# resamples every view edge (measured 2026-09-04: label backgrounds off by
# 2-4/255 along their frame edges). Window/modal scenes need the iPhone 16.
if [[ "${SIM_DEVICE:-}" == "2x" ]]; then
  DEVNAME="OpenUIKit-2x${SIM_DEVICE_SUFFIX:-}"
  DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation"
else
  DEVNAME="OpenUIKit-Chrome${SIM_DEVICE_SUFFIX:-}"
  DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
fi
RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
UDID=$(xcrun simctl list devices | grep "$DEVNAME" | grep -o '[0-9A-F-]\{36\}' | head -1)
if [[ -z "$UDID" ]]; then UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME"); fi
STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o '(Booted)' || true)
if [[ -z "$STATE" ]]; then xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID"; fi
xcrun simctl uninstall "$UDID" com.openuikit.colorprobe 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.colorprobe data)
rm -f "$CONTAINER"/Documents/* 2>/dev/null || true
xcrun simctl launch --console-pty "$UDID" com.openuikit.colorprobe >/dev/null || true
for i in {1..60}; do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
[[ -f "$CONTAINER/Documents/DONE" ]] || { echo "color_probe_sim: no DONE marker"; exit 1; }
cp "$CONTAINER"/Documents/system_colors_ios.json "$OUTDIR"/
echo "system_colors_ios.json in $OUTDIR"
