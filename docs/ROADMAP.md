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
- **M2 Text layout** — DONE for layout (0 layout issues on all label scenes);
  glyph-ink fidelity in progress (91–95% → target ≥97%)
- **M3 Controls** — in flight: UIButton, UIImageView, UIProgressView,
  UIStackView, UISwitch + oracle v2 (real-window drawHierarchy)
- **M4 Quartz backend switch** — vendor libquartz, Canvas backend abstraction,
  full suite dual-backend comparison, adopt quartz as default
- **M5 CALayer adoption** — replace the RenderPass traversal with quartz's
  real layer tree (QZLayer): UIView owns a QZLayer; compositing, masks,
  shadows, opacity groups handled by the compositor. Unlocks layer features
  UIKit users expect: shadowPath, masks, rasterization.
- **M6 Animation** — UIView.animate(withDuration:) on quartz's animation/
  timing engine; CADisplayLink-style driver; presentation vs model layer.
  Oracle: frame-by-frame comparison against real UIKit animations captured
  at fixed timestamps.
- **M7 Interactive host** — SDL2 (or bare-metal per-platform) window backend:
  UIWindow/UIScreen, run loop, touch/mouse event delivery, hit testing,
  UIGestureRecognizer (tap/pan/long-press).
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
