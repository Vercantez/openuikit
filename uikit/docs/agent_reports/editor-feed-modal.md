# TableEditor xxxl chrome, Feed compact-height refresh, Modal residuals

Round-18 board (`scoreboard/latest.json` head `6b739e29`, main `485fe6e7`):
TableEditor 16 fails (min 70.70, xxxl mean 87.656), Feed 4 (min 61.00) plus
Feed-ipad 3 at ~91.9, Modal 5 (min 77.22) plus Modal-ipad 1 at 91.52.

Goldens are the round-18 captures (read-only `/tmp/hc-conformance-*`, copied
to `/tmp/conformance-*`). Device: iPhone SE 2x / iOS 26.1, plus iPad (A16)
820×1180 @2x for `--ipad`. `SKIP_CAPTURE=1 scripts/conformance_flow.sh`.
Nothing outside `uikit/` changed. No `Package.resolved`.

## Rules (iOS cut; every constant is a named sample)

### 1. Plain subtitle at `.extraExtraExtraLarge` is 83 pt, not 62

MEASURED TableEditor t200.xxxl / t900.xxxl, iPhone SE 2x / iOS 26.1:

- Cell **83** (ours was 62). Primary 23 pt h=27.5 at y **11**; detail 21 pt
  h=25.5 at y **42.5**; gap **4**; bottom pad **15** (83−68).
- Edit: delete **[14.5, cellY+21, 34.5, 34.5]**; content x **47.5**; reorder
  **[322.5, cellY, 36.5, 83]**; labels x **63.5** (= 47.5+16). y 21 is not
  centred ((83−34.5)/2 = 24.25), same class as ax1 y 33 vs (117−38)/2.
- PNG: disc **29** in the 34.5 box (inset scales from the 26→22 `.large`
  pair); minus **14×2** (= 10.5·34.5/26). Reorder bars **2.0 pt** at cell y
  34.5 / 41.0 / 47.5 (glyph 15, origins 0 / 6.5 / 13). `.large` stays 1.5 pt
  at 2.0 / 6.5 / 11.5.

`.extraExtraExtraLarge` is not `isAccessibilityCategory`, so the ax1
39/55/41 chrome must not fire. Guard: `UITableView.isIOSChrome` and
`preferredContentSizeCategory == .extraExtraExtraLarge`. Catalyst keeps
62 / 15/26/40/27.

TableEditor t3800.xxxl **70.697 → 97.851** (layout 32 → 0). Rest xxxl
captures clear 97.5. Mid-flight t1350.xxxl **97.413** / t2350.xxxl
**96.875** stay OPEN (spring over 83 pt rows; 14 / 8 views animating).

### 2. Compact-height `beginRefreshing` does not subtract another 60

MEASURED Feed t700.landscape, iPhone SE 2x / iOS 26.1, window 667×375:

- Rest (t200.landscape): adj **78**, offset **−78**, bar `[0, 24, 667, 54]`.
- Golden refresh: adj **138**, offset **−138**, bar still **54** (no
  large-title stretch). The script already set offset to −adj−60.
- Ours then subtracted another 60 because compact height does not stretch
  the bar, landing at **−198** and shifting every card 60 pt (blob 60421,
  layout 12).

Portrait Feed t700 still stretches 106 → 166 then rebases −176 → −236.
Skip the extra `−60` when `UINavigationBar.isCompactHeight`. Guard:
`OpenUIKitRuntime.systemFontCut == .iOS`. Catalyst and portrait
`control_refresh` (rest offset 0) unchanged.

Feed t700.landscape **60.998 → 99.406** (layout 12 → 0).

### 3. Modal — no detent / dimming / corner rule landed

Lowest fail is still t5200.ax1 **77.217** (already
`Modal-t5200-ax1-header-slack`). Golden card **426** at y=120.5 vs ours
**384** at 141.5; title relative y **73** vs 22; header container 234;
gap 42.5. A pad of 73+42.5 over-grows the card vs 426. Headerless t7200.ax1
already stays the **304** card (97.412). No sheet-detent, dimming-view, or
presentation-corner sample closed a named fail without guessing. The app
was not changed.

