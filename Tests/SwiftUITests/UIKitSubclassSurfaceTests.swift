// This target imports OpenUIKit normally (not @testable), so these subclasses
// prove that UIKit's app-overridable legacy button and semantic-direction
// members remain open to downstream application modules.

import XCTest
import OpenUIKit

@MainActor
private final class SemanticOverrideView: UIView {
    override var semanticContentAttribute: UISemanticContentAttribute {
        get { super.semanticContentAttribute }
        set { super.semanticContentAttribute = newValue }
    }

    override class func userInterfaceLayoutDirection(
        for semanticContentAttribute: UISemanticContentAttribute
    ) -> UIUserInterfaceLayoutDirection {
        super.userInterfaceLayoutDirection(for: semanticContentAttribute)
    }

    override class func userInterfaceLayoutDirection(
        for semanticContentAttribute: UISemanticContentAttribute,
        relativeTo layoutDirection: UIUserInterfaceLayoutDirection
    ) -> UIUserInterfaceLayoutDirection {
        super.userInterfaceLayoutDirection(for: semanticContentAttribute,
                                           relativeTo: layoutDirection)
    }

    override var effectiveUserInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        super.effectiveUserInterfaceLayoutDirection
    }
}

@MainActor
private final class AlignmentOverrideControl: UIControl {
    override var effectiveContentHorizontalAlignment: ContentHorizontalAlignment {
        super.effectiveContentHorizontalAlignment
    }
}

@MainActor
private final class LegacyOverrideButton: UIButton {
    override var contentEdgeInsets: UIEdgeInsets {
        get { super.contentEdgeInsets }
        set { super.contentEdgeInsets = newValue }
    }
    override var titleEdgeInsets: UIEdgeInsets {
        get { super.titleEdgeInsets }
        set { super.titleEdgeInsets = newValue }
    }
    override var imageEdgeInsets: UIEdgeInsets {
        get { super.imageEdgeInsets }
        set { super.imageEdgeInsets = newValue }
    }

    override func setAttributedTitle(_ title: OpenUIKit.NSAttributedString?, for state: State) {
        super.setAttributedTitle(title, for: state)
    }

    override func attributedTitle(for state: State) -> OpenUIKit.NSAttributedString? {
        super.attributedTitle(for: state)
    }

    override var currentAttributedTitle: OpenUIKit.NSAttributedString? {
        super.currentAttributedTitle
    }
}

@MainActor
final class UIKitSubclassSurfaceTests: XCTestCase {
    func testNormallyImportedMembersRemainOverridable() {
        let view = SemanticOverrideView()
        view.semanticContentAttribute = .forceRightToLeft
        XCTAssertEqual(view.effectiveUserInterfaceLayoutDirection, .rightToLeft)

        let control = AlignmentOverrideControl()
        control.contentHorizontalAlignment = .leading
        XCTAssertEqual(control.effectiveContentHorizontalAlignment, .left)

        let button = LegacyOverrideButton(type: .system)
        button.contentEdgeInsets = UIEdgeInsets(top: 1, left: 2,
                                               bottom: 3, right: 4)
        button.setAttributedTitle(OpenUIKit.NSAttributedString(string: "Open"),
                                  for: .normal)
        XCTAssertEqual(button.currentAttributedTitle?.string, "Open")
    }
}
