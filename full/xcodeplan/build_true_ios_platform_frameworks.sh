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
FULL=${FULL:-$W/build/full}
FULL_BUILD_PROJECT=${FULL_BUILD_PROJECT:-$W}
MRROOT_INPUT=${MRROOT_INPUT:-$W/scratch/mrroot_full}
SWIFT_FOUNDATION=${SWIFT_FOUNDATION:-$W/scratch/swift-foundation}
SWIFT_COLLECTIONS=${SWIFT_COLLECTIONS:-$W/scratch/swift-collections}
OPENCOMBINE_SOURCE=${OPENCOMBINE_SOURCE:-$W/scratch/opencombine-core-durable-20260828-r2/source}
OUTPUT_ROOT=${OUTPUT_ROOT:-$W/build/true-ios-platform}

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

for tool in bash git perl patch swiftc clang++-18 ld64.lld-18 \
    llvm-nm-18 llvm-objdump-18 llvm-otool-18 file sha256sum; do
    command -v "$tool" >/dev/null || die "missing required tool: $tool"
done

case "$OUTPUT_ROOT" in
    /*/true-ios-platform|/*/true-ios-platform-[A-Za-z0-9._-]*) ;;
    *) die "OUTPUT_ROOT must be an absolute, narrowly named true-ios-platform path: $OUTPUT_ROOT" ;;
esac
[ "$(dirname "$OUTPUT_ROOT")" != / ] || die 'OUTPUT_ROOT parent may not be /'
[ -d "$W/full/xcodeplan" ] || die "project root is missing: $W"
[ -d "$UIKIT/Sources/SwiftUI" ] || die "canonical UIKit source is missing: $UIKIT"
[ -d "$SYS/usr/lib/swift" ] || die "true-iOS SDK is missing: $SYS"
[ -d "$APPLE_SWIFT_USER_OVERLAYS" ] || die 'Apple user-overlay directory is missing'
[ -x "$MRROOT_INPUT/machorun" ] || die 'input guest root has no machorun loader'
[ -d "$OPENCOMBINE_SOURCE/.git" ] || die 'OpenCombine input is not a Git checkout'

for required in \
    "$FULL/uihelpers-subject.sha256" \
    "$FULL/openuikit.o" "$FULL/opencoregraphics.o" \
    "$FULL/uikitshim.o" "$FULL/swiftcorepatch.o" \
    "$FULL/developertoolsupport/developertoolsupport.o" \
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
    Sources/SwiftUI Sources/Combine)
[ -z "$uikit_status" ] || die "canonical Combine/SwiftUI source is dirty: $uikit_status"

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
RUNTIME_ROOT=$stage/runtime-root
AUDIT=$stage/attestation
MODULE_CACHE=$BUILD/module-cache
INCLUDE=$stage/include
INTERNAL_MODULE_PATH=$stage/internal-modules
mkdir -p "$BUILD" "$PACKAGE" "$PRODUCTS" "$FRAMEWORKS" \
    "$AUDIT" "$MODULE_CACHE" "$INCLUDE" "$INTERNAL_MODULE_PATH"

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
        find "$UIKIT/Sources/SwiftUI" "$UIKIT/Sources/Combine" -type f \
            -name '*.swift' -print0 | LC_ALL=C sort -z \
            | while IFS= read -r -d '' source; do
                printf '%s\t%s\n' "${source#"$UIKIT"/}" "$(sha "$source")"
            done
        printf 'full-subject\t%s\n' "$actual_full_subject"
        printf 'opencombine-audit\t%s\n' "$(sha "$AUDIT/opencombine-sources.json")"
    } | sha256sum | awk '{print $1}'
}
SOURCE_SUBJECT_BEFORE=$(source_subject)
printf '%s\n' "$SOURCE_SUBJECT_BEFORE" > "$AUDIT/source-subject.before.sha256"

cp -a "$FULL/inc/CPortableIO" "$INCLUDE/"
cp -a "$FULL/inc/CSTBTrueType" "$INCLUDE/"
cp -a "$W/full/hostclock/include" "$INCLUDE/CHostClock"
cp -a "$UIKIT/Sources/CQuartz/include" "$INCLUDE/CQuartz"
cp -a "$OPENCOMBINE_SOURCE/Sources/COpenCombineHelpers/include" \
    "$INCLUDE/COpenCombineHelpers"
