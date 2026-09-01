//===----------------------------------------------------------------------===//
// Portable CarPlay
//
// In-memory template, list, and navigation models compile and are inspectable
// on Linux. Vehicle connection, entitlement grants, instrument-cluster windows,
// and Apple CarPlay UI are fail-closed. A host may drive the template stack
// through SPI; that never claims a car session accepted the templates.
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
// Image-size and count limits below are the portable starting values taken
// from Apple's public CarPlay programming guidance. Exact runtime point sizes
// on a given iOS build remain an oracle question.

public let CPButtonMaximumImageSize = CGSize(width: 44, height: 44)
public let CPGridTemplateMaximumItems = 8
public let CPMaximumListSectionImageSize = CGSize(width: 64, height: 64)
public let CPMaximumMessageItemImageSize = CGSize(width: 90, height: 90)
public let CPMaximumMessageItemLeadingDetailTextImageSize = CGSize(width: 32, height: 32)
public let CPMaximumNumberOfGridImages = 9
public let CPNavigationAlertMinimumDuration: TimeInterval = 5
public let CPNowPlayingButtonMaximumImageSize = CGSize(width: 44, height: 44)
public let CarPlayErrorDomain = "CarPlayErrorDomain"

public typealias CPAlertActionHandler = (CPAlertAction) -> Void
public typealias CPBarButtonHandler = (CPBarButton) -> Void

// MARK: - Portable errors

public struct CarPlayPortableError: Error, Equatable, Sendable, CustomStringConvertible {
    public enum Code: Int, Sendable {
        case notConnectedToVehicle = 1
        case noPresentedTemplate = 2
        case templateNotInStack = 3
        case emptyTemplateStack = 4
        case invalidTabSelection = 5
        case entitlementUnavailable = 6
    }

    public let code: Code
    public var description: String {
        switch code {
        case .notConnectedToVehicle:
            return "No CarPlay vehicle session is available on this host"
        case .noPresentedTemplate:
            return "No template is currently presented"
        case .templateNotInStack:
            return "The requested template is not in the interface stack"
        case .emptyTemplateStack:
            return "The interface template stack is empty"
        case .invalidTabSelection:
            return "The requested tab is not part of this tab bar template"
        case .entitlementUnavailable:
            return "The requested CarPlay entitlement is not granted on this host"
        }
    }

    public var localizedDescription: String { description }

    public init(_ code: Code) {
        self.code = code
    }
}

/// Cross-cutting portable capability. Vehicle, entitlement, and UI paths stay
/// fail-closed unless a host injects a session through SPI.
public enum CarPlayPortable: Sendable {
    public static let supportsVehicleSession = false
    public static let supportsInstrumentClusterWindow = false
    public static let supportsDashboardWindow = false
    public static let supportsNowPlayingSystemUI = false
    public static let supportsMapRendering = false

    public static var hasTemplateEntitlement: Bool { false }
    public static var hasAudioEntitlement: Bool { false }
    public static var hasMapsEntitlement: Bool { false }
    public static var hasCommunicationEntitlement: Bool { false }
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

// MARK: - NSSecureCoding helper

open class CarPlayCodingObject: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}
}
