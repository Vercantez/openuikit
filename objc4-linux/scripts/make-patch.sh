#!/usr/bin/env bash
# Regenerate patches/<name>.patch from the current state of build/objc4-src
# for the given files, relative to the pristine vendor tree.
#
#   scripts/make-patch.sh 0001-config-linux-branch "rationale line" runtime/objc-config.h ...
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/vendor/objc4"
DST="${OBJC4_SRC_DIR:-$ROOT/build/objc4-src}"

name="$1"; shift
rationale="$1"; shift

out="$ROOT/patches/$name.patch"
{
    echo "# $rationale"
    for f in "$@"; do
        if [ -e "$SRC/$f" ]; then
            diff -u "$SRC/$f" "$DST/$f" \
                | sed -e "1s|^--- .*|--- a/$f|" -e "2s|^+++ .*|+++ b/$f|" || true
        else
            # New file: diff against /dev/null
            diff -u /dev/null "$DST/$f" \
                | sed -e "1s|^--- .*|--- /dev/null|" -e "2s|^+++ .*|+++ b/$f|" || true
        fi
    done
} > "$out"

echo "wrote $out ($(wc -l < "$out") lines)"
