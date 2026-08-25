// Delegate protocols (M13, docs/APP_COMPAT.md cluster #4).
//
// Two things are under test here:
//
//   1. that a conformance COMPILES while implementing only some members —
//      the whole point of the cluster, since the census counts these as
//      compile errors before any behaviour is missing. The `Minimal*`
//      conformances below are that test: they are empty, and the file
//      failing to build is the failure.
//   2. that the members which really GATE behaviour do gate it: the text
//      field's editing/return/should-change hooks and the gesture
//      recognizer's should-begin / simultaneity / should-receive.
import XCTest
@testable import OpenUIKit

// MARK: - Compile-only conformances (empty on purpose)

private final class MinimalTextFieldDelegate: UITextFieldDelegate {}
private final class MinimalTextViewDelegate: UITextViewDelegate {}
private final class MinimalGestureDelegate: UIGestureRecognizerDelegate {}
private final class MinimalScrollDelegate: UIScrollViewDelegate {}
private final class MinimalAdaptiveDelegate: UIAdaptivePresentationControllerDelegate {}
private final class MinimalSheetDelegate: UISheetPresentationControllerDelegate {}
private final class MinimalPopoverDelegate: UIPopoverPresentationControllerDelegate {}
private final class MinimalSearchBarDelegate: UISearchBarDelegate {}
private final class MinimalTabBarControllerDelegate: UITabBarControllerDelegate {}
private final class MinimalNavigationDelegate: UINavigationControllerDelegate {}

final class DelegateDeclarationTests: XCTestCase {
    /// Every protocol in the cluster can be conformed to with NO members —
    /// the portable stand-in for ObjC's `@objc optional`.
    func testEmptyConformancesCompileAndAnswerTheDefaults() {
        XCTAssertTrue(MinimalTextFieldDelegate().textFieldShouldReturn(UITextField()))
        XCTAssertTrue(MinimalTextViewDelegate().textViewShouldBeginEditing(UITextView()))
        XCTAssertTrue(MinimalGestureDelegate()
            .gestureRecognizerShouldBegin(UIGestureRecognizer()))
        XCTAssertFalse(MinimalGestureDelegate()
            .gestureRecognizer(UIGestureRecognizer(),
                               shouldRecognizeSimultaneouslyWith: UIGestureRecognizer()))
        XCTAssertTrue(MinimalScrollDelegate().scrollViewShouldScrollToTop(UIScrollView()))
        XCTAssertTrue(MinimalSearchBarDelegate().searchBarShouldBeginEditing(UISearchBar()))
        XCTAssertTrue(MinimalTabBarControllerDelegate()
            .tabBarController(UITabBarController(), shouldSelect: UIViewController()))
        let vc = UIViewController()
        let pc = UIPresentationController(presentedViewController: vc, presenting: nil)
        XCTAssertTrue(MinimalAdaptiveDelegate().presentationControllerShouldDismiss(pc))
        XCTAssertTrue(MinimalSheetDelegate().presentationControllerShouldDismiss(pc))
        XCTAssertTrue(MinimalPopoverDelegate()
            .popoverPresentationControllerShouldDismissPopover(
                UIPopoverPresentationController(presentedViewController: vc, presenting: nil)))
    }
}

// MARK: - UITextFieldDelegate gating

private final class RecordingFieldDelegate: UITextFieldDelegate {
    var log: [String] = []
    var allowBegin = true
    var allowEnd = true
    var allowChange = true
    var returnAnswer = true

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { allowBegin }
    func textFieldDidBeginEditing(_ textField: UITextField) { log.append("didBegin") }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool { allowEnd }
    func textFieldDidEndEditing(_ textField: UITextField) { log.append("didEnd") }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        log.append("shouldChange(\(range.location),\(range.length),'\(string)')")
        return allowChange
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        log.append("shouldReturn")
        return returnAnswer
    }
}

final class TextFieldDelegateTests: XCTestCase {

    private func makeField(_ d: RecordingFieldDelegate) -> (UIWindow, UITextField) {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        let f = UITextField(frame: CGRect(x: 10, y: 10, width: 200, height: 34))
        f.delegate = d
        w.addSubview(f)
        w.makeKeyAndVisible()
        return (w, f)
    }

    func testShouldBeginEditingBlocksFocus() {
        let d = RecordingFieldDelegate()
        d.allowBegin = false
        let (_, f) = makeField(d)
        XCTAssertFalse(f.becomeFirstResponder())
        XCTAssertFalse(f.isEditing)
        XCTAssertTrue(d.log.isEmpty)
    }

