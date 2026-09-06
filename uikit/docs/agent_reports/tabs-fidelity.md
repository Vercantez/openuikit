# Tabs compact-height tab bar (landscape iOS 26 chrome)

Round-18 board (main 485fe6e7): Tabs had 42 failing rows. Worst were
t2000 ~84.6 (78.1 landscape) and t6000 ~87.5 (82.5 landscape). t2000 is
the Scroll tab; t6000 is 0.6 s after cancel-search. Goldens
`/tmp/hc-conformance-Tabs[-axis]/golden`, replayed with `SKIP_CAPTURE=1`
into `/tmp/conformance-Tabs[-axis]`. Device iPhone SE 2x / iOS 26.1
(`OpenUIKit-2x-tabs-fidelity`). Portrait / dark / rtl / ax1 / xxxl / iPad
chrome was already modelled (conf-tabs, tabs-cells, symbols-tabbar,
tabs-t2000, tabs-rows, ipad-rest). This round closes the compact-height
phone tab bar.

## What the dumps said

### t2000 portrait (Scroll selected)

Golden `UITabBar [0, 584, 375, 83]`, platter `[51, 0, 274, 62]`, stacked
18/medium/large icons. Largest wrong region `[24.0, 637.5, 13.5, 13.5]`.
1 view animating. Same glass-over-scroll-blocks residual as
`Tabs-t2000-scroll-glass` (open.txt). Not a tab-bar layout miss.

### t6000 portrait (0.6 s after cancel)

Golden nav `[0, 10, 375, 114]`, search `[0, 54, 375, 60]`, table
`adjustedContentInset.top` **124**, Row 1 abs y 124. 1 view animating.
Ours snaps `isActive=false` (bar 54 / table y 64). Same
`Tabs-t6000-cancel-inset` clock class. Not modelled.

### t200 / t2000 landscape (the structural miss)

Golden (667×375, vclass compact, window SA zero):

- `UITabBar [0, 311, 667, 64]` (not ours `[0, 292, 667, 83]`)
- `_UITabBarPlatterView [205, 0, 257.5, 44]`
- `_UITabButton [4, 4, 86.5, 36]`, `[94.5, 4, 76.5, 36]`,
  `[175, 4, 78.5, 36]` — icon LEFT, title RIGHT (not stacked)
- calendar `[6, 9, 21, 18.5]`; clock / plus.circle.fill
  `[6, 7.5, 20.5, 20.5]`
- selected title `.SFUI-Semibold` 12, unselected `.SFUI-Regular` 12,
  y=11, height 14.5
- badge `_UIBarBadgeView [59.5, 0, 16, 16]` r=8, digit `.SFUI-Medium` 10
  in `[4, 2, 8, 12]`
- table / scroll `safeAreaInsets.bottom` **64**
- `_UITabSelectionView` = the selected button rect (36 tall)

Packing (ContentView / regular 12 pt intrinsic):
`width = 6 + iconW + 8 + titleW + 12`. Library 6+21+8+39.5+12 = **86.5**,
Tools 6+20.5+8+30+12 = **76.5**, Scroll 6+20.5+8+32+12 = **78.5**. 4 pt
around and between: 4+86.5+4+76.5+4+78.5+4 = **257.5**. Platter x =
round((667−257.5)/2) = **205**. Selected semibold does not widen the
pill (Library label 42 sits in the 86.5 button).

## Rule (iOS cut, phone, compact vertical size class)

Guard: `UITabBar.isIOS && !isPad && verticalSizeClass == .compact`.
Pad keeps the 44 pt top strip; unspecified (portrait suite / Catalyst)
keeps the 83 / 72 stacked bar.

1. `barHeight` **64**. Child `safeAreaInsets.bottom` 64.
2. Platter 44 tall, corner r=22, packed pills 36 tall at y=4.
3. Horizontal icon+title: icon x=6, title at icon.maxX+8, title y=11.
   Selected 12 pt semibold, unselected 12 pt regular.
4. Compact icon display size from the dump vs the harvested 18/medium/large
   alignment box: calendar **21×18.5** (was 29×25), clock /
   plus.circle.fill **20.5×20.5** (was 27.5×27.5). Same 18 pt masks,
   `UIImageView` scaleToFill into those frames.
5. Badge 16×16, origin `(buttonWidth − 17, 0)`, digit 10 pt medium
   `[4, 2, 8, 12]`.
6. Selection capsule = selected button frame, r=18.

Cited next to the constants: Tabs t200.landscape / t2000.landscape,
iPhone SE 2x / iOS 26.1.

## After (`SKIP_CAPTURE=1`, round-18 goldens)

Portrait light / dark / rtl / ax1 / xxxl and iPad are unchanged (byte-level
on iPad ours vs the hillclimb ours). Landscape:

| capture | before | after | blob before → after | notes |
|---|---|---|---|---|
| t200.landscape | 95.882 | **97.704** | 638.5 → 43.2 | above 97.5 |
| t1000.landscape | 97.204 | **99.019** | 646.5 → 109.0 | above 97.5 |
| t2000.landscape | 78.053 | 77.901 | 364.5 → **10.5** | glass; layout 23 → 9 |
| t3000.landscape | 96.097 | **98.082** | 638.5 → 43.2 | above 97.5 |
| t4000.landscape | 94.768 | 94.962 | 98.8 → 98.8 | keyboard glyphs |
| t5000.landscape | 93.695 | 93.888 | 98.8 → 98.8 | keyboard glyphs |
| t6000.landscape | 82.522 | **84.502** | 638.5 → 45.8 | cancel inset remains |
| t7000.landscape | 95.379 | 97.270 | 638.5 → 46.2 | 0.23 below bar |

