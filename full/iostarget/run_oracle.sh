#!/bin/zsh
# run_oracle.sh — Apple side of IOSTargetGuestProbe: build it with Xcode for
# arm64-apple-ios26.0-simulator against Apple's UIKit, run it in a throwaway
# iPhone 16 / iOS 26.1 simulator, write oracle-ios26.1.txt.
set -eu
cd "${0:A:h}"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-${TMPDIR:-/tmp}/iostarget-oracle}
mkdir -p "$OUT"
xcrun swiftc -parse-as-library -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
    IOSTargetGuestProbe.swift -o "$OUT/IOSTargetGuestProbe"
DEV=$(xcrun simctl create "iPhone 16-iostarget-oracle" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1' EXIT
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl spawn "$DEV" "$OUT/IOSTargetGuestProbe" > oracle-ios26.1.txt
cat oracle-ios26.1.txt
