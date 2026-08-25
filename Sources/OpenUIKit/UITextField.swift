// UITextField. Owner: text-input module (M8).
//
// Static chrome + layout measured from real UIKit (Mac Catalyst iOS 26.1,
// scratchpad textprobe; golden/textfield_basic.*):
//
//   - .roundedRect chrome is a private background subview spanning the
//     bounds: fill = dynamic (light: white, dark: black — the private
//     _textFieldBackgroundColor), CALayer border width 0.6493506494 pt
//     (yes, that exact fraction — read off the real layer), borderColor
//     black at 20 % alpha (light; the dark resolution is not capturable
//     offscreen — we use white 20 %, see docs/KNOWN_GAPS.md), corner
//     radius 5.
//   - textRect(forBounds:) for .roundedRect = bounds inset by (7, 2);
//     .none = bounds.
//   - Placeholder renders exactly like a UILabel (color .placeholderText)
//     with the label's line box (FontEngine.labelLineHeight) centered in
//     the bounds — real UIKit hosts a UITextFieldLabel at that frame.
//   - Non-editing text renders like the placeholder label (same centered
//     line box, baseline and pen origin — fitted 99.9 against
//     golden/textfield_basic) and truncates the tail with an ellipsis
//     exactly like UILabel.
//   - intrinsicContentSize (.roundedRect) = (W + 28, 34) where W is the
//     whole-point ceil of the text width (text present) or the pixel-grid
//     ceil of the placeholder width (placeholder only), floor 5 (empty);
//     .none = (W, lineHeight + 1.5).
//   - Caret (editing): width 2 pt tint bar (real caretRect reports 1 pt;
//     the visible iOS caret is 2 pt), height = lineHeight + 1.5, vertical
//     placement from the measured caretRect probes: the field's line box
//     is lineHeight + 2 tall, centered in the text rect, caret y = floor
//     of (box top + 0.25).
//
// Editing model: becomeFirstResponder begins the session (caret at the
// tapped glyph boundary; .editingDidBegin), insertText/deleteBackward edit
// at the caret (.editingChanged), left/right move the caret, return
// resigns (.editingDidEnd, .primaryActionTriggered). Overflowing text
// scrolls horizontally to keep the caret visible. Selection is out of
// scope (see docs/KNOWN_GAPS.md).

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


public enum UITextFieldBorderStyle: Sendable {
    case none, line, bezel, roundedRect
}

// MARK: - UITextFieldDelegate (M13 delegate-protocols cluster)

/// UIKit's protocol, with UIKit's names and signatures. Every member has a
/// default implementation so a conformance can implement only what it wants
/// — the portable stand-in for ObjC's `@objc optional`.
///
/// WHICH MEMBERS ACTUALLY GATE BEHAVIOUR HERE (the rest are called at the
/// UIKit moment but their return value has nowhere to go yet):
///   - `textFieldShouldBeginEditing` — false blocks `becomeFirstResponder()`
///   - `textFieldShouldEndEditing`   — false blocks `resignFirstResponder()`
///   - `textField(_:shouldChangeCharactersIn:replacementString:)` — false
///     drops the insertion / deletion
///   - `textFieldShouldClear`        — false blocks `text = nil` via clear
///   - `textFieldShouldReturn`       — the return key's handler; UIKit does
///     NOT resign on its own, and neither do we (an app returning true
///     usually calls `resignFirstResponder()` itself)
@MainActor
public protocol UITextFieldDelegate: AnyObject {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    func textFieldDidBeginEditing(_ textField: UITextField)
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool
    func textFieldDidEndEditing(_ textField: UITextField)
    func textFieldDidEndEditing(_ textField: UITextField,
                                reason: UITextField.DidEndEditingReason)
    func textFieldDidChangeSelection(_ textField: UITextField)
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    func textFieldShouldClear(_ textField: UITextField) -> Bool
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
}

public extension UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { true }
    func textFieldDidBeginEditing(_ textField: UITextField) {}
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool { true }
    func textFieldDidEndEditing(_ textField: UITextField) {}
    func textFieldDidEndEditing(_ textField: UITextField,
                                reason: UITextField.DidEndEditingReason) {}
    func textFieldDidChangeSelection(_ textField: UITextField) {}
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool { true }
    func textFieldShouldClear(_ textField: UITextField) -> Bool { true }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { true }
}

