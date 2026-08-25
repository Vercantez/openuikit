# OpenUIKit Roadmap

Goal: an **ambitious, portable, oracle-validated UIKit** — not a toy. Real UIKit
(Mac Catalyst) remains the ground truth for every milestone.

## Layering (target architecture)

```
┌─────────────────────────────────────────────┐
│ OpenUIKit — views, controls, text, layout,  │
│ traits, animation API, gestures, VC stack   │
├─────────────────────────────────────────────┤
│ quartz (~/quartz, vendored) — Quartz 2D     │
│ rasterizer + CALayer compositor + animation │  ← the user's portable C/C++
│ timing. QZ* C API mirrors CG*/CA.           │    reimplementation (97.5/100
├─────────────────────────────────────────────┤    vs Apple by its own harness)
│ Text: data-driven FontEngine (real-UIKit    │
│ metrics) + stb_truetype + glyph smoothing   │
├─────────────────────────────────────────────┤
│ Hosts: openrender (PNG), SDL2 window (live),│
│ future: wasm/canvas                         │
└─────────────────────────────────────────────┘
```

The pure-Swift rasterizer in OpenCoreGraphics remains as a zero-dependency
fallback backend behind the same Canvas API (`OPENUIKIT_BACKEND=swift`).

## Milestones

- **M1 Geometry** — DONE (9/9 scenes, 99.65–100% pixel identity)
- **M2 Text** — DONE: layout exact (0 issues) AND glyph ink 98.7–99.996%
  via oracle-harvested per-phase ink masks (glyph_ink.json) + CoreText
  text-space pen-quantization model; portable computed fallback kept.
- **M3 Controls** — DONE: UIButton, UIImageView, UIProgressView,
  UIStackView, UISwitch + oracle v2 (real-window drawHierarchy).
  Full suite 23/23 on both backends.
- **M4.5 Effects + coverage** — DONE: shadows + gradients (scene spec v2),
  19 hardening scenes incl. realistic demo_settings; suite 42/42 on quartz,
  window-server glyph-ink variants, non-ASCII advances, alpha-encoding
  normalization in compare.
- **M4 Quartz backend switch** — DONE: libquartz vendored (Sources/CQuartz),
  Canvas backend abstraction (Backend.swift), full-suite dual-backend
  comparison (quartz ≥ swift on every scene, text byte-identical), quartz is
  the default backend. See docs/QUARTZ_NOTES.md.
- **M5 CALayer adoption** — DONE: `LayerBridge.swift` builds a real QZLayer
  tree and quartz's layer compositor (`QZLayerRenderInContext`) replaces
  the RenderPass traversal as the default
  (`OpenUIKitRuntime.compositor = .layers`; renderpass kept as fallback +
  pure-Swift-backend path). View content (glyph ink, image resampling,
  control chrome) renders via the existing drawContent path into contents
  images composited by the layer tree. Three surgical patches to vendored
  quartz reproduce the goldened CA quirks (unclamped cornerRadius,
  hard-edged transformed layers, CA shadow semantics) —
  `patches/quartz/`, reapplied by sync_quartz.sh, documented with
  upstream-suggested fixes in docs/QUARTZ_PATCHES.md. Full suite 42/42
  under BOTH compositors (layers ≥ renderpass within 0.003 everywhere,
  up to +1.5 on button/gradient scenes); 224 tests green incl.
  LayerBridgeTests.
- **M6 Animation** — DONE: `UIView.animate(withDuration:delay:options:)` +
  spring variant (UIViewAnimation.swift); animation blocks record from→to
  per property, model = final value, presentation sampled at the settable
  clock `OpenUIKitRuntime.animationTime` (host-driven seek — the portable
  stand-in for a CADisplayLink driver). Quartz's animation/timing engine
  evaluates all timing (bezier x(t) solve, spring envelope via a scratch
  QZSpringAnimation); LayerBridge applies values with CA's fill/removal,
  color-space and transform-decomposition semantics. UIKit's spring
  duration-fit reverse-engineered EXACTLY (settling equation
  |(β−v)/ω_d|·e^(−βD) = 0.001, verified to 8+ digits against probed
  CASpringAnimation parameters). Oracle2 captures frozen-clock frames;
  scene spec v3 (`animations` + `captureTimes`). Full suite 52/52 (10
  animation scenes, every frame ≥ 99.08 %, static 42 untouched);
  244 tests green. See docs/QUARTZ_NOTES.md "M6: animation engine".
