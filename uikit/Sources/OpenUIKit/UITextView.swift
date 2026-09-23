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
// visible.
//
// UITextInput document model (UTF-16 offsets, like UITextField): MEASURED
// iPhone 16 / iOS 26.1, Tools/oracle2/textviewinputprobe/transcript-ios26.1.txt
// (scenario Tests/OpenUIKitTests/TextViewTextInputScenario.swift):
//   - programmatic `text` / `attributedText`: selection moves to the end of
//     the new text; `textViewDidChangeSelection` only if it moved; no
//     `textViewDidChange`, no notification.
//   - `insertText` / `deleteBackward` / `replace(_:withText:)` work without
//     first responder and never ask `shouldChangeTextIn` (only the keyboard
//     path does); each edit reports didChangeSelection (if the selection
//     moved, or marked text was committed), then textViewDidChange, then
//     UITextViewTextDidChangeNotification. `replace` puts the caret at the
//     end of the replacement.
//   - marked text: `setMarkedText` replaces marked ?? selection; the
//     selection may leave the marked range without unmarking it;
//     `unmarkText` collapses the selection to its start and reports
//     didChangeSelection twice, then didChange + notification; clearing
//     marked text (nil / "") reports two full rounds.
//   - `selectedTextRange = nil` reads back nil while `selectedRange` reads
//     {0, 0}; the next selection write restores a range.
//   - becoming first responder keeps the selection.

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
// MARK: sugar-unify scoped imports (docs/agent_reports/sugar-unify.md):
// Foundation / ObjectiveC names OpenUIKit re-exports rather than re-declares.
// Each is @_exported here too: a plain scoped import that precedes the
// re-export in file order hides the name from clients (swiftc).
#if canImport(Foundation)
@_exported import class Foundation.NSCoder
@_exported import typealias Foundation.TimeInterval
#endif

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
import struct Foundation.URL
// `Notification.Name` for the public notification names (see UITextField).
import struct Foundation.Notification
#endif

/// Identity carried by every position minted for one text view (positions
/// from another editor are rejected, as in UITextField).
private final class UITextViewDocumentIdentity {}


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
///   - `textView(_:shouldInteractWith:in:interaction:)` (NSTextAttachment)
#if OPENUIKIT_OBJC_SUBCLASSING
@objc
#endif
public enum UITextItemInteraction: Int, Sendable {
    case invokeDefaultAction = 0
    case presentActions = 1
    case preview = 2
}

#if OPENUIKIT_OBJC_SUBCLASSING
/// Apple toolchain: UIKit's own shape (objc-protocols.md) -- @objc, UIKit's
/// runtime name, refines the @objc UIScrollViewDelegate, SDK selectors from
/// UITextView.h, all optional (checked against the SDK in
/// Tests/ObjCProtocols2Tests). Every call site goes through the `_foo`
/// dispatch helpers below; an absent method answers what the portable
/// default implementation answers. The SDK's edit-menu, writing-tools,
/// formatting, multi-range and input-suggestion members are left out:
/// OpenUIKit never sends them.
@objc(UITextViewDelegate) @preconcurrency @MainActor
public protocol UITextViewDelegate: UIScrollViewDelegate {
    @objc(textViewShouldBeginEditing:)
    optional func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    @objc(textViewShouldEndEditing:)
    optional func textViewShouldEndEditing(_ textView: UITextView) -> Bool
    @objc(textViewDidBeginEditing:)
    optional func textViewDidBeginEditing(_ textView: UITextView)
    @objc(textViewDidEndEditing:)
    optional func textViewDidEndEditing(_ textView: UITextView)
    @objc(textView:shouldChangeTextInRange:replacementText:)
    optional func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                           replacementText text: String) -> Bool
    @objc(textViewDidChange:)
    optional func textViewDidChange(_ textView: UITextView)
    @objc(textViewDidChangeSelection:)
    optional func textViewDidChangeSelection(_ textView: UITextView)
    @objc(textView:shouldInteractWithTextAttachment:inRange:interaction:)
    optional func textView(_ textView: UITextView, shouldInteractWith attachment: NSTextAttachment,
                           in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
    /// iOS 10–16 link gate (deprecated in 17, still consulted — MEASURED
    /// wordpressrowsprobe `tap.link.old`).
    @objc(textView:shouldInteractWithURL:inRange:interaction:)
    optional func textView(_ textView: UITextView, shouldInteractWith URL: URL,
                           in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
    /// iOS 17 text items (MEASURED wordpressrowsprobe; see the portable
    /// declaration below).
    @objc(textView:primaryActionForTextItem:defaultAction:)
    optional func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem,
                           defaultAction: UIAction) -> UIAction?
    @objc(textView:menuConfigurationForTextItem:defaultMenu:)
    optional func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem,
                           defaultMenu: UIMenu) -> UITextItem.MenuConfiguration?
    @objc(textView:textItemMenuWillDisplayForTextItem:animator:)
    optional func textView(_ textView: UITextView, textItemMenuWillDisplayFor textItem: UITextItem,
                           animator: UIContextMenuInteractionAnimating)
    @objc(textView:textItemMenuWillEndForTextItem:animator:)
    optional func textView(_ textView: UITextView, textItemMenuWillEndFor textItem: UITextItem,
                           animator: UIContextMenuInteractionAnimating)
}