## Axis summary vs round-18

| app | axis | n | board worst | after worst | after mean | <97.5 |
|---|---|---|---|---|---|---|
| TableEditor | light | 8 | 97.716 | 97.716 | 98.922 | 0 |
| TableEditor | dark | 8 | 96.722 | 96.722 | 97.752 | 2 |
| TableEditor | rtl | 8 | 97.712 | 97.712 | 98.921 | 0 |
| TableEditor | ax1 | 8 | 96.424 | 96.429 | 97.330 | 6 |
| TableEditor | xxxl | 8 | 70.697 | 96.875 | 97.776 | 2 |
| TableEditor | landscape | 8 | 97.920 | 97.920 | 98.833 | 0 |
| TableEditor | ipad | 8 | 98.936 | 98.936 | 99.480 | 0 |
| Feed | light | 6 | 99.049 | 99.049 | 99.332 | 0 |
| Feed | dark | 6 | 98.699 | 98.699 | 99.052 | 0 |
| Feed | rtl | 6 | 99.036 | 99.036 | 99.325 | 0 |
| Feed | ax1 | 6 | 99.324 | 99.324 | 99.433 | 0 |
| Feed | xxxl | 6 | 99.123 | 99.123 | 99.363 | 0 |
| Feed | landscape | 6 | 60.998 | 76.342 | 87.965 | 3 |
| Feed | ipad | 6 | 91.797 | 91.797 | 95.862 | 3 |
| Modal | light | 12 | 97.640 | 97.640 | 99.107 | 0 |
| Modal | dark | 12 | 97.428 | 97.428 | 98.822 | 2 |
| Modal | rtl | 12 | 97.536 | 97.536 | 98.889 | 0 |
| Modal | ax1 | 12 | 77.217 | 77.217 | 97.266 | 2 |
| Modal | xxxl | 12 | 84.998 | 84.998 | 97.984 | 1 |
| Modal | landscape | 12 | 97.653 | 97.653 | 99.080 | 0 |
| Modal | ipad | 12 | 91.522 | 91.522 | 98.990 | 1 |

Drops vs the round-18 board ≥ 0.05: **none**. TableEditor t1350.ax1
96.787 → 96.779 is −0.008 (compare residual at the minus disc).

## Every row of the three apps, every axis

`SKIP_CAPTURE=1` against the round-18 goldens. Bold after = newly above
97.5.

