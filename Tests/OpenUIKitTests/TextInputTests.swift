// Text-input module tests (M8): caret positioning math, the first-responder
// system, and the UITextField/UITextView editing model — all with synthetic
// deterministic timestamps (the caret blink runs on the host clock).
import XCTest
import Foundation
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect

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
