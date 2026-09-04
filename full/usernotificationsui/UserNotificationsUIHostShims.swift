import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif

// Isolated host-gate stand-ins. These exist only when the real modules cannot
// be imported. They are not UIKit or UserNotifications ABI and must not be
// cited as proof of those identities.

#if !canImport(UIKit)
open class UIColor: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
#endif

#if !canImport(UserNotifications)
open class UNNotification: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class UNNotificationResponse: NSObject, @unchecked Sendable {
    public let actionIdentifier: String
    public let notification: UNNotification

    public init(notification: UNNotification, actionIdentifier: String) {
        self.notification = notification
        self.actionIdentifier = actionIdentifier
        super.init()
    }
}
#endif
