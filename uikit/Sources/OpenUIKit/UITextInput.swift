// Text-input plumbing. Owner: text-input module (M8).
//
// The portable core has no system keyboard: the HOST turns its native key
// events (SDL_TEXTINPUT / SDL_KEYDOWN, a test harness, ...) into calls on
// UIWindow:
//
//   window.sendText("héllo", timestamp: t)     // committed characters
//   window.sendKey(.backspace, timestamp: t)   // editing keys
//
// Both route to the window's current first responder (UIResponder.become/
// resignFirstResponder; UIWindow.firstResponder). Text editors implement
// UIKeyInput (UIKit's protocol shape) plus the internal UITextInputTraits
// key handling below.
//
// Caret blink: UIKit's caret shows solid for a beat after focus/typing and
// then blinks on a 0.5 s half-period. The blink phase derives from the host
// clock (UIWindow.tick / the timestamps passed to sendText/sendKey) — never
// from a wall clock — so scripted captures are deterministic.

// Native and corelibs builds use Foundation's NSObject. The Foundation-hidden
// Mach-O substrate supplies the same name alongside its existing NSRange /
// IndexPath build-support declarations, so importing the unavailable module
// here must remain conditional.
#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

// MARK: - Keyboard traits

/// Keyboard layout requested by a text editor. OpenUIKit has no system
/// keyboard, but preserving UIKit's exact values lets an app and a host agree
/// on the requested layout without source adaptation.
public enum UIKeyboardType: Int, Sendable {
    case `default` = 0
    case asciiCapable = 1
    case numbersAndPunctuation = 2
    case URL = 3
    case numberPad = 4
    case phonePad = 5
    case namePhonePad = 6
    case emailAddress = 7
    case decimalPad = 8
    case twitter = 9
    case webSearch = 10
    case asciiCapableNumberPad = 11

    @available(*, deprecated, renamed: "asciiCapable")
    public static var alphabet: UIKeyboardType { .asciiCapable }
}

/// Visual style requested for the software keyboard. Portable hosts retain
/// this value but do not themselves draw an on-screen keyboard.
public enum UIKeyboardAppearance: Int, Sendable {
    case `default` = 0
    case dark = 1
    case light = 2

    @available(*, deprecated, renamed: "dark")
    public static var alert: UIKeyboardAppearance { .dark }
}

/// Automatic-capitalization policy requested from the keyboard.
public enum UITextAutocapitalizationType: Int, Sendable {
    case none = 0
    case words = 1
    case sentences = 2
    case allCharacters = 3
}

/// Automatic-correction policy requested from the keyboard.
public enum UITextAutocorrectionType: Int, Sendable {
    case `default` = 0
    case no = 1
    case yes = 2
}

/// Spell-checking policy requested from the keyboard. MEASURED iPhone 16 /
/// iOS 26.1: raw values 0...2, a fresh field reads `.default`.
public enum UITextSpellCheckingType: Int, Sendable {
    case `default` = 0
    case no = 1
    case yes = 2
}

/// Semantic purpose supplied to the platform input service.  UIKit models
/// these values as extensible string constants rather than a closed enum;
/// keeping the raw value preserves unknown future values for embedding hosts.
public struct UITextContentType: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let username = UITextContentType(rawValue: "username")
    public static let password = UITextContentType(rawValue: "password")
    public static let newPassword = UITextContentType(rawValue: "newPassword")
    public static let emailAddress = UITextContentType(rawValue: "emailAddress")
    public static let name = UITextContentType(rawValue: "name")
    public static let telephoneNumber = UITextContentType(rawValue: "telephoneNumber")
    public static let oneTimeCode = UITextContentType(rawValue: "oneTimeCode")
}

/// Label/action requested for the keyboard's return key.
public enum UIReturnKeyType: Int, Sendable {
    case `default` = 0
    case go = 1
    case google = 2
    case join = 3
    case next = 4
    case route = 5
    case search = 6
    case send = 7
    case yahoo = 8
    case done = 9
    case emergencyCall = 10
    case `continue` = 11
}

// MARK: - Keyboard assistant-bar values

/// A logical group of bar-button items. OpenUIKit does not draw a keyboard
/// assistant bar, but it keeps UIKit's ownership rule: an item can belong to
/// only one group, either as a member or as that group's representative.
@preconcurrency @MainActor
open class UIBarButtonItemGroup: NSObject {
    private var storedBarButtonItems: [UIBarButtonItem]
    private var storedRepresentativeItem: UIBarButtonItem?

