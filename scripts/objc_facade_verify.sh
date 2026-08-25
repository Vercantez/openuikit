#!/bin/zsh
# Proves the Objective-C facade (docs/OBJC_FACADE.md):
#
#   1. builds OpenUIKit + libOpenUIKitC.so with the Swift toolchain,
#   2. builds a REAL Objective-C app (clang, libobjc2, gnustep-base) against it,
#   3. runs the ObjC app -- which subclasses UIView, overrides -layoutSubviews
#      and -drawRect:, and fires an @selector target-action -- to a PNG,
#   4. runs the Swift twin (Sources/objcparity) to another PNG,
#   5. diffs the two byte for byte.
#
# Everything happens in ONE Linux container, so any difference is the bridge
# and nothing else. The image is built by ObjCFacade/Dockerfile.
#
# Usage: scripts/objc_facade_verify.sh [scratch-dir]
# Requires: Docker + the openuikit-objc-facade:noble image
#           (docker build -t openuikit-objc-facade:noble ObjCFacade).
set -e
cd "$(dirname "$0")/.."
REPO="$PWD"
WORK="${1:-/tmp/openuikit-objc-facade}"
IMAGE="openuikit-objc-facade:noble"
CONTAINER="ouk-objc-facade-verify"

mkdir -p "$WORK"/{fonts,out}
rm -f "$WORK"/out/objc.png "$WORK"/out/swift.png

# Apple's fonts are not redistributable; copy the local ones in so glyphs
# outside the harvested ink table still draw. Both programs get the same
# directory, so this cannot bias the comparison either way.
for f in SFNS.ttf SFNSMono.ttf SFNSItalic.ttf; do
  [ -f "/System/Library/Fonts/$f" ] && cp -f "/System/Library/Fonts/$f" "$WORK/fonts/$f"
done

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "==> building $IMAGE (libobjc2 + gnustep-base from source; ~4 min)"
  docker build -t "$IMAGE" "$REPO/ObjCFacade"
fi

cat > "$WORK/run.sh" <<'INNER'
set -e
mkdir -p /work && cp -r /src/. /work/
cd /work && rm -rf .build

echo "--- toolchain"
cat /VERSIONS.txt
clang --version | head -1
swift --version 2>&1 | head -1

echo "--- swift: OpenUIKit + libOpenUIKitC.so + objcparity"
swift build -c release --product OpenUIKitC 2>&1 | grep -E "error|warning: .*ABI|Compiling OpenUIKitC" || true
swift build -c release --product objcparity 2>&1 | grep -E "error" || true
ls -la .build/release/libOpenUIKitC.so

echo "--- clang: the Objective-C facade + proof app"
make -C ObjCFacade REPO=/work BUILD=/work/.build/release OUT=/work/.build/objc

echo "--- what the ObjC binary links against"
ldd .build/objc/proofapp | grep -Ei "objc|gnustep|swift|OpenUIKitC" || true

echo "--- run: Objective-C app"
OPENUIKIT_BACKEND="${OPENUIKIT_BACKEND:-quartz}" OPENUIKIT_ABI_STRICT=1 \
  ./.build/objc/proofapp /out/out/objc.png /work/Sources/OpenUIKit/Resources /out/fonts

echo "--- run: Swift twin"
OPENUIKIT_BACKEND="${OPENUIKIT_BACKEND:-quartz}" \
  ./.build/release/objcparity /out/out/swift.png /work/Sources/OpenUIKit/Resources /out/fonts
INNER

echo "==> building and running both halves in $IMAGE"
docker run --rm --name "$CONTAINER" \
  -e OPENUIKIT_BACKEND="${OPENUIKIT_BACKEND:-quartz}" \
  -v "$REPO":/src:ro -v "$WORK":/out "$IMAGE" bash /out/run.sh

echo "==> diffing the Objective-C render against the Swift render"
python3 - "$WORK/out" <<'PY'
import hashlib, sys, os
d = sys.argv[1]
h = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
a, b = f"{d}/objc.png", f"{d}/swift.png"
for p in (a, b):
    if not os.path.exists(p):
        raise SystemExit(f"missing {p}")
ha, hb = h(a), h(b)
print(f"objc.png  {ha}  ({os.path.getsize(a)} bytes)")
print(f"swift.png {hb}  ({os.path.getsize(b)} bytes)")
if ha != hb:
    raise SystemExit("DIFFER -- the facade changed the render")
print("byte-identical")
PY
echo "OBJC FACADE VERIFIED"
