#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
PACKAGE=${PACKAGE:-/opt/openuikit/core-cold/packages/core-guest-r23-44bd5af-20260901}
EXPECTED_PACKAGE_COMPLETE_SHA256=${EXPECTED_PACKAGE_COMPLETE_SHA256:-312288bda28a2fa923b75806c2aabbaaae2723cbf3d7e8f460f29605ac0f5ea3}
TARGET=arm64-apple-macos15.0
MIN_OS=15.0
PROOF=$(mktemp -d /tmp/foundation-nserror-rebuild.XXXXXX)
cleanup() {
    rm -rf "$PROOF"
}
trap cleanup EXIT

test -f "$PACKAGE/PACKAGE_COMPLETE"
actual_package_hash=$(sha256sum "$PACKAGE/PACKAGE_COMPLETE" | awk '{print $1}')
test "$actual_package_hash" = "$EXPECTED_PACKAGE_COMPLETE_SHA256"
original_foundation_hash=$(sha256sum "$PACKAGE/lib/libFoundation.dylib" \
    | awk '{print $1}')
original_compile_flags_hash=$(sha256sum "$PACKAGE/compile-flags.rsp" \
    | awk '{print $1}')

# A hard-link clone gives the rebuild the exact cold dependency closure while
# keeping the verified package immutable.  Remove every old Foundation output
# before invoking swiftc so neither a stale module nor dylib can satisfy the
# probe accidentally.
cp -al "$PACKAGE" "$PROOF/package"
REBUILT=$PROOF/package
rm -f "$REBUILT/modules/Foundation.swiftmodule" \
    "$REBUILT/modules/Foundation.swiftdoc" \
    "$REBUILT/modules/Foundation.swiftsourceinfo" \
    "$REBUILT/modules/Foundation.abi.json" \
    "$REBUILT/modules/CoreFoundation.swiftmodule" \
    "$REBUILT/modules/CoreFoundation.swiftdoc" \
    "$REBUILT/modules/CoreFoundation.swiftsourceinfo" \
    "$REBUILT/modules/CoreFoundation.abi.json" \
    "$REBUILT/lib/libFoundation.dylib" \
    "$REBUILT/lib/libCoreFoundation.dylib"
mkdir -p "$PROOF/module-cache" "$PROOF/corefoundation-module-cache"
mkdir -p "$REBUILT/include/COpenFoundationCore"
cp "$ROOT/full/foundation/include/COpenFoundationCore/OpenFoundationCFError.h" \
    "$REBUILT/include/COpenFoundationCore/OpenFoundationCFError.h"
cp "$ROOT/full/foundation/include/COpenFoundationCore/module.modulemap" \
    "$REBUILT/include/COpenFoundationCore/module.modulemap"
cp "$REBUILT/compile-flags.rsp" "$PROOF/compile-flags.rsp"
rm "$REBUILT/compile-flags.rsp"
cp "$PROOF/compile-flags.rsp" "$REBUILT/compile-flags.rsp"
printf '%s\0' \
    -Xcc -fmodule-map-file=include/COpenFoundationCore/module.modulemap \
    -Xcc -Iinclude/COpenFoundationCore \
    >> "$REBUILT/compile-flags.rsp"

mapfile -d '' -t compile_arguments < "$REBUILT/compile-flags.rsp"
mapfile -t corefoundation_sources \
    < "$ROOT/full/foundation/corefoundation_guest_sources.txt"
test "${#corefoundation_sources[@]}" -eq 1
corefoundation_paths=()
for relative in "${corefoundation_sources[@]}"; do
    test -f "$ROOT/$relative"
    corefoundation_paths+=("$ROOT/$relative")
done
mapfile -t foundation_sources \
    < "$ROOT/full/foundation/foundation_guest_sources.txt"
test "${#foundation_sources[@]}" -eq 38
foundation_paths=()
for relative in "${foundation_sources[@]}"; do
    test -f "$ROOT/$relative"
    foundation_paths+=("$ROOT/$relative")
done