extension UITextViewDelegate {
    func _shouldBeginEditing(_ v: UITextView) -> Bool { textViewShouldBeginEditing?(v) ?? true }
    func _shouldEndEditing(_ v: UITextView) -> Bool { textViewShouldEndEditing?(v) ?? true }
    func _didBeginEditing(_ v: UITextView) { textViewDidBeginEditing?(v) }
    func _didEndEditing(_ v: UITextView) { textViewDidEndEditing?(v) }
    func _shouldChangeText(_ v: UITextView, in range: NSRange, replacementText text: String) -> Bool {
        textView?(v, shouldChangeTextIn: range, replacementText: text) ?? true
    }
    func _didChange(_ v: UITextView) { textViewDidChange?(v) }
    func _didChangeSelection(_ v: UITextView) { textViewDidChangeSelection?(v) }
    func _shouldInteract(_ v: UITextView, with attachment: NSTextAttachment, in range: NSRange,
                         interaction: UITextItemInteraction) -> Bool {
        textView?(v, shouldInteractWith: attachment, in: range, interaction: interaction) ?? true
    }
    func _shouldInteract(_ v: UITextView, with url: URL, in range: NSRange,
                         interaction: UITextItemInteraction) -> Bool {
        textView?(v, shouldInteractWith: url, in: range, interaction: interaction) ?? true
    }
    /// Absent: the iOS 10 gates decide (the portable default's routing).
    func _primaryAction(_ v: UITextView, for item: UITextItem, defaultAction: UIAction) -> UIAction? {
        if let answer = textView?(v, primaryActionFor: item, defaultAction: defaultAction) {
            return answer
        }
        guard !responds(to: #selector(textView(_:primaryActionFor:defaultAction:))) else { return nil }
        return _UITextViewDelegateDefaults.primaryAction(v, item, defaultAction, self)
    }
    func _menuConfiguration(_ v: UITextView, for item: UITextItem,
                            defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
        if let answer = textView?(v, menuConfigurationFor: item, defaultMenu: defaultMenu) { return answer }
        guard !responds(to: #selector(textView(_:menuConfigurationFor:defaultMenu:))) else { return nil }
        return UITextItem.MenuConfiguration(menu: defaultMenu)
    }
    func _menuWillDisplay(_ v: UITextView, for item: UITextItem, animator: UIContextMenuInteractionAnimating) {
        textView?(v, textItemMenuWillDisplayFor: item, animator: animator)
    }
    func _menuWillEnd(_ v: UITextView, for item: UITextItem, animator: UIContextMenuInteractionAnimating) {
        textView?(v, textItemMenuWillEndFor: item, animator: animator)
    }
}
#else
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
    func textView(_ textView: UITextView, shouldInteractWith attachment: NSTextAttachment,
                  in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
#if canImport(Foundation)
    /// iOS 10–16 link gate (deprecated in 17, still consulted — MEASURED
    /// wordpressrowsprobe `tap.link.old`: a delegate implementing only this
    /// is asked with the run range and `.invokeDefaultAction`, and the URL
    /// opens when it answers true).
    func textView(_ textView: UITextView, shouldInteractWith URL: URL,
                  in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
    /// iOS 17 text items. MEASURED (wordpressrowsprobe, iPhone 16 / 26.1):
    /// a tap asks this ONCE with the item and a default action (title "",
    /// identifier `UITextInteractableItemDefaultAction`); the returned
    /// action is performed. nil → nothing opens and the text view asks
    /// `menuConfigurationFor` instead and shows that menu. When both this
    /// and the iOS 10 `shouldInteractWith URL` are implemented only this
    /// one is asked.
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem,
                  defaultAction: UIAction) -> UIAction?
    /// Asked on a long press (after `primaryActionFor`, whose answer is not
    /// performed) and on a tap whose primary action was nil. nil → no menu.
    func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem,
                  defaultMenu: UIMenu) -> UITextItem.MenuConfiguration?
    func textView(_ textView: UITextView, textItemMenuWillDisplayFor textItem: UITextItem,
                  animator: UIContextMenuInteractionAnimating)
    func textView(_ textView: UITextView, textItemMenuWillEndFor textItem: UITextItem,
                  animator: UIContextMenuInteractionAnimating)
#endif
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
    func textView(_ textView: UITextView, shouldInteractWith attachment: NSTextAttachment,
                  in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool { true }
#if canImport(Foundation)
    func textView(_ textView: UITextView, shouldInteractWith URL: URL,
                  in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool { true }
    /// The default answer routes through the iOS 10 gates so a delegate that
    /// implements ONLY `shouldInteractWith URL` (firefox's iOS 15/16
    /// fallback) still gets asked — the measured old-only behaviour — while
    /// one implementing this method is never asked the old question.
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem,
                  defaultAction: UIAction) -> UIAction? {
        _UITextViewDelegateDefaults.primaryAction(textView, textItem, defaultAction, self)
    }
    func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem,
                  defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
        UITextItem.MenuConfiguration(menu: defaultMenu)
    }
    func textView(_ textView: UITextView, textItemMenuWillDisplayFor textItem: UITextItem,
                  animator: UIContextMenuInteractionAnimating) {}
    func textView(_ textView: UITextView, textItemMenuWillEndFor textItem: UITextItem,
                  animator: UIContextMenuInteractionAnimating) {}
#endif
}

extension UITextViewDelegate {
    func _shouldBeginEditing(_ v: UITextView) -> Bool { textViewShouldBeginEditing(v) }
    func _shouldEndEditing(_ v: UITextView) -> Bool { textViewShouldEndEditing(v) }
    func _didBeginEditing(_ v: UITextView) { textViewDidBeginEditing(v) }
    func _didEndEditing(_ v: UITextView) { textViewDidEndEditing(v) }
    func _shouldChangeText(_ v: UITextView, in range: NSRange, replacementText text: String) -> Bool {
        textView(v, shouldChangeTextIn: range, replacementText: text)
    }
    func _didChange(_ v: UITextView) { textViewDidChange(v) }
    func _didChangeSelection(_ v: UITextView) { textViewDidChangeSelection(v) }
    func _shouldInteract(_ v: UITextView, with attachment: NSTextAttachment, in range: NSRange,
                         interaction: UITextItemInteraction) -> Bool {
        textView(v, shouldInteractWith: attachment, in: range, interaction: interaction)
    }
#if canImport(Foundation)
    func _shouldInteract(_ v: UITextView, with url: URL, in range: NSRange,
                         interaction: UITextItemInteraction) -> Bool {
        textView(v, shouldInteractWith: url, in: range, interaction: interaction)
    }
    func _primaryAction(_ v: UITextView, for item: UITextItem, defaultAction: UIAction) -> UIAction? {
        textView(v, primaryActionFor: item, defaultAction: defaultAction)
    }
    func _menuConfiguration(_ v: UITextView, for item: UITextItem,
                            defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
        textView(v, menuConfigurationFor: item, defaultMenu: defaultMenu)
    }
    func _menuWillDisplay(_ v: UITextView, for item: UITextItem, animator: UIContextMenuInteractionAnimating) {
        textView(v, textItemMenuWillDisplayFor: item, animator: animator)
    }
    func _menuWillEnd(_ v: UITextView, for item: UITextItem, animator: UIContextMenuInteractionAnimating) {
        textView(v, textItemMenuWillEndFor: item, animator: animator)
    }
#endif
}
#endif

#if canImport(Foundation)
/// What a delegate without `primaryActionFor` gets: the iOS 10 gates decide,
/// so a delegate implementing ONLY `shouldInteractWith URL` (firefox's iOS
/// 15/16 fallback) is still asked -- the measured old-only behaviour -- while
/// one implementing `primaryActionFor` is never asked the old question.
@MainActor
enum _UITextViewDelegateDefaults {
    static func primaryAction(_ textView: UITextView, _ textItem: UITextItem, _ defaultAction: UIAction,
                              _ delegate: UITextViewDelegate) -> UIAction? {
        switch textItem.content {
        case .link(let url):
            let ok = delegate._shouldInteract(textView, with: url, in: textItem.range,
                                              interaction: .invokeDefaultAction)
            return ok ? defaultAction : nil
        case .textAttachment(let att):
            let ok = delegate._shouldInteract(textView, with: att, in: textItem.range,
                                              interaction: .invokeDefaultAction)
            return ok ? defaultAction : nil
        case .tag:
            return defaultAction
        }
    }
}
#endif

// Objective-C runtime name = UIKit's, and header macro SWIFT_CLASS_NAMED:
// Objective-C app classes may subclass it (vtable-free, see
// ObjCSubclassing.swift).
#if OPENUIKIT_OBJC_SUBCLASSING
@objc(UITextView)
#endif
@preconcurrency @MainActor
open class UITextView: UIScrollView, UITextInput, UITextKeyHandling, UITextCaretHosting {

    /// MEASURED (textviewinputprobe): posted after didChange for every
    /// UITextInput edit (insertText, deleteBackward, replace, marked text),
    /// never for programmatic `text` assignment. Object = the text view.
    nonisolated public static let textDidChangeNotification =
        Notification.Name("UITextViewTextDidChangeNotification")
    /// MEASURED: posted after `textViewDidBeginEditing`.
    nonisolated public static let textDidBeginEditingNotification =
        Notification.Name("UITextViewTextDidBeginEditingNotification")
    /// MEASURED: posted after `textViewDidEndEditing`.
    nonisolated public static let textDidEndEditingNotification =
        Notification.Name("UITextViewTextDidEndEditingNotification")

