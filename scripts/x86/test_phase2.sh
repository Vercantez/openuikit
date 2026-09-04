#!/usr/bin/env bash
# Static teeth for the x86_64 PHASE 2 runner. Does not execute guests.
# Run from the openuikit tree: bash scripts/x86/test_phase2.sh
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
pass=0
fail=0

die_test() {
    echo "FAIL: $*" >&2
    fail=$((fail + 1))
}
ok() {
    echo "PASS: $*"
    pass=$((pass + 1))
}

expect_file() {
    local f=$1
    [ -f "$f" ] && ok "present $f" || die_test "missing $f"
}

expect_grep() {
    local needle=$1 file=$2 label=$3
    if grep -q -- "$needle" "$file"; then
        ok "$label"
    else
        die_test "$label (missing in $file: $needle)"
    fi
}

expect_not_grep() {
    local needle=$1 file=$2 label=$3
    if grep -q -- "$needle" "$file"; then
        die_test "$label (forbidden in $file: $needle)"
    else
        ok "$label"
    fi
}

PHASE2=$ROOT/scripts/x86/phase2.sh
COMMON=$ROOT/scripts/x86/common.inc
STAGE=$ROOT/scripts/x86/stage_fe_sysroot.sh
UDINC=$ROOT/scripts/x86/ud_guest.inc
OC=$ROOT/scripts/x86/build_opencombine.sh
GUEST=$ROOT/full/scripts/guest_arch.inc
WIDGET=$ROOT/full/swiftui/build_focus_widget_guest.sh
ONBOARD=$ROOT/full/swiftui/build_focus_onboarding_guest.sh
REMINDER=$ROOT/full/xcodeplan/build_and_run_reminder_scene_guest.sh
UD_RUNNER=$ROOT/foundation-macho/tests/ud_guest_runner.swift
PREPARE=$ROOT/scripts/env/prepare.py
BUILD_FULL=$ROOT/full/scripts/build_full.sh
INVENTORIES=$ROOT/full/swiftui/guest_gate_inventories.py
INVENTORIES_INC=$ROOT/full/swiftui/guest_gate_inventories.inc
X86_ORACLE=$ROOT/full/swiftui/test_guest_gate_inventories_x86_oracle.sh

expect_file "$PHASE2"
expect_file "$COMMON"
expect_file "$STAGE"
expect_file "$OC"
expect_file "$GUEST"
expect_file "$INVENTORIES"
expect_file "$INVENTORIES_INC"
expect_file "$X86_ORACLE"

echo "== bash -n"
for s in "$PHASE2" "$STAGE" "$OC" "$COMMON" "$ROOT/scripts/x86/test_phase2.sh" \
    "$ROOT/scripts/x86/stamp.inc" \
    "$ROOT/scripts/x86/test_stamp.sh" \
    "$ROOT/scripts/x86/test_stage_fe_sysroot_matches_main.sh" \
    "$ROOT/scripts/x86/test_no_existence_reuse.sh" \
    "$ROOT/scripts/ops/x86_cycle.sh" \
    "$ROOT/scripts/ops/run_box.sh" \
    "$ROOT/scripts/ops/premerge.sh" \
    "$ROOT/scripts/ops/test_ops.sh" \
    "$ROOT/scripts/ops/common.inc" \
    "$ROOT/full/foundation/fe_sysroot_measurement.inc" \
    "$ROOT/full/dispatch/swift_linux_lib.inc" \
    "$ROOT/full/urltransport/build_host_helper.sh" \
    "$ROOT/full/relativetime/build_host_helper.sh" \
    "$ROOT/full/foundationinternationalization/build_host_helper.sh" \
    "$ROOT/scripts/x86/ud_guest.inc" \
    "$ROOT/foundation-macho/scripts/link_ud_guest.sh" \
    "$ROOT/foundation-macho/scripts/build_ud_score_guest.sh" \
    "$ROOT/foundation-macho/scripts/run_ud_guest.sh" \
    "$ROOT/foundation-macho/scripts/run_ud_persist.sh" \
    "$ROOT/foundation-macho/scripts/ud_dispatch_run.inc" \
    "$ROOT/foundation-macho/scripts/test_link_ud_guest.sh" \
    "$ROOT/foundation-macho/scripts/test_build_ud_score_guest.sh" \
    "$ROOT/foundation-macho/scripts/test_run_ud_guest.sh" \
    "$ROOT/foundation-macho/scripts/check_cftest_stubs.sh" \
    "$ROOT/foundation-macho/scripts/test_build_cftest_harness.sh" \
    "$ROOT/scripts/x86/gen_swift_tbd.sh" \
    "$ROOT/scripts/x86/test_gen_swift_tbd.sh" \
    "$ROOT/scripts/x86/ensure_machorun.sh" \
    "$ROOT/full/swiftui/guest_gate_inventories.inc" \
    "$ROOT/full/swiftui/test_guest_gate_inventories_x86_oracle.sh" \
    "$ROOT/scripts/build_runtime_shims.sh" \
    "$ROOT/swiftcore-macho/scripts/test_compat_source.sh"; do
    if bash -n "$s"; then
        ok "bash -n $(basename "$s")"
    else
        die_test "bash -n $(basename "$s")"
    fi
done

echo "== operator command + marker grammar"
expect_grep 'bash scripts/x86/phase2.sh /opt/openuikit/x86-verify/openuikit' "$PHASE2" \
    "operator one-command path"
expect_grep 'ENV_PREPARE' "$COMMON" "ENV_PREPARE helper"
expect_grep 'Column 2 is cputype' "$COMMON" "x86 Mach-O check documents cputype column"
expect_grep 'RUNG_SCOREBOARD' "$PHASE2" "RUNG_SCOREBOARD"
expect_grep 'ENV_PREPARE_SUMMARY' "$PHASE2" "ENV_PREPARE_SUMMARY"
expect_grep 'never overwrite' "$PHASE2" "arm64 overwrite refusal in header"
expect_grep 'stamp_reuse' "$PHASE2" \
    "machorun substrate reuse goes through stamp_reuse"
expect_grep 'stamp_write' "$PHASE2" \
    "cold-build writes <out>.inputs-sha256"
expect_grep 'reused=1' "$PHASE2" "satisfied loader/darwin/objc4/quartz/tbd print reused=1"
expect_grep 'stamp_rebuild_reason' "$PHASE2" "cold-built prints rebuilt reason= via stamp.inc"

echo "== stamp.inc (content hash, not existence)"
# shellcheck source=stamp.inc
. "$ROOT/scripts/x86/stamp.inc"
STAMP_FIX=$(mktemp -d /tmp/phase2-stamp-inc.XXXXXX)
python3 - "$STAMP_FIX/loader" <<'PY'
import pathlib, struct, sys
pathlib.Path(sys.argv[1]).parent.mkdir(parents=True, exist_ok=True)
# ELF-looking is not required here; stamp unit test covers Mach-O. Touch a file
# and rely on test_stamp.sh for kind checks.
pathlib.Path(sys.argv[1]).write_bytes(b"not-a-product")
PY
printf 'input\n' > "$STAMP_FIX/src.c"
key=$(stamp_key "$STAMP_FIX/loader" "$STAMP_FIX/src.c")
if stamp_reuse "$STAMP_FIX/loader" "$key" 2>/dev/null; then
    die_test "existence without .inputs-sha256 reused"
else
    ok "missing .inputs-sha256 does not reuse"
fi
rm -rf "$STAMP_FIX"

echo "== denominators (committed runners, not invented)"
smoke=$(grep -c '^check(' "$UD_RUNNER" || true)
if [ "$smoke" = 14 ]; then
    ok "ud_guest_runner.swift has 14 check() calls"
else
    die_test "ud_guest_runner.swift check() count is $smoke, not 14"
fi
expect_grep 'UD_SMOKE_CHECKS=14' "$PHASE2" "phase2 hard-codes the committed 14"
expect_grep 'windows=1 turns=3 paced=true' "$PHASE2" "reminder success bar in scoreboard"
expect_grep 'PORTABLE_UIKIT_HOST_ACTIVE windows=1' "$PHASE2" "reminder window marker"
expect_grep 'PORTABLE_UIKIT_HOST_LOOP_OK turns=3 paced=true' "$PHASE2" "reminder turns marker"

echo "== libswiftCore measured first"
# The measure section must appear before FoundationEssentials / OpenCombine / rungs.
awk '
    /measure libswiftCore-for-x86/ { m=NR }
    /FoundationEssentials \/ collections/ { fe=NR }
    /OpenCombine x86/ { oc=NR }
    /==== rungs/ { r=NR }
    END {
        if (!m) { print "NO_MEASURE"; exit 1 }
        if (!(m<fe && m<oc && m<r)) { print "ORDER m="m" fe="fe" oc="oc" r="r; exit 1 }
        print "OK"
    }
' "$PHASE2" | grep -q OK && ok "libswiftCore measured before FE/OpenCombine/rungs" \
    || die_test "libswiftCore measurement is not first"

expect_grep 'BUILD_LIBSWIFTCORE_X86' "$PHASE2" "canonical libswiftCore CANNOT marker"
expect_grep 'Do not stage the arm64 dylib under an x86 name' "$PHASE2" \
    "refuse renaming arm64 libswiftCore"

echo "== x86 trees beside arm64, never on top"
expect_grep 'scratch/sysroot_fe4-x86_64' "$STAGE" "x86 sysroot suffix in stager"
expect_grep 'refusing to write unsuffixed sysroot' "$STAGE" "stager refuses unsuffixed SYS"
expect_grep 'skip arm64 Mach-O' "$STAGE" "stager skips arm64 dylibs"
expect_grep 'export-x86_64' "$OC" "OpenCombine x86 export beside durable export/"
expect_grep 'Never writes scratch/opencombine-core-durable' "$OC" \
    "OpenCombine does not rewrite durable export/"
expect_grep 'SYSROOT_SUFFIX' "$GUEST" "guest_arch SYSROOT_SUFFIX"
expect_grep 'OPENCOMBINE_EXPORT_SUFFIX' "$GUEST" "guest_arch OPENCOMBINE_EXPORT_SUFFIX"
expect_grep 'sysroot_fe4${FULL_OUT_SUFFIX}' "$BUILD_FULL" "build_full SYS suffix"
expect_grep 'require_macho_cpu "$swift_core_target"' "$BUILD_FULL" \
    "build_full refuses foreign libswiftCore"
expect_grep 'NEEDS_X86_OPENCOMBINE' "$WIDGET" "widget keeps NEEDS_X86_OPENCOMBINE"
expect_grep 'export${FULL_OUT_SUFFIX}/artifacts' "$WIDGET" "widget OpenCombine suffix"
expect_grep 'export${FULL_OUT_SUFFIX}/artifacts' "$ONBOARD" "onboarding OpenCombine suffix"
expect_grep 'export${FULL_OUT_SUFFIX}/RESULT.txt' "$WIDGET" "widget OpenCombine RESULT suffix"
expect_grep 'export${FULL_OUT_SUFFIX}/RESULT.txt' "$ONBOARD" "onboarding OpenCombine RESULT suffix"
expect_grep 'export FULL_OUT_SUFFIX' "$GUEST" "guest_arch exports FULL_OUT_SUFFIX for prepare.py"
expect_grep 'export FULL_OUT_SUFFIX' "$WIDGET" "widget re-exports FULL_OUT_SUFFIX before prepare"
expect_grep 'BASE_RUNTIME_SOURCE=${BASE_RUNTIME_SOURCE:-$W/scratch/mrroot${FULL_OUT_SUFFIX}}' \
    "$BUILD_FULL" "build_full BASE_RUNTIME_SOURCE honours FULL_OUT_SUFFIX"
expect_grep 'FE_RUNTIME_SOURCE=${FE_RUNTIME_SOURCE:-$W/scratch/mrroot_fe${FULL_OUT_SUFFIX}}' \
    "$BUILD_FULL" "build_full FE_RUNTIME_SOURCE honours FULL_OUT_SUFFIX"
expect_grep 'EXPECTED_OPENCOMBINE_OBJECT_SHA=96558e7d31c10c4bc769e9774977b74c58dc6ee83cfbd4fca8bf17229424a914' \
    "$WIDGET" "arm64 OpenCombine object SHA still stands"
expect_grep 'if \[ "$ARCH" = arm64 \]; then' "$WIDGET" \
    "widget hashes OpenCombine.o only on arm64"

echo "== reminder: x86-on-x86 must not refuse; native path skips docker"
expect_grep 'x86_64 guests on an x86_64 host are the phase-2 path' "$REMINDER" \
    "reminder documents x86-on-x86"
expect_not_grep 'if \[ "$(uname -m)" != aarch64 \] && \[ "$(uname -m)" != arm64 \]; then' \
    "$REMINDER" "reminder no longer refuses every non-aarch64 host"
expect_grep 'if \[ "$ARCH" = "$host_arch" \]' "$REMINDER" \
    "reminder native host skip-docker"
expect_grep 'if \[ "$ARCH" = arm64 \] && \[ "$(uname -m)" != aarch64 \]' \
    "$ROOT/full/frameworks/run_core_guest_package_docker.sh" \
    "core-package docker wrapper does not refuse x86-on-x86"
expect_grep 'sysroot_fe4${FULL_OUT_SUFFIX}' "$REMINDER" "reminder SYS suffix"
expect_grep 'local uikit=${UIKIT:-/uikit}' "$REMINDER" "reminder UIKIT override"

echo "== phase2 does not source machorun guest_arch (macos11 must not clobber macos15)"
if grep -n 'machorun/scripts/guest_arch.inc' "$PHASE2" | grep -v '^#' >/dev/null; then
    # A comment is fine; an actual source is not.
    if grep -E '^[[:space:]]*\. .*/machorun/scripts/guest_arch.inc' "$PHASE2" >/dev/null; then
        die_test "phase2 sources machorun guest_arch.inc (would clobber TARGET)"
    else
        ok "phase2 does not source machorun guest_arch.inc"
    fi
else
    ok "phase2 does not mention machorun guest_arch.inc"
fi
expect_grep 'full/scripts/guest_arch.inc' "$PHASE2" "phase2 sources full/ guest_arch"

echo "== usage refuse"
set +e
out=$(bash "$PHASE2" 2>&1)
rc=$?
set -e
if [ "$rc" -eq 2 ] && echo "$out" | grep -q 'usage: bash scripts/x86/phase2.sh'; then
    ok "phase2 with no args exits 2 with usage"
else
    die_test "phase2 no-args rc=$rc out=$(echo "$out" | head -2)"
fi

echo "== focus-pin probe (nested git root + expected/observed + git_error)"
if grep -F '[ -d "$FOCUS_REPO/.git" ]' "$PHASE2" >/dev/null; then
    die_test "phase2 still gates on FOCUS_REPO/.git (app subtree is not the git root)"
else
    ok "phase2 does not require a .git directory on the Focus app subtree"
fi
expect_grep 'rev-parse --show-toplevel' "$COMMON" \
    "probe resolves git toplevel before comparing HEAD"
expect_grep 'safe.directory=' "$COMMON" \
    "probe sets explicit safe.directory"
expect_grep 'expected=%s observed=' "$COMMON" \
    "ERROR line names expected and observed"
expect_grep 'expected=%s observed=%s' "$COMMON" \
    "MISMATCH line names expected and observed"

# shellcheck source=common.inc
. "$COMMON"

PIN=a2832521c1daa0c23419c73705ae043ed60c9791
WORK=$(mktemp -d /tmp/phase2-focus-pin.XXXXXX)
cleanup_focus_pin() { rm -rf "$WORK"; }
trap cleanup_focus_pin EXIT
mkdir -p "$WORK/focus-ios/focus-ios"
# Empty global config: simulate the host where $HOME-driven safe.directory
# was never set. The probe's -c safe.directory=*parents must still work.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
git -c safe.directory="$WORK/focus-ios" -c init.defaultBranch=main init "$WORK/focus-ios" >/dev/null 2>&1
git -C "$WORK/focus-ios" \
    -c safe.directory="$WORK/focus-ios" \
    -c user.email=phase2@test -c user.name=phase2 \
    commit --allow-empty -m pin >/dev/null 2>&1
git -C "$WORK/focus-ios" \
    -c safe.directory="$WORK/focus-ios" \
    commit --allow-empty --amend --no-edit \
    --date=1970-01-01T00:00:00Z >/dev/null 2>&1 || true
# Nested app subtree has no .git of its own.
[ ! -e "$WORK/focus-ios/focus-ios/.git" ] || die_test "fixture child unexpectedly has .git"
HEAD=$(git -c safe.directory="$WORK/focus-ios" -C "$WORK/focus-ios" rev-parse HEAD)

report=$(phase2_probe_focus_pin "$WORK/focus-ios/focus-ios" "$HEAD" || true)
case "$report" in
    MATCH*"observed=$HEAD"*) ok "nested git root MATCH observed=$HEAD" ;;
    *) die_test "nested MATCH expected, got: $report" ;;
esac

mismatch=$(phase2_probe_focus_pin "$WORK/focus-ios/focus-ios" "$PIN" || true)
case "$mismatch" in
    MISMATCH*"expected=$PIN"*"observed=$HEAD"*)
        ok "nested MISMATCH names expected=$PIN observed=$HEAD"
        ;;
    *) die_test "nested MISMATCH expected, got: $mismatch" ;;
esac

missing=$(phase2_probe_focus_pin "$WORK/absent" "$PIN" || true)
case "$missing" in
    ERROR*"expected=$PIN"*"observed=ABSENT"*)
        ok "missing dir ERROR names expected and observed=ABSENT"
        ;;
    *) die_test "missing ERROR expected, got: $missing" ;;
esac

nogit=$(phase2_probe_focus_pin "$WORK" "$PIN" || true)
case "$nogit" in
    ERROR*"expected=$PIN"*"observed=ERROR"*"git_error="*)
        ok "non-repo ERROR includes git_error instead of folding into not-at-pin"
        ;;
    *) die_test "non-repo ERROR expected, got: $nogit" ;;
esac

echo "== sysroot: input-keyed restage, Darwin modulemaps, Swift into usr/lib/swift"
expect_grep 'gen_darwin_modulemap.py' "$STAGE" \
    "stager runs gen_darwin_modulemap.py against the x86 sysroot"
expect_grep 'usr/lib/swift/libswiftCore.dylib' "$STAGE" \
    "stager copies libswiftCore into usr/lib/swift"
expect_grep '_Builtin_float.swiftmodule' "$STAGE" \
    "stager copies _Builtin_float into usr/lib/swift"
expect_grep 'phase2_write_sysroot_stamp' "$STAGE" \
    "stager writes an input stamp"
expect_grep 'phase2_sysroot_overlay_if' "$STAGE" \
    "stager hashes the same Darwin.swiftinterface the restage check hashes"
expect_grep 'phase2_sysroot_overlay_if' "$PHASE2" \
    "restage check hashes artifacts Darwin.swiftinterface when arm64 overlay is absent"
expect_grep 'phase2_sysroot_dmap_input' "$STAGE" \
    "stager stamps the arm64 Darwin.modulemap path, not the dest"
expect_grep 'phase2_sysroot_dmap_input' "$PHASE2" \
    "restage check stamps the arm64 Darwin.modulemap path, not the dest"
expect_not_grep 'dmap_for_stamp=$SYS/usr/include/Darwin.modulemap' "$STAGE" \
    "stager does not hash the dest Darwin.modulemap (that was HASH->ABSENT every run)"
expect_grep 're-stage sysroot-fe4-x86 (input changed:' "$PHASE2" \
    "phase2 restages when input shas change and prints which"
expect_grep 'DARWIN_CLANG_MODULEMAP' "$PHASE2" \
    "missing Darwin.modulemap is its own CANNOT, not folded into overlays"
expect_grep 'DARWIN_MODULEMAP_HEADERS' "$PHASE2" \
    "missing modulemap header files are CANNOT_DARWIN_MODULEMAP_HEADERS"
expect_grep 'stage_fe_sysroot_x86.20' "$COMMON" \
    "recipe bump restages so overlay-copied SYS matches main (VM extras only on *-fe-clang)"
expect_grep 'phase2_apply_vm_only_fe_sysroot' "$COMMON" \
    "VM-only overlay-darwin / ioctl / artifact overlays land on the FE clang sibling"
expect_grep 'overlay-darwin.8' "$ROOT/swiftcore-macho/scripts/overlay_sysroot.inc" \
    "overlay sysroot stamp recipe keys Darwin.modulemap bytes and dest sync"
expect_grep 'overlay_sysroot_sync_darwin_modulemap' "$ROOT/swiftcore-macho/scripts/overlay_sysroot.inc" \
    "overlay finish copies FE Darwin.modulemap onto the SDK dest"
