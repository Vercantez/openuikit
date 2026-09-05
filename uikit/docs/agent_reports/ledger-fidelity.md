# Ledger fidelity: phone bottom-docked search + disclosure trailing 8

Round-18 board (`uikit/scoreboard/latest.md` at 6b739e29 / main 485fe6e7)
had 47 failing Ledger rows. Worst: t4000.landscape **53.03**, t3000.landscape
**55.81**, then every axis of t3000/t4000 around **68–73**. Goldens:
`/tmp/hc-conformance-Ledger[-axis]/golden` (read-only). Work dirs
`/tmp/conformance-Ledger[-axis]`, `SKIP_CAPTURE=1`. Device: iPhone SE 2x /
iPad (A16) 820×1180 @2x / iOS 26.1.

Ledger is a plain `UINavigationController` (no tab bar) with
`navigationItem.searchController` on an inset-grouped table. The ~70 score
on every axis, and the landscape 53–56 collapse on top of it, were one
structural miss: the port hosted search as the Tabs/Notes **nav overlay**
(0 pt rest / +6 active, bar grows to 60, table `aci.bottom` 0). Real iOS
26.1 docks that search at the **bottom**.

## Measurement (frames before pixels)

Portrait SE 2x, window SA `[0,0,0,0]`, t200 golden:

| piece | golden |
|---|---|
| nav bar | `[0, 10, 375, 54]` |
| table `aci` | `[64, 0, 86, 0]` |
| `_UIInheritedView` slot | `[0, 581, 375, 86]` |
| glass platter | `[28, 591, 319, 48]` |
| field | `[33, 596, 309, 38]` |
| placeholder "Regex" | `[74.5, 605, 48.5, 20.5]` (field-local x **41.5**) |
| magnifier | `[46, 604.5, 20.5, 20]` (field-local `[13, 8.5]`) |

Active (t3000 / t4000): bar **`[0, 10, 375, 0]`** (`hidesNavigationBarDuringPresentation`);
table SA.top **10**; field `[33, 596, 249, 38]` (shrink 60 = 48+12); dismiss
platter `[299, 591, 48, 48]`. Compact 667×375: slot **82**, platter **44**,
field **36**, bar y **24**. Pad: trailing 240/280 in the 54 pt bar, **not**
bottom-docked (Ledger-ipad t200 `[565, 32, 240, 44]`). Tabs/Notes keep the
overlay (`usesBottomSearch` requires `_controller != nil && tabBarController == nil`).
Chrome does not scale with Dynamic Type (t200.ax1 / t200.xxxl keep 86/48/38).

Disclosure cell 343, contentView **316.5**, subtitle `[16, 39.5, 292.5, 16]`
→ trailing **8**. RTL: contentView still `[42.5, …, 316.5]`; subtitle abs x
**50.5** = 42.5+8 (tight inset follows the accessory).

Bottom `ScrollEdgeEffectView` height = slot + **54.8** (portrait 140.8,
landscape 136.8). Same overshoot as the top pocket (118.8 = SA.top 64 + 54.8).

## Rules (iOS cut only)

1. Phone `searchController` without a tab bar docks in a floating slot
   (`UISearchBar.BottomDock`). `searchOverlayHeight` / hide-on-scroll bump
   are 0. Active + `hidesNavigationBarDuringPresentation` sets bar height 0
   at `iOSBarTop`.
2. Table `safeAreaInsets.bottom` = slot height (86 / 82).
3. `UILayoutContainerView.layoutSubviews` re-runs container layout when the
   window replaces the 390×844 `loadView` frame (otherwise the slot stays at
   y 758).
4. Disclosure / accessory `contentView` trailing margin 8; RTL uses physical
   left.
5. Glass platter reuses the tab/toolbar 48 pt `UIPlatformGlassInteractionView`
   shadow (opacity 0.10, radius 7, offset 2.5). `clipsToBounds` would swallow
   it. MEASURED t200 y 639: (231,231,234) over a white cell / (232,232,237)
   over grouped (t4000).

Catalyst goldens unchanged (guarded). Tabs canary t200 **96.657** / t4000
**95.006** held vs the round-18 board.

## Ledger rows (round-18 before → after)

Bar 97.5. iPad already passed; listed for completeness.

### portrait light LTR

| scene | before | after |
|---|---|---|
| t200 | 91.38 | 93.57 |
| t1200 | 97.44 | 97.45 |
| t2100 | 91.13 | 92.18 |
| t3000 | 71.96 | 96.38 |
| t4000 | 69.79 | **99.76** |
| t5000 | 91.88 | 94.09 |
| t6000 | 91.14 | 92.92 |
| t7000 | 91.89 | 94.08 |

### dark

