// M12 alerts cluster: UIAlertController action model + measured layout,
// UIPresentationController callback ordering, and a custom
// UIViewControllerAnimatedTransitioning round trip driven by a fake context.
//
// Every geometry number asserted here comes from Tools/oracle2/alertprobe
// dumps of real iOS 26.1 (see Sources/OpenUIKit/UIAlertController.swift);
// the alert_* fixture family locks the same numbers in against pixels.
import XCTest
import Foundation
@testable import OpenUIKit

// MARK: - Actions

#if !os(Linux)
@MainActor
#endif
final class UIAlertActionModelTests: XCTestCase {
    func testActionsKeepAddOrder() {
        let ac = UIAlertController(title: "T", message: "M", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let ok = UIAlertAction(title: "OK", style: .default)
        ac.addAction(ok)
        ac.addAction(cancel)
        // MEASURED: real UIKit's `actions` reports the ADD order even though
        // the layout moves the cancel action.
        XCTAssertEqual(ac.actions.map(\.title), ["OK", "Cancel"])
    }

    func testTwoActionsPutCancelOnTheLeft() {
        // MEASURED both ways round on real iOS: with exactly two actions the
        // cancel one is always the LEADING pill.
        for addCancelFirst in [true, false] {
            let ac = UIAlertController(title: "T", message: "M", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            let other = UIAlertAction(title: "Delete", style: .destructive)
            if addCancelFirst { ac.addAction(cancel); ac.addAction(other) }
            else { ac.addAction(other); ac.addAction(cancel) }
            XCTAssertEqual(ac._layoutOrderedActions.map(\.title), ["Cancel", "Delete"],
                           "cancel-first=\(addCancelFirst)")
            ac._layoutCard(width: UIAlertMetrics.cardWidth)
            let pills = ac.view.subviews.compactMap { $0 as? _UIAlertActionView }
            let cancelPill = pills.first { $0.action === cancel }!
            let otherPill = pills.first { $0.action === other }!
            XCTAssertLessThan(cancelPill.frame.minX, otherPill.frame.minX)
            XCTAssertEqual(cancelPill.frame.minY, otherPill.frame.minY)
        }
    }

    func testThreeActionsStackVerticallyWithCancelLast() {
        for addCancelFirst in [true, false] {
            let ac = UIAlertController(title: "Order", message: "M", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            if addCancelFirst { ac.addAction(cancel) }
            ac.addAction(UIAlertAction(title: "One", style: .default))
            ac.addAction(UIAlertAction(title: "Two", style: .default))
            if !addCancelFirst { ac.addAction(cancel) }
            XCTAssertEqual(ac._layoutOrderedActions.map(\.title), ["One", "Two", "Cancel"])
            ac._layoutCard(width: UIAlertMetrics.cardWidth)
            let pills = ac.view.subviews.compactMap { $0 as? _UIAlertActionView }
            XCTAssertEqual(pills.count, 3)
            // Vertical stack: same x, 48 pt tall, 8 pt apart.
            XCTAssertEqual(Set(pills.map(\.frame.minX)).count, 1)
            let ys = pills.map(\.frame.minY).sorted()
            XCTAssertEqual(ys[1] - ys[0], UIAlertMetrics.actionHeight + UIAlertMetrics.actionSpacing,
                           accuracy: 1e-9)
            XCTAssertEqual(ys[2] - ys[1], UIAlertMetrics.actionHeight + UIAlertMetrics.actionSpacing,
                           accuracy: 1e-9)
            let cancelPill = pills.first { $0.action === cancel }!
            XCTAssertEqual(cancelPill.frame.minY, ys[2], accuracy: 1e-9)
        }
    }

    func testDestructiveAndPreferredStyling() {
        let ac = UIAlertController(title: "T", message: "M", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let send = UIAlertAction(title: "Send", style: .default)
        let nuke = UIAlertAction(title: "Delete", style: .destructive)
        ac.addAction(cancel); ac.addAction(send); ac.addAction(nuke)
        ac.preferredAction = send
        ac._layoutCard(width: UIAlertMetrics.cardWidth)
        let pills = ac.view.subviews.compactMap { $0 as? _UIAlertActionView }
        let sendPill = pills.first { $0.action === send }!
        let nukePill = pills.first { $0.action === nuke }!
        let cancelPill = pills.first { $0.action === cancel }!
        // MEASURED: preferred = filled tint pill + semibold WHITE title.
        XCTAssertTrue(sendPill.isPreferred)
        XCTAssertEqual(sendPill.label.font, UIAlertMetrics.preferredActionFont)
        // MEASURED: destructive titles are systemRed, everything else `label`
        // (NOT tint blue — that changed in iOS 26).
        XCTAssertEqual(nukePill.label.textColor, UIColor.systemRed)
        XCTAssertEqual(cancelPill.label.textColor, UIColor.label)
        XCTAssertEqual(cancelPill.label.font, UIAlertMetrics.actionFont)
    }

    func testDisabledActionDimsAndSwallowsTaps() {
        var fired = false
        let ac = UIAlertController(title: "T", message: "M", preferredStyle: .alert)
        let a = UIAlertAction(title: "OK", style: .default) { _ in fired = true }
        a.isEnabled = false
        ac.addAction(a)
        ac._layoutCard(width: UIAlertMetrics.cardWidth)
        let pill = ac.view.subviews.compactMap { $0 as? _UIAlertActionView }.first!
        XCTAssertFalse(pill.isEnabled)
        XCTAssertEqual(pill.label.textColor, UIColor.tertiaryLabel)
        ac._perform(a)
        XCTAssertFalse(fired)
    }

    func testAddTextFieldOnlyOnAlertStyle() {
        let alert = UIAlertController(title: "T", message: "M", preferredStyle: .alert)
        XCTAssertNil(alert.textFields)
        alert.addTextField { $0.placeholder = "Name" }
        XCTAssertEqual(alert.textFields?.count, 1)
        XCTAssertEqual(alert.textFields?.first?.placeholder, "Name")

        let sheet = UIAlertController(title: "T", message: "M", preferredStyle: .actionSheet)
        sheet.addTextField()
        XCTAssertNil(sheet.textFields, "UIKit ignores addTextField on an action sheet")
    }
}

// MARK: - Measured layout

#if !os(Linux)
@MainActor
#endif
final class UIAlertLayoutTests: XCTestCase {
    private func card(_ title: String?, _ message: String?,
                      _ actions: [(String, UIAlertAction.Style)],
                      style: UIAlertController.Style = .alert) -> (UIAlertController, CGFloat) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: style)
        for (t, s) in actions { ac.addAction(UIAlertAction(title: t, style: s)) }
        return (ac, ac._layoutCard(width: UIAlertMetrics.cardWidth))
    }

    /// Card heights read off the real-iOS probe dumps
    /// (Tools/oracle2/alertprobe, iPhone 16 / iOS 26.1).
    func testMeasuredCardHeights() {
        let third = 1.0 / 3.0
        // title + 1-line message + 1 action  -> 152.333
        XCTAssertEqual(card("Saved", "Your changes were saved.",
                            [("OK", .default)]).1, 152 + third, accuracy: 1e-6)
        // title only + 1 action              -> 126.333
        XCTAssertEqual(card("Title only", nil, [("OK", .default)]).1,
                       126 + third, accuracy: 1e-6)
        // message only + 1 action            -> 126.333 (identical: UIKit
        // renders the lone string the same way either way)
        XCTAssertEqual(card(nil, "Message only.", [("OK", .default)]).1,
                       126 + third, accuracy: 1e-6)
        // title + message + 3 actions        -> 264.333
        XCTAssertEqual(card("Choose", "Pick one option.",
                            [("First", .default), ("Second", .default),
                             ("Cancel", .cancel)]).1, 264 + third, accuracy: 1e-6)
        // action sheet, title + message + 4 actions -> 320.333 (an action
        // sheet on iPhone is laid out EXACTLY like an alert on iOS 26)
        XCTAssertEqual(card("Photo", "Choose a source for the photo.",
                            [("Take Photo", .default), ("Choose Existing", .default),
                             ("Delete", .destructive), ("Cancel", .cancel)],
                            style: .actionSheet).1, 320 + third, accuracy: 1e-6)
    }

    func testSoloLabelIsCentredAndSeventeenPointRegular() {
        // MEASURED: with only ONE of title/message, UIKit uses 17 pt REGULAR
        // and centres it; with both, 17 semibold + 15 regular, left aligned.
        let (solo, _) = card("Title only", nil, [("OK", .default)])
        let soloLabel = solo.view.subviews.compactMap { $0 as? UILabel }.first!
        XCTAssertEqual(soloLabel.font, UIAlertMetrics.soloFont)
        XCTAssertEqual(soloLabel.textAlignment, .center)

        let (both, _) = card("T", "M", [("OK", .default)])
        let labels = both.view.subviews.compactMap { $0 as? UILabel }
        XCTAssertEqual(labels.count, 2)
        XCTAssertEqual(labels[0].font, UIAlertMetrics.titleFont)
        XCTAssertEqual(labels[0].textAlignment, .left)
        XCTAssertEqual(labels[0].textColor, UIColor.label)
        XCTAssertEqual(labels[1].font, UIAlertMetrics.messageFont)
        XCTAssertEqual(labels[1].textColor, UIColor.secondaryLabel)
        XCTAssertEqual(labels[0].frame.minX, UIAlertMetrics.textInsetX, accuracy: 1e-9)
        XCTAssertEqual(labels[0].frame.width,
                       UIAlertMetrics.cardWidth - 2 * UIAlertMetrics.textInsetX, accuracy: 1e-9)
        XCTAssertEqual(labels[0].frame.minY, UIAlertMetrics.topPadding, accuracy: 1e-9)
    }

    /// MEASURED: the card is 320 wide, centred horizontally, and centred in
    /// the SAFE AREA — on a 393x852 window with insets 59/34 the card centre
    /// is 438.5, not the window centre 426.
    func testCardIsCentredInTheSafeArea() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let base = UIViewController()
        base.view.frame = window.bounds
        window.addSubview(base.view)
        let ac = UIAlertController(title: "Delete File?", message: "This cannot be undone.",
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive))
        base.present(ac, animated: false)
        let f = ac.view.frame
        XCTAssertEqual(f.width, 320, accuracy: 1e-9)
        XCTAssertEqual(f.minX, (393 - 320) / 2, accuracy: 1e-9)
        XCTAssertEqual(f.midY, 438.5, accuracy: 1e-6)
        XCTAssertEqual(f.height, 152 + 1.0 / 3.0, accuracy: 1e-6)
        XCTAssertEqual(ac.view.layer.cornerRadius, 34, accuracy: 1e-9)
    }

