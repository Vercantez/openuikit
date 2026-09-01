import CallKit
import Foundation
@preconcurrency import Dispatch

private final class TestProviderDelegate: NSObject, CXProviderDelegate {
    var began = 0
    var reset = 0
    var started: [UUID] = []
    var answered: [UUID] = []
    var ended: [UUID] = []
    var held: [Bool] = []
    var muted: [Bool] = []
    var grouped: [UUID?] = []
    var dtmf: [String] = []
    var translating: [CXTranslationEngine] = []
    var executeOverride: ((CXTransaction) -> Bool)?

    func providerDidReset(_ provider: CXProvider) {
        _ = provider
        reset += 1
    }

    func providerDidBegin(_ provider: CXProvider) {
        _ = provider
        began += 1
    }

    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
        _ = provider
        if let executeOverride {
            return executeOverride(transaction)
        }
        return false
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        _ = provider
        started.append(action.callUUID)
        action.fulfill(withDateStarted: Date())
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        _ = provider
        answered.append(action.callUUID)
        action.fulfill(withDateConnected: Date())
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        _ = provider
        ended.append(action.callUUID)
        action.fulfill(withDateEnded: Date())
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        _ = provider
        held.append(action.isOnHold)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        _ = provider
        muted.append(action.isMuted)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        _ = provider
        grouped.append(action.callUUIDToGroupWith)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        _ = provider
        dtmf.append(action.digits)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetTranslatingCallAction) {
        _ = provider
        action.fulfill(using: .default)
        translating.append(.default)
    }
}

private final class TestObserverDelegate: NSObject, CXCallObserverDelegate {
    var changes: [CXCall] = []

    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        _ = callObserver
        changes.append(call)
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

enum CallKitRuntime {
    static func main() async {
        exerciseErrors()
        exerciseHandlesAndUpdates()
        await exerciseProviderCallFlow()
        await exerciseFailClosedBoundaries()
        exerciseCallDirectory()
        exerciseCoding()
        print("CALLKIT_AGENT_RUNTIME_OK")
    }

    private static func exerciseErrors() {
        require(CXErrorDomain == "com.apple.CallKit.error", "CXErrorDomain")
        require(
            CXError.errorDomain == CXErrorDomain
                && CXError.unentitled.rawValue == 1
                && CXError.invalidArgument.rawValue == 2
                && CXError.unknownError.rawValue == 0
                && CXError.missingVoIPBackgroundMode.rawValue == 3,
            "CXError codes"
        )
        let entitled = CXError(.unentitled, userInfo: ["k": "v"])
        require(entitled.code == .unentitled, "CXError.code")
        require(entitled != CXError(.unknownError), "CXError !=")
        require(entitled == CXError(.unentitled, userInfo: ["k": "v"]), "CXError ==")
        require(CXError.Code.unentitled ~= entitled, "CXError ~=")
        _ = entitled.hashValue
        _ = entitled.localizedDescription
        _ = entitled.errorUserInfo

        require(
            CXErrorCodeIncomingCallError.callUUIDAlreadyExists.rawValue == 2
                && CXErrorCodeIncomingCallError.filteredBySensitiveParticipants.rawValue == 7,
            "incoming codes"
        )
        require(
            CXErrorCodeRequestTransactionError.emptyTransaction.rawValue == 3
                && CXErrorCodeRequestTransactionError.callIsProtected.rawValue == 8,
            "request codes"
        )
        require(
            CXErrorCodeCallDirectoryManagerError.noExtensionFound.rawValue == 1
                && CXErrorCodeCallDirectoryManagerError.unexpectedIncrementalRemoval.rawValue == 8,
            "directory codes"
        )
        require(
            CXErrorCodeNotificationServiceExtensionError.invalidClientProcess.rawValue == 1,
            "nse codes"
        )
        require(CXErrorCodeIncomingCallError.unknown != CXErrorCodeIncomingCallError.unentitled, "incoming !=")
        require(CXCallEndedReason.failed != CXCallEndedReason.remoteEnded, "ended !=")
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
        _ = CXTranslationEngine.custom.hashValue
        require(CXCallDirectoryPhoneNumberMax == 9_999_999_999, "phone max")
        require(CXHandle.HandleType(rawValue: 2) == .phoneNumber, "handle raw")
        require(CXCallEndedReason(rawValue: 4) == .answeredElsewhere, "ended raw")
        require(CXTranslationEngine(rawValue: 0) == .default, "engine raw")
        require(CXPlayDTMFCallAction.ActionType(rawValue: 3) == .hardPause, "dtmf raw")
        require(CXCallDirectoryManager.EnabledStatus(rawValue: 1) == .disabled, "status raw")
        require(CXError.Code(rawValue: 1) == .unentitled, "CXError raw")
        _ = CXErrorCodeIncomingCallError(.filteredByDoNotDisturb).localizedDescription
        _ = CXErrorCodeRequestTransactionError(.invalidAction).hashValue
        _ = CXErrorCodeCallDirectoryManagerError(.duplicateEntries).errorUserInfo
        _ = CXErrorCodeNotificationServiceExtensionError(
            .missingNotificationFilteringEntitlement
        ).localizedDescription
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
        require(action.timeoutDate == Date.distantFuture, "timeout")
        action.fulfill()
        require(action.isComplete, "fulfilled")
        let failed = CXAction()
        failed.fail()
        require(failed.isComplete, "failed complete")

        let uuid = UUID()
        let start = CXStartCallAction(call: uuid, handle: handle)
        start.isVideo = true
        start.contactIdentifier = "contact-1"
        require(start.callUUID == uuid && start.handle == handle && start.isVideo, "start action")
        let startAlt = CXStartCallAction(callUUID: uuid, handle: handle)
        require(startAlt.callUUID == uuid, "start alt init")

        let held = CXSetHeldCallAction(callUUID: uuid, onHold: true)
        require(held.isOnHold, "held")
        let muted = CXSetMutedCallAction(callUUID: uuid, muted: true)
        require(muted.isMuted, "muted")
        let grouped = CXSetGroupCallAction(callUUID: uuid, callUUIDToGroupWith: nil)
        require(grouped.callUUIDToGroupWith == nil, "group nil")
        let dtmf = CXPlayDTMFCallAction(
            callUUID: uuid,
            digits: "9",
            type: .softPause
        )
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
        require(CXTransaction(actions: [start]).actions.count == 1, "init actions")
    }

