#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
OUTPUT=$(mktemp -d "${TMPDIR:-/tmp}/cryptokit-host.XXXXXX")
trap 'rm -rf "$OUTPUT"' EXIT

mapfile -t SOURCES < "$ROOT/full/cryptokit/cryptokit_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$ROOT/$relative")
done

swiftc -parse-as-library -module-name CryptoKit \
    -emit-module -emit-module-path "$OUTPUT/CryptoKit.swiftmodule" \
    -emit-library -o "$OUTPUT/libCryptoKit.dylib" \
    "${SOURCE_PATHS[@]}"
swiftc -I "$OUTPUT" \
    -o "$OUTPUT/CryptoKitHostTests" \
    "$ROOT/full/cryptokit/tests/CryptoKitHostTests.swift" \
    "$OUTPUT/libCryptoKit.dylib"
DYLD_LIBRARY_PATH="$OUTPUT${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
LD_LIBRARY_PATH="$OUTPUT${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$OUTPUT/CryptoKitHostTests"
