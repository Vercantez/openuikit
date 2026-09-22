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
// `@objc` members (OPENUIKIT_OBJC_SUBCLASSING) need Foundation in scope; a
// scoped declaration import keeps its geometry out of this file (UIView.swift).
#if OPENUIKIT_OBJC_SUBCLASSING
import struct Foundation.Data
#endif

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


/// MEASURED iPhone 16 / iOS 26.1: raw values 0...3, a fresh field reads
/// `.none` (ios-oss-launch.md probe).
public enum UITextFieldBorderStyle: Int, Sendable {
    case none = 0, line = 1, bezel = 2, roundedRect = 3
}

extension UITextField {
    /// Swift's nested spelling of `UITextBorderStyle`.
    public typealias BorderStyle = UITextFieldBorderStyle
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
    /// Glyph colours, supplied by the owning field (`clearButtonPalette`):
    /// a plain field draws `tertiaryLabel` knocked out to `systemBackground`,
    /// a search field `secondaryLabel` knocked out to the pill's fill.
    var circleColor: UIColor = .tertiaryLabel
    var knockoutColor: UIColor = .systemBackground
    /// The filled circle's diameter. Zero (the default) means "fill the
    /// button's bounds", which is the plain field's measured geometry.
    var circleDiameter: CGFloat = 0
    /// Tip-to-tip length of the knocked-out cross, round caps included.
    /// Zero means the plain field's fixed 5.5 pt inset.
    var crossSpan: CGFloat = 0

    override func stateDidChange() {
        super.stateDidChange()
        setNeedsDisplay()
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        var circle = bounds
        if circleDiameter > 0 {
            circle = CGRect(x: bounds.midX - circleDiameter / 2,
                            y: bounds.midY - circleDiameter / 2,
                            width: circleDiameter, height: circleDiameter)
        }
        let baseCircleColor = circleColor.resolvedCGColor(with: traitCollection)
        // CGColor.withAlpha multiplies the existing component, so pass only
        // the state factor (passing the resolved alpha again would square it).
        let color = baseCircleColor.withAlpha(isHighlighted ? 0.65 : 1)
        canvas.fill(Path.roundedRect(circle, cornerRadius: circle.height / 2),
                    color: color)

        let lineWidth: CGFloat = 1.5
        // The round caps add half a line width past each tip, so a cross that
        // reads `crossSpan` tip to tip is inset by (d - crossSpan + w) / 2.
        let inset = crossSpan > 0 ? (circle.height - crossSpan + lineWidth) / 2 : 5.5
        var cross = Path()
        cross.move(to: CGPoint(x: circle.minX + inset, y: circle.minY + inset))
        cross.addLine(to: CGPoint(x: circle.maxX - inset, y: circle.maxY - inset))
        cross.move(to: CGPoint(x: circle.maxX - inset, y: circle.minY + inset))
        cross.addLine(to: CGPoint(x: circle.minX + inset, y: circle.maxY - inset))
        let foreground = knockoutColor.resolvedCGColor(with: traitCollection)
        canvas.stroke(cross, color: foreground, lineWidth: lineWidth,
                      cap: .round, join: .round)
    }
}

/// Stable identity carried by every position minted for one field. Positions
/// from another editor are deliberately rejected rather than interpreted as
/// coincidentally matching integer offsets.
private final class UITextFieldDocumentIdentity {}

