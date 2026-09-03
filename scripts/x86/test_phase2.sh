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
OC=$ROOT/scripts/x86/build_opencombine.sh
GUEST=$ROOT/full/scripts/guest_arch.inc
WIDGET=$ROOT/full/swiftui/build_focus_widget_guest.sh
ONBOARD=$ROOT/full/swiftui/build_focus_onboarding_guest.sh
REMINDER=$ROOT/full/xcodeplan/build_and_run_reminder_scene_guest.sh
UD_RUNNER=$ROOT/foundation-macho/tests/ud_guest_runner.swift
BUILD_FULL=$ROOT/full/scripts/build_full.sh

expect_file "$PHASE2"
expect_file "$COMMON"
expect_file "$STAGE"
expect_file "$OC"
expect_file "$GUEST"

echo "== bash -n"
for s in "$PHASE2" "$STAGE" "$OC" "$COMMON" "$ROOT/scripts/x86/test_phase2.sh"; do
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
expect_grep 'EXPECTED_OPENCOMBINE_OBJECT_SHA=96558e7d31c10c4bc769e9774977b74c58dc6ee83cfbd4fca8bf17229424a914' \
    "$WIDGET" "arm64 OpenCombine object SHA still stands"
expect_grep 'if \[ "$ARCH" = arm64 \]; then' "$WIDGET" \
    "widget hashes OpenCombine.o only on arm64"

echo "== reminder: x86-on-x86 must not refuse; native path skips docker"
expect_grep 'x86_64 guests on an x86_64 host are the phase-2 path' "$REMINDER" \
    "reminder documents x86-on-x86"
expect_not_grep 'if \[ "$(uname -m)" != aarch64 \] && \[ "$(uname -m)" != arm64 \]; then' \
    "$REMINDER" "reminder no longer refuses every non-aarch64 host"
expect_grep 'if \[ "$ARCH" = x86_64 \] && \[ "$(uname -m)" = x86_64 \]' "$REMINDER" \
    "reminder native x86 skip-docker"
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

echo
echo "test_phase2: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
