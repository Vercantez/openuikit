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
# shellcheck disable=SC1091
. "$(cd "$(dirname "$0")" && pwd)/guest_gate_inventories.inc"
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
SYS=$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}
MRROOT=$W/scratch/mrroot_full${FULL_OUT_SUFFIX}
SWIFT_FOUNDATION=$W/scratch/swift-foundation
SWIFT_FOUNDATION_ICU=${SWIFT_FOUNDATION_ICU:-$W/scratch/swift-foundation-icu}
FOUNDATION_INTERNATIONALIZATION_BUILDER=$W/full/foundationinternationalization/build_foundation_internationalization.sh
COREFOUNDATION_GUEST_MANIFEST=$W/full/foundation/corefoundation_guest_sources.txt
OPENCOMBINE_ROOT=${OPENCOMBINE_ROOT:-$W/scratch/opencombine-core-durable-20260828-r2}
OPENCOMBINE_ARTIFACTS=${OPENCOMBINE_ARTIFACTS:-$OPENCOMBINE_ROOT/export${FULL_OUT_SUFFIX}/artifacts}
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

assert_exact_text() {
    local label=$1 got=$2 expected=$3
    [ "$got" = "$expected" ] || {
        echo "focus_onboarding_guest: $label changed" >&2
        diff -u <(printf '%s\n' "$expected") <(printf '%s\n' "$got") >&2 || true
        exit 2
    }
}

link_map_inputs() {
    awk '
        /^# Object files:/ { in_inputs = 1; next }
        /^# Sections:/ { in_inputs = 0 }
        in_inputs { sub(/^\[[^]]+\][[:space:]]+/, ""); print }
    ' "$1"
}

run_link() {
    local name=$1
    shift
    {
        printf '%s-link' "$name"
        printf ' %q' "$@"
        printf '\n'
    }
    "$@"
}

assert_no_glibc_host_imports() {
    local image=$1 label=$2
    if llvm-nm-18 --undefined-only --extern-only --just-symbol-name "$image" \
        | grep -q '^_glibc_'; then
        die "$label imports _glibc_*; keep those in the run-local Darwin-root bridge"
    fi
}

# Every machorun invocation must print a site banner and use the same
# composed host preload plus the run-local Darwin overlay. Site names are
# how the log identifies which invocation printed rc=73.
run_machorun_site() {
    local site=$1
    shift
    echo "== machorun site: $site"
    LD_LIBRARY_PATH="$HOST_BRIDGE_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
    MACHORUN_ROOT="$RUNROOT" \
    "$MRROOT/machorun" "$@"
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

[ "$OUT" = "$W/build/focus-onboarding-guest${FULL_OUT_SUFFIX}" ] \
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
# The Darwin CoreFoundation header is the project-owned clean-room one
# (full/foundation/include/CoreFoundation, 55ff468e), beside its module map;
# the sysroot has no CoreFoundation.h at all (the arm64 authority's
# scratch/sysroot_fe4 carries none), and the Linux toolchain's copy must
# never be reached from a Darwin compile.
CF_HEADER_DIR=$W/full/foundation/include/CoreFoundation
[ -f "$CF_HEADER_DIR/CoreFoundation.h" ] && [ ! -L "$CF_HEADER_DIR/CoreFoundation.h" ] \
    || die "project CoreFoundation.h is missing: $CF_HEADER_DIR/CoreFoundation.h"
[ -f "$FOUNDATION_INTERNATIONALIZATION_BUILDER" ] && \
    [ ! -L "$FOUNDATION_INTERNATIONALIZATION_BUILDER" ] \
    || die "FoundationInternationalization builder is missing: $FOUNDATION_INTERNATIONALIZATION_BUILDER"
[ -d "$SWIFT_FOUNDATION_ICU/.git" ] \
    || die "swift-foundation-icu checkout is missing: $SWIFT_FOUNDATION_ICU"
[ -f "$COREFOUNDATION_GUEST_MANIFEST" ] && [ ! -L "$COREFOUNDATION_GUEST_MANIFEST" ] \
    || die "missing regular CoreFoundation guest source manifest"

# One fail-closed manifest owns the production Foundation facade source set.
# Keep build order explicit: the umbrella/re-exports precede the concrete
# surfaces, and probes/tests are never compiler inputs here.
[ -f "$FOUNDATION_GUEST_MANIFEST" ] && [ ! -L "$FOUNDATION_GUEST_MANIFEST" ] \
    || die "missing regular Foundation guest source manifest"
mapfile -t FOUNDATION_GUEST_RELATIVE_SOURCES < "$FOUNDATION_GUEST_MANIFEST"
[ "${#FOUNDATION_GUEST_RELATIVE_SOURCES[@]}" -eq 41 ] \
    || die "Foundation guest source manifest must contain exactly 41 lines"
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
    && [ "${#FOUNDATION_GUEST_SOURCES[@]}" -eq 40 ] \
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
    "$PACKAGE/include/COpenDispatch" "$PACKAGE/include/COpenRelativeTime" \
    "$PACKAGE/include/CQuartz" "$PACKAGE/include/CoreFoundation" \
    "$MODULE_CACHE" "$AUDIT" "$OUT/fonts" "$OUT/host"
RUNROOT=$OUT/runroot
echo '== clone shared machorun root into a writable run-local overlay'
# machorun's host_lookup/_glibc_ path only runs for images served from the
# darwin-root prefix map (is_runtime). The shared MRROOT is read-only, so
# stage those bridges in a per-run copy rather than $PACKAGE @rpath images.
[ "$RUNROOT" != "$MRROOT" ] \
    || die 'run-local overlay path collided with the shared machorun root'
mkdir -p "$RUNROOT"
cp -a "$MRROOT/." "$RUNROOT/"
chmod -R u+w "$RUNROOT"
mkdir -p "$RUNROOT/darwin/usr/lib"

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

OPENCOMBINE_RESULT=$OPENCOMBINE_ROOT/export${FULL_OUT_SUFFIX}/RESULT.txt
if [ -z "$FULL_OUT_SUFFIX" ]; then
    require_hash "$OPENCOMBINE_RESULT" "$EXPECTED_OPENCOMBINE_RESULT" OpenCombine-result
else
    [ -s "$OPENCOMBINE_RESULT" ] || die "NEEDS_X86_OPENCOMBINE: missing $OPENCOMBINE_RESULT (phase2 writes export-x86_64/RESULT.txt from the real x86 build; arm64 export/RESULT.txt SHA $EXPECTED_OPENCOMBINE_RESULT still stands)"
fi
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
cp -a "$W/full/dispatch/include/." "$PACKAGE/include/COpenDispatch/"
cp -a "$W/full/relativetime/include/." "$PACKAGE/include/COpenRelativeTime/"
# Darwin CoreFoundation clang module: the header comes from the Darwin sysroot
# only. Never -I the host toolchain's lib/swift (that is the Linux overlay
# that pulls /usr/lib/swift/CoreFoundation/CoreFoundation.h and setjmp.h).
cp "$CF_HEADER_DIR/CoreFoundation.h" \
    "$PACKAGE/include/CoreFoundation/CoreFoundation.h"
cp "$CF_HEADER_DIR/module.modulemap" \
    "$PACKAGE/include/CoreFoundation/module.modulemap"
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
    -Xfrontend -disable-objc-attr-requires-foundation-module
    -Xcc -isysroot -Xcc "$SYS"
    -Xcc -target -Xcc "$TARGET")
