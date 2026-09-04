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

# Structural gates (see docs/SCENE_SPEC.md "Structural diff gate").
#
# The percentage score is blind to a small region being COMPLETELY wrong on a
# large canvas: navbar_large once passed its 95 % threshold while missing two
# whole letters of "Library", because the missing glyphs were 0.3 % of the
# pixels. Two checks run on the SEVERE diff mask, both independent of the
# percentage, because one signal provably cannot cover both failure shapes.
#
# 1. BLOB — the largest 8-connected component of the severe mask. Catches a
#    contiguous chunk of the render being wrong: a displaced solid region, or
#    a missing glyph big enough to form one blob.
#
#    Calibration (2026-08-25, all 81 scenes / 135 frames):
#      worst legitimate component  33.2 pt^2  (modal_sheet — one stem of the
#                                              22 pt bold title; window-mode
#                                              glyph rasterization residual)
#      two deleted 34 pt glyphs   248.8 pt^2  FAILS
#      a UISwitch shifted 3 pt    268.2 pt^2  FAILS
#      a solid block shifted 6 pt 720.0 pt^2  FAILS
#    80 pt^2 sits 2.4x above the worst legitimate residual and 3.1x below the
#    smallest corruption it has to catch.
#
# 2. CONTENT ABSENCE — the golden has structure here and our render is FLAT.
#    Catches missing BODY text, which the blob check provably cannot: at 17 pt
#    a glyph's stems are ~2 px wide, so an erased word yields one small
#    component per stem (31 pt^2) rather than one large blob — numerically
#    indistinguishable from modal_sheet's legitimate 33.2 pt^2 residual.
#    Merging fragments (dilation / a link distance) was measured and does NOT
#    fix it: it grows the legitimate residual FASTER than the corruption
#    (at a 1 pt link, modal_sheet 33 -> 73 while the erased word stays at 31).
#    Eroding to keep only solid strokes fails the other way (the erased word
#    drops to 5.5, below modal_sheet's 6.2).
#
#    What does separate them is not size but KIND: missing content leaves our
#    region blank where the golden has ink, while a rasterization residual
#    leaves both regions similarly structured. So for each substantial
#    component, compare the local standard deviation of luma over its padded
#    bounding box.
#
#    Calibration (same sweep):
#      erased 17 pt body text     our std  0.00, ratio 0.000  FAILS
#      two deleted 34 pt glyphs   our std  3.70, ratio 0.036  FAILS
#      worst legitimate           our std 14.98, ratio 0.252  (stack_alignment)
#      next legitimate            our std 21.52, ratio 0.334  (stack_mixed)
#    Both conditions must hold to fire, so the gate errs toward silence: the
#    ratio bound sits 3.3x above the worst corruption and 2.1x below the worst
#    legitimate frame, the absolute bound 2.7x / 1.5x.
STRUCT_DELTA = 150     # per-pixel delta that counts as "plainly wrong", not
                       # a tolerance residual (25x PIXEL_TOL)
STRUCT_MAX_BLOB = 80.0 # points^2 of contiguous severe diff allowed

STRUCT_MIN_COMPONENT = 1.0    # pt^2 — smaller components are specks, not content.
                              # Was 4.0, which skipped punctuation-scale glyphs:
                              # an erased 2.5 pt^2 dot of an "i" in demo_settings
                              # passed at 4.0 and fails at 1.0. Lowering it is
                              # free — the whole 81-scene suite stays clean all
                              # the way down to 0.25 — and 1.0 still demands a
                              # real cluster (4 device pixels at 2x) rather than
                              # a lone pixel.
STRUCT_ABSENCE_PAD = 1.0      # pt of context around a component's bbox
STRUCT_ABSENCE_GOLDEN_STD = 20.0  # the golden must genuinely have content there
STRUCT_ABSENCE_OUR_STD = 10.0     # ...and ours must be essentially featureless
STRUCT_ABSENCE_RATIO = 0.12       # ...both absolutely and relative to the golden

# Chrome scene classes (spec v5 — M10): system-drawn chrome dominates these
# scenes (bar materials / edge effects, cell chrome, sheet presentation).
# v5.3 (M13) adds UICollectionView (tiled cell content over system-drawn
# material) and UIToolbar (a bar of iOS 26 glass platters, the same
# system-drawn material every other chrome class carries).
CHROME_CLASSES = {"UITableView", "UICollectionView", "UINavigationStack",
                  "UITabBarStack", "UIToolbar"}

