import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
private final class SplitObserver: UISplitViewControllerDelegate {
    var calls: [String] = []
    var handles = true
    func splitViewController(_ svc: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool {
        calls.append("show"); return handles
    }
    func splitViewController(_ svc: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        calls.append("detail"); return handles
    }
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        calls.append("mode\(displayMode.rawValue)")
    }
    func splitViewControllerDidCollapse(_ svc: UISplitViewController) { calls.append("collapse") }
}

#if !os(Linux)
@MainActor
#endif
final class UISplitViewControllerTests: XCTestCase {
    // All assertions below name rows in Tools/oracle2/splitviewprobe/ios26.1-*.txt.
    func testEnumRawValuesMatchOracle() {
        XCTAssertEqual([UISplitViewController.Style.unspecified, .doubleColumn, .tripleColumn].map(\.rawValue), [0, 1, 2])
        XCTAssertEqual([UISplitViewController.DisplayMode.automatic, .secondaryOnly, .oneBesideSecondary, .oneOverSecondary, .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary].map(\.rawValue), [0, 1, 2, 3, 4, 5, 6])
        XCTAssertEqual([UISplitViewController.Column.primary, .supplementary, .secondary, .compact, .inspector].map(\.rawValue), [0, 1, 2, 3, 4])
        XCTAssertEqual([UISplitViewController.SplitBehavior.automatic, .tile, .overlay, .displace].map(\.rawValue), [0, 1, 2, 3])
        XCTAssertEqual([UISplitViewController.PrimaryEdge.leading, .trailing].map(\.rawValue), [0, 1])
        XCTAssertEqual([UISplitViewController.BackgroundStyle.none, .sidebar].map(\.rawValue), [0, 1])
        XCTAssertEqual([UISplitViewController.DisplayModeButtonVisibility.automatic, .never, .always].map(\.rawValue), [0, 1, 2])
        XCTAssertEqual(UISplitViewController.DisplayMode.primaryHidden, .secondaryOnly)
        XCTAssertEqual(UISplitViewController.DisplayMode.allVisible, .oneBesideSecondary)
        XCTAssertEqual(UISplitViewController.DisplayMode.primaryOverlay, .oneOverSecondary)
    }

    func testFreshLegacyDefaultsRemainLazy() {
        let split = UISplitViewController()
        XCTAssertEqual(split.style, .unspecified)
        XCTAssertFalse(split.isViewLoaded)
        XCTAssertFalse(split.isCollapsed)
        XCTAssertEqual(split.displayMode, .secondaryOnly)
        XCTAssertEqual(split.preferredDisplayMode, .automatic)
        XCTAssertEqual(split.primaryColumnWidth, 320)
        XCTAssertTrue(split.presentsWithGesture)
        XCTAssertEqual(split.primaryEdge, .leading)
        XCTAssertEqual(split.primaryBackgroundStyle, .sidebar)
        XCTAssertTrue(split.viewControllers.isEmpty)
        XCTAssertTrue(split.children.isEmpty)
        XCTAssertNil(split.delegate)
    }

    func testColumnStyleDefaults() {
        for style in [UISplitViewController.Style.doubleColumn, .tripleColumn] {
            let split = UISplitViewController(style: style)
            XCTAssertEqual(split.style, style)
            XCTAssertEqual(split.splitBehavior, .tile)
            XCTAssertEqual(split.preferredSplitBehavior, .automatic)
            XCTAssertFalse(split.showsSecondaryOnlyButton)
            XCTAssertEqual(split.displayModeButtonVisibility, .automatic)
            XCTAssertEqual(split.primaryColumnWidth, style == .tripleColumn ? 280 : 320)
            if style == .tripleColumn { XCTAssertEqual(split.supplementaryColumnWidth, 320) }
            XCTAssertFalse(split.isViewLoaded)
        }
    }

