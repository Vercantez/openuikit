# Merge wave-38: ledger-fidelity2 then notes-fidelity2 onto main

MERGE TASK, no new rules. Main `b7b2da19` already carries Forms/NavFlow
(`docs/agent_reports/forms-navflow.md`: disclosure 20×28.5 / 14×19.5,
value1 gap 6, compact-height inner `iOSMargin`, `itemSideMargin` 38) and
Tabs (`tabs-fidelity2.md`: dark ScrollEdgeEffectView pocket). Incoming
second-pass branches were both written on `e6f52739` / round-20:

- `origin/agent/ledger-fidelity2` (`a510ca55`, report `ledger-fidelity2.md`)
- `origin/agent/notes-fidelity2` (`7ed844f6`, report `notes-fidelity2.md`)

Order: ledger first, then notes. Never keep-both on Swift. Re-expressed
each incoming change on main's version of the function. `scoreboard/latest.*`
and pin files stay main's. `scripts/vendor_pins.sh`, `env/`, `scripts/env/`
untouched. Nothing outside `uikit/`.

Goldens: `/tmp/hc-conformance-<App>[-axis]/golden` (round-21, read-only).
Replay: `SKIP_CAPTURE=1` into `/tmp/mw38-conf-<App>[-axis]`. Device:
iPhone SE 2x / iOS 26.1, plus iPad (A16) 820×1180 @2x.

## File resolutions

| file | how it was resolved |
|---|---|
| `Sources/OpenUIKit/UIBarButtonItem.swift` | **Main's `itemSideMargin` / `compactHeightSideMargin` 38** (Forms/NavFlow API). Ledger wanted a sibling `navSideMargin`; that name is not on main — packing already goes through `itemSideMargin`. Citations from Ledger Export `[545.5, 0, 83.5]` and Notes trash `[585, 0, 44, 44]` added next to NavFlow Filter. Notes unique rule kept: harvested `.trash` 17/medium/large **24×28**, platter 44, image y **7**; ax1/xxxl `harvestedSystemImage` returns nil so `_BarSymbol` stays. |
| `Sources/OpenUIKit/UITableView.swift` | **Main's compact-height inset-grouped inner = `iOSMargin`**, gated `style == .insetGrouped`. Notes' hardcoded 20 is the same number on a 667-wide window; using `iOSMargin` keeps iPhone 16 portrait "General" at 36 (card 20+16) so `realapp_focus_settings_light` stays **82.170**. Ledger / Notes landscape citations (header abs.x **40**) added. |
| `Sources/OpenUIKit/UITableViewCell.swift` | **Main's `disclosureSize(compatibleWith:)` + `effectiveDisclosureSize`** via `isAccessibilityCategory` (not Notes' switch on `.accessibilityLarge` only). `.large` stays the 10.5×14 / 3x 10.333 box. Chevron polyline keeps main's `2 * sx` scaling **plus** ledger's `bounds.height > 15` gate so the 3x 10.333×14 box (`realapp_storage` / `focus_settings`) keeps the fitted 2 pt stroke. NavFlow / Ledger / Notes samples in the comment. |
| `Sources/OpenUIKit/UINavigationBar.swift` | Identical to main after both merges (`itemSideMargin` already there). |
| `Sources/OpenUIKit/UIAlertController.swift` | Ledger unique (auto-merged): Dynamic Type header title y **73/38**, gap **42/17**, headerBottom **7/5**; 3-pill clip to `window−2×(topPadding+titleH+8)=426`. |
| `Sources/OpenUIKit/UISearchBar.swift` | Ledger unique (auto-merged): bottom-dock 21 pt Medium + inset **46.5** at ax1/xxxl (`iOSBarCapped`); overlay stays 33. |
| `Tests/OpenUIKitTests/IOSDevicePixelMetricsTests.swift` | **All four passes' rows:** `testTabBarBottomScrollEdgeEffectMatchesDump` (Tabs), `testDisclosureSizeFollowsContentSizeCategory` + `testCompactHeightInsetGroupedInnerAndNavBarSideMargin` (Forms/NavFlow), `testCompactHeightNavItemSideMarginIs38` + `testInsetGroupedHeaderInnerFollowsSystemMargin` + `testDisclosureSizeFollowsDynamicType` (Notes). |
| `Tests/OpenUIKitTests/AlertControllerTests.swift` | Ledger: `testAlertHeaderPaddingAtAccessibilityLarge` / `AtXxxxl`. |
| `Tests/OpenUIKitTests/BarItemsTests.swift` | Ledger: `testCompactHeightNavSideMarginIs38` rewritten onto `itemSideMargin`. |
| `Tests/OpenUIKitTests/TableViewTests.swift` | Ledger: `testDisclosureSizeGrowsWithDynamicType`, `testInsetGroupedHeaderUsesSystemMarginInner`. |
| `Tests/OpenUIKitTests/SystemImageTests.swift` | Notes: `testHarvestedDefaultAndBarButtonSymbolInk` trash 24×28. |
| `docs/REAL_APP_TEST.md` | Merge row newest, then Notes fidelity 2, Ledger fidelity 2, Tabs fidelity 2, Forms/NavFlow, then the rest of main. |
| `scoreboard/open.txt` | Both sides: Ledger OPEN rows + Notes-trash-ax1-xxxl (replaces Notes-trash-bar-symbol) + Modal-t5200 update. Main's NavFlow/Forms/Tabs rows kept. |
| `scoreboard/latest.*` | **Main's** (round 21). |

