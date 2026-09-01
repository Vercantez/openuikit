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
COPEN_FOUNDATION_CORE_INCLUDE=$W/full/foundation/include/COpenFoundationCore
FOUNDATION_INTERNATIONALIZATION_BUILDER=${FOUNDATION_INTERNATIONALIZATION_BUILDER:-$W/full/foundationinternationalization/build_foundation_internationalization.sh}
NATURAL_LANGUAGE_SOURCES_MANIFEST=${NATURAL_LANGUAGE_SOURCES_MANIFEST:-$W/full/naturallanguage/naturallanguage_guest_sources.txt}
FOUNDATION_MODELS_SOURCES_MANIFEST=${FOUNDATION_MODELS_SOURCES_MANIFEST:-$W/full/foundationmodels/foundationmodels_guest_sources.txt}
AUTHENTICATION_SERVICES_SOURCES_MANIFEST=${AUTHENTICATION_SERVICES_SOURCES_MANIFEST:-$W/full/authenticationservices/authenticationservices_guest_sources.txt}
AUTHENTICATION_SERVICES_SWIFTUI_SOURCES_MANIFEST=${AUTHENTICATION_SERVICES_SWIFTUI_SOURCES_MANIFEST:-$W/full/authenticationservices/authenticationservices_swiftui_guest_sources.txt}
ACCELERATE_SOURCES_MANIFEST=${ACCELERATE_SOURCES_MANIFEST:-$W/full/accelerate/accelerate_guest_sources.txt}
COMPRESSION_SOURCES_MANIFEST=${COMPRESSION_SOURCES_MANIFEST:-$W/full/compression/compression_guest_sources.txt}
CORETEXT_SOURCES_MANIFEST=${CORETEXT_SOURCES_MANIFEST:-$W/full/coretext/coretext_guest_sources.txt}
ACCELERATE_ORACLE=$W/full/accelerate/tests/AccelerateBoxConvolveOracle.c
ACCELERATE_GOLDEN=$W/full/accelerate/tests/accelerate-box-convolve-apple-2026-09-01.txt
COMPRESSION_HOST_TEST=$W/full/compression/tests/OpenCompressionHostTests.c
COMPRESSION_GOLDEN=$W/full/compression/tests/compression-brotli-apple-2026-09-01.txt
CORETEXT_GOLDEN=$W/full/coretext/tests/coretext-font-manager-apple-2026-09-01.txt
FOUNDATION_MODELS_MACRO_SOURCE=$W/full/foundationmodels/FoundationModelsMacros.swift
FOUNDATION_MODELS_CONSUMER=$W/full/foundationmodels/tests/IceCubesFoundationModelsConsumer.swift
FOUNDATION_MODELS_GOLDEN=$W/full/foundationmodels/tests/foundationmodels-apple-26.1.txt
NATURAL_LANGUAGE_GENERALIZATION=$W/full/naturallanguage/tests/NaturalLanguageGeneralizationOracle.swift
NATURAL_LANGUAGE_GENERALIZATION_GOLDEN=$W/full/naturallanguage/tests/naturallanguage-generalization-apple-26.1.txt
MACHO_DEPENDENCY_REWRITER=$W/full/xcodeplan/rewrite_macho_dependency.py
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
    llvm-nm-18 llvm-objdump-18 llvm-otool-18 file sha256sum readelf ldd \
    readlink; do
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
[ -f "$COPEN_FOUNDATION_CORE_INCLUDE/OpenFoundationCFError.h" ] \
    && [ ! -L "$COPEN_FOUNDATION_CORE_INCLUDE/OpenFoundationCFError.h" ] \
    || die 'COpenFoundationCore CFError header is missing'
[ -f "$COPEN_FOUNDATION_CORE_INCLUDE/module.modulemap" ] \
    && [ ! -L "$COPEN_FOUNDATION_CORE_INCLUDE/module.modulemap" ] \
    || die 'COpenFoundationCore module map is missing'
[ -f "$FOUNDATION_INTERNATIONALIZATION_BUILDER" ] \
    && [ ! -L "$FOUNDATION_INTERNATIONALIZATION_BUILDER" ] \
    || die 'FoundationInternationalization builder is missing'
