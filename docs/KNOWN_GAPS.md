# Known gaps (living document — fixers: read this)

## Pointer-interaction descriptors (Focus AppShortcuts, 2026-08-28)

OpenUIKit now exposes the Swift-overlay pointer family needed by Focus:
`UIPointerInteraction`, its delegate and regions, value-shaped
`UIPointerEffect`/`UIPointerShape`, and `UIPointerStyle`. Interactions retain
UIKit's one-view lifecycle, weak delegate, enabled state, and measured
defaults. `UIButton.isPointerInteractionEnabled` is also a real stored toggle,
defaulting to `false` like UIKit.

This is source and state compatibility, not a claim that Linux has UIKit's
cursor compositor:

- The host does not ingest mouse-hover movement into pointer-region requests,
  so it does not automatically ask delegates for styles or send enter/exit
  animation callbacks.
- The focused delegate surface currently includes the optional-equivalent
  `styleFor` callback. `UIPointerRegionRequest`, region selection, and the
  enter/exit animator protocols remain unmodeled.
- Effects, shapes, and styles preserve their inputs but do not morph, tint,
  scale, shadow, hide, or otherwise redraw the host cursor.
- The iOS Swift overlay advertises `UIPointerEffect` as `Sendable` and
  `Equatable`, but its preview is main-actor UI state and the live equality
  operator is non-reflexive. OpenUIKit keeps effects and shapes main-actor
  isolated and deliberately does not claim those misleading conformances.
- `invalidate()` is intentionally a no-op until a host pointer event/style
  bridge exists.
- Enabling a button's pointer interaction records the application-visible
  UIKit state; it does not synthesize a hidden interaction or hover renderer.

## `UIApplicationDelegate.window` optional-requirement bridge (Focus UIHelpers, 2026-08-28)

Objective-C UIKit declares `window` as an optional protocol requirement. A
read through an application-delegate existential therefore has two optional
layers: whether the delegate implements the requirement and whether the
implemented property contains a window. OpenUIKit's Foundation- and
Objective-C-interoperability-free Swift core cannot declare such a
requirement, so it exposes `UIWindow??` through the protocol and uses the Swift
standard library's `Mirror` to recover the usual app declaration,
`var window: UIWindow?`, from stored instance data.
Concrete reads and writes still use the app's own property; existential reads
work for ordinary stored properties, including storage inherited from a
superclass.

This is a focused source/runtime bridge, not a general replacement for
Objective-C optional dispatch:

- Assigning `window` through an `any UIApplicationDelegate` value calls an
  inert compatibility setter; it cannot mutate the app's differently typed
  `UIWindow?` storage.
- Computed, lazy, and property-wrapped `window` declarations are not exposed
  as a stored child named `window`, so the reflective existential getter does
  not discover them.
- The getter depends on Swift reflection field metadata. A host built with
  reflection metadata disabled will observe the outer optional as nil.

## Explicit CALayer subset (Focus UIHelpers and progress bar, 2026-08-29)

OpenUIKit supports process-local explicit `CALayer` trees, ordered
`addSublayer`/`insertSublayer`/`removeFromSuperlayer`, axial
`CAGradientLayer`, and `render(in:)`. Layers also have UIKit-shaped weak
delegates and a synchronous dirty-layout path: geometry/tree mutations call
`setNeedsLayout()`, `layoutIfNeeded()` walks the dirty explicit-layer subtree,
and a view's backing layer dispatches `layoutSublayers(of:)` to the view before
`layoutSubviews()`. This is deliberately not yet a unified mirror of UIKit's
private backing-layer tree:

- Focus's progress-bar slice adds `CATransaction`, copied/keyed
  `CABasicAnimation`, layer masks, `drawsAsynchronously`, and host-clock
  presentation sampling for `bounds`, `bounds.size`, `position`, `opacity`,
  `cornerRadius`, and gradient `locations`, including supported animations
  installed directly on a `UIView` backing layer. Explicit `fromValue`/`toValue`,
  removal/forwards fill, infinite repetition, replacement/removal, implicit
  frame animation inside an explicit transaction, and transaction completion
  are behavioral and tested. Completion follows the live keyed animation, so
  removal, shorter replacement, and infinite repetition change when it becomes
  due. The model layer changes immediately; completion runs only when the host
  advances `UIWindow.tick(timestamp:)`, using the same deterministic clock as
  `UIView.animate`.
- `UIProgressView.setProgress(_:animated:)` now updates the model immediately
  and samples a reversible 0.25-second fill presentation from that clock. It
  supplies the exact superclass call used by Focus's `GradientProgressBar`;
  it does not reproduce UIKit's private progress image-view layer hierarchy.
- This is not general Core Animation. There is no automatic run-loop
  transaction, `presentation()` facade, timing-function surface, delegate,
  animation group/keyframe/spring class, additive/cumulative/autoreverse
  behavior, or `byValue` lowering. Unsupported animation classes, key paths,
  and `byValue` fail loudly at `CALayer.add`; the implemented basic
  interpolation is linear. Extend the value/key-path table alongside an exact
  app consumer and behavior oracle rather than accepting an inert animation.

- `view.layer.sublayers` exposes app-installed layers only; it does not also
  expose the backing layers of `view.subviews`. Rendering places those
  explicit layers above the view's own contents and below its UIView children,
  which matches Focus's `insertSublayer(gradient, at: 0)` use. An app that
  appends a layer expecting it to appear above an already-added UIView child
  will still see it below that child.
- Layout is synchronous and caller-driven. There is no `CALayoutManager`,
  display transaction, run-loop commit, or window-server scheduling; an app
  that expects Core Animation to perform a later implicit pass must call the
  view/layer `layoutIfNeeded()` path (the OpenUIKit host does this for views).
- Explicit-layer shadows are implemented by the quartz/layers compositor but
  not by the pure-Swift render pass. CQuartz renders arbitrary mask layer trees;
  the pure-Swift fallback implements the Focus-used solid rounded-rectangle
  alpha mask only. Backgrounds, calibrated axial gradients, opacity groups,
  clipping, borders, descendant geometry, and array order work in both paths;
  Focus's gradient/order/removal and animated-mask cases have pixel tests in
  both.
- `UIGraphicsBeginImageContextWithOptions` uses OpenUIKit's process-global
  current-context stack. Nested restoration and `scale == 0` screen-scale
  selection match UIKit, but the stack is not thread-local yet.

## Orientation and status-bar policy (Focus Onboarding, 2026-08-28)

`UIInterfaceOrientationMask`, `UIStatusBarStyle`, and the corresponding
`UIViewController` override points preserve UIKit's exact raw values and
controller defaults. They are policy surfaces only: no portable system rotates
a window from `supportedInterfaceOrientations`/`shouldAutorotate`, and no host
status bar is rendered or recolored from `preferredStatusBarStyle`.

## Actor isolation (M15, 2026-08-25): what is `@MainActor` and what is not

Real UIKit marks its UI classes `@MainActor`, and app source is written
against that: `@MainActor func`, `@MainActor` closure types, `nonisolated`
overrides. OpenUIKit's classes carried no isolation at all, so that source
did not type-check (docs/APP_COMPAT.md punch list #3 — 641 uses across 270
corpus files). It does now.

**Isolated, matching the iOS SDK:** `UIResponder` and every subclass (all of
`UIView`'s subclasses, all of `UIViewController`'s, `UIApplication`,
`UIWindow`, `UIScene`/`UIWindowScene`), `UIControl`, `UIGestureRecognizer`,
`UIScreen`, `UIDevice`, `UITouch`/`UIEvent`/`UIPress`/`UIPressesEvent`,
`UIPresentationController` and the transitioning protocols, `UIMenuElement`
and friends, `UIAlertAction`, `UIBarButtonItem`/`UITabBarItem`/
`UINavigationItem`/`UIBarAppearance`, `NSLayoutConstraint`/`NSLayoutAnchor`/
`UILayoutGuide`, and **every delegate / data-source protocol** (real UIKit
annotates those too — and it is forced anyway: a `@MainActor` witness cannot
satisfy a nonisolated protocol requirement).

**Deliberately NOT isolated** — these are legal off the main actor in real
UIKit as well, and isolating them would be both wrong and a constraint on
future threading of the renderer:

| kept nonisolated | why |
|---|---|
| all of `OpenCoreGraphics` (`Canvas`, `Bitmap`, rasterizer, PNG) | the rendering core; nothing in it touches UI state |
| `UILabel.drawGlyphLine` / `drawGlyph` | the shared glyph-run painter, spelled `nonisolated static` explicitly so text rasterization stays off-main-legal even though it lives on a `@MainActor` class |
| the Cassowary solver (`Solver`, `Row`, `Constraint`, `Variable`) | pure math |
| `FontVariations`, `GlyphFont`, `UIFontMetrics` | font/text engine |
| `UIColor`, `UIImage`, `UIFont`, `UIBezierPath`, `UIGraphicsImageRenderer` | value-ish; the SDK does not isolate them either |
| `NSAttributedString`, `NSParagraphStyle`, `Timer`, `RunLoop`, `NotificationCenter`, `OperationQueue` | Foundation shapes; real Foundation does not isolate them |

Runtime cost is zero: without `-enable-actor-data-race-checks` an
`@MainActor` annotation on a synchronous method compiles to the same code.
Measured, release, every fixture scene: **1.98 s before, 1.97 s after** (3
runs each). Renders are byte-identical — 108/108 scenes, 9/9 traces, 737
tests (5 new, `Tests/OpenUIKitTests/ActorIsolationTests.swift`, which fail to
**compile** if the isolation regresses), and `scripts/linux_verify.sh` still 162/162 byte-identical frames.

### `@preconcurrency`: the half of the SDK's annotation M15 left off (2026-08-28)

M15 put `@MainActor` exactly where the SDK puts it and stopped there. The SDK
writes something stronger, and the difference is not cosmetic: UIKit's classes
are marked `NS_SWIFT_UI_ACTOR` in **Objective-C headers**, and every Swift
declaration imported from Objective-C is implicitly `@preconcurrency`. So the
SDK's contract is `@preconcurrency @MainActor`, and OpenUIKit's was
`@MainActor` alone.

What that costs, measured rather than reasoned:

| | SnapKit 250529be vs … | errors |
|---|---|---|
| the real iOS 26.1 SDK, same swiftc, same flags | | **0** (and 0 warnings) |
| OpenUIKit at 4f76a8c | | 218 |
| OpenUIKit with the type-level gaps fixed, `@MainActor` alone | | 94 |
| the same tree, `@preconcurrency @MainActor` | | **2** |

92 of those 94 were `main actor-isolated … from a nonisolated context`
errors on code the real SDK accepts **silently**. Nothing about SnapKit is
unusual; it is ordinary Swift-5-language-mode source, and that is the mode
essentially every shipping app and dependency compiles in.

The mechanism, probed directly rather than assumed: in Swift 5 language mode
`@preconcurrency` on a declaration makes an isolation violation by a client
in another module **silent**, and inside the declaring module a **warning**
instead of an error. Enforcement in the Swift 6 language mode is unchanged,
and there is no runtime component at all — the attribute only moves
diagnostics.

So all 174 `@MainActor` declarations in `Sources/OpenUIKit` carry
`@preconcurrency` as of this change. Read it as transcription, not
relaxation: it is the second half of an annotation the oracle always had.

**What it costs us.** Inside OpenUIKit, an isolation mistake now warns where
it used to error. `ActorIsolationTests` still compiles and still fails on a
regression that *removes* isolation — the annotation is still there, and
Swift-6-mode checking still sees it — but it will no longer catch a
nonisolated-context violation written inside the library. Gates on the
change: 108/108 scenes, 9/9 traces, 765 tests, and all 162 rendered PNGs
**byte-identical** to the pre-change tree.

### The three places the isolation boundary is crossed, and why

All three are `MainActor.assumeIsolated`. `assumeIsolated` is a **checked**
assertion — it traps if the assumption is ever violated — where
`nonisolated(unsafe)` only silences the compiler.

1. **`Timer._fire`** and **`NotificationCenter.post`** deliver to a
   `SelectorDispatching` target, which is `@MainActor` because every
   UIKit-shaped conformer is a view or a view controller. The two *carriers*
   stay nonisolated because Foundation's are. OpenUIKit has no threads and no
   run loop of its own, so both paths are only ever reached from the host's
   main thread.
2. **`main.swift` in `openrender`, `openhost` and `objcparity`.** Top-level
   code is not main-actor isolated, so each tool's CLI body is wrapped in a
   single `assumeIsolated` rather than scattering hops through the scene
   builders.
3. **The C ABI — `oukMain` in `Sources/OpenUIKitC/Runtime.swift`.** A
   `@_cdecl` function is nonisolated by construction: the C ABI has nowhere
   to put an executor. So every one of the ~64 entry points the Objective-C
   facade calls (docs/OBJC_FACADE.md) wraps its body in `oukMain`, which is
   `MainActor.assumeIsolated` under one name. Two alternatives were rejected
   for the same reason: `@MainActor @_cdecl` compiles, but a C caller has no
   executor to compare against, so it is *unchecked* — an ObjC app that
   dispatched a UIKit call off the main thread would corrupt state in
   silence; `nonisolated(unsafe)` is the same objection plus a false claim.
   The crossing is a check and a straight call — no `await`, no hop — so an
   ObjC `[super layoutSubviews]` still reaches the Swift implementation
   synchronously, which is what keeps the ObjC render byte-identical to the
   Swift one (`scripts/objc_facade_verify.sh`).

### The one `nonisolated(unsafe)` left in library code

