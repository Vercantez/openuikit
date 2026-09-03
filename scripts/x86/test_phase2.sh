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
PREPARE=$ROOT/scripts/env/prepare.py
BUILD_FULL=$ROOT/full/scripts/build_full.sh

expect_file "$PHASE2"
expect_file "$COMMON"
expect_file "$STAGE"
expect_file "$OC"
expect_file "$GUEST"

echo "== bash -n"
for s in "$PHASE2" "$STAGE" "$OC" "$COMMON" "$ROOT/scripts/x86/test_phase2.sh" \
    "$ROOT/full/foundation/fe_sysroot_measurement.inc"; do
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
expect_grep 're-stage sysroot-fe4-x86 (input changed:' "$PHASE2" \
    "phase2 restages when input shas change and prints which"
expect_grep 'DARWIN_CLANG_MODULEMAP' "$PHASE2" \
    "missing Darwin.modulemap is its own CANNOT, not folded into overlays"
expect_grep 'DARWIN_MODULEMAP_HEADERS' "$PHASE2" \
    "missing modulemap header files are CANNOT_DARWIN_MODULEMAP_HEADERS"
expect_grep 'stage_fe_sysroot_x86.3' "$COMMON" \
    "recipe bump restages a sysroot that lacked the FileManager header set"
expect_grep 'fe_sysroot_measurement_headers=' "$COMMON" \
    "stamp records the shared measurement-header list sha"
expect_grep 'phase2_measurement_headers_missing' "$COMMON" \
    "every header in the FileManager/sdk-gap list is checked after restage"
expect_grep 'FE_MEASUREMENT_HEADERS' "$PHASE2" \
    "missing measurement headers are CANNOT_FE_MEASUREMENT_HEADERS"
expect_grep 'phase2_stage_measurement_headers_from_arm' "$STAGE" \
    "x86 stager stages the shared list from arm64 sysroot_fe4"
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
rm -rf "$STAMPWORK"

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
for overlay in libswiftDarwin.dylib libswiftSynchronization.dylib \
    libswift_Builtin_float.dylib libswift_DarwinFoundation1.dylib \
    libswift_DarwinFoundation2.dylib libswift_DarwinFoundation3.dylib \
    libswift_RegexParser.dylib libswift_StringProcessing.dylib libswift_errno.dylib
do
    expect_grep "$overlay" "$COMMON" "overlay $overlay named in common.inc"
    expect_grep "$overlay" "$PREPARE" "overlay $overlay named in prepare.py"
    expect_grep "$overlay" "$BUILD_FULL" "overlay $overlay named in build_full.sh"
done

# Isolate $HOME so a leftover operator stdlib tree cannot satisfy the miss case.
OVERLAY_HOME=$(mktemp -d /tmp/phase2-overlay-home.XXXXXX)
OVERLAY_DEST=$(mktemp -d /tmp/phase2-overlay-dest.XXXXXX)
W=$ROOT
HOME=$OVERLAY_HOME
# shellcheck source=common.inc
. "$COMMON"
overlay_report=$(phase2_stage_x86_fe_overlays "$OVERLAY_DEST/mrroot_fe-x86_64" || true)
expected_missing='MISSING=libswiftDarwin.dylib,libswiftSynchronization.dylib,libswift_Builtin_float.dylib,libswift_DarwinFoundation1.dylib,libswift_DarwinFoundation2.dylib,libswift_DarwinFoundation3.dylib,libswift_RegexParser.dylib,libswift_StringProcessing.dylib,libswift_errno.dylib'
if [ "$overlay_report" = "$expected_missing" ]; then
    ok "overlay stage lists every missing FE dylib ($overlay_report)"
else
    die_test "overlay MISSING list expected $expected_missing got: $overlay_report"
fi

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

echo
echo "test_phase2: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
