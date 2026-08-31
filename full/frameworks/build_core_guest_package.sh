#!/usr/bin/env bash
# Build a cold, relocatable ARM64 Mach-O core-framework package for unchanged
# application sources. Run inside the pinned Linux/arm64 production image with
# fresh build/cache/root paths. The production host wrapper gates publication
# on exact pre/post content manifests for every other replay input.

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
OBSERVATION_SOURCES_MANIFEST=$W/full/observation/observation_guest_sources.txt
INTENTS_SOURCES_MANIFEST=$W/full/intents/intents_guest_sources.txt
INTENTSUI_SOURCES_MANIFEST=$W/full/intentsui/intentsui_guest_sources.txt
WEBKIT_SOURCES_MANIFEST=$W/full/webkit/webkit_guest_sources.txt
COREIMAGE_SOURCES_MANIFEST=$W/full/coreimage/coreimage_guest_sources.txt
QUARTZCORE_SOURCES_MANIFEST=$W/full/quartzcore/quartzcore_guest_sources.txt
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
    CoreGraphics
    ImageIO
    LinkPresentation
    MessageUI
    MobileCoreServices
)
FIRST_PARTY_SOURCE_DIRS=(
    localauthentication
    safariservices
    network
    storekit
    audiotoolbox
    corehaptics
    passkit
    coregraphics
    imageio
    linkpresentation
    messageui
    mobilecoreservices
)
FRONTIER_FRAMEWORKS=(
    CoreGraphics
    ImageIO
    LinkPresentation
    MessageUI
    MobileCoreServices
)
FRONTIER_SOURCE_DIRS=(
    coregraphics
    imageio
    linkpresentation
    messageui
    mobilecoreservices
)

EXPECTED_SUPPORT_BASE=af37dd231dd5a31866c0c94a04a85679b0821eff
EXPECTED_UIKIT_SWIFT_COUNT=105
EXPECTED_OPENCOREGRAPHICS_SWIFT_COUNT=12
EXPECTED_SWIFTUI_SWIFT_COUNT=8
EXPECTED_CQUARTZ_CPP_COUNT=37
EXPECTED_FOUNDATION_SOURCE_COUNT=27
EXPECTED_OBSERVATION_SOURCE_COUNT=6
EXPECTED_INTENTS_SOURCE_COUNT=1
EXPECTED_INTENTSUI_SOURCE_COUNT=1
EXPECTED_WEBKIT_SOURCE_COUNT=5
EXPECTED_COREIMAGE_SOURCE_COUNT=1
EXPECTED_QUARTZCORE_SOURCE_COUNT=1
EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS=19
EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS=2
EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS=0
EXPECTED_FOUNDATION_DARWIN_UNDEFINEDS=2
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
EXPECTED_OBSERVATION_UPSTREAM_COMMIT=ee343b46aef81c3ac7c5d7960cb35a41a88c5a9b
OBSERVATION_MACRO_PLUGIN=/usr/lib/swift/host/plugins/libObservationMacros.so
EXPECTED_OBSERVATION_PLUGIN_SHA=ea6510afdd0a9e4808229c52441e9a67ca24e8ce186fccfd082547a5ee1c1229

OBSERVATION_SOURCE_HASHES=(
    a679f8ccd75265030d6cd28b81cb49e810bc97e8d9c42c78626cce7c3ea66b2d
    6668a4dc827c6b7019fd650383999ffe113f0f40807e7bfa0093d25eb4e64406
    bf533652129e87ad16918ba05c27a63ef4ceb3c84ca5f69ccc2d6745811e389b
    20b28faff988b6195598f90990d0ca9b5f6a38054f9ea213d266d11c3d3ba898
    e14626b87d2b1c305333e916f998f5a9d587789336bf7d98235e94b29f4baea4
    f597674fe55b4ddc3d22a6cab27e25baffb06c7fbe403cd686af74be615a5757
)
OBSERVATION_PLUGIN_HOST_LIBS=(
    libSwiftSyntaxMacros.so
    libSwiftSyntaxBuilder.so
    libSwiftParserDiagnostics.so
    libSwiftBasicFormat.so
    libSwiftParser.so
    libSwiftDiagnostics.so
    libSwiftSyntax.so
)
OBSERVATION_PLUGIN_HOST_HASHES=(
    bd32b50e01ae49aefbb8a4cb73c0f53284f6e38d8f5b5e9cf5704ea928de4435
    06a02fa8a9af26796c6238396ba73412bbb08f799238a7ea144a5d68c2eda971
    3109239e809fa5e81bd2c9d5e216948bb31f655b8ea05d32dc319f0da30bc077
    c652ba5f52686d740452389a8f5ab13dca808d898aea83927351ef00548eab0d
    ddbadfc8edb5a94fd2edc23cf3d560b97ad2ced6cbcefec8fcdf3add1dad8390
    f350546755ba25a725e89f8e993d1ca2edb83629de2a2a4b5268f83b5d0485b6
    d4aee0018bfb7103e09c281d3e3c5eead335f4a01581fb62063b3994e51ac440
)
OBSERVATION_PLUGIN_LINUX_LIBS=(
    libswiftCore.so
    libswift_Concurrency.so
    libswiftGlibc.so
    libdispatch.so
    libswift_Builtin_float.so
    libBlocksRuntime.so
)
OBSERVATION_PLUGIN_LINUX_HASHES=(
    8fdbbfbf6cda36870e97fe46af2bf21eff39253d97e878aaae003f5be0127f92
    42a70f4bef727842b6a949feceb260996adb1c6ee3b7c2d424dfa0419f4b949e
    003f47955f3744ba1277704add2431f1c58b82ab07b9d91b5809bec1b877857e
    39e502b3a8b016073947574a932172c1dafff8c41abd15b9b9f11bef7aaf1b6b
    62e2a42b1a98c56af695b154cbd01892d5c64acda3ee376950d960057d7c68af
    47a4f774ed1f4c094f8510c50d0006fde89a837ae785236e2ed669b8db9d002d
)

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
HOST_DISPATCH_SOURCE=/usr/lib/swift/linux/libdispatch.so
HOST_BLOCKS_RUNTIME_SOURCE=/usr/lib/swift/linux/libBlocksRuntime.so
EXPECTED_HOST_DISPATCH_SHA256=39e502b3a8b016073947574a932172c1dafff8c41abd15b9b9f11bef7aaf1b6b
EXPECTED_HOST_BLOCKS_RUNTIME_SHA256=47a4f774ed1f4c094f8510c50d0006fde89a837ae785236e2ed669b8db9d002d

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
    llvm-nm-18 perl python3 patch sha256sum cmp file readelf ldd curl-config \
    pkg-config find sort; do
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

mapfile -t OBSERVATION_SOURCES < "$OBSERVATION_SOURCES_MANIFEST"
[ "${#OBSERVATION_SOURCES[@]}" -eq "$EXPECTED_OBSERVATION_SOURCE_COUNT" ] \
    || die 'Observation source count drifted'
[ "${#OBSERVATION_SOURCE_HASHES[@]}" -eq "$EXPECTED_OBSERVATION_SOURCE_COUNT" ] \
    || die 'Observation source hash cardinality drifted'
observation_physical=$WORK/observation-physical.txt
find "$W/full/observation/Sources/Observation" -maxdepth 1 -type f \
    -name '*.swift' -print \
    | sed "s#^$W/##" | LC_ALL=C sort > "$observation_physical"
printf '%s\n' "${OBSERVATION_SOURCES[@]}" | LC_ALL=C sort \
    > "$WORK/observation-manifest-sorted.txt"
cmp "$observation_physical" "$WORK/observation-manifest-sorted.txt" \
    || die 'Observation physical Swift set differs from its manifest'
for index in "${!OBSERVATION_SOURCES[@]}"; do
    relative=${OBSERVATION_SOURCES[$index]}
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "Observation source is not a regular file: $relative"
    git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
        || die "Observation source is not tracked: $relative"
    require_hash "$W/$relative" "${OBSERVATION_SOURCE_HASHES[$index]}" \
        "Observation-source-$index"
done
for relative in \
    full/observation/ObservationRuntimeBridge.c \
    full/observation/UPSTREAM.md \
    full/observation/observation_guest_sources.txt \
    full/observation/tests/ObservationGuestRuntimeProbe.swift \
    full/observation/tests/ObservationGuestRuntimeMain.swift; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "Observation platform input is not a regular file: $relative"
    git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
        || die "Observation platform input is not tracked: $relative"
done
write_observation_sources_attestation() {
    local output=$1 index relative
    {
        printf 'format\tobservation-guest-sources-v1\n'
        printf 'upstream\tswiftlang/swift\tcommit=%s\ttag=swift-6.2.4-RELEASE\n' \
            "$EXPECTED_OBSERVATION_UPSTREAM_COMMIT"
        printf 'manifest\t%s\tcount=%s\n' \
            "$(hash_file "$OBSERVATION_SOURCES_MANIFEST")" \
            "$EXPECTED_OBSERVATION_SOURCE_COUNT"
        for index in "${!OBSERVATION_SOURCES[@]}"; do
            relative=${OBSERVATION_SOURCES[$index]}
            printf 'source\t%s\t%s\n' "$relative" "$(hash_file "$W/$relative")"
        done
        for relative in \
            full/observation/ObservationRuntimeBridge.c \
            full/observation/tests/ObservationGuestRuntimeProbe.swift \
            full/observation/tests/ObservationGuestRuntimeMain.swift; do
            printf 'platform\t%s\t%s\n' \
                "$relative" "$(hash_file "$W/$relative")"
        done
    } > "$output"
}
write_observation_sources_attestation "$WORK/observation-sources.pre.tsv"
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

