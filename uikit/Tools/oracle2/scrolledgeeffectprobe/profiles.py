#!/usr/bin/env python3
"""Reduce the render-server screenshots scripts/scroll_edge_effect_probe_sim.sh
takes to 1 pt pixel columns so the edge-effect numbers travel with the repo
without the 1179x2556 PNGs.

    profiles.py <outdir> <out.json>

One column at x = 380 pt (clear of the title, the tab-bar platter
[60, 274] and the toolbar items), sampled at the device's 3x scale, rows
0..259 (status bar + navigation bar zone + the first bands) and 620..851
(the bottom bar zone). The table and collection sweeps are byte-identical to
the plain scroll view's (checked at reduction time) and are kept only at the
phases the port encodes.
"""
import json, sys
from PIL import Image

out_dir, out = sys.argv[1:3]
X = 380
TOP = range(0, 260)
BOTTOM = range(620, 852)

def column(path):
    im = Image.open(path).convert("RGB")
    return {"top": [list(im.getpixel((X * 3, y * 3))) for y in TOP],
            "bottom": [list(im.getpixel((X * 3, y * 3))) for y in BOTTOM]}

phases = [p for p in open(f"{out_dir}/phases.txt").read().split("\n") if p]
keep = []
for p in phases:
    kind = p.split(".")[0]
    if kind in ("table", "collection") and p.split(".")[1] not in (
            "rest", "mid", "top+12", "bottom-12", "topHard", "topHidden", "bottomHard", "bottomHidden", "bottomRest"):
        continue
    keep.append(p)

profiles = {"x_pt": X, "rows": {"top": [TOP.start, TOP.stop], "bottom": [BOTTOM.start, BOTTOM.stop]},
            "note": "RGB per point row at x=380 pt from simctl io screenshot (3x); phases from phases.txt"}
profiles["phases"] = {p: column(f"{out_dir}/screen-{p}.png") for p in keep}

# Kind equivalence: every table/collection phase equals the scroll view's.
same = {}
for p in phases:
    kind, phase = p.split(".", 1)
    if kind in ("table", "collection") and f"scroll.{phase}" in phases:
        a = column(f"{out_dir}/screen-{p}.png")
        b = column(f"{out_dir}/screen-scroll.{phase}.png")
        diff = sum(1 for z in ("top", "bottom") for r1, r2 in zip(a[z], b[z]) if max(abs(c1 - c2) for c1, c2 in zip(r1, r2)) > 2)
        same[p] = diff
profiles["kind_vs_scroll_differing_rows"] = same
json.dump(profiles, open(out, "w"), separators=(",", ":"))
print(out, len(keep), "phases")
