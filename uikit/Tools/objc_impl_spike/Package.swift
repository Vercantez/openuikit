// swift-tools-version:5.9
// Bounded measurement: can an OpenUIKit-shaped class be declared in an
// Objective-C header and implemented in Swift with `@objc @implementation`,
// so that Objective-C code can subclass it? See
// docs/agent_reports/objc-implementation-spike.md.
import PackageDescription

let package = Package(
    name: "objc_impl_spike",
    platforms: [.macOS(.v14), .iOS(.v17)],
    targets: [
        // The Objective-C declaration of the class (header only).
        .target(name: "OUIProbeHeader", path: "Sources/OUIProbeHeader"),
        // The Swift implementation of that class, plus Swift-only extensions
        // and a Swift subclass.
        .target(name: "OUIProbeImpl", dependencies: ["OUIProbeHeader"],
                path: "Sources/OUIProbeImpl"),
        // An Objective-C subclass of the Swift-implemented class, and ObjC
        // driver functions that allocate / exercise it.
        // -fno-modules: the generated OUIProbeImpl-Swift.h is otherwise
        // imported as a Clang module, which ignores the SWIFT_CLASS
        // predefinition the chain probe uses to lift the restriction.
        .target(name: "OUIProbeObjC", dependencies: ["OUIProbeHeader", "OUIProbeImpl"],
                path: "Sources/OUIProbeObjC",
                cSettings: [.unsafeFlags(["-fno-modules"])]),
        .executableTarget(name: "OUIProbeMain",
                          dependencies: ["OUIProbeHeader", "OUIProbeImpl", "OUIProbeObjC"],
                          path: "Sources/OUIProbeMain"),
    ]
)
