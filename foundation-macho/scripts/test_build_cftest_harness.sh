#!/usr/bin/env bash
# Teeth for the committed libCFTest stub pin: a fixture that matches passes,
# a fixture that differs prints CANNOT_CFTEST_STUBS with the extra/missing names.
#
#   bash foundation-macho/scripts/test_build_cftest_harness.sh
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
FM=$(cd "$HERE/.." && pwd)
H=$HERE/build_cftest_harness.sh
C=$HERE/check_cftest_stubs.sh
pass=0
fail=0

ok() { echo "PASS: $*"; pass=$((pass + 1)); }
die_test() { echo "FAIL: $*" >&2; fail=$((fail + 1)); }

expect_grep() {
    local needle=$1 file=$2 label=$3
    if grep -q -- "$needle" "$file"; then
        ok "$label"
    else
        die_test "$label (missing in $file: $needle)"
    fi
}

echo "== bash -n"
if bash -n "$H" && bash -n "$C"; then
    ok "bash -n build_cftest_harness.sh check_cftest_stubs.sh"
else
    die_test "bash -n harness/check"
fi

expect_grep 'check_cftest_stubs.sh' "$H" "harness invokes the stub pin"
expect_grep 'CANNOT_CFTEST_STUBS' "$H" "harness names CANNOT_CFTEST_STUBS"
expect_grep 'cftest-stub-func-active.txt' "$H" "harness names the committed func pin"
expect_grep 'libCFTest.dylib.inputs' "$H" "harness writes an input stamp next to the dylib"
expect_grep 'reused=1 stamp=' "$H" "matching stamp prints reused=1 stamp="
expect_grep 'reason=inputs' "$H" "stamp mismatch prints reason=inputs"
expect_grep 'CANNOT_CFTEST_STALE' "$H" "stub list newer than dylib is CANNOT_CFTEST_STALE"
expect_grep 'CFTEST_VERIFY_ONLY' "$H" "verify-only refuses instead of relinking"

echo "== matching fixture is OK"
fix=$(mktemp -d /tmp/cftest-stubs-ok.XXXXXX)
cp "$FM/docs/cf-census/cftest-stub-func-active.txt" "$fix/func.txt"
cp "$FM/docs/cf-census/cftest-stub-data.txt" "$fix/data.txt"
set +e
ok_out=$(bash "$C" "$fix/func.txt" "$fix/data.txt")
ok_st=$?
set -e
if [ "$ok_st" -eq 0 ] && echo "$ok_out" | grep -q 'CFTEST_STUBS_OK func=214 data=2'; then
    ok "matching fixture CFTEST_STUBS_OK func=214 data=2"
else
    die_test "matching fixture got exit $ok_st: $ok_out"
fi
rm -rf "$fix"

echo "== differing fixture is CANNOT_CFTEST_STUBS extra= missing="
fix=$(mktemp -d /tmp/cftest-stubs-bad.XXXXXX)
# Extra name the 143-stub x86 hole actually aborted on; drop one pin name so
# both sides of the diff are populated.
grep -v '^CFRunLoopGetCurrent$' "$FM/docs/cf-census/cftest-stub-func-active.txt" \
    >"$fix/func.txt"
echo 'CFStringCreateWithBytes' >>"$fix/func.txt"
cp "$FM/docs/cf-census/cftest-stub-data.txt" "$fix/data.txt"
set +e
bad_out=$(bash "$C" "$fix/func.txt" "$fix/data.txt")
bad_st=$?
set -e
if [ "$bad_st" -eq 2 ] \
    && echo "$bad_out" | grep -q '^CANNOT_CFTEST_STUBS ' \
    && echo "$bad_out" | grep -q 'extra=CFStringCreateWithBytes' \
    && echo "$bad_out" | grep -q 'missing=CFRunLoopGetCurrent'; then
    ok "differing fixture CANNOT_CFTEST_STUBS extra=CFStringCreateWithBytes missing=CFRunLoopGetCurrent"
else
    die_test "differing fixture got exit $bad_st: $bad_out"
fi
rm -rf "$fix"

echo "== input stamp: matching reused=1, stale stub list CANNOT, object sha relink"
SYS=${SYS:-$(cd "$FM/.." && pwd)/scratch/sysroot_fe4-x86_64}
if [ ! -d "$SYS/usr/include" ]; then
    die_test "x86 sysroot missing; cannot run harness stamp fixtures"
