# Notes fidelity — inactive search slot, compact list header, compact-height tab bar

Round-18 board (`485fe6e7` / `scoreboard/latest.md` at `6b739e29`): Notes had
60 failing rows and the lowest scores on the board (t11000.ax1 **52.20**,
t10000/t6000.landscape **~56.4**, t11000.xxxl **58.5**, …). Goldens:
`/tmp/hc-conformance-Notes[-axis]/golden` (read-only). Replay:
`SKIP_CAPTURE=1 scripts/conformance_flow.sh /tmp/conformance-Notes[-axis]
Notes [--axis]`. Device: iPhone SE 2x / iOS 26.1, window 375×667 (landscape
667×375), status bar hidden. App script: rest list t200 → push detail t1200 /
focus-body t2100 / pop t3000 → search t4000 / type "Meet" t5000 / cancel t6000
→ settings t7000–t9000 → back t10000 → delete alert t11000 / confirm t12000.

Nothing in `Sources/ConformanceApps/Notes/` was changed.

## What the dumps said (before)

t200 vs t6000, same 8 notes, phone + tab bar:

| | t200 rest | t4000 active search | t6000 after cancel |
|---|---|---|---|
| nav bar | `[0, 10, 375, 54]` | 60 | **114** = 54+60 |
| search | height 0 | fills the bar, field `[16, 8, 288, 44]` | `[0, 54, 375, 60]`, field `[16, 1, 343, 44]` |
| table inset.top | 64 | 70 | **124** |
| first header | **38** (label y 12) | **38** | **55.5** (label y 29.5) |

Ledger (window-root nav, no tab bar) restores 54 after cancel. Pad stays 54.
ax1 slot 96 (bar 150, inset 160); xxxl 74 (bar 128); landscape origin y 24 +
114, field `[20, 1, 627, 44]`. Tabs t7000 then hides it (offset 260, bar 54).

t200 overflow (8 notes) compact 38; t5000 one row 55.5. After pop, t3000
golden is 38 again but ours rebuilt 55.5 while the list was covered (topItem
was the detail, no search).

Tab "Notes" blob 216 at `[134, 597.5, 23, 21]` — `note.text` was not in the
symbol harvest. Disclosure title `[16, 15, 292.5, 20.5]` in a 316.5 content
view (trailing **8**, not 16). RTL labels `[8, 15, 292.5]` (physical left is
trailing).

Landscape tab bar golden: `UITabBar [0, 311, 667, 64]`, platter
`[240, 0, 187.5, 44]` (2 items) / Tabs `[205, 0, 257.5, 44]` (3 items),
buttons 36 pt at y 4, icon+title in a row. Ours was the portrait 83 pt bar at
y 292.

## Rules (iOS cut)

1. **Inactive search slot after cancel, phone + tab-bar nav only.**
   `searchSlotRevealed` sticks true once `isActive` becomes true.
   `showsInactiveSearchSlot`: iOS, phone, revealed, not hidden-by-scroll,
   not active, `tabBarController != nil`. Slot height = 8+scaledField+8
   (60 / 74 / 96). Inactive `layoutNavInactiveSlot`: field
   `(systemMargin, 1, W−2·margin, fieldH)` — 16 on 375, 20 on 667.
   `hideOnScrollContentBump` returns 0 while the slot is showing (otherwise
   Tabs t7000 offset 320 vs golden 260).

2. **First inset-grouped header under tab-hosted search.** Compact 38 when
   the list's *own* `navigationItem.searchController` is set, the VC is in a
   tab bar, the inactive slot is not showing, and `rowsH+full55.5+17.5`
   overflows the viewport. Using `topItem` failed t3000 (rebuild during
   push saw the detail). `displaysLargeTitles` (not SA.top ≥ 116) is what
   separates NavFlow t200 (116, header 38) from Notes t6000 (124, 55.5).
   Ledger / Forms / NavFlow landscape stay 55.5.

3. **Disclosure `accessoryType` trailing 8.** Same 8 pt SwitchCell already
   used for `accessoryView`. RTL: physical left is trailing — Notes t5000.rtl
   labels `[8, 15, 292.5]`.

4. **`note.text` harvested** at 17/medium/large + 18/medium/large (2x and 3x
   F0/F0.5). Tab 18/medium/large F0: 2x 58×50, ink 46×42 at 6,4.

5. **Compact-height tab bar.** `verticalSizeClass == .compact` (unspecified
   portrait / Catalyst unchanged). Bar **64** at y = H−64. Platter 44,
   items 36 at y 4 packed icon+title (icon leading 6, gap 8, title 12 pt at
   y 11, trailing 10.5, side pad 4, item gap 4). Symbols are unconfigured
   `UIImage(systemName:)` (Notes icon `[6, 9, 21, 18.5]` = harvest
   17|regular|unspecified 21×17.5), not portrait 18|medium|large.
   Badge 16×16 trailing-top (Tabs Tools `[61, 0, 16, 16]`).

