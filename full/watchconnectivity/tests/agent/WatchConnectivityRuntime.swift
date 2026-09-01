import Dispatch
import Foundation
import WatchConnectivity

private let callerQueueKey = DispatchSpecificKey<String>()
private let mainQueueKey = DispatchSpecificKey<String>()

private final class RuntimeDelegate: NSObject, WCSessionDelegate {
    let activationDone = DispatchSemaphore(value: 0)
    let userInfoDone = DispatchSemaphore(value: 0)
    let fileDone = DispatchSemaphore(value: 0)
    let messageErrorDone = DispatchSemaphore(value: 0)

    var activationState: WCSessionActivationState?
    var activationError: (any Error)?
    var finishedUserInfo: WCSessionUserInfoTransfer?
    var finishedUserInfoError: (any Error)?
    var finishedFile: WCSessionFileTransfer?
    var finishedFileError: (any Error)?
    var messageError: (any Error)?
    var becameInactive = false
    var deactivated = false
    var order: [String] = []
    var callbackDepth = 0
    var maxCallbackDepth = 0
    var overlapHold: DispatchSemaphore?
    var onEnter: (() -> Void)?

    private let lock = NSLock()

    private func enterCallback(_ name: String) {
        lock.lock()
        callbackDepth += 1
        if callbackDepth > maxCallbackDepth {
            maxCallbackDepth = callbackDepth
        }
        order.append(name)
        let hold = overlapHold
        let hook = onEnter
        lock.unlock()
        hook?()
        if let hold {
            hold.wait()
        }
        Thread.sleep(forTimeInterval: 0.02)
        lock.lock()
        callbackDepth -= 1
        lock.unlock()
    }

    func snapshotOrder() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return order
    }

    func snapshotMaxDepth() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return maxCallbackDepth
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        _ = session
        self.activationState = activationState
        self.activationError = error
        enterCallback("activate")
        activationDone.signal()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        _ = session
        becameInactive = true
    }

    func sessionDidDeactivate(_ session: WCSession) {
        _ = session
        deactivated = true
    }

    func session(
        _ session: WCSession,
        didFinish userInfoTransfer: WCSessionUserInfoTransfer,
        error: (any Error)?
    ) {
        _ = session
        finishedUserInfo = userInfoTransfer
        finishedUserInfoError = error
        enterCallback("userInfo")
        userInfoDone.signal()
    }

    func session(
        _ session: WCSession,
        didFinish fileTransfer: WCSessionFileTransfer,
        error: (any Error)?
    ) {
        _ = session
        finishedFile = fileTransfer
        finishedFileError = error
        enterCallback("file")
        fileDone.signal()
    }
}

private func wait(_ semaphore: DispatchSemaphore, _ name: String) {
    let result = semaphore.wait(timeout: .now() + 5)
    precondition(result == .success, "timed out waiting for \(name)")
}

private func requireCode(_ error: (any Error)?, _ expected: WCError.Code) {
    guard let error = error as? WCError else {
        fatalError("expected typed WCError, got \(String(describing: error))")
    }
    precondition(error.code == expected)
    precondition(error.errorCode == expected.rawValue)
    precondition(WCError.errorDomain == WCErrorDomain)
    precondition(expected ~= error)
}

