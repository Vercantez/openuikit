# iPad Settings real-app oracle

## What was measured

Pocket Casts Settings (`realapp_settings_light`) on a private **iPad (A16)**
simulator, 820×1180 pt @2x portrait, iOS 26.1, as
`realapp_settings_light_ipad`. Window safe area `[32, 0, 25, 0]`. Idiom `.pad`.

This screen is OptionsPicker's `.formSheet` + custom detent 343, not a table.

ipadprobe + the Settings golden (same device):

| case | `UIDropShadowView` frame |
|---|---|
| default / `.large()` / over-max custom | `[120, 260, 580, 650]` |
| custom 343 (the picker detent) | `[120, 567, 580, 343]` |

`maximumDetentValue` 650; width 580 is a constant (`x = (820−580)/2`);
vertical slack 10 centres the 650-tall card
(`y_large = (H − 650 − 10)/2 = 260`); custom detents keep the same bottom
edge (y=910). Corners `.fixed(32)` all four (continuous). Dim 0.2 over the
0.93 backdrop. Content SA `[0,0,0,0]`, layoutMargins `[0, 20, 0, 20]`.
Identity transform (not the phone 0.959 floating scale).

Two brief hints did **not** match this device and were not modelled:

- inline nav bar is **54** pt (`[0, 32, 820, 54]`), not 50
- inset-grouped card x is **20** (780 wide), not a larger readable-width inset

iPad `.pageSheet` custom 343 is still the phone-style floating card.

## Rule

Under the iOS cut + pad idiom, keep `.formSheet` as formSheet (phone still
maps it to pageSheet). Frame is the centred 580-wide card above; detent
height is the value itself (no extra bottom SA). Corners 32.

## Before / after

| screen | before (phone pageSheet on an 820-wide window) | after |
|---|---|---|
| `realapp_settings_light_ipad` | full-width floating card | **99.511** / MAE 0.273 / blob 1.8; sheet `[120, 567, 580, 343]` |
| seven existing real-app screens | — | unchanged 99.137 / 98.535 / 98.548 / 99.408 / 98.639 / 98.133 / 97.516 |

Floor: 99.4 (measured − 0.1). Catalyst **124/124**. iOS suite **112/113**
(known `corner_radius` 99.411). Linux `swift:6.2-noble` openrender green.
