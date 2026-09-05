# Merge `origin/agent/linux-env` onto main (bash-portable agent scripts)

MERGE TASK, no new rules. Main (`61aebd8d`) already carries `--rtl`,
`--ax1` / `--xxxl` (and `--ipad` / `--dark`), ALLOW_PATHS / ALLOW_DROP /
RECAPTURE_APPS / `swift build --build-tests` in `agent_merge.sh`, and
`/tmp/hc-conformance-<App>-{ipad,dark,rtl,ax1,xxxl}` in `hillclimb.sh`.
`origin/agent/linux-env` (`dc5d2536`) made those five scripts bash, plus
`linux_setup.sh`, `Dockerfile.linux-agent`, iOS-cut mask-only text without
SFNS, and the Linux XCTest bundle fix.

This merge keeps **main's current behaviour of every script exactly**
(every axis flag and work dir, every merge check) **and** the branch's
portability (`#!/usr/bin/env bash`, directory scan instead of zsh
`*(/N)` / `*(/:t)`, `[` tests, bash arrays). `--landscape` is not on
this main; it was not invented here.

## File resolutions

| file | how it was resolved |
|---|---|
| `scripts/gen_conformance_registry.sh` | Auto-merged: linux-env bash (main had not touched it). Directory scan, 8 apps byte-identical. |
| `scripts/conformance_flow.sh` | bash shebang. Flags `--ipad --dark --rtl --ax1 --xxxl`. Exports direction + content-size. `summary.json` keeps both keys. SKIP_CAPTURE restore is main's ipad/dark setname, written as a bash glob. Python still gets `"$DIRECTION" "$CONTENT_SIZE"`. |
| `scripts/ios_suite.sh` | bash + `read_lines` / `split_scenes`. **Always** materialises the 2x/3x scene split (main / goldens-commit). SKIP_CAPTURE restore is bash. Capture still shells out to zsh `render_sim_scenes.sh`. |
| `scripts/hillclimb.sh` | bash. Recapture loop runs all five extra axes (`--ipad --dark --rtl --ax1 --xxxl`). Score registration walks the same six work dirs. Goldens restore kept. |
| `scripts/agent_merge.sh` | Auto-merged, then the leftover zsh in the rtl/ax1/xxxl blocks (`${=RECAPTURE_APPS}`, `[[ ]]`, `zsh scripts/conformance_flow.sh`) rewritten to the same bash as ipad/dark. ALLOW_PATHS / ALLOW_DROP / RECAPTURE_APPS / test-bundle check kept. |
| `Tests/OpenUIKitTests/ConformanceRegistryTests.swift` | Main's RTL + content-size tests plus linux-env's bash generator (`/bin/bash` / `Glibc.system` on Linux) and `#if !os(Linux) @MainActor` on `testRegistryHasEveryScannedApp`. Combined `t200.dark.rtl.ax1` kept. |
| `docs/REAL_APP_TEST.md` | linux-env row newest, then main's ipad-open / symbols-harvest / … rows. |
| font-mask / test-bundle | Unconflicted from linux-env: `GlyphInkTable.iosMaskKey` / `OPENUIKIT_IOS_INK_MISS`, `UILabel` / `AttributedTextDraw` iOS-table-without-TTF, `Package.swift` Linux SwiftUITests stub + `-swift-version 5`, `SwiftUILinuxStub.swift`, `#if !os(Linux) @MainActor` wraps. `scripts/linux_setup.sh`, `Dockerfile.linux-agent` added as-is. |

Incoming linux-env sources that auto-merged (no conflict): the rest of
`Tests/OpenUIKitTests/*` and `Tests/SwiftUITests/*` isolation wraps
(main's named tests kept), `docs/PORTABILITY.md`,
`scripts/linux_realapp_verify.sh`. Report `docs/agent_reports/linux-env.md`
is added as-is.

## Proof (this merge)

Mac (`SIM_DEVICE_SUFFIX=-merge-linuxenv`):

- `bash -n` of the five scripts: ok
- `swift build --build-tests`: Build complete
- `swift test --filter ConformanceRegistry`: **7 tests, 0 failures** (RTL +
  content-size + combined `t200.dark.rtl.ax1` + bash regenerator)
- `swift test --filter GlyphInkTableTests --filter ConformanceRegistry`:
  21 tests, 0 failures
- `SKIP_CAPTURE=1 … /tmp/hc-conformance-NavFlow NavFlow`: t200 **99.622**,
  worst **98.196**, mean **99.036** — same as the pre-merge summary /
  goldens-commit / conf-rtl LTR
- `SKIP_CAPTURE=1 … /tmp/hc-conformance-NavFlow-rtl NavFlow --rtl`:
  t200.rtl **99.599**, t3900.rtl **98.788** blob 58.8, t3000.rtl **97.171**
  blob 58.8, worst **97.171**, mean **98.788** — same as
  `scoreboard/latest.json` (`NavFlow:t3000.rtl` 97.171). conf-rtl.md's
  older worst 97.812 is the pre-symbols-harvest board; this main already
  sat at 97.171
- Catalyst **124/124** (`/tmp/gate-merge-linuxenv`)
- real-app unchanged vs this main: **99.137 / 98.535 / 98.548 / 99.469 /
  98.639 / 98.133 / 97.516 / 99.511 / 99.760 / 99.689 / 82.170 / 85.393**

`docker exec -w /work-merge uikit-linux` (`swift:6.2-noble`; tree tarred
excluding `.build` / `Package.resolved`; `OPENUIKIT_FONT_DIR=/agent/fonts`):

- `bash -n` of the five scripts: ok
- `bash scripts/gen_conformance_registry.sh /tmp/Registry-merge.swift &&
  diff`: **8 app(s): Feed, Forms, Modal, NavFlow, Notes, Pager,
  TableEditor, Tabs** — byte-identical to checked-in `Registry.swift`
- `SKIP_CAPTURE=1 bash scripts/conformance_flow.sh /tmp/conformance-NavFlow
  NavFlow`: worst **98.196**, mean **99.036** (6 captures) — same as Mac
- Catalyst in-container **124/124**
- real-app in-container same twelve scores as Mac

No `Package.resolved`. No files outside `uikit/`. No new rendering rules.
Catalyst paths stay behind the existing iOS cut.
