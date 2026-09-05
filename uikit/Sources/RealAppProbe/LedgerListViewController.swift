// Ledger list: inset-grouped table of formatter-backed rows, search via
// NSRegularExpression, pushed detail that shows the ISO8601 export string.
// Same bytes in Sources/RealAppProbe/LedgerListViewController.swift (guest glob).
import UIKit

final class LedgerListViewController: UITableViewController, UISearchResultsUpdating {

    private static let cellIdentifier = "LedgerRow"
    private static let rowHeight: CGFloat = 92

    private var allItems: [LedgerItem] = []
    private var items: [LedgerItem] = []
    private var searchController: UISearchController!
    private(set) var jsonOK = false
    private(set) var exportStamp = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ledger"
        var rows = LedgerStore.seeded()
        if let loopback = LedgerStore.loopbackItem() {
            rows.append(loopback)
        }
        jsonOK = LedgerStore.persistRoundTrip(rows)
        if let first = rows.first {
            exportStamp = first.iso8601
        }
        allItems = rows
        items = rows

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Regex"
        navigationItem.searchController = search
        searchController = search

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Export", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem?.primaryAction = UIAction { [weak self] _ in
            self?.presentExport()
        }

        tableView.keyboardDismissMode = .onDrag
        setContentScrollView(tableView)
    }

    override func tableView(_ tableView: UITableView,
                             numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        var header = exportStamp
        if jsonOK {
            if !header.isEmpty { header += " · " }
            header += "json ok"
        }
        if header.isEmpty { return "Transactions" }
        return header
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier)
            ?? LedgerTableCell(reuseIdentifier: Self.cellIdentifier)
        if let ledgerCell = cell as? LedgerTableCell {
            ledgerCell.apply(items[indexPath.row])
        } else {
            cell.textLabel?.text = items[indexPath.row].merchant
            cell.detailTextLabel?.text = items[indexPath.row].usd
        }
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        Self.rowHeight
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openItem(at: indexPath.row)
    }

    func updateSearchResults(for searchController: UISearchController) {
        applyFilter(query: searchController.searchBar.text ?? "")
    }

    private func applyFilter(query: String) {
        items = LedgerStore.matching(allItems, query: query)
        tableView.reloadData()
    }

    func openItem(at row: Int) {
        guard row >= 0, row < items.count else { return }
        let detail = LedgerDetailViewController()
        detail.item = items[row]
        navigationController?.pushViewController(detail, animated: true)
    }

    func focusSearch() {
        searchController.isActive = true
    }

    /// Query "Coff" is a valid regex and matches "Coffee Lab".
    func typeSearch() {
        searchController.searchBar.text = "Coff"
        updateSearchResults(for: searchController)
    }

    func cancelSearch() {
        searchController.searchBar.text = ""
        searchController.isActive = false
        updateSearchResults(for: searchController)
    }

    func presentExport() {
        let alert = UIAlertController(title: "Export",
                                      message: exportStamp,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true, completion: nil)
    }

    func confirmExport() {
        dismiss(animated: true, completion: nil)
    }
}

final class LedgerTableCell: UITableViewCell {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let amountLabel = UILabel()

    init(reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        accessoryType = .disclosureIndicator

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        amountLabel.font = .preferredFont(forTextStyle: .body)
        amountLabel.textColor = .label
        amountLabel.textAlignment = .right

        for v in [titleLabel, subtitleLabel, amountLabel] {
            v.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(v)
        }
        let guide = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: guide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor,
                                                 constant: -8),

            amountLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(_ item: LedgerItem) {
        titleLabel.text = item.merchant
        amountLabel.text = item.usd
        var subtitle = item.date
        if !item.duration.isEmpty {
            subtitle += " · "
            subtitle += item.duration
        }
        subtitle += " · "
        subtitle += item.eur
        if item.source == "loopback" {
            subtitle += " · fx"
        }
        subtitleLabel.text = subtitle
    }
}

final class LedgerDetailViewController: UIViewController {
    var item: LedgerItem?
    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = item?.merchant
        view.backgroundColor = .systemBackground

        let done = UIBarButtonItem(title: "Done", style: .done, target: nil, action: nil)
        done.primaryAction = UIAction(title: "Done") { [weak self] _ in
            self?.done()
        }
        navigationItem.rightBarButtonItem = done

        var body = ""
        if let item {
            body += item.usd
            body += " / "
            body += item.eur
            body += "\n"
            body += item.date
            if !item.duration.isEmpty {
                body += "\n"
                body += item.duration
            }
            body += "\n"
            body += item.iso8601
            body += "\n"
            body += item.source
        }
        textView.text = body
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .systemBackground
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: guide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func done() {
        navigationController?.popViewController(animated: true)
    }
}
