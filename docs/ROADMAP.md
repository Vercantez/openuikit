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
- **M9 Auto Layout** — cassowary solver, NSLayoutConstraint/anchors API,
  validated against oracle layout dumps of constraint scenes.
- **M10 App framework** — UIViewController lifecycle, UINavigationController,
  UITabBarController, UITableView/UICollectionView with cell reuse; demo app
  (settings-style screen) running identically on macOS host and Linux.

## Verification principle (unchanged, applies to every milestone)

Every feature ships with fixture scenes rendered by BOTH real UIKit (oracle)
and OpenUIKit, pixel- and layout-diffed in CI (`scripts/` + compare.py).
Animations/interaction verify against time-sampled oracle captures.
