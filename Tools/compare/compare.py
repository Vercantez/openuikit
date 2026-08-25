#!/usr/bin/env python3
"""Compare oracle (golden/) output against OpenUIKit (out/) output.

Usage: compare.py [--golden golden] [--out out] [--scenes fixtures/scenes] [--json report.json] [scene ...]
Exit 0 if all compared scenes pass, 1 otherwise.

Animation scenes (spec v3, top-level "animations" + "captureTimes"): every
captured frame <name>.t<ms>.png is compared with the scene's category
threshold; layout (<name>.layout.json, the t=0 model state) is compared once.
The scene passes iff layout passes and EVERY frame passes.
"""
import argparse, json, os, sys
import numpy as np
from PIL import Image

PIXEL_TOL = 6          # per-channel delta counted as "matching"
LAYOUT_TOL = 0.5       # points

# Chrome scene classes (spec v5 — M10): system-drawn chrome dominates these
# scenes (bar materials / edge effects, cell chrome, sheet presentation).
CHROME_CLASSES = {"UITableView", "UINavigationStack", "UITabBarStack"}

def classify(scene):
    """geometry | effects | text | control | chrome, plus layoutOnly flag.

    Shadows/gradients (spec v2) do not change a scene's category by
    themselves: if the scene also has text/controls its existing category
    (and threshold) applies. A gradient-only scene stays "geometry";
    a shadow scene with no text/controls becomes "effects" (looser
    threshold — shadow blur covers many pixels).

    Chrome (spec v5) outranks everything: any UITableView /
    UINavigationStack / UITabBarStack in the tree, or a top-level "modal",
    makes the scene "chrome" — large regions of system-drawn material
    (glass platters, edge-effect gradients, sheet shadows) warrant the
    loosest threshold.
    """
    kinds = set()
    has_shadow = [False]
    def walk(v):
        kinds.add(v.get("class", "UIView"))
        if v.get("shadowOpacity", 0):
            has_shadow[0] = True
        for s in v.get("subviews", []):
            walk(s)
    walk(scene["root"])
    layout_only = scene.get("layoutOnly", False)
    if scene.get("modal") or (kinds & CHROME_CLASSES):
        cat = "chrome"
    elif kinds & {"UISwitch", "UIProgressView", "UIButton", "UIImageView", "UIStackView",
                  "UITextField", "UITextView"}:
        cat = "control"
    elif "UILabel" in kinds:
        cat = "text"
    elif has_shadow[0]:
        cat = "effects"
    else:
        cat = "geometry"
    return cat, layout_only

THRESHOLDS = {"geometry": 99.5, "effects": 98.0, "text": 97.0, "control": 96.0,
              "chrome": 95.0}

def capture_suffix(t):
    """Frame-file suffix for a capture time: ms, zero-padded to >= 3 digits
    (0.08 -> 't080', 1.0 -> 't1000'). Mirrors captureSuffix in SceneKit.swift."""
    return "t%03d" % round(t * 1000)

# Only these classes are compared structurally; private UIKit implementation
# subviews (UISwitchModernVisualElement, UIButtonLabel, ...) are skipped —
# the pixel comparison is what holds their visual placement to account.
PUBLIC_CLASSES = {"UIView", "UILabel", "UIButton", "UIImageView", "UISwitch",
                  "UIProgressView", "UIStackView", "UIGradientView",
                  "UIScrollView", "UITextField", "UITextView",
                  # spec v5 chrome. Their INTERNALS (cells, bars, controller
                  # container views) are private on both sides — only the
                  # chrome view's own frame is compared structurally; pixels
                  # hold the chrome itself to account.
                  "UITableView", "UINavigationStack", "UITabBarStack"}

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
    # Hit tests (spec v4): exact path equality, probe by probe.
    gh, oh = g.get("hitTests"), o.get("hitTests")
    if gh is not None or oh is not None:
        gh, oh = gh or [], oh or []
        if len(gh) != len(oh):
            problems.append(f"hitTests count: golden={len(gh)} ours={len(oh)}")
        else:
            for i, (a, b) in enumerate(zip(gh, oh)):
                if a.get("point") != b.get("point"):
                    problems.append(
                        f"hitTests[{i}] point: golden={a.get('point')} ours={b.get('point')}")
                elif a.get("path") != b.get("path"):
                    problems.append(
                        f"hitTests[{i}] at {a.get('point')}: "
                        f"golden path={a.get('path')!r} ours={b.get('path')!r}")
    return problems

