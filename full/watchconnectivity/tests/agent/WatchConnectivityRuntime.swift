import Foundation
import WatchConnectivity

private final class RuntimeDelegate: NSObject, WCSessionDelegate {
    var activationState: WCSessionActivationState?
    var activationError: (any Error)?
    var finishedUserInfo: WCSessionUserInfoTransfer?
    var finishedUserInfoError: (any Error)?
    var finishedFile: WCSessionFileTransfer?
    var finishedFileError: (any Error)?
    var becameInactive = false
    var deactivated = false

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        _ = session
        self.activationState = activationState
        self.activationError = error
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
    }

    func session(
        _ session: WCSession,
        didFinish fileTransfer: WCSessionFileTransfer,
        error: (any Error)?
    ) {
        _ = session
        finishedFile = fileTransfer
        finishedFileError = error
    }
}

private func requireCode(_ error: (any Error)?, _ expected: WCError.Code) {
    guard let error = error as? WCError else {
        fatalError("expected typed WCError, got \(String(describing: error))")
    }
    precondition(error.code == expected)
    precondition(error.errorCode == expected.rawValue)
    precondition(WCError.errorDomain == WCErrorDomain)
    precondition(NSDictionary(dictionary: error.errorUserInfo).isEqual(to: error.userInfo))
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

private func requireActivationAndMessaging() {
    let session = WCSession.default
    session.delegate = nil
    session.activate()

    let delegate = RuntimeDelegate()
    session.delegate = delegate
    session.activate()
    precondition(delegate.activationState == .notActivated)
    requireCode(delegate.activationError, .sessionNotSupported)
    precondition(!delegate.becameInactive)
    precondition(!delegate.deactivated)

    var replyCalled = false
    var sendError: (any Error)?
    session.sendMessage(["ok": true], replyHandler: { _ in replyCalled = true }) { error in
        sendError = error
    }
    precondition(!replyCalled)
    requireCode(sendError, .sessionNotSupported)

    var dataReplyCalled = false
    var dataError: (any Error)?
    session.sendMessageData(
        Data([0x01]),
        replyHandler: { _ in dataReplyCalled = true },
        errorHandler: { error in dataError = error }
    )
    precondition(!dataReplyCalled)
    requireCode(dataError, .sessionNotSupported)

    var invalidError: (any Error)?
    session.sendMessage(["bad": URL(fileURLWithPath: "/tmp")], replyHandler: nil) { error in
        invalidError = error
    }
    requireCode(invalidError, .payloadUnsupportedTypes)

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
    precondition(session.applicationContext.isEmpty)
}

private func requireTransfers() {
    let session = WCSession.default
    let delegate = RuntimeDelegate()
    session.delegate = delegate

    let info = session.transferUserInfo(["key": "value"])
    precondition(!info.isTransferring)
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
    precondition(complication.userInfo["c"] as? Int == 1)
    requireCode(delegate.finishedUserInfoError, .sessionNotSupported)

    let invalidInfo = session.transferUserInfo(["u": URL(fileURLWithPath: "/tmp")])
    precondition(!invalidInfo.isTransferring)
    requireCode(delegate.finishedUserInfoError, .payloadUnsupportedTypes)

    let missing = URL(fileURLWithPath: "/tmp/watchconnectivity-missing-\(UUID().uuidString)")
    let missingTransfer = session.transferFile(missing, metadata: nil)
    precondition(!missingTransfer.isTransferring)
    precondition(missingTransfer.file.fileURL == missing)
    precondition(missingTransfer.file.metadata == nil)
    requireCode(delegate.finishedFileError, .fileAccessDenied)
    missingTransfer.cancel()

    let temp = FileManager.default.temporaryDirectory
        .appendingPathComponent("watchconnectivity-\(UUID().uuidString).txt")
    try! Data("payload".utf8).write(to: temp)
    let fileTransfer = session.transferFile(temp, metadata: ["n": 1])
    precondition(!fileTransfer.isTransferring)
    precondition(fileTransfer.file.metadata?["n"] as? Int == 1)
    precondition(fileTransfer.progress.isCancelled)
    requireCode(delegate.finishedFileError, .sessionNotSupported)
    try? FileManager.default.removeItem(at: temp)
    precondition(session.outstandingFileTransfers.isEmpty)

    let badMeta = session.transferFile(temp, metadata: ["u": URL(fileURLWithPath: "/tmp")])
    requireCode(delegate.finishedFileError, .payloadUnsupportedTypes)
    _ = badMeta

    let notFile = session.transferFile(URL(string: "https://example.invalid/watch")!, metadata: nil)
    requireCode(delegate.finishedFileError, .invalidParameter)
    _ = notFile

    final class EmptyCoder: NSCoder {}
    precondition(WCSessionUserInfoTransfer(coder: EmptyCoder()) == nil)
}

requireAllErrorCodes()
requireSessionSurface()
requireActivationAndMessaging()
requireTransfers()
print("WATCHCONNECTIVITY_AGENT_RUNTIME_OK")
