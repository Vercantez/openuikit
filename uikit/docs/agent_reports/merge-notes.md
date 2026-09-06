# Merge `origin/agent/notes-fidelity` onto main

MERGE TASK, no new rules. Main (`3764a244`, `agent/editor37-merged`) already
carries Ledger (`usesBottomSearch` phone dock, disclosure trailing 8), Tabs
(iOS 26 compact-height platter packing), and TableEditor/Feed/Modal.
`origin/agent/notes-fidelity` (`62ded861`, one commit on `a806f73b` /
`485fe6e7`) is the Notes pass: inactive search slot, overflow compact
header, compact-height tab bar, `note.text`.

Never keep-both on Swift. Notes rules were re-expressed on main's version of
each function. `scoreboard/latest.*` and pin files stay main's.
`scripts/vendor_pins.sh`, `env/`, `scripts/env/` untouched.

Round-19 `scoreboard/latest.md` was not published (`latest.md` still
`6b739e29` round-18). Floors used instead:

- Notes: notes-fidelity after-column (`docs/agent_reports/notes-fidelity.md`)
- Ledger / Tabs / the rest of the board: `/tmp/hc-conformance-<App>[-axis]`
  ours (main after ledger37 + tabs37 + editor37). Ledger also checked
  against ledger-fidelity's 2 dp after-column; where that report predates
  later main merges, hc ours is the floor.

Goldens: `/tmp/hc-conformance-<App>[-axis]/golden` (read-only). Replay:
`SKIP_CAPTURE=1` into `/tmp/mn-conf-<App>[-axis]`. Device: iPhone SE 2x /
iOS 26.1, plus iPad (A16) 820×1180 @2x.

## File resolutions

