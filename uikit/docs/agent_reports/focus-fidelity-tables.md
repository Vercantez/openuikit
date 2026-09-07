# Focus settings / Hackers feed / Settings AX1 — agent/focus-fidelity-tables

Date: 2026-09-07. Base: `origin/main` `f0e0382f`. Oracle: iOS 26.1 (23B86)
simulator, iPhone 16 (3x) and iPhone SE 3rd gen (2x), private devices
`OpenUIKit-Chrome-focus-fidelity-tables` / `OpenUIKit-2x-focus-fidelity-tables`.
Goldens: `goldens/ios/golden_realapp_ios/` (unchanged). Scorer:
`Tools/compare/compare_realapp.py --scale 3 --golden-straight-alpha`, bar 97.5.

## Result

| Screen | Before (focus-score, guest) | After, native 3x | After, Linux guest 3x | Cause closed |
|---|---:|---:|---:|---|
| `realapp_focus_settings_light` | 82.491 (native 82.170) FAIL | **98.823** PASS | **98.823** PASS | table chrome: untitled headers, 52 pt classic rows, content margins, symbol accessory slot, empty system button |
| `realapp_hackers_feed_light` | 86.311 (native 85.393) FAIL | 85.536 FAIL | 85.536 FAIL | **wall** — SwiftUI port: symbol images, pill row collapse, missing trailing item (measured below, not closed). The guest number is now the native number; focus-score's 86.311 came from a render whose 3x glyph misses were left BLANK, which scored higher than the drawn text |
| `realapp_settings_light_ax1` | 96.407 (native 97.516) FAIL | 97.549 PASS | **97.549** PASS | 235 (+94) missing 3x glyph masks harvested; the guest no longer blanks them |

Native floors of the other nine phone/pad screens: unchanged or up
(storage 99.469 → 99.740, xs 98.639 → 98.720, xxxl 98.133 → 98.334 from the
same 3x masks; history / settings / dark / iPad rows identical).

## (a) Focus settings — measured rules

The port and the golden were compared frame by frame (golden
`realapp_focus_settings_light.layout.json` vs the port's dump). Every
difference was then reproduced with a scratch probe app (`tableprobe`,
kept under the agent scratchpad, not the repo) that rebuilds Blockzilla's
`SettingsViewController` shape — an `.insetGrouped` table in a
`UINavigationController`, classic `.subtitle` / `.value1` cells with
`contentView.layoutMargins = (0, 20, 0, 0)` and `cell.layoutMargins = .zero`
(SettingsViewController.swift:366), a `UIImageView(systemName:
"chevron.right")` accessory, a `PaddedSwitch` accessory, nil-title sections
whose `heightForHeaderInSection` returns 30, `ActionFooterView` footers with
a `UIButton(type: .system)` — plus sections that vary one thing each. The
probe reproduces the golden's section rects exactly (35 / 87 / 158.667 /
188.667 / 258 / 308 / 360 / 447 / 499 / 588.333 / 640.333 / 697.667 / 727.667).

| Rule (iOS cut only) | Golden / probe 3x | Probe 2x | Port before | Port after |
|---|---|---|---|---|
| Untitled section, delegate height 30 | first: rows at 35, `rectForHeader(0)` = `[35, 0]`; later: header 17.667, no view | 35; 17.5 | 30 with an empty `UITableViewHeaderFooterView` | 35 / ceil-to-pixel(17.5), no view |
| Untitled footer | 17.333 | 17.5 | 17.5 (2x-only reading) | floor-to-pixel(17.5) |
| Titled header, delegate 30 / 50 | label y 3.667 / 23.667 (pad 6) | 4 / 24 (pad 5.5) | y 18.667 (overflowed the 30 pt header) | H − labelH − (6 \| 5.5) |
| Classic row, `estimatedRowHeight = automaticDimension` | 52 (every style, with chevron / switch / no accessory) | 52 | 53 (+2 for accessory-less value1) | 52; the +2 stays only for delegate-pinned heights (fixture scenes) |
| `contentView.layoutMargins = (0, 20, 0, 0)` | label x 20; value1 detail right edge = content width − 0 | same | 16; −8 | assigned margins win |
| Automatic separator with those margins | `separatorInset` (0, 20, 0, 16); with `cell.layoutMargins = .zero` (0, 20, 0, 0) → `[20, 51, 333, 1]` | same | `[16, 52, 321, 1]` | left = content margin, right = cell's assigned margin |
| `.subtitle` cell, no detail text | label y 16 = ceil-to-pixel((52 − 20.333)/2) | 16 | 15.667 (two-line block) | centred single label |
| Symbol `UIImageView` accessory | fixed 24 pt slot at the 20 pt margin, centred: chevron 12.667 wide at 314.667, widened to 16 / 30 at 313 / 306, gearshape 20.667 at 310.667, circle.fill at 311.167; content view 309 = 353 − 20 − 24. Plain image views (8–30 pt) and UIViews (10–71 pt) keep right edge at the margin | chevron at 308.75 in the 343 pt cell (not pixel-snapped); content 303 | right edge at margin (320.333) | 24 pt slot for `image.isSymbolImage` |
| `UIButton(type: .system)`, no image | width ≥ 30; empty title keeps the line box: 12 pt 30 × 27, 17 pt 30 × 33, default 30 × 30; "abcd" 30 × 27, "abcdef" 40 × 27, "Learn more." 68 × 27 | same | empty title 0 × 12 | max(30, w) × (ceil(lineHeight) + 12) |

