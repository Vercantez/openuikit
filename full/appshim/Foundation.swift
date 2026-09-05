// The narrow NSCoder portion of build_full's app-only Foundation module.
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
// LIBRARY does not. The library now sees FoundationEssentials deliberately,
// which supplies the canonical IndexPath identity, but it still must not see
// this incomplete Foundation umbrella: doing so would switch unrelated APIs
// such as NSRange and geometry onto contracts this measuring shim cannot meet.
//
// build_full compiles this file (plus FoundationOpenUIKitAliases.swift) into
// APPINC for DeveloperToolsSupport, which needs OpenUIKit's exact Bundle.
// After UIKit is compiled without APPINC, the same APPINC path is overwritten
// with the 38-file FoundationGuest facade so RealAppProbe sees DateFormatter
// / JSONSerialization / URLSession. The library include roots never change.
//
// A MEASURING INSTRUMENT, NOT A PROPOSAL. Shipping this would be the worst
// kind of stub: every `import Foundation` would keep compiling while the first
// genuine use failed somewhere far away.

// This import is deliberately not exported. It gives the app-facing spelling
// the exact same type identity as UIView's required initializer without
// exposing a second NSCoder declaration or changing the Foundation-umbrella-
// invisible OpenUIKit build.
import OpenUIKit

/// The archive identity needed by the original app probe. OpenUIKit's
/// Foundation-free fallback is opaque on purpose: no archive decoding exists,
/// but sharing the identity is essential for required initializer inheritance.
public typealias NSCoder = OpenUIKit.NSCoder

/// DeveloperToolsSupport's asset-resource value is compiled after OpenUIKit
/// and before the complete app-facing Foundation facade. It must name the
/// exact bundle identity OpenUIKit uses rather than inventing a parallel
/// placeholder or making the target depend on the later full facade.
public typealias Bundle = OpenUIKit.Bundle
