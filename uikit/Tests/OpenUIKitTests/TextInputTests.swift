// Text-input module tests (M8): caret positioning math, the first-responder
// system, and the UITextField/UITextView editing model — all with synthetic
// deterministic timestamps (the caret blink runs on the host clock).
import XCTest
import Foundation
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.

/// Exact declarations/bodies extracted from Focus's
/// `Blockzilla/UIComponents/AutocompleteTextField.swift`. The surrounding
/// fields and test-only entry points are harness code; the marked blocks stay
/// byte-for-byte identical to the app source so this test catches superclass
/// override-surface regressions without editing or compiling around unrelated
/// Focus diagnostics.
private final class FocusAutocompleteTextInputExcerpt: UITextField {
    private var autocompleteTextLabel: UILabel?
    private var hideCursor: Bool = false
    private var lastReplacement: String?

    var isSelectionActive: Bool {
        return autocompleteTextLabel != nil
    }

    // BEGIN EXACT FOCUS L44-49
    public override var text: String? {
        didSet {
            super.text = text
            self.textDidChange(self)
        }
    }
    // END EXACT FOCUS L44-49

    private func textDidChange(_ textField: UITextField) {}

    // BEGIN EXACT FOCUS L158-170
    /// Commits the completion by setting the text and removing the highlight.
    fileprivate func applyCompletion() {

        // Clear the current completion, then set the text without the attributed style.
        let text = (self.text ?? "") + (self.autocompleteTextLabel?.text ?? "")
        let didRemoveCompletion = removeCompletion()
        self.text = text
        hideCursor = false
        // Move the cursor to the end of the completion.
        if didRemoveCompletion {
            selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
        }
    }
    // END EXACT FOCUS L158-170

    // BEGIN EXACT FOCUS L172-178
    /// Removes the autocomplete-highlighted. Returns true if a completion was actually removed
#if canImport(ObjectiveC)
    @objc
#endif
    @discardableResult fileprivate func removeCompletion() -> Bool {
        let hasActiveCompletion = isSelectionActive
        autocompleteTextLabel?.removeFromSuperview()
        autocompleteTextLabel = nil
        return hasActiveCompletion
    }
    // END EXACT FOCUS L172-178

    // BEGIN EXACT FOCUS L237-239
    public override func caretRect(for position: UITextPosition) -> CGRect {
        return hideCursor ? CGRect.zero : super.caretRect(for: position)
    }
    // END EXACT FOCUS L237-239

    // BEGIN EXACT FOCUS L277-282
    public override func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        // Clear the autocompletion if any provisionally inserted text has been
        // entered (e.g., a partial composition from a Japanese keyboard).
        removeCompletion()
        super.setMarkedText(markedText, selectedRange: selectedRange)
    }
    // END EXACT FOCUS L277-282

    // BEGIN EXACT FOCUS L302-308
    // Reset the cursor to the end of the text field.
    // This forces `caretRect(for position: UITextPosition)` to be called which will decide if we should show the cursor
    // This exists because ` caretRect(for position: UITextPosition)` is not called after we apply an autocompletion.
    private func forceResetCursor() {
        selectedTextRange = nil
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
    }
    // END EXACT FOCUS L302-308

    // BEGIN EXACT FOCUS L310-319
    public override func deleteBackward() {
        lastReplacement = ""
        hideCursor = false
        if isSelectionActive {
            removeCompletion()
            forceResetCursor()
        } else {
            super.deleteBackward()
        }
    }
    // END EXACT FOCUS L310-319

    func installCompletion(_ text: String) {
        let label = UILabel()
        label.text = text
        autocompleteTextLabel = label
    }

    func applyCompletionForTest() { applyCompletion() }
    func setCursorHiddenForTest(_ hidden: Bool) { hideCursor = hidden }
}

#if !os(Linux)
@MainActor
#endif
final class CaretMathTests: XCTestCase {
    let font = UIFont.systemFont(ofSize: 17)

