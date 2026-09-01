#!/usr/bin/env bash
# Linux runtime for one already-built, unchanged ARM64 Mach-O UIKit .app.
# The container owns display/transport state; app and guest root are read-only.

set -Eeuo pipefail

die() {
    echo "openui-live-container: $*" >&2
    exit 2
}

product=${OPENUIKIT_LIVE_PRODUCT:-}
scale=${OPENUIKIT_LIVE_SCALE:-1}
display_number=${OPENUIKIT_LIVE_DISPLAY_NUMBER:-99}
screen=${OPENUIKIT_LIVE_X11_SCREEN:-1280x960x24}
novnc_port=${OPENUIKIT_LIVE_NOVNC_PORT:-6080}
vnc_port=${OPENUIKIT_LIVE_VNC_PORT:-5900}
scripted_proof=${OPENUIKIT_LIVE_SCRIPTED_PROOF:-0}
frame_capacity=${OPENUIKIT_LIVE_FRAME_CAPACITY:-67108864}
input_capacity=${OPENUIKIT_LIVE_INPUT_CAPACITY:-256}

[[ "$product" =~ ^[A-Za-z0-9_.-]+$ ]] || die "invalid/missing product"
[[ "$scale" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "invalid live scale"
[[ "$display_number" =~ ^[0-9]+$ ]] || die "invalid display number"
[[ "$novnc_port" =~ ^[0-9]+$ ]] || die "invalid noVNC port"
[[ "$vnc_port" =~ ^[0-9]+$ ]] || die "invalid VNC port"
[[ "$frame_capacity" =~ ^[0-9]+$ ]] || die "invalid frame capacity"
[[ "$input_capacity" =~ ^[0-9]+$ ]] || die "invalid input capacity"
case "$scripted_proof" in 0|1) ;; *) die "scripted proof must be 0 or 1" ;; esac

guest_root=/guest-root
application_root=/application
app=$application_root/$product.app
executable=$app/$product
runtime=/run/openui-live
transport=$runtime/transport-v1.bin
display=:$display_number
host=/opt/openui-live/host/openui-live-sdl-host

[ -d "$guest_root" ] && [ ! -L "$guest_root" ] \
    || die "guest root mount is missing"
[ -d "$app" ] && [ ! -L "$app" ] || die "application bundle is missing: $app"
[ -f "$executable" ] && [ ! -L "$executable" ] && [ -x "$executable" ] \
    || die "application executable is missing: $executable"
[ -x "$guest_root/machorun" ] || die "machorun is missing"
[ -x "$host" ] || die "native SDL host is missing"
[ -f /opt/openui-live/source-provenance.tsv ] \
    || die "support source provenance is missing"

support_commit=$(awk -F '\t' '$1 == "commit" { print $2 }' \
    /opt/openui-live/source-provenance.tsv)
support_tree=$(awk -F '\t' '$1 == "tree" { print $2 }' \
    /opt/openui-live/source-provenance.tsv)
[[ "$support_commit" =~ ^[0-9a-f]{40}$ ]] || die "invalid support commit"
[[ "$support_tree" =~ ^[0-9a-f]{40}$ ]] || die "invalid support tree"

helpers=(
    libOpenDispatchHost.so
    libOpenFoundationInternationalizationHost.so
    libOpenURLTransportHost.so
    libOpenRelativeTimeHost.so
    libOpenCompressionHost.so
    libOpenZlibHost.so
)
preloads=()
for helper in "${helpers[@]}"; do
    path=$guest_root/host/$helper
    [ -f "$path" ] && [ ! -L "$path" ] \
        || die "runtime helper is missing: $helper"
    preloads+=("$path")
done
preload=$(IFS=:; echo "${preloads[*]}")

mkdir "$runtime"
[ ! -e "$transport" ] && [ ! -L "$transport" ] \
    || die "transport path unexpectedly exists"
rm -f "/tmp/.X${display_number}-lock" "/tmp/.X11-unix/X${display_number}"

pids=()
cleanup() {
    local pid
    for pid in "${pids[@]:-}"; do kill "$pid" 2>/dev/null || true; done
    wait 2>/dev/null || true
}
trap cleanup EXIT HUP INT TERM

Xvfb "$display" -screen 0 "$screen" -nolisten tcp -ac \
    >"$runtime/xvfb.log" 2>&1 &
xvfb_pid=$!
pids+=("$xvfb_pid")
for _ in $(seq 1 200); do
    DISPLAY="$display" xdpyinfo >/dev/null 2>&1 && break
    kill -0 "$xvfb_pid" 2>/dev/null || die "Xvfb exited during startup"
    sleep 0.05
done
DISPLAY="$display" xdpyinfo >/dev/null || die "Xvfb did not become ready"

x11vnc -display "$display" -forever -shared -nopw -localhost \
    -rfbport "$vnc_port" -o "$runtime/x11vnc.log" &
vnc_pid=$!
pids+=("$vnc_pid")
for _ in $(seq 1 200); do
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

DISPLAY="$display" SDL_VIDEODRIVER=x11 SDL_AUDIODRIVER=dummy \
    "$host" --transport "$transport" --create \
    --title "Portable UIKit - $product" \
    --frame-capacity "$frame_capacity" --input-capacity "$input_capacity" \
    >"$runtime/live-host.log" 2>&1 &
