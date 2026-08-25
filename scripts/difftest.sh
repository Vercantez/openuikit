#!/bin/sh
# difftest.sh -- run the corpus on both sides and diff.
#
#   scripts/difftest.sh                 run everything, print the table
#   scripts/difftest.sh 010 023         run only tests whose name matches
#   scripts/difftest.sh --record        re-record the macOS baseline (macOS only)
#   scripts/difftest.sh --macos         check macOS against the baseline only
#   scripts/difftest.sh --linux         check Linux against the baseline only
#   scripts/difftest.sh -v              print the diff for every failure
#
# tests/expected/<name>.txt is the ORACLE: it is what Apple's shipping runtime
# printed on macOS. Both sides are compared against it, which means the table
# reports two distinct kinds of failure:
#
#   BASELINE-DRIFT  macOS no longer matches the recorded baseline. The oracle
#                   itself moved (new OS, changed test); nothing about the port
#                   is being measured until this is resolved.
#   FAIL            Linux does not match the baseline. This is the real signal.
#
# Only stdout is compared. The runtime writes diagnostics to stderr and those
# are not part of the contract.

set -u

REPO=$(cd "$(dirname "$0")/.." && pwd)
TESTS_DIR=$REPO/tests
EXPECTED_DIR=$TESTS_DIR/expected
OUT=$REPO/build/difftest
mkdir -p "$OUT" "$EXPECTED_DIR"

RECORD=0
DO_MACOS=1
DO_LINUX=1
VERBOSE=0
FILTERS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --record)  RECORD=1; DO_LINUX=0 ;;
        --macos)   DO_LINUX=0 ;;
        --linux)   DO_MACOS=0 ;;
        -v|--verbose) VERBOSE=1 ;;
        -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
        -*)        echo "difftest.sh: unknown option $1" >&2; exit 64 ;;
        *)         FILTERS="$FILTERS $1" ;;
    esac
    shift
done

[ "$(uname -s)" = "Darwin" ] || DO_MACOS=0
if [ "$RECORD" = 1 ] && [ "$DO_MACOS" = 0 ]; then
    echo "difftest.sh: --record requires macOS (the oracle is the system runtime)" >&2
    exit 64
fi

matches() {
    [ -z "$FILTERS" ] && return 0
    for f in $FILTERS; do
        case "$1" in *"$f"*) return 0 ;; esac
    done
    return 1
}

pad() { printf '%-28s' "$1"; }

n_pass=0; n_fail=0; n_skip=0; n_drift=0; n_error=0; n_total=0
failed_names=""

printf '%-28s %-9s %-9s %s\n' TEST MACOS LINUX RESULT
printf -- '---------------------------- --------- --------- ----------------\n'

for test in "$TESTS_DIR"/*.m; do
    [ -e "$test" ] || continue
    # <name>.lib.m is a companion image built by the runners, not a test.
    case "$test" in *.lib.m) continue ;; esac
    name=$(basename "$test" .m)
    matches "$name" || continue
    n_total=$((n_total + 1))

    expected="$EXPECTED_DIR/$name.txt"
    mac_status="-"
    lin_status="-"
    result=""

    # ---- macOS side ---------------------------------------------------------
    if [ "$DO_MACOS" = 1 ]; then
        if "$REPO/harness/run_macos.sh" "$test" > "$OUT/$name.macos.txt" 2> "$OUT/$name.macos.err"; then
            mac_status="ok"
            if [ "$RECORD" = 1 ]; then
                cp "$OUT/$name.macos.txt" "$expected"
                mac_status="recorded"
            fi
        else
            case $? in
                1) mac_status="compile" ;;
                2) mac_status="crash" ;;
                *) mac_status="skip" ;;
            esac
        fi
    fi

    if [ ! -f "$expected" ]; then
        result="NO-BASELINE"
        n_error=$((n_error + 1))
        pad "$name"; printf ' %-9s %-9s %s\n' "$mac_status" "$lin_status" "$result"
        continue
    fi

    # The macOS run must still agree with the recorded oracle.
    if [ "$DO_MACOS" = 1 ] && [ "$RECORD" = 0 ] && [ "$mac_status" = "ok" ]; then
        if ! diff -q "$expected" "$OUT/$name.macos.txt" >/dev/null 2>&1; then
            mac_status="DRIFT"
        fi
    fi

    # ---- Linux side ---------------------------------------------------------
    if [ "$DO_LINUX" = 1 ]; then
        "$REPO/harness/run_linux.sh" "$test" > "$OUT/$name.linux.txt" 2> "$OUT/$name.linux.err"
        case $? in
            0) if diff -q "$expected" "$OUT/$name.linux.txt" >/dev/null 2>&1; then
                   lin_status="ok"
               else
                   lin_status="differs"
               fi ;;
            1) lin_status="compile" ;;
            2) lin_status="crash" ;;
            3) lin_status="skip" ;;
            *) lin_status="error" ;;
        esac
    fi

    # ---- verdict ------------------------------------------------------------
    if [ "$mac_status" = "DRIFT" ]; then
        result="BASELINE-DRIFT"; n_drift=$((n_drift + 1)); failed_names="$failed_names $name"
    elif [ "$mac_status" = "crash" ] || [ "$mac_status" = "compile" ]; then
        result="MACOS-BROKEN"; n_error=$((n_error + 1)); failed_names="$failed_names $name"
    elif [ "$DO_LINUX" = 0 ]; then
        result="BASELINE-OK"; n_pass=$((n_pass + 1))
    elif [ "$lin_status" = "ok" ]; then
        result="PASS"; n_pass=$((n_pass + 1))
    elif [ "$lin_status" = "skip" ]; then
        result="SKIPPED"; n_skip=$((n_skip + 1))
    else
        result="FAIL"; n_fail=$((n_fail + 1)); failed_names="$failed_names $name"
    fi

    pad "$name"; printf ' %-9s %-9s %s\n' "$mac_status" "$lin_status" "$result"

    if [ "$VERBOSE" = 1 ] && [ "$result" = "FAIL" ] && [ -s "$OUT/$name.linux.txt" ]; then
        diff -u "$expected" "$OUT/$name.linux.txt" | sed 's/^/    /' | head -40
    fi
done

echo
if [ "$RECORD" = 1 ]; then
    echo "recorded $n_total baseline(s) into tests/expected/ from the macOS system runtime"
    exit 0
fi

printf '%d tests: %d PASS, %d FAIL, %d SKIPPED' "$n_total" "$n_pass" "$n_fail" "$n_skip"
[ "$n_drift" -gt 0 ] && printf ', %d BASELINE-DRIFT' "$n_drift"
[ "$n_error" -gt 0 ] && printf ', %d ERROR' "$n_error"
echo

if [ -n "$failed_names" ]; then
    echo "not passing:$failed_names"
    echo "outputs in build/difftest/"
fi

[ "$n_fail" -eq 0 ] && [ "$n_drift" -eq 0 ] && [ "$n_error" -eq 0 ]
