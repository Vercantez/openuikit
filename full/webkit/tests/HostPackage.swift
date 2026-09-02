// swift-tools-version: 5.9
import Foundation
import PackageDescription

guard let openUIKitSource = ProcessInfo.processInfo.environment["OPENUIKIT_SOURCE"],
      !openUIKitSource.isEmpty
else {
    fatalError("OPENUIKIT_SOURCE must name the pinned OpenUIKit package")
}

let package = Package(
    name: "PortableWebKitHostGate",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "WebKit", type: .dynamic, targets: ["WebKit"]),
        .library(name: "HackersWebKitSurface", targets: ["HackersWebKitSurface"]),
        .executable(name: "WebKitHostRuntime", targets: ["WebKitHostRuntime"]),
    ],
    dependencies: [
        .package(name: "OpenUIKitSource", path: openUIKitSource),
    ],
    targets: [
        .target(
            name: "WebKit",
            dependencies: [
                .product(name: "OpenUIKit", package: "OpenUIKitSource"),
            ],
            swiftSettings: [
                .define("PORTABLE_WEBKIT_HOST"),
                .unsafeFlags(["-warnings-as-errors"]),
            ]
        ),
        .executableTarget(
            name: "WebKitHostRuntime",
            dependencies: ["WebKit"],
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"]),
            ]
        ),
        .target(
            name: "HackersWebKitSurface",
            dependencies: ["WebKit"],
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"]),
            ]
        ),
    ]
)
