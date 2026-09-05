// swift-tools-version:5.9
import CompilerPluginSupport
import Foundation
import PackageDescription

// Directory scan of Sources/ConformanceApps: every folder with a script.json
// is an app, and that JSON is a harness input (openhost --script / confprobe
// bundle), not a bundled resource. Replaces the hand-maintained exclude list
// that every app merge collided on. Same scan as scripts/gen_conformance_registry.sh.
let conformanceScriptExcludes: [String] = {
    let apps = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Sources/ConformanceApps")
    let fm = FileManager.default
    guard let items = try? fm.contentsOfDirectory(atPath: apps.path) else { return [] }
    return items.sorted().compactMap { name -> String? in
        if name.hasPrefix(".") { return nil }
        let dir = apps.appendingPathComponent(name)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }
        let script = dir.appendingPathComponent("script.json")
        guard fm.fileExists(atPath: script.path) else { return nil }
        return name + "/script.json"
    }
}()

// Manifest conditionals describe the machine evaluating Package.swift, not a
// `swift build --triple` destination. Keep the shim in the graph on every
// host, and select it at target-dependency resolution time for Linux only.
// Native Darwin SwiftUI therefore continues to compile against the SDK's
// first-party Combine module and never builds or links the shim.
let platformCombinePackages: [Package.Dependency] = [
    .package(
        url: "https://github.com/OpenCombine/OpenCombine.git",
        revision: "1c6f02c7ed8140c0ba7a783aaddb6e0685a0037b"
    ),
]
let previewMacroPackages: [Package.Dependency] = [
    // Swift 6.2's matching SwiftSyntax release. Pin the immutable revision,
    // not only the movable tag, because this code executes in the compiler.
    .package(
        url: "https://github.com/swiftlang/swift-syntax.git",
        revision: "4799286537280063c85a32f09884cfbca301b1a1"
    ),
]
let platformCombineTargets: [Target] = [
    .target(
        name: "Combine",
        dependencies: [
            .product(
                name: "OpenCombine",
                package: "OpenCombine",
                condition: .when(platforms: [.linux])
            ),
            .product(
                name: "OpenCombineDispatch",
                package: "OpenCombine",
                condition: .when(platforms: [.linux])
            ),
            .product(
                name: "OpenCombineFoundation",
                package: "OpenCombine",
                condition: .when(platforms: [.linux])
            ),
        ]
    ),
]
let swiftUICombineDependencies: [Target.Dependency] = [
    .target(name: "Combine", condition: .when(platforms: [.linux])),
]

