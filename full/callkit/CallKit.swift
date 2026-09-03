@_exported import Foundation
@preconcurrency import Dispatch

// MARK: - Public constants
//
// Error domain strings match the pinned `dotnet/macios` CallKit bindings
// (`[ErrorDomain ("CXErrorDomain")]` and siblings). They are declaration
// identities, not proof of an Apple CallKit daemon.

public let CXErrorDomain = "CXErrorDomain"
public let CXErrorDomainIncomingCall = "CXErrorDomainIncomingCall"
public let CXErrorDomainRequestTransaction = "CXErrorDomainRequestTransaction"
public let CXErrorDomainCallDirectoryManager = "CXErrorDomainCallDirectoryManager"
public let CXErrorDomainNotificationServiceExtension = "CXErrorDomainNotificationServiceExtension"

/// Phone-number storage is `Int64`. Apple's exact `CXCallDirectoryPhoneNumberMax`
/// payload is not in the sealed seed; this is a process-local ceiling so the
/// symbol compiles. Do not treat it as an attested Apple maximum.
public let CXCallDirectoryPhoneNumberMax: CXCallDirectoryPhoneNumber = .max

public typealias CXCallDirectoryPhoneNumber = Int64

// MARK: - Queue hop helpers
//
// Delegate and completion callbacks always `async` onto a serial queue.
// `nil` queues use a dedicated per-object serial queue, never the calling
// thread. Tests occupy that queue through `CallKitHostControl`.

struct CallKitUncheckedWork: @unchecked Sendable {
    let body: () -> Void
}

final class CallKitOnceFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var delivered = false

    func take() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if delivered {
            return false
        }
        delivered = true
        return true
    }
}

func callKitHop(_ queue: DispatchQueue, _ body: @escaping () -> Void) {
    let work = CallKitUncheckedWork(body: body)
    queue.async {
        work.body()
    }
}

func callKitQueueOrDedicated(_ queue: DispatchQueue?, label: String) -> DispatchQueue {
    queue ?? DispatchQueue(label: label, qos: .userInitiated)
}

// MARK: - Host SPI

/// Linux host-test control. Hidden from ordinary `import CallKit` clients.
@_spi(OpenUIKitHost)
public enum CallKitHostControl {
    public static func resetRegistry() {
        CallKitRegistry.shared.reset()
    }

    public static func enqueueOnProvider(
        _ provider: CXProvider,
        _ body: @escaping @Sendable () -> Void
    ) {
        provider.hostQueue.async(execute: body)
    }

    public static func enqueueOnObserver(
        _ observer: CXCallObserver,
        _ body: @escaping @Sendable () -> Void
    ) {
        observer.hostQueue.async(execute: body)
    }

    public static func enqueueOnController(
        _ controller: CXCallController,
        _ body: @escaping @Sendable () -> Void
    ) {
        controller.hostQueue.async(execute: body)
    }

    public static func providerQueue(_ provider: CXProvider) -> DispatchQueue {
        provider.hostQueue
    }

    public static func observerQueue(_ observer: CXCallObserver) -> DispatchQueue {
        observer.hostQueue
    }

    public static func controllerQueue(_ controller: CXCallController) -> DispatchQueue {
        controller.hostQueue
    }

    public static func isMuted(_ uuid: UUID) -> Bool {
        CallKitRegistry.shared.isMuted(uuid)
    }

    public static func groupID(for uuid: UUID) -> UUID? {
        CallKitRegistry.shared.groupID(for: uuid)
    }

    public static func translationEngine(for uuid: UUID) -> CXTranslationEngine? {
        CallKitRegistry.shared.translationEngine(for: uuid)
    }
}

// MARK: - Process-local registry
//
// Linux has no CallKit daemon or system call UI. Ownership, grouping, and
// observer snapshots live in this process. Providers are tracked weakly;
// a start action is routed only when exactly one live provider exists, never
// via a "last provider" pointer.

