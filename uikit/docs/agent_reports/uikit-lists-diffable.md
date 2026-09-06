# APP LADDER — UICollectionViewListCell, collection diffable, swipe actions

Branch `agent/uikit-lists-diffable`. Device: iPhone SE 2x / iOS 26.1
(`SIM_DEVICE_SUFFIX=-uikit-lists-diffable`). Nothing outside `uikit/`
changed. No `Package.resolved`. No PR.

Use-site counts unblocked (full/ladder/APP_LADDER.md §8 / §4 row 9, not
re-walked):

| type | apps / uses |
|---|---|
| `UICollectionViewListCell` | firefox-ios **19** |
| `UIListContentConfiguration` / `UIListContentView` / `UIBackgroundConfiguration` / `UICellConfigurationState` | content-configuration cluster (~93) |
| `UICellAccessory` (disclosure, checkmark, reorder, delete, insert, multiselect, outlineDisclosure, label, customView) | list-cell cluster |
| `UICollectionLayoutListConfiguration` | plain / grouped / insetGrouped / sidebar / sidebarPlain |
| `UICollectionViewDiffableDataSource` | **7 / 36** |
| `NSDiffableDataSourceSnapshot` | **9** apps |
| `NSDiffableDataSourceSectionSnapshot` | expand/collapse, parent/child |
| `UISwipeActionsConfiguration` / `UIContextualAction` | **10 / 67** each |

## Before / after (named screens)

List probes kept in `/tmp` (not `fixtures/scenes/` — Catalyst goldens stay
124/124). SimScene freeze skipped for `listAppearance` scenes: freezing
before layout pinned self-size at estimated 52 while the dump was 70.5.

| scene | before | after | notes |
|---|---|---|---|
| `collection_list_plain` | first cell 53 vs 52; blob from 18.5 shift | **99.624** | first item 70.5 = 52+18.5 |
| `collection_list_inset` | side 8 vs 16 | **99.875** | card `[16, 35, 343, 52]`, radius 26 |
| `collection_list_grouped` | — | **99.643** | x=0, width 375, first y 35 |
| `collection_list_accessories` | 94.934 | **99.505** | outline trailing 14×14 chevron |
| TableEditor t200–t4800 light | held | held (worst t2350 **97.716**) | edit timeline unchanged |
| TableEditor t5800 light | n/a | **35.481 → 98.822** | list rest |
| TableEditor t6800 light | n/a | **35.471 → 98.675** | select first row |

## Rules (every constant is a named sample)

### 1. Collection list rows are 52 / 68.5, not table 53

MEASURED `collection_list_plain` Echo / Bravo, iPhone SE 2x / iOS 26.1:

- Single-line `.cell()` **52**; subtitle **68.5** (primary y 15 / 20.5, detail y 35.5 / 18, bottom 15, gap 0).
- `.cell()` margins: top **16**, bottom **15.5**, leading/trailing 16.
- First **plain** item **70.5** = 52 + **18.5** `headerTopPadding` baked into height (origin 0). Extra sits **above** packed content (Alpha label y 35 = 16+18.5).

### 2. insetGrouped collection list: side 16, section top 35, radius 26

MEASURED `collection_list_inset`: first cell `[16, 35, 343, 52]`; second section y 242.5; PNG radius 26 (top y=35 left=42 = 16+26). Grouped: x=0, width 375, first cell y 35.

MEASURED TableEditor t5800: collection abs.y **116** (bar 10+106), first cell y **116** (flush). Inter-section still 35 (Foxtrot 461 → Starred 496). First-section top 35 only when the collection's window y is 0.

### 3. Accessories

MEASURED `collection_list_accessories` / TableEditor t5800 / t6800:

| accessory | box | placement |
|---|---|---|
| disclosure | 14×14 | trailing **16** (abs 329); chevron 10.5×14 at x 347 |
| checkmark | 19×18 | trailing **18.5** (abs 321.5) |
| delete/insert/multiselect | 26×26 | x **15**; contentView x **40** |
| reorder | 27×44 | x 333.5 |
| outlineDisclosure | 14×14 chevron | trailing (oracle x 330); not a 44×44 host |

