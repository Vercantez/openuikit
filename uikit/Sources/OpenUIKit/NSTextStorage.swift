// NSTextStorage. Owner: text module (TextKit-1).
//
// A notifying NSMutableAttributedString. `UITextView.textStorage` is one.
//
// Two implementations, chosen exactly as NSAttributedString.swift chooses
// the attributed-string types:
//
// * Foundation + Objective-C (Apple toolchain): an Objective-C class that
//   subclasses FOUNDATION's NSMutableAttributedString, as UIKit's does, so an
//   Objective-C app can subclass it (Simplenote's SPInteractiveTextStorage
//   overrides the four primitives and processEditing). It follows the
//   simplenote-objc-core vtable-free rule: every overridable member is
//   `@objc dynamic` or an override of an Objective-C method, everything else
//   `final`, so the class introduces no Swift vtable slot.
// * Otherwise (Linux ELF, Foundation-hidden guest library route): the
//   portable Swift class over the portable run list, unchanged.
//
// The Objective-C contract below is MEASURED on the iOS 26.1 simulator
// (Tools/oracle2/textstorageprobe/transcript-ios26.1.txt):
//   * processEditing posts the will-notification, then calls the delegate's
//     willProcessEditing, then invalidateAttributes(in: editedRange), then the
//     did-notification, the delegate's didProcessEditing, and last every
//     layout manager's processEditing(for:edited:range:changeInLength:
//     invalidatedRange:). processEditing does NOT clear the edit state and
//     does not check for an empty mask; endEditing / a top-level edited(...)
//     call it only when the mask is non-empty, then clear it.
//   * clearing leaves editedMask = [], changeInLength = 0 and editedRange =
//     {NSNotFound, <previous length>} (a fresh storage: {NSNotFound, length}).
//   * edited(mask, range, delta) on a clean storage records range with
//     `length += delta` for character edits; on a dirty one it unions range
//     into editedRange, then applies `length += delta` for character edits;
//     delta accumulates.
//   * edits made while processEditing runs (delegate, subclass override) join
//     the pending edit instead of processing recursively.
//   * NSTextStorage itself fixes attributes lazily (NSConcreteTextStorage,
//     YES); a subclass does not (NO), so its fixAttributes(in:) runs inside
//     processEditing.
// Not reproduced (documented in docs/agent_reports/attrstring-unify.md): iOS's
// fixAttributes substitutes fonts (a default Helvetica 12 where a run has no
// font, AppleColorEmoji / PingFang over characters the font lacks), which
// also adds `editedAttributes` to the mask the did-callbacks see. OpenUIKit
// has no UIFont object to insert and resolves fallback fonts at layout time.

#if canImport(ObjectiveC) && canImport(Foundation)
import Foundation
import ObjectiveC
import CPortableIO
#if canImport(AppKit)
// The AppKit-typed initializers below. The module already imports AppKit on
// the macOS host (FoundationTypes.swift); this adds nothing to what clients
// load.
import AppKit
#endif

@objc public protocol NSTextStorageDelegate: NSObjectProtocol {
    @objc(textStorage:willProcessEditing:range:changeInLength:)
    optional func textStorage(_ textStorage: NSTextStorage,
                              willProcessEditing editedMask: NSTextStorage.EditActions,
                              range editedRange: NSRange,
                              changeInLength delta: Int)
    @objc(textStorage:didProcessEditing:range:changeInLength:)
    optional func textStorage(_ textStorage: NSTextStorage,
                              didProcessEditing editedMask: NSTextStorage.EditActions,
                              range editedRange: NSRange,
                              changeInLength delta: Int)
}

// Runtime name: UIKit's `NSTextStorage` where no other exists (the iOS
// triple). The macOS host process loads AppKit's (UIFoundation's)
// NSTextStorage, and two classes of one name make objc_getClass pick either;
// there it is `OUKTextStorage`, and UIKitObjCSupport.h aliases the
// Objective-C spelling (`@compatibility_alias`).
#if canImport(AppKit)
@objc(OUKTextStorage)
#else
@objc(NSTextStorage)
#endif
open class NSTextStorage: NSMutableAttributedString {

