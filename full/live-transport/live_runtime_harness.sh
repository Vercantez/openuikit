#!/usr/bin/env bash
# Source-pinned build and localhost-only runtime control for the true-iOS
# Mach-O → mmap transport → native SDL → noVNC route.

set -Eeuo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
DEFAULT_BASE='swift@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc'

die() {
    echo "openui-live-harness: $*" >&2
    exit 2
}

usage() {
    cat >&2 <<'EOF'
usage:
  live_runtime_harness.sh build-image --source REPO --commit SHA --tree SHA
      --image TAG [--base IMAGE@sha256:DIGEST] [--cold]
  live_runtime_harness.sh launch --image IMAGE --guest-root DIR
      --application-output DIR --product NAME [--name NAME] [--port PORT]
      [--scale SCALE] [--scripted-proof]
  live_runtime_harness.sh health [--name NAME]
  live_runtime_harness.sh url [--port PORT]
  live_runtime_harness.sh stop [--name NAME]

Defaults: name=openui-macho-live port=6080 scale=1.
The app output and guest root are mounted read-only. noVNC is always published
on 127.0.0.1. `build-image --cold` passes Docker --no-cache.
EOF
    exit 2
}

need_value() { [ "$#" -ge 2 ] && [ -n "$2" ] || die "$1 requires a value"; }
sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

mode=${1:-}
[ -n "$mode" ] || usage
shift
source_repo=
commit=
tree=
image=
base=$DEFAULT_BASE
guest_root=
application_output=
product=
name=openui-macho-live
port=6080
scale=1
cold=0
scripted_proof=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --source) need_value "$@"; source_repo=$2; shift 2 ;;
        --commit) need_value "$@"; commit=$2; shift 2 ;;
        --tree) need_value "$@"; tree=$2; shift 2 ;;
        --image) need_value "$@"; image=$2; shift 2 ;;
        --base) need_value "$@"; base=$2; shift 2 ;;
        --guest-root) need_value "$@"; guest_root=$2; shift 2 ;;
        --application-output) need_value "$@"; application_output=$2; shift 2 ;;
        --product) need_value "$@"; product=$2; shift 2 ;;
        --name) need_value "$@"; name=$2; shift 2 ;;
        --port) need_value "$@"; port=$2; shift 2 ;;
        --scale) need_value "$@"; scale=$2; shift 2 ;;
        --cold) cold=1; shift ;;
        --scripted-proof) scripted_proof=1; shift ;;
        *) usage ;;
    esac
done

