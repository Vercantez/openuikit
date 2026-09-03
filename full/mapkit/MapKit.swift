@_exported import Foundation

/// Linux starting point for Apple's public `MapKit` module.
///
/// Map-point geometry, option sets, enumerations, address/POI filters, and
/// `MKDistanceFormatter` are real in-process values. Apple Maps tiles,
/// directions, local search, Look Around, and UIKit map views are not present
/// on this isolated host: those APIs stay deferred or fail closed. Nothing here
/// is a claim of Apple bit-identical projection, string format, or service
/// success.
///
/// `CoreLocation` / `UIKit` / `CoreGraphics` types are owned by those modules.
/// This lane does not publish stand-ins for them. Isolated-host compilation
/// therefore uses `Double` wherever the overlay writes `CLLocationDegrees` or
/// `CLLocationDistance` (those are typealiases of `Double` on Darwin).

public let MKErrorDomain = "MKErrorDomain"

public typealias MKZoomScale = CGFloat

public func MKRoadWidthAtZoomScale(_ zoomScale: MKZoomScale) -> CGFloat {
    // Linux stand-in: two map-points of road width at 1x. Not an Apple-oracle
    // width table.
    max(0 as CGFloat, zoomScale * 2)
}

extension NSNotification.Name {
    /// Linux uses the exported C identifier as the raw name. Apple's exact
    /// payload bytes are unobserved on this host.
    public static let MKAnnotationCalloutInfoDidChange = NSNotification.Name(
        "MKAnnotationCalloutInfoDidChangeNotification"
    )
}

/// Bridged `MKError` overlay. Raw codes follow the macios/header order
/// (`unknown = 1` … `decodingFailed = 6`). The domain string is the C
/// identifier pending an Apple-oracle probe.
public struct MKError: Error, Equatable, Hashable, Sendable {
    public enum Code: UInt, Sendable, Equatable, Hashable {
        case unknown = 1
        case serverFailure = 2
        case loadingThrottled = 3
        case placemarkNotFound = 4
        case directionsNotFound = 5
        case decodingFailed = 6
    }

    public var code: Code
    public var userInfo: [String: String]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        var strings: [String: String] = [:]
        for (key, value) in userInfo {
            strings[key] = String(describing: value)
        }
        self.userInfo = strings
    }

    public static var errorDomain: String { MKErrorDomain }
    public var errorCode: Int { Int(code.rawValue) }
    public var errorUserInfo: [String: Any] { userInfo }
    public var localizedDescription: String {
        "\(MKErrorDomain) \(code.rawValue)"
    }

    public static var unknown: Code { .unknown }
    public static var serverFailure: Code { .serverFailure }
    public static var loadingThrottled: Code { .loadingThrottled }
    public static var placemarkNotFound: Code { .placemarkNotFound }
    public static var directionsNotFound: Code { .directionsNotFound }
    public static var decodingFailed: Code { .decodingFailed }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(userInfo)
    }
}

extension MKError.Code {
    public static func ~= (match: Self, error: any Error) -> Bool {
        (error as? MKError)?.code == match
    }
}
