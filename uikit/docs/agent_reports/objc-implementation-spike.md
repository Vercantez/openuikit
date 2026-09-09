# `@objc @implementation` spike: can OpenUIKit's classes be Objective-C-declared, Swift-implemented?

**Date:** 2026-09-09  
**Branch:** `agent/objc-impl-spike`  
**Route:** Darwin only (Apple toolchain; macOS host and the iOS 26.1 simulator)  
**Status:** bounded measurement, no port. No wall hit; the probe answers every
question it was asked, and the answers bound the size of option (2).

Context: `simplenote-launch3.md` measured that Objective-C cannot subclass an
OpenUIKit class (`objc_subclassing_restricted` on all 134 generated
interfaces; lifting it crashes in `UIView.init()` on a null Swift vtable
slot), and named two architectures: (1) Objective-C-implemented UIKit classes
(`ObjCFacade` extended to the whole surface), or (2) OpenUIKit's classes
declared in an Objective-C header and implemented in Swift with SE-0436
`@objc @implementation`. This report measures (2) on the smallest surface and
then counts what UIView would have to change.

## Toolchain

| item | version |
|---|---|
| Xcode | 26.1 (17B55) |
| Swift | 6.2.1 (swiftlang-6.2.1.4.8 clang-1700.4.4.1), `swift-tools-version:5.9` package |
| macOS SDK / host | MacOSX26.1.sdk, Darwin 25.5.0, arm64 |
| iOS simulator | iOS 26.1 (23B86), device `iPhone 16-objc-impl-spike`, created and deleted by the run |
| Guest / Linux cross toolchain | not exercised: `@objc @implementation` needs Clang-imported ObjC classes and the ObjC runtime; the guest runs Apple's objc runtime with the same class-layout rule, so the Darwin result carries |

`@objc @implementation` is available in this toolchain without any feature
flag (it shipped in Swift 6.0). The whole probe is ordinary SwiftPM.

## (a) The probe: `uikit/Tools/objc_impl_spike/`

| target | role |
|---|---|
| `Sources/OUIProbeHeader/include/OUIProbeView.h` | `NS_SWIFT_UI_ACTOR @interface OUIProbeView : NSObject` shaped like UIView's core: `center`, `bounds`, `frame`, `superview` (readonly), `subviews` (readonly copy), `layoutCount`, `initWithFrame:` (designated), `init`, `addSubview:`, `removeFromSuperview`, `setNeedsLayout`, `layoutIfNeeded`, `layoutSubviews` |
| `Sources/OUIProbeImpl/OUIProbeView.swift` | `@objc @implementation extension OUIProbeView` implementing all of it, plus Swift-only stored state that is NOT in the header: a `[Struct]`, an enum with payloads, a closure, an optional `CGSize`, a `weak` back-reference |
| `Sources/OUIProbeImpl/OUIProbeView+Swift.swift` | a plain `extension OUIProbeView` in another file with a generic method, a closure-taking method, a tuple property; a Swift subclass `OUISwiftSubview` (non-final stored property + `layoutSubviews` override calling super); a vtable-free Swift subclass `OUISwiftFinalMid`; a Swift protocol adopted by a plain extension |
| `Sources/OUIProbeObjC/OUIProbeSubview.{h,m}` | `@interface OUIProbeSubview : OUIProbeView` overriding `initWithFrame:` and `layoutSubviews` (calls super); ObjC driver that allocates both classes from Objective-C |
| `Sources/OUIProbeObjC/OUIProbeLeaf.m` | chain probe: ObjC leaves under the two Swift subclasses, with the generated header's `objc_subclassing_restricted` lifted the way probe1 did |
| `Sources/OUIProbeMain/main.swift` | Swift driver, one `PASS`/`FAIL` line per check; `A`/`B` argument runs a chain probe in its own process |
| `run.sh` | reproduces everything below; `RUN_SIM=1` adds the simulator build and run |

### Results (identical on the macOS host and inside the iOS 26.1 simulator via `simctl spawn`)

