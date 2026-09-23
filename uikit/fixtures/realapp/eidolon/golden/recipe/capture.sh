#!/bin/bash
# Eidolon (artsy/eidolon 44486ed) iOS 26.1 simulator golden of the FIRST SCREEN.
# Builds the unmodified app sources/storyboards with Xcode 26.1 against
# iPhoneSimulator26.1 via CocoaPods (lock versions), launches on a throwaway
# iPad, captures screenshots + a native-scale window render + a view dump,
# then deletes the device. Read-only input: $SRC. Everything else under $G.
#
# Deviations (see Podfile.golden, step_patch.sh, KeysPod/, *Shim/):
#   Keys (cocoapods-keys) -> generated pod, oss_keys "-" values
#   CardFlight-v4 4.3.1   -> CardFlightShim (call-site-derived, fail-closed)
#   Stripe 12.1.0/14.0.1  -> StripeShim (fail-closed)
#   HockeySDK-Source + ARAnalytics/HockeyApp -> omitted (no arm64-sim slice)
#   RxCocoa 4.1.2         -> 2 redundant pass-through inits deleted (compile)
#   IPHONEOS_DEPLOYMENT_TARGET=12.0, ARCHS=arm64 (xcodebuild overrides)
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd)"   # this recipe dir (inputs, committed)
G="${EIDOLON_GOLDEN_WORK:?set EIDOLON_GOLDEN_WORK to a scratch dir}"   # outputs
mkdir -p "$G/logs" "$G/shots"

bash "$R/step_pods.sh" > /dev/null          # copy checkout, Podfile override, Keys, pod install (CI=1)
bash "$R/step_patch.sh"                       # RxCocoa compile-only patch
bash "$R/step_build.sh"                       # xcodebuild -> work/derived/.../Kiosk.app

# Serialize simulator work across agents: mkdir-style lock with a pid file,
# same protocol as uikit/scripts/conformance_probe_sim.sh.
SIM_LOCK=/tmp/conformance_sim.lock
while ! mkdir "$SIM_LOCK" 2>/dev/null; do
  holder=$(cat "$SIM_LOCK/pid" 2>/dev/null || true)
  if [[ -n "$holder" ]] && ! kill -0 "$holder" 2>/dev/null; then rm -rf "$SIM_LOCK"; continue; fi
  echo "capture.sh: waiting for $SIM_LOCK (pid ${holder:-?})" >&2
  sleep 15
done
echo $$ > "$SIM_LOCK/pid"
rm -f "$G/work/udid"
cleanup() {
  if [[ -f "$G/work/udid" ]]; then
    xcrun simctl shutdown "$(cat "$G/work/udid")" 2>/dev/null || true
    xcrun simctl delete "$(cat "$G/work/udid")" 2>/dev/null || true
  fi
  rm -rf "$SIM_LOCK"
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM HUP

bash "$R/step_run.sh"                         # device create/boot/install/launch + t=2,5,15,30s shots

UDID=$(cat "$G/work/udid")
PID=$(cat "$G/work/pid")
xcrun lldb -p "$PID" -s "$R/dump.lldb" > "$G/logs/lldb-dump.txt" 2>&1 || true
xcrun lldb -p "$PID" -s "$R/orient.lldb" > "$G/logs/lldb-orient.txt" 2>&1 || true
xcrun lldb -p "$PID" -s <(sed "s|__SHOTS__|$G/shots|" "$R/render.lldb") > "$G/logs/lldb-render.txt" 2>&1 || true

kill "$(cat "$G/work/logpid")" 2>/dev/null || true
# Shut down + delete the device and release the lock now: the lock covers
# only boot -> capture -> shutdown.
cleanup
rm -f "$G/work/udid"
trap - EXIT INT TERM HUP
( cd "$G/shots" && shasum -a 256 *.png && for f in *.png; do echo "$f $(sips -g pixelWidth -g pixelHeight "$f" | tail -2 | awk '{print $2}' | tr '\n' 'x')"; done )
