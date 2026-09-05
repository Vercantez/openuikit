// Literal downstream-module gate for the low-risk Reminder tail slice. This
// file intentionally imports public `UIKit`, never `@testable OpenUIKit`.

import XCTest
import UIKit

#if canImport(ObjectiveC)
import struct Foundation.Data
#endif

#if !os(Linux)
@MainActor
#endif
private final class ReminderTraitRegistrationProbe: UIViewController {
    var observedPrevious: UITraitCollection?

    // Exact closure annotation used by unchanged Reminder source.
    func installTraitHandler() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
            (self: Self, previousTraitCollection: UITraitCollection) in
            self.observedPrevious = previousTraitCollection
        }
    }
}

#if !os(Linux)
@MainActor
#endif
private final class ReminderTextViewOverrideProbe: UITextView {
    var assignmentCount = 0

    override var text: String! {
        didSet { assignmentCount += 1 }
    }
}

#if !os(Linux)
@MainActor
#endif
private final class ReminderOptionalTextViewOverrideProbe: UITextView {
    override var text: String? {
        get { super.text }
        set { super.text = newValue }
    }
}

#if !os(Linux)
@MainActor
#endif
final class ReminderTailSourceCompatibilityTests: XCTestCase {
    private func nonemptyReminderText(from textView: UITextView) -> String? {
        // Exact optional-binding shape that a native null-resettable
        // UITextView.text import permits.
        guard let text = textView.text, !text.isEmpty else { return nil }
        return text
    }

    func testControllerHandlerClosureCompilesThroughLiteralUIKit() {
        let savedCurrent = UITraitCollection.current
        defer { UITraitCollection.current = savedCurrent }

        let previous = UITraitCollection(userInterfaceStyle: .light)
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark)

        let controller = ReminderTraitRegistrationProbe()
        controller.installTraitHandler()
        XCTAssertFalse(controller.isViewLoaded,
                       "registration itself must not force a view load")
        controller.loadViewIfNeeded()
        controller.view._traitsDidChange(previous: previous)
        XCTAssertEqual(controller.observedPrevious?.userInterfaceStyle, .light)
    }

    func testTextIsExternallyOverridableIUOAndSupportsOptionalBinding() {
        let textView = ReminderTextViewOverrideProbe()
        XCTAssertNil(nonemptyReminderText(from: textView))

        textView.text = "Buy milk"
        XCTAssertEqual(nonemptyReminderText(from: textView), "Buy milk")

        textView.text = nil
        XCTAssertEqual(textView.text, "")
        XCTAssertNil(nonemptyReminderText(from: textView))
        XCTAssertEqual(textView.assignmentCount, 2)
    }

    func testTextAlsoAcceptsNativeOptionalOverrideSpelling() {
        let textView = ReminderOptionalTextViewOverrideProbe()
        textView.text = "optional override"
        XCTAssertEqual(textView.text, "optional override")
        textView.text = nil
        XCTAssertEqual(textView.text, "")
    }

#if canImport(ObjectiveC)
    func testEndEditingSelectorCompilesThroughLiteralUIKit() {
        XCTAssertEqual(#selector(UIView.endEditing).actionName, "endEditing:")
    }
#endif
}
