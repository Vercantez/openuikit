#!/bin/zsh
# textstorageprobe — the Apple side of Tests/AttributedStringUnifyTests.
#
# Builds scenario/OUKTextStorageScenario.m (the same file the OpenUIKit test
# target compiles) against the iOS 26.1 simulator's UIKit, runs it inside a
# throwaway iPhone 16 device with `simctl spawn`, and writes the transcript
# to transcript-ios26.1.txt. Every step has a timeout; the device is deleted.
set -eu
cd "$(dirname "$0")"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-/tmp/textstorageprobe}
mkdir -p "$OUT"
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules -target arm64-apple-ios26.1-simulator \
  -isysroot "$SDK" -Iscenario/include main.m scenario/OUKTextStorageScenario.m \
  -framework UIKit -framework Foundation -o "$OUT/textstorageprobe"
DEV=$(xcrun simctl create "iPhone 16-textstorageprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1' EXIT
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
SIMCTL_CHILD_OUK_TRACE_STDERR=${OUK_TRACE_STDERR:-} timeout 60 xcrun simctl spawn "$DEV" "$OUT/textstorageprobe" > transcript-ios26.1.txt
cat transcript-ios26.1.txt