for manifest in "$NATURAL_LANGUAGE_SOURCES_MANIFEST" \
    "$FOUNDATION_MODELS_SOURCES_MANIFEST" \
    "$AUTHENTICATION_SERVICES_SOURCES_MANIFEST" \
    "$AUTHENTICATION_SERVICES_SWIFTUI_SOURCES_MANIFEST" \
    "$ACCELERATE_SOURCES_MANIFEST" "$COMPRESSION_SOURCES_MANIFEST" \
    "$CORETEXT_SOURCES_MANIFEST"; do
    [ -f "$manifest" ] && [ ! -L "$manifest" ] \
        || die "first-party framework source manifest is missing: $manifest"
    git -C "$W" ls-files --error-unmatch "${manifest#"$W/"}" >/dev/null \
        || die "first-party framework source manifest is not tracked: $manifest"
    while IFS= read -r relative; do
        [ -n "$relative" ] || continue
        [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
            || die "first-party framework source is missing or linked: $relative"
        git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
            || die "first-party framework source is not tracked: $relative"
    done < "$manifest"
done
[ -f "$W/full/authenticationservices/SwiftUI.swiftoverlay" ] \
    && [ ! -L "$W/full/authenticationservices/SwiftUI.swiftoverlay" ] \
    || die 'AuthenticationServices cross-import overlay declaration is missing'
FOUNDATION_MODELS_NATURAL_LANGUAGE_SUPPORT_INPUTS=(
    full/foundationmodels/FoundationModelsMacros.swift
    full/foundationmodels/tests/FoundationModelsMacroOracle.swift
    full/foundationmodels/tests/FoundationModelsNativeOracle.swift
    full/foundationmodels/tests/IceCubesFoundationModelsConsumer.swift
    full/foundationmodels/tests/foundationmodels-apple-26.1.txt
    full/foundationmodels/tests/icecubes_foundationmodels_frontier.tsv
    full/naturallanguage/tests/IceCubesNaturalLanguageConsumers.swift
    full/naturallanguage/tests/NaturalLanguageGeneralizationOracle.swift
    full/naturallanguage/tests/NaturalLanguageIceCubesOracle.swift
    full/naturallanguage/tests/NaturalLanguageNativeOracle.swift
    full/naturallanguage/tests/icecubes_naturallanguage_frontier.tsv
    full/naturallanguage/tests/naturallanguage-apple-26.1.txt
    full/naturallanguage/tests/naturallanguage-generalization-apple-26.1.txt
)
FRONTIER_SUPPORT_INPUTS=(
    "${FOUNDATION_MODELS_NATURAL_LANGUAGE_SUPPORT_INPUTS[@]}"
    full/accelerate/Accelerate.c
    full/accelerate/include/Accelerate.h
    full/accelerate/include/module.modulemap
    full/accelerate/tests/AccelerateBoxConvolveOracle.c
    full/accelerate/tests/AccelerateGuestRuntime.swift
    full/accelerate/tests/accelerate-box-convolve-apple-2026-09-01.txt
    full/compression/OpenCompressionBridge.c
    full/compression/OpenCompressionHost.c
    full/compression/include/OpenCompressionABI.h
    full/compression/include/module.modulemap
    full/compression/tests/CompressionBrotliOracle.swift
    full/compression/tests/CompressionGuestRuntime.swift
    full/compression/tests/OpenCompressionHostTests.c
    full/compression/tests/compression-brotli-apple-2026-09-01.txt
    full/coretext/tests/CoreTextFontManagerOracle.swift
    full/coretext/tests/CoreTextGuestRuntime.swift
    full/coretext/tests/coretext-font-manager-apple-2026-09-01.txt
)
for relative in "${FRONTIER_SUPPORT_INPUTS[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "frontier supporting input is missing or linked: $relative"
    git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
        || die "frontier supporting input is not tracked: $relative"
done
[ -f "$SYSTEM_FONT" ] && [ ! -L "$SYSTEM_FONT" ] \
    || die "system font input is missing: $SYSTEM_FONT"
[ -f "$BOLD_FONT" ] && [ ! -L "$BOLD_FONT" ] \
    || die "bold font input is missing: $BOLD_FONT"
[ -f "$MACHO_DEPENDENCY_REWRITER" ] \
    && [ ! -L "$MACHO_DEPENDENCY_REWRITER" ] \
    || die 'Mach-O dependency rewriter is missing'
git -C "$W" ls-files --error-unmatch \
    "${MACHO_DEPENDENCY_REWRITER#"$W/"}" >/dev/null \
    || die 'Mach-O dependency rewriter is not tracked'
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

{
    printf 'format\ttrue-ios-foundationmodels-naturallanguage-sources-v1\n'
    {
        for manifest in "$FOUNDATION_MODELS_SOURCES_MANIFEST" \
            "$NATURAL_LANGUAGE_SOURCES_MANIFEST"; do
            printf 'source\t%s\t%s\n' "${manifest#"$W/"}" "$(sha "$manifest")"
            while IFS= read -r relative; do
                [ -n "$relative" ] || continue
                printf 'source\t%s\t%s\n' "$relative" "$(sha "$W/$relative")"
            done < "$manifest"
        done
        for relative in \
            "${FOUNDATION_MODELS_NATURAL_LANGUAGE_SUPPORT_INPUTS[@]}"; do
            printf 'source\t%s\t%s\n' "$relative" "$(sha "$W/$relative")"
        done
    } | LC_ALL=C sort
} > "$AUDIT/foundationmodels-naturallanguage-sources.tsv"

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
            full/xcodeplan/build_true_ios_platform_frameworks.sh \
            full/xcodeplan/true_ios_platform_package.py \
            full/xcodeplan/rewrite_macho_dependency.py \
            full/xcodeplan/tests/TrueIOSSwiftUIDylibProbe.swift \
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
            full/observation/ObservationRuntimeBridge.c \
            full/foundation/include/COpenFoundationCore/OpenFoundationCFError.h \
            full/foundation/include/COpenFoundationCore/module.modulemap; do
            printf '%s\t%s\n' "$support_source" "$(sha "$W/$support_source")"
        done
        while IFS= read -r relative; do
            [ -n "$relative" ] || continue
            printf '%s\t%s\n' "$relative" "$(sha "$W/$relative")"
        done < "$W/full/observation/observation_guest_sources.txt"
        for manifest in "$NATURAL_LANGUAGE_SOURCES_MANIFEST" \
            "$FOUNDATION_MODELS_SOURCES_MANIFEST" \
            "$AUTHENTICATION_SERVICES_SOURCES_MANIFEST" \
            "$AUTHENTICATION_SERVICES_SWIFTUI_SOURCES_MANIFEST" \
            "$ACCELERATE_SOURCES_MANIFEST" "$COMPRESSION_SOURCES_MANIFEST" \
            "$CORETEXT_SOURCES_MANIFEST"; do
            printf '%s\t%s\n' "${manifest#"$W"/}" "$(sha "$manifest")"
            while IFS= read -r relative; do
                [ -n "$relative" ] || continue
                printf '%s\t%s\n' "$relative" "$(sha "$W/$relative")"
            done < "$manifest"
        done
        printf '%s\t%s\n' full/authenticationservices/SwiftUI.swiftoverlay \
            "$(sha "$W/full/authenticationservices/SwiftUI.swiftoverlay")"
        for relative in "${FRONTIER_SUPPORT_INPUTS[@]}"; do
            printf '%s\t%s\n' "$relative" "$(sha "$W/$relative")"
        done
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

# The Apple simulator Swift runtime names Foundation by its framework path.
# Our public framework intentionally installs the portable implementation as
# /usr/lib/libFoundation.dylib.  Leaving both identities in the cold closure
# maps the same image twice under machorun and registers every Foundation ObjC
# class twice.  Rewrite exactly the six measured Apple runtime clients before
# any probe runs, without changing Mach-O layout, and publish the complete
# input/output hash and dependency-identity proof.
APPLE_FOUNDATION_LOAD=/System/Library/Frameworks/Foundation.framework/Foundation
PORTABLE_FOUNDATION_LOAD=/usr/lib/libFoundation.dylib
RUNTIME_FOUNDATION_LOAD_CLIENTS=(
    libswiftCore.dylib
    libswiftSynchronization.dylib
    libswift_Builtin_float.dylib
    libswift_Concurrency.dylib
    libswift_RegexParser.dylib
    libswift_StringProcessing.dylib
)
{
    printf 'format\ttrue-ios-runtime-foundation-load-rewrites-v1\n'
    printf 'policy\tportable-foundation-identity\tcode-signature=not-enforced-by-machorun\n'
    for library in "${RUNTIME_FOUNDATION_LOAD_CLIENTS[@]}"; do
        relative=runtime-root/darwin/usr/lib/swift/$library
        binary=$stage/$relative
        [ -f "$binary" ] && [ ! -L "$binary" ] \
            || die "runtime Foundation load client is missing: $relative"
        before_sha=$(sha "$binary")
        old_before=$(llvm-otool-18 -L "$binary" \
            | awk -v name="$APPLE_FOUNDATION_LOAD" \
                '$1 == name { count++ } END { print count + 0 }')
        new_before=$(llvm-otool-18 -L "$binary" \
            | awk -v name="$PORTABLE_FOUNDATION_LOAD" \
                '$1 == name { count++ } END { print count + 0 }')
        [ "$old_before" -eq 1 ] && [ "$new_before" -eq 0 ] \
            || die "runtime Foundation load input drifted: $relative old=$old_before new=$new_before"
        python3 -B "$MACHO_DEPENDENCY_REWRITER" "$binary" \
            "$APPLE_FOUNDATION_LOAD" "$PORTABLE_FOUNDATION_LOAD"
        old_after=$(llvm-otool-18 -L "$binary" \
            | awk -v name="$APPLE_FOUNDATION_LOAD" \
                '$1 == name { count++ } END { print count + 0 }')
        new_after=$(llvm-otool-18 -L "$binary" \
            | awk -v name="$PORTABLE_FOUNDATION_LOAD" \
                '$1 == name { count++ } END { print count + 0 }')
        [ "$old_after" -eq 0 ] && [ "$new_after" -eq 1 ] \
            || die "runtime Foundation load rewrite failed: $relative old=$old_after new=$new_after"
        printf 'runtime-load\t%s\tinput=%s\toutput=%s\told=1\tnew=1\n' \
            "$relative" "$before_sha" "$(sha "$binary")"
    done
} > "$AUDIT/runtime-foundation-load-rewrites.tsv"
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
cp -a "$COPEN_FOUNDATION_CORE_INCLUDE" "$INCLUDE/COpenFoundationCore"
cp -a "$W/full/accelerate/include" "$INCLUDE/COpenAccelerate"
cp -a "$W/full/compression/include" "$INCLUDE/COpenCompression"
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

CROSS_IMPORT_FLAGS=(-Xfrontend -enable-cross-import-overlays)
SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS" -I "$APPLE_SWIFT_USER_OVERLAYS"
    -module-cache-path "$MODULE_CACHE" -runtime-compatibility-version none -wmo
    "${CROSS_IMPORT_FLAGS[@]}"
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
    -Xcc -fmodule-map-file="$INCLUDE/COpenFoundationCore/module.modulemap"
    -Xcc -I"$INCLUDE/COpenFoundationCore"
    -Xcc -fmodule-map-file="$INCLUDE/COpenAccelerate/module.modulemap"
    -Xcc -I"$INCLUDE/COpenAccelerate"
    -Xcc -fmodule-map-file="$INCLUDE/COpenCompression/module.modulemap"
    -Xcc -I"$INCLUDE/COpenCompression"
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

echo '== Accelerate Apple differential and true-iOS vImage object'
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$INCLUDE/COpenAccelerate" \
    "$W/full/accelerate/Accelerate.c" "$ACCELERATE_ORACLE" \
    -o "$BUILD/accelerate-native-oracle"
"$BUILD/accelerate-native-oracle" \
    > "$AUDIT/accelerate-apple-differential.log"
cmp "$ACCELERATE_GOLDEN" "$AUDIT/accelerate-apple-differential.log" \
    || die 'portable Accelerate output differs from the frozen Apple transcript'
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$INCLUDE/COpenAccelerate" \
    -c "$W/full/accelerate/Accelerate.c" \
    -o "$BUILD/AccelerateC.o"

echo '== fixed-ABI Brotli Compression boundary'
BROTLI_DECODER=$(readlink -f /lib/aarch64-linux-gnu/libbrotlidec.so.1)
BROTLI_ENCODER=$(readlink -f /lib/aarch64-linux-gnu/libbrotlienc.so.1)
BROTLI_COMMON=$(readlink -f /lib/aarch64-linux-gnu/libbrotlicommon.so.1)
for brotli_library in "$BROTLI_DECODER" "$BROTLI_ENCODER" "$BROTLI_COMMON"; do
    [ -f "$brotli_library" ] && [ ! -L "$brotli_library" ] \
        || die "pinned Brotli runtime is not a regular file: $brotli_library"
    case "$brotli_library" in
        /usr/lib/aarch64-linux-gnu/libbrotli*.so.1.1.0) ;;
        *) die "pinned Brotli runtime resolved outside exact closure: $brotli_library" ;;
    esac
