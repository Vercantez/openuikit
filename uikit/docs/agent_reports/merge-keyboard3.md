# Merge `origin/agent/keyboard4-merged` onto main (landscape + bash scripts)

MERGE TASK, no new rules. `origin/agent/keyboard4-merged` (`331aca34`,
docs/agent_reports/merge-keyboard2.md, merge-keyboard.md, keyboard-chrome.md)
is the measured software keyboard in the capture path, reconciled twice.
Main has since merged the `--landscape` axis and the bash-portable scripts
(docs/agent_reports/merge-landscape2.md, merge-linuxenv.md); all seven axes
(light/dark/ipad/rtl/ax1/xxxl/landscape) are on this main.

This merge keeps **main's plumbing exactly** (every axis flag, work dir,
and merge check, including `--landscape`) **and** the keyboard drawing
(window, measured geometry, dark variant, animation frames, first-responder
detection). No new rendering rules. Pin files stay main's.

## File resolutions

| file | how it was resolved |
|---|---|
| `Tools/oracle2/confprobe/main.swift` | Main's `loadScript()` still returns `style, direction, contentSize, orientation`. Appearance+window RTL pin, `traitOverrides` content-size pin, landscape `requestGeometryUpdate` / `waitForLandscapeThenStart`, and the JSON `orientation` + size-class dump stay. Keyboard NEED_SHOT / GOT_SHOT handshake, `keyboardIsOnScreen()`, and the dump-stays-app-window comment survive. The auto-merge left the keyboard's first `captureSuffix` without `orientation` and duplicated main's later 5-arg call; restored a single first call with all four suffix axes so `--landscape` (and `--ax1` / `--xxxl`) focused captures keep their suffix. |
| `scripts/conformance_probe_sim.sh` | Main's `SIMCTL_CHILD_CONFPROBE_ORIENTATION` forwarding **and** the keyboard watcher (NEED_SHOT → `simctl io screenshot` → GOT_SHOT), started before `--console-pty`. Echo still prints `orientation`. Landscape rotate/restore of the SE is unchanged. |
| `Sources/openhost/ConformanceMode.swift` | Auto-merged correctly: `captureConformance` keeps `orientation`; capture uses `_UIKeyboardChrome.renderCapture`. |
| `Tests/OpenUIKitTests/KeyboardChromeTests.swift` | Incoming named tests kept. Class isolation already wrapped `#if !os(Linux) @MainActor` (linux-env / merge-keyboard2). Main's `ConformanceRegistryTests.testLandscapeCaptureSuffixAndOrientationResolution` is unconflicted. |
| `scoreboard/open.txt` | Keyboard-chrome's eight OPEN rows on top, then main's four RTL-rest rows, then the shared Tabs / `corner_radius` rows. |
| `docs/REAL_APP_TEST.md` | This merge newest, then main's landscape / guest-app-path rows, then merge-keyboard2 / merge-keyboard / keyboard-chrome, then main's linux-env / … rows. |
| pin files | Unconflicted from main (`env/`, `scripts/env/`, `scripts/vendor_pins.sh` untouched). |

Incoming keyboard sources that auto-merged (no conflict): `UIKeyboardChrome.swift`,
`UIResponder.swift` (`sync` on become/resign), `LayerBridge.swift` key fingerprint,
Tabs `searchBar.becomeFirstResponder()`, reports `keyboard-chrome.md` /
`merge-keyboard.md` / `merge-keyboard2.md`. Main's Notes app is unchanged.
Main's `--landscape` compact-height rules (`UINavigationBar` bar y 24,
pageSheet fill) are unconflicted.

## Proof (this merge)

`SIM_DEVICE_SUFFIX=-merge-keyboard3`. Forms goldens already at
`/tmp/conformance-Forms/golden` (NEED_SHOT set from merge-keyboard; t1200
sha256 `568847f1…`). Committed `goldens/ios/hc-conformance-Forms` is the
pre-keyboard snapshot (head `4901188a`, t1200 `b92cf32d…`) — restoring it
into this workdir would drop t1200 off 96.811, so it was not copied.
Landscape / RTL goldens were copied **from** `/tmp/hc-conformance-NavFlow-{landscape,rtl}/golden`
into `/tmp/conformance-NavFlow-*` (read only; never wrote `/tmp/hc-conformance-*`).

- `swift build --build-tests` green
- `swift test --filter 'ConformanceRegistry|Keyboard'`: **13 tests, 0 failures**
  (8 registry including RTL + content-size + landscape + combined
  `t200.dark.rtl.ax1.landscape` + bash regenerator, 2 KeyboardAvoidanceInset,
  3 KeyboardChrome)
- `SKIP_CAPTURE=1 … /tmp/conformance-Forms Forms` — same as merge-keyboard.md
  / merge-keyboard2.md:

  | capture | this merge | merge-keyboard.md |
  |---|---|---|
  | t200 | **98.910** | 98.910 |
  | t1200 | **96.811** blob 137 | 96.811 blob 137 |
  | t2100 | **96.313** blob 159.2 | 96.313 |
  | t3000 | **96.277** | 96.277 |
  | t3900 | **96.257** | 96.257 |
  | t4800 | **96.264** | 96.264 |
  | t5700 | **98.966** | 98.966 |

  Mean **97.114**. Unfocused t200 / t5700 did not move.

- `SKIP_CAPTURE=1 … /tmp/conformance-NavFlow-landscape NavFlow --landscape`:
  t200.landscape **96.707**, t1200 **99.089**, t2100 **97.000**, t3000
  **98.193**, t3900 **98.806**, t4800 **96.053**, worst **96.053**, mean
  **97.641** — same as `docs/agent_reports/conf-landscape.md` /
  merge-landscape2.md. Unchanged.
- `SKIP_CAPTURE=1 … /tmp/conformance-NavFlow-rtl NavFlow --rtl`:
  t200.rtl **99.599**, t3900.rtl **98.788** blob 58.8, t3000.rtl **97.171**
  blob 58.8, worst **97.171**, mean **98.853** — per-capture identical to
  merge-landscape2.md / merge-linuxenv (`NavFlow:t3000.rtl` 97.171). Unchanged.
- Catalyst **124/124** (`/tmp/gate-merge-keyboard3`)
- iOS suite SKIP_CAPTURE=1 **112/113** (`corner_radius` 99.411, known)
- real-app unchanged: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 /
  97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**
- Linux `swift:6.2-noble` `openrender` green (`docker run --rm -v "$PWD":/src:ro`,
  `.build` and `Package.resolved` removed after copy, 190.87 s)

No `Package.resolved`. No files outside `uikit/`. No new rendering rules.
Catalyst paths stay behind the existing iOS cut.
