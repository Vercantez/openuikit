import Foundation
import BrowserEngineKit

private final class HostTraits: NSObject, BEExtendedTextInputTraits {}

private final class HostTextInput: NSObject, BETextInput {
    var asyncInputDelegate: (any BETextInputDelegate)?
    var selectedText: String? = "sel"
    var markedText: String?
    var attributedMarkedText: NSAttributedString?
    var markedTextRange: UITextRange?
    var selectedTextRange: UITextRange?
    var automaticallyPresentEditMenu = false
    var isEditable = true
    var isReplaceAllowed = true
    var hasText: Bool { !(selectedText ?? "").isEmpty }
    var hasMarkedText: Bool { markedText != nil }
    var isSelectionAtDocumentStart: Bool { selectedTextRange == nil }
    var selectionClipRect: CGRect = .zero
    var textFirstRect: CGRect = .zero
    var textLastRect: CGRect = .zero
    var unobscuredContentRect: CGRect = CGRect(x: 0, y: 0, width: 100, height: 100)
    let textInputView = UIView()
    let unscaledView = UIView()
    var extendedTextInputTraits: (any BEExtendedTextInputTraits)? = HostTraits()
    var alternatives: [BETextAlternatives] = []
    var lastShift: (BEKeyModifierFlags, BEKeyModifierFlags)?
    var lastOffset = 0
    var lastDeleted: (UITextStorageDirection, UITextGranularity)?
    var lastWritingDirection: NSWritingDirection?
    var transposed = false
    var dictationOld: String?
    var dictationNew: String?
    var insertedSuggestion: String?
    var autoscrollPoint: CGPoint?
    var cancelledAutoscroll = false
    var selectedWord = false
    var storedText = "hello"
    var lastGesture: BEGestureType?
    var adjustedRange: BEDirectionalTextRange?
    var insertedPlaceholder: UITextPlaceholder?
    var movedSelection: (UITextGranularity, UITextStorageDirection)?
    var removedPlaceholder: (UITextPlaceholder, Bool)?
    var replacedText: (String, String, BETextReplacementOptions)?
    var requestedRectsInput: String?
    var selectedPoint: CGPoint?
    var selectedGranularity: (UITextGranularity, CGPoint)?
    var updatedSelection: (CGPoint, UITextGranularity)?

    func insertText(_ text: String) { storedText += text }
    func deleteBackward() {
        if !storedText.isEmpty { storedText.removeLast() }
    }

    func add(_ alternatives: BETextAlternatives) { self.alternatives.append(alternatives) }
    func insert(_ alternatives: BETextAlternatives) { self.alternatives.append(alternatives) }
    func alternativesForSelectedText() -> [BETextAlternatives]? { alternatives }
    func insert(_ textSuggestion: BETextSuggestion) { insertedSuggestion = textSuggestion.inputText }

    func adjustSelectionBoundary(
        to point: CGPoint,
        touchPhase touch: BESelectionTouchPhase,
        baseIsStart boundaryIsStart: Bool,
        flags: BESelectionFlags
    ) {
        _ = point
        _ = touch
        _ = boundaryIsStart
        _ = flags
    }

