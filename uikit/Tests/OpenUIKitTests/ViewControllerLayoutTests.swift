// UIView / UIViewController constraint, layout, content-container and
// transition callback tests. Callback ordering was harvested from real
// UIKit 26.1 under Mac Catalyst before implementing the portable pass.

import Foundation
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
private final class CallbackLog {
    var entries: [String] = []
    func append(_ entry: String) { entries.append(entry) }
}

#if !os(Linux)
@MainActor
#endif
private final class LayoutProbeView: UIView {
    let name: String
    let callbackLog: CallbackLog

    init(_ name: String, log: CallbackLog) {
        self.name = name
        self.callbackLog = log
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func updateConstraints() {
        callbackLog.append("\(name).update")
        super.updateConstraints()
    }

    override func layoutSubviews() {
        callbackLog.append("\(name).layout")
        super.layoutSubviews()
    }
}

#if !os(Linux)
@MainActor
#endif
private final class LayoutProbeController: UIViewController {
    required init?(coder: NSCoder) { fatalError() }
    let callbackLog: CallbackLog
    let rootProbe: LayoutProbeView
    let childProbe: LayoutProbeView

    init(log: CallbackLog) {
        callbackLog = log
        rootProbe = LayoutProbeView("root", log: log)
        childProbe = LayoutProbeView("child", log: log)
        super.init()
    }

    override func loadView() {
        rootProbe.addSubview(childProbe)
        view = rootProbe
    }

    override func updateViewConstraints() {
        callbackLog.append("vc.update")
        super.updateViewConstraints()
    }

    override func viewWillLayoutSubviews() {
        callbackLog.append("vc.willLayout")
        super.viewWillLayoutSubviews()
    }

    override func viewDidLayoutSubviews() {
        callbackLog.append("vc.didLayout")
        super.viewDidLayoutSubviews()
    }
}

#if !os(Linux)
@MainActor
#endif
private final class ContentProbeController: UIViewController {
    required init?(coder: NSCoder) { fatalError() }
    let name: String
    let callbackLog: CallbackLog

    init(_ name: String, log: CallbackLog) {
        self.name = name
        callbackLog = log
        super.init()
    }

    override var preferredContentSize: CGSize {
        get { super.preferredContentSize }
        set { super.preferredContentSize = newValue }
    }

