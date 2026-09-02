#!/bin/bash
# Reproducible WMO census for the exact pinned Blockzilla application target:
# 129 physical Swift sources plus two separately reported generated contracts.
# This deliberately does not use the older broad 182-source saturation row.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SUPPORT=$(cd "$HERE/../.." && pwd)
APP=${APP:-$SUPPORT/scratch/ladder-corpus/focus-ios/focus-ios}
SNAPKIT=${SNAPKIT:-$SUPPORT/scratch/xcodeplan-deps/SnapKit}
UIKIT_SRC=${UIKIT_SRC:-$SUPPORT/uikit}
OUTPUT=''
EXPECTED_SUPPORT_COMMIT=''
EXPECTED_SUPPORT_TREE=''
EXPECTED_UIKIT_COMMIT=''
EXPECTED_UIKIT_TREE=''
BASELINE_PRIMARY=''

die() {
    printf 'build_exact_main_census: REFUSING -- %s\n' "$*" >&2
    exit 2
}

usage() {
    cat <<'EOF'
usage: build_exact_main_census.sh --output-root ABSOLUTE_NEW_PATH \
  --expected-support-commit COMMIT --expected-support-tree TREE \
  [--expected-uikit-commit COMMIT] [--expected-uikit-tree TREE] \
  [--baseline-primary ABSOLUTE_NORMALIZED_TSV]

APP, SNAPKIT, and UIKIT_SRC may override the three read-only checkouts.
UIKIT_SRC defaults to the in-repo uikit/ subtree and is attested by
git rev-parse HEAD:uikit. --expected-uikit-commit is required only for an
external OpenUIKit checkout. Every identity is checked before and after
compilation. The output path must not exist; all modules, package products,
caches, logs, and generated build support are created beneath that one fresh
root.
When --baseline-primary is supplied, the driver emits an exact multiset delta
that preserves duplicate-diagnostic multiplicity.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --output-root) [ "$#" -ge 2 ] || die 'missing output value'; OUTPUT=$2; shift 2 ;;
        --expected-support-commit) [ "$#" -ge 2 ] || die 'missing support commit'; EXPECTED_SUPPORT_COMMIT=$2; shift 2 ;;
        --expected-support-tree) [ "$#" -ge 2 ] || die 'missing support tree'; EXPECTED_SUPPORT_TREE=$2; shift 2 ;;
        --expected-uikit-commit) [ "$#" -ge 2 ] || die 'missing UIKit commit'; EXPECTED_UIKIT_COMMIT=$2; shift 2 ;;
        --expected-uikit-tree) [ "$#" -ge 2 ] || die 'missing UIKit tree'; EXPECTED_UIKIT_TREE=$2; shift 2 ;;
        --baseline-primary) [ "$#" -ge 2 ] || die 'missing baseline path'; BASELINE_PRIMARY=$2; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done

if [ -n "$BASELINE_PRIMARY" ]; then
    case "$BASELINE_PRIMARY" in /*) ;; *) die '--baseline-primary must be absolute' ;; esac
    [ -f "$BASELINE_PRIMARY" ] && [ ! -L "$BASELINE_PRIMARY" ] \
        || die '--baseline-primary must be a regular non-symlink file'
fi

[ -n "$OUTPUT" ] || die '--output-root is required'
case "$OUTPUT" in /*) ;; *) die '--output-root must be absolute' ;; esac
[ ! -e "$OUTPUT" ] && [ ! -L "$OUTPUT" ] || die "output already exists: $OUTPUT"
# shellcheck source=../../scripts/vendor_tree.sh
. "$SUPPORT/scripts/vendor_tree.sh"
[ -z "$EXPECTED_UIKIT_TREE" ] && EXPECTED_UIKIT_TREE=$EXPECTED_INREPO_UIKIT_TREE
for value in "$EXPECTED_SUPPORT_COMMIT" "$EXPECTED_SUPPORT_TREE" \
    "$EXPECTED_UIKIT_TREE"; do
    [ "${#value}" -eq 40 ] || die 'every expected commit/tree must be 40 lowercase hex'
    case "$value" in *[!0-9a-f]*) die 'every expected commit/tree must be 40 lowercase hex' ;; esac
done
if ! vendor_is_inrepo "$SUPPORT" uikit "$UIKIT_SRC"; then
    [ -n "$EXPECTED_UIKIT_COMMIT" ] \
        || die '--expected-uikit-commit is required for an external OpenUIKit checkout'
    [ "${#EXPECTED_UIKIT_COMMIT}" -eq 40 ] \
        || die 'expected UIKit commit must be 40 lowercase hex'
    case "$EXPECTED_UIKIT_COMMIT" in
        *[!0-9a-f]*) die 'expected UIKit commit must be 40 lowercase hex' ;;
    esac
fi
for input in "$SUPPORT" "$APP" "$SNAPKIT" "$UIKIT_SRC"; do
    case "$input" in /*) ;; *) die "input checkout must be absolute: $input" ;; esac
    [ -d "$input" ] && git -C "$input" rev-parse --git-dir >/dev/null 2>&1 \
        || die "input is not inside a Git checkout: $input"
done

export APP SNAPKIT UIKIT_SRC
export CENSUS_SOURCE_MODE=exact-main
export EXPECTED_SUPPORT_COMMIT EXPECTED_SUPPORT_TREE
export EXPECTED_UIKIT_COMMIT EXPECTED_UIKIT_TREE
export BASELINE_PRIMARY
exec bash "$HERE/build_census.sh" "$OUTPUT"
