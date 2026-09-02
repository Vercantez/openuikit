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
//
// M11: the sheet is INTERACTIVE. It shows the grabber
// (`sheetPresentationController?.prefersGrabberVisible`) and its form lives
// in a UIScrollView taller than the sheet, which is what makes the measured
// sheet/scroll hand-off visible in a real app: dragging down while the form
// is scrolled to the top drags the SHEET (and fades the dim with it), while
// the same drag anywhere else scrolls the form and leaves the sheet put.

import OpenUIKit

public final class ProfileEditorViewController: UIViewController {

    static let barHeight: CGFloat = 56
    static let margin: CGFloat = 20
    static let fieldHeight: CGFloat = 38

    public let nameField = UITextField()
    public let emailField = UITextField()
    public let scrollView = UIScrollView()
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
        sheetPresentationController?.prefersGrabberVisible = true

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

        // Form, inside a scroll view so the sheet/scroll hand-off is live.
        let barH = ProfileEditorViewController.barHeight
        scrollView.frame = CGRect(x: 0, y: barH, width: width,
                                  height: view.bounds.height - barH)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)

        var y: CGFloat = 26
        let fieldWidth = width - 2 * margin

        func caption(_ text: String) {
            let l = UILabel()
            l.text = text
            l.font = .systemFont(ofSize: 13)
            l.textColor = .secondaryLabel
            l.frame = CGRect(x: margin + 6, y: y, width: fieldWidth - 12,
                             height: 18)
            l.autoresizingMask = [.flexibleWidth]
            scrollView.addSubview(l)
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
            scrollView.addSubview(tf)
            y += ProfileEditorViewController.fieldHeight + 22
        }

        func paragraph(_ text: String) {
            let l = UILabel()
            l.text = text
            l.font = .systemFont(ofSize: 13)
            l.textColor = .secondaryLabel
            l.numberOfLines = 0
            let s = l.sizeThatFits(CGSize(width: fieldWidth - 12,
                                          height: .greatestFiniteMagnitude))
            l.frame = CGRect(x: margin + 6, y: y, width: fieldWidth - 12,
                             height: s.height)
            l.autoresizingMask = [.flexibleWidth]
            scrollView.addSubview(l)
            y += s.height + 18
        }

        caption("NAME")
        field(nameField, placeholder: "Your name", text: initialName)
        caption("EMAIL")
        field(emailField, placeholder: "Email address", text: initialEmail)

        paragraph("This account is used across iCloud, the App Store and "
                  + "everything signed in on this device.")
        caption("ABOUT THIS SHEET")
        paragraph("Drag anywhere on this sheet to move it. Release past half "
                  + "its height, or flick down at 1000 points per second, and "
                  + "it dismisses; otherwise it springs back on a critically "
                  + "damped spring. The dim behind it fades in step with the "
                  + "drag — every one of those numbers was measured from real "
                  + "iOS 26 rather than guessed.")
        paragraph("This form scrolls, which is the interesting part. While it "
                  + "sits at the top, a downward drag belongs to the SHEET. "
                  + "Once it has scrolled at all, the same drag belongs to the "
                  + "form, and the sheet stays where it is. Scroll down and "
                  + "try dragging from here.")
        paragraph("Real iOS does not rubber-band a sheet upward past its "
                  + "detent — dragging up simply does nothing — so neither "
                  + "does this one.")

        // Device rows. These exist to make the form TALLER THAN THE SHEET:
        // a scroll view whose content fits never scrolls, and then the sheet
        // would take every downward drag and the hand-off would be untested.
        caption("SIGNED IN ON")
        for (name, detail) in [("iPhone 16 Pro", "This device"),
                               ("MacBook Pro", "Last seen 2 hours ago"),
                               ("iPad Air", "Last seen yesterday"),
                               ("Apple Watch", "Last seen yesterday"),
                               ("Apple TV", "Last seen last week")] {
            let row = UIView(frame: CGRect(x: margin, y: y, width: fieldWidth,
                                           height: 56))
            row.backgroundColor = .secondarySystemGroupedBackground
            row.layer.cornerRadius = 10
            row.autoresizingMask = [.flexibleWidth]

            let title = UILabel()
            title.text = name
            title.font = .systemFont(ofSize: 17)
            title.textColor = .label
            title.frame = CGRect(x: 14, y: 9, width: fieldWidth - 28, height: 20)
            title.autoresizingMask = [.flexibleWidth]
            row.addSubview(title)

            let sub = UILabel()
            sub.text = detail
            sub.font = .systemFont(ofSize: 13)
            sub.textColor = .secondaryLabel
            sub.frame = CGRect(x: 14, y: 30, width: fieldWidth - 28, height: 16)
            sub.autoresizingMask = [.flexibleWidth]
            row.addSubview(sub)

            scrollView.addSubview(row)
            y += 64
        }
        y += 24
        scrollView.contentSize = CGSize(width: width, height: y)
    }

    func finish() {
        nameField.resignFirstResponder()
        emailField.resignFirstResponder()
        onDone?(nameField.text ?? "", emailField.text ?? "")
        dismiss(animated: true)
    }
}
