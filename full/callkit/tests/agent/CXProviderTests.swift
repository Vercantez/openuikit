@_spi(OpenUIKitHost) import CallKit
import Foundation

private final class FulfillingDelegate: NSObject, CXProviderDelegate {
    var began = false
    var reset = false
    var timedOut: CXAction?
    var executeHandler: ((CXTransaction) -> Bool)?
    var onStart: ((CXStartCallAction) -> Void)?
    var onAnswer: ((CXAnswerCallAction) -> Void)?
    var onEnd: ((CXEndCallAction) -> Void)?
    var onHold: ((CXSetHeldCallAction) -> Void)?
    var onMute: ((CXSetMutedCallAction) -> Void)?
    var onGroup: ((CXSetGroupCallAction) -> Void)?
    var onDTMF: ((CXPlayDTMFCallAction) -> Void)?
    var onTranslate: ((CXSetTranslatingCallAction) -> Void)?

    func providerDidReset(_ provider: CXProvider) {
        _ = provider
        reset = true
    }

    func providerDidBegin(_ provider: CXProvider) {
        _ = provider
        began = true
    }

    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
        _ = provider
        return executeHandler?(transaction) ?? false
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        _ = provider
        if let onStart { onStart(action) } else { action.fulfill() }
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        _ = provider
        if let onAnswer { onAnswer(action) } else { action.fulfill() }
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        _ = provider
        if let onEnd { onEnd(action) } else { action.fulfill() }
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        _ = provider
        if let onHold { onHold(action) } else { action.fulfill() }
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        _ = provider
        if let onMute { onMute(action) } else { action.fulfill() }
    }

    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        _ = provider
        if let onGroup { onGroup(action) } else { action.fulfill() }
    }

    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        _ = provider
        if let onDTMF { onDTMF(action) } else { action.fulfill() }
    }

    func provider(_ provider: CXProvider, perform action: CXSetTranslatingCallAction) {
        _ = provider
        if let onTranslate { onTranslate(action) } else { action.fulfill(using: .default) }
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        _ = provider
        timedOut = action
    }
}

private func request(_ controller: CXCallController, _ transaction: CXTransaction) -> (any Error)? {
    var result: (any Error)?
    var count = 0
    controller.requestTransaction(transaction) { error in
        result = error
        count += 1
    }
    precondition(count == 1, "request completion must run inline")
    return result
}

private func reportIncoming(_ provider: CXProvider, uuid: UUID, update: CXCallUpdate) -> (any Error)? {
    var result: (any Error)?
    var count = 0
    provider.reportNewIncomingCall(uuid: uuid, update: update) { error in
        result = error
        count += 1
    }
    precondition(count == 1, "incoming completion must run inline")
    return result
}

func testCXProviderInitSetDelegateAndDidBegin() {
    CallKitHostControl.resetRegistry()
    let provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "P"))
    let delegate = FulfillingDelegate()
    provider.setDelegate(delegate, queue: nil)
    precondition(delegate.began)
    precondition(type(of: provider) == CXProvider.self)
    precondition(provider.configuration.localizedName == "P")
}

func testCXProviderReportIncomingAnswerHoldMuteDTMFTranslateEnd() {
    CallKitHostControl.resetRegistry()
    let configuration = CXProviderConfiguration()
    configuration.maximumCallGroups = 4
    let provider = CXProvider(configuration: configuration)
    let delegate = FulfillingDelegate()
    delegate.onTranslate = { $0.fulfill(using: .custom) }
    provider.setDelegate(delegate, queue: nil)
    let controller = CXCallController()
    let uuid = UUID()
    let update = CXCallUpdate()
    update.localizedCallerName = "Ada"
    update.remoteHandle = CXHandle(type: .phoneNumber, value: "+1")
    update.hasVideo = true
    precondition(reportIncoming(provider, uuid: uuid, update: update) == nil)
    let calls = controller.callObserver.calls
    precondition(calls.contains(where: { $0.uuid == uuid && !$0.isOutgoing && !$0.hasConnected }))

    precondition(request(controller, CXTransaction(action: CXAnswerCallAction(callUUID: uuid))) == nil)
    precondition(controller.callObserver.calls.contains(where: { $0.uuid == uuid && $0.hasConnected }))

    precondition(request(controller, CXTransaction(action: CXSetHeldCallAction(callUUID: uuid, onHold: true))) == nil)
    precondition(controller.callObserver.calls.contains(where: { $0.uuid == uuid && $0.isOnHold }))

    precondition(request(controller, CXTransaction(action: CXSetMutedCallAction(callUUID: uuid, muted: true))) == nil)
    precondition(CallKitHostControl.isMuted(uuid))

    let dtmf = CXPlayDTMFCallAction(callUUID: uuid, digits: "9", type: .singleTone)
    precondition(request(controller, CXTransaction(action: dtmf)) == nil)

    let translating = CXSetTranslatingCallAction(
        callUUID: uuid,
        isTranslating: true,
        localLanguage: "en",
        remoteLanguage: "es"
    )
    precondition(request(controller, CXTransaction(action: translating)) == nil)
    precondition(CallKitHostControl.translationEngine(for: uuid) == .custom)

    provider.reportCall(with: uuid, updated: update)
    provider.reportCall(with: uuid, endedAt: Date(), reason: .remoteEnded)
    precondition(controller.callObserver.calls.allSatisfy { $0.uuid != uuid })
}