| scene | before | after |
|---|---|---|
| t200.dark | 90.47 | 91.26 |
| t1200.dark | 97.64 | 97.64 |
| t2100.dark | 88.47 | 89.69 |
| t3000.dark | 72.17 | 96.35 |
| t4000.dark | 71.75 | **99.12** |
| t5000.dark | 90.97 | 91.63 |
| t6000.dark | 91.32 | 92.36 |
| t7000.dark | 90.98 | 91.70 |

### rtl

| scene | before | after |
|---|---|---|
| t200.rtl | 88.88 | 90.81 |
| t1200.rtl | 97.41 | 97.42 |
| t2100.rtl | 88.64 | 89.83 |
| t3000.rtl | 71.98 | 94.38 |
| t4000.rtl | 69.79 | **99.29** |
| t5000.rtl | 90.24 | 92.26 |
| t6000.rtl | 90.09 | 91.67 |
| t7000.rtl | 90.22 | 92.27 |

### ax1

| scene | before | after |
|---|---|---|
| t200.ax1 | 91.17 | 92.02 |
| t1200.ax1 | 97.36 | 97.36 |
| t2100.ax1 | 91.01 | 90.82 |
| t3000.ax1 | 72.64 | 94.61 |
| t4000.ax1 | 68.54 | **99.16** |
| t5000.ax1 | 91.74 | 92.52 |
| t6000.ax1 | 68.66 | 69.21 |
| t7000.ax1 | 91.73 | 92.53 |

### xxxl

| scene | before | after |
|---|---|---|
| t200.xxxl | 91.21 | 92.34 |
| t1200.xxxl | 97.35 | 97.36 |
| t2100.xxxl | 91.03 | 91.03 |
| t3000.xxxl | 73.20 | 94.96 |
| t4000.xxxl | 71.74 | **99.33** |
| t5000.xxxl | 91.76 | 92.82 |
| t6000.xxxl | 83.19 | 84.07 |
| t7000.xxxl | 91.77 | 92.82 |

### landscape

| scene | before | after |
|---|---|---|
| t200.landscape | 86.89 | 89.22 |
| t1200.landscape | 96.46 | 96.47 |
| t2100.landscape | 85.44 | 86.60 |
| t3000.landscape | 55.81 | 89.76 |
| t4000.landscape | 53.03 | 94.60 |
| t5000.landscape | 87.02 | 89.35 |
| t6000.landscape | 84.72 | 91.30 |
| t7000.landscape | 82.79 | 89.04 |

### ipad (already above bar)

| scene | before | after |
|---|---|---|
| t200 | 98.96 | 99.26 |
| t1200 | 99.28 | 99.28 |
| t2100 | 99.00 | 99.30 |
| t3000 | 99.02 | 99.32 |
| t4000 | 99.33 | 99.37 |
| t5000 | 99.02 | 99.32 |
| t6000 | 98.86 | 99.15 |
| t7000 | 99.03 | 99.32 |

14 / 56 rows at or above 97.5 (was 9: t1200.dark + 8 ipad). t4000 on every
phone axis except landscape now passes. Landscape collapse 53–56 is gone.

## Residuals (`scoreboard/open.txt`)

- **Ledger-bottom-search-glass-edge** — rest rows ~93. Frames match (slot,
  field, `$4.50` at 279.5, chevron 332.5). Remaining MAE is the 86 pt slot:
  y 639–667 golden ~232 vs ours 255 (last cell) / 242 (grouped); platter
  fill 252,252,255 vs 253,253,253; `ScrollEdgeEffectView` 140.8 not modelled
  (nav pocket is 72 / σ 1.85, different height). Active dismiss glyph golden
  22.5×21.5 vs portable `multiply` 15.5×13.5 (same as Tabs t4000).
- **Ledger-t6000-ax1-export-alert** — t6000.ax1 **69.21** blob 211.8. Export
  alert title y 323.5 vs 282, OK y 430.5 vs 386.5. Not the search dock
  (t4000.ax1 **99.16**). t6000.xxxl **84.07** same family.
- **Ledger-t1200-push-detail** — ~97.4, 1 view animating. Search gone
  (SA.bottom 0). Done x 300.7 vs 301.5; mid-flight back chevron.
- **Ledger-landscape-compact-export** — after the dock, rest ~89. Export x
  561.2 vs 583.5 in the compact 54 pt bar; header x 40 vs 36.

## Gates

Catalyst **124/124**. iOS suite **112/113** (`corner_radius`). Real-app
floors **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 /
99.65 / 82.17 / 99.86 / 99.734 / 85.393**. Tabs portrait canary held.
`UISearchControllerTests` 13/13. Linux `swift:6.2-noble` openrender green (174 s). No `Package.resolved`.
