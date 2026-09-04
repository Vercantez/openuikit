@_exported import Foundation

/// The protocol you implement to describe the content of a Live Activity.
public protocol ActivityAttributes: Decodable, Encodable {
    associatedtype ContentState: Decodable, Encodable, Hashable
}

/// The state of a Live Activity in its life cycle.
public enum ActivityState: Codable, Hashable, Sendable {
    case pending
    case active
    case ended
    case dismissed
    case stale
}

/// Presentation style for a Live Activity request.
public enum ActivityStyle: Hashable, Sendable {
    case standard
    case transient
}

/// Content and configuration of a Live Activity.
public struct ActivityContent<State: Decodable & Encodable & Hashable>:
    CustomStringConvertible
{
    public let state: State
    public let staleDate: Date?
    public let relevanceScore: Double

    public init(
        state: State,
        staleDate: Date?,
        relevanceScore: Double = 0.0
    ) {
        self.state = state
        self.staleDate = staleDate
        self.relevanceScore = relevanceScore
    }

    public var description: String {
        "ActivityContent(state: \(state), staleDate: \(String(describing: staleDate)), relevanceScore: \(relevanceScore))"
    }
}

extension ActivityContent: Sendable where State: Sendable {}

/// When the system should remove a Live Activity that ended.
///
/// Linux never presents Live Activity UI, so these values are recorded only as
/// request/end arguments. They do not dismiss a system surface.
public struct ActivityUIDismissalPolicy: Equatable, Sendable {
    private enum Kind: Equatable, Sendable {
        case `default`
        case immediate
        case after(Date)
    }

    private let kind: Kind

    private init(kind: Kind) {
        self.kind = kind
    }

    public static let `default` = ActivityUIDismissalPolicy(kind: .default)
    public static let immediate = ActivityUIDismissalPolicy(kind: .immediate)

    public static func after(_ date: Date) -> ActivityUIDismissalPolicy {
        ActivityUIDismissalPolicy(kind: .after(date))
    }
}

/// Push configuration for ActivityKit content updates.
///
/// Linux has no ActivityKit push or broadcast-channel service. Tokens and
/// channels are recorded as values only; they never register with APNs.
public struct PushType: Equatable {
    private enum Kind: Equatable {
        case token
        case channel(String)
    }

    private let kind: Kind

    private init(kind: Kind) {
        self.kind = kind
    }

    public static var token: PushType { PushType(kind: .token) }

    public static func channel(_ name: String) -> PushType {
        PushType(kind: .channel(name))
    }
}

#if OPENUIKIT_GUEST
/// Alert shown when a Live Activity updates.
///
/// Title and body are Foundation.`LocalizedStringResource` from the guest
/// Foundation module. This type is compiled only with `-D OPENUIKIT_GUEST`
/// against that module; isolated toolchain Foundation does not publish the
/// type, and ActivityKit does not ship a same-named fallback. Linux never
/// presents the alert.
public struct AlertConfiguration: Equatable, Sendable {
    public struct AlertSound: Equatable, Sendable {
        private enum Kind: Equatable, Sendable {
            case `default`
            case named(String)
        }

        private let kind: Kind

        private init(kind: Kind) {
            self.kind = kind
        }

        public static var `default`: AlertSound {
            AlertSound(kind: .default)
        }

        public static func named(_ name: String) -> AlertSound {
            AlertSound(kind: .named(name))
        }
    }

    public var title: Foundation.LocalizedStringResource
    public var body: Foundation.LocalizedStringResource
    public var sound: AlertSound

    public init(
        title: Foundation.LocalizedStringResource,
        body: Foundation.LocalizedStringResource,
        sound: AlertSound
    ) {
        self.title = title
        self.body = body
        self.sound = sound
    }
}
#endif

