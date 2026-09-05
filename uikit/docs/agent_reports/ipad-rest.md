# iPad rest (Forms, Feed, Tabs, Pager)

`--ipad` on `scripts/conformance_flow.sh` captures on a private **iPad (A16)**
(820×1180 @2x portrait, `SIM_DEVICE_SUFFIX=-ipad-rest`) and openhost renders
with idiom `.pad`, that window size, and window SA `[32, 0, 25, 0]`. Work
dirs: `/tmp/hc-conformance-{Forms,Feed,Tabs,Pager}-ipad`. Phone ConfProbe
still hides the status bar; the iPad plist leaves it visible so SA is 32/25.
Device `OpenUIKit-iPad-A16-ipad-rest` only.

NavFlow / TableEditor / Modal iPad captures were already closed
(`docs/agent_reports/conf-ipad.md`) and must not move.

## Baseline (first capture, phone chrome on the pad window)

| app | worst | mean | notes |
|---|---|---|---|
| Forms-ipad | **99.204** | 99.214 | 24 layout issues; labels x 16 vs 20; t1200 table `aci.bottom` **285** vs golden **337** |
| Feed-ipad | **8.921** | 24.912 | cards **358×291.5** vs golden **788×533.5** |
| Tabs-ipad | **45.747** | 88.306 | tab bar at bottom y=1097 vs `_UIFloatingTabBar [0, 32, 820, 44]` |
| Pager-ipad | **98.331** | 99.776 | rest already matched; mid-flight page-next/fling off |

## Forms

### Rule 1 — pad keyboard overlap is 312

MEASURED Forms-ipad t1200, iPad (A16) 820×1180 @2x / iOS 26.1.

Window SA `[32, 0, 25, 0]`. Rest table `adjustedContentInset [86, 0, 25, 0]`.
Focused name field: golden `aci.bottom` **337**. Phone overlap is 260
(337 would be 260+25=285 if we added SA). Overlap = 337 − 25 = **312**.

`UIScrollView.iOSKeyboardOverlap` is a computed var: pad+iOS **312**, else
**260**. Guard idiom `.pad` under the iOS cut. Phone Forms t1200 stays 260.

After SKIP_CAPTURE=1, t1200 table `aci [86, 0, 337, 0]` both sides.

### OPEN — grouped `layoutMarginsGuide` x=20 vs storage 16

Forms-ipad t200: text field / segmented abs.x **20**, width 780
(`820 − 20 − 20`). Storage xib `SwitchCell.layoutMargins` **`[15, 16, 15, 16]`**,
switch at x 741 = 820 − 16 − 63. Setting `_defaultBaseLayoutMargins` to 20
on pad closed Forms (mean 99.214 → **99.659**, blob 97 → 17.8) and dropped
`realapp_storage_light_ipad` **99.689 → 99.554**. Two samples disagree; the
xib oracle keeps 16 (`iOSPadCellMargin`). Forms x=20 stays OPEN
(`scoreboard/open.txt`). Leftover compact date chrome (`Sep 4, 2026` inner
label 93.5×20 at y=7 vs the 117.5×34 capsule) is the same phone structure.

## Feed

### Rule 1 — compositional `shouldInvalidateLayout` uses last prepared size

MEASURED Feed-ipad t200, iPad (A16) 820×1180 @2x / iOS 26.1.

Collection view abs `[0, 0, 820, 1180]` both sides. Cards golden
`[16, 298, 788, 533.5]` vs ours `[16, 298, 358, 291.5]`. 358 = 390 − 32
(section insets); 390 is `UIViewController.loadView` default. The bounds
setter asks `shouldInvalidateLayout` **after** applying the new size, so
comparing `newBounds` to `cv.bounds` is always false.

iOS-cut `shouldInvalidateLayout` compares `newBounds.size` to
`preparedBoundsSize` (set in `prepare()`), same trap flow layout avoids
with `preparedCrossExtent`. Catalyst keeps the `cv.bounds` compare. Phone
Feed already prepares at 375.

After: t200 / t1800 **99.874** blob 0; t700 **99.818**.

### OPEN — t2800/t3800/t4800 top 31.5 pt strip

