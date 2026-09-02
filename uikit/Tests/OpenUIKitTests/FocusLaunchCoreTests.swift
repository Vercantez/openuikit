import XCTest
import Foundation
@testable import OpenUIKit

@MainActor
private final class FocusZoomDelegate: UIScrollViewDelegate {
    let zoomView: UIView
    var began = 0
    var changed = 0
    var ended = 0

    init(_ zoomView: UIView) { self.zoomView = zoomView }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { zoomView }
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        began += 1
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { changed += 1 }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?,
                                 atScale scale: CGFloat) {
        ended += 1
    }
}

@MainActor
final class FocusLaunchCoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OpenUIKitRuntime.animationTime = 0
        UIViewAnimationCompletionQueue.entries.removeAll()
    }

    override func tearDown() {
        UIImpactFeedbackGenerator.onImpact = nil
        UIViewAnimationCompletionQueue.entries.removeAll()
        OpenUIKitRuntime.animationTime = 0
        super.tearDown()
    }

    func testCustomTableAccessoryReplacesGlyphAndReservesContentWidth() {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.frame = CGRect(x: 0, y: 0, width: 320, height: 52)
        cell.accessoryType = .disclosureIndicator
        let custom = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 30))
        cell.accessoryView = custom
        cell.layoutIfNeeded()

        XCTAssertTrue(custom.superview === cell)
        XCTAssertEqual(custom.frame.maxX, 304)
        XCTAssertEqual(custom.frame.midY, 26, accuracy: 0.5)
        XCTAssertTrue(cell._accessoryGlyphView.isHidden)
        XCTAssertEqual(cell.contentView.frame.width, 248)

        cell.accessoryView = nil
        cell.layoutIfNeeded()
        XCTAssertNil(custom.superview)
        XCTAssertFalse(cell._accessoryGlyphView.isHidden)
        XCTAssertEqual(cell.accessoryType, .disclosureIndicator)
    }

    func testSnapshotMaintainsSectionAndItemOrderAcrossMutations() {
        var snapshot = OpenUIKit.NSDiffableDataSourceSnapshot<String, Int>()
        snapshot.appendSections(["middle"])
        snapshot.insertSections(["first"], beforeSection: "middle")
        snapshot.insertSections(["last"], afterSection: "middle")
        snapshot.appendItems([3, 4], toSection: "middle")
        snapshot.appendItems([1], toSection: "first")
        snapshot.insertItems([2], afterItem: 1)
        snapshot.appendItems([5], toSection: "last")
        snapshot.moveItem(4, beforeItem: 2)

        XCTAssertEqual(snapshot.sectionIdentifiers, ["first", "middle", "last"])
        XCTAssertEqual(snapshot.itemIdentifiers, [1, 4, 2, 3, 5])
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: "first"), [1, 4, 2])
        XCTAssertEqual(snapshot.sectionIdentifier(containingItem: 4), "first")

        snapshot.deleteItems([3])
        snapshot.deleteSections(["last"])
        snapshot.moveSection("middle", beforeSection: "first")
        XCTAssertEqual(snapshot.sectionIdentifiers, ["middle", "first"])
        XCTAssertEqual(snapshot.itemIdentifiers, [1, 4, 2])
    }

    func testDiffableApplyPreservesMovedCellAndReloadReinvokesProvider() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 500))
        let table = UITableView(frame: window.bounds, style: .plain)
        window.addSubview(table)
        var providerCalls: [Int] = []
        let dataSource = UITableViewDiffableDataSource<String, Int>(tableView: table) {
            _, _, item in
            providerCalls.append(item)
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel.text = "\(item)"
            return cell
        }

        var first = OpenUIKit.NSDiffableDataSourceSnapshot<String, Int>()
        first.appendSections(["a", "b"])
        first.appendItems([1, 2], toSection: "a")
        first.appendItems([3], toSection: "b")
        dataSource.apply(first, animatingDifferences: false)
        window.layoutIfNeeded()
        let moved = try XCTUnwrap(table.cellForRow(at: IndexPath(row: 1, section: 0)))

        var second = dataSource.snapshot()
        second.moveItem(2, beforeItem: 3)
        dataSource.defaultRowAnimation = .middle
        dataSource.apply(second, animatingDifferences: true)
        window.layoutIfNeeded()
        XCTAssertTrue(table.cellForRow(at: IndexPath(row: 0, section: 1)) === moved)
        XCTAssertEqual(dataSource.snapshot().itemIdentifiers, [1, 2, 3])

        let callsBeforeReload = providerCalls.count
        var reloaded = dataSource.snapshot()
        reloaded.reloadItems([2])
        dataSource.apply(reloaded, animatingDifferences: true)
        window.layoutIfNeeded()
        XCTAssertGreaterThan(providerCalls.count, callsBeforeReload)
        XCTAssertFalse(table.cellForRow(at: IndexPath(row: 0, section: 1)) === moved)

        var deleted = dataSource.snapshot()
        deleted.deleteItems([1])
        dataSource.applySnapshotUsingReloadData(deleted)
        window.layoutIfNeeded()
        XCTAssertEqual(table.numberOfRows(inSection: 0), 0)
        XCTAssertEqual(table.numberOfRows(inSection: 1), 2)
    }

    func testUIKitOnlyConsumerResolvesThePairedDiffableTypes() {
        let table = UITableView(frame: .zero, style: .plain)
        let (snapshot, dataSource) = makeFocusUIKitOnlyDiffableTypes(tableView: table)
        XCTAssertEqual(snapshot.numberOfSections, 0)
        XCTAssertTrue(table.dataSource === dataSource)
    }

    func testHierarchyOrderingSnapshotAndTransitionAreBehavioral() throws {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        container.backgroundColor = .white
        let first = UIView(frame: container.bounds)
        first.backgroundColor = .red
        let second = UIView(frame: container.bounds)
        second.backgroundColor = .blue
        let third = UIView(frame: container.bounds)
        container.addSubview(first)
        container.addSubview(second)
        container.insertSubview(third, belowSubview: second)
        XCTAssertTrue(container.subviews[1] === third)
        container.insertSubview(first, aboveSubview: second)
        XCTAssertTrue(container.subviews.last === first)

        let oldBackend = OpenUIKitRuntime.renderBackend
        let oldCompositor = OpenUIKitRuntime.compositor
        OpenUIKitRuntime.renderBackend = .swift
        OpenUIKitRuntime.compositor = .renderPass
        defer {
            OpenUIKitRuntime.renderBackend = oldBackend
            OpenUIKitRuntime.compositor = oldCompositor
        }
        let snapshot = try XCTUnwrap(container.snapshotView(afterScreenUpdates: true)
                                    as? UIImageView)
        let captured = try XCTUnwrap(snapshot.image).bitmap.pixels
        first.backgroundColor = .green
        XCTAssertEqual(snapshot.image?.bitmap.pixels, captured,
                       "snapshot must remain independent of later source changes")

        let replacement = UIView(frame: first.frame)
        var completed: Bool?
        UIView.transition(from: first, to: replacement, duration: 0.2,
                          options: .transitionCrossDissolve) { completed = $0 }
        XCTAssertNil(first.superview)
        XCTAssertTrue(replacement.superview === container)
        XCTAssertNil(completed)
        UIView._stepAnimationCompletions(to: 0.2)
        XCTAssertEqual(completed, true)
    }

    func testShowPushesOnContainingNavigationController() {
        let root = UIViewController()
        let navigation = UINavigationController(rootViewController: root)
        let next = UIViewController()
        root.show(next, sender: nil)
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertTrue(navigation.topViewController === next)
    }

    func testNavigationBarHiddenChangesContainerGeometry() {
        let navigation = UINavigationController(rootViewController: UIViewController())
        navigation.view.frame = CGRect(x: 0, y: 0, width: 320, height: 600)
        navigation.view.layoutIfNeeded()
        XCTAssertGreaterThan(navigation.contentView.frame.minY, 0)

        navigation.setNavigationBarHidden(true, animated: false)
        XCTAssertTrue(navigation.isNavigationBarHidden)
        XCTAssertTrue(navigation.navigationBar.isHidden)
        XCTAssertEqual(navigation.contentView.frame.minY, 0)
        XCTAssertEqual(navigation.contentView.frame.height, 600)

        navigation.setNavigationBarHidden(false, animated: false)
        XCTAssertFalse(navigation.navigationBar.isHidden)
        XCTAssertGreaterThan(navigation.contentView.frame.minY, 0)
    }

    func testProgrammaticZoomUpdatesTransformStateAndCallbacks() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let scroll = UIScrollView(frame: window.bounds)
        let content = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let delegate = FocusZoomDelegate(content)
        scroll.delegate = delegate
        scroll.minimumZoomScale = 0.5
        scroll.maximumZoomScale = 3
        scroll.addSubview(content)
        window.addSubview(scroll)

        scroll.setZoomScale(2, animated: false)
        XCTAssertEqual(scroll.zoomScale, 2)
        XCTAssertEqual(content.transform, CGAffineTransform(scaleX: 2, y: 2))
        XCTAssertEqual(delegate.changed, 1)

        scroll.setZoomScale(1, animated: true)
        XCTAssertTrue(scroll.isZooming)
        XCTAssertEqual(delegate.began, 1)
        XCTAssertEqual(delegate.changed, 2)
        window.tick(timestamp: 0.25)
        XCTAssertFalse(scroll.isZooming)
        XCTAssertEqual(delegate.ended, 1)
    }

    func testPropertyAnimatorUsesTransactionClockAndSpringParameters() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        let timing = UISpringTimingParameters(
            dampingRatio: 0.75,
            initialVelocity: CGVector(dx: 0, dy: 4))
        let animator = UIViewPropertyAnimator(duration: 0.4, timingParameters: timing)
        var completion: UIViewAnimatingPosition?
        animator.addAnimations { view.alpha = 0.2 }
        animator.addCompletion { completion = $0 }

        XCTAssertEqual(view.alpha, 1, "queued property work must not run before start")
        animator.startAnimation()
        XCTAssertTrue(animator.isRunning)
        XCTAssertEqual(view.alpha, 0.2)
        guard case let .spring(damping, velocity)? = view.animations.first?.timing else {
            return XCTFail("property animator did not use spring timing")
        }
        XCTAssertEqual(damping, 0.75)
        XCTAssertEqual(velocity, 4)
        XCTAssertNil(completion)
        window.tick(timestamp: 0.4)
        XCTAssertEqual(animator.state, .stopped)
        XCTAssertEqual(completion, .end)
    }

    func testActivePropertyAnimatorRetainsItselfUntilCompletion() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        var completions = 0
        weak var weakAnimator: UIViewPropertyAnimator?
        do {
            let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
                view.alpha = 0.5
            }
            weakAnimator = animator
            animator.addCompletion { position in
                XCTAssertEqual(position, .end)
                completions += 1
            }
            animator.startAnimation()
        }

        XCTAssertNotNil(weakAnimator, "the active animation transaction owns the animator")
        window.tick(timestamp: 0.3)
        XCTAssertEqual(completions, 1)
        XCTAssertNil(weakAnimator, "the animator is released after queued delivery")
        window.tick(timestamp: 1)
        XCTAssertEqual(completions, 1)
    }

    func testAllowUserInteractionControlsAnimatedViewHitTesting() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        UIView.animate(withDuration: 1) { view.alpha = 0.5 }
        XCTAssertFalse(window.hitTest(CGPoint(x: 10, y: 10), with: nil) === view)

        view.removeAllAnimations()
        view.alpha = 1
        UIView.animate(withDuration: 1, delay: 0,
                       options: .allowUserInteraction,
                       animations: { view.alpha = 0.5 })
        XCTAssertTrue(window.hitTest(CGPoint(x: 10, y: 10), with: nil) === view)
        XCTAssertEqual(UIView.AnimationOptions.allowUserInteraction.rawValue, 1 << 1)
    }

    func testImpactGeneratorDeliversOneHostEvent() {
        var events: [UIImpactFeedbackGenerator.Impact] = []
        UIImpactFeedbackGenerator.onImpact = { events.append($0) }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        XCTAssertTrue(generator.isPrepared)
        generator.impactOccurred()
        XCTAssertFalse(generator.isPrepared)
        XCTAssertEqual(events, [.init(style: .medium, intensity: 1)])
        XCTAssertEqual(UIImpactFeedbackGenerator.lastImpact, events.last)
    }
}

