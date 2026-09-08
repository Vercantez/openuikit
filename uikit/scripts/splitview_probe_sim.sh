#!/bin/bash
# UISplitViewController's public state/containment oracle. All output stays in OUT.
# Usage: SIM_DEVICE_SUFFIX=-mine SPLIT_SIM_DEVICE=ipad scripts/splitview_probe_sim.sh OUT
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:?usage: splitview_probe_sim.sh OUT}
KIND=${SPLIT_SIM_DEVICE:-ipad}
SUFFIX=${SIM_DEVICE_SUFFIX:--uikit-blocking-types-split}
NAME="OpenUIKit-Split-${KIND}${SUFFIX}"
if [[ "$KIND" == ipad ]]; then NAME="OpenUIKit-Split${SUFFIX}"; fi
if [[ "$KIND" == 2x ]]; then
  TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation
else
  TYPE=com.apple.CoreSimulator.SimDeviceType.iPad-A16
fi
mkdir -p "$OUT/SplitViewBlockingProbe.app"
APP="$OUT/SplitViewBlockingProbe.app"
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
xcrun --sdk iphonesimulator swiftc -suppress-warnings -O \
  -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/splitviewprobe/main.swift -o "$APP/splitprobe"
python3 - "$APP/Info.plist" <<'PY'
import plistlib,sys
with open(sys.argv[1], 'wb') as f:
    plistlib.dump(dict(CFBundleExecutable='splitprobe',CFBundleIdentifier='com.openuikit.splitblockingprobe',CFBundleName='SplitViewBlockingProbe',CFBundlePackageType='APPL',CFBundleVersion='1',CFBundleShortVersionString='1.0',CFBundleSupportedPlatforms=['iPhoneSimulator'],MinimumOSVersion='26.0',UIDeviceFamily=[1,2],UILaunchScreen={}),f)
PY
UDID=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; name=sys.argv[1]; print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"] == name), ""))' "$NAME")
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "$NAME" "$TYPE" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch --console-pty "$UDID" com.openuikit.splitblockingprobe "${SPLIT_PROBE_CASE:-main}" > "$OUT/console.txt" 2>&1
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.splitblockingprobe data)
cp "$CONTAINER/Documents/splitview.txt" "$OUT/splitview.txt"
echo "measurement in $OUT/splitview.txt"
