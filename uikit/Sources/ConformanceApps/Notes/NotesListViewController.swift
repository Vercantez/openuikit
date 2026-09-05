// Notes list, pushed detail, and settings. Same source compiles against
// real UIKit and OpenUIKit (see NotesApp.swift).
import UIKit

// MARK: - Tab 1: inset-grouped notes list + search + delete alert

final class NotesListViewController: UITableViewController, UISearchResultsUpdating {

    private static let cellIdentifier = "NotesRow"
    /// App-chosen height for title + 2-line body + timestamp. Not a
    /// measured iOS chrome constant — the operator's simulator capture
    /// is the oracle for this row.
    private static let rowHeight: CGFloat = 92

    private var allNotes: [NotesItem] = []
    private var notes: [NotesItem] = []
    private var searchController: UISearchController!
    private var pendingDeleteIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes"
        allNotes = NotesApp.seededNotes()
        notes = allNotes

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search"
        navigationItem.searchController = search
        searchController = search

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .trash, target: nil, action: nil)
        navigationItem.rightBarButtonItem?.primaryAction = UIAction { [weak self] _ in
            self?.presentDeleteAlert()
        }

        tableView.keyboardDismissMode = .onDrag
        // OpenUIKit's navigation bar has no automatic content-scroll-view
        // detection (UIViewController.setContentScrollView is explicit-only);
        // real UIKit accepts the same call and already tracks this table.
        setContentScrollView(tableView)
    }

    // MARK: Data source

    override func tableView(_ tableView: UITableView,
                             numberOfRowsInSection section: Int) -> Int {
        notes.count
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        "All Notes"
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier)
            ?? NotesTableCell(reuseIdentifier: Self.cellIdentifier)
        let note = notes[indexPath.row]
        if let notesCell = cell as? NotesTableCell {
            notesCell.apply(note)
        } else {
            cell.textLabel?.text = note.title
            cell.detailTextLabel?.text = note.body
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
        openNote(at: indexPath.row)
    }

    // MARK: UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        applyFilter(query: searchController.searchBar.text ?? "")
    }

    private func applyFilter(query: String) {
        if query.isEmpty {
            notes = allNotes
        } else {
            // hasPrefix only — String.contains(String) links
            // libswift_StringProcessing on the guest (GATE_B, 54be0035).
            var filtered: [NotesItem] = []
            for note in allNotes {
                if note.title.hasPrefix(query) { filtered.append(note) }
            }
            notes = filtered
        }
        tableView.reloadData()
    }

    // MARK: Scripted steps (NotesApp.perform)

    func openNote(at row: Int) {
        guard row >= 0, row < notes.count else { return }
        let detail = NotesDetailViewController()
        detail.note = notes[row]
        navigationController?.pushViewController(detail, animated: true)
    }

    func focusSearch() {
        searchController.isActive = true
    }

    /// Query "Meet" matches "Meeting notes" via hasPrefix.
    func typeSearch() {
        searchController.searchBar.text = "Meet"
        updateSearchResults(for: searchController)
    }

    func cancelSearch() {
        searchController.searchBar.text = ""
        searchController.isActive = false
        updateSearchResults(for: searchController)
    }

    /// What the trash control does: an alert, not a swipe. UIKit has no
    /// public programmatic reveal of UIContextualAction (TableEditor).
    func presentDeleteAlert() {
        guard !notes.isEmpty else { return }
        pendingDeleteIndex = 0
        let title = notes[0].title
        let alert = UIAlertController(title: "Delete \"\(title)\"?",
                                      message: "This cannot be undone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.removePendingNote()
        })
        present(alert, animated: true, completion: nil)
    }

    /// What tapping Delete on the alert does. Dismiss first (UIKit fires
    /// the handler after dismiss); then drop the pending row.
    func confirmDelete() {
        dismiss(animated: true, completion: nil)
        removePendingNote()
    }

    private func removePendingNote() {
        let row = pendingDeleteIndex ?? 0
        pendingDeleteIndex = nil
        guard row >= 0, row < notes.count else { return }
        let removed = notes.remove(at: row)
        var kept: [NotesItem] = []
        for note in allNotes {
            if note.title == removed.title && note.timestamp == removed.timestamp {
                continue
            }
            kept.append(note)
        }
        allNotes = kept
        tableView.reloadData()
    }
}

/// Title, two-line body, DateFormatter timestamp — Auto Layout against
/// the cell's layoutMarginsGuide, the way a notes list is written.
final class NotesTableCell: UITableViewCell {
    let titleLabel = UILabel()
    let bodyLabel = UILabel()
    let timestampLabel = UILabel()

