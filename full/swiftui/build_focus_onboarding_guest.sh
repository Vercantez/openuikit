#!/usr/bin/env bash
# Build Focus's exact SwiftUI Onboarding runtime sources as reusable Darwin
# Mach-O modules/dylibs and run a project-owned interaction harness on Linux.
# The TARGET triple follows the host; x86_64 output is
# build/focus-onboarding-guest-x86_64. Defaults to the in-repo uikit/ and
# machorun/ subtrees. External UIKIT=/path or MACHORUN=/path remain overrides.

set -euo pipefail

W=${W:-$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)}
# shellcheck source=../../scripts/vendor_tree.sh
. "$W/scripts/vendor_tree.sh"
# shellcheck disable=SC1091
. "$(cd "$(dirname "$0")" && pwd)/../scripts/guest_arch.inc"
UIKIT=${UIKIT:-$W/uikit}
MACHORUN=${MACHORUN:-$W/machorun}
RESOURCE_INPUT=${1:?usage: build_focus_onboarding_guest.sh <normalized-bundles-directory>}
FOCUS_REPO=$W/scratch/ladder-corpus/focus-ios/focus-ios
FOCUS_ROOT=$W/scratch/ladder-corpus/focus-ios
FOCUS_ONBOARDING=$FOCUS_REPO/BlockzillaPackage/Sources/Onboarding
FOCUS_WIDGET=$FOCUS_REPO/BlockzillaPackage/Sources/Widget
OUT=$W/build/focus-onboarding-guest${FULL_OUT_SUFFIX}
PACKAGE=$OUT/package
MODULE_CACHE=$OUT/module-cache
AUDIT=$OUT/audit
FULL=$W/build/full${FULL_OUT_SUFFIX}
SYS=$W/scratch/sysroot_fe4
MRROOT=$W/scratch/mrroot_full${FULL_OUT_SUFFIX}
SWIFT_FOUNDATION=$W/scratch/swift-foundation
OPENCOMBINE_ROOT=${OPENCOMBINE_ROOT:-$W/scratch/opencombine-core-durable-20260828-r2}
OPENCOMBINE_ARTIFACTS=$OPENCOMBINE_ROOT/export/artifacts
OPENCOMBINE_SOURCE=$OPENCOMBINE_ROOT/source
OPENCOMBINE_HELPERS=$OPENCOMBINE_SOURCE/Sources/COpenCombineHelpers
FOUNDATION_GUEST_MANIFEST=$W/full/foundation/foundation_guest_sources.txt

EXPECTED_FOCUS_COMMIT=a2832521c1daa0c23419c73705ae043ed60c9791
EXPECTED_UIKIT_TREE=$EXPECTED_INREPO_UIKIT_TREE
EXPECTED_FOCUS_SWIFT_COUNT=227
EXPECTED_ONBOARDING_TREE=3db199a93294a4ea0e6549522c29e8b2e4dbfb979bd60c07cdad5d00386734f5
EXPECTED_ONBOARDING_FILES=66
EXPECTED_ONBOARDING_DIRECTORIES=15
EXPECTED_WIDGET_TREE=144c49c747d4689d9ca98d353cb5474b311473629383a779d99f1b705969a04d
EXPECTED_WIDGET_FILES=16
EXPECTED_WIDGET_DIRECTORIES=7
EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS=19
EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS=2
EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS=0

EXPECTED_OPENCOMBINE_RESULT=c6fe4fa173f27fad0e30d1931c5ffead0aa267d55730a5885c1142bc7502b104
EXPECTED_OPENCOMBINE_OBJECT=96558e7d31c10c4bc769e9774977b74c58dc6ee83cfbd4fca8bf17229424a914
EXPECTED_OPENCOMBINE_MODULE=674d4d049d09b074b303822a88fcdc2c1d12c1e3cca9c9414ca30a74ee2c9de0
EXPECTED_OPENCOMBINE_DOC=a5a2757d33ccb621d26aea0f8ca417cf8ba748660faf1cf37eba53c5833975bc
EXPECTED_OPENCOMBINE_HELPER=73dbadeff3f6cebb9f5c57e09380e3166b65e68f0b0427d97d6a8ffdce693693
EXPECTED_OPENCOMBINE_HEADER=eb2afa8d9b46891a47ac39e43a4f94d727120acdbc0644934296c4c4ca62e935
EXPECTED_OPENCOMBINE_MODULEMAP=d34fdd050111a8cbf5ced89a129088fcfeb2964eea76ad518fafe044966572d1
EXPECTED_OPENCOMBINE_PATCH=875cd931e95c5442775e1042a412517ab7475be0489b1a81f824a54f6872c79b
EXPECTED_OPENCOMBINE_PATCHED_HELPER=d9fbefcdba66d892d9064c46b21b6084af217ddec1d604bcaf27b160de66083b
EXPECTED_COMBINE_SHIM=828b05c3a47296fb7b0b9ed5a6ca1a45a5da46e245441c21028335f60511799f
EXPECTED_SYSTEM_FONT=ae7b7855e115a5966d8b1b3f80f254ccc117ec86f9965e202ee2940453837280
EXPECTED_MEDIUM_FONT=5c1247acef7f2b8522a31742c76d6adcb5569bacc0be7ceaa4dc39dd252ce895
SYSTEM_FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
MEDIUM_FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf

