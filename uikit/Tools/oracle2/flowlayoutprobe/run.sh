#!/bin/zsh
# flowlayoutprobe — the Apple side of Tests/ObjCSubclassingTests/FlowLayoutObjCTests.
#
# Builds scenario/OUKFlowLayoutScenario.m (the same file the OpenUIKit test
# target OpenUIKitFlowLayoutFixtures compiles) against the iOS 26.1
# simulator's UIKit, runs it inside a throwaway iPhone 16 device with
# `simctl spawn`, and writes the transcript to transcript-ios26.1.txt. Every
# step has a timeout; the device is deleted.
set -eu
cd "$(dirname "$0")"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-/tmp/flowlayoutprobe}
mkdir -p "$OUT"
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules -target arm64-apple-ios26.1-simulator \
  -isysroot "$SDK" -Iscenario/include main.m scenario/OUKFlowLayoutScenario.m \
  -framework UIKit -framework Foundation -o "$OUT/flowlayoutprobe"
# Serialize simulator work across agents (the mkdir-style lock of
# scripts/conformance_probe_sim.sh): one booted simulator at a time.
SIM_LOCK=/tmp/conformance_sim.lock
while ! mkdir "$SIM_LOCK" 2>/dev/null; do
  holder=$(cat "$SIM_LOCK/pid" 2>/dev/null || true)
  if [[ -n "$holder" ]] && ! kill -0 "$holder" 2>/dev/null; then rm -rf "$SIM_LOCK"; continue; fi
  echo "flowlayoutprobe: waiting for $SIM_LOCK (pid ${holder:-?})" >&2
  sleep 15
done
echo $$ > "$SIM_LOCK/pid"
DEV=""
trap '[[ -n "$DEV" ]] && { xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; }; rm -rf "$SIM_LOCK"' EXIT
DEV=$(xcrun simctl create "iPhone 16-flowlayoutprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl spawn "$DEV" "$OUT/flowlayoutprobe" > transcript-ios26.1.txt
cat transcript-ios26.1.txt
