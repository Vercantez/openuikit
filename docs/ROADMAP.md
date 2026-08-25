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
- **M8 Scroll + text input** — UIScrollView (quartz scroll_layer), deceleration
  curves vs oracle traces; UITextField/UITextView basics with caret/selection.
- **M9 Auto Layout** — cassowary solver, NSLayoutConstraint/anchors API,
  validated against oracle layout dumps of constraint scenes.
- **M10 App framework** — UIViewController lifecycle, UINavigationController,
  UITabBarController, UITableView/UICollectionView with cell reuse; demo app
  (settings-style screen) running identically on macOS host and Linux.

## Verification principle (unchanged, applies to every milestone)

Every feature ships with fixture scenes rendered by BOTH real UIKit (oracle)
and OpenUIKit, pixel- and layout-diffed in CI (`scripts/` + compare.py).
Animations/interaction verify against time-sampled oracle captures.