Offset **352** both sides; cards 788×533.5 both sides. Blob ~25k at
`[17, 0, 786, 31.5]`. Golden `ScrollEdgeEffectView [0, 0, 820, 140.8]`
(phone Feed was `[0, 0, 375, 118.8]` = bar.y 10 + 108.8; pad 32 + 108.8).
The port's pocket is 72 pt from container origin. Status bar is visible on
this plist. Not modelled: a pad-only pocket height would be a second
unmeasured constant. Golden still dumps offscreen story cell "A"; we cull
it. `scoreboard/open.txt`.

## Tabs

### Rule 1 — pad tab bar is a 44 pt top strip

MEASURED Tabs-ipad t200, iPad (A16) 820×1180 @2x / iOS 26.1.

`_UIFloatingTabBar [0, 32, 820, 44]` at window SA.top, not the phone bottom
bar `[0, 1097, 820, 83]`. Items are title-only 36 pt pills packed by
intrinsic width + 16 pt insets (Library 87 / Tools 73.5 / Scroll 76.5) and
centred: x0 = (820 − 237) / 2 = **291.5**. Badge **18.5×18.5**. Transition
view SA `[32, 0, 25, 0]` (window SA; bottom is **25**, not 83). A non-nav
child starts at y **96** = 32 + 44 + 20 (t1000 toolbar / t2000 scroll).

Guards `UITabBar.isPad`. Phone keeps the 83 pt bottom bar. The pad platter
is **clear** (selection container is 245×44 around the titles, not a
full-width fill) so the trailing search in the nav bar shows through.

### Rule 2 — pad hosted search is trailing 240 / 280 × 44

MEASURED Tabs-ipad t200 / t4000.

Rest `UISearchBar` abs `[564.969, 31.817, 240, 44]` (trailing inset
**15** = 820 − 240 − 565); field fills the bar; placeholder at x 39.5.
Active **280** wide at `[524.802, 31.817, 280, 44]` (same trailing 15).
Nav bar stays **54** (no +6 overlay). Inline title is gone — the floating
tab bar carries it. Active: `_UIFloatingTabBar [0, -32, 820, 44]`
(y = −SA.top).

`UINavigationBar.searchOverlayHeight` is 0 on pad. `layoutSearchBar` places
the 240/280 field at y 0 in the bar. `layoutTabBarFrame` hides the bar to
−SA.top while search is active.

After SKIP_CAPTURE=1: t2000 **45.747 → 98.657**; mean **88.306 → 96.190**.
Remaining: classic row 52 vs 53 (same phone OPEN); item title widths ~1 pt.

## Pager

Rest already matched: page control `[373, 254, 74, 26]`, cards
`[310, 296, 200, 88]`. t200 **99.975** blob 0.

### OPEN — mid-flight page-next is finished on the port

MEASURED Pager-ipad t500 / t600 / t1800. `_UIQueuingScrollView` width 820.

Golden page-next from offset 820 → 1640: t500 n=6 **1025** (0.25 of 820),
t600 n=12 **1493.5**. Ours is already **1640**. Page-previous t1800 golden
**550**, ours **0**. Same cosine as phone; the pad presentation is not
interpolating at the named frames. An attempted `layoutPageHierarchy` skip
while `pendingDirection != nil` mixed scores (t1900 better, t1800 worse)
and was reverted. `scoreboard/open.txt`.

Fling t3133/t3267 leftover blobs 58.5 / 68.0 at the 820 pt width.

## After (SKIP_CAPTURE=1, same goldens)

| app | before worst / mean | after worst / mean |
|---|---|---|
| Forms-ipad | 99.204 / 99.214 | **99.204 / 99.214** (keyboard aci closed; x=20 OPEN) |
| Feed-ipad | 8.921 / 24.912 | **91.787 / 95.825** (rest 99.87; t2800 strip OPEN) |
| Tabs-ipad | 45.747 / 88.306 | **94.223 / 96.190** |
| Pager-ipad | 98.331 / 99.776 | **98.167 / 99.664** (rest 99.97; mid-flight OPEN) |

NavFlow-ipad mean **99.194** worst 98.461; TableEditor-ipad **99.399** /
98.855; Modal-ipad **98.205** / 84.245 — unchanged from conf-ipad.

Phone Forms 98.895 / 98.933; Feed 99.038 / 99.319; Tabs 84.630 / 92.180;
Pager 99.745 / 99.856 — none dropped.

Catalyst **124/124**. Suite 112/113 (known `corner_radius` 99.411). Real app
**99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 /
82.192 / 99.760 / 99.689 / 84.582**. Linux `swift:6.2-noble` openrender
green.
