# Merge `origin/agent/conf-landscape` onto main (RTL + Dynamic Type + landscape)

Main (61aebd8d) already carries `--rtl` and `--ax1` / `--xxxl`
(`docs/agent_reports/merge-dyntype.md`). `origin/agent/conf-landscape`
added `--landscape` with the same plumbing shape. This merge keeps
**all** axes side by side. No new rendering rules.

Suffix order is `.dark` then `.rtl` then `.ax1` / `.xxxl` then
`.landscape`. Every function that took style, direction and contentSize
now also takes orientation. Scripts accept `--ipad --dark --rtl --ax1
--xxxl --landscape`, export every env var, and register every work dir
(`/tmp/hc-conformance-<App>-landscape`). Scoreboard key `App.landscape`.

Measured landscape constants kept with their sample comments: bar y **24**
in compact height (`UINavigationBar.iOSCompactHeightBarTop`), collapsed
large titles (`displaysLargeTitles`), compact-height pageSheet top inset
**0** and `.medium()` → large frame, landscape window **667×375** and
`phoneLandscapeSafeArea = .zero` (NavFlow t200.landscape dump
`windowSafeArea [0,0,0,0]`, iPhone SE 2x / iOS 26.1).

## File resolutions

| file | how it was resolved |
|---|---|
| `Sources/ConformanceApps/ConformanceRegistry.swift` | `captureSuffix(for:style:direction:contentSize:orientation:)` with suffix order `.dark` / `.rtl` / `.ax1` / `.xxxl` / `.landscape`. `resolvedContentSize` / `contentSizeCategory(for:)` **and** `resolvedOrientation(script:environment:)`. |
| `Sources/openhost/AppMode.swift` | Auto-merged. `HostAppDelegate` / `buildAppScene` keep main's `rtl` + `contentSizeCategory`. Landscape uses `conformanceLandscape` (667×375, compact-compact traits, `phoneLandscapeSafeArea`). |
| `Sources/openhost/ConformanceMode.swift` | `parseConformanceScript` still reads `"orientation"` from script.json (content-size stays env-only). `runConformanceScripted` / `captureConformance` take both `contentSize` and `orientation`. Layout dump writes both keys. |
| `Sources/openhost/main.swift` | Resolves `OPENUIKIT_APP_STYLE`, `OPENUIKIT_APP_DIRECTION`, `OPENUIKIT_APP_CONTENT_SIZE`, and `OPENUIKIT_APP_ORIENTATION`. Landscape sets `conformanceLandscape`. Passes all four into `runConformanceScripted`. |
| `Tools/oracle2/confprobe/main.swift` | `loadScript()` returns `style, direction, contentSize, orientation`. Appearance+window RTL pin, `traitOverrides` content-size pin, **and** `requestGeometryUpdate(.landscapeLeft)` + wait-until-wide before `startLink`. Capture suffix and JSON dump carry every axis. |
| `scripts/conformance_flow.sh` | Flags `--ipad --dark --rtl --ax1 --xxxl --landscape`. Exports direction, content-size, and orientation env vars. `summary.json` has `direction`, `contentSize`, and `orientation`. Python suffix order matches `captureSuffix`. Probe args forward `--landscape`. |
| `scripts/conformance_probe_sim.sh` | Forwards `SIMCTL_CHILD_CONFPROBE_DIRECTION`, `SIMCTL_CHILD_CONFPROBE_CONTENT_SIZE`, and `SIMCTL_CHILD_CONFPROBE_ORIENTATION`. Landscape uses `ConfProbe-Landscape-Info.plist` and restores portrait after copy. |
| `scripts/hillclimb.sh` | Registers `/tmp/hc-conformance-<App>-rtl`, `-ax1`, `-xxxl`, and `-landscape` next to `-ipad` and `-dark`. Recapture loop runs all extra axes. |
| `scripts/agent_merge.sh` | Per-axis re-render blocks for ipad, dark, rtl, ax1, xxxl, landscape, **each closed with its own `fi`**. |
| `scripts/scoreboard.py` | Row keys chain `App` then `.dark` then `.rtl` then `.ax1`/`.xxxl` then `.landscape`; iPad stays `App-ipad` (the summary app field). Chaining uses `key = key + …` so `-ipad` is not dropped. |
| `Tests/OpenUIKitTests/ConformanceRegistryTests.swift` | Main's tests plus the branch's: `testContentSizeCaptureSuffixAndResolution` and `testLandscapeCaptureSuffixAndOrientationResolution`. Added `t200.dark.rtl.ax1.landscape` for the combined order. |
| `Tests/OpenUIKitTests/IOSDevicePixelMetricsTests.swift` | Main's `testPadPageSheetTopInsetIsFortyTwo` plus the branch's `testCompactHeightPageSheetFillsTheWindow`. |
| `Sources/OpenUIKit/UINavigationBar.swift` | Compact-height overlay is 54 (`isCompactHeight` → `iOSBarContentHeight`). Inline title uses `displaysLargeTitles` **and** main's `effectiveLargeTitleZoneHeight`. |
| `Sources/OpenUIKit/UINavigationController.swift` | `bindContentScrollView` uses `displaysLargeTitles` **and** `effectiveLargeTitleExpandedInset`. `iOSBarTop` floor 24 when compact (sample comment kept). |
| `Sources/OpenUIKit/UIPresentation.swift` | Compact-height `topInset` **0** first, then main's pad 42. `.medium()` still returns nil in compact height. |
| `docs/HILLCLIMB.md` | Documents `--rtl`, `--ax1`/`--xxxl`, and `--landscape`, combined suffix order, and all work dirs. |
| `docs/REAL_APP_TEST.md` | Landscape fidelity-table row on top, then main's iPad-open / symbols-harvest / … rows. |