    func testPrefixWidthMatchesMeasure() {
        let text = "Hello UIKit"
        let n = UITextCaretMath.scalarCount(text)
        XCTAssertEqual(UITextCaretMath.prefixWidth(text, count: 0, font: font), 0)
        XCTAssertEqual(UITextCaretMath.prefixWidth(text, count: n, font: font),
                       FontEngine.measure(text, font: font), accuracy: 1e-9)
        // Prefix widths are the same measurement the renderer uses
        // (advances + pair kerning), so caret x == glyph pen x.
        let w5 = UITextCaretMath.prefixWidth(text, count: 5, font: font)
        XCTAssertEqual(w5, FontEngine.measure("Hello", font: font), accuracy: 1e-9)
    }

    func testCaretIndexPicksNearestBoundary() {
        let text = "Hello"
        // Boundary positions.
        var bounds: [CGFloat] = []
        for i in 0...5 { bounds.append(UITextCaretMath.prefixWidth(text, count: i, font: font)) }
        // Exactly on a boundary -> that boundary.
        for (i, b) in bounds.enumerated() {
            XCTAssertEqual(UITextCaretMath.caretIndex(for: b, text: text, font: font), i)
        }
        // Just left/right of a midpoint snaps to the nearer side.
        let mid01 = (bounds[0] + bounds[1]) / 2
        XCTAssertEqual(UITextCaretMath.caretIndex(for: mid01 - 0.25, text: text, font: font), 0)
        XCTAssertEqual(UITextCaretMath.caretIndex(for: mid01 + 0.25, text: text, font: font), 1)
        // Far left/right clamp.
        XCTAssertEqual(UITextCaretMath.caretIndex(for: -50, text: text, font: font), 0)
        XCTAssertEqual(UITextCaretMath.caretIndex(for: 10_000, text: text, font: font), 5)
        // Empty text.
        XCTAssertEqual(UITextCaretMath.caretIndex(for: 3, text: "", font: font), 0)
    }

    func testScalarOffsetIndexRoundTrip() {
        let text = "héllo"   // é is one scalar here (U+00E9)
        XCTAssertEqual(UITextCaretMath.scalarCount(text), 5)
        let i = UITextCaretMath.index(text, atScalarOffset: 2)
        XCTAssertEqual(text[i], "l")
        // Clamp past the end.
        let end = UITextCaretMath.index(text, atScalarOffset: 99)
        XCTAssertEqual(end, text.endIndex)
    }
}

#if !os(Linux)
@MainActor
#endif
final class FirstResponderTests: XCTestCase {
    func makeWindowWithField() -> (UIWindow, UITextField) {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        let tf = UITextField(frame: CGRect(x: 20, y: 20, width: 280, height: 34))
        tf.borderStyle = .roundedRect
        w.addSubview(tf)
        w.layoutIfNeeded()
        return (w, tf)
    }

    func testBecomeResignFirstResponder() {
        let (w, tf) = makeWindowWithField()
        XCTAssertFalse(tf.isFirstResponder)
        XCTAssertTrue(tf.becomeFirstResponder())
        XCTAssertTrue(tf.isFirstResponder)
        XCTAssertTrue(w.firstResponder === tf)
        XCTAssertTrue(tf.isEditing)
        tf.resignFirstResponder()
        XCTAssertFalse(tf.isFirstResponder)
        XCTAssertNil(w.firstResponder)
        XCTAssertFalse(tf.isEditing)
    }

    func testFirstResponderWithoutWindowFails() {
        let tf = UITextField()
        XCTAssertFalse(tf.becomeFirstResponder())
    }

    func testFocusMovesBetweenFields() {
        let (w, tf1) = makeWindowWithField()
        let tf2 = UITextField(frame: CGRect(x: 20, y: 80, width: 280, height: 34))
        w.addSubview(tf2)
        var log: [String] = []
        tf1.addTarget(for: .editingDidBegin) { _, _ in log.append("begin1") }
        tf1.addTarget(for: .editingDidEnd) { _, _ in log.append("end1") }
        tf2.addTarget(for: .editingDidBegin) { _, _ in log.append("begin2") }
        tf1.becomeFirstResponder()
        tf2.becomeFirstResponder()
        XCTAssertTrue(w.firstResponder === tf2)
        XCTAssertFalse(tf1.isEditing)
        XCTAssertTrue(tf2.isEditing)
        XCTAssertEqual(log, ["begin1", "end1", "begin2"])
    }