expect_grep 'usr/include/Darwin.modulemap=' "$ROOT/swiftcore-macho/scripts/overlay_sysroot.inc" \
    "overlay stamp hashes FE Darwin.modulemap bytes so a regenerated map restages"
expect_grep 'ensure_machorun_assert_vendor_clean' "$ROOT/scripts/x86/ensure_machorun.sh" \
    "ensure_machorun refuses a dirty machorun vendor subtree"
expect_grep 'status --short --untracked-files=all -- machorun' \
    "$ROOT/scripts/x86/ensure_machorun.sh" \
    "ensure_machorun asserts git status --short machorun is empty"
expect_grep 'x86_cycle_assert_machorun_clean' "$ROOT/scripts/ops/x86_cycle.sh" \
    "x86_cycle asserts git status --short machorun is empty at the end"
expect_grep 'x86_cycle_assert_overlay_darwin_modulemap' "$ROOT/scripts/ops/x86_cycle.sh" \
    "x86_cycle cmps overlay SDK Darwin.modulemap against the overlay-copied sysroot"
expect_grep 'cmp -s "$sys_map" "$sdk_map"' "$ROOT/scripts/ops/x86_cycle.sh" \
    "x86_cycle verifies Darwin.modulemap with cmp"
expect_grep 'fe_sysroot_measurement_headers=' "$COMMON" \
    "stamp records the shared measurement-header list sha"
expect_grep 'phase2_measurement_headers_missing' "$COMMON" \
    "every header in the FileManager/sdk-gap list is checked after restage"
expect_grep 'FE_MEASUREMENT_HEADERS' "$PHASE2" \
    "missing measurement headers are CANNOT_FE_MEASUREMENT_HEADERS"
expect_grep 'phase2_copy_artifact_swift_overlays' "$COMMON" \
    "artifact Darwin overlays are a helper for the FE clang dest on a fresh VM"
expect_not_grep 'phase2_copy_artifact_swift_overlays "$SYS"' "$STAGE" \
    "stager does not copy artifact overlays onto the overlay-copied SYS"
expect_grep 'phase2_stage_fe_clang_sysroot' "$STAGE" \
    "x86 stager expands Darwin.modulemap on an FE-only snapshot, not the overlay-copied sysroot"
expect_not_grep 'phase2_expand_darwin_modulemap_for_fe "$SYS"' "$STAGE" \
    "stager does not expand Darwin.modulemap in-place on the overlay-copied FE sysroot"
expect_grep 'phase2_fe_clang_sysroot' "$PHASE2" \
    "phase2 compiles FE against the expanded clang snapshot"
expect_grep 'SWIFTCORE_FE_SYSROOT' "$ROOT/scripts/ops/x86_cycle.sh" \
    "x86_cycle overlays stage points SWIFTCORE_FE_SYSROOT at the unexpanded sysroot"
expect_grep 'phase2_ensure_swift_onone_support' "$COMMON" \
    "SwiftOnoneSupport stub helper exists for collections without -O"
expect_not_grep 'phase2_ensure_swift_onone_support "$SYS"' "$STAGE" \
    "stager does not stage SwiftOnoneSupport on the overlay-copied SYS"
expect_grep 'overlay-posix' "$COMMON" \
    "POSIX semaphore.h is staged on the FE clang dest; real ioctl stays out of overlay-copied SYS"
expect_not_grep 'overlay-posix' "$STAGE" \
    "stager does not copy overlay-posix onto the overlay-copied SYS"
expect_grep 'fe_ioctl_stub.h' "$COMMON" \
    "ioctl stub is staged on the FE clang dest so SwiftOverlayShims builds"
expect_not_grep 'fe_ioctl_stub.h' "$STAGE" \
    "stager does not write fe_ioctl_stub.h into the overlay-copied SYS"
expect_not_grep 'stage_overlay_darwin.sh "$SYS"' "$STAGE" \
    "stager does not run overlay-darwin on the overlay-copied SYS"
expect_grep 'stage_overlay_darwin.sh' "$COMMON" \
    "overlay-darwin runs against the FE clang dest when Darwin.modulemap is absent"
expect_grep 'phase2_ensure_darwin_named_submodules' "$COMMON" \
    "Darwin.modulemap grows sysdir and uuid submodules for import Darwin.sysdir"
expect_grep 'malloc/malloc.h' "$COMMON" \
    "Darwin.modulemap names malloc_good_size's header for FoundationEssentials Data.swift"
expect_grep 'phase2_ensure_macho_modulemap' "$COMMON" \
    "sysroot grows MachO.dyld for FoundationEssentials Platform.swift"
expect_file "$ROOT/scripts/x86/MachO.modulemap"
expect_grep 'SwiftOverlayShims.timeval' "$COMMON" \
    "sys/time.h is textual so SwiftOverlayShims.timeval is visible"
expect_grep 'sys/time.h|time.h|semaphore.h) kind="textual header"' "$COMMON" \
    "time.h and semaphore.h are textual so SwiftOverlayShims.timespec/sem_t are visible"
expect_grep 'phase2_posix_overlay_dir' "$COMMON" \
    "overlay-posix dir helper exists for Swift -Xcc -I (UD guest)"
expect_file "$ROOT/scripts/x86/fe_ioctl_stub.h"
expect_grep 'phase2_posix_overlay_dir' "$PHASE2" \
    "os-module and FE still receive overlay-posix -I (sysroot stub is what Clang modules see)"
expect_grep 'cannot carry ioctl.h (CFSocket census)' "$ROOT/full/foundation/build_os_module.sh" \
    "build_os_module.sh forwards extra swiftc argv (overlay-posix -I on a VM)"
expect_grep 'rm -rf "${UD_GUEST_W:-$ud_w}/runroot"' "$PHASE2" \
    "rung a drops a stale runroot clone so libCFTest content is fresh"
if [ ! -f "$ROOT/scripts/x86/patch_cf_system_allocator.py" ]; then
    ok "allocator rewrite patcher is gone"
else
    die_test "allocator rewrite patcher still present"
fi
expect_not_grep 'phase2_ud_guest_patch_cf_system_allocator' "$UDINC" \
    "ud-guest does not rewrite CFAllocator isa/TSD (box cold-compile of the pin is the authority)"
expect_not_grep 'cf-system-allocator' "$UDINC" \
    "ud-guest compiles the CF pin, not a patched copy"
expect_grep 'phase2_ud_guest_stage_cf_compile_sdk' "$UDINC" \
    "CF objects compile against a machorun/sdk snapshot, not the FE sysroot overlay-darwin mutated"
expect_grep 'CFOBJC_FORCE_COPY=1' "$UDINC" \
    "cfobjc recopies the pin (existence of OUT/src is not freshness)"
expect_not_grep 'fe_malloc_zone_as_malloc.h' "$STAGE" \
    "sysroot does not globally map malloc_zone_*"
expect_grep 'stamp_key "$cfbase"' "$UDINC" \
    "cfobjc objects rebuild when malloc/malloc.h or the CF pin changes; existence is not freshness"
expect_file "$ROOT/scripts/x86/Darwin.apinotes"
expect_grep 'Darwin.apinotes' "$COMMON" \
    "FE clang snapshot stages Darwin.apinotes so CLOCK_REALTIME is the Swift name of _CLOCK_REALTIME"
expect_grep 'BUILD_FULL_THROUGH=umbrellas' "$COMMON" \
    "run-root umbrellas come from build_full.sh, not build_foundation_placeholder.sh"
expect_grep 'phase2_stage_x86_build_full_umbrellas' "$PHASE2" \
    "phase2 invokes build_full THROUGH=umbrellas before rung a"
expect_grep 'BUILD_FULL_THROUGH=umbrellas' "$BUILD_FULL" \
    "build_full.sh accepts the reduced-form umbrellas stop"
expect_not_grep 'phase2_stage_x86_foundation_placeholders' "$PHASE2" \
    "phase2 does not stage empty Foundation placeholders into the run root"
expect_not_grep 'phase2_stage_x86_foundation_placeholders' "$ROOT/scripts/x86/stage_cycle_roots.sh" \
    "cycle roots do not stage empty Foundation placeholders into the run root"
expect_grep 'fe_sysroot_append_vm_copy' "$STAGE" \
    "x86 stager uses the shared vm_copy append"
expect_grep 'fe_sysroot_measurement.inc' "$ROOT/full/foundation/stage_fe_sysroot.sh" \
    "arm64 stager reads the shared measurement inc"
expect_grep 'fe_sysroot_measurement_headers' "$ROOT/full/foundation/stage_fe_sysroot.sh" \
    "arm64 stager iterates the shared header list"
expect_not_grep 'for h in sys/xattr.h copyfile.h removefile.h fts.h pwd.h grp.h sys/utsname.h sys/quota.h' \
    "$ROOT/full/foundation/stage_fe_sysroot.sh" \
    "arm64 stager does not duplicate the FileManager header literal"
expect_not_grep 'for h in sys/xattr.h copyfile.h removefile.h fts.h pwd.h grp.h sys/utsname.h sys/quota.h' \
    "$STAGE" \
    "x86 stager does not duplicate the FileManager header literal"
expect_file "$ROOT/full/foundation/fe_sysroot_measurement_headers.txt"
expect_file "$ROOT/full/foundation/fe_sysroot_measurement.inc"
expect_grep 'removefile.h' "$ROOT/full/foundation/fe_sysroot_measurement_headers.txt" \
    "shared list includes removefile.h"
expect_grep 'complex.h' "$ROOT/full/foundation/fe_sysroot_measurement_headers.txt" \
    "shared list includes complex.h"
expect_grep 'sysdir.h' "$ROOT/full/foundation/fe_sysroot_measurement_headers.txt" \
    "shared list includes sysdir.h"
expect_grep 'BUILD_FE_REMOVEFILE_COMPAT' "$PHASE2" \
    "x86 FE chain compiles removefile_compat.c (build_fe.sh is Swift-only)"
expect_grep 'phase2_compile_removefile_compat' "$PHASE2" \
    "phase2 invokes the shared removefile_compat clang helper"
expect_not_grep 'removefile_compat.c' "$ROOT/full/foundation/build_fe.sh" \
    "build_fe.sh does not compile removefile_compat.c (Swift-only on both arches)"
expect_grep 'removefile_compat.c' "$BUILD_FULL" \
    "arm64 full link compiles removefile_compat.c"
expect_grep 'usr/include/_modules' "$COMMON" \
    "Linux Darwin fallback copies _modules from the arm64 sysroot"

echo "== x86 sysroot .tbd set: gen_tbd aliases, overlay emit, resolve before build_full"
expect_grep 'phase2_stage_darwin_tbds_into_sysroot' "$STAGE" \
    "stager stages gen_tbd darwin tbds including unsuffixed aliases"
expect_grep 'ln -sfn libobjc.A.tbd' "$COMMON" \
    "libobjc.tbd alias is created (find -type f dropped the symlink)"
expect_not_grep 'find "$MACHORUN/sdk/usr/lib" -maxdepth 1 -type f -name '\''*.tbd'\''' "$STAGE" \
    "stager no longer copies only regular .tbd files (that skipped libobjc.tbd)"
expect_grep 'phase2_stage_overlay_tbds_into_sysroot' "$STAGE" \
    "stager emits overlay tbds from x86 dylibs"
expect_grep 'phase2_twelve_overlay_names' "$COMMON" \
    "durable overlay set is twelve (nine FE + Concurrency/ObjectiveC/Observation)"
fe_n=$(phase2_fe_overlay_names | grep -c .)
[ "$fe_n" -eq 9 ] \
    && ok "phase2_fe_overlay_names stays nine (lockstep with build_full FE_OVERLAYS)" \
    || die_test "phase2_fe_overlay_names count=$fe_n want 9"
twelve_n=$(phase2_twelve_overlay_names | grep -c .)
[ "$twelve_n" -eq 12 ] \
    && ok "phase2_twelve_overlay_names is twelve" \
    || die_test "phase2_twelve_overlay_names count=$twelve_n want 12"
for extra in libswift_Concurrency.dylib libswiftObjectiveC.dylib libswiftObservation.dylib
do
    phase2_twelve_overlay_names | grep -qx "$extra" \
        && ok "twelve-overlay set includes $extra" \
        || die_test "twelve-overlay set missing $extra"
    phase2_fe_overlay_names | grep -qx "$extra" \
        && die_test "FE overlay set must not include $extra (widget load, not FE_OVERLAYS)" \
        || ok "FE overlay set does not include $extra"
done
phase2_consumer_tbd_relpaths | grep -qiE 'ARKit|AppKit|AVFoundation' \
    && die_test "consumer tbd set must not name Apple-SDK extras (ARKit/AppKit/…)" \
    || ok "consumer tbd set has no ARKit/AppKit/AVFoundation names"
expect_grep 'gen_swift_tbd.sh' "$COMMON" \
    "overlay tbds come from the committed TAPI writer"
expect_grep 'phase2_consumer_tbd_relpaths' "$COMMON" \
    "resolve inventory is consumer-derived, not the Apple SDK overlay list"
expect_grep 'NOTE extra Apple-SDK' "$PHASE2" \
    "extra Apple-SDK tbd names are a NOTE, never a CANNOT"
expect_grep 'libquartz.tbd' "$COMMON" "consumer set includes libquartz.tbd"
expect_grep '[-]lobjc' "$BUILD_FULL" "build_full link names -lobjc"
expect_grep '[-]lSystem' "$BUILD_FULL" "build_full link names -lSystem"
expect_grep 'libswift_Concurrency.dylib' "$INVENTORIES" "widget expected loads name Concurrency"
expect_grep 'libswiftObjectiveC.dylib' "$INVENTORIES" "widget expected loads name ObjectiveC"
expect_grep 'libswiftObservation.dylib' "$INVENTORIES" "widget expected loads name Observation"
expect_grep 'x86_64 drops ARM64_OVERLAY_AUTOLINK' "$INVENTORIES" \
    "x86 widget loads drop errno rather than substituting DarwinFoundation1"
expect_grep 'libswift_errno.dylib' "$INVENTORIES" "arm64 widget loads still name errno"
fe_x86=$(python3 "$INVENTORIES" --arch x86_64 --gate widget --kind loads --name foundationessentials)
printf '%s\n' "$fe_x86" | grep -qx '/usr/lib/swift/libswiftDarwin.dylib' \
    && ! printf '%s\n' "$fe_x86" | grep -q 'libswift_errno.dylib' \
    && ! printf '%s\n' "$fe_x86" | grep -q 'DarwinFoundation1' \
    && ok "x86 FE loads keep Darwin, drop errno, no DarwinFoundation1" \
    || die_test "x86 FE loads drifted: $(echo "$fe_x86" | tr '\n' '|')"
openuikit_x86=$(python3 "$INVENTORIES" --arch x86_64 --gate widget --kind loads --name openuikit)
! printf '%s\n' "$openuikit_x86" | grep -q 'libswift_errno.dylib' \
    && ! printf '%s\n' "$openuikit_x86" | grep -q 'DarwinFoundation1' \
    && ok "x86 OpenUIKit loads drop errno without DarwinFoundation1" \
    || die_test "x86 OpenUIKit loads drifted: $(echo "$openuikit_x86" | tr '\n' '|')"
arm_stubs=$(python3 "$INVENTORIES" --arch arm64 --gate widget --kind stubs --name substrate)
x86_stubs=$(python3 "$INVENTORIES" --arch x86_64 --gate widget --kind stubs --name substrate)
onboarding_x86_stubs=$(python3 "$INVENTORIES" --arch x86_64 --gate onboarding --kind stubs --name substrate)
printf '%s\n' "$arm_stubs" | grep -qx 'guest-root/darwin/System/Library/Frameworks/Foundation.framework/Foundation' \
    && printf '%s\n' "$arm_stubs" | grep -qx 'guest-root/darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation' \
    && [ -z "$x86_stubs" ] && [ -z "$onboarding_x86_stubs" ] \
    && ok "x86 closure stubs are empty; arm64 still requires Foundation+CoreFoundation" \
    || die_test "closure stub inventory drifted arm=$(printf '%s' "$arm_stubs" | tr '\n' '|') x86=$(printf '%s' "$x86_stubs" | tr '\n' '|')"
expect_grep 'closure requires --otool, --executable, --package, --guest-root, and --arch' \
    "$ROOT/full/swiftui/focus_widget_guest_attest.pl" \
    "widget/onboarding closure attest requires --arch"
command -v llvm-objdump-18 >/dev/null \
    || die_test "llvm-objdump-18 missing; cannot measure committed x86 overlays"