mapfile -t COREIMAGE_SOURCES < "$COREIMAGE_SOURCES_MANIFEST"
mapfile -t QUARTZCORE_SOURCES < "$QUARTZCORE_SOURCES_MANIFEST"
[ "${#COREIMAGE_SOURCES[@]}" -eq "$EXPECTED_COREIMAGE_SOURCE_COUNT" ] \
    || die 'CoreImage source count drifted'
[ "${#QUARTZCORE_SOURCES[@]}" -eq "$EXPECTED_QUARTZCORE_SOURCE_COUNT" ] \
    || die 'QuartzCore source count drifted'
[ "${COREIMAGE_SOURCES[0]}" = full/coreimage/CoreImage.swift ] \
    || die 'CoreImage ordered source manifest drifted'
[ "${QUARTZCORE_SOURCES[0]}" = full/quartzcore/QuartzCore.swift ] \
    || die 'QuartzCore ordered source manifest drifted'
for relative in "${COREIMAGE_SOURCES[@]}" "${QUARTZCORE_SOURCES[@]}"; do
    [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
        || die "graphics framework source is not a regular file: $relative"
    git -C "$W" ls-files --error-unmatch "$relative" >/dev/null \
        || die "graphics framework source is not tracked: $relative"
done
for coreimage_input in \
    "$COREIMAGE_SOURCES_MANIFEST" \
    "$W/full/coreimage/include/CoreImage.h" \
    "$W/full/coreimage/include/CIFilterBuiltins.h" \
    "$W/full/coreimage/include/module.modulemap" \
    "$QUARTZCORE_SOURCES_MANIFEST"; do
    [ -f "$coreimage_input" ] && [ ! -L "$coreimage_input" ] \
        || die "graphics framework input is not a regular file: $coreimage_input"
    git -C "$W" ls-files --error-unmatch "${coreimage_input#"$W"/}" >/dev/null \
        || die "graphics framework input is not tracked: $coreimage_input"
done
write_graphics_sources_attestation() {
    local output=$1 relative
    {
        printf 'format\tgraphics-framework-guest-sources-v1\n'
        printf 'manifest\tCoreImage\t%s\tcount=%s\n' \
            "$(hash_file "$COREIMAGE_SOURCES_MANIFEST")" \
            "${#COREIMAGE_SOURCES[@]}"
        for relative in "${COREIMAGE_SOURCES[@]}"; do
            printf 'source\tCoreImage\t%s\t%s\n' \
                "$relative" "$(hash_file "$W/$relative")"
        done
        printf 'underlying\tCoreImage\t%s\t%s\n' \
            full/coreimage/include/CoreImage.h \
            "$(hash_file "$W/full/coreimage/include/CoreImage.h")"
        printf 'underlying\tCoreImage.CIFilterBuiltins\t%s\t%s\n' \
            full/coreimage/include/CIFilterBuiltins.h \
            "$(hash_file "$W/full/coreimage/include/CIFilterBuiltins.h")"
        printf 'modulemap\tCoreImage\t%s\t%s\n' \
            full/coreimage/include/module.modulemap \
            "$(hash_file "$W/full/coreimage/include/module.modulemap")"
        printf 'manifest\tQuartzCore\t%s\tcount=%s\n' \
            "$(hash_file "$QUARTZCORE_SOURCES_MANIFEST")" \
            "${#QUARTZCORE_SOURCES[@]}"
        for relative in "${QUARTZCORE_SOURCES[@]}"; do
            printf 'source\tQuartzCore\t%s\t%s\n' \
                "$relative" "$(hash_file "$W/$relative")"
        done
    } > "$output"
}
write_graphics_sources_attestation "$WORK/graphics-sources.pre.tsv"

python3 -B "$FIRST_PARTY_PROVENANCE_TOOL" production \
    --support-root "$W" --policy "$FIRST_PARTY_PROVENANCE_POLICY" \
    --output "$WORK/first-party-sources.pre.tsv"
[ "$(grep -c '^source' "$WORK/first-party-sources.pre.tsv")" -eq 7 ] \
    || die 'first-party production source count drifted'
append_frontier_sources() {
    local output=$1 index framework source_dir source_manifest relative
    local -a frontier_sources
    for index in "${!FRONTIER_FRAMEWORKS[@]}"; do
        framework=${FRONTIER_FRAMEWORKS[$index]}
        source_dir=${FRONTIER_SOURCE_DIRS[$index]}
        source_manifest=$W/full/$source_dir/${source_dir}_guest_sources.txt
        [ -f "$source_manifest" ] && [ ! -L "$source_manifest" ] \
            || die "$framework frontier source manifest is missing or linked"
        mapfile -t frontier_sources < "$source_manifest"
        [ "${#frontier_sources[@]}" -eq 1 ] \
            || die "$framework frontier source manifest cardinality drifted"
        relative=${frontier_sources[0]}
        [ "$relative" = "full/$source_dir/$framework.swift" ] \
            || die "$framework frontier source path drifted: $relative"
        [ -f "$W/$relative" ] && [ ! -L "$W/$relative" ] \
            || die "$framework frontier source is missing or linked"
        git -C "$W" ls-files --error-unmatch \
            "${source_manifest#"$W"/}" "$relative" >/dev/null \
            || die "$framework frontier inputs are not tracked"
        printf 'frontier-source\t%s\t%s\t%s\t%s\n' \
            "$((index + 1))" "$framework" "$relative" \
            "$(hash_file "$W/$relative")" >> "$output"
        printf 'frontier-manifest\t%s\t%s\t%s\t%s\n' \
            "$((index + 1))" "$framework" "${source_manifest#"$W"/}" \
            "$(hash_file "$source_manifest")" >> "$output"
    done
}
append_frontier_sources "$WORK/first-party-sources.pre.tsv"
[ "$(grep -c '^frontier-source' "$WORK/first-party-sources.pre.tsv")" -eq 5 ] \
    || die 'frontier framework source count drifted'

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

[ "${#OBSERVATION_PLUGIN_HOST_LIBS[@]}" -eq \
    "${#OBSERVATION_PLUGIN_HOST_HASHES[@]}" ] \
    || die 'Observation host plugin closure cardinality drifted'
[ "${#OBSERVATION_PLUGIN_LINUX_LIBS[@]}" -eq \
    "${#OBSERVATION_PLUGIN_LINUX_HASHES[@]}" ] \
    || die 'Observation Linux plugin closure cardinality drifted'
require_hash "$OBSERVATION_MACRO_PLUGIN" "$EXPECTED_OBSERVATION_PLUGIN_SHA" \
    Observation-macro-plugin
file "$OBSERVATION_MACRO_PLUGIN" | grep -Eq 'ELF 64-bit.*(ARM aarch64|aarch64)' \
    || die 'Observation macro plugin is not native ELF64/aarch64'
readelf -h "$OBSERVATION_MACRO_PLUGIN" \
    | grep -Eq 'Machine:[[:space:]]+AArch64' \
    || die 'Observation macro plugin ELF machine is not AArch64'
for index in "${!OBSERVATION_PLUGIN_HOST_LIBS[@]}"; do
    library=${OBSERVATION_PLUGIN_HOST_LIBS[$index]}
    require_hash "/usr/lib/swift/host/$library" \
        "${OBSERVATION_PLUGIN_HOST_HASHES[$index]}" \
        "Observation-plugin-host-$library"
done
for index in "${!OBSERVATION_PLUGIN_LINUX_LIBS[@]}"; do
    library=${OBSERVATION_PLUGIN_LINUX_LIBS[$index]}
    require_hash "/usr/lib/swift/linux/$library" \
        "${OBSERVATION_PLUGIN_LINUX_HASHES[$index]}" \
        "Observation-plugin-linux-$library"
done
OBSERVATION_TOOLCHAIN=$(swiftc --version | tr '\n' ' ' | sed 's/[[:space:]]*$//')
printf '%s\n' "$OBSERVATION_TOOLCHAIN" | grep -Fq 'Swift version 6.2.4' \
    || die "Observation consumer toolchain is not Swift 6.2.4: $OBSERVATION_TOOLCHAIN"

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
        "$PREVIEW_MACRO_PLUGIN#OpenUIKitPreviewMacros" -j1)
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
    "$STAGE/guest-root" "$STAGE/probe" "$STAGE/attestation" \
    "$STAGE/host-tools/swift/host/plugins" \
    "$STAGE/host-tools/swift/linux"
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

cp "$OBSERVATION_MACRO_PLUGIN" \
    "$STAGE/host-tools/swift/host/plugins/libObservationMacros.so"
for library in "${OBSERVATION_PLUGIN_HOST_LIBS[@]}"; do
    cp "/usr/lib/swift/host/$library" "$STAGE/host-tools/swift/host/$library"
done
for library in "${OBSERVATION_PLUGIN_LINUX_LIBS[@]}"; do
    cp "/usr/lib/swift/linux/$library" "$STAGE/host-tools/swift/linux/$library"
done
STAGED_OBSERVATION_PLUGIN=$STAGE/host-tools/swift/host/plugins/libObservationMacros.so
OBSERVATION_PLUGIN_FLAGS=(-load-plugin-library "$STAGED_OBSERVATION_PLUGIN")
if ldd "$STAGED_OBSERVATION_PLUGIN" | grep -Fq 'not found'; then
    die 'packaged Observation macro plugin closure is incomplete'
