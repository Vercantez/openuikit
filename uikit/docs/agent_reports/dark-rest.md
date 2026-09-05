# Dark rest: TableEditor, Feed, Tabs, Pager on the SE 2x

NavFlow / Modal / Forms dark already landed (`conf-dark.md`). This round
runs the other four on iPhone SE 2x / iOS 26.1, reads frames before
pixels, and closes the measured dark colour gaps under the iOS cut.

Goldens: existing `/tmp/hc-conformance-<App>-dark` (SE 2x / iOS 26.1,
one confprobe process per sheet/alert). Iterated with
`SKIP_CAPTURE=1 scripts/conformance_flow.sh /tmp/flow-dark-rest-<App>
<App> --dark`. Probe family in `/tmp/glass-dark-probe` (not in the repo).

## Before

| app | worst | mean | largest miss |
|---|---|---|---|
| TableEditor | **96.470** t2350.dark | 97.530 | blob 22.2 at reorder bars |
| Feed | **89.434** t3800.dark | 94.420 | blob **13656** at the collapsed pocket `[0,0,375,37.5]` |
| Tabs | **84.907** t2000.dark | 92.655 | blob 272 at the tab-bar platter over Scroll yellow |
| Pager | **99.723** t1800/t4650 | 99.789 | already green; spinner core 1 count off |

Separators in TableEditor already match `(42,42,44)` = `separator` @0.5
over black. Selection already matches `(58,58,60)` = `systemGray4`.
Feed selected cards already match `systemGray4`. Pager page-control
inactive `(51,51,51)` / current `(191,191,191)` already match. Those
were not modelled.

## Measurements

### TableEditor — reorder ink is `.tertiaryLabel`

Glyph `[332, cellY+24, 27, 15]`, mid-bar 1.5 pt strip (SE 2x):

| capture | backdrop | golden ink | previous opaque 197 |
|---|---|---|---|
| t900.dark Alpha | black | **(70, 70, 73)** n=203 | (197, 197, 199) |
| t3800.dark Delta | selected `(58,58,60)` | **(111, 111, 115)** n=203 | (197, 197, 199) |
| light t900 | white | **(197, 197, 199)** | same |
| light t3800 | selected `(209,209,214)` | **(165, 165, 170)** | (197, 197, 199) |

All four are `UIColor.tertiaryLabel` source-over (iOS table
`(0.921569, 0.921569, 0.960784, 0.298039)` dark;
`(0.235294, 0.235294, 0.262745, 0.298039)` light). Catalyst keeps the
opaque (197, 197, 199). Guard `UITableView.isIOSChrome`.

### Feed — pocket fallback is `.systemBackground`

t2800/t3800/t4800.dark top strip y=8–12: golden `(0,0,0)` vs ours
`(209–230)`. Cause: `UINavigationBar.updatePocket` washed toward
`(backgroundColorForPocket ?? .white)`. On iOS the nav container is
`backgroundColor = nil`, so the fallback fired. Light `.systemBackground`
is white (Feed t2800 **99.042** unchanged). Dark is black.

### Tabs — dark bar glass, not the sheet mix

Probe `/tmp/glass-dark-out` `glass_{tabbar,toolbar}_dark_{black,white,gray33,red}`,
SE 2x / iOS 26.1, glyph-free interiors (tab left of selected; toolbar
below the title). One SimScene process (not a sheet/alert).

| backdrop | tab unselected | toolbar interior | selected tab |
|---|---|---|---|
| black `(0,0,0)` | **(19, 19, 19)** | **(19, 19, 19)** | **(53, 53, 53)** |
| gray33 `(51,51,51)` | **(32, 32, 32)** | **(32, 32, 32)** | **(65, 65, 65)** |
| white `(255,255,255)` | **(84, 83, 83)** | **(84, 83, 83)** | **(115, 114, 114)** |
| systemRed `(255,56,60)` | **(157, 13, 16)** | **(157, 13, 16)** | **(203, 42, 45)** |

