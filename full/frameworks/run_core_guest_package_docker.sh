#!/usr/bin/env bash
# Host-side cold replay wrapper. It constructs a no-hardlink support clone,
# mounts every source/staged input read-only, overlays only fresh writable
# build/cache/root directories, and atomically publishes one validated package.

set -euo pipefail

SUPPORT_CHECKOUT=''
EXPECTED_SUPPORT_COMMIT=''
EXPECTED_SUPPORT_TREE=''
STAGED_INPUT_ROOT=''
UIKIT_CHECKOUT=''
EXPECTED_UIKIT_COMMIT=''
EXPECTED_UIKIT_TREE=''
MACHORUN_CHECKOUT=''
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
  --output-root NEW_ABSOLUTE_PATH [Preview trio]

Preview is all-or-none:
  --developer-tools-support-module PATH
  --developer-tools-support-object PATH
  --preview-macro-plugin PATH

The staged input root must contain these immutable prepared inputs:
  sysroot_fe4/  mrroot/  mrroot_fe/  swift-foundation/
  swift-collections/  opencombine-core-durable-20260828-r2/

The wrapper never reuses a build product. It makes a fresh run directory next
to OUTPUT_ROOT, mounts the support clone read-only at /w, overlays only new
/w/build, /w/scratch/modcache_full, /w/scratch/modcache_fe4, and
/w/scratch/mrroot_full directories, and publishes OUTPUT_ROOT only after both
manifest validators pass.
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
    "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE"; do
    [ "${#expected}" -eq 40 ] || die "Git ID must be lowercase 40-hex: $expected"
    case "$expected" in *[!0-9a-f]*) die "Git ID must be lowercase 40-hex: $expected" ;; esac
done

for tool in docker git mktemp python3 tee ls awk shasum; do
    command -v "$tool" >/dev/null || die "required host tool is missing: $tool"
done
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

for relative in sysroot_fe4 mrroot mrroot_fe swift-foundation \
    swift-collections opencombine-core-durable-20260828-r2; do
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

git clone --no-hardlinks --no-local --quiet "$SUPPORT_CHECKOUT" "$RUN_ROOT/w"
assert_checkout "$RUN_ROOT/w" "$EXPECTED_SUPPORT_COMMIT" \
    "$EXPECTED_SUPPORT_TREE" cloned-support
mkdir -p "$RUN_ROOT/build" "$RUN_ROOT/modcache_full" \
    "$RUN_ROOT/modcache_fe4" "$RUN_ROOT/mrroot_full"
mkdir -p "$RUN_ROOT/w/scratch" \
    "$RUN_ROOT/w/scratch/sysroot_fe4" "$RUN_ROOT/w/scratch/mrroot" \
    "$RUN_ROOT/w/scratch/mrroot_fe" "$RUN_ROOT/w/scratch/swift-foundation" \
    "$RUN_ROOT/w/scratch/swift-collections" \
    "$RUN_ROOT/w/scratch/opencombine-core-durable-20260828-r2" \
    "$RUN_ROOT/w/scratch/modcache_full" "$RUN_ROOT/w/scratch/modcache_fe4" \
    "$RUN_ROOT/w/scratch/mrroot_full" \
    "$RUN_ROOT/w/build"

{
    printf 'format\tcore-guest-host-run-v1\n'
    printf 'host-cwd\t%s\n' "$(pwd -P)"
    printf 'support\tcommit=%s\ttree=%s\n' \
        "$EXPECTED_SUPPORT_COMMIT" "$EXPECTED_SUPPORT_TREE"
    printf 'OpenUIKit\tcommit=%s\ttree=%s\n' \
        "$EXPECTED_UIKIT_COMMIT" "$EXPECTED_UIKIT_TREE"
    printf 'image\t%s\tplatform=%s\n' "$CONTAINER_IMAGE" "$IMAGE_PLATFORM"
    printf 'fresh-build-inode\t%s\n' "$(ls -di "$RUN_ROOT/build" | awk '{print $1}')"
    printf 'fresh-modcache-inode\t%s\n' "$(ls -di "$RUN_ROOT/modcache_full" | awk '{print $1}')"
    printf 'fresh-modcache-fe4-inode\t%s\n' \
        "$(ls -di "$RUN_ROOT/modcache_fe4" | awk '{print $1}')"
    printf 'fresh-guest-root-inode\t%s\n' "$(ls -di "$RUN_ROOT/mrroot_full" | awk '{print $1}')"
    printf 'preview\t%s\n' "$([ "$preview_count" -eq 3 ] && printf enabled || printf disabled)"
} > "$RUN_ROOT/host-inputs.tsv"