    func autoscroll(to point: CGPoint) { autoscrollPoint = point }
    func cancelAutoscroll() { cancelledAutoscroll = true }
    func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        _ = sender
        return action.rawValue == "copy:"
    }
    func caretRect(for position: UITextPosition) -> CGRect {
        _ = position
        return CGRect(x: 0, y: 0, width: 1, height: 16)
    }
    func delete(in direction: UITextStorageDirection, to granularity: UITextGranularity) {
        lastDeleted = (direction, granularity)
    }
    func didInsertFinalDictationResult() {}
    func willInsertFinalDictationResult() {}
    func isPointNearMarkedText(_ point: CGPoint) -> Bool { point.x < 10 }
    func move(byOffset offset: Int) { lastOffset = offset }
    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        _ = from
        _ = toPosition
        return 2
    }
    func replaceDictatedText(_ oldText: String, withText newText: String) {
        dictationOld = oldText
        dictationNew = newText
    }
    func replaceSelectedText(_ text: String, withText replacementText: String) {
        selectedText = replacementText
        _ = text
    }
    func requestPreferredArrowDirectionForEditMenu(
        completionHandler: @escaping (UIEditMenuArrowDirection) -> Void
    ) {
        completionHandler(.automatic)
    }
    func requestTextContextForAutocorrection(
        completionHandler: @escaping (BETextDocumentContext) -> Void
    ) {
        completionHandler(
            BETextDocumentContext(
                selectedText: selectedText,
                contextBefore: nil,
                contextAfter: nil,
                markedText: markedText,
                selectedRangeInMarkedText: NSRange(location: 0, length: 0)
            )
        )
    }
    func selectWordForReplacement() { selectedWord = true }
    func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        _ = range
        return [UITextSelectionRect(rect: CGRect(x: 0, y: 0, width: 8, height: 8))]
    }
    func setAttributedMarkedText(_ markedText: NSAttributedString?, selectedRange: NSRange) {
        attributedMarkedText = markedText
        self.markedText = markedText?.string
        _ = selectedRange
    }
    func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        lastWritingDirection = writingDirection
        _ = range
    }
    func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        self.markedText = markedText
        _ = selectedRange
    }
    func setSelection(
        from: CGPoint,
        to: CGPoint,
        gesture: BEGestureType,
        state: UIGestureRecognizer.State
    ) {
        lastGesture = gesture
        _ = from
        _ = to
        _ = state
    }
    func shiftKeyStateChanged(fromState oldState: BEKeyModifierFlags, toState newState: BEKeyModifierFlags) {
        lastShift = (oldState, newState)
    }
    func systemWillDismissEditMenu(withAnimator animator: any UIEditMenuInteractionAnimating) {
        _ = animator
    }
    func systemWillPresentEditMenu(withAnimator animator: any UIEditMenuInteractionAnimating) {
        _ = animator
    }
    func text(in range: UITextRange) -> String? {
        _ = range
        return storedText
    }
    func textInteractionGesture(_ gestureType: BEGestureType, shouldBeginAt point: CGPoint) -> Bool {
        lastGesture = gestureType
        return point.x >= 0
    }
    func textStyling(
        at position: UITextPosition,
        in direction: UITextStorageDirection
    ) -> [NSAttributedString.Key: Any]? {
        _ = position
        _ = direction
        return [NSAttributedString.Key("host.font"): "host"]
    }
    func transposeCharactersAroundSelection() { transposed = true }
    func unmarkText() { markedText = nil }
    func updateCurrentSelection(
        to point: CGPoint,
        from gestureType: BEGestureType,
        in state: UIGestureRecognizer.State
    ) {
        lastGesture = gestureType
        _ = point
        _ = state
    }
    func extend(in direction: UITextLayoutDirection) { _ = direction }
    func extend(in direction: UITextStorageDirection, by granularity: UITextGranularity) {
        _ = direction
        _ = granularity
    }
    func move(in direction: UITextLayoutDirection) { _ = direction }
    func move(in direction: UITextStorageDirection, by granularity: UITextGranularity) {
        _ = direction
        _ = granularity
    }

    func adjustSelection(
        by range: BEDirectionalTextRange,
        completionHandler: @escaping () -> Void
    ) {
        _ = range
        adjustedRange = range
        completionHandler()
    }
    func handleKeyEntry(
        _ entry: BEKeyEntry,
        completionHandler: @escaping (BEKeyEntry, Bool) -> Void
    ) {
        completionHandler(entry, true)
    }
    func insertTextPlaceholder(
        size: CGSize,
        completionHandler: @escaping (UITextPlaceholder) -> Void
    ) {
        _ = size
        let placeholder = UITextPlaceholder()
        insertedPlaceholder = placeholder
        completionHandler(placeholder)
    }
    func moveSelection(
        atBoundary granularity: UITextGranularity,
        in direction: UITextStorageDirection,
        completionHandler: @escaping () -> Void
    ) {
        movedSelection = (granularity, direction)
        completionHandler()
    }
    func remove(
        _ placeholder: UITextPlaceholder,
        willInsertText: Bool,
        completionHandler: @escaping () -> Void
    ) {
        removedPlaceholder = (placeholder, willInsertText)
        completionHandler()
    }
    func replaceText(
        _ originalText: String,
        withText replacementText: String,
        options: BETextReplacementOptions,
        completionHandler: @escaping ([UITextSelectionRect]) -> Void
    ) {
        replacedText = (originalText, replacementText, options)
        let rects = [UITextSelectionRect(rect: CGRect(x: 0, y: 0, width: 8, height: 8))]
        completionHandler(rects)
    }
    func requestDocumentContext(
        _ request: BETextDocumentRequest,
        completionHandler: @escaping (BETextDocumentContext) -> Void
    ) {
        _ = request
        let context = BETextDocumentContext(
            selectedText: selectedText,
            contextBefore: nil,
            contextAfter: nil,
            markedText: nil,
            selectedRangeInMarkedText: NSRange(location: 0, length: 0)
        )
        completionHandler(context)
    }
    func requestTextRects(
        for input: String,
        withCompletionHandler completionHandler: @escaping ([UITextSelectionRect]) -> Void
    ) {
        requestedRectsInput = input
        completionHandler([])
    }
    func selectPosition(at point: CGPoint, completionHandler: @escaping () -> Void) {
        selectedPoint = point
        completionHandler()
    }
    func selectPosition(
        at point: CGPoint,
        for request: BETextDocumentRequest,
        completionHandler: @escaping (BETextDocumentContext) -> Void
    ) {
        _ = request
        selectedPoint = point
        completionHandler(BETextDocumentContext.host_empty)
    }
    func selectTextForEditMenuWithLocation(
        inView locationInView: CGPoint,
        completionHandler: @escaping (Bool, String?, NSRange) -> Void
    ) {
        completionHandler(true, selectedText, NSRange(location: 0, length: selectedText?.count ?? 0))
        _ = locationInView
    }
    func selectText(
        in granularity: UITextGranularity,
        at point: CGPoint,
        completionHandler: @escaping () -> Void
    ) {
        selectedGranularity = (granularity, point)
        completionHandler()
    }
    func updateSelection(
        extent point: CGPoint,
        boundary granularity: UITextGranularity,
        completionHandler: @escaping (Bool) -> Void
    ) {
        updatedSelection = (point, granularity)
        completionHandler(true)
    }
}