`OUKHooks.table` / `OUKHooks.installed` (`Sources/OpenUIKitC/Runtime.swift`)
— the six `@convention(c)` pointers Swift calls Objective-C through, written
once before the first render and only read afterwards. Making them
`@MainActor` was tried and reverted: `peerOrphaned` is read from `deinit`,
`deinit` is nonisolated by language rule, and isolating the table therefore
puts an `assumeIsolated` trap inside four destructors — the worst place to
add one and the worst place to diagnose one. The only other
`nonisolated(unsafe)` declarations in the tree are the `@convention(c)`
callback spies in `Tests/OpenUIKitCTests/ABITests.swift`, which stand in for
Objective-C functions and so genuinely cannot be isolated.

### Swift 6 strict concurrency: where the package actually stands

Measured at this tip, `swift build -Xswiftc -strict-concurrency=complete`
(each of these is an error in the Swift 6 *language* mode):

| | before M15 | after M15 |
|---|---|---|
| total diagnostics | 1,420 | **1,032** |

The isolation **removed 388 of them**, because a static on a `@MainActor`
class is concurrency-safe by construction. What is left is one problem
wearing three labels — **996 of the 1,032 are `#MutableGlobalVariable`**:
nonisolated mutable/`let`-of-non-Sendable statics. They are concentrated in
`UIColor.swift` (371), `UIBarSymbol.swift` (126), `RenderStats.swift` (91),
`UIAlertController.swift` (77) and `UIKitCore.swift` (75) — palettes, symbol
tables, metric constants and counters that predate this milestone and have
nothing to do with actors. Making `UIColor` `Sendable` and the tables `let`
would take most of it out; that is its own piece of work.

The genuinely NEW diagnostics this milestone introduces are **4 sites**
(24 emissions), all `#SendingRisksDataRace`, and all of them are the
`assumeIsolated` boundaries above: `Timer.swift` sending `target` and `self`,
`NotificationCenter.swift` sending `observer` and `notification` into the
main-actor closure. They are unavoidable while the carriers stay nonisolated
Foundation shapes, and they are safe for the reason stated at each site.

**So: the package does NOT build in the Swift 6 language mode**, and the
reason is pre-existing global mutable state, not isolation. It builds clean —
zero warnings — in the Swift 5 mode the package ships in, on macOS and on
Linux (`swift:6.2-noble`), which was not true mid-milestone: `@MainActor`
surfaced eight `#ConformanceIsolation` warnings on the identity
`Hashable`/`Equatable` conformances of `UIView`/`UITouch`/`UIPress`/`UIScene`
and on `BottomInsetAdjustable`. Those are fixed properly, with `nonisolated`
on the witnesses (they compare `ObjectIdentifier`s and read no isolated
state), not suppressed.

## M13 wrap-up: the accepted-divergence ledger (2026-08-25)

Every section below documents its own cluster's gaps. This one exists because
by M13 there are thirty of them and a reader needs to know, in one place,
**which divergences the project has decided to LIVE WITH** rather than fix —
and what each one costs. Gates at this commit: 108/108 fixture scenes, 9/9
scroll traces, 732 tests, Linux 162/162 byte-identical.

An "accepted" divergence is one where the fix is understood and deliberately
not taken. It is not the same as an unmeasured guess — there are none of
those left in the list, which is the point. The clusters and use counts
referenced below are the wrap-up re-ranking in docs/APP_COMPAT.md.

| divergence | what it costs | why accepted | section |
|---|---|---|---|
| **No `UIVisualEffectView` / `UIBlurEffect`** | every platter in the framework — alert card, sheet grabber, tab-bar platter, bar-button capsules, `UIPageControl` background, button pills — is a flat colour FITTED over a neutral base. Residual < 1.5 counts on a flat backdrop; **wrong in hue over a saturated one** | the fix is a real backdrop-sampling blur in the compositor, not a type declaration — the single largest remaining pixel divergence and the #1 punch-list cluster (37 uses, 3 apps) | "App compatibility (M12)", "Alerts", "Bars & appearance" |
| **`UIPickerView` rows are not perspective-projected** | each row's RECTANGLE is exact (1e-6 pt); its TEXT is drawn flat — exact at the selected row, ~0.5 pt at \|d\|=1, ~4 pt at \|d\|=2 | shearing a glyph run needs a second rasterizer; the text engine draws harvested masks on an axis-aligned baseline | "UIPickerView" |
| **`UIActivityViewController` shares nothing** | presents as the measured action-sheet shape and reports "unavailable"; no share targets exist | there is no system share service to call, on any platform we target | "Menus, actions & delegate protocols" |
| **No SF Symbols** | of the bar system items only `.edit` and `.save` are text (exact); `.done` is the prominent checkmark; every other is a hand-fitted vector of the MEASURED size, and no golden gates those vectors | the symbol font is not redistributable and not portable | "Bars & appearance" |
| **No fixture for the menu platter, `UISearchBar`, `UIStepper`, `UIPickerView`** | four surfaces are locked in by unit tests replaying real UIKit's numbers instead of by pixels | each is a property of the ORACLE, not a shortcut: iOS 26 draws menus in the render server; a private material draws as nothing; a SwiftUI hosting view draws nothing; a `CAGradientLayer` washes the capture out. Each section names the probe route that would close it | "controls2", "Menus" |
| **A non-large sheet detent is edge-to-edge; iOS 26 draws a floating card** | right HEIGHT, wrong SHAPE (iOS insets 8 pt per side and scales 377/393) | the measured numbers do not decompose into inset + height without modelling the transform | "Real-app harness (M14)" |
| **Dynamic Type is exact only at probed base values** | the 19 probed bases are exact table hits at all 12 categories; between them we interpolate linearly where UIKit's curve is piecewise with 1/3-pt quantization — worst observed ~2/3 pt at accessibility sizes | widening `baseValues` in `dyntypeprobe` closes it mechanically; nothing is hand-fitted | "Real-app harness (M14)" |
| ~~**Three types SHADOW Foundation's**~~ **NARROWED at M15** — the geometry types, `IndexPath`, `NSRange` and `TimeInterval` are now Foundation's own; what still shadows is `NSAttributedString`, `Notification`/`NotificationCenter`, `Timer`/`RunLoop` | an app importing both needs a one-line file-scope `typealias` for those three families only; a Foundation attributed string still cannot reach a `UILabel` | each survivor now has a MEASURED reason, not a blanket rule: Linux Foundation traps on UIKit's attribute values, has no portable selector-form observer, and has no scripted clock | "Foundation coexistence (M15)" |
| **Accessibility is storage only** | properties round-trip and nothing consults them | there is no accessibility tree and no assistive technology, hence no oracle | "Real-app harness (M14)" |

