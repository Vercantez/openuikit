import XCTest
@testable import OpenUIKit

// UIToolbar height rule. Every number is a row of
// Tools/oracle2/toolbarheightprobe/ios-26.1-{iphone16,se,ipad}.json
// (iOS 26.1 simulator, 2026-09-10; report:
// docs/agent_reports/toolbar-intrinsic-height.md). The port carried 54,
// which was the frame fixtures/scenes/toolbar_basic.json hands the bar,
// not a measurement.

/// Run `body` under the iOS cut with the given device traits; restores
/// everything afterwards (the neighbouring bar suites' spelling).
@MainActor
private func withIOSDevice(idiom: UIUserInterfaceIdiom = .phone,
                           vertical: UIUserInterfaceSizeClass = .regular,
                           screen: CGSize = CGSize(width: 393, height: 852),
                           scale: CGFloat = 3,
                           _ body: () -> Void) {
    let saved = OpenUIKitRuntime.systemFontCut
    let savedIdiom = UIDevice.current.userInterfaceIdiom
    let savedTraits = UITraitCollection.current
    let savedBounds = UIScreen.main.bounds
    let savedScale = UIScreen.main.scale
    OpenUIKitRuntime.systemFontCut = .iOS
    UIDevice.current.userInterfaceIdiom = idiom
    UIScreen.main._hostConfigure(bounds: CGRect(origin: .zero, size: screen), scale: scale)
    UITraitCollection.current = UITraitCollection(
        userInterfaceStyle: .light, displayScale: scale,
        verticalSizeClass: vertical, userInterfaceIdiom: idiom)
    defer {
        OpenUIKitRuntime.systemFontCut = saved
        UIDevice.current.userInterfaceIdiom = savedIdiom
        UITraitCollection.current = savedTraits
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
    }
    body()
}

@MainActor
private func threeItems() -> [UIBarButtonItem] {
    [UIBarButtonItem(barButtonSystemItem: .add),
     UIBarButtonItem(barButtonSystemItem: .flexibleSpace),
     UIBarButtonItem(barButtonSystemItem: .done)]
}

#if !os(Linux)
@MainActor
#endif
final class ToolbarHeightTests: XCTestCase {

    // MARK: Size APIs

    /// iPhone 16 + SE portrait, every items case: `intrinsic [-1, 48]`,
    /// `sizeThatFits.w0 [393, 48]`, `sizeThatFits.zero [0, 48]` (detached).
    /// The `cold.*` rows (no window yet) read 48 too, so the classic cut
    /// gets the same number.
    func testIntrinsicAndSizeThatFitsAre48OnPhone() {
        for cut in [FontEngine.SystemFontCut.macOS, .iOS] {
            let saved = OpenUIKitRuntime.systemFontCut
            OpenUIKitRuntime.systemFontCut = cut
            defer { OpenUIKitRuntime.systemFontCut = saved }
            // (The transcript also covers UIBarStyle .black: no number moves.
            // The port declares no UIBarStyle and no ladder app reads one.)
            for items in [nil, threeItems()] {
                let tb = UIToolbar(frame: CGRect(x: 0, y: 100, width: 393, height: 44))
                tb.items = items
                XCTAssertEqual(tb.intrinsicContentSize.height, 48, "\(cut)")
                XCTAssertEqual(tb.intrinsicContentSize.width, UIView.noIntrinsicMetric)
                XCTAssertEqual(tb.sizeThatFits(CGSize(width: 393, height: 0)),
                               CGSize(width: 393, height: 48))
                XCTAssertEqual(tb.sizeThatFits(.zero).height, 48)
            }
        }
        XCTAssertEqual(UIToolbar.defaultHeight, 48)
    }

    /// iPad A16, both orientations: `cold.intrinsic [-1, 44]`, every
    /// hosted/detached row 44 with or without items.
    func testIntrinsicAndSizeThatFitsAre44OnPad() {
        withIOSDevice(idiom: .pad, screen: CGSize(width: 820, height: 1180), scale: 2) {
            for items in [nil, threeItems()] {
                let tb = UIToolbar()
                tb.items = items
                XCTAssertEqual(tb.intrinsicContentSize.height, 44)
                XCTAssertEqual(tb.sizeThatFits(CGSize(width: 820, height: 0)).height, 44)
            }
            XCTAssertEqual(UIToolbar.defaultHeight, 44)
        }
    }

