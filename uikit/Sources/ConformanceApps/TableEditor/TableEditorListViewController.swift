// TableEditor list-cell screen: a UICollectionViewListCell list driven by
// UICollectionViewDiffableDataSource, with UIListContentConfiguration
// accessories and trailing UISwipeActionsConfiguration. Pushed from the
// existing table so captures 0.20–4.80 stay the same.
import UIKit

nonisolated struct TableEditorListItem: Hashable, Sendable {
    let title: String
    let subtitle: String?
    let accessory: String
}

nonisolated enum TableEditorListSection: Hashable, Sendable {
    case inbox, flags
}

final class TableEditorListViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<
        TableEditorListSection, TableEditorListItem>!

    private let inbox: [TableEditorListItem] = [
        TableEditorListItem(title: "Alpha", subtitle: nil, accessory: "disclosure"),
        TableEditorListItem(title: "Bravo", subtitle: "Second line", accessory: "checkmark"),
        TableEditorListItem(title: "Charlie", subtitle: "Detail", accessory: "value"),
        TableEditorListItem(title: "Delta", subtitle: nil, accessory: "disclosure"),
        TableEditorListItem(title: "Echo", subtitle: "Reorder me", accessory: "none"),
        TableEditorListItem(title: "Foxtrot", subtitle: nil, accessory: "none"),
    ]
    private let flags: [TableEditorListItem] = [
        TableEditorListItem(title: "Starred", subtitle: nil, accessory: "checkmark"),
        TableEditorListItem(title: "Archived", subtitle: "Last week", accessory: "disclosure"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "List"
        view.backgroundColor = .systemGroupedBackground

        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            self?.trailingSwipe(at: indexPath)
        }
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemGroupedBackground
        view.addSubview(cv)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.topAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        collectionView = cv

        cv.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "list")
        dataSource = UICollectionViewDiffableDataSource<TableEditorListSection, TableEditorListItem>(
            collectionView: cv
        ) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "list", for: indexPath) as! UICollectionViewListCell
            TableEditorListViewController.configure(cell: cell, item: item)
            return cell
        }
        applySnapshot()
        setContentScrollView(cv)
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<TableEditorListSection, TableEditorListItem>()
        snapshot.appendSections([.inbox, .flags])
        snapshot.appendItems(inbox, toSection: .inbox)
        snapshot.appendItems(flags, toSection: .flags)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    static func configure(cell: UICollectionViewListCell, item: TableEditorListItem) {
        var cfg: UIListContentConfiguration
        switch item.accessory {
        case "value":
            cfg = .valueCell()
            cfg.secondaryText = item.subtitle
        case "checkmark":
            cfg = item.subtitle == nil ? .cell() : .subtitleCell()
            cfg.secondaryText = item.subtitle
        default:
            cfg = item.subtitle == nil ? .cell() : .subtitleCell()
            cfg.secondaryText = item.subtitle
        }
        cfg.text = item.title
        cell.contentConfiguration = cfg
        var accessories: [UICellAccessory] = []
        switch item.accessory {
        case "disclosure": accessories.append(.disclosureIndicator())
        case "checkmark": accessories.append(.checkmark())
        default: break
        }
        cell.accessories = accessories
        cell.backgroundConfiguration = .listGroupedCell()
    }

    private func trailingSwipe(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in
            done(true)
        }
        let flag = UIContextualAction(style: .normal, title: "Flag") { _, _, done in
            done(true)
        }
        flag.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [delete, flag])
    }

    func selectFirst() {
        collectionView.selectItem(at: IndexPath(item: 0, section: 0),
                                   animated: false, scrollPosition: [])
        if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
            as? UICollectionViewListCell {
            var accessories = cell.accessories
            accessories.append(.checkmark())
            cell.accessories = accessories
        }
    }
}
