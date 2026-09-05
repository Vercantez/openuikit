# Tabs search slot — 60 pt stacked bar after cancel

Tabs t6000 (cancel-search) and t7000 (scroll-200) against real iOS 26.1
on the iPhone SE 2x. The 60 pt search slot under the navigation bar
(`hidesSearchBarWhenScrolling`) was measured by the tabs-rows pass and
not modelled: after cancel the table inset is 124 vs the port's 64, and
after `setContentOffset(200)` the offset is 260 vs 200.

`scripts/conformance_flow.sh /tmp/conformance-Tabs Tabs` (goldens reused
with `SKIP_CAPTURE=1`). Device `OpenUIKit-2x-tabs-search-slot`. Probe
kept in `/tmp/tabs-search-slot-probe` (not the repo).

## Before (scoreboard a72089b2)

| capture | pixels | blob | layout | meaning |
|---|---|---|---|---|
| t200 | 93.188 | 79.5 | 28 | tab 1 rest |
| t1000 | 99.402 | 31.2 | 21 | tab 2 toolbar |
| t2000 | 84.641 | 127.0 | 7 | tab 3 scroll |
| t3000 | 93.428 | 79.5 | 28 | back to tab 1 |
| t4000 | 92.914 | 79.5 | 33 | focus-search |
| t5000 | 93.135 | 79.5 | 34 | type-search |
| t6000 | **88.371** | 79.5 | 28 | cancel-search |
| t7000 | **92.375** | 47.2 | 32 | scroll-200 |

t6000 Row 1 abs.y golden **124** vs ours 64. t7000 table
`contentOffset.y` golden **260** vs ours 200.

## Probe (SE 2x)

`/tmp/tabs-search-slot-probe` — `UITabBarController` whose first tab is a
`UINavigationController` with `UISearchController` on the root over a
30-row plain table. Four configs: `hidesSearchBarWhenScrolling` ×
`prefersLargeTitles`. Window SA `[0,0,0,0]`. A bare nav (no tab bar)
takes a different presentation path (bar height 0 while active) and was
not used for the rule.

hide=true, large=false (Tabs):

| state | nav bar | search bar | adj.top | offset |
|---|---|---|---|---|
| rest (never activated) | `[0,10,375,54]` | `[0,54,375,0]` | 64 | −64 |
| `isActive = true` | `[0,10,375,60]` | fills `[0,0,375,60]` | 70 | −70 |
| after cancel | `[0,10,375,114]` | `[0,54,375,60]` | **124** | **−124** |
| `setContentOffset(200)` | `[0,10,375,54]` | `[0,54,375,0]` | 64 | **260** |
| never-activated scroll-200 | `[0,10,375,54]` | height 0 | 64 | 200 (no rebase) |

hide=false, large=false: slot is 60 at rest without activating; scroll-200
keeps the slot and offset **200** (no collapse, no rebase).

Active search is bar height 60 with large titles on or off. After cancel
with large titles the slot sits under the 106 pt overlay (bar 166, adj
176); hide-on-scroll then collapses both (offset 200 → 312 = 200+52+60).

## Rule

Guarded by `OpenUIKitRuntime.systemFontCut == .iOS`.

1. **Stacked slot is 60 pt** after the first active→inactive, or always
   when `hidesSearchBarWhenScrolling` is false. Never-activated rest with
   the hide default stays 0 (Tabs t200). Bar height = 54 + slot (114);
   table `safeAreaInsets.top` / `adjustedContentInset.top` = 124; rest
   offset −124. Search bar frame `[0, 54, W, 60]`; field `[16, 1, W−32, 44]`.
2. **Hide-on-scroll** (already the 8 pt threshold) zeros the slot. The
   Feed safe-area rebase (`contentOffset.y += previous − new` when
   `safeAreaInsets.top` shrinks) lands `setContentOffset(200)` on **260**.
   hide=false does not shrink, offset stays 200.
3. **Active search** still +6 (bar 60) and suppresses large titles.
   Inactive slot adds 60 under the current title overlay (large 106+60=166).
4. **Stacked pill** is field-centre **(236, 236, 236)** with no drop
   shadow (Tabs t6000); standalone/inline keep 253 glass.

Catalyst `searchOverlayHeight` stays 0.

## After (`SKIP_CAPTURE=1`, same goldens)

| capture | before | after | blob | notes |
|---|---|---|---|---|
| t200 | 93.188 | 93.188 | 79.5 | unchanged; slot still 0 |
| t1000 | 99.402 | 99.402 | 31.2 | unchanged |
| t2000 | 84.641 | 84.643 | 127.8 | +0.002 |
| t3000 | 93.428 | 93.429 | 79.5 | +0.001 |
| t4000 | 92.914 | 92.914 | 79.5 | unchanged (inline search) |
| t5000 | 93.135 | 93.135 | 79.5 | unchanged |
| t6000 | 88.371 | **93.944** | 79.5 | +5.573; Row 1 y 64→**124**; bar 114; field 236 |
| t7000 | 92.375 | **92.512** | 93.0 | +0.137; offset 200→**260** |

Mean **92.174 → 92.896**. No capture dropped. t6000/t7000 chrome frames
now match the golden (bar 114/54, search 60/0, adj 124/64, offset −124/260).
Neither is above 97.5: the remaining floor is classic row height **52 vs
53** (`scoreboard/open.txt`), which also leaves t200 at 93.188.

## OPEN (not modelled)

- Classic `.default` `textLabel` rows are 52 pt (Tabs) vs
  `defaultRowHeight` 53 (content-configuration fixtures / Focus). Same
  discriminator gap as tabs-cells.
- hide=false + large titles at *initial* rest was only sampled after
  flipping `hidesSearchBarWhenScrolling` post-attach (bar 114). After
  cancel the additive 106+60=166 is the measured stacked+large rest.
- A nav that is not inside a `UITabBarController` hides the bar while
  search is active (probe bar height 0, keyboard inset 260). The port
  always inlines; Tabs is the tab-hosted path.
- Keyboard remains a separate `UITextEffectsWindow` when `isActive =
  true` without `becomeFirstResponder` on the field (bottom inset 83).

## Gates

- Catalyst **124/124**
- iOS suite **112/113** (known miss `corner_radius` 99.411)
- Real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.192 / 99.760 / 99.689 / 84.582**
- Linux `swift:6.2-noble` `openrender` green
- `swift test --filter UISearchControllerTests` 11/11
