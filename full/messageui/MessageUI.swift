// Portable MessageUI mail- and message-composer surface.
//
// The controllers preserve caller-provided composition state and delegate
// identity. Linux has no configured iOS Mail or Messages service, so every
// capability query is false and no send/save UI is presented. Host-compiled
// sources import Foundation only: UINavigationController is UIKit-owned and
// is used as the superclass only when that module is importable.

import Foundation

/// Apple's `NS_ERROR_ENUM` domain. The string matches the pinned
/// `dotnet/macios` `[ErrorDomain ("MFMailComposeErrorDomain")]` annotation
/// and the TBD export `_MFMailComposeErrorDomain`.
public let MFMailComposeErrorDomain = "MFMailComposeErrorDomain"

/// Dictionary key for an attachment file URL, matching the ObjC constant name
/// exported as `_MFMessageComposeViewControllerAttachmentURL`.
public let MFMessageComposeViewControllerAttachmentURL =
    "MFMessageComposeViewControllerAttachmentURL"

/// Dictionary key for an attachment display name, matching the ObjC constant
/// name exported as `_MFMessageComposeViewControllerAttachmentAlternateFilename`.
public let MFMessageComposeViewControllerAttachmentAlternateFilename =
    "MFMessageComposeViewControllerAttachmentAlternateFilename"

/// User-info key for text-message availability, matching the ObjC constant
/// name exported as `_MFMessageComposeViewControllerTextMessageAvailabilityKey`.
public let MFMessageComposeViewControllerTextMessageAvailabilityKey =
    "MFMessageComposeViewControllerTextMessageAvailabilityKey"

public extension NSNotification.Name {
    /// Posted on Darwin when `canSendText()` changes. Linux never posts it.
    /// Raw value matches the ObjC constant
    /// `MFMessageComposeViewControllerTextMessageAvailabilityDidChangeNotification`.
    static let MFMessageComposeViewControllerTextMessageAvailabilityDidChange =
        NSNotification.Name(
            "MFMessageComposeViewControllerTextMessageAvailabilityDidChangeNotification"
        )
}

/// Result of a mail-compose session. Raw values match the pinned macios
/// `[Native]` enumeration order (`Cancelled`, `Saved`, `Sent`, `Failed`).
public enum MFMailComposeResult: Int, Sendable {
    case cancelled = 0
    case saved = 1
    case sent = 2
    case failed = 3
}

/// Result of a message-compose session. Raw values match the pinned macios
/// `[Native]` enumeration order (`Cancelled`, `Sent`, `Failed`).
public enum MessageComposeResult: Int, Sendable {
    case cancelled = 0
    case sent = 1
    case failed = 2
}

/// Mail-composer deferred action. Raw values match the pinned macios
/// `[Native]` enumeration order (`None`, `AdjustInsertionPoint`,
/// `AddMissingRecipients`).
public enum MFMailComposeControllerDeferredAction: Int, Sendable {
    case none = 0
    case adjustInsertionPoint = 1
    case addMissingRecipients = 2
}

/// Bridged mail-compose error.
///
/// The pinned API digester records a stored `_nsError: NSError` and
/// `init(_nsError:)`. Linux Foundation exposes
/// `Foundation._BridgedStoredNSError` and `Foundation._ErrorCodeProtocol`.
/// Foundation's protocol-default `hash(into:)` / `hashValue` witnesses trap
/// (`__HALT`) on this toolchain, so those two Hashable members are provided
/// here. Typed `NSError as? MFMailComposeError` round-trips are not claimed:
/// Linux Foundation special-cases Cocoa/POSIX/URL errors and does not wrap
/// arbitrary domains.
///
/// `Code` raw values match the pinned macios `[Native]` order
/// (`SaveFailed`, `SendFailed`).
@frozen
public struct MFMailComposeError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = MFMailComposeError

        case saveFailed = 0
        case sendFailed = 1
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { MFMailComposeErrorDomain }

    public static var saveFailed: Code { .saveFailed }
    public static var sendFailed: Code { .sendFailed }

    /// Foundation's `_BridgedStoredNSError` hash witnesses trap on Linux.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

@preconcurrency @MainActor
public protocol MFMailComposeViewControllerDelegate: NSObjectProtocol {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: (any Error)?
    )
}

extension MFMailComposeViewControllerDelegate {
    public func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: (any Error)?
    ) {
        _ = controller
        _ = result
        _ = error
    }
}

@preconcurrency @MainActor
public protocol MFMessageComposeViewControllerDelegate: NSObjectProtocol {
    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    )
}