fi
{
    printf 'format\tobservation-macro-plugin-v1\n'
    printf 'toolchain\t%s\n' "$OBSERVATION_TOOLCHAIN"
    printf 'plugin\thost-tools/swift/host/plugins/libObservationMacros.so\t%s\n' \
        "$(hash_file "$STAGED_OBSERVATION_PLUGIN")"
    for library in "${OBSERVATION_PLUGIN_HOST_LIBS[@]}"; do
        printf 'closure\thost-tools/swift/host/%s\t%s\n' \
            "$library" \
            "$(hash_file "$STAGE/host-tools/swift/host/$library")"
    done
    for library in "${OBSERVATION_PLUGIN_LINUX_LIBS[@]}"; do
        printf 'closure\thost-tools/swift/linux/%s\t%s\n' \
            "$library" \
            "$(hash_file "$STAGE/host-tools/swift/linux/$library")"
    done
    while IFS=$'\t' read -r soname resolved; do
        resolved=${resolved#"$STAGE/"}
        printf 'resolved\t%s\t%s\n' "$soname" "$resolved"
    done < <(ldd "$STAGED_OBSERVATION_PLUGIN" \
        | awk '/=>/ { print $1 "\t" $3; next } \
            /^[[:space:]]*\// { print $1 "\t" $1 }' \
        | LC_ALL=C sort -u)
} > "$STAGE/attestation/observation-macro-plugin.tsv"

cp -a "$FULL/inc/CPortableIO" "$STAGE/include/"
cp -a "$FULL/inc/CSTBTrueType" "$STAGE/include/"
mkdir -p "$STAGE/include/CHostClock" "$STAGE/include/CQuartz" \
    "$STAGE/include/COpenCombineHelpers" "$STAGE/include/COpenURLTransport" \
    "$STAGE/include/COpenRelativeTime" "$STAGE/include/COpenDispatch" \
    "$STAGE/include/_FoundationCShims" "$STAGE/guest-root/host"
cp -a "$W/full/hostclock/include/." "$STAGE/include/CHostClock/"
cp -a "$UIKIT/Sources/CQuartz/include/." "$STAGE/include/CQuartz/"
cp -a "$OPENCOMBINE_HELPERS/include/." "$STAGE/include/COpenCombineHelpers/"
cp -a "$W/full/urltransport/include/." "$STAGE/include/COpenURLTransport/"
cp -a "$W/full/relativetime/include/." "$STAGE/include/COpenRelativeTime/"
cp -a "$W/full/dispatch/include/." "$STAGE/include/COpenDispatch/"
cp -a "$SWIFT_FOUNDATION/Sources/_FoundationCShims/include/." \
    "$STAGE/include/_FoundationCShims/"
cp -a "$W/full/coreimage/include" "$STAGE/include/CoreImage"

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
    -Xcc -I"$STAGE/include/CQuartz"
    -Xcc -fmodule-map-file="$STAGE/include/CoreImage/module.modulemap"
    -Xcc -I"$STAGE/include/CoreImage"
    -Xcc -fmodule-map-file="$STAGE/include/COpenURLTransport/module.modulemap"
    -Xcc -I"$STAGE/include/COpenURLTransport"
    -Xcc -fmodule-map-file="$STAGE/include/COpenRelativeTime/module.modulemap"
    -Xcc -I"$STAGE/include/COpenRelativeTime"
    -Xcc -fmodule-map-file="$STAGE/include/COpenDispatch/module.modulemap"
    -Xcc -I"$STAGE/include/COpenDispatch")
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
SWIFTUI_RUNTIME_BASENAME=libswift_Concurrency
SWIFTUI_RUNTIME_LINK_FLAG=-lswift_Concurrency
SWIFTUI_RUNTIME_INSTALL_NAME=/usr/lib/swift/libswift_Concurrency.dylib
FOUNDATION_RUNTIME_BASENAMES=(
    libswift_StringProcessing
    libswiftSynchronization
    libswiftDarwin
    "${SWIFTUI_RUNTIME_BASENAME}"
)
FOUNDATION_RUNTIME_LINK_FLAGS=(
    -lswift_StringProcessing
    -lswiftSynchronization
    -lswiftDarwin
    "${SWIFTUI_RUNTIME_LINK_FLAG}"
)
FOUNDATION_RUNTIME_INSTALL_NAMES=(
    /usr/lib/swift/libswift_StringProcessing.dylib
    /usr/lib/swift/libswiftSynchronization.dylib
    /usr/lib/swift/libswiftDarwin.dylib
    "${SWIFTUI_RUNTIME_INSTALL_NAME}"
)
[ "${#FOUNDATION_RUNTIME_BASENAMES[@]}" -eq 4 ] \
    && [ "${#FOUNDATION_RUNTIME_LINK_FLAGS[@]}" -eq 4 ] \
    && [ "${#FOUNDATION_RUNTIME_INSTALL_NAMES[@]}" -eq 4 ] \
    || die 'Foundation runtime closure cardinality drifted'
for index in "${!FOUNDATION_RUNTIME_BASENAMES[@]}"; do
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
swiftui_runtime_link_input=$STAGE/sdk/usr/lib/swift/$SWIFTUI_RUNTIME_BASENAME.tbd
swiftui_runtime_input=$RUNTIME/darwin$SWIFTUI_RUNTIME_INSTALL_NAME
[ -f "$swiftui_runtime_link_input" ] && [ ! -L "$swiftui_runtime_link_input" ] \
    || die "SwiftUI runtime link input is missing: $swiftui_runtime_link_input"
[ -f "$swiftui_runtime_input" ] && [ ! -L "$swiftui_runtime_input" ] \
    || die "SwiftUI staged runtime dylib is missing: $swiftui_runtime_input"
swiftui_runtime_actual_id=$(llvm-otool-18 -D "$swiftui_runtime_input" | tail -n 1)
[ "$swiftui_runtime_actual_id" = "$SWIFTUI_RUNTIME_INSTALL_NAME" ] \
    || die "SwiftUI staged runtime ID $swiftui_runtime_actual_id, expected $SWIFTUI_RUNTIME_INSTALL_NAME"

echo '== build and audit the fixed-ABI Linux URL transport boundary'
URL_TRANSPORT_DARWIN=$RUNTIME/darwin/usr/lib/libOpenURLTransport.dylib
URL_TRANSPORT_HOST=$RUNTIME/host/libOpenURLTransportHost.so
clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenURLTransport" \
    -c "$W/full/urltransport/OpenURLTransportBridge.c" \
    -o "$WORK/open-url-transport-bridge.o"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenURLTransport.dylib \
    -o "$URL_TRANSPORT_DARWIN" "$WORK/open-url-transport-bridge.o"
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenURLTransport" -shared \
    "$W/full/urltransport/OpenURLTransportHost.c" \
    -o "$URL_TRANSPORT_HOST" -lcurl -pthread
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenURLTransport" \
    "$W/full/urltransport/OpenURLTransportHost.c" \
    "$W/full/urltransport/OpenURLTransportHostTests.c" \
    -o "$WORK/open-url-transport-host-tests" -lcurl -pthread

(
    set -e
    server_port_file=$WORK/url-transport-server.port
    server_log=$WORK/url-transport-server.log
    python3 -B "$W/full/foundation/tests/url_session_test_server.py" \
        --port-file "$server_port_file" >"$server_log" 2>&1 &
    server_pid=$!
    trap 'kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true' EXIT
    for _ in $(seq 1 200); do
        [ ! -s "$server_port_file" ] || break
        sleep 0.01
    done
    [ -s "$server_port_file" ] || die 'URL transport test server did not publish its port'
    server_port=$(tr -d '[:space:]' < "$server_port_file")
    "$WORK/open-url-transport-host-tests" "http://127.0.0.1:$server_port" \
        > "$WORK/url-transport-host-test.log"
)
grep -Fx \
    'OPEN_URL_TRANSPORT_HOST_OK bounds=hard,response method=token headers=validated cancel-destroy=race-safe' \
    "$WORK/url-transport-host-test.log" >/dev/null \
    || die 'native URL transport semantic marker is missing'

URL_TRANSPORT_SYMBOLS=(cancel create destroy perform release_response)
URL_TRANSPORT_EXPECTED_ELF=$WORK/url-transport-expected-elf.txt
URL_TRANSPORT_EXPECTED_MACH_EXPORTS=$WORK/url-transport-expected-mach-exports.txt
URL_TRANSPORT_EXPECTED_MACH_IMPORTS=$WORK/url-transport-expected-mach-imports.txt
: > "$URL_TRANSPORT_EXPECTED_ELF"
: > "$URL_TRANSPORT_EXPECTED_MACH_EXPORTS"
: > "$URL_TRANSPORT_EXPECTED_MACH_IMPORTS"
for symbol in "${URL_TRANSPORT_SYMBOLS[@]}"; do
    printf 'openui_url_transport_v1_%s\n' "$symbol" \
        >> "$URL_TRANSPORT_EXPECTED_ELF"
    printf '_openui_url_transport_v1_%s\n' "$symbol" \
        >> "$URL_TRANSPORT_EXPECTED_MACH_EXPORTS"
    printf '_glibc_openui_url_transport_v1_%s\n' "$symbol" \
        >> "$URL_TRANSPORT_EXPECTED_MACH_IMPORTS"
done
readelf --wide --syms "$URL_TRANSPORT_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_url_transport_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$WORK/url-transport-elf-exports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$URL_TRANSPORT_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/url-transport-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$URL_TRANSPORT_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/url-transport-mach-imports.txt"
cmp "$URL_TRANSPORT_EXPECTED_ELF" "$WORK/url-transport-elf-exports.txt" \
    || die 'Linux URL transport helper exports drifted'
