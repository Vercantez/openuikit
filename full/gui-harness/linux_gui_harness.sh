#!/usr/bin/env bash
# Build, launch, health-check and stop a source-pinned SwiftPM GUI application
# in Docker without changing or bind-mounting application/vendor source.

set -Eeuo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
DEFAULT_BASE='swift@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc'

die() {
    echo "linux-gui-harness: $*" >&2
    exit 2
}

usage() {
    cat <<'EOF'
Source-pinned graphical Swift application evaluation on Linux.

Usage:
  linux_gui_harness.sh audit --source DIR --commit SHA --tree SHA
  linux_gui_harness.sh build --source DIR --commit SHA --tree SHA
      [--image TAG] [--product NAME] [--base IMAGE@sha256:DIGEST]
      [--cold] [--enable-cmo]
  linux_gui_harness.sh launch --image IMAGE [--name NAME] [--app NAME]
      [--port PORT] [--scale SCALE] [--backend swift|quartz]
  linux_gui_harness.sh relaunch --image IMAGE [launch options]
  linux_gui_harness.sh health [--name NAME]
  linux_gui_harness.sh url [--port PORT]
  linux_gui_harness.sh stop [--name NAME]

Defaults:
  name=openplatform-gui-live  app=showcase  port=6080  scale=1
  product=openhost  backend=quartz

`build --cold` passes Docker --no-cache. Every build materializes source with
`git archive COMMIT`; working-tree edits and stale .build products cannot enter
the image. `launch` binds noVNC only to 127.0.0.1.
EOF
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "required command is missing: $1"
}

need_value() {
    [ "$#" -ge 2 ] && [ -n "$2" ] || die "$1 requires a value"
}

command_name=${1:-help}
[ "$#" -eq 0 ] || shift
case "$command_name" in
    -h|--help) usage; exit 0 ;;
esac

source_dir=
source_commit=
source_tree=
image=
product=openhost
base_image=$DEFAULT_BASE
container_name=openplatform-gui-live
app=showcase
port=6080
scale=1
backend=quartz
cold=0
disable_cmo=1

while [ "$#" -gt 0 ]; do
    case "$1" in
        --source) need_value "$@"; source_dir=$2; shift 2 ;;
        --commit) need_value "$@"; source_commit=$2; shift 2 ;;
        --tree) need_value "$@"; source_tree=$2; shift 2 ;;
        --image) need_value "$@"; image=$2; shift 2 ;;
        --product) need_value "$@"; product=$2; shift 2 ;;
        --base) need_value "$@"; base_image=$2; shift 2 ;;
        --name) need_value "$@"; container_name=$2; shift 2 ;;
        --app) need_value "$@"; app=$2; shift 2 ;;
        --port) need_value "$@"; port=$2; shift 2 ;;
        --scale) need_value "$@"; scale=$2; shift 2 ;;
        --backend) need_value "$@"; backend=$2; shift 2 ;;
        --cold) cold=1; shift ;;
        --enable-cmo) disable_cmo=0; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

