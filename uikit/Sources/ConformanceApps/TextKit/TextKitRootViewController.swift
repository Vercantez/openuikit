// TextKit root: UILabel + UITextView with measured 24×24 attachments.
import UIKit

final class TextKitMarkerView: UIView {}

final class TextKitChipProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        let v = TextKitMarkerView()
        v.backgroundColor = UIColor(red: 0.10, green: 0.45, blue: 0.90, alpha: 1)
        v.isUserInteractionEnabled = false
        view = v
    }
}

final class TextKitRootViewController: UIViewController {
    private let titleLabel = UILabel()
    private let inlineLabel = UILabel()
    private let textView = UITextView()
    private var hanging = false
    private var showingProvider = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        NSTextAttachment.registerViewProviderClass(
            TextKitChipProvider.self, forFileType: "public.textkit-chip")

        titleLabel.text = "Attachments"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        inlineLabel.numberOfLines = 1
        inlineLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inlineLabel)

        textView.font = .systemFont(ofSize: 17)
        textView.isEditable = false
        textView.backgroundColor = .secondarySystemBackground
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        applyDefaultString()

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inlineLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            inlineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.topAnchor.constraint(equalTo: inlineLabel.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 120),
        ])
    }

    func showHanging() {
        hanging = true
        showingProvider = false
        applyDefaultString()
    }

    func showProvider() {
        hanging = false
        showingProvider = true
        applyDefaultString()
    }

    private func applyDefaultString() {
        let bodyFont = UIFont.systemFont(ofSize: 17)
        let s = NSMutableAttributedString(string: "A", attributes: [
            NSAttributedString.Key.font: bodyFont,
            NSAttributedString.Key.foregroundColor: UIColor.label
        ])
        if showingProvider {
            let att = NSTextAttachment()
            att.fileType = "public.textkit-chip"
            att.bounds = CGRect(x: 0, y: 0, width: 24, height: 24)
            s.append(NSAttributedString(attachment: att))
        } else {
            let att = NSTextAttachment()
            att.image = Self.solidImage(size: CGSize(width: 24, height: 24),
                                        color: UIColor(red: 0.90, green: 0.15, blue: 0.15, alpha: 1))
            if hanging {
                att.bounds = CGRect(x: 0, y: -24, width: 24, height: 24)
            }
            s.append(NSAttributedString(attachment: att))
        }
        s.append(NSAttributedString(string: "B", attributes: [
            NSAttributedString.Key.font: bodyFont,
            NSAttributedString.Key.foregroundColor: UIColor.label
        ]))
        inlineLabel.attributedText = s
        inlineLabel.sizeToFit()
        textView.attributedText = s
    }

    static func solidImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            color.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
        }
    }
}