    open var barButtonItems: [UIBarButtonItem] {
        get { storedBarButtonItems }
        set { replaceItems(with: newValue) }
    }

    open var representativeItem: UIBarButtonItem? {
        get { storedRepresentativeItem }
        set { replaceRepresentative(with: newValue) }
    }

    /// No OpenUIKit bar currently collapses a group to its representative.
    open private(set) var isDisplayingRepresentativeItem = false

    public init(barButtonItems: [UIBarButtonItem],
                representativeItem: UIBarButtonItem?) {
        storedBarButtonItems = []
        storedRepresentativeItem = nil
        super.init()
        replaceItems(with: barButtonItems)
        replaceRepresentative(with: representativeItem)
    }

    private func replaceItems(with items: [UIBarButtonItem]) {
        let unique = items.reduce(into: [UIBarButtonItem]()) { result, item in
            if !result.contains(where: { $0 === item }) { result.append(item) }
        }
        for item in storedBarButtonItems
        where !unique.contains(where: { $0 === item }) && item._buttonGroup === self {
            item._buttonGroup = nil
        }
        storedBarButtonItems = []
        for item in unique {
            item._buttonGroup?._removeAssociation(of: item)
            if storedRepresentativeItem === item { storedRepresentativeItem = nil }
            item._buttonGroup = self
            storedBarButtonItems.append(item)
        }
    }

    private func replaceRepresentative(with item: UIBarButtonItem?) {
        if let old = storedRepresentativeItem, old !== item,
           old._buttonGroup === self {
            old._buttonGroup = nil
        }
        storedRepresentativeItem = nil
        guard let item else { return }
        item._buttonGroup?._removeAssociation(of: item)
        storedBarButtonItems.removeAll { $0 === item }
        item._buttonGroup = self
        storedRepresentativeItem = item
    }

    func _removeAssociation(of item: UIBarButtonItem) {
        storedBarButtonItems.removeAll { $0 === item }
        if storedRepresentativeItem === item { storedRepresentativeItem = nil }
        if item._buttonGroup === self { item._buttonGroup = nil }
    }
}

/// Mutable contents of the keyboard's shortcut bar. The portable hosts have
/// no built-in shortcut commands, so a fresh item starts with empty groups;
/// assignments are retained exactly for app/host inspection.
@preconcurrency @MainActor
open class UITextInputAssistantItem: NSObject {
    open var allowsHidingShortcuts = true
    open var leadingBarButtonGroups: [UIBarButtonItemGroup] = []
    open var trailingBarButtonGroups: [UIBarButtonItemGroup] = []

    public override init() { super.init() }
}

/// UIKit's UIKeyInput: minimal text entry.
@preconcurrency @MainActor
public protocol UIKeyInput: AnyObject {
    var hasText: Bool { get }
    func insertText(_ text: String)
    func deleteBackward()
}

// MARK: - Document positions and ranges

/// An opaque location in a text document.
///
/// UIKit exposes positions as reference objects rather than integer offsets.
/// OpenUIKit follows that shape and, for its built-in editors, stores the
/// offset in UTF-16 code units.  UTF-16 is intentional: UIKit permits a
/// position between the two code units of a surrogate pair, and its
/// `offset(from:to:)`, delegate `NSRange`s, and marked-text ranges all share
/// that coordinate system.
open class UITextPosition: NSObject, @unchecked Sendable {
    let _document: AnyObject?
    let _utf16Offset: Int?

    /// The base class is constructible so custom text inputs can subclass it.
    /// A bare position is not associated with a built-in OpenUIKit editor.
    public override init() {
        _document = nil
        _utf16Offset = nil
        super.init()
    }

    init(document: AnyObject, utf16Offset: Int) {
        _document = document
        _utf16Offset = utf16Offset
        super.init()
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UITextPosition else { return false }
        if let lhsDocument = _document,
           let rhsDocument = other._document,
           let lhsOffset = _utf16Offset,
           let rhsOffset = other._utf16Offset {
            return lhsDocument === rhsDocument && lhsOffset == rhsOffset
        }
        return self === other
    }

    open override var hash: Int {
        if let document = _document, let offset = _utf16Offset {
            var hasher = Hasher()
            hasher.combine(ObjectIdentifier(document))
            hasher.combine(offset)
            return hasher.finalize()
        }
        return ObjectIdentifier(self).hashValue
    }
}

/// An immutable ordered pair of positions in one text document.
open class UITextRange: NSObject, @unchecked Sendable {
    private let _start: UITextPosition
    private let _end: UITextPosition
    private let _valid: Bool