(
    cd "$REBUILT"
    swiftc "${compile_arguments[@]}" -parse-as-library -wmo \
        -module-cache-path "$PROOF/corefoundation-module-cache" \
        -module-name CoreFoundation -module-link-name CoreFoundation \
        -emit-module -emit-module-path modules/CoreFoundation.swiftmodule \
        -emit-object -o "$PROOF/corefoundation.o" \
        "${corefoundation_paths[@]}"
    ld64.lld-18 -arch arm64 \
        -platform_version macos "$MIN_OS" "$MIN_OS" -syslibroot sdk \
        -dylib -dead_strip -ignore_auto_link \
        -install_name @rpath/libCoreFoundation.dylib -rpath @loader_path \
        -o lib/libCoreFoundation.dylib "$PROOF/corefoundation.o" \
        -Llib -Lguest-root/darwin/usr/lib -Lsdk/usr/lib/swift \
        -lswiftCore -lswiftObjectiveC \
        guest-root/darwin/usr/lib/libswiftcompat.dylib \
        -Lsdk/usr/lib -lSystem -lobjc \
        guest-root/darwin/usr/lib/libquartz.dylib \
        guest-root/darwin/usr/lib/libSystem.B.dylib \
        -lFoundationEssentials

    swiftc "${compile_arguments[@]}" -parse-as-library -wmo \
        -module-cache-path "$PROOF/module-cache" \
        -Xfrontend -disable-implicit-string-processing-module-import \
        -module-name Foundation \
        -emit-module -emit-module-path modules/Foundation.swiftmodule \
        -emit-object -o "$PROOF/foundation.o" \
        "${foundation_paths[@]}"

    ld64.lld-18 -arch arm64 \
        -platform_version macos "$MIN_OS" "$MIN_OS" -syslibroot sdk \
        -dylib -dead_strip -ignore_auto_link \
        -install_name @rpath/libFoundation.dylib -rpath @loader_path \
        -map "$PROOF/foundation-link.map" \
        -o lib/libFoundation.dylib "$PROOF/foundation.o" \
        -Llib -Lguest-root/darwin/usr/lib -Lsdk/usr/lib/swift \
        -lswiftCore -lswiftObjectiveC \
        guest-root/darwin/usr/lib/libswiftcompat.dylib \
        -Lsdk/usr/lib -lSystem -lobjc \
        guest-root/darwin/usr/lib/libquartz.dylib \
        guest-root/darwin/usr/lib/libSystem.B.dylib \
        -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics \
        -lCombine -lOpenCombine -lDispatch \
        -lswift_StringProcessing -lswiftSynchronization -lswiftDarwin \
        -lswift_Concurrency -lswift_errno \
        guest-root/darwin/usr/lib/libOpenURLTransport.dylib \
        guest-root/darwin/usr/lib/libOpenRelativeTime.dylib \
        -reexport_library lib/libCoreFoundation.dylib \
        -reexport_library lib/libFoundationInternationalization.dylib
)

test "$(llvm-otool-18 -D "$REBUILT/lib/libFoundation.dylib" | tail -n 1)" = \
    '@rpath/libFoundation.dylib'
rebuilt_foundation_hash=$(sha256sum "$REBUILT/lib/libFoundation.dylib" \
    | awk '{print $1}')
test "$rebuilt_foundation_hash" != "$original_foundation_hash"
test "$(sha256sum "$PACKAGE/lib/libFoundation.dylib" | awk '{print $1}')" = \
    "$original_foundation_hash"
test "$(sha256sum "$PACKAGE/compile-flags.rsp" | awk '{print $1}')" = \
    "$original_compile_flags_hash"

PACKAGE=$REBUILT \
    bash "$ROOT/full/foundation/tests/test_foundation_nserror_rebridge_package.sh"
printf 'FOUNDATION_NSERROR_REBRIDGE_REBUILD_EC2_OK sources=38 package=%s original-foundation=%s rebuilt-foundation=%s\n' \
    "$actual_package_hash" "$original_foundation_hash" \
    "$rebuilt_foundation_hash"