    private static func exerciseProviderCallFlow() async {
        let configuration = CXProviderConfiguration()
        configuration.supportedHandleTypes = [.generic]
        configuration.maximumCallGroups = 8
        let provider = CXProvider(configuration: configuration)
        let delegate = TestProviderDelegate()
        provider.setDelegate(delegate, queue: nil)
        require(delegate.began == 1, "providerDidBegin")

        let observer = CXCallObserver()
        let observerDelegate = TestObserverDelegate()
        observer.setDelegate(observerDelegate, queue: nil)

        let controller = CXCallController()
        require(controller.callObserver.calls.isEmpty, "no calls yet")

        let incomingID = UUID()
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "signal")
        update.localizedCallerName = "Incoming"
        try! await provider.reportNewIncomingCall(with: incomingID, update: update)
        require(observer.calls.contains { $0.uuid == incomingID }, "incoming registered")
        require(observer.calls.first(where: { $0.uuid == incomingID })?.isOutgoing == false, "incoming direction")

        do {
            try await provider.reportNewIncomingCall(with: incomingID, update: update)
            fatalError("duplicate incoming must fail")
        } catch let error as CXErrorCodeIncomingCallError {
            require(error.code == .callUUIDAlreadyExists, "duplicate incoming code")
            require(
                CXErrorCodeIncomingCallError.Code.callUUIDAlreadyExists ~= error,
                "incoming ~="
            )
        } catch {
            fatalError("wrong duplicate error \(error)")
        }

        provider.reportCall(with: incomingID, updated: update)
        try! await controller.requestTransaction(with: CXAnswerCallAction(call: incomingID))
        require(delegate.answered == [incomingID], "answered")
        require(observer.calls.first(where: { $0.uuid == incomingID })?.hasConnected == true, "connected")

        try! await controller.requestTransaction(
            with: CXSetHeldCallAction(call: incomingID, onHold: true)
        )
        try! await controller.requestTransaction(
            with: CXSetMutedCallAction(call: incomingID, muted: true)
        )
        try! await controller.requestTransaction(
            with: CXPlayDTMFCallAction(call: incomingID, digits: "1", type: .singleTone)
        )
        let translate = CXSetTranslatingCallAction(
            call: incomingID,
            isTranslating: true,
            localLanguage: "en",
            remoteLanguage: "fr"
        )
        try! await controller.requestTransaction(with: translate)
        require(delegate.held == [true], "held callback")
        require(delegate.muted == [true], "muted callback")
        require(delegate.dtmf == ["1"], "dtmf callback")
        require(delegate.translating == [.default], "translate callback")

