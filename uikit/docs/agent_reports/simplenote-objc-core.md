# Simplenote route (b): Objective-C classes can subclass the OpenUIKit UIKit chain

**Date:** 2026-09-22  
**Route:** (b), Apple toolchain (Xcode 26.1, Swift 6.2.1) on the macOS host  
**Corpus:** Automattic/simplenote-ios `9b1bb17d8ec224a709d306e0ec34cee38bc7d933`, unpatched  
**Status:** the structural wall is gone for the 11 classes Simplenote
subclasses. An Objective-C class can now subclass UIResponder, UIView,
UIControl, UIScrollView, UITableView, UITextView, UITextField,
UITableViewCell, UIViewController, UINavigationController and
UITableViewController. Its overrides run, and its trace matches the iOS 26.1
simulator line for line. Simplenote's first screen is **not reached**. The
Swift half's bridging-header precompile went from 12 errors to 1
(`SPInteractiveTextStorage : NSTextStorage`). The walls behind that one are
measured below.

## The design (the spike's vtable-free rule, not `@objc @implementation`)

`objc-implementation-spike.md` measured the rule this work relies on. A
statically emitted Objective-C subclass works under a Swift class only if
every class on the chain adds no Swift vtable slot. I applied that rule to
the real classes instead of moving them to `@objc @implementation`, for two
reasons:

* `@implementation` needs the whole class body to be an extension of a
  Clang-declared class. The Linux ELF build and the Foundation-hidden guest
  library build have no Objective-C runtime and still need the plain
  `open class`. The result would be two copies of each 1,000-line class, or
  a code generator.
* The vtable-free rule needs no header files. Swift's own generated header
  already declares the classes, and one attribute per member switches the
  behaviour per platform.

The mechanism (`Package.swift` defines `OPENUIKIT_OBJC_SUBCLASSING` for
Apple platforms only):

| member kind | Apple toolchain | Linux ELF / guest library route |
|---|---|---|
| overridable (`open`) member, designated initializer | `#if OPENUIKIT_OBJC_SUBCLASSING @objc(<SDK selector>) #endif` + `dynamic`, so Objective-C message dispatch is used and no vtable slot exists | `dynamic` (native), unchanged dispatch |
| everything else (`public`, internal, private, stored properties) | `final` | `final` |
| the class | `@objc(UIKitName)`: UIKit's runtime name, and `SWIFT_CLASS_NAMED` in `OpenUIKit-Swift.h` | unchanged |

**Selective subclassability.** Every generated interface is
`objc_subclassing_restricted` through `SWIFT_CLASS` / `SWIFT_CLASS_NAMED`.
Consumers predefine `SWIFT_CLASS` exactly as the header would and
`SWIFT_CLASS_NAMED` without the attribute. Only the 11 chain classes use an
explicit `@objc(Name)`, so they are the only subclassable ones. An
Objective-C subclass of any other OpenUIKit class is still a compile error,
not the runtime vtable crash probe1 measured. `Package.swift` holds the
define pair (`openUIKitObjCSubclassingDefines`), and the ingest tool emits
the same pair for every Clang and Swift consumer of an app.

**Selectors are the SDK's.** `Tools/oracle2/objcsubclassprobe/selcheck.py`
compared every selector of the 11 generated interfaces
against the iPhoneSimulator26.1 SDK headers, including superclasses and
adopted protocols. Wherever the Swift-derived name differed, it is now
explicit: `drawRect:`, `nextResponder`, `touchesBegan:withEvent:`,
`hitTest:withEvent:`, `pointInside:withEvent:`, `isDescendantOfView:`,
`layoutSublayersOfLayer:`, `validateCommand:`,
`userInterfaceLayoutDirectionForSemanticContentAttribute:…`, the four
`…TrackingWithTouch:withEvent:`, `touchesShouldCancelInContentView:`,
`moveRowAtIndexPath:toIndexPath:`, the eight UITextInput selectors,
`showViewController:sender:`, `will/didMoveToParentViewController:`, the 13
UITableViewController data-source/delegate selectors, and
`@property (getter=isX) BOOL x` for `enabled`, `selected`, `highlighted`,
`secureTextEntry` and `navigationBarHidden`. The only remaining non-SDK
selectors are OpenUIKit's own `_ouk_drawContentIn:bounds:` and
`stateDidChange`.

### What had to change kind (the spike's X bucket, measured on the simulator)

`Tools/oracle2/objcsubclassprobe` records `class_getSuperclass` on iOS 26.1.
OpenUIKit now matches it:

