// UISearchController + UITabBarItem.badgeValue + navigation-item search.
import Foundation
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class UISearchControllerTests: XCTestCase {
    func testSearchControllerSurface() {
        let sc = UISearchController(searchResultsController: nil)
        XCTAssertNil(sc.searchResultsController)
        XCTAssertFalse(sc.isActive)
        XCTAssertTrue(sc.hidesNavigationBarDuringPresentation)
        XCTAssertTrue(sc.automaticallyShowsCancelButton)
        XCTAssertTrue(sc.obscuresBackgroundDuringPresentation)
        let item = UINavigationItem(title: "Library")
        XCTAssertTrue(item.hidesSearchBarWhenScrolling)
        item.searchController = sc
        XCTAssertTrue(sc._item === item)
        sc.isActive = true
        XCTAssertTrue(sc.isActive)
        XCTAssertTrue(sc.searchBar.showsCancelButton)
        sc.isActive = false
        XCTAssertFalse(sc.searchBar.showsCancelButton)
    }

    func testBadgeValueStores() {
        let item = UITabBarItem(title: "Tools", image: nil, tag: 1)
        XCTAssertNil(item.badgeValue)
        item.badgeValue = "3"
        XCTAssertEqual(item.badgeValue, "3")
        item.badgeValue = nil
        XCTAssertNil(item.badgeValue)
    }

    func testBadgeLayoutMatchesTabsT200() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let item = UITabBarItem(title: "Tools", image: nil, tag: 1)
        item.badgeValue = "3"
        let bar = UITabBar()
        bar.items = [item]
        bar.frame = CGRect(x: 0, y: 0, width: 274, height: 62)
        bar.layoutIfNeeded()
        XCTAssertEqual(bar.itemViews.count, 1)
        let v = bar.itemViews[0]
        v.frame = CGRect(x: 0, y: 0, width: 86, height: 62)
        v.layoutIfNeeded()
        XCTAssertEqual(v.badgeView.frame.size, CGSize(width: 20, height: 20))
        XCTAssertEqual(v.badgeView.frame.origin.x, 86 / 2 + 8.5, accuracy: 0.01)
        XCTAssertEqual(v.badgeView.frame.origin.y, 6, accuracy: 0.01)
        XCTAssertEqual(v.badgeView.layer.cornerRadius, 10, accuracy: 0.01)
        XCTAssertEqual(v.badgeLabel.font.pointSize, 13, accuracy: 0.01)
        XCTAssertEqual(v.badgeLabel.frame, CGRect(x: 4, y: 2, width: 12, height: 16))
    }

    func testSearchSlotHeightIsZeroWithoutSearch() {
        let bar = UINavigationBar()
        XCTAssertEqual(bar.searchOverlayHeight, 0)
    }

    func testSearchActiveExtraHeightMatchesTabsT4000() {
        let saved = OpenUIKitRuntime.systemFontCut
        let savedIdiom = UIDevice.current.userInterfaceIdiom
        OpenUIKitRuntime.systemFontCut = .iOS
        UIDevice.current.userInterfaceIdiom = .phone
        defer {
            OpenUIKitRuntime.systemFontCut = saved
            UIDevice.current.userInterfaceIdiom = savedIdiom
        }
        let sc = UISearchController(searchResultsController: nil)
        let item = UINavigationItem(title: "Library")
        item.searchController = sc
        let bar = UINavigationBar()
        bar.pushItem(item, animated: false)
        XCTAssertEqual(bar.searchOverlayHeight, 0)
        // MEASURED Tabs t7000, iPhone SE 2x / iOS 26.1: hide-on-scroll
        // bump is the 60 pt overlay slot (8+44+8). Pad is 0.
        XCTAssertEqual(bar.hideOnScrollContentBump(requestedY: 200), 60)
        sc.isActive = true
        XCTAssertEqual(bar.searchOverlayHeight, 6)
        XCTAssertEqual(bar.hideOnScrollContentBump(requestedY: 200), 0)
        sc.isActive = false
        XCTAssertEqual(bar.searchOverlayHeight, 0)
    }

    /// MEASURED /tmp/tabs-t2000-probe, iPhone SE 2x / iOS 26.1: assigning
    /// `title` overwrites `tabBarItem.title` (plain VC "Search" → "Library").
    func testTitleOverwritesTabBarItemTitle() {
        let vc = UIViewController()
        vc.tabBarItem = UITabBarItem(title: "Search", image: nil, tag: 0)
        XCTAssertEqual(vc.tabBarItem?.title, "Search")
        vc.title = "Library"
        XCTAssertEqual(vc.title, "Library")
        XCTAssertEqual(vc.tabBarItem?.title, "Library")
        XCTAssertEqual(vc.navigationItem.title, "Library")
    }

    /// MEASURED same probe: `nav.tabBarItem = "Search"` then `child.title =
    /// "Library"` copies onto the nav item even though the two items are
    /// different objects. `navigationItem.title` alone does not.
    func testNavChildTitleCopiesOntoNavTabBarItem() {
        let child = UIViewController()
        let nav = UINavigationController(rootViewController: child)
        let img = UIImage(systemName: "calendar")
        nav.tabBarItem = UITabBarItem(title: "Search", image: img, tag: 0)
        XCTAssertFalse(nav.tabBarItem === child.tabBarItem)
        XCTAssertEqual(nav.tabBarItem?.title, "Search")
        child.title = "Library"
        XCTAssertEqual(nav.tabBarItem?.title, "Library")
        XCTAssertEqual(child.tabBarItem?.title, "Library")
        XCTAssertFalse(nav.tabBarItem === child.tabBarItem)
        XCTAssertTrue(nav.tabBarItem?.image === img)

        let other = UIViewController()
        let nav2 = UINavigationController(rootViewController: other)
        nav2.tabBarItem = UITabBarItem(title: "Search", image: nil, tag: 0)
        other.navigationItem.title = "Library"
        XCTAssertEqual(nav2.tabBarItem?.title, "Search")
        XCTAssertEqual(other.title, nil)
    }

    /// Tabs t200/t2000: after the child's viewDidLoad sets title, the bar
    /// label is "Library" `[84, 623, 36, 12]`, not the "Search" assigned on
    /// the nav item before the child loaded.
    func testTabBarLabelRereadsItemTitle() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }

        final class Host: UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
                title = "Library"
            }
        }
        let child = Host()
        let nav = UINavigationController(rootViewController: child)
        nav.tabBarItem = UITabBarItem(title: "Search", image: nil, tag: 0)
        XCTAssertEqual(nav.tabBarItem?.title, "Search")
        let tab = UITabBarController()
        tab.viewControllers = [nav]
        tab.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        tab.view.layoutIfNeeded()
        XCTAssertNotNil(child.navigationController)
        XCTAssertEqual(child.title, "Library")
        XCTAssertEqual(nav.tabBarItem?.title, "Library")
        tab.tabBar.layoutIfNeeded()
        XCTAssertEqual(tab.tabBar.itemViews.first?.titleLabel.text, "Library")
    }

    /// MEASURED Tabs t200.rtl, iPhone SE 2x / iOS 26.1: items pack
    /// leading-to-trailing. Index 0 sits on the right of the platter.
    func testTabBarItemsMirrorAboutPlatterInRTL() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let items = [
            UITabBarItem(title: "Library", image: nil, tag: 0),
            UITabBarItem(title: "Tools", image: nil, tag: 1),
            UITabBarItem(title: "Scroll", image: nil, tag: 2),
        ]
        let bar = UITabBar()
        bar.items = items
        bar.selectedItem = items[0]
        bar.semanticContentAttribute = .forceRightToLeft
        bar.frame = CGRect(x: 0, y: 0, width: 375, height: 62)
        bar.layoutIfNeeded()
        XCTAssertEqual(bar.itemViews.count, 3)
        let left = bar.itemViews[2]
        let right = bar.itemViews[0]
        XCTAssertLessThan(left.frame.minX, right.frame.minX)
        XCTAssertEqual(right.titleLabel.text, "Library")
        XCTAssertEqual(left.titleLabel.text, "Scroll")
    }

    /// MEASURED Ledger t200 / t3000, iPhone SE 2x / iOS 26.1: phone
    /// `searchController` with no tab bar docks at the bottom (slot 86,
    /// field `[33, 596, 309, 38]`); activating collapses the bar to
    /// height 0 at y 10 and shrinks the field to 249.
    func testPhoneSearchWithoutTabBarDocksAtBottom() {
        let saved = OpenUIKitRuntime.systemFontCut
        let savedIdiom = UIDevice.current.userInterfaceIdiom
        let savedTraits = UITraitCollection.current
        let savedBounds = UIScreen.main.bounds
        let savedScale = UIScreen.main.scale
        OpenUIKitRuntime.systemFontCut = .iOS
        UIDevice.current.userInterfaceIdiom = .phone
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 375, height: 667),
                                     scale: 2)
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .phone)
        defer {
            OpenUIKitRuntime.systemFontCut = saved
            UIDevice.current.userInterfaceIdiom = savedIdiom
            UITraitCollection.current = savedTraits
            UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        }

        let root = UITableViewController(style: .insetGrouped)
        root.title = "Ledger"
        let sc = UISearchController(searchResultsController: nil)
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Regex"
        root.navigationItem.searchController = sc
        let nav = UINavigationController(rootViewController: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.rootViewController = nav
        window.layoutIfNeeded()

        XCTAssertTrue(nav.navigationBar.usesBottomSearch)
        XCTAssertEqual(nav.navigationBar.searchOverlayHeight, 0)
        XCTAssertEqual(nav.navigationBar.frame,
                       CGRect(x: 0, y: 10, width: 375, height: 54))
        XCTAssertEqual(root.view.safeAreaInsets.bottom, 86, accuracy: 0.01)
        XCTAssertEqual(nav.floatingSearchContainer?.frame,
                       CGRect(x: 0, y: 581, width: 375, height: 86))
        let fieldAbs = sc.searchBar.convert(sc.searchBar.bounds, to: window)
        XCTAssertEqual(fieldAbs, CGRect(x: 33, y: 596, width: 309, height: 38))

        sc.isActive = true
        window.layoutIfNeeded()
        XCTAssertEqual(nav.navigationBar.frame,
                       CGRect(x: 0, y: 10, width: 375, height: 0))
        XCTAssertEqual(root.view.safeAreaInsets.top, 10, accuracy: 0.01)
        XCTAssertEqual(root.view.safeAreaInsets.bottom, 86, accuracy: 0.01)
        let activeAbs = sc.searchBar.convert(sc.searchBar.bounds, to: window)
        XCTAssertEqual(activeAbs, CGRect(x: 33, y: 596, width: 249, height: 38))
        XCTAssertEqual(nav.floatingSearchDismissPlatter?.isHidden, false)
        XCTAssertEqual(nav.navigationBar.hideOnScrollContentBump(requestedY: 200), 0)
    }

    /// Compact height (Ledger t200.landscape): slot 82, platter 44, field 36.
    func testPhoneBottomSearchCompactHeightSlotIs82() {
        let saved = OpenUIKitRuntime.systemFontCut
        let savedIdiom = UIDevice.current.userInterfaceIdiom
        let savedTraits = UITraitCollection.current
        let savedBounds = UIScreen.main.bounds
        let savedScale = UIScreen.main.scale
        OpenUIKitRuntime.systemFontCut = .iOS
        UIDevice.current.userInterfaceIdiom = .phone
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 667, height: 375),
                                     scale: 2)
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            verticalSizeClass: .compact, userInterfaceIdiom: .phone)
        defer {
            OpenUIKitRuntime.systemFontCut = saved
            UIDevice.current.userInterfaceIdiom = savedIdiom
            UITraitCollection.current = savedTraits
            UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        }

        let root = UIViewController()
        let sc = UISearchController(searchResultsController: nil)
        root.navigationItem.searchController = sc
        let nav = UINavigationController(rootViewController: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 667, height: 375))
        window.rootViewController = nav
        window.layoutIfNeeded()

        XCTAssertTrue(nav.navigationBar.usesBottomSearch)
        XCTAssertEqual(nav.navigationBar.frame.minY, 24, accuracy: 0.01)
        XCTAssertEqual(root.view.safeAreaInsets.bottom, 82, accuracy: 0.01)
        XCTAssertEqual(nav.floatingSearchContainer?.frame,
                       CGRect(x: 0, y: 293, width: 667, height: 82))
        let fieldAbs = sc.searchBar.convert(sc.searchBar.bounds, to: window)
        XCTAssertEqual(fieldAbs, CGRect(x: 32, y: 307, width: 603, height: 36))
    }

    /// Tabs / Notes: a tab-hosted search stays the nav overlay, not the
    /// bottom dock. MEASURED Tabs t200 / t4000.
    func testTabHostedSearchStaysNavOverlay() {
        let saved = OpenUIKitRuntime.systemFontCut
        let savedIdiom = UIDevice.current.userInterfaceIdiom
        OpenUIKitRuntime.systemFontCut = .iOS
        UIDevice.current.userInterfaceIdiom = .phone
        defer {
            OpenUIKitRuntime.systemFontCut = saved
            UIDevice.current.userInterfaceIdiom = savedIdiom
        }

        let root = UIViewController()
        root.title = "Library"
        let sc = UISearchController(searchResultsController: nil)
        root.navigationItem.searchController = sc
        let nav = UINavigationController(rootViewController: root)
        nav.tabBarItem = UITabBarItem(title: "Library", image: nil, tag: 0)
        let tab = UITabBarController()
        tab.viewControllers = [nav]
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.rootViewController = tab
        window.layoutIfNeeded()

        XCTAssertFalse(nav.navigationBar.usesBottomSearch)
        XCTAssertEqual(nav.navigationBar.searchOverlayHeight, 0)
        XCTAssertEqual(nav.navigationBar.frame.height, 54, accuracy: 0.01)
        sc.isActive = true
        window.layoutIfNeeded()
        XCTAssertEqual(nav.navigationBar.searchOverlayHeight, 6)
        XCTAssertEqual(nav.navigationBar.frame.height, 60, accuracy: 0.01)
        XCTAssertEqual(nav.floatingSearchContainer?.isHidden ?? true, true)
    }

    /// MEASURED Ledger t200: disclosure contentView trailing margin is 8
    /// (subtitle 292.5 in a 316.5-wide content view).
    func testDisclosureContentViewTrailingMarginIs8() {
        let saved = OpenUIKitRuntime.systemFontCut
        let savedBounds = UIScreen.main.bounds
        let savedScale = UIScreen.main.scale
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 375, height: 667),
                                     scale: 2)
        defer {
            OpenUIKitRuntime.systemFontCut = saved
            UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        }
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.accessoryType = .disclosureIndicator
        cell.frame = CGRect(x: 0, y: 0, width: 343, height: 92)
        cell.layoutIfNeeded()
        XCTAssertEqual(cell.contentView.frame.width, 316.5, accuracy: 0.01)
        XCTAssertEqual(cell.contentView.layoutMargins.right, 8, accuracy: 0.01)
        XCTAssertEqual(cell.contentView.layoutMargins.left, 16, accuracy: 0.01)

        cell.semanticContentAttribute = .forceRightToLeft
        cell.contentView._notifyLayoutMarginsChanged()
        cell.layoutIfNeeded()
        XCTAssertEqual(cell.contentView.layoutMargins.left, 8, accuracy: 0.01)
        XCTAssertEqual(cell.contentView.layoutMargins.right, 16, accuracy: 0.01)
    }
}