        let outgoingID = UUID()
        let start = CXStartCallAction(
            call: outgoingID,
            handle: CXHandle(type: .phoneNumber, value: "555")
        )
        try! await controller.request(CXTransaction(action: start))
        require(delegate.started == [outgoingID], "started")
        provider.reportOutgoingCall(with: outgoingID, startedConnectingAt: Date())
        provider.reportOutgoingCall(with: outgoingID, connectedAt: Date())
        require(observer.calls.contains { $0.uuid == outgoingID && $0.isOutgoing }, "outgoing present")

        try! await controller.requestTransaction(
            with: CXSetGroupCallAction(call: outgoingID, callUUIDToGroupWith: incomingID)
        )
        require(delegate.grouped == [incomingID], "grouped")

        let pending = provider.pendingCallActions(of: CXAnswerCallAction.self, withCall: incomingID)
        require(pending.isEmpty, "answered action completed")

        try! await controller.requestTransaction(with: [CXEndCallAction(call: incomingID)])
        provider.reportCall(with: incomingID, endedAt: Date(), reason: .remoteEnded)
        require(delegate.ended == [incomingID], "ended")
        require(!observer.calls.contains { $0.uuid == incomingID && !$0.hasEnded }, "incoming removed")

        provider.invalidate()
        require(delegate.reset == 1, "providerDidReset")
    }

    private static func exerciseFailClosedBoundaries() async {
        do {
            try await CXProvider.reportNewIncomingVoIPPushPayload(["aps": "x"])
            fatalError("VoIP push must fail closed")
        } catch let error as CXErrorCodeNotificationServiceExtensionError {
            require(error.code == .invalidClientProcess, "voip fail code")
            require(
                CXErrorCodeNotificationServiceExtensionError.errorDomain
                    == CXErrorDomainNotificationServiceExtension,
                "voip domain"
            )
        } catch {
            fatalError("wrong voip error \(error)")
        }

        let provider = CXProvider(configuration: CXProviderConfiguration())
        provider.setDelegate(TestProviderDelegate(), queue: nil)
        let controller = CXCallController(queue: DispatchQueue(label: "callkit-test-controller"))
        do {
            try await controller.request(CXTransaction(actions: []))
            fatalError("empty transaction must fail")
        } catch {
            requireRequestError(error, .emptyTransaction)
        }

        do {
            try await controller.requestTransaction(with: CXEndCallAction(call: UUID()))
            fatalError("unknown uuid must fail")
        } catch {
            requireRequestError(error, .unknownCallUUID)
        }
        provider.invalidate()

        do {
            try await CXCallController().requestTransaction(with: CXEndCallAction(call: UUID()))
            fatalError("missing provider must fail")
        } catch {
            requireRequestError(error, .unknownCallProvider)
        }

        do {
            try await CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "none")
            fatalError("reload must fail closed")
        } catch let error as CXErrorCodeCallDirectoryManagerError {
            require(error.code == .noExtensionFound, "reload code")
        } catch {
            fatalError("wrong reload error \(error)")
        }

        do {
            _ = try await CXCallDirectoryManager.sharedInstance.enabledStatusForExtension(
                withIdentifier: "none"
            )
            fatalError("enabled status must fail closed")
        } catch let error as CXErrorCodeCallDirectoryManagerError {
            require(error.code == .noExtensionFound, "status code")
            require(
                CXErrorCodeCallDirectoryManagerError.Code.noExtensionFound ~= error,
                "directory ~="
            )
        } catch {
            fatalError("wrong status error \(error)")
        }

        let settings = await withCheckedContinuation { continuation in
            CXCallDirectoryManager.sharedInstance.openSettings { error in
                continuation.resume(returning: error)
            }
        }
        require((settings as? CXError)?.code == .unentitled, "openSettings fail closed")
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
        if let error = delegate.errors.first as? CXErrorCodeCallDirectoryManagerError {
            require(
                error.code == .unexpectedIncrementalRemoval || error.code == .noExtensionFound,
                "directory complete error"
            )
        }

        let provider = CXCallDirectoryProvider()
        provider.beginRequest(with: CXCallDirectoryExtensionContext())
        require(
            CXCallDirectoryManager.EnabledStatus.disabled.rawValue == 1,
            "enabled status raw"
        )
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

let _callKitRuntimeDone = DispatchSemaphore(value: 0)
Task {
    await CallKitRuntime.main()
    _callKitRuntimeDone.signal()
}
_callKitRuntimeDone.wait()
