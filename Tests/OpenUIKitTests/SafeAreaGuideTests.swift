// Safe area / UILayoutGuide tests. Owner: autolayout module (controls2).
//
// Every expectation here is a MEASURED value from the real-UIKit probe
// recorded in Sources/OpenUIKit/AutoLayout/UILayoutGuide.swift's header
// (Mac Catalyst iOS 26.1, offscreen). The probe forces a root view's
// safeAreaInsets and reads what UIKit computes for descendants; these tests
// replay the nine propagation frames and the guide/margin results verbatim.

import XCTest
@testable import OpenUIKit

@MainActor
final class SafeAreaPropagationTests: XCTestCase {

    /// Parent 320x480 with insets (44, 10, 34, 12); nine child frames, and
    /// the insets real UIKit reported for each.
    func testMeasuredPropagationSweep() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        root._setSafeAreaInsets(UIEdgeInsets(top: 44, left: 10, bottom: 34, right: 12))

        let cases: [(CGRect, UIEdgeInsets)] = [
            (CGRect(x: 0, y: 0, width: 320, height: 480),
             UIEdgeInsets(top: 44, left: 10, bottom: 34, right: 12)),
            (CGRect(x: 30, y: 20, width: 100, height: 500),
             UIEdgeInsets(top: 24, left: 0, bottom: 34, right: 0)),
            (CGRect(x: -40, y: -60, width: 200, height: 200),
             UIEdgeInsets(top: 44, left: 10, bottom: 0, right: 0)),
            (CGRect(x: 0, y: 100, width: 320, height: 200),
             UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 12)),
            (CGRect(x: 0, y: 460, width: 320, height: 100),
             UIEdgeInsets(top: 0, left: 10, bottom: 34, right: 12)),
            (CGRect(x: 300, y: 0, width: 100, height: 480),
             UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 12)),
            (CGRect(x: -50, y: -50, width: 500, height: 700),
             UIEdgeInsets(top: 44, left: 10, bottom: 34, right: 12)),
            (CGRect(x: 5, y: 10, width: 60, height: 20),
             UIEdgeInsets(top: 34, left: 5, bottom: 0, right: 0)),
            (CGRect(x: 0, y: 500, width: 100, height: 50),
             UIEdgeInsets(top: 0, left: 10, bottom: 34, right: 0)),
        ]
        for (frame, expected) in cases {
            let child = UIView(frame: frame)
            root.addSubview(child)
            root.layoutIfNeeded()
            XCTAssertEqual(child.safeAreaInsets, expected, "child \(frame)")
            child.removeFromSuperview()
        }
    }

    func testSafeAreaLayoutGuideIsBoundsInsetByInsets() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        root._setSafeAreaInsets(UIEdgeInsets(top: 44, left: 10, bottom: 34, right: 12))
        root.layoutIfNeeded()
        XCTAssertEqual(root.safeAreaLayoutGuide.layoutFrame,
                       CGRect(x: 10, y: 44, width: 298, height: 402))
    }

    /// A view pinned to the safe-area guide lands exactly on the measured
    /// guide rect (the probe's box: (10, 44, 298, 402)).
    func testPinningToSafeAreaGuideSolves() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        root._setSafeAreaInsets(UIEdgeInsets(top: 44, left: 10, bottom: 34, right: 12))
        let box = UIView()
        box.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(box)
        let g = root.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            box.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            box.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            box.topAnchor.constraint(equalTo: g.topAnchor),
            box.bottomAnchor.constraint(equalTo: g.bottomAnchor),
        ])
        root.layoutIfNeeded()
        XCTAssertEqual(box.frame, CGRect(x: 10, y: 44, width: 298, height: 402))
    }

    func testSafeAreaInsetsDidChangeFires() {
        @MainActor
        final class Watcher: UIView {
            var log: [String] = []
            override func safeAreaInsetsDidChange() { log.append("safe") }
            override func layoutMarginsDidChange() { log.append("margins") }
        }
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let child = Watcher(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        root.addSubview(child)
        root._setSafeAreaInsets(UIEdgeInsets(top: 44, left: 10, bottom: 34, right: 12))
        root.layoutIfNeeded()
        // Measured ordering: margins first, then the safe area.
        XCTAssertEqual(child.log, ["margins", "safe"])
        XCTAssertEqual(child.safeAreaInsets,
                       UIEdgeInsets(top: 44, left: 10, bottom: 34, right: 12))
        child.log = []
        root.layoutIfNeeded()
        XCTAssertEqual(child.log, [], "a settled safe area must not re-notify")
    }

    func testAdditionalSafeAreaInsetsAddToTheInherited() {
        let vc = UIViewController()
        vc.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        let window = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window._setSafeAreaInsets(UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        window.addSubview(vc.view)
        vc.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 0, bottom: 6, right: 0)
        window.layoutIfNeeded()
        XCTAssertEqual(vc.view.safeAreaInsets,
                       UIEdgeInsets(top: 69, left: 0, bottom: 40, right: 0))
    }
}

@MainActor
final class LayoutMarginsTests: XCTestCase {

