#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
OUTPUT=$(mktemp -d "${TMPDIR:-/tmp}/commoncrypto-host.XXXXXX")
trap 'rm -rf "$OUTPUT"' EXIT

clang -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$ROOT/full/commoncrypto/include" \
    "$ROOT/full/commoncrypto/CommonDigest.c" \
    "$ROOT/full/commoncrypto/tests/CommonCryptoHostTests.c" \
    -o "$OUTPUT/CommonCryptoHostTests"
"$OUTPUT/CommonCryptoHostTests"
