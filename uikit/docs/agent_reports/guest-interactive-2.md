# Guest interactive host, round 2: iOS constraint breaking, keyboard taps, live frame skipping

Branch `agent/guest-interactive-2` (from main after `agent/guest-interactive-host`; main merged in twice).
ALLOW_PATHS: `'^full/(driver/host_full/|scripts/build_full\.sh$)'`.

Typed text now draws in Firefox Focus's URL bar, and the field's geometry
matches iOS 26.1 exactly. Taps on the drawn keyboard type characters. Live
hosts stop re-rendering unchanged screens and run Foundation timers.

## 1. Unsatisfiable constraints: which one iOS breaks

### Measured

- **`Tools/oracle2/breakprobe`** (`scripts/break_probe_sim.sh`,
  `gen_scenarios.py`): 820 scenarios on the iOS 26.1 simulator (iPhone SE,
  2x). It records UIKit's own decision by wrapping
  `-[UIView engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:]`,
  plus the resulting frames. The scenarios vary:
  - every creation order and every activation order;
  - live mode (engine present) and bulk mode (installed before joining a window);
  - sibling and parent/child views;
  - relations, constants, attributes, multipliers;
  - history (remove or re-add the opposing constraint);
  - content-size priorities.

  Results: `golden/layout_break_ios.json`.
- **Focus itself** (`scripts/focus_edit_probe_sim.sh`,
  `Tools/focusoracle/FocusEditOracle.swift`, observation only): the
  unmodified app in the editing state. It records every break with
  SnapKit's `file#line`, the URL bar's frames and constraints, a
  screenshot, and the framebuffer with the keyboard. Results:
  `golden/focus_edit_ios/`.

### Findings

- **Order does not matter.** The broken constraint is the same for every
  creation order, every activation order, and live or bulk mode (F1–F10).