    func testDefaultMarginsAreEightAllRound() {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 200))
        XCTAssertEqual(v.layoutMargins, UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
    }

    /// Measured: base 8 under safe (44, 10, 34, 12) -> (52, 18, 42, 20).
    func testMarginsAreBasePlusSafeArea() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let child = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        root.addSubview(child)
        root._setSafeAreaInsets(UIEdgeInsets(top: 44, left: 10, bottom: 34, right: 12))
        root.layoutIfNeeded()
        XCTAssertEqual(child.layoutMargins,
                       UIEdgeInsets(top: 52, left: 18, bottom: 42, right: 20))
        child.insetsLayoutMarginsFromSafeArea = false
        XCTAssertEqual(child.layoutMargins, UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
    }

    /// Measured: parent margins 20, child at (10, 10, 100, 100) in a
    /// 320x480 parent -> (10, 10, 8, 8).
    func testPreservesSuperviewLayoutMargins() {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        parent.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        let child = UIView(frame: CGRect(x: 10, y: 10, width: 100, height: 100))
        child.preservesSuperviewLayoutMargins = true
        parent.addSubview(child)
        parent.layoutIfNeeded()
        XCTAssertEqual(child.layoutMargins,
                       UIEdgeInsets(top: 10, left: 10, bottom: 8, right: 8))
    }

    func testLayoutMarginsGuideWithoutSafeArea() {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        v.layoutIfNeeded()
        XCTAssertEqual(v.layoutMarginsGuide.layoutFrame,
                       CGRect(x: 8, y: 8, width: 304, height: 464))
    }

    /// Measured 1 pt bisection: readable == the margins rect until BOTH
    /// bounds.width > 1008 and marginsWidth > 920, then a 920 pt band
    /// centred in the bounds.
    func testReadableContentGuideSweep() {
        // (boundsWidth, sideMargin, expected x, expected width)
        let expected: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (320, 8, 8, 304), (375, 8, 8, 359), (834, 8, 8, 818),
            (1000, 8, 8, 984), (1008, 8, 8, 992), (1009, 8, 44.5, 920),
            (1020, 8, 50, 920), (1024, 8, 52, 920), (1400, 8, 240, 920),
            (1008, 40, 40, 928), (1009, 40, 44.5, 920),
            (1200, 200, 200, 800), (2000, 600, 600, 800), (1200, 0, 140, 920),
        ]
        for (w, margin, x, width) in expected {
            let v = UIView(frame: CGRect(x: 0, y: 0, width: w, height: 200))
            v.layoutMargins = UIEdgeInsets(top: 8, left: margin, bottom: 8, right: margin)
            v.layoutIfNeeded()
            let r = v.readableContentGuide.layoutFrame
            XCTAssertEqual(r.origin.x, x, "w=\(w) margin=\(margin)")
            XCTAssertEqual(r.width, width, "w=\(w) margin=\(margin)")
            XCTAssertEqual(r.origin.y, 8, "w=\(w) margin=\(margin)")
            XCTAssertEqual(r.height, 184, "w=\(w) margin=\(margin)")
        }
    }
}

@MainActor
final class UILayoutGuideTests: XCTestCase {

    /// A custom guide is a first-class solver item: it is positioned by the
    /// app's constraints and views can pin to it (probe F: guide
    /// (4, 68, 120, 40), the pinned box identical).
    func testCustomGuideIsSolvedAndViewsPinToIt() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        root._setSafeAreaInsets(UIEdgeInsets(top: 44, left: 10, bottom: 34, right: 12))
        let safe = root.safeAreaLayoutGuide
        let top = UIView()
        top.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(top)
        NSLayoutConstraint.activate([
            top.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            top.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            top.topAnchor.constraint(equalTo: safe.topAnchor),
            top.heightAnchor.constraint(equalToConstant: 60),
        ])
        let guide = UILayoutGuide()
        guide.identifier = "custom"
        root.addLayoutGuide(guide)
        let box = UIView()
        box.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(box)
        NSLayoutConstraint.activate([
            guide.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 8),
            guide.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 4),
            guide.widthAnchor.constraint(equalToConstant: 120),
            guide.heightAnchor.constraint(equalToConstant: 40),
            box.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            box.topAnchor.constraint(equalTo: guide.topAnchor),
            box.widthAnchor.constraint(equalTo: guide.widthAnchor),
            box.heightAnchor.constraint(equalTo: guide.heightAnchor),
        ])
        root.layoutIfNeeded()
        XCTAssertEqual(top.frame, CGRect(x: 10, y: 44, width: 298, height: 60))
        XCTAssertEqual(guide.layoutFrame, CGRect(x: 14, y: 112, width: 120, height: 40))
        XCTAssertEqual(box.frame, guide.layoutFrame)
    }

    func testUnreferencedCustomGuideStaysZero() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let g = UILayoutGuide()
        root.addLayoutGuide(g)
        root.layoutIfNeeded()
        XCTAssertEqual(g.layoutFrame, .zero)
        XCTAssertEqual(root.layoutGuides.count, 1)
        root.removeLayoutGuide(g)
        XCTAssertTrue(root.layoutGuides.isEmpty)
        XCTAssertNil(g.owningView)
    }
}