    /// UIKit's `delegate` on a text view is the text-view delegate; because
    /// `UITextViewDelegate` refines `UIScrollViewDelegate`, assigning it also
    /// satisfies the scroll delegate the superclass calls. The scroll
    /// callbacks therefore keep working through the SAME object, as in UIKit.
    public final var textViewDelegate: UITextViewDelegate? {
        get { delegate as? UITextViewDelegate }
        set { delegate = newValue }
    }

    // MARK: Content properties

    // UIKit text-input traits. The portable renderer has no keyboard of its
    // own; hosts can inspect these exact values when choosing an input UI.
    public final var autocapitalizationType: UITextAutocapitalizationType = .sentences
    public final var autocorrectionType: UITextAutocorrectionType = .default
    public final var spellCheckingType: UITextSpellCheckingType = .default
    public final var keyboardType: UIKeyboardType = .default
    public final var keyboardAppearance: UIKeyboardAppearance = .default
    public final var returnKeyType: UIReturnKeyType = .default
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var enablesReturnKeyAutomatically = false
    /// Semantic purpose retained for password managers and host keyboards,
    /// matching the same trait on UITextField.
    public final var textContentType: UITextContentType?

    /// UIKit imports its `null_resettable` NSString property as `String!`:
    /// callers may use optional binding, while assigning nil resets to an
    /// empty string. The normalization is the first observer operation so
    /// every subsequent text-layout path continues to see non-nil content.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var text: String! = "" {
        didSet {
            if text == nil { text = "" }
            _attributed = nil
            contentDidChange()
            if _textMutationDepth == 0 { _textWasAssigned() }
        }
    }

    /// > 0 while OpenUIKit itself rewrites `text` (edits, storage sync):
    /// those paths manage the selection and delegate calls themselves.
    final var _textMutationDepth = 0

    /// Programmatic assignment (MEASURED): marked text is dropped and the
    /// selection moves to the end; didChangeSelection only if it moved.
    final func _textWasAssigned() {
        _markedUTF16Range = nil
        _storeSelection(NSRange(location: _utf16Length, length: 0), notify: true)
    }

    /// Attributed content (M12). Wrapping and drawing go through
    /// AttributedTextLayout with `usesFontLineHeight` set, so a single-font
    /// attributed string lays out exactly like the plain path. Editing
    /// rewrites `text` and DROPS the attributes (docs/KNOWN_GAPS.md).
    public final var attributedText: NSAttributedString? {
        get {
            if let a = _attributed { return a }
            guard !text.isEmpty else { return nil }
            return NSAttributedString(string: text,
                                      attributes: [.font: effectiveFont,
                                                   .foregroundColor: effectiveTextColor])
        }
        set {
            let s = newValue?.string ?? ""
            _attributed = newValue
            // Assign through the storage directly (the `text` observer would
            // clear `_attributed` again).
            _plainBacking = s
            contentDidChange()
            _textWasAssigned()
        }
    }
    final var _attributed: NSAttributedString?
    /// Write-through to `text` without tripping its didSet.
    private final var _plainBacking: String {
        get { text }
        set {
            let saved = _attributed
            _textMutationDepth += 1
            text = newValue
            _textMutationDepth -= 1
            _attributed = saved
        }
    }

    /// Flattened attributed content, or nil when the view holds plain text.
    final var attributedLayoutText: AttributedTextLayout.Text? {
        guard let a = _attributed, a.length > 0 else { return nil }
        var t = AttributedTextLayout.flatten(_applyingLinkAttributes(a),
                                             defaultFont: effectiveFont,
                                             defaultColor: effectiveTextColor)
        t.usesFontLineHeight = true
        return t
    }
    public final var font: UIFont? {
        didSet { contentDidChange() }
    }
    /// UIKit declares `textColor` nullable. MEASURED iPhone 16 / iOS 26.1
    /// (iososswallsprobe `lens.textView.textColor.*`): a fresh view reads a
    /// non-nil label colour; after `= nil` the getter reads nil. OpenUIKit
    /// draws a nil colour as `.label` (the rendered colour of a nil
    /// `textColor` is not measured).
    public final var textColor: UIColor? {
        get { _textColor }
        set { _textColor = newValue; contentDidChange() }
    }
    private final var _textColor: UIColor? = .label
    final var effectiveTextColor: UIColor { _textColor ?? .label }

    /// UIKit's `textAlignment` (iOS 26.1 default `.natural`, raw 4).
    /// Stored only: plain-text drawing stays leading-aligned; attributed text
    /// follows its paragraph style.
    public final var textAlignment: NSTextAlignment = .natural

