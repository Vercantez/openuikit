import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
private final class SizeClassChangeProbeController: UIViewController {
    private(set) var previousTraits: UITraitCollection?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        previousTraits = previousTraitCollection
        super.traitCollectionDidChange(previousTraitCollection)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class RegisteredTraitProbeController: UIViewController {
    var log: [String] = []
    var handlerPrevious: UITraitCollection?
    var handlerCurrent: UITraitCollection?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        log.append("legacy")
        super.traitCollectionDidChange(previousTraitCollection)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class LegacyViewTraitProbe: UIView {
    var log: [String] = []
    var previousTraits: UITraitCollection?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        log.append("legacy")
        previousTraits = previousTraitCollection
    }
}

private enum CustomTraitReusingStyleName: UITraitDefinition {
    static var name: String { UITraitUserInterfaceStyle.name }
}

/// Size-class initializer results and merge precedence were measured against
/// UIKit 26.1 under Mac Catalyst before implementing this portable subset.
#if !os(Linux)
@MainActor
#endif
final class TraitCollectionTests: XCTestCase {
    func testUIViewLegacyTraitCallbackFollowsModernRegistration() {
        let savedCurrent = UITraitCollection.current
        defer { UITraitCollection.current = savedCurrent }
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light,
            displayScale: 2
        )
        let view = LegacyViewTraitProbe()
        let previous = view.traitCollection
        view.registerForTraitChanges(
            [UITraitUserInterfaceStyle.self]
        ) { (target: LegacyViewTraitProbe, _) in
            target.log.append("modern")
        }

        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .dark,
            displayScale: 2
        )
        view._traitsDidChange(previous: previous)

