#!/usr/bin/env bash
# Run a real app (Firefox Focus) from the Mach-O guest in a window you can use
# from the Mac: host_full under machorun inside the arm64 Linux container, on
# an Xvfb display, served to a browser through x11vnc + noVNC.
#
#   bash scripts/ops/guest_interactive.sh [--app focus] [--port 6080] [--tree DIR]
#                                         [--detach] [--no-build] [--stop]
#
# Then open the printed URL (http://localhost:6080/vnc.html?...). Click = tap,
# drag = pan, the Mac keyboard types into the focused field.
#
#   --app NAME    app to run (host_full --app; default focus)
#   --port N      localhost port for noVNC (default 6080; bound to 127.0.0.1)
#   --tree DIR    openuikit checkout or worktree to run (default: this one)
#   --detach      start and return; stop later with --stop
#   --no-build    do not run local_guest_verify.sh's build step first
#   --stop        stop the container for --port
#
# Build: scripts/ops/local_guest_verify.sh (LOCAL_GUEST_SKIP_VERIFY=1) builds
# whatever is stale for the tree, host_full included, and reuses a fresh
# build. Image: openuikit-guest-interactive:arm64 = the guest build image plus
# Xvfb/x11vnc/noVNC (scripts/ops/guest_interactive.Dockerfile), rebuilt when
# either changes.
#
# Environment passed through to the guest host (defaults in brackets):
#   OPENUI_SDL_HOST_WINDOW_SCALE [2]   window pixels per point (1 = 375x667)
#   OPENUI_SDL_HOST_STATS        [1]   fps + input->present latency every 2 s
set -euo pipefail

IMAGE=${GUEST_INTERACTIVE_IMAGE:-openuikit-guest-interactive:arm64}
BASE_IMAGE=${LOCAL_GUEST_IMAGE:-openuikit-guest-env:arm64}

log() { printf '[guest-interactive] %s\n' "$*" >&2; }
die() { printf '[guest-interactive] FAIL: %s\n' "$*" >&2; exit 2; }

# ----------------------------------------------------------- container side --
if [ "${1:-}" = --inside ]; then
    : "${TREE:?}" "${ROOTDIR:?}" "${APP:?}"
    BUILD=$TREE/build/full
    UIKIT=$TREE/uikit
    W_PT=375 H_PT=667
    SCALE=${OPENUI_SDL_HOST_WINDOW_SCALE:-2}
    GEOM="$((W_PT * SCALE))x$((H_PT * SCALE))x24"
    export DISPLAY=:1
    Xvfb :1 -screen 0 "$GEOM" -nolisten tcp -noreset >/tmp/xvfb.log 2>&1 &
    for _ in $(seq 100); do xdotool getdisplaygeometry >/dev/null 2>&1 && break; sleep 0.1; done
    xdotool getdisplaygeometry >/dev/null 2>&1 || { cat /tmp/xvfb.log; die 'Xvfb did not start'; }
    x11vnc -display :1 -forever -shared -nopw -localhost -rfbport 5900 -quiet \
        -noxrecord -noxfixes >/tmp/x11vnc.log 2>&1 &
    websockify --web /usr/share/novnc 6080 localhost:5900 >/tmp/websockify.log 2>&1 &
    log "display :1 $GEOM, VNC :5900, noVNC :6080"
    cd "$UIKIT"
    # The same guest environment linux_guest_realapp_verify.sh gives
    # render_full, plus the window helper.
    exec env MACHORUN_ROOT="$ROOTDIR" LD_LIBRARY_PATH="$BUILD/host" \
        LD_PRELOAD="$BUILD/host/libOpenDispatchHost.so:$BUILD/host/libOpenFoundationInternationalizationHost.so:$BUILD/host/libOpenURLTransportHost.so:$BUILD/host/libOpenRelativeTimeHost.so:$BUILD/host/libOpenSDLHost.so" \
        OPENUIKIT_RESOURCE_ROOT="$UIKIT/Sources/OpenUIKit/Resources" \
        OPENUIKIT_FORCE_IOS=1 OPENUIKIT_REALAPP_SCALE=2 OPENUIKIT_BACKEND=quartz \
        SDL_VIDEODRIVER=x11 OPENUI_SDL_HOST_WINDOW_SCALE="$SCALE" \
        OPENUI_SDL_HOST_STATS="${OPENUI_SDL_HOST_STATS:-1}" \
        "$ROOTDIR/machorun" "$BUILD/host_full" --app "$APP" \
        --assets "$UIKIT/fixtures/realapp/assets"
fi

# ---------------------------------------------------------------- host side --
APP=focus
PORT=6080
TREE=
DETACH=0
BUILD=1
STOP=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --app) APP=${2:?}; shift 2 ;;
        --port) PORT=${2:?}; shift 2 ;;
        --tree) TREE=${2:?}; shift 2 ;;
        --detach) DETACH=1; shift ;;
        --no-build) BUILD=0; shift ;;
        --stop) STOP=1; shift ;;
        -h|--help) sed -n '2,28p' "$0"; exit 0 ;;
        *) die "unknown option $1 (see --help)" ;;
    esac
