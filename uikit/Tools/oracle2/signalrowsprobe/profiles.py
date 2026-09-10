#!/usr/bin/env python3
"""Extract 1 pt pixel columns from the render-server screenshots that
scripts/signal_edge_probe_sim.sh and scripts/signal_rows_probe_sim.sh take,
so the scrim numbers travel with the repo without the 1179x2556 PNGs.

    profiles.py <edge-outdir> <rows-outdir> <out.json>

Columns are sampled at x = 380 pt (no container subview above it) at the
device's 3x scale; rows are point rows 0..851. `edge` phases come from the
Signal-order probe, `rows` phases from the exploratory probe (light-variant
evidence: phase7 = elements added after attach, phase8 = .hard).
"""
import json, sys
from PIL import Image

edge_dir, rows_dir, out = sys.argv[1:4]
X = 380

def column(path):
    im = Image.open(path).convert("RGB")
    return [list(im.getpixel((X * 3, y * 3))) for y in range(im.size[1] // 3)]

profiles = {"x_pt": X, "note": "RGB per point row at x=380 pt from simctl io screenshot (3x)"}
profiles["edge"] = {p: column(f"{edge_dir}/screen-{p}.png") for p in
                    ["rest", "under60", "under0", "under100", "bottomUnder", "bottomRest",
                     "reattach", "hard", "automaticAgain", "hiddenEdge", "noContent"]}
profiles["rows"] = {p: column(f"{rows_dir}/screen-{p}.png") for p in
                    ["phase6", "phase7", "phase8", "phase9", "phase10", "phase12"]}
json.dump(profiles, open(out, "w"), separators=(",", ":"))
print(out, sum(len(v) for v in profiles["edge"].values()) + sum(len(v) for v in profiles["rows"].values()), "rows")
