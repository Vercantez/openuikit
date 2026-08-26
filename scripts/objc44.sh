#!/bin/bash
# objc44.sh -- run ~/objc4-linux's 44-test differential corpus under machorun.
#
# THE ORACLE RULE. The baselines in tests/objc44/*.txt are copies of
# ~/objc4-linux/tests/expected/*.txt, recorded on macOS 26.1/arm64 against
# APPLE'S SHIPPING libobjc. This script never writes them. If one mismatches,
# that is a failure to report, not a number to update.
#
# The binaries in tests/objc44/ were compiled ON macOS by APPLE'S clang, with
# harness/run_macos.sh's exact flags -- the same compile that recorded the
# baselines. tests/objc44/README.md has the provenance and the rebuild command,
# and records that all 44 were verified to reproduce their baseline natively on
# macOS before ever being run here. That check is what makes a Linux-side
# mismatch mean something.
#
#   scripts/objc44.sh                 all 44
#   scripts/objc44.sh 023 038         only those
#
# Needs: the loader, darwin/usr/lib/*.dylib and darwin/usr/lib/libobjc.A.dylib.
# Build libobjc with scripts/build_objc4.sh (which needs a macOS SDK -- see
# that script's header).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$ROOT/tests/objc44"
LOADER="${MACHORUN_LOADER:-$ROOT/build/machorun}"

[ -x "$LOADER" ] || { echo "objc44: no loader at $LOADER (scripts/build.sh loader)" >&2; exit 1; }
[ -f "$ROOT/darwin/usr/lib/libobjc.A.dylib" ] || {
    echo "objc44: darwin/usr/lib/libobjc.A.dylib is missing." >&2
    echo "        Build it with scripts/build_objc4.sh (needs a macOS SDK)." >&2
    exit 1; }

export LC_ALL=C LANG=C TZ=UTC
pass=0; fail=0
FAILED=()

for f in "$D"/*.txt; do
    N=$(basename "$f" .txt)
    if [ $# -gt 0 ]; then
        want=0
        for a in "$@"; do case "$N" in $a*) want=1 ;; esac; done
        [ $want = 1 ] || continue
    fi
    [ -x "$D/$N" ] || { printf '%-38s %s\n' "$N" "NO-BINARY"; continue; }

    DL=""
    [ -f "$D/lib$N-dlopen.dylib" ] && DL="$D/lib$N-dlopen.dylib"

    out=$(cd "$D" && OBJC_PRINT_LOAD_METHODS=NO OBJC_PRINT_INITIALIZE_METHODS=NO \
          OBJC4_TEST_DLOPEN_LIB="$DL" \
          timeout -k 2 30 "$LOADER" "./$N" 2>"$D/.$N.stderr")
    rc=$?

    if [ "$out" = "$(cat "$f")" ] && [ $rc -eq 0 ]; then
        printf '%-38s PASS\n' "$N"; pass=$((pass+1))
    else
        printf '%-38s FAIL (exit %d)\n' "$N" $rc; fail=$((fail+1)); FAILED+=("$N")
    fi
done

echo "----------------------------------------------------------------------"
printf 'objc4 differential corpus under machorun: %d/%d PASS\n' $pass $((pass+fail))
if [ ${#FAILED[@]} -gt 0 ]; then
    echo
    for N in "${FAILED[@]}"; do
        echo "=== $N"
        diff <(cd "$D" && OBJC4_TEST_DLOPEN_LIB="" timeout -k 2 30 "$LOADER" "./$N" 2>/dev/null) \
             "$D/$N.txt" | head -10
        echo "--- stderr:"; head -4 "$D/.$N.stderr"
    done
fi
rm -f "$D"/.*.stderr
[ $fail -eq 0 ]