Files: `Sources/OpenUIKit/UITableView.swift` (untitled header / footer
heights, delegate-height flag, separator insets, classic automatic height,
value1 padding scope), `Sources/OpenUIKit/UITableViewCell.swift` (header
label y, label x / detail edge from assigned margins, subtitle-without-detail
centring, symbol accessory slot), `Sources/OpenUIKit/UIButton.swift`
(legacy minimum width / empty-title height). Every constant carries its
measurement in a comment. Tests: `Tests/OpenUIKitTests/FocusSettingsTableTests.swift`
(6 tests, failing before the change on the first five assertions groups,
passing after; the Catalyst-cut test pins 0 × 12 / no change there).

Open, left as measured: the 30 pt and 10 pt `chevron.right` symbol
accessories sit one pixel above the floored centre (10.667 vs 11, 20.667 vs
21); the body-size chevron Focus uses is on the floor. The automatic titled
header (55.333 / 45.333 / compact 38) keeps its previous rule.

Native result: 82.170 → 98.33 (rules) → 98.678 (subtitle centring +
accessory pixel floor) → **98.823** (with the 3x masks of part (c)).
Residual blob `[312.3, 325.3, 0.3, 9.0]`.

## (b) Hackers feed — the wall (measured, not closed)

`realapp_hackers_feed_light` is SwiftUI (`FeedView` → `List` of
`PostRowView` → `PostDisplayView` from the DesignSystem stub, hosted in a
`UINavigationController`). The golden's cells are opaque
`CellHostingView`s, so the port's own dump and the pixels are the evidence:

1. **SF Symbols are blank.** `Sources/SwiftUI/Hosting.swift`
   `_SystemSymbolView.drawContent` paints only `chevron.right` and
   `magnifyingglass` procedurally and returns for every other name. The
   feed shows `safari` (55 pt thumbnail placeholder), `arrow.up`,
   `message`, `bookmark` (12 pt caption pills), `gearshape` (trailing bar
   item) and `chevron.down` (title menu) — all empty in the render.
   `symbol_ink_ios_3x.json` has these names only at the 17 pt bar / tab
   configurations (`17|regular|unspecified`, `17|regular|large`,
   `17|medium|large`, `18|medium|large`); the caption-size and 55 pt
   configurations are unharvested.
