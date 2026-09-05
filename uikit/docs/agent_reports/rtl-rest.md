# RTL rest — Modal, Feed, Tabs, Pager on the SE 2x

NavFlow / TableEditor / Forms already have an RTL axis (`docs/agent_reports/conf-rtl.md`).
This round captures the other four apps with
`scripts/conformance_flow.sh /tmp/hc-conformance-<App>-rtl <App> --rtl` on
iPhone SE 2x / iOS 26.1 (`SIM_DEVICE_SUFFIX=-rtl-rest`) and closes the two
largest *layout-direction* misses per app under `_layoutIsRTL`.

LTR captures and the three already-done RTL apps were re-rendered with
`SKIP_CAPTURE=1` after the rules landed; their means did not move.

## Baseline (RTL, appearance pin, before the rules)

| app | worst | mean | notes |
|---|---|---|---|
| Feed | **90.347** (t700.rtl) | 94.747 | t200/t1800 **90.527** blob **2350** at the stories strip |
| Tabs | **84.227** (t6000.rtl) | 91.203 | t2000 84.590; Library abs.x **84** vs golden **256**; search field still LTR |
| Pager | **99.705** (t1800.rtl) | 99.827 | rest ~99.86; page-0 current is the leftmost dot |
| Modal | **97.536** (t600.rtl) | 98.881 | named RTL axes already matched (see OPEN) |

### Frames (golden vs ours, before)

Feed t200.rtl pixels (nested-scroller dumps lie — A abs.x 16 both sides):
item 0 “A” on the **right** at x **287** = 375 − 16 − 72; B/C/D to the left;
E clips at x **−49**. Circle interiors at 16/100/184/268: golden palette
**3,2,1,0** vs ours **0,1,2,3**. Equal 16/16 card insets leave x 16 either way.

Tabs t200.rtl: Library title abs.x **256** vs 84; Scroll **88** vs 259.5.
Tabs t4000.rtl: search field golden **`[71, 18, 288, 44]`** = 16+44+11,
dismiss on the trailing (left) edge; ours field at 16, dismiss at 315.
Toolbar Left/Right stayed physical (32 / 302) — not reversed.
Placeholder stays at field-x + 39.5 (110.5).

Pager t200.rtl: `_UIPageIndicatorView` for page 0 is the **rightmost**
(`[200.5, 262, 10, 10]`); page 2 leftmost. t1200 page 1 stays the middle
dot. t1200 “Two” at 157.5 both sides — programmatic paging is not reversed.
Cards A–D stay physical x.

Modal t200.rtl: grabber **`[177.5, …, 36, 5]`** both sides. Sheet heading
already RTL via Auto Layout. t5200 3-up alert order Save / Discard / Cancel
last, same as LTR. Title ink is physical left (do not switch to `.natural`).

## Rules

All gated by `_layoutIsRTL` (unspecified still LTR, so Catalyst and LTR
captures do not move).

### Feed — orthogonal `parentFrame` mirror + directional insets

MEASURED Feed t200.rtl, iPhone SE 2x / iOS 26.1.

1. Orthogonal items pack in content-space from `insets.leading` and are
   mirrored at `parentFrame`: `screenX = W − (localMaxX − offset)`.
   Item 0 at 287; item 4 at −49.
2. Non-orthogonal `NSDirectionalEdgeInsets` resolve against the collection
   view’s layout direction: `physicalLeading = rtl ? trailing : leading`.
   Equal 16/16 is a no-op on the 343 pt card (375 − 16 − 343); unequal
   leading/trailing swaps the physical left edge (unit test).

### Tabs — tab items + nav-inline search

MEASURED Tabs t200.rtl / t4000.rtl, iPhone SE 2x / iOS 26.1.

1. Phone tab-bar items pack LTR then mirror about the platter width (same
   as nav-bar chrome). Library title abs.x **256**; Scroll **88**. Pad
   `layoutPadItems` is not mirrored (unmeasured).
