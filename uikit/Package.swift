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

// Linux-only C target that pumps corelibs XCTest's CFRunLoop so the ink
// and selector lists do not stall in awaitUsingExpectation → ppoll
// (swift-corelibs-xctest#504). MEASURED uikit-linux Swift 6.2.4: ink 3/5
// hung at timeout 20 s; 10 ms non-main DISPATCH_SOURCE_TYPE_TIMER +
// dispatch_async_f onto _dispatch_main_q made ink 20/20 and selector 20/20
// (docs/agent_reports/linux-xctest.md). Empty on Darwin so the test count
// is unchanged. Package.swift is evaluated on the build host.
#if os(Linux)
let linuxXCTestSupportTargets: [Target] = [
    .target(name: "CLinuxXCTestSupport", publicHeadersPath: "include"),
    // SnapKit 5.7.0 LayoutConstraintItem.swift:82 associated objects.
    // Darwin UIKit @_exported-imports SDK ObjectiveC; native ELF has none.
    // Named OpenUIKitObjectiveC so `canImport(ObjectiveC)` stays false in
    // OpenUIKit (a target named ObjectiveC made @objc branches compile
    // with ObjC interop disabled — MEASURED swift:6.2-noble openrender).
    .target(name: "OpenUIKitObjectiveC", path: "Sources/ObjectiveC"),
    .systemLibrary(
        name: "CLibXML2",
        path: "Sources/CLibXML2",
        pkgConfig: "libxml-2.0",
        providers: [.apt(["libxml2-dev"]), .brew(["libxml2"])]
    ),
]
let openUIKitTestDeps: [Target.Dependency] = [
    "OpenUIKit", "UIKit", "ConformanceApps",
    "SafariServices", "MessageUI", "LinkPresentation", "PhotosUI",
    "CLinuxXCTestSupport",
]
let openUIKitCTestDeps: [Target.Dependency] = [
    "OpenUIKitC", "OpenUIKit", "COpenUIKitABI",
    "CLinuxXCTestSupport",
]
let swiftUITestLinuxDeps: [Target.Dependency] = [
    "CLinuxXCTestSupport",
]
#else
let linuxXCTestSupportTargets: [Target] = []
let openUIKitTestDeps: [Target.Dependency] = [
    "OpenUIKit", "UIKit", "ConformanceApps",
    "SafariServices", "MessageUI", "LinkPresentation", "PhotosUI",
]
let openUIKitCTestDeps: [Target.Dependency] = [
    "OpenUIKitC", "OpenUIKit", "COpenUIKitABI",
]
let swiftUITestLinuxDeps: [Target.Dependency] = []
#endif

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
    ] + swiftUICombineDependencies + swiftUITestLinuxDeps,
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