def classify(scene):
    """geometry | effects | text | control | chrome, plus layoutOnly flag.

    Shadows/gradients (spec v2) do not change a scene's category by
    themselves: if the scene also has text/controls its existing category
    (and threshold) applies. A gradient-only scene stays "geometry";
    a shadow scene with no text/controls becomes "effects" (looser
    threshold — shadow blur covers many pixels).

    Chrome (spec v5) outranks everything: any UITableView /
    UICollectionView / UINavigationStack / UITabBarStack / UIToolbar in the
    tree, or a top-level "modal" or "alert" (spec v5.2 — M12), makes the
    scene "chrome" — large regions of system-drawn material (glass
    platters, edge-effect gradients, sheet shadows, the alert card's
    blurred platter) plus tiled cell content warrant the loosest
    threshold.
    """
    kinds = set()
    has_shadow = [False]
    def walk(v):
        kinds.add(v.get("class", "UIView"))
        # A scroll view's pull-to-refresh control (spec v5.3) is a CONTROL
        # even though it is spelled as a key, not as a class.
        if v.get("refreshControl"):
            kinds.add("UIRefreshControl")
        if v.get("shadowOpacity", 0):
            has_shadow[0] = True
        for s in v.get("subviews", []):
            walk(s)
    walk(scene["root"])
    layout_only = scene.get("layoutOnly", False)
    if scene.get("modal") or scene.get("alert") or (kinds & CHROME_CLASSES):
        cat = "chrome"
    elif kinds & {"UISwitch", "UIProgressView", "UIButton", "UIImageView", "UIStackView",
                  "UITextField", "UITextView", "UISlider", "UISegmentedControl",
                  "UIActivityIndicatorView", "UIPageControl",
                  "UIRefreshControl", "UISearchBar", "UIStepper", "UIPickerView"}:
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
                  # App-compat controls. UISlider's real subtree is private
                  # on the golden side (_UISliderGlassVisualElement), so it
                  # compares cleanly; UISegmentedControl and
                  # UIActivityIndicatorView expose PUBLIC-class internals
                  # (UIImageView) in real UIKit's dump and are therefore
                  # left out — their whole subtree is skipped structurally
                  # and the pixels hold them to account.
                  "UISlider",
                  # spec v5 chrome. Their INTERNALS (cells, bars, controller
                  # container views) are private on both sides — only the
                  # chrome view's own frame is compared structurally; pixels
                  # hold the chrome itself to account. (A collection view's
                  # cells dump as the scene's own cell class on both sides,
                  # and real UIKit's contentView is a bare "UIView" where
                  # ours is a private forwarding subclass — so the cell
                  # subtree must stay private, exactly like a table's.)
                  #
                  # UIToolbar (v5.3) is deliberately NOT here: real UIKit's
                  # toolbar subtree exposes PUBLIC-class internals (the glass
                  # platters' UIViews), so including it would compare two
                  # unrelated private trees. Its whole subtree is skipped and
                  # the pixels hold it to account — the same rule
                  # UISegmentedControl follows.
                  "UITableView", "UICollectionView",
                  "UINavigationStack", "UITabBarStack",
                  # controls2. UIRefreshControl's whole subtree is private on
                  # the golden side (_UIRefreshControlModernContentView), so
                  # only its own 60 pt frame is compared structurally and the
                  # spinner's pixels hold the rest to account.
                  #
                  # UISearchBar is deliberately absent even though
                  # `searchbar_placeholder` / `searchbar_text_clear` (v5.4)
                  # now render it: real UIKit's first child is a bare
                  # "UIView" wrapper around _UISearchBarSearchContainerView
                  # where ours is the private UISearchTextField, so including
                  # the bar would compare two unrelated trees. Its pixels hold
                  # it to account, exactly like UIToolbar's. UIStepper and
                  # UIPickerView are absent because no fixture renders them
                  # (docs/KNOWN_GAPS.md).
                  "UIRefreshControl"}

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

def compare_layout(g, o, modal=False):
    problems = []
    if modal:
        # A modal scene's golden dump is the WINDOW (SimScene dumps the
        # presented sheet's private container hierarchy: UITransitionView /
        # UIDropShadowView / ...), so no public path lines up with the
        # port's scene-root dump; the pixels carry the comparison.
        return problems
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

