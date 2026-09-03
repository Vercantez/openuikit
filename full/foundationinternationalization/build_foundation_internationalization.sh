#!/usr/bin/env bash
# Build the complete pinned FoundationInternationalization implementation for
# the ARM64 Mach-O guest.  This is intentionally the full swift-foundation ICU
# closure: all common, i18n, and io translation units, including packaged ICU
# data.  No host ICU formatting API participates in guest semantics.

set -euo pipefail
export GIT_OPTIONAL_LOCKS=0

SUPPORT_ROOT=${SUPPORT_ROOT:?SUPPORT_ROOT is required}
SWIFT_FOUNDATION=${SWIFT_FOUNDATION:?SWIFT_FOUNDATION is required}
SWIFT_FOUNDATION_ICU=${SWIFT_FOUNDATION_ICU:?SWIFT_FOUNDATION_ICU is required}
STAGE=${STAGE:?STAGE is required}
WORK=${WORK:?WORK is required}
TARGET=${TARGET:-arm64-apple-macos15.0}
LINK_ARCH=${TARGET%%-*}
MIN_OS=${MIN_OS:-15.0}
LINK_PLATFORM=${LINK_PLATFORM:-macos}
LINK_SDK_VERSION=${LINK_SDK_VERSION:-$MIN_OS}
APPLE_SWIFT_USER_OVERLAYS=${APPLE_SWIFT_USER_OVERLAYS:-}
DYLIB_INSTALL_PREFIX=${DYLIB_INSTALL_PREFIX:-@rpath}
FOUNDATION_ICU_JOBS=${FOUNDATION_ICU_JOBS:-8}
COLLECTIONS=${COLLECTIONS:-}
OSMOD=${OSMOD:-}
CSHIMS=${CSHIMS:-}

EXPECTED_FOUNDATION_COMMIT=c6793ef0c19c2cbaeba5a0e52078f129afc7dcfc
EXPECTED_FOUNDATION_TREE=4651798679b98e27383ca3626434fb128f191486
EXPECTED_FOUNDATION_ICU_COMMIT=87dbab99780e277b6a4c2a397ab1a894f877b39a
EXPECTED_FOUNDATION_ICU_TREE=823a4a2a13f60a0fd2715db85a754dda11d5fd39
EXPECTED_FOUNDATION_INTL_SWIFT_COUNT=61
EXPECTED_FOUNDATION_ICU_CPP_COUNT=474
EXPECTED_FOUNDATION_ICU_HEADER_COUNT=205

die() {
    echo "foundation_internationalization: REFUSING -- $*" >&2
    exit 2
}

case "$FOUNDATION_ICU_JOBS" in
    ''|*[!0-9]*) die 'FOUNDATION_ICU_JOBS must be a positive integer' ;;
esac
[ "$FOUNDATION_ICU_JOBS" -gt 0 ] \
    || die 'FOUNDATION_ICU_JOBS must be a positive integer'
