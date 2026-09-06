// NSTextStorage. Owner: text module (TextKit-1).
//
// A notifying `NSMutableAttributedString`. Edits call `edited(_:range:
// changeInLength:)` and, unless `beginEditing` is open, `processEditing()`,
// which posts the will/did notifications and talks to the delegate. Layout
// managers registered here are invalidated on every processed edit.
//
// `UITextView.textStorage` is one of these.

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
