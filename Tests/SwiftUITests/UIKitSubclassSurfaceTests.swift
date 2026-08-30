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

/// UIKit's registered cell initializer is an ordinary override. Keeping these
/// declarations in a normally importing target catches both a public
/// `required` regression and any internal constructor leaking through
/// inheritance into application subclasses.
@MainActor
private class OrdinaryInitializerCollectionCell: UICollectionViewCell {
    static var initializerEvents: [String] = []
    let initializerMarker: Int

    override init(frame: CGRect) {
        initializerMarker = 37
        OrdinaryInitializerCollectionCell.initializerEvents.append("before-super")
        super.init(frame: frame)
        OrdinaryInitializerCollectionCell.initializerEvents.append(
            contentView.superview === self ? "after-super-content" : "after-super-missing"
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not archive-backed")
    }
}

/// A leaf with no initializer must inherit the ordinary override and remain
/// dynamically constructible when its own metatype is registered.
@MainActor
private final class InheritedInitializerCollectionCell:
    OrdinaryInitializerCollectionCell {}

/// Adding an unrelated designated initializer is valid UIKit source. It must
/// not acquire an unnameable required constructor from OpenUIKit internals.
@MainActor
private final class ExtraDesignatedCollectionCell: UICollectionViewCell {
    let token: Int

    init(token: Int) {
        self.token = token
        super.init(frame: CGRect(x: 1, y: 2, width: 3, height: 4))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not archive-backed")
    }
}

@MainActor
private class OrdinaryInitializerSupplementaryView: UICollectionReusableView {
    static var initializerCalls = 0
    let initializerMarker: Int

    override init(frame: CGRect) {
        initializerMarker = 73
        OrdinaryInitializerSupplementaryView.initializerCalls += 1
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not archive-backed")
    }
}

@MainActor
private final class InheritedInitializerSupplementaryView:
    OrdinaryInitializerSupplementaryView {}

@MainActor
private final class ExtraDesignatedSupplementaryView: UICollectionReusableView {
    let token: Int

    init(token: Int) {
        self.token = token
        super.init(frame: CGRect(x: 4, y: 3, width: 2, height: 1))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not archive-backed")
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

    func testRegisteredCollectionCellCallsOrdinaryFrameOverrideOnce() {
        OrdinaryInitializerCollectionCell.initializerEvents = []
        let collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: 100, height: 100),
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        collectionView.register(
            OrdinaryInitializerCollectionCell.self,
            forCellWithReuseIdentifier: "ordinary"
        )

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ordinary",
            for: IndexPath(item: 0, section: 0)
        )

        XCTAssertEqual(
            (cell as? OrdinaryInitializerCollectionCell)?.initializerMarker,
            37
        )
        XCTAssertEqual(
            OrdinaryInitializerCollectionCell.initializerEvents,
            ["before-super", "after-super-content"]
        )
        XCTAssertEqual(cell.subviews.filter { $0 === cell.contentView }.count, 1)
    }

    func testRegisteredInheritedLeafDispatchesToMostDerivedFrameOverride() {
        OrdinaryInitializerCollectionCell.initializerEvents = []
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        collectionView.register(
            InheritedInitializerCollectionCell.self,
            forCellWithReuseIdentifier: "leaf"
        )

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "leaf",
            for: IndexPath(item: 0, section: 0)
        )

        XCTAssertTrue(cell is InheritedInitializerCollectionCell)
        XCTAssertEqual(
            OrdinaryInitializerCollectionCell.initializerEvents,
            ["before-super", "after-super-content"]
        )
        XCTAssertEqual(cell.subviews.filter { $0 === cell.contentView }.count, 1)
    }

    func testRegisteredSupplementaryInheritedLeafUsesOrdinaryOverride() {
        OrdinaryInitializerSupplementaryView.initializerCalls = 0
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        collectionView.register(
            InheritedInitializerSupplementaryView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "leaf-supplementary"
        )

        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "leaf-supplementary",
            for: IndexPath(item: 0, section: 0)
        )

        XCTAssertTrue(view is InheritedInitializerSupplementaryView)
        XCTAssertEqual(
            (view as? OrdinaryInitializerSupplementaryView)?.initializerMarker,
            73
        )
        XCTAssertEqual(OrdinaryInitializerSupplementaryView.initializerCalls, 1)
    }

    func testUnrelatedDesignatedInitializersHaveNoHiddenRequirement() {
        XCTAssertEqual(ExtraDesignatedCollectionCell(token: 41).token, 41)
        XCTAssertEqual(ExtraDesignatedSupplementaryView(token: 42).token, 42)
    }
}
