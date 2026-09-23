#!/usr/bin/env bash
# Interactive Mach-O guest host (host_full), replayed headless: Firefox Focus
# launched through its real AppDelegate, driven by real touch and text events
# from uikit/fixtures/realapp/focus_host_script.json under SDL's dummy video
# driver, twice. Asserts what each capture's state.json says the app did, and
# that the two runs wrote byte-identical frames and state.
#
# Run by linux_guest_realapp_verify.sh (same environment variables). Wherever
# SDL2's headers exist build_full.sh builds host_full, so there it is required.
set -euo pipefail
cd "$(dirname "$0")/.."
UIKIT=$PWD
SUPPORT=${OPENUIKIT_REALAPP_GUEST_SUPPORT:-$(git rev-parse --show-toplevel)}
BUILD=${OPENUIKIT_REALAPP_GUEST_BUILD:-$SUPPORT/build/full}
ROOT=${OPENUIKIT_REALAPP_GUEST_ROOT:-$SUPPORT/scratch/mrroot_full}
WORK=${1:-/tmp/openuikit-guest-host-verify}
[ "$(uname -s)" = Linux ] || { echo 'guest host verification requires Linux' >&2; exit 2; }
if [ ! -f "$BUILD/host_full" ]; then
    if [ -f /usr/include/SDL2/SDL.h ]; then
        echo 'host_full missing although SDL2 is installed: build_full.sh must have built it' >&2
        exit 2
    fi
    echo 'GUEST HOST SKIPPED: no SDL2 on this builder, so build_full.sh did not build host_full'
    exit 0
fi
[ "$(sha256sum "$BUILD/host_full" | cut -d ' ' -f1)" = "$(cat "$BUILD/host_full.sha256")" ] \
    || { echo 'host_full changed since build' >&2; exit 2; }
SCRIPT=$UIKIT/fixtures/realapp/focus_host_script.json

run_once() {
    local out=$1
    rm -rf "$out"; mkdir -p "$out"
    env MACHORUN_ROOT="$ROOT" LD_LIBRARY_PATH="$BUILD/host" \
        LD_PRELOAD="$BUILD/host/libOpenDispatchHost.so:$BUILD/host/libOpenFoundationInternationalizationHost.so:$BUILD/host/libOpenURLTransportHost.so:$BUILD/host/libOpenRelativeTimeHost.so:$BUILD/host/libOpenSDLHost.so" \
        OPENUIKIT_RESOURCE_ROOT="$UIKIT/Sources/OpenUIKit/Resources" \
        OPENUIKIT_FORCE_IOS=1 OPENUIKIT_REALAPP_SCALE=2 OPENUIKIT_BACKEND=quartz \
        SDL_VIDEODRIVER=dummy \
        timeout 600 "$ROOT/machorun" "$BUILD/host_full" --app focus \
        --assets "$UIKIT/fixtures/realapp/assets" --script "$SCRIPT" --record "$out" \
        > "$out.log" 2>&1 || { tail -40 "$out.log"; return 1; }
}
printf '==> host_full replay (Focus, dummy SDL video, 2 runs)\n'
run_once "$WORK/run1"
run_once "$WORK/run2"
grep -F 'HOST_FULL_LAUNCHED app=focus root=BrowserViewController' "$WORK/run1.log"
python3 - "$WORK" "$SCRIPT" <<'PY'
import json, pathlib, sys
work, script = pathlib.Path(sys.argv[1]), json.loads(pathlib.Path(sys.argv[2]).read_text())
run1, run2 = work / 'run1', work / 'run2'
captures = script['captures']
def stem(t): return 'focus_host.t%03d' % round(t * 1000)
names = sorted(p.name for p in run1.iterdir())
assert names == sorted(p.name for p in run2.iterdir()), 'the two runs wrote different files'
assert len([n for n in names if n.endswith('.png')]) == len(captures), 'missing captures'
for n in names:
    assert (run1 / n).read_bytes() == (run2 / n).read_bytes(), 'run-to-run difference: ' + n
state = {t: json.loads((run1 / (stem(t) + '.state.json')).read_text()) for t in captures}
def field(t):
    fs = [f for f in state[t]['textFields'] if f['class'] == 'URLTextField']
    assert len(fs) == 1, 'expected one URLTextField at t=%s' % t
    return fs[0]
def top(t):
    tops = [p for p in state[t]['presented'] if p.startswith('top=')]
    return tops[-1][4:] if tops else None
