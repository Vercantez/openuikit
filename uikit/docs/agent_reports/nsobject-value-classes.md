# The UIKit value classes Apple derives from NSObject, and the accessibility surface Apple puts on NSObject

**Date:** 2026-09-10. **Branch:** `agent/nsobject-value-classes`, base `c8bed283` (origin/main at branch time).
**SDK read:** `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk`.
**Oracle:** iPhone 16 / iOS 26.1 (23B86), private device `OpenUIKit-NSObjectValue-nsobject-value-classes` (created and deleted; 0 devices match afterwards). Probe `Tools/oracle2/nsobjectvalueprobe`, runner `scripts/nsobject_value_probe_sim.sh`, transcript committed as [nsobject-value-classes-oracle-ios26.1.json](nsobject-value-classes-oracle-ios26.1.json).
**Result:** the wall named in [ios-oss-launch.md](ios-oss-launch.md) is gone. **ReactiveExtensions 12 → 0 (target passes)**; **Prelude_UIKit 49 → 20**, with every hierarchy diagnostic and every one of the six named types absent from what remains. **KsApi**, which had never reached semantic checking, now compiles its 325 files.

## (1) What Apple declares

Straight out of the headers in the SDK named above. Line numbers are that file's.

| type | declaration | file:line |
|---|---|---|
| `CALayer` | `@interface CALayer : NSObject <NSSecureCoding, CAMediaTiming>` | `QuartzCore.framework/Headers/CALayer.h:117` |
| `UIBarItem` | `NS_SWIFT_UI_ACTOR @interface UIBarItem : NSObject <NSCoding, UIAppearance>` | `UIKit.framework/Headers/UIBarItem.h:19` |
| `UIBarButtonItem` | `@interface UIBarButtonItem : UIBarItem <NSCoding>` | `UIKit.framework/Headers/UIBarButtonItem.h:69` |
| `UITabBarItem` | `@interface UITabBarItem : UIBarItem` | `UIKit.framework/Headers/UITabBarItem.h:35` |
| `UINavigationItem` | `@interface UINavigationItem : NSObject <NSCoding>` | `UIKit.framework/Headers/UINavigationItem.h:91` |
| `NSParagraphStyle` | `@interface NSParagraphStyle : NSObject <NSCopying, NSMutableCopying, NSSecureCoding>` | `UIKit.framework/Headers/NSParagraphStyle.h:69` |
| `NSMutableParagraphStyle` | `@interface NSMutableParagraphStyle : NSParagraphStyle` | `UIKit.framework/Headers/NSParagraphStyle.h:113` |

`UIBarItem`'s own members (UIBarItem.h:24-40): `enabled` (default YES), `title`, `image`, `landscapeImagePhone`, `largeContentSizeImage`, `imageInsets`, `landscapeImagePhoneInsets`, `largeContentSizeImageInsets`, `tag` (default 0), `-setTitleTextAttributes:forState:`, `-titleTextAttributesForState:`.

**Accessibility.** `UIAccessibility.h:44` opens `@interface NSObject (UIAccessibility)`, and the members ReactiveExtensions touches are all in it: `isAccessibilityElement` (:52), `accessibilityLabel` (:64), `accessibilityHint` (:79), `accessibilityValue` (:95), `accessibilityTraits` (:113), `accessibilityElementsHidden` (:160), `accessibilityViewIsModal` (:167), `shouldGroupAccessibilityChildren` (:174), `accessibilityNavigationStyle` (:182). `UIAccessibilityContainer.h:31` adds a second category with `accessibilityElements` (:53).

**`accessibilityIdentifier` is NOT on NSObject.** `UIAccessibilityIdentification.h:19` declares `@protocol UIAccessibilityIdentification <NSObject>` with that one property, and :30-39 adopt it on exactly four types: `UIView`, `UIBarItem`, `UIAlertAction`, `UIMenuElement`. This is the one row where the port keeps a deliberate divergence — see §4.

## (2) What the oracle measured