t2000.landscape pixel score −0.15: the 83 pt stacked bar no longer covers
a different strip; the platter now sits on the coloured scroll blocks
where glass mix is the known gap (blob 10.5 at `[218.5, 329.5, 13, 9]`,
same class as portrait t2000).

## Every Tabs row (before = round-18 `/tmp/hc-conformance-Tabs*`)

| row | before | after |
|---|---|---|
| t200 | 96.657 | 96.657 |
| t1000 | 99.402 | 99.402 |
| t2000 | 84.603 | 84.603 |
| t3000 | 96.898 | 96.898 |
| t4000 | 95.006 | 95.006 |
| t5000 | 93.709 | 93.709 |
| t6000 | 87.496 | 87.496 |
| t7000 | 96.600 | 96.600 |
| t200.dark | 97.317 | 97.317 |
| t1000.dark | 98.786 | 98.786 |
| t2000.dark | 84.851 | 84.851 |
| t3000.dark | 97.553 | 97.553 |
| t4000.dark | 92.353 | 92.353 |
| t5000.dark | 92.416 | 92.416 |
| t6000.dark | 88.262 | 88.262 |
| t7000.dark | 97.193 | 97.193 |
| t200.rtl | 96.671 | 96.671 |
| t1000.rtl | 99.091 | 99.091 |
| t2000.rtl | 84.598 | 84.598 |
| t3000.rtl | 96.912 | 96.912 |
| t4000.rtl | 94.789 | 94.789 |
| t5000.rtl | 93.573 | 93.573 |
| t6000.rtl | 87.456 | 87.456 |
| t7000.rtl | 96.610 | 96.610 |
| t200.ax1 | 96.541 | 96.541 |
| t1000.ax1 | 99.043 | 99.043 |
| t2000.ax1 | 84.603 | 84.603 |
| t3000.ax1 | 96.739 | 96.739 |
| t4000.ax1 | 92.822 | 92.822 |
| t5000.ax1 | 90.967 | 90.967 |
| t6000.ax1 | 82.735 | 82.735 |
| t7000.ax1 | 95.973 | 95.973 |
| t200.xxxl | 96.419 | 96.419 |
| t1000.xxxl | 99.043 | 99.043 |
| t2000.xxxl | 84.629 | 84.629 |
| t3000.xxxl | 96.634 | 96.634 |
| t4000.xxxl | 94.836 | 94.836 |
| t5000.xxxl | 93.327 | 93.327 |
| t6000.xxxl | 85.238 | 85.238 |
| t7000.xxxl | 96.169 | 96.169 |
| t200.landscape | 95.882 | **97.704** |
| t1000.landscape | 97.204 | **99.019** |
| t2000.landscape | 78.053 | 77.901 |
| t3000.landscape | 96.097 | **98.082** |
| t4000.landscape | 94.768 | 94.962 |
| t5000.landscape | 93.695 | 93.888 |
| t6000.landscape | 82.522 | **84.502** |
| t7000.landscape | 95.379 | 97.270 |
| Tabs-ipad t200 | 98.621 | 98.621 |
| Tabs-ipad t1000 | 99.209 | 99.209 |
| Tabs-ipad t2000 | 98.657 | 98.657 |
| Tabs-ipad t3000 | 98.157 | 98.157 |
| Tabs-ipad t4000 | 96.100 | 96.100 |
| Tabs-ipad t5000 | 96.254 | 96.254 |
| Tabs-ipad t6000 | 98.603 | 98.603 |
| Tabs-ipad t7000 | 98.365 | 98.365 |

New landscape passes: t200 / t1000 / t3000. t7000.landscape 97.270 is
0.23 under the bar.

## OPEN (not modelled)

- Portrait t2000 glass over scroll blocks (`Tabs-t2000-scroll-glass`).
  Landscape t2000 is the same mix with the bar now in the dump frame
  (`Tabs-t2000-landscape-glass`).
- t6000 family: 0.6 s after cancel the golden still has the 60 pt search
  slot (portrait inset 124 / landscape 138; ax1 bar 150). Clock, 1 view
  animating (`Tabs-t6000-cancel-inset`, `Tabs-t6000-ax1-search-below-bar`).
- t4000 / t5000 keyboard glyphs (Forms-keyboard-letter-caps /
  Forms-t1200-landscape-key-glyphs).
- Compact-height 12 pt title width: dump Tools/Scroll regular 30 / 32;
  SelectedContentView copies dump semibold 31.5 / 34. Button widths follow
  regular. Layout-issue `abs.w` is the duplicate dump labels.
- Compact symbol *configuration* was not dumped (`preferredSymbolConfiguration`
  is not in confprobe JSON). Icon *frames* were read off t200.landscape.

## Gates

- Catalyst `openrender render` + `compare.py`: **124/124**
- iOS suite `SKIP_CAPTURE=1 scripts/ios_suite.sh /tmp/suite-tabs-fidelity`: **112/113**, miss is the known `corner_radius` (99.411)
- Real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393**
- `swift test --filter testCompactHeightTabBarIsInline64Pt` (platter `[205, 0, 257.5, 44]`) plus pad tab-bar tests and `TabBarControllerTests`
- Linux `swift:6.2-noble` `openrender` release build green
- No `Package.resolved`
