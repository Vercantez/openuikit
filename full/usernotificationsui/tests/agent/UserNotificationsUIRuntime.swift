import Foundation
import UserNotificationsUI

#if canImport(UIKit)
import UIKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif

enum UserNotificationsUIRuntime {
    static func runStandaloneSurface() {
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
    }
}

UserNotificationsUIRuntime.runStandaloneSurface()
#if canImport(UIKit) && canImport(UserNotifications)
print("USERNOTIFICATIONSUI_STAGED_RUNTIME_SKIPPED_IN_SEALED_GATE")
#else
print("USERNOTIFICATIONSUI_STANDALONE_ONLY")
#endif
print("USERNOTIFICATIONSUI_AGENT_RUNTIME_OK")
