// swift-tools-version:5.9
// iOS-target probe (docs/agent_reports/ios-target-route.md).
//
// The smallest real case of building app source for an iOS triple against
// OpenUIKit: `#if os(iOS)` + `import UIKit` + an Objective-C subclass of
// UIView. Built with
//
//   swift build --triple arm64-apple-ios26.1-simulator --sdk <curated SDK>
//
// (Tools/iostarget/ios_target.py prints the exact command). On the macOS
// triple it must NOT compile: IOSTargetProbe/main.swift carries a zero-argument
// @IBAction and an #error for any non-iOS condition.
import PackageDescription

let subclassingDefines = [
    "-DSWIFT_CLASS(SWIFT_NAME)=SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA",
    "-DSWIFT_CLASS_NAMED(SWIFT_NAME)=SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA",
]

let package = Package(
    name: "IOSTargetProbe",
    platforms: [.iOS("26.0"), .macOS(.v11)],
    dependencies: [.package(name: "OpenUIKit", path: "../../..")],
    targets: [
        // The shared Objective-C scenario (Tools/oracle2/objcsubclassprobe),
        // compiled against OpenUIKit's generated header.
        .target(
            name: "IOSTargetProbeObjC",
            // OpenUIKit, not the UIKit product: a Clang target depending on the
            // Swift `UIKit` target makes SwiftPM emit a second `module UIKit`
            // (for UIKit-Swift.h) next to UIKitClangModule's ("redefinition of
            // module 'UIKit'", measured after main's UIKitClangModule).
            dependencies: [
                .product(name: "OpenUIKit", package: "OpenUIKit"),
                .product(name: "OpenUIKitObjCBridge", package: "OpenUIKit"),
            ],
            publicHeadersPath: "include",
            cSettings: [.define("OUK_OPENUIKIT", to: "1"), .unsafeFlags(subclassingDefines)]
        ),
        .executableTarget(
            name: "IOSTargetProbe",
            dependencies: [
                "IOSTargetProbeObjC",
                .product(name: "UIKit", package: "OpenUIKit"),
            ],
            swiftSettings: [.unsafeFlags(subclassingDefines.flatMap { ["-Xcc", $0] })]
        ),
    ]
)
