# Merge `origin/agent/focus-e2e` onto main

MERGE TASK, no new rules. Main (`45f6395b`) already carries
`agent/combine-merged` (Combine and `os` as package products,
`Sources/Combine/Combine.swift`, ingest emission, report
`combine-product.md`) and `agent/presentable-merged` (SafariServices /
MessageUI / LinkPresentation + the Present app) plus the round-15 board.
`origin/agent/focus-e2e` (`300dd9ca`, three commits) is the Focus/Blockzilla
exam: ingest → Linux build census → home screen.

`agent/silent-merged` has **not** landed: `Package.swift` is still a single
`products:` / `targets:` array.

This merge keeps **one Combine module** (main's combine-product file as the
base, plus focus-e2e's Darwin non-empty-module enum and the linux-only
`.product` condition the ingest emits), **one `os` product**, the harness-stub
products focus-e2e publishes, presentable products from main, the 13th
real-app screen `realapp_focus_home_light`, and both fidelity-table rows.
`scoreboard/latest.*` and pin files stay main's. Never keep-both on Swift
code.

## File resolutions

| file | how it was resolved |
|---|---|
| `Sources/Combine/Combine.swift` | Main's combine-product body and 17/20-ladder comment, plus focus-e2e's `else { enum _OpenUIKitCombineProduct {} }` so Darwin `swift build --product Combine` is not an empty module. Both reports cited in the header. |
| `Package.swift` | Presentable libraries (SafariServices / MessageUI / LinkPresentation) **and** Combine **and** `os` **and** Glean / Intents / IntentsUI / Onboarding / Licenses / DesignSystem. One Combine product, one `os` product. `os` target + `OSTests` from main. RealAppProbe `exclude` keeps focus-e2e's `"Focus/script.json"`. ConformanceApps still depends on the presentable modules. |
| `Tools/ingest/xcodeproj_to_package.py` | `PORTED_PRODUCTS` is Combine + `os` (combine-product) **and** the six harness stubs (focus-e2e). Generated packages list linux-conditioned `.product` for all of them. `os` stays Foundation-heavy, not a toolchain module. |
| `Tools/ingest/test_xcodeproj_to_package.py` | Main's `test_combine_and_os_are_ported_products` plus `assertNotIn("os", no_port)`; emit asserts both `os` and `Glean`. |
| `docs/REAL_APP_TEST.md` | Focus-e2e row newest, then presentable, then Combine/`os`. |
| Focus home wiring | Unconflicted from focus-e2e: `FocusScreens` / `FocusShims` / vendored `HomeViewController`, `realapp_focus_home_light` in `compare_realapp.py` and `RealAppScreen.screens`. |

Incoming focus-e2e sources that auto-merged (no conflict):
`docs/agent_reports/focus-e2e.md`, `focus_home.t200.png`, wordmark assets,
`scripts/realapp_probe_sim.sh`. Report `docs/agent_reports/focus-e2e.md` is
added as-is.

## Proof (this merge)

- `swift package describe --type json`: **one** Combine, **one** `os`, plus
  Glean / Intents / IntentsUI / Onboarding / Licenses / DesignSystem /
  SafariServices / MessageUI / LinkPresentation. Elapsed **1.031 s** (< 20 s).
- `swift build --build-tests`: Build complete (42.52 s).
- `swift test --filter 'Ingest|Combine|Focus'`: **29 tests, 0 failures**.
- `python3 -m pytest Tools/ingest -q` with
  `LADDER_CORPUS=/Users/miguelsalinas/openuikit/scratch/ladder-corpus`:
  **34 passed**.
- Re-ingest of mozilla-mobile/focus-ios `a2832521` Blockzilla (same command
  as `docs/agent_reports/focus-e2e.md`): exit 0, `swift=131`, **gaps=0**,
  **no_port=14** — SnapKit, Fuzi, Sentry, UIHelpers, FocusAppServices,
  AppShortcuts, WebKit, LocalAuthentication, SafariServices, AudioToolbox,
  CoreHaptics, Network, PassKit, StoreKit. Same list as focus-e2e.md.
  Generated `Package.swift` lists linux-conditioned Combine, `os`, and the
  six stubs.
- `openrender realapp` emits **13** screens. Twelve committed floors
  unchanged: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 /
  97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**.
  `realapp_focus_home_light`: MISSING golden (operator, as in focus-e2e.md).
- `openhost --app focus --scale 2 --script Sources/RealAppProbe/Focus/script.json`
  `focus_app.t200.png` is **byte-identical** to
  `docs/agent_reports/focus-e2e/focus_home.t200.png`
  (`sha256:64771e0041bffbac3e8251db157aaa3e9e4f9d52a37ae884cb87698096e0b2fd`,
  786×1704).
- Catalyst **124/124** (`/tmp/gate-merge-focus`).
- Linux `docker run --rm -v … swift:6.2-noble` `openrender` **complete
  (203.17 s)**.

No `Package.resolved`. Nothing outside `uikit/`. No new rendering rules.
Catalyst paths stay behind the existing iOS cut.