    func testBeginAndEndCallbacksFire() {
        let d = RecordingFieldDelegate()
        let (_, f) = makeField(d)
        XCTAssertTrue(f.becomeFirstResponder())
        XCTAssertEqual(d.log, ["didBegin"])
        XCTAssertTrue(f.resignFirstResponder())
        XCTAssertEqual(d.log, ["didBegin", "didEnd"])
    }

    func testShouldEndEditingBlocksResign() {
        let d = RecordingFieldDelegate()
        let (_, f) = makeField(d)
        f.becomeFirstResponder()
        d.allowEnd = false
        XCTAssertFalse(f.resignFirstResponder())
        XCTAssertTrue(f.isEditing)
        d.allowEnd = true
        XCTAssertTrue(f.resignFirstResponder())
        XCTAssertFalse(f.isEditing)
    }

    /// A refusal to end editing also survives another responder trying to
    /// take focus (UIResponder consults canResignFirstResponder).
    func testShouldEndEditingBlocksFocusTransfer() {
        let d = RecordingFieldDelegate()
        let (w, f) = makeField(d)
        let other = UITextField(frame: CGRect(x: 10, y: 60, width: 200, height: 34))
        w.addSubview(other)
        f.becomeFirstResponder()
        d.allowEnd = false
        XCTAssertFalse(other.becomeFirstResponder())
        XCTAssertTrue(f.isFirstResponder)
    }

    func testShouldChangeCharactersGatesTyping() {
        let d = RecordingFieldDelegate()
        let (w, f) = makeField(d)
        f.becomeFirstResponder()
        w.sendText("ab", timestamp: 0)
        XCTAssertEqual(f.text, "ab")
        d.allowChange = false
        w.sendText("c", timestamp: 0.1)
        XCTAssertEqual(f.text, "ab", "a refused change does not reach the text")
        w.sendKey(.backspace, timestamp: 0.2)
        XCTAssertEqual(f.text, "ab", "a refused delete does not reach the text either")
        XCTAssertTrue(d.log.contains("shouldChange(2,0,'c')"))
        XCTAssertTrue(d.log.contains("shouldChange(1,1,'')"))
    }

    /// UIKit's return handling: the delegate is asked first, and answering
    /// false suppresses the field's own response (no primaryActionTriggered,
    /// no resign).
    func testShouldReturnGatesThePrimaryAction() {
        let d = RecordingFieldDelegate()
        let (w, f) = makeField(d)
        var primary = 0
        f.addTarget(for: .primaryActionTriggered) { _, _ in primary += 1 }
        f.becomeFirstResponder()
        d.returnAnswer = false
        w.sendKey(.return, timestamp: 0)
        XCTAssertEqual(primary, 0)
        XCTAssertTrue(f.isEditing)
        d.returnAnswer = true
        w.sendKey(.return, timestamp: 0.1)
        XCTAssertEqual(primary, 1)
        XCTAssertFalse(f.isEditing)
    }

    func testClearIsGatedToo() {
        final class NoClear: UITextFieldDelegate {
            func textFieldShouldClear(_ textField: UITextField) -> Bool { false }
        }
        let f = UITextField()
        f.text = "hello"
        let d = NoClear()
        f.delegate = d
        XCTAssertFalse(f._clear())
        XCTAssertEqual(f.text, "hello")
    }
}

// MARK: - UITextViewDelegate gating

private final class RecordingTextViewDelegate: UITextViewDelegate {
    var changes = 0
    var allowChange = true
    var didBegin = 0
    func textViewDidBeginEditing(_ textView: UITextView) { didBegin += 1 }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool { allowChange }
    func textViewDidChange(_ textView: UITextView) { changes += 1 }
}

final class TextViewDelegateTests: XCTestCase {
    func testTextViewDelegateGatesAndReports() {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        let tv = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        let d = RecordingTextViewDelegate()
        tv.delegate = d
        XCTAssertTrue(tv.textViewDelegate === d, "a UITextViewDelegate IS the scroll delegate")
        w.addSubview(tv)
        w.makeKeyAndVisible()
        XCTAssertTrue(tv.becomeFirstResponder())
        XCTAssertEqual(d.didBegin, 1)
        w.sendText("hi", timestamp: 0)
        XCTAssertEqual(tv.text, "hi")
        XCTAssertEqual(d.changes, 1)
        d.allowChange = false
        w.sendText("!", timestamp: 0.1)
        XCTAssertEqual(tv.text, "hi")
        XCTAssertEqual(d.changes, 1)
    }
}

