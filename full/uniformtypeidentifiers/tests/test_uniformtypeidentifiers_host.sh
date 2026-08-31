#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
OUTPUT=$(mktemp -d "${TMPDIR:-/tmp}/uniformtypeidentifiers-host.XXXXXX")
trap 'rm -rf "$OUTPUT"' EXIT

swiftc -parse-as-library -module-name UniformTypeIdentifiers \
    -emit-module -emit-module-path "$OUTPUT/UniformTypeIdentifiers.swiftmodule" \
    -emit-library -o "$OUTPUT/libUniformTypeIdentifiers.dylib" \
    "$ROOT/full/uniformtypeidentifiers/UniformTypeIdentifiers.swift"
swiftc -I "$OUTPUT" -L "$OUTPUT" -lUniformTypeIdentifiers \
    -o "$OUTPUT/UniformTypeIdentifiersHostTests" \
    "$ROOT/full/uniformtypeidentifiers/tests/UniformTypeIdentifiersHostTests.swift"
DYLD_LIBRARY_PATH="$OUTPUT${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$OUTPUT/UniformTypeIdentifiersHostTests"