final class CallKitCallRecord {
    let uuid: UUID
    weak var provider: CXProvider?
    var isOutgoing: Bool
    var hasConnected = false
    var hasEnded = false
    var isOnHold = false
    var isMuted = false
    var groupID: UUID
    var handle: CXHandle?
    var localizedCallerName: String?
    var hasVideo = false
    var supportsDTMF = true
    var supportsGrouping = true
    var supportsHolding = true
    var supportsUngrouping = true
    var connectedAt: Date?
    var endedAt: Date?
    var startedConnectingAt: Date?
    var translationEngine: CXTranslationEngine?

    init(uuid: UUID, provider: CXProvider, outgoing: Bool) {
        self.uuid = uuid
        self.provider = provider
        self.isOutgoing = outgoing
        self.groupID = uuid
    }

    func snapshotCall() -> CXCall {
        CXCall(
            uuid: uuid,
            outgoing: isOutgoing,
            onHold: isOnHold,
            hasConnected: hasConnected,
            hasEnded: hasEnded
        )
    }
}

final class CallKitPendingTransaction {
    let transaction: CXTransaction
    let provider: CXProvider
    let reservedStartUUIDs: Set<UUID>
    var completion: ((any Error)?) -> Void
    let controllerQueue: DispatchQueue
    let once = CallKitOnceFlag()

    init(
        transaction: CXTransaction,
        provider: CXProvider,
        reservedStartUUIDs: Set<UUID>,
        completion: @escaping ((any Error)?) -> Void,
        controllerQueue: DispatchQueue
    ) {
        self.transaction = transaction
        self.provider = provider
        self.reservedStartUUIDs = reservedStartUUIDs
        self.completion = completion
        self.controllerQueue = controllerQueue
    }
}

final class CallKitRegistry {
    static let shared = CallKitRegistry()

    private let lock = NSLock()
    private var providers: [ObjectIdentifier: WeakProvider] = [:]
    private var calls: [UUID: CallKitCallRecord] = [:]
    private var reservedStarts: Set<UUID> = []
    private var observers: [ObjectIdentifier: WeakObserver] = [:]
    private var pending: [UUID: CallKitPendingTransaction] = [:]

    private struct WeakProvider {
        weak var value: CXProvider?
    }

    private struct WeakObserver {
        weak var value: CXCallObserver?
    }

    func reset() {
        lock.lock()
        providers.removeAll()
        calls.removeAll()
        reservedStarts.removeAll()
        observers.removeAll()
        pending.removeAll()
        lock.unlock()
    }

    func registerProvider(_ provider: CXProvider) {
        lock.lock()
        providers[ObjectIdentifier(provider)] = WeakProvider(value: provider)
        compactLocked()
        lock.unlock()
    }

    func invalidateProvider(_ provider: CXProvider) -> (
        calls: [CallKitCallRecord],
        pending: [CallKitPendingTransaction]
    ) {
        lock.lock()
        compactLocked()
        let id = ObjectIdentifier(provider)
        providers[id] = nil
        let owned = calls.values.filter { $0.provider === provider && !$0.hasEnded }
        for record in owned {
            record.hasEnded = true
            record.endedAt = Date()
        }
        reservedStarts.removeAll()
        let dropped = pending.values.filter { $0.provider === provider }
        for item in dropped {
            pending[item.transaction.uuid] = nil
            for uuid in item.reservedStartUUIDs {
                reservedStarts.remove(uuid)
            }
        }
        lock.unlock()
        return (owned, dropped)
    }

    func registerObserver(_ observer: CXCallObserver) {
        lock.lock()
        observers[ObjectIdentifier(observer)] = WeakObserver(value: observer)
        compactLocked()
        lock.unlock()
    }

    func liveProviders() -> [CXProvider] {
        lock.lock()
        defer { lock.unlock() }
        compactLocked()
        return providers.values.compactMap(\.value)
    }

    func soleLiveProvider() -> CXProvider? {
        let live = liveProviders()
        if live.count == 1 {
            return live[0]
        }
        return nil
    }

    func record(for uuid: UUID) -> CallKitCallRecord? {
        lock.lock()
        defer { lock.unlock() }
        return calls[uuid]
    }

