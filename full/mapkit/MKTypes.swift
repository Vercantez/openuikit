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
/// pinned macios binding of `MKFeatureDisplayPriority`. Darwin macOS 26.1
/// matches those raw values.
public struct MKFeatureDisplayPriority: RawRepresentable, Hashable, Sendable {
    public var rawValue: CGFloat

    public init(rawValue: CGFloat) {
        self.rawValue = rawValue
    }

    public static let required = MKFeatureDisplayPriority(rawValue: 1000)
    public static let defaultHigh = MKFeatureDisplayPriority(rawValue: 750)
    public static let defaultLow = MKFeatureDisplayPriority(rawValue: 250)
}

/// Typed `CGFloat` wrapper. Darwin macOS 26.1: max/defaultSelected = 1000,
/// defaultUnselected = 500, min = 0.
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
