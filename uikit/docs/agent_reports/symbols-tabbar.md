# Tab-bar SF Symbol ink

Tabs residuals against real iOS 26.1 (iPhone SE 2x, window SA `[0,0,0,0]`)
were SF Symbol glyph ink inside the platter, not glass and not layout.
`scripts/conformance_flow.sh /tmp/conformance-Tabs Tabs` (goldens reused
with `SKIP_CAPTURE=1` after tabs-cells). Device `OpenUIKit-2x-symbols-tabbar`.

## Before (tabs-cells: 18 pt medium large + selected `.fill` sibling)

| capture | pixels | blob | layout | meaning |
|---|---|---|---|---|
| t200 | 93.089 | 79.5 | 31 | tab 1 rest |
| t1000 | 97.914 | 59.0 | 20 | tab 2 toolbar |
| t2000 | **84.571** | 246.0 | 8 | tab 3 scroll |
| t3000 | 93.330 | 79.5 | 31 | back to tab 1 |
| t4000 | 92.817 | 79.5 | 33 | focus-search |
| t5000 | 93.066 | 79.5 | 34 | type-search |
| t6000 | 88.253 | 79.5 | 31 | cancel-search |
| t7000 | 92.315 | 59.0 | 35 | scroll-200 |

Mean **91.919**, worst **84.571**. t1000 blob at Search calendar
`[91.5, 597.5, 22.5, 21]`; t2000 blob at selected Scroll
`[264, 598.5, 19, 19]`.

## Measurements (symbolinkprobe, SE 2x + iPhone 16 3x / iOS 26.1)

A dedicated harvest (same method as `Tools/oracle2/inkprobe`:
`UIImageView.drawHierarchy` on opaque white, coverage = 255 − gray of
`UIColor.label`) plus clones of the live tab-bar `UIImageView`s.

1. **Configuration.** Every tab `UIImageView.preferredSymbolConfiguration`
   dumps `pointSize=18, weight=Medium, scale=Large`. Unconfigured
   `item.image` stays the default size (calendar 21×17.5); the view
   applies the configuration (frame calendar **29×25**, clock /
   plus.circle.fill **27.5×27.5**).
2. **Sizes at that triple.** SE 2x CGImage vs alignment box: calendar
   46×42 in 58×50 (ox,oy=6,4); clock / clock.fill / plus.circle.fill
   47×47 in 55×55 (4,4). iPhone 16 3x: calendar 69×63 in 87×75 (9,6);
   clock 70×70 in 82×82 (6,6) → alignment **82/3 pt**, not 27.5.
3. **Fill names that do not exist.** `calendar.fill`, `gear.fill`,
   `magnifyingglass.fill` are nil. `clock.fill`, `house.fill`,
   `person.fill` exist.
4. **Selected is not the `.fill` sibling.** Cloned tab-bar image views
   at sel2 (Scroll) match isolated `clock` (inkSum 159273), not
   `clock.fill` (405941). t2000 golden crop vs those masks: outline
   **corr 0.999997**, fill 0.34. The previous `.fill` swap was the
   extra ink in `[264, 598.5, 19, 19]`.
5. **Pen phase.** 2x: two masks (integer vs half device-pixel view
   origin). Tab-bar frames land on integer device pixels (calendar abs
   y 595.5 → 1191 px), so F0 is the bar's mask. 3x: one mask per glyph.
6. **Tint.** Opaque-label coverage is byte-identical in light and dark.
   Unselected `UIImageView.tintColor` is (0,0,0,1), not `secondaryLabel`.
   Template application is alpha × tint (existing `templateImage`).
7. **Tab-bar-as-drawn vs isolated.** A platter crop is glass-contaminated
   (inkPx 2900 vs isolated 1109). Cloning the item `UIImageView` onto
   opaque white matches the isolated configured `UIImage(systemName:)`.

Vector stand-ins could not reproduce the harvested coverage (the same
reason text uses `glyph_ink_ios.json`). Masks live in
`Resources/symbol_ink_ios.json` (2x) and `symbol_ink_ios_3x.json` (3x).

## Rule

Under `OpenUIKitRuntime.systemFontCut == .iOS` and configuration
18 / medium / large, stamp the harvested label-opaque coverage into the
alignment bitmap (black RGB, alpha = coverage). Selected and unselected
use the same symbol name; tint is applied by `UITabBar.templateImage`.
Catalyst keeps the procedural vectors (`tabbar_basic` uses solid
bitmaps). Guarded in `SymbolInkTable.stampTemplate`.

## After (SKIP_CAPTURE=1, same goldens)

| capture | before | after | blob | layout |
|---|---|---|---|---|
| t200 | 93.089 | **93.175** | 79.5 | 31 |
| t1000 | 97.914 | **99.414** | 31.2 | 20 |
| t2000 | 84.571 | **84.643** | 127.8 | 8 |
| t3000 | 93.330 | **93.416** | 79.5 | 31 |
| t4000 | 92.817 | **92.901** | 79.5 | 33 |
| t5000 | 93.066 | **93.122** | 79.5 | 34 |
| t6000 | 88.253 | **88.358** | 79.5 | 31 |
| t7000 | 92.315 | **92.363** | 47.2 | 35 |

Mean **91.919 → 92.174**, worst 84.571 → **84.643**. t1000 above the
97.5 bar; largest remaining region `[249, 14.5, 4, 8.5]` (toolbar
glyph, not the tab bar). t2000 blob moved off the clock to
`[24, 637, 14.5, 14]` (glass over the scroll blocks). t200 largest
region is still table text `[36, 399, 12, 15]` (52 vs 53).

## OPEN

- Tabs classic row 52 vs `defaultRowHeight` 53 — already
  `scoreboard/open.txt`.
- t2000 glass over scroll content (platter-adjacent golden
  `[255,239,180]` vs ours `[248,241,228]`) — `Tabs-t2000-scroll-glass`.

## Gates

- iOS suite `scripts/ios_suite.sh /tmp/suite-symbols-tabbar`: **112/113**,
  miss is the known `corner_radius` (99.411).
- Catalyst `openrender render` + `compare.py`: **124/124**.
- Real app, floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.511 / 82.192** (Focus) / **99.760 / 99.689**.
- `swift test --filter SystemImageTests` passed (22).
- Linux `swift:6.2-noble` `openrender` release build green.
