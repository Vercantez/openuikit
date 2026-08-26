#!/bin/bash
# Stage the build inputs out of the sibling repos and start the build container.
#
#   scripts/container.sh up      # stage + create the container
#   scripts/container.sh sh      # shell into it
#   scripts/container.sh down    # remove it
#
# Run on the macOS host. The sibling repos are read-only inputs and are copied,
# never mounted: Docker cannot mount from some of these paths, and this scope is
# explicitly forbidden from writing to them.
#
# Only ever touches the container named below, by exact name — the user runs
# unrelated containers.
set -euo pipefail
cd "$(dirname "$0")/.."
REPO=$PWD
NAME=fm-build
IMAGE=${IMAGE:-swift-macho-spike:noble}   # swift 6.2.4 + llvm-18/ld64.lld, arm64
SCRATCH=${SCRATCH:-${TMPDIR:-/tmp}/foundation-macho}
STAGE=$SCRATCH/stage
WORK=$SCRATCH/work

MACHORUN=${MACHORUN:-$HOME/machorun}
SWIFTCORE=${SWIFTCORE:-$HOME/swiftcore-macho}
SCF=${SCF:-$SCRATCH/src/scf}

stage() {
  rm -rf "$STAGE"; mkdir -p "$STAGE" "$WORK"

  # swift-corelibs-foundation, for Apple's open-source CoreFoundation headers.
  if [ ! -d "$SCF" ]; then
    mkdir -p "$(dirname "$SCF")"
    git clone --depth 1 --branch release/6.2 \
      https://github.com/swiftlang/swift-corelibs-foundation.git "$SCF"
  fi

  cp -a "$MACHORUN/sdk"                     "$STAGE/machorun-sdk"
  cp -a "$MACHORUN/vendor/objc4-priv"       "$STAGE/objc4-priv"
  mkdir -p "$STAGE/objc4-runtime"
  cp -a "$MACHORUN/vendor/objc4/runtime/"*.h "$STAGE/objc4-runtime/"
  mkdir -p "$STAGE/darwinlib"
  cp -a "$MACHORUN/darwin/usr/lib/"*.dylib  "$STAGE/darwinlib/"
  cp -a "$MACHORUN/build/machorun"          "$STAGE/machorun-bin"

  mkdir -p "$STAGE/swiftcore"
  cp -a "$SWIFTCORE/artifacts/swift-macosx" "$STAGE/swiftcore/"
  cp -a "$SWIFTCORE/artifacts/libswiftcompat.dylib" "$STAGE/darwinlib/"
  cp -a "$SWIFTCORE/sdk/libc"               "$STAGE/libc"
  cp -a "$SWIFTCORE/sdk/foundation"         "$STAGE/foundation"

  mkdir -p "$STAGE/scf/Sources/CoreFoundation"
  cp -a "$SCF/Sources/CoreFoundation/include" "$STAGE/scf/Sources/CoreFoundation/"

  echo "staged into $STAGE ($(du -sh "$STAGE" | cut -f1))"
}

case "${1:-up}" in
  up)
    stage
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    docker run -d --name "$NAME" \
      -v "$STAGE:/stage:ro" -v "$WORK:/work" -v "$REPO:/repo" \
      -w /work "$IMAGE" sleep infinity >/dev/null
    docker exec "$NAME" bash -lc 'bash /repo/scripts/stage_sdk.sh'
    echo
    echo "next:  docker exec $NAME bash -lc 'bash /repo/scripts/build_slice.sh &&"
    echo "                                    bash /repo/scripts/build_overlay.sh &&"
    echo "                                    bash /repo/scripts/run_tests.sh'"
    ;;
  sh)   exec docker exec -it "$NAME" bash ;;
  down) docker rm -f "$NAME" >/dev/null 2>&1 && echo "removed $NAME" ;;
  *)    echo "usage: container.sh up|sh|down" >&2; exit 2 ;;
esac