Not on this list because they are **open work, not accepted**: compositional
layout / diffable data sources / animated batch updates ("UICollectionView"),
the picker wheel's spin and the refresh control's pull threshold (both
blocked on a Simulator drag), `UIWindow.makeKeyAndVisible()`'s missing
appearance transition (a small fix, first item on the M14 report's list), and
`import Foundation` alongside OpenUIKit (the largest structural obstacle in
the project — docs/REAL_APP_TEST.md).

## M13 integration note (2026-08-25)

All four M13 clusters — collection view, bars & appearance, menus & actions +
delegate protocols, and controls2 — are merged. Merged gates: 108/108 fixture
scenes, 9/9 scroll traces, 711 tests, 0 failures. Each cluster's own section
below is unchanged and still accurate about what it measured; two
cross-cluster facts belong here rather than in any one of them:

- **`UISearchBar` has two owners.** controls2 measured its chrome and menus
  built its delegate contract; the merged file keeps both (see
  docs/ARCHITECTURE.md's note under the module table). The consequence for a
  fixer: the "no chrome at all" claim in the menus section below is now
  **stale** — the bar does draw a measured magnifier, field and cancel
  button. What remains true is that the field's PILL is inferred rather than
  measured (`tertiarySystemFill` at radius 10) and that there is still no
  fixture, so none of it is golden-gated.
- **The gesture-recognizer exclusion rule changed the event pipeline for
  everyone.** The menus cluster added UIKit's default "first recognizer to
  recognize fails the others sharing the touch" behaviour. Every other
  cluster's work sits on top of it: the collection view's selection, the
  refresh control's pull, the bar buttons' taps and all nine scroll traces
  were re-verified against it at the merge, not just on their own branches.

## App-compat cluster "controls2" (2026-08-25): what shipped and what could not

Scope: the remaining controls plus the compile-blockers that are not types —
`UIRefreshControl`, `UISearchBar`, `UIStepper`, `UIPickerView`,
`NotificationCenter`, `Timer`, and `UILayoutGuide` / `safeAreaInsets` /
`safeAreaLayoutGuide`. Two new fixtures:
`constraints_safearea` (100.0 %) and `control_refresh` (99.4 %).

### The three types that SHADOW Foundation, and why they had to

`NotificationCenter` / `Notification` / `Notification.Name` / `OperationQueue`
and `Timer` / `RunLoop` are declared **in OpenUIKit**, for exactly the reason
`NSAttributedString` already is: the library imports no Foundation at all
(docs/PORTABILITY.md), and a UIKit that cannot post
`UIApplication.didBecomeActiveNotification` is not much of a UIKit — the
census counted ~90 uses of the notification-name group, the largest missing
member group after app-local noise. Consequences a caller must know:

- An app or test importing BOTH sees `'Notification' is ambiguous for type
  lookup in this context`. The fix is a file-scope
  `private typealias Notification = OpenUIKit.Notification`, the same pattern
  the repo already uses for `CGRect` and `NSAttributedString`.
  `Tests/OpenUIKitTests/NotificationTimerTests.swift` is the worked example.
- There is **no bridging** in either direction. An observer registered on
  OpenUIKit's `NotificationCenter.default` never hears Foundation's, and a
  Foundation `Timer` never fires on the host clock.
- `addObserver(forName:object:queue:using:)` returns a `NotificationToken`,
  not `any NSObjectProtocol`: portable Swift has no `NSObject`, and *naming*
  a class `NSObjectProtocol` would collide with the real protocol on Darwin.
  Porting means changing the declared type of the stored observer and nothing
  else.
- **`queue:` is accepted and IGNORED.** There is no run loop and no threads;
  every notification is delivered inline on the poster's stack.
  `OperationQueue` exists only so `.main` compiles.
- **`Timer` runs on the HOST CLOCK**, the timestamp passed to
  `UIWindow.tick(timestamp:)` — the same clock that drives scroll
  deceleration, transitions and animation completions. `openhost` ticks every
  frame so timers behave normally; `openrender` ticks only a scene's scripted
  capture times, and a STATIC scene never ticks, so no golden can be
  perturbed by a timer. `fireDate` is a `TimeInterval`, not a `Date`
  (`Date` is Foundation and there is no wall clock to anchor it to), and
  `tolerance` and the run-loop `mode` are stored and ignored.
- Only the app-lifecycle notifications are POSTED (all five transitions, with
  `UIApplication.shared` as the object, after the delegate method returns).
  The keyboard names, `UIDevice.orientationDidChangeNotification`,
  `didReceiveMemoryWarning` and `significantTimeChange` are DECLARED so app
  code compiles and NOTHING posts them — there is no system keyboard, no
  device to interrogate and no memory-pressure signal in the portable core.

### Safe area / layout guides: measured, and where the model stops

The propagation rule, the guide rects, the margins arithmetic and the
readable-width thresholds are all fitted to a Catalyst probe and reproduced
to the digit; the derivation lives in
`Sources/OpenUIKit/AutoLayout/UILayoutGuide.swift` and every number is
replayed by `Tests/OpenUIKitTests/SafeAreaGuideTests.swift`. Not modelled:

- **Transforms.** Propagation reads `frame`, so a transformed child's safe
  area comes from its transformed frame rather than from UIKit's
  untransformed layout rect. No fixture transforms a safe-area child.
- **RTL.** `leading`/`trailing` alias `left`/`right`, as everywhere else in
  Auto Layout (M9).
- **Convergence is TWO iterations.** Safe area is both a layout input (it is
  derived from frames) and a layout output (guides move views), so
  `layoutIfNeeded` propagates, solves, propagates again and re-solves only if
  something moved. A hierarchy that needed a third pass would settle one
  frame late; none that a fixture or an app builds does.
- **A system guide always reports a frame**, even when no constraint mentions
  it. Real UIKit leaves `layoutFrame` at `.zero` until the guide takes part
  in a solve. The value we report is the one UIKit converges to; only the
  "never asked" case differs.
- **`readableContentGuide`'s 920 pt cap is the DEFAULT BODY FONT's.** There is
  no Dynamic Type (still a gap), so it is a constant.
- **OpenUIKit's own chrome does not set `additionalSafeAreaInsets` yet.** The
  nav bar and the tab bar still expect a screen to be told its bottom inset
  explicitly (`BottomInsetAdjustable` in DemoApp) — see the M10 note below.
  The mechanism now exists; wiring it is a chrome-module change.
- `UILayoutSupport` / `topLayoutGuide` / `bottomLayoutGuide` (the pre-iOS-11
  spelling) are not declared.

### UIRefreshControl: goldened visual, UNMEASURED interaction

Everything the fixture pins — the 60 pt height, the offset-tracking frame,
the eight 3.5 x 10 pt blades on a 10 pt ring with the measured 0.25 pt seed
offset, the 216/255 label alpha — is measured. What is not:

- **The blade-chase animation.** Real UIKit animates the replicator's
  `instanceAlphaOffset`; Core Animation discards animations on a layer with
  no render context, so the offscreen oracle only ever sees the REST pose
  (eight blades at one uniform alpha), which is what the golden pins and what
  we draw. **OpenUIKit's refresh spinner therefore does not spin.** Note this
  is NOT the same situation as `UIActivityIndicatorView`, whose fade ladder
  lives in the layers themselves and IS reproduced.
- **The pull threshold and the refreshing inset.** Driving `contentOffset` to
  −200 pt through the property never fires `.valueChanged` offscreen (UIKit
  arms the trigger from the pan's end, which an offscreen scroll view never
  receives). "Trigger at a pull past the control's 60 pt height, then hold
  `contentInset.top += 60`" is UIKit's DOCUMENTED behaviour, not a
  measurement. Pinning it needs a synthetic drag in the Simulator — the route
  `Tools/oracle2/scrollprobe.swift` already established for scroll physics.
- `attributedTitle` is stored and never drawn.

### UISearchBar and UIStepper: NO FIXTURE, and the reason is the oracle

- **`UISearchBar`'s field pill does not composite.**
  `searchTextField.backgroundColor` is nil, its layer's `backgroundColor` is
  nil and `cornerRadius` is 0; the visible rounded fill is a private material
  that `layer.render(in:)` draws as NOTHING — the capture is transparent
  everywhere except the magnifier and the placeholder ink. So `fieldFill`
  (`tertiarySystemFill`) and the 10 pt corner radius are INFERRED, not
  measured. Everything else IS measured and unit-tested: `sizeThatFits` =
  (width, 44) at six heights, the field at (8, (H − 44)/2, W − 16, 36) over
  six heights and three widths, the magnifier's 2 pt ring of outer radius 6.5
  read off the golden ink at 2x, the placeholder in **system MEDIUM 17** (not
  regular) at black/white alpha 0.25, and the 39.5 / 14 pt text insets.
  The CANCEL BUTTON never appears offscreen at all (UIKit builds it lazily in
  a real window), so its metrics are UIKit's documented shape, unmeasured.
  Scope bars, bookmark/results buttons, `barTintColor` and the
  search-results-controller integration are not implemented.
- **`UIStepper` renders NOTHING offscreen** — 0 of 12032 non-transparent
  pixels — because real UIKit draws it through
  `UICoreHostingView<DesignLibraryStepper>`. It is implemented from the
  windowed probe the previous cluster recorded here (94 x 32 capsule,
  quaternarySystemFill-like background, 13 pt bars in (37, 37, 37), a 1 pt
  centre divider at ~180) plus the property defaults read this pass. The bars'
  THICKNESS, the capsule's corner radius and the pressed/disabled appearances
  are NOT measured. `autorepeat` is accepted and ignored.
- Both are blocked on the same operational wall as before: regenerating a
  `"window": true` golden needs an ACTIVE, unlocked display session, and
  `Tools/oracle2` fails with "window never became renderable" without one.
  That is still true in this environment.

### UIPickerView: the wheel is EXACT, the glyph projection is not attempted

The cylinder law — `tableHeight = H + 75`,
`N = ceil(2·tableHeight/rowHeight)` rows per revolution (an exact integer in
all thirteen probed configurations), `R = 0.334225372·tableHeight`,
`centerY = H/2 + R·sin(d·2π/N)`, `height = rowHeight·cos(d·2π/N)` — fits real
UIKit's own private cell frames to 1e-6 pt on the centres and 1e-13 pt on the
heights. Derivation and the full probe table:
`Sources/OpenUIKit/UIPickerView.swift`.

- **Row text is NOT perspective-projected** — the deliberate flat
  approximation. Each row's RECTANGLE is exact; its text is drawn unsquashed
  and centred in that rectangle, because OpenUIKit's text engine draws from
  harvested glyph masks on an axis-aligned baseline and shearing a glyph run
  would mean a second rasterizer. Error vs the golden: exact at the selected
  row, ~0.5 pt at |d| = 1, ~4 pt at |d| = 2, worse beyond.
- **There is no fixture, on purpose.** An offscreen capture of a real picker
  is a translucent wash, not a picture: a `CAGradientLayer` at
  (0, 10, W, H − 20) composites over everything (centre pixel (231,231,231)
  at alpha 204, corners alpha 0) and erases the opaque sibling behind it.
  `PickerWheelTests` replays UIKit's cell table instead, for |d| up to 4 over
  thirteen configurations.
- The SELECTION INDICATOR's corner radius is a PLACEHOLDER: the layer reports
  `cornerRadius = nan` with `cornerCurve = .continuous` and the fill does not
  composite, so there is neither a property nor a pixel to read. Its rect
  (9, (H − rowH − 2)/2, W − 18, rowH + 2) and colour (`quaternarySystemFill`)
  ARE measured.
- The top/bottom fade is not drawn, so the wheel has hard edges.
- MULTI-COMPONENT X POSITIONS are inferred, not measured: offscreen UIKit
  centres every component's table at the same x, so there is nothing to
  measure. The component WIDTHS are measured
  (`floor((W − 18 − 5(n−1))/n)`, checked for n = 1…5).
- **The wheel does not spin.** `selectRow(_:inComponent:animated:)` jumps;
  there is no pan, no deceleration and no snap. Same Simulator-drag blocker
  as the refresh control's threshold.
- `UIDatePicker` was DEFERRED and nothing was built. It is a formatter and a
  calendar on top of this wheel, and both are Foundation; the wheel it would
  sit on is now measured and available.

## App compatibility (M12, 2026-08-25): what a real app still cannot do

Effective coverage was **88.5%** of what four real open-source apps reference
when this section was written (**97.1%** at the M13 wrap-up —
docs/APP_COMPAT.md). The honest headline is the other one, and it has NOT
changed: **no corpus app compiles end to end yet**, and the reasons are
structural rather than long-tail. M14 sharpened it — a real app's *screen*
renders with **99.3%** of its source unmodified (97.7% as first measured; M15
removed 10 of the 14 changed lines across three passes — Foundation
coexistence 5, actor isolation 4, harness access level 1), and none of the
changes it needed was a missing UIKit member. **All 4 survivors are
`#selector`/`@objc`**, which is a Swift-compiler restriction off Darwin rather
than an OpenUIKit gap (docs/REAL_APP_TEST.md).

- **Delegate protocols that do not exist stop compilation before behaviour
  does.** *(M13: CLOSED — see "UICollectionView" and "Menus, actions &
  delegate protocols" below. `UITextFieldDelegate`, `UITextViewDelegate`,
  `UIGestureRecognizerDelegate`, `UITabBarControllerDelegate`,
  `UISearchBarDelegate` and the three presentation-controller delegates now
  exist with UIKit's member names and defaulted implementations; the
  `UICollectionView` trio — data source, delegate, delegate-flow-layout —
  landed with the collection-view cluster.)* A `class Foo: UIView,
  UITextFieldDelegate` used to fail on the conformance name; that class of
  failure is gone.
- **No `UIBarButtonItem`, therefore no real `UINavigationItem`.** 270 uses,
  every app. The nav bar shows `vc.title` plus a back button and nothing else;
  there is no way to put a button in a bar.
- ~~**No `UICollectionView`**~~ **SHIPPED (M13)** — see the collection-view
  section below for what landed and what is still missing inside it. The
  reuse machinery was lifted out of `UITableView` into `Sources/OpenUIKit/
  UIReuse.swift` (`ReuseRegistry` + `VisibleViewMap`) and both containers now
  drive that one implementation.
- ~~**No notifications, anywhere.**~~ **FIXED (controls2, see the top of this
  file):** OpenUIKit declares a portable `NotificationCenter` and POSTS the
  five app-lifecycle notifications. The keyboard and device names are
  declared but nothing posts them.
- **Safe area: now REAL** (controls2). `UIView.safeAreaInsets`,
  `safeAreaLayoutGuide`, `layoutMarginsGuide`, `readableContentGuide`,
  `UILayoutGuide` in the solver and
  `UIViewController.additionalSafeAreaInsets` all exist and are measured.
  What is still missing is that OpenUIKit's OWN nav/tab chrome does not use
  `additionalSafeAreaInsets` yet.
- **No `UIVisualEffectView`, so nothing in the framework blurs** — see the
  alerts section below for the fitted flat model and exactly where it is
  wrong. This is now a cross-cutting divergence, not an alert detail: it
  covers the alert card and pills, the sheet grabber, the tab-bar platter,
  the `UIPageControl` background, the M13 **menu platter** and every M13
  **bar-button platter** in a navigation bar or toolbar.
- **No SF Symbols.** `UIBarButtonItem(barButtonSystemItem:)` draws one for
  most of its cases on iOS 26; OpenUIKit substitutes hand-fitted vectors of
  the measured size. See the bars section below. The menu's check and
  chevron columns are the same substitution.
- **No `Timer` before controls2; now on the host clock.** See the top of this
  file: it fires from `UIWindow.tick(timestamp:)`, never from a wall clock,
  which is what keeps scripted captures reproducible.
- **No Dynamic Type.** `UIFontMetrics` (66 uses), `UIFont.preferredFont` (21)
  and `UITraitPreferredContentSizeCategory` (55) are all missing; text sizes
  are absolute.
- **No `UIAppearance` proxies** (`UINavigationBar.appearance()` etc., ~20
  uses) and no `UIView.setAnimationsEnabled` (92 uses — the single most-used
  missing member on a type we do implement).
- **Selectors: `addTarget(_:action:for:)` still takes a closure.** Not because
  it cannot be otherwise — the M12 measurement retracted the earlier verdict
  and showed `@objc`/`#selector` compile, link and run on stock Linux Swift
  with a ~10-line shim (`Tools/objcshim/verify.sh`). It simply was not
  adopted. `UIApplication.sendAction`'s nil-target chain walk is faithful; the
  spelling is not.

## UICollectionView (M13, 2026-08-25): what shipped and what did not

Shipped: `UICollectionView` (a `UIScrollView` subclass that tiles whatever
its layout describes), `UICollectionViewCell`, `UICollectionReusableView`,
`UICollectionViewLayout` (abstract) + `UICollectionViewFlowLayout`,
`UICollectionViewLayoutAttributes`, the data-source / delegate /
delegate-flow-layout protocols, register + `dequeueReusableCell(
withReuseIdentifier:for:)` + `dequeueReusableSupplementaryView(...)`,
IndexPath `item` spelling, single and multiple selection, `reloadData`, and
five oracle fixtures (`collection_flow_grid`, `_flow_lines`, `_sections`,
`_horizontal`, `_dark`). Flow-layout geometry is measured, not guessed:
`scripts/flow_probe.sh` dumps real UIKit's frames for 20 configurations and
`FlowLayoutMeasuredTests` reproduces every one of them.

What is NOT there:

- **`performBatchUpdates(_:completion:)` does not animate.** It runs the
  block, does a full `reloadData()` and calls `completion(true)`
  synchronously — the end state is right, the transition is a hard cut. So
  do `insertItems`/`deleteItems`/`moveItem`/`reloadItems`/`reloadSections`:
  every one of them is a `reloadData()`. UITableView's animated portable
  spelling (`performUpdates(withDuration:identity:updates:)`, which matches
  rows by identity so a moving row keeps its cell) has no collection
  counterpart yet; that is the obvious next step and the machinery it needs
  is already generic.
- **No `UICollectionViewCompositionalLayout` and no
  `UICollectionViewDiffableDataSource`** — the tail of the census cluster.
  The abstract `UICollectionViewLayout` is the seam they would plug into: a
  compositional layout only has to answer `prepare` /
  `collectionViewContentSize` / `layoutAttributesForElements(in:)`.
- **No `sectionHeadersPinToVisibleBounds`** (UIKit's default is false, so a
  stock flow layout matches). Sticky headers exist for `UITableView.plain`
  only.
- **No self-sizing cells** (`estimatedItemSize` /
  `UICollectionViewFlowLayout.automaticSize`), same scope call as the table's
  row heights: a delegate supplies sizes or the layout's `itemSize` is used.
- **No decoration views**, no drag/drop, no `UICollectionViewController`, no
  focus/hover, no interactive reordering, no prefetching (`isPrefetchingEnabled`
  and `UICollectionViewDataSourcePrefetching` do not exist — tiling is
  synchronous, which is what the reuse test measures).
- **Delegate-method fallbacks are protocol defaults, not `respondsToSelector`.**
  `UICollectionViewDelegateFlowLayout`'s default implementations return the
  layout's own property, which is what UIKit falls back to. The consequence
  is that an app CANNOT distinguish "not implemented" from "implemented and
  returned the layout's value" — harmless here, but the same portability
  limit documented in docs/OBJC_RUNTIME.md.
- **A cell subclass that declares its own `init(frame:)` must spell it
  `required`.** `register(_:forCellWithReuseIdentifier:)` takes a metatype and
  instantiates it, and Swift only allows that through a `required`
  initializer — so `UICollectionReusableView.init(frame:)` is `required` and
  UIKit's usual `override init(frame: CGRect)` becomes
  `required init(frame: CGRect)`. Same shape as
  `UITableViewCell.init(style:reuseIdentifier:)`, and the same kind of
  source-level cost as the selector `ActionTable` (docs/OBJC_RUNTIME.md): a
  subclass that adds no custom initializer needs no change at all.
- **Frame-only collection-view construction is an intentional compatibility
  extension.** UIKit classifies `init(frame:)` as convenience but raises at
  runtime when no layout is supplied. OpenUIKit's `UICollectionView()` and
  `UICollectionView(frame:)` instead install a `UICollectionViewFlowLayout`,
  preserving this project's preexisting source surface. Portable app code
  should use `init(frame:collectionViewLayout:)` for UIKit-identical intent.
- **A cell shows no selection by default**, exactly like UIKit: `isSelected`
  flips and `selectedBackgroundView` (nil unless the app sets it) is
  unhidden. Nothing is drawn otherwise, and there is no fade.
- **`UICollectionView.backgroundView` is pinned to the visible rect** rather
  than the content rect (it tracks `contentOffset` on every tile), which is
  UIKit's behaviour for a background view but is not separately measured.
- The collection view's default `backgroundColor` is `.systemBackground`
  (what the Catalyst probe dumps). Older UIKit used clear/white; an app that
  relied on that sees a different default.

## Menus, actions & delegate protocols (M13, 2026-08-25): scope notes

What shipped: `UIMenuElement`/`UIAction`/`UICommand`/`UIKeyCommand`/`UIMenu`/
`UIDeferredMenuElement`, key-command routing through the M12 responder chain,
`UIContextMenuConfiguration` + `UIContextMenuInteraction` + `UIInteraction`,
a measured menu platter, `UIActivityViewController` (an honest stub), and the
delegate protocols listed above. 439 corpus uses move from `missing` to
`implemented` at the next census run (docs/APP_COMPAT.md).

### The menu platter has NO fixture, and that is a measured conclusion

**iOS 26 draws the menu in the render server.** The probe
(`Tools/oracle2/menuprobe`, `scripts/menu_probe_sim.sh`) presents a real
`UIMenu` from a real `UIButton` in the iPhone-16 simulator; the private view
tree dumps at full geometry (`_UIContextMenuView` (40, 120, 250, 146) and so
on), but `drawHierarchy(afterScreenUpdates: true)` — the capture BOTH Mac
oracles and the SimScene renderer use — returns the platter **blank**
(verified at three settle times; only the iOS 26 "magic morph" placeholder
appears). The platter is visible only in the device FRAMEBUFFER
(`xcrun simctl io screenshot`), which carries SpringBoard's Dynamic Island and
runs at the device's 3× scale, so it is not a golden any scene renderer can be
diffed against.

Consequence: `fixtures/scenes/` gains no `menu_*` scene. The substitute gate is
`Tests/OpenUIKitTests/MenuTests.swift`, where **every expected number is a
measurement** — layout from the view-tree dumps (platter 250 pt wide, rows
42 pt, title inset 28/40/60, section gap 21, header 40.333, subtitle row 58…)
and pixels from the framebuffer (fill 250 over white / 215 over 0.5 grey /
196 / 176; shadow 243 beside, 247 above, 239 below). A regression fails there
exactly as a fixture diff would. If a future iOS renders menus back into the
app process, promote these to a real scene.

### Menu divergences, deliberate

- **No SF Symbols.** The check and chevron columns are reserved at the
  measured widths (centres 20 pt from the leading edge / 31 pt from the
  trailing edge; boxes 13.33×12.33 and 9.33×12.67), but the glyphs are drawn
  as strokes, not `checkmark` / `chevron.right`.
- **No blur.** The platter fill is the usual flat-colour-at-alpha fit
  (light: 0.7108 of 0.976 white, max residual 1.1 counts; dark: 0.7202 of
  0.118, max residual **3.7** counts — the dark blur is the less linear, and
  the fit is NOT bent to make the black-base point exact).
- **Corner radius is fitted, not read.** The layer reports 0 because the shape
  belongs to the glass effect; a circle of R = 32.57 pt fits the framebuffer
  edge profile with 0.37 pt r.m.s. residual (same method as the page sheet).
- **Anchoring is measured at ONE anchor.** A 100×44 button at (40, 120)
  produced a platter at (40, 120), so the platter's top-left goes on the
  source's top-left, clamped into the window. Real UIKit also flips the
  platter above/beside the source when it will not fit; the clamp is a
  stand-in.
- **No present/dismiss animation, no background blur, no preview.** The
  long-press menu appears at the moment UIKit's would (the recognizer is a
  real 0.5 s `UILongPressGestureRecognizer`) but without the morph, and
  `UIContextMenuConfiguration.previewProvider` /
  `contextMenuInteraction(_:previewFor…)` are stored and ignored. The animator
  objects handed to the delegate run their animations and completions
  IMMEDIATELY, so app side effects still happen in order.
- **A submenu REPLACES the platter** instead of sliding in, and
  `.keepsMenuPresented` is not honoured (selection always dismisses).
- **Mixed image/no-image menus are assumed, not probed.** The `state` probe
  proved the CHECK column is reserved for the whole menu (one `.on` item moved
  all three titles to inset 40); the same rule is applied to images, where
  only an all-image menu was measured.

### Key commands

- Routing is UIKit's — chain from the first responder, first match wins,
  action to the vending responder then up the chain — with one documented
  substitution: **with no first responder the walk starts at the window's
  root view controller**, not at the window. UIKit reaches the root
  controller through a private default first responder; starting at the
  window would end the chain at `UIApplication` and no app's global command
  would ever fire.
- **No `UIMenuBuilder`, no discoverability HUD**, and
  `UIKeyCommand.alternates` is accepted and ignored.
- `openhost` maps SDL key presses to `(input, modifierFlags)` and offers them
  to `performKeyCommand` BEFORE text input, which is UIKit's precedence. A
  press no command claims falls through unchanged.

### Gesture-recognizer exclusion (behaviour CHANGE)

Adding `UIGestureRecognizerDelegate` also added UIKit's default exclusion,
which OpenUIKit did not have before: **the first recognizer to recognize now
fails the others sharing the touch**, unless either delegate answers
`shouldRecognizeSimultaneouslyWith` with true. The whole fixture suite, the
nine scroll traces and the (then) 544 tests stayed green across the change.
NOT modelled: failure requirements — `require(toFail:)` does not exist and
`shouldRequireFailureOf` / `shouldBeRequiredToFailBy` are declarations only.

### Other honest limits from this cluster

- **`UISearchBar`'s DELEGATE contract is what this cluster owns** — the full
  `UISearchBarDelegate` member list plus the `UITextFieldDelegate` bridge, so
  text-change, the search button (the return key) and begin/end editing all
  reach the app through the real input pipeline. *(Superseded in part at the
  M13 merge: this cluster shipped the bar as a bare `UITextField` in a
  container with no chrome at all, but controls2 independently MEASURED the
  chrome — bar height, field inset, magnifier, text metrics — and the merged
  file carries both. See "App-compat cluster controls2" at the top of this
  file for what is measured and what is still inferred; there is still no
  fixture, and no scope bar or bookmark/results button in either version.)*
- **`UIActivityViewController` shares nothing.** It presents as the measured
  page sheet and lists the titles of the app's own `applicationActivities` in
  a `UITableView`; no system activity exists, so a sheet with nothing to offer
  says exactly that. `completionWithItemsHandler` fires where UIKit's does.
- **Popovers always adapt.** `UIPopoverPresentationController` stores
  `sourceView`/`sourceRect`/`permittedArrowDirections` and presents as a
  sheet — which is what real UIKit does at iPhone width, but an iPad-sized
  window would get a sheet where UIKit draws an arrow-anchored popover.
- **`UIDeferredMenuElement` resolves SYNCHRONOUS providers only.** UIKit's
  provider may complete later (it shows a spinner meanwhile); there is no run
  loop to come back to, so a late completion contributes nothing.
- **`scrollViewWillEndDragging` retargeting matches the LANDING POINT, not
  the timing.** A delegate that rewrites `targetContentOffset` gets a real
  UIKit deceleration curve whose initial velocity is solved backwards from
  the requested offset (`UIScrollPhysics.velocityToLand`); UIKit instead
  reshapes the curve's duration. Paging lands in the right place, over a
  slightly different interval.
- **Text-field/-view `shouldChange…` ranges are in UNICODE SCALARS**, not
  UTF-16 — the caret model's units. Same numbers for ASCII, different ones
  for emoji and other non-BMP text.
- **`textFieldShouldEndEditing` is asked twice on a focus transfer** (once by
  `canResignFirstResponder`, once inside `resignFirstResponder`). UIKit asks
  once; the predicate is expected to be pure.
- Declared-but-never-called, for source compatibility: the zooming members of
  `UIScrollViewDelegate` (no `zoomScale` exists), `scrollViewShouldScrollToTop`
  (no status-bar tap), `sheetPresentationControllerDidChangeSelectedDetentIdentifier`
  (one detent), and `UITabBarControllerDelegate`'s animation-controller
  members (tab switches are not animated).

## Two cuts of San Francisco (2026-08-25): the fixture suite has two oracles

**RESOLVED** — this section used to read "`alert_dark` fails the absence gate
… OWNER: text", diagnosed as real iOS "tightening alert label advances" and
needing a per-alert tracking model. That diagnosis was wrong. The defect was
neither alert-specific nor tracking: **Apple ships two different builds of
San Francisco and UIKit picks one by platform.**

    Mac Catalyst   UIFont.systemFont -> .SFNS-*   (macOS cut)
    iOS 26.1       UIFont.systemFont -> .SFUI-*   (iOS cut)

Same outlines, same `wght`, same clamped `opsz`, same pair kerning — but the
iOS cut is spaced TIGHTER below 20 pt. Re-taking the whole `oracle
fontmetrics` dump on iOS (`Tools/oracle2/fontprobe`,
`scripts/font_probe_sim.sh`, vendored as `golden/font_metrics_ios.json`) and
diffing it against the Catalyst one (`golden/font_metrics.json`) gives an
exact law over all 432 font entries x 95 printable ASCII glyphs — maximum
deviation **0.000000000 pt**:

    advance_macOS(c, size) - advance_iOS(c, size) = T(size) * size / 2048

| size | 8 | 9 | 10 | 11 | 11.5 | 12 | 13 | 13.5 | 14 | 15 | 16 | 17 | 17.5 | 18 | 19 | >=20 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| T (font units) | 50 | 50 | 50 | 46 | 45 | 44 | 41 | 41 | 40 | 38 | 37 | 37 | 31 | 25 | 12 | **0** |

T does not depend on the glyph or the weight — only on the point size, the
signature of a spacing difference rather than different outlines. It is zero
at every size >= 20 pt (exactly where SF switches from the Text optical face
to Display) and zero for the monospaced family at every size (SF Mono has no
optical-size axis). Italic tracks system. Pair kerning is IDENTICAL: feeding
the Catalyst kerning table the iOS advances reproduces the iOS
`stringWidths` with residual **0** over all 432 x 6 reference strings.

Why it surfaced as one alert scene: `scripts/regen_goldens.sh` routes scenes
with an `"alert"` or a `"modal"` key — and only those — through the iOS
Simulator, because Catalyst bridges `UIAlertController` into an AppKit panel
and a pageSheet into an AppKit sheet window. Those six goldens are set in
`.SFUI`; every other golden is set in `.SFNS`, which is what the vendored
table describes and what the rasterizer's `SFNS.ttf` draws. Laying an
`.SFUI` golden out with `.SFNS` advances accumulates ~0.31 pt per character
at 17 pt, so the 12-glyph alert title "Delete File?" ended 3.7 pt wide and
its "?" left the golden's ink behind — the 2.5 x 2.0 pt hole the absence
gate reported. The absence gate was right; the metrics were wrong.

Fix: `FontEngine.SystemFontCut` (`OpenUIKitRuntime.systemFontCut`, default
`.macOS`) subtracts the measured T(size) when the iOS cut is selected, and
`runScene` selects it for the Simulator-routed scenes. Every one of the six
improved — nothing else moved:

| scene | pixels | worst blob (pt^2) |
|---|---|---|
| `alert_dark` | 98.475 **FAIL** -> 98.569 PASS | 30.8 -> 5.0 |
| `alert_destructive` | 98.602 -> 98.726 | 42.2 -> 3.0 |
| `alert_actionsheet` | 98.105 -> 98.228 | 36.8 -> 5.0 |
| `alert_basic` | 98.917 -> 98.999 | 7.5 -> 11.8 |
| `modal_sheet` | 99.324 -> 99.347 | 33.0 -> 3.0 |
| `modal_sheet_grabber` | 99.314 -> 99.338 | 33.0 -> 3.0 |

Note the third column: `compare.py`'s blob threshold is calibrated against
"worst legitimate component 33.2 pt^2 (`modal_sheet` — one stem of the 22 pt
bold title)". That residual was this bug, not a rasterization limit, and it
is now 3.0. Measured over all 96 passing scenes at the M12 tip, the worst
legitimate component is now **20.0 pt^2** (`stack_alignment`,
`anim_concurrent`) against an 80 pt^2 gate, so the gate could be tightened
considerably; that is `compare.py`'s call, not the text module's, and the
calibration comment is now stale.

