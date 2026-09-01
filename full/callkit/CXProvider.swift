import Foundation
@preconcurrency import Dispatch

public protocol CXProviderDelegate: NSObjectProtocol {
    func providerDidReset(_ provider: CXProvider)
    func providerDidBegin(_ provider: CXProvider)
    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool
    func provider(_ provider: CXProvider, perform action: CXStartCallAction)
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction)
    func provider(_ provider: CXProvider, perform action: CXEndCallAction)
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction)
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction)
    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction)
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction)
    func provider(_ provider: CXProvider, perform action: CXSetTranslatingCallAction)
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction)
}

extension CXProviderDelegate {
    public func providerDidBegin(_ provider: CXProvider) {
        _ = provider
    }

    public func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
        _ = provider
        _ = transaction
        return false
    }

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        _ = provider
        _ = action
    }

    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        _ = provider
        _ = action
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        _ = provider
        _ = action
    }

    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        _ = provider
        _ = action
    }

    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        _ = provider
        _ = action
    }

    public func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        _ = provider
        _ = action
    }

    public func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        _ = provider
        _ = action
    }

    public func provider(_ provider: CXProvider, perform action: CXSetTranslatingCallAction) {
        _ = provider
        _ = action
    }

    public func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        _ = provider
        _ = action
    }
}

open class CXProvider: NSObject, @unchecked Sendable {
    private let stateLock = NSLock()
    private var storedConfiguration: CXProviderConfiguration
    private weak var delegate: (any CXProviderDelegate)?
    private var delegateQueue: DispatchQueue?
    private var pending: [CXTransaction] = []
    private var didBegin = false
    private var valid = true

    public var configuration: CXProviderConfiguration {
        get {
            stateLock.lock()
            let value = storedConfiguration
            stateLock.unlock()
            return value
        }
        set {
            let copied = (newValue.copy() as? CXProviderConfiguration) ?? newValue
            stateLock.lock()
            storedConfiguration = copied
            stateLock.unlock()
        }
    }

    public var pendingTransactions: [CXTransaction] {
        stateLock.lock()
        let values = pending.filter { !$0.isComplete }
        stateLock.unlock()
        return values
    }

    public init(configuration: CXProviderConfiguration) {
        self.storedConfiguration =
            (configuration.copy() as? CXProviderConfiguration) ?? configuration
        super.init()
        CXCallKitRuntime.register(self)
    }

    deinit {
        CXCallKitRuntime.unregister(self)
    }

    open func setDelegate(
        _ delegate: (any CXProviderDelegate)?,
        queue: DispatchQueue?
    ) {
        stateLock.lock()
        self.delegate = delegate
        self.delegateQueue = queue
        let shouldBegin = !didBegin && valid
        if shouldBegin {
            didBegin = true
        }
        stateLock.unlock()
        if shouldBegin {
            performOnDelegateQueue {
                delegate?.providerDidBegin(self)
            }
        }
    }

    open func invalidate() {
        stateLock.lock()
        let alreadyInvalid = !valid
        valid = false
        pending.removeAll()
        let delegate = self.delegate
        stateLock.unlock()
        CXCallKitRuntime.unregister(self)
        guard !alreadyInvalid else { return }
        performOnDelegateQueue {
            delegate?.providerDidReset(self)
        }
    }

    open func reportNewIncomingCall(
        with UUID: UUID,
        update: CXCallUpdate,
        completion: @escaping ((any Error)?) -> Void
    ) {
        guard isValid else {
            completion(CXError(.unentitled))
            return
        }
        let call = CXCall(uuid: UUID, outgoing: false)
        call.apply(update)
        if let error = CXCallKitRuntime.insertCall(call, ownedBy: self) {
            completion(error)
            return
        }
        completion(nil)
    }

    open func reportNewIncomingCall(with UUID: UUID, update: CXCallUpdate) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reportNewIncomingCall(with: UUID, update: update) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    open func reportCall(with UUID: UUID, updated update: CXCallUpdate) {
        CXCallKitRuntime.applyUpdate(update, to: UUID)
    }

    open func reportCall(
        with UUID: UUID,
        endedAt dateEnded: Date?,
        reason endedReason: CXCallEndedReason
    ) {
        _ = dateEnded
        _ = endedReason
        CXCallKitRuntime.endCall(uuid: UUID)
        removePending(for: UUID)
    }

    open func reportOutgoingCall(with UUID: UUID, startedConnectingAt dateStartedConnecting: Date?) {
        _ = dateStartedConnecting
        _ = CXCallKitRuntime.markOutgoingStarted(uuid: UUID, provider: self)
    }

    open func reportOutgoingCall(with UUID: UUID, connectedAt dateConnected: Date?) {
        _ = dateConnected
        CXCallKitRuntime.markOutgoingConnected(uuid: UUID)
    }

    open func pendingCallActions(of callActionClass: AnyClass, withCall callUUID: UUID) -> [CXCallAction] {
        stateLock.lock()
        let actions = pending.flatMap(\.actions).compactMap { action -> CXCallAction? in
            guard let callAction = action as? CXCallAction,
                  !callAction.isComplete,
                  callAction.callUUID == callUUID,
                  callAction.isKind(of: callActionClass)
            else {
                return nil
            }
            return callAction
        }
        stateLock.unlock()
        return actions
    }

