import Foundation
import Dispatch

#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Linux starting implementation of Apple's public `MapKit` module.
///
/// Geometry, option sets, request objects, and in-memory annotation/overlay
/// state are real. Apple map data, directions, search, snapshots, Look Around,
/// device location, entitlements, and UI presentation stay fail-closed.
public enum MapKitModule {
    public static let linuxStartingPoint = "MapKit"
}

/// Apple's public MapKit error domain. The string identity matches the
/// `ErrorDomain("MKErrorDomain")` binding recorded in the pinned macios
/// evidence; the ObjC export is `MKErrorDomain`.
public let MKErrorDomain = "MKErrorDomain"

public struct MKError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: UInt, Hashable, Sendable {
        case unknown = 1
        case serverFailure = 2
        case loadingThrottled = 3
        case placemarkNotFound = 4
        case directionsNotFound = 5
        case decodingFailed = 6
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { MKErrorDomain }
    public var errorCode: Int { Int(bitPattern: UInt(code.rawValue)) }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let unknown = Code.unknown
    public static let serverFailure = Code.serverFailure
    public static let loadingThrottled = Code.loadingThrottled
    public static let placemarkNotFound = Code.placemarkNotFound
    public static let directionsNotFound = Code.directionsNotFound
    public static let decodingFailed = Code.decodingFailed

    public static func == (lhs: MKError, rhs: MKError) -> Bool {
        lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension MKError.Code {
    public static func ~= (match: MKError.Code, error: any Error) -> Bool {
        (error as? MKError)?.code == match
    }
}

public let MKLaunchOptionsCameraKey = "MKLaunchOptionsCameraKey"
public let MKLaunchOptionsDirectionsModeKey = "MKLaunchOptionsDirectionsModeKey"
public let MKLaunchOptionsDirectionsModeCycling = "MKLaunchOptionsDirectionsModeCycling"
public let MKLaunchOptionsDirectionsModeDefault = "MKLaunchOptionsDirectionsModeDefault"
public let MKLaunchOptionsDirectionsModeDriving = "MKLaunchOptionsDirectionsModeDriving"
public let MKLaunchOptionsDirectionsModeTransit = "MKLaunchOptionsDirectionsModeTransit"
public let MKLaunchOptionsDirectionsModeWalking = "MKLaunchOptionsDirectionsModeWalking"
public let MKLaunchOptionsMapCenterKey = "MKLaunchOptionsMapCenterKey"
public let MKLaunchOptionsMapSpanKey = "MKLaunchOptionsMapSpanKey"
public let MKLaunchOptionsMapTypeKey = "MKLaunchOptionsMapTypeKey"
public let MKLaunchOptionsShowsTrafficKey = "MKLaunchOptionsShowsTrafficKey"
public let MKMapItemTypeIdentifier = "MKMapItemTypeIdentifier"
public let MKMapViewDefaultAnnotationViewReuseIdentifier = "MKMapViewDefaultAnnotationViewReuseIdentifier"
public let MKMapViewDefaultClusterAnnotationViewReuseIdentifier = "MKMapViewDefaultClusterAnnotationViewReuseIdentifier"

/// Declared without a pinned numeric payload. Apple's `MKMapCameraZoomDefault`
/// value is an oracle question; this Linux starting point uses a non-finite
/// sentinel so callers can detect "unspecified zoom" without inventing a
/// camera altitude.
public let MKMapCameraZoomDefault: Double = Double.infinity

public typealias MKZoomScale = CGFloat

extension NSNotification.Name {
    public static let MKAnnotationCalloutInfoDidChange = NSNotification.Name(
        "MKAnnotationCalloutInfoDidChangeNotification"
    )
}

/// Request-scoped, exactly-once, non-inline completion helper.
final class MKFailClosedGate: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    private var finished = false
    private let generation: UInt64

    init(generation: UInt64) {
        self.generation = generation
    }

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    func completeOnce(_ body: () -> Void) {
        lock.lock()
        if finished {
            lock.unlock()
            return
        }
        finished = true
        lock.unlock()
        body()
    }
}

func mk_finishOffQueue(gate: MKFailClosedGate, _ body: @escaping () -> Void) {
    DispatchQueue.global(qos: .utility).async {
        gate.completeOnce(body)
    }
}

func mk_unsupportedServiceError(_ code: MKError.Code = .unknown) -> MKError {
    MKError(code, userInfo: [
        NSLocalizedDescriptionKey: "MapKit Apple service is unavailable on this Linux starting point"
    ])
}
