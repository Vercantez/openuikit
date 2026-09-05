# Merge `origin/agent/notes-fidelity` onto main

MERGE TASK, no new rules. `origin/agent/notes-fidelity` (compact 38 first
header under tab+search, disclosure trailing 8, segmented Auto Layout min
34, `note.text`, RTL tab packing) into current main, which had since landed
the 73-name symbol harvest and the Tabs-measured tab-bar platter mirror.

## `note.text`

The 73-name harvest did **not** contain `note.text`. The branch's masks
were added on top of main's tables (not a duplicate):

| resource | names | entries | `note.text` keys |
|---|---|---|---|
| `symbol_ink_ios.json` (2x) | 73 → **74** | 584 → **592** | 8 (F0 + F0.5 × 4 configs) |
| `symbol_ink_ios_3x.json` | 73 → **74** | 292 → **296** | 4 (F0 × 4 configs) |

`names.txt` appends `note.text`. `SymbolInkTable` comments that the
branch updated (unconfigured 17/regular/unspecified) say 74/74; the
harvest's own 73/73 measurements in that file stay.

## File resolutions

| file | how it was resolved |
|---|---|
| `Sources/OpenUIKit/UITabBar.swift` | **ours (main)**. Auto-merge stacked the branch's visual-index packing **on top of** main's pack-LTR-then-mirror, which would double-reverse items. Main already measures the same leading-to-trailing rule from Tabs t200.rtl (Library abs.x 256 / Scroll 88). Capsule stays `item.frame.midX`. |
| `Resources/symbol_ink_ios.json` / `_3x.json` | theirs (branch): harvest + `note.text`. Main had not touched the JSON since the merge-base. |
| `SymbolInkTable.swift`, `names.txt` | branch's 74th name on main's harvest. |
| `UITableView.swift` | branch: tab+search compact-38 when the full header would scroll. |
| `UITableViewCell.swift` | branch: `accessoryType != .none` eats content-view trailing 8. |
| `UISegmentedControl.swift` | branch: Auto Layout iOS min height 34. |
| `IOSDevicePixelMetricsTests.swift` | main's file (`#if !os(Linux)` `@MainActor`) **plus** the branch's named tests: `testTabHostedSearchCompactsFirstGroupedHeaderWhenScrollable`, `testPhoneTabBarItemsPackLeadingToTrailingInRTL`, `testDisclosureAccessoryEatsContentViewTrailingMargin`, and the two Notes-like helpers (same Linux `@MainActor` guard as `UntitledGroupedSource`). |
| `SystemImageTests.swift` | main's Linux `@MainActor` guard **plus** the branch's `note.text` 29×25 assertion and 74/74 comment. |
| `docs/REAL_APP_TEST.md` | **both** rows: notes-fidelity newest, then main's linux-env / rtl-rest. |
| `scoreboard/open.txt` | **both** sides: main's four RTL OPEN items kept; branch's `Notes-t200-search-platter` and the Notes sentence on `Tabs-t6000-cancel-inset`. |
| pin files | main (untouched). No `Package.resolved`. |

The branch's Notes t200.rtl sample (Notes label abs.x 216) is the same
leading-to-trailing packing main already has from Tabs; the named RTL
test passes against main's platter-mirror.

## Proof (this Mac)

- `swift build --build-tests` green
- `swift test --filter 'TableView|TabBar|Symbol'`: 75 tests, 0 failures
- Named tests + `SystemImageTests` / `IOSDevicePixelMetricsTests`: 43 tests,
  0 failures (including the three Notes cases and `note.text` 29×25)
- `SKIP_CAPTURE=1 scripts/conformance_flow.sh /tmp/conformance-Notes Notes`
  (goldens already at `/tmp/conformance-Notes/golden`, sha256-identical to
  `/tmp/hc-conformance-Notes`; not written). Light:

  | capture | notes-fidelity after | this merge |
  |---|---|---|
  | t200 | **89.019** blob 111.2 layout 3 | **89.105** blob 111.2 layout 3 |
  | t5000 | **98.784** blob 38.2 layout 6 | **98.784** blob 38.2 layout 6 |

  Mean 84.751 (notes-fidelity 86.448). t2100 75.423 vs their 97.538 is
  clock: golden `NOT AT REST` (1 view animating); leftover blob
  `[133.5, 597.5, 23, 21]` is the tab icon while ours is on the pushed
  note. Not a compact-header / `note.text` miss — t200 frames still match
  (header 38, blob `[326.5, 19, 21, 23]` search platter).
- Tabs light against committed `goldens/ios/hc-conformance-Tabs` into
  `/tmp/conformance-Tabs-merge-notesfid` (not `/tmp/hc-conformance-*`):
  t200 **96.652**, t1000 **99.402**, t3000 **96.892**, t4000 **96.345**,
  t5000 **96.627**, t6000 **87.482**, t7000 **92.529**, t2000 84.630,
  mean **93.820** — same as the board (`scoreboard/latest.md` / Tabs
  t200 96.65, mean 93.820 in tabs-rows).
- Catalyst **124/124**
- Real-app unchanged: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**
- Linux `swift:6.2-noble` `openrender` green (187.18 s)

No new rules. Catalyst paths stay behind the existing iOS cut.