        XCTAssertEqual(view.log, ["modern", "legacy"])
        XCTAssertEqual(view.previousTraits, previous)
        XCTAssertEqual(view.traitCollection.userInterfaceStyle, .dark)
    }

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
        XCTAssertEqual(traits.userInterfaceIdiom, .unspecified)
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
        XCTAssertEqual(category.userInterfaceIdiom, .unspecified)

        let idiom = UITraitCollection(userInterfaceIdiom: .pad)
        XCTAssertEqual(idiom.userInterfaceIdiom, .pad)
        XCTAssertEqual(idiom.userInterfaceStyle, .unspecified)
        XCTAssertEqual(idiom.displayScale, 0)
    }

    func testExistingHostInitializerCanCarryACompleteEnvironment() {
        let traits = UITraitCollection(
            userInterfaceStyle: .dark,
            displayScale: 3,
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            preferredContentSizeCategory: .accessibilityLarge,
            userInterfaceIdiom: .pad
        )
        XCTAssertEqual(traits.userInterfaceStyle, .dark)
        XCTAssertEqual(traits.displayScale, 3)
        XCTAssertEqual(traits.horizontalSizeClass, .regular)
        XCTAssertEqual(traits.verticalSizeClass, .compact)
        XCTAssertEqual(traits.preferredContentSizeCategory, .accessibilityLarge)
        XCTAssertEqual(traits.userInterfaceIdiom, .pad)
    }

    func testTraitsFromMergesEveryModeledTraitAndIgnoresLaterUnspecifiedValues() {
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: .light),
            UITraitCollection(displayScale: 3),
            UITraitCollection(horizontalSizeClass: .regular),
            UITraitCollection(verticalSizeClass: .compact),
            UITraitCollection(preferredContentSizeCategory: .extraLarge),
            UITraitCollection(userInterfaceIdiom: .pad),
            UITraitCollection(userInterfaceStyle: .dark),
            UITraitCollection(horizontalSizeClass: .unspecified),
            UITraitCollection(preferredContentSizeCategory: .unspecified),
            UITraitCollection(userInterfaceIdiom: .unspecified),
        ])

        XCTAssertEqual(traits.userInterfaceStyle, .dark)
        XCTAssertEqual(traits.displayScale, 3)
        XCTAssertEqual(traits.horizontalSizeClass, .regular)
        XCTAssertEqual(traits.verticalSizeClass, .compact)
        XCTAssertEqual(traits.preferredContentSizeCategory, .extraLarge)
        XCTAssertEqual(traits.userInterfaceIdiom, .pad)
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

    /// MEASURED confprobe --ax1, iPhone SE 2x / iOS 26.1: the window's
    /// `traitOverrides.preferredContentSizeCategory` is the environment
    /// descendants see, even when `UITraitCollection.current` is still
    /// `.large`. Same setter realappprobe uses.
    func testWindowTraitOverridesPreferredContentSizeCategory() {
        let savedCurrent = UITraitCollection.current
        defer { UITraitCollection.current = savedCurrent }
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            preferredContentSizeCategory: .large)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.traitOverrides.preferredContentSizeCategory = .accessibilityLarge
        XCTAssertEqual(window.traitCollection.preferredContentSizeCategory,
                       .accessibilityLarge)
        let child = UIView()
        window.addSubview(child)
        XCTAssertEqual(child.traitCollection.preferredContentSizeCategory,
                       .accessibilityLarge)
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

    func testControllerRegistrationDoesNotLoadViewAndOwnerRetainsToken() {
        var controller: RegisteredTraitProbeController? = RegisteredTraitProbeController()
        var registration: UITraitChangeRegistration? = controller?.registerForTraitChanges(
            [UITraitUserInterfaceStyle.self]
        ) { (_: RegisteredTraitProbeController, _: UITraitCollection) in }
        weak var weakRegistration = registration

        XCTAssertFalse(controller!.isViewLoaded)
        XCTAssertNotNil(weakRegistration)
        registration = nil
        XCTAssertNotNil(weakRegistration,
                        "the observable, not the caller, owns its registration")

        controller = nil
        XCTAssertNil(weakRegistration,
                     "controller teardown releases registrations without a cycle")
    }

    func testControllerHostDeliveryFiltersTraitsAndRunsModernBeforeLegacy() {
        let savedCurrent = UITraitCollection.current
        defer { UITraitCollection.current = savedCurrent }
        let previous = UITraitCollection(
            userInterfaceStyle: .light,
            displayScale: 2,
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .dark,
            displayScale: 2,
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )

        let controller = RegisteredTraitProbeController()
        controller.registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
            (target: RegisteredTraitProbeController, prior: UITraitCollection) in
            target.log.append("handler")
            target.handlerPrevious = prior
            target.handlerCurrent = target.traitCollection
        }
        controller.registerForTraitChanges([UITraitHorizontalSizeClass.self]) {
            (target: RegisteredTraitProbeController, _: UITraitCollection) in
            target.log.append("unrelated")
        }
        controller.registerForTraitChanges([]) {
            (target: RegisteredTraitProbeController, _: UITraitCollection) in
            target.log.append("empty")
        }

        XCTAssertEqual(controller.log, [], "registration has no initial delivery")
        controller.loadViewIfNeeded()
        controller.view._traitsDidChange(previous: previous)

        XCTAssertEqual(controller.log, ["handler", "legacy"])
        XCTAssertEqual(controller.handlerPrevious?.userInterfaceStyle, .light)
        XCTAssertEqual(controller.handlerCurrent?.userInterfaceStyle, .dark)
    }

    func testControllerRegistrationSurvivesRootReplacementAndUnregisters() {
        let savedCurrent = UITraitCollection.current
        defer { UITraitCollection.current = savedCurrent }
        let previous = UITraitCollection(userInterfaceStyle: .light)
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark)

        let controller = RegisteredTraitProbeController()
        var fireCount = 0
        var registration: UITraitChangeRegistration? = controller.registerForTraitChanges(
            [UITraitUserInterfaceStyle.self]
        ) { (_: RegisteredTraitProbeController, _: UITraitCollection) in
            fireCount += 1
        }
        weak var weakRegistration = registration

        let oldRoot = UIView()
        controller.view = oldRoot
        let replacementRoot = UIView()
        controller.view = replacementRoot

        oldRoot._traitsDidChange(previous: previous)
        XCTAssertEqual(fireCount, 0,
                       "a replaced root must not deliver controller registrations")
        replacementRoot._traitsDidChange(previous: previous)
        XCTAssertEqual(fireCount, 1)

        controller.unregisterForTraitChanges(registration!)
        registration = nil
        XCTAssertNil(weakRegistration)
        replacementRoot._traitsDidChange(previous: previous)
        XCTAssertEqual(fireCount, 1)
    }

    func testFixedChildStyleDoesNotSpuriouslyFireOnInheritedStyleChange() {
        let savedCurrent = UITraitCollection.current
        defer { UITraitCollection.current = savedCurrent }
        let previous = UITraitCollection(userInterfaceStyle: .light)
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark)

        let parent = UIView()
        let child = UIView()
        child.overrideUserInterfaceStyle = .dark
        parent.addSubview(child)
        var parentCount = 0
        var childCount = 0
        parent.registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
            (_: UIView, _: UITraitCollection) in parentCount += 1
        }
        child.registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
            (_: UIView, _: UITraitCollection) in childCount += 1
        }

        parent._traitsDidChange(previous: previous)

        XCTAssertEqual(parentCount, 1)
        XCTAssertEqual(childCount, 0,
                       "the child was dark both before and after inheritance changed")
    }

    func testViewRegistrationsSuppressSameAndUnrelatedTraitEvents() {
        let savedCurrent = UITraitCollection.current
        defer { UITraitCollection.current = savedCurrent }
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .dark,
            displayScale: 2,
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )
        let view = UIView()
        var styleCount = 0
        var horizontalCount = 0
        view.registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
            (_: UIView, _: UITraitCollection) in styleCount += 1
        }
        view.registerForTraitChanges([UITraitHorizontalSizeClass.self]) {
            (_: UIView, _: UITraitCollection) in horizontalCount += 1
        }

        view._traitsDidChange(previous: view.traitCollection)
        XCTAssertEqual(styleCount, 0)
        XCTAssertEqual(horizontalCount, 0)

        var previous = view.traitCollection
        previous.userInterfaceStyle = .light
        view._traitsDidChange(previous: previous)
        XCTAssertEqual(styleCount, 1)
        XCTAssertEqual(horizontalCount, 0)
    }

    func testFixedChildControllerRootUsesItsOwnPreviousEffectiveStyle() {
        let savedCurrent = UITraitCollection.current
        defer { UITraitCollection.current = savedCurrent }
        let previous = UITraitCollection(userInterfaceStyle: .light)
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark)

        let parent = UIViewController()
        let child = UIViewController()
        parent.addChild(child)
        child.view.overrideUserInterfaceStyle = .dark
        parent.view.addSubview(child.view)
        child.didMove(toParent: parent)
        var handlerCount = 0
        child.registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
            (_: UIViewController, _: UITraitCollection) in handlerCount += 1
        }

        parent.view._traitsDidChange(previous: previous)

        XCTAssertEqual(handlerCount, 0)
    }

    func testCustomTraitCannotMasqueradeAsBuiltinByReusingItsName() {
        let controller = UIViewController()
        controller.loadViewIfNeeded()
        var handlerCount = 0
        controller.registerForTraitChanges([CustomTraitReusingStyleName.self]) {
            (_: UIViewController, _: UITraitCollection) in handlerCount += 1
        }

        let unchanged = controller.traitCollection
        controller.view._traitsDidChange(previous: unchanged)

        XCTAssertEqual(handlerCount, 1,
                       "unknown custom traits conservatively fire on explicit host events")
    }
}
