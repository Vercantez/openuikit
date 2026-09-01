import Foundation
@preconcurrency import Dispatch
@_spi(OpenUIKitHost) import CallKit

private final class QueueProbe {
    let key = DispatchSpecificKey<String>()
    let queue: DispatchQueue
    let name: String

    init(_ name: String) {
        self.name = name
        self.queue = DispatchQueue(label: name)
        queue.setSpecific(key: key, value: name)
    }

    func assertCurrent(_ message: String) {
        if DispatchQueue.getSpecific(key: key) != name {
            fatalError(message)
        }
    }
}

private final class TestProviderDelegate: NSObject, CXProviderDelegate, @unchecked Sendable {
    let probe: QueueProbe?
    var began = 0
    var reset = 0
    var started: [UUID] = []
    var answered: [UUID] = []
    var ended: [UUID] = []
    var held: [Bool] = []
    var muted: [Bool] = []
    var grouped: [UUID?] = []
    var dtmf: [String] = []
    var translating = 0
    var performDepth = 0
    var maxPerformDepth = 0
    var nestedMutedDuringAnswer = 0
    var onAnswer: (() -> Void)?
    var onStart: (() -> Void)?
    var onEnd: (() -> Void)?
    var onMute: (() -> Void)?
    var onGroup: (() -> Void)?
    var onBegin: (() -> Void)?
    var onReset: (() -> Void)?
    var reentrantController: CXCallController?
    var reentrantMute: CXSetMutedCallAction?

    init(probe: QueueProbe? = nil) {
        self.probe = probe
    }

    private func enterPerform() {
        probe?.assertCurrent("provider delegate ran off its queue")
        performDepth += 1
        maxPerformDepth = max(maxPerformDepth, performDepth)
    }

    private func leavePerform() {
        performDepth -= 1
    }

    func providerDidReset(_ provider: CXProvider) {
        _ = provider
        probe?.assertCurrent("providerDidReset off queue")
        reset += 1
        onReset?()
    }

    func providerDidBegin(_ provider: CXProvider) {
        _ = provider
        probe?.assertCurrent("providerDidBegin off queue")
        began += 1
        onBegin?()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        _ = provider
        enterPerform()
        started.append(action.callUUID)
        onStart?()
        action.fulfill(withDateStarted: Date())
        leavePerform()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        _ = provider
        enterPerform()
        answered.append(action.callUUID)
        if let controller = reentrantController, let mute = reentrantMute {
            controller.requestTransaction(with: mute) { _ in }
            nestedMutedDuringAnswer = muted.count
        }
        onAnswer?()
        action.fulfill(withDateConnected: Date())
        leavePerform()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        _ = provider
        enterPerform()
        ended.append(action.callUUID)
        onEnd?()
        action.fulfill(withDateEnded: Date())
        leavePerform()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        _ = provider
        enterPerform()
        held.append(action.isOnHold)
        action.fulfill()
        leavePerform()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        _ = provider
        enterPerform()
        muted.append(action.isMuted)
        onMute?()
        action.fulfill()
        leavePerform()
    }

    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        _ = provider
        enterPerform()
        grouped.append(action.callUUIDToGroupWith)
        onGroup?()
        action.fulfill()
        leavePerform()
    }

    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        _ = provider
        enterPerform()
        dtmf.append(action.digits)
        action.fulfill()
        leavePerform()
    }

    func provider(_ provider: CXProvider, perform action: CXSetTranslatingCallAction) {
        _ = provider
        enterPerform()
        action.fulfill(using: .default)
        translating += 1
        leavePerform()
    }
}

private final class TestObserverDelegate: NSObject, CXCallObserverDelegate, @unchecked Sendable {
    let probe: QueueProbe?
    var changes: [CXCall] = []
    var onChange: (() -> Void)?

    init(probe: QueueProbe? = nil) {
        self.probe = probe
    }

    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        _ = callObserver
        probe?.assertCurrent("observer callback off queue")
        changes.append(call)
        onChange?()
    }
}

private final class DirectoryDelegate: NSObject, CXCallDirectoryExtensionContextDelegate {
    var errors: [any Error] = []

    func requestFailed(
        for extensionContext: CXCallDirectoryExtensionContext,
        withError error: any Error
    ) {
        _ = extensionContext
        errors.append(error)
    }
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

private func wait(_ semaphore: DispatchSemaphore, _ message: String) {
    if semaphore.wait(timeout: .now() + 5) == .timedOut {
        fatalError(message)
    }
}

private func requireRequestError(_ error: any Error, _ code: CXErrorCodeRequestTransactionError.Code) {
    guard let typed = error as? CXErrorCodeRequestTransactionError else {
        fatalError("expected CXErrorCodeRequestTransactionError, got \(error)")
    }
    require(typed.code == code, "unexpected request error \(typed.code)")
    require(typed.errorCode == code.rawValue, "errorCode mismatch")
    require(
        CXErrorCodeRequestTransactionError.errorDomain == CXErrorDomainRequestTransaction,
        "request domain mismatch"
    )
}

private func request(
    _ controller: CXCallController,
    _ transaction: CXTransaction
) -> (any Error)? {
    let done = DispatchSemaphore(value: 0)
    var captured: (any Error)?
    controller.request(transaction) { error in
        captured = error
        done.signal()
    }
    wait(done, "request completion timed out")
    return captured
}

enum CallKitRuntime {
    static func run() {
        exerciseErrors()
        exerciseHandlesAndUpdates()
        exerciseQueueIdentityAndNonReentrancy()
        exerciseOwnershipRouting()
        exerciseAtomicPreflight()
        exercisePendingReportsAndLimits()
        exerciseFailClosedBoundaries()
        exerciseCallDirectory()
        exerciseCoding()
        print("CALLKIT_AGENT_RUNTIME_OK")
    }

