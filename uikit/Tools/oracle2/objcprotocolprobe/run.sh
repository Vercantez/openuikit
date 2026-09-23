#!/bin/zsh
# objcprotocolprobe — the Apple side of Tests/ObjCProtocolTests.
#
# Builds scenario/OUKProtocolScenario.m (the same file OpenUIKit's test target
# compiles) against the iOS 26.1 simulator's UIKit, runs it inside a throwaway
# iPhone 16 device with `simctl spawn`, and writes transcript-ios26.1.txt.
# Every step has a timeout; the device is deleted.
set -eu
cd "$(dirname "$0")"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-/tmp/objcprotocolprobe}
mkdir -p "$OUT"
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules -target arm64-apple-ios26.1-simulator \
  -isysroot "$SDK" -Iscenario/include main.m scenario/OUKProtocolScenario.m \
  -framework UIKit -framework Foundation -o "$OUT/objcprotocolprobe"
DEV=$(xcrun simctl create "iPhone 16-objcprotocolprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1' EXIT
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl spawn "$DEV" "$OUT/objcprotocolprobe" > transcript-ios26.1.txt
cat transcript-ios26.1.txt
