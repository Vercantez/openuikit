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
phase2_write_sysroot_stamp "$STAMPWORK/stamp" \
    "$STAMPWORK/core-a" "$STAMPWORK/mod" "$STAMPWORK/bf" \
    "$STAMPWORK/gen" "$STAMPWORK/overlay" "$STAMPWORK/dmap"
match=$(phase2_sysroot_stamp_diff "$STAMPWORK/stamp" \
    "$STAMPWORK/core-a" "$STAMPWORK/mod" "$STAMPWORK/bf" \
    "$STAMPWORK/gen" "$STAMPWORK/overlay" "$STAMPWORK/dmap" && echo MATCH || echo FAIL)
if [ "$match" = MATCH ]; then
    ok "stamp matches when inputs are unchanged"
else
    die_test "unchanged inputs should match stamp, got $match"
fi
diff=$(phase2_sysroot_stamp_diff "$STAMPWORK/stamp" \
    "$STAMPWORK/core-b" "$STAMPWORK/mod" "$STAMPWORK/bf" \
    "$STAMPWORK/gen" "$STAMPWORK/overlay" "$STAMPWORK/dmap" || true)
case "$diff" in
    *"libswiftCore "*) ok "stamp names libswiftCore when the artifact sha changes ($diff)" ;;
    *) die_test "expected libswiftCore old->new, got: $diff" ;;
esac
missing_stamp=$(phase2_sysroot_stamp_diff "$STAMPWORK/absent" \
    "$STAMPWORK/core-a" "$STAMPWORK/mod" "$STAMPWORK/bf" \
    "$STAMPWORK/gen" "$STAMPWORK/overlay" "$STAMPWORK/dmap" || true)
case "$missing_stamp" in
    stamp=ABSENT) ok "missing stamp is stamp=ABSENT (restage, do not reuse)" ;;
    *) die_test "missing stamp expected stamp=ABSENT, got: $missing_stamp" ;;
esac
rm -rf "$STAMPWORK"

MMWORK=$(mktemp -d /tmp/phase2-modulemap.XXXXXX)
mkdir -p "$MMWORK/arm/usr/include" "$MMWORK/sys/usr/include"
cat > "$MMWORK/sys/usr/include/module.modulemap" <<'EOF'
module ObjectiveC [system] { header "objc/objc.h" export * }
EOF
cat > "$MMWORK/arm/usr/include/Darwin.modulemap" <<'EOF'
module Darwin [system] { header "stdio.h" export * }
EOF
cat > "$MMWORK/arm/usr/include/DarwinFoundation1.modulemap" <<'EOF'
module _DarwinFoundation1 [system] { header "errno.h" export * }
EOF
printf 'module ObjectiveC [system] { header "objc/objc.h" export * }\nextern module Darwin "Darwin.modulemap"\nextern module _DarwinFoundation1 "DarwinFoundation1.modulemap"\n' \
    > "$MMWORK/arm/usr/include/module.modulemap"
# Generator is not Xcode; copy path must still produce Darwin.modulemap.
if phase2_install_darwin_modulemaps "$MMWORK/sys" "$MMWORK/arm" "$MMWORK/no-such-gen.py"; then
    if [ -f "$MMWORK/sys/usr/include/Darwin.modulemap" ] \
        && [ -f "$MMWORK/sys/usr/include/DarwinFoundation1.modulemap" ] \
        && grep -q 'extern module Darwin' "$MMWORK/sys/usr/include/module.modulemap"; then
        ok "Darwin family maps copied from arm64 sysroot when generator cannot run"
    else
        die_test "copy path did not install Darwin.modulemap + extern module lines"
    fi
else
    die_test "install_darwin_modulemaps failed on a fixture that has pruned maps"
fi
rm -rf "$MMWORK"

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

echo
echo "test_phase2: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
