# Pager t500 / t600 — page-next clock and cosine curve

## What was below the bar

Pager:t500 and Pager:t600 were measured-open: two iOS captures of the same
page-next script differed by **31,142 / 33,857 px** in the moving pages
(bbox x 128–680) while at-rest t400 was identical. The round-8 head scored
the same 95.85 against the later goldens, so nothing in the port had moved.
UIPageViewController's scroll transition is not a `CASpringAnimation`, so
confprobe's freeze/seek clock does not govern it.

## Probe

`/tmp/pager-clock-probe` on OpenUIKit-2x-pager-clock (iPhone SE 3rd gen,
2x, iOS 26.1, UDID `8D3897A6-8889-4B73-8302-AFEB62174428`). One process
dumped `_UIQueuingScrollView` presentation offsets, model offsets, drag
flags, and every `CAAnimation` in the tree; ten in-process traces plus
ten fresh-process launches.

### Mechanism (not pan, not CA)

Every tick: `modelOffset == pOffset`. `isDragging` / `isDecelerating` /
`isTracking` are all false. The only CAAnimations in the tree are page-
control `contentsMultiplyColor` (0.25 s / 0.016 s). This is a private
vsync updater writing bounds, not a pan/deceleration and not a layer
animation.

`layer.speed = 0` + `timeOffset` does **not** stop it: freeze-hold walked
the full cosine while the layer was "frozen". Seek to `action+6/60` stays
at the live n=1 state (pOffset **378**), the same artifact as the old
confprobe fallback freeze.

`setViewControllers(animated:)` starts on a later runloop turn: 10
in-process traces had `motionDelayFrames = [1, 2, 2, 2, 2, 2, 2, 2, 2, 2]`.
A wait-from-action clock therefore samples two different points on the
curve. Ten **fresh-process** first page-nexts were already delay=1.

### Ten-run spread before (wait N frames from the action)

| named | min | max | spread |
|---|---|---|---|
| n=0 | 375 | 375 | 0 |
| n=6 | **442** | **469** | **27 pt** |
| n=12 | **626.5** | **656.5** | **30 pt** |
| n=18 | 375 | 747 | 372 (queue reset vs still in flight) |

27–30 pt at 2x over a 280-pt-tall page is the 31k px class
(`~30 × 2 × 280 × 2`). Two causes: (1) the 1-vs-2 vsync start;
(2) capturing t400 **on the action tick** lets the private updater keep
vsync while confprobe's display link stalls on `drawHierarchy`.

### Curve

Cosine ease-in-out over **0.3 s**: `(1 − cos(πt))/2`. Fits live n=1..17
within **0.25 pt**. Cubic-bezier(0.42,0,0.58,1) is ~458 / 667 (the old
7–11 pt residual).

| n | live pOffset | cosine | cubic |
|---|---|---|---|
| 0 | 375 | 375 | 375 |
| 1 | 378 | 378.1 | — |
| 6 | **469** | 468.75 | ~458 |
| 12 | **656.5** | 656.25 | ~667 |
| 17 | 747 | 747 | — |
| 18 | 375 (queue reset) | — | — |

Fling 0→400, same cosine: n=8 **165.5**, n=16 **388**, n=30 **400**.

Motion-relative from the same 10 live traces: mot+5 → **469**, mot+11 →
**656.5** on every run.

### Ten-run / five-run spread after

Named frame N is the first tick whose inverted-cosine index
`acos(1 − 2|Δ|/travel) / π × 18` is ≥ N. Capture-before-action at equal
frames so t400's PNG cannot stall the updater.

| source | t500 | t600 | spread |
|---|---|---|---|
| 10 in-process, motion-relative | 469 | 656.5 | 0 |
| 10 fresh-process first page-next | 469 | 656.5 | 0 |
| 5 confprobe recaptures (`conformance_probe_sim.sh Pager`) | 469 / curN 6 | 656.5 / curN 12 | **0** |

