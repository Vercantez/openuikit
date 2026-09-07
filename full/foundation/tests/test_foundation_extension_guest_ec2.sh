#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
PACKAGE_ROOT=${PACKAGE_ROOT:?set PACKAGE_ROOT to a complete ARM64 guest package}
[ -f "$PACKAGE_ROOT/PACKAGE_COMPLETE" ] || {
    echo "Foundation extension guest test requires PACKAGE_COMPLETE" >&2
    exit 2
}
[ -f "$PACKAGE_ROOT/compile-flags.rsp" ] || {
    echo "Foundation extension guest test requires compile-flags.rsp" >&2
    exit 2
}

WORK=$(mktemp -d "${TMPDIR:-/tmp}/foundation-extension-guest.XXXXXX")
cleanup() {
    find "$WORK" -depth -delete
}
trap cleanup EXIT

mkdir -p "$WORK/modules" "$WORK/lib" "$WORK/module-cache"
FIXTURE="$ROOT/full/foundation/tests/FoundationExtensionGuestFixture.swift"
CODER_SOURCE="$ROOT/full/foundation/NSCoder+KeyedCompatibility.swift"
REFERENCE_SOURCE="$ROOT/full/foundation/FoundationReferenceCollections.swift"
SOURCE="$ROOT/full/foundation/NSExtensionHost.swift"
CONTRACT_SOURCE="$ROOT/full/foundation/NSPredicateCollections.swift"
LOCK_SOURCE="$ROOT/full/foundation/NSLock.swift"
STREAM_SOURCE="$ROOT/full/foundation/Stream.swift"
CORE_FOUNDATION_SOURCE="$ROOT/full/foundation/CoreFoundationCompatibility.swift"
CORE_FOUNDATION_EXPORT_SOURCE="$ROOT/full/foundation/FoundationCoreFoundationExports.swift"
RUNTIME="$ROOT/full/foundation/tests/FoundationExtensionGuestRuntime.swift"

(
    cd "$PACKAGE_ROOT"
    mapfile -d '' -t PACKAGE_FLAGS < compile-flags.rsp
    swiftc -I "$WORK/modules" "${PACKAGE_FLAGS[@]}" \
        -module-cache-path "$WORK/module-cache" -wmo -parse-as-library \
        -module-name CoreFoundation -emit-module \
        -emit-module-path "$WORK/modules/CoreFoundation.swiftmodule" \
        -emit-object -o "$WORK/core-foundation.o" \
        "$CORE_FOUNDATION_SOURCE"
    swiftc -I "$WORK/modules" "${PACKAGE_FLAGS[@]}" \
        -module-cache-path "$WORK/module-cache" -wmo -parse-as-library \
        -module-name Foundation -emit-module \
        -emit-module-path "$WORK/modules/Foundation.swiftmodule" \
        -emit-object -o "$WORK/foundation-extension.o" \
        "$FIXTURE" "$CODER_SOURCE" "$REFERENCE_SOURCE" "$SOURCE" \
        "$CONTRACT_SOURCE" \
        "$LOCK_SOURCE" "$STREAM_SOURCE" "$CORE_FOUNDATION_EXPORT_SOURCE" \
        "$ROOT/full/foundation/Progress.swift"
    swiftc -I "$WORK/modules" "${PACKAGE_FLAGS[@]}" \
        -module-cache-path "$WORK/module-cache" -wmo \
        -module-name FoundationExtensionGuestRuntime -emit-object \
        -o "$WORK/foundation-extension-runtime.o" "$RUNTIME"
    swiftc -I "$WORK/modules" "${PACKAGE_FLAGS[@]}" \
        -module-cache-path "$WORK/module-cache" -wmo -parse-as-library \
        -module-name FocusGuestDragDrop -emit-object \
        -o "$WORK/focus-guest-dnd.o" "$ROOT/full/appshim/tests/FocusGuestDragDrop.swift"
)

