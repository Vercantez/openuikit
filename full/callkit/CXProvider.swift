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
    public func providerDidBegin(_ provider: CXProvider) {}
    public func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool { false }
    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) { action.fail() }
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) { action.fail() }
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) { action.fail() }
    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) { action.fail() }
    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) { action.fail() }
    public func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) { action.fail() }
    public func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) { action.fail() }
    public func provider(_ provider: CXProvider, perform action: CXSetTranslatingCallAction) { action.fail() }
    public func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {}
}

open class CXProviderConfiguration: NSObject, NSCopying, @unchecked Sendable {
    public private(set) var localizedName: String?
    public var ringtoneSound: String?
    public var iconTemplateImageData: Data?
    /// Documented Apple default: 2 call groups.
    public var maximumCallGroups: Int = 2
    /// Documented Apple default: 5 calls per group.
    public var maximumCallsPerCallGroup: Int = 5
    public var supportsVideo = false
    public var includesCallsInRecents = true
    public var supportsAudioTranslation = false
    @nonobjc public var supportedHandleTypes: Set<CXHandle.HandleType> = []

    public override init() {
        super.init()
    }

    public convenience init(localizedName: String) {
        self.init()
        self.localizedName = localizedName
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = CXProviderConfiguration()
        copy.localizedName = localizedName
        copy.ringtoneSound = ringtoneSound
        copy.iconTemplateImageData = iconTemplateImageData
        copy.maximumCallGroups = maximumCallGroups
        copy.maximumCallsPerCallGroup = maximumCallsPerCallGroup
        copy.supportsVideo = supportsVideo
        copy.includesCallsInRecents = includesCallsInRecents
        copy.supportsAudioTranslation = supportsAudioTranslation
        copy.supportedHandleTypes = supportedHandleTypes
        return copy
    }
}

