#!/usr/bin/env bash
# Build a cold, relocatable ARM64 Mach-O core-framework package for unchanged
# application sources. Run inside the pinned Linux/arm64 production image with
# /w writable only at fresh build/cache/root mounts and all source inputs RO.

set -euo pipefail
export GIT_OPTIONAL_LOCKS=0

W=${W:-/w}
MACHORUN=${MACHORUN:-/machorun}
TARGET=arm64-apple-macos15.0
MIN_OS=15.0
SYS=$W/scratch/sysroot_fe4
FULL=$W/build/full
WORK=$W/build/core-guest-work
MRROOT=$W/scratch/mrroot_full
BUILD_FULL_CACHE=$W/scratch/modcache_full
BUILD_FE_CACHE=$W/scratch/modcache_fe4
SWIFT_FOUNDATION=$W/scratch/swift-foundation
SWIFT_COLLECTIONS=$W/scratch/swift-collections
OPENCOMBINE_ROOT=${OPENCOMBINE_ROOT:-$W/scratch/opencombine-core-durable-20260828-r2}
OPENCOMBINE_SOURCE=$OPENCOMBINE_ROOT/source
OPENCOMBINE_ARTIFACTS=$OPENCOMBINE_ROOT/export/artifacts
OPENCOMBINE_HELPERS=$OPENCOMBINE_SOURCE/Sources/COpenCombineHelpers
MANIFEST_TOOL=$W/full/frameworks/core_package_manifest.py
FOUNDATION_SOURCES_MANIFEST=$W/full/foundation/foundation_guest_sources.txt
INTENTS_SOURCES_MANIFEST=$W/full/intents/intents_guest_sources.txt
INTENTSUI_SOURCES_MANIFEST=$W/full/intentsui/intentsui_guest_sources.txt
WEBKIT_SOURCES_MANIFEST=$W/full/webkit/webkit_guest_sources.txt
WEBKIT_PROVENANCE_TOOL=$W/full/webkit/webkit_provenance.py
WEBKIT_PROVENANCE_POLICY=$W/full/webkit/webkit-provenance.json
FIRST_PARTY_PROVENANCE_TOOL=$W/full/first-party-frameworks/first_party_provenance.py
FIRST_PARTY_PROVENANCE_POLICY=$W/full/first-party-frameworks/first-party-provenance.json
SDK_DANGLING_EXCLUSIONS=$W/full/frameworks/sdk_dangling_symlink_exclusions.tsv
OUTPUT_ROOT=''
EXPECTED_SUPPORT_COMMIT=''
EXPECTED_SUPPORT_TREE=''
UIKIT=''
EXPECTED_UIKIT_COMMIT=''
EXPECTED_UIKIT_TREE=''
DEVELOPER_TOOLS_SUPPORT_MODULE=''
DEVELOPER_TOOLS_SUPPORT_OBJECT=''
PREVIEW_MACRO_PLUGIN=''

FIRST_PARTY_FRAMEWORKS=(
    LocalAuthentication
    SafariServices
    Network
    StoreKit
    AudioToolbox
    CoreHaptics
    PassKit
)
FIRST_PARTY_SOURCE_DIRS=(
    localauthentication
    safariservices
    network
    storekit
    audiotoolbox
    corehaptics
    passkit
)

EXPECTED_SUPPORT_BASE=af37dd231dd5a31866c0c94a04a85679b0821eff
EXPECTED_UIKIT_SWIFT_COUNT=105
EXPECTED_OPENCOREGRAPHICS_SWIFT_COUNT=12
EXPECTED_SWIFTUI_SWIFT_COUNT=7
EXPECTED_CQUARTZ_CPP_COUNT=37
EXPECTED_FOUNDATION_SOURCE_COUNT=18
EXPECTED_INTENTS_SOURCE_COUNT=1
EXPECTED_INTENTSUI_SOURCE_COUNT=1
EXPECTED_WEBKIT_SOURCE_COUNT=5
EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS=19
EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS=2
EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS=0
EXPECTED_FOUNDATION_COMMIT=c6793ef0c19c2cbaeba5a0e52078f129afc7dcfc
EXPECTED_FOUNDATION_TREE=4651798679b98e27383ca3626434fb128f191486
EXPECTED_COLLECTIONS_COMMIT=9bf03ff58ce34478e66aaee630e491823326fd06
EXPECTED_COLLECTIONS_TREE=5e4de96f40ccf147dab967f38cb7988ecd933c27
EXPECTED_OPENCOMBINE_COMMIT=1c6f02c7ed8140c0ba7a783aaddb6e0685a0037b
EXPECTED_OPENCOMBINE_TREE=66a9d91efc910c7577e40b2dec166a2de427594a
EXPECTED_MACHORUN_COMMIT=e6b1745bef09ac8f1e2d6e6c83f7c70d6dbe49a5
EXPECTED_MACHORUN_TREE=1b41ede32d9a3ba2a5ec2d37685dc64b4eee9b43
EXPECTED_PREVIEW_SWIFTSYNTAX_REVISION=4799286537280063c85a32f09884cfbca301b1a1
PREVIEW_EXECUTABLE_EXPORT_SYMBOL='_$s21DeveloperToolsSupport7PreviewV14_openUIKitBodyACypyScMYcc_tcfC'

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
SYSTEM_FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
BOLD_FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
EXPECTED_SYSTEM_FONT=ae7b7855e115a5966d8b1b3f80f254ccc117ec86f9965e202ee2940453837280
EXPECTED_BOLD_FONT=5c1247acef7f2b8522a31742c76d6adcb5569bacc0be7ceaa4dc39dd252ce895

usage() {
    cat <<'EOF'
usage: build_core_guest_package.sh --output-root /w/build/NEW_NAME \
    --expected-support-commit COMMIT --expected-support-tree TREE \
    --uikit-checkout PATH --expected-uikit-commit COMMIT \
    --expected-uikit-tree TREE [options]

Required:
  --output-root PATH
  --expected-support-commit 40_HEX
  --expected-support-tree 40_HEX
  --uikit-checkout PATH
  --expected-uikit-commit 40_HEX
  --expected-uikit-tree 40_HEX

Foundation source contract:
  --foundation-sources-manifest PATH
      Defaults to /w/full/foundation/foundation_guest_sources.txt.

Optional Preview contract (all three or none):
  --developer-tools-support-module PATH
  --developer-tools-support-object PATH
  --preview-macro-plugin PATH

The output must not exist. It must be a direct child of /w/build. The final
package never contains the host macro plugin; it records its hash/ELF/toolchain
identity and publishes an external-plugin load specification instead.
EOF
}

die() {
    echo "core_guest_package: REFUSING -- $*" >&2
    exit 2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --output-root)
            [ "$#" -ge 2 ] || die '--output-root requires a value'
            OUTPUT_ROOT=$2; shift 2 ;;
        --expected-support-commit)
            [ "$#" -ge 2 ] || die '--expected-support-commit requires a value'
            EXPECTED_SUPPORT_COMMIT=$2; shift 2 ;;
        --expected-support-tree)
            [ "$#" -ge 2 ] || die '--expected-support-tree requires a value'
            EXPECTED_SUPPORT_TREE=$2; shift 2 ;;
        --uikit-checkout)
            [ "$#" -ge 2 ] || die '--uikit-checkout requires a value'
            UIKIT=$2; shift 2 ;;
        --expected-uikit-commit)
            [ "$#" -ge 2 ] || die '--expected-uikit-commit requires a value'
            EXPECTED_UIKIT_COMMIT=$2; shift 2 ;;
        --expected-uikit-tree)
            [ "$#" -ge 2 ] || die '--expected-uikit-tree requires a value'
            EXPECTED_UIKIT_TREE=$2; shift 2 ;;
        --foundation-sources-manifest)
            [ "$#" -ge 2 ] || die '--foundation-sources-manifest requires a value'
            FOUNDATION_SOURCES_MANIFEST=$2; shift 2 ;;
        --developer-tools-support-module)
            [ "$#" -ge 2 ] || die '--developer-tools-support-module requires a value'
            DEVELOPER_TOOLS_SUPPORT_MODULE=$2; shift 2 ;;
        --developer-tools-support-object)
            [ "$#" -ge 2 ] || die '--developer-tools-support-object requires a value'
            DEVELOPER_TOOLS_SUPPORT_OBJECT=$2; shift 2 ;;
        --preview-macro-plugin)
            [ "$#" -ge 2 ] || die '--preview-macro-plugin requires a value'
            PREVIEW_MACRO_PLUGIN=$2; shift 2 ;;
        --help|-h)
            usage; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done