cmp "$URL_TRANSPORT_EXPECTED_MACH_EXPORTS" "$WORK/url-transport-mach-exports.txt" \
    || die 'Mach-O URL transport bridge exports drifted'
cmp "$URL_TRANSPORT_EXPECTED_MACH_IMPORTS" "$WORK/url-transport-mach-imports.txt" \
    || die 'Mach-O URL transport host imports drifted'
[ "$(llvm-otool-18 -D "$URL_TRANSPORT_DARWIN" | tail -n 1)" = \
    /usr/lib/libOpenURLTransport.dylib ] \
    || die 'Mach-O URL transport install name drifted'
{
    printf 'format\topen-url-transport-abi-v1\n'
    printf 'request-layout\tsize=104\tpointers=64-bit\n'
    printf 'response-layout\tsize=88\tpointers=64-bit\n'
    for symbol in "${URL_TRANSPORT_SYMBOLS[@]}"; do
        printf 'symbol\topenui_url_transport_v1_%s\tguest-export=_openui_url_transport_v1_%s\tguest-host-import=_glibc_openui_url_transport_v1_%s\thost-export=openui_url_transport_v1_%s\n' \
            "$symbol" "$symbol" "$symbol" "$symbol"
    done
} > "$STAGE/attestation/url-transport-abi.tsv"

curl_ca=$(curl-config --ca)
[ -f "$curl_ca" ] && [ ! -L "$curl_ca" ] \
    || die "libcurl CA bundle is not a regular file: $curl_ca"
readelf --wide --dynamic "$URL_TRANSPORT_HOST" \
    | awk '$2 == "(NEEDED)" { value=$5; gsub(/^\[|\]$/, "", value); print value }' \
    | LC_ALL=C sort -u > "$WORK/url-transport-direct-sonames.txt"
ldd "$URL_TRANSPORT_HOST" \
    | awk '/=>/ { print $1; next } /^[[:space:]]*\// { count=split($1, part, "/"); print part[count] }' \
    | LC_ALL=C sort -u > "$WORK/url-transport-transitive-sonames.txt"
{
    printf 'format\topen-url-transport-host-v1\n'
    printf 'libcurl-version\t%s\n' "$(curl-config --version)"
    printf 'tls-backend\t%s\n' "$(curl-config --ssl-backends)"
    printf 'tls-verification\tpeer=required\thost=required\n'
    printf 'redirects\thost-disabled\tguest-owned\n'
    printf 'ca-bundle\t%s\t%s\n' "$curl_ca" "$(hash_file "$curl_ca")"
    while IFS= read -r feature; do
        printf 'feature\t%s\n' "$feature"
    done < <(curl-config --features)
    while IFS= read -r soname; do
        printf 'direct-soname\t%s\n' "$soname"
    done < "$WORK/url-transport-direct-sonames.txt"
    while IFS= read -r soname; do
        printf 'transitive-soname\t%s\n' "$soname"
    done < "$WORK/url-transport-transitive-sonames.txt"
} > "$STAGE/attestation/url-transport-host.tsv"
{
    printf 'local\tdarwin/usr/lib/libOpenURLTransport.dylib\t%s\tbuilt from full/urltransport/OpenURLTransportBridge.c\n' \
        "$(hash_file "$URL_TRANSPORT_DARWIN")"
    printf 'local\thost/libOpenURLTransportHost.so\t%s\tbuilt from full/urltransport/OpenURLTransportHost.c\n' \
        "$(hash_file "$URL_TRANSPORT_HOST")"
} >> "$RUNTIME/.manifest"

echo '== build and audit the fixed-ABI ICU relative-time boundary'
RELATIVE_TIME_DARWIN=$RUNTIME/darwin/usr/lib/libOpenRelativeTime.dylib
RELATIVE_TIME_HOST=$RUNTIME/host/libOpenRelativeTimeHost.so
clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenRelativeTime" \
    -c "$W/full/relativetime/OpenRelativeTimeBridge.c" \
    -o "$WORK/open-relative-time-bridge.o"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenRelativeTime.dylib \
    -o "$RELATIVE_TIME_DARWIN" "$WORK/open-relative-time-bridge.o"
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenRelativeTime" -shared \
    "$W/full/relativetime/OpenRelativeTimeHost.c" \
    -o "$RELATIVE_TIME_HOST" -licui18n -licuuc -lm
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenRelativeTime" \
    "$W/full/relativetime/OpenRelativeTimeHost.c" \
    "$W/full/relativetime/OpenRelativeTimeHostTests.c" \
    -o "$WORK/open-relative-time-host-tests" -licui18n -licuuc -lm
"$WORK/open-relative-time-host-tests" \
    > "$WORK/open-relative-time-host-test.log"
grep -Fx \
    'OPEN_RELATIVE_TIME_HOST_OK icu=real locale=en,fr,de,ja styles=4 bounds=hard' \
    "$WORK/open-relative-time-host-test.log" >/dev/null \
    || die 'native relative-time semantic marker is missing'

printf 'openui_relative_time_v1_format\n' \
    > "$WORK/relative-time-expected-elf.txt"
printf '_openui_relative_time_v1_format\n' \
    > "$WORK/relative-time-expected-mach-exports.txt"
printf '_glibc_openui_relative_time_v1_format\n' \
    > "$WORK/relative-time-expected-mach-imports.txt"
readelf --wide --syms "$RELATIVE_TIME_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_relative_time_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$WORK/relative-time-elf-exports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$RELATIVE_TIME_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/relative-time-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$RELATIVE_TIME_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/relative-time-mach-imports.txt"
cmp "$WORK/relative-time-expected-elf.txt" \
    "$WORK/relative-time-elf-exports.txt" \
    || die 'Linux relative-time helper exports drifted'
cmp "$WORK/relative-time-expected-mach-exports.txt" \
    "$WORK/relative-time-mach-exports.txt" \
    || die 'Mach-O relative-time bridge exports drifted'
cmp "$WORK/relative-time-expected-mach-imports.txt" \
    "$WORK/relative-time-mach-imports.txt" \
    || die 'Mach-O relative-time host imports drifted'
[ "$(llvm-otool-18 -D "$RELATIVE_TIME_DARWIN" | tail -n 1)" = \
    /usr/lib/libOpenRelativeTime.dylib ] \
    || die 'Mach-O relative-time install name drifted'

readelf --wide --dynamic "$RELATIVE_TIME_HOST" \
    | awk '$2 == "(NEEDED)" { value=$5; gsub(/^\[|\]$/, "", value); print value }' \
    | LC_ALL=C sort -u > "$WORK/relative-time-direct-sonames.txt"
ldd "$RELATIVE_TIME_HOST" \
    | awk '/=>/ { print $1; next } /^[[:space:]]*\// { count=split($1, part, "/"); print part[count] }' \
    | LC_ALL=C sort -u > "$WORK/relative-time-transitive-sonames.txt"
{
    printf 'format\topen-relative-time-abi-v1\n'
    printf 'symbol\topenui_relative_time_v1_format\tguest-export=_openui_relative_time_v1_format\tguest-host-import=_glibc_openui_relative_time_v1_format\thost-export=openui_relative_time_v1_format\n'
    printf 'limits\tlocale-bytes=256\toutput-bytes=4096\n'
} > "$STAGE/attestation/relative-time-abi.tsv"
{
    printf 'format\topen-relative-time-host-v1\n'
    printf 'icu-version\t%s\n' "$(pkg-config --modversion icu-i18n)"
    printf 'locales\ticu-data-driven\n'
    printf 'styles\tfull,spell-out,short,abbreviated\n'
    while IFS= read -r soname; do
        printf 'direct-soname\t%s\n' "$soname"
    done < "$WORK/relative-time-direct-sonames.txt"
    while IFS= read -r soname; do
        printf 'transitive-soname\t%s\n' "$soname"
    done < "$WORK/relative-time-transitive-sonames.txt"
} > "$STAGE/attestation/relative-time-host.tsv"
{
    printf 'local\tdarwin/usr/lib/libOpenRelativeTime.dylib\t%s\tbuilt from full/relativetime/OpenRelativeTimeBridge.c\n' \
        "$(hash_file "$RELATIVE_TIME_DARWIN")"
    printf 'local\thost/libOpenRelativeTimeHost.so\t%s\tbuilt from full/relativetime/OpenRelativeTimeHost.c\n' \
        "$(hash_file "$RELATIVE_TIME_HOST")"
} >> "$RUNTIME/.manifest"

echo '== build and pin the Linux libdispatch scheduling boundary'
for host_runtime_input in "$HOST_DISPATCH_SOURCE" "$HOST_BLOCKS_RUNTIME_SOURCE"; do
    [ -f "$host_runtime_input" ] && [ ! -L "$host_runtime_input" ] \
        || die "host Dispatch runtime input is not a regular file: $host_runtime_input"
done
require_hash "$HOST_DISPATCH_SOURCE" "$EXPECTED_HOST_DISPATCH_SHA256" \
    host-libdispatch
require_hash "$HOST_BLOCKS_RUNTIME_SOURCE" \
    "$EXPECTED_HOST_BLOCKS_RUNTIME_SHA256" host-BlocksRuntime
cp "$HOST_DISPATCH_SOURCE" "$RUNTIME/host/libdispatch.so"
cp "$HOST_BLOCKS_RUNTIME_SOURCE" "$RUNTIME/host/libBlocksRuntime.so"

