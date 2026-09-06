import Foundation
import BrowserEngineKit

func testBEDirectionalTextRangeDefaultInit() {
    let range = BEDirectionalTextRange()
    precondition(range.offset == 0)
    precondition(range.length == 0)
}

func testBEDirectionalTextRangeOffsetLengthInit() {
    let range = BEDirectionalTextRange(offset: -2, length: 5)
    precondition(range.offset == -2)
    precondition(range.length == 5)
}

func testBEDirectionalTextRangeOffset() {
    var range = BEDirectionalTextRange(offset: 4, length: 1)
    precondition(range.offset == 4)
    range.offset = 9
    precondition(range.offset == 9)
}

func testBEDirectionalTextRangeLength() {
    var range = BEDirectionalTextRange(offset: 0, length: 3)
    precondition(range.length == 3)
    range.length = 0
    precondition(range.length == 0)
}

func testBETextDocumentRequestHostMakeStoresOptions() {
    let request = BETextDocumentRequest.host_make(
        options: [.text, .textRects],
        surroundingGranularity: .word,
        granularityCount: 2
    )
    precondition(request.options.contains(.text))
    precondition(request.options.contains(.textRects))
}

func testBETextDocumentRequestGranularityCount() {
    let request = BETextDocumentRequest.host_make(granularityCount: 3)
    precondition(request.granularityCount == 3)
    request.granularityCount = 8
    precondition(request.granularityCount == 8)
}

func testBETextDocumentRequestSurroundingGranularity() {
    let request = BETextDocumentRequest.host_make(surroundingGranularity: .sentence)
    precondition(request.surroundingGranularity == .sentence)
    request.surroundingGranularity = .document
    precondition(request.surroundingGranularity == .document)
}

func testBETextDocumentContextStringInit() {
    let context = BETextDocumentContext(
        selectedText: "sel",
        contextBefore: "before",
        contextAfter: "after",
        markedText: "mark",
        selectedRangeInMarkedText: NSRange(location: 1, length: 2)
    )
    precondition(context.selectedText == "sel")
    precondition(context.contextBefore == "before")
    precondition(context.contextAfter == "after")
    precondition(context.markedText == "mark")
    precondition(context.selectedRangeInMarkedText.location == 1)
}

func testBETextDocumentContextAttributedInit() {
    let selected = NSAttributedString(string: "S")
    let before = NSAttributedString(string: "B")
    let after = NSAttributedString(string: "A")
    let marked = NSAttributedString(string: "M")
    let context = BETextDocumentContext(
        attributedSelectedText: selected,
        contextBefore: before,
        contextAfter: after,
        markedText: marked,
        selectedRangeInMarkedText: NSRange(location: 0, length: 1)
    )
    precondition(context.attributedSelectedText?.string == "S")
    precondition(context.attributedContextBefore?.string == "B")
    precondition(context.attributedContextAfter?.string == "A")
    precondition(context.attributedMarkedText?.string == "M")
    precondition(context.selectedText == "S")
}

func testBETextDocumentContextAddTextRect() {
    let context = BETextDocumentContext(
        selectedText: nil,
        contextBefore: nil,
        contextAfter: nil,
        markedText: nil,
        selectedRangeInMarkedText: NSRange(location: 0, length: 0)
    )
    precondition(context.textRects.isEmpty)
    let rect = CGRect(x: 1, y: 2, width: 3, height: 4)
    context.addTextRect(rect, forCharacterRange: NSRange(location: 5, length: 6))
    precondition(context.textRects.count == 1)
    precondition(context.textRects[0].0 == rect)
    precondition(context.textRects[0].1.location == 5)
}

func testBETextDocumentContextAutocorrectedRanges() {
    let context = BETextDocumentContext(
        selectedText: nil,
        contextBefore: nil,
        contextAfter: nil,
        markedText: nil,
        selectedRangeInMarkedText: NSRange(location: 0, length: 0)
    )
    precondition(context.autocorrectedRanges.isEmpty)
    let value = NSNumber(value: 42)
    context.autocorrectedRanges = [value]
    precondition(context.autocorrectedRanges.count == 1)
    precondition((context.autocorrectedRanges[0] as! NSNumber).intValue == 42)
}

func testBETextSuggestionInitStoresInputText() {
    let suggestion = BETextSuggestion(inputText: "hello")
    precondition(suggestion.inputText == "hello")
    let asObject: NSObject = suggestion
    precondition(asObject === suggestion)
}

func testBEAutoFillTextSuggestionContents() {
    let username = UITextContentType(rawValue: "username")
    let suggestion = BEAutoFillTextSuggestion.host_make(
        inputText: "user",
        contents: [username: "ada"]
    )
    precondition(suggestion.inputText == "user")
    precondition(suggestion.contents[username] == "ada")
}

func testBETextAlternativesStrings() {
    let alternatives = BETextAlternatives.host_make(
        primaryString: "colour",
        alternativeStrings: ["color", "clr"]
    )
    precondition(alternatives.primaryString == "colour")
    precondition(alternatives.alternativeStrings == ["color", "clr"])
}

func testBEKeyEntryHostMakeStoresProperties() {
    let key = UIKey(characters: "a")
    let entry = BEKeyEntry.host_make(
        key: key,
        state: .down,
        isKeyRepeating: true,
        timestamp: 1.5
    )
    precondition(entry.key === key)
    precondition(entry.state == .down)
    precondition(entry.isKeyRepeating)
    precondition(entry.timestamp == 1.5)
}

func testBEKeyEntryContextInitAndFlags() {
    let entry = BEKeyEntry.host_make(
        key: UIKey(characters: "b"),
        state: .up,
        isKeyRepeating: false,
        timestamp: 0
    )
    let context = BEKeyEntryContext(keyEntry: entry)
    precondition(context.keyEntry === entry)
    precondition(!context.isDocumentEditable)
    precondition(!context.shouldInsertCharacter)
    precondition(!context.shouldEvaluateForInputSystemHandling)
    context.isDocumentEditable = true
    context.shouldInsertCharacter = true
    context.shouldEvaluateForInputSystemHandling = true
    precondition(context.isDocumentEditable)
    precondition(context.shouldInsertCharacter)
    precondition(context.shouldEvaluateForInputSystemHandling)
}

func testBEAccessibilityTraitsHostValues() {
    precondition(BEAccessibility.menuItem.rawValue == 1 << 40)
    precondition(BEAccessibility.popUpButton.rawValue == 1 << 41)
    precondition(BEAccessibility.radioButton.rawValue == 1 << 42)
    precondition(BEAccessibility.readOnly.rawValue == 1 << 43)
    precondition(BEAccessibility.visited.rawValue == 1 << 44)
}

func testBEAccessibilityNotificationsHostValues() {
    precondition(BEAccessibility.selectionChangedNotification.rawValue == 0xBE01)
    precondition(BEAccessibility.valueChangedNotification.rawValue == 0xBE02)
    precondition(
        BEAccessibility.selectionChangedNotification != BEAccessibility.valueChangedNotification
    )
}
