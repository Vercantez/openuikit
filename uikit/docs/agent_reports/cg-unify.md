# cg-unify: OpenUIKit's CoreGraphics, ImageIO and QuartzCore types are Apple's own on Apple toolchains

**Date:** 2026-09-22/23. **Branch:** `agent/cg-unify` (increments pinned as `agent/cg-unify-phase1`, merged, and `agent/cg-unify-phase3`).
**Toolchains:** Xcode 26.1 / Swift 6.2.1 (macOS host, route (b) iOS triple); Linux Swift 6.2.4 (guest, Linux ELF).
**Oracle:** iOS 26.1 simulator (iPhone 16), throwaway devices under `/tmp/conformance_sim.lock`.

## Result

| | before | after |
|---|---|---|
| NetNewsWire RSCore, iOS triple (`chain_census.py --ios-target`) | **25** errors, 22 of them CoreGraphics/ImageIO/QuartzCore (RSImage.swift :38–204) | **4**, none CG/CA (phase 2; the 4 are pngData/@objc-optional/sendAction rows owned by netnewswire-launch and objc-surface). Phase 3 with main merged: still **4**. |
| Simplenote Swift half, iOS triple (`swift build --target Simplenote`, curated SDK, WidgetKit imports dropped from scratch copies) | **308** unique errors; 346 "'CALayer'/'CAGradientLayer' has different definitions" lines; 23 CA/CG-shaped rows | phase 1 306, phase 2 291, phase 3 **283**; **0** "different definitions"; **0** CA/CG-shaped rows |
| eidolon ObjC pods, iOS triple (`objc_pod_census.py --ios-sdk`, eidolon-nib's tool e6be1b33) | **565** (phase-2 tree); 3 × "'CALayer' has different definitions"; CA surface rows CABasicAnimation 8, CALayer 6, CAShapeLayer 6, CAMediaTimingFunction 2, CAAnimationGroup 2 | **449** with the same tool, 0 different definitions; **440** and **0** CA/CG rows once the census umbrella imports QuartzCore as Apple's <UIKit/UIKit.h> does (reported to eidolon-nib) |
| gate scenes + real-app screens | | **193/193 PNGs byte-identical** to 535694fa after each phase (release `openrender`, same inputs) |

## Design

"On Apple toolchains" is `#if canImport(CoreGraphics)`, measured to be true exactly
where Apple's frameworks are usable: the macOS host (gate, tests, `openrender`) and
route (b)'s iOS triple. It is false on Linux ELF and on both Mach-O guests: the
guest sysroot (`scratch/sysroot_fe4`, also staged for the iOS guest) carries
`QuartzCore.swiftmodule` and `UniformTypeIdentifiers.swiftmodule` but no
Foundation or CoreGraphics, so `canImport(QuartzCore)` is true there and the
module does not build (the guest-route gate caught `no such module 'Foundation'`
through UTType.swift on the first phase-2 run). The guest links machorun's `.tbd`s
and runs the port's dylibs; nothing Apple-CG exists at link or run time, so every
port type stays there.

### Phase 1: geometry, colour, transform, CG enums; UIKit re-exports CoreGraphics + ImageIO

* `CGFloat/CGPoint/CGSize/CGRect/CGVector` were already Foundation's (M15).
* `CGAffineTransform`, `CGColor`, `CGColorSpace`, `CGImageAlphaInfo` (OpenCoreGraphics)
  and `CGLineCap`, `CGLineJoin` (OpenUIKit) are typealiases of CoreGraphics' types.
  `CGBlendMode` already was. The port's CGAffineTransform math (own sin/cos) was
  replaced by CoreGraphics' with no pixel change.
* The renderer keeps a value colour, **`CanvasColor`** (the old struct renamed); public
  API speaks `CGColor` and converts at the boundary. Conversion rules measured on
  iOS 26.1 (`cgunifyprobe ## color`, `genrgb`): `UIColor.cgColor` is extended sRGB /
  extended gray; sRGB, extended sRGB/gray and device spaces are read verbatim;
  generic RGB/gray, Display P3 etc. go through CoreGraphics' conversion (generic-RGB
  red paints 255,38,0 on iOS, as the port now does). `UIColor(cgColor:)` keeps its
  source colour (and is not `==` to the same components in UIKit's space, as on
  iOS). CALayer colour properties return the object assigned; border/shadow default
  to sRGB black.
