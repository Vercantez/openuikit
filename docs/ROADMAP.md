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
- **Reminder UIDatePicker slice (2026-08-30)** — bounded functional support
  for the unchanged app's 320 x 320 inline-date and 160 x 160 wheel-time
  paths. The exact whole-source census is 34 -> 12 diagnostics: 25 old errors
  removed, 3 deeper errors exposed, 9 unchanged, and zero app/vendor edits.
  Public availability/open-inheritance shape, native state transitions,
  deterministic host-clock/calendar policy, hostile-date admission, public
  touch events, bounded hostile picker viewports, and both renderer routes are
  gated. A separate exact ARM64 Mach-O gate compiles all 102 OpenUIKit sources
  with Foundation hidden, reruns the inherited system-image guest, and launches
  a literal-UIKit DatePicker guest twice on Linux with pinned state/touch/render
  output. Its FoundationEssentials-only locale provider exposes a requested
  `en_US_POSIX` as `en_001`; FoundationInternationalization and locale/24-hour fidelity,
  compact overlays, wheel physics, accessibility, and native pixels remain
  roadmap work; this milestone does not claim complete UIDatePicker or an
  unchanged Reminder launch.
- **Reminder presentation/table successor slice (2026-08-30)** — the exact
  unchanged 22-source census advances **12 -> 7 diagnostics**, removing only
  the popover-color, modal-transition, and table-row-move five-error surface
  with zero additions or app/vendor edits. `UIModalTransitionStyle`, the open
  controller property, and open popover accessor/background close measured
  raw/default/round-trip state; style-driven animation and regular-width
  popover chrome remain future work. Direct and pure-single begin/end
  `UITableView.moveRow(at:to:)` preserve visible identity, exact destination
  frames, order, and selection, including nested batches with an intervening
  viewport change. Mixed/multiple/reload batches use a coherent nonidentity
  rebuild and row-animation pixels are not claimed. A committed iOS 26.1
  oracle pins only that state/identity/frame/order/selection boundary; the
  successor Reminder gate pins all 22 sources, 23 call-site lines, complete
  diagnostic multisets, and the exact one-commit changed-path allowlist.
- **Reminder trait/text/framework-selector successor slice (2026-08-30)** —
  the exact unchanged whole-source census advances **7 -> 4 diagnostics**,
  removing only controller handler-form trait registration, native
  null-resettable `UITextView.text` optionality, and the framework-owned
  `UIView.endEditing:` selector boundary, with zero additions and zero
  app/vendor edits. Controller registrations are owner-retained, noninitial,
  no-view-load, filtered, unregisterable, and root-replacement safe under the
  explicit host-driven trait seam. Text nil resets to empty while clearing
  attributed content, clamping the caret, and invalidating text layout; actual
  tap recognition reaches the exact built-in selector with iOS 26.1's measured
  `false` argument. The committed native
  and unchanged-Reminder probes pin this bounded behavior, all 22 sources,
  26 call-site lines, complete multisets, and the exact 21-path candidate.
  At that predecessor boundary, full `UITraitChangeObservable`/`traitOverrides` topology, app-defined Swift
  Objective-C dispatch, `#Preview`, Foundation/OpenUIKit `Notification`
  bridging, and the picker class-parameter Objective-C boundary remain. This
  milestone does not claim an unchanged Reminder build or launch.
- **Reminder responder-root / Objective-C selector successor (2026-08-30)** —
  exact unchanged Reminder advances **4 -> 2 diagnostics**, removing only its
  UIDatePicker `@objc` / `#selector` pair with zero additions and zero
  app/vendor edits. `UIResponder` now inherits NSObject from Foundation on
  ordinary builds and from ObjectiveC on the Foundation-hidden Mach-O guest;
  inherited identity replaces redundant UIView/UIScene conformances. After
  semantic built-ins, `SelectorDispatch` performs responding NSObject methods
  with exact 0/1/2 arity before the portable registry fallback. Literal
  UIDatePicker source, runtime precedence/fallback, weak lifetime,
  `UIVisualEffectView` archive replacement, native ELF NSObject identity, an
  iOS 26.1 oracle, and a twice-run Linux-hosted ARM64 Mach-O guest are gated.
  Native ELF still cannot compile literal Swift `@objc` / `#selector`;
  `UIGestureRecognizer` and `UIEvent` remain non-responder senders; Notification
  and Timer selector delivery remains registry-only. `#Preview` and
  Notification ambiguity are the exact two Reminder diagnostics left for
  independent successor slices, so this is not yet an unchanged app launch.
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
  - UITextField selection core DONE (2026-08-29): UTF-16 document positions
    and ranges, selected/marked text, ranged insertion/replacement and
    composed-character deletion, plus deterministic caret/selection geometry.
    Verified against the unchanged Focus autocomplete override bodies and a
    real-UIKit UTF-16/IME probe. Selection chrome and UITextView migration
    remain out of scope (docs/KNOWN_GAPS.md "Text input").
  - Focus text-traits and responder-editing slice DONE (2026-08-29): exact
    keyboard type/appearance, autocapitalization, autocorrection, and return
    enum values/defaults on UITextField/UITextView; coupled placeholders; measured
    clear-button and left/right side-view modes/geometry, including right-view
    precedence independent of assignment order; assistant-item group
    storage/ownership; attached-field `selectAll`; ordered text-change
    notifications; and subtree-aware `UIView.endEditing`. The surprising iOS
    26.1 force/refusal contract is
    oracle-pinned rather than inferred from the SDK header. The host keyboard,
    SF Symbol clear glyph, and assistant-bar presentation remain documented
    boundaries in KNOWN_GAPS.
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

