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

echo "test_build_cftest_harness: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
