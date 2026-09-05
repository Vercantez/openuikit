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
/// Linux never presents Live Activity UI. These values still drive
/// process-local `.ended` → `.dismissed` transitions against the host clock:
/// `.default` dismisses four hours after end, `.immediate` dismisses at end,
/// and `.after(date)` dismisses at `min(date, end + 4h)`.
public struct ActivityUIDismissalPolicy: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case `default`
        case immediate
        case after(Date)
    }

    let kind: Kind

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
/// Linux has no ActivityKit push or broadcast-channel service. Tokens stay
/// `nil` unless a host test hook assigns one. Channel names are recorded only.
public struct PushType: Equatable {
    enum Kind: Equatable {
        case token
        case channel(String)
    }

    let kind: Kind

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
/// `areActivitiesEnabled` and `frequentPushesEnabled` read a process-local
/// stored setting. Linux has no Settings app or entitlement daemon; host tests
/// write the flags. Enablement sequences emit the current value, then later
/// changes, and do not finish on their own.
public final class ActivityAuthorizationInfo {
    public struct ActivityEnablementUpdates: AsyncSequence {
        public typealias Element = Bool
        public typealias AsyncIterator = Iterator

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = Bool
            private let pump: OpenUIKitAsyncPump<Bool>

            public init() {
                pump = OpenUIKitAsyncPump(
                    stream: OpenUIKitActivityKitHost.activityEnablementFanout.makeStream()
                )
            }

            public mutating func next() async -> Bool? {
                await pump.next()
            }
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }
    }

    public struct FrequentPushEnablementUpdates: AsyncSequence {
        public typealias Element = Bool
        public typealias AsyncIterator = Iterator

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = Bool
            private let pump: OpenUIKitAsyncPump<Bool>

            public init() {
                pump = OpenUIKitAsyncPump(
                    stream: OpenUIKitActivityKitHost.frequentPushEnablementFanout.makeStream()
                )
            }

            public mutating func next() async -> Bool? {
                await pump.next()
            }
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }
    }

    public final var areActivitiesEnabled: Bool {
        OpenUIKitActivityKitHost.lock.lock()
        let value = OpenUIKitActivityKitHost.areActivitiesEnabled
        OpenUIKitActivityKitHost.lock.unlock()
        return value
    }

    public final var frequentPushesEnabled: Bool {
        OpenUIKitActivityKitHost.lock.lock()
        let value = OpenUIKitActivityKitHost.frequentPushesEnabled
        OpenUIKitActivityKitHost.lock.unlock()
        return value
    }

    public final let activityEnablementUpdates: ActivityEnablementUpdates
    public final let frequentPushEnablementUpdates: FrequentPushEnablementUpdates

    public init() {
        activityEnablementUpdates = ActivityEnablementUpdates()
        frequentPushEnablementUpdates = FrequentPushEnablementUpdates()
    }
}

/// The object you use to start, update, and end a Live Activity.
///
/// Linux provides a process-local registry: `request` can succeed, up to eight
/// non-dismissed activities may exist, and `update`/`end` transition
/// `activityState` against an injectable clock. There is no Live Activity UI,
/// WidgetKit extension host, or APNs. `pushToken` stays `nil` unless a host
/// test hook assigns bytes.
public class Activity<Attributes: ActivityAttributes>: Identifiable, @unchecked Sendable {
    public typealias ID = String
    public typealias ContentState = Attributes.ContentState

    public struct ActivityUpdates: AsyncSequence {
        public typealias Element = Activity<Attributes>
        public typealias AsyncIterator = Iterator

        let makeStream: () -> AsyncStream<Activity<Attributes>>

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = Activity<Attributes>
            private let pump: OpenUIKitAsyncPump<Activity<Attributes>>

            init(stream: AsyncStream<Activity<Attributes>>) {
                pump = OpenUIKitAsyncPump(stream: stream)
            }