func testBETextInputEditableAndSelectedText() {
    let input = HostTextInput()
    precondition(input.isEditable)
    precondition(input.selectedText == "sel")
    precondition(input.isReplaceAllowed)
    precondition(!input.automaticallyPresentEditMenu)
    precondition(input.hasText)
}

func testBETextInputMarkedText() {
    let input = HostTextInput()
    precondition(!input.hasMarkedText)
    input.setMarkedText("m", selectedRange: NSRange(location: 0, length: 1))
    precondition(input.markedText == "m")
    precondition(input.hasMarkedText)
    input.setAttributedMarkedText(NSAttributedString(string: "A"), selectedRange: NSRange(location: 0, length: 1))
    precondition(input.attributedMarkedText?.string == "A")
    input.unmarkText()
    precondition(input.markedText == nil)
}

func testBETextInputInsertDeleteAndTextInRange() {
    let input = HostTextInput()
    input.insertText("!")
    precondition(input.text(in: UITextRange()) == "hello!")
    input.deleteBackward()
    precondition(input.storedText == "hello")
}

func testBETextInputAlternatives() {
    let input = HostTextInput()
    let alternatives = BETextAlternatives.host_make(primaryString: "a", alternativeStrings: ["b"])
    input.add(alternatives)
    input.insert(alternatives)
    input.insert(BETextSuggestion(inputText: "world"))
    precondition(input.alternativesForSelectedText()?.count == 2)
    precondition(input.insertedSuggestion == "world")
}

