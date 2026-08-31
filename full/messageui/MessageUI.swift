// Portable MessageUI mail-composer surface. The controller preserves all
// caller-provided composition state and delegate identity. Since Linux has no
// configured iOS Mail service, capability reporting is explicitly false.

import Foundation
@_exported import UIKit

public enum MFMailComposeResult: Int, Sendable {
    case cancelled = 0
    case saved = 1
    case sent = 2
    case failed = 3
}

public enum MFMailComposeError: Error, Equatable, Sendable {
    case serviceUnavailable
}

@preconcurrency @MainActor
public protocol MFMailComposeViewControllerDelegate: AnyObject {
    nonisolated func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    )
}

@preconcurrency @MainActor
open class MFMailComposeViewController: UINavigationController {
    open weak var mailComposeDelegate: MFMailComposeViewControllerDelegate?

    public private(set) var portableToRecipients: [String]?
    public private(set) var portableCcRecipients: [String]?
    public private(set) var portableBccRecipients: [String]?
    public private(set) var portableSubject = ""
    public private(set) var portableMessageBody = ""
    public private(set) var portableMessageBodyIsHTML = false

    open class func canSendMail() -> Bool { false }

    open func setToRecipients(_ recipients: [String]?) {
        portableToRecipients = recipients
    }

    open func setCcRecipients(_ recipients: [String]?) {
        portableCcRecipients = recipients
    }

    open func setBccRecipients(_ recipients: [String]?) {
        portableBccRecipients = recipients
    }

    open func setSubject(_ subject: String) {
        portableSubject = subject
    }

    open func setMessageBody(_ body: String, isHTML: Bool) {
        portableMessageBody = body
        portableMessageBodyIsHTML = isHTML
    }

    open func addAttachmentData(
        _ attachment: Data,
        mimeType: String,
        fileName: String
    ) {
        portableAttachments.append(
            Attachment(data: attachment, mimeType: mimeType, fileName: fileName)
        )
    }

    public struct Attachment: Sendable {
        public let data: Data
        public let mimeType: String
        public let fileName: String
    }

    public private(set) var portableAttachments: [Attachment] = []

    /// Deterministic host hook used by platform shells that choose to present
    /// their own mail UI. It never reports a fabricated successful send.
    open func reportPortableServiceUnavailable() {
        mailComposeDelegate?.mailComposeController(
            self,
            didFinishWith: .failed,
            error: MFMailComposeError.serviceUnavailable
        )
    }
}
