#!/bin/bash
# The scoreboard: macOS baseline vs machorun-on-Linux, one row per fixture.
#
#   scripts/difftest.sh                run the whole loop and print the table
#   scripts/difftest.sh --no-run       grade whatever is already in tests/actual/
#   scripts/difftest.sh --no-verify    skip re-verifying the oracle (not advised)
#   scripts/difftest.sh printf ...  restrict to some fixtures
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

# Taken before ANY work, and compared after all of it. See the check further
# down for why the tree moving mid-run is a real event here rather than a
# hypothetical one.
HEAD_BEFORE=""
git -C "$ROOT" rev-parse --short HEAD >/dev/null 2>&1 &&
    HEAD_BEFORE="$(git -C "$ROOT" rev-parse --short HEAD)"

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
    if [ "$st" != "ran" ]; then
        LINUX_SKIP_REASON="$(cut -f2 "$LNX_DIR/.status")"
        # A shell error after run_linux truncates .status must not grade old
        # captures: measured with Bash 3.2's embedded-heredoc parse failure.
        LINUX_SKIP_REASON="${LINUX_SKIP_REASON:-harness/run_linux.sh did not complete (empty status)}"
    fi
else
    LINUX_SKIP_REASON="harness/run_linux.sh has not produced any results"
fi

# ------------------------------------------- did the subject hold still?
#
# REFUSES BEFORE PRINTING ANYTHING, which is the whole design. A scoreboard
# assembled from two different loaders looks exactly like one assembled from
# one, so there is no verdict worth showing and no partial result worth
# salvaging -- printing the table with a warning above it would leave numbers on
# the screen that someone will quote. See harness/common.sh#gate_check_stable.
FP_LINE=""
if [ -z "$LINUX_SKIP_REASON" ] && [ -f "$LNX_DIR/.fingerprint" ]; then
    fp_before="$(cut -f1 "$LNX_DIR/.fingerprint")"
    fp_after="$(cut -f2 "$LNX_DIR/.fingerprint")"
    gate_check_stable "$fp_before" "$fp_after" "loader and darwin/ dylibs" || exit 2
    FP_LINE="build $fp_before"
elif [ -z "$LINUX_SKIP_REASON" ]; then
    # The Linux side says it ran but recorded no fingerprint. That is a harness
    # older than this check, not a clean run -- report it as unknown rather than
    # letting a missing file read as agreement.
    FP_LINE="build unrecorded (harness predates the stability check)"
fi

# THE SOURCES MUST ALSO HOLD STILL, and this is a second question rather than
# the same one twice. The artefacts can be byte-identical across a branch switch
# while tests/expected/ -- the baselines being graded against -- is not. HEAD is
# the cheapest thing that moves when either does.
HEAD_AFTER=""
if git -C "$ROOT" rev-parse --short HEAD >/dev/null 2>&1; then
    HEAD_AFTER="$(git -C "$ROOT" rev-parse --short HEAD)"
    if [ -n "${HEAD_BEFORE:-}" ]; then
        gate_check_stable "$HEAD_BEFORE" "$HEAD_AFTER" "git HEAD" || exit 2
    fi
fi

# ------------------------------------------------------------ the table
printf '\n%smachorun differential test%s\n' "$C_BLD" "$C_RESET"
printf '%soracle: %s | %s%s\n' "$C_DIM" \
    "$(awk -F': ' '/^product:/{print $2}' "$PROVENANCE")" \
    "$(awk -F': ' '/^ld:/{print $2}' "$PROVENANCE")" "$C_RESET"
if [ -n "$LINUX_SKIP_REASON" ]; then
    printf '%slinux:  not run -- %s%s\n' "$C_YEL" "$LINUX_SKIP_REASON" "$C_RESET"
fi
# The subject, named on the scoreboard. A verdict is about a specific tree, and
# a table that does not say which one cannot be quoted later without guessing.
if [ -n "$FP_LINE" ] || [ -n "$HEAD_AFTER" ]; then
    printf '%ssubject: %s%s%s\n' "$C_DIM" \
        "${HEAD_AFTER:+HEAD $HEAD_AFTER }" "$FP_LINE" "$C_RESET"
fi
printf '\n'
printf '%-26s %-4s %-8s %-16s %s\n' "FIXTURE" "RUNG" "FIXUPS" "VERDICT" "DETAIL"
printf '%s\n' "--------------------------------------------------------------------------------"

n_pass=0 n_fail=0 n_xfail=0 n_xpass=0 n_skip=0 n_noor=0 n_drift=0
ladder=0

while IFS= read -r row; do
    id="$(field "$row" 1)"
    fixups="$(field "$row" 2)"
    oracle="$(field "$row" 3)"
    linux="$(field "$row" 4)"
    # The ladder position is RENDERED, not stored. It used to be a column that
    # every new fixture had to claim, which is a thing to remember rather than
    # a thing that refuses -- and four merges in one day collided on it. Row
    # order in the manifest IS the ladder; this just numbers it for reading.
    ladder=$((ladder + 1))
    selected "$id" || continue

    colour="$C_RESET"; verdict_s=""; detail=""

    if drifted "$id"; then
        verdict_s="BASELINE-DRIFT"; colour="$C_RED"
        detail="macOS output changed; comparison void"
        n_drift=$((n_drift + 1))
    elif [ "$(verdict "$oracle")" = "norun" ]; then
        # Linux-only fixtures: Darwin cannot execute them (unaligned cache
        # layout, a segment that overruns the file) but they still have a
        # committed expected/ that describes what the loader must do. Grade
        # that. exit_unixthread stays NO-ORACLE because it is linux=xfail
        # and has no expected output -- the two cases must not collapse.
        if [ "$(verdict "$linux")" = "pass" ] && [ -f "$EXPECTED_DIR/$id.exit" ]; then
            if [ -n "$LINUX_SKIP_REASON" ] || [ ! -f "$LNX_DIR/$id.exit" ]; then
                verdict_s="SKIPPED"; colour="$C_YEL"
                [ -n "$LINUX_SKIP_REASON" ] && detail="" || detail="no result recorded"
                n_skip=$((n_skip + 1))
            else
                cmp_out="$(compare_capture "$EXPECTED_DIR" "$LNX_DIR" "$id")"
                if [ "$cmp_out" = match ]; then
                    verdict_s="PASS"; colour="$C_GRN"
                    n_pass=$((n_pass + 1))
                else
                    verdict_s="FAIL"; colour="$C_RED"
                    detail="$cmp_out"
                    n_fail=$((n_fail + 1))
                fi
            fi
        else
            verdict_s="NO-ORACLE"; colour="$C_YEL"
            detail="$(reason "$oracle")"
            n_noor=$((n_noor + 1))
        fi
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

    printf '%-26s %-4s %-8s %s%-16s%s %s\n' \
        "$id" "$ladder" "$fixups" "$colour" "$verdict_s" "$C_RESET" "$detail"
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
