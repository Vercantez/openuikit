#!/bin/zsh
# oracle_flow.sh <outdir> <scene.json | scene-name>... — the whole real-iOS
# oracle loop for a handful of scenes, in one command:
#
#   1. capture each scene with REAL UIKit on the iOS 26 simulator, on the
#      device the scene belongs to (the iPhone SE 3rd gen at 2x for scale-2
#      scenes up to 375 pt wide; the iPhone 16 at 3x for wider windows,
#      sheets and alerts — the scene file is copied with "scale": 3 for those),
#      ONE SimScene process per sheet/alert scene (a dismissed alert or sheet
#      breaks the glass materials of everything captured after it in the same
#      process — docs/REAL_APP_TEST.md, capture hazards);
#   2. render the same scene files with OpenUIKit under the iOS cut
#      (OPENUIKIT_FORCE_IOS=1 openrender);
#   3. compare (Tools/compare/compare.py --golden-straight-alpha), and write
#      per scene: golden.png, ours.png, diff.png, sheet.png (golden over ours),
#      the two layout dumps and report.txt;
#   4. print the scoreboard.
#
#   scripts/oracle_flow.sh /tmp/flow tableview_grouped navbar_large
#   SIM_DEVICE_SUFFIX=-a1 scripts/oracle_flow.sh /tmp/flow fixtures/scenes/x.json
#
# SIM_DEVICE_SUFFIX gives this run its own simulator devices, so several
# flows (several agents) can run side by side. SKIP_CAPTURE=1 reuses
# <outdir>/golden from an earlier run.
set -e
setopt null_glob
cd "$(dirname "$0")/.."
OUT=${1:?usage: oracle_flow.sh <outdir> <scene>...}; shift
(( $# > 0 )) || { echo "no scenes given" >&2; exit 2 }
mkdir -p "$OUT/scenes" "$OUT/golden" "$OUT/ours" "$OUT/report"

# Resolve names to scene files and copy them (patching the 3x group's scale).
python3 - "$OUT" "$@" <<'PY'
import json, os, shutil, sys
out = sys.argv[1]
two, bars, modal, alerts = [], [], [], []
for arg in sys.argv[2:]:
    f = arg if arg.endswith('.json') else f'fixtures/scenes/{arg}.json'
    if not os.path.exists(f): sys.exit(f'no such scene: {arg}')
    d = json.load(open(f))
    if d.get('animations'): sys.exit(f'{arg}: animation scenes have no simulator oracle')
    big = d.get('modal') or d.get('alert') or (d.get('window') and d.get('size', [0])[0] > 375)
    dst = f"{out}/scenes/{os.path.basename(f)}"
    if big:
        d['scale'] = 3
        json.dump(d, open(dst, 'w'), indent=1)
        (bars if d.get('ios') else alerts if d.get('alert') else modal).append(dst)
    else:
        shutil.copyfile(f, dst); two.append(dst)
for name, lst in (('2x', two), ('3x_bars', bars), ('3x_modal', modal), ('3x_alerts', alerts)):
    open(f'{out}/scenes_{name}.txt', 'w').write('\n'.join(lst) + ('\n' if lst else ''))
print(f"{len(two)} scene(s) on the SE (2x); iPhone 16 at 3x: {len(bars)} bar, {len(modal)} sheet/window, {len(alerts)} alert")
PY

if [[ -z "${SKIP_CAPTURE:-}" ]]; then
  echo "==> real iOS capture ($OUT/golden)"
  s2=("${(@f)$(cat "$OUT/scenes_2x.txt")}"); s3b=("${(@f)$(cat "$OUT/scenes_3x_bars.txt")}")
  s3m=("${(@f)$(cat "$OUT/scenes_3x_modal.txt")}"); s3a=("${(@f)$(cat "$OUT/scenes_3x_alerts.txt")}")
  if (( ${#s2} > 0 )) && [[ -n "${s2[1]}" ]]; then SIM_DEVICE=2x zsh scripts/render_sim_scenes.sh "$OUT/golden" "${s2[@]}" | tail -1; fi
  if (( ${#s3b} > 0 )) && [[ -n "${s3b[1]}" ]]; then zsh scripts/render_sim_scenes.sh "$OUT/golden" "${s3b[@]}" | tail -1; fi
  for f in "${s3m[@]}" "${s3a[@]}"; do [[ -n "$f" ]] && zsh scripts/render_sim_scenes.sh "$OUT/golden" "$f" | tail -1; done
fi

echo "==> OpenUIKit render, iOS cut ($OUT/ours)"
swift build -c release --product openrender >/dev/null
rm -rf "$OUT/ours"
OPENUIKIT_FORCE_IOS=1 ./.build/release/openrender render "$OUT/ours" "$OUT"/scenes/*.json >/dev/null

echo "==> compare"
names=("${(@)${(@f)$(ls "$OUT"/scenes/*.json)}:t:r}")
python3 Tools/compare/compare.py --scenes "$OUT/scenes" --golden "$OUT/golden" --out "$OUT/ours" \
  --golden-straight-alpha "${names[@]}" > "$OUT/compare.txt" 2>&1 || true

# Per-scene report folders: golden / ours / diff / sheet / dumps / report.txt.
python3 - "$OUT" "${names[@]}" <<'PY'
import os, shutil, sys
from PIL import Image, ImageChops
out = sys.argv[1]
text = open(f'{out}/compare.txt').read().splitlines()
for name in sys.argv[2:]:
    d = f'{out}/report/{name}'; os.makedirs(d, exist_ok=True)
    g, o = f'{out}/golden/{name}.png', f'{out}/ours/{name}.png'
    if not (os.path.exists(g) and os.path.exists(o)):
        open(f'{d}/report.txt', 'w').write('missing golden or render\n'); continue
    shutil.copyfile(g, f'{d}/golden.png'); shutil.copyfile(o, f'{d}/ours.png')
    for k in ('golden', 'ours'):
        src = f"{out}/{k}/{name}.layout.json"
        if os.path.exists(src): shutil.copyfile(src, f'{d}/{k}.layout.json')
    gi = Image.open(g).convert('RGBA'); oi = Image.open(o).convert('RGBA')
    white = Image.new('RGBA', gi.size, (255, 255, 255, 255))
    gc = Image.alpha_composite(white, gi).convert('RGB'); oc = Image.alpha_composite(white, oi).convert('RGB')
    diff = ImageChops.difference(gc, oc).point(lambda v: min(255, v * 4))
    diff.save(f'{d}/diff.png')
    sheet = Image.new('RGB', (gc.width * 2 + 10, gc.height), (255, 0, 255))
    sheet.paste(gc, (0, 0)); sheet.paste(oc, (gc.width + 10, 0)); sheet.save(f'{d}/sheet.png')
    lines = [l for l in text if l.startswith(('PASS', 'FAIL')) and l.split()[1] == name]
    i = text.index(lines[0]) if lines else -1
    detail = []
    if i >= 0:
        for l in text[i + 1:]:
            if l.startswith(('PASS', 'FAIL')) or 'scenes pass' in l: break
            detail.append(l)
    open(f'{d}/report.txt', 'w').write('\n'.join(lines + detail) + '\n')
PY
grep -E '^(PASS|FAIL)' "$OUT/compare.txt" | sort
echo "reports: $OUT/report/<scene>/{sheet,diff,golden,ours}.png + report.txt + layout dumps"