/// Why a request to start a Live Activity failed.
///
/// `errorDomain` and `errorCode` are Linux-local CustomNSError witnesses, not
/// observed Apple NSError values. See `oracle-questions.tsv`.
public enum ActivityAuthorizationError: Error, Hashable, Sendable,
    LocalizedError, CustomNSError
{
    case attributesTooLarge
    case unsupported
    case denied
    case globalMaximumExceeded
    case targetMaximumExceeded
    case unsupportedTarget
    case visibility
    case persistenceFailure
    case missingProcessIdentifier
    case unentitled
    case malformedActivityIdentifier
    case reconnectNotPermitted

    public static var errorDomain: String {
        "ActivityKit.ActivityAuthorizationError"
    }

    public var errorCode: Int {
        switch self {
        case .attributesTooLarge: return 0
        case .unsupported: return 1
        case .denied: return 2
        case .globalMaximumExceeded: return 3
        case .targetMaximumExceeded: return 4
        case .unsupportedTarget: return 5
        case .visibility: return 6
        case .persistenceFailure: return 7
        case .missingProcessIdentifier: return 8
        case .unentitled: return 9
        case .malformedActivityIdentifier: return 10
        case .reconnectNotPermitted: return 11
        }
    }

    public var failureReason: String? {
        switch self {
        case .attributesTooLarge:
            return "The provided Live Activity attributes exceeded the maximum size of 4KB."
        case .unsupported:
            return "The device doesn't support Live Activities."
        case .denied:
            return "A person deactivated Live Activities in Settings."
        case .globalMaximumExceeded:
            return "The device reached the maximum number of ongoing Live Activities."
        case .targetMaximumExceeded:
            return "The app has already started the maximum number of concurrent Live Activities."
        case .unsupportedTarget:
            return "The app doesn't have the required entitlement to start a Live Activities."
        case .visibility:
            return "The app tried to start the Live Activity while it was in the background."
        case .persistenceFailure:
            return "The system couldn't persist the Live Activity."
        case .missingProcessIdentifier:
            return "The process that tried to start the Live Activity is missing a process identifier."
        case .unentitled:
            return "The app doesn't have the required entitlement to start a Live Activity."
        case .malformedActivityIdentifier:
            return "The provided activity identifier is malformed."
        case .reconnectNotPermitted:
            return "The process that tried to recreate the Live Activity is not the process that originally created the Live Activity."
        }
    }

    public var recoverySuggestion: String? { nil }

    public var errorDescription: String? { failureReason }
}

/// Authorization state for Live Activities and frequent push updates.
///
/// Linux has no Live Activity daemon, entitlement check, or Settings toggle.
/// Both flags are therefore `false`, and the enablement sequences emit that
/// current value once, then finish. They never later emit `true`.
public final class ActivityAuthorizationInfo {
    public struct ActivityEnablementUpdates: AsyncSequence {
        public typealias Element = Bool
        public typealias AsyncIterator = Iterator

        let current: Bool

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = Bool
            var remaining: Bool?

            public mutating func next() async -> Bool? {
                guard let value = remaining else { return nil }
                remaining = nil
                return value
            }
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator(remaining: current)
        }
    }

    public struct FrequentPushEnablementUpdates: AsyncSequence {
        public typealias Element = Bool
        public typealias AsyncIterator = Iterator

        let current: Bool

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = Bool
            var remaining: Bool?

            public mutating func next() async -> Bool? {
                guard let value = remaining else { return nil }
                remaining = nil
                return value
            }
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator(remaining: current)
        }
    }

    public final var areActivitiesEnabled: Bool { false }
    public final var frequentPushesEnabled: Bool { false }
    public final let activityEnablementUpdates: ActivityEnablementUpdates
    public final let frequentPushEnablementUpdates: FrequentPushEnablementUpdates

    public init() {
        activityEnablementUpdates = ActivityEnablementUpdates(current: false)
        frequentPushEnablementUpdates = FrequentPushEnablementUpdates(current: false)
    }
}