// Objective-C runtime name = UIKit's, and header macro SWIFT_CLASS_NAMED:
// Objective-C app classes may subclass it (vtable-free, see
// ObjCSubclassing.swift).
#if OPENUIKIT_OBJC_SUBCLASSING
@objc(UITextField)
#endif
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
    public final var autocapitalizationType: UITextAutocapitalizationType = .sentences
    public final var autocorrectionType: UITextAutocorrectionType = .default
    public final var spellCheckingType: UITextSpellCheckingType = .default
    /// The semantic credential/contact purpose is retained for the embedding
    /// keyboard or password-manager service.  OpenUIKit does not inspect or
    /// persist the entered value itself.
    public final var textContentType: UITextContentType?
    public final var keyboardType: UIKeyboardType = .default
    public final var keyboardAppearance: UIKeyboardAppearance = .default
    public final var returnKeyType: UIReturnKeyType = .default
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var enablesReturnKeyAutomatically = false
    /// Secure entry keeps the model text unchanged while rendering one bullet
    /// per composed character. This mirrors UIKit's privacy boundary: bindings
    /// and delegates receive the real value, but neither static nor editing
    /// snapshots expose it.
    /// Backing store; the property below carries UIKit's Objective-C
    /// spelling (`getter=isSecureTextEntry`, `setSecureTextEntry:`) so an Objective-C
    /// subclass's `-setSecureTextEntry:` override is what Swift-side sets reach.
    final var _isSecureTextEntryStorage: Bool = false
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(secureTextEntry)
#endif
    open dynamic var isSecureTextEntry: Bool {
#if OPENUIKIT_OBJC_SUBCLASSING
        @objc(isSecureTextEntry)
#endif
        get { _isSecureTextEntryStorage }
#if OPENUIKIT_OBJC_SUBCLASSING
        @objc(setSecureTextEntry:)
#endif
        set {
            let oldValue = _isSecureTextEntryStorage
            _isSecureTextEntryStorage = newValue
                guard isSecureTextEntry != oldValue else { return }
                refreshContent()
        
        }
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var text: String? {
        get { _text.isEmpty ? (_hasText ? _text : nil) : _text }
        set {
            _text = newValue ?? ""
            _hasText = newValue != nil
            _attributed = nil
            normalizeTextStateAfterContentAssignment()
            if isEditing {
                // Forms typeName / Tabs typeSearch assign `.text` while
                // focused. MEASURED kbstateprobe has_text: caret at end
                // (sel 11/11) and lowercase keys; t2100 goldens show
                // QuickType for the typed string.
                storeSelection(NSRange(location: documentUTF16Length, length: 0),
                           notifyDelegate: false)
                if let w = window { _UIKeyboardChrome.sync(from: w) }
            }
            refreshContent()
        }
    }
    final var _text: String = ""
    final var _hasText = false

    /// Attributed content (M12). Rendering goes through the same
    /// UITextFieldLabel the plain path uses, so per-run fonts/colors/kern
    /// land unchanged. Editing rewrites the plain string and DROPS the
    /// attributes (documented in docs/KNOWN_GAPS.md — real UIKit keeps
    /// typing attributes; we do not model them).
    public final var attributedText: NSAttributedString? {
        get {
            if let a = _attributed { return a }
            guard _hasText || !_text.isEmpty else { return nil }
            return NSAttributedString(string: _text,
                                      attributes: [.font: _font, .foregroundColor: _textColor])
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
                if let f = attrs[.font] as? UIFont { _font = f }
                if let c = attrs[.foregroundColor] as? UIColor { textColor = c }
            }
            normalizeTextStateAfterContentAssignment()
            refreshContent()
        }
    }
    final var _attributed: NSAttributedString?

    private final var _placeholder: String?
    private final var _attributedPlaceholder: NSAttributedString?
    private final var placeholderUsesDefaultAttributes = false

    /// The plain and attributed placeholder properties are two views of one
    /// UIKit value: assigning either updates the other's string, and nil on
    /// either side clears both (iOS 26.1 oracle).
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var placeholder: String? {
        get { _placeholder }
        set {
            _placeholder = newValue
            placeholderUsesDefaultAttributes = newValue != nil
            _attributedPlaceholder = newValue.map(makeDefaultAttributedPlaceholder)
            refreshContent()
        }
    }

    public final var attributedPlaceholder: NSAttributedString? {
        get { _attributedPlaceholder }
        set {
            _attributedPlaceholder = newValue.map(NSAttributedString.init(attributedString:))
            _placeholder = newValue?.string
            placeholderUsesDefaultAttributes = false
            refreshContent()
        }
    }

    /// UIKit declares `font` nullable. MEASURED iPhone 16 / iOS 26.1
    /// (iososswallsprobe `lens.textField.font.*`): a fresh field reads
    /// `.SFUI-Regular` 17, and after `= nil` it reads the same font again —
    /// nil resets to the default.
    public final var font: UIFont? {
        get { _font }
        set { _font = newValue ?? .systemFont(ofSize: 17) }
    }
    final var _font: UIFont = .systemFont(ofSize: 17) {
        didSet {
            if placeholderUsesDefaultAttributes, let placeholder = _placeholder {
                _attributedPlaceholder = makeDefaultAttributedPlaceholder(placeholder)
            }
            refreshContent()
        }
    }

    /// UIKit declares `textColor` nullable. MEASURED iPhone 16 / iOS 26.1: a
    /// fresh field reads `labelColor`, and assigning nil reads `labelColor`
    /// again (ios-oss-launch.md probe) — nil resets to the default, it is
    /// never observed.
    public final var textColor: UIColor? {
        get { _textColor }
        set { _textColor = newValue ?? .label }
    }
    private final var _textColor: UIColor = .label {
        didSet { refreshContent() }
    }

    /// UIKit's `textAlignment` (iOS 26.1 default `.natural`, raw 4 —
    /// iososswallsprobe `lens.textField.textAlignment.default`). Stored
    /// only: the field keeps drawing its text leading-aligned.
    public final var textAlignment: NSTextAlignment = .natural

    public final var borderStyle: UITextFieldBorderStyle = .none {
        didSet { setNeedsLayout() }
    }

    public final var clearButtonMode: ViewMode = .never {
        didSet {
            if clearButtonMode != .never { ensureClearButton() }
            setNeedsLayout()
        }
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var leftView: UIView? {
        didSet { replaceAccessoryView(oldValue, with: leftView) }
    }
    public final var leftViewMode: ViewMode = .never {
        didSet { setNeedsLayout() }
    }
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var rightView: UIView? {
        didSet { replaceAccessoryView(oldValue, with: rightView) }
    }
    public final var rightViewMode: ViewMode = .never {
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

    final let backgroundView = UITextFieldBackgroundView()
    final let canvasView = UITextFieldCanvasView()
    final let textLabel = UITextFieldLabel()
    final let placeholderLabel = UITextFieldLabel()
    /// Created lazily on first edit so static scenes/layout dumps never
    /// see it (a plain UIView: background = tint bar).
    final var caretView: UIView?
    private final var clearButton: UITextFieldClearButton?

    // MARK: Delegate (M13)

    /// UIKit's reason codes for `textFieldDidEndEditing(_:reason:)`.
    /// `.cancelled` exists for the iPad keyboard's cancel affordance, which
    /// has no equivalent here — every end is `.committed`.
    public enum DidEndEditingReason: Sendable { case committed, cancelled }

    public weak final var delegate: UITextFieldDelegate?

    // MARK: Editing state

    public private(set) final var isEditing = false
    private final let textDocumentIdentity = UITextFieldDocumentIdentity()
    private final var selectedUTF16Range: NSRange? = NSRange(location: 0, length: 0)
    private final var unselectedCaretOffset = 0
    private final var markedUTF16Range: NSRange?

    /// Caret position as a UTF-16 offset into `_text`. Kept public-for-tests
    /// for the original M8 harness; `selectedTextRange` is the app API.
    public internal(set) final var caretOffset: Int {
        get { selectedUTF16Range?.upperBound ?? unselectedCaretOffset }
        set {
            let offset = Swift.min(Swift.max(0, newValue), documentUTF16Length)
            storeSelection(NSRange(location: offset, length: 0),
                           notifyDelegate: false)
        }
    }
    /// Horizontal scroll of overflowing text (points, >= 0).
    public internal(set) final var textScrollOffset: CGFloat = 0

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureTextFieldViews()
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    public required dynamic init?(coder: NSCoder) {
        super.init(coder: coder)
        configureTextFieldViews()
    }

    private final func configureTextFieldViews() {
        isOpaque = false
        backgroundView.isUserInteractionEnabled = false
        canvasView.isUserInteractionEnabled = false
        canvasView.clipsToBounds = true
        textLabel.font = _font
        placeholderLabel.font = _font
        placeholderLabel.textColor = .placeholderText
        addSubview(backgroundView)
        addSubview(canvasView)
        canvasView.addSubview(textLabel)
        canvasView.addSubview(placeholderLabel)
        refreshContent()
    }

    /// Colour of a placeholder the field itself built (an app-supplied
    /// `attributedPlaceholder` carries its own). `UISearchTextField`
    /// overrides it.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    dynamic var defaultPlaceholderColor: UIColor { .placeholderText }

    private final func makeDefaultAttributedPlaceholder(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text,
                           attributes: [.font: _font,
                                        .foregroundColor: defaultPlaceholderColor])
    }

    private final func replaceAccessoryView(_ oldView: UIView?, with newView: UIView?) {
        guard oldView !== newView else { return }
        oldView?.removeFromSuperview()
        setNeedsLayout()
    }

    /// UIKit keeps an inactive accessory detached while preserving its last
    /// frame, bounds, and caller-controlled `isHidden` value. Attachment is
    /// reconciled in layout (not synchronously from the property setters).
    private final func layoutAccessoryView(_ view: UIView, mode viewMode: ViewMode,
                                     frame: @autoclosure () -> CGRect) {
        if mode(viewMode, showsForEditing: isEditing) {
            if view.superview !== self { addSubview(view) }
            view.frame = frame()
        } else if view.superview === self {
            view.removeFromSuperview()
        }
    }

    /// Clear-glyph colours. `UISearchTextField` overrides both.
    /// Vtable-free (OPENUIKIT_OBJC_SUBCLASSING): a tuple is not an
    /// Objective-C type, so UISearchTextField's override is a type check.
    final var clearButtonPalette: (circle: UIColor, knockout: UIColor) {
        if let search = self as? UISearchTextField { return search._searchClearButtonPalette }
        return _fieldClearButtonPalette
    }
    final var _fieldClearButtonPalette: (circle: UIColor, knockout: UIColor) {
        (.tertiaryLabel, .systemBackground)
    }

    /// Diameter of the filled circle inside the clear button's box; 0 means
    /// "the whole box", which is the plain field's measured glyph.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    dynamic var clearButtonCircleDiameter: CGFloat { 0 }

    /// Tip-to-tip length of the cross knocked out of that circle; 0 means the
    /// plain field's fixed 5.5 pt inset.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    dynamic var clearButtonCrossSpan: CGFloat { 0 }

    private final func ensureClearButton() {
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

    private final func mode(_ mode: ViewMode, showsForEditing editing: Bool) -> Bool {
        switch mode {
        case .never: return false
        case .whileEditing: return editing
        case .unlessEditing: return !editing
        case .always: return true
        }
    }

    private final var shouldShowRightView: Bool {
        rightView != nil && mode(rightViewMode, showsForEditing: isEditing)
    }

    private final var isClearButtonModeActive: Bool {
        mode(clearButtonMode, showsForEditing: isEditing)
    }

    private final var shouldShowClearButton: Bool {
        !_text.isEmpty
            && isClearButtonModeActive
            && !shouldShowRightView
    }

    // MARK: UTF-16 document model

    private final var documentUTF16Length: Int { _text.utf16.count }

    private final func makePosition(_ offset: Int) -> UITextPosition {
        UITextPosition(document: textDocumentIdentity, utf16Offset: offset)
    }

    private final func validatedOffset(_ position: UITextPosition) -> Int? {
        guard position._document === textDocumentIdentity,
              let offset = position._utf16Offset,
              offset >= 0, offset <= documentUTF16Length else { return nil }
        return offset
    }

    private final func validatedRange(_ range: UITextRange) -> NSRange? {
        guard range._isOpenUIKitRange,
              let first = validatedOffset(range.start),
              let second = validatedOffset(range.end) else { return nil }
        let lower = Swift.min(first, second)
        let upper = Swift.max(first, second)
        return NSRange(location: lower, length: upper - lower)
    }

    private final func makeRange(_ range: NSRange) -> UITextRange {
        UITextRange(start: makePosition(range.location),
                    end: makePosition(range.upperBound))
    }

    private final func clampedOffset(_ offset: Int) -> Int {
        Swift.min(Swift.max(0, offset), documentUTF16Length)
    }

    private final func clampedRange(_ range: NSRange) -> NSRange {
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

    private final func storeSelection(_ range: NSRange?, notifyDelegate: Bool,
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

    private final func normalizeTextStateAfterContentAssignment() {
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

    private final func utf16Slice(_ range: NSRange) -> String {
        let units = Array(_text.utf16)
        return String(decoding: units[range.location..<range.upperBound], as: UTF16.self)
    }

    private final func prefix(toUTF16Offset offset: Int) -> String {
        let units = Array(_text.utf16)
        return String(decoding: units[0..<clampedOffset(offset)], as: UTF16.self)
    }

    private final func replacingUTF16(_ range: NSRange, with replacement: String) -> String {
        var units = Array(_text.utf16)
        units.replaceSubrange(range.location..<range.upperBound, with: replacement.utf16)
        return String(decoding: units, as: UTF16.self)
    }

    /// UTF-16 offsets at Swift Character boundaries. UIKit document methods
    /// accept every code-unit boundary, but keyboard arrows/backspace operate
    /// on composed characters (verified with surrogate and combining probes).
    private final var characterBoundaries: [Int] {
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

    private final func previousCharacterBoundary(before offset: Int) -> Int {
        characterBoundaries.last(where: { $0 < offset }) ?? 0
    }

    private final func nextCharacterBoundary(after offset: Int) -> Int {
        characterBoundaries.first(where: { $0 > offset }) ?? documentUTF16Length
    }

    private final func utf16Offset(forScalarOffset scalarOffset: Int) -> Int {
        let index = UITextCaretMath.index(_text, atScalarOffset: scalarOffset)
        guard let utf16Index = index.samePosition(in: _text.utf16) else {
            return documentUTF16Length
        }
        return _text.utf16.distance(from: _text.utf16.startIndex, to: utf16Index)
    }

    private final func mutate(_ range: NSRange, replacement: String,
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

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var beginningOfDocument: UITextPosition { makePosition(0) }
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var endOfDocument: UITextPosition { makePosition(documentUTF16Length) }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var selectedTextRange: UITextRange? {
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

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var markedTextRange: UITextRange? {
        markedUTF16Range.map(makeRange)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(textInRange:)
#endif
    open dynamic func text(in range: UITextRange) -> String? {
        guard let range = validatedRange(range) else { return nil }
        return utf16Slice(range)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(replaceRange:withText:)
#endif
    open dynamic func replace(_ range: UITextRange, withText text: String) {
        guard let range = validatedRange(range) else { return }
        // Direct UITextInput replacement is lower-level than keyboard entry:
        // UIKit bypasses UITextFieldDelegate's mutation gate and the control's
        // editingChanged event, but does report the resulting selection.
        _ = mutate(range, replacement: text, consultDelegate: false,
                   emitEditingChanged: false)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(textRangeFromPosition:toPosition:)
#endif
    open dynamic func textRange(from fromPosition: UITextPosition,
                        to toPosition: UITextPosition) -> UITextRange? {
        guard let from = validatedOffset(fromPosition),
              let to = validatedOffset(toPosition) else { return nil }
        let lower = Swift.min(from, to)
        let upper = Swift.max(from, to)
        return makeRange(NSRange(location: lower, length: upper - lower))
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(positionFromPosition:offset:)
#endif
    open dynamic func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let start = validatedOffset(position) else { return nil }
        let result: Int
        if offset > 0, start > Int.max - offset { return nil }
        if offset == Int.min { return nil }
        if offset < 0, start < -offset { return nil }
        result = start + offset
        guard result >= 0, result <= documentUTF16Length else { return nil }
        return makePosition(result)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(offsetFromPosition:toPosition:)
#endif
    open dynamic func offset(from: UITextPosition, to: UITextPosition) -> Int {
        guard let first = validatedOffset(from), let second = validatedOffset(to) else { return 0 }
        return second - first
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
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

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func unmarkText() {
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

    final func refreshContent() {
        textLabel.font = _font
        textLabel.textColor = _textColor
        if isSecureTextEntry {
            textLabel.text = secureDisplayText
        } else if let a = _attributed {
            textLabel.attributedText = a
        } else {
            textLabel.text = _text
        }
        placeholderLabel.font = _font
        placeholderLabel.textColor = defaultPlaceholderColor
        placeholderLabel.attributedText = _attributedPlaceholder
        textLabel.isHidden = _text.isEmpty
        placeholderLabel.isHidden = !_text.isEmpty || (_placeholder ?? "").isEmpty
        setNeedsLayout()
    }

    private final var secureDisplayText: String {
        String(repeating: "\u{2022}", count: _text.count)
    }

    private final var renderedText: String {
        isSecureTextEntry ? secureDisplayText : _text
    }

    // MARK: Geometry (measured)

    final var lineHeight: CGFloat { FontEngine.labelLineHeight(for: _font) }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func borderRect(forBounds bounds: CGRect) -> CGRect { bounds }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func textRect(forBounds bounds: CGRect) -> CGRect {
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

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func editingRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
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

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        guard let leftView else { return .zero }
        return CGRect(x: bounds.minX,
                      y: FontEngine.ceilToPixel(
                        bounds.minY + ((bounds.height - leftView.bounds.height) / 2),
                        scale: textLabel.layoutScale),
                      width: leftView.bounds.width, height: leftView.bounds.height)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func rightViewRect(forBounds bounds: CGRect) -> CGRect {
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
            base = Swift.max(FontEngine.ceilToPixel(FontEngine.measure(_text, font: _font),
                                                    scale: scale), 5)
        } else if !_text.isEmpty {
            base = Swift.max(FontEngine.measure(renderedText, font: _font).rounded(.up), 5)
        } else if let p = placeholder, !p.isEmpty {
            base = FontEngine.ceilToPixel(FontEngine.measure(p, font: _font), scale: scale)
        } else {
            base = 5
        }
        switch borderStyle {
        case .roundedRect, .bezel, .line:
            return CGSize(width: base + 28, height: 34)
        case .none:
            return CGSize(width: base, height: FontEngine.metrics(for: _font).lineHeight + 1.5)
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
                let palette = clearButtonPalette
                clearButton.circleColor = palette.circle
                clearButton.knockoutColor = palette.knockout
                clearButton.circleDiameter = clearButtonCircleDiameter
                clearButton.crossSpan = clearButtonCrossSpan
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
            let w = Swift.max(FontEngine.measure(renderedText, font: _font).rounded(.up) + 2,
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
        // MEASURED kbstateprobe has_text, iPhone SE 2x: focusing a
        // field that already has text leaves selStart=selEnd=11 and a
        // lowercase keyboard. UIResponder.becomeFirstResponder syncs the
        // keyboard before this override moves the caret, so rebuild now.
        if let w = window { _UIKeyboardChrome.sync(from: w) }
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
        let scalarOffset = UITextCaretMath.caretIndex(for: x, text: _text, font: _font)
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

    public final var hasText: Bool { !_text.isEmpty }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func insertText(_ text: String) {
        guard isEditing else { return }
        let target = markedUTF16Range ?? selectedUTF16Range
            ?? NSRange(location: unselectedCaretOffset, length: 0)
        _ = mutate(target, replacement: text, consultDelegate: true,
                   emitEditingChanged: true)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func deleteBackward() {
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
    public final func _clear() -> Bool {
        if let d = delegate, !d.textFieldShouldClear(self) { return false }
        // Real clear-button interaction leaves a non-nil empty string.
        text = ""
        storeSelection(NSRange(location: 0, length: 0), notifyDelegate: false)
        sendActions(for: .editingChanged)
        NotificationCenter.default.post(name: Self.textDidChangeNotification,
                                        object: self)
        return true
    }

    final func handleKey(_ key: UIKeyEventKey) {
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

    final func ensureCaretView() {
        if caretView == nil {
            let v = UIView()   // plain UIView: no content pass, no dump noise
            v.isUserInteractionEnabled = false
            canvasView.addSubview(v)
            caretView = v
        }
    }

    /// Caret becomes solid immediately after any caret motion/edit.
    final func revealCaret() {
        caretView?.isHidden = false
    }

    private final func revealSelectionEnd() {
        setNeedsLayout()
    }

    final func caretBlinkChanged(visible: Bool) {
        guard isEditing else { return }
        caretView?.isHidden = !visible
    }

    /// Caret x in text space (pen 0 at the first glyph), pixel-rounded like
    /// real caretRect values.
    final var caretTextX: CGFloat {
        textX(atUTF16Offset: caretOffset)
    }

    private final func textX(atUTF16Offset offset: Int) -> CGFloat {
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
            FontEngine.measure(displayPrefix, font: _font),
            scale: scale)
    }

    private final var caretVerticalMetrics: (y: CGFloat, height: CGFloat) {
        let tr = textRect(forBounds: bounds)
        let fontLineHeight = FontEngine.metrics(for: _font).lineHeight
        let height = fontLineHeight + 1.5
        let boxTop = tr.minY + (tr.height - (fontLineHeight + 2)) / 2
        return ((boxTop + 0.25).rounded(.down), height)
    }

    /// UIKit reports a one-point caret rect even though the visible iOS bar
    /// is two points wide. Geometry is in the text field's coordinate space.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(caretRectForPosition:)
#endif
    open dynamic func caretRect(for position: UITextPosition) -> CGRect {
        guard let offset = validatedOffset(position) else { return .zero }
        let tr = textRect(forBounds: bounds)
        let metrics = caretVerticalMetrics
        return CGRect(x: tr.minX + textX(atUTF16Offset: offset) - textScrollOffset,
                      y: metrics.y, width: 1, height: metrics.height)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(firstRectForRange:)
#endif
    open dynamic func firstRect(for range: UITextRange) -> CGRect {
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

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(selectionRectsForRange:)
#endif
    open dynamic func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        guard let range = validatedRange(range), range.length > 0 else { return [] }
        return [UITextSelectionRect(rect: firstRect(for: makeRange(range)),
                                    containsStart: true, containsEnd: true)]
    }

    final func layoutCaret() {
        guard let caret = caretView, isEditing else { return }
        let tr = textRect(forBounds: bounds)
        // Keep the caret visible: adjust the horizontal scroll first.
        let cx = caretTextX
        let visibleW = tr.width - 2   // caret bar width stays inside
        let textW = FontEngine.measure(renderedText, font: _font)
        var scroll = textScrollOffset
        let maxScroll = Swift.max(0, textW + 2 - tr.width)
        if cx - scroll > visibleW { scroll = cx - visibleW }
        if cx - scroll < 0 { scroll = cx }
        scroll = Swift.min(Swift.max(0, scroll), Swift.max(maxScroll, cx))
        if scroll != textScrollOffset {
            textScrollOffset = scroll
            // Re-place the text label with the new offset.
            let labelY = ((bounds.height - lineHeight) / 2 + 0.5).rounded(.down) - tr.minY
            let w = Swift.max(FontEngine.measure(renderedText, font: _font).rounded(.up) + 2,
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
