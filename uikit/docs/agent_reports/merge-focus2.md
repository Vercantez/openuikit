# Merge `origin/agent/focus-merged` onto main (split Package.swift)

MERGE TASK, no new rules. Main (`6ad4f7e4`) already carries
`agent/silent-merged3` (typed `coreProducts`/`frameworkProducts` and
`coreTargets`/`frameworkTargets`/`conformanceTargets`/`testTargets`, plus
StoreKit / ImageIO / CoreImage / `NSUbiquitousKeyValueStore` /
HTTPCookieStorage) and Combine/`os` as products.
`origin/agent/focus-merged` (`bb229b57`) is the reconciled Focus exam: one
Combine/`os` product, the six harness-stub products, Focus home as the 13th
real-app screen, ingest emission (report `merge-focus.md`). It was written
against a main whose `uikit/Package.swift` still had single `products:` /
`targets:` literals.

A keep-both of that manifest onto the split arrays is what the compiler
cannot type-check (`Package.swift:555: unable to type-check this expression
in reasonable time`). This merge keeps **every main target, product,
dependency, exclude list, swiftSettings and platform condition** and
**adds the branch's six stub products on `frameworkProducts`**, with
Combine/`os` still in `coreProducts` and ingest still emitting
linux-conditioned `.product` lines for all of them.

## File resolutions

| file | how it was resolved |
|---|---|
| `uikit/Package.swift` | Not keep-both. Took main's split arrays. Combine/`os` comments cite combine-product **and** focus-e2e (15 Blockzilla files). Added Glean / Intents / IntentsUI / Onboarding / Licenses / DesignSystem to `frameworkProducts` (MEASURED focus-e2e wave1: SwiftPM refuses those names in both packages). RealAppProbe `exclude` keeps `"Focus/script.json"`. StoreKit / ImageIO / CoreImage Darwin `OpenUIKit*` names stay main's. |
| `uikit/docs/REAL_APP_TEST.md` | Both sides' rows. This merge's type-check row newest; then focus-e2e; then silent-merged3 / silent-frameworks; then presentable + Combine/`os`. |
| `scoreboard/latest.*` / `open.txt` / pin files | From main (unconflicted). |
| `Sources/Combine/Combine.swift` | Auto-merged: main's combine-product body plus focus-e2e's Darwin `enum _OpenUIKitCombineProduct {}`. |
| `Tools/ingest/xcodeproj_to_package.py` | Auto-merged: `PORTED_PRODUCTS` is Combine + `os` **and** the six stubs; emit lists linux-conditioned `.product` for all eight. |
| `Tools/ingest/test_xcodeproj_to_package.py` | Auto-merged: main's `test_combine_and_os_are_ported_products` plus emit assert for Glean. |

Incoming focus-e2e sources that auto-merged (no conflict):
`FocusScreens` / `FocusShims` / vendored `HomeViewController`,
`realapp_focus_home_light` in `compare_realapp.py` and
`RealAppScreen.screens`, `docs/agent_reports/focus-e2e.md`,
`focus_home.t200.png`, wordmark assets, `scripts/realapp_probe_sim.sh`.
Report `docs/agent_reports/merge-focus.md` is added as-is.

`swift package describe --type json` vs main's pre-merge graph: same
targets / products / dependencies, plus the six stub products. Shared
product records match byte-for-byte. RealAppProbe `sources` grow by the
three HomeViewController files; `product_memberships` on the stub targets
gain their new product names.

No files outside `uikit/`. No pin files. No `Package.resolved`.

## Proof (this merge)

Mac (`SIM_DEVICE_SUFFIX=-merge-focus2`):

- `time swift package describe --type json > /dev/null`: **0.578 s** (bar <20 s)
- `swift build --build-tests`: Build complete (29.10 s)
- `swift test --filter 'Ingest|Combine|Focus'`: **29 tests, 0 failures**
- `python3 -m pytest Tools/ingest -q` with
  `LADDER_CORPUS=/Users/miguelsalinas/openuikit/scratch/ladder-corpus`:
  **34 passed**. Without the corpus: 14 passed, 20 skipped.
- `openrender realapp` emits **13** screens. Twelve committed floors
  unchanged: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 /
  97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**.
  `realapp_focus_home_light`: MISSING golden (operator, as in focus-e2e.md).
- `OPENUIKIT_FORCE_IOS=1 openhost --app focus --scale 2 --script
  Sources/RealAppProbe/Focus/script.json` `focus_app.t200.png` is
  **byte-identical** to
  `docs/agent_reports/focus-e2e/focus_home.t200.png`
  (`sha256:64771e0041bffbac3e8251db157aaa3e9e4f9d52a37ae884cb87698096e0b2fd`,
  786×1704).
- Catalyst **124/124** (`/tmp/gate-merge-focus2`)

`docker run --rm -v "$PWD":/src:ro swift:6.2-noble` (tree copied to `/work`):

- `time swift package describe >/dev/null`: **0.804 s**
- `swift build -c release --product openrender`: **Build of product 'openrender' complete! (182.04s)**

No new rendering rules. Catalyst paths stay behind the existing iOS cut.
The focus-e2e measurements (Blockzilla ingest no_port 21→14, home wordmark
`[44, 394, 305, 65.333]`) are unchanged.