| type | before | after | why it had to change |
|---|---|---|---|
| UITouch, UIPress | final Swift class, `Hashable` | NSObject subclass (identity equality, as before) | `touches*` / `presses*` take `Set<UITouch>` / `Set<UIPress>` |
| UIEvent | final Swift class | NSObject subclass, non-final | `touches*`, `hitTest`, `pointInside` |
| UIPressesEvent | Swift class | subclass of UIEvent (measured) | `presses*` |
| UIColor | Swift class, `Hashable` | NSObject subclass; `isEqual:`/`hash` keep the old resolved-components equality | `tintColor` override point; every Objective-C color use |
| UITraitCollection | mutable struct | immutable NSObject class over the old fields (`_with { }` replaces 5 internal mutation sites; 2 tests adjusted the same way) | `traitCollection`, `traitCollectionDidChange:` |
| Canvas (OpenCoreGraphics) | final Swift class | NSObject subclass | `drawContent(in:bounds:)` has 25 overrides and must dispatch on Objective-C subclasses too |
| 9 enums | Swift enums | `@objc` Int enums with SDK names and raw values (`UITableViewStyle`, `UITableViewCellStyle`, `UITableViewCellEditingStyle`, `UIStatusBarStyle`, `UIModalTransitionStyle`, `UISemanticContentAttribute`, `UIUserInterfaceLayoutDirection`, `UIControlContentVertical/HorizontalAlignment`) | parameters of `@objc` initializers and override points |

The iOS 26.1 superclass facts, all matched: `UIResponder:NSObject`,
`UIView:UIResponder`, `UITouch:NSObject`, `UIEvent:NSObject`,
`UIPress:NSObject`, `UIPressesEvent:UIEvent`, `UIColor:NSObject`,
`UITraitCollection:NSObject`.

Four internal override points take Swift-only types, and none of them is
public API. Each one's override is now reached by a type check in a `final`
base: `_iosGlassPath` (the sheet), `_defaultBaseLayoutMargins` (the cell and
its content view), `_constraintBaselines` (UILabel), and UIAlertController's
presentation factories. `clearButtonPalette` (UISearchTextField) gets the
same treatment.

### The documented exceptions (Swift vtable slots kept on purpose)

Apps override these members, so they stay `open`, but their types cannot
be Objective-C:

* `UIResponder.buildMenu(with:)`, because `UIMenuBuilder` is a Swift
  protocol whose requirements use Swift structs.
* On UIViewController:
  * `supportedInterfaceOrientations` (a Swift `OptionSet`)
  * `preferredContentSizeDidChange`, `systemLayoutFittingSizeDidChange`,
    `size(forChildContentContainer:…)`, `viewWillTransition(to:with:)` and
    `willTransition(to:with:)` (Swift protocols)
  * `popoverPresentationController` and `transitionCoordinator`

Every OpenUIKit caller goes through a `_…Dispatch` helper
(`ObjCSubclassing.swift`). The helper reads the slot only when every class
from the receiver's isa up to the declaring class is a Swift class, checked
with the `FAST_IS_SWIFT` bits. Otherwise it runs the base behaviour, which
is what an Objective-C subclass would get anyway, because it cannot override
a Swift-only member. `ObjCSubclassingTests` enforces this list exactly.

### Two runtime hazards found while doing it (measured, fixed, documented)

1. **`Self.classMember` / `type(of: self).classMember` crash on an
   Objective-C subclass instance.** For such an instance, Swift's metatype is
   an ObjCClassWrapper. Swift lowers a class-member message on a metatype of
   a Swift class as if that metadata were the class object, so `objc_msgSend`
   receives the wrapper. A scratch probe on macOS 26 measured `SIGSEGV` at
   `0x310` (wrapper kind 0x305 + 0x10) for `Self.k`, `type(of: self).k`,
   `(object_getClass(self) as! A.Type).k` and an `unsafeBitCast` of it.
   `_objcMessageable(_:)` boxes the metatype as `AnyObject`, which goes
   through `swift_getObjCClassFromMetadata` and yields the real class. That
   is used at `UIView.layer` (`layerClass`), in
   `effectiveUserInterfaceLayoutDirection`, and in
   `UITableView.register(_:forCellReuseIdentifier:)`.
2. **Stale incremental builds crash.** Vtable offsets moved, so an object
   file that a dependency change did not trigger recompiling still reads old
   slots. This was measured: `EidolonRxCocoaTests`' `TapScenarios.swift.o`
   (reached through the `UIKit` shim) was not rebuilt and crashed in
   `objc_msgSend`. A clean `.build` fixes it. `agent_merge.sh` uses fresh
   worktrees; **any existing `.build` must be cleaned after this lands.**

## Proof

