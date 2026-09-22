// Fail-closed stand-in for BrazeKit from braze-swift-sdk 12.1.0 (c630122e).
// Surface = what ios-oss touches (all in Kickstarter-iOS/AppDelegate.swift):
//   Braze.prepareForDelayedInitialization(pushAutomation:)          :55
//   Braze.Configuration.Push.Automation (Bool literal; automaticSetup,
//     requestAuthorizationAtLaunch, registerDeviceToken)           :560-566
//   Braze.Configuration .triggerMinimumTimeInterval, .push.automation,
//     .logger.level = .debug (inside SegmentBrazeUI's configuration hook)
//   braze.changeUser(userId:), braze.delegate, braze.inAppMessagePresenter,
//     braze.notifications.register(deviceToken:),
//     braze.notifications.subscribeToUpdates(payloadTypes:[.opened]) -> Cancellable,
//     payload.badge                                                 :78,164,533-555
//   BrazeDelegate.braze(_:shouldOpenURL:) with Braze.URLContext.url  :648
//   BrazeKit.Braze.Cancellable                                      :31
//
// Behaviour: no Braze instance is ever created. `Braze` has no public
// initializer; the only producer in the app is SegmentBrazeUI's destination,
// which (fail-closed) never calls its ready callback. So every
// `self.braze?...` in AppDelegate is a nil-optional no-op. Delayed
// initialization records nothing. The instance members below exist only so
// the app's call sites type-check; they send nothing and deliver no
// notification payload.
import Foundation

public protocol BrazeDelegate: AnyObject {
    func braze(_ braze: Braze, shouldOpenURL context: Braze.URLContext) -> Bool
}

public protocol BrazeInAppMessagePresenter: AnyObject {}

public final class Braze {
    // MARK: Configuration

    public final class Configuration {
        public final class Push {
            public final class Automation: ExpressibleByBooleanLiteral {
                public var automaticSetup: Bool
                public var requestAuthorizationAtLaunch: Bool
                public var registerDeviceToken: Bool
                public var handleBackgroundNotification: Bool
                public var handleNotificationResponse: Bool
                public var willPresentNotification: Bool

                public required init(booleanLiteral value: Bool) {
                    automaticSetup = value
                    requestAuthorizationAtLaunch = value
                    registerDeviceToken = value
                    handleBackgroundNotification = value
                    handleNotificationResponse = value
                    willPresentNotification = value
                }
            }

            public var automation: Automation = false
            init() {}
        }

        public final class Logger {
            public enum Level: Int {
                case debug
                case info
                case error
                case disabled
            }

            public var level: Level = .error
            init() {}
        }

        public let apiKey: String
        public let endpoint: String
        public var triggerMinimumTimeInterval: TimeInterval = 30
        public let push = Push()
        public let logger = Logger()

        public init(apiKey: String, endpoint: String) {
            self.apiKey = apiKey
            self.endpoint = endpoint
        }
    }

    // MARK: Delayed initialization

    /// Records nothing: no Braze instance will ever be initialized.
    public static func prepareForDelayedInitialization(
        pushAutomation: Configuration.Push.Automation? = nil
    ) {}

    // MARK: Cancellable / URL context

    public final class Cancellable {
        init() {}
        public func cancel() {}
    }

    public struct URLContext {
        public let url: URL
        init(url: URL) { self.url = url }
    }

    // MARK: Notifications

    public final class Notifications {
        public struct Payload {
            public struct PayloadType: OptionSet, Hashable {
                public let rawValue: Int
                public init(rawValue: Int) { self.rawValue = rawValue }
                public static let received = PayloadType(rawValue: 1 << 0)
                public static let opened = PayloadType(rawValue: 1 << 1)
            }

            public let badge: Int?
        }

        init() {}

        /// Dropped: there is no Braze backend to register with.
        public func register(deviceToken: Data) {}

        /// The update closure is never called.
        public func subscribeToUpdates(
            payloadTypes: Payload.PayloadType = [.opened, .received],
            _ update: @escaping (Payload) -> Void
        ) -> Cancellable {
            Cancellable()
        }
    }

    // MARK: Instance (never constructed by the shim)

    public let configuration: Configuration
    public weak var delegate: BrazeDelegate?
    public var inAppMessagePresenter: BrazeInAppMessagePresenter?
    public let notifications = Notifications()

    init(configuration: Configuration) { self.configuration = configuration }

    /// Dropped.
    public func changeUser(userId: String) {}
}
