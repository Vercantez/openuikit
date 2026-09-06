// TableEditor's root screen: a plain UITableViewController of subtitle
// cells, with an Edit button that raises delete controls and reorder
// handles the way a reminders list does.
import UIKit

final class TableEditorRootViewController: UITableViewController {

    /// The list, as a plain mutable array — the shape an editable table has.
    private var items: [TableEditorItem] = [
        TableEditorItem(title: "Alpha", subtitle: "First item"),
        TableEditorItem(title: "Bravo", subtitle: "Second item"),
        TableEditorItem(title: "Charlie", subtitle: "Third item"),
        TableEditorItem(title: "Delta", subtitle: "Fourth item"),
        TableEditorItem(title: "Echo", subtitle: "Fifth item"),
        TableEditorItem(title: "Foxtrot", subtitle: "Sixth item"),
        TableEditorItem(title: "Golf", subtitle: "Seventh item"),
        TableEditorItem(title: "Hotel", subtitle: "Eighth item"),
        TableEditorItem(title: "India", subtitle: "Ninth item"),
        TableEditorItem(title: "Juliet", subtitle: "Tenth item"),
        TableEditorItem(title: "Kilo", subtitle: "Eleventh item"),
        TableEditorItem(title: "Lima", subtitle: "Twelfth item"),
    ]

    private static let cellIdentifier = "TableEditorRow"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reminders"
        tableView.allowsSelectionDuringEditing = true
        refreshEditButton()
        // OpenUIKit's navigation bar has no automatic content-scroll-view
        // detection (UIViewController.setContentScrollView is explicit-only);
        // real UIKit accepts the same call and already tracks this table.
        setContentScrollView(tableView)
    }

    // MARK: Data source

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: Self.cellIdentifier)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.subtitle
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView,
                            moveRowAt sourceIndexPath: IndexPath,
                            to destinationIndexPath: IndexPath) {
        let item = items.remove(at: sourceIndexPath.row)
        items.insert(item, at: destinationIndexPath.row)
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // MARK: Scripted steps (TableEditorApp.perform)

    /// What the Edit / Done bar button does. Called by its UIAction and by
    /// the script.
    func setTableEditing(_ editing: Bool) {
        tableView.setEditing(editing, animated: true)
        refreshEditButton()
    }

    /// What a delete-control tap does. Called by `commit editingStyle` and
    /// by the script (row 2 is Charlie at the start of the timeline).
    func deleteRow(at row: Int) {
        let path = IndexPath(row: row, section: 0)
        tableView(tableView, commit: .delete, forRowAt: path)
    }

    /// Insert a uniquely titled row at `row` with `.automatic` animation.
    func insertRow(at row: Int) {
        items.insert(TableEditorItem(title: "Zero", subtitle: "Inserted item"),
                     at: row)
        tableView.insertRows(at: [IndexPath(row: row, section: 0)],
                             with: .automatic)
    }

    /// What a row tap does while `allowsSelectionDuringEditing` is on.
    func selectRow(at row: Int) {
        tableView.selectRow(at: IndexPath(row: row, section: 0),
                            animated: false, scrollPosition: .none)
    }

    func openListScreen() {
        navigationController?.pushViewController(TableEditorListViewController(),
                                                 animated: false)
    }

    func selectListFirst() {
        (navigationController?.topViewController as? TableEditorListViewController)?
            .selectFirst()
    }

    private func refreshEditButton() {
        let editing = tableView.isEditing
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            primaryAction: UIAction(title: editing ? "Done" : "Edit") { [weak self] _ in
                guard let self else { return }
                self.setTableEditing(!self.tableView.isEditing)
            })
    }
}
