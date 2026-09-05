# Merge `origin/agent/merge-keyboard` onto main (rtl / ax1 / xxxl + bash scripts)

MERGE TASK, no new rules. `origin/agent/merge-keyboard` (docs/agent_reports/merge-keyboard.md and keyboard-chrome.md) is the measured software keyboard in the capture path, reconciled once already against the Linux-trial Notes app. Main (`c16b1455`) has since gained `--rtl` / `--ax1` / `--xxxl` (docs/agent_reports/merge-dyntype.md) and bash-portable agent scripts (docs/agent_reports/merge-linuxenv.md). `--landscape` is **not** on this main; it lives on `agent/landscape2-merged` (docs/agent_reports/merge-landscape.md on that branch) and was not invented here.

This merge keeps **main's plumbing exactly** (every axis flag, work dir, and merge check) **and** the keyboard drawing (window, measured geometry, dark variant, animation frames, first-responder detection). No new rendering rules.

## File resolutions

| file | how it was resolved |
|---|---|
| `Tools/oracle2/confprobe/main.swift` | Main's `loadScript()` still returns `style, direction, contentSize`. Appearance+window RTL pin and `traitOverrides` content-size pin stay. `captureSuffix` and the JSON dump still carry `contentSize`. Keyboard NEED_SHOT / GOT_SHOT handshake, `keyboardIsOnScreen()`, and the dump-stays-app-window comment survive. The auto-merge dropped `contentSize` from the first `captureSuffix` call (keyboard's older 3-arg form); restored so `--ax1` / `--xxxl` focused captures keep their suffix. |
| `scripts/conformance_probe_sim.sh` | Main's `SIMCTL_CHILD_CONFPROBE_CONTENT_SIZE` forwarding **and** the keyboard watcher (NEED_SHOT → `simctl io screenshot` → GOT_SHOT), started before `--console-pty`. Echo still prints `contentSize`. |
| `Sources/openhost/ConformanceMode.swift` | Auto-merged correctly: `runConformanceScripted` / `captureConformance` keep `contentSize`; capture uses `_UIKeyboardChrome.renderCapture`. |
| `Tests/OpenUIKitTests/KeyboardChromeTests.swift` | Incoming named tests kept. Class isolation wrapped `#if !os(Linux) @MainActor` so Linux 6.2.4 `swift build --build-tests` still links (linux-env). |
| `scoreboard/open.txt` | Keyboard-chrome's eight OPEN rows on top, then main's four RTL-rest rows, then the shared Tabs / `corner_radius` rows. |
| `docs/REAL_APP_TEST.md` | This merge newest, then merge-keyboard, then keyboard-chrome, then main's linux-env / rtl-rest / ipad-open / … rows. |

Incoming keyboard sources that auto-merged (no conflict): `UIKeyboardChrome.swift`, `UIResponder.swift` (`sync` on become/resign), `LayerBridge.swift` key fingerprint, Tabs `searchBar.becomeFirstResponder()`, reports `keyboard-chrome.md` / `merge-keyboard.md`. Main's Notes app is unchanged.

## Proof (this merge)

`SIM_DEVICE_SUFFIX=-merge-keyboard2`. Goldens for Forms/Notes focused frames came from `/tmp/conformance-Forms` / `/tmp/conformance-Notes` (merge-keyboard's NEED_SHOT captures); `/tmp/hc-conformance-Forms/golden` on this Mac was still the pre-keyboard drawHierarchy set (t1200 band black). RTL goldens already on this Mac.

- `swift build --build-tests` green
- `swift test --filter 'ConformanceRegistry|Keyboard'`: **12 tests, 0 failures** (7 registry including RTL + content-size + bash regenerator, 2 KeyboardAvoidanceInset, 3 KeyboardChrome)
- `SKIP_CAPTURE=1 … /tmp/hc-conformance-Forms Forms` — same as merge-keyboard.md:

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

- `SKIP_CAPTURE=1 … /tmp/hc-conformance-Notes Notes` — t2100 **94.593** blob 159.2. Unfocused held vs merge-keyboard.md: t200 **77.714**, t1200 **96.832**, t3000 **77.655**, t7000 **99.111**, t8000 **99.093**, t9000 **99.070**.
- `SKIP_CAPTURE=1 … /tmp/hc-conformance-NavFlow-rtl NavFlow --rtl`: t200.rtl **99.599**, t3900.rtl **98.788** blob 58.8, worst **97.171**, mean **98.788** — same as `docs/agent_reports/conf-rtl.md` / merge-linuxenv (`NavFlow:t3000.rtl` 97.171). `--landscape` is not a flag on this main (usage of `conformance_flow.sh` is `--ipad --dark --rtl --ax1 --xxxl`); not invented here.
- Catalyst **124/124** (`/tmp/gate-merge-keyboard2`)
- iOS suite SKIP_CAPTURE=1 **112/113** (`corner_radius` 99.411, known)
- real-app unchanged: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**
- Linux `swift:6.2-noble` `openrender` green (`docker run --rm -v "$PWD":/src:ro`, 180.18 s)

No `Package.resolved`. No files outside `uikit/`. No new rendering rules. Catalyst paths stay behind the existing iOS cut.
