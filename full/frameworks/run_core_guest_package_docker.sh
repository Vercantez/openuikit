#!/usr/bin/env bash
# Host-side cold replay wrapper. Every input is physically staged below one
# fresh host directory, Docker receives exactly one RW bind, and publication is
# gated on byte-identical pre/post input manifests plus both package validators.

set -euo pipefail
export GIT_OPTIONAL_LOCKS=0
export PYTHONDONTWRITEBYTECODE=1

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
PHYSICAL_REPLAY_TOOL=$SCRIPT_DIR/physical_replay.py

SUPPORT_CHECKOUT=''
EXPECTED_SUPPORT_COMMIT=''
EXPECTED_SUPPORT_TREE=''
STAGED_INPUT_ROOT=''
UIKIT_CHECKOUT=''
EXPECTED_UIKIT_COMMIT=''
EXPECTED_UIKIT_TREE=''
MACHORUN_CHECKOUT=''
EXPECTED_MACHORUN_COMMIT=''
EXPECTED_MACHORUN_TREE=''
EXPECTED_MACHORUN_LOADER_SHA256=''
OUTPUT_ROOT=''
DEVELOPER_TOOLS_SUPPORT_MODULE=''
DEVELOPER_TOOLS_SUPPORT_OBJECT=''
PREVIEW_MACRO_PLUGIN=''
CONTAINER_IMAGE=''

usage() {
    cat <<'EOF'
usage: run_core_guest_package_docker.sh \
  --container-image SHA256_IMAGE_ID \
  --support-checkout PATH --expected-support-commit HASH \
  --expected-support-tree HASH --staged-input-root PATH \
  --uikit-checkout PATH --expected-uikit-commit HASH \
  --expected-uikit-tree HASH --machorun-checkout PATH \
  --expected-machorun-commit HASH --expected-machorun-tree HASH \
  --expected-machorun-loader-sha256 HASH \
  --output-root NEW_ABSOLUTE_PATH [Preview trio]

Preview is all-or-none:
  --developer-tools-support-module PATH
  --developer-tools-support-object PATH
  --preview-macro-plugin PATH

The staged input root must contain these immutable prepared inputs:
  sysroot_fe4/  mrroot/  mrroot_fe/  swift-foundation/  swift-foundation-icu/
  swift-collections/  opencombine-core-durable-20260828-r2/

The wrapper never reuses a build product. It creates fresh physical copies of
every input beneath one replay root, gives Docker only that one RW host bind,
and keeps build, module caches, and the working guest root in fresh directories
inside it. Only /tmp is tmpfs; no mount is nested below /replay. The container
has no network and a read-only root filesystem. Copied inputs are
content-verified rather than mount-enforced read-only: an exact
type/mode/symlink/content manifest is compared after all validation and before
the package is atomically published.
EOF
}

die() {
    echo "core_guest_package_host: REFUSING -- $*" >&2
    exit 2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --support-checkout) SUPPORT_CHECKOUT=${2-}; shift 2 ;;
        --container-image) CONTAINER_IMAGE=${2-}; shift 2 ;;
        --expected-support-commit) EXPECTED_SUPPORT_COMMIT=${2-}; shift 2 ;;
        --expected-support-tree) EXPECTED_SUPPORT_TREE=${2-}; shift 2 ;;
        --staged-input-root) STAGED_INPUT_ROOT=${2-}; shift 2 ;;
        --uikit-checkout) UIKIT_CHECKOUT=${2-}; shift 2 ;;
        --expected-uikit-commit) EXPECTED_UIKIT_COMMIT=${2-}; shift 2 ;;
        --expected-uikit-tree) EXPECTED_UIKIT_TREE=${2-}; shift 2 ;;
        --machorun-checkout) MACHORUN_CHECKOUT=${2-}; shift 2 ;;
        --expected-machorun-commit) EXPECTED_MACHORUN_COMMIT=${2-}; shift 2 ;;
        --expected-machorun-tree) EXPECTED_MACHORUN_TREE=${2-}; shift 2 ;;
        --expected-machorun-loader-sha256)
            EXPECTED_MACHORUN_LOADER_SHA256=${2-}; shift 2 ;;
        --output-root) OUTPUT_ROOT=${2-}; shift 2 ;;
        --developer-tools-support-module)
            DEVELOPER_TOOLS_SUPPORT_MODULE=${2-}; shift 2 ;;
        --developer-tools-support-object)
            DEVELOPER_TOOLS_SUPPORT_OBJECT=${2-}; shift 2 ;;
        --preview-macro-plugin) PREVIEW_MACRO_PLUGIN=${2-}; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done

