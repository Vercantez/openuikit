import XCTest
import UIKit

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
final class UIKitAttributedScopeTests: XCTestCase {
    func testTypedUIKitAttributesRoundTripThroughAttributedString() {
        var attributed = AttributedString("code link")
        let range = attributed.startIndex ..< attributed.endIndex
        let font = UIFont.monospacedSystemFont(ofSize: 17, weight: .semibold)
        let color = UIColor.systemBlue

        attributed[range][AttributeScopes.UIKitAttributes.FontAttribute.self] = font
        attributed[range][AttributeScopes.UIKitAttributes.ForegroundColorAttribute.self] = color
        attributed[range][AttributeScopes.UIKitAttributes.UnderlineStyleAttribute.self] = .single

        XCTAssertEqual(
            attributed[range][AttributeScopes.UIKitAttributes.FontAttribute.self],
            font
        )
        XCTAssertEqual(
            attributed[range][AttributeScopes.UIKitAttributes.ForegroundColorAttribute.self],
            color
        )
        XCTAssertEqual(
            attributed[range][AttributeScopes.UIKitAttributes.UnderlineStyleAttribute.self],
            .single
        )
    }

    func testOpenUIKitDictionaryConvertsToTypedParagraphAttribute() {
        let paragraph = OpenUIKit.NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.25
        paragraph.paragraphSpacing = 8

        let container = AttributeContainer([
            OpenUIKit.NSAttributedString.Key.paragraphStyle: paragraph,
        ])

        let stored = container[
            AttributeScopes.UIKitAttributes.ParagraphStyleAttribute.self
        ]
        XCTAssertEqual(stored, paragraph)
        XCTAssertEqual(stored?.lineHeightMultiple, 1.25)
        XCTAssertEqual(stored?.paragraphSpacing, 8)
    }

    func testDictionaryConversionDropsUnknownAndMismatchedValues() {
        let container = AttributeContainer([
            OpenUIKit.NSAttributedString.Key("UnknownAttribute"): 7,
            .font: "not a font",
            .underlineStyle: OpenUIKit.NSUnderlineStyle.single.rawValue,
        ])

        XCTAssertNil(container[AttributeScopes.UIKitAttributes.FontAttribute.self])
        XCTAssertEqual(
            container[AttributeScopes.UIKitAttributes.UnderlineStyleAttribute.self],
            OpenUIKit.NSUnderlineStyle.single
        )
    }
}
