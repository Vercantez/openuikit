// UISearchController + UITabBarItem.badgeValue + navigation-item search.
import Foundation
import XCTest
@testable import OpenUIKit

@MainActor
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
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let sc = UISearchController(searchResultsController: nil)
        let item = UINavigationItem(title: "Library")
        item.searchController = sc
        let bar = UINavigationBar()
        bar.pushItem(item, animated: false)
        XCTAssertEqual(bar.searchOverlayHeight, 0)
        sc.isActive = true
        XCTAssertEqual(bar.searchOverlayHeight, 6)
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
}
