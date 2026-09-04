// UITextView. Owner: text-input module (M8).
//
// A UIScrollView subclass (like real UIKit) whose text layout matches the
// measured Catalyst iOS 26.1 TextKit behavior (scratchpad textprobe;
// golden/textview_basic.*):
//
//   - Default backgroundColor = .systemBackground, clipsToBounds = true.
//   - textContainerInset = (8, 0, 8, 0), lineFragmentPadding = 5:
//     text starts at x = 5, first line top at y = 8.
//   - Line height = font.lineHeight EXACTLY (the metrics-table values are
//     UIKit's integer UIFont.lineHeight: 16 @ 13 pt, 18 @ 15 pt, 20 @ 17 pt)
//     — NOT UILabel's line box (labelLineHeight adds +1 in three size
//     bands; UILabel and UITextView genuinely differ at e.g. 15 pt).
//   - First baseline at inset.top + floor(ascender + 0.5); the glyph pen
//     starts exactly at the padding edge (x = 5; fitted 99.97 against
//     golden/textview_basic — no TextKit pen shift).
//   - contentSize = (width, inset.top + inset.bottom + lines * lineHeight).
//   - Caret: height = lineHeight + 1.5, x = 5 + pixel-rounded prefix
//     width, y = floor(inset.top + line * lineHeight - 0.75) (measured
//     caretRect probes across sizes 11...24). Rendered 2 pt wide in tint
//     color (task spec; real caretRect reports 1 pt).
//   - font is nil by default and renders at 12 pt system (real UIKit's
//     legacy default is Helvetica 12 — lineHeight differs by 1 pt there;
//     always set a font, as the fixtures and demo do).
//
// Editing: tap focuses (isEditable), caret at nearest glyph boundary;
// insertText/deleteBackward edit at the caret; left/right/up/down move it;
// return inserts a newline. The view auto-scrolls to keep the caret
// visible. Selection is out of scope (docs/KNOWN_GAPS.md).

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif


/// Content canvas (private name — layout dumps stay comparable; real
/// UIKit's counterpart is _UITextContainerView/_UITextLayoutCanvasView).
@preconcurrency @MainActor
final class UITextViewCanvasView: UIView {
    weak var owner: UITextView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        isUserInteractionEnabled = false
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        owner?.drawText(in: canvas)
    }
}

// MARK: - UITextViewDelegate (M13 delegate-protocols cluster)

/// UIKit's protocol. It REFINES `UIScrollViewDelegate` exactly as UIKit's
/// does (a text view is a scroll view, and the scroll callbacks are part of
/// the contract). All members have defaults, so optional members stay
/// optional without ObjC.
///
/// Gating members that really gate here:
///   - `textViewShouldBeginEditing` / `textViewShouldEndEditing`
///   - `textView(_:shouldChangeTextIn:replacementText:)`
/// `textView(_:shouldInteractWith:in:interaction:)` is NOT declared: it takes
/// `NSTextAttachment` / `URL`, neither of which exists off Foundation here.
@preconcurrency @MainActor
public protocol UITextViewDelegate: UIScrollViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool
    func textViewDidBeginEditing(_ textView: UITextView)
    func textViewDidEndEditing(_ textView: UITextView)
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool
    func textViewDidChange(_ textView: UITextView)
    func textViewDidChangeSelection(_ textView: UITextView)
}

public extension UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool { true }
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool { true }
    func textViewDidBeginEditing(_ textView: UITextView) {}
    func textViewDidEndEditing(_ textView: UITextView) {}
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool { true }
    func textViewDidChange(_ textView: UITextView) {}
    func textViewDidChangeSelection(_ textView: UITextView) {}
}

@preconcurrency @MainActor
open class UITextView: UIScrollView, UIKeyInput, UITextKeyHandling, UITextCaretHosting {

