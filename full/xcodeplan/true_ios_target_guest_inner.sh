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
MODULES=$OUTPUT/modules
OBJECT=$OUTPUT/TrueIOSTargetProbe.o
EXECUTABLE=$OUTPUT/TrueIOSTargetProbe

mkdir -p "$MODULE_CACHE" "$MODULES" "$OUTPUT/attestation"

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
    > "$OUTPUT/attestation/load-commands.txt"

grep -Fq 'platform 7' "$OUTPUT/attestation/load-commands.txt"
grep -Fq 'minos 17.0' "$OUTPUT/attestation/load-commands.txt"
grep -Fq '/usr/lib/swift/libswiftCore.dylib' \
    "$OUTPUT/attestation/dylib-loads.txt"
grep -Fq '/usr/lib/libSystem.B.dylib' \
    "$OUTPUT/attestation/dylib-loads.txt"

echo '== build the first true-iOS portable framework slice: os + OSLog'
swiftc -target "$TARGET" -sdk "$OUTPUT/sdk" \
    -module-cache-path "$MODULE_CACHE" \
    -module-name os -wmo -parse-as-library \
    -runtime-compatibility-version none \
    -emit-module -emit-module-path "$MODULES/os.swiftmodule" \
    -emit-object -o "$OUTPUT/os.o" "$OUTPUT/inputs/os.swift"
ld64.lld-18 -dylib -arch arm64 \
    -platform_version ios-simulator "$MINIMUM_OS" "$SDK_VERSION" \
    -syslibroot "$OUTPUT/sdk" \
    -install_name @rpath/libosPortable.dylib -rpath @loader_path \
    -dead_strip \
    -L"$OUTPUT/sdk/usr/lib/swift" \
    -lswiftCore -lswiftDarwin -lswiftObjectiveC \
    -L"$OUTPUT/sdk/usr/lib" -lSystem -lobjc \
    -o "$OUTPUT/libosPortable.dylib" "$OUTPUT/os.o"

swiftc -target "$TARGET" -sdk "$OUTPUT/sdk" \
    -module-cache-path "$MODULE_CACHE" -I "$MODULES" \
    -module-name OSLog -wmo -parse-as-library \
    -runtime-compatibility-version none \
    -emit-module -emit-module-path "$MODULES/OSLog.swiftmodule" \
    -emit-object -o "$OUTPUT/OSLog.o" "$OUTPUT/inputs/OSLog.swift"
ld64.lld-18 -dylib -arch arm64 \
    -platform_version ios-simulator "$MINIMUM_OS" "$SDK_VERSION" \
    -syslibroot "$OUTPUT/sdk" \
    -install_name @rpath/libOSLog.dylib -rpath @loader_path \
    -dead_strip \
    -L"$OUTPUT/sdk/usr/lib/swift" -lswiftCore \
    -L"$OUTPUT/sdk/usr/lib" -lSystem \
    -o "$OUTPUT/libOSLog.dylib" "$OUTPUT/OSLog.o" \
    -reexport_library "$OUTPUT/libosPortable.dylib"

swiftc -target "$TARGET" -sdk "$OUTPUT/sdk" \
    -module-cache-path "$MODULE_CACHE" -I "$MODULES" \
    -module-name TrueIOSOSLogRuntime -parse-as-library \
    -runtime-compatibility-version none \
    -emit-object -o "$OUTPUT/TrueIOSOSLogRuntime.o" \
    "$OUTPUT/inputs/OSLogGuestRuntime.swift"
ld64.lld-18 -arch arm64 \
    -platform_version ios-simulator "$MINIMUM_OS" "$SDK_VERSION" \
    -syslibroot "$OUTPUT/sdk" \
    -rpath @loader_path -rpath /usr/lib/swift \
    -dead_strip -exported_symbol __mh_execute_header \
    -L"$OUTPUT" -lOSLog -losPortable \
    -L"$OUTPUT/sdk/usr/lib/swift" -lswiftCore \
    -L"$OUTPUT/sdk/usr/lib" -lSystem \
    -o "$OUTPUT/TrueIOSOSLogRuntime" "$OUTPUT/TrueIOSOSLogRuntime.o"

: > "$OUTPUT/attestation/framework-load-commands.txt"
for product in libosPortable.dylib libOSLog.dylib TrueIOSOSLogRuntime; do
    PRODUCT_LOADS="$OUTPUT/attestation/$product.load-commands.txt"
    llvm-otool-18 -l "$OUTPUT/$product" > "$PRODUCT_LOADS"
    {
        printf 'product\t%s\n' "$product"
        cat "$PRODUCT_LOADS"
    } >> "$OUTPUT/attestation/framework-load-commands.txt"
    grep -Fq 'platform 7' "$PRODUCT_LOADS"
done
llvm-otool-18 -L "$OUTPUT/libOSLog.dylib" \
    | tee "$OUTPUT/attestation/oslog-dylib-loads.txt"
grep -Fq '@rpath/libosPortable.dylib' \
    "$OUTPUT/attestation/oslog-dylib-loads.txt"

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

(
    cd "$OUTPUT"
    LD_LIBRARY_PATH="$PACKAGE/guest-root/host" \
    LD_PRELOAD="$PACKAGE/guest-root/host/libOpenDispatchHost.so:$PACKAGE/guest-root/host/libOpenFoundationInternationalizationHost.so:$PACKAGE/guest-root/host/libOpenURLTransportHost.so:$PACKAGE/guest-root/host/libOpenRelativeTimeHost.so" \
    MACHORUN_ROOT="$PACKAGE/guest-root" \
        "$PACKAGE/guest-root/machorun" ./TrueIOSOSLogRuntime
) 2>&1 | tee "$OUTPUT/attestation/oslog-runtime.log"
grep -Fq '[info] OpenUIKit.OSLogGuestRuntime:Standalone' \
    "$OUTPUT/attestation/oslog-runtime.log"
grep -Fq '[signpost-event] OpenUIKit.OSLogGuestRuntime:Standalone' \
    "$OUTPUT/attestation/oslog-runtime.log"
grep -Fxq \
    'OSLOG_GUEST_MACHO_OK backend=standard-error signposts=visible reexport=os' \
    "$OUTPUT/attestation/oslog-runtime.log"

sha256sum "$OBJECT" "$EXECUTABLE" \
    "$OUTPUT/os.o" "$OUTPUT/libosPortable.dylib" \
    "$OUTPUT/OSLog.o" "$OUTPUT/libOSLog.dylib" \
    "$OUTPUT/TrueIOSOSLogRuntime.o" "$OUTPUT/TrueIOSOSLogRuntime" \
    > "$OUTPUT/attestation/products.sha256"
