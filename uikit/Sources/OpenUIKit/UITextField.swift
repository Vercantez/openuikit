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
// scrolls horizontally to keep the caret visible. The UITextInput-compatible
// selection model uses UTF-16 document offsets, supports ranged replacement
// and marked text, and exposes deterministic single-line selection geometry.

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

#if canImport(Foundation)
// `Notification.Name` is a nested typealias on Foundation.Notification. The
// defining module must be visible where the public static notification name
// is emitted, including on Darwin where the scoped CoreGraphics branch above
// deliberately avoids an umbrella Foundation import.
import struct Foundation.Notification
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
///   - `textFieldShouldClear`        — false blocks `text = ""` via clear
///   - `textFieldShouldReturn`       — the return key's handler; UIKit does
///     NOT resign on its own, and neither do we (an app returning true
///     usually calls `resignFirstResponder()` itself)
@preconcurrency @MainActor
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
                                reason: UITextField.DidEndEditingReason) {
        // UIKit calls the reason-bearing callback on modern systems and
        // falls back to the legacy spelling when that is all a delegate
        // implements. A default forward gives pure Swift protocols the same
        // one-callback behavior without Objective-C optional dispatch.
        textFieldDidEndEditing(textField)
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {}
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool { true }
    func textFieldShouldClear(_ textField: UITextField) -> Bool { true }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { true }
}

/// Real UIKit's placeholder-label class name (private in compare.py's
/// layout diff, like the oracle's).
@preconcurrency @MainActor
final class UITextFieldLabel: UILabel {}

/// The .roundedRect chrome (private class name keeps it out of layout
/// comparison, mirroring _UITextFieldRoundedRectBackgroundViewNeue).
@preconcurrency @MainActor
final class UITextFieldBackgroundView: UIView {}

/// Clipping container for the text label + caret (mirrors
/// _UITextLayoutCanvasView).
@preconcurrency @MainActor
final class UITextFieldCanvasView: UIView {}

/// Portable vector stand-in for UIKit's SF-Symbol-backed clear button. Its
/// measured frame and interaction are exact; the glyph outline is documented
/// as an approximation because SF Symbols cannot be redistributed.
@preconcurrency @MainActor
final class UITextFieldClearButton: UIControl {
    override func stateDidChange() {
        super.stateDidChange()
        setNeedsDisplay()
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let baseCircleColor = UIColor.tertiaryLabel
            .resolvedCGColor(with: traitCollection)
        // CGColor.withAlpha multiplies the existing component, so pass only
        // the state factor (passing the resolved alpha again would square it).
        let circleColor = baseCircleColor.withAlpha(isHighlighted ? 0.65 : 1)
        canvas.fill(Path.roundedRect(bounds, cornerRadius: bounds.height / 2),
                    color: circleColor)

        let inset: CGFloat = 5.5
        var cross = Path()
        cross.move(to: CGPoint(x: bounds.minX + inset, y: bounds.minY + inset))
        cross.addLine(to: CGPoint(x: bounds.maxX - inset, y: bounds.maxY - inset))
        cross.move(to: CGPoint(x: bounds.maxX - inset, y: bounds.minY + inset))
        cross.addLine(to: CGPoint(x: bounds.minX + inset, y: bounds.maxY - inset))
        let foreground = UIColor.systemBackground.resolvedCGColor(with: traitCollection)
        canvas.stroke(cross, color: foreground, lineWidth: 1.5,
                      cap: .round, join: .round)
    }
}

/// Stable identity carried by every position minted for one field. Positions
/// from another editor are deliberately rejected rather than interpreted as
/// coincidentally matching integer offsets.
private final class UITextFieldDocumentIdentity {}

@preconcurrency @MainActor
open class UITextField: UIControl, UITextInput, UITextKeyHandling, UITextCaretHosting {

    /// Posted synchronously after user-driven text mutation, with the field as
    /// the object and no userInfo. The SDK declares this name nonisolated.
    nonisolated public static let textDidChangeNotification =
        Notification.Name("UITextFieldTextDidChangeNotification")

    /// Visibility policy shared by the clear button and custom side views.
    /// Raw values are UIKit's stable NS_ENUM values.
    public enum ViewMode: Int, Sendable {
        case never = 0
        case whileEditing = 1
        case unlessEditing = 2
        case always = 3
    }

    // MARK: Content properties

