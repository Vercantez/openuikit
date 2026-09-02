import Foundation
import Dispatch

open class MKDirections: NSObject {
    public enum RoutePreference: Int, Hashable, Sendable {
        case any = 0
        case avoid = 1
    }

    public typealias DirectionsHandler = (MKDirections.Response?, (any Error)?) -> Void
    public typealias ETAHandler = (MKDirections.ETAResponse?, (any Error)?) -> Void

    open class Request: NSObject {
        open var source: MKMapItem?
        open var destination: MKMapItem?
        open var transportType: MKDirectionsTransportType = []
        open var requestsAlternateRoutes = false
        open var departureDate: Date?
        open var arrivalDate: Date?
        open var highwayPreference: RoutePreference = .any
        open var tollPreference: RoutePreference = .any

        public override init() {
            super.init()
        }

        public init(contentsOfURL url: URL) {
            _ = url
            super.init()
        }

        open class func isDirectionsRequest(_ url: URL) -> Bool {
            _ = url
            return false
        }
    }

    open class Response: NSObject {
        public let source: MKMapItem
        public let destination: MKMapItem
        public let routes: [MKRoute]

        init(source: MKMapItem, destination: MKMapItem, routes: [MKRoute]) {
            self.source = source
            self.destination = destination
            self.routes = routes
            super.init()
        }
    }

    open class ETAResponse: NSObject {
        public let source: MKMapItem
        public let destination: MKMapItem
        public let expectedTravelTime: TimeInterval
        public let distance: Double
        public let expectedArrivalDate: Date
        public let expectedDepartureDate: Date
        public let transportType: MKDirectionsTransportType

        init(
            source: MKMapItem,
            destination: MKMapItem,
            expectedTravelTime: TimeInterval,
            distance: Double,
            expectedArrivalDate: Date,
            expectedDepartureDate: Date,
            transportType: MKDirectionsTransportType
        ) {
            self.source = source
            self.destination = destination
            self.expectedTravelTime = expectedTravelTime
            self.distance = distance
            self.expectedArrivalDate = expectedArrivalDate
            self.expectedDepartureDate = expectedDepartureDate
            self.transportType = transportType
            super.init()
        }
    }

    private let request: Request
    private let generation: UInt64
    private var gate: MKFailClosedGate
    private let lock = NSLock()
    private var calculating = false

    public init(request: Request) {
        self.request = request
        self.generation = UInt64.random(in: 1...UInt64.max)
        self.gate = MKFailClosedGate(generation: generation)
        super.init()
    }

    open var isCalculating: Bool {
        lock.lock()
        defer { lock.unlock() }
        return calculating
    }

    open func cancel() {
        lock.lock()
        calculating = false
        lock.unlock()
        gate.cancel()
    }

    open func calculate(completionHandler: @escaping DirectionsHandler) {
        startFailClosed(completionHandler)
    }

    open func calculateETA(completionHandler: @escaping ETAHandler) {
        startFailClosed(completionHandler)
    }

    private func startFailClosed<Response>(_ handler: @escaping (Response?, (any Error)?) -> Void) {
        lock.lock()
        calculating = true
        let current = MKFailClosedGate(generation: generation)
        gate = current
        lock.unlock()
        mk_finishOffQueue(gate: current) { [weak self] in
            handler(nil, mk_unsupportedServiceError(.directionsNotFound))
            self?.lock.lock()
            self?.calculating = false
            self?.lock.unlock()
        }
    }
}

open class MKRoute: NSObject {
    open var name: String = ""
    open var advisoryNotices: [String] = []
    open var distance: Double = 0
    open var expectedTravelTime: TimeInterval = 0
    open var transportType: MKDirectionsTransportType = []
    open var steps: [Step] = []
    open var hasTolls = false
    open var hasHighways = false
    open var polyline = MKPolyline()

    open class Step: NSObject {
        open var instructions: String = ""
        open var notice: String?
        open var distance: Double = 0
        open var transportType: MKDirectionsTransportType = []
        open var polyline = MKPolyline()
    }
}

open class MKLocalSearch: NSObject {
    public typealias CompletionHandler = (MKLocalSearch.Response?, (any Error)?) -> Void

