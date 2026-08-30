#!/usr/bin/env bash
# Build and attest the content-addressed Linux/ARM64 cross-compilation image.
set -euo pipefail
umask 077

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY=$(cd -- "$SCRIPT_DIR/.." && pwd)
BASE_REFERENCE='swift:6.2-noble@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc'
BASE_IMAGE_ID='sha256:b7a5862e90bdf042ed5586b26cd47135ec93c4f97d3dd4d3181fdabcccc3c6d7'
TAG=''
EXISTING_IMAGE_ID=''
ATTESTATION_ROOT=''

die() {
    echo "swift-macho-image: REFUSING -- $*" >&2
    exit 2
}

usage() {
    cat >&2 <<'EOF'
usage: harness/build_image.sh \
  (--tag LOCAL_TAG | --image-id SHA256_IMAGE_ID) \
  --attestation-root NEW_ABSOLUTE_DIRECTORY

Build mode creates a Linux/ARM64 image from the digest- and version-pinned
recipe. Verification mode re-attests a previously built exact content ID
against the current clean support checkout. The attestation root must not
exist. On failure it is renamed with .INVALID-DO-NOT-USE; on success, SUCCESS
names the exact image ID.
EOF
    exit 2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --tag) [ "$#" -ge 2 ] || usage; TAG=$2; shift 2 ;;
        --image-id) [ "$#" -ge 2 ] || usage; EXISTING_IMAGE_ID=$2; shift 2 ;;
        --attestation-root)
            [ "$#" -ge 2 ] || usage; ATTESTATION_ROOT=$2; shift 2 ;;
        --help|-h) usage ;;
        *) usage ;;
    esac
done
[ -n "$ATTESTATION_ROOT" ] || usage
mode_count=0
[ -n "$TAG" ] && mode_count=$((mode_count + 1))
[ -n "$EXISTING_IMAGE_ID" ] && mode_count=$((mode_count + 1))
[ "$mode_count" -eq 1 ] || usage
if [ -n "$EXISTING_IMAGE_ID" ]; then
    [ "${#EXISTING_IMAGE_ID}" -eq 71 ] \
        || die "image ID must be an exact sha256 content ID"
    case "$EXISTING_IMAGE_ID" in
        sha256:*[!0-9a-f]*|*[!0-9a-f])
            die "image ID must be an exact lowercase sha256 content ID" ;;
        sha256:*) ;;
        *) die "image ID must be an exact sha256 content ID" ;;
    esac