    private static func exerciseErrors() {
        require(CXError.errorDomain == CXErrorDomain, "CXError domain identity")
        require(CXError.unentitled.rawValue == 1, "CXError.unentitled")
        require(CXError.invalidArgument.rawValue == 2, "CXError.invalidArgument")
        require(CXError.unknownError.rawValue == 0, "CXError.unknownError")
        require(CXError.missingVoIPBackgroundMode.rawValue == 3, "CXError.missingVoIPBackgroundMode")
        let entitled = CXError(.unentitled, userInfo: ["k": "v"])
        require(entitled.code == .unentitled, "CXError.code")
        require(entitled != CXError(.unknownError), "CXError !=")
        require(entitled == CXError(.unentitled, userInfo: ["k": "v"]), "CXError ==")
        require(CXError.Code.unentitled ~= entitled, "CXError ~=")
        _ = entitled.hashValue
        _ = entitled.localizedDescription
        _ = entitled.errorUserInfo

        require(CXErrorCodeIncomingCallError.callUUIDAlreadyExists.rawValue == 2, "incoming exists")
        require(CXErrorCodeRequestTransactionError.emptyTransaction.rawValue == 3, "empty txn")
        require(CXErrorCodeCallDirectoryManagerError.noExtensionFound.rawValue == 1, "no extension")
        require(
            CXErrorCodeNotificationServiceExtensionError.invalidClientProcess.rawValue == 1,
            "nse"
        )
        require(CXErrorCodeIncomingCallError.unknown != .unentitled, "incoming !=")
        require(CXCallEndedReason.failed != .remoteEnded, "ended !=")
        require(CXHandle.HandleType.generic != .emailAddress, "handle !=")
        require(CXPlayDTMFCallAction.ActionType.singleTone != .hardPause, "dtmf !=")
        require(CXTranslationEngine.default != .custom, "engine !=")
        require(
            CXCallDirectoryManager.EnabledStatus.unknown
                != CXCallDirectoryManager.EnabledStatus.enabled,
            "enabled !="
        )
        _ = CXCallEndedReason.failed.hashValue
        _ = CXHandle.HandleType.phoneNumber.hashValue
        require(CXHandle.HandleType(rawValue: 2) == .phoneNumber, "handle raw")
        require(CXCallEndedReason(rawValue: 4) == .answeredElsewhere, "ended raw")
        require(CXPlayDTMFCallAction.ActionType(rawValue: 3) == .hardPause, "dtmf raw")
        require(CXCallDirectoryManager.EnabledStatus(rawValue: 1) == .disabled, "status raw")
        require(CXError.Code(rawValue: 1) == .unentitled, "CXError raw")
        _ = CXErrorCodeIncomingCallError(.filteredByDoNotDisturb).localizedDescription
        _ = CXErrorCodeRequestTransactionError(.invalidAction).hashValue
        _ = CXErrorCodeCallDirectoryManagerError(.duplicateEntries).errorUserInfo
        _ = CXErrorCodeNotificationServiceExtensionError(
            .missingNotificationFilteringEntitlement
        ).localizedDescription
        _ = CXCallDirectoryPhoneNumberMax
        _ = CXTranslationEngine(rawValue: CXTranslationEngine.default.rawValue)
    }