### What is still NOT modelled

- **Vertical metrics also differ between the cuts** and the selector does not
  switch them. `golden/font_metrics_ios.json` vs `golden/font_metrics.json`:
  `capHeight`, `xHeight` and `leading` are identical everywhere, but
  `ascender` / `descender` / `lineHeight` differ at EVERY size, e.g. 17 pt
  semibold `lineHeight` 20 (Catalyst, a whole number) vs 20.28711 (iOS,
  unrounded), and 15 pt regular 18 vs 17.90039. iOS then puts a UILabel's
  line box at `ceil(lineHeight)` on the device's 1/3 pt grid — which is
  exactly where `UIAlertMetrics.titleLineHeight` = 20.333 and
  `messageLineHeight` = 18 came from when the alerts cluster measured them
  off the live view tree. The chrome that needs those numbers therefore
  already carries them as measured constants, `labelLineHeight`'s
  Catalyst-fitted bonus bands stay correct for the Catalyst goldens, and no
  scene currently needs the iOS line box in the general path. Modelling it
  properly means an iOS-cut branch of `labelLineHeight` with its own
  oracle-measured band table.
- **Truncation under the iOS cut is untested.** `tightTable` (the trak-based
  ellipsis / tight-tracking model) was generated offline from macOS's
  `SFNS.ttf`; `ellipsisAdvance` and `measureTight` get the cut delta applied
  on top, but no Simulator-routed fixture truncates a label, so the
  combination has no golden behind it.
