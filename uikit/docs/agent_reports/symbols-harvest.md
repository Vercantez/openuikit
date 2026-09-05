# Harvested SF Symbol coverage beyond the tab bar

`UIImage(systemName:)` on the iOS cut returned a harvested stamp only for
the ten tab-bar names at 18 pt medium large. Every other name was nil on
Linux (the trial Notes tab lost its icon). This round extends the same
harvest (`Tools/oracle2/symbolinkprobe`, method as
docs/agent_reports/symbols-tabbar.md) to the symbols real apps actually
pass, at the configurations they pass them at.

Devices: `OpenUIKit-2x-symbols-harvest` (SE 3rd gen, 2x) and
`OpenUIKit-Chrome-symbols-harvest` (iPhone 16, 3x) / iOS 26.1. Captures
`/tmp/symbolink-2x-symbols-harvest`, `/tmp/symbolink-3x-symbols-harvest`.

## Name union (73)

String literals `systemName:` / `systemImage:` plus the dynamic names the
sources actually pass:

| source | names |
|---|---|
| `Sources/RealAppProbe/Vendored/**` | arrow.up, arrow.up.arrow.down, arrow.uturn.down, calendar, checkmark, chevron.down, chevron.right, gearshape, safari, sparkles, square.and.arrow.up, xmark.circle.fill |
| Hackers `PostType.iconName` (not a literal) | flame, bubble.left.and.bubble.right, eye, briefcase, star, bolt, bookmark, clock |
| DesignSystem / `UISearchBar` chrome | message, multiply |
| Conformance apps (7 under `Sources/ConformanceApps/`) | calendar, clock, plus.circle.fill |
| Previous tab-bar harvest | calendar, clock, clock.fill, gear, house, house.fill, magnifyingglass, person, person.fill, plus.circle.fill |
| Top 60 `systemName:` / `systemImage:` counts across the 20 ladder-corpus apps (`scratch/ladder-corpus`) | checkmark, xmark, square.and.arrow.up, ellipsis, trash, chevron.forward, circle.fill, chevron.right, safari, doc.on.doc, info.circle, checkmark.circle.fill, plus, xmark.circle.fill, chevron.backward, chevron.down, calendar, exclamationmark.triangle, gearshape, checkmark.circle, magnifyingglass, circle, play.fill, ellipsis.circle, doc, camera, arrow.up, star, exclamationmark.circle.fill, envelope, house, doc.text, link, star.fill, exclamationmark.triangle.fill, bell, folder, list.bullet, minus.circle, sparkles, questionmark.circle, chevron.up.chevron.down, arrow.clockwise, pencil, chevron.up, gear, photo, photo.on.rectangle, photo.on.rectangle.angled, arrow.up.arrow.down, xmark.circle, plus.circle, line.3.horizontal.decrease, pause.fill, chevron.left, exclamationmark.circle, person, number, arrow.uturn.down, person.crop.circle |

Union after de-dupe, all present on iOS 26.1: **73**. List in
`Tools/oracle2/symbolinkprobe/names.txt`. Conformance is seven apps, not
eight.

## Configurations (measured, not guessed)

Live dump `symbol_configs.json` from the probe (tab-bar `UIImageView`s,
nav-bar button `UIImageView`s, unconfigured `UIImage(systemName:)` and
its `UIImageView`):

| stored key | why | measurement |
|---|---|---|
| `17\|regular\|unspecified` | nil `UIImage.SymbolConfiguration` | unconfigured calendar **21×17.5** at 2x (42×35 px). Byte-identical to explicit `pointSize=17, weight=Regular, scale=Unspecified` (**73/73** names). Live `UIImageView.preferredSymbolConfiguration` is nil. |
| `17\|regular\|large` | the brief's bar-button candidate | **distinct** mask: plus **45×43** vs 17 medium large **46×44**. Stored because the candidate was named; it is not what the live bar button uses. |
| `17\|medium\|large` | live nav-bar button | `preferredSymbolConfiguration` dumps `textStyle=UICTFontTextStyleBody, weight=Medium, scale=Large`. Body @ Large is 17 pt; `pointSize=17, weight=Medium, scale=Large` is byte-identical to that text-style configuration (**73/73**). Live plus button **frame** 22.5×21.5 vs harvested alignment **23×22** — view layout vs alignment box; coverage method matches the tab-bar harvest byte-for-byte. |
| `18\|medium\|large` | live tab bar | `preferredSymbolConfiguration` dumps `pointSize=18, weight=Medium, scale=Large`. Calendar 18/medium/large F0 is **byte-identical** to the previous tab-bar-only table (inkPx 1109, inkSum 243587). |

Aliases applied at lookup, not stored: `default` → `17|regular|unspecified`;
`body|medium|large` → `17|medium|large`.

Phases: 2x two masks (view origin 20 vs 20.25 pt). Every 18/medium/large
F0 vs F0.5 pair differed (**73/73**). Tab-bar frames land on integer
device pixels, so F0. 3x: one mask (F0).

