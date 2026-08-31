#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
OUTPUT=$(mktemp -d "${TMPDIR:-/tmp}/cryptokit-host.XXXXXX")
trap 'rm -rf "$OUTPUT"' EXIT

swiftc -parse-as-library -module-name CryptoKit \
    -emit-module -emit-module-path "$OUTPUT/CryptoKit.swiftmodule" \
    -emit-library -o "$OUTPUT/libCryptoKit.dylib" \
    "$ROOT/full/cryptokit/CryptoKit.swift"
swiftc -I "$OUTPUT" -L "$OUTPUT" -lCryptoKit \
    -o "$OUTPUT/CryptoKitHostTests" \
    "$ROOT/full/cryptokit/tests/CryptoKitHostTests.swift"
DYLD_LIBRARY_PATH="$OUTPUT${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$OUTPUT/CryptoKitHostTests"
