#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
cmake --build build -j
fail=0
for t in build/test_*; do
  [[ -x "$t" && -f "$t" ]] || continue
  echo "== $(basename "$t") =="
  if ! "$t"; then fail=1; fi
done
exit $fail
