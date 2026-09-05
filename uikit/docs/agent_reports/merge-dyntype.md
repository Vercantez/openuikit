# Merge `origin/agent/conf-dyntype` onto main (RTL + Dynamic Type axes)

Main (863d90df) already carries `--rtl` (`origin/agent/conf-rtl`).
`origin/agent/conf-dyntype` added `--ax1` / `--xxxl` with the same plumbing
shape. This merge keeps **both** axes side by side. No new rendering rules.

Suffix order is `.dark` then `.rtl` then `.ax1` / `.xxxl`. Every function
that took one axis now takes both. Scripts accept `--ipad --dark --rtl
--ax1 --xxxl`, export both env vars, and register every work dir.

## File resolutions

| file | how it was resolved |
|---|---|
| `Sources/ConformanceApps/ConformanceRegistry.swift` | `captureSuffix(for:style:direction:contentSize:)` with suffix order `.dark` / `.rtl` / `.ax1` / `.xxxl`. Both `resolvedDirection(script:environment:)` and `resolvedContentSize(environment:)` plus `contentSizeCategory(for:)`. |
| `Sources/openhost/AppMode.swift` | `HostAppDelegate` and `buildAppScene` take **both** `rtl` and `contentSizeCategory`. Window gets `traitOverrides.preferredContentSizeCategory` and, when rtl, appearance + `semanticContentAttribute` before `makeRoot()`. |
| `Sources/openhost/ConformanceMode.swift` | `runConformanceScripted` / `captureConformance` take both `direction` and `contentSize`. Layout dump writes both keys. `parseConformanceScript` still reads `"direction"` from script.json (content-size stays env-only, as the dyntype branch measured). |
| `Sources/openhost/main.swift` | Resolves `OPENUIKIT_APP_STYLE`, `OPENUIKIT_APP_DIRECTION`, and `OPENUIKIT_APP_CONTENT_SIZE`. Passes both into `buildAppScene` and `runConformanceScripted`. Live `--app` does the same. |
| `Tools/oracle2/confprobe/main.swift` | `loadScript()` returns `style, direction, contentSize`. Appearance+window RTL pin **and** `traitOverrides` content-size pin before `makeRoot()`. Capture suffix and JSON dump carry both. |
| `scripts/conformance_flow.sh` | Flags `--ipad --dark --rtl --ax1 --xxxl`. Exports `CONFPROBE_DIRECTION` / `OPENUIKIT_APP_DIRECTION` and `CONFPROBE_CONTENT_SIZE` / `OPENUIKIT_APP_CONTENT_SIZE`. `summary.json` has both `direction` and `contentSize`. Python suffix order matches `captureSuffix`. |
| `scripts/conformance_probe_sim.sh` | Forwards both `SIMCTL_CHILD_CONFPROBE_DIRECTION` and `SIMCTL_CHILD_CONFPROBE_CONTENT_SIZE`. |
| `scripts/hillclimb.sh` | Registers `/tmp/hc-conformance-<App>-rtl`, `-ax1`, and `-xxxl` next to `-ipad` and `-dark`. Recapture loop runs all five extra axes. |
| `scripts/agent_merge.sh` | Per-axis re-render blocks for ipad, dark, rtl, ax1, xxxl, **each closed with its own `fi`**. |
| `scripts/scoreboard.py` | Row keys chain `App` then `.dark` then `.rtl` then `.ax1`/`.xxxl`; iPad stays `App-ipad` (the summary app field). Combinations follow that order (`App.dark.rtl.ax1`, `App-ipad.dark`, …). Chaining uses `key = key + …` so `-ipad` is not dropped (the dyntype side had `key = app + ".dark"`). |
| `Tests/OpenUIKitTests/ConformanceRegistryTests.swift` | Both test sets kept (`testRTLCaptureSuffixAndDirectionResolution` and `testContentSizeCaptureSuffixAndResolution`). Added `t200.dark.rtl.ax1` for the combined order. |
| `Sources/OpenUIKit/UINavigationBar.swift` | Large-title frame keeps **main's RTL x** (`bounds.width − largeTitleX − w`) **and** the branch's `effectiveLargeTitleLabelY` / `effectiveLargeTitleLabelHeight`. |
| `docs/HILLCLIMB.md` | Documents `--rtl` and `--ax1`/`--xxxl`, combined suffix order, and all work dirs. |
| `docs/REAL_APP_TEST.md` | Both fidelity-table rows kept (RTL on top, then Dynamic Type), plus main's iPad-rest / tabs-rows / glass-platter rows that sat between them. |

Incoming dyntype sources that auto-merged (no conflict): `UIBarButtonItem.swift`,
`UIColor.swift`, `UIDatePicker.swift`, `UIEvent.swift`, `UIFontMetrics.swift`,
`UINavigationController.swift`, `UITableView.swift`, `UITableViewCell.swift`,
`UIView.swift`, and the matching unit tests. Report
`docs/agent_reports/conf-dyntype.md` is added as-is.

## Proof (this merge)

- `swift build -c release --product openrender` / `--product openhost` green
- `swiftc` of `Tools/oracle2/confprobe/main.swift` + ConformanceApps against
  the iOS simulator SDK green (the probe is not an SPM product)
- `swift test --filter ConformanceRegistry`: 7 tests, 0 failures (RTL +
  content-size + combined `t200.dark.rtl.ax1`)
- `SKIP_CAPTURE=1 … NavFlow --rtl`: worst **97.812**, mean **98.960**,
  t200.rtl **99.599** — same as `docs/agent_reports/conf-rtl.md`
- `SKIP_CAPTURE=1 … Forms --ax1`: worst **98.176**, mean **98.214** — same
  as `docs/agent_reports/conf-dyntype.md`
- light `SKIP_CAPTURE=1` NavFlow: t200 **99.622**, worst **98.196**, mean
  **99.036** — unchanged from the pre-merge summary
- Linux `swift:6.2-noble` `openrender` green
- Catalyst gate 124/124

No new rules. Catalyst paths stay behind the existing iOS cut.
