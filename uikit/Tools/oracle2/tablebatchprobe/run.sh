#!/bin/zsh
# tablebatchprobe — Apple side of TableViewBatchUpdatesTests. Builds main.swift
# for the iOS 26.1 simulator against Apple's UIKit, runs it in a throwaway
# iPhone 16 with `simctl spawn`, writes transcript-ios26.1.txt.
set -eu
cd "$(dirname "$0")"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-/tmp/tablebatchprobe}
mkdir -p "$OUT"
xcrun swiftc -target arm64-apple-ios26.1-simulator -sdk "$SDK" main.swift -o "$OUT/tablebatchprobe"
DEV=$(xcrun simctl create "iPhone 16-tablebatchprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1' EXIT
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl spawn "$DEV" "$OUT/tablebatchprobe" > transcript-ios26.1.txt
cat transcript-ios26.1.txt