2. **The pill row collapses under a two-line title.** Row 0 ("Show HN: A
   tiny UIKit Hacker News client") in the port's dump: caption
   `[67, 10.17, 86.67, 14.33]`, title `[67, 30.5, 294, 40.67]` (two lines),
   then the pills' backgrounds are 6 pt tall (`[67, 81.17, 56.33, 6]`) and
   their labels 0 pt (`[93, 87.17, 20.33, 0]`); single-line rows keep
   full pills. The VStack measured 77 pt for a 97.33 pt content box, i.e.
   the pill HStack was proposed the remainder after the wrapped title
   instead of its own fitting height. Row heights: golden 127.333 (two-line)
   / 107 (one-line); ours 129.333 / 109 (+2 pt each, cause not isolated).
3. **The trailing `gearshape` item never reaches the bar.** Golden nav bar:
   `PlatterView [277, 0, 44, 44]` (gear, `UIImageView [2.33, 0, 27.33, 27]`)
   and `PlatterView [333, 0, 44, 44]` (search). Ours: only
   `_UIBarButtonItemView [333, 0, 44, 44]`. `_openCustomBarButtonItem`
   (Hosting.swift) already carries the measured `[277, 0, 44, 44]`
   platter, so the `ToolbarItem(placement: .navigationBarTrailing)
   { settingsButton }` entry is being dropped before it (not isolated).
   The scorer's missing-content region `[287.3, 70.0, 23.0, 23.0]` is this
   gear.
4. **The "Top" title menu paints nothing.** Ours has the
   `_SwiftUIMenuControl [136.83, 4, 119.33, 36]` with a `UILabel "Top"`
   `[14, 11.83, 29.33, 20.33]` and a `_SystemSymbolView` (chevron.down)
   inside a platter, but the render shows an empty pill; the golden shows
   "Top ⌄" (`HostingUIButton [0, 0, 119.33, 36]`).
5. **Title wrap width.** The golden wraps "Show HN: A tiny UIKit Hacker /
   News client"; ours "Show HN: A tiny UIKit Hacker News / client" — our
   title label is 294 pt wide (67 … 361); the golden column is narrower by
   roughly 50 pt (pixel reading only, the golden cell is opaque).

Each of these is SwiftUI-port engine work (symbol harvest at caption / 55 pt
configurations plus a table lookup in `_SystemSymbolView`; VStack/HStack
proposal semantics; toolbar entry collection) and none is a table constant.
The brief's "2 pt self-sizing constant" reading was the smallest of the five
differences. No change was made for this screen; native 85.393 → 85.536
(the 3x masks only).

## (c) Settings AX1 — 3x glyph masks

`OPENUIKIT_INK_LOG` over the 15 real-app screens at
`OPENUIKIT_REALAPP_SCALE=3` (native, iOS cut) listed **235** unique `I3|`
misses — light only, 20 (family, size) pairs from `system-regular|12` to
`system-semibold|33`; `realapp_settings_light_ax1` alone contributes the
`system-bold|24`, `system-semibold|30` and `system-semibold|33` keys. The
guest draws a miss blank (focus-score's `I3|system-regular|13|light|F0.0|71`
was the first of them). Harvested with `Tools/oracle2/inkprobe`
(`SIMCTL_CHILD_INK_SCALE=3`, iPhone 16 / iOS 26.1): 235/235 masks, 0
skipped, the 9 overlapping `(family, size)` baselines byte-identical to the
existing table. `glyph_ink_ios_3x.json` 850 → **1085** entries. Native 3x
`OPENUIKIT_INK_LOG` afterwards: empty. Native ax1 97.516 → 97.549 (the
harvested masks replace the CoreText fallback pixel for pixel).

## Guest render (Linux Mach-O, `uikit-linux`)

The branch snapshot (`git archive agent/focus-fidelity-tables`, uikit tree
`31fda508…`, machorun tree unchanged `76885295…`) was staged as
`/work-focus-fidelity-tables` in the operator's container and built with
the production builder, `W=$PWD bash full/scripts/build_full.sh`, against
the existing support inputs (`/tmp/focus-guest-linux/support/scratch`:
sysroot_fe4, swift-foundation, swift-collections, swift-foundation-icu,
mrroot, mrroot_fe, opencombine) and the machorun products of the previous
score copy. Two container-only scratch commits, neither on the branch:
the copy's `scripts/vendor_pins.sh` pinned to this snapshot's uikit tree
(the builder's attestation), and `full/driver/main.swift` reading
`OPENUIKIT_REALAPP_SCALE` through `cpio_getenv` — the guest driver does not
read it, so the first 3x attempt rendered 786 × 1704 (2x). Result:
`FOCUS_GUEST_BUILT`, then `machorun render_full realapp` at
`OPENUIKIT_REALAPP_SCALE=3`, iOS cut, no font directory:

```text
[render_full] realapp rendered=15 failed=0
```

Two more 3x glyph rounds were needed for the two UNSCORED screens the
guest renders after the twelve scored ones: Ledger trapped on
`I3|system-regular|13|light|F0.0|36` ("$", the guest's own Foundation
formats the amounts) and then on `I3|system-medium|18|light|F0.0|71`, so
13 pt regular and 17 / 18 pt medium ASCII 33–126 (light, F0.0) were
harvested on the same device: 94 + 188 masks, 0 skipped, 56 + 35
overlapping keys byte-identical. `glyph_ink_ios_3x` final: **1276** entries.

All twelve scored guest PNGs are **byte-identical** to the native 3x render
of the same commit (12/12; across the 15, only Ledger — guest Foundation
formatter output — and the browser differ), so the guest scores are the
native scores:

| Screen | focus-score guest | this branch, guest 3x |
|---|---:|---:|
| `realapp_focus_settings_light` | 82.491 FAIL | **98.823** PASS |
| `realapp_settings_light_ax1` | 96.407 FAIL | **97.549** PASS |
| `realapp_hackers_feed_light` | 86.311 FAIL | 85.536 FAIL |
| history / settings / dark / storage | 99.137 / 98.535 / 98.548 / 99.268 | 99.137 / 98.535 / 98.548 / **99.740** |
| settings xs / xxxl | 98.477 / 97.654 | **98.720** / **98.334** |
| settings / history / storage iPad (2x) | 99.650 / 99.860 / 99.734 | 99.650 / 99.860 / 99.734 |

The guest 2x run of the same build (the verifier's geometry) is
byte-identical to the committed `linux-existing14.sha256` baseline on
13/14 screens; the fourteenth, Focus settings, is the intended change and
its new digest equals the native 2x render's.

## Gates

- Catalyst gate: **124/124** (`openrender render fixtures/scenes/*.json`,
  `compare.py`).
- Fresh iOS suite on the private simulators (`scripts/ios_suite.sh
  /tmp/suite-focus-fidelity-tables`): **112/113**, the sole miss the
  pre-existing `corner_radius` 99.411 — the same count and the same miss as
  focus-golden / focus-score recorded before this branch; no scene dropped.
- Real-app floors (native 3x, `compare_realapp.py`): 99.137 / 98.535 /
  98.548 / 99.740 / 98.720 / 98.334 / 97.549 / 99.650 / 98.823 / 99.860 /
  99.734 / 85.536 — every row at or above its previous value.
- Unit tests: `FocusSettingsTableTests` 6/6, plus `TableViewMetricsTests`,
  `TableViewCompatibilityTests`, `UIButtonTests`, `IOSDevicePixelMetricsTests`
  — 68/68.
- Guest 2x baseline (`fixtures/realapp/linux-existing14.sha256`): 13/14
  byte-identical; `realapp_focus_settings_light.png` changed by design and
  its new digest `80fa957f…` equals the native 2x render's digest (guest =
  Darwin, byte for byte). The committed browser fixture is unchanged
  (byte-identical to this guest run).
- Merge proof, from the monorepo root: `CHECK_ONLY=1 bash
  uikit/scripts/agent_merge.sh agent/focus-fidelity-tables` printed no
  `REFUSED` line — macOS build + Catalyst 124/124, guest library route,
  test bundle, real-app floors, the ten-app conformance board (no drop),
  Linux `swift:6.2-noble` build — and ended with `checks passed
  (CHECK_ONLY)` (exit 128 in its cleanup, as documented). Run once at
  `a69b31df` and again on the final commit (see the bottom of this file).

## Reproduce

```sh
# probes (scratch app, agent scratchpad): tableprobe on both devices
SIM_DEVICE_SUFFIX=-focus-fidelity-tables zsh tableprobe_sim.sh /tmp/tableprobe-focus-fidelity-tables
SIM_DEVICE=2x SIM_DEVICE_SUFFIX=-focus-fidelity-tables zsh tableprobe_sim.sh /tmp/tableprobe2x-focus-fidelity-tables
# 3x glyph harvest
sort -u ink.log | sed 's/^I3|//' > keys.txt
INK_KEYS=keys.txt SIMCTL_CHILD_INK_SCALE=3 SIM_DEVICE_SUFFIX=-focus-fidelity-tables scripts/ink_probe_sim.sh /tmp/ink3x
# native score
OPENUIKIT_REALAPP_SCALE=3 OPENUIKIT_FORCE_IOS=1 ./.build/release/openrender realapp /tmp/app
python3 Tools/compare/compare_realapp.py --golden goldens/ios/golden_realapp_ios --out /tmp/app --scale 3 --golden-straight-alpha
```
