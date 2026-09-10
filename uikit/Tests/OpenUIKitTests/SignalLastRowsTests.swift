// Signal-iOS's last four blocking UIKit rows, each asserted from the iOS 26.1
// oracle transcript Tools/oracle2/signallastrowsprobe/ios-26.1-iphone16.json
// (iPad (A16) transcript identical for every fact asserted here).
import XCTest
@testable import OpenUIKit

private typealias CALayer = OpenUIKit.CALayer

// MARK: - UITab / UITabBarController.tabs

#if !os(Linux)
@MainActor
#endif
private final class TabsDelegate: UITabBarControllerDelegate {
    var log: [String] = []
    var allow = true
    var allowTab = true
    func tabBarController(_ c: UITabBarController, shouldSelect vc: UIViewController) -> Bool {
        log.append("shouldSelect \(vc.title ?? "")"); return allow
    }
    func tabBarController(_ c: UITabBarController, didSelect vc: UIViewController) {
        log.append("didSelect \(vc.title ?? "")")
    }
    func tabBarController(_ c: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
        log.append("shouldSelectTab \(tab.identifier) @\(c.selectedIndex)"); return allowTab
    }
    func tabBarController(_ c: UITabBarController, didSelectTab tab: UITab, previousTab: UITab?) {
        log.append("didSelectTab \(tab.identifier) prev \(previousTab?.identifier ?? "nil") @\(c.selectedIndex)")
    }
}

#if !os(Linux)
@MainActor
#endif
final class UITabTests: XCTestCase {
    private var calls: [String: Int] = [:]
    private var controllers: [String: UIViewController] = [:]

    private func tab(_ id: String, _ title: String) -> UITab {
        let vc = UIViewController(); vc.title = title
        controllers[id] = vc
        return UITab(title: title, image: nil, identifier: id) { [self] tab in
            calls[id, default: 0] += 1
            XCTAssertEqual(tab.identifier, id, "the provider receives the tab")
            return controllers[id]!
        }
    }

    private func make() -> (UITabBarController, TabsDelegate, [UITab]) {
        let tbc = UITabBarController()
        let d = TabsDelegate()
        tbc.delegate = d
        let tabs = [tab("chats", "Chats"), tab("calls", "Calls"), tab("stories", "Stories")]
        return (tbc, d, tabs)
    }

    func testProviderIsLazyRunsOnceAndStampsTheController() {
        let t = tab("chats", "Chats")
        XCTAssertEqual(calls["chats"] ?? 0, 0, "measured: nothing at init")
        XCTAssertEqual(t.badgeValue, nil)
        XCTAssertEqual(t.preferredPlacement, .automatic)
        XCTAssertFalse(t.isHidden); XCTAssertTrue(t.isEnabled); XCTAssertFalse(t.allowsHiding)
        XCTAssertFalse(t.hasVisiblePlacement, "measured false until attached")
        XCTAssertNil(t.tabBarController)
        let vc = t.viewController
        XCTAssertEqual(calls["chats"], 1)
        XCTAssertTrue(vc === controllers["chats"])
        XCTAssertTrue(vc?.tab === t, "measured `vcTabIsSelf` before any controller")
        _ = t.viewController
        XCTAssertEqual(calls["chats"], 1, "measured: the provider runs once")
        t.accessibilityValue = "3 unread"
        XCTAssertEqual(t.accessibilityValue, "3 unread")
    }

    func testTabsAssignmentBeforeViewLoadMirrorsItemsAndReportsSelection() {
        let (tbc, d, tabs) = make()
        tabs[0].badgeValue = "3"
        tbc.tabs = tabs
        XCTAssertEqual(calls, ["chats": 1, "calls": 1, "stories": 1], "measured: every provider runs at `tabs =`")
        XCTAssertNil(tbc.viewControllers, "measured `viewControllersNil` true under the tabs API")
        XCTAssertEqual(tbc.tabBar.items?.map { $0.title ?? "nil" }, ["Chats", "Calls", "Stories"])
        XCTAssertEqual(tbc.tabBar.items?.map { $0.badgeValue ?? "nil" }, ["3", "nil", "nil"])
        XCTAssertEqual(tbc.tabBar.items?.map { $0.tag }, [0, 0, 0])
        XCTAssertEqual(tbc.selectedIndex, 0)
        XCTAssertTrue(tbc.selectedTab === tabs[0])
        XCTAssertTrue(tbc.selectedViewController === controllers["chats"])
        XCTAssertEqual(d.log, ["didSelectTab chats prev nil @0"])
        XCTAssertTrue(tabs[0].tabBarController === tbc)
        XCTAssertTrue(tabs[0].hasVisiblePlacement)
        XCTAssertTrue(controllers["chats"]?.tabBarItem === tbc.tabBar.items?[0], "one item object per tab")
        d.log = []
        tbc.loadViewIfNeeded()
        XCTAssertEqual(d.log, [], "measured: nothing fires when the view appears")
        XCTAssertTrue(tbc.tabBar.selectedItem === tbc.tabBar.items?[0])
    }