- **Glyph OUTLINES still come from `SFNS.ttf`** — the rasterizer has no
  `.SFUI` font file to load (iOS's is inside the Simulator runtime). The
  residual left in the alert goldens after this fix is mostly that: our
  17 pt "D" inks about 0.5 pt left of the golden's, and stems land within
  half a point of the iOS ones rather than on them.
- The alert card sits at x = 36.5 while iOS puts it at 36.667 (UIKit rounds
  the card origin onto the 1/3 pt grid); that is 0.167 pt of the remaining
  horizontal residual and belongs to the alerts cluster, not to text.

Re-derive the iOS dump with `scripts/font_probe_sim.sh <outdir>` (needs a
booted iOS 26 simulator); `Tools/oracle2/alerttextprobe` is the narrower
probe that found the split, dumping the alert labels' fonts, attributes and
CoreText glyph positions.

## App lifecycle / environment (M12, 2026-08-25): scope notes

The cluster is `UIResponder` as a real base class + `UIApplication` /
`UIApplicationDelegate` / `UIScreen` / `UIDevice`
(docs/APP_COMPAT.md, 543 uses). Shipped: the exact UIKit responder chain
(`UIResponder.swift`), first-responder state moved off UIView onto
UIResponder (so a view controller can hold focus), touches/presses
defaulting to forwarding up the chain, `UIWindow.rootViewController` /
`makeKeyAndVisible`, and openhost booting `--app` through
`UIApplicationMain` + a real `HostAppDelegate`. What did **not** ship, and
why:

- **No run loop, therefore no self-driving lifecycle.** `UIApplicationMain`
  performs the launch sequence and RETURNS; the host drives the rest with
  five `_host…` methods (`_hostDidBecomeActive`, `_hostWillResignActive`,
  `_hostDidEnterBackground`, `_hostWillEnterForeground`,
  `_hostWillTerminate`). This is not a gap that can be closed without giving
  the portable core a run loop and a wall clock, which the architecture
  forbids. The ORDER and the `applicationState` an app observes are UIKit's;
  only the trigger differs.
- ~~**No notifications.**~~ **FIXED (controls2):** all five transitions post
  their UIKit notification on OpenUIKit's own portable
  `NotificationCenter.default`, with `UIApplication.shared` as the object,
  right after the delegate method returns. The center SHADOWS Foundation's —
  see the controls2 section at the top of this file.
- **`sendAction` takes a closure, not a `Selector`.** Portable Swift has no
  selectors. The nil-target chain walk — the part that actually matters — is
  faithful; the spelling is not.
- **`open(_:)`/`canOpenURL` take a `String`, not a `URL`,** for the same
  Foundation reason, and do nothing unless a host installs
  `UIApplication.urlOpenHandler`.
- **`UIDevice` values are declared, not measured** (`.phone`, "iOS",
  "26.1", "iPhone"). There is no device to interrogate and the library may
  be running on Linux; the header of `UIDevice.swift` says so explicitly.
  `UIScreen`, by contrast, IS driven by the host's real surface.
- **Scenes are minimal.** `UIScene`/`UIWindowScene`/`UISceneSession`/
  `UISceneDelegate`/`UIWindowSceneDelegate` exist so scene-shaped app code
  compiles and receives activation callbacks. There is no session
  persistence, no state restoration, no multi-window management, and
  `connectedScenes` is empty unless an app opts in — which is what keeps a
  window's next responder the application, the pre-scene shape the hosts
  boot.
- **`UIApplication.windows` counts every live window, not every VISIBLE
  one.** There is no window server to ask about visibility.
- **A first responder removed from its window does not auto-resign.** UIKit
  resigns it; here `isFirstResponder` simply goes false while the window
  still holds a weak reference. Pre-existing behavior, carried over
  unchanged by the migration.
- **A DISABLED `UIControl` still swallows touches** instead of forwarding
  them up the chain (UIKit forwards). Pre-existing; the new forwarding
  default made it visible but did not change it.
## Foundation coexistence (M15, 2026-08-25)

**`import Foundation` next to `import OpenUIKit` now works.** The library
imports Foundation and re-exports Foundation's own `CGFloat`, `CGPoint`,
`CGSize`, `CGRect`, `IndexPath`, `NSRange`, `NSRangePointer` and
`TimeInterval` rather than declaring rivals, so there is exactly ONE of each
in any program. Design, the full table, and the measured reason each survivor
survived: docs/PORTABILITY.md "M15: the library imports Foundation, and there
is exactly one `CGRect`", plus `Sources/OpenUIKit/FoundationTypes.swift`.
Evidence it worked: 151 `private typealias` lines deleted from 40 test files,
`Tests/OpenUIKitTests/FoundationCoexistenceTests.swift` green, and Linux still
162/162 byte-identical.

Three families still shadow Foundation's, each for a measured reason rather
than a blanket rule — `NSAttributedString` (below), `Notification` /
`NotificationCenter`, and `Timer` / `RunLoop`. One residual name clash exists
only on Darwin: `CGAffineTransform`, because Foundation re-exports
CoreGraphics' there and OpenUIKit must keep its own to hold the render
byte-identical. On Linux there is nothing to disambiguate.

Two Swift gotchas this uncovered, both worth knowing before touching the
imports:

- A **default argument** or an `@inlinable` body may only use members whose
  defining module *that file* imports — which is why 31 library files carry a
  scoped `import struct CoreGraphics.CGRect`-style block.
- In a file where the name is visible twice, `[CGFloat](repeating:count:)`
  array-of-type sugar stops parsing as a type and the compiler reports
  `cannot call value of non-function type '[CGFloat.Type]'`. Spell it
  `Array<CGFloat>(repeating:count:)`. This bites app code too.

## Attributed text (M12, 2026-08-25): shadows Foundation, and what is not modelled

### The types SHADOW Foundation's — MEASURED, not a matter of taste

`NSAttributedString`, `NSMutableAttributedString`, `NSAttributedString.Key`,
`NSParagraphStyle` and `NSMutableParagraphStyle` are declared **in OpenUIKit**
(`Sources/OpenUIKit/NSAttributedString.swift`, `NSParagraphStyle.swift`).
(`NSRange` is no longer among them — M15 made it Foundation's.)

Through M14 the reason was the no-Foundation rule. M15 removed that rule and
re-tested the assumption, and the types stayed, because of this:

> On Swift 6.2 Linux, `NSMutableAttributedString.addAttribute` **traps** the
> second time a plain Swift value is stored under a key — run coalescing calls
> `isEqual` on the boxed `__SwiftValue`. Every OpenUIKit attribute value
> (`UIFont`, `UIColor`, `CGFloat`, `NSParagraphStyle`) is a plain Swift value.

So corelibs-Foundation's attributed string cannot hold UIKit's attributes on
the target platform at all, and adopting it would trade a compile-time name
clash for a runtime crash. Consequences a caller must know:

- An app (or test) that imports **both** OpenUIKit and Foundation sees two
  types with each of those names and the compiler reports
  `'NSAttributedString' is ambiguous for type lookup in this context`. The fix
  is a file-scope disambiguation, e.g.
  `private typealias NSAttributedString = OpenUIKit.NSAttributedString`.
  `Tests/OpenUIKitTests/AttributedStringTests.swift` is the worked example.
- A Foundation `NSAttributedString` cannot be handed to `UILabel`; it has to
  be rebuilt. There is no conversion helper — adding one would require the
  library to import Foundation.
- Attribute values are `Any`, like Foundation's. Run coalescing compares
  values with `attributeValuesEqual`, which understands `UIFont`, `UIColor`,
  `CGFloat`/`Double`/`Int`/`Bool`/`String` and `NSParagraphStyle`; any other
  value type compares as *unequal*, so adjacent runs carrying it never merge.
  That is conservative (an extra run, never a wrong one), but
  `effectiveRange` can therefore report a shorter range than Foundation would.
- `NSMutableAttributedString.mutableString` is a plain `String` accessor, not
  a live-editing proxy.

### Measured behavior that IS modelled

All of it comes from Catalyst probes (`Tools/attrprobe/run.sh
measure|geometry|decorations`) and is pinned by the `attrtext_*` goldens:
per-character `.kern` including the last character, `.kern == 0` disabling
pair kerning, pair kerning across run boundaries but never across fonts,
the per-run ascent/descent line box (see AttributedTextLayout's header),
`lineSpacing`/`paragraphSpacing`/`lineHeightMultiple`/min/max line heights,
head and tail indents, and the underline/strikethrough rects, which are
vendored measurements (`Resources/text_decorations.json`) because no closed
form fit the size sweep: the rect top is weight-dependent at 34 pt but not at
17 pt, and the thickness steps at sizes CTFontGetUnderlineThickness does not
predict.

### Not modelled

- **Attributed truncation.** A single-line attributed label that overflows is
  clipped, not ellipsised: the plain path's tight-tracking truncation model
  (`TextLayout.truncate`) is per-font and has no multi-run equivalent yet. No
  fixture overflows; an app that truncates attributed text will see a clipped
  last glyph instead of "…".
- **`.backgroundColor` rect.** Drawn as the run's advance width × the line
  box. Probed once (real UIKit's rect was ~1 pt shorter than the line box at
  17 pt) but not fitted, and no fixture exercises it.
- **Underline patterns and `.double`/`.thick`.** Every non-empty style draws
  the same single rule; `patternDot`/`patternDash`/`byWord` are accepted and
  ignored. Real UIKit's `.thick` and `.double` were measured (rows
  73–78 / 73–80 at 17 pt vs 75–78 for `.single`) but are not implemented.
- **`.strokeColor` / `.strokeWidth` / `.link` / attachments.** The keys exist
  so app code compiles; nothing reads them (no stroking, no
  `NSTextAttachment`).
- **`UITextField` / `UITextView` editing drops attributes.** Typing rewrites
  the plain string and clears the attributed storage; real UIKit keeps
  `typingAttributes`, which we do not model.
- **`hyphenationFactor`, `baseWritingDirection`, tab stops** are absent from
  `NSParagraphStyle` (or present and ignored, for `hyphenationFactor`).
- **`lineHeightMultiple` / min / max baselines.** The heights are golden-
  correct, but the extra space is added entirely above the baseline; only
  `lineSpacing` (which does not move the baseline) is pixel-validated by a
  fixture.

### Glyph-ink coverage: 23 misses, NOT harvested (measured decision)

`OPENUIKIT_INK_LOG` over the six `attrtext_*` scenes reports **23** table
misses — glyphs the harvested-mask fast path does not have, which fall
through to the computed GlyphSmoothing rasterizer (system-regular 13/15/20/24/34,
system-semibold 17, system-bold 17, plus one dark 13 pt cell). They were left
unharvested on purpose: every scene passes with margin anyway
(`attrtext_runs` 98.6, `attrtext_paragraph` 99.3, `attrtext_underline_strike`
99.3, `attrtext_kern_baseline` 99.99, `attrtext_dark` 99.9,
`attrtext_fields` 99.1 against a 97 % text / 96 % control threshold, largest
severe blob 17.8 pt² against an 80 pt² gate). Harvesting those cells is the
next fidelity step if a future fixture in these sizes runs tight; the recipe
is the "Glyph ink harvest" section below.
## Bars & appearance (M13, 2026-08-25)

`UIBarButtonItem` (270 uses), `UINavigationItem`, `UIToolbar` and the
`UIBarAppearance` family are measured from real iOS 26.1 (iPhone 16, compact)
through `Tools/oracle2/simscene` — the fixtures `navitem_buttons`,
`navitem_titleview`, `navitem_dark`, `navbar_appearance` and `toolbar_basic`.
Re-probe any of it with

    SIMCTL_CHILD_SIMSCENE_DEBUG=1 scripts/render_sim_scenes.sh <outdir> <scene.json>

which prints the full private view tree (frames, fonts, colors) for every
scene it renders. What is NOT faithful:

- **The platters are glass; ours are flat.** iOS 26 puts every bar button in
  its own capsule that samples, blurs and refracts the backdrop. We draw the
  measured flat equivalent (white in light mode, (25, 25, 25) in dark) plus a
  shadow whose (opacity 0.075, sigma 10, offset (0, 4)) are a least-squares
  fit to the golden's own falloff — `python3 Tools/compare/fit_bar_shadow.py`,
  rms 2.3 counts. Over a flat neutral backdrop that is what the golden shows
  (over white the platter is literally invisible apart from its shadow). Over
  a **saturated** backdrop it is wrong in hue exactly like the alert card:
  probed over #FF0000 the real platter renders pink and the labels lose their
  tint entirely, and probed over a #FFCC00 opaque bar the whole bar reads
  (247, 206, 70) rather than the (255, 204, 0) that was set — the edge effect
  and the glass both recolor it. **A fixture must not put bar items over a
  saturated backdrop**; the shipped ones use white, black and #F2F2F7.
- **The refractive band is a fitted approximation.** Measured on two goldens,
  the top **14.5 pt** of a 44 pt navigation-bar platter shows the backdrop
  unchanged instead of the frosted fill. We reproduce it by washing that band
  back to the bar's own background color, which only works when the bar HAS a
  flat background; over a transparent bar the band stays frosted. A
  standalone `UIToolbar` platter probed over a saturated backdrop shows a
  UNIFORM fill with no band at all, so toolbars do not apply it — the reason
  for that difference is not understood, it is simply what both probes show.
- **No SF Symbols, so most system items are approximations.** Measured:
  exactly `.edit` and `.save` render as TEXT ("Edit" / "Save") on iOS 26 and
  are therefore exact; `.done` is the PROMINENT style (a tint-filled capsule
  with a white checkmark, and `UIBarButtonItem.Style.done` was literally
  renamed `.prominent`); everything else is an SF Symbol. `_BarSymbol` draws
  a hand-fitted vector of the MEASURED bounding box and stroke weight for
  each one — recognizable, correctly sized and correctly colored, but not the
  same outline. **No golden gates them and no fixture uses one**; the
  fixtures use `.edit`/`.save`, custom titles and synthesized template images.
- **Untinted bar buttons render `label`-colored, not tinted.** This surprises
  people, so it is worth restating: it is MEASURED, twice. Setting
  `navigationBar.tintColor = .systemBlue` still produces black glyphs on
  iOS 26; only an item's OWN `tintColor` is honored. Apps that expect blue
  bar buttons will see black — and so will they on real iOS 26.
- **No item cross-fade during push/pop.** The title and back button animate
  (M7.5), the item platters swap instantly.
- **Toolbars do not merge adjacent image items.** A run of image-only items
  in a real toolbar sometimes shares ONE long platter (measured: six symbol
  items did, a mixed text/symbol row did not, and two symbol items in a
  navigation bar did not). The rule was not pinned down; OpenUIKit always
  gives each item its own platter, which is what every measured *navigation
  bar* does. `toolbar_basic` therefore uses title items only.
- **`isTranslucent` is stored and ignored** (no blur to be translucent with),
  and `UIBarAppearance.backgroundEffect` is accepted and ignored.
- **`configureWithDefaultBackground()` == transparent for a static bar.**
  iOS 26's default bar is transparent at rest and gets its material from the
  scroll-edge effect once content passes under it; that effect is modelled
  only in the large-title path (`UINavigationBar.updatePocket`).
- **`UINavigationBar`'s default appearance is OPAQUE, not iOS 26's default.**
  A deliberate compatibility choice: it keeps the inline bar looking like it
  did before M13 for hosts and demos. Set `standardAppearance` explicitly for
  the iOS 26 look. No golden covers the default.

One guessed constant was **replaced** by measurement in M13: the inline
navigation bar's zone split was a 20 pt "status inset" + a 44 pt content bar
(title centre 42). Real iOS 26 is 10 + 54 with the title centre at **32**,
which is the same 64 pt total M10 already measured for the large-title bar's
inline zone. `UINavigationBar.barHeight` is unchanged, so nothing below the
bar moved.

## Alerts + custom transitions (M12, 2026-08-25)

Everything in `Sources/OpenUIKit/UIAlertController.swift` is measured from
real iOS 26.1 by `Tools/oracle2/alertprobe` (20 configurations, full private
view-tree dumps + window snapshots + a display-link sampling of the present
animation; `scripts/alert_probe_sim.sh`). What is NOT faithful:

- **No `UIVisualEffectView`, so nothing actually blurs.** The alert card and
  the button pills are live blurs in real UIKit. Here they are the measured
  FLAT equivalents: a least-squares fit of `out = k·base + m` over four
  neutral bases per appearance, giving alpha 0.7143 of 0.9937-white over the
  backdrop (light) / alpha 0.6506 of 0.0989-black (dark) for the card, and
  alpha 0.1372 of 0.109-black / alpha 0.1097 of white for the pills, applied
  over the card. Residual under 1.5 counts over the whole measured range on
  a FLAT backdrop — but a patterned backdrop shows through unsmeared, and a
  saturated one is wrong in hue: the real material desaturates (measured: a
  pure-red base gives (242, 168, 166) under the card where the flat model
  predicts (234, 193, 189)). Same limitation as the sheet grabber and the
  tab-bar platter.
- **The card's corners are CIRCULAR, real UIKit's are `continuous`.** A
  superellipse fit of the golden's corner profile is r = 41.5 with exponent
  2.6 (rms 0.36 pt) against 0.81 pt rms for the best circular fit (r = 32.3).
  We draw `layer.cornerRadius = 34` circular; the four corner regions
  disagree by up to ~2 pt over a few pt² each — far below the structural
  gate's 150-count severity threshold, and worth ~0.02 % of the scene.
- **The card's shadow is drawn as a RING, not as a layer shadow.** Core
  Animation draws a layer's shadow under the whole layer tree without
  occluding it (measured — golden/alpha_shadow_group), so a layer shadow on
  a 71 %-opaque card bleeds 4–7 counts into its interior, unevenly. Real iOS
  keeps the interior perfectly flat, so `_UIAlertShadowView` clips the
  blurred silhouette to the outside of the card's shape (non-zero winding
  ring). Its parameters (blur 22, offset (0, 8), alpha 0.085) are fitted to
  the measured edge profiles, not to a UIKit API.
- **The present transition animates ONLY the dim.** Sampling every layer's
  `presentation()` per display-link frame across an animated present found a
  critically damped opacity spring on the dimming view (ω = 22.88 rad/s,
  converged over 24 frames) and NO animation whatsoever on the card's layer
  or on any ancestor up to the window — no scale, no fade. If UIKit fades the
  card through a private portal/snapshot layer, this probe cannot see it. The
  DISMISS animation could not be measured at all (the dim's presentation
  opacity stayed pinned at 1 for the whole dismissal), so we play the present
  in reverse.
- ~~**Alert labels are TIGHTER than plain labels.**~~ **FIXED, and it was
  not an alert property.** The alert's title/message did render with wider
  advances than the golden's ("Delete File?" at 17 pt semibold +3.8 %,
  "This cannot be undone." at 15 pt +1.4 %), and the same golden's plain
  20 pt semibold label really did match byte for byte — but only because the
  divergence is ZERO at 20 pt. Mac Catalyst and iOS use different cuts of San
  Francisco (`.SFNS` vs `.SFUI`) that differ by a measured per-size constant
  below 20 pt, and the alert goldens are the ones rendered by iOS. See "Two
  cuts of San Francisco" at the top of this file. Alert wrap points now use
  the iOS advances like the rest of the alert layout.
