import Foundation
import WatchConnectivity

private final class RecordingSessionDelegate: NSObject, WCSessionDelegate {
    var activationState: WCSessionActivationState?
    var activationError: (any Error)?
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
}

func testWCSessionClassIdentity() {
    let session = WCSession.default
    let object: NSObject = session
    precondition(object === session)
    precondition(session.isKind(of: NSObject.self))
    precondition(type(of: session) == WCSession.self)
}

func testWCSessionIsSupportedFalse() {
    precondition(WCSession.isSupported() == false)
}

func testWCSessionDefaultIdentity() {
    precondition(WCSession.default === WCSession.default)
}

func testWCSessionActivateStaysNotActivated() {
    let session = WCSession.default
    session.delegate = nil
    session.activate()
    precondition(session.activationState == .notActivated)
    precondition(!WCSession.isSupported())
}

func testWCSessionSendMessageNeverReplies() {
    var replyCalled = false
    WCSession.default.sendMessage(
        ["ok": true],
        replyHandler: { _ in replyCalled = true },
        errorHandler: nil
    )
    precondition(!replyCalled)

    var invalidReplyCalled = false
    WCSession.default.sendMessage(
        ["bad": URL(fileURLWithPath: "/tmp")],
        replyHandler: { _ in invalidReplyCalled = true },
        errorHandler: nil
    )
    precondition(!invalidReplyCalled)
}

func testWCSessionSendMessageDataNeverReplies() {
    var replyCalled = false
    WCSession.default.sendMessageData(
        Data([0x01]),
        replyHandler: { _ in replyCalled = true },
        errorHandler: nil
    )
    precondition(!replyCalled)
}

func testWCSessionTransferCurrentComplicationUserInfo() {
    let transfer = WCSession.default.transferCurrentComplicationUserInfo(["c": 1])
    precondition(transfer.isCurrentComplicationInfo)
    precondition(!transfer.isTransferring)
    precondition(transfer.userInfo["c"] as? Int == 1)
    precondition(WCSession.default.remainingComplicationUserInfoTransfers == 0)
}

func testWCSessionTransferFileFailClosed() {
    let session = WCSession.default
    session.delegate = nil
    let missing = URL(fileURLWithPath: "/tmp/watchconnectivity-missing-\(UUID().uuidString)")
    let missingTransfer = session.transferFile(missing, metadata: nil)
    precondition(!missingTransfer.isTransferring)
    precondition(missingTransfer.file.fileURL == missing)
    precondition(missingTransfer.file.metadata == nil)

    let notFile = session.transferFile(
        URL(string: "https://example.invalid/watch")!,
        metadata: nil
    )
    precondition(!notFile.isTransferring)
    precondition(!notFile.file.fileURL.isFileURL)
}

func testWCSessionTransferUserInfoFailClosed() {
    let transfer = WCSession.default.transferUserInfo(["key": "value"])
    precondition(!transfer.isTransferring)
    precondition(!transfer.isCurrentComplicationInfo)
    precondition(transfer.userInfo["key"] as? String == "value")

    let invalid = WCSession.default.transferUserInfo(["u": URL(fileURLWithPath: "/tmp")])
    precondition(!invalid.isTransferring)
}

func testWCSessionUpdateApplicationContextFailClosed() {
    let session = WCSession.default
    do {
        try session.updateApplicationContext(["theme": "dark"])
        preconditionFailure("updateApplicationContext must fail closed")
    } catch let error as WCError {
        precondition(error.code == .sessionNotSupported)
    } catch {
        preconditionFailure("expected WCError")
    }

    do {
        try session.updateApplicationContext(["null": NSNull()])
        preconditionFailure("NSNull must be rejected")
    } catch let error as WCError {
        precondition(error.code == .payloadUnsupportedTypes)
    } catch {
        preconditionFailure("expected WCError")
    }

    do {
        try session.updateApplicationContext(["url": URL(fileURLWithPath: "/tmp")])
        preconditionFailure("non-plist values must be rejected")
    } catch let error as WCError {
        precondition(error.code == .payloadUnsupportedTypes)
    } catch {
        preconditionFailure("expected WCError")
    }
    precondition(session.applicationContext.isEmpty)
}

func testWCSessionActivationStateNotActivated() {
    precondition(WCSession.default.activationState == .notActivated)
}

func testWCSessionApplicationContextEmpty() {
    precondition(WCSession.default.applicationContext.isEmpty)
}

func testWCSessionIsComplicationEnabledFalse() {
    precondition(WCSession.default.isComplicationEnabled == false)
}

func testWCSessionDelegateRoundTrip() {
    let session = WCSession.default
    let delegate = RecordingSessionDelegate()
    session.delegate = delegate
    precondition(session.delegate === delegate)
    session.delegate = nil
    precondition(session.delegate == nil)
}

func testWCSessionHasContentPendingFalse() {
    precondition(WCSession.default.hasContentPending == false)
}

func testWCSessionOutstandingFileTransfersEmpty() {
    precondition(WCSession.default.outstandingFileTransfers.isEmpty)
}

func testWCSessionOutstandingUserInfoTransfersEmpty() {
    precondition(WCSession.default.outstandingUserInfoTransfers.isEmpty)
}

func testWCSessionIsPairedFalse() {
    precondition(WCSession.default.isPaired == false)
}

func testWCSessionIsReachableFalse() {
    precondition(WCSession.default.isReachable == false)
}

func testWCSessionReceivedApplicationContextEmpty() {
    precondition(WCSession.default.receivedApplicationContext.isEmpty)
}

func testWCSessionRemainingComplicationUserInfoTransfersZero() {
    precondition(WCSession.default.remainingComplicationUserInfoTransfers == 0)
}

func testWCSessionIsWatchAppInstalledFalse() {
    precondition(WCSession.default.isWatchAppInstalled == false)
}

func testWCSessionWatchDirectoryURLNil() {
    precondition(WCSession.default.watchDirectoryURL == nil)
}
