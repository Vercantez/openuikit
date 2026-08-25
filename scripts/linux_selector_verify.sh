#!/bin/zsh
# Proves the selector target-action path (docs/OBJC_RUNTIME.md) BUILDS and RUNS
# on Linux, not just on macOS. Companion to scripts/linux_verify.sh, which
# proves the renderer is byte-identical on the fixture scenes; this one proves
# the app-facing API works off Darwin, end to end.
#
# Inside a stock swift:6.2-noble container (plus libsdl2-dev, which also closes
# the "openhost was not built on Linux" gap in docs/PORTABILITY.md) it:
#   1. builds the library, openrender and openhost -- openhost pulls in
#      DemoApp, which contains SelectorApp.swift: a screen wired entirely with
#      addTarget(_:action:for:) and UITapGestureRecognizer(target:action:),
#      never with a closure;
#   2. runs the selector dispatch test suite, which drives real touches through
#      UIWindow into selector-registered targets;
#   3. replays scripts/selector_interaction.json against that screen with
#      `openhost --app selectors --script` (SDL's dummy video driver, so it is
#      headless) and diffs the recorded frames against this machine's macOS
#      run of the same script -- byte for byte. A selector that failed to fire
#      would change the rendered counter, so identical bytes prove the actions
#      ran identically on both operating systems.
#
# Usage: scripts/linux_selector_verify.sh [scratch-dir]
# Requires: Docker.
set -e
cd "$(dirname "$0")/.."
REPO="$PWD"
WORK="${1:-/tmp/openuikit-selector-verify}"
IMAGE="swift:6.2-noble"

rm -rf "$WORK"
mkdir -p "$WORK"/{fonts,linux_out,mac_out}

# Apple's fonts are not redistributable; copy the local ones in so the
# container can render glyphs that are not in the harvested ink table.
for f in SFNS.ttf SFNSMono.ttf SFNSItalic.ttf; do
  [ -f "/System/Library/Fonts/$f" ] && cp -f "/System/Library/Fonts/$f" "$WORK/fonts/$f"
done

echo "==> macOS reference run of the selector app"
swift build -c release --product openhost >/dev/null
OPENUIKIT_BACKEND=quartz ./.build/release/openhost --app selectors \
    --script scripts/selector_interaction.json --record "$WORK/mac_out" >/dev/null

cat > "$WORK/run.sh" <<'INNER'
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq libsdl2-dev >/dev/null
mkdir -p /work && cp -r /src/. /work/
cd /work && rm -rf .build
swift --version

echo "==> build (library + openrender + openhost + DemoApp)"
swift build -c release --product openrender >/dev/null
swift build -c release --product openhost >/dev/null
echo "    built clean"

echo "==> selector dispatch tests"
# Two Linux-only harness quirks, neither of them ours (both reproduce on
# untouched suites -- see docs/PORTABILITY.md):
#   * `swift test` blocks in poll() forever with no TTY, so we build the tests
#     and run the XCTest bundle directly;
#   * the bundle itself hangs mid-run roughly one launch in five, in this
#     image, even for purely computational suites (GeometryTests/ColorTests
#     flake at the same rate). So: run under a timeout and retry.
swift build --build-tests >/dev/null
BUNDLE="$(swift build --build-tests --show-bin-path | tail -1)/OpenUIKitPackageTests.xctest"
SUITES=OpenUIKitTests.SelectorNameTests,OpenUIKitTests.ActionTableTests,OpenUIKitTests.SelectorDispatchDeliveryTests,OpenUIKitTests.ControlSelectorTargetTests,OpenUIKitTests.GestureSelectorTargetTests,OpenUIKitTests.SelectorDemoAppTests
ok=0
for attempt in 1 2 3 4 5 6 7 8; do
  if SWIFT_BACKTRACE=enable=no timeout 120 "$BUNDLE" "$SUITES" >/out/tests.log 2>&1; then
    ok=1; break
  fi
  echo "    (attempt $attempt hung -- known Linux XCTest flake, retrying)"
done
tail -2 /out/tests.log
[ "$ok" = 1 ] || { echo "    selector tests did not complete"; exit 1; }
grep -qE "Executed [0-9]+ tests, with 0 failures" /out/tests.log

echo "==> scripted replay of the selector-wired screen"
replay=0
for attempt in 1 2 3 4; do
  if SDL_VIDEODRIVER=dummy OPENUIKIT_FONT_DIR=/out/fonts OPENUIKIT_BACKEND=quartz \
     timeout 180 ./.build/release/openhost --app selectors \
     --script scripts/selector_interaction.json --record /out/linux_out >/dev/null 2>&1; then
    replay=1; break
  fi
  echo "    (attempt $attempt failed, retrying)"
done
[ "$replay" = 1 ] || { echo "    scripted replay failed"; exit 1; }
echo "    recorded $(ls /out/linux_out/*.png | wc -l) frames"
INNER

echo "==> Linux build + test + replay ($IMAGE)"
docker run --rm -v "$REPO":/src:ro -v "$WORK":/out "$IMAGE" bash /out/run.sh

echo "==> diffing the Linux frames against the macOS frames (expect byte-identical)"
python3 - "$WORK" <<'PY'
import hashlib, os, sys
w = sys.argv[1]
same, diff = 0, []
names = sorted(f for f in os.listdir(f"{w}/mac_out") if f.endswith(".png"))
assert names, "no macOS frames recorded"
for f in names:
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
echo "SELECTOR PATH VERIFIED ON LINUX"
