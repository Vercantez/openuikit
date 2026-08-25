#!/usr/bin/env bash
# Materialise a patched copy of the vendored objc4 into build/objc4-src.
#
# vendor/objc4 is PRISTINE and stays that way. Every change we make to Apple's
# source lives in patches/NNNN-*.patch and is applied here, so that an upstream
# drop can be re-vendored and the patches re-applied (or seen to conflict).
#
# Idempotent: the tree is re-synced from vendor before patching, so running
# this twice is the same as running it once.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/vendor/objc4"
DST="${OBJC4_SRC_DIR:-$ROOT/build/objc4-src}"

[ -d "$SRC/runtime" ] || { echo "error: $SRC/runtime not found" >&2; exit 1; }

mkdir -p "$(dirname "$DST")"
rsync -a --delete "$SRC/" "$DST/"

shopt -s nullglob
patches=( "$ROOT"/patches/*.patch )
if [ ${#patches[@]} -eq 0 ]; then
    echo "apply-patches: no patches, vendor copy is verbatim -> $DST"
    exit 0
fi

for p in "${patches[@]}"; do
    printf 'apply-patches: %-46s ' "$(basename "$p")"
    if patch -p1 -d "$DST" --forward --silent < "$p"; then
        # Print the rationale line (first line of the patch file, a comment).
        head -1 "$p" | sed 's/^# *//'
    else
        echo "FAILED"
        exit 1
    fi
done

echo "apply-patches: ${#patches[@]} patch(es) applied -> $DST"