2. Nav-inline search (`_navInlineActive`): dismiss 44×44 at leading
   `side` (16), field at `side+d+gap` (**71**). Field internals stay
   physical. Standalone `showsCancelButton` is not changed (unmeasured).

### Pager — page-control visual index

MEASURED Pager t200.rtl / t2000.rtl, iPhone SE 2x / iOS 26.1.

Page 0 paints the rightmost dot (centre 51 vs LTR leftmost). Visual index
= `n − 1 − index`. t1200 page 1 stays the middle. Tracking uses the
leading half (physical right in RTL) to step toward page 0.

### Modal — no new layout rule

Grabber, 3-button order, and “More” on trailing/left already match from
the Auto Layout / chrome rules in conf-rtl. See OPEN.

## After (`SKIP_CAPTURE=1`)

| app | capture | before | after |
|---|---|---|---|
| Feed | t200.rtl | 90.527 blob 2350 | **99.658** blob 11.5 |
| Feed | t700.rtl | 90.347 blob 2350 | **99.478** blob 11.5 |
| Feed | t1800.rtl | 90.527 blob 2350 | **99.658** blob 11.5 |
| Feed | worst / mean | 90.347 / 94.747 | **99.025 / 99.312** |
| Tabs | t200.rtl | 93.394 (Library x 84) | **96.666** (Library x 256) |
| Tabs | t4000.rtl | 92.679 (field x 16) | **96.122** (field x 71) |
| Tabs | t6000.rtl | 84.227 | **87.445** |
| Tabs | worst / mean | 84.227 / 91.203 | **84.598 / 93.718** |
| Pager | t200.rtl | 99.863 | **99.903** |
| Pager | t2000.rtl | 99.863 | **99.903** |
| Pager | t1800.rtl | 99.705 blob 127 | **99.745** blob 127 |
| Pager | worst / mean | 99.705 / 99.827 | **99.745 / 99.856** |
| Modal | worst / mean | 97.536 / 98.881 | **97.536 / 98.881** (unchanged) |

Feed leftover layout_issues on A/B/C/D/E are nested-scroller dump letters
(content-space x); pixels are the oracle.

## LTR and already-done RTL (must not move)

`SKIP_CAPTURE=1` after the rules:

| dir | mean / worst |
|---|---|
| Feed LTR | 99.319 / 99.038 |
| Tabs LTR | 93.820 / 84.641 |
| Pager LTR | 99.856 / 99.745 |
| Modal LTR | 99.099 / 97.639 |
| NavFlow LTR | 99.036 / 98.196 |
| TableEditor LTR | 98.922 / 97.716 |
| Forms LTR | 98.933 / 98.895 |
| NavFlow RTL | 98.788 / 97.171 |
| TableEditor RTL | 98.921 / 97.712 |
| Forms RTL | 97.838 / 97.793 |

## OPEN

- **Tabs badge slot.** Dump has two `_UIBarBadgeView`s at 159 and 196.5
  (snapshot + live). Pixels disagree: t200 paints the LTR slot, t1000 the
  RTL slot. Mirroring about the icon centre closed t1000 blob 273→31 and
  opened t200 blob 42→275. `scoreboard/open.txt` `Tabs-rtl-badge-slot`.
- **Tabs t2000.rtl 84.598** / t6000 87.445 — same LTR classes (Scroll-tab
  glass, 60 pt search-slot cancel inset).
- **Pager t1800.rtl** blob 127 — same LTR presentation-vs-model OPEN;
  paging is not reversed (t1200 “Two” at 157.5 both).
- **Modal t600.rtl 97.536** — dump at rest (~318), golden pixels mid-flight
  (~360). Clock/freeze, not RTL layout. 2-up cancel-on-leading was not in
  this app (unmeasured).
- **Feed story-letter dumps** — nested orthogonal dumps stay in content
  space; do not chase them.

## Gates

Catalyst **124/124**. iOS suite **112/113** (`corner_radius` 99.411).
Real app **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 /
99.511 / 82.192 / 99.760 / 99.689 / 85.393**. Linux `swift:6.2-noble`
openrender green. No `Package.resolved`.
