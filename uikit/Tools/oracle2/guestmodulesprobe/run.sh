#!/bin/zsh
# guestmodulesprobe -- the Apple side of Tools/guestprobes/GuestModulesProbe.
#
# Builds main.swift for the iOS 26.1 simulator WITHOUT keychain entitlements
# (the guest has no keychain, and answers as such a process does), runs it on
# a throwaway iPhone 16 (simctl spawn, under /tmp/conformance_sim.lock) and
# writes transcript-ios26.1.txt.
set -eu
cd "$(dirname "$0")"
source ../sim_lock.zsh
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-${TMPDIR:-/tmp}/guestmodulesprobe}
mkdir -p "$OUT"
xcrun --sdk iphonesimulator swiftc -parse-as-library -target arm64-apple-ios26.1-simulator \
  -sdk "$SDK" main.swift -o "$OUT/guestmodulesprobe"
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
DEV=$(xcrun simctl create "iPhone 16-guestmodulesprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 120 xcrun simctl spawn "$DEV" "$OUT/guestmodulesprobe" > transcript-ios26.1.txt
cat transcript-ios26.1.txt