for assignment in \
    "container image:$CONTAINER_IMAGE" \
    "support checkout:$SUPPORT_CHECKOUT" \
    "expected support commit:$EXPECTED_SUPPORT_COMMIT" \
    "expected support tree:$EXPECTED_SUPPORT_TREE" \
    "staged input root:$STAGED_INPUT_ROOT" \
    "UIKit checkout:$UIKIT_CHECKOUT" \
    "expected UIKit commit:$EXPECTED_UIKIT_COMMIT" \
    "expected UIKit tree:$EXPECTED_UIKIT_TREE" \
    "machorun checkout:$MACHORUN_CHECKOUT" \
    "expected machorun commit:$EXPECTED_MACHORUN_COMMIT" \
    "expected machorun tree:$EXPECTED_MACHORUN_TREE" \
    "expected machorun loader SHA-256:$EXPECTED_MACHORUN_LOADER_SHA256" \
    "output root:$OUTPUT_ROOT"; do
    label=${assignment%%:*}
    value=${assignment#*:}
    [ -n "$value" ] || die "$label is required"
done

for path in "$SUPPORT_CHECKOUT" "$STAGED_INPUT_ROOT" \
    "$UIKIT_CHECKOUT" "$MACHORUN_CHECKOUT" "$OUTPUT_ROOT"; do
    case "$path" in /*) ;; *) die "path must be absolute: $path" ;; esac
done
for expected in "$EXPECTED_SUPPORT_COMMIT" "$EXPECTED_SUPPORT_TREE" \
    "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE" \
    "$EXPECTED_MACHORUN_COMMIT" "$EXPECTED_MACHORUN_TREE"; do
    [ "${#expected}" -eq 40 ] || die "Git ID must be lowercase 40-hex: $expected"
    case "$expected" in *[!0-9a-f]*) die "Git ID must be lowercase 40-hex: $expected" ;; esac
done
[ "${#EXPECTED_MACHORUN_LOADER_SHA256}" -eq 64 ] \
    || die 'machorun loader SHA-256 must be lowercase 64-hex'
case "$EXPECTED_MACHORUN_LOADER_SHA256" in
    *[!0-9a-f]*) die 'machorun loader SHA-256 must be lowercase 64-hex' ;;
esac

for tool in docker git mktemp python3 tee awk shasum; do
    command -v "$tool" >/dev/null || die "required host tool is missing: $tool"
done
[ -f "$PHYSICAL_REPLAY_TOOL" ] && [ ! -L "$PHYSICAL_REPLAY_TOOL" ] \
    || die "physical replay helper is missing or linked: $PHYSICAL_REPLAY_TOOL"
[ "${#CONTAINER_IMAGE}" -eq 71 ] \
    || die "container image must be an exact sha256 content ID"
case "$CONTAINER_IMAGE" in
    sha256:*[!0-9a-f]*|*[!0-9a-f])
        die "container image must be an exact lowercase sha256 content ID" ;;
    sha256:*) ;;
    *) die "container image must be an exact sha256 content ID" ;;
esac
ACTUAL_IMAGE_ID=$(docker image inspect --format '{{.Id}}' \
    "$CONTAINER_IMAGE" 2>/dev/null) \
    || die "container image is unavailable: $CONTAINER_IMAGE"
[ "$ACTUAL_IMAGE_ID" = "$CONTAINER_IMAGE" ] \
    || die "container image identity differs: $ACTUAL_IMAGE_ID"
IMAGE_PLATFORM=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' \
    "$CONTAINER_IMAGE")
[ "$IMAGE_PLATFORM" = linux/arm64 ] \
    || die "container image platform is $IMAGE_PLATFORM, expected linux/arm64"
for checkout in "$SUPPORT_CHECKOUT" "$UIKIT_CHECKOUT" "$MACHORUN_CHECKOUT"; do
    [ -d "$checkout" ] && [ ! -L "$checkout" ] \
        || die "checkout is not a real directory: $checkout"
done
[ ! -e "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ] \
    || die "output root already exists: $OUTPUT_ROOT"
OUTPUT_PARENT=$(dirname "$OUTPUT_ROOT")
[ -d "$OUTPUT_PARENT" ] && [ ! -L "$OUTPUT_PARENT" ] \
    || die "output parent is not a real directory: $OUTPUT_PARENT"

assert_checkout() {
    local checkout=$1 commit=$2 tree=$3 label=$4
    local actual_commit actual_tree status
    actual_commit=$(git -C "$checkout" rev-parse --verify HEAD^{commit})
    actual_tree=$(git -C "$checkout" rev-parse --verify HEAD^{tree})
    status=$(git -C "$checkout" status --porcelain=v1 --untracked-files=all)
    [ "$actual_commit" = "$commit" ] \
        || die "$label commit $actual_commit, expected $commit"
    [ "$actual_tree" = "$tree" ] \
        || die "$label tree $actual_tree, expected $tree"
    [ -z "$status" ] || die "$label checkout is dirty: $status"
}
assert_checkout "$SUPPORT_CHECKOUT" "$EXPECTED_SUPPORT_COMMIT" \
    "$EXPECTED_SUPPORT_TREE" support
assert_checkout "$UIKIT_CHECKOUT" "$EXPECTED_UIKIT_COMMIT" \
    "$EXPECTED_UIKIT_TREE" OpenUIKit
assert_checkout "$MACHORUN_CHECKOUT" "$EXPECTED_MACHORUN_COMMIT" \
    "$EXPECTED_MACHORUN_TREE" machorun

MACHORUN_LOADER=$MACHORUN_CHECKOUT/build/machorun
[ -f "$MACHORUN_LOADER" ] && [ ! -L "$MACHORUN_LOADER" ] \
    && [ -x "$MACHORUN_LOADER" ] \
    || die "machorun loader is not an executable regular file: $MACHORUN_LOADER"
ACTUAL_MACHORUN_LOADER_SHA256=$(shasum -a 256 "$MACHORUN_LOADER" | awk '{print $1}')
[ "$ACTUAL_MACHORUN_LOADER_SHA256" = "$EXPECTED_MACHORUN_LOADER_SHA256" ] \
    || die "machorun loader SHA-256 $ACTUAL_MACHORUN_LOADER_SHA256, expected $EXPECTED_MACHORUN_LOADER_SHA256"
MACHORUN_RUNTIME=$MACHORUN_CHECKOUT/darwin/usr
[ -d "$MACHORUN_RUNTIME" ] && [ ! -L "$MACHORUN_RUNTIME" ] \
    || die "machorun runtime is not a real directory: $MACHORUN_RUNTIME"
[ -f "$MACHORUN_RUNTIME/lib/libSystem.B.dylib" ] \
    && [ ! -L "$MACHORUN_RUNTIME/lib/libSystem.B.dylib" ] \
    || die 'machorun runtime is missing libSystem.B.dylib'

STAGED_INPUTS=(
    sysroot_fe4
    mrroot
    mrroot_fe
    swift-foundation
    swift-foundation-icu
    swift-collections
    opencombine-core-durable-20260828-r2
)
for relative in "${STAGED_INPUTS[@]}"; do
    input=$STAGED_INPUT_ROOT/$relative
    [ -d "$input" ] && [ ! -L "$input" ] \
        || die "missing staged input directory: $input"
done

preview_count=0
[ -n "$DEVELOPER_TOOLS_SUPPORT_MODULE" ] && preview_count=$((preview_count + 1))
[ -n "$DEVELOPER_TOOLS_SUPPORT_OBJECT" ] && preview_count=$((preview_count + 1))
[ -n "$PREVIEW_MACRO_PLUGIN" ] && preview_count=$((preview_count + 1))
[ "$preview_count" -eq 0 ] || [ "$preview_count" -eq 3 ] \
    || die 'Preview inputs are all-or-none'
if [ "$preview_count" -eq 3 ]; then
    for input in "$DEVELOPER_TOOLS_SUPPORT_MODULE" \
        "$DEVELOPER_TOOLS_SUPPORT_OBJECT" "$PREVIEW_MACRO_PLUGIN"; do
        [ -f "$input" ] && [ ! -L "$input" ] \
            || die "Preview input is not a regular non-symlink file: $input"
    done
fi

RUN_ROOT=$(mktemp -d "$OUTPUT_PARENT/.core-guest-run.XXXXXX")
REPLAY_ROOT=$RUN_ROOT/replay
EVIDENCE=$RUN_ROOT/evidence
RUN_SUCCESS=0
quarantine_run() {
    local status=$?
    trap - EXIT
    if [ "$RUN_SUCCESS" -ne 1 ]; then
        if [ -d "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ]; then
            output_invalid=${OUTPUT_ROOT}.INVALID-DO-NOT-USE
            [ ! -e "$output_invalid" ] \
                || output_invalid=${output_invalid}.$(date -u +%Y%m%dT%H%M%SZ)
            mv -- "$OUTPUT_ROOT" "$output_invalid"
            echo "core_guest_package_host: quarantined partial output at $output_invalid" >&2
        fi
        if [ -d "$RUN_ROOT" ]; then
            invalid=${RUN_ROOT}.INVALID-DO-NOT-USE
            [ ! -e "$invalid" ] || invalid=${invalid}.$(date -u +%Y%m%dT%H%M%SZ)
            mv -- "$RUN_ROOT" "$invalid"
            echo "core_guest_package_host: quarantined failed run at $invalid" >&2
        fi
    fi
    exit "$status"
}
trap quarantine_run EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p "$REPLAY_ROOT" "$EVIDENCE"
git clone --no-hardlinks --no-local --quiet "$SUPPORT_CHECKOUT" "$REPLAY_ROOT/w"
git clone --no-hardlinks --no-local --quiet "$UIKIT_CHECKOUT" "$REPLAY_ROOT/uikit"
git clone --no-hardlinks --no-local --quiet "$MACHORUN_CHECKOUT" "$REPLAY_ROOT/machorun"
assert_checkout "$REPLAY_ROOT/w" "$EXPECTED_SUPPORT_COMMIT" \
    "$EXPECTED_SUPPORT_TREE" cloned-support
assert_checkout "$REPLAY_ROOT/uikit" "$EXPECTED_UIKIT_COMMIT" \
    "$EXPECTED_UIKIT_TREE" cloned-OpenUIKit
assert_checkout "$REPLAY_ROOT/machorun" "$EXPECTED_MACHORUN_COMMIT" \
    "$EXPECTED_MACHORUN_TREE" cloned-machorun
for copy in support OpenUIKit machorun; do
    case "$copy" in
        support) source_checkout=$SUPPORT_CHECKOUT; copied_checkout=$REPLAY_ROOT/w ;;
        OpenUIKit) source_checkout=$UIKIT_CHECKOUT; copied_checkout=$REPLAY_ROOT/uikit ;;
        machorun) source_checkout=$MACHORUN_CHECKOUT; copied_checkout=$REPLAY_ROOT/machorun ;;
    esac
    python3 -B "$PHYSICAL_REPLAY_TOOL" prove-git-copy \
        --source "$source_checkout" --destination "$copied_checkout" \
        --label "$copy" --output "$EVIDENCE/copy-$copy.json"
done

mkdir -p "$REPLAY_ROOT/machorun/build" "$REPLAY_ROOT/machorun/darwin"
python3 -B "$PHYSICAL_REPLAY_TOOL" copy-file \
    --source "$MACHORUN_LOADER" \
    --destination "$REPLAY_ROOT/machorun/build/machorun" \
    --label machorun-loader --output "$EVIDENCE/copy-machorun-loader.json"
python3 -B "$PHYSICAL_REPLAY_TOOL" copy-tree \
    --source "$MACHORUN_RUNTIME" \
    --destination "$REPLAY_ROOT/machorun/darwin/usr" \
    --label machorun-runtime --output "$EVIDENCE/copy-machorun-runtime.json"
COPIED_MACHORUN_LOADER_SHA256=$(shasum -a 256 \
    "$REPLAY_ROOT/machorun/build/machorun" | awk '{print $1}')
[ "$COPIED_MACHORUN_LOADER_SHA256" = "$EXPECTED_MACHORUN_LOADER_SHA256" ] \
    || die 'physically copied machorun loader hash differs'
assert_checkout "$REPLAY_ROOT/machorun" "$EXPECTED_MACHORUN_COMMIT" \
    "$EXPECTED_MACHORUN_TREE" staged-machorun

mkdir -p "$REPLAY_ROOT/w/scratch"
for relative in "${STAGED_INPUTS[@]}"; do
    python3 -B "$PHYSICAL_REPLAY_TOOL" copy-tree \
        --source "$STAGED_INPUT_ROOT/$relative" \
        --destination "$REPLAY_ROOT/w/scratch/$relative" \
        --label "staged-$relative" \
        --output "$EVIDENCE/copy-staged-$relative.json"
done

if [ "$preview_count" -eq 3 ]; then
    mkdir -p "$REPLAY_ROOT/inputs/preview"
    python3 -B "$PHYSICAL_REPLAY_TOOL" copy-file \
        --source "$DEVELOPER_TOOLS_SUPPORT_MODULE" \
        --destination "$REPLAY_ROOT/inputs/preview/DeveloperToolsSupport.swiftmodule" \
        --label DeveloperToolsSupport-module \
        --output "$EVIDENCE/copy-preview-module.json"
    python3 -B "$PHYSICAL_REPLAY_TOOL" copy-file \
        --source "$DEVELOPER_TOOLS_SUPPORT_OBJECT" \
        --destination "$REPLAY_ROOT/inputs/preview/developertoolsupport.o" \
        --label DeveloperToolsSupport-object \
        --output "$EVIDENCE/copy-preview-object.json"
    python3 -B "$PHYSICAL_REPLAY_TOOL" copy-file \
        --source "$PREVIEW_MACRO_PLUGIN" \
        --destination "$REPLAY_ROOT/inputs/preview/OpenUIKitPreviewMacros-tool" \
        --label Preview-macro-plugin \
        --output "$EVIDENCE/copy-preview-plugin.json"
fi

# These four exact paths are the only replay paths excluded from the immutable
# input manifest. They are new empty physical directories in the one replay
# bind. Do not over-mount them: Docker Desktop has been observed losing nested
# tmpfs mounts mid-container, including a populated working guest root.
FRESH_PATHS=(
    w/build
    w/scratch/modcache_full
    w/scratch/modcache_fe4
    w/scratch/mrroot_full
)
mkdir -p "$REPLAY_ROOT/w/build" \
    "$REPLAY_ROOT/w/scratch/modcache_full" \
    "$REPLAY_ROOT/w/scratch/modcache_fe4" \
    "$REPLAY_ROOT/w/scratch/mrroot_full"
SNAPSHOT_ARGS=()
for relative in "${FRESH_PATHS[@]}"; do
    SNAPSHOT_ARGS+=(--exclude "$relative")
done
python3 -B "$PHYSICAL_REPLAY_TOOL" snapshot --root "$REPLAY_ROOT" \
    --output "$EVIDENCE/input-manifest.pre.jsonl" "${SNAPSHOT_ARGS[@]}"
INPUT_MANIFEST_PRE_SHA256=$(shasum -a 256 \
    "$EVIDENCE/input-manifest.pre.jsonl" | awk '{print $1}')

record_git_identity() {
    local checkout=$1 label=$2 commit tree status
    commit=$(git -C "$checkout" rev-parse --verify HEAD^{commit})
    tree=$(git -C "$checkout" rev-parse --verify HEAD^{tree})
    status=$(git -C "$checkout" status --porcelain=v1 --untracked-files=all)
    [ -z "$status" ] || die "$label staged Git checkout is dirty: $status"
    printf 'git\t%s\tcommit=%s\ttree=%s\n' "$label" "$commit" "$tree"
}
{
    printf 'format\tcore-guest-host-run-v2\n'
    printf 'host-cwd\t%s\n' "$(pwd -P)"
    printf 'image\t%s\tplatform=%s\n' "$CONTAINER_IMAGE" "$IMAGE_PLATFORM"
    record_git_identity "$REPLAY_ROOT/w" support
    record_git_identity "$REPLAY_ROOT/uikit" OpenUIKit
    record_git_identity "$REPLAY_ROOT/machorun" machorun
    record_git_identity "$REPLAY_ROOT/w/scratch/swift-foundation" swift-foundation
    record_git_identity "$REPLAY_ROOT/w/scratch/swift-foundation-icu" \
        swift-foundation-icu
    record_git_identity "$REPLAY_ROOT/w/scratch/swift-collections" swift-collections
    record_git_identity \
        "$REPLAY_ROOT/w/scratch/opencombine-core-durable-20260828-r2/source" \
        OpenCombine
    printf 'machorun-loader\tsha256=%s\n' "$COPIED_MACHORUN_LOADER_SHA256"
    printf 'input-manifest-pre\tsha256=%s\n' "$INPUT_MANIFEST_PRE_SHA256"
    for report in "$EVIDENCE"/copy-*.json; do
        printf 'physical-copy-report\t%s\tsha256=%s\n' "${report##*/}" \
            "$(shasum -a 256 "$report" | awk '{print $1}')"
    done
    printf 'bind\tcount=1\tmode=rw\tguest=/replay\n'
    printf 'input-immutability\tcontent-manifest-pre-post\n'
    printf 'container-root\tread-only\n'
    printf 'network\tnone\n'
    printf 'tmpfs\t/tmp\n'
    for relative in "${FRESH_PATHS[@]}"; do
        printf 'fresh-bind-path\t%s\n' "$relative"
    done
    printf 'preview\t%s\n' "$([ "$preview_count" -eq 3 ] && printf enabled || printf disabled)"
} > "$EVIDENCE/host-inputs.tsv"