* The UIKit shim `@_exported import`s CoreGraphics and ImageIO (the measured
  re-export set, `Tools/oracle2/uikitreexportprobe_ios`).
* The port's CAFilter runtime name is `OUKCAFilter` on Apple hosts (no second
  `CAFilter` class next to QuartzCore's; `CAFilter` on the guest).

### Phase 2: UIKit's current context is an Apple CGContext; UIImage <-> CGImage; CGPath; UTType

* `UIGraphicsGetCurrentContext()`, `UIGraphicsImageRendererContext.cgContext` and
  `CALayer.render(in:)` speak CoreGraphics' `CGContext`. The port makes it lazily as
  a **CGBitmapContext over the Canvas's own premultiplied Quartz backing** (same
  RGBA8 layout), so CoreGraphics calls and the port's rasterizer write the same
  pixels in call order; nothing is composited (Swift backend: a private buffer
  composited before each UIKit call). Base CTM = Canvas CTM flipped
  (`ctm=[1 0 0 -1 0 2]`, measured), clipped to the draw rect.
* UIKit's own drawing calls (UIRectFill, UIBezierPath fill/stroke/addClip,
  UIImage.draw, UILabel.drawText) read the CTM, clip and fill/stroke colour from the
  CGContext (fill/stroke through CoreGraphics' exported
  `CGContextGetFillColorAsColor`/`…Stroke…`), then draw with the port's rasterizer.
  Measured: `cg.setFillColor(blue)` then `UIRectFill` paints blue; a translate then
  `UIRectFill` moves it; `restoreGState` restores the colour — the probe's rows
  match the simulator on both backends.
* A session whose code never asks for the context runs exactly the old path.
* App-made bitmap contexts (`UIGraphicsPushContext`, `render(in:)`) get a Canvas over
  their own memory (premultiplied RGBA8), or an offscreen composited at pop.
* `UIImage.cgImage` (premultiplied sRGB RGBA8, as iOS reports), `init(cgImage:)`,
  `init(cgImage:scale:orientation:)`, `imageOrientation`, `UIImage.Orientation`, and
  ObjC twins `CGImage` / `+imageWithCGImage:(scale:orientation:)` / `-initWithCGImage:`.
* `UIBezierPath.cgPath` is CoreGraphics' `CGPath` (rect/oval element sequences match
  iOS); the renderer's path is `_path`.
* `UTType` is UniformTypeIdentifiers' (NetNewsWire `UTType.png` was ambiguous).
* Linux/guest: `CGContext` = `Canvas`.

### Phase 3: Core Animation is QuartzCore's

* `CALayer`, `CAGradientLayer`, `CALayerDelegate`, `CACornerMask`,
  `CALayerCornerCurve`, `CAMediaTimingFillMode`, `CAAnimation`,
  `CAPropertyAnimation`, `CABasicAnimation`, `CATransaction`, `CATransform3D` are
  QuartzCore's; the UIKit shim re-exports QuartzCore; `OpenUIKit-Swift.h` no longer
  declares a CALayer (the ODR wall). CAShapeLayer, CASpringAnimation, CADisplayLink,
  CAMediaTimingFunction, CAKeyframeAnimation exist through `import UIKit`.
* The port renders from QuartzCore's layer as the model; its own per-layer state
  (backing view, animation records on the port's clock, per-corner radii, layout
  flags) is an associated object (`QuartzCoreUnification.swift`).
* A load-time constructor (`OpenUIKitQuartzBootstrap`, Apple platforms only)
  installs interposers on CALayer / CATransaction that keep the port's measured
  model: a backing layer's geometry/opacity/hidden/background/transform are its
  view's (getters read the view, setters write it); implicit animations are the
  port's (sampled on the deterministic `OpenUIKitRuntime` clock — QuartzCore's need a
  render server and wall-clock begin times, so `-actionForKey:` returns nil);
  `-addAnimation:forKey:`/removal also record into the port's model;
  `+[CATransaction …]` drive the port's transaction model (completion blocks on the
  port's clock); layout runs on the port's flags (QuartzCore's `-layoutIfNeeded`
  re-runs a layer while dirty and looped on UITabBar — measured); `-renderInContext:`
  draws with the port's renderer. The CA interposers only change layers the port has
  state for, or add behaviour and forward.