| file | how it was resolved |
|---|---|
| `Sources/OpenUIKit/UINavigationBar.swift` | Main's `usesBottomSearch` / collapsed chrome **plus** Notes' `searchSlotRevealed` / `showsInactiveSearchSlot` / inactive overlay. `searchOverlayHeight`: `usesBottomSearch → 0`, then active +6, then inactive slot (60 / 74 / 96). `hideOnScrollContentBump` returns 0 while the slot is showing. Pad trailing search must not be un-hidden by `applyCollapsedBarChrome` (Ledger's collapsed-bar restore was undoing Tabs-ipad title hide). |
| `Sources/OpenUIKit/UITabBar.swift` | **Main (Tabs packing).** `compactItemTrailing=12`, regular 12 pt, `compactIconSize` of 18/medium/large, badge `width−16−1`. Notes 2-up citation on `layoutCompactHeightItems` (platter `[240, 0, 187.5, 44]`). Did **not** take Notes' unconfigured `UIImage(systemName:)` compact path — that would drop Tabs landscape. |
| `Sources/OpenUIKit/UITableViewCell.swift` | **Main's body** (disclosure trailing 8 + RTL + TableEditor xxxl chrome). Notes t200 / t5000 / t5000.rtl citation added next to Ledger's 8 pt sample. |
| `Tests/OpenUIKitTests/IOSDevicePixelMetricsTests.swift` | **Both tests:** `testCompactHeightTabBarIsInline64Pt` (Tabs 3-up) and `testCompactHeightTabBarIs64AndPacksIconTitle` (Notes 2-up). Headerprobe `SA.top=116` now attaches a large-title nav so `displaysLargeTitles` fires (Notes replaced the overlay heuristic). Compact-height rest still 55.5; xxxl `SA.top=84` without search stays 55.5. |
| `docs/REAL_APP_TEST.md` | Merge row newest, then Notes, TableEditor, Tabs, Ledger, then the rest of main. |
| `scoreboard/open.txt` | Main's TableEditor / Feed / Modal OPEN rows **plus** Notes' `Notes-trash-bar-symbol` / `Notes-t12000-delete-animation`. Combined Modal-t5200 comment. Keyboard numbers from Notes (t2100 **95.363** / landscape **94.189**). `Tabs-t6000-cancel-inset` already 89.519. |

Incoming Notes sources that auto-merged (reviewed, no keep-both):
`UISearchBar.swift` (`_navInactiveSlot` + Ledger `BottomDock`),
`UISearchController.swift` (`searchSlotRevealed = true` on activate),
`UITableView.swift` (`searchOverflowCompact` + `_hostingViewController` +
TableEditor xxxl comment), `UISearchControllerTests.swift`
(`testInactiveSearchSlotAfterCancelInTabBar` + Ledger dock tests),
`SystemImageTests.swift` (`note.text`), symbol JSON + `names.txt`.
Report `docs/agent_reports/notes-fidelity.md` is added as-is.

## Interaction that is not a drop of either rule

Tabs t6000.landscape **84.090**: Notes inactive slot on the Tabs-measured
64 pt bar. notes-fidelity (slot, Notes packing) was **83.806**;
tabs-fidelity (packing, no slot) was **84.502**; round-18 was **82.52**.
Portrait t6000 **89.519** matches notes-fidelity (tabs-fidelity was 87.496).
Both measured behaviours are in the tree: compact packing (`compactItemWidth`)
and the 60 pt inactive slot (`showsInactiveSearchSlot`).

Ledger t3000.dark **95.349** matches `/tmp/hc-conformance-Ledger-dark` ours
(main after later merges). ledger-fidelity's after-column **96.35** is the
pre-editor measurement; this merge does not move Ledger vs current main.

## Proof

- `swift test --filter 'IOSDevicePixelMetricsTests|UISearchControllerTests|SystemImageTests'`:
  21 + 14 + 23, 0 failures (both compact-height tab-bar tests; inactive slot
  + Ledger bottom dock + Tabs overlay).
- Catalyst **124/124** (`/tmp/gate-merge-notes`).
- iOS suite **112/113**, miss `corner_radius` (`/tmp/suite-merge-notes`).
  Same as main.
- Real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.65 / 82.170 / 99.86 / 99.734 / 85.393**.
  `realapp_focus_home_light` and `realapp_ledger_light` missing goldens
  (same as sibling reports). `/tmp/app-merge-notes`.
- Linux docker `swift:6.2-noble` `openrender` **complete (177.41 s)**.
- Linux `scripts/linux_verify.sh /tmp/linux-verify-merge-notes`: Swift 6.2.4
  openrender **complete (180.73 s)**, **124/124** vs Catalyst goldens,
  **178/178** byte-identical to the macOS render.
- Canary of Feed / Forms / Modal / NavFlow / Pager / Present / TableEditor
  on every axis vs `/tmp/hc-conformance-*` ours: hold, except 0.001–0.008
  mid-flight noise (Pager t1900.dark **99.732 → 99.731**, TableEditor
  t1350.ax1 **96.787 → 96.779**) and TableEditor xxxl **gains** vs stale hc
  (editor37 already on main; t3800.xxxl **97.851**).
- No `Package.resolved`. Nothing outside `uikit/`.

## Notes vs notes-fidelity after (every axis)

Portrait / dark / rtl / ax1 / xxxl / ipad match the report exactly.
Landscape is at or above (Tabs packing on main, which Notes did not have).

| scene | notes-fidelity after | merge | Δ |
|---|---|---|---|
| t200 | 89.469 | **89.469** | 0 |
| t1200 | 96.916 | 96.916 | 0 |
| t2100 | 95.363 | 95.363 | 0 |
| t3000 | 89.117 | 89.117 | 0 |
| t4000 | 89.111 | 89.111 | 0 |
| t5000 | 98.818 | 98.818 | 0 |
| t6000 | 82.159 | 82.159 | 0 |
| t7000 | 99.192 | 99.192 | 0 |
| t8000 | 99.174 | 99.174 | 0 |
| t9000 | 99.164 | 99.164 | 0 |
| t10000 | 82.142 | 82.142 | 0 |
| t11000 | 80.615 | 80.615 | 0 |
| t12000 | 72.015 | 72.015 | 0 |
| t200.dark | 87.195 | 87.195 | 0 |
| t1200.dark | 96.974 | 96.974 | 0 |
| t2100.dark | 93.919 | 93.919 | 0 |
| t3000.dark | 87.512 | 87.512 | 0 |
| t4000.dark | 86.884 | 86.884 | 0 |
| t5000.dark | 98.221 | 98.221 | 0 |
| t6000.dark | 82.885 | 82.885 | 0 |
| t7000.dark | 97.856 | 97.856 | 0 |
| t8000.dark | 97.854 | 97.854 | 0 |
| t9000.dark | 97.836 | 97.836 | 0 |
| t10000.dark | 82.984 | 82.984 | 0 |
| t11000.dark | 87.735 | 87.735 | 0 |
| t12000.dark | 73.005 | 73.005 | 0 |
| t200.rtl | 81.716 | 81.716 | 0 |
| t1200.rtl | 96.987 | 96.987 | 0 |
| t2100.rtl | 95.452 | 95.452 | 0 |
| t3000.rtl | 81.722 | 81.722 | 0 |
| t4000.rtl | 85.734 | 85.734 | 0 |
| t5000.rtl | 97.860 | 97.860 | 0 |
| t6000.rtl | 79.986 | 79.986 | 0 |
| t7000.rtl | 99.194 | 99.194 | 0 |
| t8000.rtl | 99.176 | 99.176 | 0 |
| t9000.rtl | 99.166 | 99.166 | 0 |
| t10000.rtl | 79.988 | 79.988 | 0 |
| t11000.rtl | 78.736 | 78.736 | 0 |
| t12000.rtl | 71.987 | 71.987 | 0 |
| t200.ax1 | 88.713 | 88.713 | 0 |
| t1200.ax1 | 96.931 | 96.931 | 0 |
| t2100.ax1 | 95.393 | 95.393 | 0 |
| t3000.ax1 | 88.351 | 88.351 | 0 |
| t4000.ax1 | 86.566 | 86.566 | 0 |
| t5000.ax1 | 96.167 | 96.167 | 0 |
| t6000.ax1 | 77.364 | 77.364 | 0 |
| t7000.ax1 | 99.190 | 99.190 | 0 |
| t8000.ax1 | 99.172 | 99.172 | 0 |
| t9000.ax1 | 99.161 | 99.161 | 0 |
| t10000.ax1 | 77.335 | 77.335 | 0 |
| t11000.ax1 | 55.123 | 55.123 | 0 |
| t12000.ax1 | 68.610 | 68.610 | 0 |
| t200.xxxl | 89.396 | 89.396 | 0 |
| t1200.xxxl | 96.931 | 96.931 | 0 |
| t2100.xxxl | 95.393 | 95.393 | 0 |
| t3000.xxxl | 89.290 | 89.290 | 0 |
| t4000.xxxl | 88.375 | 88.375 | 0 |
| t5000.xxxl | 97.921 | 97.921 | 0 |
| t6000.xxxl | 80.533 | 80.533 | 0 |
| t7000.xxxl | 99.190 | 99.190 | 0 |
| t8000.xxxl | 99.172 | 99.172 | 0 |
| t9000.xxxl | 99.161 | 99.161 | 0 |
| t10000.xxxl | 80.540 | 80.540 | 0 |
| t11000.xxxl | 71.181 | 71.181 | 0 |
| t12000.xxxl | 70.520 | 70.520 | 0 |
| t200.landscape | 85.868 | **85.946** | +0.078 |
| t1200.landscape | 94.675 | **94.790** | +0.115 |
| t2100.landscape | 94.189 | **94.207** | +0.018 |
| t3000.landscape | 85.657 | **85.679** | +0.022 |
| t4000.landscape | 85.984 | **86.007** | +0.023 |
| t5000.landscape | 86.597 | **86.723** | +0.126 |
| t6000.landscape | 71.946 | **71.968** | +0.022 |
| t7000.landscape | 97.016 | **97.226** | +0.210 |
| t8000.landscape | 96.998 | **97.206** | +0.208 |
| t9000.landscape | 96.988 | **97.196** | +0.208 |
| t10000.landscape | 71.900 | **71.980** | +0.080 |
| t11000.landscape | 76.480 | **76.578** | +0.098 |
| t12000.landscape | 64.554 | **64.582** | +0.028 |
| Notes-ipad:t200 | 97.729 | 97.729 | 0 |
| Notes-ipad:t1200 | 98.056 | 98.056 | 0 |
| Notes-ipad:t2100 | 95.488 | 95.488 | 0 |
| Notes-ipad:t3000 | 97.729 | 97.729 | 0 |
| Notes-ipad:t4000 | 99.462 | 99.462 | 0 |
| Notes-ipad:t5000 | 99.660 | 99.660 | 0 |
| Notes-ipad:t6000 | 97.617 | 97.617 | 0 |
| Notes-ipad:t7000 | 98.702 | 98.702 | 0 |
| Notes-ipad:t8000 | 98.799 | 98.799 | 0 |
| Notes-ipad:t9000 | 98.796 | 98.796 | 0 |
| Notes-ipad:t10000 | 96.114 | 96.114 | 0 |
| Notes-ipad:t11000 | 97.567 | 97.567 | 0 |
| Notes-ipad:t12000 | 97.751 | 97.751 | 0 |

## Ledger vs main hc ours (every axis)

Byte-level hold of `/tmp/hc-conformance-Ledger[-axis]` ours (0 drops, 0
gains). Scores:

| scene | merge |
|---|---|
| t200 | 93.570 |
| t1200 | 97.448 |
| t2100 | 92.310 |
| t3000 | 96.346 |
| t4000 | 99.758 |
| t5000 | 94.199 |
| t6000 | 92.915 |
| t7000 | 94.084 |
| t200.dark | 91.411 |
| t1200.dark | 97.643 |
| t2100.dark | 89.494 |
| t3000.dark | 95.349 |
| t4000.dark | 99.122 |
| t5000.dark | 91.806 |
| t6000.dark | 92.356 |
| t7000.dark | 91.701 |
| t200.rtl | 90.813 |
| t1200.rtl | 97.426 |
| t2100.rtl | 89.610 |
| t3000.rtl | 94.387 |
| t4000.rtl | 99.288 |
| t5000.rtl | 92.326 |
| t6000.rtl | 91.669 |
| t7000.rtl | 92.270 |
| t200.ax1 | 92.015 |
| t1200.ax1 | 97.366 |
| t2100.ax1 | 90.834 |
| t3000.ax1 | 94.596 |
| t4000.ax1 | 99.159 |
| t5000.ax1 | 92.518 |
| t6000.ax1 | 69.214 |
| t7000.ax1 | 92.529 |
| t200.xxxl | 92.338 |
| t1200.xxxl | 97.366 |
| t2100.xxxl | 91.063 |
| t3000.xxxl | 94.964 |
| t4000.xxxl | 99.334 |
| t5000.xxxl | 92.813 |
| t6000.xxxl | 84.072 |
| t7000.xxxl | 92.819 |
| t200.landscape | 89.218 |
| t1200.landscape | 96.474 |
| t2100.landscape | 86.437 |
| t3000.landscape | 89.764 |
| t4000.landscape | 94.598 |
| t5000.landscape | 89.347 |
| t6000.landscape | 91.302 |
| t7000.landscape | 89.038 |
| Ledger-ipad:t200 | 99.257 |
| Ledger-ipad:t1200 | 99.285 |
| Ledger-ipad:t2100 | 99.320 |
| Ledger-ipad:t3000 | 99.319 |
| Ledger-ipad:t4000 | 99.370 |
| Ledger-ipad:t5000 | 99.318 |
| Ledger-ipad:t6000 | 99.149 |
| Ledger-ipad:t7000 | 99.322 |

## Tabs vs tabs-fidelity / notes-fidelity (every axis)

Portrait / dark / rtl / ax1 / xxxl / ipad match tabs-fidelity except the
t6000 family, which matches notes-fidelity (inactive slot). Landscape
matches tabs-fidelity except t6000.landscape (both rules; see above).

| scene | tabs-fidelity after | notes-fidelity | merge |
|---|---|---|---|
| t200 | 96.657 | 96.657 | **96.657** |
| t1000 | 99.402 | | 99.402 |
| t2000 | 84.603 | | 84.603 |
| t3000 | 96.898 | | 96.898 |
| t4000 | 95.006 | | 95.006 |
| t5000 | 93.709 | | 93.709 |
| t6000 | 87.496 | **89.519** | **89.519** |
| t7000 | 96.600 | 96.600 | 96.600 |
| t200.dark | 97.317 | | 97.317 |
| t1000.dark | 98.786 | | 98.786 |
| t2000.dark | 84.851 | | 84.851 |
| t3000.dark | 97.553 | | 97.553 |
| t4000.dark | 92.353 | | 92.353 |
| t5000.dark | 92.416 | | 92.416 |
| t6000.dark | 88.262 | | **92.096** |
| t7000.dark | 97.193 | | 97.193 |
| t200.rtl | 96.671 | | 96.671 |
| t1000.rtl | 99.091 | | 99.091 |
| t2000.rtl | 84.598 | | 84.598 |
| t3000.rtl | 96.912 | | 96.912 |
| t4000.rtl | 94.789 | | 94.789 |
| t5000.rtl | 93.573 | | 93.573 |
| t6000.rtl | 87.456 | | **89.534** |
| t7000.rtl | 96.610 | | 96.610 |
| t200.ax1 | 96.541 | | 96.541 |
| t1000.ax1 | 99.043 | | 99.043 |
| t2000.ax1 | 84.603 | | 84.603 |
| t3000.ax1 | 96.739 | | 96.739 |
| t4000.ax1 | 92.822 | | 92.822 |
| t5000.ax1 | 90.967 | | 90.967 |
| t6000.ax1 | 82.735 | | **84.882** |
| t7000.ax1 | 95.973 | | 95.973 |
| t200.xxxl | 96.419 | | 96.419 |
| t1000.xxxl | 99.043 | | 99.043 |
| t2000.xxxl | 84.629 | | 84.629 |
| t3000.xxxl | 96.634 | | 96.634 |
| t4000.xxxl | 94.836 | | 94.836 |
| t5000.xxxl | 93.327 | | 93.327 |
| t6000.xxxl | 85.238 | | **87.504** |
| t7000.xxxl | 96.169 | | 96.169 |
| t200.landscape | **97.704** | 97.476 | **97.704** |
| t1000.landscape | **99.019** | 98.716 | **99.019** |
| t2000.landscape | 77.901 | 77.893 | 77.901 |
| t3000.landscape | **98.082** | 97.795 | **98.082** |
| t4000.landscape | 94.962 | | 94.962 |
| t5000.landscape | 93.888 | | 93.888 |
| t6000.landscape | 84.502 | 83.806 | **84.090** |
| t7000.landscape | 97.270 | 96.985 | **97.270** |
| Tabs-ipad:t200 | 98.621 | | 98.621 |
| Tabs-ipad:t1000 | 99.209 | | 99.209 |
| Tabs-ipad:t2000 | 98.657 | | 98.657 |
| Tabs-ipad:t3000 | 98.157 | | 98.157 |
| Tabs-ipad:t4000 | 96.100 | | 96.100 |
| Tabs-ipad:t5000 | 96.254 | | 96.254 |
| Tabs-ipad:t6000 | 98.603 | | 98.603 |
| Tabs-ipad:t7000 | 98.365 | | 98.365 |

No new rendering rules. Catalyst paths stay behind the existing iOS cut.
No `Package.resolved`.