    func testBadgeAndTitlePropagateTabToItemOnly() {
        let (tbc, _, tabs) = make()
        tbc.tabs = tabs
        tabs[1].badgeValue = "7"
        XCTAssertEqual(tbc.tabBar.items?[1].badgeValue, "7")
        XCTAssertEqual(controllers["calls"]?.tabBarItem?.badgeValue, "7")
        controllers["calls"]?.tabBarItem?.badgeValue = "9"
        XCTAssertEqual(tabs[1].badgeValue, "7", "measured: item → tab does not propagate")
        tabs[1].badgeValue = nil
        XCTAssertNil(tbc.tabBar.items?[1].badgeValue)
        tabs[1].title = "Calls2"
        XCTAssertEqual(tbc.tabBar.items?[1].title, "Calls2")
        XCTAssertEqual(controllers["calls"]?.title, "Calls", "measured: the controller's title is untouched")
    }

    func testProgrammaticSelectionFiresOnlyDidSelectTab() {
        let (tbc, d, tabs) = make()
        tbc.tabs = tabs
        tbc.loadViewIfNeeded()
        d.log = []
        tbc.selectedTab = tabs[1]
        XCTAssertEqual(tbc.selectedIndex, 1)
        XCTAssertTrue(tbc.selectedViewController === controllers["calls"])
        XCTAssertEqual(d.log, ["didSelectTab calls prev chats @1"])
        d.log = []
        tbc.selectedIndex = 2
        XCTAssertTrue(tbc.selectedTab === tabs[2])
        XCTAssertEqual(d.log, ["didSelectTab stories prev calls @2"])
        d.log = []
        tbc.selectedViewController = controllers["chats"]
        XCTAssertEqual(tbc.selectedIndex, 0)
        XCTAssertEqual(d.log, ["didSelectTab chats prev stories @0"])
    }

    func testUserTapConsultsTheTabPairOnly() {
        let (tbc, d, tabs) = make()
        tbc.tabs = tabs
        tbc.loadViewIfNeeded()
        d.log = []
        tbc.tabBar(tbc.tabBar, didSelect: tbc.tabBar.items![1])
        XCTAssertEqual(d.log, ["shouldSelectTab calls @0", "didSelectTab calls prev chats @1"])
        d.log = []
        tbc.tabBar(tbc.tabBar, didSelect: tbc.tabBar.items![1])
        XCTAssertEqual(d.log, ["shouldSelectTab calls @1", "didSelectTab calls prev calls @1"],
                       "measured: a re-tap reports again with previous == tab")
        d.log = []
        d.allowTab = false
        tbc.tabBar(tbc.tabBar, didSelect: tbc.tabBar.items![2])
        XCTAssertEqual(d.log, ["shouldSelectTab stories @1"])
        XCTAssertEqual(tbc.selectedIndex, 1, "vetoed")
        d.log = []
        d.allowTab = true
        d.allow = false
        tbc.tabBar(tbc.tabBar, didSelect: tbc.tabBar.items![2])
        XCTAssertEqual(tbc.selectedIndex, 2, "measured: the legacy shouldSelect is not consulted")
        XCTAssertEqual(d.log, ["shouldSelectTab stories @1", "didSelectTab stories prev calls @2"])
    }