* Measured on iOS 26.1 and now QuartzCore's (the port's own layer differed):
  `mask.superlayer === owner` (true, measured on iOS 26.1); on macOS QuartzCore (the same framework) ancestor insertion raises CALayerInvalid;
  CALayer is a real KVC container (`opaque`, arbitrary keys, `filters.<name>.<key>`
  resolved by the filter's `name`; the port's filter tokens became key-value objects).

### Phase 4: re-exported, not re-declared

Every unified name was first a `public typealias X = Apple.X`. A client that
imports Foundation/CoreGraphics/QuartzCore and UIKit then sees the name twice, and
Swift parses `[String: CGSize]()`, `[CGFloat](repeating:count:)`, `[CALayer]()`,
`[String: CGColor]()`, `[CGAffineTransform](…)` as collection LITERALS of metatypes
("cannot call value of non-function type '[AnyHashable : CGSize.Type]'";
NetNewsWire SingleLineUILabelSizer.swift:16, found by netnewswire-launch for the
geometry names; measured for every unified name). All of them are now scoped
`@_exported import`s of the one declaration: `struct Foundation.CGFloat`,
`struct CoreFoundation.CGPoint/CGSize/CGRect` (`CoreFoundation.CGFloat` does not
resolve for importers — measured), `CoreGraphics.CGVector/CGAffineTransform/
CGColor/CGColorSpace/CGImageAlphaInfo/CGLineCap/CGLineJoin`, the eleven QuartzCore
types, and `UniformTypeIdentifiers.UTType`. Linux re-exports `Foundation.CGFloat/
CGPoint/CGSize/CGRect`; the guest (no Foundation) keeps the portable structs.
`CGUnifyTests.testCollectionSugarOverUnifiedNamesIsAType` did not compile before.
Pixels 193/193 byte-identical to main c0dca164; Linux build green.

## Tests (each fails before, passes after)

* `Tests/CGUnifyTests` replays `Tools/oracle2/cgunifyprobe` (the same Swift the iOS
  26.1 simulator ran; `import UIKit` only) section by section: color, layer,
  transform, path, bitmap context, imageio (phase 1/2b), renderer context, draw(_:),
  uiimage cgImage on both backends (phase 2), quartzcore + quartzcore render
  (phase 3); plus type-identity tests, CanvasColor round trips, "an unused CGContext
  changes no pixel", UIKit drawing into an app bitmap context. Before each phase the
  fixture target did not compile (the names did not exist through `import UIKit`).
* `ObjCBridgeTests.testUIImageCGImageSelectors`; `LayerContextCompatibilityTests`
  legacy-context tests now drive the CGContext API; CoreAnimationCompatibility /
  LayerContext / NSObjectValueClass assert QuartzCore's (= iOS's) behaviour where it
  differs from the portable layer's, and keep the portable assertions on Linux/guest.
* Full suite (clean build): 2018 tests; the failures are a subset of the base tree's own run
  (535694fa, same machine: FoundationCoexistence, IOSNavigationBarTransition,
  KeyboardChrome ×4, RasterizerTests perf budget, TextFieldDelegate ×2,
  UIButtonConfiguration, UIScrollEdgeEffect, UISearchBar, ValueTypeTail shortcut —
  the last is order-dependent and passes alone, on both trees).

## Validation

