#!/usr/bin/env bash
# Build the first reusable true-iOS dynamic platform slice on Linux.
#
# This consumes a completed TARGET=arm64-apple-ios18.0-simulator build_full
# output, recompiles pinned OpenCombine plus canonical Combine/SwiftUI for that
# target, links a split dylib graph, emits Xcode-style framework bundles, and
# cold-runs a SwiftUI executable against only the published dylibs. Canonical
# UIKit and upstream sources are read-only inputs.

set -euo pipefail

W=${W:-/w}
UIKIT=${UIKIT:-/uikit}
SYS=${SYS:-/true-ios-sdk/sdk}
APPLE_SWIFT_USER_OVERLAYS=${APPLE_SWIFT_USER_OVERLAYS:-/true-ios-sdk/apple-overlays}
TRUE_IOS_SDK_STAGE=${TRUE_IOS_SDK_STAGE:-/true-ios-sdk}
FULL=${FULL:-$W/build/full}
FULL_BUILD_PROJECT=${FULL_BUILD_PROJECT:-$W}
MRROOT_INPUT=${MRROOT_INPUT:-$W/scratch/mrroot_full}
SWIFT_FOUNDATION=${SWIFT_FOUNDATION:-$W/scratch/swift-foundation}
SWIFT_FOUNDATION_ICU=${SWIFT_FOUNDATION_ICU:-$W/scratch/swift-foundation-icu}
SWIFT_COLLECTIONS=${SWIFT_COLLECTIONS:-$W/scratch/swift-collections}
OPENCOMBINE_SOURCE=${OPENCOMBINE_SOURCE:-$W/scratch/opencombine-core-durable-20260828-r2/source}
FOUNDATION_SOURCES_MANIFEST=${FOUNDATION_SOURCES_MANIFEST:-$W/full/foundation/foundation_guest_sources.txt}
FOUNDATION_INTERNATIONALIZATION_BUILDER=${FOUNDATION_INTERNATIONALIZATION_BUILDER:-$W/full/foundationinternationalization/build_foundation_internationalization.sh}
OUTPUT_ROOT=${OUTPUT_ROOT:-$W/build/true-ios-platform}
SYSTEM_FONT=${SYSTEM_FONT:-/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf}
BOLD_FONT=${BOLD_FONT:-/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf}

TARGET=arm64-apple-ios18.0-simulator
TARGET_VARIANT=arm64-apple-ios-simulator
MINIMUM_OS=18.0
SDK_VERSION=26.1
PLATFORM=ios-simulator

die() {
    echo "true_ios_platform: $*" >&2
    exit 2
}

sha() { sha256sum "$1" | awk '{print $1}'; }

for tool in bash git perl patch python3 swiftc clang-18 clang++-18 ld64.lld-18 \
    llvm-nm-18 llvm-objdump-18 llvm-otool-18 file sha256sum readelf ldd; do
    command -v "$tool" >/dev/null || die "missing required tool: $tool"
done

case "$OUTPUT_ROOT" in
    /*/true-ios-platform|/*/true-ios-platform-[A-Za-z0-9._-]*) ;;
    *) die "OUTPUT_ROOT must be an absolute, narrowly named true-ios-platform path: $OUTPUT_ROOT" ;;
esac
[ "$(dirname "$OUTPUT_ROOT")" != / ] || die 'OUTPUT_ROOT parent may not be /'
[ -d "$W/full/xcodeplan" ] || die "project root is missing: $W"
[ -d "$UIKIT/Sources/SwiftUI" ] || die "canonical UIKit source is missing: $UIKIT"
[ -d "$UIKIT/Sources/OpenUIKit/Resources" ] \
    || die "canonical OpenUIKit resources are missing: $UIKIT"
[ -d "$SYS/usr/lib/swift" ] || die "true-iOS SDK is missing: $SYS"
[ -d "$APPLE_SWIFT_USER_OVERLAYS" ] || die 'Apple user-overlay directory is missing'
[ "$SYS" = "$TRUE_IOS_SDK_STAGE/sdk" ] \
    || die 'SYS must name the SDK inside TRUE_IOS_SDK_STAGE'
[ "$APPLE_SWIFT_USER_OVERLAYS" = "$TRUE_IOS_SDK_STAGE/apple-overlays" ] \
    || die 'Apple overlays must come from TRUE_IOS_SDK_STAGE'
[ -f "$TRUE_IOS_SDK_STAGE/SDK_COMPLETE" ] \
    && [ ! -L "$TRUE_IOS_SDK_STAGE/SDK_COMPLETE" ] \
    || die 'true-iOS SDK completion marker is missing'
grep -Fx \
    'TRUE_IOS_FULL_SDK_COMPLETE target=arm64-apple-ios18.0-simulator apple-overlays=darwin,objectivec' \
    "$TRUE_IOS_SDK_STAGE/SDK_COMPLETE" >/dev/null \
    || die 'true-iOS SDK completion marker drifted'
[ -f "$TRUE_IOS_SDK_STAGE/attestation/target-sdk-inputs.sha256" ] \
    && [ ! -L "$TRUE_IOS_SDK_STAGE/attestation/target-sdk-inputs.sha256" ] \
    || die 'true-iOS SDK input attestation is missing'
(
    cd "$TRUE_IOS_SDK_STAGE"
    sha256sum -c attestation/target-sdk-inputs.sha256 >/dev/null
) || die 'true-iOS SDK input attestation failed'
[ -x "$MRROOT_INPUT/machorun" ] || die 'input guest root has no machorun loader'
[ -d "$OPENCOMBINE_SOURCE/.git" ] || die 'OpenCombine input is not a Git checkout'
[ -d "$SWIFT_FOUNDATION_ICU/.git" ] \
    || die 'swift-foundation-icu input is not a Git checkout'
[ "$(git -C "$SWIFT_FOUNDATION_ICU" rev-parse HEAD^{commit})" = \
    87dbab99780e277b6a4c2a397ab1a894f877b39a ] \
    || die 'swift-foundation-icu commit drifted'
[ "$(git -C "$SWIFT_FOUNDATION_ICU" rev-parse HEAD^{tree})" = \
    823a4a2a13f60a0fd2715db85a754dda11d5fd39 ] \
    || die 'swift-foundation-icu tree drifted'
