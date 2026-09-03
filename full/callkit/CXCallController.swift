import Foundation
@preconcurrency import Dispatch

public protocol CXCallObserverDelegate: NSObjectProtocol {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall)
}

open class CXCall: NSObject, @unchecked Sendable {
    public let uuid: UUID
    public let isOutgoing: Bool
    public let isOnHold: Bool
    public let hasConnected: Bool
    public let hasEnded: Bool

    init(uuid: UUID, outgoing: Bool, onHold: Bool, hasConnected: Bool, hasEnded: Bool) {
        self.uuid = uuid
        self.isOutgoing = outgoing
        self.isOnHold = onHold
        self.hasConnected = hasConnected
        self.hasEnded = hasEnded
        super.init()
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CXCall else { return false }
        return uuid == other.uuid
            && isOutgoing == other.isOutgoing
            && isOnHold == other.isOnHold
            && hasConnected == other.hasConnected
            && hasEnded == other.hasEnded
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(uuid)
        return hasher.finalize()
    }
}

open class CXCallObserver: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private weak var delegate: CXCallObserverDelegate?
    private var callbackQueue: DispatchQueue
    let hostQueue: DispatchQueue

    public var calls: [CXCall] {
        CallKitRegistry.shared.snapshotCalls()
    }

    public override init() {
        let queue = DispatchQueue(
            label: "CallKit.CXCallObserver.\(UUID().uuidString)",
            qos: .userInitiated
        )
        self.hostQueue = queue
        self.callbackQueue = queue
        super.init()
        CallKitRegistry.shared.registerObserver(self)
    }

    public func setDelegate(_ delegate: (any CXCallObserverDelegate)?, queue: DispatchQueue?) {
        lock.lock()
        self.delegate = delegate
        self.callbackQueue = queue ?? hostQueue
        lock.unlock()
    }

    func hostNotify(_ call: CXCall) {
        lock.lock()
        let delegate = self.delegate
        let hopQueue = callbackQueue
        lock.unlock()
        guard let delegate else { return }
        callKitHop(hopQueue) { [weak self] in
            guard let self else { return }
            delegate.callObserver(self, callChanged: call)
        }
    }
}

open class CXCallController: NSObject, @unchecked Sendable {
    public let callObserver: CXCallObserver
    let hostQueue: DispatchQueue

    public override convenience init() {
        self.init(queue: DispatchQueue(label: "CallKit.CXCallController.default", qos: .userInitiated))
    }

    public init(queue: DispatchQueue) {
        self.hostQueue = queue
        self.callObserver = CXCallObserver()
        super.init()
    }

    public func request(_ transaction: CXTransaction) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.requestTransaction(transaction) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func requestTransaction(with action: CXAction) async throws {
        try await request(CXTransaction(action: action))
    }

    public func requestTransaction(with actions: [CXAction]) async throws {
        try await request(CXTransaction(actions: actions))
    }

    @_spi(OpenUIKitHost)
    public func requestTransaction(_ transaction: CXTransaction, completion: @escaping (Error?) -> Void) {
        let once = CallKitOnceFlag()
        func finish(_ error: Error?) {
            guard once.take() else { return }
            callKitHop(hostQueue) {
                completion(error)
            }
        }
        switch CallKitRegistry.shared.preflight(transaction) {
        case .failure(let error):
            finish(error)
        case .success(let success):
            success.provider.perform(
                transaction: transaction,
                completion: { error in
                    finish(error)
                },
                controllerQueue: hostQueue
            )
        }
    }
}