overlay_foundation_hits=0
for overlay in "$ROOT"/swiftcore-macho/artifacts/swift-macosx/x86_64/*.dylib; do
    [ -f "$overlay" ] || die_test "committed x86 overlay missing: $overlay"
    if llvm-objdump-18 --macho --private-headers "$overlay" \
        | grep -qE '(^|[[:space:]])name .*(/| )(Core)?Foundation\.framework'; then
        overlay_foundation_hits=$((overlay_foundation_hits + 1))
        echo "FOUNDATION_LC $(basename "$overlay")" >&2
    fi
done
[ "$overlay_foundation_hits" -eq 0 ] \
    && ok "committed x86 overlays declare no Foundation/CoreFoundation" \
    || die_test "committed x86 overlays naming Foundation.framework: $overlay_foundation_hits"
expect_grep 'libswiftCore.tbd' "$ROOT/full/swiftui/focus_widget_guest_attest.pl" \
    "widget attest requires named libswiftCore.tbd"
expect_grep '[-]lswiftCore' "$ROOT/foundation-macho/scripts/link_ud_guest.sh" \
    "link_ud_guest -lswiftCore"
# Required set is grepped from those consumers, not the arm64 Apple-SDK overlay list.
ATTEST=$ROOT/full/swiftui/focus_widget_guest_attest.pl
LINK_UD=$ROOT/foundation-macho/scripts/link_ud_guest.sh
want=$(phase2_consumer_tbd_relpaths)
derived=$(
    {
        grep -hoE 'libswift[A-Za-z0-9_]+\.tbd' \
            "$BUILD_FULL" "$WIDGET" "$ONBOARD" "$ATTEST" "$LINK_UD" "$INVENTORIES" 2>/dev/null \
            | sed 's|^|usr/lib/swift/|'
        grep -hoE 'lib(System(\.B)?|objc(\.A)?|c\+\+(\.1)?|c\+\+abi|quartz)\.tbd' \
            "$BUILD_FULL" "$WIDGET" "$ONBOARD" "$ATTEST" "$LINK_UD" "$INVENTORIES" 2>/dev/null \
            | sed 's|^|usr/lib/|'
        grep -hoE -- '-l(swift[A-Za-z0-9_]+|objc|System)' \
            "$BUILD_FULL" "$WIDGET" "$ONBOARD" "$ATTEST" "$LINK_UD" "$INVENTORIES" 2>/dev/null \
            | while IFS= read -r flag; do
                name=${flag#-l}
                case "$name" in
                    swift*) printf 'usr/lib/swift/lib%s.tbd\n' "$name" ;;
                    objc) printf 'usr/lib/libobjc.tbd\n' ;;
                    System) printf 'usr/lib/libSystem.tbd\n' ;;
                esac
            done
        grep -hoE '/usr/lib/swift/libswift[A-Za-z0-9_]+\.dylib' \
            "$WIDGET" "$ONBOARD" "$LINK_UD" "$INVENTORIES" 2>/dev/null \
            | sed 's|^/||; s/\.dylib$/.tbd/'
    } | grep -E '^usr/lib/' | sort -u
)
derived_ok=1
while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    case "$rel" in
        *ARKit*|*AppKit*|*AVFoundation*|*Accelerate*|*AppleArchive*)
            die_test "consumer grep produced Apple-SDK extra $rel"
            derived_ok=0
            continue
            ;;
    esac
    if ! printf '%s\n' "$want" | grep -qx "$rel"; then
        die_test "consumer names $rel but required set lacks it"
        derived_ok=0
    fi
done <<< "$derived"
[ "$derived_ok" -eq 1 ] \
    && ok "consumer -l/.tbd/expected_* names are a subset of the required set"
printf '%s\n' "$derived" | grep -q 'usr/lib/swift/libswiftCore.tbd' \
    && printf '%s\n' "$derived" | grep -q 'usr/lib/libobjc.tbd' \
    && ok "consumer grep found libswiftCore.tbd and libobjc.tbd" \
    || die_test "consumer grep missed Core/objc (derived=$(echo "$derived" | tr '\n' ','))"
expect_grep 'never copy arm64' "$STAGE" "stager comment refuses arm64 tbd copies"
expect_grep 'phase2_sysroot_tbd_resolve' "$PHASE2" \
    "phase2 resolves the tbd set before build_full"
expect_grep 'X86_SYSROOT_TBDS' "$PHASE2" "tbd hole is CANNOT_X86_SYSROOT_TBDS"
expect_grep 'SYSROOT_TBDS_OK' "$PHASE2" "rungs b/c wait on SYSROOT_TBDS_OK"
expect_grep 'tbd-set=' "$COMMON" "stamp records the arm64 tbd inventory"
expect_grep 'tbd-darwin-dylibs=' "$COMMON" "stamp records darwin dylib shas that gen_tbd reads"
expect_grep '_objc_sync_exit' "$COMMON" "acceptance list names render_full.o _objc_sync_exit"
expect_grep '2>&1 | tee "$W/scratch/phase2-rung-a-smoke.log"' "$PHASE2" \
    "rung a smoke log captures stderr"
expect_grep '2>&1 | tee "$W/scratch/phase2-rung-b-widget.log"' "$PHASE2" \
    "rung b widget log captures build_full stderr"
expect_grep '2>&1 | tee "$W/scratch/phase2-rung-b-onboarding.log"' "$PHASE2" \
    "rung b onboarding log captures stderr"
expect_grep '2>&1 | tee "$W/scratch/phase2-rung-c-reminder.log"' "$PHASE2" \
    "rung c log captures build_full stderr"
expect_not_grep '^            | tee "$W/scratch/phase2-rung-b-widget.log"' "$PHASE2" \
    "rung b widget tee is not stdout-only"
expect_grep 'never copy arm64 tbds' "$COMMON" \
    "darwin tbd stage refuses arm64-macos files"
awk '
    /cannot sysroot-tbds-x86 X86_SYSROOT_TBDS/ { t=NR }
    /build_focus_widget_guest.sh/ { if (!w) w=NR }
    END {
        if (!t) { print "NO_TBD"; exit 1 }
        if (!w) { print "NO_WIDGET"; exit 1 }
        if (!(t<w)) { print "ORDER t="t" w="w; exit 1 }
        print "OK"
    }
' "$PHASE2" | grep -q OK \
    && ok "CANNOT_X86_SYSROOT_TBDS is emitted before build_focus_widget_guest.sh" \
    || die_test "tbd resolve CANNOT is not before build_full/widget"

echo "== measurement headers: shared list, stage_absent from arm64, stamp recipe .3"
expect_grep 'phase2_darwin_modulemap_missing_headers' "$COMMON" \
    "every header path named by staged modulemaps is checked"
expect_grep 'compiles Darwin.swiftinterface' "$COMMON" \
    "x86 takes the arm64 compile-the-interface path (no version-check disable)"
expect_not_grep 'disable-deserialization-safety' "$PHASE2" \
    "phase2 does not blanket-disable the SDK version check"
expect_not_grep 'disable-deserialization-safety' "$ROOT/full/foundation/build_os_module.sh" \
    "os-module does not disable the SDK version check"
expect_grep 'SWIFT_TOOLCHAIN' "$PHASE2" \
    "phase2 exports SWIFT_TOOLCHAIN for overlay scripts"
expect_grep 'SWIFT_TOOLCHAIN' "$ROOT/swiftcore-macho/scripts/guest_arch.inc" \
    "guest_arch honors SWIFT_TOOLCHAIN"
expect_not_grep 'no swiftc at /opt/swift624/usr/bin or /usr/bin' \
    "$ROOT/swiftcore-macho/scripts/guest_arch.inc" \
    "guest_arch no longer refuses solely on hardcoded toolchain paths"

STAMPWORK=$(mktemp -d /tmp/phase2-stamp.XXXXXX)
echo a > "$STAMPWORK/core-a"
echo b > "$STAMPWORK/core-b"
echo m > "$STAMPWORK/mod"
echo f > "$STAMPWORK/bf"
echo g > "$STAMPWORK/gen"
echo o > "$STAMPWORK/overlay"
echo d > "$STAMPWORK/dmap"
echo list-a > "$STAMPWORK/meas-a"
echo list-b > "$STAMPWORK/meas-b"
phase2_write_sysroot_stamp "$STAMPWORK/stamp" \
    "$STAMPWORK/core-a" "$STAMPWORK/mod" "$STAMPWORK/bf" \
    "$STAMPWORK/gen" "$STAMPWORK/overlay" "$STAMPWORK/dmap" \
    "$STAMPWORK/meas-a"
match=$(phase2_sysroot_stamp_diff "$STAMPWORK/stamp" \
    "$STAMPWORK/core-a" "$STAMPWORK/mod" "$STAMPWORK/bf" \
    "$STAMPWORK/gen" "$STAMPWORK/overlay" "$STAMPWORK/dmap" \
    "$STAMPWORK/meas-a" && echo MATCH || echo FAIL)
if [ "$match" = MATCH ]; then
    ok "stamp matches when inputs are unchanged"
else
    die_test "unchanged inputs should match stamp, got $match"
fi
diff=$(phase2_sysroot_stamp_diff "$STAMPWORK/stamp" \
    "$STAMPWORK/core-b" "$STAMPWORK/mod" "$STAMPWORK/bf" \
    "$STAMPWORK/gen" "$STAMPWORK/overlay" "$STAMPWORK/dmap" \
    "$STAMPWORK/meas-a" || true)
case "$diff" in
    *"libswiftCore "*) ok "stamp names libswiftCore when the artifact sha changes ($diff)" ;;
    *) die_test "expected libswiftCore old->new, got: $diff" ;;
esac
missing_stamp=$(phase2_sysroot_stamp_diff "$STAMPWORK/absent" \
    "$STAMPWORK/core-a" "$STAMPWORK/mod" "$STAMPWORK/bf" \
    "$STAMPWORK/gen" "$STAMPWORK/overlay" "$STAMPWORK/dmap" \
    "$STAMPWORK/meas-a" || true)
case "$missing_stamp" in
    stamp=ABSENT) ok "missing stamp is stamp=ABSENT (restage, do not reuse)" ;;
    *) die_test "missing stamp expected stamp=ABSENT, got: $missing_stamp" ;;
esac
meas_diff=$(phase2_sysroot_stamp_diff "$STAMPWORK/stamp" \
    "$STAMPWORK/core-a" "$STAMPWORK/mod" "$STAMPWORK/bf" \
    "$STAMPWORK/gen" "$STAMPWORK/overlay" "$STAMPWORK/dmap" \
    "$STAMPWORK/meas-b" || true)
case "$meas_diff" in
    *"fe_sysroot_measurement_headers "*)
        ok "stamp names fe_sysroot_measurement_headers when the shared list sha changes ($meas_diff)"
        ;;
    *) die_test "expected fe_sysroot_measurement_headers old->new, got: $meas_diff" ;;
esac
grep -q '^tbd-set=' "$STAMPWORK/stamp" \
    && ok "written stamp includes tbd-set" \
    || die_test "stamp missing tbd-set"
grep -q '^tbd-darwin-dylibs=' "$STAMPWORK/stamp" \
    && ok "written stamp includes tbd-darwin-dylibs" \
    || die_test "stamp missing tbd-darwin-dylibs"
rm -rf "$STAMPWORK"

echo "== tbd resolve: missing alias, wrong target, gen_tbd symbols, live sysroot"
TBDWORK=$(mktemp -d /tmp/phase2-tbd.XXXXXX)
mkdir -p "$TBDWORK/x86/usr/lib" "$TBDWORK/arm/usr/lib" "$TBDWORK/arm/usr/lib/swift"
# Arm64 inventory names libobjc.tbd (Apple unsuffixed). Empty x86 sysroot
# must report it missing, not pass vacuously.
printf '%s\n' '--- !tapi-tbd' 'targets:         [ arm64-macos ]' '...' \
    > "$TBDWORK/arm/usr/lib/libobjc.tbd"
miss=$(phase2_sysroot_tbd_resolve "$TBDWORK/x86" "$TBDWORK/arm" || true)
case "$miss" in
    MISSING=*libobjc.tbd*)
        ok "resolve names MISSING=usr/lib/libobjc.tbd when the alias is absent ($miss)"
        ;;
    *) die_test "expected MISSING=…libobjc.tbd, got: $miss" ;;
esac

# Never copy an arm64-macos tbd even if the filename matches.
FAKESDK=$(mktemp -d /tmp/phase2-fake-sdk.XXXXXX)
mkdir -p "$FAKESDK/sdk/usr/lib"
printf '%s\n' '--- !tapi-tbd' 'targets:         [ arm64-macos ]' '...' \
    > "$FAKESDK/sdk/usr/lib/libobjc.A.tbd"
ln -sfn libobjc.A.tbd "$FAKESDK/sdk/usr/lib/libobjc.tbd"
if phase2_stage_darwin_tbds_into_sysroot "$TBDWORK/refuse" "$FAKESDK" 2>"$TBDWORK/refuse.err"; then
    die_test "darwin tbd stage accepted an arm64-macos libobjc.A.tbd"
else
    grep -q 'never copy arm64 tbds' "$TBDWORK/refuse.err" \
        && ok "darwin tbd stage refuses arm64-macos gen_tbd output" \
        || die_test "refuse path did not name arm64 copy ($(cat "$TBDWORK/refuse.err"))"
fi
rm -rf "$FAKESDK"

if ! phase2_stage_darwin_tbds_into_sysroot "$TBDWORK/x86" "$ROOT/machorun"; then
    die_test "phase2_stage_darwin_tbds_into_sysroot failed against machorun/sdk"
fi
if [ -L "$TBDWORK/x86/usr/lib/libobjc.tbd" ] \
    && [ "$(readlink "$TBDWORK/x86/usr/lib/libobjc.tbd")" = libobjc.A.tbd ]; then
    ok "libobjc.tbd is a symlink to libobjc.A.tbd"
else
    die_test "libobjc.tbd is not the gen_tbd alias (link=$(readlink "$TBDWORK/x86/usr/lib/libobjc.tbd" 2>/dev/null || echo missing))"
fi
if phase2_tbd_is_x86_target "$TBDWORK/x86/usr/lib/libobjc.tbd"; then
    ok "staged libobjc.tbd names x86_64-macos"
else
    die_test "staged libobjc.tbd does not name x86_64-macos"
fi
undef_ok=1
while IFS= read -r sym; do
    [ -n "$sym" ] || continue
    if ! grep -q "'$sym'" "$TBDWORK/x86/usr/lib/libobjc.tbd"; then
        echo "FAIL: $sym not in staged libobjc.tbd" >&2
        undef_ok=0
    fi
done < <(phase2_render_full_objc_undefs)
if [ "$undef_ok" -eq 1 ]; then
    ok "render_full.o objc undefs are all in staged libobjc.tbd"
else
    die_test "staged libobjc.tbd is missing render_full.o objc undefs"
fi
# Acceptance: ld64 -lobjc against those undefs (the operator == link failure).
# Other undefs (crt) may remain; the eight must not appear in ld64 stderr.
if command -v ld64.lld-18 >/dev/null 2>&1 && command -v clang >/dev/null 2>&1; then
    cat > "$TBDWORK/undefs.s" <<'EOF'
    .text
    .globl _main
_main:
    callq _objc_sync_exit
    callq _objc_sync_enter
    callq _objc_setAssociatedObject
    callq _objc_getAssociatedObject
    callq _objc_opt_self
    callq _objc_getClassList
    callq _objc_getClass
    movq __objc_empty_cache@GOTPCREL(%rip), %rax
    xorl %eax, %eax
    ret
EOF
    if clang -c -target x86_64-apple-macos15.0 -o "$TBDWORK/undefs.o" "$TBDWORK/undefs.s" \
        2>"$TBDWORK/clang.err"; then
        set +e
        ld64.lld-18 -arch x86_64 -platform_version macos 15.0 15.0 \
            -syslibroot "$TBDWORK/x86" -L/usr/lib -lobjc -lSystem \
            -e _main -o "$TBDWORK/undefs.bin" "$TBDWORK/undefs.o" \
            >"$TBDWORK/ld.err" 2>&1
        set -e
        ld_hit=0
        while IFS= read -r sym; do
            [ -n "$sym" ] || continue
            if grep -q "$sym" "$TBDWORK/ld.err"; then
                echo "FAIL: ld64 still undefined $sym" >&2
                ld_hit=1
            fi
        done < <(phase2_render_full_objc_undefs)
        if [ "$ld_hit" -eq 0 ]; then
            ok "ld64 -lobjc does not report render_full.o objc undefs"
        else
            die_test "ld64 still missing objc symbols ($(cat "$TBDWORK/ld.err"))"
        fi
    else
        ok "skip ld64 -lobjc (clang could not emit x86_64 Mach-O: $(tr '\n' ' ' < "$TBDWORK/clang.err"))"
    fi
else
    ok "skip ld64 -lobjc (ld64.lld-18 or clang absent)"
fi
# Arm inventory also names an overlay tbd we cannot copy (arm64 target).
printf '%s\n' '--- !tapi-tbd' 'targets:         [ arm64-macos ]' '...' \
    > "$TBDWORK/arm/usr/lib/swift/libswiftCore.tbd"
overlay_miss=$(phase2_sysroot_tbd_resolve "$TBDWORK/x86" "$TBDWORK/arm" || true)
case "$overlay_miss" in
    MISSING=*usr/lib/swift/libswiftCore.tbd*)
        ok "resolve names missing consumer overlay libswiftCore.tbd ($overlay_miss)"
        ;;
    *) die_test "expected MISSING overlay libswiftCore.tbd, got: $overlay_miss" ;;
esac
# Extra Apple-SDK names (ARKit, AppKit, …) must not become CANNOT.
printf '%s\n' '--- !tapi-tbd' 'targets:         [ arm64-macos ]' '...' \
    > "$TBDWORK/arm/usr/lib/swift/libswiftARKit.tbd"
printf '%s\n' '--- !tapi-tbd' 'targets:         [ arm64-macos ]' '...' \
    > "$TBDWORK/arm/usr/lib/swift/libswiftAppKit.tbd"
arkit_res=$(phase2_sysroot_tbd_resolve "$TBDWORK/x86" "$TBDWORK/arm" || true)
case "$arkit_res" in
    *libswiftARKit*|*libswiftAppKit*)
        die_test "Apple-SDK extras must not be MISSING/WRONG_TARGET: $arkit_res"
        ;;
esac
ok "ARKit/AppKit in the arm64 inventory are not a CANNOT ($arkit_res)"
extras=$(phase2_sysroot_tbd_extras "$TBDWORK/arm" | paste -sd, -)
case "$extras" in
    *libswiftARKit.tbd*libswiftAppKit.tbd*|*libswiftAppKit.tbd*libswiftARKit.tbd*)
        ok "extras helper names ARKit and AppKit ($extras)"
        ;;
    *) die_test "expected extras to name ARKit and AppKit, got: $extras" ;;
esac
core_src=$ROOT/swiftcore-macho/artifacts/swift-macosx/x86_64/libswiftCore.dylib
if [ -f "$core_src" ] && phase2_is_x86_macho "$core_src"; then
    if phase2_emit_tbd_from_dylib "$core_src" \
        /usr/lib/swift/libswiftCore.dylib \
        "$TBDWORK/x86/usr/lib/swift/libswiftCore.tbd" \
        && phase2_tbd_is_x86_target "$TBDWORK/x86/usr/lib/swift/libswiftCore.tbd"; then
        ok "overlay tbd emitted from x86 libswiftCore.dylib names x86_64-macos"
    else
        die_test "failed to emit x86 libswiftCore.tbd from the x86 dylib"
    fi
    overlay_ok=$(phase2_sysroot_tbd_resolve "$TBDWORK/x86" "$TBDWORK/arm" || true)
    case "$overlay_ok" in
        OK) ok "resolve OK after gen_tbd aliases + twelve overlay tbds" ;;
        MISSING=*)
            if echo "$overlay_ok" | grep -q 'usr/lib/swift/libswiftCore.tbd'; then
                die_test "libswiftCore.tbd still missing after emit: $overlay_ok"
            fi
            echo "$overlay_ok" | grep -qE 'ARKit|AppKit' \
                && die_test "resolve must not name Apple-SDK extras after Core emit: $overlay_ok"
            ok "resolve names remaining consumer overlay tbds after Core ($overlay_ok)"
            ;;
        *) die_test "expected OK or MISSING consumer overlays after emitting Core tbd, got: $overlay_ok" ;;
    esac
else
    ok "skip live libswiftCore overlay emit (no x86 dylib in artifacts)"
fi
# Copied arm64 target must not pass even if the file exists.
cp -f "$TBDWORK/arm/usr/lib/libobjc.tbd" "$TBDWORK/x86/usr/lib/libobjc.tbd"
wrong=$(phase2_sysroot_tbd_resolve "$TBDWORK/x86" "$TBDWORK/arm" || true)
case "$wrong" in
    *WRONG_TARGET=*libobjc.tbd*)
        ok "resolve names WRONG_TARGET for an arm64-macos libobjc.tbd ($wrong)"
        ;;
    *) die_test "expected WRONG_TARGET=…libobjc.tbd, got: $wrong" ;;
esac
rm -rf "$TBDWORK"

# Live x86 sysroot: apply darwin aliases without wiping headers, then check.
if [ -d "$ROOT/scratch/sysroot_fe4-x86_64/usr/lib" ] \
    && [ -s "$ROOT/machorun/sdk/usr/lib/libobjc.A.tbd" ]; then
    if phase2_stage_darwin_tbds_into_sysroot \
        "$ROOT/scratch/sysroot_fe4-x86_64" "$ROOT/machorun"; then
        if [ -e "$ROOT/scratch/sysroot_fe4-x86_64/usr/lib/libobjc.tbd" ] \
            && phase2_tbd_is_x86_target "$ROOT/scratch/sysroot_fe4-x86_64/usr/lib/libobjc.tbd" \
            && grep -q "'_objc_sync_exit'" "$ROOT/scratch/sysroot_fe4-x86_64/usr/lib/libobjc.tbd"; then
            ok "live sysroot_fe4-x86_64 libobjc.tbd is x86 and exports _objc_sync_exit"
        else
            die_test "live sysroot still lacks an x86 libobjc.tbd with _objc_sync_exit"
        fi
    else
        die_test "could not stage darwin tbds into live sysroot_fe4-x86_64"
    fi
    W=$ROOT
    phase2_stage_overlay_tbds_into_sysroot "$ROOT/scratch/sysroot_fe4-x86_64" || true
    live_res=$(phase2_sysroot_tbd_resolve \
        "$ROOT/scratch/sysroot_fe4-x86_64" "$ROOT/scratch/sysroot_fe4" || true)
    case "$live_res" in
        OK) ok "live x86 sysroot tbd resolve vs arm64 inventory: OK" ;;
        MISSING=*)
            if echo "$live_res" | grep -qE 'libswiftObjectiveC|libswift_DarwinFoundation|libswift_errno|libswift_Concurrency|libswiftObservation'; then
                ok "live resolve names remaining consumer overlay holes: $live_res"
            else
                die_test "live resolve MISSING is not a consumer overlay: $live_res"
            fi
            echo "$live_res" | grep -qE 'ARKit|AppKit|AVFoundation' \
                && die_test "live resolve must not name Apple-SDK extras: $live_res"
            ;;
        *) die_test "live resolve unexpected: $live_res" ;;
    esac
    W=$ROOT
else
    ok "skip live sysroot tbd apply (sysroot_fe4-x86_64 or gen_tbd output absent)"
fi

MMWORK=$(mktemp -d /tmp/phase2-modulemap.XXXXXX)
mkdir -p "$MMWORK/arm/usr/include/_modules" \
    "$MMWORK/sys/usr/include/objc" \
    "$MMWORK/old/usr/include/objc"
# ObjectiveC map is already on the x86 sysroot (stager writes it before Darwin).
cat > "$MMWORK/sys/usr/include/module.modulemap" <<'EOF'
module ObjectiveC [system] { header "objc/objc.h" export * }
EOF
echo '/* objc */' > "$MMWORK/sys/usr/include/objc/objc.h"
echo '/* objc */' > "$MMWORK/old/usr/include/objc/objc.h"
# errno.h stands in for machorun/sdk headers the stager already copied.
echo '/* errno */' > "$MMWORK/sys/usr/include/errno.h"
echo '/* errno */' > "$MMWORK/old/usr/include/errno.h"
# Unique shim names: enumerate from the arm64 tree, do not hard-code 44 files.
printf '%s\n' '/* GENERATED by machorun scripts/gen_darwin_modulemap.py */' \
    > "$MMWORK/arm/usr/include/_modules/_darwin_c_ctype.h"
