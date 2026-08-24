#!/usr/bin/env python3
"""Compare oracle (golden/) output against OpenUIKit (out/) output.

Usage: compare.py [--golden golden] [--out out] [--scenes fixtures/scenes] [--json report.json] [scene ...]
Exit 0 if all compared scenes pass, 1 otherwise.
"""
import argparse, json, os, sys
import numpy as np
from PIL import Image

PIXEL_TOL = 6          # per-channel delta counted as "matching"
LAYOUT_TOL = 0.5       # points

def classify(scene):
    """geometry | text | control, plus layoutOnly flag."""
    kinds = set()
    def walk(v):
        kinds.add(v.get("class", "UIView"))
        for s in v.get("subviews", []):
            walk(s)
    walk(scene["root"])
    layout_only = scene.get("layoutOnly", False)
    if kinds & {"UISwitch", "UIProgressView", "UIButton", "UIImageView", "UIStackView"}:
        cat = "control"
    elif "UILabel" in kinds:
        cat = "text"
    else:
        cat = "geometry"
    return cat, layout_only

THRESHOLDS = {"geometry": 99.5, "text": 97.0, "control": 96.0}

# Only these classes are compared structurally; private UIKit implementation
# subviews (UISwitchModernVisualElement, UIButtonLabel, ...) are skipped —
# the pixel comparison is what holds their visual placement to account.
PUBLIC_CLASSES = {"UIView", "UILabel", "UIButton", "UIImageView", "UISwitch",
                  "UIProgressView", "UIStackView"}

def visible_views(dump):
    """Public-class views, excluding entire subtrees rooted at private views."""
    private_prefixes = []
    out = {}
    for v in dump["views"]:  # dumps are in DFS order, parents first
        path = v["path"]
        if any(path == p or path.startswith(p + ".") for p in private_prefixes):
            continue
        if v["class"] not in PUBLIC_CLASSES:
            private_prefixes.append(path)
            continue
        out[path] = v
    return out

def compare_layout(g, o):
    problems = []
    gv = visible_views(g)
    ov = visible_views(o)
    for path in sorted(set(gv) | set(ov)):
        if path not in ov:
            problems.append(f"missing view path='{path}' ({gv[path]['class']})")
            continue
        if path not in gv:
            problems.append(f"extra view path='{path}' ({ov[path]['class']})")
            continue
        a, b = gv[path], ov[path]
        for key in ("frame", "intrinsic", "sizeThatFits200"):
            if key not in a:
                continue
            if key not in b:
                problems.append(f"path='{path}' missing {key}")
                continue
            for i, (x, y) in enumerate(zip(a[key], b[key])):
                if abs(x - y) > LAYOUT_TOL:
                    problems.append(f"path='{path}' {key}[{i}]: golden={x} ours={y}")
    return problems

def compare_pixels(gpath, opath, diff_path):
    gi = np.asarray(Image.open(gpath).convert("RGBA"), dtype=np.int16)
    oi = np.asarray(Image.open(opath).convert("RGBA"), dtype=np.int16)
    if gi.shape != oi.shape:
        return None, f"size mismatch golden={gi.shape} ours={oi.shape}"
    # compare over white and composite alpha (both RGBA already)
    delta = np.abs(gi - oi).max(axis=2)
    match = (delta <= PIXEL_TOL)
    score = 100.0 * match.mean()
    mae = float(np.abs(gi - oi).mean())
    if score < 100.0 and diff_path:
        heat = np.zeros((*delta.shape, 3), dtype=np.uint8)
        heat[..., 0] = np.clip(delta * 4, 0, 255)          # red = diff magnitude
        heat[..., 1] = np.where(match, 60, 0)              # dim green where matching
        Image.fromarray(heat).save(diff_path)
    return {"score": round(score, 3), "mae": round(mae, 3)}, None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--golden", default="golden")
    ap.add_argument("--out", default="out")
    ap.add_argument("--scenes", default="fixtures/scenes")
    ap.add_argument("--json", default=None)
    ap.add_argument("scene_names", nargs="*")
    args = ap.parse_args()

    names = args.scene_names or sorted(
        f[:-5] for f in os.listdir(args.scenes) if f.endswith(".json"))
    diffdir = os.path.join(args.out, "diffs")
    os.makedirs(diffdir, exist_ok=True)

    report, all_pass = [], True
    for name in names:
        scene = json.load(open(os.path.join(args.scenes, name + ".json")))
        cat, layout_only = classify(scene)
        entry = {"scene": name, "category": cat}

        gl = os.path.join(args.golden, name + ".layout.json")
        ol = os.path.join(args.out, name + ".layout.json")
        if not os.path.exists(ol):
            entry["status"] = "MISSING"
            entry["layout_problems"] = ["no output from openrender"]
            all_pass = False
            report.append(entry)
            continue
        problems = compare_layout(json.load(open(gl)), json.load(open(ol)))
        entry["layout_problems"] = problems
        layout_ok = not problems

        pixel_ok = True
        if not layout_only:
            res, err = compare_pixels(
                os.path.join(args.golden, name + ".png"),
                os.path.join(args.out, name + ".png"),
                os.path.join(diffdir, name + ".diff.png"))
            if err:
                entry["pixel_error"] = err
                pixel_ok = False
            else:
                entry.update(res)
                entry["threshold"] = THRESHOLDS[cat]
                pixel_ok = res["score"] >= THRESHOLDS[cat]
        else:
            entry["pixel"] = "skipped (layoutOnly)"

        entry["status"] = "PASS" if (layout_ok and pixel_ok) else "FAIL"
        if entry["status"] == "FAIL":
            all_pass = False
        report.append(entry)

    w = max(len(r["scene"]) for r in report)
    for r in report:
        score = f"{r.get('score', '—'):>8}" if isinstance(r.get("score"), float) else f"{'—':>8}"
        nl = len(r.get("layout_problems", []))
        print(f"{r['status']:7} {r['scene']:{w}} [{r['category']:8}] pixels={score}  layout_issues={nl}")
        for p in r.get("layout_problems", [])[:5]:
            print(f"        · {p}")
        if nl > 5:
            print(f"        · ... {nl - 5} more")

    npass = sum(1 for r in report if r["status"] == "PASS")
    print(f"\n{npass}/{len(report)} scenes pass")
    if args.json:
        json.dump(report, open(args.json, "w"), indent=1)
    sys.exit(0 if all_pass else 1)

main()