cp -a "$SWIFT_FOUNDATION/Sources/_FoundationCShims/include" \
    "$INCLUDE/_FoundationCShims"

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
copy_module DeveloperToolsSupport "$FULL/developertoolsupport"
copy_module UIKit "$FULL/uikitinc"
copy_module FoundationEssentials "$FULL/foundation/essentials"
copy_module InternalCollectionsUtilities "$FULL/foundation/collections"
copy_module OrderedCollections "$FULL/foundation/collections"
copy_module _RopeModule "$FULL/foundation/collections"
copy_module os "$FULL/foundation/os"

SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS" -I "$APPLE_SWIFT_USER_OVERLAYS"
    -module-cache-path "$MODULE_CACHE" -runtime-compatibility-version none -wmo
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xfrontend -disable-objc-attr-requires-foundation-module)
CFLAGS=(-Xcc -I"$INCLUDE/CPortableIO" -Xcc -I"$INCLUDE/CSTBTrueType"
    -Xcc -I"$INCLUDE/CHostClock" -Xcc -I"$INCLUDE/COpenCombineHelpers"
    -Xcc -I"$INCLUDE/CQuartz"
    -Xcc -fmodule-map-file="$INCLUDE/_FoundationCShims/module.modulemap"
    -Xcc -I"$INCLUDE/_FoundationCShims")
FE_FLAGS=(-I "$FULL/foundation/essentials"
    -I "$FULL/foundation/collections" -I "$FULL/foundation/os")
LD=(ld64.lld-18 -arch arm64 -platform_version "$PLATFORM" "$MINIMUM_OS" \
    "$SDK_VERSION" -syslibroot "$SYS")
