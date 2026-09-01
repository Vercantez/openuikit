import UIKit

final class LiveTransportProofViewController: UIViewController {
    private let statusLabel = UILabel()
    private let textField = UITextField()
    private let typedLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel(frame: CGRect(x: 24, y: 72, width: 342, height: 42))
        title.text = "Mach-O UIKit on Linux"
        title.font = .boldSystemFont(ofSize: 27)
        title.textColor = .label
        view.addSubview(title)

        statusLabel.frame = CGRect(x: 24, y: 136, width: 342, height: 30)
        statusLabel.text = "Button: waiting"
        statusLabel.font = .systemFont(ofSize: 19)
        statusLabel.textColor = .secondaryLabel
        view.addSubview(statusLabel)

        let button = UIButton(type: .system)
        button.frame = CGRect(x: 24, y: 194, width: 230, height: 52)
        button.setTitle("Tap to turn green", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addAction(UIAction { [weak self] _ in
            self?.statusLabel.text = "Button: clicked"
            self?.statusLabel.textColor = .systemGreen
            self?.view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        }, for: .touchUpInside)
        view.addSubview(button)

        let instruction = UILabel(frame: CGRect(x: 24, y: 280, width: 342, height: 24))
        instruction.text = "Focus the field, then type: Linux UIKit"
        instruction.font = .systemFont(ofSize: 15)
        instruction.textColor = .secondaryLabel
        view.addSubview(instruction)

        textField.frame = CGRect(x: 24, y: 314, width: 342, height: 44)
        textField.borderStyle = .roundedRect
        textField.placeholder = "Type through SDL/noVNC"
        textField.font = .systemFont(ofSize: 18)
        textField.addAction(UIAction { [weak self] _ in
            let text = self?.textField.text ?? ""
            self?.typedLabel.text = "Typed: " + (text.isEmpty ? "—" : text)
        }, for: .editingChanged)
        view.addSubview(textField)

        typedLabel.frame = CGRect(x: 24, y: 376, width: 342, height: 34)
        typedLabel.text = "Typed: —"
        typedLabel.font = .boldSystemFont(ofSize: 18)
        typedLabel.textColor = .label
        view.addSubview(typedLabel)

        let contract = UILabel(frame: CGRect(x: 24, y: 456, width: 342, height: 96))
        contract.text = "Unchanged application source\nARM64 iOS simulator Mach-O\nUIRenderer → SDL → noVNC"
        contract.font = .systemFont(ofSize: 16)
        contract.textColor = .secondaryLabel
        contract.numberOfLines = 3
        view.addSubview(contract)
    }
}