    public struct ResultType: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let address = ResultType(rawValue: 1 << 0)
        public static let pointOfInterest = ResultType(rawValue: 1 << 1)
        public static let physicalFeature = ResultType(rawValue: 1 << 2)
    }

    open class Request: NSObject {
        public typealias ResultType = MKLocalSearch.ResultType

        open var naturalLanguageQuery: String?
        open var resultTypes: MKLocalSearch.ResultType = []
        open var regionPriority: MKLocalSearchRegionPriority = .default
        open var addressFilter: MKAddressFilter?
        open var pointOfInterestFilter: MKPointOfInterestFilter?

        public override init() {
            super.init()
        }

        public convenience init(naturalLanguageQuery: String) {
            self.init()
            self.naturalLanguageQuery = naturalLanguageQuery
        }

        public init(completion: MKLocalSearchCompletion) {
            self.naturalLanguageQuery = completion.title
            super.init()
        }
    }

    open class Response: NSObject {
        public let mapItems: [MKMapItem]
        init(mapItems: [MKMapItem]) {
            self.mapItems = mapItems
            super.init()
        }
    }

    private var gate: MKFailClosedGate
    private let lock = NSLock()
    private var searching = false
    private let generation: UInt64

    public override init() {
        self.generation = UInt64.random(in: 1...UInt64.max)
        self.gate = MKFailClosedGate(generation: generation)
        super.init()
    }

    public init(request: Request) {
        self.generation = UInt64.random(in: 1...UInt64.max)
        self.gate = MKFailClosedGate(generation: generation)
        super.init()
        _ = request
    }

    public init(request: MKLocalPointsOfInterestRequest) {
        self.generation = UInt64.random(in: 1...UInt64.max)
        self.gate = MKFailClosedGate(generation: generation)
        super.init()
        _ = request
    }

    public init(pointsOfInterestRequest request: MKLocalPointsOfInterestRequest) {
        self.generation = UInt64.random(in: 1...UInt64.max)
        self.gate = MKFailClosedGate(generation: generation)
        super.init()
        _ = request
    }

    open var isSearching: Bool {
        lock.lock()
        defer { lock.unlock() }
        return searching
    }

    open func cancel() {
        lock.lock()
        searching = false
        lock.unlock()
        gate.cancel()
    }

    open func start(completionHandler: @escaping CompletionHandler) {
        lock.lock()
        searching = true
        let current = MKFailClosedGate(generation: generation)
        gate = current
        lock.unlock()
        mk_finishOffQueue(gate: current) { [weak self] in
            completionHandler(nil, mk_unsupportedServiceError(.placemarkNotFound))
            self?.lock.lock()
            self?.searching = false
            self?.lock.unlock()
        }
    }
}

open class MKLocalSearchCompleter: NSObject {
    public struct ResultType: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let address = ResultType(rawValue: 1 << 0)
        public static let pointOfInterest = ResultType(rawValue: 1 << 1)
        public static let query = ResultType(rawValue: 1 << 2)
        public static let physicalFeature = ResultType(rawValue: 1 << 3)
    }

    public enum FilterType: Int, Hashable, Sendable {
        case locationsAndQueries = 0
        case locationsOnly = 1
    }

    open weak var delegate: (any MKLocalSearchCompleterDelegate)?
    open var queryFragment: String = "" {
        didSet { beginFailClosedQuery() }
    }
    open var resultTypes: ResultType = []
    open var filterType: FilterType = .locationsAndQueries
    open var regionPriority: MKLocalSearchRegionPriority = .default
    open var addressFilter: MKAddressFilter?
    open var pointOfInterestFilter: MKPointOfInterestFilter?
    public private(set) var results: [MKLocalSearchCompletion] = []

    private let lock = NSLock()
    private var searching = false
    private var gate = MKFailClosedGate(generation: 0)

    open var isSearching: Bool {
        lock.lock()
        defer { lock.unlock() }
        return searching
    }

    open func cancel() {
        lock.lock()
        searching = false
        lock.unlock()
        gate.cancel()
    }

    private func beginFailClosedQuery() {
        lock.lock()
        searching = !queryFragment.isEmpty
        let current = MKFailClosedGate(generation: 1)
        gate = current
        lock.unlock()
        guard !queryFragment.isEmpty else { return }
        mk_finishOffQueue(gate: current) { [weak self] in
            guard let self, !current.isCancelled else { return }
            self.results = []
            self.lock.lock()
            self.searching = false
            self.lock.unlock()
            self.delegate?.completer(self, didFailWithError: mk_unsupportedServiceError(.placemarkNotFound))
        }
    }
}

public protocol MKLocalSearchCompleterDelegate: NSObjectProtocol {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter)
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error)
}

extension MKLocalSearchCompleterDelegate {
    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {}
    public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        _ = (completer, error)
    }
}

open class MKLocalSearchCompletion: NSObject {
    public let title: String
    public let subtitle: String
    public let titleHighlightRanges: [NSValue]
    public let subtitleHighlightRanges: [NSValue]

    public init(
        title: String,
        subtitle: String = "",
        titleHighlightRanges: [NSValue] = [],
        subtitleHighlightRanges: [NSValue] = []
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleHighlightRanges = titleHighlightRanges
        self.subtitleHighlightRanges = subtitleHighlightRanges
        super.init()
    }
}

