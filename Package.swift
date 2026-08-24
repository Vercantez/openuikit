// swift-tools-version:5.9
import PackageDescription

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
        // CLI: renders scene JSON (docs/SCENE_SPEC.md) to PNG + layout dump.
        // May use Foundation (it is a tool, not the library).
        .executableTarget(name: "openrender", dependencies: ["OpenUIKit"]),
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
        .executableTarget(name: "openhost", dependencies: ["OpenUIKit", "CSDL2"]),
        .testTarget(name: "OpenUIKitTests", dependencies: ["OpenUIKit"]),
    ],
    cxxLanguageStandard: .cxx17
)
