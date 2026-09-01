import Foundation
import UIKit
import UserNotificationsUI

@_spi(OpenUIKitHost) import UserNotifications
@_spi(OpenUIKitHost) import UserNotificationsUI

/// Real-integration client. Compiled only against platform Foundation, UIKit,
/// and UserNotifications. Must not be linked to unit-fixture lookalikes.
@main
enum UserNotificationsUIRealIntegration {
    static func main() async {
        let color: UIKit.UIColor = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)
        let content = UNMutableNotificationContent()
        content.body = "integration"
        let request = UNNotificationRequest(
            identifier: "integration",
            content: content,
            trigger: nil
        )
        let notification: UserNotifications.UNNotification = UNNotification(
            date: Date(timeIntervalSince1970: 1),
            request: request
        )

        let receiver = IntegrationContentExtension(tint: color)
        let existential: any UNNotificationContentExtension = receiver
        await MainActor.run {
            existential.didReceive(notification)
        }
        precondition(receiver.received == ["integration"])
        let tint: UIKit.UIColor = existential.mediaPlayPauseButtonTintColor
        _ = tint
        existential.mediaPlay()
        precondition(receiver.played == 1)

        let context = NSExtensionContext()
        let _: Foundation.NSExtensionContext = context
        context.dismissNotificationContentExtension()

        print("USERNOTIFICATIONSUI_REAL_INTEGRATION_OK")
    }
}

private final class IntegrationContentExtension: NSObject, UNNotificationContentExtension {
    let tint: UIColor
    var received: [String] = []
    var played = 0

    init(tint: UIColor) {
        self.tint = tint
    }

    func didReceive(_ notification: UNNotification) {
        received.append(notification.request.identifier)
    }

    func mediaPlay() {
        played += 1
    }

    var mediaPlayPauseButtonTintColor: UIColor { tint }
}