done
COMPRESSION_HOST=$RUNTIME_ROOT/host/libOpenCompressionHost.so
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$INCLUDE/COpenCompression" -shared \
    "$W/full/compression/OpenCompressionHost.c" \
    -o "$COMPRESSION_HOST" \
    "$BROTLI_DECODER" "$BROTLI_ENCODER" "$BROTLI_COMMON"
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$INCLUDE/COpenCompression" \
    "$W/full/compression/OpenCompressionHost.c" "$COMPRESSION_HOST_TEST" \
    -o "$BUILD/open-compression-host-tests" \
    "$BROTLI_DECODER" "$BROTLI_ENCODER" "$BROTLI_COMMON"
"$BUILD/open-compression-host-tests" \
    > "$AUDIT/open-compression-host-test.log"
grep -Fx \
    'OPEN_COMPRESSION_HOST_OK algorithm=brotli roundtrip=exact malformed=fail-closed limit=hard abi=v1' \
    "$AUDIT/open-compression-host-test.log" >/dev/null \
    || die 'native Compression semantic marker is missing'
printf '%s\n' openui_compression_v1_release openui_compression_v1_transform \
    > "$BUILD/open-compression-expected-elf.txt"
readelf --wide --syms "$COMPRESSION_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_compression_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$BUILD/open-compression-elf-exports.txt"
cmp "$BUILD/open-compression-expected-elf.txt" \
    "$BUILD/open-compression-elf-exports.txt" \
    || die 'Linux Compression helper exports drifted'
readelf --wide --file-header "$COMPRESSION_HOST" \
    | grep -Fq 'Machine:                           AArch64' \
    || die 'Linux Compression helper is not ELF AArch64'
LD_LIBRARY_PATH="$RUNTIME_ROOT/host" ldd "$COMPRESSION_HOST" \
    | grep -Fq 'not found' \
    && die 'Linux Compression helper closure is incomplete'

clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$INCLUDE/COpenCompression" \
    -c "$W/full/compression/OpenCompressionBridge.c" \
    -o "$BUILD/OpenCompressionBridge.o"
printf '%s\n' _openui_compression_v1_release _openui_compression_v1_transform \
    > "$BUILD/open-compression-expected-mach-exports.txt"
printf '%s\n' _glibc_openui_compression_v1_release \
    _glibc_openui_compression_v1_transform \
    > "$BUILD/open-compression-expected-mach-imports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$BUILD/OpenCompressionBridge.o" | LC_ALL=C sort -u \
    > "$BUILD/open-compression-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$BUILD/OpenCompressionBridge.o" | LC_ALL=C sort -u \
    > "$BUILD/open-compression-mach-imports.txt"
cmp "$BUILD/open-compression-expected-mach-exports.txt" \
    "$BUILD/open-compression-mach-exports.txt" \
    || die 'Mach-O Compression bridge exports drifted'
cmp "$BUILD/open-compression-expected-mach-imports.txt" \
    "$BUILD/open-compression-mach-imports.txt" \
    || die 'Mach-O Compression host imports drifted'

readelf --wide --dynamic "$COMPRESSION_HOST" \
    | awk '$2 == "(NEEDED)" { value=$5; gsub(/^\[|\]$/, "", value); print value }' \
    | LC_ALL=C sort -u > "$BUILD/open-compression-direct-sonames.txt"
ldd "$COMPRESSION_HOST" \
    | awk '/=>/ { print $1; next } /^[[:space:]]*\// { count=split($1, part, "/"); print part[count] }' \
    | LC_ALL=C sort -u > "$BUILD/open-compression-transitive-sonames.txt"