COMMON_RUNTIME=(-L"$MRROOT_INPUT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore
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

echo '== canonical SwiftUI source'
mapfile -d '' -t swiftui_sources < <(
    find "$UIKIT/Sources/SwiftUI" -maxdepth 1 -type f -name '*.swift' \
        -print0 | LC_ALL=C sort -z
)
[ "${#swiftui_sources[@]}" -ge 6 ] \
    || die "canonical SwiftUI source denominator unexpectedly fell to ${#swiftui_sources[@]}"
"${SWIFTC[@]}" "${CFLAGS[@]}" "${FE_FLAGS[@]}" -parse-as-library \
    -I "$PACKAGE" -module-name SwiftUI \
    -emit-module -emit-module-path "$PACKAGE/SwiftUI.swiftmodule" \
    -emit-object -o "$BUILD/SwiftUI.o" "${swiftui_sources[@]}"

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
"${LD[@]}" -dylib -install_name /usr/lib/libDeveloperToolsSupport.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lOpenUIKit -lFoundationEssentials \
    "${COMMON_RUNTIME[@]}" -o "$PRODUCTS/libDeveloperToolsSupport.dylib" \
    "$FULL/developertoolsupport/developertoolsupport.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -install_name /usr/lib/libUIKit.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lOpenUIKit -lOpenCoreGraphics -lFoundationEssentials \
    -lDeveloperToolsSupport "${COMMON_RUNTIME[@]}" -lobjc \
    -o "$PRODUCTS/libUIKit.dylib" "$FULL/uikitshim.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"
"${LD[@]}" -dylib -install_name /usr/lib/libSwiftUI.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    -L"$PRODUCTS" -lOpenUIKit -lOpenCoreGraphics -lFoundationEssentials \
    -lCombine -lOpenCombine "${COMMON_RUNTIME[@]}" \
    -o "$PRODUCTS/libSwiftUI.dylib" "$BUILD/SwiftUI.o" \
    "$MRROOT_INPUT/darwin/usr/lib/libSystem.B.dylib"

PUBLIC_MODULES=(
    FoundationEssentials OpenCoreGraphics OpenUIKit DeveloperToolsSupport
    UIKit OpenCombine Combine SwiftUI
)
INTERNAL_MODULES=(InternalCollectionsUtilities OrderedCollections _RopeModule os)

echo '== framework SDK layout'
cp -a "$SYS/." "$SDK_OUT/"
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
mkdir -p "$SDK_OUT/usr/local"
cp -a "$INCLUDE" "$SDK_OUT/usr/local/include"

echo '== private cold runtime root'
cp -a "$MRROOT_INPUT/." "$RUNTIME_ROOT/"
for module in "${PUBLIC_MODULES[@]}"; do
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
PROBE_CFLAGS=(-Xcc -I"$SDK_OUT/usr/local/include/CPortableIO"
    -Xcc -I"$SDK_OUT/usr/local/include/CSTBTrueType"
    -Xcc -I"$SDK_OUT/usr/local/include/CHostClock"
    -Xcc -I"$SDK_OUT/usr/local/include/COpenCombineHelpers"
    -Xcc -I"$SDK_OUT/usr/local/include/CQuartz"
    -Xcc -fmodule-map-file="$SDK_OUT/usr/local/include/_FoundationCShims/module.modulemap"
    -Xcc -I"$SDK_OUT/usr/local/include/_FoundationCShims")
# Compile against the immutable base SDK plus the newly emitted framework
# overlay. The published SDK is a byte-for-byte base copy carrying that same
# overlay; keeping the base path here also proves the framework layer does not
# rely on mutating or shadowing Apple SDK modules.
if ! swiftc -target "$TARGET" -sdk "$SYS" -I "$APPLE_SWIFT_USER_OVERLAYS" \
    -F "$FRAMEWORKS" -I "$INTERNAL_MODULE_PATH" \
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
for module in SwiftUI UIKit OpenUIKit Combine OpenCombine; do
    expected_module_path="$FRAMEWORKS/$module.framework/Modules/$module.swiftmodule/$TARGET_VARIANT.swiftmodule"
    grep -Fq "loaded module '$module'; source: '$expected_module_path'" \
        "$AUDIT/framework-module-loading.log" \
        || die "$module was not loaded from its published framework module"
done
"${LD[@]}" -dead_strip -exported_symbol __mh_execute_header \
    -rpath @loader_path -F"$FRAMEWORKS" -framework SwiftUI -framework UIKit \
    -L"$PRODUCTS" -lOpenUIKit -lOpenCoreGraphics -lFoundationEssentials \
    -lDeveloperToolsSupport -lCombine -lOpenCombine \
    "${COMMON_RUNTIME[@]}" -lobjc \
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

# Compiler caches and intermediate objects are deliberately not published.
# Every replay starts from a clean temporary stage and regenerates them.
rm -rf -- "$BUILD" "$INCLUDE"
(
    cd "$stage"
    find products package internal-modules sdk/System/Library/Frameworks \
        -type f -print0 | LC_ALL=C sort -z \
        | while IFS= read -r -d '' path; do
            printf '%s\t%s\n' "$(sha256sum "$path" | awk '{print $1}')" "$path"
        done
    printf '%s\t%s\n' "$(sha256sum true-ios-swiftui-dylib-probe | awk '{print $1}')" \
        true-ios-swiftui-dylib-probe
    for module in "${PUBLIC_MODULES[@]}"; do
        runtime_path="runtime-root/darwin/usr/lib/lib$module.dylib"
        printf '%s\t%s\n' "$(sha256sum "$runtime_path" | awk '{print $1}')" \
            "$runtime_path"
    done
) | LC_ALL=C sort > "$AUDIT/artifacts.sha256"
printf '%s\n' \
    "TRUE_IOS_PLATFORM_COMPLETE target=$TARGET dylibs=${#PUBLIC_MODULES[@]} swiftui_sources=${#swiftui_sources[@]} source=$SOURCE_SUBJECT_BEFORE" \
    > "$stage/PLATFORM_COMPLETE"

mv "$stage" "$OUTPUT_ROOT"
stage=''
trap - EXIT HUP INT TERM
echo "true_ios_platform: published $OUTPUT_ROOT"
cat "$OUTPUT_ROOT/PLATFORM_COMPLETE"