No source in the union passed an explicit `UIImage.SymbolConfiguration`
other than what the live chrome already dumps. Reminder's 56 pt
`plus.circle.fill` stays on the procedural path (not a harvested key).

## Resource

Alignment-box coverage only (`{pw,ph,w,h,ox,oy,m}`), same packing as
`glyph_ink_ios.json`. Keys `name|pointSize|weight|scale|phase`.

| file | bytes | entries |
|---|---|---|
| `Sources/OpenUIKit/Resources/symbol_ink_ios.json` | 1,968,623 | 584 = 73 × 4 configs × 2 phases |
| `Sources/OpenUIKit/Resources/symbol_ink_ios_3x.json` | 2,135,728 | 292 = 73 × 4 configs × 1 phase |
| **total** | **4,104,351 (~4.10 MB)** | under the 6 MB budget |

2x alignment sizes (px, F0) for every stored config:

| name | 17/reg/unspec | 17/reg/large | 17/med/large | 18/med/large |
|---|---|---|---|---|
| `arrow.up` | 34×36 | 43×49 | 43×49 | 47×51 |
| `arrow.up.arrow.down` | 48×37 | 60×50 | 61×50 | 66×53 |
| `arrow.uturn.down` | 39×36 | 50×49 | 51×49 | 55×52 |
| `calendar` | 42×35 | 53×48 | 54×48 | 58×50 |
| `checkmark` | 37×33 | 47×45 | 48×45 | 52×47 |
| `chevron.down` | 37×21 | 47×29 | 48×30 | 52×31 |
| `chevron.right` | 25×33 | 32×45 | 33×46 | 35×48 |
| `gearshape` | 42×40 | 54×54 | 55×54 | 57×57 |
| `safari` | 40×38 | 52×52 | 52×52 | 55×55 |
| `sparkles` | 37×42 | 48×57 | 48×58 | 53×60 |
| `square.and.arrow.up` | 38×44 | 48×59 | 49×60 | 53×63 |
| `xmark.circle.fill` | 40×38 | 52×52 | 52×52 | 55×55 |
| `clock` | 40×38 | 52×52 | 52×52 | 55×55 |
| `plus.circle.fill` | 40×38 | 52×52 | 52×52 | 55×55 |
| `message` | 45×37 | 58×50 | 59×51 | 62×53 |
| `flame` | 34×40 | 44×54 | 44×55 | 47×58 |
| `bubble.left.and.bubble.right` | 56×42 | 70×56 | 72×57 | 77×60 |
| `eye` | 52×33 | 66×45 | 67×45 | 72×47 |
| `briefcase` | 47×37 | 59×50 | 60×51 | 65×53 |
| `star` | 44×40 | 56×54 | 57×54 | 59×57 |
| `bolt` | 34×43 | 42×57 | 43×58 | 45×61 |
| `bookmark` | 35×40 | 45×54 | 46×55 | 47×57 |
| `clock.fill` | 40×38 | 52×52 | 52×52 | 55×55 |
| `gear` | 43×41 | 55×54 | 56×55 | 58×58 |
| `house` | 48×39 | 61×53 | 62×54 | 67×56 |
| `house.fill` | 48×39 | 61×53 | 62×54 | 67×56 |
| `magnifyingglass` | 41×37 | 52×50 | 52×51 | 55×53 |
| `person` | 38×35 | 48×48 | 48×48 | 52×50 |
| `person.fill` | 36×34 | 46×47 | 47×47 | 51×49 |
| `xmark` | 35×31 | 44×42 | 45×43 | 49×45 |
| `ellipsis` | 37×11 | 47×16 | 48×17 | 50×17 |
| `trash` | 39×41 | 48×56 | 48×56 | 51×59 |
| `chevron.forward` | 25×33 | 32×45 | 33×46 | 35×48 |
| `circle.fill` | 40×38 | 52×52 | 52×52 | 55×55 |
| `doc.on.doc` | 42×46 | 54×62 | 55×63 | 59×66 |
| `info.circle` | 40×38 | 52×52 | 52×52 | 55×55 |
| `checkmark.circle.fill` | 40×38 | 52×52 | 52×52 | 55×55 |
| `plus` | 36×32 | 45×43 | 46×44 | 50×46 |
| `chevron.backward` | 25×33 | 32×45 | 33×46 | 35×48 |
| `exclamationmark.triangle` | 41×36 | 53×49 | 54×49 | 58×52 |
| `checkmark.circle` | 40×38 | 52×52 | 52×52 | 55×55 |
| `circle` | 40×38 | 52×52 | 52×52 | 55×55 |
| `play.fill` | 30×32 | 38×44 | 39×45 | 42×47 |
| `ellipsis.circle` | 40×38 | 52×52 | 52×52 | 55×55 |
| `doc` | 36×40 | 46×54 | 47×55 | 51×57 |
| `camera` | 49×36 | 63×49 | 63×49 | 68×52 |
| `exclamationmark.circle.fill` | 40×38 | 52×52 | 52×52 | 55×55 |
| `envelope` | 49×33 | 62×45 | 62×46 | 67×48 |
| `doc.text` | 36×40 | 46×54 | 47×55 | 51×57 |
| `link` | 44×42 | 56×56 | 57×57 | 59×59 |
| `star.fill` | 44×40 | 56×54 | 57×54 | 59×57 |
| `exclamationmark.triangle.fill` | 41×36 | 53×49 | 54×49 | 58×52 |
| `bell` | 40×39 | 51×52 | 52×53 | 54×56 |
| `folder` | 46×35 | 59×47 | 59×48 | 64×50 |
| `list.bullet` | 42×29 | 53×39 | 54×40 | 59×42 |
| `minus.circle` | 40×38 | 52×52 | 52×52 | 55×55 |
| `questionmark.circle` | 40×38 | 52×52 | 52×52 | 55×55 |
| `chevron.up.chevron.down` | 31×36 | 39×49 | 40×51 | 44×53 |
| `arrow.clockwise` | 36×40 | 46×54 | 46×55 | 49×57 |
| `pencil` | 35×31 | 45×43 | 46×44 | 48×46 |
| `chevron.up` | 37×21 | 47×29 | 48×30 | 52×31 |
| `photo` | 48×35 | 61×48 | 61×48 | 66×50 |
| `photo.on.rectangle` | 50×38 | 63×51 | 64×52 | 69×55 |
| `photo.on.rectangle.angled` | 51×40 | 65×53 | 66×54 | 70×57 |
| `xmark.circle` | 40×38 | 52×52 | 52×52 | 55×55 |
| `plus.circle` | 40×38 | 52×52 | 52×52 | 55×55 |
| `line.3.horizontal.decrease` | 42×24 | 54×33 | 54×34 | 59×35 |
| `pause.fill` | 29×32 | 36×43 | 37×44 | 40×47 |
| `chevron.left` | 25×33 | 32×45 | 33×46 | 35×48 |
| `exclamationmark.circle` | 40×38 | 52×52 | 52×52 | 55×55 |
| `number` | 38×37 | 49×50 | 49×50 | 53×53 |
| `person.crop.circle` | 40×38 | 52×52 | 52×52 | 55×55 |
| `multiply` | 31×27 | 39×37 | 40×38 | 43×39 |

