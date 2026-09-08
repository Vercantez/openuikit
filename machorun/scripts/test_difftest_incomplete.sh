#!/bin/bash
# Old captures must not turn an interrupted run (empty .status) green.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/linux"
# Give the grader byte-matching captures so ONLY run status can reject them.
for suffix in exit stdout stderr; do
    cp "$ROOT/tests/expected/main_ret.$suffix" "$TMP/linux/main_ret.$suffix"
done
: > "$TMP/linux/.status"
rc=0
ACTUAL_DIR="$TMP" bash "$ROOT/scripts/difftest.sh" --no-run --no-verify main_ret \
    > "$TMP/report" 2>&1 || rc=$?
[ "$rc" = 2 ] || { cat "$TMP/report"; echo "FAIL: expected exit 2, got $rc"; exit 1; }
grep -q 'did not complete (empty status)' "$TMP/report"
grep -q 'pass 0  fail 0  xfail 0  xpass 0  skipped 1' "$TMP/report"
echo 'PASS -- empty run status refuses matching leftover captures (exit 2)'
