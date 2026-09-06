# Forms / NavFlow fidelity (round-20 goldens)

Round-20 board (`uikit/scoreboard/latest.md` at e6f52739 / 2fb7792c):
Forms 30 rows below 97.5, Forms-ipad five at 96.2–96.3, NavFlow 11 at
95.1–97.5. Work dirs `/tmp/conformance-{Forms,NavFlow}[-axis]` copied from
read-only `/tmp/hc-conformance-*`. Device: iPhone SE 2x / iOS 26.1;
Forms-ipad / NavFlow-ipad on iPad (A16) 820×1180 @2x. `SKIP_CAPTURE=1`.
`SIM_DEVICE_SUFFIX=-forms-navflow`. Previous keyboard / conf-dark / conf-rtl
/ conf-landscape / ipad-rest / conf-dyntype reports were read first.

## What the goldens actually show

The Forms “one score per axis” pattern is **keyboard-up frames**
(t1200–t4800), not a dark palette or RTL accessory miss on the form itself.

| axis | unfocused (t200 / t5700) | focused (t1200–t4800) | largest blob |
|---|---|---|---|
| light | 98.93 / 98.99 | 96.81–96.72 | 137 delete `[333.5, 579]` |
| dark | 97.67 / 97.69 | 95.39–95.31 | 213 emoji `[64.5, 632]` |
| rtl | 97.92 / 97.85 | 96.08–95.88 | 557 slider `[212.5, 326.5]` **and** keyboard |
| ax1 | 98.21 / 98.27 | 96.49–96.40 | 137 delete |
| xxxl | 98.61 / 98.67 | 96.74–96.67 | 137 delete |
| landscape | 99.32 / 99.60 | 93.47–91.43 | 98.8 delete `[561.5, 308]` |
| ipad | 99.23 / 99.22 | 96.19–96.30 | 378.8 keyboard strip; labels x 20 vs 16 |

Unfocused Forms already sits above 97.5 on every axis. Grouped dark cells are
already `(28, 28, 30)` (conf-dark). Pad grouped `layoutMarginsGuide` x=20 vs
storage xib 16 is still the two-sample disagreement ipad-rest left OPEN
(flipping the default dropped `realapp_storage_light_ipad` 99.689 → 99.554).
Keyboard letter-caps / SF-symbol stand-ins are already in `scoreboard/open.txt`.

NavFlow has **no keyboard**. The failing ax1 / xxxl / landscape rows are
nav-bar Dynamic Type and compact-height metrics.

## Measurements (NavFlow t200.*, SE 2x / iOS 26.1)

**Disclosure `_UITableCellAccessoryButton` in the 44 pt inset-grouped cell
(343 wide, trailing margin 16):**

| category | button | contentView | “On” x |
|---|---|---|---|
| `.large` (t200) | 10.5×14 @ 316.5 | 316.5 | 286 |
| `.extraExtraExtraLarge` | **14×19.5** @ 313,10 | 313 | 275.5 |
| `.accessibilityLarge` | **20×28.5** @ 307,2 | 307 | 256.5 |

Ours was always 10.5×14 / content 316.5.

**value1 compression (ax1, content 307, detail right = 307−8 = 299):**

- Appearance 172 @ x 16 (maxX 188); Automatic 105 @ x **194** (gap **6**, not
  intrinsic 145).
- Manage Downloads 281 @ x 16 (maxX 297); 1.2 GB width **0** at x 299.
- Primary y **3** in the 44 pt row (`ceil((44−39.5)/2)=3`), not pixel-ceil 2.5.
  xxxl: 27.5 at y **9** (`ceil(8.25)=9`).

**Landscape (window 667×375, vclass compact):**

- Card x 20 both sides (`iOSMargin(667)=20`). Labels cell-local **20** (abs 40)
  vs ours 16 (abs 36). Header “General” abs **40**.
- Filter `PlatterView [557.5, 0, 71.5, 44]` → trailing **38** (= 667−557.5−71.5).
  Ours packed at 16 (platter x 579.5). TableEditor-landscape Edit abs.x 582.24
  vs 16-pt packing 604.5 is the same 22 pt (= 38−16).

## Rules (iOS cut only)

1. `UITableViewCell.disclosureSize(compatibleWith:)` — accessibility **20×28.5**,
   xxxl **14×19.5**, else the measured 10.5×14 (2x) / 10.333×14 (3x). Content
   width and glyph box follow. Chevron polyline scales with the box.
2. value1 primary is **not** inset a second 16 from the content trailing edge;
   detail is right-aligned to `contentWidth−8` and compressed with a **6 pt**
   gap from the title (`value1TitleDetailGap`). y is `ceil((h−labelH)/2)` to
   whole points.
3. Compact-height phone inset-grouped inner / header / separator left =
   `iOSMargin` (**20** on 667). Portrait SE stays 16. Pad still uses
   `iOSPadInsetGroupedInnerInset`.
