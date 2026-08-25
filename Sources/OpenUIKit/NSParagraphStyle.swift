// NSParagraphStyle. Owner: text module (M12 — attributed text).
//
// Portable stand-in for Foundation's paragraph style (same shadowing caveat
// as NSAttributedString — see docs/KNOWN_GAPS.md). Only the properties the
// layout engine honors are declared; each one is oracle-measured, see
// AttributedTextLayout for the rules:
//   lineSpacing           extra points BETWEEN line boxes (n-1 gaps)
//   paragraphSpacing      extra points after a hard line break
//   paragraphSpacingBefore extra points before every paragraph but the first
//   lineHeightMultiple    scales the natural line height
//   minimum/maximumLineHeight  clamp, applied after the multiple
//   firstLineHeadIndent / headIndent   left inset of the first / later lines
//   tailIndent            negative = inset from the trailing edge
//   alignment, lineBreakMode  adopted by UILabel when set on the string
//
// The base class is nominally immutable (Foundation shape): its properties
// have internal setters and NSMutableParagraphStyle re-exposes them.

open class NSParagraphStyle: Equatable {
    public internal(set) var alignment: NSTextAlignment = .natural
    public internal(set) var lineSpacing: CGFloat = 0
    public internal(set) var paragraphSpacing: CGFloat = 0
    public internal(set) var paragraphSpacingBefore: CGFloat = 0
    public internal(set) var lineHeightMultiple: CGFloat = 0
    public internal(set) var minimumLineHeight: CGFloat = 0
    public internal(set) var maximumLineHeight: CGFloat = 0
    public internal(set) var firstLineHeadIndent: CGFloat = 0
    public internal(set) var headIndent: CGFloat = 0
    public internal(set) var tailIndent: CGFloat = 0
    public internal(set) var lineBreakMode: NSLineBreakMode = .byWordWrapping
    public internal(set) var hyphenationFactor: Float = 0

    public init() {}

    /// UIKit's shared default paragraph style.
    public static let `default` = NSParagraphStyle()

    open func mutableCopy() -> NSMutableParagraphStyle {
        let m = NSMutableParagraphStyle()
        m.setParagraphStyle(self)
        return m
    }

    /// True when nothing in this style changes layout (the fast path).
    var isDefaultLayout: Bool {
        lineSpacing == 0 && paragraphSpacing == 0 && paragraphSpacingBefore == 0
            && lineHeightMultiple == 0 && minimumLineHeight == 0 && maximumLineHeight == 0
            && firstLineHeadIndent == 0 && headIndent == 0 && tailIndent == 0
    }

    public static func == (a: NSParagraphStyle, b: NSParagraphStyle) -> Bool {
        a.alignment == b.alignment && a.lineSpacing == b.lineSpacing
            && a.paragraphSpacing == b.paragraphSpacing
            && a.paragraphSpacingBefore == b.paragraphSpacingBefore
            && a.lineHeightMultiple == b.lineHeightMultiple
            && a.minimumLineHeight == b.minimumLineHeight
            && a.maximumLineHeight == b.maximumLineHeight
            && a.firstLineHeadIndent == b.firstLineHeadIndent
            && a.headIndent == b.headIndent && a.tailIndent == b.tailIndent
            && a.lineBreakMode == b.lineBreakMode
            && a.hyphenationFactor == b.hyphenationFactor
    }
}

open class NSMutableParagraphStyle: NSParagraphStyle {
    public override init() { super.init() }

    open override var alignment: NSTextAlignment {
        get { super.alignment } set { super.alignment = newValue }
    }
    open override var lineSpacing: CGFloat {
        get { super.lineSpacing } set { super.lineSpacing = newValue }
    }
    open override var paragraphSpacing: CGFloat {
        get { super.paragraphSpacing } set { super.paragraphSpacing = newValue }
    }
    open override var paragraphSpacingBefore: CGFloat {
        get { super.paragraphSpacingBefore } set { super.paragraphSpacingBefore = newValue }
    }
    open override var lineHeightMultiple: CGFloat {
        get { super.lineHeightMultiple } set { super.lineHeightMultiple = newValue }
    }
    open override var minimumLineHeight: CGFloat {
        get { super.minimumLineHeight } set { super.minimumLineHeight = newValue }
    }
    open override var maximumLineHeight: CGFloat {
        get { super.maximumLineHeight } set { super.maximumLineHeight = newValue }
    }
    open override var firstLineHeadIndent: CGFloat {
        get { super.firstLineHeadIndent } set { super.firstLineHeadIndent = newValue }
    }
    open override var headIndent: CGFloat {
        get { super.headIndent } set { super.headIndent = newValue }
    }
    open override var tailIndent: CGFloat {
        get { super.tailIndent } set { super.tailIndent = newValue }
    }
    open override var lineBreakMode: NSLineBreakMode {
        get { super.lineBreakMode } set { super.lineBreakMode = newValue }
    }
    open override var hyphenationFactor: Float {
        get { super.hyphenationFactor } set { super.hyphenationFactor = newValue }
    }

    open func setParagraphStyle(_ obj: NSParagraphStyle) {
        alignment = obj.alignment
        lineSpacing = obj.lineSpacing
        paragraphSpacing = obj.paragraphSpacing
        paragraphSpacingBefore = obj.paragraphSpacingBefore
        lineHeightMultiple = obj.lineHeightMultiple
        minimumLineHeight = obj.minimumLineHeight
        maximumLineHeight = obj.maximumLineHeight
        firstLineHeadIndent = obj.firstLineHeadIndent
        headIndent = obj.headIndent
        tailIndent = obj.tailIndent
        lineBreakMode = obj.lineBreakMode
        hyphenationFactor = obj.hyphenationFactor
    }
}
