# Merge `origin/agent/focus-merged3` onto main (Ledger 13th, Focus home 14th)

MERGE TASK, no new rules. Main (`5f6bed0e`) already carries
`agent/guesttrial2-merged`: Ledger's first screen is the 13th real-app
row (`realapp_ledger_light`, `GUEST_REALAPP_SCREENS=13`).
`origin/agent/focus-merged3` (`6d72b933`) is the Focus exam re-expressed
on the split manifest (report `merge-focus2.md`): one Combine/`os`
product, the six harness-stub products, Focus home as a real-app screen,
ingest emission. It still treated home as the 13th screen because it
forked before Ledger landed.

This merge keeps **main's plumbing exact** (Ledger 13th, guest-trial2
rows, `scoreboard/latest.*`, pin files, presentable / StoreKit / ImageIO
/ CoreImage products) **and** adds Focus home as the **14th** screen
(`realapp_focus_home_light`), rendered last as `focus-e2e.md` requires
so a guest 2x ink miss on home cannot drop the screens before it.
Never keep-both on Swift code.

## File resolutions

| file | how it was resolved |
|---|---|
| `uikit/Sources/RealAppProbe/RealAppScreen.swift` | The only Swift conflict. Variant `.focusHome` + `.ledger` both kept. `screens` is `focusScreenTable + hackersScreenTable + ledgerScreenTable + focusHomeTable`. Comment: fourteen screens, Ledger 13th, home last. `makeRoot` already auto-merged both cases. |
| `uikit/Package.swift` | Auto-merged. Main's split arrays unchanged since merge-base; incoming added Glean / Intents / IntentsUI / Onboarding / Licenses / DesignSystem to `frameworkProducts` and `Focus/script.json` to RealAppProbe `exclude`. Combine/`os` stay in `coreProducts`. 26 products, 0 duplicates. |
| `uikit/docs/REAL_APP_TEST.md` | Both sides' rows. This merge newest; then merge-focus2 / focus-e2e; then main's guest-trial2 / present-axes / silent-merged / … |
| `scoreboard/latest.*` / `open.txt` / pin files | From main (unconflicted). Main's Present-t1200 OPEN row kept. |
| `Sources/Combine/Combine.swift` | Auto-merged: main's combine-product body plus focus-e2e's Darwin `enum _OpenUIKitCombineProduct {}`. |
| `Tools/ingest/xcodeproj_to_package.py` | Auto-merged: `PORTED_PRODUCTS` is Combine + `os` **and** the six stubs; emit lists linux-conditioned `.product` for all eight. |
| `Tools/compare/compare_realapp.py` | Auto-merged: `realapp_focus_home_light` **and** `realapp_ledger_light`. |
| `Tools/ingest/test_xcodeproj_to_package.py` | Auto-merged: combine/`os` tests plus emit assert for Glean. |

Incoming focus-e2e sources that auto-merged (no conflict):
`FocusScreens` / `FocusShims` / vendored `HomeViewController`,
wordmark assets, `docs/agent_reports/focus-e2e.md`,
`focus_home.t200.png`, `scripts/realapp_probe_sim.sh`,
`openhost --app focus`. Reports `merge-focus.md` and
`merge-focus2.md` are added as-is.

`swift package describe --type json`: same targets / products as main,
plus the six stub products. RealAppProbe `sources` grow by the three
HomeViewController files.

No files outside `uikit/`. No pin files. No `Package.resolved`.

## Proof (this merge)

Mac (`SIM_DEVICE_SUFFIX=-merge-focus3`):

- `time swift package describe > /dev/null`: **0.97 s** (bar <20 s)
- `swift build --build-tests`: Build complete (32.06 s)
- `swift test --filter 'Ingest|Combine|Focus|Ledger'`: **29 tests, 0 failures**
- `python3 -m pytest Tools/ingest -q` with
  `LADDER_CORPUS=/Users/miguelsalinas/openuikit/scratch/ladder-corpus`:
  **34 passed**. Without the corpus: 14 passed, 20 skipped.
- `openrender realapp` emits **14** screens in order, Ledger 13th, Focus
  home last: history, settings light/dark, storage, xs/xxxl/ax1,
  settings ipad, history ipad, storage ipad, focus settings, hackers,
  **ledger**, **focus_home**.
- Twelve committed floors vs `/tmp/golden_realapp_ios` do not drop:
  **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 /
  99.511 / 82.170 / 99.760 / 99.689 / 85.393**. The 13 main screens
  (12 floors + Ledger) are **byte-identical** to `/tmp/app-gt2-s3`
  (main's post-harvest render). Ledger sha256
  `aeee639f7efdce37ce1a2cb30fcff23554073aaf9c1bebce433094b8a19683fa`.
- `OPENUIKIT_FORCE_IOS=1 openhost --app focus --scale 2 --script
  Sources/RealAppProbe/Focus/script.json` `focus_app.t200.png` is
  **byte-identical** to
  `docs/agent_reports/focus-e2e/focus_home.t200.png`
  (`sha256:64771e0041bffbac3e8251db157aaa3e9e4f9d52a37ae884cb87698096e0b2fd`,
  786×1704).
- Catalyst **124/124** (`/tmp/gate-merge-focus3`)

`docker run --rm -v "$PWD":/src:ro swift:6.2-noble` (tree tarred to
`/work`, exclude `.build` / `Package.resolved`):

- `time swift package describe >/dev/null`: **0.819 s**
- `swift build -c release --product openrender`: **Build of product
  'openrender' complete! (188.13s)**

No new rendering rules. Catalyst paths stay behind the existing iOS cut.
The focus-e2e measurements (Blockzilla ingest no_port 21→14, home wordmark
`[44, 394, 305, 65.333]`) and the guest-trial2 Ledger screen are unchanged.

## Arm64 authority

`queue_box.sh arm64 verify` on **`f75875cc`** (instance `i-00da4d9ca172eb1ff`,
command `b51daaee-8767-4c3c-bd55-0e4ef9aeb219`):

| line | value |
|---|---|
| `BUILD_OK` / `TBD_CHECK_OK` / `difftest rc=0` | yes |
| **`build_full rc=0`** | **yes** |
| **`GATE_B_PASS`** | **yes** |
| `GUEST_REALAPP_RC` | 133 |
| **`GUEST_REALAPP_SCREENS`** | **13** |

Home is last, so the guest 2x miss cannot drop Ledger or Hackers.
MEASURED miss on the 14th screen:

```
OPENUIKIT_IOS_INK_MISS: I|system-regular|12|light|F0.25|107
```

Scalar 107 is `'k'`. Guest scale-2 has no SFNS; `glyph_ink_ios.json` has
12 pt regular light at other phases/scalars but not this F0.25 `k`.
Mac `openrender realapp` is 3x (`glyph_ink_ios_3x.json`) and emitted all
14. Same class as focus-e2e.md §6 (then `I|system-semibold|18|light|F0.0|83`
on home-as-13th; guest-trial2 harvested that 18 pt key, so this merge's
miss is a new 12 pt cell). Harvesting the 2x `system-regular|12` mask is a
follow-up, not a merge rule.
