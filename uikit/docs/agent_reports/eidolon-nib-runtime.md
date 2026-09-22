# Eidolon pass 3: a storyboard / NIB runtime, measured against iOS 26.1

2026-09-22, branch `worktree-agent-a0549899b7f421981`, base `9cd38125`.

This pass replaces the NIB row of [eidolon-launch2.md](eidolon-launch2.md)'s
blocker table ("initial storyboard lookup nil; missing app factories;
10/17/12 unhandled direct archive entries") with a general storyboard/NIB
runtime: `UIStoryboard` loading of compiled `.storyboardc`, archived objects
built through their own `init(coder:)`, outlets / actions / runtime attributes /
segues, measured transcript-for-transcript against a private iOS 26.1
simulator loading **the same compiled bytes**. It then re-measures Eidolon's
remaining walls. **Eidolon's first screen is not reached; score N/A.** The
next wall is the Objective-C CocoaPods half (below), not the NIB layer.

## What the runtime does

A compiled storyboard (`ibtool --compile`, what Xcode ships) is a directory:
a binary `Info.plist` (entry point, identifier -> scene nib) plus one NIBArchive
per scene and one per controller view. New and changed files:

| piece | where |
|---|---|
| Foundation-free `bplist00` reader (the guest library has no Foundation) | `Sources/OpenUIKit/BinaryPropertyList.swift` |
| `UIStoryboard` (initial / identifier instantiation, UIKit's failure messages), `UIStoryboardSegue`, segue templates (show, push, modal, presentation, embed), `performSegue` / `shouldPerformSegue` / `prepare(for:sender:)`, `storyboard` property | `Sources/OpenUIKit/UIStoryboard.swift` |
| `UINibCoder` (an `NSCoder` positioned on one archived object) and the connection objects (outlets, outlet collections, target-action, runtime attributes) | `Sources/OpenUIKit/UINibCoder.swift` |
| archived keys -> state (views, controls, stacks, tables, cells, spinners, text fields/views, navigation / bar button / tab bar items, gestures) | `Sources/OpenUIKit/UINibKeys.swift` |
| decoder core: run-time class lookup, `init(coder:)` / `init()` construction, external objects, `awakeFromNib` order, symbolic spacing, embedded nibs, `Bundle.loadNibNamed` | `Sources/OpenUIKit/UINib.swift` |
| `init(coder:)` hooks (the paths the brief allows): UIView / UIViewController decode; UILabel, UIButton, UIImageView, UITextField, UITableViewCell, UIActivityIndicatorView re-apply the archive after their own post-`super` defaults; storyboard view load in `loadView` of UIViewController / UITableViewController / UICollectionViewController; embed segues between `loadView` and `viewDidLoad` | those files |

**Class lookup.** A custom class is found by its archived name the way
`NSClassFromString` finds it: `objc_lookUpClass` on an Objective-C runtime,
else `_typeByName` on the current mangling (`_TtC5Kiosk17AppViewController` ->
`5Kiosk17AppViewControllerC`; measured: the legacy spelling returns nil,
the current one the type). `UINibClassRegistry.moduleAliases` covers a port
that compiles the app under another module name (`["Kiosk": "Eidolon"]`).
A registered factory still wins (the realapp harness path is unchanged), and
UIKit's own classes stay on the registry path the Pocket Casts screens were
measured on. An IB custom *object* gets `init()`, not `init(coder:)` (measured).

**Outlets** go to framework-owned names first (`view`, `storyboard`,
`delegate`, `dataSource`, …), then `UINibOutletConnecting`, then KVC —
Foundation `setValue(_:forKey:)` where it cannot raise, the Objective-C
setter where Foundation is hidden (guest library). Where UIKit would raise
`NSUnknownKeyException`, the port records the outlet in
`UINib.unhandledKeys` and continues (a deliberate divergence).

## The oracle

`scripts/nib_runtime_probe_sim.sh` builds `Tools/oracle2/nibruntimeprobe`
(real UIKit, `UIApplicationMain` — measured: without it `sendActions` delivers
nothing) with module name `NibRuntimeTests` from the **same** scenario files
the port test compiles (`Tests/NibRuntimeTests/*Scenario.swift`), on
`OpenUIKit-NibRuntime-nibrt-a054`, iPhone 16, iOS 26.1 (23B86). Inputs are the
carried `fixtures/nibruntime/NibRuntimeProbe.storyboardc` (ibtool output of
`Tools/oracle2/nibruntimeprobe/NibRuntimeProbe.storyboard`; two compiles are
byte-identical), `ProbeXibView.nib`, and Eidolon's 29 compiled view archives.

| transcript | what it pins | port vs iOS |
|---|---|---|
| `nibruntime.json` (56 ordered events, 345 values, 14 dumped views) | nav controller + archived root relationship; `init(coder:)` sees decoded frame/background before superview; runtime attribute before outlets; outlets in archive order; `awakeFromNib` after; storyboard nil in `init(coder:)`, set by `awakeFromNib`; view nib in `loadView`; embed: `shouldPerform` (sender = controller) -> instantiate -> `prepare` -> child view load (screen-sized) -> `willMove` -> child view fills container, autoresizing 18 -> `didMove` -> parent `viewDidLoad`; archived button action; tap gesture; `performSegue` (no `shouldPerform`); control-triggered segue (with `shouldPerform`, sender = button); push onto an unloaded nav sends no `didMove`; identifier instantiation | **exact** (0 differences) |
| `nibruntime2.json` (19 events, 295 values) | stack views (axis/spacing/distribution/alignment/arranged), safe-area constraints, spinner, table view controller with archived prototype cell (custom class, outlet, reuse id, `awakeFromNib`), tab bar controller (children, items; `selectedIndex` NSNotFound before and after view load), xib with custom File's Owner, `Bundle.loadNibNamed` | 11 values differ, all recorded: table self-sizing of an ambiguous cell (iOS 51 pt, port's measured classic row 52) and a 1/3 pt text width |
| `eidolonnibs.json` (29 archives, 5,032 values, no app classes) | UIKit's unknown-class fallback to `UIOriginalClassName`, fonts, colours, frames after layout at 1024 x 768, every outlet via `setValue(_:forUndefinedKey:)` recorders | 28/28 loadable archives match except **6 values**: two labels naming the unbundled private face AGaramondPro-Regular, which iOS replaces with **Helvetica** (the port has no Helvetica face). `KeypadView.xib` raises `NSUnknownKeyException … key keys` on iOS without the app classes; the port records it instead. |

`fixtures/nibruntime/known_divergences.json` lists those 17 paths with the
measured reason; `NibRuntimeTests` fails on any other difference **and** if a
listed path stops differing. Framework facts the transcripts forced
(each covered by the same tests): `NSTextAlignment` and `UIButton.ButtonType`
UIKit raw values; `UISegmentedControl` clips to bounds (programmatic too);
an archived `UITextField` reports `clipsToBounds` false although its archive
says true; an absent `UIUserInteractionDisabled` means enabled; IB "Standard"
spacing (`NSSpace`) is 20 to the superview, 8 between siblings; a navigation
controller's archived stack is parented without containment callbacks.

## Validation

| check | result |
|---|---|
| `swift test --filter 'NibRuntimeTests\|UINibTests'` (Darwin) | **18/18** (5 new + 13 existing UINib) |
| Before this branch | the scenario does not compile (no `UIStoryboardSegue`, `prepare(for:)`, `storyboard`) and `instantiateInitialViewController()` returned nil |
| `scripts/guest_route_check.sh` (Foundation-hidden guest library) | `GUEST_ROUTE_CHECK_OK`, openuikit=161 |
| `swift:6.2-noble` Linux | openrender, ConformanceApps, OpenUIKitTests, NibRuntimeTests build (rc 0) |
| **Mach-O guest, machorun + objc4** (`scripts/nib_guest_probe.sh`) | `NIB_GUEST_RUNTIME_OK class=GuestNibController label=Guest badgeInitFrame=(10,20,30,40) taps=1 prepared=["Embed"] child=UIViewController` — class found by name through objc4, `init(coder:)`, ObjC-setter outlets, action, embed segue with the app's `prepare` override |
| `scripts/ops/local_guest_verify.sh` (full guest) | `FOCUS_REAL_APPDELEGATE_LAUNCHED root=BrowserViewController`; rendered 15 screens, existing 14/14 byte-identical; `REAL-APP SCREEN VERIFIED ON LINUX` |
| Catalyst gate / real-app floors (CHECK_ONLY run) | 124/124; the 14 real-app scores equal the previous report's |

## Eidolon after this pass

| blocker (eidolon-launch2) | now |
|---|---|
| NIB | `UIStoryboard(name: "Auction").instantiateInitialViewController()` now returns the scene (a `UIViewController` stand-in, as UIKit's own fallback, since the app classes do not compile) with its view nib loaded and both embed segues performed (`UINavigationController`, `UIViewController` children, 6 subviews). The 19 unhandled entries are all absent-app facts: 6 Kiosk classes, 9 outlets they declare, 3 private fonts, 1 asset-catalog image. With the app compiled, its classes resolve by name (alias `Kiosk` -> `Eidolon`). |
| DEP absent imports | Open. 24 of the 109 app files import one of the 14 absent modules; the first screen needs `AppDelegate.swift` (SDWebImage) and `ListingsViewController.swift` (ARCollectionViewMasonryLayout). 12 of the 14 are Objective-C pods that subclass or extend OpenUIKit's Swift classes. Measured with SVProgressHUD (ladder-deps HEAD `ece669b`, **not** the locked 2.2.3) against `OpenUIKit-Swift.h` + `UIKitObjCSupport.h`: **397 errors**, including `SVProgressHUD.h:65:12: error: cannot subclass a class that was declared with the 'objc_subclassing_restricted' attribute` and missing Objective-C properties (`text` ×15, `alpha` ×12, `frame`, `image`, …) — the wall simplenote-launch3 measured, which the parallel `@objc @implementation` work targets. |
| DEP other RxCocoa AppKit branches | Open, not adapted this pass. App use: `.rx.text` 38, `.rx.action` 26, `.rx.observe` 16 (KVO, not UIKit), `.rx.event` 7, `.rx.isEnabled` 4, `.rx.textInput` 3, `.rx.attributedText` 3, `.rx.tap` 3 (done in pass 2), `.rx.title` 1, `.rx.controlEvent` 1. |
| CardFlight / Stripe | Unchanged. The locked CardFlight source is unavailable and its API cannot be recovered from call sites, so no shim is written; Stripe stays the fail-closed 12.1.0 adapter. No payment, account or network success is produced anywhere. |
| First-screen score | **N/A** — not reached. |

## After merging main: the Objective-C pods, re-censused

Main's Simplenote change (vtable-free UIKit chain, `SWIFT_CLASS_NAMED`) is
merged (5d03dea4). `objc_subclassing_restricted` is gone for the chain
classes. I then fetched the Podfile.lock versions of the absent pods
(`fixtures/realapp/eidolon/objc_pods.json` lists URL, tag and resolved commit;
the sources are not vendored) and syntax-checked every translation unit.
`Tools/ingest/objc_pod_census.py` runs the check against the ingest tool's
route-(b) `<UIKit/UIKit.h>` (generated header + support header + bridge
header, with the subclassing defines) under `-include UIKit/UIKit.h`, which is
what CocoaPods' Pod-prefix.pch does. Full per-TU errors:
`eidolon-objc-pods-census.json`.

| | errors |
|---|---:|
| 15 pods, 51 translation units (9 clean) | **1,025 → 899** |
| of which macOS-branch leakage | 137 |
| of which OpenUIKit Objective-C surface | 331 |
| of which pod-internal / cascade | 431 |

The one fix in this step is `UI_APPEARANCE_SELECTOR` in `UIKitObjCSupport.h`,
copied verbatim from the iOS 26.1 SDK (`UIAppearance.h:22`). It clears 126
parse errors: SVProgressHUD 2.2.3's 42 annotated properties, 3 errors each.
A build-time check in `UIKitObjCSupport.m` does not compile without the macro.

**macOS-branch leakage (137)**, recorded as found and not worked around.
Another agent (ios-target) is moving route (b) to an iOS triple:
- SDWebImage 3.8.2 (118): `TARGET_OS_IPHONE` is false, so it takes its
  `NSImage`/`NSImageView`/`MKAnnotationView` branches, and `SDWebImageCompat.h`
  fires `SDWebImage doesn't support Deployment Target version < 5.0`.
- Clang reports `has different definitions in different modules` for
  `CALayer` (QuartzCore), `NSTextContainer`/`NSLayoutManager` (AppKit) and
  `NSLayoutConstraint`/`CAGradientLayer`/`NSParagraphStyle`/`NSTextAttachment`
  (OpenUIKit). The macOS SDK's modules and OpenUIKit's generated header
  declare the same names.
- XNGMarkdownParser (13) and Artsy+OSSUIFonts (4) resolve `NSFont` /
  `NSFontDescriptor` where iOS has `UIFont` / `UIFontDescriptor`.

**OpenUIKit Objective-C surface (331)**, by symbol: CALayer 36 (bounds,
borderColor, backgroundColor), UIVisualEffectView 23, UIFont 20, UIColor 16
(`CGColor`), UIImage 13, UIApplication 11, UIView 9, UICollectionViewLayoutAttributes 8,
CABasicAnimation 8, UIButton 8, UIImageView 7, CAShapeLayer 6,
NSLayoutRelation / UILayoutPriority / NSLayoutAttribute* 25, UIImageOrientation 9,
UIBezierPath 4, UIInterpolatingMotionEffect 4.

The structural one is **UIFont, a Swift struct in the port**. It has no
Objective-C class, so the categories `Artsy+UIFonts` / `Artsy+OSSUIFonts`
(`+[UIFont serifFontWithSize:]`) cannot exist. `Artsy+UILabels` and
`Artsy-UIButtons` call them 18 times (`receiver 'UIFont' for class message is
a forward declaration`). These three pods cover 20 of the 24 app files that
import an absent module.

Where Eidolon stops now:
- **First screen: not reached; score N/A.**
- Next wall: the macOS-triple leakage above, which the iOS-target work
  addresses, plus an Objective-C `UIFont` class and CALayer / UIColor
  `CGColor` surface for the Artsy pods.
- CardFlight stays unavailable (no shim: its API cannot be recovered from the
  call sites); Stripe stays the fail-closed adapter.

## Not supported (open)

Unwind segues and custom `UIStoryboardSegue` subclasses; popover templates;
trait-variation storage (`_UIRelationshipTraitStorage*`); attributed-text
attribute runs (characters only); button background images; bundled custom
fonts (no face loader: private faces fall back to the system face, iOS uses
Helvetica); prototype-cell external objects; collection-view, page-view,
split-view and visual-effect archives; `instantiateViewController(identifier:creator:)`;
restoration identifiers; accessibility configurations. In the Foundation-hidden
guest, KVC is the Objective-C setter only (no ivar fallback) and an outlet
*collection* has no `NSArray` bridge. Unknown keys are listed in
`UINib.unhandledKeys`, never guessed.

## Reproduce

From `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-mine scripts/nib_runtime_probe_sim.sh /tmp/nib-oracle
swift test --filter 'NibRuntimeTests|UINibTests'
python3 Tools/nib/nibdump.py fixtures/nibruntime/NibRuntimeProbe.storyboardc
bash scripts/nib_guest_probe.sh            # Mach-O guest, machorun + objc4
```

Machine-readable facts are in `eidolon-nib-runtime.json`.