- **Wrapped alert text uses the wrong line pitch.** Measured pitches are 22 pt
  for the title and 20 pt for the message (against 20.333/18 for the first
  line), which the card HEIGHT reproduces exactly — but the labels themselves
  draw with UILabel's own uniform pitch, so the second and later lines sit a
  point or two off. Single-line alerts (every alert_* fixture) are exact.
- **Text fields are laid out but never focused.** `addTextField` builds the
  measured 48 pt pill and places the field, and real iOS makes the first
  field first responder on presentation (with a blinking caret), which is why
  no fixture covers it — the golden would not be deterministic.
- **`preferredAction` styling is measured but ungoldened.** The filled pill
  ((55, 126, 239) with a white semibold title) was read off probe pixels; no
  fixture exercises it.
- **`UIPresentationController` holds `presentedViewController` `unowned`.**
  UIKit holds it strongly; here the presented controller owns its
  presentation controller (`vc.sheetPresentationController` is configured
  before a presentation exists), so the back reference has to be weak to
  avoid a cycle.
- **No `UIViewControllerInteractiveTransitioning`.** The interactive back
  swipe and the interactive sheet drag are scrubbed against the host clock by
  the controllers themselves, from measured physics; routing them through a
  percent-driven interactive protocol would change the feel. A custom
  animator therefore always runs non-interactively, and the built-in
  navigation slide stays scrubbable by living in
  `_UINavigationSlideAnimator` + `UINavigationController.applyTransition`
  rather than finishing through `context.completeTransition`.
- **A custom navigation animator gets no bar cross-fade.** `_runTransition`
  sets the bar's state directly instead of running
  `beginTransition`/`setTransitionProgress`, because the bar's cross-fade is
  driven by the same coverage function the built-in slide owns.
- **The alert centres in a HARD-CODED safe area.** `UIScreenMetrics`
  (`safeAreaTop` 59, `safeAreaBottom` 34) are the reference device's measured
  window insets — the portable core still has no safe-area model, and the
  page sheet's 59 pt top inset is the same constant. On a window that is not
  an iPhone 16 the card is centred as if it were.
## Real-app harness (M14, 2026-08-25): scope notes

Full report: docs/REAL_APP_TEST.md. What follows is the divergence list the
harness produced — every one of these is something a real app's source
exercised and OpenUIKit does not fully honour.

- **Dynamic Type is EXACT only at the default content size category.**
  `UIFontMetrics` / `UIFont.preferredFont(forTextStyle:)` /
  `UIFontDescriptor.preferredFontDescriptor(withTextStyle:)` are driven by
  `Resources/dynamic_type.json`, dumped from real iOS 26 by
  `Tools/oracle2/dyntypeprobe`. At `.large` (a device's default, and what
  every fixture renders) `scaledValue(for:)` measures as the identity and the
  table reproduces it exactly. At the other 11 categories the 19 PROBED base
  values are exact table hits; values between them are linearly interpolated,
  where real UIKit's curve is piecewise with 1/3-pt quantization and slope
  changes the probe does not resolve — worst observed gap ~2/3 pt at
  accessibility sizes. Widening `baseValues` in the probe closes it. Nothing
  is hand-fitted.
- **Nothing changes the content size category.** There is no Settings app, so
  `UILabel.adjustsFontForContentSizeCategory` is inert unless a host changes
  `UITraitCollection.current.preferredContentSizeCategory` itself, and
  `registerForTraitChanges` handlers only fire when a host calls
  `UIView._traitsDidChange(previous:)`.
- **Size classes use a bounds approximation, not device policy.** Partial
  `UITraitCollection` construction and `traitsFrom` merging match the modeled
  UIKit traits, and views/controllers inherit both axes through their window;
  before attachment they use `UIScreen.main`'s completed environment. If a
  host supplies a non-unspecified axis in `UITraitCollection.current`, it
  remains authoritative. Otherwise `UIScreen` and `UIWindow` classify that
  axis as regular at 600 pt and compact below it. OpenUIKit does not model
  device idiom, iPhone landscape exceptions, split-view/multitasking policy,
  or automatic trait-change delivery when a window is resized; a host must
  call `UIView._traitsDidChange(previous:)` after changing its environment.
- **A non-large sheet detent is drawn EDGE TO EDGE; iOS 26 draws a floating
  card.** `UISheetPresentationController.detents` is measured
  (`Tools/oracle2/detentprobe`, 13 cases, raw dump at
  `fixtures/realapp/detents_ios.json`): `context.maximumDetentValue` is
  exactly `containerHeight - 59 - bottomSafeArea` (759 on a 393x852 window),
  `.large()` is the frame OpenUIKit already drew, and a value above the
  maximum collapses to that frame — all reproduced. But below the maximum,
  real iOS 26 insets the card 8 pt on each side and 8 pt off the bottom and
  scales it by 377/393; the measured numbers do not decompose into an inset
  plus a height without modelling that transform, so OpenUIKit draws the sheet
  at the right HEIGHT with the wrong SHAPE. `.medium()` is implemented as half
  the container height plus the bottom safe area; measured is 425 on an 852 pt
  container, so the residual is 1 pt.
- **`UIStackView` composes with Auto Layout but does not generate its
  constraints.** M14 made `addArrangedSubview` clear
  `translatesAutoresizingMaskIntoConstraints` (as UIKit does), made a row's
  own unary size constraint count as content
  (`UIView._explicitSizeConstraint`), and made the solver leave arranged
  subviews' frames to the stack. That is enough for the common shape — a
  stack of constraint-sized rows inside a scroll view — but a stack whose
  arranged subviews are positioned by constraints RELATIVE TO EACH OTHER
  still will not lay out, because the stack is a frame layout, not a
  constraint generator.
- **`UIScrollView.contentLayoutGuide` drives `contentSize`, one-way.** The
  guide's origin is pinned to the content origin and its size is solved;
  `layoutSubviews` then adopts the solved size as `contentSize`. Setting
  `contentSize` directly while the guide is also constrained is undefined
  (UIKit calls it a conflict; OpenUIKit lets the guide win).
- **Accessibility is STORAGE ONLY.** `isAccessibilityElement`,
  `accessibilityLabel/Value/Hint/Identifier`, `accessibilityTraits` round-trip
  and nothing consults them. There is no accessibility tree to query and no
  assistive technology to drive, so there is also no oracle for them.
- **`UIWindow.makeKeyAndVisible()` runs no appearance transition.** Real UIKit
  sends `viewWillAppear`/`viewDidAppear` to the root controller; OpenUIKit
  does not, so app code that starts work in `viewDidAppear` never runs. Both
  `openrender realapp` and `openhost --app pocketcasts` work around it with an
  explicit call. This is a small fix and is the first item to take from the
  report's blocked list.
- **`UIImage(named:)` reads loose files, not asset catalogs.** No `.xcassets`
  or `.car` reader, and therefore no template-rendering-intent flag from the
  catalog — an app that relies on the catalog to mark an icon as a template
  gets an untinted image unless it tints explicitly.
- ~~**A target that links OpenUIKit still cannot `import Foundation`.**~~
  *(M15: CLOSED — see "Foundation coexistence (M15)" above.)* The geometry
  types, `IndexPath`, `NSRange` and `TimeInterval` are now `typealias`-es to
  Foundation's own, so there is one declaration rather than two rivals.
  `NSCoder` and `required init?(coder:)` (344 of the corpus's 5,099 files)
  resolve, and the real-app harness compiles them verbatim. Residue is
  narrowed and listed above: `NSAttributedString`, `Notification`/
  `NotificationCenter` and `Timer`/`RunLoop` still shadow Foundation's.
- **`UIView.init(coder:)` preserves UIKit's initializer contract, not archive
  support.** `UIView` exposes the exact required `init?(coder: NSCoder)`
  designated initializer and a distinct zero-argument convenience
  initializer. Foundation-visible builds make OpenUIKit's `NSCoder` an alias
  of `Foundation.NSCoder`; the Foundation-hidden Mach-O boundary aliases its
  Foundation-shim spelling back to OpenUIKit's fallback class. App and
  framework declarations therefore have one signature in both build modes.
  A code-based subclass that overrides `init(frame:)` and implements the
  required coder path inherits `init()` through ordinary Swift convenience-
  initializer rules; Focus's unchanged `AsyncImageView()` is the regression
  case. The coder token is still ignored, the view starts with zero geometry,
  and no nib, storyboard, or unarchiver state is decoded.
- **`#selector` and `@objc` do not compile off Darwin — and this is now the
  ONLY thing left in the real-app ledger.** Measured by reverting the vendored
  source to pristine upstream text: Linux emits *"error: Objective-C
  interoperability is disabled"* for `@objc`, and `Selector` is absent from
  corelibs-Foundation entirely. `#selector` fails behind it because its
  argument must be an `@objc` method. Two of the four sites fail on **macOS**
  too, because OpenUIKit's `UISwitch` is a native Swift class and so is not an
  ObjC-representable *parameter* type. No library can shim a compiler
  diagnostic, so the portable spelling (`Selector.named(…)` plus a
  `SelectorDispatching` table, docs/OBJC_RUNTIME.md) is the permanent answer
  for **Swift** app source. **Objective-C** app source pays nothing — libobjc2
  dispatches `@selector(tapped:)` natively (docs/OBJC_FACADE.md).
- ~~**OpenUIKit's classes carry no `@MainActor` isolation.**~~ *(M15: CLOSED
  — see "Actor isolation" below.)* `UIResponder` and every subclass,
  `UIControl`, `UIGestureRecognizer`, `UIScreen`, `UIDevice`, the touch/event
  types, the presentation and transitioning types, the bar-item and bar
  appearance types, the Auto Layout types and every delegate / data-source
  protocol are `@MainActor`, matching the iOS SDK. App source that writes
  `@MainActor func`, `@MainActor` closure types or `nonisolated` against that
  assumption — 641 uses across 270 corpus files — now type-checks.