    private static func exerciseHandlesAndUpdates() {
        let handle = CXHandle(type: .phoneNumber, value: "+15551212")
        require(handle.type == .phoneNumber && handle.value == "+15551212", "handle fields")
        let copied = handle.copy() as! CXHandle
        require(copied == handle && copied !== handle, "handle copy")

        let update = CXCallUpdate()
        update.remoteHandle = handle
        update.localizedCallerName = "Ada"
        update.hasVideo = true
        update.supportsDTMF = false
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        let updateCopy = update.copy() as! CXCallUpdate
        require(updateCopy.localizedCallerName == "Ada", "update copy name")
        require(updateCopy.hasVideo && !updateCopy.supportsDTMF, "update flags")

        let configuration = CXProviderConfiguration(localizedName: "OpenPhone")
        require(configuration.localizedName == "OpenPhone", "localizedName")
        require(configuration.maximumCallGroups == 2, "default groups")
        require(configuration.maximumCallsPerCallGroup == 5, "default per group")
        configuration.supportsVideo = true
        configuration.includesCallsInRecents = false
        configuration.supportsAudioTranslation = true
        configuration.ringtoneSound = "ring.caf"
        configuration.iconTemplateImageData = Data([0x00, 0x01])
        configuration.supportedHandleTypes = [.phoneNumber, .generic]
        let configCopy = configuration.copy() as! CXProviderConfiguration
        require(configCopy.supportsVideo && configCopy.supportedHandleTypes.contains(.generic), "config copy")

        let action = CXAction()
        require(!action.isComplete, "new action")
        require(action.timeoutDate == Date.distantFuture, "portable timeoutDate")
        require(action.uuid != UUID(), "action uuid identity")
        action.fulfill()
        require(action.isComplete, "fulfilled")
        require(action._portableDidFulfill == true, "fulfill flag")
        let failed = CXAction()
        failed.fail()
        require(failed.isComplete, "failed complete")
        require(failed._portableDidFulfill == false, "fail flag")

        let uuid = UUID()
        let start = CXStartCallAction(call: uuid, handle: handle)
        start.isVideo = true
        start.contactIdentifier = "contact-1"
        require(start.callUUID == uuid && start.handle == handle && start.isVideo, "start action")
        _ = CXStartCallAction(callUUID: uuid, handle: handle)
        _ = CXSetHeldCallAction(callUUID: uuid, onHold: true)
        _ = CXSetMutedCallAction(callUUID: uuid, muted: true)
        _ = CXSetGroupCallAction(callUUID: uuid, callUUIDToGroupWith: nil)
        let dtmf = CXPlayDTMFCallAction(callUUID: uuid, digits: "9", type: .softPause)
        require(dtmf.digits == "9" && dtmf.type == .softPause, "dtmf")
        let translating = CXSetTranslatingCallAction(
            callUUID: uuid,
            isTranslating: true,
            localLanguage: "en",
            remoteLanguage: "es"
        )
        require(translating.isTranslating && translating.localLanguage == "en", "translating")
        let transaction = CXTransaction(action: start)
        transaction.addAction(CXEndCallAction(call: uuid))
        require(transaction.actions.count == 2, "transaction actions")
        require(!transaction.isComplete, "transaction incomplete")
    }

    private static func exerciseQueueIdentityAndNonReentrancy() {
        let providerProbe = QueueProbe("callkit.provider.delegate")
        let observerProbe = QueueProbe("callkit.observer.delegate")
        let configuration = CXProviderConfiguration()
        configuration.maximumCallGroups = 8
        let provider = CXProvider(configuration: configuration)
        let delegate = TestProviderDelegate(probe: providerProbe)
        let began = DispatchSemaphore(value: 0)
        delegate.onBegin = { began.signal() }
        provider.setDelegate(delegate, queue: providerProbe.queue)
        wait(began, "providerDidBegin")
        require(delegate.began == 1, "began")

        let observer = CXCallObserver()
        let observerDelegate = TestObserverDelegate(probe: observerProbe)
        let changed = DispatchSemaphore(value: 0)
        observerDelegate.onChange = { changed.signal() }
        observer.setDelegate(observerDelegate, queue: observerProbe.queue)

        let controller = CXCallController()
        let incomingID = UUID()
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "signal")
        let incomingDone = DispatchSemaphore(value: 0)
        provider.reportNewIncomingCall(with: incomingID, update: update) { error in
            require(error == nil, "incoming report")
            incomingDone.signal()
        }
        wait(incomingDone, "incoming completion")
        wait(changed, "observer incoming")

        let answered = DispatchSemaphore(value: 0)
        let muted = DispatchSemaphore(value: 0)
        delegate.onAnswer = { answered.signal() }
        delegate.onMute = { muted.signal() }
        delegate.reentrantController = controller
        delegate.reentrantMute = CXSetMutedCallAction(call: incomingID, muted: true)

        let submitError = request(controller, CXTransaction(action: CXAnswerCallAction(call: incomingID)))
        require(submitError == nil, "answer submit")
        require(delegate.answered.isEmpty || delegate.maxPerformDepth >= 1, "no circular answer assert")
        wait(answered, "answer perform")
        require(delegate.answered == [incomingID], "answered")
        require(delegate.nestedMutedDuringAnswer == 0, "mute must not re-enter answer")
        wait(muted, "mute perform")
        require(delegate.muted == [true], "muted after async")
        require(delegate.maxPerformDepth == 1, "non-reentrant perform")
        require(observer.calls.first(where: { $0.uuid == incomingID })?.hasConnected == true, "connected after fulfill")

        let mainKey = DispatchSpecificKey<String>()
        DispatchQueue.main.setSpecific(key: mainKey, value: "callkit.main")

        let nilBegin = DispatchSemaphore(value: 0)
        let nilProvider = CXProvider(configuration: CXProviderConfiguration())
        let nilDelegate = TestProviderDelegate()
        nilDelegate.onBegin = {
            require(
                DispatchQueue.getSpecific(key: mainKey) == "callkit.main",
                "nil provider queue is main"
            )
            nilBegin.signal()
        }
        nilProvider.setDelegate(nilDelegate, queue: nil)
        wait(nilBegin, "nil-queue providerDidBegin")

