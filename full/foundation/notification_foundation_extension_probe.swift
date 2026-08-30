// Reminder-shaped producer file.  Keep its import topology exact: the model
// layer sees Foundation and does not import UIKit or OpenUIKit.
import Foundation

extension Notification.Name {
    static let guestReminderDidChange =
        Notification.Name("GuestReminderDidChange")
}

func foundationNotificationMetatype() -> Foundation.Notification.Type {
    Foundation.Notification.self
}

func foundationNotificationNameMetatype() -> Foundation.Notification.Name.Type {
    Foundation.Notification.Name.self
}

func foundationNotificationCenterMetatype() -> Foundation.NotificationCenter.Type {
    Foundation.NotificationCenter.self
}

func foundationOperationQueueMetatype() -> Foundation.OperationQueue.Type {
    Foundation.OperationQueue.self
}

#if canImport(ObjectiveC)
func foundationNSNotificationMetatype() -> Foundation.NSNotification.Type {
    Foundation.NSNotification.self
}
#endif