- **M12 App compatibility — DONE 2026-08-25.** The milestone that turned the
  question from "does it match UIKit?" into "can a real app be written against
  it?". Ordered by a measurement, not a guess: `Tools/apicensus/census.py`
  counts every UIKit symbol reference in four large open-source apps
  (eidolon, DuckDuckGo iOS, Kickstarter ios-oss, pocket-casts-ios — 5,099
  Swift files, 16,343 references) and diffs it against what OpenUIKit exports.
  The top four clusters were then built, each with its own oracle probe.
  - **Coverage moved 70.2% → 85.4%** frequency-weighted on the shared
    three-app corpus (38 → 63 of the 171 distinct types those apps touch);
    **88.5% effective** on the four-app corpus once Foundation types that
    exist on Linux and the deliberate storyboard/nib non-goal are excluded.
    Exported UIKit-shaped public types: 63 → 111. Full tables, the re-ranked
    remaining punch list and the method caveats: docs/APP_COMPAT.md.
  - **Gates at the M12 tip: 96/96 scenes (150 frames), 9/9 scroll traces,
    517 tests, Linux 96/96 and 150/150 byte-identical.**

  **Cluster 1 — attributed text** (713 uses closed).
  - **Portable Foundation-shaped types.** `NSAttributedString`,
    `NSMutableAttributedString` (with `attributes(at:effectiveRange:)`,
    `enumerateAttribute(s)`, `addAttribute(s)`, `setAttributes`,
    `removeAttribute`, `append`/`insert`/`replaceCharacters`,
    `attributedSubstring`), `NSAttributedString.Key`, `NSRange`,
    `NSParagraphStyle`/`NSMutableParagraphStyle` and `UIFontDescriptor` —
    declared IN OpenUIKit, no Foundation. They shadow Foundation's names;
    the tradeoff and the one-line disambiguation are in docs/KNOWN_GAPS.md.
  - **Layout + drawing.** `AttributedTextLayout` measures, wraps and draws
    per run: per-run fonts/colors/kern/baseline offsets, mixed-font line
    boxes, paragraph line spacing/indents/height clamps, underline and
    strikethrough. `attributedText` on `UILabel`, `UITextField` and
    `UITextView`; glyph ink goes through the existing harvested-mask
    pipeline unchanged (`UILabel.drawGlyph` was split out of
    `drawGlyphLine` so both paths rasterize identically).
  - **Measured, not guessed.** `Tools/attrprobe/` probes real Catalyst UIKit
    for the kern/pair-kerning/line-box/baseline-offset rules, and
    `oracle textdecor` vendors the underline/strikethrough rects
    (`Resources/text_decorations.json`) — no closed form fit the size sweep.
  - Scene spec v5.2 adds the `attributedText` run form; six new goldens
    (`attrtext_runs`, `attrtext_paragraph`, `attrtext_kern_baseline`,
    `attrtext_underline_strike`, `attrtext_dark`, `attrtext_fields`).
  - Cluster gate on merge: 87/87 scenes, 9/9 scroll traces, 434 tests.

  **Cluster 2 — app lifecycle / environment** (805 uses closed, the largest).
  - `UIResponder` becomes the real base class with UIKit's exact chain;
    first-responder state moved off `UIView` onto `UIResponder`, so a view
    controller can hold focus. `UIApplication` + `UIApplicationDelegate`, a
    minimal `UIScene`/`UIWindowScene` layer, host-driven `UIScreen`, and a
    `UIDevice` whose values are declared rather than measured (there is no
    device, and it may be Linux).
  - `openhost --app` now boots through `UIApplicationMain` and a real app
    delegate. There is **no run loop** in the portable core, so
    `UIApplicationMain` performs the launch sequence and returns; the host
    drives the rest through five `_host…` methods. The order and the
    `applicationState` an app observes are UIKit's — only the trigger differs.
    No `NotificationCenter` either (it is Foundation): the delegate callbacks
    are the only observation point. Both in docs/KNOWN_GAPS.md.

  **Cluster 3 — alerts + the custom-transition API** (514 uses closed).

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
  - Cluster gate on merge: 85/85 scenes, 9/9 scroll traces, 418 tests, Linux
    still byte-identical (139/139 frames).

  **Cluster 4 — image loading, app-side drawing, first controls** (107 uses
  closed; the cheap items the census kept surfacing under other headings).
  - **Image codecs.** `UIImage(named:)` / `(contentsOfFile:)` / `(data:)` with
    PNG+JPEG decode, `@2x`/`@3x` scale suffixes, `pngData()` /
    `jpegData(compressionQuality:)`. The decoder is the `stb_image` copy
    already vendored inside CQuartz, reached through an additive C API that
    hands over STRAIGHT (non-premultiplied) RGBA8
    (`patches/quartz/005-image-io-memory.patch`, per the vendored-quartz
    policy) — OpenUIKit contains no decoding code of its own.
    `UIImage(named:)` resolves against `OpenUIKitRuntime.imageSearchPaths`,
    empty by default: the library hardcodes no host paths.
  - **`UIBezierPath`** — construction/arcs/transforms plus `fill()` /
    `stroke()` / `addClip()` on the current context, backed by
    OpenCoreGraphics `Path`; `Canvas.stroke` gained cap/join/miter.
  - **App-side drawing** — `UIView.draw(_ rect:)` through the existing
    layer-contents path (invalidated by `setNeedsDisplay()`),
    `UIGraphicsImageRenderer`, `UIGraphicsGetCurrentContext()` returning the
    `Canvas`, `UIColor.setFill()/setStroke()`.
  - **Four controls**, oracle-goldened: `UIActivityIndicatorView`,
    `UISlider`, `UISegmentedControl`, `UIPageControl` (`control_activity`,
    `control_slider`, `control_segmented`, `control_pagecontrol`,
    `control_dark`). `UIStepper` was probed and deferred — real UIKit draws
    it through a SwiftUI hosting view, so it only renders in the windowed
    oracle, and regenerating a `"window": true` golden needs an active,
    unlocked display session. Measurements for whoever picks it up are in
    docs/KNOWN_GAPS.md.

  **Integration + the bug the merge exposed.** Merging the four clusters and
  re-measuring turned up a defect that had been mis-diagnosed as
  alert-specific letter tracking: **Apple ships two cuts of San Francisco and
  UIKit picks one by platform** (`.SFNS` on Mac Catalyst, `.SFUI` on iOS).
  Only the six Simulator-routed goldens (the `alert_*` and `modal_sheet*`
  scenes) are set in the iOS cut. Re-taking the whole font-metrics dump on iOS
  (`Tools/oracle2/fontprobe`, vendored as `golden/font_metrics_ios.json`) and
  diffing it against the Catalyst one gives an exact per-size law over all 432
  font entries × 95 glyphs, maximum deviation **0.000000000 pt**:
  `advance_macOS − advance_iOS = T(size) · size / 2048`, with T zero at every
  size ≥ 20 pt and for the monospaced family, and pair kerning identical
  between the cuts. `OpenUIKitRuntime.systemFontCut` selects it; all six scenes
  improved and `alert_dark` went from FAIL to PASS. Nothing else moved. The
  residual, the vertical metrics that are still *not* switched, and the fact
  that outlines still come from `SFNS.ttf` are in docs/KNOWN_GAPS.md.

  Also this milestone: `compare.py` gained a **content-absence check**
  alongside M11's blob gate, after the same class of failure proved able to
  hide missing BODY text (stems ~2 device pixels wide never form a blob large
  enough to trip the size cap). The absence floor is punctuation-scale
  (1.0 pt²). And the ObjC-selector question was **reversed by measurement**:
  the earlier verdict ("ObjC interop is broken off-Darwin at the compiler
  level") turned out to be an artefact of a badly shaped shim — `Selector` was
  declared String-shaped where the compiler expects pointer-shaped, which
  crashed swift-frontend. With a correct ~10-line `ObjectiveC` shim plus a
  ~20-line C stub, `@objc` and `#selector` **compile, link and run on stock
  `swift:6.2-noble`**, with selector names recoverable at runtime
  (`Tools/objcshim/verify.sh`). UIKit's real `addTarget(_:action:for:)` is
  therefore reachable without a compiler fork; nothing was adopted this
  milestone, but the assessment that ruled it out is retracted.

- **M13 Collection view — DONE 2026-08-25.** The census's #1 remaining
  cluster (498 uses across 23 types, all four corpus apps).
  - **The reuse machinery was lifted first.** Per-identifier pools,
    registered factories and `prepareForReuse`-on-dequeue moved out of
    `UITableView` into `Sources/OpenUIKit/UIReuse.swift` (`ReuseRegistry<V>`
    + `VisibleViewMap<Key, V>` for the tiling bookkeeping). `UITableView`
    drives that shared component for its cells and its header/footer/card
    views; `UICollectionView` drives it for cells and, one registry per
    supplementary KIND, for headers and footers. Regression bar: every
    `tableview_*` fixture and every table test unchanged.
  - **`UICollectionViewFlowLayout` is MEASURED, not assumed.**
    `scripts/flow_probe.sh` builds a Mac Catalyst probe that dumps real
    UIKit's item and supplementary frames for 20 configurations; the rules it
    exposed are transcribed at the top of `UICollectionViewFlowLayout.swift`
    and asserted frame-for-frame by `FlowLayoutMeasuredTests`. Two of them
    are not guessable: a line's spacing is the leftover DISTRIBUTED over the
    gaps (the "minimum" is a floor), and a section's LAST line is spaced as
    if phantom items filled it — but only when every item on that line has
    the same size, otherwise it falls back to the minimum. Item origins snap
    to the device pixel grid; sizes do not.
  - **Five oracle fixtures**: `collection_flow_grid`,
    `collection_flow_lines` (wrapping + a delegate-sized second section),
    `collection_sections` (headers/footers, including an EMPTY section),
    `collection_horizontal` (columns + horizontal supplementaries clipped at
    the viewport edge), `collection_dark`. All pass ≥ 98.9 % pixels. Dark
    works through the OFFSCREEN oracle here because the scene resolves every
    colour it draws against the scene traits at build time.
  - **Reuse is real and tested**: a 10 000-item grid swept end to end
    instantiates ~one screenful of cells (`CollectionViewReuseTests`,
    mirroring the table's gate), and `layoutAttributesForElements(in:)`
    binary-searches sections and lines so scrolling stays O(visible).
  - Deliberately NOT built: compositional layout, diffable data source,
    animated batch updates (`performBatchUpdates` is a documented
    reload-and-complete fallback), sticky headers, self-sizing cells,
    decoration views. All in docs/KNOWN_GAPS.md "UICollectionView".

- **M14 Real-app harness — DONE 2026-08-25.** The definition-of-done test for
  the whole app-compat effort (docs/APP_COMPAT.md). Full report:
  **docs/REAL_APP_TEST.md**.
  - **A shipping app's screen renders.** Four UNMODIFIED source files from
    Automattic/pocket-casts-ios (the options-picker sheet: 605 lines,
    `UIScrollView` + `UIStackView` + anchors + a self-sizing sheet) live in
    `Sources/RealAppProbe/Vendored/`. `openrender realapp` renders three
    configurations; `openhost --app pocketcasts` runs it live with the app's
    own touch handling; `scripts/linux_realapp_verify.sh` builds and replays
    the whole thing on Linux, **13/13 frames byte-identical**.
  - **97.7 % of the app source is unmodified** — 14 of 605 lines changed, and
    the 258-line view controller with all the Auto Layout in it compiles
    byte-for-byte. Every one of the 14 is a language/runtime incompatibility
    (`NSCoder`/Foundation 5, `@MainActor` 4, `#selector`/`@objc` 4, an access
    level 1); **none is a missing UIKit member**. *(M15 closed all of those
    rows except `#selector`/`@objc`: the ledger is now **4 lines / 99.3 %**,
    and three of the four vendored files are unmodified end to end.)*
  - **Dynamic Type shipped, oracle-backed.** `UIFont.TextStyle`,
    `UIContentSizeCategory`, `UIFont.preferredFont(forTextStyle:)`,
    `UIFontDescriptor.preferredFontDescriptor(withTextStyle:)` and
    `UIFontMetrics`, driven by `Resources/dynamic_type.json` — the verbatim
    dump of `Tools/oracle2/dyntypeprobe` on real iOS 26 (11 styles x 12
    categories x 19 base values). The census's largest remaining cluster.
  - **Sheet detents shipped, measured.** `UISheetPresentationController
    .detents` with `.large()`/`.medium()`/`.custom(resolver:)` and
    `UIModalPresentationStyle.formSheet`, from `Tools/oracle2/detentprobe`
    (13 cases). `maximumDetentValue` and the over-maximum collapse are exact;
    the iOS-26 floating-card shape is a stated divergence.
  - **UIStackView now composes with Auto Layout** and `UIScrollView` gained
    `contentLayoutGuide`/`frameLayoutGuide` wired into the cassowary solver,
    so constraints against the content guide drive `contentSize` — the recipe
    every modern scrolling screen uses.
  - Also: `UIView` identity `Equatable`/`Hashable`,
    `systemLayoutSizeFitting`, `registerForTraitChanges`, accessibility
    storage, `UIImage.draw(in:)`, and nine classes made `open` so app code can
    subclass them.
  - Gates: 108/108 fixture scenes, 9/9 scroll traces, **732 tests**, 0
    failures.
  - **The verdict is in docs/REAL_APP_TEST.md and it is not "done":**
    rendering a real code-based screen works; compiling a whole app does not,
    and the ranked reasons are ~~Foundation interoperability~~ *(closed in
    M15)*, selector dispatch, ~~`@MainActor`~~ *(closed in M15)*, asset
    catalogs and xibs — none of them about UIKit's API surface.

- **M15 real-app re-measurement — DONE 2026-08-25.** The milestone's own
  yardstick, re-run: every adaptation in the vendored pocket-casts source was
  reverted to pristine upstream text, one reason-class at a time, and
  recompiled.
  - **Ledger: 14 changed lines → 4. 97.7 % → 99.3 % unmodified.** Three of
    the four vendored files are now unmodified app code end to end, including
    the 258-line view controller.
  - **Foundation row (5 lines) closed** — `import Foundation` and
    `required init?(coder: NSCoder)` compile verbatim.
  - **`@MainActor` row (4 lines) closed** — `OptionAction`'s isolated closure
    types and initializers compile verbatim.
  - **Harness row (1 line) closed**, and it needed two different fixes that
    had looked like one. The `public` was harness plumbing: the module
    boundary moved to `RealAppScreen.makeRoot(variant:theme:)` so
    `OptionsPicker` stays `internal` as upstream declares it. The `@MainActor`
    was load-bearing (15 isolation errors without it) — but load-bearing in
    the *app's own build too*, which supplies it via a module-wide default, so
    `RealAppProbe` is now compiled with `-default-isolation MainActor`, the
    setting an Xcode 26 app target carries. Mirroring the app's build
    configuration rather than editing its source.
  - **`#selector`/`@objc` row (4 lines) remains open on native ELF**, with
    diagnostics rather than inference: on Linux `@objc` is the compiler error
    *"Objective-C interoperability is disabled"* and `Selector` is not in
    corelibs-Foundation. The later responder-root slice closes the former two
    macOS failures: `UISwitch` is now an ObjC-representable NSObject descendant
    and responder target metadata dispatches without a registry. A library
    still cannot shim native ELF's compiler diagnostic, so this remains the
    **entire cross-platform harness** ledger.
  - **The informative number has moved.** At 4 changed lines the adaptation
    ratio is saturated; the real remaining cost is the **256 lines of
    scaffolding** the harness writes around the app (theme system, selector
    table, module alias). Next work is scaffolding reduction — a
    `SelectorDispatching` macro and an `.xcassets` reader — not type count.
  - Gates all green and unchanged: 108/108 scenes, 9/9 scroll traces, **765
    tests**, **162/162** byte-identical Linux frames, **13/13** for the
    real-app screen. Renders verified byte-identical against a worktree build
    of the previous commit, so the reverts are behaviour-neutral.

- **M15 `@MainActor` isolation — DONE 2026-08-25.** Punch-list blocker #3
  (`@MainActor`: 641 uses across 270 of the corpus's 5,099 files). Real UIKit
  isolates its UI classes to the main actor and app source is written against
  that; OpenUIKit's classes had no isolation, so that source did not
  type-check.
  - `UIResponder` and every subclass, `UIControl`, `UIGestureRecognizer`,
    `UIScreen`, `UIDevice`, the touch/event types, the presentation and
    transitioning types, the bar-item and bar-appearance types, the Auto
    Layout types and **every delegate / data-source protocol** are now
    `@MainActor`, matching the iOS SDK.
  - Deliberately NOT isolated: all of `OpenCoreGraphics`, the glyph-run
    painter (`nonisolated static`), the Cassowary solver, the font engine,
    and `UIColor`/`UIImage`/`UIFont`/`UIBezierPath`/`UIGraphicsImageRenderer`
    — legal off the main actor in real UIKit too.
  - Exactly two boundary crossings, both `MainActor.assumeIsolated` (checked,
    traps off-main) with the reasoning at the site — timer/notification
    delivery to a `SelectorDispatching` target, and each tool's top-level
    `main.swift`. No `nonisolated(unsafe)` anywhere.
  - **Real-app ledger 14 changed lines → 10, 97.7 % → 98.3 %**: the
    `@MainActor` category is gone from it entirely. *(This is this entry's own
    contribution; combined with the Foundation and harness rows the M15 tip is
    **4 lines / 99.3 %** — see "M15 real-app re-measurement" above.)*
  - **No output change and no perf change**: 108/108 scenes, 9/9 traces, **737**
    tests (5 new in `Tests/OpenUIKitTests/ActorIsolationTests.swift`, written
    the way app source is so a regression fails to COMPILE), 162/162 byte-identical macOS-vs-Linux frames, 13/13 for the
    real-app screen; release render of every scene 1.98 s before / 1.97 s
    after.
  - Swift 6 strict-concurrency diagnostics **1,420 → 1,032**. The package
    still does not build in the Swift 6 language mode, and the reason is
    pre-existing global mutable state (996 of the 1,032 are
    `#MutableGlobalVariable`, concentrated in `UIColor.swift` and the symbol
    /metric tables), not isolation. Detail in docs/KNOWN_GAPS.md "Actor
    isolation".

## M13 — bars & appearance (2026-08-25)

Punch-list cluster #2, **322 corpus uses across all four apps**, closed:
`UIBarButtonItem` (270 — the largest missing type after Foundation and nibs),
`UINavigationItem`, `UIToolbar`, `UIBarAppearance` +
`UINavigationBarAppearance` / `UIToolbarAppearance` / `UITabBarAppearance`,
and `UIBarMetrics`; navigation-title attributes have UIKit's dictionary
source shape. `UIViewController.navigationItem` and
`toolbarItems` now drive the bars, which is how every real code-based app
configures them. 8 new exported types, 5 new fixtures.

The measurement drove three findings that a guess would have missed, all of
them iOS-26-specific:

1. **Bar buttons are capsule glass platters**, one per item — 44 pt tall in a
   navigation bar and **48** in a toolbar (measured separately), top-aligned
   at the bar's own y = 0, side margin 16, width = content + 2 x 16, with a
   12 pt gap that is skipped after a space item.
2. **An untinted bar button renders `label`-colored, not tinted** — probed
   both ways, including with `navigationBar.tintColor` explicitly set. Only an
   item's OWN tint is honored. And of the system items, exactly `.edit` and
   `.save` are text; `.done` is the PROMINENT style (`UIBarButtonItem.Style`
   `.done` was renamed `.prominent` in iOS 26).
3. **The inline bar's zone split was wrong since M7.5.** It was a guessed
   20 pt "status inset" + 44 pt content bar with the title centred at y 42;
   real iOS 26 is 10 + 54 with the centre at **32** — the same split M10 had
   already measured for the large-title bar's inline zone. `barHeight` is
   still 64, so nothing below the bar moved. The guess is gone.

Goldens for this cluster come from **real iOS in the headless Simulator**
(new `"ios": true` scene key, scene spec v5.3) rather than Mac Catalyst,
which is not ground truth for iOS 26's glass bars. Divergences — flat
platters instead of glass, hand-fitted vectors instead of SF Symbols — are in
docs/KNOWN_GAPS.md "Bars & appearance", with an explicit warning that a
fixture must not put bar items over a saturated backdrop.

## App-compat cluster "controls2" (2026-08-25) — the remaining controls, and the compile-blockers that are not types

Two fixtures, and the cluster's own 50 new unit tests, all green.

- **`NotificationCenter`, `Notification`, `Notification.Name`,
  `OperationQueue`** — portable, declared in OpenUIKit because the library
  imports no Foundation, and SHADOWING Foundation's exactly like
  `NSAttributedString`. Both registration forms (closure and selector, the
  latter through M12's portable dispatch), object filtering by identity,
  re-entrant-safe delivery. The five **app-lifecycle transitions now POST**
  their UIKit notifications with `UIApplication.shared` as the object; the
  keyboard / device names are declared and nothing posts them.
- **`Timer` + `RunLoop`** on the HOST CLOCK — `UIWindow.tick(timestamp:)` is
  the run-loop turn, so a scripted capture stays reproducible and a static
  scene's timers never fire. Closure and selector forms, late-repeat
  skipping, `fire()`, `invalidate()`.
- **`UILayoutGuide` in the cassowary solver** plus the whole safe-area model:
  `safeAreaInsets` with its measured PER-EDGE CLAMPED propagation (nine probe
  frames, exact), `safeAreaLayoutGuide` / `layoutMarginsGuide` /
  `readableContentGuide`, `layoutMargins` = base + safe area,
  `preservesSuperviewLayoutMargins`, `additionalSafeAreaInsets`,
  `safeAreaInsetsDidChange`. Fixture `constraints_safearea` matches the
  golden at **100.0 %**. This closes docs/APP_COMPAT.md's own named example
  of a missing member on a type we export.
- **`UIRefreshControl`** with scroll-view pull-to-refresh. Fixture
  `control_refresh` (99.4 %) pins the measured spinner: eight 3.5 x 10 pt
  blades on a 10 pt ring with the measured 0.25 pt seed offset, at
  216/255 label alpha. The chase animation and the pull threshold are NOT
  measurable offscreen and are documented as such.
- **`UISearchBar`**, **`UIStepper`**, **`UIPickerView`** — implemented from
  measured geometry, with NO fixture in each case for a reason that is a
  property of the oracle: a private material that renders as nothing, a
  SwiftUI hosting view that renders nothing at all, and a `CAGradientLayer`
  that turns the capture into a translucent wash. Each is covered instead by
  unit tests that replay real UIKit's own numbers — most notably
  `PickerWheelTests`, which reproduces UIKit's private picker-cell frames to
  1e-6 pt over thirteen configurations from a cylinder law fitted this pass
  (`tableHeight = H + 75`, `N = ceil(2·tableHeight/rowHeight)`,
  `R = 0.334225372·tableHeight`).
- `UIDatePicker` was deferred in this historical controls2 milestone. The
  later bounded Reminder slice above now supplies its measured app path.

Every divergence, and the probe route that would close it, is in
docs/KNOWN_GAPS.md ("App-compat cluster controls2").

## M13 integrated (2026-08-25) — all four clusters merged

The four M13 clusters (collection view, bars & appearance, menus & actions +
delegate protocols, controls2) are merged on `master`. Merged gates:
`swift build` clean, **108/108 scenes** (96 → 108), **9/9 scroll traces**,
**711 tests** (544 → 711), 0 failures. `Sources/OpenUIKit` declares **170**
public `UI`/`NS`/`CA` type names, up from 111.

Coverage re-measured at the merge: **90.7%** frequency-weighted, **96.3%**
effective (was 83.0 / 88.5). 42 types and 1,257 corpus uses moved from
`missing` to `implemented`. The corpus is not vendored here, so only the
`--ours` half of the census was regenerated and the committed per-type counts
were reclassified against it — see the caveat in docs/APP_COMPAT.md.

Two shared-file merges are worth recording because they were resolved by
KEEPING BOTH intents rather than picking a side:

- **`UISearchBar` was built twice.** controls2 measured the CHROME (44 pt
  bar, 8 pt field inset, the magnifier's stroked ring, medium-17 text at
  x 39.5) and menus built the DELEGATE contract (UIKit's full
  `UISearchBarDelegate` member list plus a `UITextFieldDelegate` bridge, so
  typing and the return key actually reach an app). The merged file keeps
  controls2's geometry and menus' wiring; the cancel button, which controls2
  drew and menus did not have, now routes through menus' `_cancel()`.
- **`compare.py`'s class sets took three additions**: `UICollectionView` and
  `UIToolbar` join `CHROME_CLASSES`, and `UICollectionView` +
  `UIRefreshControl` join `PUBLIC_CLASSES` while `UIToolbar` deliberately
  stays out of it (its real subtree exposes public-class internals). Each
  branch's justification comment is preserved.

## M13 wrap-up (2026-08-25) — re-measured, re-verified, closed

The milestone is closed on `master` at the M14 tip. Nothing new was built in
the wrap-up; what it did was re-measure, re-verify and re-rank, so the next
milestone is chosen on current evidence rather than on M12's.

**Gate, all green at the wrap-up commit:** `swift build` clean, **108/108
fixture scenes**, **9/9 scroll traces**, **732 tests** (2 skipped, 0
failures).

**Portability re-verified, and it is the run that clears the gate:**
`scripts/linux_verify.sh` on stock `swift:6.2-noble`
(`aarch64-unknown-linux-gnu`, Swift 6.2.4, 24.73 s clean build) renders all
162 frames, passes **108/108 scenes** against the real-UIKit goldens, and is
**162/162 byte-identical** to the macOS render — `PORTABILITY VERIFIED`. No
cluster broke portability and nothing had to be fixed to make it pass. The
one M14-specific risk was that Dynamic Type might reach for a host text
system; it does not — it reads the vendored `Resources/dynamic_type.json`,
and 162 byte-identical frames prove no host lookup crept in
(docs/PORTABILITY.md).

**Coverage re-measured at HEAD: 91.5% frequency-weighted, 97.1% effective**
(90.7 / 96.3 at the M13 merge; 83.0 / 88.5 at M12). 116 of the 220 distinct
UIKit types the corpus references are implemented; **474 uses (2.9%) of
genuinely-missing types remain**. `Sources/OpenUIKit` declares **180** public
`UI`/`NS`/`CA` type names, up from 170 at the M13 merge and 63 before M12.
The corpus is still not vendored here, so only the `--ours` half of the
census was regenerated and the committed per-type counts were reclassified
against it — the caveat is stated in full in docs/APP_COMPAT.md.

**The accepted-divergence ledger is now consolidated** at the top of
docs/KNOWN_GAPS.md: nine divergences the project has decided to live with
(visual-effect APIs not yet wired to the backdrop backend, the flat picker rows, the
`UIActivityViewController` stub, no SF Symbols, the four surfaces with no
fixture, the edge-to-edge sheet detent, Dynamic Type between probed bases,
the three Foundation shadows, storage-only accessibility), each with what it
costs and why. None of them is an unmeasured guess, which is the property that
matters.

## Next — where the census points (docs/APP_COMPAT.md)

M13's four clusters closed the whole top five of the M12 punch list except
its tails, and M14 took Dynamic Type. Re-ranked at the wrap-up on the 96
missing types / 474 uses that are left, **apps first then uses**:

1. **Materials / blur** (37 uses, 3 apps) — `UIVisualEffectView` 20,
   `UIBlurEffect` 12. The public object/view-semantics API is now present, but
   this remains the single largest source of PIXEL divergence because every
   platter in the framework is a fitted flat colour. The backdrop-filter
   primitive now exists; the remaining fix is descriptor routing and
   framework integration.
2. **Home-screen shortcuts** (31, 3) — value types plus one `UIApplication`
   property. No pixels, no oracle. The cheapest three-app entry left.
3. **Haptics** (30, 3) — a recording no-op; compile-blocker removal.
4. **TextKit attachments** (17, 3) — `NSTextAttachment` is real work (an
   inline box the text engine must lay out and paint); the rest is TextKit-1
   plumbing we deliberately do not have.
5. **Transition coordinator** (13, 3) — the public handle onto the
   presentation/transitioning API M12 already shipped.

By USES instead, the two-app entries outrank 2–5: drag & drop (62),
pointer/hover (33), `UIPasteboard` (32), table extras (31 — swipe actions +
diffable), system pickers (25), `NSItemProvider` (18). Inside shipped
clusters: compositional layout + diffable data sources, animated batch
updates, and broader `UIDatePicker` fidelity beyond the bounded Reminder slice
(locale/calendar presentation, overlays, wheel motion, and accessibility).

**But the type census has nearly run out of things to say, and the wrap-up's
own re-measurement says where to go instead.** Two findings outrank every
cluster above:

- **`UIView.setAnimationsEnabled` + `performWithoutAnimation` is 100 corpus
  uses** — larger than any missing *type* cluster on the list, and one global
  flag plus one wrapper of work. The missing-MEMBER pool was re-checked
  member by member at this commit (docs/APP_COMPAT.md) and this is what came
  out on top.
- **The real blocker is not UIKit's API surface at all.** M14 proved a
  shipping app's screen renders with **99.3%** of its source unmodified
  (97.7% before M15) and **none of the changed lines a missing UIKit member**
  — every one was a language or runtime incompatibility. After M15 the ranked
  reasons a whole app still does not compile are native-ELF selector syntax
  (the remaining language wall; Objective-C-capable responder dispatch now
  works), asset catalogs, localization and xibs;
  ~~Foundation interoperability~~ and ~~`@MainActor`~~ are both closed
  (docs/REAL_APP_TEST.md, docs/APP_COMPAT.md "M15 punch list").

So the milestone this points at is **`import Foundation` alongside
OpenUIKit** — which would let an app's model layer, theme system and string
tables compile untouched — not more UIKit types.

## Verification principle (unchanged, applies to every milestone)

Every feature ships with fixture scenes rendered by BOTH real UIKit (oracle)
and OpenUIKit, pixel- and layout-diffed in CI (`scripts/` + compare.py).
Animations/interaction verify against time-sampled oracle captures.