DOCKER_ARGS=(
    run --rm --platform linux/arm64
    --network none
    --read-only
    -e GIT_OPTIONAL_LOCKS=0
    -e PYTHONDONTWRITEBYTECODE=1
    -e HOME=/tmp/home
    -e TMPDIR=/tmp
    -e XDG_CACHE_HOME=/tmp/xdg-cache
    -e W=/replay/w
    -e MACHORUN=/replay/machorun
    --tmpfs /tmp:rw,exec,nosuid,nodev,mode=1777
    -v "$REPLAY_ROOT:/replay:rw"
)
BUILD_ARGS=(
    bash full/frameworks/build_core_guest_package.sh
    --output-root /replay/w/build/core-package
    --expected-support-commit "$EXPECTED_SUPPORT_COMMIT"
    --expected-support-tree "$EXPECTED_SUPPORT_TREE"
    --uikit-checkout /replay/uikit
    --expected-uikit-commit "$EXPECTED_UIKIT_COMMIT"
    --expected-uikit-tree "$EXPECTED_UIKIT_TREE"
)
if [ "$preview_count" -eq 3 ]; then
    BUILD_ARGS+=(
        --developer-tools-support-module /replay/inputs/preview/DeveloperToolsSupport.swiftmodule
        --developer-tools-support-object /replay/inputs/preview/developertoolsupport.o
        --preview-macro-plugin /replay/inputs/preview/OpenUIKitPreviewMacros-tool
    )