for required_soname in libbrotlidec.so.1 libbrotlienc.so.1 \
    libbrotlicommon.so.1; do
    grep -Fx "$required_soname" \
        "$BUILD/open-compression-transitive-sonames.txt" >/dev/null \
        || die "Linux Compression closure does not contain $required_soname"
done
{
    printf 'format\topen-compression-host-v1\n'
    printf 'host-abi\tELF64-AArch64\n'
    printf 'algorithm\tbrotli\tencode=real\tdecode=real\n'
    printf 'limits\tguest-input=256MiB\tguest-output=256MiB\n'
    printf 'apple-transcript\t%s\n' "$(sha "$COMPRESSION_GOLDEN")"
    while IFS= read -r soname; do
        printf 'direct-soname\t%s\n' "$soname"
    done < "$BUILD/open-compression-direct-sonames.txt"
    while IFS= read -r soname; do
        printf 'transitive-soname\t%s\n' "$soname"
    done < "$BUILD/open-compression-transitive-sonames.txt"
} > "$AUDIT/open-compression-host.tsv"
{
    printf 'format\topen-compression-abi-v1\n'
    printf 'response-layout\tsize=24\tpointers=64-bit\n'
    printf 'symbol\topenui_compression_v1_transform\tguest-export=_openui_compression_v1_transform\tguest-host-import=_glibc_openui_compression_v1_transform\thost-export=openui_compression_v1_transform\n'
    printf 'symbol\topenui_compression_v1_release\tguest-export=_openui_compression_v1_release\tguest-host-import=_glibc_openui_compression_v1_release\thost-export=openui_compression_v1_release\n'
} > "$AUDIT/open-compression-abi.tsv"
cp "$COMPRESSION_GOLDEN" "$AUDIT/compression-brotli-apple.txt"
cp "$CORETEXT_GOLDEN" "$AUDIT/coretext-font-manager-apple.txt"

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

echo '== portable Dispatch and 33-source public Foundation facade'
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
[ "${#foundation_relative_sources[@]}" -eq 33 ] \
    || die "Foundation source denominator is ${#foundation_relative_sources[@]}, expected 33"
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
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$PRODUCTS/libFoundation.dylib" | LC_ALL=C sort -u \
    > "$AUDIT/foundation-runtime-exports.txt"
llvm-nm-18 -u -j "$BUILD/Foundation.o" | LC_ALL=C sort -u \
    > "$AUDIT/foundation-runtime-undefineds.txt"
for forbidden in _CFErrorGetDomain _CFErrorGetCode _CFErrorCopyUserInfo; do
    [ "$(grep -Fxc "$forbidden" "$AUDIT/foundation-runtime-undefineds.txt")" -eq 0 ] \
        || die "Foundation CFError bridge eagerly imports absent C API: $forbidden"
done
for symbol in \
    '_$s10Foundation24_getErrorDefaultUserInfoyyXlSgxs0C0RzlF' \
    '_$s10Foundation21_bridgeNSErrorToError_3outSbSo0C0C_SpyxGtAA021_ObjectiveCBridgeableE0RzlF' \
    '_$s10Foundation26_ObjectiveCBridgeableErrorMp' \
    '_$sSo10CFErrorRefas5Error10FoundationMc'; do
    [ "$(grep -Fxc "$symbol" "$AUDIT/foundation-runtime-exports.txt")" -eq 1 ] \
        || die "Foundation runtime bridge export is missing or duplicated: $symbol"
done

echo '== six relocatable first-party compiler-library plugins'
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
swiftc -parse-as-library -emit-library -module-name FoundationModelsMacros \
    -no-toolchain-stdlib-rpath -I /usr/lib/swift/host -L /usr/lib/swift/host \
    -Xlinker -rpath -Xlinker '$ORIGIN/..' \
    -Xlinker -rpath -Xlinker '$ORIGIN/../../../swift/linux' \
    "$FOUNDATION_MODELS_MACRO_SOURCE" \
    -o "$HOST_TOOLS/swift/host/plugins/libFoundationModelsMacros.so"
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
    -load-plugin-library "$HOST_TOOLS/swift/host/plugins/libFoundationModelsMacros.so"
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
        FoundationModelsMacros \
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

echo '== FoundationModels, NaturalLanguage, and AuthenticationServices frameworks'
mapfile -t foundation_models_relative_sources \
    < "$FOUNDATION_MODELS_SOURCES_MANIFEST"
[ "${#foundation_models_relative_sources[@]}" -eq 1 ] \
    || die 'FoundationModels source denominator drifted'
foundation_models_sources=()
for relative in "${foundation_models_relative_sources[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "FoundationModels source is missing or linked: $relative"
    foundation_models_sources+=("$W/$relative")
done
mapfile -t natural_language_relative_sources \
    < "$NATURAL_LANGUAGE_SOURCES_MANIFEST"
[ "${#natural_language_relative_sources[@]}" -eq 1 ] \
    || die 'NaturalLanguage source denominator drifted'
natural_language_sources=()
for relative in "${natural_language_relative_sources[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "NaturalLanguage source is missing or linked: $relative"
    natural_language_sources+=("$W/$relative")
done
mapfile -t authentication_services_relative_sources \
    < "$AUTHENTICATION_SERVICES_SOURCES_MANIFEST"
[ "${#authentication_services_relative_sources[@]}" -eq 1 ] \
    || die 'AuthenticationServices source denominator drifted'
authentication_services_sources=()
for relative in "${authentication_services_relative_sources[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "AuthenticationServices source is missing or linked: $relative"
    authentication_services_sources+=("$W/$relative")
done
mapfile -t authentication_services_swiftui_relative_sources \
    < "$AUTHENTICATION_SERVICES_SWIFTUI_SOURCES_MANIFEST"
[ "${#authentication_services_swiftui_relative_sources[@]}" -eq 1 ] \
    || die 'AuthenticationServices SwiftUI source denominator drifted'
authentication_services_swiftui_sources=()
for relative in "${authentication_services_swiftui_relative_sources[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "AuthenticationServices SwiftUI source is missing or linked: $relative"
    authentication_services_swiftui_sources+=("$W/$relative")
done

"${SWIFTC[@]}" "${CFLAGS[@]}" "${FOUNDATION_CFLAGS[@]}" \
    "${FE_FLAGS[@]}" "${PLUGIN_FLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name FoundationModels -emit-module \
    -emit-module-path "$PACKAGE/FoundationModels.swiftmodule" \
    -emit-object -o "$BUILD/FoundationModels.o" \
    "${foundation_models_sources[@]}"
"${SWIFTC[@]}" "${CFLAGS[@]}" "${FOUNDATION_CFLAGS[@]}" \
    "${FE_FLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name NaturalLanguage -emit-module \
    -emit-module-path "$PACKAGE/NaturalLanguage.swiftmodule" \
    -emit-object -o "$BUILD/NaturalLanguage.o" \
    "${natural_language_sources[@]}"
