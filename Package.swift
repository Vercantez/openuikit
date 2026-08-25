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
    products: [
        .library(name: "OpenUIKit", targets: ["OpenUIKit"]),
        .library(name: "OpenCoreGraphics", targets: ["OpenCoreGraphics"]),
        .executable(name: "openrender", targets: ["openrender"]),
        .executable(name: "openhost", targets: ["openhost"]),
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
        // rendering backend behind the same Canvas API. No Foundation, no
        // Apple frameworks.
        .target(name: "OpenCoreGraphics", dependencies: ["CQuartz"]),
        // The UIKit reimplementation. No Foundation, no Apple frameworks.
        .target(name: "OpenUIKit", dependencies: ["OpenCoreGraphics", "CSTBTrueType", "CPortableIO", "CQuartz"]),
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
        // Same no-Foundation rule as OpenUIKit itself: openrender links this
        // target, and Foundation's CoreGraphics types would clash with ours.
        .target(name: "RealAppProbe", dependencies: ["OpenUIKit", "UIKit"]),
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
        .testTarget(name: "OpenUIKitTests", dependencies: ["OpenUIKit"]),
    ],
    cxxLanguageStandard: .cxx17
)