// MARK: - UIGestureRecognizerDelegate gating

private final class GestureDelegate: UIGestureRecognizerDelegate {
    var allowBegin = true
    var allowSimultaneous = false
    var refuseTouches = false
    /// How many times UIKit's "may this gesture begin?" question was asked.
    var beginAsked = 0
    func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
        beginAsked += 1
        return allowBegin
    }
    func gestureRecognizer(_ g: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        allowSimultaneous
    }
    func gestureRecognizer(_ g: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !refuseTouches
    }
}

final class GestureDelegateTests: XCTestCase {

    private func makeWindow() -> (UIWindow, UIView) {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        w.addSubview(v)
        w.makeKeyAndVisible()
        return (w, v)
    }

    func testShouldBeginFailsTheGesture() {
        let (w, v) = makeWindow()
        var fired = 0
        let tap = UITapGestureRecognizer { _ in fired += 1 }
        let d = GestureDelegate()
        d.allowBegin = false
        tap.delegate = d
        v.addGestureRecognizer(tap)
        w.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        w.sendTouch(.ended, at: CGPoint(x: 50, y: 50), timestamp: 0.05)
        XCTAssertEqual(fired, 0)
        XCTAssertEqual(d.beginAsked, 1, "the delegate was asked, once, at recognition")
        // (The state is back at .possible: a completed touch sequence resets
        // every recognizer, exactly as UIKit does.)
        XCTAssertEqual(tap.state, .possible)
    }

    func testShouldReceiveTouchKeepsTheRecognizerOutOfTheSequence() {
        let (w, v) = makeWindow()
        var fired = 0
        let tap = UITapGestureRecognizer { _ in fired += 1 }
        let d = GestureDelegate()
        d.refuseTouches = true
        tap.delegate = d
        v.addGestureRecognizer(tap)
        w.sendTouch(.began, at: CGPoint(x: 50, y: 50), timestamp: 0)
        w.sendTouch(.ended, at: CGPoint(x: 50, y: 50), timestamp: 0.05)
        XCTAssertEqual(fired, 0)
        XCTAssertEqual(d.beginAsked, 0, "it never even observed the touch")
    }

    /// UIKit's default: the first recognizer to recognize FAILS the others
    /// sharing the touch.
    func testExclusionIsTheDefault() {
        let (w, v) = makeWindow()
        let inner = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        v.addSubview(inner)
        var outerFired = 0, innerFired = 0
        let outerTap = UITapGestureRecognizer { _ in outerFired += 1 }
        let innerTap = UITapGestureRecognizer { _ in innerFired += 1 }
        v.addGestureRecognizer(outerTap)
        inner.addGestureRecognizer(innerTap)
        w.sendTouch(.began, at: CGPoint(x: 20, y: 20), timestamp: 0)
        w.sendTouch(.ended, at: CGPoint(x: 20, y: 20), timestamp: 0.05)
        XCTAssertEqual(innerFired + outerFired, 1, "exactly one recognizer wins")
    }

    /// ...unless either delegate allows simultaneity.
    func testSimultaneousRecognitionWhenTheDelegateAllowsIt() {
        let (w, v) = makeWindow()
        let inner = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        v.addSubview(inner)
        var outerFired = 0, innerFired = 0
        let outerTap = UITapGestureRecognizer { _ in outerFired += 1 }
        let innerTap = UITapGestureRecognizer { _ in innerFired += 1 }
        let d = GestureDelegate()
        d.allowSimultaneous = true
        innerTap.delegate = d
        v.addGestureRecognizer(outerTap)
        inner.addGestureRecognizer(innerTap)
        w.sendTouch(.began, at: CGPoint(x: 20, y: 20), timestamp: 0)
        w.sendTouch(.ended, at: CGPoint(x: 20, y: 20), timestamp: 0.05)
        XCTAssertEqual(innerFired, 1)
        XCTAssertEqual(outerFired, 1)
    }
}

// MARK: - Scroll / tab-bar / adaptive presentation wiring

private final class RetargetingScrollDelegate: UIScrollViewDelegate {
    var target: CGPoint?
    var seenVelocity: CGPoint = .zero
    var natural: CGPoint = .zero
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        seenVelocity = velocity
        natural = targetContentOffset.pointee
        if let target { targetContentOffset.pointee = target }
    }
}

final class ScrollDelegateWiringTests: XCTestCase {

    private func makeScroll() -> UIScrollView {
        let sv = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        sv.contentSize = CGSize(width: 200, height: 4000)
        return sv
    }