func testBETextInputSuggestionAndReplace() {
    let input = HostTextInput()
    input.insert(BETextSuggestion(inputText: "world"))
    precondition(input.insertedSuggestion == "world")
    input.replaceSelectedText("sel", withText: "new")
    precondition(input.selectedText == "new")
}

func testBETextInputShiftAndMove() {
    let input = HostTextInput()
    input.shiftKeyStateChanged(fromState: BEKeyModifierFlags.none, toState: .shift)
    precondition(input.lastShift?.0 == BEKeyModifierFlags.none)
    precondition(input.lastShift?.1 == .shift)
    input.move(byOffset: 3)
    precondition(input.lastOffset == 3)
    input.delete(in: .backward, to: .character)
    precondition(input.lastDeleted?.0 == .backward)
}

func testBETextInputRectsAndStyling() {
    let input = HostTextInput()
    precondition(input.caretRect(for: UITextPosition()).width == 1)
    precondition(input.selectionRects(for: UITextRange()).count == 1)
    precondition(input.textStyling(at: UITextPosition(), in: .forward)?[NSAttributedString.Key("host.font")] as? String == "host")
    precondition(input.offset(from: UITextPosition(), to: UITextPosition()) == 2)
}

func testBETextInputGesturesAndAutoscroll() {
    let input = HostTextInput()
    precondition(input.textInteractionGesture(.loupe, shouldBeginAt: CGPoint(x: 1, y: 0)))
    input.updateCurrentSelection(to: .zero, from: .oneFingerTap, in: .ended)
    precondition(input.lastGesture == .oneFingerTap)
    input.setSelection(from: .zero, to: CGPoint(x: 1, y: 1), gesture: .doubleTap, state: .ended)
    precondition(input.lastGesture == .doubleTap)
    input.autoscroll(to: CGPoint(x: 9, y: 9))
    precondition(input.autoscrollPoint == CGPoint(x: 9, y: 9))
    input.cancelAutoscroll()
    precondition(input.cancelledAutoscroll)
    input.selectWordForReplacement()
    precondition(input.selectedWord)
    input.transposeCharactersAroundSelection()
    precondition(input.transposed)
}

func testBETextInputDictationAndEditMenu() {
    let input = HostTextInput()
    input.willInsertFinalDictationResult()
    input.replaceDictatedText("old", withText: "new")
    input.didInsertFinalDictationResult()
    precondition(input.dictationOld == "old")
    precondition(input.dictationNew == "new")
    var direction: UIEditMenuArrowDirection?
    input.requestPreferredArrowDirectionForEditMenu { direction = $0 }
    precondition(direction == .automatic)
    var context: BETextDocumentContext?
    input.requestTextContextForAutocorrection { context = $0 }
    precondition(context?.selectedText == "sel")
    input.systemWillPresentEditMenu(withAnimator: BEHostEditMenuAnimator())
    input.systemWillDismissEditMenu(withAnimator: BEHostEditMenuAnimator())
    input.setBaseWritingDirection(.leftToRight, for: UITextRange())
    precondition(input.lastWritingDirection == .leftToRight)
}

func testBETextInputCanPerformActionAndViews() {
    let input = HostTextInput()
    precondition(input.canPerformAction(Selector("copy:"), withSender: nil))
    precondition(!input.canPerformAction(Selector("paste:"), withSender: nil))
    precondition(input.textInputView !== input.unscaledView)
    precondition(input.unobscuredContentRect.width == 100)
    precondition(input.isPointNearMarkedText(CGPoint(x: 1, y: 0)))
    precondition(!input.isPointNearMarkedText(CGPoint(x: 20, y: 0)))
}

func testBETextInputDirectionNavigation() {
    let input = HostTextInput()
    input.move(in: .right)
    input.extend(in: .left)
    input.move(in: .forward, by: .word)
    input.extend(in: .backward, by: .sentence)
}

func testBETextInputResponderEditActions() {
    let input = HostTextInput()
    input.share(nil)
    input.addShortcut(nil)
    input.lookup(nil)
    input.findSelected(nil)
    input.promptForReplace(nil)
    input.replace(nil)
    input.translate(nil)
    input.transliterateChinese(nil)
}

