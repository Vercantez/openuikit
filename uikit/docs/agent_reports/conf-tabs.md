# Tabs conformance app — search-in-navbar + tab-bar badge

Sixth conformance app `Sources/ConformanceApps/Tabs/`. Same UIKit source
compiles against real UIKit (`Tools/oracle2/confprobe`, iPhone SE 2x /
iOS 26.1, window SA `[0,0,0,0]`) and OpenUIKit (`openhost --app Tabs`).
`scripts/conformance_flow.sh /tmp/conformance-Tabs Tabs`.

Three tabs: Search (nav + `UISearchController` over a 30-row plain table),
Tools (toolbar + `UIButton.menu` / `showsMenuAsPrimaryAction`, badge `"3"`),
Scroll (eight 120 pt blocks). Script: select-tab-2/3/1, focus-search,
type-search, cancel-search, scroll-200. `show-menu` is implemented but not
in the script — a presented menu hangs on the window.

## Baseline (first capture, before the two rules)

| capture | pixels | blob | layout | meaning |
|---|---|---|---|---|
| t200 | 90.972 | 232.5 | 46 | tab 1 rest |
| t1000 | 97.693 | 234.8 | 23 | tab 2 toolbar |
| t2000 | **84.481** | **406.5** | 11 | tab 3 scroll |
| t3000 | 91.244 | 232.5 | 46 | back to tab 1 |
| t4000 | 92.446 | 232.5 | 52 | focus-search |
| t5000 | 92.646 | 232.5 | 48 | type-search |
| t6000 | 86.594 | 232.5 | 44 | cancel-search |
| t7000 | 92.180 | 232.5 | 51 | scroll-200 |

Mean **91.032**, worst **84.481**. Tab bar height was already 83
(`[0, 584, 375, 83]`); toolbar labels already sat at y=14. The two
largest measured gaps were the **hosted search slot** (port added 56 pt
under the 54 pt bar) and the **badge** (wrong size/origin; t2000 blob
406.5).

## Rule 1 — hosted search is 0 pt at rest, +6 pt when active

MEASURED Tabs t200 / t4000, iPhone SE 2x / iOS 26.1:

- Rest: `UINavigationBar [0, 10, 375, 54]`; `UISearchBar [0, 64, 375, 0]`;
  table `abs [0, 64, 375, 667]`, SA `[64, 0, 83, 0]`, offset `(0, −64)`.
- Active: bar **`[0, 10, 375, 60]`** (+6); search fills the bar; field
  **`[16, 18, 288, 44]`** (bar-local y 8); dismiss **`[315, 18, 44, 44]`**
  r=17, empty title, 22.5×21.5 image (not "Cancel"); table SA top **70**.
- Keyboard is a separate window: `adjustedContentInset.bottom` stays **83**,
  not the Forms 260 pt overlap. iOS-cut
  `UIScrollView.iOSKeyboardAvoidanceBottom` therefore returns 0 when the
  responder is not inside this scroll view.

Guarded by `OpenUIKitRuntime.systemFontCut == .iOS`. Catalyst search bars
are standalone and unchanged.

## Rule 2 — tab-bar badge is 20×20 at iconCenterX+8.5, y=6

MEASURED Tabs t200, iPhone SE 2x / iOS 26.1:

- `_UIBarBadgeView [196.5, 590, 20, 20]`, r=10, fill **(255, 56, 60)**
  (same captured sRGB as the table delete-control / `systemRed` in confprobe).
- Digit `"3"`: 13 pt regular, label `[200.5, 592, 12, 16]` (badge-local
  `[4, 2]`).
- Origin vs icon centre in the 62 pt platter item: **x = iconCenterX + 8.5,
  y = 6**. Tools button golden `[141, 588, 94, 54]`; platter
  `[51, 584, 274, 62]`.

Catalyst keeps the previous 16 pt `systemRed` badge. Guard: `UITabBar.isIOS`.

## After (SKIP_CAPTURE=1, same goldens)

| capture | before | after | blob | layout |
|---|---|---|---|---|
| t200 | 90.972 | **92.929** | 220.5 | 44 |
| t1000 | 97.693 | **97.794** | 220.2 | 20 |
| t2000 | 84.481 | **84.570** | **226.5** | 8 |
| t3000 | 91.244 | **93.169** | 220.5 | 44 |
| t4000 | 92.446 | **92.658** | 220.5 | 46 |
| t5000 | 92.646 | **92.895** | 220.5 | 44 |
| t6000 | 86.594 | **88.172** | 220.5 | 42 |
| t7000 | 92.180 | **92.262** | 220.5 | 47 |

Mean **91.032 → 91.806**, worst 84.481 → **84.570**. t2000 blob **406.5 →
226.5**. Search frames now match (bar 54/60, field 288×44 at (16,18),
table SA 64/70). Badge view origin matches `[196.5, 590, 20, 20]`.

## OPEN (not modelled)

- iOS 26 selected-tab title dumps as `"Library"` (the nav title) at the
  tab bar, not `"Search"`. Largest remaining wrong region is
  `[91.0, 597.5, 23.0, 21.0]` — the selected SF Symbol, not the badge.
- Default-style cell label intrinsic 20.5×~45 vs iOS 52×343; cell 53 vs
  52. Pre-existing table chrome, not this app's two rules.
- Badge glyph ink of `"3"` at 13 pt is 8.5 pt wide in the port's metrics vs
  the dump's 12 pt label bounds (frame is now the measured `[4, 2, 12, 16]`).
- `show-menu` is not in the script (window-hanging presented menu).
- Keyboard is a separate window; not in the PNG.

## Gates

- Catalyst: **124/124**
- iOS suite: **112/113** (known miss `corner_radius` 99.411 — count held)
- Real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.511**
- Linux `swift:6.2-noble` `openrender` green
- `swift test --filter UISearchControllerTests` (5) and `ConformanceRegistryTests`