die() {
    echo "focus_onboarding_guest: $*" >&2
    exit 2
}

hash_file() { sha256sum "$1" | awk '{print $1}'; }
hash_stream() { sha256sum | awk '{print $1}'; }

require_hash() {
    local file=$1 expected=$2 label=$3 actual
    [ -f "$file" ] && [ ! -L "$file" ] || die "missing regular $label: $file"
    actual=$(hash_file "$file")
    [ "$actual" = "$expected" ] || die "$label drifted: $actual"
}

tree_digest() {
    local root=$1
    (
        cd "$root"
        find . -type f -print0 | LC_ALL=C sort -z | while IFS= read -r -d '' file; do
            printf '%s\0%s\0' "${file#./}" "$(hash_file "$file")"
        done
    ) | hash_stream
}

assert_clean_commit() {
    local repo=$1 expected=$2 label=$3 expected_tree=${4:-} actual status actual_tree
    [ -d "$repo/.git" ] || die "$label is not a Git checkout: $repo"
    actual=$(git -C "$repo" rev-parse --verify HEAD^{commit})
    [ "$actual" = "$expected" ] || die "$label expected $expected, got $actual"
    if [ -n "$expected_tree" ]; then
        actual_tree=$(git -C "$repo" rev-parse --verify HEAD^{tree})
        [ "$actual_tree" = "$expected_tree" ] \
            || die "$label tree expected $expected_tree, got $actual_tree"
    fi
    status=$(git -C "$repo" status --porcelain=v1 --untracked-files=all)
    [ -z "$status" ] || die "$label checkout is not clean: $status"
}

validate_bundle() {
    local bundle=$1 files=$2 directories=$3 digest=$4 label=$5
    [ -d "$bundle" ] && [ ! -L "$bundle" ] || die "$label is not a real directory"
    local invalid actual_files actual_directories actual_digest
    invalid=$(find "$bundle" -mindepth 1 ! -type f ! -type d -print -quit)
    [ -z "$invalid" ] || die "$label contains a symlink/special node: $invalid"
    actual_files=$(find "$bundle" -type f | wc -l | tr -d '[:space:]')
    actual_directories=$(find "$bundle" -mindepth 1 -type d | wc -l | tr -d '[:space:]')
    [ "$actual_files" = "$files" ] || die "$label has $actual_files files, expected $files"
    [ "$actual_directories" = "$directories" ] \
        || die "$label has $actual_directories directories, expected $directories"
    actual_digest=$(tree_digest "$bundle")
    [ "$actual_digest" = "$digest" ] || die "$label tree drifted: $actual_digest"
}

[ "$OUT" = "$W/build/focus-onboarding-guest" ] \
    || die "derived output path invariant changed"
assert_vendor_tree "$W" uikit "$UIKIT" "$EXPECTED_UIKIT_TREE" OpenUIKit
assert_vendor_tree "$W" machorun "$MACHORUN" "$EXPECTED_INREPO_MACHORUN_TREE" machorun
if vendor_is_inrepo "$W" uikit "$UIKIT"; then
    echo "focus_onboarding_guest: attested OpenUIKit source=HEAD:uikit tree=$EXPECTED_UIKIT_TREE"
else
    echo "focus_onboarding_guest: attested OpenUIKit source=checkout tree=$EXPECTED_UIKIT_TREE"
fi
if vendor_is_inrepo "$W" machorun "$MACHORUN"; then
    echo "focus_onboarding_guest: attested machorun source=HEAD:machorun tree=$EXPECTED_INREPO_MACHORUN_TREE"
else
    echo "focus_onboarding_guest: attested machorun source=checkout tree=$EXPECTED_INREPO_MACHORUN_TREE"
fi
for tool in git swiftc clang-18 clang++-18 ld64.lld-18 llvm-nm-18 llvm-otool-18 \
    sha256sum patch; do
    command -v "$tool" >/dev/null || die "required tool is missing: $tool"
done
[ -x "$MRROOT/machorun" ] || die "built machorun root is missing: $MRROOT"
[ -d "$SYS/usr/include" ] || die "FoundationEssentials sysroot is missing: $SYS"

# One fail-closed manifest owns the production Foundation facade source set.
# Keep build order explicit: the umbrella/re-exports precede the concrete
# surfaces, and probes/tests are never compiler inputs here.
[ -f "$FOUNDATION_GUEST_MANIFEST" ] && [ ! -L "$FOUNDATION_GUEST_MANIFEST" ] \
    || die "missing regular Foundation guest source manifest"
mapfile -t FOUNDATION_GUEST_RELATIVE_SOURCES < "$FOUNDATION_GUEST_MANIFEST"
[ "${#FOUNDATION_GUEST_RELATIVE_SOURCES[@]}" -eq 38 ] \
    || die "Foundation guest source manifest must contain exactly 38 lines"
