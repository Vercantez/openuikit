#!/bin/zsh
# ios_suite.sh [<workdir>] — the whole scene suite against REAL iOS.
#
# Renders every STATIC scene (no "animations") twice — with real UIKit on the
# iPhone 16 / iOS 26 simulator (scripts/render_sim_scenes.sh, sRGB captures)
# and with OpenUIKit under the iOS font cut / iOS palette / pixel-grid
# rounding (OPENUIKIT_FORCE_IOS=1 openrender) — and diffs them with
# Tools/compare/compare.py. The Catalyst goldens in golden/ stay the
# regression gate; this is the FIDELITY measurement against the platform
# apps actually ship on. First measured 2026-09-04: 17/98 before the iOS
# palette and sRGB fix, 31/98 after (docs/REAL_APP_TEST.md has the list).
#
#   scripts/ios_suite.sh                 # work in /tmp/ios_suite
#   scripts/ios_suite.sh /path/to/work   # keeps golden_ios/, out_ios/, compare.txt
#   SKIP_CAPTURE=1 scripts/ios_suite.sh  # reuse an existing golden_ios/
set -e
setopt null_glob
cd "$(dirname "$0")/.."
WORK=${1:-/tmp/ios_suite}
mkdir -p "$WORK"
GOLD="$WORK/golden_ios"; OUT="$WORK/out_ios"

python3 - "$WORK" <<'EOF'
import json, glob, sys
work = sys.argv[1]
static = [f for f in sorted(glob.glob('fixtures/scenes/*.json')) if not json.load(open(f)).get('animations')]
open(work + '/static_scenes.txt', 'w').write('\n'.join(static) + '\n')
print(f"{len(static)} static scenes of {len(glob.glob('fixtures/scenes/*.json'))}")
EOF
scenes=("${(@f)$(cat "$WORK/static_scenes.txt")}")
names=("${(@)scenes:t:r}")

if [[ -z "${SKIP_CAPTURE:-}" ]]; then
  echo "==> real iOS capture ($GOLD)"
  rm -rf "$GOLD"
  # Two devices: scenes that capture the WINDOW (window/modal/alert — sheet
  # insets, bars and safe areas are device geometry) on the iPhone 16 (3x),
  # everything else on the iPhone SE (2x), whose pixel grid IS the scene's.
  python3 - "$WORK" <<'PYSPLIT'
import json, sys
work = sys.argv[1]
win, plain = [], []
for f in open(work + '/static_scenes.txt').read().split():
    d = json.load(open(f))
    (win if (d.get('window') or d.get('modal') or d.get('alert')) else plain).append(f)
open(work + '/scenes_3x.txt', 'w').write('\n'.join(win) + '\n')
open(work + '/scenes_2x.txt', 'w').write('\n'.join(plain) + '\n')
print(f"    {len(plain)} scenes on the 2x device, {len(win)} window scenes on the iPhone 16")
PYSPLIT
  s2=("${(@f)$(cat "$WORK/scenes_2x.txt")}"); s3=("${(@f)$(cat "$WORK/scenes_3x.txt")}")
  if (( ${#s2} > 0 )); then SIM_DEVICE=2x zsh scripts/render_sim_scenes.sh "$GOLD" "${s2[@]}" | tail -1; fi
  if (( ${#s3} > 0 )); then zsh scripts/render_sim_scenes.sh "$GOLD" "${s3[@]}" | tail -1; fi
  # A P3-tagged capture from an older SimScene build is converted so the diff
  # is sRGB vs sRGB (SimScene itself now writes untagged straight-alpha sRGB).
  python3 - "$GOLD" <<'PYCONV'
import glob, io, sys
from PIL import Image, ImageCms
dst = ImageCms.createProfile('sRGB'); n = 0
for f in glob.glob(sys.argv[1] + '/*.png'):
    im = Image.open(f); icc = im.info.get('icc_profile')
    if not icc: continue
    try:
        src = ImageCms.ImageCmsProfile(io.BytesIO(icc))
        rgba = im.convert('RGBA'); a = rgba.getchannel('A')
        rgb = ImageCms.profileToProfile(rgba.convert('RGB'), src, dst)
        out = rgb.convert('RGBA'); out.putalpha(a); out.save(f); n += 1
    except Exception as e:
        print('  not converted:', f, e)
print(f"    converted {n} P3-tagged captures to sRGB")
PYCONV
fi

echo "==> OpenUIKit render with the iOS cut ($OUT)"
swift build -c release --product openrender >/dev/null
rm -rf "$OUT"
OPENUIKIT_FORCE_IOS=1 ./.build/release/openrender render "$OUT" "${scenes[@]}" >/dev/null
echo "==> compare"
python3 Tools/compare/compare.py --golden "$GOLD" --out "$OUT" "${names[@]}" > "$WORK/compare.txt" 2>&1 || true
grep -E 'scenes pass' "$WORK/compare.txt"
grep '^FAIL' "$WORK/compare.txt" | sort -t= -k2 -n | head -25
echo "full report: $WORK/compare.txt"
