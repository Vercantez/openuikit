# UIScrollEdgeEffect: the iOS 26 edge effect object, measured and routed

Branch `agent/scroll-edge-effect`, 2026-09-10. Task: the wall recorded in
[signal-blocking-rows](signal-blocking-rows.md) — `UIScrollEdgeEffect`
(`UIScrollView.topEdgeEffect / bottomEdgeEffect / leftEdgeEffect /
rightEdgeEffect`, `.style` `.automatic/.soft/.hard`, `.isHidden`) did not
exist in the port, so an app hiding the effect kept the container scrim.
Measure the default effects per scroll-view kind and per bar, the profile
per style, what `isHidden` removes, the relation to the container
interaction, and the read-back defaults; then implement it.

## 1. Probe recipe

`Tools/oracle2/scrolledgeeffectprobe/` (README there), `main.swift` +
`scripts/scroll_edge_effect_probe_sim.sh`, iPhone 16 / iOS 26.1 @3x. One
app, 96 phases, a render-server screenshot per phase (`drawHierarchy` does
not show the effect). Content: 75 alternating black / red 40 pt bands, read
as a 1 pt column at x = 380 (clear of the title, the tab-bar platter
[60, 334] and the toolbar items). Committed: `ios-26.1-iphone16.json`
(transcript, effect read-back, filtered window trees) and
`profiles-ios-26.1-iphone16.json` (77 columns, rows 0–259 and 620–851).

Rows below quote screen rows; offsets are content offsets. Rest under the
inline bar + tab bar is −113 (safe 113 / 83); `mid` is 100 pt under (−13).

## 2. Oracle table

### Read-back (`fresh`, `freshAfterSet`, and every attached phase)

| measurement | iOS 26.1 | port after |
|---|---|---|
| `UIScrollEdgeEffect` / `UIScrollEdgeEffectStyle` | NSObject subclasses; `init` unavailable | same |
| styles | three process-wide singletons; `hard.isEqual(hard)` true, `hard.isEqual(soft)` false; description `<UIScrollEdgeEffectStyle: 0x…>` | singletons, identity equality |
| per scroll view | four DISTINCT effect objects, stable across reads, never shared with another scroll view | same |
| defaults, UIScrollView / UITableView / UICollectionView, attached or not, under nav bar / tab bar / toolbar / large title | `.automatic`, `isHidden == false` on all four edges | same |
| set `.hard` + hidden on top | reads back; bottom unchanged | same |
| left / right | same objects and defaults; nothing horizontal was probed | store-only |

### Where the effect is painted (window trees at rest / mid / hard / hidden)

Apple's painter is IN THE SCROLL VIEW: two `_UITouchPassthroughView`s
pinned to the visible rect (`[0, −13, 393, 852]` at mid), one
`UIKit.ScrollEdgeEffectView` per engaged edge with `TouchBlocker`,
`PocketMask`, `PocketBlur` (`variableBlur`), `LuminanceAdjustment` and a
`BackdropView`. Frames (scroll-view coordinates):

| context | automatic | `.hard` |
|---|---|---|
| inline nav bar (frame [0, 59, 393, 54], safe 113) | `[0, 0, 393, 167.8]` = 113 + 54.8 | `[0, 0, 393, 103]` = bar frame maxY − 10 (glass gap); PocketMask hidden, `gaussianBlur`, backdrop α 0.90 |
| tab bar (frame [0, 769, 393, 83] = safe 83) | `[0, 704.2, 393, 147.8]` = 83 + 64.8 | `[0, 769, 393, 83]` = bar frame |
| toolbar (slot 86 = 10 + platter + 28) | `[0, 776, 393, 76]` hard only measured | slot top 766 + 10 |
| nav bar + 100 pt container interaction (inset 213) | `[0, 0, 393, 247.8]` — ONE view grows over the container | `[0, 0, 393, 183]` = inner edge 213 − 30 |
| `isHidden = true` | the same view with `alpha 0` (tree unchanged) | — |

So (2) of the task: with both a bar and a container interaction on the
same edge there is one painter, the scroll view's edge effect; the
interaction only extends its pocket. Hiding the effect removes the bar
band AND the container band (`interaction.topHidden`: rows 0–112 white,
bands raw from 113).

### Engagement thresholds (`scroll.top+d`, `scroll.bottom-d`, x = 380)

| edge | off | on | rule |
|---|---|---|---|
| top under the inline nav bar | 0, 1, 2, 4, 8 pt past the safe edge (raw content) | 12, 16, 20 (partial), 24 (transitional), 32+ (full) | content past the bar's glass edge at 103 (safe 113 − 10) |
| bottom under the tab bar | bottom rest (rows 769–851 white) | 1 pt short of the rest, and already at the top rest | content past the bar frame |
| large-title bar | 12 and 40 pt: raw | collapsed (160): dark scrim 197 over red rows 0–28, blur | the existing port pocket |
| table / collection | identical to the scroll view at every phase except the unstable untouched-automatic material (`kind_vs_scroll_differing_rows`) | | |

### Pixel profile per style (x = 380, mid = 100 pt under; red (255,0,0) / black bands)

