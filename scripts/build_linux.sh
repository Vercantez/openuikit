#!/usr/bin/env bash
#
# scripts/build_linux.sh -- one command, clean checkout to libobjc.so.
#
#   ./scripts/build_linux.sh              # build
#   ./scripts/build_linux.sh inventory    # per-translation-unit compile report
#   ./scripts/build_linux.sh shell        # interactive shell in the container
#   ./scripts/build_linux.sh clean
#
# Everything happens inside a container built from docker/Dockerfile
# (Ubuntu 24.04 + clang 18). No packages are installed on the host.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${OBJC4_LINUX_IMAGE:-objc4-linux-build:24.04}"
ARCH="${OBJC4_LINUX_ARCH:-aarch64}"
cmd="${1:-build}"

case "$ARCH" in
    aarch64) PLATFORM=linux/arm64 ;;
    x86_64)  PLATFORM=linux/amd64 ;;
    *) echo "unsupported OBJC4_LINUX_ARCH=$ARCH" >&2; exit 2 ;;
esac

if [ "$cmd" = clean ]; then
    rm -rf "$ROOT/build"
    echo "cleaned $ROOT/build"
    exit 0
fi

# 1. Build the toolchain image if it is not there (idempotent, cached).
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "==> building toolchain image $IMAGE"
    docker build --platform "$PLATFORM" -t "$IMAGE" -f "$ROOT/docker/Dockerfile" "$ROOT/docker"
fi

# 2. Materialise the patched objc4 source tree (host side; vendor stays pristine).
echo "==> applying patches"
"$ROOT/scripts/apply-patches.sh"

# 3. Build inside the container.
run() {
    docker run --rm --platform "$PLATFORM" \
        -v "$ROOT":/work -w /work \
        -e OBJC4_LINUX_ARCH="$ARCH" \
        "$IMAGE" bash -c "$1"
}

case "$cmd" in
    build)
        echo "==> configuring + building"
        run 'set -e
             cmake -S /work -B /work/build/linux-$OBJC4_LINUX_ARCH -G Ninja \
                   -DCMAKE_BUILD_TYPE=RelWithDebInfo \
                   -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
             cmake --build /work/build/linux-$OBJC4_LINUX_ARCH -- -k 0'
        ;;
    inventory)
        run 'bash /work/scripts/inventory.sh'
        ;;
    shell)
        docker run --rm -it --platform "$PLATFORM" -v "$ROOT":/work -w /work "$IMAGE" bash
        ;;
    *)
        echo "usage: $0 [build|inventory|shell|clean]" >&2; exit 2 ;;
esac