def severe_components(delta):
    """8-connected components of the severe diff mask, as (ys, xs) arrays.

    Union-find over the sparse coordinate list rather than a dense label pass:
    severe masks are a few thousand pixels even on a badly wrong frame, and
    this keeps the tool on numpy + Pillow alone (no scipy).
    """
    ys, xs = np.nonzero(delta > STRUCT_DELTA)   # raster order (row-major)
    n = len(ys)
    if n == 0:
        return []
    pos = {}
    for i in range(n):
        pos[(int(ys[i]), int(xs[i]))] = i
    parent = list(range(n))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    # In raster order only the four already-visited 8-neighbours can exist.
    for i in range(n):
        y, x = int(ys[i]), int(xs[i])
        for dy, dx in ((-1, -1), (-1, 0), (-1, 1), (0, -1)):
            j = pos.get((y + dy, x + dx))
            if j is None:
                continue
            ra, rb = find(i), find(j)
            if ra != rb:
                parent[rb] = ra

    groups = {}
    for i in range(n):
        groups.setdefault(find(i), []).append(i)
    return [(ys[g], xs[g]) for g in groups.values()]


def largest_diff_blob(delta, scale, comps=None):
    """Largest severe component: (area in points^2, bbox in points as
    (x, y, w, h)) — or (0.0, None) when nothing differs severely."""
    comps = severe_components(delta) if comps is None else comps
    if not comps:
        return 0.0, None
    my, mx = max(comps, key=lambda c: len(c[0]))
    bbox = (float(mx.min()) / scale, float(my.min()) / scale,
            float(mx.max() - mx.min() + 1) / scale,
            float(my.max() - my.min() + 1) / scale)
    return len(my) / float(scale * scale), bbox


def missing_content(gluma, oluma, scale, comps):
    """The most content-absent severe component, or None.

    A component qualifies when the GOLDEN has real structure over its padded
    bounding box and OUR render is featureless there — content that simply was
    not drawn, as opposed to content drawn slightly differently. Returns
    (area pt^2, bbox pt, golden std, our std, ratio).
    """
    pad = max(1, int(round(STRUCT_ABSENCE_PAD * scale)))
    worst = None
    for cy, cx in comps:
        area = len(cy) / float(scale * scale)
        if area < STRUCT_MIN_COMPONENT:
            continue
        y0 = max(0, int(cy.min()) - pad)
        y1 = min(gluma.shape[0], int(cy.max()) + 1 + pad)
        x0 = max(0, int(cx.min()) - pad)
        x1 = min(gluma.shape[1], int(cx.max()) + 1 + pad)
        gstd = float(gluma[y0:y1, x0:x1].std())
        ostd = float(oluma[y0:y1, x0:x1].std())
        if gstd < STRUCT_ABSENCE_GOLDEN_STD:
            continue                      # the golden has nothing to miss
        ratio = ostd / gstd
        if ostd > STRUCT_ABSENCE_OUR_STD or ratio > STRUCT_ABSENCE_RATIO:
            continue                      # we drew something there
        bbox = (float(cx.min()) / scale, float(cy.min()) / scale,
                float(cx.max() - cx.min() + 1) / scale,
                float(cy.max() - cy.min() + 1) / scale)
        cand = (area, bbox, gstd, ostd, ratio)
        if worst is None or area > worst[0]:
            worst = cand
    return worst


