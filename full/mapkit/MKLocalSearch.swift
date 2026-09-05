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

open class MKLocalSearch: NSObject {
    public struct ResultType: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let address = ResultType(rawValue: 1 << 0)
        public static let pointOfInterest = ResultType(rawValue: 1 << 1)
        public static let physicalFeature = ResultType(rawValue: 1 << 2)
    }

    public typealias CompletionHandler = (Response?, (any Error)?) -> Void

    public class Request: NSObject {
        public typealias ResultType = MKLocalSearch.ResultType
        public var naturalLanguageQuery: String?
        public var region: MKCoordinateRegion = MKCoordinateRegion()
        public var regionPriority: MKLocalSearchRegionPriority = .default
        public var resultTypes: ResultType = [.address, .pointOfInterest]
        public var pointOfInterestFilter: MKPointOfInterestFilter?
        public var addressFilter: MKAddressFilter?

        public override init() { super.init() }

        public init(completion: MKLocalSearchCompletion) {
            naturalLanguageQuery = completion.title
            super.init()
        }

        public convenience init(naturalLanguageQuery: String) {
            self.init()
            self.naturalLanguageQuery = naturalLanguageQuery
        }

        public convenience init(naturalLanguageQuery: String, region: MKCoordinateRegion) {
            self.init()
            self.naturalLanguageQuery = naturalLanguageQuery
            self.region = region
        }
    }

    open class Response: NSObject {
        open var mapItems: [MKMapItem] = []
        open var boundingRegion: MKCoordinateRegion = MKCoordinateRegion()
    }

    public private(set) var isSearching: Bool = false

    public init(request: Request) {
        _ = request
        super.init()
    }

    public init(request: MKLocalPointsOfInterestRequest) {
        _ = request
        super.init()
    }

    public convenience init(pointsOfInterestRequest request: MKLocalPointsOfInterestRequest) {
        self.init(request: request)
    }

    open func start(completionHandler: @escaping CompletionHandler) {
        isSearching = false
        completionHandler(nil, MKError(.serverFailure))
    }

    open func cancel() {
        isSearching = false
    }
}

open class MKLocalSearchCompletion: NSObject {
    open var title: String = ""
    open var subtitle: String = ""
    open var titleHighlightRanges: [NSValue] = []
    open var subtitleHighlightRanges: [NSValue] = []
}

open class MKLocalSearchCompleter: NSObject {
    public struct ResultType: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let address = ResultType(rawValue: 1 << 0)
        public static let pointOfInterest = ResultType(rawValue: 1 << 1)
        public static let query = ResultType(rawValue: 1 << 2)
        public static let physicalFeature = ResultType(rawValue: 1 << 3)
    }

    public enum FilterType: Int, Sendable, Equatable, Hashable {
        case locationsAndQueries = 0
        case locationsOnly = 1
    }

    open weak var delegate: (any MKLocalSearchCompleterDelegate)?
    open var queryFragment: String = "" {
        didSet { mk_runQuery() }
    }
    open var region: MKCoordinateRegion = MKCoordinateRegion()
    open var regionPriority: MKLocalSearchRegionPriority = .default
    open var resultTypes: ResultType = [.address, .pointOfInterest, .query]
    open var filterType: FilterType = .locationsAndQueries
    open var pointOfInterestFilter: MKPointOfInterestFilter?
    open var addressFilter: MKAddressFilter?
    public private(set) var results: [MKLocalSearchCompletion] = []
    public private(set) var isSearching: Bool = false

    public override init() { super.init() }

    open func cancel() {
        isSearching = false
    }

    private func mk_runQuery() {
        results = []
        if queryFragment.isEmpty {
            isSearching = false
            return
        }
        isSearching = true
        isSearching = false
        delegate?.completer(self, didFailWithError: MKError(.serverFailure))
    }
}

public protocol MKLocalSearchCompleterDelegate: AnyObject {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter)
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error)
}

extension MKLocalSearchCompleterDelegate {
    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) { _ = completer }
    public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        _ = (completer, error)
    }
}

open class MKLocalPointsOfInterestRequest: NSObject {
    /// Darwin macOS 26.1: `maxRadius == 2000`.
    public class var maxRadius: CLLocationDistance { 2000 }

    public private(set) var coordinate: CLLocationCoordinate2D
    public private(set) var radius: CLLocationDistance
    public var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
    }
    open var pointOfInterestFilter: MKPointOfInterestFilter?

    public init(center coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.coordinate = coordinate
        self.radius = min(max(radius, 0), Self.maxRadius)
        super.init()
    }

    public convenience init(centerCoordinate coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.init(center: coordinate, radius: radius)
    }

    public init(coordinateRegion region: MKCoordinateRegion) {
        coordinate = region.center
        let meters = MKMetersPerMapPointAtLatitude(region.center.latitude)
        let rect = MKMapRectForCoordinateRegion(region)
        radius = min(Self.maxRadius, max(rect.width, rect.height) / 2 * meters)
        super.init()
    }
}

open class MKGeocodingRequest: NSObject {
    public private(set) var addressString: String
    open var region: MKCoordinateRegion = MKCoordinateRegion()
    open var preferredLocale: Locale?
    public private(set) var isCancelled: Bool = false
    public private(set) var isLoading: Bool = false

    public init?(addressString: String) {
        if addressString.isEmpty { return nil }
        self.addressString = addressString
        super.init()
    }

    open func cancel() {
        isCancelled = true
        isLoading = false
    }

    open func getMapItems(completionHandler: @escaping ([MKMapItem]?, (any Error)?) -> Void) {
        isLoading = false
        completionHandler(nil, MKError(.placemarkNotFound))
    }
}

open class MKReverseGeocodingRequest: NSObject {
    public private(set) var location: CLLocation
    open var preferredLocale: Locale?
    public private(set) var isCancelled: Bool = false
    public private(set) var isLoading: Bool = false

    public init?(location: CLLocation) {
        self.location = location
        super.init()
    }

    open func cancel() {
        isCancelled = true
        isLoading = false
    }

    open func getMapItems(completionHandler: @escaping ([MKMapItem]?, (any Error)?) -> Void) {
        isLoading = false
        completionHandler(nil, MKError(.placemarkNotFound))
    }
}
