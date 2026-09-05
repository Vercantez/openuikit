import Foundation

/// Process-local identities reconstructed from the sealed public graph and
/// documented CarPlay programming-guide limits. Numeric sizes and counts are
/// not claimed as Apple ABI bytes.

public let CarPlayErrorDomain = "CarPlayErrorDomain"
public let CPGridTemplateMaximumItems: Int = 8
public let CPMaximumNumberOfGridImages: Int = 9
public let CPNavigationAlertMinimumDuration: TimeInterval = 5
public let CPButtonMaximumImageSize = CGSize(width: 80, height: 80)
public let CPMaximumListSectionImageSize = CGSize(width: 90, height: 90)
public let CPMaximumMessageItemImageSize = CGSize(width: 90, height: 90)
public let CPMaximumMessageItemLeadingDetailTextImageSize = CGSize(width: 90, height: 90)
public let CPNowPlayingButtonMaximumImageSize = CGSize(width: 80, height: 80)

/// Documented navigation-stack depth (root plus four pushed templates).
let CarPlayMaximumTemplateDepth = 5
/// Documented tab-bar cap. Some head units only present four tabs.
let CarPlayDocumentedTabBarMaximum = 5
let CarPlayDocumentedTabBarSomeUnitsMaximum = 4
let CarPlayAlertMaximumActionCount = 2
let CarPlayInformationMaximumItemCount = 10
let CarPlayInformationMaximumActionCount = 3
let CarPlayPointOfInterestMaximumCount = 12

public typealias CPAlertActionHandler = (CPAlertAction) -> Void
public typealias CPBarButtonHandler = (CPBarButton) -> Void

public func NSStringFromCPJunctionType(_ junctionType: CPJunctionType) -> String! {
    String(describing: junctionType)
}
public func NSStringFromCPLaneStatus(_ laneStatus: CPLaneStatus) -> String! {
    String(describing: laneStatus)
}
public func NSStringFromCPManeuverType(_ maneuverType: CPManeuverType) -> String! {
    String(describing: maneuverType)
}
public func NSStringFromCPTrafficSide(_ trafficSide: CPTrafficSide) -> String! {
    String(describing: trafficSide)
}

extension UISceneSession.Role {
    public static let CPTemplateApplicationDashboardSceneSessionRoleApplication =
        UISceneSession.Role(rawValue: "CPTemplateApplicationDashboardSceneSessionRoleApplication")
    public static let CPTemplateApplicationInstrumentClusterSceneSessionRoleApplication =
        UISceneSession.Role(rawValue: "CPTemplateApplicationInstrumentClusterSceneSessionRoleApplication")
    public static let carTemplateApplication =
        UISceneSession.Role(rawValue: "CPTemplateApplicationSceneSessionRoleApplication")
}

public enum CarPlayHostError: Error, CustomNSError, Equatable, Sendable {
    case notConnected
    case templateHierarchyExceeded
    case invalidTemplate
    case templateNotInHierarchy
    case emptyTemplateStack
    case templateLimitExceeded
    case vehicleSurfaceUnavailable

    public static var errorDomain: String { CarPlayErrorDomain }

    public var errorCode: Int {
        switch self {
        case .notConnected: return 1
        case .templateHierarchyExceeded: return 2
        case .invalidTemplate: return 3
        case .templateNotInHierarchy: return 4
        case .emptyTemplateStack: return 5
        case .templateLimitExceeded: return 6
        case .vehicleSurfaceUnavailable: return 7
        }
    }

    public var errorUserInfo: [String: Any] {
        let description: String
        switch self {
        case .notConnected:
            description = "No simulated CarPlay session is connected."
        case .templateHierarchyExceeded:
            description = "Template stack exceeds the documented depth of 5."
        case .invalidTemplate:
            description = "Template is not valid for this presentation."
        case .templateNotInHierarchy:
            description = "Template is not in the interface-controller stack."
        case .emptyTemplateStack:
            description = "Template stack is empty."
        case .templateLimitExceeded:
            description = "Template exceeds a documented item, button, or tab limit."
        case .vehicleSurfaceUnavailable:
            description = "Dashboard and instrument-cluster surfaces are fail-closed on Linux."
        }
        return [NSLocalizedDescriptionKey: description]
    }
}

@MainActor
func carPlayIsPresentable(_ template: CPTemplate) -> Bool {
    template is CPAlertTemplate || template is CPActionSheetTemplate || template is CPVoiceControlTemplate
}

@MainActor
func carPlayValidateListSections(_ sections: [CPListSection]) throws {
    if sections.count > CPListTemplate.maximumSectionCount {
        throw CarPlayHostError.templateLimitExceeded
    }
    let items = sections.reduce(0) { $0 + $1.items.count }
    if items > CPListTemplate.maximumItemCount {
        throw CarPlayHostError.templateLimitExceeded
    }
}

@MainActor
func carPlayValidateGridButtons(_ buttons: [CPGridButton]) throws {
    if buttons.count > CPGridTemplateMaximumItems {
        throw CarPlayHostError.templateLimitExceeded
    }
}

@MainActor
func carPlayValidateTabTemplates(_ templates: [CPTemplate]) throws {
    if templates.count > CPTabBarTemplate.maximumTabCount {
        throw CarPlayHostError.templateLimitExceeded
    }
}

@MainActor
func carPlayValidateAlertActions(_ actions: [CPAlertAction]) throws {
    if actions.count > CPAlertTemplate.maximumActionCount {
        throw CarPlayHostError.templateLimitExceeded
    }
}
