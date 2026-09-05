import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(UIKit)
import UIKit
#endif

open class MKDirections: NSObject {
    public enum RoutePreference: Int, Sendable, Equatable, Hashable {
        case any = 0
        case avoid = 1
    }

    public typealias DirectionsHandler = (Response?, (any Error)?) -> Void
    public typealias ETAHandler = (ETAResponse?, (any Error)?) -> Void

    public class Request: NSObject {
        public var source: MKMapItem?
        open var destination: MKMapItem?
        open var transportType: MKDirectionsTransportType = .automobile
        open var requestsAlternateRoutes: Bool = false
        open var departureDate: Date?
        open var arrivalDate: Date?
        open var highwayPreference: RoutePreference = .any
        open var tollPreference: RoutePreference = .any

        public override init() { super.init() }

        public init(contentsOfURL url: URL) {
            super.init()
            _ = url
        }

        open class func isDirectionsRequest(_ url: URL) -> Bool {
            url.scheme == "http" || url.scheme == "https" || url.scheme == "maps"
        }
    }

    open class Response: NSObject {
        open var source: MKMapItem
        open var destination: MKMapItem
        open var routes: [MKRoute]

        public override init() {
            source = MKMapItem.forCurrentLocation()
            destination = MKMapItem.forCurrentLocation()
            routes = []
            super.init()
        }
    }

    open class ETAResponse: NSObject {
        open var source: MKMapItem
        open var destination: MKMapItem
        open var transportType: MKDirectionsTransportType
        open var expectedTravelTime: TimeInterval
        open var distance: CLLocationDistance
        open var expectedArrivalDate: Date
        open var expectedDepartureDate: Date

        public override init() {
            source = MKMapItem.forCurrentLocation()
            destination = MKMapItem.forCurrentLocation()
            transportType = .automobile
            expectedTravelTime = 0
            distance = 0
            expectedArrivalDate = Date()
            expectedDepartureDate = Date()
            super.init()
        }
    }

    public private(set) var isCalculating: Bool = false
    private var cancelled = false

    public init(request: Request) {
        _ = request
        super.init()
    }

    open func calculate(completionHandler: @escaping DirectionsHandler) {
        isCalculating = false
        completionHandler(nil, MKError(.directionsNotFound))
    }

    open func calculateETA(completionHandler: @escaping ETAHandler) {
        isCalculating = false
        completionHandler(nil, MKError(.directionsNotFound))
    }

    open func cancel() {
        cancelled = true
        isCalculating = false
    }
}

open class MKRoute: NSObject {
    open var name: String = ""
    open var advisoryNotices: [String] = []
    open var distance: CLLocationDistance = 0
    open var expectedTravelTime: TimeInterval = 0
    open var transportType: MKDirectionsTransportType = .automobile
    open var polyline: MKPolyline = MKPolyline()
    open var steps: [Step] = []
    open var hasHighways: Bool = false
    open var hasTolls: Bool = false

    open class Step: NSObject {
        open var instructions: String = ""
        open var notice: String?
        open var distance: CLLocationDistance = 0
        open var transportType: MKDirectionsTransportType = .automobile
        open var polyline: MKPolyline = MKPolyline()
    }
}
