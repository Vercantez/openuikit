# Tabs fidelity 2 — bottom ScrollEdgeEffectView (dark pocket)

Round-20 board (main e6f52739, first pass `docs/agent_reports/tabs-fidelity.md`):
39 Tabs rows below 97.5. t2000 was identical ~84.6 on light/rtl/ax1/xxxl
(78.0 landscape) — one structural miss. t6000 was search leftover
(landscape 84.1, ax1 84.9, xxxl 87.5, light/rtl 89.5), not a More tab.

Goldens `/tmp/hc-conformance-Tabs[-axis]/golden`, replayed
`SKIP_CAPTURE=1` into `/tmp/conformance-Tabs[-axis]`. Device iPhone SE 2x
/ iOS 26.1. Notes canary against `/tmp/hc-conformance-Notes[-dark]`.

## What the dumps said (t2000)

Portrait light (Scroll selected):

- `UITabBar [0, 584, 375, 83]`, platter `[51, 584, 274, 62]` — already
  matched. Largest wrong region was `[24, 637, 14.5, 14]` **left of the
  platter**, over the yellow scroll block.
- Bottom `ScrollEdgeEffectView [0, 519.2, 375, 147.8]` = bar 83 + **64.8**.
  `PocketBlur` hidden. `BackdropView` white **α=0.85**.
- x=30 (left of platter) over yellow (242,179,64): mix toward T=247,
  plateau α≈0.835 at y=644 → (247,236,216). Platter interior is glass
  (255,244,207), not that wash.

Compact t2000.landscape: pocket `[0, 246.2, 667, 128.8]` = 64 + 64.8.
BackdropView **α=0** / `popacity` 0.151. A T=82 invert of red at x=30 is
glass-over-content, not this pocket.

Dark: BackdropView α=0.6 white, but x=30 yellow → (97,71,26) at y=644,
ratio 0.40 on all three channels (α=0.598 toward **black**). Visible is
LuminanceAdjustment, not the white fill.

t6000: after Notes' inactive-search-slot rule the 60 pt slot already
matches (bar 114 / inset 124; ax1 bar 150 / field 96). Leftover is
`Search` abs.w 55 vs 303.5 (ax1 x 74 vs 55.5, w 102.5 vs 303.5). Golden
still has 1 view animating 0.6 s after cancel. Not More.

## Rule (iOS cut, phone, not pad)

Guard: `UITabBar.isIOS && !isPad`. Overlay parented on the tab bar
(window frame = dump) so table `retile()` cannot cover it. Not a
`UIGradientView` (quartz would skip `drawContent` and the platter hole).
Platter AABB punched out so glass still samples unwashed content.

1. Overshoot **64.8**. Portrait overlay `[0, −64.8, W, barHeight+64.8]`.
2. **Light paints nothing.** T=247 (yellow invert) dropped Notes t5000
   **98.818 → 97.237** (pass→fail). T=255 (dump BackdropView white)
   dropped it to **92.007** and Notes t7000 **99.192 → 92.381**. No
   single T fits yellow scroll blocks and grouped cards.
3. **Compact paints nothing.** BackdropView α=0. Painting T=82 dropped
   t200.landscape **97.70 → 80.47**.
4. **Dark** multiplies toward black with the x=30 stop table (plateau
   α=0.598). Notes t5000.dark **98.221** / t7000.dark **97.856** held.

Cited: Tabs t2000 / t2000.dark / t2000.landscape, Notes t5000, iPhone SE
2x / iOS 26.1.

## After (`SKIP_CAPTURE=1`, round-20 goldens)

Light / rtl / ax1 / xxxl / landscape / iPad: **identical** to round-20
(light and compact pockets paint nothing). Dark:

| capture | before | after | blob before → after |
|---|---|---|---|
| t200.dark | 97.317 | 97.472 | 40.8 → 19.0 |
| t1000.dark | 98.786 | 98.786 | 15.2 hold |
| t2000.dark | 84.855 | **93.203** | 8.0 → 8.0 |
| t3000.dark | 97.553 | **97.708** | 40.8 → 19.0 |
| t4000.dark | 92.353 | 92.361 | keyboard |
| t5000.dark | 92.416 | 92.420 | keyboard |
| t6000.dark | 92.096 | 92.135 | cancel-slot |
| t7000.dark | 97.193 | 97.289 | 46.8 hold |

Notes light byte-held (t5000 **98.818**, t7000 **99.192**). Notes dark
passes held; some failing rows rose (t200.dark 87.204 → 91.763). No
board pass became a fail.

## Every Tabs row (before = round-20 `/tmp/hc-conformance-Tabs*`)

