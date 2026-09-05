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

open class MKAddress: NSObject {
    public let fullAddress: String
    public let shortAddress: String?

    public init?(fullAddress: String, shortAddress: String?) {
        if fullAddress.isEmpty { return nil }
        self.fullAddress = fullAddress
        self.shortAddress = shortAddress
        super.init()
    }
}

open class MKAddressRepresentations: NSObject {
    public enum ContextStyle: Int, Sendable, Equatable, Hashable {
        case automatic = 0
        case full = 1
        case short = 2
    }

    open var cityName: String?
    open var cityWithContext: String?
    open var regionName: String?
    open var region: Locale.Region?

    public override init() { super.init() }

    open func cityWithContext(_ style: ContextStyle) -> String? {
        switch style {
        case .short: return cityName
        case .full, .automatic: return cityWithContext ?? cityName
        }
    }

    open func fullAddress(includingRegion: Bool, singleLine: Bool) -> String? {
        _ = singleLine
        var parts: [String] = []
        if let cityName { parts.append(cityName) }
        if includingRegion, let regionName { parts.append(regionName) }
        if parts.isEmpty { return nil }
        return parts.joined(separator: ", ")
    }
}

#if canImport(CoreLocation)
/// Darwin `CLPlacemark.init()` is `API_UNAVAILABLE`; `init(coder:)` with an
/// empty keyed coder yields a blank placemark (macOS 26.1 probe 2026-09-05).
private final class MKEmptyKeyedCoder: NSCoder {
    override var allowsKeyedCoding: Bool { true }
    override func containsValue(forKey key: String) -> Bool {
        _ = key
        return false
    }
    override func decodeObject(forKey key: String) -> Any? {
        _ = key
        return nil
    }
    override func decodeBool(forKey key: String) -> Bool {
        _ = key
        return false
    }
    override func decodeInt32(forKey key: String) -> Int32 {
        _ = key
        return 0
    }
    override func decodeInt64(forKey key: String) -> Int64 {
        _ = key
        return 0
    }
    override func decodeFloat(forKey key: String) -> Float {
        _ = key
        return 0
    }
    override func decodeDouble(forKey key: String) -> Double {
        _ = key
        return 0
    }
    override func decodeInteger(forKey key: String) -> Int {
        _ = key
        return 0
    }
}
#endif

open class MKPlacemark: CLPlacemark, MKAnnotation, @unchecked Sendable {
    public private(set) var coordinate: CLLocationCoordinate2D
    private var storedName: String?
    private var storedLocality: String?
    private var storedAdministrativeArea: String?
    private var storedPostalCode: String?
    private var storedCountry: String?
    private var storedISOCountryCode: String?
    private var storedThoroughfare: String?
    private var storedSubThoroughfare: String?

    public var title: String? { storedName }
    public var subtitle: String? { storedLocality }
    public var countryCode: String? { storedISOCountryCode }

    #if canImport(CoreLocation)
    public override var name: String? { storedName }
    public override var locality: String? { storedLocality }
    public override var administrativeArea: String? { storedAdministrativeArea }
    public override var postalCode: String? { storedPostalCode }
    public override var country: String? { storedCountry }
    public override var isoCountryCode: String? { storedISOCountryCode }
    public override var thoroughfare: String? { storedThoroughfare }
    public override var subThoroughfare: String? { storedSubThoroughfare }
    public override var location: CLLocation? {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    #endif

    public init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        #if canImport(CoreLocation)
        super.init(coder: MKEmptyKeyedCoder())!
        #else
        super.init()
        location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        #endif
    }

