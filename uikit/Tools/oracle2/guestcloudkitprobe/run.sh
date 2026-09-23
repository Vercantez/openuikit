#!/bin/zsh
# guestcloudkitprobe -- the Apple side of Tools/guestprobes/GuestCloudKitProbe.
#
# Builds main.swift for the iOS 26.1 simulator WITH CloudKit entitlements
# (simulator.entitlements in the __TEXT,__entitlements section, as Xcode does
# for simulator builds; a signature carrying them is refused by simctl spawn)
# on a device with no iCloud account, runs it on
# a throwaway iPhone 16 (simctl spawn, under /tmp/conformance_sim.lock) and
# writes transcript-ios26.1.txt.
set -eu
cd "$(dirname "$0")"
source ../sim_lock.zsh
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-${TMPDIR:-/tmp}/guestcloudkitprobe}
mkdir -p "$OUT"
xcrun --sdk iphonesimulator swiftc -parse-as-library -target arm64-apple-ios26.1-simulator \
  -sdk "$SDK" main.swift -o "$OUT/guestcloudkitprobe" \
  -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __entitlements -Xlinker simulator.entitlements
codesign -f -s - "$OUT/guestcloudkitprobe"
DEV=
cleanup() {
  if [[ -n "$DEV" ]]; then
    xcrun simctl shutdown "$DEV" >/dev/null 2>&1 || true
    xcrun simctl delete "$DEV" >/dev/null 2>&1 || true
  fi
  sim_lock_release
}
trap cleanup EXIT
sim_lock_acquire
DEV=$(xcrun simctl create "iPhone 16-guestcloudkitprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 120 xcrun simctl spawn "$DEV" "$OUT/guestcloudkitprobe" > transcript-ios26.1.txt
cat transcript-ios26.1.txt