// Literal Apple framework names on Linux so ladder apps keep `import ImageIO`
// / `import CoreImage` / `import StoreKit`. The same target names on Darwin
// shadow the SDK modules and break XCTest (XCUIAutomation then fails looking
// up CQuartz through our ImageIO). Darwin builds the port under OpenUIKit*
// names; tests import those.
#if os(Linux)
let imageIOModule = "ImageIO"
let coreImageModule = "CoreImage"
let storeKitModule = "StoreKit"
let libkernModule = "libkern"
let uiKitLinuxDependencies: [Target.Dependency] = ["OpenUIKitObjectiveC"]
let fuziLinuxDependencies: [Target.Dependency] = ["CLibXML2"]
// Clang submodules `os.log` / `os.signpost` so `import os.log` resolves
// (focus-e2e: a SwiftPM target named "os.log" compiles as os_log). Darwin
// keeps the SDK os module; publicHeadersPath here would shadow it.
let osTarget: Target = .target(name: "os", publicHeadersPath: "include")
// SnapKit 5.7.0 Debugging.swift:153 `type(of: object).description()` —
// Darwin AnyObject is NSObject (`+description`); Linux AnyObject.Type has
// no such member (MEASURED swift:6.2-noble). Sources stay unmodified.
// PrivacyInfo.xcprivacy is not Swift (focus-launch Darwin SnapKit exclude).
let snapKitExclude = ["LICENSE", "VENDOR.txt", "Debugging.swift", "PrivacyInfo.xcprivacy"]
let onboardingPath = "Sources/RealAppProbe/FocusModules/Onboarding"
let onboardingDeps: [Target.Dependency] = [
    .target(name: "Combine", condition: .when(platforms: [.linux])),
]
let onboardingExclude: [String] = []
let blockzillaRealAppDeps: [Target.Dependency] = []
#else
let imageIOModule = "OpenUIKitImageIO"
let coreImageModule = "OpenUIKitCoreImage"
let storeKitModule = "OpenUIKitStoreKit"
let libkernModule = "OpenUIKitLibkern"
let uiKitLinuxDependencies: [Target.Dependency] = []
let fuziLinuxDependencies: [Target.Dependency] = []
let osTarget: Target = .target(name: "os")
let snapKitExclude = ["LICENSE", "VENDOR.txt", "PrivacyInfo.xcprivacy"]
// Real BlockzillaPackage Onboarding (21 files, SnapKit + Widget).
// Linux / guest keep FocusModules handlers (no SnapKit).
let onboardingPath = "Sources/BlockzillaPackage/Onboarding"
let onboardingDeps: [Target.Dependency] = [
    "SnapKit", "DesignSystem", "Widget", "OpenUIKit", "UIKit", "SwiftUI",
]
let onboardingExclude: [String] = ["Preview Files"]
let blockzillaRealAppDeps: [Target.Dependency] = ["Blockzilla"]
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

// Swift 6.2 cannot type-check one Package(products:targets:) literal of this
// size in reasonable time. Measured on the keep-both of agent/silent-frameworks
// onto main after Combine/os products and SafariServices/MessageUI/
// LinkPresentation + Present: `Package.swift:137: error: the compiler is
// unable to type-check this expression in reasonable time` on macOS and on
// Linux swift:6.2-noble (corelibs is where the timeout first bit). Named
// [Product]/[Target] arrays type-check in seconds on both.

let coreProducts: [Product] = [
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
    // Combine is a product so an ingested SwiftPM package can
    // `import Combine` on Linux (17/20 ladder apps; 357 files under
    // local Package.swift trees, scratch/ladder-corpus 2026-09-05,
    // docs/agent_reports/combine-product.md; MEASURED focus-ios
    // a2832521 Blockzilla: 15 files, AppDelegate.swift:8,
    // docs/agent_reports/focus-e2e.md). Darwin dependents keep the
    // SDK module via
    // `.product(..., condition: .when(platforms: [.linux]))`.
    .library(name: "Combine", targets: ["Combine"]),
    // Logger / OSLog / os_log / OSAllocatedUnfairLock / os_signpost.
    // 13/20 ladder apps `import os` (202 files); call shapes in
    // Sources/os/*.swift. Darwin dependents keep the SDK `os` the
    // same way Combine does (docs/agent_reports/combine-product.md).
    .library(name: "os", targets: ["os"]),
    .executable(name: "openrender", targets: ["openrender"]),
    .executable(name: "openhost", targets: ["openhost"]),
    // The C ABI an Objective-C app links against (docs/OBJC_FACADE.md).
    // Dynamic on purpose: the ObjC facade is built by clang against
    // libobjc2/gnustep-base, outside SPM, and links this .so.
    .library(name: "OpenUIKitC", type: .dynamic, targets: ["OpenUIKitC"]),
]