DISPATCH_HOST=$RUNTIME/host/libOpenDispatchHost.so
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$W/full/dispatch/include" -I /usr/lib/swift -shared \
    "$W/full/dispatch/OpenDispatchHost.c" \
    -L "$RUNTIME/host" -Wl,-rpath,'$ORIGIN' \
    -ldispatch -Wl,--no-as-needed -lBlocksRuntime -Wl,--as-needed -pthread \
    -o "$DISPATCH_HOST"
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$W/full/dispatch/include" -I /usr/lib/swift \
    "$W/full/dispatch/OpenDispatchHost.c" \
    "$W/full/dispatch/OpenDispatchHostTests.c" \
    -L "$RUNTIME/host" -Wl,-rpath,"$RUNTIME/host" \
    -ldispatch -Wl,--no-as-needed -lBlocksRuntime -Wl,--as-needed -pthread \
    -o "$WORK/open-dispatch-host-tests"
LD_LIBRARY_PATH="$RUNTIME/host" "$WORK/open-dispatch-host-tests" \
    > "$WORK/open-dispatch-host-test.log" 2>&1
grep -Fx \
    'OPEN_DISPATCH_HOST_OK global=minted async=worker after=timer main-token=contained glibc>=2.38' \
    "$WORK/open-dispatch-host-test.log" >/dev/null \
    || die 'native Dispatch host semantic marker is missing'

DISPATCH_HOST_EXPECTED_EXPORTS=$WORK/open-dispatch-host-expected-exports.txt
{
    printf '%s\n' \
        openui_dispatch_host_v1_after \
        openui_dispatch_host_v1_async \
        openui_dispatch_host_v1_get_global_queue \
        openui_dispatch_host_v1_main \
        openui_dispatch_host_v1_monotonic_nanoseconds \
        openui_dispatch_host_v1_runtime_check
} > "$DISPATCH_HOST_EXPECTED_EXPORTS"
readelf --wide --syms "$DISPATCH_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_dispatch_host_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$WORK/open-dispatch-host-exports.txt"
cmp "$DISPATCH_HOST_EXPECTED_EXPORTS" "$WORK/open-dispatch-host-exports.txt" \
    || die 'Linux Dispatch helper exports drifted'

dispatch_glibc_max=$(readelf --version-info "$RUNTIME/host/libdispatch.so" \
    | grep -o 'GLIBC_[0-9][0-9.]*' | sort -Vu | tail -n 1)
blocks_glibc_max=$(readelf --version-info "$RUNTIME/host/libBlocksRuntime.so" \
    | grep -o 'GLIBC_[0-9][0-9.]*' | sort -Vu | tail -n 1)
[ "$dispatch_glibc_max" = GLIBC_2.38 ] \
    || die "staged libdispatch maximum glibc requirement is $dispatch_glibc_max, expected GLIBC_2.38"
[ "$blocks_glibc_max" = GLIBC_2.17 ] \
    || die "staged BlocksRuntime maximum glibc requirement is $blocks_glibc_max, expected GLIBC_2.17"
readelf --wide --dynamic "$DISPATCH_HOST" \
    | awk '$2 == "(NEEDED)" { value=$5; gsub(/^\[|\]$/, "", value); print value }' \
    | LC_ALL=C sort -u > "$WORK/open-dispatch-host-sonames.txt"
for required_soname in libdispatch.so libBlocksRuntime.so; do
    grep -Fx "$required_soname" "$WORK/open-dispatch-host-sonames.txt" >/dev/null \
        || die "Linux Dispatch helper does not pin $required_soname"
done
{
    printf 'format\topen-dispatch-host-v1\n'
    printf 'host-abi\tELF64-AArch64\n'
    printf 'glibc-minimum\t2.38\tsource=staged-libdispatch-version-needs\n'
    printf 'runtime\tlibdispatch.so\t%s\tmax-version=%s\n' \
        "$(hash_file "$RUNTIME/host/libdispatch.so")" "$dispatch_glibc_max"
    printf 'runtime\tlibBlocksRuntime.so\t%s\tmax-version=%s\n' \
        "$(hash_file "$RUNTIME/host/libBlocksRuntime.so")" "$blocks_glibc_max"
    printf 'helper\tlibOpenDispatchHost.so\t%s\trpath=$ORIGIN\n' \
        "$(hash_file "$DISPATCH_HOST")"
    while IFS= read -r soname; do
        printf 'direct-soname\t%s\n' "$soname"
    done < "$WORK/open-dispatch-host-sonames.txt"
    printf 'queue-policy\tmain=kind-only\tglobal=helper-minted-only\n'
    printf 'job-policy\tguest-callback=opaque\thost-dispatch=dispatch_async_f\n'
} > "$STAGE/attestation/open-dispatch-host.tsv"
cp "$WORK/open-dispatch-host-test.log" \
    "$STAGE/attestation/open-dispatch-host-test.log"

clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$STAGE/include/COpenDispatch" \
    -c "$W/full/dispatch/OpenDispatchBridge.c" \
    -o "$WORK/open-dispatch-bridge.o"
DISPATCH_DARWIN=$RUNTIME/darwin/usr/lib/libOpenDispatch.dylib
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenDispatch.dylib \
    -o "$DISPATCH_DARWIN" "$WORK/open-dispatch-bridge.o"
{
    printf '%s\n' \
        _openui_dispatch_v1_after \
        _openui_dispatch_v1_async \
        _openui_dispatch_v1_get_global_queue \
        _openui_dispatch_v1_monotonic_nanoseconds
} > "$WORK/open-dispatch-mach-expected-exports.txt"
{
    printf '%s\n' \
        _glibc_openui_dispatch_host_v1_after \
        _glibc_openui_dispatch_host_v1_async \
        _glibc_openui_dispatch_host_v1_get_global_queue \
        _glibc_openui_dispatch_host_v1_monotonic_nanoseconds
} > "$WORK/open-dispatch-mach-expected-imports.txt"
llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$DISPATCH_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/open-dispatch-mach-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$DISPATCH_DARWIN" | LC_ALL=C sort -u \
    > "$WORK/open-dispatch-mach-imports.txt"
cmp "$WORK/open-dispatch-mach-expected-exports.txt" \
    "$WORK/open-dispatch-mach-exports.txt" \
    || die 'Mach-O Dispatch bridge exports drifted'
cmp "$WORK/open-dispatch-mach-expected-imports.txt" \
    "$WORK/open-dispatch-mach-imports.txt" \
    || die 'Mach-O Dispatch bridge host imports drifted'
[ "$(llvm-otool-18 -D "$DISPATCH_DARWIN" | tail -n 1)" = \
    /usr/lib/libOpenDispatch.dylib ] \
    || die 'Mach-O Dispatch bridge install name drifted'
{
    printf 'local\tdarwin/usr/lib/libOpenDispatch.dylib\t%s\tbuilt from full/dispatch/OpenDispatchBridge.c\n' \
        "$(hash_file "$DISPATCH_DARWIN")"
    printf 'local\thost/libdispatch.so\t%s\tpinned Swift 6.2.4 Linux libdispatch\n' \
        "$(hash_file "$RUNTIME/host/libdispatch.so")"
    printf 'local\thost/libBlocksRuntime.so\t%s\tpinned Swift 6.2.4 BlocksRuntime\n' \
        "$(hash_file "$RUNTIME/host/libBlocksRuntime.so")"
    printf 'local\thost/libOpenDispatchHost.so\t%s\tbuilt from full/dispatch/OpenDispatchHost.c\n' \
        "$(hash_file "$DISPATCH_HOST")"
} >> "$RUNTIME/.manifest"

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

echo '== build the portable Dispatch Swift module'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" \
    -module-name Dispatch -module-link-name Dispatch -emit-module \
    -emit-module-path "$STAGE/modules/Dispatch.swiftmodule" \
    -emit-object -o "$WORK/dispatch.o" "$W/full/dispatch/Dispatch.swift"

echo '== build the official Observation runtime and portable helper boundary'
OBSERVATION_SOURCE_PATHS=()
for relative in "${OBSERVATION_SOURCES[@]}"; do
    OBSERVATION_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library -suppress-warnings \
    -module-name Observation -module-link-name swiftObservation \
    -enable-library-evolution -enable-experimental-feature Macros \
    -enable-experimental-feature ExtensionMacros \
    -emit-module -emit-module-path "$STAGE/modules/Observation.swiftmodule" \
    -emit-module-interface-path "$STAGE/modules/Observation.swiftinterface" \
    -emit-object -o "$WORK/observation.o" "${OBSERVATION_SOURCE_PATHS[@]}"
clang-18 -target "$TARGET" -isysroot "$STAGE/sdk" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -c "$W/full/observation/ObservationRuntimeBridge.c" \
    -o "$WORK/observation-runtime-bridge.o"
OBSERVATION_DYLIB=$RUNTIME/darwin/usr/lib/swift/libswiftObservation.dylib
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name /usr/lib/swift/libswiftObservation.dylib \
    -o "$OBSERVATION_DYLIB" \
    "$WORK/observation.o" "$WORK/observation-runtime-bridge.o" \
    "$FULL/swiftcorepatch.o" \
    -L"$RUNTIME/darwin/usr/lib" -L"$STAGE/sdk/usr/lib/swift" \
    -lswiftCore -lswiftObjectiveC "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "$RUNTIME/darwin/usr/lib/libswiftcompat.dylib" \
    -L"$STAGE/sdk/usr/lib" -lSystem -lobjc \
    "$RUNTIME/darwin/usr/lib/libSystem.B.dylib"