open class MKLocalPointsOfInterestRequest: NSObject {
    public class var maxRadius: Double { 20_000 }

    public private(set) var radius: Double
    open var pointOfInterestFilter: MKPointOfInterestFilter?

    public init(centerMapPoint: MKMapPoint, radius: Double) {
        self.radius = min(max(radius, 0), Self.maxRadius)
        super.init()
        _ = centerMapPoint
    }

    public override init() {
        self.radius = Self.maxRadius
        super.init()
    }
}

open class MKGeocodingRequest: NSObject {
    open var addressFilter: MKAddressFilter?
    public let addressString: String?
    private var gate = MKFailClosedGate(generation: 0)
    private let lock = NSLock()
    private var cancelled = false
    private var loading = false

    public init?(addressString: String) {
        guard !addressString.isEmpty else { return nil }
        self.addressString = addressString
        super.init()
    }

    open var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    open var isLoading: Bool {
        lock.lock()
        defer { lock.unlock() }
        return loading
    }

    open func cancel() {
        lock.lock()
        cancelled = true
        loading = false
        lock.unlock()
        gate.cancel()
    }

    open func getMapItems(completionHandler: @escaping ([MKMapItem]?, (any Error)?) -> Void) {
        lock.lock()
        loading = true
        lock.unlock()
        let current = MKFailClosedGate(generation: 1)
        gate = current
        mk_finishOffQueue(gate: current) { [weak self] in
            completionHandler(nil, mk_unsupportedServiceError(.placemarkNotFound))
            self?.lock.lock()
            self?.loading = false
            self?.lock.unlock()
        }
    }
}

open class MKReverseGeocodingRequest: NSObject {
    private var gate = MKFailClosedGate(generation: 0)
    private let lock = NSLock()
    private var cancelled = false
    private var loading = false

    public override init() {
        super.init()
    }

    open var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    open var isLoading: Bool {
        lock.lock()
        defer { lock.unlock() }
        return loading
    }

    open func cancel() {
        lock.lock()
        cancelled = true
        loading = false
        lock.unlock()
        gate.cancel()
    }

    open func getMapItems(completionHandler: @escaping ([MKMapItem]?, (any Error)?) -> Void) {
        lock.lock()
        loading = true
        lock.unlock()
        let current = MKFailClosedGate(generation: 1)
        gate = current
        mk_finishOffQueue(gate: current) { [weak self] in
            completionHandler(nil, mk_unsupportedServiceError(.placemarkNotFound))
            self?.lock.lock()
            self?.loading = false
            self?.lock.unlock()
        }
    }
}

open class MKMapItemRequest: NSObject {
    public var mapItem: MKMapItem?
    private var gate = MKFailClosedGate(generation: 0)

    public override init() {
        super.init()
    }

    public init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        super.init()
    }

    public init(mapItemIdentifier: MKMapItem.Identifier) {
        let item = MKMapItem()
        item.identifier = mapItemIdentifier
        self.mapItem = item
        super.init()
    }

    open var isCancelled: Bool { gate.isCancelled }

    open var isLoading: Bool {
        lock.lock()
        defer { lock.unlock() }
        return loading
    }

    private let lock = NSLock()
    private var loading = false

    open func cancel() {
        lock.lock()
        loading = false
        lock.unlock()
        gate.cancel()
    }

    open func getMapItem(completionHandler: @escaping (MKMapItem?, (any Error)?) -> Void) {
        lock.lock()
        loading = true
        lock.unlock()
        let current = MKFailClosedGate(generation: 1)
        gate = current
        mk_finishOffQueue(gate: current) { [weak self] in
            completionHandler(nil, mk_unsupportedServiceError(.placemarkNotFound))
            self?.lock.lock()
            self?.loading = false
            self?.lock.unlock()
        }
    }
}

open class MKMapSnapshotter: NSObject {
    public typealias CompletionHandler = (MKMapSnapshotter.Snapshot?, (any Error)?) -> Void

    open class Options: NSObject {
        open var scale: CGFloat = 1
        open var size: CGSize = CGSize(width: 256, height: 256)
        open var mapType: MKMapType = .standard
        open var showsPointsOfInterest = true
        open var pointOfInterestFilter: MKPointOfInterestFilter?
        open var preferredConfiguration: MKMapConfiguration?
        open var camera: MKMapCamera?
        open var mapRect: MKMapRect = .world
    }

    open class Snapshot: NSObject {}

    private var gate = MKFailClosedGate(generation: 0)
    private let lock = NSLock()
    private var loading = false
    private let options: Options

    public init(options: Options) {
        self.options = options
        super.init()
    }

    open var isLoading: Bool {
        lock.lock()
        defer { lock.unlock() }
        return loading
    }

