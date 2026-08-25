#!/usr/bin/env python3
"""Regression tests for compare.py's pixel comparison.

Two things are guarded here:

1. Alpha encoding. oracle2 ("window": true) goldens store PREMULTIPLIED RGB
   while openrender writes straight alpha; compare_pixels must treat both
   encodings of the same visual result as a perfect match, and must still
   catch real color/alpha mismatches.
2. The structural gate. A small region being COMPLETELY wrong must fail even
   when the percentage score is far above the category threshold — the
   navbar_large "missing two letters at 99.5 %" blind spot.

Run: python3 Tools/compare/test_compare.py
"""
import os, sys, tempfile
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compare import (compare_pixels, largest_diff_blob, STRUCT_DELTA,
                     STRUCT_MAX_BLOB)


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

    structural_tests(tmp)
    print("test_compare.py: all assertions passed")


def structural_tests(tmp):
    """The gate that closes the navbar_large blind spot."""
    # Component labelling: area is reported in POINTS^2, so the same physical
    # blob must measure the same at scale 1 and scale 2, and diagonal
    # touching must join (8-connectivity).
    m = np.zeros((40, 40))
    m[10:20, 10:20] = 255                       # 10x10 = 100 px
    area, bbox = largest_diff_blob(m, scale=1)
    assert area == 100.0, area
    assert bbox == (10.0, 10.0, 10.0, 10.0), bbox
    area2, _ = largest_diff_blob(m, scale=2)
    assert area2 == 25.0, area2                 # same blob, 2x device scale

    diag = np.zeros((10, 10))
    diag[2, 2] = diag[3, 3] = 255               # touch only at a corner
    assert largest_diff_blob(diag, scale=1)[0] == 2.0, "8-connectivity"

    # Severity floor: a whole-canvas MILD difference is not structural.
    mild = np.full((40, 40), STRUCT_DELTA - 1.0)
    assert largest_diff_blob(mild, scale=1)[0] == 0.0

    # End to end: a large canvas that matches everywhere except one solid
    # 12x12 pt patch — 0.09 % of the pixels, so the percentage score sails
    # past every category threshold, but the gate must see the patch.
    big = 400
    golden = np.zeros((big, big, 4)); golden[...] = [255, 255, 255, 255]
    ours = golden.copy()
    ours[100:124, 100:124] = [0, 0, 0, 255]     # 24x24 px = 12x12 pt at 2x
    res, err = compare_pixels(png(tmp, "gb.png", golden), png(tmp, "ob.png", ours),
                              None, golden_premultiplied=False, scale=2)
    assert err is None, err
    assert res["score"] > 99.6, res["score"]    # would pass every threshold
    assert res["blob"] == 144.0, res["blob"]    # 12 x 12 pt
    assert res["blob"] > STRUCT_MAX_BLOB, "the blind spot must be closed"

    # ... and a diff of the same total area SCATTERED as single pixels is
    # not structural (that is what an antialiasing residual looks like).
    ours = golden.copy()
    ours[::4, ::4] = [0, 0, 0, 255]
    res, err = compare_pixels(png(tmp, "gs.png", golden), png(tmp, "os.png", ours),
                              None, golden_premultiplied=False, scale=2)
    assert err is None, err
    assert res["blob"] < 1.0, res["blob"]       # one device pixel at 2x
    assert res["blob"] <= STRUCT_MAX_BLOB


main()
