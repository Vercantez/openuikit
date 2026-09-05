# iPad-open: pageSheet top 42, inset-grouped inner 20, popover glass

Three items `conf-ipad` left measured-open, closed from probes on a private
**iPad (A16)** 820×1180 @2x / iOS 26.1 (`SIM_DEVICE_SUFFIX=-ipad-open`).
Window SA `[32, 0, 25, 0]`. PadProbe cases in `/tmp/ipad-open-cap` (not in
the repo): `sheet_{white,black,red,grad}`, `table_{inset,grouped,plain,
inset_nav}`, `popover_{white,black,red,grad}`,
`popover_actionsheet_{white,black,red,grad}`. One process per CASE.

Work dirs: `/tmp/hc-conformance-{NavFlow,TableEditor,Modal}-ipad` (same
goldens as conf-ipad; `SKIP_CAPTURE=1` for the after round).

## 1. Large pageSheet top is 42

All four backdrops + NavFlow-ipad t1200 / Modal-ipad t3200:

| fact | number |
|---|---|
| `UIDropShadowView` | `[0, 42, 820, 1138]` |
| PNG fill top | ypt **42** (dimmed white 204 → sheet 255) |
| fill | opaque white, not glass |
| window SA.top | 32 |

The port used `max(30, sa.top)` → **32**. This is not that rule.

**Rule (iOS cut + pad idiom):** `_UIPageSheetView.iOSPadTopInset = 42`.
Phone stays `max(30, sa.top)` / 667-tall 30 / else 59. Pad formSheet is
still the centred 580×650 card (unchanged).

## 2. Inset-grouped inner text is 20

| case | card x | label.frame.x | label abs x | cell layoutMargins |
|---|---|---|---|---|
| `table_inset` (bare UITableView) | wrapper **16** | **20** | 36 | `[15, 20, 15, 20]` |
| `table_inset_nav` (NavFlow-like) | wrapper **20** | **20** | **40** | `[15, 20, 15, 20]` |
| `table_grouped` | 0 | **16** | 16 | `[15, 16, 15, 16]` |
| `table_plain` | 0 | **16** | 16 | `[15, 16, 15, 16]` |

NavFlow-ipad t200: cell abs x 20, label abs **40**, header label abs **40**.
Pixels: first ink ~1 pt into the label.

**Rule:** pad + `.insetGrouped` inner inset **20** (`iOSPadInsetGroupedInnerInset`)
for `_textInset`, cell `iOSMargin` / `layoutMargins.left`, header label inner,
separator left. Card x stays 20 (`insetGroupedSideInset` / table `iOSMargin`).
Grouped / plain keep `iOSPadCellMargin` **16**. Forms (`.grouped`) and
TableEditor (`.plain`) do not move.

Bare-table card x 16 is `table.layoutMargins.left` without a nav — a
different configuration; not changed.

## 3. Two pad popover glasses; action-sheet shadow

Bar-button **content** popover `[561, 62, 240, 180]` (t9200; frame already
matched):

| backdrop | interior |
|---|---|
| white | **252** |
| black | **215** |
| red | (255, 216, 218) |
| grad centre / left / right | 223 / 228 / 218 |

`out = (1−α)·B + α·T`: 252 − 215 = 37 ⇒ α = **218/255**, T = **215/218**.
Ring over black 240/230/215 (platter ring 240/233/220, reused). Dump has
**no** `_UIRoundedRectShadowView`. Halo over white peaks at **11** counts
(255−244), stronger below (239). PNG top-left of the dump frame is already
252 — corner radius **0**, not invented.

Action-sheet popover `[266, 466, 288, 248]` (t7200):

| backdrop | interior |
|---|---|
| white | **246** |
| black | **178** |
| red | (255, 175, 176) |
| grad left / centre | 221 / 209 |

`out = (1−α)·B + α·T`: 246 − 178 = 68 ⇒ α = **187/255**, T = **178/187**.
Grad-left predicted 223 vs 221. Ring over black: edge 233 vs interior 178
⇒ 55/77. **Does not fit** the content-popover mix (black 178 vs 215).