/// Mail composition controller. Callers may record recipients, subject, body,
/// and attachments; Linux never presents Mail UI or reports a successful send.
/// Isolated host subclasses `NSObject` because UIKit is not a declared
/// dependency. A later UIKit-linked build can restore `UINavigationController`.
@preconcurrency @MainActor
open class MFMailComposeViewController: NSObject {
    open weak var mailComposeDelegate: (any MFMailComposeViewControllerDelegate)?

    public private(set) var portableToRecipients: [String]?
    public private(set) var portableCcRecipients: [String]?
    public private(set) var portableBccRecipients: [String]?
    public private(set) var portableSubject = ""
    public private(set) var portableMessageBody = ""
    public private(set) var portableMessageBodyIsHTML = false
    public private(set) var portablePreferredSendingEmailAddress = ""

    public struct Attachment: Sendable {
        public let data: Data
        public let mimeType: String
        public let fileName: String
    }

    public private(set) var portableAttachments: [Attachment] = []

    open class func canSendMail() -> Bool { false }

    open func setToRecipients(_ toRecipients: [String]?) {
        portableToRecipients = toRecipients
    }

    open func setCcRecipients(_ ccRecipients: [String]?) {
        portableCcRecipients = ccRecipients
    }

    open func setBccRecipients(_ bccRecipients: [String]?) {
        portableBccRecipients = bccRecipients
    }

    open func setSubject(_ subject: String) {
        portableSubject = subject
    }

    open func setMessageBody(_ body: String, isHTML: Bool) {
        portableMessageBody = body
        portableMessageBodyIsHTML = isHTML
    }

    open func setPreferredSendingEmailAddress(_ emailAddress: String) {
        portablePreferredSendingEmailAddress = emailAddress
    }

    open func addAttachmentData(
        _ attachment: Data,
        mimeType: String,
        fileName filename: String
    ) {
        portableAttachments.append(
            Attachment(data: attachment, mimeType: mimeType, fileName: filename)
        )
    }

    /// Deterministic host hook used by platform shells that choose to present
    /// their own mail UI. It never reports a fabricated successful send.
    open func reportPortableServiceUnavailable() {
        mailComposeDelegate?.mailComposeController(
            self,
            didFinishWith: .failed,
            error: MFMailComposeError(.sendFailed)
        )
    }
}

/// Message composition controller. Callers may record recipients, subject,
/// body, and attachments; Linux never presents Messages UI or reports a
/// successful send. Isolated host subclasses `NSObject` because UIKit is
/// not a declared dependency.
@preconcurrency @MainActor
open class MFMessageComposeViewController: NSObject {
    open weak var messageComposeDelegate: (any MFMessageComposeViewControllerDelegate)?

    open var recipients: [String]?
    open var body: String?
    open var subject: String?

    public private(set) var portableUserAttachmentsDisabled = false
    private var storedAttachments: [[AnyHashable: Any]] = []

    open var attachments: [[AnyHashable: Any]]? {
        storedAttachments.isEmpty ? nil : storedAttachments
    }

    open class func canSendText() -> Bool { false }
    open class func canSendAttachments() -> Bool { false }
    open class func canSendSubject() -> Bool { false }

    open class func isSupportedAttachmentUTI(_ uti: String) -> Bool {
        _ = uti
        return false
    }

    @discardableResult
    open func addAttachmentURL(
        _ attachmentURL: URL,
        withAlternateFilename alternateFilename: String?
    ) -> Bool {
        guard attachmentURL.isFileURL else { return false }
        var record: [AnyHashable: Any] = [
            MFMessageComposeViewControllerAttachmentURL: attachmentURL
        ]
        let name = alternateFilename ?? attachmentURL.lastPathComponent
        record[MFMessageComposeViewControllerAttachmentAlternateFilename] = name
        storedAttachments.append(record)
        return true
    }

    @discardableResult
    open func addAttachmentData(
        _ attachmentData: Data,
        typeIdentifier uti: String,
        filename: String
    ) -> Bool {
        guard !filename.isEmpty else { return false }
        _ = attachmentData
        _ = uti
        storedAttachments.append([
            MFMessageComposeViewControllerAttachmentAlternateFilename: filename
        ])
        return true
    }

    open func disableUserAttachments() {
        portableUserAttachmentsDisabled = true
    }

    /// Deterministic host hook used by platform shells that choose to present
    /// their own message UI. It never reports a fabricated successful send.
    open func reportPortableServiceUnavailable() {
        messageComposeDelegate?.messageComposeViewController(
            self,
            didFinishWith: .failed
        )
    }
}
