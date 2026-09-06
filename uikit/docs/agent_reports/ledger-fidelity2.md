# Ledger fidelity 2: compact nav 38, alert Dynamic Type header, disclosure box

Round-20 board (`uikit/scoreboard/latest.md`) still had 42 Ledger rows
below 97.5 after the first pass (`docs/agent_reports/ledger-fidelity.md`,
bottom-docked search). Lowest: t6000.ax1 **69.21**, t6000.xxxl **84.07**,
landscape 86–91, t2100/t200 rtl/dark/ax1/xxxl ~90. Goldens:
`/tmp/hc-conformance-Ledger[-axis]/golden` (read-only). Work dirs
`/tmp/conformance-Ledger[-axis]`, `SKIP_CAPTURE=1`. Device: iPhone SE 2x /
iPad (A16) 820×1180 @2x / iOS 26.1. Port only, iOS 26.1 cut.

## Measurement (frames before pixels)

### Compact-height nav side margin = 38

Notes t200.landscape trash platter `[585, 0, 44, 44]` in 667 → trailing
**38**. NavFlow Filter `[557.5, 0, 71.5]` → 38. Ledger Export platter
`[545.5, 0, 83.5]` → 38 (label abs.x **561.153**). Portrait Ledger t200
`[275.5, 0, 83.5]` in 375 stays 16. Toolbar packing unmeasured at compact
height; `sideMargin` stays 16.

After: Ledger t200.landscape Export label **561.5** (was 583.5).

### Compact-height inset-grouped header inner = iOSMargin

Ledger t200.landscape `_UITableViewHeaderFooterViewLabel` abs.x **40** =
card 20 + 20, not 36. Portrait 375 stays 32. Portrait 393 keeps inner 16
(header 36) so `realapp_focus_settings_light` does not move — using
`iOSMargin` on every width≥390 dropped that floor 82.170→82.158.

After: ours header abs **[40, 107.5, 265, 20.5]**.

### Alert header padding at Dynamic Type (both labels)

Same numbers as Modal t5200. Headerless t7200.ax1 stays 304.

| category | title y | gap | headerBottom | 1-pill card |
|---|---|---|---|---|
| `.large` | 22 | 7.667 | 4.333 | 152 |
| `.xxxl` | **38** | **17** | **5** | **193** at y 237 |
| `.ax1` | **73** | **42** | **7** | **329** at y 169 |

3-pill ax1 natural 472.5 clips to **426** at y **120.5** =
`topPadding + titleH + 8` from both edges of the 667 window. Ledger
t6000.ax1 one-pill 329 is under the cap.

After: t6000.ax1 `_UIAlertCardView [27.5, 169, 320, 329]`, title
`[30, 73, 260, 39.5]`, OK `[164.5, 430.5]` — matches golden
`_UIAlertControllerPhoneTVMacView`. Blob 211.8→7.2.

### Disclosure accessory Dynamic Type

Ledger t200 / t200.xxxl / t200.ax1, cell 343, trailing margin stays 16:

| category | accessory | contentView |
|---|---|---|
| `.large` | 10.5×14 (3x: 10.333×14) | 316.5 |
| `.xxxl` | **14×19.5** | 313 |
| `.ax1` | **20×28.5** | 307 |

Polyline scales only when `bounds.height > 15` so the 3x 10.333 box
(`realapp_storage` / `focus_settings`) keeps the fitted 2 pt stroke.

### Bottom-dock search font (not overlay)

Ledger t200.ax1 / t200.xxxl placeholder `[46.5, 6.5, 58.5, 25.5]` = **21 pt
Medium** (`iOSBarCapped` extraExtraLarge) and inset **46.5** (abs.x 79.5 =
field 33 + 46.5). Overlay (Tabs t4000.ax1) stays uncapped 33. Chrome 86/48/38
does not scale.

## Rules (iOS cut only)

1. `_UIBarMetrics.navSideMargin` is **38** when `UINavigationBar.isCompactHeight`.
   Packing in `UINavigationBar` uses `navSideMargin`; toolbar keeps `sideMargin`.
2. Compact-height inset-grouped `groupedHeaderLabelX` inner = `iOSMargin` (20
   on 667). Portrait inner stays 16.
3. `UIAlertMetrics.topPadding` / `titleMessageGap` / `headerBottomPadding` grow
   with category when both title and message are set. `frameOfPresentedViewInContainerView`
   clips to `window − 2×(topPadding + titleH + 8)`.
4. `UITableViewCell.disclosureSize(compatibleWith:)` is 14×19.5 at xxxl and
   20×28.5 at accessibility. Chevron polyline scales only for those boxes.
5. Bottom-docked `UISearchBar` field font uses `iOSBarCapped`; `BottomDock.textLeftInset`
   is 46.5 at ax1/xxxl.

Catalyst goldens unchanged (guarded). Tabs canary t200 **96.657** /
t200.landscape **97.704** / t4000 **95.006** held vs round-20. Modal t5200.ax1
**77.22 → 96.239** (layout 0), t5200.xxxl **85.00 → 97.777** (now above bar);
t7200.ax1 **97.412** held.

## Ledger rows (round-20 before → after)

Bar 97.5. `SKIP_CAPTURE=1` vs `/tmp/hc-conformance-Ledger[-axis]/golden`.
iPad already passed; listed for completeness. **14 / 56** still at or above
97.5 (same count; t4000.landscape 94.60→95.37 still under). Biggest move:
t6000.ax1 **69.21 → 90.16**.

