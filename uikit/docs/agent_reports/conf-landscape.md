# Landscape / compact-height conformance axis

`--landscape` on `scripts/conformance_flow.sh` rotates the private **iPhone SE
(3rd gen) 2x** to `landscapeLeft` before the first capture and suffixes names
`.landscape` (`t200.landscape`). openhost renders 667×375 with compact-compact
traits (not the 600 pt width approximation — that would mark 667 as regular
and adapt popovers like iPad). Work dirs:
`/tmp/hc-conformance-{NavFlow,TableEditor,Modal}-landscape`. Portrait names
and `/tmp/hc-conformance-<App>` are unchanged.

`SIM_DEVICE_SUFFIX=-conf-landscape`. ConfProbe uses
`ConfProbe-Landscape-Info.plist` (landscapeLeft only, status bar hidden) plus
`requestGeometryUpdate(.landscapeLeft)` and waits until the window is wide
before `startLink`.

## Oracle (iPhone SE 2x / iOS 26.1)

Dump `screen` on all three apps:

| key | value |
|---|---|
| bounds | **667×375**, scale 2 |
| horizontalSizeClass | 1 (compact) |
| verticalSizeClass | 1 (compact) |
| interfaceOrientation | 4 (`landscapeLeft`) |
| windowSafeArea | **`[0, 0, 0, 0]`** |

The brief guessed `[0, 0, 21, 0]`. The dump is zero: status bar hidden, SE
has no home indicator. `RealAppScreen.phoneLandscapeSafeArea = .zero`.

None of these three apps has a tab bar or a toolbar in landscape. Nav buttons
stay 44 pt tall (`PlatterView` height 44). Alert card width stays **320**
(t5200 `[173.5, 55.5, 320, 264]`, centred; `(667−320)/2 = 173.5`).

## Baseline (first capture, phone chrome)

| app | worst | mean | notes |
|---|---|---|---|
| NavFlow-landscape | **75.540** (t3000) | 79.327 | bar `[0, 10, 667, 106]`, two Library labels |
| TableEditor-landscape | *(see after)* | | first capture collided; first successful compare already had the nav rules |
| Modal-landscape | **0.489** (t1200) | 79.188 | medium sheet `[8, 169.358, 651, 197.642]` |

**NavFlow t200.landscape golden:** bar `[0, 24, 667, 54]`, table SA top **78**
(= 24+54), one `"Library"` inline at `[305, 35.5]`. Ours was bar
`[0, 10, 667, 106]`, table SA 116, large-title overlay still expanded.

**Modal t1200.landscape golden:** `UIDropShadowView [0, 0, 667, 375]`, heading
`"Medium sheet"` at y=**28** (= `view.top+28`). t3200 large and t9200 adapted
popover are the same full window. Ours medium was the portrait 425/759
floating card.

**Modal t5200:** golden alert `[173.5, 55.5, 320, 264]` — width unchanged.
Ours y was 44.833 because the first render still had window SA bottom 21;
`(375−21−264)/2 = 45`. Zeroing SA centres it at 55.5.

TableEditor goldens (after a sequential recapture): bar already `[0, 24, 667,
54]`, table SA 78. Remaining miss is Edit/Done platter x (582 vs 604).

## Rule 1 — compact height collapses large titles; bar origin y=24

Guard: `OpenUIKitRuntime.systemFontCut == .iOS` AND
`UITraitCollection.current.verticalSizeClass == .compact`. Unspecified
vertical (portrait suite / Catalyst) does not count.

1. `displaysLargeTitles = prefersLargeTitles && !isCompactHeight`.
   `prefersLargeTitles` stays true (NavFlow sets it). Overlay height 54, no
   41 pt large-title label.
2. `iOSBarTop = max(SA.top, isCompactHeight ? 24 : 10)`.
   MEASURED NavFlow t200.landscape / t3000.landscape: bar `[0, 24, 667, 54]`,
   table SA top 78.

Portrait 375×667 / 390×700 stays y=10 / height 106.

## Rule 2 — compact-height pageSheet fills the window

MEASURED Modal t1200.landscape / t3200.landscape / t9200.landscape.

1. `_UIPageSheetView.topInset(in:)` returns **0** when vertical size class is
   compact (portrait SE keeps the 30 pt floor from probe_sheet_inset).
2. `.medium()` `resolvedDetentHeight()` returns **nil** in compact height, so
   the large-frame path applies — not the 425/759 floating card
   `[8, 169.358, 651, 197.642]` that formula yields on a 375-tall container.

Portrait `testSEWindowLargeAndMediumDetentsOnIOS` (unspecified vertical)
still expects `[0, 30, 375, 637]` / floating medium.

## After (SKIP_CAPTURE=1, same goldens)

**NavFlow-landscape** mean 79.327 → **97.641**, worst 75.540 → **96.053**

| capture | before | after |
|---|---|---|
| t200 | 78.464 | **96.707** |
| t1200 | 89.266 | **99.089** |
| t2100 | 78.757 | **97.000** |
| t3000 | **75.540** | **98.193** |
| t3900 | 76.063 | **98.806** |
| t4800 | 77.874 | **96.053** |

Bar `[0, 24, 667, 54]`, table SA 78, one Library at `[305.25, 35.5]`.

**TableEditor-landscape** worst **97.888**, mean **98.801** (all ≥ 97.5). First
successful compare already included rule 1 (the colliding first capture
scored 0). Remaining layout_issues=1 is Edit/Done `abs.x` (golden 582.24 /
571.194 vs ours 604.5 / 593.5).

**Modal-landscape** mean 79.188 → **99.076**, worst 0.489 → **97.653**

| capture | before | after |
|---|---|---|
| t200 / t2100 / t4100 | ~97.5 | **99.584** |
| t600 | 11.956 | **99.106** |
| t1200 | **0.489** | **98.753** |
| t3200 | 89.798 | **98.862** |
| t5200 | 87.433 | **97.653** |
| t6100 / t8100 | ~97.5 | **99.535** |
| t7200 | 84.412 | **98.222** |
| t9200 | 90.690 | **98.922** |
| t10100 | ~97.5 | **99.578** |

t1200 sheet is full-window; t5200 card `[173.5, 55.333, 320, 264.333]`.

**Portrait** NavFlow / TableEditor / Modal SKIP_CAPTURE=1 against
`/tmp/hc-conformance-<App>`: worst/mean **identical** (99.036 / 98.922 /
99.099).

## OPEN

- NavFlow grouped labels **x=36 vs 40**; Filter label **x=595.5 vs 573.203**
  (platter trailing ~32 vs ~54). Same 22 pt trailing class as TableEditor
  Edit/Modal More. Not a compact-height bar-height rule (platters stay 44).
- Alert/action-sheet **action titles stretch to 288** vs golden intrinsic
  widths (t5200 Save 38 vs 288). Same class as portrait Modal; width of the
  **card** is already 320.
- No toolbar 32 / tab-bar-beside-icons sample in these three apps.

## Gates

Catalyst **124/124**. iOS suite **112/113** (`corner_radius` 99.411, known).
Real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 /
97.516 / 99.511 / 82.192 / 99.760 / 99.689 / 85.393**. Linux
`swift:6.2-noble` openrender green. No `Package.resolved`.
