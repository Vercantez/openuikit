// swift-tools-version:5.9
// Reproduces the wall measured in docs/agent_reports/objc-impl-chain1.md:
// a Swift class two levels below an `@objc @implementation` class that
// adopts NSCoding cannot declare a designated initializer.
import PackageDescription

let package = Package(
    name: "required_init_probe",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "ProbeHeader", path: "Sources/ProbeHeader"),
        .target(name: "ProbeImpl", dependencies: ["ProbeHeader"], path: "Sources/ProbeImpl"),
        // The grandchild in ANOTHER module fails the same way (an app's view class).
        .target(name: "ProbeClient", dependencies: ["ProbeHeader", "ProbeImpl"], path: "Sources/ProbeClient"),
    ]
)
