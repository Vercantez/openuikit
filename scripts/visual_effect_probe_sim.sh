#!/bin/zsh
# Build and run the iOS 26 UIVisualEffect semantic oracle. The required output
# path receives a stable text fixture suitable for diffing with OpenUIKit's
# XCTest matrix; stdout only reports that path after a successful run.
set -e
setopt pipefail
cd "$(dirname "$0")/.."

OUT=${1:?usage: scripts/visual_effect_probe_sim.sh <output.txt> [simulator-udid]}
UDID=${2:-}
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=$(mktemp -d /private/tmp/openuikit-visual-effect-probe.XXXXXX)/VisualEffectProbe.app
mkdir -p "$APP"

swiftc -parse-as-library -O \
  -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/visualeffectprobe/main.swift \
  -o "$APP/visualeffectprobe"
cp Tools/oracle2/VisualEffectProbe-Info.plist "$APP/Info.plist"

if [[ -z "$UDID" ]]; then
  DEVNAME="OpenUIKit-VisualEffect"
  DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
  RUNTIME=$(xcrun simctl list runtimes | \
    grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
  UDID=$(xcrun simctl list devices | grep "$DEVNAME" | \
    grep -o '[0-9A-F-]\{36\}' | head -1 || true)
  if [[ -z "$UDID" ]]; then
    UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME")
  fi
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" >/dev/null
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch --terminate-running-process --console-pty \
  "$UDID" com.openuikit.visualeffectprobe | \
  tr -d '\r' | \
  sed -n -E '/^(fresh|reset|factory|copy|blur[. -]|vibrancy[. -]|nil[ -]|base[ -]|lazy-|frame-access)/p' \
  > "$OUT"
test -s "$OUT"
echo "visual-effect oracle: $OUT"