    override func preferredContentSizeDidChange(
        forChildContentContainer container: UIContentContainer
    ) {
        callbackLog.append("\(name).preferred")
        super.preferredContentSizeDidChange(forChildContentContainer: container)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        callbackLog.append("\(name).traits")
        super.traitCollectionDidChange(previousTraitCollection)
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        callbackLog.append("\(name).transition")
        super.viewWillTransition(to: size, with: coordinator)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class ProgrammaticNibController: UIViewController {
    private(set) var loadViewCallCount = 0

    override func loadView() {
        loadViewCallCount += 1
        view = UIView(frame: CGRect(x: 1, y: 2, width: 3, height: 4))
    }
}

#if !os(Linux)
@MainActor
#endif
private final class TransitionCoordinatorProbe: UIViewControllerTransitionCoordinator {
    var isAnimated = false
    var presentationStyle: UIModalPresentationStyle = .fullScreen
    var initiallyInteractive = false
    var isInterruptible = false
    var isInteractive = false
    var isCancelled = false
    var transitionDuration: TimeInterval = 0
    var percentComplete: CGFloat = 0
    var completionVelocity: CGFloat = 0
    var completionCurve: UIView.AnimationCurve = .easeInOut
    var containerView = UIView()
    var targetTransform: OpenUIKit.CGAffineTransform = .identity
    var animateCalls = 0

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        nil
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? { nil }

    func animate(
        alongsideTransition animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?
    ) -> Bool {
        animateCalls += 1
        animation?(self)
        completion?(self)
        return true
    }

    func animateAlongsideTransition(
        in view: UIView?,
        animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?
    ) -> Bool {
        animate(alongsideTransition: animation, completion: completion)
    }

    func notifyWhenInteractionChanges(
        _ handler: @escaping (any UIViewControllerTransitionCoordinatorContext) -> Void
    ) {}

    func notifyWhenInteractionEnds(
        _ handler: @escaping (any UIViewControllerTransitionCoordinatorContext) -> Void
    ) {}
}

#if !os(Linux)
@MainActor
#endif
private final class CoordinatorVendingController: UIViewController {
    required init?(coder: NSCoder) { fatalError() }
    let coordinator: UIViewControllerTransitionCoordinator

    init(coordinator: UIViewControllerTransitionCoordinator) {
        self.coordinator = coordinator
        super.init()
    }

    override var transitionCoordinator: UIViewControllerTransitionCoordinator? {
        coordinator
    }
}

#if !os(Linux)
@MainActor
#endif
final class ViewControllerLayoutTests: XCTestCase {

    func testNilNibInitializerMatchesPlainProgrammaticInitialization() {
        let plain = UIViewController()
        let explicitNil = UIViewController(nibName: nil, bundle: nil)

        XCTAssertNil(plain.nibName)
        XCTAssertNil(explicitNil.nibName)
        XCTAssertTrue(plain.nibBundle === Bundle.main)
        XCTAssertTrue(explicitNil.nibBundle === Bundle.main)
        XCTAssertFalse(plain.isViewLoaded)
        XCTAssertFalse(explicitNil.isViewLoaded)

        _ = plain.view
        _ = explicitNil.view

        XCTAssertTrue(plain.isViewLoaded)
        XCTAssertTrue(explicitNil.isViewLoaded)
        XCTAssertEqual(plain.view.frame, explicitNil.view.frame)
    }

    func testNibRequestStaysLazyAndAllowsProgrammaticLoadViewOverride() {
        let controller = ProgrammaticNibController(
            nibName: "Settings", bundle: Bundle.main)

        XCTAssertEqual(controller.nibName, "Settings")
        XCTAssertTrue(controller.nibBundle === Bundle.main)
        XCTAssertFalse(controller.isViewLoaded)
        XCTAssertEqual(controller.loadViewCallCount, 0)

        _ = controller.view

        XCTAssertTrue(controller.isViewLoaded)
        XCTAssertEqual(controller.loadViewCallCount, 1)
        XCTAssertEqual(
            controller.view.frame,
            CGRect(x: 1, y: 2, width: 3, height: 4))
    }

    func testNewViewNeedsConstraintsAndDirectUpdateClearsIt() {
        let log = CallbackLog()
        let view = LayoutProbeView("plain", log: log)

        XCTAssertTrue(view.needsUpdateConstraints())
        view.updateConstraints()

        XCTAssertFalse(view.needsUpdateConstraints())
        XCTAssertEqual(log.entries, ["plain.update"])
    }

    func testConstraintPassIsBottomUpAndUsesControllerForManagedRoot() {
        let log = CallbackLog()
        let controller = LayoutProbeController(log: log)
        _ = controller.view
        controller.view.updateConstraintsIfNeeded()
        controller.view.layoutIfNeeded()
        log.entries.removeAll()

        controller.childProbe.setNeedsUpdateConstraints()
        controller.view.layoutIfNeeded()

        XCTAssertEqual(log.entries, [
            "child.update",
            "vc.update", "root.update",
            "vc.willLayout", "root.layout", "vc.didLayout",
        ])
        XCTAssertFalse(controller.childProbe.needsUpdateConstraints())
        XCTAssertFalse(controller.rootProbe.needsUpdateConstraints())
    }

    func testControllerCallbacksBracketRootBeforeDirtyChildLayouts() {
        let log = CallbackLog()
        let controller = LayoutProbeController(log: log)
        _ = controller.view
        controller.view.updateConstraintsIfNeeded()
        controller.view.layoutIfNeeded()
        log.entries.removeAll()

        controller.rootProbe.setNeedsLayout()
        controller.childProbe.setNeedsLayout()
        controller.view.layoutIfNeeded()

        XCTAssertEqual(log.entries, [
            "vc.willLayout", "root.layout", "vc.didLayout", "child.layout",
        ])
        log.entries.removeAll()
        controller.view.layoutIfNeeded()
        XCTAssertEqual(log.entries, [], "a settled pass must emit no callbacks")
    }

    func testPreferredContentSizeNotifiesImmediateParentWithProtocolType() {
        let log = CallbackLog()
        let parent = ContentProbeController("parent", log: log)
        let child = ContentProbeController("child", log: log)
        parent.addChild(child)
        child.didMove(toParent: parent)

        child.preferredContentSize = CGSize(width: 17, height: 23)

        XCTAssertEqual(log.entries, ["parent.preferred"])
        XCTAssertEqual(child.preferredContentSize, CGSize(width: 17, height: 23))
        XCTAssertEqual(
            parent.size(forChildContentContainer: child,
                        withParentContainerSize: CGSize(width: 101, height: 203)),
            CGSize(width: 101, height: 203))
    }

    func testLegacyTraitCallbackFollowsControllerRootViewTree() {
        let log = CallbackLog()
        let parent = ContentProbeController("parent", log: log)
        let child = ContentProbeController("child", log: log)
        parent.addChild(child)
        parent.view.addSubview(child.view)
        child.didMove(toParent: parent)
        log.entries.removeAll()

        let previous = UITraitCollection(userInterfaceStyle: .light)
        parent.view._traitsDidChange(previous: previous)

        XCTAssertEqual(log.entries, ["parent.traits", "child.traits"])
    }

    func testTransitionCoordinatorShapeAndContainmentPropagation() {
        XCTAssertEqual(UIView.AnimationCurve.easeInOut.rawValue, 0)
        XCTAssertEqual(UIView.AnimationCurve.easeIn.rawValue, 1)
        XCTAssertEqual(UIView.AnimationCurve.easeOut.rawValue, 2)
        XCTAssertEqual(UIView.AnimationCurve.linear.rawValue, 3)

        let log = CallbackLog()
        let parent = ContentProbeController("parent", log: log)
        let child = ContentProbeController("child", log: log)
        parent.addChild(child)
        child.didMove(toParent: parent)
        let coordinator = TransitionCoordinatorProbe()

        let vendingParent = CoordinatorVendingController(coordinator: coordinator)
        let inheritingChild = UIViewController()
        vendingParent.addChild(inheritingChild)
        inheritingChild.didMove(toParent: vendingParent)
        XCTAssertTrue(inheritingChild.transitionCoordinator === coordinator)

        parent.viewWillTransition(
            to: CGSize(width: 320, height: 480), with: coordinator)
        XCTAssertEqual(log.entries, ["parent.transition", "child.transition"])

        var animationRan = false
        XCTAssertTrue(coordinator.animate(alongsideTransition: { _ in
            animationRan = true
        }))
        XCTAssertTrue(animationRan)
        XCTAssertEqual(coordinator.animateCalls, 1)
    }
}
