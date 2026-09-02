import Foundation

open class MKAddress: NSObject {
    public let fullAddress: String
    public let shortAddress: String?

    public init?(fullAddress: String, shortAddress: String?) {
        guard !fullAddress.isEmpty else { return nil }
        self.fullAddress = fullAddress
        self.shortAddress = shortAddress
        super.init()
    }
}

open class MKAddressFilter: NSObject {
    public struct Options: OptionSet, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let country = Options(rawValue: 1 << 0)
        public static let administrativeArea = Options(rawValue: 1 << 1)
        public static let subAdministrativeArea = Options(rawValue: 1 << 2)
        public static let locality = Options(rawValue: 1 << 3)
        public static let subLocality = Options(rawValue: 1 << 4)
        public static let postalCode = Options(rawValue: 1 << 5)
    }

    private enum Mode {
        case including
        case excluding
    }

    private let mode: Mode
    private let options: Options

    public init(including options: Options) {
        self.mode = .including
        self.options = options
        super.init()
    }

    public init(includingOptions options: Options) {
        self.mode = .including
        self.options = options
        super.init()
    }

    public init(excluding options: Options) {
        self.mode = .excluding
        self.options = options
        super.init()
    }

    public init(excludingOptions options: Options) {
        self.mode = .excluding
        self.options = options
        super.init()
    }

    public class var includingAll: MKAddressFilter {
        MKAddressFilter(including: [
            .country, .administrativeArea, .subAdministrativeArea,
            .locality, .subLocality, .postalCode
        ])
    }

    public class var excludingAll: MKAddressFilter {
        MKAddressFilter(excluding: [
            .country, .administrativeArea, .subAdministrativeArea,
            .locality, .subLocality, .postalCode
        ])
    }

    public func includes(_ options: Options) -> Bool {
        switch mode {
        case .including:
            return self.options.contains(options)
        case .excluding:
            return self.options.isDisjoint(with: options)
        }
    }

    public func excludes(_ options: Options) -> Bool {
        !includes(options)
    }
}

open class MKAddressRepresentations: NSObject {
    public enum ContextStyle: Int, Hashable, Sendable {
        case automatic = 0
        case short = 1
        case full = 2
    }

    public var cityName: String?
    public var cityWithContext: String?
    public var regionName: String?
    private var storedFullAddress: String?

    public override init() {
        super.init()
    }

    public init(fullAddress: String?, cityName: String?, regionName: String?) {
        self.storedFullAddress = fullAddress
        self.cityName = cityName
        self.regionName = regionName
        self.cityWithContext = cityName
        super.init()
    }

    open func fullAddress(includingRegion: Bool, singleLine: Bool) -> String? {
        _ = singleLine
        guard let storedFullAddress else { return nil }
        if includingRegion, let regionName, !storedFullAddress.contains(regionName) {
            return storedFullAddress + ", " + regionName
        }
        return storedFullAddress
    }

    open func cityWithContext(_ style: ContextStyle) -> String? {
        switch style {
        case .automatic, .short:
            return cityName
        case .full:
            if let cityName, let regionName {
                return cityName + ", " + regionName
            }
            return cityName
        }
    }
}

open class MKPointOfInterestFilter: NSObject {
    private enum Mode {
        case includingAll
        case excludingAll
        case including
        case excluding
    }

    public private(set) var includedCategories: [MKPointOfInterestCategory]
    public private(set) var excludedCategories: [MKPointOfInterestCategory]
    private let mode: Mode

    public override init() {
        self.includedCategories = []
        self.excludedCategories = []
        self.mode = .includingAll
        super.init()
    }

    public init(including categories: [MKPointOfInterestCategory]) {
        self.includedCategories = categories
        self.excludedCategories = []
        self.mode = .including
        super.init()
    }

    public init(excluding categories: [MKPointOfInterestCategory]) {
        self.includedCategories = []
        self.excludedCategories = categories
        self.mode = .excluding
        super.init()
    }

