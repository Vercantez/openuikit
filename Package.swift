// swift-tools-version:5.9
import PackageDescription

// Selector target-action (docs/OBJC_RUNTIME.md) deliberately needs NOTHING
// here -- no swiftSettings, no linkerSettings, no `.when(platforms:)`:
//
//   * macOS gets `Selector` from `import ObjectiveC`, which is free.
//   * Linux gets OpenUIKit's own `Selector` struct; the library never emits
//     ObjC interop code, so there is no `-lobjc`, no shim target and no
//     frontend flag. (Enabling `-enable-objc-interop` on Linux is not an
//     option for reasons measured in Tools/objcshim/interop_limits.sh.)
//
// That matters for packaging: `.unsafeFlags` anywhere in a manifest makes the
// whole package unusable as an SPM *dependency*, so needing them would have
// forced the feature to be opt-in. It does not, and this package stays
// dependency-clean on both platforms.

let package = Package(
    name: "OpenUIKit",
    // Swift concurrency (`@MainActor`, which the UI classes now carry the
    // way real UIKit does) needs a 10.15+ deployment target on Darwin;
    // SwiftPM was already linking these products for macOS 11. Declaring
    // it makes that explicit instead of leaving it to the default.
    // Apple-only: it has no effect on the Linux build.
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "OpenUIKit", targets: ["OpenUIKit"]),
        // Literal import bridge for unchanged iOS source.  The target already
        // existed for in-package probes; publishing it also lets external
        // source-preservation probes keep `import UIKit` byte-for-byte.
        .library(name: "UIKit", targets: ["UIKit"]),
        // Source-compatible first SwiftUI slice.  The public module name is
        // intentionally literal: unchanged app source keeps `import SwiftUI`.
        // Its renderer is backed by OpenUIKit rather than an Apple framework.
        .library(name: "SwiftUI", targets: ["SwiftUI"]),
        .library(name: "OpenCoreGraphics", targets: ["OpenCoreGraphics"]),
        .executable(name: "openrender", targets: ["openrender"]),
        .executable(name: "openhost", targets: ["openhost"]),
        // The C ABI an Objective-C app links against (docs/OBJC_FACADE.md).
        // Dynamic on purpose: the ObjC facade is built by clang against
        // libobjc2/gnustep-base, outside SPM, and links this .so.
        .library(name: "OpenUIKitC", type: .dynamic, targets: ["OpenUIKitC"]),
    ],
    targets: [
        // Vendored stb_truetype (single-header C library, public domain).
        .target(name: "CSTBTrueType"),
        // Minimal libc file IO shim so OpenUIKit never needs Foundation.
        .target(name: "CPortableIO"),
        // Vendored quartz: portable Quartz 2D + CoreAnimation reimplementation
        // (C++17, C API QZ* mirroring CG*). Synced from ~/quartz by
        // scripts/sync_quartz.sh — do not edit by hand.
        // STBTT_STATIC + target-wide STB_TRUETYPE_IMPLEMENTATION keep quartz's
        // private stb_truetype copy at internal linkage so it cannot collide
        // with the CSTBTrueType target at link time.
        .target(
            name: "CQuartz",
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("include"),
                .define("STBTT_STATIC"),
                .define("STB_TRUETYPE_IMPLEMENTATION", to: ""),
            ]
        ),
        // Pure-Swift geometry + software rasterizer + PNG, plus the CQuartz
        // rendering backend behind the same Canvas API.
        //
        // M15: these two targets DO import Foundation now, so that CGRect,
        // CGFloat, IndexPath, NSRange and TimeInterval are Foundation's own
        // types instead of colliding rivals — that is what lets an app write
        // `import Foundation` next to `import OpenUIKit`
        // (docs/APP_COMPAT.md "M15", docs/PORTABILITY.md). The rule that
        // replaced "no Foundation" is the one that actually earns the
        // byte-identical Linux render: no wall clock, no locale and no random
        // source anywhere in the render or layout path, enforced by
        // Tests/OpenUIKitTests/FoundationCoexistenceTests.swift. No other
        // Apple framework is imported for its types.
        .target(name: "OpenCoreGraphics", dependencies: ["CQuartz"]),
        // The UIKit reimplementation. Same rule as above.
        .target(name: "OpenUIKit", dependencies: ["OpenCoreGraphics", "CSTBTrueType", "CPortableIO", "CQuartz"]),
        // S1/S1.5 is the stateless composition/hosting surface required by
        // Focus's widget and seven DesignSystem Swift files. Keep this a
        // separate module so UIKit-only users do not acquire SwiftUI symbols.
        .target(name: "SwiftUI", dependencies: ["OpenUIKit"]),
        // M7.5 demo app: a multi-screen Settings-style app written against
        // OpenUIKit exactly like a normal UIKit app (UIViewController
        // subclasses, addTarget actions, UIView.animate). Same rules as
        // OpenUIKit itself: no Foundation, no Apple frameworks — it is
        // reference material for what OpenUIKit app code looks like.
        // Hosted by `openhost --app demo` (docs/APP_FEEL.md).
        // One documented exception to the no-Foundation rule:
        // SelectorApp.swift's Darwin-only branch does
        // `import struct Foundation.Data`, which is what makes `@objc` legal
        // without a compiler flag. The Linux build of this target still
        // imports nothing but OpenUIKit.
        .target(name: "DemoApp", dependencies: ["OpenUIKit"]),
        // A module named `UIKit` that does nothing but `@_exported import
        // OpenUIKit`, so vendored real-app source can keep its `import UIKit`
        // line verbatim. See Sources/UIKitShim/UIKit.swift.
        .target(name: "UIKit", dependencies: ["OpenUIKit"], path: "Sources/UIKitShim"),
        // M14 real-app harness: UNMODIFIED source files lifted out of a
        // shipping open-source iOS app (Automattic/pocket-casts-ios), compiled
        // against OpenUIKit to measure how much of a real screen survives.
        // Everything that is not app source lives in Shims.swift and is
        // labelled there. Report: docs/REAL_APP_TEST.md.
        // M15: it imports Foundation now — through the `UIKit` shim, which
        // re-exports it exactly as real UIKit's swiftinterface does. That is
        // what let the app's `import Foundation` and its
        // `required init?(coder: NSCoder)` be restored verbatim, taking the
        // ledger from 14 changed lines to 9 (98.5 % unmodified).
        // M15: built with `-default-isolation MainActor`. This is NOT a
        // concession — it is the build setting a real iOS app target carries.
        // Xcode 26 / Swift 6.2 app targets default the whole module to
        // main-actor isolation ("Approachable Concurrency"), which is how
        // pocket-casts's own `class OptionsPicker` — no `@MainActor` on it —
        // legally creates and drives a main-actor-isolated UIViewController.
        // Mirroring the app's build configuration rather than editing the
        // app's source is what let the last `@MainActor` come off the vendored
        // files. Verified accepted by both toolchains in the gate (Apple
        // 6.2.1 and Linux 6.2.4).
        .target(name: "RealAppProbe", dependencies: ["OpenUIKit", "UIKit"],
                swiftSettings: [.unsafeFlags(["-default-isolation", "MainActor"])]),
        // CLI: renders scene JSON (docs/SCENE_SPEC.md) to PNG + layout dump.
        // May use Foundation (it is a tool, not the library).
        .executableTarget(name: "openrender", dependencies: ["OpenUIKit", "RealAppProbe"]),
        // SDL2 via pkg-config (brew install sdl2 on macOS, apt install
        // libsdl2-dev on Linux). System library — nothing vendored.
        .systemLibrary(
            name: "CSDL2",
            pkgConfig: "sdl2",
            providers: [.brew(["sdl2"]), .apt(["libsdl2-dev"])]
        ),
        // SDL2 live host: real-time interactive window + scripted-event
        // recorder for a scene JSON. Shares openrender's scene-building
        // code via symlinked sources (SceneBuilder.swift / SceneIO.swift,
        // see Sources/openhost/main.swift header); openrender itself stays
        // byte-identical.
        // May use Foundation (it is a host, like openrender).
        .executableTarget(name: "openhost", dependencies: ["OpenUIKit", "CSDL2", "DemoApp", "RealAppProbe"]),
        // The TYPES half of the C ABI (the ObjC callback vtable), shared by
        // the Swift side and the ObjC facade so its layout cannot drift.
        .target(name: "COpenUIKitABI", publicHeadersPath: "include"),
        // The C ABI half of the Objective-C bridge: @_cdecl entry points over
        // opaque handles. No @objc anywhere — Swift ObjC interop does not work
        // off Darwin (docs/OBJC_RUNTIME.md), and this target is how OpenUIKit
        // sidesteps that. Design + ownership rule: docs/OBJC_FACADE.md.
        .target(name: "OpenUIKitC",
                dependencies: ["OpenUIKit", "OpenCoreGraphics", "COpenUIKitABI", "CPortableIO"]),
        // The Swift twin of ObjCFacade/ProofApp.m: the same screen, built with
        // the Swift API, rendered through the same entry point. Its PNG is the
        // thing the ObjC app's PNG is diffed against
        // (scripts/objc_facade_verify.sh).
        // linkedLibrary (NOT unsafeFlags) so the package stays usable as an SPM
        // dependency, per this manifest's header. Needed because objcparity is
        // Foundation-free: nothing else on its link line drags in libm, which
        // the rasterizer's math calls need.
        .executableTarget(name: "objcparity",
                          dependencies: ["OpenUIKit", "OpenUIKitC", "CPortableIO"],
                          linkerSettings: [.linkedLibrary("m", .when(platforms: [.linux]))]),
        .testTarget(name: "OpenUIKitTests", dependencies: ["OpenUIKit"]),
        .testTarget(name: "SwiftUITests", dependencies: ["SwiftUI", "OpenUIKit"]),
        .testTarget(name: "OpenUIKitCTests",
                    dependencies: ["OpenUIKitC", "OpenUIKit", "COpenUIKitABI"]),
    ],
    cxxLanguageStandard: .cxx17
)
