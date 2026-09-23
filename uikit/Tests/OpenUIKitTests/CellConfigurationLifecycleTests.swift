import XCTest
@testable import OpenUIKit

/// UICollectionViewCell configuration lifecycle (NetNewsWire's
/// MainFeedCollectionViewCell / MainTimelineCell override
/// updateConfiguration(using:) on a plain UICollectionViewCell). MEASURED
/// iPhone 16 / iOS 26.1: Tools/oracle2/cellconfigprobe/transcript-ios26.1.txt.
@MainActor
final class CellConfigurationLifecycleTests: XCTestCase {
    final class PlainCell: UICollectionViewCell {
        static var events: [String] = []
        var name = ""
        override func updateConfiguration(using state: UICellConfigurationState) {
            super.updateConfiguration(using: state)
            PlainCell.events.append("\(name).update selected=\(state.isSelected) window=\(window != nil) bg=\(backgroundConfiguration == nil ? "nil" : "set")")
        }
    }

    final class Controller: UICollectionViewController {
        init() {
            super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(
                using: .init(appearance: .insetGrouped)))
        }
        required init?(coder: NSCoder) { fatalError() }
        override func viewDidLoad() {
            super.viewDidLoad()
            collectionView.register(PlainCell.self, forCellWithReuseIdentifier: "c")
        }
        override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 2 }
        override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "c", for: indexPath) as! PlainCell
            cell.name = "cell\(indexPath.item)"
            PlainCell.events.append("cellForItemAt \(indexPath.item)")
            return cell
        }
    }

    func testDefaults() {
        let plain = UICollectionViewCell()
        XCTAssertNil(plain.backgroundConfiguration)
        XCTAssertNil(plain.contentConfiguration)
        XCTAssertTrue(plain.automaticallyUpdatesBackgroundConfiguration)
        XCTAssertTrue(plain.automaticallyUpdatesContentConfiguration)
        XCTAssertFalse(plain.configurationState.isSelected)
        let list = UICollectionViewListCell()
        list.layoutIfNeeded()
        XCTAssertNotNil(list.backgroundConfiguration, "MEASURED: a list cell has one")
    }

    func testUpdateRunsOnDisplayAndCoalescesIntoTheNextLayout() {
        PlainCell.events = []
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let controller = Controller()
        window.rootViewController = UINavigationController(rootViewController: controller)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        let cv = controller.collectionView!
        cv.layoutIfNeeded()
        XCTAssertEqual(PlainCell.events, [
            "cellForItemAt 0", "cell0.update selected=false window=true bg=nil",
            "cellForItemAt 1", "cell1.update selected=false window=true bg=nil",
        ], "each displayed cell is configured once, as it is prepared")

        let cell = cv.cellForItem(at: IndexPath(item: 0, section: 0)) as! PlainCell
        PlainCell.events = []
        cell.setNeedsUpdateConfiguration()
        XCTAssertEqual(PlainCell.events, [], "not synchronous")
        cell.isSelected = true
        XCTAssertEqual(PlainCell.events, [], "not synchronous")
        cv.layoutIfNeeded()
        XCTAssertEqual(PlainCell.events, ["cell0.update selected=true window=true bg=nil"], "one coalesced pass")
    }

    func testBackgroundConfigurationSetByTheAppIsUpdatedAndShown() {
        let cell = UICollectionViewCell(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        var bg = UIBackgroundConfiguration.clear()
        bg.backgroundColor = .red
        cell.backgroundConfiguration = bg
        cell.layoutIfNeeded()
        XCTAssertEqual(cell.backgroundConfiguration?.backgroundColor, .red)
        XCTAssertTrue(cell.subviews.contains { $0 is _UIBackgroundConfigurationView })
        cell.backgroundConfiguration = nil
        XCTAssertFalse(cell.subviews.contains { $0 is _UIBackgroundConfigurationView })
    }
}

/// NetNewsWire MainFeedCollectionViewController / MainTimelineDataSource /
/// TimelineCustomizerCollectionViewController surface.
@MainActor
final class CollectionHooksTests: XCTestCase {
    final class Overriding: UICollectionViewController {
        var primary = 0
        override func collectionView(_ collectionView: UICollectionView, canPerformPrimaryActionForItemAt indexPath: IndexPath) -> Bool { true }
        override func collectionView(_ collectionView: UICollectionView, performPrimaryActionForItemAt indexPath: IndexPath) { primary += 1 }
        override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool { false }
        override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool { false }
        override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {}
        override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? { nil }
    }

    func testHooksAreOverridableWithUIKitNotImplementedDefaults() {
        let base = UICollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
        let cv = base.collectionView!
        let ip = IndexPath(item: 0, section: 0)
        XCTAssertFalse(base.collectionView(cv, canPerformPrimaryActionForItemAt: ip))
        XCTAssertFalse(base.collectionView(cv, shouldShowMenuForItemAt: ip))
        XCTAssertNil(base.collectionView(cv, contextMenuConfigurationForItemAt: ip, point: .zero))
        XCTAssertFalse(base.collectionView(cv, canMoveItemAt: ip))
        let o = Overriding(collectionViewLayout: UICollectionViewFlowLayout())
        XCTAssertTrue(o.collectionView(o.collectionView, canPerformPrimaryActionForItemAt: ip))
    }

    func testSetCollectionViewLayoutReplacesTheLayout() {
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 480),
                                  collectionViewLayout: UICollectionViewFlowLayout())
        let next = UICollectionViewCompositionalLayout.list(using: .init(appearance: .plain))
        cv.setCollectionViewLayout(next, animated: false)
        XCTAssertTrue(cv.collectionViewLayout === next)
    }

    func testSnapshotReconfigureItemsIsRecordedSeparatelyFromReload() {
        var snap = OpenUIKit.NSDiffableDataSourceSnapshot<Int, Int>()
        snap.appendSections([0])
        snap.appendItems([1, 2])
        snap.reconfigureItems([1])
        // MEASURED iOS 26.1: reconfigured [1], reloaded []
        XCTAssertEqual(snap.reconfiguredItemIdentifiers, [1])
        XCTAssertEqual(snap.reloadedItemIdentifiers, [])
        snap.reloadItems([2])
        XCTAssertEqual(snap.reloadedItemIdentifiers, [2])
    }
}
