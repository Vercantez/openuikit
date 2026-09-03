import Foundation

/// Process-local identities. Numeric sizes are unobserved SDK bytes; they are
/// nonzero so callers can read a stable value. They are not Apple-oracle ABI.

public let CarPlayErrorDomain = "CarPlayErrorDomain"
public let CPGridTemplateMaximumItems: Int = 8
public let CPMaximumNumberOfGridImages: Int = 9
public let CPNavigationAlertMinimumDuration: TimeInterval = 5
public let CPButtonMaximumImageSize = CGSize(width: 80, height: 80)
public let CPMaximumListSectionImageSize = CGSize(width: 90, height: 90)
public let CPMaximumMessageItemImageSize = CGSize(width: 90, height: 90)
public let CPMaximumMessageItemLeadingDetailTextImageSize = CGSize(width: 90, height: 90)
public let CPNowPlayingButtonMaximumImageSize = CGSize(width: 80, height: 80)

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

enum CarPlaySessionError: Error {
    case notConnected
    case emptyStack
}

