# The Objective-C surface: UIFont as a class, CALayer, CGColorRef and the census tail

**Date:** 2026-09-22
**Branch:** `agent/objc-surface`, merged with main `09576338` (attrstring-unify included)
**Route:** (b), Apple toolchain (Xcode 26.1), plus the Mach-O guest (machorun + objc4)
**Oracle:** iPhone 16, iOS 26.1 simulator (`Tools/oracle2/objcsurfaceprobe`)

## Result

| measure | main `dd173c84` | this branch |
|---|---:|---:|
| eidolon Objective-C pods: errors (15 pods, 50 TUs) | **898** | **507** |
| of which OpenUIKit Objective-C surface | 331 | 127 |
| of which pod-internal / cascade | 430 | 243 |
| of which macOS-triple leakage (ios-target's area) | 137 | 137 |
| clean TUs | 7 | 12 |
| Simplenote Objective-C half: errors (61 TUs) | **922** | **847** |
| missing selector / unknown type / other | 516 / 237 / 169 | 454 / 237 / 156 |
| clean TUs | 26 | 27 |
| guest: Objective-C UIFont category + CALayer subclass under machorun | does not compile (no UIFont class; CALayer restricted with vtable slots) | **`OBJC_SURFACE_GUEST_OK`**: 37 lines identical to iOS 26.1 |

Per-pod numbers are in `objc-surface-census.json`. Both censuses run on the macOS
triple, which is how route (b) builds today. Per pod: FLKAutoLayout 63 → 2,
Artsy-UIButtons 123 → 33, Artsy-OSSUIFonts 39 → 12, Artsy-UILabels 53 → 26,
SVProgressHUD 263 → 178, SDWebImage 204 → 141 (118 of those remaining are
its macOS branch), UIView-BooleanAnimations and Artsy-UIColors → 0.

## 1. UIFont is an NSObject class

`public final class UIFont: NSObject`. It was a Swift struct, so Objective-C had
no UIFont class at all. That caused `cannot define category for undefined class
'UIFont'` (Artsy+UIFonts) and 18× `receiver 'UIFont' for class message is a
forward declaration`.

* **Swift source compatibility.** `UIFont.systemFont(ofSize:weight:)`,
  `boldSystemFont`, `italicSystemFont`, `monospacedSystemFont`,
  `preferredFont(forTextStyle:)`, `UIFont(name:size:)`,
  `UIFont(descriptor:size:)`, the metrics, `fontName`/`familyName` and
  Hashable all work unchanged. `withSize(_:)` is new, with UIKit's
  spelling. Every stored property is a `let`. The internal sites that
  mutated a struct copy (UILabel's shrink-to-fit, UIFontMetrics' scaling,
  `preferredFont`'s leading, the two `customFontName` initializers) now use
  copy helpers or initializer arguments that keep every other field, so the
  fonts drawn are the same.
* **Value semantics, measured** (`transcript-ios26.1.txt ## font` / `## identity`).
  * `isEqual:`/`hash` compare the description.
  * `systemFont(17)` equals another `systemFont(17)`, `[systemFont(18)
    fontWithSize:17]` and `systemFontOfSize:17 weight:Regular`.
  * `boldSystemFontOfSize:17` equals neither weight:Bold nor weight:Semibold, and
    it is named `.SFUI-Semibold`. It is the system font with the bold trait,
    not a weight. It is modelled that way, and the glyph weight OpenUIKit
    draws is unchanged.
  * `italicSystemFontOfSize:` is `.SFUI-RegularItalic`.
  * `preferredFontForTextStyle:body` is not equal to `systemFont(17)`.
  * `[font copy]` returns the receiver.
  * Identity is not part of the contract. iOS caches system fonts; OpenUIKit
    builds a new object per call.
* **Objective-C surface** (`Sources/OpenUIKit/ObjCSurface.swift`, native, so
  the guest has it too). The iPhoneSimulator26.1 SDK selectors:
  `systemFontOfSize:[weight:]`, `boldSystemFontOfSize:`,
  `italicSystemFontOfSize:`, `monospacedSystemFontOfSize:weight:`,
  `fontWithSize:`, `pointSize`, `ascender`, `descender`, `capHeight`,
  `xHeight`, `lineHeight`, `leading`, `copyWithZone:`. Where Foundation
  exists there are also `fontWithName:size:`, `preferredFontForTextStyle:[…]`,
  `familyNames`, `fontNamesForFamilyName:`, `fontName` and `familyName`.
  `UIFontWeight*` constants (`UIKitObjCSupport.h`) carry the measured values.
  UILabel, UITextField and UITextView get `font` twins.
* **Runtime name.** On the Foundation-hidden guest the runtime name is
  `UIFont` (`SWIFT_CLASS_NAMED("UIFont")` in the guest's header). The macOS
  host keeps the mangled name: **measured**, the private UIFoundation
  framework already registers a class `UIFont` ("Class UIFont is implemented
  in both …UIFoundation… and …"). The header's interface name is `UIFont`
  either way, so Objective-C source and categories are unaffected.
* **Through Foundation's NSAttributedString** (attrstring-unify's path),
  measured. The attribute reads back as the identical object.
  `addAttribute`/`enumerateAttribute` ranges match. Equal fonts coalesce into
  one run. Copies and equal-font strings are `isEqual`. The Swift
  `[NSAttributedString.Key: Any]` literal Kickstarter's Library writes now
  type-checks.

## 2. CALayer and CGColorRef

* **Vtable-free.** This is the simplenote-objc-core rule. Every member is
  `final` except `layoutSublayers`, which is `@objc dynamic`.
  `init(owner:)` is no longer required on Objective-C runtimes. A view creates
  its backing layer with an Objective-C `-init` sent to `+layerClass`, so an
  Objective-C `+layerClass` subclass's `-init` runs as on iOS.
  `ObjCSurfaceTests` reads the type descriptor: 0 introduced slots.
* **Measured and changed.** A new layer's `needsLayout` is **NO** and
  `layoutIfNeeded` runs nothing (OpenUIKit said YES). A view's backing layer
  still starts dirty. `LayerContextCompatibilityTests` asserted the old
  unmeasured behaviour and now follows the oracle.
* **Surface.**
  * `+layer`, which sends `[[self alloc] init]` so the subclass's `-init` runs.
  * Layout: `setNeedsLayout`, `needsLayout`, `layoutIfNeeded`.
  * Tree: `addSublayer:`, `insertSublayer:atIndex:`, `removeFromSuperlayer`,
    `superlayer`, `sublayers`, `mask`, `delegate`.
  * Geometry: `bounds`, `frame`, `position`, `anchorPoint`.
  * Appearance: `opacity`, `hidden`/`isHidden`, `opaque`/`isOpaque`,
    `masksToBounds`, `cornerRadius`, `borderWidth`, `contentsScale`, the
    shadow properties, `shouldRasterize` and the rest.
  * CGColorRef (`OpenUIKitObjCBridge`): `borderColor`, `backgroundColor`,
    `shadowColor`, plus `UIColor.CGColor` and `+colorWithCGColor:`. The
    conversion keeps the gray model, matching iOS: white/clear/`colorWithWhite:`
    are 2-component gray and the rest 4-component sRGB. It lives in two
    functions (`_cgColorRef`, `_openColor`).
* **Runtime name.** `CALayer` (`SWIFT_CLASS_NAMED`, subclassable) on the guest.
  On the macOS host the mangled name stays, because QuartzCore's CALayer is in
  every process. The host fixture lifts `objc_subclassing_restricted` to
  exercise the same vtable-free class.
* **Two runtime hazards found and fixed** (both `+layerClass` / `+layer` on an
  Objective-C subclass, whose Swift metatype is a class wrapper).
  * `type as AnyObject` retained the wrapper as an object. **Measured:**
    SIGSEGV in `swift_unknownObjectRelease` at 0x320.
  * `as! Self` failed the cast. **Measured:** "Could not cast value of type
    'OUKTraceLayer' to 'OUKTraceLayer'".
  * Fix: reinterpret the metatype as `NSObject.Type` and send `init`.

## 3. The rest of the census list

These are `@objc(<SDK selector>)` twins over existing OpenUIKit API, with SDK
raw values, in `OpenUIKitObjCBridge`, plus declarations in `UIKitObjCSupport.h`.

* **UIVisualEffectView:** `initWithEffect:`, `contentView`, `effect`, and
  `+[UIBlurEffect effectWithStyle:]` with UIBlurEffectStyle.
* **UIView:** `layer`, `transform` (CoreGraphics' struct ↔
  OpenCoreGraphics'), `contentMode` with UIViewContentMode,
  `addConstraint:`, and `animateWithDuration:` in four variants including
  the spring one.
* **UIImage:** `imageWithContentsOfFile:`, `initWithData:`/`imageWithData:`,
  `imageWithRenderingMode:`, `renderingMode`. UIImageOrientation and
  UIImageRenderingMode are declared.
* **UIApplication:** `canOpenURL:` and `openURL:`, plus the two notification
  names.
* **Auto Layout:**
  * UILayoutPriority constants.
  * NSLayoutRelation and NSLayoutAttribute, Objective-C side only
    (`!__swift__`). With both modules visible, the Swift importer rejects
    AppKit's copy next to ours. **Measured.**
  * Off `TARGET_OS_IPHONE` the attribute enum carries exactly AppKit's members
    and the margins become macros, as the SDK itself does. The 22-member enum
    had produced "different definitions" in Simplenote files that see AppKit.
    **Measured.**
  * `+constraintWithItem:…`, `constant`, `active`.
* **UIButton / UIControl:** `titleLabel`, `imageView`,
  `set{Title,TitleColor,Image,BackgroundImage}:forState:`, `state`.
* **Alerts:** UIAlertAction is now NSObject-derived. Its superclass was
  measured, and it keeps identity equality. `+actionWithTitle:style:handler:`
  and `+alertControllerWithTitle:message:preferredStyle:`/`addAction:` are
  added.
* **UIBarButtonItem:** the three initializers. PageCurl fails closed.
* **Other:**
  * `+[UIScreen mainScreen]`, `colorWithHue:…`.
  * UIGeometry's inline helpers, UIOffset.
  * The UICollectionElementKind constants.
  * `UIApplicationDelegate.window`.
  * NSIndexPath `item`/`section`/`+indexPathForItem:inSection:`. These are
    declared in the header. The bridge implements them only where AppKit
    doesn't already. **Measured:** the older `section` twin replaced AppKit's.

## Tests (each fails before the change, passes after)

* `Tests/ObjCSurfaceTests` (11 tests). The shared scenario — the same `.m`
  the simulator runs — must match `transcript-ios26.1.txt` line for line for
  superclasses, font, layer, the layer subclass and cgcolor. The tests also
  check Swift value semantics, the class is Objective-C-visible with the
  category attached, the Foundation attribute round trip, CALayer's zero
  vtable slots, and that no twin shadows a native selector (that check caught
  a UIControl `isEnabled` twin that would have recursed).
  * Before the change the fixture does not compile. `@interface UIFont
    (OUKSurfaceProbe)` fails with "cannot define category for undefined
    class", as in the census.
* Full suite, clean `.build`: 2005 tests. The failing set is a subset of main
  `dd173c84`'s: 12 classes vs main's 13, none new. Two tests changed to follow
  measurements:
  * LayerContextCompatibility (new layer is clean).
  * UIAlertLayout (a text-style font is not `==` the plain system font; the
    test now compares the face).
* **Guest** (`uikit/scripts/objc_surface_guest_probe.sh`). It works on a
  diagnostic copy of `build_full.sh`, following the NIB probe's pattern. It
  emits the guest OpenUIKit's Objective-C header and compiles the scenario
  with clang-18 `-DOUK_NO_FOUNDATION`. Beside objc4 it uses a guest-only
  `<Foundation/Foundation.h>` stand-in, because the header includes it; that is
  **measured**. It runs under machorun and compares with
  `transcript-guest-ios26.1.txt`, which is the same variant run on the
  simulator.
  * Output: `SWIFT_CLASS_NAMED("CALayer")`, `SWIFT_CLASS_NAMED("UIFont")`,
    `OBJC_SURFACE_GUEST_EXIT=0`, **`OBJC_SURFACE_GUEST_OK 37 lines identical`**.
  * `nib_guest_probe.sh`'s anchor no longer exists in `build_full.sh`, because
    the probes moved to `run_jobs`. This probe anchors on the
    `run_jobs build_final_executable` line.

## What is still open (ranked by the after-census)

1. **Objective-C subclasses of UILabel, UIButton and UIImageView.** These are
   the 6 remaining `cannot subclass` errors: ARLabel, ORColourView, ARButton,
   ARCircularActionButton, UIImageViewAligned, and SVRadialGradientLayer on
   the host. Most of Artsy-UILabels/-UIButtons' remaining cascade comes from
   them. The fix is the same vtable-free treatment the 11 chain classes got.
2. **Plain Swift classes Objective-C cannot see** (class-ABI changes like
   UIFont's): CAAnimation/CABasicAnimation/CAAnimationGroup/
   CAMediaTimingFunction, CAShapeLayer (absent), UIBezierPath,
   UICollectionViewLayout/LayoutAttributes/FlowLayout (ARCollectionViewMasonryLayout
   subclasses it), UIActivity, UIMotionEffect.
3. **No OpenUIKit behaviour yet, so no twin:** background tasks,
   `UIWindow.windowLevel`, `UIImage.CGImage`/`imageWithCGImage:…`,
   `CALayer.contents`, UIAccessibility notifications.
4. **Measured gap:** iOS instantiates the variable system font at any weight
   (`systemFontOfSize:17 weight:0.35` → `.SFUI-Regular_wdth_opsz_GRAD_wght284FFF9`).
   OpenUIKit has only the named weights, so `systemFontOfSize:weight:` maps
   to the nearest.
5. **Not mine, recorded:**
   * macOS-triple leakage, 137 (SDWebImage's `TARGET_OS_IPHONE` branch,
     `NSFont`, AppKit duplicates): ios-target.
   * `'CALayer' has different definitions` against QuartzCore (15): the
     CA/CG type-unification wall. ios-target measured that it persists on
     the iOS triple.
   * `NSUnderlineStyle*`: attrstring-unify.
   * Artsy's `+sansSerifFontWithSize:`/`artsyPurpleRegular` callers: the
     private Artsy+UIFonts pod and the header layout.
   * Main's `UIButtonConfigurationTests.testAttributedTitleFontAndColourWin`
     fails on main `dd173c84` too.

### On CA/CG type unification (coordinator request)

Full unification — on Apple toolchains CALayer being QuartzCore's CALayer or
a subclass of it, and CGColor being CoreGraphics.CGColor — is **not** done
here. The surface is built so as not to make it harder:

* The Apple-host runtime names stay mangled.
* Every Objective-C twin lives in two blocks (`ObjCSurface.swift`'s CALayer
  extension, the bridge's CGColorRef section) that a unified CALayer would
  simply inherit and delete.
* All CGColorRef crossings go through `_cgColorRef`/`_openColor`, which
  become identity once CGColor is CoreGraphics'.
* The iOS-triple census was not run. It needs ios-target's curated SDK
  (`Tools/ingest/ios_target_sdk.py`, on `agent/ios-target-route`), OpenUIKit
  and the bridge built with `--triple arm64-apple-ios26.1-simulator`, and the
  census compiled with `-target arm64-apple-ios26.1-simulator -isysroot
  <curated SDK>` against those triple-specific generated headers.

## Risks

* `UIFont` is a class. Swift code that mutated a font copy no longer
  compiles, as in UIKit; the in-repo sites were converted. Each font is now a
  heap object (a new one per factory call; iOS caches). Pixels: see the gate
  line below.
* CALayer members became `final`. A Swift subclass outside OpenUIKit could
  not override them before either (they were `public`), so this is
  unchanged. An Objective-C subclass's override of a property setter
  (`-setBounds:`) is not seen by OpenUIKit's Swift internals.
* Adding `CPortableIO` to `objc_pod_census.py` repairs the tool on main,
  where every TU had failed with "'cportableio.h' file not found".
* Stale `.build` directories must be cleaned after this lands, because the
  class layouts changed.

## Commands

```
Tools/oracle2/objcsurfaceprobe/run.sh                         # iOS 26.1 oracle (both transcripts)
swift build --build-tests && swift test --skip-build --filter ObjCSurfaceTests
python3 Tools/ingest/objc_pod_census.py <pods> <spec.json> out.json   # eidolon pods
bash uikit/scripts/objc_surface_guest_probe.sh <tree>                 # machorun guest
```
