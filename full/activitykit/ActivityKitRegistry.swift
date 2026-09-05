import Foundation

/// Process-local Live Activity host.
///
/// Linux has no ActivityKit daemon, Dynamic Island, Lock Screen, or APNs.
/// This registry is an in-process stand-in: `Activity.request` can succeed,
/// activities occupy a cap of eight non-dismissed entries, and dismissal
/// uses an injectable clock. It never presents UI or registers push tokens.
enum OpenUIKitActivityKitHost {
    static let lock = NSLock()

    static let maximumConcurrentActivities = 8
    static let maximumPayloadBytes = 4096
    static let defaultDismissalInterval: TimeInterval = 4 * 60 * 60
    static let maximumActiveInterval: TimeInterval = 8 * 60 * 60

    static var nowOverride: Date?
    static var areActivitiesEnabled = true
    static var frequentPushesEnabled = false
    static var deviceSupportsActivities = true
    static var entitled = true
    static var isBackgrounded = false
    static var injectedRequestError: ActivityAuthorizationError?

    static var records: [String: any OpenUIKitLiveActivityHandle] = [:]

    static let activityEnablementFanout = OpenUIKitFanout<Bool>(replay: .latest(true))
    static let frequentPushEnablementFanout = OpenUIKitFanout<Bool>(replay: .latest(false))

    static var now: Date {
        lock.lock()
        let value = nowOverride ?? Date()
        lock.unlock()
        return value
    }

    static func reset() {
        lock.lock()
        let existing = Array(records.values)
        records.removeAll()
        nowOverride = nil
        areActivitiesEnabled = true
        frequentPushesEnabled = false
        deviceSupportsActivities = true
        entitled = true
        isBackgrounded = false
        injectedRequestError = nil
        lock.unlock()
        activityEnablementFanout.reset(latest: true)
        frequentPushEnablementFanout.reset(latest: false)
        for handle in existing {
            handle.openUIKitHostInvalidate()
        }
    }

    static func setAreActivitiesEnabled(_ enabled: Bool) {
        lock.lock()
        let changed = areActivitiesEnabled != enabled
        areActivitiesEnabled = enabled
        lock.unlock()
        if changed {
            activityEnablementFanout.yield(enabled)
        }
    }

    static func setFrequentPushesEnabled(_ enabled: Bool) {
        lock.lock()
        let changed = frequentPushesEnabled != enabled
        frequentPushesEnabled = enabled
        lock.unlock()
        if changed {
            frequentPushEnablementFanout.yield(enabled)
        }
    }

    static func setNow(_ date: Date) {
        lock.lock()
        nowOverride = date
        let handles = Array(records.values)
        lock.unlock()
        for handle in handles {
            handle.openUIKitHostRefreshLifecycle(now: date)
        }
    }

    static func countedActivityCount() -> Int {
        lock.lock()
        let handles = Array(records.values)
        lock.unlock()
        return handles.filter { $0.openUIKitHostCountsTowardCap }.count
    }

    static func register(_ handle: any OpenUIKitLiveActivityHandle) {
        lock.lock()
        records[handle.openUIKitHostID] = handle
        lock.unlock()
    }

    static func handle(id: String) -> (any OpenUIKitLiveActivityHandle)? {
        lock.lock()
        let value = records[id]
        lock.unlock()
        return value
    }

