import XCTest
@testable import OpenUIKit

@MainActor
private final class SizeClassChangeProbeController: UIViewController {
    private(set) var previousTraits: UITraitCollection?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        previousTraits = previousTraitCollection
        super.traitCollectionDidChange(previousTraitCollection)
    }
}

/// Size-class initializer results and merge precedence were measured against
/// UIKit 26.1 under Mac Catalyst before implementing this portable subset.
@MainActor
final class TraitCollectionTests: XCTestCase {
    func testSizeClassRawValuesAndEmptyCollectionMatchUIKit() {
        XCTAssertEqual(UIUserInterfaceSizeClass.unspecified.rawValue, 0)
        XCTAssertEqual(UIUserInterfaceSizeClass.compact.rawValue, 1)
        XCTAssertEqual(UIUserInterfaceSizeClass.regular.rawValue, 2)

        let traits = UITraitCollection()
        XCTAssertEqual(traits.userInterfaceStyle, .unspecified)
        XCTAssertEqual(traits.displayScale, 0)
        XCTAssertEqual(traits.horizontalSizeClass, .unspecified)
        XCTAssertEqual(traits.verticalSizeClass, .unspecified)
        XCTAssertEqual(traits.preferredContentSizeCategory, .unspecified)
    }

    func testSpecializedInitializersCreatePartialCollections() {
        let horizontal = UITraitCollection(horizontalSizeClass: .compact)
        XCTAssertEqual(horizontal.horizontalSizeClass, .compact)
        XCTAssertEqual(horizontal.verticalSizeClass, .unspecified)
        XCTAssertEqual(horizontal.userInterfaceStyle, .unspecified)
        XCTAssertEqual(horizontal.displayScale, 0)
        XCTAssertEqual(horizontal.preferredContentSizeCategory, .unspecified)

        let vertical = UITraitCollection(verticalSizeClass: .regular)
        XCTAssertEqual(vertical.horizontalSizeClass, .unspecified)
        XCTAssertEqual(vertical.verticalSizeClass, .regular)

        let style = UITraitCollection(userInterfaceStyle: .dark)
        XCTAssertEqual(style.userInterfaceStyle, .dark)
        XCTAssertEqual(style.displayScale, 0)
        XCTAssertEqual(style.preferredContentSizeCategory, .unspecified)

        let scale = UITraitCollection(displayScale: 3)
        XCTAssertEqual(scale.displayScale, 3)
        XCTAssertEqual(scale.userInterfaceStyle, .unspecified)

        let category = UITraitCollection(preferredContentSizeCategory: .extraLarge)
        XCTAssertEqual(category.preferredContentSizeCategory, .extraLarge)
        XCTAssertEqual(category.userInterfaceStyle, .unspecified)
        XCTAssertEqual(category.displayScale, 0)
    }

    func testExistingHostInitializerCanCarryACompleteEnvironment() {
        let traits = UITraitCollection(
            userInterfaceStyle: .dark,
            displayScale: 3,
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            preferredContentSizeCategory: .accessibilityLarge
        )
        XCTAssertEqual(traits.userInterfaceStyle, .dark)
        XCTAssertEqual(traits.displayScale, 3)
        XCTAssertEqual(traits.horizontalSizeClass, .regular)
        XCTAssertEqual(traits.verticalSizeClass, .compact)
        XCTAssertEqual(traits.preferredContentSizeCategory, .accessibilityLarge)
    }