        let nilObserver = CXCallObserver()
        let nilObserverDelegate = TestObserverDelegate()
        let nilChanged = DispatchSemaphore(value: 0)
        nilObserverDelegate.onChange = {
            require(
                DispatchQueue.getSpecific(key: mainKey) == "callkit.main",
                "nil observer queue is main"
            )
            nilChanged.signal()
        }
        nilObserver.setDelegate(nilObserverDelegate, queue: nil)
        let nilIncoming = UUID()
        nilProvider.reportNewIncomingCall(with: nilIncoming, update: CXCallUpdate()) { error in
            require(error == nil, "nil-queue incoming")
        }
        wait(nilChanged, "nil-queue observer")

        let reset = DispatchSemaphore(value: 0)
        delegate.onReset = { reset.signal() }
        provider.invalidate()
        wait(reset, "providerDidReset")
        nilProvider.invalidate()
    }

    private static func exerciseOwnershipRouting() {
        let firstProbe = QueueProbe("callkit.owner.first")
        let secondProbe = QueueProbe("callkit.owner.second")
        let first = CXProvider(configuration: CXProviderConfiguration())
        let second = CXProvider(configuration: CXProviderConfiguration())
        let firstDelegate = TestProviderDelegate(probe: firstProbe)
        let secondDelegate = TestProviderDelegate(probe: secondProbe)
        let firstBegan = DispatchSemaphore(value: 0)
        let secondBegan = DispatchSemaphore(value: 0)
        firstDelegate.onBegin = { firstBegan.signal() }
        secondDelegate.onBegin = { secondBegan.signal() }
        first.setDelegate(firstDelegate, queue: firstProbe.queue)
        second.setDelegate(secondDelegate, queue: secondProbe.queue)
        wait(firstBegan, "first begin")
        wait(secondBegan, "second begin")

        let a = UUID()
        let b = UUID()
        first.reportNewIncomingCall(with: a, update: CXCallUpdate()) { error in
            require(error == nil, "first incoming")
        }
        second.reportNewIncomingCall(with: b, update: CXCallUpdate()) { error in
            require(error == nil, "second incoming")
        }

        let controller = CXCallController()

        let crossGroup = CXSetGroupCallAction(call: a, callUUIDToGroupWith: b)
        requireRequestError(
            request(controller, CXTransaction(action: crossGroup))!,
            .invalidAction
        )
        require(firstDelegate.grouped.isEmpty, "cross-provider group not delivered")
        require(secondDelegate.grouped.isEmpty, "cross-provider group not stolen")

        let strayStart = CXStartCallAction(
            call: UUID(),
            handle: CXHandle(type: .generic, value: "stray")
        )
        requireRequestError(
            request(controller, CXTransaction(action: strayStart))!,
            .unknownCallProvider
        )
        require(firstDelegate.started.isEmpty && secondDelegate.started.isEmpty, "start unbound with two providers")

        let firstEnded = DispatchSemaphore(value: 0)
        firstDelegate.onEnd = { firstEnded.signal() }
        let error = request(controller, CXTransaction(action: CXEndCallAction(call: a)))
        require(error == nil, "end A submit")
        wait(firstEnded, "end A routed to owner")
        require(firstDelegate.ended == [a], "first owner ended A")
        require(secondDelegate.ended.isEmpty, "last provider must not steal A")

        first.invalidate()
        second.invalidate()
    }