DOCKER_ARGS=(
    run --rm --platform linux/arm64
    -e GIT_OPTIONAL_LOCKS=0
    -v "$RUN_ROOT/w:/w:ro"
    -v "$RUN_ROOT/build:/w/build:rw"
    -v "$RUN_ROOT/modcache_full:/w/scratch/modcache_full:rw"
    -v "$RUN_ROOT/modcache_fe4:/w/scratch/modcache_fe4:rw"
    -v "$RUN_ROOT/mrroot_full:/w/scratch/mrroot_full:rw"
    -v "$STAGED_INPUT_ROOT/sysroot_fe4:/w/scratch/sysroot_fe4:ro"
    -v "$STAGED_INPUT_ROOT/mrroot:/w/scratch/mrroot:ro"
    -v "$STAGED_INPUT_ROOT/mrroot_fe:/w/scratch/mrroot_fe:ro"
    -v "$STAGED_INPUT_ROOT/swift-foundation:/w/scratch/swift-foundation:ro"
    -v "$STAGED_INPUT_ROOT/swift-collections:/w/scratch/swift-collections:ro"
    -v "$STAGED_INPUT_ROOT/opencombine-core-durable-20260828-r2:/w/scratch/opencombine-core-durable-20260828-r2:ro"
    -v "$UIKIT_CHECKOUT:/uikit:ro"
    -v "$MACHORUN_CHECKOUT:/machorun:ro"
)
BUILD_ARGS=(
    bash full/frameworks/build_core_guest_package.sh
    --output-root /w/build/core-package
    --expected-support-commit "$EXPECTED_SUPPORT_COMMIT"
    --expected-support-tree "$EXPECTED_SUPPORT_TREE"
    --uikit-checkout /uikit
    --expected-uikit-commit "$EXPECTED_UIKIT_COMMIT"
    --expected-uikit-tree "$EXPECTED_UIKIT_TREE"
)
if [ "$preview_count" -eq 3 ]; then
    DOCKER_ARGS+=(
        -v "$DEVELOPER_TOOLS_SUPPORT_MODULE:/inputs/DeveloperToolsSupport.swiftmodule:ro"
        -v "$DEVELOPER_TOOLS_SUPPORT_OBJECT:/inputs/developertoolsupport.o:ro"
        -v "$PREVIEW_MACRO_PLUGIN:/inputs/OpenUIKitPreviewMacros-tool:ro"
    )
    BUILD_ARGS+=(
        --developer-tools-support-module /inputs/DeveloperToolsSupport.swiftmodule
        --developer-tools-support-object /inputs/developertoolsupport.o
        --preview-macro-plugin /inputs/OpenUIKitPreviewMacros-tool
    )
fi

docker "${DOCKER_ARGS[@]}" -w /w "$CONTAINER_IMAGE" \
    bash -lc 'set -euo pipefail; pwd -P; test -d /w -a -d /w/build; "$@"; python3 full/xcodeplan/core_guest_package.py /w/build/core-package --emit-summary' \
    core-package-build "${BUILD_ARGS[@]}" 2>&1 | tee "$RUN_ROOT/docker.log"

[ -d "$RUN_ROOT/build/core-package" ] \
    || die 'container returned success without a core package'
python3 "$RUN_ROOT/w/full/xcodeplan/core_guest_package.py" \
    "$RUN_ROOT/build/core-package" --emit-summary \
    | tee "$RUN_ROOT/host-validator.log"
mv -- "$RUN_ROOT/build/core-package" "$OUTPUT_ROOT"
{
    printf 'format\tcore-guest-host-success-v1\n'
    printf 'output\t%s\n' "$OUTPUT_ROOT"
    printf 'core-package-json\t%s\n' \
        "$(shasum -a 256 "$OUTPUT_ROOT/attestation/core-package.json" | awk '{print $1}')"
} > "$RUN_ROOT/SUCCESS"
RUN_SUCCESS=1
echo "CORE_GUEST_PACKAGE_HOST_OK output=$OUTPUT_ROOT evidence=$RUN_ROOT"