    func testSubsetRestoreAndEmptyTabs() {
        let (tbc, d, tabs) = make()
        tbc.tabs = tabs
        tbc.loadViewIfNeeded()
        tbc.selectedTab = tabs[2]
        d.log = []
        tbc.tabs = [tabs[0], tabs[1]]
        XCTAssertEqual(tbc.selectedIndex, 0)
        XCTAssertTrue(tbc.selectedTab === tabs[0])
        XCTAssertEqual(d.log, ["didSelectTab chats prev stories @0"])
        XCTAssertNil(tabs[2].tabBarController)
        XCTAssertEqual(tbc.tabBar.items?.count, 2)
        d.log = []
        tbc.tabs = tabs
        XCTAssertEqual(calls["stories"], 1, "measured: the provider is not re-run")
        XCTAssertTrue(tabs[2].viewController === controllers["stories"])
        XCTAssertEqual(d.log, [], "measured: the surviving selection reports nothing")
        XCTAssertEqual(tbc.tabBar.items?.count, 3)
        tbc.tabs = []
        XCTAssertEqual(tbc.selectedIndex, Int.max, "NSNotFound")
        XCTAssertEqual(tbc.tabBar.items?.count, 0)
        XCTAssertNotNil(tbc.tabBar.items, "measured: [] not nil")
        XCTAssertTrue(tbc.selectedTab === tabs[0], "measured: stale selection kept")
    }

    func testLegacyViewControllersAfterTabsAndBack() {
        let (tbc, d, tabs) = make()
        tbc.tabs = tabs
        tbc.loadViewIfNeeded()
        let la = UIViewController(); la.title = "LegacyA"
        la.tabBarItem = UITabBarItem(title: "LA", image: nil, tag: 10)
        let lb = UIViewController(); lb.title = "LegacyB"
        d.log = []
        tbc.viewControllers = [la, lb]
        XCTAssertEqual(tbc.tabs.count, 0, "measured: tabs emptied")
        XCTAssertEqual(tbc.viewControllers?.count, 2)
        XCTAssertNil(tabs[0].tabBarController)
        XCTAssertNil(la.tab)
        XCTAssertEqual(tbc.tabBar.items?.map { $0.title ?? "" }, ["LA", "LegacyB"])
        XCTAssertTrue(tbc.tabBar.items?[0] === la.tabBarItem)
        XCTAssertNil(tbc.selectedTab, "UIKit answers a private auto-generated tab; not modelled")
        tbc.tabs = tabs
        XCTAssertNil(tbc.viewControllers)
        XCTAssertNil(la.parent, "measured: legacy children leave")
        XCTAssertTrue(tabs[0].tabBarController === tbc)
        XCTAssertEqual(tbc.tabBar.items?.count, 3)
    }

    func testDelegateSpellingAlias() {
        let tbc = UITabBarController()
        let d = TabsDelegate()
        tbc.tabBarControllerDelegate = d
        XCTAssertTrue(tbc.delegate === d)
        XCTAssertEqual(tbc.mode, .automatic, "measured 0 on both devices")
    }
}

// MARK: - UINavigationBarDelegate

#if !os(Linux)
@MainActor
#endif
private final class BarDelegate: UINavigationBarDelegate {
    var log: [String] = []
    var allowPush = true, allowPop = true
    var positionCalls = 0
    var positionBar: UIBarPositioning?
    var answer: UIBarPosition = .any
    func row(_ e: String, _ item: UINavigationItem, _ b: UINavigationBar) -> String {
        "\(e) \(item.title ?? "nil") items=\(b.items.map { $0.title ?? "nil" }) top=\(b.topItem?.title ?? "nil")"
    }
    func navigationBar(_ b: UINavigationBar, shouldPush item: UINavigationItem) -> Bool { log.append(row("shouldPush", item, b)); return allowPush }
    func navigationBar(_ b: UINavigationBar, didPush item: UINavigationItem) { log.append(row("didPush", item, b)) }
    func navigationBar(_ b: UINavigationBar, shouldPop item: UINavigationItem) -> Bool { log.append(row("shouldPop", item, b)); return allowPop }
    func navigationBar(_ b: UINavigationBar, didPop item: UINavigationItem) { log.append(row("didPop", item, b)) }
    func position(for bar: UIBarPositioning) -> UIBarPosition { positionCalls += 1; positionBar = bar; return answer }
}

