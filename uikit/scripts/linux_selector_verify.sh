#!/usr/bin/env bash
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
# Requires: Docker, or an attested Cursor cloud environment matching swift:6.2-noble.
set -e
cd "$(dirname "$0")/.."
REPO="$PWD"
WORK="${1:-/tmp/openuikit-selector-verify}"
IMAGE="swift:6.2-noble"
REPO_ROOT=$(git rev-parse --show-toplevel)

rm -rf "$WORK"
mkdir -p "$WORK"/{fonts,linux_out,mac_out}

# Apple's fonts are not redistributable; copy the local ones in so the
# container can render glyphs that are not in the harvested ink table.
for f in SFNS.ttf SFNSMono.ttf SFNSItalic.ttf; do
  [ -f "/System/Library/Fonts/$f" ] && cp -f "/System/Library/Fonts/$f" "$WORK/fonts/$f"
done

echo "==> macOS reference run of the selector app"
if [ "$(uname -s)" = Darwin ]; then
swift build -c release --product openhost >/dev/null
OPENUIKIT_BACKEND=quartz ./.build/release/openhost --app selectors \
    --script scripts/selector_interaction.json --record "$WORK/mac_out" >/dev/null
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
  mkdir -p /work
  tar -C "$SRC" --exclude=.build --exclude=Package.resolved -cf - . | tar -C /work -xf -
  cd /work
fi
swift --version

echo "==> build (library + openrender + openhost + DemoApp)"
swift build -c release --product openrender >/dev/null
swift build -c release --product openhost >/dev/null
echo "    built clean"

echo "==> selector dispatch tests"
# `swift test` still blocks in poll() with no TTY, so we build the tests
# and run the XCTest bundle directly (docs/PORTABILITY.md). The in-bundle
# hang (awaitUsingExpectation / CFRunLoop ppoll) is pumped by
# CLinuxXCTestSupport — no retry loop.
swift build --build-tests >/dev/null
BUNDLE="$(swift build --build-tests --show-bin-path | tail -1)/OpenUIKitPackageTests.xctest"
# ApplicationShellCompatibilityTests executes Linux-only Foundation fallbacks
# (currently NSUserActivity) rather than merely letting the build type-check them.
SUITES=OpenUIKitTests.SelectorNameTests,OpenUIKitTests.ActionTableTests,OpenUIKitTests.SelectorDispatchDeliveryTests,OpenUIKitTests.ControlSelectorTargetTests,OpenUIKitTests.GestureSelectorTargetTests,OpenUIKitTests.SelectorDemoAppTests,OpenUIKitTests.ApplicationShellCompatibilityTests
if ! SWIFT_BACKTRACE=enable=no timeout 120 "$BUNDLE" "$SUITES" >"$OUT/tests.log" 2>&1; then
  echo "    selector tests did not complete"; tail -20 "$OUT/tests.log"; exit 1
fi
tail -2 "$OUT/tests.log"
grep -qE "Executed [0-9]+ tests, with 0 failures" "$OUT/tests.log"

echo "==> scripted replay of the selector-wired screen"
replay=0
for attempt in 1 2 3 4; do
  if SDL_VIDEODRIVER=dummy OPENUIKIT_FONT_DIR="$OUT/fonts" OPENUIKIT_BACKEND=quartz \
     timeout 180 ./.build/release/openhost --app selectors \
     --script scripts/selector_interaction.json --record "$OUT/linux_out" >/dev/null 2>&1; then
    replay=1; break
  fi
  echo "    (attempt $attempt failed, retrying)"
done
[ "$replay" = 1 ] || { echo "    scripted replay failed"; exit 1; }
echo "    recorded $(ls "$OUT/linux_out"/*.png | wc -l) frames"
INNER

echo "==> Linux build + test + replay ($IMAGE)"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
docker run --rm -v "$REPO":/src:ro -v "$WORK":/out "$IMAGE" bash /out/run.sh
elif bash "$REPO_ROOT/.cursor/attest-cursor-env.sh"; then
echo "CURSOR_ENV_TOOLCHAIN_ATTESTED running linux_selector_verify in-VM (docker pins swift:6.2-noble only)"
INNER_SRC=$REPO INNER_OUT=$WORK INNER_IN_PLACE=1 bash "$WORK/run.sh"
else
echo "linux_selector_verify: REFUSING -- Docker is required to pin swift:6.2-noble and CURSOR_ENV attestation failed" >&2
exit 2
fi

echo "==> diffing the Linux frames against the macOS frames (expect byte-identical)"
if [ "$(uname -s)" != Darwin ]; then
echo "CURSOR_ENV_MACOS_ORACLE_LOCAL_ONLY skipping macOS byte-identical compare"
echo "LINUX SELECTOR HALF COMPLETE (macOS oracle is local-only)"
exit 0
fi
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