    func testEverySizingPreferenceUsesFloatAutomaticSentinel() {
        let split = UISplitViewController(style: .tripleColumn)
        XCTAssertEqual(UISplitViewController.automaticDimension, -3.4028234663852886e38)
        let preferences: [KeyPath<UISplitViewController, CGFloat>] = [
            \.preferredPrimaryColumnWidthFraction, \.preferredPrimaryColumnWidth,
            \.minimumPrimaryColumnWidth, \.maximumPrimaryColumnWidth,
            \.preferredSupplementaryColumnWidthFraction, \.preferredSupplementaryColumnWidth,
            \.minimumSupplementaryColumnWidth, \.maximumSupplementaryColumnWidth,
            \.preferredSecondaryColumnWidthFraction, \.preferredSecondaryColumnWidth,
            \.minimumSecondaryColumnWidth, \.preferredInspectorColumnWidthFraction,
            \.preferredInspectorColumnWidth, \.minimumInspectorColumnWidth,
            \.maximumInspectorColumnWidth,
        ]
        for preference in preferences { XCTAssertEqual(split[keyPath: preference], UISplitViewController.automaticDimension) }
        XCTAssertFalse(split.isViewLoaded)
    }

    func testWidthConfigurationDoesNotLoadOrChangeCurrentWidth() {
        let split = UISplitViewController(style: .doubleColumn)
        split.preferredPrimaryColumnWidth = 280
        split.preferredPrimaryColumnWidthFraction = 0.4
        split.minimumPrimaryColumnWidth = 200
        split.maximumPrimaryColumnWidth = 420
        XCTAssertEqual(split.preferredPrimaryColumnWidth, 280)
        XCTAssertEqual(split.preferredPrimaryColumnWidthFraction, 0.4)
        XCTAssertEqual(split.minimumPrimaryColumnWidth, 200)
        XCTAssertEqual(split.maximumPrimaryColumnWidth, 420)
        XCTAssertEqual(split.primaryColumnWidth, 320)
        XCTAssertFalse(split.isViewLoaded)
    }

    func testLegacyArrayAssignmentIsLazyAndRemovesSlots() {
        let split = UISplitViewController(), primary = UIViewController(), secondary = UIViewController()
        split.viewControllers = [primary, secondary]
        split.viewControllers = [primary, secondary]
        XCTAssertEqual(split.viewControllers.count, 2)
        XCTAssertTrue(split.children.isEmpty)
        XCTAssertNil(primary.parent)
        XCTAssertNil(secondary.parent)
        split.viewControllers = [primary]
        XCTAssertTrue(split.viewControllers.first === primary)
        split.viewControllers = []
        XCTAssertTrue(split.viewControllers.isEmpty)
        XCTAssertFalse(split.isViewLoaded)
    }

    func testColumnStorageReturnsOriginalControllersAndExcludesCompactFromArray() {
        let split = UISplitViewController(style: .tripleColumn)
        let primary = UIViewController(), supplementary = UIViewController(), secondary = UIViewController(), compact = UIViewController()
        split.setViewController(primary, for: .primary)
        split.setViewController(secondary, for: .secondary)
        split.setViewController(supplementary, for: .supplementary)
        split.setViewController(compact, for: .compact)
        XCTAssertTrue(split.viewController(for: .primary) === primary)
        XCTAssertTrue(split.viewController(for: .supplementary) === supplementary)
        XCTAssertTrue(split.viewController(for: .secondary) === secondary)
        XCTAssertTrue(split.viewController(for: .compact) === compact)
        XCTAssertNil(split.viewController(for: .inspector))
        XCTAssertEqual(split.viewControllers.count, 3)
        XCTAssertTrue(split.viewControllers[1] === supplementary)
        XCTAssertTrue(split.children.isEmpty)
        for column in [UISplitViewController.Column.primary, .supplementary, .secondary, .compact, .inspector] { XCTAssertFalse(split.isShowing(column)) }
        split.setViewController(nil, for: .secondary)
        XCTAssertNil(split.viewController(for: .secondary))
        XCTAssertEqual(split.viewControllers.count, 2)
        split.setViewController(nil, for: .compact)
        XCTAssertNil(split.viewController(for: .compact))
    }

    func testSplitAncestorWalkExcludesSelfAndUncontainedControllers() {
        let split = UISplitViewController(style: .doubleColumn), child = UIViewController()
        split.setViewController(child, for: .primary)
        XCTAssertNil(child.splitViewController)
        XCTAssertNil(split.splitViewController)
        let nav = UINavigationController(rootViewController: child)
        split.addChild(nav)
        XCTAssertTrue(child.splitViewController === split)
        XCTAssertTrue(nav.splitViewController === split)
    }