Also identical across the five recaptures: t1800 reverse 281.5 / curN 6,
t3133 fling 165.5 / curN 8.

## Rules

1. **iOS-cut programmatic scroll is cosine ease-in-out**, not CA cubic
   `(0.42,0,0.58,1)`. Guard:
   `OpenUIKitRuntime.systemFontCut == .iOS` via
   `UIView.scrollCurveTiming()` / `animateScrollCurve`. Catalyst keeps
   the cubic so its 0.25 / 0.32 completion ticks stay. `_cos` is a Taylor
   helper (no Darwin/Glibc `cos` on the guest load list). Samples: table
   above.

2. **confprobe mid-flight for tick-updated scrolls** inverts that cosine
   from `_UIQueuingScrollView` / moving `UIScrollView` presentation
   origin. Springs still freeze at `CASpringAnimation.beginTime + N/60`.
   Capture order 0, step order 1 at equal frames.

3. **openhost samples the same frame**: capture then action at equal
   frames so frame 0 is rest before `setViewControllers`; animation still
   begins at that frame's `animationTime`, so t500 is 6/60 of cosine.

## Before / after (SKIP_CAPTURE=1, five identical runs)

Five `scripts/conformance_flow.sh /tmp/flow-pager-clock Pager` runs,
every capture identical to 3 dp.

| capture | before (cubic, one golden) | after | blob | layout |
|---|---|---|---|---|
| t200 | 99.903 | 99.903 | 0 | 0 |
| t400 | 99.863 | **99.903** | 0 | 0 (was 2: capture-before-action) |
| t500 | 98.898 / open **97.54** | **99.818** | 1778 → **0** | 2 |
| t600 | 98.945 / open **95.85** | **99.797** | 1651 → **0.5** | 2 |
| t700 | 99.863 | 99.863 | 0 | 0 |
| t1200 | 99.863 | 99.863 | 0 | 0 |
| t1700 | 99.823 | 99.863 | 0 | 0 |
| t1800 | 98.944 | **99.745** | 1651 → 127 | 2 |
| t1900 | 98.952 | **99.769** | 1651 → 127 | 2 |
| t2000 | 99.903 | 99.903 | 0 | 0 |
| t2500 | 99.903 | 99.903 | 0 | 0 |
| t3000 | 99.903 | 99.903 | 0 | 0 |
| t3133 | 99.602 | **99.844** | 30.2 → 0 | 4 |
| t3267 | 99.663 | **99.888** | 38.2 → 0.5 | 4 |
| t3500 | 99.888 | 99.888 | 0.5 | 0 |
| t4000 | 99.888 | 99.888 | 0.5 | 0 |
| t4650 | 99.805 | 99.805 | 0.5 | 0 |

Mean **99.617 → 99.856**, worst **98.898 → 99.745** (t1800). Both named
frames above 97.5 with identical scores across five SKIP_CAPTURE=1 runs
and identical pOffset across five recaptures. Removed `Pager:t500` and
`Pager:t600` from `scoreboard/open.txt`.

Mid-flight `layout_issues` 2/4 remain: ours dumps the **model** offset
(750) vs golden **presentation** (469 / 656.5). Pixels use presentation.

## Clocks that did not work (do not revert)

- Layer freeze/seek: updater ignores `speed=0`.
- Callback-count after first motion: t500 landed at **530** (n=8); PNG
  stall / skipped vsyncs while the private updater keeps vsync.
- Timestamp `motionTS+(N−1)/60` treating first motion as n=1: t500 **530**
  then **498.5** (n=7). First motion is often already n=2; plus one vsync
  of lateness.

## Gates

- Catalyst **124/124**
- iOS suite **112/113** (known `corner_radius` 99.411)
- real app **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511** (+ Focus 82.192, iPad 99.760 / 99.689)
- Linux `swift:6.2-noble` `openrender` green
- `swift test --filter UIPageViewControllerTests --filter UIScrollViewInteractionTests --filter ConformanceRegistryTests --filter AnimationTests --filter LayerCacheTests` 79/79