// Linux 6.2.4 XCTest cannot invoke `@MainActor` SwiftUI test methods
// (discovery casts them to `() throws -> Void` and traps; linux-trial).
// Package.swift is evaluated on the build host: the Linux image compiles a
// stub; Darwin still compiles the full SwiftUITests tree.
#if os(Linux)
let swiftUITestTarget: Target = .testTarget(
    name: "SwiftUITests",
    dependencies: [
        "SwiftUI",
        "OpenUIKit",
        "Symbols",
        "DeveloperToolsSupport",
    ] + swiftUICombineDependencies,
    sources: ["SwiftUILinuxStub.swift"],
    swiftSettings: [
        .unsafeFlags([
            "-swift-version", "5",
            "-Xfrontend", "-strict-concurrency=minimal",
            "-Xfrontend", "-warn-concurrency",
        ], .when(platforms: [.linux])),
    ]
)
#else
let swiftUITestTarget: Target = .testTarget(
    name: "SwiftUITests",
    dependencies: [
        "SwiftUI",
        "OpenUIKit",
        "Symbols",
        "DeveloperToolsSupport",
    ] + swiftUICombineDependencies
)
#endif

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
        // Target-side metadata emitted by #Preview declaration expansions.
        .library(name: "DeveloperToolsSupport", targets: ["DeveloperToolsSupport"]),
        // Source-compatible first SwiftUI slice.  The public module name is
        // intentionally literal: unchanged app source keeps `import SwiftUI`.
        // Its renderer is backed by OpenUIKit rather than an Apple framework.
        .library(name: "SwiftUI", targets: ["SwiftUI"]),
        // SF Symbols effect values are a separate first-party framework on
        // Apple platforms. Keep that literal module boundary so unchanged
        // source can continue to `import Symbols`.
        .library(name: "Symbols", targets: ["Symbols"]),
        .library(name: "OpenCoreGraphics", targets: ["OpenCoreGraphics"]),
        .executable(name: "openrender", targets: ["openrender"]),
        .executable(name: "openhost", targets: ["openhost"]),
        // The C ABI an Objective-C app links against (docs/OBJC_FACADE.md).
        // Dynamic on purpose: the ObjC facade is built by clang against
        // libobjc2/gnustep-base, outside SPM, and links this .so.
        .library(name: "OpenUIKitC", type: .dynamic, targets: ["OpenUIKitC"]),
    ],
    dependencies: platformCombinePackages + previewMacroPackages,
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
        // The declaration macro executes on the build host even when UIKit is
        // being emitted for a different target triple.
        .macro(
            name: "OpenUIKitPreviewMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .macro(
            name: "OpenSwiftUIMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .target(name: "DeveloperToolsSupport"),
        // Build the replacement resiliently on Darwin too. AppKit's prebuilt
        // module references Apple's resilient Symbols ABI; matching that
        // convention prevents the compiler from trying to deserialize two
        // incompatible return conventions while host-testing this module.
        .target(
            name: "Symbols",
            swiftSettings: [.unsafeFlags(["-enable-library-evolution"])]
        ),
        // S1/S1.5 plus the first S2 observation/state slice. Keep this a
        // separate module so UIKit-only users do not acquire SwiftUI or
        // Combine symbols.
        .target(
            name: "SwiftUI",
            dependencies: [
                "OpenUIKit",
                "Symbols",
                "DeveloperToolsSupport",
                "OpenUIKitPreviewMacros",
                "OpenSwiftUIMacros",
            ] + swiftUICombineDependencies
        ),
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
        // A module named `UIKit` that re-exports OpenUIKit and owns narrowly
        // scoped compatibility overlays (identity aliases and #Preview), so
        // real-app source keeps its `import UIKit` line verbatim. See
        // Sources/UIKitShim/UIKit.swift.
        .target(
            name: "UIKit",
            dependencies: [
                "OpenUIKit",
                "DeveloperToolsSupport",
                "OpenUIKitPreviewMacros",
            ],
            path: "Sources/UIKitShim"
        ),
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
        // Focus Settings real-app screen: stub modules so
        // SettingsViewController.swift keeps its `import Glean` / `import
        // Intents` / … lines unmodified. Colours, strings and app types live
        // in FocusShims.swift (same module as the cells). Exclude the stub
        // sources from RealAppProbe so they are not compiled twice.
        .target(name: "Glean", path: "Sources/RealAppProbe/FocusModules/Glean"),
        .target(name: "Intents", path: "Sources/RealAppProbe/FocusModules/Intents"),
        .target(name: "IntentsUI",
                dependencies: ["Intents", "OpenUIKit"],
                path: "Sources/RealAppProbe/FocusModules/IntentsUI"),
        .target(name: "Onboarding", path: "Sources/RealAppProbe/FocusModules/Onboarding"),
        .target(name: "Licenses",
                dependencies: ["SwiftUI"],
                path: "Sources/RealAppProbe/FocusModules/Licenses"),
        // Focus Settings still `import DesignSystem`; SettingsViewController
        // names no DesignSystem types, so the Hackers stub (which re-exports
        // FocusDesignSystemStub) satisfies both screens. The empty Focus
        // DesignSystem.swift stays on disk unused.
        .target(name: "Domain",
                path: "Sources/RealAppProbe/HackersModules/Domain"),
        .target(name: "Shared",
                dependencies: [
                    "Domain", "OpenUIKit", "UIKit", "SwiftUI",
                    .target(name: "Combine", condition: .when(platforms: [.linux])),
                ],
                path: "Sources/RealAppProbe/HackersModules/Shared",
                // Package platforms is macOS 11; @Observable is 14+. The
                // Darwin probe compiles these against the iOS 26 SDK.
                swiftSettings: [.unsafeFlags(["-disable-availability-checking"])]),
        .target(name: "DesignSystem",
                dependencies: [
                    "Domain", "Shared", "SwiftUI", "OpenUIKit", "UIKit",
                ],
                path: "Sources/RealAppProbe/HackersModules/DesignSystem",
                swiftSettings: [.unsafeFlags(["-disable-availability-checking"])]),
        .target(name: "RealAppProbe",
                dependencies: [
                    "OpenUIKit", "UIKit",
                    "Glean", "Intents", "IntentsUI",
                    "Onboarding", "Licenses", "DesignSystem",
                    "Domain", "Shared",
                    "SwiftUI",
                    .target(name: "Combine", condition: .when(platforms: [.linux])),
                ],
                exclude: ["FocusModules", "HackersModules"],
                swiftSettings: [
                    .enableUpcomingFeature("IsolatedDefaultValues"),
                    .unsafeFlags([
                        "-default-isolation", "MainActor",
                        "-disable-availability-checking",
                    ]),
                ]),
        // CONFORMANCE APPS (docs/HILLCLIMB.md): small UIKit apps written the
        // way real apps are, whose source is compiled BOTH against OpenUIKit
        // (here, hosted by `openhost --app <name>`) and against real UIKit in
        // the iOS simulator (Tools/oracle2/confprobe), and whose scripted
        // replays are compared capture by capture
        // (scripts/conformance_flow.sh). Their only imports are UIKit and
        // Foundation — the `UIKit` shim re-exports both, exactly as real
        // UIKit's swiftinterface does — so the same bytes compile on the two
        // sides with no patching, unlike Sources/RealAppProbe.
        //
        // Registration is one table: ConformanceApps.registry, generated by
        // scripts/gen_conformance_registry.sh from a directory scan. The
        // exclude list is the same scan (conformanceScriptExcludes above).
        //
        // `-default-isolation MainActor` for the same reason RealAppProbe
        // carries it: that IS the build setting an Xcode 26 app target has,
        // and the simulator compile in scripts/conformance_probe_sim.sh
        // passes the identical flag.
        // Each app's script.json is a HARNESS input read from the repo path
        // (openhost --script, and copied into the probe bundle by
        // scripts/conformance_probe_sim.sh), not a bundled resource.
        .target(name: "ConformanceApps", dependencies: ["OpenUIKit", "UIKit"],
                exclude: conformanceScriptExcludes,
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
        .executableTarget(name: "openhost", dependencies: ["OpenUIKit", "CSDL2", "DemoApp", "RealAppProbe", "ConformanceApps"]),
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
        // UIKit is included so source-compatibility tests can use the exact
        // unchanged app import (`import UIKit`) rather than testing only the
        // implementation module's spelling.
        // Linux 6.2.4 XCTest discovers `(T) -> () throws -> Void`; `@MainActor`
        // on the class crashes that cast (linux-trial). Test classes drop the
        // attribute on Linux (see CoreAnimationCompatibilityTests). The
        // compiler's default isolation is Swift 6, so a nonisolated XCTestCase
        // cannot call `@preconcurrency @MainActor` UIKit without -swift-version 5.
        .testTarget(
            name: "OpenUIKitTests",
            dependencies: ["OpenUIKit", "UIKit", "ConformanceApps"],
            swiftSettings: [
                .unsafeFlags([
                    "-swift-version", "5",
                    "-Xfrontend", "-strict-concurrency=minimal",
                    "-Xfrontend", "-warn-concurrency",
                ], .when(platforms: [.linux])),
            ]
        ),
        swiftUITestTarget,
        .testTarget(
            name: "OpenUIKitCTests",
            dependencies: ["OpenUIKitC", "OpenUIKit", "COpenUIKitABI"],
            swiftSettings: [
                .unsafeFlags([
                    "-swift-version", "5",
                    "-Xfrontend", "-strict-concurrency=minimal",
                    "-Xfrontend", "-warn-concurrency",
                ], .when(platforms: [.linux])),
            ]
        ),
    ] + platformCombineTargets,
    cxxLanguageStandard: .cxx17
)