checks = [
    (0.5, 'launch: URL bar first responder, keyboard up',
     lambda: state[0.5]['keyboardUp'] and field(0.5)['isFirstResponder']),
    (1.6, 'tap Cancel: editing ends, keyboard down',
     lambda: not state[1.6]['keyboardUp'] and not field(1.6)['isEditing']),
    (2.6, 'tap URL bar: editing, keyboard up, field 263 pt wide (iOS 26.1)',
     lambda: state[2.6]['keyboardUp'] and field(2.6)['isEditing']
     and field(2.6)['frameInWindow'] == [48, 28.5, 263, 39.5]),
    (3.3, 'type "mozilla": the field holds it',
     lambda: field(3.3)['text'] == 'mozilla' and field(3.3)['isEditing']),
    (3.9, 'tap the keyboard\'s "a" key: "mozillaa"',
     lambda: field(3.9)['text'] == 'mozillaa'),
    (4.5, 'tap the keyboard\'s delete key: "mozilla"',
     lambda: field(4.5)['text'] == 'mozilla'),
    (5.5, 'tap Cancel: editing ends, field cleared',
     lambda: not state[5.5]['keyboardUp'] and field(5.5)['text'] == ''),
    (6.3, 'tap menu: Help / Settings platter',
     lambda: 'contextMenuView' in state[6.3]['labels']
     and {'Help', 'Settings'} <= set(state[6.3]['labels'])),
    (7.3, 'tap Settings: SettingsViewController presented',
     lambda: top(7.3) == 'SettingsViewController'),
    (8.3, 'tap Theme: ThemeViewController pushed',
     lambda: top(8.3) == 'ThemeViewController'),
    (9.3, 'tap back: popped to SettingsViewController',
     lambda: top(9.3) == 'SettingsViewController'),
    (10.9, 'tap Done: Settings dismissed',
     lambda: state[10.9]['presented'] == []),
]
for t, what, ok in checks:
    assert ok(), 'FAILED t=%s %s: %s' % (t, what, json.dumps(state[t])[:600])
    print('  t=%-4s %s' % (t, what))
pngs = {t: (run1 / (stem(t) + '.png')).read_bytes() for t in captures}
# Each step that changes what is on screen must change the frame.
for a, b in [(0.5, 1.6), (1.6, 2.6), (2.6, 3.3), (3.3, 3.9), (3.9, 4.5), (5.5, 6.3),
             (6.3, 7.3), (7.3, 8.3), (8.3, 9.3), (9.3, 10.9)]:
    assert pngs[a] != pngs[b], 'frames t=%s and t=%s are identical' % (a, b)
# Typed text is DRAWN: the URL field's pixels (48..311 x 30..66 pt, 2x)
# change when "mozilla" is typed, and the "a"/delete taps undo each other.
import struct, zlib
def rgba(png):
    # Minimal PNG decode (8-bit RGBA, filter types 0-4) -- no PIL on the gate.
    pos, w, h, idat = 8, 0, 0, b''
    while pos < len(png):
        n = struct.unpack('>I', png[pos:pos+4])[0]; kind = png[pos+4:pos+8]; body = png[pos+8:pos+8+n]
        if kind == b'IHDR': w, h = struct.unpack('>II', body[:8])
        if kind == b'IDAT': idat += body
        pos += 12 + n
    raw, stride, out, prev = zlib.decompress(idat), w * 4, [], bytearray(w * 4)
    for y in range(h):
        f, line = raw[y*(stride+1)], bytearray(raw[y*(stride+1)+1:(y+1)*(stride+1)])
        for i in range(stride):
            a = line[i-4] if i >= 4 else 0; b = prev[i]; c = prev[i-4] if i >= 4 else 0
            if f == 1: line[i] = (line[i] + a) & 255
            elif f == 2: line[i] = (line[i] + b) & 255
            elif f == 3: line[i] = (line[i] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c; pa, pb, pc = abs(p-a), abs(p-b), abs(p-c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        out.append(bytes(line)); prev = line
    return w, out
def region(png, x0, y0, x1, y1):
    w, rows = rgba(png)
    return b''.join(r[x0*4:x1*4] for r in rows[y0:y1])
url = (96, 60, 622, 132)  # the URL field, device pixels
assert region(pngs[2.6], *url) != region(pngs[3.3], *url), 'typed text is not drawn in the URL field'
assert region(pngs[3.3], *url) == region(pngs[4.5], *url), '"a" then delete did not restore the field'
print('  typed text drawn in the URL field; key tap + delete restore it')
log = (work / 'run1.log').read_text()
misses = [l for l in log.splitlines() if l.startswith('HOST_FULL_INK_MISSES')]
print('%d captures byte-identical across 2 runs; %s' % (len(captures), misses[0][:80] if misses else 'no ink report'))
PY
echo 'GUEST HOST INTERACTION VERIFIED ON LINUX'