    /// UIKit hands the delegate the natural landing offset and its velocity
    /// in points per MILLISECOND.
    func testWillEndDraggingReportsTheNaturalTargetAndVelocity() {
        let sv = makeScroll()
        let d = RetargetingScrollDelegate()
        sv.delegate = d
        sv.contentOffset = CGPoint(x: 0, y: 100)
        sv.endDragging(velocity: CGPoint(x: 0, y: 1000), at: 0)
        XCTAssertEqual(d.seenVelocity.y, 1, accuracy: 0.001)
        XCTAssertEqual(d.natural.y,
                       UIScrollPhysics.decelTargetOffset(x0: 100, v0: 1000), accuracy: 0.5)
    }

    /// A retarget is honoured exactly: the deceleration lands on the offset
    /// the delegate asked for.
    func testRetargetLandsWhereTheDelegateAsked() {
        let sv = makeScroll()
        let d = RetargetingScrollDelegate()
        d.target = CGPoint(x: 0, y: 600)
        sv.delegate = d
        sv.contentOffset = CGPoint(x: 0, y: 100)
        sv.endDragging(velocity: CGPoint(x: 0, y: 1000), at: 0)
        UIScrollView._stepScrollAnimations(to: 10)
        XCTAssertEqual(sv.contentOffset.y, 600, accuracy: 0.5)
    }
}

private final class TabDelegate: UITabBarControllerDelegate {
    var allow = true
    var selected: [String] = []
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool { allow }
    func tabBarController(_ tabBarController: UITabBarController,
                          didSelect viewController: UIViewController) {
        selected.append(viewController.title ?? "")
    }
}

final class TabBarControllerDelegateTests: XCTestCase {
    func testShouldSelectGatesAUserTapAndDidSelectReports() {
        let tab = UITabBarController()
        let a = UIViewController(); a.title = "A"
        let b = UIViewController(); b.title = "B"
        tab.setViewControllers([a, b], animated: false)
        let d = TabDelegate()
        tab.tabBarControllerDelegate = d
        tab.loadViewIfNeeded()
        XCTAssertEqual(d.selected, ["A"])

        d.allow = false
        tab.tabBar(tab.tabBar, didSelect: b.tabBarItem!)
        XCTAssertEqual(tab.selectedIndex, 0, "a refused tap does not switch tabs")

        d.allow = true
        tab.tabBar(tab.tabBar, didSelect: b.tabBarItem!)
        XCTAssertEqual(tab.selectedIndex, 1)
        XCTAssertEqual(d.selected, ["A", "B"])
    }
}

private final class AdaptiveDelegate: UIAdaptivePresentationControllerDelegate {
    var allowDismiss = true
    var log: [String] = []
    func presentationControllerShouldDismiss(_ c: UIPresentationController) -> Bool {
        allowDismiss
    }
    func presentationControllerWillDismiss(_ c: UIPresentationController) {
        log.append("will")
    }
    func presentationControllerDidDismiss(_ c: UIPresentationController) {
        log.append("did")
    }
    func presentationControllerDidAttemptToDismiss(_ c: UIPresentationController) {
        log.append("attempt")
    }
}

final class AdaptivePresentationDelegateTests: XCTestCase {

    /// The interactive sheet drag asks the delegate before it commits, and
    /// reports the refusal — the same place `isModalInPresentation` is read.
    func testShouldDismissGatesTheInteractiveDrag() {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let presenter = UIViewController()
        w.rootViewController = presenter
        w.makeKeyAndVisible()
        let presented = UIViewController()
        let d = AdaptiveDelegate()
        d.allowDismiss = false
        presented.sheetPresentationController?.delegate = d
        presenter.present(presented, animated: false)
        w.layoutIfNeeded()

        let sheet = try! XCTUnwrap(presented._presentationSheet)
        sheet.endDrag(velocity: 2000, at: 0)   // a firm downward fling
        XCTAssertEqual(d.log, ["attempt"])
        XCTAssertNotNil(presenter.presentedViewController, "the sheet stayed")

        d.allowDismiss = true
        sheet.endDrag(velocity: 2000, at: 1)
        _UIPageSheetView._stepSheetInteractions(to: 5)
        XCTAssertEqual(d.log, ["attempt", "will", "did"])
        XCTAssertNil(presenter.presentedViewController)
    }

