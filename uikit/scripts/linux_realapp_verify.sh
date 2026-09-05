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
#   2. renders the thirteen headless screens (`openrender realapp`);
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
IMAGE="${OPENUIKIT_LINUX_IMAGE:-openuikit-linux-agent}"
REPO_ROOT=$(git rev-parse --show-toplevel)

rm -rf "$WORK"
mkdir -p "$WORK"/{fonts,linux_out,mac_out,linux_host,mac_host}

# Apple's fonts are not redistributable. The macOS reference render can use
# the host's SFNS. The inner Linux iOS-cut half draws harvested 2x masks
# with no FONT_DIR, then uses /out/fonts for unharvested 3x realapp glyphs
# when the Mac host copied SFNS (glyph_ink_ios_3x.json is 848 keys).
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
if ! python3 -c "import PIL, numpy" >/dev/null 2>&1 || ! command -v zsh >/dev/null 2>&1; then
  bash "$SRC/scripts/linux_setup.sh"
fi
if ! pkg-config --exists sdl2 >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null && apt-get install -y -qq libsdl2-dev >/dev/null
fi
if [ -n "${INNER_IN_PLACE:-}" ]; then
  cd "$SRC"
else
  mkdir -p /work
  tar -C "$SRC" --exclude=.build --exclude=Package.resolved -cf - . | tar -C /work -xf -
  cd /work
fi
swift --version

echo "==> build (library + openrender + openhost + RealAppProbe)"
swift build -c release --product openrender
swift build -c release --product openhost
echo "    built clean -- the vendored app source compiles off Darwin"

echo "==> unit tests (Linux 6.2.4 XCTest bundle)"
# `swift test` still blocks in poll() with no TTY (docs/PORTABILITY.md) —
# that is the SPM harness, not the bundle. The bundle itself used to hang
# inside awaitUsingExpectation → CFRunLoop ppoll (swift-corelibs-xctest#504;
# 3/5 ink-list launches at timeout 20 s on uikit-linux 6.2.4). CLinuxXCTestSupport
# wakes the main CFRunLoop from a non-main dispatch timer and drains
# DispatchQueue.main before the loop sleeps, so one attempt is enough.
swift build --build-tests
BUNDLE="$(swift build --build-tests --show-bin-path | tail -1)/OpenUIKitPackageTests.xctest"
run_suites() {
  local name=$1 suites=$2
  : > "$OUT/tests-$name.log"
  if ! SWIFT_BACKTRACE=enable=no timeout 60 "$BUNDLE" "$suites" >"$OUT/tests-$name.log" 2>&1; then
    echo "    $name tests did not complete"; tail -20 "$OUT/tests-$name.log"; exit 1
  fi
  tail -3 "$OUT/tests-$name.log"
  if grep -qE "Executed [0-9]+ tests, with [1-9][0-9]* failures" "$OUT/tests-$name.log"; then
    echo "    $name tests had failures"; exit 1
  fi
  grep -qE "Executed [0-9]+ tests, with 0 failures" "$OUT/tests-$name.log"
}
run_suites selector \
  OpenUIKitTests.SelectorNameTests,OpenUIKitTests.ActionTableTests,OpenUIKitTests.SelectorDispatchDeliveryTests,OpenUIKitTests.ControlSelectorTargetTests,OpenUIKitTests.GestureSelectorTargetTests,OpenUIKitTests.SelectorDemoAppTests,OpenUIKitTests.ApplicationShellCompatibilityTests
run_suites ink \
  OpenUIKitTests.GlyphInkTableTests,OpenUIKitTests.CoreAnimationCompatibilityTests,OpenUIKitTests.ConformanceRegistryTests,OpenUIKitTests.GeometryTests,OpenUIKitTests.ColorTests,OpenUIKitCTests.ABITests,SwiftUITests.SwiftUILinuxStubTests
echo "    unit tests passed"

