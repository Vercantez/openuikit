# Quartz — portable Quartz 2D + Core Animation

A from-scratch, portable reimplementation of Apple **Quartz 2D** (Core Graphics) and a **CALayer** compositor (Core Animation). No GPU backend — the rasterizer and layer tree are CPU. On macOS the harness renders every scene through official `CoreGraphics.framework` / `QuartzCore.framework` **and** through this library, then pixel-diffs them.

Current score vs Apple (56 scenes, 256×256): **97.46 / 100**
- Core Graphics: **97.62**
- Core Animation: **96.96**

## Layout

| Path | What |
|---|---|
| `include/quartz/quartz.h` | Public C API (`QZ*` mirrors `CG*`) |
| `src/` | Software rasterizer, stroke converter, gstate |
| `harness/` | Dual backend (Apple CG + QZ) and scene suite |
| `tools/run_suite.sh` | Build → compare → score → history |
| `metrics/history.jsonl` | SCORE over iterations |
| `output/report.html` | Side-by-side Apple / ours / diff |

## Run the comparison loop

```bash
./tools/run_suite.sh
# or one suite:
./build/qzcompare --suite cg
./build/qzcompare --suite ca --only ca_solid
open output/report.html
```

Requires macOS + Xcode CLT (official CoreGraphics + QuartzCore), CMake, and Python 3.

The library itself (`libquartz`) has **no** Apple dependencies and is meant to be portable.

## Coordinate system

Same as `CGBitmapContext`: user space origin bottom-left, y-up. Backing store is top-down premultiplied RGBA8888.
