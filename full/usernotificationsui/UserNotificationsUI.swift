#if canImport(UIKit)
import UIKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(UIKit) && canImport(UserNotifications)
import Foundation
#endif

// MARK: - Host availability
//
// Linux has no Apple notification-content-extension process, no SpringBoard
// banner host, and no entitlement to present `UNNotificationContentExtension`
// UI. Methods that would talk to that host record the request and do nothing
// else. They never report a successful system dismiss, default action, or
// media session.

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

#if canImport(UIKit) && canImport(UserNotifications)
// MARK: - Content extension protocol
//
// Apple's optional Objective-C requirements cannot be `@objc optional` on this
// Linux toolchain. They are still protocol requirements so existential
// dispatch uses the conformer's witness. Defaults live in the extension.

public protocol UNNotificationContentExtension: NSObjectProtocol {
    @MainActor func didReceive(_ notification: UNNotification)

    func didReceive(
        _ response: UNNotificationResponse
    ) async -> UNNotificationContentExtensionResponseOption

    func didReceive(
        _ response: UNNotificationResponse,
        completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) ->
            Void
    )

    func mediaPlay()

    func mediaPause()

    var mediaPlayPauseButtonType: UNNotificationContentExtensionMediaPlayPauseButtonType { get }

    var mediaPlayPauseButtonFrame: CGRect { get }

    var mediaPlayPauseButtonTintColor: UIColor { get }
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

// MARK: - Foundation.NSExtensionContext
//
// UserNotificationsUI does not own `NSExtensionContext`. Production APIs
// extend the staged Foundation identity so NotificationCenter and this module
// share one type. Linux has no extension host: the methods only record local
// sidecar state.

private final class _UNNotificationContentExtensionHostState {
    var actions: [UNNotificationAction] = []
    var didRequestDismiss = false
    var didRequestDefaultAction = false
    var mediaIsPlaying = false
    var hostEvents: [UserNotificationsUIHostEvent] = []
}

private enum _UNNotificationContentExtensionHostStorage {
    private static let lock = NSLock()
    private static var states: [ObjectIdentifier: _UNNotificationContentExtensionHostState] = [:]

    static func state(for context: NSExtensionContext) -> _UNNotificationContentExtensionHostState {
        lock.lock()
        defer { lock.unlock() }
        let key = ObjectIdentifier(context)
        if let existing = states[key] {
            return existing
        }
        let created = _UNNotificationContentExtensionHostState()
        states[key] = created
        return created
    }
}

extension NSExtensionContext {
    public var notificationActions: [UNNotificationAction] {
        get { _UNNotificationContentExtensionHostStorage.state(for: self).actions }
        set {
            let state = _UNNotificationContentExtensionHostStorage.state(for: self)
            state.actions = Array(newValue)
            state.hostEvents.append(
                .notificationActionsUpdated(count: state.actions.count)
            )
        }
    }

    /// Records a dismiss request. Does not remove a system banner or complete
    /// an extension request: `contentExtensionHostAvailable` is false.
    public func dismissNotificationContentExtension() {
        let state = _UNNotificationContentExtensionHostStorage.state(for: self)
        state.didRequestDismiss = true
        state.hostEvents.append(.dismissRequested)
    }

    /// Records a default-action request. Does not launch the containing app
    /// or invoke `UNNotificationDefaultActionIdentifier`.
    public func performNotificationDefaultAction() {
        let state = _UNNotificationContentExtensionHostStorage.state(for: self)
        state.didRequestDefaultAction = true
        state.hostEvents.append(.defaultActionRequested)
    }

    /// Records that the extension began media playback. Linux has no
    /// notification media session; the flag is local only.
    public func mediaPlayingStarted() {
        let state = _UNNotificationContentExtensionHostStorage.state(for: self)
        state.mediaIsPlaying = true
        state.hostEvents.append(.mediaPlayingStarted)
    }

    /// Records that the extension paused media playback. Linux has no
    /// notification media session; the flag is local only.
    public func mediaPlayingPaused() {
        let state = _UNNotificationContentExtensionHostStorage.state(for: self)
        state.mediaIsPlaying = false
        state.hostEvents.append(.mediaPlayingPaused)
    }

    @_spi(OpenUIKitHost)
    public var notificationContentExtensionDidRequestDismiss: Bool {
        _UNNotificationContentExtensionHostStorage.state(for: self).didRequestDismiss
    }

    @_spi(OpenUIKitHost)
    public var notificationContentExtensionDidRequestDefaultAction: Bool {
        _UNNotificationContentExtensionHostStorage.state(for: self).didRequestDefaultAction
    }

    @_spi(OpenUIKitHost)
    public var notificationContentExtensionMediaIsPlaying: Bool {
        _UNNotificationContentExtensionHostStorage.state(for: self).mediaIsPlaying
    }

    @_spi(OpenUIKitHost)
    public var notificationContentExtensionHostEvents: [UserNotificationsUIHostEvent] {
        _UNNotificationContentExtensionHostStorage.state(for: self).hostEvents
    }
}
#endif