[ "$(llvm-otool-18 -D "$OBSERVATION_DYLIB" | tail -n 1)" = \
    /usr/lib/swift/libswiftObservation.dylib ] \
    || die 'Observation runtime install name drifted'
llvm-otool-18 -hv "$OBSERVATION_DYLIB" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'Observation runtime is not an ARM64 Mach-O dylib'
if llvm-nm-18 --undefined-only --just-symbol-name "$OBSERVATION_DYLIB" \
    | grep -Eq '^__swift_observation_(lock|tls)_'; then
    die 'Observation runtime retained an unresolved lock/TLS primitive'
fi
observation_protocol_exports=$(llvm-nm-18 --defined-only --extern-only \
    --just-symbol-name "$OBSERVATION_DYLIB" \
    | awk 'index($0, "$s11Observation10ObservableMp") { count++ } \
        END { print count + 0 }')
observation_registrar_exports=$(llvm-nm-18 --defined-only --extern-only \
    --just-symbol-name "$OBSERVATION_DYLIB" \
    | awk 'index($0, "$s11Observation0A9RegistrarV") { count++ } \
        END { print count + 0 }')
[ "$observation_protocol_exports" -eq 1 ] \
    || die "Observation protocol export count $observation_protocol_exports, expected 1"
[ "$observation_registrar_exports" -ge 12 ] \
    || die "Observation registrar export count $observation_registrar_exports, expected at least 12"
printf 'local\tdarwin/usr/lib/swift/libswiftObservation.dylib\t%s\tbuilt from official Swift 6.2.4 Observation sources\n' \
    "$(hash_file "$OBSERVATION_DYLIB")" >> "$RUNTIME/.manifest"

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
    "${OBSERVATION_PLUGIN_FLAGS[@]}" \
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
foundation_darwin_undefineds=$(awk \
    'index($0, "6Darwin") { count++ } END { print count + 0 }' \
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
[ "$foundation_darwin_undefineds" -eq \
    "$EXPECTED_FOUNDATION_DARWIN_UNDEFINEDS" ] \
    || die "Foundation Darwin undefined count $foundation_darwin_undefineds, expected $EXPECTED_FOUNDATION_DARWIN_UNDEFINEDS"
printf 'Foundation facade direct undefineds: StringProcessing=%s Synchronization=%s RegexParser=%s Darwin=%s\n' \
    "$foundation_string_processing_undefineds" \
    "$foundation_synchronization_undefineds" \
    "$foundation_regex_parser_undefineds" \
    "$foundation_darwin_undefineds"

echo '== compile final Foundation-visible UIKit (optional Preview plugin explicit)'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    "${PREVIEW_FLAGS[@]}" -module-name UIKit -emit-module \
    -emit-module-path "$STAGE/modules/UIKit.swiftmodule" \
    -emit-object -o "$WORK/uikit.o" "$UIKIT/Sources/UIKitShim/UIKit.swift"

echo '== compile CoreImage overlay and identity-preserving QuartzCore facade'
COREIMAGE_SOURCE_PATHS=()
for relative in "${COREIMAGE_SOURCES[@]}"; do
    COREIMAGE_SOURCE_PATHS+=("$W/$relative")
done
QUARTZCORE_SOURCE_PATHS=()
for relative in "${QUARTZCORE_SOURCES[@]}"; do
    QUARTZCORE_SOURCE_PATHS+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name CoreImage -import-underlying-module -emit-module \
    -emit-module-path "$STAGE/modules/CoreImage.swiftmodule" \
    -emit-object -o "$WORK/coreimage.o" "${COREIMAGE_SOURCE_PATHS[@]}"
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name QuartzCore -emit-module \
    -emit-module-path "$STAGE/modules/QuartzCore.swiftmodule" \
    -emit-object -o "$WORK/quartzcore.o" "${QUARTZCORE_SOURCE_PATHS[@]}"

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

echo '== compile twelve independent first-party framework modules'
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

echo '== link twenty-six reusable core framework dylibs'
"${LD[@]}" -dylib -dead_strip -ignore_auto_link -undefined dynamic_lookup \
    -install_name @rpath/libDispatch.dylib -rpath @loader_path \
    -o "$STAGE/lib/libDispatch.dylib" \
    "$WORK/dispatch.o" "$DISPATCH_DARWIN" \
    "${COMMON_LINK[@]}" "$STAGE/sdk/usr/lib/swift/libswift_Concurrency.tbd"
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
    "${COMMON_LINK[@]}" -lFoundationEssentials -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}" "$URL_TRANSPORT_DARWIN" \
    "$RELATIVE_TIME_DARWIN"
foundation_graphics_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libFoundation.dylib" \
    | awk '$1 == "@rpath/libOpenCoreGraphics.dylib" { count++ } END { print count + 0 }')
[ "$foundation_graphics_load_count" -eq 1 ] \
    || die "libFoundation OpenCoreGraphics load count $foundation_graphics_load_count, expected 1"
for install_name in "${FOUNDATION_RUNTIME_INSTALL_NAMES[@]}"; do
    load_count=$(llvm-otool-18 -L "$STAGE/lib/libFoundation.dylib" \
        | awk -v expected="$install_name" '$1 == expected { count++ } END { print count + 0 }')
    [ "$load_count" -eq 1 ] \
        || die "libFoundation runtime load count $load_count for $install_name, expected 1"
done
foundation_transport_load_count=$(llvm-otool-18 -L "$STAGE/lib/libFoundation.dylib" \
    | awk '$1 == "/usr/lib/libOpenURLTransport.dylib" { count++ } END { print count + 0 }')
[ "$foundation_transport_load_count" -eq 1 ] \
    || die "libFoundation URL transport load count $foundation_transport_load_count, expected 1"
foundation_relative_time_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libFoundation.dylib" \
    | awk '$1 == "/usr/lib/libOpenRelativeTime.dylib" { count++ } END { print count + 0 }')
[ "$foundation_relative_time_load_count" -eq 1 ] \
    || die "libFoundation relative-time load count $foundation_relative_time_load_count, expected 1"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libSwiftUI.dylib -rpath @loader_path \
    -o "$STAGE/lib/libSwiftUI.dylib" "$WORK/swiftui.o" \
    "${COMMON_LINK[@]}" -lFoundationEssentials -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine \
    "$SWIFTUI_RUNTIME_LINK_FLAG" "$OBSERVATION_DYLIB" \
    "$FULL/swiftcorepatch.o"
swiftui_foundation_essentials_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libSwiftUI.dylib" \
    | awk '$1 == "@rpath/libFoundationEssentials.dylib" { count++ } \
        END { print count + 0 }')
[ "$swiftui_foundation_essentials_load_count" -eq 1 ] \
    || die "libSwiftUI FoundationEssentials load count $swiftui_foundation_essentials_load_count, expected 1"
swiftui_runtime_load_count=$(llvm-otool-18 -L "$STAGE/lib/libSwiftUI.dylib" \
    | awk -v expected="$SWIFTUI_RUNTIME_INSTALL_NAME" \
        '$1 == expected { count++ } END { print count + 0 }')
[ "$swiftui_runtime_load_count" -eq 1 ] \
    || die "libSwiftUI runtime load count $swiftui_runtime_load_count for $SWIFTUI_RUNTIME_INSTALL_NAME, expected 1"
swiftui_observation_load_count=$(llvm-otool-18 -L "$STAGE/lib/libSwiftUI.dylib" \
    | awk '$1 == "/usr/lib/swift/libswiftObservation.dylib" { count++ } \
        END { print count + 0 }')
[ "$swiftui_observation_load_count" -eq 1 ] \
    || die "libSwiftUI Observation load count $swiftui_observation_load_count, expected 1"
UIKIT_UNDEFINED_FLAGS=()
[ "$PREVIEW_ENABLED" -eq 0 ] || UIKIT_UNDEFINED_FLAGS=(-undefined dynamic_lookup)
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libUIKit.dylib -rpath @loader_path \
    "${UIKIT_UNDEFINED_FLAGS[@]}" \
    -o "$STAGE/lib/libUIKit.dylib" "$WORK/uikit.o" \
    "${COMMON_LINK[@]}" -lFoundation -lFoundationEssentials \
    -lOpenUIKit -lOpenCoreGraphics

"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libCoreImage.dylib -rpath @loader_path \
    -o "$STAGE/lib/libCoreImage.dylib" "$WORK/coreimage.o" \
    "${COMMON_LINK[@]}" -lOpenCoreGraphics
"${LD[@]}" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libQuartzCore.dylib -rpath @loader_path \
    -o "$STAGE/lib/libQuartzCore.dylib" "$WORK/quartzcore.o" \
    "${COMMON_LINK[@]}" -lOpenUIKit -lOpenCoreGraphics
coreimage_graphics_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libCoreImage.dylib" \
    | awk '$1 == "@rpath/libOpenCoreGraphics.dylib" { count++ } END { print count + 0 }')
quartzcore_uikit_load_count=$(llvm-otool-18 -L \
    "$STAGE/lib/libQuartzCore.dylib" \
    | awk '$1 == "@rpath/libOpenUIKit.dylib" { count++ } END { print count + 0 }')
[ "$coreimage_graphics_load_count" -eq 1 ] \
    || die "libCoreImage OpenCoreGraphics load count $coreimage_graphics_load_count, expected 1"
[ "$quartzcore_uikit_load_count" -eq 1 ] \
    || die "libQuartzCore OpenUIKit load count $quartzcore_uikit_load_count, expected 1"
