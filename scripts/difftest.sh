#!/bin/bash
# The scoreboard: macOS baseline vs machorun-on-Linux, one row per fixture.
#
#   scripts/difftest.sh                run the whole loop and print the table
#   scripts/difftest.sh --no-run       grade whatever is already in tests/actual/
#   scripts/difftest.sh --no-verify    skip re-verifying the oracle (not advised)
#   scripts/difftest.sh 03_printf ...  restrict to some fixtures
#
# Verdicts
#   PASS            Linux output is byte-identical to macOS, exit code included
#   FAIL            it is not
#   XFAIL           it is not, and the manifest says so with a reason -- a
#                   documented wall, not a surprise
#   XPASS           the manifest expected failure and it passed. Good news, but
#                   it means the manifest is now lying; update it.
#   SKIPPED         nothing ran on Linux (no loader yet, no docker, ...)
#   NO-ORACLE       macOS cannot execute this fixture, so there is nothing to
#                   diff against; it exists for the loader's parser
#   BASELINE-DRIFT  macOS itself no longer produces the recorded output. The
#                   whole comparison is void until that is resolved -- this is
#                   never reported as PASS.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/harness/common.sh"

DO_RUN=1
DO_VERIFY=1
ONLY=()
for a in "$@"; do
    case "$a" in
        --no-run) DO_RUN=0 ;;
        --no-verify) DO_VERIFY=0 ;;
        -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
        -*) die "unknown option $a" ;;
        *) ONLY+=("$a") ;;
    esac
done

selected() {
    [ ${#ONLY[@]} -eq 0 ] && return 0
    local w
    for w in "${ONLY[@]}"; do [ "$w" = "$1" ] && return 0; done
    return 1
}

MAC_DIR="$ACTUAL_DIR/macos"
LNX_DIR="$ACTUAL_DIR/linux"
DRIFTED=""

# ------------------------------------------------------------ oracle trust
# Baselines are only meaningful if a Darwin machine produced them. This is the
# check that makes the numbers trustworthy; without it a stray run on Linux
# could quietly redefine "correct".
PROVENANCE="$EXPECTED_DIR/PROVENANCE"
if [ ! -f "$PROVENANCE" ]; then
    die "tests/expected/PROVENANCE is missing. Baselines are untrusted; record them on macOS with harness/run_macos.sh --record"
fi
prov_os="$(awk -F': ' '/^os:/{print $2}' "$PROVENANCE")"
if [ "$prov_os" != "Darwin" ]; then
    die "tests/expected/PROVENANCE says os=$prov_os. Baselines must come from Darwin. Refusing to grade."
fi

# ------------------------------------------------------------ oracle side
if [ "$(uname -s)" = "Darwin" ] && [ "$DO_VERIFY" = 1 ]; then
    mkdir -p "$ACTUAL_DIR"
    NO_COLOR=1 "$ROOT/harness/run_macos.sh" ${ONLY[@]+"${ONLY[@]}"} \
        > "$ACTUAL_DIR/.macos-verify.log" 2>&1
    DRIFTED="$(awk '/BASELINE-DRIFT/{print $1}' "$ACTUAL_DIR/.macos-verify.log" 2>/dev/null | tr '\n' ' ')"
elif [ "$DO_VERIFY" = 1 ]; then
    printf '%snote:%s not on macOS, so the oracle could not be re-verified this run.\n' "$C_YEL" "$C_RESET"
    printf '      Baselines recorded %s.\n\n' "$(awk -F': ' '/^recorded:/{print $2}' "$PROVENANCE")"
fi

drifted() { case " $DRIFTED " in *" $1 "*) return 0;; *) return 1;; esac; }

# ------------------------------------------------------------ linux side
LINUX_SKIP_REASON=""
if [ "$DO_RUN" = 1 ]; then
    "$ROOT/harness/run_linux.sh" ${ONLY[@]+"${ONLY[@]}"} > "$ACTUAL_DIR/.linux-run.log" 2>&1
fi
if [ -f "$LNX_DIR/.status" ]; then
    st="$(cut -f1 "$LNX_DIR/.status")"
    [ "$st" = "ran" ] || LINUX_SKIP_REASON="$(cut -f2 "$LNX_DIR/.status")"
else
    LINUX_SKIP_REASON="harness/run_linux.sh has not produced any results"
fi

# ------------------------------------------------------------ the table
printf '\n%smachorun differential test%s\n' "$C_BLD" "$C_RESET"
printf '%soracle: %s | %s%s\n' "$C_DIM" \
    "$(awk -F': ' '/^product:/{print $2}' "$PROVENANCE")" \
    "$(awk -F': ' '/^ld:/{print $2}' "$PROVENANCE")" "$C_RESET"