    init(reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        accessoryType = .disclosureIndicator

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2

        timestampLabel.font = .preferredFont(forTextStyle: .footnote)
        timestampLabel.textColor = .tertiaryLabel

        for v in [titleLabel, bodyLabel, timestampLabel] {
            v.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(v)
        }
        let guide = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: guide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor),

            timestampLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 4),
            timestampLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            timestampLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(_ note: NotesItem) {
        titleLabel.text = note.title
        bodyLabel.text = note.body
        timestampLabel.text = note.timestamp
    }
}

// MARK: - Pushed detail: UITextView + Done

final class NotesDetailViewController: UIViewController {
    var note: NotesItem?
    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = note?.title
        view.backgroundColor = .systemBackground

        let done = UIBarButtonItem(title: "Done", style: .done, target: nil, action: nil)
        done.primaryAction = UIAction(title: "Done") { [weak self] _ in
            self?.done()
        }
        navigationItem.rightBarButtonItem = done

        var body = note?.body ?? ""
        if let stamp = note?.timestamp {
            body += "\n\n"
            body += stamp
        }
        textView.text = body
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .systemBackground
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

    func focusBody() {
        _ = textView.becomeFirstResponder()
    }

    func done() {
        _ = textView.resignFirstResponder()
        _ = view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Tab 2: settings (switch + segmented control, UserDefaults)

final class NotesSettingsViewController: UITableViewController {

    private enum Row: Int, CaseIterable {
        case icloud, sort
        static func at(_ indexPath: IndexPath) -> Row {
            Row(rawValue: indexPath.row) ?? .icloud
        }
    }

    let iCloudSwitch = UISwitch()
    let sortControl = UISegmentedControl(items: ["Date", "Title", "Manual"])
    private let iCloudLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"

        iCloudLabel.text = "iCloud Sync"
        iCloudLabel.font = .preferredFont(forTextStyle: .body)
        iCloudLabel.textColor = .label

        iCloudSwitch.isOn = UserDefaults.standard.bool(forKey: NotesApp.iCloudKey)
        iCloudSwitch.addAction(UIAction { [weak self] _ in
            self?.persistICloud()
        }, for: .valueChanged)

        sortControl.selectedSegmentIndex = UserDefaults.standard.integer(forKey: NotesApp.sortKey)
        sortControl.addAction(UIAction { [weak self] _ in
            self?.persistSort()
        }, for: .valueChanged)

        setContentScrollView(tableView)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        "Preferences"
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = Row.at(indexPath)
        let id = "NotesSettings.\(row.rawValue)"
        let cell = tableView.dequeueReusableCell(withIdentifier: id)
            ?? UITableViewCell(style: .default, reuseIdentifier: id)
        cell.selectionStyle = .none
        cell.textLabel?.text = nil
        install(row, in: cell)
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }

    private func install(_ row: Row, in cell: UITableViewCell) {
        switch row {
        case .icloud:
            pinTrailingControl(iCloudSwitch, label: iCloudLabel, in: cell)
        case .sort:
            pinFullWidth(sortControl, in: cell, height: 33)
        }
    }

    private func pinFullWidth(_ view: UIView, in cell: UITableViewCell,
                              height: CGFloat) {
        guard view.superview !== cell.contentView else { return }
        view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(view)
        let guide = cell.contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            view.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            view.heightAnchor.constraint(equalToConstant: height),
        ])
    }

    private func pinTrailingControl(_ control: UIView, label: UILabel,
                                    in cell: UITableViewCell) {
        guard label.superview !== cell.contentView else { return }
        label.translatesAutoresizingMaskIntoConstraints = false
        control.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(label)
        cell.contentView.addSubview(control)
        let guide = cell.contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            control.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            control.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor,
                                            constant: -8),
        ])
    }

    func toggleICloud() {
        iCloudSwitch.setOn(!iCloudSwitch.isOn, animated: true)
        persistICloud()
    }

    func selectSegment(_ index: Int) {
        sortControl.selectedSegmentIndex = index
        persistSort()
    }

    private func persistICloud() {
        UserDefaults.standard.set(iCloudSwitch.isOn, forKey: NotesApp.iCloudKey)
    }

    private func persistSort() {
        UserDefaults.standard.set(sortControl.selectedSegmentIndex, forKey: NotesApp.sortKey)
    }
}
