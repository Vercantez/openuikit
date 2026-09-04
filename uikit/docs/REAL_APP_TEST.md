# Running a real app's screen — the definition-of-done experiment

**Question:** can a screen from a real, shipping, open-source UIKit app be
compiled against OpenUIKit *as written* and rendered — headless, live, and
identically on Linux?

**Answer: yes, for the screen tested, at 99.3 % of its source unmodified.**
4 of 605 vendored lines had to change, and this file says exactly which 4
and why. It also says what the experiment did **not** prove, which is more
interesting than what it did.

> **Updated at the M15 tip.** The first version of this experiment reported
> **14** changed lines / 97.7 %. Three M15 pieces retired ten of them, one
> reason-class at a time, each one reverted to pristine upstream text and
> recompiled. This file is the merged ledger:
>
> * **Foundation coexistence** (docs/APP_COMPAT.md) retired the whole 5-line
>   "NSCoder / Foundation collision" row — `import Foundation` and
>   `required init?(coder: NSCoder)` are back, verbatim.
> * **`@MainActor` isolation** retired the 4-line row — `OptionAction`'s
>   `@MainActor` closure types and initializers are back, verbatim, now that
>   UIView/UIViewController/UIControl carry the isolation real UIKit does.
> * **The harness access-level line** retired the last non-UIKit entry — see
>   "The line that came off by moving the boundary" below. `OptionsPicker` is
>   `class OptionsPicker` again, with no `@MainActor` written into it.
>
> Blockers #2, #3 and the harness row are **closed**. The ledger is 4 lines
> / 99.3 %, and **all 4 are the single `#selector`/`@objc` row** — required by
> this experiment's native-ELF build, whose compiler rejects both spellings
> before OpenUIKit is consulted. **Three of the four vendored files are now unmodified
> app code end to end.** Nothing else about the experiment changed: the
> renders are byte-identical to the previous commit's (checked against a
> worktree build of it, 3/3), and the Linux gate still reports 13/13.

> **Responder-root update (2026-08-30).** The same four adaptations remain in
> this cross-platform harness because one source must compile on native ELF;
> this historical 605-line ledger has not been redefined. The former macOS
> half of the failure is now closed: `UIResponder` inherits NSObject, so
> UIViewController targets and responder controls including `UISwitch` and
> `UIDatePicker` are Objective-C-representable, and 0/1/2-argument actions use
> real runtime metadata without a `SelectorDispatching` table. Recognizer/event
> senders and Timer delivery retain narrower limits below.
>
> **Notification successor update (2026-08-30).** Foundation+Objective-C now
> uses Foundation's canonical Notification/NSNotification/NotificationCenter/
> OperationQueue family, so a direct `import Foundation` + `import UIKit` file
> has no center ambiguity and zero/one-argument notification selectors use the
> native runtime. Native ELF keeps the registry center. The Foundation-hidden
> guest has a bounded NSObject bridge and central 0/1 dispatch, but production's
> separately owned FoundationGuest shim still needs its four exact aliases.

---

## What was attempted

