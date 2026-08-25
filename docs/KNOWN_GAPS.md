# Known gaps (living document — fixers: read this)

## Navigation / view controllers (M7.5, 2026-08-24): scope notes

- Transition geometry/timing implements APP_FEEL exactly (0.35 s easeInOut,
  +width→0 slide, −0.3·width parallax, black 0→8 % scrim, soft edge shadow
  sigma 4.5 pt / opacity 0.15) and is verified against the closed forms in
  ViewControllerLifecycleTests (incl. a rendered mid-transition pixel
  probe). Not oracle-captured yet — oracle2 time-sampling of a real
  UINavigationController push (per APP_FEEL "Oracle strategy") is still
  open; the bar title/back crossfade-and-slide parameters (0.35·W title
  slide, fast 40 %-duration back-label fade) are feel approximations.
- Completion model: transition CLEANUP + viewDidAppear/viewDidDisappear
  fire from the host clock via their own registry (they predate the
  clock-driven UIView.animate completions and do not use them) —
  UIWindow.tick calls UINavigationController._stepTransitions
  (same pattern as the scroll hook; one additive line in UIEvent.swift,
  coordinated with the event module). A host that renders without ticking
  shows the settled final frame but never completes the stack/lifecycle;
  `UINavigationController._hasActiveTransition` is the redraw hint.
- Appearance callbacks fire on nav-container install/push/pop only; there
  is no window-attachment notion in the portable core (the root VC gets
  willAppear/didAppear when the nav view loads, not when it joins a
  window). beginAppearanceTransition/endAppearanceTransition are public
  and UIKit-shaped, including the cancelled-interactive-pop reversal.
- Interactive back-swipe: left-edge (< 20 pt) pan scrubs the pop 1:1;
  release completes at > 50 % progress or ≥ 300 pt/s forward fling
  (≤ −300 pt/s always cancels), tail animated with a critically-damped
  0.35 s spring. The 300 pt/s threshold is feel-tuned, not measured. No
  recognizer dependency system exists (M7 note): the edge pan coexists
  with content recognizers and relies on its direction gate (leads
  horizontally away from the edge) — a horizontally scrollable view under
  the edge would fight it; require(toFail:) is the eventual fix.
- No UINavigationItem: the bar shows vc.title and "‹ previous-title"
  ("Back" fallback) only; no rightBarButtonItems, prompts, large titles,
  bar button customization, or bar blur (APP_FEEL allows the hairline
  bar). setViewControllers, hidesBarsOnSwipe, toolbars: not implemented.
  popToRootViewController collapses the middle of the stack instantly and
  animates only the top pop.

## UIScrollView (M7.5, 2026-08-24): scope notes

- Physics constants are APP_FEEL's documented UIKit values (0.998/ms,
  c=0.55, ~0.5 s critically damped bounce via the ωT=9.2334 settle
  equation, 0.1 pt/s stop, ~100 ms velocity window, ~150 ms content-touch
  delay). Static scrolled RENDERING is oracle-verified (scroll_static,
  100.0 incl. hit tests); the dynamic curves are unit-tested against the
  closed forms only — oracle time-sampled traces come with M8
  (drive a real UIScrollView pan in oracle2 and diff position series).
- Deceleration/bounce is stepped by UIWindow.tick(timestamp:), which
  openhost calls every frame/script step. A host that renders without
  ticking sees a frozen scroll (call tick, or
  UIScrollView._stepScrollAnimations(to:), before rendering).
  `UIScrollView._hasActiveScrollAnimations` is the redraw hint.
- Indicator visuals (35 % black/white bar, 36 pt min length, both-axis
  bars flash whenever either axis scrolls) are feel-approximations, not
  oracle-fitted; they are lazily created so static scenes/layout dumps
  never see them. Fade is UIView.animate alpha (model alpha drops to 0
  at settle; presentation fades 0.4 s).
- touchesShouldCancel(in:) defaults to true for ALL views including
  UIControls (modern-UIKit behavior — scrolling cancels button/row
  tracking); the pre-iOS-8 documented control exception is not
  reproduced. directionalLockEnabled, paging, zooming, scrollsToTop,
  contentInsetAdjustmentBehavior and scroll-to-top/flash APIs are not
  implemented. setContentOffset(animated:) uses 0.25 s easeInOut.
- A touch-down that catches a decelerating scroll consumes the whole
  touch (content never sees it) — matches UIKit's stop-scroll tap.
  Nested scroll views are untested (single scroll view per touch path).

## demo_settings: remaining FAIL is window-capture ALPHA ENCODING, not text

