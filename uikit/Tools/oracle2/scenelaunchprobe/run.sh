#!/bin/zsh
# Builds LaunchProbe.app (module LaunchProbe, Info.plist scene manifest with a
# storyboard, unsigned like an Xcode simulator build) and records its launch
# on a throwaway iPhone 16 / iOS 26.1 device into transcript-ios26.1.txt.
#   zsh run.sh [WORKDIR]
set -eu
HERE=${0:A:h}
WORK=${1:-${TMPDIR:-/tmp}/scenelaunchprobe}
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
APP=$WORK/LaunchProbe.app
rm -rf "$APP"; mkdir -p "$APP"
swiftc -parse-as-library -module-name LaunchProbe -target arm64-apple-ios26.1-simulator -sdk "$SDK" \
  "$HERE/LaunchProbe.swift" -o "$APP/LaunchProbe"
xcrun ibtool --compile "$APP/Main.storyboardc" "$HERE/Main.storyboard" \
  --target-device iphone --minimum-deployment-target 26.0
cp "$HERE/Info.plist" "$APP/Info.plist"
codesign -s - "$APP" 2>/dev/null || true
source "${HERE:h}/sim_lock.zsh"
sim_lock_acquire
DEV=$(xcrun simctl create "iPhone 16-scenelaunchprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; sim_lock_release' EXIT
xcrun simctl boot "$DEV"
xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl install "$DEV" "$APP"
{
  echo "# LaunchProbe, iPhone 16 simulator, iOS 26.1 (23B86), simctl launch --console, $(date -u +%F)"
  timeout 60 xcrun simctl launch --console "$DEV" org.openuikit.launchprobe 2>&1 | grep -E "^(EV|FACT|DONE)"
} > "$HERE/transcript-ios26.1.txt"
cat "$HERE/transcript-ios26.1.txt"
