// swift-tools-version:5.9
import Foundation
import PackageDescription

guard let openUIKitRoot = ProcessInfo.processInfo.environment["OPENUIKIT_PREVIEW_ROOT"] else {
    fatalError("OPENUIKIT_PREVIEW_ROOT is required")
}

let package = Package(
    name: "OpenUIKitPreviewProbe",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(name: "OpenUIKitUnderTest", path: openUIKitRoot),
    ],
    targets: [
        .target(
            name: "PreviewClient",
            dependencies: [
                .product(name: "UIKit", package: "OpenUIKitUnderTest"),
            ]
        ),
        .executableTarget(
            name: "PreviewRuntime",
            dependencies: [
                "PreviewClient",
                .product(name: "UIKit", package: "OpenUIKitUnderTest"),
                .product(name: "DeveloperToolsSupport", package: "OpenUIKitUnderTest"),
            ]
        ),
        .target(
            name: "NamedNegative",
            dependencies: [
                .product(name: "UIKit", package: "OpenUIKitUnderTest"),
            ]
        ),
        .target(
            name: "BodyNegative",
            dependencies: [
                .product(name: "UIKit", package: "OpenUIKitUnderTest"),
            ]
        ),
        .target(
            name: "SPINegative",
            dependencies: [
                .product(name: "UIKit", package: "OpenUIKitUnderTest"),
            ]
        ),
    ]
)