printf '%s\n' '/* GENERATED by machorun scripts/gen_darwin_modulemap.py */' \
    > "$MMWORK/arm/usr/include/_modules/_unique_shim_from_arm.h"
cat > "$MMWORK/arm/usr/include/Darwin.modulemap" <<'EOF'
module Darwin [system] { header "_modules/_unique_shim_from_arm.h" export * }
EOF
cat > "$MMWORK/arm/usr/include/Darwin_C.modulemap" <<'EOF'
module Darwin.C [system] { header "_modules/_darwin_c_ctype.h" export * }
EOF
cat > "$MMWORK/arm/usr/include/DarwinFoundation1.modulemap" <<'EOF'
module _DarwinFoundation1 [system] { header "errno.h" export * }
EOF
printf 'module ObjectiveC [system] { header "objc/objc.h" export * }\nextern module Darwin "Darwin.modulemap"\nextern module _DarwinFoundation1 "DarwinFoundation1.modulemap"\n' \
    > "$MMWORK/arm/usr/include/module.modulemap"

# Fail-before: maps-only restage (what x86.1 wrote) leaves named _modules headers absent.
cp "$MMWORK/arm/usr/include/"*.modulemap "$MMWORK/old/usr/include/"
cp "$MMWORK/sys/usr/include/module.modulemap" "$MMWORK/old/usr/include/module.modulemap"
before=$(phase2_darwin_modulemap_missing_headers "$MMWORK/old" || true)
case "$before" in
    *_modules/_darwin_c_ctype.h*_modules/_unique_shim_from_arm.h*|*_modules/_unique_shim_from_arm.h*_modules/_darwin_c_ctype.h*)
        ok "maps-only restage fails header check before the copy ($before)"
        ;;
    *) die_test "maps-only tree should name missing _modules headers, got: $before" ;;
esac

# Pass-after: Linux fallback copies maps AND enumerated _modules shims.
if phase2_install_darwin_modulemaps "$MMWORK/sys" "$MMWORK/arm" "$MMWORK/no-such-gen.py"; then
    if [ -f "$MMWORK/sys/usr/include/Darwin.modulemap" ] \
        && [ -f "$MMWORK/sys/usr/include/DarwinFoundation1.modulemap" ] \
        && [ -f "$MMWORK/sys/usr/include/_modules/_darwin_c_ctype.h" ] \
        && [ -f "$MMWORK/sys/usr/include/_modules/_unique_shim_from_arm.h" ] \
        && grep -q 'extern module Darwin' "$MMWORK/sys/usr/include/module.modulemap"; then
        ok "Darwin fallback copies maps and enumerated _modules shims from arm64"
    else
        die_test "copy path did not install maps + _modules shims"
    fi
else
    die_test "install_darwin_modulemaps failed on a fixture that has pruned maps and _modules"
fi
after=$(phase2_darwin_modulemap_missing_headers "$MMWORK/sys" && echo NONE || true)
if [ "$after" = NONE ]; then
    ok "after restage every header path named by staged modulemaps resolves"
else
    die_test "expected no missing headers after copy, got: $after"
fi
rm -rf "$MMWORK"

echo "== FE clang snapshot: expand does not rewrite the overlay-copied Darwin.modulemap"
SNAP=$(mktemp -d /tmp/phase2-fe-clang.XXXXXX)
mkdir -p "$SNAP/sys/usr/include"
printf '%s\n' 'module Darwin [system] {' '  header "math.h"' '  export *' '}' \
    > "$SNAP/sys/usr/include/Darwin.modulemap"
printf '/* math */\n' > "$SNAP/sys/usr/include/math.h"
printf '/* unistd */\n' > "$SNAP/sys/usr/include/unistd.h"
cp -a "$SNAP/sys/usr/include/Darwin.modulemap" "$SNAP/overlay-clean.modulemap"
if phase2_stage_fe_clang_sysroot "$SNAP/sys" "$ROOT"; then
    fe_clang=$(phase2_fe_clang_sysroot "$SNAP/sys")
    if cmp -s "$SNAP/sys/usr/include/Darwin.modulemap" "$SNAP/overlay-clean.modulemap"; then
        ok "overlay-copied Darwin.modulemap is unchanged after FE clang snapshot"
    else
        die_test "overlay-copied Darwin.modulemap was mutated"
    fi
    if grep -q 'header "unistd.h"' "$fe_clang/usr/include/Darwin.modulemap"; then
        ok "FE clang snapshot Darwin.modulemap names unistd.h for Darwin.write"
    else
        die_test "FE clang snapshot missing unistd.h"
    fi
    if grep -q 'header "unistd.h"' "$SNAP/sys/usr/include/Darwin.modulemap"; then
        die_test "overlay-copied Darwin.modulemap names unistd.h (would break _DarwinFoundation3)"
    else
        ok "overlay-copied Darwin.modulemap does not name unistd.h"
    fi
else
    die_test "phase2_stage_fe_clang_sysroot failed on fixture"
fi
rm -rf "$SNAP"

echo "== FileManager measurement headers: fail before copy, pass after arm64 stage_absent"
n_hdr=$(fe_sysroot_measurement_headers | wc -l | tr -d ' ')
if [ "$n_hdr" = 10 ]; then
    ok "shared measurement list has 10 headers"
else
    die_test "shared measurement list count is $n_hdr, not 10"
fi
MHWORK=$(mktemp -d /tmp/phase2-meas-hdr.XXXXXX)
mkdir -p "$MHWORK/arm/usr/include/sys" "$MHWORK/sys/usr/include/sys" \
    "$MHWORK/sys/usr/include/mach"
# Arm64 fixture has the full shared list (what PR #17's sysroot_fe4 carries).
while IFS= read -r h; do
    [ -n "$h" ] || continue
    mkdir -p "$MHWORK/arm/usr/include/$(dirname "$h")"
    printf '/* ARM %s */\n' "$h" > "$MHWORK/arm/usr/include/$h"
done < <(fe_sysroot_measurement_headers)
# x86 restage without removefile.h (the operator failure class).
while IFS= read -r h; do
    [ -n "$h" ] || continue
    [ "$h" = removefile.h ] && continue
    mkdir -p "$MHWORK/sys/usr/include/$(dirname "$h")"
    printf '/* X86 %s */\n' "$h" > "$MHWORK/sys/usr/include/$h"
done < <(fe_sysroot_measurement_headers)
before_mh=$(phase2_measurement_headers_missing "$MHWORK/sys" || true)
if [ "$before_mh" = removefile.h ]; then
    ok "restage without removefile.h fails header-resolve before the compiler ($before_mh)"
else
    die_test "expected missing=removefile.h, got: $before_mh"
fi
# stage_absent: already-present copyfile.h must not be shadowed.
printf '/* X86 copyfile.h must survive */\n' > "$MHWORK/sys/usr/include/copyfile.h"
printf '/* ARM copyfile.h would shadow */\n' > "$MHWORK/arm/usr/include/copyfile.h"
phase2_stage_measurement_headers_from_arm "$MHWORK/sys" "$MHWORK/arm"
if [ -f "$MHWORK/sys/usr/include/removefile.h" ] \
    && grep -q 'ARM removefile.h' "$MHWORK/sys/usr/include/removefile.h" \
    && grep -q 'X86 copyfile.h must survive' "$MHWORK/sys/usr/include/copyfile.h"; then
    ok "stage_absent copies missing removefile.h from arm64 and refuses to shadow copyfile.h"
else
    die_test "stage_absent did not copy removefile.h / preserve copyfile.h"
fi
after_mh=$(phase2_measurement_headers_missing "$MHWORK/sys" && echo NONE || true)
if [ "$after_mh" = NONE ]; then
    ok "after restage every header in the shared measurement list exists in the x86 sysroot"
else
    die_test "expected no missing measurement headers after copy, got: $after_mh"
fi
# vm_copy append (shared helper; not a file copy).
printf '/* empty vm_map.h */\n' > "$MHWORK/sys/usr/include/mach/vm_map.h"
fe_sysroot_append_vm_copy "$MHWORK/sys/usr/include/mach/vm_map.h"
if grep -q 'extern kern_return_t vm_copy' "$MHWORK/sys/usr/include/mach/vm_map.h"; then
    ok "shared helper appends vm_copy to mach/vm_map.h"
else
    die_test "vm_copy was not appended"
fi
fe_sysroot_append_vm_copy "$MHWORK/sys/usr/include/mach/vm_map.h"
vm_n=$(grep -c 'extern kern_return_t vm_copy' "$MHWORK/sys/usr/include/mach/vm_map.h" || true)
if [ "$vm_n" = 1 ]; then
    ok "vm_copy append is idempotent"
else
    die_test "vm_copy appended twice (count=$vm_n)"
fi
rm -rf "$MHWORK"

# Compile removefile_compat.c the way try_fe will (same clang line as build_full.sh).
if command -v clang-18 >/dev/null && [ -d "$ROOT/scratch/sysroot_fe4-x86_64/usr/include" ]; then
    COMPAT_OUT=$(mktemp -d /tmp/phase2-removefile-compat.XXXXXX)
    if phase2_compile_removefile_compat \
        "$ROOT/scratch/sysroot_fe4-x86_64" \
        "$COMPAT_OUT/removefile_compat.o" \
        x86_64-apple-macos15.0 \
        "$ROOT" \
        && phase2_is_x86_macho "$COMPAT_OUT/removefile_compat.o"; then
        ok "removefile_compat.c compiles to X86_64 Mach-O against the x86 sysroot"
        rm -rf "$COMPAT_OUT"
    else
        die_test "removefile_compat.c failed to compile against scratch/sysroot_fe4-x86_64"
        rm -rf "$COMPAT_OUT"
    fi
else
    echo "SKIP: clang-18 / x86 sysroot not present for removefile_compat compile"
fi

echo "== os-module-x86 before build_fe + fe-imports census"
expect_grep 'full/foundation/build_os_module.sh' "$PHASE2" \
    "phase2 builds the local os module"
expect_grep 'OSMOD="$OSMOD"' "$PHASE2" \
    "phase2 passes OSMOD into build_fe.sh"
expect_grep 'cannot fe-imports FE_IMPORTS' "$PHASE2" \
    "fe-imports refusal is CANNOT_FE_IMPORTS"
expect_grep 'try_os_module || true' "$PHASE2" \
    "os-module runs in the FE chain"
expect_grep 'os.swiftmodule|os.swiftmodule/\*' "$STAGE" \
    "stager skips Apple os overlay (FE uses os-module)"
OSMOD_SH=$ROOT/full/foundation/build_os_module.sh
COL_SH=$ROOT/full/foundation/build_collections.sh
FE_SH=$ROOT/full/foundation/build_fe.sh
expect_grep 'TARGET:-arm64-apple-macos15.0' "$OSMOD_SH" \
    "os-module script is TARGET-retargetable"
expect_grep 'MC:-$W/scratch/modcache_fe4' "$OSMOD_SH" \
    "os-module cache is overridable (x86 uses a suffixed cache)"
# Order: build_os_module.sh must appear before build_fe.sh invocation.
awk '
    /full\/foundation\/build_os_module.sh/ { os=NR }
    /full\/foundation\/build_fe.sh/ { fe=NR }
    END {
        if (!os || !fe || !(os<fe)) { print "ORDER os="os" fe="fe; exit 1 }
        print "OK"
    }
' "$PHASE2" | grep -q OK && ok "os-module step is before build_fe.sh" \
    || die_test "os-module is not before build_fe.sh"

echo "== one canonical module-cache path per target (no /w vs \$W pcm collision)"
expect_grep 'pwd -P' "$PHASE2" \
    "phase2 resolves W to a physical path (pwd -P)"
expect_grep 'phase2_canonical_dir' "$PHASE2" \
    "phase2 canonicalizes the per-target module cache"
expect_grep 'modcache_fe4${FULL_OUT_SUFFIX}' "$PHASE2" \
    "x86 module cache is scratch/modcache_fe4-x86_64 beside arm64 modcache_fe4"
expect_grep 'note module-cache satisfied' "$PHASE2" \
    "ENV_PREPARE module-cache prints the cache path"
expect_grep 'MC="$MC"' "$PHASE2" \
    "phase2 passes MC into the x86 swiftc chain"
mc_n=$(grep -c 'MC="$MC"' "$PHASE2" || true)
if [ "$mc_n" -ge 4 ]; then
    ok "phase2 passes MC= to os-module, collections, FE, and OpenCombine ($mc_n assignments)"
else
    die_test "expected >=4 MC=\"\$MC\" assignments in phase2 (got $mc_n)"
fi
expect_grep 'mc=$MC' "$PHASE2" \
    "os-module/collections/FE/OpenCombine ENV_PREPARE lines include mc="
expect_grep 'MC:-$W/scratch/modcache_fe4' "$COL_SH" \
    "collections cache is overridable (x86 passes the suffixed canonical MC)"
expect_grep 'MC:-$W/scratch/modcache_fe4' "$FE_SH" \
    "FE cache is overridable (x86 passes the suffixed canonical MC)"
expect_grep '-module-cache-path "$MC"' "$COL_SH" \
    "collections swiftc uses -module-cache-path \$MC"
expect_grep '-module-cache-path "$MC"' "$FE_SH" \
    "FE swiftc uses -module-cache-path \$MC"
expect_grep '-module-cache-path "$MC"' "$OSMOD_SH" \
    "os-module swiftc uses -module-cache-path \$MC"
expect_grep '-module-cache-path "$MC"' "$OC" \
    "OpenCombine swiftc uses -module-cache-path \$MC"
expect_grep 'realpath -P' "$OSMOD_SH" \
    "os-module realpath-canonicalizes MC (hand-run without MC still one spelling)"
expect_grep 'realpath -P' "$COL_SH" \
    "collections realpath-canonicalizes MC"
expect_grep 'realpath -P' "$FE_SH" \
    "FE realpath-canonicalizes MC"
expect_grep 'realpath -P' "$OC" \
    "OpenCombine realpath-canonicalizes MC"
expect_not_grep '-module-cache-path "$W/scratch/modcache_fe4"' "$COL_SH" \
    "collections no longer hardcodes unsuffixed cache on the swiftc line"
expect_not_grep '-module-cache-path "$W/scratch/modcache_fe4"' "$FE_SH" \
    "FE no longer hardcodes unsuffixed cache on the swiftc line"
for s in "$OSMOD_SH" "$COL_SH" "$FE_SH"; do
    if bash -n "$s"; then
        ok "bash -n $(basename "$s")"
    else
        die_test "bash -n $(basename "$s")"
    fi
done
# /w -> physical tree is the same inode; clang treats two spellings as two pcm defs.
# macOS: /tmp is a symlink to /private/tmp, so mktemp may return /tmp/... while
# realpath -P returns /private/tmp/.... Reproduce that split on Linux with a
# tmp -> private/tmp alias, then compare pwd -P paths on both sides.
MC_HOST=$(mktemp -d /tmp/phase2-modcache-host.XXXXXX)
mkdir -p "$MC_HOST/private/tmp"
ln -sfn "$MC_HOST/private/tmp" "$MC_HOST/tmp"
MC_REAL=$(mktemp -d "$MC_HOST/private/tmp/phase2-modcache.XXXXXX")
MCWORK="$MC_HOST/tmp/$(basename "$MC_REAL")"
mkdir -p "$MCWORK/physical/scratch/modcache_fe4-x86_64"
ln -sfn "$MCWORK/physical" "$MCWORK/wlink"
via_w=$(phase2_canonical_dir "$MCWORK/wlink/scratch/modcache_fe4-x86_64")
via_phys=$(phase2_canonical_dir "$MCWORK/physical/scratch/modcache_fe4-x86_64")
if [ -n "$via_w" ] && [ "$via_w" = "$via_phys" ]; then
    ok "phase2_canonical_dir collapses /w-style symlink and physical cache to one path"
else
    die_test "canonical cache mismatch via_w=$via_w via_phys=$via_phys"
fi
phys_canon=$(cd "$MCWORK/physical/scratch/modcache_fe4-x86_64" && pwd -P)
link_unresolved="$MCWORK/wlink/scratch/modcache_fe4-x86_64"
if [ "$via_w" = "$link_unresolved" ]; then
    die_test "canonical cache still uses symlink spelling $via_w"
fi
if [ "$via_w" = "$phys_canon" ]; then
    ok "canonical cache is the physical spelling ($via_w)"
else
    die_test "canonical cache is neither symlink nor physical: $via_w (physical=$phys_canon)"
fi
# Same canonicalize the os-module script applies on a hand-run with W=/w.
hand=$(
    unset MC
    W=$MCWORK/wlink
    W=$(cd "$W" && pwd -P)
    MC=${MC:-$W/scratch/modcache_fe4-x86_64}
    mkdir -p "$MC"
    realpath -P "$MC"
)
if [ "$hand" = "$via_phys" ]; then
    ok "os-module W=pwd -P + realpath MC matches canonical cache under a /w-style W"
else
    die_test "hand-run canonicalize $hand != $via_phys"
fi
handed_symlink=$(
    W=$MCWORK/wlink
    W=$(cd "$W" && pwd -P)
    MC=$MCWORK/wlink/scratch/modcache_fe4-x86_64
    mkdir -p "$MC"
    realpath -P "$MC"
)
if [ "$handed_symlink" = "$via_phys" ]; then
    ok "realpath MC collapses an explicitly passed /w-style cache path"
else
    die_test "passed /w-style MC $handed_symlink != $via_phys"
fi
rm -rf "$MC_HOST"

FEWORK=$(mktemp -d /tmp/phase2-fe-imports.XXXXXX)
mkdir -p "$FEWORK/sys/usr/include" \
    "$FEWORK/sys/usr/lib/swift/Darwin.swiftmodule" \
    "$FEWORK/sys/usr/lib/swift/Swift.swiftmodule" \
    "$FEWORK/sys/usr/lib/swift/_Builtin_float.swiftmodule" \
    "$FEWORK/os"
touch "$FEWORK/sys/usr/include/Darwin.modulemap"
touch "$FEWORK/sys/usr/lib/swift/Darwin.swiftmodule/x86_64-apple-macos.swiftinterface"
touch "$FEWORK/sys/usr/lib/swift/Swift.swiftmodule/x86_64-apple-macos.swiftmodule"
touch "$FEWORK/sys/usr/lib/swift/_Builtin_float.swiftmodule/x86_64-apple-macos.swiftmodule"
touch "$FEWORK/os/os.swiftmodule"
missing=$(phase2_probe_fe_imports "$FEWORK/sys" "$FEWORK/os" || true)
case "$missing" in
    MISSING*"present=Darwin,os,Swift,_Builtin_float"*"absent=_StringProcessing,_Concurrency"*"optional_absent=Synchronization"*)
        ok "fe-imports names _StringProcessing,_Concurrency absent in one line ($missing)"
        ;;
    *) die_test "fe-imports MISSING census expected, got: $missing" ;;
esac
mkdir -p "$FEWORK/sys/usr/lib/swift/_StringProcessing.swiftmodule" \
    "$FEWORK/sys/usr/lib/swift/_Concurrency.swiftmodule" \
    "$FEWORK/sys/usr/lib/swift/Synchronization.swiftmodule"
touch "$FEWORK/sys/usr/lib/swift/_StringProcessing.swiftmodule/x86_64-apple-macos.swiftinterface"
touch "$FEWORK/sys/usr/lib/swift/_Concurrency.swiftmodule/x86_64-apple-macos.swiftinterface"
touch "$FEWORK/sys/usr/lib/swift/Synchronization.swiftmodule/x86_64-apple-macos.swiftinterface"
match=$(phase2_probe_fe_imports "$FEWORK/sys" "$FEWORK/os" || true)
case "$match" in
    MATCH*"present=Darwin,os,Swift,_Builtin_float,_StringProcessing,_Concurrency,Synchronization"*)
        ok "fe-imports MATCH when required modules and Synchronization are present"
        ;;
    *) die_test "fe-imports MATCH expected, got: $match" ;;
esac
# Arm64 slice under an x86 sysroot is not presence.
rm -f "$FEWORK/sys/usr/lib/swift/_Concurrency.swiftmodule/x86_64-apple-macos.swiftinterface"
touch "$FEWORK/sys/usr/lib/swift/_Concurrency.swiftmodule/arm64-apple-macos.swiftinterface"
armonly=$(phase2_probe_fe_imports "$FEWORK/sys" "$FEWORK/os" || true)
case "$armonly" in
    MISSING*"absent=_Concurrency"*)
        ok "fe-imports refuses an arm64 _Concurrency slice as x86 presence"
        ;;
    *) die_test "arm64-only _Concurrency should be absent, got: $armonly" ;;
esac
rm -rf "$FEWORK"

