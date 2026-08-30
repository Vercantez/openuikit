// swift-tools-version: 5.9
import Foundation
import PackageDescription

guard let openUIKitSource = ProcessInfo.processInfo.environment["OPENUIKIT_SOURCE"],
      !openUIKitSource.isEmpty
else {
    fatalError("OPENUIKIT_SOURCE must name the pinned OpenUIKit package")
}

let frameworkNames = [
    "LocalAuthentication", "SafariServices", "Network", "StoreKit",
    "AudioToolbox", "CoreHaptics", "PassKit",
]

let package = Package(
    name: "PortableFirstPartyFrameworkHostGate",
    platforms: [.macOS(.v13)],
    products: frameworkNames.map {
        .library(name: $0, type: .dynamic, targets: [$0])
    },
    dependencies: [
        .package(name: "OpenUIKitSource", path: openUIKitSource),
    ],
    targets: frameworkNames.map { name in
        let needsUIKit = ["SafariServices", "StoreKit", "PassKit"].contains(name)
        return .target(
            name: name,
            dependencies: needsUIKit
                ? [
                    .product(name: "OpenUIKit", package: "OpenUIKitSource"),
                ]
                : []
        )
    }
)
