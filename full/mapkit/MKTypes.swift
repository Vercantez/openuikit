import Foundation

public struct MKDirectionsTransportType: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let automobile = MKDirectionsTransportType(rawValue: 1 << 0)
    public static let walking = MKDirectionsTransportType(rawValue: 1 << 1)
    public static let transit = MKDirectionsTransportType(rawValue: 1 << 2)
    public static let cycling = MKDirectionsTransportType(rawValue: 1 << 3)
    public static let any = MKDirectionsTransportType(rawValue: 0x0FFF_FFFF)
}

public enum MKMapType: UInt, Sendable, Equatable, Hashable {
    case standard = 0
    case satellite = 1
    case hybrid = 2
    case satelliteFlyover = 3
    case hybridFlyover = 4
    case mutedStandard = 5
}

public enum MKFeatureVisibility: Int, Sendable, Equatable, Hashable {
    case adaptive = 0
    case hidden = 1
    case visible = 2
}

public enum MKOverlayLevel: Int, Sendable, Equatable, Hashable {
    case aboveRoads = 0
    case aboveLabels = 1
}

public enum MKUserTrackingMode: Int, Sendable, Equatable, Hashable {
    case none = 0
    case follow = 1
    case followWithHeading = 2
}

public enum MKPinAnnotationColor: UInt, Sendable, Equatable, Hashable {
    case red = 0
    case green = 1
    case purple = 2
}

public enum MKLookAroundBadgePosition: Int, Sendable, Equatable, Hashable {
    case topLeading = 0
    case topTrailing = 1
    case bottomTrailing = 2
}

public struct MKMapFeatureOptions: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let pointsOfInterest = MKMapFeatureOptions(rawValue: 1 << 0)
    public static let territories = MKMapFeatureOptions(rawValue: 1 << 1)
    public static let physicalFeatures = MKMapFeatureOptions(rawValue: 1 << 2)
}

public enum MKLocalSearchRegionPriority: Int, Sendable, Equatable, Hashable {
    case `default` = 0
    case required = 1
}

/// Typed `CGFloat` wrapper. Header constants 1000 / 750 / 250 come from the
/// pinned macios binding of `MKFeatureDisplayPriority`.
public struct MKFeatureDisplayPriority: RawRepresentable, Hashable, Sendable {
    public var rawValue: CGFloat

    public init(rawValue: CGFloat) {
        self.rawValue = rawValue
    }

    public static let required = MKFeatureDisplayPriority(rawValue: 1000)
    public static let defaultHigh = MKFeatureDisplayPriority(rawValue: 750)
    public static let defaultLow = MKFeatureDisplayPriority(rawValue: 250)
}

/// Typed `CGFloat` wrapper. Linux uses 1000 / 1000 / 500 / 0 pending an
/// Apple-oracle probe of the four named constants.
public struct MKAnnotationViewZPriority: RawRepresentable, Hashable, Sendable {
    public var rawValue: CGFloat

    public init(rawValue: CGFloat) {
        self.rawValue = rawValue
    }

    public static let max = MKAnnotationViewZPriority(rawValue: 1000)
    public static let defaultSelected = MKAnnotationViewZPriority(rawValue: 1000)
    public static let defaultUnselected = MKAnnotationViewZPriority(rawValue: 500)
    public static let min = MKAnnotationViewZPriority(rawValue: 0)
}

open class MKDirections: NSObject {
    public enum RoutePreference: Int, Sendable, Equatable, Hashable {
        case any = 0
        case avoid = 1
    }

    public typealias DirectionsHandler = (Response?, (any Error)?) -> Void
    public typealias ETAHandler = (ETAResponse?, (any Error)?) -> Void

    open class Response: NSObject {}
    open class ETAResponse: NSObject {}
}

open class MKLocalSearch: NSObject {
    public struct ResultType: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let address = ResultType(rawValue: 1 << 0)
        public static let pointOfInterest = ResultType(rawValue: 1 << 1)
        public static let physicalFeature = ResultType(rawValue: 1 << 2)
    }

    public typealias CompletionHandler = (Response?, (any Error)?) -> Void

    open class Response: NSObject {}
}

open class MKLocalSearchCompleter: NSObject {
    public struct ResultType: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let address = ResultType(rawValue: 1 << 0)
        public static let pointOfInterest = ResultType(rawValue: 1 << 1)
        public static let query = ResultType(rawValue: 1 << 2)
        public static let physicalFeature = ResultType(rawValue: 1 << 3)
    }

    public enum FilterType: Int, Sendable, Equatable, Hashable {
        case locationsAndQueries = 0
        case locationsOnly = 1
    }
}

open class MKAnnotationView: NSObject {
    public enum CollisionMode: Int, Sendable, Equatable, Hashable {
        case rectangle = 0
        case circle = 1
        case none = 2
    }

    public enum DragState: UInt, Sendable, Equatable, Hashable {
        case none = 0
        case starting = 1
        case dragging = 2
        case canceling = 3
        case ending = 4
    }
}

open class MKMapConfiguration: NSObject {
    public enum ElevationStyle: Int, Sendable, Equatable, Hashable {
        case flat = 0
        case realistic = 1
    }
}

open class MKStandardMapConfiguration: MKMapConfiguration {
    public enum EmphasisStyle: Int, Sendable, Equatable, Hashable {
        case `default` = 0
        case muted = 1
    }
}

open class MKScaleView: NSObject {
    public enum Alignment: Int, Sendable, Equatable, Hashable {
        case leading = 0
        case trailing = 1
        case center = 2
    }
}

open class MKMapFeatureAnnotation: NSObject {
    public enum FeatureType: Int, Sendable, Equatable, Hashable {
        case pointOfInterest = 0
        case territory = 1
        case physicalFeature = 2
    }
}

open class MKSelectionAccessory: NSObject {
    public struct MapItemDetailPresentationStyle {
        public enum CalloutStyle: Int, Sendable, Equatable, Hashable {
            case automatic = 0
            case full = 1
            case compact = 2
        }
    }
}

open class MKAddressRepresentations: NSObject {
    public enum ContextStyle: Int, Sendable, Equatable, Hashable {
        case automatic = 0
        case full = 1
        case short = 2
    }
}