    public typealias EditActions = OUKTextStorageEditActions

    public static let willProcessEditingNotification =
        Notification.Name("NSTextStorageWillProcessEditingNotification")
    public static let didProcessEditingNotification =
        Notification.Name("NSTextStorageDidProcessEditingNotification")

    /// The characters and attributes. A concrete Foundation string; the four
    /// primitives below are the only access.
    private final let _store = Foundation.NSMutableAttributedString()

    private final var _editedMask: EditActions = []
    private final var _editedRange = NSRange(location: NSNotFound, length: 0)
    private final var _changeInLength = 0
    private final var _editingDepth = 0
    private final var _processing = false
    private final var _layoutManagers: [NSLayoutManager] = []
    private final weak var _delegate: NSTextStorageDelegate?

    // MARK: Initializers
    //
    // None are declared: the class inherits Foundation's designated set
    // (init(), init(string:), init(string:attributes:),
    // init(attributedString:), init?(coder:) and, on the macOS host,
    // AppKit's required NSPasteboardReading initializer, whose parameter
    // type would otherwise pull AppKit into OpenUIKit-Swift.h). Foundation's
    // inherited initializers fill a subclass through the primitives below,
    // so a fresh storage has run one edit and reads editedRange
    // {NSNotFound, length}, as iOS 26.1's does.

#if canImport(AppKit)
    public override init() { super.init() }
    public override init(string str: String) { super.init(string: str) }
    public override init(string str: String, attributes attrs: [NSAttributedString.Key: Any]? = nil) { super.init(string: str, attributes: attrs) }
    public override init(attributedString attrStr: NSAttributedString) { super.init(attributedString: attrStr) }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
    @nonobjc public required init?(pasteboardPropertyList propertyList: Any,
                                   ofType type: NSPasteboard.PasteboardType) {
        super.init(pasteboardPropertyList: propertyList, ofType: type)
    }
    @nonobjc public override init?(html data: Data,
                                   options: [NSAttributedString.DocumentReadingOptionKey: Any] = [:],
                                   documentAttributes dict: AutoreleasingUnsafeMutablePointer<NSDictionary?>?) {
        super.init(html: data, options: options, documentAttributes: dict)
    }
    @nonobjc public override init(url: URL,
                                  options: [NSAttributedString.DocumentReadingOptionKey: Any] = [:],
                                  documentAttributes dict: AutoreleasingUnsafeMutablePointer<NSDictionary?>?) throws {
        try super.init(url: url, options: options, documentAttributes: dict)
    }
    @nonobjc public override init(data: Data,
                                  options: [NSAttributedString.DocumentReadingOptionKey: Any] = [:],
                                  documentAttributes dict: AutoreleasingUnsafeMutablePointer<NSDictionary?>?) throws {
        try super.init(data: data, options: options, documentAttributes: dict)
    }
#endif

    // MARK: Primitives

    open override var string: String { _store.string }

    open override func attributes(at location: Int,
                                  effectiveRange range: NSRangePointer?)
        -> [NSAttributedString.Key: Any] {
        _store.attributes(at: location, effectiveRange: range)
    }

