#!/bin/bash
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)
BUILD=$(mktemp -d /private/tmp/libsystem-math-compat.XXXXXX)
trap 'rm -rf "$BUILD"' EXIT
SDK=$(xcrun --sdk macosx --show-sdk-path)
COMMON=(-std=c11 -O2 -Wall -Wextra -Werror -fno-builtin-nan -fno-builtin-remquo)

xcrun clang "${COMMON[@]}" \
    "$ROOT/full/shims/tests/LibSystemMathTranscript.c" \
    -o "$BUILD/apple-oracle"
"$BUILD/apple-oracle" > "$BUILD/apple.txt"

xcrun clang "${COMMON[@]}" \
    "$ROOT/full/shims/libsystem_math_compat.c" \
    "$ROOT/full/shims/tests/LibSystemMathTranscript.c" \
    -o "$BUILD/portable"
"$BUILD/portable" > "$BUILD/portable.txt"
cmp "$BUILD/apple.txt" "$BUILD/portable.txt"

xcrun clang -target arm64-apple-macos15.0 -isysroot "$SDK" \
    "${COMMON[@]}" -c "$ROOT/full/shims/libsystem_math_compat.c" \
    -o "$BUILD/libsystem-math-arm64.o"
for binary in "$BUILD/portable" "$BUILD/libsystem-math-arm64.o"; do
    for symbol in _nan _remquo; do
        count=$(xcrun llvm-nm --defined-only --extern-only --just-symbol-name \
            "$binary" | awk -v wanted="$symbol" \
            '$0 == wanted { count++ } END { print count + 0 }')
        [ "$count" -eq 1 ] || {
            printf 'libsystem-math-compat: %s definition count %s in %s\n' \
                "$symbol" "$count" "$binary" >&2
            exit 1
        }
    done
done

rows=$(wc -l < "$BUILD/portable.txt" | tr -d '[:space:]')
[ "$rows" -eq 150 ]
printf '%s\n' \
    'LIBSYSTEM_MATH_COMPAT_HOST_OK symbols=nan,remquo apple-differential=150 quotient-bits=7 nan-tags=decimal,octal,hex,fail-closed'
