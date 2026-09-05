# Feed t700 / Pager t4650 — measured spinner phase

## What was below the bar

Feed t700 and Pager t4650 each carried a **32 pt²** blob at the
`UIRefreshControl` spinner. Scores were already above 97.5 (Feed t700
**99.466**, Pager t4650 **99.691**) but the residual was the same class:
eight full-opacity `label`@216/255 blades where iOS is still fading in.

Pager also hosts a large `UIActivityIndicatorView` at named frame 9
(t4650 = 0.15 s). That indicator was already close; the 32 pt² blob was
the refresh control.

## Probe

`/tmp/spinner-spokes/spinnerprobe.swift` on OpenUIKit-2x-spinner-spokes
(iPhone SE 3rd gen, 2x, iOS 26.1). Freeze at animation begin + N/60,
frames 0..24. Same clock confprobe uses
(`CASpringAnimation.beginTime + N/60` for the refresh appear; contents
keyframe begin for the activity indicator).

### UIActivityIndicatorView (act_n0..24)

Not a replicator. Discrete 16-frame `contents` CAKeyframeAnimation,
duration **0.8 s**, infinite repeat. Medium artwork 40×40 px, large
74×74 px. **8** visual spokes. Darkest starts at 9 o'clock, advances
clockwise. 16 × 0.05 s = two artwork frames per 45° spoke → iOS-cut
step **0.1 s**. Catalyst stays **1/8 s**. Default-color core over white
is still (156, 156, 159). Pager large indicator at frame 9 remains
step 1 at t=0.15 under 0.1 s (same as 1/8 s).

Geometry was already measured (medium 6.5×2.5 r=1.25 ring 6.75; large
12×5 r=2.5 ring 11.5) and is unchanged. Opacity ladder 217, 180, 143,
106, 69, 69, 69, 69 /255, starting at 9 o'clock, lighter
counter-clockwise.

### UIRefreshControl (rc_n0..24)

8 capsules, seed **`[48.5, 35, 3.5, 10]`**, r=1.75, ring 10, seedDX
0.25. Seed pbg = light **`secondaryLabel`**
`(0.235294, 0.235294, 0.262745, 0.6)`.

- Replicator opacity: 1 s CABasicAnimation from 0. Presentation =
  easeInOut (0.42, 0, 0.58, 1). n=9 / t=0.15 → **0.04521**; n=18 /
  t=0.30 → **0.18740** (rms 3e-7).
- Transform: discrete 45° every **0.125 s** (keyTimes 0, 0.125, …, 1,
  duration 1). n=9 → 45°, n=18 → 90°.
- `instanceAlphaOffset` spring (mass 1, k 5, c 5000) is ~0.004 / 0.012
  at those frames — all eight blades equally faint; not drawn.
- Frozen rest (`elapsed==0`, suite `control_refresh`) keeps Catalyst
  **`label` @ 216/255**.

Feed t700 = 0.30 s after `beginRefreshing`; Pager t4650 = 0.15 s.

## Rule

Guarded by `OpenUIKitRuntime.systemFontCut == .iOS`. Driven by
`OpenUIKitRuntime.animationTime` so a named conformance frame is
deterministic.

- `UIRefreshControl`: when `isRefreshing && elapsed > 0`, seed colour
  `secondaryLabel`, fade = easeInOut(elapsed / 1.0), extra rotation
  `⌊elapsed / 0.125⌋ × 45°`. Rest pose unchanged.
- `UIActivityIndicatorView.stepDuration`: **0.1** on the iOS cut,
  **1/8** on Catalyst.

## Before / after (SKIP_CAPTURE=1, same goldens)

Five `scripts/conformance_flow.sh` runs, t700 / t4650 identical to 3 dp.
Other Feed / Pager captures did not move.

| capture | before | after | blob |
|---|---|---|---|
| Feed t200 | 99.658 | 99.658 | 0 |
| Feed t700 | 99.466 | **99.478** | 32 → **0** |
| Feed t1800 | 99.658 | 99.658 | 0 |
| Feed t2800 | 99.042 | 99.042 | 3.5 |
| Feed t3800 | 99.038 | 99.038 | 3.5 |
| Feed t4800 | 99.038 | 99.038 | 3.5 |
| Pager t4650 | 99.691 | **99.805** | 32 → 0.5 |
| Pager (rest / other mid-flight) | unchanged | unchanged | — |

Mean Feed **99.319**, Pager **99.624**. Pager leftover blob 0.5 at
`[206.5, 336.0, 1.0, 1.0]` is not the spinner.

## Not measured (left open)

- `instanceAlphaOffset` past the first 0.4 s, and `instanceColor`'s
  spring to-value. Feed t700 / Pager t4650 land at 0.30 / 0.15 s.
- Dark-style refresh appear (light only).
- Activity-indicator artwork between the 8 discrete spoke steps (the
  two 0.05 s contents frames per spoke). Pager frame 9 does not need
  it.

## Other gates

- Catalyst `compare.py`: **124/124**
- Real-app (`OPENUIKIT_FORCE_IOS=1`, scale 3): floors held
  99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511
  (+ Focus 80.345, iPad History 99.760 / Storage 99.689)
- iOS suite: **112/113** (known `corner_radius` 99.411)
- Linux `swift:6.2-noble` `openrender` release: green
- `swift test --filter UIRefreshControl` 9 passed;
  `testActivityIndicatorMetricsAndAnimationStepping` passed