## After (`SKIP_CAPTURE=1` vs round-18 goldens)

Default mean ~77 → **90.250**, worst 70.05 → **72.015** (t12000 animation).
Settings t7000–t9000 held ≥ 97.5. t5000 98.74 → **98.818**. iPad unchanged
(search slot is phone+tab only).

### Every Notes row, every axis

| scene | r18 | after | Δ |
|---|---|---|---|
| t200 | 77.841 | **89.469** | +11.63 |
| t1200 | 96.834 | 96.916 | +0.08 |
| t2100 | 95.362 | 95.363 | 0 |
| t3000 | 77.738 | **89.117** | +11.38 |
| t4000 | 77.815 | **89.111** | +11.30 |
| t5000 | 98.737 | **98.818** | +0.08 |
| t6000 | 67.524 | **82.159** | +14.64 |
| t7000 | 99.111 | 99.192 | +0.08 |
| t8000 | 99.093 | 99.174 | +0.08 |
| t9000 | 99.083 | 99.164 | +0.08 |
| t10000 | 67.522 | **82.142** | +14.62 |
| t11000 | 68.339 | **80.615** | +12.28 |
| t12000 | 70.049 | 72.015 | +1.97 |
| t200.dark | 75.785 | **87.195** | +11.41 |
| t1200.dark | 96.908 | 96.974 | +0.07 |
| t2100.dark | 93.918 | 93.919 | 0 |
| t3000.dark | 76.140 | **87.512** | +11.37 |
| t4000.dark | 75.783 | **86.884** | +11.10 |
| t5000.dark | 98.156 | 98.221 | +0.07 |
| t6000.dark | 66.161 | **82.885** | +16.72 |
| t7000.dark | 97.774 | 97.856 | +0.08 |
| t8000.dark | 97.771 | 97.854 | +0.08 |
| t9000.dark | 97.754 | 97.836 | +0.08 |
| t10000.dark | 66.244 | **82.984** | +16.74 |
| t11000.dark | 68.455 | **87.735** | +19.28 |
| t12000.dark | 68.731 | 73.005 | +4.27 |
| t200.rtl | 77.457 | **81.716** | +4.26 |
| t1200.rtl | 96.919 | 96.987 | +0.07 |
| t2100.rtl | 95.452 | 95.452 | 0 |
| t3000.rtl | 77.455 | **81.722** | +4.27 |
| t4000.rtl | 77.520 | **85.734** | +8.21 |
| t5000.rtl | 97.792 | **97.860** | +0.07 |
| t6000.rtl | 67.527 | **79.986** | +12.46 |
| t7000.rtl | 99.127 | 99.194 | +0.07 |
| t8000.rtl | 99.108 | 99.176 | +0.07 |
| t9000.rtl | 99.098 | 99.166 | +0.07 |
| t10000.rtl | 67.526 | **79.988** | +12.46 |
| t11000.rtl | 67.977 | **78.736** | +10.76 |
| t12000.rtl | 70.056 | 71.987 | +1.93 |
| t200.ax1 | 77.892 | **88.713** | +10.82 |
| t1200.ax1 | 96.849 | 96.931 | +0.08 |
| t2100.ax1 | 95.393 | 95.393 | 0 |
| t3000.ax1 | 77.779 | **88.351** | +10.57 |
| t4000.ax1 | 86.479 | 86.566 | +0.09 |
| t5000.ax1 | 89.879 | **96.167** | +6.29 |
| t6000.ax1 | 63.332 | **77.364** | +14.03 |
| t7000.ax1 | 99.109 | 99.190 | +0.08 |
| t8000.ax1 | 99.090 | 99.172 | +0.08 |
| t9000.ax1 | 99.080 | 99.161 | +0.08 |
| t10000.ax1 | 63.317 | **77.335** | +14.02 |
| t11000.ax1 | 52.196 | 55.123 | +2.93 |
| t12000.ax1 | 64.686 | 68.610 | +3.92 |
| t200.xxxl | 77.760 | **89.396** | +11.64 |
| t1200.xxxl | 96.849 | 96.931 | +0.08 |
| t2100.xxxl | 95.393 | 95.393 | 0 |
| t3000.xxxl | 77.712 | **89.290** | +11.58 |
| t4000.xxxl | 87.592 | 88.375 | +0.78 |
| t5000.xxxl | 91.620 | **97.921** | +6.30 |
| t6000.xxxl | 65.246 | **80.533** | +15.29 |
| t7000.xxxl | 99.109 | 99.190 | +0.08 |
| t8000.xxxl | 99.090 | 99.172 | +0.08 |
| t9000.xxxl | 99.080 | 99.161 | +0.08 |
| t10000.xxxl | 65.246 | **80.540** | +15.29 |
| t11000.xxxl | 58.539 | **71.181** | +12.64 |
| t12000.xxxl | 66.772 | 70.520 | +3.75 |
| t200.landscape | 76.049 | **85.868** | +9.82 |
| t1200.landscape | 94.611 | 94.675 | +0.06 |
| t2100.landscape | 94.303 | 94.189 | −0.11 |
| t3000.landscape | 75.950 | **85.657** | +9.71 |
| t4000.landscape | 76.378 | **85.984** | +9.61 |
| t5000.landscape | 86.188 | 86.597 | +0.41 |
| t6000.landscape | 56.482 | **71.946** | +15.46 |
| t7000.landscape | 96.668 | 97.016 | +0.35 |
| t8000.landscape | 96.648 | 96.998 | +0.35 |
| t9000.landscape | 96.637 | 96.988 | +0.35 |
| t10000.landscape | 56.440 | **71.900** | +15.46 |
| t11000.landscape | 66.879 | **76.480** | +9.60 |
| t12000.landscape | 60.411 | 64.554 | +4.14 |
| Notes-ipad:t200 | 97.729 | 97.729 | 0 |
| Notes-ipad:t1200 | 98.056 | 98.056 | 0 |
| Notes-ipad:t2100 | 95.488 | 95.488 | 0 |
| Notes-ipad:t3000 | 97.729 | 97.729 | 0 |
| Notes-ipad:t4000 | 99.462 | 99.462 | 0 |
| Notes-ipad:t5000 | 99.660 | 99.660 | 0 |
| Notes-ipad:t6000 | 97.617 | 97.617 | 0 |
| Notes-ipad:t7000 | 98.702 | 98.702 | 0 |
| Notes-ipad:t8000 | 98.799 | 98.799 | 0 |
| Notes-ipad:t9000 | 98.796 | 98.796 | 0 |
| Notes-ipad:t10000 | 96.114 | 96.114 | 0 |
| Notes-ipad:t11000 | 97.567 | 97.567 | 0 |
| Notes-ipad:t12000 | 97.751 | 97.751 | 0 |

