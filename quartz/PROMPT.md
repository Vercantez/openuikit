# Portable Quartz 2D — iteration prompt

Reimplement Apple Quartz 2D (Core Graphics) and Core Animation (CALayer tree) as a portable CPU library (`QZ*` / `QZLayer*` in `include/quartz/quartz.h`) and **pixel-match official Apple CoreGraphics + QuartzCore** on this Mac.

Harness suites: `--suite cg` (bitmap drawing) and `--suite ca` (`CALayer renderInContext:` vs `QZLayerRenderInContext`).

## Loop

Every iteration:

1. `./tools/run_suite.sh` — builds, renders every scene through Apple Quartz **and** our engine, writes `output/{apple,qz,diff}/*.png` plus `output/metrics.json`.
2. Read `metrics/latest.json` and `metrics/history.jsonl`. Decide if the last change **improved or regressed** SCORE / mean MAE.
3. Open the worst scenes (highest MAE) as PNGs: `output/apple/<name>.png`, `output/qz/<name>.png`, `output/diff/<name>.png`.
4. Fix the root cause in `src/` (rasterizer, stroke, path, blend, CTM, clip, gradients).
5. Re-run. Do not ship a regression. Prefer analytic correctness over hacks that help one scene.

## Success metric

SCORE in `output/metrics.json` is 0–100 from exact pixel match %, close (max channel ≤8) %, and MAE vs Apple.

Done when SCORE ≥ 95 and no scene has MAE > 2.0, or when remaining error is only subpixel AA disagreement on curves/strokes.

## Ground truth

Apple `CGBitmapContext` on this machine: sRGB, premul RGBA, y-up user space, memory top-down. Stroke is centered on the path. Coverage AA, `floor(cov*255)` for coverage, `round(c*255)` for color.

## Do not

- Do not link Apple frameworks into `libquartz`. The library must stay portable.
- Do not weaken tests to inflate SCORE.
- Do not claim completion if `run_suite.sh` was not run this iteration.
