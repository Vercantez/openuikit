#!/bin/zsh
# cgunifyprobe — Apple side of CGUnifyTests. Builds main.swift + scenario/ for
# the iOS 26.1 simulator against Apple's UIKit, then (holding the shared
# /tmp/conformance_sim.lock) runs it in a throwaway iPhone 16 with
# `simctl spawn`, shuts the device down and deletes it, and writes
# transcript-ios26.1.txt.
set -eu
cd "$(dirname "$0")"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-/tmp/cgunifyprobe}
mkdir -p "$OUT"
xcrun swiftc -target arm64-apple-ios26.1-simulator -sdk "$SDK" main.swift scenario/*.swift -o "$OUT/cgunifyprobe"
SIM_LOCK=/tmp/conformance_sim.lock
while ! mkdir "$SIM_LOCK" 2>/dev/null; do
  holder=$(cat "$SIM_LOCK/pid" 2>/dev/null || true)
  if [[ -n "$holder" ]] && ! kill -0 "$holder" 2>/dev/null; then rm -rf "$SIM_LOCK"; continue; fi
  echo "cgunifyprobe: waiting for $SIM_LOCK (pid ${holder:-?})" >&2; sleep 15
done
echo $$ > "$SIM_LOCK/pid"
DEV=$(xcrun simctl create "iPhone 16-cgunifyprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; rm -rf "$SIM_LOCK"' EXIT
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl spawn "$DEV" "$OUT/cgunifyprobe" > transcript-ios26.1.txt
cat transcript-ios26.1.txt
