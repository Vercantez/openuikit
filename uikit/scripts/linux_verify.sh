#!/usr/bin/env bash
# Proves OpenUIKit's portability claim: builds the library + openrender inside
# a stock Swift Linux container, renders every fixture scene there, and diffs
# the result against the real-UIKit goldens AND against this machine's own
# macOS render (which must be byte-identical).
#
# Usage: scripts/linux_verify.sh [scratch-dir]
# Requires: Docker, or an attested Cursor cloud environment matching
# swift:6.2-noble (the Linux half only; the macOS oracle is local-only).
set -e
cd "$(dirname "$0")/.."
REPO="$PWD"
WORK="${1:-/tmp/openuikit-linux-verify}"
IMAGE="swift:6.2-noble"
REPO_ROOT=$(git rev-parse --show-toplevel)

mkdir -p "$WORK"/{fonts,linux_out,mac_out}

# Apple's fonts are not redistributable; copy the local ones in so the
# container can render glyphs that are not in the harvested ink table.
for f in SFNS.ttf SFNSMono.ttf SFNSItalic.ttf; do
  [ -f "/System/Library/Fonts/$f" ] && cp -f "/System/Library/Fonts/$f" "$WORK/fonts/$f"
done

echo "==> macOS reference render"
if [ "$(uname -s)" = Darwin ]; then
swift build -c release --product openrender >/dev/null
OPENUIKIT_BACKEND=quartz ./.build/release/openrender render "$WORK/mac_out" fixtures/scenes/*.json >/dev/null
else
echo "CURSOR_ENV_MACOS_ORACLE_LOCAL_ONLY host=$(uname -s)"
fi

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
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
docker run --rm -v "$REPO":/src:ro -v "$WORK":/out "$IMAGE" bash /out/run.sh
elif bash "$REPO_ROOT/.cursor/attest-cursor-env.sh"; then
echo "CURSOR_ENV_TOOLCHAIN_ATTESTED running linux_verify in-VM (docker pins swift:6.2-noble only)"
(
  set -e
  cd "$REPO"
  rm -rf .build
  swift --version
  swift build -c release --product openrender 2>&1 | grep -E "error|complete" | tail -3
  OPENUIKIT_FONT_DIR="$WORK/fonts" OPENUIKIT_BACKEND=quartz \
    ./.build/release/openrender render "$WORK/linux_out" fixtures/scenes/*.json >/dev/null
  echo "linux rendered $(ls "$WORK/linux_out"/*.png | wc -l) frames"
)
else
echo "linux_verify: REFUSING -- Docker is required to pin swift:6.2-noble and CURSOR_ENV attestation failed" >&2
exit 2
fi

echo "==> diffing Linux output against real-UIKit goldens"
python3 Tools/compare/compare.py --out "$WORK/linux_out" | tail -1

echo "==> diffing Linux output against the macOS render (expect byte-identical)"
if [ "$(uname -s)" != Darwin ]; then
echo "CURSOR_ENV_MACOS_ORACLE_LOCAL_ONLY skipping macOS byte-identical compare"
echo "LINUX HALF COMPLETE (macOS oracle is local-only)"
exit 0
fi
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
