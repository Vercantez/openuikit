#!/bin/bash
# stress_unfair_lock.sh -- the regression gate for the os_unfair_lock owner token.
#
#   scripts/stress_unfair_lock.sh              100 runs of the default fixtures
#   scripts/stress_unfair_lock.sh 500          500 runs
#   scripts/stress_unfair_lock.sh 200 043      200 runs of 043* only
#
# WHY THIS EXISTS, because a bare loop over a passing test looks like padding.
#
# An os_unfair_lock is four bytes, so a locked one identifies its owner by a
# 32-bit token. That token used to be `(unsigned)(pthread_self() >> 8)` -- half
# of a 64-bit TCB pointer thrown away. Two threads whose TCBs agreed in those
# bits got the SAME token, and then one thread taking a lock another thread
# held read as recursive acquisition by the owner, which libSystem correctly
# traps. Exit 71, from a fixture with no bug in it.
#
# Whether two TCBs collide depends on where the allocator put them, so it
# depends on ASLR, so it depends on the run. On Apple silicon it essentially
# never happened and the corpus was green; on Graviton3 (Neoverse-V1, Ubuntu
# 24.04, 4 KB pages) it happened about half the time and the corpus fell to
# ~24/44. One run of one fixture therefore proves nothing either way -- only a
# distribution does. That is what this script measures, and it is why the gate
# is a loop rather than a test case.
#
# The fix (mr_thread_token(), darwin/src/objcsupport.c) hands each thread a
# sequential id instead of hashing its pointer, so collisions are impossible by
# construction rather than unlikely. A regression would be someone deriving the
# token from an address again -- which would pass a single run on any machine
# they own, and fail here.
#
# Exit status is the point: 0 iff every single run matched its recorded
# baseline with exit 0.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$ROOT/tests/objc44"
LOADER="${MACHORUN_LOADER:-$ROOT/build/machorun}"

N="${1:-100}"
shift 2>/dev/null || true

# The threaded ones. 004 is the fixture that caught this on Graviton; 043
# creates threads outright; 037 is @synchronized, i.e. the RECURSIVE lock,
# whose owner check compares against a word os_unfair_lock_lock wrote and so
# breaks if the two ever disagree about what a token is.
DEFAULT_FIXTURES=(004-dispatch-basic 043-threads 037-synchronized)

[ "$(uname -s)" = "Linux" ] || {
    echo "stress_unfair_lock: this runs the LINUX loader, but \`uname -s\` says $(uname -s)." >&2
    echo "        Run it inside the test-bed container:" >&2
    echo "          docker run --rm -i --platform linux/arm64 -v \"$ROOT:/work\" -w /work \\" >&2
    echo "            \"\${MACHORUN_IMAGE:-machorun-testbed:24.04}\" bash -c 'bash scripts/stress_unfair_lock.sh'" >&2
    exit 2; }

[ -x "$LOADER" ] || { echo "stress_unfair_lock: no loader at $LOADER (scripts/build.sh loader)" >&2; exit 1; }
[ -f "$ROOT/darwin/usr/lib/libobjc.A.dylib" ] || {
    echo "stress_unfair_lock: darwin/usr/lib/libobjc.A.dylib is missing." >&2
    echo "        Build it with scripts/build_objc4.sh." >&2
    exit 1; }

case "$N" in ''|*[!0-9]*) echo "stress_unfair_lock: run count must be a number, got '$N'" >&2; exit 1 ;; esac

