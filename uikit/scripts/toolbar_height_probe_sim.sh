#!/bin/zsh
# toolbar_height_probe_sim.sh <outdir> [device...] — build
# Tools/oracle2/toolbarheightprobe for the iOS 26 simulator and run it on
# each requested device (default: iphone16 se ipad), collecting
# <outdir>/toolbarheight-<device>.json. Every device is created with
# SIM_DEVICE_SUFFIX and deleted afterwards. The app measures portrait, then
# rotates itself to landscape and measures again, then writes DONE.
set -e
setopt null_glob
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: toolbar_height_probe_sim.sh <outdir> [iphone16|se|ipad ...]}
shift || true
DEVICES=("$@")
(( ${#DEVICES} )) || DEVICES=(iphone16 se ipad)
mkdir -p "$OUTDIR"
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/ToolbarHeightProbe.app
rm -rf "$APP"; mkdir -p "$APP"
swiftc -O -swift-version 5 -Xfrontend -default-isolation -Xfrontend MainActor -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  -module-name toolbarheightprobe Tools/oracle2/toolbarheightprobe/main.swift -o "$APP/toolbarheightprobe"
python3 - "$APP/Info.plist" <<'PY'
import plistlib, sys
plistlib.dump({
  'CFBundleIdentifier': 'com.openuikit.toolbarheightprobe', 'CFBundleExecutable': 'toolbarheightprobe',
  'CFBundleName': 'ToolbarHeightProbe', 'CFBundleDevelopmentRegion': 'en', 'CFBundlePackageType': 'APPL',
  'LSRequiresIPhoneOS': True, 'UIDeviceFamily': [1, 2], 'UILaunchScreen': {}, 'UIRequiresFullScreen': True,
  'UISupportedInterfaceOrientations': ['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'],
  'UISupportedInterfaceOrientations~ipad': ['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'],
}, open(sys.argv[1], 'wb'))
PY
RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
for DEV in "${DEVICES[@]}"; do
  case "$DEV" in
    iphone16) DEVTYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-16 ;;
    se) DEVTYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation ;;
    ipad) DEVTYPE=com.apple.CoreSimulator.SimDeviceType.iPad-A16 ;;
    *) echo "unknown device $DEV"; exit 2 ;;
  esac
  DEVNAME="OpenUIKit-ToolbarHeight-${DEV}${SIM_DEVICE_SUFFIX:-}"
  UDID=$(xcrun simctl list devices | grep "$DEVNAME" | grep -o '[0-9A-F-]\{36\}' | head -1)
  if [[ -z "$UDID" ]]; then UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME"); fi
  STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o '(Booted)' || true)
  if [[ -z "$STATE" ]]; then xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID"; fi
  xcrun simctl uninstall "$UDID" com.openuikit.toolbarheightprobe 2>/dev/null || true
  xcrun simctl install "$UDID" "$APP"
  CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.toolbarheightprobe data)
  rm -f "$CONTAINER"/Documents/* 2>/dev/null || true
  xcrun simctl launch --console-pty "$UDID" com.openuikit.toolbarheightprobe > "$OUTDIR/launch-$DEV.log" 2>&1 || true
  for i in {1..90}; do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
  if [[ -f "$CONTAINER/Documents/toolbarheight.json" ]]; then
    cp "$CONTAINER/Documents/toolbarheight.json" "$OUTDIR/toolbarheight-$DEV.json"
    [[ -f "$CONTAINER/Documents/DONE" ]] || echo "toolbar_height_probe_sim: $DEV no DONE marker (partial JSON copied)"
  else
    echo "toolbar_height_probe_sim: $DEV produced no JSON"
  fi
  xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
  xcrun simctl delete "$UDID" >/dev/null 2>&1 || true
done
echo "toolbarheight-*.json in $OUTDIR"
