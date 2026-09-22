#!/bin/zsh
# objcsurfaceprobe — the Apple side of Tests/ObjCSurfaceTests and of
# scripts/objc_surface_guest_probe.sh.
#
# Builds scenario/OUKSurfaceScenario.m (the same file OpenUIKit's test target
# and the machorun guest probe compile) against the iOS 26.1 simulator's
# UIKit, runs it inside a throwaway iPhone 16 device with `simctl spawn`, and
# writes transcript-ios26.1.txt. Every step has a timeout; the device is deleted.
set -eu
cd "$(dirname "$0")"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-/tmp/objcsurfaceprobe}
mkdir -p "$OUT"
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules -target arm64-apple-ios26.1-simulator \
  -isysroot "$SDK" -Iscenario/include main.m scenario/OUKSurfaceScenario.m \
  -framework UIKit -framework QuartzCore -framework Foundation -o "$OUT/objcsurfaceprobe"
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules -target arm64-apple-ios26.1-simulator \
  -isysroot "$SDK" -DOUK_NO_FOUNDATION=1 -Iscenario/include guest_main.c scenario/OUKSurfaceScenario.m \
  -framework UIKit -framework QuartzCore -framework Foundation -o "$OUT/objcsurfaceprobe-guest"
DEV=$(xcrun simctl create "iPhone 16-objcsurfaceprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1' EXIT
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl spawn "$DEV" "$OUT/objcsurfaceprobe" > transcript-ios26.1.txt
cat transcript-ios26.1.txt
# The Foundation-free variant the machorun guest runs (OUK_NO_FOUNDATION),
# measured on the same device: the guest's expected output.
timeout 60 xcrun simctl spawn "$DEV" "$OUT/objcsurfaceprobe-guest" > transcript-guest-ios26.1.txt
cat transcript-guest-ios26.1.txt