4. Compact-height nav-bar `itemSideMargin` **38**. Toolbar keeps `sideMargin` 16.

Catalyst paths unchanged (`OpenUIKitRuntime.systemFontCut == .iOS`,
`UINavigationBar.isCompactHeight`, `UITableView.isIOSChrome`).

## Before / after

Before = round-20 board. After = this branch, `SKIP_CAPTURE=1`
`/tmp/conformance-*` vs the same goldens.

### NavFlow

| capture | before | after | notes |
|---|---|---|---|
| t200 | 99.62 | **99.623** | held, layout 0 |
| t200.ax1 | 96.01 | **97.465** | layout 7→1; Library 156 vs 157 |
| t2100.ax1 | 96.01 | **97.465** | same |
| t4800.ax1 | 95.06 | **96.515** | same leftover after pop |
| t1200.ax1 | — | **99.223** | pass |
| t3000.ax1 | — | **97.829** | pass (back chevron 128) |
| t200.xxxl | 97.36 | **98.404** | layout 0 |
| t2100.xxxl | 97.36 | **98.404** | pass |
| t4800.xxxl | 96.05 | **97.092** | 1 pt Filter stem |
| t3000.xxxl | 97.50 | **97.495** | back `‹` blob 128 |
| t200.landscape | 96.46 | **98.116** | layout 8→0 |
| t2100.landscape | 97.00 | **99.556** | pass |
| t4800.landscape | 96.05 | **98.373** | pass |
| t1200.landscape | 99.09 | **99.089** | held |
| t3000.rtl | 97.16 | **97.158** | back `‹` OPEN |
| t200.dark | 99.31 | **99.307** | held |
| t200 (ipad) | 99.23 | **99.836** | held |

Landscape **all six ≥ 98.1**. Light / dark / rtl / ipad unfocused held.
ax1 rest still 0.035 under the bar (large-title width 156 vs 157).

### Forms / Forms-ipad

Byte-score identical to the keyboard-fidelity / keyboard-state floors.
Unfocused held. Focused leftover is the recorded key-cap / SF-symbol class.

| axis | t200 | focused worst | t5700 |
|---|---|---|---|
| light | 98.930 | 96.721 (t3900) | 98.985 |
| dark | 97.674 | 95.309 (t4800) | 97.686 |
| rtl | 97.916 | 95.884 (t3900) | 97.849 |
| ax1 | 98.212 | 96.400 (t3900) | 98.268 |
| xxxl | 98.610 | 96.669 (t3900) | 98.665 |
| landscape | 99.322 | 91.426 (t3900) | 99.604 |
| ipad | 99.228 | 96.192 (t1200) | 99.221 |

### Side effect

TableEditor-landscape Edit/Done 22 pt trailing closed (layout 1→0). Worst
**97.990**, t200.landscape **99.640**. Tabs t200.landscape **97.704** held
(tab bar, not nav platters).

## Open (samples in `scoreboard/open.txt`)

1. **Keyboard glyphs** (Forms t1200–t4800 every axis). UILabel 22 pt vs
   private key-cap; stroke stand-ins for delete/emoji/mic/return. Dark blob
   213; landscape blob 98.8. Already recorded.
2. **Forms-ipad grouped x=20** vs storage xib `[15,16,15,16]`. Two samples
   disagree; xib oracle kept.
3. **Forms RTL slider** blob 557 at `[212.5, 326.5, 94.5, 6]` even on
   t200.rtl (97.916, already above bar). Compact date 20×93.5 vs 34×117.5
   capsule (same LTR class).
4. **NavFlow ax1 “Library” 156 vs 157** (blob 24.8 at `[153.5, 84.5]`). 1 pt
   large-title stem; not a disclosure/detail residual (those layout issues
   closed).
5. **NavFlow t4800.xxxl** blob 10.8 at Filter `[310, 28, 1, 11]`.
6. **Back `‹` + “Library”** (t3000.rtl 97.158 / t3000.xxxl 97.495). iOS 26
   44×44 glass chevron vs the port’s label (conf-rtl OPEN).

## Gates

- Catalyst **124/124** (`/tmp/gate-forms-navflow`).
- iOS suite `SKIP_CAPTURE=1` **112/113** (`corner_radius` 99.411).
- Real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.65 / 82.170 / 99.86 / 99.734 / 85.393**.
  `realapp_settings_light_ax1` **97.516** (disclosure size only fires on
  accessibility / xxxl table chrome; the picker is not that).
- TableEditor-landscape worst **97.990**; Tabs t200.landscape **97.704**.
- `testDisclosureSizeFollowsContentSizeCategory`,
  `testCompactHeightInsetGroupedInnerAndNavBarSideMargin`,
  `testValue1DisclosureAndDetailCompressionAtAccessibilityLarge` pass.
- Linux `swift:6.2-noble` `openrender` green (195.01 s).
- No `Package.resolved`.
