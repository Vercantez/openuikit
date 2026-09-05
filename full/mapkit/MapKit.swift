@_exported import Foundation
#if canImport(CoreGraphics)
@_exported import CoreGraphics
#endif
#if canImport(CoreLocation)
@_exported import CoreLocation
#endif
#if canImport(UIKit)
@_exported import UIKit
#endif

/// Linux `MapKit` module. Geometry, annotations, overlays, and MKMapView
/// stores are real in-process values. Apple Maps tiles, directions, local
/// search, Look Around, and snapshotter success fail closed with `MKError`.
///
/// Measured against Darwin MapKit on macOS 26.1 (`xcrun swift` probe,
/// 2026-09-05): world size `268435456`, equator meters-per-point
/// `0.14828977333772544`, `MKMapPoint(0°, 0°) = (134217728, 134217728)`,
/// POI raw strings `MKPOICategory…`, `MKMapCameraZoomDefault = -1`,
/// `MKLocalPointsOfInterestRequest.maxRadius = 2000`.

public let MKErrorDomain = "MKErrorDomain"

public let MKAnnotationCalloutInfoDidChangeNotification =
    "MKAnnotationCalloutInfoDidChangeNotification"

public let MKLaunchOptionsDirectionsModeKey = "MKLaunchOptionsDirectionsMode"
public let MKLaunchOptionsMapCenterKey = "MKLaunchOptionsMapCenter"
public let MKLaunchOptionsMapSpanKey = "MKLaunchOptionsMapSpan"
public let MKLaunchOptionsMapTypeKey = "MKLaunchOptionsMapType"
public let MKLaunchOptionsShowsTrafficKey = "MKLaunchOptionsShowsTraffic"
public let MKLaunchOptionsCameraKey = "MKLaunchOptionsCameraKey"
public let MKLaunchOptionsDirectionsModeDriving = "MKLaunchOptionsDirectionsModeDriving"
public let MKLaunchOptionsDirectionsModeWalking = "MKLaunchOptionsDirectionsModeWalking"
public let MKLaunchOptionsDirectionsModeTransit = "MKLaunchOptionsDirectionsModeTransit"
public let MKLaunchOptionsDirectionsModeDefault = "MKLaunchOptionsDirectionsModeDefault"
public let MKLaunchOptionsDirectionsModeCycling = "MKLaunchOptionsDirectionsModeCycling"

public let MKMapViewDefaultAnnotationViewReuseIdentifier =
    "MKMapViewDefaultAnnotationViewReuseIdentifier"
public let MKMapViewDefaultClusterAnnotationViewReuseIdentifier =
    "MKMapViewDefaultClusterAnnotationViewReuseIdentifier"
public let MKMapItemTypeIdentifier = "com.apple.mapkit.map-item"

/// Darwin macOS 26.1: `MKMapCameraZoomDefault == -1`.
public let MKMapCameraZoomDefault: CLLocationDistance = -1

public typealias MKZoomScale = CGFloat

extension NSNotification.Name {
    /// Darwin macOS 26.1: raw value `MKAnnotationCalloutInfoDidChangeNotification`.
    public static let MKAnnotationCalloutInfoDidChange = NSNotification.Name(
        MKAnnotationCalloutInfoDidChangeNotification
    )
}

/// Bridged `MKError` overlay. Raw codes follow the macios/header order
/// (`unknown = 1` … `decodingFailed = 6`). Darwin domain string is
/// `MKErrorDomain` (macOS 26.1).
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

func mk_nsError(_ error: MKError) -> NSError {
    NSError(
        domain: MKErrorDomain,
        code: error.errorCode,
        userInfo: error.errorUserInfo
    )
}

func mk_containsToken(_ haystack: String, _ needle: String) -> Bool {
    var index = haystack.startIndex
    while index < haystack.endIndex {
        if haystack[index...].hasPrefix(needle) {
            return true
        }
        index = haystack.index(after: index)
    }
    return false
}

func mk_replaceTemplate(_ template: String, key: String, value: String) -> String {
    // Avoid `_StringProcessing` String.replacing. Tile templates use `{z}`/`{x}`/`{y}`.
    var result = ""
    var index = template.startIndex
    while index < template.endIndex {
        if template[index...].hasPrefix(key) {
            result += value
            index = template.index(index, offsetBy: key.count)
        } else {
            result.append(template[index])
            index = template.index(after: index)
        }
    }
    return result
}
