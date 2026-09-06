# Merge `origin/agent/uikit-lists-diffable` onto main

MERGE TASK, no new rules. Main (`3cec221a`) already carries values39e,
materials40c, textkit41c, pickers41c (shim TextKit-1 aliases, Package.swift
PhotosUI, fidelity-table rows). `origin/agent/uikit-lists-diffable`
(`38987f3c`, one commit on `e08c83a5`) adds UICollectionViewListCell +
UIListContentConfiguration / UIListContentView / UICellAccessory,
UICollectionLayoutListConfiguration, UIBackgroundConfiguration list
states, UICollectionViewDiffableDataSource +
NSDiffableDataSourceSectionSnapshot, swipe actions with iOS 26.1-measured
metrics, and two TableEditor screens (t5800 / t6800).

Never keep-both on Swift. `scoreboard/latest.*` and pin files stay main's.
`scripts/vendor_pins.sh`, `env/`, `scripts/env/` untouched.

Operator recaptures with `RECAPTURE_APPS="TableEditor TableEditor-ipad"`.

## File resolutions

| file | how it was resolved |
|---|---|
| `Sources/UIKitShim/UIKit.swift` | **Union.** Diffable aliases stay grouped: snapshot, incoming `NSDiffableDataSourceSectionSnapshot`, table diffable, incoming `UICollectionViewDiffableDataSource`, then main's TextKit-1 aliases (`NSAttributedString` … `NSLayoutManagerDelegate`). Every symbol each side exports, once. |
| `docs/REAL_APP_TEST.md` | Union newest-first: this merge row, then lists-diffable, then main's pickers / textkit / materials / values / transitions / urlsession / … |
| `Sources/OpenUIKit/UIContentConfiguration.swift` | Incoming file kept, but its second `NSDirectionalRectEdge` dropped. Main already defines the Hashable OptionSet in `AutoLayout/UILayoutGuide.swift`; keep-both does not compile (`invalid redeclaration`). |
| `Sources/openrender/SceneBuilder.swift`, `Tools/oracle/SceneKit.swift` | Auto-merged: main's TextKit attachment runs **and** incoming `listAppearance` / `SceneListDriver`. |
| `scoreboard/open.txt` | Auto-merged: incoming TableEditor t5800 rtl/ax1/xxxl/landscape OPEN rows on top of main. |
| `Package.swift` | Main (incoming did not touch it). New OpenUIKit sources are directory-globbed. |
| `Sources/PhotosUI/PhotosUI.swift`, `Sources/SafariServices/SafariServices.swift` | Main's pickers types. `@preconcurrency` added on `PHPickerViewControllerDelegate` and `SFSafariViewControllerDelegate` so Linux 6.2.4 `swift build --build-tests` can call them from a nonisolated XCTestCase the same way it calls `@preconcurrency @MainActor` UIView. No runtime change. |
| `Tests/OpenUIKitTests/ValueTypeTailTests.swift` | Main's values tests. `NotificationCenter.default` qualified as `OpenUIKit.NotificationCenter.default` — the same Linux corelibs ambiguity TextKitTests already named (`8b8c2a12`). |

Incoming sources that auto-merged (reviewed, no keep-both):
`UICellAccessory.swift`, `UICollectionViewListCell.swift`,
`UIListContentConfiguration.swift`, `UISwipeActions.swift`,
`UICollectionViewDiffableDataSource.swift`, list hooks in
`UICollectionView.swift` / `UICollectionViewCell.swift` /
`UICollectionViewCompositionalLayout.swift` / `UITableView.swift` /
`UITableViewCell.swift`, TableEditor list VC + `open-list` /
`select-list-0`, `ListCellDiffableTests.swift`, simscene freeze skip for
`listAppearance`. Report `docs/agent_reports/uikit-lists-diffable.md`
is added as-is.

`UIContentConfiguration` / `UIContentView` / `UIConfigurationState` are
`@preconcurrency @MainActor` so ListCellDiffableTests compiles on Linux
under `-swift-version 5` (same annotation UIView already carries).

## Proof

Mac (`SIM_DEVICE_SUFFIX=-merge-lists`):

- `swift test --filter ListCellDiffableTests`: **9 tests, 0 failures**
- Catalyst **124/124** (`/tmp/gate-merge-lists`)
- iOS suite `SKIP_CAPTURE=1` `/tmp/suite-merge-lists`: **112/113**, miss
  `corner_radius` (same as main)
- Real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.65 / 82.170 / 99.86 / 99.734 / 85.393**.
  `realapp_focus_home_light` and `realapp_ledger_light` missing goldens
  (same as sibling reports). `/tmp/app-merge-lists`.

`SKIP_CAPTURE=1` vs `/tmp/hc-conformance-TableEditor[-axis]` (t200–t4800;
t5800/t6800 were absent from those goldens → 0.000 missing):

| axis | t200 | worst t200–t4800 | vs incoming |
|---|---|---|---|
| light | 99.188 | t2350 **97.716** | held |
| dark | 98.823 | t2350.dark **96.729** (already OPEN) | held |
| rtl | 99.188 | t2350.rtl **97.712** | held |
| ax1 | 97.913 | t2350.ax1 **96.429** (OPEN edit disc) | held |
| xxxl | 98.053 | t2350.xxxl **96.875** (OPEN mid-flight) | held |
| landscape | 99.640 | t2350.landscape **97.990** | held |
| ipad | 99.901 | t2350 **98.936** | held |

Fresh capture of the two NEW screens (`scripts/conformance_flow.sh`,
iPhone SE 2x / iOS 26.1, plus iPad (A16) 820×1180 @2x). Every TableEditor
row:

| axis | t5800 | t6800 | t200–t4800 | ≥97.5 list |
|---|---|---|---|---|
| light | **98.822** | **98.675** | held (worst 97.716) | yes |
| dark | **98.846** | **98.704** | held (t2350.dark 96.729 OPEN) | list yes |
| ipad | **98.801** | **98.708** | held (t200 99.901) | yes |
| rtl | 96.549 | 96.402 | held | OPEN mirror |
| ax1 | 84.155 | 81.750 | held | OPEN dyntype |
| xxxl | 78.078 | 77.166 | held | OPEN dyntype |
| landscape | 85.639 | 77.301 | held | OPEN compact bar |

Identical to `docs/agent_reports/uikit-lists-diffable.md`. Residuals stay
in `scoreboard/open.txt`.

Linux:

- `docker exec -w /work-merge-lists uikit-linux`: `swift build --product
  openrender` complete; `--target ConformanceApps` complete;
  `swift build --build-tests` complete (48.32 s after the
  `@preconcurrency` / NotificationCenter qualify).
- `docker run --rm swift:6.2-noble` openrender **complete (234.97 s)**.

No `Package.resolved`. Nothing outside `uikit/`. No unguarded
`import Foundation` / `import Dispatch` in library sources.