fi

docker "${DOCKER_ARGS[@]}" -w /replay/w "$CONTAINER_IMAGE" \
    bash -lc 'set -euo pipefail; mkdir -p "$HOME" "$XDG_CACHE_HOME"; test -d "$W" -a -d "$W/build"; "$@"; python3 -B full/xcodeplan/core_guest_package.py "$W/build/core-package" --emit-summary' \
    core-package-build "${BUILD_ARGS[@]}" 2>&1 | tee "$RUN_ROOT/docker.log"

PACKAGE=$REPLAY_ROOT/w/build/core-package
[ -d "$PACKAGE" ] && [ ! -L "$PACKAGE" ] \
    || die 'container returned success without a core package'

# This is a host-visible durability gate, not merely a container-local build
# assertion. A real build must leave the staged loader and all three linked
# root products in the one bind after Docker exits. It specifically prevents a
# nested-mount regression from reaching package validation or publication.
GUEST_ROOT=$REPLAY_ROOT/w/scratch/mrroot_full
GUEST_ROOT_PRODUCTS=(
    machorun
    .manifest
    darwin/usr/lib/libSystem.real.dylib
    darwin/usr/lib/libSystem.B.dylib
    darwin/usr/lib/libc++.real.dylib
    darwin/usr/lib/libc++.1.dylib
    darwin/usr/lib/libquartz.dylib
    darwin/usr/lib/libOpenFoundationInternationalization.dylib
    host/libOpenFoundationInternationalizationHost.so
)
{
    printf 'format\tcore-guest-durable-root-v1\n'
    for relative in "${GUEST_ROOT_PRODUCTS[@]}"; do
        product=$GUEST_ROOT/$relative
        [ -f "$product" ] && [ ! -L "$product" ] \
            || die "durable guest-root product is missing after Docker: $relative"
        printf 'product\t%s\tsha256=%s\n' "$relative" \
            "$(shasum -a 256 "$product" | awk '{print $1}')"
    done
} > "$EVIDENCE/guest-root-post-build.tsv"
python3 -B "$REPLAY_ROOT/w/full/xcodeplan/core_guest_package.py" \
    "$PACKAGE" --emit-summary | tee "$RUN_ROOT/host-validator.log"

