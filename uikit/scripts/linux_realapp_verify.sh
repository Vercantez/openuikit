#!/usr/bin/env bash
# Proves the REAL-APP screen (docs/REAL_APP_TEST.md) builds and renders
# IDENTICALLY on Linux. Companion to scripts/linux_verify.sh (fixture scenes)
# and scripts/linux_selector_verify.sh (selector dispatch).
#
# Inside a stock swift:6.2-noble container it:
#   1. builds the library, openrender and openhost -- both now link
#      Sources/RealAppProbe, which is UNMODIFIED source from
#      Automattic/pocket-casts-ios. A build failure here would mean the app
#      source only compiles on Darwin;
#   2. renders the twelve headless screens (`openrender realapp`);
#   3. replays scripts/realapp_interaction.json against the live screen
#      (`openhost --app pocketcasts --script`, SDL dummy driver);
#   4. diffs both sets against this machine's macOS run, byte for byte.
#
# Usage: scripts/linux_realapp_verify.sh [scratch-dir]
# Requires: Docker, or an attested Cursor cloud environment matching swift:6.2-noble.
set -e
cd "$(dirname "$0")/.."
REPO="$PWD"
WORK="${1:-/tmp/openuikit-realapp-verify}"
IMAGE="swift:6.2-noble"
REPO_ROOT=$(git rev-parse --show-toplevel)

rm -rf "$WORK"
mkdir -p "$WORK"/{fonts,linux_out,mac_out,linux_host,mac_host}

# Apple's fonts are not redistributable; copy the local ones in so the
# container can render glyphs that are not in the harvested ink table.
for f in SFNS.ttf SFNSMono.ttf SFNSItalic.ttf; do
  [ -f "/System/Library/Fonts/$f" ] && cp -f "/System/Library/Fonts/$f" "$WORK/fonts/$f"
done

echo "==> macOS reference render of the real-app screen"
if [ "$(uname -s)" = Darwin ]; then
swift build -c release --product openrender >/dev/null
swift build -c release --product openhost >/dev/null
OPENUIKIT_BACKEND=quartz ./.build/release/openrender realapp "$WORK/mac_out" >/dev/null
OPENUIKIT_BACKEND=quartz ./.build/release/openhost --app pocketcasts \
    --script scripts/realapp_interaction.json --record "$WORK/mac_host" >/dev/null
else
echo "CURSOR_ENV_MACOS_ORACLE_LOCAL_ONLY host=$(uname -s)"
fi

cat > "$WORK/run.sh" <<'INNER'
set -e
SRC=${INNER_SRC:-/src}
OUT=${INNER_OUT:-/out}
if ! pkg-config --exists sdl2 >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null && apt-get install -y -qq libsdl2-dev >/dev/null
fi
if [ -n "${INNER_IN_PLACE:-}" ]; then
  cd "$SRC"
else
  mkdir -p /work && cp -r "$SRC"/. /work/
  cd /work && rm -rf .build
fi
swift --version

echo "==> build (library + openrender + openhost + RealAppProbe)"
swift build -c release --product openrender 2>&1 | grep -E "error" && exit 1
swift build -c release --product openhost 2>&1 | grep -E "error" && exit 1
echo "    built clean -- the vendored app source compiles off Darwin"

echo "==> headless render"
OPENUIKIT_FONT_DIR="$OUT/fonts" OPENUIKIT_BACKEND=quartz \
  ./.build/release/openrender realapp "$OUT/linux_out"
n=$(ls "$OUT/linux_out"/*.png | wc -l | tr -d ' ')
[ "$n" -eq 12 ] || { echo "expected 12 realapp screens, got $n"; ls "$OUT/linux_out"; exit 1; }
echo "==> scripted live replay"
replay=0
for attempt in 1 2 3 4; do
  if SDL_VIDEODRIVER=dummy OPENUIKIT_FONT_DIR="$OUT/fonts" OPENUIKIT_BACKEND=quartz \
     timeout 180 ./.build/release/openhost --app pocketcasts \
     --script scripts/realapp_interaction.json --record "$OUT/linux_host" >/dev/null 2>&1; then
    replay=1; break
  fi
  echo "    (attempt $attempt failed, retrying)"
done
[ "$replay" = 1 ] || { echo "    scripted replay failed"; exit 1; }
echo "    recorded $(ls "$OUT/linux_host"/*.png | wc -l) frames"
INNER

echo "==> Linux build + render + replay ($IMAGE)"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
docker run --rm -v "$REPO":/src:ro -v "$WORK":/out "$IMAGE" bash /out/run.sh
elif bash "$REPO_ROOT/.cursor/attest-cursor-env.sh"; then
echo "CURSOR_ENV_TOOLCHAIN_ATTESTED running linux_realapp_verify in-VM (docker pins swift:6.2-noble only)"
INNER_SRC=$REPO INNER_OUT=$WORK INNER_IN_PLACE=1 bash "$WORK/run.sh"
else
echo "linux_realapp_verify: REFUSING -- Docker is required to pin swift:6.2-noble and CURSOR_ENV attestation failed" >&2
exit 2
fi

echo "==> diffing Linux against macOS (expect byte-identical)"
if [ "$(uname -s)" != Darwin ]; then
echo "CURSOR_ENV_MACOS_ORACLE_LOCAL_ONLY skipping macOS byte-identical compare"
echo "LINUX REALAPP HALF COMPLETE (macOS oracle is local-only)"
exit 0
fi
python3 - "$WORK" <<'PY'
import hashlib, os, sys
w = sys.argv[1]
h = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
total_same, total_diff = 0, []
for mac, lin, label in [("mac_out", "linux_out", "headless"),
                        ("mac_host", "linux_host", "live")]:
    names = sorted(f for f in os.listdir(f"{w}/{mac}") if f.endswith(".png"))
    assert names, f"no macOS frames in {mac}"
    same, diff = 0, []
    for f in names:
        b = f"{w}/{lin}/{f}"
        if not os.path.exists(b):
            diff.append(f + " (missing)"); continue
        if h(f"{w}/{mac}/{f}") == h(b): same += 1
        else: diff.append(f)
    print(f"  {label}: byte-identical {same}/{same + len(diff)}")
    total_same += same; total_diff += diff
if total_diff:
    print("differing:", total_diff)
    raise SystemExit(1)
print(f"byte-identical: {total_same}/{total_same}")
PY
echo "REAL-APP SCREEN VERIFIED ON LINUX"
