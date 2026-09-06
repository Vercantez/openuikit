// Corpus tail #1 / #8: UIViewControllerTransitionCoordinator during
// push/present, UIPercentDrivenInteractiveTransition, and the
// UIViewPropertyAnimator state machine measured on iPhone SE 2x / iOS 26.1
// (animprobe, /tmp/uikit-tail-animprobe/report.json).
import XCTest
import Foundation
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
private struct CoordinatorSnap {
    let exists: Bool
    let duration: TimeInterval
    let style: UIModalPresentationStyle?
    let curveRaw: Int?
    let isAnimated: Bool
    let isInteractive: Bool
    let initiallyInteractive: Bool
    let isInterruptible: Bool
    let percentComplete: CGFloat
    let completionVelocity: CGFloat
    let identityTransform: Bool

    init(_ c: UIViewControllerTransitionCoordinator?) {
        exists = c != nil
        duration = c?.transitionDuration ?? -1
        style = c?.presentationStyle
        curveRaw = c?.completionCurve.rawValue
        isAnimated = c?.isAnimated ?? false
        isInteractive = c?.isInteractive ?? false
        initiallyInteractive = c?.initiallyInteractive ?? false
        isInterruptible = c?.isInterruptible ?? false
        percentComplete = c?.percentComplete ?? -1
        completionVelocity = c?.completionVelocity ?? -1
        identityTransform = c.map { $0.targetTransform == .identity } ?? false
    }
}

#if !os(Linux)
@MainActor
#endif
private final class CoordinatorProbeVC: UIViewController {
    var will: CoordinatorSnap?
    var did: CoordinatorSnap?
    var alongsideRanInWillAppear = false
    var alongsideAnimationCount = 0
    var alongsideCompletionCount = 0

