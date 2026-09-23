import XCTest
@testable import OpenUIKit

/// NetNewsWire SettingsViewController / AccountInspectorViewController /
/// FeedInspectorViewController / ArticleThemesTableViewController overrides.
@MainActor
final class TableControllerHooksTests: XCTestCase {
    final class Overriding: UITableViewController {
        override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool { false }
        override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
            super.tableView(tableView, indentationLevelForRowAt: indexPath) + 1
        }
        override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
            UIContextMenuConfiguration(identifier: "row" as NSString as NSCopying, previewProvider: nil, actionProvider: nil)
        }
        override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            UISwipeActionsConfiguration(actions: [])
        }
    }

    func testDefaultsAndOverrides() {
        let base = UITableViewController(style: .insetGrouped)
        let tv = base.tableView!
        let ip = IndexPath(row: 0, section: 0)
        XCTAssertTrue(base.tableView(tv, shouldHighlightRowAt: ip))
        XCTAssertEqual(base.tableView(tv, indentationLevelForRowAt: ip), 0)
        XCTAssertNil(base.tableView(tv, contextMenuConfigurationForRowAt: ip, point: .zero))
        XCTAssertNil(base.tableView(tv, trailingSwipeActionsConfigurationForRowAt: ip))
        let o = Overriding(style: .plain)
        XCTAssertFalse(o.tableView(o.tableView, shouldHighlightRowAt: ip))
        XCTAssertEqual(o.tableView(o.tableView, indentationLevelForRowAt: ip), 1)
        XCTAssertEqual(o.tableView(o.tableView, contextMenuConfigurationForRowAt: ip, point: .zero)?.identifier,
                       AnyHashable("row" as NSString))
        // The delegate path the table view already uses sees the override.
        let delegate: UITableViewDelegate = o
#if canImport(ObjectiveC)
        // UIKit's @objc protocol: an optional requirement (objc-protocols.md).
        XCTAssertNotNil(delegate.tableView?(o.tableView, trailingSwipeActionsConfigurationForRowAt: ip) ?? nil)
#else
        XCTAssertNotNil(delegate.tableView(o.tableView, trailingSwipeActionsConfigurationForRowAt: ip))
#endif
        XCTAssertNil(UIContextMenuConfiguration(identifier: nil).identifier)
    }
}