- **Content decides.** UIKit breaks the constraint with the greatest key,
  compared in this order:
  1. its latest item, ranked breadth-first (depth, then subview order,
     then a view's layout guides after its subviews);
  2. its other item, ranked the same way;
  3. inequality before equality, and `<=` before `>=`;
  4. the attribute on its latest item, by raw value (centerX over trailing
     over leading, bottom over top);
  5. the larger constant, written as `latest = earlier + k`.
- **A broken constraint stays in the engine** at a strength just above
  every optional priority, and stays broken while it is active (F7hist).
- **Content-size constraints at priority 1000 are not required.** They beat
  every optional app constraint and silently lose to a required one
  (I1–I3); UIKit never logs breaking them.

### Implementation (`AutoLayout/LayoutEngine.swift`, `Cassowary.swift`)

- The solver reports the mutually exclusive set (`lastConflict`) from the
  failed row's markers.
- The engine breaks the constraint with the greatest key and keeps it in
  the solve at `brokenStrength`.
- `NSLayoutConstraint._brokenInEngine` persists the break until the
  constraint is deactivated.
- Required content-size priorities map to strength 1000 (above 999, below
  required).
- `OpenUIKitRuntime.constraintBreakObserver` is the port's equivalent of
  UIKit's break log. `host_full` prints it with `HOST_FULL_BREAK_LOG=1`.
- Conflicts against a port-only artifact keep the old "break the newcomer"
  rule. The artifact: a stack's arranged subview enters the solve as a
  fixed frame, where UIKit uses UISV relations, so iOS never sees that
  conflict. With the new rule applied there as well, realapp_history_light
  dropped from 99.137 to 98.772.

### Tests

- `Tests/OpenUIKitTests/LayoutBreakTests`: **814/820** probe scenarios
  match iOS. The 6 misses are one family, `V4tie.flip2`: a frame-based
  container written as the first item against its child.
- The model has no rule for that pair yet; those scenarios are listed as
  known divergent.

### Focus result

- The editing URL bar now equals iOS exactly:
  - border 48–311 pt (263 wide);
  - cancel 30 pt;
  - settings button 36 pt;
  - text field 263 × 39.5 pt at y −1.5.
- The field height needed one more measured fix. A `UITextField` subclass
  that insets `textRect(forBounds:)` vertically grows its intrinsic height
  by that inset (Focus: 19.5 + 2 × 10).
- Remaining differences in the bar: the hidden toolset buttons' heights,
  and the stop button's height.

## 2. Taps on the drawn keyboard

- **webSearch layout, measured** from the iOS framebuffer of Focus's URL
  field (`focus_edit.typed.framebuffer.png`):
  - no QuickType bar (panel top 434, height 233);
  - letter rows at the default y;
  - bottom row: 123, emoji, mic, space (130.5 pt), ".", blue go key (57.5 pt).

  The port's drawing now matches.
- **Taps:** `UIWindow.sendTouch` hands touches on the showing panel to the
  keys, as iOS's separate keyboard window does. The app never sees them.
  - A touch goes to the nearest key and commits on touch-up inside it.
  - Letters and "." insert text; space, delete and return work.
  - Shift is one-shot.
  - 123, emoji and mic do nothing (those panels are not modeled).
- Hardware typing is unchanged.

## 3. Frame rate and latency

### Profiled (`HOST_FULL_PROFILE=1`)

- **Layout (constraint solve):** 20–45 ms per pass. It ran on every frame,
  twice per frame in the live loop.
- **Keyboard composite:** 140–330 ms. `applyFill` called `setNeedsDisplay`
  on every key at every capture, so the keys never cached and no frame was
  ever "unchanged".
- **Settings:** always takes the uncached render-pass path (220–400 ms),
  because the liquid-glass Done button samples the destination and the
  retained compositor has no node for that.
- **Idle:** the live loop re-rendered twice a second (the idle redraw)
  whether or not anything changed.

### Fixed, pixel-neutral

Scripted replays and captures are untouched and stay byte-identical.

- **Frame skipping.** `HostLoopHooks.frameFingerprint`, backed by
  `_UIKeyboardChrome._hostFrameFingerprint` (LayerBridge's subtree
  fingerprint of the app and keyboard windows). A live frame whose
  fingerprint equals the last presented one is neither rendered nor
  presented. The change check runs every 50 ms.
- **Keyboard caching.** The keyboard chrome no longer re-applies unchanged
  colors or letter case, so its keys use the layer content cache.
- **Layout.** The live loop lays out only when something is marked for
  layout (`UIView._hostSubtreeNeedsLayout`), once per frame.
- **Measured:** idle Focus home with the caret blinking, over 6 s: 89 frames
  skipped, 23 rendered. The rendered ones are caret flips and timer ticks.

### Real window: Xvfb + noVNC, xdotool input, SDL stats

Measured with the Mac under a load average of 88–150 from other agents, so
treat these as upper bounds.

| action | input to present | frame rate |
|---|---|---|
| typing into the URL field (hardware keys, 7 keys) | 49–54 ms | — |
| drawn-keyboard key taps | 57–67 ms | — |
| tap the URL bar / Cancel | 116–276 ms | — |
| idle home | — | 2 fps (caret blinks only; nothing else renders) |
| idle Settings | — | ≈0 fps |
| open Settings (presentation animation) | 0.7–1.5 s | — |
| taps inside Settings | 0.56–0.76 s | — |

Settings is limited by the render-pass fallback (see below).

### Not fixed

- A frame that changes on Settings still costs one render-pass render.
- The pixel-neutral fix would be either:
  - a destination-sampling (glass) node in CQuartz's retained compositor, so
    Settings can take the cached layer path; or
  - damage-rect rendering in the render pass. Glass sampling across the
    damage edge makes that hard to prove identical.
- I did not attempt either. Scene captures never reach two stable frames,
  so the gate cannot catch a pixel mistake there.

## 4. Run loops in live hosts (coordinator request)

- **openhost live mode** turns `Foundation.RunLoop.main` once per loop turn.
  After timer-unify, `Timer` is Foundation's there, so app Timers, delayed
  `perform`s, run-loop sources and (on Darwin) the dispatch main queue now
  run.
- **Scripted `--script/--record`** never turns it and stays on the host clock.
- **The Mach-O guest** has no CFRunLoop: `full/appshim` aliases OpenUIKit's
  host-clock `RunLoop` and `Timer`. The runnable main loop there is the host
  loop itself:
  - `UIWindow.tick` fires the app's timers on the SDL clock;
  - `beginTurn` drains libdispatch's main queue (`asyncAfter` included).
- **Live test** (both hosts): `--live-seconds N --timer-selftest`. A
  repeating 0.5 s `Timer` rewrites a label, and the verdict requires the
  updates to reach presented frames.
  - openhost on macOS, after timer-unify (so Foundation's `Timer` through the
    Foundation run loop):
    `HOST_TIMER_SELFTEST ok ticks=5 presented=tick 0,…,tick 5`.
  - host_full in the guest:
    `HOST_TIMER_SELFTEST ok ticks=11 presented=tick 0,…,tick 11`.

## Gate

- `linux_guest_host_verify.sh` script (`fixtures/realapp/focus_host_script.json`):
  - Cancel is now at the iOS position (x 10–40).
  - The URL field is asserted to be `[48, 28.5, 263, 39.5]`.
  - Typed text must visibly change the URL-field pixels.
  - It taps "a" on the drawn keyboard, then delete (`mozillaa`, then
    `mozilla`); the field's pixels must return to their state before the
    two taps.
  - Then the menu, Settings, Theme, back and Done, as before.
  - 12 captures, byte-identical across 2 runs.
- **One fixture changed:** `fixtures/realapp/realapp_focus_browser_light.png`
  (the Linux browser screen). The URL placeholder "Search or enter address"
  now draws, as on iOS.
  - `compare_realapp` against `goldens/ios` (2x): 99.288 → **99.555**.
  - The missing-ink blob at the URL field is gone.
  - The 14 other screens are byte-identical.

Verdicts at 372f3c50:

- `CHECK_ONLY agent_merge`: 124/124 scenes, real-app floors held (all 15
  real-app screens byte-identical to main on macOS), `GUEST_ROUTE_CHECK_OK`,
  **checks passed**.
- `local_guest_verify.sh`: `FOCUS_REAL_APPDELEGATE_LAUNCHED root=BrowserViewController`,
  existing screens byte-identical 14/14, `REAL-APP SCREEN VERIFIED ON LINUX`,
  12 captures byte-identical across 2 runs, `GUEST HOST INTERACTION VERIFIED ON LINUX`.