def compare_pixels(gpath, opath, diff_path, golden_premultiplied=False):
    """Composite both images over white (each with its own alpha encoding)
    and compare the result plus the raw alpha channel.

    openrender always writes straight (unassociated) alpha, the PNG norm.
    Goldens from Tools/oracle (offscreen layer.render) are straight too, but
    goldens from Tools/oracle2 ("window": true scenes; drawHierarchy →
    UIImage.pngData) carry PREMULTIPLIED RGB in semi-transparent regions —
    golden RGB == straight RGB * alpha exactly. Comparing raw channels there
    flags huge RGB deltas at low alpha even when the renders agree, so the
    caller tells us the golden's encoding and we compare what a viewer sees.
    """
    gi = np.asarray(Image.open(gpath).convert("RGBA"), dtype=np.float64)
    oi = np.asarray(Image.open(opath).convert("RGBA"), dtype=np.float64)
    if gi.shape != oi.shape:
        return None, f"size mismatch golden={gi.shape} ours={oi.shape}"
    ga, oa = gi[..., 3:], oi[..., 3:]
    if golden_premultiplied:
        gw = gi[..., :3] + (255.0 - ga)                # RGB already * alpha
    else:
        gw = gi[..., :3] * ga / 255.0 + (255.0 - ga)
    ow = oi[..., :3] * oa / 255.0 + (255.0 - oa)
    # max over composited RGB delta and alpha delta (alpha itself is encoded
    # identically on both sides, so it is still compared directly)
    delta = np.maximum(np.abs(gw - ow).max(axis=2), np.abs(ga - oa)[..., 0])
    match = (delta <= PIXEL_TOL)
    score = 100.0 * match.mean()
    mae = float(delta.mean())
    if score < 100.0 and diff_path:
        heat = np.zeros((*delta.shape, 3), dtype=np.uint8)
        heat[..., 0] = np.clip(delta * 4, 0, 255).astype(np.uint8)  # red = diff magnitude
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

        # oracle2 ("window" scenes) goldens are premultiplied
        premul = bool(scene.get("window", False))
        pixel_ok = True
        if layout_only:
            entry["pixel"] = "skipped (layoutOnly)"
        elif scene.get("animations"):
            # Multi-frame comparison: every captured frame must pass the
            # scene's category threshold.
            entry["threshold"] = THRESHOLDS[cat]
            frames = []
            for t in scene["captureTimes"]:
                suffix = capture_suffix(t)
                frame = {"t": t}
                opath = os.path.join(args.out, f"{name}.{suffix}.png")
                if not os.path.exists(opath):
                    frame["error"] = "missing frame"
                    pixel_ok = False
                else:
                    res, err = compare_pixels(
                        os.path.join(args.golden, f"{name}.{suffix}.png"), opath,
                        os.path.join(diffdir, f"{name}.{suffix}.diff.png"),
                        golden_premultiplied=premul)
                    if err:
                        frame["error"] = err
                        pixel_ok = False
                    else:
                        frame.update(res)
                        if res["score"] < THRESHOLDS[cat]:
                            pixel_ok = False
                frames.append(frame)
            entry["frames"] = frames
            scores = [f["score"] for f in frames if "score" in f]
            if scores:
                entry["score"] = min(scores)   # worst frame headlines the scene
                entry["mae"] = max(f["mae"] for f in frames if "mae" in f)
        else:
            res, err = compare_pixels(
                os.path.join(args.golden, name + ".png"),
                os.path.join(args.out, name + ".png"),
                os.path.join(diffdir, name + ".diff.png"),
                golden_premultiplied=premul)
            if err:
                entry["pixel_error"] = err
                pixel_ok = False
            else:
                entry.update(res)
                entry["threshold"] = THRESHOLDS[cat]
                pixel_ok = res["score"] >= THRESHOLDS[cat]

        entry["status"] = "PASS" if (layout_ok and pixel_ok) else "FAIL"
        if entry["status"] == "FAIL":
            all_pass = False
        report.append(entry)

    w = max(len(r["scene"]) for r in report)
    for r in report:
        score = f"{r.get('score', '—'):>8}" if isinstance(r.get("score"), float) else f"{'—':>8}"
        nl = len(r.get("layout_problems", []))
        print(f"{r['status']:7} {r['scene']:{w}} [{r['category']:8}] pixels={score}  layout_issues={nl}")
        if "frames" in r:
            details = "  ".join(
                f"t{f['t']:g}={f['score']}" if "score" in f else f"t{f['t']:g}=({f['error']})"
                for f in r["frames"])
            print(f"        frames: {details}")
        for p in r.get("layout_problems", [])[:5]:
            print(f"        · {p}")
        if nl > 5:
            print(f"        · ... {nl - 5} more")

    npass = sum(1 for r in report if r["status"] == "PASS")
    print(f"\n{npass}/{len(report)} scenes pass")
    if args.json:
        json.dump(report, open(args.json, "w"), indent=1)
    sys.exit(0 if all_pass else 1)

if __name__ == "__main__":
    main()