### portrait light LTR

| scene | before | after |
|---|---|---|
| t200 | 93.57 | 93.57 |
| t1200 | 97.45 | 97.45 |
| t2100 | 92.23 | 92.23 |
| t3000 | 96.38 | 96.38 |
| t4000 | **99.76** | **99.76** |
| t5000 | 94.10 | 94.10 |
| t6000 | 92.92 | 92.92 |
| t7000 | 94.08 | 94.08 |

### dark

| scene | before | after |
|---|---|---|
| t200.dark | 91.36 | 91.36 |
| t1200.dark | **97.64** | **97.64** |
| t2100.dark | 89.68 | 89.68 |
| t3000.dark | 95.08 | 95.08 |
| t4000.dark | **99.12** | **99.12** |
| t5000.dark | 92.10 | 92.10 |
| t6000.dark | 92.36 | 92.36 |
| t7000.dark | 91.70 | 91.70 |

### rtl

| scene | before | after |
|---|---|---|
| t200.rtl | 90.81 | 90.81 |
| t1200.rtl | 97.42 | 97.42 |
| t2100.rtl | 89.55 | 89.55 |
| t3000.rtl | 94.37 | 94.37 |
| t4000.rtl | **99.29** | **99.29** |
| t5000.rtl | 92.29 | 92.29 |
| t6000.rtl | 91.67 | 91.67 |
| t7000.rtl | 92.27 | 92.27 |

### ax1

| scene | before | after |
|---|---|---|
| t200.ax1 | 92.02 | 93.12 |
| t1200.ax1 | 97.36 | 97.36 |
| t2100.ax1 | 90.75 | 91.67 |
| t3000.ax1 | 94.60 | 95.87 |
| t4000.ax1 | **99.16** | **99.49** |
| t5000.ax1 | 92.56 | 93.62 |
| t6000.ax1 | 69.21 | 90.16 |
| t7000.ax1 | 92.53 | 93.56 |

### xxxl

| scene | before | after |
|---|---|---|
| t200.xxxl | 92.34 | 93.38 |
| t1200.xxxl | 97.36 | 97.36 |
| t2100.xxxl | 90.86 | 91.79 |
| t3000.xxxl | 95.00 | 96.17 |
| t4000.xxxl | **99.33** | **99.53** |
| t5000.xxxl | 92.85 | 93.86 |
| t6000.xxxl | 84.07 | 92.26 |
| t7000.xxxl | 92.82 | 93.82 |

### landscape

| scene | before | after |
|---|---|---|
| t200.landscape | 89.22 | 90.05 |
| t1200.landscape | 96.47 | 97.21 |
| t2100.landscape | 86.56 | 88.30 |
| t3000.landscape | 89.78 | 90.55 |
| t4000.landscape | 94.60 | 95.37 |
| t5000.landscape | 89.34 | 90.18 |
| t6000.landscape | 91.30 | 91.91 |
| t7000.landscape | 89.04 | 89.87 |

### ipad (already above bar)

| scene | before | after |
|---|---|---|
| t200 | 99.26 | 99.26 |
| t1200 | 99.28 | 99.28 |
| t2100 | 99.31 | 99.31 |
| t3000 | 99.32 | 99.32 |
| t4000 | 99.37 | 99.37 |
| t5000 | 99.32 | 99.32 |
| t6000 | 99.15 | 99.15 |
| t7000 | 99.32 | 99.32 |

Portrait `.large` / rtl / dark / ipad held (no rule fires there). Landscape
blob 76→7.8 on the rest rows after Export 38 + header 40; leftover is the
search-slot glass. t6000.ax1 leftover blob 7.2 is that same glass (alert
frames match).

## Residuals (`scoreboard/open.txt`)

- **Ledger-bottom-search-glass-edge** — rest ~90–94, blob ~4–8 at the 86/82
  pt slot. Frames match (Export 561.5, header 40, `$4.50`, chevron).
  `ScrollEdgeEffectView` 140.8 (portrait) / 136.8 (landscape) unmodelled.
  Regex dump `abs.w` 48.5 vs 267.5 is the label box, not pixels.
- **Ledger-t2100-midflight** — 1 view animating; golden has `Done`, ours at
  rest. Same class on rtl/dark/ax1/xxxl/landscape (~88–92).
- **Ledger-t1200-push-detail** — ~97.4, 1 view animating, mid-flight back
  chevron. Search gone (SA.bottom 0). Landscape 96.47→97.21 is the compact
  38 on the detail bar, still under 97.5.
- **Ledger-t6000-ax1-glass** — alert closed (card 329 at y 169). Leftover
  Regex after-cancel `abs.h` 20.5 vs capped 25.5; same slot glass as t200.

## Gates

Catalyst **124/124**. iOS suite **112/113** (`corner_radius`). Real-app
floors **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 /
99.65 / 82.170 / 99.86 / 99.734 / 85.393**. Tabs canaries held. Modal
t5200.ax1/xxxl as above. Unit tests: `testCompactHeightNavSideMarginIs38`,
`testAlertHeaderPaddingAtAccessibilityLarge` / `AtXxxxl`,
`testDisclosureSizeGrowsWithDynamicType`,
`testInsetGroupedHeaderUsesSystemMarginInner`. Linux `swift:6.2-noble`
openrender green (182.19 s). No `Package.resolved`. No text harvest (bottom-dock 21 pt
Medium is Darwin CoreText; Linux realapp Ledger stays `.large` 17 medium,
already harvested).