| app | axis | capture | before | after | blob | layout |
|---|---|---|---|---|---|---|
| TableEditor | light | t200 | 99.188 | 99.188 | 12.0 | 0 |
| TableEditor | light | t900 | 99.120 | 99.120 | 12.0 | 0 |
| TableEditor | light | t1350 | 98.343 | 98.343 | 14.5 | 0 |
| TableEditor | light | t1900 | 99.120 | 99.120 | 12.0 | 0 |
| TableEditor | light | t2350 | 97.716 | 97.716 | 12.0 | 0 |
| TableEditor | light | t2900 | 99.099 | 99.099 | 12.0 | 0 |
| TableEditor | light | t3800 | 99.100 | 99.100 | 12.0 | 0 |
| TableEditor | light | t4800 | 99.693 | 99.693 | 12.0 | 0 |
| TableEditor | dark | t200.dark | 98.812 | 98.812 | 12.0 | 0 |
| TableEditor | dark | t900.dark | 97.556 | 97.556 | 12.0 | 0 |
| TableEditor | dark | t1350.dark | 96.926 | 96.926 | 18.5 | 0 |
| TableEditor | dark | t1900.dark | 97.565 | 97.565 | 12.0 | 0 |
| TableEditor | dark | t2350.dark | 96.722 | 96.722 | 12.0 | 0 |
| TableEditor | dark | t2900.dark | 97.549 | 97.549 | 12.0 | 0 |
| TableEditor | dark | t3800.dark | 97.554 | 97.554 | 12.0 | 0 |
| TableEditor | dark | t4800.dark | 99.331 | 99.331 | 12.0 | 0 |
| TableEditor | rtl | t200.rtl | 99.188 | 99.188 | 12.0 | 0 |
| TableEditor | rtl | t900.rtl | 99.120 | 99.120 | 12.0 | 0 |
| TableEditor | rtl | t1350.rtl | 98.343 | 98.343 | 14.5 | 0 |
| TableEditor | rtl | t1900.rtl | 99.120 | 99.120 | 12.0 | 0 |
| TableEditor | rtl | t2350.rtl | 97.712 | 97.712 | 12.0 | 0 |
| TableEditor | rtl | t2900.rtl | 99.096 | 99.096 | 12.0 | 0 |
| TableEditor | rtl | t3800.rtl | 99.097 | 99.097 | 12.0 | 0 |
| TableEditor | rtl | t4800.rtl | 99.689 | 99.689 | 12.0 | 0 |
| TableEditor | ax1 | t200.ax1 | 97.913 | 97.913 | 24.5 | 1 |
| TableEditor | ax1 | t900.ax1 | 97.292 | 97.300 | 34.2 | 1 |
| TableEditor | ax1 | t1350.ax1 | 96.787 | 96.779 | 166.5 | 1 |
| TableEditor | ax1 | t1900.ax1 | 97.302 | 97.311 | 34.2 | 1 |
| TableEditor | ax1 | t2350.ax1 | 96.424 | 96.429 | 34.2 | 1 |
| TableEditor | ax1 | t2900.ax1 | 97.292 | 97.301 | 34.2 | 1 |
| TableEditor | ax1 | t3800.ax1 | 97.302 | 97.311 | 34.2 | 1 |
| TableEditor | ax1 | t4800.ax1 | 98.294 | 98.294 | 24.5 | 1 |
| TableEditor | xxxl | t200.xxxl | 92.352 | **98.053** | 8.2 | 0 |
| TableEditor | xxxl | t900.xxxl | 89.458 | **97.858** | 23.5 | 0 |
| TableEditor | xxxl | t1350.xxxl | 88.941 | 97.413 | 45.8 | 0 |
| TableEditor | xxxl | t1900.xxxl | 89.496 | **97.849** | 23.5 | 0 |
| TableEditor | xxxl | t2350.xxxl | 88.167 | 96.875 | 23.5 | 0 |
| TableEditor | xxxl | t2900.xxxl | 89.426 | **97.839** | 23.5 | 0 |
| TableEditor | xxxl | t3800.xxxl | 70.697 | **97.851** | 23.5 | 0 |
| TableEditor | xxxl | t4800.xxxl | 92.707 | **98.471** | 8.2 | 0 |
| TableEditor | landscape | t200.landscape | 99.373 | 99.373 | 51.5 | 1 |
| TableEditor | landscape | t900.landscape | 98.832 | 98.832 | 83.5 | 1 |
| TableEditor | landscape | t1350.landscape | 98.548 | 98.548 | 83.5 | 1 |
| TableEditor | landscape | t1900.landscape | 98.832 | 98.832 | 83.5 | 1 |
| TableEditor | landscape | t2350.landscape | 97.920 | 97.920 | 83.5 | 1 |
| TableEditor | landscape | t2900.landscape | 98.811 | 98.811 | 83.5 | 1 |
| TableEditor | landscape | t3800.landscape | 98.812 | 98.812 | 83.5 | 1 |
| TableEditor | landscape | t4800.landscape | 99.534 | 99.534 | 51.5 | 1 |
| TableEditor | ipad | t200 | 99.901 | 99.901 | 80.5 | 1 |
| TableEditor | ipad | t900 | 99.457 | 99.457 | 105.2 | 1 |
| TableEditor | ipad | t1350 | 99.251 | 99.251 | 105.2 | 1 |
| TableEditor | ipad | t1900 | 99.494 | 99.494 | 105.2 | 1 |
| TableEditor | ipad | t2350 | 98.936 | 98.936 | 105.2 | 1 |
| TableEditor | ipad | t2900 | 99.452 | 99.452 | 105.2 | 1 |
| TableEditor | ipad | t3800 | 99.452 | 99.452 | 105.2 | 1 |
| TableEditor | ipad | t4800 | 99.896 | 99.896 | 80.5 | 1 |
| Feed | light | t200 | 99.674 | 99.674 | 0.0 | 0 |
| Feed | light | t700 | 99.494 | 99.494 | 0.0 | 0 |
| Feed | light | t1800 | 99.674 | 99.674 | 0.0 | 0 |
| Feed | light | t2800 | 99.054 | 99.054 | 3.5 | 0 |
| Feed | light | t3800 | 99.049 | 99.049 | 3.5 | 0 |
| Feed | light | t4800 | 99.049 | 99.049 | 3.5 | 0 |
| Feed | dark | t200.dark | 99.435 | 99.435 | 1.5 | 0 |
| Feed | dark | t700.dark | 99.345 | 99.345 | 1.5 | 0 |
| Feed | dark | t1800.dark | 99.435 | 99.435 | 1.5 | 0 |
| Feed | dark | t2800.dark | 98.701 | 98.701 | 3.8 | 0 |
| Feed | dark | t3800.dark | 98.699 | 98.699 | 3.8 | 0 |
| Feed | dark | t4800.dark | 98.699 | 98.699 | 3.8 | 0 |
| Feed | rtl | t200.rtl | 99.673 | 99.673 | 11.5 | 5 |
| Feed | rtl | t700.rtl | 99.493 | 99.493 | 11.5 | 5 |
| Feed | rtl | t1800.rtl | 99.673 | 99.673 | 11.5 | 5 |
| Feed | rtl | t2800.rtl | 99.040 | 99.040 | 5.5 | 0 |
| Feed | rtl | t3800.rtl | 99.036 | 99.036 | 5.5 | 0 |
| Feed | rtl | t4800.rtl | 99.036 | 99.036 | 5.5 | 0 |
| Feed | ax1 | t200.ax1 | 99.599 | 99.599 | 16.8 | 0 |
| Feed | ax1 | t700.ax1 | 99.421 | 99.421 | 16.8 | 0 |
| Feed | ax1 | t1800.ax1 | 99.599 | 99.599 | 16.8 | 0 |
| Feed | ax1 | t2800.ax1 | 99.329 | 99.329 | 7.2 | 0 |
| Feed | ax1 | t3800.ax1 | 99.324 | 99.324 | 7.2 | 0 |
| Feed | ax1 | t4800.ax1 | 99.324 | 99.324 | 7.2 | 0 |
| Feed | xxxl | t200.xxxl | 99.661 | 99.661 | 0.2 | 0 |
| Feed | xxxl | t700.xxxl | 99.481 | 99.481 | 0.2 | 0 |
| Feed | xxxl | t1800.xxxl | 99.661 | 99.661 | 0.2 | 0 |
| Feed | xxxl | t2800.xxxl | 99.127 | 99.127 | 7.2 | 0 |
| Feed | xxxl | t3800.xxxl | 99.123 | 99.123 | 7.2 | 0 |
| Feed | xxxl | t4800.xxxl | 99.123 | 99.123 | 7.2 | 0 |
| Feed | landscape | t200.landscape | 99.603 | 99.603 | 3.5 | 0 |
| Feed | landscape | t700.landscape | 60.998 | **99.406** | 3.5 | 0 |
| Feed | landscape | t1800.landscape | 99.603 | 99.603 | 3.5 | 0 |
| Feed | landscape | t2800.landscape | 76.342 | 76.342 | 56.5 | 0 |
| Feed | landscape | t3800.landscape | 76.417 | 76.417 | 57.2 | 0 |
| Feed | landscape | t4800.landscape | 76.417 | 76.417 | 57.2 | 0 |
| Feed | ipad | t200 | 99.878 | 99.878 | 0.0 | 0 |
| Feed | ipad | t700 | 99.822 | 99.822 | 0.0 | 0 |
| Feed | ipad | t1800 | 99.878 | 99.878 | 0.0 | 0 |
| Feed | ipad | t2800 | 92.000 | 92.000 | 21944.0 | 1 |
| Feed | ipad | t3800 | 91.797 | 91.797 | 25129.0 | 1 |
| Feed | ipad | t4800 | 91.797 | 91.797 | 25129.0 | 1 |
| Modal | light | t200 | 99.839 | 99.839 | 3.5 | 0 |
| Modal | light | t600 | 97.640 | 97.640 | 34.8 | 0 |
| Modal | light | t1200 | 97.938 | 97.938 | 9.0 | 0 |
| Modal | light | t2100 | 99.839 | 99.839 | 3.5 | 0 |
| Modal | light | t3200 | 99.118 | 99.118 | 2.5 | 0 |
| Modal | light | t4100 | 99.839 | 99.839 | 3.5 | 0 |
| Modal | light | t5200 | 97.843 | 97.843 | 3.8 | 0 |
| Modal | light | t6100 | 99.839 | 99.839 | 3.5 | 0 |
| Modal | light | t7200 | 98.615 | 98.615 | 3.8 | 0 |
| Modal | light | t8100 | 99.839 | 99.839 | 3.5 | 0 |
| Modal | light | t9200 | 99.105 | 99.105 | 11.0 | 0 |
| Modal | light | t10100 | 99.833 | 99.833 | 3.5 | 5 |
| Modal | dark | t200.dark | 99.648 | 99.648 | 4.2 | 0 |
| Modal | dark | t600.dark | 97.428 | 97.428 | 22.5 | 0 |
| Modal | dark | t1200.dark | 97.467 | 97.467 | 7.5 | 0 |
| Modal | dark | t2100.dark | 99.648 | 99.648 | 4.2 | 0 |
| Modal | dark | t3200.dark | 98.405 | 98.405 | 8.5 | 0 |
| Modal | dark | t4100.dark | 99.648 | 99.648 | 4.2 | 0 |
| Modal | dark | t5200.dark | 97.707 | 97.707 | 3.0 | 0 |
| Modal | dark | t6100.dark | 99.648 | 99.648 | 4.2 | 0 |
| Modal | dark | t7200.dark | 98.375 | 98.375 | 0.5 | 0 |
| Modal | dark | t8100.dark | 99.648 | 99.648 | 4.2 | 0 |
| Modal | dark | t9200.dark | 98.589 | 98.589 | 8.8 | 0 |
| Modal | dark | t10100.dark | 99.648 | 99.648 | 4.2 | 5 |
| Modal | rtl | t200.rtl | 99.437 | 99.437 | 14.5 | 0 |
| Modal | rtl | t600.rtl | 97.536 | 97.536 | 38.2 | 0 |
| Modal | rtl | t1200.rtl | 97.844 | 97.844 | 9.0 | 0 |
| Modal | rtl | t2100.rtl | 99.437 | 99.437 | 14.5 | 0 |
| Modal | rtl | t3200.rtl | 99.138 | 99.138 | 1.2 | 0 |
| Modal | rtl | t4100.rtl | 99.437 | 99.437 | 14.5 | 0 |
| Modal | rtl | t5200.rtl | 97.831 | 97.831 | 4.2 | 0 |
| Modal | rtl | t6100.rtl | 99.437 | 99.437 | 14.5 | 0 |
| Modal | rtl | t7200.rtl | 98.601 | 98.601 | 4.2 | 0 |
| Modal | rtl | t8100.rtl | 99.437 | 99.437 | 14.5 | 0 |
| Modal | rtl | t9200.rtl | 99.103 | 99.103 | 11.0 | 0 |
| Modal | rtl | t10100.rtl | 99.432 | 99.432 | 14.5 | 5 |
| Modal | ax1 | t200.ax1 | 99.809 | 99.809 | 2.5 | 0 |
| Modal | ax1 | t600.ax1 | 97.606 | 97.606 | 34.8 | 0 |
| Modal | ax1 | t1200.ax1 | 97.899 | 97.899 | 9.0 | 0 |
| Modal | ax1 | t2100.ax1 | 99.809 | 99.809 | 2.5 | 0 |
| Modal | ax1 | t3200.ax1 | 99.107 | 99.107 | 2.5 | 0 |
| Modal | ax1 | t4100.ax1 | 99.809 | 99.809 | 2.5 | 0 |
| Modal | ax1 | t5200.ax1 | 77.217 | 77.217 | 1028.2 | 5 |
| Modal | ax1 | t6100.ax1 | 99.809 | 99.809 | 2.5 | 0 |
| Modal | ax1 | t7200.ax1 | 97.412 | 97.412 | 6.5 | 0 |
| Modal | ax1 | t8100.ax1 | 99.809 | 99.809 | 2.5 | 0 |
| Modal | ax1 | t9200.ax1 | 99.095 | 99.095 | 18.8 | 0 |
| Modal | ax1 | t10100.ax1 | 99.806 | 99.806 | 2.0 | 5 |
| Modal | xxxl | t200.xxxl | 99.809 | 99.809 | 2.5 | 0 |
| Modal | xxxl | t600.xxxl | 97.606 | 97.606 | 34.8 | 0 |
| Modal | xxxl | t1200.xxxl | 97.899 | 97.899 | 9.0 | 0 |
| Modal | xxxl | t2100.xxxl | 99.809 | 99.809 | 2.5 | 0 |
| Modal | xxxl | t3200.xxxl | 99.107 | 99.107 | 2.5 | 0 |
| Modal | xxxl | t4100.xxxl | 99.809 | 99.809 | 2.5 | 0 |
| Modal | xxxl | t5200.xxxl | 84.998 | 84.998 | 158.5 | 5 |
| Modal | xxxl | t6100.xxxl | 99.809 | 99.809 | 2.5 | 0 |
| Modal | xxxl | t7200.xxxl | 98.252 | 98.252 | 6.5 | 0 |
| Modal | xxxl | t8100.xxxl | 99.809 | 99.809 | 2.5 | 0 |
| Modal | xxxl | t9200.xxxl | 99.095 | 99.095 | 18.8 | 0 |
| Modal | xxxl | t10100.xxxl | 99.806 | 99.806 | 2.0 | 5 |
| Modal | landscape | t200.landscape | 99.585 | 99.585 | 87.0 | 1 |
| Modal | landscape | t600.landscape | 99.107 | 99.107 | 11.0 | 1 |
| Modal | landscape | t1200.landscape | 98.754 | 98.754 | 3.8 | 1 |
| Modal | landscape | t2100.landscape | 99.585 | 99.585 | 87.0 | 1 |
| Modal | landscape | t3200.landscape | 98.864 | 98.864 | 2.5 | 1 |
| Modal | landscape | t4100.landscape | 99.585 | 99.585 | 87.0 | 1 |
| Modal | landscape | t5200.landscape | 97.653 | 97.653 | 36.0 | 1 |
| Modal | landscape | t6100.landscape | 99.535 | 99.535 | 87.2 | 1 |
| Modal | landscape | t7200.landscape | 98.333 | 98.333 | 36.0 | 1 |
| Modal | landscape | t8100.landscape | 99.535 | 99.535 | 87.2 | 1 |
| Modal | landscape | t9200.landscape | 98.922 | 98.922 | 0.2 | 1 |
| Modal | landscape | t10100.landscape | 99.503 | 99.503 | 66.5 | 6 |
| Modal | ipad | t200 | 99.939 | 99.939 | 72.2 | 1 |
| Modal | ipad | t600 | 99.235 | 99.235 | 37.5 | 1 |
| Modal | ipad | t1200 | 99.367 | 99.367 | 32.5 | 1 |
| Modal | ipad | t2100 | 99.939 | 99.939 | 72.2 | 1 |
| Modal | ipad | t3200 | 99.782 | 99.782 | 2.5 | 1 |
| Modal | ipad | t4100 | 99.939 | 99.939 | 72.2 | 1 |
| Modal | ipad | t5200 | 99.419 | 99.419 | 32.5 | 1 |
| Modal | ipad | t6100 | 99.939 | 99.939 | 72.2 | 1 |
| Modal | ipad | t7200 | 91.522 | 91.522 | 66.8 | 1 |
| Modal | ipad | t8100 | 99.939 | 99.939 | 72.2 | 1 |
| Modal | ipad | t9200 | 98.923 | 98.923 | 68.5 | 1 |
| Modal | ipad | t10100 | 99.939 | 99.939 | 71.8 | 6 |

