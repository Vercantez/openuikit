#!/usr/bin/env bash
# Stamp-keyed wrapper around machorun/scripts/build_fixtures_linux_x86_64.sh.
# Does not edit that script. Stamp + sentinel live under scratch/ so
# `git status --short machorun` stays empty (tests/bin-x86_64/ is gitignored;
# a sidecar next to that directory would not be).
#
# objc4 is not built here: scripts/x86/ensure_machorun.sh already runs
# `machorun/scripts/build.sh objc4` (via build_objc4.sh) stamp-keyed.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
W=${1:-}
if [ -z "$W" ]; then
    W=$(cd "$HERE/.." && pwd -P)
fi
W=$(cd "$W" && pwd -P)

# shellcheck source=../scripts/x86/stamp.inc
. "$W/scripts/x86/stamp.inc"

MACHORUN=$W/machorun
SCRIPT=$MACHORUN/scripts/build_fixtures_linux_x86_64.sh
BIN=$MACHORUN/tests/bin-x86_64
SENTINEL=$W/scratch/x86-fixtures-linux
TBD=$MACHORUN/sdk/usr/lib/libSystem.tbd
OBJC=$MACHORUN/darwin/usr/lib/libobjc.A.dylib

[ -f "$SCRIPT" ] || {
    printf 'cursor-fixtures: missing %s\n' "$SCRIPT" >&2
    exit 1
}
[ -s "$TBD" ] || {
    printf 'cursor-fixtures: missing %s (run the x86 cycle tbd stage first)\n' "$TBD" >&2
    exit 1
}
[ -f "$OBJC" ] || {
    printf 'cursor-fixtures: missing %s (ensure_machorun / build.sh objc4 first)\n' "$OBJC" >&2
    exit 1
}

mkdir -p "$W/scratch"

tree=$(git -C "$W" rev-parse HEAD:machorun 2>/dev/null | tr -d '[:space:]') || tree=missing
key=$(stamp_key "$SENTINEL" "$tree" "$SCRIPT" "$TBD" "$OBJC")

fixtures_bin_ready() {
    [ -s "$BIN/.built_count" ] || return 1
    [ "$(tr -d '[:space:]' < "$BIN/.built_count")" -gt 0 ] 2>/dev/null || return 1
}

if stamp_reuse "$SENTINEL" "$key" && fixtures_bin_ready; then
    printf 'CURSOR_ENV_X86_FIXTURES reused=1 stamp=%s built=%s out=%s\n' \
        "$(printf '%s' "$key" | cut -c1-12)" \
        "$(tr -d '[:space:]' < "$BIN/.built_count")" \
        "$BIN"
    exit 0
fi

stamp_rebuild_reason "$SENTINEL" "$key"
echo "== x86 fixtures (machorun/scripts/build_fixtures_linux_x86_64.sh)"
bash "$SCRIPT"

fixtures_bin_ready || {
    printf 'cursor-fixtures: builder did not produce %s/.built_count > 0\n' "$BIN" >&2
    exit 1
}

mkdir -p "$SENTINEL"
{
    printf 'built=%s\n' "$(tr -d '[:space:]' < "$BIN/.built_count")"
    printf 'refused=%s\n' "$(tr -d '[:space:]' < "$BIN/.refused_count" 2>/dev/null || printf '0')"
    printf 'out=%s\n' "$BIN"
} > "$SENTINEL/BUILD_SUMMARY"
stamp_write "$SENTINEL" "$key"
printf 'CURSOR_ENV_X86_FIXTURES rebuilt=1 stamp=%s built=%s out=%s\n' \
    "$(printf '%s' "$key" | cut -c1-12)" \
    "$(tr -d '[:space:]' < "$BIN/.built_count")" \
    "$BIN"
exit 0