| question | result |
|---|---|
| Does it compile? | Yes, after three shape corrections listed under "rules the compiler enforces". `swift build` clean; the simulator cross-build (`--triple arm64-apple-ios26.1-simulator`) produces an LC_BUILD_VERSION platform 7 binary. |
| ObjC allocates the ObjC subclass (`[[OUIProbeSubview alloc] initWithFrame:label:]`)? | Yes. `class=OUIProbeSubview super=OUIProbeView`, frame `{{10, 20}, {30, 40}}` after the designated-init chain `-[OUIProbeSubview initWithFrame:label:]` → `-[OUIProbeSubview initWithFrame:]` → Swift `init(frame:)` → `NSObject.init`. |
| ObjC allocates the base via the convenience `-init`? | Yes (`convenience override init()` in Swift delegating to `init(frame:)`). This is exactly the call that crashed in probe1. |
| Override / super chain at runtime? | Yes. Trace for a tree with an ObjC child and a Swift child: `OUIProbeView.layoutSubviews(base)`, `OUIProbeSubview.layoutSubviews(base)` (ObjC override called super), `OUISwiftSubview…(before super)`, `…(base)`, `…(after super)`. Counters: base 1 / ObjC 1 (+1 in the ObjC override) / Swift 1 (+1 in the Swift override). |
| Swift allocates the ObjC subclass and casts it? | Yes: `OUIProbeSubview(frame:label:)`, `is OUIProbeView`, `as? OUIProbeSubview` out of `[OUIProbeView]`, `NSClassFromString` returns the same class object from both sides. |
| Swift subclass of the `@implementation` class? | Yes: `OUISwiftSubview(frame:)`, override + super, ObjC sends `-layoutSubviews` to it through the runtime (`objc sees OUIProbeImpl.OUISwiftSubview (super OUIProbeView)`). |
| Swift-native conveniences on the same class? | Yes: generic `firstSubview(of:)`, closure-taking `animate(keyPath:from:to:completion:)`, tuple computed property, enum-with-payload state, all in a plain extension in another file. |
| Swift-only stored properties? | Yes, as long as they are `final` (or private). They become real ivars of the ObjC class: `class_copyIvarList` on `OUIProbeView` lists 10 ivars: `center, bounds, needsLayout, _superview, _subviews, _layoutCount, animations, tint, onLayout, lastLayoutSize`. `public final var` is accessible from other modules. |
| Swift protocol conformance added by a plain extension? | Yes: `extension OUIProbeView: OUIProbeLayoutHost {}` with requirements satisfied by header methods; a protocol-typed call reaches the ObjC subclass's override. |
| `@MainActor` isolation? | Yes via `NS_SWIFT_UI_ACTOR` on the `@interface`; the implementation extension is main-actor isolated like OpenUIKit's `@preconcurrency @MainActor` classes. |

18 of 18 runtime checks pass on the host; 19 of 19 with the conformance check
added; identical output inside the simulator.

### Rules the compiler enforces (each one measured, each one shapes (b))

| rule | diagnostic | consequence for OpenUIKit |
|---|---|---|
| A member not in the header must be `final`, `private` or `fileprivate`. | `instance method 'swiftOnlyOverridable()' does not match any instance method declared in the headers … add 'final' to define a Swift-only instance method that cannot be overridden` (same for properties; `open` is rejected the same way) | Every `open`/overridable member must be in an Objective-C header, so its types must be ObjC-representable. Internal override points (`_defaultBaseLayoutMargins`, `_constraintBaselines`, `_iosGlassPath`, `_firstResponderWindow`) must move to an internal category header. |
| A `readonly` header property is get-only even inside the implementation extension. | `cannot assign to property: 'superview' is a get-only property` (with `private(set) var`) | `public internal(set)` / `private(set)` stored properties split into a header `readonly` computed getter over a `final` Swift-only backing ivar. |
| A `weak` header property cannot be implemented by a computed getter. | `property 'superview' of type 'OUIProbeView?' does not match type 'OUIProbeView?' declared by the header` | Match UIKit's real header, which declares `superview` `readonly` without `weak`; keep the weak reference in the Swift backing ivar. |
| Exactly one `@objc @implementation extension` per class (one per header category). | `duplicate implementation of imported class 'OUIProbeView'` | UIView's 1,000-line class body stays one extension; Swift-only API can still spread over ordinary extensions in other files. |
| `-init` redeclared in the header is an override of NSObject's. | `overriding declaration requires an 'override' keyword` | `public convenience override init()`; no semantic change. |

### The chain rule (the measurement that sizes the first step)

An ObjC class under a **Swift** subclass of the implemented class: with the
generated header's restriction lifted (probe1's method; needs `-fno-modules`
so the predefined `SWIFT_CLASS` macro is honoured, which is why the ObjC
target carries that flag),

