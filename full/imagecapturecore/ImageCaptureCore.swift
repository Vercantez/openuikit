@_exported import Foundation

// Linux starting point for Apple's ImageCaptureCore. Image Capture
// hardware, the `icdd` daemon, PTP/USB cameras, scanners, and TCC
// authorization are fail-closed: Linux has none of those services.
// Value types, error codes with documented raw values, typed NSString
// keys, notification-free state machines, and honest empty catalogs
// are implemented here.

/// CoreGraphics is not a declared dependency. Camera icons and
/// thumbnails are never vended on Linux; the overlay exists so public
/// property types type-check.
public typealias CGImage = NSObject

/// Darwin `off_t` overlay. 64-bit file offsets match LP64 `off_t`.
public typealias off_t = Int64

/// Objective-C `Selector` is not available on Linux Foundation.
/// Selector-based download/PTP callbacks are fail-closed and never
/// performed.
public struct Selector: Hashable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// `NSError` domain for ImageCaptureCore return codes. Apple's runtime
/// surface observed in shipping Image Capture errors is the reverse-DNS
/// string, not the export symbol name.
public let ICErrorDomain: String = "com.apple.ImageCaptureCore"
