import Foundation
import MessageUI

// Isolated host-gate success against toolchain Foundation is not integrated
// guest-Foundation success. This probe is for a future clean EC2 run that
// builds guest Foundation first, then MessageUI with that `-I` / `-L`.

func messageUIDependencyIdentityProbe() {
    let data = Data("messageui".utf8)
    let url = URL(fileURLWithPath: "/tmp/messageui-identity.txt")
    let recipients = ["identity@example.com"]
    precondition(type(of: data) == Data.self)
    precondition(type(of: url) == URL.self)
    precondition(!String(reflecting: type(of: data)).hasPrefix("MessageUI."))
    precondition(!String(reflecting: type(of: url)).hasPrefix("MessageUI."))

    precondition(MFMailComposeViewController.canSendMail() == false)
    let mail = MFMailComposeViewController()
    mail.setToRecipients(recipients)
    mail.addAttachmentData(data, mimeType: "text/plain", fileName: "identity.txt")
    precondition(mail.portableToRecipients == recipients)
    precondition(mail.portableAttachments.first?.data == data)

    precondition(MFMessageComposeViewController.canSendText() == false)
    let message = MFMessageComposeViewController()
    message.recipients = ["+15555550199"]
    precondition(message.addAttachmentURL(url, withAlternateFilename: "identity.txt"))
    precondition(message.attachments?.first?[MFMessageComposeViewControllerAttachmentURL] as? URL == url)

    let error = MFMailComposeError(.sendFailed, userInfo: ["probe": data.count])
    precondition(error.errorDomain == MFMailComposeErrorDomain)
    precondition((error as NSError).domain == MFMailComposeErrorDomain)

    print("MESSAGEUI_DEPENDENCY_IDENTITY_OK")
}

messageUIDependencyIdentityProbe()