    // Keyboard traits are retained even though OpenUIKit itself owns no
    // software keyboard. A host can inspect them when choosing an input UI.
    open var autocapitalizationType: UITextAutocapitalizationType = .sentences
    open var autocorrectionType: UITextAutocorrectionType = .default
    /// The semantic credential/contact purpose is retained for the embedding
    /// keyboard or password-manager service.  OpenUIKit does not inspect or
    /// persist the entered value itself.
    open var textContentType: UITextContentType?
    open var keyboardType: UIKeyboardType = .default
    open var keyboardAppearance: UIKeyboardAppearance = .default
    open var returnKeyType: UIReturnKeyType = .default
    open var enablesReturnKeyAutomatically = false
    /// Secure entry keeps the model text unchanged while rendering one bullet
    /// per composed character. This mirrors UIKit's privacy boundary: bindings
    /// and delegates receive the real value, but neither static nor editing
    /// snapshots expose it.
    open var isSecureTextEntry = false {
        didSet {
            guard isSecureTextEntry != oldValue else { return }
            refreshContent()
        }
    }

    open var text: String? {
        get { _text.isEmpty ? (_hasText ? _text : nil) : _text }
        set {
            _text = newValue ?? ""
            _hasText = newValue != nil
            _attributed = nil
            normalizeTextStateAfterContentAssignment()
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
    open var attributedText: NSAttributedString? {
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
            normalizeTextStateAfterContentAssignment()
            refreshContent()
        }
    }
    var _attributed: NSAttributedString?

    private var _placeholder: String?
    private var _attributedPlaceholder: NSAttributedString?
    private var placeholderUsesDefaultAttributes = false

    /// The plain and attributed placeholder properties are two views of one
    /// UIKit value: assigning either updates the other's string, and nil on
    /// either side clears both (iOS 26.1 oracle).
    open var placeholder: String? {
        get { _placeholder }
        set {
            _placeholder = newValue
            placeholderUsesDefaultAttributes = newValue != nil
            _attributedPlaceholder = newValue.map(makeDefaultAttributedPlaceholder)
            refreshContent()
        }
    }

    open var attributedPlaceholder: NSAttributedString? {
        get { _attributedPlaceholder }
        set {
            _attributedPlaceholder = newValue.map(NSAttributedString.init(attributedString:))
            _placeholder = newValue?.string
            placeholderUsesDefaultAttributes = false
            refreshContent()
        }
    }

    public var font: UIFont = .systemFont(ofSize: 17) {
        didSet {
            if placeholderUsesDefaultAttributes, let placeholder = _placeholder {
                _attributedPlaceholder = makeDefaultAttributedPlaceholder(placeholder)
            }
            refreshContent()
        }
    }

    public var textColor: UIColor = .label {
        didSet { refreshContent() }
    }

    public var borderStyle: UITextFieldBorderStyle = .none {
        didSet { setNeedsLayout() }
    }

    open var clearButtonMode: ViewMode = .never {
        didSet {
            if clearButtonMode != .never { ensureClearButton() }
            setNeedsLayout()
        }
    }

    open var leftView: UIView? {
        didSet { replaceAccessoryView(oldValue, with: leftView) }
    }
    open var leftViewMode: ViewMode = .never {
        didSet { setNeedsLayout() }
    }
    open var rightView: UIView? {
        didSet { replaceAccessoryView(oldValue, with: rightView) }
    }
    open var rightViewMode: ViewMode = .never {
        didSet { setNeedsLayout() }
    }

    // MARK: Chrome metrics (measured — see header)

    static let roundedRectCornerRadius: CGFloat = 5
    /// iOS 26.1, MEASURED 2026-09-04 (scripts/ios_suite.sh textfield_basic):
    /// the .roundedRect border is a single device pixel (0.5 pt at 2x) of
    /// (219, 219, 220) over white; Catalyst's is the 0.649 pt black-20 % ring.
    /// Corner radius (5) and text inset (7, 2) match on both.
    static var roundedRectBorderWidth: CGFloat {
        OpenUIKitRuntime.systemFontCut == .iOS ? 0.5 : 0.6493506493506493
    }
    static let roundedRectTextInset = CGSize(width: 7, height: 2)
    /// Light: black 20 %; dark resolution is unverified (KNOWN_GAPS).
    static let chromeBorderColor = UIColor(.dynamic { t in
        if OpenUIKitRuntime.systemFontCut == .iOS, t.userInterfaceStyle != .dark {
            return CGColor(red: 219 / 255, green: 219 / 255, blue: 220 / 255, alpha: 1)
        }
        return t.userInterfaceStyle == .dark
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
    private var clearButton: UITextFieldClearButton?

    // MARK: Delegate (M13)

    /// UIKit's reason codes for `textFieldDidEndEditing(_:reason:)`.
    /// `.cancelled` exists for the iPad keyboard's cancel affordance, which
    /// has no equivalent here — every end is `.committed`.
    public enum DidEndEditingReason: Sendable { case committed, cancelled }

    public weak var delegate: UITextFieldDelegate?

    // MARK: Editing state

    public private(set) var isEditing = false
    private let textDocumentIdentity = UITextFieldDocumentIdentity()
    private var selectedUTF16Range: NSRange? = NSRange(location: 0, length: 0)
    private var unselectedCaretOffset = 0
    private var markedUTF16Range: NSRange?

    /// Caret position as a UTF-16 offset into `_text`. Kept public-for-tests
    /// for the original M8 harness; `selectedTextRange` is the app API.
    public internal(set) var caretOffset: Int {
        get { selectedUTF16Range?.upperBound ?? unselectedCaretOffset }
        set {
            let offset = Swift.min(Swift.max(0, newValue), documentUTF16Length)
            storeSelection(NSRange(location: offset, length: 0),
                           notifyDelegate: false)
        }
    }
    /// Horizontal scroll of overflowing text (points, >= 0).
    public internal(set) var textScrollOffset: CGFloat = 0

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureTextFieldViews()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureTextFieldViews()
    }

    private func configureTextFieldViews() {
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

    private func makeDefaultAttributedPlaceholder(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text,
                           attributes: [.font: font,
                                        .foregroundColor: UIColor.placeholderText])
    }

    private func replaceAccessoryView(_ oldView: UIView?, with newView: UIView?) {
        guard oldView !== newView else { return }
        oldView?.removeFromSuperview()
        setNeedsLayout()
    }

    /// UIKit keeps an inactive accessory detached while preserving its last
    /// frame, bounds, and caller-controlled `isHidden` value. Attachment is
    /// reconciled in layout (not synchronously from the property setters).
    private func layoutAccessoryView(_ view: UIView, mode viewMode: ViewMode,
                                     frame: @autoclosure () -> CGRect) {
        if mode(viewMode, showsForEditing: isEditing) {
            if view.superview !== self { addSubview(view) }
            view.frame = frame()
        } else if view.superview === self {
            view.removeFromSuperview()
        }
    }

    private func ensureClearButton() {
        if let clearButton {
            if clearButton.superview !== self { addSubview(clearButton) }
            return
        }
        let button = UITextFieldClearButton()
        button.isOpaque = false
        button.addTarget(for: .touchUpInside) { [weak self] _, _ in
            _ = self?._clear()
        }
        clearButton = button
        addSubview(button)
    }

    private func mode(_ mode: ViewMode, showsForEditing editing: Bool) -> Bool {
        switch mode {
        case .never: return false
        case .whileEditing: return editing
        case .unlessEditing: return !editing
        case .always: return true
        }
    }

    private var shouldShowRightView: Bool {
        rightView != nil && mode(rightViewMode, showsForEditing: isEditing)
    }

    private var isClearButtonModeActive: Bool {
        mode(clearButtonMode, showsForEditing: isEditing)
    }

    private var shouldShowClearButton: Bool {
        !_text.isEmpty
            && isClearButtonModeActive
            && !shouldShowRightView
    }

    // MARK: UTF-16 document model

    private var documentUTF16Length: Int { _text.utf16.count }

    private func makePosition(_ offset: Int) -> UITextPosition {
        UITextPosition(document: textDocumentIdentity, utf16Offset: offset)
    }

    private func validatedOffset(_ position: UITextPosition) -> Int? {
        guard position._document === textDocumentIdentity,
              let offset = position._utf16Offset,
              offset >= 0, offset <= documentUTF16Length else { return nil }
        return offset
    }

    private func validatedRange(_ range: UITextRange) -> NSRange? {
        guard range._isOpenUIKitRange,
              let first = validatedOffset(range.start),
              let second = validatedOffset(range.end) else { return nil }
        let lower = Swift.min(first, second)
        let upper = Swift.max(first, second)
        return NSRange(location: lower, length: upper - lower)
    }

    private func makeRange(_ range: NSRange) -> UITextRange {
        UITextRange(start: makePosition(range.location),
                    end: makePosition(range.upperBound))
    }

    private func clampedOffset(_ offset: Int) -> Int {
        Swift.min(Swift.max(0, offset), documentUTF16Length)
    }

    private func clampedRange(_ range: NSRange) -> NSRange {
        let start = clampedOffset(range.location)
        // All internally stored ranges are already non-overflowing, but this
        // saturating form also handles NSNotFound/hostile marked selections.
        let proposedEnd: Int
        let nonnegativeLength = Swift.max(0, range.length)
        let (sum, overflow) = range.location.addingReportingOverflow(nonnegativeLength)
        if overflow {
            proposedEnd = Int.max
        } else {
            proposedEnd = sum
        }
        let end = clampedOffset(proposedEnd)
        let lower = Swift.min(start, end)
        let upper = Swift.max(start, end)
        return NSRange(location: lower, length: upper - lower)
    }

    private func storeSelection(_ range: NSRange?, notifyDelegate: Bool,
                                preserveMarkedText: Bool = false) {
        let old = selectedUTF16Range
        if let range {
            let clamped = clampedRange(range)
            selectedUTF16Range = clamped
            unselectedCaretOffset = clamped.upperBound
            if !preserveMarkedText, let marked = markedUTF16Range,
               clamped.location < marked.location || clamped.upperBound > marked.upperBound {
                markedUTF16Range = nil
            }
        } else {
            selectedUTF16Range = nil
        }

        guard old != selectedUTF16Range else { return }
        if selectedUTF16Range != nil {
            revealCaret()
            revealSelectionEnd()
        } else {
            caretView?.isHidden = true
        }
        setNeedsLayout()
        if notifyDelegate { delegate?.textFieldDidChangeSelection(self) }
    }

    private func normalizeTextStateAfterContentAssignment() {
        let oldSelection = selectedUTF16Range
        if let oldSelection {
            let oldStart = oldSelection.location
            let oldEnd = oldSelection.upperBound
            let start = clampedOffset(oldStart)
            let end = clampedOffset(oldEnd)
            selectedUTF16Range = NSRange(location: Swift.min(start, end),
                                         length: Swift.max(start, end) - Swift.min(start, end))
            unselectedCaretOffset = selectedUTF16Range!.upperBound
        } else {
            unselectedCaretOffset = clampedOffset(unselectedCaretOffset)
        }
        markedUTF16Range = nil
    }

    private func utf16Slice(_ range: NSRange) -> String {
        let units = Array(_text.utf16)
        return String(decoding: units[range.location..<range.upperBound], as: UTF16.self)
    }

    private func prefix(toUTF16Offset offset: Int) -> String {
        let units = Array(_text.utf16)
        return String(decoding: units[0..<clampedOffset(offset)], as: UTF16.self)
    }

    private func replacingUTF16(_ range: NSRange, with replacement: String) -> String {
        var units = Array(_text.utf16)
        units.replaceSubrange(range.location..<range.upperBound, with: replacement.utf16)
        return String(decoding: units, as: UTF16.self)
    }

    /// UTF-16 offsets at Swift Character boundaries. UIKit document methods
    /// accept every code-unit boundary, but keyboard arrows/backspace operate
    /// on composed characters (verified with surrogate and combining probes).
    private var characterBoundaries: [Int] {
        var result: [Int] = []
        result.reserveCapacity(_text.count + 1)
        for index in _text.indices {
            if let utf16Index = index.samePosition(in: _text.utf16) {
                result.append(_text.utf16.distance(from: _text.utf16.startIndex,
                                                   to: utf16Index))
            }
        }
        let end = documentUTF16Length
        if result.last != end { result.append(end) }
        return result
    }

    private func previousCharacterBoundary(before offset: Int) -> Int {
        characterBoundaries.last(where: { $0 < offset }) ?? 0
    }

    private func nextCharacterBoundary(after offset: Int) -> Int {
        characterBoundaries.first(where: { $0 > offset }) ?? documentUTF16Length
    }

    private func utf16Offset(forScalarOffset scalarOffset: Int) -> Int {
        let index = UITextCaretMath.index(_text, atScalarOffset: scalarOffset)
        guard let utf16Index = index.samePosition(in: _text.utf16) else {
            return documentUTF16Length
        }
        return _text.utf16.distance(from: _text.utf16.startIndex, to: utf16Index)
    }

    private func mutate(_ range: NSRange, replacement: String,
                        consultDelegate: Bool, emitEditingChanged: Bool) -> Bool {
        if consultDelegate, let delegate,
           !delegate.textField(self, shouldChangeCharactersIn: range,
                               replacementString: replacement) { return false }

        _text = replacingUTF16(range, with: replacement)
        _hasText = true
        _attributed = nil
        markedUTF16Range = nil
        let insertionEnd = range.location + replacement.utf16.count
        storeSelection(NSRange(location: insertionEnd, length: 0),
                       notifyDelegate: false)
        refreshContent()
        revealCaret()
        revealSelectionEnd()
        delegate?.textFieldDidChangeSelection(self)
        if emitEditingChanged {
            sendActions(for: .editingChanged)
            NotificationCenter.default.post(name: Self.textDidChangeNotification,
                                            object: self)
        }
        return true
    }

    // MARK: UITextInput document API

    open var beginningOfDocument: UITextPosition { makePosition(0) }
    open var endOfDocument: UITextPosition { makePosition(documentUTF16Length) }

    open var selectedTextRange: UITextRange? {
        get { selectedUTF16Range.map(makeRange) }
        set {
            guard let newValue else {
                // Although UITextInput permits no selection, UITextField
                // normalizes a nil assignment to a caret at document start.
                // An active IME mark survives this cursor-reset operation.
                storeSelection(NSRange(location: 0, length: 0),
                               notifyDelegate: true, preserveMarkedText: true)
                return
            }
            guard let range = validatedRange(newValue) else { return }
            storeSelection(range, notifyDelegate: true)
        }
    }

    open var markedTextRange: UITextRange? {
        markedUTF16Range.map(makeRange)
    }

    open func text(in range: UITextRange) -> String? {
        guard let range = validatedRange(range) else { return nil }
        return utf16Slice(range)
    }

    open func replace(_ range: UITextRange, withText text: String) {
        guard let range = validatedRange(range) else { return }
        // Direct UITextInput replacement is lower-level than keyboard entry:
        // UIKit bypasses UITextFieldDelegate's mutation gate and the control's
        // editingChanged event, but does report the resulting selection.
        _ = mutate(range, replacement: text, consultDelegate: false,
                   emitEditingChanged: false)
    }

    open func textRange(from fromPosition: UITextPosition,
                        to toPosition: UITextPosition) -> UITextRange? {
        guard let from = validatedOffset(fromPosition),
              let to = validatedOffset(toPosition) else { return nil }
        let lower = Swift.min(from, to)
        let upper = Swift.max(from, to)
        return makeRange(NSRange(location: lower, length: upper - lower))
    }

    open func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let start = validatedOffset(position) else { return nil }
        let result: Int
        if offset > 0, start > Int.max - offset { return nil }
        if offset == Int.min { return nil }
        if offset < 0, start < -offset { return nil }
        result = start + offset
        guard result >= 0, result <= documentUTF16Length else { return nil }
        return makePosition(result)
    }

    open func offset(from: UITextPosition, to: UITextPosition) -> Int {
        guard let first = validatedOffset(from), let second = validatedOffset(to) else { return 0 }
        return second - first
    }

    open func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        guard let markedText, !markedText.isEmpty else {
            if let markedUTF16Range {
                _ = mutate(markedUTF16Range, replacement: "",
                           consultDelegate: false, emitEditingChanged: false)
            } else {
                unmarkText()
            }
            return
        }
        let target = markedUTF16Range ?? selectedUTF16Range
            ?? NSRange(location: unselectedCaretOffset, length: 0)
        _text = replacingUTF16(target, with: markedText)
        _hasText = true
        _attributed = nil
        let markedLength = markedText.utf16.count
        markedUTF16Range = NSRange(location: target.location, length: markedLength)

        let relativeStart = Swift.min(Swift.max(0, selectedRange.location), markedLength)
        let remaining = markedLength - relativeStart
        let relativeLength = Swift.min(Swift.max(0, selectedRange.length), remaining)
        storeSelection(NSRange(location: target.location + relativeStart,
                               length: relativeLength),
                       notifyDelegate: false, preserveMarkedText: true)
        refreshContent()
        revealCaret()
        revealSelectionEnd()
        delegate?.textFieldDidChangeSelection(self)
    }

