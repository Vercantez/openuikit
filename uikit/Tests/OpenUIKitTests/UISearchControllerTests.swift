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
}
