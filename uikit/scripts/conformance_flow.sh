#!/bin/zsh
# conformance_flow.sh <workdir> <app> — the whole conformance-app loop for one
# app, in one command (docs/HILLCLIMB.md, docs/ORACLE_FLOW.md).
#
#   1. replay the app's script.json with REAL UIKit on the iOS 26 simulator
#      (scripts/conformance_probe_sim.sh) into <workdir>/golden;
#   2. replay the SAME SOURCE with OpenUIKit under the iOS cut
#      (openhost --app <app> --script ... --record) into <workdir>/ours;
#   3. compare capture by capture with Tools/compare/compare.py's own pixel
#      functions (straight-alpha goldens — the captures are opaque, so
#      premultiplied and straight are the same bytes) plus an absolute-frame
#      layout diff, and write
#        <workdir>/report/<t>/{sheet,diff,golden,ours}.png + report.txt
#        <workdir>/summary.json  {app, captures: [{name, score, blob,
#                                                  layout_issues}]}
#      which scripts/scoreboard.py reads with --conformance <workdir>.
#
#   scripts/conformance_flow.sh /tmp/conf NavFlow
#   SKIP_CAPTURE=1 scripts/conformance_flow.sh /tmp/conf NavFlow
#
# SIM_DEVICE_SUFFIX gives the run its own simulator devices.
set -e
setopt null_glob
cd "$(dirname "$0")/.."
OUT=${1:?usage: conformance_flow.sh <workdir> <app>}
APPNAME=${2:?usage: conformance_flow.sh <workdir> <app>}
SCRIPT="Sources/ConformanceApps/$APPNAME/script.json"
[[ -f "$SCRIPT" ]] || { echo "no such conformance app: $SCRIPT" >&2; exit 2 }
mkdir -p "$OUT/golden" "$OUT/ours" "$OUT/report"

if [[ -z "${SKIP_CAPTURE:-}" ]]; then
  echo "==> real iOS replay ($OUT/golden)"
  zsh scripts/conformance_probe_sim.sh "$APPNAME" "$OUT/golden" | tail -1
fi

echo "==> OpenUIKit replay, iOS cut ($OUT/ours)"
swift build -c release --product openhost >/dev/null
rm -rf "$OUT/ours"; mkdir -p "$OUT/ours"
./.build/release/openhost --app "$APPNAME" --script "$SCRIPT" --record "$OUT/ours" \
  | tail -1

echo "==> compare"
python3 - "$OUT" "$APPNAME" "$SCRIPT" <<'PY'
import json, os, shutil, sys
sys.path.insert(0, os.path.join(os.getcwd(), "Tools/compare"))
import compare                                   # the suite's own pixel gate
from PIL import Image, ImageChops

out, app, script_path = sys.argv[1], sys.argv[2], sys.argv[3]
script = json.load(open(script_path))
scale = None

def suffix(t):
    return compare.capture_suffix(t)

def abs_rows(dump):
    """(text, abs-frame) for every view the two trees can be matched on.

    Real UIKit hangs an app's controllers off private containers
    (UILayoutContainerView, UIViewControllerWrapperView, UITransitionView)
    that OpenUIKit has no counterpart for, so compare.py's path-indexed
    layout diff would compare two unrelated trees (the same reason
    compare_realapp.py re-roots at the sheet's scroll view). What DOES
    identify the same object on both sides is the text it draws, plus the
    controls the app created; both are compared in ABSOLUTE window
    coordinates.
    """
    rows = {}
    for v in dump["views"]:
        key = None
        if v.get("text"):
            key = ("text", v["text"])
        elif v["class"] in ("UISwitch",):
            key = ("class", v["class"])
        if key is None:
            continue
        rows.setdefault(key, []).append(v)
    for k in rows:
        rows[k].sort(key=lambda v: (v["abs"][1], v["abs"][0]))
    return rows

