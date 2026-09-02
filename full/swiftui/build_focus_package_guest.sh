#!/usr/bin/env bash
# Extend the accepted 12-source Focus onboarding guest with exact unchanged
# package targets: SnapKit 36 of 37, DesignSystem 7, Widget 2, Onboarding 21, and
# Licenses 2. Run Bundle, Published, constraint-lifecycle, plist decode, and
# SwiftUI navigation behavior under Linux/machorun.
# Defaults to the in-repo uikit/ and machorun/ subtrees. External UIKIT=/path
# or MACHORUN=/path checkouts remain overrides.

set -euo pipefail

W=${W:-$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)}
# shellcheck source=../../scripts/vendor_tree.sh
. "$W/scripts/vendor_tree.sh"
UIKIT=${UIKIT:-$W/uikit}
MACHORUN=${MACHORUN:-$W/machorun}
RESOURCE_INPUT=${1:?usage: build_focus_package_guest.sh <normalized-bundles-directory>}

FOCUS_ROOT=$W/scratch/ladder-corpus/focus-ios
FOCUS_REPO=$FOCUS_ROOT/focus-ios
FOCUS_SOURCES=$FOCUS_REPO/BlockzillaPackage/Sources
SNAPKIT_ROOT=$W/scratch/xcodeplan-deps/SnapKit
BASE=$W/build/focus-onboarding-guest
OUT=$W/build/focus-package-guest
PACKAGE=$OUT/package
MODULE_CACHE=$OUT/module-cache
AUDIT=$OUT/audit
FULL=$W/build/full
SYS=$W/scratch/sysroot_fe4
MRROOT=$W/scratch/mrroot_full
SWIFT_FOUNDATION=$W/scratch/swift-foundation

EXPECTED_FOCUS_COMMIT=a2832521c1daa0c23419c73705ae043ed60c9791
EXPECTED_UIKIT_TREE=$EXPECTED_INREPO_UIKIT_TREE
EXPECTED_SNAPKIT_COMMIT=e74fe2a978d1216c3602b129447c7301573cc2d8
EXPECTED_FOUNDATION_COMMIT=c6793ef0c19c2cbaeba5a0e52078f129afc7dcfc
EXPECTED_OPENCOMBINE_COMMIT=1c6f02c7ed8140c0ba7a783aaddb6e0685a0037b
EXPECTED_ONBOARDING_COUNT=21
EXPECTED_ONBOARDING_MANIFEST=3653d727155b031f93f0bb6532f49428f48b8c39476f61e9f703cf81ad10d243
EXPECTED_DESIGNSYSTEM_COUNT=7
EXPECTED_DESIGNSYSTEM_MANIFEST=fb619b923007c5e15a1d57f8f6a696377fe8fc991e211c66cb4ef62c8e385c66
EXPECTED_WIDGET_COUNT=2
EXPECTED_WIDGET_MANIFEST=e8f92a22ebf14849b8406e61b1ac531335ed6d0b937b6b629df25f7318f16e44
EXPECTED_LICENSES_COUNT=2
EXPECTED_LICENSES_MANIFEST=43273d263b95324f5598b3c423fa38801b3e8a20aff85f36a3cf792fe25fd53e
EXPECTED_SNAPKIT_TOTAL_COUNT=37
EXPECTED_SNAPKIT_COUNT=36
EXPECTED_SNAPKIT_MANIFEST=0e3d407c38d2edfe48fecd643ef36519883bdec12e93d31d4fde4945168f5194
EXPECTED_SNAPKIT_DEBUGGING_SHA=6af70d54a6e6fb112d87f8adb93caead0bc2afc472e4bbb04347bf591be3b3e3
EXPECTED_FOCUS_PACKAGE=2d29b769de137389f5613de6755211b255533375bf6003a2192f514e96899248
EXPECTED_FOCUS_RESOLVED=632a0df0276ba7828f456ae3964f158fb7115d05f175ddf637abdd7ab4a4633b
EXPECTED_SNAPKIT_PACKAGE=ebb3e3c90a96e832e848e577c04b0cb9f16723c487c0efa727114d49c0a5492a
EXPECTED_SNAPKIT_PRIVACY=a07418e5fe128e224cd37964bc21c503b7aa2f575e7b4927468478ad873214fe
EXPECTED_FOCUS_LICENSE=63812032c2b82d2eb8269ed63458192e2783a3274919bf751b7ec6c09791376d
EXPECTED_LIBRARY_LICENSES=560a8535f642e0f42ea9a4b155491256d4405e57dcca3f1565509ad6bf10f1d8
EXPECTED_PROVIDER_MARKER=c574e2edbf1969f408fc94e597304e30cdf22f4eee76b5c84d45afcb06ca1df3
ACCESSOR_ATTEST=$W/full/swiftui/focus_resource_accessor_attest.pl
ACCESSOR_ORACLE=$W/full/swiftui/FOCUS_RESOURCE_ACCESSOR_ORACLE.tsv

die() {
    echo "focus_package_guest: $*" >&2
    exit 2
}

hash_file() { sha256sum "$1" | awk '{print $1}'; }

