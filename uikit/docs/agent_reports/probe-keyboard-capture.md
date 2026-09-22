# probe-keyboard-capture: why keyboard-up conformance captures went short

Branch `agent/probe-keyboard-capture`, merged with `agent/gate-speed`.
iPhone SE 3rd gen 2x and iPad (A16) simulators, iOS 26.1, Xcode 26.1.

## Symptom

Forms `--dark/--rtl/--ax1/--ipad` produced 3/7 goldens (t200, t1200 and t5700
only). Tabs `--ipad/--dark` produced 6/8 (t5000 missing among others). Every
run still ended with `DONE=ok`. Later the same thing happened on the base
axis too (gate-speed's refresh got Forms 3/7 and Tabs 6/8).

## Root cause (measured)

This is not simulator device state. Both shared devices read `light`,
`large`, `AppleLanguages=(en-US)` and `ConnectHardwareKeyboard=0`, and
`com.apple.keyboard.preferences` holds only the four onboarding skip flags.
Base, dark, rtl and ax1 share one device, and the axis is applied inside the
app (window overrides), so no axis leaves anything on the device.

The actual chain:

1. A keyboard-up capture asks the shell watcher for `simctl io screenshot`
   (NEED_SHOT/GOT_SHOT). On this host (load average 200-400) the screenshot
   takes 0.2 s to 11.4 s, and the slowness is not limited to the first shot:
   - home screen, back to back: 6.3 / 10.4 / 10.4 s, then 0.2 s;
   - within one run: t1200 6.15 s, t2100 8.88 s, t3000 11.36 s, t3900 2.14 s, t4800 0.30 s.
2. confprobe waited for the shot by blocking its main thread (`Thread.sleep`
   loop, 10 s cap). When the cap was hit, it fell back to drawHierarchy, which
   produces a frame with no keyboard.
3. After the stall, the display link's media-frame clock had jumped ahead.
   The next tick then fired every overdue action at once. Two examples:
   - Forms: `type/toggle/slide-0.7` all ran at frame 245 after a 2.75 s shot;
     after a 10 s stall, all five actions ran at frame 690.
   - Tabs (gate-speed log): t4000 was captured at frame 240 and the next capture at frame 893.
4. Each action replaced `armedAfterAction`, which silently dropped the
   previous action's pending capture. Only the last one (t5700) survived.
5. `conformance_flow.sh` piped the probe through `| tail -1`, so no failure
   could reach the caller in any case.

Whether a run went short depended on whether a screenshot hit a multi-second
stall. That explains why base light worked at 15:00 and failed later.

## Fix (under uikit/ only)

- `Tools/oracle2/confprobe/main.swift`
  - The framebuffer shot is now asynchronous. The layout JSON is dumped at
    the capture tick, NEED_SHOT is written, and the display-link handler
    returns (the main thread stays free) until GOT_SHOT arrives. The pause is
    then added to `startedAt`, so every later action keeps its scripted gap
    to this capture. `lastActionTimestamp` and `springBegin` stay in real
    media time, and a seek capture's layer freeze is released only after the shot.
  - The meaning of a frame is unchanged: the recorded `frame` numbers are
    still the scripted 60 Hz indices (12, 76, 90, 126, 144, ...), and the
    keyboard is drawn the same way.
  - The total pause is recorded as `clock.pausedForShots`.
  - It is a failure (`DONE != ok`, exit 4) if an armed capture is still
    pending when the next action fires, if any scripted PNG is missing
    (`SHORT CAPTURE n/N: missing [...]`), if a shot is unreadable, or if a
    shot takes more than 90 s. The watchdog is now 300 s.
- `scripts/conformance_probe_sim.sh`
  - Compiles only directories that contain a `script.json`. The old glob
    picked up EidolonTap, which imports RxSwift, so every probe compile
    failed; this supersedes gate-speed's EidolonTap-only exclusion.
  - Takes `/tmp/conformance_sim.lock` itself (mkdir plus pid file, same format
    as gate-speed). The lock is re-entrant when the holder is an ancestor
    process (refresh or agent_merge, then flow, then probe).
  - Takes a warm-up screenshot, logs the time of each shot, counts PNGs
    against the script, and restores portrait before any failure exit.
- `scripts/conformance_flow.sh`
  - The probe log goes to `<workdir>/probe.log`, and the probe's exit status
    is honoured.
  - The golden PNG count is checked against the script. A short capture
    exits 4 (the same code gate-speed uses for a short set) and any other
    probe failure exits 3.

## Completeness, every committed axis set, run twice in a row (probe, rc=0 each)

| set | pass 1 | pass 2 |
|---|---|---|
| Forms | 7/7 (paused 29.4 s) | 7/7 |
| Forms-ipad / -dark / -rtl / -ax1 | 7/7 each | 7/7 each |
| Tabs / -ipad / -dark | 8/8 each | 8/8 each |
| TableEditor / -ipad / -dark / -rtl / -ax1 | 10/10 each | 10/10 each |
| Pager / -ipad / -dark | 17/17 each | 17/17 each |

The pass 1 Forms base run paused 29.4 s in total for screenshots. Its images
match pass 2 (paused 1.8 s) to within 0.02 % of pixels, where the difference
is the caret blink. The pause therefore does not change what a frame shows.
Keyboard-up frames agree to within 0.02-0.16 % between the two passes.

## Refresh (refresh_conformance_goldens.sh): board vs new

Every set was captured on its first attempt.

| row | board | new | delta |
|---|---|---|---|
| Forms-ipad t1200 / t2100 / t3000 / t3900 / t4800 | 96.19-96.30 | 96.34-96.45 | +0.15 each |
| Forms-ipad t200 / t5700 | 99.228 / 99.221 | same | 0 |
| Forms .dark (7 rows) | | | 0, except t3000 -0.017 |
| Forms .rtl (7 rows) | | | 0 |
| Forms .ax1 (7 rows) | | | 0, except t1200 -0.018 and t3000 -0.017 |
| Tabs-ipad t1000 / t3000 / t4000 / t5000 | 99.209 / 97.989 / 96.099 / 96.254 | 99.276 / 98.156 / 96.256 / 96.411 | +0.07 / +0.17 / +0.16 / +0.16 |
| Tabs-ipad t200 / t2000 / t6000 / t7000 | | | 0 |
| Tabs t1000.dark / t4000.dark | 98.813 / 92.358 | 98.883 / 92.373 | +0.07 / +0.02 |
| **Tabs t2000.dark** | **93.193** | **92.475** | **-0.718** |
| other Tabs .dark rows | | | 0 |
| Tabs (base) t1000 / t2000 | 99.409 / 84.946 | 99.440 / 84.925 | +0.03 / -0.02 |
| Tabs (base) other 6 rows | | | 0 |

The gate flagged Tabs base as stale (the Tabs sources changed after its Sep 5
capture), so it was refreshed as well. It captured 8/8 on the first attempt.

**Tabs:t2000.dark, -0.718.** This is capture noise on the golden side, not a
port regression. The same OpenUIKit render scores:

- 93.155 against the Sep 5 golden;
- 93.193 against matrix pass 2;
- 92.475 against matrix pass 1 and against the refresh capture.

The two probe captures differ in 5.9 % of pixels, all inside the tab bar
(bbox y 1088-1328 px). The layout dump shows one view still `playing` at
t2000 (0.6 s after `select-tab-3`) in both captures. The tab bar's selection
animation lands in one of two states. The refreshed golden was committed as
captured (not cherry-picked), and this row is noted as bimodal. Settling it
would need a later capture time or a probe-side wait for rest. That changes
what the frame means, so it is left as a separate decision.

## Gate

See the final status in the handback. The run was
`CHECK_ONLY=1 bash uikit/scripts/agent_merge.sh agent/probe-keyboard-capture`.
