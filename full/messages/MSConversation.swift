import Foundation

/// Local conversation handle. Linux never attaches to iMessage: insert and
/// send complete synchronously with `MSMessageErrorCode.sendWhileNotVisible`.
open class MSConversation: NSObject {
    public let localParticipantIdentifier: UUID
    public private(set) var remoteParticipantIdentifiers: [UUID]
    public private(set) var selectedMessage: MSMessage?

    public override init() {
        self.localParticipantIdentifier = UUID()
        self.remoteParticipantIdentifiers = []
        self.selectedMessage = nil
        super.init()
    }

    private func failClosed(
        _ completionHandler: ((Error?) -> Void)?
    ) {
        completionHandler?(
            MessagesLinuxSupport.messageError(.sendWhileNotVisible)
        )
    }

    private func failClosedValidatingFile(
        _ url: URL,
        completionHandler: ((Error?) -> Void)?
    ) {
        if !url.isFileURL {
            completionHandler?(
                MessagesLinuxSupport.messageError(.improperFileURL)
            )
            return
        }
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        )
        if !exists {
            completionHandler?(
                MessagesLinuxSupport.messageError(.fileNotFound)
            )
            return
        }
        if isDirectory.boolValue {
            completionHandler?(
                MessagesLinuxSupport.messageError(.improperFileType)
            )
            return
        }
        failClosed(completionHandler)
    }

    open func insert(
        _ message: MSMessage,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        _ = message
        failClosed(completionHandler)
    }

    open func insert(
        _ sticker: MSSticker,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        _ = sticker
        failClosed(completionHandler)
    }

    open func insertText(
        _ text: String,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        _ = text
        failClosed(completionHandler)
    }

    open func insertAttachment(
        _ url: URL,
        withAlternateFilename filename: String?,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        _ = filename
        failClosedValidatingFile(url, completionHandler: completionHandler)
    }

    open func send(
        _ message: MSMessage,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        _ = message
        failClosed(completionHandler)
    }

    open func send(
        _ sticker: MSSticker,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        _ = sticker
        failClosed(completionHandler)
    }

    open func sendText(
        _ text: String,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        _ = text
        failClosed(completionHandler)
    }

    open func sendAttachment(
        _ url: URL,
        withAlternateFilename filename: String?,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        _ = filename
        failClosedValidatingFile(url, completionHandler: completionHandler)
    }
}
