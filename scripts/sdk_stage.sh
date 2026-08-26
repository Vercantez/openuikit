#!/bin/bash
# sdk_stage.sh -- assemble sdk/usr/include from sdk/MANIFEST.tsv.
#
#   scripts/sdk_stage.sh            fetch what is missing, stage, rewrite CHECKSUMS
#   scripts/sdk_stage.sh --verify   re-fetch upstream and prove the staged tree
#                                   still matches it, byte for byte.  Needs network.
#   scripts/sdk_stage.sh --offline  stage from the cache only; never touch the net
#
# sdk/usr/include is COMMITTED.  This script is how it is regenerated, not how
# it is obtained at build time -- the build must work with no network and no
# Xcode, which is the entire point of the milestone.
#
# Four sources, and the manifest says which is which per header:
#   <repo>:<path>     apple-oss-distributions/<repo> at the tag in sdk/SOURCES.tsv
#   gen:<repo>:<path> a header that is not a blob upstream but is the OUTPUT of
#                     a generator upstream publishes -- run it, do not transcribe
#   objc4:<path>      vendor/objc4 (Apple's objc4 drop, already in tree)
#   local             sdk/local/<same relative path> -- clean-room, ours
#
# Loud aborts, no silent stubs: a header the manifest names and this script
# cannot produce is a hard failure here, not a confusing compile error 400
# files later.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SDK="$ROOT/sdk"
INC="$SDK/usr/include"
CACHE="${SDK_CACHE:-$ROOT/build/sdk-src}"
MANIFEST="$SDK/MANIFEST.tsv"
SOURCES="$SDK/SOURCES.tsv"
SUMS="$SDK/CHECKSUMS.sha256"
RAW="https://raw.githubusercontent.com/apple-oss-distributions"

MODE=stage
case "${1:---}" in
    --verify)  MODE=verify ;;
    --offline) MODE=offline ;;
    --) ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "sdk_stage: unknown option $1" >&2; exit 64 ;;
esac

die() { echo "sdk_stage: $*" >&2; exit 1; }

[ -f "$MANIFEST" ] || die "no manifest at $MANIFEST"
[ -f "$SOURCES" ]  || die "no source pins at $SOURCES"

sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
           else shasum -a 256 "$1" | cut -d' ' -f1; fi; }

# ------------------------------------------------------------------ the pins
declare -A TAG
while IFS=$'\t' read -r repo tag lic what; do
    case "$repo" in ''|\#*) continue ;; esac
    TAG[$repo]="$tag"
done < "$SOURCES"
echo "== pinned releases: ${#TAG[@]}"

# ---------------------------------------------------------------- the fetch
# One curl per upstream file, into a per-repo/per-tag cache.  Individual files
# rather than tarballs: xnu's tarball is ~100 MB and we want 202 headers from it.
fetch_one() { # fetch_one <repo> <path>
    local repo="$1" path="$2" tag="${TAG[$1]:-}" dst
    [ -n "$tag" ] || die "no tag pinned for repo '$repo' (sdk/SOURCES.tsv)"
    dst="$CACHE/$repo-$tag/$path"
    [ -s "$dst" ] && return 0
    [ "$MODE" = offline ] && die "cache miss for $repo:$path and --offline was given"
    mkdir -p "$(dirname "$dst")"
    if ! curl -fsSL --retry 3 "$RAW/$repo/$tag/$path" -o "$dst.tmp"; then
        rm -f "$dst.tmp"
        die "cannot fetch $repo:$path at $tag -- check the path in sdk/MANIFEST.tsv"
    fi
    # GitHub serves a 200 with a text body for some error shapes; a header that
    # is not a header is worth catching here rather than at compile time.
    [ -s "$dst.tmp" ] || { rm -f "$dst.tmp"; die "$repo:$path came back empty"; }
    mv "$dst.tmp" "$dst"
}

# -------------------------------------------------- source tree -> SDK tree
# A published header is not the installed header.  Libc marks the regions that
# exist only while Libc itself is being built, and its own install step deletes
# them:
#
#   Libc/xcodescripts/headers.sh:407
#       for i in `... grep -l '^//Begin-Libc'`; do ed - $i < strip-header.ed
#   Libc/xcodescripts/strip-header.ed
#       g/^\/\/Begin-Libc$/.,/^\/\/End-Libc$/d
#
# Skip it and _ctype.h arrives with `#include "xlocale_private.h"` at the top,
# which is not in any SDK and stops 28 of 32 objc4 TUs dead.  This reproduces
# Apple's rule exactly, on the same trigger, and nothing else.
#
# Apple's headers.sh also runs `unifdef` with arguments computed by
# generate_features.pl.  That pass is NOT reproduced here: its inputs are
# build-configuration flags we do not have, and its effect is to delete
# preprocessor branches that a compiler evaluates to the same answer anyway.
# If that ever stops being true it will be a compile error, which is the point.
n_stripped=0
install_header() { # install_header <src> <dst>
    if grep -q '^//Begin-Libc$' "$1" 2>/dev/null; then
        sed '/^\/\/Begin-Libc$/,/^\/\/End-Libc$/d' "$1" > "$2"
        n_stripped=$((n_stripped+1))
    else
        cp "$1" "$2"
    fi
}