## OPEN (measured; in `scoreboard/open.txt`)

- **TableEditor t1350.xxxl / t2350.xxxl** — rest frames match (t200.xxxl
  98.053 / t900.xxxl 97.858 / t3800.xxxl 97.851, layout 0). Mid-flight delete
  t1350 **97.413** blob 45.8 at `[18.5, 653.5, 27, 10.5]`, 14 views
  animating; insert t2350 **96.875** blob 23.5 at `[18.0, 162.0, 26.5, 10.0]`,
  8 views. Spring over 83 pt rows vs `.large` 62.
- **TableEditor ax1 edit disc** — t900.ax1 **97.300** blob 34.2; t2350.ax1
  **96.429** at `[20.5, 185.0, 30.0, 10.0]`; t1350.ax1 **96.779**. Layout 1:
  Reminders abs.w 238.5 vs 239.5. Rest t200.ax1 **97.913** already above bar.
  Disc is the measured ax1 39×38 chrome; leftover is glyph/fill.
- **TableEditor dark mid-flight** — t1350.dark **96.926** blob 18.5;
  t2350.dark **96.722** blob 12.0 at `[133.5, 76.0, 0.5, 24.0]`, 10 views
  animating (title stem / clock). Same class as dark-rest.
- **Feed t2800/t3800/t4800.landscape** — **76.342–76.417** blob 56–57 at
  `[343.0, 39.0, 8.5, 13.0]`, 0 layout. Offset 300 both sides. Compact bar
  54. Missing nav-bar glass over the scrolled 16:9 card. Same class as
  `Tabs-t2000-scroll-glass`.
