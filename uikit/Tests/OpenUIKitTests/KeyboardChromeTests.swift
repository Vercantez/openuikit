// iOS software-keyboard chrome. MEASURED /tmp/kb-se field_white_light,
// iPhone SE 2x / iOS 26.1: panel [0, 407, 375, 260], Q at
// [8.5, 459, 30.5, 42], overlap 260. Catalyst does not install the window.
import Foundation
import XCTest
@testable import OpenUIKit

@MainActor
final class KeyboardChromeTests: XCTestCase {

    var savedCut = OpenUIKitRuntime.systemFontCut

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        super.tearDown()
    }

    func makeWindow() -> (UIWindow, UITextField) {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        w.backgroundColor = .white
        let tf = UITextField(frame: CGRect(x: 16, y: 80, width: 343, height: 34))
        w.addSubview(tf)
        w.layoutIfNeeded()
        return (w, tf)
    }

    func keyboardWindow() -> _UIKeyboardWindow? {
        for w in UIApplication.shared.windows {
            if let kb = w as? _UIKeyboardWindow { return kb }
        }
        return nil
    }

    func testIOSFocusInstallsMeasuredPanelAndQKey() throws {
        OpenUIKitRuntime.systemFontCut = .iOS
        let (_, tf) = makeWindow()
        XCTAssertTrue(tf.becomeFirstResponder())
        let kb = try XCTUnwrap(keyboardWindow())
        XCTAssertFalse(kb.isHidden)
        XCTAssertEqual(kb.windowLevel.rawValue, 1)
        XCTAssertEqual(kb.restPanelFrame,
                       CGRect(x: 0, y: 407, width: 375, height: 260))
        XCTAssertEqual(kb.panel.frame.origin.y, 407, accuracy: 0.01)
        XCTAssertEqual(kb.panel.layer.cornerRadius, 26, accuracy: 0.01)

        var q: _UIKeyboardKey?
        for sub in kb.panel.subviews {
            guard let key = sub as? _UIKeyboardKey, key.label?.text == "Q" else {
                continue
            }
            q = key
            break
        }
        let key = try XCTUnwrap(q)
        XCTAssertEqual(key.frame, CGRect(x: 8.5, y: 52, width: 30.5, height: 42))
        XCTAssertEqual(key.layer.cornerRadius, 7, accuracy: 0.01)
        XCTAssertEqual(key.label?.font.pointSize ?? 0, 22, accuracy: 0.01)
        _ = tf.resignFirstResponder()
    }

    func testCatalystCutDoesNotShowKeyboard() {
        OpenUIKitRuntime.systemFontCut = .macOS
        let (_, tf) = makeWindow()
        XCTAssertTrue(tf.becomeFirstResponder())
        if let kb = keyboardWindow() {
            XCTAssertTrue(kb.isHidden)
        }
        _ = tf.resignFirstResponder()
    }

    func testUnfocusedCaptureDoesNotCompositeKeyboard() {
        OpenUIKitRuntime.systemFontCut = .iOS
        let (w, tf) = makeWindow()
        let a = UIRenderer.render(w, scale: 2)
        let b = _UIKeyboardChrome.renderCapture(appWindow: w, scale: 2)
        XCTAssertTrue(a.pixels.elementsEqual(b.pixels))
        XCTAssertTrue(tf.becomeFirstResponder())
        OpenUIKitRuntime.animationTime += _UIKeyboardChrome.presentDuration + 0.05
        UIView._stepAnimationCompletions(to: OpenUIKitRuntime.animationTime)
        let focused = _UIKeyboardChrome.renderCapture(appWindow: w, scale: 2)
        XCTAssertFalse(a.pixels.elementsEqual(focused.pixels))
        // Key cap fill, not the Q ink: panel-local (18.5, 58) → window
        // (18.5, 465) → 2x px (37, 930). MEASURED field_white_light interiors
        // are opaque 255.
        let o = (930 * focused.width + 37) * 4
        XCTAssertEqual(focused.pixels[o], 255)
        XCTAssertEqual(focused.pixels[o + 1], 255)
        XCTAssertEqual(focused.pixels[o + 2], 255)
        XCTAssertEqual(focused.pixels[o + 3], 255)
        _ = tf.resignFirstResponder()
    }
}
