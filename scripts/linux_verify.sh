#!/bin/zsh
# Proves OpenUIKit's portability claim: builds the library + openrender inside
# a stock Swift Linux container, renders every fixture scene there, and diffs
# the result against the real-UIKit goldens AND against this machine's own
# macOS render (which must be byte-identical).
#
# Usage: scripts/linux_verify.sh [scratch-dir]
# Requires: Docker.
set -e
cd "$(dirname "$0")/.."
REPO="$PWD"
WORK="${1:-/tmp/openuikit-linux-verify}"
IMAGE="swift:6.2-noble"

mkdir -p "$WORK"/{fonts,linux_out,mac_out}

# Apple's fonts are not redistributable; copy the local ones in so the
# container can render glyphs that are not in the harvested ink table.
for f in SFNS.ttf SFNSMono.ttf SFNSItalic.ttf; do
  [ -f "/System/Library/Fonts/$f" ] && cp -f "/System/Library/Fonts/$f" "$WORK/fonts/$f"
done

echo "==> macOS reference render"
swift build -c release --product openrender >/dev/null
OPENUIKIT_BACKEND=quartz ./.build/release/openrender render "$WORK/mac_out" fixtures/scenes/*.json >/dev/null

cat > "$WORK/run.sh" <<'INNER'
set -e
mkdir -p /work && cp -r /src/. /work/
cd /work && rm -rf .build
swift --version
swift build -c release --product openrender 2>&1 | grep -E "error|complete" | tail -3
OPENUIKIT_FONT_DIR=/out/fonts OPENUIKIT_BACKEND=quartz \
  ./.build/release/openrender render /out/linux_out fixtures/scenes/*.json >/dev/null
echo "linux rendered $(ls /out/linux_out/*.png | wc -l) frames"
INNER

echo "==> Linux build + render ($IMAGE)"
docker run --rm -v "$REPO":/src:ro -v "$WORK":/out "$IMAGE" bash /out/run.sh

echo "==> diffing Linux output against real-UIKit goldens"
python3 Tools/compare/compare.py --out "$WORK/linux_out" | tail -1

echo "==> diffing Linux output against the macOS render (expect byte-identical)"
python3 - "$WORK" <<'PY'
import hashlib, os, sys
w = sys.argv[1]
same, diff = 0, []
for f in sorted(os.listdir(f"{w}/mac_out")):
    if not f.endswith(".png"): continue
    b = f"{w}/linux_out/{f}"
    if not os.path.exists(b):
        diff.append(f + " (missing)"); continue
    h = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
    if h(f"{w}/mac_out/{f}") == h(b): same += 1
    else: diff.append(f)
print(f"byte-identical: {same}/{same + len(diff)}")
if diff:
    print("differing:", diff)
    raise SystemExit(1)
PY
echo "PORTABILITY VERIFIED"