#if os(macOS)
@MainActor
final class FocusLaunchCoreDuplicateTrapTests: XCTestCase {
    /// Public snapshot mutation is deliberately fail-fast, like UIKit. Run
    /// each invalid operation in a child xctest process so the parent can
    /// mechanically prove the precondition without taking down the suite.
    func testDuplicateIdentifiersTrap() throws {
        if let mode = ProcessInfo.processInfo.environment["OPENUIKIT_DUPLICATE_MODE"] {
            var snapshot = OpenUIKit.NSDiffableDataSourceSnapshot<String, Int>()
            if mode == "section" {
                snapshot.appendSections(["duplicate", "duplicate"])
            } else {
                snapshot.appendSections(["section"])
                snapshot.appendItems([1, 1], toSection: "section")
            }
            XCTFail("duplicate identifiers unexpectedly survived")
            return
        }

        for mode in ["section", "item"] {
            let child = Process()
            child.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
            child.arguments = [
                "OpenUIKitTests.FocusLaunchCoreDuplicateTrapTests/testDuplicateIdentifiersTrap"
            ]
            var environment = ProcessInfo.processInfo.environment
            environment["OPENUIKIT_DUPLICATE_MODE"] = mode
            child.environment = environment
            child.standardOutput = FileHandle.nullDevice
            child.standardError = FileHandle.nullDevice
            try child.run()
            child.waitUntilExit()
            XCTAssertNotEqual(child.terminationStatus, 0,
                              "duplicate \(mode) identifiers must terminate")
        }
    }
}
#endif