func testBETextInputOptionalDefaults() {
    let input = HostTextInput()
    precondition(input.selectionContainerViewAboveText == nil)
    precondition(input.selectionContainerViewBelowText == nil)
    input.keyboardWillDismiss()
    input.removeTextAlternatives()
}

func testBEExtendedTextInputTraitsDefaults() {
    let traits = HostTraits()
    precondition(traits.insertionPointColor == nil)
    precondition(traits.selectionHandleColor == nil)
    precondition(traits.selectionHighlightColor == nil)
    precondition(!traits.isSingleLineDocument)
    precondition(!traits.isTypingAdaptationEnabled)
}

private final class HostTextInputDelegate: BETextInputDelegate {
    var invalidated = false
    var will = false
    var did = false
    func invalidateTextEntryContext(for textInput: any BETextInput) {
        _ = textInput
        invalidated = true
    }
    func selectionDidChange(for textInput: any BETextInput) {
        _ = textInput
        did = true
    }
    func selectionWillChange(for textInput: any BETextInput) {
        _ = textInput
        will = true
    }
    func shouldDeferEventHandlingToSystem(
        for textInput: any BETextInput,
        context keyEventContext: BEKeyEntryContext
    ) -> Bool {
        _ = textInput
        _ = keyEventContext
        return false
    }
    func textInput(_ textInput: any BETextInput, deferReplaceTextActionToSystem sender: Any) {
        _ = textInput
        _ = sender
    }
    func textInput(_ textInput: any BETextInput, setCandidateSuggestions suggestions: [BETextSuggestion]?) {
        _ = textInput
        _ = suggestions
    }
}

func testBETextInputDelegateMethods() {
    let delegate = HostTextInputDelegate()
    let input = HostTextInput()
    input.asyncInputDelegate = delegate
    precondition(input.asyncInputDelegate === delegate)
    delegate.invalidateTextEntryContext(for: input)
    delegate.selectionWillChange(for: input)
    delegate.selectionDidChange(for: input)
    let entry = BEKeyEntry.host_make(key: UIKey(characters: "a"), state: .down, isKeyRepeating: false, timestamp: 0)
    precondition(!delegate.shouldDeferEventHandlingToSystem(for: input, context: BEKeyEntryContext(keyEntry: entry)))
    delegate.textInput(input, deferReplaceTextActionToSystem: "sender")
    delegate.textInput(input, setCandidateSuggestions: nil)
    precondition(delegate.invalidated)
    precondition(delegate.will)
    precondition(delegate.did)
}

func testBEDragInteractionDelegateDefaults() {
    final class HostDrag: NSObject, BEDragInteractionDelegate {}
    let drag = HostDrag()
    let interaction = BEDragInteraction(delegate: drag)
    var added = false
    drag.dragInteraction(
        interaction,
        itemsForAddingTo: BEHostDragSession(),
        forTouchAt: .zero
    ) { items in
        added = items.isEmpty
        return true
    }
    precondition(added)
    var prepared = false
    drag.dragInteraction(interaction, prepare: BEHostDragSession()) {
        prepared = true
        return false
    }
    precondition(prepared)
}

func testBETextInputAdjustSelectionByRangeCompletion() {
    let input = HostTextInput()
    var completed = false
    input.adjustSelection(by: BEDirectionalTextRange(offset: 1, length: 2)) {
        completed = true
    }
    precondition(completed)
    precondition(input.adjustedRange == BEDirectionalTextRange(offset: 1, length: 2))
}

func testBETextInputHandleKeyEntryCompletion() {
    let input = HostTextInput()
    let entry = BEKeyEntry.host_make(key: UIKey(characters: "a"), state: .down, isKeyRepeating: false, timestamp: 0)
    var result: (BEKeyEntry, Bool)?
    input.handleKeyEntry(entry) { result = ($0, $1) }
    precondition(result?.0 === entry)
    precondition(result?.1 == true)
}

