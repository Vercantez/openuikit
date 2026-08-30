// Reminder-shaped consumer file.  Keep its import topology exact: this view
// layer sees UIKit and does not import Foundation or OpenUIKit directly.
import UIKit

func proveUIKitOnlyNotificationIdentities() {
    let _: UIKit.Notification.Type = foundationNotificationMetatype()
    let _: UIKit.Notification.Name.Type = foundationNotificationNameMetatype()
    let _: UIKit.NotificationCenter.Type = foundationNotificationCenterMetatype()
    let _: UIKit.OperationQueue.Type = foundationOperationQueueMetatype()

    // This member was declared in the Foundation-only file.  It is visible
    // here only when both modules expose the same Notification.Name identity.
    let _: UIKit.Notification.Name = .guestReminderDidChange

#if canImport(ObjectiveC)
    let _: UIKit.NSNotification.Type = foundationNSNotificationMetatype()
#endif
}