let frameworkProducts: [Product] = [
    .library(name: storeKitModule, targets: [storeKitModule]),
    .library(name: imageIOModule, targets: [imageIOModule]),
    .library(name: coreImageModule, targets: [coreImageModule]),
    // Presentable first-party frameworks. Literal module names so
    // unchanged app source keeps `import SafariServices` /
    // `import MessageUI` / `import LinkPresentation`.
    .library(name: "SafariServices", targets: ["SafariServices"]),
    .library(name: "MessageUI", targets: ["MessageUI"]),
    .library(name: "LinkPresentation", targets: ["LinkPresentation"]),
    .library(name: "PhotosUI", targets: ["PhotosUI"]),
    // Harness stubs RealAppProbe already compiles (Focus Settings).
    // Publishing them lets an ingested Blockzilla `import Glean` on
    // Linux without a second target of the same name (SwiftPM refuses
    // Glean/Intents/Onboarding/Licenses/DesignSystem in both packages;
    // MEASURED focus-e2e wave1). Darwin dependents keep linux-only
    // `.product(..., condition: .when(platforms: [.linux]))`. These
    // are not Mozilla Glean / the SDK Intents framework.
    .library(name: "Glean", targets: ["Glean"]),
    .library(name: "Intents", targets: ["Intents"]),
    .library(name: "IntentsUI", targets: ["IntentsUI"]),
    .library(name: "Onboarding", targets: ["Onboarding"]),
    .library(name: "Licenses", targets: ["Licenses"]),
    .library(name: "DesignSystem", targets: ["DesignSystem"]),
    // Focus a2832521: SnapKit 5.7.0 e74fe2a, sentry-cocoa 8.20.0, Fuzi 3.1.3,
    // libkern atomics (focus-deps). Darwin-only Blockzilla still depends on
    // this SnapKit — one copy, not the launch Darwin-only duplicate.
    // Launch adds FocusAppServices / LocalAuthentication / PassKit / Network.
    .library(name: "SnapKit", targets: ["SnapKit"]),
    .library(name: "Sentry", targets: ["Sentry"]),
    .library(name: "Fuzi", targets: ["Fuzi"]),
    .library(name: libkernModule, targets: [libkernModule]),
    .library(name: "FocusAppServices", targets: ["FocusAppServices"]),
    .library(name: "LocalAuthentication", targets: ["LocalAuthentication"]),
    .library(name: "PassKit", targets: ["PassKit"]),
    .library(name: "Network", targets: ["Network"]),
]

let coreTargets: [Target] = [
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
        ] + uiKitLinuxDependencies,
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
    .target(name: "Glean",
            dependencies: ["OpenUIKit", "UIKit"],
            path: "Sources/RealAppProbe/FocusModules/Glean"),
    .target(name: "Intents",
            dependencies: ["OpenUIKit", "UIKit"],
            path: "Sources/RealAppProbe/FocusModules/Intents"),
    .target(name: "IntentsUI",
            dependencies: ["Intents", "OpenUIKit"],
            path: "Sources/RealAppProbe/FocusModules/IntentsUI"),
    .target(name: "Onboarding",
            dependencies: onboardingDeps,
            path: onboardingPath,
            exclude: onboardingExclude),
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
            ] + blockzillaRealAppDeps,
            exclude: ["FocusModules", "HackersModules", "Focus/script.json"],
            swiftSettings: [
                .enableUpcomingFeature("IsolatedDefaultValues"),
                .unsafeFlags([
                    "-default-isolation", "MainActor",
                    "-disable-availability-checking",
                ]),
            ]),
]