Gray samples fit `out = (65/255)·B + 19`, i.e. **α = 190/255**,
**T = 19/190**, same σ=2.25 as light. Not the sheet mix (57 over black,
α=203/255). Red residual pred (84, 33, 34) vs (157, 13, 16) reported,
not fitted (same class as the light red residual).

Selected capsule is white-over-glass: black 19→53 ⇒ **34/236**. gray33
pred 64.1 vs 65. White residual 108.6 vs 115 reported.

Wiring: `_usesIOSDarkBarGlass` on the tab platter and on toolbar item
platters (`appliesRefraction == false`). Nav-bar platters keep the
measured dark flats + refraction (`navitem_dark` 25).

Tabs t200.dark unselected 25 / selected 58 are this mix over the table
(not uniform black). After the mix, t1000.dark Left interior **19**
(was 25). t2000.dark unselected over yellow `(231,171,61)` is ours
`(75,60,34)` vs golden `(166,114,21)` — the chroma residual; score
stays 84.907, blob **271.8 → 8.0**. Written up in `scoreboard/open.txt`.

### Pager — iOS dark spinner invert

Pager t200.dark `UIActivityIndicatorView` `[32, 408, 37, 37]`, 9 o'clock
core at blade α=217/255: golden **(120, 120, 125)** vs previous
**(119, 119, 119)**. Invert (same method as light (156,156,159) over
white → (139,139,142)): **(141, 141, 147)**. After: ours (119, 119, 125).
t1800.dark blob 127 at `[93.5, 0, 0.5, 254]` is a 0.5 pt page-transition
hairline (layout `One` abs.x golden=−124.5 / ours=157) — same family as
light pager-clock, not a dark colour.

`Tools/oracle2/colorprobe` already has `tertiaryLabel` / `secondaryLabel`
/ `separator` in the dark table. No new semantic was missing.

## After (SKIP_CAPTURE=1, SE 2x goldens)

| app | capture | before | after |
|---|---|---|---|
| TableEditor | t2350.dark | 96.470 blob 22.2 | **96.722** blob **12.0** (now the 0.5 pt title stem) |
| TableEditor | t900.dark | 97.304 | **97.418** (bars now (70,70,73)) |
| TableEditor | mean | 97.530 | **97.632** |
| Feed | t3800.dark | 89.434 blob 13656 | **98.699** blob **3.8** |
| Feed | t2800.dark | 89.435 | **98.701** (y=8 both (0,0,0)) |
| Feed | mean | 94.420 | **99.052** |
| Tabs | t2000.dark | 84.907 blob 272 | 84.907 blob **8.0** (chroma residual) |
| Tabs | t1000.dark | 98.799 | **98.784** (Left interior 25→**19**) |
| Tabs | t200.dark | 93.901 | **93.920** |
| Tabs | mean | 92.655 | **92.667** |
| Pager | t200.dark | (in the 99.8 cluster) | **99.819** blob 0; 9 o'clock (119,119,125) |
| Pager | mean | 99.789 | **99.791** worst **99.721** |

Light TableEditor mean 98.784→98.785 (t3800 98.951→**98.963**, selected
handles now 165). Light Feed 99.319 / t2800 99.042 unchanged. Light Tabs
mean **92.180** byte-score identical. Dark NavFlow mean **99.030** identical.
Dark Forms 97.635→97.637. Dark Modal 98.827→98.826.

## Open (not modelled)

- Dark tab-bar / toolbar red/yellow chroma (Tabs t2000.dark 84.907).
  Gray mix is the two-unknown fit; a third saturation unknown would
  close it. `scoreboard/open.txt` `Tabs-t2000-dark-bar-chroma`.
- TableEditor remaining 0.5 pt large-title stem `[133.5, 76.0, 0.5, 24.0]`
  and mid-flight spring (same class as light).
- Pager t1800.dark 0.5 pt page-transition hairline (pager-clock).
- Tabs 52 vs 53 row stride (already OPEN).

## Gates

Catalyst **124/124**. iOS suite **112/113** (known `corner_radius` 99.411).
Real-app floors held: 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 /
97.516 / 99.511 / 82.192 / 99.760 / 99.689 / 84.582. Linux `swift:6.2-noble`
openrender green. No `Package.resolved`.
