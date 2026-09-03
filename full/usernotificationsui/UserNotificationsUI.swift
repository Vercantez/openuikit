import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif

/// Media control overlay the system may draw on a notification content extension.
///
/// Raw values follow the pinned `dotnet/macios` `Native` enum (`ulong`) case
/// order in `src/usernotificationsui.cs`. They are not taken from an Apple
/// runtime observation.
public enum UNNotificationContentExtensionMediaPlayPauseButtonType: UInt, Hashable, Sendable {
    case none = 0
    case `default` = 1
    case overlay = 2
}

/// Preferred disposition after a content extension handles a notification action.
///
/// Raw values follow the pinned `dotnet/macios` `Native` enum (`ulong`) case
/// order in `src/usernotificationsui.cs`. Darwin's unimplemented-optional
/// forwarding behavior is unobserved on this host.
public enum UNNotificationContentExtensionResponseOption: UInt, Hashable, Sendable {
    case doNotDismiss = 0
    case dismiss = 1
    case dismissAndForwardAction = 2
}

/// Notification content-extension protocol.
///
/// Apple's Objective-C surface marks every member except `didReceive(_:)` as
/// optional. Linux has no Objective-C optional-requirement runtime, so those
/// members are real protocol requirements with defaults. Calls through an
/// existential therefore dispatch to a conformer's override instead of the
/// extension default.
///
/// Apple's Swift overlay marks `didReceive(_: UNNotification)` `@MainActor`.
/// This Linux protocol is not actor-isolated: the sealed host runtime is a
/// synchronous executable, and there is no notification UI thread.
///
/// Linux has no notification extension host, SpringBoard, or containing-app
/// launch path. Defaults are fail-closed: they do not dismiss a banner, play
/// media, or forward an action.
public protocol UNNotificationContentExtension: NSObjectProtocol {
    func didReceive(_ notification: UNNotification)

    func didReceive(
        _ response: UNNotificationResponse,
        completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void
    )

    func didReceive(_ response: UNNotificationResponse) async -> UNNotificationContentExtensionResponseOption

    func mediaPlay()
    func mediaPause()

    var mediaPlayPauseButtonType: UNNotificationContentExtensionMediaPlayPauseButtonType { get }
    var mediaPlayPauseButtonFrame: CGRect { get }
    var mediaPlayPauseButtonTintColor: UIColor { get }
}

extension UNNotificationContentExtension {
    public func didReceive(
        _ response: UNNotificationResponse,
        completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void
    ) {
        _ = response
        completion(.doNotDismiss)
    }

    public func didReceive(
        _ response: UNNotificationResponse
    ) async -> UNNotificationContentExtensionResponseOption {
        await withCheckedContinuation { continuation in
            self.didReceive(response) { option in
                continuation.resume(returning: option)
            }
        }
    }

    public func mediaPlay() {}
    public func mediaPause() {}

    public var mediaPlayPauseButtonType: UNNotificationContentExtensionMediaPlayPauseButtonType {
        .none
    }

    public var mediaPlayPauseButtonFrame: CGRect {
        .zero
    }

    public var mediaPlayPauseButtonTintColor: UIColor {
        UserNotificationsUIHostMediaPlayPauseButtonTintColor.shared
    }
}

/// Stable default tint used when a conformer does not override
/// `mediaPlayPauseButtonTintColor`. Not an Apple system color.
enum UserNotificationsUIHostMediaPlayPauseButtonTintColor {
    static let shared = UIColor()
}

#if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
extension NSExtensionContext {
    /// Asks the notification extension host to dismiss the custom UI.
    /// Unimplemented on Linux: `Foundation.NSExtensionContext` is absent.
    public func dismissNotificationContentExtension() {}

    /// Tells the host that extension-owned media playback paused.
    public func mediaPlayingPaused() {}

    /// Tells the host that extension-owned media playback started.
    public func mediaPlayingStarted() {}

    /// Asks the host to perform the notification's default action.
    public func performNotificationDefaultAction() {}

    /// Replacement notification actions presented by the host, when a host exists.
    public var notificationActions: [UNNotificationAction] {
        get { [] }
        set { _ = newValue }
    }
}
#endif