## App-compat cluster: image loading, drawing, controls (2026-08-25)

What shipped (all oracle-backed): PNG/JPEG decode+encode and
`UIImage(named:/contentsOfFile:/data:)`, `UIBezierPath`, app-side drawing
(`UIView.draw(_:)`, `UIGraphicsImageRenderer`), and four controls —
`UIActivityIndicatorView`, `UISlider`, `UISegmentedControl`,
`UIPageControl` (fixtures `control_activity`, `control_slider`,
`control_segmented`, `control_pagecontrol`, `control_dark`).

**Deferred, with the reason:**

- ~~**`UIStepper`**~~ / ~~**`UIRefreshControl`**~~ / ~~**`UISearchBar`** /
  **`UIPickerView`**~~ — **all four shipped in the controls2 cluster; see the
  section at the top of this file for what is goldened and what is not.** The
  original deferral notes follow, because their measurements are still the
  ones the stepper is built from.
- **`UIStepper`** — measurable but not done. Real UIKit draws it through a
  SwiftUI hosting view (`UICoreHostingView<DesignLibraryStepper>`), so it
  renders ONLY in the windowed oracle. Probed metrics for whoever picks it
  up (94 x 32 control over white, Catalyst iOS 26.1): capsule background
  ≈ (243,243,243) over white (quaternarySystemFill-like), minus bar
  x 37..50 of a control at x=20 (13 pt long) in near-black (37,37,37), a
  1 pt divider at the centre (colour ≈ 180), and a matching 13 pt plus bar
  centred in the right half. Nothing else about the glyph strokes has been
  fitted.
- **Operational note**: regenerating a `"window": true` golden needs an
  ACTIVE, unlocked display session — `Tools/oracle2` composites through the
  real render server and otherwise fails with "window never became
  renderable" (this is what stopped `UIStepper` from being finished in this
  pass; the offscreen v1 oracle keeps working regardless).
- **`UIRefreshControl`** — needs scroll-view integration (pull-to-refresh
  offset behavior) that no static scene can validate, plus edits to
  `UIScrollView.swift`, which this cluster does not own. The visual is the
  spinner that already ships here.
- **`UISearchBar` / `UIPickerView`** — not attempted (they were not in this
  cluster's list).

**Fidelity notes on what did ship:**

- The activity indicator's ROTATION TIMING is not oracle-validated: Core
  Animation discards the spin offscreen and the windowed oracle can only
  sample it on the wall clock. The goldens pin the rest pose; the
  implementation advances one blade (45°) every 1/8 s, i.e. UIKit's
  classic one-revolution-per-second discrete step.
- `UISegmentedControl.intrinsicContentSize` is NOT reproduced (the oracle
  no longer dumps `intrinsic` for it). Real UIKit's per-segment width mixes
  the widest title, a 32 pt floor and ~18.5 pt of padding in a way that no
  probe set fit; scenes therefore give segmented controls explicit frames.
  Segment SPLITTING inside a given width is exact (integer-floor
  boundaries).
- `UISegmentedControl` disabled rendering uses a measured 0.5 alpha on the
  background and the titles (probe: 246 background and 146 ink over white
  against 238/39 enabled). No fixture covers the disabled state.
- Track-tap behavior on `UISlider` and tap-to-advance on `UIPageControl`
  are plausible UIKit behavior, not oracle-measured (no static scene can
  express them).
- `UIPageControl`'s glass background (real UIKit puts a
  `UIVisualEffectView` behind the dots) is not drawn: it composites to
  nothing in every capture probed, over white, black and red.
- The pure-Swift rasterizer backend ignores `UIBezierPath.lineCapStyle` /
  `lineJoinStyle` (it keeps its butt-cap / round-join model); the quartz
  backend — the default, and the one every golden uses — honors them via
  the additive `Canvas.stroke(_:color:lineWidth:cap:join:miterLimit:)`.
- `UIBezierPath.bounds` returns the FLATTENED (drawn) extent, not UIKit's
  control-point box.
- A view's custom content is rendered into an offscreen extent of
  `bounds` inset by −2 pt (LayerBridge.contentExtent), so app drawing —
  or a control shadow, e.g. the slider thumb's — that spills further than
  2 pt outside the bounds is clipped. UIKit clips `draw(_:)` to the view
  too, but its layer shadows are not clipped.
- `UIImage.withTintColor` recolors pixels immediately (CG `.sourceIn` of a
  flat color over the silhouette). `renderingMode` is stored and honored by
  that call, but `.automatic` behaves as `.alwaysOriginal` — there is no
  asset catalog to carry a template flag.


## Interactive sheets (M11, 2026-08-25): what shipped and what did not

Shipped, all measured (docs/APP_FEEL.md "Measured sheet interaction"):
drag-to-dismiss with the 10 pt slop and 1:1 tracking, the linear dim
interpolation, the 50 %-of-height and 1000 pt/s release rules, the
ω = √(1000/3) critically damped settle, the grabber, and the sheet ↔ inner
scroll view hand-off. Not shipped:

- **DETENTS — deferred deliberately, but MEASURED first.** `sheetprobe`
  established what they actually are on iOS 26, and it is a bigger mechanism
  than "another rest position":
  - With `[.medium(), .large()]` the sheet opens at **medium**, not large.
  - A non-large detent is not just shorter — it **floats**. The medium sheet
    reports frame (8, 403.687, 377, 440.313) on a 393×852 window: inset 8 pt
    on the left, right and bottom. Those numbers are one **scale transform of
    0.9593** applied to the ordinary full-width sheet (393 × 0.9593 = 377.0,
    36 × 0.9593 = 34.53, 5 × 0.9593 = 4.796 — the grabber scales with it), so
    the untransformed medium sheet is 393 × 459 and the chrome is a transform
    about the bottom edge, not a different layout.
  - Dragging between detents **RESIZES** the sheet: the bottom stays pinned,
    the top follows the finger and the height grows (measured 459 → 501 → 561
    → 617 → 677 → 689 as the finger travelled 240 pt up), and the scale
    transform is released to 1.0 the moment the drag starts. It does not
    translate the way a dismissal drag does.
  - The dim stays at a **flat 0.2 for the whole detent drag** — it responds
    only to dismissal progress, never to detent progress.
  - Release snaps to the nearest detent (240 pt up from medium landed on
    large: frame back to (0, 59, 393, 793)).
  - The dismissal rule stays proportional to the CURRENT detent's height: a
    400 pt custom detent springs back from 170 pt and dismisses from 210 pt.
  Implementing this needs a resizing sheet (content re-layout per frame), a
  transform-based floating chrome, and a snap-target search — three things
  none of which the dismissal path needed. The measurements above are the
  spec; nothing was built.
- **`isModalInPresentation` only suppresses the dismissal.** The sheet still
  tracks the finger 1:1 and springs back. Real UIKit also stiffens the drag
  itself (it resists rather than following); that resistance was not measured.
- **The grabber's DARK colour is extrapolated, not measured.** Light is exact
  — (197, 197, 200) over white, i.e. systemFill's (120, 120, 128) base at
  alpha 0.4295. `drawHierarchy` renders the dark grabber as *nothing at all*
  (the same private-material capture limitation as the dark textfield border
  and the dark tab bar), so the dark alpha is the light one scaled by the
  ratio UIKit uses for the systemFill family itself (0.2 → 0.36). No dark
  sheet fixture exists to check it against.
- **No tap-outside-to-dismiss — probed, result INCONCLUSIVE, so nothing
  changed.** A synthetic tap on the dim above the sheet did NOT dismiss it in
  the probe (`tap_outside`; `tap_outside_modal` and `tap_inside` likewise),
  which would say OpenUIKit's existing behaviour is already right. But that is
  the one probe result not confidently separable from a limitation of the
  synthetic-touch harness: the same harness demonstrably drives the sheet's
  own pan and the inner scroll view, yet a tap recognizer installed by UIKit
  on a private dimming view is a different delivery path, and common
  understanding of iOS is that a pageSheet DOES dismiss on an outside tap.
  Rather than ship a behaviour change on an ambiguous measurement, M10's
  "the dim swallows every touch" stands. Resolving it needs either a
  non-synthetic tap (a real UI test on a device/simulator) or finding the
  recognizer in the hierarchy dump and asserting on it directly.
- No `UISheetPresentationControllerDelegate`, and
  `UISheetPresentationController` exposes only `prefersGrabberVisible`. The
  detent API surface is deliberately ABSENT rather than present-and-fake.
- **The hand-off rule is written twice.** `_UISheetPanGestureRecognizer` and
  `UIScrollViewPanGestureRecognizer` each gate themselves on "is the scroll
  view at the top and is the drag downward", from opposite sides, because
  there is no `require(toFail:)` (see the event-system notes below). They
  cannot disagree today, but nothing enforces that. A *horizontally* scrolling
  view inside a sheet is untested.
- **A sheet whose content scroll view is not scrollable takes every downward
  drag**, because `dragsY` is false and the scroll pan never contests it.
  That is arguably correct (the content cannot move) and matches what the
  probe saw, but it is not separately measured.
- Only the top-most sheet is interactive: a sheet presented ON a sheet gets
  its own pan, but the stack is collapsed non-animated on dismiss (M10
  behaviour, unchanged).

## Showcase app / M10 completion (2026-08-25): scope notes

- ~~**No UICollectionView.**~~ M10's brief named it and nothing was built;
  it landed in M13, and the reuse machinery it needed (per-identifier
  pools, `dequeueReusableCell`, tiled visible-rect layout) was lifted out of
  UITableView into the shared `UIReuse.swift` at the same time. The
  showcase app itself still does not USE a collection view.
- **The floating tab bar reserves nothing.** There is no safe-area /
  `additionalSafeAreaInsets` model in the portable core, so every screen
  under a UITabBarController has to be told how much bottom chrome sits
  over it (`BottomInsetAdjustable` in DemoApp, set from
  `UITabBar.barHeight`). A screen that forgets draws under the platter.
  Same for `hidesBottomBarWhenPushed`: not implemented, so the tab bar
  stays over pushed detail screens (which is UIKit's DEFAULT, but real
  apps usually opt out).