    open override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        _store.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range,
               changeInLength: str.utf16.count - range.length)
        endEditing()
    }

    open override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?,
                                     range: NSRange) {
        beginEditing()
        _store.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    // MARK: Edit state

    @objc open dynamic weak var delegate: NSTextStorageDelegate? {
        get { _delegate }
        set { _delegate = newValue }
    }

    @objc open dynamic var editedMask: EditActions { _editedMask }
    @objc open dynamic var editedRange: NSRange { _editedRange }
    @objc open dynamic var changeInLength: Int { _changeInLength }

    @objc open dynamic var layoutManagers: [NSLayoutManager] { _layoutManagers }

    @objc(addLayoutManager:)
    open dynamic func addLayoutManager(_ aLayoutManager: NSLayoutManager) {
        if _layoutManagers.contains(where: { $0 === aLayoutManager }) { return }
        _layoutManagers.append(aLayoutManager)
        aLayoutManager.bindTextStorage(self)
    }

    @objc(removeLayoutManager:)
    open dynamic func removeLayoutManager(_ aLayoutManager: NSLayoutManager) {
        _layoutManagers.removeAll { $0 === aLayoutManager }
        aLayoutManager.bindTextStorage(nil)
    }

    open override func beginEditing() {
        _editingDepth += 1
    }

    open override func endEditing() {
        if _editingDepth > 0 { _editingDepth -= 1 }
        if _editingDepth == 0 { _processPendingEdit() }
    }

    @objc(edited:range:changeInLength:)
    open dynamic func edited(_ editedMask: EditActions, range editedRange: NSRange,
                             changeInLength delta: Int) {
        let chars = editedMask.contains(.editedCharacters)
        if _editedMask.isEmpty {
            _editedRange = editedRange
            if chars { _editedRange.length += delta }
            _changeInLength = delta
        } else {
            let lo = Swift.min(_editedRange.location, editedRange.location)
            let hi = Swift.max(_editedRange.location + _editedRange.length,
                               editedRange.location + editedRange.length)
            _editedRange = NSRange(location: lo, length: hi - lo)
            if chars { _editedRange.length += delta }
            _changeInLength += delta
        }
        _editedMask.formUnion(editedMask)
        if _editingDepth == 0 { _processPendingEdit() }
    }

    /// endEditing / top-level edited(...): process once, then clear. Edits
    /// made while processing join the pending edit (measured).
    private final func _processPendingEdit() {
        guard !_processing, !_editedMask.isEmpty else { return }
        _processing = true
        _editingDepth += 1
        processEditing()
        _editingDepth -= 1
        _processing = false
        _editedMask = []
        _editedRange.location = NSNotFound
        _changeInLength = 0
    }

    @objc open dynamic func processEditing() {
        let center = NotificationCenter.default
        center.post(name: NSTextStorage.willProcessEditingNotification, object: self)
        _delegate?.textStorage?(self, willProcessEditing: _editedMask,
                                range: _editedRange, changeInLength: _changeInLength)
        let range = _editedRange
        if range.location != NSNotFound {
            invalidateAttributes(in: range)
        }
        center.post(name: NSTextStorage.didProcessEditingNotification, object: self)
        let mask = _editedMask
        let delta = _changeInLength
        let finalRange = _editedRange
        _delegate?.textStorage?(self, didProcessEditing: mask,
                                range: finalRange, changeInLength: delta)
        for lm in _layoutManagers {
            lm.processEditing(for: self, edited: mask, range: finalRange,
                              changeInLength: delta, invalidatedRange: finalRange)
        }
    }

    // MARK: Attribute fixing

    /// NSTextStorage itself fixes lazily (iOS: NSConcreteTextStorage YES);
    /// any subclass does not (NSTextStorage's default NO).
    @objc open dynamic var fixesAttributesLazily: Bool {
        object_getClass(self) == NSTextStorage.self
    }

    @objc(invalidateAttributesInRange:)
    open dynamic func invalidateAttributes(in range: NSRange) {
        if !fixesAttributesLazily { fixAttributes(in: range) }
    }

    @objc(ensureAttributesAreFixedInRange:)
    open dynamic func ensureAttributesAreFixed(in range: NSRange) {
        if fixesAttributesLazily { fixAttributes(in: range) }
    }

    /// UIKit's font substitution is not reproduced (see the file header):
    /// attributes are left as they are. On the macOS host this overrides
    /// AppKit's category method, which would insert AppKit NSFont values.
#if canImport(AppKit)
    @objc(fixAttributesInRange:)
    open override func fixAttributes(in range: NSRange) {}
#else
    @objc(fixAttributesInRange:)
    open dynamic func fixAttributes(in range: NSRange) {}
#endif
}

#else

// MARK: - Portable NSTextStorage (no Foundation or no Objective-C runtime)

#if canImport(Foundation)
import struct Foundation.Notification
#endif

public protocol NSTextStorageDelegate: AnyObject {
    func textStorage(_ textStorage: NSTextStorage,
                     willProcessEditing editedMask: NSTextStorage.EditActions,
                     range editedRange: NSRange,
                     changeInLength delta: Int)
    func textStorage(_ textStorage: NSTextStorage,
                     didProcessEditing editedMask: NSTextStorage.EditActions,
                     range editedRange: NSRange,
                     changeInLength delta: Int)
}