private func requireAllErrorCodes() {
    let expected: [(WCError.Code, Int, WCError.Code)] = [
        (.genericError, 7001, WCError.genericError),
        (.sessionNotSupported, 7002, WCError.sessionNotSupported),
        (.sessionMissingDelegate, 7003, WCError.sessionMissingDelegate),
        (.sessionNotActivated, 7004, WCError.sessionNotActivated),
        (.deviceNotPaired, 7005, WCError.deviceNotPaired),
        (.watchAppNotInstalled, 7006, WCError.watchAppNotInstalled),
        (.notReachable, 7007, WCError.notReachable),
        (.invalidParameter, 7008, WCError.invalidParameter),
        (.payloadTooLarge, 7009, WCError.payloadTooLarge),
        (.payloadUnsupportedTypes, 7010, WCError.payloadUnsupportedTypes),
        (.messageReplyFailed, 7011, WCError.messageReplyFailed),
        (.messageReplyTimedOut, 7012, WCError.messageReplyTimedOut),
        (.fileAccessDenied, 7013, WCError.fileAccessDenied),
        (.deliveryFailed, 7014, WCError.deliveryFailed),
        (.insufficientSpace, 7015, WCError.insufficientSpace),
        (.sessionInactive, 7016, WCError.sessionInactive),
        (.transferTimedOut, 7017, WCError.transferTimedOut),
        (.companionAppNotInstalled, 7018, WCError.companionAppNotInstalled),
        (.watchOnlyApp, 7019, WCError.watchOnlyApp),
    ]
    for (code, raw, alias) in expected {
        precondition(code.rawValue == raw)
        precondition(alias == code)
        precondition(WCError.Code(rawValue: raw) == code)
        let error = WCError(code, userInfo: ["k": raw])
        precondition(error.code == code)
        precondition(error.userInfo["k"] as? Int == raw)
        precondition(error.errorUserInfo["k"] as? Int == raw)
        precondition(!error.localizedDescription.isEmpty)
        _ = error.hashValue
        var hasher = Hasher()
        error.hash(into: &hasher)
        _ = hasher.finalize()
        _ = code.hashValue
        var codeHasher = Hasher()
        code.hash(into: &codeHasher)
        _ = codeHasher.finalize()
        precondition(error != WCError(.genericError, userInfo: ["other": true]) || code == .genericError)
        precondition(WCError(code) == WCError(code))
        precondition(!(WCError(code) != WCError(code)))
        if code != .genericError {
            precondition(WCError(code) != WCError(.genericError))
        }
    }
    let empty = WCError(.sessionNotSupported)
    requireCode(empty, .sessionNotSupported)
    precondition(NSDictionary(dictionary: empty.errorUserInfo).isEqual(to: empty.userInfo))
    let bridged = empty as NSError
    precondition(bridged.domain == WCErrorDomain)
    precondition(bridged.code == WCError.sessionNotSupported.rawValue)
    precondition(WCError.Code(rawValue: 0) == nil)
    precondition(WCSessionActivationState(rawValue: 0) == .notActivated)
    precondition(WCSessionActivationState(rawValue: 1) == .inactive)
    precondition(WCSessionActivationState(rawValue: 2) == .activated)
    precondition(WCSessionActivationState(rawValue: 3) == nil)
    precondition(WCSessionActivationState.notActivated != .activated)
    _ = WCSessionActivationState.notActivated.hashValue
    var stateHasher = Hasher()
    WCSessionActivationState.inactive.hash(into: &stateHasher)
    _ = stateHasher.finalize()
}

private func requireFoundationIdentities() {
    let session: WCSession = .default
    let object: NSObject = session
    precondition(object === session)
    precondition(session.isKind(of: NSObject.self))

    let error = WCError(.sessionNotSupported)
    let bridged = error as NSError
    precondition(bridged.domain == WCErrorDomain)
    precondition(bridged.code == WCError.sessionNotSupported.rawValue)

    let string = "ok" as NSString
    let number = NSNumber(value: 3)
    let date = NSDate(timeIntervalSince1970: 0)
    let data = NSData(data: Data([0x01]))
    let array: NSArray = [string, number]
    let dict: NSDictionary = ["k": string, "n": number, "d": date, "b": data, "a": array]
    do {
        try session.updateApplicationContext(dict as! [String: Any])
        fatalError("canonical plist context must still fail closed")
    } catch {
        requireCode(error, .sessionNotSupported)
    }
}

private func requireSessionSurface() {
    let session = WCSession.default
    precondition(session === WCSession.default)
    precondition(!WCSession.isSupported())
    precondition(session.activationState == .notActivated)
    precondition(!session.hasContentPending)
    precondition(!session.isPaired)
    precondition(!session.isWatchAppInstalled)
    precondition(!session.isComplicationEnabled)
    precondition(session.watchDirectoryURL == nil)
    precondition(!session.isReachable)
    precondition(session.remainingComplicationUserInfoTransfers == 0)
    precondition(session.applicationContext.isEmpty)
    precondition(session.receivedApplicationContext.isEmpty)
    precondition(session.outstandingFileTransfers.isEmpty)
    precondition(session.outstandingUserInfoTransfers.isEmpty)
}

private func requireDelegateQueueContract() {
    DispatchQueue.main.setSpecific(key: mainQueueKey, value: "main")
    let caller = DispatchQueue(label: "watchconnectivity.runtime.caller")
    caller.setSpecific(key: callerQueueKey, value: "caller")

    let session = WCSession.default
    let delegate = RuntimeDelegate()
    let entered = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    let returned = DispatchSemaphore(value: 0)
    delegate.onEnter = {
        precondition(DispatchQueue.getSpecific(key: callerQueueKey) != "caller")
        precondition(DispatchQueue.getSpecific(key: mainQueueKey) != "main")
        precondition(!Thread.isMainThread)
        entered.signal()
        release.wait()
    }
    session.delegate = delegate

    caller.async {
        session.activate()
        returned.signal()
    }

    wait(returned, "activate-return")
    wait(entered, "activate-enter")
    release.signal()
    wait(delegate.activationDone, "activation")
    requireCode(delegate.activationError, .sessionNotSupported)
    precondition(delegate.activationState == .notActivated)
    precondition(!delegate.becameInactive)
    precondition(!delegate.deactivated)
    session.delegate = nil
}

