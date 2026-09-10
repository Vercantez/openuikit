#!/bin/bash
# UISplitViewController column geometry + collapse/expand delegate-order oracle.
# Usage (from uikit/):
#   SIM_DEVICE_SUFFIX=-mine SPLIT_SIM_DEVICE=ipad     scripts/splitframes_probe_sim.sh OUT
#   SIM_DEVICE_SUFFIX=-mine SPLIT_SIM_DEVICE=iphone16 scripts/splitframes_probe_sim.sh OUT
# Output: OUT/splitframes.json (settled snapshots) and OUT/console.txt.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:?usage: splitframes_probe_sim.sh OUT}
KIND=${SPLIT_SIM_DEVICE:-ipad}
SUFFIX=${SIM_DEVICE_SUFFIX:--uikit-splitframes}
NAME="OpenUIKit-SplitFrames-${KIND}${SUFFIX}"
if [[ "$KIND" == iphone16 ]]; then
  TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-16
else
  TYPE=com.apple.CoreSimulator.SimDeviceType.iPad-A16
fi
mkdir -p "$OUT/SplitFramesProbe.app"
APP="$OUT/SplitFramesProbe.app"
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
xcrun --sdk iphonesimulator swiftc -suppress-warnings -O \
  -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/splitframesprobe/main.swift -o "$APP/splitframesprobe"
python3 - "$APP/Info.plist" <<'PY'
import plistlib,sys
with open(sys.argv[1], 'wb') as f:
    plistlib.dump(dict(CFBundleExecutable='splitframesprobe',CFBundleIdentifier='com.openuikit.splitframesprobe',CFBundleName='SplitFramesProbe',CFBundlePackageType='APPL',CFBundleVersion='1',CFBundleShortVersionString='1.0',CFBundleSupportedPlatforms=['iPhoneSimulator'],MinimumOSVersion='26.0',UIDeviceFamily=[1,2],UILaunchScreen={}),f)
PY
UDID=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; name=sys.argv[1]; print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"] == name), ""))' "$NAME")
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "$NAME" "$TYPE" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.splitframesprobe data)
rm -f "$CONTAINER/Documents/splitframes.json"
xcrun simctl launch --console-pty "$UDID" com.openuikit.splitframesprobe > "$OUT/console.txt" 2>&1 || true
cp "$CONTAINER/Documents/splitframes.json" "$OUT/splitframes.json"
echo "measurement in $OUT/splitframes.json ($(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["records"]))' "$OUT/splitframes.json") records)"