FOUNDATION_GUEST_SOURCES=()
FOUNDATION_GUEST_EXCLUDED_URLSESSION=0
for relative in "${FOUNDATION_GUEST_RELATIVE_SOURCES[@]}"; do
    case "$relative" in
        ''|/*|./*|../*|*/../*|*/./*|*//*|*[^A-Za-z0-9._+/-]*)
            die "invalid Foundation guest source path: $relative" ;;
    esac
    case "$relative" in
        full/appshim/*.swift|full/foundation/*.swift) ;;
        *) die "Foundation guest manifest escaped production source roots: $relative" ;;
    esac
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "Foundation guest source is not a regular file: $relative"
    # This legacy Focus-only harness runs against a read-only shared machorun
    # root and cannot stage the production Linux URL-transport helper there.
    # The relocatable core-package builder compiles the complete 38-source
    # facade; this bounded historical harness explicitly excludes URLSession.
    if [ "$relative" = full/foundation/URLSession.swift ]; then
        FOUNDATION_GUEST_EXCLUDED_URLSESSION=$((FOUNDATION_GUEST_EXCLUDED_URLSESSION + 1))
        continue
    fi
    for prior in "${FOUNDATION_GUEST_SOURCES[@]}"; do
        [ "$prior" != "$W/$relative" ] \
            || die "duplicate Foundation guest source: $relative"
    done
    FOUNDATION_GUEST_SOURCES+=("$W/$relative")
done
[ "$FOUNDATION_GUEST_EXCLUDED_URLSESSION" -eq 1 ] \
    && [ "${#FOUNDATION_GUEST_SOURCES[@]}" -eq 37 ] \
    || die 'legacy Focus Foundation exclusion contract drifted'

assert_clean_commit "$FOCUS_ROOT" "$EXPECTED_FOCUS_COMMIT" Focus
ONBOARDING_INPUT=$RESOURCE_INPUT/Focus_Onboarding.bundle
WIDGET_INPUT=$RESOURCE_INPUT/Focus_Widget.bundle
validate_bundle "$ONBOARDING_INPUT" "$EXPECTED_ONBOARDING_FILES" \
    "$EXPECTED_ONBOARDING_DIRECTORIES" "$EXPECTED_ONBOARDING_TREE" Onboarding-bundle
validate_bundle "$WIDGET_INPUT" "$EXPECTED_WIDGET_FILES" \
    "$EXPECTED_WIDGET_DIRECTORIES" "$EXPECTED_WIDGET_TREE" Widget-bundle

rm -rf -- "$OUT"
mkdir -p "$PACKAGE/include/CPortableIO" "$PACKAGE/include/CSTBTrueType" \
    "$PACKAGE/include/CHostClock" "$PACKAGE/include/COpenCombineHelpers" \
    "$PACKAGE/include/CQuartz" "$MODULE_CACHE" "$AUDIT" "$OUT/fonts"

git -C "$FOCUS_ROOT" ls-tree -r -z "$EXPECTED_FOCUS_COMMIT" -- focus-ios \
    | while IFS= read -r -d '' record; do
        case "$record" in
            *$'\t'*.swift) printf '%s\0' "$record" ;;
        esac
    done > "$AUDIT/focus-swift-tree.manifest"
actual_focus_swift_count=$(tr -cd '\0' < "$AUDIT/focus-swift-tree.manifest" \
    | wc -c | tr -d '[:space:]')
[ "$actual_focus_swift_count" = "$EXPECTED_FOCUS_SWIFT_COUNT" ] \
    || die "Focus Swift subject count changed: $actual_focus_swift_count"

SOURCE_RELATIVES=(
    'BlockzillaPackage/Sources/Widget/Assets.swift'
    'BlockzillaPackage/Sources/Widget/SearchWidgetView.swift'
    'BlockzillaPackage/Sources/Onboarding/DesignSystem/Color+AppColors.swift'
    'BlockzillaPackage/Sources/Onboarding/DesignSystem/Font+AppFonts.swift'
    'BlockzillaPackage/Sources/Onboarding/DesignSystem/Image+AppImages.swift'
    'BlockzillaPackage/Sources/Onboarding/PortraitHostingController.swift'
    'BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/CardBannerView.swift'
    'BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/DefaultBrowserOnboardingView.swift'
    'BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/GetStartedOnboardingView.swift'
    'BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/OnboardingView.swift'
    'BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/OnboardingViewModel.swift'
    'BlockzillaPackage/Sources/Onboarding/SwiftUI Onboarding/ShowMeHowOnboardingView.swift'
)
SOURCE_HASHES=(
    efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e
    721669388a4556e1609f580ed87d6065b63981770e71b0f77db292767b05f6c2
    d64850a384db3bfc2961cad6f7b1d9d3522f081fa19709462c11f41893615e81
    845f9756402af21481e34275d2cc294d602fa4df5d90e69548ea37c8e47a3300
    d6731252dc45289bc513b17cf1b4ba78e7c56b399e1b6a5942c8d1352b35ae54
    efd238b2b4b3481a7a6f0f1fd63f6d458d43731e70c9cc172a8a15aa9271dd77
    f74fe3774be86ed3ea54bb7c36b89db115eb3da72736c3366aba5b11a700c5aa
    0eebbfa3d4736fdd1e4caadd4c1806618cc18f85f54523b37898037c8ff800c6
    ef92bd5b89c44805b3177189ad5b3d3ad88be16f8d5e1f3307faf4c6500a87ef
    65cb54ccf6bc12863b8b1b026a825f826d850a71157f961c992ed6d6220b7952
    ae5c6d4c49d0a81fd1e7552051658c5bb116dd6b7f0d212044c3d1e33b3c24ff
    2ff75ad07ee409f05a61f7fe036e27b34a25142ccd464bbfc63642c35efe5291
)
[ "${#SOURCE_RELATIVES[@]}" -eq 12 ] || die "exact source inventory is not 12 files"
for index in "${!SOURCE_RELATIVES[@]}"; do
    require_hash "$FOCUS_REPO/${SOURCE_RELATIVES[$index]}" \
        "${SOURCE_HASHES[$index]}" "Focus source ${SOURCE_RELATIVES[$index]}"
done

require_hash "$OPENCOMBINE_ROOT/export/RESULT.txt" "$EXPECTED_OPENCOMBINE_RESULT" OpenCombine-result
if [ "$ARCH" = arm64 ]; then
    require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" "$EXPECTED_OPENCOMBINE_OBJECT" OpenCombine-object
    require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftmodule" "$EXPECTED_OPENCOMBINE_MODULE" OpenCombine-module
    require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftdoc" "$EXPECTED_OPENCOMBINE_DOC" OpenCombine-doc
else
    if ! llvm-otool-18 -hv "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" 2>/dev/null \
        | grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}"; then
        die "NEEDS_X86_OPENCOMBINE: OpenCombine.o is not $ARCH (arm64 durable SHA $EXPECTED_OPENCOMBINE_OBJECT still stands; rebuild for $TARGET beside that tree)"
    fi
fi
require_hash "$OPENCOMBINE_HELPERS/COpenCombineHelpers.cpp" "$EXPECTED_OPENCOMBINE_HELPER" OpenCombine-helper
require_hash "$OPENCOMBINE_HELPERS/include/COpenCombineHelpers.h" "$EXPECTED_OPENCOMBINE_HEADER" OpenCombine-header
require_hash "$OPENCOMBINE_HELPERS/include/module.modulemap" "$EXPECTED_OPENCOMBINE_MODULEMAP" OpenCombine-modulemap
require_hash "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch" \
    "$EXPECTED_OPENCOMBINE_PATCH" OpenCombine-patch
require_hash "$W/full/oracle-opencombine/Combine.swift" "$EXPECTED_COMBINE_SHIM" Combine-shim
require_hash "$SYSTEM_FONT" "$EXPECTED_SYSTEM_FONT" system-font
require_hash "$MEDIUM_FONT" "$EXPECTED_MEDIUM_FONT" medium-font

echo '== rebuild complete FoundationEssentials/OpenUIKit production substrate'
bash "$W/full/scripts/build_full.sh"
expected_subject=$(bash "$W/full/scripts/uihelpers_subject.sh" "$W" "$UIKIT")
actual_subject=$(tr -d '[:space:]' < "$FULL/uihelpers-subject.sha256")
[ "$actual_subject" = "$expected_subject" ] || die "build_full subject marker is stale"

cp -a "$ONBOARDING_INPUT" "$OUT/Focus_Onboarding.bundle"
cp -a "$WIDGET_INPUT" "$OUT/Focus_Widget.bundle"
validate_bundle "$OUT/Focus_Onboarding.bundle" "$EXPECTED_ONBOARDING_FILES" \
    "$EXPECTED_ONBOARDING_DIRECTORIES" "$EXPECTED_ONBOARDING_TREE" staged-Onboarding-bundle
validate_bundle "$OUT/Focus_Widget.bundle" "$EXPECTED_WIDGET_FILES" \
    "$EXPECTED_WIDGET_DIRECTORIES" "$EXPECTED_WIDGET_TREE" staged-Widget-bundle
cp "$SYSTEM_FONT" "$OUT/fonts/DejaVuSans.ttf"
cp "$MEDIUM_FONT" "$OUT/fonts/DejaVuSans-Bold.ttf"
require_hash "$OUT/fonts/DejaVuSans.ttf" "$EXPECTED_SYSTEM_FONT" staged-system-font
require_hash "$OUT/fonts/DejaVuSans-Bold.ttf" "$EXPECTED_MEDIUM_FONT" staged-medium-font

cp -a "$FULL/inc/CPortableIO/." "$PACKAGE/include/CPortableIO/"
cp -a "$FULL/inc/CSTBTrueType/." "$PACKAGE/include/CSTBTrueType/"
cp -a "$W/full/hostclock/include/." "$PACKAGE/include/CHostClock/"
cp -a "$UIKIT/Sources/CQuartz/include/." "$PACKAGE/include/CQuartz/"
cp -a "$W/full/foundation/include/COpenFoundationCore" \
    "$PACKAGE/include/COpenFoundationCore"
cp "$OPENCOMBINE_HELPERS/include/COpenCombineHelpers.h" \
    "$OPENCOMBINE_HELPERS/include/module.modulemap" "$PACKAGE/include/COpenCombineHelpers/"
cp "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftmodule" \
    "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftdoc" "$PACKAGE/"
for module in OpenUIKit OpenCoreGraphics; do
    for suffix in swiftmodule swiftdoc swiftsourceinfo abi.json; do
        cp "$FULL/$module.$suffix" "$PACKAGE/$module.$suffix"
    done
done

SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS"
    -module-cache-path "$MODULE_CACHE" -runtime-compatibility-version none -wmo
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch "$ARCH" -platform_version macos 15.0 15.0
    -syslibroot "$SYS" -rpath /usr/lib/swift)
PACKAGE_CINC=(-Xcc -I"$PACKAGE/include/CPortableIO"
    -Xcc -I"$PACKAGE/include/CSTBTrueType"
    -Xcc -I"$PACKAGE/include/CHostClock"
    -Xcc -I"$PACKAGE/include/COpenCombineHelpers"
    -Xcc -I"$PACKAGE/include/CQuartz"
    -Xcc -fmodule-map-file="$PACKAGE/include/COpenFoundationCore/module.modulemap"
    -Xcc -I"$PACKAGE/include/COpenFoundationCore")
FE_OUT=$FULL/foundation/essentials
FE_COLLECTIONS=$FULL/foundation/collections
FE_OS=$FULL/foundation/os
FE_CSHIMS=$FULL/foundation/cshims
FE_FLAGS=(-I "$FE_OUT" -I "$FE_COLLECTIONS" -I "$FE_OS"
    -Xcc -fmodule-map-file="$SWIFT_FOUNDATION/Sources/_FoundationCShims/include/module.modulemap"
    -Xcc -I"$SWIFT_FOUNDATION/Sources/_FoundationCShims/include")
FE_OBJECTS=(
    "$FE_OUT/FoundationEssentials.o"
    "$FE_COLLECTIONS/InternalCollectionsUtilities.o"
    "$FE_COLLECTIONS/OrderedCollections.o"
    "$FE_COLLECTIONS/_RopeModule.o"
    "$FE_OS/os.o"
    "$FE_CSHIMS/platform_shims.o"
    "$FE_CSHIMS/string_shims.o"
    "$FE_CSHIMS/uuid.o"
    "$FE_OUT/fm_unimplemented.o"
    "$FE_OUT/removefile_compat.o"
    "$FE_OUT/uuid_compat.o"
)
FOUNDATION_RUNTIME_BASENAMES=(
    libswift_StringProcessing
    libswiftSynchronization
)
FOUNDATION_RUNTIME_LINK_FLAGS=(
    -lswift_StringProcessing
    -lswiftSynchronization
)
FOUNDATION_RUNTIME_INSTALL_NAMES=(
    /usr/lib/swift/libswift_StringProcessing.dylib
    /usr/lib/swift/libswiftSynchronization.dylib
)
[ "${#FOUNDATION_RUNTIME_BASENAMES[@]}" -eq 2 ] \
    && [ "${#FOUNDATION_RUNTIME_LINK_FLAGS[@]}" -eq 2 ] \
    && [ "${#FOUNDATION_RUNTIME_INSTALL_NAMES[@]}" -eq 2 ] \
    || die 'Foundation runtime closure cardinality drifted'
for index in 0 1; do
    library=${FOUNDATION_RUNTIME_BASENAMES[$index]}
    install_name=${FOUNDATION_RUNTIME_INSTALL_NAMES[$index]}
    link_input=$SYS/usr/lib/swift/$library.tbd
    runtime_input=$MRROOT/darwin$install_name
    [ -f "$link_input" ] && [ ! -L "$link_input" ] \
        || die "Foundation runtime link input is missing: $link_input"
    [ -f "$runtime_input" ] && [ ! -L "$runtime_input" ] \
        || die "Foundation staged runtime dylib is missing: $runtime_input"
    actual_id=$(llvm-otool-18 -D "$runtime_input" | tail -n 1)
    [ "$actual_id" = "$install_name" ] \
        || die "Foundation staged runtime ID $actual_id, expected $install_name"
done

# A cold cache must build the SDK's textual Swift module before it recursively
# builds _Concurrency for the pinned binary OpenCombine module.  With the
# Swift 6.2.4 Linux compiler and Apple Swift 6.2.1 SDK interfaces, asking one
# frontend invocation to build both can leave Swift cached but fail the nested
# _Concurrency build.  Prewarming only Swift, with implicit stdlib imports
# disabled by -parse-stdlib, makes the same clean-cache build deterministic.
echo '== prewarm the Darwin Swift module cache'
swiftc -target "$TARGET" -sdk "$SYS" \
    -module-cache-path "$MODULE_CACHE" -parse-stdlib -typecheck \
    -e 'import Swift'

echo '== package pinned OpenCombine and literal Combine'
cp "$OPENCOMBINE_HELPERS/COpenCombineHelpers.cpp" "$OUT/COpenCombineHelpers.cpp"
patch --batch --forward --fuzz=0 "$OUT/COpenCombineHelpers.cpp" \
    "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch"
require_hash "$OUT/COpenCombineHelpers.cpp" "$EXPECTED_OPENCOMBINE_PATCHED_HELPER" patched-OpenCombine-helper
clang++-18 -target "$TARGET" -isysroot "$SYS" -stdlib=libc++ -std=c++17 -O2 \
    -I "$PACKAGE/include/COpenCombineHelpers" -c "$OUT/COpenCombineHelpers.cpp" \
    -o "$OUT/copencombinehelpers.o"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libOpenCombine.dylib -rpath @loader_path \
    -o "$PACKAGE/libOpenCombine.dylib" \
    "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" "$OUT/copencombinehelpers.o" \
    "$SYS/usr/lib/swift/libswift_Concurrency.tbd" "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$MRROOT/darwin/usr/lib/libc++abi.dylib" "$SYS/usr/lib/libSystem.tbd" \
    "$MRROOT/darwin/usr/lib/libSystem.real.dylib" "$SYS/usr/lib/libobjc.tbd"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" -I "$PACKAGE" \
    -module-name Combine -emit-module -emit-module-path "$PACKAGE/Combine.swiftmodule" \
    -emit-object -o "$OUT/combine.o" "$W/full/oracle-opencombine/Combine.swift"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libCombine.dylib -rpath @loader_path \
    -reexport_library "$PACKAGE/libOpenCombine.dylib" \
    -o "$PACKAGE/libCombine.dylib" "$OUT/combine.o" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" "$SYS/usr/lib/libSystem.tbd"

echo '== compile SwiftUI with Foundation deliberately hidden'
swiftui_sources=("$UIKIT"/Sources/SwiftUI/*.swift)
[ "${#swiftui_sources[@]}" -eq 7 ] || die "expected the complete seven-source SwiftUI directory"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name SwiftUI \
    -emit-module -emit-module-path "$PACKAGE/SwiftUI.swiftmodule" \
    -emit-object -o "$OUT/swiftui.o" "${swiftui_sources[@]}"

echo '== compile the bounded Foundation umbrella after SwiftUI'
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name Foundation \
    -emit-module -emit-module-path "$PACKAGE/Foundation.swiftmodule" \
    -emit-object -o "$OUT/foundation.o" \
    "${FOUNDATION_GUEST_SOURCES[@]}"
llvm-nm-18 -u -j "$OUT/foundation.o" | LC_ALL=C sort -u \
    > "$AUDIT/foundation-undefined-symbols.txt"
foundation_string_processing_undefineds=$(awk \
    'index($0, "17_StringProcessing") { count++ } END { print count + 0 }' \
    "$AUDIT/foundation-undefined-symbols.txt")
foundation_synchronization_undefineds=$(awk \
    'index($0, "15Synchronization") { count++ } END { print count + 0 }' \
    "$AUDIT/foundation-undefined-symbols.txt")
foundation_regex_parser_undefineds=$(awk \
    'index($0, "12_RegexParser") { count++ } END { print count + 0 }' \
    "$AUDIT/foundation-undefined-symbols.txt")
[ "$foundation_string_processing_undefineds" -eq \
    "$EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS" ] \
    || die "Foundation StringProcessing undefined count $foundation_string_processing_undefineds, expected $EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS"
[ "$foundation_synchronization_undefineds" -eq \
    "$EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS" ] \
    || die "Foundation Synchronization undefined count $foundation_synchronization_undefineds, expected $EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS"
[ "$foundation_regex_parser_undefineds" -eq \
    "$EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS" ] \
    || die "Foundation RegexParser undefined count $foundation_regex_parser_undefineds, expected $EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS"

# build_full emitted a deliberately early literal UIKit identity-probe module
# before either app-facing Foundation module existed.  Pair that exact module
# with the reusable FoundationGuest output above to prove the aliases converge
# even across the Foundation-hidden branch.  This is not the final app-facing
# UIKit module: build_focus_package_guest rebuilds literal UIKit after this
# Foundation facade exists, which is the order required by all-source apps.
echo '== FoundationGuest/UIKit notification identity compile proof'
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -I "$FULL/uikitinc" \
    -module-name FoundationGuestNotificationIdentityProbe -typecheck \
    "$W/full/foundation/notification_foundation_extension_probe.swift" \
    "$W/full/foundation/notification_uikit_consumer_probe.swift" \
    "$W/full/foundation/notification_direct_import_probe.swift"

echo '== exact unchanged Focus Widget and Onboarding modules'
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name Widget \
    -emit-module -emit-module-path "$PACKAGE/Widget.swiftmodule" \
    -emit-object -o "$OUT/widget.o" \
    "$FOCUS_WIDGET/Assets.swift" "$FOCUS_WIDGET/SearchWidgetView.swift" \
    "$W/full/swiftui/FocusWidgetBundle.generated.swift"
onboarding_sources=(
    "$FOCUS_ONBOARDING/DesignSystem/Color+AppColors.swift"
    "$FOCUS_ONBOARDING/DesignSystem/Font+AppFonts.swift"
    "$FOCUS_ONBOARDING/DesignSystem/Image+AppImages.swift"
    "$FOCUS_ONBOARDING/PortraitHostingController.swift"
    "$FOCUS_ONBOARDING/SwiftUI Onboarding/CardBannerView.swift"
    "$FOCUS_ONBOARDING/SwiftUI Onboarding/DefaultBrowserOnboardingView.swift"
    "$FOCUS_ONBOARDING/SwiftUI Onboarding/GetStartedOnboardingView.swift"
    "$FOCUS_ONBOARDING/SwiftUI Onboarding/OnboardingView.swift"
    "$FOCUS_ONBOARDING/SwiftUI Onboarding/OnboardingViewModel.swift"
    "$FOCUS_ONBOARDING/SwiftUI Onboarding/ShowMeHowOnboardingView.swift"
)
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name Onboarding \
    -emit-module -emit-module-path "$PACKAGE/Onboarding.swiftmodule" \
    -emit-object -o "$OUT/onboarding.o" \
    "${onboarding_sources[@]}" "$W/full/swiftui/FocusOnboardingBundle.generated.swift"

echo '== package nine reusable guest dylibs'
"${LD[@]}" -dylib -dead_strip -install_name @rpath/libFoundationEssentials.dylib \
    -rpath @loader_path -L"$MRROOT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -o "$PACKAGE/libFoundationEssentials.dylib" \
    "${FE_OBJECTS[@]}" "$FULL/swiftcorepatch.o"
"${LD[@]}" -dylib -dead_strip -install_name @rpath/libOpenCoreGraphics.dylib \
    -rpath @loader_path -L"$MRROOT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -o "$PACKAGE/libOpenCoreGraphics.dylib" "$FULL/opencoregraphics.o"
"${LD[@]}" -dylib -dead_strip -install_name @rpath/libOpenUIKit.dylib \
    -rpath @loader_path -L"$PACKAGE" -lFoundationEssentials -lOpenCoreGraphics \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore -lswiftObjectiveC \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -o "$PACKAGE/libOpenUIKit.dylib" "$FULL/openuikit.o" \
    "$FULL/cportableio.o" "$FULL/cstbtruetype.o" "$FULL/hostclock.o" \
    "$FULL/swiftcorepatch.o"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libFoundation.dylib -rpath @loader_path \
    -o "$PACKAGE/libFoundation.dylib" "$OUT/foundation.o" \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore -lswiftObjectiveC \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$PACKAGE" -lFoundationEssentials -lOpenUIKit -lCombine -lOpenCombine \
    -L"$SYS/usr/lib/swift" "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib"
for install_name in "${FOUNDATION_RUNTIME_INSTALL_NAMES[@]}"; do
    load_count=$(llvm-otool-18 -L "$PACKAGE/libFoundation.dylib" \
        | awk -v expected="$install_name" '$1 == expected { count++ } END { print count + 0 }')
    [ "$load_count" -eq 1 ] \
        || die "libFoundation runtime load count $load_count for $install_name, expected 1"
done
"${LD[@]}" -dylib -dead_strip -install_name @rpath/libSwiftUI.dylib \
    -rpath @loader_path -L"$PACKAGE" \
    -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -o "$PACKAGE/libSwiftUI.dylib" "$OUT/swiftui.o"
"${LD[@]}" -dylib -dead_strip -install_name @rpath/libWidget.dylib \
    -rpath @loader_path -L"$PACKAGE" \
    -lSwiftUI -lOpenUIKit -lFoundationEssentials \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -o "$PACKAGE/libWidget.dylib" "$OUT/widget.o"
"${LD[@]}" -dylib -dead_strip -install_name @rpath/libOnboarding.dylib \
    -rpath @loader_path -L"$PACKAGE" \
    -lFoundation -lFoundationEssentials -lSwiftUI -lWidget -lOpenUIKit \
    -lCombine -lOpenCombine \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -o "$PACKAGE/libOnboarding.dylib" "$OUT/onboarding.o"

echo '== compile and link the project-owned guest harness'
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
    -c "$W/full/swiftui/FocusOnboardingUUIDProbe.c" -o "$OUT/uuid-probe.o"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name FocusOnboardingGuest \
    -emit-object -o "$OUT/guest-main.o" "$W/full/swiftui/FocusOnboardingGuestMain.swift"
"${LD[@]}" -dead_strip -exported_symbol __mh_execute_header \
    -rpath @loader_path/package -o "$OUT/focus_onboarding_guest" \
    "$OUT/guest-main.o" "$OUT/uuid-probe.o" \
    -L"$PACKAGE" -lOnboarding -lWidget -lFoundation -lFoundationEssentials \
    -lSwiftUI -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib"

for dylib in FoundationEssentials OpenCoreGraphics OpenUIKit Foundation \
    OpenCombine Combine SwiftUI Widget Onboarding; do
    llvm-otool-18 -hv "$PACKAGE/lib$dylib.dylib" \
        | grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}.*[[:space:]]DYLIB" \
        || die "lib$dylib is not a $ARCH Mach-O dylib"
    actual_id=$(llvm-otool-18 -D "$PACKAGE/lib$dylib.dylib" | tail -n 1)
    [ "$actual_id" = "@rpath/lib$dylib.dylib" ] \
        || die "lib$dylib install name changed: $actual_id"
done
llvm-otool-18 -hv "$OUT/focus_onboarding_guest" \
    | grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}.*[[:space:]]EXECUTE" \
    || die "guest is not a $ARCH Mach-O executable"

perl "$W/full/swiftui/focus_widget_guest_attest.pl" closure \
    --otool llvm-otool-18 --executable "$OUT/focus_onboarding_guest" \
    --package "$PACKAGE" --guest-root "$MRROOT" \
    > "$AUDIT/runtime-closure.manifest"

echo '== run exact Focus interaction path on Linux/machorun'
if [ "$(uname -m)" != aarch64 ] && [ "$(uname -m)" != arm64 ]; then
    echo "focus_onboarding_guest: compile/link may proceed on this VM; execution cannot" >&2
    bash "${W:-$(git rev-parse --show-toplevel)}/.cursor/refuse-arm64-execution.sh" \
        || exit $?
fi
(
    cd "$OUT"
    MACHORUN_ROOT="$MRROOT" "$MRROOT/machorun" ./focus_onboarding_guest \
        "$OUT/Focus_Onboarding.bundle" \
        "$OUT/Focus_Widget.bundle" \
        "$UIKIT/Sources/OpenUIKit/Resources" "$OUT/fonts"
) | tee "$OUT/runtime.log"
grep -Fx \
    'FOCUS_ONBOARDING_MACHO_GUEST_OK sources=12 pages=2 touches=3 uuid=full telemetry=getStartedAppeared,getStartedButtonTapped,defaultBrowserAppeared,defaultBrowserSettingsTapped,defaultBrowserSkip' \
    "$OUT/runtime.log" >/dev/null || die "exact runtime success marker is missing"

for index in "${!SOURCE_RELATIVES[@]}"; do
    require_hash "$FOCUS_REPO/${SOURCE_RELATIVES[$index]}" \
        "${SOURCE_HASHES[$index]}" "post-run Focus source ${SOURCE_RELATIVES[$index]}"
done
assert_clean_commit "$FOCUS_ROOT" "$EXPECTED_FOCUS_COMMIT" post-run-Focus
assert_vendor_tree "$W" uikit "$UIKIT" "$EXPECTED_UIKIT_TREE" post-run-OpenUIKit
assert_vendor_tree "$W" machorun "$MACHORUN" "$EXPECTED_INREPO_MACHORUN_TREE" post-run-machorun
validate_bundle "$RESOURCE_INPUT/Focus_Onboarding.bundle" "$EXPECTED_ONBOARDING_FILES" \
    "$EXPECTED_ONBOARDING_DIRECTORIES" "$EXPECTED_ONBOARDING_TREE" post-run-Onboarding-input
validate_bundle "$RESOURCE_INPUT/Focus_Widget.bundle" "$EXPECTED_WIDGET_FILES" \
    "$EXPECTED_WIDGET_DIRECTORIES" "$EXPECTED_WIDGET_TREE" post-run-Widget-input

{
    printf 'focus-swift-tree\t%s\n' "$(hash_file "$AUDIT/focus-swift-tree.manifest")"
    printf 'runtime-closure\t%s\n' "$(hash_file "$AUDIT/runtime-closure.manifest")"
    printf 'runtime-log\t%s\n' "$(hash_file "$OUT/runtime.log")"
    printf 'guest\t%s\n' "$(hash_file "$OUT/focus_onboarding_guest")"
    printf 'onboarding-bundle-accessor\t%s\n' \
        "$(hash_file "$W/full/swiftui/FocusOnboardingBundle.generated.swift")"
    printf 'widget-bundle-accessor\t%s\n' \
        "$(hash_file "$W/full/swiftui/FocusWidgetBundle.generated.swift")"
    for dylib in FoundationEssentials OpenCoreGraphics OpenUIKit Foundation \
        OpenCombine Combine SwiftUI Widget Onboarding; do
        printf 'lib%s\t%s\n' "$dylib" "$(hash_file "$PACKAGE/lib$dylib.dylib")"
    done
    printf 'onboarding-resources\t%s\n' "$(tree_digest "$OUT/Focus_Onboarding.bundle")"
    printf 'widget-resources\t%s\n' "$(tree_digest "$OUT/Focus_Widget.bundle")"
} > "$OUT/artifacts.sha256"

echo '== Focus Onboarding Mach-O guest proof passed'
cat "$OUT/artifacts.sha256"