func testBETextInputInsertTextPlaceholderCompletion() {
    let input = HostTextInput()
    var placeholder: UITextPlaceholder?
    input.insertTextPlaceholder(size: CGSize(width: 10, height: 20)) {
        placeholder = $0
    }
    precondition(placeholder != nil)
    precondition(placeholder === input.insertedPlaceholder)
}

func testBETextInputMoveSelectionAtBoundaryCompletion() {
    let input = HostTextInput()
    var completed = false
    input.moveSelection(atBoundary: .word, in: .forward) {
        completed = true
    }
    precondition(completed)
    precondition(input.movedSelection?.0 == .word)
    precondition(input.movedSelection?.1 == .forward)
}

func testBETextInputRemoveTextPlaceholderCompletion() {
    let input = HostTextInput()
    let placeholder = UITextPlaceholder()
    var completed = false
    input.remove(placeholder, willInsertText: true) {
        completed = true
    }
    precondition(completed)
    precondition(input.removedPlaceholder?.0 === placeholder)
    precondition(input.removedPlaceholder?.1 == true)
}

func testBETextInputReplaceTextCompletion() {
    let input = HostTextInput()
    var rects: [UITextSelectionRect]?
    input.replaceText("old", withText: "new", options: .addUnderline) {
        rects = $0
    }
    precondition(rects?.count == 1)
    precondition(input.replacedText?.0 == "old")
    precondition(input.replacedText?.1 == "new")
    precondition(input.replacedText?.2 == .addUnderline)
}

func testBETextInputRequestDocumentContextCompletion() {
    let input = HostTextInput()
    var context: BETextDocumentContext?
    input.requestDocumentContext(BETextDocumentRequest.host_make()) {
        context = $0
    }
    precondition(context?.selectedText == "sel")
}

func testBETextInputRequestTextRectsCompletion() {
    let input = HostTextInput()
    var rects: [UITextSelectionRect]?
    input.requestTextRects(for: "hi", withCompletionHandler: {
        rects = $0
    })
    precondition(rects?.isEmpty == true)
    precondition(input.requestedRectsInput == "hi")
}

func testBETextInputSelectPositionCompletion() {
    let input = HostTextInput()
    var completed = false
    input.selectPosition(at: CGPoint(x: 4, y: 5)) {
        completed = true
    }
    precondition(completed)
    precondition(input.selectedPoint == CGPoint(x: 4, y: 5))
}

func testBETextInputSelectPositionForRequestCompletion() {
    let input = HostTextInput()
    var context: BETextDocumentContext?
    input.selectPosition(at: CGPoint(x: 1, y: 2), for: BETextDocumentRequest.host_make()) {
        context = $0
    }
    precondition(context != nil)
    precondition(context?.selectedText == nil)
    precondition(input.selectedPoint == CGPoint(x: 1, y: 2))
}

func testBETextInputSelectTextForEditMenuCompletion() {
    let input = HostTextInput()
    var result: (Bool, String?, NSRange)?
    input.selectTextForEditMenuWithLocation(inView: CGPoint(x: 3, y: 3)) {
        result = ($0, $1, $2)
    }
    precondition(result?.0 == true)
    precondition(result?.1 == "sel")
    precondition(result?.2 == NSRange(location: 0, length: 3))
}

func testBETextInputSelectTextInGranularityCompletion() {
    let input = HostTextInput()
    var completed = false
    input.selectText(in: .sentence, at: CGPoint(x: 7, y: 8)) {
        completed = true
    }
    precondition(completed)
    precondition(input.selectedGranularity?.0 == .sentence)
    precondition(input.selectedGranularity?.1 == CGPoint(x: 7, y: 8))
}

func testBETextInputUpdateSelectionCompletion() {
    let input = HostTextInput()
    var updated: Bool?
    input.updateSelection(extent: CGPoint(x: 2, y: 2), boundary: .paragraph) {
        updated = $0
    }
    precondition(updated == true)
    precondition(input.updatedSelection?.0 == CGPoint(x: 2, y: 2))
    precondition(input.updatedSelection?.1 == .paragraph)
}
