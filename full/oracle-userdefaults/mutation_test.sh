#!/bin/bash
# TEETH IN THE OTHER DIRECTION: prove the PORT scoreboard can FAIL.
#
#   full/oracle-userdefaults/mutation_test.sh
#
# `port 627/627` on its own does not show the oracle detects anything — a board
# that cannot fail is not evidence. Each mutation below removes ONE of the
# deliberate deviations from upstream and rebuilds. The PORT board must DROP.
#
# A mutation that changes nothing means that correction is not load-bearing and
# the rows meant to cover it do not actually reach it — report it rather than
# quietly enjoying a clean run. Every mutation is also checked for having
# APPLIED at all: a perl expression that silently matches nothing would produce
# an identical file, rebuild, score 627/627, and read as "the correction does
# not matter" when the truth is that the test never ran.
#
# Mutations are applied to a COPY. The port source is never modified.
set -uo pipefail

SRC=${PORT_SRC:-$HOME/foundation-macho/src/overlay/UserDefaults.swift}
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${1:-${TMPDIR:-/tmp}/ud-mutation}
mkdir -p "$WORK"

if [ ! -f "$SRC" ]; then echo "FATAL: no port source at $SRC" >&2; exit 2; fi

# The unmutated baseline, so "dropped" is measured against a number from this
# same run rather than one remembered from another.
echo "==> baseline (unmutated)"
PORT_SRC="$SRC" "$HERE/build_ud_host.sh" "$WORK/base" >/dev/null 2>&1 || {
  echo "FATAL: baseline build failed" >&2; exit 2; }
BASE=$("$WORK/base/ud_runner" score 2>&1 | grep -E '^PORT ' | grep -oE 'fail [0-9]+' | grep -oE '[0-9]+')
echo "    baseline PORT failures: $BASE"
if [ "${BASE:-1}" -ne 0 ]; then
  echo "    *** baseline is not clean; fix that before mutation-testing ***" >&2
  exit 3
fi

pass=0; vacuous=0; undetected=0

mutate () {
  local name=$1 expr=$2
  cp "$SRC" "$WORK/UserDefaults.swift"
  perl -0pi -e "$expr" "$WORK/UserDefaults.swift"
  if cmp -s "$SRC" "$WORK/UserDefaults.swift"; then
    printf '  %-38s VACUOUS — the mutation did not apply\n' "$name"
    vacuous=$((vacuous+1)); return
  fi
  if ! PORT_SRC="$WORK/UserDefaults.swift" "$HERE/build_ud_host.sh" "$WORK/out" >/dev/null 2>&1; then
    printf '  %-38s build failed (counts as detected: it cannot ship)\n' "$name"
    pass=$((pass+1)); return
  fi
  local f
  f=$("$WORK/out/ud_runner" score 2>&1 | grep -E '^PORT ' | grep -oE 'fail [0-9]+' | grep -oE '[0-9]+')
  if [ "${f:-0}" -gt 0 ]; then
    printf '  %-38s DETECTED — PORT fail %s (baseline %s)\n' "$name" "$f" "$BASE"
    pass=$((pass+1))
  else
    printf '  %-38s NOT DETECTED — board still clean\n' "$name"
    undetected=$((undetected+1))
  fi
}

echo
echo "==> mutations (each removes one deviation-from-upstream)"

mutate "bool: revert to nonzero-int" \
 's/if s == "1" \{ return true \}\n        let l = s\.lowercased\(\)\n        return l == "yes" \|\| l == "true"/return _cfIntValue(s) != 0/s'

mutate "integer: remove the Int32 clamp" \
 's/if signed > Int64\(Int32\.max\) \{ return Int32\.max \}\n        if signed < Int64\(Int32\.min\) \{ return Int32\.min \}\n        return Int32\(signed\)/return Int32(truncatingIfNeeded: signed)/s'

mutate "integer: allow trailing junk" \
 's/guard i == end else \{ return 0 \}/\/\/ prefix parse (upstream-ish)/s'

mutate "string(Double): Swift description" \
 's/String\(format: "%0\.16g", v\)/String(v)/s'

echo
echo "detected $pass · not detected $undetected · vacuous $vacuous"
if [ "$undetected" -gt 0 ] || [ "$vacuous" -gt 0 ]; then
  echo "FAIL: a correction the oracle cannot see removed is a correction the"
  echo "      oracle is not testing."
  exit 1
fi
echo "PASS: every deviation is load-bearing and the oracle detects its removal."
