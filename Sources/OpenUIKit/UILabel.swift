// UILabel. Owner: text module.
// SKELETON — sizeThatFits, line breaking, truncation, alignment, and
// glyph drawing must match real UIKit (validate against golden/label_*).

public enum NSTextAlignment: Sendable {
    case left, center, right, justified, natural
}

public enum NSLineBreakMode: Sendable {
    case byWordWrapping, byCharWrapping, byClipping
    case byTruncatingHead, byTruncatingTail, byTruncatingMiddle
}

open class UILabel: UIView {
    public var text: String? { didSet { setNeedsLayout() } }
    public var font: UIFont = .systemFont(ofSize: 17)
    public var textColor: UIColor = .label
    public var textAlignment: NSTextAlignment = .natural
    public var numberOfLines: Int = 1
    public var lineBreakMode: NSLineBreakMode = .byTruncatingTail

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isOpaque = false
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        // text module: implement using FontEngine + line breaking.
        guard let text, !text.isEmpty else { return .zero }
        let w = FontEngine.measure(text, font: font)
        return CGSize(width: min(w, size.width), height: font.lineHeight)
    }

    open override var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
    }

    open override func drawContent(in canvas: Canvas, bounds: CGRect) {
        // text module: implement glyph drawing.
    }
}