| check | result |
|---|---|
| `Tests/ObjCSubclassingTests` (new, 7 tests) | The shared Objective-C scenario compiled against OpenUIKit (`OUKObjCView : UIView` overrides `initWithFrame:`, `layoutSubviews`, `sizeThatFits:`, `willMoveToSuperview:`, `didMoveToSuperview`; `OUKObjCLeafView : OUKObjCView`) produces **the same 43-line trace** as the iOS 26.1 simulator (`transcript-ios26.1.txt`). That includes `-init` reaching the subclass's `-initWithFrame:`, layout counts across `layoutIfNeeded`/`setNeedsLayout`/bounds change, and `sizeToFit` using the override. The 8 superclass facts match. A Swift subclass still overrides `init(frame:)`/`layoutSubviews`/`sizeThatFits`. The Swift type descriptors of all 11 classes introduce no vtable slot outside the allowlist. No selector is implemented twice (a bridge twin would replace the native method). Runtime names are UIKit's. |
| Before the change | `@interface OUKObjCView : UIView` fails to compile (`objc_subclassing_restricted`). With the attribute lifted, `-init` crashes on a null vtable slot (simplenote-launch3 probe1). |
| `Tests/OpenUIKitObjCBridgeTests` | 8/8, including new tests for the SDK-named color surface and for the support header's Swift-distinct C names |
| full `swift test` (clean build, sequential) | 1894 tests; the 11 failures are **identical** to base `9cd38125` run the same way (1887 tests, same 11). Per-class isolated runs: the same 7 failing classes on both. |
| Catalyst gate | **124/124** |
| pixels | All 178 scene PNGs and all 15 real-app PNGs are **byte-identical** to base `9cd38125` (release `openrender`, same inputs) |
| real-app 3x | 99.137 / 98.535 / 98.548 / 99.74 / 98.72 / 98.334 / 97.549 / 99.65 / 98.823 / 98.558 / 99.86 / 99.734 / 98.235 / 99.61 (all at or above the gate floors) |
| Linux `swift:6.2-noble` | `openrender` (release), `ConformanceApps`, `OpenUIKitTests` build |
| ingest tests | 48/48 with the corpus (2 new) |
| guest route / machorun | see "Guest verification" |

## Simplenote, re-ingested

`python3 uikit/Tools/ingest/xcodeproj_to_package.py …/Simplenote.xcodeproj
--target Simplenote --out … --allow-gaps` then
`swift build --target Simplenote`:

| stage | simplenote-launch3 | now |
|---|---|---|
| bridging-header PCH | 12 errors: 10 × `objc_subclassing_restricted`, `NSTextStorage`, `NSDirectionalEdgeInsets` | **1 error**: `SPInteractiveTextStorage.h:4: cannot find interface declaration for 'NSTextStorage'` |
| ObjC half, per-TU `clang -fsyntax-only` (61 TUs, `Simplenote-Swift.h` still the Foundation-only placeholder) | 24 clean, 1,100 errors, 601 missing selectors, 256 unknown names, **52 cannot-subclass** | **25 clean, 981 errors, 564 missing selectors, 246 unknown names, 0 cannot-subclass** |

The following were fixed on the way, each with a test:
* The enums OpenUIKit now exports are no longer redeclared in
  `UIKitObjCSupport.h`. Clang had reported `different definitions`.
* `UIEdgeInsets`, `NSDirectionalEdgeInsets` and the 16 support protocols
  carry `NS_SWIFT_NAME(…ObjC)`. This removed 13 `ambiguous use of
  'init(top:left:bottom:right:)'` and 16 protocol-ambiguity errors from the
  Swift half.
* The `NSDirectionalEdgeInsets` struct now exists on the Swift side. Its
  inline `Make` stays ObjC-side because it collides with AppKit's, a
  re-measurement of launch3's note.
* `MobileCoreServices` links OpenUIKit's product. macOS has no SDK module of
  that name, which cost 231 duplicate errors.
* 52 SDK-named UIColor class properties, `colorWithRed:…`,
  `colorWithWhite:alpha:`, `colorNamed:`, `colorWithAlphaComponent:`, and
  `backgroundColor`/`textColor` twins exist now that UIColor is an NSObject.
* 22 bridge twins that the classes now implement natively were removed.

### The next wall (exact)

```
Sources/SimplenoteObjC/include/Simplenote/Classes/SPInteractiveTextStorage.h:4:39:
error: cannot find interface declaration for 'NSTextStorage', superclass of 'SPInteractiveTextStorage'
error: failed to emit precompiled header … for bridging header 'Sources/SimplenoteObjC/include/Simplenote/Simplenote-Bridging-Header.h'
```

