import Foundation

/// Portable `CallKit` for Linux-hosted OpenUIKit.
///
/// The public type, method, and error-code identities follow the pinned iPhoneOS
/// 26.1 Swift symbol graph. Process-local call objects, transactions, and
/// provider callbacks are real. Apple telephony, system in-call UI, audio-session
/// activation, PushKit VoIP delivery, Settings, and Call Directory installation
/// are not present on this host and fail closed instead of fabricating success.

public typealias CXCallDirectoryPhoneNumber = Int64

/// Maximum E.164-style directory entry used by Call Directory APIs.
/// The 10-digit ceiling is the publicly documented limit for sequential
/// phone-number entries; record an oracle probe if a later SDK changes it.
public let CXCallDirectoryPhoneNumberMax: CXCallDirectoryPhoneNumber = 9_999_999_999

/// Publicly observed `NSError` domain strings for CallKit. Exact bytes were not
/// present in the sealed SDK inputs; see `oracle-questions.tsv`.
public let CXErrorDomain = "com.apple.CallKit.error"
public let CXErrorDomainIncomingCall = "com.apple.CallKit.error.incomingcall"
public let CXErrorDomainRequestTransaction = "com.apple.CallKit.error.requesttransaction"
public let CXErrorDomainCallDirectoryManager = "com.apple.CallKit.error.calldirectorymanager"
public let CXErrorDomainNotificationServiceExtension =
    "com.apple.CallKit.error.notificationserviceextension"

public enum CXCallEndedReason: Int, Equatable, Hashable, Sendable {
    case failed = 1
    case remoteEnded = 2
    case unanswered = 3
    case answeredElsewhere = 4
    case declinedElsewhere = 5
}

public enum CXTranslationEngine: Int, Equatable, Hashable, Sendable {
    case `default` = 0
    case custom = 1
}

/// Process-local CallKit host. There is no `callservicesd` on Linux: calls live
/// in this registry, provider callbacks stay in-process, and Apple services
/// remain fail-closed.
enum CXCallKitRuntime {
    private struct WeakProvider {
        weak var value: CXProvider?
    }

    private struct WeakObserver {
        weak var value: CXCallObserver?
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
        for uuid in owned {
            calls.removeValue(forKey: uuid)
            groups.removeValue(forKey: uuid)
            owners.removeValue(forKey: uuid)
        }
        let remaining = Array(calls.values)
        let currentObservers = snapshotObserversLocked()
        lock.unlock()
        for call in remaining {
            notify(currentObservers, callChanged: call)
        }
    }

    static func activeProvider() -> CXProvider? {
        lock.lock()
        providers.removeAll { $0.value == nil }
        let provider = providers.last?.value
        lock.unlock()
        return provider
    }

    static func addObserver(_ observer: CXCallObserver) {
        lock.lock()
        observers.removeAll { $0.value == nil || $0.value === observer }
        observers.append(WeakObserver(value: observer))
        lock.unlock()
    }

    static func currentCalls() -> [CXCall] {
        lock.lock()
        let values = Array(calls.values).sorted {
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

    static func groupCount() -> Int {
        lock.lock()
        let count = Set(groups.values).count
        lock.unlock()
        return count
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