    /// UIKit does NOT report didDismiss for a programmatic dismissal — those
    /// members mean "the user did it".
    func testProgrammaticDismissDoesNotReportUserDismissal() {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let presenter = UIViewController()
        w.rootViewController = presenter
        w.makeKeyAndVisible()
        let presented = UIViewController()
        let d = AdaptiveDelegate()
        presented.sheetPresentationController?.delegate = d
        presenter.present(presented, animated: false)
        presenter.dismiss(animated: false)
        XCTAssertTrue(d.log.isEmpty)
    }

    /// A `.popover` presentation adapts to the sheet on this device class and
    /// forwards its delegate.
    func testPopoverAdaptsToASheet() {
        let vc = UIViewController()
        vc.modalPresentationStyle = .popover
        let popover = try! XCTUnwrap(vc.popoverPresentationController)
        XCTAssertEqual(popover.adaptedStyle, .pageSheet)
        XCTAssertEqual(vc._resolvedPresentationStyle, .pageSheet)
    }
}

// MARK: - UISearchBar

private final class SearchDelegate: UISearchBarDelegate {
    var texts: [String] = []
    var searches = 0
    var cancels = 0
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        texts.append(searchText)
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searches += 1 }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) { cancels += 1 }
}

final class SearchBarTests: XCTestCase {
    func testTypingAndSearchingReachTheDelegate() {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        let bar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        let d = SearchDelegate()
        bar.delegate = d
        w.addSubview(bar)
        w.makeKeyAndVisible()
        XCTAssertTrue(bar.becomeFirstResponder())
        w.sendText("ab", timestamp: 0)
        XCTAssertEqual(bar.text, "ab")
        XCTAssertEqual(d.texts, ["ab"])
        w.sendKey(.return, timestamp: 0.1)
        XCTAssertEqual(d.searches, 1)
        bar._cancel()
        XCTAssertEqual(d.cancels, 1)
        XCTAssertEqual(bar.text, "")
    }
}

// MARK: - UIActivityViewController (the honest stub)

private final class TestActivity: UIActivity {
    let title: String
    var performed = 0
    init(title: String) { self.title = title; super.init() }
    override var activityTitle: String? { title }
    override var activityType: UIActivity.ActivityType? { UIActivity.ActivityType("test.\(title)") }
    override func perform() { performed += 1; activityDidFinish(true) }
}

final class ActivityViewControllerTests: XCTestCase {

    func testDismissWithoutPickingReportsNotCompleted() {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let presenter = UIViewController()
        w.rootViewController = presenter
        w.makeKeyAndVisible()
        var completed: Bool?
        var type: UIActivity.ActivityType?
        let vc = UIActivityViewController(activityItems: ["hello"], applicationActivities: nil)
        vc.completionWithItemsHandler = { t, done, _, _ in type = t; completed = done }
        presenter.present(vc, animated: false)
        presenter.dismiss(animated: false)
        XCTAssertEqual(completed, false)
        XCTAssertNil(type)
    }

    func testPickingAnActivityRunsItAndReportsCompletion() {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let presenter = UIViewController()
        w.rootViewController = presenter
        w.makeKeyAndVisible()
        let activity = TestActivity(title: "Save")
        var completed: Bool?
        var type: UIActivity.ActivityType?
        let vc = UIActivityViewController(activityItems: ["hello"],
                                          applicationActivities: [activity])
        vc.completionWithItemsHandler = { t, done, _, _ in type = t; completed = done }
        presenter.present(vc, animated: false)
        w.layoutIfNeeded()
        XCTAssertEqual(vc.availableActivities.count, 1)
        vc.tableView(vc.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        // The dismissal is animated: its completion (and therefore
        // viewDidDisappear) lands when the host clock passes the transition.
        w.tick(timestamp: 2)
        XCTAssertEqual(activity.performed, 1)
        XCTAssertEqual(completed, true)
        XCTAssertEqual(type?.rawValue, "test.Save")
    }

    /// No system activities exist here, so a share sheet with nothing to
    /// offer says so rather than pretending.
    func testEmptySheetSaysItHasNothingToOffer() {
        let vc = UIActivityViewController(activityItems: ["x"], applicationActivities: nil)
        vc.loadViewIfNeeded()
        XCTAssertTrue(vc.availableActivities.isEmpty)
        let cell = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(cell.textLabel.text, "No sharing services are available.")
    }

    func testExcludedTypesAreDropped() {
        let a = TestActivity(title: "Save")
        let vc = UIActivityViewController(activityItems: ["x"], applicationActivities: [a])
        vc.excludedActivityTypes = [UIActivity.ActivityType("test.Save")]
        XCTAssertTrue(vc.availableActivities.isEmpty)
    }
}
