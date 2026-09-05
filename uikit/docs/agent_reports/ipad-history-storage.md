# iPad History + Storage real-app oracles

## What was measured

Pocket Casts Listening History picker and Storage & Data Use on a private
**iPad (A16)** simulator, 820×1180 pt @2x portrait, iOS 26.1, as
`realapp_history_light_ipad` and `realapp_storage_light_ipad`. Window safe
area `[32, 0, 25, 0]`. Idiom `.pad`. Goldens from
`REALAPP_DEVICE=iPad-A16 scripts/realapp_probe_sim.sh` (SIM_DEVICE_SUFFIX
`-ipad-history-storage`).

History is the same two-row OptionsPicker as the phone (not a table). The
existing pad formSheet rule sizes the card to the custom detent:

| case | `UIDropShadowView` / `_UIPageSheetView` |
|---|---|
| History (untitled, 2 × 72 pt rows) | `[120, 753, 580, 157]` |
| Settings (detent 343, already landed) | `[120, 567, 580, 343]` |

157 = 12 pt stack inset + 145 pt stack. Same 580-wide centred card, same
bottom edge 910. Frames matched before any new rule.

Storage is the xib-driven grouped table. The app pushes it onto a large-title
settings stack; the phone golden stays a bare root so it does not move.
MEASURED the golden dump:

| fact | number |
|---|---|
| bar | `[0, 32, 820, 106]` (54 + 52, y = window SA 32) |
| large-title label | `[20, 3.5, 306.5, 41]` in the 52 pt zone (abs `[20, 89.5]`) |
| child `safeAreaInsets.top` / table offset | **138** (= 32 + 106) / **−138** |
| grouped cell `layoutMargins` | `[15, 16, 15, 16]` |
| SwitchCell content / switch x | 741 / 741 (`820 − 16 − 63`) |
| inset-grouped card x (ipadprobe, unchanged) | **20** |

Phone iOS large-title x stays **16**. Phone 393 grouped cells stay **20**.

## Rules (iOS cut + pad idiom)

1. `UINavigationBar.largeTitleX` is 20 on pad (`isIOS && !isPad ? 16 : 20`).
2. `UITableViewCell.iOSMargin` is 16 on pad (`UITableView.iOSPadCellMargin`).
   `UITableView.iOSMargin` / inset-grouped card x stay 20.

## Before / after

| screen | before | after |
|---|---|---|
| `realapp_history_light_ipad` | (new) formSheet already `[120, 753, 580, 157]` | **99.760** / MAE 0.174 / blob 6.5 |
| `realapp_storage_light_ipad` | title x 16, cell labels x 20; **99.161** / blob 161.5 | **99.689** / MAE 1.063 / blob 12.0; title `[20, 89.5]`, cells x 16, switch x 741 |
| eight existing real-app screens | — | unchanged 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 |

Floors: History 99.6, Storage 99.5 (measured − 0.1). Catalyst **124/124**.
iOS suite **112/113** (known `corner_radius` 99.411). Linux `swift:6.2-noble`
openrender green.

Left OPEN: History blob 6.5 (icon AA); Storage blob 12.0 (0.5 pt stem in the
34 pt large title). Same rasteriser residual the other real-app rows carry.
