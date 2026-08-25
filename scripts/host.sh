#!/bin/sh
# Launch the SDL2 live host (openhost) on a scene, from anywhere.
#
#   scripts/host.sh                          # demo_settings, interactive
#   scripts/host.sh fixtures/scenes/foo.json # any scene
#   scripts/host.sh --demo                   # scripted demo run (records
#                                            # frames to out_host/)
#   scripts/host.sh --nav-demo               # navigation demo (push/pop,
#                                            # back-swipe), interactive
#   scripts/host.sh --nav-demo --script scripts/nav_push.json --record out_host
#
# Extra arguments pass through to openhost (--scale N, --script/--record).
# Requires SDL2: brew install sdl2 (macOS) / apt install libsdl2-dev (Linux).
set -e
cd "$(dirname "$0")/.."

swift build -c release --product openhost

if [ "$1" = "--demo" ]; then
    shift
    exec env OPENUIKIT_BACKEND=quartz .build/release/openhost \
        fixtures/scenes/demo_settings.json \
        --script scripts/demo_interaction.json --record out_host "$@"
fi

if [ $# -eq 0 ]; then
    set -- fixtures/scenes/demo_settings.json
fi
exec env OPENUIKIT_BACKEND=quartz .build/release/openhost "$@"