- **M7 Interactive host** — SDL2 (or bare-metal per-platform) window backend:
  UIWindow/UIScreen, run loop, touch/mouse event delivery, hit testing,
  UIGestureRecognizer (tap/pan/long-press).
- **M7.5 App Feel** — USER PRIORITY: real multi-screen demo app on OpenUIKit (Sources/DemoApp via openhost --app): UIScrollView with UIKit-exact physics (0.998/ms deceleration, 0.55 rubber-band, bounce springs), nav push/pop parallax transitions, row highlight feel. Spec: docs/APP_FEEL.md.
  - UIScrollView DONE (2026-08-24): contentOffset = bounds.origin through both
    compositors (scroll_static oracle golden 100.0), closed-form physics per
    APP_FEEL (UIScrollPhysics: 0.998/ms deceleration, c=0.55 rubber-band,
    critically damped ~0.5 s bounce carrying release velocity, exact
    deceleration→edge handoff), ~100 ms release-velocity window,
    delaysContentTouches/touchesShouldCancel in the window pipeline,
    2.5 pt indicators with 0.4 s fade on the UIView.animate clock, physics
    stepped from UIWindow.tick (host clock — deterministic scripted
    captures, scripts/scroll_flick.json). 20 tests (UIScrollViewTests).
  - Navigation DONE (2026-08-24): UIViewController (lazy loadView/viewDidLoad,
    UIKit-ordered appearance callbacks via begin/endAppearanceTransition,
    containment), UINavigationController (44 pt bar + 20 pt status inset over
    a clipped content area; push/pop = 0.35 s easeInOut slide with −0.3·width
    parallax, 0→8 % scrim, soft leading-edge shadow, driven by UIView.animate;
    completion on the host clock via UIWindow.tick → _stepTransitions) and
    UINavigationBar (semibold-17 centered title, "‹ previous-title" back
    button with the 0.2-alpha pressed dim, 0.5 pt hairline, title crossfade/
    slide with the transition). Interactive left-edge back-swipe scrubs the
    pop, completes > 50 % / ≥ 300 pt/s, cancels with a spring. 13 tests
    (NavigationControllerTests incl. a rendered mid-transition pixel probe);
    scripted capture: `openhost --nav-demo --script scripts/nav_push.json`.
    Scope notes in docs/KNOWN_GAPS.md.
  - Demo app + app hosting DONE (2026-08-24) — M7.5 COMPLETE: Sources/DemoApp
    (library target, no Foundation — reference for idiomatic OpenUIKit app
    code) with three screens per APP_FEEL: Settings root (profile card +
    16 icon-tile rows in grouped cards inside a UIScrollView, disclosure
    pushes, switch rows, systemGray4 highlight flash with 0.3 s
    UIView.animate fade), Display & Brightness (switch group + pan-driven
    UISlider-style brightness slider with live footnote), About (value rows
    + long scrollable colophon). Icon tiles are hand-drawn Canvas paths (16
    glyphs, no SF Symbols). `openhost --app demo` boots the
    UIApplication-lite (390x780 window, default --scale 1); hosts now run
    layout-before-draw (window.layoutIfNeeded() per frame) and dirty-flag
    rendering — a frame renders only on input, active scroll/nav animation,
    or before OpenUIKitRuntime.animationWorkDeadline; idle costs zero.
    Acceptance: scripts/appfeel_demo.json scripted run (flick → momentum →
    rubber-band → settle, row highlight, push mid-transition, switch
    toggle, slider drag, pop) — every frame visually verified;
    scripts/appfeel_demo.gif. Suite 56/56, swift test 305 green.