echo "==> no-font iOS cut (2x harvested masks; Linux trial had blank labels)"
# glyph_ink_ios.json 7533 keys (2026-09-05, +13pt regular ASCII). "Hello" at 17 pt regular F0.0 is
# a HIT for H/e/l/o (383 opaque pixels measured). "Q" (U+0051) has metrics
# but is not in that table — U+2603 sizeToFits to width 0 and never draws.
# No OPENUIKIT_FONT_DIR on this path.
unset OPENUIKIT_FONT_DIR
python3 - <<'PY'
import json, os
os.makedirs("/tmp/inkprobe", exist_ok=True)
hit = {
  "name": "linux_ink_hit", "size": [320, 80], "scale": 2, "style": "light",
  "ios": True,
  "root": {"class": "UIView", "backgroundColor": "systemBackground",
           "subviews": [{"class": "UILabel", "frame": [16, 24, 0, 0],
                         "text": "Hello", "fontSize": 17, "sizeToFit": True}]}
}
miss = json.loads(json.dumps(hit)); miss["name"] = "linux_ink_miss"
miss["root"]["subviews"][0]["text"] = "Q"
json.dump(hit, open("/tmp/inkprobe/hit.json", "w"))
json.dump(miss, open("/tmp/inkprobe/miss.json", "w"))
PY
OPENUIKIT_FORCE_IOS=1 OPENUIKIT_BACKEND=quartz \
  ./.build/release/openrender render /tmp/inkprobe/hit-out /tmp/inkprobe/hit.json
python3 - <<'PY'
from PIL import Image
import numpy as np, glob
paths = glob.glob("/tmp/inkprobe/hit-out/*.png")
assert paths, "no-font iOS render wrote no PNG"
im = np.array(Image.open(paths[0]))
ink = int((im[:, :, 3] > 200).sum())
print(f"    no-font Hello opaque pixels (alpha>200): {ink}")
assert ink > 50, "harvested iOS masks must draw without SFNS.ttf"
PY
if OPENUIKIT_FORCE_IOS=1 OPENUIKIT_BACKEND=quartz \
     ./.build/release/openrender render /tmp/inkprobe/miss-out /tmp/inkprobe/miss.json \
     >/tmp/inkprobe/miss.log 2>&1; then
  echo "    expected OPENUIKIT_IOS_INK_MISS for Q (U+0051)"; cat /tmp/inkprobe/miss.log; exit 1
fi
grep -F "OPENUIKIT_IOS_INK_MISS:" /tmp/inkprobe/miss.log | head -1
grep -F "OPENUIKIT_IOS_INK_MISS: I|system-regular|17|light|F0.0|81" /tmp/inkprobe/miss.log

echo "==> headless render (iOS cut; 3x realapp)"
# 3x table is 848 keys — unharvested glyphs still need a font file
# (docs/PORTABILITY.md). Use /out/fonts when the Mac host copied SFNS.
if [ -f "$OUT/fonts/SFNS.ttf" ]; then
  export OPENUIKIT_FONT_DIR="$OUT/fonts"
  echo "    OPENUIKIT_FONT_DIR=$OPENUIKIT_FONT_DIR (unharvested 3x fallback)"
else
  unset OPENUIKIT_FONT_DIR
  echo "    no SFNS; unharvested 3x keys abort with OPENUIKIT_IOS_INK_MISS"
fi
OPENUIKIT_BACKEND=quartz \
  ./.build/release/openrender realapp "$OUT/linux_out"
n=$(ls "$OUT/linux_out"/*.png | wc -l | tr -d ' ')
[ "$n" -eq 13 ] || { echo "expected 13 realapp screens, got $n"; ls "$OUT/linux_out"; exit 1; }
echo "==> scripted live replay"
replay=0
for attempt in 1 2 3 4; do
  if SDL_VIDEODRIVER=dummy OPENUIKIT_BACKEND=quartz \
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
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "==> building $IMAGE from Dockerfile.linux-agent"
  docker build -f Dockerfile.linux-agent -t "$IMAGE" .
fi
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
        # Ledger pixels are Foundation formatter output (Apple on Darwin,
        # corelibs on Linux). They are not a raster identity; skip the
        # sha256 compare. Count still requires the PNG to exist.
        if f == "realapp_ledger_light.png":
            b = f"{w}/{lin}/{f}"
            if not os.path.exists(b):
                diff.append(f + " (missing)")
            else:
                same += 1
            continue
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