- **Sustained scroll is under 60 fps at scale 2** in this app: ≈ 22 ms per
  frame on the Tasks table, ≈ 18 ms on the large-title Settings list
  (60 fps at scale 1). Cause, measurements and the parked fix:
  docs/APP_FEEL.md "Inset-grouped table scroll cost". The large-title
  pocket blur is recomputed per observed offset and is a large part of the
  Settings number — the KNOWN GAP noted below ("unmeasured at sustained
  60 fps with heavy content") is now measured, and it is real.
- ~~The profile sheet has no grabber, no drag-to-dismiss and no detents~~
  **FIXED for grabber + drag-to-dismiss (M11, see the section at the top of
  this file).** The profile sheet now shows the grabber, drags to dismiss,
  and its form scrolls, so the sheet/scroll hand-off is live in the app
  (`scripts/sheet_drag.json` captures all three outcomes). Detents are still
  absent — measured, deferred, spec recorded above.
- Tab selection still jumps rather than sliding the capsule, and switching
  tabs is instantaneous (real iOS crossfades the content). Both are
  UITabBar/UITabBarController gaps listed below, now visible in an app.
- **`OPENUIKIT_APP_STYLE=dark --app showcase` shows a LIGHT tab bar** over a
  correctly dark app: the platter (#FDFDFE), capsule and unselected-item
  colours are hard-coded light constants because the M10 tab-bar goldens
  are light. Every other surface in the three tabs resolves its dynamic
  colours correctly. This is the most visible unmeasured-chrome gap left.

## UITableView animated updates (M10, 2026-08-25): scope notes

- `performUpdates(withDuration:delay:options:identity:updates:completion:)`
  is NOT UIKit's API. UIKit takes an explicit list of moves/inserts/deletes
  (`moveRow(at:to:)`, `insertRows(at:with:)`, `deleteRows(at:with:)` inside
  `performBatchUpdates`); this takes a stable per-index-path identity and
  diffs. It covers moves and inserts; **deletes do not animate** — a row
  whose identity vanishes is retired immediately, because the cell would
  have to be kept alive outside the visible set to fade it out. There is
  no `UITableView.RowAnimation` vocabulary (`.fade`/`.top`/`.left`…);
  inserts always fade in.
- Scrolling DURING an update is not handled: the animation's recorded
  endpoints are the frames computed at update time, so a re-tile triggered
  by a contentOffset change mid-flight assigns model frames the in-flight
  animation still overrides. Nothing in the app can do this today (the
  update is started by a tap, and a tap cancels scrolling).
- A row that moves between sections in a grouped table borrows
  `secondarySystemGroupedBackground` for the flight and dissolves it over
  the last 0.12 s. Until that dissolve finishes the cell is an opaque
  RECTANGLE, so for the two or three frames it spends landing on a card's
  first/last row it covers that card's 26 pt corners. Measured composited
  output is white-on-white in light mode (invisible); in dark mode, or on
  a tinted card, it would show.
- `indexPathForSelectedRow` is re-derived from the identity map and is
  CLEARED if the selected row is not visible after the update (UIKit keeps
  off-screen selection).

## UITableView (M10, 2026-08-25): scope notes

- No real self-sizing: row height resolves delegate `heightForRowAt` →
  `rowHeight` → the measured 51.5 pt default. A data source that builds
  `.subtitle` cells must return `UITableViewCell.subtitleRowHeight`
  (70.5) from the delegate (openrender's scene driver does; real UIKit
  self-sizes). Same for multi-line custom cells.
- Inset-grouped side margin is oracle-dependent:
  `insetGroupedSideInset` defaults to the offscreen-Catalyst 8 pt (the
  light goldens); a real UIWindow measures 16 pt (tableview_dark,
  oracle2) — openrender's SceneBuilder sets 16 for `"window": true`
  scenes. Apps targeting device feel should set 16.
- Selection overlay is a full-bleed rect; on an inset-grouped section's
  first/last row it is NOT clipped to the card's 26 pt corners.
- No editing mode (delete/reorder); animated moves/inserts arrived with
  `performUpdates` (see above) but there is no delete animation and no
  `UITableView.RowAnimation`, no `UITableViewHeaderFooterView` reuse pool
  (headers/footers are rebuilt per section entering the viewport —
  cheap, they're one label), no index titles, no multi-selection.
- `.grouped` style renders with the `.insetGrouped` chrome (no legacy
  full-width grouped look; no fixture covers it).
- Plain footers have no golden: they render with header-like height
  (40.5) and footer typography; plain headers assume an opaque
  `systemBackground` (matches the golden over a white table).
- Dark WINDOW text (e.g. tableview_dark) draws through the smoothed
  rasterizer fallback: glyph_ink_window.json currently carries only
  light-mode masks, so dark window glyphs are slightly softer/heavier
  than the golden (text-module coverage gap, not table-specific;
  tableview_dark still passes at 97.7).

## Modal / tab bar / large-title chrome (M10, 2026-08-25): scope notes

- Modal presentation implements `.pageSheet` (default) and `.fullScreen`
  only — no popover/formSheet/custom transitioning delegates and no
  detents. Drag-to-dismiss, the grabber and `isModalInPresentation` landed
  in M11 (see the top of this file); tap-outside-to-dismiss still does not
  exist (the dim swallows touches). The presenting view is NOT pushed
  back/scaled — the golden shows a flat 20% dim over the base
  (indistinguishable in the fixture); revisit if a fixture ever exposes the
  scaled base edge. Sheet metrics (top inset **59 pt — measured off the live
  frame in M11**, corner radii 37.7/58.2 pt circular fits of iOS 26's
  continuous corners) are the iPhone-16 measurements and are used at every
  window size.
- UITabBar: light-mode platter/capsule/shadow constants only (the M10
  goldens are light); dark-mode glass is unmeasured. No badges, no
  `moreNavigationController` (> 5 items just shrinks the pitch), no
  selection animation (the capsule jumps — real iOS 26 slides it).
- Large titles: the bar tracks ONE explicitly bound scroll view
  (`UIViewController.setContentScrollView(_:)`); there is no automatic
  detection of the topmost scroll view, and `contentInset.top` is owned
  by the binding (an app that sets its own top inset on the tracked
  scroll view will fight it). The scroll-edge pocket is a tuned
  approximation (Gaussian sigma 8 pt + background wash + vertical fade
  vs. iOS's progressive material blur), recomputed per observed offset —
  fine for scripted/interactive rates, unmeasured at sustained 60 fps
  with heavy content. Bar transitions (push/pop title morph) fall back
  to the inline-title choreography in large-title mode — a pushed child
  currently keeps the large-title container layout of its nav controller.

## Auto Layout (M9, 2026-08-24): scope notes

- Priorities minimize a WEIGHTED SUM of violations (weight = priority), not
  a strict lexicographic hierarchy: pairwise battles (750 vs 749, 251 vs
  250, 999 vs required) resolve winner-take-all exactly like UIKit (LP
  vertex optimum, verified by fixtures), but in principle several weaker
  constraints could jointly outweigh one stronger — no fixture or normal
  layout depends on this.
- leading/trailing alias left/right (LTR only; no RTL). Layout margins and
  the safe-area/layout guides arrived with "controls2"; the eight MARGIN
  ATTRIBUTES (`leftMargin` … `centerYWithinMargins`) arrived 2026-08-28 and
  are golden-exact against real UIKit — fixture `constraints_margins`,
  100.0 % pixels, and a probe confirms the attribute spelling and the
  `layoutMarginsGuide` spelling resolve to the identical geometry on both
  sides. **They are read as a constant at solve time**, like intrinsic sizes
  and baselines: a constraint that uses a view's OWN margin attribute while
  that same view's frame is being solved is order-dependent here, because the
  margins depend on the frame the solve has not produced yet. Real UIKit
  converges over repeated layout passes. No fixture does this, and the
  fixture deliberately takes its margins from a FRAME-BASED container.

- **Oracle limitation found while measuring the margin attributes
  (2026-08-28), and it predates them.** The scene spec forces a safe area by
  overriding `safeAreaInsets` on a private `UIView` subclass. That override
  reaches DESCENDANTS — a child's inherited safe area, its guides and its
  `layoutMargins` all follow it — but it does **not** reach the overriding
  view's OWN `layoutMargins`. Probe, root 320x480 forced to safe
  (59,16,34,20), a box pinned to the root's own layout-margins guide:

  | | oracle (real UIKit, forced safe area) | OpenUIKit |
  |---|---|---|
  | box at the root's own margins | (8, 8) | (24, 67) |
  | box at a child container's margins | (24, 8) | (24, 8) |

  Both spellings — the guide and the attribute — diverge identically, so
  this is the safe-area model, not the new attributes. OpenUIKit adds the
  forced insets to that view's own margins; the oracle's UIKit does not,
  because its internal margin computation reads an ivar the getter override
  never sets. **On a real device the safe area is not overridden and the
  question does not arise**, and the controls2 measurement that says margins
  = base + safe area (44,10,34,12 -> 52,18,42,20) was taken through a real
  window, so OpenUIKit is very likely right and the oracle is the artifact.
  Not resolved either way here, because nothing renders it: no fixture pins
  to the forced view's own margins, and `constraints_safearea` — written
  before anyone noticed — happens to use a descendant's guide.
- Constraint attributes map to FRAME edges in the solve space; a superview's
  bounds.origin (scrolled UIScrollView content) is not modeled, so
  constraint children of a scrolled view anchor to its frame, not its
  visible bounds. No constraint fixture scrolls.
- Baselines: UILabel only (single-line line-box math, offset =
  floor(ascender + 0.5) from top — same rounding as the draw path). Other
  views' baseline attributes alias the bottom edge, like plain UIKit views.
  A label stretched beyond its intrinsic height keeps the top-anchored
  baseline (real UIKit re-centers; no fixture covers it).
- An unsatisfiable REQUIRED constraint is dropped at add time (UIKit
  "breaks" a constraint and logs; the library stays silent).
- UIStackView still lays out by direct frame computation (pre-M9 code,
  golden-exact); it does not generate constraints for arranged subviews.
  Mixing a stack view INSIDE a constraint-sized parent works (the solver
  sets its frame, then layoutSubviews distributes).

## Text input (M8, 2026-08-24): scope notes

- SELECTION is not implemented (no range selection, no select-all/copy/
  paste, no selection handles, no shift+arrows). Caret editing only.
  UIKit's UITextInput/UITextPosition/UITextRange protocol family is not
  reproduced — UIKeyInput plus internal key routing is the whole surface.
- Caret geometry is measured (height = lineHeight + 1.5, TF y from the
  probed caretRect box math, TV y = floor(8 + line·lineH − 0.75)) but the
  BAR IS DRAWN 2 pt WIDE in tint color per the visible iOS caret; real
  caretRect(for:) reports width 1. Blink cadence (0.6 s solid hold,
  0.5 s half-period) is feel-tuned, not measured.
- Dark-mode .roundedRect chrome: the fill's dynamic resolution was probed
  (light white / dark black) but the BORDER's dark resolution is not
  capturable offscreen — implemented as white@20% (light black@20% is
  measured). No dark textfield fixture exists (the offscreen oracle cannot
  resolve the private dynamic chrome color in dark — same trait quirk as
  SceneKit's colorOrDie note).
- UITextField at 15/19–21 pt: the unfocused text/placeholder use the
  UILabel line box (labelLineHeight, +1 in those bands) while real TF
  editing boxes use lineHeight + 2 — baselines can differ by ~0.5 pt at
  those sizes (fixtures/demo use 13/17 pt, where they coincide).
- UITextView with font == nil renders 12 pt system; real UIKit's legacy
  default is Helvetica 12 (lineHeight 14 vs our 15). Always set a font.
- UITextField shows text from offset 0 when not editing (matches UIKit);
  ending editing resets the horizontal scroll to 0 without animation.
- Typing glyphs come from the same UILabel ink-table/stb path as labels;
  TextKit's slightly different rasterization (≈1 px softer tops, seen in
  the golden diffs) is inside the 96-threshold by a wide margin
  (textfield_basic 99.87, textview_basic 99.97) — no TextKit-context
  glyph harvest needed so far.

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

- Physics constants are MEASURED against real iOS UIKit (M8, 2026-08-24):
  0.998/ms deceleration with a 10 pt/s stop and the 0.499 per-ms-sum
  position factor, c=0.55 rubber band, two-regime bounce spring (ω=11
  critically damped with velocity, λ=9/46 overdamped from rest), ~100 ms
  velocity window, exact 10 pt slop absorption. Ground truth + methodology:
  golden/scroll_traces/SCHEMA.md and docs/APP_FEEL.md "Measured scroll
  physics"; regression gate: Tools/compare/compare_scroll.py (9/9).
  Remaining honest gaps within that: (a) the rest-release bounce is an
  empirical overdamped fit — mid-curve it can deviate up to ~14 pt of a
  235 pt overscroll from the oracle (settle time is within 3%; whatever
  UIKit's true integrator is, no single linear spring fits both measured
  regimes); (b) the ~150 ms content-touch delay and the 50 pt/s regime
  threshold remain feel-tuned, not measured; (c) UIKit quantizes
  contentOffset to the device pixel grid — OpenUIKit doesn't (sub-1/3-pt);
  (d) real UIKit starts the decel animation ~1 frame after the lift;
  OpenUIKit starts it exactly at the lift timestamp (compare_scroll aligns
  ±20 ms); (e) Mac Catalyst's POINTER scroll physics (different decay,
  stiff rubber band — golden/scroll_traces/catalyst_pointer/) are a
  separate input mode OpenUIKit does not implement.
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
- Content-touch claim (M8.1): travel > 5 pt
  (`UIScrollView.contentTouchCancelDistance`) along a scrollable axis
  cancels a delivered content touch in the same event, ahead of the pan's
  10 pt recognition slop, so a row un-highlights the moment the finger
  starts dragging. The 5 pt is FEEL-TUNED, not oracle-measured (UIKit's
  own content-touch cancellation threshold is private); the axis test uses
  the dominant travel component and honors canCancelContentTouches /
  touchesShouldCancel(in:) exactly like the begin gate.
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

## Verification blind spot: localized degradation (top remaining)

The oracle comparison has three gates — layout (0.5 pt), pixel percentage
(category thresholds), and the structural gate (contiguous wrong region +
content absence). Together they catch *missing* and *moved* content well.

They are weakest against content that is **present but subtly wrong in a small
region**: a text run at the wrong weight/hinting/subpixel phase, a gradient
with a slightly wrong ramp, a control drawn with the wrong corner radius.
Absence cannot fire (both sides have structure), and a soft error's per-pixel
deltas fall under the 150-count severity floor, so only the percentage sees it
— and a small region on a large canvas barely moves the percentage. Measured:
a blurred 370×100 px text region scores 99.007 % and passes everything. The
floor is not a tunable here: blur *redistributes* ink rather than removing it,
so the largest per-pixel delta anywhere in that region is **92** and the severe
mask is empty — there are no components for either structural check to look at,
at any threshold above ordinary antialiasing.

This matters because it is exactly the class the M2 text work fought, caught
then only because the error was global. The fix is not another whole-frame
metric (two were measured and rejected — see SCENE_SPEC "Structural diff
gate"): it needs **per-region scoring**, e.g. align text runs via the layout
dump and score each run's ink against its own area rather than the canvas.
Until then, treat a high percentage on a text-dense scene as weak evidence,
and prefer adding a tight fixture (small canvas, one feature) over trusting a
large scene's score.

## `UIView.superview` is STRONG — the hierarchy is a retain cycle (found 2026-08-25, M14+)

Found by the Objective-C facade prototype (docs/OBJC_FACADE.md), whose first
ownership check fired on every orderly teardown until the cause was understood.

```swift
// Sources/OpenUIKit/UIView.swift
public internal(set) var superview: UIView?        // strong  <- UIKit's is not
public internal(set) var subviews: [UIView] = []   // strong
```

Both edges of the parent/child relationship are strong, so **a view hierarchy
is a reference cycle and is never deallocated** — a parent stays allocated
after its last external owner lets go, and so does everything under it. Nothing
in the render/oracle path notices: every fixture builds a tree, renders it, and
exits.

**What it costs.** Nothing for `openrender` (short-lived). For a long-running
host — `openhost`, and any real app, which is the whole point of M14 — every
screen ever built is retained forever. A navigation stack that pushes and pops
100 detail screens holds 100 view trees.

**The fix and its price.** `weak var superview` closes it, but `superview` is
read on hot paths (`layoutIfNeeded` walks to the root on every call,
`traitCollection` recurses up, `window` walks up), and a weak read is not free.
`unowned(unsafe)` would be free and matches UIKit's actual `assign` semantics,
at the cost of no dangling-pointer trap. Either way it needs a perf run over
`scripts/perf_*.json` and a pass over the places that assume a parent stays
alive (`UIPresentation`'s containers, `UIViewController._view`).

Not fixed in the facade branch on purpose: it is a view-module semantics change
with a measurable cost, and the bridge works without it.
