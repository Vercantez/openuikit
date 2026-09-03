#!/usr/bin/env bash
# Build Linux libOpenURLTransportHost.so.
# Clang flags stay byte-identical to the host -shared recipe in
# full/frameworks/build_core_guest_package.sh and
# full/xcodeplan/build_true_ios_platform_frameworks.sh. Darwin dylib,
# host tests, and attestation stay in those lanes.

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
[ -n "$INCLUDE_DIR" ] || INCLUDE_DIR=$W/full/urltransport/include

mkdir -p "$HOST_DIR"
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$INCLUDE_DIR" -shared \
    "$W/full/urltransport/OpenURLTransportHost.c" \
    -o "$HOST_DIR/libOpenURLTransportHost.so" -lcurl -pthread
