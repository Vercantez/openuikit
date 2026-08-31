#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
BUTTONKIT=${1:-/private/tmp/icecubes-remote-cache-v3-20260831/objects/sha256/5c/5c1869c1721b4d6875e028a73a2dd9bf40554677a49620123b58ecbf5ed9102b/repository}
SFSAFESYMBOLS=${2:-/private/tmp/icecubes-remote-cache-v3-20260831/objects/sha256/1a/1ac18353e08d7e3c085f1bb9c76e5bdfb159e54bad7beedb2d01465d255c4aee/repository}
EXPECTED_COMMIT=8ea442e22cc396960aba246bf03d967842aeedb9
EXPECTED_APPINTENT_SHA256=2c46aea844dbaf5a03cd8044a716a009a27d339347198d59aa045097729144e3
EXPECTED_SF_COMMIT=e01b3d4f861412f8dcee8d93c417d2c2b0cdfd77
EXPECTED_SF_APPINTENT_SHA256=e6e8cda6372f90957d430acd9a7ec85f84f1578518b83074073ccfb8a75e9339

[ -d "$BUTTONKIT/.git" ] || { echo "missing ButtonKit repository" >&2; exit 2; }
[ "$(git -C "$BUTTONKIT" rev-parse HEAD)" = "$EXPECTED_COMMIT" ] || {
    echo "ButtonKit commit drifted" >&2
    exit 2
}
[ -z "$(git -C "$BUTTONKIT" status --short)" ] || {
    echo "ButtonKit is not untouched" >&2
    exit 2
}
EXACT_SOURCE="$BUTTONKIT/Sources/ButtonKit/Button+AppIntent.swift"
[ "$(shasum -a 256 "$EXACT_SOURCE" | awk '{print $1}')" = "$EXPECTED_APPINTENT_SHA256" ] || {
    echo "Button+AppIntent.swift hash drifted" >&2
    exit 2
}
[ -d "$SFSAFESYMBOLS/.git" ] || { echo "missing SFSafeSymbols repository" >&2; exit 2; }
[ "$(git -C "$SFSAFESYMBOLS" rev-parse HEAD)" = "$EXPECTED_SF_COMMIT" ] || {
    echo "SFSafeSymbols commit drifted" >&2
    exit 2
}
[ -z "$(git -C "$SFSAFESYMBOLS" status --short)" ] || {
    echo "SFSafeSymbols is not untouched" >&2
    exit 2
}
SF_EXACT_SOURCE="$SFSAFESYMBOLS/Sources/SFSafeSymbols/Initializers/AppIntents/DisplayRepresentationImage+SFSymbol.swift"
[ "$(shasum -a 256 "$SF_EXACT_SOURCE" | awk '{print $1}')" = "$EXPECTED_SF_APPINTENT_SHA256" ] || {
    echo "SFSafeSymbols AppIntents source hash drifted" >&2
    exit 2
}

TMP=$(mktemp -d /private/tmp/appintents-host-proof.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

swiftc -parse-as-library -module-name AppIntents \
    -emit-module -emit-module-path "$TMP/AppIntents.swiftmodule" \
    -emit-library -o "$TMP/libAppIntents.dylib" \
    "$ROOT/full/appintents/AppIntents.swift"

swiftc -parse-as-library -I "$TMP" -L "$TMP" -lAppIntents \
    "$ROOT/full/appintents/tests/AppIntentsHostRuntime.swift" \
    -o "$TMP/appintents-host-runtime"
DYLD_LIBRARY_PATH="$TMP" "$TMP/appintents-host-runtime" \
    | grep -Fxq 'APPINTENTS_HOST_RUNTIME_OK execution=1 shortcuts=2 system-registration=unavailable'

# This is the untouched file that stopped the exact production build.  The
# parse/typecheck deliberately runs after our module shadows Apple's module.
# ButtonKit's remaining declarations are supplied by its other untouched files.
mapfile -t BUTTONKIT_SOURCES < <(find "$BUTTONKIT/Sources/ButtonKit" \
    -type f -name '*.swift' -print | LC_ALL=C sort)
swiftc -parse-as-library -suppress-warnings -typecheck -I "$TMP" \
    "${BUTTONKIT_SOURCES[@]}"

mapfile -t SFSAFESYMBOLS_SOURCES < <(find "$SFSAFESYMBOLS/Sources/SFSafeSymbols" \
    -type f -name '*.swift' \
    ! -path '*/Initializers/SwiftUI/Button+SFSymbol.swift' \
    -print | LC_ALL=C sort)
# The one excluded source consumes SwiftUI's AppIntent-specific Button
# initializer rather than an AppIntents declaration. It is intentionally left
# to the SwiftUI lane; the exact AppIntents DisplayRepresentation consumer is
# compiled here with every other SFSafeSymbols production source.
swiftc -parse-as-library -suppress-warnings -typecheck -I "$TMP" \
    "${SFSAFESYMBOLS_SOURCES[@]}"

printf 'APPINTENTS_EXACT_CONSUMERS_OK buttonkit=%s:%s:%s sfsafesymbols=%s:%s:%s\n' \
    "$EXPECTED_COMMIT" "$EXPECTED_APPINTENT_SHA256" "${#BUTTONKIT_SOURCES[@]}" \
    "$EXPECTED_SF_COMMIT" "$EXPECTED_SF_APPINTENT_SHA256" "${#SFSAFESYMBOLS_SOURCES[@]}"