            public func next() async -> Activity<Attributes>? {
                await pump.next()
            }
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator(stream: makeStream())
        }
    }

    public struct ActivityStateUpdates: AsyncSequence {
        public typealias Element = ActivityState
        public typealias AsyncIterator = Iterator

        let makeStream: () -> AsyncStream<ActivityState>

        public struct Iterator: AsyncIteratorProtocol, Sendable {
            public typealias Element = ActivityState
            private let pump: OpenUIKitAsyncPump<ActivityState>

            init(stream: AsyncStream<ActivityState>) {
                pump = OpenUIKitAsyncPump(stream: stream)
            }

            public func next() async -> ActivityState? {
                await pump.next()
            }
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator(stream: makeStream())
        }
    }

    public struct ContentUpdates: AsyncSequence {
        public typealias Element = ActivityContent<Activity<Attributes>.ContentState>
        public typealias AsyncIterator = Iterator

        let makeStream: () -> AsyncStream<ActivityContent<Activity<Attributes>.ContentState>>

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = ActivityContent<Activity<Attributes>.ContentState>
            private let pump: OpenUIKitAsyncPump<
                ActivityContent<Activity<Attributes>.ContentState>
            >

            init(
                stream: AsyncStream<ActivityContent<Activity<Attributes>.ContentState>>
            ) {
                pump = OpenUIKitAsyncPump(stream: stream)
            }

            public func next() async -> ActivityContent<Activity<Attributes>.ContentState>? {
                await pump.next()
            }
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator(stream: makeStream())
        }
    }

    public struct ContentStateUpdates: AsyncSequence {
        public typealias Element = Activity<Attributes>.ContentState
        public typealias AsyncIterator = Iterator

        let makeStream: () -> AsyncStream<Activity<Attributes>.ContentState>

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = Activity<Attributes>.ContentState
            private let pump: OpenUIKitAsyncPump<Activity<Attributes>.ContentState>

            init(stream: AsyncStream<Activity<Attributes>.ContentState>) {
                pump = OpenUIKitAsyncPump(stream: stream)
            }

            public func next() async -> Activity<Attributes>.ContentState? {
                await pump.next()
            }
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator(stream: makeStream())
        }
    }

    public struct PushTokenUpdates: AsyncSequence {
        public typealias Element = Data
        public typealias AsyncIterator = Iterator

        let makeStream: () -> AsyncStream<Data>

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = Data
            private let pump: OpenUIKitAsyncPump<Data>

            init(stream: AsyncStream<Data>) {
                pump = OpenUIKitAsyncPump(stream: stream)
            }

            public func next() async -> Data? {
                await pump.next()
            }
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator(stream: makeStream())
        }
    }

    private static var typeStore: ActivityTypeStore<Attributes> {
        ActivityStoreRegistry.store(for: Attributes.self)
    }

    public let id: String
    public let attributes: Attributes

    private let stateLock = NSLock()
    private var storedContent: ActivityContent<ContentState>
    private var storedActivityState: ActivityState
    private var storedPushToken: Data?
    private var startedAt: Date
    private var endedAt: Date?
    private var dismissAt: Date?
    private var lastTimestamp: Date
    private var invalidated = false

    private let contentFanout = OpenUIKitFanout<ActivityContent<ContentState>>(replay: .log)
    private let contentStateFanout = OpenUIKitFanout<ContentState>(replay: .log)
    private let activityStateFanout = OpenUIKitFanout<ActivityState>(replay: .log)
    private let pushTokenFanout = OpenUIKitFanout<Data>(replay: .log)

    public var content: ActivityContent<ContentState> {
        _ = openUIKitRefreshLifecycle(now: OpenUIKitActivityKitHost.now)
        stateLock.lock()
        let value = storedContent
        stateLock.unlock()
        return value
    }

    public var contentState: ContentState { content.state }

    public var activityState: ActivityState {
        openUIKitRefreshLifecycle(now: OpenUIKitActivityKitHost.now)
    }

    public var pushToken: Data? {
        stateLock.lock()
        let value = storedPushToken
        stateLock.unlock()
        return value
    }

    public var contentUpdates: ContentUpdates {
        ContentUpdates(makeStream: { [contentFanout] in contentFanout.makeStream() })
    }

    public var contentStateUpdates: ContentStateUpdates {
        ContentStateUpdates(makeStream: { [contentStateFanout] in
            contentStateFanout.makeStream()
        })
    }

    public var activityStateUpdates: ActivityStateUpdates {
        ActivityStateUpdates(makeStream: { [activityStateFanout] in
            activityStateFanout.makeStream()
        })
    }

    public var pushTokenUpdates: PushTokenUpdates {
        PushTokenUpdates(makeStream: { [pushTokenFanout] in pushTokenFanout.makeStream() })
    }

    public static var activities: [Activity<Attributes>] {
        typeStore.snapshot()
    }

    public static var activityUpdates: ActivityUpdates {
        ActivityUpdates(makeStream: { typeStore.activityFanout.makeStream() })
    }

    public static var pushToStartToken: Data? { nil }

    public static var pushToStartTokenUpdates: PushTokenUpdates {
        PushTokenUpdates {
            let (stream, continuation) = AsyncStream<Data>.makeStream()
            continuation.finish()
            return stream
        }
    }

    private init(
        id: String,
        attributes: Attributes,
        content: ActivityContent<ContentState>,
        activityState: ActivityState,
        startedAt: Date
    ) {
        self.id = id
        self.attributes = attributes
        self.storedContent = content
        self.storedActivityState = activityState
        self.startedAt = startedAt
        self.lastTimestamp = startedAt
        contentFanout.yield(content)
        contentStateFanout.yield(content.state)
        activityStateFanout.yield(activityState)
    }

    public static func request(
        attributes: Attributes,
        contentState: Activity<Attributes>.ContentState,
        pushType: PushType? = nil
    ) throws -> Activity<Attributes> {
        try request(
            attributes: attributes,
            content: ActivityContent(state: contentState, staleDate: nil),
            pushType: pushType,
            style: .standard,
            id: nil
        )
    }

    public static func request(
        attributes: Attributes,
        content: ActivityContent<Activity<Attributes>.ContentState>,
        pushType: PushType? = nil
    ) throws -> Activity<Attributes> {
        try request(
            attributes: attributes,
            content: content,
            pushType: pushType,
            style: .standard,
            id: nil
        )
    }

    public static func request(
        attributes: Attributes,
        content: ActivityContent<Activity<Attributes>.ContentState>,
        pushType: PushType? = nil,
        style: ActivityStyle
    ) throws -> Activity<Attributes> {
        try request(
            attributes: attributes,
            content: content,
            pushType: pushType,
            style: style,
            id: nil
        )
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
        _ = (alertConfiguration, start)
        return try request(
            attributes: attributes,
            content: content,
            pushType: pushType,
            style: style,
            id: nil
        )
    }

    public static func request(
        attributes: Attributes,
        content: ActivityContent<Activity<Attributes>.ContentState>,
        pushType: PushType? = nil,
        style: ActivityStyle,
        alertConfiguration: AlertConfiguration,
        startDate: Date
    ) throws -> Activity<Attributes> {
        _ = (alertConfiguration, startDate)
        return try request(
            attributes: attributes,
            content: content,
            pushType: pushType,
            style: style,
            id: nil
        )
    }