Incoming landscape sources that auto-merged (no conflict):
`RealAppScreen.swift` (`windowSizePhoneLandscape` / `phoneLandscapeSafeArea`),
`ChromeControllerTests.swift` (`testCompactHeightCollapsesLargeTitlesAndRaisesBarTop`),
`ConfProbe-Landscape-Info.plist`, `goldens_snapshot.sh`. Report
`docs/agent_reports/conf-landscape.md` is added as-is.

## Proof (this merge)

- `swift build --build-tests` green
- `swift test --filter ConformanceRegistry`: 8 tests, 0 failures (RTL +
  content-size + landscape + combined `t200.dark.rtl.ax1.landscape`)
- `testCompactHeightCollapsesLargeTitlesAndRaisesBarTop` and
  `testCompactHeightPageSheetFillsTheWindow` pass
- `SKIP_CAPTURE=1 … NavFlow --landscape`: worst **96.053**, mean **97.641**,
  t200.landscape **96.707**, t3000.landscape **98.193** — same as
  `docs/agent_reports/conf-landscape.md`
- `SKIP_CAPTURE=1 … NavFlow --rtl`: t200.rtl **99.599**, t3900.rtl **98.788**
  (blob 58.8) — same as `docs/agent_reports/conf-rtl.md`. Worst **97.171**
  / mean **98.788** match `scoreboard/latest.json` (`NavFlow:t3000.rtl`
  97.171); later main glass/symbol rows moved the original report's
  97.812 / 98.960 worst/mean
- `SKIP_CAPTURE=1 … Forms --ax1`: worst **98.176**, mean **98.214** — same
  as `docs/agent_reports/conf-dyntype.md`
- Linux `swift:6.2-noble` `openrender` green
- Catalyst gate **124/124**
- Real-app screens unchanged: **99.137 / 98.535 / 98.548 / 99.469 /
  98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**

No new rules. Catalyst paths stay behind the existing iOS cut.
No `Package.resolved`.