    open func unmarkText() {
        markedUTF16Range = nil
    }

    /// Standard responder action. UIKit first focuses an attached field, then
    /// selects its entire UTF-16 document. A detached/disabled field cannot
    /// become first responder and leaves its existing selection untouched.
    open override func selectAll(_ sender: Any?) {
        guard isFirstResponder || becomeFirstResponder() else { return }
        storeSelection(NSRange(location: 0, length: documentUTF16Length),
                       notifyDelegate: true)
    }

    func refreshContent() {
        textLabel.font = font
        textLabel.textColor = textColor
        if isSecureTextEntry {
            textLabel.text = secureDisplayText
        } else if let a = _attributed {
            textLabel.attributedText = a
        } else {
            textLabel.text = _text
        }
        placeholderLabel.font = font
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.attributedText = _attributedPlaceholder
        textLabel.isHidden = _text.isEmpty
        placeholderLabel.isHidden = !_text.isEmpty || (_placeholder ?? "").isEmpty
        setNeedsLayout()
    }

    private var secureDisplayText: String {
        String(repeating: "\u{2022}", count: _text.count)
    }

    private var renderedText: String {
        isSecureTextEntry ? secureDisplayText : _text
    }

    // MARK: Geometry (measured)

    var lineHeight: CGFloat { FontEngine.labelLineHeight(for: font) }