echo "== base runtime suffix + x86 overlay CANNOT lists the nine FE dylibs"
expect_file "$PREPARE"
expect_grep 'scratch/mrroot${FULL_OUT_SUFFIX}' "$BUILD_FULL" "BASE default uses suffix"
expect_grep 'scratch/mrroot_fe${FULL_OUT_SUFFIX}' "$BUILD_FULL" "FE default uses suffix"
expect_grep 'phase2_stage_x86_base_mrroot' "$PHASE2" "phase2 stages scratch/mrroot-x86_64"
expect_grep 'scratch/mrroot${FULL_OUT_SUFFIX}' "$PHASE2" "phase2 BASE_MRROOT is suffixed"
expect_grep 'CANNOT_X86_OVERLAYS_NOT_BUILT' "$PHASE2" "phase2 overlay hole is not the macOS marker"
expect_grep 'CANNOT_X86_OVERLAYS_NOT_BUILT' "$PREPARE" "widget env-prepare overlay hole is not the macOS marker"
expect_grep 'try_generate_tbd' "$PREPARE" "tbd-stubs tries gen_tbd instead of host=x86_64"
expect_not_grep 'CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS' "$PHASE2" \
    "phase2 overlay staging does not use the macOS CoreSimulator marker"
expect_grep 'phase2_find_x86_overlay' "$COMMON" "overlay search helper"
expect_grep 'phase2_is_cache_extract' "$COMMON" "cache-extract detector"
expect_grep 'phase2_stage_x86_run_root_overlays' "$COMMON" "run-root overlay stager"
expect_grep 'CANNOT_STAGE_CACHE_EXTRACT' "$COMMON" "cache-extract refusal marker"
expect_grep 'OVERLAY_PROVENANCE' "$COMMON" "overlay provenance line"
expect_grep 'llvm-objdump' "$COMMON" "provenance reads llvm-objdump private-headers"
expect_grep 'phase2_stage_x86_run_root_overlays' "$PHASE2" \
    "phase2 restages overlays into the run root"
expect_not_grep 'if phase2_is_x86_macho "$swift/$name"; then' "$COMMON" \
    "BASE fill no longer keeps an existing x86 Mach-O (ObjectiveC Apple-extract skip)"
for overlay in libswiftDarwin.dylib libswiftSynchronization.dylib \
    libswift_Builtin_float.dylib libswift_DarwinFoundation1.dylib \
    libswift_DarwinFoundation2.dylib libswift_DarwinFoundation3.dylib \
    libswift_RegexParser.dylib libswift_StringProcessing.dylib libswift_errno.dylib
do
    expect_grep "$overlay" "$COMMON" "overlay $overlay named in common.inc"
    expect_grep "$overlay" "$PREPARE" "overlay $overlay named in prepare.py"
    expect_grep "$overlay" "$BUILD_FULL" "overlay $overlay named in build_full.sh"
done

# Isolate $HOME and $W so a leftover operator stdlib tree or this checkout's
# swiftcore-macho/artifacts/swift-macosx/x86_64 (libswiftDarwin /
# libswift_Builtin_float) cannot satisfy the miss case.
OVERLAY_HOME=$(mktemp -d /tmp/phase2-overlay-home.XXXXXX)
OVERLAY_DEST=$(mktemp -d /tmp/phase2-overlay-dest.XXXXXX)
OVERLAY_W=$(mktemp -d /tmp/phase2-overlay-w.XXXXXX)
W=$OVERLAY_W
HOME=$OVERLAY_HOME
# shellcheck source=common.inc
. "$COMMON"
overlay_report=$(phase2_stage_x86_fe_overlays "$OVERLAY_DEST/mrroot_fe-x86_64" || true)
expected_missing='MISSING=libswiftDarwin.dylib,libswiftSynchronization.dylib,libswift_Builtin_float.dylib,libswift_DarwinFoundation1.dylib,libswift_DarwinFoundation2.dylib,libswift_DarwinFoundation3.dylib,libswift_RegexParser.dylib,libswift_StringProcessing.dylib,libswift_errno.dylib,libswift_Concurrency.dylib,libswiftObjectiveC.dylib,libswiftObservation.dylib'
if [ "$overlay_report" = "$expected_missing" ]; then
    ok "overlay stage lists every missing overlay of the twelve ($overlay_report)"
else
    die_test "overlay MISSING list expected $expected_missing got: $overlay_report"
fi
W=$ROOT
rm -rf "$OVERLAY_W"

BASE_DEST=$(mktemp -d /tmp/phase2-base-mrroot.XXXXXX)
x86_core=$ROOT/swiftcore-macho/artifacts/swift-macosx/x86_64/libswiftCore.dylib
phase2_stage_x86_base_mrroot \
    "$BASE_DEST/mrroot-x86_64" \
    "$ROOT/machorun/build/machorun" \
    "$ROOT/machorun/darwin" \
    "$x86_core"
if [ -x "$BASE_DEST/mrroot-x86_64/machorun" ] \
    && [ -f "$BASE_DEST/mrroot-x86_64/darwin/usr/lib/swift/libswiftCore.dylib" ] \
    && phase2_is_x86_macho "$BASE_DEST/mrroot-x86_64/darwin/usr/lib/swift/libswiftCore.dylib" \
    && phase2_is_elf_x86_loader "$BASE_DEST/mrroot-x86_64/machorun"; then
    ok "base mrroot-x86_64 stages loader + x86 libswiftCore beside, not into, scratch/mrroot"
else
    die_test "base mrroot-x86_64 stage did not produce loader+x86 libswiftCore"
fi
rm -rf "$BASE_DEST" "$OVERLAY_HOME" "$OVERLAY_DEST"

echo "== x86 host runtime from /opt/swift/usr layout; empty host is CANNOT_X86_HOST_RUNTIME"
expect_file "$ROOT/full/dispatch/swift_linux_lib.inc"
expect_grep 'openuikit_resolve_swift_linux_lib' \
    "$ROOT/full/dispatch/build_host_bridge.sh" \
    "build_host_bridge.sh uses the shared Swift linux-lib resolver"
expect_grep 'openuikit_resolve_swift_linux_lib' "$COMMON" \
    "phase2 host stager uses the shared Swift linux-lib resolver"
expect_grep '/opt/swift/usr' "$ROOT/full/dispatch/swift_linux_lib.inc" \
    "resolver searches /opt/swift/usr"
expect_grep 'phase2_stage_x86_host_runtime' "$PHASE2" \
    "phase2 fills scratch/mrroot-x86_64/host"
expect_grep 'X86_HOST_RUNTIME' "$PHASE2" "empty host/ is CANNOT_X86_HOST_RUNTIME"
expect_not_grep 'src=/usr/lib/swift/linux/$name' "$COMMON" \
    "host stager no longer hardcodes /usr/lib/swift/linux"
expect_not_grep 'X86_HOST_RUNTIME' "$ROOT/scripts/env/markers.py" \
    "CANNOT_X86_HOST_RUNTIME is not a PR3 CURSOR_ENV_CANNOT_* marker"
expect_file "$ROOT/full/urltransport/build_host_helper.sh"
expect_file "$ROOT/full/relativetime/build_host_helper.sh"
expect_file "$ROOT/full/foundationinternationalization/build_host_helper.sh"
expect_grep 'openuikit_host_runtime_toolchain_files' "$COMMON" \
    "host stager copies only toolchain names"
expect_grep 'openuikit_host_runtime_built_files' \
    "$ROOT/full/dispatch/swift_linux_lib.inc" \
    "host runtime list splits built Open* names from toolchain copies"
expect_grep 'urltransport/build_host_helper.sh' "$COMMON" \
    "phase2 builds libOpenURLTransportHost.so via committed helper script"
expect_grep 'relativetime/build_host_helper.sh' "$COMMON" \
    "phase2 builds libOpenRelativeTimeHost.so via committed helper script"
expect_grep 'foundationinternationalization/build_host_helper.sh' "$COMMON" \
    "phase2 builds libOpenFoundationInternationalizationHost.so via committed helper script"
expect_grep 'urltransport/build_host_helper.sh' \
    "$ROOT/full/frameworks/build_core_guest_package.sh" \
    "core-package host URL recipe is the shared helper script"
expect_grep 'relativetime/build_host_helper.sh' \
    "$ROOT/full/frameworks/build_core_guest_package.sh" \
    "core-package host relative-time recipe is the shared helper script"
expect_grep 'foundationinternationalization/build_host_helper.sh' \
    "$ROOT/full/foundationinternationalization/build_foundation_internationalization.sh" \
    "intl lane host recipe is the shared helper script"
expect_grep '-lcurl -pthread' "$ROOT/full/urltransport/build_host_helper.sh" \
    "URL host helper keeps committed -lcurl -pthread"
expect_grep '-licui18n -licuuc -lm' \
    "$ROOT/full/relativetime/build_host_helper.sh" \
    "relative-time host helper keeps committed ICU libs"
expect_not_grep 'OpenURLTransportHost.c' "$COMMON" \
    "phase2 does not inline the URL host clang recipe"
expect_not_grep 'OpenRelativeTimeHost.c' "$COMMON" \
    "phase2 does not inline the relative-time host clang recipe"
expect_not_grep 'OpenFoundationInternationalizationHost.c' "$COMMON" \
    "phase2 does not inline the intl host clang recipe"
# Host check must appear in phase2.sh before the widget/build_full invocation.
awk '
    /cannot mrroot-host-x86 X86_HOST_RUNTIME/ { h=NR }
    /build_focus_widget_guest.sh/ { if (!w) w=NR }
    END {
        if (!h) { print "NO_HOST"; exit 1 }
        if (!w) { print "NO_WIDGET"; exit 1 }
        if (!(h<w)) { print "ORDER h="h" w="w; exit 1 }
        print "OK"
    }
' "$PHASE2" | grep -q OK \
    && ok "CANNOT_X86_HOST_RUNTIME is emitted before build_focus_widget_guest.sh" \
    || die_test "host runtime CANNOT is not before build_full/widget"
HOST_NAMES='libdispatch.so,libBlocksRuntime.so,libOpenDispatchHost.so,libOpenFoundationInternationalizationHost.so,libOpenURLTransportHost.so,libOpenRelativeTimeHost.so'
for host_name in libdispatch.so libBlocksRuntime.so libOpenDispatchHost.so \
    libOpenFoundationInternationalizationHost.so libOpenURLTransportHost.so \
    libOpenRelativeTimeHost.so
do
    expect_grep "$host_name" "$ROOT/full/dispatch/swift_linux_lib.inc" \
        "host runtime names $host_name"
    expect_grep "$host_name" "$BUILD_FULL" "build_full.sh names $host_name"
done

OPEN_HOST_NAMES='libOpenDispatchHost.so,libOpenFoundationInternationalizationHost.so,libOpenURLTransportHost.so,libOpenRelativeTimeHost.so'
saved_toolchain=${SWIFT_TOOLCHAIN:-}
unset SWIFT_TOOLCHAIN
real_linux=$(openuikit_resolve_swift_linux_lib)
if [ ! -f "$real_linux/libdispatch.so" ] || [ ! -f "$real_linux/libBlocksRuntime.so" ]; then
    die_test "no ELF toolchain libdispatch/libBlocksRuntime under $real_linux"
fi

HOST_FIX=$(mktemp -d /tmp/phase2-host-fix.XXXXXX)
HOST_DEST=$(mktemp -d /tmp/phase2-host-dest.XXXXXX)
mkdir -p "$HOST_FIX/opt/swift/usr/lib/swift/linux"
cp -fL "$real_linux/libdispatch.so" "$HOST_FIX/opt/swift/usr/lib/swift/linux/libdispatch.so"
cp -fL "$real_linux/libBlocksRuntime.so" \
    "$HOST_FIX/opt/swift/usr/lib/swift/linux/libBlocksRuntime.so"
# Dummy Open* in the linux dir must never be copied (including fake arm64 ELF).
for host_name in libOpenDispatchHost.so \
    libOpenFoundationInternationalizationHost.so libOpenURLTransportHost.so \
    libOpenRelativeTimeHost.so
do
    printf 'not-x86-open-%s\n' "$host_name" \
        > "$HOST_FIX/opt/swift/usr/lib/swift/linux/$host_name"
done
export SWIFT_TOOLCHAIN=$HOST_FIX/opt/swift/usr
resolved=$(openuikit_resolve_swift_linux_lib)
if [ "$resolved" = "$HOST_FIX/opt/swift/usr/lib/swift/linux" ]; then
    ok "resolver uses fixture SWIFT_TOOLCHAIN=/opt/swift/usr layout"
else
    die_test "resolver got $resolved want $HOST_FIX/opt/swift/usr/lib/swift/linux"
fi

host_copy=$(phase2_stage_x86_host_runtime "$HOST_DEST" || true)
expected_open_missing="MISSING=$OPEN_HOST_NAMES"
if [ "$host_copy" = "$expected_open_missing" ] \
    && phase2_is_elf_x86_so "$HOST_DEST/host/libdispatch.so" \
    && phase2_is_elf_x86_so "$HOST_DEST/host/libBlocksRuntime.so"; then
    open_copied=0
    for host_name in libOpenDispatchHost.so \
        libOpenFoundationInternationalizationHost.so libOpenURLTransportHost.so \
        libOpenRelativeTimeHost.so
    do
        if [ -e "$HOST_DEST/host/$host_name" ]; then
            open_copied=1
        fi
    done
    if [ "$open_copied" -eq 0 ]; then
        ok "without repo, toolchain copies are ELF x86-64 and each Open* is named missing"
    else
        die_test "Open* leaked into dest without a build: $(ls -l "$HOST_DEST/host")"
    fi
else
    die_test "copy-only host stage expected $expected_open_missing got: $host_copy"
fi

# Build uses the real Swift linux dir for dispatch.h; the fixture has only .so files.
if [ -z "${saved_toolchain}" ]; then
    unset SWIFT_TOOLCHAIN
else
    export SWIFT_TOOLCHAIN=$saved_toolchain
fi

# Leftover non-x86 Open* in dest must be rebuilt, not kept.
printf 'arm64-leftover\n' > "$HOST_DEST/host/libOpenURLTransportHost.so"
host_built=$(phase2_stage_x86_host_runtime "$HOST_DEST" "$ROOT" || true)
if [ "$host_built" = OK ]; then
    host_all=1
    for host_name in libdispatch.so libBlocksRuntime.so libOpenDispatchHost.so \
        libOpenFoundationInternationalizationHost.so libOpenURLTransportHost.so \
        libOpenRelativeTimeHost.so
    do
        if ! phase2_is_elf_x86_so "$HOST_DEST/host/$host_name"; then
            host_all=0
        fi
        if ! grep -q "$host_name" "$HOST_DEST/host/SHA256SUMS"; then
            host_all=0
        fi
        want=$(sha256sum "$HOST_DEST/host/$host_name" | awk '{print $1}')
        got=$(grep -F "/$host_name" "$HOST_DEST/host/SHA256SUMS" | awk '{print $1}')
        if [ "$want" != "$got" ]; then
            host_all=0
        fi
    done
    if grep -q arm64-leftover "$HOST_DEST/host/libOpenURLTransportHost.so"; then
        host_all=0
    fi
    dummy_url=$(sha256sum "$HOST_FIX/opt/swift/usr/lib/swift/linux/libOpenURLTransportHost.so" \
        | awk '{print $1}')
    built_url=$(sha256sum "$HOST_DEST/host/libOpenURLTransportHost.so" | awk '{print $1}')
    if [ "$dummy_url" = "$built_url" ]; then
        host_all=0
    fi
    if [ "$host_all" -eq 1 ]; then
        ok "with repo, four Open* are built ELF x86-64 (not copied) and sha256 recorded"
    else
        die_test "built host/ incomplete under $HOST_DEST/host: $(ls -l "$HOST_DEST/host"); $(file "$HOST_DEST/host"/*.so)"
    fi
else
    die_test "repo host stage expected OK got: $host_built logs=$(ls "$HOST_DEST/host-work" 2>/dev/null); $(tail -n 20 "$HOST_DEST/host-work"/*.log 2>/dev/null)"
fi

EMPTY_FIX=$(mktemp -d /tmp/phase2-host-empty.XXXXXX)
EMPTY_DEST=$(mktemp -d /tmp/phase2-host-empty-dest.XXXXXX)
mkdir -p "$EMPTY_FIX/opt/swift/usr/lib/swift/linux" "$EMPTY_DEST/host"
export SWIFT_TOOLCHAIN=$EMPTY_FIX/opt/swift/usr
host_miss=$(phase2_stage_x86_host_runtime "$EMPTY_DEST" || true)
expected_host_missing="MISSING=$HOST_NAMES"
if [ "$host_miss" = "$expected_host_missing" ]; then
    ok "empty toolchain without repo is MISSING listing every HOST_RUNTIME_FILES name"
else
    die_test "empty host MISSING expected $expected_host_missing got: $host_miss"
fi

EMPTY_BUILD=$(mktemp -d /tmp/phase2-host-empty-build.XXXXXX)
mkdir -p "$EMPTY_BUILD/host"
host_empty_build=$(phase2_stage_x86_host_runtime "$EMPTY_BUILD" "$ROOT" || true)
expected_dispatch_missing='MISSING=libdispatch.so,libBlocksRuntime.so,libOpenDispatchHost.so'
if [ "$host_empty_build" = "$expected_dispatch_missing" ] \
    && phase2_is_elf_x86_so \
        "$EMPTY_BUILD/host/libOpenFoundationInternationalizationHost.so" \
    && phase2_is_elf_x86_so "$EMPTY_BUILD/host/libOpenURLTransportHost.so" \
    && phase2_is_elf_x86_so "$EMPTY_BUILD/host/libOpenRelativeTimeHost.so"; then
    ok "empty toolchain with repo names each unbuilt helper (dispatch) and builds the other three"
else
    die_test "empty+repo expected $expected_dispatch_missing plus three ELF Open* got: $host_empty_build $(ls -l "$EMPTY_BUILD/host"); $(file "$EMPTY_BUILD/host"/* 2>/dev/null)"
fi

if [ -z "${saved_toolchain}" ]; then
    unset SWIFT_TOOLCHAIN
else
    export SWIFT_TOOLCHAIN=$saved_toolchain
fi
rm -rf "$HOST_FIX" "$HOST_DEST" "$EMPTY_FIX" "$EMPTY_DEST" "$EMPTY_BUILD"

echo "== x86 mrroot layout is build_full.sh BASE/FE inventory before any rung"
expect_grep 'mrroot-layout-x86' "$PHASE2" "phase2 item mrroot-layout-x86"
expect_grep 'X86_MRROOT_LAYOUT' "$PHASE2" "layout hole is CANNOT_X86_MRROOT_LAYOUT"
expect_grep 'CANNOT_X86_MRROOT_LAYOUT' "$PHASE2" \
    "rung substrate names CANNOT_X86_MRROOT_LAYOUT"
expect_not_grep 'X86_MRROOT_LAYOUT' "$ROOT/scripts/env/markers.py" \
    "CANNOT_X86_MRROOT_LAYOUT is not a PR3 CURSOR_ENV_CANNOT_* marker"
expect_grep 'STUBS_ONLY' "$ROOT/scripts/build_runtime_shims.sh" \
    "loud-abort stubs have a STUBS_ONLY recipe"
expect_grep 'phase2_fill_x86_loud_abort_stubs' "$COMMON" \
    "layout fill uses build_runtime_shims.sh STUBS_ONLY"
expect_grep 'build_runtime_shims.sh' "$COMMON" \
    "layout names the committed stub recipe"
expect_grep 'build_compat.sh' "$COMMON" "layout names the committed compat recipe"
expect_grep 'artifacts/libswiftcompat.dylib is arm64' "$COMMON" \
    "layout never treats artifacts/libswiftcompat.dylib as an x86 source"
expect_grep 'phase2_base_layout_macho_names' "$COMMON" \
    "layout inventory is a closed BASE Mach-O list"
expect_grep 'LAYOUT_OK' "$PHASE2" "rungs b/c wait on LAYOUT_OK"
expect_grep 'phase2_rung_selected_quiet b' "$PHASE2" \
    "host-w-layout / focus-pin / SWIFTUI_SUBSTRATE only cannot when rung b is selected"
expect_grep 'Rung b would CANNOT_HOST_W_LAYOUT' "$PHASE2" \
    "PHASE2_RUNGS=a notes the /w mount instead of failing host-w-layout"
expect_grep 'Rung b would CANNOT_FOCUS_PIN' "$PHASE2" \
    "PHASE2_RUNGS=a notes a missing Focus pin instead of failing focus-pin"
