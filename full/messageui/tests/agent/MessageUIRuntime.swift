import Foundation
import MessageUI

/// Schema-v2 host gate compiles `*Tests.swift` and a generated runner, not this
/// file. Keep it as a standalone probe that exercises the same fail-closed
/// composition surface.

func messageUIRuntimeProbe() {
    precondition(MFMailComposeResult.cancelled.rawValue == 0)
    precondition(MFMailComposeResult.saved.rawValue == 1)
    precondition(MFMailComposeResult.sent.rawValue == 2)
    precondition(MFMailComposeResult.failed.rawValue == 3)
    precondition(MessageComposeResult.cancelled.rawValue == 0)
    precondition(MessageComposeResult.sent.rawValue == 1)
    precondition(MessageComposeResult.failed.rawValue == 2)
    precondition(MFMailComposeErrorDomain == "MFMailComposeErrorDomain")
    precondition(MFMailComposeViewController.canSendMail() == false)
    precondition(MFMessageComposeViewController.canSendText() == false)
    precondition(MFMessageComposeViewController.canSendAttachments() == false)
    precondition(MFMessageComposeViewController.canSendSubject() == false)

    let mail = MFMailComposeViewController()
    mail.setSubject("runtime")
    mail.setToRecipients(["runtime@example.com"])
    mail.setMessageBody("body", isHTML: false)
    precondition(mail.portableSubject == "runtime")
    precondition(mail.portableToRecipients == ["runtime@example.com"])

    let message = MFMessageComposeViewController()
    message.body = "runtime-body"
    precondition(message.body == "runtime-body")

    print("MESSAGEUI_AGENT_RUNTIME_OK")
}

messageUIRuntimeProbe()
