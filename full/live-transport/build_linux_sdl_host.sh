#!/usr/bin/env bash
# Build the native side of the live UIKit transport without touching any app
# or vendor checkout. The output directory must not already exist.

set -Eeuo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

die() {
    echo "openui-live-host-build: $*" >&2
    exit 2
}

usage() {
    echo "usage: $0 --output-root ABSOLUTE_NONEXISTENT_DIRECTORY" >&2
    exit 2
}

output=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --output-root) [ "$#" -ge 2 ] || usage; output=$2; shift 2 ;;
        *) usage ;;
    esac
done
case "$output" in /*) ;; *) usage ;; esac
[ "$(uname -s)" = Linux ] \
    || die "native display host production build requires Linux"
[ ! -e "$output" ] && [ ! -L "$output" ] \
    || die "output root already exists: $output"
for tool in clang pkg-config sha256sum file; do
    command -v "$tool" >/dev/null 2>&1 || die "required tool is missing: $tool"
done
pkg-config --exists sdl2 || die "SDL2 development package is unavailable"

mkdir "$output"
compiler=$(command -v clang)
compiler=$(python3 -B - "$compiler" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve(strict=True))
PY
)

# pkg-config output is a compiler/linker argument language. SDL's supported
# flags contain no shell quoting on the target Linux images; reject anything
# outside that deliberately narrow shape before word splitting it into arrays.
cflags_text=$(pkg-config --cflags sdl2)
libs_text=$(pkg-config --libs sdl2)
case "$cflags_text $libs_text" in
    *[!A-Za-z0-9_./+,:=\ -]*) die "SDL2 pkg-config emitted unsafe flags" ;;
esac
read -r -a cflags <<<"$cflags_text"
read -r -a libs <<<"$libs_text"

sources=(
    "$SCRIPT_DIR/OpenUIKitLiveTransportCommon.c"
    "$SCRIPT_DIR/OpenUIKitLiveTransportHost.c"
    "$SCRIPT_DIR/OpenUIKitLiveSDLHost.c"
)
for source in "${sources[@]}"; do
    [ -f "$source" ] && [ ! -L "$source" ] \
        || die "source is not a regular file: $source"
done
headers=(
    "$SCRIPT_DIR/OpenUIKitLiveTransportInternal.h"
    "$SCRIPT_DIR/include/OpenUIKitLiveTransportABI.h"
    "$SCRIPT_DIR/include/OpenUIKitLiveTransportGuest.h"
    "$SCRIPT_DIR/include/OpenUIKitLiveTransportHost.h"
)
for header in "${headers[@]}"; do
    [ -f "$header" ] && [ ! -L "$header" ] \
        || die "header is not a regular file: $header"
done

command=("$compiler" -std=c11 -O2 -Wall -Wextra -Werror
    -fvisibility=hidden -fno-common
    -I "$SCRIPT_DIR/include" -I "$SCRIPT_DIR"
    "${cflags[@]}" "${sources[@]}" "${libs[@]}"
    -o "$output/openui-live-sdl-host")
printf '%s\0' "${command[@]}" >"$output/compile-arguments.nul"
"${command[@]}" >"$output/compile.stdout" 2>"$output/compile.stderr"
[ ! -s "$output/compile.stdout" ] \
    || die "compiler emitted unexpected stdout"
[ ! -s "$output/compile.stderr" ] \
    || die "compiler emitted unexpected stderr"
[ -x "$output/openui-live-sdl-host" ] \
    || die "native SDL host was not produced"
file "$output/openui-live-sdl-host" >"$output/binary-file.txt"

{
    printf 'format\topenui-live-linux-host-v1\n'
    printf 'compiler\t%s\n' "$compiler"
    printf 'compiler_sha256\t%s\n' \
        "$(sha256sum "$compiler" | awk '{print $1}')"
    printf 'sdl2_version\t%s\n' "$(pkg-config --modversion sdl2)"
    printf 'binary_sha256\t%s\n' \
        "$(sha256sum "$output/openui-live-sdl-host" | awk '{print $1}')"
    printf 'arguments_sha256\t%s\n' \
        "$(sha256sum "$output/compile-arguments.nul" | awk '{print $1}')"
    for source in "${sources[@]}" "${headers[@]}"; do
        printf 'input_sha256\t%s\t%s\n' \
            "$(sha256sum "$source" | awk '{print $1}')" \
            "${source#$SCRIPT_DIR/}"
    done
} >"$output/provenance.tsv"

echo "OPENUI_LIVE_LINUX_HOST_BUILD_OK output=$output sha256=$(sha256sum "$output/openui-live-sdl-host" | awk '{print $1}')"
