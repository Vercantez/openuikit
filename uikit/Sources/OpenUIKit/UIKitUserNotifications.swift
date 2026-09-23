// The UIKit members that name UserNotifications types. Kept in their own file
// so UIApplication.swift keeps its selective Foundation imports. Apple's UIKit
// exports UserNotifications (its headers import UNNotificationResponse.h), and
// the port's UIKit shim re-exports it under the same condition.

#if (canImport(AppKit) || os(iOS)) && canImport(UserNotifications)
import UserNotifications

extension UISceneConnectionOptions {
    /// The notification response that launched the scene. nil on an ordinary
    /// launch (MEASURED Tools/oracle2/scenelaunchprobe, iOS 26.1). The port
    /// never launches a scene from a notification, so it stays nil.
    public var notificationResponse: UNNotificationResponse? {
        _notificationResponse as? UNNotificationResponse
    }
}

extension UNNotificationResponse {
    /// UIKit's routing of a response to the scene it targets (declared by
    /// UIKit on UNNotificationResponse). The port delivers no notifications
    /// and so has no target scene to report: nil.
    @MainActor public var targetScene: UIScene? { nil }
}
#endif