    public class var includingAll: MKPointOfInterestFilter {
        MKPointOfInterestFilter()
    }

    public class var excludingAll: MKPointOfInterestFilter {
        MKPointOfInterestFilter(mode: .excludingAll)
    }

    private init(mode: Mode) {
        self.includedCategories = []
        self.excludedCategories = []
        self.mode = mode
        super.init()
    }

    open func includes(_ category: MKPointOfInterestCategory) -> Bool {
        switch mode {
        case .includingAll:
            return true
        case .excludingAll:
            return false
        case .including:
            return includedCategories.contains(category)
        case .excluding:
            return !excludedCategories.contains(category)
        }
    }

    open func excludes(_ category: MKPointOfInterestCategory) -> Bool {
        !includes(category)
    }
}

open class MKMapItem: NSObject {
    public class Identifier: NSObject, RawRepresentable {
        public typealias RawValue = String
        public let rawValue: String

        public var identifierString: String { rawValue }

        public required init?(rawValue: String) {
            self.rawValue = rawValue
            super.init()
        }

        public init(identifierString: String) {
            self.rawValue = identifierString
            super.init()
        }

        public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
            lhs.rawValue == rhs.rawValue
        }

        public override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? Identifier else { return false }
            return rawValue == other.rawValue
        }

        public override var hash: Int { rawValue.hashValue }
    }

    open var name: String?
    open var phoneNumber: String?
    open var url: URL?
    open var isCurrentLocation: Bool
    open var pointOfInterestCategory: MKPointOfInterestCategory?
    open var identifier: Identifier?
    open var address: MKAddress?
    open var addressRepresentations: MKAddressRepresentations?
    open var timeZone: TimeZone?

    public override init() {
        self.isCurrentLocation = false
        super.init()
    }

    public init(address: MKAddress?) {
        self.address = address
        self.isCurrentLocation = false
        super.init()
        self.name = address?.shortAddress ?? address?.fullAddress
    }

    open class func forCurrentLocation() -> MKMapItem {
        let item = MKMapItem()
        item.isCurrentLocation = true
        item.name = "Current Location"
        return item
    }

    open func openInMaps(launchOptions: [String: Any]? = nil) -> Bool {
        _ = launchOptions
        return false
    }

    open class func openMaps(
        with mapItems: [MKMapItem],
        launchOptions: [String: Any]? = nil
    ) -> Bool {
        _ = (mapItems, launchOptions)
        return false
    }
}

open class MKSelectionAccessory: NSObject {
    public class MapItemDetailPresentationStyle: NSObject {
        public enum CalloutStyle: Int, Hashable, Sendable {
            case automatic = 0
            case full = 1
            case compact = 2
        }

        fileprivate enum Kind {
            case automatic
            case callout(CalloutStyle)
            case openInMaps
        }

        private let kind: Kind

        private init(kind: Kind) {
            self.kind = kind
            super.init()
        }

        public class var callout: MapItemDetailPresentationStyle {
            MapItemDetailPresentationStyle(kind: .callout(.automatic))
        }

        public class var openInMaps: MapItemDetailPresentationStyle {
            MapItemDetailPresentationStyle(kind: .openInMaps)
        }

        public class func callout(_ style: CalloutStyle) -> MapItemDetailPresentationStyle {
            MapItemDetailPresentationStyle(kind: .callout(style))
        }

        public class func automatic(
            presentationViewController: AnyObject? = nil
        ) -> MapItemDetailPresentationStyle {
            _ = presentationViewController
            return MapItemDetailPresentationStyle(kind: .automatic)
        }
    }

    public let presentationStyle: MapItemDetailPresentationStyle

    private init(presentationStyle: MapItemDetailPresentationStyle) {
        self.presentationStyle = presentationStyle
        super.init()
    }

    open class func mapItemDetail(
        _ presentationStyle: MapItemDetailPresentationStyle
    ) -> MKSelectionAccessory {
        MKSelectionAccessory(presentationStyle: presentationStyle)
    }
}
