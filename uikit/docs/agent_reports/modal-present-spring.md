# Modal t600 — measured pageSheet present spring

## What was below the bar

Modal t600 (medium sheet, named frame 12 at 60 Hz) scored **92.626** against
the 97.5 bar, blob 105 pt², layout 0. Five `conformance_flow.sh` runs were
identical to 3 dp. Glass-fill top (interior 245) was **359.5** golden vs
**337.0** openhost; rest 317.5 both (t1200). Remaining **42.0 vs 19.5** of
the 349.5 pt travel. The port's duration-fit ζ=1 D=0.4 spring
(ω·D=9.233, ω=23.08) ran ahead of iOS at every overlapping sample.

## Probe

Patched confprobe (seek window 0..35, freeze at
`CASpringAnimation.beginTime + k/60`) plus a `/tmp` Modal script that
captures frames 0..30 of one `sheet-medium` present. Device: iPhone SE
(3rd gen) 2x / iOS 26.1, `SIM_DEVICE_SUFFIX=-modal-present-spring`.
Presentation-layer `UIDropShadowView` model frame is already at rest
(transform 0.957); the visual is the PNG glass-fill top against the
dimmed presenter (centre x vs 2 pt inset).

Glass-fill top y(k), rest 317.5:

| k | t (s) | y | remaining |
|---|---|---|---|
| 0 | 0.000 | off-screen (PNG 255, dim 0) | 1.000 |
| 1 | 0.017 | 643.5 (sliver) | 0.933 |
| 4 | 0.067 | 546.0 | 0.654 |
| 6 | 0.100 | 476.5 | 0.455 |
| 9 | 0.150 | 402.0 | 0.242 |
| 12 | 0.200 | 359.5 | 0.120 |
| 15 | 0.250 | 338.0 | 0.059 |
| 18 | 0.300 | 327.0 | 0.027 |
| 24 | 0.400 | 319.5 | 0.006 |
| 30 | 0.500 | 318.0 | 0.001 |

No extra delay: frame 0 is the FROM state (sheet still at the bottom);
frame 1 has left. Not a UIView keyframe/cubic (easeOut D=0.5 rms 71 pt,
easeInOut rms 127). Critically damped ζ=1, ω=√(1000/3)=**18.2574**
(same ω as `UISheetPhysics.settleOmega`, mass 3 / stiffness 1000)
matches k=4..30 within 0.5 pt (rms 0.28). Free fit ω=18.276, rms 0.26.

CASpringAnimation keys on the drop-shadow view itself were additive
near-zero `position` / `bounds.size` with the UIKit default mass=3
k=1000 c=500 (overdamped ζ=4.56) — those are not the slide. The slide
was read off the pixels, the same way the TableEditor row spring was
fitted from samples.

`UIView.animate(usingSpringWithDamping: 1)` duration-fits
ω·D = 9.2334134764, so D = 9.2334134764 / 18.2574 = **0.50573**.

## Rule

iOS-cut `_UIPageSheetAnimator` uses `iOSPresentSpringDuration` (0.50573)
and `iOSPresentSpringDamping` (1). Catalyst keeps
`presentTransitionDuration` 0.4. Guard:
`OpenUIKitRuntime.systemFontCut == .iOS`.

## Before / after (SKIP_CAPTURE=1, same goldens)

Five `scripts/conformance_flow.sh` runs, t600 identical to 3 dp
(**97.588** all). Rest captures did not move.

| capture | before | after | blob | layout |
|---|---|---|---|---|
| t200 | 99.843 | 99.843 | 4.2 | 0 |
| t600 | 92.626 | **97.588** | 105 → 17 | 0 |
| t1200 | 97.805 | 97.805 | 4.5 | 0 |
| t2100 | 99.843 | 99.843 | 4.2 | 0 |
| t3200 | 99.116 | 99.116 | 2.5 | 0 |
| t4100 | 99.843 | 99.843 | 4.2 | 0 |
| t5200 | 97.902 | 97.902 | 4.5 | 6 |
| t6100 | 99.843 | 99.843 | 4.2 | 0 |
| t7200 | 98.524 | 98.524 | 6.2 | 10 |
| t8100 | 99.843 | 99.843 | 4.2 | 0 |
| t9200 | 99.106 | 99.106 | 11.0 | 0 |
| t10100 | 99.831 | 99.831 | 4.2 | 5 |

Frame 12 glass-fill top 337.0 → **360.0** vs golden 359.5. Leaves
`scoreboard/open.txt`.

## Other gates

- Catalyst `compare.py`: **124/124**
- Real-app (`OPENUIKIT_FORCE_IOS=1`, scale 3): floors held
  99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511
- iOS suite: **112/113** (known `corner_radius` 99.411)
- Linux `swift:6.2-noble` `openrender` release: green
- `SheetInteractionTests` 17/17 including the new iOS-cut duration /
  remaining-at-frame-12 assertion
