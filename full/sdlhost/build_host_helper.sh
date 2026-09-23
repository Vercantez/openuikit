#!/usr/bin/env bash
# Build Linux libOpenSDLHost.so: the SDL window / event loop / texture upload
# of the interactive Mach-O guest host (host_full). Same recipe shape as
# full/urltransport/build_host_helper.sh. The Darwin half
# (OpenSDLHostBridge.c -> libOpenSDLHost.dylib) is built by build_full.sh.

set -euo pipefail

W=''
HOST_DIR=''
INCLUDE_DIR=''

usage() {
    echo "usage: build_host_helper.sh --repo ROOT --host-dir DIR [--include-dir DIR]" >&2
    exit 2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo)
            [ "$#" -ge 2 ] || usage
            W=$2; shift 2 ;;
        --host-dir)
            [ "$#" -ge 2 ] || usage
            HOST_DIR=$2; shift 2 ;;
        --include-dir)
            [ "$#" -ge 2 ] || usage
            INCLUDE_DIR=$2; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo "build_host_helper.sh: unknown option $1" >&2
            usage ;;
    esac
done

[ -n "$W" ] && [ -n "$HOST_DIR" ] || usage
[ -n "$INCLUDE_DIR" ] || INCLUDE_DIR=$W/full/sdlhost/include

mkdir -p "$HOST_DIR"
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$INCLUDE_DIR" -shared \
    "$W/full/sdlhost/OpenSDLHost.c" \
    -o "$HOST_DIR/libOpenSDLHost.so" -lSDL2 -ldl
