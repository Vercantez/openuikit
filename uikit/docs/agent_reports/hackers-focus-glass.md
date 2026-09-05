# Hackers / Focus nav-bar glass platters

The two newest real-app screens were held back by glass the material
function already covers. This branch wires the missing **geometry**
under the iOS cut. The mix (`_UIGlassMaterial`, wave 12) is not retuned.

## Probe (not in the repo)

`scripts/render_sim_scenes.sh`, iPhone 16 @3x / iOS 26.1. Four backdrops
(white, black, systemRed, white→black gradient) under a navigation bar
with (a) a title `UIBarButtonItem` "Done", (b) a `UIBarButtonItem` with
`menu` titled "Top", (c) `navigationItem.searchController`. Probes lived
in `/tmp/glass-navplatters/`.

| item | frame | r | white | black | red |
|---|---|---|---|---|---|
| Done title | `[303.667, 0, 73.333, 44]` | 22 | 255 | 198 | (255,174,179) |
| UIKit menu "Top" | `[16, 0, 62, 44]` | 22 | 255 | 198 | (255,174,179) |
| `searchController` | `[28, 835, 337, 48]` | — | bottom toolbar field, not a 44×44 nav icon |

Ring over black: dx=0/0.33/0.67 → 231/223/213 then 198. Same two-unknown
mix as toolbar/tab/nav-back. Black frost 198 matches
`glass_navbar_iphone16_black` Back (filled content under a transparent
bar). Focus Done over the unpainted bar stays **220**. Mix not retuned.

A UIKit menu-backed title item is **not** the Hackers Top. Hackers'
selector is SwiftUI `.glassEffect(.regular.interactive(), in: .capsule)`.

## Golden frames (iPhone 16 @3x)

`realapp_hackers_feed_light.layout.json`:

- Bar `[0, 59, 393, 54]`.
- Principal `HostedViewWrapper` `[136.667, 4, 119.667, 36]` (centre 22).
- Glass `UIPlatformGlassInteractionView` `[20, −4, 79.333, 44]` r=22
  inside that host. Horizontal pad 20. Vertical pad 16 is collapsed by
  the 36 pt title control. Text "Top" `[14, 12, 29.333, 20]` in the
  glass (leading 14). Chevron in an 18×18 circle, HStack spacing 8.
- Trailing two 44×44 platters, gap 12, trailing margin 16: settings
  `[277, 0, 44, 44]`, search `[333, 0, 44, 44]`. Not one grouped run.

`realapp_focus_settings_light`: Done `[303.667, 0, 73.333, 44]` r=22
already matches the existing bar-button metrics (interior 220). The
481.7 pt² blob at `[290, 733, 63, 19]` is a table accessory / chevron
region (`SettingsTableViewAccessoryCell` near y=727), not the platter.

## Rules (iOS cut)

1. **`ToolbarItem` keeps placement.** `_OpenToolbarItem` /
   `DefaultToolbarItem` / `ToolbarSpacer` wrap `.toolbarItem(placement)`.
   Bottom-bar items (Hackers' `DefaultToolbarItem(kind: .search)`) are
   skipped.

2. **`UIHostingController` installs chrome** on `navigationItem`, not only
   `NavigationStack`. Principal → `titleView` (36 pt host, vertical
   padding collapsed so the 44 pt glass centres at y=−4). Trailing
   image items → real `UIBarButtonItem`s. `.searchable(placement:
   .toolbar)` → trailing-most `.search` system item (the 0-height
   content `UISearchBar` stays for tests).

3. **iOS `.glassEffect` is `_UIGlassMaterial`**, capsule r=height/2,
   sized to the child's measured frame (so 44 overflow the 36 pt
   host). Catalyst keeps `UIVisualEffectView`.

4. **`_isolatesPlatter`** + `_showsPlatterWithCustomView` so two SwiftUI
   image items keep two 44×44 platters at gap 12, not a grouped 8 pt run.
   Search is `.search` (vector magnifier). Settings/xmark stay SwiftUI
   custom views so `SwiftUI.Image.systemName.*` remains in the tree.

## Ours after (Hackers dump)

- Title host `[136.833, 4, 119.333, 36]` (Δ 0.333 pt vs golden).
- Glass `[20, −4, 79.333, 44]` r=22. Text `[14, 11.833, 29.333, 20.333]`.
  Circle `[51.333, 13, 18, 18]`.
- Search `[333, 0, 44, 44]`, settings `[277, 0, 44, 44]`.

## Before / after

| screen | before | after | blob |
|---|---|---|---|
| `realapp_hackers_feed_light` | 84.582 / MAE 14.054 / 174.4 at `[84.0, 152.3, 11.7, 43.7]` | **85.393** / MAE 13.931 / 149.7 at `[118.3, 620.7, 13.7, 24.3]` | missing 134.3 at `[287.3, 70.0, 23.0, 23.0]` (settings `gearshape` SF) |
| `realapp_focus_settings_light` | 82.192 / MAE 8.404 / 481.7 at `[290, 733, 63, 19]` | **82.192** / same | off-platter; Done interior already 220 |

Other real-app screens unchanged: **99.137 / 98.535 / 98.548 / 99.469 /
98.639 / 98.133 / 97.516 / 99.511 / 99.760 / 99.689**. Catalyst
**124/124**. iOS suite **112/113** (known miss `corner_radius`). Linux
`swift:6.2-noble` openrender green.

## Open (not guessed)

- Nav title platters over **filled black content** frost at **198** vs
  toolbar / Focus-unpainted **220**. Same as the prior navbar probe. Mix
  not retuned.
- UIKit `UIBarButtonItem.menu` is a regular title platter, not Hackers'
  glassEffect capsule.
- UIKit `searchController` is a bottom 48 pt field, not the 44×44 nav
  icon. The icon is `.searchable` + `.searchToolbarBehavior(.minimize)`.
- Settings `gearshape` and search SF size vs `_BarSymbol.magnifier`
  remain known SF-Symbol gaps; platters were the target.
- Focus blob 481.7 at `[290, 733, 63, 19]` is off the Done platter.
- Residual Hackers blob 149.7 at `[118.3, 620.7]` is in the list (cell
  129.333/109 vs golden 127.333/107), not chrome.
