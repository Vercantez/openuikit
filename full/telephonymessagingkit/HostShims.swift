@_exported import Foundation

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif

/// Empty async sequence used when Linux has no telephony daemon to stream.
public struct TelephonyMessagingEmptyAsyncSequence<Element: Sendable>: AsyncSequence, Sendable {
    public struct Iterator: AsyncIteratorProtocol, Sendable {
        public mutating func next() async -> Element? { nil }
    }

    public init() {}

    public func makeAsyncIterator() -> Iterator {
        Iterator()
    }
}

#if !canImport(UniformTypeIdentifiers)
/// Isolated-host stand-in for `UniformTypeIdentifiers.UTType`.
public struct UTType: Hashable, Sendable, Codable {
    public var identifier: String

    public init(_ identifier: String) {
        self.identifier = identifier
    }

    public static let plainText = UTType("public.plain-text")
    public static let jpeg = UTType("public.jpeg")
    public static let png = UTType("public.png")
    public static let data = UTType("public.data")
}
#endif

#if !canImport(CoreGraphics)
public typealias CGFloat = Double

/// Isolated-host stand-in for CoreGraphics `CGColor`.
public struct CGColor: Hashable, Sendable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}
#endif

#if !canImport(CoreLocation)
public typealias CLLocationDegrees = Double

/// Isolated-host stand-in for `CLLocationCoordinate2D`.
public struct CLLocationCoordinate2D: Equatable, Hashable, Sendable, Codable {
    public var latitude: CLLocationDegrees
    public var longitude: CLLocationDegrees

    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
#endif