    static func encodePayload<Attributes: ActivityAttributes>(
        attributes: Attributes,
        state: Attributes.ContentState
    ) throws -> (attributes: Attributes, state: Attributes.ContentState, bytes: Int) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let attributeData: Data
        let stateData: Data
        do {
            attributeData = try encoder.encode(attributes)
            stateData = try encoder.encode(state)
        } catch {
            throw ActivityAuthorizationError.persistenceFailure
        }
        let bytes = attributeData.count + stateData.count
        if bytes > maximumPayloadBytes {
            throw ActivityAuthorizationError.attributesTooLarge
        }
        do {
            let roundTripAttributes = try decoder.decode(Attributes.self, from: attributeData)
            let roundTripState = try decoder.decode(Attributes.ContentState.self, from: stateData)
            return (roundTripAttributes, roundTripState, bytes)
        } catch {
            throw ActivityAuthorizationError.persistenceFailure
        }
    }

    static func validateIdentifier(_ id: String) throws {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed != id {
            throw ActivityAuthorizationError.malformedActivityIdentifier
        }
        if id.contains("/") || id.contains("\0") {
            throw ActivityAuthorizationError.malformedActivityIdentifier
        }
    }

    static func preflightRequest(id: String?) throws {
        lock.lock()
        let injected = injectedRequestError
        injectedRequestError = nil
        let supports = deviceSupportsActivities
        let isEntitled = entitled
        let enabled = areActivitiesEnabled
        let backgrounded = isBackgrounded
        let existingIDs = Set(records.keys)
        lock.unlock()

        if let injected {
            throw injected
        }
        if !supports {
            throw ActivityAuthorizationError.unsupported
        }
        if !isEntitled {
            throw ActivityAuthorizationError.unentitled
        }
        if !enabled {
            throw ActivityAuthorizationError.denied
        }
        if backgrounded {
            throw ActivityAuthorizationError.visibility
        }
        if let id {
            try validateIdentifier(id)
            if existingIDs.contains(id) {
                throw ActivityAuthorizationError.reconnectNotPermitted
            }
        }
        if countedActivityCount() >= maximumConcurrentActivities {
            throw ActivityAuthorizationError.targetMaximumExceeded
        }
    }
}

protocol OpenUIKitLiveActivityHandle: AnyObject {
    var openUIKitHostID: String { get }
    var openUIKitHostCountsTowardCap: Bool { get }
    func openUIKitHostRefreshLifecycle(now: Date)
    func openUIKitHostSetPushToken(_ data: Data?)
    func openUIKitHostInvalidate()
}

enum OpenUIKitFanoutReplay<Element> {
    case none
    case latest(Element)
    case log
}

final class OpenUIKitFanout<Element>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]
    private var log: [Element] = []
    private var latest: Element?
    private var replay: OpenUIKitFanoutReplay<Element>

    init(replay: OpenUIKitFanoutReplay<Element>) {
        self.replay = replay
        switch replay {
        case .latest(let value):
            latest = value
        case .none, .log:
            break
        }
    }

    func reset(latest: Element? = nil) {
        lock.lock()
        log.removeAll()
        self.latest = latest
        if let latest {
            replay = .latest(latest)
        }
        let cons = Array(continuations.values)
        continuations.removeAll()
        lock.unlock()
        for continuation in cons {
            continuation.finish()
        }
    }

    func makeStream() -> AsyncStream<Element> {
        AsyncStream { continuation in
            let id = UUID()
            self.lock.lock()
            self.continuations[id] = continuation
            let snapshot: [Element]
            switch self.replay {
            case .none:
                snapshot = []
            case .latest:
                snapshot = self.latest.map { [$0] } ?? []
            case .log:
                snapshot = self.log
            }
            self.lock.unlock()
            for item in snapshot {
                continuation.yield(item)
            }
            continuation.onTermination = { _ in
                self.lock.lock()
                self.continuations.removeValue(forKey: id)
                self.lock.unlock()
            }
        }
    }

    func yield(_ element: Element) {
        lock.lock()
        log.append(element)
        latest = element
        let cons = Array(continuations.values)
        lock.unlock()
        for continuation in cons {
            continuation.yield(element)
        }
    }

    func finish() {
        lock.lock()
        let cons = Array(continuations.values)
        continuations.removeAll()
        lock.unlock()
        for continuation in cons {
            continuation.finish()
        }
    }
}

final class OpenUIKitAsyncPump<Element>: @unchecked Sendable {
    private var iterator: AsyncStream<Element>.Iterator

    init(stream: AsyncStream<Element>) {
        iterator = stream.makeAsyncIterator()
    }

    func next() async -> Element? {
        await iterator.next()
    }
}

extension ActivityUIDismissalPolicy {
    var openUIKitKind: OpenUIKitDismissalKind {
        switch kind {
        case .default:
            return .default
        case .immediate:
            return .immediate
        case .after(let date):
            return .after(date)
        }
    }

    func openUIKitDismissalDate(endedAt: Date) -> Date {
        let cap = endedAt.addingTimeInterval(OpenUIKitActivityKitHost.defaultDismissalInterval)
        switch kind {
        case .immediate:
            return endedAt
        case .default:
            return cap
        case .after(let date):
            if date < endedAt {
                return endedAt
            }
            return min(date, cap)
        }
    }
}

