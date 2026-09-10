// Members the ios-oss (Kickstarter) route-(b) chain census asked for and the
// iPhone 16 / iOS 26.1 probe measured (docs/agent_reports/ios-oss-launch.md,
// "Oracle values"). Every expected value below is a probe line, not a guess.
import XCTest
import Foundation
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class IosOssLaunchMembersTests: XCTestCase {

    // decel.normal=0.998 decel.fast=0.99 decel.default=0.998
    func testScrollViewDecelerationRateTypedEnum() {
        XCTAssertEqual(UIScrollView.DecelerationRate.normal.rawValue, 0.998, accuracy: 1e-12)
        XCTAssertEqual(UIScrollView.DecelerationRate.fast.rawValue, 0.99, accuracy: 1e-12)
        let scroll = UIScrollView(frame: .zero)
        XCTAssertEqual(scroll.decelerationRate, .normal)
        scroll.decelerationRate = .fast
        XCTAssertEqual(scroll.decelerationRate.rawValue, 0.99, accuracy: 1e-12)
        scroll.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0.5)
        XCTAssertEqual(scroll.decelerationRate.rawValue, 0.5, accuracy: 1e-12)
        // the physics constant the struct is built from is unchanged
        XCTAssertEqual(UIScrollPhysics.decelerationRateNormal, 0.998, accuracy: 1e-12)
    }

    // textfield.borderStyle.raws=[0, 1, 2, 3] textfield.borderStyle.default=0
    func testTextFieldBorderStyleNestedNameAndRawValues() {
        XCTAssertEqual([UITextField.BorderStyle.none, .line, .bezel, .roundedRect].map { $0.rawValue },
                       Array(0...3))
        let field = UITextField()
        XCTAssertEqual(field.borderStyle, .none)
        field.borderStyle = UITextField.BorderStyle.roundedRect
        XCTAssertEqual(field.borderStyle, UITextFieldBorderStyle.roundedRect)
    }

    // spellChecking.raws=[0, 1, 2] textfield.spellChecking.default=0
    func testSpellCheckingTypeRawValuesAndDefault() {
        XCTAssertEqual([UITextSpellCheckingType.default, .no, .yes].map { $0.rawValue }, Array(0...2))
        XCTAssertEqual(UITextField().spellCheckingType, .default)
        XCTAssertEqual(UITextView().spellCheckingType, .default)
        let field = UITextField()
        field.spellCheckingType = .no
        XCTAssertEqual(field.spellCheckingType.rawValue, 1)
    }

    // navStyle.raws=[0, 1, 2] view.navStyle.default=0
    func testAccessibilityNavigationStyleRawValuesAndDefault() {
        XCTAssertEqual([UIAccessibilityNavigationStyle.automatic, .separate, .combined].map { $0.rawValue },
                       Array(0...2))
        let view = UIView()
        XCTAssertEqual(view.accessibilityNavigationStyle, .automatic)
        view.accessibilityNavigationStyle = .combined
        XCTAssertEqual(view.accessibilityNavigationStyle, .combined)
        XCTAssertEqual(UIViewController().accessibilityNavigationStyle, .automatic)
    }

    // textfield.textColor=<... labelColor> textfield.textColor.isNil=false
    // textfield.textColor.afterNil=<... labelColor>
    func testTextFieldTextColorIsNullableButNeverReadsNil() {
        let field = UITextField()
        XCTAssertEqual(field.textColor, UIColor.label)
        field.textColor = .red
        XCTAssertEqual(field.textColor, UIColor.red)
        field.textColor = nil
        XCTAssertNotNil(field.textColor)
        XCTAssertEqual(field.textColor, UIColor.label)
        // the nullable spelling type-checks the way UIKit's does
        let optional: UIColor? = field.textColor
        XCTAssertNotNil(optional)
    }
}