fi
case "$ATTESTATION_ROOT" in /*) ;; *) die "attestation root must be absolute" ;; esac
[ ! -e "$ATTESTATION_ROOT" ] && [ ! -L "$ATTESTATION_ROOT" ] \
    || die "attestation root already exists: $ATTESTATION_ROOT"
[ -f "$SCRIPT_DIR/Dockerfile" ] && [ ! -L "$SCRIPT_DIR/Dockerfile" ] \
    || die "Dockerfile is not a regular non-symlink file"
for tool in docker git shasum awk tee grep mkdir mv date; do
    command -v "$tool" >/dev/null || die "required host tool is missing: $tool"
done

support_commit=$(git -C "$REPOSITORY" rev-parse --verify HEAD^{commit})
support_tree=$(git -C "$REPOSITORY" rev-parse --verify HEAD^{tree})
support_status=$(git -C "$REPOSITORY" status --porcelain=v1 --untracked-files=all)
[ -z "$support_status" ] || die "support checkout is not clean: $support_status"
base_id=$(docker image inspect --format '{{.Id}}' "$BASE_REFERENCE" 2>/dev/null) \
    || die "digest-pinned base image is unavailable: $BASE_REFERENCE"
[ "$base_id" = "$BASE_IMAGE_ID" ] \
    || die "base image ID is $base_id, expected $BASE_IMAGE_ID"
[ "$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$BASE_REFERENCE")" \
    = linux/arm64 ] || die "base image is not Linux/ARM64"

mkdir "$ATTESTATION_ROOT"
success=0
cleanup() {
    status=$?
    trap - EXIT
    if [ "$success" -ne 1 ] && [ -d "$ATTESTATION_ROOT" ]; then
        invalid=$ATTESTATION_ROOT.INVALID-DO-NOT-USE
        [ ! -e "$invalid" ] || invalid=$invalid.$(date -u +%Y%m%dT%H%M%SZ)
        mv -- "$ATTESTATION_ROOT" "$invalid"
        echo "swift-macho-image: quarantined failed evidence at $invalid" >&2
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

{
    printf 'format\tswift-macho-image-build-v1\n'
    printf 'host-cwd\t%s\n' "$(pwd -P)"
    printf 'support\tcommit=%s\ttree=%s\n' "$support_commit" "$support_tree"
    printf 'dockerfile_sha256\t%s\n' \
        "$(shasum -a 256 "$SCRIPT_DIR/Dockerfile" | awk '{print $1}')"
    printf 'base_reference\t%s\n' "$BASE_REFERENCE"
    printf 'base_image_id\t%s\n' "$BASE_IMAGE_ID"
    if [ -n "$TAG" ]; then
        printf 'mode\tbuild\n'
        printf 'requested_tag\t%s\n' "$TAG"
    else
        printf 'mode\tverify-existing\n'
        printf 'requested_image_id\t%s\n' "$EXISTING_IMAGE_ID"
    fi
} >"$ATTESTATION_ROOT/inputs.tsv"

if [ -n "$TAG" ]; then
    docker build --no-cache --pull=false --platform linux/arm64 \
        --tag "$TAG" --file "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR" \
        2>&1 | tee "$ATTESTATION_ROOT/docker-build.log"
    image_id=$(docker image inspect --format '{{.Id}}' "$TAG")
else
    image_id=$EXISTING_IMAGE_ID
fi
[ "${#image_id}" -eq 71 ] || die "built image has a malformed content ID"
case "$image_id" in sha256:*) ;; *) die "built image is not content-addressed" ;; esac
[ "$(docker image inspect --format '{{.Id}}' "$image_id" 2>/dev/null)" = "$image_id" ] \
    || die "exact image is unavailable: $image_id"
[ "$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$image_id")" \
    = linux/arm64 ] || die "built image is not Linux/ARM64"
docker image inspect "$image_id" >"$ATTESTATION_ROOT/image-inspect.json"
docker history --no-trunc "$image_id" >"$ATTESTATION_ROOT/image-history.txt"

docker run --rm --platform linux/arm64 "$image_id" bash -lc '
set -euo pipefail
printf "format\tswift-macho-image-runtime-v1\n"
printf "platform\t%s/%s\n" "$(uname -s)" "$(uname -m)"
dpkg-query -W -f="\${Package}\t\${Version}\t\${Architecture}\n" \
  lld-18 llvm-18 clang-18 libc++-18-dev file xxd binutils python3 \
  | LC_ALL=C sort
printf "swiftc_sha256\t%s\n" "$(sha256sum /usr/bin/swiftc | awk "{print \$1}")"
printf "python_version\t%s\n" "$(python3 --version)"
printf "swift_version\t%s\n" "$(swiftc --version | head -1)"
printf "clang_version\t%s\n" "$(clang-18 --version | head -1)"
printf "lld_version\t%s\n" "$(ld64.lld-18 --version | head -1)"
printf "font_system_sha256\t%s\n" \
  "$(sha256sum /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf | awk "{print \$1}")"
printf "font_bold_sha256\t%s\n" \
  "$(sha256sum /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf | awk "{print \$1}")"
for tool in python3 swiftc clang-18 clang++-18 ld64.lld-18 llvm-otool-18 \
    llvm-nm-18 perl patch sha256sum file readelf; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 2; }
done
tmp=$(mktemp -d)
trap "rm -rf -- \"$tmp\"" EXIT
printf "#include <vector>\nint main(){std::vector<int> v; return (int)v.size();}\n" \
  >"$tmp/libcxx.cpp"
clang++-18 -stdlib=libc++ "$tmp/libcxx.cpp" -o "$tmp/libcxx-probe"
"$tmp/libcxx-probe"
printf "libcxx_compile_and_run\tOK\n"
' >"$ATTESTATION_ROOT/runtime-attestation.tsv"

for expected in \
    $'binutils\t2.42-4ubuntu2.10\tarm64' \
    $'clang-18\t1:18.1.3-1ubuntu1\tarm64' \
    $'file\t1:5.45-3build1\tarm64' \
    $'libc++-18-dev\t1:18.1.3-1ubuntu1\tarm64' \
    $'lld-18\t1:18.1.3-1ubuntu1\tarm64' \
    $'llvm-18\t1:18.1.3-1ubuntu1\tarm64' \
    $'python3\t3.12.3-0ubuntu2.1\tarm64' \
    $'xxd\t2:9.1.0016-1ubuntu7.20\tarm64' \
    $'platform\tLinux/aarch64' \
    $'swiftc_sha256\t5a7209655c37a4f4937ea5219a4af59a7c9fc52dd13c615f26682642bc3a83ff' \
    $'python_version\tPython 3.12.3' \
    $'font_system_sha256\tae7b7855e115a5966d8b1b3f80f254ccc117ec86f9965e202ee2940453837280' \
    $'font_bold_sha256\t5c1247acef7f2b8522a31742c76d6adcb5569bacc0be7ceaa4dc39dd252ce895' \
    $'libcxx_compile_and_run\tOK'; do
    grep -Fx "$expected" "$ATTESTATION_ROOT/runtime-attestation.tsv" >/dev/null \
        || die "runtime attestation is missing: $expected"
done
{
    printf 'format\tswift-macho-image-success-v1\n'
    printf 'image_id\t%s\n' "$image_id"
    printf 'platform\tlinux/arm64\n'
    printf 'runtime_attestation_sha256\t%s\n' \
        "$(shasum -a 256 "$ATTESTATION_ROOT/runtime-attestation.tsv" | awk '{print $1}')"
} >"$ATTESTATION_ROOT/SUCCESS"
success=1
echo "SWIFT_MACHO_IMAGE_OK image=$image_id evidence=$ATTESTATION_ROOT"
