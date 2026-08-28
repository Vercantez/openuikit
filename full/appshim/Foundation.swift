// A module named Foundation containing exactly ONE public name.
//
// MEASURED, and the shape of the result is the point:
//
//  * The four UNMODIFIED vendored app files need exactly one Foundation name,
//    NSCoder, for the `required init?(coder:)` UIKit forces on every UIView
//    subclass. OptionAction.swift writes `import Foundation` and uses NOTHING
//    from it -- with the module absent, that vestigial line is the ONLY error
//    in the entire real-app target.
//  * But a module named Foundation on the LIBRARY's search path flips
//    OpenUIKit's 33 `#if canImport(Foundation)` guards and OpenCoreGraphics'
//    too, which then demand Foundation's own IndexPath, IndexSet, NSRange,
//    NSRangePointer, TimeInterval, CGFloat, CGPoint, CGSize and CGRect. A
//    nearly-empty Foundation is WORSE than none: it switches the library onto
//    a path it cannot satisfy.
//
// So this module lives in an include directory the APP modules see and the
// LIBRARY does not. That is not a trick -- it is the real configuration: the
// library is built freestanding (the branch that renders 108/108) while the
// app is built against Foundation, exactly as a real app would be.
//
// A MEASURING INSTRUMENT, NOT A PROPOSAL. Shipping this would be the worst
// kind of stub: every `import Foundation` would keep compiling while the first
// genuine use failed somewhere far away.

// This import is deliberately not exported. It gives the app-facing spelling
// the exact same type identity as UIView's required initializer without
// exposing a second NSCoder declaration or changing the Foundation-invisible
// OpenUIKit build.
import OpenUIKit

/// The one name the app source needs. OpenUIKit's Foundation-free fallback is
/// opaque on purpose: no archive decoding exists, and the app probes never
/// invoke it. Sharing the identity is nevertheless essential for Swift's
/// required/designated/convenience initializer inheritance rules.
public typealias NSCoder = OpenUIKit.NSCoder