/// Real UIKit's placeholder-label class name (private in compare.py's
/// layout diff, like the oracle's).
@MainActor
final class UITextFieldLabel: UILabel {}

/// The .roundedRect chrome (private class name keeps it out of layout
/// comparison, mirroring _UITextFieldRoundedRectBackgroundViewNeue).
@MainActor
final class UITextFieldBackgroundView: UIView {}

/// Clipping container for the text label + caret (mirrors
/// _UITextLayoutCanvasView).
@MainActor
final class UITextFieldCanvasView: UIView {}

@MainActor
open class UITextField: UIControl, UIKeyInput, UITextKeyHandling, UITextCaretHosting {

    // MARK: Content properties

    public var text: String? {
        get { _text.isEmpty ? (_hasText ? _text : nil) : _text }
        set {
            _text = newValue ?? ""
            _hasText = newValue != nil
            _attributed = nil
            if caretOffset > UITextCaretMath.scalarCount(_text) {
                caretOffset = UITextCaretMath.scalarCount(_text)
            }
            refreshContent()
        }
    }
    var _text: String = ""
    var _hasText = false

    /// Attributed content (M12). Rendering goes through the same
    /// UITextFieldLabel the plain path uses, so per-run fonts/colors/kern
    /// land unchanged. Editing rewrites the plain string and DROPS the
    /// attributes (documented in docs/KNOWN_GAPS.md — real UIKit keeps
    /// typing attributes; we do not model them).
    public var attributedText: NSAttributedString? {
        get {
            if let a = _attributed { return a }
            guard _hasText || !_text.isEmpty else { return nil }
            return NSAttributedString(string: _text,
                                      attributes: [.font: font, .foregroundColor: textColor])
        }
        set {
            _attributed = newValue
            _text = newValue?.string ?? ""
            _hasText = newValue != nil
            // Real UIKit folds the string's leading font / color into the
            // field's own `font` and `textColor` (measured: the field's
            // intrinsicContentSize then measures the PLAIN characters with
            // that one font, ignoring later runs — see Tools/attrprobe).
            if let a = newValue, a.length > 0 {
                let attrs = a.attributes(at: 0, effectiveRange: nil)
                if let f = attrs[.font] as? UIFont { font = f }
                if let c = attrs[.foregroundColor] as? UIColor { textColor = c }
            }
            if caretOffset > UITextCaretMath.scalarCount(_text) {
                caretOffset = UITextCaretMath.scalarCount(_text)
            }
            refreshContent()
        }
    }
    var _attributed: NSAttributedString?

    public var placeholder: String? {
        didSet { refreshContent() }
    }

    public var font: UIFont = .systemFont(ofSize: 17) {
        didSet { refreshContent() }
    }

    public var textColor: UIColor = .label {
        didSet { refreshContent() }
    }

    public var borderStyle: UITextFieldBorderStyle = .none {
        didSet { setNeedsLayout() }
    }

    // MARK: Chrome metrics (measured — see header)

    static let roundedRectCornerRadius: CGFloat = 5
    static let roundedRectBorderWidth: CGFloat = 0.6493506493506493
    static let roundedRectTextInset = CGSize(width: 7, height: 2)
    /// Light: black 20 %; dark resolution is unverified (KNOWN_GAPS).
    static let chromeBorderColor = UIColor(.dynamic { t in
        t.userInterfaceStyle == .dark
            ? CGColor(red: 1, green: 1, blue: 1, alpha: 0.2)
            : CGColor(red: 0, green: 0, blue: 0, alpha: 0.2)
    })
    static let chromeFillColor = UIColor(.dynamic { t in
        t.userInterfaceStyle == .dark
            ? CGColor(red: 0, green: 0, blue: 0, alpha: 1)
            : CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    })

    // MARK: Internal views

    let backgroundView = UITextFieldBackgroundView()
    let canvasView = UITextFieldCanvasView()
    let textLabel = UITextFieldLabel()
    let placeholderLabel = UITextFieldLabel()
    /// Created lazily on first edit so static scenes/layout dumps never
    /// see it (a plain UIView: background = tint bar).
    var caretView: UIView?

    // MARK: Delegate (M13)

    /// UIKit's reason codes for `textFieldDidEndEditing(_:reason:)`.
    /// `.cancelled` exists for the iPad keyboard's cancel affordance, which
    /// has no equivalent here — every end is `.committed`.
    public enum DidEndEditingReason: Sendable { case committed, cancelled }

