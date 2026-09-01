#!/usr/bin/env bash
# Runs inside the pinned Linux/arm64 toolchain image. The host wrapper has
# already constructed a private target SDK by overlaying the iOS-simulator
# standard-library interfaces and TBDs on the core package SDK.

set -euo pipefail

OUTPUT=${1:?output root is required}
PACKAGE=${2:?core package root is required}
TARGET=arm64-apple-ios17.0-simulator
MINIMUM_OS=17.0
SDK_VERSION=26.1
MODULE_CACHE=$OUTPUT/module-cache
OBJECT=$OUTPUT/TrueIOSTargetProbe.o
EXECUTABLE=$OUTPUT/TrueIOSTargetProbe

mkdir -p "$MODULE_CACHE" "$OUTPUT/attestation"

swiftc --version | tee "$OUTPUT/attestation/swift-toolchain.txt"
swiftc -target "$TARGET" -sdk "$OUTPUT/sdk" \
    -module-cache-path "$MODULE_CACHE" \
    -runtime-compatibility-version none \
    -parse-as-library -emit-object \
    "$OUTPUT/TrueIOSTargetProbe.swift" -o "$OBJECT" \
    2>&1 | tee "$OUTPUT/attestation/compile.log"

ld64.lld-18 -arch arm64 \
    -platform_version ios-simulator "$MINIMUM_OS" "$SDK_VERSION" \
    -syslibroot "$OUTPUT/sdk" \
    -rpath /usr/lib/swift -rpath @loader_path \
    -dead_strip -exported_symbol __mh_execute_header \
    -L"$OUTPUT/sdk/usr/lib/swift" -lswiftCore \
    -L"$OUTPUT/sdk/usr/lib" -lSystem \
    -o "$EXECUTABLE" "$OBJECT" \
    2>&1 | tee "$OUTPUT/attestation/link.log"

file "$OBJECT" "$EXECUTABLE" \
    | tee "$OUTPUT/attestation/file-types.txt"
llvm-otool-18 -L "$EXECUTABLE" \
    | tee "$OUTPUT/attestation/dylib-loads.txt"
llvm-otool-18 -l "$EXECUTABLE" \
    | tee "$OUTPUT/attestation/load-commands.txt"

grep -Fq 'platform 7' "$OUTPUT/attestation/load-commands.txt"
grep -Fq 'minos 17.0' "$OUTPUT/attestation/load-commands.txt"
grep -Fq '/usr/lib/swift/libswiftCore.dylib' \
    "$OUTPUT/attestation/dylib-loads.txt"
grep -Fq '/usr/lib/libSystem.B.dylib' \
    "$OUTPUT/attestation/dylib-loads.txt"

for helper in libOpenDispatchHost.so \
    libOpenFoundationInternationalizationHost.so \
    libOpenURLTransportHost.so libOpenRelativeTimeHost.so; do
    test -f "$PACKAGE/guest-root/host/$helper"
done

(
    cd "$OUTPUT"
    LD_LIBRARY_PATH="$PACKAGE/guest-root/host" \
    LD_PRELOAD="$PACKAGE/guest-root/host/libOpenDispatchHost.so:$PACKAGE/guest-root/host/libOpenFoundationInternationalizationHost.so:$PACKAGE/guest-root/host/libOpenURLTransportHost.so:$PACKAGE/guest-root/host/libOpenRelativeTimeHost.so" \
    MACHORUN_ROOT="$PACKAGE/guest-root" \
        "$PACKAGE/guest-root/machorun" ./TrueIOSTargetProbe
) | tee "$OUTPUT/attestation/runtime.log"

grep -Fxq \
    'TRUE_IOS_TRIPLE_GUEST_OK os=iOS target=arm64-apple-ios-simulator' \
    "$OUTPUT/attestation/runtime.log"

sha256sum "$OBJECT" "$EXECUTABLE" \
    > "$OUTPUT/attestation/products.sha256"