**App:** [Automattic/pocket-casts-ios](https://github.com/Automattic/pocket-casts-ios)
at `ddf27e6` (MPL-2.0). 1,690 Swift files; one of the four apps in the
`Tools/apicensus` corpus.

**Screen:** the **options picker** — the bottom sheet Pocket Casts puts up
from a "..." button, used on ~20 screens (Listening History, Up Next, General
Settings, the player shelf, Uploaded Files, …). Four source files, 605 lines:

| file | lines | what it is |
|---|---|---|
| `podcasts/OptionsPickerRootController.swift` | 258 | the sheet's `UIViewController`: a `UIScrollView` + `UIStackView` built entirely in code, self-sizing through `UISheetPresentationController` detents |
| `podcasts/SimpleActionView.swift` | 228 | one row: icon, label, optional secondary label, optional `UISwitch` or tick, tap gesture, press highlight |
| `podcasts/OptionsPicker.swift` | 83 | the presenter |
| `podcasts/OptionAction.swift` | 36 | the model for one row |

It was chosen for three reasons, all of which matter to the honesty of the
result:

1. **It is code-based.** No storyboard, no xib, no `@IBOutlet` — the explicit
   non-goal in docs/APP_COMPAT.md.
2. **It has no third-party dependencies at all.** All four files import only
   `UIKit` (and `Foundation`, for nothing). So the shim file below contains
   *zero* stand-ins for RxSwift/SnapKit/etc. — every shim is the app's own
   infrastructure. What is being tested is the UIKit surface and only that.
3. **It is dense in the things the census says apps actually do**:
   `UIStackView` + `NSLayoutConstraint` anchors, `UIScrollView`'s
   `contentLayoutGuide`/`frameLayoutGuide`, `layoutMarginsGuide`,
   `safeAreaLayoutGuide`, `systemLayoutSizeFitting`, `UIFontMetrics`,
   `UISheetPresentationController` custom detents, `#selector` target-action,
   `UIImage(named:)`, `registerForTraitChanges`, content hugging /
   compression resistance, `touchesBegan` highlighting.

Selecting one screen out of one app is a **sample of size one**. Everything
below is a measurement of that sample, not a claim about apps in general.

---

## What rendered

Headless, `openrender realapp` (three configurations, 393×852 @2×):

| ![history](images/realapp_history_light.png) | ![settings](images/realapp_settings_light.png) | ![dark](images/realapp_settings_dark.png) |
|---|---|---|
| `realapp_history_light` — the Listening History "..." menu, transcribed from `ListeningHistoryViewController.swift:234` | `realapp_settings_light` — a titled picker exercising the tick, the secondary label, the `UISwitch` row and the destructive row | `realapp_settings_dark` — the same in the app's dark theme |

Live, `openhost --app pocketcasts --script scripts/realapp_interaction.json`
(five of the ten recorded frames; each interaction is the app's own code
running):

![live](images/realapp_live_strip.png)

*0.20 s the sheet is mid-slide (the app calls `present(animated: true)`);
0.85 s at rest; 1.30 s the `UISwitch` has flipped — a touch went through
`UIControl.addTarget` and `Selector.named("switchToggled:")` into the app's
method; 1.95 s the Play row is filled with `#F7F9FA`, which is
`ThemeColor.primaryUi01Active` set by the app's `touchesBegan` override
arriving through `UIScrollView.delaysContentTouches`; 2.30 s the sheet is
gone, because releasing that press fired the app's `actionTapped`, which
called its own `animateOut(optionChosen:)`.*

Linux: `scripts/linux_realapp_verify.sh` builds the library, `openrender`,
`openhost` **and the vendored app source** inside a stock `swift:6.2-noble`
container, renders the three headless configurations, replays the scripted
interaction, and diffs all of it against this machine's macOS run.

```
==> build (library + openrender + openhost + RealAppProbe)
    built clean -- the vendored app source compiles off Darwin
  headless: byte-identical 3/3
  live:     byte-identical 10/10
byte-identical: 13/13
REAL-APP SCREEN VERIFIED ON LINUX
```

**Nothing here is oracle-goldened.** There is no real-UIKit golden of this
screen and there cannot be one without building Pocket Casts, so the render
is *plausible*, not *proven*. What IS proven against real UIKit is every
primitive underneath it — the 108 fixture scenes, and the new measurements in
`Tests/OpenUIKitTests/DynamicTypeTests.swift`, which replay
`Tools/oracle2/dyntypeprobe` and `Tools/oracle2/detentprobe` numbers taken on
real iOS 26. Two divergences are visible in the pictures above and are listed
under "Where the render is wrong".

---

## The adaptation ledger

This is the number the experiment exists to produce. Vendored sources are in
`Sources/RealAppProbe/Vendored/`; every change carries an `ADAPTED(reason)`
comment at the site.

| file | original lines | lines removed or changed | unmodified |
|---|---|---|---|
| `OptionsPickerRootController.swift` | 258 | **0** | 100 % |
| `SimpleActionView.swift` | 228 | 4 | 98.2 % |
| `OptionsPicker.swift` | 83 | **0** | 100 % |
| `OptionAction.swift` | 36 | **0** | 100 % |
| **total** | **605** | **4** | **99.3 %** |

**Three of the four files are now unmodified app code**, including the
258-line view controller — the actual *screen*, and the file with all the Auto
Layout in it. Every remaining changed line is in one file and belongs to one
reason.

### The 4 lines, by reason

| reason | lines | detail |
|---|---|---|
| ~~**`NSCoder` / Foundation collision**~~ | ~~5~~ **0** | **CLOSED at M15; exact initializer contract completed 2026-08-28.** `import Foundation` and the `required init?(coder: NSCoder)` are back, verbatim. What made it possible: OpenUIKit's `CGRect`/`CGSize`/`CGFloat`/`IndexPath` are now Foundation's own types rather than rivals, and `Sources/UIKitShim/UIKit.swift` re-exports Foundation the way real UIKit's swiftinterface does — so a file whose only import line is `import UIKit` can name `NSCoder`. `UIView` now exposes UIKit's exact required `init?(coder: NSCoder)` designated initializer and its distinct zero-argument convenience initializer. Foundation-visible builds alias OpenUIKit's spelling to `Foundation.NSCoder`; the Foundation-hidden Mach-O boundary aliases its shim spelling back to OpenUIKit's fallback identity, so app and framework declarations remain one signature. The app's unavailable coder initializer is therefore a real required override, and a code-based subclass that implements both designated paths inherits `init()` normally. It compiles; it does not *archive*: the coder token is ignored and no nib/storyboard state is decoded. |
| ~~**`@MainActor` isolation**~~ | ~~4~~ **0** | **CLOSED at M15.** `OptionAction`'s `action` and `submenu` closure types and its two initializers are declared `@MainActor` upstream; they used to be deleted, and they are now compiled as written. OpenUIKit annotates `UIView`/`UIViewController`/`UIControl` and the delegate protocols `@MainActor`, exactly as real UIKit does. |
| **`#selector` / `@objc`** | **4** | To keep this one source native-ELF-compatible, two `#selector(…)` call sites are `Selector.named(…)`; two action declarations omit `@objc`/`private`, and the one-argument sender is erased. Objective-C-capable responder controls no longer require these adaptations, but the Linux half still does. **This remains the whole cross-platform harness ledger.** |
| ~~**harness plumbing**~~ | ~~1~~ **0** | **CLOSED at M15.** See below — the boundary moved instead of the source. |

Notice what is **not** in that table: no missing method, no renamed property,
no restructured layout, no removed feature. Every one of the 4 lines is a
*language/runtime* incompatibility, not an API-surface hole. That is a
different and better failure mode than the census's "missing type" counting
suggests — but see "the code that was written *around* it", below.

### Why the row remains on native ELF — measured, not assumed

The four remaining lines were reverted to pristine upstream text and
recompiled, so the diagnostics below are what the toolchains actually say
rather than what docs/OBJC_RUNTIME.md predicts.

**On Linux, `@objc` is a compiler error.** Not a missing symbol — a
diagnostic, emitted before any library is consulted:

```
error: Objective-C interoperability is disabled
    @objc func switchToggled(_ sender: UISwitch?) {}
     ^
error: cannot find 'Selector' in scope       // Selector is not in corelibs-Foundation
```

That fires with or without `import Foundation`, and `#selector` fails behind
it because its argument must be an `@objc` method. **No library can shim a
compiler diagnostic**, so this row is closed by the language, not by
OpenUIKit's surface. It is the same wall docs/OBJC_RUNTIME.md documents for
Swift ObjC interop generally, reached from the app-source side.

**The former two macOS failures are now closed.** Before the responder-root
slice, the measured diagnostics were:

```
error: method cannot be marked '@objc' because the type of the parameter
       cannot be represented in Objective-C
    @objc private func switchToggled(_ sender: UISwitch?)
error: argument of '#selector' refers to instance method 'switchToggled'
       that is not exposed to Objective-C
```

At that boundary OpenUIKit's `UISwitch` was a plain Swift class. It now inherits
NSObject through `UIResponder` -> `UIView` -> `UIControl`, so the original
typed action and selector compile on Objective-C-capable builds. A responder
controller's exposed 0/1/2-argument actions dispatch through runtime metadata;
no hand-written table is required there. This exact transition is also pinned
by unchanged Reminder's UIDatePicker diagnostics, which move 4 -> 2.

All four harness lines still need their portable spelling because one source
text must compile on native ELF. A macro could generate its
`SelectorDispatching` table, but it cannot make that compiler accept `@objc`
or `#selector`; it would reduce scaffolding rather than this line count.

### The line that came off by moving the boundary, not the source

The harness row is worth its own paragraph because closing it required
distinguishing two things that looked identical in the ledger.

`OptionsPicker.swift` carried `@MainActor public class OptionsPicker` where
upstream has a bare `class OptionsPicker`. Two separate divergences:

* **`public`** was pure harness plumbing: `RealAppScreen`'s public factories
  *named* `OptionsPicker` in their signatures, and a public function cannot
  return an internal type. Fixed by moving the module boundary to the harness
  side — `RealAppScreen.makeRoot(variant:theme:)` now takes a public `Variant`
  enum, `OptionsPicker` never appears in a public signature, and it is
  `internal` again exactly as upstream declares it.

* **`@MainActor`** is load-bearing: deleting it produces **15** actor-isolation
  errors (`call to main actor-isolated initializer 'init()' in a synchronous
  nonisolated context`, and so on). The previous version of this file argued
  from that fact that the annotation was not really a divergence, since the
  app's own build would need it too. **That argument was wrong**, and the way
  it was wrong is instructive: pocket-casts ships the bare `class` and it
  compiles, because an Xcode 26 / Swift 6.2 app target defaults the *whole
  module* to main-actor isolation ("Approachable Concurrency"). The app never
  writes `@MainActor` because its build setting supplies it.

  So the fix was to mirror the app's **build configuration** instead of
  editing its **source**: `RealAppProbe` is now compiled with
  `-default-isolation MainActor` (Package.swift), and upstream's bare `class
  OptionsPicker` compiles as written. Verified accepted by both toolchains the
  gate uses — Apple Swift 6.2.1 and Linux Swift 6.2.4.

The general lesson, and the reason this is recorded rather than just fixed: a
line can be in the ledger because OpenUIKit is missing something, **or**
because the harness is not configured the way a real app target is. Those look
the same in a diff and are not the same result. The second kind should be
hunted for before any of it is counted against UIKit coverage.

### The code written around it (this is the real cost)

Unmodified app source is not the whole bill. Three files exist that a real
UIKit build would not need:

| file | lines | why |
|---|---|---|
| `Sources/RealAppProbe/Shims.swift` | 207 | the app's own infrastructure: its 11-theme colour system (`Theme`, `ThemeColor`, `AppTheme` — ~2,200 real lines collapsed to two themes, with **the exact hexes from the app's own `scripts/themes/theme.csv`**), its `UIFont.font(ofSize:weight:scalingWith:)` helper, `UIImage.tintedImage`, `UIView.updateSizeConstraints`, a `LiquidGlass` feature flag pinned off, and two empty sibling row classes. **No shim in this file stands in for a UIKit symbol** — that rule is stated at the top of the file, because shimming UIKit would make the measurement circular. |
| `Sources/RealAppProbe/SelectorTables.swift` | 23 | the `SelectorDispatching` conformance `SimpleActionView` cannot supply for itself. Two lines plus one per action, for **one** class. Real UIKit needs zero. |
| `Sources/UIKitShim/UIKit.swift` | 26 | a module literally named `UIKit` that does nothing but `@_exported import OpenUIKit` and (M15) `@_exported import Foundation` — the same two re-exports real UIKit's swiftinterface carries — so the vendored files keep `import UIKit` verbatim. Counted as a shim; it hides four lines of adaptation that say nothing about API coverage. |

Plus `Sources/RealAppProbe/RealAppScreen.swift` (121) and
`Sources/openrender/RealApp.swift` (81), which are harness, not app.

So: **605 app lines, 4 changed, 256 lines of scaffolding** (shims + selector
table + module alias). Scaled up, the scaffolding is the thing that would
hurt: the selector table is ~3 lines per action class, and the theme shim
would have to become the app's real theme system (which, since M15 closed
the Foundation row, would now largely compile as plain Swift). **The
scaffolding, not the ledger, is where the remaining cost is**: at 4 changed
lines the adaptation ratio has stopped being the informative number, and the
256 lines of surrounding infrastructure is what a whole-app attempt would
actually pay.

---

## What had to be built to get here

Everything the compiler asked for that was a genuine UIKit gap was
implemented rather than shimmed. All of it is *members of types OpenUIKit
already exported* — the gap docs/APP_COMPAT.md flags as under-measured, now
measured by a compiler instead of a regex.

| built | why the app needed it | oracle |
|---|---|---|
| `UIFont.TextStyle`, `UIContentSizeCategory`, `UIFont.preferredFont(forTextStyle:)`, `UIFontDescriptor.preferredFontDescriptor(withTextStyle:)`, **`UIFontMetrics`** | every label goes through the app's `UIFont.font(ofSize:weight:scalingWith:)` | **`Tools/oracle2/dyntypeprobe`** on real iOS 26: 11 styles × 12 categories × 19 base values → `Sources/OpenUIKit/Resources/dynamic_type.json`. Raw dump kept at `fixtures/realapp/dynamic_type_ios.json`. |
| `UISheetPresentationController.detents` + `.large()`/`.medium()`/`.custom(resolver:)` + the resolution context; `UIModalPresentationStyle.formSheet` | the sheet sizes itself to its content | **`Tools/oracle2/detentprobe`** on real iOS 26, 13 cases → `fixtures/realapp/detents_ios.json`. `maximumDetentValue` (759 on a 393×852 window = height − 59 − 34) and the over-maximum collapse to the `.large` frame are exact. |
| `UIScrollView.contentLayoutGuide` / `frameLayoutGuide`, wired into the cassowary solver so constraints against the content guide *drive* `contentSize` | the picker is a scroll view sized by its stack | covered by the existing scroll fixtures + new unit tests |
| **`UIStackView` composing with Auto Layout**: `addArrangedSubview` clears `translatesAutoresizingMaskIntoConstraints` (as UIKit does), a row's own size constraints are honoured as content, and the solver no longer overwrites arranged-subview frames | without it every row collapsed to height 0 and the sheet was 12 pt tall | the 108 fixture scenes and the existing stack tests are the regression bar; `testFillNestedStackIsFlexible` caught a real over-reach and constrained the fix |
| `UIView` `Equatable`/`Hashable` (identity), `systemLayoutSizeFitting(_:withHorizontalFittingPriority:verticalFittingPriority:)`, `layoutFittingCompressedSize`/`ExpandedSize`, `registerForTraitChanges`, accessibility storage; `UILabel.adjustsFontForContentSizeCategory`; `UIImage.draw(in:)`/`draw(at:)` | `if previousView != label`, `preferredSheetHeight`, `registerForTraitChanges`, `isAccessibilityElement`, image tinting | unit tests |
| **nine classes made `open`** (`UISwitch`, `UIStackView`, `UISlider`, `UISegmentedControl`, `UIProgressView`, `UIPageControl`, `UIRefreshControl`, `UIActivityIndicatorView`, `UISearchTextField`, `UIPanGestureRecognizer`) | `class ThemeableSwitch: UISwitch` did not compile | — |

Gates after all of it: `swift build` clean, **108/108 fixture scenes**,
**9/9 scroll traces**, **732 tests** (711 → 732), 0 failures.

---

## Blocked on — ranked

Ranked by how much of the corpus each one would touch. Counts are
`grep -rIo --include="*.swift"` over all four corpus apps (5,099 Swift files),
run 2026-08-25; the method over-counts comments and dead code, like the rest
of the census.

| # | blocker | corpus reach | what it costs today |
|---|---|---|---|
| 1 | **`@objc` / `#selector` on native ELF, plus its dispatch table** | `#selector` **1,138 uses / 360 files**; `@objc` **1,189 / 395** | Measured here at 4 changed lines + a 23-line table for one class — **the entire cross-platform harness ledger**. Reverting them makes native ELF emit "Objective-C interoperability is disabled". Responder and gesture-recognizer target/action plus measured zero/one-argument Notification selectors now use runtime metadata on Objective-C-capable builds; native ELF still needs the registry. Plain event senders and Timer remain bounded. Objective-C app source uses the separate libobjc2 facade (M15, docs/OBJC_FACADE.md). |
| ~~2~~ | ~~**Foundation cannot be imported alongside OpenUIKit**~~ — **FIXED at M15** | `NSCoder` **379 / 344**; and every app file that says `import Foundation` at all | Was "the single biggest structural obstacle to compiling an app *as a whole*". Closed by Foundation aliases; the Notification successor now also canonicalizes Notification/NSNotification/OperationQueue whenever Foundation is visible and NotificationCenter on Foundation+Objective-C. Residue: `NSAttributedString` and `Timer`/`RunLoop` remain shadows everywhere, native ELF qualifies its custom center, and `CGAffineTransform` still clashes on Darwin only. |
| ~~3~~ | ~~**No `@MainActor` isolation on OpenUIKit's classes**~~ — **SHIPPED (M15)** | `@MainActor` **641 uses / 270 files** | **Was** 4 of this sample's 14 changed lines; now 0. UIResponder and every subclass, UIControl, UIGestureRecognizer, UIScreen, UIDevice, the touch/event types, the presentation and transitioning types, the bar-item types, the Auto Layout types and every delegate/data-source protocol are `@MainActor`, matching the iOS SDK. The rendering core (OpenCoreGraphics), the text engine's glyph entry points, the Cassowary solver and the value-ish types (`UIColor`, `UIImage`, `UIFont`, `UIBezierPath`) are deliberately **not** isolated — they are legal off the main actor in real UIKit too. See docs/KNOWN_GAPS.md for the two `MainActor.assumeIsolated` boundaries this leaves. |
| 4 | **No asset catalog** | `UIImage(named:)` **438 / 161** | `UIImage(named:)` resolves loose `@2x`/`@3x` files only. Real apps ship `.xcassets`, which also carry the template-rendering-intent flag the app's tinting depends on. The harness copies three PNGs into `fixtures/realapp/assets/` and renames one (`small-tick` is stored as `tick@2x.png` inside its imageset). A `.xcassets` reader is a small, self-contained project. |
| 5 | **`UIWindow` runs no appearance transition** | `viewDidAppear` **119 / 105** | `makeKeyAndVisible()` does not call `viewWillAppear`/`viewDidAppear` on the root controller, so app code that starts work there never runs. The harness works around it with an explicit `presentPickerNow()`; both `openrender` and `openhost` had to do it. This is a small fix and should be one. |
| 6 | **Localization** | `L10n.` **3,400 / 540** | Not UIKit — but every user-visible string in three of the four corpus apps goes through a generated `L10n` enum backed by `NSLocalizedString`/`Bundle`. Any whole-app attempt hits it immediately. The harness passes literals. |
| 7 | **Visual-effect rendering** | 20 / 11 | `UIVisualEffectView` now executes Gaussian and masked-variable blur through the Canvas backdrop primitive. This screen still pins `LiquidGlass` off because `UIGlassEffect`, calibrated material styles, and framework-chrome routing remain open; the sheet platter, alerts and bar buttons therefore remain flat. |
| 8 | **`UIFontMetrics` away from the default category** | `UIFontMetrics` 66 / 48 | Exact at `.large` and at all 2,508 probed (style, category, base) points; linearly interpolated between them, where real UIKit's curve is piecewise with ⅓-pt quantization. Worst case ~⅔ pt at accessibility sizes. Widening `baseValues` in the probe closes it. |
| 9 | **iOS-26 floating sheet card** | — | Below the maximum detent, iOS 26 draws the sheet as a card inset 8 pt on each side and 8 pt off the bottom, scaled by 377/393. OpenUIKit draws it edge-to-edge at the correct *height*. The probe measured it (`fixtures/realapp/detents_ios.json`); the geometry does not decompose into an inset plus a height without also modelling the transform, so it was left. **Visible in the screenshots above.** |
| 10 | **Accessibility is storage only** | `isAccessibilityElement`, `accessibilityTraits` etc. | Values round-trip; nothing consults them. Fine for rendering, not for a UI test that queries the accessibility tree — which is the obvious next use for a UIKit reimplementation. |
| 11 | **`registerForTraitChanges` needs a host to fire it** | — | Registrations are stored and `_traitsDidChange(previous:)` delivers them, but nothing in OpenUIKit changes the content size category on its own. |
| 12 | **`UIStackView` is still a frame layout** | — | It now *composes* with Auto Layout (rows sized by their own constraints, stack reports a fitting size, solver defers to it), but it does not generate the constraints UIKit's does. A stack whose arranged subviews are positioned by constraints *relative to each other* would not work. |
| 13 | **xibs / storyboards** | `@IBOutlet` **1,678 / 323** | Explicit non-goal, restated because it is the reason 323 of 5,099 files are out of reach by construction — including the sibling `MultiSelectFooterView` in this very app. |

---

## Where the render is wrong

Stated up front because the screenshots look better than the fidelity claim.
**Measured against real iOS since 2026-09-04**: `scripts/realapp_probe_sim.sh`
runs the same unmodified app source under real UIKit on the iPhone 16 / iOS
26.1 simulator (`Tools/oracle2/realappprobe`), writing a 3x capture and a
layout dump per variant; `Tools/compare/compare_realapp.py` diffs
`OPENUIKIT_REALAPP_SCALE=3 openrender realapp` against it.

| variant | pixel score | MAE | largest blob | sheet frames |
|---|---|---|---|---|
| `realapp_history_light` | 99.0 (was 92.2) | 0.7 | 3.0 pt² | all match |
| `realapp_settings_light` | 98.5 (was 90.2) | 0.9 | 5.2 pt² | all match (UISwitch internals are private views) |
| `realapp_settings_dark` | 98.5 (was 90.0) | 1.0 | 2.8 pt² | all match |

What the measurement closed (each a measured UIKit fact, cited at the code):
the iOS 26 **floating sheet card** (the 393-wide sheet under a (W−16)/W scale
transform, corners 38 / 47.74, height = detent + 34 bottom safe area); the
**dark dim** (black at 0.48, not 0.2); the **iOS cut's vertical font
metrics** (`font_metrics_ios.json`; label line = lineHeight rounded UP to the
pixel grid); **pixel-grid rounding** of origins and sizes on a 3x device;
**UIStackView's zero layoutMargins**; **UIScrollView keeping content at the top
when `contentInset` grows** (offset −12); the **UISwitch on-track colour**;
the **Auto Layout tie-break** in a two-label row (`Tools/oracle2/layoutprobe`,
`golden/layout_tiebreak_ios.json`: a wrapping label's intrinsic constraints
are re-added after the first pass); and the **card shadow** (Gaussian fit to
the golden: black, σ ≈ 15.5 pt, opacity 0.09, offset +7.5 pt down — cast from a
background rounded at the larger radius, since neither compositor casts a
shadow from custom-drawn content).

### The whole scene suite against real iOS

`scripts/ios_suite.sh` captures every static scene with real UIKit on the
iOS 26.1 simulator (sRGB) and diffs `OPENUIKIT_FORCE_IOS=1 openrender`
against it — the port under the iOS font cut, the iOS palette
(`system_colors_ios.json`, measured by `Tools/oracle2/colorprobe`: 10 light
and 13 dark semantic colours differ from Catalyst's — `label` is opaque on
iOS, dark `systemBackground` is black) and pixel-grid rounding. The Catalyst
goldens stay the regression gate (109/109); this is the fidelity measurement.

| date | pass | note |
|---|---|---|
| 2026-09-04 | 17/98 | first capture; Display P3 captures read raw, Catalyst palette |
| 2026-09-04 | 31/98 | sRGB captures, iOS palette; worst families: gradients (56–85), grouped table views (78–94), text (88–95), group-opacity shadow (76), `corner_radius` (blob 3889 pt²) |
| 2026-09-04 | 37/98 | gradients interpolate in plain sRGB on iOS (Generic RGB is Catalyst's); switch on = systemGreen / off = tertiaryLabel; legacy button title box = whole-point ceil of lineHeight; simulator captures are standard-range straight alpha. Left: text rasterization (~20 scenes, iOS stems are crisper and ~20 % lighter than the Catalyst-harvested masks, baseline 1 px lower), iOS 26 inset-grouped cells (drawn 12 pt inside their frames, mechanism not in any dump), group-opacity shadow, `corner_radius` > half |


Still wrong:

1. **Circular corners where iOS draws continuous ones** (the card, the switch
   track) — a few pixels at each corner.
2. **The switch thumb is a flat white capsule**; iOS 26's is a liquid-glass lens
   with highlights, and the on-track sheen image is not modelled (the flat
   colour is the measured composite).
3. **No blur anywhere.** The sheet platter is a flat fill.
4. **Two tie-breaks the engine does not reproduce** (a compression tie and two
   width preferences at 250 — "the first view takes the space"), reported by
   `LayoutTieBreakTests`, not gated.

---

## Verdict

**How far is OpenUIKit from running real apps?**

*Rendering* a real code-based screen: **arrived, for this class of screen.**
The screen's own layout code — 258 lines of `UIScrollView` + `UIStackView` +
anchors + guides + a self-sizing sheet — compiled and laid out with zero
edits, and the result is byte-identical on Linux. That is a stronger result
than the census's 96.3 % "effective coverage" predicted, because the census
counts *types* and the things that actually broke were *members* and
*language features*.

*Compiling a whole app*: **closer than at M14, and the remaining reasons are
now specific, ranked, and mostly not about UIKit.** The two that M14 called
the biggest structural obstacles — Foundation interoperability and
`@MainActor` — are both closed, and closing them is what took this ledger from
14 lines to 4.

What is left, in descending order of impact: native-ELF selector syntax and
its registry (item 1), asset catalogs (item 4), localization (item 6) and xibs
(item 13). The first remains a language wall only for native ELF Swift:
`@objc` does not compile there and no library can change that diagnostic.
Objective-C-capable responder targets now use real metadata with unchanged
source. The honest cross-platform framing is still a per-action-method cost on
native ELF, where a macro could generate `SelectorDispatching`. Objective-C app
source pays nothing here because its separate facade uses libobjc2
(docs/OBJC_FACADE.md).

A useful next milestone is therefore not "more UIKit types" and no longer
"Foundation" either. It is **the scaffolding**: an `.xcassets` reader and the
selector macro, which together are most of the 256 lines this harness had to
write around the app.

*Caveat on the whole thing*: one screen, one app. The next screen would find
different holes. `Sources/RealAppProbe` is set up so adding a second one is
cheap, and that is the way to make this number mean something.

---

## Reproducing

```sh
# headless
swift build -c release --product openrender
OPENUIKIT_BACKEND=quartz ./.build/release/openrender realapp out_realapp

# live (SDL2 window; add --script/--record for the deterministic capture)
swift build -c release --product openhost
OPENUIKIT_BACKEND=quartz ./.build/release/openhost --app pocketcasts
OPENUIKIT_BACKEND=quartz ./.build/release/openhost --app pocketcasts \
    --script scripts/realapp_interaction.json --record out_host_realapp

# Linux byte-identity (Docker)
scripts/linux_realapp_verify.sh

# re-take the oracle measurements (iOS Simulator)
scripts/dyntype_probe_sim.sh <outdir>
scripts/detent_probe_sim.sh  <outdir>
```

The app checkout is not vendored. `git clone https://github.com/Automattic/pocket-casts-ios`
and compare `Sources/RealAppProbe/Vendored/` against `podcasts/` to audit the
4-line ledger yourself. Three of the four files should differ only in
comments.
