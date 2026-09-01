import Foundation
@preconcurrency import Dispatch

/// Portable `CallKit` for Linux-hosted OpenUIKit.
///
/// Process-local call objects, transactions, and provider callbacks are real.
/// Apple telephony, system in-call UI, audio routing, PushKit VoIP delivery,
/// Settings, and Call Directory installation fail closed.
///
/// The isolated host gate compiles this module against Foundation only.
/// `AVAudioSession` delegate methods compile exclusively when the real
/// AVFoundation module is present (`#if canImport(AVFoundation)`). This
/// module never declares a lookalike `AVAudioSession` type.

public typealias CXCallDirectoryPhoneNumber = Int64

/// Unattested Call Directory ceiling. The sealed header is 311 bytes and was
/// not copied; do not treat this placeholder as the Darwin ABI value.
public let CXCallDirectoryPhoneNumberMax: CXCallDirectoryPhoneNumber = 0

/// Unattested `NSError` domain placeholders. Compare against `CXError.errorDomain`
/// in process; do not treat the string bytes as a Darwin dump.
public let CXErrorDomain = "CXErrorDomain"
public let CXErrorDomainIncomingCall = "CXErrorDomainIncomingCall"
public let CXErrorDomainRequestTransaction = "CXErrorDomainRequestTransaction"
public let CXErrorDomainCallDirectoryManager = "CXErrorDomainCallDirectoryManager"
public let CXErrorDomainNotificationServiceExtension =
    "CXErrorDomainNotificationServiceExtension"

public enum CXCallEndedReason: Int, Equatable, Hashable, Sendable {
    case failed = 1
    case remoteEnded = 2
    case unanswered = 3
    case answeredElsewhere = 4
    case declinedElsewhere = 5
}

public enum CXTranslationEngine: Int, Equatable, Hashable, Sendable {
    case `default`
    case custom
}

/// Process-local CallKit host. There is no `callservicesd` on Linux.
enum CXCallKitRuntime {
    struct WeakProvider {
        weak var value: CXProvider?
    }

    private struct WeakObserver {
        weak var value: CXCallObserver?
    }

    struct Snapshot {
        var calls: Set<UUID>
        var groups: [UUID: UUID]
        var owners: [UUID: ObjectIdentifier]
        var providers: [ObjectIdentifier: CXProvider]
        var maxGroups: [ObjectIdentifier: Int]
        var maxPerGroup: [ObjectIdentifier: Int]
    }

    private static let lock = NSLock()
    private static var providers: [WeakProvider] = []
    private static var observers: [WeakObserver] = []
    private static var calls: [UUID: CXCall] = [:]
    private static var groups: [UUID: UUID] = [:]
    private static var owners: [UUID: ObjectIdentifier] = [:]

    static func register(_ provider: CXProvider) {
        lock.lock()
        providers.removeAll { $0.value == nil || $0.value === provider }
        providers.append(WeakProvider(value: provider))
        lock.unlock()
    }

    static func unregister(_ provider: CXProvider) {
        let identifier = ObjectIdentifier(provider)
        lock.lock()
        providers.removeAll { $0.value == nil || $0.value === provider }
        let owned = owners.compactMap { uuid, owner in owner == identifier ? uuid : nil }
        var ended: [CXCall] = []
        for uuid in owned {
            if let call = calls.removeValue(forKey: uuid) {
                call.markEnded()
                ended.append(call)
            }
            groups.removeValue(forKey: uuid)
            owners.removeValue(forKey: uuid)
        }
        let currentObservers = snapshotObserversLocked()
        lock.unlock()
        for call in ended {
            notify(currentObservers, callChanged: call)
        }
    }

    static func provider(owning uuid: UUID) -> CXProvider? {
        lock.lock()
        providers.removeAll { $0.value == nil }
        let identifier = owners[uuid]
        let provider = providers.compactMap(\.value).first {
            identifier == ObjectIdentifier($0)
        }
        lock.unlock()
        return provider
    }

    static func liveProviders() -> [CXProvider] {
        lock.lock()
        providers.removeAll { $0.value == nil }
        let values = providers.compactMap(\.value)
        lock.unlock()
        return values
    }

    static func snapshot() -> Snapshot {
        lock.lock()
        providers.removeAll { $0.value == nil }
        var providerMap: [ObjectIdentifier: CXProvider] = [:]
        var maxGroups: [ObjectIdentifier: Int] = [:]
        var maxPerGroup: [ObjectIdentifier: Int] = [:]
        for provider in providers.compactMap(\.value) {
            let id = ObjectIdentifier(provider)
            providerMap[id] = provider
            maxGroups[id] = provider.configuration.maximumCallGroups
            maxPerGroup[id] = provider.configuration.maximumCallsPerCallGroup
        }
        let snap = Snapshot(
            calls: Set(calls.keys),
            groups: groups,
            owners: owners,
            providers: providerMap,
            maxGroups: maxGroups,
            maxPerGroup: maxPerGroup
        )
        lock.unlock()
        return snap
    }