    /// The base range is empty and unassociated. Built-in editors reject it.
    public override init() {
        let position = UITextPosition()
        _start = position
        _end = position
        _valid = false
        super.init()
    }

    init(start: UITextPosition, end: UITextPosition) {
        _start = start
        _end = end
        _valid = true
        super.init()
    }

    open var start: UITextPosition { _start }
    open var end: UITextPosition { _end }
    open var isEmpty: Bool { !_valid || start == end }

    var _isOpenUIKitRange: Bool { _valid }
}

/// Geometry for one visual piece of a selection. A single-line
/// `UITextField` returns at most one of these; multi-line editors may return
/// several as their text-input surface grows.
public enum NSWritingDirection: Int, Sendable {
    case natural = -1
    case leftToRight = 0
    case rightToLeft = 1
}

open class UITextSelectionRect: NSObject, @unchecked Sendable {
    private let _rect: CGRect
    private let _writingDirection: NSWritingDirection
    private let _containsStart: Bool
    private let _containsEnd: Bool
    private let _isVertical: Bool

    /// UIKit exposes this as an abstract subclassing surface. The default
    /// values make `super.init()` usable by portable custom text inputs;
    /// concrete subclasses override the getters.
    public override init() {
        _rect = .zero
        _writingDirection = .natural
        _containsStart = false
        _containsEnd = false
        _isVertical = false
        super.init()
    }

    public init(rect: CGRect, writingDirection: NSWritingDirection = .natural,
                containsStart: Bool, containsEnd: Bool,
                isVertical: Bool = false) {
        _rect = rect
        _writingDirection = writingDirection
        _containsStart = containsStart
        _containsEnd = containsEnd
        _isVertical = isVertical
        super.init()
    }

    open var rect: CGRect { _rect }
    open var writingDirection: NSWritingDirection { _writingDirection }
    open var containsStart: Bool { _containsStart }
    open var containsEnd: Bool { _containsEnd }
    open var isVertical: Bool { _isVertical }
}

/// The deterministic core of UIKit's text-input protocol used by
/// OpenUIKit's editors. Keyboard tokenization and writing-direction APIs are
/// separate future slices; selection, replacement, composition, document
/// navigation, and geometry are real behaviors here rather than compile-only
/// placeholders.
@preconcurrency @MainActor
public protocol UITextInput: UIKeyInput {
    func text(in range: UITextRange) -> String?
    func replace(_ range: UITextRange, withText text: String)

    var selectedTextRange: UITextRange? { get set }
    var markedTextRange: UITextRange? { get }
    func setMarkedText(_ markedText: String?, selectedRange: NSRange)
    func unmarkText()

    var beginningOfDocument: UITextPosition { get }
    var endOfDocument: UITextPosition { get }
    func textRange(from fromPosition: UITextPosition,
                   to toPosition: UITextPosition) -> UITextRange?
    func position(from position: UITextPosition, offset: Int) -> UITextPosition?
    func offset(from: UITextPosition, to: UITextPosition) -> Int

    func firstRect(for range: UITextRange) -> CGRect
    func caretRect(for position: UITextPosition) -> CGRect
    func selectionRects(for range: UITextRange) -> [UITextSelectionRect]
}

/// Editing keys the host can send (beyond committed text).
public enum UIKeyEventKey: String, Sendable {
    case backspace
    case left
    case right
    case up
    case down
    case `return`
}

/// Internal: views that take editing-key input (caret movement, return).
@preconcurrency @MainActor
protocol UITextKeyHandling: AnyObject {
    func handleKey(_ key: UIKeyEventKey)
}

extension UIWindow {
    /// Feed committed text from the host's input stream to the first
    /// responder. `timestamp` (host clock) resets the caret-blink phase so
    /// the caret is solid while typing.
    public func sendText(_ text: String, timestamp: TimeInterval = 0) {
        guard !text.isEmpty, let fr = firstResponder as? UIKeyInput else { return }
        UITextInputState.noteActivity(at: timestamp)
        fr.insertText(text)
    }

    /// Feed one editing key (backspace / arrows / return) to the first
    /// responder.
    public func sendKey(_ key: UIKeyEventKey, timestamp: TimeInterval = 0) {
        guard let fr = firstResponder else { return }
        UITextInputState.noteActivity(at: timestamp)
        if let handler = fr as? UITextKeyHandling {
            handler.handleKey(key)
        } else if let input = fr as? UIKeyInput, key == .backspace {
            input.deleteBackward()
        }
    }
}