- **M8 (perf) Layer-contents caching — DONE**: CA-style content-image +
  stable-subtree composite caches in LayerBridge (fingerprint-driven, no
  invalidation wiring; setNeedsDisplay for custom drawContent) + quartz
  patch 004 (unit-scale blit, rect fill/clip fast paths) + offscreen
  culling. Sustained scroll: 145 → ≈ 8.7 ms/frame at scale 2, 39 → ≈ 3.0 ms
  at scale 1 (60 fps both; --app defaults to scale 2 again). Settled frames
  bit-identical with caching off; suite unaffected. See APP_FEEL
  "Performance".
- **M7.6 (app feel, second pass) — DONE (2026-08-24)**: three fixes on top of
  the M8 caching merge, plus a re-recorded acceptance GIF.
  - `UIView.animate` completions now fire ON THE HOST CLOCK instead of
    synchronously (the M6 divergence in KNOWN_GAPS): queued at
    `begin + delay + duration`, delivered by
    `UIView._stepAnimationCompletions(to:)` from `UIWindow.tick` after the
    scroll/transition steppers. Blocks that record no animation still
    complete immediately (UIKit creates no CAAnimation); handlers due in one
    tick run as one batch, so a completion that starts a new animation is
    served on a later tick. `_hasPendingAnimationCompletions` joins openhost's
    dirty check. Residual: `finished` is always true (no cancellation path).
  - Row highlight now cancels the moment the finger drags: the scroll pan
    claims its content touches at 5 pt of travel along a scrollable axis
    (`UIScrollView.contentTouchCancelDistance`), ahead of its own 10 pt
    recognition slop, so the row is already fading when the content starts
    to move. Gated by the same axis/`touchesShouldCancel` rules as the begin
    gate. This closes the last "not done" item in APP_FEEL's row-feel list.
  - Push pre-warm measured and REJECTED — the incoming screen's first frame
    is irreducible rasterization, and both variants tried either made the
    first live frame worse or perturbed a capture frame. The probe
    (scripts/perf_push.json) instead found the real cost: the tapped row's
    0.3 s highlight fade invalidates its whole ancestor chain, so the
    OUTGOING screen re-composites at ≈ 24 ms/frame for the entire 0.35 s
    transition. Partial subtree composites are the follow-up. Numbers in
    APP_FEEL "Push transition cost".
  - scripts/appfeel_demo.gif re-recorded through the M8 caching pipeline at
    scale 2 — the same 14-state acceptance timeline, now captured on the
    60 fps path (sustained scroll 145.3 → 8.7 ms/frame at scale 2, 39.0 →
    3.0 ms at scale 1; scripts/perf_scroll.json). All 14 frames visually
    verified. Suite 56/56, swift test 317 green.
- **M8 Scroll + text input** — UIScrollView (quartz scroll_layer), deceleration
  curves vs oracle traces; UITextField/UITextView basics with caret/selection.
  - Scroll physics vs oracle traces DONE (2026-08-24): real-UIKit ground
    truth measured via synthetic UITouch drags in the iOS 26.1 Simulator
    (Tools/oracle2/simprobe, scripts/scroll_probe_sim.sh; the Catalyst
    channel turned out to exercise only the Mac POINTER physics — kept as
    documentation in golden/scroll_traces/catalyst_pointer/). Constants
    corrected from the traces: 10 pt/s decel stop + 0.499 per-ms-sum
    position factor, two-regime bounce spring (ω=11 crit with velocity,
    λ=9/46 overdamped from rest), exact 10 pt slop absorption; 0.998/ms
    and c=0.55 confirmed. Gate: Tools/compare/compare_scroll.py replays
    the trace inputs through OpenUIKit (`openrender scrolltrace`) — 9/9
    within decel ≤2 pt / rubber-band ≤1 pt / settle ≤10%. Details:
    APP_FEEL "Measured scroll physics".
  - Text input DONE (2026-08-24): UITextField (.roundedRect chrome, all
    metrics measured off real UIKit — Catalyst textprobe) + UITextView
    (TextKit insets/line heights), oracle-verified static scenes
    textfield_basic / textview_basic at 99.87 / 99.97; first-responder
    system (UIView become/resign, UIWindow.firstResponder + sendText/
    sendKey), caret (2 pt tint bar, deterministic host-clock blink,
    glyph-advance positioning + tap-to-place), editing model with
    .editingDidBegin/Changed/DidEnd, horizontal keep-caret-visible scroll,
    multiline caret movement; openhost SDL_TEXTINPUT/KEYDOWN wiring +
    scripted text/key events; `--app textdemo` + scripts/textinput_demo.gif.
    Selection is out of scope (docs/KNOWN_GAPS.md "Text input").
