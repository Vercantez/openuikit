import Foundation

public struct BEDirectionalTextRange: Equatable, Hashable, Sendable {
    public var offset: Int
    public var length: Int

    public init() {
        offset = 0
        length = 0
    }

    public init(offset: Int, length: Int) {
        self.offset = offset
        self.length = length
    }
}

public final class BEKeyEntry: NSObject, @unchecked Sendable {
    public enum KeyPressState: Int, Equatable, Hashable, Sendable {
        case down = 1
        case up = 2
    }

    public let key: UIKey
    public let state: KeyPressState
    public let isKeyRepeating: Bool
    public let timestamp: TimeInterval

    public static func host_make(
        key: UIKey,
        state: KeyPressState,
        isKeyRepeating: Bool,
        timestamp: TimeInterval
    ) -> BEKeyEntry {
        BEKeyEntry(
            key: key,
            state: state,
            isKeyRepeating: isKeyRepeating,
            timestamp: timestamp
        )
    }

    private init(
        key: UIKey,
        state: KeyPressState,
        isKeyRepeating: Bool,
        timestamp: TimeInterval
    ) {
        self.key = key
        self.state = state
        self.isKeyRepeating = isKeyRepeating
        self.timestamp = timestamp
        super.init()
    }
}

public final class BEKeyEntryContext: NSObject, @unchecked Sendable {
    public let keyEntry: BEKeyEntry
    public var isDocumentEditable: Bool = false
    public var shouldInsertCharacter: Bool = false
    public var shouldEvaluateForInputSystemHandling: Bool = false

    public init(keyEntry: BEKeyEntry) {
        self.keyEntry = keyEntry
        super.init()
    }
}

public final class BETextDocumentRequest: NSObject, @unchecked Sendable {
    public struct Options: OptionSet, Hashable, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let text = Options(rawValue: 1 << 0)
        public static let attributedText = Options(rawValue: 1 << 1)
        public static let textRects = Options(rawValue: 1 << 2)
        public static let markedTextRects = Options(rawValue: 1 << 5)
        public static let autocorrectedRanges = Options(rawValue: 1 << 7)
    }

    public var options: Options
    public var surroundingGranularity: UITextGranularity
    public var granularityCount: Int

    public static func host_make(
        options: Options = [],
        surroundingGranularity: UITextGranularity = .character,
        granularityCount: Int = 0
    ) -> BETextDocumentRequest {
        BETextDocumentRequest(
            options: options,
            surroundingGranularity: surroundingGranularity,
            granularityCount: granularityCount
        )
    }

    private init(
        options: Options,
        surroundingGranularity: UITextGranularity,
        granularityCount: Int
    ) {
        self.options = options
        self.surroundingGranularity = surroundingGranularity
        self.granularityCount = granularityCount
        super.init()
    }
}

public final class BETextDocumentContext: NSObject, @unchecked Sendable {
    public private(set) var selectedText: String?
    public private(set) var contextBefore: String?
    public private(set) var contextAfter: String?
    public private(set) var markedText: String?
    public private(set) var attributedSelectedText: NSAttributedString?
    public private(set) var attributedContextBefore: NSAttributedString?
    public private(set) var attributedContextAfter: NSAttributedString?
    public private(set) var attributedMarkedText: NSAttributedString?
    public private(set) var selectedRangeInMarkedText: NSRange
    public private(set) var textRects: [(CGRect, NSRange)] = []
    public var autocorrectedRanges: [NSValue] = []

    public init(
        selectedText: String?,
        contextBefore: String?,
        contextAfter: String?,
        markedText: String?,
        selectedRangeInMarkedText: NSRange
    ) {
        self.selectedText = selectedText
        self.contextBefore = contextBefore
        self.contextAfter = contextAfter
        self.markedText = markedText
        self.selectedRangeInMarkedText = selectedRangeInMarkedText
        super.init()
    }

    public init(
        attributedSelectedText selectedText: NSAttributedString?,
        contextBefore: NSAttributedString?,
        contextAfter: NSAttributedString?,
        markedText: NSAttributedString?,
        selectedRangeInMarkedText: NSRange
    ) {
        self.attributedSelectedText = selectedText
        self.attributedContextBefore = contextBefore
        self.attributedContextAfter = contextAfter
        self.attributedMarkedText = markedText
        self.selectedText = selectedText?.string
        self.contextBefore = contextBefore?.string
        self.contextAfter = contextAfter?.string
        self.markedText = markedText?.string
        self.selectedRangeInMarkedText = selectedRangeInMarkedText
        super.init()
    }