for framework in CoreImage QuartzCore; do
    if llvm-otool-18 -L "$STAGE/lib/lib$framework.dylib" \
        | grep -Fq "/System/Library/Frameworks/$framework.framework/"; then
        die "lib$framework loads the Apple $framework framework"
    fi
done

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
        SafariServices|StoreKit|PassKit|MessageUI)
            expected_uikit_load=1
            framework_link_dependencies+=(
                -lUIKit
                -lOpenUIKit
                -lOpenCoreGraphics
            )
            ;;
        CoreGraphics)
            framework_link_dependencies+=(
                -lOpenCoreGraphics
            )
            ;;
        ImageIO)
            framework_link_dependencies+=(
                -lCoreGraphics
                -lOpenCoreGraphics
                "$RUNTIME/darwin/usr/lib/libquartz.dylib"
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
    "${OBSERVATION_PLUGIN_FLAGS[@]}" "${PREVIEW_FLAGS[@]}" \
    -module-name CoreGuestPackageProbe \
    -emit-object -o "$WORK/core-probe.o" \
    "$W/full/frameworks/CoreGuestPackageProbe.swift" \
    "$W/full/frameworks/FoundationHackersCompatibilityProbe.swift" \
    "$W/full/observation/tests/ObservationGuestRuntimeProbe.swift"
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
    -lWebKit -lIntentsUI -lIntents -lCoreImage -lQuartzCore -lDispatch \
    -lUIKit -lFoundation -lFoundationEssentials -lSwiftUI \
    -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine \
    -lLocalAuthentication -lSafariServices -lNetwork -lStoreKit \
    -lAudioToolbox -lCoreHaptics -lPassKit -lCoreGraphics -lImageIO \
    -lLinkPresentation -lMessageUI -lMobileCoreServices \
    "$SWIFTUI_RUNTIME_LINK_FLAG" \
    "$OBSERVATION_DYLIB"

for dylib in FoundationEssentials OpenCoreGraphics OpenUIKit OpenCombine \
    Dispatch \
    Combine SwiftUI Foundation UIKit CoreImage QuartzCore Intents IntentsUI WebKit \
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
probe_observation_load_count=$(llvm-otool-18 -L \
    "$STAGE/probe/CoreGuestPackageProbe" \
    | awk '$1 == "/usr/lib/swift/libswiftObservation.dylib" { count++ } \
        END { print count + 0 }')
[ "$probe_observation_load_count" -eq 1 ] \
    || die "core probe Observation load count $probe_observation_load_count, expected 1"

perl "$W/full/swiftui/focus_widget_guest_attest.pl" closure \
    --otool llvm-otool-18 --executable "$STAGE/probe/CoreGuestPackageProbe" \
    --package "$STAGE" --guest-root "$STAGE/guest-root" \
    > "$STAGE/attestation/runtime-closure.tsv"
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$DISPATCH_HOST:$URL_TRANSPORT_HOST:$RELATIVE_TIME_HOST${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$STAGE/guest-root" \
        "$STAGE/guest-root/machorun" ./probe/CoreGuestPackageProbe \
        "$STAGE/resources/OpenUIKit" \
        "$STAGE/resources/OpenUIKit/fonts/DejaVuSans.ttf" \
        "$STAGE/resources/OpenUIKit/fonts/DejaVuSans-Bold.ttf"
) | tee "$STAGE/attestation/runtime.log"
grep -Fq 'CORE_GUEST_PACKAGE_MACHO_OK notification=shared combine=delivered resources=loaded fonts=system,bold intents=donated shortcuts=stored foundation=locks,filehandle,characters,strings,ranges,attributed,objc,number-bridge,data-search,cfurl,reexports data-platform=lock,kvs,relative-time-icu,filesystem,storekit-model observation=macro,reexport,registrar,tracking,ignored,one-shot graphics=coreimage,quartzcore intentsui=host-driven swiftui-app=constructed first-party=portable-12 webkit=engine-unavailable preview=' \
    "$STAGE/attestation/runtime.log" || die 'core package runtime marker is missing'

echo '== compile/link/run the real Dispatch and Swift-concurrency Mach-O gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name DispatchMachORuntime -emit-object \
    -o "$WORK/dispatch-macho-runtime.o" \
    "$W/full/dispatch/tests/DispatchMachORuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/DispatchMachORuntime" \
    "$WORK/dispatch-macho-runtime.o" "${COMMON_LINK[@]}" \
    -lDispatch -lFoundation -lFoundationEssentials -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/DispatchMachORuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'Dispatch runtime gate is not an ARM64 Mach-O executable'
(
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$DISPATCH_HOST:$URL_TRANSPORT_HOST${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/DispatchMachORuntime
) | tee "$STAGE/attestation/dispatch-runtime.log"
grep -Fx \
    'OPEN_DISPATCH_MACHO_OK async-main=drained taskgroup=8 detached=42 global=17 main=23 after=29 vouchers=null' \
    "$STAGE/attestation/dispatch-runtime.log" >/dev/null \
    || die 'real Dispatch/Swift-concurrency Mach-O runtime marker is missing'

echo '== compile/link/run the full async Foundation URLSession cold gate'
"${SWIFTC[@]}" -parse-as-library "${C_FLAGS[@]}" "${FE_FLAGS[@]}" \
    -module-name FoundationURLSessionRuntime -emit-object \
    -o "$WORK/foundation-urlsession-runtime.o" \
    "$W/full/foundation/tests/FoundationURLSessionRuntime.swift"
"${LD[@]}" -dead_strip -ignore_auto_link \
    -exported_symbol __mh_execute_header -rpath @loader_path/../lib \
    -o "$STAGE/probe/FoundationURLSessionRuntime" \
    "$WORK/foundation-urlsession-runtime.o" "${COMMON_LINK[@]}" \
    -lDispatch -lFoundation -lFoundationEssentials -lOpenUIKit \
    -lOpenCoreGraphics -lCombine -lOpenCombine \
    "${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"
llvm-otool-18 -hv "$STAGE/probe/FoundationURLSessionRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'Foundation URLSession runtime gate is not an ARM64 Mach-O executable'
(
    set -e
    server_port_file=$WORK/foundation-urlsession-runtime.port
    server_log=$WORK/foundation-urlsession-server.log
    python3 -B "$W/full/foundation/tests/url_session_test_server.py" \
        --port-file "$server_port_file" >"$server_log" 2>&1 &
    server_pid=$!
    trap 'kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true' EXIT
    for _ in $(seq 1 200); do
        [ ! -s "$server_port_file" ] || break
        sleep 0.01
    done
    [ -s "$server_port_file" ] \
        || die 'Foundation URLSession test server did not publish its port'
    server_port=$(tr -d '[:space:]' < "$server_port_file")
    cd "$STAGE"
    LD_LIBRARY_PATH="$RUNTIME/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$DISPATCH_HOST:$URL_TRANSPORT_HOST${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/FoundationURLSessionRuntime \
        "http://127.0.0.1:$server_port"
) | tee "$STAGE/attestation/foundation-urlsession-runtime.log"
grep -Fx \
    'FOUNDATION_URLSESSION_MACHO_OK delegate=retained configuration=isolated cookies=host-domain-path-expiry-delete redirect=set-cookie-post-get status500=response final-url=preserved concurrency=parallel input-stream=bounded urlprotocol=intercepted-cache-hit-redirect-refused timeouts=configuration-request https=not-requested' \
    "$STAGE/attestation/foundation-urlsession-runtime.log" >/dev/null \
    || die 'full async Foundation URLSession Mach-O runtime marker is missing'

echo '== write relocatable compile/link contracts'
COMPILE_ARGUMENTS=(
    -target "$TARGET" -sdk sdk -runtime-compatibility-version none
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xfrontend -disable-objc-attr-requires-foundation-module
    -load-plugin-library host-tools/swift/host/plugins/libObservationMacros.so
    -I modules
    -Xcc -Iinclude/CPortableIO
    -Xcc -Iinclude/CSTBTrueType
    -Xcc -Iinclude/CHostClock
    -Xcc -Iinclude/COpenCombineHelpers
    -Xcc -Iinclude/CQuartz
    -Xcc -fmodule-map-file=include/CoreImage/module.modulemap
    -Xcc -Iinclude/CoreImage
    -Xcc -fmodule-map-file=include/COpenURLTransport/module.modulemap
    -Xcc -Iinclude/COpenURLTransport
    -Xcc -fmodule-map-file=include/COpenRelativeTime/module.modulemap
    -Xcc -Iinclude/COpenRelativeTime
    -Xcc -fmodule-map-file=include/COpenDispatch/module.modulemap
    -Xcc -Iinclude/COpenDispatch
    -Xcc -fmodule-map-file=include/_FoundationCShims/module.modulemap
    -Xcc -Iinclude/_FoundationCShims
)
LINK_ARGUMENTS=(
    -arch arm64 -platform_version macos "$MIN_OS" "$MIN_OS" -syslibroot sdk
    -Llib -Lguest-root/darwin/usr/lib -Lsdk/usr/lib/swift
    -lswiftCore -lswiftObjectiveC "${SWIFTUI_RUNTIME_LINK_FLAG}"
    guest-root/darwin/usr/lib/swift/libswiftObservation.dylib
    guest-root/darwin/usr/lib/libswiftcompat.dylib
    -Lsdk/usr/lib -lSystem -lobjc
    guest-root/darwin/usr/lib/libquartz.dylib
    guest-root/darwin/usr/lib/libSystem.B.dylib
    -lWebKit -lCoreImage -lQuartzCore -lDispatch -lUIKit -lFoundation -lFoundationEssentials -lSwiftUI
    -lIntentsUI -lIntents -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine
    -lLocalAuthentication -lSafariServices -lNetwork -lStoreKit
    -lAudioToolbox -lCoreHaptics -lPassKit -lCoreGraphics -lImageIO
    -lLinkPresentation -lMessageUI -lMobileCoreServices
)
printf '%s\0' "${COMPILE_ARGUMENTS[@]}" > "$STAGE/compile-flags.rsp"
printf '%s\0' "${LINK_ARGUMENTS[@]}" > "$STAGE/link-inputs.rsp"

if [ "$PREVIEW_ENABLED" -eq 1 ]; then
    printf '%s\0' -load-plugin-executable \
        '${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros' -j1 \
        > "$STAGE/preview-plugin-load-flag.rsp"
    {
        printf 'format\tcore-preview-input-v2\n'
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
        printf 'plugin-driver-job-count\t1\n'
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
cp "$WORK/observation-sources.pre.tsv" \
    "$STAGE/attestation/observation-sources.tsv"
cp "$WORK/intents-sources.pre.tsv" "$STAGE/attestation/intents-sources.tsv"
cp "$WORK/graphics-sources.pre.tsv" "$STAGE/attestation/graphics-sources.tsv"
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
    printf 'Observation\tupstream=%s\tsources=%s\tplugin=%s\ttoolchain=%s\n' \
        "$EXPECTED_OBSERVATION_UPSTREAM_COMMIT" \
        "$(hash_file "$OBSERVATION_SOURCES_MANIFEST")" \
        "$EXPECTED_OBSERVATION_PLUGIN_SHA" "$OBSERVATION_TOOLCHAIN"
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
    printf 'url-transport\theader=%s\tbridge=%s\thost=%s\thost-tests=%s\n' \
        "$(hash_file "$W/full/urltransport/include/OpenURLTransportABI.h")" \
        "$(hash_file "$W/full/urltransport/OpenURLTransportBridge.c")" \
        "$(hash_file "$W/full/urltransport/OpenURLTransportHost.c")" \
        "$(hash_file "$W/full/urltransport/OpenURLTransportHostTests.c")"
    printf 'frontier-frameworks\tframeworks=5\tsources=5\n'
    printf 'relative-time\theader=%s\tbridge=%s\thost=%s\thost-tests=%s\n' \
        "$(hash_file "$W/full/relativetime/include/OpenRelativeTimeABI.h")" \
        "$(hash_file "$W/full/relativetime/OpenRelativeTimeBridge.c")" \
        "$(hash_file "$W/full/relativetime/OpenRelativeTimeHost.c")" \
        "$(hash_file "$W/full/relativetime/OpenRelativeTimeHostTests.c")"
    printf 'dispatch\theader=%s\tmodule-map=%s\tbridge=%s\thost=%s\thost-tests=%s\tswift=%s\truntime-gate=%s\n' \
        "$(hash_file "$W/full/dispatch/include/OpenDispatchABI.h")" \
        "$(hash_file "$W/full/dispatch/include/module.modulemap")" \
        "$(hash_file "$W/full/dispatch/OpenDispatchBridge.c")" \
        "$(hash_file "$W/full/dispatch/OpenDispatchHost.c")" \
        "$(hash_file "$W/full/dispatch/OpenDispatchHostTests.c")" \
        "$(hash_file "$W/full/dispatch/Dispatch.swift")" \
        "$(hash_file "$W/full/dispatch/tests/DispatchMachORuntime.swift")"
    printf 'dispatch-host-runtime\tlibdispatch=%s\tlibBlocksRuntime=%s\tglibc-minimum=2.38\n' \
        "$EXPECTED_HOST_DISPATCH_SHA256" \
        "$EXPECTED_HOST_BLOCKS_RUNTIME_SHA256"
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
    Dispatch \
    Combine SwiftUI Foundation UIKit CoreImage QuartzCore Intents IntentsUI WebKit \
    "${FIRST_PARTY_FRAMEWORKS[@]}"; do
    record_module_family framework "$framework"
    record_artifact framework "$framework" dylib "lib/lib$framework.dylib"
done
record_module_family framework Observation
record_artifact runtime Observation dylib \
    guest-root/darwin/usr/lib/swift/libswiftObservation.dylib
record_artifact host-tool ObservationMacros plugin \
    host-tools/swift/host/plugins/libObservationMacros.so
for library in "${OBSERVATION_PLUGIN_HOST_LIBS[@]}"; do
    record_artifact host-tool ObservationMacros dependency \
        "host-tools/swift/host/$library"
done
for library in "${OBSERVATION_PLUGIN_LINUX_LIBS[@]}"; do
    record_artifact host-tool ObservationMacros dependency \
        "host-tools/swift/linux/$library"
done
record_artifact include CoreImage umbrella-header include/CoreImage/CoreImage.h
record_artifact include CoreImage submodule-header \
    include/CoreImage/CIFilterBuiltins.h
record_artifact include CoreImage module-map include/CoreImage/module.modulemap
record_artifact include COpenDispatch abi-header \
    include/COpenDispatch/OpenDispatchABI.h
record_artifact include COpenDispatch module-map \
    include/COpenDispatch/module.modulemap
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
record_artifact runtime OpenURLTransport darwin-bridge \
    guest-root/darwin/usr/lib/libOpenURLTransport.dylib
record_artifact runtime OpenURLTransport linux-helper \
    guest-root/host/libOpenURLTransportHost.so
record_artifact runtime OpenRelativeTime darwin-bridge \
    guest-root/darwin/usr/lib/libOpenRelativeTime.dylib
record_artifact runtime OpenRelativeTime linux-helper \
    guest-root/host/libOpenRelativeTimeHost.so
record_artifact runtime OpenDispatch linux-helper \
    guest-root/host/libOpenDispatchHost.so
record_artifact runtime OpenDispatch darwin-bridge \
    guest-root/darwin/usr/lib/libOpenDispatch.dylib
record_artifact runtime OpenDispatch linux-libdispatch \
    guest-root/host/libdispatch.so
record_artifact runtime OpenDispatch linux-blocks-runtime \
    guest-root/host/libBlocksRuntime.so
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
record_artifact probe DispatchMachORuntime executable \
    probe/DispatchMachORuntime
record_artifact probe FoundationURLSessionRuntime executable \
    probe/FoundationURLSessionRuntime
record_artifact attestation runtime runtime-log attestation/runtime.log
record_artifact attestation dispatch host \
    attestation/open-dispatch-host.tsv
record_artifact attestation dispatch host-test-log \
    attestation/open-dispatch-host-test.log
record_artifact attestation dispatch runtime-log \
    attestation/dispatch-runtime.log
record_artifact attestation foundation-urlsession runtime-log \
    attestation/foundation-urlsession-runtime.log
record_artifact attestation contracts compile-rsp compile-flags.rsp
record_artifact attestation contracts link-rsp link-inputs.rsp
record_artifact attestation source-sets manifest attestation/source-sets.tsv
record_artifact attestation foundation-sources manifest \
    attestation/foundation-sources.tsv
record_artifact attestation observation-sources manifest \
    attestation/observation-sources.tsv
record_artifact attestation observation-macro-plugin closure \
    attestation/observation-macro-plugin.tsv
record_artifact attestation intents-sources manifest \
    attestation/intents-sources.tsv
record_artifact attestation graphics-sources manifest \
    attestation/graphics-sources.tsv
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
record_artifact attestation url-transport abi \
    attestation/url-transport-abi.tsv
record_artifact attestation url-transport host \
    attestation/url-transport-host.tsv
record_artifact attestation relative-time abi \
    attestation/relative-time-abi.tsv
record_artifact attestation relative-time host \
    attestation/relative-time-host.tsv
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
write_observation_sources_attestation "$WORK/observation-sources.post.tsv"
cmp "$WORK/observation-sources.pre.tsv" "$WORK/observation-sources.post.tsv" \
    || die 'Observation source manifest/files changed during build'
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

write_graphics_sources_attestation "$WORK/graphics-sources.post.tsv"
cmp "$WORK/graphics-sources.pre.tsv" "$WORK/graphics-sources.post.tsv" \
    || die 'CoreImage/QuartzCore source manifests/files changed during build'

python3 -B "$FIRST_PARTY_PROVENANCE_TOOL" production \
    --support-root "$W" --policy "$FIRST_PARTY_PROVENANCE_POLICY" \
    --output "$WORK/first-party-sources.post.tsv"
append_frontier_sources "$WORK/first-party-sources.post.tsv"
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
require_hash "$OBSERVATION_MACRO_PLUGIN" "$EXPECTED_OBSERVATION_PLUGIN_SHA" \
    post-Observation-macro-plugin
for index in "${!OBSERVATION_PLUGIN_HOST_LIBS[@]}"; do
    library=${OBSERVATION_PLUGIN_HOST_LIBS[$index]}
    require_hash "/usr/lib/swift/host/$library" \
        "${OBSERVATION_PLUGIN_HOST_HASHES[$index]}" \
        "post-Observation-plugin-host-$library"
done
for index in "${!OBSERVATION_PLUGIN_LINUX_LIBS[@]}"; do
    library=${OBSERVATION_PLUGIN_LINUX_LIBS[$index]}
    require_hash "/usr/lib/swift/linux/$library" \
        "${OBSERVATION_PLUGIN_LINUX_HASHES[$index]}" \
        "post-Observation-plugin-linux-$library"
done
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
    --graphics-sources attestation/graphics-sources.tsv
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
