import Foundation
import UserNotificationsUI

private final class MinimalContentExtension: NSObject, UNNotificationContentExtension {
    var receivedDates: [Date] = []

    func didReceive(_ notification: UNNotification) {
        receivedDates.append(notification.date)
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

@MainActor
enum UserNotificationsUIRuntime {
    static func runSynchronousSurface() {
        precondition(!UserNotificationsUIHost.contentExtensionHostAvailable)
        precondition(!UserNotificationsUIHost.appleNotificationServiceAvailable)
        precondition(!UserNotificationsUIHost.mediaPlaybackHostAvailable)

        precondition(
            UNNotificationContentExtensionMediaPlayPauseButtonType.none.rawValue == 0
        )
        precondition(
            UNNotificationContentExtensionMediaPlayPauseButtonType.default.rawValue == 1
        )
        precondition(
            UNNotificationContentExtensionMediaPlayPauseButtonType.overlay.rawValue == 2
        )
        precondition(
            UNNotificationContentExtensionMediaPlayPauseButtonType(rawValue: 0)
                == UNNotificationContentExtensionMediaPlayPauseButtonType.none
        )
        precondition(UNNotificationContentExtensionMediaPlayPauseButtonType(rawValue: 1) == .default)
        precondition(UNNotificationContentExtensionMediaPlayPauseButtonType(rawValue: 2) == .overlay)
        precondition(UNNotificationContentExtensionMediaPlayPauseButtonType(rawValue: 99) == nil)
        precondition(
            UNNotificationContentExtensionMediaPlayPauseButtonType.none
                != UNNotificationContentExtensionMediaPlayPauseButtonType.overlay
        )
        precondition(
            UNNotificationContentExtensionMediaPlayPauseButtonType.none.hashValue
                == UNNotificationContentExtensionMediaPlayPauseButtonType.none.hashValue
        )
        var buttonHasher = Hasher()
        UNNotificationContentExtensionMediaPlayPauseButtonType.default.hash(into: &buttonHasher)
        _ = buttonHasher.finalize()

        precondition(UNNotificationContentExtensionResponseOption.doNotDismiss.rawValue == 0)
        precondition(UNNotificationContentExtensionResponseOption.dismiss.rawValue == 1)
        precondition(
            UNNotificationContentExtensionResponseOption.dismissAndForwardAction.rawValue == 2
        )
        precondition(UNNotificationContentExtensionResponseOption(rawValue: 0) == .doNotDismiss)
        precondition(UNNotificationContentExtensionResponseOption(rawValue: 1) == .dismiss)
        precondition(
            UNNotificationContentExtensionResponseOption(rawValue: 2) == .dismissAndForwardAction
        )
        precondition(UNNotificationContentExtensionResponseOption(rawValue: 7) == nil)
        precondition(
            UNNotificationContentExtensionResponseOption.dismiss
                != UNNotificationContentExtensionResponseOption.doNotDismiss
        )
        precondition(
            UNNotificationContentExtensionResponseOption.dismiss.hashValue
                == UNNotificationContentExtensionResponseOption.dismiss.hashValue
        )
        var optionHasher = Hasher()
        UNNotificationContentExtensionResponseOption.doNotDismiss.hash(into: &optionHasher)
        _ = optionHasher.finalize()

        let notification = UNNotification(date: Date(timeIntervalSince1970: 1_700_000_000))
        let minimal = MinimalContentExtension()
        minimal.didReceive(notification)
        precondition(minimal.receivedDates == [notification.date])
        precondition(minimal.mediaPlayPauseButtonType == UNNotificationContentExtensionMediaPlayPauseButtonType.none)
        precondition(minimal.mediaPlayPauseButtonFrame == .zero)
        let defaultTint = minimal.mediaPlayPauseButtonTintColor
        precondition(defaultTint.isEqual(UIColor(red: 0, green: 0, blue: 0, alpha: 1)))
        minimal.mediaPlay()
        minimal.mediaPause()

        let media = MediaContentExtension()
        media.didReceive(notification)
        media.mediaPlay()
        media.mediaPlay()
        media.mediaPause()
        precondition(media.played == 2)
        precondition(media.paused == 1)
        precondition(media.mediaPlayPauseButtonType == .overlay)
        precondition(
            media.mediaPlayPauseButtonFrame == CGRect(x: 8, y: 16, width: 44, height: 44)
        )
        precondition(
            media.mediaPlayPauseButtonTintColor.isEqual(
                UIColor(red: 1, green: 0, blue: 0, alpha: 1)
            )
        )
        let copiedTint = media.mediaPlayPauseButtonTintColor.copy() as? UIColor
        precondition(copiedTint?.isEqual(media.mediaPlayPauseButtonTintColor) == true)

        let context = NSExtensionContext()
        let reply = UNNotificationAction(identifier: "reply", title: "Reply")
        let later = UNNotificationAction(identifier: "later", title: "Later")
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
            context.hostEvents
                == [
                    .notificationActionsUpdated(count: 2),
                    .notificationActionsUpdated(count: 0),
                    .dismissRequested,
                    .defaultActionRequested,
                    .mediaPlayingStarted,
                    .mediaPlayingPaused,
                ]
        )
    }

    static func runAsyncSurface() async {
        let notification = UNNotification(date: Date(timeIntervalSince1970: 42))
        let response = UNNotificationResponse(
            notification: notification,
            actionIdentifier: "reply"
        )

        let minimal = MinimalContentExtension()
        let defaultOption = await minimal.didReceive(response)
        precondition(defaultOption == .doNotDismiss)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            minimal.didReceive(response) { option in
                precondition(option == .doNotDismiss)
                continuation.resume()
            }
        }

        let media = MediaContentExtension()
        let overridden = await media.didReceive(response)
        precondition(overridden == .dismissAndForwardAction)
        precondition(media.lastResponseOption == .dismissAndForwardAction)
    }
}

UserNotificationsUIRuntime.runSynchronousSurface()
await UserNotificationsUIRuntime.runAsyncSurface()
print("USERNOTIFICATIONSUI_AGENT_RUNTIME_OK")
