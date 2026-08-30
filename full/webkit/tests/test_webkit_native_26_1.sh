#!/bin/bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
EXPECTED_XCODE='Xcode 26.1|Build version 17B55'
EXPECTED_PLATFORM=26.1
EXPECTED_SDK_BUILD=23B77
DEVICE=${WEBKIT_ORACLE_DEVICE:-15E0B30F-6F1B-4F98-AD63-19D5AAFEDCDD}

[ "$(xcodebuild -version | paste -sd '|')" = "$EXPECTED_XCODE" ] || {
    printf 'refusing unpinned Xcode (expected %s)\n' "$EXPECTED_XCODE" >&2
    exit 2
}
[ "$(xcrun --sdk iphonesimulator --show-sdk-platform-version)" = "$EXPECTED_PLATFORM" ]
[ "$(xcrun --sdk iphonesimulator --show-sdk-build-version)" = "$EXPECTED_SDK_BUILD" ]
xcrun simctl list devices | grep -F "$DEVICE" | grep -F '(Booted)' >/dev/null || {
    printf 'pinned simulator is not booted: %s\n' "$DEVICE" >&2
    exit 2
}

OUT=$(mktemp -d /tmp/webkit-native-oracle.XXXXXX)
cleanup() {
    case "$OUT" in
        /tmp/webkit-native-oracle.*|/private/tmp/webkit-native-oracle.*)
            rm -rf -- "$OUT"
            ;;
        *) printf 'refusing unsafe cleanup path: %s\n' "$OUT" >&2 ;;
    esac
}
trap cleanup EXIT

SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun swiftc -parse-as-library -sdk "$SDK" \
    -target arm64-apple-ios26.1-simulator \
    "$HERE/WebKitNativeOracle.swift" -o "$OUT/WebKitNativeOracle"
xcrun simctl spawn "$DEVICE" "$OUT/WebKitNativeOracle" > "$OUT/actual.txt"
cmp "$HERE/webkit-native-xcode-26.1-ios-26.1.txt" "$OUT/actual.txt" || {
    diff -u "$HERE/webkit-native-xcode-26.1-ios-26.1.txt" "$OUT/actual.txt" || true
    printf 'native WebKit oracle drifted\n' >&2
    exit 3
}
printf 'WEBKIT_NATIVE_26_1_OK sdk-build=%s\n' "$EXPECTED_SDK_BUILD"