    private static func exerciseAtomicPreflight() {
        let probe = QueueProbe("callkit.preflight")
        let configuration = CXProviderConfiguration()
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 2
        let provider = CXProvider(configuration: configuration)
        let delegate = TestProviderDelegate(probe: probe)
        let began = DispatchSemaphore(value: 0)
        delegate.onBegin = { began.signal() }
        provider.setDelegate(delegate, queue: probe.queue)
        wait(began, "preflight begin")
        let controller = CXCallController()
        let observer = controller.callObserver

        let missing = UUID()
        let start = CXStartCallAction(
            call: UUID(),
            handle: CXHandle(type: .generic, value: "x")
        )
        let mixed = CXTransaction(actions: [start, CXEndCallAction(call: missing)])
        let mixedError = request(controller, mixed)
        requireRequestError(mixedError!, .unknownCallUUID)
        require(start.isComplete, "rejected start is failed")
        require(start._portableDidFulfill == false, "rejected start not fulfilled")
        require(!observer.calls.contains { $0.uuid == start.callUUID }, "no partial start")
        require(delegate.started.isEmpty, "rejected txn not delivered")

        let dup = UUID()
        let dupTxn = CXTransaction(
            actions: [
                CXStartCallAction(call: dup, handle: CXHandle(type: .generic, value: "a")),
                CXStartCallAction(call: dup, handle: CXHandle(type: .generic, value: "b"))
            ]
        )
        requireRequestError(request(controller, dupTxn)!, .callUUIDAlreadyExists)
        require(!observer.calls.contains { $0.uuid == dup }, "duplicate start not inserted")

        let pairA = UUID()
        let pairB = UUID()
        let groupedStarts = DispatchSemaphore(value: 0)
        let grouped = DispatchSemaphore(value: 0)
        delegate.onStart = { groupedStarts.signal() }
        delegate.onGroup = { grouped.signal() }
        require(
            request(
                controller,
                CXTransaction(
                    actions: [
                        CXStartCallAction(call: pairA, handle: CXHandle(type: .generic, value: "ga")),
                        CXStartCallAction(call: pairB, handle: CXHandle(type: .generic, value: "gb")),
                        CXSetGroupCallAction(call: pairB, callUUIDToGroupWith: pairA)
                    ]
                )
            ) == nil,
            "two starts plus group under one group budget"
        )
        wait(groupedStarts, "grouped start A")
        wait(groupedStarts, "grouped start B")
        wait(grouped, "group perform")
        require(observer.calls.contains { $0.uuid == pairA }, "grouped start A present")
        require(observer.calls.contains { $0.uuid == pairB }, "grouped start B present")

        let endedPair = DispatchSemaphore(value: 0)
        delegate.onEnd = { endedPair.signal() }
        require(
            request(
                controller,
                CXTransaction(
                    actions: [
                        CXEndCallAction(call: pairA),
                        CXEndCallAction(call: pairB)
                    ]
                )
            ) == nil,
            "end grouped pair"
        )
        wait(endedPair, "end pair A")
        wait(endedPair, "end pair B")
        delegate.onEnd = nil
        delegate.onGroup = nil

        let firstStart = DispatchSemaphore(value: 0)
        delegate.onStart = { firstStart.signal() }
        let only = UUID()
        require(
            request(
                controller,
                CXTransaction(
                    action: CXStartCallAction(
                        call: only,
                        handle: CXHandle(type: .generic, value: "one")
                    )
                )
            ) == nil,
            "single start"
        )
        wait(firstStart, "first start perform")
        require(observer.calls.contains { $0.uuid == only }, "start present after fulfill")

        let extra = UUID()
        let overflow = CXStartCallAction(
            call: extra,
            handle: CXHandle(type: .generic, value: "two")
        )
        requireRequestError(
            request(controller, CXTransaction(action: overflow))!,
            .maximumCallGroupsReached
        )
        require(!observer.calls.contains { $0.uuid == extra }, "overflow start absent")

        let ghost = UUID()
        let groupMissing = CXSetGroupCallAction(call: only, callUUIDToGroupWith: ghost)
        requireRequestError(
            request(controller, CXTransaction(action: groupMissing))!,
            .unknownCallUUID
        )

        let failedStartID = UUID()
        provider.invalidate()
        let failProvider = CXProvider(configuration: CXProviderConfiguration())
        let failBegan = DispatchSemaphore(value: 0)
        let failDelegate = FailingStartDelegate(probe: probe, began: failBegan)
        failProvider.setDelegate(failDelegate, queue: probe.queue)
        wait(failBegan, "fail provider begin")
        let failController = CXCallController()
        let failStart = CXStartCallAction(
            call: failedStartID,
            handle: CXHandle(type: .generic, value: "fail")
        )
        let performed = DispatchSemaphore(value: 0)
        failDelegate.onPerformed = { performed.signal() }
        require(request(failController, CXTransaction(action: failStart)) == nil, "fail start submit")
        wait(performed, "fail start perform")
        require(failStart._portableDidFulfill == false, "failed action")
        require(
            !failController.callObserver.calls.contains { $0.uuid == failedStartID },
            "failed start did not mutate"
        )
        failProvider.invalidate()
    }