    func testLegacyShowDelegateCanHandleWithoutLoading() {
        let split = UISplitViewController(), observer = SplitObserver()
        split.delegate = observer
        split.show(UIViewController(), sender: nil)
        split.showDetailViewController(UIViewController(), sender: nil)
        XCTAssertEqual(observer.calls, ["show", "detail"])
        XCTAssertFalse(split.isViewLoaded)
        XCTAssertTrue(split.viewControllers.isEmpty)
    }

    func testColumnShowBypassesLegacyDelegateAndReplacesSecondary() {
        let split = UISplitViewController(style: .doubleColumn), observer = SplitObserver()
        let primary = UIViewController(), detail = UIViewController()
        split.delegate = observer
        split.setViewController(primary, for: .primary)
        split.show(UIViewController(), sender: nil)
        split.showDetailViewController(detail, sender: nil)
        XCTAssertTrue(observer.calls.isEmpty)
        XCTAssertTrue(split.isViewLoaded)
        XCTAssertTrue(split.children.isEmpty)
        XCTAssertTrue(split.viewController(for: .primary) === primary)
        XCTAssertTrue(split.viewController(for: .secondary) === detail)
    }

    func testChildShowDetailForwardsToSplitDelegate() {
        let split = UISplitViewController(), child = UIViewController(), observer = SplitObserver()
        split.delegate = observer
        split.addChild(child)
        child.showDetailViewController(UIViewController(), sender: nil)
        XCTAssertEqual(observer.calls, ["detail"])
    }

    func testDelegateIsWeak() {
        let split = UISplitViewController()
        var observer: SplitObserver? = SplitObserver()
        split.delegate = observer
        observer = nil
        XCTAssertNil(split.delegate)
    }

    private func mount(_ split: UISplitViewController, width: CGFloat, height: CGFloat, compact: Bool) -> UIWindow {
        UITraitCollection.current = UITraitCollection(horizontalSizeClass: compact ? .compact : .regular)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = split
        split.beginAppearanceTransition(true, animated: false)
        split.endAppearanceTransition()
        window.layoutIfNeeded()
        return window
    }

    func testExpandedLegacyContainsOriginalChildren() {
        let previous = UITraitCollection.current
        defer { UITraitCollection.current = previous }
        let split = UISplitViewController(), a = UIViewController(), b = UIViewController()
        split.viewControllers = [a, b]
        let window = mount(split, width: 820, height: 1180, compact: false)
        XCTAssertEqual(split.displayMode, .oneBesideSecondary)
        XCTAssertFalse(split.isCollapsed)
        XCTAssertTrue(a.parent === split)
        XCTAssertTrue(b.parent === split)
        XCTAssertEqual(split.children.count, 2)
        withExtendedLifetime(window) {}
    }

    func testExpandedColumnStyleWrapsPlainChildrenOnAppearance() {
        let previous = UITraitCollection.current
        defer { UITraitCollection.current = previous }
        let split = UISplitViewController(style: .doubleColumn), a = UIViewController(), b = UIViewController()
        split.setViewController(a, for: .primary)
        split.setViewController(b, for: .secondary)
        split.loadViewIfNeeded()
        XCTAssertTrue(split.children.isEmpty)
        let window = mount(split, width: 820, height: 1180, compact: false)
        XCTAssertEqual(split.children.count, 2)
        XCTAssertTrue(a.parent is UINavigationController)
        XCTAssertTrue(a.parent?.parent === split)
        XCTAssertTrue(a.splitViewController === split)
        XCTAssertTrue(split.viewController(for: .primary) === a)
        XCTAssertTrue(split.isShowing(.primary))
        XCTAssertTrue(split.isShowing(.secondary))
        withExtendedLifetime(window) {}
    }