private func requireCallbackOrderingAndNoOverlap() {
    let session = WCSession.default
    let delegate = RuntimeDelegate()
    let hold = DispatchSemaphore(value: 0)
    delegate.overlapHold = hold
    session.delegate = delegate

    session.activate()
    _ = session.transferUserInfo(["k": "v"])
    let temp = FileManager.default.temporaryDirectory
        .appendingPathComponent("watchconnectivity-order-\(UUID().uuidString).txt")
    try! Data("payload".utf8).write(to: temp)
    _ = session.transferFile(temp, metadata: ["n": 1])

    let firstEntered = DispatchSemaphore(value: 0)
    DispatchQueue.global().async {
        Thread.sleep(forTimeInterval: 0.05)
        firstEntered.signal()
        hold.signal()
        hold.signal()
        hold.signal()
    }
    wait(delegate.activationDone, "order-activate")
    wait(delegate.userInfoDone, "order-userInfo")
    wait(delegate.fileDone, "order-file")
    wait(firstEntered, "overlap-hold-released")
    precondition(delegate.snapshotOrder() == ["activate", "userInfo", "file"])
    precondition(delegate.snapshotMaxDepth() == 1)
    try? FileManager.default.removeItem(at: temp)
    session.delegate = nil
}

private func requireActivationAndMessaging() {
    let session = WCSession.default
    session.delegate = nil
    session.activate()

    let delegate = RuntimeDelegate()
    session.delegate = delegate
    session.activate()
    wait(delegate.activationDone, "activation")
    precondition(delegate.activationState == .notActivated)
    requireCode(delegate.activationError, .sessionNotSupported)
    precondition(!delegate.becameInactive)
    precondition(!delegate.deactivated)

    var replyCalled = false
    session.sendMessage(["ok": true], replyHandler: { _ in replyCalled = true }) { error in
        delegate.messageError = error
        delegate.messageErrorDone.signal()
    }
    wait(delegate.messageErrorDone, "sendMessage-error")
    precondition(!replyCalled)
    requireCode(delegate.messageError, .sessionNotSupported)

    var dataReplyCalled = false
    delegate.messageError = nil
    session.sendMessageData(
        Data([0x01]),
        replyHandler: { _ in dataReplyCalled = true },
        errorHandler: { error in
            delegate.messageError = error
            delegate.messageErrorDone.signal()
        }
    )
    wait(delegate.messageErrorDone, "sendMessageData-error")
    precondition(!dataReplyCalled)
    requireCode(delegate.messageError, .sessionNotSupported)

    session.sendMessage(["bad": URL(fileURLWithPath: "/tmp")], replyHandler: nil) { error in
        delegate.messageError = error
        delegate.messageErrorDone.signal()
    }
    wait(delegate.messageErrorDone, "sendMessage-invalid")
    requireCode(delegate.messageError, .payloadUnsupportedTypes)

    do {
        try session.updateApplicationContext(["theme": "dark"])
        fatalError("updateApplicationContext must fail closed")
    } catch {
        requireCode(error, .sessionNotSupported)
    }
    do {
        try session.updateApplicationContext(["url": URL(fileURLWithPath: "/tmp")])
        fatalError("invalid application context must be rejected")
    } catch {
        requireCode(error, .payloadUnsupportedTypes)
    }
    do {
        try session.updateApplicationContext(["null": NSNull()])
        fatalError("NSNull must be rejected")
    } catch {
        requireCode(error, .payloadUnsupportedTypes)
    }

    let nestedOK: [String: Any] = [
        "s": "hello",
        "n": NSNumber(value: 1),
        "b": true,
        "date": Date(timeIntervalSince1970: 0),
        "data": Data([0x02]),
        "arr": ["a", NSNumber(value: 2), true],
        "dict": ["inner": "value", "count": NSNumber(value: 3)],
    ]
    do {
        try session.updateApplicationContext(nestedOK)
        fatalError("nested plist must still fail closed")
    } catch {
        requireCode(error, .sessionNotSupported)
    }

    let nestedNull: [String: Any] = ["outer": ["inner": NSNull()]]
    do {
        try session.updateApplicationContext(nestedNull)
        fatalError("nested NSNull must be rejected")
    } catch {
        requireCode(error, .payloadUnsupportedTypes)
    }

    let nestedBadKeys = NSMutableDictionary()
    nestedBadKeys[NSNumber(value: 1)] = "nope"
    do {
        try session.updateApplicationContext(["wrapped": nestedBadKeys])
        fatalError("non-string dictionary keys must be rejected")
    } catch {
        requireCode(error, .payloadUnsupportedTypes)
    }

    precondition(session.applicationContext.isEmpty)
    session.delegate = nil
}

