#!/bin/bash
# On-box arm64 verify. Runs INSIDE the checked-out tree (run_box.sh's document
# has already fetched the bundle and checked out the sha). This is the operator's
# proven sequence from 2026-09-02/03 (formerly /tmp/verify_m45.sh), committed so
# the runner cannot drift from it:
#   stash libswiftCore + remove the staged libswiftcompat (a stale copy
#   duplicates real darwin definitions in build.sh's CHECK 4) → build.sh all →
#   park test → gen_tbd --check → check_stale → run_linux → difftest →
#   restore libswiftCore → stage_swiftcore → build_full → refresh the sysroot
#   libSystem.tbd → Gate B (Focus widget) with the box-staged resource bundle.
set -u
export HOME=${HOME:-/root}
export PATH=/opt/swift624/usr/bin:/usr/local/bin:/usr/bin:/bin
TREE=${1:-$(pwd)}
cd "$TREE" || exit 2
W=$(dirname "$TREE")
H=$(git rev-parse HEAD)
echo "main $H"
echo "pins: uikit=$(grep EXPECTED_INREPO_UIKIT_TREE scripts/vendor_pins.sh | cut -d= -f2 | cut -c1-8) live=$(git rev-parse HEAD:uikit | cut -c1-8) machorun=$(git rev-parse HEAD:machorun | cut -c1-8)"
cd machorun || exit 2
SC=darwin/usr/lib/swift/libswiftCore.dylib
[ -f "$SC" ] && mv "$SC" /tmp/libswiftCore.stash && echo "stashed libswiftCore (not part of master darwin tree)"
[ -f darwin/usr/lib/libswiftcompat.dylib ] && rm -f darwin/usr/lib/libswiftcompat.dylib && echo "removed staged libswiftcompat before build.sh (re-staged by stage_swiftcore after the tests)"
echo "== build.sh all"; bash scripts/build.sh > "$W/verify-build.log" 2>&1 && echo BUILD_OK || { echo BUILD_FAIL; grep -E '^!!|PLAIN|CHECK' "$W/verify-build.log" | tail -6; }
echo "== test_check_undefined_park"; bash scripts/test_check_undefined_park.sh > "$W/verify-park.log" 2>&1; echo "park rc=$?"; tail -1 "$W/verify-park.log"
echo "== gen_tbd --check"; bash scripts/gen_tbd.sh --check > "$W/verify-tbd.log" 2>&1 && echo TBD_CHECK_OK || { echo TBD_CHECK_FAIL; grep -E '^!!|CHECK [0-9]' "$W/verify-tbd.log" | tail -6; }
echo "== check_stale"; bash scripts/check_stale.sh 2>&1 | tail -1
echo "== run_linux"; bash harness/run_linux.sh > "$W/verify-runlinux.log" 2>&1; echo "run_linux rc=$?"; tail -3 "$W/verify-runlinux.log"
echo "== difftest"; bash scripts/difftest.sh > "$W/verify-difftest.log" 2>&1; echo "difftest rc=$?"
grep -E ' FAIL ' "$W/verify-difftest.log" | head -10
grep -E '^pass ' "$W/verify-difftest.log"
[ -f /tmp/libswiftCore.stash ] && install -d darwin/usr/lib/swift && mv /tmp/libswiftCore.stash "$SC" && echo "restored libswiftCore for the platform gate"
echo "== stage_swiftcore (libswiftcompat + libswiftCore from swiftcore-macho/artifacts)"
bash scripts/stage_swiftcore.sh "$TREE/swiftcore-macho/artifacts" > "$W/verify-stage.log" 2>&1; echo "stage_swiftcore rc=$?"; tail -4 "$W/verify-stage.log"
cd "$TREE"
echo "== build_full.sh (stage mrroot_full from this machorun; rebuild umbrellas)"
build_full_rc=0
bash full/scripts/build_full.sh > "$W/build_full.log" 2>&1 || build_full_rc=$?
echo "build_full rc=$build_full_rc"
grep -E "^build_full:|error:|FAIL|umbrella|OK$|ObservationMacros" "$W/build_full.log" | tail -12 | sed 's/^/build_full: /'
echo "build_full: --- log tail ---"
tail -40 "$W/build_full.log" | sed 's/^/build_full: /'
cp machorun/sdk/usr/lib/libSystem.tbd scratch/sysroot_fe4/usr/lib/libSystem.tbd
echo "== guest realapp (expect 12 screens)"
if [ "$build_full_rc" -ne 0 ]; then
  echo "guest_realapp skipped (build_full rc=$build_full_rc)"
  echo "build_full: GUEST_REALAPP_SCREENS=0"
else
mkdir -p "$W/guest-realapp"
# Prefer the rebuilt $OUT/host helper (has create_queue). The staged
# scratch/mrroot_full/host copy is what build_full copies from BASE and
# lacks that export (attempt 10, c8faae90, GUEST_REALAPP_SCREENS=3).
HOST_SO="$TREE/build/full/host"
if [ ! -f "$HOST_SO/libOpenDispatchHost.so" ]; then
  HOST_SO="$TREE/scratch/mrroot_full/host"
fi
echo "build_full: GUEST_REALAPP_HOST_SO=$HOST_SO"
# Preload stays inside this subshell so GATE_B's widget guest is not
# affected (widget guest sets its own LD_PRELOAD).
(
  cd "$TREE/build/full"
  export MACHORUN_ROOT="$TREE/scratch/mrroot_full"
  if [ -f "$HOST_SO/libOpenDispatchHost.so" ]; then
    export LD_LIBRARY_PATH="$HOST_SO${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export LD_PRELOAD="$HOST_SO/libOpenDispatchHost.so:$HOST_SO/libOpenFoundationInternationalizationHost.so:$HOST_SO/libOpenURLTransportHost.so:$HOST_SO/libOpenRelativeTimeHost.so"
  fi
  OPENUIKIT_RESOURCE_ROOT="$TREE/uikit/Sources/OpenUIKit/Resources" \
  OPENUIKIT_FONT_DIR="$TREE/scratch/fonts" \
  OPENUIKIT_BACKEND=quartz OPENUIKIT_FORCE_IOS=1 \
  "$TREE/scratch/mrroot_full/machorun" ./render_full realapp "$W/guest-realapp" \
    "$TREE/uikit/fixtures/realapp/assets"
) > "$W/guest-realapp.log" 2>&1
echo "build_full: GUEST_REALAPP_RC=$?"
grep -E '^rendered realapp_|^\[render_full\] realapp|Fatal error|UINib:' "$W/guest-realapp.log" | tail -30 \
    | sed 's/^/build_full: realapp: /'
echo "build_full: GUEST_REALAPP_SCREENS=$(ls "$W/guest-realapp"/*.png 2>/dev/null | wc -l | tr -d ' ')"
echo "build_full: --- guest realapp log ---"
tail -30 "$W/guest-realapp.log" | sed 's/^/build_full: realapp: /'
fi
P=$(ls -d /tmp/focus-widget-res.* 2>/dev/null | head -1); B="$P/output/bundles/Focus_Widget.bundle"
[ -d "$B" ] || { echo "GATE_B_FAIL rc=2 (no staged Focus_Widget.bundle under /tmp/focus-widget-res.*)"; exit 2; }
echo "== GATE B (widget guest) on $H"
if bash full/swiftui/build_focus_widget_guest.sh "$B" > "$W/widget-gate.log" 2>&1; then echo GATE_B_PASS; else echo "GATE_B_FAIL rc=$?"; fi
grep -vE 'warning:|^ *[0-9]+ \||^ *\|' "$W/widget-gate.log" | tail -22
