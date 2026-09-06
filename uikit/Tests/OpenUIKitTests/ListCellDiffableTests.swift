// List-cell / collection-diffable / swipe-action compile and behaviour tests.
import XCTest
import Foundation
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class ListCellDiffableTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OpenUIKitRuntime.animationTime = 0
    }

    func testListContentConfigurationFactories() {
        let cell = UIListContentConfiguration.cell()
        XCTAssertEqual(cell.styleKind, .cell)
        XCTAssertEqual(cell.directionalLayoutMargins.leading, 16)
        let sub = UIListContentConfiguration.subtitleCell()
        XCTAssertEqual(sub.styleKind, .subtitleCell)
        XCTAssertFalse(sub.prefersSideBySideTextAndSecondaryText)
        let value = UIListContentConfiguration.valueCell()
        XCTAssertTrue(value.prefersSideBySideTextAndSecondaryText)
        let header = UIListContentConfiguration.groupedHeader()
        XCTAssertEqual(header.styleKind, .groupedHeader)
    }

    func testListContentViewLaysOutTextAndSecondary() {
        var cfg = UIListContentConfiguration.subtitleCell()
        cfg.text = "Title"
        cfg.secondaryText = "Subtitle"
        let view = UIListContentView(configuration: cfg)
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 62)
        view.layoutIfNeeded()
        XCTAssertFalse(view.subviews.isEmpty)
        let height = view.preferredHeight(forWidth: 320)
        XCTAssertGreaterThan(height, 40)
        XCTAssertLessThan(height, 90)
    }

    func testCellAccessoriesStandardWidthsMatchTableChrome() {
        let disclosure = UICellAccessory.disclosureIndicator()
        XCTAssertEqual(disclosure.standardWidth(), UITableViewCell.disclosureSize.width)
        let check = UICellAccessory.checkmark()
        XCTAssertEqual(check.standardWidth(), UITableViewCell.checkmarkSize.width)
        let reorder = UICellAccessory.reorder(displayed: .always)
        XCTAssertEqual(reorder.standardWidth(), UITableViewCell.reorderWidth)
        XCTAssertTrue(UICellAccessory.delete(displayed: .always).isLeading)
        XCTAssertFalse(disclosure.isLeading)
    }

    func testBackgroundConfigurationListFills() {
        XCTAssertNil(UIBackgroundConfiguration.listPlainCell().backgroundColor)
        XCTAssertEqual(UIBackgroundConfiguration.listGroupedCell().backgroundColor,
                       UIColor.secondarySystemGroupedBackground)
        let selected = UICellConfigurationState(traitCollection: .current)
        var state = selected
        state.isSelected = true
        let updated = UIBackgroundConfiguration.listPlainCell().updated(for: state)
        XCTAssertNotNil(updated.backgroundColor)
    }

    func testListLayoutSectionInsets() {
        let env = NSCollectionLayoutEnvironment(
            container: NSCollectionLayoutContainer(
                contentSize: CGSize(width: 375, height: 560),
                contentInsets: .zero),
            traitCollection: .current)
        let plain = NSCollectionLayoutSection.list(
            using: UICollectionLayoutListConfiguration(appearance: .plain),
            layoutEnvironment: env)
        XCTAssertEqual(plain.contentInsets.leading, 0)
        let inset = NSCollectionLayoutSection.list(
            using: UICollectionLayoutListConfiguration(appearance: .insetGrouped),
            layoutEnvironment: env)
        XCTAssertEqual(inset.contentInsets.leading, 16)
        XCTAssertEqual(inset.contentInsets.top, 35)
    }

    func testCollectionDiffableApplyInsertDeleteMove() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 500))
        let layout = UICollectionViewCompositionalLayout(
            list: UICollectionLayoutListConfiguration(appearance: .plain))
        let cv = UICollectionView(frame: window.bounds, collectionViewLayout: layout)
        cv.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "c")
        window.addSubview(cv)
        var providerCalls: [Int] = []
        let dataSource = UICollectionViewDiffableDataSource<String, Int>(collectionView: cv) {
            collection, indexPath, item in
            providerCalls.append(item)
            let cell = collection.dequeueReusableCell(withReuseIdentifier: "c",
                                                      for: indexPath) as? UICollectionViewListCell
            var cfg = UIListContentConfiguration.cell()
            cfg.text = "\(item)"
            cell?.contentConfiguration = cfg
            return cell
        }

        var first = OpenUIKit.NSDiffableDataSourceSnapshot<String, Int>()
        first.appendSections(["a", "b"])
        first.appendItems([1, 2], toSection: "a")
        first.appendItems([3], toSection: "b")
        dataSource.apply(first, animatingDifferences: false)
        window.layoutIfNeeded()
        XCTAssertEqual(cv.numberOfSections, 2)
        XCTAssertEqual(cv.numberOfItems(inSection: 0), 2)
        let moved = try XCTUnwrap(cv.cellForItem(at: IndexPath(item: 1, section: 0)))

        var second = dataSource.snapshot()
        second.moveItem(2, beforeItem: 3)
        dataSource.apply(second, animatingDifferences: true)
        window.layoutIfNeeded()
        XCTAssertTrue(cv.cellForItem(at: IndexPath(item: 0, section: 1)) === moved)
        XCTAssertEqual(dataSource.snapshot().itemIdentifiers, [1, 2, 3])

        var deleted = dataSource.snapshot()
        deleted.deleteItems([1])
        dataSource.applySnapshotUsingReloadData(deleted)
        window.layoutIfNeeded()
        XCTAssertEqual(cv.numberOfItems(inSection: 0), 0)
        XCTAssertEqual(cv.numberOfItems(inSection: 1), 2)
        XCTAssertEqual(dataSource.itemIdentifier(for: IndexPath(item: 0, section: 1)), 2)
    }

    func testSectionSnapshotExpandCollapse() {
        var snap = OpenUIKit.NSDiffableDataSourceSectionSnapshot<String>()
        snap.append(["parent"])
        snap.append(["child"], to: "parent")
        snap.collapse(["parent"])
        XCTAssertEqual(snap.visibleItems(), ["parent"])
        XCTAssertEqual(snap.level(of: "child"), 1)
        snap.expand(["parent"])
        XCTAssertEqual(snap.visibleItems(), ["parent", "child"])
        XCTAssertTrue(snap.isExpanded("parent"))
    }

    func testSwipeActionDefaults() {
        let destructive = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in
            done(true)
        }
        XCTAssertEqual(destructive.backgroundColor, UIColor.systemRed)
        let normal = UIContextualAction(style: .normal, title: "Flag") { _, _, done in
            done(true)
        }
        XCTAssertEqual(normal.backgroundColor, UIColor.systemGray)
        let config = UISwipeActionsConfiguration(actions: [destructive, normal])
        XCTAssertTrue(config.performsFirstActionWithFullSwipe)
        XCTAssertEqual(config.actions.count, 2)
        XCTAssertEqual(_UISwipeActionButton.capsuleHeight, 44)
        XCTAssertEqual(_UISwipeActionButton.pullPadding, 10)
        XCTAssertEqual(_UISwipeActionButton.titleFontSize, 13)
        let delBtn = _UISwipeActionButton(action: destructive)
        let flagBtn = _UISwipeActionButton(action: normal)
        XCTAssertGreaterThan(delBtn.preferredWidth(), flagBtn.preferredWidth())
        XCTAssertGreaterThan(flagBtn.preferredWidth(),
                             _UISwipeActionButton.titleInset * 2)
        XCTAssertEqual(_UISwipeActionButton.fullSwipeTravelPt, 260)
        XCTAssertEqual(_UISwipeActionButton.fullSwipeNoFireTravelPt, 250)
    }

    func testTableCellDefaultContentConfigurationMatchesStyle() {
        let def = UITableViewCell(style: .default, reuseIdentifier: nil)
        XCTAssertEqual(def.defaultContentConfiguration().styleKind, .cell)
        let sub = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        XCTAssertEqual(sub.defaultContentConfiguration().styleKind, .subtitleCell)
        let value = UITableViewCell(style: .value1, reuseIdentifier: nil)
        XCTAssertEqual(value.defaultContentConfiguration().styleKind, .valueCell)
    }
}
