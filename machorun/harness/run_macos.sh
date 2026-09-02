#!/bin/bash
# The oracle. Runs the fixtures natively on macOS and either RECORDS the
# expected behaviour or VERIFIES that the recorded behaviour still holds.
#
#   harness/run_macos.sh            verify baselines still match this machine
#   harness/run_macos.sh --record   (re-)record baselines
#   harness/run_macos.sh --record printf tls    record just these
#
# GUARDING THE ORACLE
# -------------------
# Everything downstream trusts tests/expected/. Three locks:
#   1. This script refuses to run anywhere but Darwin. A Linux box cannot
#      write a baseline even by accident, because --record only exists here.
#   2. Recording stamps tests/expected/PROVENANCE with the OS, kernel and
#      toolchain that produced the baselines. difftest.sh reads that stamp and
#      refuses to grade anything if it does not say Darwin.
#   3. Verification (the default mode) re-runs every fixture natively and
#      compares. If macOS's own output has moved -- new OS, new libSystem --
#      you get BASELINE-DRIFT, never a silent PASS built on a stale baseline.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/harness/common.sh"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "${C_RED}run_macos.sh: this is the ORACLE and only runs on macOS.${C_RESET}" >&2
    echo "  host is $(uname -s); baselines must come from a machine that" >&2
    echo "  executes the fixture bytes natively. Refusing." >&2
    exit 64
fi

MODE=verify
ONLY=()
for a in "$@"; do
    case "$a" in
        --record) MODE=record ;;
        --verify|--check) MODE=verify ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
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

PROVENANCE="$EXPECTED_DIR/PROVENANCE"
OUT_DIR="$ACTUAL_DIR/macos"
mkdir -p "$EXPECTED_DIR" "$OUT_DIR"

write_provenance() {
    {
        echo "os: $(uname -s)"
        echo "release: $(uname -r)"
        echo "arch: $(uname -m)"
        echo "product: $(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null) ($(sw_vers -buildVersion 2>/dev/null))"
        echo "clang: $(clang --version 2>/dev/null | head -1)"
        echo "ld: $(ld -v 2>&1 | head -1)"
        echo "recorded: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    } > "$PROVENANCE"
}

printf '%s%s%s  (%s)\n' "$C_BLD" \
    "$([ $MODE = record ] && echo 'recording macOS baselines' || echo 'verifying macOS baselines')" \
    "$C_RESET" "$(sw_vers -productVersion 2>/dev/null) $(uname -m)"
printf '%s\n' "----------------------------------------------------------------------"

n_ok=0 n_drift=0 n_recorded=0 n_skipped=0 n_missing=0

while IFS= read -r row; do
    id="$(field "$row" 1)"
    oracle="$(field "$row" 3)"   # id, fixups, ORACLE, linux, what
    selected "$id" || continue

    if [ "$(verdict "$oracle")" = "norun" ]; then
        printf '  %-24s %sNO-ORACLE%s  %s\n' "$id" "$C_YEL" "$C_RESET" "$(reason "$oracle")"
        n_skipped=$((n_skipped + 1))
        continue
    fi

    if [ ! -x "$BIN_DIR/$id" ]; then
        printf '  %-24s %sMISSING%s    tests/bin/%s not built\n' "$id" "$C_RED" "$C_RESET" "$id"
        n_missing=$((n_missing + 1))
        continue
    fi

    capture_run "$OUT_DIR" "$id" "./$id"

    if [ "$MODE" = record ]; then
        cp "$OUT_DIR/$id.stdout" "$EXPECTED_DIR/$id.stdout"
        cp "$OUT_DIR/$id.stderr" "$EXPECTED_DIR/$id.stderr"
        cp "$OUT_DIR/$id.exit"   "$EXPECTED_DIR/$id.exit"
        printf '  %-24s %sRECORDED%s   exit=%s stdout=%s bytes\n' "$id" "$C_GRN" "$C_RESET" \
            "$(cat "$EXPECTED_DIR/$id.exit")" \
            "$(wc -c < "$EXPECTED_DIR/$id.stdout" | tr -d ' ')"
        n_recorded=$((n_recorded + 1))
    else
        detail="$(compare_capture "$EXPECTED_DIR" "$OUT_DIR" "$id")"
        if [ "$detail" = match ]; then
            printf '  %-24s %sOK%s\n' "$id" "$C_GRN" "$C_RESET"
            n_ok=$((n_ok + 1))
        elif [ "$detail" = "no baseline recorded" ]; then
            printf '  %-24s %sNO-BASELINE%s  run with --record\n' "$id" "$C_YEL" "$C_RESET"
            n_missing=$((n_missing + 1))
        else
            printf '  %-24s %sBASELINE-DRIFT%s  %s\n' "$id" "$C_RED" "$C_RESET" "$detail"
            n_drift=$((n_drift + 1))
        fi
    fi
done < <(manifest_rows)

if [ "$MODE" = record ] && [ ${#ONLY[@]} -eq 0 ]; then
    write_provenance
fi

printf '%s\n' "----------------------------------------------------------------------"
if [ "$MODE" = record ]; then
    printf 'recorded %d, no-oracle %d, missing %d\n' "$n_recorded" "$n_skipped" "$n_missing"
    [ "$n_missing" -gt 0 ] && exit 1
    exit 0
fi
printf 'ok %d, drift %d, no-oracle %d, missing %d\n' "$n_ok" "$n_drift" "$n_skipped" "$n_missing"
if [ "$n_drift" -gt 0 ]; then
    echo
    echo "${C_RED}The oracle moved.${C_RESET} macOS no longer produces the recorded output for"
    echo "the fixtures above. Do NOT re-record blindly -- find out what changed"
    echo "first (OS update? rebuilt fixtures? nondeterministic output?), then"
    echo "re-record deliberately and commit the diff on its own."
    exit 1
fi
[ "$n_missing" -gt 0 ] && exit 1
exit 0
