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
#                                        # (or goldens/ios/ios_suite via scripts/goldens_restore.sh)
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

# Always materialise the 2x/3x scene split so SKIP_CAPTURE=1 works without
# leftover $WORK/scenes from a previous capture (the Linux restore path).
# Two devices: modal/alert scenes and windows wider than the SE's 375 pt
# (sheet insets, alert widths and safe areas are device geometry) on the
# iPhone 16 (3x); everything else, window scenes included, on the iPhone
# SE (2x), whose pixel grid IS the scene's — measured 2026-09-04: the
# 375-wide navbar_dark/navbar_large score 99.5 against the SE and 98.9
# against the iPhone 16 for the same render.
# The iPhone 16 is a 3x device: capturing it at the scene's scale 2
# resamples every edge, so its group is captured AND rendered at scale 3
# from patched copies of the scene files ($WORK/scenes). The 2x group is
# copied unchanged; compare.py reads the copies too.
python3 - "$WORK" <<'PYSPLIT'
import json, sys, os, shutil
work = sys.argv[1]
os.makedirs(work + '/scenes', exist_ok=True)
bars, modal, alerts, plain = [], [], [], []
for f in open(work + '/static_scenes.txt').read().split():
    d = json.load(open(f))
    big = d.get('modal') or d.get('alert') or (d.get('window') and d.get('size', [0])[0] > 375)
    dst = work + '/scenes/' + os.path.basename(f)
    if big:
        d['scale'] = 3
        json.dump(d, open(dst, 'w'), indent=1)
        # MEASURED 2026-09-04: once a SimScene process has shown an alert
        # or a sheet, the glass bar platters no longer render in its later
        # captures (navitem_dark came back with no platter at all, black
        # where three stand-alone captures show the (25,25,25) capsule).
        # Bar-chrome scenes therefore get their own process, run first;
        # sheets and other windows next; ALERTS LAST (a dismissed alert also
        # costs the next sheet its grabber and the 12 pt the grabber adds:
        # modal_sheet_grabber captured after alert_* had no grabber and its
        # title at y 87, alone it has the grabber and the title at 99).
        (bars if d.get('ios') else alerts if d.get('alert') else modal).append(dst)
    else:
        shutil.copyfile(f, dst)
        plain.append(dst)
open(work + '/scenes_3x_bars.txt', 'w').write('\n'.join(bars) + '\n')
open(work + '/scenes_3x_modal.txt', 'w').write('\n'.join(modal) + '\n')
open(work + '/scenes_3x_alerts.txt', 'w').write('\n'.join(alerts) + '\n')
open(work + '/scenes_2x.txt', 'w').write('\n'.join(plain) + '\n')
print(f"    {len(plain)} scenes on the 2x device; on the iPhone 16 at 3x: {len(bars)} bar scenes, {len(modal)} sheet/window scenes, then {len(alerts)} alert scenes")
PYSPLIT

if [[ -z "${SKIP_CAPTURE:-}" ]]; then
  echo "==> real iOS capture ($GOLD)"
  rm -rf "$GOLD"
  s2=("${(@f)$(cat "$WORK/scenes_2x.txt")}"); s3b=("${(@f)$(cat "$WORK/scenes_3x_bars.txt")}"); s3m=("${(@f)$(cat "$WORK/scenes_3x_modal.txt")}"); s3a=("${(@f)$(cat "$WORK/scenes_3x_alerts.txt")}")
  if (( ${#s2} > 0 )); then SIM_DEVICE=2x zsh scripts/render_sim_scenes.sh "$GOLD" "${s2[@]}" | tail -1; fi
  if (( ${#s3b} > 0 )); then zsh scripts/render_sim_scenes.sh "$GOLD" "${s3b[@]}" | tail -1; fi
  # One SimScene process PER sheet/alert scene: a dismissed sheet costs the
  # next sheet its grabber just as a dismissed alert does (modal_sheet_grabber
  # captured after modal_sheet: 96.7, alone: 99.7).
  for f in "${s3m[@]}" "${s3a[@]}"; do zsh scripts/render_sim_scenes.sh "$GOLD" "$f" | tail -1; done
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
else
  pngs=("$GOLD"/*.png(N))
  if (( ${#pngs} == 0 )); then
    if [[ -d goldens/ios/ios_suite ]]; then
      echo "==> no goldens at $GOLD; restoring committed goldens/ios/ios_suite"
      zsh scripts/goldens_restore.sh ios_suite
      if [[ "$GOLD" != /tmp/ios_suite/golden_ios ]]; then
        mkdir -p "$GOLD"
        cp -R /tmp/ios_suite/golden_ios/. "$GOLD"/
      fi
    else
      echo "ios_suite.sh: no goldens at $GOLD (run scripts/goldens_restore.sh or recapture)" >&2
      exit 2
    fi
  fi
fi

echo "==> OpenUIKit render with the iOS cut ($OUT)"
swift build -c release --product openrender >/dev/null
rm -rf "$OUT"
suite_scenes=("${(@f)$(ls "$WORK"/scenes/*.json)}")
OPENUIKIT_FORCE_IOS=1 ./.build/release/openrender render "$OUT" "${suite_scenes[@]}" >/dev/null
echo "==> compare"
python3 Tools/compare/compare.py --scenes "$WORK/scenes" --golden "$GOLD" --out "$OUT" --golden-straight-alpha "${names[@]}" > "$WORK/compare.txt" 2>&1 || true
grep -E 'scenes pass' "$WORK/compare.txt"
grep '^FAIL' "$WORK/compare.txt" | sort -t= -k2 -n | head -25
echo "full report: $WORK/compare.txt"
