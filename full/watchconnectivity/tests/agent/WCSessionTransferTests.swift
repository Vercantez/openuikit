import Foundation
import WatchConnectivity

func testWCSessionFilePayload() {
    let url = URL(fileURLWithPath: "/tmp/watchconnectivity-file-\(UUID().uuidString)")
    let transfer = WCSession.default.transferFile(url, metadata: ["n": 1, "s": "ok"])
    let file = transfer.file
    precondition(file.isKind(of: NSObject.self))
    precondition(file.fileURL == url)
    precondition(file.fileURL.isFileURL)
    precondition(file.metadata?["n"] as? Int == 1)
    precondition(file.metadata?["s"] as? String == "ok")

    let missingMeta = WCSession.default.transferFile(url, metadata: nil).file
    precondition(missingMeta.metadata == nil)
}

func testWCSessionFileTransferCancel() {
    let url = URL(fileURLWithPath: "/tmp/watchconnectivity-file-transfer")
    let transfer = WCSession.default.transferFile(url, metadata: ["k": "v"])
    precondition(transfer.isKind(of: NSObject.self))
    precondition(transfer.file.fileURL == url)
    precondition(transfer.progress.isKind(of: Progress.self))
    precondition(transfer.progress.isCancelled)
    precondition(!transfer.isTransferring)
    transfer.cancel()
    precondition(!transfer.isTransferring)
    precondition(transfer.progress.isCancelled)
}

func testWCSessionUserInfoTransferCancel() {
    let transfer = WCSession.default.transferUserInfo(["s": "hello"])
    precondition(transfer.isKind(of: NSObject.self))
    precondition(!transfer.isCurrentComplicationInfo)
    precondition(!transfer.isTransferring)
    precondition(transfer.userInfo["s"] as? String == "hello")
    transfer.cancel()
    precondition(!transfer.isTransferring)

    let complication = WCSession.default.transferCurrentComplicationUserInfo(["c": true])
    precondition(complication.isCurrentComplicationInfo)
    precondition(complication.userInfo["c"] as? Bool == true)
    precondition(WCSessionUserInfoTransfer.supportsSecureCoding)
}

func testWCSessionUserInfoTransferInitCoderFailClosed() {
    final class EmptyCoder: NSCoder {}
    precondition(WCSessionUserInfoTransfer(coder: EmptyCoder()) == nil)
}