#if !os(Linux)
@MainActor
#endif
private final class ProbeNav: UINavigationController, UINavigationBarDelegate {
    var log: [String] = []
    var allowPop = true
    func row(_ e: String, _ item: UINavigationItem, _ b: UINavigationBar) -> String {
        "\(e) \(item.title ?? "nil") top=\(topViewController?.navigationItem === item) vcs=\(viewControllers.count) bar=\(b.items.count) own=\(b === navigationBar)"
    }
    func navigationBar(_ b: UINavigationBar, shouldPush item: UINavigationItem) -> Bool { log.append(row("shouldPush", item, b)); return true }
    func navigationBar(_ b: UINavigationBar, shouldPop item: UINavigationItem) -> Bool { log.append(row("shouldPop", item, b)); return allowPop }
    func navigationBar(_ b: UINavigationBar, didPop item: UINavigationItem) { log.append(row("didPop", item, b)) }
}

#if !os(Linux)
@MainActor
#endif
final class UINavigationBarDelegateTests: XCTestCase {
    func testStandalonePushPopOrderAndVeto() {
        let bar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 393, height: 44))
        XCTAssertNil(bar.delegate, "measured nil on a standalone bar")
        let d = BarDelegate()
        bar.delegate = d
        let a = UINavigationItem(title: "A"), b = UINavigationItem(title: "B"), c = UINavigationItem(title: "C")
        bar.pushItem(a, animated: false)
        bar.pushItem(b, animated: false)
        XCTAssertEqual(d.log, [
            "shouldPush A items=[] top=nil", "didPush A items=[\"A\"] top=A",
            "shouldPush B items=[\"A\"] top=A", "didPush B items=[\"A\", \"B\"] top=B"])
        d.log = []
        d.allowPush = false
        bar.pushItem(c, animated: false)
        XCTAssertEqual(d.log, ["shouldPush C items=[\"A\", \"B\"] top=B"])
        XCTAssertEqual(bar.items.map { $0.title! }, ["A", "B"], "vetoed push")
        d.log = []
        d.allowPush = true
        bar.pushItem(c, animated: true)
        XCTAssertEqual(d.log, ["shouldPush C items=[\"A\", \"B\"] top=B", "didPush C items=[\"A\", \"B\", \"C\"] top=C"],
                       "measured: didPush is synchronous even when animated")
        d.log = []
        d.allowPop = false
        let vetoed = bar.popItem(animated: false)
        XCTAssertTrue(vetoed === c, "measured: a vetoed pop still returns the top item")
        XCTAssertEqual(bar.items.count, 3)
        XCTAssertEqual(d.log, ["shouldPop C items=[\"A\", \"B\", \"C\"] top=C"])
        d.log = []
        d.allowPop = true
        XCTAssertTrue(bar.popItem(animated: false) === c)
        XCTAssertEqual(d.log, ["shouldPop C items=[\"A\", \"B\", \"C\"] top=C", "didPop C items=[\"A\", \"B\"] top=B"])
        d.log = []
        XCTAssertTrue(bar.popItem(animated: true) === b)
        XCTAssertTrue(bar.popItem(animated: false) === a)
        XCTAssertEqual(bar.items.count, 0)
        XCTAssertEqual(d.log.count, 4)
        d.log = []
        XCTAssertNil(bar.popItem(animated: false))
        XCTAssertEqual(d.log, [], "UIKit asks with a nil item here; not representable in Swift")
    }

    func testSetItemsReportsOnlyAnimatedSimulatedPushOrPop() {
        let bar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 393, height: 44))
        let d = BarDelegate()
        bar.delegate = d
        let a = UINavigationItem(title: "A"), b = UINavigationItem(title: "B"), c = UINavigationItem(title: "C"), e = UINavigationItem(title: "E")
        bar.setItems([a, b, c], animated: false)
        XCTAssertEqual(d.log, [], "measured: no should* and nothing when not animated")
        bar.setItems([a, b], animated: true)
        XCTAssertEqual(d.log, ["didPop C items=[\"A\", \"B\"] top=B"])
        d.log = []
        bar.setItems([a, b, e], animated: true)
        XCTAssertEqual(d.log, ["didPush E items=[\"A\", \"B\", \"E\"] top=E"])
        d.log = []
        d.allowPop = false
        bar.setItems([a], animated: false)
        XCTAssertEqual(bar.items.map { $0.title! }, ["A"], "measured: a vetoing shouldPop does not apply to setItems")
        XCTAssertEqual(d.log, [])
        bar.setItems(nil, animated: false)
        XCTAssertEqual(bar.items.count, 0, "measured: [] not nil")
    }

    func testBarPositionAndPositionForAskedOnceOnAdd() {
        let bar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 393, height: 44))
        XCTAssertEqual(bar.barPosition.rawValue, 2, "measured .top detached")
        let d = BarDelegate()
        d.answer = .topAttached
        bar.delegate = d
        XCTAssertEqual(d.positionCalls, 0)
        XCTAssertEqual(bar.barPosition.rawValue, 2, "measured: still .top while detached")
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        host.addSubview(bar)
        XCTAssertEqual(d.positionCalls, 1)
        XCTAssertTrue((d.positionBar as AnyObject) === bar)
        XCTAssertEqual(bar.barPosition.rawValue, 3)
        host.setNeedsLayout(); host.layoutIfNeeded()
        XCTAssertEqual(d.positionCalls, 1)
    }

    func testControllerManagedBarDelegateIsTheConformingController() {
        let plain = UINavigationController(rootViewController: UIViewController())
        plain.loadViewIfNeeded()
        XCTAssertNil(plain.navigationBar.delegate, "no conformance, nothing to deliver to")
        let root = UIViewController(); root.title = "Root"
        let nav = ProbeNav(rootViewController: root)
        nav.loadViewIfNeeded()
        XCTAssertTrue(nav.navigationBar.delegate === nav, "measured `barDelegateIsNav`")
    }

    func testBackTapAsksShouldPopThenPopsThenReportsDidPop() {
        let root = UIViewController(); root.title = "Root"
        let nav = ProbeNav(rootViewController: root)
        nav.loadViewIfNeeded()
        nav.view.layoutIfNeeded()
        let second = UIViewController(); second.title = "Second"
        nav.log = []
        nav.pushViewController(second, animated: false)
        XCTAssertEqual(nav.log, ["shouldPush Second top=true vcs=2 bar=1 own=true"],
                       "measured: shouldPush with the controller stack grown and the bar not yet")
        nav.log = []
        _ = nav.popViewController(animated: false)
        XCTAssertEqual(nav.log, [], "measured: a programmatic pop asks nothing")
        nav.pushViewController(second, animated: false)
        nav.log = []
        nav.allowPop = false
        nav._backButtonTapped()
        XCTAssertEqual(nav.log, ["shouldPop Second top=true vcs=2 bar=2 own=true"])
        XCTAssertEqual(nav.viewControllers.count, 2, "vetoed")
        XCTAssertEqual(nav.navigationBar.items.count, 2)
        nav.log = []
        nav.allowPop = true
        nav._backButtonTapped()
        nav.finishActiveTransition()
        XCTAssertEqual(nav.viewControllers.count, 1)
        XCTAssertEqual(nav.log.first, "shouldPop Second top=true vcs=2 bar=2 own=true")
        XCTAssertEqual(nav.log.count, 2)
        XCTAssertTrue(nav.log[1].hasPrefix("didPop Second top=false vcs=1"), "\(nav.log)")
        XCTAssertTrue(nav.topViewController === root)
    }
}