[ -z "$(git -C "$SWIFT_FOUNDATION_ICU" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'swift-foundation-icu checkout is dirty'
[ -f "$FOUNDATION_SOURCES_MANIFEST" ] && [ ! -L "$FOUNDATION_SOURCES_MANIFEST" ] \
    || die 'Foundation source manifest is missing'
[ -f "$FOUNDATION_INTERNATIONALIZATION_BUILDER" ] \
    && [ ! -L "$FOUNDATION_INTERNATIONALIZATION_BUILDER" ] \
    || die 'FoundationInternationalization builder is missing'
[ -f "$SYSTEM_FONT" ] && [ ! -L "$SYSTEM_FONT" ] \
    || die "system font input is missing: $SYSTEM_FONT"
[ -f "$BOLD_FONT" ] && [ ! -L "$BOLD_FONT" ] \
    || die "bold font input is missing: $BOLD_FONT"
[ "$(sha "$SYSTEM_FONT")" = ae7b7855e115a5966d8b1b3f80f254ccc117ec86f9965e202ee2940453837280 ] \
    || die 'system font input hash drifted'
[ "$(sha "$BOLD_FONT")" = 5c1247acef7f2b8522a31742c76d6adcb5569bacc0be7ceaa4dc39dd252ce895 ] \
    || die 'bold font input hash drifted'
[ -z "$(find "$UIKIT/Sources/OpenUIKit/Resources" -type l -print -quit)" ] \
    || die 'canonical OpenUIKit resources contain a symlink'

for required in \
    "$FULL/uihelpers-subject.sha256" \
    "$FULL/openuikit.o" "$FULL/opencoregraphics.o" \
    "$FULL/uikitshim.o" "$FULL/swiftcorepatch.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib" \
    "$MRROOT_INPUT/darwin/usr/lib/libc++.1.dylib" \
    "$MRROOT_INPUT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT_INPUT/darwin/usr/lib/libswiftcompat.dylib"; do
    [ -f "$required" ] && [ ! -L "$required" ] \
        || die "missing regular build input: $required"
done

# The reusable full objects must be from one completed, attested build. Allow a
# separately mounted source checkout because a frozen build may be promoted
# into a newer integration checkout without mutating either one.
expected_full_subject=$(bash "$FULL_BUILD_PROJECT/full/scripts/uihelpers_subject.sh" \
    "$FULL_BUILD_PROJECT" "$UIKIT" "$SWIFT_FOUNDATION" "$SWIFT_COLLECTIONS")
actual_full_subject=$(tr -d '[:space:]' < "$FULL/uihelpers-subject.sha256")
[ "$actual_full_subject" = "$expected_full_subject" ] \
    || die "full build subject is stale: expected $expected_full_subject, got $actual_full_subject"

uikit_status=$(git -C "$UIKIT" status --porcelain=v1 --untracked-files=all -- \
    Sources/SwiftUI Sources/Combine Sources/UIKitShim \
    Sources/Symbols \
    Sources/DeveloperToolsSupport Sources/OpenUIKitPreviewMacros \
    Sources/OpenSwiftUIMacros)
[ -z "$uikit_status" ] \
    || die "canonical app-facing framework/plugin source is dirty: $uikit_status"

output_parent=$(dirname "$OUTPUT_ROOT")
output_name=$(basename "$OUTPUT_ROOT")
mkdir -p "$output_parent"
rm -rf -- "$OUTPUT_ROOT"
stage=$(mktemp -d "$output_parent/.${output_name}.building.XXXXXX")
cleanup() {
    if [ -n "${stage:-}" ] && [ -d "$stage" ]; then
        rm -rf -- "$stage"
    fi
}
trap cleanup EXIT HUP INT TERM

BUILD=$stage/build
PACKAGE=$stage/package
PRODUCTS=$stage/products
SDK_OUT=$stage/sdk
FRAMEWORKS=$SDK_OUT/System/Library/Frameworks
APPLE_OVERLAYS_OUT=$stage/apple-overlays
RUNTIME_ROOT=$stage/runtime-root
RESOURCES=$stage/resources/OpenUIKit
AUDIT=$stage/attestation
MODULE_CACHE=$BUILD/module-cache
INCLUDE=$stage/include
PUBLISHED_INCLUDE=$stage/platform-include
SDK_PROVENANCE=$stage/sdk-provenance
INTERNAL_MODULE_PATH=$stage/internal-modules
HOST_TOOLS=$stage/host-tools
mkdir -p "$BUILD" "$PACKAGE" "$PRODUCTS" "$FRAMEWORKS" \
    "$APPLE_OVERLAYS_OUT" "$AUDIT" "$MODULE_CACHE" "$INCLUDE" \
    "$PUBLISHED_INCLUDE" "$SDK_PROVENANCE" "$INTERNAL_MODULE_PATH" \
    "$RESOURCES/fonts" "$HOST_TOOLS/swift/host/plugins" \
    "$HOST_TOOLS/swift/linux"

# Attest the complete pinned OpenCombine compiler subject before compiling it.
perl "$W/full/oracle-opencombine/policy_tool.pl" attest \
    "$W/full/oracle-opencombine/policy.json" "$OPENCOMBINE_SOURCE" \
    "$AUDIT/opencombine-sources.nul" "$AUDIT/opencombine-sources.json"
mapfile -d '' -t opencombine_relative_sources < "$AUDIT/opencombine-sources.nul"
[ "${#opencombine_relative_sources[@]}" -eq 103 ] \
    || die "OpenCombine source denominator is ${#opencombine_relative_sources[@]}, expected 103"
opencombine_sources=()
for source in "${opencombine_relative_sources[@]}"; do
    case "$source" in
        /*) opencombine_sources+=("$source") ;;
        *) opencombine_sources+=("$OPENCOMBINE_SOURCE/$source") ;;
    esac
done

source_subject() {
    {
        printf 'uikit-commit\t%s\n' "$(git -C "$UIKIT" rev-parse HEAD^{commit})"
        printf 'uikit-tree\t%s\n' "$(git -C "$UIKIT" rev-parse HEAD^{tree})"
        find "$UIKIT/Sources/SwiftUI" "$UIKIT/Sources/Combine" \
            "$UIKIT/Sources/Symbols" \
            "$UIKIT/Sources/UIKitShim" "$UIKIT/Sources/DeveloperToolsSupport" \
            "$UIKIT/Sources/OpenUIKitPreviewMacros" \
            "$UIKIT/Sources/OpenSwiftUIMacros" -type f \
            -name '*.swift' -print0 | LC_ALL=C sort -z \
            | while IFS= read -r -d '' source; do
                printf '%s\t%s\n' "${source#"$UIKIT"/}" "$(sha "$source")"
            done
        find "$UIKIT/Sources/OpenUIKit/Resources" -type f -print0 \
            | LC_ALL=C sort -z \
            | while IFS= read -r -d '' resource; do
                printf '%s\t%s\n' "${resource#"$UIKIT"/}" "$(sha "$resource")"
            done
        printf 'font-system\t%s\n' "$(sha "$SYSTEM_FONT")"
        printf 'font-bold\t%s\n' "$(sha "$BOLD_FONT")"
        printf 'swift-foundation-icu-commit\t%s\n' \
            "$(git -C "$SWIFT_FOUNDATION_ICU" rev-parse HEAD^{commit})"
        printf 'swift-foundation-icu-tree\t%s\n' \
            "$(git -C "$SWIFT_FOUNDATION_ICU" rev-parse HEAD^{tree})"
        printf 'foundation-manifest\t%s\n' "$(sha "$FOUNDATION_SOURCES_MANIFEST")"
        while IFS= read -r relative; do
            [ -n "$relative" ] || continue
            printf '%s\t%s\n' "$relative" "$(sha "$W/$relative")"
        done < "$FOUNDATION_SOURCES_MANIFEST"
        for support_source in \
            full/foundationinternationalization/build_foundation_internationalization.sh \
            full/foundationinternationalization/FoundationICUCXXThreading.cpp \
            full/foundationinternationalization/OpenFoundationInternationalizationBridge.c \
            full/foundationinternationalization/OpenFoundationInternationalizationHost.c \
            full/urltransport/OpenURLTransportBridge.c \
            full/urltransport/OpenURLTransportHost.c \
            full/relativetime/OpenRelativeTimeBridge.c \
            full/relativetime/OpenRelativeTimeHost.c \
            full/dispatch/Dispatch.swift full/dispatch/OpenDispatchBridge.c \
            full/dispatch/OpenDispatchHost.c \
            full/observation/observation_guest_sources.txt \
            full/observation/ObservationRuntimeBridge.c; do
            printf '%s\t%s\n' "$support_source" "$(sha "$W/$support_source")"
        done
        while IFS= read -r relative; do
            [ -n "$relative" ] || continue
            printf '%s\t%s\n' "$relative" "$(sha "$W/$relative")"
        done < "$W/full/observation/observation_guest_sources.txt"
        printf 'full-subject\t%s\n' "$actual_full_subject"
        printf 'opencombine-audit\t%s\n' "$(sha "$AUDIT/opencombine-sources.json")"
        printf 'true-ios-sdk-complete\t%s\n' \
            "$(sha "$TRUE_IOS_SDK_STAGE/SDK_COMPLETE")"
        printf 'true-ios-sdk-inputs\t%s\n' \
            "$(sha "$TRUE_IOS_SDK_STAGE/attestation/target-sdk-inputs.sha256")"
    } | sha256sum | awk '{print $1}'
}
SOURCE_SUBJECT_BEFORE=$(source_subject)
printf '%s\n' "$SOURCE_SUBJECT_BEFORE" > "$AUDIT/source-subject.before.sha256"

echo '== immutable SDK and cold runtime staging'
cp -a "$SYS/." "$SDK_OUT/"
cp -a "$APPLE_SWIFT_USER_OVERLAYS/." "$APPLE_OVERLAYS_OUT/"
cp -a "$MRROOT_INPUT/." "$RUNTIME_ROOT/"
cp "$TRUE_IOS_SDK_STAGE/SDK_COMPLETE" "$SDK_PROVENANCE/"
cp "$TRUE_IOS_SDK_STAGE/attestation/target-sdk-inputs.sha256" \
    "$SDK_PROVENANCE/"

cp -a "$FULL/inc/CPortableIO" "$INCLUDE/"
cp -a "$FULL/inc/CSTBTrueType" "$INCLUDE/"
cp -a "$W/full/hostclock/include" "$INCLUDE/CHostClock"
cp -a "$UIKIT/Sources/CQuartz/include" "$INCLUDE/CQuartz"
cp -a "$OPENCOMBINE_SOURCE/Sources/COpenCombineHelpers/include" \
    "$INCLUDE/COpenCombineHelpers"
cp -a "$W/full/urltransport/include" "$INCLUDE/COpenURLTransport"
cp -a "$W/full/relativetime/include" "$INCLUDE/COpenRelativeTime"
cp -a "$W/full/dispatch/include" "$INCLUDE/COpenDispatch"
cp -a "$SWIFT_FOUNDATION/Sources/_FoundationCShims/include" \
    "$INCLUDE/_FoundationCShims"
cp -a "$UIKIT/Sources/OpenUIKit/Resources/." "$RESOURCES/"
cp "$SYSTEM_FONT" "$RESOURCES/fonts/DejaVuSans.ttf"
cp "$BOLD_FONT" "$RESOURCES/fonts/DejaVuSans-Bold.ttf"

copy_module() {
    local module=$1 source_directory=$2 suffix source
    for suffix in swiftmodule swiftdoc swiftsourceinfo abi.json; do
        source="$source_directory/$module.$suffix"
        [ -f "$source" ] && [ ! -L "$source" ] \
            || die "missing module artifact: $source"
        cp "$source" "$PACKAGE/"
    done
}

copy_module OpenUIKit "$FULL"
copy_module OpenCoreGraphics "$FULL"
copy_module FoundationEssentials "$FULL/foundation/essentials"
copy_module InternalCollectionsUtilities "$FULL/foundation/collections"
copy_module OrderedCollections "$FULL/foundation/collections"
copy_module _RopeModule "$FULL/foundation/collections"
copy_module os "$FULL/foundation/os"

SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS" -I "$APPLE_SWIFT_USER_OVERLAYS"
    -module-cache-path "$MODULE_CACHE" -runtime-compatibility-version none -wmo
    -Xfrontend -enable-cross-import-overlays
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xfrontend -disable-objc-attr-requires-foundation-module)
CFLAGS=(-Xcc -I"$INCLUDE/CPortableIO" -Xcc -I"$INCLUDE/CSTBTrueType"
    -Xcc -I"$INCLUDE/CHostClock" -Xcc -I"$INCLUDE/COpenCombineHelpers"
    -Xcc -I"$INCLUDE/CQuartz"
    -Xcc -fmodule-map-file="$INCLUDE/COpenURLTransport/module.modulemap"
    -Xcc -I"$INCLUDE/COpenURLTransport"
    -Xcc -fmodule-map-file="$INCLUDE/COpenRelativeTime/module.modulemap"
    -Xcc -I"$INCLUDE/COpenRelativeTime"
    -Xcc -fmodule-map-file="$INCLUDE/COpenDispatch/module.modulemap"
    -Xcc -I"$INCLUDE/COpenDispatch"
    -Xcc -fmodule-map-file="$INCLUDE/_FoundationCShims/module.modulemap"
    -Xcc -I"$INCLUDE/_FoundationCShims")
FE_FLAGS=(-I "$FULL/foundation/essentials"
    -I "$FULL/foundation/collections" -I "$FULL/foundation/os")
LD=(ld64.lld-18 -arch arm64 -platform_version "$PLATFORM" "$MINIMUM_OS" \
    "$SDK_VERSION" -syslibroot "$SYS")
COMMON_RUNTIME=(-L"$RUNTIME_ROOT/darwin/usr/lib/swift"
    -L"$MRROOT_INPUT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore
    "$MRROOT_INPUT/darwin/usr/lib/libswiftcompat.dylib" -L/usr/lib -lSystem)

echo '== pinned OpenCombine (103 sources) and literal Combine'
cp "$OPENCOMBINE_SOURCE/Sources/COpenCombineHelpers/COpenCombineHelpers.cpp" \
    "$BUILD/COpenCombineHelpers.cpp"
patch --batch --forward --fuzz=0 "$BUILD/COpenCombineHelpers.cpp" \
    "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch"
patched_helper_sha=$(sha "$BUILD/COpenCombineHelpers.cpp")
[ "$patched_helper_sha" = d9fbefcdba66d892d9064c46b21b6084af217ddec1d604bcaf27b160de66083b ] \
    || die "patched OpenCombine helper drifted: $patched_helper_sha"
clang++-18 -target "$TARGET" -isysroot "$SYS" -stdlib=libc++ -std=c++17 -O2 \
    -I "$INCLUDE/COpenCombineHelpers" -c "$BUILD/COpenCombineHelpers.cpp" \
    -o "$BUILD/copencombinehelpers.o"
"${SWIFTC[@]}" "${CFLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name OpenCombine \
    -emit-module -emit-module-path "$PACKAGE/OpenCombine.swiftmodule" \
    -emit-object -o "$BUILD/OpenCombine.o" "${opencombine_sources[@]}"
"${SWIFTC[@]}" "${CFLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name Combine \
    -emit-module -emit-module-path "$PACKAGE/Combine.swiftmodule" \
    -emit-object -o "$BUILD/Combine.o" "$UIKIT/Sources/Combine/Combine.swift"

FE_OBJECTS=(
    "$FULL/foundation/essentials/FoundationEssentials.o"
    "$FULL/foundation/collections/InternalCollectionsUtilities.o"
    "$FULL/foundation/collections/OrderedCollections.o"
    "$FULL/foundation/collections/_RopeModule.o"
    "$FULL/foundation/os/os.o"
    "$FULL/foundation/cshims/platform_shims.o"
    "$FULL/foundation/cshims/string_shims.o"
    "$FULL/foundation/cshims/uuid.o"
    "$FULL/foundation/essentials/fm_unimplemented.o"
    "$FULL/foundation/essentials/removefile_compat.o"
    "$FULL/foundation/essentials/uuid_compat.o"
)

echo '== split true-iOS dynamic framework graph'
"${LD[@]}" -dylib -install_name /usr/lib/libOpenCombine.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$MRROOT_INPUT/darwin/usr/lib" -L/usr/lib/swift \
    -lswiftCore -lswift_Concurrency -L/usr/lib -lSystem \
    -o "$PRODUCTS/libOpenCombine.dylib" \
    "$BUILD/OpenCombine.o" "$BUILD/copencombinehelpers.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libc++.1.dylib" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -install_name /usr/lib/libCombine.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lOpenCombine "${COMMON_RUNTIME[@]}" \
    -o "$PRODUCTS/libCombine.dylib" "$BUILD/Combine.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -install_name /usr/lib/libFoundationEssentials.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    "${COMMON_RUNTIME[@]}" -o "$PRODUCTS/libFoundationEssentials.dylib" \
    "${FE_OBJECTS[@]}" "$FULL/swiftcorepatch.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -install_name /usr/lib/libOpenCoreGraphics.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    "${COMMON_RUNTIME[@]}" -o "$PRODUCTS/libOpenCoreGraphics.dylib" \
    "$FULL/opencoregraphics.o" "$MRROOT_INPUT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -install_name /usr/lib/libOpenUIKit.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lFoundationEssentials -lOpenCoreGraphics \
    "${COMMON_RUNTIME[@]}" -lobjc -o "$PRODUCTS/libOpenUIKit.dylib" \
    "$FULL/openuikit.o" "$FULL/cportableio.o" "$FULL/cstbtruetype.o" \
    "$FULL/hostclock.o" "$FULL/swiftcorepatch.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

echo '== first-party Symbols and official Observation runtime'
mapfile -d '' -t symbols_sources < <(
    find "$UIKIT/Sources/Symbols" -maxdepth 1 -type f -name '*.swift' \
        -print0 | LC_ALL=C sort -z
)
[ "${#symbols_sources[@]}" -eq 1 ] \
    || die "Symbols source denominator is ${#symbols_sources[@]}, expected 1"
"${SWIFTC[@]}" -parse-as-library -module-name Symbols \
    -module-link-name Symbols -enable-library-evolution \
    -emit-module -emit-module-path "$PACKAGE/Symbols.swiftmodule" \
    -emit-module-interface-path "$PACKAGE/Symbols.swiftinterface" \
    -emit-object -o "$BUILD/Symbols.o" "${symbols_sources[@]}"
"${LD[@]}" -dylib -dead_strip -install_name /usr/lib/libSymbols.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    "${COMMON_RUNTIME[@]}" -o "$PRODUCTS/libSymbols.dylib" \
    "$BUILD/Symbols.o" "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

mapfile -t observation_relative_sources \
    < "$W/full/observation/observation_guest_sources.txt"
[ "${#observation_relative_sources[@]}" -eq 6 ] \
    || die "Observation source denominator is ${#observation_relative_sources[@]}, expected 6"
observation_sources=()
for relative in "${observation_relative_sources[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "Observation source is missing or a symlink: $relative"
    observation_sources+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library -suppress-warnings \
    -module-name Observation -module-link-name swiftObservation \
    -enable-library-evolution -enable-experimental-feature Macros \
    -enable-experimental-feature ExtensionMacros \
    -emit-module -emit-module-path "$PACKAGE/Observation.swiftmodule" \
    -emit-module-interface-path "$PACKAGE/Observation.swiftinterface" \
    -emit-object -o "$BUILD/Observation.o" "${observation_sources[@]}"
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -c "$W/full/observation/ObservationRuntimeBridge.c" \
    -o "$BUILD/observation-runtime-bridge.o"
OBSERVATION_DYLIB=$RUNTIME_ROOT/darwin/usr/lib/swift/libswiftObservation.dylib
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name /usr/lib/swift/libswiftObservation.dylib \
    -o "$OBSERVATION_DYLIB" \
    "$BUILD/Observation.o" "$BUILD/observation-runtime-bridge.o" \
    "$FULL/swiftcorepatch.o" -L"$MRROOT_INPUT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore -lswiftObjectiveC -lswift_Concurrency \
    "$MRROOT_INPUT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

echo '== fixed-ABI Foundation service bridges'
URL_TRANSPORT_DARWIN=$RUNTIME_ROOT/darwin/usr/lib/libOpenURLTransport.dylib
URL_TRANSPORT_HOST=$RUNTIME_ROOT/host/libOpenURLTransportHost.so
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$INCLUDE/COpenURLTransport" \
    -c "$W/full/urltransport/OpenURLTransportBridge.c" \
    -o "$BUILD/open-url-transport-bridge.o"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenURLTransport.dylib \
    -o "$URL_TRANSPORT_DARWIN" "$BUILD/open-url-transport-bridge.o"
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$INCLUDE/COpenURLTransport" -shared \
    "$W/full/urltransport/OpenURLTransportHost.c" \
    -o "$URL_TRANSPORT_HOST" -lcurl -pthread

RELATIVE_TIME_DARWIN=$RUNTIME_ROOT/darwin/usr/lib/libOpenRelativeTime.dylib
RELATIVE_TIME_HOST=$RUNTIME_ROOT/host/libOpenRelativeTimeHost.so
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$INCLUDE/COpenRelativeTime" \
    -c "$W/full/relativetime/OpenRelativeTimeBridge.c" \
    -o "$BUILD/open-relative-time-bridge.o"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenRelativeTime.dylib \
    -o "$RELATIVE_TIME_DARWIN" "$BUILD/open-relative-time-bridge.o"
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$INCLUDE/COpenRelativeTime" -shared \
    "$W/full/relativetime/OpenRelativeTimeHost.c" \
    -o "$RELATIVE_TIME_HOST" -licui18n -licuuc -lm

DISPATCH_DARWIN=$RUNTIME_ROOT/darwin/usr/lib/libOpenDispatch.dylib
DISPATCH_HOST=$RUNTIME_ROOT/host/libOpenDispatchHost.so
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$INCLUDE/COpenDispatch" -c "$W/full/dispatch/OpenDispatchBridge.c" \
    -o "$BUILD/open-dispatch-bridge.o"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenDispatch.dylib \
    -o "$DISPATCH_DARWIN" "$BUILD/open-dispatch-bridge.o"
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$INCLUDE/COpenDispatch" -I /usr/lib/swift -shared \
    "$W/full/dispatch/OpenDispatchHost.c" \
    -L "$RUNTIME_ROOT/host" -Wl,-rpath,'$ORIGIN' \
    -ldispatch -Wl,--no-as-needed -lBlocksRuntime -Wl,--as-needed -pthread \
    -o "$DISPATCH_HOST"
for bridge in OpenURLTransport OpenRelativeTime OpenDispatch; do
    actual_id=$(llvm-otool-18 -D \
        "$RUNTIME_ROOT/darwin/usr/lib/lib$bridge.dylib" | tail -n 1)
    [ "$actual_id" = "/usr/lib/lib$bridge.dylib" ] \
        || die "$bridge bridge install name drifted: $actual_id"
done
for helper in "$URL_TRANSPORT_HOST" "$RELATIVE_TIME_HOST" "$DISPATCH_HOST"; do
    LD_LIBRARY_PATH="$RUNTIME_ROOT/host" ldd "$helper" | grep -Fq 'not found' \
        && die "Foundation service host closure is incomplete: $helper"
done

echo '== full pinned FoundationInternationalization and 474-TU ICU'
FINTL_STAGE=$BUILD/foundation-internationalization-stage
mkdir -p "$FINTL_STAGE"
ln -s "$SDK_OUT" "$FINTL_STAGE/sdk"
ln -s "$PACKAGE" "$FINTL_STAGE/modules"
ln -s "$PRODUCTS" "$FINTL_STAGE/lib"
ln -s "$INCLUDE" "$FINTL_STAGE/include"
ln -s "$RUNTIME_ROOT" "$FINTL_STAGE/guest-root"
ln -s "$AUDIT" "$FINTL_STAGE/attestation"
env SUPPORT_ROOT="$W" SWIFT_FOUNDATION="$SWIFT_FOUNDATION" \
    SWIFT_FOUNDATION_ICU="$SWIFT_FOUNDATION_ICU" STAGE="$FINTL_STAGE" \
    WORK="$BUILD" TARGET="$TARGET" MIN_OS="$MINIMUM_OS" \
    LINK_PLATFORM="$PLATFORM" LINK_SDK_VERSION="$SDK_VERSION" \
    APPLE_SWIFT_USER_OVERLAYS="$APPLE_OVERLAYS_OUT" \
    DYLIB_INSTALL_PREFIX=/usr/lib \
    FOUNDATION_ICU_JOBS="${FOUNDATION_ICU_JOBS:-8}" \
    bash "$FOUNDATION_INTERNATIONALIZATION_BUILDER"

echo '== portable Dispatch and 32-source public Foundation facade'
"${SWIFTC[@]}" "${CFLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name Dispatch -module-link-name Dispatch \
    -emit-module -emit-module-path "$PACKAGE/Dispatch.swiftmodule" \
    -emit-object -o "$BUILD/Dispatch.o" "$W/full/dispatch/Dispatch.swift"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libDispatch.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lOpenCombine "${COMMON_RUNTIME[@]}" \
    -lswift_Concurrency -o "$PRODUCTS/libDispatch.dylib" \
    "$BUILD/Dispatch.o" "$DISPATCH_DARWIN" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

FOUNDATION_CFLAGS=(
    -Xcc -fmodule-map-file="$INCLUDE/FoundationICU/_foundation_unicode/module.modulemap"
    -Xcc -I"$INCLUDE/FoundationICU"
)
mapfile -t foundation_relative_sources < "$FOUNDATION_SOURCES_MANIFEST"
[ "${#foundation_relative_sources[@]}" -eq 32 ] \
    || die "Foundation source denominator is ${#foundation_relative_sources[@]}, expected 32"
foundation_sources=()
for relative in "${foundation_relative_sources[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "Foundation source is missing or a symlink: $relative"
    foundation_sources+=("$W/$relative")
done
"${SWIFTC[@]}" "${CFLAGS[@]}" "${FOUNDATION_CFLAGS[@]}" \
    "${FE_FLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name Foundation \
    -emit-module -emit-module-path "$PACKAGE/Foundation.swiftmodule" \
    -emit-object -o "$BUILD/Foundation.o" "${foundation_sources[@]}"
FOUNDATION_RUNTIME_FLAGS=(
    -lswift_StringProcessing -lswiftSynchronization -lswiftDarwin
    -lswift_Concurrency -lswift_errno
)
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name /usr/lib/libFoundation.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics \
    -lCombine -lOpenCombine -lDispatch \
    "${COMMON_RUNTIME[@]}" -lswiftObjectiveC -lobjc \
    "${FOUNDATION_RUNTIME_FLAGS[@]}" \
    "$URL_TRANSPORT_DARWIN" "$RELATIVE_TIME_DARWIN" \
    -reexport_library "$PRODUCTS/libFoundationInternationalization.dylib" \
    -o "$PRODUCTS/libFoundation.dylib" "$BUILD/Foundation.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

echo '== five relocatable first-party compiler-library plugins'
PLUGIN_HOST_LIBRARIES=(
    libSwiftSyntaxMacros.so libSwiftSyntaxBuilder.so libSwiftParserDiagnostics.so
    libSwiftBasicFormat.so libSwiftParser.so libSwiftDiagnostics.so libSwiftSyntax.so
)
PLUGIN_LINUX_LIBRARIES=(
    libswiftCore.so libswift_Concurrency.so libswiftGlibc.so libdispatch.so
    libswift_Builtin_float.so libBlocksRuntime.so libswiftSwiftOnoneSupport.so
    libswift_StringProcessing.so libswift_RegexParser.so
)
cp /usr/lib/swift/host/plugins/libObservationMacros.so \
    "$HOST_TOOLS/swift/host/plugins/"
cp /usr/lib/swift/host/plugins/libFoundationMacros.so \
    "$HOST_TOOLS/swift/host/plugins/"
for library in "${PLUGIN_HOST_LIBRARIES[@]}"; do
    cp "/usr/lib/swift/host/$library" "$HOST_TOOLS/swift/host/$library"
done
for library in "${PLUGIN_LINUX_LIBRARIES[@]}"; do
    cp "/usr/lib/swift/linux/$library" "$HOST_TOOLS/swift/linux/$library"
done
swiftc -parse-as-library -emit-library -module-name SwiftDataMacros \
    -no-toolchain-stdlib-rpath -I /usr/lib/swift/host -L /usr/lib/swift/host \
    -Xlinker -rpath -Xlinker '$ORIGIN/..' \
    -Xlinker -rpath -Xlinker '$ORIGIN/../../../swift/linux' \
    "$W/full/swiftdata/SwiftDataMacros.swift" \
    -o "$HOST_TOOLS/swift/host/plugins/libSwiftDataMacros.so"
swiftc -parse-as-library -emit-library -module-name OpenUIKitPreviewMacros \
    -no-toolchain-stdlib-rpath -I /usr/lib/swift/host -L /usr/lib/swift/host \
    -Xlinker -rpath -Xlinker '$ORIGIN/..' \
    -Xlinker -rpath -Xlinker '$ORIGIN/../../../swift/linux' \
    "$UIKIT/Sources/OpenUIKitPreviewMacros/UIKitPreviewMacro.swift" \
    -o "$HOST_TOOLS/swift/host/plugins/libOpenUIKitPreviewMacros.so"
swiftc -parse-as-library -emit-library -module-name OpenSwiftUIMacros \
    -no-toolchain-stdlib-rpath -I /usr/lib/swift/host -L /usr/lib/swift/host \
    -Xlinker -rpath -Xlinker '$ORIGIN/..' \
    -Xlinker -rpath -Xlinker '$ORIGIN/../../../swift/linux' \
    "$UIKIT/Sources/OpenSwiftUIMacros/EntryMacro.swift" \
    -o "$HOST_TOOLS/swift/host/plugins/libOpenSwiftUIMacros.so"
PLUGIN_FLAGS=(
    -load-plugin-library "$HOST_TOOLS/swift/host/plugins/libObservationMacros.so"
    -load-plugin-library "$HOST_TOOLS/swift/host/plugins/libFoundationMacros.so"
    -load-plugin-library "$HOST_TOOLS/swift/host/plugins/libSwiftDataMacros.so"
    -load-plugin-library "$HOST_TOOLS/swift/host/plugins/libOpenUIKitPreviewMacros.so"
    -load-plugin-library "$HOST_TOOLS/swift/host/plugins/libOpenSwiftUIMacros.so"
)
for plugin in "$HOST_TOOLS"/swift/host/plugins/*.so; do
    file "$plugin" | grep -Eq 'ELF 64-bit.*(ARM aarch64|aarch64)' \
        || die "compiler plugin is not native ELF64/aarch64: $plugin"
    LD_LIBRARY_PATH="$HOST_TOOLS/swift/host:$HOST_TOOLS/swift/linux" \
        ldd "$plugin" | grep -Fq 'not found' \
        && die "compiler plugin closure is incomplete: $plugin"
done
{
    printf 'format\ttrue-ios-compiler-plugins-v1\n'
    for module in ObservationMacros FoundationMacros SwiftDataMacros \
        OpenUIKitPreviewMacros OpenSwiftUIMacros; do
        printf 'plugin\t%s\thost-tools/swift/host/plugins/lib%s.so\t%s\n' \
            "$module" "$module" \
            "$(sha "$HOST_TOOLS/swift/host/plugins/lib$module.so")"
    done
} > "$AUDIT/compiler-plugins.tsv"

echo '== post-Foundation DeveloperToolsSupport, final UIKit, and SwiftUI'
"${SWIFTC[@]}" "${CFLAGS[@]}" "${FOUNDATION_CFLAGS[@]}" \
    "${FE_FLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name DeveloperToolsSupport \
    -emit-module -emit-module-path "$PACKAGE/DeveloperToolsSupport.swiftmodule" \
    -emit-object -o "$BUILD/DeveloperToolsSupport.o" \
    "$UIKIT/Sources/DeveloperToolsSupport/Preview.swift"
"${SWIFTC[@]}" "${CFLAGS[@]}" "${FOUNDATION_CFLAGS[@]}" \
    "${FE_FLAGS[@]}" "${PLUGIN_FLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name UIKit -emit-module -emit-module-path "$PACKAGE/UIKit.swiftmodule" \
    -emit-object -o "$BUILD/UIKit.o" "$UIKIT/Sources/UIKitShim/UIKit.swift"
mapfile -d '' -t swiftui_sources < <(
    find "$UIKIT/Sources/SwiftUI" -maxdepth 1 -type f -name '*.swift' \
        -print0 | LC_ALL=C sort -z
)
[ "${#swiftui_sources[@]}" -ge 11 ] \
    || die "canonical SwiftUI source denominator unexpectedly fell to ${#swiftui_sources[@]}"
"${SWIFTC[@]}" "${CFLAGS[@]}" "${FOUNDATION_CFLAGS[@]}" \
    "${FE_FLAGS[@]}" "${PLUGIN_FLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name SwiftUI -emit-module \
    -emit-module-path "$PACKAGE/SwiftUI.swiftmodule" \
    -emit-object -o "$BUILD/SwiftUI.o" "${swiftui_sources[@]}"

"${LD[@]}" -dylib -install_name /usr/lib/libDeveloperToolsSupport.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lFoundation -lOpenUIKit -lFoundationEssentials \
    "${COMMON_RUNTIME[@]}" -o "$PRODUCTS/libDeveloperToolsSupport.dylib" \
    "$BUILD/DeveloperToolsSupport.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -install_name /usr/lib/libUIKit.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lOpenUIKit -lOpenCoreGraphics -lFoundation \
    -lFoundationEssentials -lDeveloperToolsSupport \
    "${COMMON_RUNTIME[@]}" -lswiftObjectiveC -lobjc \
    -o "$PRODUCTS/libUIKit.dylib" "$BUILD/UIKit.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -install_name /usr/lib/libSwiftUI.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lUIKit -lFoundation -lOpenUIKit -lOpenCoreGraphics \
    -lFoundationEssentials -lDeveloperToolsSupport -lCombine -lOpenCombine \
    -lSymbols \
    "${COMMON_RUNTIME[@]}" -lswiftObjectiveC -lswift_Concurrency \
    -o "$PRODUCTS/libSwiftUI.dylib" "$BUILD/SwiftUI.o" \
    "$OBSERVATION_DYLIB" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

cp -a "$INCLUDE/." "$PUBLISHED_INCLUDE/"
PUBLIC_MODULES=(
    FoundationEssentials FoundationInternationalization Foundation Dispatch
    OpenCoreGraphics OpenUIKit DeveloperToolsSupport UIKit OpenCombine Combine
    Symbols SwiftUI
)
PRIVATE_DYLIBS=(_FoundationICU)
RUNTIME_SWIFT_MODULES=(Observation)
INTERNAL_MODULES=(InternalCollectionsUtilities OrderedCollections _RopeModule os)

echo '== framework SDK layout'
stage_framework() {
    local module=$1 framework="$FRAMEWORKS/$1.framework" suffix source destination
    mkdir -p "$framework/Modules/$module.swiftmodule"
    cp "$PRODUCTS/lib$module.dylib" "$framework/$module"
    for suffix in swiftmodule swiftdoc swiftsourceinfo abi.json; do
        source="$PACKAGE/$module.$suffix"
        [ -f "$source" ] && [ ! -L "$source" ] || die "missing $module.$suffix"
        destination="$framework/Modules/$module.swiftmodule/$TARGET_VARIANT.$suffix"
        cp "$source" "$destination"
    done
}
for module in "${PUBLIC_MODULES[@]}"; do stage_framework "$module"; done

# Private transitive Swift modules live in the SDK Swift module directory; the
# public first-party identities above remain framework modules.
for module in "${INTERNAL_MODULES[@]}"; do
    module_directory="$SDK_OUT/usr/lib/swift/$module.swiftmodule"
    mkdir -p "$module_directory"
    for suffix in swiftmodule swiftdoc swiftsourceinfo abi.json; do
        cp "$PACKAGE/$module.$suffix" \
            "$module_directory/$TARGET_VARIANT.$suffix"
        cp "$PACKAGE/$module.$suffix" "$INTERNAL_MODULE_PATH/"
    done
done
for module in "${RUNTIME_SWIFT_MODULES[@]}"; do
    module_directory="$SDK_OUT/usr/lib/swift/$module.swiftmodule"
    mkdir -p "$module_directory"
    for suffix in swiftmodule swiftdoc swiftsourceinfo abi.json; do
        cp "$PACKAGE/$module.$suffix" \
            "$module_directory/$TARGET_VARIANT.$suffix"
        cp "$PACKAGE/$module.$suffix" "$INTERNAL_MODULE_PATH/"
    done
done

echo '== private cold runtime root'
for module in "${PUBLIC_MODULES[@]}"; do
    install -m 0755 "$PRODUCTS/lib$module.dylib" \
        "$RUNTIME_ROOT/darwin/usr/lib/lib$module.dylib"
done
for module in "${PRIVATE_DYLIBS[@]}"; do
    install -m 0755 "$PRODUCTS/lib$module.dylib" \
        "$RUNTIME_ROOT/darwin/usr/lib/lib$module.dylib"
done
mkdir -p "$RUNTIME_ROOT/darwin/System/Library/Frameworks"
for module in "${PUBLIC_MODULES[@]}"; do
    cp -a "$FRAMEWORKS/$module.framework" \
        "$RUNTIME_ROOT/darwin/System/Library/Frameworks/"
done

echo '== untouched-source-shaped framework consumer'
PROBE_SOURCE=$W/full/xcodeplan/tests/TrueIOSSwiftUIDylibProbe.swift
[ -f "$PROBE_SOURCE" ] && [ ! -L "$PROBE_SOURCE" ] \
    || die 'SwiftUI dylib probe source is missing'
PROBE_CFLAGS=(-Xcc -I"$PUBLISHED_INCLUDE/CPortableIO"
    -Xcc -I"$PUBLISHED_INCLUDE/CSTBTrueType"
    -Xcc -I"$PUBLISHED_INCLUDE/CHostClock"
    -Xcc -I"$PUBLISHED_INCLUDE/COpenCombineHelpers"
    -Xcc -I"$PUBLISHED_INCLUDE/CQuartz"
    -Xcc -fmodule-map-file="$PUBLISHED_INCLUDE/COpenURLTransport/module.modulemap"
    -Xcc -I"$PUBLISHED_INCLUDE/COpenURLTransport"
    -Xcc -fmodule-map-file="$PUBLISHED_INCLUDE/COpenRelativeTime/module.modulemap"
    -Xcc -I"$PUBLISHED_INCLUDE/COpenRelativeTime"
    -Xcc -fmodule-map-file="$PUBLISHED_INCLUDE/COpenDispatch/module.modulemap"
    -Xcc -I"$PUBLISHED_INCLUDE/COpenDispatch"
    -Xcc -fmodule-map-file="$PUBLISHED_INCLUDE/FoundationICU/_foundation_unicode/module.modulemap"
    -Xcc -I"$PUBLISHED_INCLUDE/FoundationICU"
    -Xcc -fmodule-map-file="$PUBLISHED_INCLUDE/_FoundationCShims/module.modulemap"
    -Xcc -I"$PUBLISHED_INCLUDE/_FoundationCShims")
# Compile from a fresh cache using only paths that will be published. Keeping
# support module maps outside the SDK is intentional: SDK usr/local/include is
# an implicit Clang search path and would collide with the toolchain's own
# _FoundationCShims module map in a downstream clean build.
if ! swiftc -target "$TARGET" -sdk "$SDK_OUT" -I "$APPLE_OVERLAYS_OUT" \
    -F "$FRAMEWORKS" \
    -module-cache-path "$BUILD/framework-module-cache" \
    -runtime-compatibility-version none -Rmodule-loading \
    -Xfrontend -disable-implicit-string-processing-module-import \
    -Xfrontend -disable-objc-attr-requires-foundation-module \
    "${PROBE_CFLAGS[@]}" -parse-as-library \
    -module-name TrueIOSSwiftUIDylibProbe -emit-object \
    -o "$BUILD/true-ios-swiftui-dylib-probe.o" "$PROBE_SOURCE" \
    2> "$AUDIT/framework-module-loading.log"; then
    cat "$AUDIT/framework-module-loading.log" >&2
    die 'framework-only consumer compile failed'
fi
for module in SwiftUI UIKit Foundation Dispatch Symbols OpenUIKit Combine OpenCombine; do
    expected_module_path="$FRAMEWORKS/$module.framework/Modules/$module.swiftmodule/$TARGET_VARIANT.swiftmodule"
    grep -Fq "loaded module '$module'; source: '$expected_module_path'" \
        "$AUDIT/framework-module-loading.log" \
        || die "$module was not loaded from its published framework module"
done
"${LD[@]}" -dead_strip -exported_symbol __mh_execute_header \
    -rpath @loader_path -F"$FRAMEWORKS" -framework SwiftUI -framework UIKit \
    -L"$PRODUCTS" -lFoundation -lFoundationInternationalization -lDispatch \
    -lOpenUIKit -lOpenCoreGraphics -lFoundationEssentials \
    -lDeveloperToolsSupport -lCombine -lOpenCombine -lSymbols -l_FoundationICU \
    "${COMMON_RUNTIME[@]}" -lswiftObjectiveC -lswift_Concurrency -lobjc \
    "$OBSERVATION_DYLIB" \
    -o "$stage/true-ios-swiftui-dylib-probe" \
    "$BUILD/true-ios-swiftui-dylib-probe.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

echo '== Mach-O platform and dynamic-closure audit'
for module in "${PUBLIC_MODULES[@]}"; do
    binary="$PRODUCTS/lib$module.dylib"
    file "$binary" | grep -Fq 'Mach-O 64-bit arm64 dynamically linked shared library' \
        || die "lib$module is not an ARM64 Mach-O dylib"
    actual_id=$(llvm-otool-18 -D "$binary" | tail -n 1)
    [ "$actual_id" = "/usr/lib/lib$module.dylib" ] \
        || die "lib$module ID is $actual_id"
    headers=$(llvm-objdump-18 --macho --private-headers "$binary")
    grep -Fq 'platform iossimulator' <<< "$headers" \
        || die "lib$module does not advertise iOS Simulator"
    grep -Fq 'sdk 26.1' <<< "$headers" || die "lib$module SDK marker drifted"
    grep -Fq 'minos 18.0' <<< "$headers" || die "lib$module minOS marker drifted"
done
for module in "${PRIVATE_DYLIBS[@]}"; do
    binary="$PRODUCTS/lib$module.dylib"
    file "$binary" | grep -Fq 'Mach-O 64-bit arm64 dynamically linked shared library' \
        || die "lib$module is not an ARM64 Mach-O dylib"
    actual_id=$(llvm-otool-18 -D "$binary" | tail -n 1)
    [ "$actual_id" = "/usr/lib/lib$module.dylib" ] \
        || die "lib$module ID is $actual_id"
    headers=$(llvm-objdump-18 --macho --private-headers "$binary")
    grep -Fq 'platform iossimulator' <<< "$headers" \
        || die "lib$module does not advertise iOS Simulator"
    grep -Fq 'sdk 26.1' <<< "$headers" || die "lib$module SDK marker drifted"
    grep -Fq 'minos 18.0' <<< "$headers" || die "lib$module minOS marker drifted"
done
file "$OBSERVATION_DYLIB" \
    | grep -Fq 'Mach-O 64-bit arm64 dynamically linked shared library' \
    || die 'libswiftObservation is not an ARM64 Mach-O dylib'
[ "$(llvm-otool-18 -D "$OBSERVATION_DYLIB" | tail -n 1)" = \
    /usr/lib/swift/libswiftObservation.dylib ] \
    || die 'libswiftObservation install name drifted'
observation_headers=$(llvm-objdump-18 --macho --private-headers \
    "$OBSERVATION_DYLIB")
grep -Fq 'platform iossimulator' <<< "$observation_headers" \
    || die 'libswiftObservation does not advertise iOS Simulator'
grep -Fq 'sdk 26.1' <<< "$observation_headers" \
    || die 'libswiftObservation SDK marker drifted'
grep -Fq 'minos 18.0' <<< "$observation_headers" \
    || die 'libswiftObservation minOS marker drifted'
probe_headers=$(llvm-objdump-18 --macho --private-headers \
    "$stage/true-ios-swiftui-dylib-probe")
grep -Fq 'platform iossimulator' <<< "$probe_headers" \
    || die 'probe does not advertise iOS Simulator'
swiftui_loads=$(llvm-otool-18 -L "$stage/true-ios-swiftui-dylib-probe" \
    | awk '$1 == "/usr/lib/libSwiftUI.dylib" { count++ } END { print count + 0 }')
[ "$swiftui_loads" -eq 1 ] || die "probe SwiftUI load count is $swiftui_loads"

HOST_LIBRARIES=(
    libdispatch.so libBlocksRuntime.so libOpenDispatchHost.so
    libOpenFoundationInternationalizationHost.so libOpenURLTransportHost.so
    libOpenRelativeTimeHost.so
)
for host_library in "${HOST_LIBRARIES[@]}"; do
    [ -f "$RUNTIME_ROOT/host/$host_library" ] && [ ! -L "$RUNTIME_ROOT/host/$host_library" ] \
        || die "cold runtime host closure is missing $host_library"
done
host_preload="$RUNTIME_ROOT/host/libOpenDispatchHost.so:$RUNTIME_ROOT/host/libOpenFoundationInternationalizationHost.so:$RUNTIME_ROOT/host/libOpenURLTransportHost.so:$RUNTIME_ROOT/host/libOpenRelativeTimeHost.so"
(
    cd "$stage"
    MACHORUN_ROOT="$RUNTIME_ROOT" \
    LD_LIBRARY_PATH="$RUNTIME_ROOT/host" LD_PRELOAD="$host_preload" \
        "$RUNTIME_ROOT/machorun" ./true-ios-swiftui-dylib-probe
) | tee "$AUDIT/runtime.log"
grep -Fq 'TRUE_IOS_SWIFTUI_DYLIB_RUNTIME_OK descendants=' "$AUDIT/runtime.log" \
    || die 'cold SwiftUI dylib runtime marker is missing'

SOURCE_SUBJECT_AFTER=$(source_subject)
printf '%s\n' "$SOURCE_SUBJECT_AFTER" > "$AUDIT/source-subject.after.sha256"
[ "$SOURCE_SUBJECT_BEFORE" = "$SOURCE_SUBJECT_AFTER" ] \
    || die 'canonical/upstream source changed during the build'
(
    cd "$TRUE_IOS_SDK_STAGE"
    sha256sum -c attestation/target-sdk-inputs.sha256 >/dev/null
) || die 'true-iOS SDK input changed during the build'

# Compiler caches and intermediate objects are deliberately not published.
# Every replay starts from a clean temporary stage and regenerates them.
rm -rf -- "$BUILD" "$INCLUDE"
(
    cd "$stage"
    find products package internal-modules sdk apple-overlays platform-include \
        runtime-root sdk-provenance resources host-tools \
        -type f -print0 | LC_ALL=C sort -z \
        | while IFS= read -r -d '' path; do
            printf '%s\t%s\n' "$(sha256sum "$path" | awk '{print $1}')" "$path"
        done
    find attestation -type f \
        ! -name artifacts.sha256 ! -name symlinks.tsv -print0 \
        | LC_ALL=C sort -z \
        | while IFS= read -r -d '' path; do
            printf '%s\t%s\n' "$(sha256sum "$path" | awk '{print $1}')" "$path"
        done
    printf '%s\t%s\n' "$(sha256sum true-ios-swiftui-dylib-probe | awk '{print $1}')" \
        true-ios-swiftui-dylib-probe
) | LC_ALL=C sort > "$AUDIT/artifacts.sha256"
(
    cd "$stage"
    find sdk apple-overlays platform-include runtime-root resources host-tools \
        -type l -print0 \
        | LC_ALL=C sort -z \
        | while IFS= read -r -d '' path; do
            target=$(readlink "$path")
            target_sha=$(printf '%s' "$target" | sha256sum | awk '{print $1}')
            printf '%s\t%s\t%s\n' "$target_sha" "$path" "$target"
        done
) > "$AUDIT/symlinks.tsv"
artifact_ledger_sha=$(sha "$AUDIT/artifacts.sha256")
symlink_ledger_sha=$(sha "$AUDIT/symlinks.tsv")
printf '%s\n' \
    "TRUE_IOS_PLATFORM_COMPLETE target=$TARGET dylibs=$((${#PUBLIC_MODULES[@]} + ${#PRIVATE_DYLIBS[@]} + ${#RUNTIME_SWIFT_MODULES[@]})) swiftui_sources=${#swiftui_sources[@]} source=$SOURCE_SUBJECT_BEFORE artifacts=$artifact_ledger_sha symlinks=$symlink_ledger_sha" \
    > "$stage/PLATFORM_COMPLETE"
python3 -B "$W/full/xcodeplan/true_ios_platform_package.py" \
    "$stage" --emit-summary

mv "$stage" "$OUTPUT_ROOT"
stage=''
trap - EXIT HUP INT TERM
echo "true_ios_platform: published $OUTPUT_ROOT"
cat "$OUTPUT_ROOT/PLATFORM_COMPLETE"