The headers give declarations; the probe gives behaviour. It walks each class's runtime superclass chain with `class_getSuperclass`, asks `class_conformsToProtocol` about eight protocols, reads every informal property on a bare `NSObject()`, reads `UIBarItem`'s defaults through both concrete subclasses, exercises the per-state / per-metrics appearance surface, and exercises `NSParagraphStyle`'s equality, hash and copy semantics. Every row below is a line of the committed transcript.

| measured | value |
|---|---|
| chains | `CALayer → NSObject`; `UIBarButtonItem → UIBarItem → NSObject`; `UITabBarItem → UIBarItem → NSObject`; `UINavigationItem → NSObject`; `NSMutableParagraphStyle → NSParagraphStyle → NSObject` |
| conformances | CALayer: NSCoding, NSSecureCoding, CAMediaTiming (not NSCopying). UIBarItem / UIBarButtonItem / UITabBarItem: NSCoding + **UIAppearance**. UINavigationItem: NSCoding only. Both paragraph styles: NSCoding, NSSecureCoding, NSCopying, NSMutableCopying |
| bare `NSObject()` | `isAccessibilityElement` false; label / hint / value nil; traits 0; `elementsHidden` false; `viewIsModal` false; `shouldGroupAccessibilityChildren` false; `navigationStyle` 0; `accessibilityElements` nil |
| non-view NSObjects | a `UIBarButtonItem`, a `UINavigationItem`, a `CALayer` and an `NSMutableParagraphStyle` all read back what was written to their accessibility properties |
| `UIBarItem` defaults, via both subclasses | `isEnabled` true, `title` nil, image / landscape / large-content images nil, all three inset pairs zero, `tag` 0, `titleTextAttributes(for: .normal)` nil, `accessibilityIdentifier` nil |
| `UITabBarItem(title:image:tag:)` | title and tag land on the inherited storage (`"Home"`, 3); `selectedImage` nil; `titlePositionAdjustment` (0, 0) |
| `UIBarButtonItem` appearance | every getter nil / zero on a fresh item; a 2×2 image set for `(.normal, .default)` reads back at that key and is **nil** for `(.normal, .compact)`; the title adjustment reads (3, −4) for `.default` and (0, 0) for `.compact` |
| `CALayer` defaults | `shouldRasterize` false, `rasterizationScale` 1, `masksToBounds` false, `borderWidth` 0, `cornerRadius` 0, `shadowOpacity` 0, `shadowRadius` 3, `shadowOffset` (0, −3), `borderColor` and `shadowColor` non-nil |
| `NSParagraphStyle` semantics | `mutableCopy()` is an `NSMutableParagraphStyle`, `copy()` an `NSParagraphStyle`; equal-valued styles are `isEqual` and not identical; hashes agree; **a `Set` of the two has one element**; after mutating one they differ and the `Set` has two |

That last row is the one that decides how equality has to be written after the re-parent — see §3.

Two rows are **not** evidence: `UIAccessibilityIdentification` came back false for every class including `UIView`, because `NSProtocolFromString("UIAccessibilityIdentification")` did not resolve a live protocol object in the probe process. The header adoption at UIAccessibilityIdentification.h:30-39 stands; the runtime row is simply unmeasured.

## (3) What changed in the port

**Accessibility onto NSObject** (`Sources/OpenUIKit/NSObjectAccessibility.swift`, new). The eleven informal properties plus `accessibilityElements` and the custom-action / custom-rotor pairs moved off `extension UIResponder` (UIViewCompat.swift) and off UIResponder's stored `_accessibility`.

They are **not** a plain `extension NSObject`. That shape compiles the ReactiveExtensions call site but breaks the other half: a Swift extension member is not overridable, and a subclass that redeclares one is rejected outright —

```
UIResponder.swift:311: error: non-'@objc' property 'accessibilityValue' is declared in
                       extension of 'NSObject' and cannot be overridden
```