FIXTURES=()
if [ $# -gt 0 ]; then
    for a in "$@"; do
        for f in "$D"/*.txt; do
            b=$(basename "$f" .txt)
            case "$b" in $a*) FIXTURES+=("$b") ;; esac
        done
    done
    [ ${#FIXTURES[@]} -gt 0 ] || { echo "stress_unfair_lock: no fixture matches $*" >&2; exit 1; }
else
    FIXTURES=("${DEFAULT_FIXTURES[@]}")
fi

export LC_ALL=C LANG=C TZ=UTC
total_fail=0

for N4 in "${FIXTURES[@]}"; do
    [ -x "$D/$N4" ] || { echo "stress_unfair_lock: no binary $D/$N4" >&2; total_fail=$((total_fail+1)); continue; }
    want=$(cat "$D/$N4.txt")
    fails=0; first_rc=""; first_err=""
    for ((i = 1; i <= N; i++)); do
        out=$(cd "$D" && OBJC4_TEST_DLOPEN_LIB="" timeout -k 2 30 "$LOADER" "./$N4" 2>"$D/.stress.stderr")
        rc=$?
        if [ $rc -ne 0 ] || [ "$out" != "$want" ]; then
            fails=$((fails+1))
            [ -n "$first_rc" ] || { first_rc=$rc; first_err=$(head -3 "$D/.stress.stderr"); }
        fi
    done
    rm -f "$D/.stress.stderr"
    printf '%-38s %d/%d ok' "$N4" $((N - fails)) "$N"
    if [ $fails -eq 0 ]; then echo; else
        echo "   <-- $fails FAILED"
        echo "    first failure exit $first_rc"
        [ -n "$first_err" ] && echo "$first_err" | sed 's/^/    /'
        total_fail=$((total_fail+fails))
    fi
done

# ------------------------------------------------------------------ and the
# MAIN corpus's threaded fixture, for a SECOND intermittent bug this same
# repeat-until-a-distribution-appears method caught.
#
# tests/bin/pthread aborted about 3% of runs with "The futex facility
# returned an unexpected error code" -- 10 failures in 300 -- from a fixture
# with no bug in it. The cause was adopt_lock() in darwin/src/libsystem.c
# lazily initialising the very mutex that guards lazy initialisation, behind the
# comment "first use is before any thread exists". Two guest threads racing
# their first touch of any pthread object both re-ran pthread_mutex_init over
# storage the other already held. objcsupport.c's dtsd_key_make() had had
# exactly the same bug behind exactly the same comment, so this is a pattern,
# not an accident -- which is why it is worth a gate and not just a fix.
#
# scripts/difftest.sh runs each fixture ONCE, so 3% reads as green 97% of the
# time. That is the whole argument for this script, made a second time.
if [ $# -eq 0 ]; then
    B="$ROOT/tests/bin"
    E="$ROOT/tests/expected"
    for id in pthread pthread_cond; do
        if [ ! -x "$B/$id" ] || [ ! -f "$E/$id.stdout" ]; then
            echo "stress: skipping $id (no binary or no recorded baseline)"
            continue
        fi
        want=$(cat "$E/$id.stdout")
        fails=0; first_rc=""; first_err=""
        for ((i = 1; i <= N; i++)); do
            out=$(cd "$B" && timeout -k 2 30 "$LOADER" "./$id" 2>"$B/.stress.stderr")
            rc=$?
            if [ $rc -ne 0 ] || [ "$out" != "$want" ]; then
                fails=$((fails+1))
                [ -n "$first_rc" ] || { first_rc=$rc; first_err=$(head -3 "$B/.stress.stderr"); }
            fi
        done
        rm -f "$B/.stress.stderr"
        printf '%-38s %d/%d ok' "$id" $((N - fails)) "$N"
        if [ $fails -eq 0 ]; then echo; else
            echo "   <-- $fails FAILED"
            echo "    first failure exit $first_rc"
            [ -n "$first_err" ] && echo "$first_err" | sed 's/^/    /'
            total_fail=$((total_fail+fails))
        fi
    done
fi

echo "----------------------------------------------------------------------"
if [ $total_fail -eq 0 ]; then
    echo "threading gates: $N runs each, zero failures"
    exit 0
fi
echo "threading gates: $total_fail FAILED runs."
echo "  \"recursive acquisition by the owning thread\" on a fixture that does not"
echo "  recurse  -> the os_unfair_lock owner token is colliding between threads"
echo "              again; see docs/UNIMPLEMENTED.md#os-unfair-lock-owner."
echo "  \"futex facility returned an unexpected error code\""
echo "              -> something is lazily initialising a lock again; see"
echo "                 adopt_lock() in darwin/src/libsystem.c."
exit 1