    /// UIKit's `delegate` on a text view is the text-view delegate; because
    /// `UITextViewDelegate` refines `UIScrollViewDelegate`, assigning it also
    /// satisfies the scroll delegate the superclass calls. The scroll
    /// callbacks therefore keep working through the SAME object, as in UIKit.
    public var textViewDelegate: UITextViewDelegate? {
        get { delegate as? UITextViewDelegate }
        set { delegate = newValue }
    }

    // MARK: Content properties

    // UIKit text-input traits. The portable renderer has no keyboard of its
    // own; hosts can inspect these exact values when choosing an input UI.
    open var autocapitalizationType: UITextAutocapitalizationType = .sentences
    open var autocorrectionType: UITextAutocorrectionType = .default
    open var keyboardType: UIKeyboardType = .default
    open var keyboardAppearance: UIKeyboardAppearance = .default
    open var returnKeyType: UIReturnKeyType = .default
    open var enablesReturnKeyAutomatically = false
    /// Semantic purpose retained for password managers and host keyboards,
    /// matching the same trait on UITextField.
    open var textContentType: UITextContentType?

    /// UIKit imports its `null_resettable` NSString property as `String!`:
    /// callers may use optional binding, while assigning nil resets to an
    /// empty string. The normalization is the first observer operation so
    /// every subsequent text-layout path continues to see non-nil content.
    open var text: String! = "" {
        didSet {
            if text == nil { text = "" }
            _attributed = nil
            if caretOffset > UITextCaretMath.scalarCount(text) {
                caretOffset = UITextCaretMath.scalarCount(text)
            }
            contentDidChange()
        }
    }

    /// Attributed content (M12). Wrapping and drawing go through
    /// AttributedTextLayout with `usesFontLineHeight` set, so a single-font
    /// attributed string lays out exactly like the plain path. Editing
    /// rewrites `text` and DROPS the attributes (docs/KNOWN_GAPS.md).
    public var attributedText: NSAttributedString? {
        get {
            if let a = _attributed { return a }
            guard !text.isEmpty else { return nil }
            return NSAttributedString(string: text,
                                      attributes: [.font: effectiveFont,
                                                   .foregroundColor: textColor])
        }
        set {
            let s = newValue?.string ?? ""
            _attributed = newValue
            // Assign through the storage directly (the `text` observer would
            // clear `_attributed` again).
            _textStorage = s
            if caretOffset > UITextCaretMath.scalarCount(s) {
                caretOffset = UITextCaretMath.scalarCount(s)
            }
            contentDidChange()
        }
    }
    var _attributed: NSAttributedString?
    /// Write-through to `text` without tripping its didSet.
    private var _textStorage: String {
        get { text }
        set {
            let saved = _attributed
            text = newValue
            _attributed = saved
        }
    }