let frameworkTargets: [Target] = [
    // Fail-closed StoreKit, portable ImageIO (PNG/JPEG via CQuartz), and
    // CoreImage (CIGaussianBlur on the quartz 3-box Gaussian). Linux apps
    // `import StoreKit` / `import ImageIO` / `import CoreImage` against
    // these products; Darwin tests that do not depend on them still see
    // the SDK modules.
    .target(
        name: imageIOModule,
        dependencies: ["OpenCoreGraphics", "CQuartz"],
        path: "Sources/ImageIO"
    ),
    .target(
        name: coreImageModule,
        dependencies: ["OpenCoreGraphics", .target(name: imageIOModule), "CQuartz"],
        path: "Sources/CoreImage"
    ),
    .target(
        name: storeKitModule,
        dependencies: ["OpenUIKit"],
        path: "Sources/StoreKit"
    ),
    .target(
        name: "SafariServices",
        dependencies: ["OpenUIKit", "UIKit"]
    ),
    .target(
        name: "MessageUI",
        dependencies: ["OpenUIKit", "UIKit"]
    ),
    .target(
        name: "LinkPresentation",
        dependencies: ["OpenUIKit", "UIKit"]
    ),
    .target(
        name: "PhotosUI",
        dependencies: ["OpenUIKit", "UIKit"]
    ),
    osTarget,
    // Unmodified SnapKit 5.7.0 (e74fe2a). One copy: focus-deps's target
    // (Linux excludes Debugging.swift) plus focus-launch's
    // PrivacyInfo.xcprivacy exclude. `import UIKit` is OpenUIKit's UIKit
    // product so `canImport(UIKit)` is true on macOS too.
    .target(
        name: "SnapKit",
        dependencies: ["UIKit", "OpenUIKit"],
        exclude: snapKitExclude
    ),
    .target(name: "Sentry"),
    .target(
        name: "Fuzi",
        dependencies: fuziLinuxDependencies,
        exclude: ["LICENSE", "VENDOR.txt"],
        linkerSettings: [.linkedLibrary("xml2", .when(platforms: [.linux]))]
    ),
    .target(
        name: libkernModule,
        path: "Sources/libkern"
    ),
    .target(name: "FocusAppServices"),
    .target(
        name: "LocalAuthentication",
        dependencies: [
            "OpenUIKit", "UIKit",
            .target(name: "Combine", condition: .when(platforms: [.linux])),
        ],
        path: "Sources/LocalAuthentication"
    ),
    .target(
        name: "PassKit",
        dependencies: ["OpenUIKit", "UIKit"]
    ),
    .target(name: "Network"),
]

