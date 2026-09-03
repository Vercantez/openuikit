@_spi(OpenUIKitHost) import CallKit
import Dispatch
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private func nsError(_ error: any Error) -> NSError {
    error as NSError
}

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0
    private var calls: [CXCall] = []

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback() {
        lock.lock()
        sawReturned = returned
        count += 1
        lock.unlock()
    }

    func noteCall(_ call: CXCall) {
        lock.lock()
        sawReturned = returned
        count += 1
        calls.append(call)
        lock.unlock()
    }

    func snapshot() -> (sawReturned: Bool, count: Int, calls: [CXCall]) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count, calls)
    }
}

private final class FulfillingDelegate: NSObject, CXProviderDelegate {
    var onStart: ((CXStartCallAction) -> Void)?
    var onAnswer: ((CXAnswerCallAction) -> Void)?
    var onEnd: ((CXEndCallAction) -> Void)?
    var onHold: ((CXSetHeldCallAction) -> Void)?
    var onMute: ((CXSetMutedCallAction) -> Void)?
    var onGroup: ((CXSetGroupCallAction) -> Void)?
    var onDTMF: ((CXPlayDTMFCallAction) -> Void)?
    var onTranslate: ((CXSetTranslatingCallAction) -> Void)?
    var onBegin: (() -> Void)?
    var onReset: (() -> Void)?
    var executeHandler: ((CXTransaction) -> Bool)?

    func providerDidReset(_ provider: CXProvider) {
        _ = provider
        onReset?()
    }