    func testTapFocusesAndPositionsCaret() {
        let (w, tf) = makeWindowWithField()
        tf.text = "Hello UIKit"
        w.layoutIfNeeded()
        // Tap between 'H' and 'e' (prefix "H" is ~12pt wide): text starts at
        // textRect.x = 27 in window coords.
        let hw = UITextCaretMath.prefixWidth("Hello UIKit", count: 1,
                                             font: tf.font)
        let p = CGPoint(x: 27 + hw + 0.5, y: 37)
        w.sendTouch(.began, at: p, timestamp: 0)
        w.sendTouch(.ended, at: p, timestamp: 0.05)
        XCTAssertTrue(tf.isEditing)
        XCTAssertEqual(tf.caretOffset, 1)
    }
}

#if !os(Linux)
@MainActor
#endif
final class KeyboardAvoidanceInsetTests: XCTestCase {
    /// Forms t1200 vs t200, iPhone SE 2x, iOS 26.1: focusing a UITextField
    /// inside a table raises `adjustedContentInset.bottom` 0 → 260, while
    /// `contentInset` stays zero. The editor itself does not pick up the 260.
    func testTablePicksUpKeyboardOverlapOnlyWhileEditing() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let table = UITableView(frame: window.bounds, style: .grouped)
        let field = UITextField(frame: CGRect(x: 16, y: 10, width: 343, height: 22))
        table.addSubview(field)
        window.addSubview(table)
        window.layoutIfNeeded()

        XCTAssertEqual(table.adjustedContentInset.bottom, 0)
        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertEqual(table.contentInset.bottom, 0)
        XCTAssertEqual(table.adjustedContentInset.bottom, 260)
        _ = field.resignFirstResponder()
        XCTAssertEqual(table.adjustedContentInset.bottom, 0)
    }

    /// MEASURED Forms-ipad t1200, iPad (A16) 820×1180 @2x / iOS 26.1:
    /// focused table `adjustedContentInset.bottom` **337** vs rest **25**.
    /// Overlap 337 − 25 = **312**. Phone stays 260.
    func testPadTableKeyboardOverlapIs312() {
        let savedCut = OpenUIKitRuntime.systemFontCut
        let savedIdiom = UIDevice.current.userInterfaceIdiom
        let savedTraits = UITraitCollection.current
        OpenUIKitRuntime.systemFontCut = .iOS
        UIDevice.current.userInterfaceIdiom = .pad
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .pad)
        defer {
            OpenUIKitRuntime.systemFontCut = savedCut
            UIDevice.current.userInterfaceIdiom = savedIdiom
            UITraitCollection.current = savedTraits
        }

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
        window._setSafeAreaInsets(UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0))
        let table = UITableView(frame: window.bounds, style: .grouped)
        let field = UITextField(frame: CGRect(x: 20, y: 10, width: 780, height: 22))
        table.addSubview(field)
        window.addSubview(table)
        window.layoutIfNeeded()

        XCTAssertEqual(table.adjustedContentInset.bottom, 25)
        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertEqual(table.contentInset.bottom, 0)
        XCTAssertEqual(table.adjustedContentInset.bottom, 337)
        _ = field.resignFirstResponder()
        XCTAssertEqual(table.adjustedContentInset.bottom, 25)
    }
}

#if !os(Linux)
@MainActor
#endif
final class TextFieldEditingTests: XCTestCase {
    var w: UIWindow!
    var tf: UITextField!
    var events: [String] = []

    override func setUp() {
        super.setUp()
        w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        tf = UITextField(frame: CGRect(x: 20, y: 20, width: 280, height: 34))
        tf.borderStyle = .roundedRect
        w.addSubview(tf)
        w.layoutIfNeeded()
        events = []
        tf.addTarget(for: .editingChanged) { [self] c, _ in
            events.append("changed:\((c as! UITextField).text ?? "")")
        }
        tf.addTarget(for: .editingDidEnd) { [self] _, _ in events.append("didEnd") }
    }

    func testSecureEntryPreservesModelAndMasksRenderedLabel() {
        tf.text = "s3cr\u{00E9}t"
        tf.isSecureTextEntry = true
        tf.layoutIfNeeded()

        XCTAssertEqual(tf.text, "s3cr\u{00E9}t")
        XCTAssertEqual(tf.textLabel.text, "\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}")
        XCTAssertFalse(tf.textLabel.text?.contains("s3cr") == true)

        tf.isSecureTextEntry = false
        XCTAssertEqual(tf.textLabel.text, "s3cr\u{00E9}t")
    }