"${SWIFTC[@]}" "${CFLAGS[@]}" "${FOUNDATION_CFLAGS[@]}" \
    "${FE_FLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name AuthenticationServices -emit-module \
    -emit-module-path "$PACKAGE/AuthenticationServices.swiftmodule" \
    -emit-object -o "$BUILD/AuthenticationServices.o" \
    "${authentication_services_sources[@]}"
"${SWIFTC[@]}" "${CFLAGS[@]}" "${FOUNDATION_CFLAGS[@]}" \
    "${FE_FLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name _AuthenticationServices_SwiftUI -emit-module \
    -emit-module-path \
        "$PACKAGE/_AuthenticationServices_SwiftUI.swiftmodule" \
    -emit-object -o "$BUILD/AuthenticationServicesSwiftUI.o" \
    "${authentication_services_swiftui_sources[@]}"
mkdir -p "$PACKAGE/AuthenticationServices.swiftcrossimport"
cp "$W/full/authenticationservices/SwiftUI.swiftoverlay" \
    "$PACKAGE/AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay"

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name /usr/lib/libFoundationModels.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials "${COMMON_RUNTIME[@]}" \
    -lswiftObjectiveC -lswift_Concurrency -lobjc \
    -o "$PRODUCTS/libFoundationModels.dylib" \
    "$BUILD/FoundationModels.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$PRODUCTS/libFoundationModels.dylib" | LC_ALL=C sort -u \
    > "$AUDIT/foundationmodels-runtime-exports.txt"
for symbol in \
    '_$s16FoundationModels16GeneratedContentV10jsonStringSSvg' \
    '_$s16FoundationModels19SystemLanguageModelC7defaultACvgZ' \
    '_$s16FoundationModels20LanguageModelSessionC7respond2to10generating21includeSchemaInPrompt7optionsAC8ResponseVy_xGSS_xmSbAA17GenerationOptionsVtYaKAA9GenerableRzlF' \
    '_$s16FoundationModels20LanguageModelSessionC14streamResponse2to10generating21includeSchemaInPrompt7optionsAC0G6StreamVy_xGSS_xmSbAA17GenerationOptionsVtAA9GenerableRzlF'; do
    [ "$(grep -Fxc "$symbol" "$AUDIT/foundationmodels-runtime-exports.txt")" -eq 1 ] \
        || die "FoundationModels runtime export is missing or duplicated: $symbol"
done
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name /usr/lib/libNaturalLanguage.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lFoundation -lFoundationEssentials \
    "${COMMON_RUNTIME[@]}" -lswiftObjectiveC -lobjc \
    -o "$PRODUCTS/libNaturalLanguage.dylib" "$BUILD/NaturalLanguage.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name /usr/lib/libAuthenticationServices.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lFoundation -lFoundationEssentials \
    "${COMMON_RUNTIME[@]}" -lswiftObjectiveC -lswift_Concurrency -lobjc \
    -o "$PRODUCTS/libAuthenticationServices.dylib" \
    "$BUILD/AuthenticationServices.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name /usr/lib/lib_AuthenticationServices_SwiftUI.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lAuthenticationServices -lSwiftUI -lFoundation \
    -lFoundationEssentials "${COMMON_RUNTIME[@]}" \
    -lswiftObjectiveC -lswift_Concurrency -lobjc \
    -o "$PRODUCTS/lib_AuthenticationServices_SwiftUI.dylib" \
    "$BUILD/AuthenticationServicesSwiftUI.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

echo '== Accelerate, Compression, and CoreText first-party frameworks'
mapfile -t accelerate_relative_sources < "$ACCELERATE_SOURCES_MANIFEST"
mapfile -t compression_relative_sources < "$COMPRESSION_SOURCES_MANIFEST"
mapfile -t coretext_relative_sources < "$CORETEXT_SOURCES_MANIFEST"
[ "${#accelerate_relative_sources[@]}" -eq 1 ] \
    || die 'Accelerate source denominator drifted'
[ "${#compression_relative_sources[@]}" -eq 1 ] \
    || die 'Compression source denominator drifted'
[ "${#coretext_relative_sources[@]}" -eq 1 ] \
    || die 'CoreText source denominator drifted'
for relative in "${accelerate_relative_sources[@]}" \
    "${compression_relative_sources[@]}" "${coretext_relative_sources[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "first-party source is missing or linked: $relative"
done

"${SWIFTC[@]}" "${CFLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name Accelerate -emit-module \
    -emit-module-path "$PACKAGE/Accelerate.swiftmodule" \
    -emit-object -o "$BUILD/Accelerate.o" \
    "$W/${accelerate_relative_sources[0]}"
"${SWIFTC[@]}" "${CFLAGS[@]}" "${FOUNDATION_CFLAGS[@]}" \
    "${FE_FLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name Compression -emit-module \
    -emit-module-path "$PACKAGE/Compression.swiftmodule" \
    -emit-object -o "$BUILD/Compression.o" \
    "$W/${compression_relative_sources[0]}"
"${SWIFTC[@]}" "${CFLAGS[@]}" "${FOUNDATION_CFLAGS[@]}" \
    "${FE_FLAGS[@]}" -parse-as-library -I "$PACKAGE" \
    -module-name CoreText -emit-module \
    -emit-module-path "$PACKAGE/CoreText.swiftmodule" \
    -emit-object -o "$BUILD/CoreText.o" \
    "$W/${coretext_relative_sources[0]}"

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name /usr/lib/libAccelerate.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    "${COMMON_RUNTIME[@]}" -o "$PRODUCTS/libAccelerate.dylib" \
    "$BUILD/Accelerate.o" "$BUILD/AccelerateC.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link -undefined dynamic_lookup \
    -install_name /usr/lib/libCompression.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lFoundation -lFoundationEssentials \
    "${COMMON_RUNTIME[@]}" -lswiftObjectiveC -lobjc \
    -o "$PRODUCTS/libCompression.dylib" \
    "$BUILD/Compression.o" "$BUILD/OpenCompressionBridge.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name /usr/lib/libCoreText.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lFoundation -lFoundationEssentials \
    "${COMMON_RUNTIME[@]}" -lswiftObjectiveC -lobjc \
    -o "$PRODUCTS/libCoreText.dylib" "$BUILD/CoreText.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

[ "$(llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$PRODUCTS/libAccelerate.dylib" \
    | awk '$0 == "_vImageBoxConvolve_ARGB8888" { count++ } END { print count + 0 }')" \
    -eq 1 ] || die 'libAccelerate vImage export count drifted'
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$PRODUCTS/libCompression.dylib" \
    | awk '$0 ~ /^_openui_compression_v1_/ { print }' | LC_ALL=C sort -u \
    > "$BUILD/libcompression-c-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$PRODUCTS/libCompression.dylib" \
    | awk '$0 ~ /^_glibc_openui_compression_v1_/ { print }' | LC_ALL=C sort -u \
    > "$BUILD/libcompression-host-imports.txt"