## Interaction that is not a drop of either rule

Compact-height 38, disclosure 20×28.5/14×19.5, and header inner `iOSMargin`
were measured independently by Forms/NavFlow, Ledger, and Notes. The merge
keeps one implementation (main's APIs) with every side's sample in the
citation. Named gains still fire:

- Ledger t6000.ax1 **90.180** (ledger-fidelity2 **90.16**, r21 board **69.46**)
  blob 211.8→**7.2**. t6000.xxxl **92.261** (report **92.26**, board **84.50**).
- Notes t200 blob **34.8** (report 111.2→34.8; r21 board 89.47 → merge **89.506**).
- Notes t11000.ax1 **67.544** (notes-fidelity2 **55.444**, board **55.45**) —
  Ledger's alert header pad on the Notes export alert.
- Modal t5200.ax1 **96.239** / t5200.xxxl **97.777** (board 77.22 / 85.00).
- Tabs t2000.dark **90.278** holds the r21 board (**90.28**). Forms t1200
  **96.808** and NavFlow t200.ax1 **97.465** hold.

Rest-frame 2 dp residuals vs the round-20 after-columns sit **on the round-21
board** (same class as merge-notes mid-flight noise). They are not lost rules.

| row | r20 report after | merge | r21 board |
|---|---|---|---|
| Ledger:t5000.dark | 92.10 | 91.840 | 91.84 |
| Ledger:t2100.dark | 89.68 | 89.555 | 89.56 |
| Ledger:t3000.dark | 95.08 | 94.991 | 94.99 |
| Ledger:t2100 | 92.23 | 92.189 | 92.19 |
| Notes:t200.xxxl | 89.441 | 89.406 | 89.41 |
| Notes:t4000.xxxl | 88.558 | 88.422 | 88.42 |

Notes dark family is **above** notes-fidelity2 because Tabs' dark pocket
landed on main after that report (t200.dark report 87.263 / board 91.74 /
merge **91.803**).

## Proof

- `swift test --filter 'IOSDevicePixelMetricsTests|AlertControllerTests|BarItemsTests|TableViewTests|SystemImageTests'`:
  every new row green (Tabs pocket, Forms/NavFlow disclosure+inner+38,
  Ledger alert pad + dock search + rewritten `itemSideMargin` test,
  Notes trash 24×28).
- Catalyst **124/124** (`/tmp/gate-merge-wave38`).
- iOS suite **112/113**, miss `corner_radius` 99.411 (`/tmp/suite-merge-wave38`).
  Same as main.
- Real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.65 / 82.170 / 99.86 / 99.734 / 85.393**.
  `realapp_focus_home_light` and `realapp_ledger_light` missing goldens
  (same as sibling reports). `/tmp/app-merge-wave38`.
- Linux docker `swift:6.2-noble` `openrender` **complete**.
- Linux `scripts/linux_verify.sh /tmp/linux-verify-merge-wave38`: Swift 6.2.4
  openrender **complete (178.65 s)**, **124/124** vs Catalyst goldens,
  **178/178** byte-identical to the macOS render.
- Whole r21 board: **237/237 matched, 0 drops, 37 gains**. Canaries
  Feed / Modal / Pager / Present / TableEditor hold (worst −0.005).
- No `Package.resolved`. Nothing outside `uikit/`.

## Ledger vs ledger-fidelity2 after (56 rows)

| row | ledger-fidelity2 after | merge | Δ | r21 board | blob |
|---|---|---|---|---|---|
| Ledger:t1200 | 97.450 | 97.446 | -0.004 | 97.450 | 77.2 |
| Ledger:t1200.ax1 | 97.360 | 97.366 | +0.006 | 97.370 | 140.8 |
| Ledger:t1200.dark | 97.640 | 97.638 | -0.002 | 97.640 | 77.0 |
| Ledger:t1200.landscape | 97.210 | 97.211 | +0.001 | 97.210 | 88.2 |
| Ledger:t1200.rtl | 97.420 | 97.424 | +0.004 | 97.420 | 130.2 |
| Ledger:t1200.xxxl | 97.360 | 97.365 | +0.005 | 97.360 | 140.8 |
| Ledger:t200 | 93.570 | 93.566 | -0.004 | 93.570 | 3.8 |
| Ledger:t200.ax1 | 93.120 | 93.131 | +0.011 | 92.910 | 7.8 |
| Ledger:t200.dark | 91.360 | **91.400** | +0.040 | 91.400 | 6.2 |
| Ledger:t200.landscape | 90.050 | 90.048 | -0.002 | 90.050 | 7.8 |
| Ledger:t200.rtl | 90.810 | 90.813 | +0.003 | 90.810 | 6.2 |
| Ledger:t200.xxxl | 93.380 | 93.382 | +0.002 | 93.310 | 7.8 |
| Ledger:t2100 | 92.230 | 92.189 | -0.041 | 92.190 | 3.8 |
| Ledger:t2100.ax1 | 91.670 | **91.696** | +0.026 | 91.590 | 7.8 |
| Ledger:t2100.dark | 89.680 | 89.555 | -0.125 | 89.560 | 6.2 |
| Ledger:t2100.landscape | 88.300 | 88.317 | +0.017 | 88.320 | 7.8 |
| Ledger:t2100.rtl | 89.550 | 89.547 | -0.003 | 89.550 | 6.2 |
| Ledger:t2100.xxxl | 91.790 | **92.236** | +0.446 | 92.210 | 7.8 |
| Ledger:t3000 | 96.380 | 96.323 | -0.057 | 96.320 | 27.5 |
| Ledger:t3000.ax1 | 95.870 | 95.870 | +0.000 | 95.630 | 55.0 |
| Ledger:t3000.dark | 95.080 | 94.991 | -0.089 | 94.990 | 14.0 |
| Ledger:t3000.landscape | 90.550 | 90.553 | +0.003 | 90.550 | 27.5 |
| Ledger:t3000.rtl | 94.370 | 94.375 | +0.005 | 94.380 | 27.5 |
| Ledger:t3000.xxxl | 96.170 | 96.138 | -0.032 | 96.100 | 54.2 |
| Ledger:t4000 | 99.760 | 99.776 | +0.016 |  | 23.8 |
| Ledger:t4000.ax1 | 99.490 | 99.487 | -0.003 |  | 87.2 |
| Ledger:t4000.dark | 99.120 | **99.155** | +0.035 |  | 23.8 |
| Ledger:t4000.landscape | 95.370 | 95.388 | +0.018 | 95.390 | 23.8 |
| Ledger:t4000.rtl | 99.290 | 99.288 | -0.002 |  | 46.0 |
| Ledger:t4000.xxxl | 99.530 | 99.529 | -0.001 |  | 87.2 |
| Ledger:t5000 | 94.100 | 94.065 | -0.035 | 94.060 | 3.8 |
| Ledger:t5000.ax1 | 93.620 | 93.593 | -0.027 | 93.440 | 7.8 |
| Ledger:t5000.dark | 92.100 | 91.840 | -0.260 | 91.840 | 6.2 |
| Ledger:t5000.landscape | 90.180 | 90.179 | -0.001 | 90.180 | 7.8 |
| Ledger:t5000.rtl | 92.290 | 92.283 | -0.007 | 92.280 | 3.8 |
| Ledger:t5000.xxxl | 93.860 | 93.859 | -0.001 | 93.830 | 7.8 |
| Ledger:t6000 | 92.920 | 92.911 | -0.009 | 92.910 | 3.8 |
| Ledger:t6000.ax1 | 90.160 | **90.180** | +0.020 | 69.460 | 7.2 |
| Ledger:t6000.dark | 92.360 | **92.389** | +0.029 | 92.390 | 1.2 |
| Ledger:t6000.landscape | 91.910 | 91.909 | -0.001 | 91.910 | 6.2 |
| Ledger:t6000.rtl | 91.670 | 91.672 | +0.002 | 91.670 | 3.8 |
| Ledger:t6000.xxxl | 92.260 | 92.261 | +0.001 | 84.500 | 7.2 |
| Ledger:t7000 | 94.080 | 94.080 | +0.000 | 94.080 | 3.8 |
| Ledger:t7000.ax1 | 93.560 | 93.569 | +0.009 | 93.420 | 7.8 |
| Ledger:t7000.dark | 91.700 | **91.730** | +0.030 | 91.730 | 6.2 |
| Ledger:t7000.landscape | 89.870 | 89.870 | +0.000 | 89.870 | 7.8 |
| Ledger:t7000.rtl | 92.270 | 92.271 | +0.001 | 92.270 | 3.8 |
| Ledger:t7000.xxxl | 93.820 | 93.820 | +0.000 | 93.790 | 7.8 |
| Ledger-ipad:t1200 | 99.280 | 99.285 | +0.005 |  | 245.2 |
| Ledger-ipad:t200 | 99.260 | 99.257 | -0.003 |  | 59.8 |
| Ledger-ipad:t2100 | 99.310 | 99.315 | +0.005 |  | 59.8 |
| Ledger-ipad:t3000 | 99.320 | 99.318 | -0.002 |  | 58.5 |
| Ledger-ipad:t4000 | 99.370 | 99.370 | +0.000 |  | 59.8 |
| Ledger-ipad:t5000 | 99.320 | 99.319 | -0.001 |  | 58.8 |
| Ledger-ipad:t6000 | 99.150 | 99.149 | -0.001 |  | 55.5 |
| Ledger-ipad:t7000 | 99.320 | 99.322 | +0.002 |  | 59.8 |

Below report by >0.02: 8
- Ledger:t2100 report=92.230 merge=92.189 Δ=-0.041 board=92.19
- Ledger:t2100.dark report=89.680 merge=89.555 Δ=-0.125 board=89.56
- Ledger:t3000 report=96.380 merge=96.323 Δ=-0.057 board=96.32
- Ledger:t3000.dark report=95.080 merge=94.991 Δ=-0.089 board=94.99
- Ledger:t3000.xxxl report=96.170 merge=96.138 Δ=-0.032 board=96.1
- Ledger:t5000 report=94.100 merge=94.065 Δ=-0.035 board=94.06
- Ledger:t5000.ax1 report=93.620 merge=93.593 Δ=-0.027 board=93.44
- Ledger:t5000.dark report=92.100 merge=91.840 Δ=-0.260 board=91.84

## Notes vs notes-fidelity2 after

| row | notes-fidelity2 after | merge | Δ | r21 board | blob |
|---|---|---|---|---|---|
| Notes:t10000 | 82.199 | 82.198 | -0.001 | 82.160 | 43.0 |
| Notes:t10000.ax1 | 77.630 | 77.631 | +0.001 | 77.630 | 329.8 |
| Notes:t10000.dark | 83.054 | **87.543** | +4.489 | 87.480 | 16.5 |
| Notes:t10000.landscape | 72.933 | **72.974** | +0.041 | 72.940 | 139.0 |
| Notes:t10000.rtl | 80.006 | 80.025 | +0.019 | 79.990 | 52.8 |
| Notes:t10000.xxxl | 80.544 | 80.548 | +0.004 | 80.550 | 329.8 |
| Notes:t11000 | 80.649 | 80.649 | +0.000 | 80.610 | 28.5 |
| Notes:t11000.ax1 | 55.444 | **67.544** | +12.100 | 55.450 | 210.8 |
| Notes:t11000.dark | 87.873 | **93.744** | +5.871 | 93.710 | 3.0 |
| Notes:t11000.landscape | 76.821 | **76.859** | +0.038 | 76.820 | 101.0 |
| Notes:t11000.rtl | 78.770 | 78.771 | +0.001 | 78.740 | 163.2 |
| Notes:t11000.xxxl | 71.177 | **78.639** | +7.462 | 71.180 | 106.2 |
| Notes:t1200 | 96.919 | 96.917 | -0.002 | 96.920 | 129.5 |
| Notes:t1200.ax1 | 96.931 | 96.931 | +0.000 | 96.930 | 123.2 |
| Notes:t1200.dark | 96.971 | 96.972 | +0.001 | 96.970 | 131.8 |
| Notes:t1200.landscape | 95.527 | **95.616** | +0.089 | 95.620 | 139.2 |
| Notes:t1200.rtl | 96.987 | 96.987 | +0.000 | 96.990 | 97.8 |
| Notes:t1200.xxxl | 96.931 | 96.931 | +0.000 | 96.930 | 123.2 |
| Notes:t12000 | 72.052 | 72.051 | -0.001 | 72.010 | 79.2 |
| Notes:t12000.ax1 | 68.496 | 68.508 | +0.012 | 68.510 | 329.8 |
| Notes:t12000.dark | 73.288 | **77.452** | +4.164 | 77.390 | 75.8 |
| Notes:t12000.landscape | 64.649 | 64.663 | +0.014 | 64.650 | 139.0 |
| Notes:t12000.rtl | 72.025 | 72.024 | -0.001 | 71.990 | 79.2 |
| Notes:t12000.xxxl | 70.476 | 70.479 | +0.003 | 70.480 | 329.8 |
| Notes:t200 | 89.470 | **89.506** | +0.036 | 89.470 | 34.8 |
| Notes:t200.ax1 | 89.025 | 89.026 | +0.001 | 89.030 | 330.0 |
| Notes:t200.dark | 87.263 | **91.803** | +4.540 | 91.740 | 16.5 |
| Notes:t200.landscape | 86.232 | **86.294** | +0.062 | 86.280 | 34.8 |
| Notes:t200.rtl | 81.753 | 81.753 | +0.000 | 81.720 | 79.2 |
| Notes:t200.xxxl | 89.441 | 89.406 | -0.035 | 89.410 | 330.0 |
| Notes:t2100 | 95.382 | 95.363 | -0.019 | 95.360 | 137.0 |
| Notes:t2100.ax1 | 95.393 | 95.374 | -0.019 | 95.370 | 137.0 |
| Notes:t2100.dark | 93.919 | **93.940** | +0.021 | 93.940 | 213.2 |
| Notes:t2100.landscape | 95.129 | **95.154** | +0.025 | 95.150 | 98.8 |
| Notes:t2100.rtl | 95.452 | 95.433 | -0.019 | 95.430 | 137.0 |
| Notes:t2100.xxxl | 95.393 | 95.393 | +0.000 | 95.390 | 137.0 |
| Notes:t3000 | 89.157 | 89.161 | +0.004 | 89.120 | 34.8 |
| Notes:t3000.ax1 | 88.739 | **88.831** | +0.092 | 88.830 | 328.5 |
| Notes:t3000.dark | 87.325 | **92.124** | +4.799 | 92.070 | 16.5 |
| Notes:t3000.landscape | 86.692 | **86.809** | +0.117 | 86.770 | 139.2 |
| Notes:t3000.rtl | 81.758 | 81.761 | +0.003 | 81.720 | 79.2 |
| Notes:t3000.xxxl | 89.078 | **89.300** | +0.222 | 89.300 | 328.8 |
| Notes:t4000 | 89.111 | 89.116 | +0.005 | 89.120 | 38.2 |
| Notes:t4000.ax1 | 86.883 | 86.888 | +0.005 | 86.890 | 282.2 |
| Notes:t4000.dark | 86.884 | **91.502** | +4.618 | 91.500 | 23.8 |
| Notes:t4000.landscape | 85.987 | **86.065** | +0.078 | 86.060 | 139.2 |
| Notes:t4000.rtl | 85.734 | 85.733 | -0.001 | 85.730 | 53.0 |
| Notes:t4000.xxxl | 88.558 | 88.422 | -0.136 | 88.420 | 86.2 |
| Notes:t5000 | 98.818 | 98.818 | +0.000 |  | 38.2 |
| Notes:t5000.ax1 | 96.164 | 96.164 | +0.000 | 96.160 | 282.2 |
| Notes:t5000.dark | 98.221 | 98.233 | +0.012 |  | 23.8 |
| Notes:t5000.landscape | 86.911 | **86.983** | +0.072 | 86.990 | 139.0 |
| Notes:t5000.rtl | 97.860 | 97.860 | +0.000 |  | 68.5 |
| Notes:t5000.xxxl | 97.923 | 97.923 | +0.000 |  | 152.5 |
| Notes:t6000 | 82.196 | 82.196 | +0.000 | 82.160 | 43.0 |
| Notes:t6000.ax1 | 77.622 | 77.623 | +0.001 | 77.620 | 330.0 |
| Notes:t6000.dark | 82.944 | **87.433** | +4.489 | 87.370 | 16.5 |
| Notes:t6000.landscape | 72.190 | **72.269** | +0.079 | 72.260 | 139.0 |
| Notes:t6000.rtl | 80.024 | 80.023 | -0.001 | 79.990 | 52.8 |
| Notes:t6000.xxxl | 80.539 | 80.541 | +0.002 | 80.540 | 330.0 |
| Notes:t7000 | 99.192 | 99.192 | +0.000 |  | 15.8 |
| Notes:t7000.ax1 | 99.190 | 99.190 | +0.000 |  | 9.0 |
| Notes:t7000.dark | 97.856 | 97.856 | +0.000 |  | 16.5 |
| Notes:t7000.landscape | 97.503 | 97.505 | +0.002 | 97.500 | 137.5 |
| Notes:t7000.rtl | 99.194 | 99.194 | +0.000 |  | 9.0 |
| Notes:t7000.xxxl | 99.190 | 99.190 | +0.000 |  | 9.0 |
| Notes:t8000 | 99.174 | 99.174 | +0.000 |  | 15.8 |
| Notes:t8000.ax1 | 99.172 | 99.172 | +0.000 |  | 9.0 |
| Notes:t8000.dark | 97.854 | 97.854 | +0.000 |  | 16.5 |
| Notes:t8000.landscape | 97.483 | 97.484 | +0.001 | 97.480 | 137.5 |
| Notes:t8000.rtl | 99.176 | 99.176 | +0.000 |  | 9.0 |
| Notes:t8000.xxxl | 99.172 | 99.172 | +0.000 |  | 9.0 |
| Notes:t9000 | 99.164 | 99.164 | +0.000 |  | 15.8 |
| Notes:t9000.ax1 | 99.161 | 99.161 | +0.000 |  | 9.0 |
| Notes:t9000.dark | 97.836 | 97.836 | +0.000 |  | 16.5 |
| Notes:t9000.landscape | 97.473 | 97.474 | +0.001 | 97.470 | 137.5 |
| Notes:t9000.rtl | 99.166 | 99.166 | +0.000 |  | 9.0 |
| Notes:t9000.xxxl | 99.161 | 99.161 | +0.000 |  | 9.0 |
| Notes-ipad:t10000 | 96.110 | **96.135** | +0.025 | 96.140 | 119.0 |
| Notes-ipad:t11000 | 97.567 | 97.567 | +0.000 | 97.570 | 53.8 |
| Notes-ipad:t1200 | 98.056 | 98.056 | +0.000 |  | 248.8 |
| Notes-ipad:t12000 | 97.751 | 97.751 | +0.000 | 97.750 | 116.2 |
| Notes-ipad:t200 | 97.726 | 97.726 | +0.000 | 97.730 | 117.5 |
| Notes-ipad:t2100 | 95.493 | 95.492 | -0.001 | 95.490 | 380.5 |
| Notes-ipad:t3000 | 97.731 | 97.729 | -0.002 | 97.730 | 121.8 |
| Notes-ipad:t4000 | 99.463 | 99.467 | +0.004 |  | 113.8 |
| Notes-ipad:t5000 | 99.660 | 99.660 | +0.000 |  | 114.8 |
| Notes-ipad:t6000 | 97.618 | 97.619 | +0.001 | 97.620 | 116.5 |
| Notes-ipad:t7000 | 98.661 | **98.702** | +0.041 |  | 345.2 |
| Notes-ipad:t8000 | 98.799 | 98.799 | +0.000 |  | 345.2 |
| Notes-ipad:t9000 | 98.796 | 98.796 | +0.000 |  | 345.2 |

Below report by >0.02: 2
- Notes:t200.xxxl report=89.441 merge=89.406 Δ=-0.035 board=89.41
- Notes:t4000.xxxl report=88.558 merge=88.422 Δ=-0.136 board=88.42

## Tabs vs round-21 board

| row | r21 board | merge | Δ | r21 board | blob |
|---|---|---|---|---|---|
| Tabs:t1000 | — | 99.409 | — |  | 31.2 |
| Tabs:t1000.ax1 | — | 99.043 | — |  | 88.5 |
| Tabs:t1000.dark | — | 98.813 | — |  | 15.2 |
| Tabs:t1000.landscape | — | 99.022 | — |  | 110.8 |
| Tabs:t1000.rtl | — | 99.098 | — |  | 273.2 |
| Tabs:t1000.xxxl | — | 99.043 | — |  | 88.5 |
| Tabs:t200 | 96.660 | 96.657 | -0.003 | 96.660 | 41.8 |
| Tabs:t200.ax1 | 96.540 | 96.541 | +0.001 | 96.540 | 113.0 |
| Tabs:t200.dark | 97.470 | 97.472 | +0.002 | 97.470 | 19.0 |
| Tabs:t200.landscape | 97.750 | 97.751 | +0.001 | 97.750 | 43.2 |
| Tabs:t200.rtl | 96.670 | 96.671 | +0.001 | 96.670 | 41.8 |
| Tabs:t200.xxxl | 96.420 | 96.419 | -0.001 | 96.420 | 73.0 |
| Tabs:t2000 | 84.670 | 84.665 | -0.005 | 84.670 | 139.8 |
| Tabs:t2000.ax1 | 84.640 | 84.642 | +0.002 | 84.640 | 131.2 |
| Tabs:t2000.dark | 90.280 | 90.278 | -0.002 | 90.280 | 47.0 |
| Tabs:t2000.landscape | 77.900 | 77.901 | +0.001 | 77.900 | 10.5 |
| Tabs:t2000.rtl | 84.660 | 84.663 | +0.003 | 84.660 | 136.5 |
| Tabs:t2000.xxxl | 84.630 | 84.631 | +0.001 | 84.630 | 123.5 |
| Tabs:t3000 | 96.900 | 96.898 | -0.002 | 96.900 | 41.8 |
| Tabs:t3000.ax1 | 96.740 | 96.739 | -0.001 | 96.740 | 113.0 |
| Tabs:t3000.dark | 97.710 | 97.708 | -0.002 | 97.710 | 19.0 |
| Tabs:t3000.landscape | — | 98.082 | — |  | 43.2 |
| Tabs:t3000.rtl | 96.910 | 96.912 | +0.002 | 96.910 | 41.8 |
| Tabs:t3000.xxxl | 96.630 | 96.634 | +0.004 | 96.630 | 73.0 |
| Tabs:t4000 | 95.010 | 95.011 | +0.001 | 95.010 | 137.0 |
| Tabs:t4000.ax1 | 92.850 | 92.852 | +0.002 | 92.850 | 282.0 |
| Tabs:t4000.dark | 92.360 | 92.358 | -0.002 | 92.360 | 213.2 |
| Tabs:t4000.landscape | 94.960 | 94.960 | +0.000 | 94.960 | 98.8 |
| Tabs:t4000.rtl | 94.790 | 94.788 | -0.002 | 94.790 | 137.0 |
| Tabs:t4000.xxxl | 94.840 | 94.836 | -0.004 | 94.840 | 137.0 |
| Tabs:t5000 | 93.720 | 93.724 | +0.004 | 93.720 | 137.0 |
| Tabs:t5000.ax1 | 90.970 | 90.967 | -0.003 | 90.970 | 282.0 |
| Tabs:t5000.dark | 92.450 | 92.452 | +0.002 | 92.450 | 213.2 |
| Tabs:t5000.landscape | 93.890 | 93.890 | +0.000 | 93.890 | 98.8 |
| Tabs:t5000.rtl | 93.580 | 93.576 | -0.004 | 93.580 | 137.0 |
| Tabs:t5000.xxxl | 93.330 | 93.327 | -0.003 | 93.330 | 139.8 |
| Tabs:t6000 | 89.520 | 89.519 | -0.001 | 89.520 | 42.5 |
| Tabs:t6000.ax1 | 84.880 | 84.882 | +0.002 | 84.880 | 27.2 |
| Tabs:t6000.dark | 92.130 | 92.131 | +0.001 | 92.130 | 19.0 |
| Tabs:t6000.landscape | 84.090 | 84.090 | +0.000 | 84.090 | 36.0 |
| Tabs:t6000.rtl | 89.530 | 89.535 | +0.005 | 89.530 | 33.2 |
| Tabs:t6000.xxxl | 87.500 | 87.504 | +0.004 | 87.500 | 73.2 |
| Tabs:t7000 | 96.600 | 96.600 | +0.000 | 96.600 | 45.8 |
| Tabs:t7000.ax1 | 95.970 | 95.973 | +0.003 | 95.970 | 160.0 |
| Tabs:t7000.dark | 97.290 | 97.289 | -0.001 | 97.290 | 46.8 |
| Tabs:t7000.landscape | 97.270 | 97.270 | +0.000 | 97.270 | 46.2 |
| Tabs:t7000.rtl | 96.610 | 96.610 | +0.000 | 96.610 | 46.0 |
| Tabs:t7000.xxxl | 96.170 | 96.169 | -0.001 | 96.170 | 73.2 |
| Tabs-ipad:t1000 | — | 99.211 | — |  | 78.8 |
| Tabs-ipad:t200 | — | 98.620 | — |  | 35.0 |
| Tabs-ipad:t2000 | — | 98.657 | — |  | 37.2 |
| Tabs-ipad:t3000 | — | 98.029 | — |  | 35.0 |
| Tabs-ipad:t4000 | 96.100 | 96.101 | +0.001 | 96.100 | 380.5 |
| Tabs-ipad:t5000 | 96.260 | 96.256 | -0.004 | 96.260 | 449.2 |
| Tabs-ipad:t6000 | — | 98.602 | — |  | 35.0 |
| Tabs-ipad:t7000 | — | 98.364 | — |  | 43.2 |

Below board by >0.02: 0

## Forms vs round-21 board

| row | r21 board | merge | Δ | r21 board | blob |
|---|---|---|---|---|---|
| Forms:t1200 | 96.810 | 96.808 | -0.002 | 96.810 | 137.0 |
| Forms:t1200.ax1 | 96.470 | 96.469 | -0.001 | 96.470 | 137.0 |
| Forms:t1200.dark | 95.400 | 95.404 | +0.004 | 95.400 | 213.2 |
| Forms:t1200.landscape | 93.480 | 93.482 | +0.002 | 93.480 | 98.8 |
| Forms:t1200.rtl | 96.080 | 96.076 | -0.004 | 96.080 | 557.5 |
| Forms:t1200.xxxl | 96.740 | 96.739 | -0.001 | 96.740 | 137.0 |
| Forms:t200 | — | 98.930 | — |  | 17.8 |
| Forms:t200.ax1 | — | 98.212 | — |  | 111.8 |
| Forms:t200.dark | 97.670 | 97.674 | +0.004 | 97.670 | 11.8 |
| Forms:t200.landscape | — | 99.322 | — |  | 3.5 |
| Forms:t200.rtl | — | 97.916 | — |  | 557.5 |
| Forms:t200.xxxl | — | 98.610 | — |  | 69.8 |
| Forms:t2100 | 96.770 | 96.769 | -0.001 | 96.770 | 137.0 |
| Forms:t2100.ax1 | 96.450 | 96.448 | -0.002 | 96.450 | 137.0 |
| Forms:t2100.dark | 95.360 | 95.361 | +0.001 | 95.360 | 213.2 |
| Forms:t2100.landscape | 94.080 | 94.076 | -0.004 | 94.080 | 98.8 |
| Forms:t2100.rtl | 95.940 | 95.936 | -0.004 | 95.940 | 557.5 |
| Forms:t2100.xxxl | 96.720 | 96.718 | -0.002 | 96.720 | 137.0 |
| Forms:t3000 | 96.750 | 96.751 | +0.001 | 96.750 | 137.0 |
| Forms:t3000.ax1 | 96.430 | 96.429 | -0.001 | 96.430 | 137.0 |
| Forms:t3000.dark | 95.350 | 95.353 | +0.003 | 95.350 | 213.2 |
| Forms:t3000.landscape | 93.260 | 93.256 | -0.004 | 93.260 | 98.8 |
| Forms:t3000.rtl | 95.920 | 95.917 | -0.003 | 95.920 | 557.5 |
| Forms:t3000.xxxl | 96.680 | 96.682 | +0.002 | 96.680 | 137.0 |
| Forms:t3900 | 96.720 | 96.721 | +0.001 | 96.720 | 137.0 |
| Forms:t3900.ax1 | 96.400 | 96.400 | +0.000 | 96.400 | 137.0 |
| Forms:t3900.dark | 95.320 | 95.323 | +0.003 | 95.320 | 213.2 |
| Forms:t3900.landscape | 91.430 | 91.426 | -0.004 | 91.430 | 98.8 |
| Forms:t3900.rtl | 95.880 | 95.884 | +0.004 | 95.880 | 566.0 |
| Forms:t3900.xxxl | 96.670 | 96.669 | -0.001 | 96.670 | 137.0 |
| Forms:t4800 | 96.730 | 96.728 | -0.002 | 96.730 | 137.0 |
| Forms:t4800.ax1 | 96.410 | 96.407 | -0.003 | 96.410 | 137.0 |
| Forms:t4800.dark | 95.310 | 95.309 | -0.001 | 95.310 | 213.2 |
| Forms:t4800.landscape | 91.460 | 91.457 | -0.003 | 91.460 | 98.8 |
| Forms:t4800.rtl | 95.890 | 95.892 | +0.002 | 95.890 | 566.0 |
| Forms:t4800.xxxl | 96.680 | 96.677 | -0.003 | 96.680 | 137.0 |
| Forms:t5700 | — | 98.985 | — |  | 17.8 |
| Forms:t5700.ax1 | — | 98.268 | — |  | 111.8 |
| Forms:t5700.dark | 97.690 | 97.686 | -0.004 | 97.690 | 11.8 |
| Forms:t5700.landscape | — | 99.604 | — |  | 3.5 |
| Forms:t5700.rtl | — | 97.849 | — |  | 566.0 |
| Forms:t5700.xxxl | — | 98.665 | — |  | 69.8 |
| Forms-ipad:t1200 | 96.190 | 96.194 | +0.004 | 96.190 | 378.8 |
| Forms-ipad:t200 | — | 99.228 | — |  | 82.5 |
| Forms-ipad:t2100 | 96.300 | 96.302 | +0.002 | 96.300 | 378.8 |
| Forms-ipad:t3000 | 96.300 | 96.299 | -0.001 | 96.300 | 378.8 |
| Forms-ipad:t3900 | 96.300 | 96.296 | -0.004 | 96.300 | 378.8 |
| Forms-ipad:t4800 | 96.300 | 96.299 | -0.001 | 96.300 | 378.8 |
| Forms-ipad:t5700 | — | 99.221 | — |  | 122.0 |

Below board by >0.02: 0

## NavFlow vs round-21 board

| row | r21 board | merge | Δ | r21 board | blob |
|---|---|---|---|---|---|
| NavFlow:t1200 | — | 99.248 | — |  | 2.2 |
| NavFlow:t1200.ax1 | — | 99.223 | — |  | 3.0 |
| NavFlow:t1200.dark | — | 98.704 | — |  | 10.8 |
| NavFlow:t1200.landscape | — | 99.089 | — |  | 0.0 |
| NavFlow:t1200.rtl | — | 99.249 | — |  | 2.2 |
| NavFlow:t1200.xxxl | — | 99.223 | — |  | 3.0 |
| NavFlow:t200 | — | 99.625 | — |  | 6.2 |
| NavFlow:t200.ax1 | 97.470 | 97.465 | -0.005 | 97.470 | 24.8 |
| NavFlow:t200.dark | — | 99.313 | — |  | 6.2 |
| NavFlow:t200.landscape | — | 99.265 | — |  | 16.5 |
| NavFlow:t200.rtl | — | 99.603 | — |  | 6.2 |
| NavFlow:t200.xxxl | — | 98.404 | — |  | 10.8 |
| NavFlow:t2100 | — | 99.625 | — |  | 6.2 |
| NavFlow:t2100.ax1 | 97.470 | 97.465 | -0.005 | 97.470 | 24.8 |
| NavFlow:t2100.dark | — | 99.313 | — |  | 6.2 |
| NavFlow:t2100.landscape | — | 99.558 | — |  | 16.5 |
| NavFlow:t2100.rtl | — | 99.603 | — |  | 6.2 |
| NavFlow:t2100.xxxl | — | 98.404 | — |  | 10.8 |
| NavFlow:t3000 | 97.580 | 97.576 | -0.004 | 97.580 | 97.2 |
| NavFlow:t3000.ax1 | 97.200 | 97.205 | +0.005 | 97.200 | 128.0 |
| NavFlow:t3000.dark | — | 98.830 | — |  | 98.2 |
| NavFlow:t3000.landscape | — | 98.193 | — |  | 77.8 |
| NavFlow:t3000.rtl | 97.450 | 97.453 | +0.003 | 97.450 | 58.8 |
| NavFlow:t3000.xxxl | 97.500 | 97.495 | -0.005 | 97.500 | 128.0 |
| NavFlow:t3900 | — | 98.796 | — |  | 97.5 |
| NavFlow:t3900.ax1 | — | 98.430 | — |  | 128.5 |
| NavFlow:t3900.dark | — | 98.824 | — |  | 98.2 |
| NavFlow:t3900.landscape | — | 98.806 | — |  | 78.0 |
| NavFlow:t3900.rtl | — | 98.788 | — |  | 58.8 |
| NavFlow:t3900.xxxl | — | 98.713 | — |  | 128.5 |
| NavFlow:t4800 | — | 98.734 | — |  | 6.2 |
| NavFlow:t4800.ax1 | 96.200 | 96.196 | -0.004 | 96.200 | 24.8 |
| NavFlow:t4800.dark | — | 99.304 | — |  | 6.2 |
| NavFlow:t4800.landscape | — | 98.667 | — |  | 16.5 |
| NavFlow:t4800.rtl | — | 98.593 | — |  | 6.2 |
| NavFlow:t4800.xxxl | 97.130 | 97.132 | +0.002 | 97.130 | 10.8 |
| NavFlow-ipad:t1200 | — | 99.814 | — |  | 0.0 |
| NavFlow-ipad:t200 | — | 99.836 | — |  | 59.5 |
| NavFlow-ipad:t2100 | — | 99.836 | — |  | 59.5 |
| NavFlow-ipad:t3000 | — | 99.538 | — |  | 59.5 |
| NavFlow-ipad:t3900 | — | 99.687 | — |  | 59.5 |
| NavFlow-ipad:t4800 | — | 99.632 | — |  | 59.5 |

Below board by >0.02: 0

## Other apps vs r21 board (matched failing rows only)

- Feed: board-rows 6/42, drops 0, gains 0, worst Feed:t3800.landscape -0.003 (board 76.420 → 76.417)
- Modal: board-rows 12/84, drops 0, gains 2, worst Modal:t600.ax1 -0.004 (board 97.610 → 97.606)
- Pager: none on board
- Present: board-rows 6/21, drops 0, gains 0, worst Present:t1200.ax1 -0.003 (board 94.490 → 94.487)
- TableEditor: board-rows 16/56, drops 0, gains 0, worst TableEditor:t2350.xxxl -0.005 (board 96.880 → 96.875)

## Whole r21 board

**237/237 matched, 0 drops, 37 gains.** Named gains listed under Proof.
Nothing else on the board dropped.

Pushed as `agent/merge-wave38`. Do not open a pull request.