enum OpenUIKitDismissalKind: Equatable {
    case `default`
    case immediate
    case after(Date)
}

extension PushType {
    var openUIKitChannelName: String? {
        switch kind {
        case .token:
            return nil
        case .channel(let name):
            return name
        }
    }

    var openUIKitRequestsToken: Bool {
        switch kind {
        case .token:
            return true
        case .channel:
            return false
        }
    }
}

@_spi(OpenUIKitHost)
public enum OpenUIKitActivityKitTesting {
    public static func reset() {
        OpenUIKitActivityKitHost.reset()
        ActivityStoreRegistry.resetAll()
    }

    public static func setAreActivitiesEnabled(_ enabled: Bool) {
        OpenUIKitActivityKitHost.setAreActivitiesEnabled(enabled)
    }

    public static func setFrequentPushesEnabled(_ enabled: Bool) {
        OpenUIKitActivityKitHost.setFrequentPushesEnabled(enabled)
    }

    public static func setNow(_ date: Date) {
        OpenUIKitActivityKitHost.setNow(date)
    }

    public static func setDeviceSupportsActivities(_ supported: Bool) {
        OpenUIKitActivityKitHost.lock.lock()
        OpenUIKitActivityKitHost.deviceSupportsActivities = supported
        OpenUIKitActivityKitHost.lock.unlock()
    }

    public static func setEntitled(_ entitled: Bool) {
        OpenUIKitActivityKitHost.lock.lock()
        OpenUIKitActivityKitHost.entitled = entitled
        OpenUIKitActivityKitHost.lock.unlock()
    }

    public static func setBackgrounded(_ backgrounded: Bool) {
        OpenUIKitActivityKitHost.lock.lock()
        OpenUIKitActivityKitHost.isBackgrounded = backgrounded
        OpenUIKitActivityKitHost.lock.unlock()
    }

    public static func setInjectedRequestError(_ error: ActivityAuthorizationError?) {
        OpenUIKitActivityKitHost.lock.lock()
        OpenUIKitActivityKitHost.injectedRequestError = error
        OpenUIKitActivityKitHost.lock.unlock()
    }

    public static func setPushToken(_ data: Data?, forActivityID id: String) {
        OpenUIKitActivityKitHost.handle(id: id)?.openUIKitHostSetPushToken(data)
    }
}

enum ActivityStoreRegistry {
    static let lock = NSLock()
    static var boxes: [ObjectIdentifier: any ActivityTypeStoreReset] = [:]

    static func store<Attributes: ActivityAttributes>(
        for type: Attributes.Type
    ) -> ActivityTypeStore<Attributes> {
        let key = ObjectIdentifier(type)
        lock.lock()
        if let existing = boxes[key] as? ActivityTypeStore<Attributes> {
            lock.unlock()
            return existing
        }
        let created = ActivityTypeStore<Attributes>()
        boxes[key] = created
        lock.unlock()
        return created
    }

    static func resetAll() {
        lock.lock()
        let copies = Array(boxes.values)
        boxes.removeAll()
        lock.unlock()
        for store in copies {
            store.reset()
        }
    }
}

protocol ActivityTypeStoreReset: AnyObject {
    func reset()
}

final class ActivityTypeStore<Attributes: ActivityAttributes>: ActivityTypeStoreReset, @unchecked Sendable {
    private let lock = NSLock()
    private var ordered: [Activity<Attributes>] = []
    let activityFanout = OpenUIKitFanout<Activity<Attributes>>(replay: .log)

    func reset() {
        lock.lock()
        ordered.removeAll()
        lock.unlock()
        activityFanout.reset()
    }

    func append(_ activity: Activity<Attributes>) {
        lock.lock()
        ordered.append(activity)
        lock.unlock()
        activityFanout.yield(activity)
    }

    func snapshot() -> [Activity<Attributes>] {
        lock.lock()
        let copy = ordered
        lock.unlock()
        let now = OpenUIKitActivityKitHost.now
        return copy.filter { activity in
            activity.openUIKitRefreshLifecycle(now: now)
            return activity.activityState != .dismissed
        }
    }
}