    /// Linux has no Notification Service Extension or PushKit VoIP host. The
    /// payload is not forwarded and the call fails closed.
    open class func reportNewIncomingVoIPPushPayload(
        _ dictionaryPayload: [AnyHashable: Any],
        completion: @escaping ((any Error)?) -> Void
    ) {
        _ = dictionaryPayload
        completion(CXErrorCodeNotificationServiceExtensionError(.invalidClientProcess))
    }

    open class func reportNewIncomingVoIPPushPayload(
        _ dictionaryPayload: [AnyHashable: Any]
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reportNewIncomingVoIPPushPayload(dictionaryPayload) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func submit(_ transaction: CXTransaction, completion: @escaping ((any Error)?) -> Void) {
        guard isValid else {
            completion(CXErrorCodeRequestTransactionError(.unknownCallProvider))
            return
        }
        if transaction.actions.isEmpty {
            completion(CXErrorCodeRequestTransactionError(.emptyTransaction))
            return
        }
        if let error = validate(transaction) {
            completion(error)
            return
        }

        stateLock.lock()
        pending.append(transaction)
        let delegate = self.delegate
        stateLock.unlock()

        performOnDelegateQueue {
            if delegate?.provider(self, execute: transaction) == true {
                completion(nil)
                return
            }
            for action in transaction.actions {
                self.dispatch(action, to: delegate)
            }
            completion(nil)
        }
    }

    private var isValid: Bool {
        stateLock.lock()
        let value = valid
        stateLock.unlock()
        return value
    }

    private func validate(_ transaction: CXTransaction) -> (any Error)? {
        let maximumGroups = configuration.maximumCallGroups
        for action in transaction.actions {
            switch action {
            case let start as CXStartCallAction:
                if CXCallKitRuntime.contains(start.callUUID) {
                    return CXErrorCodeRequestTransactionError(.callUUIDAlreadyExists)
                }
                if CXCallKitRuntime.groupCount() >= maximumGroups {
                    return CXErrorCodeRequestTransactionError(.maximumCallGroupsReached)
                }
            case let callAction as CXCallAction:
                if !CXCallKitRuntime.contains(callAction.callUUID)
                    && !(callAction is CXStartCallAction)
                {
                    return CXErrorCodeRequestTransactionError(.unknownCallUUID)
                }
            default:
                return CXErrorCodeRequestTransactionError(.invalidAction)
            }
        }
        return nil
    }

    private func dispatch(_ action: CXAction, to delegate: (any CXProviderDelegate)?) {
        switch action {
        case let start as CXStartCallAction:
            _ = CXCallKitRuntime.markOutgoingStarted(uuid: start.callUUID, provider: self)
            delegate?.provider(self, perform: start)
        case let answer as CXAnswerCallAction:
            CXCallKitRuntime.markAnswered(uuid: answer.callUUID)
            delegate?.provider(self, perform: answer)
        case let end as CXEndCallAction:
            delegate?.provider(self, perform: end)
        case let held as CXSetHeldCallAction:
            CXCallKitRuntime.setHeld(uuid: held.callUUID, onHold: held.isOnHold)
            delegate?.provider(self, perform: held)
        case let muted as CXSetMutedCallAction:
            delegate?.provider(self, perform: muted)
        case let group as CXSetGroupCallAction:
            _ = CXCallKitRuntime.group(uuid: group.callUUID, with: group.callUUIDToGroupWith)
            delegate?.provider(self, perform: group)
        case let dtmf as CXPlayDTMFCallAction:
            delegate?.provider(self, perform: dtmf)
        case let translating as CXSetTranslatingCallAction:
            delegate?.provider(self, perform: translating)
        default:
            action.fail()
            delegate?.provider(self, timedOutPerforming: action)
        }
    }

    private func removePending(for uuid: UUID) {
        stateLock.lock()
        pending.removeAll { transaction in
            transaction.actions.allSatisfy { action in
                guard let callAction = action as? CXCallAction else {
                    return action.isComplete
                }
                return callAction.callUUID != uuid || callAction.isComplete
            }
        }
        stateLock.unlock()
    }

    private func performOnDelegateQueue(_ body: @escaping () -> Void) {
        stateLock.lock()
        let queue = delegateQueue
        stateLock.unlock()
        if let queue {
            queue.async {
                body()
            }
        } else {
            body()
        }
    }
}

open class CXCallController: NSObject, @unchecked Sendable {
    private let queue: DispatchQueue
    public let callObserver: CXCallObserver

    public convenience override init() {
        self.init(queue: DispatchQueue(label: "org.openuikit.CallKit.CXCallController"))
    }

    public init(queue: DispatchQueue) {
        self.queue = queue
        self.callObserver = CXCallObserver()
        super.init()
    }

    open func request(
        _ transaction: CXTransaction,
        completion: @escaping ((any Error)?) -> Void
    ) {
        queue.async {
            guard let provider = CXCallKitRuntime.activeProvider() else {
                completion(CXErrorCodeRequestTransactionError(.unknownCallProvider))
                return
            }
            provider.submit(transaction, completion: completion)
        }
    }

    open func request(_ transaction: CXTransaction) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.request(transaction) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    open func requestTransaction(
        with action: CXAction,
        completion: @escaping ((any Error)?) -> Void
    ) {
        request(CXTransaction(action: action), completion: completion)
    }

    open func requestTransaction(with action: CXAction) async throws {
        try await request(CXTransaction(action: action))
    }

    open func requestTransaction(
        with actions: [CXAction],
        completion: @escaping ((any Error)?) -> Void
    ) {
        request(CXTransaction(actions: actions), completion: completion)
    }

    open func requestTransaction(with actions: [CXAction]) async throws {
        try await request(CXTransaction(actions: actions))
    }
}