    open func cancel() {
        lock.lock()
        loading = false
        lock.unlock()
        gate.cancel()
    }

    open func start(completionHandler: @escaping CompletionHandler) {
        lock.lock()
        loading = true
        let current = MKFailClosedGate(generation: 1)
        gate = current
        lock.unlock()
        mk_finishOffQueue(gate: current) { [weak self] in
            completionHandler(nil, mk_unsupportedServiceError(.serverFailure))
            self?.lock.lock()
            self?.loading = false
            self?.lock.unlock()
        }
    }
}

open class MKLookAroundScene: NSObject {}

open class MKLookAroundSceneRequest: NSObject {
    private var gate = MKFailClosedGate(generation: 0)
    private let lock = NSLock()
    private var loading = false

    public override init() {
        super.init()
    }

    open var isCancelled: Bool { gate.isCancelled }

    open var isLoading: Bool {
        lock.lock()
        defer { lock.unlock() }
        return loading
    }

    open func cancel() {
        lock.lock()
        loading = false
        lock.unlock()
        gate.cancel()
    }

    open func getSceneWithCompletionHandler(
        _ completionHandler: @escaping (MKLookAroundScene?, (any Error)?) -> Void
    ) {
        lock.lock()
        loading = true
        lock.unlock()
        let current = MKFailClosedGate(generation: 1)
        gate = current
        mk_finishOffQueue(gate: current) { [weak self] in
            completionHandler(nil, mk_unsupportedServiceError(.unknown))
            self?.lock.lock()
            self?.loading = false
            self?.lock.unlock()
        }
    }
}

open class MKLookAroundSnapshotter: NSObject {
    open class Options: NSObject {
        open var size: CGSize = CGSize(width: 256, height: 256)
        open var pointOfInterestFilter: MKPointOfInterestFilter?
    }

    open class Snapshot: NSObject {}

    private var gate = MKFailClosedGate(generation: 0)
    private let lock = NSLock()
    private var loading = false

    public init(scene: MKLookAroundScene, options: Options) {
        super.init()
        _ = (scene, options)
    }

    open var isLoading: Bool {
        lock.lock()
        defer { lock.unlock() }
        return loading
    }

    open func cancel() {
        lock.lock()
        loading = false
        lock.unlock()
        gate.cancel()
    }

    open func getSnapshotWithCompletionHandler(
        _ completionHandler: @escaping (Snapshot?, (any Error)?) -> Void
    ) {
        lock.lock()
        loading = true
        lock.unlock()
        let current = MKFailClosedGate(generation: 1)
        gate = current
        mk_finishOffQueue(gate: current) { [weak self] in
            completionHandler(nil, mk_unsupportedServiceError(.unknown))
            self?.lock.lock()
            self?.loading = false
            self?.lock.unlock()
        }
    }
}

open class MKGeoJSONDecoder: NSObject {
    open var pointOfInterestFilter: MKPointOfInterestFilter?

    open func decode(_ data: Data) throws -> [any MKGeoJSONObject] {
        _ = data
        throw mk_unsupportedServiceError(.decodingFailed)
    }
}

open class MKGeoJSONFeature: NSObject, MKGeoJSONObject {
    open var identifier: String?
    open var properties: Data?
    open var geometry: [MKShape] = []
}

open class MKDistanceFormatter: Formatter {
    public enum Units: UInt, Hashable, Sendable {
        case `default` = 0
        case metric = 1
        case imperial = 2
        case imperialWithYards = 3
    }

    public enum DistanceUnitStyle: UInt, Hashable, Sendable {
        case `default` = 0
        case abbreviated = 1
        case full = 2
    }

    open var units: Units = .metric
    open var unitStyle: DistanceUnitStyle = .abbreviated
    open var locale: Locale = .current

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open func string(fromDistance distance: Double) -> String {
        guard distance.isFinite else { return "" }
        let meters = abs(distance)
        switch units {
        case .imperial, .imperialWithYards:
            let miles = meters / 1609.344
            if miles >= 0.1 {
                return String(format: "%.1f mi", miles)
            }
            let feet = meters / 0.3048
            return String(format: "%.0f ft", feet)
        case .metric, .default:
            if meters >= 1000 {
                return String(format: "%.1f km", meters / 1000)
            }
            return String(format: "%.0f m", meters)
        }
    }

    open func distance(from distance: String) -> Double {
        let trimmed = distance.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        let value = Double(trimmed.split(whereSeparator: { !$0.isNumber && $0 != "." && $0 != "-" }).first.map(String.init) ?? "") ?? 0
        if trimmed.lowercased().contains("km") { return value * 1000 }
        if trimmed.lowercased().contains("mi") { return value * 1609.344 }
        if trimmed.lowercased().contains("ft") { return value * 0.3048 }
        return value
    }
}