    /// UITextInputTraits' `isSecureTextEntry` (iOS 26.1 default false).
    /// Stored only — a text view never masks its text here.
    public final var isSecureTextEntry: Bool = false
    public final var textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0) {
        didSet { contentDidChange() }
    }
    public final var isEditable = true
    /// UIKit default true. False turns text-item interaction off entirely
    /// (MEASURED wordpressrowsprobe `tap.link.new.notSelectable`: no
    /// delegate call, nothing opens).
    public final var isSelectable = true
    /// Attributes painted over `.link` runs. MEASURED default on iOS 26.1:
    /// exactly `[.foregroundColor: systemBlue]` (no underline).
    public final var linkTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.systemBlue] {
        didSet { contentDidChange() }
    }

    public static let lineFragmentPadding: CGFloat = 5

    /// TextKit-1 stack. The three objects are the real ones; `attributedText`
    /// / `text` write through `textStorage`. MEASURED attach_probe UITextView
    /// path 7: lineFragmentPadding 5, inset (8, 0, 8, 0).
    public final let textStorage = NSTextStorage()
    public final let layoutManager = NSLayoutManager()
    public final let textContainer = NSTextContainer(size: CGSize(width: 0, height: 0))

    final var effectiveFont: UIFont { font ?? .systemFont(ofSize: 12) }
    final var lineHeight: CGFloat { FontEngine.metrics(for: effectiveFont).lineHeight }

    // MARK: Internal views / editing state

    final let contentView = UITextViewCanvasView()
    final var caretView: UIView?
    public private(set) final var isEditing = false
    /// Caret position as a unicode-scalar offset into `text` (the end of the
    /// selection). Kept for the M8 caret/line math; `selectedRange` is the
    /// app API. Setting it collapses the selection without delegate calls.
    public internal(set) final var caretOffset: Int {
        get { _scalarOffset(forUTF16: _selectedUTF16Range.upperBound) }
        set {
            let n = Swift.min(Swift.max(0, newValue), UITextCaretMath.scalarCount(text))
            _storeSelection(NSRange(location: _utf16Offset(forScalar: n), length: 0),
                            notify: false)
        }
    }

    // UITextInput state (UTF-16 offsets into `text`).
    private final let _documentIdentity = UITextViewDocumentIdentity()
    final var _selectedUTF16Range = NSRange(location: 0, length: 0)
    /// MEASURED: after `selectedTextRange = nil` the getter reads nil while
    /// `selectedRange` reads {0, 0}.
    final var _selectedTextRangeIsNil = false
    final var _markedUTF16Range: NSRange?
    /// Preferred caret x (text space) preserved across up/down moves.
    final var preferredCaretX: CGFloat?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureTextCanvas()
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    public required dynamic init?(coder: NSCoder) {
        super.init(coder: coder)
        configureTextCanvas()
    }

    private final func configureTextCanvas() {
        isOpaque = true
        backgroundColor = .systemBackground
        contentView.owner = self
        addSubview(contentView)
        textContainer.lineFragmentPadding = UITextView.lineFragmentPadding
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textStorage.delegate = self
    }

    final func contentDidChange() {
        syncTextKitStorage()
        contentView.setNeedsDisplay()
        setNeedsLayout()
    }

    private final var suppressingStorage = false
    private final var attachmentProviders: [Int: NSTextAttachmentViewProvider] = [:]

    private final func syncTextKitStorage() {
        if suppressingStorage { return }
        suppressingStorage = true
        let s: NSAttributedString
        if let a = _attributed {
            s = a
        } else {
            s = NSAttributedString(string: text ?? "",
                                   attributes: [.font: effectiveFont,
                                                .foregroundColor: effectiveTextColor])
        }
        textStorage.setAttributedString(s)
        suppressingStorage = false
    }

    // MARK: Line layout

    final var wrapWidth: CGFloat {
        Swift.max(0, bounds.width - textContainerInset.left - textContainerInset.right
                     - 2 * UITextView.lineFragmentPadding)
    }

    /// Wrapped lines with their unicode-scalar offset ranges into `text`.
    struct LineRun {
        var text: Substring
        var start: Int   // scalar offset of the first character
        var end: Int     // scalar offset past the last character
    }

    final func lineRuns() -> [LineRun] {
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

    final var contentHeight: CGFloat {
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
        if textContainer.widthTracksTextView {
            textContainer.size = CGSize(width: bounds.width, height: Swift.max(h, bounds.height))
        }
        layoutAttachmentViews()
        layoutCaret()
    }

    // MARK: Drawing (called by the content canvas)

    final func drawText(in canvas: Canvas) {
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
            // Image attachments paint here only when no hosted view covers
            // them. UITextView hosts a UIImageView for `usesTextAttachmentView`
            // (MEASURED attach_probe UITextView path 7: a view sits on the
            // 24×24 box). Passing false avoids a double-draw of the same
            // pixels.
            AttributedTextLayout.draw(t, lines: lines,
                                      in: AttributedTextLayout.DrawContext(
                                        canvas: canvas, traits: traitCollection,
                                        bounds: box,
                                        alignment: t.paragraph.alignment,
                                        drawAttachments: false))
            return
        }
        guard !text.isEmpty else { return }
        let font = effectiveFont
        let color = effectiveTextColor.resolvedCGColor(with: traitCollection)
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
        return d._shouldEndEditing(self)
    }

    @discardableResult
    open override func becomeFirstResponder() -> Bool {
        if !isEditing, let d = textViewDelegate, !d._shouldBeginEditing(self) {
            return false
        }
        guard super.becomeFirstResponder() else { return false }
        if !isEditing {
            // MEASURED (textviewinputprobe `becomeFirstResponder`): the
            // selection is kept; shouldBegin, didBegin, then the notification.
            isEditing = true
            UITextInputState.focus(self, at: OpenUIKitRuntime.animationTime)
            ensureCaretView()
            caretView?.isHidden = false
            setNeedsLayout()
            textViewDelegate?._didBeginEditing(self)
            NotificationCenter.default.post(name: Self.textDidBeginEditingNotification, object: self)
        }
        // Same as UITextField: keyboard sync during super runs before
        // caretOffset is at document end. MEASURED kbstateprobe textview
        // ("…lunch.") is lowercase.
        if let w = window { _UIKeyboardChrome.sync(from: w) }
        return true
    }

    @discardableResult
    open override func resignFirstResponder() -> Bool {
        if isEditing, let d = textViewDelegate, !d._shouldEndEditing(self) {
            return false
        }
        let r = super.resignFirstResponder()
        if isEditing {
            isEditing = false
            UITextInputState.unfocus(self)
            caretView?.isHidden = true
            textViewDelegate?._didEndEditing(self)
            NotificationCenter.default.post(name: Self.textDidEndEditingNotification, object: self)
        }
        return r
    }

    /// Start of the current press, for the tap-versus-long-press split of
    /// the text-item path (`textItemPressDuration`).
    final var _pressStart: TimeInterval?

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        _pressStart = touches.first?.timestamp
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        _pressStart = nil
    }

    /// Tap: focus and position the caret (touches the scroll pan let
    /// through — a drag scrolls, a clean tap edits).
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let start = _pressStart
        _pressStart = nil
        guard let touch = touches.first else { return }
        let p = touch.location(in: self)   // bounds coords == content coords
#if canImport(Foundation)
        // Text items win over editing: MEASURED `tap.link.new.editable` —
        // an editable text view opens the link and does NOT become first
        // responder.
        if isSelectable, let item = textItem(at: p) {
            let held = touch.timestamp - (start ?? touch.timestamp)
            if held >= UITextView.textItemPressDuration {
                _presentTextItemMenu(for: item, afterPrimaryAction: true)
            } else {
                _performPrimaryAction(for: item)
            }
            return
        }
