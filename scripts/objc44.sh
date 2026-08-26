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
#   scripts/objc44.sh                 all 44, then the concurrency repetition gate
#   scripts/objc44.sh 023 038         only those, no repetition gate
#   MACHORUN_NO_STRESS=1 scripts/objc44.sh    all 44, no repetition gate
#
# Needs: the loader, darwin/usr/lib/*.dylib and darwin/usr/lib/libobjc.A.dylib.
# Build libobjc with scripts/build_objc4.sh (which needs a macOS SDK -- see
# that script's header).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$ROOT/tests/objc44"
LOADER="${MACHORUN_LOADER:-$ROOT/build/machorun}"

# The loader is a Linux ELF. Run from macOS, all 44 execs fail with "cannot
# execute binary file" and the script reports 0/44 -- which reads like a
# catastrophic regression and is really a wrong-host mistake. Say so once, up
# front, rather than 44 times in a shape that invites re-recording a baseline.
[ "$(uname -s)" = "Linux" ] || {
    echo "objc44: this runs the LINUX loader, but \`uname -s\` says $(uname -s)." >&2
    echo "        Run it inside the test-bed container:" >&2
    echo "          docker run --rm -i --platform linux/arm64 -v \"$ROOT:/work\" -w /work \\" >&2
    echo "            \"\${MACHORUN_IMAGE:-machorun-testbed:24.04}\" bash -c 'bash scripts/objc44.sh'" >&2
    exit 2; }

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

# One pass over the corpus cannot see a concurrency bug whose failure rate is a
# coin flip -- the os_unfair_lock owner-token collision that took Graviton3 down
# to 24/44 was green on Apple silicon for exactly that reason. So a full run
# ends with a repetition gate. It costs about a second and a half (these
# fixtures run in ~5 ms each); MACHORUN_NO_STRESS=1 opts out.
stress_rc=0
if [ $# -eq 0 ] && [ "${MACHORUN_NO_STRESS:-0}" != 1 ]; then
    echo
    bash "$ROOT/scripts/stress_unfair_lock.sh" "${MACHORUN_STRESS_RUNS:-100}" || stress_rc=1
fi

[ $fail -eq 0 ] && [ $stress_rc -eq 0 ]