    func testTypingInsertsAtCaret() {
        tf.becomeFirstResponder()
        w.sendText("Hi")
        XCTAssertEqual(tf.text, "Hi")
        XCTAssertEqual(tf.caretOffset, 2)
        w.sendKey(.left)
        w.sendText("ey ")
        XCTAssertEqual(tf.text, "Hey i")
        XCTAssertEqual(tf.caretOffset, 4)
        XCTAssertEqual(events, ["changed:Hi", "changed:Hey i"])
    }

    func testBackspaceDeletesBeforeCaret() {
        tf.text = "abc"
        tf.becomeFirstResponder()   // caret at end
        XCTAssertEqual(tf.caretOffset, 3)
        w.sendKey(.backspace)
        XCTAssertEqual(tf.text, "ab")
        w.sendKey(.left)
        w.sendKey(.backspace)
        XCTAssertEqual(tf.text, "b")
        XCTAssertEqual(tf.caretOffset, 0)
        w.sendKey(.backspace)   // at position 0: no-op
        XCTAssertEqual(tf.text, "b")
    }

    func testArrowsClampToTextEnds() {
        tf.text = "ab"
        tf.becomeFirstResponder()
        w.sendKey(.right)
        XCTAssertEqual(tf.caretOffset, 2)
        w.sendKey(.left); w.sendKey(.left); w.sendKey(.left)
        XCTAssertEqual(tf.caretOffset, 0)
    }

    func testReturnResignsAndFiresDidEnd() {
        tf.becomeFirstResponder()
        w.sendText("x")
        w.sendKey(.return)
        XCTAssertFalse(tf.isEditing)
        XCTAssertNil(w.firstResponder)
        XCTAssertEqual(events, ["changed:x", "didEnd"])
    }

    func testOverflowScrollKeepsCaretVisible() {
        tf.text = "The quick brown fox jumps over the lazy dog near the bank"
        tf.becomeFirstResponder()   // caret at end
        w.layoutIfNeeded()
        let textW = FontEngine.measure(tf.text!, font: tf.font)
        let visibleW = tf.textRect(forBounds: tf.bounds).width
        XCTAssertGreaterThan(textW, visibleW)
        // Caret (at the end) must sit inside the visible strip.
        let caretX = tf.caretTextX - tf.textScrollOffset
        XCTAssertGreaterThanOrEqual(caretX, 0)
        XCTAssertLessThanOrEqual(caretX, visibleW)
        // Move to start: scroll returns to 0.
        for _ in 0..<UITextCaretMath.scalarCount(tf.text!) { w.sendKey(.left) }
        w.layoutIfNeeded()
        XCTAssertEqual(tf.textScrollOffset, 0)
    }

    func testCaretBlinkOnHostClock() {
        OpenUIKitRuntime.animationTime = 0
        tf.becomeFirstResponder()
        w.layoutIfNeeded()
        let caret = tf.caretView!
        XCTAssertFalse(caret.isHidden)          // solid right after focus
        w.tick(timestamp: UITextInputState.solidHold + 0.1)
        XCTAssertTrue(caret.isHidden)           // first blink-off phase
        w.tick(timestamp: UITextInputState.solidHold
               + UITextInputState.blinkHalfPeriod + 0.1)
        XCTAssertFalse(caret.isHidden)          // back on
        // Typing makes it solid immediately.
        w.tick(timestamp: 2.6)                  // some off phase
        w.sendText("a", timestamp: 2.61)
        XCTAssertFalse(caret.isHidden)
        tf.resignFirstResponder()
    }

    func testCaretGeometry17pt() {
        tf.text = "Hello"
        tf.becomeFirstResponder()
        w.layoutIfNeeded()
        let caret = tf.caretView!
        // Measured caret metrics at 17 pt in a 34 pt field: height 21.5,
        // y = 6 (field coords; caret lives in the canvas at (7, 2)).
        XCTAssertEqual(caret.frame.height, 21.5, accuracy: 1e-9)
        XCTAssertEqual(caret.frame.minY + 2, 6, accuracy: 1e-9)
        XCTAssertEqual(caret.frame.width, 2)
        // Caret x = pixel-rounded text width (caret at end).
        let expected = FontEngine.roundToPixel(
            FontEngine.measure("Hello", font: tf.font), scale: 2)
        XCTAssertEqual(caret.frame.minX, expected, accuracy: 1e-9)
    }
}

