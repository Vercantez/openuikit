import Foundation
import WatchConnectivity

/// Required-method-only delegate so optional WCSessionDelegate defaults are reachable.
private final class MinimalSessionDelegate: NSObject, WCSessionDelegate {
    var activationCalls = 0
    var inactiveCalls = 0
    var deactivateCalls = 0
    var lastActivationState: WCSessionActivationState?
    var lastActivationError: (any Error)?

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        _ = session
        activationCalls += 1
        lastActivationState = activationState
        lastActivationError = error
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        _ = session
        inactiveCalls += 1
    }

    func sessionDidDeactivate(_ session: WCSession) {
        _ = session
        deactivateCalls += 1
    }
}

func testWCSessionDelegateConformance() {
    let delegate: any WCSessionDelegate = MinimalSessionDelegate()
    precondition(delegate is NSObject)
}

func testSessionActivationDidCompleteWith() {
    let delegate = MinimalSessionDelegate()
    let error = WCError(.sessionNotSupported)
    delegate.session(
        WCSession.default,
        activationDidCompleteWith: .notActivated,
        error: error
    )
    precondition(delegate.activationCalls == 1)
    precondition(delegate.lastActivationState == .notActivated)
    guard let received = delegate.lastActivationError as? WCError else {
        preconditionFailure("expected WCError")
    }
    precondition(received.code == .sessionNotSupported)
    precondition(WCSession.default.activationState == .notActivated)
    precondition(delegate.inactiveCalls == 0)
    precondition(delegate.deactivateCalls == 0)
}

func testSessionDidFinishFileTransfer() {
    let delegate = MinimalSessionDelegate()
    let transfer = WCSession.default.transferFile(
        URL(fileURLWithPath: "/tmp/watchconnectivity-delegate-missing"),
        metadata: nil
    )
    var sawFinish = false
    delegate.session(WCSession.default, didFinish: transfer, error: WCError(.fileAccessDenied))
    sawFinish = true
    precondition(sawFinish)
    precondition(!transfer.isTransferring)
}

func testSessionDidFinishUserInfoTransfer() {
    let delegate = MinimalSessionDelegate()
    let transfer = WCSession.default.transferUserInfo(["k": "v"])
    delegate.session(
        WCSession.default,
        didFinish: transfer,
        error: WCError(.sessionNotSupported)
    )
    precondition(!transfer.isTransferring)
    precondition(transfer.userInfo["k"] as? String == "v")
}

func testSessionDidReceiveApplicationContextDefault() {
    let delegate = MinimalSessionDelegate()
    delegate.session(
        WCSession.default,
        didReceiveApplicationContext: ["theme": "dark"]
    )
    precondition(WCSession.default.receivedApplicationContext.isEmpty)
    precondition(WCSession.default.applicationContext.isEmpty)
    precondition(!WCSession.default.hasContentPending)
}

func testSessionDidReceiveFileDefault() {
    let delegate = MinimalSessionDelegate()
    let file = WCSession.default.transferFile(
        URL(fileURLWithPath: "/tmp/watchconnectivity-incoming-missing"),
        metadata: ["n": 1]
    ).file
    delegate.session(WCSession.default, didReceive: file)
    precondition(WCSession.default.outstandingFileTransfers.isEmpty)
    precondition(!WCSession.default.hasContentPending)
}

func testSessionDidReceiveMessageDefault() {
    let delegate = MinimalSessionDelegate()
    delegate.session(WCSession.default, didReceiveMessage: ["ping": "pong"])
    precondition(!WCSession.default.isReachable)
    precondition(!WCSession.default.hasContentPending)
}

func testSessionDidReceiveMessageReplyHandlerDoesNotReply() {
    let delegate = MinimalSessionDelegate()
    var replies = 0
    delegate.session(WCSession.default, didReceiveMessage: ["ping": true]) { _ in
        replies += 1
    }
    precondition(replies == 0)
    precondition(!WCSession.default.isReachable)
}

func testSessionDidReceiveMessageDataDefault() {
    let delegate = MinimalSessionDelegate()
    delegate.session(WCSession.default, didReceiveMessageData: Data([0x0A]))
    precondition(!WCSession.default.hasContentPending)
}

func testSessionDidReceiveMessageDataReplyHandlerDoesNotReply() {
    let delegate = MinimalSessionDelegate()
    var replies = 0
    delegate.session(
        WCSession.default,
        didReceiveMessageData: Data([0x0B])
    ) { _ in
        replies += 1
    }
    precondition(replies == 0)
}

func testSessionDidReceiveUserInfoDefault() {
    let delegate = MinimalSessionDelegate()
    delegate.session(WCSession.default, didReceiveUserInfo: ["k": "v"])
    delegate.session(WCSession.default, didReceiveUserInfo: [:])
    precondition(WCSession.default.outstandingUserInfoTransfers.isEmpty)
    precondition(!WCSession.default.hasContentPending)
}

func testSessionDidBecomeInactive() {
    let delegate = MinimalSessionDelegate()
    delegate.sessionDidBecomeInactive(WCSession.default)
    precondition(delegate.inactiveCalls == 1)
    precondition(WCSession.default.activationState == .notActivated)
    precondition(delegate.deactivateCalls == 0)
}

func testSessionDidDeactivate() {
    let delegate = MinimalSessionDelegate()
    delegate.sessionDidDeactivate(WCSession.default)
    precondition(delegate.deactivateCalls == 1)
    precondition(WCSession.default.activationState == .notActivated)
    precondition(delegate.inactiveCalls == 0)
}

func testSessionReachabilityDidChangeDefault() {
    let delegate = MinimalSessionDelegate()
    delegate.sessionReachabilityDidChange(WCSession.default)
    precondition(WCSession.default.isReachable == false)
}

func testSessionWatchStateDidChangeDefault() {
    let delegate = MinimalSessionDelegate()
    delegate.sessionWatchStateDidChange(WCSession.default)
    precondition(WCSession.default.isPaired == false)
    precondition(WCSession.default.isWatchAppInstalled == false)
    precondition(WCSession.default.watchDirectoryURL == nil)
}
