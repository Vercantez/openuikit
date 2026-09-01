@_exported import Foundation

#if canImport(UIKit)
@_exported import UIKit
#endif

#if canImport(UserNotifications)
@_exported import UserNotifications
#endif

// MARK: - Linux dependency stand-ins
//
// The isolated host gate compiles only this module. UIKit and UserNotifications
// are declared dependencies but are not on the Linux toolchain module path.
// These stand-ins exist solely so the UserNotificationsUI surface typechecks
// until those modules are linked. They are not Apple notification objects and
// they are not a UIKit color catalog.

#if !canImport(UIKit)
public final class UIColor: NSObject, NSCopying {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UIColor else { return false }
        return red == other.red
            && green == other.green
            && blue == other.blue
            && alpha == other.alpha
    }
}
#endif

#if !canImport(UserNotifications)
public final class UNNotification: NSObject {
    public let date: Date

    public init(date: Date = Date()) {
        self.date = date
        super.init()
    }
}

public final class UNNotificationResponse: NSObject {
    public let notification: UNNotification
    public let actionIdentifier: String

    public init(notification: UNNotification, actionIdentifier: String) {
        self.notification = notification
        self.actionIdentifier = actionIdentifier
        super.init()
    }
}

public final class UNNotificationAction: NSObject {
    public let identifier: String
    public let title: String

    public init(identifier: String, title: String) {
        self.identifier = identifier
        self.title = title
        super.init()
    }
}
#endif

// MARK: - Host availability

/// Linux has no Apple notification-content-extension process, no SpringBoard
/// banner host, and no entitlement to present `UNNotificationContentExtension`
/// UI. Methods that would talk to that host record the request and do nothing
/// else. They never report a successful system dismiss, default action, or
/// media session.
public enum UserNotificationsUIHost: Sendable {
    public static let contentExtensionHostAvailable = false
    public static let appleNotificationServiceAvailable = false
    public static let mediaPlaybackHostAvailable = false
}

public enum UserNotificationsUIHostEvent: Equatable, Sendable {
    case notificationActionsUpdated(count: Int)
    case dismissRequested
    case defaultActionRequested
    case mediaPlayingStarted
    case mediaPlayingPaused
}

// MARK: - Public enumerations
//
// Raw values follow Apple's `NS_ENUM(NSUInteger, ...)` order in
// `UNNotificationContentExtension.h` (iOS 10 / Xcode 26.1 seed): first
// enumerator is 0.

public enum UNNotificationContentExtensionMediaPlayPauseButtonType: UInt, Equatable,
    Hashable, Sendable
{
    case none = 0
    case `default` = 1
    case overlay = 2
}

public enum UNNotificationContentExtensionResponseOption: UInt, Equatable, Hashable,
    Sendable
{
    case doNotDismiss = 0
    case dismiss = 1
    case dismissAndForwardAction = 2
}

// MARK: - Content extension protocol
//
// Apple's optional Objective-C requirements cannot be expressed as `@objc
// optional` on this Linux toolchain (Objective-C interoperability is
// disabled). Protocol extension defaults provide the same source surface:
// conformers may override any of the members below.

public protocol UNNotificationContentExtension: NSObjectProtocol {
    @MainActor func didReceive(_ notification: UNNotification)
}

extension UNNotificationContentExtension {
    /// Fail-closed default: keep the notification visible. Linux has no host
    /// that can honestly dismiss or forward a system notification action.
    public func didReceive(
        _ response: UNNotificationResponse
    ) async -> UNNotificationContentExtensionResponseOption {
        _ = response
        return .doNotDismiss
    }

    /// Completion-handler overlay of the same ObjC requirement recorded as a
    /// conflicting duplicate of the async spelling. Independent of the async
    /// default so this port does not invent Apple's bridging.
    public func didReceive(
        _ response: UNNotificationResponse,
        completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) ->
            Void
    ) {
        _ = response
        completion(.doNotDismiss)
    }

    public func mediaPlay() {}

    public func mediaPause() {}

    public var mediaPlayPauseButtonType: UNNotificationContentExtensionMediaPlayPauseButtonType {
        .none
    }

    public var mediaPlayPauseButtonFrame: CGRect { .zero }

    /// Portable default tint. Apple's unimplemented color is not in the seed.
    public var mediaPlayPauseButtonTintColor: UIColor {
        UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
}

// MARK: - NSExtensionContext

/// Linux counterpart of Foundation's `NSExtensionContext` plus the
/// UserNotificationsUI category methods. Foundation on this toolchain does not
/// ship `NSExtensionContext`. The type stores local extension state; it does
/// not complete an Apple extension request or drive a notification UI.
open class NSExtensionContext: NSObject {
    private var storedNotificationActions: [UNNotificationAction] = []

    public private(set) var notificationContentExtensionDidRequestDismiss = false
    public private(set) var notificationContentExtensionDidRequestDefaultAction = false
    public private(set) var notificationContentExtensionMediaIsPlaying = false
    public private(set) var hostEvents: [UserNotificationsUIHostEvent] = []

    public override init() {
        super.init()
    }

    open var notificationActions: [UNNotificationAction] {
        get { storedNotificationActions }
        set {
            storedNotificationActions = Array(newValue)
            hostEvents.append(
                .notificationActionsUpdated(count: storedNotificationActions.count)
            )
        }
    }

    /// Records a dismiss request. Does not remove a system banner or complete
    /// an extension request: `contentExtensionHostAvailable` is false.
    open func dismissNotificationContentExtension() {
        notificationContentExtensionDidRequestDismiss = true
        hostEvents.append(.dismissRequested)
    }

    /// Records a default-action request. Does not launch the containing app
    /// or invoke `UNNotificationDefaultActionIdentifier`.
    open func performNotificationDefaultAction() {
        notificationContentExtensionDidRequestDefaultAction = true
        hostEvents.append(.defaultActionRequested)
    }

    /// Records that the extension began media playback. Linux has no
    /// notification media session; the flag is local only.
    open func mediaPlayingStarted() {
        notificationContentExtensionMediaIsPlaying = true
        hostEvents.append(.mediaPlayingStarted)
    }

    /// Records that the extension paused media playback. Linux has no
    /// notification media session; the flag is local only.
    open func mediaPlayingPaused() {
        notificationContentExtensionMediaIsPlaying = false
        hostEvents.append(.mediaPlayingPaused)
    }
}