| chain | result |
|---|---|
| A: `OUIProbeLeafA : OUISwiftSubview : OUIProbeView`, where the Swift middle has one non-final stored property (two vtable entries) | **SIGSEGV pc=0**, exit 139, on host and simulator. Crash frame: `OUISwiftSubview.layoutSubviews() + 172` (the accessor for `swiftSubviewLayouts` dispatched through a Swift vtable slot the statically emitted ObjC class object does not have), called from `-[OUIProbeLeafA layoutSubviews]`. Same mechanism as probe1's `UIView.init()` crash, different slot. |
| B: `OUIProbeLeafB : OUISwiftFinalMid : OUIProbeView`, where the Swift middle has only ObjC-visible overrides and `final` Swift-only members | **Survives** on host and simulator: `leaf=OUIProbeLeafB super=OUIProbeImpl.OUISwiftFinalMid frame={{1, 1}, {2, 2}} layoutCount=1 leafLayouts=1 instanceSize(mid)=176 instanceSize(leaf)=184`. |

So for an Objective-C app class to subclass OpenUIKit class C, **every class
on the chain from `UIResponder` to C** must be either `@objc @implementation`
or vtable-free (no non-final Swift-only member, no non-`@objc` override
point). A chain with one ordinary `open class` in the middle crashes at the
first vtable dispatch, and nothing at compile time says so once the attribute
is lifted.

## (b) What `UIView` would have to give up or restructure

Source: `Sources/OpenUIKit/UIView.swift` lines 483–1475 (`open class UIView:
UIResponder, CALayerDelegate`, `@preconcurrency @MainActor`), the class body
only. 128 members plus 1 nested type (`AutoresizingMask`), counted by
extracting every top-level declaration in the body (127 regex hits, 3
initializers the regex does not match, minus the `#if canImport(Foundation)`
twin of `description`).

| bucket | count | what it means |
|---|---|---|
| **H**: goes into the public header as-is | **65** | Every type in the signature is already ObjC-representable (CGRect/CGPoint/CGSize/CGFloat/Bool/Int/String, `UIView`, `UIWindow`, `UIResponder`, `UIGestureRecognizer`, `NSCoder`, `AnyClass`, Int-backed enums). Includes the 3 initializers, the 4 `convert` methods, all hierarchy methods, all layout/constraint methods, all lifecycle override points, `layerClass`, `appearance()`, `next`, `description`, `endEditing` (already `@objc`), `draw(_:)`. |
| **S**: Swift-only, stays in the extension as `final` (or private) | **44** | Internal/private state and helpers never overridden by a subclass: `animations: [UIViewAnimation]`, `contentVersion`, `_layerCacheState`, the 4 `UILayoutPriority` fields, the 4 layout-guide references, the 4 `UIEdgeInsets` fields, `_traitRegistrations`, `_gestureRecognizers`, `_interactions`, `_pasteConfiguration`, `_managingViewController` (weak), `_toSuperview`, `_transformToRoot()` (tuple), `_autoresizeAxis`, the two `private static` appearance-proxy fields, the private subtree walkers, etc. Measured to work as ivars: struct arrays, enums with payloads, closures, optionals, weak. Change: add `final`. |
| **X**: must be restructured before it can be declared | **19** | Listed below. |

The 19 X members, grouped by the smallest restructuring that fixes them:

