import Foundation
import UIKit
import UserNotificationsUI

@_spi(OpenUIKitHost) import UserNotifications

@main
enum UserNotificationsUIIdentityConsumer {
    static func main() {
        let color = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)
        let _: UIKit.UIColor = color
        precondition(String(reflecting: UIColor.self).hasPrefix("UIKit."))
        precondition(!String(reflecting: UIColor.self).hasPrefix("UserNotificationsUI."))

        let content = UNMutableNotificationContent()
        content.body = "identity"
        let request = UNNotificationRequest(
            identifier: "identity",
            content: content,
            trigger: nil
        )
        let notification = UNNotification(date: Date(timeIntervalSince1970: 1), request: request)
        let _: UserNotifications.UNNotification = notification
        precondition(String(reflecting: UNNotification.self).contains("UserNotifications.UNNotification"))
        precondition(!String(reflecting: UNNotification.self).hasPrefix("UserNotificationsUI."))

        let context = NSExtensionContext()
        context.dismissNotificationContentExtension()
        let _: NSExtensionContext = context
        precondition(!String(reflecting: NSExtensionContext.self).hasPrefix("UserNotificationsUI."))
        precondition(!String(reflecting: type(of: context)).hasPrefix("UserNotificationsUI."))

        print("USERNOTIFICATIONSUI_IDENTITY_CONSUMER_OK")
        print(
            "USERNOTIFICATIONSUI_IDENTITY_MODULES color=\(String(reflecting: UIColor.self)) notification=\(String(reflecting: UNNotification.self)) context=\(String(reflecting: NSExtensionContext.self))"
        )
    }
}
