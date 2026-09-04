// NavFlow's root screen: an inset-grouped UITableViewController whose rows
// come from a data source, with a "Filter" bar button that raises the sheet.
import UIKit

final class NavFlowRootViewController: UITableViewController {

    /// The list, as a plain model array — the shape a settings screen has.
    private let sections: [(header: String, items: [NavFlowItem])] = [
        ("General", [
            NavFlowItem(title: "Notifications", detail: "On",
                        body: "Alerts, sounds and badges for this account."),
            NavFlowItem(title: "Appearance", detail: "Automatic",
                        body: "Match the system light and dark appearance."),
            NavFlowItem(title: "Downloads", detail: "Wi-Fi",
                        body: "Only download new episodes over Wi-Fi."),
        ]),
        ("Storage", [
            NavFlowItem(title: "Manage Downloads", detail: "1.2 GB",
                        body: "Remove episodes you have already played."),
            NavFlowItem(title: "Clear Cache", detail: "",
                        body: "Artwork and metadata are re-fetched on demand."),
        ]),
    ]

    private static let cellIdentifier = "NavFlowRow"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Library"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            primaryAction: UIAction(title: "Filter") { [weak self] _ in
                self?.showFilters()
            })
        // OpenUIKit's navigation bar has no automatic content-scroll-view
        // detection (UIViewController.setContentScrollView is explicit-only);
        // real UIKit accepts the same call and already tracks this table.
        setContentScrollView(tableView)
    }

    // MARK: Data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Not `register(_:forCellReuseIdentifier:)`: the reuse registry
        // constructs with `style: .default` on both sides, and this list wants
        // the .value1 detail column.
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier)
            ?? UITableViewCell(style: .value1, reuseIdentifier: Self.cellIdentifier)
        let item = sections[indexPath.section].items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.detail
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: Delegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openItem(at: indexPath)
    }

    // MARK: Scripted steps (NavFlowApp.perform)

    /// What a row tap does. Called by `didSelectRowAt` and by the script.
    func openItem(at indexPath: IndexPath) {
        let detail = NavFlowDetailViewController()
        detail.item = sections[indexPath.section].items[indexPath.row]
        navigationController?.pushViewController(detail, animated: true)
    }

    /// What the "Filter" bar button does. Called by its UIAction and by the
    /// script.
    func showFilters() {
        let sheet = NavFlowFilterViewController()
        sheet.modalPresentationStyle = .pageSheet
        present(sheet, animated: true, completion: nil)
    }
}