let conformanceTargets: [Target] = [
    // CONFORMANCE APPS (docs/HILLCLIMB.md): small UIKit apps written the
    // way real apps are, whose source is compiled BOTH against OpenUIKit
    // (here, hosted by `openhost --app <name>`) and against real UIKit in
    // the iOS simulator (Tools/oracle2/confprobe), and whose scripted
    // replays are compared capture by capture
    // (scripts/conformance_flow.sh). Imports are UIKit (which re-exports
    // Foundation, as real UIKit's swiftinterface does) plus the first-
    // party modules an app would import — Present also imports
    // SafariServices, MessageUI, and LinkPresentation. The same bytes
    // compile on the two sides with no patching, unlike Sources/RealAppProbe.
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
    .target(name: "ConformanceApps",
            dependencies: ["OpenUIKit", "UIKit", "SafariServices", "MessageUI", "LinkPresentation"],
            exclude: conformanceScriptExcludes,
            swiftSettings: [.unsafeFlags(["-default-isolation", "MainActor"])]),
    // CLI: renders scene JSON (docs/SCENE_SPEC.md) to PNG + layout dump.
    // May use Foundation (it is a tool, not the library).
    .executableTarget(
        name: "openrender",
        dependencies: ["OpenUIKit", "RealAppProbe", "os"],
        exclude: ["Info.plist"],
        linkerSettings: [
            // MEASURED mozilla-mobile/focus-ios a2832521 AppInfo /
            // NimbusExtensions force-unwrap CFBundleName, CFBundlePackageType,
            // CFBundleShortVersionString, NimbusAppName, NimbusAppChannel
            // (Blockzilla/Shared/AppInfo.swift:21-62, NimbusExtensions.swift:43).
            .unsafeFlags([
                "-Xlinker", "-sectcreate",
                "-Xlinker", "__TEXT",
                "-Xlinker", "__info_plist",
                "-Xlinker", URL(fileURLWithPath: #filePath)
                    .deletingLastPathComponent()
                    .appendingPathComponent("Sources/openrender/Info.plist")
                    .path,
            ], .when(platforms: [.macOS])),
        ]
    ),
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
    .executableTarget(name: "openhost", dependencies: ["OpenUIKit", "CSDL2", "DemoApp", "RealAppProbe", "ConformanceApps", "os"]),
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
]

let testTargets: [Target] = [
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
        dependencies: openUIKitTestDeps,
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
        dependencies: openUIKitCTestDeps,
        swiftSettings: [
            .unsafeFlags([
                "-swift-version", "5",
                "-Xfrontend", "-strict-concurrency=minimal",
                "-Xfrontend", "-warn-concurrency",
            ], .when(platforms: [.linux])),
        ]
    ),
    .testTarget(
        name: "StoreKitTests",
        dependencies: [.target(name: storeKitModule), "OpenUIKit"],
        swiftSettings: [
            .unsafeFlags([
                "-swift-version", "5",
                "-Xfrontend", "-strict-concurrency=minimal",
                "-Xfrontend", "-warn-concurrency",
            ], .when(platforms: [.linux])),
        ]
    ),
    .testTarget(
        name: "ImageIOTests",
        dependencies: [.target(name: imageIOModule), "OpenCoreGraphics"],
        swiftSettings: [
            .unsafeFlags([
                "-swift-version", "5",
                "-Xfrontend", "-strict-concurrency=minimal",
                "-Xfrontend", "-warn-concurrency",
            ], .when(platforms: [.linux])),
        ]
    ),
    .testTarget(
        name: "CoreImageTests",
        dependencies: [
            .target(name: coreImageModule),
            .target(name: imageIOModule),
            "OpenCoreGraphics",
        ],
        swiftSettings: [
            .unsafeFlags([
                "-swift-version", "5",
                "-Xfrontend", "-strict-concurrency=minimal",
                "-Xfrontend", "-warn-concurrency",
            ], .when(platforms: [.linux])),
        ]
    ),
    .testTarget(
        name: "OSTests",
        dependencies: ["os"],
        swiftSettings: [
            .unsafeFlags([
                "-swift-version", "5",
                "-Xfrontend", "-strict-concurrency=minimal",
                "-Xfrontend", "-warn-concurrency",
            ], .when(platforms: [.linux])),
        ]
    ),
    .testTarget(
        name: "SnapKitOpenUIKitTests",
        dependencies: ["SnapKit", "UIKit", "OpenUIKit"],
        swiftSettings: [
            .unsafeFlags([
                "-swift-version", "5",
                "-Xfrontend", "-strict-concurrency=minimal",
                "-Xfrontend", "-warn-concurrency",
            ], .when(platforms: [.linux])),
            .unsafeFlags([
                "-swift-version", "5",
                "-default-isolation", "MainActor",
            ], .when(platforms: [.macOS])),
        ]
    ),
    .testTarget(
        name: "GleanTests",
        dependencies: ["Glean"],
        swiftSettings: [
            .unsafeFlags([
                "-swift-version", "5",
                "-Xfrontend", "-strict-concurrency=minimal",
                "-Xfrontend", "-warn-concurrency",
            ], .when(platforms: [.linux])),
        ]
    ),
    .testTarget(
        name: "SentryTests",
        dependencies: ["Sentry"],
        swiftSettings: [
            .unsafeFlags([
                "-swift-version", "5",
                "-Xfrontend", "-strict-concurrency=minimal",
                "-Xfrontend", "-warn-concurrency",
            ], .when(platforms: [.linux])),
        ]
    ),
    .testTarget(
        name: "LibkernTests",
        dependencies: [.target(name: libkernModule)],
        swiftSettings: [
            .unsafeFlags([
                "-swift-version", "5",
                "-Xfrontend", "-strict-concurrency=minimal",
                "-Xfrontend", "-warn-concurrency",
            ], .when(platforms: [.linux])),
        ]
    ),
    .testTarget(
        name: "FuziTests",
        dependencies: ["Fuzi"],
        swiftSettings: [
            .unsafeFlags([
                "-swift-version", "5",
                "-Xfrontend", "-strict-concurrency=minimal",
                "-Xfrontend", "-warn-concurrency",
            ], .when(platforms: [.linux])),
        ]
    ),
]