expect_grep 'elif phase2_rung_selected_quiet c' "$PHASE2" \
    "unselected rung c does not cannot REMINDER_INVENTORY"
awk '
    /cannot mrroot-layout-x86 X86_MRROOT_LAYOUT/ { l=NR }
    /build_focus_widget_guest.sh/ { if (!w) w=NR }
    END {
        if (!l) { print "NO_LAYOUT"; exit 1 }
        if (!w) { print "NO_WIDGET"; exit 1 }
        if (!(l<w)) { print "ORDER l="l" w="w; exit 1 }
        print "OK"
    }
' "$PHASE2" | grep -q OK \
    && ok "CANNOT_X86_MRROOT_LAYOUT is emitted before build_focus_widget_guest.sh" \
    || die_test "layout CANNOT is not before build_full/widget"
for layout_name in Foundation CoreFoundation libswiftcompat.dylib \
    libswiftCore.dylib libswiftObjectiveC.dylib libswift_Concurrency.dylib
do
    expect_grep "$layout_name" "$COMMON" "layout inventory names $layout_name"
    expect_grep "$layout_name" "$BUILD_FULL" "build_full.sh names $layout_name"
done
expect_grep 'libswiftObservation.dylib' "$COMMON" \
    "layout inventory names libswiftObservation.dylib (widget expected_swiftui_loads)"

LAYOUT_HOME=$(mktemp -d /tmp/phase2-layout-home.XXXXXX)
LAYOUT_W=$(mktemp -d /tmp/phase2-layout-w.XXXXXX)
LAYOUT_DEST=$(mktemp -d /tmp/phase2-layout-dest.XXXXXX)
LAYOUT_FE=$(mktemp -d /tmp/phase2-layout-fe.XXXXXX)
W=$LAYOUT_W
HOME=$LAYOUT_HOME
layout_miss=$(phase2_stage_x86_mrroot_layout \
    "$LAYOUT_DEST" "$LAYOUT_FE" "$LAYOUT_W" "$LAYOUT_W/sys" "$LAYOUT_W/loader" || true)
W=$ROOT
case "$layout_miss" in
    MISSING=*)
        layout_ok=1
        for need in libswiftcompat.dylib Foundation CoreFoundation; do
            echo "$layout_miss" | grep -q "$need" || layout_ok=0
        done
        while IFS= read -r name; do
            [ -n "$name" ] || continue
            echo "$layout_miss" | grep -q "$name" || layout_ok=0
        done < <(phase2_twelve_overlay_names)
        if [ "$layout_ok" -eq 1 ]; then
            ok "empty dest MISSING= includes Foundation + all twelve overlays ($layout_miss)"
        else
            die_test "empty dest MISSING incomplete (need twelve overlays): $layout_miss"
        fi
        ;;
    *) die_test "empty dest layout expected MISSING=… got: $layout_miss" ;;
esac
rm -rf "$LAYOUT_HOME" "$LAYOUT_W" "$LAYOUT_DEST" "$LAYOUT_FE"

SYS=${SYS:-$ROOT/scratch/sysroot_fe4-x86_64}
if [ -d "$SYS/usr/lib" ]; then
    STUB_DEST=$(mktemp -d /tmp/phase2-layout-stubs.XXXXXX)
    phase2_fill_x86_loud_abort_stubs "$STUB_DEST" "$ROOT" "$SYS" || true
    if phase2_is_x86_macho \
        "$STUB_DEST/darwin/System/Library/Frameworks/Foundation.framework/Foundation" \
        && phase2_is_x86_macho \
        "$STUB_DEST/darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"; then
        ok "STUBS_ONLY loud-abort stubs are X86_64 Mach-O"
    else
        die_test "loud-abort stubs were not x86 Mach-O under $STUB_DEST"
    fi
    phase2_fill_x86_libswiftcompat \
        "$STUB_DEST" "$ROOT" "$SYS" "$ROOT/machorun/build/machorun" || true
    if phase2_is_x86_macho "$STUB_DEST/darwin/usr/lib/libswiftcompat.dylib"; then
        ok "build_compat.sh emits x86_64 libswiftcompat.dylib (not artifacts/ arm64)"
    else
        die_test "libswiftcompat fill did not produce x86 Mach-O ($(tail -5 "$STUB_DEST/shim-work/build_compat.log" 2>/dev/null))"
    fi
    phase2_fill_x86_base_swift_dylibs "$STUB_DEST" || true
    if phase2_is_x86_macho \
        "$STUB_DEST/darwin/usr/lib/swift/libswift_Concurrency.dylib"; then
        ok "layout stages x86 libswift_Concurrency.dylib from overlay search"
    else
        die_test "libswift_Concurrency.dylib was not staged as x86 Mach-O"
    fi
    if [ -f "$STUB_DEST/darwin/usr/lib/swift/libswiftObjectiveC.dylib" ]; then
        if phase2_is_loadable_x86_overlay \
            "$STUB_DEST/darwin/usr/lib/swift/libswiftObjectiveC.dylib"; then
            art=$ROOT/swiftcore-macho/artifacts/swift-macosx/x86_64/libswiftObjectiveC.dylib
            if cmp -s "$STUB_DEST/darwin/usr/lib/swift/libswiftObjectiveC.dylib" "$art"; then
                ok "layout stages loadable libswiftObjectiveC.dylib from artifacts"
            else
                die_test "staged libswiftObjectiveC.dylib does not match artifacts"
            fi
        else
            die_test "libswiftObjectiveC.dylib present but is a cache extract"
        fi
    else
        die_test "libswiftObjectiveC.dylib absent (artifacts has a from-source build)"
    fi
    rm -rf "$STUB_DEST"
else
    die_test "x86 sysroot missing; cannot build loud-abort stubs"
fi

expect_grep 'x86_unexported_symbols.txt' \
    "$ROOT/swiftcore-macho/scripts/build_compat.sh" \
    "x86 compat omits overlap via the committed unexport list"
expect_file "$ROOT/swiftcore-macho/sdk/compat/x86_unexported_symbols.txt"
expect_file "$ROOT/swiftcore-macho/artifacts/libswiftcompat.source.json"
expect_file "$ROOT/swiftcore-macho/scripts/test_compat_source.sh"
if bash "$ROOT/swiftcore-macho/scripts/test_compat_source.sh"; then
    ok "swiftcompat.c sha matches the pin beside artifacts/libswiftcompat.dylib"
else
    die_test "swiftcompat.c sha disagrees with artifacts/libswiftcompat.source.json"
fi
# The source-pin test must fail when the recorded sha is not the file's sha.
PIN_FIX=$(mktemp -d /tmp/phase2-compat-pin.XXXXXX)
python3 - "$ROOT/swiftcore-macho/artifacts/libswiftcompat.source.json" \
    "$PIN_FIX/bad.json" <<'PY'
import json, sys
from pathlib import Path
pin = json.loads(Path(sys.argv[1]).read_text())
pin["swiftcompat.c"]["sha256"] = "0" * 64
Path(sys.argv[2]).write_text(json.dumps(pin))
PY
if COMPAT_SOURCE_PIN=$PIN_FIX/bad.json \
    bash "$ROOT/swiftcore-macho/scripts/test_compat_source.sh" >/dev/null 2>&1; then
    die_test "test_compat_source.sh passed with a mismatched swiftcompat.c sha"
else
    ok "test_compat_source.sh fails when swiftcompat.c sha disagrees with the pin"
fi
rm -rf "$PIN_FIX"

echo "== env-prepare with FULL_OUT_SUFFIX=-x86_64 never resolves unsuffixed arm64 trees"
PREP_FIX=$(mktemp -d /tmp/phase2-prepare-suffix.XXXXXX)
mkdir -p "$PREP_FIX/env" \
    "$PREP_FIX/scratch/sysroot_fe4/usr/include" \
    "$PREP_FIX/scratch/mrroot/darwin/usr/lib/swift" \
    "$PREP_FIX/scratch/mrroot_full/darwin/usr/lib" \
    "$PREP_FIX/scratch/mrroot_fe/darwin/usr/lib/swift"
cp "$ROOT/env/contract.json" "$PREP_FIX/env/contract.json"
echo trap > "$PREP_FIX/scratch/sysroot_fe4/usr/include/.trap"
prep_out=$(FULL_OUT_SUFFIX=-x86_64 python3 "$PREPARE" \
    --root "$PREP_FIX" --gate focus-widget --verify-only --no-fetch)
if echo "$prep_out" | grep -E 'id=sysroot_fe4 .*sysroot_fe4-x86_64' >/dev/null \
    && echo "$prep_out" | grep -E 'id=mrroot-base-runtime .*mrroot-x86_64' >/dev/null \
    && echo "$prep_out" | grep -E 'id=mrroot_full .*mrroot_full-x86_64' >/dev/null \
    && ! echo "$prep_out" | grep ENV_PREPARE_ | grep -E '/scratch/(mrroot_full|mrroot_fe|sysroot_fe4|mrroot)(/| |$)' | grep -v -- '-x86_64' >/dev/null; then
    ok "prepare.py FULL_OUT_SUFFIX=-x86_64 resolves only suffixed trees"
else
    die_test "prepare.py suffix resolution leaked unsuffixed trees: $(echo "$prep_out" | grep ENV_PREPARE_ | grep -E 'sysroot_fe4|mrroot' | head -20)"
fi
echo "$prep_out" | grep -q 'CANNOT_X86_OVERLAYS_NOT_BUILT' \
    && ok "prepare.py x86 overlays emit CANNOT_X86_OVERLAYS_NOT_BUILT" \
    || die_test "prepare.py missing CANNOT_X86_OVERLAYS_NOT_BUILT"
if echo "$prep_out" | grep 'id=tbd-stubs' | grep -q 'CURSOR_ENV_CANNOT_GENERATE_TBD'; then
    die_test "tbd-stubs still refused by host=x86_64"
else
    ok "tbd-stubs is not host=x86_64 CANNOT_GENERATE_TBD"
fi
rm -rf "$PREP_FIX"

echo "== ud-guest-x86 uses committed linker, suffixed tree, reused FE objects"
expect_file "$UDINC"
expect_grep 'ud-guest-x86' "$PHASE2" "phase2 item ud-guest-x86"
expect_grep 'phase2_try_ud_guest' "$PHASE2" "phase2 invokes the ud-guest producer"
expect_grep 'SwiftOverlayShims.timeval' "$PHASE2" \
    "ud-guest -sdk comment names SwiftOverlayShims.timeval"
python3 - "$PHASE2" <<'PY' && ok "try_ud_guest third arg is FE_CLANG_SYS" || die_test "try_ud_guest still passes overlay-copied SYS"
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
start = text.find("ud_report=$(phase2_try_ud_guest")
if start < 0:
    raise SystemExit("call not found")
end = text.find("|| true)", start)
chunk = text[start:end]
args = re.findall(r'"\$([A-Z0-9_]+)"', chunk)
if len(args) < 3 or args[2] != "FE_CLANG_SYS":
    raise SystemExit(f"args={args} chunk={chunk!r}")
PY
python3 - "$PHASE2" <<'PY' && ok "try_ud_score_guest sysroot arg is FE_CLANG_SYS" || die_test "try_ud_score_guest still passes overlay-copied SYS"
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
start = text.find("score_report=$(phase2_try_ud_score_guest")
if start < 0:
    raise SystemExit("score call not found")
end = text.find("|| true)", start)
chunk = text[start:end]
if '"$FE_CLANG_SYS"' not in chunk:
    raise SystemExit(chunk)
if re.search(r'"\$SYS"', chunk):
    raise SystemExit(f"still passes SYS: {chunk!r}")
PY
expect_grep 'foundation-macho/scripts/link_ud_guest.sh' "$UDINC" \
    "producer names the committed linker"
expect_grep 'foundation-macho/scripts/link_ud_guest.sh' "$PHASE2" \
    "phase2 still names the committed linker"
expect_grep 'link_ud_guest.log' "$UDINC" "ud-guest spills the linker log to the work-tree root"
expect_grep 'link_ud_guest.sh exit $st log=$log' "$UDINC" \
    "UD_GUEST CANNOT names log= (does not flatten ld64)"
expect_grep 'Never both' "$ROOT/foundation-macho/scripts/link_ud_guest.sh" \
    "linker takes one _RopeModule.o, never both copies"
expect_grep 'clang-18' "$ROOT/foundation-macho/scripts/link_ud_guest.sh" \
    "link_ud_guest prefers clang-18"
expect_grep '-nostdlib' "$ROOT/foundation-macho/scripts/link_ud_guest.sh" \
    "link_ud_guest is -nostdlib"
if grep -E '^[^#]*build_fe\.sh' "$UDINC" >/dev/null; then
    die_test "ud-guest-x86 invokes build_fe.sh"
else
    ok "ud-guest-x86 does not compile FE a second time"
fi
expect_grep 'scratch/ud-guest-x86_64' "$UDINC" "work tree is suffixed"
expect_grep 'refusing unsuffixed/arm64 ud-guest work tree' "$UDINC" \
    "unsuffixed work tree is a named CANNOT"
expect_grep 'export UD_GUEST_BIN' "$PHASE2" "successful link exports UD_GUEST_BIN for rung a"
expect_grep 'phase2_stage_cftest_into_run_root' "$UDINC" \
    "libCFTest is staged into the run root after link"
expect_grep 'src_sha' "$UDINC" "run-root stager compares source sha to dest sha"
expect_grep 'libCFTest.dylib.inputs' "$UDINC" \
    "ud-guest names the libCFTest input stamp"
expect_grep 'ud_guest.inputs' "$ROOT/foundation-macho/scripts/link_ud_guest.sh" \
    "link_ud_guest writes bin/ud_guest.inputs"
expect_grep 'reused=1 stamp=' "$ROOT/foundation-macho/scripts/build_cftest_harness.sh" \
    "harness prints reused=1 stamp="
expect_grep 'reason=inputs' "$ROOT/foundation-macho/scripts/build_cftest_harness.sh" \
    "harness prints reason=inputs on stamp mismatch"
expect_grep 'CANNOT_CFTEST_STALE' "$UDINC" \
    "stub list newer than dylib is CANNOT_CFTEST_STALE"
expect_grep 'CANNOT_CFTEST_STALE' "$PHASE2" \
    "phase2 maps CANNOT_CFTEST_STALE to cftest-stubs"
expect_grep 'phase2_cftest_stub_list_stale' "$PHASE2" \
    "cftest-stubs satisfied requires the dylib not older than the stub list"
expect_grep 'never on a present' "$ROOT/scripts/x86/PHASE2.md" \
    "PHASE2.md documents stamp reuse, not sibling stub files"
expect_grep 'phase2_stage_cftest_into_run_root' "$PHASE2" \
    "phase2 stages libCFTest after ud-guest link, before rung a"
expect_grep 'libCFTest-run-root' "$PHASE2" "ENV_PREPARE item names libCFTest-run-root"
expect_grep 'phase2_ud_guest_ensure_dispatch' "$UDINC" \
    "ud-guest builds/reuses the Dispatch host bridge + Darwin runtime"
expect_grep 'phase2_ud_guest_ensure_dispatch' "$PHASE2" \
    "phase2 invokes ud-guest-dispatch before rung a"
expect_grep 'ud-guest-dispatch' "$PHASE2" "ENV_PREPARE item names ud-guest-dispatch"
expect_grep 'DISPATCH_HOST=${UD_DISPATCH_HOST:-}' "$PHASE2" \
    "rung a passes DISPATCH_HOST into run_ud_guest.sh"
expect_grep 'DISPATCH_DARWIN=${UD_DISPATCH_DARWIN:-}' "$PHASE2" \
    "rung a passes DISPATCH_DARWIN into the runners"
expect_grep 'build_host_bridge.sh' "$UDINC" \
    "ud-guest-dispatch reuses full/dispatch/build_host_bridge.sh"
expect_grep 'OpenDispatchBridge.c' "$UDINC" \
    "ud-guest-dispatch links the Darwin OpenDispatch facade"
expect_grep 'run-root loader refresh' "$PHASE2" \
    "phase2 refreshes \$MRROOT/machorun before rung a (stamp, not -nt)"
expect_grep 'ud_dispatch_loader_line' "$ROOT/foundation-macho/scripts/run_ud_guest.sh" \
    "run_ud_guest.sh prints loader sha256 on == binary"
expect_grep 'LD_PRELOAD' "$ROOT/foundation-macho/scripts/ud_dispatch_run.inc" \
    "runner helper LD_PRELOADs the host bridge"
expect_grep 'darwin/usr/lib/libOpenDispatch.dylib' \
    "$ROOT/foundation-macho/scripts/ud_dispatch_run.inc" \
    "runner helper stages the Darwin runtime image"
expect_grep 'darwin/usr/lib/libCFTest.dylib' "$PHASE2" \
    "libCFTest stage names the run-root path"
expect_grep 'CoreFoundation slot is a byte-identical copy' "$UDINC" \
    "run-root stager refuses a duplicate CF framework slot"
expect_grep 'build_full.sh does not stage libCFTest' "$UDINC" \
    "libCFTest staging is not routed through build_full.sh"
expect_grep 'CANNOT_UD_GUEST_' "$UDINC" "refusal markers use CANNOT_UD_GUEST_"
expect_grep 'LIBCFTEST libCFTest.dylib' "$UDINC" "CF hole names file=libCFTest.dylib"
expect_grep 'CANNOT_CFTEST_STUBS' "$UDINC" "stub-set refusal is CANNOT_CFTEST_STUBS"
expect_grep 'phase2_ud_guest_format_stub_cannot' "$UDINC" \
    "ud-guest formats count= and first= for the stub CANNOT"
expect_grep 'phase2_ud_guest_ensure_icu_checkout' "$UDINC" \
    "ud-guest fetches the pinned ICU checkout"
expect_grep 'cftest-stubs' "$PHASE2" "ENV_PREPARE item names cftest-stubs"
expect_grep 'CANNOT_CFTEST_STUBS' "$PHASE2" "phase2 maps CANNOT_CFTEST_STUBS to cftest-stubs"
expect_grep 'Will not link ud_guest against it' "$PHASE2" \
    "unexpected stub set does not proceed to link_ud_guest.sh"
expect_grep 'USERDEFAULTSGUEST UserDefaultsGuest.o' "$UDINC" "port hole names file=UserDefaultsGuest.o"
expect_grep 'overlay-posix' "$UDINC" \
    "UserDefaultsGuest swiftc gets overlay-posix -I (ioctl not in Darwin sysroot)"
expect_grep 'UserDefaultsGuest.swiftc.log' "$UDINC" "port swiftc output is spilled to a file"
expect_grep 'runner.swiftc.log' "$UDINC" "runner swiftc output is spilled to a file"
expect_grep '_FoundationCShims' "$UDINC" "port/runner pass the CShims module map"
expect_grep 'phase2_ensure_sdk_settings' "$UDINC" "ud-guest compile writes SDKSettings.json if missing"
expect_grep 'phase2_ensure_sdk_settings' "$STAGE" "x86 sysroot stager writes SDKSettings.json"
expect_grep 'SDKSettings.json' "$COMMON" "SDKSettings.json helper is shared"
expect_grep 'RUNNER runner.o' "$UDINC" "runner hole names file=runner.o"
expect_grep 'build_ud_score_guest.sh' "$UDINC" "port/runner argv follows the committed scoreboard compile"
expect_grep 'phase2_try_ud_score_guest' "$UDINC" \
    "ud_guest.inc produces bin/ud_score_guest through the committed recipe"
expect_grep 'phase2_try_ud_score_guest' "$PHASE2" \
    "phase2 invokes the ud-score-guest producer"
expect_grep 'ud-score-guest' "$PHASE2" "ENV_PREPARE item names ud-score-guest"
expect_grep 'bin/ud_score_guest' "$UDINC" "scoreboard output is scratch/ud-guest-x86_64/bin/ud_score_guest"
expect_grep 'ud_score_guest.otool.txt' "$UDINC" "otool evidence sits beside ud_score_guest"
expect_grep 'darwin-golden-2026-08-28.txt' "$UDINC" \
    "scoreboard embeds the carried darwin golden"
expect_grep 'GUEST SCOREBOARD' "$PHASE2" \
    "phase2 reports run_ud_persist.sh GUEST SCOREBOARD denominators"
expect_grep 'Success bar unchanged' "$PHASE2" \
    "persist success bar is still committed run_ud_persist.sh"
expect_grep 'PREFS:=$HOME/Library/Preferences' "$PHASE2" \
    "persist witness looks at \$HOME/Library/Preferences (Cursor HOME is not /root)"
expect_grep 'persist_presence=$(sed -n' "$PHASE2" \
    "presence line is taken from the positive persist board, not the control"