else
    HW=$(mktemp -d /tmp/cftest-stamp.XXXXXX)
    mkdir -p "$HW/cfobjc/obj" "$HW/nscfobj" "$HW/lib" "$HW/sdk/usr/lib" "$HW/sdk/usr/include"
    # Use the real x86 sysroot for -isysroot / tbds; keep W's sdk/ for layout.
    echo 'int cfobjc_probe=1;' | clang-18 -target x86_64-apple-macos13.0 \
        -isysroot "$SYS" -c -o "$HW/cfobjc/obj/CFString.o" -x c -
    echo 'int nscf_probe=1;' | clang-18 -target x86_64-apple-macos13.0 \
        -isysroot "$SYS" -c -o "$HW/nscfobj/NSCFConstantString.o" -x c -
    : > "$HW/expect-func.txt"
    : > "$HW/expect-data.txt"

    run_h() {
        W="$HW" SDK="$SYS" LIB="$HW/lib" \
            CFOBJC_OBJ="$HW/cfobjc/obj" NSCF_OBJ="$HW/nscfobj" \
            R="$FM" PROBE_SRC="$FM/tests/probe_sysctl.c" \
            CFTEST_EXPECT_FUNC="$HW/expect-func.txt" \
            CFTEST_EXPECT_DATA="$HW/expect-data.txt" \
            TRIPLE=x86_64-apple-macos13.0 \
            LLD_BIN=/usr/lib/llvm-18/bin \
            "$@" bash "$H"
    }

    set +e
    first=$(run_h 2>&1)
    first_st=$?
    set -e
    if [ "$first_st" -eq 0 ] && echo "$first" | grep -q 'libCFTest relinked' \
        && [ -f "$HW/lib/libCFTest.dylib" ] \
        && [ -f "$HW/lib/libCFTest.dylib.inputs" ]
    then
        ok "first harness run relinks and writes libCFTest.dylib.inputs"
    else
        die_test "first harness run exit $first_st: $first"
    fi
    grep -q '^obj:cfobjc/CFString.o=' "$HW/lib/libCFTest.dylib.inputs" \
        && grep -q '^obj:nscfobj/NSCFConstantString.o=' "$HW/lib/libCFTest.dylib.inputs" \
        && grep -q '^obj:cfstubs.o=' "$HW/lib/libCFTest.dylib.inputs" \
        && grep -q '^stub-func-active=' "$HW/lib/libCFTest.dylib.inputs" \
        && grep -q '^tbd:libSystem=' "$HW/lib/libCFTest.dylib.inputs" \
        && grep -q '^tbd:libobjc=' "$HW/lib/libCFTest.dylib.inputs" \
        && grep -q '^argv=' "$HW/lib/libCFTest.dylib.inputs" \
        && ok "stamp records objects, stub-set, tbds, argv" \
        || die_test "stamp contents: $(tr '\n' ' ' < "$HW/lib/libCFTest.dylib.inputs")"

    old_sha=$(sha256sum "$HW/lib/libCFTest.dylib" | awk '{print $1}')
    set +e
    second=$(run_h 2>&1)
    second_st=$?
    set -e
    new_sha=$(sha256sum "$HW/lib/libCFTest.dylib" | awk '{print $1}')
    if [ "$second_st" -eq 0 ] && echo "$second" | grep -q 'libCFTest reused=1 stamp=' \
        && [ "$old_sha" = "$new_sha" ]
    then
        ok "matching stamp is reused=1 (dylib sha unchanged)"
    else
        die_test "second harness run exit $second_st sha $old_sha->$new_sha: $second"
    fi

    set +e
    v_ok=$(CFTEST_VERIFY_ONLY=1 run_h 2>&1)
    v_ok_st=$?
    set -e
    if [ "$v_ok_st" -eq 0 ] && echo "$v_ok" | grep -q 'libCFTest reused=1 stamp='; then
        ok "verify-only matching stamp is reused=1"
    else
        die_test "verify-only match exit $v_ok_st: $v_ok"
    fi

    # Regenerated stub list, old dylib: CANNOT in verify-only.
    touch -d '2020-01-01 00:00:00 UTC' "$HW/lib/libCFTest.dylib"
    touch "$HW/stub-func-active.txt"
    set +e
    stale=$(CFTEST_VERIFY_ONLY=1 run_h 2>&1)
    stale_st=$?
    set -e
    if [ "$stale_st" -eq 2 ] \
        && echo "$stale" | grep -q '^CANNOT_CFTEST_STALE ' \
        && echo "$stale" | grep -q 'stub-func-active.txt=' \
        && echo "$stale" | grep -q 'libCFTest.dylib=' \
        && echo "$stale" | grep -qv 'reused=1'
    then
        ok "stale dylib + fresh stub list is CANNOT_CFTEST_STALE (verify-only, not satisfied)"
    else
        die_test "stale stub list verify-only exit $stale_st: $stale"
    fi

    # Same stale pair without verify-only must relink, not reuse.
    set +e
    relink_stale=$(run_h 2>&1)
    relink_stale_st=$?
    set -e
    if [ "$relink_stale_st" -eq 0 ] && echo "$relink_stale" | grep -q 'libCFTest relinked' \
        && echo "$relink_stale" | grep -qv 'reused=1'
    then
        ok "stale dylib + fresh stub list relinks (not reused)"
    else
        die_test "stale stub list relink exit $relink_stale_st: $relink_stale"
    fi

    # Changed object sha → reason=inputs obj:… old->new
    echo 'int cfobjc_probe=2;' | clang-18 -target x86_64-apple-macos13.0 \
        -isysroot "$SYS" -c -o "$HW/cfobjc/obj/CFString.o" -x c -
    set +e
    chg=$(CFTEST_VERIFY_ONLY=1 run_h 2>&1)
    chg_st=$?
    set -e
    if [ "$chg_st" -eq 2 ] \
        && echo "$chg" | grep -q 'reason=inputs obj:cfobjc/CFString.o ' \
        && echo "$chg" | grep -q 'CANNOT_CFTEST_INPUTS'
    then
        ok "changed object sha is reason=inputs obj:cfobjc/CFString.o (verify-only)"
    else
        die_test "changed object verify-only exit $chg_st: $chg"
    fi
    set +e
    chg_link=$(run_h 2>&1)
    chg_link_st=$?
    set -e
    if [ "$chg_link_st" -eq 0 ] && echo "$chg_link" | grep -q 'reason=inputs obj:cfobjc/CFString.o ' \
        && echo "$chg_link" | grep -q 'libCFTest relinked'
    then
        ok "changed object sha relinks with reason=inputs obj:cfobjc/CFString.o"
    else
        die_test "changed object relink exit $chg_link_st: $chg_link"
    fi
    rm -rf "$HW"
fi

echo "test_build_cftest_harness: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