- **M9 Auto Layout — DONE (2026-08-24)**: pure-Swift Cassowary (kiwi-style
  incremental simplex, deterministic pivoting) in
  Sources/OpenUIKit/AutoLayout/; NSLayoutConstraint
  (item/attribute/relation/multiplier/constant/priority, activate installs on
  the nearest common ancestor), full anchor API, UILayoutPriority,
  translatesAutoresizingMaskIntoConstraints (true = frame enters as required
  edge constraints), intrinsic-size constraints at hugging (<=) /
  compression-resistance (>=) priorities (defaults 250/750, labels 251
  vertical hugging), label firstBaseline/lastBaseline from the draw-path
  ascender rounding. Solving happens in layoutIfNeeded before the
  layoutSubviews recursion, in root space; oracle-fitted post-solve rounding
  (origins -> nearest integer point ties-away, sizes -> nearest 0.5 pt, per
  view in LOCAL coordinates). Gate: all 12 constraints_* scenes at 0.000
  layout delta + pixel pass (70/70 suite), 9/9 scroll traces, 353 tests.
  UIStackView still lays out by direct frame computation (works; refit onto
  the solver is future work).
- **M10 App framework — DONE (2026-08-25)**: UIViewController lifecycle,
  UINavigationController, UITabBarController, UITableView with cell reuse,
  modal presentation and iOS 26 large titles, all exercised together by a
  real three-tab app (`openhost --app showcase`). UICollectionView was NOT
  attempted (see docs/KNOWN_GAPS.md).
  - UITableView DONE (2026-08-25): UIScrollView subclass with REAL cell
    reuse (only visible rows instantiated — proven by a 10k-row sweep
    test; per-identifier pools + dequeueReusableCell/register), plain +
    insetGrouped chrome measured off the M10 goldens (51.5/70.5 pt rows,
    40.5 pt headers, 22 pt plain top padding, sticky plain headers,
    26 pt-radius cards, measured separator insets + selected-adjacent
    hiding), UITableViewCell default/subtitle/value1 with vector
    chevron/checkmark accessories and the #DCDCDC selection flash /
    0.3 s deselect fade (APP_FEEL row feel through the scroll view's
    content-touch pipeline), UITableViewController, openrender scene
    wiring. Gate: tableview_plain/grouped/dark/selected at
    97.9/98.2/97.7/98.3 (chrome ≥95), 11 new tests, sustained flick
    scroll of a 96-row table at 3.5–4.5 ms/frame scale 2 with cells
    compositing from cached rasters (scripts/perf_table.json — cache
    hit/build ≈ 14/0 per steady frame).
  - Showcase app DONE (2026-08-25) — M10 COMPLETE:
    `swift run -c release openhost --app showcase` boots a
    UITabBarController over three independent UINavigationController
    stacks (Settings / Tasks / Text), each keeping its own stack, scroll
    position and control state across tab switches. What this milestone
    added on top of the framework pieces:
    - **Tasks rebuilt on a real UITableView** (`.insetGrouped`, 16 pt side
      inset, `register`/`dequeueReusableCell`, dataSource + delegate,
      `TaskCell`/`IconCell`/`PlaceholderCell`). It keeps the pre-table
      feel: checkbox spring pop, the animated move of a row between
      TODAY and COMPLETED, row highlight (now UITableViewCell's own
      measured #DCDCDC flash + 0.3 s fade, and the UIKit
      select-on-push / deselect-on-return convention).
    - **`UITableView.performUpdates(withDuration:delay:options:identity:
      updates:completion:)`** — the portable stand-in for UIKit's
      `moveRow`/`insertRows` batch updates. Rows are matched across the
      update by a caller-supplied stable identity, so a row that moves
      (even between sections) KEEPS ITS CELL and any animation running
      inside it, while cards, headers and every other visible row animate
      into place around it in the same block. New rows fade in; a row
      crossing the gap between two cards borrows the card fill for the
      flight and dissolves it over the last 0.12 s (a hard restore would
      square off the card's 26 pt corners as it lands). Finished
      animations are dropped on completion — `UIView`'s new internal
      `_removeFinishedAnimations(at:)`, because a completed animation
      still pins the layer to its recorded end value and would override
      the frames the next tiling pass assigns. 4 tests
      (TableViewAnimatedUpdateTests).
    - **Settings runs with `prefersLargeTitles`**: the root binds its
      scroll view with `setContentScrollView(_:)`, so the 34 pt title
      collapses into the inline title over the scroll-edge pocket.
    - **Profile sheet**: the Settings profile card presents a
      `.pageSheet` profile editor (two UITextFields + Done) with the M10
      presentation API; typing goes to the sheet's fields and Done writes
      the name back to the card.
    - `BottomInsetAdjustable` (DemoApp): the floating tab bar owns the
      bottom 72 pt of EVERY screen and nothing reserves it automatically
      (no safe-area model in the portable core), so the container hands
      the inset down to roots and pushed screens.
    - Acceptance: `scripts/showcase_demo.json` — 116 captured frames over
      one 10.9 s timeline (tab switching, table flick with momentum, row
      select highlight, modal present mid-transition + typing + dismiss,
      large-title collapse mid-scroll, cross-section row move, push/pop),
      every frame visually verified; `scripts/showcase_demo.gif`.
    - Perf (scripts/perf_showcase_table.json, scale 2, M3 Max): Tasks
      table flick ≈ 22 ms/frame (≈ 45 fps, 6.2 ms / 60 fps at scale 1),
      Settings large-title scroll ≈ 18 ms/frame. Both are over the 16.6 ms
      budget at scale 2; the diagnosis and the rejected fix are in
      docs/APP_FEEL.md "Inset-grouped table scroll cost".
    - Gates: 80/80 scenes, 9/9 scroll traces, 385 tests.

- **M11 Interactive sheets + structural comparison gate — DONE
  (2026-08-25)**: two things the previous milestones left as known holes.
  - **Interactive pageSheet.** M10 shipped the sheet's mechanics; M11 ships
    its behaviour, measured rather than guessed. New oracle
    `Tools/oracle2/sheetprobe` (`scripts/sheet_probe_sim.sh`) drives a live
    `UISheetPresentationController` in a headless iOS 26.1 simulator with
    synthetic UITouch drags and samples the sheet frame + dim opacity per
    display-link frame — the sibling of M8's scroll SimProbe. What it
    established, and what now ships: 1:1 tracking after exactly 10 pt of
    slop; **no upward rubber band at all** (the natural guess was wrong —
    iOS refuses to move a sheet above its detent); dimming exactly linear in
    drag progress (`0.2·(1 − offset/height)`, residual ≤ 0.0025); dismissal
    past **50 % of the sheet's height** (proportional, confirmed against a
    400 pt custom detent) **or ≥ 1000 pt/s**; one critically damped settle
    spring at **ω = √(1000/3) = 18.2574** for both outcomes (rms 0.02–0.05 pt
    over the whole curve); the **grabber** (36 × 5 pt, r 2.5, 5 pt below the
    top, systemFill base at α 0.4295) behind `prefersGrabberVisible`; and the
    **sheet ↔ inner scroll view hand-off**. The measured sheet top inset
    (59 pt, read off the live frame) replaced M10's 59.5 pt golden fit and
    improved both modal scenes. New golden `modal_sheet_grabber` (81 scenes).
    Detents were measured in full and **deliberately deferred** — the spec is
    in docs/KNOWN_GAPS.md, because a non-large detent is a scale transform
    plus a resizing drag, not another rest position.
  - **Structural diff gate.** `navbar_large` once passed its 95 % threshold
    while rendering "Library" as "Li rar" (docs/PORTABILITY.md). compare.py
    now labels the connected components of the severe-diff mask (delta > 150)
    and fails any frame with a contiguous wrong region over 80 pt²,
    independent of the percentage. Calibrated on all 81 scenes: worst
    legitimate component 33.2 pt², the historical corruption 248.8 pt².
  - Acceptance: `scripts/sheet_drag.json` — mid-drag, spring-back, completing
    dismissal and the scroll hand-off, every frame checked against the
    closed-form spring and read as an image.
  - Gates: 81/81 scenes (with the structural gate active), 9/9 scroll traces,
    398 tests, Linux still byte-identical.

