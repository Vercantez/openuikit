// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OpenUIKit",
    products: [
        .library(name: "OpenUIKit", targets: ["OpenUIKit"]),
        .library(name: "OpenCoreGraphics", targets: ["OpenCoreGraphics"]),
        .executable(name: "openrender", targets: ["openrender"]),
    ],
    targets: [
        // Vendored stb_truetype (single-header C library, public domain).
        .target(name: "CSTBTrueType"),
        // Minimal libc file IO shim so OpenUIKit never needs Foundation.
        .target(name: "CPortableIO"),
        // Pure-Swift geometry + software rasterizer + PNG. No Foundation, no Apple frameworks.
        .target(name: "OpenCoreGraphics"),
        // The UIKit reimplementation. No Foundation, no Apple frameworks.
        .target(name: "OpenUIKit", dependencies: ["OpenCoreGraphics", "CSTBTrueType", "CPortableIO"]),
        // CLI: renders scene JSON (docs/SCENE_SPEC.md) to PNG + layout dump.
        // May use Foundation (it is a tool, not the library).
        .executableTarget(name: "openrender", dependencies: ["OpenUIKit"]),
        .testTarget(name: "OpenUIKitTests", dependencies: ["OpenUIKit"]),
    ]
)