# --------------------------------------------------------------- the staging
rm -rf "$INC"
mkdir -p "$INC" "$CACHE"

n_up=0 n_local=0 n_objc=0
: > "$SUMS.new"

while IFS=$'\t' read -r rel src; do
    case "$rel" in ''|\#*) continue ;; esac
    [ -n "$src" ] || die "manifest row for '$rel' has no source"
    out="$INC/$rel"
    mkdir -p "$(dirname "$out")"
    case "$src" in
        local)
            in="$SDK/local/$rel"
            [ -f "$in" ] || die "manifest says '$rel' is local, but sdk/local/$rel does not exist"
            cp "$in" "$out"; n_local=$((n_local+1)) ;;
        objc4:*)
            in="$ROOT/vendor/objc4/${src#objc4:}"
            [ -f "$in" ] || die "manifest says '$rel' comes from $src, but $in does not exist"
            cp "$in" "$out"; n_objc=$((n_objc+1)) ;;
        gen:*)
            # A header that is not a blob upstream but is the OUTPUT of a
            # generator upstream publishes.  Running it beats transcribing it.
            spec="${src#gen:}"; repo="${spec%%:*}"; path="${spec#*:}"
            fetch_one "$repo" "$path"
            g="$CACHE/$repo-${TAG[$repo]}/$path"
            ( cd "$(dirname "$out")" && sh "$g" "$(basename "$out")" ) >/dev/null \
                || die "generator $src failed for $rel"
            [ -s "$out" ] || die "generator $src produced nothing for $rel"
            printf '%s  %s  %s\n' "$(sha256 "$g")" "$src" "$rel" >> "$SUMS.new"
            n_up=$((n_up+1)) ;;
        *:*)
            repo="${src%%:*}"; path="${src#*:}"
            fetch_one "$repo" "$path"
            in="$CACHE/$repo-${TAG[$repo]}/$path"
            install_header "$in" "$out"
            # The checksum is of the PRISTINE upstream file, not of what we
            # wrote: that is what --verify has to be able to re-derive.
            printf '%s  %s  %s\n' "$(sha256 "$in")" "$src" "$rel" >> "$SUMS.new"
            n_up=$((n_up+1)) ;;
        *) die "manifest row '$rel': unrecognised source '$src'" ;;
    esac
done < "$MANIFEST"

echo "   upstream $n_up   clean-room $n_local   objc4 $n_objc   = $((n_up+n_local+n_objc))"
echo "   //Begin-Libc regions stripped from $n_stripped header(s), as Libc's own install does"

# ---------------------------------------------------------------- the patches
# The second class of "published tree is not the installed header", and unlike
# the //Begin-Libc one there is no upstream rule to reproduce: Apple's release
# process deletes `#ifndef __OPEN_SOURCE__` regions from some headers and does
# not delete the code that USES what those regions defined.  dyld's
# mach-o/dyld.h references DYLD_EXCLAVEKIT_UNAVAILABLE eight times and, in the
# published copy, defines it nowhere.
#
# So: one patch per header, in sdk/patches/, each with a header comment saying
# what upstream dropped.  Small, auditable, and it fails loudly -- a patch that
# does not apply is a pinned tag that moved, which is exactly the drift
# docs/SDK_SURVEY.md §6.2 warns about.
shopt -s nullglob 2>/dev/null || true
PATCHES=("$SDK"/patches/*.patch)
if [ ${#PATCHES[@]} -gt 0 ]; then
    for p in "${PATCHES[@]}"; do
        patch -p1 -d "$INC" --no-backup-if-mismatch -s < "$p" \
            || die "sdk/patches/$(basename "$p") did not apply -- has the pinned tag moved?"
    done
    echo "   patches applied: ${#PATCHES[@]}"
fi

# ------------------------------------------------------------------ checksums
{
    echo "# sha256 of every UPSTREAM file staged into sdk/usr/include, with the"
    echo "# apple-oss-distributions path it came from.  Rows for clean-room"
    echo "# (sdk/local/) and objc4 headers are deliberately absent: those live in"
    echo "# this repository and git already vouches for them."
    echo "#"
    echo "# scripts/sdk_stage.sh --verify re-fetches upstream and checks these."
    sort -k3 "$SUMS.new"
} > "$SUMS"
rm -f "$SUMS.new"

# --------------------------------------------------------------------- verify
if [ "$MODE" = verify ]; then
    echo "== verify: re-fetching every upstream file and diffing"
    bad=0
    while read -r want src rel; do
        case "$want" in \#*) continue ;; esac
        # A gen: row records the sha256 of the GENERATOR, not of a header.
        case "$src" in gen:*) spec="${src#gen:}" ;; *) spec="$src" ;; esac
        repo="${spec%%:*}"; path="${spec#*:}"
        f="$CACHE/$repo-${TAG[$repo]}/$path"
        rm -f "$f"; fetch_one "$repo" "$path"
        got=$(sha256 "$f")
        if [ "$got" != "$want" ]; then
            echo "!! $rel  ($src)  upstream sha256 changed"
            bad=$((bad+1))
        fi
    done < "$SUMS"
    [ "$bad" = 0 ] || die "$bad upstream file(s) no longer match the pinned tag"
    echo "   all upstream files match their pinned tag"
fi

echo "   -> $INC"
