#!/usr/bin/env python3
"""Compare the REAL-iOS goldens of the real-app screen against OpenUIKit's render.

    Tools/compare/compare_realapp.py --golden <dir from realapp_probe_sim.sh> \
        --out <dir from `openrender realapp`> [--diff <dir>]

The real-app screen is not a scene JSON (see Sources/openrender/RealApp.swift),
so Tools/compare/compare.py's scene-driven main() cannot grade it. This
driver reuses compare.py's pixel and layout functions unchanged and prints,
per variant, the same three facts the suite prints: the pixel score, the
largest severe blob, and the layout problems (public classes only, the
LAYOUT_TOL used by every scene).

Exit status is 0 always: this is a measurement, not a gate. The gate is a
separate decision, taken once the numbers have been read.
"""
import argparse, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import compare  # noqa: E402

def window_frames(dump, anchor="UIScrollView"):
    """(class, window-space frame) per view, DFS order, for every view under the
    first view of class `anchor` (the sheet content, which both renderers build
    from the same app source). Real UIKit wraps the presented sheet in private
    containers (UITransitionView/UIDropShadowView) and OpenUIKit in its own
    (_UIPageSheetView), so path equality is meaningless above the scroll view;
    below it the subtree is the app's own view code and must match 1:1.

    A pushed screen needs a different anchor: its table is the app's own
    UITableView SUBCLASS out of the nib, so "UIScrollView" matches nothing.
    Real UIKit still interposes UITransitionView/UIDropShadowView above the
    controller's view, so the anchor is that view's class."""
    by_path = {v["path"]: v for v in dump["views"]}
    def origin(path):
        x = y = 0.0
        parts = path.split(".") if path else []
        for i in range(len(parts) + 1):
            p = ".".join(parts[:i])
            v = by_path.get(p)
            if v is None:
                continue
            x += v["frame"][0]; y += v["frame"][1]
        return x, y
    root = next((v for v in dump["views"] if v["class"] == anchor), None)
    if root is None:
        return None, []
    rows = []
    prefix = root["path"]
    for v in dump["views"]:
        p = v["path"]
        if p == prefix or p.startswith(prefix + "."):
            ox, oy = origin(p)
            rows.append((v["class"], [round(ox, 3), round(oy, 3), v["frame"][2], v["frame"][3]], v.get("text")))
    return root, rows


def compare_sheet(g, o, tol=compare.LAYOUT_TOL, anchor="UIScrollView"):
    groot, grows = window_frames(g, anchor); oroot, orows = window_frames(o, anchor)
    problems = []
    if groot is None or oroot is None:
        return [f"no {anchor}: golden={groot is not None} ours={oroot is not None}"], 0
    n = min(len(grows), len(orows))
    if len(grows) != len(orows):
        problems.append(f"sheet subtree size: golden={len(grows)} ours={len(orows)}")
    for i in range(n):
        gc, gf, gt = grows[i]; oc, of, ot = orows[i]
        if gc != oc:
            problems.append(f"[{i}] class golden={gc} ours={oc}")
            continue
        for k, (a, b) in enumerate(zip(gf, of)):
            if abs(a - b) > tol:
                problems.append(f"[{i}] {gc} frame[{k}]: golden={a} ours={b}")
                break
        # openrender's dump carries no text; compare it only when both do.
        if gt is not None and ot is not None and gt != ot:
            problems.append(f"[{i}] {gc} text golden={gt!r} ours={ot!r}")
    return problems, n


# name -> the class the layout subtree is anchored at (see window_frames).
VARIANTS = {
    "realapp_history_light": "UIScrollView",
    "realapp_settings_light": "UIScrollView",
    "realapp_settings_dark": "UIScrollView",
    # The nib-loaded screen: `ThemeableView` is StorageAndDataUseViewController's
    # own view, straight out of StorageAndDataUseViewController.xib.
    "realapp_storage_light": "ThemeableView",
    # Dynamic Type sizes of realapp_settings_light (window trait override).
    "realapp_settings_light_xs": "UIScrollView",
    "realapp_settings_light_xxxl": "UIScrollView",
    "realapp_settings_light_ax1": "UIScrollView",
    # iPad (A16) portrait of the Settings picker. Goldens are native 2x
    # (compare_pixels uses the dump's screen.scale, not --scale).
    "realapp_settings_light_ipad": "UIScrollView",
    # Firefox Focus Settings: inset-grouped UITableView under a nav bar.
    "realapp_focus_settings_light": "UITableView",
    # Firefox Focus browser home (HomeViewController). Pixel score is the
    # gate once the operator captures the iOS golden; no 1:1 class subtree.
    "realapp_focus_home_light": "UIImageView",
    "realapp_history_light_ipad": "UIScrollView",
    # Same ThemeableView root as the phone storage screen; the iPad row
    # wraps it in a large-title nav, which sits outside this subtree.
    "realapp_storage_light_ipad": "ThemeableView",
    # Hackers feed (weiran/Hackers FeedView). SwiftUI List on real iOS 26
    # is UpdateCoalescingCollectionView; OpenUIKit List is UIScrollView.
    # Class-for-class subtree compare is not 1:1; the pixel score is the
    # gate. Anchor ours at the list scroll view so a missing PNG still
    # prints the layout note.
    "realapp_hackers_feed_light": "UIScrollView",
    # Ledger first screen: inset-grouped UITableView under a nav bar.
    "realapp_ledger_light": "UITableView",
    "realapp_focus_browser_light": "URLBar",
}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--golden", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--diff", default=None)
    ap.add_argument("--scale", type=int, default=2)
    args = ap.parse_args()
    if args.diff:
        os.makedirs(args.diff, exist_ok=True)
    for name, anchor in VARIANTS.items():
        gpng = os.path.join(args.golden, name + ".png")
        opng = os.path.join(args.out, name + ".png")
        glay = os.path.join(args.golden, name + ".layout.json")
        olay = os.path.join(args.out, name + ".layout.json")
        if not (os.path.exists(gpng) and os.path.exists(opng)):
            print(f"{name}: MISSING golden={os.path.exists(gpng)} out={os.path.exists(opng)}")
            continue
        g = json.load(open(glay)) if os.path.exists(glay) else {}
        scale = args.scale
        scr = g.get("screen") if isinstance(g, dict) else None
        if isinstance(scr, dict) and scr.get("scale"):
            scale = scr["scale"]
        diff_path = os.path.join(args.diff, name + ".diff.png") if args.diff else None
        res = compare.compare_pixels(gpng, opng, diff_path, golden_premultiplied=True, scale=scale)
        print(f"{name}: pixels {res}")
        if os.path.exists(glay) and os.path.exists(olay):
            o = json.load(open(olay))
            problems = compare.compare_layout(g, o)
            sp, n = compare_sheet(g, o, anchor=anchor)
            print(f"{name}: {anchor} subtree compared={n} views; problems={len(sp)} (window-space frames, tol {compare.LAYOUT_TOL} pt)")
            for p in sp[:30]:
                print("   ", p)
            if len(sp) > 30:
                print(f"    ... {len(sp) - 30} more")
        else:
            print(f"{name}: layout MISSING golden={os.path.exists(glay)} out={os.path.exists(olay)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
