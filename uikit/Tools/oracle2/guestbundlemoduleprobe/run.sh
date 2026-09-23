#!/bin/zsh
# guestbundlemoduleprobe -- the Apple side of Tools/guestprobes/GuestBundleModuleProbe.
#
# Generates the accessor with full/xcodeplan/swiftpm_resource_accessor.py (the
# text Xcode 26.1 writes), builds main.swift + accessor for the iOS 26.1
# simulator, stages GuestProbe_GuestBundleModuleProbe.bundle beside the
# executable, runs it on a throwaway iPhone 16 (simctl spawn, under
# /tmp/conformance_sim.lock) and writes transcript-ios26.1.txt.
set -eu
cd "$(dirname "$0")"
source ../sim_lock.zsh
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-${TMPDIR:-/tmp}/guestbundlemoduleprobe}
rm -rf "$OUT"; mkdir -p "$OUT"
python3 ../../../../full/xcodeplan/swiftpm_resource_accessor.py \
  GuestProbe_GuestBundleModuleProbe "$OUT/resource_bundle_accessor.swift"
xcrun --sdk iphonesimulator swiftc -parse-as-library -module-name GuestBundleModuleProbe \
  -target arm64-apple-ios26.1-simulator -sdk "$SDK" \
  main.swift "$OUT/resource_bundle_accessor.swift" -o "$OUT/GuestBundleModuleProbe"
cp -R GuestProbe_GuestBundleModuleProbe.bundle "$OUT/"
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
DEV=$(xcrun simctl create "iPhone 16-guestbundlemoduleprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 120 xcrun simctl spawn "$DEV" "$OUT/GuestBundleModuleProbe" > transcript-ios26.1.txt
cat transcript-ios26.1.txt
