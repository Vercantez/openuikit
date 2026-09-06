// Fail-closed placeholder chrome for system pickers that have no host
// service (document / image / font / document-browser). Not a public type.
//
// The sheet around it IS the measured page sheet (`modalPresentationStyle =
// .pageSheet`, same as UIActivityViewController). The body is a grouped
// background plus a secondary label — not the remote iOS picker chrome,
// which is out of process and unmeasured (docs/KNOWN_GAPS.md).

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

@preconcurrency @MainActor
final class _UIUnavailableSystemUIView: UIView {
    let messageLabel = UILabel()
    let cancelButton = UIButton(type: .system)
    var onCancel: (() -> Void)?

    init(message: String, cancelTitle: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        backgroundColor = .systemGroupedBackground
        messageLabel.text = message
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        addSubview(messageLabel)
        cancelButton.setTitle(cancelTitle, for: .normal)
        cancelButton.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?.onCancel?()
        }
        addSubview(cancelButton)
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        let h = bounds.height
        messageLabel.frame = CGRect(x: 24, y: h / 2 - 40, width: w - 48, height: 48)
        cancelButton.frame = CGRect(x: 24, y: h / 2 + 16, width: w - 48, height: 44)
    }
}
