#!/usr/bin/env python3
"""Regression tests for compare.py's alpha-encoding handling.

oracle2 ("window": true) goldens store PREMULTIPLIED RGB while openrender
writes straight alpha; compare_pixels must treat both encodings of the same
visual result as a perfect match, and must still catch real color/alpha
mismatches. Run: python3 Tools/compare/test_compare.py
"""
import os, sys, tempfile
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compare import compare_pixels


def png(tmp, name, arr):
    path = os.path.join(tmp, name)
    Image.fromarray(arr.astype(np.uint8), "RGBA").save(path)
    return path


def score(tmp, golden, ours, premul):
    res, err = compare_pixels(png(tmp, "g.png", golden), png(tmp, "o.png", ours),
                              None, golden_premultiplied=premul)
    assert err is None, err
    return res["score"]


def main():
    tmp = tempfile.mkdtemp()
    H = W = 8

    # Straight-alpha pixel [115,115,123,a=30] over transparent (the
    # demo_settings search pill); its premultiplied form is [14,14,14,30].
    straight = np.zeros((H, W, 4)); straight[...] = [115, 115, 123, 30]
    premul = np.zeros((H, W, 4)); premul[...] = [14, 14, 14, 30]

    # 1. premul golden vs straight ours: same visual -> match with the flag,
    #    mismatch without it (the raw-channel bug this guards against).
    assert score(tmp, premul, straight, premul=True) == 100.0, "premul golden must match"
    assert score(tmp, premul, straight, premul=False) == 0.0, "flag off must expose the encoding gap"

    # 2. straight golden vs identical straight ours still matches (oracle1 path).
    assert score(tmp, straight, straight, premul=False) == 100.0

    # 3. real color difference is still caught in both modes.
    red = np.zeros((H, W, 4)); red[...] = [255, 0, 0, 255]
    blue = np.zeros((H, W, 4)); blue[...] = [0, 0, 255, 255]
    assert score(tmp, red, blue, premul=False) == 0.0
    assert score(tmp, red, blue, premul=True) == 0.0

    # 4. alpha coverage still matters even when the over-white composite
    #    agrees: white@a=0 vs white@a=255 both composite to white.
    clear = np.zeros((H, W, 4)); clear[...] = [255, 255, 255, 0]
    opaque_white = np.zeros((H, W, 4)); opaque_white[...] = [255, 255, 255, 255]
    assert score(tmp, clear, opaque_white, premul=False) == 0.0
    assert score(tmp, clear, opaque_white, premul=True) == 0.0

    # 5. opaque pixels: premul == straight, flag must be a no-op.
    solid = np.zeros((H, W, 4)); solid[...] = [40, 80, 120, 255]
    assert score(tmp, solid, solid, premul=True) == 100.0

    print("test_compare.py: all assertions passed")


main()
