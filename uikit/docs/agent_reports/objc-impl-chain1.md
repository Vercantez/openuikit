# `@objc @implementation` chain 1: UIResponder → UIView → UIWindow — stopped at a measured wall

**Date:** 2026-09-09  
**Branch:** `agent/objc-impl-chain1` (based on `agent/objc-impl-spike`)  
**Toolchain:** Xcode 26.1 (17B55), Swift 6.2.1 (swiftlang-6.2.1.4.8), MacOSX26.1.sdk, arm64; Linux check in `swift:6.2-noble`  
**Status:** **WALL at gate (1)** — the Darwin package build. Every remaining
error has one cause, reproduced in 30 s by
`Tools/objc_impl_chain1/required_init_probe/run.sh`. Gates (2)–(5) were not
run because (1) is red. The port itself is complete for the three classes
and compiles on Linux (the plain-Swift shape), so the branch is the starting
point for the follow-up, not a throwaway.

## The wall

**Rule (measured, Swift 6.2.1):** a Swift class *two or more levels* below an
`@objc @implementation` class whose header adopts `NSCoding` cannot declare a
designated initializer. Whatever it declares, the compiler reports

```
error: 'required' initializer 'init(coder:)' must be provided by subclass of 'UIView'
note:  'required' initializer is declared in superclass here   (UIView.h, initWithCoder:)
```

and, as a consequence, the class no longer inherits the convenience `init()`
(`UIButton()` → "missing argument for parameter 'frame'"). A *direct* Swift
subclass (`UILabel: UIView`) is fine. The chain `UIButton : UIControl : UIView`
is not, and neither is an app's `class Cell: UITableViewCell`.

What this costs on this tree (classes at depth ≥ 2 under `UIView` that
declare `init?(coder:)`, counted by walking `class X: Y` declarations):

| module | classes | examples |
|---|---|---|
| OpenUIKit | 23 | UIStepper, `_UIBarButtonItemView`, `_UITabBarItemView`, `_UIContextMenuCell` (22 of them error on the current build; the 23rd is inside a `#if`) |
| RealAppProbe (unchanged app source) | 9 | SettingsTableViewToggleCell, SmartLabel |
| Blockzilla / BlockzillaPackage | 13 | SubtitleCell, AutocompleteTextField, TooltipTableViewCell |
| ConformanceApps | 5 | LedgerTableCell, FeedCardCell |
| DemoApp / openhost | 12 | TaskCell, SceneCollectionCell |
| Eidolon | 2 | ListingsCollectionViewCell |
| SwiftUI | 1 | `_SwiftUISearchBar` |
| Tests | 17 | CountingItemCell, DatePickerFrameProbe |
| **total** | **82** | |

The OpenUIKit target after every other error was fixed (`swift build --target
OpenUIKit`, unique diagnostics): **42 errors = 22 required-initializer + 9
lost-convenience-initializer (`UIButton()`, `UITextField()`, …) + 11
type-inference cascades of those two in UISearchBar / UIAlertController**.
Nothing else.

Every shape that could dodge it was measured on the probe; none works:

| variant | result |
|---|---|
| grandchild under an intermediate with no initializers | ✗ same error |
| grandchild under an intermediate that redeclares both designated initializers | ✗ |
| grandchild under an intermediate spelled `required override init?(coder:)` | ✗ |
| grandchild spelled `required override init?(coder:)` | ✗ |
| grandchild in **another module** (an app's view class) | ✗ same error |
| grandchild with only convenience initializers | ✓ (no designated initializer, so no check) |
| header adopts NSCoding, implementation initializer **not** `required` | ✗ "initializer 'init(coder:)' should be 'required' to match initializer declared by the header" |
| header does **not** adopt NSCoding (`initWithCoder:` a plain designated initializer) | ✗ every subclass's `required init?(coder:)` (the spelling every app uses) becomes "overriding declaration requires an 'override' keyword" |
| `initWithCoder:` `NS_REFINED_FOR_SWIFT`, implementation matched by `@objc(initWithCoder:)` | ✗ same wall on the refined name |
| `initWithCoder:` `NS_SWIFT_UNAVAILABLE` | ✗ the implementation cannot match it |
| without `NS_SWIFT_UI_ACTOR` | ✗ |

Mechanism, as far as it can be inferred from the diagnostics: an initializer
implemented by the `@implementation` extension is a **second Swift
declaration next to the imported one** (the same thing makes `UIApplication()`
"ambiguous use of 'init()'" when `-init` is redeclared in UIResponder.h). A
direct subclass's `init?(coder:)` overrides one of the two; the other, still
`required`, is what the grandchild is told to provide. Real UIKit has only the
imported declaration, which is why 3-deep Swift chains under real UIView work.
No public issue describing this was found; it is filed here as the measured
fact. Whether a newer toolchain fixes it is the first thing the follow-up
should check (the repro package is self-contained).

Because `initWithCoder:` + `NSCoding` is the only shape under which unchanged
app source (`required init?(coder:)`, `super.init(coder:)`) compiles against
a direct subclass, and that same shape breaks every grandchild, **the first
chain cannot be converted on Swift 6.2.1 without changing app sources**,
which the gates forbid. This is the wall; the rest of this report records what
was built so the follow-up does not re-derive it.

## Compiler rules measured beyond the spike (each shaped the port)

| rule | diagnostic / observation |
|---|---|
| A header type can only be a Foundation/CoreGraphics type or a class declared in an Objective-C header. A forward-declared `@class UIColor` does **not** unify with the Swift class of that name: the member is treated as absent from the header. | `property 'tintColor' does not match any property declared in the headers` |
| Initializers not declared in the header are rejected unless `private` / `fileprivate`. | `initializer 'init(label:)' does not match any initializer declared in the headers` (private ones compile) |
| Members are matched by **selector**, not Swift name: `NS_SWIFT_NAME` fixes the client-side name, the implementation needs `@objc(selector)` when the default selector differs. | `selector 'isHidden' for property 'isHidden' not found in header; did you mean 'hidden'?` — same for `insertSubview:atIndex:`, `isDescendantOfView:`, `drawRect:`, `nextResponder`, and the four `convertPoint:/convertRect:` overloads |
| Explicit `open` / `public` on header members is accepted (needed by the shell generator). | no diagnostic |
| Overrides of inherited non-header members (`description`, `isEqual`) are accepted; a non-header override of `init()` is not, and redeclaring `-init` makes every subclass call ambiguous. | `ambiguous use of 'init()'` on `UIApplication()`; fixed by not redeclaring `-init` and giving UIApplication an explicit `override init()` |
| A `weak` computed property is invalid, so a header-readonly / Swift-typed weak property is a `final weak var _x` ivar plus a non-weak computed accessor. | |
| `@objc open` members in a **plain** extension of the implemented class are overridable by Swift *and* Objective-C subclasses, with `super` chains intact, and the generated `OpenUIKit-Swift.h` exports them as a category. | measured on the spike probe (ObjC leaf overriding `tintColor`, `touchesBegan:withEvent:`, a bridged struct property, a category C-struct property; trace of every `super` call) |
| A Swift struct conforming to `_ObjectiveCBridgeable` is legal in an `@objc open` signature (property and optional parameter) and round-trips; Objective-C sees the box class. | `traitCollection` / `traitCollectionDidChange:` on the probe |
| An override of a category-header member (`_firstResponderWindow`) must be **public**. | `overriding property must be as accessible as the declaration it overrides` |
| Importing the header module with SwiftPM's default `export *` module map makes CoreGraphics' `CGAffineTransform` / `CGColor` visible in every OpenUIKit file → ambiguous with OpenCoreGraphics' own. | 1,500+ `'CGColor' is ambiguous for type lookup` lines; fixed by a hand-written `module.modulemap` without `export *` |
| Swift's `#if` cannot split a declaration's braces, so `#if X @objc @implementation extension UIView { #else open class UIView { #endif` is not Swift. | `expected '}' in class` — see "the two shapes" |
| Corelibs Foundation's NSObject has no overridable KVC; the guest's `ObjectiveC.NSObject` has none. | Linux: `method does not override any method from its superclass` on CALayer's `setValue(_:forKey:)` — gated on `canImport(ObjectiveC) && canImport(Foundation)` |

## What was built

### Layout

| piece | where |
|---|---|
| Objective-C declarations: `UIResponder.h`, `UIView.h`, `UIWindow.h`, `UIGeometry.h` (`UIEdgeInsets` C struct), `OpenUIKitInternal.h` (categories for the internal override points), umbrella + non-exporting `module.modulemap` | `Sources/OpenUIKitObjC/` (Clang target, Darwin only, `#if !os(Linux)` in the manifest) |
| Route switch: `OPENUIKIT_OBJC_IMPLEMENTATION` (`.define`, not an unsafe flag) on OpenUIKit and OpenCoreGraphics for the Darwin platforms; the Clang target is a conditional dependency | `Package.swift` |
| `@_exported import OpenUIKitObjC`, the `UITraitCollection` bridge (`_ObjectiveCBridgeable`, box class named `UITraitCollection` for Objective-C), `UIEdgeInsets` extensions (`.zero`, Equatable, defaulted init) | `Sources/OpenUIKit/ObjCImplementation.swift` |
| The three implementations (each: main `@objc @implementation extension`, an `@objc(OpenUIKitInternal) @implementation extension` for the category, a plain extension of `@objc open` members) | `UIResponder.swift`, `UIView.swift`, `UIEvent.swift` |
| Generator/checker for the plain-Swift shape | `scripts/objc_impl_shell_check.py` |
| Chain-rule gate: Objective-C subclasses of UIView and UIWindow (init, override header members and plain-extension members, super), XCTest + a `simctl spawn`-able driver | `Tests/OpenUIKitObjCSubclassProbe/`, `Tests/OpenUIKitObjCSubclassTests/`, `Tools/objc_impl_chain1/objcsubclassprobe/` (written; not exercised — gate (1)) |
| Wall reproduction | `Tools/objc_impl_chain1/required_init_probe/` |

### The two shapes, and why one is generated

Swift's `#if` cannot wrap a declaration head, so the plain-Swift class body
(native Linux and the Foundation-hidden guest route, which is a raw `swiftc`
invocation that never sees the manifest) has to be a second copy of the same
members. `scripts/objc_impl_shell_check.py` **derives** it from the Darwin
block (merges the three containers into one `open class` body, drops
`@objc(...)` attributes, keeps only the `#elseif`/`#else` branches of nested
`#if OPENUIKIT_OBJC_IMPLEMENTATION` member blocks) and compares bytes; `--fix`
rewrites it. The derived block is committed (the guest route compiles files
without running scripts). Measured: the derived shape builds on Linux —
`swift build --target OpenUIKit` in `swift:6.2-noble`, 0 errors.

Directive per class: `// objc-impl-shell: open class UIView: UIResponder`.

### What moved to the header, and the final/private split

| class | header (`.h`) | plain-extension `@objc open`/`public` (Swift-typed) | `final` / `static` Swift-only | `private` |
|---|---|---|---|---|
| UIResponder | 6 properties + 6 methods (+1 category property `_firstResponderWindow`) | 10: `inputAssistantItem`, `keyCommands`, 4 `touches*`, 4 `presses*` | 3 (`_accessibility`, `_resolvedInputAssistantItem`, `_responderChain`) | 1 |
| UIView | 18 properties + 32 methods + 3 initializers, `<NSCoding>` (+1 category property `_defaultBaseLayoutMargins`) | 16: `layer`, `backgroundColor`, `tintColor`, `traitCollection`, `traitCollectionDidChange`, `semanticContentAttribute`, `effectiveUserInterfaceLayoutDirection`, 2× `userInterfaceLayoutDirection(for:)`, `layoutSublayers(of:)`, `point(inside:with:)`, `hitTest`, `gestureRecognizers`, `add/removeGestureRecognizer`, `drawContent(in:bounds:)` | 60 (every S-bucket member of the spike plus the backing ivars `_superview`, `_subviews`, `_layerStorage`, `_backgroundColor`, `_tintColor`; `transform`, `contentMode`, `autoresizingMask`, `overrideUserInterfaceStyle`, `traitOverrides`, `_usesIOSGlass`, `_openUIKitBrightness/Saturation` stay public but `final`) | 6 |
| UIWindow | 2 properties + 3 methods + 2 initializers | 5: `traitCollection` override, `windowScene`, `rootViewController`, `init(windowScene:)` (now a convenience initializer), `sendEvent(_:)` | 18 (`windowLevel`, `sendTouch`, `sendHover`, the touch bookkeeping, `_firstResponder`, `_windowScene`, `_rootViewController`, …) | 0 |

The spike's 19 X restructurings, as done here:

| X item | what happened |
|---|---|
| `superview`, `subviews` (readonly split) | header readonly; `final weak var _superview`, `final var _subviews`; the 0 external mutation sites needed no change (all in UIView.swift) |
| `UIViewContentMode`, `UIUserInterfaceStyle` (no raw type) | left Swift-only `final` (`contentMode`, `overrideUserInterfaceStyle` are `public var`, not `open`) — **follow-up**: NS_ENUM |
| `UITraitOverrides` | `final` (public var) |
| `UIEvent` in `point(inside:)` / `hitTest` | UIEvent, UITouch, UIPress, UIPressesEvent derive from NSObject on every route; the members are `@objc open` in the plain extension with UIKit's selectors |
| `UIColor` in `backgroundColor` / `tintColor` | UIColor derives from NSObject on every route (`isEqual:`/`hash` replace the static `==`); members `@objc open` |
| `CGAffineTransform` (`transform`) | `public final var` (OpenCoreGraphics' struct stays); **follow-up** for Objective-C |
| `CALayer` (`layer`, `layoutSublayers(of:)`) | CALayer derives from NSObject on every route (KVC members become overrides where Foundation has them); `layer` is `@objc public` over `final lazy var _layerStorage` |
| `UITraitCollection` (`traitCollection`, `traitCollectionDidChange`) | **not** converted to a class: bridged (`_ObjectiveCBridgeable`), 486 struct uses untouched; **follow-up**: the class conversion, if Objective-C needs to read traits |
| `Canvas` (`drawContent`) | Canvas derives from NSObject on every route; `drawContent` is `@objc(drawContentIn:bounds:) open`; the 35 overrides compile unchanged |
| `_defaultBaseLayoutMargins` | category header with `UIEdgeInsets` as the C struct from `UIGeometry.h` (on Darwin that C struct **is** `OpenUIKit.UIEdgeInsets`; the support header's copy was replaced by an `#import`); the two overrides became `public override` |
| `_constraintBaselines()` (tuple) | `final`, reads `_UIConstraintBaselineProviding` (UILabel adopts it) — a conformance replaces the override |
| `_iosGlassPath(in:)` (`Path`) | `final`, reads `_UIGlassPathProviding` (`_UIPageSheetView` adopts it) |
| `_firstResponderWindow` | category header (`OpenUIKitInternal.h`); the four overrides are `public override` |
| `UISemanticContentAttribute`, `UIUserInterfaceLayoutDirection` | `@objc` enums on the Darwin route (the support header's duplicate NS_ENUM removed) |
| `init(windowScene:)` (UIWindowScene is a Swift class) | a **convenience** initializer in the plain extension; strictly more inheritable than the designated one it replaces; 0 overrides |
| `UIView.description` | override inside the implementation extension (allowed) |

Other things the port touched: the `OpenUIKitObjCBridge` `@objc(selector)` twins for members the header now declares were removed (they would be duplicate selectors; `autoresizingMask` and `safeAreaInsets` remain); `OpenUIKitObjCSupport` depends on the declaration target for `UIEdgeInsets`.

### What differs on Linux / the guest route

- No `OpenUIKitObjC` target, no flag: the generated `#else` block is an ordinary `open class` with the same member list; `_firstResponderWindow` and `_defaultBaseLayoutMargins` are `public` there too (the override rule).
- `UIEdgeInsets` stays the Swift struct.
- The `@objc` enum attributes, the `UITraitCollection` bridge and `encode(with:)`'s selector attribute exist only on the Darwin route; `UIView.encode(with:)` itself exists on every route (UIVisualEffectView's is now `override`).
- UITouch / UIEvent / UIPress / UIPressesEvent / UIColor / CALayer / Canvas are NSObject subclasses on every route (corelibs `NSObject` on Linux, `ObjectiveC.NSObject` on the guest); CALayer's KVC overrides only where Apple's Foundation is present.

## Gates

| gate | result |
|---|---|
| (1) `swift build` (Darwin) | **RED — the wall.** `--target OpenUIKit`: 42 unique errors, all one cause (22 + 9 + 11 above). Before the port, `swift build --build-tests` of the base commit: clean in 41 s. |
| (1′) Linux `swift build --target OpenUIKit` in `swift:6.2-noble` | green, 0 errors (verifies the generated shells) |
| (2) unit tests (Responder / View / Window / Layout / Hit-testing / SafeArea) | not run: blocked by (1). Planned filter: `OpenUIKitTests.(ResponderLifecycleTests|ViewGeometryTests|GeometryTests|EventSystemTests|AutoLayoutTests|SafeAreaGuideTests|TraitCollectionTests|ViewControllerLayoutTests|LayoutTieBreakTests|UIViewCoderCompatibilityTests)` |
| (3) Objective-C subclass test | written (`Tests/OpenUIKitObjCSubclassTests`, 22 runtime checks + a driver for `simctl spawn`); not run: blocked by (1). The same checks passed on the spike-shaped probe (see rules above). |
| (4) Catalyst 124/124, iOS 112/113 | not run: blocked by (1) |
| (5) `CHECK_ONLY=1 scripts/agent_merge.sh agent/objc-impl-chain1` | not run: blocked by (1); the branch touches only `uikit/` and no pin files |

## Follow-ups

1. **The wall.** Check the repro on a newer toolchain; if it persists, the first-chain step needs a different initializer story (e.g. `initWithCoder:` implemented in an Objective-C `.m` half of the class so that only the imported declaration exists in Swift — SE-0436 allows a class to have its main `@implementation` in either language, but then the stored properties cannot live in the Swift extension; not attempted).
2. NS_ENUM for `UIViewContentMode`, `UIUserInterfaceStyle`; NS_OPTIONS for `UIView.AutoresizingMask`; CoreGraphics' `CGAffineTransform` on Darwin (`transform` is Swift-only).
3. `UITraitCollection` as a class (the bridge box has no members Objective-C can read).
4. Objective-C exposure of `layoutMargins`, `safeAreaInsets`, the animation class methods (all in extensions — the ObjC-surface question of simplenote-launch3).
5. The generator is not in `agent_merge.sh`; running `scripts/objc_impl_shell_check.py` on the three files is a 1-second gate worth adding.

## Reproducing

```
# the wall, 30 s
zsh uikit/Tools/objc_impl_chain1/required_init_probe/run.sh
# the port's Darwin build (expect the 42 errors above)
cd uikit && swift build --target OpenUIKit
# the generated plain-Swift shells are in sync
python3 scripts/objc_impl_shell_check.py Sources/OpenUIKit/UIResponder.swift Sources/OpenUIKit/UIView.swift Sources/OpenUIKit/UIEvent.swift
# Linux
docker run --rm -v "$PWD":/src:ro swift:6.2-noble bash -c 'cp -r /src /work && cd /work && rm -f Package.resolved && swift build --target OpenUIKit'
```