— which would have cost `UIResponder.accessibilityValue` its `open` status. Blockzilla's unmodified `AutocompleteTextField.swift:51` writes `public override var accessibilityValue`. UIKit gets both because its version is an Objective-C category, i.e. dynamically dispatched; `@objc` is not available on Linux at all, and on the Foundation-hidden guest a `String?` property is not `@objc`-representable, so that escape is closed on the two substrates that matter.

The surface is therefore a protocol with default implementations that NSObject conforms to (`UIAccessibilityInformalProtocol`). A generic constrained to `Object: NSObject` resolves the members through that conformance, and a class in the port may still declare one in its own body — which shadows a protocol default rather than overriding a superclass member. Both halves work on every substrate, with no `#if`.

**Storage.** OpenUIKit cannot add stored properties to Foundation's NSObject, so `_UIAccessibilityStorage` is a side table keyed by `ObjectIdentifier`. `ObjectIdentifier` is the object's address, so a naive table hands a fresh object a dead one's label as soon as an allocation reuses an address; every entry therefore carries a `weak` owner, and a lookup whose owner is nil or is a different object reads as absent. Writes sweep dead entries every 256 writes so the table cannot grow without bound. Not synchronized — the same standing single-thread assumption as `UIApplication._preferredContentSizeCategory`.

**Re-parenting.** `CALayer`, `UINavigationItem` and `NSParagraphStyle` now derive from NSObject; a new `UIBarItem` (`Sources/OpenUIKit/UIBarItem.swift`) derives from NSObject and carries the members the header lists, and `UIBarButtonItem` and `UITabBarItem` derive from it. The relayout notifications stay exactly where they were: `UITabBarItem` overrides `title` to keep its `setNeedsLayout`, `UIBarButtonItem` keeps having none, so **the re-parent moves no pixels by construction**.

**Members added**, each one a requirement of a Kickstarter-Prelude lens protocol and each storage-only (nothing in the renderer reads them, recorded in `docs/KNOWN_GAPS.md`): `CALayer.shouldRasterize` / `rasterizationScale`; `UIBarButtonItem.possibleTitles` and its fourteen per-state / per-metrics appearance accessors; `UITabBarItem.selectedImage` / `titlePositionAdjustment`; and on `UIBarItem` the three image variants, the three inset pairs and the title-text-attribute pair.

**Two consequences of the re-parent, both resolved toward Apple.**

*Equality.* `NSParagraphStyle` used to declare `Hashable` with a Swift `==` / `hash(into:)` pair. With NSObject supplying the conformance, those two would have been **ignored** by `Set` and `Dictionary`, which consult the superclass's witnesses — and the oracle says two equal-valued styles must collapse to one element. The value comparison is now spelled as overrides of `isEqual(_:)` and `hash`, the shape `UIVisualEffect.swift:252` already uses; `==` is kept as an overload so statically typed comparisons read as before.

*Copying.* `mutableCopy()` was declared `-> NSMutableParagraphStyle`, which cannot stand next to NSObject's own `mutableCopy()`. It now has Apple's signature (`-> Any`, via `NSCopying` / `NSMutableCopying` conformance and `copy(with:)` / `mutableCopy(with:)`), so `style.mutableCopy() as! NSMutableParagraphStyle` — what real app source writes — is the spelling; the typed helper the port's own callers use is `mutableParagraphStyleCopy()`. One test line changed to Apple's spelling.