validate_runtime_options() {
    [[ "$container_name" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] \
        || die "invalid container name: $container_name"
    [[ "$app" =~ ^[A-Za-z0-9_.-]+$ ]] || die "invalid app name: $app"
    [[ "$product" =~ ^[A-Za-z0-9_.-]+$ ]] \
        || die "invalid product name: $product"
    [[ "$port" =~ ^[0-9]+$ ]] || die "port must be numeric"
    [ "$port" -ge 1024 ] && [ "$port" -le 65535 ] \
        || die "port must be between 1024 and 65535"
    [[ "$scale" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "invalid scale: $scale"
    awk -v value="$scale" 'BEGIN { exit !(value > 0) }' \
        || die "scale must be greater than zero"
    case "$backend" in swift|quartz) ;; *) die "backend must be swift or quartz" ;; esac
}

audit_source() {
    require_command git
    [ -n "$source_dir" ] || die "--source is required"
    [ -n "$source_commit" ] || die "--commit is required"
    [ -n "$source_tree" ] || die "--tree is required"
    [[ "$source_commit" =~ ^[0-9a-f]{40}$ ]] \
        || die "commit must be a full lowercase 40-hex object ID"
    [[ "$source_tree" =~ ^[0-9a-f]{40}$ ]] \
        || die "tree must be a full lowercase 40-hex object ID"
    [ -d "$source_dir" ] || die "source directory does not exist: $source_dir"
    source_dir=$(CDPATH= cd -- "$source_dir" && pwd -P)
    git -C "$source_dir" cat-file -e "${source_commit}^{commit}" 2>/dev/null \
        || die "commit is not present in source repository: $source_commit"
    actual_commit=$(git -C "$source_dir" rev-parse "${source_commit}^{commit}")
    [ "$actual_commit" = "$source_commit" ] || die "commit identity drifted"
    actual_tree=$(git -C "$source_dir" rev-parse "${source_commit}^{tree}")
    [ "$actual_tree" = "$source_tree" ] \
        || die "tree mismatch: expected $source_tree, commit owns $actual_tree"
    submodules=$(git -C "$source_dir" ls-tree -r "$source_commit" \
        | awk '$1 == "160000" { print $4 }')
    [ -z "$submodules" ] \
        || die "gitlink/submodule source is not materialized by this harness: $submodules"
    tracked_files=$(git -C "$source_dir" ls-tree -r --name-only "$source_commit" \
        | wc -l | tr -d '[:space:]')
    [ "$tracked_files" -gt 0 ] || die "source commit contains no tracked files"
    printf 'GUI_SOURCE_AUDIT_OK\tcommit=%s\ttree=%s\ttracked-files=%s\trepository=%s\n' \
        "$source_commit" "$source_tree" "$tracked_files" "$source_dir"
}

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

build_image() {
    require_command docker
    require_command tar
    audit_source
    [[ "$base_image" =~ @sha256:[0-9a-f]{64}$ ]] \
        || die "--base must be pinned by a sha256 repository digest"
    [ "$disable_cmo" = 0 ] || [ "$disable_cmo" = 1 ] \
        || die "invalid CMO setting"
    validate_runtime_options
    [ -n "$image" ] || image="openplatform-gui:${source_commit:0:12}"

    tmp_parent=${TMPDIR:-/tmp}
    tmp_parent=${tmp_parent%/}
    context=$(mktemp -d "${tmp_parent}/openplatform-gui-build.XXXXXX")
    cleanup_context() {
        [ -n "${context:-}" ] || return 0
        case "$context" in
            "${tmp_parent}"/openplatform-gui-build.*)
                if [ -x /usr/bin/trash ]; then
                    /usr/bin/trash "$context"
                else
                    rm -rf -- "$context"
                fi
                ;;
            *) echo "linux-gui-harness: refusing unsafe cleanup: $context" >&2 ;;
        esac
        context=
    }
    trap cleanup_context EXIT HUP INT TERM

    mkdir -p "$context/source"
    git -C "$source_dir" archive --format=tar \
        --output="$context/source.tar" "$source_commit"
    archive_sha=$(sha256_file "$context/source.tar")
    tar -xf "$context/source.tar" -C "$context/source"
    rm -f "$context/source.tar"
    cp "$SCRIPT_DIR/Dockerfile" "$context/Dockerfile"
    cp "$SCRIPT_DIR/container_entrypoint.sh" "$context/container_entrypoint.sh"
    {
        printf 'commit\t%s\n' "$source_commit"
        printf 'tree\t%s\n' "$source_tree"
        printf 'tracked-files\t%s\n' "$tracked_files"
        printf 'archive-sha256\t%s\n' "$archive_sha"
    } >"$context/source-provenance.tsv"

    build=(docker build --progress=plain)
    [ "$cold" = 0 ] || build+=(--no-cache)
    build+=(
        --build-arg "SWIFT_BASE=$base_image"
        --build-arg "SOURCE_COMMIT=$source_commit"
        --build-arg "SOURCE_TREE=$source_tree"
        --build-arg "SOURCE_ARCHIVE_SHA256=$archive_sha"
        --build-arg "SOURCE_TRACKED_FILES=$tracked_files"
        --build-arg "PRODUCT=$product"
        --build-arg "DISABLE_CMO=$disable_cmo"
        --tag "$image"
        "$context"
    )
    "${build[@]}"

    image_id=$(docker image inspect --format '{{.Id}}' "$image")
    image_commit=$(docker image inspect --format \
        '{{index .Config.Labels "org.opencontainers.image.revision"}}' "$image")
    image_tree=$(docker image inspect --format \
        '{{index .Config.Labels "org.opencontainers.image.source-tree"}}' "$image")
    [ "$image_commit" = "$source_commit" ] || die "built image commit label drifted"
    [ "$image_tree" = "$source_tree" ] || die "built image tree label drifted"
    printf 'GUI_IMAGE_BUILD_OK\timage=%s\tid=%s\tcommit=%s\ttree=%s\tarchive=%s\tcold=%s\n' \
        "$image" "$image_id" "$source_commit" "$source_tree" "$archive_sha" "$cold"

    cleanup_context
    trap - EXIT HUP INT TERM
}

