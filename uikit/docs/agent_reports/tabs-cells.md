# Tabs cells + selected-tab SF Symbol

Two Tabs residuals against real iOS 26.1 (iPhone SE 2x, window SA
`[0,0,0,0]`). Glass / platter material was not touched.

`scripts/conformance_flow.sh /tmp/conformance-Tabs Tabs` (goldens reused
with `SKIP_CAPTURE=1` after the first capture). Device
`OpenUIKit-2x-tabs-cells`.

## Before (conf-tabs, hosted search + badge)

| capture | pixels | blob | layout | meaning |
|---|---|---|---|---|
| t200 | 92.929 | 220.5 | 44 | tab 1 rest |
| t1000 | 97.794 | 220.2 | 20 | tab 2 toolbar |
| t2000 | **84.570** | 226.5 | 8 | tab 3 scroll |
| t3000 | 93.169 | 220.5 | 44 | back to tab 1 |
| t4000 | 92.658 | 220.5 | 46 | focus-search |
| t5000 | 92.895 | 220.5 | 44 | type-search |
| t6000 | 88.172 | 220.5 | 42 | cancel-search |
| t7000 | 92.262 | 220.5 | 47 | scroll-200 |

Mean **91.806**, worst **84.570**. Ours dump: default `textLabel`
`[16, 80.5, 44.5, 20.5]`; tab icons 21×17.5 / 20×19.

## Measurements

### 1. Classic default cell label fills the content view

Tabs t200 golden (SE 2x / iOS 26.1):

- cell `[0, 0, 375, 52]`, contentView `[0, 0, 375, 52]`
- `UITableViewLabel` `[16, 0, 343, 52]` (width = 375−16−16)
- intrinsic height still 20.5; font `.SFUI-Regular 17`
- `contentSize.height` 1560 = 30 × 52

A private grouped default-cell probe on the same SE (classic `textLabel`,
not `contentConfiguration`) was the same 52 / fill.

`tableview_grouped` / `tableview_plain` on the same device, captured
through SceneKit's `defaultContentConfiguration()`, are **53**. Setting
`defaultRowHeight` to 52 matches Tabs but drops `tableview_grouped`
(blob 94 > 80) and Focus Settings (80.345 → 79.82). Left in
`scoreboard/open.txt`. iOS `defaultRowHeight` stays **53** (Catalyst
51.5).

Rule, `UITableView.isIOSChrome` + `style == .default`: label frame
`[labelX, 0, contentWidth − 2·inset, contentView.height]`. UILabel's iOS
draw path centres the 20.5 pt line in that box. Subtitle / value1 /
Catalyst keep the intrinsic box.

### 2. Tab-bar SF Symbol configuration + selected fill

Private probe on the SE 2x (`SIM_DEVICE=2x`), tab bar of three system
images (`calendar`, `clock`, `plus.circle.fill`):

- every tab `UIImageView.preferredSymbolConfiguration` dumps
  `pointSize=18, weight=Medium, scale=Large`
- `item.image` / `selectedImage` stay the unconfigured name
- at 18 / medium / large: calendar **29×25** (46×42 px); clock,
  `clock.fill`, `plus.circle.fill` **27.5×27.5**
- `UIImage(systemName: "calendar.fill")` is **nil** on iOS 26.1;
  `clock.fill` exists
- live selected calendar view: `[33, 7.5, 29, 25]` in the 94×54
  button, abs `[88, 595.5, 29, 25]`
- unselected clock/plus: `[33, 6, 27.5, 27.5]`
- isolated ink (96×96 crops): selected `clock.fill` 1600 dark
  pixels vs outline `clock` 777

Rule, `UITabBar.isIOS` only: render `UIImage(systemName:withConfiguration:)`
at 18 / medium / large; if selected, use `name + ".fill"` when that
symbol exists (`hasSuffix(".fill")` otherwise). Catalyst keeps the
raw item image (tabbar_basic uses solid 24×24 bitmaps).

Calendar at that configuration is drawn as a filled header + even-odd
page cutout (the outline stand-in did not match `calendar_sel.png`).
`calendar.fill` is not in the portable set.

## After (SKIP_CAPTURE=1, same goldens)

| capture | before | after | blob | layout |
|---|---|---|---|---|
| t200 | 92.929 | **93.089** | 79.5 | 31 |
| t1000 | 97.794 | **97.914** | 59.0 | 20 |
| t2000 | 84.570 | **84.571** | 246.0 | 8 |
| t3000 | 93.169 | **93.330** | 79.5 | 31 |
| t4000 | 92.658 | **92.817** | 79.5 | 33 |
| t5000 | 92.895 | **93.066** | 79.5 | 34 |
| t6000 | 88.172 | **88.253** | 79.5 | 31 |
| t7000 | 92.262 | **92.315** | 59.0 | 35 |

Mean **91.806 → 91.919**, worst 84.570 → **84.571**.

Ours t200: label `[16, 0, 343, 53]` (fill; height follows
`defaultRowHeight` 53 vs golden 52). Tab image views
`[28.5, 11.5, 29, 25]` / `[29.25, 10.25, 27.5, 27.5]`; abs calendar
`[87.5, 595.5, 29, 25]` vs golden `[88, 595.5, 29, 25]`.

## Remaining blobs (glass not modelled)

`_UITabBarPlatterView` abs `[51, 584, 274, 62]`.

- t1000 / Tools-selected captures: blob **59** at the Search calendar
  `[91.5, 597.5, 22.5, 21]` — glyph ink inside the platter, not the
  glass fill.
- t2000: blob **246** at `[264.0, 598.5, 19.0, 19.0]` — selected
  Scroll `clock.fill` vs SF Symbol ink (our fill is heavier: 1567 vs
  1026 dark pixels in the 27.5 pt crop). Inside the platter.
- t200 with row height 53: largest wrong region `[36.0, 399.0, 12.0, 15.0]`
  is table text (the 1 pt stride), not the platter.

## Gates

- iOS suite `scripts/ios_suite.sh /tmp/suite-tabs-cells`: **112/113**,
  miss is the known `corner_radius` (99.411). `tableview_grouped`
  98.689 / blob 4.
- Catalyst `openrender render` + `compare.py`: **124/124**.
- Real app, floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.511 / 80.345** (Focus) / **99.760 / 99.689**.
- `swift test --filter TableViewIOSEditChromeTests --filter
  SystemImageTests --filter UISearchControllerTests` passed.
- Linux `swift:6.2-noble` `openrender` release build green.
