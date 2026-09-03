@preconcurrency import Dispatch
import Foundation

// MARK: - Delegate
//
// Required `didUpdate` matches the graph (`Abstract` in macios). Optional
// incoming-push / invalidation methods have empty defaults. The iOS 11+
// ObjC selector `...withCompletionHandler:` is spelled both as a trailing
// completion and as the canonical Swift `async` overlay (the seed's
// conflicting duplicate of that precise ID). Linux cannot observe which
// method Apple actually invokes when both are implemented.

public protocol PKPushRegistryDelegate: NSObjectProtocol {
    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    )

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType
    )

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        withCompletionHandler completion: @escaping () -> Void
    )

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType
    ) async

    func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    )
}

extension PKPushRegistryDelegate {
    public func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType
    ) {
        _ = (registry, payload, type)
    }

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        withCompletionHandler completion: @escaping () -> Void
    ) {
        completion()
    }

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType
    ) async {
        await withCheckedContinuation { continuation in
            self.pushRegistry(
                registry,
                didReceiveIncomingPushWith: payload,
                for: type,
                withCompletionHandler: {
                    continuation.resume()
                }
            )
        }
    }

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        _ = (registry, type)
    }
}

// MARK: - Registry
//
// Fail-closed: setting `desiredPushTypes` records the set and never talks
// to APNs, never fabricates a token, and never invokes `didUpdate` or
// `didInvalidate`. `pushToken(for:)` is always nil. Delegate callbacks
// that do run (host-test SPI only) hop once with `async` onto the queue
// captured at `init(queue:)` — or onto a private serial queue when that
// argument is nil. Darwin's nil-queue choice (main vs private serial) is
// unobserved; Linux uses a private serial queue and does not claim Apple
// identity.

private struct PKPushRegistryWork: @unchecked Sendable {
    let body: () -> Void
}

private final class PKPushRegistryOnceFlag: @unchecked Sendable {
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

open class PKPushRegistry: NSObject {
    private let lock = NSLock()
    private let callbackQueue: DispatchQueue
    private weak var storedDelegate: (any PKPushRegistryDelegate)?
    private var storedDesiredPushTypes: Set<PKPushType>?

    @available(*, unavailable, message: "Use init(queue:)")
    public override init() {
        fatalError("PKPushRegistry() is unavailable; use init(queue:)")
    }

    /// Designated initializer. `queue` is the Darwin `dispatch_queue_t?`
    /// overlay (`DispatchQueue?`). Nil selects a private serial queue
    /// labeled `PushKit.PKPushRegistry.callback`; that is a Linux choice,
    /// not an Apple-oracle observation of main-queue versus private-queue.
    public init(queue: DispatchQueue?) {
        if let queue {
            self.callbackQueue = queue
        } else {
            self.callbackQueue = DispatchQueue(
                label: "PushKit.PKPushRegistry.callback",
                qos: .utility
            )
        }
        super.init()
    }

    open weak var delegate: (any PKPushRegistryDelegate)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedDelegate
        }
        set {
            lock.lock()
            storedDelegate = newValue
            lock.unlock()
        }
    }

    open var desiredPushTypes: Set<PKPushType>? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedDesiredPushTypes
        }
        set {
            lock.lock()
            storedDesiredPushTypes = newValue
            lock.unlock()
            // Fail-closed: do not contact APNs, do not mint a token, do not
            // invoke didUpdate / didInvalidate. Darwin registration timing
            // and entitlement failure callbacks are unobserved.
        }
    }

    open func pushToken(for type: PKPushType) -> Data? {
        _ = type
        return nil
    }

    func hostEnqueue(_ body: @escaping () -> Void) {
        let work = PKPushRegistryWork(body: body)
        callbackQueue.async {
            work.body()
        }
    }

    func hostDeliverCredentials(
        _ credentials: PKPushCredentials,
        type: PKPushType
    ) {
        lock.lock()
        let hasDelegate = storedDelegate != nil
        lock.unlock()
        guard hasDelegate else { return }
        let once = PKPushRegistryOnceFlag()
        hostEnqueue { [weak self] in
            guard let self, once.take() else { return }
            self.lock.lock()
            let delegate = self.storedDelegate
            self.lock.unlock()
            delegate?.pushRegistry(self, didUpdate: credentials, for: type)
        }
    }

    func hostDeliverIncomingPush(
        _ payload: PKPushPayload,
        type: PKPushType
    ) {
        lock.lock()
        let hasDelegate = storedDelegate != nil
        lock.unlock()
        guard hasDelegate else { return }
        let once = PKPushRegistryOnceFlag()
        hostEnqueue { [weak self] in
            guard let self, once.take() else { return }
            self.lock.lock()
            let delegate = self.storedDelegate
            self.lock.unlock()
            delegate?.pushRegistry(
                self,
                didReceiveIncomingPushWith: payload,
                for: type,
                withCompletionHandler: {}
            )
        }
    }

    func hostDeliverInvalidation(type: PKPushType) {
        lock.lock()
        let hasDelegate = storedDelegate != nil
        lock.unlock()
        guard hasDelegate else { return }
        let once = PKPushRegistryOnceFlag()
        hostEnqueue { [weak self] in
            guard let self, once.take() else { return }
            self.lock.lock()
            let delegate = self.storedDelegate
            self.lock.unlock()
            delegate?.pushRegistry(self, didInvalidatePushTokenFor: type)
        }
    }
}