if [ -n "$LINUX_SKIP_REASON" ]; then
    printf '%slinux:  not run -- %s%s\n' "$C_YEL" "$LINUX_SKIP_REASON" "$C_RESET"
fi
printf '\n'
printf '%-24s %-5s %-8s %-16s %s\n' "FIXTURE" "RUNG" "FIXUPS" "VERDICT" "DETAIL"
printf '%s\n' "--------------------------------------------------------------------------------"

n_pass=0 n_fail=0 n_xfail=0 n_xpass=0 n_skip=0 n_noor=0 n_drift=0

while IFS= read -r row; do
    id="$(field "$row" 1)"
    rung="$(field "$row" 2)"
    fixups="$(field "$row" 3)"
    oracle="$(field "$row" 4)"
    linux="$(field "$row" 5)"
    selected "$id" || continue

    colour="$C_RESET"; verdict_s=""; detail=""

    if drifted "$id"; then
        verdict_s="BASELINE-DRIFT"; colour="$C_RED"
        detail="macOS output changed; comparison void"
        n_drift=$((n_drift + 1))
    elif [ "$(verdict "$oracle")" = "norun" ]; then
        verdict_s="NO-ORACLE"; colour="$C_YEL"
        detail="$(reason "$oracle")"
        n_noor=$((n_noor + 1))
    elif [ -n "$LINUX_SKIP_REASON" ] || [ ! -f "$LNX_DIR/$id.exit" ]; then
        verdict_s="SKIPPED"; colour="$C_YEL"
        # The global reason is already printed above the table; only say
        # something here if this one fixture is skipped for its own reason.
        [ -n "$LINUX_SKIP_REASON" ] && detail="" || detail="no result recorded"
        n_skip=$((n_skip + 1))
    else
        cmp_out="$(compare_capture "$EXPECTED_DIR" "$LNX_DIR" "$id")"
        if [ "$cmp_out" = match ]; then
            if [ "$(verdict "$linux")" = "xfail" ]; then
                verdict_s="XPASS"; colour="$C_BLU"
                detail="manifest says xfail but it passed -- update tests/manifest.tsv"
                n_xpass=$((n_xpass + 1))
            else
                verdict_s="PASS"; colour="$C_GRN"
                n_pass=$((n_pass + 1))
            fi
        else
            if [ "$(verdict "$linux")" = "xfail" ]; then
                verdict_s="XFAIL"; colour="$C_YEL"
                detail="$(reason "$linux")"
                n_xfail=$((n_xfail + 1))
            else
                verdict_s="FAIL"; colour="$C_RED"
                detail="$cmp_out"
                n_fail=$((n_fail + 1))
            fi
        fi
    fi

    printf '%-24s %-5s %-8s %s%-16s%s %s\n' \
        "$id" "$rung" "$fixups" "$colour" "$verdict_s" "$C_RESET" "$detail"
done < <(manifest_rows)

printf '%s\n' "--------------------------------------------------------------------------------"
printf '%spass %d%s  %sfail %d%s  %sxfail %d%s  %sxpass %d%s  %sskipped %d%s  %sno-oracle %d%s  %sdrift %d%s\n' \
    "$C_GRN" "$n_pass" "$C_RESET" "$C_RED" "$n_fail" "$C_RESET" \
    "$C_YEL" "$n_xfail" "$C_RESET" "$C_BLU" "$n_xpass" "$C_RESET" \
    "$C_YEL" "$n_skip" "$C_RESET" "$C_YEL" "$n_noor" "$C_RESET" \
    "$C_RED" "$n_drift" "$C_RESET"

if [ "$n_fail" -gt 0 ] || [ "$n_drift" -gt 0 ]; then
    echo
    echo "To see a failure in detail:"
    echo "  diff tests/expected/<id>.stdout tests/actual/linux/<id>.stdout"
    echo "  cat  tests/actual/linux/<id>.stderr"
    exit 1
fi

# A run in which nothing executed is not a passing run. Until 2026-08-25 this
# script exited 0 when the loader failed to compile and every row said SKIPPED,
# so a CI gate on the exit status went green on a tree that did not build.
# Measured, not theorised: appending `this is not c;` to src/main.c produced
# "pass 0 ... skipped 20" and exit 0. Distinct code, because "nothing ran" is a
# different fact from "something disagreed with macOS".
if [ "$n_skip" -gt 0 ]; then
    echo
    printf '%s%d fixture(s) did not run, so this is not a verdict.%s\n' "$C_RED" "$n_skip" "$C_RESET"
    [ -n "$LINUX_SKIP_REASON" ] && echo "  reason: $LINUX_SKIP_REASON"
    echo "  see tests/actual/linux/.build.log"
    exit 2
fi
exit 0
