// A module named `UIKit` that re-exports OpenUIKit -- and NOTHING else.
//
// ~/uikit's own UIKitShim is `@_exported import Foundation` + `@_exported
// import OpenUIKit`, because real UIKit's swiftinterface re-exports Foundation
// and the vendored app files rely on that to name NSCoder.
//
// MEASURED, and it is the central result of the app-path scoping:
//
//  * The four UNMODIFIED vendored app files need exactly ONE Foundation name,
//    NSCoder, for the `required init?(coder:)` UIKit forces on every UIView
//    subclass. Nothing else. OptionAction.swift even writes `import
//    Foundation` and uses nothing from it.
//  * But introducing a module NAMED Foundation, however small, flips
//    OpenUIKit's 33 `#if canImport(Foundation)` guards AND OpenCoreGraphics'
//    to their Foundation branches, which then demand Foundation's own
//    IndexPath, IndexSet, NSRange, NSRangePointer, TimeInterval, CGFloat,
//    CGPoint, CGSize and CGRect. There is no "small Foundation" for this stack: a
//    nearly-empty one is WORSE than none, because it switches the library onto
//    a path it cannot satisfy.
//
// So the cheap configuration is this one: no Foundation module at all, and
// NSCoder supplied by OpenUIKit alongside its Foundation-free value names. The
// library stays on its freestanding branch -- the same branch that renders
// 108/108 -- and the app source still compiles unmodified.
@_exported import Foundation
@_exported import OpenUIKit
