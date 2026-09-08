# Simplenote launch rung 2, pass 3: route (b) mixed graph measured to its wall

**Date:** 2026-09-07  
**Route:** (b), Apple toolchain on this Mac → Mach-O guest → `machorun`  
**Corpus:** Automattic/simplenote-ios `9b1bb17d8ec224a709d306e0ec34cee38bc7d933`, unpatched  
**Branch:** `agent/simplenote-launch3`  
**Status:** first screen not reached on OpenUIKit; score **N/A**. The iOS 26.1
oracle capture of the first screen now exists (below). The blocker is no
longer a build-order question: it is a runtime fact about Objective-C classes
whose superclass is a Swift class.

## The measurement that decides the architecture (probe1)

Pass 2 assumed the route-(b) Objective-C half would compile against
`ObjCFacade/include/UIKit.h` (the Linux C-ABI facade). That header declares its
own `UIView`/`UIViewController` classes, so a Swift half that imports the
bridging header sees two `UIView`s: the facade's (`__ObjC`) and OpenUIKit's.
Simplenote's Swift half extends the ObjC app classes 98 times, so a second
universe is unusable. The single-universe alternative on the Apple toolchain
is SwiftPM's own generated header: `swift build --target OpenUIKit` writes
`.build/<triple>/<cfg>/OpenUIKit.build/include/OpenUIKit-Swift.h` (134
`@interface`s) plus a module map, and hands the include path to every Clang
target that depends on OpenUIKit. That is the Xcode mechanism pass 2 reported
as a wall. A four-target probe package (Bridge → AppObjC → AppSwift, Sources
in the session scratchpad, numbers below) measured what it gives:

| question | result |
|---|---|
| Does a Clang target see the Swift target's generated header before compiling? | Yes: `AppObjC` compiled `#import "Bridge-Swift.h"` and `#import "OpenUIKit-Swift.h"` with no extra flags. Staged order is an ordinary SwiftPM dependency. |
| Does Swift map the header's `SWIFT_CLASS("_TtC9OpenUIKit10UITextView")` back to `OpenUIKit.UITextView`? | Yes, when imported as the `OpenUIKit` Clang module (`-Xcc -I` to that include dir): an ObjC subclass of the header's `UITextView` is assignable to `OpenUIKit.UITextView`. **No** for a textual copy of the same header (imported as a distinct class), and no for a hand-written `objc_runtime_name` interface. |
| Does the Swift half survive the header? | Only with six renames: OpenUIKit imports AppKit on macOS (FoundationTypes.swift:63), so `NSLayoutConstraint`, `NSTextContainer`, `NSLayoutManager`, `NSTextAttachment`, `NSAdaptiveImageGlyph`, `NSTextAttachmentViewProvider` report `has different definitions in different modules`. `-Xcc -DNSLayoutConstraint=OUK_NSLayoutConstraint` on the Swift target keeps the runtime name and the mapping. |
| Can an Objective-C class subclass `UITextView` / `UIViewController`? | **No.** Every class in the generated header is `objc_subclassing_restricted` (Apple's rule). Predefining `SWIFT_CLASS` without the attribute compiles both classes, and the first `[[SPTextView alloc] init]` dies at `UIView.swift:809` (`self.init(frame:)` inside the convenience `init()`): `EXC_BAD_ACCESS pc=0x0`, `lr = OpenUIKit.UIView.init() + 56`. A statically emitted Objective-C class object has no Swift vtable region, so the delegated designated-initializer slot reads zero. This is the runtime reason for the attribute, not a compiler policy. |
| Does the ObjC protocol `UITableViewDataSource` coexist with OpenUIKit's Swift protocol? | Not under the same name: `'UITableViewDataSource' is ambiguous for type lookup`. The support header names every protocol `NS_SWIFT_NAME(...ObjC)`. |
| Do relative `-Xcc -I` paths resolve? | Yes: SwiftPM runs swiftc with the package root as cwd. |

Consequence for Simplenote: **18 of its 35 Objective-C classes subclass an
OpenUIKit Swift class** (SPAppDelegate : UIResponder, SPNavigationController :
UINavigationController, SPNoteListViewController / SPSidebarContainerViewController
/ SPNoteEditorViewController / SPEntryListViewController /
SPMarkdownPreviewViewController : UIViewController, SPTableViewController :
UITableViewController, SPTextView : UITextView, SPTextField : UITextField,
SPEntryListCell : UITableViewCell, SPModalActivityIndicator : UIView, and their
subclasses), one subclasses OpenUIKit's `NSTextStorage` (not exported: it
derives from OpenUIKit's own `NSMutableAttributedString`, a plain Swift class),
one subclasses `UIActivity` (not NSObject-derived). `setupDefaultWindow`
constructs four of them. The first screen cannot be built from the unpatched
ObjC half on route (b); no facade member count changes that. The dynamic
alternative (`objc_allocateClassPair` twins, which objc4 does lay out
correctly) breaks `swift_dynamicCastClass` for the 9 `as? SP…` casts and the
98 Swift extensions of those classes, so it was not pursued.

## What this pass built and measured

| step | before | after | where |
|---|---|---|---|
| (1) staged build order | generated manifest did not load on macOS (`product 'libkern' required … not found`; SwiftPM validates product names under platform conditions); placeholder `Simplenote-Swift.h` | ingest emits `<App>` Swift library target with `-import-objc-header`, `-Xcc -I` to SwiftPM's generated header dirs and the six renames; `<App>ObjC` Clang target **depends on** `<App>` so SwiftPM writes `<App>-Swift.h` first; `<App>Main` executable for `main.m`; `<UIKit/UIKit.h>` shim = generated header + support + bridge; `#if os(Linux)` platform-named products with `-module-alias`; no placeholder | `Tools/ingest/xcodeproj_to_package.py`, 45 tests (`test_xcodeproj_to_package.py`, Simplenote corpus class added; two pass-2-era corpus tests were failing since pass 2 and are corrected) |
| (1) Simperium shim | `@import Simperium` failed: sub-headers import `../SimperiumUmbrella.h`, which does not exist; pass 2's "target builds" never imported the module | umbrella layout `include/Simperium/Simperium.h`; module builds | `Sources/Simperium` |
| (2) ObjC UIKit surface | 33 facade interfaces listed as walls | generated header exports 134 OpenUIKit interfaces for free; `OpenUIKitObjCSupport` (Clang target) adds 33 enums, 2 structs, 5 typed strings, 23 extern constants, 16 protocols, raw values read off the iPhoneSimulator26.1 SDK headers, strings off OpenUIKit's Swift raw values; `OpenUIKitObjCBridge` (Swift target) adds 147 `@objc(selector)` twins over existing OpenUIKit members, 6 runtime-dispatched tests | `Sources/OpenUIKitObjCSupport`, `Sources/OpenUIKitObjCBridge`, `Tests/OpenUIKitObjCBridgeTests` |
| (3) credentials | `Simplenote/Credentials/SPCredentials.swift` missing (229 → 228) | ingest emits it from the public `SPCredentials-demo.swift` (generic `<stem>-demo.swift` rule, recorded as `demo_substitutes`); never the real secret | ingest + tests |
| (3) CoreData model | not compiled | `xcrun momc Simplenote.xcdatamodeld` → `Simplenote.momd` (7 versions + `VersionInfo.plist`), exit 0 | measured only; the app cannot load it before the wall |
| (3) intents | not generated | `xcrun intentbuilderc generate` → 9 Swift files, 1,045 lines, `import Intents`, exit 0 | measured only |
| (3) NIB instantiation | open | remains open: the custom classes are the 18 impossible ObjC subclasses | — |
| (4) oracle capture | none | iPhone 16 / iOS 26.1, real Xcode simulator build of the unpatched corpus with demo credentials: `docs/agent_reports/simplenote-launch3-first-screen-ios26.1.png` | measured below |
| (4) OpenUIKit first screen | N/A | N/A (wall above) | — |

## Objective-C census (per translation unit, clang `-fsyntax-only -ferror-limit=0`)

62 translation units (50 `.m` + 12 Hoextdown `.c`), the exact SwiftPM command
for the generated package's `SimplenoteObjC` target, `Simplenote-Swift.h`
still the Foundation-only placeholder because the Swift half cannot emit it
(next section). Full data: `simplenote-launch3-objc-census.json`.

| `<UIKit/UIKit.h>` = | clean TUs | errors | unknown type | missing selector | cannot subclass |
|---|---|---|---|---|---|
| generated header only (restriction lifted) | 24 | 1,790 | 686 | 987 | — |
| + OpenUIKitObjCSupport (lifted) | 26 | 1,507 | 257 | 1,071 | — |
| + OpenUIKitObjCBridge (lifted) | 26 | 1,048 | 256 | 601 | — |
| + bridge, restriction in force (shipped) | 24 | 1,100 | 256 | 601 | **52** in 12 headers |

Of the 256 remaining unknown names, 6 are OpenUIKit `NSTextStorage`, 2
`UITextPosition` in an expression context, and the rest are the app's own
Swift symbols (`SPCredentials`, `SPPinLockManager`, `ShortcutsHandler`, …)
that only the generated `Simplenote-Swift.h` can supply. Of the 601 remaining
missing selectors, the largest receivers are classes OpenUIKit does not derive
from NSObject and therefore cannot export at all: `UIBarButtonItem` (11
class-method sites), `UIColor` (`backgroundColor`/`textColor`/`tintColor`,
the `simplenote*Color` extension family), `UIFont`, `UIAlertAction`,
`UIScreen`, `UIViewPropertyAnimator`, `UIPercentDrivenInteractiveTransition`;
then `UIView.animateWithDuration:…` class methods (11) and `transform`
(OpenUIKit's own `CGAffineTransform`). Making those classes NSObject-derived is
the same class-ABI change pass 1 made for `UIImage`; it is not done here.

## The Swift half

`swift build --target Simplenote` in the regenerated package (228 Swift files +
demo credentials, bridging header, all five pinned dependencies, Simperium and
AutomatticTracks shims): the bridging-header precompile fails with **12
errors** and 0 of 228 files reach semantic checking. All twelve are the wall:
10 × `cannot subclass a class that was declared with the
'objc_subclassing_restricted' attribute` (SPAppDelegate.h,
SPEntryListViewController.h, SPMarkdownPreviewViewController.h,
SPNavigationController.h, SPNoteEditorViewController.h,
SPNoteListViewController.h, SPSidebarContainerViewController.h,
SPTableViewController.h, SPTextField.h, SPTextView.h), `NSTextStorage`
(SPInteractiveTextStorage.h), and `NSDirectionalEdgeInsets` (SPTextField.h:13;
AppKit declares that struct, so the support header keeps it ObjC-side only).
Before this pass the same build stopped at the manifest.

## Oracle: the real first screen (iPhone 16, iOS 26.1)

Xcode built the unpatched corpus for the simulator (`xcodebuild -scheme
Simplenote`, demo credentials supplied through the `Copy Secrets` phase by
overriding `HOME` for that build only; the corpus tree is unchanged, the
ignored `Simplenote/Credentials/` output was removed afterwards). A build with
`CODE_SIGNING_ALLOWED=NO` launches to the home screen: the app aborts at
`FileManager+Simplenote.swift:20` (`sharedContainerURL` force-unwrap, the
app-group entitlement is stripped). The ad-hoc-signed build launches. Two
captures 5 s apart are byte-identical. What it shows, measured on the 1179×2556
PNG (@3x, points = px/3):

| element | frame (pt) | note |
|---|---|---|
| window | 393 × 852 | white |
| logo | x 148.7–244.3, y 270.7–366.3 | blue `#3361CC` glyph |
| "Simplenote" title | x 110.7–282.0, y 402.3–432.7 | near-black |
| "The simplest way to keep notes." | x 57.3–335.0, y 447.7–466.0 | gray |
| **Sign Up** button | x 24–369, y 702–746 (345 × 44) | fill `rgb(51,97,204)`, corner radius 4 pt (first full-width row at +12 px), white label |
| **Log In** link | x 174.7–218.3, y 770.3–785.3 | blue text |

The screen is Simperium's onboarding (`SPOnboardingViewController`, a Swift
class presented from `authenticateSimperium`), not the note list. Log:
`Simperium loaded 4 entity definitions`, `Simperium starting...` with the demo
app ID; no account exists, nothing is synced.

## Updated blocker table

| blocker | measured state after pass 3 |
|---|---|
| Mixed language graph | **Closed as a build-order problem.** SwiftPM emits `<App>-Swift.h` for the Swift target and the Clang target depends on it; the ingest tool emits that graph, the bridging header, the generated-header include dirs and the six AppKit renames; Simplenote's Swift target reaches the bridging-header precompile. |
| Objective-C subclasses of OpenUIKit classes | **Structural wall, measured.** Compile-time: `objc_subclassing_restricted` on all 134 generated interfaces, 52 diagnostics in 12 app headers. Runtime with the attribute lifted: null Swift vtable slot at `UIView.init()`. 18 of 35 app classes, including every class `setupDefaultWindow` creates. Dynamic twins break Swift casts. No OpenUIKit change removes this while OpenUIKit's classes are Swift classes. |
| ObjC UIKit ABI (declarations) | 134 interfaces from the generated header + support header (enums/structs/protocols/strings, SDK-measured). Remaining: classes that are not NSObject-derived (UIColor, UIFont, UIBarButtonItem, UIAlertAction, UIScreen, UIDevice, UIActivity, UIViewPropertyAnimator, UIPercentDrivenInteractiveTransition, UIPresentationController, NSParagraphStyle/NSMutableParagraphStyle) and OpenUIKit's own `NSAttributedString`/`NSMutableAttributedString`/`NSTextStorage` hierarchy, which is neither Foundation's nor NSObject-derived (7 ObjC files use Foundation's). |
| ObjC UIKit ABI (behaviour) | 147 `@objc` selector twins over existing OpenUIKit members, 6 runtime tests; missing-selector diagnostics 987 → 601. Override points (`viewDidLoad`, `layoutSubviews`, …) are callable, not overridable, because of the subclassing wall. Delegate protocols are declared with `…ObjC` Swift names; adapters that hand an ObjC delegate to OpenUIKit's Swift protocols were not built (no ObjC class can own a table view here). |
| Services | unchanged from pass 2 (fail-closed Simperium/AutomatticTracks); Simperium's module now actually imports. |
| MobileCoreServices | unchanged. |
| Dependency/platform branches | unchanged (SimplenoteFoundation iOS-only table helpers). |
| Generated app material | credentials: emitted from the public demo; CoreData model: `momc` compiles all 7 versions; intents: `intentbuilderc` generates 9 files; NIB runtime instantiation: open (the custom classes are the wall). |
| Guest wiring | not attempted: the guest runs Apple's objc runtime with the same class-layout rule; there is no compiled app to copy in. `full/` and pin files untouched. |
| Oracle / first screen | iOS 26.1 golden captured and measured (above). OpenUIKit first screen **N/A**. |

## What would move this rung

Either the ObjC half is compiled against Objective-C-implemented UIKit classes
(the `ObjCFacade` design, extended to the whole surface the Swift half uses
too, so both halves share one universe), or OpenUIKit's classes become
`@objc @implementation`-style pure Objective-C classes on Darwin. Both are
architecture decisions, not facade members, and both are outside a pass.

## Validation

| check | result |
|---|---|
| ingest tests | 45/45 with the corpus (`LADDER_CORPUS=…/scratch/ladder-corpus`), 21 of them skipped without it |
| OpenUIKitObjCBridgeTests | 6/6, selectors sent through the runtime |
| `swift build --target OpenUIKitObjCSupport` / `OpenUIKitObjCBridge` / `Simperium` | green |
| Catalyst gate | **124/124** (`/tmp/gate-simplenote-launch3`) |
| real-app 3x floors | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.17 / 99.286 / 99.86 / 99.734 / 85.393 / 97.096 (unchanged; no rendering rule touched) |
| Linux `swift:6.2-noble` release openrender | green, 191.18 s (new targets are inside the Darwin `#else` block) |
| iOS suite (fresh goldens, `/tmp/suite-simplenote-launch3`) | **112/113**, only the known `corner_radius` (99.411); no passing scene dropped |
| `CHECK_ONLY=1 bash uikit/scripts/agent_merge.sh agent/simplenote-launch3` | first run: `MERGE CONFLICT with main` on the fidelity-table row (main had advanced); after merging origin/main with both rows kept: **`checks passed (CHECK_ONLY)`**, no REFUSED line; the script exits 128 in its cleanup, as in passes 1 and 2 |