#if os(Linux)
let blockzillaProducts: [Product] = []
let blockzillaTargets: [Target] = []
#else
let blockzillaProducts: [Product] = [
    .library(name: "Blockzilla", targets: ["Blockzilla"]),
    // MEASURED ShortcutView.swift:103 `#selector(didTap)` — Linux corelibs
    // cannot compile it (focus-e2e.md). Darwin-only with Blockzilla.
    .library(name: "AppShortcuts", targets: ["AppShortcuts"]),
    // SnapKit lives in frameworkProducts (one copy, both platforms).
    // UIHelpers ImageLoader.swift:29 URLRequest is FoundationNetworking
    // on Linux and this is Focus source we do not patch.
    .library(name: "WebKit", targets: ["WebKit"]),
    .library(name: "UIHelpers", targets: ["UIHelpers"]),
    .library(name: "UIComponents", targets: ["UIComponents"]),
]
let blockzillaTargets: [Target] = [
    .target(
        name: "WebKit",
        dependencies: ["OpenUIKit", "UIKit"],
        swiftSettings: [.unsafeFlags(["-disable-availability-checking"])]
    ),
    .target(
        name: "UIHelpers",
        dependencies: ["OpenUIKit", "UIKit"],
        path: "Sources/BlockzillaPackage/UIHelpers",
        swiftSettings: [.unsafeFlags(["-disable-availability-checking"])]
    ),
    .target(
        name: "UIComponents",
        dependencies: ["UIHelpers", "OpenUIKit", "UIKit"],
        path: "Sources/BlockzillaPackage/UIComponents",
        swiftSettings: [.unsafeFlags(["-disable-availability-checking"])]
    ),
    .target(
        name: "Widget",
        dependencies: ["SwiftUI"],
        path: "Sources/BlockzillaPackage/Widget",
        swiftSettings: [.unsafeFlags(["-disable-availability-checking"])]
    ),
    .target(
        name: "AppShortcuts",
        dependencies: [
            "UIComponents", "DesignSystem", "OpenUIKit", "UIKit",
        ],
        path: "Sources/BlockzillaPackage/AppShortcuts",
        swiftSettings: [.unsafeFlags(["-disable-availability-checking"])]
    ),
    // mozilla-mobile/focus-ios a2832521 Blockzilla (129 present sources).
    // Darwin-only: #selector is a Linux corelibs wall (focus-e2e.md).
    .target(
        name: "Blockzilla",
        dependencies: [
            "OpenUIKit", "UIKit", "SwiftUI",
            "SnapKit", "WebKit", "Glean", "Sentry", "Fuzi",
            "FocusAppServices", "Onboarding", "AppShortcuts",
            "UIHelpers", "DesignSystem", "Licenses",
            "Intents", "IntentsUI", "LocalAuthentication",
            "SafariServices", "PassKit",
            // MEASURED debug `swift test`: NimbusWrapper.swift:5
            // `import os.log` compiled against this package's `os`
            // product (`_$s2os5OSLogV9subsystem8categoryACSS_SStcfC` matches
            // Sources/os/OSLog.swift.o) but the executable did not link
            // it. Apple's libswiftos does not define that struct init.
            "os",
            // MEASURED agent_merge.sh (fresh worktree, release openrender
            // then `swift build --build-tests`): URLExtensions.swift:6
            // `import Network` + :317 `IPv4Address(host)` compiled against
            // this package's Network product (Sources/Network/Network.swift
            // was built at [139/247]) but Blockzilla did not depend on it,
            // so debug openrender/openhost failed to link
            // `Network.IPv4Address.init(String)` /
            // `Network.IPv6Address.init(String)` (merge_focus46-merged.log,
            // merge_focus2m-merged.log). Same class as `os` above.
            // `--product openrender` alone never built the Network target,
            // so `import Network` hit Apple's framework and autolinked.
            "Network",
            .target(name: storeKitModule),
        ],
        path: "Sources/Blockzilla",
        swiftSettings: [
            .enableUpcomingFeature("IsolatedDefaultValues"),
            .unsafeFlags([
                "-default-isolation", "MainActor",
                "-disable-availability-checking",
                "-module-alias", "StoreKit=\(storeKitModule)",
            ]),
        ],
    ),
]
#endif