## M12 — app-compat: alerts + the custom-transition API (2026-08-25)

Driven by the census in docs/APP_COMPAT.md: `UIAlertController` is the
third-largest cluster (332 uses) and the custom-transition cluster (64 uses)
is what lets an app supply its own present/push animations.

- **`UIAlertController` / `UIAlertAction`**, both styles, measured — not
  guessed — from real iOS 26.1 in the headless Simulator by the new
  `Tools/oracle2/alertprobe` (`scripts/alert_probe_sim.sh`): 20
  configurations, each dumping the whole private view tree in window
  coordinates plus a window snapshot, one configuration per app launch
  (alerts do not tear down fast enough to share a process). Findings that
  overturned the obvious guesses:
  - iOS 26's alert is a **320 pt card with 34 pt continuous corners and
    48 pt PILL buttons**, centred in the window's **safe area** (438.5 on a
    393 × 852 window, not the window centre 426).
  - **An action sheet on iPhone is laid out identically to an alert** — the
    slide-up bottom sheet is gone. (Touching
    `popoverPresentationController` at all flips it into a popover and
    silently drops the cancel action.)
  - Action titles are **`label`, not tint blue**; `.destructive` is
    systemRed; two actions sit side by side with **cancel on the LEFT
    whatever order they were added**, three or more stack with cancel last.
  - The card and pills are blurs; both were solved as flat colour + alpha by
    rendering the same alert over four known bases per appearance
    (residual < 1.5 counts). Divergence recorded in docs/KNOWN_GAPS.md.
  - The **present transition animates only the dimming view**, on a
    critically damped spring of ω = 22.88 rad/s (converged over 24
    display-link frames); the card carries no animation on its layer or any
    ancestor.
  - Scene spec **v5.2**: a top-level `"alert"` key, routed to the Simulator
    like `"modal"`. New goldens `alert_basic`, `alert_destructive`,
    `alert_actionsheet`, `alert_dark` (85 scenes).
- **The transitioning API** (`UIPresentationController`,
  `UIViewControllerAnimatedTransitioning` + context + transitioning
  delegate, `UINavigationControllerDelegate`) and the **refactor**: the sheet
  presentation's dim/platter moved onto `UISheetPresentationController` and
  its animation into `_UIPageSheetAnimator`; push/pop dispatches through
  `_UINavigationSlideAnimator`. Behaviour is unchanged by construction (the
  code moved, the constants did not) and the whole existing suite proves it.
  No interactive transitioning — the back swipe and the sheet drag stay
  clock-scrubbed from measured physics (docs/KNOWN_GAPS.md).
- Gates: 85/85 scenes, 9/9 scroll traces, 418 tests, Linux still
  byte-identical (139/139 frames).

## Verification principle (unchanged, applies to every milestone)

Every feature ships with fixture scenes rendered by BOTH real UIKit (oracle)
and OpenUIKit, pixel- and layout-diffed in CI (`scripts/` + compare.py).
Animations/interaction verify against time-sampled oracle captures.
