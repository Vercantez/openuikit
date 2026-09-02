#!/bin/bash
# vendor_quartz.sh -- (re)stage vendor/quartz from the upstream ~/quartz tree.
#
#   scripts/vendor_quartz.sh            copy upstream -> vendor/quartz, rewrite CHECKSUMS
#   scripts/vendor_quartz.sh --verify   check the COMMITTED checksums against
#                                       vendor/quartz as it stands in this repo
#   scripts/vendor_quartz.sh --diff     diff vendor/quartz against upstream
#
# Same arrangement as vendor/objc4: the vendored tree is PRISTINE. Every change
# needed to build it as a Mach-O dylib on Linux lives in patches-quartz/ and is
# applied to a COPY at build time (scripts/build_quartz.sh). That is what makes
# "how many patches?" a number rather than an opinion.
#
# WHY ONLY THREE DIRECTORIES. Upstream ~/quartz also carries harness/, demo/,
# tests/, scenes/, tools/ and metrics/. Every one of those is macOS-only by
# construction -- the harness links -framework CoreGraphics/QuartzCore because
# its whole job is to render each scene through Apple's frameworks AND through
# quartz and pixel-diff the two. None of it is part of libquartz, and vendoring
# it here would import an Apple-framework dependency into a tree that has none.
# The library itself is include/ + src/ + third_party/ and nothing else; the
# upstream CMakeLists.txt's `add_library(quartz STATIC ...)` target says so.
#
# UPSTREAM IS NOT A GIT REPOSITORY (checked: ~/quartz has no .git). There is no
# commit to pin, so provenance is pinned the only way it can be: the sha256 of
# every file, recorded in vendor/quartz/CHECKSUMS.sha256, plus the upstream
# absolute path and the staging date in vendor/quartz/PROVENANCE.md. --verify
# treats that record as read-only and dies with a diff, exactly as
# scripts/sdk_stage.sh --verify does (and for the reason its header gives: a
# verifier that rewrites the thing it verifies cannot fail).
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
UP="${QUARTZ_SRC:-$HOME/quartz}"
DST="$ROOT/vendor/quartz"
SUMS="$DST/CHECKSUMS.sha256"

# The library, and only the library.
DIRS=(include src third_party)

MODE=stage
case "${1:---}" in
    --verify) MODE=verify ;;
    --diff)   MODE=diff ;;
    --)       ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "vendor_quartz: unknown option $1" >&2; exit 64 ;;
esac

die() { echo "vendor_quartz: $*" >&2; exit 1; }

# LC_ALL=C on every sort. scripts/sdk_stage.sh learned this the hard way: a
# locale-dependent sort made the committed record non-reproducible across
# machines (18 rows moved, not one hash changed).
export LC_ALL=C

sums_of() { # sums_of <root-dir>  -- "sha256  relpath" for every file, sorted
    local d="$1" f
    ( cd "$d" && find "${DIRS[@]}" -type f -print0 2>/dev/null | sort -z |
      xargs -0 shasum -a 256 2>/dev/null ) |
      sed 's#  \./#  #' | sort -k2
}

case "$MODE" in
verify)
    [ -f "$SUMS" ] || die "no $SUMS -- stage first"
    got=$(sums_of "$DST")
    if ! diff <(grep -v '^#' "$SUMS") <(printf '%s\n' "$got") ; then
        die "vendor/quartz does not match its committed CHECKSUMS.sha256"
    fi
    echo "vendor_quartz: $(grep -vc '^#' "$SUMS") files match CHECKSUMS.sha256"
    ;;
diff)
    [ -d "$UP" ] || die "no upstream tree at $UP (set QUARTZ_SRC)"
    for d in "${DIRS[@]}"; do
        diff -ru "$DST/$d" "$UP/$d" || true
    done
    ;;
stage)
    [ -d "$UP" ] || die "no upstream tree at $UP (set QUARTZ_SRC)"
    for d in "${DIRS[@]}"; do
        [ -d "$UP/$d" ] || die "$UP/$d does not exist"
    done
    # Remove the VENDORED DIRECTORIES ONLY, never $DST itself: PROVENANCE.md
    # lives beside them and is ours, not upstream's.
    mkdir -p "$DST"
    for d in "${DIRS[@]}"; do
        rm -rf "${DST:?}/$d"
        cp -R "$UP/$d" "$DST/$d"
    done
    # No build products, no editor droppings.
    find "$DST" -name '.DS_Store' -delete

    {
        echo "# vendor/quartz -- sha256 of every vendored file."
        echo "# Regenerate with scripts/vendor_quartz.sh; check with --verify."
        echo "# Upstream: $UP  (not a git repository; no commit to pin)"
        echo "# Staged:   $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        sums_of "$DST"
    } > "$SUMS"

    n=$(grep -vc '^#' "$SUMS")
    echo "vendor_quartz: staged $n files from $UP into vendor/quartz"
    ;;
esac