    static func addObserver(_ observer: CXCallObserver) {
        lock.lock()
        observers.removeAll { $0.value == nil || $0.value === observer }
        observers.append(WeakObserver(value: observer))
        lock.unlock()
    }

    static func currentCalls() -> [CXCall] {
        lock.lock()
        let values = Array(calls.values).filter { !$0.hasEnded }.sorted {
            $0.uuid.uuidString < $1.uuid.uuidString
        }
        lock.unlock()
        return values
    }

    static func call(uuid: UUID) -> CXCall? {
        lock.lock()
        let call = calls[uuid]
        lock.unlock()
        return call
    }

    static func insertCall(
        _ call: CXCall,
        ownedBy provider: CXProvider
    ) -> CXErrorCodeIncomingCallError? {
        lock.lock()
        if calls[call.uuid] != nil {
            lock.unlock()
            return CXErrorCodeIncomingCallError(.callUUIDAlreadyExists)
        }
        calls[call.uuid] = call
        groups[call.uuid] = call.uuid
        owners[call.uuid] = ObjectIdentifier(provider)
        let currentObservers = snapshotObserversLocked()
        lock.unlock()
        notify(currentObservers, callChanged: call)
        return nil
    }

    static func applyUpdate(_ update: CXCallUpdate, to uuid: UUID) {
        lock.lock()
        guard let call = calls[uuid] else {
            lock.unlock()
            return
        }
        call.apply(update)
        let currentObservers = snapshotObserversLocked()
        lock.unlock()
        notify(currentObservers, callChanged: call)
    }

    static func markOutgoingStarted(uuid: UUID, provider: CXProvider) -> CXCall {
        lock.lock()
        let call: CXCall
        if let existing = calls[uuid] {
            existing.markOutgoingConnecting()
            call = existing
        } else {
            call = CXCall(uuid: uuid, outgoing: true)
            calls[uuid] = call
            groups[uuid] = uuid
            owners[uuid] = ObjectIdentifier(provider)
        }
        let currentObservers = snapshotObserversLocked()
        lock.unlock()
        notify(currentObservers, callChanged: call)
        return call
    }

    static func markOutgoingConnected(uuid: UUID) {
        lock.lock()
        guard let call = calls[uuid] else {
            lock.unlock()
            return
        }
        call.markConnected()
        let currentObservers = snapshotObserversLocked()
        lock.unlock()
        notify(currentObservers, callChanged: call)
    }

    static func markAnswered(uuid: UUID) {
        lock.lock()
        guard let call = calls[uuid] else {
            lock.unlock()
            return
        }
        call.markConnected()
        let currentObservers = snapshotObserversLocked()
        lock.unlock()
        notify(currentObservers, callChanged: call)
    }

    static func setHeld(uuid: UUID, onHold: Bool) {
        lock.lock()
        guard let call = calls[uuid] else {
            lock.unlock()
            return
        }
        call.setOnHold(onHold)
        let currentObservers = snapshotObserversLocked()
        lock.unlock()
        notify(currentObservers, callChanged: call)
    }

    static func group(uuid: UUID, with other: UUID?) -> Bool {
        lock.lock()
        guard calls[uuid] != nil else {
            lock.unlock()
            return false
        }
        if let other {
            guard calls[other] != nil else {
                lock.unlock()
                return false
            }
            let group = groups[other] ?? other
            groups[uuid] = group
        } else {
            groups[uuid] = uuid
        }
        let call = calls[uuid]!
        let currentObservers = snapshotObserversLocked()
        lock.unlock()
        notify(currentObservers, callChanged: call)
        return true
    }

    static func endCall(uuid: UUID) {
        lock.lock()
        guard let call = calls.removeValue(forKey: uuid) else {
            lock.unlock()
            return
        }
        call.markEnded()
        groups.removeValue(forKey: uuid)
        owners.removeValue(forKey: uuid)
        let currentObservers = snapshotObserversLocked()
        lock.unlock()
        notify(currentObservers, callChanged: call)
    }

    static func contains(_ uuid: UUID) -> Bool {
        lock.lock()
        let present = calls[uuid] != nil
        lock.unlock()
        return present
    }

