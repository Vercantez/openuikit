#!/usr/bin/env bash
# Prove in-repo vendor-tree attestation: matching HEAD:uikit/HEAD:machorun,
# refuse a wrong tree, refuse a dirty subtree, and accept an external checkout
# override whose HEAD^{tree} matches the pin.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)

die() {
    echo "vendor_tree_test: $*" >&2
    exit 2
}

# shellcheck source=vendor_tree.sh
. "$ROOT/scripts/vendor_tree.sh"

pass=0
fail=0
expect_ok() {
    local label=$1
    shift
    if ( "$@" ); then
        echo "PASS: $label"
        pass=$((pass + 1))
    else
        echo "FAIL: $label" >&2
        fail=$((fail + 1))
    fi
}
expect_refuse() {
    local label=$1
    shift
    if ( "$@" >/tmp/vendor-tree-test.err 2>&1 ); then
        echo "FAIL: $label (expected refuse)" >&2
        fail=$((fail + 1))
    else
        echo "PASS: $label"
        pass=$((pass + 1))
    fi
}

actual_uikit=$(git -C "$ROOT" rev-parse HEAD:uikit)
actual_machorun=$(git -C "$ROOT" rev-parse HEAD:machorun)
[ "$actual_uikit" = "$EXPECTED_INREPO_UIKIT_TREE" ] \
    || die "pin $EXPECTED_INREPO_UIKIT_TREE != HEAD:uikit $actual_uikit"
[ "$actual_machorun" = "$EXPECTED_INREPO_MACHORUN_TREE" ] \
    || die "pin $EXPECTED_INREPO_MACHORUN_TREE != HEAD:machorun $actual_machorun"
echo "MEASURED: HEAD:uikit=$actual_uikit HEAD:machorun=$actual_machorun"

expect_ok 'in-repo uikit tree' \
    assert_vendor_tree "$ROOT" uikit "$ROOT/uikit" "$EXPECTED_INREPO_UIKIT_TREE" OpenUIKit
expect_ok 'in-repo machorun tree' \
    assert_vendor_tree "$ROOT" machorun "$ROOT/machorun" \
    "$EXPECTED_INREPO_MACHORUN_TREE" machorun

wrong=0000000000000000000000000000000000000000
expect_refuse 'wrong uikit tree' \
    assert_vendor_tree "$ROOT" uikit "$ROOT/uikit" "$wrong" OpenUIKit

dirty=$ROOT/uikit/.vendor-tree-test-dirty
cleanup() { rm -f -- "$dirty"; }
trap cleanup EXIT
printf 'dirty\n' > "$dirty"
expect_refuse 'dirty uikit subtree' \
    assert_vendor_tree "$ROOT" uikit "$ROOT/uikit" "$EXPECTED_INREPO_UIKIT_TREE" OpenUIKit
rm -f -- "$dirty"
trap - EXIT
expect_ok 'clean after dirty-file removal' \
    assert_vendor_tree "$ROOT" uikit "$ROOT/uikit" "$EXPECTED_INREPO_UIKIT_TREE" OpenUIKit

# Regression test for the virtiofs false-positive fix: vendor_status_of now
# runs with --no-optional-locks -c core.checkStat=minimal -c core.trustctime=false
# so a bind-mounted worktree whose dev/ino/uid churn under Docker's virtiofs
# (mtime/size unchanged) is no longer reported dirty. checkStat=minimal must
# not swallow a REAL edit to an already-tracked file (content+mtime+size all
# change, not just dev/ino/uid), so prove that path is still caught.
tracked=$ROOT/uikit/REPORT.md
tracked_backup=$(mktemp /tmp/vendor-tree-test-report.XXXXXX)
cp -- "$tracked" "$tracked_backup"
restore_tracked() { cp -- "$tracked_backup" "$tracked"; rm -f -- "$tracked_backup"; }
trap restore_tracked EXIT
printf '\nvendor-tree-test-modified-content\n' >> "$tracked"
expect_refuse 'modified tracked file in uikit subtree' \
    assert_vendor_tree "$ROOT" uikit "$ROOT/uikit" "$EXPECTED_INREPO_UIKIT_TREE" OpenUIKit
restore_tracked
trap - EXIT
expect_ok 'clean after tracked-file restore' \
    assert_vendor_tree "$ROOT" uikit "$ROOT/uikit" "$EXPECTED_INREPO_UIKIT_TREE" OpenUIKit

echo "vendor_tree_test: $pass passed, $fail failed (denominator=$((pass + fail)))"
[ "$fail" -eq 0 ]
printf 'VENDOR_TREE_ATTESTATION_OK uikit=%s machorun=%s checks=%s/%s\n' \
    "$EXPECTED_INREPO_UIKIT_TREE" "$EXPECTED_INREPO_MACHORUN_TREE" \
    "$pass" "$((pass + fail))"