[[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] \
    || die "invalid container name: $name"
[[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ] \
    || die "port must be between 1024 and 65535"
[[ "$scale" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "invalid scale"

print_url() {
    printf 'http://127.0.0.1:%s/vnc.html?autoconnect=1&resize=scale\n' "$1"
}

build_image() {
    for tool in docker git tar; do
        command -v "$tool" >/dev/null 2>&1 || die "required tool is missing: $tool"
    done
    [ -d "$source_repo" ] || die "support repository is missing: $source_repo"
    [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || die "commit must be full lowercase SHA"
    [[ "$tree" =~ ^[0-9a-f]{40}$ ]] || die "tree must be full lowercase SHA"
    [[ "$base" =~ @sha256:[0-9a-f]{64}$ ]] \
        || die "base image must be pinned by repository digest"
    [ -n "$image" ] || die "--image is required"
    source_repo=$(CDPATH= cd -- "$source_repo" && pwd -P)
    actual_commit=$(git -C "$source_repo" rev-parse --verify "${commit}^{commit}") \
        || die "support commit is unavailable"
    actual_tree=$(git -C "$source_repo" rev-parse --verify "${commit}^{tree}")
    [ "$actual_commit" = "$commit" ] || die "support commit identity drifted"
    [ "$actual_tree" = "$tree" ] || die "support tree identity drifted"
    git -C "$source_repo" cat-file -e \
        "$commit:full/live-transport/Dockerfile" 2>/dev/null \
        || die "support commit does not contain the live runtime Dockerfile"

    temp_parent=${TMPDIR:-/tmp}
    temp_parent=${temp_parent%/}
    context=$(mktemp -d "$temp_parent/openui-live-image.XXXXXX")
    cleanup_context() {
        [ -n "${context:-}" ] || return 0
        case "$context" in
            "$temp_parent"/openui-live-image.*)
                if [ -x /usr/bin/trash ]; then
                    /usr/bin/trash "$context"
                else
                    rm -rf -- "$context"
                fi
                ;;
            *) echo "openui-live-harness: refusing unsafe cleanup: $context" >&2 ;;
        esac
        context=
    }
    trap cleanup_context EXIT HUP INT TERM
    git -C "$source_repo" archive --format=tar \
        --output="$context/source.tar" "$commit"
    archive_sha=$(sha256_file "$context/source.tar")
    tar -xf "$context/source.tar" -C "$context"
    if [ -x /usr/bin/trash ]; then
        /usr/bin/trash "$context/source.tar"
    else
        rm -f -- "$context/source.tar"
    fi
    tracked=$(git -C "$source_repo" ls-tree -r --name-only "$commit" \
        | wc -l | tr -d '[:space:]')
    {
        printf 'commit\t%s\n' "$commit"
        printf 'tree\t%s\n' "$tree"
        printf 'archive_sha256\t%s\n' "$archive_sha"
        printf 'tracked_files\t%s\n' "$tracked"
    } >"$context/source-provenance.tsv"

    command=(docker build --platform linux/arm64 --progress=plain)
    [ "$cold" -eq 0 ] || command+=(--no-cache)
    command+=(--build-arg "SWIFT_BASE=$base"
        --build-arg "SUPPORT_COMMIT=$commit"
        --build-arg "SUPPORT_TREE=$tree"
        --build-arg "SUPPORT_ARCHIVE_SHA256=$archive_sha"
        -f "$context/full/live-transport/Dockerfile"
        -t "$image" "$context")
    "${command[@]}"
    image_id=$(docker image inspect --format '{{.Id}}' "$image")
    image_commit=$(docker image inspect --format \
        '{{index .Config.Labels "org.opencontainers.image.revision"}}' "$image")
    image_tree=$(docker image inspect --format \
        '{{index .Config.Labels "org.opencontainers.image.source-tree"}}' "$image")
    [ "$image_commit" = "$commit" ] || die "runtime image commit label drifted"
    [ "$image_tree" = "$tree" ] || die "runtime image tree label drifted"
    echo "OPENUI_LIVE_IMAGE_OK image=$image id=$image_id commit=$commit tree=$tree archive=$archive_sha cold=$cold"
    cleanup_context
    trap - EXIT HUP INT TERM
}

health() {
    command -v docker >/dev/null 2>&1 || die "docker is unavailable"
    command -v curl >/dev/null 2>&1 || die "curl is unavailable"
    [ "$(docker inspect --format '{{.State.Running}}' "$name" 2>/dev/null || true)" = true ] \
        || die "container is not running: $name"
    docker exec "$name" test -s /run/openui-live/ready.env \
        || die "container has no readiness record"
    ready=$(docker exec "$name" cat /run/openui-live/ready.env)
    value() { printf '%s\n' "$ready" | awk -F= -v key="$1" '$1 == key { print $2 }'; }
    ready_commit=$(value SUPPORT_COMMIT)
    ready_tree=$(value SUPPORT_TREE)
    ready_display=$(value DISPLAY)
    ready_window=$(value WINDOW_ID)
    [[ "$ready_commit" =~ ^[0-9a-f]{40}$ ]] || die "invalid ready commit"
    [[ "$ready_tree" =~ ^[0-9a-f]{40}$ ]] || die "invalid ready tree"
    [[ "$ready_window" =~ ^[0-9]+$ ]] || die "invalid ready window"
    image_commit=$(docker inspect --format \
        '{{index .Config.Labels "org.opencontainers.image.revision"}}' "$name")
    image_tree=$(docker inspect --format \
        '{{index .Config.Labels "org.opencontainers.image.source-tree"}}' "$name")
    [ "$ready_commit" = "$image_commit" ] || die "runtime/image commit mismatch"
    [ "$ready_tree" = "$image_tree" ] || die "runtime/image tree mismatch"
    docker exec "$name" bash -lc \
        'source /run/openui-live/ready.env; kill -0 "$XVFB_PID"; kill -0 "$VNC_PID"; kill -0 "$WEBSOCKIFY_PID"; kill -0 "$HOST_PID"; kill -0 "$GUEST_PID"' \
        || die "one or more live runtime processes exited"
    docker exec "$name" env DISPLAY="$ready_display" \
        xwininfo -id "$ready_window" >/dev/null \
        || die "live SDL window is not visible"
    proof=$(docker exec "$name" cat /run/openui-live/proof.tsv)
    proof_value() { printf '%s\n' "$proof" | awk -F '\t' -v key="$1" '$1 == key { print $2 }'; }
    executable_sha=$(proof_value executable_sha256)
    initial_sha=$(proof_value initial_pixel_sha256)
    clicked_sha=$(proof_value clicked_pixel_sha256)
    typed_sha=$(proof_value typed_pixel_sha256)
    [[ "$executable_sha" =~ ^[0-9a-f]{64}$ ]] || die "invalid executable hash"
    [[ "$initial_sha" =~ ^[0-9a-f]{64}$ ]] || die "invalid initial pixel hash"
    if [ "$(proof_value scripted_proof)" = 1 ]; then
        [[ "$clicked_sha" =~ ^[0-9a-f]{64}$ ]] || die "invalid clicked pixel hash"
        [[ "$typed_sha" =~ ^[0-9a-f]{64}$ ]] || die "invalid typed pixel hash"
        [ "$initial_sha" != "$clicked_sha" ] && [ "$clicked_sha" != "$typed_sha" ] \
            || die "scripted proof frame hashes did not change"
    fi
    url=$(print_url "$port")
    html_bytes=$(curl --fail --silent --show-error --max-time 5 "$url" \
        | wc -c | tr -d '[:space:]')
    [ "$html_bytes" -gt 1000 ] || die "noVNC health response is too small"
    image_id=$(docker inspect --format '{{.Image}}' "$name")
    echo "OPENUI_LIVE_HEALTH_OK container=$name image=$image_id executable=$executable_sha initial=$initial_sha clicked=$clicked_sha typed=$typed_sha url=$url"
}

launch() {
    command -v docker >/dev/null 2>&1 || die "docker is unavailable"
    [ -n "$image" ] || die "--image is required"
    [ -d "$guest_root" ] && [ ! -L "$guest_root" ] \
        || die "guest root is not an ordinary directory"
    [ -d "$application_output" ] && [ ! -L "$application_output" ] \
        || die "application output is not an ordinary directory"
    [[ "$product" =~ ^[A-Za-z0-9_.-]+$ ]] || die "invalid/missing product"
    guest_root=$(CDPATH= cd -- "$guest_root" && pwd -P)
    application_output=$(CDPATH= cd -- "$application_output" && pwd -P)
    [ -x "$guest_root/machorun" ] || die "guest root has no machorun"
    [ -x "$application_output/$product.app/$product" ] \
        || die "application executable is missing"
    docker inspect "$name" >/dev/null 2>&1 \
        && die "container already exists: $name"
    image_id=$(docker image inspect --format '{{.Id}}' "$image" 2>/dev/null) \
        || die "runtime image is unavailable: $image"
    docker run -d --platform linux/arm64 --name "$name" \
        -p "127.0.0.1:${port}:6080" \
        -e "OPENUIKIT_LIVE_PRODUCT=$product" \
        -e "OPENUIKIT_LIVE_SCALE=$scale" \
        -e "OPENUIKIT_LIVE_SCRIPTED_PROOF=$scripted_proof" \
        -v "$guest_root:/guest-root:ro" \
        -v "$application_output:/application:ro" \
        "$image" >/dev/null
    for _ in $(seq 1 1200); do
        docker exec "$name" test -s /run/openui-live/ready.env 2>/dev/null && break
        [ "$(docker inspect --format '{{.State.Running}}' "$name" 2>/dev/null || true)" = true ] \
            || { docker logs "$name" >&2 || true; die "live container exited during startup"; }
        sleep 0.05
    done
    docker exec "$name" test -s /run/openui-live/ready.env \
        || { docker logs "$name" >&2 || true; die "live container did not become ready"; }
    health
}

case "$mode" in
    build-image) build_image ;;
    launch) launch ;;
    health) health ;;
    url) print_url "$port" ;;
    stop)
        command -v docker >/dev/null 2>&1 || die "docker is unavailable"
        docker inspect "$name" >/dev/null 2>&1 || die "container does not exist: $name"
        docker rm -f "$name" >/dev/null
        echo "OPENUI_LIVE_STOP_OK container=$name"
        ;;
    *) usage ;;
esac
