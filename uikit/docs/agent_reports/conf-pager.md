# Pager — seventh conformance app

## App

`Sources/ConformanceApps/Pager/`, registered like Feed/Modal. Window 375×667
on the iPhone SE 2x / iOS 26.1 (status bar hidden).

- `UIPageViewController` (scroll, horizontal), three coloured pages, UIPageControl
- paging `UIScrollView`, four 200 pt cards
- large `UIActivityIndicatorView` + a hosted `UIRefreshControl`
- actions: `page-next`, `page-previous`, `fling`, `spinner-frame-9`

Script captures named 60 Hz frames of the page transition (0/6/12/18), the
paging `setContentOffset(animated:)` curve (0/8/16/30), and the indicator
at frame 9 after `startAnimating`.

## First capture (wrong clock)

`scripts/conformance_flow.sh /tmp/conformance-Pager Pager` against goldens
that sought any `CAAnimation` with duration > 0.05:

| capture | score | blob | what the dump actually was |
|---|---|---|---|
| t200 rest | 99.903 | 0 | OK |
| t400–t700 page-next | ~62 | ~94478 | empty trailing slot / n=1 freeze (offset 378) |
| t1200 rest | 62.007 | ~94478 | finished bounds animation pinned origin 750 |
| t3000–t3267 fling | ~55 | cards gone | n=1 freeze (offset 3) |
| t4650 | 61.814 | — | same pin, then 32 pt² spinner leftover |

Mean **65.301**, worst **55.040**.

## Measurements (iPhone SE 2x / iOS 26.1)

After confprobe waits N display-link frames when there is no
`CASpringAnimation` (TableEditor / Modal still seek), the presentation
offsets are:

**page-next** 375 → 750, then the 3-slot queue resets at n=18:

```
n=0 t400:  375
n=6 t500:  469
n=12 t600: 656.5
n=18 t700: 375  (reset)
```

**fling** `setContentOffset(400, animated: true)` from 0:

```
n=0 t3000:  0
n=8 t3133:  165.5
n=16 t3267: 388
n=30 t3500: 400
```

A live CADisplayLink probe of a *standalone* scroll view had an extra
frame of delay (n=1 still 0, n=8 = 131.5). The Pager app's own wait-capture
is the oracle for this scene; that extra frame was not modelled.

## Rules

1. **Finished UIView bounds animations do not pin presentation.** CA removes
   them. `LayerBridge.presentationState` / `applyPresentation` only apply
   `isActive` records; `completeProgrammaticTransition` and
   `setContentOffset(animated:)` drop finished records before the model
   recenters. Guard: CA semantics, both cuts. Sample: Pager t1200, model
   offset 375, pixels were white at origin 750.

2. **A bounds-origin animation skips layer-cache culling.** Model origin is
   already `to` while presentation interpolates. Culling `model ∩
   presentation` was empty (t400: presentation 375 vs model 750, pixel
   0,0,0,0). `analyze` sets `subtreePlacementAnimated` when a bounds
   origin changes so the subtree is built directly. Sample: Pager t400.

3. **iOS-cut programmatic page scroll is ease-in-out 0.3 s**
   (`UIPageViewController.programmaticScrollDuration`). Catalyst keeps 0.32
   so the 0.31/0.32 completion ticks stay put. Samples: t400/t500/t600/t700
   offsets above.

4. **iOS-cut `setContentOffset(animated:)` is ease-in-out 0.3 s.** Catalyst
   keeps 0.25. Samples: t3000/t3133/t3267/t3500 offsets above.

confprobe: only seek when a `CASpringAnimation` is in the tree. Pager
page/fling are tick-updated bounds, not springs; seeking froze every
mid-flight capture at n=1.

## After (five identical SKIP_CAPTURE=1 runs)

| capture | score | blob | layout | note |
|---|---|---|---|---|
| t200 | 99.903 | 0 | 0 | rest |
| t400 | 99.863 | 0 | 2 | n=0, dump is model 750 vs golden 375 |
| t500 | **98.898** | 1778 | 2 | n=6: 469 vs cubic ~458, 7 pt strip |
| t600 | 98.945 | 1651 | 2 | n=12: 656.5 vs cubic ~667 |
| t700 | 99.863 | 0 | 0 | n=18 reset |
| t1200 | 99.863 | 0 | 0 | rest |
| t1700 | 99.823 | 0 | 2 | page-previous n=0 |
| t1800 | 98.944 | 1651 | 2 | n=6 reverse |
| t1900 | 98.952 | 1651 | 2 | n=12 reverse |
| t2000 | 99.903 | 0 | 0 | n=18 reset |
| t2500 | 99.903 | 0 | 0 | rest |
| t3000 | 99.903 | 0 | 4 | fling n=0 |
| t3133 | 99.602 | 30.2 | 4 | n=8: 165.5 |
| t3267 | 99.663 | 38.2 | 4 | n=16: 388 |
| t3500 | 99.888 | 0.5 | 0 | rest |
| t4000 | 99.888 | 0.5 | 0 | rest |
| t4650 | 99.691 | 32 | 0 | spinner / refresh, Feed t700 class |

Mean **65.301 → 99.617**, worst **55.040 → 98.898**.

Five runs, every capture identical to three decimals.

## Left OPEN

- Page-curve residual: iOS n=6/12 is 469 / 656.5; the port's cubic
  ease-in-out over 0.3 s is ~458 / 667. No other duration or delay fitted
  both samples. Not a score search.
- t4650 blob 32 pt² at `[139.5, 401.5, 3.5, 10.0]` — the hosted
  `UIRefreshControl` (confprobe found its spring and sought frame 9 of
  that clock). Same leftover class as Feed t700. Large `UIActivityIndicatorView`
  phase already matches.
- Mid-flight `layout_issues` count the model offset in ours vs presentation
  in the golden dump. Pixels use presentation.

## Gates

- Catalyst **124/124**
- iOS suite **112/113** (known `corner_radius` 99.411)
- real app **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511**
- Linux `swift:6.2-noble` `openrender` green
- `swift test --filter UIPageViewControllerTests,UIScrollViewInteractionTests,ConformanceRegistryTests,AnimationTests,LayerCacheTests` green