container_exists() {
    docker inspect "$container_name" >/dev/null 2>&1
}

container_running() {
    [ "$(docker inspect --format '{{.State.Running}}' "$container_name" \
        2>/dev/null || true)" = true ]
}

published_port() {
    binding=$(docker port "$container_name" 6080/tcp 2>/dev/null | head -n 1)
    [ -n "$binding" ] || die "container publishes no noVNC port"
    case "$binding" in
        127.0.0.1:*) printf '%s\n' "${binding##*:}" ;;
        *) die "noVNC is not bound to localhost: $binding" ;;
    esac
}

print_url() {
    printf 'http://127.0.0.1:%s/vnc.html?autoconnect=1&resize=scale\n' "$1"
}

health_gate() {
    require_command docker
    require_command curl
    container_running || die "container is not running: $container_name"
    docker exec "$container_name" test -s /run/openplatform/ready.env \
        || die "container has no readiness record"
    ready=$(docker exec "$container_name" cat /run/openplatform/ready.env)
    ready_value() {
        printf '%s\n' "$ready" | awk -F= -v key="$1" '$1 == key { print $2 }'
    }
    ready_commit=$(ready_value SOURCE_COMMIT)
    ready_tree=$(ready_value SOURCE_TREE)
    ready_window=$(ready_value WINDOW_ID)
    ready_display=$(ready_value DISPLAY)
    ready_app=$(ready_value APP)
    [[ "$ready_commit" =~ ^[0-9a-f]{40}$ ]] || die "invalid ready commit"
    [[ "$ready_tree" =~ ^[0-9a-f]{40}$ ]] || die "invalid ready tree"
    [[ "$ready_window" =~ ^[0-9]+$ ]] || die "invalid ready window"

    label_commit=$(docker inspect --format \
        '{{index .Config.Labels "org.opencontainers.image.revision"}}' \
        "$container_name")
    label_tree=$(docker inspect --format \
        '{{index .Config.Labels "org.opencontainers.image.source-tree"}}' \
        "$container_name")
    [ "$label_commit" = "$ready_commit" ] || die "runtime/image commit mismatch"
    [ "$label_tree" = "$ready_tree" ] || die "runtime/image tree mismatch"

    docker exec "$container_name" bash -lc \
        'source /run/openplatform/ready.env; kill -0 "$XVFB_PID"; kill -0 "$VNC_PID"; kill -0 "$WEBSOCKIFY_PID"; kill -0 "$APP_PID"' \
        || die "one or more display/application processes exited"
    docker exec "$container_name" env DISPLAY="$ready_display" \
        xwininfo -id "$ready_window" >/dev/null \
        || die "SDL window is not visible"
    docker exec "$container_name" env DISPLAY="$ready_display" \
        import -window "$ready_window" /run/openplatform/health.png
    dimensions=$(docker exec "$container_name" identify -format '%wx%h' \
        /run/openplatform/health.png)
    pixel_sha=$(docker exec "$container_name" sha256sum \
        /run/openplatform/health.png | awk '{print $1}')
    deviation=$(docker exec "$container_name" convert \
        /run/openplatform/health.png -format '%[fx:standard_deviation]' info:)
    awk -v value="$deviation" 'BEGIN { exit !(value > 0) }' \
        || die "captured SDL window is a uniform framebuffer"

    live_port=$(published_port)
    url=$(print_url "$live_port")
    html_bytes=$(curl --fail --silent --show-error --max-time 5 "$url" | wc -c \
        | tr -d '[:space:]')
    [ "$html_bytes" -gt 1000 ] || die "noVNC HTML health response is too small"
    image_id=$(docker inspect --format '{{.Image}}' "$container_name")
    printf 'GUI_HEALTH_OK\tcontainer=%s\timage=%s\tapp=%s\twindow=%s\tdimensions=%s\tpixels=%s\thtml-bytes=%s\tcommit=%s\ttree=%s\turl=%s\n' \
        "$container_name" "$image_id" "$ready_app" "$ready_window" \
        "$dimensions" "$pixel_sha" "$html_bytes" "$ready_commit" \
        "$ready_tree" "$url"
}

