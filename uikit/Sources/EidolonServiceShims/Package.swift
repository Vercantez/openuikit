// swift-tools-version: 5.9
import PackageDescription

// Standalone verification package. The monorepo may declare the same four
// targets at their explicit child paths without adopting a package pin.
let package = Package(
    name: "EidolonServiceShims",
    products: [
        .library(name: "Keys", targets: ["Keys"]),
        .library(name: "ARAnalytics", targets: ["ARAnalytics"]),
        .library(name: "Stripe", targets: ["Stripe"]),
        .library(name: "EidolonLaunchCompat", targets: ["EidolonLaunchCompat"]),
    ],
    targets: [
        .target(name: "Keys", path: "Keys"),
        .target(name: "ARAnalytics", path: "ARAnalytics"),
        .target(name: "Stripe", path: "Stripe"),
        .target(name: "EidolonLaunchCompat", dependencies: ["Keys"], path: "EidolonLaunchCompat"),
        .testTarget(name: "EidolonServiceShimTests", dependencies: ["Keys", "ARAnalytics", "Stripe", "EidolonLaunchCompat"]),
    ]
)