done
NAME=openuikit-guest-interactive-$PORT
if [ "$STOP" = 1 ]; then
    docker rm -f "$NAME" >/dev/null 2>&1 && log "stopped $NAME" || log "$NAME was not running"
    exit 0
fi

HERE=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
TREE=${TREE:-$(CDPATH= cd -- "$HERE/../.." && pwd -P)}
TREE=$(CDPATH= cd -- "$TREE" && pwd -P)
TREE=$(git -C "$TREE" rev-parse --show-toplevel)
COMMON=$(cd "$TREE" && cd "$(git rev-parse --git-common-dir)" && pwd -P)
MAIN=$(dirname "$COMMON")
SCRATCH=$(CDPATH= cd -- "$MAIN/scratch" && pwd -P)
command -v docker >/dev/null || die 'docker not on PATH'

if [ "$BUILD" = 1 ]; then
    log "building (or reusing) the guest for $TREE"
    LOCAL_GUEST_SKIP_VERIFY=1 bash "$HERE/local_guest_verify.sh" "$TREE"
fi
[ -f "$TREE/build/full/host_full" ] \
    || die "no $TREE/build/full/host_full (build_full skips it without SDL2 headers; run local_guest_verify.sh)"
if [ "$TREE" = "$MAIN" ]; then ROOTDIR=$SCRATCH/mrroot_full; else ROOTDIR=$TREE/build/local-guest/mrroot_full; fi
[ -x "$ROOTDIR/machorun" ] || die "no guest root at $ROOTDIR"

dockerfile=$HERE/guest_interactive.Dockerfile
base_id=$(docker image inspect -f '{{.Id}}' "$BASE_IMAGE" 2>/dev/null) \
    || die "no $BASE_IMAGE image (scripts/ops/local_guest_verify.sh builds it)"
want_label="$(shasum -a 256 "$dockerfile" | cut -d' ' -f1)-$base_id"
have_label=$(docker image inspect -f '{{index .Config.Labels "openuikit.interactive"}}' "$IMAGE" 2>/dev/null || true)
if [ "$want_label" != "$have_label" ]; then
    log "building $IMAGE (Xvfb + x11vnc + noVNC over $BASE_IMAGE)"
    ctx=$(mktemp -d)
    docker build --platform linux/arm64 --build-arg "BASE_IMAGE=$BASE_IMAGE" \
        --label "openuikit.interactive=$want_label" -t "$IMAGE" -f "$dockerfile" "$ctx" >&2
    rmdir "$ctx"
fi

docker rm -f "$NAME" >/dev/null 2>&1 || true
mounts=()
for p in "$TREE" "$MAIN" "$SCRATCH" "$HERE"; do
    case "$p" in "$HOME"|"$HOME"/*) ;; *) mounts+=(-v "$p:$p") ;; esac
done
mounts+=(-v "$HOME:$HOME")
docker run -d --rm --name "$NAME" --platform linux/arm64 "${mounts[@]}" \
    -p "127.0.0.1:$PORT:6080" \
    -e TREE="$TREE" -e ROOTDIR="$ROOTDIR" -e APP="$APP" \
    -e OPENUI_SDL_HOST_WINDOW_SCALE="${OPENUI_SDL_HOST_WINDOW_SCALE:-2}" \
    -e OPENUI_SDL_HOST_STATS="${OPENUI_SDL_HOST_STATS:-1}" \
    "$IMAGE" bash "$HERE/$(basename "${BASH_SOURCE[0]}")" --inside >/dev/null

# Ready = the app launched and noVNC answers.
for _ in $(seq 240); do
    docker logs "$NAME" 2>&1 | grep -q HOST_FULL_LAUNCHED && \
        curl -fsS -o /dev/null "http://127.0.0.1:$PORT/vnc.html" 2>/dev/null && break
    docker inspect "$NAME" >/dev/null 2>&1 || { die "container exited before the app launched"; }
    sleep 0.5
done
docker logs "$NAME" 2>&1 | grep -q HOST_FULL_LAUNCHED \
    || { docker logs "$NAME" 2>&1 | tail -30 >&2; die "the app did not launch within 120 s"; }
URL="http://localhost:$PORT/vnc.html?autoconnect=1&resize=scale&reconnect=1"
docker logs "$NAME" 2>&1 | grep HOST_FULL_LAUNCHED >&2 || true
echo
echo "  Open: $URL"
echo
if [ "$DETACH" = 1 ]; then
    log "running detached as $NAME; logs: docker logs -f $NAME; stop: bash $0 --stop --port $PORT"
    exit 0
fi
log "Ctrl-C stops it (logs follow; sdlhost-stats lines are fps and input->present latency)"
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true; exit 0' INT TERM
docker logs -f "$NAME" 2>&1 || true
docker rm -f "$NAME" >/dev/null 2>&1 || true
