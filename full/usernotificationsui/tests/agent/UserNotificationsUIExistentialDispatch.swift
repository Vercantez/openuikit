import Foundation
import UIKit
import UserNotificationsUI

@_spi(OpenUIKitHost) import UserNotifications
@_spi(OpenUIKitHost) import UserNotificationsUI

private final class MinimalContentExtension: NSObject, UNNotificationContentExtension {
    var received: [String] = []

    func didReceive(_ notification: UNNotification) {
        received.append(notification.request.identifier)
    }
}

private final class MediaContentExtension: NSObject, UNNotificationContentExtension {
    var played = 0
    var paused = 0
    var lastResponseOption: UNNotificationContentExtensionResponseOption?

    func didReceive(_ notification: UNNotification) {
        _ = notification
    }

    func didReceive(
        _ response: UNNotificationResponse
    ) async -> UNNotificationContentExtensionResponseOption {
        _ = response
        lastResponseOption = .dismissAndForwardAction
        return .dismissAndForwardAction
    }

    func didReceive(
        _ response: UNNotificationResponse,
        completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) ->
            Void
    ) {
        _ = response
        lastResponseOption = .dismiss
        completion(.dismiss)
    }

    func mediaPlay() {
        played += 1
    }

    func mediaPause() {
        paused += 1
    }

    var mediaPlayPauseButtonType: UNNotificationContentExtensionMediaPlayPauseButtonType {
        .overlay
    }

    var mediaPlayPauseButtonFrame: CGRect {
        CGRect(x: 8, y: 16, width: 44, height: 44)
    }

    var mediaPlayPauseButtonTintColor: UIColor {
        UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    }
}

@main
enum UserNotificationsUIExistentialDispatch {
    static func main() async {
        let content = UNMutableNotificationContent()
        content.body = "dispatch"
        let request = UNNotificationRequest(
            identifier: "dispatch",
            content: content,
            trigger: nil
        )
        let notification = UNNotification(date: Date(timeIntervalSince1970: 42), request: request)
        let response = UNNotificationResponse(
            notification: notification,
            actionIdentifier: "reply"
        )

        let minimalConcrete = MinimalContentExtension()
        let minimal: any UNNotificationContentExtension = minimalConcrete
        await MainActor.run {
            minimal.didReceive(notification)
        }
        precondition(minimalConcrete.received == ["dispatch"])
        precondition(
            minimal.mediaPlayPauseButtonType
                == UNNotificationContentExtensionMediaPlayPauseButtonType.none
        )
        precondition(minimal.mediaPlayPauseButtonFrame == .zero)
        let defaultTint = minimal.mediaPlayPauseButtonTintColor
        precondition(defaultTint.isEqual(UIColor(red: 0, green: 0, blue: 0, alpha: 1)))
        let defaultOption = await minimal.didReceive(response)
        precondition(defaultOption == .doNotDismiss)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            minimal.didReceive(response) { option in
                precondition(option == .doNotDismiss)
                continuation.resume()
            }
        }

        let mediaConcrete = MediaContentExtension()
        let media: any UNNotificationContentExtension = mediaConcrete
        media.mediaPlay()
        media.mediaPlay()
        media.mediaPause()
        precondition(mediaConcrete.played == 2)
        precondition(mediaConcrete.paused == 1)
        precondition(media.mediaPlayPauseButtonType == .overlay)
        precondition(media.mediaPlayPauseButtonFrame == CGRect(x: 8, y: 16, width: 44, height: 44))
        precondition(
            media.mediaPlayPauseButtonTintColor.isEqual(UIColor(red: 1, green: 0, blue: 0, alpha: 1))
        )
        let overridden = await media.didReceive(response)
        precondition(overridden == .dismissAndForwardAction)
        precondition(mediaConcrete.lastResponseOption == .dismissAndForwardAction)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            media.didReceive(response) { option in
                precondition(option == .dismiss)
                continuation.resume()
            }
        }
        precondition(mediaConcrete.lastResponseOption == .dismiss)

        let reply = UNNotificationAction(identifier: "reply", title: "Reply")
        let later = UNNotificationAction(identifier: "later", title: "Later")
        let context = NSExtensionContext()
        context.notificationActions = [reply, later]
        precondition(context.notificationActions.count == 2)
        precondition(context.notificationActions[0].identifier == "reply")
        precondition(context.notificationActions[1].title == "Later")
        context.notificationActions = []
        precondition(context.notificationActions.isEmpty)
        context.dismissNotificationContentExtension()
        context.performNotificationDefaultAction()
        context.mediaPlayingStarted()
        precondition(context.notificationContentExtensionDidRequestDismiss)
        precondition(context.notificationContentExtensionDidRequestDefaultAction)
        precondition(context.notificationContentExtensionMediaIsPlaying)
        context.mediaPlayingPaused()
        precondition(!context.notificationContentExtensionMediaIsPlaying)
        precondition(
            context.notificationContentExtensionHostEvents
                == [
                    .notificationActionsUpdated(count: 2),
                    .notificationActionsUpdated(count: 0),
                    .dismissRequested,
                    .defaultActionRequested,
                    .mediaPlayingStarted,
                    .mediaPlayingPaused,
                ]
        )

        print("USERNOTIFICATIONSUI_EXISTENTIAL_DISPATCH_OK")
    }
}