Two trailing accessories pack inward. MEASURED t6800 Alpha: disclosure stays 329, checkmark **299.5**, gap **10.5**.

### 4. Selected insetGrouped list fill is systemGray4

MEASURED TableEditor t6800 Alpha mid-card **(209, 209, 214)** = light `systemGray4` / `UITableViewCell.selectionColor`. Unselected is `secondarySystemGroupedBackground` (white). `isSelected` now refreshes `UIBackgroundConfiguration`.

### 5. Swipe rest-reveal (swipeprobe, SE 2x / iOS 26.1)

`/tmp/swipeprobe` pan on a plain `UICollectionViewListCell`, titles Delete+Flag:

| token | value | sample |
|---|---|---|
| pull padding | **10** | Flag x=10, Delete x=83.5, pull width 157 = 2×63.5+3×10 |
| title-only button | **63.5** | Delete text 39.5 + 2×12 |
| capsule | **44×**, y **4**, corner r **13** | PNG top-edge inset 13 |
| title font | **13** | label h 16, y 14 in the 44 |
| image+title Delete | **82** | trash 14.5×16.5 at (12, 13.5), 4 pt gap, title at 30.5 |
| destructive fill | (255, 56, 60) | dump `bg=(1.000, 0.220, 0.235)` = systemRed |
| Flag fill | (255, 141, 40) | explicit `.systemOrange` |
| full-swipe | **250** no-fire / **260** fires Delete | flick, hold=0; hold 0.45 s pans of 40…240 never fire |

Rest-reveal SPI (`progress == 1`) lays out the settled pull, not a full-width first-action expansion. Cell content shifts by the pull width; first action sits nearest the trailing edge.

## TableEditor conformance (list screen on every axis)

New actions `open-list` / `select-list-0` after `done`. Captures 5.80 / 6.80.
t200–t4800 goldens unchanged. `nonisolated` snapshot identifiers so confprobe
(`-default-isolation MainActor`) compiles against real UIKit.

| axis | t5800 | t6800 | t200–t4800 | ≥97.5 |
|---|---|---|---|---|
| light | **98.822** | **98.675** | held (worst 97.716) | yes |
| dark | **98.846** | **98.704** | held (t2350.dark 96.729, already OPEN) | list yes |
| ipad | **98.801** | **98.708** | held (t200 99.901) | yes |
| rtl | 96.549 | 96.402 | held (t200.rtl 99.188) | OPEN mirror |
| ax1 | 84.155 | 81.750 | held (t200.ax1 97.913) | OPEN dyntype |
| xxxl | 78.078 | 77.166 | held (t200.xxxl 98.053) | OPEN dyntype |
| landscape | 85.639 | 77.301 | held (t200.landscape 99.640) | OPEN compact bar |

Residuals in `scoreboard/open.txt`. Light t5800 leftover is the iOS 26 back
control (golden has no `‹` / `Reminders` labels; blob 58.8 at [31, 23]).

## Gates

| gate | result |
|---|---|
| Catalyst | **124/124** |
| iOS suite `SKIP_CAPTURE=1` `/tmp/ios_suite` | **112/113** (`corner_radius`, unchanged) |
| real-app floors | **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393** |
| `ListCellDiffableTests` | 9/9 |
| Linux `swift:6.2-noble` openrender | green (224.33 s) |

## Open questions (not modelled)

- Collection-list row height / accessory chrome at ax1, xxxl, compact-height.
- RTL `UIListContentView` origin (Alpha 299.5 vs 62).
- Default `.normal` swipe fill (Flag was explicit systemOrange).
- iOS 26 back control after push (chevron image, no `‹` + previous title).
- `listCell()` factory is appearance-blind here (plain alias); insetGrouped
  TableEditor uses the measured `listGroupedCell()` fill.