private func requireTransfers() {
    let session = WCSession.default
    let delegate = RuntimeDelegate()
    session.delegate = delegate

    let info = session.transferUserInfo(["key": "value"])
    precondition(!info.isTransferring)
    wait(delegate.userInfoDone, "transferUserInfo")
    precondition(info.userInfo["key"] as? String == "value")
    precondition(!info.isCurrentComplicationInfo)
    requireCode(delegate.finishedUserInfoError, .sessionNotSupported)
    precondition(delegate.finishedUserInfo === info)
    info.cancel()
    precondition(!info.isTransferring)
    precondition(session.outstandingUserInfoTransfers.isEmpty)
    precondition(WCSessionUserInfoTransfer.supportsSecureCoding)

    let complication = session.transferCurrentComplicationUserInfo(["c": 1])
    precondition(complication.isCurrentComplicationInfo)
    wait(delegate.userInfoDone, "complication")
    precondition(complication.userInfo["c"] as? Int == 1)
    requireCode(delegate.finishedUserInfoError, .sessionNotSupported)

    let invalidInfo = session.transferUserInfo(["u": URL(fileURLWithPath: "/tmp")])
    wait(delegate.userInfoDone, "invalid-userInfo")
    precondition(!invalidInfo.isTransferring)
    requireCode(delegate.finishedUserInfoError, .payloadUnsupportedTypes)

    let missing = URL(fileURLWithPath: "/tmp/watchconnectivity-missing-\(UUID().uuidString)")
    let missingTransfer = session.transferFile(missing, metadata: nil)
    wait(delegate.fileDone, "missing-file")
    precondition(!missingTransfer.isTransferring)
    precondition(missingTransfer.file.fileURL == missing)
    precondition(missingTransfer.file.metadata == nil)
    requireCode(delegate.finishedFileError, .fileAccessDenied)
    missingTransfer.cancel()

    let temp = FileManager.default.temporaryDirectory
        .appendingPathComponent("watchconnectivity-\(UUID().uuidString).txt")
    try! Data("payload".utf8).write(to: temp)
    let fileTransfer = session.transferFile(temp, metadata: ["n": 1])
    wait(delegate.fileDone, "file-transfer")
    precondition(!fileTransfer.isTransferring)
    precondition(fileTransfer.file.metadata?["n"] as? Int == 1)
    precondition(fileTransfer.progress.isCancelled)
    requireCode(delegate.finishedFileError, .sessionNotSupported)
    try? FileManager.default.removeItem(at: temp)
    precondition(session.outstandingFileTransfers.isEmpty)

    let badMeta = session.transferFile(temp, metadata: ["u": URL(fileURLWithPath: "/tmp")])
    wait(delegate.fileDone, "bad-metadata")
    requireCode(delegate.finishedFileError, .payloadUnsupportedTypes)
    _ = badMeta

    let notFile = session.transferFile(URL(string: "https://example.invalid/watch")!, metadata: nil)
    wait(delegate.fileDone, "not-file-url")
    requireCode(delegate.finishedFileError, .invalidParameter)
    _ = notFile

    let nullMeta = session.transferFile(temp, metadata: ["n": NSNull()])
    wait(delegate.fileDone, "null-metadata")
    requireCode(delegate.finishedFileError, .payloadUnsupportedTypes)
    _ = nullMeta

    final class EmptyCoder: NSCoder {}
    precondition(WCSessionUserInfoTransfer(coder: EmptyCoder()) == nil)
    session.delegate = nil
}

requireAllErrorCodes()
requireFoundationIdentities()
requireSessionSurface()
requireDelegateQueueContract()
requireCallbackOrderingAndNoOverlap()
requireActivationAndMessaging()
requireTransfers()
print("WATCHCONNECTIVITY_AGENT_RUNTIME_OK")
