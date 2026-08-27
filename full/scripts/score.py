#!/usr/bin/env python3
"""score.py -- the scoreboard for the 108-scene suite, three comparisons deep.

Reporting a single "N/108 pixel-identical" number would be misleading, because
a frame can differ from the real-UIKit golden for two completely different
reasons: OpenUIKit's own fidelity to UIKit, or this Mach-O/machorun stack
getting a different answer than the same code gets natively. Those have
different owners, so they are measured separately:

  A) Linux/machorun  vs  macOS-native OpenUIKit   -- isolates THIS stack.
                                                     Any difference is ours.
  B) macOS-native    vs  real-UIKit golden        -- OpenUIKit's own fidelity,
                                                     identical on both platforms.
  C) Linux/machorun  vs  real-UIKit golden        -- the headline, and the sum
                                                     of the two effects above.

Usage: score.py <linux-out-dir> <macos-out-dir> <golden-dir> [scenes-dir]
"""
import os, sys, json
import numpy as np
from PIL import Image


def arr(p):
    return np.asarray(Image.open(p).convert("RGBA"), dtype=np.int16)


def compare(p, q):
    a, b = arr(p), arr(q)
    if a.shape != b.shape:
        return ("dims", None, None)
    d = np.abs(a - b)
    if not d.any():
        return ("identical", 0, 0)
    return ("differ", int(d.any(axis=2).sum()), int(d.max()))


def scene_of(png):
    """boxes_basic.png -> boxes_basic;  anim_fade.t250.png -> anim_fade"""
    s = png[:-4]
    head, _, tail = s.rpartition(".")
    if head and tail.startswith("t") and tail[1:].isdigit():
        return head
    return s


def main():
    lin, mac, gold = sys.argv[1], sys.argv[2], sys.argv[3]
    scenes_dir = sys.argv[4] if len(sys.argv) > 4 else os.path.expanduser("~/uikit/fixtures/scenes")

    all_scenes = sorted(f[:-5] for f in os.listdir(scenes_dir) if f.endswith(".json"))
    frames = sorted(f for f in os.listdir(lin) if f.endswith(".png"))
    rendered_scenes = sorted({scene_of(f) for f in frames})
    missing_scenes = [s for s in all_scenes if s not in rendered_scenes]

    res = {"A": [[], []], "B": [[], []], "C": [[], []]}
    for f in frames:
        for key, (x, y) in (("A", (mac, lin)), ("B", (gold, mac)), ("C", (gold, lin))):
            px, py = os.path.join(x, f), os.path.join(y, f)
            if not (os.path.exists(px) and os.path.exists(py)):
                continue
            r = compare(px, py)
            res[key][0 if r[0] == "identical" else 1].append((f, r))

    print("SCENES")
    print("  total in fixtures/scenes : %d" % len(all_scenes))
    print("  rendered under machorun  : %d" % len(rendered_scenes))
    print("  did not render (crashed) : %d" % len(missing_scenes))
    print("  frames produced          : %d" % len(frames))
    print()
    labels = {
        "A": "Linux/machorun  vs  macOS-native OpenUIKit   [isolates THIS stack]",
        "B": "macOS-native    vs  real-UIKit golden        [OpenUIKit's own fidelity]",
        "C": "Linux/machorun  vs  real-UIKit golden        [headline: A and B combined]",
    }
    for k in "ABC":
        same, diff = res[k]
        n = len(same) + len(diff)
        print("%s) %s" % (k, labels[k]))
        print("    frames compared : %d" % n)
        print("    identical       : %d" % len(same))
        print("    differing       : %d" % len(diff))
        if diff:
            worst = sorted(diff, key=lambda t: -t[1][2])[:5]
            print("    largest channel deltas:")
            for f, r in worst:
                print("      %-34s %d px, max delta %s" % (f, r[1], r[2]))
        print()

    if missing_scenes:
        print("SCENES THAT DID NOT RENDER (%d) -- listed, never omitted:" % len(missing_scenes))
        for s in missing_scenes:
            print("   ", s)


if __name__ == "__main__":
    main()