    func providerOwning(uuid: UUID) -> CXProvider? {
        lock.lock()
        defer { lock.unlock() }
        return calls[uuid]?.provider
    }

    func snapshotCalls() -> [CXCall] {
        lock.lock()
        defer { lock.unlock() }
        return calls.values
            .filter { !$0.hasEnded }
            .sorted { $0.uuid.uuidString < $1.uuid.uuidString }
            .map { $0.snapshotCall() }
    }

    func liveObservers() -> [CXCallObserver] {
        lock.lock()
        defer { lock.unlock() }
        compactLocked()
        return observers.values.compactMap(\.value)
    }

    func activeGroupCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return groupCountLocked()
    }

    func groupCountLocked() -> Int {
        Set(calls.values.filter { !$0.hasEnded }.map(\.groupID)).count
    }

    func groupSizeLocked(_ groupID: UUID) -> Int {
        calls.values.filter { !$0.hasEnded && $0.groupID == groupID }.count
    }

    struct PreflightSuccess {
        let provider: CXProvider
        let reservedStartUUIDs: Set<UUID>
    }

    func preflight(_ transaction: CXTransaction) -> Result<PreflightSuccess, CXErrorCodeRequestTransactionError> {
        lock.lock()
        defer { lock.unlock() }
        compactLocked()
        let actions = transaction.actions
        if actions.isEmpty {
            return .failure(CXErrorCodeRequestTransactionError(.emptyTransaction))
        }

        var startUUIDs: [UUID] = []
        var seenStart = Set<UUID>()
        var startHandle: CXHandle?
        var referenced: [UUID] = []

        for action in actions {
            if action.isComplete {
                return .failure(CXErrorCodeRequestTransactionError(.invalidAction))
            }
            if let start = action as? CXStartCallAction {
                let uuid = start.callUUID
                if seenStart.contains(uuid) || calls[uuid] != nil || reservedStarts.contains(uuid) {
                    return .failure(CXErrorCodeRequestTransactionError(.callUUIDAlreadyExists))
                }
                seenStart.insert(uuid)
                startUUIDs.append(uuid)
                startHandle = start.handle
                _ = startHandle
            } else if let callAction = action as? CXCallAction {
                referenced.append(callAction.callUUID)
            } else {
                return .failure(CXErrorCodeRequestTransactionError(.invalidAction))
            }
        }

        let owners = referenced.compactMap { calls[$0]?.provider }
        if referenced.contains(where: { calls[$0] == nil }) {
            return .failure(CXErrorCodeRequestTransactionError(.unknownCallUUID))
        }
        if referenced.contains(where: { calls[$0]?.hasEnded == true }) {
            return .failure(CXErrorCodeRequestTransactionError(.unknownCallUUID))
        }

        let uniqueOwners = Set(owners.map { ObjectIdentifier($0) })
        let provider: CXProvider
        if uniqueOwners.count > 1 {
            return .failure(CXErrorCodeRequestTransactionError(.unknownCallProvider))
        }
        if let existing = owners.first {
            provider = existing
        } else {
            let live = providers.values.compactMap(\.value)
            guard live.count == 1, let only = live.first else {
                return .failure(CXErrorCodeRequestTransactionError(.unknownCallProvider))
            }
            provider = only
        }

        let configuration = provider.configuration
        let currentGroups = groupCountLocked()
        if currentGroups + startUUIDs.count > configuration.maximumCallGroups {
            return .failure(CXErrorCodeRequestTransactionError(.maximumCallGroupsReached))
        }

        for action in actions {
            if let group = action as? CXSetGroupCallAction {
                let sourceUUID = group.callUUID
                guard let source = calls[sourceUUID], !source.hasEnded else {
                    return .failure(CXErrorCodeRequestTransactionError(.unknownCallUUID))
                }
                if let targetUUID = group.callUUIDToGroupWith {
                    guard let target = calls[targetUUID], !target.hasEnded else {
                        return .failure(CXErrorCodeRequestTransactionError(.unknownCallUUID))
                    }
                    if source.provider !== target.provider {
                        return .failure(CXErrorCodeRequestTransactionError(.unknownCallProvider))
                    }
                    var merged = groupSizeLocked(target.groupID)
                    if source.groupID != target.groupID {
                        merged += groupSizeLocked(source.groupID)
                    }
                    if merged > configuration.maximumCallsPerCallGroup {
                        return .failure(CXErrorCodeRequestTransactionError(.maximumCallGroupsReached))
                    }
                }
            }
        }

        for uuid in startUUIDs {
            reservedStarts.insert(uuid)
        }
        return .success(PreflightSuccess(provider: provider, reservedStartUUIDs: Set(startUUIDs)))
    }

    func storePending(_ item: CallKitPendingTransaction) {
        lock.lock()
        pending[item.transaction.uuid] = item
        lock.unlock()
    }

    func pendingTransactions(for provider: CXProvider) -> [CXTransaction] {
        lock.lock()
        defer { lock.unlock() }
        return pending.values
            .filter { $0.provider === provider }
            .map(\.transaction)
    }

    func pendingCallActions(of callActionClass: AnyClass, callUUID: UUID, provider: CXProvider) -> [CXCallAction] {
        lock.lock()
        defer { lock.unlock() }
        var result: [CXCallAction] = []
        for item in pending.values where item.provider === provider {
            for action in item.transaction.actions {
                guard !action.isComplete, let callAction = action as? CXCallAction else { continue }
                guard callAction.callUUID == callUUID else { continue }
                if callAction.isKind(of: callActionClass) {
                    result.append(callAction)
                }
            }
        }
        return result
    }

    func finishPending(transactionUUID: UUID, error: (any Error)?) {
        lock.lock()
        let item = pending.removeValue(forKey: transactionUUID)
        if let item {
            for uuid in item.reservedStartUUIDs where calls[uuid] == nil {
                reservedStarts.remove(uuid)
            }
        }
        lock.unlock()
        guard let item else { return }
        guard item.once.take() else { return }
        let completion = item.completion
        callKitHop(item.controllerQueue) {
            completion(error)
        }
    }

    func applyStart(uuid: UUID, provider: CXProvider, handle: CXHandle, video: Bool) -> CXCall? {
        lock.lock()
        defer { lock.unlock() }
        reservedStarts.remove(uuid)
        if calls[uuid] != nil {
            return nil
        }
        let record = CallKitCallRecord(uuid: uuid, provider: provider, outgoing: true)
        record.handle = handle
        record.hasVideo = video
        calls[uuid] = record
        return record.snapshotCall()
    }

    func applyIncoming(uuid: UUID, provider: CXProvider, update: CXCallUpdate) -> Result<CXCall, CXErrorCodeIncomingCallError> {
        lock.lock()
        defer { lock.unlock() }
        if calls[uuid] != nil || reservedStarts.contains(uuid) {
            return .failure(CXErrorCodeIncomingCallError(.callUUIDAlreadyExists))
        }
        if groupCountLocked() + 1 > provider.configuration.maximumCallGroups {
            return .failure(CXErrorCodeIncomingCallError(.unknown))
        }
        let record = CallKitCallRecord(uuid: uuid, provider: provider, outgoing: false)
        applyUpdateLocked(record, update)
        calls[uuid] = record
        return .success(record.snapshotCall())
    }

    func applyUpdate(_ uuid: UUID, _ update: CXCallUpdate) -> CXCall? {
        lock.lock()
        defer { lock.unlock() }
        guard let record = calls[uuid], !record.hasEnded else { return nil }
        applyUpdateLocked(record, update)
        return record.snapshotCall()
    }

    private func applyUpdateLocked(_ record: CallKitCallRecord, _ update: CXCallUpdate) {
        if let handle = update.remoteHandle {
            record.handle = handle
        }
        if let name = update.localizedCallerName {
            record.localizedCallerName = name
        }
        record.hasVideo = update.hasVideo
        record.supportsDTMF = update.supportsDTMF
        record.supportsGrouping = update.supportsGrouping
        record.supportsHolding = update.supportsHolding
        record.supportsUngrouping = update.supportsUngrouping
    }

    func applyAnswer(uuid: UUID, connectedAt: Date) -> CXCall? {
        lock.lock()
        defer { lock.unlock() }
        guard let record = calls[uuid], !record.hasEnded else { return nil }
        record.hasConnected = true
        record.connectedAt = connectedAt
        record.isOnHold = false
        return record.snapshotCall()
    }

    func applyEnd(uuid: UUID, endedAt: Date) -> CXCall? {
        lock.lock()
        defer { lock.unlock() }
        guard let record = calls[uuid] else { return nil }
        record.hasEnded = true
        record.endedAt = endedAt
        record.groupID = record.uuid
        return record.snapshotCall()
    }

    func applyEndedReport(uuid: UUID, endedAt: Date?, reason: CXCallEndedReason) -> CXCall? {
        _ = reason
        return applyEnd(uuid: uuid, endedAt: endedAt ?? Date())
    }

    func applyHold(uuid: UUID, onHold: Bool) -> CXCall? {
        lock.lock()
        defer { lock.unlock() }
        guard let record = calls[uuid], !record.hasEnded else { return nil }
        record.isOnHold = onHold
        return record.snapshotCall()
    }

    func applyMute(uuid: UUID, muted: Bool) -> CXCall? {
        lock.lock()
        defer { lock.unlock() }
        guard let record = calls[uuid], !record.hasEnded else { return nil }
        record.isMuted = muted
        return record.snapshotCall()
    }

    func applyGroup(uuid: UUID, with target: UUID?) -> CXCall? {
        lock.lock()
        defer { lock.unlock() }
        guard let source = calls[uuid], !source.hasEnded else { return nil }
        if let target {
            guard let other = calls[target], !other.hasEnded else { return nil }
            let newGroup = other.groupID
            let oldGroup = source.groupID
            for record in calls.values where record.groupID == oldGroup && !record.hasEnded {
                record.groupID = newGroup
            }
        } else {
            source.groupID = source.uuid
        }
        return source.snapshotCall()
    }

    func applyTranslation(uuid: UUID, engine: CXTranslationEngine?) -> CXCall? {
        lock.lock()
        defer { lock.unlock() }
        guard let record = calls[uuid], !record.hasEnded else { return nil }
        record.translationEngine = engine
        return record.snapshotCall()
    }

    func applyOutgoingStartedConnecting(uuid: UUID, at date: Date?) -> CXCall? {
        lock.lock()
        defer { lock.unlock() }
        guard let record = calls[uuid], !record.hasEnded else { return nil }
        record.startedConnectingAt = date
        record.isOutgoing = true
        return record.snapshotCall()
    }

    func applyOutgoingConnected(uuid: UUID, at date: Date?) -> CXCall? {
        lock.lock()
        defer { lock.unlock() }
        guard let record = calls[uuid], !record.hasEnded else { return nil }
        record.hasConnected = true
        record.connectedAt = date
        return record.snapshotCall()
    }

    func releaseReservations(_ uuids: Set<UUID>) {
        lock.lock()
        for uuid in uuids where calls[uuid] == nil {
            reservedStarts.remove(uuid)
        }
        lock.unlock()
    }

    func isMuted(_ uuid: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return calls[uuid]?.isMuted ?? false
    }

    func groupID(for uuid: UUID) -> UUID? {
        lock.lock()
        defer { lock.unlock() }
        return calls[uuid]?.groupID
    }

    func translationEngine(for uuid: UUID) -> CXTranslationEngine? {
        lock.lock()
        defer { lock.unlock() }
        return calls[uuid]?.translationEngine
    }

    func notifyObservers(callUUID: UUID) {
        let observers = liveObservers()
        let call = record(for: callUUID)?.snapshotCall()
        guard let call else { return }
        for observer in observers {
            observer.hostNotify(call)
        }
    }

    private func compactLocked() {
        providers = providers.filter { $0.value.value != nil }
        observers = observers.filter { $0.value.value != nil }
    }
}