    open func borderRect(forBounds bounds: CGRect) -> CGRect { bounds }

    open func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect: CGRect
        switch borderStyle {
        case .roundedRect, .bezel, .line:
            rect = bounds.insetBy(dx: UITextField.roundedRectTextInset.width,
                                  dy: UITextField.roundedRectTextInset.height)
        case .none:
            rect = bounds
        }

        if let leftView, mode(leftViewMode, showsForEditing: isEditing) {
            rect.origin.x += leftView.bounds.width
            rect.size.width -= leftView.bounds.width
        }
        if rightView != nil, mode(rightViewMode, showsForEditing: isEditing) {
            let rightEdge = rightViewRect(forBounds: bounds).minX
            rect.size.width = Swift.min(rect.maxX, rightEdge) - rect.minX
        }
        if shouldShowClearButton {
            let clearEdge = clearButtonRect(forBounds: bounds).minX - 29.0 / 3.0
            rect.size.width = Swift.min(rect.maxX, clearEdge) - rect.minX
        }
        rect.size.width = Swift.max(0, rect.width)
        return rect
    }

    open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

    open func editingRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

    open func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        // iOS 26.1 bases this hook on MODE ACTIVITY, not text presence or the
        // existence of a visible private control. For a 200x34 field an active
        // clear mode uses (175, 8, 19.667, 19), even with empty text. An
        // inactive mode uses (176, 8, 19, 19). An active right view suppresses
        // the clear control and also selects the latter hook geometry.
        let usesActiveClearGeometry = isClearButtonModeActive && !shouldShowRightView
        let width: CGFloat = usesActiveClearGeometry ? 59.0 / 3.0 : 19
        let height: CGFloat = 19
        let trailingInset: CGFloat = usesActiveClearGeometry ? 16.0 / 3.0 : 5
        let x = bounds.maxX - width - trailingInset
        let y = bounds.minY
            + ((bounds.height - height) / 2).rounded(.toNearestOrAwayFromZero)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    open func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        guard let leftView else { return .zero }
        return CGRect(x: bounds.minX,
                      y: FontEngine.ceilToPixel(
                        bounds.minY + ((bounds.height - leftView.bounds.height) / 2),
                        scale: textLabel.layoutScale),
                      width: leftView.bounds.width, height: leftView.bounds.height)
    }

    open func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        guard let rightView else { return .zero }
        return CGRect(x: bounds.maxX - rightView.bounds.width,
                      y: FontEngine.ceilToPixel(
                        bounds.minY + ((bounds.height - rightView.bounds.height) / 2),
                        scale: textLabel.layoutScale),
                      width: rightView.bounds.width, height: rightView.bounds.height)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }

    open override var intrinsicContentSize: CGSize {
        let scale = textLabel.layoutScale
        let base: CGFloat
        if !isSecureTextEntry, _attributed != nil, !_text.isEmpty {
            // Attributed: measured with the field's single `font` (see the
            // attributedText setter), ceiled to the pixel grid.
            base = Swift.max(FontEngine.ceilToPixel(FontEngine.measure(_text, font: font),
                                                    scale: scale), 5)
        } else if !_text.isEmpty {
            base = Swift.max(FontEngine.measure(renderedText, font: font).rounded(.up), 5)
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
            backgroundView.frame = borderRect(forBounds: bounds)
            backgroundView.backgroundColor = UITextField.chromeFillColor
            backgroundView.layer.cornerRadius = UITextField.roundedRectCornerRadius
            backgroundView.layer.borderWidth = UITextField.roundedRectBorderWidth
            backgroundView.layer.borderColor =
                UITextField.chromeBorderColor.resolvedCGColor(with: traitCollection)
        }
        if let leftView {
            layoutAccessoryView(leftView, mode: leftViewMode,
                                frame: leftViewRect(forBounds: bounds))
        }
        if let rightView {
            layoutAccessoryView(rightView, mode: rightViewMode,
                                frame: rightViewRect(forBounds: bounds))
        }
        let showsClearButton = shouldShowClearButton
        if showsClearButton { ensureClearButton() }
        if let clearButton {
            if shouldShowRightView {
                // Measured iOS 26.1 precedence: an active rightView removes
                // the private clear control from the hierarchy, independent
                // of which property was assigned first.
                clearButton.removeFromSuperview()
            } else {
                clearButton.isHidden = !showsClearButton
                clearButton.frame = showsClearButton
                    ? clearButtonRect(forBounds: bounds) : .zero
            }
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
            let w = Swift.max(FontEngine.measure(renderedText, font: font).rounded(.up) + 2,
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
            storeSelection(NSRange(location: documentUTF16Length, length: 0),
                           notifyDelegate: false)
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
        let scalarOffset = UITextCaretMath.caretIndex(for: x, text: _text, font: font)
        let offset = utf16Offset(forScalarOffset: scalarOffset)
        storeSelection(NSRange(location: offset, length: 0),
                       notifyDelegate: wasEditing)
        if wasEditing {
            UITextInputState.noteActivity(at: OpenUIKitRuntime.animationTime)
        }
        revealCaret()
        setNeedsLayout()
    }

    // MARK: UIKeyInput

    public var hasText: Bool { !_text.isEmpty }

    open func insertText(_ text: String) {
        guard isEditing else { return }
        let target = markedUTF16Range ?? selectedUTF16Range
            ?? NSRange(location: unselectedCaretOffset, length: 0)
        _ = mutate(target, replacement: text, consultDelegate: true,
                   emitEditingChanged: true)
    }

    open func deleteBackward() {
        guard isEditing else { return }
        let selection = selectedUTF16Range
            ?? NSRange(location: unselectedCaretOffset, length: 0)
        let target: NSRange
        if selection.length > 0 {
            target = selection
        } else {
            guard selection.location > 0 else { return }
            let previous = previousCharacterBoundary(before: selection.location)
            let next = nextCharacterBoundary(after: selection.location)
            // A UITextPosition may sit between UTF-16 surrogate code units,
            // but backspace still removes the containing composed character.
            let end = characterBoundaries.contains(selection.location)
                ? selection.location : next
            target = NSRange(location: previous, length: end - previous)
        }
        _ = mutate(target, replacement: "", consultDelegate: true,
                   emitEditingChanged: true)
    }

    /// UIKit's clear-button path, minus the button (no clear-button chrome is
    /// measured yet — see docs/KNOWN_GAPS.md). Exposed so an app that draws
    /// its own clear affordance gets the delegate gate UIKit gives it.
    @discardableResult
    public func _clear() -> Bool {
        if let d = delegate, !d.textFieldShouldClear(self) { return false }
        // Real clear-button interaction leaves a non-nil empty string.
        text = ""
        storeSelection(NSRange(location: 0, length: 0), notifyDelegate: false)
        sendActions(for: .editingChanged)
        NotificationCenter.default.post(name: Self.textDidChangeNotification,
                                        object: self)
        return true
    }

    func handleKey(_ key: UIKeyEventKey) {
        guard isEditing else { return }
        switch key {
        case .backspace:
            deleteBackward()
        case .left:
            let range = selectedUTF16Range
                ?? NSRange(location: unselectedCaretOffset, length: 0)
            let destination = range.length > 0
                ? range.location
                : previousCharacterBoundary(before: range.location)
            storeSelection(NSRange(location: destination, length: 0),
                           notifyDelegate: true)
            revealCaret()
            setNeedsLayout()
        case .right:
            let range = selectedUTF16Range
                ?? NSRange(location: unselectedCaretOffset, length: 0)
            let destination = range.length > 0
                ? range.upperBound
                : nextCharacterBoundary(after: range.upperBound)
            storeSelection(NSRange(location: destination, length: 0),
                           notifyDelegate: true)
            revealCaret()
            setNeedsLayout()
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

    private func revealSelectionEnd() {
        setNeedsLayout()
    }

    func caretBlinkChanged(visible: Bool) {
        guard isEditing else { return }
        caretView?.isHidden = !visible
    }

    /// Caret x in text space (pen 0 at the first glyph), pixel-rounded like
    /// real caretRect values.
    var caretTextX: CGFloat {
        textX(atUTF16Offset: caretOffset)
    }

    private func textX(atUTF16Offset offset: Int) -> CGFloat {
        let scale = textLabel.layoutScale
        // Document offsets may address the interior of a surrogate pair or
        // combining sequence, but glyph geometry cannot. UIKit anchors such
        // positions at the composed character's leading edge rather than
        // measuring a repaired UTF-16 prefix containing U+FFFD.
        let geometryOffset = characterBoundaries.last(where: {
            $0 <= clampedOffset(offset)
        }) ?? 0
        let modelPrefix = prefix(toUTF16Offset: geometryOffset)
        let displayPrefix = isSecureTextEntry
            ? String(repeating: "\u{2022}", count: modelPrefix.count)
            : modelPrefix
        return FontEngine.roundToPixel(
            FontEngine.measure(displayPrefix, font: font),
            scale: scale)
    }

    private var caretVerticalMetrics: (y: CGFloat, height: CGFloat) {
        let tr = textRect(forBounds: bounds)
        let fontLineHeight = FontEngine.metrics(for: font).lineHeight
        let height = fontLineHeight + 1.5
        let boxTop = tr.minY + (tr.height - (fontLineHeight + 2)) / 2
        return ((boxTop + 0.25).rounded(.down), height)
    }

    /// UIKit reports a one-point caret rect even though the visible iOS bar
    /// is two points wide. Geometry is in the text field's coordinate space.
    open func caretRect(for position: UITextPosition) -> CGRect {
        guard let offset = validatedOffset(position) else { return .zero }
        let tr = textRect(forBounds: bounds)
        let metrics = caretVerticalMetrics
        return CGRect(x: tr.minX + textX(atUTF16Offset: offset) - textScrollOffset,
                      y: metrics.y, width: 1, height: metrics.height)
    }

    open func firstRect(for range: UITextRange) -> CGRect {
        guard let range = validatedRange(range) else { return .zero }
        if range.length == 0 { return caretRect(for: makePosition(range.location)) }
        let tr = textRect(forBounds: bounds)
        let metrics = caretVerticalMetrics
        let firstX = textX(atUTF16Offset: range.location)
        let secondX = textX(atUTF16Offset: range.upperBound)
        return CGRect(x: tr.minX + Swift.min(firstX, secondX) - textScrollOffset,
                      y: metrics.y,
                      width: Swift.abs(secondX - firstX),
                      height: metrics.height)
    }

    open func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        guard let range = validatedRange(range), range.length > 0 else { return [] }
        return [UITextSelectionRect(rect: firstRect(for: makeRange(range)),
                                    containsStart: true, containsEnd: true)]
    }

    func layoutCaret() {
        guard let caret = caretView, isEditing else { return }
        let tr = textRect(forBounds: bounds)
        // Keep the caret visible: adjust the horizontal scroll first.
        let cx = caretTextX
        let visibleW = tr.width - 2   // caret bar width stays inside
        let textW = FontEngine.measure(renderedText, font: font)
        var scroll = textScrollOffset
        let maxScroll = Swift.max(0, textW + 2 - tr.width)
        if cx - scroll > visibleW { scroll = cx - visibleW }
        if cx - scroll < 0 { scroll = cx }
        scroll = Swift.min(Swift.max(0, scroll), Swift.max(maxScroll, cx))
        if scroll != textScrollOffset {
            textScrollOffset = scroll
            // Re-place the text label with the new offset.
            let labelY = ((bounds.height - lineHeight) / 2 + 0.5).rounded(.down) - tr.minY
            let w = Swift.max(FontEngine.measure(renderedText, font: font).rounded(.up) + 2,
                              tr.width)
            textLabel.frame = CGRect(x: -textScrollOffset,
                                     y: labelY, width: w, height: lineHeight)
        }
        // Measured caret metrics: height = lineHeight + 1.5; the field's
        // line box (lineHeight + 2) is centered in the text rect and the
        // caret y floors box top + 0.25 (probe: y 6 at h 34 / 17 pt).
        let metrics = caretVerticalMetrics
        caret.backgroundColor = tintColor
        caret.frame = CGRect(x: cx - textScrollOffset,
                             y: metrics.y - tr.minY, width: 2, height: metrics.height)
    }
}
