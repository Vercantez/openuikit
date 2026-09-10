// MessageUI — first-party module covering the ladder-corpus call sites
// (12 of 20 apps import it).
//
// Corpus surface (grep scratch/ladder-corpus):
//   MFMailComposeViewController (UINavigationController), canSendMail,
//   setToRecipients, setSubject, setMessageBody(_:isHTML:), addAttachmentData,
//   setBccRecipients, mailComposeDelegate, MFMailComposeResult,
//   MFMessageComposeViewController, canSendText, recipients, body,
//   messageComposeDelegate, MessageComposeResult.
//
// MEASURED PresentProbe mail, iPhone SE 2x / iOS 26.1:
//   canSendMail() == false (mail.flag, 17 bytes). present() hung ~40 s with
//   no completion and no compose pixels. Do not present on the simulator.
//   Cancel/Send chrome is therefore unobserved — the compose form below
//   reuses already-measured nav-bar title items and grouped-table fill
//   (`systemGroupedBackground`), and the report lists Mail-specific pixels
//   as OPEN.
import UIKit

public enum MFMailComposeResult: Int, Sendable {
    case cancelled = 0
    case saved = 1
    case sent = 2
    case failed = 3
}

public enum MessageComposeResult: Int, Sendable {
    case cancelled = 0
    case sent = 1
    case failed = 2
}

@MainActor
public protocol MFMailComposeViewControllerDelegate: NSObjectProtocol {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: (any Error)?
    )
}

@MainActor
public protocol MFMessageComposeViewControllerDelegate: NSObjectProtocol {
    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    )
}

open class MFMailComposeViewController: UINavigationController {
    open weak var mailComposeDelegate: (any MFMailComposeViewControllerDelegate)?

    private var toRecipients: [String]?
    private var ccRecipients: [String]?
    private var bccRecipients: [String]?
    private var subjectText = ""
    private var messageBody = ""
    private var messageBodyIsHTML = false
    private struct Attachment {
        var data: Data
        var mimeType: String
        var fileName: String
    }
    private var attachments: [Attachment] = []
    private weak var form: _MFMailComposeFormController?

    /// MEASURED PresentProbe mail, iPhone SE 2x / iOS 26.1: false.
    open class func canSendMail() -> Bool { false }

    public override init() {
        let form = _MFMailComposeFormController()
        super.init(rootViewController: form)
        self.form = form
        form.composer = self
    }

    /// Required by the base coder initializer; unmeasured, mirrors `init()`.
    public required init?(coder: NSCoder) {
        let form = _MFMailComposeFormController()
        super.init(coder: coder)
        pushViewController(form, animated: false)
        self.form = form
        form.composer = self
    }

    open func setToRecipients(_ toRecipients: [String]?) {
        self.toRecipients = toRecipients
        form?.reloadFields()
    }

    open func setCcRecipients(_ ccRecipients: [String]?) {
        self.ccRecipients = ccRecipients
        form?.reloadFields()
    }

    open func setBccRecipients(_ bccRecipients: [String]?) {
        self.bccRecipients = bccRecipients
        form?.reloadFields()
    }

    open func setSubject(_ subject: String) {
        subjectText = subject
        form?.reloadFields()
    }

    open func setMessageBody(_ body: String, isHTML: Bool) {
        messageBody = body
        messageBodyIsHTML = isHTML
        form?.reloadFields()
    }

    open func addAttachmentData(_ attachment: Data, mimeType: String, fileName: String) {
        attachments.append(Attachment(data: attachment, mimeType: mimeType, fileName: fileName))
    }

    fileprivate func finish(_ result: MFMailComposeResult) {
        mailComposeDelegate?.mailComposeController(self, didFinishWith: result, error: nil)
        dismiss(animated: true, completion: nil)
    }

    fileprivate func currentTo() -> String { Self.join(toRecipients) }
    fileprivate func currentSubject() -> String { subjectText }
    fileprivate func currentBody() -> String { messageBody }

    private static func join(_ values: [String]?) -> String {
        guard let values, !values.isEmpty else { return "" }
        var out = ""
        for (i, value) in values.enumerated() {
            if i > 0 { out += ", " }
            out += value
        }
        return out
    }
}

/// Compose form. Mail-specific Cancel/Send pixels were unobserved
/// (`canSendMail` false; present hung). Nav items use the measured
/// `_UIBarMetrics` title path; the table fill is `systemGroupedBackground`
/// (Forms t200 / grouped fixtures).
final class _MFMailComposeFormController: UIViewController {
    weak var composer: MFMailComposeViewController?
    private let toField = UITextField()
    private let subjectField = UITextField()
    private let bodyView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            primaryAction: UIAction(title: "Cancel") { [weak self] _ in
                self?.composer?.finish(.cancelled)
            })
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            primaryAction: UIAction(title: "Send") { [weak self] _ in
                self?.composer?.finish(.failed)
            })

        toField.placeholder = "To"
        toField.font = .systemFont(ofSize: 17)
        toField.backgroundColor = .secondarySystemGroupedBackground
        subjectField.placeholder = "Subject"
        subjectField.font = .systemFont(ofSize: 17)
        subjectField.backgroundColor = .secondarySystemGroupedBackground
        bodyView.font = .systemFont(ofSize: 17)
        bodyView.backgroundColor = .secondarySystemGroupedBackground
        view.addSubview(toField)
        view.addSubview(subjectField)
        view.addSubview(bodyView)
        reloadFields()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // MEASURED tableview_grouped / Forms t200: grouped inset 16, row 53.
        let inset: CGFloat = 16
        let row: CGFloat = 53
        let y0 = view.safeAreaInsets.top
        let w = view.bounds.width - inset * 2
        toField.frame = CGRect(x: inset, y: y0 + 8, width: w, height: row)
        subjectField.frame = CGRect(x: inset, y: y0 + 8 + row, width: w, height: row)
        let bodyY = y0 + 8 + row * 2
        bodyView.frame = CGRect(
            x: inset, y: bodyY, width: w,
            height: max(80, view.bounds.height - bodyY - inset))
    }

    func reloadFields() {
        guard isViewLoaded else { return }
        toField.text = composer?.currentTo()
        subjectField.text = composer?.currentSubject()
        bodyView.text = composer?.currentBody()
    }
}

open class MFMessageComposeViewController: UIViewController {
    open weak var messageComposeDelegate: (any MFMessageComposeViewControllerDelegate)?
    open var recipients: [String]?
    open var body: String?
    private let bodyView = UITextView()

    /// Unmeasured on this simulator (no Messages). Fail closed false, same
    /// class as canSendMail.
    open class func canSendText() -> Bool { false }

    public init() {
        super.init()
    }

    /// Required by the base coder initializer; unmeasured, mirrors `init()`.
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private let cancelButton = UIButton(type: .system)

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addAction(UIAction { [weak self] _ in
            self?.finish(.cancelled)
        }, for: .touchUpInside)
        view.addSubview(cancelButton)
        bodyView.font = .systemFont(ofSize: 17)
        bodyView.text = body
        view.addSubview(bodyView)
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let inset: CGFloat = 16
        let top = view.safeAreaInsets.top + 8
        cancelButton.frame = CGRect(x: inset, y: top, width: 80, height: 44)
        bodyView.frame = CGRect(
            x: inset, y: top + 52,
            width: view.bounds.width - inset * 2,
            height: max(80, view.bounds.height - top - 52 - inset))
    }

    private func finish(_ result: MessageComposeResult) {
        messageComposeDelegate?.messageComposeViewController(self, didFinishWith: result)
        dismiss(animated: true, completion: nil)
    }
}