[ -n "$OUTPUT_ROOT" ] || die '--output-root is required'
[ -n "$EXPECTED_SUPPORT_COMMIT" ] || die '--expected-support-commit is required'
[ -n "$EXPECTED_SUPPORT_TREE" ] || die '--expected-support-tree is required'
[ -n "$UIKIT" ] || die '--uikit-checkout is required'
[ -n "$EXPECTED_UIKIT_COMMIT" ] || die '--expected-uikit-commit is required'
[ -n "$EXPECTED_UIKIT_TREE" ] || die '--expected-uikit-tree is required'
case "$UIKIT" in /*) ;; *) die '--uikit-checkout must be absolute' ;; esac
for expected_git_id in "$EXPECTED_SUPPORT_COMMIT" "$EXPECTED_SUPPORT_TREE" \
    "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE"; do
    [ "${#expected_git_id}" -eq 40 ] \
        || die 'expected UIKit commit/tree must each be lowercase 40-hex'
    case "$expected_git_id" in
        *[!0-9a-f]*) die 'expected UIKit commit/tree must each be lowercase 40-hex' ;;
    esac
done
case "$OUTPUT_ROOT" in
    /*) ;;
    *) die '--output-root must be absolute' ;;
esac
[ "$(dirname "$OUTPUT_ROOT")" = "$W/build" ] \
    || die '--output-root must be a direct child of /w/build'
case "$OUTPUT_ROOT" in
    *'/../'*|*'/./'*|*'//'*) die '--output-root is not normalized' ;;
esac
[ ! -e "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ] \
    || die "output root already exists: $OUTPUT_ROOT"

preview_count=0
[ -n "$DEVELOPER_TOOLS_SUPPORT_MODULE" ] && preview_count=$((preview_count + 1))
[ -n "$DEVELOPER_TOOLS_SUPPORT_OBJECT" ] && preview_count=$((preview_count + 1))
[ -n "$PREVIEW_MACRO_PLUGIN" ] && preview_count=$((preview_count + 1))
[ "$preview_count" -eq 0 ] || [ "$preview_count" -eq 3 ] \
    || die 'Preview inputs are all-or-none'
PREVIEW_ENABLED=0
[ "$preview_count" -eq 3 ] && PREVIEW_ENABLED=1

for tool in git swiftc clang-18 clang++-18 ld64.lld-18 llvm-otool-18 \
    llvm-nm-18 perl python3 patch sha256sum cmp file readelf find sort; do
    command -v "$tool" >/dev/null || die "required tool is missing: $tool"
done
[ -x "$MANIFEST_TOOL" ] || die "manifest tool is missing or not executable: $MANIFEST_TOOL"
[ -x "$WEBKIT_PROVENANCE_TOOL" ] \
    || die "WebKit provenance tool is missing or not executable: $WEBKIT_PROVENANCE_TOOL"
[ -f "$WEBKIT_PROVENANCE_POLICY" ] && [ ! -L "$WEBKIT_PROVENANCE_POLICY" ] \
    || die "WebKit provenance policy is missing or linked: $WEBKIT_PROVENANCE_POLICY"
[ -x "$FIRST_PARTY_PROVENANCE_TOOL" ] \
    || die "first-party provenance tool is missing or not executable: $FIRST_PARTY_PROVENANCE_TOOL"
[ -f "$FIRST_PARTY_PROVENANCE_POLICY" ] && [ ! -L "$FIRST_PARTY_PROVENANCE_POLICY" ] \
    || die "first-party provenance policy is missing or linked: $FIRST_PARTY_PROVENANCE_POLICY"
[ -x "$MACHORUN/build/machorun" ] || die 'current machorun input is missing'
[ -d "$SYS/usr/include" ] || die "SDK is missing: $SYS"
[ -d "$W/build" ] && [ ! -L "$W/build" ] || die '/w/build must be a real directory'
[ ! -e "$FULL" ] && [ ! -L "$FULL" ] || die "stale build_full output exists: $FULL"
[ ! -e "$WORK" ] && [ ! -L "$WORK" ] || die "stale core work root exists: $WORK"
for fresh in "$MRROOT" "$BUILD_FULL_CACHE" "$BUILD_FE_CACHE"; do
    if [ -e "$fresh" ] || [ -L "$fresh" ]; then
        [ -d "$fresh" ] && [ ! -L "$fresh" ] || die "fresh root is not a real directory: $fresh"
        [ -z "$(find "$fresh" -mindepth 1 -maxdepth 1 -print -quit)" ] \
            || die "fresh root is not empty: $fresh"
    fi
done

mkdir -p "$WORK"
STAGE=$(mktemp -d "$W/build/.core-guest-package.INCOMPLETE.XXXXXX")
SUCCESS=0
quarantine_on_exit() {
    local status=$?
    trap - EXIT
    if [ "$SUCCESS" -ne 1 ]; then
        local partial=''
        if [ -d "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ]; then
            partial=$OUTPUT_ROOT
        elif [ -d "$STAGE" ] && [ ! -L "$STAGE" ]; then
            partial=$STAGE
        fi
        if [ -n "$partial" ]; then
            local invalid=${OUTPUT_ROOT}.INVALID-DO-NOT-USE
            [ ! -e "$invalid" ] || invalid=${invalid}.$(date -u +%Y%m%dT%H%M%SZ)
            mv -- "$partial" "$invalid"
            echo "core_guest_package: quarantined partial package at $invalid" >&2
        fi
        [ ! -d "$MRROOT" ] || touch "$MRROOT/.INVALID-DO-NOT-USE"
        [ ! -d "$BUILD_FULL_CACHE" ] || touch "$BUILD_FULL_CACHE/.INVALID-DO-NOT-USE"
        [ ! -d "$BUILD_FE_CACHE" ] || touch "$BUILD_FE_CACHE/.INVALID-DO-NOT-USE"
    fi
    exit "$status"
}
trap quarantine_on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

hash_file() { sha256sum "$1" | awk '{print $1}'; }

nm_symbol_count() {
    local mode=$1 path=$2 symbol=$3
    llvm-nm-18 "$mode" --extern-only --just-symbol-name "$path" 2>/dev/null \
        | awk -v expected="$symbol" '$0 == expected { count++ } END { print count + 0 }'
}

nm_developer_tools_support_count() {
    local mode=$1 path=$2
    llvm-nm-18 "$mode" --extern-only --just-symbol-name "$path" 2>/dev/null \
        | awk 'index($0, "DeveloperToolsSupport") { count++ } END { print count + 0 }'
}

require_hash() {
    local path=$1 expected=$2 label=$3 actual
    [ -f "$path" ] && [ ! -L "$path" ] || die "missing regular $label: $path"
    actual=$(hash_file "$path")
    [ "$actual" = "$expected" ] || die "$label hash $actual, expected $expected"
}

assert_clean_commit() {
    local repo=$1 expected_commit=$2 expected_tree=$3 label=$4
    local actual_commit actual_tree status
    [ -d "$repo/.git" ] || die "$label is not a Git checkout: $repo"
    actual_commit=$(git -C "$repo" rev-parse --verify HEAD^{commit})
    actual_tree=$(git -C "$repo" rev-parse --verify HEAD^{tree})
    status=$(git -C "$repo" status --porcelain=v1 --untracked-files=all)
    [ "$actual_commit" = "$expected_commit" ] \
        || die "$label commit $actual_commit, expected $expected_commit"
    [ "$actual_tree" = "$expected_tree" ] \
        || die "$label tree $actual_tree, expected $expected_tree"
    [ -z "$status" ] || die "$label checkout is dirty: $status"
}

assert_exact_swift_set() {
    local repo=$1 relative=$2 expected_count=$3 label=$4 prefix=$5
    local tracked=$WORK/$prefix.tracked physical=$WORK/$prefix.physical count
    git -C "$repo" ls-files -z -- "$relative" \
        | while IFS= read -r -d '' path; do
            case "$path" in *.swift) printf '%s\0' "$path" ;; esac
          done | LC_ALL=C sort -z > "$tracked"
    find "$repo/$relative" -type f -name '*.swift' -print0 \
        | while IFS= read -r -d '' path; do
            printf '%s\0' "${path#"$repo"/}"
          done | LC_ALL=C sort -z > "$physical"
    cmp "$tracked" "$physical" || die "$label physical Swift set differs from pinned Git"
    count=$(tr -cd '\0' < "$physical" | wc -c | tr -d '[:space:]')
    [ "$count" = "$expected_count" ] \
        || die "$label Swift count $count, expected $expected_count"
    sha256sum "$physical" | awk -v label="$label" '{print "source-set\t" label "\t" $1 "\tcount='"$count"'"}'
}

SUPPORT_COMMIT=$(git -C "$W" rev-parse --verify HEAD^{commit})
SUPPORT_TREE=$(git -C "$W" rev-parse --verify HEAD^{tree})
[ "$SUPPORT_COMMIT" = "$EXPECTED_SUPPORT_COMMIT" ] \
    || die "support commit $SUPPORT_COMMIT, expected $EXPECTED_SUPPORT_COMMIT"
[ "$SUPPORT_TREE" = "$EXPECTED_SUPPORT_TREE" ] \
    || die "support tree $SUPPORT_TREE, expected $EXPECTED_SUPPORT_TREE"
git -C "$W" merge-base --is-ancestor "$EXPECTED_SUPPORT_BASE" "$SUPPORT_COMMIT" \
    || die "support HEAD does not descend from reviewed base $EXPECTED_SUPPORT_BASE"
[ -z "$(git -C "$W" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'support checkout is dirty'
assert_clean_commit "$UIKIT" "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE" OpenUIKit
assert_clean_commit "$MACHORUN" "$EXPECTED_MACHORUN_COMMIT" "$EXPECTED_MACHORUN_TREE" machorun
assert_clean_commit "$SWIFT_FOUNDATION" "$EXPECTED_FOUNDATION_COMMIT" "$EXPECTED_FOUNDATION_TREE" swift-foundation
assert_clean_commit "$SWIFT_COLLECTIONS" "$EXPECTED_COLLECTIONS_COMMIT" "$EXPECTED_COLLECTIONS_TREE" swift-collections
assert_clean_commit "$OPENCOMBINE_SOURCE" "$EXPECTED_OPENCOMBINE_COMMIT" "$EXPECTED_OPENCOMBINE_TREE" OpenCombine

SOURCE_SET_ATTEST=$WORK/source-sets.pre.tsv
{
    printf 'format\tcore-source-sets-v1\n'
    assert_exact_swift_set "$UIKIT" Sources/OpenUIKit \
        "$EXPECTED_UIKIT_SWIFT_COUNT" OpenUIKit openuikit
    assert_exact_swift_set "$UIKIT" Sources/OpenCoreGraphics \
        "$EXPECTED_OPENCOREGRAPHICS_SWIFT_COUNT" OpenCoreGraphics opencoregraphics
    assert_exact_swift_set "$UIKIT" Sources/SwiftUI \
        "$EXPECTED_SWIFTUI_SWIFT_COUNT" SwiftUI swiftui
} > "$SOURCE_SET_ATTEST"
cquartz_count=$(find "$UIKIT/Sources/CQuartz" -maxdepth 1 -type f -name '*.cpp' \
    | wc -l | tr -d '[:space:]')
[ "$cquartz_count" = "$EXPECTED_CQUARTZ_CPP_COUNT" ] \
    || die "CQuartz C++ count $cquartz_count, expected $EXPECTED_CQUARTZ_CPP_COUNT"

python3 "$MANIFEST_TOOL" foundation-sources \
    --support-root "$W" --manifest "$FOUNDATION_SOURCES_MANIFEST" \
    --output "$WORK/foundation-sources.pre.tsv"
[ "$(grep -c '^source' "$WORK/foundation-sources.pre.tsv")" -eq \
    "$EXPECTED_FOUNDATION_SOURCE_COUNT" ] || die 'Foundation source count drifted'
python3 -B "$WEBKIT_PROVENANCE_TOOL" production \
    --support-root "$W" --policy "$WEBKIT_PROVENANCE_POLICY" \
    --output "$WORK/webkit-sources.pre.tsv"
[ "$(grep -c '^source' "$WORK/webkit-sources.pre.tsv")" -eq \
    "$EXPECTED_WEBKIT_SOURCE_COUNT" ] || die 'WebKit source count drifted'

mapfile -t INTENTS_SOURCES < "$INTENTS_SOURCES_MANIFEST"
mapfile -t INTENTSUI_SOURCES < "$INTENTSUI_SOURCES_MANIFEST"
[ "${#INTENTS_SOURCES[@]}" -eq "$EXPECTED_INTENTS_SOURCE_COUNT" ] \
    || die 'Intents source count drifted'
[ "${#INTENTSUI_SOURCES[@]}" -eq "$EXPECTED_INTENTSUI_SOURCE_COUNT" ] \
    || die 'IntentsUI source count drifted'
[ "${INTENTS_SOURCES[0]}" = full/intents/Intents.swift ] \
    || die 'Intents ordered source manifest drifted'
[ "${INTENTSUI_SOURCES[0]}" = full/intentsui/IntentsUI.swift ] \
    || die 'IntentsUI ordered source manifest drifted'
for relative in "${INTENTS_SOURCES[@]}" "${INTENTSUI_SOURCES[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "framework source is not a regular file: $relative"
    git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
        || die "framework source is not tracked: $relative"
done
{
    printf 'format\tframework-guest-sources-v1\n'
    printf 'manifest\tIntents\t%s\tcount=%s\n' \
        "$(hash_file "$INTENTS_SOURCES_MANIFEST")" "${#INTENTS_SOURCES[@]}"
    for relative in "${INTENTS_SOURCES[@]}"; do
        printf 'source\tIntents\t%s\t%s\n' "$relative" "$(hash_file "$W/$relative")"
    done
    printf 'manifest\tIntentsUI\t%s\tcount=%s\n' \
        "$(hash_file "$INTENTSUI_SOURCES_MANIFEST")" "${#INTENTSUI_SOURCES[@]}"
    for relative in "${INTENTSUI_SOURCES[@]}"; do
        printf 'source\tIntentsUI\t%s\t%s\n' "$relative" "$(hash_file "$W/$relative")"
    done
} > "$WORK/intents-sources.pre.tsv"

python3 -B "$FIRST_PARTY_PROVENANCE_TOOL" production \
    --support-root "$W" --policy "$FIRST_PARTY_PROVENANCE_POLICY" \
    --output "$WORK/first-party-sources.pre.tsv"
[ "$(grep -c '^source' "$WORK/first-party-sources.pre.tsv")" -eq 7 ] \
    || die 'first-party production source count drifted'

python3 "$MANIFEST_TOOL" inventory-tree \
    --root "$UIKIT/Sources/OpenUIKit/Resources" \
    --logical-root resources/OpenUIKit --reject-symlinks \
    --output "$WORK/openuikit-resources.pre.tsv"
python3 "$MANIFEST_TOOL" inventory-tree \
    --root "$SYS" --logical-root sdk \
    --dangling-exclusions "$SDK_DANGLING_EXCLUSIONS" \
    --output "$WORK/sdk.pre.tsv"
python3 "$MANIFEST_TOOL" dangling-symlinks \
    --root "$SYS" --exclusions "$SDK_DANGLING_EXCLUSIONS" \
    --output "$WORK/sdk-dangling.pre.tsv"

require_hash "$OPENCOMBINE_ROOT/export/RESULT.txt" "$EXPECTED_OPENCOMBINE_RESULT" OpenCombine-result
require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" "$EXPECTED_OPENCOMBINE_OBJECT" OpenCombine-object
require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftmodule" "$EXPECTED_OPENCOMBINE_MODULE" OpenCombine-module
require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftdoc" "$EXPECTED_OPENCOMBINE_DOC" OpenCombine-doc
require_hash "$OPENCOMBINE_HELPERS/COpenCombineHelpers.cpp" "$EXPECTED_OPENCOMBINE_HELPER" OpenCombine-helper
require_hash "$OPENCOMBINE_HELPERS/include/COpenCombineHelpers.h" "$EXPECTED_OPENCOMBINE_HEADER" OpenCombine-header
require_hash "$OPENCOMBINE_HELPERS/include/module.modulemap" "$EXPECTED_OPENCOMBINE_MODULEMAP" OpenCombine-modulemap
require_hash "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch" \
    "$EXPECTED_OPENCOMBINE_PATCH" OpenCombine-patch
require_hash "$W/full/oracle-opencombine/Combine.swift" "$EXPECTED_COMBINE_SHIM" Combine-shim
require_hash "$SYSTEM_FONT" "$EXPECTED_SYSTEM_FONT" system-font
require_hash "$BOLD_FONT" "$EXPECTED_BOLD_FONT" bold-font

PREVIEW_MODULE_SHA=''
PREVIEW_OBJECT_SHA=''
PREVIEW_PLUGIN_SHA=''
PREVIEW_TOOLCHAIN=''
PREVIEW_FLAGS=()
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    [ "$(basename "$DEVELOPER_TOOLS_SUPPORT_MODULE")" = DeveloperToolsSupport.swiftmodule ] \
        || die 'DeveloperToolsSupport module basename drifted'
    [ "$(basename "$DEVELOPER_TOOLS_SUPPORT_OBJECT")" = developertoolsupport.o ] \
        || die 'DeveloperToolsSupport object basename drifted'
    [ "$(basename "$PREVIEW_MACRO_PLUGIN")" = OpenUIKitPreviewMacros-tool ] \
        || die 'Preview plugin basename drifted'
    for input in "$DEVELOPER_TOOLS_SUPPORT_MODULE" \
        "$DEVELOPER_TOOLS_SUPPORT_OBJECT" "$PREVIEW_MACRO_PLUGIN"; do
        [ -f "$input" ] && [ ! -L "$input" ] \
            || die "Preview input is not a regular non-symlink file: $input"
    done
    [ -x "$PREVIEW_MACRO_PLUGIN" ] || die 'Preview macro plugin is not executable'
    llvm-otool-18 -hv "$DEVELOPER_TOOLS_SUPPORT_OBJECT" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]OBJECT' \
        || die 'DeveloperToolsSupport object is not an ARM64 Mach-O object'
    preview_export_definition_count=$(nm_symbol_count --defined-only \
        "$DEVELOPER_TOOLS_SUPPORT_OBJECT" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
    [ "$preview_export_definition_count" -eq 1 ] \
        || die "Preview DTS initializer definition count $preview_export_definition_count, expected 1"
    file "$PREVIEW_MACRO_PLUGIN" | grep -Eq 'ELF 64-bit.*(ARM aarch64|aarch64)' \
        || die 'Preview macro plugin is not native ELF64/aarch64'
    readelf -h "$PREVIEW_MACRO_PLUGIN" | grep -Eq 'Machine:[[:space:]]+AArch64' \
        || die 'Preview macro plugin ELF machine is not AArch64'
    PREVIEW_TOOLCHAIN=$(swiftc --version | tr '\n' ' ' | sed 's/[[:space:]]*$//')
    printf '%s\n' "$PREVIEW_TOOLCHAIN" | grep -Fq 'Swift version 6.2.4' \
        || die "Preview consumer toolchain is not Swift 6.2.4: $PREVIEW_TOOLCHAIN"
    PREVIEW_MODULE_SHA=$(hash_file "$DEVELOPER_TOOLS_SUPPORT_MODULE")
    PREVIEW_OBJECT_SHA=$(hash_file "$DEVELOPER_TOOLS_SUPPORT_OBJECT")
    PREVIEW_PLUGIN_SHA=$(hash_file "$PREVIEW_MACRO_PLUGIN")
    PREVIEW_FLAGS=(-load-plugin-executable \
        "$PREVIEW_MACRO_PLUGIN#OpenUIKitPreviewMacros")
fi

echo '== rebuild the proven FoundationEssentials/OpenUIKit substrate from cold roots'
BUILD_FULL_ENV=(W="$W" UIKIT="$UIKIT" MACHORUN="$MACHORUN")
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    BUILD_FULL_ENV+=(
        BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE="$DEVELOPER_TOOLS_SUPPORT_MODULE"
        BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_OBJECT="$DEVELOPER_TOOLS_SUPPORT_OBJECT"
        BUILD_FULL_PREVIEW_MACRO_PLUGIN="$PREVIEW_MACRO_PLUGIN"
    )
fi
env "${BUILD_FULL_ENV[@]}" bash "$W/full/scripts/build_full.sh"
expected_subject=$(bash "$W/full/scripts/uihelpers_subject.sh" "$W" "$UIKIT")
actual_subject=$(tr -d '[:space:]' < "$FULL/uihelpers-subject.sha256")
[ "$actual_subject" = "$expected_subject" ] \
    || die 'build_full subject marker is stale'
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    awk -F '\t' -v name=DeveloperToolsSupport.swiftmodule \
        -v sha="$PREVIEW_MODULE_SHA" \
        '$1 == name && $2 == sha { found = 1 } END { exit !found }' \
        "$FULL/uihelpers-artifacts.sha256" \
        || die 'build_full did not attest the exact DTS module'
    awk -F '\t' -v name=developertoolsupport.o -v sha="$PREVIEW_OBJECT_SHA" \
        '$1 == name && $2 == sha { found = 1 } END { exit !found }' \
        "$FULL/uihelpers-artifacts.sha256" \
        || die 'build_full did not attest the exact DTS object'
    awk -F '\t' -v name=OpenUIKitPreviewMacros-tool -v sha="$PREVIEW_PLUGIN_SHA" \
        '$1 == name && $2 == sha { found = 1 } END { exit !found }' \
        "$FULL/uihelpers-artifacts.sha256" \
        || die 'build_full did not attest the exact Preview plugin'
elif grep -Eq '^(DeveloperToolsSupport\.swiftmodule|developertoolsupport\.o|OpenUIKitPreviewMacros-tool)[[:space:]]' \
    "$FULL/uihelpers-artifacts.sha256"; then
    die 'non-Preview build_full output carries Preview artifact attestations'
fi

mkdir -p "$STAGE/sdk" "$STAGE/modules" "$STAGE/lib" "$STAGE/include" \
    "$STAGE/objects" "$STAGE/resources/OpenUIKit/fonts" \
    "$STAGE/guest-root" "$STAGE/probe" "$STAGE/attestation"
cp -a "$SYS/." "$STAGE/sdk/"
cp "$SDK_DANGLING_EXCLUSIONS" \
    "$STAGE/attestation/sdk-dangling-symlink-exclusions.tsv"
python3 "$MANIFEST_TOOL" dangling-symlinks \
    --root "$STAGE/sdk" \
    --exclusions "$STAGE/attestation/sdk-dangling-symlink-exclusions.tsv" \
    --output "$STAGE/attestation/sdk-dangling-symlinks.tsv" --remove
cmp "$WORK/sdk-dangling.pre.tsv" \
    "$STAGE/attestation/sdk-dangling-symlinks.tsv" \
    || die 'staged SDK dangling-symlink set differs from bracketed input'
cp -a "$MRROOT/." "$STAGE/guest-root/"
cp -a "$UIKIT/Sources/OpenUIKit/Resources/." "$STAGE/resources/OpenUIKit/"
cp "$SYSTEM_FONT" "$STAGE/resources/OpenUIKit/fonts/DejaVuSans.ttf"
cp "$BOLD_FONT" "$STAGE/resources/OpenUIKit/fonts/DejaVuSans-Bold.ttf"

cp -a "$FULL/inc/CPortableIO" "$STAGE/include/"
cp -a "$FULL/inc/CSTBTrueType" "$STAGE/include/"
mkdir -p "$STAGE/include/CHostClock" "$STAGE/include/CQuartz" \
    "$STAGE/include/COpenCombineHelpers" "$STAGE/include/_FoundationCShims"
cp -a "$W/full/hostclock/include/." "$STAGE/include/CHostClock/"
cp -a "$UIKIT/Sources/CQuartz/include/." "$STAGE/include/CQuartz/"
cp -a "$OPENCOMBINE_HELPERS/include/." "$STAGE/include/COpenCombineHelpers/"
cp -a "$SWIFT_FOUNDATION/Sources/_FoundationCShims/include/." \
    "$STAGE/include/_FoundationCShims/"

copy_module_family() {
    local source_dir=$1 name=$2 suffix source
    [ -f "$source_dir/$name.swiftmodule" ] \
        || die "required module is missing: $source_dir/$name.swiftmodule"
    for suffix in swiftmodule swiftdoc swiftsourceinfo abi.json; do
        source=$source_dir/$name.$suffix
        [ ! -e "$source" ] || cp "$source" "$STAGE/modules/"
    done
}
copy_module_family "$FULL/foundation/essentials" FoundationEssentials
copy_module_family "$FULL/foundation/collections" InternalCollectionsUtilities
copy_module_family "$FULL/foundation/collections" OrderedCollections
copy_module_family "$FULL/foundation/collections" _RopeModule
copy_module_family "$FULL/foundation/os" os
copy_module_family "$FULL" OpenCoreGraphics
copy_module_family "$FULL" OpenUIKit
cp "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftmodule" \
    "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftdoc" "$STAGE/modules/"

if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    cp "$DEVELOPER_TOOLS_SUPPORT_MODULE" \
        "$STAGE/modules/DeveloperToolsSupport.swiftmodule"
    cp "$DEVELOPER_TOOLS_SUPPORT_OBJECT" \
        "$STAGE/objects/developertoolsupport.o"
fi

MODULE_CACHE=$WORK/module-cache
mkdir -p "$MODULE_CACHE"
SWIFTC=(swiftc -target "$TARGET" -sdk "$STAGE/sdk"
    -module-cache-path "$MODULE_CACHE" -runtime-compatibility-version none -wmo
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch arm64 -platform_version macos "$MIN_OS" "$MIN_OS"
    -syslibroot "$STAGE/sdk")
C_FLAGS=(-Xcc -I"$STAGE/include/CPortableIO"
    -Xcc -I"$STAGE/include/CSTBTrueType"
    -Xcc -I"$STAGE/include/CHostClock"
    -Xcc -I"$STAGE/include/COpenCombineHelpers"
    -Xcc -I"$STAGE/include/CQuartz")
FE_FLAGS=(-I "$STAGE/modules"
    -Xcc -fmodule-map-file="$STAGE/include/_FoundationCShims/module.modulemap"
    -Xcc -I"$STAGE/include/_FoundationCShims")
RUNTIME=$STAGE/guest-root
COMMON_LINK=(-rpath @loader_path -L"$STAGE/lib"
    -L"$RUNTIME/darwin/usr/lib" -L"$STAGE/sdk/usr/lib/swift"
    -lswiftCore -lswiftObjectiveC "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib"
    -L"$STAGE/sdk/usr/lib" -lSystem -lobjc
    "$RUNTIME/darwin/usr/lib/libquartz.dylib"
    "$RUNTIME/darwin/usr/lib/libSystem.B.dylib")
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
    link_input=$STAGE/sdk/usr/lib/swift/$library.tbd
    runtime_input=$RUNTIME/darwin$install_name
    [ -f "$link_input" ] && [ ! -L "$link_input" ] \
        || die "Foundation runtime link input is missing: $link_input"
    [ -f "$runtime_input" ] && [ ! -L "$runtime_input" ] \
        || die "Foundation staged runtime dylib is missing: $runtime_input"
    actual_id=$(llvm-otool-18 -D "$runtime_input" | tail -n 1)
    [ "$actual_id" = "$install_name" ] \
        || die "Foundation staged runtime ID $actual_id, expected $install_name"
done
SWIFTUI_RUNTIME_BASENAME=libswift_Concurrency
SWIFTUI_RUNTIME_LINK_FLAG=-lswift_Concurrency
SWIFTUI_RUNTIME_INSTALL_NAME=/usr/lib/swift/libswift_Concurrency.dylib
swiftui_runtime_link_input=$STAGE/sdk/usr/lib/swift/$SWIFTUI_RUNTIME_BASENAME.tbd
swiftui_runtime_input=$RUNTIME/darwin$SWIFTUI_RUNTIME_INSTALL_NAME
[ -f "$swiftui_runtime_link_input" ] && [ ! -L "$swiftui_runtime_link_input" ] \
    || die "SwiftUI runtime link input is missing: $swiftui_runtime_link_input"
[ -f "$swiftui_runtime_input" ] && [ ! -L "$swiftui_runtime_input" ] \
    || die "SwiftUI staged runtime dylib is missing: $swiftui_runtime_input"
swiftui_runtime_actual_id=$(llvm-otool-18 -D "$swiftui_runtime_input" | tail -n 1)
[ "$swiftui_runtime_actual_id" = "$SWIFTUI_RUNTIME_INSTALL_NAME" ] \
    || die "SwiftUI staged runtime ID $swiftui_runtime_actual_id, expected $SWIFTUI_RUNTIME_INSTALL_NAME"

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
    "$FULL/foundation/essentials/uuid_compat.o"
)

echo '== prewarm a new core-package Darwin module cache'
swiftc -target "$TARGET" -sdk "$STAGE/sdk" \
    -module-cache-path "$MODULE_CACHE" -parse-stdlib -typecheck -e 'import Swift'

echo '== build pinned OpenCombine and literal Combine'
cp "$OPENCOMBINE_HELPERS/COpenCombineHelpers.cpp" "$WORK/COpenCombineHelpers.cpp"
patch --batch --forward --fuzz=0 "$WORK/COpenCombineHelpers.cpp" \
    "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch"
require_hash "$WORK/COpenCombineHelpers.cpp" "$EXPECTED_OPENCOMBINE_PATCHED_HELPER" patched-OpenCombine-helper
clang++-18 -target "$TARGET" -isysroot "$STAGE/sdk" -stdlib=libc++ \
    -std=c++17 -O2 -I "$STAGE/include/COpenCombineHelpers" \
    -c "$WORK/COpenCombineHelpers.cpp" -o "$WORK/copencombinehelpers.o"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libOpenCombine.dylib -rpath @loader_path \
    -o "$STAGE/lib/libOpenCombine.dylib" \
    "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" "$WORK/copencombinehelpers.o" \
    "$STAGE/sdk/usr/lib/swift/libswift_Concurrency.tbd" \
    "$STAGE/sdk/usr/lib/swift/libswiftCore.tbd" \
    "$RUNTIME/darwin/usr/lib/libc++abi.dylib" \
    "$STAGE/sdk/usr/lib/libSystem.tbd" \
    "$RUNTIME/darwin/usr/lib/libSystem.real.dylib" \
    "$STAGE/sdk/usr/lib/libobjc.tbd"
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" -I "$STAGE/modules" \
    -module-name Combine -emit-module \
    -emit-module-path "$STAGE/modules/Combine.swiftmodule" \
    -emit-object -o "$WORK/combine.o" "$W/full/oracle-opencombine/Combine.swift"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libCombine.dylib -rpath @loader_path \
    -reexport_library "$STAGE/lib/libOpenCombine.dylib" \
    -o "$STAGE/lib/libCombine.dylib" "$WORK/combine.o" \
    "$STAGE/sdk/usr/lib/swift/libswiftCore.tbd" "$STAGE/sdk/usr/lib/libSystem.tbd"

echo '== compile SwiftUI while Foundation is hidden'
mapfile -d '' -t SWIFTUI_SOURCES < <(
    find "$UIKIT/Sources/SwiftUI" -maxdepth 1 -type f -name '*.swift' \
        -print0 | LC_ALL=C sort -z
)
[ "${#SWIFTUI_SOURCES[@]}" -eq "$EXPECTED_SWIFTUI_SWIFT_COUNT" ] \
    || die 'SwiftUI source count changed before compile'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name SwiftUI -emit-module \
    -emit-module-path "$STAGE/modules/SwiftUI.swiftmodule" \
    -emit-object -o "$WORK/swiftui.o" "${SWIFTUI_SOURCES[@]}"

echo '== compile the ordered app-facing Foundation facade manifest'
mapfile -t FOUNDATION_SOURCES < "$FOUNDATION_SOURCES_MANIFEST"
[ "${#FOUNDATION_SOURCES[@]}" -eq "$EXPECTED_FOUNDATION_SOURCE_COUNT" ] \
    || die 'Foundation source array count changed'
FOUNDATION_SOURCE_PATHS=()
for relative in "${FOUNDATION_SOURCES[@]}"; do
    FOUNDATION_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name Foundation -emit-module \
    -emit-module-path "$STAGE/modules/Foundation.swiftmodule" \
    -emit-object -o "$WORK/foundation.o" "${FOUNDATION_SOURCE_PATHS[@]}"
llvm-nm-18 -u -j "$WORK/foundation.o" | LC_ALL=C sort -u \
    > "$WORK/foundation-undefined-symbols.txt"
foundation_string_processing_undefineds=$(awk \
    'index($0, "17_StringProcessing") { count++ } END { print count + 0 }' \
    "$WORK/foundation-undefined-symbols.txt")
foundation_synchronization_undefineds=$(awk \
    'index($0, "15Synchronization") { count++ } END { print count + 0 }' \
    "$WORK/foundation-undefined-symbols.txt")
foundation_regex_parser_undefineds=$(awk \
    'index($0, "12_RegexParser") { count++ } END { print count + 0 }' \
    "$WORK/foundation-undefined-symbols.txt")
[ "$foundation_string_processing_undefineds" -eq \
    "$EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS" ] \
    || die "Foundation StringProcessing undefined count $foundation_string_processing_undefineds, expected $EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS"
[ "$foundation_synchronization_undefineds" -eq \
    "$EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS" ] \
    || die "Foundation Synchronization undefined count $foundation_synchronization_undefineds, expected $EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS"
[ "$foundation_regex_parser_undefineds" -eq \
    "$EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS" ] \
    || die "Foundation RegexParser undefined count $foundation_regex_parser_undefineds, expected $EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS"
printf 'Foundation facade direct undefineds: StringProcessing=%s Synchronization=%s RegexParser=%s\n' \
    "$foundation_string_processing_undefineds" \
    "$foundation_synchronization_undefineds" \
    "$foundation_regex_parser_undefineds"

echo '== compile final Foundation-visible UIKit (optional Preview plugin explicit)'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${PREVIEW_FLAGS[@]}" -module-name UIKit -emit-module \
    -emit-module-path "$STAGE/modules/UIKit.swiftmodule" \
    -emit-object -o "$WORK/uikit.o" "$UIKIT/Sources/UIKitShim/UIKit.swift"

echo '== compile production Intents and IntentsUI modules'
INTENTS_SOURCE_PATHS=()
for relative in "${INTENTS_SOURCES[@]}"; do
    INTENTS_SOURCE_PATHS+=("$W/$relative")
done
INTENTSUI_SOURCE_PATHS=()
for relative in "${INTENTSUI_SOURCES[@]}"; do
    INTENTSUI_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name Intents -emit-module \
    -emit-module-path "$STAGE/modules/Intents.swiftmodule" \
    -emit-object -o "$WORK/intents.o" "${INTENTS_SOURCE_PATHS[@]}"
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name IntentsUI -emit-module \
    -emit-module-path "$STAGE/modules/IntentsUI.swiftmodule" \
    -emit-object -o "$WORK/intentsui.o" "${INTENTSUI_SOURCE_PATHS[@]}"

echo '== compile the production first-party WebKit module'
mapfile -t WEBKIT_SOURCES < "$WEBKIT_SOURCES_MANIFEST"
[ "${#WEBKIT_SOURCES[@]}" -eq "$EXPECTED_WEBKIT_SOURCE_COUNT" ] \
    || die 'WebKit source array count changed'
WEBKIT_SOURCE_PATHS=()
for relative in "${WEBKIT_SOURCES[@]}"; do
    WEBKIT_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name WebKit -emit-module \
    -emit-module-path "$STAGE/modules/WebKit.swiftmodule" \
    -emit-object -o "$WORK/webkit.o" "${WEBKIT_SOURCE_PATHS[@]}"

echo '== compile seven independent first-party framework modules'
for index in "${!FIRST_PARTY_FRAMEWORKS[@]}"; do
    framework=${FIRST_PARTY_FRAMEWORKS[$index]}
    source_dir=${FIRST_PARTY_SOURCE_DIRS[$index]}
    source_manifest=$W/full/$source_dir/${source_dir}_guest_sources.txt
    mapfile -t framework_sources < "$source_manifest"
    [ "${#framework_sources[@]}" -eq 1 ] \
        || die "$framework source manifest cardinality drifted"
    framework_source_paths=()
    for relative in "${framework_sources[@]}"; do
        framework_source_paths+=("$W/$relative")
    done
    "${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
        -module-name "$framework" -emit-module \
        -emit-module-path "$STAGE/modules/$framework.swiftmodule" \
        -emit-object -o "$WORK/$source_dir.o" \
        "${framework_source_paths[@]}"
done
network_string_processing_undefineds=$(llvm-nm-18 -u -j "$WORK/network.o" \
    | awk 'index($0, "_StringProcessing") { count++ } END { print count + 0 }')
[ "$network_string_processing_undefineds" -eq 0 ] \
    || die "Network has $network_string_processing_undefineds direct StringProcessing undefineds, expected 0"

echo '== final Foundation/UIKit notification identity proof'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${PREVIEW_FLAGS[@]}" -module-name CorePackageNotificationIdentityProbe \
    -typecheck \
    "$W/full/foundation/notification_foundation_extension_probe.swift" \
    "$W/full/foundation/notification_uikit_consumer_probe.swift" \
    "$W/full/foundation/notification_direct_import_probe.swift"

echo '== link eighteen reusable core framework dylibs'
"${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libFoundationEssentials.dylib -rpath @loader_path \
    -L"$RUNTIME/darwin/usr/lib" -L"$STAGE/sdk/usr/lib/swift" \
    -lswiftCore "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$STAGE/sdk/usr/lib" -lSystem "$RUNTIME/darwin/usr/lib/libSystem.B.dylib" \
    -o "$STAGE/lib/libFoundationEssentials.dylib" \
    "${FE_OBJECTS[@]}" "$FULL/swiftcorepatch.o"
"${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libOpenCoreGraphics.dylib -rpath @loader_path \
    -L"$RUNTIME/darwin/usr/lib" -L"$STAGE/sdk/usr/lib/swift" \
    -lswiftCore "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$STAGE/sdk/usr/lib" -lSystem "$RUNTIME/darwin/usr/lib/libquartz.dylib" \
    "$RUNTIME/darwin/usr/lib/libSystem.B.dylib" \
    -o "$STAGE/lib/libOpenCoreGraphics.dylib" "$FULL/opencoregraphics.o"
"${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libOpenUIKit.dylib -rpath @loader_path \
    -L"$STAGE/lib" -lFoundationEssentials -lOpenCoreGraphics \
    -L"$RUNTIME/darwin/usr/lib" -L"$STAGE/sdk/usr/lib/swift" \
    -lswiftCore -lswiftObjectiveC "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$STAGE/sdk/usr/lib" -lSystem -lobjc \
    "$RUNTIME/darwin/usr/lib/libquartz.dylib" \
    "$RUNTIME/darwin/usr/lib/libSystem.B.dylib" \
    -o "$STAGE/lib/libOpenUIKit.dylib" "$FULL/openuikit.o" \
    "$FULL/cportableio.o" "$FULL/cstbtruetype.o" "$FULL/hostclock.o" \
    "$FULL/swiftcorepatch.o"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libFoundation.dylib -rpath @loader_path \
    -o "$STAGE/lib/libFoundation.dylib" "$WORK/foundation.o" \
    "${COMMON_LINK[@]}" -lFoundationEssentials -lOpenUIKit -lCombine -lOpenCombine \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
for install_name in "${FOUNDATION_RUNTIME_INSTALL_NAMES[@]}"; do
    load_count=$(llvm-otool-18 -L "$STAGE/lib/libFoundation.dylib" \
        | awk -v expected="$install_name" '$1 == expected { count++ } END { print count + 0 }')
    [ "$load_count" -eq 1 ] \
        || die "libFoundation runtime load count $load_count for $install_name, expected 1"
done
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libSwiftUI.dylib -rpath @loader_path \
    -o "$STAGE/lib/libSwiftUI.dylib" "$WORK/swiftui.o" \
    "${COMMON_LINK[@]}" -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine \
    "$SWIFTUI_RUNTIME_LINK_FLAG"
swiftui_runtime_load_count=$(llvm-otool-18 -L "$STAGE/lib/libSwiftUI.dylib" \
    | awk -v expected="$SWIFTUI_RUNTIME_INSTALL_NAME" \
        '$1 == expected { count++ } END { print count + 0 }')
[ "$swiftui_runtime_load_count" -eq 1 ] \
    || die "libSwiftUI runtime load count $swiftui_runtime_load_count for $SWIFTUI_RUNTIME_INSTALL_NAME, expected 1"
UIKIT_UNDEFINED_FLAGS=()
[ "$PREVIEW_ENABLED" -eq 0 ] || UIKIT_UNDEFINED_FLAGS=(-undefined dynamic_lookup)
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libUIKit.dylib -rpath @loader_path \
    "${UIKIT_UNDEFINED_FLAGS[@]}" \
    -o "$STAGE/lib/libUIKit.dylib" "$WORK/uikit.o" \
    "${COMMON_LINK[@]}" -lFoundation -lFoundationEssentials \
    -lOpenUIKit -lOpenCoreGraphics

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libIntents.dylib -rpath @loader_path \
    -o "$STAGE/lib/libIntents.dylib" "$WORK/intents.o" \
    "${COMMON_LINK[@]}" -lFoundation -lFoundationEssentials \
    -lOpenUIKit -lCombine -lOpenCombine -lswiftSynchronization
intents_runtime_load_count=$(llvm-otool-18 -L "$STAGE/lib/libIntents.dylib" \
    | awk '$1 == "/usr/lib/swift/libswiftSynchronization.dylib" { count++ } END { print count + 0 }')
[ "$intents_runtime_load_count" -eq 1 ] \
    || die "libIntents Synchronization runtime load count $intents_runtime_load_count, expected 1"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libIntentsUI.dylib -rpath @loader_path \
    -o "$STAGE/lib/libIntentsUI.dylib" "$WORK/intentsui.o" \
    "${COMMON_LINK[@]}" -lIntents -lUIKit -lFoundation \
    -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libWebKit.dylib -rpath @loader_path \
    -needed_library "$STAGE/lib/libUIKit.dylib" \
    -needed_library "$STAGE/lib/libFoundation.dylib" \
    -o "$STAGE/lib/libWebKit.dylib" "$WORK/webkit.o" \
    "${COMMON_LINK[@]}" -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics

WEBKIT_REQUIRED_LOADS=(
    @rpath/libUIKit.dylib
    @rpath/libFoundation.dylib
)
for install_name in "${WEBKIT_REQUIRED_LOADS[@]}"; do
    load_count=$(llvm-otool-18 -L "$STAGE/lib/libWebKit.dylib" \
        | awk -v expected="$install_name" '$1 == expected { count++ } END { print count + 0 }')
    [ "$load_count" -eq 1 ] \
        || die "libWebKit load count $load_count for $install_name, expected 1"
done
if llvm-otool-18 -L "$STAGE/lib/libWebKit.dylib" \
    | grep -Fq '/System/Library/Frameworks/WebKit.framework/'; then
    die 'portable libWebKit must not load Apple WebKit.framework'
fi
{
    printf 'format\twebkit-dylib-loads-v1\n'
    printf 'install-id\t@rpath/libWebKit.dylib\n'
    printf 'required-load\t@rpath/libUIKit.dylib\tcount=1\n'
    printf 'required-load\t@rpath/libFoundation.dylib\tcount=1\n'
    printf 'apple-webkit-framework-load-count\t0\n'
    printf 'rendering-engine\tabsent\n'
} > "$STAGE/attestation/webkit-dylib-loads.tsv"

uikit_preview_import_count=$(nm_symbol_count --undefined-only \
    "$STAGE/lib/libUIKit.dylib" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
uikit_dts_import_count=$(nm_developer_tools_support_count --undefined-only \
    "$STAGE/lib/libUIKit.dylib")
[ "$uikit_preview_import_count" -eq "$PREVIEW_ENABLED" ] \
    || die "Preview libUIKit initializer import count $uikit_preview_import_count, expected $PREVIEW_ENABLED"
[ "$uikit_dts_import_count" -eq "$PREVIEW_ENABLED" ] \
    || die "Preview libUIKit DeveloperToolsSupport import count $uikit_dts_import_count, expected $PREVIEW_ENABLED"

FIRST_PARTY_LOAD_AUDIT=$STAGE/attestation/first-party-dylib-loads.tsv
printf 'format\tfirst-party-dylib-loads-v1\n' > "$FIRST_PARTY_LOAD_AUDIT"
for index in "${!FIRST_PARTY_FRAMEWORKS[@]}"; do
    framework=${FIRST_PARTY_FRAMEWORKS[$index]}
    source_dir=${FIRST_PARTY_SOURCE_DIRS[$index]}
    framework_link_dependencies=(
        -lFoundation
        -lFoundationEssentials
        "$SWIFTUI_RUNTIME_LINK_FLAG"
    )
    expected_uikit_load=0
    case "$framework" in
        SafariServices|StoreKit|PassKit)
            expected_uikit_load=1
            framework_link_dependencies+=(
                -lUIKit
                -lOpenUIKit
                -lOpenCoreGraphics
            )
            ;;
    esac
    "${LD[@]}" -dylib -dead_strip -ignore_auto_link \
        -install_name "@rpath/lib$framework.dylib" -rpath @loader_path \
        -o "$STAGE/lib/lib$framework.dylib" "$WORK/$source_dir.o" \
        "${COMMON_LINK[@]}" "${framework_link_dependencies[@]}"
    foundation_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libFoundation.dylib" { count++ } END { print count + 0 }')
    uikit_load_count=$(llvm-otool-18 -L "$STAGE/lib/lib$framework.dylib" \
        | awk '$1 == "@rpath/libUIKit.dylib" { count++ } END { print count + 0 }')
    concurrency_load_count=$(llvm-otool-18 -L \
        "$STAGE/lib/lib$framework.dylib" \
        | awk -v expected="$SWIFTUI_RUNTIME_INSTALL_NAME" \
            '$1 == expected { count++ } END { print count + 0 }')
    [ "$foundation_load_count" -eq 1 ] \
        || die "lib$framework Foundation load count $foundation_load_count, expected 1"
    [ "$uikit_load_count" -eq "$expected_uikit_load" ] \
        || die "lib$framework UIKit load count $uikit_load_count, expected $expected_uikit_load"
    [ "$concurrency_load_count" -eq 1 ] \
        || die "lib$framework Concurrency load count $concurrency_load_count, expected 1"
    if llvm-otool-18 -L "$STAGE/lib/lib$framework.dylib" \
        | grep -Fq "/System/Library/Frameworks/$framework.framework/"; then
        die "lib$framework loads the Apple $framework framework"
    fi
    printf '%s\tfoundation=%s\tuikit=%s\tconcurrency=%s\tapple-self-load=0\n' \
        "$framework" "$foundation_load_count" "$uikit_load_count" \
        "$concurrency_load_count" >> "$FIRST_PARTY_LOAD_AUDIT"
done

echo '== compile/link/run the core package probe'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${PREVIEW_FLAGS[@]}" -module-name CoreGuestPackageProbe \
    -emit-object -o "$WORK/core-probe.o" \
    "$W/full/frameworks/CoreGuestPackageProbe.swift"
PROBE_LINK_EXTRA=()
[ "$PREVIEW_ENABLED" -eq 0 ] \
    || PROBE_LINK_EXTRA+=("$STAGE/objects/developertoolsupport.o")
probe_dts_count=0
for input in "${PROBE_LINK_EXTRA[@]}"; do
    [ "$input" != "$STAGE/objects/developertoolsupport.o" ] \
        || probe_dts_count=$((probe_dts_count + 1))
done
[ "$probe_dts_count" -eq "$PREVIEW_ENABLED" ] \
    || die "core probe DTS link count $probe_dts_count, expected $PREVIEW_ENABLED"
PROBE_EXPORT_FLAGS=(-exported_symbol __mh_execute_header)
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    staged_preview_definition_count=$(nm_symbol_count --defined-only \
        "$STAGE/objects/developertoolsupport.o" \
        "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
    [ "$staged_preview_definition_count" -eq 1 ] \
        || die "staged Preview DTS initializer definition count $staged_preview_definition_count, expected 1"
    PROBE_EXPORT_FLAGS+=(-exported_symbol "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
fi
"${LD[@]}" -dead_strip -ignore_auto_link \
    "${PROBE_EXPORT_FLAGS[@]}" -rpath @loader_path/../lib \
    -o "$STAGE/probe/CoreGuestPackageProbe" "$WORK/core-probe.o" \
    "${PROBE_LINK_EXTRA[@]}" "${COMMON_LINK[@]}" \
    -lWebKit -lIntentsUI -lIntents -lUIKit -lFoundation -lFoundationEssentials -lSwiftUI \
    -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine \
    -lLocalAuthentication -lSafariServices -lNetwork -lStoreKit \
    -lAudioToolbox -lCoreHaptics -lPassKit "$SWIFTUI_RUNTIME_LINK_FLAG"

for dylib in FoundationEssentials OpenCoreGraphics OpenUIKit OpenCombine \
    Combine SwiftUI Foundation UIKit Intents IntentsUI WebKit \
    "${FIRST_PARTY_FRAMEWORKS[@]}"; do
    llvm-otool-18 -hv "$STAGE/lib/lib$dylib.dylib" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
        || die "lib$dylib is not an ARM64 Mach-O dylib"
    actual_id=$(llvm-otool-18 -D "$STAGE/lib/lib$dylib.dylib" | tail -n 1)
    [ "$actual_id" = "@rpath/lib$dylib.dylib" ] \
        || die "lib$dylib install name changed: $actual_id"
done
if llvm-otool-18 -L "$STAGE/lib/libUIKit.dylib" \
    | grep -Fq DeveloperToolsSupport; then
    die 'libUIKit must not load a DeveloperToolsSupport dylib'
fi
probe_preview_export_count=$(nm_symbol_count --defined-only \
    "$STAGE/probe/CoreGuestPackageProbe" "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")
probe_dts_export_count=$(nm_developer_tools_support_count --defined-only \
    "$STAGE/probe/CoreGuestPackageProbe")
[ "$probe_preview_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "core probe Preview initializer export count $probe_preview_export_count, expected $PREVIEW_ENABLED"
[ "$probe_dts_export_count" -eq "$PREVIEW_ENABLED" ] \
    || die "core probe DeveloperToolsSupport export count $probe_dts_export_count, expected $PREVIEW_ENABLED"
{
    printf 'format\tcore-probe-link-audit-v1\n'
    printf 'developer-tools-support-object-count\t%s\n' "$probe_dts_count"
    printf 'libUIKit-developer-tools-support-load-count\t0\n'
    printf 'libUIKit-preview-initializer-import-count\t%s\n' \
        "$uikit_preview_import_count"
    printf 'executable-preview-initializer-export-count\t%s\n' \
        "$probe_preview_export_count"
    printf 'runtime-preview-body-evaluation\t%s\n' \
        "$([ "$PREVIEW_ENABLED" -eq 1 ] && printf enabled || printf disabled)"
} > "$STAGE/attestation/probe-link-audit.tsv"
llvm-otool-18 -hv "$STAGE/probe/CoreGuestPackageProbe" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'core package probe is not an ARM64 Mach-O executable'

perl "$W/full/swiftui/focus_widget_guest_attest.pl" closure \
    --otool llvm-otool-18 --executable "$STAGE/probe/CoreGuestPackageProbe" \
    --package "$STAGE" --guest-root "$STAGE/guest-root" \
    > "$STAGE/attestation/runtime-closure.tsv"
(
    cd "$STAGE"
    MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/CoreGuestPackageProbe \
        "$STAGE/resources/OpenUIKit" \
        "$STAGE/resources/OpenUIKit/fonts/DejaVuSans.ttf" \
        "$STAGE/resources/OpenUIKit/fonts/DejaVuSans-Bold.ttf"
) | tee "$STAGE/attestation/runtime.log"
grep -Fq 'CORE_GUEST_PACKAGE_MACHO_OK notification=shared combine=delivered resources=loaded fonts=system,bold intents=donated shortcuts=stored intentsui=host-driven first-party=fail-closed-7 webkit=engine-unavailable preview=' \
    "$STAGE/attestation/runtime.log" || die 'core package runtime marker is missing'

echo '== write relocatable compile/link contracts'
COMPILE_ARGUMENTS=(
    -target "$TARGET" -sdk sdk -runtime-compatibility-version none
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xfrontend -disable-objc-attr-requires-foundation-module
    -I modules
    -Xcc -Iinclude/CPortableIO
    -Xcc -Iinclude/CSTBTrueType
    -Xcc -Iinclude/CHostClock
    -Xcc -Iinclude/COpenCombineHelpers
    -Xcc -Iinclude/CQuartz
    -Xcc -fmodule-map-file=include/_FoundationCShims/module.modulemap
    -Xcc -Iinclude/_FoundationCShims
)
LINK_ARGUMENTS=(
    -arch arm64 -platform_version macos "$MIN_OS" "$MIN_OS" -syslibroot sdk
    -Llib -Lguest-root/darwin/usr/lib -Lsdk/usr/lib/swift
    -lswiftCore -lswiftObjectiveC
    guest-root/darwin/usr/lib/libswiftcompat.dylib
    -Lsdk/usr/lib -lSystem -lobjc
    guest-root/darwin/usr/lib/libquartz.dylib
    guest-root/darwin/usr/lib/libSystem.B.dylib
    -lWebKit -lUIKit -lFoundation -lFoundationEssentials -lSwiftUI
    -lIntentsUI -lIntents -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine
    -lLocalAuthentication -lSafariServices -lNetwork -lStoreKit
    -lAudioToolbox -lCoreHaptics -lPassKit
)
printf '%s\0' "${COMPILE_ARGUMENTS[@]}" > "$STAGE/compile-flags.rsp"
printf '%s\0' "${LINK_ARGUMENTS[@]}" > "$STAGE/link-inputs.rsp"

if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    printf '%s\0' -load-plugin-executable \
        '${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros' \
        > "$STAGE/preview-plugin-load-flag.rsp"
    {
        printf 'format\tcore-preview-input-v1\n'
        printf 'module-name\tDeveloperToolsSupport\n'
        printf 'module-path\tmodules/DeveloperToolsSupport.swiftmodule\n'
        printf 'module-sha256\t%s\n' "$PREVIEW_MODULE_SHA"
        printf 'object-path\tobjects/developertoolsupport.o\n'
        printf 'object-sha256\t%s\n' "$PREVIEW_OBJECT_SHA"
        printf 'plugin-basename\tOpenUIKitPreviewMacros-tool\n'
        printf 'plugin-sha256\t%s\n' "$PREVIEW_PLUGIN_SHA"
        printf 'plugin-elf-class\tELF64\n'
        printf 'plugin-elf-machine\tAArch64\n'
        printf 'plugin-toolchain\t%s\n' "$PREVIEW_TOOLCHAIN"
        printf 'plugin-swiftsyntax-revision\t%s\n' \
            "$EXPECTED_PREVIEW_SWIFTSYNTAX_REVISION"
        printf 'plugin-registration\tOpenUIKitPreviewMacros\n'
        printf 'plugin-load-flags\tpreview-plugin-load-flag.rsp\n'
    } > "$STAGE/attestation/preview-input.tsv"
fi

echo '== exhaustive tree attestations'
python3 "$MANIFEST_TOOL" inventory-tree --root "$STAGE/sdk" \
    --logical-root sdk --output "$STAGE/attestation/sdk-tree.tsv"
cmp "$WORK/sdk.pre.tsv" "$STAGE/attestation/sdk-tree.tsv" \
    || die 'packaged SDK tree differs from the bracketed input SDK'
python3 "$MANIFEST_TOOL" inventory-tree --root "$STAGE/include" \
    --logical-root include --reject-symlinks \
    --output "$STAGE/attestation/include-tree.tsv"
python3 "$MANIFEST_TOOL" inventory-tree --root "$STAGE/guest-root" \
    --logical-root guest-root --output "$STAGE/attestation/guest-root-tree.tsv"
python3 "$MANIFEST_TOOL" inventory-tree \
    --root "$STAGE/resources/OpenUIKit" --logical-root resources/OpenUIKit \
    --reject-symlinks --output "$STAGE/attestation/openuikit-resources-tree.tsv"
cmp "$WORK/openuikit-resources.pre.tsv" \
    <(awk -F '\t' '$2 !~ /^resources\/OpenUIKit\/fonts(\/|$)/' \
        "$STAGE/attestation/openuikit-resources-tree.tsv") \
    || die 'staged OpenUIKit resource tree differs from source before fonts'

cp "$WORK/foundation-sources.pre.tsv" "$STAGE/attestation/foundation-sources.tsv"
cp "$WORK/intents-sources.pre.tsv" "$STAGE/attestation/intents-sources.tsv"
cp "$WORK/webkit-sources.pre.tsv" "$STAGE/attestation/webkit-sources.tsv"
cp "$WORK/foundation-undefined-symbols.txt" \
    "$STAGE/attestation/foundation-undefined-symbols.txt"
cp "$WORK/first-party-sources.pre.tsv" \
    "$STAGE/attestation/first-party-sources.tsv"
cp "$SOURCE_SET_ATTEST" "$STAGE/attestation/source-sets.tsv"
{
    printf 'format\tcore-input-provenance-v1\n'
    printf 'support\tcommit=%s\ttree=%s\tbase=%s\n' \
        "$SUPPORT_COMMIT" "$SUPPORT_TREE" "$EXPECTED_SUPPORT_BASE"
    printf 'OpenUIKit\tcommit=%s\ttree=%s\tSwift=%s\tOpenCoreGraphics=%s\tSwiftUI=%s\tCQuartzCPP=%s\n' \
        "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE" \
        "$EXPECTED_UIKIT_SWIFT_COUNT" "$EXPECTED_OPENCOREGRAPHICS_SWIFT_COUNT" \
        "$EXPECTED_SWIFTUI_SWIFT_COUNT" "$EXPECTED_CQUARTZ_CPP_COUNT"
    printf 'swift-foundation\tcommit=%s\ttree=%s\n' \
        "$EXPECTED_FOUNDATION_COMMIT" "$EXPECTED_FOUNDATION_TREE"
    printf 'swift-collections\tcommit=%s\ttree=%s\n' \
        "$EXPECTED_COLLECTIONS_COMMIT" "$EXPECTED_COLLECTIONS_TREE"
    printf 'OpenCombine\tcommit=%s\ttree=%s\n' \
        "$EXPECTED_OPENCOMBINE_COMMIT" "$EXPECTED_OPENCOMBINE_TREE"
    printf 'machorun\tcommit=%s\ttree=%s\tloader-sha256=%s\n' \
        "$EXPECTED_MACHORUN_COMMIT" "$EXPECTED_MACHORUN_TREE" \
        "$(hash_file "$MACHORUN/build/machorun")"
    printf 'font\tsystem\tcontainer:/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf\t%s\n' \
        "$EXPECTED_SYSTEM_FONT"
    printf 'font\tbold\tcontainer:/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf\t%s\n' \
        "$EXPECTED_BOLD_FONT"
    printf 'sdk-dangling-exclusions\t%s\tcount=9\n' \
        "$(hash_file "$SDK_DANGLING_EXCLUSIONS")"
    printf 'first-party-policy\t%s\tframeworks=7\tsources=7\n' \
        "$(hash_file "$FIRST_PARTY_PROVENANCE_POLICY")"
    printf 'toolchain\tswiftc\t%s\n' "$(swiftc --version | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
    printf 'toolchain\tclang\t%s\n' "$(clang-18 --version | head -1)"
    [ "$PREVIEW_ENABLED" -eq 0 ] || printf 'preview\tmodule=%s\tobject=%s\tplugin=%s\n' \
        "$PREVIEW_MODULE_SHA" "$PREVIEW_OBJECT_SHA" "$PREVIEW_PLUGIN_SHA"
} > "$STAGE/attestation/input-provenance.tsv"

ARTIFACT_LEDGER=$STAGE/attestation/artifacts.tsv
printf 'format\tcore-artifacts-v1\n' > "$ARTIFACT_LEDGER"
record_artifact() {
    local category=$1 name=$2 role=$3 relative=$4 size
    [ -f "$STAGE/$relative" ] && [ ! -L "$STAGE/$relative" ] \
        || die "artifact is not a regular file: $relative"
    size=$(wc -c < "$STAGE/$relative" | tr -d '[:space:]')
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$category" "$name" "$role" \
        "$relative" "$(hash_file "$STAGE/$relative")" "$size" \
        >> "$ARTIFACT_LEDGER"
}
record_module_family() {
    local category=$1 name=$2 file suffix role
    for file in "$STAGE/modules/$name".*; do
        [ -f "$file" ] || continue
        suffix=${file#"$STAGE/modules/$name."}
        role=$suffix
        [ "$suffix" != abi.json ] || role=abi-json
        record_artifact "$category" "$name" "$role" "modules/$(basename "$file")"
    done
}
for framework in FoundationEssentials OpenCoreGraphics OpenUIKit OpenCombine \
    Combine SwiftUI Foundation UIKit Intents IntentsUI WebKit \
    "${FIRST_PARTY_FRAMEWORKS[@]}"; do
    record_module_family framework "$framework"
    record_artifact framework "$framework" dylib "lib/lib$framework.dylib"
done
for dependency in InternalCollectionsUtilities OrderedCollections _RopeModule os; do
    record_module_family module-dependency "$dependency"
done
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    record_artifact module-dependency DeveloperToolsSupport swiftmodule \
        modules/DeveloperToolsSupport.swiftmodule
    record_artifact object DeveloperToolsSupport object \
        objects/developertoolsupport.o
fi
record_artifact runtime CQuartz dylib guest-root/darwin/usr/lib/libquartz.dylib
record_artifact runtime machorun executable guest-root/machorun
record_artifact resource OpenUIKit system-font \
    resources/OpenUIKit/fonts/DejaVuSans.ttf
record_artifact resource OpenUIKit bold-font \
    resources/OpenUIKit/fonts/DejaVuSans-Bold.ttf
while IFS= read -r resource; do
    relative=${resource#"$STAGE/"}
    case "$relative" in resources/OpenUIKit/fonts/*) continue ;; esac
    record_artifact resource OpenUIKit runtime-resource "$relative"
done < <(find "$STAGE/resources/OpenUIKit" -type f | LC_ALL=C sort)
record_artifact probe CoreGuestPackageProbe executable probe/CoreGuestPackageProbe
record_artifact attestation runtime runtime-log attestation/runtime.log
record_artifact attestation contracts compile-rsp compile-flags.rsp
record_artifact attestation contracts link-rsp link-inputs.rsp
record_artifact attestation source-sets manifest attestation/source-sets.tsv
record_artifact attestation foundation-sources manifest \
    attestation/foundation-sources.tsv
record_artifact attestation intents-sources manifest \
    attestation/intents-sources.tsv
record_artifact attestation webkit-sources manifest \
    attestation/webkit-sources.tsv
record_artifact attestation webkit-dylib-loads manifest \
    attestation/webkit-dylib-loads.tsv
record_artifact attestation foundation-undefined-symbols undefined-symbols \
    attestation/foundation-undefined-symbols.txt
record_artifact attestation first-party-sources manifest \
    attestation/first-party-sources.tsv
record_artifact attestation first-party-dylib-loads manifest \
    attestation/first-party-dylib-loads.tsv
record_artifact attestation input-provenance manifest \
    attestation/input-provenance.tsv
record_artifact attestation sdk-tree manifest attestation/sdk-tree.tsv
record_artifact attestation sdk-dangling-symlinks manifest \
    attestation/sdk-dangling-symlinks.tsv
record_artifact attestation sdk-dangling-exclusions manifest \
    attestation/sdk-dangling-symlink-exclusions.tsv
record_artifact attestation include-tree manifest attestation/include-tree.tsv
record_artifact attestation guest-root-tree manifest \
    attestation/guest-root-tree.tsv
record_artifact attestation resources-tree manifest \
    attestation/openuikit-resources-tree.tsv
record_artifact attestation runtime-closure manifest \
    attestation/runtime-closure.tsv
record_artifact attestation probe-link manifest attestation/probe-link-audit.tsv
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    record_artifact attestation preview load-rsp preview-plugin-load-flag.rsp
    record_artifact attestation preview manifest attestation/preview-input.tsv
fi

echo '== post-build input bracket'
assert_clean_commit "$UIKIT" "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE" post-OpenUIKit
assert_clean_commit "$MACHORUN" "$EXPECTED_MACHORUN_COMMIT" "$EXPECTED_MACHORUN_TREE" post-machorun
assert_clean_commit "$SWIFT_FOUNDATION" "$EXPECTED_FOUNDATION_COMMIT" "$EXPECTED_FOUNDATION_TREE" post-swift-foundation
assert_clean_commit "$SWIFT_COLLECTIONS" "$EXPECTED_COLLECTIONS_COMMIT" "$EXPECTED_COLLECTIONS_TREE" post-swift-collections
assert_clean_commit "$OPENCOMBINE_SOURCE" "$EXPECTED_OPENCOMBINE_COMMIT" "$EXPECTED_OPENCOMBINE_TREE" post-OpenCombine
[ "$SUPPORT_COMMIT" = "$(git -C "$W" rev-parse HEAD)" ] \
    && [ "$SUPPORT_TREE" = "$(git -C "$W" rev-parse HEAD^{tree})" ] \
    && [ -z "$(git -C "$W" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'support checkout changed during build'
python3 "$MANIFEST_TOOL" foundation-sources \
    --support-root "$W" --manifest "$FOUNDATION_SOURCES_MANIFEST" \
    --output "$WORK/foundation-sources.post.tsv"
cmp "$WORK/foundation-sources.pre.tsv" "$WORK/foundation-sources.post.tsv" \
    || die 'Foundation source manifest/files changed during build'
python3 -B "$WEBKIT_PROVENANCE_TOOL" production \
    --support-root "$W" --policy "$WEBKIT_PROVENANCE_POLICY" \
    --output "$WORK/webkit-sources.post.tsv"
cmp "$WORK/webkit-sources.pre.tsv" "$WORK/webkit-sources.post.tsv" \
    || die 'WebKit source manifest/files changed during build'
{
    printf 'format\tframework-guest-sources-v1\n'
    printf 'manifest\tIntents\t%s\tcount=%s\n' \
        "$(hash_file "$INTENTS_SOURCES_MANIFEST")" "${#INTENTS_SOURCES[@]}"
    for relative in "${INTENTS_SOURCES[@]}"; do
        printf 'source\tIntents\t%s\t%s\n' "$relative" "$(hash_file "$W/$relative")"
    done
    printf 'manifest\tIntentsUI\t%s\tcount=%s\n' \
        "$(hash_file "$INTENTSUI_SOURCES_MANIFEST")" "${#INTENTSUI_SOURCES[@]}"
    for relative in "${INTENTSUI_SOURCES[@]}"; do
        printf 'source\tIntentsUI\t%s\t%s\n' "$relative" "$(hash_file "$W/$relative")"
    done
} > "$WORK/intents-sources.post.tsv"
cmp "$WORK/intents-sources.pre.tsv" "$WORK/intents-sources.post.tsv" \
    || die 'Intents/IntentsUI source manifests/files changed during build'

python3 -B "$FIRST_PARTY_PROVENANCE_TOOL" production \
    --support-root "$W" --policy "$FIRST_PARTY_PROVENANCE_POLICY" \
    --output "$WORK/first-party-sources.post.tsv"
cmp "$WORK/first-party-sources.pre.tsv" "$WORK/first-party-sources.post.tsv" \
    || die 'first-party source manifests/files changed during build'
python3 "$MANIFEST_TOOL" inventory-tree \
    --root "$UIKIT/Sources/OpenUIKit/Resources" \
    --logical-root resources/OpenUIKit --reject-symlinks \
    --output "$WORK/openuikit-resources.post.tsv"
cmp "$WORK/openuikit-resources.pre.tsv" "$WORK/openuikit-resources.post.tsv" \
    || die 'OpenUIKit resources changed during build'
python3 "$MANIFEST_TOOL" inventory-tree \
    --root "$SYS" --logical-root sdk \
    --dangling-exclusions "$SDK_DANGLING_EXCLUSIONS" \
    --output "$WORK/sdk.post.tsv"
cmp "$WORK/sdk.pre.tsv" "$WORK/sdk.post.tsv" \
    || die 'SDK input changed during build'
python3 "$MANIFEST_TOOL" dangling-symlinks \
    --root "$SYS" --exclusions "$SDK_DANGLING_EXCLUSIONS" \
    --output "$WORK/sdk-dangling.post.tsv"
cmp "$WORK/sdk-dangling.pre.tsv" "$WORK/sdk-dangling.post.tsv" \
    || die 'SDK dangling-symlink input changed during build'
require_hash "$SYSTEM_FONT" "$EXPECTED_SYSTEM_FONT" post-system-font
require_hash "$BOLD_FONT" "$EXPECTED_BOLD_FONT" post-bold-font
if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    require_hash "$DEVELOPER_TOOLS_SUPPORT_MODULE" "$PREVIEW_MODULE_SHA" post-DTS-module
    require_hash "$DEVELOPER_TOOLS_SUPPORT_OBJECT" "$PREVIEW_OBJECT_SHA" post-DTS-object
    require_hash "$PREVIEW_MACRO_PLUGIN" "$PREVIEW_PLUGIN_SHA" post-preview-plugin
fi

WRITE_ARGS=(
    write --package-root "$STAGE"
    --artifact-ledger "$ARTIFACT_LEDGER"
    --artifact-ledger-relative attestation/artifacts.tsv
    --input-provenance attestation/input-provenance.tsv
    --source-sets attestation/source-sets.tsv
    --foundation-sources attestation/foundation-sources.tsv
    --intents-sources attestation/intents-sources.tsv
    --webkit-sources attestation/webkit-sources.tsv
    --first-party-sources attestation/first-party-sources.tsv
    --first-party-dylib-loads attestation/first-party-dylib-loads.tsv
    --sdk-inventory attestation/sdk-tree.tsv
    --sdk-dangling-symlinks attestation/sdk-dangling-symlinks.tsv
    --sdk-dangling-exclusions attestation/sdk-dangling-symlink-exclusions.tsv
    --include-inventory attestation/include-tree.tsv
    --guest-inventory attestation/guest-root-tree.tsv
    --resource-inventory attestation/openuikit-resources-tree.tsv
    --runtime-closure attestation/runtime-closure.tsv
    --compile-rsp compile-flags.rsp --link-rsp link-inputs.rsp
)
[ "$PREVIEW_ENABLED" -eq 0 ] \
    || WRITE_ARGS+=(--preview-attestation attestation/preview-input.tsv \
        --external-preview-plugin "$PREVIEW_MACRO_PLUGIN")
python3 "$MANIFEST_TOOL" "${WRITE_ARGS[@]}"
VERIFY_PREVIEW_ARGS=()
[ "$PREVIEW_ENABLED" -eq 0 ] \
    || VERIFY_PREVIEW_ARGS=(--preview-plugin "$PREVIEW_MACRO_PLUGIN")
python3 "$MANIFEST_TOOL" verify --package-root "$STAGE" \
    "${VERIFY_PREVIEW_ARGS[@]}"
{
    printf 'format\tcore-package-complete-v1\n'
    printf 'core-package-json\t%s\n' \
        "$(hash_file "$STAGE/attestation/core-package.json")"
    printf 'artifacts\t%s\n' "$(hash_file "$ARTIFACT_LEDGER")"
    printf 'runtime-closure\t%s\n' \
        "$(hash_file "$STAGE/attestation/runtime-closure.tsv")"
    printf 'runtime-log\t%s\n' "$(hash_file "$STAGE/attestation/runtime.log")"
} > "$STAGE/PACKAGE_COMPLETE"

mv -- "$STAGE" "$OUTPUT_ROOT"
python3 "$MANIFEST_TOOL" verify --package-root "$OUTPUT_ROOT" \
    "${VERIFY_PREVIEW_ARGS[@]}"
SUCCESS=1
echo "CORE_GUEST_PACKAGE_OK output=$OUTPUT_ROOT target=$TARGET preview=$PREVIEW_ENABLED"