#endif

    static func request(
        attributes: Attributes,
        content: ActivityContent<Activity<Attributes>.ContentState>,
        pushType: PushType?,
        style: ActivityStyle,
        id requestedID: String?
    ) throws -> Activity<Attributes> {
        _ = style
        if let channel = pushType?.openUIKitChannelName, channel.isEmpty {
            throw ActivityAuthorizationError.malformedActivityIdentifier
        }
        try OpenUIKitActivityKitHost.preflightRequest(id: requestedID)
        let payload = try OpenUIKitActivityKitHost.encodePayload(
            attributes: attributes,
            state: content.state
        )
        let startedAt = OpenUIKitActivityKitHost.now
        let resolvedContent = ActivityContent(
            state: payload.state,
            staleDate: content.staleDate,
            relevanceScore: content.relevanceScore
        )
        var initialState = ActivityState.active
        if let staleDate = resolvedContent.staleDate, staleDate <= startedAt {
            initialState = .stale
        }
        let activity = Activity(
            id: requestedID ?? UUID().uuidString,
            attributes: payload.attributes,
            content: resolvedContent,
            activityState: initialState,
            startedAt: startedAt
        )
        OpenUIKitActivityKitHost.register(activity)
        typeStore.append(activity)
        return activity
    }

    @_spi(OpenUIKitHost)
    public static func openUIKitHostRequest(
        attributes: Attributes,
        content: ActivityContent<Activity<Attributes>.ContentState>,
        pushType: PushType? = nil,
        style: ActivityStyle = .standard,
        id: String
    ) throws -> Activity<Attributes> {
        try request(
            attributes: attributes,
            content: content,
            pushType: pushType,
            style: style,
            id: id
        )
    }

    private func applyContentUpdate(
        _ content: ActivityContent<ContentState>,
        timestamp: Date
    ) {
        stateLock.lock()
        if invalidated || storedActivityState == .ended || storedActivityState == .dismissed {
            stateLock.unlock()
            return
        }
        if timestamp < lastTimestamp {
            stateLock.unlock()
            return
        }
        lastTimestamp = timestamp
        storedContent = content
        let previous = storedActivityState
        if let staleDate = content.staleDate, staleDate <= timestamp {
            storedActivityState = .stale
        } else if storedActivityState == .pending || storedActivityState == .stale {
            storedActivityState = .active
        }
        let nextState = storedActivityState
        stateLock.unlock()
        contentFanout.yield(content)
        contentStateFanout.yield(content.state)
        if nextState != previous {
            activityStateFanout.yield(nextState)
        }
    }

    public func update(using contentState: Activity<Attributes>.ContentState) async {
        await update(
            ActivityContent(
                state: contentState,
                staleDate: storedStaleDate,
                relevanceScore: storedRelevanceScore
            )
        )
    }

    public func update(
        _ content: ActivityContent<Activity<Attributes>.ContentState>
    ) async {
        applyContentUpdate(content, timestamp: OpenUIKitActivityKitHost.now)
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
        await update(content, alertConfiguration: alertConfiguration, timestamp: OpenUIKitActivityKitHost.now)
    }

    public func update(
        _ content: ActivityContent<Activity<Attributes>.ContentState>,
        alertConfiguration: AlertConfiguration? = nil,
        timestamp: Date
    ) async {
        _ = alertConfiguration
        applyContentUpdate(content, timestamp: timestamp)
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
                staleDate: storedStaleDate,
                relevanceScore: storedRelevanceScore
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
        await end(
            content,
            dismissalPolicy: dismissalPolicy,
            timestamp: OpenUIKitActivityKitHost.now
        )
    }

    public func end(
        _ content: ActivityContent<Activity<Attributes>.ContentState>?,
        dismissalPolicy: ActivityUIDismissalPolicy = .default,
        timestamp: Date
    ) async {
        applyEnd(content, dismissalPolicy: dismissalPolicy, timestamp: timestamp)
    }

    private func applyEnd(
        _ content: ActivityContent<ContentState>?,
        dismissalPolicy: ActivityUIDismissalPolicy,
        timestamp: Date
    ) {
        stateLock.lock()
        if invalidated || storedActivityState == .dismissed {
            stateLock.unlock()
            return
        }
        if timestamp < lastTimestamp {
            stateLock.unlock()
            return
        }
        lastTimestamp = timestamp
        if let content {
            storedContent = content
        }
        let previous = storedActivityState
        endedAt = timestamp
        let dismissalDate = dismissalPolicy.openUIKitDismissalDate(endedAt: timestamp)
        dismissAt = dismissalDate
        if timestamp >= dismissalDate {
            storedActivityState = .dismissed
        } else {
            storedActivityState = .ended
        }
        let nextState = storedActivityState
        let newContent = storedContent
        let didUpdateContent = content != nil
        stateLock.unlock()
        if didUpdateContent {
            contentFanout.yield(newContent)
            contentStateFanout.yield(newContent.state)
        }
        if nextState != previous {
            activityStateFanout.yield(nextState)
        }
    }

    private var storedStaleDate: Date? {
        stateLock.lock()
        let value = storedContent.staleDate
        stateLock.unlock()
        return value
    }

    private var storedRelevanceScore: Double {
        stateLock.lock()
        let value = storedContent.relevanceScore
        stateLock.unlock()
        return value
    }

    @discardableResult
    func openUIKitRefreshLifecycle(now: Date) -> ActivityState {
        stateLock.lock()
        if invalidated {
            let value = storedActivityState
            stateLock.unlock()
            return value
        }
        let previous = storedActivityState
        if storedActivityState == .active || storedActivityState == .stale || storedActivityState == .pending {
            if now.timeIntervalSince(startedAt) >= OpenUIKitActivityKitHost.maximumActiveInterval {
                endedAt = startedAt.addingTimeInterval(OpenUIKitActivityKitHost.maximumActiveInterval)
                dismissAt = endedAt!.addingTimeInterval(OpenUIKitActivityKitHost.defaultDismissalInterval)
                storedActivityState = .ended
            } else if let staleDate = storedContent.staleDate, now >= staleDate {
                storedActivityState = .stale
            }
        }
        if storedActivityState == .ended, let dismissAt, now >= dismissAt {
            storedActivityState = .dismissed
        }
        let next = storedActivityState
        stateLock.unlock()
        if next != previous {
            activityStateFanout.yield(next)
        }
        return next
    }
}

extension Activity: OpenUIKitLiveActivityHandle {
    var openUIKitHostID: String { id }

    var openUIKitHostCountsTowardCap: Bool {
        openUIKitRefreshLifecycle(now: OpenUIKitActivityKitHost.now) != .dismissed
    }

    func openUIKitHostRefreshLifecycle(now: Date) {
        _ = openUIKitRefreshLifecycle(now: now)
    }

    func openUIKitHostSetPushToken(_ data: Data?) {
        stateLock.lock()
        storedPushToken = data
        stateLock.unlock()
        if let data {
            pushTokenFanout.yield(data)
        }
    }

    func openUIKitHostInvalidate() {
        stateLock.lock()
        invalidated = true
        stateLock.unlock()
        contentFanout.finish()
        contentStateFanout.finish()
        activityStateFanout.finish()
        pushTokenFanout.finish()
    }
}