    public init(coordinate: CLLocationCoordinate2D, addressDictionary: [String: Any]?) {
        self.coordinate = coordinate
        if let dictionary = addressDictionary {
            storedName = dictionary["Name"] as? String
            storedLocality = dictionary["City"] as? String
            storedAdministrativeArea = dictionary["State"] as? String
            storedPostalCode = dictionary["ZIP"] as? String
            storedCountry = dictionary["Country"] as? String
            storedISOCountryCode = dictionary["CountryCode"] as? String
            storedThoroughfare = dictionary["Thoroughfare"] as? String
            storedSubThoroughfare = dictionary["SubThoroughfare"] as? String
        }
        #if canImport(CoreLocation)
        super.init(coder: MKEmptyKeyedCoder())!
        #else
        super.init()
        name = storedName
        locality = storedLocality
        administrativeArea = storedAdministrativeArea
        postalCode = storedPostalCode
        country = storedCountry
        isoCountryCode = storedISOCountryCode
        thoroughfare = storedThoroughfare
        subThoroughfare = storedSubThoroughfare
        location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        #endif
    }

    public required init?(coder: NSCoder) {
        coordinate = CLLocationCoordinate2D()
        #if canImport(CoreLocation)
        super.init(coder: coder)
        #else
        _ = coder
        super.init()
        return nil
        #endif
    }
}

open class MKMapItem: NSObject {
    public final class Identifier: NSObject, NSCopying, Codable {
        public typealias RawValue = String
        public let rawValue: String

        public init?(rawValue string: String) {
            if string.isEmpty { return nil }
            rawValue = string
            super.init()
        }

        public convenience init?(identifierString string: String) {
            self.init(rawValue: string)
        }

        public init?(coder: NSCoder) {
            _ = coder
            return nil
        }

        public func copy(with zone: NSZone? = nil) -> Any {
            _ = zone
            return Identifier(rawValue: rawValue) ?? Identifier(rawValue: "id")!
        }

        public override var hash: Int { rawValue.hashValue }

        public override func isEqual(_ object: Any?) -> Bool {
            (object as? Identifier)?.rawValue == rawValue
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            rawValue = try container.decode(String.self)
            super.init()
        }
    }

    public private(set) var placemark: MKPlacemark
    open var name: String?
    open var phoneNumber: String?
    open var url: URL?
    open var timeZone: TimeZone?
    open var pointOfInterestCategory: MKPointOfInterestCategory?
    public private(set) var isCurrentLocation: Bool = false
    public private(set) var identifier: Identifier?
    public var alternateIdentifiers: Set<Identifier> = []
    open var address: MKAddress?
    open var addressRepresentations: MKAddressRepresentations?

    public var location: CLLocation {
        placemark.location ?? CLLocation(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude)
    }

    public init(placemark: MKPlacemark) {
        self.placemark = placemark
        self.name = placemark.name
        super.init()
    }

    public init(location: CLLocation, address: MKAddress?) {
        self.placemark = MKPlacemark(coordinate: location.coordinate)
        self.address = address
        super.init()
    }

    public init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open class func forCurrentLocation() -> MKMapItem {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)))
        item.isCurrentLocation = true
        item.name = "Current Location"
        return item
    }

    /// Linux has no Maps app: listed no-op, returns false.
    open func openInMaps(launchOptions: [String: Any]? = nil) -> Bool {
        _ = launchOptions
        return false
    }

    open func openInMaps(launchOptions: [String: Any]? = nil, from scene: UIScene?) async -> Bool {
        _ = scene
        return openInMaps(launchOptions: launchOptions)
    }

    open class func openMaps(with mapItems: [MKMapItem], launchOptions: [String: Any]? = nil) -> Bool {
        _ = (mapItems, launchOptions)
        return false
    }

    open class func openMaps(
        with mapItems: [MKMapItem],
        launchOptions: [String: Any]? = nil,
        from scene: UIScene?
    ) async -> Bool {
        _ = scene
        return openMaps(with: mapItems, launchOptions: launchOptions)
    }
}

open class MKSelectionAccessory: NSObject {
    public final class MapItemDetailPresentationStyle: NSObject {
        public enum CalloutStyle: Int, Sendable, Equatable, Hashable {
            case automatic = 0
            case full = 1
            case compact = 2
        }

