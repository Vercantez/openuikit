//===----------------------------------------------------------------------===//
// CarPlay
//
// Template, list, and navigation models compile on Linux. Vehicle presentation
// is fail-closed until a host injects a session through @_spi(OpenUIKitHost).
// UIKit and MapKit identities are imported when those modules are staged;
// this module never redefines them.
//===----------------------------------------------------------------------===//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(MapKit)
import MapKit
#endif

// MARK: - Public constants
//
// Numeric values are unattested against iPhoneOS 26.1. They exist so the
// identifiers compile; coverage treats them as declared, not implemented.

public let CPButtonMaximumImageSize = CGSize(width: 0, height: 0)
public let CPGridTemplateMaximumItems = 0
public let CPMaximumListSectionImageSize = CGSize(width: 0, height: 0)
public let CPMaximumMessageItemImageSize = CGSize(width: 0, height: 0)
public let CPMaximumMessageItemLeadingDetailTextImageSize = CGSize(width: 0, height: 0)
public let CPMaximumNumberOfGridImages = 0
public let CPNavigationAlertMinimumDuration: TimeInterval = 0
public let CPNowPlayingButtonMaximumImageSize = CGSize(width: 0, height: 0)
public let CarPlayErrorDomain = "CarPlayErrorDomain"

public typealias CPAlertActionHandler = (CPAlertAction) -> Void
public typealias CPBarButtonHandler = (CPBarButton) -> Void

// MARK: - Host SPI errors and vehicle session

@_spi(OpenUIKitHost)
public enum CarPlayHostError: Error, Equatable, Sendable {
    case vehicleSessionDisconnected
    case templateNotInStack
    case noPresentedTemplate
    case emptyTemplateStack
}

@MainActor
enum CarPlayHostSessionState {
    static var isConnected = false
}

// MARK: - Option sets

public struct CPContentStyle: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let light = CPContentStyle(rawValue: 1 << 0)
    public static let dark = CPContentStyle(rawValue: 1 << 1)
}

public struct CPLimitableUserInterface: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let keyboard = CPLimitableUserInterface(rawValue: 1 << 0)
    public static let lists = CPLimitableUserInterface(rawValue: 1 << 1)
}

public struct CPManeuverDisplayStyle: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let leadingSymbol = CPManeuverDisplayStyle(rawValue: 1 << 0)
    public static let trailingSymbol = CPManeuverDisplayStyle(rawValue: 1 << 1)
    public static let symbolOnly = CPManeuverDisplayStyle(rawValue: 1 << 2)
    public static let instructionOnly = CPManeuverDisplayStyle(rawValue: 1 << 3)
}

#if canImport(UIKit)
extension UISceneSession.Role {
    public static let carTemplateApplication = UISceneSession.Role(
        rawValue: "CPTemplateApplicationSceneSessionRoleApplication"
    )
    public static let CPTemplateApplicationDashboardSceneSessionRoleApplication =
        UISceneSession.Role(
            rawValue: "CPTemplateApplicationDashboardSceneSessionRoleApplication"
        )
    public static let CPTemplateApplicationInstrumentClusterSceneSessionRoleApplication =
        UISceneSession.Role(
            rawValue: "CPTemplateApplicationInstrumentClusterSceneSessionRoleApplication"
        )
}

@_spi(OpenUIKitHost)
public enum CarPlayHostFixtures {
    public static func image() -> UIImage {
        UIImage()
    }

    public static func color() -> UIColor {
        .black
    }
}
#endif

#if canImport(MapKit)
@_spi(OpenUIKitHost)
public enum CarPlayHostMapFixtures {
    public static func mapItem() -> MKMapItem {
        MKMapItem()
    }
}
#endif
