#!/bin/bash
# Build, compare against official Apple Quartz, record metrics history.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p build output metrics
if [[ ! -f build/CMakeCache.txt ]]; then
  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
fi
cmake --build build -j
./build/qzcompare --out output --suite all "$@"
python3 tools/score.py