/// Shared caret-blink state for the (single) focused text editor.
/// UIWindow.tick calls `_stepCaretBlink` every frame; the active editor
/// registers itself on focus and gets `caretBlinkChanged` callbacks when
/// the on/off phase flips, so it can update its caret view (a plain
/// property change — the next render picks it up).
@preconcurrency @MainActor
public enum UITextInputState {
    /// Blink half-period (seconds) and the solid hold after focus/typing.
    public static var blinkHalfPeriod: TimeInterval = 0.5
    public static var solidHold: TimeInterval = 0.6

    static weak var activeEditor: (AnyObject & UITextCaretHosting)?
    static var phaseOrigin: TimeInterval = 0
    static var lastVisible = true

    /// True while an editor is focused — the host's "keep rendering"
    /// redraw hint (openhost polls it like _hasActiveScrollAnimations).
    public static var _hasActiveCaret: Bool { activeEditor != nil }

    static func focus(_ editor: AnyObject & UITextCaretHosting, at t: TimeInterval) {
        activeEditor = editor
        phaseOrigin = t
        lastVisible = true
    }

    static func unfocus(_ editor: AnyObject) {
        if activeEditor === editor { activeEditor = nil }
    }

    /// Typing/caret movement makes the caret solid again.
    static func noteActivity(at t: TimeInterval) {
        phaseOrigin = t
        if !lastVisible {
            lastVisible = true
            activeEditor?.caretBlinkChanged(visible: true)
        }
    }

    static func caretVisible(at t: TimeInterval) -> Bool {
        let dt = t - phaseOrigin
        if dt < solidHold { return true }
        let halves = ((dt - solidHold) / blinkHalfPeriod).rounded(.down)
        return halves.truncatingRemainder(dividingBy: 2) == 1
    }

    /// Advance the blink clock (called from UIWindow.tick).
    public static func _stepCaretBlink(to t: TimeInterval) {
        guard let editor = activeEditor else { return }
        let visible = caretVisible(at: t)
        if visible != lastVisible {
            lastVisible = visible
            editor.caretBlinkChanged(visible: visible)
        }
    }
}

/// Internal: an editor that hosts a blinking caret view.
@preconcurrency @MainActor
protocol UITextCaretHosting {
    func caretBlinkChanged(visible: Bool)
}

// MARK: - Caret positioning math (unit-tested)

/// Pure caret math shared by UITextField and UITextView: glyph-boundary
/// hit testing and prefix widths from the FontEngine advance/kerning
/// tables (the same measurement the renderer uses).
@preconcurrency @MainActor
public enum UITextCaretMath {
    /// Width of the first `count` unicode scalars of `text`.
    public static func prefixWidth(_ text: String, count: Int, font: UIFont) -> CGFloat {
        var total: CGFloat = 0
        var prev: Unicode.Scalar? = nil
        var i = 0
        for ch in text.unicodeScalars {
            if i == count { break }
            if let p = prev { total += FontEngine.kerning(p, ch, font: font) }
            total += FontEngine.advance(of: ch, font: font)
            prev = ch
            i += 1
        }
        return total
    }

    /// Nearest glyph boundary (0...scalarCount) to `x`, where x is in
    /// text space (pen 0 at the first glyph). UIKit picks the boundary
    /// whose position is closest to the tap.
    public static func caretIndex(for x: CGFloat, text: String, font: UIFont) -> Int {
        if x <= 0 { return 0 }
        var total: CGFloat = 0
        var prev: Unicode.Scalar? = nil
        var i = 0
        for ch in text.unicodeScalars {
            if let p = prev { total += FontEngine.kerning(p, ch, font: font) }
            let adv = FontEngine.advance(of: ch, font: font)
            // Boundary i sits at `total`; boundary i+1 at `total + adv`.
            if x < total + adv {
                return (x - total) <= (total + adv - x) ? i : i + 1
            }
            total += adv
            prev = ch
            i += 1
        }
        return i
    }

    /// String.Index for a unicode-scalar offset.
    public static func index(_ text: String, atScalarOffset n: Int) -> String.Index {
        var i = text.unicodeScalars.startIndex
        var k = 0
        while k < n, i < text.unicodeScalars.endIndex {
            i = text.unicodeScalars.index(after: i)
            k += 1
        }
        return i
    }

    public static func scalarCount(_ text: String) -> Int {
        text.unicodeScalars.count
    }
}
