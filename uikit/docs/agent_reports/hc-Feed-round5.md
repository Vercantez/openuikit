# Feed t2800/t3800/t4800 — scroll-edge pocket blur

## What was below the bar

Feed conformance captures after `scroll-300` (t2800, and t3800/t4800 which
keep that offset) scored **95.96** against the 97.5 bar, blob 3.5 pt², 0
layout issues. Frames already matched (inline "Feed" `[167.5, 21.5, 39.5, 21]`,
cards, offset 352). 39 % of the 64 pt bar strip failed PIXEL_TOL 6: the port's
8 pt content-blur pocket turned "Morning briefing" into a 245 cloud (iOS 233)
and spread the 1 pt card sliver 12 pt down.

## Probe

`/tmp/probe_scroll_edge_white.json` + `_grouped.json`, captured
`SIM_DEVICE=2x` on the iPhone SE / iOS 26.1. Collapsed large-title bar
(`contentOffset` 160) over 50 pt red/green/blue/black/gray columns.

- `ScrollEdgeEffectView` `[0, 0, 375, 118.8]` in the scroll view.
- Wash toward the VC background (white 255 / grouped 242,242,247), same
  wash-vs-y on both: peak **0.83** at y = 12, 0 at y ≈ 102.
- Red|green edge at y = 8…20 (inline-title band): 10–90 % mix is **5 pt**;
  erf fit **σ = 1.85** (rms 1.1). Catalyst's 8 pt kernel is 4× too wide.

## Rule

iOS-cut `UINavigationBar.pocketBlurSigma = 1.85`; Catalyst keeps 8
(`golden/navbar_inline`). Guard: `OpenUIKitRuntime.systemFontCut == .iOS`.

## Before / after (SKIP_CAPTURE=1, same goldens)

| capture | before | after | blob | layout |
|---|---|---|---|---|
| t200 | 99.658 | 99.658 | 0 | 0 |
| t700 | 99.466 | 99.466 | 32 (spinner) | 0 |
| t1800 | 99.658 | 99.658 | 0 | 0 |
| t2800 | 95.961 | **99.042** | 3.5 | 0 |
| t3800 | 95.956 | **99.038** | 3.5 | 0 |
| t4800 | 95.956 | **99.038** | 3.5 | 0 |

Mean 97.776 → **99.317**, worst 95.956 → **99.038**. Bar-strip fail 39 % → 6.3 %.
Suite `navbar_inline` 98.663 → **99.199**. Catalyst 124/124; real app unchanged;
iOS suite 112/113 (known `corner_radius`).

Left OPEN: wash falloff past y = 24 (iOS 0.24 at y = 64 vs port 0.10 + alpha
ramp 56–72); t700 spinner phase; blob 3.5 at the inline "Feed" glyph.
