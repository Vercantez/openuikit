import Foundation
import MessageUI

func testMailComposeResultRawValues() {
    precondition(MFMailComposeResult.cancelled.rawValue == 0)
    precondition(MFMailComposeResult.saved.rawValue == 1)
    precondition(MFMailComposeResult.sent.rawValue == 2)
    precondition(MFMailComposeResult.failed.rawValue == 3)
    precondition(MFMailComposeResult(rawValue: 0) == .cancelled)
    precondition(MFMailComposeResult(rawValue: 1) == .saved)
    precondition(MFMailComposeResult(rawValue: 2) == .sent)
    precondition(MFMailComposeResult(rawValue: 3) == .failed)
    precondition(MFMailComposeResult(rawValue: 4) == nil)
    precondition(MFMailComposeResult.cancelled != .failed)
    precondition(MFMailComposeResult.cancelled.hashValue == MFMailComposeResult.cancelled.hashValue)
    var hasher = Hasher()
    MFMailComposeResult.sent.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMessageComposeResultRawValues() {
    precondition(MessageComposeResult.cancelled.rawValue == 0)
    precondition(MessageComposeResult.sent.rawValue == 1)
    precondition(MessageComposeResult.failed.rawValue == 2)
    precondition(MessageComposeResult(rawValue: 0) == .cancelled)
    precondition(MessageComposeResult(rawValue: 1) == .sent)
    precondition(MessageComposeResult(rawValue: 2) == .failed)
    precondition(MessageComposeResult(rawValue: 3) == nil)
    precondition(MessageComposeResult.cancelled != .sent)
    precondition(MessageComposeResult.failed.hashValue == MessageComposeResult.failed.hashValue)
    var hasher = Hasher()
    MessageComposeResult.cancelled.hash(into: &hasher)
    _ = hasher.finalize()
}

func testDeferredActionRawValues() {
    precondition(MFMailComposeControllerDeferredAction.none.rawValue == 0)
    precondition(MFMailComposeControllerDeferredAction.adjustInsertionPoint.rawValue == 1)
    precondition(MFMailComposeControllerDeferredAction.addMissingRecipients.rawValue == 2)
    precondition(MFMailComposeControllerDeferredAction(rawValue: 0) == MFMailComposeControllerDeferredAction.none)
    precondition(MFMailComposeControllerDeferredAction(rawValue: 1) == .adjustInsertionPoint)
    precondition(MFMailComposeControllerDeferredAction(rawValue: 2) == .addMissingRecipients)
    precondition(MFMailComposeControllerDeferredAction(rawValue: 3) == nil)
    precondition(MFMailComposeControllerDeferredAction.none != .addMissingRecipients)
    precondition(
        MFMailComposeControllerDeferredAction.none.hashValue
            == MFMailComposeControllerDeferredAction.none.hashValue
    )
    var hasher = Hasher()
    MFMailComposeControllerDeferredAction.adjustInsertionPoint.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMailComposeErrorDomain() {
    precondition(MFMailComposeErrorDomain == "MFMailComposeErrorDomain")
    precondition(MFMailComposeError.errorDomain == "MFMailComposeErrorDomain")
    precondition(MFMailComposeError.errorDomain == MFMailComposeErrorDomain)
    precondition(MFMailComposeError._nsErrorDomain == MFMailComposeErrorDomain)
}

func testMailComposeErrorCodes() {
    precondition(MFMailComposeError.Code.saveFailed.rawValue == 0)
    precondition(MFMailComposeError.Code.sendFailed.rawValue == 1)
    precondition(MFMailComposeError.saveFailed == .saveFailed)
    precondition(MFMailComposeError.sendFailed == .sendFailed)
    precondition(MFMailComposeError.Code(rawValue: 0) == .saveFailed)
    precondition(MFMailComposeError.Code(rawValue: 1) == .sendFailed)
    precondition(MFMailComposeError.Code(rawValue: 2) == nil)
    precondition(
        MFMailComposeError.Code.saveFailed.hashValue
            == MFMailComposeError.Code.saveFailed.hashValue
    )
    var hasher = Hasher()
    MFMailComposeError.Code.sendFailed.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMailComposeErrorEqualityAndHash() {
    let empty = MFMailComposeError(.saveFailed)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(empty.errorCode == 0)
    precondition(empty.code == .saveFailed)
    precondition(!empty.localizedDescription.isEmpty)

    let sentinel = MFMailComposeError(.saveFailed, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(empty == MFMailComposeError(.saveFailed))
    precondition(sentinel != empty)
    precondition(empty.hashValue == sentinel.hashValue)

    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    MFMailComposeError(.saveFailed).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testMailComposeErrorPatternMatch() {
    let error: any Error = MFMailComposeError(.sendFailed)
    precondition(MFMailComposeError.Code.sendFailed ~= error)
    precondition(!(MFMailComposeError.Code.saveFailed ~= error))
    do {
        throw MFMailComposeError(.saveFailed)
    } catch let error as MFMailComposeError where error.code == .saveFailed {
        ()
    } catch {
        preconditionFailure("expected Code.saveFailed pattern match")
    }
}

func testMailComposeErrorProtocolConformance() {
    func bridgedDomain<E: Foundation._BridgedStoredNSError>(_: E.Type) -> String {
        E._nsErrorDomain
    }
    func errorTypeName<C: Foundation._ErrorCodeProtocol>(_: C.Type) -> String {
        String(describing: C._ErrorType.self)
    }
    precondition(bridgedDomain(MFMailComposeError.self) == MFMailComposeErrorDomain)
    precondition(
        errorTypeName(MFMailComposeError.Code.self) == String(describing: MFMailComposeError.self)
    )

    let error = MFMailComposeError(.sendFailed)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    _ = error.hashValue

    var seen: Set<Int> = []
    seen.insert(error.hashValue)
    seen.insert(MFMailComposeError(.sendFailed).hashValue)
    precondition(seen.count == 1)
}

func testMailComposeErrorInequality() {
    precondition(MFMailComposeError(.saveFailed) != MFMailComposeError(.sendFailed))
}

func testNotificationAndAttachmentConstants() {
    precondition(
        NSNotification.Name.MFMessageComposeViewControllerTextMessageAvailabilityDidChange.rawValue
            == "MFMessageComposeViewControllerTextMessageAvailabilityDidChangeNotification"
    )
    precondition(
        MFMessageComposeViewControllerTextMessageAvailabilityKey
            == "MFMessageComposeViewControllerTextMessageAvailabilityKey"
    )
    precondition(
        MFMessageComposeViewControllerAttachmentURL
            == "MFMessageComposeViewControllerAttachmentURL"
    )
    precondition(
        MFMessageComposeViewControllerAttachmentAlternateFilename
            == "MFMessageComposeViewControllerAttachmentAlternateFilename"
    )
}

private func messageUIOnMain(_ work: @escaping @Sendable @MainActor () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated(work)
        return
    }
    DispatchQueue.main.sync {
        MainActor.assumeIsolated(work)
    }
}

private final class MailFinishProbe: NSObject, MFMailComposeViewControllerDelegate, @unchecked Sendable {
    var result: MFMailComposeResult?
    var error: (any Error)?

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: (any Error)?
    ) {
        _ = controller
        self.result = result
        self.error = error
    }
}

private final class MessageFinishProbe: NSObject, MFMessageComposeViewControllerDelegate, @unchecked Sendable {
    var result: MessageComposeResult?

    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        _ = controller
        self.result = result
    }
}

func testCanSendMailIsFalse() {
    messageUIOnMain {
        precondition(MFMailComposeViewController.canSendMail() == false)
    }
}

func testMailComposerStoresRecipientsAndBody() {
    messageUIOnMain {
        let composer = MFMailComposeViewController()
        composer.setToRecipients(["to@example.com"])
        composer.setCcRecipients(["cc@example.com"])
        composer.setBccRecipients(["bcc@example.com"])
        composer.setSubject("Subject")
        composer.setMessageBody("<p>Hi</p>", isHTML: true)
        precondition(composer.portableToRecipients == ["to@example.com"])
        precondition(composer.portableCcRecipients == ["cc@example.com"])
        precondition(composer.portableBccRecipients == ["bcc@example.com"])
        precondition(composer.portableSubject == "Subject")
        precondition(composer.portableMessageBody == "<p>Hi</p>")
        precondition(composer.portableMessageBodyIsHTML)
        composer.setToRecipients(nil)
        precondition(composer.portableToRecipients == nil)
    }
}

func testMailComposerStoresAttachments() {
    messageUIOnMain {
        let composer = MFMailComposeViewController()
        let data = Data("hello".utf8)
        composer.addAttachmentData(data, mimeType: "text/plain", fileName: "note.txt")
        precondition(composer.portableAttachments.count == 1)
        precondition(composer.portableAttachments[0].data == data)
        precondition(composer.portableAttachments[0].mimeType == "text/plain")
        precondition(composer.portableAttachments[0].fileName == "note.txt")
    }
}

func testMailComposerPreferredSendingAddress() {
    messageUIOnMain {
        let composer = MFMailComposeViewController()
        composer.setPreferredSendingEmailAddress("from@example.com")
        precondition(composer.portablePreferredSendingEmailAddress == "from@example.com")
    }
}

func testMailComposeDelegateFinishFailedClosed() {
    messageUIOnMain {
        let composer = MFMailComposeViewController()
        let probe = MailFinishProbe()
        composer.mailComposeDelegate = probe
        composer.reportPortableServiceUnavailable()
        precondition(probe.result == .failed)
        let typed = probe.error as? MFMailComposeError
        precondition(typed?.code == .sendFailed)
        precondition((probe.error as NSError?)?.domain == MFMailComposeErrorDomain)
    }
}

func testMessageComposerCapabilityFlags() {
    messageUIOnMain {
        precondition(MFMessageComposeViewController.canSendText() == false)
        precondition(MFMessageComposeViewController.canSendAttachments() == false)
        precondition(MFMessageComposeViewController.canSendSubject() == false)
    }
}

func testIsSupportedAttachmentUTIIsFalse() {
    messageUIOnMain {
        precondition(MFMessageComposeViewController.isSupportedAttachmentUTI("public.jpeg") == false)
        precondition(MFMessageComposeViewController.isSupportedAttachmentUTI("public.plain-text") == false)
    }
}

func testMessageComposerStoresFields() {
    messageUIOnMain {
        let composer = MFMessageComposeViewController()
        composer.recipients = ["+15555550100"]
        composer.body = "hello"
        composer.subject = "subj"
        precondition(composer.recipients == ["+15555550100"])
        precondition(composer.body == "hello")
        precondition(composer.subject == "subj")
        composer.recipients = nil
        composer.body = nil
        composer.subject = nil
        precondition(composer.recipients == nil)
        precondition(composer.body == nil)
        precondition(composer.subject == nil)
    }
}

func testMessageComposerAttachments() {
    messageUIOnMain {
        let composer = MFMessageComposeViewController()
        precondition(composer.attachments == nil)

        let fileURL = URL(fileURLWithPath: "/tmp/messageui-attachment.txt")
        precondition(composer.addAttachmentURL(fileURL, withAlternateFilename: "alt.txt"))
        let httpURL = URL(string: "https://example.invalid/file.txt")!
        precondition(composer.addAttachmentURL(httpURL, withAlternateFilename: nil) == false)
        precondition(
            composer.addAttachmentData(Data("x".utf8), typeIdentifier: "public.plain-text", filename: "x.txt")
        )
        precondition(
            composer.addAttachmentData(Data(), typeIdentifier: "public.data", filename: "") == false
        )

        let stored = composer.attachments
        precondition(stored?.count == 2)
        precondition(stored?[0][MFMessageComposeViewControllerAttachmentURL] as? URL == fileURL)
        precondition(
            stored?[0][MFMessageComposeViewControllerAttachmentAlternateFilename] as? String == "alt.txt"
        )
        precondition(
            stored?[1][MFMessageComposeViewControllerAttachmentAlternateFilename] as? String == "x.txt"
        )
    }
}

func testMessageComposerDisableUserAttachments() {
    messageUIOnMain {
        let composer = MFMessageComposeViewController()
        precondition(composer.portableUserAttachmentsDisabled == false)
        composer.disableUserAttachments()
        precondition(composer.portableUserAttachmentsDisabled)
        precondition(
            composer.addAttachmentData(Data("y".utf8), typeIdentifier: "public.data", filename: "y.bin")
        )
    }
}

func testMessageComposeDelegateFinishFailedClosed() {
    messageUIOnMain {
        let composer = MFMessageComposeViewController()
        let probe = MessageFinishProbe()
        composer.messageComposeDelegate = probe
        composer.reportPortableServiceUnavailable()
        precondition(probe.result == .failed)
    }
}