`_UIRoundedRectShadowView` `[-150, -150, 588, 548]` ⇒ spill **150**. Halo
over white peaks at **21** counts (255−234) on both the top and the side ⇒
offsetY **0**. 10–90 % of the left halo is 23…189 device px = 11.5…94.5 pt
(width **83** pt); Gaussian 10–90 is 2.563σ ⇒ σ = 83/2.563. Canvas `blur`
is 2σ. Phone alert ring-shadow (spill 44, offset 8, blur 22, α 0.085) is a
different chrome and is not reused. Card corner stays **34** (phone alert;
not re-measured — the 50 pt “first 255” on the top edge includes the
shadow around the corner).

σ for the glass *fill* is not identified from the interiors; the platter
kernel (2.25) is reused.

**Rules (iOS cut + pad idiom):** `_iosGlassKind.padContentPopover` and
`.padActionSheetPopover` as two named mixes. Pad action sheet turns
`_usesIOSGlass` on the card and draws `_UIAlertShadowView` with the 150 /
0 / 21/255 / 83/2.563×2 numbers. Content popover fill mix yes; its 11-count
halo is **not** modelled (`scoreboard/open.txt` `pad-content-popover-halo`).

## Before / after (every capture)

conf-ipad after is this branch’s before (`SKIP_CAPTURE=1`, same goldens).

### NavFlow-ipad  mean 99.194 → **99.724**, worst 98.461 → **99.538**

| capture | before | after | blob | layout |
|---|---|---|---|---|
| t200 | 99.226 | **99.835** | 75.5 → 57.2 | 12 → 1 |
| t1200 | 98.461 | **99.814** | 78.5 → **0** | 16 → 1 |
| t2100 | 99.226 | **99.835** | 75.5 → 57.2 | 12 → 1 |
| t3000 | 99.538 | 99.538 | 59.5 | 2 |
| t3900 | 99.687 | 99.687 | 59.5 | 2 |
| t4800 | 99.024 | **99.633** | 75.5 → 57.2 | 12 → 1 |

t1200 sheet top 42 closes the Filter pageSheet. Remaining layout issue on
every capture is `text='Filter' abs.x` 754.203 vs 748.5 (More/Filter
platter, same as Modal). t200 leftover blob is that platter, not cell text.

### TableEditor-ipad  mean 99.399 → **99.399**, worst 98.855 → **98.855**

`.plain`. Every capture identical (t200 99.820 … t2350 98.855). Edit
platter blob 105.2 unchanged.

### Modal-ipad  mean 98.205 → **98.988**, worst 84.245 → **91.491**

| capture | before | after | notes |
|---|---|---|---|
| t200 / t2100 / t4100 / t6100 / t8100 | 99.939 | 99.939 | rest |
| t10100 | 99.939 | 99.939 | |
| t600 | 98.825 | **99.235** | pageSheet 42; blob 130.2 → 37.5 |
| t1200 | 98.800 | **99.367** | blob 107.2 → 32.5 |
| t3200 | 98.641 | **99.781** | blob 97.5 → 2.5 |
| t5200 | 99.419 | 99.419 | |
| t7200 | **84.245** | **91.491** | glass + shadow; MAE 1.517 |
| t9200 | 98.898 | **98.923** | content-popover fill 252; leftover More platter |

t7200 leftover blob is `[749, 48, 12, 12]` (More platter), not the card
centre. Dump still compares pill labels at intrinsic width vs our 256-wide
pill box (Copy/Share/Favorite/Delete abs.x/w). That is not a fill constant.
t9200 content-popover halo left OPEN.

## Gates

Catalyst **124/124**. iOS suite **112/113** (known `corner_radius` 99.411).
Real-app floors unchanged **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
98.133 / 97.516 / 99.511 / 82.192 / 99.760 / 99.689 / 84.582**. Linux
`swift:6.2-noble` openrender green. No `Package.resolved`.