| restructuring | members | notes |
|---|---|---|
| X3 readonly-with-internal-setter split (mechanical, measured on the probe) | `superview`, `subviews` | header `readonly`, `final` backing ivar, 2 members |
| Enum needs an `Int` raw type + `@objc` (NS_ENUM in the header) | `contentMode` (`UIViewContentMode`), `overrideUserInterfaceStyle` (`UIUserInterfaceStyle`) | 2 members, 2 enum declarations move to the header; `UISemanticContentAttribute` and `UIUserInterfaceLayoutDirection` are already `Int` enums and only need the header declaration (their 4 members are counted in H) |
| A non-NSObject class becomes NSObject-derived (the class-ABI change pass 1 already made for `UIImage`) | `traitOverrides` (`UITraitOverrides`, final class), `point(inside:with:)` and `hitTest(_:with:)` (`UIEvent`, final class) | 3 members, 2 types |
| `UIColor` becomes NSObject-derived | `backgroundColor`, `tintColor` | 2 members. `UIColor` is `Hashable, @unchecked Sendable` and value-compared; as an NSObject subclass it needs `isEqual:`/`hash` overrides. Already on simplenote-launch3's list (it is the largest missing-selector receiver there). |
| `CGAffineTransform` becomes CoreGraphics' struct on Darwin | `transform` | 1 member. OpenCoreGraphics defines its own; the file header notes the collision. The fix is the alias OpenUIKit already uses for `CGRect`/`CGPoint`/`CGSize` (`import struct CoreGraphics.…`). |
| `CALayer` becomes NSObject-derived (or `@objc @implementation` itself) | `layer`, `layoutSublayers(of:)` | 2 members. `CALayer` is `open class CALayer` with an `isolated deinit`, 89 stored/computed members. Keeping `layer` Swift-only `final` compiles but hides `view.layer` from Objective-C, which no ObjC app tolerates. |
| `UITraitCollection` becomes an NSObject class (it is a mutable `struct` today) | `traitCollection`, `traitCollectionDidChange(_:)` | 2 members. Mutated in place at 2 sites in this file (`t.userInterfaceStyle = …`); UIKit's is an immutable class. |
| `Canvas` (OpenCoreGraphics, `public final class`) becomes NSObject-derived and `drawContent(in:bounds:)` moves to an internal category header with `NS_SWIFT_NAME(drawContent(in:bounds:))` | `drawContent(in:bounds:)` | 1 member, but **25 overrides** across OpenUIKit's subclasses; the Swift spelling is preserved by the swift name, so the overrides keep compiling. |
| Internal override points move to an internal category header (`@interface UIView (OpenUIKitInternal)`, implemented by a second `@objc(OpenUIKitInternal) @implementation extension`) and lose Swift-only types | `_defaultBaseLayoutMargins` (2 overrides; `UIEdgeInsets` as the C struct), `_constraintBaselines()` (1 override; returns a tuple → two CGFloat methods or a small `@objc` struct), `_iosGlassPath(in:)` (1 override; returns OpenCoreGraphics `Path` → the one override becomes data the base reads), `_firstResponderWindow` (4 overrides across UIResponder/UIView/UIViewController; `UIWindow?`, representable) | 4 members |

Type declarations that change kind for UIView alone: 12 (`UIColor`, `CALayer`,
`UITraitCollection`, `UIEvent`, `UITraitOverrides`, `Canvas`,
`CGAffineTransform`, `UIEdgeInsets` → C struct, `UIViewContentMode`,
`UIUserInterfaceStyle`, `AutoresizingMask` → NS_OPTIONS, plus NS_ENUM
declarations for the two Int enums).

Other things the task asked to count:

| item | count | verdict |
|---|---|---|
| `open` / `final` usage in the body | 32 `open` members, 0 `final` | Every `open` member is in H or X above; `open` becomes ordinary ObjC dynamic dispatch. The 44 S members gain `final`. |
| Designated-initializer chain | `init(frame:)` designated, `convenience init()`, `required init?(coder:)` | Measured shape (`init(frame:)` → `super.init()`; `convenience override init()`); `initWithCoder:` declared in the header keeps subclasses' `required init?(coder:)` overrides compiling if the header adopts `NSCoding`. |
| `extension UIView` in other files | 13 declarations in 11 files inside `Sources/OpenUIKit`; 18 in 16 files across `Sources/` | All stay as they are: measured, a plain extension in a separate file adds Swift-only API and a protocol conformance to the implemented class. Members in them are already non-overridable. Any of them an ObjC app must call (`layoutMargins`, `safeAreaInsets`, `layoutMarginsGuide`, animation class methods, …) needs a header declaration, which is the ObjC-surface question of simplenote-launch3, not a class-shape question. |
| Protocol conformances | 3: `CALayerDelegate` (declaration), `UICoordinateSpace`, `UIPasteConfigurationSupporting` (extensions) | Move to plain extensions; measured. `CALayerDelegate`'s requirement `layoutSublayers(of:)` is the CALayer-typed override point counted in X. |
| Subclasses of UIView inside `Sources/OpenUIKit` | **59 direct, 89 transitive** (201 transitive across all of `Sources/`, SwiftUI and probe apps included) | They keep compiling and running as Swift subclasses of an ObjC-declared class (measured: `OUISwiftSubview`, `override init(frame:)`, `override func layoutSubviews()` + super, overriding `bounds` with `didSet` is an ordinary override of an ObjC property). Overrides of the X members (25 `drawContent`, 1 each of `traitCollectionDidChange`, `traitCollection`, `tintColor`, `hitTest`) compile unchanged once the base signature keeps its Swift name. |
| `UIViewController` (lines 75–676, 82 members, counted by type only, not member by member) | ≈ 36 H / 19 S (+1 nested enum) / 26 X | X is dominated by protocol-typed and non-NSObject-typed API: `UILayoutSupport`, `UIContentContainer`, `UIViewControllerTransitionCoordinator`, `UIViewControllerTransitioningDelegate` (need `@objc protocol`), `UIPresentationController`/`UIPopoverPresentationController`, `UINavigationItem`, `UIBarButtonItem`, `UITabBarItem` (non-NSObject classes), `UITraitCollection` ×2, `UIModalPresentationStyle` (no raw type), `UIInterfaceOrientationMask`/`UIRectEdge` (NS_OPTIONS), `additionalSafeAreaInsets` (`UIEdgeInsets`), 5 `internal(set)`/`private(set)` splits, `_firstResponderWindow`. |
| `UIResponder` (29 members, 27 unique) | ≈ 17 H / 1 S / 9 X | X: 4 `touches*` (`Set<UITouch>`; `UITouch: Hashable` is not NSObject-derived, and `NSSet` needs it), 4 `presses*` (`UIPress`, `UIPressesEvent` non-NSObject), `_firstResponderWindow`. `keyCommands` depends on `UICommand: UIMenuElement`'s root. |