#if !os(Linux)
@MainActor
#endif
final class TextFieldSelectionTests: XCTestCase {
    final class Delegate: UITextFieldDelegate {
        var changes: [NSRange] = []
        var selectionChanges = 0

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            changes.append(range)
            return true
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            selectionChanges += 1
        }
    }

    func position(_ offset: Int, in field: UITextField) -> UITextPosition {
        field.position(from: field.beginningOfDocument, offset: offset)!
    }

    func range(_ lower: Int, _ upper: Int, in field: UITextField) -> UITextRange {
        field.textRange(from: position(lower, in: field),
                        to: position(upper, in: field))!
    }

    func offsets(of range: UITextRange, in field: UITextField) -> [Int] {
        [field.offset(from: field.beginningOfDocument, to: range.start),
         field.offset(from: field.beginningOfDocument, to: range.end)]
    }

    func testUTF16PositionsRangesAndStrictDocumentIdentity() {
        let field = UITextField()
        field.text = "A😀B"

        XCTAssertEqual(field.offset(from: field.beginningOfDocument,
                                    to: field.endOfDocument), 4)
        XCTAssertEqual(position(0, in: field), field.beginningOfDocument)
        XCTAssertEqual(position(4, in: field), field.endOfDocument)
        XCTAssertNil(field.position(from: field.beginningOfDocument, offset: 5))
        XCTAssertNil(field.position(from: field.beginningOfDocument, offset: Int.min))

        // Real UIKit permits every UTF-16 boundary, including the middle of
        // a surrogate pair; slicing there produces the replacement scalar.
        XCTAssertEqual(field.text(in: range(0, 2, in: field)), "A�")
        XCTAssertEqual(field.text(in: range(1, 3, in: field)), "😀")
        XCTAssertEqual(offsets(of: field.textRange(from: position(3, in: field),
                                                   to: position(1, in: field))!,
                               in: field), [1, 3])

        let other = UITextField()
        other.text = field.text
        let foreign = range(0, 1, in: other)
        let originalSelection = field.selectedTextRange!
        XCTAssertNil(field.text(in: foreign))
        XCTAssertNil(field.textRange(from: foreign.start, to: field.endOfDocument))
        XCTAssertNil(field.position(from: foreign.start, offset: 1))
        XCTAssertEqual(field.offset(from: foreign.start, to: field.endOfDocument), 0)
        field.selectedTextRange = foreign
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field),
                       offsets(of: originalSelection, in: field))
        XCTAssertEqual(field.caretRect(for: foreign.start), .zero)

        // UIKit's three abstract document geometry classes are NSObject
        // subclassing surfaces, not unrelated Swift-only value wrappers.
        let positionObject: NSObject = field.beginningOfDocument
        let rangeObject: NSObject = field.selectedTextRange!
        let selectionObject: NSObject = UITextSelectionRect()
        XCTAssertNotEqual(positionObject, rangeObject)
        XCTAssertEqual((selectionObject as! UITextSelectionRect).writingDirection,
                       .natural)
    }

    func testSelectionReplacementAndContentAssignmentClamping() {
        let field = UITextField()
        field.text = "A😀B"
        field.selectedTextRange = range(1, 3, in: field)
        XCTAssertEqual(field.text(in: field.selectedTextRange!), "😀")

        field.replace(field.selectedTextRange!, withText: "Z")
        XCTAssertEqual(field.text, "AZB")
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [2, 2])

        field.text = "abcdef"
        field.selectedTextRange = range(2, 4, in: field)
        field.text = "xy"
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [2, 2])
        field.selectedTextRange = nil
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [0, 0])
        field.selectedTextRange = field.textRange(from: field.endOfDocument,
                                                  to: field.endOfDocument)
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [2, 2])
    }

    func testTypingReplacesSelectionAndBackspaceDeletesComposedCharacters() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
        let field = UITextField(frame: CGRect(x: 10, y: 10, width: 280, height: 34))
        let delegate = Delegate()
        field.delegate = delegate
        window.addSubview(field)

        field.text = "A😀B"
        XCTAssertTrue(field.becomeFirstResponder())
        field.selectedTextRange = range(1, 3, in: field)
        window.sendText("Z")
        XCTAssertEqual(field.text, "AZB")
        XCTAssertEqual(delegate.changes.last, NSRange(location: 1, length: 2))
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [2, 2])

        field.text = "A😀B"
        field.selectedTextRange = range(3, 3, in: field)
        window.sendKey(.backspace)
        XCTAssertEqual(field.text, "AB")
        XCTAssertEqual(delegate.changes.last, NSRange(location: 1, length: 2))
        XCTAssertEqual(field.caretOffset, 1)

        field.text = "Ae\u{301}B"
        field.selectedTextRange = range(3, 3, in: field)
        window.sendKey(.backspace)
        XCTAssertEqual(field.text, "AB")
        XCTAssertEqual(delegate.changes.last, NSRange(location: 1, length: 2))
        XCTAssertEqual(field.caretOffset, 1)

        field.text = "A😀B"
        field.selectedTextRange = range(4, 4, in: field)
        window.sendKey(.left)
        XCTAssertEqual(field.caretOffset, 3)
        window.sendKey(.left)
        XCTAssertEqual(field.caretOffset, 1)

        field.text = "A😀B"
        field.selectedTextRange = range(2, 2, in: field)
        window.sendKey(.backspace)
        XCTAssertEqual(field.text, "AB")
        XCTAssertEqual(delegate.changes.last, NSRange(location: 1, length: 2))
        XCTAssertEqual(field.caretOffset, 1)
    }

    func testMarkedTextReplacementSelectionAndCommit() {
        let field = UITextField()
        let delegate = Delegate()
        field.delegate = delegate
        field.text = "abcdef"
        field.selectedTextRange = range(2, 4, in: field)

        var editingChanges = 0
        field.addTarget(for: .editingChanged) { control, _ in
            _ = control
            editingChanges += 1
        }
        let delegateMutationsBeforeMark = delegate.changes.count
        let selectionChangesBeforeMark = delegate.selectionChanges
        field.setMarkedText("XYZ", selectedRange: NSRange(location: 1, length: 1))

        XCTAssertEqual(field.text, "abXYZef")
        XCTAssertEqual(offsets(of: field.markedTextRange!, in: field), [2, 5])
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [3, 4])
        XCTAssertEqual(field.text(in: field.markedTextRange!), "XYZ")
        XCTAssertEqual(editingChanges, 0)
        XCTAssertEqual(delegate.changes.count, delegateMutationsBeforeMark)
        XCTAssertEqual(delegate.selectionChanges, selectionChangesBeforeMark + 1)

        field.setMarkedText("Q", selectedRange: NSRange(location: 99, length: 99))
        XCTAssertEqual(field.text, "abQef")
        XCTAssertEqual(offsets(of: field.markedTextRange!, in: field), [2, 3])
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [3, 3])
        field.selectedTextRange = nil
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [0, 0])
        XCTAssertNotNil(field.markedTextRange)
        field.setMarkedText(nil, selectedRange: NSRange(location: 0, length: 0))
        XCTAssertNil(field.markedTextRange)
        XCTAssertEqual(field.text, "abef")
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [2, 2])
        XCTAssertEqual(editingChanges, 0)
        XCTAssertEqual(delegate.changes.count, delegateMutationsBeforeMark)
    }

    func testMarkedEmptyAndDirectReplaceUseUITextInputCallbacks() {
        let field = UITextField()
        let delegate = Delegate()
        field.delegate = delegate
        field.text = "abcdef"
        field.selectedTextRange = range(2, 4, in: field)

        var editingChanges = 0
        field.addTarget(for: .editingChanged) { _, _ in editingChanges += 1 }
        delegate.changes.removeAll()
        delegate.selectionChanges = 0

        // With no active mark, an empty non-nil marked string is a no-op.
        field.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
        XCTAssertEqual(field.text, "abcdef")
        XCTAssertNil(field.markedTextRange)
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [2, 4])
        XCTAssertEqual(delegate.changes.count, 0)
        XCTAssertEqual(delegate.selectionChanges, 0)
        XCTAssertEqual(editingChanges, 0)

        field.setMarkedText("XYZ", selectedRange: NSRange(location: 0, length: 0))
        delegate.selectionChanges = 0
        field.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
        XCTAssertEqual(field.text, "abef")
        XCTAssertNil(field.markedTextRange)
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [2, 2])
        XCTAssertEqual(delegate.changes.count, 0)
        XCTAssertEqual(delegate.selectionChanges, 1)
        XCTAssertEqual(editingChanges, 0)

        delegate.selectionChanges = 0
        field.replace(range(0, 2, in: field), withText: "Q")
        XCTAssertEqual(field.text, "Qef")
        XCTAssertEqual(offsets(of: field.selectedTextRange!, in: field), [1, 1])
        XCTAssertEqual(delegate.changes.count, 0)
        XCTAssertEqual(delegate.selectionChanges, 1)
        XCTAssertEqual(editingChanges, 0)
    }

    func testCaretAndSelectionGeometryUseDocumentPositions() {
        let field = UITextField(frame: CGRect(x: 0, y: 0, width: 240, height: 34))
        field.borderStyle = .roundedRect
        field.text = "Hello"
        field.layoutIfNeeded()

        let caret = field.caretRect(for: position(2, in: field))
        let expectedX = field.textRect(forBounds: field.bounds).minX
            + FontEngine.roundToPixel(FontEngine.measure("He", font: field.font), scale: 2)
        XCTAssertEqual(caret.minX, expectedX, accuracy: 1e-9)
        XCTAssertEqual(caret.minY, 6, accuracy: 1e-9)
        XCTAssertEqual(caret.width, 1, accuracy: 1e-9)
        XCTAssertEqual(caret.height, 21.5, accuracy: 1e-9)

        let selection = range(1, 4, in: field)
        let first = field.firstRect(for: selection)
        let startX = field.caretRect(for: position(1, in: field)).minX
        let endX = field.caretRect(for: position(4, in: field)).minX
        XCTAssertEqual(first.minX, startX, accuracy: 1e-9)
        XCTAssertEqual(first.width, endX - startX, accuracy: 1e-9)
        let rects = field.selectionRects(for: selection)
        XCTAssertEqual(rects.count, 1)
        XCTAssertEqual(rects[0].rect, first)
        XCTAssertTrue(rects[0].containsStart)
        XCTAssertTrue(rects[0].containsEnd)
        XCTAssertFalse(rects[0].isVertical)
        XCTAssertEqual(rects[0].writingDirection, .natural)
        XCTAssertTrue(field.selectionRects(for: range(2, 2, in: field)).isEmpty)

        field.text = "A😀B"
        let leadingEmojiX = field.caretRect(for: position(1, in: field)).minX
        let surrogateMidpointX = field.caretRect(for: position(2, in: field)).minX
        let trailingEmojiX = field.caretRect(for: position(3, in: field)).minX
        XCTAssertEqual(surrogateMidpointX, leadingEmojiX, accuracy: 1e-9)
        XCTAssertGreaterThanOrEqual(trailingEmojiX, surrogateMidpointX)
    }

    func testExactFocusOverrideBodiesCompileAndRunUnchanged() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
        let field = FocusAutocompleteTextInputExcerpt(
            frame: CGRect(x: 10, y: 10, width: 280, height: 34))
        window.addSubview(field)
        field.text = "moz"
        XCTAssertTrue(field.becomeFirstResponder())

        field.installCompletion("illa")
        field.applyCompletionForTest()
        XCTAssertEqual(field.text, "mozilla")
        XCTAssertEqual(field.offset(from: field.beginningOfDocument,
                                    to: field.selectedTextRange!.end), 7)

        field.installCompletion(".org")
        field.setMarkedText("Q", selectedRange: NSRange(location: 1, length: 0))
        XCTAssertFalse(field.isSelectionActive)
        XCTAssertEqual(field.markedTextRange.map { field.text(in: $0) }.flatMap { $0 }, "Q")
        // A new provisional edit has real range/selection semantics after
        // the Focus override clears its completion.
        field.setMarkedText("XY", selectedRange: NSRange(location: 1, length: 1))
        XCTAssertEqual(field.markedTextRange.map { field.text(in: $0) }.flatMap { $0 }, "XY")

        field.unmarkText()
        field.setCursorHiddenForTest(true)
        XCTAssertEqual(field.caretRect(for: field.endOfDocument), .zero)
        field.setCursorHiddenForTest(false)
        XCTAssertEqual(field.caretRect(for: field.endOfDocument).width, 1)
    }
}