LD=(ld64.lld-18 -arch "$ARCH" -platform_version macos 15.0 15.0
    -syslibroot "$SYS" -rpath /usr/lib/swift)
PACKAGE_CINC=(-Xcc -I"$PACKAGE/include/CPortableIO"
    -Xcc -I"$PACKAGE/include/CSTBTrueType"
    -Xcc -I"$PACKAGE/include/CHostClock"
    -Xcc -fmodule-map-file="$PACKAGE/include/COpenCombineHelpers/module.modulemap"
    -Xcc -I"$PACKAGE/include/COpenCombineHelpers"
    -Xcc -fmodule-map-file="$PACKAGE/include/COpenDispatch/module.modulemap"
    -Xcc -I"$PACKAGE/include/COpenDispatch"
    -Xcc -I"$PACKAGE/include/CQuartz"
    -Xcc -fmodule-map-file="$PACKAGE/include/COpenFoundationCore/module.modulemap"
    -Xcc -I"$PACKAGE/include/COpenFoundationCore"
    -Xcc -fmodule-map-file="$PACKAGE/include/CoreFoundation/module.modulemap"
    -Xcc -I"$PACKAGE/include/CoreFoundation")
HOST_BRIDGE_DIR=$OUT/host
RELATIVE_TIME_RUNTIME=$RUNROOT/darwin/usr/lib/libOpenRelativeTime.dylib
RELATIVE_TIME_DARWIN=$PACKAGE/libOpenRelativeTime.dylib
RELATIVE_TIME_HOST=$HOST_BRIDGE_DIR/libOpenRelativeTimeHost.so
DISPATCH_DARWIN=$RUNROOT/darwin/usr/lib/libOpenDispatch.dylib
FOUNDATION_INTL_RUNTIME=$RUNROOT/darwin/usr/lib/libOpenFoundationInternationalization.dylib
FOUNDATION_INTL_DARWIN=$PACKAGE/libOpenFoundationInternationalization.dylib
FOUNDATION_INTL_HOST=$HOST_BRIDGE_DIR/libOpenFoundationInternationalizationHost.so
HOST_PRELOAD_DLSYM_PROBE=$W/full/swiftui/host_preload_dlsym_probe.c
MACHO_DEPENDENCY_REWRITER=$W/full/xcodeplan/rewrite_macho_dependency.py
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
    libswiftDarwin
    libswift_Concurrency
)
FOUNDATION_RUNTIME_LINK_FLAGS=(
    -lswift_StringProcessing
    -lswiftSynchronization
)
FOUNDATION_RUNTIME_INSTALL_NAMES=(
    /usr/lib/swift/libswift_StringProcessing.dylib
    /usr/lib/swift/libswiftSynchronization.dylib
    /usr/lib/swift/libswiftDarwin.dylib
    /usr/lib/swift/libswift_Concurrency.dylib
)
[ "${#FOUNDATION_RUNTIME_BASENAMES[@]}" -eq 4 ] \
    && [ "${#FOUNDATION_RUNTIME_LINK_FLAGS[@]}" -eq 2 ] \
    && [ "${#FOUNDATION_RUNTIME_INSTALL_NAMES[@]}" -eq 4 ] \
    || die 'Foundation runtime closure cardinality drifted'
for index in "${!FOUNDATION_RUNTIME_BASENAMES[@]}"; do
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
"${SWIFTC[@]}" -parse-stdlib -typecheck \
    -e 'import Swift'

echo '== package pinned OpenCombine and literal Combine'
cp "$OPENCOMBINE_HELPERS/COpenCombineHelpers.cpp" "$OUT/COpenCombineHelpers.cpp"
patch --batch --forward --fuzz=0 "$OUT/COpenCombineHelpers.cpp" \
    "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch"
require_hash "$OUT/COpenCombineHelpers.cpp" "$EXPECTED_OPENCOMBINE_PATCHED_HELPER" patched-OpenCombine-helper
clang++-18 -target "$TARGET" -isysroot "$SYS" -stdlib=libc++ -std=c++17 -O2 \
    -I "$PACKAGE/include/COpenCombineHelpers" -c "$OUT/COpenCombineHelpers.cpp" \
    -o "$OUT/copencombinehelpers.o"
run_link libOpenCombine "${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libOpenCombine.dylib -rpath @loader_path \
    -map "$AUDIT/libOpenCombine.link-map" \
    -o "$PACKAGE/libOpenCombine.dylib" \
    "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" "$OUT/copencombinehelpers.o" \
    "$SYS/usr/lib/swift/libswift_Concurrency.tbd" "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$MRROOT/darwin/usr/lib/libc++abi.dylib" "$SYS/usr/lib/libSystem.tbd" \
    "$MRROOT/darwin/usr/lib/libSystem.real.dylib" "$SYS/usr/lib/libobjc.tbd"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" -I "$PACKAGE" \
    -module-name Combine -emit-module -emit-module-path "$PACKAGE/Combine.swiftmodule" \
    -emit-object -o "$OUT/combine.o" "$W/full/oracle-opencombine/Combine.swift"
run_link libCombine "${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libCombine.dylib -rpath @loader_path \
    -reexport_library "$PACKAGE/libOpenCombine.dylib" \
    -map "$AUDIT/libCombine.link-map" \
    -o "$PACKAGE/libCombine.dylib" "$OUT/combine.o" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" "$SYS/usr/lib/libSystem.tbd"