    private static func exercisePendingReportsAndLimits() {
        let executeProbe = QueueProbe("callkit.execute")
        let executeProvider = CXProvider(configuration: CXProviderConfiguration())
        let executeDelegate = ExecuteTrueDelegate(probe: executeProbe)
        let executeBegan = DispatchSemaphore(value: 0)
        executeDelegate.onBegin = { executeBegan.signal() }
        executeProvider.setDelegate(executeDelegate, queue: executeProbe.queue)
        wait(executeBegan, "execute begin")
        let executeController = CXCallController()
        let executeID = UUID()
        let executeStart = CXStartCallAction(
            call: executeID,
            handle: CXHandle(type: .generic, value: "execute")
        )
        require(
            request(executeController, CXTransaction(action: executeStart)) == nil,
            "execute submit"
        )
        wait(executeDelegate.executed, "execute transaction")
        require(executeDelegate.performedStarts == 0, "execute true skips perform")
        require(
            !executeController.callObserver.calls.contains { $0.uuid == executeID },
            "execute true does not mutate"
        )
        executeProvider.invalidate()

        let probe = QueueProbe("callkit.pending")
        let configuration = CXProviderConfiguration()
        configuration.maximumCallGroups = 2
        configuration.maximumCallsPerCallGroup = 1
        let provider = CXProvider(configuration: configuration)
        let delayed = DelayedStartDelegate(probe: probe)
        let began = DispatchSemaphore(value: 0)
        delayed.onBegin = { began.signal() }
        provider.setDelegate(delayed, queue: probe.queue)
        wait(began, "pending begin")

        let controllerQueue = DispatchQueue(label: "callkit.controller.identity")
        let controllerKey = DispatchSpecificKey<String>()
        controllerQueue.setSpecific(key: controllerKey, value: "controller")
        let controller = CXCallController(queue: controllerQueue)
        let startID = UUID()
        let start = CXStartCallAction(
            call: startID,
            handle: CXHandle(type: .generic, value: "pending")
        )
        let submitted = DispatchSemaphore(value: 0)
        var submitError: (any Error)?
        controller.request(CXTransaction(action: start)) { error in
            require(
                DispatchQueue.getSpecific(key: controllerKey) == "controller",
                "request completion on controller queue"
            )
            submitError = error
            submitted.signal()
        }
        wait(submitted, "pending submit")
        require(submitError == nil, "pending submit ok")
        wait(delayed.performed, "pending perform")
        require(controller.callObserver.calls.isEmpty, "no mutation before fulfill")
        require(
            provider.pendingCallActions(of: CXStartCallAction.self, withCall: startID).count == 1,
            "pendingCallActions"
        )
        require(provider.pendingTransactions.count == 1, "pendingTransactions")
        start.fulfill(withDateStarted: Date())
        let appeared = DispatchSemaphore(value: 0)
        let observer = TestObserverDelegate(probe: probe)
        observer.onChange = { appeared.signal() }
        controller.callObserver.setDelegate(observer, queue: probe.queue)
        if controller.callObserver.calls.contains(where: { $0.uuid == startID }) {
            appeared.signal()
        }
        wait(appeared, "fulfilled start visible")
        require(
            provider.pendingCallActions(of: CXStartCallAction.self, withCall: startID).isEmpty,
            "pending cleared after fulfill"
        )

        provider.reportOutgoingCall(with: startID, startedConnectingAt: Date())
        provider.reportOutgoingCall(with: startID, connectedAt: Date())
        require(
            controller.callObserver.calls.first(where: { $0.uuid == startID })?.hasConnected == true,
            "outgoing connected"
        )
        let update = CXCallUpdate()
        update.localizedCallerName = "Pending"
        provider.reportCall(with: startID, updated: update)

        let second = UUID()
        let secondStart = CXStartCallAction(
            call: second,
            handle: CXHandle(type: .generic, value: "second")
        )
        delayed.performed = DispatchSemaphore(value: 0)
        require(
            request(controller, CXTransaction(action: secondStart)) == nil,
            "second group start"
        )
        wait(delayed.performed, "second start perform")
        secondStart.fulfill()
        require(controller.callObserver.calls.contains { $0.uuid == second }, "second present")

        requireRequestError(
            request(
                controller,
                CXTransaction(action: CXSetGroupCallAction(call: second, callUUIDToGroupWith: startID))
            )!,
            .invalidAction
        )
        require(
            controller.callObserver.calls.contains { $0.uuid == second },
            "per-group overflow kept second"
        )
        require(
            controller.callObserver.calls.contains { $0.uuid == startID },
            "per-group overflow kept first"
        )

        let ended = DispatchSemaphore(value: 0)
        observer.onChange = { ended.signal() }
        provider.reportCall(with: startID, endedAt: Date(), reason: .remoteEnded)
        wait(ended, "report ended")
        require(
            !controller.callObserver.calls.contains { $0.uuid == startID },
            "ended call removed"
        )

        let duplicate = UUID()
        let incomingDone = DispatchSemaphore(value: 0)
        provider.reportNewIncomingCall(with: duplicate, update: CXCallUpdate()) { error in
            require(error == nil, "first incoming")
            incomingDone.signal()
        }
        wait(incomingDone, "incoming")
        let dupDone = DispatchSemaphore(value: 0)
        var dupError: (any Error)?
        provider.reportNewIncomingCall(with: duplicate, update: CXCallUpdate()) { error in
            dupError = error
            dupDone.signal()
        }
        wait(dupDone, "duplicate incoming")
        require(
            (dupError as? CXErrorCodeIncomingCallError)?.code == .callUUIDAlreadyExists,
            "duplicate incoming"
        )

        delayed.performed = DispatchSemaphore(value: 0)
        let dtmf = CXPlayDTMFCallAction(call: second, digits: "1", type: .singleTone)
        let held = CXSetHeldCallAction(call: second, onHold: true)
        let translating = CXSetTranslatingCallAction(
            callUUID: second,
            isTranslating: true,
            localLanguage: "en",
            remoteLanguage: "es"
        )
        let actionsSubmitted = DispatchSemaphore(value: 0)
        var actionsError: (any Error)?
        controller.requestTransaction(with: [dtmf, held, translating]) { error in
            actionsError = error
            actionsSubmitted.signal()
        }
        wait(actionsSubmitted, "requestTransaction with actions")
        require(actionsError == nil, "requestTransaction with actions")
        wait(delayed.performed, "dtmf")
        wait(delayed.performed, "held")
        wait(delayed.performed, "translating")
        require(dtmf.isComplete && held.isComplete && translating.isComplete, "actions fulfilled")
        require(
            controller.callObserver.calls.first(where: { $0.uuid == second })?.isOnHold == true,
            "held after fulfill"
        )

        provider.invalidate()
        require(
            !controller.callObserver.calls.contains { $0.uuid == second },
            "invalidate ends owned calls"
        )
        require(
            !controller.callObserver.calls.contains { $0.uuid == duplicate },
            "invalidate ends incoming"
        )
    }

