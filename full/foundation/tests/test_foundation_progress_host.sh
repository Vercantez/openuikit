#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
WORK=$(mktemp -d "${TMPDIR:-/private/tmp}/foundation-progress.XXXXXX")
cleanup() {
    if command -v trash >/dev/null 2>&1; then trash "$WORK"; else rm -rf -- "$WORK"; fi
}
trap cleanup EXIT

xcrun swiftc "$ROOT/full/oracle-progress/ProgressOracle.swift" \
    -o "$WORK/apple-oracle"
"$WORK/apple-oracle" > "$WORK/apple-oracle.txt"
cmp "$ROOT/full/oracle-progress/progress-apple-2026-08-31.txt" \
    "$WORK/apple-oracle.txt"

xcrun swiftc -D FOUNDATION_PROGRESS_HOST -parse-as-library -wmo \
    -module-name FoundationProgressPortable \
    -emit-module -emit-module-path "$WORK/FoundationProgressPortable.swiftmodule" \
    -emit-object -o "$WORK/FoundationProgressPortable.o" \
    "$ROOT/full/foundation/Progress.swift"
xcrun swiftc -parse-as-library -I "$WORK" \
    "$ROOT/full/foundation/tests/FoundationProgressRuntime.swift" \
    "$WORK/FoundationProgressPortable.o" -o "$WORK/runtime"
"$WORK/runtime" | tee "$WORK/runtime.log"
grep -Fx \
    'FOUNDATION_PROGRESS_HOST_OK fraction=initial-prior-new kvo=typed-invalidated states=cancel-pause-finish' \
    "$WORK/runtime.log" >/dev/null