expect_not_grep "grep 'presence:' \"\$W/scratch/phase2-rung-a-persist.log\" | tail -1" "$PHASE2" \
    "does not quote the NEGATIVE CONTROL presence 0/17 on the scoreboard"
expect_grep 'OrderedCollections.swiftmodule' "$UDINC" \
    "ud-guest stages OrderedCollections.swiftmodule next to the .o"
expect_grep '_RopeModule.swiftmodule' "$UDINC" \
    "ud-guest stages _RopeModule.swiftmodule next to the .o"
expect_grep 'InternalCollectionsUtilities.swiftmodule' "$UDINC" \
    "ud-guest stages InternalCollectionsUtilities.swiftmodule"
expect_grep '-I "$fe_out/collections"' "$UDINC" \
    "port/runner argv has -I fe_out/collections (build_url_runner / PR #28 class)"
expect_grep '-I "$ud_w/fe/collections"' "$UDINC" \
    "port/runner argv has -I staged fe/collections"
expect_grep 'phase2_ud_guest_compile_port "$ud_w" "$repo" "$sys" "$compile_triple" "$mc" "$fe_out"' \
    "$UDINC" "try_ud_guest passes fe_out onto the port argv"
expect_grep 'build_full.sh argv -O1 -nostdinc' "$UDINC" \
    "fm_unimplemented uses build_full.sh clang argv"
expect_grep 'build_cftest_harness.sh' "$UDINC" "CF path names the committed CF linker"
expect_file "$ROOT/foundation-macho/scripts/build_cfobjc.sh"
expect_grep 'build_cfobjc.sh' "$UDINC" "CF path names the committed cfobjc recipe"
expect_grep 'PHASE2_UD_GUEST_CF_COMMIT=f3a7a34302317a95665bf4ff1a62ee1b459c1695' \
    "$UDINC" "ud-guest-x86 pins the census CF commit"
expect_grep 'PHASE2_UD_GUEST_CF_TREE=2f9136f253a51406f2bcb0a612bcb6a9eba03570' \
    "$UDINC" "ud-guest-x86 pins the census CF tree"
expect_grep 'PHASE2_UD_GUEST_ICU_COMMIT=87dbab99780e277b6a4c2a397ab1a894f877b39a' \
    "$UDINC" "ud-guest-x86 pins the ICU headers commit"
expect_grep 'scratch/swift-foundation-icu' "$UDINC" "ICU checkout dest is the contract tree"
expect_grep 'scratch/ud-guest-x86_64/cf' "$UDINC" "CF checkout dest is under the suffixed work tree"
expect_grep 'phase2_ud_guest_ensure_cf_checkout' "$UDINC" "ud-guest fetches the pinned CF checkout"
expect_grep '"id": "swift-corelibs-foundation"' "$ROOT/env/contract.json" \
    "contract names the CF checkout"
expect_grep 'f3a7a34302317a95665bf4ff1a62ee1b459c1695' "$ROOT/env/contract.json" \
    "contract pins the census CF commit"
expect_grep '"ud-guest-x86"' "$ROOT/env/contract.json" \
    "contract demanded_by includes ud-guest-x86"
expect_grep 'clone-pinned-repo.sh' "$UDINC" \
    "ud-guest fetches CF through clone-pinned-repo.sh"
expect_not_grep 'scf-full' "$UDINC" \
    "does not ask the operator to stage HOME/scf-full"
expect_not_grep 'CF sources missing' "$UDINC" \
    "does not ask the operator to stage CF sources"
expect_grep 'build_cfobjc.sh' "$ROOT/scripts/x86/PHASE2.md" \
    "PHASE2.md names the committed cfobjc recipe"
expect_grep 'cftest-stubs' "$ROOT/scripts/x86/PHASE2.md" \
    "PHASE2.md names the cftest-stubs ENV_PREPARE item"
expect_grep 'CANNOT_CFTEST_STUBS' "$ROOT/scripts/x86/PHASE2.md" \
    "PHASE2.md names CANNOT_CFTEST_STUBS"
expect_grep 'Will not invent a stub dylib' "$UDINC" \
    "does not invent a stub libCFTest.dylib"
expect_not_grep 'no committed recipe (shell-history only)' "$UDINC" \
    "recipe is committed; no longer a shell-history hole"
expect_not_grep 'Will not invent a CF compiler or a stub' "$UDINC" \
    "recipe exists; CF compiler is build_cfobjc.sh"
for load in libswiftCore libswiftDarwin libswift_StringProcessing \
    libswiftSynchronization libswift_errno libobjc libSystem libCFTest libswiftcompat
do
    expect_grep "$load" "$UDINC" "expected load $load is in the otool census"
done
expect_not_grep 'Operator: stage CF+FE objects, link_ud_guest.sh, then re-run' \
    "$PHASE2" "rung a no longer asks the operator to hand-stage the binary"

echo "== ud-guest-x86 refusal + staging resolution"
UDWORK=$(mktemp -d /tmp/phase2-ud-guest.XXXXXX)
SYS=${SYS:-$ROOT/scratch/sysroot_fe4-x86_64}
if [ ! -d "$SYS/usr/include" ]; then
    SYS=$UDWORK/fake-x86-sdk
    mkdir -p "$SYS/usr/include" "$SYS/usr/lib"
    emit_tbd() {
        local dest=$1 install=$2
        cat >"$dest" <<EOF
--- !tapi-tbd
tbd-version:     4
targets:         [ x86_64-macos ]
install-name:    '$install'
current-version: 1
compatibility-version: 1
exports:
  - targets:   [ x86_64-macos ]
    symbols:   [ '_dummy_tbd' ]
...
EOF
    }
    emit_tbd "$SYS/usr/lib/libSystem.B.tbd" "/usr/lib/libSystem.B.dylib"
    ln -sfn libSystem.B.tbd "$SYS/usr/lib/libSystem.tbd"
    emit_tbd "$SYS/usr/lib/libobjc.A.tbd" "/usr/lib/libobjc.A.dylib"
    ln -sfn libobjc.A.tbd "$SYS/usr/lib/libobjc.tbd"
    mkdir -p "$SYS/usr/include/objc"
    cat >"$SYS/usr/include/objc/NSObject.h" <<'EOF'
#ifndef _TEST_NSOBJECT_H_
#define _TEST_NSOBJECT_H_
typedef struct objc_class *Class;
typedef struct objc_object { Class isa; } *id;
typedef struct objc_selector *SEL;
@interface NSObject
+ (void)initialize;
- (void)doesNotRecognizeSelector:(SEL)s;
@end
#endif
EOF
    echo "NOTE: scratch/sysroot_fe4-x86_64 absent; dummy Mach-O fixtures use $SYS"
fi
# shellcheck source=common.inc
. "$COMMON"

unsuf=$(phase2_ud_guest_refuse_unsuffixed "$UDWORK/scratch/ud-guest" || true)
case "$unsuf" in
    CANNOT_UD_GUEST_WORKTREE\ file=*reason=refusing\ unsuffixed/arm64*)
        ok "unsuffixed work tree is CANNOT_UD_GUEST_WORKTREE"
        ;;
    *) die_test "unsuffixed refusal got: $unsuf" ;;
esac

wt=$(phase2_ud_guest_worktree "$UDWORK")
if [ "$wt" = "$UDWORK/scratch/ud-guest-x86_64" ]; then
    ok "worktree helper is scratch/ud-guest-x86_64"
else
    die_test "worktree helper got $wt"
fi

score_env=$(phase2_prepare ud-score-guest "cold-built bin=$wt/bin/ud_score_guest")
if echo "$score_env" | grep -q "^ENV_PREPARE ud-score-guest cold-built bin=$wt/bin/ud_score_guest$"; then
    ok "ENV_PREPARE ud-score-guest cold-built line"
else
    die_test "ud-score-guest ENV_PREPARE got: $score_env"
fi
score_ok=$(phase2_prepare ud-score-guest "satisfied bin=$wt/bin/ud_score_guest")
if echo "$score_ok" | grep -q "^ENV_PREPARE ud-score-guest satisfied bin=$wt/bin/ud_score_guest$"; then
    ok "ENV_PREPARE ud-score-guest satisfied line"
else
    die_test "ud-score-guest satisfied ENV_PREPARE got: $score_ok"
fi

echo "== CANNOT_CFTEST_STUBS ENV_PREPARE payload is count= + first five names"
stub_line=$(phase2_ud_guest_format_stub_cannot \
    'CANNOT_CFTEST_STUBS extra=CFStringCreateWithBytes,CFCalendarCreateWithIdentifier,CFCharacterSetCreateWithCharactersInString,CFLocaleCreate,CFRunLoopGetCurrent,CFBundleAllowMixedLocalizations missing=' || true)
case "$stub_line" in
    CANNOT_CFTEST_STUBS\ file=libCFTest.dylib\ count=6\ first=CFStringCreateWithBytes,CFCalendarCreateWithIdentifier,CFCharacterSetCreateWithCharactersInString,CFLocaleCreate,CFRunLoopGetCurrent\ extra=CFStringCreateWithBytes,*)
        ok "format_stub_cannot count=6 first= five names (CFStringCreateWithBytes first)"
        ;;
    *)
        die_test "format_stub_cannot got: $stub_line"
        ;;
esac

missing=$(phase2_ud_guest_stage_fe "$UDWORK/foundation" "$wt" || true)
case "$missing" in
    CANNOT_UD_GUEST_FOUNDATIONESSENTIALS\ file=FoundationEssentials.o*)
        ok "missing FE object is CANNOT_UD_GUEST_FOUNDATIONESSENTIALS file=FoundationEssentials.o"
        ;;
    *) die_test "missing FE refusal got: $missing" ;;
esac

if [ -d "$SYS/usr/include" ]; then
    fe=$UDWORK/foundation
    mkdir -p "$fe/essentials" "$fe/collections" "$fe/os" "$fe/cshims"
    echo 'int ud_guest_probe=1;' | clang-18 -target x86_64-apple-macos15.0 \
        -isysroot "$SYS" -c -o "$fe/essentials/FoundationEssentials.o" -x c -
    echo 'int ud_guest_probe=1;' | clang-18 -target x86_64-apple-macos15.0 \
        -isysroot "$SYS" -c -o "$fe/collections/OrderedCollections.o" -x c -
    echo 'int ud_guest_probe=1;' | clang-18 -target x86_64-apple-macos15.0 \
        -isysroot "$SYS" -c -o "$fe/collections/InternalCollectionsUtilities.o" -x c -
    echo 'int ud_guest_probe=1;' | clang-18 -target x86_64-apple-macos15.0 \
        -isysroot "$SYS" -c -o "$fe/collections/_RopeModule.o" -x c -
    echo 'int ud_guest_probe=1;' | clang-18 -target x86_64-apple-macos15.0 \
        -isysroot "$SYS" -c -o "$fe/os/os.o" -x c -
    echo 'int ud_guest_probe=1;' | clang-18 -target x86_64-apple-macos15.0 \
        -isysroot "$SYS" -c -o "$fe/cshims/platform_shims.o" -x c -
    echo 'int ud_guest_probe=1;' | clang-18 -target x86_64-apple-macos15.0 \
        -isysroot "$SYS" -c -o "$fe/cshims/string_shims.o" -x c -
    echo 'int ud_guest_probe=1;' | clang-18 -target x86_64-apple-macos15.0 \
        -isysroot "$SYS" -c -o "$fe/cshims/uuid.o" -x c -
    : > "$fe/essentials/FoundationEssentials.swiftmodule"
    : > "$fe/collections/OrderedCollections.swiftmodule"
    : > "$fe/collections/InternalCollectionsUtilities.swiftmodule"
    : > "$fe/collections/_RopeModule.swiftmodule"
    : > "$fe/os/os.swiftmodule"
    staged=$(phase2_ud_guest_stage_fe "$fe" "$wt" || true)
    case "$staged" in
        OK\ fe-staged*)
            if [ -f "$wt/fe/module/FoundationEssentials.o" ] \
                && [ -f "$wt/fe/collections/OrderedCollections.o" ] \
                && [ -f "$wt/fe/collections/OrderedCollections.swiftmodule" ] \
                && [ -f "$wt/fe/collections/_RopeModule.o" ] \
                && [ -f "$wt/fe/collections/_RopeModule.swiftmodule" ] \
                && [ -f "$wt/fe/_RopeModule.o" ] \
                && [ -f "$wt/fe/os/os.o" ] \
                && [ -f "$wt/fe/cshims/uuid.o" ] \
                && phase2_is_x86_macho "$wt/fe/module/FoundationEssentials.o"; then
                ok "staging maps build/full-x86_64/foundation into scratch/ud-guest-x86_64/fe"
            else
                die_test "staged layout incomplete under $wt/fe"
            fi
            ;;
        *) die_test "staging resolution got: $staged" ;;
    esac
else
    die_test "x86 sysroot missing; cannot compile staging fixtures"
fi

# Wrong-tree dest refuses and names the pin. Does not fetch over it.
mkdir -p "$wt/cf"
git -c safe.directory="$wt/cf" init -q "$wt/cf"
git -c safe.directory="$wt/cf" -C "$wt/cf" config user.email test@example.com
git -c safe.directory="$wt/cf" -C "$wt/cf" config user.name test
echo wrong > "$wt/cf/README"
git -c safe.directory="$wt/cf" -C "$wt/cf" add README
git -c safe.directory="$wt/cf" -C "$wt/cf" commit -q -m wrong
cfreport=$(phase2_ud_guest_ensure_cftest "$wt" "$ROOT" || true)
case "$cfreport" in
    CANNOT_UD_GUEST_LIBCFTEST\ file=libCFTest.dylib*)
        if echo "$cfreport" | grep -q 'f3a7a34302317a95665bf4ff1a62ee1b459c1695' \
            && echo "$cfreport" | grep -q 'CF checkout tree differs' \
            && echo "$cfreport" | grep -q 'Will not invent a stub dylib'; then
            ok "wrong CF tree is CANNOT_UD_GUEST_LIBCFTEST naming commit f3a7a343"
        else
            die_test "wrong-tree refusal did not name the pin: $cfreport"
        fi
        ;;
    *) die_test "wrong-tree CF refusal got: $cfreport" ;;
esac
rm -rf "$wt/cf"

# A leftover non-git dest (operator-staged tree) is also a named refusal.
mkdir -p "$wt/cf"
echo staged-by-operator > "$wt/cf/README"
cfreport=$(phase2_ud_guest_ensure_cftest "$wt" "$ROOT" || true)
case "$cfreport" in
    CANNOT_UD_GUEST_LIBCFTEST\ file=libCFTest.dylib*)
        if echo "$cfreport" | grep -q 'f3a7a34302317a95665bf4ff1a62ee1b459c1695' \
            && echo "$cfreport" | grep -q 'not a git checkout' \
            && [ -f "$wt/cf/README" ]; then
            ok "non-git CF dest is CANNOT_UD_GUEST_LIBCFTEST naming commit f3a7a343 (not overwritten)"
        else
            die_test "non-git dest refusal did not name the pin: $cfreport"
        fi
        ;;
    *) die_test "non-git CF dest refusal got: $cfreport" ;;
esac
rm -rf "$wt/cf"

# A provided x86 dylib is accepted (resolution path for the CF hole).
echo 'int ud_cftest=1;' | clang-18 -target x86_64-apple-macos15.0 \
    -isysroot "$SYS" -c -o "$UDWORK/cftest.o" -x c -
clang-18 -target x86_64-apple-macos15.0 -isysroot "$SYS" \
    -fuse-ld=lld -B /usr/lib/llvm-18/bin -nostdlib -dynamiclib \
    -install_name /usr/lib/libCFTest.dylib \
    "$UDWORK/cftest.o" -o "$UDWORK/libCFTest.dylib" 2>/dev/null \
    || clang-18 -target x86_64-apple-macos15.0 -isysroot "$SYS" \
        -fuse-ld=lld -B /usr/lib/llvm-18/bin -dynamiclib \
        -install_name /usr/lib/libCFTest.dylib \
        "$UDWORK/cftest.o" -o "$UDWORK/libCFTest.dylib"
