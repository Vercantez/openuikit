#!/usr/bin/env bash
# Full Objective-C/Mach-O app route, run inside the Linux build container.
set -euo pipefail
cd "$(dirname "$0")/.."
UIKIT=$PWD
SUPPORT=${OPENUIKIT_REALAPP_GUEST_SUPPORT:-$(git rev-parse --show-toplevel)}
BUILD=${OPENUIKIT_REALAPP_GUEST_BUILD:-$SUPPORT/build/full}
ROOT=${OPENUIKIT_REALAPP_GUEST_ROOT:-$SUPPORT/scratch/mrroot_full}
WORK=${1:-/tmp/openuikit-guest-realapp-verify}
[ "$(uname -s)" = Linux ] || { echo 'guest realapp verification requires Linux' >&2; exit 2; }
[ -x "$ROOT/machorun" ] && [ -f "$BUILD/render_full" ] || {
    echo 'Build full/scripts/build_full.sh before running the guest verifier.' >&2; exit 2;
}
expected_subject=$(cat "$BUILD/focus-guest-subject.sha256")
actual_subject=$(python3 "$SUPPORT/full/focus-ios/guest_subject.py" "$SUPPORT" "$UIKIT")
[ "$expected_subject" = "$actual_subject" ] || { echo 'Guest inputs changed since build' >&2; exit 2; }
[ "$(sha256sum "$BUILD/render_full" | cut -d ' ' -f1)" = "$(cat "$BUILD/focus-guest-executable.sha256")" ] \
    || { echo 'Guest executable changed since build' >&2; exit 2; }
mkdir -p "$WORK/linux_out"
# A stale extra PNG must not satisfy the screen count.
rm -f "$WORK/linux_out/"*.png "$WORK/linux_out/"*.layout.json
export MACHORUN_ROOT="$ROOT" LD_LIBRARY_PATH="$BUILD/host"
export LD_PRELOAD="$BUILD/host/libOpenDispatchHost.so:$BUILD/host/libOpenFoundationInternationalizationHost.so:$BUILD/host/libOpenURLTransportHost.so:$BUILD/host/libOpenRelativeTimeHost.so"
unset OPENUIKIT_FONT_DIR OPENUIKIT_REALAPP_ONLY OPENUIKIT_INK_LOG
export OPENUIKIT_RESOURCE_ROOT="$UIKIT/Sources/OpenUIKit/Resources"
export OPENUIKIT_FORCE_IOS=1 OPENUIKIT_REALAPP_SCALE=2 OPENUIKIT_BACKEND=quartz
"$ROOT/machorun" "$BUILD/GuestBoundaryTests" > "$WORK/boundary.log" 2>&1
grep -F 'FOCUS_GUEST_BOUNDARY_OK' "$WORK/boundary.log"
"$ROOT/machorun" "$BUILD/LaunchProbe" > "$WORK/launch.log" 2>&1
grep -F 'FOCUS_REAL_APPDELEGATE_LAUNCHED root=BrowserViewController' "$WORK/launch.log"
"$ROOT/machorun" "$BUILD/FuziProbe" fixtures/realapp/focus-bundle/SearchPlugins/default/*.xml \
    > "$WORK/fuzi.txt" 2> "$WORK/fuzi.log"
cmp "$SUPPORT/full/focus-ios/fuzi-default-plugins.expected.txt" "$WORK/fuzi.txt"
echo 'Fuzi: all 64 default-plugin reference lines match the native parser'
printf '==> machorun real AppDelegate launch (15 screens, harvested iOS 2x ink)\n'
"$ROOT/machorun" "$BUILD/render_full" realapp "$WORK/linux_out" "$UIKIT/fixtures/realapp/assets" > "$WORK/guest.log" 2>&1 || {
    tail -60 "$WORK/guest.log"; exit 1;
}
# Loader and guest libraries stay out of the host verification tools.
unset LD_PRELOAD LD_LIBRARY_PATH
python3 - "$UIKIT" "$WORK" <<'PY'
import hashlib, json, pathlib, sys
uikit, work = map(pathlib.Path, sys.argv[1:])
out = work / 'linux_out'
expected = {}
for line in (uikit / 'fixtures/realapp/linux-existing14.sha256').read_text().splitlines():
    digest, name = line.split()
    expected[name] = digest
assert len(expected) == 14, 'baseline must contain exactly fourteen screens'
browser = 'realapp_focus_browser_light.png'
assert {p.name for p in out.glob('*.png')} == set(expected) | {browser}, 'expected fifteen named screens'
for name, digest in expected.items():
    assert hashlib.sha256((out/name).read_bytes()).hexdigest() == digest, 'existing screen changed: ' + name
layout = json.loads((out / browser.replace('.png', '.layout.json')).read_text())
assert layout['screen'] == {'bounds': [393, 852], 'scale': 2}
classes = {v['class'] for v in layout['views']}
assert 'URLBar' in classes and 'HomeViewToolbar' in classes, 'missing real browser URL bar/home'
log = (work / 'guest.log').read_text()
assert '[render_full] realapp rendered=15 failed=0' in log
assert 'OPENUIKIT_IOS_INK_MISS:' not in log
fixture = uikit / 'fixtures/realapp' / browser
assert fixture.is_file(), 'missing committed Linux browser fixture'
assert fixture.read_bytes() == (out/browser).read_bytes(), 'Linux browser fixture differs from this guest run'
print('rendered 15 screens; existing screens byte-identical 14/14 (including Ledger)')
print('realapp_focus_browser_light: real AppDelegate URL bar + home, 393x852 @2x')
PY
echo 'REAL-APP SCREEN VERIFIED ON LINUX'
