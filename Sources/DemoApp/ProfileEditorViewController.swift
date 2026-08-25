// Profile editor sheet. Owner: demo app (M10 showcase).
//
// Presented by the Settings profile card with the M10 modal API
// (`present(_:animated:)`, default .pageSheet): the sheet slides up from the
// bottom over 0.4 s on a critically damped spring while a 20% black dim
// fades in over everything below — navigation bar and tab bar included,
// because the presentation attaches to the window, not to the presenter.
//
// The sheet has no navigation controller of its own (a pageSheet is not a
// nav stack), so it draws its own 56 pt title bar: centered title, trailing
// "Done" button. Done writes the fields back through `onDone` and dismisses.
//
// Two UITextFields exercise the M8 editing model inside a modal: tapping one
// makes it first responder, the caret blinks on the host clock, and typed
// characters (SDL_TEXTINPUT, or a scripted "text" event) land in the field
// that is focused inside the sheet — first-responder state is per window, so
// the sheet's fields take over from anything focused underneath.

import OpenUIKit

public final class ProfileEditorViewController: UIViewController {

    static let barHeight: CGFloat = 56
    static let margin: CGFloat = 20
    static let fieldHeight: CGFloat = 38

    public let nameField = UITextField()
    public let emailField = UITextField()
    let doneButton = UIButton(type: .custom)

    /// Called with the edited values just before the sheet dismisses.
    public var onDone: ((String, String) -> Void)?

    let initialName: String
    let initialEmail: String

    public init(name: String, email: String) {
        initialName = name
        initialEmail = email
        super.init()
    }

    public override func viewDidLoad() {
        title = "Profile"
        view.backgroundColor = .systemGroupedBackground

        let width = view.bounds.width
        let margin = ProfileEditorViewController.margin

        // Title bar.
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: width,
                                       height: ProfileEditorViewController.barHeight))
        bar.autoresizingMask = [.flexibleWidth]
        view.addSubview(bar)

        let heading = UILabel()
        heading.text = "Profile"
        heading.font = .systemFont(ofSize: 17, weight: .semibold)
        heading.textColor = .label
        let hs = heading.intrinsicContentSize
        heading.frame = CGRect(x: ((width - hs.width) / 2).rounded(),
                               y: ((bar.bounds.height - hs.height) / 2).rounded(),
                               width: hs.width, height: hs.height)
        bar.addSubview(heading)

        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.systemBlue, for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        let dw: CGFloat = 60
        doneButton.frame = CGRect(x: width - margin - dw,
                                  y: (bar.bounds.height - 34) / 2,
                                  width: dw, height: 34)
        doneButton.autoresizingMask = [.flexibleLeftMargin]
        doneButton.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?.finish()
        }
        bar.addSubview(doneButton)

        let hairline = UIView(frame: CGRect(x: 0, y: bar.bounds.height - 0.5,
                                            width: width, height: 0.5))
        hairline.backgroundColor = .separator
        hairline.autoresizingMask = [.flexibleWidth]
        bar.addSubview(hairline)

        // Form.
        var y = ProfileEditorViewController.barHeight + 26
        let fieldWidth = width - 2 * margin

        func caption(_ text: String) {
            let l = UILabel()
            l.text = text
            l.font = .systemFont(ofSize: 13)
            l.textColor = .secondaryLabel
            l.frame = CGRect(x: margin + 6, y: y, width: fieldWidth - 12,
                             height: 18)
            l.autoresizingMask = [.flexibleWidth]
            view.addSubview(l)
            y += 24
        }

        func field(_ tf: UITextField, placeholder: String, text: String) {
            tf.borderStyle = .roundedRect
            tf.placeholder = placeholder
            tf.text = text
            tf.font = .systemFont(ofSize: 17)
            tf.frame = CGRect(x: margin, y: y, width: fieldWidth,
                              height: ProfileEditorViewController.fieldHeight)
            tf.autoresizingMask = [.flexibleWidth]
            view.addSubview(tf)
            y += ProfileEditorViewController.fieldHeight + 22
        }

        caption("NAME")
        field(nameField, placeholder: "Your name", text: initialName)
        caption("EMAIL")
        field(emailField, placeholder: "Email address", text: initialEmail)

        let note = UILabel()
        note.text = "This account is used across iCloud, the App Store and "
            + "everything signed in on this device."
        note.font = .systemFont(ofSize: 13)
        note.textColor = .secondaryLabel
        note.numberOfLines = 0
        let ns = note.sizeThatFits(CGSize(width: fieldWidth - 12,
                                          height: .greatestFiniteMagnitude))
        note.frame = CGRect(x: margin + 6, y: y, width: fieldWidth - 12,
                            height: ns.height)
        note.autoresizingMask = [.flexibleWidth]
        view.addSubview(note)
    }

    func finish() {
        nameField.resignFirstResponder()
        emailField.resignFirstResponder()
        onDone?(nameField.text ?? "", emailField.text ?? "")
        dismiss(animated: true)
    }
}