## (c) Comparison with option (1), ObjC-implemented classes

Option (1) is `ObjCFacade/include/UIKit.h`: 297 lines, 15 `@interface`s
(UIColor, UIResponder, UIView, UILabel, UIControl, UIButton, UIViewController,
UIApplication, UIWindow, UINavigationController, UIScrollView, UITableView,
UITableViewCell, UITextView, UITextField), 67 methods and 47 properties in
total, implemented in `UIKitFacade.m` over a C ABI into OpenUIKit
(`OpenUIKitABI.h`); simplenote-launch3 then added the Darwin-side
`OpenUIKitObjCSupport` (33 enums, 2 structs, 16 protocols, 23 constants) and
`OpenUIKitObjCBridge` (147 `@objc` selector twins over existing members).
Against the same counts: UIView alone has 65 header-ready members and 19
that need restructuring, so the facade's whole 114-member surface is smaller
than one class's H bucket. Extending (1) to "the whole surface the Swift
half uses too" means writing every one of those members twice (an ObjC
class and the Swift class behind it) and keeping two object graphs
consistent (the facade's `UIView` and OpenUIKit's are different classes,
which is the two-universe problem probe1 measured: Simplenote's Swift half
extends its ObjC classes 98 times and needs one universe). Option (2) writes
each member once, in Swift, in the class that already exists; its cost is
the 19 X restructurings per class plus the 12 type-kind changes, and the
chain rule forces it on whole inheritance chains rather than one class at a
time. Option (2) also preserves the 89 Swift subclasses and 18 extensions
unchanged, which (1) cannot do at all: under (1) the Swift subclasses would
subclass the facade's ObjC class and lose every non-`@objc` override point.
On the numbers, (2) is the smaller and the only single-universe option; the
147 bridge twins and the 33+16+23 support declarations from simplenote-
launch3 are reusable as the header content for (2).

## Recommendation and the smallest viable first step

Do option (2), but not "UIView + UIViewController only": the chain rule
(probe chain A) means an ObjC app class can only subclass a class whose
whole ancestor chain is implemented, and Simplenote's 18 subclassing classes
target 8 OpenUIKit classes on 5 chains (`UITextView → UIScrollView → UIView →
UIResponder`, `UITextField → UIControl → UIView`, `UITableViewCell → UIView`,
`UITableViewController → UIViewController → UIResponder`,
`UINavigationController → UIViewController`), so the smallest step that
unblocks Simplenote is **10 classes**: UIResponder, UIView, UIScrollView,
UIControl, UITextView, UITextField, UITableViewCell, UIViewController,
UITableViewController, UINavigationController, plus the 12 type-kind changes
above (UIColor, CALayer, UITraitCollection, UIEvent, UITraitOverrides,
Canvas, CGAffineTransform, UIEdgeInsets, 2 enums, 1 option set, NS_ENUM
declarations). The smallest step that *proves* the architecture on real
OpenUIKit is 3 classes on one chain, UIResponder + UIView + UIWindow (the
window is a UIView subclass every host path constructs), which exercises the
19 X restructurings, the 12 type changes, the 89 Swift subclasses and the
124/124 Catalyst gate, and would take one pass. Measured hazards to carry
into that pass: nothing at compile time catches a Swift class left in the
middle of a chain (chain A is a runtime SIGSEGV), so the gate should include
an ObjC subclass of every converted class; `-fno-modules` was needed only for
the restriction-lifting probe, not for the design; and the header must
declare `superview` the way UIKit does (readonly, not weak).
