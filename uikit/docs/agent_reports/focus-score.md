# Focus fidelity measurement — agent/focus-score

2026-09-06. Source baseline: `497db123` (origin/main). Focus app:
`a2832521c1daa0c23419c73705ae043ed60c9791`.

**CANNOT produce the first current-main Linux Focus fidelity score.**
Before: score N/A. After: score N/A; **0 fresh guest captures, 15 CANNOT,
0 scored**. This is a measured build blocker, not a zero-percent fidelity
result. No renderer, app, golden, pin, or build source changes are committed.

The fifteen rows in the guest report are fifteen **real-app** screens,
including three Focus rows; they are not fifteen Blockzilla screens.
Thirteen carried real-app goldens exist. Ledger and the isolated Focus home
have no carried iOS real-app golden; the full browser has its own SE golden.

## Measured blocker

Built in the operator's `uikit-linux` container, using a private support
copy at `/work-focus-score`. Current worktree source was copied with tar;
`/src`, `/work`, the original support checkout, and vendor pins were not
modified. The production builder was invoked from `uikit/`:

```sh
W=/work-focus-score bash /work-focus-score/full/scripts/build_full.sh
```

The full guest build exits **1**, at the unchanged Blockzilla source:

```text
BrowserViewController.swift:1193:21: error: value of type 'any UIDropSession' has no member 'loadObjects'
URLBar.swift:1137:49: error: cannot convert value of type 'Foundation.NSItemProvider' to expected argument type 'OpenUIKit.NSItemProvider'
```

Evidence: [compiler diagnostics and missing success stamps](focus-score/build-blocker.txt).
Complete logs remain in `uikit-linux:/work-focus-score/build-final.log`
and `build-unchanged-main.log`. An earlier relocated libxml CMake cache
error was resolved by clearing only the private copy's libxml build cache.
The two API errors above are the remaining source blocker.

The builder removes its success stamps before rebuilding. Its leftover
`render_full` still has SHA-256
`6d705b2c8d82edfa73c560da59bfadb504b55fc2acefa7a6de7838ed7da45b32`,
the old executable named in `focus-guest-linux.md`. **It was not executed or
scored as a fresh build.** Its documented browser geometry is also
393×852 @2x, whereas the browser oracle is 375×667 @2x with safe area
[20,0,0,0], portrait, and the URLBar Cancel action applied. Resizing would
not repair that capture-state mismatch.

An opt-in geometry/scale/Cancel harness was prepared and tested natively,
but guest compilation stopped at Blockzilla before compiling the renderer.
It is not committed because no fresh guest render could verify it. Scratch
copies remain at `/tmp/focus-score-prepared/`. No native image is presented
as Linux evidence.

## Per-screen inventory

`G` is `goldens/ios/golden_realapp_ios/`; each golden column names the PNG
under that directory. All ours/score/diff fields are absent because the
fresh guest executable could not be built. **B** means the exact two
compiler errors above, documented in `focus-score/build-blocker.txt`.
Dimensions are original pixels, never resampled. [Machine-readable
inventory and golden hashes](focus-score/inventory.json).

| Screen | Golden (G/) | Ours | Score | Pass/fail | Top diff region / reason |
|---|---|---|---|---|---|
| `realapp_focus_home_light` | **missing** | — | — | CANNOT | —; B + no carried golden |
| `realapp_focus_settings_light` | `realapp_focus_settings_light.png` (1179×2556) | — | — | CANNOT | —; B |
| `realapp_hackers_feed_light` | `realapp_hackers_feed_light.png` (1179×2556) | — | — | CANNOT | —; B |
| `realapp_history_light` | `realapp_history_light.png` (1179×2556) | — | — | CANNOT | —; B |
| `realapp_history_light_ipad` | `realapp_history_light_ipad.png` (1640×2360) | — | — | CANNOT | —; B |
| `realapp_ledger_light` | **missing** | — | — | CANNOT | —; B + no carried golden |
| `realapp_settings_dark` | `realapp_settings_dark.png` (1179×2556) | — | — | CANNOT | —; B |
| `realapp_settings_light` | `realapp_settings_light.png` (1179×2556) | — | — | CANNOT | —; B |
| `realapp_settings_light_ax1` | `realapp_settings_light_ax1.png` (1179×2556) | — | — | CANNOT | —; B |
| `realapp_settings_light_ipad` | `realapp_settings_light_ipad.png` (1640×2360) | — | — | CANNOT | —; B |
| `realapp_settings_light_xs` | `realapp_settings_light_xs.png` (1179×2556) | — | — | CANNOT | —; B |
| `realapp_settings_light_xxxl` | `realapp_settings_light_xxxl.png` (1179×2556) | — | — | CANNOT | —; B |
| `realapp_storage_light` | `realapp_storage_light.png` (1179×2556) | — | — | CANNOT | —; B |
| `realapp_storage_light_ipad` | `realapp_storage_light_ipad.png` (1640×2360) | — | — | CANNOT | —; B |
| `realapp_focus_browser_light` | `realapp_focus_browser_light.png` (750×1334) | — | — | CANNOT | —; B |

There are **no scored FAIL rows** to assign to missing glyphs/fonts, layout
constants, color/material, missing views, or timing. A compile failure
cannot establish those visual cause classes. The next wave must first
close this API/type-identity blocker; no pixels or layout dumps were
fabricated to supply a visual diagnosis.

## Dependency and scoring continuation

`origin/agent/focus-guest-dnd` contains the measured repair at
`ab10a3c3020b4de31eb035dfdb044a9b533a5048`. It is **not an ancestor of main**
at measurement time. Its report names the same two diagnostics. The repair
requires `full/appshim/FoundationGuest.swift`,
`full/foundation/NSExtensionHost.swift`, `full/foundation/Progress.swift`,
and the matching `uikit/` provider/session changes. A uikit-only partial
pick cannot install the Foundation bridge. The operator must merge that
dependency and advance pins; this branch does neither.

After that merge: rebuild the fresh guest, capture each registered screen
in its own process at its golden's native geometry/scale, and call
`Tools/compare/compare.py`'s `compare_pixels` with
`golden_premultiplied=False` and the golden's scale, exactly as
`conformance_flow.sh` does. Use the existing conformance scoreboard bar
97.5; preserve its blob/missing-content diagnostics and layout evidence.
Do not count absent images, stale binaries, or device/scale mismatches as
scores. Capture missing home/Ledger goldens separately if those rows are
required. Nothing in this report introduces a new metric or threshold.

## Validation

- Catalyst **124/124** (`/tmp/focus-score-catalyst.log`).
- Fresh iOS **112/113**; only existing `corner_radius` **99.411**.
  Replayed those fresh goldens with the experimental harness stashed:
  **112/113**, and `compare.txt` is byte-identical. Logs:
  `/tmp/focus-score-ios-suite.log`, `/tmp/focus-score-baseline-suite.log`.
- Twelve existing real-app scores unchanged: **99.137 / 98.535 / 98.548 /
  99.469 / 98.639 / 98.133 / 97.516 / 99.650 / 82.170 / 99.860 /
  99.734 / 85.393** (`/tmp/focus-score-realapp.log`). These are the standard
  native regression gate, **not Linux Focus scores**.
- FocusLaunchCoreTests **12/12**, zero failures (`/tmp/focus-score-tests.log`).
- Standard Linux `swift:6.2-noble` release openrender **green, 189.30 s**
  (`/tmp/focus-score-linux-build.log`). This native ELF build does not
  compile Objective-C Blockzilla; it cannot clear the full-guest blocker.
- Final operator CHECK_ONLY proof: transcript to be appended after execution.
