#!/usr/bin/env bash
# Focused live regression for Docker Desktop's nested-mount disappearance.
# It stages and links a minimal libSystem/libc++/libquartz chain inside the one
# physical replay bind, churns a real tmpfs /tmp between links, exits Docker,
# and then proves the linked guest root is still host-visible.

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
PHYSICAL_REPLAY_TOOL=$SCRIPT_DIR/physical_replay.py
CONTAINER_IMAGE=''

usage() {
    echo 'usage: test_single_bind_guest_root_docker.sh --container-image sha256:64_HEX'
}

die() {
    echo "single_bind_guest_root: REFUSING -- $*" >&2
    exit 2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --container-image) CONTAINER_IMAGE=${2-}; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done

[ "${#CONTAINER_IMAGE}" -eq 71 ] \
    || die 'container image must be an exact sha256 content ID'
case "$CONTAINER_IMAGE" in
    sha256:*[!0-9a-f]*|*[!0-9a-f])
        die 'container image must be an exact lowercase sha256 content ID' ;;
    sha256:*) ;;
    *) die 'container image must be an exact sha256 content ID' ;;
esac
for tool in awk docker mktemp python3 shasum tee; do
    command -v "$tool" >/dev/null || die "required tool is missing: $tool"
done
ACTUAL_IMAGE_ID=$(docker image inspect --format '{{.Id}}' "$CONTAINER_IMAGE")
[ "$ACTUAL_IMAGE_ID" = "$CONTAINER_IMAGE" ] \
    || die "container image identity differs: $ACTUAL_IMAGE_ID"
IMAGE_PLATFORM=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' \
    "$CONTAINER_IMAGE")
[ "$IMAGE_PLATFORM" = linux/arm64 ] \
    || die "container image platform is $IMAGE_PLATFORM, expected linux/arm64"

SMOKE_PARENT=${TMPDIR:-/tmp}
[ -d "$SMOKE_PARENT" ] && [ ! -L "$SMOKE_PARENT" ] \
    || die "temporary parent is not a real directory: $SMOKE_PARENT"
SMOKE_ROOT=$(mktemp -d "$SMOKE_PARENT/.single-bind-guest-root.XXXXXX")
REPLAY_ROOT=$SMOKE_ROOT/replay
SUCCESS=0
finish() {
    status=$?
    trap - EXIT
    if [ "$SUCCESS" -eq 1 ]; then
        python3 -B "$PHYSICAL_REPLAY_TOOL" remove-tree \
            --path "$SMOKE_ROOT" --expected-parent "$SMOKE_PARENT"
    elif [ -d "$SMOKE_ROOT" ]; then
        invalid=$SMOKE_ROOT.INVALID-DO-NOT-USE
        mv -- "$SMOKE_ROOT" "$invalid"
        echo "single_bind_guest_root: quarantined failure at $invalid" >&2
    fi
    exit "$status"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p "$REPLAY_ROOT/source" "$REPLAY_ROOT/work" \
    "$REPLAY_ROOT/machorun/build" \
    "$REPLAY_ROOT/w/scratch/mrroot_full/darwin/usr/lib"
cat > "$REPLAY_ROOT/source/system.c" <<'EOF'
int single_bind_system_probe(void) { return 11; }
EOF
cat > "$REPLAY_ROOT/source/cxx.cpp" <<'EOF'
extern "C" int single_bind_cxx_probe(void) { return 22; }
EOF
cat > "$REPLAY_ROOT/source/quartz.cpp" <<'EOF'
extern "C" int single_bind_quartz_probe(void) { return 33; }
EOF
printf '#!/bin/sh\nexit 0\n' > "$REPLAY_ROOT/machorun/build/machorun"
chmod +x "$REPLAY_ROOT/machorun/build/machorun"

docker run --rm --platform linux/arm64 --network none --read-only \
    -e HOME=/tmp/home -e TMPDIR=/tmp -e XDG_CACHE_HOME=/tmp/xdg-cache \
    --tmpfs /tmp:rw,exec,nosuid,nodev,mode=1777 \
    -v "$REPLAY_ROOT:/replay:rw" -w /replay "$CONTAINER_IMAGE" \
    bash -lc '
        set -euo pipefail
        guest=/replay/w/scratch/mrroot_full
        lib=$guest/darwin/usr/lib
        work=/replay/work
        mkdir -p "$HOME" "$XDG_CACHE_HOME" "$lib" "$work/churn" /tmp/cache
        cp /replay/machorun/build/machorun "$guest/machorun"
        clang-18 -target arm64-apple-macos15.0 -c /replay/source/system.c -o "$work/system.o"
        clang-18 -target arm64-apple-macos15.0 -c /replay/source/cxx.cpp -o "$work/cxx.o"
        ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
            -syslibroot "$guest/darwin" -dylib -undefined dynamic_lookup \
            -install_name /usr/lib/libSystem.B.dylib \
            -o "$lib/libSystem.B.dylib" "$work/system.o"
        ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
            -syslibroot "$guest/darwin" -dylib -undefined dynamic_lookup \
            -install_name /usr/lib/libc++.1.dylib \
            -o "$lib/libc++.1.dylib" "$work/cxx.o" "$lib/libSystem.B.dylib"
        printf "linked-before-churn\n" > "$guest/.manifest"
        # Exercise the only tmpfs while issuing enough independent compiler
        # processes to cross the phase boundary that exposed disappearing
        # nested mounts in the production build.
        for number in $(seq 1 48); do
            clang-18 -target arm64-apple-macos15.0 \
                -DSINGLE_BIND_CHURN="$number" -c /replay/source/system.c \
                -o "$work/churn/$number.o"
            printf "%08d\n" "$number" >> /tmp/cache/churn
        done
        test -f "$lib/libSystem.B.dylib"
        test -f "$lib/libc++.1.dylib"
        clang-18 -target arm64-apple-macos15.0 -c /replay/source/quartz.cpp \
            -o "$work/quartz.o"
        ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
            -syslibroot "$guest/darwin" -dylib -undefined dynamic_lookup \
            -install_name /usr/lib/libquartz.dylib \
            -o "$lib/libquartz.dylib" "$work/quartz.o" \
            "$lib/libc++.1.dylib" "$lib/libSystem.B.dylib"
        for product in "$guest/machorun" "$guest/.manifest" \
            "$lib/libSystem.B.dylib" "$lib/libc++.1.dylib" \
            "$lib/libquartz.dylib"; do
            test -f "$product"
        done
    ' 2>&1 | tee "$SMOKE_ROOT/docker.log"

GUEST_ROOT=$REPLAY_ROOT/w/scratch/mrroot_full
for relative in machorun .manifest darwin/usr/lib/libSystem.B.dylib \
    darwin/usr/lib/libc++.1.dylib darwin/usr/lib/libquartz.dylib; do
    product=$GUEST_ROOT/$relative
    [ -f "$product" ] && [ ! -L "$product" ] \
        || die "host cannot see durable product after Docker: $relative"
    printf 'durable\t%s\tsha256=%s\n' "$relative" \
        "$(shasum -a 256 "$product" | awk '{print $1}')"
done
SUCCESS=1
echo 'SINGLE_BIND_GUEST_ROOT_OK'
