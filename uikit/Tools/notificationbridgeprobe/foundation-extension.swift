// Deliberately imports only the app-facing Foundation umbrella assembled by
// the guest gate. Reminder declares its notification-name extension this way.

import Foundation

extension Notification.Name {
    static let openUIKitGuestProbe = Notification.Name("OpenUIKitGuestProbe")
    static let openUIKitGuestOther = Notification.Name("OpenUIKitGuestOther")
}

// The UIKit-only file cannot qualify this module under production's build
// order (UIKit is compiled before the app-facing Foundation shim). File-scoped
// imports are intentional: return the Foundation-side identities for the
// UIKit-only main to compare without weakening its import topology.
func foundationNotificationType() -> Any.Type { Notification.self }
func foundationNSNotificationType() -> Any.Type { NSNotification.self }
func foundationNotificationCenterType() -> Any.Type { NotificationCenter.self }
func foundationOperationQueueType() -> Any.Type { OperationQueue.self }
func foundationDefaultNotificationCenter() -> NotificationCenter {
    NotificationCenter.default
}
