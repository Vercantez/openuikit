# Tabs classic plain-row height is 52 pt (dump and pixels agree)

Tabs rest captures sat at 88–93 with 28–35 layout issues because the port
laid classic `textLabel` cells at `defaultRowHeight` 53. The dump said 52;
this round measured the **pixels** of the SE 2x golden PNG (same dump-vs-
pixels question the inset-grouped card had). The dump was telling the
truth.

`scripts/conformance_flow.sh /tmp/conformance-Tabs Tabs` (goldens reused
with `SKIP_CAPTURE=1`). Device `OpenUIKit-2x-tabs-rows`. Glass / symbol ink
not touched.

## Before (53 pt plain automaticDimension)

From the leftover `/tmp/conformance-Tabs` ours at 53 pt vs the same
goldens:

| capture | pixels | blob | layout | meaning |
|---|---|---|---|---|
| t200 | 93.080 | 79.5 | 28 | tab 1 rest; blob table text `[36, 399, 12, 15]` |
| t1000 | 99.294 | 59.0 | 21 | tab 2 toolbar (no table) |
| t2000 | 84.643 | 246.0 | 7 | tab 3 scroll (no table; glass) |
| t3000 | 93.321 | 79.5 | 28 | back to tab 1 |
| t4000 | 92.806 | 79.5 | 33 | focus-search |
| t5000 | 93.027 | 79.5 | 34 | type-search |
| t6000 | 88.263 | 79.5 | 28 | cancel-search |
| t7000 | 92.268 | 59.0 | 32 | scroll-200 |

Mean **92.088**, worst **84.643**. Ours t200: label `[16, 0, 343, 53]`,
Row 2 abs y 117 vs golden 116.

## Measurements

### Tabs t200 golden PNG vs dump (SE 2x / iOS 26.1)

Dump (honest):

- table abs `[0, 64, 375, 667]`, `contentOffset [0, −64]`,
  `adjustedContentInset [64, 0, 83, 0]`, `contentSize.height` **1560** =
  30 × 52
- cells `[0, 64+52·n, 375, 52]`, label `[16, 0, 343, 52]`
- bottom `_UITableViewCellSeparatorView` at cell y=51 / abs y `115+52·n`,
  height 1
- extra top separator on row 0 at abs `[16, 64, 343, 1]`

Pixels (750×1334, scale 2):

- separator pixel-rows RGB **(232,232,232)** at pt **64.0–64.5** (top of
  row 1), then **115.0–115.5, 167, 219, 271, 323, 375, 427, 479, 531,
  583** — stride **52**, 1 pt (2 device px) hairlines
- text ink top **84.0 + 52·n** (row 1: 84.0–95.5; row 7: 396.0–407.5),
  centred in the 52 pt box (intrinsic 20.5)

Not a 0.5 pt separator rounded up, not a content inset, not a dump that
reports a pre-layout 52 while pixels are 53. The row **is** 52 pt; the
1 pt separator sits **inside** the cell at y=51.

### rowprobe (private, `/tmp/rowprobe`, same SE)

Classic `textLabel` vs `defaultContentConfiguration()`, one variable at a
time. `rowHeight`/`estimatedRowHeight` both −1.

| case | cell h | contentSize.h (5 rows) |
|---|---|---|
| plain_classic_noheader / header / accessory / value1 / never / tvc / nav_tvc | **52** | 260 (+ header 310) |
| plain_config_noheader / header / value1 | **53** | 265 (+ header 315) |
| grouped_classic / inset_classic | **52** | 353 |
| grouped_config / inset_config | **53** | 358 |
| virgin `UITableViewCell()` bounds.h | 44 | — |

nav_tvc_plain_classic has **6** separators for 5 rows (the extra is the
top hairline); tvc / no-nav classic have 5.

Discriminator: **classic `textLabel` = 52**, **content-config = 53**,
every style. Grouped classic is also 52, but a global 52 drops
`tableview_grouped` (oracle uses content-config) and Focus (80.345 →
79.82). The iOS cut therefore applies 52 only to **plain**
`automaticDimension`.

Fixture scenes go through SceneKit content-config on the iOS oracle and
SceneBuilder classic cells on the port. SceneBuilder's `heightForRowAt`
now returns `defaultRowHeight` (53 / Catalyst 51.5) instead of
`automaticDimension`, so `tableview_plain` stays 99.018.

### First-row top hairline

Tabs t200 pixels at y=64 are (232,232,232); ours were white. iOS-cut
plain first row of section 0 shows `topSeparatorView` when
`adjustedContentInset.top > 0` (underlaps a bar). Grouped first-row top
sep unchanged. `tableview_plain` pins `.never` so adj top is 0 — no extra
line.

## After (SKIP_CAPTURE=1, same goldens)

| capture | before | after | blob | layout |
|---|---|---|---|---|
| t200 | 93.080 | **96.652** | 41.8 | **5** |
| t1000 | 99.294 | **99.402** | 31.2 | 21 |
| t2000 | 84.643 | 84.643 | 127.8 | 7 |
| t3000 | 93.321 | **96.892** | 41.8 | **5** |
| t4000 | 92.806 | **96.341** | 45.5 | 10 |
| t5000 | 93.027 | **96.623** | 45.5 | 14 |
| t6000 | 88.263 | 87.482 | 75.2 | 17 |
| t7000 | 92.268 | **92.529** | 83.2 | 20 |

Mean **92.088 → 93.820**, worst still **84.643** (t2000 glass). t1000 /
t2000 have no table; blob 246 → 127.8 on t2000 is the current-tree
symbol-ink ours vs a leftover 53-pt folder, not this rule.

Ours t200: label `[16, 64, 343, 52]`, `contentSize.height` 1560, Row 2
abs y 116 — dump match. Remaining t200 blob **41.8** at
`[17.5, 655.5, 8.5, 11.5]` is the tab bar (table-region fail 1.5 %, tab-bar
17.5 %). Layout 5 is extra dump labels (`Library`/`Search`/`Tools`
counts), not row frames.

t200 / t3000–t5000 do not cross 97.5: rest leftover is platter glass /
search-dismiss chrome. t6000 / t7000 stay below because of search-slot
offset, not row height:

- t6000 cancel: golden `adjustedContentInset.top` **124**, offset −124,
  Row 1 at 124; ours rest 64. Capture is 0.6 s after cancel with 1 view
  still animating.
- t7000 `setContentOffset(200)`: golden offset **260**, ours 200
  (`hidesSearchBarWhenScrolling` default). 260 − 200 = 60.

Those two residuals go in `scoreboard/open.txt`. Grouped classic = 52
is also unmodelled (Focus / Forms); left grouped at 53 on purpose.

## Gates

- iOS suite `SKIP_CAPTURE=1 scripts/ios_suite.sh /tmp/suite-tabs-rows`:
  **112/113**, miss is the known `corner_radius` (99.411).
  `tableview_plain` 99.018 / blob 3, `tableview_grouped` 98.689 / blob 4,
  `tableview_selected` 99.24 — identical to the pre-change suite.
- Catalyst `openrender render` + `compare.py`: **124/124**.
- Real app, floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.511 / 82.192** (Focus) / **99.760 / 99.689 /
  84.582** (Hackers).
- `swift test --filter TableViewIOSEditChromeTests` (5) passed.
- Linux `swift:6.2-noble` `openrender` release build green.