COMMON_LINK=(
    -rpath @loader_path
    -L"$PACKAGE_ROOT/lib"
    -L"$PACKAGE_ROOT/guest-root/darwin/usr/lib"
    -L"$PACKAGE_ROOT/sdk/usr/lib/swift"
    -lswiftCore
    -lswiftObjectiveC
    "$PACKAGE_ROOT/guest-root/darwin/usr/lib/libswiftcompat.dylib"
    -L"$PACKAGE_ROOT/sdk/usr/lib"
    -lSystem
    -lobjc
    "$PACKAGE_ROOT/guest-root/darwin/usr/lib/libquartz.dylib"
    "$PACKAGE_ROOT/guest-root/darwin/usr/lib/libSystem.B.dylib"
)
FOUNDATION_LINK=(
    -lFoundationEssentials
    -lOpenUIKit
    -lOpenCoreGraphics
    -lCombine
    -lOpenCombine
    -lDispatch
    -lFoundationInternationalization
    -lswift_StringProcessing
    -lswiftSynchronization
    -lswiftDarwin
    -lswift_Concurrency
    -lswift_errno
)

ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
    -syslibroot "$PACKAGE_ROOT/sdk" -dylib -ignore_auto_link \
    -install_name @rpath/libCoreFoundation.dylib -rpath @loader_path \
    -o "$WORK/lib/libCoreFoundation.dylib" "$WORK/core-foundation.o" \
    "${COMMON_LINK[@]}" "${FOUNDATION_LINK[@]}"
ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
    -syslibroot "$PACKAGE_ROOT/sdk" -dylib -ignore_auto_link \
    -install_name @rpath/libFoundation.dylib -rpath @loader_path \
    -o "$WORK/lib/libFoundation.dylib" "$WORK/foundation-extension.o" \
    -L"$WORK/lib" "${COMMON_LINK[@]}" -lCoreFoundation \
    "${FOUNDATION_LINK[@]}"
ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
    -syslibroot "$PACKAGE_ROOT/sdk" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header \
    -rpath "$WORK/lib" -rpath "$PACKAGE_ROOT/lib" \
    -o "$WORK/FoundationExtensionGuestRuntime" \
    "$WORK/foundation-extension-runtime.o" \
    -L"$WORK/lib" "${COMMON_LINK[@]}" -lFoundation -lCoreFoundation \
    "${FOUNDATION_LINK[@]}"

ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
    -syslibroot "$PACKAGE_ROOT/sdk" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header \
    -rpath "$WORK/lib" -rpath "$PACKAGE_ROOT/lib" \
    -o "$WORK/FocusGuestDragDrop" "$WORK/focus-guest-dnd.o" \
    -L"$WORK/lib" "${COMMON_LINK[@]}" -lFoundation -lCoreFoundation \
    "${FOUNDATION_LINK[@]}"

llvm-otool-18 -hv "$WORK/lib/libFoundation.dylib" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB'
llvm-otool-18 -hv "$WORK/lib/libCoreFoundation.dylib" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB'
llvm-otool-18 -hv "$WORK/FoundationExtensionGuestRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE'
[ "$(llvm-otool-18 -L "$WORK/FoundationExtensionGuestRuntime" \
    | awk '$1 == "@rpath/libFoundation.dylib" { count++ } END { print count + 0 }')" \
    -eq 1 ]
[ "$(llvm-otool-18 -L "$WORK/lib/libFoundation.dylib" \
    | awk '$1 == "@rpath/libCoreFoundation.dylib" { count++ } END { print count + 0 }')" \
    -eq 1 ]

HOST_ROOT="$PACKAGE_ROOT/guest-root/host"
HOST_PRELOAD="$HOST_ROOT/libOpenDispatchHost.so"
HOST_PRELOAD="$HOST_PRELOAD:$HOST_ROOT/libOpenFoundationInternationalizationHost.so"
HOST_PRELOAD="$HOST_PRELOAD:$HOST_ROOT/libOpenURLTransportHost.so"
HOST_PRELOAD="$HOST_PRELOAD:$HOST_ROOT/libOpenRelativeTimeHost.so"
LD_LIBRARY_PATH="$HOST_ROOT${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
LD_PRELOAD="$HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
MACHORUN_ROOT="$PACKAGE_ROOT/guest-root" \
    "$PACKAGE_ROOT/guest-root/machorun" \
    "$WORK/FoundationExtensionGuestRuntime" \
    | tee "$WORK/runtime.log"
grep -Fx \
    'FOUNDATION_EXTENSION_GUEST_OK module=Foundation identity=OpenUIKit callbacks=66 concurrency=64 coding=fail-closed canonical=predicate,dictionary,nscopying,coder,stream,cfuuid reference=array,data' \
    "$WORK/runtime.log" >/dev/null

LD_LIBRARY_PATH="$HOST_ROOT${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
LD_PRELOAD="$HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
MACHORUN_ROOT="$PACKAGE_ROOT/guest-root" \
    "$PACKAGE_ROOT/guest-root/machorun" "$WORK/FocusGuestDragDrop" \
    | tee "$WORK/dnd.log"
grep -Fx 'FOCUS_GUEST_DND_OK same-object=true urls=3 strings=1 callbacks=once progress=3/3 copy=coding=retained' \
    "$WORK/dnd.log" >/dev/null

printf '%s\n' \
    'FOUNDATION_EXTENSION_EC2_OK architecture=arm64 module=Foundation dylib=libFoundation.dylib identity=OpenUIKit callbacks=66 concurrency=64 canonical=predicate,dictionary,nscopying,coder,stream,cfuuid reference=array,data'