    func testTraitsFromMergesEveryModeledTraitAndIgnoresLaterUnspecifiedValues() {
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: .light),
            UITraitCollection(displayScale: 3),
            UITraitCollection(horizontalSizeClass: .regular),
            UITraitCollection(verticalSizeClass: .compact),
            UITraitCollection(preferredContentSizeCategory: .extraLarge),
            UITraitCollection(userInterfaceStyle: .dark),
            UITraitCollection(horizontalSizeClass: .unspecified),
            UITraitCollection(preferredContentSizeCategory: .unspecified),
        ])

        XCTAssertEqual(traits.userInterfaceStyle, .dark)
        XCTAssertEqual(traits.displayScale, 3)
        XCTAssertEqual(traits.horizontalSizeClass, .regular)
        XCTAssertEqual(traits.verticalSizeClass, .compact)
        XCTAssertEqual(traits.preferredContentSizeCategory, .extraLarge)
        XCTAssertEqual(UITraitCollection(traitsFrom: []), UITraitCollection())
    }

    func testWindowDerivesOnlyUnspecifiedAxesAndSubviewsAndControllerInheritThem() {
        let savedCurrent = UITraitCollection.current
        defer { UITraitCollection.current = savedCurrent }
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .dark,
            displayScale: 2,
            horizontalSizeClass: .compact,
            verticalSizeClass: .unspecified,
            preferredContentSizeCategory: .extraLarge
        )

        // UIScreen.main defaults to 390 x 844, so 800 x 500 deliberately
        // disagrees with both screen-derived axes. The explicit horizontal
        // value remains authoritative; vertical comes from the window.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 500))
        XCTAssertEqual(window.traitCollection.horizontalSizeClass, .compact)
        XCTAssertEqual(window.traitCollection.verticalSizeClass, .compact)

        let controller = UIViewController()
        window.rootViewController = controller
        let child = UIView()
        controller.view.addSubview(child)
        XCTAssertEqual(child.traitCollection.horizontalSizeClass, .compact)
        XCTAssertEqual(child.traitCollection.verticalSizeClass, .compact)
        XCTAssertEqual(child.traitCollection.preferredContentSizeCategory, .extraLarge)
        XCTAssertEqual(controller.traitCollection, child.traitCollection)

        window.overrideUserInterfaceStyle = .light
        XCTAssertEqual(child.traitCollection.userInterfaceStyle, .light)
        XCTAssertEqual(child.traitCollection.horizontalSizeClass, .compact)
        XCTAssertEqual(child.traitCollection.verticalSizeClass, .compact)

        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .dark,
            displayScale: 2,
            horizontalSizeClass: .unspecified,
            verticalSizeClass: .regular
        )
        XCTAssertEqual(window.traitCollection.horizontalSizeClass, .regular)
        XCTAssertEqual(window.traitCollection.verticalSizeClass, .regular)
    }

    func testDetachedViewsUseScreenAxesButWindowUsesItsOwnBounds() {
        let screen = UIScreen.main
        let savedBounds = screen.bounds
        let savedScale = screen.scale
        let savedCurrent = UITraitCollection.current
        defer {
            screen._hostConfigure(bounds: savedBounds, scale: savedScale)
            UITraitCollection.current = savedCurrent
        }
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light,
            displayScale: 2,
            horizontalSizeClass: .unspecified,
            verticalSizeClass: .unspecified
        )
        screen._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 900, height: 900),
                              scale: 2)

        let detached = UIView(frame: .zero)
        XCTAssertEqual(detached.traitCollection.horizontalSizeClass, .regular)
        XCTAssertEqual(detached.traitCollection.verticalSizeClass, .regular)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        XCTAssertEqual(window.traitCollection.horizontalSizeClass, .compact)
        XCTAssertEqual(window.traitCollection.verticalSizeClass, .compact)
    }

    func testScreenDerivationPreservesCurrentAndDoesNotMutateIt() {
        let screen = UIScreen.main
        let savedBounds = screen.bounds
        let savedScale = screen.scale
        let savedCurrent = UITraitCollection.current
        defer {
            screen._hostConfigure(bounds: savedBounds, scale: savedScale)
            UITraitCollection.current = savedCurrent
        }
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .dark,
            displayScale: 2,
            horizontalSizeClass: .compact,
            verticalSizeClass: .unspecified,
            preferredContentSizeCategory: .extraLarge
        )
        screen._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 900, height: 500),
                              scale: 3)

        let screenTraits = screen.traitCollection
        XCTAssertEqual(screenTraits.userInterfaceStyle, .dark)
        XCTAssertEqual(screenTraits.displayScale, 3)
        XCTAssertEqual(screenTraits.horizontalSizeClass, .compact)
        XCTAssertEqual(screenTraits.verticalSizeClass, .compact)
        XCTAssertEqual(screenTraits.preferredContentSizeCategory, .extraLarge)

        // Focus reads these values in a UIView initializer and in
        // UIViewController.viewDidLoad, before the objects join a window.
        let detachedView = UIView(frame: .zero)
        let detachedController = UIViewController()
        let detachedTraits = detachedView.traitCollection
        XCTAssertEqual(detachedTraits.userInterfaceStyle, .dark)
        XCTAssertEqual(detachedTraits.displayScale, 2)
        XCTAssertEqual(detachedTraits.horizontalSizeClass, .compact)
        XCTAssertEqual(detachedTraits.verticalSizeClass, .compact)
        XCTAssertEqual(detachedTraits.preferredContentSizeCategory, .extraLarge)
        XCTAssertEqual(detachedController.traitCollection, detachedTraits)
        detachedController.loadViewIfNeeded()
        XCTAssertEqual(detachedController.traitCollection, detachedTraits)

        XCTAssertEqual(UITraitCollection.current.verticalSizeClass, .unspecified)
        XCTAssertEqual(UITraitCollection.current.displayScale, 2)
    }

    func testLegacyTraitCallbackReceivesPreviousSizeClasses() {
        let savedCurrent = UITraitCollection.current
        defer { UITraitCollection.current = savedCurrent }
        let previous = UITraitCollection(
            userInterfaceStyle: .light,
            displayScale: 2,
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light,
            displayScale: 2,
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        )
        let controller = SizeClassChangeProbeController()
        controller.loadViewIfNeeded()
        controller.view._traitsDidChange(previous: previous)

        XCTAssertEqual(controller.previousTraits?.horizontalSizeClass, .compact)
        XCTAssertEqual(controller.previousTraits?.verticalSizeClass, .regular)
        XCTAssertEqual(controller.traitCollection.horizontalSizeClass, .regular)
        XCTAssertEqual(controller.traitCollection.verticalSizeClass, .regular)
    }
}