    func testMountedPrimaryWidthUsesMeasuredAbsoluteAndFraction() {
        let previous = UITraitCollection.current
        defer { UITraitCollection.current = previous }
        let split = UISplitViewController(style: .doubleColumn)
        let window = mount(split, width: 820, height: 1180, compact: false)
        split.preferredPrimaryColumnWidthFraction = 0.4
        split.preferredPrimaryColumnWidth = 280
        XCTAssertEqual(split.primaryColumnWidth, 280)
        split.preferredPrimaryColumnWidth = UISplitViewController.automaticDimension
        XCTAssertEqual(split.primaryColumnWidth, 328)
        split.minimumPrimaryColumnWidth = 400
        split.maximumPrimaryColumnWidth = 500
        XCTAssertEqual(split.primaryColumnWidth, 400)
        split.minimumPrimaryColumnWidth = UISplitViewController.automaticDimension
        split.maximumPrimaryColumnWidth = 300
        XCTAssertEqual(split.primaryColumnWidth, 300)
        withExtendedLifetime(window) {}
    }

    func testPhoneLegacyCollapsesPublicArrayAndUsesWindowWidth() {
        let previous = UITraitCollection.current
        defer { UITraitCollection.current = previous }
        let split = UISplitViewController(), a = UIViewController(), b = UIViewController(), observer = SplitObserver()
        split.delegate = observer
        split.viewControllers = [a, b]
        let window = mount(split, width: 375, height: 667, compact: true)
        XCTAssertTrue(split.isCollapsed)
        XCTAssertEqual(split.displayMode, .oneBesideSecondary)
        XCTAssertEqual(split.primaryColumnWidth, 375)
        XCTAssertEqual(split.viewControllers.count, 1)
        XCTAssertTrue(split.viewControllers.first === a)
        XCTAssertNil(b.parent)
        XCTAssertTrue(observer.calls.contains("collapse"))
        withExtendedLifetime(window) {}
    }

    func testPhoneColumnStyleNestsSecondaryNavigationAndShowPrimaryPopsIt() {
        let previous = UITraitCollection.current
        defer { UITraitCollection.current = previous }
        let split = UISplitViewController(style: .tripleColumn)
        let a = UIViewController(), s = UIViewController(), b = UIViewController()
        split.setViewController(a, for: .primary)
        split.setViewController(s, for: .supplementary)
        split.setViewController(b, for: .secondary)
        let window = mount(split, width: 375, height: 667, compact: true)
        let nav = split.children.first as? UINavigationController
        XCTAssertEqual(split.children.count, 1)
        XCTAssertEqual(nav?.viewControllers.count, 3)
        XCTAssertTrue(nav?.topViewController === b.parent)
        XCTAssertTrue(split.viewController(for: .secondary) === b)
        XCTAssertEqual(split.primaryColumnWidth, 375)
        XCTAssertEqual(split.supplementaryColumnWidth, 375)
        XCTAssertFalse(split.isShowing(.primary))
        XCTAssertTrue(split.isShowing(.secondary))
        split.hide(.primary)
        XCTAssertTrue(split.isShowing(.secondary))
        split.show(.primary)
        XCTAssertEqual(nav?.viewControllers.count, 1)
        XCTAssertTrue(split.isShowing(.primary))
        XCTAssertFalse(split.isShowing(.secondary))
        withExtendedLifetime(window) {}
    }

    func testPhoneDisplayModeSweepRetainsModeTwoAndChangesPreferredBehavior() {
        let previous = UITraitCollection.current
        defer { UITraitCollection.current = previous }
        let split = UISplitViewController(style: .tripleColumn)
        let window = mount(split, width: 375, height: 667, compact: true)
        for (mode, behavior) in [(UISplitViewController.DisplayMode.secondaryOnly, UISplitViewController.SplitBehavior.tile), (.oneBesideSecondary, .tile), (.oneOverSecondary, .overlay), (.twoBesideSecondary, .tile), (.twoOverSecondary, .overlay), (.twoDisplaceSecondary, .displace)] {
            split.preferredDisplayMode = mode
            XCTAssertEqual(split.preferredDisplayMode, mode)
            XCTAssertEqual(split.preferredSplitBehavior, behavior)
            XCTAssertEqual(split.displayMode, .oneBesideSecondary)
            XCTAssertEqual(split.splitBehavior, .tile)
        }
        withExtendedLifetime(window) {}
    }
}
