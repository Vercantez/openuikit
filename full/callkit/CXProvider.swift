import Foundation
@preconcurrency import Dispatch
#if canImport(AVFoundation)
import AVFoundation
#endif

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
#if canImport(AVFoundation)
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession)
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession)
#endif
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

#if canImport(AVFoundation)
    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        _ = provider
        _ = audioSession
    }

    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        _ = provider
        _ = audioSession
    }
#endif
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

    /// Linux has no Notification Service Extension or PushKit VoIP host.
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

#if canImport(AVFoundation)
    /// Host SPI: deliver a real `AVFoundation.AVAudioSession` to the provider
    /// delegate. This does not activate Apple audio I/O.
    @_spi(OpenUIKitHost)
    public func _portableDeliverAudioSessionActivation(_ session: AVAudioSession) {
        performOnDelegateQueue {
            self.delegate?.provider(self, didActivate: session)
        }
    }

    @_spi(OpenUIKitHost)
    public func _portableDeliverAudioSessionDeactivation(_ session: AVAudioSession) {
        performOnDelegateQueue {
            self.delegate?.provider(self, didDeactivate: session)
        }
    }
#endif

    func accept(_ actions: [CXAction], as transaction: CXTransaction) {
        for action in actions {
            action.portableProvider = self
        }
        stateLock.lock()
        pending.append(transaction)
        stateLock.unlock()
    }

    func deliver(_ actions: [CXAction], as transaction: CXTransaction) {
        performOnDelegateQueue {
            guard self.isValid else { return }
            if self.delegate?.provider(self, execute: transaction) == true {
                return
            }
            for action in actions {
                self.dispatch(action)
            }
        }
    }

    func portableActionDidComplete(_ action: CXAction, success: Bool) {
        guard success else { return }
        switch action {
        case let start as CXStartCallAction:
            _ = CXCallKitRuntime.markOutgoingStarted(uuid: start.callUUID, provider: self)
        case let answer as CXAnswerCallAction:
            CXCallKitRuntime.markAnswered(uuid: answer.callUUID)
        case let end as CXEndCallAction:
            CXCallKitRuntime.endCall(uuid: end.callUUID)
        case let held as CXSetHeldCallAction:
            CXCallKitRuntime.setHeld(uuid: held.callUUID, onHold: held.isOnHold)
        case let group as CXSetGroupCallAction:
            _ = CXCallKitRuntime.group(uuid: group.callUUID, with: group.callUUIDToGroupWith)
        default:
            break
        }
    }

    private var isValid: Bool {
        stateLock.lock()
        let value = valid
        stateLock.unlock()
        return value
    }

    private func dispatch(_ action: CXAction) {
        let delegate = self.delegate
        switch action {
        case let start as CXStartCallAction:
            delegate?.provider(self, perform: start)
        case let answer as CXAnswerCallAction:
            delegate?.provider(self, perform: answer)
        case let end as CXEndCallAction:
            delegate?.provider(self, perform: end)
        case let held as CXSetHeldCallAction:
            delegate?.provider(self, perform: held)
        case let muted as CXSetMutedCallAction:
            delegate?.provider(self, perform: muted)
        case let group as CXSetGroupCallAction:
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
        let toFail = pending.flatMap(\.actions).filter { action in
            guard let callAction = action as? CXCallAction else { return false }
            return callAction.callUUID == uuid && !callAction.isComplete
        }
        stateLock.unlock()
        for action in toFail {
            action.fail()
        }
        stateLock.lock()
        pending.removeAll { $0.isComplete }
        stateLock.unlock()
    }

    private func performOnDelegateQueue(_ body: @escaping () -> Void) {
        stateLock.lock()
        let queue = CXCallKitCallbackQueue(delegateQueue)
        stateLock.unlock()
        queue.async {
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
            switch CXCallKitRuntime.plan(transaction) {
            case .failure(let error):
                for action in transaction.actions {
                    action.portableReject()
                }
                completion(error)
            case .success(let assignments):
                var wrapped: [(CXProvider, [CXAction], CXTransaction)] = []
                for (provider, actions) in assignments {
                    let slice = CXTransaction(actions: actions)
                    provider.accept(actions, as: slice)
                    wrapped.append((provider, actions, slice))
                }
                completion(nil)
                for (provider, actions, slice) in wrapped {
                    provider.deliver(actions, as: slice)
                }
            }
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