func testCXProviderDuplicateIncomingAndPendingActions() {
    CallKitHostControl.resetRegistry()
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let delegate = FulfillingDelegate()
    provider.setDelegate(delegate, queue: nil)
    let uuid = UUID()
    precondition(reportIncoming(provider, uuid: uuid, update: CXCallUpdate()) == nil)
    var duplicate: (any Error)?
    provider.reportNewIncomingCall(uuid: uuid, update: CXCallUpdate()) { error in
        duplicate = error
    }
    precondition(CXErrorCodeIncomingCallError.callUUIDAlreadyExists ~= duplicate!)
    precondition(provider.pendingCallActions(of: CXEndCallAction.self, withCall: uuid).isEmpty)
    precondition(provider.pendingTransactions.isEmpty)
}

func testCXProviderExecuteTransactionShortCircuit() {
    CallKitHostControl.resetRegistry()
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let delegate = FulfillingDelegate()
    var performCount = 0
    delegate.executeHandler = { transaction in
        transaction.actions.forEach { $0.fulfill() }
        return true
    }
    delegate.onStart = { action in
        performCount += 1
        action.fulfill()
    }
    provider.setDelegate(delegate, queue: nil)
    let controller = CXCallController()
    let uuid = UUID()
    precondition(
        request(
            controller,
            CXTransaction(action: CXStartCallAction(callUUID: uuid, handle: CXHandle(type: .generic, value: "e")))
        ) == nil
    )
    precondition(performCount == 0)
    precondition(controller.callObserver.calls.contains(where: { $0.uuid == uuid }))
}

func testCXProviderInvalidateResets() {
    CallKitHostControl.resetRegistry()
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let delegate = FulfillingDelegate()
    provider.setDelegate(delegate, queue: nil)
    provider.invalidate()
    precondition(delegate.reset)
}

func testCXProviderOutgoingConnectingAndConnected() {
    CallKitHostControl.resetRegistry()
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let delegate = FulfillingDelegate()
    provider.setDelegate(delegate, queue: nil)
    let controller = CXCallController()
    let uuid = UUID()
    precondition(
        request(
            controller,
            CXTransaction(action: CXStartCallAction(callUUID: uuid, handle: CXHandle(type: .generic, value: "out")))
        ) == nil
    )
    provider.reportOutgoingCall(with: uuid, startedConnectingAt: Date())
    provider.reportOutgoingCall(with: uuid, connectedAt: Date())
    precondition(controller.callObserver.calls.contains(where: { $0.uuid == uuid && $0.isOutgoing && $0.hasConnected }))
}

func testCXProviderTimedOutPerformingAction() {
    CallKitHostControl.resetRegistry()
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let delegate = FulfillingDelegate()
    var startPerformed = false
    delegate.onStart = { action in
        startPerformed = true
        action.fulfill()
    }
    provider.setDelegate(delegate, queue: nil)
    let controller = CXCallController()
    let action = CXStartCallAction(callUUID: UUID(), handle: CXHandle(type: .generic, value: "late"))
    CallKitHostControl.setTimeoutDate(action, Date.distantPast)
    let error = request(controller, CXTransaction(action: action))
    precondition(error != nil)
    precondition(delegate.timedOut === action)
    precondition(!startPerformed)
    CallKitHostControl.notifyTimeout(provider, action: CXAction())
    precondition(delegate.timedOut != nil)
}

func testCXProviderVoIPPushPayloadFailClosed() {
    var count = 0
    var error: (any Error)?
    CXProvider.reportNewIncomingVoIPPushPayload(["aps": "x"]) { received in
        count += 1
        error = received
    }
    precondition(count == 1)
    precondition(CXErrorCodeNotificationServiceExtensionError.invalidClientProcess ~= error!)
}

func testCXProviderDelegateProtocolIdentity() {
    let delegate: any CXProviderDelegate = FulfillingDelegate()
    _ = delegate
}