- **Feed-ipad t2800/t3800/t4800** — **92.000 / 91.797 / 91.797** blob
  21944–25129 at `[18.0, 0.0, 784.0, 28.0]`. Layout 1: letter A golden 1 /
  ours 0 (culled off-screen). Pad bar/glass after scroll-300; not cell layout.
- **Modal t5200.ax1 / t5200.xxxl / t7200.ax1** — header slack (card 426 vs
  384; title y 73 vs 22). xxxl t5200 **84.998** blob 158.5, 5 layout (action
  y 13 pt). Headerless t7200.ax1 **97.412** blob 6.5 at `[319.5, 28.5, 4.0, 10.5]`.
- **Modal t600.dark / t1200.dark** — **97.428 / 97.467** blob 22.5 / 7.5,
  0 layout. Dump at rest; golden pixels mid-flight. Same clock class as
  `Modal-t600-rtl-clock`.
- **Modal-ipad t7200** — **91.522** blob 66.8 at `[749.0, 48.0, 12.0, 12.0]`.
  Layout 1: "More" abs.x 753.199 vs 747.5. Pad trailing platter, not sheet
  chrome.

## Gates

- `swift test --filter TableViewIOSEditChromeTests --filter testPlainSubtitleRowAndEditChromeAtXxxxl --filter UIRefreshControlIOSCutTests`: **15** tests, 0 failures
- iOS suite `SKIP_CAPTURE=1`: **112/113** (`corner_radius` 99.411)
- Catalyst: **124/124**
- Real-app floors held:
  **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.650 / 82.170 / 99.860 / 99.734 / 85.393**
  (`ledger_light` / `focus_home_light` have no golden in `/tmp/golden_realapp_ios`)
- Linux `swift:6.2-noble` `openrender` green (179.59 s). Host `.build`
  symlinks break a literal `cp -r /src /work`; source tar excluding `.build`
  is the same tree.
- No `Package.resolved`