        public static var callout: MapItemDetailPresentationStyle { MapItemDetailPresentationStyle() }
        public static var openInMaps: MapItemDetailPresentationStyle { MapItemDetailPresentationStyle() }

        public static func callout(_ style: CalloutStyle = .automatic) -> MapItemDetailPresentationStyle {
            _ = style
            return MapItemDetailPresentationStyle()
        }

        public static func automatic(presentationViewController: UIViewController? = nil) -> MapItemDetailPresentationStyle {
            _ = presentationViewController
            return MapItemDetailPresentationStyle()
        }

        public class func sheet(presentedFrom viewController: UIViewController) -> MapItemDetailPresentationStyle {
            _ = viewController
            return MapItemDetailPresentationStyle()
        }
    }

    public class func mapItemDetail(_ presentationStyle: MapItemDetailPresentationStyle) -> MKSelectionAccessory {
        _ = presentationStyle
        return MKSelectionAccessory()
    }
}

open class MKMapItemDetailViewController: UIViewController {
    open weak var delegate: (any MKMapItemDetailViewControllerDelegate)?
    open var mapItem: MKMapItem?

    public init(mapItem: MKMapItem?) {
        self.mapItem = mapItem
        super.init()
    }

    public init(mapItem: MKMapItem?, displaysMap: Bool) {
        self.mapItem = mapItem
        super.init()
        _ = displaysMap
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

public protocol MKMapItemDetailViewControllerDelegate: AnyObject {
    func mapItemDetailViewControllerDidFinish(_ detailViewController: MKMapItemDetailViewController)
}

extension MKMapItemDetailViewControllerDelegate {
    public func mapItemDetailViewControllerDidFinish(_ detailViewController: MKMapItemDetailViewController) {
        _ = detailViewController
    }
}

open class MKMapItemRequest: NSObject {
    public private(set) var mapItemIdentifier: MKMapItem.Identifier?
    public private(set) var mapFeatureAnnotation: MKMapFeatureAnnotation?
    public private(set) var featureAnnotation: MKMapFeatureAnnotation = MKMapFeatureAnnotation()
    public private(set) var isCancelled: Bool = false
    public private(set) var isLoading: Bool = false

    public init(mapItemIdentifier identifier: MKMapItem.Identifier) {
        mapItemIdentifier = identifier
        super.init()
    }

    public init(mapFeatureAnnotation: MKMapFeatureAnnotation) {
        self.mapFeatureAnnotation = mapFeatureAnnotation
        self.featureAnnotation = mapFeatureAnnotation
        super.init()
    }

    open func cancel() {
        isCancelled = true
        isLoading = false
    }

    open func getMapItem(completionHandler: @escaping (MKMapItem?, (any Error)?) -> Void) {
        isLoading = false
        completionHandler(nil, MKError(.serverFailure))
    }
}

#if os(Linux)
open class NSUserActivity: NSObject {
    public var activityType: String
    public var mapItem: MKMapItem!

    public init(activityType: String) {
        self.activityType = activityType
        super.init()
    }
}
#else
extension NSUserActivity {
    public var mapItem: MKMapItem! {
        get { nil }
        set { _ = newValue }
    }
}
#endif

extension NSValue {
    public convenience init(MKCoordinate coordinate: CLLocationCoordinate2D) {
        var value = coordinate
        self.init(bytes: &value, objCType: "dd")
    }

    public convenience init(MKCoordinateSpan span: MKCoordinateSpan) {
        var value = span
        self.init(bytes: &value, objCType: "dd")
    }

    public var mkCoordinateValue: CLLocationCoordinate2D {
        var value = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        getValue(&value)
        return value
    }

    public var mkCoordinateSpanValue: MKCoordinateSpan {
        var value = MKCoordinateSpan()
        getValue(&value)
        return value
    }
}
