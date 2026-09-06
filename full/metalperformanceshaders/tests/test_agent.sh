#!/usr/bin/env bash
set -euo pipefail
FRAMEWORK_ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/mps-agent-tests.XXXXXX")
trap 'rm -rf -- "$TMP"' EXIT HUP INT TERM
mapfile -t SOURCES < "$FRAMEWORK_ROOT/metalperformanceshaders_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do SOURCE_PATHS+=("$REPO_ROOT/$relative"); done
swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name MetalPerformanceShaders \
    -emit-module-path "$TMP/MetalPerformanceShaders.swiftmodule" \
    -o "$TMP/libMetalPerformanceShaders.dylib" "${SOURCE_PATHS[@]}"
# Run every synchronous focused probe, including the earlier depth passes.
python3 -B - "$FRAMEWORK_ROOT" "$TMP/main.swift" <<'PY'
from pathlib import Path
import re
import sys
root, output = map(Path, sys.argv[1:])
tests = []
for path in sorted((root / 'tests/agent').glob('*Tests.swift')):
    tests.extend(re.findall(r'^func (test\w+)\(\) \{', path.read_text(), re.M))
assert tests and len(tests) == len(set(tests))
output.write_text('import Foundation\n' + '\n'.join(
    f'print("RUN {name}"); {name}()' for name in tests
) + f'\nprint("MPS_FOCUSED_TESTS_OK count={len(tests)}")\n')
PY
swiftc -warnings-as-errors -I "$TMP" "$FRAMEWORK_ROOT"/tests/agent/*Tests.swift \
    "$TMP/main.swift" "$TMP/libMetalPerformanceShaders.dylib" -o "$TMP/agent-tests"
LD_LIBRARY_PATH="$TMP${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$TMP/agent-tests"
