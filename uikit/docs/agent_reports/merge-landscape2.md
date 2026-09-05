# Merge `origin/agent/landscape2-merged` onto main (bash-portable + landscape)

MERGE TASK, no new rules. Main already carries the bash-portable agent
scripts (`docs/agent_reports/merge-linuxenv.md`, `linux-env.md`) with
`--ipad --dark --rtl --ax1 --xxxl`. `origin/agent/landscape2-merged`
(`107759d0`) added `--landscape` on the pre-linux-env zsh scripts and
reconciled it once with rtl/ax1 (`docs/agent_reports/merge-landscape.md`,
`conf-landscape.md`). This merge keeps **main's current behaviour of
every script exactly** (bash-portable, every axis flag and work dir,
every merge check) **and** adds the landscape axis the way the other
axes are: flag `--landscape`, `/tmp/hc-conformance-<App>-landscape`,
`agent_merge.sh` re-render block with its own `fi`, scoreboard key
`App.landscape`, ConformanceClock suffix order `.dark` `.rtl`
`.ax1`/`.xxxl` `.landscape`.

Pin files (`env/`, `scripts/env/`, `scripts/vendor_pins.sh`) stay
main's. No new rendering rules.

## File resolutions

| file | how it was resolved |
|---|---|
| `env/contract.json`, `scripts/env/test_contract.py`, `scripts/vendor_pins.sh` | **ours (main)**. Landscape2-merged's last commit already tried to keep main's pins; main has since advanced them. |
| `scripts/conformance_flow.sh` | bash shebang. Flags `--ipad --dark --rtl --ax1 --xxxl --landscape`. Exports direction, content-size, **and** orientation. `summary.json` has all three keys plus `orientation`. SKIP_CAPTURE restore is bash `[` tests; setname appends `-ipad`/`-dark`/`-rtl`/`-ax1`/`-xxxl`/`-landscape`. Probe/host args are bash arrays; `--landscape` is forwarded next to `--ipad`. Python still gets `"$DIRECTION" "$CONTENT_SIZE" "$ORIENTATION"`. Capture still shells out to zsh `conformance_probe_sim.sh`. |
| `scripts/hillclimb.sh` | bash. Recapture loop runs all six extra axes including `--landscape`. Score registration walks the same seven work dirs (`-ipad -dark -rtl -ax1 -xxxl -landscape`). Directory scan, not zsh `*(/:t)`. |
| `scripts/agent_merge.sh` | Auto-merged, then the leftover zsh in the landscape block (`${=RECAPTURE_APPS}`, `[[ ]]`, `zsh scripts/conformance_flow.sh`) rewritten to the same bash as ipad/dark/rtl/ax1/xxxl, **closed with its own `fi`**. ALLOW_PATHS / ALLOW_DROP / RECAPTURE_APPS / test-bundle check kept. |
| `scripts/ios_suite.sh` | Unconflicted from main (bash + `read_lines` / `split_scenes`). Landscape is not an iOS-suite axis. |
| `Tests/OpenUIKitTests/ConformanceRegistryTests.swift` | Main's RTL + content-size tests plus linux-env's bash generator (`/bin/bash` / `Glibc.system` on Linux) and `#if !os(Linux) @MainActor` on `testRegistryHasEveryScannedApp`, **plus** the branch's `testLandscapeCaptureSuffixAndOrientationResolution` (combined `t200.dark.rtl.ax1.landscape`). |
| `docs/REAL_APP_TEST.md` | Landscape fidelity-table row newest, then main's linux-env / rtl-rest / ipad-open / … rows. |
| Compact-height rules | Unconflicted from landscape2-merged: `UINavigationBar` bar y **24** / collapsed large titles; `UIPresentation` compact-height pageSheet top inset **0** and `.medium()` → large frame; `RealAppScreen.windowSizePhoneLandscape` 667×375 and `phoneLandscapeSafeArea = .zero`. Comments keep the NavFlow t200.landscape sample. |