    public weak var delegate: UITextFieldDelegate?

    // MARK: Editing state

    public private(set) var isEditing = false
    /// Caret position as a unicode-scalar offset into `_text`.
    public internal(set) var caretOffset: Int = 0
    /// Horizontal scroll of overflowing text (points, >= 0).
    public internal(set) var textScrollOffset: CGFloat = 0

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isOpaque = false
        backgroundView.isUserInteractionEnabled = false
        canvasView.isUserInteractionEnabled = false
        canvasView.clipsToBounds = true
        textLabel.font = font
        placeholderLabel.font = font
        placeholderLabel.textColor = .placeholderText
        addSubview(backgroundView)
        addSubview(canvasView)
        canvasView.addSubview(textLabel)
        canvasView.addSubview(placeholderLabel)
        refreshContent()
    }

    func refreshContent() {
        textLabel.font = font
        textLabel.textColor = textColor
        if let a = _attributed {
            textLabel.attributedText = a
        } else {
            textLabel.text = _text
        }
        placeholderLabel.font = font
        placeholderLabel.text = placeholder
        textLabel.isHidden = _text.isEmpty
        placeholderLabel.isHidden = !_text.isEmpty || (placeholder ?? "").isEmpty
        setNeedsLayout()
    }

    // MARK: Geometry (measured)

    var lineHeight: CGFloat { FontEngine.labelLineHeight(for: font) }

    public func textRect(forBounds bounds: CGRect) -> CGRect {
        switch borderStyle {
        case .roundedRect, .bezel, .line:
            return bounds.insetBy(dx: UITextField.roundedRectTextInset.width,
                                  dy: UITextField.roundedRectTextInset.height)
        case .none:
            return bounds
        }
    }

    public func editingRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }

    open override var intrinsicContentSize: CGSize {
        let scale = textLabel.layoutScale
        let base: CGFloat
        if _attributed != nil, !_text.isEmpty {
            // Attributed: measured with the field's single `font` (see the
            // attributedText setter), ceiled to the pixel grid.
            base = Swift.max(FontEngine.ceilToPixel(FontEngine.measure(_text, font: font),
                                                    scale: scale), 5)
        } else if !_text.isEmpty {
            base = Swift.max(FontEngine.measure(_text, font: font).rounded(.up), 5)
        } else if let p = placeholder, !p.isEmpty {
            base = FontEngine.ceilToPixel(FontEngine.measure(p, font: font), scale: scale)
        } else {
            base = 5
        }
        switch borderStyle {
        case .roundedRect, .bezel, .line:
            return CGSize(width: base + 28, height: 34)
        case .none:
            return CGSize(width: base, height: FontEngine.metrics(for: font).lineHeight + 1.5)
        }
    }

    // MARK: Layout

    open override func layoutSubviews() {
        super.layoutSubviews()
        let chrome = borderStyle == .roundedRect
        backgroundView.isHidden = !chrome
        if chrome {
            backgroundView.frame = bounds
            backgroundView.backgroundColor = UITextField.chromeFillColor
            backgroundView.layer.cornerRadius = UITextField.roundedRectCornerRadius
            backgroundView.layer.borderWidth = UITextField.roundedRectBorderWidth
            backgroundView.layer.borderColor =
                UITextField.chromeBorderColor.resolvedCGColor(with: traitCollection)
        }
        let tr = textRect(forBounds: bounds)
        canvasView.frame = tr
        let lineH = lineHeight
        // Label line box centered in the BOUNDS with UILabel's rounding
        // (golden: y = 7 at h = 34 / 17 pt, y = 9 at h = 34 / 13 pt).
        let labelY = ((bounds.height - lineH) / 2 + 0.5).rounded(.down)
        let labelYInCanvas = labelY - tr.minY

        placeholderLabel.frame = CGRect(x: 0, y: labelYInCanvas,
                                        width: tr.width, height: lineH)
        if isEditing {
            // Full text width, shifted by the scroll offset; no truncation.
            let w = Swift.max(FontEngine.measure(_text, font: font).rounded(.up) + 2,
                              tr.width)
            textLabel.lineBreakMode = .byClipping
            textLabel.frame = CGRect(x: -textScrollOffset,
                                     y: labelYInCanvas, width: w, height: lineH)
        } else {
            textLabel.lineBreakMode = .byTruncatingTail
            textLabel.frame = CGRect(x: 0, y: labelYInCanvas,
                                     width: tr.width, height: lineH)
        }
        layoutCaret()
    }

    // MARK: First responder / editing session

    open override var canBecomeFirstResponder: Bool { isEnabled }

    /// So a TAP ON ANOTHER responder honours the delegate's refusal too:
    /// `UIResponder.becomeFirstResponder` consults this before evicting the
    /// current first responder. (Consequence: a focus transfer asks
    /// `textFieldShouldEndEditing` twice — once here, once inside
    /// `resignFirstResponder`. UIKit asks once; the predicate is expected to
    /// be pure either way.)
    open override var canResignFirstResponder: Bool {
        guard isEditing, let d = delegate else { return true }
        return d.textFieldShouldEndEditing(self)
    }

    @discardableResult
    open override func becomeFirstResponder() -> Bool {
        // UIKit asks the delegate BEFORE taking focus, and a false answer
        // fails the whole call (M13).
        if !isEditing, let d = delegate, !d.textFieldShouldBeginEditing(self) {
            return false
        }
        guard super.becomeFirstResponder() else { return false }
        if !isEditing {
            isEditing = true
            caretOffset = UITextCaretMath.scalarCount(_text)
            UITextInputState.focus(self, at: OpenUIKitRuntime.animationTime)
            ensureCaretView()
            revealCaret()
            setNeedsLayout()
            sendActions(for: .editingDidBegin)
            delegate?.textFieldDidBeginEditing(self)
        }
        return true
    }

    @discardableResult
    open override func resignFirstResponder() -> Bool {
        // UIKit: a delegate that refuses to end editing keeps the field
        // focused, and resignFirstResponder returns false.
        if isEditing, let d = delegate, !d.textFieldShouldEndEditing(self) {
            return false
        }
        let r = super.resignFirstResponder()
        if isEditing {
            isEditing = false
            textScrollOffset = 0
            UITextInputState.unfocus(self)
            caretView?.isHidden = true
            setNeedsLayout()
            sendActions(for: .editingDidEnd)
            delegate?.textFieldDidEndEditing(self)
            delegate?.textFieldDidEndEditing(self, reason: .committed)
        }
        return r
    }

    /// Tap: focus and put the caret at the nearest glyph boundary.
    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        guard let touch, point(inside: touch.location(in: self), with: event) else { return }
        let wasEditing = isEditing
        becomeFirstResponder()
        guard isEditing else { return }
        let p = touch.location(in: self)
        let tr = textRect(forBounds: bounds)
        let x = p.x - tr.minX + textScrollOffset
        caretOffset = UITextCaretMath.caretIndex(for: x, text: _text, font: font)
        if wasEditing {
            UITextInputState.noteActivity(at: OpenUIKitRuntime.animationTime)
        }
        revealCaret()
        setNeedsLayout()
    }

    // MARK: UIKeyInput

    public var hasText: Bool { !_text.isEmpty }

    public func insertText(_ text: String) {
        guard isEditing else { return }
        // UIKit asks the delegate first; the range is the (empty) caret
        // range in unicode-scalar units — UIKit measures it in UTF-16, the
        // one place this file's scalar-based caret model shows through
        // (documented in docs/KNOWN_GAPS.md).
        if let d = delegate,
           !d.textField(self, shouldChangeCharactersIn: NSRange(location: caretOffset, length: 0),
                        replacementString: text) { return }
        let i = UITextCaretMath.index(_text, atScalarOffset: caretOffset)
        _text.insert(contentsOf: text, at: i)
        _hasText = true
        _attributed = nil
        caretOffset += UITextCaretMath.scalarCount(text)
        refreshContent()
        revealCaret()
        sendActions(for: .editingChanged)
        delegate?.textFieldDidChangeSelection(self)
    }

    public func deleteBackward() {
        guard isEditing, caretOffset > 0 else { return }
        if let d = delegate,
           !d.textField(self, shouldChangeCharactersIn: NSRange(location: caretOffset - 1, length: 1),
                        replacementString: "") { return }
        let end = UITextCaretMath.index(_text, atScalarOffset: caretOffset)
        let start = UITextCaretMath.index(_text, atScalarOffset: caretOffset - 1)
        _text.removeSubrange(start..<end)
        _attributed = nil
        caretOffset -= 1
        refreshContent()
        revealCaret()
        sendActions(for: .editingChanged)
        delegate?.textFieldDidChangeSelection(self)
    }

    /// UIKit's clear-button path, minus the button (no clear-button chrome is
    /// measured yet — see docs/KNOWN_GAPS.md). Exposed so an app that draws
    /// its own clear affordance gets the delegate gate UIKit gives it.
    @discardableResult
    public func _clear() -> Bool {
        if let d = delegate, !d.textFieldShouldClear(self) { return false }
        text = nil
        caretOffset = 0
        sendActions(for: .editingChanged)
        delegate?.textFieldDidChangeSelection(self)
        return true
    }

    func handleKey(_ key: UIKeyEventKey) {
        guard isEditing else { return }
        switch key {
        case .backspace:
            deleteBackward()
        case .left:
            if caretOffset > 0 { caretOffset -= 1 }
            revealCaret()
            setNeedsLayout()
            delegate?.textFieldDidChangeSelection(self)
        case .right:
            if caretOffset < UITextCaretMath.scalarCount(_text) { caretOffset += 1 }
            revealCaret()
            setNeedsLayout()
            delegate?.textFieldDidChangeSelection(self)
        case .up, .down:
            break // single line
        case .return:
            // UIKit order: the delegate sees the return key first, and a
            // delegate that answers false suppresses the field's own
            // response (the action + the resign).
            if let d = delegate, !d.textFieldShouldReturn(self) { return }
            sendActions(for: .primaryActionTriggered)
            resignFirstResponder()
        }
    }

    // MARK: Caret

    func ensureCaretView() {
        if caretView == nil {
            let v = UIView()   // plain UIView: no content pass, no dump noise
            v.isUserInteractionEnabled = false
            canvasView.addSubview(v)
            caretView = v
        }
    }

    /// Caret becomes solid immediately after any caret motion/edit.
    func revealCaret() {
        caretView?.isHidden = false
    }

    func caretBlinkChanged(visible: Bool) {
        guard isEditing else { return }
        caretView?.isHidden = !visible
    }

    /// Caret x in text space (pen 0 at the first glyph), pixel-rounded like
    /// real caretRect values.
    var caretTextX: CGFloat {
        let scale = textLabel.layoutScale
        return FontEngine.roundToPixel(
            UITextCaretMath.prefixWidth(_text, count: caretOffset, font: font),
            scale: scale)
    }

    func layoutCaret() {
        guard let caret = caretView, isEditing else { return }
        let tr = textRect(forBounds: bounds)
        // Keep the caret visible: adjust the horizontal scroll first.
        let cx = caretTextX
        let visibleW = tr.width - 2   // caret bar width stays inside
        let textW = FontEngine.measure(_text, font: font)
        var scroll = textScrollOffset
        let maxScroll = Swift.max(0, textW + 2 - tr.width)
        if cx - scroll > visibleW { scroll = cx - visibleW }
        if cx - scroll < 0 { scroll = cx }
        scroll = Swift.min(Swift.max(0, scroll), Swift.max(maxScroll, cx))
        if scroll != textScrollOffset {
            textScrollOffset = scroll
            // Re-place the text label with the new offset.
            let labelY = ((bounds.height - lineHeight) / 2 + 0.5).rounded(.down) - tr.minY
            let w = Swift.max(FontEngine.measure(_text, font: font).rounded(.up) + 2,
                              tr.width)
            textLabel.frame = CGRect(x: -textScrollOffset,
                                     y: labelY, width: w, height: lineHeight)
        }
        // Measured caret metrics: height = lineHeight + 1.5; the field's
        // line box (lineHeight + 2) is centered in the text rect and the
        // caret y floors box top + 0.25 (probe: y 6 at h 34 / 17 pt).
        let fontLineH = FontEngine.metrics(for: font).lineHeight
        let caretH = fontLineH + 1.5
        let boxTop = tr.minY + (tr.height - (fontLineH + 2)) / 2
        let caretY = (boxTop + 0.25).rounded(.down)
        caret.backgroundColor = tintColor
        caret.frame = CGRect(x: cx - textScrollOffset,
                             y: caretY - tr.minY, width: 2, height: caretH)
    }
}
