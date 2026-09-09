#!/bin/zsh
# Reproduces every measurement in docs/agent_reports/objc-implementation-spike.md.
#   Tools/objc_impl_spike/run.sh            # macOS host: build, run, chain probes, compile probe
#   RUN_SIM=1 Tools/objc_impl_spike/run.sh  # additionally build for the iOS simulator and
#                                           # run inside a throwaway iOS 26.1 device
# Every step runs in the foreground with a timeout. Exit status is non-zero
# if any expectation below is not met.
set -u
cd "$(dirname "$0")" || exit 1
fail=0
step() { print -- "\n== $1 =="; }

step "macOS build"
timeout 300 swift build 2>&1 | grep -E "error|Build complete" | sort -u
BIN=.build/debug/OUIProbeMain
[[ -x $BIN ]] || { echo "build failed"; exit 1; }

step "macOS run (ObjC + Swift scenarios; expect ALL PASS)"
timeout 60 $BIN; [[ $? -eq 0 ]] || fail=1

step "chain B: ObjC leaf under a vtable-free Swift middle class (expect SURVIVED)"
timeout 60 $BIN B; [[ $? -eq 0 ]] || fail=1

step "chain A: ObjC leaf under a Swift middle class with a vtable entry (expect SIGSEGV, exit 139)"
timeout 60 $BIN A; rc=$?; echo "exit=$rc"; [[ $rc -eq 139 ]] || fail=1

step "compile probe: non-final Swift-only members in the @implementation extension (expect 3 errors)"
n=$(timeout 300 swift build -Xswiftc -DOUIPROBE_NONFINAL 2>&1 | grep -c "does not match any .* declared in the headers")
echo "errors=$n"; [[ $n -ge 3 ]] || fail=1
timeout 300 swift build >/dev/null 2>&1   # restore the normal build

if [[ ${RUN_SIM:-0} == 1 ]]; then
  step "iOS simulator build (arm64-apple-ios-simulator)"
  SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
  timeout 300 swift build --scratch-path .build-sim --triple arm64-apple-ios26.1-simulator \
    -Xswiftc -sdk -Xswiftc "$SDK" -Xcc -isysroot -Xcc "$SDK" 2>&1 | grep -E "error|Build complete" | sort -u
  SBIN=$PWD/.build-sim/arm64-apple-ios-simulator/debug/OUIProbeMain
  [[ -x $SBIN ]] || { echo "simulator build failed"; exit 1; }
  SUFFIX=${SIM_DEVICE_SUFFIX:--objc-impl-spike}
  DEV=$(xcrun simctl create "iPhone 16$SUFFIX" "iPhone 16" "com.apple.CoreSimulator.SimRuntime.iOS-26-1") || exit 1
  step "iOS simulator run in $DEV"
  timeout 180 xcrun simctl boot "$DEV"; timeout 120 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
  timeout 60 xcrun simctl spawn "$DEV" "$SBIN"; [[ $? -eq 0 ]] || fail=1
  timeout 60 xcrun simctl spawn "$DEV" "$SBIN" B; [[ $? -eq 0 ]] || fail=1
  timeout 60 xcrun simctl spawn "$DEV" "$SBIN" A; rc=$?; echo "chain A exit=$rc"; [[ $rc -ne 0 ]] || fail=1
  xcrun simctl shutdown "$DEV" >/dev/null 2>&1
  xcrun simctl delete "$DEV" && echo "deleted $DEV"
fi

print -- "\nRESULT: $([[ $fail -eq 0 ]] && echo OK || echo MISMATCH)"
exit $fail