echo '== compile the first-party Symbols value model while Foundation is hidden'
symbols_sources=("$UIKIT"/Sources/Symbols/*.swift)
[ "${#symbols_sources[@]}" -eq 1 ] || die 'Symbols source count changed before compile'
invalid_symbols_source=$(find "$UIKIT/Sources/Symbols" -mindepth 1 -maxdepth 1 \
    \( ! -type f -o ! -name '*.swift' \) -print -quit)
[ -z "$invalid_symbols_source" ] || die "unsupported Symbols source node: $invalid_symbols_source"
for symbols_source in "${symbols_sources[@]}"; do
    [ -f "$symbols_source" ] && [ ! -L "$symbols_source" ] \
        || die "Symbols source is not a regular non-symlink file: $symbols_source"
done
"${SWIFTC[@]}" -parse-as-library \
    -I "$PACKAGE" \
    -module-name Symbols -module-link-name Symbols \
    -emit-module -emit-module-path "$PACKAGE/Symbols.swiftmodule" \
    -emit-object -o "$OUT/symbols.o" \
    "${symbols_sources[@]}"
run_link libSymbols "${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libSymbols.dylib -rpath @loader_path \
    -map "$AUDIT/libSymbols.link-map" \
    -o "$PACKAGE/libSymbols.dylib" "$OUT/symbols.o" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    "$SYS/usr/lib/libSystem.tbd"
symbols_apple_load_count=$(llvm-otool-18 -L "$PACKAGE/libSymbols.dylib" \
    | awk '$1 ~ /^\/System\/Library\/Frameworks\/Symbols\.framework\// { count++ } \
        END { print count + 0 }')
[ "$symbols_apple_load_count" -eq 0 ] \
    || die "libSymbols Apple Symbols load count $symbols_apple_load_count, expected 0"

echo '== compile SwiftUI with Foundation deliberately hidden'
# The complete authoritative SwiftUI source directory, as the widget gate
# packages it: a hand-pinned count (seven, then eleven) silently refuses every
# new first-party runtime file (State.swift, TextAttributes.swift, ...) that
# View.swift already depends on. Refuse an empty or impure directory instead.
swiftui_sources=("$UIKIT"/Sources/SwiftUI/*.swift)
[ "${#swiftui_sources[@]}" -gt 0 ] || die "SwiftUI source inventory is empty"
invalid_swiftui_source=$(find "$UIKIT/Sources/SwiftUI" -mindepth 1 -maxdepth 1 \
    \( ! -type f -o ! -name '*.swift' \) -print -quit)
[ -z "$invalid_swiftui_source" ] || die "unsupported SwiftUI source node: $invalid_swiftui_source"
for swiftui_source in "${swiftui_sources[@]}"; do
    [ -f "$swiftui_source" ] && [ ! -L "$swiftui_source" ] \
        || die "SwiftUI source is not a regular non-symlink file: $swiftui_source"
done
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name SwiftUI \
    -emit-module -emit-module-path "$PACKAGE/SwiftUI.swiftmodule" \
    -emit-object -o "$OUT/swiftui.o" "${swiftui_sources[@]}"

# FoundationGuest.swift @_exported-imports FoundationInternationalization;
# the umbrella cannot be bounded without that module. Build it from the
# committed FI script against the same Darwin sysroot / FE module the
# gate already uses. Do not write the Darwin bridge into the shared
# machorun root: this harness keeps that tree read-only and stages the
# `_glibc_*` image in the run-local overlay so machorun will host-lookup.
echo '== build pinned FoundationInternationalization against the same sysroot'
for fe_artifact in FoundationEssentials.swiftmodule FoundationEssentials.swiftdoc; do
    [ -f "$FE_OUT/$fe_artifact" ] && [ ! -L "$FE_OUT/$fe_artifact" ] \
        || die "FoundationEssentials module artifact is missing: $FE_OUT/$fe_artifact"
    cp "$FE_OUT/$fe_artifact" "$PACKAGE/$fe_artifact"
done
"${LD[@]}" -dylib -dead_strip -install_name @rpath/libFoundationEssentials.dylib \
    -rpath @loader_path -L"$MRROOT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -o "$PACKAGE/libFoundationEssentials.dylib" \
    "${FE_OBJECTS[@]}" "$FULL/swiftcorepatch.o"
FINTL_STAGE=$OUT/fi-stage
FINTL_WORK=$OUT/fi-work
rm -rf -- "$FINTL_STAGE" "$FINTL_WORK"
mkdir -p "$FINTL_STAGE/guest-root/host" \
    "$FINTL_STAGE/guest-root/darwin/usr/lib" \
    "$FINTL_STAGE/include" \
    "$FINTL_STAGE/attestation" \
    "$FINTL_WORK"
ln -sfn "$SYS" "$FINTL_STAGE/sdk"
ln -sfn "$PACKAGE" "$FINTL_STAGE/lib"
ln -sfn "$PACKAGE" "$FINTL_STAGE/modules"
cp -a "$SWIFT_FOUNDATION/Sources/_FoundationCShims/include/." \
    "$FINTL_STAGE/include/_FoundationCShims/"
for fi_runtime in libc++.1.dylib libc++.real.dylib libc++abi.dylib \
    libSystem.B.dylib libSystem.real.dylib libswiftcompat.dylib; do
    [ -e "$MRROOT/darwin/usr/lib/$fi_runtime" ] \
        || die "FoundationInternationalization runtime dylib is missing: $MRROOT/darwin/usr/lib/$fi_runtime"
    ln -s "$MRROOT/darwin/usr/lib/$fi_runtime" \
        "$FINTL_STAGE/guest-root/darwin/usr/lib/$fi_runtime"
done
: > "$FINTL_STAGE/guest-root/.manifest"
env SUPPORT_ROOT="$W" SWIFT_FOUNDATION="$SWIFT_FOUNDATION" \
    SWIFT_FOUNDATION_ICU="$SWIFT_FOUNDATION_ICU" STAGE="$FINTL_STAGE" \
    WORK="$FINTL_WORK" TARGET="$TARGET" MIN_OS=15.0 \
    COLLECTIONS="$FE_COLLECTIONS" OSMOD="$FE_OS" CSHIMS="$FE_CSHIMS" \
    FOUNDATION_ICU_JOBS="${FOUNDATION_ICU_JOBS:-8}" \
    bash "$FOUNDATION_INTERNATIONALIZATION_BUILDER"
[ -f "$PACKAGE/FoundationInternationalization.swiftmodule" ] && \
    [ ! -L "$PACKAGE/FoundationInternationalization.swiftmodule" ] \
    || die 'FoundationInternationalization swiftmodule is missing after build'
[ -f "$PACKAGE/libFoundationInternationalization.dylib" ] && \
    [ ! -L "$PACKAGE/libFoundationInternationalization.dylib" ] \
    || die 'libFoundationInternationalization.dylib is missing after build'
[ -f "$PACKAGE/lib_FoundationICU.dylib" ] && \
    [ ! -L "$PACKAGE/lib_FoundationICU.dylib" ] \
    || die 'lib_FoundationICU.dylib is missing after build'

echo '== build the OpenFoundationInternationalization Darwin bridge and Linux host helper'
[ -f "$MACHO_DEPENDENCY_REWRITER" ] && [ ! -L "$MACHO_DEPENDENCY_REWRITER" ] \
    || die "Mach-O dependency rewriter is missing: $MACHO_DEPENDENCY_REWRITER"
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$W/full/foundationinternationalization/include" \
    -c "$W/full/foundationinternationalization/OpenFoundationInternationalizationBridge.c" \
    -o "$OUT/open-foundation-internationalization-bridge.o"
run_link libOpenFoundationInternationalizationRuntime "${LD[@]}" -dylib \
    -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenFoundationInternationalization.dylib \
    -map "$AUDIT/libOpenFoundationInternationalizationRuntime.link-map" \
    -o "$FOUNDATION_INTL_RUNTIME" \
    "$OUT/open-foundation-internationalization-bridge.o"
run_link libOpenFoundationInternationalization "${LD[@]}" -L"$MRROOT/darwin/usr/lib" -dylib -dead_strip \
    -ignore_auto_link \
    -install_name @rpath/libOpenFoundationInternationalization.dylib \
    -rpath @loader_path \
    -map "$AUDIT/libOpenFoundationInternationalization.link-map" \
    -o "$FOUNDATION_INTL_DARWIN" \
    -reexport_library "$FOUNDATION_INTL_RUNTIME" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib"
bash "$W/full/foundationinternationalization/build_host_helper.sh" \
    --repo "$W" --host-dir "$HOST_BRIDGE_DIR" \
    --include-dir "$W/full/foundationinternationalization/include"
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$W/full/foundationinternationalization/include" \
    "$W/full/foundationinternationalization/OpenFoundationInternationalizationHost.c" \
    "$W/full/foundationinternationalization/OpenFoundationInternationalizationHostTests.c" \
    -o "$OUT/open-foundation-internationalization-host-tests"
"$OUT/open-foundation-internationalization-host-tests" \
    > "$OUT/open-foundation-internationalization-host-test.log"
grep -Fx \
    'OPEN_FOUNDATION_INTERNATIONALIZATION_HOST_OK realpath=bounded,versioned' \
    "$OUT/open-foundation-internationalization-host-test.log" >/dev/null \
    || die 'FoundationInternationalization host marker is missing'
[ -f "$FOUNDATION_INTL_DARWIN" ] && [ ! -L "$FOUNDATION_INTL_DARWIN" ] \
    || die 'libOpenFoundationInternationalization.dylib is missing after build'
[ -f "$FOUNDATION_INTL_RUNTIME" ] && [ ! -L "$FOUNDATION_INTL_RUNTIME" ] \
    || die 'run-local OpenFoundationInternationalization Darwin bridge is missing'
[ -f "$FOUNDATION_INTL_HOST" ] && [ ! -L "$FOUNDATION_INTL_HOST" ] \
    || die 'libOpenFoundationInternationalizationHost.so is missing after build'
printf 'openui_foundation_intl_v1_realpath\n' \
    > "$AUDIT/foundation-intl-expected-elf.txt"
printf '_realpath\n' > "$AUDIT/foundation-intl-expected-mach-exports.txt"
printf '_glibc_openui_foundation_intl_v1_realpath\n' \
    > "$AUDIT/foundation-intl-expected-mach-imports.txt"
readelf --wide --syms "$FOUNDATION_INTL_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_foundation_intl_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$AUDIT/foundation-intl-elf-exports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$FOUNDATION_INTL_RUNTIME" | LC_ALL=C sort -u \
    > "$AUDIT/foundation-intl-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$FOUNDATION_INTL_RUNTIME" | LC_ALL=C sort -u \
    > "$AUDIT/foundation-intl-mach-imports.txt"
cmp "$AUDIT/foundation-intl-expected-elf.txt" \
    "$AUDIT/foundation-intl-elf-exports.txt" \
    || die 'FoundationInternationalization Linux helper exports drifted'
cmp "$AUDIT/foundation-intl-expected-mach-exports.txt" \
    "$AUDIT/foundation-intl-mach-exports.txt" \
    || die 'FoundationInternationalization Mach-O bridge exports drifted'
cmp "$AUDIT/foundation-intl-expected-mach-imports.txt" \
    "$AUDIT/foundation-intl-mach-imports.txt" \
    || die 'FoundationInternationalization Mach-O bridge host import drifted'
[ "$(llvm-otool-18 -D "$FOUNDATION_INTL_RUNTIME" | tail -n 1)" = \
    /usr/lib/libOpenFoundationInternationalization.dylib ] \
    || die 'run-local FoundationInternationalization Mach-O bridge ID drifted'
[ "$(llvm-otool-18 -D "$FOUNDATION_INTL_DARWIN" | tail -n 1)" = \
    @rpath/libOpenFoundationInternationalization.dylib ] \
    || die 'packaged FoundationInternationalization Mach-O bridge ID drifted'
assert_no_glibc_host_imports "$FOUNDATION_INTL_DARWIN" \
    'packaged OpenFoundationInternationalization facade'
fi_runtime_reexport_count=$(llvm-otool-18 -l "$FOUNDATION_INTL_DARWIN" \
    | awk '$1 == "cmd" { command = $2 }
        $1 == "name" && $2 == "/usr/lib/libOpenFoundationInternationalization.dylib" \
            && command == "LC_REEXPORT_DYLIB" { count++ }
        END { print count + 0 }')
[ "$fi_runtime_reexport_count" -eq 1 ] \
    || die "packaged FI facade Darwin-root reexport count $fi_runtime_reexport_count, expected 1"
icu_bridge_old=$(llvm-otool-18 -L "$PACKAGE/lib_FoundationICU.dylib" \
    | awk '$1 == "/usr/lib/libOpenFoundationInternationalization.dylib" { count++ } END { print count + 0 }')
icu_bridge_new=$(llvm-otool-18 -L "$PACKAGE/lib_FoundationICU.dylib" \
    | awk '$1 == "@rpath/libOpenFoundationInternationalization.dylib" { count++ } END { print count + 0 }')
[ "$icu_bridge_old" -eq 1 ] && [ "$icu_bridge_new" -eq 0 ] \
    || die "Foundation ICU runtime bridge load input drifted: old=$icu_bridge_old new=$icu_bridge_new"
python3 -B "$MACHO_DEPENDENCY_REWRITER" "$PACKAGE/lib_FoundationICU.dylib" \
    /usr/lib/libOpenFoundationInternationalization.dylib \
    @rpath/libOpenFoundationInternationalization.dylib
icu_bridge_old=$(llvm-otool-18 -L "$PACKAGE/lib_FoundationICU.dylib" \
    | awk '$1 == "/usr/lib/libOpenFoundationInternationalization.dylib" { count++ } END { print count + 0 }')
icu_bridge_new=$(llvm-otool-18 -L "$PACKAGE/lib_FoundationICU.dylib" \
    | awk '$1 == "@rpath/libOpenFoundationInternationalization.dylib" { count++ } END { print count + 0 }')
[ "$icu_bridge_old" -eq 0 ] && [ "$icu_bridge_new" -eq 1 ] \
    || die "Foundation ICU runtime bridge load rewrite drifted: old=$icu_bridge_old new=$icu_bridge_new"
PACKAGE_CINC+=(
    -Xcc -fmodule-map-file="$FINTL_STAGE/include/FoundationICU/_foundation_unicode/module.modulemap"
    -Xcc -I"$FINTL_STAGE/include/FoundationICU"
)

echo '== compile first-party CoreFoundation before the Foundation umbrella'
mapfile -t COREFOUNDATION_GUEST_RELATIVE_SOURCES < "$COREFOUNDATION_GUEST_MANIFEST"
[ "${#COREFOUNDATION_GUEST_RELATIVE_SOURCES[@]}" -eq 1 ] \
    || die "CoreFoundation guest source manifest must contain exactly 1 line"
COREFOUNDATION_GUEST_SOURCES=()
for relative in "${COREFOUNDATION_GUEST_RELATIVE_SOURCES[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "CoreFoundation guest source is not a regular file: $relative"
    COREFOUNDATION_GUEST_SOURCES+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name CoreFoundation -module-link-name CoreFoundation \
    -emit-module -emit-module-path "$PACKAGE/CoreFoundation.swiftmodule" \
    -emit-object -o "$OUT/corefoundation.o" \
    "${COREFOUNDATION_GUEST_SOURCES[@]}"

echo '== compile the project Dispatch module before the Foundation umbrella'
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$PACKAGE/include/COpenDispatch" \
    -c "$W/full/dispatch/OpenDispatchBridge.c" \
    -o "$OUT/open-dispatch-bridge.o"
run_link libOpenDispatch "${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenDispatch.dylib \
    -map "$AUDIT/libOpenDispatch.link-map" \
    -o "$DISPATCH_DARWIN" "$OUT/open-dispatch-bridge.o"
[ "$(llvm-otool-18 -D "$DISPATCH_DARWIN" | tail -n 1)" = \
    /usr/lib/libOpenDispatch.dylib ] \
    || die 'run-local OpenDispatch Mach-O bridge ID drifted'
dispatch_glibc=$(llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$DISPATCH_DARWIN" | grep -c '^_glibc_openui_dispatch_host_v1_' || true)
[ "$dispatch_glibc" -eq 12 ] \
    || die "run-local OpenDispatch host import count $dispatch_glibc, expected 12"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" \
    -I "$PACKAGE" \
    -module-name Dispatch -module-link-name Dispatch -emit-module \
    -emit-module-path "$PACKAGE/Dispatch.swiftmodule" \
    -emit-object -o "$OUT/dispatch.o" "$W/full/dispatch/Dispatch.swift"
run_link libDispatch "${LD[@]}" -dylib -dead_strip -ignore_auto_link -undefined dynamic_lookup \
    -install_name @rpath/libDispatch.dylib -rpath @loader_path \
    -map "$AUDIT/libDispatch.link-map" \
    -o "$PACKAGE/libDispatch.dylib" \
    "$OUT/dispatch.o" "$DISPATCH_DARWIN" \
    -L"$PACKAGE" -lOpenCombine \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift \
    -lswiftCore \
    "$SYS/usr/lib/swift/libswiftSynchronization.tbd" \
    "$SYS/usr/lib/swift/libswift_Concurrency.tbd" \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem "$MRROOT/darwin/usr/lib/libSystem.B.dylib"
[ -f "$PACKAGE/Dispatch.swiftmodule" ] && [ ! -L "$PACKAGE/Dispatch.swiftmodule" ] \
    || die 'project Dispatch swiftmodule is missing after build'
[ -f "$PACKAGE/libDispatch.dylib" ] && [ ! -L "$PACKAGE/libDispatch.dylib" ] \
    || die 'libDispatch.dylib is missing after build'
assert_no_glibc_host_imports "$PACKAGE/libDispatch.dylib" 'packaged libDispatch'
dispatch_open_load_count=$(llvm-otool-18 -L "$PACKAGE/libDispatch.dylib" \
    | awk '$1 == "/usr/lib/libOpenDispatch.dylib" { count++ } END { print count + 0 }')
[ "$dispatch_open_load_count" -eq 1 ] \
    || die "packaged libDispatch OpenDispatch load count $dispatch_open_load_count, expected 1"

echo '== compile the bounded Foundation umbrella after SwiftUI'
[ -f "$PACKAGE/include/COpenCombineHelpers/module.modulemap" ] && \
    [ ! -L "$PACKAGE/include/COpenCombineHelpers/module.modulemap" ] \
    && [ -f "$PACKAGE/include/COpenCombineHelpers/COpenCombineHelpers.h" ] && \
    [ ! -L "$PACKAGE/include/COpenCombineHelpers/COpenCombineHelpers.h" ] \
    || die 'packaged COpenCombineHelpers module map is missing from PACKAGE/include'
umbrella_swiftc=(
    "${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}"
    -Xcc -fmodule-map-file="$PACKAGE/include/COpenCombineHelpers/module.modulemap"
    -Xcc -I"$PACKAGE/include/COpenCombineHelpers"
    -I "$PACKAGE"
    -module-name Foundation
    -emit-module -emit-module-path "$PACKAGE/Foundation.swiftmodule"
    -emit-object -o "$OUT/foundation.o"
)
{
    printf 'umbrella-swiftc'
    printf ' %q' "${umbrella_swiftc[@]}"
    printf '\n'
}
"${umbrella_swiftc[@]}" "${FOUNDATION_GUEST_SOURCES[@]}"
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

echo '== build the OpenRelativeTime Darwin bridge and Linux host helper'
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$PACKAGE/include/COpenRelativeTime" \
    -c "$W/full/relativetime/OpenRelativeTimeBridge.c" \
    -o "$OUT/open-relative-time-bridge.o"
run_link libOpenRelativeTimeRuntime "${LD[@]}" -dylib -dead_strip \
    -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenRelativeTime.dylib \
    -map "$AUDIT/libOpenRelativeTimeRuntime.link-map" \
    -o "$RELATIVE_TIME_RUNTIME" "$OUT/open-relative-time-bridge.o"
run_link libOpenRelativeTime "${LD[@]}" -L"$MRROOT/darwin/usr/lib" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libOpenRelativeTime.dylib -rpath @loader_path \
    -map "$AUDIT/libOpenRelativeTime.link-map" \
    -o "$RELATIVE_TIME_DARWIN" \
    -reexport_library "$RELATIVE_TIME_RUNTIME" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib"
bash "$W/full/relativetime/build_host_helper.sh" \
    --repo "$W" --host-dir "$HOST_BRIDGE_DIR" \
    --include-dir "$PACKAGE/include/COpenRelativeTime"
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$PACKAGE/include/COpenRelativeTime" \
    "$W/full/relativetime/OpenRelativeTimeHost.c" \
    "$W/full/relativetime/OpenRelativeTimeHostTests.c" \
    -o "$OUT/open-relative-time-host-tests" -licui18n -licuuc -lm
"$OUT/open-relative-time-host-tests" \
    > "$OUT/open-relative-time-host-test.log"
grep -Fx \
    'OPEN_RELATIVE_TIME_HOST_OK icu=real locale=en,fr,de,ja styles=4 bounds=hard' \
    "$OUT/open-relative-time-host-test.log" >/dev/null \
    || die 'native relative-time semantic marker is missing'
[ -f "$RELATIVE_TIME_DARWIN" ] && [ ! -L "$RELATIVE_TIME_DARWIN" ] \
    || die 'libOpenRelativeTime.dylib is missing after build'
[ -f "$RELATIVE_TIME_RUNTIME" ] && [ ! -L "$RELATIVE_TIME_RUNTIME" ] \
    || die 'run-local OpenRelativeTime Darwin bridge is missing'
[ -f "$RELATIVE_TIME_HOST" ] && [ ! -L "$RELATIVE_TIME_HOST" ] \
    || die 'libOpenRelativeTimeHost.so is missing after build'
printf 'openui_relative_time_v1_format\n' \
    > "$AUDIT/relative-time-expected-elf.txt"
printf '_openui_relative_time_v1_format\n' \
    > "$AUDIT/relative-time-expected-mach-exports.txt"
printf '_glibc_openui_relative_time_v1_format\n' \
    > "$AUDIT/relative-time-expected-mach-imports.txt"
readelf --wide --syms "$RELATIVE_TIME_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_relative_time_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$AUDIT/relative-time-elf-exports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$RELATIVE_TIME_RUNTIME" | LC_ALL=C sort -u \
    > "$AUDIT/relative-time-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$RELATIVE_TIME_RUNTIME" | LC_ALL=C sort -u \
    > "$AUDIT/relative-time-mach-imports.txt"
cmp "$AUDIT/relative-time-expected-elf.txt" \
    "$AUDIT/relative-time-elf-exports.txt" \
    || die 'Linux relative-time helper exports drifted'
cmp "$AUDIT/relative-time-expected-mach-exports.txt" \
    "$AUDIT/relative-time-mach-exports.txt" \
    || die 'Mach-O relative-time bridge exports drifted'
cmp "$AUDIT/relative-time-expected-mach-imports.txt" \
    "$AUDIT/relative-time-mach-imports.txt" \
    || die 'Mach-O relative-time host imports drifted'
[ "$(llvm-otool-18 -D "$RELATIVE_TIME_RUNTIME" | tail -n 1)" = \
    /usr/lib/libOpenRelativeTime.dylib ] \
    || die 'run-local relative-time Mach-O bridge ID drifted'
[ "$(llvm-otool-18 -D "$RELATIVE_TIME_DARWIN" | tail -n 1)" = \
    @rpath/libOpenRelativeTime.dylib ] \
    || die 'packaged relative-time Mach-O facade ID drifted'
assert_no_glibc_host_imports "$RELATIVE_TIME_DARWIN" \
    'packaged OpenRelativeTime facade'
relative_time_runtime_reexport_count=$(llvm-otool-18 -l "$RELATIVE_TIME_DARWIN" \
    | awk '$1 == "cmd" { command = $2 }
        $1 == "name" && $2 == "/usr/lib/libOpenRelativeTime.dylib" \
            && command == "LC_REEXPORT_DYLIB" { count++ }
        END { print count + 0 }')
[ "$relative_time_runtime_reexport_count" -eq 1 ] \
    || die "packaged relative-time facade Darwin-root reexport count $relative_time_runtime_reexport_count, expected 1"

echo '== package ten reusable guest dylibs'
run_link libFoundationEssentials "${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libFoundationEssentials.dylib -rpath @loader_path \
    -L"$MRROOT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -map "$AUDIT/libFoundationEssentials.link-map" \
    -o "$PACKAGE/libFoundationEssentials.dylib" \
    "${FE_OBJECTS[@]}" "$FULL/swiftcorepatch.o"
run_link libOpenCoreGraphics "${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libOpenCoreGraphics.dylib -rpath @loader_path \
    -L"$MRROOT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -map "$AUDIT/libOpenCoreGraphics.link-map" \
    -o "$PACKAGE/libOpenCoreGraphics.dylib" "$FULL/opencoregraphics.o"
run_link libOpenUIKit "${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libOpenUIKit.dylib -rpath @loader_path \
    -L"$PACKAGE" -lFoundationEssentials -lOpenCoreGraphics \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore -lswiftObjectiveC \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -map "$AUDIT/libOpenUIKit.link-map" \
    -o "$PACKAGE/libOpenUIKit.dylib" "$FULL/openuikit.o" \
    "$FULL/cportableio.o" "$FULL/cstbtruetype.o" "$FULL/hostclock.o" \
    "$FULL/swiftcorepatch.o"
run_link libFoundation "${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libFoundation.dylib -rpath @loader_path \
    -map "$AUDIT/libFoundation.link-map" \
    -o "$PACKAGE/libFoundation.dylib" "$OUT/foundation.o" "$OUT/corefoundation.o" \
    "${FE_OBJECTS[@]}" \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore -lswiftObjectiveC \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$PACKAGE" -lFoundationEssentials -lFoundationInternationalization \
    -lDispatch -lOpenUIKit -lCombine -lOpenCombine \
    "$PACKAGE/libOpenCoreGraphics.dylib" \
    "$RELATIVE_TIME_RUNTIME" \
    -L"$SYS/usr/lib/swift" "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}" \
    "$SYS/usr/lib/swift/libswiftDarwin.tbd" \
    "$SYS/usr/lib/swift/libswift_Concurrency.tbd" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib"
for install_name in "${FOUNDATION_RUNTIME_INSTALL_NAMES[@]}"; do
    load_count=$(llvm-otool-18 -L "$PACKAGE/libFoundation.dylib" \
        | awk -v expected="$install_name" '$1 == expected { count++ } END { print count + 0 }')
    [ "$load_count" -eq 1 ] \
        || die "libFoundation runtime load count $load_count for $install_name, expected 1"
done
foundation_graphics_load_count=$(llvm-otool-18 -L "$PACKAGE/libFoundation.dylib" \
    | awk '$1 == "@rpath/libOpenCoreGraphics.dylib" { count++ } END { print count + 0 }')
[ "$foundation_graphics_load_count" -eq 1 ] \
    || die "libFoundation OpenCoreGraphics load count $foundation_graphics_load_count, expected 1"
foundation_relative_time_load_count=$(llvm-otool-18 -L "$PACKAGE/libFoundation.dylib" \
    | awk '$1 == "/usr/lib/libOpenRelativeTime.dylib" { count++ } END { print count + 0 }')
[ "$foundation_relative_time_load_count" -eq 1 ] \
    || die "libFoundation relative-time load count $foundation_relative_time_load_count, expected 1"
run_link libSwiftUI "${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libSwiftUI.dylib -rpath @loader_path \
    -L"$PACKAGE" \
    -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine -lSymbols -lFoundationEssentials \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -map "$AUDIT/libSwiftUI.link-map" \
    -o "$PACKAGE/libSwiftUI.dylib" "$OUT/swiftui.o"
run_link libWidget "${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libWidget.dylib -rpath @loader_path \
    -L"$PACKAGE" \
    -lSwiftUI -lOpenUIKit -lFoundationEssentials \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -map "$AUDIT/libWidget.link-map" \
    -o "$PACKAGE/libWidget.dylib" "$OUT/widget.o"
run_link libOnboarding "${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libOnboarding.dylib -rpath @loader_path \
    -L"$PACKAGE" \
    -lFoundation -lFoundationEssentials -lSwiftUI -lWidget -lOpenUIKit \
    -lCombine -lOpenCombine \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -map "$AUDIT/libOnboarding.link-map" \
    -o "$PACKAGE/libOnboarding.dylib" "$OUT/onboarding.o"

expected_openuikit_inputs=$(guest_gate_inventory onboarding inputs openuikit)
# removefile_compat.o is in FE_OBJECTS for the onboarding FE/umbrella
# command lines, but the widget FE map omits inputs that contribute no
# symbols (lld lists contributors, not the argv). Keep that object off the
# inventory until a real map shows it.
expected_foundationessentials_inputs=$(guest_gate_inventory onboarding inputs foundationessentials)
expected_opencoregraphics_inputs=$(guest_gate_inventory onboarding inputs opencoregraphics)
expected_swiftui_inputs=$(guest_gate_inventory onboarding inputs swiftui)
expected_opencombine_inputs=$(guest_gate_inventory onboarding inputs opencombine)
expected_combine_inputs=$(guest_gate_inventory onboarding inputs combine)
expected_symbols_inputs=$(guest_gate_inventory onboarding inputs symbols)
# Umbrella objects plus the four input classes the failed link named:
# libswift_Concurrency.tbd, libswiftDarwin.tbd, libOpenCoreGraphics.dylib,
# and the run-local OpenRelativeTime Darwin-root image. The package @rpath
# facade re-exports /usr/lib/libOpenRelativeTime.dylib, but ld64.lld's
# re-export search hits -L$PACKAGE first (same basename as the empty
# facade) and never reaches -L$RUNROOT. List the runtime dylib itself;
# that keeps LC_ID /usr/lib (machorun is_runtime) and binds the symbol.
# -ignore_auto_link means Darwin/Concurrency cannot ride in through autolink
# the way they do on FE.
expected_foundation_inputs=$(guest_gate_inventory onboarding inputs foundation)
expected_widget_inputs=$(guest_gate_inventory onboarding inputs widget)
expected_onboarding_inputs=$(guest_gate_inventory onboarding inputs onboarding)
assert_exact_text "libOpenUIKit linker inputs" \
    "$(link_map_inputs "$AUDIT/libOpenUIKit.link-map")" "$expected_openuikit_inputs"
assert_exact_text "libFoundationEssentials linker inputs" \
    "$(link_map_inputs "$AUDIT/libFoundationEssentials.link-map")" \
    "$expected_foundationessentials_inputs"
assert_exact_text "libOpenCoreGraphics linker inputs" \
    "$(link_map_inputs "$AUDIT/libOpenCoreGraphics.link-map")" \
    "$expected_opencoregraphics_inputs"
assert_exact_text "libSwiftUI linker inputs" \
    "$(link_map_inputs "$AUDIT/libSwiftUI.link-map")" "$expected_swiftui_inputs"
assert_exact_text "libOpenCombine linker inputs" \
    "$(link_map_inputs "$AUDIT/libOpenCombine.link-map")" "$expected_opencombine_inputs"
assert_exact_text "libCombine linker inputs" \
    "$(link_map_inputs "$AUDIT/libCombine.link-map")" "$expected_combine_inputs"
assert_exact_text "libSymbols linker inputs" \
    "$(link_map_inputs "$AUDIT/libSymbols.link-map")" "$expected_symbols_inputs"
assert_exact_text "libFoundation linker inputs" \
    "$(link_map_inputs "$AUDIT/libFoundation.link-map")" "$expected_foundation_inputs"
assert_exact_text "libWidget linker inputs" \
    "$(link_map_inputs "$AUDIT/libWidget.link-map")" "$expected_widget_inputs"
assert_exact_text "libOnboarding linker inputs" \
    "$(link_map_inputs "$AUDIT/libOnboarding.link-map")" "$expected_onboarding_inputs"
for required in libswift_Concurrency.tbd libswiftDarwin.tbd \
    libOpenCoreGraphics.dylib libOpenRelativeTime.dylib; do
    grep -Fq "$required" "$AUDIT/libFoundation.link-map" || \
        die "libFoundation link map omitted $required"
done

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
    -lSwiftUI -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine -lSymbols \
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib"

for dylib in FoundationEssentials OpenCoreGraphics OpenUIKit Foundation \
    FoundationInternationalization _FoundationICU OpenFoundationInternationalization \
    Dispatch OpenRelativeTime OpenCombine Combine \
    Symbols SwiftUI Widget Onboarding; do
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
    --package "$PACKAGE" --guest-root "$RUNROOT" \
    --arch "$ARCH" \
    > "$AUDIT/runtime-closure.manifest"
awk -F '\t' '
    $1 == "file" && $2 == "package/libOpenFoundationInternationalization.dylib" {
        files++
    }
    END { exit files == 1 ? 0 : 1 }
' "$AUDIT/runtime-closure.manifest" \
    || die 'runtime-closure inventory omitted package/libOpenFoundationInternationalization.dylib'
awk -F '\t' '
    $1 == "file" && $2 == "guest-root/darwin/usr/lib/libOpenFoundationInternationalization.dylib" {
        files++
    }
    END { exit files == 1 ? 0 : 1 }
' "$AUDIT/runtime-closure.manifest" \
    || die 'runtime-closure inventory omitted the run-local OpenFoundationInternationalization Darwin bridge'
awk -F '\t' '
    $1 == "file" && $2 == "guest-root/darwin/usr/lib/libOpenRelativeTime.dylib" {
        files++
    }
    END { exit files == 1 ? 0 : 1 }
' "$AUDIT/runtime-closure.manifest" \
    || die 'runtime-closure inventory omitted the run-local OpenRelativeTime Darwin bridge'
awk -F '\t' '
    $1 == "file" && $2 == "guest-root/darwin/usr/lib/libOpenDispatch.dylib" {
        files++
    }
    END { exit files == 1 ? 0 : 1 }
' "$AUDIT/runtime-closure.manifest" \
    || die 'runtime-closure inventory omitted the run-local OpenDispatch Darwin bridge'
awk -F '\t' '
    $1 == "edge" && $2 == "package/lib_FoundationICU.dylib" \
        && $4 == "@rpath/libOpenFoundationInternationalization.dylib" \
        && $5 == "package/libOpenFoundationInternationalization.dylib" {
        edges++
    }
    END { exit edges == 1 ? 0 : 1 }
' "$AUDIT/runtime-closure.manifest" \
    || die 'runtime-closure omitted the Foundation ICU @rpath OpenFoundationInternationalization edge'

echo '== run exact Focus interaction path on Linux/machorun'
echo '== build Linux Dispatch host bridge'
DISPATCH_HOST=$HOST_BRIDGE_DIR/libOpenDispatchHost.so
host_bridge_args=(
    --repo "$W"
    --host-dir "$HOST_BRIDGE_DIR"
    --work-dir "$OUT/host-work"
    --attestation-dir "$AUDIT"
    --ledger-style focus-onboarding
    --refuse-prefix 'focus_onboarding_guest: '
)
if [ "$(uname -m)" = aarch64 ] || [ "$(uname -m)" = arm64 ]; then
    host_bridge_args+=(--host-abi ELF64-AArch64)
else
    host_bridge_args+=(--skip-runtime-pin --host-abi "ELF64-$(uname -m)")
fi
bash "$W/full/dispatch/build_host_bridge.sh" "${host_bridge_args[@]}"
[ -f "$DISPATCH_HOST" ] && [ ! -L "$DISPATCH_HOST" ] \
    || die "Linux Dispatch host helper is missing: $DISPATCH_HOST"

echo '== compose Linux host preload'
# Frameworks PLATFORM_HOST_PRELOAD order is dispatch, FI, URL transport,
# relative-time. This harness excludes URLSession.swift, so it does not
# bind OpenURLTransport and omits that helper.
for helper in "$DISPATCH_HOST" "$FOUNDATION_INTL_HOST" "$RELATIVE_TIME_HOST"; do
    [ -f "$helper" ] && [ ! -L "$helper" ] \
        || die "Linux host helper is missing from the run preload: $helper"
done
EARLY_PLATFORM_HOST_PRELOAD=$DISPATCH_HOST:$FOUNDATION_INTL_HOST:$RELATIVE_TIME_HOST
printf 'LD_PRELOAD=%s\n' \
    "$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}"

echo '== host dlsym probe of composed LD_PRELOAD (loader-process RTLD_DEFAULT)'
[ -f "$HOST_PRELOAD_DLSYM_PROBE" ] && [ ! -L "$HOST_PRELOAD_DLSYM_PROBE" ] \
    || die "host dlsym probe source is missing: $HOST_PRELOAD_DLSYM_PROBE"
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -o "$OUT/host_preload_dlsym_probe" "$HOST_PRELOAD_DLSYM_PROBE"
LD_LIBRARY_PATH="$HOST_BRIDGE_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD${LD_PRELOAD:+:$LD_PRELOAD}" \
    "$OUT/host_preload_dlsym_probe" \
        openui_relative_time_v1_format \
        openui_dispatch_host_v1_get_global_queue \
        openui_foundation_intl_v1_realpath \
    | tee "$OUT/host-preload-dlsym.log"
for probe_symbol in openui_relative_time_v1_format \
    openui_dispatch_host_v1_get_global_queue \
    openui_foundation_intl_v1_realpath; do
    grep -Fx "dlsym hit: $probe_symbol" "$OUT/host-preload-dlsym.log" >/dev/null \
        || die "composed LD_PRELOAD did not export $probe_symbol to RTLD_DEFAULT"
done

if [ "$ARCH" = arm64 ] && [ "$(uname -m)" != aarch64 ] && [ "$(uname -m)" != arm64 ]; then
    echo "focus_onboarding_guest: compile/link may proceed on this VM; execution of arm64 guests cannot" >&2
    bash "${W:-$(git rev-parse --show-toplevel)}/.cursor/refuse-arm64-execution.sh" \
        || exit $?
fi
(
    cd "$OUT"
    run_machorun_site interaction-path ./focus_onboarding_guest \
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
        FoundationInternationalization _FoundationICU OpenFoundationInternationalization \
        Dispatch OpenRelativeTime OpenCombine Combine Symbols SwiftUI Widget Onboarding; do
        printf 'lib%s\t%s\n' "$dylib" "$(hash_file "$PACKAGE/lib$dylib.dylib")"
    done
    printf 'onboarding-resources\t%s\n' "$(tree_digest "$OUT/Focus_Onboarding.bundle")"
    printf 'widget-resources\t%s\n' "$(tree_digest "$OUT/Focus_Widget.bundle")"
} > "$OUT/artifacts.sha256"

echo '== Focus Onboarding Mach-O guest proof passed'
cat "$OUT/artifacts.sha256"