/// The object you use to start, update, and end a Live Activity.
///
/// Linux has no Live Activity UI, WidgetKit extension host, or ActivityKit
/// push service. `request` always throws ``ActivityAuthorizationError/unsupported``.
/// `activities` is empty, push tokens are `nil`, and static update sequences
/// complete without values. Instance `update`/`end` APIs are declared so the
/// class matches the public surface; they are unreachable until a future host
/// can construct an activity without claiming Apple presentation.
public class Activity<Attributes: ActivityAttributes>: Identifiable {
    public typealias ID = String
    public typealias ContentState = Attributes.ContentState

    public struct ActivityUpdates: AsyncSequence {
        public typealias Element = Activity<Attributes>
        public typealias AsyncIterator = Iterator

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = Activity<Attributes>

            public func next() async -> Activity<Attributes>? { nil }
        }

        public func makeAsyncIterator() -> Iterator { Iterator() }
    }

    public struct ActivityStateUpdates: AsyncSequence {
        public typealias Element = ActivityState
        public typealias AsyncIterator = Iterator

        public struct Iterator: AsyncIteratorProtocol, Sendable {
            public typealias Element = ActivityState

            public func next() async -> ActivityState? { nil }
        }

        public func makeAsyncIterator() -> Iterator { Iterator() }
    }

    public struct ContentUpdates: AsyncSequence {
        public typealias Element = ActivityContent<Activity<Attributes>.ContentState>
        public typealias AsyncIterator = Iterator

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = ActivityContent<Activity<Attributes>.ContentState>

            public func next() async -> ActivityContent<Activity<Attributes>.ContentState>? {
                nil
            }
        }

        public func makeAsyncIterator() -> Iterator { Iterator() }
    }

    public struct ContentStateUpdates: AsyncSequence {
        public typealias Element = Activity<Attributes>.ContentState
        public typealias AsyncIterator = Iterator

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = Activity<Attributes>.ContentState

            public func next() async -> Activity<Attributes>.ContentState? { nil }
        }

        public func makeAsyncIterator() -> Iterator { Iterator() }
    }

    public struct PushTokenUpdates: AsyncSequence {
        public typealias Element = Data
        public typealias AsyncIterator = Iterator

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = Data

            public func next() async -> Data? { nil }
        }

        public func makeAsyncIterator() -> Iterator { Iterator() }
    }

    public let id: String
    public let attributes: Attributes

    private var storedContent: ActivityContent<ContentState>
    private var storedActivityState: ActivityState

    public var content: ActivityContent<ContentState> { storedContent }
    public var contentState: ContentState { storedContent.state }
    public var activityState: ActivityState { storedActivityState }
    public var pushToken: Data? { nil }

    public var contentUpdates: ContentUpdates { ContentUpdates() }
    public var contentStateUpdates: ContentStateUpdates { ContentStateUpdates() }
    public var activityStateUpdates: ActivityStateUpdates { ActivityStateUpdates() }
    public var pushTokenUpdates: PushTokenUpdates { PushTokenUpdates() }

    public static var activities: [Activity<Attributes>] { [] }
    public static var activityUpdates: ActivityUpdates { ActivityUpdates() }
    public static var pushToStartToken: Data? { nil }
    public static var pushToStartTokenUpdates: PushTokenUpdates { PushTokenUpdates() }

    private init(
        id: String,
        attributes: Attributes,
        content: ActivityContent<ContentState>,
        activityState: ActivityState
    ) {
        self.id = id
        self.attributes = attributes
        self.storedContent = content
        self.storedActivityState = activityState
    }

    private static func unsupportedRequest() throws -> Activity<Attributes> {
        throw ActivityAuthorizationError.unsupported
    }

    public static func request(
        attributes: Attributes,
        contentState: Activity<Attributes>.ContentState,
        pushType: PushType? = nil
    ) throws -> Activity<Attributes> {
        _ = (attributes, contentState, pushType)
        return try unsupportedRequest()
    }

    public static func request(
        attributes: Attributes,
        content: ActivityContent<Activity<Attributes>.ContentState>,
        pushType: PushType? = nil
    ) throws -> Activity<Attributes> {
        _ = (attributes, content, pushType)
        return try unsupportedRequest()
    }

    public static func request(
        attributes: Attributes,
        content: ActivityContent<Activity<Attributes>.ContentState>,
        pushType: PushType? = nil,
        style: ActivityStyle
    ) throws -> Activity<Attributes> {
        _ = (attributes, content, pushType, style)
        return try unsupportedRequest()
    }