    private static func exerciseFailClosedBoundaries() {
        let voipBox = DispatchSemaphore(value: 0)
        var voipError: (any Error)?
        CXProvider.reportNewIncomingVoIPPushPayload(["aps": "x"]) { error in
            voipError = error
            voipBox.signal()
        }
        wait(voipBox, "voip")
        require(
            (voipError as? CXErrorCodeNotificationServiceExtensionError)?.code
                == .invalidClientProcess,
            "voip fail closed"
        )

        let provider = CXProvider(configuration: CXProviderConfiguration())
        let probe = QueueProbe("callkit.failclosed")
        let delegate = TestProviderDelegate(probe: probe)
        let began = DispatchSemaphore(value: 0)
        delegate.onBegin = { began.signal() }
        provider.setDelegate(delegate, queue: probe.queue)
        wait(began, "fail-closed begin")
        let controller = CXCallController(queue: DispatchQueue(label: "callkit-test-controller"))
        requireRequestError(request(controller, CXTransaction(actions: []))!, .emptyTransaction)
        requireRequestError(
            request(controller, CXTransaction(action: CXEndCallAction(call: UUID())))!,
            .unknownCallUUID
        )
        provider.invalidate()

        let orphan = DispatchSemaphore(value: 0)
        var orphanError: (any Error)?
        CXCallController().requestTransaction(with: CXEndCallAction(call: UUID())) { error in
            orphanError = error
            orphan.signal()
        }
        wait(orphan, "orphan")
        requireRequestError(orphanError!, .unknownCallProvider)

        let reloadBox = DispatchSemaphore(value: 0)
        var reloadError: (any Error)?
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "none") { error in
            reloadError = error
            reloadBox.signal()
        }
        wait(reloadBox, "reload")
        require(
            (reloadError as? CXErrorCodeCallDirectoryManagerError)?.code == .noExtensionFound,
            "reload"
        )

        let settingsBox = DispatchSemaphore(value: 0)
        var settings: (any Error)?
        CXCallDirectoryManager.sharedInstance.openSettings { error in
            settings = error
            settingsBox.signal()
        }
        wait(settingsBox, "settings")
        require((settings as? CXError)?.code == .unentitled, "openSettings")

        let statusBox = DispatchSemaphore(value: 0)
        var status: CXCallDirectoryManager.EnabledStatus?
        var statusError: (any Error)?
        CXCallDirectoryManager.sharedInstance.enabledStatusForExtension(withIdentifier: "none") {
            enabled, error in
            status = enabled
            statusError = error
            statusBox.signal()
        }
        wait(statusBox, "enabled status")
        require(status == .unknown, "enabled status unknown")
        require(
            (statusError as? CXErrorCodeCallDirectoryManagerError)?.code == .noExtensionFound,
            "enabled status fail-closed"
        )
    }

    private static func exerciseCallDirectory() {
        let context = CXCallDirectoryExtensionContext()
        let delegate = DirectoryDelegate()
        context.delegate = delegate
        require(!context.isIncremental, "default incremental")
        context.addBlockingEntry(withNextSequentialPhoneNumber: 1_555_111_2222)
        context.addBlockingEntry(withNextSequentialPhoneNumber: 1_555_111_2223)
        context.addIdentificationEntry(
            withNextSequentialPhoneNumber: 1_555_000_0001,
            label: "Spam"
        )
        context.removeBlockingEntry(withPhoneNumber: 1_555_111_2222)
        context.completeRequest { success in
            require(!success, "completeRequest must not claim host install")
        }
        require(!delegate.errors.isEmpty, "directory delegate failure")
        require(
            (delegate.errors.first as? CXErrorCodeCallDirectoryManagerError)?.code
                == .unexpectedIncrementalRemoval,
            "non-incremental removal fail-closed"
        )

        let ordered = CXCallDirectoryExtensionContext()
        let orderDelegate = DirectoryDelegate()
        ordered.delegate = orderDelegate
        ordered.addBlockingEntry(withNextSequentialPhoneNumber: 200)
        ordered.addBlockingEntry(withNextSequentialPhoneNumber: 100)
        ordered.completeRequest { success in
            require(!success, "out-of-order blocking fails closed")
        }
        require(
            (orderDelegate.errors.first as? CXErrorCodeCallDirectoryManagerError)?.code
                == .entriesOutOfOrder,
            "entriesOutOfOrder"
        )

        let duplicates = CXCallDirectoryExtensionContext()
        let duplicateDelegate = DirectoryDelegate()
        duplicates.delegate = duplicateDelegate
        duplicates.addIdentificationEntry(withNextSequentialPhoneNumber: 300, label: "A")
        duplicates.addIdentificationEntry(withNextSequentialPhoneNumber: 300, label: "B")
        duplicates.completeRequest { success in
            require(!success, "duplicate identification fails closed")
        }
        require(
            (duplicateDelegate.errors.first as? CXErrorCodeCallDirectoryManagerError)?.code
                == .duplicateEntries,
            "duplicateEntries"
        )

        let incremental = CXCallDirectoryExtensionContext()
        incremental._portableSetIncremental(true)
        incremental.addBlockingEntry(withNextSequentialPhoneNumber: 400)
        incremental.addIdentificationEntry(withNextSequentialPhoneNumber: 500, label: "X")
        incremental.removeBlockingEntry(withPhoneNumber: 400)
        incremental.removeIdentificationEntry(withPhoneNumber: 500)
        incremental.addBlockingEntry(withNextSequentialPhoneNumber: 401)
        incremental.addIdentificationEntry(withNextSequentialPhoneNumber: 501, label: "Y")
        incremental.removeAllBlockingEntries()
        incremental.removeAllIdentificationEntries()
        require(incremental._portableBlockingEntries.isEmpty, "removed all blocking")
        require(incremental._portableIdentificationEntries.isEmpty, "removed all identification")
        incremental.completeRequest { success in
            require(!success, "incremental complete still has no host")
        }

        CXCallDirectoryProvider().beginRequest(with: CXCallDirectoryExtensionContext())
        require(CXCallDirectoryManager.EnabledStatus.disabled.rawValue == 1, "enabled raw")
    }

    private static func exerciseCoding() {
        let handle = CXHandle(type: .emailAddress, value: "ada@example.com")
        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: handle,
                requiringSecureCoding: true
            )
            let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: CXHandle.self, from: data)
            require(decoded == handle, "handle round trip")
        } catch {
            fatalError("handle archive failed: \(error)")
        }

        let action = CXCallAction(callUUID: UUID())
        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: action,
                requiringSecureCoding: true
            )
            let decoded = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: CXCallAction.self,
                from: data
            )
            require(decoded?.callUUID == action.callUUID, "call action round trip")
        } catch {
            fatalError("action archive failed: \(error)")
        }
        let transaction = CXTransaction()
        transaction.addAction(CXAction())
        require(!transaction.actions.isEmpty, "blank transaction add")
    }
}