for path in "$SUPPORT_ROOT" "$SWIFT_FOUNDATION" "$SWIFT_FOUNDATION_ICU" \
    "$STAGE" "$WORK"; do
    case "$path" in /*) ;; *) die "path must be absolute: $path" ;; esac
done
SWIFT_OVERLAY_FLAGS=()
if [ -n "$APPLE_SWIFT_USER_OVERLAYS" ]; then
    case "$APPLE_SWIFT_USER_OVERLAYS" in
        /*) ;;
        *) die "Apple Swift overlay path must be absolute: $APPLE_SWIFT_USER_OVERLAYS" ;;
    esac
    [ -d "$APPLE_SWIFT_USER_OVERLAYS" ] \
        || die "Apple Swift overlay directory is missing: $APPLE_SWIFT_USER_OVERLAYS"
    SWIFT_OVERLAY_FLAGS=(-I "$APPLE_SWIFT_USER_OVERLAYS")
fi
for tool in git find cmp sha256sum swiftc clang-18 clang++-18 ld64.lld-18 \
    llvm-nm-18 llvm-otool-18 readelf xargs; do
    command -v "$tool" >/dev/null || die "required tool is missing: $tool"
done
[ -d "$STAGE/sdk" ] && [ -d "$STAGE/modules" ] \
    && [ -d "$STAGE/lib" ] && [ -d "$STAGE/guest-root/darwin/usr/lib" ] \
    || die 'staged SDK/module/library/runtime roots are incomplete'
[ -f "$STAGE/lib/libFoundationEssentials.dylib" ] \
    || die 'libFoundationEssentials.dylib must be linked first'
for name in COLLECTIONS OSMOD CSHIMS; do
    value=${!name}
    [ -n "$value" ] || continue
    case "$value" in /*) ;; *) die "$name path must be absolute: $value" ;; esac
    [ -d "$value" ] || die "$name directory is missing: $value"
done
if [ -n "$COLLECTIONS" ]; then
    for module in InternalCollectionsUtilities OrderedCollections _RopeModule; do
        [ -f "$COLLECTIONS/$module.swiftmodule" ] && [ ! -L "$COLLECTIONS/$module.swiftmodule" ] \
            && [ -f "$COLLECTIONS/$module.o" ] && [ ! -L "$COLLECTIONS/$module.o" ] \
            || die "COLLECTIONS is missing $module.swiftmodule/.o: $COLLECTIONS"
    done
fi
if [ -n "$OSMOD" ]; then
    [ -f "$OSMOD/os.swiftmodule" ] && [ ! -L "$OSMOD/os.swiftmodule" ] \
        && [ -f "$OSMOD/os.o" ] && [ ! -L "$OSMOD/os.o" ] \
        || die "OSMOD is missing os.swiftmodule/.o: $OSMOD"
fi
if [ -n "$CSHIMS" ]; then
    for object in platform_shims string_shims uuid; do
        [ -f "$CSHIMS/$object.o" ] && [ ! -L "$CSHIMS/$object.o" ] \
            || die "CSHIMS is missing $object.o: $CSHIMS"
    done
fi

assert_checkout() {
    local checkout=$1 expected_commit=$2 expected_tree=$3 label=$4
    local actual_commit actual_tree status
    [ -d "$checkout/.git" ] || die "$label is not a Git checkout"
    actual_commit=$(git -C "$checkout" rev-parse --verify HEAD^{commit})
    actual_tree=$(git -C "$checkout" rev-parse --verify HEAD^{tree})
    status=$(git -C "$checkout" status --porcelain=v1 --untracked-files=all)
    [ "$actual_commit" = "$expected_commit" ] \
        || die "$label commit $actual_commit, expected $expected_commit"
    [ "$actual_tree" = "$expected_tree" ] \
        || die "$label tree $actual_tree, expected $expected_tree"
    [ -z "$status" ] || die "$label checkout is dirty: $status"
}

assert_checkout "$SWIFT_FOUNDATION" "$EXPECTED_FOUNDATION_COMMIT" \
    "$EXPECTED_FOUNDATION_TREE" swift-foundation
assert_checkout "$SWIFT_FOUNDATION_ICU" "$EXPECTED_FOUNDATION_ICU_COMMIT" \
    "$EXPECTED_FOUNDATION_ICU_TREE" swift-foundation-icu

[ ! -e "$WORK/foundation-internationalization" ] \
    || die 'FoundationInternationalization work directory is stale'
mkdir -p "$WORK/foundation-internationalization/icu-objects" \
    "$WORK/foundation-internationalization/module-cache" \
    "$STAGE/include" "$STAGE/guest-root/host" "$STAGE/attestation"
INTL_WORK=$WORK/foundation-internationalization
ICU_SOURCE_ROOT=$SWIFT_FOUNDATION_ICU/icuSources
ICU_OBJECT_ROOT=$INTL_WORK/icu-objects
INTL_SOURCE_ROOT=$SWIFT_FOUNDATION/Sources/FoundationInternationalization
COMPAT_INCLUDE=$SUPPORT_ROOT/full/foundationinternationalization/include

git -C "$SWIFT_FOUNDATION" ls-files -z -- \
    'Sources/FoundationInternationalization/*.swift' \
    | LC_ALL=C sort -z > "$INTL_WORK/swift-sources.tracked.nul"
find "$INTL_SOURCE_ROOT" -type f -name '*.swift' -print0 \
    | while IFS= read -r -d '' path; do
        printf '%s\0' "${path#"$SWIFT_FOUNDATION"/}"
      done | LC_ALL=C sort -z > "$INTL_WORK/swift-sources.physical.nul"
cmp "$INTL_WORK/swift-sources.tracked.nul" \
    "$INTL_WORK/swift-sources.physical.nul" \
    || die 'FoundationInternationalization physical Swift set differs from pinned Git'
intl_swift_count=$(tr -cd '\0' < "$INTL_WORK/swift-sources.tracked.nul" \
    | wc -c | tr -d '[:space:]')
[ "$intl_swift_count" -eq "$EXPECTED_FOUNDATION_INTL_SWIFT_COUNT" ] \
    || die "FoundationInternationalization Swift count $intl_swift_count, expected $EXPECTED_FOUNDATION_INTL_SWIFT_COUNT"

git -C "$SWIFT_FOUNDATION_ICU" ls-files -z -- \
    'icuSources/common/*.cpp' 'icuSources/i18n/*.cpp' 'icuSources/io/*.cpp' \
    | LC_ALL=C sort -z > "$INTL_WORK/icu-sources.tracked.nul"
find "$ICU_SOURCE_ROOT/common" "$ICU_SOURCE_ROOT/i18n" "$ICU_SOURCE_ROOT/io" \
    -type f -name '*.cpp' -print0 \
    | while IFS= read -r -d '' path; do
        printf '%s\0' "${path#"$SWIFT_FOUNDATION_ICU"/}"
      done | LC_ALL=C sort -z > "$INTL_WORK/icu-sources.physical.nul"
cmp "$INTL_WORK/icu-sources.tracked.nul" \
    "$INTL_WORK/icu-sources.physical.nul" \
    || die 'Foundation ICU physical C++ set differs from pinned Git'
icu_cpp_count=$(tr -cd '\0' < "$INTL_WORK/icu-sources.tracked.nul" \
    | wc -c | tr -d '[:space:]')
[ "$icu_cpp_count" -eq "$EXPECTED_FOUNDATION_ICU_CPP_COUNT" ] \
    || die "Foundation ICU C++ count $icu_cpp_count, expected $EXPECTED_FOUNDATION_ICU_CPP_COUNT"

icu_header_count=$(git -C "$SWIFT_FOUNDATION_ICU" ls-files -z -- \
    'icuSources/include/_foundation_unicode/*' | tr -cd '\0' \
    | wc -c | tr -d '[:space:]')
[ "$icu_header_count" -eq "$EXPECTED_FOUNDATION_ICU_HEADER_COUNT" ] \
    || die "Foundation ICU header count $icu_header_count, expected $EXPECTED_FOUNDATION_ICU_HEADER_COUNT"
[ -f "$ICU_SOURCE_ROOT/include/_foundation_unicode/module.modulemap" ] \
    || die 'Foundation ICU module map is missing'
[ ! -e "$STAGE/include/FoundationICU" ] \
    || die 'staged Foundation ICU headers already exist'
mkdir -p "$STAGE/include/FoundationICU"
cp -a "$ICU_SOURCE_ROOT/include/_foundation_unicode" \
    "$STAGE/include/FoundationICU/"

hash_file() {
    sha256sum "$1" | awk '{print $1}'
}

{
    printf 'format\tfoundation-internationalization-sources-v1\n'
    printf 'swift-foundation\tcommit=%s\ttree=%s\tswift=%s\n' \
        "$EXPECTED_FOUNDATION_COMMIT" "$EXPECTED_FOUNDATION_TREE" \
        "$intl_swift_count"
    printf 'swift-foundation-icu\tcommit=%s\ttree=%s\tcpp=%s\theaders=%s\tstubdata=excluded\n' \
        "$EXPECTED_FOUNDATION_ICU_COMMIT" "$EXPECTED_FOUNDATION_ICU_TREE" \
        "$icu_cpp_count" "$icu_header_count"
    while IFS= read -r -d '' relative; do
        printf 'swift\t%s\t%s\n' "$relative" \
            "$(hash_file "$SWIFT_FOUNDATION/$relative")"
    done < "$INTL_WORK/swift-sources.tracked.nul"
    while IFS= read -r -d '' relative; do
        printf 'icu-cpp\t%s\t%s\n' "$relative" \
            "$(hash_file "$SWIFT_FOUNDATION_ICU/$relative")"
    done < "$INTL_WORK/icu-sources.tracked.nul"
} > "$STAGE/attestation/foundation-internationalization-sources.tsv"

ICU_DEFINES=(
    -DU_ATTRIBUTE_DEPRECATED=
    -DU_SHOW_CPLUSPLUS_API=1
    -DU_SHOW_INTERNAL_API=1
    -DU_STATIC_IMPLEMENTATION
    -DU_TIMEZONE=timezone
    '-DU_TIMEZONE_PACKAGE="icutz44l"'
    -DFORTIFY_SOURCE=2
    -DSTD_INSPIRED
    -DMAC_OS_X_VERSION_MIN_REQUIRED=101500
    -DU_HAVE_STRTOD_L=1
    -DU_HAVE_XLOCALE_H=1
    -DU_HAVE_STRING_VIEW=1
    -DU_HAVE_NL_LANGINFO_CODESET=0
    -DU_DISABLE_RENAMING=1
    -DU_COMBINED_IMPLEMENTATION
    -DU_COMMON_IMPLEMENTATION
    -DU_I18N_IMPLEMENTATION
    -DU_IO_IMPLEMENTATION
    '-DICU_DATA_DIR="/usr/share/icu/"'
    -DUSE_PACKAGE_DATA=1
    -DAPPLE_ICU_CHANGES=1
)
export TARGET STAGE ICU_SOURCE_ROOT ICU_OBJECT_ROOT COMPAT_INCLUDE
printf -v FOUNDATION_ICU_DEFINES_Q '%q ' "${ICU_DEFINES[@]}"
export FOUNDATION_ICU_DEFINES_Q
while IFS= read -r -d '' relative; do
    printf '%s\0' "$SWIFT_FOUNDATION_ICU/$relative"
done < "$INTL_WORK/icu-sources.tracked.nul" \
    | xargs -0 -n 1 -P "$FOUNDATION_ICU_JOBS" bash -c '
        set -euo pipefail
        source_path=$1
        relative=${source_path#"$ICU_SOURCE_ROOT"/}
        object_path=$ICU_OBJECT_ROOT/${relative%.cpp}.o
        mkdir -p "$(dirname "$object_path")"
        eval "set -- $FOUNDATION_ICU_DEFINES_Q"
        clang++-18 -target "$TARGET" -isysroot "$STAGE/sdk" \
            -std=c++17 -O2 -nostdinc++ \
            -isystem /usr/lib/llvm-18/include/c++/v1 \
            "$@" -I "$COMPAT_INCLUDE" -I "$ICU_SOURCE_ROOT/include" \
            -I "$ICU_SOURCE_ROOT/common" -I "$ICU_SOURCE_ROOT/i18n" \
            -I "$ICU_SOURCE_ROOT/io" -c "$source_path" -o "$object_path"
      ' foundation-icu-compile
icu_object_count=$(find "$ICU_OBJECT_ROOT" -type f -name '*.o' \
    | wc -l | tr -d '[:space:]')
[ "$icu_object_count" -eq "$EXPECTED_FOUNDATION_ICU_CPP_COUNT" ] \
    || die "Foundation ICU object count $icu_object_count, expected $EXPECTED_FOUNDATION_ICU_CPP_COUNT"

clang++-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c++17 -O2 \
    -fno-exceptions -fno-rtti -nostdinc++ \
    -isystem /usr/lib/llvm-18/include/c++/v1 \
    -c "$SUPPORT_ROOT/full/foundationinternationalization/FoundationICUCXXThreading.cpp" \
    -o "$INTL_WORK/foundation-icu-cxx-threading.o"
clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$COMPAT_INCLUDE" \
    -c "$SUPPORT_ROOT/full/foundationinternationalization/OpenFoundationInternationalizationBridge.c" \
    -o "$INTL_WORK/open-foundation-internationalization-bridge.o"

INTL_DARWIN=$STAGE/guest-root/darwin/usr/lib/libOpenFoundationInternationalization.dylib
ld64.lld-18 -arch "$LINK_ARCH" \
    -platform_version "$LINK_PLATFORM" "$MIN_OS" "$LINK_SDK_VERSION" \
    -syslibroot "$STAGE/sdk" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenFoundationInternationalization.dylib \
    -o "$INTL_DARWIN" \
    "$INTL_WORK/open-foundation-internationalization-bridge.o"

INTL_HOST=$STAGE/guest-root/host/libOpenFoundationInternationalizationHost.so
bash "$SUPPORT_ROOT/full/foundationinternationalization/build_host_helper.sh" \
    --repo "$SUPPORT_ROOT" \
    --host-dir "$STAGE/guest-root/host" \
    --include-dir "$COMPAT_INCLUDE"
clang-18 -std=c11 -O2 -Wall -Wextra -Werror -I "$COMPAT_INCLUDE" \
    "$SUPPORT_ROOT/full/foundationinternationalization/OpenFoundationInternationalizationHost.c" \
    "$SUPPORT_ROOT/full/foundationinternationalization/OpenFoundationInternationalizationHostTests.c" \
    -o "$INTL_WORK/open-foundation-internationalization-host-tests"
"$INTL_WORK/open-foundation-internationalization-host-tests" \
    > "$INTL_WORK/open-foundation-internationalization-host-test.log"
grep -Fx \
    'OPEN_FOUNDATION_INTERNATIONALIZATION_HOST_OK realpath=bounded,versioned' \
    "$INTL_WORK/open-foundation-internationalization-host-test.log" >/dev/null \
    || die 'FoundationInternationalization host marker is missing'

printf 'openui_foundation_intl_v1_realpath\n' \
    > "$INTL_WORK/foundation-intl-expected-elf.txt"
printf '_realpath\n' > "$INTL_WORK/foundation-intl-expected-mach-exports.txt"
printf '_glibc_openui_foundation_intl_v1_realpath\n' \
    > "$INTL_WORK/foundation-intl-expected-mach-imports.txt"
readelf --wide --syms "$INTL_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_foundation_intl_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$INTL_WORK/foundation-intl-elf-exports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name "$INTL_DARWIN" \
    | LC_ALL=C sort -u > "$INTL_WORK/foundation-intl-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name "$INTL_DARWIN" \
    | LC_ALL=C sort -u > "$INTL_WORK/foundation-intl-mach-imports.txt"
cmp "$INTL_WORK/foundation-intl-expected-elf.txt" \
    "$INTL_WORK/foundation-intl-elf-exports.txt" \
    || die 'FoundationInternationalization Linux helper exports drifted'
cmp "$INTL_WORK/foundation-intl-expected-mach-exports.txt" \
    "$INTL_WORK/foundation-intl-mach-exports.txt" \
    || die 'FoundationInternationalization Mach-O bridge exports drifted'
cmp "$INTL_WORK/foundation-intl-expected-mach-imports.txt" \
    "$INTL_WORK/foundation-intl-mach-imports.txt" \
    || die 'FoundationInternationalization Mach-O bridge host import drifted'
[ "$(llvm-otool-18 -D "$INTL_DARWIN" | tail -n 1)" = \
    /usr/lib/libOpenFoundationInternationalization.dylib ] \
    || die 'FoundationInternationalization Mach-O bridge ID drifted'

mapfile -d '' -t ICU_OBJECTS < <(
    find "$ICU_OBJECT_ROOT" -type f -name '*.o' -print0 | LC_ALL=C sort -z
)
RUNTIME_LIB=$STAGE/guest-root/darwin/usr/lib
ld64.lld-18 -arch "$LINK_ARCH" \
    -platform_version "$LINK_PLATFORM" "$MIN_OS" "$LINK_SDK_VERSION" \
    -syslibroot "$STAGE/guest-root/darwin" -dylib -dead_strip \
    -install_name "$DYLIB_INSTALL_PREFIX/lib_FoundationICU.dylib" \
    -rpath @loader_path \
    -o "$STAGE/lib/lib_FoundationICU.dylib" \
    "${ICU_OBJECTS[@]}" "$INTL_WORK/foundation-icu-cxx-threading.o" \
    "$INTL_DARWIN" "$RUNTIME_LIB/libc++.1.dylib" \
    "$RUNTIME_LIB/libc++.real.dylib" "$RUNTIME_LIB/libc++abi.dylib" \
    "$STAGE/sdk/usr/lib/libSystem.tbd" "$RUNTIME_LIB/libSystem.B.dylib" \
    "$RUNTIME_LIB/libSystem.real.dylib"

THREADING_SYMBOLS=(
    __ZNSt3__111__call_onceERVmPvPFvS2_E
    __ZNSt3__118condition_variable10notify_allEv
    __ZNSt3__118condition_variable4waitERNS_11unique_lockINS_5mutexEEE
    __ZNSt3__118condition_variableD1Ev
    __ZNSt3__15mutex4lockEv
    __ZNSt3__15mutex6unlockEv
    __ZNSt3__15mutexD1Ev
)
for symbol in "${THREADING_SYMBOLS[@]}"; do
    definition_count=$(llvm-nm-18 --defined-only --extern-only --just-symbol-name \
        "$STAGE/lib/lib_FoundationICU.dylib" | grep -Fxc "$symbol" || true)
    [ "$definition_count" -eq 1 ] \
        || die "Foundation ICU threading definition count $definition_count for $symbol, expected 1"
done
icu_bridge_load_count=$(llvm-otool-18 -L "$STAGE/lib/lib_FoundationICU.dylib" \
    | awk '$1 == "/usr/lib/libOpenFoundationInternationalization.dylib" { count++ } END { print count + 0 }')
[ "$icu_bridge_load_count" -eq 1 ] \
    || die "Foundation ICU runtime bridge load count $icu_bridge_load_count, expected 1"

SWIFTC=(swiftc -target "$TARGET" -sdk "$STAGE/sdk" "${SWIFT_OVERLAY_FLAGS[@]}"
    -module-cache-path "$INTL_WORK/module-cache"
    -runtime-compatibility-version none -wmo
    -Xfrontend -disable-objc-attr-requires-foundation-module)
mapfile -d '' -t INTL_SOURCES < <(
    while IFS= read -r -d '' relative; do
        printf '%s\0' "$SWIFT_FOUNDATION/$relative"
    done < "$INTL_WORK/swift-sources.tracked.nul"
)
"${SWIFTC[@]}" -parse-as-library -package-name SwiftFoundation \
    -I "$STAGE/modules" \
    ${COLLECTIONS:+-I "$COLLECTIONS"} \
    ${OSMOD:+-I "$OSMOD"} \
    -Xcc -fmodule-map-file="$STAGE/include/FoundationICU/_foundation_unicode/module.modulemap" \
    -Xcc -I"$STAGE/include/FoundationICU" \
    -Xcc -fmodule-map-file="$STAGE/include/_FoundationCShims/module.modulemap" \
    -Xcc -I"$STAGE/include/_FoundationCShims" \
    -module-name FoundationInternationalization \
    -module-link-name FoundationInternationalization \
    -emit-module \
    -emit-module-path "$STAGE/modules/FoundationInternationalization.swiftmodule" \
    -emit-object -o "$INTL_WORK/FoundationInternationalization.o" \
    "${INTL_SOURCES[@]}"

ld64.lld-18 -arch "$LINK_ARCH" \
    -platform_version "$LINK_PLATFORM" "$MIN_OS" "$LINK_SDK_VERSION" \
    -syslibroot "$STAGE/sdk" -dylib -dead_strip -ignore_auto_link \
    -install_name "$DYLIB_INSTALL_PREFIX/libFoundationInternationalization.dylib" \
    -rpath @loader_path \
    -o "$STAGE/lib/libFoundationInternationalization.dylib" \
    "$INTL_WORK/FoundationInternationalization.o" \
    ${COLLECTIONS:+"$COLLECTIONS/InternalCollectionsUtilities.o"} \
    ${COLLECTIONS:+"$COLLECTIONS/OrderedCollections.o"} \
    ${COLLECTIONS:+"$COLLECTIONS/_RopeModule.o"} \
    ${OSMOD:+"$OSMOD/os.o"} \
    ${CSHIMS:+"$CSHIMS/platform_shims.o"} \
    ${CSHIMS:+"$CSHIMS/string_shims.o"} \
    ${CSHIMS:+"$CSHIMS/uuid.o"} \
    -L"$STAGE/lib" -lFoundationEssentials -l_FoundationICU \
    -L"$RUNTIME_LIB" -L"$STAGE/sdk/usr/lib/swift" \
    -lswiftCore -lswiftObjectiveC -lswift_StringProcessing \
    -lswift_Builtin_float "$RUNTIME_LIB/libswiftcompat.dylib" \
    -L"$STAGE/sdk/usr/lib" -lSystem -lobjc "$RUNTIME_LIB/libSystem.B.dylib"

for dylib in lib_FoundationICU.dylib libFoundationInternationalization.dylib; do
    llvm-otool-18 -hv "$STAGE/lib/$dylib" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
        || die "$dylib is not an ARM64 Mach-O dylib"
done
[ "$(llvm-otool-18 -D "$STAGE/lib/lib_FoundationICU.dylib" | tail -n 1)" = \
    "$DYLIB_INSTALL_PREFIX/lib_FoundationICU.dylib" ] \
    || die 'Foundation ICU dylib ID drifted'
[ "$(llvm-otool-18 -D "$STAGE/lib/libFoundationInternationalization.dylib" | tail -n 1)" = \
    "$DYLIB_INSTALL_PREFIX/libFoundationInternationalization.dylib" ] \
    || die 'FoundationInternationalization dylib ID drifted'

{
    printf 'format\topen-foundation-internationalization-abi-v1\n'
    printf 'symbol\trealpath\tguest-export=_realpath\tguest-host-import=_glibc_openui_foundation_intl_v1_realpath\thost-export=openui_foundation_intl_v1_realpath\n'
    printf 'buffer\tcaller-owned\tguest-bytes=1024\thost-max-bytes=4096\n'
} > "$STAGE/attestation/foundation-internationalization-abi.tsv"
{
    printf 'format\topen-foundation-internationalization-host-v1\n'
    printf 'operation\trealpath\tfixed-width-v1\n'
    printf 'ownership\tguest-buffer\tno-host-pointer-transfer\n'
    printf 'native-test\t%s\n' \
        "$(tr -d '\n' < "$INTL_WORK/open-foundation-internationalization-host-test.log")"
} > "$STAGE/attestation/foundation-internationalization-host.tsv"
{
    printf 'local\tdarwin/usr/lib/libOpenFoundationInternationalization.dylib\t%s\tbuilt from full/foundationinternationalization/OpenFoundationInternationalizationBridge.c\n' \
        "$(hash_file "$INTL_DARWIN")"
    printf 'local\thost/libOpenFoundationInternationalizationHost.so\t%s\tbuilt from full/foundationinternationalization/OpenFoundationInternationalizationHost.c\n' \
        "$(hash_file "$INTL_HOST")"
} >> "$STAGE/guest-root/.manifest"

assert_checkout "$SWIFT_FOUNDATION" "$EXPECTED_FOUNDATION_COMMIT" \
    "$EXPECTED_FOUNDATION_TREE" post-swift-foundation
assert_checkout "$SWIFT_FOUNDATION_ICU" "$EXPECTED_FOUNDATION_ICU_COMMIT" \
    "$EXPECTED_FOUNDATION_ICU_TREE" post-swift-foundation-icu

echo "FOUNDATION_INTERNATIONALIZATION_BUILD_OK swift=$intl_swift_count icu-cpp=$icu_cpp_count icu-headers=$icu_header_count"