3x default `house` is 72×59 px (24 × 59/3 pt); `chevron.right` 38×50 px
(12.667×16.667 pt) — Focus golden accessory `UIImageView` is the same
size `[314.667, 17.667, 12.667, 16.667]`.

## Rule

Under `OpenUIKitRuntime.systemFontCut == .iOS`, `SymbolInkTable.stampTemplate`
looks up `name|configurationKey|F0`. Nil configuration maps to
`17|regular|unspecified`. A harvested name at a harvested configuration
whose key is missing from the resource is
`preconditionFailure("SymbolInkTable missing key: " + key)` — a silent
miss would stamp the procedural silhouette. Unharvested names and
unharvested configurations return nil and keep the existing procedural
fallback (Reminder six + `clock.fill`) or fail closed.

Catalyst keeps the vectors (`tabbar_basic` uses solid bitmaps).

## After

| gate | result |
|---|---|
| Catalyst `openrender render` + `compare.py` | **124/124** |
| iOS suite `scripts/ios_suite.sh /tmp/suite-symbols-harvest` | **112/113**, miss is the known `corner_radius` |
| real app | **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393** |
| `swift test --filter SystemImageTests` | 23 passed (+ 3 `SystemImageSourceCompatibilityTests`) |
| Linux `swift:6.2-noble` `openrender` release | green |

Focus **82.192 → 82.170** (MAE 8.404→8.412, blob still 481.7 at
`[290, 733, 63, 19]`). `chevron.right` accessory size now matches the
golden 12.667×16.667; ours x is 320.333 vs golden 314.667 (pre-existing
layout, Focus OPEN — stock grouped trailing vs Focus
`contentView.layoutMargins`). The extra ink at the wrong x is the 0.022.
Not a pass→fail.

Hackers **85.393** held (same as the glass-platter after). SwiftUI
`Image(systemName:)` is still the 18×18 placeholder — routing those nodes
through `UIImage(systemName:)` changed layout and dropped the feed, so it
was reverted. The leftover missing 134.3 at `[287.3, 70.0, 23, 23]` is
still settings `gearshape` on that SwiftUI path.

Other Pocket Casts / iPad screens unchanged.

## OPEN

- SwiftUI `Image(systemName:)` still a placeholder. Wiring it to the
  harvest is a layout change, not a missing-key problem.
- Focus accessory x 320.333 vs 314.667.
- DesignSystem `arrow.up.circle.fill` / `bookmark.fill` are not in the 73
  (not a Vendored literal and not in the corpus top 60). Unharvested → nil.
- Unharvested configurations (Reminder 56 pt `plus.circle.fill`, any
  weight/scale outside the four keys) stay procedural / nil.