private final class DelayedStartDelegate: NSObject, CXProviderDelegate, @unchecked Sendable {
    let probe: QueueProbe
    var performed = DispatchSemaphore(value: 0)
    var onBegin: (() -> Void)?

    init(probe: QueueProbe) {
        self.probe = probe
    }

    func providerDidBegin(_ provider: CXProvider) {
        _ = provider
        probe.assertCurrent("delayed begin off queue")
        onBegin?()
    }

    func providerDidReset(_ provider: CXProvider) {
        _ = provider
        probe.assertCurrent("delayed reset off queue")
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        _ = provider
        probe.assertCurrent("delayed start off queue")
        performed.signal()
    }

    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        _ = provider
        probe.assertCurrent("delayed dtmf off queue")
        action.fulfill()
        performed.signal()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        _ = provider
        probe.assertCurrent("delayed hold off queue")
        action.fulfill()
        performed.signal()
    }

    func provider(_ provider: CXProvider, perform action: CXSetTranslatingCallAction) {
        _ = provider
        probe.assertCurrent("delayed translating off queue")
        action.fulfill(using: .default)
        performed.signal()
    }
}

private final class ExecuteTrueDelegate: NSObject, CXProviderDelegate, @unchecked Sendable {
    let probe: QueueProbe
    let executed = DispatchSemaphore(value: 0)
    var performedStarts = 0
    var onBegin: (() -> Void)?

    init(probe: QueueProbe) {
        self.probe = probe
    }

    func providerDidBegin(_ provider: CXProvider) {
        _ = provider
        probe.assertCurrent("execute begin off queue")
        onBegin?()
    }

    func providerDidReset(_ provider: CXProvider) {
        _ = provider
    }

    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
        _ = provider
        _ = transaction
        probe.assertCurrent("execute off queue")
        executed.signal()
        return true
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        _ = provider
        performedStarts += 1
        action.fulfill()
    }
}

private final class FailingStartDelegate: NSObject, CXProviderDelegate, @unchecked Sendable {
    let probe: QueueProbe
    let began: DispatchSemaphore
    var onPerformed: (() -> Void)?

    init(probe: QueueProbe, began: DispatchSemaphore) {
        self.probe = probe
        self.began = began
    }

    func providerDidBegin(_ provider: CXProvider) {
        _ = provider
        probe.assertCurrent("fail begin off queue")
        began.signal()
    }

    func providerDidReset(_ provider: CXProvider) {
        _ = provider
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        _ = provider
        probe.assertCurrent("fail start off queue")
        action.fail()
        onPerformed?()
    }
}

let _callKitDriver = DispatchQueue(label: "callkit.runtime.driver")
_callKitDriver.async {
    CallKitRuntime.run()
    exit(0)
}
dispatchMain()
