// Imports are file-scoped. Keep this helper UIKit-only so XCTest/AppKit's
// reexports cannot mask an ambiguity at the unchanged application boundary.
import UIKit

#if !os(Linux)
@MainActor
#endif
func makeFocusUIKitOnlyDiffableTypes(
    tableView: UITableView
) -> (NSDiffableDataSourceSnapshot<String, Int>,
      UITableViewDiffableDataSource<String, Int>) {
    let snapshot = NSDiffableDataSourceSnapshot<String, Int>()
    let dataSource = UITableViewDiffableDataSource<String, Int>(tableView: tableView) {
        _, _, _ in UITableViewCell(style: .default, reuseIdentifier: nil)
    }
    return (snapshot, dataSource)
}
