#!/bin/bash
# Regression for the exact ignored-source provenance failure found in review.
# It clones only the pinned upstream checkout, injects a source hidden by the
# upstream repo's checked-in **/.build* ignore rule, and requires the production
# manifest tool to reject it while ordinary status still reports clean.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
TOOL=$ROOT/full/foundation/pinned_inputs.pl
SF=${SWIFT_FOUNDATION_CHECKOUT:-$ROOT/scratch/swift-foundation}
SC=${SWIFT_COLLECTIONS_CHECKOUT:-$ROOT/scratch/swift-collections}

perl "$TOOL" verify --swift-foundation "$SF" --swift-collections "$SC" >/dev/null

TMP=$(mktemp -d "${TMPDIR:-/tmp}/pinned-inputs-guard.XXXXXX")
cleanup() { rm -rf -- "$TMP"; }
trap cleanup EXIT
git clone --quiet --no-hardlinks "$SF" "$TMP/swift-foundation"
mkdir -p "$TMP/swift-foundation/Sources/FoundationEssentials/.build-review"
printf 'public enum IgnoredInjectedSource {}\n' \
    >"$TMP/swift-foundation/Sources/FoundationEssentials/.build-review/Injected.swift"

[ -z "$(git -C "$TMP/swift-foundation" status --porcelain=v1 --untracked-files=all)" ] || {
    echo "test setup failed: ordinary status unexpectedly sees ignored source" >&2
    exit 1
}

set +e
output=$(perl "$TOOL" verify \
    --swift-foundation "$TMP/swift-foundation" \
    --swift-collections "$SC" 2>&1)
status=$?
set -e
[ "$status" -eq 2 ] || {
    echo "ignored source was not rejected (status=$status): $output" >&2
    exit 1
}
printf '%s\n' "$output" | grep -F 'tracked/untracked/ignored drift' >/dev/null || {
    echo "ignored-source rejection lacked the expected diagnostic: $output" >&2
    exit 1
}
echo "PINNED_INPUTS_IGNORED_SOURCE_REJECTED"