t2100.landscape −0.11 is the keyboard glyph class (`scoreboard/open.txt`); the
compact 64 pt tab bar reveals 19 pt of the same panel. t5000.rtl held above
97.5 after the RTL trailing-8 fix (97.406 with physical-right-only had
dropped it).

## Other apps (must not drop)

Tabs default: t200 **96.657** (r18 96.66), t6000 **89.519** (87.50; inactive
slot now matches inset 124), t7000 **96.600** held. Tabs landscape: t200
**97.476** (95.88), t1000 **98.716** (97.20), t3000 **97.795** (96.10),
t6000 **83.806** (82.52), t7000 **96.985** (95.38). t2000.landscape **77.893**
vs 78.05: blob 364.5 → **22.5**; leftover is Tabs-t2000-scroll-glass over
the newly exposed 19 pt (correct 64 vs wrong 83). Ledger / Forms / NavFlow
not re-run; their compact-header / no-tab-bar samples are the 55.5 class
the new guard leaves alone.

## OPEN

- **Notes-trash-bar-symbol** — `_BarSymbol` vs SF `trash`, blob 111 at
  `[326.5, 19, 21, 23]` (landscape `[619.5, 35.5, 20, 22]`).
- **Notes-t12000-delete-animation** — golden header 38 mid-flight vs rest 55.5.
- **Keyboard** — t2100 family, already in open.txt.
- **t11000.ax1** 55.123 — search slot now 150/96; leftover is
  Modal-t5200-ax1-header-slack (card 369 vs 280.5).
- **ax1/xxxl cell content 307 vs 316.5** — larger accessory at accessibility
  sizes; not fitted (would need a dyntype chevron sample).
- Landscape "All Notes" x 40 vs 36 — same 4 pt as NavFlow grouped 36 vs 40
  (`conf-landscape.md` OPEN).

Closed vs prior open.txt: Notes-t200-ax1-first-header (now compact 38 at
SA.top 64), Notes-t11000-ax1-search-stays-active (bar 150 matches).

## Gates

Catalyst **124/124**. iOS suite **112/113** (`corner_radius`). Real-app floors
held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 /
82.170 / 99.860 / 99.734 / 85.393** (ledger / focus-home goldens absent from
`/tmp/golden_realapp_ios`). Linux `swift:6.2-noble` openrender green. No
`Package.resolved`.