    func testDimAlphaMatchesAppearance() {
        for (style, expected) in [(UIUserInterfaceStyle.light, UIAlertMetrics.dimAlphaLight),
                                  (UIUserInterfaceStyle.dark, UIAlertMetrics.dimAlphaDark)] {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
            window.overrideUserInterfaceStyle = style
            let base = UIViewController()
            base.view.frame = window.bounds
            window.addSubview(base.view)
            let ac = UIAlertController(title: "T", message: "M", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            base.present(ac, animated: false)
            let pc = ac.presentationController as! _UIAlertPresentationController
            XCTAssertEqual(pc.dim.alpha, expected, accuracy: 1e-9)
        }
    }

    func testTapRunsHandlerAfterDismissal() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let base = UIViewController()
        base.view.frame = window.bounds
        window.addSubview(base.view)
        let ac = UIAlertController(title: "T", message: "M", preferredStyle: .alert)
        var presentedWhenFired = true
        let a = UIAlertAction(title: "OK", style: .default) { _ in
            presentedWhenFired = base.presentedViewController != nil
        }
        ac.addAction(a)
        base.present(ac, animated: false)
        XCTAssertNotNil(base.presentedViewController)
        ac._perform(a)
        // The dismissal is animated, so it finishes on the host clock.
        OpenUIKitRuntime.animationTime = UIAlertMetrics.transitionDuration + 0.01
        UIView._stepAnimationCompletions(to: OpenUIKitRuntime.animationTime)
        OpenUIKitRuntime.animationTime = 0
        // UIKit dismisses first, THEN runs the handler.
        XCTAssertNil(base.presentedViewController)
        XCTAssertFalse(presentedWhenFired)
    }

    /// MEASURED Modal t5200, iPhone SE 2x / iOS 26.1, window SA [0,0,0,0]:
    /// the 320×264 alert card is at y 201.5 — centred on the 667-pt window,
    /// not the iPhone-16 59/34 safe band (that path sits at y 213.833).
    func testAlertCentersInSEWindowOnIOS() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let base = UIViewController()
        window.rootViewController = base
        window.makeKeyAndVisible()
        let ac = UIAlertController(title: "Save changes?",
                                   message: "This cannot be undone.",
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default))
        ac.addAction(UIAlertAction(title: "Discard", style: .destructive))
        base.present(ac, animated: false)
        let frame = ac.view.frame
        XCTAssertEqual(frame.width, 320, accuracy: 1e-9)
        XCTAssertEqual(frame.minX, 27.5, accuracy: 1e-9)
        XCTAssertEqual(frame.midY, 333.5, accuracy: 0.5)
        XCTAssertEqual(frame.minY, 201.5, accuracy: 0.5)
    }
}