    /// `autoLayout.*.viewBottom.frame [0, 804, 393, 48]`, `safeAreaBottom
    /// [0, 770, 393, 48]` (iPhone 16 portrait, SA [59, 0, 34, 0]); iPad
    /// `[0, 1136, 820, 44]` / `[0, 1111, 820, 44]` (SA [32, 0, 25, 0]).
    func testAutoLayoutBottomPinnedBarLaysOutAtItsIntrinsicHeight() {
        let cases: [(UIUserInterfaceIdiom, CGSize, UIEdgeInsets, CGFloat)] = [
            (.phone, CGSize(width: 393, height: 852), UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0), 48),
            (.pad, CGSize(width: 820, height: 1180), UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0), 44),
        ]
        for (idiom, screen, sa, h) in cases {
            withIOSDevice(idiom: idiom, screen: screen, scale: idiom == .pad ? 2 : 3) {
                for toSafeArea in [false, true] {
                    let root = UIView(frame: CGRect(origin: .zero, size: screen))
                    root._setSafeAreaInsets(sa)
                    let tb = UIToolbar()
                    tb.translatesAutoresizingMaskIntoConstraints = false
                    tb.items = threeItems()
                    root.addSubview(tb)
                    let bottom = toSafeArea ? root.safeAreaLayoutGuide.bottomAnchor : root.bottomAnchor
                    NSLayoutConstraint.activate([
                        tb.leadingAnchor.constraint(equalTo: root.leadingAnchor),
                        tb.trailingAnchor.constraint(equalTo: root.trailingAnchor),
                        tb.bottomAnchor.constraint(equalTo: bottom),
                    ])
                    root.layoutIfNeeded()
                    let y = screen.height - (toSafeArea ? sa.bottom : 0) - h
                    XCTAssertEqual(tb.frame, CGRect(x: 0, y: y, width: screen.width, height: h),
                                   "\(idiom) toSafeArea=\(toSafeArea)")
                }
            }
        }
    }

    // MARK: Platter row

    /// `frame.default.items.hosted44.tree` `_UIInheritedView [16, -2, 361, 48]`,
    /// `hosted54` `[16, 0, 361, 48]`, `hosted64` `[16, 0, 361, 48]`,
    /// `autoLayout` (48 high) `[16, 0, 361, 48]`: top-aligned once the bar
    /// is platter-high, centred when it is shorter.
    func testPlattersTopAlignedWhenBarIsPlatterHighAndCentredWhenShorter() {
        withIOSDevice {
            for (h, y): (CGFloat, CGFloat) in [(44, -2), (48, 0), (54, 0), (64, 0)] {
                let tb = UIToolbar(frame: CGRect(x: 0, y: 100, width: 393, height: h))
                tb.items = threeItems()
                tb.layoutIfNeeded()
                let first = tb.itemViews[0].frame
                XCTAssertEqual(first.minY, y, "bar \(h)")
                XCTAssertEqual(first.height, 48, "bar \(h)")
                XCTAssertEqual(first.minX, 16, "bar \(h)")
                XCTAssertEqual(tb.itemViews[2].frame.maxX, 393 - 16, "bar \(h)")
            }
        }
    }

    /// SE landscape (667 × 375, compact height): `hosted54.tree`
    /// `_UIInheritedView [20, 0, 627, 44]` — platters 44, margin 20. The
    /// direct `intrinsic` read is 44 there, but `autoLayout.*.frame` and
    /// `autoLayout.deferred.viewDidLoad.viewBottom` stay `[0, 327, 667, 48]`
    /// (UIKit keeps the cold 48 until invalidateIntrinsicContentSize); the
    /// port reports the laid-out 48.
    func testCompactHeightPlattersAre44WithMargin20AndIntrinsicStays48() {
        withIOSDevice(vertical: .compact, screen: CGSize(width: 667, height: 375), scale: 2) {
            let tb = UIToolbar(frame: CGRect(x: 0, y: 100, width: 667, height: 54))
            tb.items = threeItems()
            tb.layoutIfNeeded()
            XCTAssertEqual(tb.itemViews[0].frame, CGRect(x: 20, y: 0, width: 44, height: 44))
            XCTAssertEqual(tb.itemViews[2].frame.maxX, 667 - 20)
            XCTAssertEqual(tb.intrinsicContentSize.height, 48)
            XCTAssertEqual(_UIBarMetrics.toolbarPlatterHeightForCurrentTraits, 44)
            XCTAssertEqual(_UIBarMetrics.toolbarSideMarginForCurrentTraits, 20)
        }
    }

    /// iPad A16 `hosted54.tree` `_UIInheritedView [20, 0, 780, 44]`; the
    /// Tabs-ipad golden's `UIToolbar [0, 96, 820, 54]` carries the same row.
    func testPadPlattersAre44WithMargin20() {
        withIOSDevice(idiom: .pad, screen: CGSize(width: 820, height: 1180), scale: 2) {
            let tb = UIToolbar(frame: CGRect(x: 0, y: 96, width: 820, height: 54))
            tb.items = threeItems()
            tb.layoutIfNeeded()
            XCTAssertEqual(tb.itemViews[0].frame, CGRect(x: 20, y: 0, width: 44, height: 44))
            XCTAssertEqual(tb.itemViews[2].frame.maxX, 820 - 20)
        }
    }

    // MARK: UINavigationController-managed slot

    private func makeNav(size: CGSize, safeArea: UIEdgeInsets, items: [UIBarButtonItem]?)
        -> (UINavigationController, UIViewController) {
        let vc = UIViewController()
        vc.title = "Root"
        vc.toolbarItems = items
        let nav = UINavigationController(rootViewController: vc)
        nav.view.frame = CGRect(origin: .zero, size: size)
        nav.view._setSafeAreaInsets(safeArea)
        nav.setToolbarHidden(false, animated: false)
        nav.view.layoutIfNeeded()
        return (nav, vc)
    }

    /// iPhone 16 portrait `navigation.default.items`: slot
    /// `_UIInheritedView [0, 766, 393, 86]`, platters `[28, 776, 337, 48]`
    /// (first glass platter `[28, 776, 48, 48]`), `rootViewFrame
    /// [0, 0, 393, 852]`, `rootSafeArea [113, 0, 86, 0]`.
    func testNavigationToolbarSlotIs86OnPhonePortrait() {
        withIOSDevice {
            let (nav, vc) = makeNav(size: CGSize(width: 393, height: 852),
                                    safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
                                    items: threeItems())
            XCTAssertEqual(nav.toolbar.frame, CGRect(x: 0, y: 766, width: 393, height: 86))
            let first = nav.toolbar.itemViews[0]
            XCTAssertEqual(first.frame, CGRect(x: 28, y: 10, width: 48, height: 48))
            XCTAssertEqual(nav.toolbar.convert(first.frame, to: nav.view),
                           CGRect(x: 28, y: 776, width: 48, height: 48))
            XCTAssertEqual(nav.toolbar.itemViews[2].frame.maxX, 393 - 28)
            XCTAssertEqual(vc.view.frame, CGRect(x: 0, y: 0, width: 393, height: 852))
            XCTAssertEqual(vc.view.safeAreaInsets.bottom, 86)
            XCTAssertEqual(vc.view.safeAreaInsets.top, 113)
        }
    }

    /// `navigation.default.noItems` (iPhone 16): no bottom views at all,
    /// `rootSafeArea [113, 0, 34, 0]` — `isToolbarHidden = false` with nil
    /// `toolbarItems` takes no slot. Giving the top controller items brings
    /// the 86 pt slot back.
    func testNavigationToolbarWithoutItemsTakesNoSlot() {
        withIOSDevice {
            let (nav, vc) = makeNav(size: CGSize(width: 393, height: 852),
                                    safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
                                    items: nil)
            XCTAssertFalse(nav.isToolbarHidden)
            XCTAssertEqual(nav.toolbarHeight, 0)
            XCTAssertEqual(nav.toolbar.frame.minY, 852)
            XCTAssertEqual(vc.view.safeAreaInsets.bottom, 34)

            vc.toolbarItems = threeItems()
            nav.view.layoutIfNeeded()
            XCTAssertEqual(nav.toolbar.frame, CGRect(x: 0, y: 766, width: 393, height: 86))
            XCTAssertEqual(vc.view.safeAreaInsets.bottom, 86)

            vc.toolbarItems = []
            nav.view.layoutIfNeeded()
            XCTAssertEqual(nav.toolbarHeight, 0)
            XCTAssertEqual(vc.view.safeAreaInsets.bottom, 34)
        }
    }

    /// SE landscape `navigation.default.items`: slot `[0, 293, 667, 82]`,
    /// platters `[28, 303, 611, 44]`, `rootSafeArea [78, 0, 82, 0]`.
    /// (iPhone 16 landscape is the same 82 with the 59 pt side insets:
    /// slot `[59, 311, 734, 82]`, platters `[87, 321, 678, 44]`.)
    func testNavigationToolbarSlotIs82AtCompactHeight() {
        withIOSDevice(vertical: .compact, screen: CGSize(width: 667, height: 375), scale: 2) {
            let (nav, vc) = makeNav(size: CGSize(width: 667, height: 375),
                                    safeArea: .zero, items: threeItems())
            XCTAssertEqual(nav.toolbar.frame, CGRect(x: 0, y: 293, width: 667, height: 82))
            XCTAssertEqual(nav.toolbar.itemViews[0].frame, CGRect(x: 28, y: 10, width: 44, height: 44))
            XCTAssertEqual(nav.toolbar.itemViews[2].frame.maxX, 667 - 28)
            XCTAssertEqual(vc.view.safeAreaInsets.bottom, 82)
        }
        withIOSDevice(vertical: .compact, screen: CGSize(width: 852, height: 393), scale: 3) {
            let (nav, vc) = makeNav(size: CGSize(width: 852, height: 393),
                                    safeArea: UIEdgeInsets(top: 0, left: 59, bottom: 20, right: 59),
                                    items: threeItems())
            XCTAssertEqual(nav.toolbar.frame, CGRect(x: 0, y: 311, width: 852, height: 82))
            XCTAssertEqual(nav.toolbar.itemViews[0].frame, CGRect(x: 87, y: 10, width: 44, height: 44))
            XCTAssertEqual(vc.view.safeAreaInsets.bottom, 82)
        }
    }

    /// iPad A16 `navigation.default.items` (either orientation): slot
    /// `[0, 1101, 820, 79]`, platters `[10, 1111, 800, 44]` (first glass
    /// platter `[10, 1111, 44, 44]`), `rootSafeArea [86, 0, 79, 0]`.
    func testNavigationToolbarSlotIs79OnPad() {
        withIOSDevice(idiom: .pad, screen: CGSize(width: 820, height: 1180), scale: 2) {
            let (nav, vc) = makeNav(size: CGSize(width: 820, height: 1180),
                                    safeArea: UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0),
                                    items: threeItems())
            XCTAssertEqual(nav.toolbar.frame, CGRect(x: 0, y: 1101, width: 820, height: 79))
            XCTAssertEqual(nav.toolbar.itemViews[0].frame, CGRect(x: 10, y: 10, width: 44, height: 44))
            XCTAssertEqual(nav.toolbar.itemViews[2].frame.maxX, 820 - 10)
            XCTAssertEqual(vc.view.safeAreaInsets.bottom, 79)
        }
    }

    /// `_UIBarMetrics` table the rules above are built from.
    func testSlotMetricsTable() {
        withIOSDevice {
            XCTAssertEqual(_UIBarMetrics.toolbarSlotHeight, 86)
            XCTAssertEqual(_UIBarMetrics.toolbarSlotSideInset, 28)
        }
        withIOSDevice(vertical: .compact, screen: CGSize(width: 667, height: 375), scale: 2) {
            XCTAssertEqual(_UIBarMetrics.toolbarSlotHeight, 82)
        }
        withIOSDevice(idiom: .pad, screen: CGSize(width: 820, height: 1180), scale: 2) {
            XCTAssertEqual(_UIBarMetrics.toolbarSlotHeight, 79)
            XCTAssertEqual(_UIBarMetrics.toolbarSlotSideInset, 10)
        }
        // Same slot the bottom search dock already carried (Ledger t200).
        withIOSDevice {
            XCTAssertEqual(_UIBarMetrics.toolbarSlotHeight, UISearchBar.BottomDock.slotHeight)
        }
    }
}
