// SwiftUI surface ios-oss ServerDrivenUI / Library / KDS need (pass 3).
// Values quoted from the iOS 26.1 transcripts of Tools/oracle2/
// swiftuia11yprobe and iososslibraryprobe where they are measurable.
import XCTest
#if os(Linux)
@preconcurrency @testable import SwiftUI
@preconcurrency @testable import OpenUIKit
#else
@testable import SwiftUI
@testable import OpenUIKit
#endif

@MainActor
final class IosOssServerDrivenUITests: XCTestCase {
    // ImageBlock.swift:22 `Color(style.color.swiftUIColor())` — compiles on
    // iOS 26.1 and is the same colour.
    func testColorFromColor() {
        XCTAssertEqual(Color(Color.red), Color.red)
    }

    // text.truncationMode.raws=["head", "tail", "middle"]
    func testNestedTruncationModeSpelling() {
        let modes: [Text.TruncationMode] = [.head, .tail, .middle]
        XCTAssertEqual(modes, [.head, .tail, .middle])
    }

    func testItalicUsesTheItalicSystemDesign() {
        XCTAssertEqual(Font.body.italic().resolve(weight: nil).design, .italic)
        XCTAssertEqual(Font.body.italic().resolve(weight: nil).pointSize, 17)
        XCTAssertEqual(Font.system(size: 20, weight: .bold).italic().resolve(weight: nil).weight, .bold)
    }

    // KDS `Font(uiFont)` must keep a registered face (it used to flatten
    // every UIFont into a system descriptor).
    func testFontFromUIFontKeepsTheFont() {
        let system = UIFont.systemFont(ofSize: 15, weight: .semibold)
        XCTAssertEqual(Font(system).resolve(weight: nil), system)
        XCTAssertEqual(Font(system).weight(.bold).resolve(weight: nil).weight, .bold)
    }

    // uikit.* raw values; the SwiftUI traits map by name (the hosted tree is
    // not measurable without an assistive technology).
    func testNewTraitsCompileAndAreDistinct() {
        let t: AccessibilityTraits = [.isStaticText, .startsMediaSession]
        XCTAssertTrue(t.contains(.isStaticText))
        XCTAssertFalse(t.contains(.isHeader))
        let v = Text("x").accessibilityHeading(.h1).backgroundStyle(Color.gray)
        _ = v
        XCTAssertNotEqual(AccessibilityHeadingLevel.h4, .h1)
    }

    func testListWithSelectionBuildsAPlainList() {
        var selection: Int? = nil
        let binding = Binding<Int?>(get: { selection }, set: { selection = $0 })
        let list = List(selection: binding) { Text("a") }
        _ = list._makeOpenUIKitNode()
        XCTAssertNil(selection, "the port never writes the selection")
    }
}