// MARK: - NSIndexPath

#if !os(Linux)
@MainActor
#endif
final class NSIndexPathTests: XCTestCase {
    func testConveniencesAndBridging() {
        let i = NSIndexPath(item: 3, section: 1)
        XCTAssertEqual(i.length, 2)
        XCTAssertEqual(i.index(atPosition: 0), 1)
        XCTAssertEqual(i.index(atPosition: 1), 3)
        XCTAssertEqual(i.section, 1)
        XCTAssertEqual(i.item, 3)
        XCTAssertEqual(i.row, 3, "measured: the same slot")
        let r = NSIndexPath(row: 4, section: 2)
        XCTAssertEqual([r.section, r.row, r.item, r.length], [2, 4, 4, 2])
        let ip = i as IndexPath
        XCTAssertEqual([ip.section, ip.item, ip.row, ip.count], [1, 3, 3, 2])
        XCTAssertEqual(ip, IndexPath(item: 3, section: 1))
        let back = IndexPath(item: 5, section: 6) as NSIndexPath
        XCTAssertEqual([back.section, back.item, back.row, back.length], [6, 5, 5, 2])
        let attributes = UICollectionViewLayoutAttributes(forCellWith: NSIndexPath(item: 7, section: 0) as IndexPath)
        XCTAssertEqual([attributes.indexPath.section, attributes.indexPath.item], [0, 7])
    }
}

// MARK: - UICornerConfiguration

