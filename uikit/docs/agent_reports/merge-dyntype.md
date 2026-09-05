# Merge `origin/agent/dyntype-rest` onto main

MERGE TASK, no new rules. Main already carries landscape / Notes / symbol
masks / the guest app path / the dependency trial, plus `--rtl` and
`--ax1` / `--xxxl`. `origin/agent/dyntype-rest` (5ee8de01) measured the
remaining Dynamic Type chrome on NavFlow / Modal / Tabs / Pager / Notes
at `.accessibilityLarge` (iPhone SE 2x / iOS 26.1). This merge keeps
**main's plumbing exact** and the branch's **measured iOS-cut rules**.

Pin files (`scripts/vendor_pins.sh`, `env/`, `scripts/env/`) and
`scoreboard/latest.*` stay main's. No `Package.resolved`.

## File resolutions

| file | how it was resolved |
|---|---|
| `Sources/ConformanceApps/ConformanceRegistry.swift` | Main. Already has `captureSuffix(..., contentSize:, orientation:)` with suffix order `.dark` / `.rtl` / `.ax1` / `.xxxl` / `.landscape`, plus `resolvedContentSize` / `contentSizeCategory(for:)` / `resolvedOrientation`. |
| `Sources/openhost/AppMode.swift`, `ConformanceMode.swift`, `main.swift` | Main. Axes already include content-size and landscape. |
| `Tools/oracle2/confprobe/main.swift` | Main. |
| `scripts/conformance_flow.sh`, `conformance_probe_sim.sh`, `hillclimb.sh`, `agent_merge.sh`, `scoreboard.py` | Main. `--landscape` sits after `--ax1` / `--xxxl`; per-axis `fi` blocks kept. |
| `Tests/OpenUIKitTests/ConformanceRegistryTests.swift` | Main's file (never keep-both). Content-size tests already cover the branch's `testAx1CaptureSuffixAndContentSizeResolution`; landscape tests stay. |
| `Tests/OpenUIKitTests/IOSDevicePixelMetricsTests.swift` | Main's `testCompactHeightBarTop` **plus** the branch's ax1 assertions (48 / 57.5 / 54 / 115.5 / 125.5, row 80, alert 33/30/63.5, window-join restyle 34→48). |
| `Sources/OpenUIKit/UIColor.swift` | Same `UITraitOverrides` type. Comment is the branch measurement: construction-time `preferredFont(forTextStyle:)` stays `.large`; descendant `view.traitCollection` sees the window override (Pager / Notes / Feed t200.ax1). |
| `Sources/OpenUIKit/UIEvent.swift` | Main already stamped `traitOverrides` onto the window collection; keep the branch's sample comment. |
| `Sources/OpenUIKit/UINavigationBar.swift` | Main's `displaysLargeTitles` / `effectiveLargeTitle*` / compact-height overlay **and** the branch's `compatibleWith:` helpers (`largeTitleFont` 48 Bold, zone `max(52, labelH+4)`, bar 115.5, inset 125.5). `iOSLargeTitleBarHeight` stays the `.large` constant **106**. `updateFromScroll` still gates on `displaysLargeTitles` and re-styles via `applyTitleAttributes()` (NavFlow t200.ax1 Library `[16, 64, 156, 57.5]`). |
| `Sources/OpenUIKit/UINavigationController.swift` | Main (`displaysLargeTitles` + `effectiveLargeTitleExpandedInset`). |
| `Sources/OpenUIKit/UISearchBar.swift` | Main's RTL nav-inline dismiss (Tabs t4000.rtl field `[71, 18, 288, 44]`) with the branch's scaled field height `d` (80 at ax1, 44 at `.large`). |
| `Sources/OpenUIKit/UITableViewCell.swift` | Main's `applyIOSPreferredFonts` / subtitle fitting **117** at ax1, plus the branch's classic `.default` / `.value1` / `.value2` body fonts (NavFlow t200.ax1 33/39.5; Tabs t200.ax1 33). |
| `docs/REAL_APP_TEST.md` | Branch dyntype-rest row on top, then main's Hackers dep-trial / landscape / guest-app / … rows. |
| `scoreboard/open.txt` | Both sides: ax1 OPEN lines, then main's RTL OPEN lines. |

Incoming dyntype-rest sources that auto-merged (no conflict):
`UIAlertController.swift` (alert 33/30/63.5), `UITableView.swift`
(`plainClassicRowHeight(compatibleWith:)`), `UIView.swift` (view-level
`traitOverrides`), `TraitCollectionTests.swift`. Report
`docs/agent_reports/dyntype-rest.md` is added as-is.

## Proof (this merge)

Goldens for SKIP_CAPTURE were copied into `/tmp/conformance-*` (committed
`goldens/ios` for Forms-ax1 and NavFlow-rtl; read-only copies of the round
dirs for Notes/Tabs ax1/xxxl, Forms-xxxl, NavFlow-landscape). Never wrote
into `/tmp/hc-conformance-*`.

| run | this merge | report to match | Δ |
|---|---|---|---|
| Notes `--ax1` | worst **52.170**, mean **81.791** | dyntype-rest 52.009 / 81.592 | +0.161 / +0.199 |
| Tabs `--ax1` | worst **82.739**, mean **92.408**; t200.ax1 **96.546** | 82.614 / 92.352; t200.ax1 96.421 | +0.125 / +0.056 |
| Forms `--ax1` | worst **98.176**, mean **98.214** | conf-dyntype / merge-landscape **98.176 / 98.214** (dyntype-rest's 98.563/98.601 was a later `/tmp` re-run; committed `goldens/ios/hc-conformance-Forms-ax1` matches the original axis) | 0 |
| Notes `--xxxl` | worst **58.890**, mean **82.773** | (axis run; no named bar in dyntype-rest) | — |
| Forms `--xxxl` | worst **98.489**, mean **98.527** | — | — |
| Tabs `--xxxl` | worst **84.641**, mean **91.436** | — | — |
| NavFlow `--landscape` | worst **96.053**, mean **97.641**; t200.landscape **96.707**, t3000.landscape **98.193** | merge-landscape.md | 0 |
| NavFlow `--rtl` | worst **97.812**, mean **98.960**; t200.rtl **99.599**, t3900.rtl **98.788** blob 58.8 | conf-rtl.md | 0 |

- `swift build --build-tests` green
- `swift test --filter 'ConformanceRegistry|DynamicType|Trait'`: 64 tests, 0 failures
- `IOSDevicePixelMetricsTests` (including the new ax1 cases): pass
- Catalyst gate **124/124**
- Real-app screens unchanged: **99.137 / 98.535 / 98.548 / 99.469 /
  98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**
- Linux `swift:6.2-noble` `openrender` green (183.66 s)

`git log origin/main..agent/merge-dyntype` shows the dyntype-rest commit
(5ee8de01) plus the merge commits. No new rules. Catalyst paths stay
behind the existing iOS cut.