    func providerDidBegin(_ provider: CXProvider) {
        _ = provider
        onBegin?()
    }

    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
        _ = provider
        return executeHandler?(transaction) ?? false
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        _ = provider
        if let onStart {
            onStart(action)
        } else {
            action.fulfill()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        _ = provider
        if let onAnswer {
            onAnswer(action)
        } else {
            action.fulfill()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        _ = provider
        if let onEnd {
            onEnd(action)
        } else {
            action.fulfill()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        _ = provider
        if let onHold {
            onHold(action)
        } else {
            action.fulfill()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        _ = provider
        if let onMute {
            onMute(action)
        } else {
            action.fulfill()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        _ = provider
        if let onGroup {
            onGroup(action)
        } else {
            action.fulfill()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        _ = provider
        if let onDTMF {
            onDTMF(action)
        } else {
            action.fulfill()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetTranslatingCallAction) {
        _ = provider
        if let onTranslate {
            onTranslate(action)
        } else {
            action.fulfill(using: .default)
        }
    }
}

private final class ObserverProbe: NSObject, CXCallObserverDelegate {
    let state: LockedState

    init(state: LockedState) {
        self.state = state
    }

    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        _ = callObserver
        state.noteCall(call)
    }
}

private final class DirectoryDelegate: NSObject, CXCallDirectoryExtensionContextDelegate {
    let state: LockedState
    var lastError: (any Error)?

    init(state: LockedState) {
        self.state = state
    }

    func requestFailed(
        for extensionContext: CXCallDirectoryExtensionContext,
        withError error: any Error
    ) {
        _ = extensionContext
        lastError = error
        state.noteCallback()
    }
}

private final class CompletionQueueBlocker: @unchecked Sendable {
    private let occupied = DispatchSemaphore(value: 0)
    private let hold = DispatchSemaphore(value: 0)

    func occupy(_ enqueue: (@escaping @Sendable () -> Void) -> Void) {
        enqueue { [self] in
            occupied.signal()
            hold.wait()
        }
        waitEvent(occupied, "queue was not occupied")
    }

    func release() {
        hold.signal()
    }
}

private func waitRequest(
    _ controller: CXCallController,
    _ transaction: CXTransaction
) -> (any Error)? {
    let done = DispatchSemaphore(value: 0)
    var result: (any Error)?
    controller.requestTransaction(transaction) { error in
        result = error
        done.signal()
    }
    waitEvent(done, "request did not complete")
    return result
}

private func waitIncoming(_ provider: CXProvider, uuid: UUID, update: CXCallUpdate) -> (any Error)? {
    let done = DispatchSemaphore(value: 0)
    var result: (any Error)?
    provider.reportNewIncomingCall(uuid: uuid, update: update) { error in
        result = error
        done.signal()
    }
    waitEvent(done, "incoming report did not complete")
    return result
}

private func requireRequestError(_ error: (any Error)?, _ code: CXErrorCodeRequestTransactionError.Code) {
    guard let error else { fatalError("expected request error \(code)") }
    precondition(code ~= error, "expected \(code), got \(error)")
    let ns = nsError(error)
    precondition(ns.domain == CXErrorDomainRequestTransaction)
    precondition(ns.code == code.rawValue)
}

private func requireIncomingError(_ error: (any Error)?, _ code: CXErrorCodeIncomingCallError.Code) {
    guard let error else { fatalError("expected incoming error \(code)") }
    precondition(code ~= error, "expected \(code), got \(error)")
}

private func runCallKitRuntimeTests() {
CallKitHostControl.resetRegistry()

// MARK: - Constants and error overlay

precondition(CXErrorDomain == "CXErrorDomain")
precondition(CXErrorDomainIncomingCall == "CXErrorDomainIncomingCall")
precondition(CXErrorDomainRequestTransaction == "CXErrorDomainRequestTransaction")
precondition(CXErrorDomainCallDirectoryManager == "CXErrorDomainCallDirectoryManager")
precondition(CXErrorDomainNotificationServiceExtension == "CXErrorDomainNotificationServiceExtension")
precondition(CXError.errorDomain == CXErrorDomain)
precondition(CXError.unknownError.rawValue == 0)
precondition(CXError.unentitled.rawValue == 1)
precondition(CXError.invalidArgument.rawValue == 2)
precondition(CXError.missingVoIPBackgroundMode.rawValue == 3)
precondition(CXError.Code(rawValue: 2) == .invalidArgument)
precondition(CXError.Code(rawValue: 99) == nil)

let typed = CXError(.invalidArgument, userInfo: ["k": "v"])
precondition(typed.code == .invalidArgument)
precondition(typed.errorCode == 2)
precondition(typed.userInfo["k"] as? String == "v")
precondition(typed.errorUserInfo["k"] as? String == "v")
precondition(!typed.localizedDescription.isEmpty)
precondition(CXError.invalidArgument ~= typed)
precondition(CXError.invalidArgument ~= nsError(typed))
precondition(!(CXError.unentitled ~= typed))
precondition(typed == CXError(.invalidArgument, userInfo: ["k": "v"]))
precondition(typed != CXError(.unentitled))
var errorHasher = Hasher()
typed.hash(into: &errorHasher)
_ = typed.hashValue
_ = errorHasher.finalize()

let fresh = NSError(domain: CXErrorDomain, code: CXError.Code.unentitled.rawValue)
precondition(CXError.unentitled ~= fresh)
precondition((fresh as? CXError) == nil)

precondition(CXErrorCodeIncomingCallError.callUUIDAlreadyExists.rawValue == 2)
precondition(CXErrorCodeIncomingCallError.filteredByDoNotDisturb.rawValue == 3)
precondition(CXErrorCodeIncomingCallError.filteredByBlockList.rawValue == 4)
precondition(CXErrorCodeIncomingCallError.filteredDuringRestrictedSharingMode.rawValue == 5)
precondition(CXErrorCodeIncomingCallError.callIsProtected.rawValue == 6)
precondition(CXErrorCodeIncomingCallError.filteredBySensitiveParticipants.rawValue == 7)
precondition(CXErrorCodeIncomingCallError.unknown ~= CXErrorCodeIncomingCallError(.unknown))

precondition(CXErrorCodeRequestTransactionError.emptyTransaction.rawValue == 3)
precondition(CXErrorCodeRequestTransactionError.unknownCallUUID.rawValue == 4)
precondition(CXErrorCodeRequestTransactionError.unknownCallProvider.rawValue == 2)
precondition(CXErrorCodeRequestTransactionError.maximumCallGroupsReached.rawValue == 7)

precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound.rawValue == 1)
precondition(CXErrorCodeCallDirectoryManagerError.entriesOutOfOrder.rawValue == 3)
precondition(CXErrorCodeCallDirectoryManagerError.duplicateEntries.rawValue == 4)
precondition(CXErrorCodeCallDirectoryManagerError.unexpectedIncrementalRemoval.rawValue == 8)

precondition(CXErrorCodeNotificationServiceExtensionError.invalidClientProcess.rawValue == 1)
precondition(CXErrorCodeNotificationServiceExtensionError.missingNotificationFilteringEntitlement.rawValue == 2)

precondition(CXCallEndedReason.failed.rawValue == 1)
precondition(CXCallEndedReason.remoteEnded.rawValue == 2)
precondition(CXCallEndedReason.unanswered.rawValue == 3)
precondition(CXCallEndedReason.answeredElsewhere.rawValue == 4)
precondition(CXCallEndedReason.declinedElsewhere.rawValue == 5)
precondition(CXCallEndedReason.failed != .unanswered)

precondition(CXHandle.HandleType.generic.rawValue == 1)
precondition(CXHandle.HandleType.phoneNumber.rawValue == 2)
precondition(CXHandle.HandleType.emailAddress.rawValue == 3)
precondition(CXPlayDTMFCallAction.ActionType.singleTone.rawValue == 1)
precondition(CXPlayDTMFCallAction.ActionType.softPause.rawValue == 2)
precondition(CXPlayDTMFCallAction.ActionType.hardPause.rawValue == 3)
precondition(CXTranslationEngine.default.rawValue == 0)
precondition(CXTranslationEngine.custom.rawValue == 1)
precondition(CXCallDirectoryManager.EnabledStatus.unknown.rawValue == 0)
precondition(CXCallDirectoryManager.EnabledStatus.disabled.rawValue == 1)
precondition(CXCallDirectoryManager.EnabledStatus.enabled.rawValue == 2)

precondition(CXCallDirectoryPhoneNumberMax == Int64.max)

let handle = CXHandle(type: .phoneNumber, value: "+15551212")
precondition(handle.type == .phoneNumber)
precondition(handle.value == "+15551212")
let handleCopy = handle.copy() as! CXHandle
precondition(handle.isEqual(handleCopy))
precondition(handle.hash == handleCopy.hash)

let update = CXCallUpdate()
update.remoteHandle = handle
update.localizedCallerName = "Ada"
update.hasVideo = true
update.supportsDTMF = false
let updateCopy = update.copy() as! CXCallUpdate
precondition(updateCopy.localizedCallerName == "Ada")
precondition(updateCopy.hasVideo)
precondition(updateCopy.remoteHandle?.value == "+15551212")

let configuration = CXProviderConfiguration(localizedName: "OpenUIKit")
precondition(configuration.localizedName == "OpenUIKit")
precondition(configuration.maximumCallGroups == 2)
precondition(configuration.maximumCallsPerCallGroup == 5)
precondition(!configuration.supportsVideo)
configuration.supportsVideo = true
configuration.supportedHandleTypes = [.phoneNumber, .generic]
configuration.ringtoneSound = "tone.caf"
configuration.includesCallsInRecents = false
configuration.supportsAudioTranslation = true
let configCopy = configuration.copy() as! CXProviderConfiguration
precondition(configCopy.localizedName == "OpenUIKit")
precondition(configCopy.supportsVideo)
precondition(configCopy.supportedHandleTypes.contains(.phoneNumber))

// MARK: - Incoming call, observer hop, answer/hold/mute/end

let provider = CXProvider(configuration: configuration)
let delegate = FulfillingDelegate()
let beginState = LockedState()
delegate.onBegin = { beginState.noteCallback() }
provider.setDelegate(delegate, queue: nil)
let beginDone = DispatchSemaphore(value: 0)
CallKitHostControl.enqueueOnProvider(provider) {
    beginDone.signal()
}
waitEvent(beginDone, "providerDidBegin hop")
precondition(beginState.snapshot().count == 1)

let controller = CXCallController()
let observerState = LockedState()
let observerProbe = ObserverProbe(state: observerState)
controller.callObserver.setDelegate(observerProbe, queue: nil)

let incomingUUID = UUID()
observerState.markReturned()
let incomingError = waitIncoming(provider, uuid: incomingUUID, update: update)
precondition(incomingError == nil, "incoming should register process-locally")
precondition(observerState.snapshot().count >= 1)
precondition(observerState.snapshot().sawReturned, "observer callback must hop, not run inline")
let incomingCalls = controller.callObserver.calls
precondition(incomingCalls.contains(where: { $0.uuid == incomingUUID && !$0.isOutgoing && !$0.hasConnected }))

let answer = CXAnswerCallAction(callUUID: incomingUUID)
precondition(waitRequest(controller, CXTransaction(action: answer)) == nil)
precondition(controller.callObserver.calls.contains(where: { $0.uuid == incomingUUID && $0.hasConnected }))

let held = CXSetHeldCallAction(callUUID: incomingUUID, onHold: true)
precondition(waitRequest(controller, CXTransaction(action: held)) == nil)
precondition(controller.callObserver.calls.contains(where: { $0.uuid == incomingUUID && $0.isOnHold }))

let muted = CXSetMutedCallAction(callUUID: incomingUUID, muted: true)
precondition(waitRequest(controller, CXTransaction(action: muted)) == nil)
precondition(CallKitHostControl.isMuted(incomingUUID))

let dtmf = CXPlayDTMFCallAction(callUUID: incomingUUID, digits: "9", type: .singleTone)
precondition(dtmf.digits == "9")
precondition(waitRequest(controller, CXTransaction(action: dtmf)) == nil)

let translating = CXSetTranslatingCallAction(
    callUUID: incomingUUID,
    isTranslating: true,
    localLanguage: "en",
    remoteLanguage: "es"
)
precondition(translating.isTranslating)
precondition(translating.localLanguage == "en")
delegate.onTranslate = { action in
    action.fulfill(using: .custom)
}
precondition(waitRequest(controller, CXTransaction(action: translating)) == nil)
precondition(CallKitHostControl.translationEngine(for: incomingUUID) == .custom)

let pending = provider.pendingCallActions(of: CXEndCallAction.self, withCall: incomingUUID)
precondition(pending.isEmpty)

let end = CXEndCallAction(callUUID: incomingUUID)
precondition(waitRequest(controller, CXTransaction(action: end)) == nil)
precondition(controller.callObserver.calls.allSatisfy { $0.uuid != incomingUUID })

provider.reportCall(with: incomingUUID, endedAt: Date(), reason: .remoteEnded)

// MARK: - Empty / unknown / duplicate preflight is atomic

CallKitHostControl.resetRegistry()
let provider2 = CXProvider(configuration: CXProviderConfiguration())
let delegate2 = FulfillingDelegate()
provider2.setDelegate(delegate2, queue: nil)
let controller2 = CXCallController()

requireRequestError(
    waitRequest(controller2, CXTransaction(actions: [])),
    .emptyTransaction
)
requireRequestError(
    waitRequest(controller2, CXTransaction(action: CXEndCallAction(callUUID: UUID()))),
    .unknownCallUUID
)

let firstIncoming = UUID()
precondition(waitIncoming(provider2, uuid: firstIncoming, update: CXCallUpdate()) == nil)
requireIncomingError(
    waitIncoming(provider2, uuid: firstIncoming, update: CXCallUpdate()),
    .callUUIDAlreadyExists
)
precondition(waitRequest(controller2, CXTransaction(action: CXEndCallAction(callUUID: firstIncoming))) == nil)

let startA = CXStartCallAction(
    callUUID: UUID(),
    handle: CXHandle(type: .generic, value: "a")
)
let startDup = CXStartCallAction(
    callUUID: startA.callUUID,
    handle: CXHandle(type: .generic, value: "b")
)
requireRequestError(
    waitRequest(controller2, CXTransaction(actions: [startA, startDup])),
    .callUUIDAlreadyExists
)
precondition(
    !controller2.callObserver.calls.contains(where: { $0.uuid == startA.callUUID }),
    "rejected start pair must not mutate"
)

// MARK: - Start, group, max groups

let out1 = UUID()
let out2 = UUID()
let start1 = CXStartCallAction(call: out1, handle: CXHandle(type: .emailAddress, value: "a@b.c"))
start1.isVideo = true
start1.contactIdentifier = "cid"
precondition(waitRequest(controller2, CXTransaction(action: start1)) == nil)
provider2.reportOutgoingCall(with: out1, startedConnectingAt: Date())
provider2.reportOutgoingCall(with: out1, connectedAt: Date())
precondition(controller2.callObserver.calls.contains(where: { $0.uuid == out1 && $0.isOutgoing && $0.hasConnected }))

let start2 = CXStartCallAction(callUUID: out2, handle: CXHandle(type: .generic, value: "b"))
precondition(waitRequest(controller2, CXTransaction(action: start2)) == nil)

let group = CXSetGroupCallAction(callUUID: out1, callUUIDToGroupWith: out2)
precondition(waitRequest(controller2, CXTransaction(action: group)) == nil)
precondition(CallKitHostControl.groupID(for: out1) == CallKitHostControl.groupID(for: out2))

let ungroup = CXSetGroupCallAction(call: out1, callUUIDToGroupWith: nil)
precondition(waitRequest(controller2, CXTransaction(action: ungroup)) == nil)

let out3 = UUID()
requireRequestError(
    waitRequest(
        controller2,
        CXTransaction(action: CXStartCallAction(callUUID: out3, handle: CXHandle(type: .generic, value: "c")))
    ),
    .maximumCallGroupsReached
)
precondition(!controller2.callObserver.calls.contains(where: { $0.uuid == out3 }))

// Unknown group target
let missingGroup = CXSetGroupCallAction(callUUID: out1, callUUIDToGroupWith: UUID())
requireRequestError(waitRequest(controller2, CXTransaction(action: missingGroup)), .unknownCallUUID)

// MARK: - Two providers: start must not use a last-provider pointer

CallKitHostControl.resetRegistry()
let pA = CXProvider(configuration: CXProviderConfiguration())
let pB = CXProvider(configuration: CXProviderConfiguration())
let dA = FulfillingDelegate()
let dB = FulfillingDelegate()
pA.setDelegate(dA, queue: nil)
pB.setDelegate(dB, queue: nil)
let twoController = CXCallController()
requireRequestError(
    waitRequest(
        twoController,
        CXTransaction(action: CXStartCallAction(callUUID: UUID(), handle: CXHandle(type: .generic, value: "x")))
    ),
    .unknownCallProvider
)

let owned = UUID()
precondition(waitIncoming(pA, uuid: owned, update: CXCallUpdate()) == nil)
precondition(waitRequest(twoController, CXTransaction(action: CXAnswerCallAction(call: owned))) == nil)
precondition(twoController.callObserver.calls.contains(where: { $0.uuid == owned && $0.hasConnected }))

// MARK: - Queue identity / non-reentrancy

CallKitHostControl.resetRegistry()
let queuedProvider = CXProvider(configuration: CXProviderConfiguration())
let queuedDelegate = FulfillingDelegate()
let performState = LockedState()
queuedDelegate.onStart = { action in
    performState.noteCallback()
    action.fulfill()
}
queuedProvider.setDelegate(queuedDelegate, queue: nil)
let queuedController = CXCallController()
let blocker = CompletionQueueBlocker()
blocker.occupy { body in
    CallKitHostControl.enqueueOnProvider(queuedProvider, body)
}
performState.markReturned()
let queuedStart = CXStartCallAction(callUUID: UUID(), handle: CXHandle(type: .generic, value: "q"))
let queuedDone = DispatchSemaphore(value: 0)
var queuedError: (any Error)?
queuedController.requestTransaction(CXTransaction(action: queuedStart)) { error in
    queuedError = error
    queuedDone.signal()
}
precondition(performState.snapshot().count == 0, "perform must not run while provider queue is occupied")
blocker.release()
waitEvent(queuedDone, "queued request did not complete")
precondition(queuedError == nil)
precondition(performState.snapshot().count == 1)
precondition(performState.snapshot().sawReturned, "perform must hop after request returns to the queue")

// MARK: - Invalidate resets

let resetState = LockedState()
queuedDelegate.onReset = { resetState.noteCallback() }
queuedProvider.invalidate()
let resetDone = DispatchSemaphore(value: 0)
CallKitHostControl.enqueueOnProvider(queuedProvider) {
    resetDone.signal()
}
waitEvent(resetDone, "invalidate hop")
precondition(resetState.snapshot().count == 1)

// MARK: - Call directory fail-closed + sequential store

let directory = CXCallDirectoryExtensionContext(incremental: true)
let dirState = LockedState()
let dirDelegate = DirectoryDelegate(state: dirState)
directory.delegate = dirDelegate
directory.addBlockingEntry(withNextSequentialPhoneNumber: 15551212)
directory.addBlockingEntry(withNextSequentialPhoneNumber: 15551212)
directory.addBlockingEntry(withNextSequentialPhoneNumber: 15559999)
precondition(directory.hostBlockingEntries() == [15551212, 15559999])
directory.addIdentificationEntry(withNextSequentialPhoneNumber: 15550001, label: "Bank")
precondition(directory.hostIdentificationEntries().first?.1 == "Bank")
directory.removeBlockingEntry(withPhoneNumber: 15551212)
precondition(directory.hostBlockingEntries() == [15559999])
directory.removeAllBlockingEntries()
directory.removeAllIdentificationEntries()
precondition(directory.hostBlockingEntries().isEmpty)
precondition(directory.isIncremental)

let completeDone = DispatchSemaphore(value: 0)
var completeFlag = true
directory.completeRequest { ok in
    completeFlag = ok
    completeDone.signal()
}
waitEvent(completeDone, "completeRequest")
precondition(!completeFlag)
precondition(dirState.snapshot().count == 1)
precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound ~= dirDelegate.lastError!)

let providerExt = CXCallDirectoryProvider()
providerExt.beginRequest(with: directory)

let settingsDone = DispatchSemaphore(value: 0)
var settingsError: (any Error)?
CXCallDirectoryManager.sharedInstance.openSettings { error in
    settingsError = error
    settingsDone.signal()
}
waitEvent(settingsDone, "openSettings")
precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound ~= settingsError!)

// MARK: - VoIP push fail-closed (no NSE host)

let pushDone = DispatchSemaphore(value: 0)
var pushError: (any Error)?
Task {
    do {
        try await CXProvider.reportNewIncomingVoIPPushPayload(["aps": "x"])
    } catch {
        pushError = error
    }
    pushDone.signal()
}
waitEvent(pushDone, "voip push")
precondition(CXErrorCodeNotificationServiceExtensionError.invalidClientProcess ~= pushError!)

let reloadDone = DispatchSemaphore(value: 0)
var reloadError: (any Error)?
Task {
    do {
        try await CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.example.spam")
    } catch {
        reloadError = error
    }
    reloadDone.signal()
}
waitEvent(reloadDone, "reloadExtension")
precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound ~= reloadError!)

let statusDone = DispatchSemaphore(value: 0)
var statusError: (any Error)?
Task {
    do {
        _ = try await CXCallDirectoryManager.sharedInstance.enabledStatusForExtension(withIdentifier: "com.example.spam")
    } catch {
        statusError = error
    }
    statusDone.signal()
}
waitEvent(statusDone, "enabledStatus")
precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound ~= statusError!)

// execute: returning true skips per-action defaults; fulfill inside execute
CallKitHostControl.resetRegistry()
let execProvider = CXProvider(configuration: CXProviderConfiguration())
let execDelegate = FulfillingDelegate()
execDelegate.executeHandler = { transaction in
    transaction.actions.forEach { $0.fulfill() }
    return true
}
var performCount = 0
execDelegate.onStart = { action in
    performCount += 1
    action.fulfill()
}
execProvider.setDelegate(execDelegate, queue: nil)
let execController = CXCallController()
let execUUID = UUID()
precondition(
    waitRequest(
        execController,
        CXTransaction(action: CXStartCallAction(callUUID: execUUID, handle: CXHandle(type: .generic, value: "e")))
    ) == nil
)
precondition(performCount == 0, "execute true must skip perform")
precondition(execController.callObserver.calls.contains(where: { $0.uuid == execUUID }))

// MARK: - Transaction addAction / completeness / NSCoding

let tx = CXTransaction(action: CXAction())
tx.addAction(CXAction())
precondition(tx.actions.count == 2)
precondition(!tx.isComplete)
tx.actions.forEach { $0.fulfill() }
precondition(tx.isComplete)

let coded = CXHandle(type: .emailAddress, value: "z@z.z")
let archiver = NSKeyedArchiver(requiringSecureCoding: true)
coded.encode(with: archiver)
let data = archiver.encodedData
do {
    let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
    unarchiver.requiresSecureCoding = true
    if let restored = CXHandle(coder: unarchiver) {
        precondition(restored.type == .emailAddress)
        precondition(restored.value == "z@z.z")
    }
} catch {
    _ = error
}

let action = CXAction()
precondition(!action.isComplete)
precondition(action.timeoutDate == Date.distantFuture)
action.fail()
precondition(action.isComplete)

CallKitHostControl.resetRegistry()
print("CALLKIT_AGENT_RUNTIME_OK")
}

runCallKitRuntimeTests()
