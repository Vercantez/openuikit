#!/bin/bash
# Build libswiftcompat.dylib locally, in Docker, with no AWS box.
#
# The Graviton box that first built this artefact is gone, and spinning one up
# to relink a 50 KB shim is not proportionate. Everything the build needs is
# already on this machine:
#
#   machorun-swift:6.2.4      swift.org 6.2.4's clang (the compiler) and
#                             Ubuntu's ld64.lld-18 (the Darwin linker)
#   ~/machorun/sdk            machorun's header+tbd SDK
#   ~/machorun/build/sdk/     the staged Command Line Tools headers, for c++/v1
#   ~/machorun/darwin/usr/lib the built userland the overlap check grades against
#
# Still no Apple toolchain and no Xcode: the compile is swift.org's clang and
# the link is LLVM's ld64.lld, exactly as on the box.
#
# Usage:  scripts/build_compat_docker.sh [-o OUTPUT]
# Default output is artifacts/libswiftcompat.dylib in this repo. Pass
# -o ~/machorun/darwin/usr/lib/libswiftcompat.dylib only if you mean to stage
# it; ~/machorun is not ours to write to casually.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACHORUN="${MACHORUN:-$HOME/machorun}"
IMAGE="${MACHORUN_SWIFT_IMAGE:-machorun-swift:6.2.4}"
OUT="$REPO/artifacts/libswiftcompat.dylib"
[ "${1:-}" = "-o" ] && { OUT="$2"; shift 2; }

for p in "$MACHORUN/sdk/usr/include" "$MACHORUN/sdk/usr/lib" \
         "$MACHORUN/build/sdk/MacOSX.sdk/usr/include/c++/v1" \
         "$MACHORUN/darwin/usr/lib/libSystem.B.dylib"; do
  [ -e "$p" ] || { echo "missing input: $p" >&2; exit 2; }
done

C=swiftcompat-build-$$
docker rm -f "$C" >/dev/null 2>&1 || true
docker run -d --name "$C" --platform linux/arm64 \
  -v "$MACHORUN":/work:ro -v "$REPO":/src:ro "$IMAGE" sleep infinity >/dev/null
trap 'docker rm -f "$C" >/dev/null 2>&1 || true' EXIT

# Bind mounts from macOS have silently TRUNCATED files copied out of them
# before, so the source is checked by content on the far side rather than
# assumed to have arrived whole. A short swiftcompat.c would compile fine and
# quietly drop whichever symbols fell off the end.
want=$(md5 -q "$REPO/sdk/compat/swiftcompat.c" 2>/dev/null || md5sum "$REPO/sdk/compat/swiftcompat.c" | cut -d' ' -f1)
got=$(docker exec "$C" md5sum /src/sdk/compat/swiftcompat.c | cut -d' ' -f1)
[ "$want" = "$got" ] || { echo "swiftcompat.c differs across the mount ($want vs $got)" >&2; exit 2; }

# Compose the sysroot: machorun's headers+tbds are the base, and c++/v1 comes
# from the staged CLT headers, which is the only place libc++'s headers exist.
docker exec "$C" bash -c '
  set -e
  rm -rf /b/sdk; mkdir -p /b/sdk/usr
  cp -a /work/sdk/usr/include /b/sdk/usr/include
  cp -a /work/sdk/usr/lib     /b/sdk/usr/lib
  mkdir -p /b/sdk/usr/include/c++
  cp -a /work/build/sdk/MacOSX.sdk/usr/include/c++/v1 /b/sdk/usr/include/c++/v1
'

# LOADER must be passed explicitly: it defaults to $W/machorun/build/machorun,
# and W is /b in here while machorun is mounted at /work. Without this the
# loader block is skipped silently and the assertion grades a set missing the
# entire dyld surface -- an inert guard that reports PASS.
docker exec -e W=/b -e SDK=/b/sdk -e SRC=/src/sdk/compat \
            -e MRLIB=/work/darwin/usr/lib -e LOADER=/work/build/machorun \
            -e OUT=/b/libswiftcompat.dylib \
            "$C" bash /src/scripts/build_compat.sh

mkdir -p "$(dirname "$OUT")"
docker cp "$C:/b/libswiftcompat.dylib" "$OUT"
echo "copied out: $OUT ($(wc -c < "$OUT") bytes)"
