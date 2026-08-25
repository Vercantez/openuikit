// Text-input demo app (M8). Owner: text-input module.
//
// `openhost --app textdemo`: a small form screen exercising the editing
// model end to end — two UITextFields (name / email style), a multiline
// UITextView (notes), and a label mirroring the name field's live
// .editingChanged text. Tap a field: it becomes first responder and the
// caret appears (2 pt tint bar blinking on the host clock); type on the
// real keyboard (SDL_TEXTINPUT) or drive it with a --script.

import OpenUIKit

public enum TextDemoApp {
    public static let windowSize = CGSize(width: 390, height: 560)

    public static func makeRootViewController() -> UINavigationController {
        UINavigationController(rootViewController: TextDemoRootViewController())
    }
}

final class TextDemoRootViewController: UIViewController {
    let nameField = UITextField()
    let emailField = UITextField()
    let notesView = UITextView()
    let mirrorLabel = UILabel()

    override func viewDidLoad() {
        title = "Text Input"
        view.backgroundColor = .systemGroupedBackground

        let margin: CGFloat = 20
        let width = view.bounds.width - 2 * margin
        var y: CGFloat = 24

        func caption(_ text: String) {
            let l = UILabel()
            l.text = text
            l.font = .systemFont(ofSize: 13)
            l.textColor = .secondaryLabel
            l.frame = CGRect(x: margin + 6, y: y, width: width - 12, height: 18)
            l.autoresizingMask = [.flexibleWidth]
            view.addSubview(l)
            y += 24
        }

        caption("NAME")
        nameField.borderStyle = .roundedRect
        nameField.placeholder = "Your name"
        nameField.frame = CGRect(x: margin, y: y, width: width, height: 34)
        nameField.autoresizingMask = [.flexibleWidth]
        view.addSubview(nameField)
        y += 46

        caption("EMAIL")
        emailField.borderStyle = .roundedRect
        emailField.placeholder = "Email address"
        emailField.frame = CGRect(x: margin, y: y, width: width, height: 34)
        emailField.autoresizingMask = [.flexibleWidth]
        view.addSubview(emailField)
        y += 46

        caption("NOTES")
        notesView.font = .systemFont(ofSize: 17)
        notesView.frame = CGRect(x: margin, y: y, width: width, height: 120)
        notesView.autoresizingMask = [.flexibleWidth]
        notesView.layer.cornerRadius = 10
        view.addSubview(notesView)
        y += 132

        mirrorLabel.font = .systemFont(ofSize: 15)
        mirrorLabel.textColor = .secondaryLabel
        mirrorLabel.frame = CGRect(x: margin + 6, y: y, width: width - 12,
                                   height: 20)
        mirrorLabel.autoresizingMask = [.flexibleWidth]
        view.addSubview(mirrorLabel)
        updateMirror()

        nameField.addTarget(for: [.editingChanged, .editingDidBegin,
                                  .editingDidEnd]) { [weak self] _, _ in
            self?.updateMirror()
        }
    }

    func updateMirror() {
        let name = nameField.text ?? ""
        mirrorLabel.text = "Name: " + (name.isEmpty ? "\u{2014}" : name)
    }
}
