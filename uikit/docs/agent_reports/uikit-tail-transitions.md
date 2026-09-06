# Corpus tail #1 and #8 — transition coordinator + property animator

Branch: `agent/uikit-tail-transitions`. Device: iPhone SE (3rd gen) 2x /
iOS 26.1, simulator `OpenUIKit-2x-uikit-tail-transitions`. Probe app
`/tmp/uikit-tail-animprobe` (not in the repo); numbers below are from
`/tmp/uikit-tail-animprobe/report.json`.

This lands the public handles onto M6's frame-exact animator and M7.5/M12's
push/present paths. No new pixel rule: Catalyst goldens, the iOS suite miss,
and the real-app floors are unchanged.

## What was measured (iOS 26.1)

### `UIViewPropertyAnimator`

- Defaults: `state` inactive, `isRunning` false, `isReversed` false,
  `fractionComplete` 0, `isInterruptible` true, `isUserInteractionEnabled`
  true, `isManualHitTestingEnabled` false, `scrubsLinearly` true,
  `pausesOnCompletion` false, `delay` 0.
- `UICubicTimingParameters(animationCurve:)`: easeInOut (0.42, 0, 0.58, 1),
  easeIn (0.42, 0, 1, 1), easeOut (0, 0, 0.58, 1), linear (0, 0, 1, 1);
  `timingCurveType` builtIn (0). Custom points: type cubic (1), curve raw 6.
  Default init: CSS ease (0.25, 0.1, 0.25, 1), curve raw 5.
- Running 1 s move, box center.x 50→150:
  - linear: `fractionComplete` = elapsed time; x = 50+100·t
    (t=0.25/0.5/0.75/1 → 75/100/125/150).
  - easeInOut: `fractionComplete` still linear; pixels follow the cubic
    (t=0.25 → progress 0.12916 → x=62.916; probe t≈0.243 → x=62.14).
  - spring ζ=0.5 D=1: t≈0.297 → x=166.15, same family as
    `UIView.animate(usingSpringWithDamping:)`.
- Normal completion **releases** the animator (inactive, not stopped).
- `stopAnimation(true)` from paused → inactive, completions skipped, model
  restored to FROM (alpha 1 after 1→0).
- `finishAnimation(at: .start)` from stopped → inactive, model at start.
- Setting `fractionComplete` on inactive → state active, `isRunning` false.

Scrub presentation-layer CA samples in the probe always reported the model
value (no flush); running CADisplayLink tracks are the pixel oracle. Scrub
in the port is `speed=0` + `timeOffset`.

### `transitionCoordinator`

- Non-nil on from, to, and the navigation controller during animated push;
  still non-nil in `viewDidAppear`; nil after the transition ends.
- Push: duration **0.35**, `presentationStyle` `.none`, `completionCurve`
  raw **7**, `completionVelocity` 1, not interactive/interruptible,
  `targetTransform` identity, `percentComplete` 0 at `viewWillAppear`.
- PageSheet present: style pageSheet, `completionCurve` easeInOut (0),
  **`transitionDuration` 0 at `viewWillAppear`**, presenting controller
  also vends the coordinator.
- `animate(alongsideTransition:)` returns true; the animation block is
  **not** synchronous in `viewWillAppear`; completion runs after the
  transition.
- Non-animated present/push: coordinator nil.

Physical mass/stiffness/damping springs are stored and converted to a
damping ratio for the existing duration-fit evaluator. An independent
ω-from-mass duration was not measured and is not invented.

## Rule

- Coordinator attached **before** appearance will-callbacks on animated
  push/pop/present/dismiss; `complete(cancelled:)` runs **after**
  `viewDidAppear`. Alongside is queued at register and flushed inside the
  built-in `UIView.animate` / spring block (custom animators get
  `flushAlongsideIfNeeded`).
- Push curve raw 7 is `UIView.AnimationCurve.navigationTransition`.
- Property animator state machine + cubic/spring timing on the existing
  host-clock transaction engine (`pacesLinearly` only while scrubbing).

## Before / after

No pixel rule changed. Built-in slide/sheet springs are the same records.

| gate | before | after |
|---|---|---|
| Catalyst | 124/124 | **124/124** (`/tmp/gate-uikit-tail-transitions`) |
| iOS suite | 112/113 (`corner_radius` 99.411) | **112/113** (`corner_radius` 99.411) |
| real-app floors | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.170 / 99.86 / 99.734 / 85.393 | **held** (`/tmp/app-uikit-tail-transitions` vs `/tmp/golden_realapp_ios`) |
| Linux `swift:6.2-noble` openrender | green | **green** (189.48 s) |

`TransitionAnimatorTests` 9/9, `IOSDevicePixelMetricsTests` animator rows,
`FocusLaunchCoreTests` property-animator cases (completion state is now
`.inactive`, matching the probe), `PresentationControllerTests` callback
order, `ViewControllerLifecycleTests` animated push. Present/NavFlow pixels
were not retouched.

## 20-app census this unblocks

`full/ladder/uikit-union-2026-08-27.json` (APP_LADDER.md §4):

| type | apps | uses |
|---|---|---|
| `UIViewControllerTransitionCoordinator` | 18 | 141 |
| `UIViewPropertyAnimator` | 11 | 151 |
| `UIPercentDrivenInteractiveTransition` | 5 | 27 |
| `UIViewControllerInteractiveTransitioning` | 4 | 14 |
| `UIViewControllerTransitionCoordinatorContext` | 3 | 8 |
| `UISpringTimingParameters` | 4 | 4 |
| `UIViewImplicitlyAnimating` | 2 | 3 |
| `UICubicTimingParameters` | 1 | 1 |

Blocking ranks: coordinator is corpus tail **#1** (highest app-reach of
the remaining UIKit types); property animator is tail **#8**.

## Open questions (not guessed)

- Physical `init(mass:stiffness:damping:)` duration vs the duration-fit
  ζ spring: stored, not independently timed.
- Interruptible `UIViewPropertyAnimator` returned from
  `interruptibleAnimator(using:)` vs built-in back-swipe: built-in swipe
  stays on its measured host-clock scrub path.
- Rotation size transitions still have no coordinator vendor (host owns
  the surface).