launch_container() {
    require_command docker
    validate_runtime_options
    [ -n "$image" ] || die "--image is required"
    container_exists && die "container already exists; use relaunch or stop: $container_name"
    image_id=$(docker image inspect --format '{{.Id}}' "$image" 2>/dev/null) \
        || die "image does not exist: $image"
    image_commit=$(docker image inspect --format \
        '{{index .Config.Labels "org.opencontainers.image.revision"}}' "$image")
    image_tree=$(docker image inspect --format \
        '{{index .Config.Labels "org.opencontainers.image.source-tree"}}' "$image")
    [[ "$image_commit" =~ ^[0-9a-f]{40}$ ]] || die "image lacks exact commit label"
    [[ "$image_tree" =~ ^[0-9a-f]{40}$ ]] || die "image lacks exact tree label"

    docker run -d \
        --name "$container_name" \
        -p "127.0.0.1:${port}:6080" \
        -e "OPENPLATFORM_PRODUCT=$product" \
        -e "OPENPLATFORM_APP=$app" \
        -e "OPENPLATFORM_SCALE=$scale" \
        -e "OPENUIKIT_BACKEND=$backend" \
        "$image_id" >/dev/null

    ready=0
    for _ in $(seq 1 600); do
        if docker exec "$container_name" test -s /run/openplatform/ready.env \
            >/dev/null 2>&1; then
            ready=1
            break
        fi
        container_running || break
        sleep 0.1
    done
    if [ "$ready" != 1 ]; then
        docker logs "$container_name" >&2 || true
        die "container did not become ready"
    fi
    health_gate
}

stop_container() {
    require_command docker
    validate_runtime_options
    if container_exists; then
        docker rm -f "$container_name" >/dev/null
        echo "GUI_STOP_OK container=$container_name"
    else
        echo "GUI_STOP_OK container=$container_name already-absent"
    fi
}

case "$command_name" in
    help) usage ;;
    audit) audit_source ;;
    build) build_image ;;
    launch) launch_container ;;
    relaunch)
        require_command docker
        validate_runtime_options
        container_exists && docker rm -f "$container_name" >/dev/null
        launch_container
        ;;
    health)
        validate_runtime_options
        health_gate
        ;;
    url)
        validate_runtime_options
        print_url "$port"
        ;;
    stop) stop_container ;;
    *) usage >&2; die "unknown command: $command_name" ;;
esac