| style | top (nav bar) | bottom (tab bar) |
|---|---|---|
| `.hard` | flat WHITE α 0.902: rows 22–44 black read (230,230,230), 62–84 red read (255,230,230), ~6 pt blur at band edges (45–61), HARD CUT: row 103 raw black, 133–172 raw red. No dividing line visible on red at rows 103 / 183 / 776. `toolbar.bottomHard` 776–851 same 227–230 | rows 769–851: 239→255 over red then (255,230,230) flat 782–804, 822–851 (230,230,230); row 768 raw |
| `.soft` (and `.automatic` once any style was set — identical columns) | white wash, no dark zone: black rows 22–47 read 213 (α 0.835), red 58–89 (255,211→165,…) α 0.83→0.65, black 97–132 133→11 (0.52→0.04), 0 by row 149 = safe top + 36; blur strongest at the top (rows 8–21 ramp) | rows 733–772 black read 5→79 (0.02→0.31), red 773–812 G 83→187 (0.33→0.73), 813–831 189→198 (0.78), easing back to 177 at 851 |
| `.automatic` untouched | luminance-adaptive material: rows 0–8 white read 197 (dark α 0.23), 20–42 black, 58–64 red 186 (dark 0.27), 65–123 pink (255,164,164) / (176,174,174) regardless of content, 133–172 dark fringe 236→254. NOT stable: `mid` vs `mid2` (same offset, second visit) differ on 110 rows | dark scrim only: rows 724–752 red 254→246, 773 (228,0,0) → 812 (197,0,0): α 0.106→0.227, rising into the bar |
| `isHidden = true` | raw: rows 0–12 white, bands from 13; the navigation bar itself unchanged | raw bands to row 851 |
| large-title `.hard` | white plate rows 0–102 ((255,230,230) over red 0–24, 230 flat 42–64), raw from 103 | — |
| large-title hidden | raw bands from row 0 (collapsed) | — |
| container + nav bar, automatic | light wash over the container's top 37 pt (black 113–149 reads 137→0), not the Signal-order black scrim — the light variant the earlier report recorded | — |
| container `.hard` | 230 flat rows 122–144, (255,230,230) to 182, hard cut at 183 = 213 − 30 | — |

## 3. What the port does now

`Sources/OpenUIKit/UIScrollEdgeEffect.swift` (measurement block above the
code):

- `UIScrollEdgeEffect` (final, NSObject; `edge`, `style`, `isHidden`) and
  `UIScrollEdgeEffect.Style` (final, NSObject; `.automatic/.soft/.hard`
  singletons, identity equality). `UIScrollView` creates four distinct
  objects on first access; an untouched scroll view carries none and paints
  exactly as before (the floors do not move).
- Routing, one painter per edge as measured:
  - `UIScrollEdgeElementContainerInteraction._update` — hidden → the pocket
    is hidden (scrim gone); `.hard` → the pocket becomes the plate from the
    visible edge to the container's inner edge − 30, white α 0.902, hard
    cut; `.soft`/`.automatic` → the existing Signal-order scrim.
  - `UINavigationBar.updatePocket` — the collapsed large-title pocket is
    off when the tracked scroll view's top effect is hidden or `.hard`.
  - `UITabBar.layoutBottomEdgeEffect` — the dark gradient is off when the
    selected controller's content scroll view (explicit
    `setContentScrollView`, else the visible leaf's root / first direct
    scroll-view subview reaching the bar:
    `UIViewController._resolvedContentScrollView(for:)`) has its bottom
    effect hidden or `.hard`.
  - New `_UIScrollEdgeEffectView` (accessibility id `ScrollEdgeEffectView`)
    owned by the scroll view for `.hard` under a bar: extent from the
    bars found through the responder chain — navigation bar frame maxY −
    10 and toolbar slot top + 10 on the iOS cut (the glass gap), tab bar
    frame — engaged when content passes that edge (top: on at 12, off at
    8; bottom: on at 1), pinned to the visible rect, above content and
    below the indicators, absent while a container interaction paints the
    edge.
- Store-only, documented: `.soft` (recorded profile, needs the variable
  blur), the untouched adaptive `.automatic` material under an inline bar
  (unstable in the oracle; the port keeps painting nothing there), left /
  right, the ~6 pt blur inside the hard plate, the hard plate's dark-mode
  colour (light only measured; dark follows `systemBackground`), the
  `.hard` dividing line (not visible on the sampled columns).

## 4. Gates

```
swift test --filter UIScrollEdgeEffectTests
  6 tests, 0 failures
  failing-first (routing edits to the interaction, navigation bar and tab
  bar stashed; the class and the scroll-view plate present):
  6 tests, 13 failures — testHidingTheTopEffectRemovesTheContainerScrim,
  testHardStyleDrawsTheMeasuredPlateOverTheContainer,
  testLargeTitlePocketAndTabBarGradientFollowTheEffect fail; the read-back
  and bar-plate tests pass on the new file alone.
swift test --filter "UIScrollEdgeEffectTests|ScrollView|Interaction|TableView|CollectionView|NavigationBar|NavigationController|LargeTitle|TabBar|ChromeController|IOSDevicePixelMetrics"
  231 tests, 0 failures (41 suites; UIScrollEdgeElementContainerInteractionTests 5,
  UIScrollViewInteractionTests 20, ScrollViewLayoutGuideTests 4,
  LargeTitleNavigationTests 6, IOSNavigationBarTransitionTests 18,
  IOSDevicePixelMetricsTests 32, TableView* 50, CollectionView* 19,
  TabBarController* 5)
```

Merge check: see `docs/REAL_APP_TEST.md` (row dated 2026-09-10).

## 5. Walls left

- The `.soft` wash and the untouched `.automatic` material need the
  variable blur and the luminance adjustment (`docs/KNOWN_GAPS.md`); the
  oracle itself did not settle the untouched material between two visits
  of the same offset, so its column is recorded, not encoded.
- `.hard` in dark mode, the dividing line, and the plate's band-edge blur
  are unmeasured or unpaintable; the plate is a flat light fill.
- Two container interactions on the same edge would each paint a plate
  (one painter per interaction, not per edge); Signal attaches one per
  edge.
- The container's automatic material under a navigation bar measured as
  the light wash variant, not the black scrim the Signal-order probe gave;
  which variant Apple picks (attach order, bar presence, adaptive
  luminance) is still not derived — the port keeps the Signal-order scrim.