#endif
        guard isEditable else { return }
        becomeFirstResponder()
        guard isEditing else { return }
        caretOffset = caretIndex(at: p)
        preferredCaretX = nil
        UITextInputState.noteActivity(at: OpenUIKitRuntime.animationTime)
        caretView?.isHidden = false
        setNeedsLayout()
    }

    /// Nearest glyph boundary to a point in content coordinates.
    final func caretIndex(at p: CGPoint) -> Int {
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

    public final var hasText: Bool { !text.isEmpty }

    /// MEASURED: works without first responder, never asks
    /// `shouldChangeTextIn`; replaces marked text, else the selection.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func insertText(_ str: String) {
        let hadMarked = _markedUTF16Range != nil
        let target = _markedUTF16Range ?? _selectedUTF16Range
        _edit(target, with: str, forceSelectionNotify: hadMarked)
    }

    /// MEASURED: deletes the selection, else the composed character before
    /// the caret (a whole surrogate pair), without first responder and
    /// without asking the delegate.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func deleteBackward() {
        guard let target = _deleteBackwardRange() else { return }
        _edit(target, with: "", forceSelectionNotify: false)
    }

    final func _deleteBackwardRange() -> NSRange? {
        let sel = _selectedUTF16Range
        if sel.length > 0 { return sel }
        guard sel.location > 0 else { return nil }
        let bounds = _characterBoundaries
        let previous = bounds.last(where: { $0 < sel.location }) ?? 0
        let end = bounds.contains(sel.location)
            ? sel.location : (bounds.first(where: { $0 > sel.location }) ?? _utf16Length)
        return NSRange(location: previous, length: end - previous)
    }

    /// Keyboard path (host `UIWindow.sendText` / backspace / return): the
    /// same edit, gated by `textView(_:shouldChangeTextIn:replacementText:)`
    /// as UIKit's keyboard does.
    final func _keyboardInsertText(_ str: String) {
        guard isEditing else { return }
        let target = _markedUTF16Range ?? _selectedUTF16Range
        if let d = textViewDelegate,
           !d._shouldChangeText(self, in: target, replacementText: str) { return }
        insertText(str)
    }

    final func _keyboardDeleteBackward() {
        guard isEditing, let target = _deleteBackwardRange() else { return }
        if let d = textViewDelegate,
           !d._shouldChangeText(self, in: target, replacementText: "") { return }
        _edit(target, with: "", forceSelectionNotify: false)
    }

    /// One edit: replace `range`, caret after the replacement, marked text
    /// dropped, then (MEASURED order) didChangeSelection — when the
    /// selection moved or `forceSelectionNotify` — didChange, notification.
    final func _edit(_ range: NSRange, with str: String, forceSelectionNotify: Bool) {
        _replaceText(range, with: str)
        _markedUTF16Range = nil
        let moved = _storeSelection(NSRange(location: range.location + str.utf16.count, length: 0),
                                    notify: false)
        preferredCaretX = nil
        afterEdit()
        _emitEditRound(selection: moved || forceSelectionNotify)
    }

    final func _emitEditRound(selection: Bool) {
        if selection { textViewDelegate?._didChangeSelection(self) }
        textViewDelegate?._didChange(self)
        NotificationCenter.default.post(name: Self.textDidChangeNotification, object: self)
    }

    final func afterEdit() {
        contentDidChange()
        caretView?.isHidden = !isEditing
        layoutIfNeeded()
        scrollCaretToVisible()
    }

    // MARK: UITextInput document model (UTF-16)

    final var _utf16Length: Int { text.utf16.count }

    /// Replace a UTF-16 range of `text` (no selection or delegate work).
    final func _replaceText(_ range: NSRange, with str: String) {
        var units = Array(text.utf16)
        let r = _clamped(range)
        units.replaceSubrange(r.location..<r.upperBound, with: str.utf16)
        _textMutationDepth += 1
        text = String(decoding: units, as: UTF16.self)
        _textMutationDepth -= 1
    }

    final func _clampedOffset(_ o: Int) -> Int { Swift.min(Swift.max(0, o), _utf16Length) }

    final func _clamped(_ r: NSRange) -> NSRange {
        let start = _clampedOffset(r.location)
        let (sum, overflow) = r.location.addingReportingOverflow(Swift.max(0, r.length))
        let end = _clampedOffset(overflow ? Int.max : sum)
        return NSRange(location: Swift.min(start, end), length: Swift.abs(end - start))
    }

    /// Store the selection; true when it changed. `notify` sends
    /// didChangeSelection on a change (MEASURED: an unchanged assignment
    /// sends nothing).
    @discardableResult
    final func _storeSelection(_ r: NSRange, notify: Bool) -> Bool {
        let clamped = _clamped(r)
        _selectedTextRangeIsNil = false
        guard clamped != _selectedUTF16Range else { return false }
        _selectedUTF16Range = clamped
        if isEditing { caretView?.isHidden = false }
        setNeedsLayout()
        if notify { textViewDelegate?._didChangeSelection(self) }
        return true
    }

    /// UTF-16 offsets at Character boundaries (backspace granularity).
    final var _characterBoundaries: [Int] {
        var result: [Int] = [0]
        var o = 0
        for ch in text { o += ch.utf16.count; result.append(o) }
        return result
    }

    /// Scalar offset containing UTF-16 offset `u` (a position inside a
    /// surrogate pair maps to that pair's scalar).
    final func _scalarOffset(forUTF16 u: Int) -> Int {
        var units = 0, n = 0
        for sc in text.unicodeScalars {
            let w = sc.value > 0xFFFF ? 2 : 1
            if units + w > u { break }
            units += w
            n += 1
        }
        return n
    }

    final func _utf16Offset(forScalar n: Int) -> Int {
        var units = 0, i = 0
        for sc in text.unicodeScalars {
            if i == n { break }
            units += sc.value > 0xFFFF ? 2 : 1
            i += 1
        }
        return units
    }

    final func _position(_ o: Int) -> UITextPosition {
        UITextPosition(document: _documentIdentity, utf16Offset: o)
    }

    final func _offset(_ p: UITextPosition) -> Int? {
        guard p._document === _documentIdentity, let o = p._utf16Offset,
              o >= 0, o <= _utf16Length else { return nil }
        return o
    }

    final func _range(_ r: UITextRange) -> NSRange? {
        guard r._isOpenUIKitRange, let a = _offset(r.start), let b = _offset(r.end) else { return nil }
        return NSRange(location: Swift.min(a, b), length: Swift.abs(b - a))
    }

    final func _textRange(_ r: NSRange) -> UITextRange {
        UITextRange(start: _position(r.location), end: _position(r.upperBound))
    }

    /// UIKit's `selectedRange` (UTF-16). MEASURED: a fresh view reads {0, 0};
    /// assignment reports didChangeSelection only when it changes.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var selectedRange: NSRange {
        get { _selectedUTF16Range }
        set { _storeSelection(newValue, notify: true) }
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var selectedTextRange: UITextRange? {
        get { _selectedTextRangeIsNil ? nil : _textRange(_selectedUTF16Range) }
        set {
            guard let newValue else {
                _storeSelection(NSRange(location: 0, length: 0), notify: true)
                _selectedTextRangeIsNil = true
                return
            }
            guard let r = _range(newValue) else { return }
            _storeSelection(r, notify: true)
        }
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var markedTextRange: UITextRange? {
        _markedUTF16Range.map(_textRange)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var beginningOfDocument: UITextPosition { _position(0) }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var endOfDocument: UITextPosition { _position(_utf16Length) }

    /// MEASURED: a range splitting a surrogate pair yields U+FFFD for the
    /// lone half once bridged to a Swift String.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(textInRange:)
#endif
    open dynamic func text(in range: UITextRange) -> String? {
        guard let r = _range(range) else { return nil }
        let units = Array(text.utf16)
        return String(decoding: units[r.location..<r.upperBound], as: UTF16.self)
    }

    /// MEASURED: no `shouldChangeTextIn`; caret at the end of the
    /// replacement; didChangeSelection only if the selection moved, then
    /// didChange + notification (even when the text is unchanged).
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(replaceRange:withText:)
#endif
    open dynamic func replace(_ range: UITextRange, withText text: String) {
        guard let r = _range(range) else { return }
        _edit(r, with: text, forceSelectionNotify: false)
    }

    /// MEASURED: a reversed pair is normalized (textRange(3, 1) = [1, 3]).
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(textRangeFromPosition:toPosition:)
#endif
    open dynamic func textRange(from fromPosition: UITextPosition,
                                to toPosition: UITextPosition) -> UITextRange? {
        guard let a = _offset(fromPosition), let b = _offset(toPosition) else { return nil }
        return _textRange(NSRange(location: Swift.min(a, b), length: Swift.abs(b - a)))
    }

    /// MEASURED: nil outside [0, length]; offsets inside a surrogate pair
    /// are valid positions.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(positionFromPosition:offset:)
#endif
    open dynamic func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let start = _offset(position) else { return nil }
        let (sum, overflow) = start.addingReportingOverflow(offset)
        guard !overflow, sum >= 0, sum <= _utf16Length else { return nil }
        return _position(sum)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(offsetFromPosition:toPosition:)
#endif
    open dynamic func offset(from: UITextPosition, to: UITextPosition) -> Int {
        guard let a = _offset(from), let b = _offset(to) else { return 0 }
        return b - a
    }

    /// MEASURED: replaces marked ?? selection; the selection lands at
    /// `selectedRange` relative to the marked text; one round of
    /// didChangeSelection / didChange / notification. nil or "" deletes the
    /// marked text and reports two rounds.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        guard let markedText, !markedText.isEmpty else {
            // Without marked text this is not measured; nothing happens.
            guard let marked = _markedUTF16Range else { return }
            _edit(marked, with: "", forceSelectionNotify: true)
            _emitEditRound(selection: true)
            return
        }
        let oldMarked = _markedUTF16Range
        let target = oldMarked ?? _selectedUTF16Range
        _replaceText(target, with: markedText)
        let length = markedText.utf16.count
        let marked = NSRange(location: target.location, length: length)
        _markedUTF16Range = marked
        let start = Swift.min(Swift.max(0, selectedRange.location), length)
        let len = Swift.min(Swift.max(0, selectedRange.length), length - start)
        let moved = _storeSelection(NSRange(location: target.location + start, length: len),
                                    notify: false)
        preferredCaretX = nil
        afterEdit()
        _emitEditRound(selection: moved || oldMarked != marked)
    }

    /// MEASURED: the selection collapses to its start; didChangeSelection
    /// twice, then didChange + notification. No marked text: nothing.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func unmarkText() {
        guard _markedUTF16Range != nil else { return }
        _markedUTF16Range = nil
        _storeSelection(NSRange(location: _selectedUTF16Range.location, length: 0), notify: false)
        textViewDelegate?._didChangeSelection(self)
        _emitEditRound(selection: true)
    }

    final func handleKey(_ key: UIKeyEventKey) {
        guard isEditing else { return }
        switch key {
        case .backspace:
            _keyboardDeleteBackward()
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
            _keyboardInsertText("\n")
            return
        }
        caretView?.isHidden = false
        setNeedsLayout()
        layoutIfNeeded()
        scrollCaretToVisible()
        textViewDelegate?._didChangeSelection(self)
    }

    /// Up/down arrows: nearest boundary in the adjacent line, preserving
    /// the caret's x across consecutive vertical moves (UIKit behavior).
    final func moveCaretVertically(by delta: Int) {
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
    final func caretLine(in runs: [LineRun]) -> (Int, Int)? {
        caretLine(in: runs, at: caretOffset)
    }

    /// (line index, scalar offset within the line) for scalar offset `caretOffset`.
    final func caretLine(in runs: [LineRun], at caretOffset: Int) -> (Int, Int)? {
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

    // MARK: UITextInput geometry
    //
    // MEASURED textviewinputprobe (iPhone 16 / iOS 26.1, "geometry" lines;
    // 17 pt and 12 pt system font, 320 pt wide, default insets):
    //   pitch          P = lineHeight ceiled to the pixel (20.33 @ 17 pt 3x)
    //   caretRect      x = text x - 1, y = floor(top - 0.75) + line * P
    //                  (7, 27.33), width 2, height floor(lineHeight + 2)
    //                  (22 @ 17 pt, 16 @ 12 pt).
    //   firstRect      empty range: (text x, top + line * P, 0, P);
    //                  within one line: caret y/height from start to end x;
    //                  continuing past the line: to the fragment's end
    //                  (width - padding), height P + 1 (21.33).
    //   selectionRects one per line fragment spanned (count measured only).
    // Text x uses the port's glyph advances (within 0.5 pt of Apple's here).

    /// (line, x in view space) for UTF-16 offset `o`.
    final func _lineAndX(forUTF16 o: Int) -> (line: Int, x: CGFloat) {
        let runs = lineRuns()
        let s = _scalarOffset(forUTF16: o)
        guard let (line, within) = caretLine(in: runs, at: s) else {
            return (0, textContainerInset.left + UITextView.lineFragmentPadding)
        }
        let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 2
        let px = FontEngine.roundToPixel(
            UITextCaretMath.prefixWidth(String(runs[line].text), count: within,
                                        font: effectiveFont), scale: scale)
        return (line, textContainerInset.left + UITextView.lineFragmentPadding + px)
    }

    final var _linePitch: CGFloat {
        let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 2
        return FontEngine.ceilToPixel(lineHeight, scale: scale)
    }

    final func _caretY(line: Int) -> CGFloat {
        (textContainerInset.top - 0.75).rounded(.down) + CGFloat(line) * _linePitch
    }

    final var _caretHeight: CGFloat { (lineHeight + 2).rounded(.down) }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(caretRectForPosition:)
#endif
    open dynamic func caretRect(for position: UITextPosition) -> CGRect {
        guard let o = _offset(position) else { return .zero }
        let (line, x) = _lineAndX(forUTF16: o)
        return CGRect(x: x - 1, y: _caretY(line: line), width: 2, height: _caretHeight)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(firstRectForRange:)
#endif
    open dynamic func firstRect(for range: UITextRange) -> CGRect {
        guard let r = _range(range) else { return .zero }
        let (line, x1) = _lineAndX(forUTF16: r.location)
        if r.length == 0 {
            return CGRect(x: x1, y: textContainerInset.top + CGFloat(line) * _linePitch,
                          width: 0, height: _linePitch)
        }
        let (endLine, x2) = _lineAndX(forUTF16: r.upperBound)
        if endLine == line {
            return CGRect(x: x1, y: _caretY(line: line), width: Swift.max(0, x2 - x1),
                          height: _caretHeight)
        }
        let right = bounds.width - textContainerInset.right - UITextView.lineFragmentPadding
        return CGRect(x: x1, y: _caretY(line: line), width: Swift.max(0, right - x1),
                      height: _linePitch + 1)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(selectionRectsForRange:)
#endif
    open dynamic func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        guard let r = _range(range), r.length > 0 else { return [] }
        let (l1, x1) = _lineAndX(forUTF16: r.location)
        let (l2, x2) = _lineAndX(forUTF16: r.upperBound)
        let left = textContainerInset.left + UITextView.lineFragmentPadding
        let right = bounds.width - textContainerInset.right - UITextView.lineFragmentPadding
        var out: [UITextSelectionRect] = []
        for line in l1...Swift.max(l1, l2) {
            let a = line == l1 ? x1 : left
            let b = line == l2 ? x2 : right
            out.append(UITextSelectionRect(
                rect: CGRect(x: a, y: _caretY(line: line), width: Swift.max(0, b - a),
                             height: _caretHeight),
                containsStart: line == l1, containsEnd: line == l2))
        }
        return out
    }

    // MARK: Caret geometry (measured — see header)

    /// Caret rect in CONTENT coordinates.
    public final func caretRect() -> CGRect {
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

    final func ensureCaretView() {
        if caretView == nil {
            let v = UIView()   // plain UIView: no dump noise, no content pass
            v.isUserInteractionEnabled = false
            contentView.addSubview(v)
            caretView = v
        }
    }

    final func layoutCaret() {
        guard let caret = caretView, isEditing else { return }
        caret.backgroundColor = tintColor
        caret.frame = caretRect()
    }

    final func caretBlinkChanged(visible: Bool) {
        guard isEditing else { return }
        caretView?.isHidden = !visible
    }

    /// Keep the caret's line inside the visible rect (vertical only).
    final func scrollCaretToVisible() {
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

    /// Host a view for each `usesTextAttachmentView` attachment. Image
    /// attachments still paint through AttributedTextLayout (the pixel
    /// oracle); a hosted UIImageView sits on the same box so app code that
    /// walks subviews finds a view. MEASURED attach_probe UITextView path 7:
    /// 24×24 box at (16.023, 8) in view space (padding 5 + "A" + inset 8).
    final func layoutAttachmentViews() {
        guard let t = attributedLayoutText else {
            for p in attachmentProviders.values { p.view?.removeFromSuperview() }
            attachmentProviders.removeAll()
            return
        }
        let lines = AttributedTextLayout.wrap(t, maxWidth: wrapWidth, maxLines: 0,
                                              scale: traitCollection.displayScale)
        let originX = textContainerInset.left + UITextView.lineFragmentPadding
        var boxTop = textContainerInset.top
        var seen: Set<Int> = []
        var scalar = 0
        for line in lines {
            var x = originX + line.indent
            var i = line.range.lowerBound
            while i < line.range.upperBound {
                let st = t.style(i)
                let adv = AttributedTextLayout.advance(t, i)
                if let att = st.attachment, att.usesTextAttachmentView {
                    let b = att.attachmentBounds(
                        for: textContainer,
                        proposedLineFragment: CGRect(x: 0, y: 0, width: 0, height: 0),
                        glyphPosition: CGPoint(x: 0, y: 0),
                        characterIndex: i)
                    let baselineY = boxTop + line.ascent
                    let imgY = baselineY - (b.origin.y + b.height)
                    let pad = att.lineLayoutPadding
                    let imgX = x + pad + b.origin.x
                    let imgW = Swift.max(0, b.width - 2 * pad)
                    let rect = CGRect(x: imgX, y: imgY, width: imgW, height: b.height)
                    var provider = attachmentProviders[i]
                    if provider == nil {
                        let cls: NSTextAttachmentViewProvider.Type
                        if let ft = att.fileType,
                           let registered = NSTextAttachment.textAttachmentViewProviderClass(forFileType: ft) {
                            cls = registered
                        } else {
                            cls = NSTextAttachmentViewProvider.self
                        }
                        let p = cls.init(textAttachment: att, parentView: contentView,
                                         textLayoutManager: nil, location: i)
                        p.loadView()
                        if let v = p.view {
                            v.isUserInteractionEnabled = false
                            contentView.addSubview(v)
                        }
                        attachmentProviders[i] = p
                        provider = p
                    }
                    provider?.view?.frame = rect
                    seen.insert(i)
                }
                x += adv
                if i + 1 < line.range.upperBound {
                    x += AttributedTextLayout.kerning(t, i)
                }
                i += 1
                scalar += 1
            }
            boxTop += line.height + line.spacingBelow
        }
        _ = scalar
        for (idx, p) in attachmentProviders {
            if !seen.contains(idx) {
                p.view?.removeFromSuperview()
                attachmentProviders.removeValue(forKey: idx)
            }
        }
    }
}

extension UITextView: NSTextStorageDelegate {
    public func textStorage(_ textStorage: NSTextStorage,
                            didProcessEditing editedMask: NSTextStorage.EditActions,
                            range editedRange: NSRange,
                            changeInLength delta: Int) {
        if suppressingStorage { return }
        suppressingStorage = true
        _attributed = NSAttributedString(attributedString: textStorage)
        let saved = _attributed
        _textMutationDepth += 1
        text = textStorage.string
        _textMutationDepth -= 1
        _attributed = saved
        // Direct storage edits are not measured for selection side effects:
        // keep the selection, clamped to the new length, silently.
        _storeSelection(_selectedUTF16Range, notify: false)
        if let m = _markedUTF16Range, m.upperBound > _utf16Length { _markedUTF16Range = nil }
        suppressingStorage = false
        contentView.setNeedsDisplay()
        setNeedsLayout()
    }
}

// MARK: - Text items (links, attachments, tags)
//
// MEASURED Tools/oracle2/wordpressrowsprobe on iPhone 16 / iOS 26.1
// (`ios-26.1-iphone16-textitem.json`, every row a case name there):
//
//   tap on a link, delegate implements the iOS 17 methods
//     `primaryActionFor` once → returned action performed (URL opens).
//     nil → nothing opens; `menuConfigurationFor` asked, its menu shown,
//     `textItemMenuWillDisplayFor` sent.  custom action → only it runs.
//   tap, delegate implements only iOS 10 `shouldInteractWith URL`
//     that is asked (run range, `.invokeDefaultAction`), true → opens.
//   tap, both implemented → only `primaryActionFor`.  no delegate → opens.
//   tap on a tag → `primaryActionFor` (.tag), default action is "show the
//     menu": `menuConfigurationFor` with an EMPTY default menu → nothing.
//   tap on an attachment → `primaryActionFor` (.textAttachment); no menu.
//   `isSelectable = false` → nothing at all.  editable → still opens, and
//     the text view does NOT become first responder.
//   long press on a link → `primaryActionFor` (answer NOT performed), then
//     `menuConfigurationFor` with the default menu (title = URL string,
//     identifier `UITextItemDefaultMenuIdentifier`, "Open" / "Copy" /
//     "Share…"), `willDisplay`, platter shown; nil config → no menu.
//   long press on an attachment → default menu "Copy Image" / "Save to
//     Camera Roll".
//
// Not modelled: the link selection highlight UIKit sets during a menu
// (`selectedRange` = item range — the port has no selection model), the
// menu platter geometry (the port's own measured `_UIMenuPresentation`
// layout is used), the `_UIContextMenuView` preview, and the 0.5 s press
// threshold, which is UIKit's long-press default rather than a measured
// text-item number.
extension UITextView {
    /// Hold longer than this and the press asks for the menu instead of the
    /// primary action. UIKit's long-press default; not a measured text-item
    /// number.
    public static let textItemPressDuration: TimeInterval = 0.5

    /// `linkTextAttributes` painted over every `.link` run (MEASURED default
    /// systemBlue). Non-link runs are untouched.
    func _applyingLinkAttributes(_ a: NSAttributedString) -> NSAttributedString {
        guard !linkTextAttributes.isEmpty else { return a }
        var hasLink = false
        // No early stop: the stop parameter's type differs between
        // Foundation's NSAttributedString (Apple toolchain) and the portable
        // one, and the scan is linear either way.
        a.enumerateAttribute(.link, in: NSRange(location: 0, length: a.length)) { v, _, _ in
            if v != nil { hasLink = true }
        }
        guard hasLink else { return a }
        let m = NSMutableAttributedString(attributedString: a)
        let attrs = linkTextAttributes
        a.enumerateAttribute(.link, in: NSRange(location: 0, length: a.length)) { v, r, _ in
            if v != nil { m.addAttributes(attrs, range: r) }
        }
        return m
    }

#if canImport(Foundation)
    /// The text item under `p` (bounds coordinates), or nil for plain text
    /// and for points past a line's last glyph.
    public func textItem(at p: CGPoint) -> UITextItem? {
        _textItemHit(at: p)?.item
    }

    struct _TextItemHit {
        var item: UITextItem
        /// The item run's box on the tapped line, bounds coordinates.
        var rect: CGRect
    }

    func _textItemHit(at p: CGPoint) -> _TextItemHit? {
        guard let t = attributedLayoutText, let a = _attributed else { return nil }
        let lines = AttributedTextLayout.wrap(t, maxWidth: wrapWidth, maxLines: 0,
                                              scale: traitCollection.displayScale)
        let originX = textContainerInset.left + UITextView.lineFragmentPadding
        var utf16: [Int] = []
        var off = 0
        for sc in a.string.unicodeScalars {
            utf16.append(off)
            off += sc.value > 0xFFFF ? 2 : 1
        }
        var top = textContainerInset.top
        for line in lines {
            let bottom = top + line.height
            defer { top = bottom + line.spacingBelow }
            guard p.y >= top, p.y < bottom else { continue }
            // Locate the scalar under p.x.
            var x = originX + line.indent
            var hit: Int?
            var i = line.range.lowerBound
            while i < line.range.upperBound {
                var end = x + AttributedTextLayout.advance(t, i)
                if i + 1 < line.range.upperBound { end += AttributedTextLayout.kerning(t, i) }
                if p.x >= x, p.x < end { hit = i; break }
                x = end
                i += 1
            }
            guard let idx = hit, idx < utf16.count else { return nil }
            let loc = utf16[idx]
            guard let (content, range) = _textItemContent(in: a, at: loc) else { return nil }
            // The run's box on this line: the union of its scalars' advances.
            var rx = originX + line.indent
            var minX = CGFloat.greatestFiniteMagnitude
            var maxX = -CGFloat.greatestFiniteMagnitude
            var j = line.range.lowerBound
            while j < line.range.upperBound {
                var end = rx + AttributedTextLayout.advance(t, j)
                if j + 1 < line.range.upperBound { end += AttributedTextLayout.kerning(t, j) }
                if j < utf16.count, range.contains(utf16[j]) {
                    minX = Swift.min(minX, rx)
                    maxX = Swift.max(maxX, end)
                }
                rx = end
                j += 1
            }
            let rect = minX <= maxX
                ? CGRect(x: minX, y: top, width: maxX - minX, height: line.height)
                : CGRect(x: p.x, y: top, width: 0, height: line.height)
            return _TextItemHit(item: UITextItem(content: content, range: range), rect: rect)
        }
        return nil
    }

    /// Link beats attachment beats tag, each with the attribute run's
    /// effective range (MEASURED ranges `[5, 5]` / `[27, 1]` / `[14, 7]`).
    private func _textItemContent(in a: NSAttributedString, at loc: Int)
        -> (UITextItem.Content, NSRange)? {
        var range = NSRange(location: 0, length: 0)
        if let v = a.attribute(.link, at: loc, effectiveRange: &range) {
            let url = (v as? URL) ?? (v as? String).flatMap { URL(string: $0) }
            if let url { return (.link(url), range) }
        }
        range = NSRange(location: 0, length: 0)
        if let att = a.attribute(.attachment, at: loc, effectiveRange: &range) as? NSTextAttachment {
            return (.textAttachment(att), range)
        }
        range = NSRange(location: 0, length: 0)
        if let tag = a.attribute(.textItemTag, at: loc, effectiveRange: &range) as? String {
            return (.tag(tag), range)
        }
        return nil
    }

    /// The action handed to the delegate as `defaultAction` (MEASURED:
    /// empty title, identifier `UITextInteractableItemDefaultAction`).
    func _defaultAction(for item: UITextItem) -> UIAction {
        UIAction(identifier: UITextItem.defaultActionIdentifier) { [weak self] _ in
            self?._performDefaultAction(for: item)
        }
    }

    /// What the default action does: a link opens, a tag shows its menu, an
    /// attachment does nothing (MEASURED `tap.tag.new` / `tap.attachment.new`).
    func _performDefaultAction(for item: UITextItem) {
        switch item.content {
        case .link(let url):
            UIApplication.shared.open(url)
        case .tag:
            _presentTextItemMenu(for: item, afterPrimaryAction: false)
        case .textAttachment:
            break
        }
    }

    /// Tap path. MEASURED order: `primaryActionFor` once; its answer is
    /// performed; nil falls through to the menu.
    func _performPrimaryAction(for item: UITextItem) {
        let fallback = _defaultAction(for: item)
        let action: UIAction?
        if let d = textViewDelegate {
            action = d._primaryAction(self, for: item, defaultAction: fallback)
        } else {
            action = fallback
        }
        if let action {
            action.performWithSender(self, target: nil)
        } else {
            _presentTextItemMenu(for: item, afterPrimaryAction: false)
        }
    }

    /// The default menu for an item (MEASURED titles, identifiers and
    /// children; "Share…" and "Save to Camera Roll" are declarations —
    /// there is no activity sheet or photo library to hand them to).
    func _defaultMenu(for item: UITextItem) -> UIMenu {
        switch item.content {
        case .link(let url):
            return UIMenu(title: url.absoluteString,
                          identifier: UITextItem.defaultMenuIdentifier,
                          children: [
                            UIAction(title: "Open") { _ in UIApplication.shared.open(url) },
                            UIAction(title: "Copy") { _ in UIPasteboard.general.string = url.absoluteString },
                            UIAction(title: "Share…") { _ in },
                          ])
        case .textAttachment(let att):
            return UIMenu(title: "", identifier: UITextItem.defaultMenuIdentifier,
                          children: [
                            UIAction(title: "Copy Image") { _ in
                                if let img = att.image { UIPasteboard.general.image = img }
                            },
                            UIAction(title: "Save to Camera Roll") { _ in },
                          ])
        case .tag:
            return UIMenu(title: "", identifier: UIMenu.Identifier("com.apple.menu.dynamic"),
                          children: [])
        }
    }

    /// Menu path. `afterPrimaryAction` is the long-press shape: MEASURED
    /// `press.link.new.default` asks `primaryActionFor` first (answer not
    /// performed), then `menuConfigurationFor`. An empty menu (the tag
    /// default) shows nothing; nil shows nothing.
    func _presentTextItemMenu(for item: UITextItem, afterPrimaryAction: Bool) {
        let hit = _textItemHitRect(for: item) ?? bounds
        if afterPrimaryAction, let d = textViewDelegate {
            _ = d._primaryAction(self, for: item, defaultAction: _defaultAction(for: item))
        }
        let defaultMenu = _defaultMenu(for: item)
        let config: UITextItem.MenuConfiguration?
        if let d = textViewDelegate {
            config = d._menuConfiguration(self, for: item, defaultMenu: defaultMenu)
        } else {
            config = UITextItem.MenuConfiguration(menu: defaultMenu)
        }
        guard let config, !config.menu.children.isEmpty else { return }
        let animator = _UITextItemMenuAnimator()
        textViewDelegate?._menuWillDisplay(self, for: item, animator: animator)
        let presentation = _UIMenuPresentation.present(config.menu, from: self, sourceRect: hit)
        animator.finish()
        presentation?.onDismiss = { [weak self] in
            guard let self else { return }
            let end = _UITextItemMenuAnimator()
            self.textViewDelegate?._menuWillEnd(self, for: item, animator: end)
            end.finish()
        }
    }

    /// The item's box on its first line, for anchoring the menu.
    private func _textItemHitRect(for item: UITextItem) -> CGRect? {
        guard let t = attributedLayoutText, let a = _attributed else { return nil }
        let lines = AttributedTextLayout.wrap(t, maxWidth: wrapWidth, maxLines: 0,
                                              scale: traitCollection.displayScale)
        let originX = textContainerInset.left + UITextView.lineFragmentPadding
        var utf16: [Int] = []
        var off = 0
        for sc in a.string.unicodeScalars {
            utf16.append(off)
            off += sc.value > 0xFFFF ? 2 : 1
        }
        var top = textContainerInset.top
        for line in lines {
            var x = originX + line.indent
            var minX = CGFloat.greatestFiniteMagnitude
            var maxX = -CGFloat.greatestFiniteMagnitude
            var i = line.range.lowerBound
            while i < line.range.upperBound {
                var end = x + AttributedTextLayout.advance(t, i)
                if i + 1 < line.range.upperBound { end += AttributedTextLayout.kerning(t, i) }
                if i < utf16.count, item.range.contains(utf16[i]) {
                    minX = Swift.min(minX, x)
                    maxX = Swift.max(maxX, end)
                }
                x = end
                i += 1
            }
            if minX <= maxX {
                return CGRect(x: minX, y: top, width: maxX - minX, height: line.height)
            }
            top += line.height + line.spacingBelow
        }
        return nil
    }
#endif
}
