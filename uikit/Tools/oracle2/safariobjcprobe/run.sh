#!/bin/zsh
# safariobjcprobe — the Apple side of Tests/SafariObjCTests.
#
# Builds scenario/OUKSafariScenario.m (the same file OpenUIKit's test target
# compiles) against the iOS 26.1 simulator SDK, runs it in a throwaway
# iPhone 16 under /tmp/conformance_sim.lock (Tools/oracle2/sim_lock.zsh),
# and writes transcript-ios26.1.txt. The device is shut down and deleted.
set -eu
cd "$(dirname "$0")"
source ../sim_lock.zsh
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-/tmp/safariobjcprobe}
mkdir -p "$OUT"
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules -target arm64-apple-ios26.1-simulator \
  -isysroot "$SDK" -Iscenario/include main.m scenario/OUKSafariScenario.m \
  -framework UIKit -framework SafariServices -framework Foundation -o "$OUT/safariobjcprobe"
sim_lock_acquire
DEV=$(xcrun simctl create "iPhone 16-safariobjcprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; sim_lock_release' EXIT
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl spawn "$DEV" "$OUT/safariobjcprobe" > transcript-ios26.1.txt
cat transcript-ios26.1.txt
