import XCTest
@testable import OpenUIKit

/// UITextView's UITextInput model and the small RxCocoa rows, replayed
/// against the iPhone 16 / iOS 26.1 transcript
/// Tools/oracle2/textviewinputprobe/transcript-ios26.1.txt — the SAME
/// scenario functions (TextViewTextInputScenario.swift, RxRowsScenario.swift)
/// ran there against Apple's UIKit.
#if !os(Linux)
@MainActor
#endif
final class TextViewTextInputTests: XCTestCase {
    private var savedCut = OpenUIKitRuntime.systemFontCut
    private var savedBounds = CGRect.zero
    private var savedScale: CGFloat = 2

    /// The oracle device: iPhone 16 (393 x 852 @3x), iOS system-font cut.
    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        savedBounds = UIScreen.main.bounds
        savedScale = UIScreen.main.scale
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852), scale: 3)
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        super.tearDown()
    }

    private func oracleSection(_ name: String) throws -> [String] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Tools/oracle2/textviewinputprobe/transcript-ios26.1.txt")
        let text = try String(contentsOf: url, encoding: .utf8)
        var out: [String] = []
        var inSection = false
        for line in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if line.hasPrefix("## ") { inSection = (line == "## " + name); continue }
            if inSection && !line.isEmpty { out.append(line) }
        }
        return out
    }

    private func settle() { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01)) }

    private func host() -> (UIWindow, UIView) {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let vc = UIViewController()
        w.rootViewController = vc
        w.makeKeyAndVisible()
        return (w, vc.view)
    }

    /// Numbers inside parentheses (geometry) compare within `tolerance`
    /// points: the port's glyph advances are not Apple's to the pixel (text x
    /// differs by <= 0.5 pt on these strings; every y/height is exact).
    private func geometryMatches(_ a: String, _ b: String, tolerance: Double) -> Bool {
        func split(_ s: String) -> ([String], [Double]) {
            var words: [String] = [], nums: [Double] = []
            var cur = ""
            var inParen = false
            for ch in s {
                if ch == "(" { inParen = true; words.append(cur); cur = ""; continue }
                if ch == ")" { inParen = false; nums += cur.split(separator: ",").compactMap { Double($0) }; cur = ""; continue }
                cur.append(ch)
                _ = inParen
            }
            words.append(cur)
            return (words, nums)
        }
        let (wa, na) = split(a), (wb, nb) = split(b)
        guard wa == wb, na.count == nb.count else { return false }
        return zip(na, nb).allSatisfy { abs($0 - $1) <= tolerance }
    }

    private func compare(_ got: [String], _ want: [String], geometryTolerance: Double,
                         file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(want.isEmpty, "oracle section missing", file: file, line: line)
        for i in 0..<max(got.count, want.count) {
            let g = i < got.count ? got[i] : "<missing>"
            let w = i < want.count ? want[i] : "<missing>"
            if g == w { continue }
            if w.hasPrefix("geometry"), geometryMatches(g, w, tolerance: geometryTolerance) { continue }
            XCTFail("line \(i + 1):\n  iOS 26.1: \(w)\n  OpenUIKit: \(g)", file: file, line: line)
        }
    }

    func testUITextViewTextInputMatchesIOS26() throws {
        let want = try oracleSection("textview")
        let (window, view) = host()
        let got = OUKTextViewInputScenario.run(host: view, settle: settle)
        _ = window
        compare(got, want, geometryTolerance: 0.5)
    }

    func testRxRowsMatchIOS26() throws {
        let want = try oracleSection("rxrows")
        let (window, view) = host()
        let got = OUKRxRowsScenario.run(host: view, settle: settle)
        _ = window
        compare(got, want, geometryTolerance: 0)
    }

    /// RxCocoa's `TextInput<Base: UITextInput>` (Common/TextInput.swift)
    /// needs UITextView to conform, as on iOS.
    func testUITextViewIsUITextInput() {
        func take<T: UITextInput>(_ t: T) -> T { t }
        let tv = UITextView()
        XCTAssertTrue(take(tv) === tv)
    }

    /// The host keyboard path still asks `shouldChangeTextIn` (the
    /// direct `insertText` API does not — MEASURED).
    func testKeyboardPathStillConsultsDelegate() {
        final class Deny: NSObject, UITextViewDelegate {
            var asked: [String] = []
            func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                          replacementText text: String) -> Bool { asked.append(text); return false }
        }
        let (window, view) = host()
        let tv = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        view.addSubview(tv)
        let d = Deny()
        tv.delegate = d
        XCTAssertTrue(tv.becomeFirstResponder())
        window.sendText("a")
        XCTAssertEqual(tv.text, "")
        XCTAssertEqual(d.asked, ["a"])
        tv.insertText("b")
        XCTAssertEqual(tv.text, "b")
        XCTAssertEqual(d.asked, ["a"])
    }
}