| row | before | after |
|---|---|---|
| t200 | 96.657 | 96.657 |
| t1000 | 99.402 | 99.402 |
| t2000 | 84.631 | 84.631 |
| t3000 | 96.898 | 96.898 |
| t4000 | 95.006 | 95.006 |
| t5000 | 93.709 | 93.709 |
| t6000 | 89.519 | 89.519 |
| t7000 | 96.600 | 96.600 |
| t200.dark | 97.317 | **97.472** |
| t1000.dark | 98.786 | 98.786 |
| t2000.dark | 84.855 | **93.203** |
| t3000.dark | 97.553 | **97.708** |
| t4000.dark | 92.353 | 92.361 |
| t5000.dark | 92.416 | 92.420 |
| t6000.dark | 92.096 | 92.135 |
| t7000.dark | 97.193 | **97.289** |
| t200.rtl | 96.671 | 96.671 |
| t1000.rtl | 99.091 | 99.091 |
| t2000.rtl | 84.622 | 84.622 |
| t3000.rtl | 96.912 | 96.912 |
| t4000.rtl | 94.789 | 94.789 |
| t5000.rtl | 93.573 | 93.573 |
| t6000.rtl | 89.534 | 89.534 |
| t7000.rtl | 96.610 | 96.610 |
| t200.ax1 | 96.541 | 96.541 |
| t1000.ax1 | 99.043 | 99.043 |
| t2000.ax1 | 84.634 | 84.634 |
| t3000.ax1 | 96.739 | 96.739 |
| t4000.ax1 | 92.822 | 92.822 |
| t5000.ax1 | 90.967 | 90.967 |
| t6000.ax1 | 84.882 | 84.882 |
| t7000.ax1 | 95.973 | 95.973 |
| t200.xxxl | 96.419 | 96.419 |
| t1000.xxxl | 99.043 | 99.043 |
| t2000.xxxl | 84.634 | 84.634 |
| t3000.xxxl | 96.634 | 96.634 |
| t4000.xxxl | 94.836 | 94.836 |
| t5000.xxxl | 93.327 | 93.327 |
| t6000.xxxl | 87.504 | 87.504 |
| t7000.xxxl | 96.169 | 96.169 |
| t200.landscape | 97.704 | 97.751 |
| t1000.landscape | 99.019 | 99.019 |
| t2000.landscape | 78.049 | 78.049 |
| t3000.landscape | 98.082 | 98.082 |
| t4000.landscape | 94.962 | 94.962 |
| t5000.landscape | 93.888 | 93.888 |
| t6000.landscape | 84.090 | 84.090 |
| t7000.landscape | 97.270 | 97.270 |
| Tabs-ipad t200 | 98.621 | 98.621 |
| Tabs-ipad t1000 | 99.208 | 99.208 |
| Tabs-ipad t2000 | 98.657 | 98.657 |
| Tabs-ipad t3000 | 98.072 | 98.072 |
| Tabs-ipad t4000 | 96.101 | 96.101 |
| Tabs-ipad t5000 | 96.254 | 96.254 |
| Tabs-ipad t6000 | 98.603 | 98.603 |
| Tabs-ipad t7000 | 98.365 | 98.365 |

t200.landscape +0.047 is the transparent overlay in the tree (still a
pass). Light t2000 family did not move.

## OPEN (not modelled)

- Light t2000 glass over scroll blocks (`Tabs-t2000-scroll-glass`).
  Side wash at x=30 is the pocket; platter interior is `_UIGlassMaterial`
  chroma (golden [255,239,180] vs ours [248,241,228]). T=247 and T=255
  both fail the Notes t5000 sample. Landscape t2000 **78.049** is the
  same glass with compact BackdropView α=0 (`Tabs-t2000-landscape-glass`).
- t6000 family: 0.6 s after cancel, 1 view animating, `Search` abs.w 55
  vs 303.5 (`Tabs-t6000-cancel-inset`, `Tabs-t6000-ax1-search-below-bar`).
  Slot layout already matches.
- t4000 / t5000 keyboard glyphs (Forms-keyboard-letter-caps).
- t200.dark **97.472** / t7000.dark **97.289** / t7000.landscape **97.270**
  still under 97.5 after the dark pocket (nav-bar / badge leftovers).

## Gates

- Catalyst `openrender render` + `compare.py`: **124/124**
- iOS suite `SKIP_CAPTURE=1 scripts/ios_suite.sh /tmp/suite-tabs-fidelity2`: **112/113**, miss is the known `corner_radius` (99.411)
- Real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393** (`/tmp/golden_realapp_ios` has no ledger/focus-home PNGs; those screens rendered)
- `swift test --filter testTabBarBottomScrollEdgeEffectMatchesDump` (portrait `[0, −64.8, 375, 147.8]`, compact `[0, −64.8, 667, 128.8]`, light/compact α=0)
- Linux `swift:6.2-noble` `openrender` release build green
- No `Package.resolved`