After the text fixes below (2026-08-24), demo_settings measures 95.42 against
golden with compare.py's raw-channel diff, but 99.54 when both images are
composited over white with the golden interpreted as PREMULTIPLIED alpha.
Root cause: oracle2 (drawHierarchy) window captures store semi-transparent
pixels premultiplied — the `tertiarySystemFill` search bar is
(14,14,15,a=30) in golden (= 118·30/255) where our PNG stores straight
(115,115,123,a=31). That one 350x36pt bar is ~4.1% of the scene's pixels,
all counted as mismatches by the raw-channel compare. Owner: fixture
(compare.py could normalize encodings) or rendercli/rasterizer (premultiply
window-scene output). NOT the text module: every text region of the scene
now matches within tolerance. Opaque pixels are unaffected (premultiplied ==
straight at alpha 255), which is why deep_mixed passes.

## Glyph ink harvest: coverage tooling now automated (2026-08-24)

`OPENUIKIT_INK_LOG=<path> openrender render ...` dumps every ink-table miss
("W|family|size|style|tag|codepoint" for window-table misses, "O|..." for
offscreen). Harvest tooling (text-fixer scratchpad `h2/`): gen.py turns the
miss list into space-prefixed single-glyph probe scenes at integer x (all
phase tags per missed char, validation cells included), rendered by BOTH
oracle1 (offscreen entries) and oracle2 (window entries); extract2.py
validates extraction against already-stored entries (geometry byte-exact;
values within ±1 count — the residual of representing each phase BIN by one
mask) and merges only new keys. Dark-mode cells: Catalyst dark
systemBackground renders lum 30, full label ink 221, so masks are
v = round((lum-30)·255/191) with bbox threshold lum > 30.6 (validated ±2
counts against the stored regular-17 dark entries).
Coverage added: all button_states/button_dark/demo_settings combos
(regular 11/13/14/15/17/20/24, light/medium/heavy/bold 17, bold 34,
semibold 17 incl. U+203A, regular-15 dark, semibold-17 dark; window
variants for demo_settings' strings). Regression tests:
GlyphInkTableTests.testOffscreenCoverageForButtonStates /
testWindowCoverageForDemoSettings / testOffscreenDarkCoverageForButtonDark.

## Non-ASCII advances: vendored in font_metrics.json (2026-08-24)

Resources/font_metrics.json "advances" now also carries oracle-measured
non-ASCII advances (– — ‘ ’ “ ” • … ‹ › · × ° →, all families/weights/
sizes; scratchpad advprobe.swift, same NSString.size measurement as the
oracle's fontmetrics dump). FontEngine interpolates them like ASCII ones;
U+2026 keeps its exact label-context (tight-table) advance. This fixed all
14 demo_settings layout failures (U+203A at semibold-17 is 7.5693pt → 8pt
ceiled label width; the old font-file fallback gave 7pt).

## Text in window scenes: SOLVED mechanism, extend coverage as needed

Window scenes (`"window": true`, oracle2/drawHierarchy goldens) rasterize
label glyphs darker/crisper than offscreen `layer.render` — real UIKit's
own offscreen render of deep_mixed mismatches the window golden by the same
~5% the old renderer did, and no pointwise coverage transfer reproduces it
(it is a spatial re-rendering). Fix (text module): window-variant ink masks
in `Sources/OpenUIKit/Resources/glyph_ink_window.json`, harvested with the
SAME probe methodology as glyph_ink.json but rendered through oracle2
(space-prefixed single-glyph labels at integer x; extraction validated
byte-exact against the offscreen table first). Selected via
`GlyphInkTable.windowCompositing`, set by openrender from the scene's
`window` flag; per-glyph fallback to the offscreen table. Coverage today:
deep_mixed's strings (fixed deep_mixed 95.95 → 99.64) plus all of
demo_settings' strings (34pt bold title, 17pt regular/semibold incl. U+203A,
13pt incl. U+2014, 15pt button titles) via the automated miss-log harvest
(`h2/` in the text-fixer scratchpad, successor of `wharvest/`); see
"Glyph ink harvest" above. Window dark mode remains unharvested (no window
dark scene exists yet).

## Text module: glyph_ink.json harvest coverage — RESOLVED 2026-08-24

Item 1 of the old diagnosis (harvest coverage + non-ASCII advances) is fixed;
see the two sections above. button_states 94.90 → 96.60 PASS. Still open:

- **drawMask blend calibration.** Exact for the `.label` color it was fitted
  on; ~9 counts dark at AA edges for pure black and tint-blue titles. All
  diffs on fully-harvested strings are ≤15 counts. Consider color-dependent
  calibration or fitting the blend exponent per ink color family. (Was not
  needed to pass button_states once coverage landed.)
- Button path is NOT the problem: button text renders byte-identically to the
  label path (verified by A/B probe, commit 0d4da17).

## UIButton (fixed, for the record)
Real UIKit gives the title label the FULL bounds width (squeeze to
floor(width)) and truncates button titles MIDDLE, not tail (commit 0d4da17).

## Earlier accepted residuals (within thresholds, from M2/M3)
- Dark-mode saturated-color text (label_dark link row) has a different ink
  profile than the default color — needs color-keyed harvests.
- truncateHead/Middle per-char tight-advance quantization subtlety (≤+0.11pt).
- Light saturated-color glyphs: small mask-shape differences beyond the gamma
  model.

## Event system (M7, 2026-08-24): scope notes

- switch_toggle_anim goldens are WALL-CLOCK captures (the modern UISwitch
  thumb is display-link driven and ignores frozen-clock seeks; see the
  switch-setOn section of docs/SCENE_SPEC.md). Frames carry a few ms of
  scheduling jitter — regenerating that golden produces near- but not
  byte-identical frames. Our fitted model currently scores ≥ 98.3 per
  frame (threshold 96), leaving ~2 points of jitter headroom.
- UISwitch drag-to-toggle (thumb tracking during a pan on the switch) is
  not implemented — tap-to-toggle only. UIControl uses plain
  point(inside:) for isTouchInside (UIKit uses a ~70 pt outset during
  drags on some controls).
- Gesture recognizer dependencies (require(toFail:), delegate methods,
  simultaneous recognition) are not implemented; recognizers observe
  independently. UITouch.tapCount timing constants (0.35 s / 30 pt) are
  host-tunable statics on UIWindow, not oracle-derived.
- Long press with no intervening events fires on the NEXT event/tick at
  or after minimumPressDuration (no run loop in the core — the host's
  `tick(timestamp:)` provides time-only advance).

## Animation engine (M6, 2026-08-24): scope notes

- Presentation sampling requires the DEFAULT pipeline (quartz backend +
  layers compositor). Under `OPENUIKIT_COMPOSITOR=renderpass` or
  `OPENUIKIT_BACKEND=swift` animation scenes render MODEL values only
  (every frame = final state). Owner: view module, only if a host ever
  needs animated rendering on the pure-Swift path.
- `UIView.animate` completion handlers now fire ON THE CLOCK (M8.1, was
  synchronous): they are queued at `begin + delay + duration` and
  delivered by `UIView._stepAnimationCompletions(to:)`, which
  `UIWindow.tick(timestamp:)` calls after the scroll/transition steppers.
  A host that advances `OpenUIKitRuntime.animationTime` without ticking a
  window never delivers them (`UIView._hasPendingAnimationCompletions` is
  the redraw hint; openhost's dirty check includes it). Residual
  divergences: `finished` is always `true` — there is no cancellation
  path, so replacing an in-flight animation on the same property does not
  deliver `false` the way CA's `didStop` does, and `removeAllAnimations()`
  leaves a queued completion to fire at its original end time. A block
  that records no animation completes immediately (matching UIKit, which
  creates no CAAnimation). Handlers due in one tick run as a single batch,
  so a completion that starts a new animation gets its completion on a
  later tick — one run-loop turn per batch.
- Spring initialVelocity: UIKit's internal duration-fit solver picks a
  much softer spring (a different root of the same settling equation —
  see docs/QUARTZ_NOTES.md) once the velocity crosses a threshold
  (measured: between v=1.65 and v=1.7 at ζ=0.5, D=1, scaling roughly with
  1/D; near the crossover UIKit emits unconverged garbage parameters,
  e.g. ζ=0.5 D=2 v=0.9 → stiffness 354.6 with settlingDuration < D). We
  always take the settled (largest) root, which matches UIKit for
  moderate velocities (probed: exact for v ∈ [−2, 1.65] at ζ=0.5 D=1)
  and diverges deliberately in the garbage regime. All fixtures use v=0,
  where the model is exact to 8+ digits.
- Transform interpolation implements CA's decomposition for the 2D affine
  subset (translation/scale/shear/rotation lerp, rotation shortest-path).
  Degenerate (rank-deficient) matrices fall back to componentwise lerp;
  180° rotations are ambiguous (CA's quaternion slerp has the same
  ambiguity). backgroundColor nil endpoints lerp as transparent black
  (CA snaps); no fixture covers either.
- A `bounds`/frame resize animates the layer rect only — a view's CONTENT
  image (glyph ink, image resampling, control chrome) is not re-stretched
  per frame the way CA scales `contents` with the presentation bounds.
  No fixture resizes a content-bearing view; revisit if one does.