def compare_pixels(gpath, opath, diff_path, golden_premultiplied=False, scale=1):
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
    comps = severe_components(delta)
    blob, bbox = largest_diff_blob(delta, scale, comps)
    absent = missing_content(gw.mean(axis=2), ow.mean(axis=2), scale, comps)
    if score < 100.0 and diff_path:
        heat = np.zeros((*delta.shape, 3), dtype=np.uint8)
        heat[..., 0] = np.clip(delta * 4, 0, 255).astype(np.uint8)  # red = diff magnitude
        heat[..., 1] = np.where(match, 60, 0)              # dim green where matching
        heat[..., 2] = np.where(delta > STRUCT_DELTA, 255, 0)  # blue = severe mask
        Image.fromarray(heat).save(diff_path)
    res = {"score": round(score, 3), "mae": round(mae, 3), "blob": round(blob, 1)}
    if bbox:
        res["blob_bbox"] = [round(v, 1) for v in bbox]
    if absent:
        area, abox, gstd, ostd, ratio = absent
        res["missing"] = {"area": round(area, 1),
                          "bbox": [round(v, 1) for v in abox],
                          "golden_std": round(gstd, 2),
                          "our_std": round(ostd, 2),
                          "ratio": round(ratio, 3)}
    return res, None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--golden", default="golden")
    ap.add_argument("--out", default="out")
    ap.add_argument("--scenes", default="fixtures/scenes")
    ap.add_argument("--json", default=None)
    ap.add_argument("scene_names", nargs="*")
    ap.add_argument("--golden-straight-alpha", action="store_true",
                    help="every golden PNG carries straight alpha (SimScene "
                         "captures since the capture-format round), window "
                         "scenes included")
    ap.add_argument("--golden-premultiplied", action="store_true",
                    help="every golden PNG is premultiplied (simulator captures)")
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
        problems = compare_layout(json.load(open(gl)), json.load(open(ol)),
                                  modal=bool(scene.get("modal")))
        entry["layout_problems"] = problems
        layout_ok = not problems

        # oracle2 ("window" scenes) goldens are premultiplied, and so is
        # every drawHierarchy capture from the iOS simulator
        # (--golden-premultiplied, scripts/ios_suite.sh).
        # Window-scene goldens from oracle2 (UIImage.pngData) are premultiplied;
        # SimScene captures are straight alpha since the capture-format round
        # (--golden-straight-alpha, which scripts/ios_suite.sh passes).
        premul = (bool(scene.get("window", False)) and not args.golden_straight_alpha) \
            or args.golden_premultiplied
        scale = scene.get("scale", 1)
        pixel_ok = True
        struct_ok = True
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
                        golden_premultiplied=premul, scale=scale)
                    if err:
                        frame["error"] = err
                        pixel_ok = False
                    else:
                        frame.update(res)
                        if res["score"] < THRESHOLDS[cat]:
                            pixel_ok = False
                        if res["blob"] > STRUCT_MAX_BLOB:
                            struct_ok = False
                        if "missing" in res:
                            struct_ok = False
                            entry.setdefault("missing", res["missing"])
                frames.append(frame)
            entry["frames"] = frames
            scores = [f["score"] for f in frames if "score" in f]
            if scores:
                entry["score"] = min(scores)   # worst frame headlines the scene
                entry["mae"] = max(f["mae"] for f in frames if "mae" in f)
                entry["blob"] = max(f["blob"] for f in frames if "blob" in f)
        else:
            res, err = compare_pixels(
                os.path.join(args.golden, name + ".png"),
                os.path.join(args.out, name + ".png"),
                os.path.join(diffdir, name + ".diff.png"),
                golden_premultiplied=premul, scale=scale)
            if err:
                entry["pixel_error"] = err
                pixel_ok = False
            else:
                entry.update(res)
                entry["threshold"] = THRESHOLDS[cat]
                pixel_ok = res["score"] >= THRESHOLDS[cat]
                struct_ok = res["blob"] <= STRUCT_MAX_BLOB and "missing" not in res

        if not struct_ok:
            problems = []
            if entry.get("blob", 0) > STRUCT_MAX_BLOB:
                problems.append(
                    f"contiguous wrong region {entry['blob']} pt^2 exceeds "
                    f"{STRUCT_MAX_BLOB} pt^2 (delta > {STRUCT_DELTA})"
                    + (f" at {entry['blob_bbox']}" if "blob_bbox" in entry else ""))
            if "missing" in entry:
                m = entry["missing"]
                problems.append(
                    f"content missing at {m['bbox']}: the golden has structure "
                    f"there (std {m['golden_std']}) and ours is flat "
                    f"(std {m['our_std']}, ratio {m['ratio']})")
            entry["structural"] = problems

        entry["status"] = "PASS" if (layout_ok and pixel_ok and struct_ok) else "FAIL"
        if entry["status"] == "FAIL":
            all_pass = False
        report.append(entry)

    w = max(len(r["scene"]) for r in report)
    for r in report:
        score = f"{r.get('score', '—'):>8}" if isinstance(r.get("score"), float) else f"{'—':>8}"
        blob = f"{r.get('blob', '—'):>6}" if isinstance(r.get("blob"), float) else f"{'—':>6}"
        nl = len(r.get("layout_problems", []))
        print(f"{r['status']:7} {r['scene']:{w}} [{r['category']:8}] pixels={score}  "
              f"blob={blob}  layout_issues={nl}")
        for p in r.get("structural", []):
            print(f"        · STRUCTURAL: {p}")
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