python3 -B "$PHYSICAL_REPLAY_TOOL" snapshot --root "$REPLAY_ROOT" \
    --output "$EVIDENCE/input-manifest.post.jsonl" "${SNAPSHOT_ARGS[@]}"
INPUT_MANIFEST_POST_SHA256=$(shasum -a 256 \
    "$EVIDENCE/input-manifest.post.jsonl" | awk '{print $1}')
python3 -B "$PHYSICAL_REPLAY_TOOL" compare \
    --before "$EVIDENCE/input-manifest.pre.jsonl" \
    --after "$EVIDENCE/input-manifest.post.jsonl"
[ "$INPUT_MANIFEST_POST_SHA256" = "$INPUT_MANIFEST_PRE_SHA256" ] \
    || die 'immutable input manifest hash differs after replay'

[ ! -e "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ] \
    || die "output root appeared before atomic publication: $OUTPUT_ROOT"
python3 -B "$PHYSICAL_REPLAY_TOOL" publish \
    --source "$PACKAGE" --destination "$OUTPUT_ROOT" \
    --expected-parent "$OUTPUT_PARENT"
python3 -B "$PHYSICAL_REPLAY_TOOL" remove-tree \
    --path "$REPLAY_ROOT" --expected-parent "$RUN_ROOT"
{
    printf 'format\tcore-guest-host-success-v2\n'
    printf 'output\t%s\n' "$OUTPUT_ROOT"
    printf 'core-package-json\t%s\n' \
        "$(shasum -a 256 "$OUTPUT_ROOT/attestation/core-package.json" | awk '{print $1}')"
    printf 'input-manifest-pre\t%s\n' "$INPUT_MANIFEST_PRE_SHA256"
    printf 'input-manifest-post\t%s\n' "$INPUT_MANIFEST_POST_SHA256"
    printf 'physical-replay-cleaned\tyes\n'
} > "$RUN_ROOT/SUCCESS"
RUN_SUCCESS=1
echo "CORE_GUEST_PACKAGE_HOST_OK output=$OUTPUT_ROOT evidence=$RUN_ROOT"