    override func viewWillAppear(_ animated: Bool) {
        will = CoordinatorSnap(transitionCoordinator)
        var ran = false
        let registered = transitionCoordinator?.animate(alongsideTransition: { _ in
            ran = true
            self.alongsideAnimationCount += 1
        }, completion: { _ in
            self.alongsideCompletionCount += 1
        }) ?? false
        alongsideRanInWillAppear = ran
        if let c = transitionCoordinator {
            XCTAssertTrue(registered || !c.isAnimated)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        did = CoordinatorSnap(transitionCoordinator)
    }
}

#if !os(Linux)
@MainActor
#endif
final class TransitionAnimatorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OpenUIKitRuntime.animationTime = 0
        UIViewAnimationCompletionQueue.entries.removeAll()
    }

    override func tearDown() {
        OpenUIKitRuntime.animationTime = 0
        UIViewAnimationCompletionQueue.entries.removeAll()
        super.tearDown()
    }

    // MARK: UIViewPropertyAnimator state machine

    func testPropertyAnimatorDefaultsMatchAnimprobe() {
        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear)
        XCTAssertEqual(animator.state, .inactive)
        XCTAssertFalse(animator.isRunning)
        XCTAssertFalse(animator.isReversed)
        XCTAssertEqual(animator.fractionComplete, 0)
        XCTAssertTrue(animator.isInterruptible)
        XCTAssertTrue(animator.isUserInteractionEnabled)
        XCTAssertFalse(animator.isManualHitTestingEnabled)
        XCTAssertTrue(animator.scrubsLinearly)
        XCTAssertFalse(animator.pausesOnCompletion)
        XCTAssertEqual(animator.delay, 0)
    }

    func testCubicTimingParametersMatchAnimprobeControlPoints() {
        let easeInOut = UICubicTimingParameters(animationCurve: .easeInOut)
        XCTAssertEqual(easeInOut.controlPoint1, CGPoint(x: 0.42, y: 0))
        XCTAssertEqual(easeInOut.controlPoint2, CGPoint(x: 0.58, y: 1))
        XCTAssertEqual(easeInOut.timingCurveType, .builtIn)
        XCTAssertEqual(easeInOut.animationCurve.rawValue, 0)

        let easeIn = UICubicTimingParameters(animationCurve: .easeIn)
        XCTAssertEqual(easeIn.controlPoint1, CGPoint(x: 0.42, y: 0))
        XCTAssertEqual(easeIn.controlPoint2, CGPoint(x: 1, y: 1))

        let easeOut = UICubicTimingParameters(animationCurve: .easeOut)
        XCTAssertEqual(easeOut.controlPoint1, CGPoint(x: 0, y: 0))
        XCTAssertEqual(easeOut.controlPoint2, CGPoint(x: 0.58, y: 1))

        let linear = UICubicTimingParameters(animationCurve: .linear)
        XCTAssertEqual(linear.controlPoint1, CGPoint(x: 0, y: 0))
        XCTAssertEqual(linear.controlPoint2, CGPoint(x: 1, y: 1))

        let custom = UICubicTimingParameters(
            controlPoint1: CGPoint(x: 0.22, y: 1),
            controlPoint2: CGPoint(x: 0.36, y: 1))
        XCTAssertEqual(custom.timingCurveType, .cubic)
        XCTAssertEqual(custom.animationCurve.rawValue, 6)

        let css = UICubicTimingParameters()
        XCTAssertEqual(css.controlPoint1, CGPoint(x: 0.25, y: 0.1))
        XCTAssertEqual(css.controlPoint2, CGPoint(x: 0.25, y: 1))
        XCTAssertEqual(css.animationCurve.rawValue, 5)
    }

    func testPropertyAnimatorPauseStopFinishAndScrub() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        window.addSubview(view)
        view.alpha = 1
        var completions = 0
        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear)
        animator.addAnimations { view.alpha = 0 }
        animator.addCompletion { _ in completions += 1 }
        animator.startAnimation()
        XCTAssertEqual(animator.state, .active)
        XCTAssertTrue(animator.isRunning)
        XCTAssertEqual(view.alpha, 0, "model is the TO value once committed")

        OpenUIKitRuntime.animationTime = 0.4
        XCTAssertEqual(animator.fractionComplete, 0.4, accuracy: 1e-9)
        animator.pauseAnimation()
        XCTAssertEqual(animator.state, .active)
        XCTAssertFalse(animator.isRunning)
        XCTAssertEqual(animator.fractionComplete, 0.4, accuracy: 1e-9)

        animator.stopAnimation(true)
        XCTAssertEqual(animator.state, .inactive)
        XCTAssertEqual(view.alpha, 1, "stopAnimation(true) restores FROM")
        XCTAssertEqual(completions, 0)

        let second = UIViewPropertyAnimator(duration: 1, curve: .linear)
        second.addAnimations { view.alpha = 0 }
        var finishedAt: UIViewAnimatingPosition?
        second.addCompletion { finishedAt = $0 }
        second.startAnimation()
        second.pauseAnimation()
        second.stopAnimation(false)
        XCTAssertEqual(second.state, .stopped)
        second.finishAnimation(at: .start)
        XCTAssertEqual(second.state, .inactive)
        XCTAssertEqual(view.alpha, 1)
        XCTAssertEqual(finishedAt, .start)
    }

    func testSettingFractionCompleteOnInactiveActivatesPaused() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        view.center = CGPoint(x: 50, y: 50)
        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear)
        animator.addAnimations { view.center.x = 150 }
        XCTAssertEqual(animator.state, .inactive)
        animator.fractionComplete = 0.5
        XCTAssertEqual(animator.state, .active)
        XCTAssertFalse(animator.isRunning)
        XCTAssertEqual(animator.fractionComplete, 0.5, accuracy: 1e-9)
    }

    func testPercentDrivenUpdateFinishAndCancel() {
        let percent = UIPercentDrivenInteractiveTransition()
        XCTAssertEqual(percent.percentComplete, 0)
        XCTAssertEqual(percent.completionSpeed, 1)
        XCTAssertEqual(percent.completionCurve, .easeInOut)
        XCTAssertTrue(percent.wantsInteractiveStart)
        percent.update(0.4)
        XCTAssertEqual(percent.percentComplete, 0.4, accuracy: 1e-9)
        percent.update(1.5)
        XCTAssertEqual(percent.percentComplete, 1, accuracy: 1e-9)
        percent.update(-0.2)
        XCTAssertEqual(percent.percentComplete, 0, accuracy: 1e-9)
        percent.finish()
        percent.cancel()
    }

    // MARK: Transition coordinator

    func testPushVendsCoordinatorWithMeasuredPushProperties() {
        let from = CoordinatorProbeVC()
        from.title = "From"
        let nav = UINavigationController(rootViewController: from)
        nav.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        nav.view.layoutIfNeeded()
        from.will = nil
        from.did = nil
        from.alongsideAnimationCount = 0

        let to = CoordinatorProbeVC()
        to.title = "To"
        OpenUIKitRuntime.animationTime = 1
        nav.pushViewController(to, animated: true)

        XCTAssertEqual(to.will?.exists, true)
        XCTAssertNotNil(from.transitionCoordinator)
        XCTAssertTrue(from.transitionCoordinator === to.transitionCoordinator)
        XCTAssertTrue(nav.transitionCoordinator === to.transitionCoordinator)
        XCTAssertEqual(to.will?.duration ?? -1, 0.35, accuracy: 1e-12)
        XCTAssertEqual(to.will?.style, UIModalPresentationStyle.none)
        XCTAssertEqual(to.will?.curveRaw, 7)
        XCTAssertEqual(to.will?.isAnimated, true)
        XCTAssertEqual(to.will?.isInteractive, false)
        XCTAssertEqual(to.will?.initiallyInteractive, false)
        XCTAssertEqual(to.will?.isInterruptible, false)
        XCTAssertEqual(to.will?.percentComplete, 0)
        XCTAssertEqual(to.will?.completionVelocity, 1)
        XCTAssertEqual(to.will?.identityTransform, true)
        XCTAssertFalse(to.alongsideRanInWillAppear,
                       "animate(alongsideTransition:) is not synchronous in viewWillAppear")
        XCTAssertEqual(to.alongsideAnimationCount, 1,
                       "built-in slide flushes alongside inside UIView.animate")

        UINavigationController._stepTransitions(to: 1.35)
        UIView._stepAnimationCompletions(to: 1.35)
        XCTAssertEqual(to.did?.exists, true, "coordinator survives viewDidAppear")
        XCTAssertEqual(to.alongsideCompletionCount, 1)
        XCTAssertNil(to.transitionCoordinator)
        XCTAssertNil(from.transitionCoordinator)
        XCTAssertNil(nav.transitionCoordinator)
    }

    func testNonAnimatedPushHasNoCoordinator() {
        let from = CoordinatorProbeVC()
        let nav = UINavigationController(rootViewController: from)
        nav.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        nav.view.layoutIfNeeded()
        let to = CoordinatorProbeVC()
        nav.pushViewController(to, animated: false)
        XCTAssertEqual(to.will?.exists, false)
        XCTAssertNil(to.transitionCoordinator)
        XCTAssertNil(nav.transitionCoordinator)
    }

    func testPresentVendsCoordinatorWithMeasuredPageSheetProperties() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let base = CoordinatorProbeVC()
        base.view.frame = window.bounds
        window.addSubview(base.view)
        let sheet = CoordinatorProbeVC()
        sheet.modalPresentationStyle = .pageSheet
        base.present(sheet, animated: true)

        XCTAssertEqual(sheet.will?.exists, true)
        XCTAssertNotNil(base.transitionCoordinator, "presenting controller vends the coordinator")
        XCTAssertTrue(base.transitionCoordinator === sheet.transitionCoordinator)
        XCTAssertEqual(sheet.will?.style, .pageSheet)
        XCTAssertEqual(sheet.will?.duration ?? -1, 0, accuracy: 1e-12)
        XCTAssertEqual(sheet.will?.curveRaw, 0)
        XCTAssertEqual(sheet.will?.isAnimated, true)
        XCTAssertEqual(sheet.will?.isInteractive, false)
        XCTAssertFalse(sheet.alongsideRanInWillAppear)
        XCTAssertEqual(sheet.alongsideAnimationCount, 1)

        OpenUIKitRuntime.animationTime = 2
        UIView._stepAnimationCompletions(to: 2)
        XCTAssertEqual(sheet.did?.exists, true)
        XCTAssertEqual(sheet.alongsideCompletionCount, 1)
        XCTAssertNil(sheet.transitionCoordinator)
        XCTAssertNil(base.transitionCoordinator)
    }

    func testNonAnimatedPresentHasNoCoordinator() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let base = CoordinatorProbeVC()
        base.view.frame = window.bounds
        window.addSubview(base.view)
        let sheet = CoordinatorProbeVC()
        base.present(sheet, animated: false)
        XCTAssertEqual(sheet.will?.exists, false)
        XCTAssertNil(sheet.transitionCoordinator)
        XCTAssertNil(base.transitionCoordinator)
    }
}