cmp "$BUILD/open-compression-expected-mach-exports.txt" \
    "$BUILD/libcompression-c-exports.txt" \
    || die 'libCompression C exports drifted'
cmp "$BUILD/open-compression-expected-mach-imports.txt" \
    "$BUILD/libcompression-host-imports.txt" \
    || die 'libCompression host imports drifted'
if llvm-otool-18 -L "$PRODUCTS/libCompression.dylib" | grep -Fq libbrotli; then
    die 'libCompression must cross the fixed host ABI instead of loading Brotli'
fi
for module in Accelerate Compression CoreText; do
    if llvm-otool-18 -L "$PRODUCTS/lib$module.dylib" \
        | grep -Fq "/System/Library/Frameworks/$module.framework/"; then
        die "portable lib$module loads the Apple $module framework"
    fi
done

cp -a "$INCLUDE/." "$PUBLISHED_INCLUDE/"
PUBLIC_MODULES=(
    FoundationEssentials FoundationInternationalization Foundation Dispatch
    OpenCoreGraphics OpenUIKit DeveloperToolsSupport UIKit OpenCombine Combine
    Symbols SwiftUI FoundationModels NaturalLanguage AuthenticationServices
    _AuthenticationServices_SwiftUI Accelerate Compression CoreText
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
mkdir -p \
    "$FRAMEWORKS/AuthenticationServices.framework/Modules/AuthenticationServices.swiftcrossimport"
cp "$PACKAGE/AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay" \
    "$FRAMEWORKS/AuthenticationServices.framework/Modules/AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay"

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
    -Xcc -fmodule-map-file="$PUBLISHED_INCLUDE/COpenFoundationCore/module.modulemap"
    -Xcc -I"$PUBLISHED_INCLUDE/COpenFoundationCore"
    -Xcc -fmodule-map-file="$PUBLISHED_INCLUDE/COpenAccelerate/module.modulemap"
    -Xcc -I"$PUBLISHED_INCLUDE/COpenAccelerate"
    -Xcc -fmodule-map-file="$PUBLISHED_INCLUDE/COpenCompression/module.modulemap"
    -Xcc -I"$PUBLISHED_INCLUDE/COpenCompression"
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
    "${CROSS_IMPORT_FLAGS[@]}" \
    -Xfrontend -disable-implicit-string-processing-module-import \
    -Xfrontend -disable-objc-attr-requires-foundation-module \
    "${PROBE_CFLAGS[@]}" "${PLUGIN_FLAGS[@]}" -parse-as-library \
    -module-name TrueIOSSwiftUIDylibProbe -emit-object \
    -o "$BUILD/true-ios-swiftui-dylib-probe.o" "$PROBE_SOURCE" \
    2> "$AUDIT/framework-module-loading.log"; then
    cat "$AUDIT/framework-module-loading.log" >&2
    die 'framework-only consumer compile failed'
fi
for module in SwiftUI UIKit Foundation Dispatch Symbols OpenUIKit Combine \
    OpenCombine FoundationModels NaturalLanguage AuthenticationServices \
    _AuthenticationServices_SwiftUI Accelerate Compression CoreText; do
    expected_module_path="$FRAMEWORKS/$module.framework/Modules/$module.swiftmodule/$TARGET_VARIANT.swiftmodule"
    grep -Fq "loaded module '$module'; source: '$expected_module_path'" \
        "$AUDIT/framework-module-loading.log" \
        || die "$module was not loaded from its published framework module"
done
"${LD[@]}" -dead_strip -exported_symbol __mh_execute_header \
    -rpath @loader_path -F"$FRAMEWORKS" -framework SwiftUI -framework UIKit \
    -framework FoundationModels -framework NaturalLanguage \
    -framework AuthenticationServices \
    -framework _AuthenticationServices_SwiftUI -framework Accelerate \
    -framework Compression -framework CoreText \
    -L"$PRODUCTS" -lFoundation -lFoundationInternationalization -lDispatch \
    -lOpenUIKit -lOpenCoreGraphics -lFoundationEssentials \
    -lDeveloperToolsSupport -lCombine -lOpenCombine -lSymbols -l_FoundationICU \
    "${COMMON_RUNTIME[@]}" -lswiftObjectiveC -lswift_Concurrency -lobjc \
    "$OBSERVATION_DYLIB" \
    -o "$stage/true-ios-swiftui-dylib-probe" \
    "$BUILD/true-ios-swiftui-dylib-probe.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

echo '== exact FoundationModels macro consumer and 29-row NaturalLanguage oracle'
DOWNSTREAM_SWIFTC=(swiftc -target "$TARGET" -sdk "$SDK_OUT"
    -I "$APPLE_OVERLAYS_OUT" -F "$FRAMEWORKS"
    -runtime-compatibility-version none
    -Xfrontend -disable-objc-attr-requires-foundation-module)
PUBLISHED_FOUNDATION_MODELS_PLUGIN=$HOST_TOOLS/swift/host/plugins/libFoundationModelsMacros.so

"${DOWNSTREAM_SWIFTC[@]}" "${PROBE_CFLAGS[@]}" \
    -module-cache-path "$BUILD/foundationmodels-macro-module-cache" \
    -load-plugin-library "$PUBLISHED_FOUNDATION_MODELS_PLUGIN" \
    -parse-as-library -typecheck -dump-macro-expansions \
    "$FOUNDATION_MODELS_CONSUMER" \
    > "$AUDIT/foundationmodels-macro-expansions.log" 2>&1
for expansion in \
    'static var generationSchema' \
    'var generatedContent' \
    'struct PartiallyGenerated' \
    'extension Tags: FoundationModels.Generable' \
    'guides: [.count(5)]'; do
    grep -Fq "$expansion" "$AUDIT/foundationmodels-macro-expansions.log" \
        || die "FoundationModels macro expansion is missing: $expansion"
done
"${DOWNSTREAM_SWIFTC[@]}" "${PROBE_CFLAGS[@]}" \
    -module-cache-path "$BUILD/foundationmodels-consumer-module-cache" \
    -load-plugin-library "$PUBLISHED_FOUNDATION_MODELS_PLUGIN" \
    -Rmodule-loading -parse-as-library \
    -module-name IceCubesFoundationModelsConsumer -emit-object \
    -o "$BUILD/IceCubesFoundationModelsConsumer.o" \
    "$FOUNDATION_MODELS_CONSUMER" \
    2>> "$AUDIT/framework-module-loading.log"
"${LD[@]}" -dead_strip -exported_symbol __mh_execute_header \
    -rpath @loader_path -F"$FRAMEWORKS" -framework FoundationModels \
    -L"$PRODUCTS" -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials "${COMMON_RUNTIME[@]}" \
    -lswiftObjectiveC -lswift_Concurrency -lobjc \
    -o "$stage/foundationmodels-icecubes-probe" \
    "$BUILD/IceCubesFoundationModelsConsumer.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

"${DOWNSTREAM_SWIFTC[@]}" "${PROBE_CFLAGS[@]}" \
    -module-cache-path "$BUILD/naturallanguage-generalization-module-cache" \
    -Rmodule-loading -module-name NaturalLanguageGeneralizationOracle \
    -emit-object -o "$BUILD/NaturalLanguageGeneralizationOracle.o" \
    "$NATURAL_LANGUAGE_GENERALIZATION" \
    2>> "$AUDIT/framework-module-loading.log"
"${LD[@]}" -dead_strip -exported_symbol __mh_execute_header \
    -rpath @loader_path -F"$FRAMEWORKS" -framework NaturalLanguage \
    -L"$PRODUCTS" -lFoundation -lFoundationInternationalization \
    -lFoundationEssentials "${COMMON_RUNTIME[@]}" \
    -lswiftObjectiveC -lobjc \
    -o "$stage/naturallanguage-generalization-probe" \
    "$BUILD/NaturalLanguageGeneralizationOracle.o" \
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
for probe_name in foundationmodels-icecubes-probe \
    naturallanguage-generalization-probe; do
    probe_binary="$stage/$probe_name"
    file "$probe_binary" | grep -Fq 'Mach-O 64-bit arm64 executable' \
        || die "$probe_name is not an ARM64 Mach-O executable"
    probe_headers=$(llvm-objdump-18 --macho --private-headers "$probe_binary")
    grep -Fq 'platform iossimulator' <<< "$probe_headers" \
        || die "$probe_name does not advertise iOS Simulator"
    grep -Fq 'sdk 26.1' <<< "$probe_headers" \
        || die "$probe_name SDK marker drifted"
    grep -Fq 'minos 18.0' <<< "$probe_headers" \
        || die "$probe_name minOS marker drifted"
done
swiftui_loads=$(llvm-otool-18 -L "$stage/true-ios-swiftui-dylib-probe" \
    | awk '$1 == "/usr/lib/libSwiftUI.dylib" { count++ } END { print count + 0 }')
[ "$swiftui_loads" -eq 1 ] || die "probe SwiftUI load count is $swiftui_loads"
foundation_models_loads=$(llvm-otool-18 -L \
    "$stage/true-ios-swiftui-dylib-probe" \
    | awk '$1 == "/usr/lib/libFoundationModels.dylib" { count++ } END { print count + 0 }')
natural_language_loads=$(llvm-otool-18 -L \
    "$stage/true-ios-swiftui-dylib-probe" \
    | awk '$1 == "/usr/lib/libNaturalLanguage.dylib" { count++ } END { print count + 0 }')
authentication_services_loads=$(llvm-otool-18 -L \
    "$stage/true-ios-swiftui-dylib-probe" \
    | awk '$1 == "/usr/lib/libAuthenticationServices.dylib" { count++ } END { print count + 0 }')
authentication_services_overlay_loads=$(llvm-otool-18 -L \
    "$stage/true-ios-swiftui-dylib-probe" \
    | awk '$1 == "/usr/lib/lib_AuthenticationServices_SwiftUI.dylib" { count++ } END { print count + 0 }')
accelerate_loads=$(llvm-otool-18 -L \
    "$stage/true-ios-swiftui-dylib-probe" \
    | awk '$1 == "/usr/lib/libAccelerate.dylib" { count++ } END { print count + 0 }')
compression_loads=$(llvm-otool-18 -L \
    "$stage/true-ios-swiftui-dylib-probe" \
    | awk '$1 == "/usr/lib/libCompression.dylib" { count++ } END { print count + 0 }')
coretext_loads=$(llvm-otool-18 -L \
    "$stage/true-ios-swiftui-dylib-probe" \
    | awk '$1 == "/usr/lib/libCoreText.dylib" { count++ } END { print count + 0 }')
[ "$foundation_models_loads" -eq 1 ] \
    || die "probe FoundationModels load count is $foundation_models_loads"
[ "$natural_language_loads" -eq 1 ] \
    || die "probe NaturalLanguage load count is $natural_language_loads"
[ "$authentication_services_loads" -eq 1 ] \
    || die "probe AuthenticationServices load count is $authentication_services_loads"
[ "$authentication_services_overlay_loads" -eq 1 ] \
    || die "probe AuthenticationServices overlay load count is $authentication_services_overlay_loads"
[ "$accelerate_loads" -eq 1 ] \
    || die "probe Accelerate load count is $accelerate_loads"
[ "$compression_loads" -eq 1 ] \
    || die "probe Compression load count is $compression_loads"
[ "$coretext_loads" -eq 1 ] \
    || die "probe CoreText load count is $coretext_loads"
foundation_models_consumer_loads=$(llvm-otool-18 -L \
    "$stage/foundationmodels-icecubes-probe" \
    | awk '$1 == "/usr/lib/libFoundationModels.dylib" { count++ } END { print count + 0 }')
natural_language_generalization_loads=$(llvm-otool-18 -L \
    "$stage/naturallanguage-generalization-probe" \
    | awk '$1 == "/usr/lib/libNaturalLanguage.dylib" { count++ } END { print count + 0 }')
[ "$foundation_models_consumer_loads" -eq 1 ] \
    || die 'FoundationModels exact consumer load count drifted'
[ "$natural_language_generalization_loads" -eq 1 ] \
    || die 'NaturalLanguage generalization load count drifted'
authentication_services_overlay_base_loads=$(llvm-otool-18 -L \
    "$PRODUCTS/lib_AuthenticationServices_SwiftUI.dylib" \
    | awk '$1 == "/usr/lib/libAuthenticationServices.dylib" { count++ } END { print count + 0 }')
authentication_services_overlay_swiftui_loads=$(llvm-otool-18 -L \
    "$PRODUCTS/lib_AuthenticationServices_SwiftUI.dylib" \
    | awk '$1 == "/usr/lib/libSwiftUI.dylib" { count++ } END { print count + 0 }')
[ "$authentication_services_overlay_base_loads" -eq 1 ] \
    || die 'AuthenticationServices overlay base load count drifted'
[ "$authentication_services_overlay_swiftui_loads" -eq 1 ] \
    || die 'AuthenticationServices overlay SwiftUI load count drifted'
for binary in "$PRODUCTS/libFoundationModels.dylib" \
    "$PRODUCTS/libNaturalLanguage.dylib" \
    "$PRODUCTS/libAuthenticationServices.dylib" \
    "$PRODUCTS/lib_AuthenticationServices_SwiftUI.dylib"; do
    if llvm-otool-18 -L "$binary" \
        | grep -Eq '/System/Library/Frameworks/(FoundationModels|NaturalLanguage|AuthenticationServices|_AuthenticationServices_SwiftUI)\.framework/'; then
        die "portable first-party binary loads an Apple framework: $binary"
    fi
done
{
    printf 'format\ttrue-ios-foundationmodels-natural-auth-loads-v2\n'
    printf 'probe\tfoundationmodels=%s\tnaturallanguage=%s\tauthenticationservices=%s\toverlay=%s\n' \
        "$foundation_models_loads" "$natural_language_loads" \
        "$authentication_services_loads" \
        "$authentication_services_overlay_loads"
    printf 'foundationmodels\tconsumer=%s\texports=%s\tapple-self-load=0\n' \
        "$foundation_models_consumer_loads" \
        "$(wc -l < "$AUDIT/foundationmodels-runtime-exports.txt" | tr -d '[:space:]')"
    printf 'naturallanguage\tgeneralization=%s\tapple-self-load=0\n' \
        "$natural_language_generalization_loads"
    printf 'overlay\tbase=%s\tswiftui=%s\tapple-self-load=0\n' \
        "$authentication_services_overlay_base_loads" \
        "$authentication_services_overlay_swiftui_loads"
} > "$AUDIT/naturallanguage-authenticationservices-loads.tsv"

accelerate_vimage_exports=$(llvm-nm-18 --defined-only --extern-only \
    --just-symbol-name "$PRODUCTS/libAccelerate.dylib" \
    | awk '$0 == "_vImageBoxConvolve_ARGB8888" { count++ } END { print count + 0 }')
compression_c_exports=$(wc -l < "$BUILD/libcompression-c-exports.txt" \
    | tr -d '[:space:]')
compression_host_imports=$(wc -l < "$BUILD/libcompression-host-imports.txt" \
    | tr -d '[:space:]')
[ "$accelerate_vimage_exports" -eq 1 ] \
    || die 'Accelerate vImage export denominator drifted'
[ "$compression_c_exports" -eq 2 ] \
    || die 'Compression C export denominator drifted'
[ "$compression_host_imports" -eq 2 ] \
    || die 'Compression host import denominator drifted'
{
    printf 'format\ttrue-ios-accelerate-compression-coretext-loads-v1\n'
    printf 'probe\taccelerate=%s\tcompression=%s\tcoretext=%s\n' \
        "$accelerate_loads" "$compression_loads" "$coretext_loads"
    printf 'accelerate\tvimage-export=%s\tapple-self-load=0\n' \
        "$accelerate_vimage_exports"
    printf 'compression\tc-exports=%s\thost-imports=%s\tbrotli-load=0\tapple-self-load=0\n' \
        "$compression_c_exports" "$compression_host_imports"
    printf 'coretext\tapple-self-load=0\n'
} > "$AUDIT/accelerate-compression-coretext-loads.tsv"

HOST_LIBRARIES=(
    libdispatch.so libBlocksRuntime.so libOpenDispatchHost.so
    libOpenFoundationInternationalizationHost.so libOpenURLTransportHost.so
    libOpenRelativeTimeHost.so libOpenCompressionHost.so
)
for host_library in "${HOST_LIBRARIES[@]}"; do
    [ -f "$RUNTIME_ROOT/host/$host_library" ] && [ ! -L "$RUNTIME_ROOT/host/$host_library" ] \
        || die "cold runtime host closure is missing $host_library"
done
host_preload="$RUNTIME_ROOT/host/libOpenDispatchHost.so:$RUNTIME_ROOT/host/libOpenFoundationInternationalizationHost.so:$RUNTIME_ROOT/host/libOpenURLTransportHost.so:$RUNTIME_ROOT/host/libOpenRelativeTimeHost.so:$RUNTIME_ROOT/host/libOpenCompressionHost.so"
printf '%s\n' \
    'concpatch: dlopen("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation") -- refused, as machorun does. mode=16' \
    > "$BUILD/runtime-loader-expected.stderr.log"
(
    cd "$stage"
    MACHORUN_ROOT="$RUNTIME_ROOT" \
    LD_LIBRARY_PATH="$RUNTIME_ROOT/host" LD_PRELOAD="$host_preload" \
        "$RUNTIME_ROOT/machorun" ./true-ios-swiftui-dylib-probe \
        "$RESOURCES/fonts/DejaVuSans.ttf" \
        "$stage/coretext-runtime-fonts"
) 2> "$AUDIT/runtime.stderr.log" | tee "$AUDIT/runtime.log"
grep -Fq 'TRUE_IOS_SWIFTUI_DYLIB_RUNTIME_OK descendants=' "$AUDIT/runtime.log" \
    || die 'cold SwiftUI dylib runtime marker is missing'
cmp "$BUILD/runtime-loader-expected.stderr.log" \
    "$AUDIT/runtime.stderr.log" \
    || die 'cold SwiftUI dylib loader stderr differs'

cp "$FOUNDATION_MODELS_GOLDEN" \
    "$AUDIT/foundationmodels-apple-26.1.txt"
cp "$NATURAL_LANGUAGE_GENERALIZATION_GOLDEN" \
    "$AUDIT/naturallanguage-generalization-apple-26.1.txt"
(
    cd "$stage"
    MACHORUN_ROOT="$RUNTIME_ROOT" \
    LD_LIBRARY_PATH="$RUNTIME_ROOT/host" LD_PRELOAD="$host_preload" \
        "$RUNTIME_ROOT/machorun" ./foundationmodels-icecubes-probe
) 2> "$AUDIT/foundationmodels-runtime.stderr.log" \
    | tee "$AUDIT/foundationmodels-runtime.log"
head -n 4 "$AUDIT/foundationmodels-runtime.log" \
    > "$BUILD/foundationmodels-apple-comparable.txt"
cmp "$BUILD/foundationmodels-apple-comparable.txt" \
    "$AUDIT/foundationmodels-apple-26.1.txt" \
    || die 'FoundationModels generated-content transcript differs from Apple 26.1'
grep -Fxq \
    'FOUNDATIONMODELS_GUEST_MACHO_OK macro=generable guide=count generated=roundtrip direct=fail-closed stream=fail-closed available=false' \
    "$AUDIT/foundationmodels-runtime.log" \
    || die 'FoundationModels fail-closed runtime marker is missing'
cmp "$BUILD/runtime-loader-expected.stderr.log" \
    "$AUDIT/foundationmodels-runtime.stderr.log" \
    || die 'FoundationModels cold loader stderr differs'
(
    cd "$stage"
    MACHORUN_ROOT="$RUNTIME_ROOT" \
    LD_LIBRARY_PATH="$RUNTIME_ROOT/host" LD_PRELOAD="$host_preload" \
        "$RUNTIME_ROOT/machorun" ./naturallanguage-generalization-probe
) 2> "$AUDIT/naturallanguage-generalization-runtime.stderr.log" \
    | tee "$AUDIT/naturallanguage-generalization-runtime.log"
cmp "$AUDIT/naturallanguage-generalization-runtime.log" \
    "$AUDIT/naturallanguage-generalization-apple-26.1.txt" \
    || die 'NaturalLanguage 29-row generalization differs from Apple 26.1'
[ ! -s "$AUDIT/naturallanguage-generalization-runtime.stderr.log" ] \
    || die 'NaturalLanguage cold loader stderr differs'

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
    for probe in foundationmodels-icecubes-probe \
        naturallanguage-generalization-probe; do
        printf '%s\t%s\n' "$(sha256sum "$probe" | awk '{print $1}')" "$probe"
    done
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
