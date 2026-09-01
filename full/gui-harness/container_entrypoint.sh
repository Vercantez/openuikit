#!/usr/bin/env bash
# Runtime half of the graphical Linux evaluation harness. It exposes one SDL
# application window through a localhost-bound noVNC port on the Docker host.

set -Eeuo pipefail

die() {
    echo "openplatform-gui-entrypoint: $*" >&2
    exit 1
}

product=${OPENPLATFORM_PRODUCT:-openhost}
app=${OPENPLATFORM_APP:-showcase}
scale=${OPENPLATFORM_SCALE:-1}
display_number=${OPENPLATFORM_DISPLAY_NUMBER:-99}
screen=${OPENPLATFORM_X11_SCREEN:-1280x960x24}
novnc_port=${OPENPLATFORM_NOVNC_PORT:-6080}
vnc_port=${OPENPLATFORM_VNC_PORT:-5900}

[[ "$product" =~ ^[A-Za-z0-9_.-]+$ ]] || die "invalid product name"
[[ "$app" =~ ^[A-Za-z0-9_.-]+$ ]] || die "invalid app name"
[[ "$scale" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "invalid scale"
[[ "$display_number" =~ ^[0-9]+$ ]] || die "invalid display number"
[[ "$novnc_port" =~ ^[0-9]+$ ]] || die "invalid noVNC port"
[[ "$vnc_port" =~ ^[0-9]+$ ]] || die "invalid VNC port"

binary="/opt/application/.build/release/${product}"
[ -x "$binary" ] || die "built product is missing: $binary"
[ -f /opt/openplatform/source-provenance.tsv ] \
    || die "source provenance is missing"

source_commit=$(awk -F '\t' '$1 == "commit" { print $2 }' \
    /opt/openplatform/source-provenance.tsv)
source_tree=$(awk -F '\t' '$1 == "tree" { print $2 }' \
    /opt/openplatform/source-provenance.tsv)
[[ "$source_commit" =~ ^[0-9a-f]{40}$ ]] || die "invalid source commit provenance"
[[ "$source_tree" =~ ^[0-9a-f]{40}$ ]] || die "invalid source tree provenance"

runtime=/run/openplatform
display=":${display_number}"
mkdir -p "$runtime"
rm -f "/tmp/.X${display_number}-lock" "/tmp/.X11-unix/X${display_number}"

pids=()
cleanup() {
    local pid
    for pid in "${pids[@]:-}"; do
        kill "$pid" 2>/dev/null || true
    done
    wait 2>/dev/null || true
}
trap cleanup EXIT HUP INT TERM

Xvfb "$display" -screen 0 "$screen" -nolisten tcp -ac \
    >"$runtime/xvfb.log" 2>&1 &
xvfb_pid=$!
pids+=("$xvfb_pid")

for _ in $(seq 1 100); do
    DISPLAY="$display" xdpyinfo >/dev/null 2>&1 && break
    kill -0 "$xvfb_pid" 2>/dev/null || die "Xvfb exited during startup"
    sleep 0.05
done
DISPLAY="$display" xdpyinfo >/dev/null || die "Xvfb did not become ready"

x11vnc -display "$display" -forever -shared -nopw -localhost \
    -rfbport "$vnc_port" -o "$runtime/x11vnc.log" &
vnc_pid=$!
pids+=("$vnc_pid")

for _ in $(seq 1 100); do
    bash -c "</dev/tcp/127.0.0.1/${vnc_port}" 2>/dev/null && break
    kill -0 "$vnc_pid" 2>/dev/null || die "x11vnc exited during startup"
    sleep 0.05
done
bash -c "</dev/tcp/127.0.0.1/${vnc_port}" 2>/dev/null \
    || die "x11vnc did not become ready"

websockify --web=/usr/share/novnc "$novnc_port" "127.0.0.1:${vnc_port}" \
    >"$runtime/websockify.log" 2>&1 &
websockify_pid=$!
pids+=("$websockify_pid")

export DISPLAY="$display"
export SDL_VIDEODRIVER=x11
export SDL_AUDIODRIVER=dummy
export OPENUIKIT_BACKEND=${OPENUIKIT_BACKEND:-quartz}
export OPENUIKIT_FONT_DIR=/opt/openplatform/fonts

cd /opt/application
"$binary" --app "$app" --scale "$scale" &
app_pid=$!
pids+=("$app_pid")

window_id=
for _ in $(seq 1 300); do
    window_id=$(xdotool search --onlyvisible --name "^${app}_app$" \
        2>/dev/null | head -n 1 || true)
    [ -n "$window_id" ] && break
    kill -0 "$app_pid" 2>/dev/null || {
        wait "$app_pid" || true
        die "application exited before creating its SDL window"
    }
    kill -0 "$websockify_pid" 2>/dev/null \
        || die "websockify exited during startup"
    sleep 0.05
done
[ -n "$window_id" ] || die "SDL window did not become visible"

import -window "$window_id" "$runtime/initial.png"
identify "$runtime/initial.png" >"$runtime/initial-image.txt"
initial_sha=$(sha256sum "$runtime/initial.png" | awk '{print $1}')

ready_tmp="$runtime/ready.env.tmp"
{
    printf 'SOURCE_COMMIT=%s\n' "$source_commit"
    printf 'SOURCE_TREE=%s\n' "$source_tree"
    printf 'PRODUCT=%s\n' "$product"
    printf 'APP=%s\n' "$app"
    printf 'DISPLAY=%s\n' "$display"
    printf 'WINDOW_ID=%s\n' "$window_id"
    printf 'XVFB_PID=%s\n' "$xvfb_pid"
    printf 'VNC_PID=%s\n' "$vnc_pid"
    printf 'WEBSOCKIFY_PID=%s\n' "$websockify_pid"
    printf 'APP_PID=%s\n' "$app_pid"
    printf 'INITIAL_PIXEL_SHA256=%s\n' "$initial_sha"
} >"$ready_tmp"
mv "$ready_tmp" "$runtime/ready.env"

echo "OPENPLATFORM_GUI_READY app=${app} window=${window_id} pixels=${initial_sha} commit=${source_commit}"
wait "$app_pid"
