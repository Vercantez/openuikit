import Foundation
import Messages

func messagesConversationCapturedError(
    _ body: (@escaping (Error?) -> Void) -> Void
) -> NSError? {
    var captured: Error?
    body { captured = $0 }
    return captured as NSError?
}

func testConversationParticipants() {
    let conversation = MSConversation()
    let nullSender = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    precondition(conversation.localParticipantIdentifier != nullSender)
    precondition(conversation.remoteParticipantIdentifiers.isEmpty)
}

func testSelectedMessageNil() {
    let conversation = MSConversation()
    precondition(conversation.selectedMessage == nil)
}

func testInsertTextFailsClosed() {
    let conversation = MSConversation()
    let error = messagesConversationCapturedError { handler in
        conversation.insertText("hello", completionHandler: handler)
    }
    precondition(error?.domain == MSMessagesErrorDomain)
    precondition(error?.code == MSMessageErrorCode.sendWhileNotVisible.rawValue)
}

func testInsertMessageFailsClosed() {
    let conversation = MSConversation()
    let error = messagesConversationCapturedError { handler in
        conversation.insert(MSMessage(), completionHandler: handler)
    }
    precondition(error?.code == MSMessageErrorCode.sendWhileNotVisible.rawValue)
}

func testInsertStickerFailsClosed() {
    let sticker = messagesMakePNGSticker()
    let conversation = MSConversation()
    let error = messagesConversationCapturedError { handler in
        conversation.insert(sticker, completionHandler: handler)
    }
    precondition(error?.code == MSMessageErrorCode.sendWhileNotVisible.rawValue)
}

func testInsertAttachmentRejectsNonFileURL() {
    let conversation = MSConversation()
    let error = messagesConversationCapturedError { handler in
        conversation.insertAttachment(
            URL(string: "https://example.com/file.png")!,
            withAlternateFilename: "file.png",
            completionHandler: handler
        )
    }
    precondition(error?.code == MSMessageErrorCode.improperFileURL.rawValue)
}

func testInsertAttachmentFailsClosedForValidFile() {
    let url = messagesWriteTempPNG()
    let conversation = MSConversation()
    let error = messagesConversationCapturedError { handler in
        conversation.insertAttachment(
            url,
            withAlternateFilename: "sticker.png",
            completionHandler: handler
        )
    }
    precondition(error?.code == MSMessageErrorCode.sendWhileNotVisible.rawValue)
}

func testSendTextFailsClosed() {
    let conversation = MSConversation()
    let error = messagesConversationCapturedError { handler in
        conversation.sendText("hello", completionHandler: handler)
    }
    precondition(error?.code == MSMessageErrorCode.sendWhileNotVisible.rawValue)
}

func testSendMessageFailsClosed() {
    let conversation = MSConversation()
    let error = messagesConversationCapturedError { handler in
        conversation.send(MSMessage(), completionHandler: handler)
    }
    precondition(error?.code == MSMessageErrorCode.sendWhileNotVisible.rawValue)
}

func testSendStickerFailsClosed() {
    let sticker = messagesMakePNGSticker()
    let conversation = MSConversation()
    let error = messagesConversationCapturedError { handler in
        conversation.send(sticker, completionHandler: handler)
    }
    precondition(error?.code == MSMessageErrorCode.sendWhileNotVisible.rawValue)
}

func testSendAttachmentFailsClosed() {
    let url = messagesWriteTempPNG()
    let conversation = MSConversation()
    let error = messagesConversationCapturedError { handler in
        conversation.sendAttachment(
            url,
            withAlternateFilename: nil,
            completionHandler: handler
        )
    }
    precondition(error?.code == MSMessageErrorCode.sendWhileNotVisible.rawValue)
}

func testInsertAttachmentMissingFile() {
    let conversation = MSConversation()
    let missing = URL(fileURLWithPath: "/tmp/messages-missing-\(UUID().uuidString).png")
    let error = messagesConversationCapturedError { handler in
        conversation.insertAttachment(
            missing,
            withAlternateFilename: nil,
            completionHandler: handler
        )
    }
    precondition(error?.code == MSMessageErrorCode.fileNotFound.rawValue)
}