if phase2_is_x86_macho "$UDWORK/libCFTest.dylib"; then
    UD_CFTEST_DYLIB=$UDWORK/libCFTest.dylib
    cfok=$(phase2_ud_guest_ensure_cftest "$wt" "$ROOT" || true)
    if [ -z "$cfok" ] && [ -f "$wt/lib/libCFTest.dylib" ] \
        && phase2_is_x86_macho "$wt/lib/libCFTest.dylib"; then
        ok "UD_CFTEST_DYLIB stages an x86 libCFTest.dylib into the suffixed tree"
    else
        die_test "UD_CFTEST_DYLIB resolution got: '$cfok'"
    fi
    echo "== libCFTest stage into the run root (after link, before run)"
    CFROOT=$(mktemp -d /tmp/phase2-cftest-root.XXXXXX)
    cstage=$(phase2_stage_cftest_into_run_root "$UDWORK/libCFTest.dylib" "$CFROOT" || true)
    case "$cstage" in
        status=cold-built\ path=*sha256=*)
            dest=${cstage#*path=}
            dest=${dest%% *}
            sha=${cstage##*sha256=}
            want=$(sha256sum "$CFROOT/darwin/usr/lib/libCFTest.dylib" | awk '{print $1}')
            env_line=$(phase2_prepare libCFTest-run-root "cold-built path=$dest sha256=$sha")
            if [ "$dest" = "$CFROOT/darwin/usr/lib/libCFTest.dylib" ] \
                && [ "$sha" = "$want" ] \
                && [ -f "$CFROOT/darwin/usr/lib/libCFTest.dylib" ] \
                && phase2_is_x86_macho "$CFROOT/darwin/usr/lib/libCFTest.dylib" \
                && [ ! -e "$CFROOT/darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" ] \
                && echo "$env_line" | grep -q "ENV_PREPARE libCFTest-run-root cold-built path=$dest sha256=$sha"
            then
                ok "libCFTest stages into run-root darwin/usr/lib (ENV_PREPARE path+sha256; not the CF slot)"
            else
                die_test "libCFTest stage dest/sha/ENV_PREPARE mismatch: '$cstage' env='$env_line'"
            fi
            ;;
        *) die_test "libCFTest run-root stage got: '$cstage'" ;;
    esac
    again=$(phase2_stage_cftest_into_run_root "$UDWORK/libCFTest.dylib" "$CFROOT" || true)
    case "$again" in
        status=satisfied\ path=*sha256=*)
            ok "libCFTest re-stage of an identical dest is satisfied"
            ;;
        *) die_test "identical re-stage got: '$again'" ;;
    esac
    echo 'int ud_cftest=2;' | clang-18 -target x86_64-apple-macos15.0 \
        -isysroot "$SYS" -c -o "$UDWORK/cftest2.o" -x c -
    clang-18 -target x86_64-apple-macos15.0 -isysroot "$SYS" \
        -fuse-ld=lld -B /usr/lib/llvm-18/bin -nostdlib -dynamiclib \
        -install_name /usr/lib/libCFTest.dylib \
        "$UDWORK/cftest2.o" -o "$UDWORK/libCFTest2.dylib" 2>/dev/null \
        || clang-18 -target x86_64-apple-macos15.0 -isysroot "$SYS" \
            -fuse-ld=lld -B /usr/lib/llvm-18/bin -dynamiclib \
            -install_name /usr/lib/libCFTest.dylib \
            "$UDWORK/cftest2.o" -o "$UDWORK/libCFTest2.dylib"
    src2=$(sha256sum "$UDWORK/libCFTest2.dylib" | awk '{print $1}')
    dest1=$(sha256sum "$CFROOT/darwin/usr/lib/libCFTest.dylib" | awk '{print $1}')
    if [ "$src2" != "$dest1" ]; then
        changed=$(phase2_stage_cftest_into_run_root "$UDWORK/libCFTest2.dylib" "$CFROOT" || true)
        case "$changed" in
            status=cold-built\ path=*sha256=$src2)
                ok "libCFTest re-stage copies when source sha differs from dest sha"
                ;;
            *) die_test "different-sha re-stage got: '$changed' want sha256=$src2" ;;
        esac
    else
        die_test "could not emit a different-sha libCFTest fixture"
    fi
    mkdir -p "$CFROOT/darwin/System/Library/Frameworks/CoreFoundation.framework"
    cp -f "$UDWORK/libCFTest.dylib" \
        "$CFROOT/darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"
    dup=$(phase2_stage_cftest_into_run_root "$UDWORK/libCFTest.dylib" "$CFROOT" || true)
    case "$dup" in
        CANNOT_UD_GUEST_LIBCFTEST\ file=libCFTest.dylib*byte-identical*)
            ok "libCFTest stage refuses a byte-identical CoreFoundation slot"
            ;;
        *) die_test "duplicate CF slot got: '$dup'" ;;
    esac
    rm -rf "$CFROOT"
    unset UD_CFTEST_DYLIB

    echo "== libCFTest reuse is stamp-keyed, not sibling stub files"
    mkdir -p "$wt/cfobjc/obj" "$wt/nscfobj" "$wt/lib"
    echo 'int cfobjc_probe=1;' | clang-18 -target x86_64-apple-macos13.0 \
        -c -o "$wt/cfobjc/obj/CFString.o" -x c -
    echo 'int nscf_probe=1;' | clang-18 -target x86_64-apple-macos13.0 \
        -c -o "$wt/nscfobj/NSCFConstantString.o" -x c -
    cp "$ROOT/foundation-macho/docs/cf-census/cftest-stub-func-active.txt" \
        "$wt/stub-func-active.txt"
    cp "$ROOT/foundation-macho/docs/cf-census/cftest-stub-data.txt" \
        "$wt/stub-data.txt"
    rm -f "$wt/lib/libCFTest.dylib.inputs"
    # dest from UD_CFTEST_DYLIB is present; stub files match the pin.
    pin_sha=$(sha256sum "$wt/lib/libCFTest.dylib" | awk '{print $1}')
    pin_report=$(phase2_ud_guest_ensure_cftest "$wt" "$ROOT" "$SYS" || true)
    pin_sha_after=$(sha256sum "$wt/lib/libCFTest.dylib" | awk '{print $1}')
    case "$pin_report" in
        ''|status=satisfied*)
            die_test "pin-matching stub files reused the dylib without an input stamp: '$pin_report'"
            ;;
        CANNOT_*)
            if [ "$pin_sha" = "$pin_sha_after" ]; then
                ok "pin-matching stub files without .inputs do not reuse (got $pin_report)"
            else
                die_test "pin-without-stamp mutated dest sha $pin_sha->$pin_sha_after report=$pin_report"
            fi
            ;;
        *)
            die_test "pin-without-stamp got: '$pin_report'"
            ;;
    esac

    mkdir -p "$wt/stub-mtime/lib"
    echo dylib > "$wt/stub-mtime/lib/libCFTest.dylib"
    echo stubs > "$wt/stub-mtime/stub-func-active.txt"
    touch -d '2020-01-01 00:00:00 UTC' "$wt/stub-mtime/lib/libCFTest.dylib"
    touch "$wt/stub-mtime/stub-func-active.txt"
    if phase2_cftest_stub_list_stale "$wt/stub-mtime"; then
        stale_line=$(phase2_cftest_stub_stale_cannot "$wt/stub-mtime")
        case "$stale_line" in
            CANNOT_CFTEST_STALE\ file=libCFTest.dylib\ stub-func-active.txt=*\ libCFTest.dylib=*)
                ok "stub list newer than dylib is CANNOT_CFTEST_STALE naming both mtimes"
                ;;
            *) die_test "stale-cannot line: $stale_line" ;;
        esac
    else
        die_test "stub_list_stale did not detect newer stub-func-active.txt"
    fi

    echo "== ensure_cftest matching stamp is reused=1"
    STAMPW=$(mktemp -d /tmp/phase2-cftest-stamp.XXXXXX)
    mkdir -p "$STAMPW/cfobjc/obj" "$STAMPW/nscfobj" "$STAMPW/lib"
    echo 'int cfobjc_probe=1;' | clang-18 -target x86_64-apple-macos13.0 \
        -c -o "$STAMPW/cfobjc/obj/CFString.o" -x c -
    echo 'int cfbase_probe=1;' | clang-18 -target x86_64-apple-macos13.0 \
        -c -o "$STAMPW/cfobjc/obj/CFBase.o" -x c -
    echo 'int nscf_probe=1;' | clang-18 -target x86_64-apple-macos13.0 \
        -c -o "$STAMPW/nscfobj/NSCFConstantString.o" -x c -
    stamp_write "$STAMPW/cfobjc/obj/CFBase.o" "$(stamp_key \
        "$STAMPW/cfobjc/obj/CFBase.o" \
        "$ROOT/foundation-macho/scripts/build_cfobjc.sh" \
        "$SYS/usr/include/malloc/malloc.h" \
        "$PHASE2_UD_GUEST_CF_COMMIT")"
    : > "$STAMPW/expect-func.txt"
    : > "$STAMPW/expect-data.txt"
    set +e
    h1=$(W="$STAMPW" SDK="$SYS" LIB="$STAMPW/lib" \
        CFOBJC_OBJ="$STAMPW/cfobjc/obj" NSCF_OBJ="$STAMPW/nscfobj" \
        R="$ROOT/foundation-macho" \
        PROBE_SRC="$ROOT/foundation-macho/tests/probe_sysctl.c" \
        CFTEST_EXPECT_FUNC="$STAMPW/expect-func.txt" \
        CFTEST_EXPECT_DATA="$STAMPW/expect-data.txt" \
        TRIPLE=x86_64-apple-macos13.0 LLD_BIN=/usr/lib/llvm-18/bin \
        bash "$ROOT/foundation-macho/scripts/build_cftest_harness.sh" 2>&1)
    h1_st=$?
    set -e
    if [ "$h1_st" -ne 0 ] || [ ! -f "$STAMPW/lib/libCFTest.dylib.inputs" ]; then
        die_test "stamp fixture harness exit $h1_st: $h1"
    else
        stamp_sha=$(sha256sum "$STAMPW/lib/libCFTest.dylib" | awk '{print $1}')
        reused=$(phase2_ud_guest_ensure_cftest "$STAMPW" "$ROOT" "$SYS" || true)
        stamp_sha2=$(sha256sum "$STAMPW/lib/libCFTest.dylib" | awk '{print $1}')
        case "$reused" in
            status=satisfied*\ reused=1\ stamp=*)
                if [ "$stamp_sha" = "$stamp_sha2" ]; then
                    ok "ensure_cftest matching stamp is reused=1 (sha unchanged)"
                else
                    die_test "reused=1 but sha changed $stamp_sha->$stamp_sha2"
                fi
                ;;
            *) die_test "ensure_cftest stamp reuse got: '$reused'" ;;
        esac
    fi
    rm -rf "$STAMPW"
else
    die_test "could not emit an x86 libCFTest.dylib fixture"
fi

echo "== ud-guest-dispatch stamps the host bridge; unstamped ELF is not reused"
DISP_HOST_DIR=$UDWORK/existing-host
mkdir -p "$DISP_HOST_DIR"
echo 'int openui_dispatch_host_v1_runtime_check(void){return 0;}' \
    | clang-18 -shared -fPIC -o "$DISP_HOST_DIR/libOpenDispatchHost.so" -x c -
DISP_SYS=$UDWORK/dispatch-sysroot
mkdir -p "$DISP_SYS/usr/lib"
disp_report=$(phase2_ud_guest_ensure_dispatch \
    "$ROOT" "$wt" "$DISP_SYS" x86_64-apple-macos15.0 \
    "$DISP_HOST_DIR/libOpenDispatchHost.so" || true)
case "$disp_report" in
    status=cold-built\ bridge=*runtime=*sha256=*)
        dhost=${disp_report#*bridge=}
        dhost=${dhost%% *}
        drun=${disp_report#*runtime=}
        drun=${drun%% *}
        dsha=${disp_report##*sha256=}
        want=$(sha256sum "$wt/lib/libOpenDispatch.dylib" | awk '{print $1}')
        if [ "$dhost" = "$wt/host/libOpenDispatchHost.so" ] \
            && [ "$dhost" != "$DISP_HOST_DIR/libOpenDispatchHost.so" ] \
            && [ "$drun" = "$wt/lib/libOpenDispatch.dylib" ] \
            && [ "$dsha" = "$want" ] \
            && [ "$(llvm-otool-18 -D "$drun" | tail -n 1)" = \
                /usr/lib/libOpenDispatch.dylib ] \
            && llvm-nm-18 -u "$drun" | grep -q '_glibc_openui_dispatch_host_v1_get_global_queue'
        then
            ok "ensure_dispatch rebuilds unstamped ELF and links Darwin LC_ID /usr/lib/libOpenDispatch.dylib"
        else
            die_test "ensure_dispatch dest mismatch: '$disp_report' id=$(llvm-otool-18 -D "$drun" 2>/dev/null | tail -n 1)"
        fi
        again=$(phase2_ud_guest_ensure_dispatch \
            "$ROOT" "$wt" "$DISP_SYS" x86_64-apple-macos15.0 \
            "$DISP_HOST_DIR/libOpenDispatchHost.so" || true)
        case "$again" in
            status=satisfied\ bridge=*runtime=*sha256=*)
                ok "ensure_dispatch re-run of identical host+runtime is satisfied"
                ;;
            *) die_test "ensure_dispatch idempotent re-run got: '$again'" ;;
        esac
        ;;
    *) die_test "ensure_dispatch got: '$disp_report'" ;;
esac

echo "== ud-guest-x86 fetches the pinned swift-corelibs-foundation checkout"
ck=$(phase2_ud_guest_ensure_cf_checkout "$wt" "$ROOT" || true)
if [ -z "$ck" ] \
    && [ -f "$wt/cf/Sources/CoreFoundation/CFRuntime.c" ] \
    && [ "$(git -c safe.directory="$wt/cf" -C "$wt/cf" rev-parse HEAD)" = "$PHASE2_UD_GUEST_CF_COMMIT" ] \
    && [ "$(git -c safe.directory="$wt/cf" -C "$wt/cf" rev-parse 'HEAD^{tree}')" = "$PHASE2_UD_GUEST_CF_TREE" ]; then
    ok "fetched $PHASE2_UD_GUEST_CF_ID commit=$PHASE2_UD_GUEST_CF_COMMIT tree=$PHASE2_UD_GUEST_CF_TREE"
    cf_dispatch=$(grep -RhoE '\bdispatch_[A-Za-z0-9_]+' \
        "$wt/cf/Sources/CoreFoundation" \
        | sed 's/^/_/' | sort -u)
    for need in _dispatch_queue_attr_concurrent _dispatch_queue_create \
        _dispatch_async_f _dispatch_once_f _dispatch_get_global_queue \
        _dispatch_semaphore_create _dispatch_semaphore_signal \
        _dispatch_semaphore_wait _dispatch_source_create
    do
        if printf '%s\n' "$cf_dispatch" | grep -qx "$need"; then
            ok "pinned CF sources mention $need"
        else
            # Not every name is spelled in every CF tree; record absence, do not fail.
            echo "NOTE: pinned CF sources do not spell $need (load-time nm is authoritative)"
        fi
    done
    printf '%s\n' "$cf_dispatch" | grep dispatch_ | head -40
else
    die_test "CF pin fetch got: '${ck:-empty}' dest=$wt/cf"
fi

echo "== cfobjc recipe argv is the documented flag set"
if CFOBJC_SKIP_COMPILE=1 bash "$ROOT/foundation-macho/scripts/test_build_cfobjc.sh"; then
    ok "test_build_cfobjc.sh (argv + missing-CF + missing-ICU)"
else
    die_test "test_build_cfobjc.sh"
fi

echo "== libCFTest stub pin: matching fixture OK, differing fixture CANNOT"
if bash "$ROOT/foundation-macho/scripts/test_build_cftest_harness.sh"; then
    ok "test_build_cftest_harness.sh"
else
    die_test "test_build_cftest_harness.sh"
fi

echo "== link_ud_guest.sh clang-18, one rope, dummy X86_64 binary"
if bash "$ROOT/foundation-macho/scripts/test_link_ud_guest.sh"; then
    ok "test_link_ud_guest.sh"
else
    die_test "test_link_ud_guest.sh"
fi

echo "== build_ud_score_guest.sh arm64 argv, x86 -l set, stamp reuse"
if bash "$ROOT/foundation-macho/scripts/test_build_ud_score_guest.sh"; then
    ok "test_build_ud_score_guest.sh"
else
    die_test "test_build_ud_score_guest.sh"
fi

echo "== run_ud_guest.sh dispatch argv (preload, runroot, loader sha256)"
if bash "$ROOT/foundation-macho/scripts/test_run_ud_guest.sh"; then
    ok "test_run_ud_guest.sh"
else
    die_test "test_run_ud_guest.sh"
fi

echo "== ud-guest-x86 linker log is a file path, not flattened ld64"
mkdir -p "$wt/bin"
link_report=$(phase2_ud_guest_link "$ROOT" "$wt" "${SYS:-$wt/fe/sysroot}" \
    "$wt/bin/ud_guest" || true)
if echo "$link_report" | grep -q 'CANNOT_UD_GUEST_UD_GUEST file=ud_guest' \
    && echo "$link_report" | grep -q "log=$wt/link_ud_guest.log" \
    && [ -f "$wt/link_ud_guest.log" ] \
    && grep -q . "$wt/link_ud_guest.log"; then
    if echo "$link_report" | grep -q 'ld64.lld'; then
        die_test "CANNOT line still inlines ld64 output: $link_report"
    else
        ok "UD_GUEST CANNOT names log= under scratch/ud-guest-x86_64"
    fi
else
    die_test "link log-spill got: $link_report"
fi

echo "== ud-guest-x86 compiler log is a file path, not inlined swiftc text"
port_mc=$UDWORK/mc
mkdir -p "$port_mc"
port_report=$(phase2_ud_guest_compile_port "$wt" "$ROOT" "$SYS" \
    "x86_64-apple-macos15.0" "$port_mc" || true)
if echo "$port_report" | grep -q 'CANNOT_UD_GUEST_USERDEFAULTSGUEST file=UserDefaultsGuest.o' \
    && echo "$port_report" | grep -q "log=$wt/fe/UserDefaultsGuest.swiftc.log" \
    && [ -f "$wt/fe/UserDefaultsGuest.swiftc.log" ] \
    && grep -q . "$wt/fe/UserDefaultsGuest.swiftc.log"; then
    if echo "$port_report" | grep -q 'warning: Could not read SDKSettings'; then
        die_test "CANNOT line still inlines swiftc output: $port_report"
    else
        ok "UserDefaultsGuest CANNOT names log= under scratch/ud-guest-x86_64"
    fi
else
    die_test "port compile log-spill got: $port_report"
fi
rm -rf "$UDWORK"

echo "== overlay provenance from artifacts + cache-extract refusal"
# shellcheck source=common.inc
. "$COMMON"
ART_OC=$ROOT/swiftcore-macho/artifacts/swift-macosx/x86_64/libswiftObjectiveC.dylib
PACK=$ROOT/machorun/scripts/pack_macho.py
if [ ! -f "$ART_OC" ]; then
    die_test "missing from-source $ART_OC"
elif [ ! -f "$PACK" ]; then
    die_test "missing $PACK (PR #55 strip-fixups)"
else
    saved_w=$W
    saved_home=$HOME
    W=$ROOT
    PROV_DEST=$(mktemp -d /tmp/phase2-overlay-prov.XXXXXX)
    prov=$(phase2_stage_x86_run_root_overlays "$PROV_DEST" || true)
    oc_line=$(printf '%s\n' "$prov" | grep 'name=libswiftObjectiveC.dylib' | head -1 || true)
    art_dir=$ROOT/swiftcore-macho/artifacts/swift-macosx/x86_64
    art_sha=$(sha256sum "$ART_OC" | awk '{print substr($1,1,12)}')
    if echo "$oc_line" | grep -q "OVERLAY_PROVENANCE name=libswiftObjectiveC.dylib" \
        && echo "$oc_line" | grep -q "srcdir=$art_dir" \
        && echo "$oc_line" | grep -q "sha256=$art_sha" \
        && echo "$oc_line" | grep -q 'fixups=dyld_info' \
        && cmp -s "$PROV_DEST/darwin/usr/lib/swift/libswiftObjectiveC.dylib" "$ART_OC"
    then
        ok "OVERLAY_PROVENANCE names artifacts libswiftObjectiveC (sha256 prefix, fixups=dyld_info)"
    else
        die_test "ObjectiveC provenance expected artifacts+$art_sha+dyld_info got: '$oc_line'"
    fi
    # Stale Apple extract already in the dest must be overwritten, not kept.
    EXTRACT_W=$(mktemp -d /tmp/phase2-overlay-extract.XXXXXX)
    mkdir -p "$EXTRACT_W/scratch/apple-x86-overlays" \
        "$EXTRACT_W/swiftcore-macho/artifacts/swift-macosx/x86_64"
    python3 "$PACK" strip-fixups "$ART_OC" \
        -o "$EXTRACT_W/scratch/apple-x86-overlays/libswiftObjectiveC.dylib"
    if ! phase2_is_cache_extract \
        "$EXTRACT_W/scratch/apple-x86-overlays/libswiftObjectiveC.dylib"
    then
        die_test "strip-fixups fixture is not a cache extract"
    fi
    STALE_DEST=$(mktemp -d /tmp/phase2-overlay-stale.XXXXXX)
    mkdir -p "$STALE_DEST/darwin/usr/lib/swift"
    cp -f "$EXTRACT_W/scratch/apple-x86-overlays/libswiftObjectiveC.dylib" \
        "$STALE_DEST/darwin/usr/lib/swift/libswiftObjectiveC.dylib"
    W=$ROOT
    stale_prov=$(phase2_stage_x86_run_root_overlays "$STALE_DEST" || true)
    if cmp -s "$STALE_DEST/darwin/usr/lib/swift/libswiftObjectiveC.dylib" "$ART_OC" \
        && echo "$stale_prov" | grep -q "OVERLAY_PROVENANCE name=libswiftObjectiveC.dylib" \
        && echo "$stale_prov" | grep -q "srcdir=$art_dir" \
        && ! echo "$stale_prov" | grep -q '^CANNOT_STAGE_CACHE_EXTRACT'
    then
        ok "stale dest cache extract is overwritten from artifacts (not kept)"
    else
        die_test "stale overwrite failed: $(sha256sum "$STALE_DEST/darwin/usr/lib/swift/libswiftObjectiveC.dylib" "$ART_OC"); $stale_prov"
    fi
    # Isolated tree: only the cache extract is findable. Must refuse, not stage.
    W=$EXTRACT_W
    HOME=$EXTRACT_W
    REFUSE_DEST=$(mktemp -d /tmp/phase2-overlay-refuse.XXXXXX)
    refuse=$(phase2_stage_x86_run_root_overlays "$REFUSE_DEST" || true)
    extract_src=$EXTRACT_W/scratch/apple-x86-overlays/libswiftObjectiveC.dylib
    if echo "$refuse" | grep -q "CANNOT_STAGE_CACHE_EXTRACT name=libswiftObjectiveC.dylib src=$extract_src" \
        && [ ! -f "$REFUSE_DEST/darwin/usr/lib/swift/libswiftObjectiveC.dylib" ]
    then
        ok "cache extract is CANNOT_STAGE_CACHE_EXTRACT name=… src=… (not staged)"
    else
        die_test "cache-extract refusal got: '$refuse' dest=$(ls -l "$REFUSE_DEST/darwin/usr/lib/swift" 2>/dev/null)"
    fi
    W=$saved_w
    HOME=$saved_home
    rm -rf "$PROV_DEST" "$STALE_DEST" "$REFUSE_DEST" "$EXTRACT_W"
fi

echo "== stamp library + existence-reuse + ops + SYS vs main"
if bash "$ROOT/scripts/x86/test_stamp.sh"; then
    ok "test_stamp.sh"
else
    die_test "test_stamp.sh"
fi
if bash "$ROOT/scripts/x86/test_stage_fe_sysroot_matches_main.sh"; then
    ok "test_stage_fe_sysroot_matches_main.sh"
else
    die_test "test_stage_fe_sysroot_matches_main.sh"
fi
if bash "$ROOT/scripts/x86/test_no_existence_reuse.sh"; then
    ok "test_no_existence_reuse.sh"
else
    die_test "test_no_existence_reuse.sh"
fi
if bash "$ROOT/scripts/ops/test_ops.sh"; then
    ok "test_ops.sh"
else
    die_test "test_ops.sh"
fi

echo "== gen_swift_tbd.sh round-trip (libswiftCore + overlays)"
if bash "$ROOT/scripts/x86/test_gen_swift_tbd.sh"; then
    ok "test_gen_swift_tbd.sh"
else
    die_test "test_gen_swift_tbd.sh"
fi

echo "== x86 Darwin re-export oracle (ld64.lld attributes POSIXErrorCode to libswiftDarwin)"
if bash "$X86_ORACLE"; then
    ok "test_guest_gate_inventories_x86_oracle.sh"
else
    die_test "test_guest_gate_inventories_x86_oracle.sh"
fi

echo
echo "test_phase2: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
