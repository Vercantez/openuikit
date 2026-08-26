#!/bin/bash
# Shared helpers for the machorun differential-test harness.
# Sourced by run_macos.sh, run_linux.sh and scripts/difftest.sh.
#
# Deliberately bash-3.2 clean: /bin/bash on macOS is still 3.2, and the oracle
# side has to run there.

# ---------------------------------------------------------------- locations
harness_root() {
    ( cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd )
}
ROOT="${ROOT:-$(harness_root)}"
BIN_DIR="$ROOT/tests/bin"
EXPECTED_DIR="$ROOT/tests/expected"
ACTUAL_DIR="${ACTUAL_DIR:-$ROOT/tests/actual}"
MANIFEST="$ROOT/tests/manifest.tsv"

# ------------------------------------------------------------------ colours
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET=$'\033[0m'; C_RED=$'\033[31m'; C_GRN=$'\033[32m'
    C_YEL=$'\033[33m';  C_BLU=$'\033[34m'; C_DIM=$'\033[2m'; C_BLD=$'\033[1m'
else
    C_RESET=; C_RED=; C_GRN=; C_YEL=; C_BLU=; C_DIM=; C_BLD=
fi

die() { echo "${C_RED}error:${C_RESET} $*" >&2; exit 1; }

# ----------------------------------------------------------------- manifest
# Emits one TAB-separated row per fixture: id rung fixups oracle linux what
manifest_rows() {
    [ -f "$MANIFEST" ] || die "missing manifest: $MANIFEST"
    grep -v '^[[:space:]]*#' "$MANIFEST" | grep -v '^[[:space:]]*$'
}

manifest_ids() { manifest_rows | cut -f1; }

# field <row> <n>  -- 1-based TAB field
field() { printf '%s' "$1" | cut -f"$2"; }

# A manifest cell is either a bare verdict ("run", "pass") or
# "verdict:free text reason". These split it.
verdict() { printf '%s' "${1%%:*}"; }
reason()  { case "$1" in *:*) printf '%s' "${1#*:}";; *) printf '';; esac; }

# --------------------------------------------------------------- execution
# Run a command with a wall-clock limit; prefers GNU timeout, falls back to a
# watchdog so a stock macOS (no coreutils) still works.
TIMEOUT_SECS="${TIMEOUT_SECS:-20}"

_have() { command -v "$1" >/dev/null 2>&1; }

run_limited() { # run_limited <cmd...>   (caller handles redirection)
    if _have timeout;  then timeout  -k 2 "$TIMEOUT_SECS" "$@"; return $?; fi
    if _have gtimeout; then gtimeout -k 2 "$TIMEOUT_SECS" "$@"; return $?; fi
    "$@" &
    local pid=$! rc=0
    ( sleep "$TIMEOUT_SECS"; kill -9 "$pid" >/dev/null 2>&1 ) &
    local watchdog=$!
    wait "$pid"; rc=$?
    kill "$watchdog" >/dev/null 2>&1
    wait "$watchdog" >/dev/null 2>&1
    return $rc
}

# capture_run <outdir> <id> <cmd...>
# Writes <id>.stdout, <id>.stderr, <id>.exit into outdir. Fixtures are run
# from tests/bin with no arguments and a normalised locale/timezone so the
# output is a function of the binary alone.
capture_run() {
    local outdir="$1"; shift
    local id="$1"; shift
    mkdir -p "$outdir"
    local rc=0
    (
        cd "$BIN_DIR" || exit 125
        export LC_ALL=C LANG=C TZ=UTC
        run_limited "$@"
    ) >"$outdir/$id.stdout" 2>"$outdir/$id.stderr" || rc=$?
    printf '%d\n' "$rc" > "$outdir/$id.exit"
    return 0
}

# --------------------------------------------------------------- comparison
# compare_capture <expected_dir> <actual_dir> <id>
# echoes "match" or a human-readable first difference; returns 0 / 1.
compare_capture() {
    local e="$1" a="$2" id="$3"
    local ee ae
    if [ ! -f "$e/$id.exit" ]; then echo "no baseline recorded"; return 1; fi
    if [ ! -f "$a/$id.exit" ]; then echo "no result produced"; return 1; fi
    ee="$(cat "$e/$id.exit")"; ae="$(cat "$a/$id.exit")"
    if [ "$ee" != "$ae" ]; then echo "exit $ae, expected $ee"; return 1; fi
    if ! cmp -s "$e/$id.stdout" "$a/$id.stdout"; then
        local n
        n="$(diff "$e/$id.stdout" "$a/$id.stdout" 2>/dev/null | head -1)"
        echo "stdout differs (${n:-binary difference})"; return 1
    fi
    if ! cmp -s "$e/$id.stderr" "$a/$id.stderr"; then
        echo "stderr differs"; return 1
    fi
    echo "match"; return 0
}