require_hash() {
    local file=$1 expected=$2 label=$3 actual
    [ -f "$file" ] && [ ! -L "$file" ] || die "missing regular $label: $file"
    actual=$(hash_file "$file")
    [ "$actual" = "$expected" ] || die "$label drifted: $actual"
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

write_source_manifest() {
    local root=$1 output=$2
    shift 2
    : > "$output"
    local source relative
    for source in "$@"; do
        [ -f "$source" ] && [ ! -L "$source" ] \
            || die "source is not a regular file: $source"
        relative=${source#"$root"/}
        [ "$relative" != "$source" ] \
            || die "source is outside manifest root $root: $source"
        case "$relative" in
            *$'\t'*|*$'\r'*|*$'\n'*) die "unsafe source path: $relative" ;;
        esac
        printf '%s\t%s\n' "$relative" "$(hash_file "$source")" >> "$output"
    done
}

check_source_manifest() {
    local label=$1 expected_count=$2 expected_digest=$3 root=$4 output=$5
    shift 5
    [ "$#" -eq "$expected_count" ] \
        || die "$label source count $#, expected $expected_count"
    write_source_manifest "$root" "$output" "$@"
    local actual
    actual=$(hash_file "$output")
    [ "$actual" = "$expected_digest" ] \
        || die "$label source manifest drifted: $actual"
}

[ "$OUT" = "$W/build/focus-package-guest" ] \
    || die "derived output path invariant changed"
for tool in git swiftc ld64.lld-18 llvm-otool-18 sha256sum perl cmp; do
    command -v "$tool" >/dev/null || die "required tool is missing: $tool"
done
[ -x "$MRROOT/machorun" ] || die "built machorun root is missing: $MRROOT"
[ -d "$SYS/usr/include" ] || die "FoundationEssentials sysroot is missing: $SYS"

assert_clean_commit "$FOCUS_ROOT" "$EXPECTED_FOCUS_COMMIT" Focus
assert_clean_commit "$SNAPKIT_ROOT" "$EXPECTED_SNAPKIT_COMMIT" SnapKit
assert_vendor_tree "$W" uikit "$UIKIT" "$EXPECTED_UIKIT_TREE" OpenUIKit
assert_vendor_tree "$W" machorun "$MACHORUN" "$EXPECTED_INREPO_MACHORUN_TREE" machorun
assert_clean_commit "$SWIFT_FOUNDATION" "$EXPECTED_FOUNDATION_COMMIT" swift-foundation

OPENCOMBINE_ROOT=${OPENCOMBINE_ROOT:-$W/scratch/opencombine-core-durable-20260828-r2}
assert_clean_commit "$OPENCOMBINE_ROOT/source" "$EXPECTED_OPENCOMBINE_COMMIT" OpenCombine

mapfile -d '' -t SNAPKIT_ALL_SRCS < <(
    find "$SNAPKIT_ROOT/Sources" -maxdepth 1 -type f -name '*.swift' \
        -print0 | LC_ALL=C sort -z
)
mapfile -d '' -t SNAPKIT_SRCS < <(
    find "$SNAPKIT_ROOT/Sources" -maxdepth 1 -type f -name '*.swift' \
        ! -name Debugging.swift -print0 | LC_ALL=C sort -z
)
mapfile -d '' -t DESIGNSYSTEM_SRCS < <(
    find "$FOCUS_SOURCES/DesignSystem" -type f -name '*.swift' -print0 \
        | LC_ALL=C sort -z
)
mapfile -d '' -t WIDGET_SRCS < <(
    find "$FOCUS_SOURCES/Widget" -type f -name '*.swift' -print0 \
        | LC_ALL=C sort -z
)
mapfile -d '' -t ONBOARDING_SRCS < <(
    find "$FOCUS_SOURCES/Onboarding" -type f -name '*.swift' \
        ! -name Onboarding.generated.swift -print0 | LC_ALL=C sort -z
)
mapfile -d '' -t LICENSES_SRCS < <(
    find "$FOCUS_SOURCES/Licenses" -type f -name '*.swift' -print0 \
        | LC_ALL=C sort -z
)

rm -rf -- "$OUT"
mkdir -p "$AUDIT" "$MODULE_CACHE"
[ "${#SNAPKIT_ALL_SRCS[@]}" -eq "$EXPECTED_SNAPKIT_TOTAL_COUNT" ] \
    || die "SnapKit upstream source count ${#SNAPKIT_ALL_SRCS[@]}, expected $EXPECTED_SNAPKIT_TOTAL_COUNT"
[ "$((${#SNAPKIT_ALL_SRCS[@]} - ${#SNAPKIT_SRCS[@]}))" -eq 1 ] \
    || die "SnapKit exclusion count is not exactly one"
require_hash "$SNAPKIT_ROOT/Sources/Debugging.swift" \
    "$EXPECTED_SNAPKIT_DEBUGGING_SHA" SnapKit-Debugging.swift
{
    printf 'format\tsnapkit-source-exclusions-v1\n'
    printf 'source\tSources/Debugging.swift\t%s\texcluded\t%s\n' \
        "$EXPECTED_SNAPKIT_DEBUGGING_SHA" \
        'requires-NSObject-ObjC-dynamic-description-surface'
} > "$AUDIT/snapkit-exclusions.tsv"
check_source_manifest SnapKit "$EXPECTED_SNAPKIT_COUNT" \
    "$EXPECTED_SNAPKIT_MANIFEST" "$SNAPKIT_ROOT" "$AUDIT/snapkit-sources.tsv" \
    "${SNAPKIT_SRCS[@]}"
check_source_manifest DesignSystem "$EXPECTED_DESIGNSYSTEM_COUNT" \
    "$EXPECTED_DESIGNSYSTEM_MANIFEST" "$FOCUS_REPO" \
    "$AUDIT/designsystem-sources.tsv" "${DESIGNSYSTEM_SRCS[@]}"
check_source_manifest Widget "$EXPECTED_WIDGET_COUNT" \
    "$EXPECTED_WIDGET_MANIFEST" "$FOCUS_REPO" "$AUDIT/widget-sources.tsv" \
    "${WIDGET_SRCS[@]}"
check_source_manifest Onboarding "$EXPECTED_ONBOARDING_COUNT" \
    "$EXPECTED_ONBOARDING_MANIFEST" "$FOCUS_REPO" \
    "$AUDIT/onboarding-sources.tsv" "${ONBOARDING_SRCS[@]}"
check_source_manifest Licenses "$EXPECTED_LICENSES_COUNT" \
    "$EXPECTED_LICENSES_MANIFEST" "$FOCUS_REPO" "$AUDIT/licenses-sources.tsv" \
    "${LICENSES_SRCS[@]}"
require_hash "$FOCUS_SOURCES/Licenses/focus-ios.plist" \
    "$EXPECTED_FOCUS_LICENSE" Focus-license-resource
require_hash "$FOCUS_SOURCES/Licenses/license-list.plist" \
    "$EXPECTED_LIBRARY_LICENSES" library-licenses-resource
require_hash "$FOCUS_REPO/BlockzillaPackage/Package.swift" \
    "$EXPECTED_FOCUS_PACKAGE" Focus-Package.swift
require_hash \
    "$FOCUS_REPO/Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" \
    "$EXPECTED_FOCUS_RESOLVED" Focus-Package.resolved
require_hash "$SNAPKIT_ROOT/Package.swift" \
    "$EXPECTED_SNAPKIT_PACKAGE" SnapKit-Package.swift
require_hash "$SNAPKIT_ROOT/Sources/PrivacyInfo.xcprivacy" \
    "$EXPECTED_SNAPKIT_PRIVACY" SnapKit-privacy-resource

perl "$ACCESSOR_ATTEST" attest \
    --focus-root "$FOCUS_REPO" --snapkit-root "$SNAPKIT_ROOT" \
    --support-root "$W" --build-script "$W/full/swiftui/build_focus_package_guest.sh" \
    > "$AUDIT/resource-accessor-provenance.tsv"
cmp -s "$ACCESSOR_ORACLE" "$AUDIT/resource-accessor-provenance.tsv" \
    || die "resource accessor provenance diverged from reviewed SwiftPM 6.2.1 oracle"

echo '== preserve and rerun the accepted exact 12-source onboarding guest'
bash "$W/full/swiftui/build_focus_onboarding_guest.sh" "$RESOURCE_INPUT"

mkdir -p "$PACKAGE"
cp -a "$BASE/package/." "$PACKAGE/"

SWIFTC=(swiftc -target arm64-apple-macos15.0 -sdk "$SYS"
    -module-cache-path "$MODULE_CACHE" -runtime-compatibility-version none -wmo
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0
    -syslibroot "$SYS")
PACKAGE_CINC=(-Xcc -I"$PACKAGE/include/CPortableIO"
    -Xcc -I"$PACKAGE/include/CSTBTrueType"
    -Xcc -I"$PACKAGE/include/CHostClock"
    -Xcc -I"$PACKAGE/include/COpenCombineHelpers"
    -Xcc -I"$PACKAGE/include/CQuartz")
FE_OUT=$FULL/foundation/essentials
FE_COLLECTIONS=$FULL/foundation/collections
FE_OS=$FULL/foundation/os
FE_FLAGS=(-I "$FE_OUT" -I "$FE_COLLECTIONS" -I "$FE_OS"
    -Xcc -fmodule-map-file="$SWIFT_FOUNDATION/Sources/_FoundationCShims/include/module.modulemap"
    -Xcc -I"$SWIFT_FOUNDATION/Sources/_FoundationCShims/include")
COMMON_LINK=(-rpath @loader_path -L"$PACKAGE"
    -L"$MRROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore -lswiftObjectiveC
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib"
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib"
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib")

echo '== prewarm the package Darwin Swift module cache'
swiftc -target arm64-apple-macos15.0 -sdk "$SYS" \
    -module-cache-path "$MODULE_CACHE" -parse-stdlib -typecheck \
    -e 'import Swift'

# The onboarding stage already built OpenUIKit with Foundation hidden, then
# emitted the app-facing Foundation facade.  Build literal UIKit only now so
# its Foundation-visible branch re-exports that facade.  This is the final
# UIKit module consumed by the unchanged package sources; build_full's earlier
# UIKit artifact remains an identity/legacy-renderer probe only.
echo '== compile final app-facing UIKit after Foundation facade (SnapKit exclusion attested)'
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name UIKit \
    -emit-module -emit-module-path "$PACKAGE/UIKit.swiftmodule" \
    -emit-object -o "$OUT/uikit.o" "$UIKIT/Sources/UIKitShim/UIKit.swift"

# The inherited FoundationGuest umbrella and the literal UIKit module above
# are the exact modules the unchanged Focus package sources consume.  Re-run
# the split-import identity probe against this final package graph so neither
# the Foundation-visible UIKit branch nor packaging can reintroduce a rival
# notification declaration.
echo '== packaged Foundation/UIKit notification identity compile proof'
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name FocusPackageNotificationIdentityProbe -typecheck \
    "$W/full/foundation/notification_foundation_extension_probe.swift" \
    "$W/full/foundation/notification_uikit_consumer_probe.swift" \
    "$W/full/foundation/notification_direct_import_probe.swift"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name SnapKit \
    -emit-module -emit-module-path "$PACKAGE/SnapKit.swiftmodule" \
    -emit-object -o "$OUT/snapkit.o" "${SNAPKIT_SRCS[@]}" \
    "$W/full/swiftui/FocusSnapKitBundle.generated.swift"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name DesignSystem \
    -emit-module -emit-module-path "$PACKAGE/DesignSystem.swiftmodule" \
    -emit-object -o "$OUT/designsystem.o" "${DESIGNSYSTEM_SRCS[@]}" \
    "$W/full/swiftui/FocusDesignSystemBundle.generated.swift"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name Widget \
    -emit-module -emit-module-path "$PACKAGE/Widget.swiftmodule" \
    -emit-object -o "$OUT/widget.o" "${WIDGET_SRCS[@]}" \
    "$W/full/swiftui/FocusWidgetBundle.generated.swift"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name Onboarding \
    -emit-module -emit-module-path "$PACKAGE/Onboarding.swiftmodule" \
    -emit-object -o "$OUT/onboarding.o" "${ONBOARDING_SRCS[@]}" \
    "$W/full/swiftui/FocusOnboardingBundle.generated.swift"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name Licenses \
    -emit-module -emit-module-path "$PACKAGE/Licenses.swiftmodule" \
    -emit-object -o "$OUT/licenses.o" "${LICENSES_SRCS[@]}" \
    "$W/full/swiftui/FocusLicensesBundle.generated.swift"

echo '== link reusable package dylibs'
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libUIKit.dylib -o "$PACKAGE/libUIKit.dylib" \
    "$OUT/uikit.o" "${COMMON_LINK[@]}" \
    -lFoundation -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libSnapKit.dylib -o "$PACKAGE/libSnapKit.dylib" \
    "$OUT/snapkit.o" "${COMMON_LINK[@]}" \
    -lUIKit -lFoundation -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libDesignSystem.dylib -o "$PACKAGE/libDesignSystem.dylib" \
    "$OUT/designsystem.o" "${COMMON_LINK[@]}" \
    -lUIKit -lFoundation -lFoundationEssentials -lSwiftUI -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libWidget.dylib -o "$PACKAGE/libWidget.dylib" \
    "$OUT/widget.o" "${COMMON_LINK[@]}" \
    -lFoundation -lFoundationEssentials -lSwiftUI -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libOnboarding.dylib -o "$PACKAGE/libOnboarding.dylib" \
    "$OUT/onboarding.o" "${COMMON_LINK[@]}" \
    -lUIKit -lFoundation -lFoundationEssentials -lSwiftUI -lWidget \
    -lSnapKit -lDesignSystem -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libLicenses.dylib -o "$PACKAGE/libLicenses.dylib" \
    "$OUT/licenses.o" "${COMMON_LINK[@]}" \
    -lUIKit -lFoundation -lFoundationEssentials -lSwiftUI -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine

echo '== link and run Bundle/Published/SnapKit lifecycle probe'
PROBE_APP=$OUT/FocusPackageProbe.app
PROVIDER=$PACKAGE/FocusPackageProbe.framework
SNAPKIT_BUNDLE=$PROBE_APP/SnapKit_SnapKit.bundle
mkdir -p "$PROBE_APP/Contents/MacOS" "$PROBE_APP/Contents/Resources" \
    "$PROVIDER/Resources" "$OUT/FlatResources.bundle" "$SNAPKIT_BUNDLE"
printf 'present\n' > "$OUT/FlatResources.bundle/present.txt"
printf 'focus-package-provider\n' \
    > "$PROVIDER/Resources/bundle-provider-marker.txt"
cp "$SNAPKIT_ROOT/Sources/PrivacyInfo.xcprivacy" "$SNAPKIT_BUNDLE/"
require_hash "$PROVIDER/Resources/bundle-provider-marker.txt" \
    "$EXPECTED_PROVIDER_MARKER" dynamic-Bundle-provider-marker
require_hash "$SNAPKIT_BUNDLE/PrivacyInfo.xcprivacy" \
    "$EXPECTED_SNAPKIT_PRIVACY" staged-SnapKit-privacy-resource
[ "$(find "$SNAPKIT_BUNDLE" -mindepth 1 -maxdepth 1 -type f | wc -l)" -eq 1 ] \
    || die "SnapKit_SnapKit.bundle file inventory is not exactly one"
[ -z "$(find "$SNAPKIT_BUNDLE" -mindepth 1 ! -type f -print -quit)" ] \
    || die "SnapKit_SnapKit.bundle contains a non-file node"
"${SWIFTC[@]}" -parse-as-library -module-name FocusPackageBundleProvider \
    -emit-module -emit-module-path "$PACKAGE/FocusPackageBundleProvider.swiftmodule" \
    -emit-object -o "$OUT/provider.o" \
    "$W/full/swiftui/FocusPackageBundleProvider.swift"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/FocusPackageProbe.framework/FocusPackageProbe \
    -o "$PROVIDER/FocusPackageProbe" "$OUT/provider.o" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$SYS/usr/lib/swift/libswiftObjectiveC.tbd" \
    "$SYS/usr/lib/libSystem.tbd" "$SYS/usr/lib/libobjc.tbd"
"${SWIFTC[@]}" "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" -I "$PACKAGE" \
    -module-name FocusPackageRuntimeProbe -emit-object \
    -o "$OUT/package-probe.o" "$W/full/swiftui/FocusPackageRuntimeProbe.swift"
"${LD[@]}" -dead_strip -ignore_auto_link -exported_symbol __mh_execute_header \
    -rpath @loader_path/../../../package -rpath @executable_path/../Frameworks \
    -o "$PROBE_APP/Contents/MacOS/FocusPackageProbe" \
    "$OUT/package-probe.o" "$PROVIDER/FocusPackageProbe" \
    "${COMMON_LINK[@]}" -lOnboarding -lWidget -lSnapKit -lDesignSystem \
    -lUIKit -lFoundation -lFoundationEssentials -lSwiftUI -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine
perl "$W/full/swiftui/focus_widget_guest_attest.pl" closure \
    --otool llvm-otool-18 \
    --executable "$PROBE_APP/Contents/MacOS/FocusPackageProbe" \
    --package "$PACKAGE" --guest-root "$MRROOT" \
    > "$AUDIT/package-runtime-closure.manifest"
grep -Fqx $'file\tpackage/FocusPackageProbe.framework/FocusPackageProbe\t'\
"$(hash_file "$PROVIDER/FocusPackageProbe")" \
    "$AUDIT/package-runtime-closure.manifest" \
    || die "dynamic Bundle provider is absent from recursive runtime closure"
(
    cd "$OUT"
    MACHORUN_ROOT="$MRROOT" "$MRROOT/machorun" \
        "$PROBE_APP/Contents/MacOS/FocusPackageProbe" \
        "$PROBE_APP" "$OUT/FlatResources.bundle" "$PROVIDER"
) | tee "$OUT/package-runtime.log"
grep -Fx 'FOCUS_PACKAGE_FOUNDATION_OK bundle=main,flat,dynamic resource=url' \
    "$OUT/package-runtime.log" >/dev/null \
    || die "Foundation runtime marker is missing"
grep -Fx 'FOCUS_PACKAGE_PUBLISHED_OK handlers=v1,v2' \
    "$OUT/package-runtime.log" >/dev/null \
    || die "Published runtime marker is missing"
grep -Fx \
    'FOCUS_PACKAGE_SNAPKIT_OK lifecycle=add,remove set=identity,equality,retention resource=privacy' \
    "$OUT/package-runtime.log" >/dev/null \
    || die "SnapKit runtime marker is missing"

echo '== run exact Focus Licenses two-source/two-resource SwiftUI path'
LICENSES_APP=$OUT/FocusLicensesGuest.app
LICENSES_BUNDLE=$LICENSES_APP/Focus_Licenses.bundle
mkdir -p "$LICENSES_APP/Contents/MacOS" "$LICENSES_APP/Contents/Resources" \
    "$LICENSES_BUNDLE"
cp "$FOCUS_SOURCES/Licenses/focus-ios.plist" \
    "$FOCUS_SOURCES/Licenses/license-list.plist" \
    "$LICENSES_BUNDLE/"
require_hash "$LICENSES_BUNDLE/focus-ios.plist" \
    "$EXPECTED_FOCUS_LICENSE" staged-Focus-license-resource
require_hash "$LICENSES_BUNDLE/license-list.plist" \
    "$EXPECTED_LIBRARY_LICENSES" staged-library-licenses-resource
[ "$(find "$LICENSES_BUNDLE" -mindepth 1 -maxdepth 1 -type f | wc -l)" -eq 2 ] \
    || die "Focus_Licenses.bundle file inventory is not exactly two"
[ -z "$(find "$LICENSES_BUNDLE" -mindepth 1 ! -type f -print -quit)" ] \
    || die "Focus_Licenses.bundle contains a non-file node"
[ -z "$(find "$LICENSES_APP/Contents/Resources" -mindepth 1 -print -quit)" ] \
    || die "Licenses resources leaked loose into app Contents/Resources"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -module-name FocusLicensesGuest -emit-object \
    -o "$OUT/licenses-main.o" "$W/full/swiftui/FocusLicensesGuestMain.swift"
"${LD[@]}" -dead_strip -ignore_auto_link -exported_symbol __mh_execute_header \
    -rpath @loader_path/../../../package \
    -o "$LICENSES_APP/Contents/MacOS/FocusLicensesGuest" \
    "$OUT/licenses-main.o" "${COMMON_LINK[@]}" \
    -lLicenses -lUIKit -lFoundation -lFoundationEssentials -lSwiftUI \
    -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine
perl "$W/full/swiftui/focus_widget_guest_attest.pl" closure \
    --otool llvm-otool-18 \
    --executable "$LICENSES_APP/Contents/MacOS/FocusLicensesGuest" \
    --package "$PACKAGE" --guest-root "$MRROOT" \
    > "$AUDIT/licenses-runtime-closure.manifest"
(
    cd "$OUT"
    MACHORUN_ROOT="$MRROOT" "$MRROOT/machorun" \
        ./FocusLicensesGuest.app/Contents/MacOS/FocusLicensesGuest \
        "$LICENSES_APP"
) | tee "$OUT/licenses-runtime.log"
grep -Fx 'FOCUS_LICENSES_MACHO_GUEST_OK sources=2 resources=2 bundle=module rows=8 navigation=push' \
    "$OUT/licenses-runtime.log" >/dev/null \
    || die "Licenses runtime marker is missing"

# Prove the portable generated accessor cannot fall back to loose main-bundle,
# current-directory, or build-machine resources. This sibling app keeps the
# same @loader_path reachability to package/ but deliberately has no adjacent
# Focus_Licenses.bundle; exact plist decoys must not rescue it.
MISSING_LICENSES_APP=$OUT/FocusLicensesMissing.app
mkdir -p "$MISSING_LICENSES_APP/Contents/MacOS" \
    "$MISSING_LICENSES_APP/Contents/Resources"
cp "$LICENSES_APP/Contents/MacOS/FocusLicensesGuest" \
    "$MISSING_LICENSES_APP/Contents/MacOS/FocusLicensesGuest"
cp "$FOCUS_SOURCES/Licenses/focus-ios.plist" \
    "$FOCUS_SOURCES/Licenses/license-list.plist" \
    "$MISSING_LICENSES_APP/Contents/Resources/"
cp "$FOCUS_SOURCES/Licenses/focus-ios.plist" \
    "$FOCUS_SOURCES/Licenses/license-list.plist" "$OUT/"
set +e
(
    cd "$OUT"
    MACHORUN_ROOT="$MRROOT" "$MRROOT/machorun" \
        ./FocusLicensesMissing.app/Contents/MacOS/FocusLicensesGuest \
        "$MISSING_LICENSES_APP"
) > "$AUDIT/licenses-missing-bundle.stdout" \
    2> "$AUDIT/licenses-missing-bundle.stderr"
missing_licenses_rc=$?
set -e
[ "$missing_licenses_rc" -eq 133 ] \
    || die "missing Focus_Licenses.bundle control expected SIGTRAP/133, got $missing_licenses_rc"
! grep -Fq 'FOCUS_LICENSES_MACHO_GUEST_OK' \
    "$AUDIT/licenses-missing-bundle.stdout" \
    "$AUDIT/licenses-missing-bundle.stderr" \
    || die "missing Focus_Licenses.bundle control reached success marker"
missing_licenses_fatal_line=$(grep -Fm1 \
    'could not load main-relative Focus_Licenses.bundle:' \
    "$AUDIT/licenses-missing-bundle.stderr") \
    || die "missing Focus_Licenses.bundle control did not fail in accessor"
missing_licenses_fatal_message="could not load${missing_licenses_fatal_line#*could not load}"
missing_licenses_fatal_message=${missing_licenses_fatal_message//"$MISSING_LICENSES_APP"/'<MISSING_APP>'}
expected_missing_licenses_fatal='could not load main-relative Focus_Licenses.bundle: <MISSING_APP>/Focus_Licenses.bundle'
[ "$missing_licenses_fatal_message" = "$expected_missing_licenses_fatal" ] \
    || die "missing-bundle normalized fatal message drifted: $missing_licenses_fatal_message"
[ ! -e "$MISSING_LICENSES_APP/Focus_Licenses.bundle" ] \
    || die "missing-bundle control unexpectedly gained adjacent resources"
require_hash "$MISSING_LICENSES_APP/Contents/Resources/focus-ios.plist" \
    "$EXPECTED_FOCUS_LICENSE" missing-control-app-Focus-license-decoy
require_hash "$MISSING_LICENSES_APP/Contents/Resources/license-list.plist" \
    "$EXPECTED_LIBRARY_LICENSES" missing-control-app-library-license-decoy
require_hash "$OUT/focus-ios.plist" "$EXPECTED_FOCUS_LICENSE" \
    missing-control-cwd-Focus-license-decoy
require_hash "$OUT/license-list.plist" "$EXPECTED_LIBRARY_LICENSES" \
    missing-control-cwd-library-license-decoy
{
    printf 'format\tfocus-licenses-missing-bundle-v1\n'
    printf 'termination\tsignal\tSIGTRAP\tshell-status=133\n'
    printf 'fatal-message\t%s\n' "$missing_licenses_fatal_message"
    printf 'topology\tadjacent-bundle\tabsent\n'
    printf 'topology\tapp-loose-decoys\texact=2\n'
    printf 'topology\tcwd-loose-decoys\texact=2\n'
    printf 'success-marker\tabsent\n'
} > "$AUDIT/licenses-missing-bundle.normalized.tsv"

for dylib in UIKit SnapKit DesignSystem Widget Onboarding Licenses; do
    llvm-otool-18 -hv "$PACKAGE/lib$dylib.dylib" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
        || die "lib$dylib is not an ARM64 Mach-O dylib"
    actual_id=$(llvm-otool-18 -D "$PACKAGE/lib$dylib.dylib" | tail -n 1)
    [ "$actual_id" = "@rpath/lib$dylib.dylib" ] \
        || die "lib$dylib install name changed: $actual_id"
done
for executable in "$PROBE_APP/Contents/MacOS/FocusPackageProbe" \
    "$LICENSES_APP/Contents/MacOS/FocusLicensesGuest"; do
    llvm-otool-18 -hv "$executable" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
        || die "guest is not an ARM64 Mach-O executable: $executable"
done

perl "$W/full/swiftui/focus_widget_guest_attest.pl" closure \
    --otool llvm-otool-18 \
    --executable "$PROBE_APP/Contents/MacOS/FocusPackageProbe" \
    --package "$PACKAGE" --guest-root "$MRROOT" \
    > "$AUDIT/post-package-runtime-closure.manifest"
cmp -s "$AUDIT/package-runtime-closure.manifest" \
    "$AUDIT/post-package-runtime-closure.manifest" \
    || die "package probe recursive runtime closure drifted"
perl "$W/full/swiftui/focus_widget_guest_attest.pl" closure \
    --otool llvm-otool-18 \
    --executable "$LICENSES_APP/Contents/MacOS/FocusLicensesGuest" \
    --package "$PACKAGE" --guest-root "$MRROOT" \
    > "$AUDIT/post-licenses-runtime-closure.manifest"
cmp -s "$AUDIT/licenses-runtime-closure.manifest" \
    "$AUDIT/post-licenses-runtime-closure.manifest" \
    || die "Licenses recursive runtime closure drifted"

check_source_manifest post-SnapKit "$EXPECTED_SNAPKIT_COUNT" \
    "$EXPECTED_SNAPKIT_MANIFEST" "$SNAPKIT_ROOT" "$AUDIT/post-snapkit-sources.tsv" \
    "${SNAPKIT_SRCS[@]}"
require_hash "$SNAPKIT_ROOT/Sources/Debugging.swift" \
    "$EXPECTED_SNAPKIT_DEBUGGING_SHA" post-run-SnapKit-Debugging.swift
{
    printf 'format\tsnapkit-source-exclusions-v1\n'
    printf 'source\tSources/Debugging.swift\t%s\texcluded\t%s\n' \
        "$EXPECTED_SNAPKIT_DEBUGGING_SHA" \
        'requires-NSObject-ObjC-dynamic-description-surface'
} > "$AUDIT/post-snapkit-exclusions.tsv"
cmp -s "$AUDIT/snapkit-exclusions.tsv" "$AUDIT/post-snapkit-exclusions.tsv" \
    || die "SnapKit exclusion ledger changed during execution"
check_source_manifest post-DesignSystem "$EXPECTED_DESIGNSYSTEM_COUNT" \
    "$EXPECTED_DESIGNSYSTEM_MANIFEST" "$FOCUS_REPO" \
    "$AUDIT/post-designsystem-sources.tsv" "${DESIGNSYSTEM_SRCS[@]}"
check_source_manifest post-Widget "$EXPECTED_WIDGET_COUNT" \
    "$EXPECTED_WIDGET_MANIFEST" "$FOCUS_REPO" "$AUDIT/post-widget-sources.tsv" \
    "${WIDGET_SRCS[@]}"
check_source_manifest post-Onboarding "$EXPECTED_ONBOARDING_COUNT" \
    "$EXPECTED_ONBOARDING_MANIFEST" "$FOCUS_REPO" \
    "$AUDIT/post-onboarding-sources.tsv" "${ONBOARDING_SRCS[@]}"
check_source_manifest post-Licenses "$EXPECTED_LICENSES_COUNT" \
    "$EXPECTED_LICENSES_MANIFEST" "$FOCUS_REPO" "$AUDIT/post-licenses-sources.tsv" \
    "${LICENSES_SRCS[@]}"
require_hash "$FOCUS_SOURCES/Licenses/focus-ios.plist" \
    "$EXPECTED_FOCUS_LICENSE" post-run-Focus-license-resource
require_hash "$FOCUS_SOURCES/Licenses/license-list.plist" \
    "$EXPECTED_LIBRARY_LICENSES" post-run-library-licenses-resource
require_hash "$LICENSES_BUNDLE/focus-ios.plist" \
    "$EXPECTED_FOCUS_LICENSE" post-run-staged-Focus-license-resource
require_hash "$LICENSES_BUNDLE/license-list.plist" \
    "$EXPECTED_LIBRARY_LICENSES" post-run-staged-library-licenses-resource
require_hash "$SNAPKIT_BUNDLE/PrivacyInfo.xcprivacy" \
    "$EXPECTED_SNAPKIT_PRIVACY" post-run-staged-SnapKit-privacy-resource
require_hash "$MISSING_LICENSES_APP/Contents/Resources/focus-ios.plist" \
    "$EXPECTED_FOCUS_LICENSE" missing-control-loose-Focus-license-decoy
require_hash "$MISSING_LICENSES_APP/Contents/Resources/license-list.plist" \
    "$EXPECTED_LIBRARY_LICENSES" missing-control-loose-library-license-decoy
[ ! -e "$MISSING_LICENSES_APP/Focus_Licenses.bundle" ] \
    || die "missing-bundle control changed during execution"
require_hash "$PROVIDER/Resources/bundle-provider-marker.txt" \
    "$EXPECTED_PROVIDER_MARKER" post-run-dynamic-Bundle-provider-marker
perl "$ACCESSOR_ATTEST" attest \
    --focus-root "$FOCUS_REPO" --snapkit-root "$SNAPKIT_ROOT" \
    --support-root "$W" --build-script "$W/full/swiftui/build_focus_package_guest.sh" \
    > "$AUDIT/post-resource-accessor-provenance.tsv"
cmp -s "$AUDIT/resource-accessor-provenance.tsv" \
    "$AUDIT/post-resource-accessor-provenance.tsv" \
    || die "resource accessor provenance changed during execution"
cmp -s "$ACCESSOR_ORACLE" "$AUDIT/post-resource-accessor-provenance.tsv" \
    || die "post-run accessor provenance diverged from reviewed oracle"
assert_clean_commit "$FOCUS_ROOT" "$EXPECTED_FOCUS_COMMIT" post-run-Focus
assert_clean_commit "$SNAPKIT_ROOT" "$EXPECTED_SNAPKIT_COMMIT" post-run-SnapKit
assert_vendor_tree "$W" uikit "$UIKIT" "$EXPECTED_UIKIT_TREE" post-run-OpenUIKit
assert_vendor_tree "$W" machorun "$MACHORUN" "$EXPECTED_INREPO_MACHORUN_TREE" post-run-machorun
assert_clean_commit "$SWIFT_FOUNDATION" "$EXPECTED_FOUNDATION_COMMIT" post-run-swift-foundation
assert_clean_commit "$OPENCOMBINE_ROOT/source" "$EXPECTED_OPENCOMBINE_COMMIT" post-run-OpenCombine

{
    printf 'uikit-tree\t%s\n' "$EXPECTED_UIKIT_TREE"
    printf 'uikit-tree-source\tHEAD:uikit\n'
    printf 'machorun-tree\t%s\n' "$EXPECTED_INREPO_MACHORUN_TREE"
    printf 'snapkit-sources\t%s\n' "$(hash_file "$AUDIT/snapkit-sources.tsv")"
    printf 'snapkit-exclusions\t%s\n' "$(hash_file "$AUDIT/snapkit-exclusions.tsv")"
    printf 'designsystem-sources\t%s\n' "$(hash_file "$AUDIT/designsystem-sources.tsv")"
    printf 'widget-sources\t%s\n' "$(hash_file "$AUDIT/widget-sources.tsv")"
    printf 'onboarding-sources\t%s\n' "$(hash_file "$AUDIT/onboarding-sources.tsv")"
    printf 'licenses-sources\t%s\n' "$(hash_file "$AUDIT/licenses-sources.tsv")"
    printf 'package-runtime\t%s\n' "$(hash_file "$OUT/package-runtime.log")"
    printf 'licenses-runtime\t%s\n' "$(hash_file "$OUT/licenses-runtime.log")"
    printf 'package-guest\t%s\n' \
        "$(hash_file "$PROBE_APP/Contents/MacOS/FocusPackageProbe")"
    printf 'licenses-guest\t%s\n' \
        "$(hash_file "$LICENSES_APP/Contents/MacOS/FocusLicensesGuest")"
    printf 'bundle-provider-image\t%s\n' \
        "$(hash_file "$PROVIDER/FocusPackageProbe")"
    printf 'bundle-provider-marker\t%s\n' "$EXPECTED_PROVIDER_MARKER"
    printf 'resource-accessor-provenance\t%s\n' \
        "$(hash_file "$AUDIT/resource-accessor-provenance.tsv")"
    printf 'resource-accessor-oracle\t%s\n' "$(hash_file "$ACCESSOR_ORACLE")"
    printf 'focus-package-manifest\t%s\n' "$EXPECTED_FOCUS_PACKAGE"
    printf 'focus-package-resolved\t%s\n' "$EXPECTED_FOCUS_RESOLVED"
    printf 'snapkit-package-manifest\t%s\n' "$EXPECTED_SNAPKIT_PACKAGE"
    printf 'snapkit-bundle-accessor\t%s\n' \
        "$(hash_file "$W/full/swiftui/FocusSnapKitBundle.generated.swift")"
    printf 'designsystem-bundle-accessor\t%s\n' \
        "$(hash_file "$W/full/swiftui/FocusDesignSystemBundle.generated.swift")"
    printf 'onboarding-bundle-accessor\t%s\n' \
        "$(hash_file "$W/full/swiftui/FocusOnboardingBundle.generated.swift")"
    printf 'widget-bundle-accessor\t%s\n' \
        "$(hash_file "$W/full/swiftui/FocusWidgetBundle.generated.swift")"
    printf 'licenses-bundle-accessor\t%s\n' \
        "$(hash_file "$W/full/swiftui/FocusLicensesBundle.generated.swift")"
    printf 'package-runtime-closure\t%s\n' \
        "$(hash_file "$AUDIT/package-runtime-closure.manifest")"
    printf 'licenses-runtime-closure\t%s\n' \
        "$(hash_file "$AUDIT/licenses-runtime-closure.manifest")"
    printf 'focus-license-resource\t%s\n' "$EXPECTED_FOCUS_LICENSE"
    printf 'library-licenses-resource\t%s\n' "$EXPECTED_LIBRARY_LICENSES"
    printf 'snapkit-privacy-resource\t%s\n' "$EXPECTED_SNAPKIT_PRIVACY"
    printf 'licenses-missing-bundle-normalized\t%s\n' \
        "$(hash_file "$AUDIT/licenses-missing-bundle.normalized.tsv")"
    for dylib in UIKit SnapKit DesignSystem Widget Onboarding Licenses; do
        printf 'lib%s\t%s\n' "$dylib" "$(hash_file "$PACKAGE/lib$dylib.dylib")"
    done
} > "$OUT/artifacts.sha256"

echo '== Focus full package Mach-O guest proof passed'
cat "$OUT/artifacts.sha256"