#if !os(Linux)
@MainActor
#endif
final class TextViewEditingTests: XCTestCase {
    var w: UIWindow!
    var tv: UITextView!

    override func setUp() {
        super.setUp()
        w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        tv = UITextView(frame: CGRect(x: 16, y: 16, width: 288, height: 140))
        tv.font = .systemFont(ofSize: 17)
        w.addSubview(tv)
        w.layoutIfNeeded()
    }

    func testTextNilAssignmentResetsContentAndCaretToEmpty() {
        tv.text = "abcdef"
        tv.caretOffset = 6
        tv.attributedText = NSAttributedString(string: "styled")
        XCTAssertNotNil(tv._attributed)

        tv.text = nil

        XCTAssertEqual(tv.text, "")
        XCTAssertNil(tv._attributed)
        XCTAssertEqual(tv.caretOffset, 0)
        w.layoutIfNeeded()
        XCTAssertEqual(tv.contentSize.height, 16 + 20)
    }

    func testTypingAndNewlines() {
        tv.becomeFirstResponder()
        w.sendText("Hello")
        w.sendKey(.return)
        w.sendText("World")
        XCTAssertEqual(tv.text, "Hello\nWorld")
        XCTAssertEqual(tv.caretOffset, 11)
        XCTAssertEqual(tv.lineRuns().count, 2)
        w.sendKey(.backspace)
        XCTAssertEqual(tv.text, "Hello\nWorl")
    }