public extension NSTextStorageDelegate {
    func textStorage(_ textStorage: NSTextStorage,
                     willProcessEditing editedMask: NSTextStorage.EditActions,
                     range editedRange: NSRange,
                     changeInLength delta: Int) {}
    func textStorage(_ textStorage: NSTextStorage,
                     didProcessEditing editedMask: NSTextStorage.EditActions,
                     range editedRange: NSRange,
                     changeInLength delta: Int) {}
}

open class NSTextStorage: NSMutableAttributedString {

    public struct EditActions: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let editedAttributes = EditActions(rawValue: 1)
        public static let editedCharacters = EditActions(rawValue: 2)
    }

    public static let willProcessEditingNotification =
        Notification.Name("NSTextStorageWillProcessEditingNotification")
    public static let didProcessEditingNotification =
        Notification.Name("NSTextStorageDidProcessEditingNotification")

    open weak var delegate: NSTextStorageDelegate?

    open private(set) var editedMask: EditActions = []
    open private(set) var editedRange: NSRange = NSRange(location: 0, length: 0)
    open private(set) var changeInLength: Int = 0

    private var _layoutManagers: [NSLayoutManager] = []
    open var layoutManagers: [NSLayoutManager] { _layoutManagers }

    private var editingDepth: Int = 0

    open func addLayoutManager(_ aLayoutManager: NSLayoutManager) {
        if _layoutManagers.contains(where: { $0 === aLayoutManager }) { return }
        _layoutManagers.append(aLayoutManager)
        aLayoutManager.bindTextStorage(self)
    }

    open func removeLayoutManager(_ aLayoutManager: NSLayoutManager) {
        _layoutManagers.removeAll { $0 === aLayoutManager }
        aLayoutManager.bindTextStorage(nil)
    }

    open func beginEditing() {
        editingDepth += 1
    }

    open func endEditing() {
        if editingDepth > 0 { editingDepth -= 1 }
        if editingDepth == 0 { processEditing() }
    }

    open func edited(_ editedMask: EditActions, range editedRange: NSRange,
                     changeInLength delta: Int) {
        if self.editedMask.isEmpty {
            self.editedRange = editedRange
            self.changeInLength = delta
        } else {
            let newLo = Swift.min(self.editedRange.location, editedRange.location)
            let newHi = Swift.max(self.editedRange.location + self.editedRange.length,
                                  editedRange.location + editedRange.length)
            self.editedRange = NSRange(location: newLo, length: Swift.max(0, newHi - newLo))
            self.changeInLength += delta
        }
        self.editedMask.formUnion(editedMask)
        if editingDepth == 0 { processEditing() }
    }

    open func processEditing() {
        guard !editedMask.isEmpty else { return }
        let mask = editedMask
        let range = editedRange
        let delta = changeInLength
        delegate?.textStorage(self, willProcessEditing: mask, range: range, changeInLength: delta)
        NotificationCenter.default.post(name: Self.willProcessEditingNotification, object: self)
        for lm in _layoutManagers {
            lm.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
        }
        delegate?.textStorage(self, didProcessEditing: mask, range: range, changeInLength: delta)
        NotificationCenter.default.post(name: Self.didProcessEditingNotification, object: self)
        editedMask = []
        editedRange = NSRange(location: 0, length: 0)
        changeInLength = 0
    }

    open func invalidateAttributes(in range: NSRange) {
        edited(.editedAttributes, range: range, changeInLength: 0)
    }

    open func ensureAttributesAreFixed(in range: NSRange) {
        // Attributes are always fixed; the portable storage has no lazy fix.
    }

    open var fixesAttributesLazily: Bool { false }

    override func didReplaceCharacters(in range: NSRange, changeInLength delta: Int) {
        edited(.editedCharacters, range: range, changeInLength: delta)
    }

    override func didSetAttributes(in range: NSRange) {
        edited(.editedAttributes, range: range, changeInLength: 0)
    }
}

#endif // canImport(ObjectiveC) && canImport(Foundation)
