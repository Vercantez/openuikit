// Tabs' three screens: a searchable plain table, a toolbar + menu button,
// and a scroll view.
import UIKit

// MARK: - Tab 1: search over a plain table of 30 rows

final class TabsSearchViewController: UITableViewController, UISearchResultsUpdating {

    private static let cellIdentifier = "TabsRow"
    private static let allTitles: [String] = {
        var titles: [String] = []
        var i = 1
        while i <= 30 {
            titles.append("Row \(i)")
            i += 1
        }
        return titles
    }()

    private var titles: [String] = TabsSearchViewController.allTitles
    private var searchController: UISearchController!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Library"
        tableView.keyboardDismissMode = .onDrag

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search"
        navigationItem.searchController = search
        // hidesSearchBarWhenScrolling default is true — the script's
        // scroll-200 capture is that hide.
        searchController = search

        // OpenUIKit's navigation bar has no automatic content-scroll-view
        // detection (UIViewController.setContentScrollView is explicit-only);
        // real UIKit accepts the same call and already tracks this table.
        setContentScrollView(tableView)
    }

    // MARK: Data source

    override func tableView(_ tableView: UITableView,
                             numberOfRowsInSection section: Int) -> Int {
        titles.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier)
            ?? UITableViewCell(style: .default, reuseIdentifier: Self.cellIdentifier)
        cell.textLabel?.text = titles[indexPath.row]
        return cell
    }

    // MARK: UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        applyFilter(query: searchController.searchBar.text ?? "")
    }

    private func applyFilter(query: String) {
        if query.isEmpty {
            titles = Self.allTitles
        } else {
            var filtered: [String] = []
            for title in Self.allTitles {
                if title.hasPrefix(query) { filtered.append(title) }
            }
            titles = filtered
        }
        tableView.reloadData()
    }

    // MARK: Scripted steps (TabsApp.perform)

    /// What tapping the search field does: the bar becomes first responder
    /// (keyboard-up, search moves into the navigation bar).
    func focusSearch() {
        searchController.isActive = true
    }

    /// What typing into the field does. Query "Row 1" matches Row 1 and
    /// Row 10–19 via hasPrefix (no String.contains — guest GATE_B).
    func typeSearch() {
        searchController.searchBar.text = "Row 1"
        updateSearchResults(for: searchController)
    }

    /// What the Cancel control does: clear, resign, restore the full list.
    func cancelSearch() {
        searchController.searchBar.text = ""
        searchController.isActive = false
        updateSearchResults(for: searchController)
    }

    /// What a programmatic scroll of the table does. hidesSearchBarWhenScrolling
    /// default is true, so this is the hide.
    func scrollTable(to y: CGFloat) {
        tableView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
    }
}

// MARK: - Tab 2: toolbar + menu button

final class TabsToolsViewController: UIViewController {

    private var menuButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.setItems([
            UIBarButtonItem(title: "Left", style: .plain, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil),
            UIBarButtonItem(title: "Right", style: .plain, target: nil, action: nil),
        ], animated: false)
        view.addSubview(toolbar)

        let button = UIButton(type: .system)
        button.setTitle("Actions", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.menu = UIMenu(title: "", children: [
            UIAction(title: "Copy") { _ in },
            UIAction(title: "Share") { _ in },
            UIAction(title: "Delete", attributes: .destructive) { _ in },
        ])
        button.showsMenuAsPrimaryAction = true
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        menuButton = button

        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 54),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 32),
        ])
    }

    /// UIButton.performPrimaryAction presents the menu when
    /// showsMenuAsPrimaryAction is set (iOS 17+). Not in the script — a
    /// presented menu hangs on the window and would overlay later captures.
    func showMenu() {
        menuButton.performPrimaryAction()
    }
}

// MARK: - Tab 3: scroll view

final class TabsScrollViewController: UIViewController {

    private var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        scroll.backgroundColor = .systemBackground
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        scrollView = scroll

        let palette: [(CGFloat, CGFloat, CGFloat)] = [
            (0.25, 0.48, 0.85),
            (0.55, 0.35, 0.75),
            (0.90, 0.40, 0.35),
            (0.20, 0.65, 0.50),
            (0.95, 0.70, 0.25),
            (0.35, 0.55, 0.80),
            (0.70, 0.30, 0.45),
            (0.15, 0.55, 0.60),
        ]
        let blockHeight: CGFloat = 120
        var i = 0
        while i < 8 {
            let c = palette[i]
            let block = UIView()
            block.backgroundColor = UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
            block.translatesAutoresizingMaskIntoConstraints = false
            scroll.addSubview(block)
            let top = CGFloat(i) * (blockHeight + 12) + 16
            NSLayoutConstraint.activate([
                block.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor,
                                              constant: 16),
                block.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor,
                                               constant: -16),
                block.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor,
                                            constant: top),
                block.heightAnchor.constraint(equalToConstant: blockHeight),
                block.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor,
                                              constant: -32),
            ])
            i += 1
        }
        let lastBottom = 16 + 8 * (blockHeight + 12) - 12 + 16
        scroll.contentLayoutGuide.heightAnchor.constraint(equalToConstant: lastBottom).isActive = true
        setContentScrollView(scroll)
    }
}