open class CXProvider: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var storedConfiguration: CXProviderConfiguration
    private weak var delegate: CXProviderDelegate?
    private var callbackQueue: DispatchQueue
    private var invalidated = false
    let hostQueue: DispatchQueue

    public var configuration: CXProviderConfiguration {
        get {
            lock.lock()
            defer { lock.unlock() }
            return (storedConfiguration.copy() as? CXProviderConfiguration) ?? storedConfiguration
        }
        set {
            lock.lock()
            storedConfiguration = (newValue.copy() as? CXProviderConfiguration) ?? newValue
            lock.unlock()
        }
    }

    public var pendingTransactions: [CXTransaction] {
        CallKitRegistry.shared.pendingTransactions(for: self)
    }

    public init(configuration: CXProviderConfiguration) {
        self.storedConfiguration = (configuration.copy() as? CXProviderConfiguration) ?? configuration
        let queue = DispatchQueue(label: "CallKit.CXProvider.\(UUID().uuidString)", qos: .userInitiated)
        self.hostQueue = queue
        self.callbackQueue = queue
        super.init()
        CallKitRegistry.shared.registerProvider(self)
    }

    public func setDelegate(_ delegate: (any CXProviderDelegate)?, queue: DispatchQueue?) {
        lock.lock()
        self.delegate = delegate
        self.callbackQueue = queue ?? hostQueue
        let hopQueue = self.callbackQueue
        let begin = delegate
        let alreadyInvalid = invalidated
        lock.unlock()
        if let begin, !alreadyInvalid {
            callKitHop(hopQueue) { [weak self] in
                guard let self else { return }
                begin.providerDidBegin(self)
            }
        }
    }

    private func hopQueue() -> DispatchQueue {
        lock.lock()
        defer { lock.unlock() }
        return callbackQueue
    }

    public func invalidate() {
        lock.lock()
        invalidated = true
        let delegate = self.delegate
        lock.unlock()
        let result = CallKitRegistry.shared.invalidateProvider(self)
        for item in result.pending {
            for action in item.transaction.actions where !action.isComplete {
                action.fail()
            }
            CallKitRegistry.shared.finishPending(
                transactionUUID: item.transaction.uuid,
                error: CXError(.unentitled)
            )
        }
        for record in result.calls {
            CallKitRegistry.shared.notifyObservers(callUUID: record.uuid)
        }
        if let delegate {
            callKitHop(hopQueue()) { [weak self] in
                guard let self else { return }
                delegate.providerDidReset(self)
            }
        }
    }

    public func pendingCallActions(of callActionClass: AnyClass, withCall callUUID: UUID) -> [CXCallAction] {
        CallKitRegistry.shared.pendingCallActions(of: callActionClass, callUUID: callUUID, provider: self)
    }

    @_spi(OpenUIKitHost)
    public func reportNewIncomingCall(
        uuid: UUID,
        update: CXCallUpdate,
        completion: @escaping (Error?) -> Void
    ) {
        let once = CallKitOnceFlag()
        func finish(_ error: Error?) {
            guard once.take() else { return }
            callKitHop(hopQueue()) {
                completion(error)
            }
        }
        lock.lock()
        let dead = invalidated
        lock.unlock()
        if dead {
            finish(CXErrorCodeIncomingCallError(.unentitled))
            return
        }
        switch CallKitRegistry.shared.applyIncoming(uuid: uuid, provider: self, update: update) {
        case .success:
            CallKitRegistry.shared.notifyObservers(callUUID: uuid)
            finish(nil)
        case .failure(let error):
            finish(error)
        }
    }

    public func reportNewIncomingCall(with UUID: UUID, update: CXCallUpdate) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.reportNewIncomingCall(uuid: UUID, update: update) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func reportCall(with UUID: UUID, updated update: CXCallUpdate) {
        _ = CallKitRegistry.shared.applyUpdate(UUID, update)
        CallKitRegistry.shared.notifyObservers(callUUID: UUID)
    }

    public func reportCall(with UUID: UUID, endedAt dateEnded: Date?, reason endedReason: CXCallEndedReason) {
        _ = CallKitRegistry.shared.applyEndedReport(uuid: UUID, endedAt: dateEnded, reason: endedReason)
        CallKitRegistry.shared.notifyObservers(callUUID: UUID)
    }

    public func reportOutgoingCall(with UUID: UUID, startedConnectingAt dateStartedConnecting: Date?) {
        _ = CallKitRegistry.shared.applyOutgoingStartedConnecting(uuid: UUID, at: dateStartedConnecting)
        CallKitRegistry.shared.notifyObservers(callUUID: UUID)
    }

    public func reportOutgoingCall(with UUID: UUID, connectedAt dateConnected: Date?) {
        _ = CallKitRegistry.shared.applyOutgoingConnected(uuid: UUID, at: dateConnected)
        CallKitRegistry.shared.notifyObservers(callUUID: UUID)
    }

    public class func reportNewIncomingVoIPPushPayload(
        _ dictionaryPayload: [AnyHashable: Any]
    ) async throws {
        _ = dictionaryPayload
        throw CXErrorCodeNotificationServiceExtensionError(.invalidClientProcess)
    }

    func perform(transaction: CXTransaction, completion: @escaping (Error?) -> Void, controllerQueue: DispatchQueue) {
        lock.lock()
        let delegate = self.delegate
        let dead = invalidated
        lock.unlock()
        if dead {
            completion(CXError(.unentitled))
            return
        }
        for action in transaction.actions {
            action.owningProvider = self
            action.owningTransaction = transaction
        }
        let item = CallKitPendingTransaction(
            transaction: transaction,
            provider: self,
            reservedStartUUIDs: Set(
                transaction.actions.compactMap { ($0 as? CXStartCallAction)?.callUUID }
            ),
            completion: completion,
            controllerQueue: controllerQueue
        )
        CallKitRegistry.shared.storePending(item)
        callKitHop(hopQueue()) { [weak self] in
            guard let self else {
                CallKitRegistry.shared.finishPending(
                    transactionUUID: transaction.uuid,
                    error: CXErrorCodeRequestTransactionError(.unknownCallProvider)
                )
                return
            }
            guard let delegate else {
                for action in transaction.actions where !action.isComplete {
                    action.fail()
                }
                CallKitRegistry.shared.finishPending(
                    transactionUUID: transaction.uuid,
                    error: CXErrorCodeRequestTransactionError(.unknownCallProvider)
                )
                return
            }
            if delegate.provider(self, execute: transaction) {
                if transaction.isComplete {
                    return
                }
                return
            }
            for action in transaction.actions where !action.isComplete {
                self.dispatchPerform(action, delegate: delegate)
            }
        }
    }

    private func dispatchPerform(_ action: CXAction, delegate: CXProviderDelegate) {
        switch action {
        case let start as CXStartCallAction:
            delegate.provider(self, perform: start)
        case let answer as CXAnswerCallAction:
            delegate.provider(self, perform: answer)
        case let end as CXEndCallAction:
            delegate.provider(self, perform: end)
        case let held as CXSetHeldCallAction:
            delegate.provider(self, perform: held)
        case let muted as CXSetMutedCallAction:
            delegate.provider(self, perform: muted)
        case let group as CXSetGroupCallAction:
            delegate.provider(self, perform: group)
        case let dtmf as CXPlayDTMFCallAction:
            delegate.provider(self, perform: dtmf)
        case let translating as CXSetTranslatingCallAction:
            delegate.provider(self, perform: translating)
        default:
            action.fail()
        }
    }
}