| check | result |
|---|---|
| pixels (release `openrender`, 178 gate scenes + 15 real-app screens) | **193/193 byte-identical** to 535694fa after phase 1, phase 2 and phase 3, and the merged phase-3 tree 193/193 byte-identical to main c0dca164 |
| phase 1 gate: `CHECK_ONLY=1 agent_merge.sh agent/cg-unify` (ef4c6d35) | `124/124 scenes pass`, `GUEST_ROUTE_CHECK_OK`, Linux build, **`checks passed (CHECK_ONLY)`**; merged to main as agent/cg-unify-phase1 |
| phase 3 gate: `CHECK_ONLY=1 agent_merge.sh agent/cg-unify-phase3` | 747ef006: `124/124 scenes pass`, `GUEST_ROUTE_COMPILE_OK openuikit=172 opencoregraphics=12`, `GUEST_ROUTE_CHECK_OK`, real-app scores unchanged (99.137 / 98.535 / … / 99.61), conformance passed, Linux build RED on one test (`autoreleasepool` is not in corelibs); fixed in the commit that adds this report (Linux check below) |
| `scripts/ops/local_guest_verify.sh` (747ef006) | `FOCUS_REAL_APPDELEGATE_LAUNCHED`, `rendered 15 screens; existing screens byte-identical 14/14`, **`REAL-APP SCREEN VERIFIED ON LINUX`**, `GUEST HOST INTERACTION VERIFIED ON LINUX` |
| `full/iostarget/ios_guest.sh` (747ef006) | `IOS_TARGET_PROBE_MATCHES_IOS_26_1 lines=14`, `REAL-APP SCREEN VERIFIED ON LINUX`, **`IOS_TARGET_GUEST_VERIFIED target=arm64-apple-ios26.0-simulator`** (run right after local_guest_verify: run alone after host git activity it stops at "OpenUIKit subtree is dirty" listing the 5 tracked symlinks — the container's view of the host index; the coordinator owns that) |
| Linux `swift:6.2-noble` (openrender, ConformanceApps, OpenUIKitTests) | green after the test fix |
| final gate: `CHECK_ONLY=1 agent_merge.sh agent/cg-unify-phase3` (1b8aa78d) | `124/124 scenes pass`, `GUEST_ROUTE_CHECK_OK`, Linux build, **`checks passed (CHECK_ONLY)`** |
| phase 4 gate: `CHECK_ONLY=1 agent_merge.sh agent/cg-unify-phase4` (286370f0) | `124/124 scenes pass`, `GUEST_ROUTE_CHECK_OK`, Linux build, **`checks passed (CHECK_ONLY)`**; `local_guest_verify.sh` on 286370f0: 14/14 byte-identical, `REAL-APP SCREEN VERIFIED ON LINUX`. `ios_guest.sh` on 286370f0 stopped before compiling at the container's "subtree is dirty" check (symlinks; then `machorun/tests/bin/.../libdup_link.dylib`); phase 4 changes no guest-compiled code (all under `canImport(CoreGraphics)` or the Foundation branch the guest does not take), and ios_guest passed on 747ef006 |
| render time, gate scenes (main binary vs phase 3, alternating) | 25.2 s / 20.2 s, 19.4 s / 15.8 s: no slowdown from the interposers |

## What stays on the port's own types, and why

* **Linux ELF and both Mach-O guests: everything** (Canvas-backed `CGContext`,
  `CanvasColor` as `CGColor`, the port's CGAffineTransform, CALayer family,
  CATransaction model, ImageIO module on Linux). No Apple CoreGraphics/QuartzCore
  exists at link or run time there (machorun has only the port's dylibs); the guest
  sysroot's QuartzCore interface cannot even build.
* **The renderer's value types on Apple toolchains:** `CanvasColor`, `Path`, `Bitmap`,
  `Canvas`. Apple's CGColor/CGPath/CGContext are the public face; the rasterizer is
  the port's (pixel identity).
* **ImageIO port module** (`OpenUIKitImageIO` on Darwin) is only for its own tests;
  apps get Apple's ImageIO.

## Risks / not done

* The interposers are process-global on CALayer/CATransaction: QuartzCore implicit
  actions are disabled for every layer in an OpenUIKit process, and CATransaction
  completion blocks run on the port's clock. Fine for the port's processes; an
  Apple-UI layer tree in the same process would lose implicit animation.
* `+[CATransaction completionBlock]` is not interposed (returning a Swift closure as
  a block there crashed Swift 6.2.1's release IRGen in an unrelated dispatch
  block, measured); it answers nil for blocks the port's model holds.
* The interposers call `MainActor.assumeIsolated`: Core Animation use off the main
  thread in an OpenUIKit process traps (it did in the port's own model too).
* CoreGraphics SPI `CGContextGetFillColorAsColor` / `CGContextGetStrokeColorAsColor`
  (exported, in the SDK `.tbd`) is how UIKit calls learn the context's colour.
* Clip sync from an app's CGContext to port drawing is the clip's bounding box
  (exact for rect clips); `UIBezierPath.addClip()` paths are applied exactly while
  CoreGraphics' clip box shows them active.
* Not rendered by the port yet (compiles and stores, as before): `CALayer.contents`,
  `CALayer.transform` on standalone layers, `CAShapeLayer` paths, non-basic
  animations (keyframe/group/spring are kept by QuartzCore, not sampled).
* UIImage orientation is stored, not applied to drawing.
* Stale SwiftPM build descriptions: a package built before these phases does not see
  the new files (`UIGraphicsCoreGraphics.swift`, `QuartzCoreUnification.swift`);
  delete `.build/*/debug/description.json` (measured). Delete stale `.build` after
  the type changes.