#if OPENUIKIT_GUEST
    public static func request(
        attributes: Attributes,
        content: ActivityContent<Activity<Attributes>.ContentState>,
        pushType: PushType? = nil,
        style: ActivityStyle,
        alertConfiguration: AlertConfiguration,
        start: Date
    ) throws -> Activity<Attributes> {
        _ = (attributes, content, pushType, style, alertConfiguration, start)
        return try unsupportedRequest()
    }

    public static func request(
        attributes: Attributes,
        content: ActivityContent<Activity<Attributes>.ContentState>,
        pushType: PushType? = nil,
        style: ActivityStyle,
        alertConfiguration: AlertConfiguration,
        startDate: Date
    ) throws -> Activity<Attributes> {
        _ = (attributes, content, pushType, style, alertConfiguration, startDate)
        return try unsupportedRequest()
    }
#endif

    private func applyContentUpdate(
        _ content: ActivityContent<ContentState>
    ) {
        storedContent = content
        if storedActivityState == .pending {
            storedActivityState = .active
        }
    }

    public func update(using contentState: Activity<Attributes>.ContentState) async {
        applyContentUpdate(
            ActivityContent(state: contentState, staleDate: storedContent.staleDate)
        )
    }

    public func update(
        _ content: ActivityContent<Activity<Attributes>.ContentState>
    ) async {
        applyContentUpdate(content)
    }

#if OPENUIKIT_GUEST
    public func update(
        using contentState: Activity<Attributes>.ContentState,
        alertConfiguration: AlertConfiguration? = nil
    ) async {
        _ = alertConfiguration
        await update(using: contentState)
    }

    public func update(
        _ content: ActivityContent<Activity<Attributes>.ContentState>,
        alertConfiguration: AlertConfiguration? = nil
    ) async {
        await update(content, alertConfiguration: alertConfiguration, timestamp: Date())
    }

    public func update(
        _ content: ActivityContent<Activity<Attributes>.ContentState>,
        alertConfiguration: AlertConfiguration? = nil,
        timestamp: Date
    ) async {
        _ = (alertConfiguration, timestamp)
        applyContentUpdate(content)
    }
#endif

    public func end(
        using contentState: Activity<Attributes>.ContentState? = nil,
        dismissalPolicy: ActivityUIDismissalPolicy = .default
    ) async {
        let content: ActivityContent<ContentState>?
        if let contentState {
            content = ActivityContent(
                state: contentState,
                staleDate: storedContent.staleDate,
                relevanceScore: storedContent.relevanceScore
            )
        } else {
            content = nil
        }
        await end(content, dismissalPolicy: dismissalPolicy)
    }

    public func end(
        _ content: ActivityContent<Activity<Attributes>.ContentState>?,
        dismissalPolicy: ActivityUIDismissalPolicy = .default
    ) async {
        await end(content, dismissalPolicy: dismissalPolicy, timestamp: Date())
    }

    public func end(
        _ content: ActivityContent<Activity<Attributes>.ContentState>?,
        dismissalPolicy: ActivityUIDismissalPolicy = .default,
        timestamp: Date
    ) async {
        _ = (dismissalPolicy, timestamp)
        if let content {
            storedContent = content
        }
        storedActivityState = .ended
    }
}