def layout_problems(g, o, tol=compare.LAYOUT_TOL):
    gr, orr = abs_rows(g), abs_rows(o)
    problems = []
    for key in sorted(set(gr) | set(orr), key=lambda k: (k[0], k[1])):
        a, b = gr.get(key, []), orr.get(key, [])
        label = f"{key[0]}={key[1]!r}"
        if len(a) != len(b):
            problems.append(f"{label}: golden has {len(a)}, ours has {len(b)}")
        for ga, oa in zip(a, b):
            for i, axis in enumerate("xywh"):
                if abs(ga["abs"][i] - oa["abs"][i]) > tol:
                    problems.append(f"{label} abs.{axis}: golden={ga['abs'][i]} ours={oa['abs'][i]}")
    return problems

captures = []
for t in script["captures"]:
    name = suffix(t)
    d = f"{out}/report/{name}"
    os.makedirs(d, exist_ok=True)
    g = f"{out}/golden/{app}.{name}.png"
    o = f"{out}/ours/{app}.{name}.png"
    gl, ol = f"{out}/golden/{app}.{name}.layout.json", f"{out}/ours/{app}.{name}.layout.json"
    if not (os.path.exists(g) and os.path.exists(o)):
        open(f"{d}/report.txt", "w").write("missing golden or render\n")
        captures.append({"name": name, "score": 0.0, "blob": 0.0, "layout_issues": 1})
        continue
    gdump, odump = json.load(open(gl)), json.load(open(ol))
    if scale is None:
        scale = gdump["screen"]["scale"]
    shutil.copyfile(g, f"{d}/golden.png"); shutil.copyfile(o, f"{d}/ours.png")
    res, err = compare.compare_pixels(g, o, f"{d}/diff.png",
                                      golden_premultiplied=False, scale=scale)
    problems = layout_problems(gdump, odump)
    gi = Image.open(g).convert("RGB"); oi = Image.open(o).convert("RGB")
    if gi.size == oi.size:
        ImageChops.difference(gi, oi).point(lambda v: min(255, v * 4)).save(f"{d}/absdiff.png")
    sheet = Image.new("RGB", (gi.width * 2 + 10, max(gi.height, oi.height)), (255, 0, 255))
    sheet.paste(gi, (0, 0)); sheet.paste(oi, (gi.width + 10, 0)); sheet.save(f"{d}/sheet.png")

    if err:
        lines = [f"{app} {name}: {err}"]
        entry = {"name": name, "score": 0.0, "blob": 0.0, "layout_issues": len(problems)}
    else:
        entry = {"name": name, "score": res["score"], "blob": res["blob"],
                 "layout_issues": len(problems)}
        lines = [f"{app} {name}  pixels={res['score']:.3f}  blob={res['blob']} pt^2"
                 f"  mae={res['mae']}  layout_issues={len(problems)}"]
        if "blob_bbox" in res:
            lines.append(f"  largest wrong region at {res['blob_bbox']}")
        if "missing" in res:
            m = res["missing"]
            lines.append(f"  content missing at {m['bbox']} (golden std {m['golden_std']},"
                         f" ours {m['our_std']})")
    # A capture that caught an animation reports it: the simulator dump has a
    # presentation frame only where the render tree differs from the model.
    moving = [v["path"] for v in gdump["views"] if "pframe" in v]
    if moving:
        lines.append(f"  NOT AT REST on the golden side: {len(moving)} view(s) animating")
    lines += ["  " + p for p in problems]
    open(f"{d}/report.txt", "w").write("\n".join(lines) + "\n")
    captures.append(entry)
    print(lines[0])

summary = {"app": app, "captures": captures}
json.dump(summary, open(f"{out}/summary.json", "w"), indent=1)
scores = [c["score"] for c in captures]
print(f"\n{app}: {len(captures)} capture(s), worst {min(scores):.3f}, "
      f"mean {sum(scores) / len(scores):.3f}")
PY
echo "reports: $OUT/report/<t>/{sheet,diff,golden,ours}.png + report.txt; $OUT/summary.json"
