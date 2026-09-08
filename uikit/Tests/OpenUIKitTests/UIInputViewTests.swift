import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
private final class SilentInputView: UIInputView, UIInputViewAudioFeedback {}

#if !os(Linux)
@MainActor
#endif
private final class AudibleInputView: UIInputView, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { true }
}

#if !os(Linux)
@MainActor
#endif
final class UIInputViewTests: XCTestCase {
    func testDefaultAndFrameInitializersMatchOracle() {
        let zero = UIInputView()
        XCTAssertEqual(zero.frame, .zero)
        XCTAssertEqual(zero.inputViewStyle, .default)
        XCTAssertFalse(zero.allowsSelfSizing)
        let frame = CGRect(x: 4, y: 6, width: 140, height: 70)
        let view = UIInputView(frame: frame)
        XCTAssertEqual(view.frame, frame)
        XCTAssertEqual(view.inputViewStyle, .default)
        XCTAssertNil(view.backgroundColor)
        XCTAssertTrue(view.isOpaque)
        XCTAssertFalse(view.clipsToBounds)
    }

    func testExplicitStylesKeepGeometryAndRawValues() {
        XCTAssertEqual(UIInputView.Style.default.rawValue, 0)
        XCTAssertEqual(UIInputView.Style.keyboard.rawValue, 1)
        let frame = CGRect(x: 20, y: 150, width: 300, height: 80)
        for style: UIInputView.Style in [.default, .keyboard] {
            let view = UIInputView(frame: frame, inputViewStyle: style)
            XCTAssertEqual(view.inputViewStyle, style)
            XCTAssertEqual(view.frame, frame)
            XCTAssertEqual(view.bounds, CGRect(origin: .zero, size: frame.size))
            XCTAssertNil(view.backgroundColor)
            XCTAssertTrue(view.isOpaque)
            XCTAssertFalse(view.clipsToBounds)
        }
    }

    func testSelfSizingRoundTripsWithoutInventingIntrinsicSize() {
        for style: UIInputView.Style in [.default, .keyboard] {
            let view = UIInputView(frame: CGRect(x: 20, y: 150, width: 300, height: 80), inputViewStyle: style)
            XCTAssertFalse(view.allowsSelfSizing)
            for value in [true, false] {
                view.allowsSelfSizing = value
                XCTAssertEqual(view.allowsSelfSizing, value)
                XCTAssertEqual(view.intrinsicContentSize, CGSize(width: -1, height: -1))
                XCTAssertEqual(view.sizeThatFits(.zero), view.bounds.size)
                XCTAssertEqual(view.sizeThatFits(CGSize(width: 400, height: 200)), view.bounds.size)
            }
        }
    }

    func testUnsupportedArchiveFailsClosed() {
        XCTAssertNil(UIInputView(coder: NSCoder()))
    }

    func testAudioFeedbackDefaultsDisabledAndAllowsExplicitOptIn() {
        let silent: UIInputViewAudioFeedback = SilentInputView()
        let audible: UIInputViewAudioFeedback = AudibleInputView()
        XCTAssertFalse(silent.enableInputClicksWhenVisible)
        XCTAssertTrue(audible.enableInputClicksWhenVisible)
        // A capability descriptor does not create an audio backend.
        UIDevice.current.playInputClick()
        UIDevice.current.playInputClick()
        XCTAssertFalse(silent.enableInputClicksWhenVisible)
        XCTAssertTrue(audible.enableInputClicksWhenVisible)
    }
}