#if !os(Linux)
@MainActor
#endif
final class UICornerConfigurationTests: XCTestCase {
    private func alpha(_ bitmap: Bitmap, _ x: Int, _ y: Int) -> Int {
        Int(bitmap.pixels[(y * bitmap.width + x) * 4 + 3])
    }
    private func radii(_ v: UIView) -> [CGFloat]? {
        v.layer._cornerRadii.map { [$0.topLeft, $0.topRight, $0.bottomLeft, $0.bottomRight] }
    }
    private func view(_ w: CGFloat, _ h: CGFloat, _ c: UICornerConfiguration) -> UIView {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: w, height: h))
        v.backgroundColor = .red
        v.cornerConfiguration = c
        return v
    }

    func testResolutionTableFromTheOracle() {
        XCTAssertNil(radii(UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))))
        XCTAssertEqual(radii(view(100, 40, .uniformCorners(radius: .fixed(8)))), [8, 8, 8, 8])
        XCTAssertEqual(radii(view(60, 60, .corners(radius: .fixed(12)))), [12, 12, 12, 12])
        XCTAssertEqual(radii(view(100, 40, .uniformCorners(radius: .fixed(40)))), [20, 20, 20, 20], "clamped to min(w,h)/2")
        XCTAssertEqual(radii(view(100, 40, .capsule())), [20, 20, 20, 20])
        XCTAssertEqual(radii(view(60, 100, .capsule())), [30, 30, 30, 30])
        XCTAssertEqual(radii(view(100, 40, .capsule(maximumRadius: 10))), [10, 10, 10, 10])
        XCTAssertEqual(radii(view(120, 80, .corners(topLeftRadius: .fixed(10), topRightRadius: .fixed(0),
                                                      bottomLeftRadius: .fixed(20), bottomRightRadius: .fixed(30)))),
                       [10, 0, 20, 30])
        XCTAssertEqual(radii(view(120, 80, .corners(topLeftRadius: .fixed(10), topRightRadius: nil,
                                                      bottomLeftRadius: nil, bottomRightRadius: nil))),
                       [10, 0, 0, 0], "unspecified corners are square")
        XCTAssertEqual(radii(view(100, 60, .uniformEdges(topRadius: .fixed(16), bottomRadius: .fixed(4)))), [16, 16, 4, 4])
        XCTAssertEqual(radii(view(100, 60, .uniformTopRadius(.fixed(16)))), [16, 16, 0, 0])
        XCTAssertEqual(radii(view(100, 60, .uniformEdges(leftRadius: .fixed(5), rightRadius: .fixed(7)))), [5, 7, 5, 7])
    }

    func testDescriptionsMatchTheOracle() {
        XCTAssertEqual(UIView().cornerConfiguration.description,
                       "UICornerConfiguration(topLeftRadius: .unspecified, topRightRadius: .unspecified, bottomLeftRadius: .unspecified, bottomRightRadius: .unspecified)")
        XCTAssertEqual(UICornerConfiguration.uniformCorners(radius: .fixed(8)).description,
                       "UICornerConfiguration(topLeftRadius: .fixed(radius: 8.0), topRightRadius: .fixed(radius: 8.0), bottomLeftRadius: .fixed(radius: 8.0), bottomRightRadius: .fixed(radius: 8.0))")
        XCTAssertEqual(UICornerConfiguration.capsule().description,
                       "UICornerConfiguration(topLeftRadius: .capsule, topRightRadius: .capsule, bottomLeftRadius: .capsule, bottomRightRadius: .capsule)")
        XCTAssertEqual(UICornerConfiguration.capsule(maximumRadius: 10).description,
                       "UICornerConfiguration(topLeftRadius: .fixed(radius: 10.0), topRightRadius: .fixed(radius: 10.0), bottomLeftRadius: .fixed(radius: 10.0), bottomRightRadius: .fixed(radius: 10.0))")
        XCTAssertEqual(UICornerConfiguration.uniformTopRadius(.fixed(16)).description,
                       "UICornerConfiguration(topLeftRadius: .fixed(radius: 16.0), topRightRadius: .fixed(radius: 16.0), bottomLeftRadius: .unspecified, bottomRightRadius: .unspecified)")
        XCTAssertEqual(UICornerConfiguration.uniformCorners(radius: .containerConcentric(minimum: 8)).description,
                       "UICornerConfiguration(topLeftRadius: .containerConcentric(minimumRadius: 8.0), topRightRadius: .containerConcentric(minimumRadius: 8.0), bottomLeftRadius: .containerConcentric(minimumRadius: 8.0), bottomRightRadius: .containerConcentric(minimumRadius: 8.0))")
    }

    func testFixedConfigurationRendersTheSameBytesAsCornerRadius() {
        let configured = view(100, 40, .uniformCorners(radius: .fixed(8)))
        XCTAssertEqual(configured.layer.cornerRadius, 0, "measured: cornerRadius stays 0")
        let twin = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        twin.backgroundColor = .red
        twin.layer.cornerRadius = 8
        for scale in [1, 3] as [CGFloat] {
            let a = UIRenderer.renderPassRender(configured, scale: scale)
            let b = UIRenderer.renderPassRender(twin, scale: scale)
            XCTAssertEqual(a.pixels, b.pixels, "render pass, scale \(scale)")
            let c = LayerBridge.render(configured, scale: scale)
            let d = LayerBridge.render(twin, scale: scale)
            XCTAssertEqual(c.pixels, d.pixels, "layer bridge, scale \(scale)")
        }
        // Measured: a later `layer.cornerRadius` reads back but does not draw.
        configured.layer.cornerRadius = 30
        XCTAssertEqual(configured.layer.cornerRadius, 30)
        XCTAssertEqual(UIRenderer.renderPassRender(configured, scale: 1).pixels,
                       UIRenderer.renderPassRender(twin, scale: 1).pixels)
    }

    func testPerCornerRadiiRenderIndependently() {
        let v = view(120, 80, .corners(topLeftRadius: .fixed(10), topRightRadius: .fixed(0),
                                       bottomLeftRadius: .fixed(20), bottomRightRadius: .fixed(30)))
        // Oracle (corners-ios-26.1-iphone16.json): 10.1 / 1.0 / 20.2 / 30.2.
        let bitmap = UIRenderer.renderPassRender(v, scale: 1)
        XCTAssertEqual(alpha(bitmap, 1, 1), 0, "top-left r10: outside the arc")
        XCTAssertEqual(alpha(bitmap, 4, 4), 255, "top-left r10: inside")
        XCTAssertEqual(alpha(bitmap, 118, 1), 255, "top-right r0: square")
        XCTAssertEqual(alpha(bitmap, 4, 75), 0, "bottom-left r20: outside")
        XCTAssertEqual(alpha(bitmap, 8, 72), 255, "bottom-left r20: inside")
        XCTAssertEqual(alpha(bitmap, 112, 72), 0, "bottom-right r30: outside")
        XCTAssertEqual(alpha(bitmap, 110, 70), 255, "bottom-right r30: inside")
        XCTAssertEqual(alpha(bitmap, 60, 40), 255)
        // The CQuartz layer backend takes ONE radius per layer and receives
        // the largest (30) for a non-uniform set — a documented approximation
        // of that backend (CoreAnimation.swift `effectiveCornerRadius`).
        let bridged = LayerBridge.render(v, scale: 1)
        XCTAssertEqual(alpha(bridged, 118, 1), 0, "layer backend: largest radius on every corner")
        XCTAssertEqual(alpha(bridged, 110, 70), 255)
        XCTAssertEqual(alpha(bridged, 60, 40), 255)
    }

    func testCapsuleFollowsAResize() {
        let v = view(100, 40, .capsule())
        XCTAssertEqual(radii(v), [20, 20, 20, 20])
        v.frame = CGRect(x: 0, y: 0, width: 200, height: 60)
        XCTAssertEqual(radii(v), [30, 30, 30, 30], "measured 200×60 → 30")
        v.cornerConfiguration = .unspecified
        XCTAssertNil(radii(v))
    }

    func testContainerConcentricSubtractsTheInset() {
        let container = view(108, 68, .uniformCorners(radius: .fixed(20)))
        let child = UIView(frame: CGRect(x: 4, y: 4, width: 100, height: 60))
        child.backgroundColor = .red
        container.addSubview(child)
        child.cornerConfiguration = .uniformCorners(radius: .containerConcentric(minimum: 8))
        XCTAssertEqual(radii(child), [16, 16, 16, 16], "measured layer state: 20 − 4")
        container.cornerConfiguration = .uniformCorners(radius: .fixed(10))
        XCTAssertEqual(radii(child), [8, 8, 8, 8], "floored at the minimum")
    }
}