// Simplenote 9b1bb17 dependency census: 30 unchanged Swift sources at the
// five pins in Sources/SimplenoteDependencies/PROVENANCE.json. Darwin route
// (b) only: Foundation uses CoreData/AppKit; Gridicons has @objc factories.
// This does not claim a guest CoreData port or an app launch.
#if os(Linux)
let simplenoteProducts: [Product] = []
let simplenoteTargets: [Target] = []
#else
let simplenoteProducts: [Product] = [
    "SimplenoteFoundation", "SimplenoteEndpoints", "SimplenoteInterlinks",
    "SimplenoteSearch", "Gridicons", "Simperium", "AutomatticTracks",
    "AutomatticTracksModelObjC",
].map { .library(name: $0, targets: [$0]) }
let simplenoteSettings: [SwiftSetting] = [
    .unsafeFlags(["-default-isolation", "MainActor", "-disable-availability-checking"]),
]
let simplenoteTargets: [Target] = [
    .target(name: "Simperium", path: "Sources/Simperium", publicHeadersPath: "include/Simperium"),
    .target(name: "AutomatticTracksModelObjC", path: "Sources/AutomatticTracksModelObjC", publicHeadersPath: "include"),
    .target(name: "AutomatticTracks", dependencies: ["AutomatticTracksModelObjC"], path: "Sources/AutomatticTracks", swiftSettings: simplenoteSettings),
    .target(name: "SimplenoteFoundation", dependencies: ["UIKit"],
            path: "Sources/SimplenoteDependencies/SimplenoteFoundation",
            swiftSettings: simplenoteSettings),
    .target(name: "SimplenoteEndpoints",
            path: "Sources/SimplenoteDependencies/SimplenoteEndpoints",
            swiftSettings: simplenoteSettings),
    .target(name: "SimplenoteInterlinks", dependencies: ["SimplenoteFoundation"],
            path: "Sources/SimplenoteDependencies/SimplenoteInterlinks",
            swiftSettings: simplenoteSettings),
    .target(name: "SimplenoteSearch",
            path: "Sources/SimplenoteDependencies/SimplenoteSearch",
            swiftSettings: simplenoteSettings),
    .target(name: "Gridicons", dependencies: ["UIKit", "SwiftUI"],
            path: "Sources/SimplenoteDependencies/Gridicons",
            resources: [.copy("Resources")],
            swiftSettings: simplenoteSettings),
]
#endif

let package = Package(
    name: "OpenUIKit",
    // Swift concurrency (`@MainActor`, which the UI classes now carry the
    // way real UIKit does) needs a 10.15+ deployment target on Darwin;
    // SwiftPM was already linking these products for macOS 11. Declaring
    // it makes that explicit instead of leaving it to the default.
    // Apple-only: it has no effect on the Linux build.
    platforms: [.macOS(.v11)],
    products: coreProducts + frameworkProducts + blockzillaProducts + simplenoteProducts,
    dependencies: platformCombinePackages + previewMacroPackages,
    targets: coreTargets + frameworkTargets + conformanceTargets + testTargets + platformCombineTargets + linuxXCTestSupportTargets + blockzillaTargets + simplenoteTargets,
    cxxLanguageStandard: .cxx17
)