    /// Full-transaction preflight. On failure the registry is untouched.
    static func plan(
        _ transaction: CXTransaction
    ) -> Result<[(CXProvider, [CXAction])], any Error> {
        if transaction.actions.isEmpty {
            return .failure(CXErrorCodeRequestTransactionError(.emptyTransaction))
        }

        let snap = snapshot()
        if snap.providers.isEmpty {
            return .failure(CXErrorCodeRequestTransactionError(.unknownCallProvider))
        }

        var calls = snap.calls
        var groups = snap.groups
        var owners = snap.owners
        var assignments: [ObjectIdentifier: [CXAction]] = [:]

        let existingOwners = Set(
            transaction.actions.compactMap { action -> ObjectIdentifier? in
                guard let callAction = action as? CXCallAction,
                      !(action is CXStartCallAction)
                else {
                    return nil
                }
                return owners[callAction.callUUID]
            }
        )
        let hasStarts = transaction.actions.contains { $0 is CXStartCallAction }

        var startProvider: CXProvider?
        if hasStarts {
            if existingOwners.count == 1, let id = existingOwners.first {
                startProvider = snap.providers[id]
            } else if existingOwners.isEmpty {
                // Starts have no owning UUID yet. Bind them only when a single
                // live provider exists; never fall back to a process-global
                // "last registered" provider while several are alive.
                if snap.providers.count == 1 {
                    startProvider = snap.providers.values.first
                } else {
                    return .failure(CXErrorCodeRequestTransactionError(.unknownCallProvider))
                }
            } else {
                return .failure(CXErrorCodeRequestTransactionError(.invalidAction))
            }
        }

        for action in transaction.actions {
            switch action {
            case let start as CXStartCallAction:
                guard let startProvider else {
                    return .failure(CXErrorCodeRequestTransactionError(.unknownCallProvider))
                }
                if calls.contains(start.callUUID) {
                    return .failure(CXErrorCodeRequestTransactionError(.callUUIDAlreadyExists))
                }
                calls.insert(start.callUUID)
                groups[start.callUUID] = start.callUUID
                owners[start.callUUID] = ObjectIdentifier(startProvider)
                assignments[ObjectIdentifier(startProvider), default: []].append(start)

            case let group as CXSetGroupCallAction:
                guard calls.contains(group.callUUID) else {
                    return .failure(CXErrorCodeRequestTransactionError(.unknownCallUUID))
                }
                guard let owner = owners[group.callUUID],
                      snap.providers[owner] != nil
                else {
                    return .failure(CXErrorCodeRequestTransactionError(.unknownCallUUID))
                }
                if let target = group.callUUIDToGroupWith {
                    guard calls.contains(target) else {
                        return .failure(CXErrorCodeRequestTransactionError(.unknownCallUUID))
                    }
                    guard owners[target] == owner else {
                        return .failure(CXErrorCodeRequestTransactionError(.invalidAction))
                    }
                    let destination = groups[target] ?? target
                    groups[group.callUUID] = destination
                } else {
                    groups[group.callUUID] = group.callUUID
                }
                assignments[owner, default: []].append(group)

            case let callAction as CXCallAction:
                guard calls.contains(callAction.callUUID) else {
                    return .failure(CXErrorCodeRequestTransactionError(.unknownCallUUID))
                }
                guard let owner = owners[callAction.callUUID],
                      snap.providers[owner] != nil
                else {
                    return .failure(CXErrorCodeRequestTransactionError(.unknownCallUUID))
                }
                assignments[owner, default: []].append(callAction)

            default:
                return .failure(CXErrorCodeRequestTransactionError(.invalidAction))
            }
        }

        for (providerID, provider) in snap.providers {
            _ = provider
            let owned = owners.filter { $0.value == providerID }.map(\.key)
            let groupIDs = Set(owned.compactMap { groups[$0] })
            if groupIDs.count > (snap.maxGroups[providerID] ?? 2) {
                return .failure(CXErrorCodeRequestTransactionError(.maximumCallGroupsReached))
            }
            let limit = snap.maxPerGroup[providerID] ?? 5
            for groupID in groupIDs {
                let size = owned.filter { groups[$0] == groupID }.count
                if size > limit {
                    return .failure(CXErrorCodeRequestTransactionError(.invalidAction))
                }
            }
        }

        var result: [(CXProvider, [CXAction])] = []
        for (id, actions) in assignments {
            guard let provider = snap.providers[id] else {
                return .failure(CXErrorCodeRequestTransactionError(.unknownCallProvider))
            }
            result.append((provider, actions))
        }
        return .success(result)
    }

    private static func snapshotObserversLocked() -> [CXCallObserver] {
        observers.removeAll { $0.value == nil }
        return observers.compactMap(\.value)
    }

    private static func notify(_ observers: [CXCallObserver], callChanged call: CXCall) {
        for observer in observers {
            observer.portableCallChanged(call)
        }
    }
}

func CXCallKitCallbackQueue(_ explicit: DispatchQueue?) -> DispatchQueue {
    explicit ?? .main
}
