# Merge `origin/agent/keyboard-chrome` onto main

MERGE TASK, no new rules. `origin/agent/keyboard-chrome` (docs/agent_reports/keyboard-chrome.md) drew a measured iOS 26.1 software keyboard in the capture path, but it also added its own minimal `Sources/ConformanceApps/Notes/` (empty UITextView, `focus-body` / `blur`). Main already has the Linux-trial Notes app of the same name (tabs, list, detail, settings, search, delete — docs/agent_reports/linux-trial.md), plus `--dark` / `--ipad` / `--rtl` / `--ax1` plumbing in openhost, confprobe, and `conformance_probe_sim.sh`.

## Resolution

1. **Main's Notes kept unchanged.** `NotesApp.swift` and `script.json` are byte-identical to `origin/main`. `NotesRootViewController.swift` (the branch's bare text view) is dropped. No `Keyboard/` app: Forms `focus-name` and main's Notes `focus-body` already exercise a first responder.
2. **Keyboard drawing + probe plumbing survive** next to main's axes: `_UIKeyboardChrome` / `_UIKeyboardWindow`, the measured geometry table, dark mix, 23/60 present animation, `renderCapture` in `ConformanceMode.captureConformance` (still passing `direction` into `captureSuffix`), NEED_SHOT / GOT_SHOT in confprobe + `conformance_probe_sim.sh`, Tabs `searchBar.becomeFirstResponder()`.
3. **Scoreboard and fidelity table keep both sides' rows.** Keyboard-chrome's six open rows sit above main's `Tabs-t2000-dark-bar-chroma`. This merge adds two Notes samples from the re-measurement. Newest fidelity-table row is this merge; the original keyboard-chrome row is kept under it.

## What was re-measured

Device: iPhone SE 3rd gen 2x, iOS 26.1, `OpenUIKit-2x-merge-keyboard`. A fresh device showed the Slide to Type onboarding on the first Notes t2100; prefs `DidShowContinuousPathIntroduction` (and the three sibling tutorial flags) were set on **this** UDID only, then the device was rebooted. Recaptures after that are the numbers below.

Before = `/tmp/hc-conformance-Notes` and `-dark` (main, no keyboard pixels). After = `/tmp/conformance-Notes` and `/tmp/conformance-Notes-dark`. Forms / Tabs light = `/tmp/conformance-Forms` / `/tmp/conformance-Tabs`, compared to the keyboard-chrome report (`/tmp/flow-keyboard-chrome-*`).

### Forms light — matches keyboard-chrome

| capture | first responder | keyboard-chrome after | this merge |
|---|---|---|---|
| t200 | no | 98.910 | **98.910** |
| t1200 | name field, empty | 96.811 | **96.811** blob 137 |
| t2100 | + typed text | 96.313 | **96.313** blob 159.2 |
| t3000 | yes | 96.277 | **96.277** |
| t3900 | yes | 96.274 | **96.257** |
| t4800 | yes | 96.264 | **96.264** |
| t5700 | no (blur) | 98.966 | **98.966** |

Mean **97.114** (keyboard-chrome 97.116). Unfocused did not move.

### Tabs light — matches keyboard-chrome

| capture | keyboard-chrome | this merge |
|---|---|---|
| t200 | 96.652 | **96.652** |
| t1000 | 99.402 | **99.402** |
| t2000 | 84.634 | **84.663** |
| t3000 | 96.892 | **96.892** |
| t4000 focus-search | 93.665 | **93.669** blob 137 |
| t5000 type-search | 93.246 | **93.250** blob 3442.8 |
| t6000 | 87.482 | **87.482** |
| t7000 | 92.529 | **92.529** |

t2000 is the known scroll-glass residual (`scoreboard/open.txt`); ±0.03 is recapture noise, not a keyboard. Unfocused t200 / t6000 / t7000 did not move.

### Notes light — main's app, not the dropped minimal UITextView

keyboard-chrome's Notes was empty-body t200 / t1200-focus / t2100-blur at **99.904 / 98.306 / 99.904**. Main's script is 13 captures; `focus-body` is t=1.50 so the first-responder frame is **t2100**.

| capture | first responder | before (hc-conformance-Notes) | after |
|---|---|---|---|
| t200 | no (list) | 77.652 | **77.714** |
| t1200 | no (detail after push) | 96.793 | **96.832** |
| t2100 | yes (`focus-body`) | 97.416 | **94.593** blob 159.2 at shift `[19.5, 579.5, 20, 17]` |
| t3000 | no (`done`) | 77.635 | **77.655** |
| t4000 | search `isActive` | 77.699 | **61.662** |
| t5000 | type-search | 98.66 | **61.933** |
| t6000 | no (cancel) | 67.42 | **67.459** |
| t7000 | no (settings) | 99.072 | **99.111** |
| t8000 | no | 99.054 | **99.093** |
| t9000 | no | 99.031 | **99.070** |
| t10000 | no | 67.419 | **67.458** |
| t11000 | no (alert) | 68.275 | **68.315** |
| t12000 | no | 69.953 | **69.992** |

Nothing without a keyboard moved more than recapture noise (~0.06). t2100 is the same shift-key stand-in as Forms t2100 (blob 159); golden is lowercase + QuickType because the note already has text, while the measured empty-field model is uppercase + empty bar. t4000/t5000: main's `focusSearch` is `isActive` only (app unchanged). Golden still shows the tab bar — real iOS did not raise the remote keyboard — while the port draws one because `UISearchController.isActive` calls `becomeFirstResponder()`. Not retuned; samples in `scoreboard/open.txt`.

### Notes dark

| capture | first responder | before | after |
|---|---|---|---|
| t200.dark | no | 75.587 | **75.564** |
| t1200.dark | no | 96.856 | **96.901** |
| t2100.dark | yes | 96.846 | **93.174** blob 213.2 (emoji, same class as Forms dark) |
| t3000.dark | no | 75.783 | **75.576** |
| t4000.dark | search `isActive` | 75.497 | **63.133** |
| t5000.dark | type-search | 98.015 | **61.498** |
| t6000.dark | no | 65.882 | **65.923** |
| t7000.dark | no | 97.710 | **97.752** |
| t8000.dark | no | 97.708 | **97.749** |
| t9000.dark | no | 97.690 | **97.732** |
| t10000.dark | no | 65.991 | **66.034** |
| t11000.dark | no | 68.570 | **68.615** |
| t12000.dark | no | 68.650 | **68.692** |

Unfocused held. First-responder t2100.dark is the dark emoji residual already on the Forms/Tabs keyboard-chrome rows.

## Gates

- `swift build --build-tests` clean.
- `KeyboardChromeTests` + `KeyboardAvoidanceInsetTests` + `ConformanceRegistryTests` pass (11 tests).
- Catalyst **124/124**.
- iOS suite SKIP_CAPTURE=1 **112/113** (`corner_radius` 99.411, known).
- Real app unchanged **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**.
- Linux `swift:6.2-noble` `openrender` green.
- No `Package.resolved`. Files outside `uikit/` untouched.
