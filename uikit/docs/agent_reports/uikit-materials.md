# uikit-materials — UIVisualEffectView / UIBlurEffect / UIGlassEffect

APP LADDER §4 row 3. Probe `/tmp/materials-probe` and
`/tmp/materials-dark-probe` on **iPhone SE 3rd gen 2x / iOS 26.1**
(`OpenUIKit-2x-uikit-materials`). Tables in `docs/MATERIALS.md`. Nothing
was fitted to a comparison score.

There is **no** `UIView.glassEffect` in iOS 26.1 UIKit headers. The port
matches `UIGlassEffect.h`: `Style.regular=0` / `.clear=1`,
`init(style:)`, `isInteractive`, `tintColor`, `UIGlassContainerEffect.spacing`
default 0. Glass `copy()` is a new object; container `copy()` is self.

## Mixes (iOS cut only)

Classic `UIBlurEffect` CAFilter: gaussianBlur → colorSaturate 1.8 →
source-over overlay. Saturation **clamped to `[0, alpha]`** before the
overlay.

| style | σ | sat | overlay | yellow interior |
|---|---|---|---|---|
| extraLight / prominent | 20 | 1.8 | rgba(0.97,0.97,0.97,0.80) | (249,233,198) |
| light / regular (light) | 30 | 1.8 | rgba(1,1,1,0.30) | (255,199,77) |
| dark / regular (dark) | 20 | 1.8 | rgba(0.11,0.11,0.11,0.73) | (89,68,20) |

System materials: two-unknown gray mix from white/black + dumped radius/sat.
`luminanceCurveMap` LUT is not a closed chroma model. Light systemMaterial
over yellow (255,236,192) vs mix (245,230,198) is OPEN. Dark over gray33
is 50 vs mix 41 (LUT `inputValues` 0.16/0.26/0.1/0.1 dumped, not modelled).

UIGlassEffect.regular light: white 251 / black 175, α=179/255, sat=2
unclamped. Dark: white 91 / black 24, α=188/255, sat=2.225 from red G
(red R predicted 141 vs 150). Clear: white 255 / black 19 both appearances.

Tab-bar platter: existing α=222/255, T=220/222, σ=2.25 plus **unclamped
Rec.709 sat 5.651** from yellow (242,179,64)→(255,240,156). Same s hits
red (255,201,204) and green (162,255,189) at Δ≤1. Clamp-before-tint
floored yellow B at 220. Dark bar / pad mixes stay sat=1.

Vibrancy label compositing: no closed mix. Left OPEN.

## Materials conformance (all axes)

One 200×120 effect. Classic styles over probe yellow; systemMaterial /
glass / clear over gray33 (closed gray mix). Styles tab hides the tab bar
so captures grade the effect, not Tabs t2000 leftover. t8000 is the Bar
tab (same class as Tabs t2000).

| axis | t1000 XL | t2000 Lt | t3000 Dk | t4000 Reg | t5000 Mat | t6000 Gl | t7000 Clr | t8000 Bar |
|---|---|---|---|---|---|---|---|---|
| light | 100.000 | 100.000 | 100.000 | 100.000 | 100.000 | 99.746 | 99.746 | 84.972 |
| rtl | 100.000 | 100.000 | 100.000 | 100.000 | 100.000 | 99.746 | 99.746 | 84.922 |
| ax1 | 100.000 | 100.000 | 100.000 | 100.000 | 100.000 | 99.746 | 99.746 | 84.921 |
| xxxl | 100.000 | 100.000 | 100.000 | 100.000 | 100.000 | 99.746 | 99.746 | 84.910 |
| dark | 100.000 | 100.000 | 100.000 | 100.000 | 100.000 | 99.746 | 99.746 | 89.388 |
| landscape | 100.000 | 100.000 | 100.000 | 100.000 | 100.000 | 99.746 | 99.746 | 77.840 |
| ipad | 98.733 | 98.726 | 98.965 | 98.726 | 98.956 | 99.051 | 99.315 | 98.811 |

Effect-view interiors (PIXEL_TOL 6 crop) ≥97.5 on every style on every
axis. t8000 is tab-bar leftover (`scoreboard/open.txt`).

## Tabs t2000 before / after

`SKIP_CAPTURE=1` vs round-22 `/tmp/hc-conformance-Tabs*` goldens. Other
Tabs rows byte-held (light: only t2000 moved).

| axis | before | after |
|---|---|---|
| light | 84.665 | **84.937** (+0.272) |
| rtl | 84.636 | **84.924** (+0.288) |
| ax1 | 84.629 | **84.948** (+0.319) |
| xxxl | 84.627 | **84.956** (+0.329) |
| dark | 93.210 | 93.210 |
| landscape | 77.611 | 77.612 |
| ipad | 98.657 | 98.657 |

t2000 leftover is **not** the isolated-probe platter mix. In-app golden
platter over yellow is (255,244,208) vs mix (255,240,156); pocket x=30
y=644 is still washed (248,236,216) vs ours raw yellow — light
ScrollEdgeEffectView still paints nothing. Not retuned to the in-app
score.

## Canaries / gates

- Notes light vs `/tmp/hc-conformance-Notes`: **no drops**. t5000
  **98.818 → 98.841** (platter sat on grouped cards).
- Catalyst **124/124**.
- iOS suite **112/113** (`corner_radius` 99.411).
- Real-app floors held **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393**
  (`focus_home` / `ledger` goldens absent, same as prior rows).
- Unit tests: MaterialMixTests, GlassMaterialTests, UIVisualEffectTests,
  ConformanceRegistryTests, CanvasBackdropFilterTests — 80/80.
- Linux `swift:6.2-noble` `openrender` release **complete (274.42 s / 212.50 s)**.
  Fixture render with `OPENUIKIT_FONT_DIR` SFNS: **124/124** vs `golden/`,
  **178/178** byte-identical vs the Mac Catalyst gate.

Open questions: system-material chroma / dark gray33 LUT, glass.clear
chroma, glass.regular dark red R 141 vs 150, tinted glass G/B over white,
vibrancy compositing, Tabs t2000 ScrollEdgeEffectView wash.