host_pid=$!
pids+=("$host_pid")
for _ in $(seq 1 200); do
    [ -f "$transport" ] && break
    kill -0 "$host_pid" 2>/dev/null || die "native SDL host exited during startup"
    sleep 0.05
done
[ -f "$transport" ] || die "native SDL host did not create transport"

(
    cd "$app"
    LD_LIBRARY_PATH="$guest_root/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$preload${LD_PRELOAD:+:$LD_PRELOAD}" \
    MACHORUN_ROOT="$guest_root" \
    OPENUIKIT_LIVE_TRANSPORT="$transport" \
    OPENUIKIT_LIVE_SCALE="$scale" \
        "$guest_root/machorun" "$executable"
) >"$runtime/guest.log" 2>&1 &
guest_pid=$!
pids+=("$guest_pid")

window_id=
for _ in $(seq 1 1200); do
    window_id=$(DISPLAY="$display" xdotool search --onlyvisible \
        --name "^Portable UIKit - ${product}$" 2>/dev/null | head -n 1 || true)
    [ -n "$window_id" ] && grep -q '^OPENUIKIT_LIVE_FRAME ' \
        "$runtime/live-host.log" && break
    kill -0 "$guest_pid" 2>/dev/null || {
        wait "$guest_pid" || true
        tail -100 "$runtime/guest.log" >&2 || true
        die "Mach-O guest exited before its first live frame"
    }
    kill -0 "$host_pid" 2>/dev/null || die "native SDL host exited before first frame"
    sleep 0.05
done
[ -n "$window_id" ] || die "live SDL window did not become visible"
grep -q '^OPENUIKIT_LIVE_FRAME ' "$runtime/live-host.log" \
    || die "Mach-O guest published no live frame"

capture() {
    local name=$1
    DISPLAY="$display" import -window "$window_id" "$runtime/$name.png"
    identify "$runtime/$name.png" >"$runtime/$name-image.txt"
    sha256sum "$runtime/$name.png" | awk '{print $1}'
}

initial_sha=$(capture initial)
clicked_sha=-
typed_sha=-
if [ "$scripted_proof" -eq 1 ]; then
    DISPLAY="$display" xdotool mousemove --window "$window_id" 139 220 click 1
    sleep 0.35
    clicked_sha=$(capture clicked)
    [ "$clicked_sha" != "$initial_sha" ] \
        || die "button click did not change the framebuffer"

    DISPLAY="$display" xdotool mousemove --window "$window_id" 150 336 click 1
    DISPLAY="$display" xdotool type --window "$window_id" --delay 35 'Linux UIKit'
    sleep 0.45
    typed_sha=$(capture typed)
    [ "$typed_sha" != "$clicked_sha" ] \
        || die "typed input did not change the framebuffer"
    input_count=$(grep -c '^OPENUIKIT_LIVE_INPUT ' "$runtime/live-host.log" || true)
    [ "$input_count" -ge 5 ] \
        || die "scripted click/type proof published too few input records: $input_count"
fi

frame_sequence=$(awk '/^OPENUIKIT_LIVE_FRAME / {
    for (i = 1; i <= NF; i++) if ($i ~ /^sequence=/) { sub(/^sequence=/, "", $i); value=$i }
} END { print value }' "$runtime/live-host.log")
input_sequence=$(awk '/^OPENUIKIT_LIVE_INPUT / {
    for (i = 1; i <= NF; i++) if ($i ~ /^sequence=/) { sub(/^sequence=/, "", $i); value=$i }
} END { print value + 0 }' "$runtime/live-host.log")

{
    printf 'format\topenui-live-runtime-proof-v1\n'
    printf 'support_commit\t%s\n' "$support_commit"
    printf 'support_tree\t%s\n' "$support_tree"
    printf 'product\t%s\n' "$product"
    printf 'executable_sha256\t%s\n' "$(sha256sum "$executable" | awk '{print $1}')"
    printf 'machorun_sha256\t%s\n' "$(sha256sum "$guest_root/machorun" | awk '{print $1}')"
    printf 'initial_pixel_sha256\t%s\n' "$initial_sha"
    printf 'clicked_pixel_sha256\t%s\n' "$clicked_sha"
    printf 'typed_pixel_sha256\t%s\n' "$typed_sha"
    printf 'frame_sequence\t%s\n' "$frame_sequence"
    printf 'input_sequence\t%s\n' "$input_sequence"
    printf 'scripted_proof\t%s\n' "$scripted_proof"
} >"$runtime/proof.tsv"

ready_tmp=$runtime/ready.env.tmp
{
    printf 'SUPPORT_COMMIT=%s\n' "$support_commit"
    printf 'SUPPORT_TREE=%s\n' "$support_tree"
    printf 'PRODUCT=%s\n' "$product"
    printf 'DISPLAY=%s\n' "$display"
    printf 'WINDOW_ID=%s\n' "$window_id"
    printf 'XVFB_PID=%s\n' "$xvfb_pid"
    printf 'VNC_PID=%s\n' "$vnc_pid"
    printf 'WEBSOCKIFY_PID=%s\n' "$websockify_pid"
    printf 'HOST_PID=%s\n' "$host_pid"
    printf 'GUEST_PID=%s\n' "$guest_pid"
} >"$ready_tmp"
mv "$ready_tmp" "$runtime/ready.env"

echo "OPENUIKIT_LIVE_CONTAINER_READY product=$product window=$window_id pixels=$typed_sha commit=$support_commit"
wait "$guest_pid"