The app expects UIKit's NSTextStorage, which subclasses **Foundation's**
`NSMutableAttributedString`, and overrides the four primitives
(`SPInteractiveTextStorage.m`). OpenUIKit's NSTextStorage subclasses
OpenUIKit's own run-based `NSAttributedString`, which is not NSObject-derived
and shadows Foundation's. Fixing this means putting OpenUIKit's text system
on Foundation's `NSAttributedString` for the Apple toolchain and the
Foundation-carrying guest, while keeping the portable one for the
Foundation-hidden library route. That is an architecture item of its own,
and it is **open**.

**What lies behind it** (measured with an uncommitted experiment that
declared an Objective-C `NSTextStorage` so the PCH passes; the experiment
is not in the branch). The Swift half reaches type checking with **488
unique errors in 85 of 228 files**, plus Clang ODR collisions. The groups,
largest first:

1. **The macOS triple.** These errors come from compiling iOS source for
   `arm64-apple-macosx`, not from OpenUIKit:
   * 42 × `@IBAction methods must have 1 argument`. This is the macOS rule;
     iOS allows 0 to 2 arguments.
   * The pinned SimplenoteFoundation takes its `#elseif os(macOS)` branch
     and `import AppKit`, which puts AppKit in the Swift half's Clang
     context.
2. **AppKit/QuartzCore class-name collisions** with OpenUIKit's exported
   Objective-C interfaces: `different definitions in different modules` for
   CALayer, NSParagraphStyle, NSMutableParagraphStyle, NSTextContainer,
   NSLayoutManager, NSLayoutConstraint, NSTextAttachment,
   NSAdaptiveImageGlyph and NSTextStorage. launch3's `-D` renames rename
   AppKit's copies too (`'OUK_NSLayoutConstraint' has different
   definitions`).
3. **Two universes for Foundation types.** `'NSAttributedString' is
   ambiguous` (22), `'Timer' is ambiguous` (6).
4. **API narrowing and gaps.** Examples: `overriding non-open property
   outside of its defining module` (8), `method does not override` (15),
   `restorationIdentifier`, `setBackgroundImage`, `UIAccessibility`,
   `UITextInputPasswordRules`, `isEditing`, `selectedRange`.

Points 1 and 2 argue for building route (b)'s app half for an iOS triple (or
`-macabi`) instead of macOS. That is a route decision; it was not attempted
here.

## Guest verification

GUEST_RESULT_PLACEHOLDER

What the guest run does **not** exercise: the guest build (`build_full.sh`)
compiles OpenUIKit without `OPENUIKIT_OBJC_SUBCLASSING`, which is
Apple-toolchain only. So the guest run shows that the shared-path changes do
not regress route (a): NSObject-derived UIColor, UITraitCollection, Canvas
and UIEvent, plus the `final`/`dynamic` modifiers. Objective-C subclassing
on machorun's objc4 is **not reached**. It needs an Apple-toolchain Mach-O
under machorun. As built today, that binary links macOS frameworks
(CoreServices, AudioToolbox, CoreHaptics, … for `openrender`), which the
guest does not provide. The evidence that objc4 accepts the layout is the
macOS host runtime (Apple's objc4) and the iOS 26.1 simulator oracle, the
same class-layout rules the spike relied on.

## Risks

* **API narrowing.** These members were `open` and are now `final` because
  their types are not Objective-C: UITextField/UITextView text-input traits
  (7 + 7), `attributedText`, `attributedPlaceholder`, `clear/left/
  rightViewMode`, `UIControl.state`,
  `UITableViewCell.defaultContentConfiguration()` and
  `UIViewController.edgesForExtendedLayout`. Nothing in this repository
  overrides them. An app outside it that does will not compile.
* **Message dispatch on the Apple toolchain** for every override point.
  Pixels are byte-identical; speed was not measured.
* **`UITraitCollection` is a class.** Code that mutated a copy
  (`var t = x.traitCollection; t.style = …`) no longer compiles, as in
  UIKit. Seven sites in the repository were converted.
* **Stale `.build` directories crash** (hazard 2 above).

## Validation commands

```
swift build --build-tests && swift test --skip-build --filter "ObjCSubclassingTests|ObjCBridgeTests"
Tools/oracle2/objcsubclassprobe/run.sh           # iOS 26.1 simulator oracle (transcript-ios26.1.txt)
python3 Tools/oracle2/objcsubclassprobe/selcheck.py .build/arm64-apple-macosx/debug/OpenUIKit.build/include/OpenUIKit-Swift.h UIResponder UIView …
LADDER_CORPUS=…/scratch/ladder-corpus python3 -m pytest Tools/ingest/test_xcodeproj_to_package.py
CHECK_ONLY=1 uikit/scripts/agent_merge.sh <branch>
```