Incoming landscape sources that auto-merged (no conflict):
`ConformanceRegistry.swift` (`resolvedOrientation` / suffix `.landscape`),
`AppMode.swift` / `ConformanceMode.swift` / `main.swift` (`--landscape`,
`conformanceLandscape`), `ChromeControllerTests.swift`
(`testCompactHeightCollapsesLargeTitlesAndRaisesBarTop`),
`IOSDevicePixelMetricsTests.swift` (`testCompactHeightPageSheetFillsTheWindow`
kept next to main's `testPadPageSheetTopInsetIsFortyTwo`),
`conformance_probe_sim.sh` (still zsh; `--landscape` +
`ConfProbe-Landscape-Info.plist`), `scoreboard.py` (`App.landscape`),
`goldens_restore.sh` / `goldens_snapshot.sh` comments. Report
`docs/agent_reports/conf-landscape.md` is added as-is.

## Proof (this merge)

Mac (`SIM_DEVICE_SUFFIX=-merge-landscape2`):

- `bash -n` of `conformance_flow.sh` / `hillclimb.sh` / `agent_merge.sh` /
  `ios_suite.sh` / `gen_conformance_registry.sh`: ok
- `swift build --build-tests`: Build complete
- `swift test --filter ConformanceRegistry`: **8 tests, 0 failures** (RTL +
  content-size + landscape + combined `t200.dark.rtl.ax1.landscape` + bash
  regenerator)
- `testCompactHeightCollapsesLargeTitlesAndRaisesBarTop` and
  `testCompactHeightPageSheetFillsTheWindow`: pass
- `SKIP_CAPTURE=1 … /tmp/hc-conformance-NavFlow-landscape NavFlow --landscape`:
  t200.landscape **96.707**, t1200 **99.089**, t2100 **97.000**, t3000
  **98.193**, t3900 **98.806**, t4800 **96.053**, worst **96.053**, mean
  **97.641** — same as `docs/agent_reports/conf-landscape.md`
- `SKIP_CAPTURE=1 … /tmp/hc-conformance-NavFlow-rtl NavFlow --rtl`:
  t200.rtl **99.599**, t3900.rtl **98.788** blob 58.8, t3000.rtl **97.171**
  blob 58.8, worst **97.171**, mean **98.788** — same as
  `docs/agent_reports/merge-linuxenv.md` / `scoreboard/latest.json`
  (`NavFlow:t3000.rtl` 97.171). Unchanged.
- Catalyst **124/124** (`/tmp/gate-merge-landscape2`)
- real-app unchanged vs this main: **99.137 / 98.535 / 98.548 / 99.469 /
  98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**

`docker exec -w /work-merge-landscape2 uikit-linux` (`swift:6.2-noble`;
tree tarred excluding `.build` / `Package.resolved`;
`OPENUIKIT_FONT_DIR=/agent/fonts`):

- `bash -n` of the five scripts: ok
- `bash scripts/gen_conformance_registry.sh /tmp/Registry-merge-landscape2.swift &&
  diff`: **8 app(s): Feed, Forms, Modal, NavFlow, Notes, Pager,
  TableEditor, Tabs** — byte-identical to checked-in `Registry.swift`
- `SKIP_CAPTURE=1 bash scripts/conformance_flow.sh /tmp/hc-conformance-NavFlow-linuxpath
  NavFlow`: worst **98.196**, mean **99.036** (6 captures, `orientation=portrait`)
  — same as Mac goldens-commit / merge-linuxenv LTR
- Catalyst in-container **124/124**
- `swift build -c release --product openrender`: Build of product
  'openrender' complete

Clean `docker run --rm -v "$PWD":/src:ro swift:6.2-noble` (`.build` and
`Package.resolved` removed after copy): **Build of product 'openrender'
complete** (192.30 s).

No `Package.resolved`. No files outside `uikit/`. No new rendering rules.
Catalyst paths stay behind the existing iOS cut.