    /// Flattened attributed content, or nil when the view holds plain text.
    var attributedLayoutText: AttributedTextLayout.Text? {
        guard let a = _attributed, a.length > 0 else { return nil }
        var t = AttributedTextLayout.flatten(a, defaultFont: effectiveFont,
                                             defaultColor: textColor)
        t.usesFontLineHeight = true
        return t
    }
    public var font: UIFont? {
        didSet { contentDidChange() }
    }
    public var textColor: UIColor = .label {
        didSet { contentDidChange() }
    }
    public var textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0) {
        didSet { contentDidChange() }
    }
    public var isEditable = true

    public static let lineFragmentPadding: CGFloat = 5

    var effectiveFont: UIFont { font ?? .systemFont(ofSize: 12) }
    var lineHeight: CGFloat { FontEngine.metrics(for: effectiveFont).lineHeight }

    // MARK: Internal views / editing state

    let contentView = UITextViewCanvasView()
    var caretView: UIView?
    public private(set) var isEditing = false
    /// Caret position as a unicode-scalar offset into `text`.
    public internal(set) var caretOffset: Int = 0
    /// Preferred caret x (text space) preserved across up/down moves.
    var preferredCaretX: CGFloat?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureTextCanvas()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureTextCanvas()
    }

    private func configureTextCanvas() {
        isOpaque = true
        backgroundColor = .systemBackground
        contentView.owner = self
        addSubview(contentView)
    }

    func contentDidChange() {
        contentView.setNeedsDisplay()
        setNeedsLayout()
    }

    // MARK: Line layout

    var wrapWidth: CGFloat {
        Swift.max(0, bounds.width - textContainerInset.left - textContainerInset.right
                     - 2 * UITextView.lineFragmentPadding)
    }

    /// Wrapped lines with their unicode-scalar offset ranges into `text`.
    struct LineRun {
        var text: Substring
        var start: Int   // scalar offset of the first character
        var end: Int     // scalar offset past the last character
    }

    func lineRuns() -> [LineRun] {
        let lines = TextLayout.wrap(text, font: effectiveFont,
                                    maxWidth: wrapWidth, maxLines: 0)
        var runs: [LineRun] = []
        runs.reserveCapacity(Swift.max(lines.count, 1))
        let scalars = text.unicodeScalars
        for l in lines {
            let start = scalars.distance(from: scalars.startIndex,
                                         to: l.text.startIndex)
            let count = l.text.unicodeScalars.count
            runs.append(LineRun(text: l.text, start: start, end: start + count))
        }
        if runs.isEmpty {
            runs.append(LineRun(text: text[text.startIndex...], start: 0, end: 0))
        }
        return runs
    }

    var contentHeight: CGFloat {
        if let t = attributedLayoutText {
            let lines = AttributedTextLayout.wrap(t, maxWidth: wrapWidth, maxLines: 0,
                                                  scale: traitCollection.displayScale)
            var h: CGFloat = 0
            for (i, l) in lines.enumerated() {
                h += l.height
                if i < lines.count - 1 { h += l.spacingBelow }
            }
            return textContainerInset.top + textContainerInset.bottom
                + Swift.max(h, lineHeight)
        }
        let n = Swift.max(1, lineRuns().count)
        return textContainerInset.top + textContainerInset.bottom
            + CGFloat(n) * lineHeight
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let h = contentHeight
        contentView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: h)
        contentSize = CGSize(width: bounds.width, height: h)
        layoutCaret()
    }

    // MARK: Drawing (called by the content canvas)

    func drawText(in canvas: Canvas) {
        if let t = attributedLayoutText {
            let lines = AttributedTextLayout.wrap(t, maxWidth: wrapWidth, maxLines: 0,
                                                  scale: traitCollection.displayScale)
            var h: CGFloat = 0
            for (i, l) in lines.enumerated() {
                h += l.height
                if i < lines.count - 1 { h += l.spacingBelow }
            }
            // The text container is top-aligned, not centered: give
            // AttributedTextLayout a bounds whose centering lands the block
            // at the container inset.
            let x = textContainerInset.left + UITextView.lineFragmentPadding
            let box = CGRect(x: x, y: textContainerInset.top,
                             width: Swift.max(0, wrapWidth), height: h)
            AttributedTextLayout.draw(t, lines: lines,
                                      in: AttributedTextLayout.DrawContext(
                                        canvas: canvas, traits: traitCollection,
                                        bounds: box,
                                        alignment: t.paragraph.alignment))
            return
        }
        guard !text.isEmpty else { return }
        let font = effectiveFont
        let color = textColor.resolvedCGColor(with: traitCollection)
        guard color.alpha > 0 else { return }
        let dark = traitCollection.userInterfaceStyle == .dark
        let glyphFont = GlyphRasterizer.font(for: font)
        let asc = FontEngine.metrics(for: font).ascender
        var baseline0 = textContainerInset.top + (asc + 0.5).rounded(.down)
        if GlyphInkTable.usesIOSTable {
            // textview_paragraphs_2x on the 2x SE oracle: +0.5 pt baseline
            // shift (one device pixel) raises score 94.157 -> 98.887.
            baseline0 += 0.5
        }
        let penX = textContainerInset.left + UITextView.lineFragmentPadding
        let lineH = lineHeight
        for (i, run) in lineRuns().enumerated() {
            guard !run.text.isEmpty else { continue }
            UILabel.drawGlyphLine(String(run.text),
                                  at: CGPoint(x: penX,
                                              y: baseline0 + CGFloat(i) * lineH),
                                  in: canvas, font: font, dark: dark,
                                  color: color, glyphFont: glyphFont)
        }
    }

    // MARK: First responder / editing session

    open override var canBecomeFirstResponder: Bool { isEditable }

    /// See the note on `UITextField.canResignFirstResponder` — same reason,
    /// same double-ask caveat.
    open override var canResignFirstResponder: Bool {
        guard isEditing, let d = textViewDelegate else { return true }
        return d.textViewShouldEndEditing(self)
    }

    @discardableResult
    open override func becomeFirstResponder() -> Bool {
        if !isEditing, let d = textViewDelegate, !d.textViewShouldBeginEditing(self) {
            return false
        }
        guard super.becomeFirstResponder() else { return false }
        if !isEditing {
            isEditing = true
            caretOffset = UITextCaretMath.scalarCount(text)
            UITextInputState.focus(self, at: OpenUIKitRuntime.animationTime)
            ensureCaretView()
            caretView?.isHidden = false
            setNeedsLayout()
            textViewDelegate?.textViewDidBeginEditing(self)
        }
        return true
    }

    @discardableResult
    open override func resignFirstResponder() -> Bool {
        if isEditing, let d = textViewDelegate, !d.textViewShouldEndEditing(self) {
            return false
        }
        let r = super.resignFirstResponder()
        if isEditing {
            isEditing = false
            UITextInputState.unfocus(self)
            caretView?.isHidden = true
            textViewDelegate?.textViewDidEndEditing(self)
        }
        return r
    }

    /// Tap: focus and position the caret (touches the scroll pan let
    /// through — a drag scrolls, a clean tap edits).
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard isEditable, let touch = touches.first else { return }
        let p = touch.location(in: self)   // bounds coords == content coords
        becomeFirstResponder()
        guard isEditing else { return }
        caretOffset = caretIndex(at: p)
        preferredCaretX = nil
        UITextInputState.noteActivity(at: OpenUIKitRuntime.animationTime)
        caretView?.isHidden = false
        setNeedsLayout()
    }

    /// Nearest glyph boundary to a point in content coordinates.
    func caretIndex(at p: CGPoint) -> Int {
        let runs = lineRuns()
        let lineH = lineHeight
        let rawLine = ((p.y - textContainerInset.top) / lineH).rounded(.down)
        let line = Swift.min(Swift.max(Int(rawLine), 0), runs.count - 1)
        let run = runs[line]
        let x = p.x - textContainerInset.left - UITextView.lineFragmentPadding
        let within = UITextCaretMath.caretIndex(for: x, text: String(run.text),
                                                font: effectiveFont)
        return run.start + within
    }

    // MARK: UIKeyInput

    public var hasText: Bool { !text.isEmpty }

    public func insertText(_ str: String) {
        guard isEditing else { return }
        if let d = textViewDelegate,
           !d.textView(self, shouldChangeTextIn: NSRange(location: caretOffset, length: 0),
                       replacementText: str) { return }
        let i = UITextCaretMath.index(text, atScalarOffset: caretOffset)
        text.insert(contentsOf: str, at: i)
        caretOffset += UITextCaretMath.scalarCount(str)
        preferredCaretX = nil
        afterEdit()
    }

    public func deleteBackward() {
        guard isEditing, caretOffset > 0 else { return }
        if let d = textViewDelegate,
           !d.textView(self, shouldChangeTextIn: NSRange(location: caretOffset - 1, length: 1),
                       replacementText: "") { return }
        let end = UITextCaretMath.index(text, atScalarOffset: caretOffset)
        let start = UITextCaretMath.index(text, atScalarOffset: caretOffset - 1)
        text.removeSubrange(start..<end)
        caretOffset -= 1
        preferredCaretX = nil
        afterEdit()
    }

    func afterEdit() {
        contentDidChange()
        caretView?.isHidden = false
        layoutIfNeeded()
        scrollCaretToVisible()
        textViewDelegate?.textViewDidChange(self)
        textViewDelegate?.textViewDidChangeSelection(self)
    }

    func handleKey(_ key: UIKeyEventKey) {
        guard isEditing else { return }
        switch key {
        case .backspace:
            deleteBackward()
            return
        case .left:
            if caretOffset > 0 { caretOffset -= 1 }
            preferredCaretX = nil
        case .right:
            if caretOffset < UITextCaretMath.scalarCount(text) { caretOffset += 1 }
            preferredCaretX = nil
        case .up, .down:
            moveCaretVertically(by: key == .down ? 1 : -1)
        case .return:
            insertText("\n")
            return
        }
        caretView?.isHidden = false
        setNeedsLayout()
        layoutIfNeeded()
        scrollCaretToVisible()
        textViewDelegate?.textViewDidChangeSelection(self)
    }

    /// Up/down arrows: nearest boundary in the adjacent line, preserving
    /// the caret's x across consecutive vertical moves (UIKit behavior).
    func moveCaretVertically(by delta: Int) {
        let runs = lineRuns()
        guard let (line, within) = caretLine(in: runs) else { return }
        let target = line + delta
        guard target >= 0, target < runs.count else { return }
        let font = effectiveFont
        let x = preferredCaretX
            ?? UITextCaretMath.prefixWidth(String(runs[line].text),
                                           count: within, font: font)
        preferredCaretX = x
        let run = runs[target]
        let within2 = UITextCaretMath.caretIndex(for: x, text: String(run.text),
                                                 font: font)
        caretOffset = run.start + within2
    }

    /// (line index, scalar offset within the line) for the caret.
    func caretLine(in runs: [LineRun]) -> (Int, Int)? {
        for (i, r) in runs.enumerated() {
            if caretOffset < r.end { return (i, Swift.max(0, caretOffset - r.start)) }
            if caretOffset == r.end {
                // Boundary shared with the next line's start (char wrap):
                // prefer the next line's start, else this line's end.
                if i + 1 < runs.count, runs[i + 1].start == r.end {
                    return (i + 1, 0)
                }
                return (i, caretOffset - r.start)
            }
        }
        guard let last = runs.indices.last else { return nil }
        return (last, runs[last].end - runs[last].start)
    }

    // MARK: Caret geometry (measured — see header)

    /// Caret rect in CONTENT coordinates.
    public func caretRect() -> CGRect {
        let runs = lineRuns()
        guard let (line, within) = caretLine(in: runs) else { return .zero }
        let font = effectiveFont
        let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 2
        let px = FontEngine.roundToPixel(
            UITextCaretMath.prefixWidth(String(runs[line].text), count: within,
                                        font: font), scale: scale)
        let lineH = lineHeight
        let x = textContainerInset.left + UITextView.lineFragmentPadding + px
        let y = (textContainerInset.top + CGFloat(line) * lineH - 0.75).rounded(.down)
        return CGRect(x: x, y: y, width: 2, height: lineH + 1.5)
    }

    func ensureCaretView() {
        if caretView == nil {
            let v = UIView()   // plain UIView: no dump noise, no content pass
            v.isUserInteractionEnabled = false
            contentView.addSubview(v)
            caretView = v
        }
    }

    func layoutCaret() {
        guard let caret = caretView, isEditing else { return }
        caret.backgroundColor = tintColor
        caret.frame = caretRect()
    }

    func caretBlinkChanged(visible: Bool) {
        guard isEditing else { return }
        caretView?.isHidden = !visible
    }

    /// Keep the caret's line inside the visible rect (vertical only).
    func scrollCaretToVisible() {
        let r = caretRect()
        var off = contentOffset
        let visibleH = bounds.height
        if r.maxY + textContainerInset.bottom > off.y + visibleH {
            off.y = r.maxY + textContainerInset.bottom - visibleH
        }
        if r.minY - textContainerInset.top < off.y {
            off.y = Swift.max(0, r.minY - textContainerInset.top)
        }
        if off != contentOffset { contentOffset = off }
    }
}