*KVC.* `CALayer`'s four bounded key-value compatibility entry points now collide with NSObject's real KVC. On Darwin they are `override`s (without that, `layer.setValue(_:forKey:)` from an app's visual-effect code would reach Objective-C KVC and raise `undefined key`, because these are Swift stored properties); on native Linux corelibs declares KVC in an `extension NSObject`, which Swift will not let a subclass override, and the Mach-O guest's root class has no KVC at all, so both declare them fresh. Keyed on `canImport(ObjectiveC) && canImport(Foundation)`, the same fail-closed shape as `awakeFromNib`.

## (4) Divergences, stated

- **Dispatch.** UIKit's category members are dynamic; the port's protocol defaults are statically dispatched. An app's `override` of `accessibilityValue` is seen through the declaring class's static type but **not** through a call site whose static type is only `NSObject`. There is no third option in Swift without the Objective-C runtime.
- **`UIAccessibilityInformalProtocol` has no UIKit counterpart.** It is additive; no app source names it.
- **`accessibilityIdentifier`.** Apple puts it on the `UIAccessibilityIdentification` protocol adopted by four types. The port declares the protocol and adopts it on `UIView` and `UIBarItem`, but keeps the member itself on `UIResponder` so a view controller can carry one, which several real apps set.
- **Conformances not adopted:** `NSCoding` / `NSSecureCoding` on all six types, `UIAppearance` on the bar items, `CAMediaTiming` on `CALayer`. The port has no archiver for any of them and no appearance proxy; adopting them would mean writing unmeasured stubs.
- **Storage-only members** are listed in §3 and in `docs/KNOWN_GAPS.md`. They round-trip faithfully and change no pixel.
- **`UITab`** is an NSObject subclass in UIKit and is still a plain Swift class here, with its own three accessibility properties. Out of the named scope; not touched.

## (5) Census, before and after

Reproduced exactly as `ios-oss-launch.md` documents it, on the same machine, corpus and checkouts, with only the port differing. Corpus `/Users/miguelsalinas/openuikit/scratch/ladder-corpus/ios-oss` at `2f2dabb40b74dd1e7a7511a0dedb47d967ab08a0` (verified, read-only, `git status` clean); SwiftPM checkouts (41 packages) from the session scratchpad; spec `docs/agent_reports/ios-oss-launch-chain.json`, unmodified.

```sh
python3 Tools/ingest/spm_app_chain.py docs/agent_reports/ios-oss-launch-chain.json \
  --out $SCRATCH/chain-{before,after} \
  --corpus ~/openuikit/scratch/ladder-corpus/ios-oss \
  --checkouts $SCRATCH/spm/checkouts --openuikit <port worktree>
python3 Tools/ingest/chain_census.py docs/agent_reports/ios-oss-launch-chain.json \
  --package $SCRATCH/chain-{before,after} --out … --only ReactiveExtensions Prelude_UIKit \
  --continue --timeout 540 --jobs 4
```

"Before" is a detached worktree at `c8bed283`, this branch's own base — not the 2026-09-09 report's base, so the two columns differ by these commits and nothing else.

| target | before (`c8bed283`) | after (this branch) |
|---|---|---|
| **ReactiveExtensions** | **failed, 12 own errors**, 1 file | **passed, 0 errors** |
| **Prelude_UIKit** | **failed, 49 own errors**, 23 files | **failed, 20 own errors**, 14 files |
| KsApi | blocked by dependency, never semantically checked | reaches semantic checking (below) |

The 12 ReactiveExtensions rows were all one message shape — `reference to member 'accessibilityElementsHidden' / 'accessibilityHint' / 'accessibilityLabel' / 'accessibilityTraits' / 'accessibilityValue' cannot be resolved without a contextual type`, two sites each — and all 12 are gone.

Prelude_UIKit's top rows before were `type 'CALayer' has no member 'lens'` (9), `cannot declare conformance to 'NSObjectProtocol' in Swift` (5), `cannot find type 'UIBarItem' in scope` (2), `value of type 'Object' has no member 'accessibilityElements'` (2). **All of those are gone, and none of the six types in scope appears in the remaining 20.** What is left is a different family entirely — other types' lens protocols and a drawing surface:

| remaining Prelude_UIKit row | count |
|---|---|
| `UIButton` does not conform to `UIButtonProtocol` (`adjustsImageWhenHighlighted`, `adjustsImageWhenDisabled`, `setBackgroundImage(_:for:)`, `backgroundImage(for:)`) | 2 |
| `UIControl` (`allTargets`, `actions(forTarget:forControlEvent:)`) | 1 |
| `UILabel` / `UITextField` / `UITextView` — the port's `font` is `UIFont` and `textColor` `UIColor` where the protocol requires `UIFont?` / `UIColor?` | 4 |
| `UITextView` does not conform to `UITextInputTraitsProtocol` (`isSecureTextEntry`) | 1 |
| `UIScrollView` (`scrollIndicatorInsets`), `UIStackView` (`isBaselineRelativeArrangement`), `UITabBar` (`barTintColor`), `UIProgressView` (`progressViewStyle`), `UIActivityIndicatorView` (`style`, `color`; candidate not settable), `UITableViewController` (`tableView` not settable) | 6 |
| `UINavigationController.viewControllers` setter must be `public` | 1 |
| `UIImage.swift` / `UIButton.swift` drawing: `UIGraphicsBeginImageContext`, `Canvas.setFillColor`, `.pixel`, a `CGRect` vs `Path` argument, a missing `color` parameter | 5 |

**KsApi.** Before, it was "blocked by dependency, 12 dep errors, its own files never reach semantic checking". After, it compiles and stops on **one** row: `no such module 'MobileCoreServices'`. That is a spec omission, not a port gap — the port ships a `MobileCoreServices` product (`Package.swift:298`) that the chain spec does not list among KsApi's `openuikit` products. Confirmed by re-running the census against a scratch copy of the spec with that product added (the committed spec was not modified): KsApi then compiles its 325 files and reports **22** rows, **19** of which are `cannot find 'Secrets' in scope` — the generated file `ios-oss-launch.md` records as absent from the clone. The genuinely new KsApi surface is three rows: `UIDevice.identifierForVendor`, one Prelude `.~` operator inference, one `.template` contextual base.

## (6) Tests

`Tests/OpenUIKitTests/NSObjectValueClassTests.swift`, 22 tests, every expectation a header line or a transcript line. They cover the four class chains, the bare-`NSObject` defaults, per-object independence, non-view UIKit objects, the one-object-one-state property (a `UIView` and the same object typed as `NSObject` must never disagree), the lifetime guard (2,000 short-lived objects, none of which may inherit a predecessor's label, and no ownerless entry may survive a sweep), `UIBarItem`'s defaults through both subclasses, both initializer families filling inherited storage, the title-text-attribute pair, the appearance defaults and round-trip, `CALayer`'s lens members and its KVC surface, and the paragraph-style copy / equality / `Set` semantics.

Two of them are the **compile fixtures** for the wall, in the app's own shapes: a generic function constrained to `Object: NSObject` that writes six accessibility members (ReactiveExtensions), and `_PreludeKSObjectShape`, a class-bound protocol rooted at `NSObjectProtocol` with the nine accessibility requirements Prelude's `KSObjectProtocol` lists, conformed retroactively by `UIView`, `CALayer`, `UIBarItem` and `UINavigationItem`. Neither compiles on `c8bed283`; the failing-first evidence for this change is that the file does not build at all before it, which is the same thing the census reports at scale.

| run | result |
|---|---|
| `swift test --filter NSObjectValueClassTests` | **22/22** |
| `--filter 'NSObjectValueClassTests\|BarButtonItemTests\|BarButtonActionTests\|NavigationItemTests\|TabBarControllerTests\|TabBarControllerDelegateTests\|LayerBridgeTests\|LayerCacheTests\|LayerContextCompatibilityTests\|AttributedStringTests\|AttrtextParagraphProbeTests\|DynamicTypeTests\|IosOssLaunchMembersTests\|ToolbarHeightTests\|NavigationToolbarTests'` | **143/143** |
| `swift build` (every Darwin target) | complete, 0 errors |
| `swift build --build-tests` | complete, 0 errors |

## (7) Validation

| check | result |
|---|---|
| corpus | `git status --short` empty before and after; nothing written to the clone |
| chain spec | committed spec unmodified; the MobileCoreServices experiment used a scratch copy |
| simulator | created with `SIM_DEVICE_SUFFIX=-nsobject-value-classes`, deleted (0 devices match) |
| pins / bundles / app sources | untouched; no `Package.resolved`, `.app` or vendored app file changed |
| merge check | MERGE_CHECK_VERDICT |