    func testCaretRectPerLine() {
        tv.text = "Hello\nWorld"
        tv.becomeFirstResponder()      // caret at end (line 2)
        let r = tv.caretRect()
        // Measured: x = 5 + prefix, y = floor(8 + i*20 - 0.75), h = 21.5.
        XCTAssertEqual(r.height, 21.5, accuracy: 1e-9)
        XCTAssertEqual(r.minY, 27)     // line 1: floor(8 + 20 - 0.75)
        let wWorld = FontEngine.roundToPixel(
            FontEngine.measure("World", font: tv.effectiveFont), scale: 2)
        XCTAssertEqual(r.minX, 5 + wWorld, accuracy: 1e-9)
        // Line 0 caret.
        tv.caretOffset = 0
        XCTAssertEqual(tv.caretRect().minY, 7)   // floor(8 - 0.75)
        XCTAssertEqual(tv.caretRect().minX, 5)
    }

    func testUpDownArrowsPreserveColumn() {
        tv.text = "aaaa aaaa aaaa\nbb\ncccc cccc cccc"
        tv.becomeFirstResponder()
        tv.caretOffset = 10            // line 0, column 10
        w.sendKey(.up)                 // clamped (already top)
        XCTAssertEqual(tv.caretOffset, 10)
        w.sendKey(.down)               // line 1 has 2 chars -> clamps to 2
        XCTAssertEqual(tv.caretOffset, 17)   // "aaaa aaaa aaaa\n" = 15 + 2
        w.sendKey(.down)               // line 2, preferred column restored
        XCTAssertEqual(tv.caretOffset, 18 + 10)
    }

    func testTapPositionsCaretInLine() {
        tv.text = "Hello UIKit down here"
        w.layoutIfNeeded()
        // Tap line 0 between scalars 6 and 7 ("Hello U|IKit").
        let x = 5 + UITextCaretMath.prefixWidth(tv.text, count: 7,
                                                font: tv.effectiveFont)
        let p = CGPoint(x: 16 + x - 0.3, y: 16 + 8 + 10)
        w.sendTouch(.began, at: p, timestamp: 10)
        w.sendTouch(.ended, at: p, timestamp: 10.05)
        XCTAssertTrue(tv.isEditing)
        XCTAssertEqual(tv.caretOffset, 7)
    }

    func testContentSizeTracksEdits() {
        tv.text = ""
        w.layoutIfNeeded()
        XCTAssertEqual(tv.contentSize.height, 16 + 20)   // one empty line
        tv.becomeFirstResponder()
        w.sendText("line1")
        w.sendKey(.return)
        w.sendText("line2")
        w.layoutIfNeeded()
        XCTAssertEqual(tv.contentSize.height, 16 + 2 * 20)
    }
}