    public func addTextRect(_ rect: CGRect, forCharacterRange range: NSRange) {
        textRects.append((rect, range))
    }
}

open class BETextSuggestion: NSObject, @unchecked Sendable {
    public let inputText: String

    public init(inputText: String) {
        self.inputText = inputText
        super.init()
    }
}

public final class BEAutoFillTextSuggestion: BETextSuggestion, @unchecked Sendable {
    public let contents: [UITextContentType: String]

    public static func host_make(
        inputText: String,
        contents: [UITextContentType: String]
    ) -> BEAutoFillTextSuggestion {
        BEAutoFillTextSuggestion(inputText: inputText, contents: contents)
    }

    private init(inputText: String, contents: [UITextContentType: String]) {
        self.contents = contents
        super.init(inputText: inputText)
    }
}

public final class BETextAlternatives: NSObject, @unchecked Sendable {
    public let primaryString: String
    public let alternativeStrings: [String]

    public static func host_make(
        primaryString: String,
        alternativeStrings: [String]
    ) -> BETextAlternatives {
        BETextAlternatives(
            primaryString: primaryString,
            alternativeStrings: alternativeStrings
        )
    }

    private init(primaryString: String, alternativeStrings: [String]) {
        self.primaryString = primaryString
        self.alternativeStrings = alternativeStrings
        super.init()
    }
}

public protocol BEResponderEditActions: UIResponderStandardEditActions {
    func addShortcut(_ sender: Any?)
    func findSelected(_ sender: Any?)
    func lookup(_ sender: Any?)
    func promptForReplace(_ sender: Any?)
    func replace(_ sender: Any?)
    func share(_ sender: Any?)
    func translate(_ sender: Any?)
    func transliterateChinese(_ sender: Any?)
}

extension BEResponderEditActions {
    public func addShortcut(_ sender: Any?) { _ = sender }
    public func findSelected(_ sender: Any?) { _ = sender }
    public func lookup(_ sender: Any?) { _ = sender }
    public func promptForReplace(_ sender: Any?) { _ = sender }
    public func replace(_ sender: Any?) { _ = sender }
    public func share(_ sender: Any?) { _ = sender }
    public func translate(_ sender: Any?) { _ = sender }
    public func transliterateChinese(_ sender: Any?) { _ = sender }
}

public protocol BETextSelectionDirectionNavigation: AnyObject {
    func extend(in direction: UITextLayoutDirection)
    func extend(in direction: UITextStorageDirection, by granularity: UITextGranularity)
    func move(in direction: UITextLayoutDirection)
    func move(in direction: UITextStorageDirection, by granularity: UITextGranularity)
}

public protocol BEExtendedTextInputTraits: UITextInputTraits {
    var insertionPointColor: UIColor? { get }
    var selectionHandleColor: UIColor? { get }
    var selectionHighlightColor: UIColor? { get }
    var isSingleLineDocument: Bool { get }
    var isTypingAdaptationEnabled: Bool { get }
}

extension BEExtendedTextInputTraits {
    public var insertionPointColor: UIColor? { nil }
    public var selectionHandleColor: UIColor? { nil }
    public var selectionHighlightColor: UIColor? { nil }
    public var isSingleLineDocument: Bool { false }
    public var isTypingAdaptationEnabled: Bool { false }
}

public protocol BETextInputDelegate: AnyObject {
    func invalidateTextEntryContext(for textInput: any BETextInput)
    func selectionDidChange(for textInput: any BETextInput)
    func selectionWillChange(for textInput: any BETextInput)
    func shouldDeferEventHandlingToSystem(
        for textInput: any BETextInput,
        context keyEventContext: BEKeyEntryContext
    ) -> Bool
    func textInput(_ textInput: any BETextInput, deferReplaceTextActionToSystem sender: Any)
    func textInput(_ textInput: any BETextInput, setCandidateSuggestions suggestions: [BETextSuggestion]?)
}

public protocol BETextInput: BEResponderEditActions, BETextSelectionDirectionNavigation, UIKeyInput {
    var asyncInputDelegate: (any BETextInputDelegate)? { get set }
    var attributedMarkedText: NSAttributedString? { get }
    var automaticallyPresentEditMenu: Bool { get }
    var isEditable: Bool { get }
    var extendedTextInputTraits: (any BEExtendedTextInputTraits)? { get }
    var hasMarkedText: Bool { get }
    var markedText: String? { get }
    var markedTextRange: UITextRange? { get }
    var isReplaceAllowed: Bool { get }
    var selectedText: String? { get }
    var selectedTextRange: UITextRange? { get set }
    var isSelectionAtDocumentStart: Bool { get }
    var selectionClipRect: CGRect { get }
    var selectionContainerViewAboveText: UIView? { get }
    var selectionContainerViewBelowText: UIView? { get }
    var textFirstRect: CGRect { get }
    var textInputView: UIView { get }
    var textLastRect: CGRect { get }
    var unobscuredContentRect: CGRect { get }
    var unscaledView: UIView { get }

