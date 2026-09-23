"""Fit the automatic bottom scroll-edge material under an iOS 26 toolbar.

Reads the three window captures run.sh writes (edge-white/gray/black.png,
iPhone 16 @3x) and fits, per pixel row, out = in * (1 - a) + k * B * a where
B is the scroll view's background (white, 242/242/247, black):
  * a from the white column over the black backdrop (B = 0: out = 255(1 - a)),
  * k from the black column over the white and gray backdrops,
then checks the model on five gray-scale columns x three backdrops and writes
edge-model-ios26.1.json next to this script (a per 1/3 pt from the effect
view's top pixel row, 711.2 pt -> row 2134).

    python3 fit.py [captures-dir]
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
S = (sys.argv[1] if len(sys.argv) > 1 else HERE + "/captures") + "/"
W = np.asarray(Image.open(S + "edge-white.png").convert("RGB")).astype(float)
G = np.asarray(Image.open(S + "edge-gray.png").convert("RGB")).astype(float)
K = np.asarray(Image.open(S + "edge-black.png").convert("RGB")).astype(float)


def col(img, i):
    """Mean over column i's inner 12 pt, per pixel row (columns are 20 pt wide
    from x 150: white, 242/242/247, 200, 128, black, red, blue)."""
    x0 = (150 + 20 * i + 4) * 3
    return img[:, x0:x0 + 36].mean(axis=1)


top = int(round(711.2 * 3))
alpha = 1 - col(K, 0)[:, 0] / 255.0
kw = col(W, 4)[:, 0] / (255.0 * np.maximum(alpha, 1e-6))
kg = col(G, 4)[:, 2] / (247.0 * np.maximum(alpha, 1e-6))
for y in range(top, 2556, 15):
    print(f"y {y / 3:7.2f} a={alpha[y]:.4f} k_white={kw[y]:.4f} k_gray={kg[y]:.4f}")
backs = {"white": (W, (255, 255, 255)), "gray": (G, (242, 242, 247)), "black": (K, (0, 0, 0))}
colors = [(255, 255, 255), (242, 242, 247), (200, 200, 200), (128, 128, 128), (0, 0, 0)]
k = float(np.median(np.concatenate([kw[top + 60:2556 - 10], kg[top + 60:2556 - 10]])))
print("k =", round(k, 4))
worst = 0.0
for name, (img, B) in backs.items():
    for i, c in enumerate(colors):
        o = col(img, i)[top:]
        a = alpha[top:, None]
        pred = np.array(c)[None, :] * (1 - a) + np.array(B)[None, :] * k * a
        e = float(np.abs(o - pred).max())
        worst = max(worst, e)
        print(f"{name:5s} column {i} max error {e:.2f}")
print("worst", round(worst, 2))
json.dump({"top_px": top, "k": round(k, 4), "worst_error": round(worst, 2),
           "alpha_px": [round(float(v), 4) for v in alpha[top:]]},
          open(os.path.join(HERE, "edge-model-ios26.1.json"), "w"), indent=0)