    func add(_ alternatives: BETextAlternatives)
    func adjustSelectionBoundary(
        to point: CGPoint,
        touchPhase touch: BESelectionTouchPhase,
        baseIsStart boundaryIsStart: Bool,
        flags: BESelectionFlags
    )
    func adjustSelection(by range: BEDirectionalTextRange) async
    func alternativesForSelectedText() -> [BETextAlternatives]?
    func autoscroll(to point: CGPoint)
    func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool
    func cancelAutoscroll()
    func caretRect(for position: UITextPosition) -> CGRect
    func delete(in direction: UITextStorageDirection, to granularity: UITextGranularity)
    func didInsertFinalDictationResult()
    func handleKeyEntry(_ entry: BEKeyEntry) async -> (BEKeyEntry, Bool)
    func insert(_ alternatives: BETextAlternatives)
    func insertTextPlaceholder(size: CGSize) async -> UITextPlaceholder
    func insert(_ textSuggestion: BETextSuggestion)
    func isPointNearMarkedText(_ point: CGPoint) -> Bool
    func keyboardWillDismiss()
    func move(byOffset offset: Int)
    func moveSelection(
        atBoundary granularity: UITextGranularity,
        in direction: UITextStorageDirection
    ) async
    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int
    func removeTextAlternatives()
    func remove(_ placeholder: UITextPlaceholder, willInsertText: Bool) async
    func replaceDictatedText(_ oldText: String, withText newText: String)
    func replaceSelectedText(_ text: String, withText replacementText: String)
    func replaceText(
        _ originalText: String,
        withText replacementText: String,
        options: BETextReplacementOptions
    ) async -> [UITextSelectionRect]
    func requestDocumentContext(_ request: BETextDocumentRequest) async -> BETextDocumentContext
    func requestPreferredArrowDirectionForEditMenu(
        completionHandler: @escaping (UIEditMenuArrowDirection) -> Void
    )
    func requestTextContextForAutocorrection(
        completionHandler: @escaping (BETextDocumentContext) -> Void
    )
    func requestTextRects(for input: String) async -> [UITextSelectionRect]
    func selectPosition(at point: CGPoint) async
    func selectPosition(at point: CGPoint, for request: BETextDocumentRequest) async -> BETextDocumentContext
    func selectTextForEditMenuWithLocation(
        inView locationInView: CGPoint
    ) async -> (Bool, String?, NSRange)
    func selectText(in granularity: UITextGranularity, at point: CGPoint) async
    func selectWordForReplacement()
    func selectionRects(for range: UITextRange) -> [UITextSelectionRect]
    func setAttributedMarkedText(_ markedText: NSAttributedString?, selectedRange: NSRange)
    func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange)
    func setMarkedText(_ markedText: String?, selectedRange: NSRange)
    func setSelection(
        from: CGPoint,
        to: CGPoint,
        gesture: BEGestureType,
        state: UIGestureRecognizer.State
    )
    func shiftKeyStateChanged(fromState oldState: BEKeyModifierFlags, toState newState: BEKeyModifierFlags)
    func systemWillDismissEditMenu(withAnimator animator: any UIEditMenuInteractionAnimating)
    func systemWillPresentEditMenu(withAnimator animator: any UIEditMenuInteractionAnimating)
    func text(in range: UITextRange) -> String?
    func textInteractionGesture(_ gestureType: BEGestureType, shouldBeginAt point: CGPoint) -> Bool
    func textStyling(
        at position: UITextPosition,
        in direction: UITextStorageDirection
    ) -> [NSAttributedString.Key: Any]?
    func transposeCharactersAroundSelection()
    func unmarkText()
    func updateCurrentSelection(
        to point: CGPoint,
        from gestureType: BEGestureType,
        in state: UIGestureRecognizer.State
    )
    func updateSelection(
        extent point: CGPoint,
        boundary granularity: UITextGranularity
    ) async -> Bool
    func willInsertFinalDictationResult()
}

extension BETextInput {
    public var selectionContainerViewAboveText: UIView? { nil }
    public var selectionContainerViewBelowText: UIView? { nil }
    public func keyboardWillDismiss() {}
    public func removeTextAlternatives() {}
}

public protocol BETextInteractionDelegate: AnyObject {
    func systemDidChangeSelection(for textInteraction: BETextInteraction)
    func systemWillChangeSelection(for textInteraction: BETextInteraction)
}

public enum BETextInteractionHostAction: Equatable {
    case addShortcut(String, CGRect)
    case dismissEditMenu
    case editabilityChanged
    case presentEditMenu
    case refreshKeyboardUI
    case selectionBoundary(CGPoint, BESelectionTouchPhase, BESelectionFlags)
    case selectionGesture(CGPoint, BEGestureType, UIGestureRecognizer.State, BESelectionFlags)
    case share(String, CGRect)
    case showDictionary(String, NSRange, CGRect)
    case showReplacements(String)
    case translate(String, CGRect)
    case transliterateChinese(String)
}

public final class BETextInteraction: NSObject, @unchecked Sendable {
    public weak var delegate: (any BETextInteractionDelegate)?
    public weak var contextMenuInteractionDelegate: (any UIContextMenuInteractionDelegate)?
    public let contextMenuInteraction = UIContextMenuInteraction()
    public let textSelectionDisplayInteraction = UITextSelectionDisplayInteraction()
    public private(set) var host_lastAction: BETextInteractionHostAction?

    public override init() {
        super.init()
    }

    public func addShortcut(forText text: String, from presentationRect: CGRect) {
        host_lastAction = .addShortcut(text, presentationRect)
    }

    public func dismissEditMenuForSelection() {
        host_lastAction = .dismissEditMenu
    }

    public func editabilityChanged() {
        host_lastAction = .editabilityChanged
    }

    public func presentEditMenuForSelection() {
        host_lastAction = .presentEditMenu
    }

    public func refreshKeyboardUI() {
        host_lastAction = .refreshKeyboardUI
    }

    public func selectionBoundaryAdjusted(
        to point: CGPoint,
        touchPhase touch: BESelectionTouchPhase,
        flags: BESelectionFlags
    ) {
        host_lastAction = .selectionBoundary(point, touch, flags)
    }

    public func selectionChangedWithGesture(
        at point: CGPoint,
        gesture gestureType: BEGestureType,
        state gestureState: UIGestureRecognizer.State,
        flags: BESelectionFlags
    ) {
        host_lastAction = .selectionGesture(point, gestureType, gestureState, flags)
    }

    public func share(text: String, from presentationRect: CGRect) {
        host_lastAction = .share(text, presentationRect)
    }

    public func showDictionary(
        forTextInContext textWithContext: String,
        definingTextInRange range: NSRange,
        from presentationRect: CGRect
    ) {
        host_lastAction = .showDictionary(textWithContext, range, presentationRect)
    }

    public func showReplacements(forText text: String) {
        host_lastAction = .showReplacements(text)
    }

    public func translate(text: String, from presentationRect: CGRect) {
        host_lastAction = .translate(text, presentationRect)
    }

    public func transliterateChinese(forText text: String) {
        host_lastAction = .transliterateChinese(text)
    }
}

public final class BEContextMenuConfiguration: UIContextMenuConfiguration, @unchecked Sendable {
    public override init() {
        super.init()
    }

    /// Linux cannot present a system context menu. Always returns `false`.
    public func fulfill(using configuration: UIContextMenuConfiguration?) -> Bool {
        _ = configuration
        return false
    }
}

public protocol BEDragInteractionDelegate: UIDragInteractionDelegate {
    func dragInteraction(
        _ dragInteraction: BEDragInteraction,
        itemsForAddingTo session: any UIDragSession,
        forTouchAt point: CGPoint,
        completion: @escaping ([UIDragItem]) -> Bool
    )
    func dragInteraction(
        _ dragInteraction: BEDragInteraction,
        prepare session: any UIDragSession,
        completion: @escaping () -> Bool
    )
}

extension BEDragInteractionDelegate {
    public func dragInteraction(
        _ dragInteraction: BEDragInteraction,
        itemsForAddingTo session: any UIDragSession,
        forTouchAt point: CGPoint,
        completion: @escaping ([UIDragItem]) -> Bool
    ) {
        _ = dragInteraction
        _ = session
        _ = point
        _ = completion([])
    }

    public func dragInteraction(
        _ dragInteraction: BEDragInteraction,
        prepare session: any UIDragSession,
        completion: @escaping () -> Bool
    ) {
        _ = dragInteraction
        _ = session
        _ = completion()
    }
}

public final class BEDragInteraction: UIDragInteraction, @unchecked Sendable {
    public private(set) weak var delegate: (any BEDragInteractionDelegate)?

    public init(delegate: any BEDragInteractionDelegate) {
        self.delegate = delegate
        super.init()
    }
}
