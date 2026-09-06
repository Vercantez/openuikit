// UITableView tests (M10): cell reuse (the core invariant: only visible
// rows are ever instantiated, recycled cells come back through
// dequeueReusableCell), measured chrome metrics (row/header/footer
// geometry from golden/tableview_*), sticky plain headers, selection via
// the real touch pipeline, and UITableViewController wiring.
import XCTest
import Foundation
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.

// MARK: - Helpers

/// Counts live/total instances so reuse can be proven.
#if !os(Linux)
@MainActor
#endif
private final class CountingCell: UITableViewCell {
    static var created = 0
    override init(style: CellStyle = .default, reuseIdentifier: String? = nil) {
        CountingCell.created += 1
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

/// Deliberately uses UIKit's ordinary non-required override spelling for the
/// reuse initializer. The separate required coder path remains unavailable,
/// as it is for a normal programmatic cell.
private final class CountingHeader: UITableViewHeaderFooterView {
    static var created = 0
    override init(reuseIdentifier: String?) {
        CountingHeader.created += 1
        super.init(reuseIdentifier: reuseIdentifier)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

/// Grandchildren which add designated initializers must not be forced to
/// implement an OpenUIKit-only required initializer. Real UIKit adds no such
/// requirement to either reusable-view hierarchy. They do still satisfy
/// UIView's UIKit-required coder initializer separately.
private class GrandchildBaseCell: UITableViewCell {
    override init(style: CellStyle = .default, reuseIdentifier: String? = nil) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

private final class CustomGrandchildCell: GrandchildBaseCell {
    let marker: Int
    init(marker: Int) {
        self.marker = marker
        super.init(style: .default, reuseIdentifier: nil)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

private class GrandchildBaseHeader: UITableViewHeaderFooterView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

private final class CustomGrandchildHeader: GrandchildBaseHeader {
    let marker: Int
    init(marker: Int) {
        self.marker = marker
        super.init(reuseIdentifier: nil)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

#if !os(Linux)
@MainActor
#endif
private final class BigTableSource: UITableViewDataSource, UITableViewDelegate {
    var rows = 10_000
    var selected: [IndexPath] = []

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "row")
            as? CountingCell ?? CountingCell(style: .default, reuseIdentifier: "row")
        cell.textLabel.text = "Row \(indexPath.row)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected.append(indexPath)
    }
}

/// The tableview_plain fixture's data (3 sections, 7 rows).
#if !os(Linux)
@MainActor
#endif
private final class PlainFixtureSource: UITableViewDataSource, UITableViewDelegate {
    let sections: [(header: String, rows: [String])] = [
        ("Fruits", ["Apple", "Banana", "Cherry"]),
        ("Vegetables", ["Asparagus", "Beetroot"]),
        ("Grains", ["Amaranth", "Barley"]),
    ]
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel.text = sections[indexPath.section].rows[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }
}

/// The tableview_grouped fixture's shape (heights only matter here).
#if !os(Linux)
@MainActor
#endif
private final class GroupedFixtureSource: UITableViewDataSource, UITableViewDelegate {
    // (style, header, footer, row styles)
    let sections: [(header: String, footer: String, styles: [UITableViewCell.CellStyle])] = [
        ("Account", "Your account details are synced across devices.",
         [.value1, .value1, .default]),
        ("Notifications", "Alerts appear on the lock screen.",
         [.subtitle, .default, .subtitle]),
    ]
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].styles.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: sections[indexPath.section].styles[indexPath.row],
                                   reuseIdentifier: nil)
        cell.textLabel.text = "r\(indexPath.row)"
        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].footer
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        sections[indexPath.section].styles[indexPath.row] == .subtitle
            ? UITableViewCell.subtitleRowHeight
            : UITableView.automaticDimension
    }
}

#if !os(Linux)
@MainActor
#endif
final class TableViewReuseTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        CountingCell.created = 0
        CountingHeader.created = 0
    }

    /// The reuse gate: sweeping a 10k-row table end to end must never
    /// instantiate more than roughly one screenful of cells.
    func testTenThousandRowScrollInstantiatesOnlyVisibleCells() {
        let source = BigTableSource()
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 600),
                                style: .plain)
        table.dataSource = source
        table.delegate = source
        table.layoutIfNeeded()

        let expectedContentH = 10_000 * UITableViewCell.defaultRowHeight
        XCTAssertEqual(table.contentSize.height, expectedContentH, accuracy: 0.001)

        // Fully visible + the two partial rows at the edges.
        let maxVisible = Int((600 / UITableViewCell.defaultRowHeight).rounded(.up)) + 1
        XCTAssertLessThanOrEqual(table.visibleCells.count, maxVisible)
        XCTAssertGreaterThan(table.visibleCells.count, 0)

        // Sweep the whole table in screen-sized steps, then in row steps.
        let maxOffset = expectedContentH - 600
        var y: CGFloat = 0
        while y < maxOffset {
            table.contentOffset = CGPoint(x: 0, y: y)
            XCTAssertLessThanOrEqual(table.visibleCells.count, maxVisible)
            y += 600
        }
        for step in 0..<200 {
            table.contentOffset = CGPoint(x: 0, y: CGFloat(step) * 17.25)
        }
        // Live cells ≈ visible + a couple of spares in the reuse pool.
        XCTAssertLessThanOrEqual(
            CountingCell.created, maxVisible + 2,
            "reuse failed: \(CountingCell.created) cells created for a \(maxVisible)-row viewport")
    }

    func testDequeueRecyclesAndPreparesForReuse() {
        let source = BigTableSource()
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 200),
                                style: .plain)
        table.dataSource = source
        table.delegate = source
        table.layoutIfNeeded()

        guard let first = table.cellForRow(at: IndexPath(row: 0, section: 0)) else {
            return XCTFail("row 0 not tiled")
        }
        first.setSelected(true, animated: false)

        // Push row 0 far out of the viewport: its cell is recycled and
        // immediately dequeued (prepareForReuse) for an incoming row.
        table.contentOffset = CGPoint(x: 0, y: 2000)
        XCTAssertNil(table.cellForRow(at: IndexPath(row: 0, section: 0)))
        XCTAssertTrue(table.visibleCells.contains { $0 === first },
                      "expected the retired cell to be reused for an incoming row")
        XCTAssertNotEqual(table.indexPath(for: first), IndexPath(row: 0, section: 0))
        XCTAssertFalse(first.isSelected, "prepareForReuse must clear selection")
        XCTAssertNil(table.dequeueReusableCell(withIdentifier: "unknown"))
    }

    func testRegisteredClassIsInstantiatedByDequeue() {
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 200))
        table.register(CountingCell.self, forCellReuseIdentifier: "counting")
        let cell = table.dequeueReusableCell(withIdentifier: "counting")
        XCTAssertTrue(cell is CountingCell)
        XCTAssertEqual(cell?.reuseIdentifier, "counting")
        XCTAssertEqual(CountingCell.created, 1)
    }

    func testRegisteredHeaderClassUsesOrdinaryOverrideInitializer() {
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 200))
        table.register(CountingHeader.self,
                       forHeaderFooterViewReuseIdentifier: "header")
        let header = table.dequeueReusableHeaderFooterView(withIdentifier: "header")
        XCTAssertTrue(header is CountingHeader)
        XCTAssertEqual(header?.reuseIdentifier, "header")
        XCTAssertEqual(CountingHeader.created, 1)
    }

    func testReusableViewGrandchildrenMayAddDesignatedInitializers() {
        XCTAssertEqual(CustomGrandchildCell(marker: 41).marker, 41)
        XCTAssertEqual(CustomGrandchildHeader(marker: 42).marker, 42)
    }
}

#if !os(Linux)
@MainActor
#endif
final class TableViewCompatibilityTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    func testHeaderFooterAndBackgroundParticipateInScrollGeometry() {
        let source = BigTableSource()
        source.rows = 1
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 60))
        let background = UIView()
        table.backgroundView = background
        table.tableHeaderView = UIView(frame: CGRect(x: 12, y: 7, width: 20, height: 10))
        table.tableFooterView = UIView(frame: CGRect(x: 5, y: 3, width: 20, height: 20))
        table.dataSource = source
        table.delegate = source
        table.layoutIfNeeded()

        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 0)).minY, 10)
        XCTAssertEqual(table.contentSize.height,
                       10 + UITableViewCell.defaultRowHeight + 20,
                       accuracy: 0.001)
        XCTAssertEqual(table.tableHeaderView?.frame,
                       CGRect(x: 0, y: 0, width: 320, height: 10))
        XCTAssertEqual(table.tableFooterView?.frame.minY ?? -1,
                       10 + UITableViewCell.defaultRowHeight,
                       accuracy: 0.001)
        XCTAssertEqual(background.frame, table.bounds)

        table.contentOffset = CGPoint(x: 0, y: 12)
        XCTAssertEqual(background.frame, table.bounds,
                       "the background remains fixed to the visible bounds")
    }

    func testBatchDeletionRebuildsAgainstTheMutatedDataSourceAtEndUpdates() {
        let source = BigTableSource()
        source.rows = 3
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        table.dataSource = source
        table.delegate = source
        table.layoutIfNeeded()
        XCTAssertEqual(table.numberOfRows(inSection: 0), 3)

        table.beginUpdates()
        source.rows = 2
        table.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .fade)
        XCTAssertEqual(table.numberOfRows(inSection: 0), 3,
                       "a batch is committed atomically by endUpdates")
        table.endUpdates()

        XCTAssertEqual(table.numberOfRows(inSection: 0), 2)
        XCTAssertNil(table.cellForRow(at: IndexPath(row: 2, section: 0)))
    }

    func testMultipleSelectionAndEditingStateReachVisibleCells() {
        let source = BigTableSource()
        source.rows = 3
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        table.dataSource = source
        table.delegate = source
        table.allowsMultipleSelection = true
        table.layoutIfNeeded()

        table.selectRow(at: IndexPath(row: 0, section: 0), animated: false)
        table.selectRow(at: IndexPath(row: 1, section: 0), animated: false)
        XCTAssertEqual(table.indexPathsForSelectedRows,
                       [IndexPath(row: 0, section: 0), IndexPath(row: 1, section: 0)])

        table.setEditing(true, animated: false)
        XCTAssertTrue(table.isEditing)
        XCTAssertTrue(table.visibleCells.allSatisfy(\.isEditing))
        XCTAssertNil(table.indexPathsForSelectedRows,
                     "selection is cleared when editing selection is disabled")
    }

    func testExplicitZeroSeparatorInsetOverridesStyleDefault() {
        let source = BigTableSource()
        source.rows = 1
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
        table.dataSource = source
        table.delegate = source
        table.layoutIfNeeded()
        let cell = table.cellForRow(at: IndexPath(row: 0, section: 0))!

        XCTAssertEqual(cell.separatorView.frame.minX, 16)
        cell.separatorInset = .zero
        cell.layoutIfNeeded()
        XCTAssertEqual(cell.separatorView.frame.minX, 0)
        XCTAssertEqual(cell.separatorView.frame.width, 320)
    }
}

#if !os(Linux)
@MainActor
#endif
final class TableViewMetricsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    /// Measured plain chrome (golden/tableview_plain.layout.json): 22 pt
    /// padding + 40.5 pt header per section, 51.5 pt rows.
    func testPlainRowGeometryMatchesGolden() {
        let source = PlainFixtureSource()
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 480),
                                style: .plain)
        table.dataSource = source
        table.delegate = source
        table.layoutIfNeeded()

        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 0)).minY, 62.5)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 1, section: 0)).minY, 114)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 2, section: 0)).minY, 165.5)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 1)).minY, 279.5)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 1, section: 1)).minY, 331)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 2)).minY, 445)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 1, section: 2)).minY, 496.5)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 0)).width, 375)
        XCTAssertEqual(table.contentSize.height, 548, accuracy: 0.001)

        // Barley (496.5) starts below the 480 pt viewport: never built.
        XCTAssertNil(table.cellForRow(at: IndexPath(row: 1, section: 2)))
        XCTAssertEqual(table.visibleCells.count, 6)
    }

    /// Measured inset-grouped chrome (golden/tableview_grouped.layout.json):
    /// no top padding, 40.5 pt headers, 30 pt one-line footers, 70.5 pt
    /// subtitle rows, 8 pt side inset.
    func testGroupedGeometryMatchesGolden() {
        let source = GroupedFixtureSource()
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 620),
                                style: .insetGrouped)
        table.dataSource = source
        table.delegate = source
        table.layoutIfNeeded()

        let r0 = table.rectForRow(at: IndexPath(row: 0, section: 0))
        XCTAssertEqual(r0.minY, 40.5)
        XCTAssertEqual(r0.minX, 8)
        XCTAssertEqual(r0.width, 359)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 2, section: 0)).maxY, 195)
        // Footer 30 pt, then the next header at 225.
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 1)).minY, 265.5)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 1)).height, 70.5)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 2, section: 1)).maxY, 458)
        XCTAssertEqual(table.contentSize.height, 488, accuracy: 0.001)

        // Real-window metrics: switching the side inset re-tiles the cards.
        table.insetGroupedSideInset = 16
        table.layoutIfNeeded()
        let r16 = table.rectForRow(at: IndexPath(row: 0, section: 0))
        XCTAssertEqual(r16.minX, 16)
        XCTAssertEqual(r16.width, 343)
    }

    func testPlainHeaderSticksToVisibleTop() {
        let source = PlainFixtureSource()
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 300),
                                style: .plain)
        table.dataSource = source
        table.delegate = source
        table.layoutIfNeeded()

        // At rest the first header sits at its natural 22 pt.
        XCTAssertEqual(table.headerViews[0]?.frame.minY, 22)

        // Scrolled into section 0: the header pins to the offset.
        table.contentOffset = CGPoint(x: 0, y: 100)
        XCTAssertEqual(table.headerViews[0]?.frame.minY, 100)

        // Near the section end it is pushed out by the next section
        // (rows end 217 − 40.5 = 176.5).
        table.contentOffset = CGPoint(x: 0, y: 190)
        XCTAssertEqual(table.headerViews[0]?.frame.minY, 176.5)

        // Past the section: header 0 is retired; header 1 pins.
        table.contentOffset = CGPoint(x: 0, y: 248)
        XCTAssertNil(table.headerViews[0])
        XCTAssertEqual(table.headerViews[1]?.frame.minY, 248)
    }

    func testGroupedLastRowHasNoSeparator() {
        let source = GroupedFixtureSource()
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 620),
                                style: .insetGrouped)
        table.dataSource = source
        table.delegate = source
        table.layoutIfNeeded()

        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 0, section: 0))?
            .separatorView.isHidden, false)
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 2, section: 0))?
            .separatorView.isHidden, true)
    }
}

#if !os(Linux)
@MainActor
#endif
final class TableViewSelectionTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    private func makeTappableTable()
        -> (window: UIWindow, table: UITableView, source: BigTableSource) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 600))
        let source = BigTableSource()
        source.rows = 20
        let table = UITableView(frame: window.bounds, style: .plain)
        table.dataSource = source
        table.delegate = source
        window.addSubview(table)
        window.layoutIfNeeded()
        return (window, table, source)
    }

    /// A tap: touch-down highlights (after the content-touch delay flush on
    /// the up event — UIKit's quick-tap behavior), touch-up selects and
    /// fires didSelectRowAt.
    func testTapSelectsRowAndFiresDelegate() {
        let (window, table, source) = makeTappableTable()
        // Row 2 spans y 103..154.5.
        window.sendTouch(.began, at: CGPoint(x: 200, y: 120), timestamp: 0)
        window.sendTouch(.ended, at: CGPoint(x: 200, y: 120), timestamp: 0.05)

        XCTAssertEqual(source.selected, [IndexPath(row: 2, section: 0)])
        XCTAssertEqual(table.indexPathForSelectedRow, IndexPath(row: 2, section: 0))
        let cell = table.cellForRow(at: IndexPath(row: 2, section: 0))!
        XCTAssertTrue(cell.isSelected)
        XCTAssertEqual(cell.selectedBackgroundView?.alpha, 1)
        // Measured separator rule: the selected row and the one above lose
        // their separators.
        XCTAssertEqual(cell.separatorView.isHidden, true)
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 1, section: 0))?
            .separatorView.isHidden, true)
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 0, section: 0))?
            .separatorView.isHidden, false)

        // Selecting another row deselects the first (didDeselect path).
        window.sendTouch(.began, at: CGPoint(x: 200, y: 60), timestamp: 1.0)
        window.sendTouch(.ended, at: CGPoint(x: 200, y: 60), timestamp: 1.05)
        XCTAssertEqual(table.indexPathForSelectedRow, IndexPath(row: 1, section: 0))
        XCTAssertFalse(cell.isSelected)

        // deselectRow clears the highlight state.
        table.deselectRow(at: IndexPath(row: 1, section: 0), animated: false)
        XCTAssertNil(table.indexPathForSelectedRow)
    }

    /// Dragging along the scrollable axis cancels the press: the row
    /// un-highlights and no selection is committed (the scroll view's
    /// content-touch cancellation, same feel as DemoApp rows).
    func testDragCancelsRowHighlightAndSelection() {
        let (window, table, source) = makeTappableTable()
        window.sendTouch(.began, at: CGPoint(x: 200, y: 300), timestamp: 0)
        // Hold still past the content-touch delay so the touch is DELIVERED
        // (row highlighted), then drag: the pan claims the touch.
        window.tick(timestamp: 0.2)
        let path = IndexPath(row: 5, section: 0)
        XCTAssertEqual(table.cellForRow(at: path)?.isHighlighted, true)
        for i in 1...6 {
            window.sendTouch(.moved, at: CGPoint(x: 200, y: 300 - CGFloat(i) * 8),
                             timestamp: 0.2 + Double(i) * 0.016)
        }
        XCTAssertEqual(table.cellForRow(at: path)?.isHighlighted, false)
        window.sendTouch(.ended, at: CGPoint(x: 200, y: 252), timestamp: 0.4)
        XCTAssertTrue(source.selected.isEmpty)
        XCTAssertNil(table.indexPathForSelectedRow)
        XCTAssertGreaterThan(table.contentOffset.y, 0)
    }

    /// A selected row that scrolls out and back in keeps its selection
    /// (state lives on the table, not the recycled cell).
    func testSelectionSurvivesRecycling() {
        let (_, table, source) = makeTappableTable()
        source.rows = 100
        table.reloadData()
        table.layoutIfNeeded()
        table.selectRow(at: IndexPath(row: 0, section: 0), animated: false)
        table.contentOffset = CGPoint(x: 0, y: 2000)
        XCTAssertNil(table.cellForRow(at: IndexPath(row: 0, section: 0)))
        table.contentOffset = .zero
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 0, section: 0))?.isSelected, true)
    }
}

// MARK: - UITableViewController

#if !os(Linux)
@MainActor
#endif
private final class TestTableController: UITableViewController {
    var didSelect: [IndexPath] = []
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        4
    }
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel.text = "Row \(indexPath.row)"
        return cell
    }
    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        "Header"
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelect.append(indexPath)
    }
}

#if !os(Linux)
@MainActor
#endif
final class TableViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    /// The controller's view IS the table; subclass overrides are reached
    /// through the protocol witnesses (the protocol-extension dispatch
    /// pitfall this class exists to avoid).
    func testControllerWiresTableAndDispatchesOverrides() {
        let vc = TestTableController(style: .plain)
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        vc.view.layoutIfNeeded()

        XCTAssertTrue(vc.view === vc.tableView)
        XCTAssertTrue(vc.tableView.dataSource === vc)
        XCTAssertEqual(vc.tableView.numberOfSections, 1)
        XCTAssertEqual(vc.tableView.numberOfRows(inSection: 0), 4)
        // titleForHeader override reached → measured header chrome applies.
        XCTAssertEqual(vc.tableView.rectForRow(at: IndexPath(row: 0, section: 0)).minY,
                       22 + 40.5)
        XCTAssertEqual(vc.tableView.visibleCells.count, 4)
        XCTAssertEqual(vc.tableView.visibleCells.first?.textLabel.text, "Row 0")

        vc.tableView.commitRowTap(on: vc.tableView.visibleCells[2])
        XCTAssertEqual(vc.didSelect, [IndexPath(row: 2, section: 0)])
    }
}

// MARK: - Animated updates (identity-matched moves)

/// Two sections holding reference-typed items, so an item's identity is
/// stable while it moves between them (the Tasks app's shape).
#if !os(Linux)
@MainActor
#endif
private final class MovableSource: UITableViewDataSource, UITableViewDelegate {
    #if !os(Linux)
    @MainActor
    #endif
    final class Item { let name: String; init(_ n: String) { name = n } }
    var sections: [[Item]] = [
        [Item("a"), Item("b"), Item("c")],
        [Item("x")],
    ]

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection s: Int) -> Int {
        sections[s].count
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection s: Int) -> String? {
        s == 0 ? "Open" : "Done"
    }
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "row")
            ?? UITableViewCell(style: .default, reuseIdentifier: "row")
        cell.textLabel.text = sections[indexPath.section][indexPath.row].name
        return cell
    }

    func identity(_ p: IndexPath) -> AnyHashable {
        ObjectIdentifier(sections[p.section][p.row])
    }
}

/// Explicit row arrays for UIKit-compatible `moveRow(at:to:)` tests. The
/// reference-typed item lets the assertions distinguish item identity from an
/// index path whose meaning changes during the move.
#if !os(Linux)
@MainActor
#endif
private final class RowMoveSource: UITableViewDataSource {
    #if !os(Linux)
    @MainActor
    #endif
    final class Item {
        let name: String
        init(_ name: String) { self.name = name }
    }

    var sections: [[Item]]
    var requestedPaths: [IndexPath] = []

    init(_ names: [[String]]) {
        sections = names.map { $0.map(Item.init) }
    }

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        requestedPaths.append(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "move-row")
            ?? UITableViewCell(style: .default, reuseIdentifier: "move-row")
        cell.textLabel.text = sections[indexPath.section][indexPath.row].name
        return cell
    }

    func move(from source: IndexPath, to destination: IndexPath) {
        let item = sections[source.section].remove(at: source.row)
        sections[destination.section].insert(item, at: destination.row)
    }

    func insert(_ name: String, at destination: IndexPath) {
        sections[destination.section].insert(Item(name), at: destination.row)
    }
}

#if !os(Linux)
@MainActor
#endif
final class TableViewRowMoveTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    private func makeTable(_ names: [[String]], height: CGFloat = 400)
        -> (UIWindow, UITableView, RowMoveSource) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: height))
        let source = RowMoveSource(names)
        let table = UITableView(frame: window.bounds, style: .plain)
        table.rowHeight = 44
        table.dataSource = source
        window.addSubview(table)
        window.layoutIfNeeded()
        return (window, table, source)
    }

    private func cells(in table: UITableView, section: Int, count: Int)
        -> [UITableViewCell] {
        (0..<count).map {
            table.cellForRow(at: IndexPath(row: $0, section: section))!
        }
    }

    /// iOS 26.1 oracle: A moves 0→2, B/C shift up, D stays put, and every
    /// visible item keeps the exact cell it had before the move.
    func testDirectMovePreservesCellsFramesOrderAndMultipleSelection() {
        let (window, table, source) = makeTable([["A", "B", "C", "D"]])
        let before = cells(in: table, section: 0, count: 4)
        let beforeFrames = before.map(\.frame)
        table.allowsMultipleSelection = true
        table.selectRow(at: IndexPath(row: 0, section: 0), animated: false)
        table.selectRow(at: IndexPath(row: 2, section: 0), animated: false)

        let from = IndexPath(row: 0, section: 0)
        let to = IndexPath(row: 2, section: 0)
        source.move(from: from, to: to)
        table.moveRow(at: from, to: to)
        window.layoutIfNeeded()

        let after = cells(in: table, section: 0, count: 4)
        XCTAssertTrue(after[0] === before[1])
        XCTAssertTrue(after[1] === before[2])
        XCTAssertTrue(after[2] === before[0])
        XCTAssertTrue(after[3] === before[3])
        XCTAssertEqual(after.map { $0.textLabel.text }, ["B", "C", "A", "D"])
        XCTAssertEqual(after.map(\.frame), beforeFrames)
        XCTAssertEqual(table.indexPathForSelectedRow, IndexPath(row: 2, section: 0))
        XCTAssertEqual(table.indexPathsForSelectedRows,
                       [IndexPath(row: 1, section: 0), IndexPath(row: 2, section: 0)])
        XCTAssertTrue(after[1].isSelected)
        XCTAssertTrue(after[2].isSelected)
    }

    func testSameSourceAndDestinationPreservesIdentityFramesAndSelection() {
        let (window, table, source) = makeTable([["A", "B", "C", "D"]])
        let before = cells(in: table, section: 0, count: 4)
        let beforeFrames = before.map(\.frame)
        table.allowsMultipleSelection = true
        table.selectRow(at: IndexPath(row: 1, section: 0), animated: false)
        table.selectRow(at: IndexPath(row: 2, section: 0), animated: false)

        let unchanged = IndexPath(row: 1, section: 0)
        source.move(from: unchanged, to: unchanged)
        table.moveRow(at: unchanged, to: unchanged)
        window.layoutIfNeeded()

        let after = cells(in: table, section: 0, count: 4)
        for index in before.indices {
            XCTAssertTrue(after[index] === before[index])
        }
        XCTAssertEqual(after.map(\.frame), beforeFrames)
        XCTAssertEqual(after.map { $0.textLabel.text }, ["A", "B", "C", "D"])
        XCTAssertEqual(table.indexPathForSelectedRow, unchanged)
        XCTAssertEqual(table.indexPathsForSelectedRows,
                       [unchanged, IndexPath(row: 2, section: 0)])
        XCTAssertTrue(after[1].isSelected)
        XCTAssertTrue(after[2].isSelected)
    }

    /// The pure single-move fast path is deferred until the outer batch ends,
    /// then applies the same identity/selection permutation as a direct move.
    func testSingleMoveInsideBeginEndUpdatesIsAtomicAndIdentityPreserving() {
        let (window, table, source) = makeTable([["A", "B", "C", "D"]])
        let before = cells(in: table, section: 0, count: 4)
        let beforeFrames = before.map(\.frame)
        table.selectRow(at: IndexPath(row: 2, section: 0), animated: false)

        let from = IndexPath(row: 3, section: 0)
        let to = IndexPath(row: 1, section: 0)
        table.beginUpdates()
        source.move(from: from, to: to)
        table.moveRow(at: from, to: to)
        XCTAssertTrue(table.cellForRow(at: IndexPath(row: 1, section: 0)) === before[1],
                      "the old slot map stays visible until endUpdates")
        XCTAssertEqual(table.indexPathForSelectedRow, IndexPath(row: 2, section: 0))
        table.endUpdates()
        window.layoutIfNeeded()

        let after = cells(in: table, section: 0, count: 4)
        XCTAssertTrue(after[0] === before[0])
        XCTAssertTrue(after[1] === before[3])
        XCTAssertTrue(after[2] === before[1])
        XCTAssertTrue(after[3] === before[2])
        XCTAssertEqual(after.map { $0.textLabel.text }, ["A", "D", "B", "C"])
        XCTAssertEqual(after.map(\.frame), beforeFrames)
        XCTAssertEqual(table.indexPathForSelectedRow, IndexPath(row: 3, section: 0))
        XCTAssertEqual(table.indexPathsForSelectedRows, [IndexPath(row: 3, section: 0)])
    }

    func testCrossSectionMoveRekeysBothSectionsAndSelection() {
        let (window, table, source) = makeTable([["A", "B", "C"], ["X", "Y"]])
        let before = Dictionary(uniqueKeysWithValues: table.visibleCells.map {
            ($0.textLabel.text!, $0)
        })
        table.allowsMultipleSelection = true
        table.selectRow(at: IndexPath(row: 1, section: 0), animated: false)
        table.selectRow(at: IndexPath(row: 1, section: 1), animated: false)

        let from = IndexPath(row: 1, section: 0)
        let to = IndexPath(row: 1, section: 1)
        source.move(from: from, to: to)
        table.moveRow(at: from, to: to)
        window.layoutIfNeeded()

        let expected: [(String, IndexPath)] = [
            ("A", IndexPath(row: 0, section: 0)),
            ("C", IndexPath(row: 1, section: 0)),
            ("X", IndexPath(row: 0, section: 1)),
            ("B", IndexPath(row: 1, section: 1)),
            ("Y", IndexPath(row: 2, section: 1)),
        ]
        for (name, path) in expected {
            XCTAssertTrue(table.cellForRow(at: path) === before[name])
        }
        XCTAssertEqual(table.visibleCells.map { $0.textLabel.text },
                       ["A", "C", "X", "B", "Y"])
        XCTAssertEqual(table.indexPathForSelectedRow, IndexPath(row: 1, section: 1))
        XCTAssertEqual(table.indexPathsForSelectedRows,
                       [IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 1)])
    }

    func testOffscreenSelectionFollowsMoveIntoVisibleViewport() {
        let names = (0..<100).map { "R\($0)" }
        let (window, table, source) = makeTable([names], height: 100)
        let rowZero = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        let rowOne = table.cellForRow(at: IndexPath(row: 1, section: 0))!
        table.selectRow(at: IndexPath(row: 80, section: 0), animated: false)

        let from = IndexPath(row: 80, section: 0)
        let to = IndexPath(row: 1, section: 0)
        source.move(from: from, to: to)
        table.moveRow(at: from, to: to)
        window.layoutIfNeeded()

        XCTAssertTrue(table.cellForRow(at: IndexPath(row: 0, section: 0)) === rowZero)
        XCTAssertTrue(table.cellForRow(at: IndexPath(row: 2, section: 0)) === rowOne)
        XCTAssertEqual(table.cellForRow(at: to)?.textLabel.text, "R80")
        XCTAssertEqual(table.cellForRow(at: to)?.isSelected, true)
        XCTAssertEqual(table.indexPathForSelectedRow, to)
    }

    func testMultipleMovesInOneBatchUseCoherentRebuildFallback() {
        let (window, table, source) = makeTable([["A", "B", "C", "D"]])
        table.beginUpdates()
        source.move(from: IndexPath(row: 0, section: 0),
                    to: IndexPath(row: 2, section: 0))
        table.moveRow(at: IndexPath(row: 0, section: 0),
                      to: IndexPath(row: 2, section: 0))
        source.move(from: IndexPath(row: 3, section: 0),
                    to: IndexPath(row: 1, section: 0))
        table.moveRow(at: IndexPath(row: 3, section: 0),
                      to: IndexPath(row: 1, section: 0))
        table.endUpdates()
        window.layoutIfNeeded()

        XCTAssertEqual(table.visibleCells.map { $0.textLabel.text }, ["B", "D", "C", "A"])
        XCTAssertEqual(Set(table.visibleCells.map(ObjectIdentifier.init)).count, 4)
        XCTAssertEqual(table.numberOfRows(inSection: 0), 4)
    }

    func testMixedMoveAndInsertBatchUsesCoherentRebuildFallback() {
        let (window, table, source) = makeTable([["A", "B", "C", "D"]])
        table.beginUpdates()
        source.move(from: IndexPath(row: 0, section: 0),
                    to: IndexPath(row: 2, section: 0))
        table.moveRow(at: IndexPath(row: 0, section: 0),
                      to: IndexPath(row: 2, section: 0))
        let inserted = IndexPath(row: 1, section: 0)
        source.insert("X", at: inserted)
        table.insertRows(at: [inserted], with: .none)
        table.endUpdates()
        window.layoutIfNeeded()

        XCTAssertEqual(table.visibleCells.map { $0.textLabel.text },
                       ["B", "X", "C", "A", "D"])
        XCTAssertEqual(Set(table.visibleCells.map(ObjectIdentifier.init)).count, 5)
        XCTAssertEqual(table.numberOfRows(inSection: 0), 5)
    }

    func testNestedBatchSuppressesIntermediateRetileUntilOuterMoveCommit() {
        let names = (0..<100).map { "R\($0)" }
        let (window, table, source) = makeTable([names], height: 100)
        table.selectRow(at: IndexPath(row: 80, section: 0), animated: false)
        source.requestedPaths.removeAll()

        let from = IndexPath(row: 80, section: 0)
        let to = IndexPath(row: 1, section: 0)
        table.beginUpdates()
        table.beginUpdates()
        source.move(from: from, to: to)
        table.moveRow(at: from, to: to)
        table.contentOffset = CGPoint(x: 0, y: 40 * 44)
        table.layoutIfNeeded()

        XCTAssertEqual(source.requestedPaths, [])
        XCTAssertEqual(table.indexPathsForVisibleRows,
                       [IndexPath(row: 0, section: 0),
                        IndexPath(row: 1, section: 0),
                        IndexPath(row: 2, section: 0)])
        table.endUpdates()
        table.layoutIfNeeded()
        XCTAssertEqual(source.requestedPaths, [], "inner end must not commit")

        table.endUpdates()
        window.layoutIfNeeded()

        XCTAssertEqual(table.indexPathsForVisibleRows,
                       [IndexPath(row: 40, section: 0),
                        IndexPath(row: 41, section: 0),
                        IndexPath(row: 42, section: 0)])
        XCTAssertEqual(table.visibleCells.map { $0.textLabel.text },
                       ["R39", "R40", "R41"])
        XCTAssertEqual(Set(table.visibleCells.map(ObjectIdentifier.init)).count, 3)
        XCTAssertEqual(table.indexPathForSelectedRow, to)
    }

    func testQueuedMoveThenReloadUsesFallbackAndRetainsReloadSelectionClearing() {
        let (window, table, source) = makeTable([["A", "B", "C", "D"]])
        table.selectRow(at: IndexPath(row: 2, section: 0), animated: false)
        source.requestedPaths.removeAll()

        table.beginUpdates()
        source.move(from: IndexPath(row: 0, section: 0),
                    to: IndexPath(row: 2, section: 0))
        table.moveRow(at: IndexPath(row: 0, section: 0),
                      to: IndexPath(row: 2, section: 0))
        table.reloadData()
        table.layoutIfNeeded()
        XCTAssertNil(table.indexPathForSelectedRow)
        XCTAssertEqual(source.requestedPaths, [])
        table.endUpdates()
        window.layoutIfNeeded()

        XCTAssertEqual(table.visibleCells.map { $0.textLabel.text }, ["B", "C", "A", "D"])
        XCTAssertEqual(Set(table.visibleCells.map(ObjectIdentifier.init)).count, 4)
        XCTAssertNil(table.indexPathForSelectedRow)
    }

    func testInvalidPositiveSourceFallsBackWithoutShiftingCellsOrSelection() {
        let (window, table, source) = makeTable([["A", "B", "C", "D"]])
        table.selectRow(at: IndexPath(row: 1, section: 0), animated: false)

        table.moveRow(at: IndexPath(row: 99, section: 0),
                      to: IndexPath(row: 0, section: 0))
        window.layoutIfNeeded()

        XCTAssertEqual(table.visibleCells.map { $0.textLabel.text }, ["A", "B", "C", "D"])
        XCTAssertEqual(Set(table.visibleCells.map(ObjectIdentifier.init)).count, 4)
        XCTAssertEqual(table.indexPathForSelectedRow, IndexPath(row: 1, section: 0))
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 1, section: 0))?.isSelected,
                       true)
        _ = source
    }
}

#if !os(Linux)
@MainActor
#endif
final class TableViewAnimatedUpdateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        OpenUIKitRuntime.animationTime = 0
    }

    override func tearDown() {
        OpenUIKitRuntime.animationTime = 0
        super.tearDown()
    }

    private func makeTable() -> (UIWindow, UITableView, MovableSource) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 600))
        let source = MovableSource()
        let table = UITableView(frame: window.bounds, style: .insetGrouped)
        table.dataSource = source
        table.delegate = source
        window.addSubview(table)
        window.layoutIfNeeded()
        return (window, table, source)
    }

    /// The whole point of performUpdates: a row that changes section keeps
    /// its EXACT cell (so animations running inside it survive), and the
    /// cell animates from the slot it used to occupy to its new one.
    func testMovedRowKeepsItsCellAndAnimatesFromTheOldSlot() {
        let (window, table, source) = makeTable()
        let moving = source.sections[0][1]              // "b"
        let cell = table.cellForRow(at: IndexPath(row: 1, section: 0))!
        let oldFrame = cell.frame

        table.performUpdates(withDuration: 0.35,
                             identity: { source.identity($0) },
                             updates: {
            source.sections[0].remove(at: 1)
            source.sections[1].insert(moving, at: 0)
        })
        window.layoutIfNeeded()

        let newPath = IndexPath(row: 0, section: 1)
        XCTAssertTrue(table.cellForRow(at: newPath) === cell,
                      "the moved row must keep its cell, not be re-dequeued")
        XCTAssertEqual(cell.textLabel.text, "b")
        // Model frame = destination; a position animation carries it there
        // from where it was.
        XCTAssertEqual(cell.frame, table.rectForRow(at: newPath))
        XCTAssertNotEqual(cell.frame, oldFrame)
        let move = cell.animations.first { $0.property == .position }
        XCTAssertNotNil(move, "the moved cell should animate its position")
        if case let .point(from)? = move?.from {
            XCTAssertEqual(from.y, oldFrame.midY, accuracy: 0.001)
        } else {
            XCTFail("expected a point-valued position animation")
        }
        // A grouped cell is transparent (the card draws the fill), so it
        // borrows the card colour for the flight across the gap.
        XCTAssertNotNil(cell.backgroundColor)
    }

    /// Rows that stay put still animate into their new slots, and the
    /// section cards resize with them — one coordinated move.
    func testNeighboursAndCardsAnimateAroundTheMove() {
        let (window, table, source) = makeTable()
        let moving = source.sections[0][0]              // "a", the first row
        let follower = table.cellForRow(at: IndexPath(row: 1, section: 0))!
        let followerOld = follower.frame
        let cardOld = table.cardViews[0]!.frame

        table.performUpdates(withDuration: 0.35,
                             identity: { source.identity($0) },
                             updates: {
            source.sections[0].remove(at: 0)
            source.sections[1].append(moving)
        })
        window.layoutIfNeeded()

        XCTAssertTrue(table.cellForRow(at: IndexPath(row: 0, section: 0)) === follower)
        XCTAssertEqual(follower.frame.minY, followerOld.minY - followerOld.height,
                       accuracy: 0.001)
        XCTAssertNotNil(follower.animations.first { $0.property == .position })
        let card = table.cardViews[0]!
        XCTAssertEqual(card.frame.height, cardOld.height - followerOld.height,
                       accuracy: 0.001)
        XCTAssertNotNil(card.animations.first { $0.property == .bounds })
    }

    /// A row with no counterpart before the update fades in; everything
    /// settles on the model values once the clock passes the end (and the
    /// finished animations are dropped, so later tiling can re-frame).
    func testInsertedRowFadesInAndAnimationsAreDroppedOnCompletion() {
        let (window, table, source) = makeTable()
        table.performUpdates(withDuration: 0.3,
                             identity: { source.identity($0) },
                             updates: {
            source.sections[0].insert(MovableSource.Item("new"), at: 0)
        })
        window.layoutIfNeeded()

        let fresh = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        XCTAssertEqual(fresh.textLabel.text, "new")
        XCTAssertEqual(fresh.alpha, 1, "the model alpha is the final value")
        let fade = fresh.animations.first { $0.property == .alpha }
        XCTAssertNotNil(fade)
        if case let .scalar(from)? = fade?.from { XCTAssertEqual(from, 0) }

        OpenUIKitRuntime.animationTime = 0.4
        window.tick(timestamp: 0.4)
        XCTAssertTrue(fresh.animations.isEmpty,
                      "finished animations must be dropped or they keep "
                      + "overriding the frames later tiling assigns")
        let moved = table.cellForRow(at: IndexPath(row: 1, section: 0))!
        XCTAssertTrue(moved.animations.isEmpty)
        XCTAssertNil(moved.backgroundColor)
    }

    /// Reuse still holds across an update: nothing leaks, and a row that
    /// disappears from the visible set goes back to the pool.
    func testUpdateKeepsRowCountAndGeometryConsistent() {
        let (window, table, source) = makeTable()
        table.performUpdates(withDuration: 0.2,
                             identity: { source.identity($0) },
                             updates: {
            let item = source.sections[0].removeLast()
            source.sections[1].insert(item, at: 0)
        })
        window.layoutIfNeeded()

        XCTAssertEqual(table.numberOfRows(inSection: 0), 2)
        XCTAssertEqual(table.numberOfRows(inSection: 1), 2)
        XCTAssertEqual(table.visibleCells.count, 4)
        XCTAssertEqual(table.visibleCells.map { $0.textLabel.text },
                       ["a", "b", "c", "x"])
    }
}

// MARK: - iOS plain subtitle + edit chrome (TableEditor conformance)

#if !os(Linux)
@MainActor
#endif
private final class SubtitleListSource: UITableViewDataSource, UITableViewDelegate {
    var titles = ["Alpha", "Bravo", "Charlie"]
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        titles.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel.text = titles[indexPath.row]
        cell.detailTextLabel?.text = "item \(indexPath.row)"
        return cell
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { true }
}

#if !os(Linux)
@MainActor
#endif
private final class DefaultListSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 3 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel.text = "Row \(indexPath.row + 1)"
        return cell
    }
}

#if !os(Linux)
@MainActor
#endif
final class TableViewIOSEditChromeTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 375, height: 667),
                                     scale: 2)
    }
    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        super.tearDown()
    }

    /// MEASURED TableEditor t200, iPhone SE 2x: plain subtitle cells are
    /// 62 pt, primary at y 9, detail at y 32.5, text x 16.
    func testPlainSubtitleRowIs62OnIOS() {
        let source = SubtitleListSource()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let table = UITableView(frame: window.bounds, style: .plain)
        table.dataSource = source
        table.delegate = source
        window.addSubview(table)
        window.layoutIfNeeded()

        let cell = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        XCTAssertEqual(cell.frame.height, 62, accuracy: 0.001)
        XCTAssertEqual(cell.frame.minY, 0, accuracy: 0.001)
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 1, section: 0))!.frame.minY,
                       62, accuracy: 0.001)
        XCTAssertEqual(cell.textLabel.frame.origin.x, 16, accuracy: 0.001)
        XCTAssertEqual(cell.textLabel.frame.origin.y, 9, accuracy: 0.001)
        XCTAssertEqual(cell.detailTextLabel!.frame.origin.y, 32.5, accuracy: 0.001)
    }

    /// MEASURED Tabs t200 golden PNG + dump, iPhone SE 2x / iOS 26.1:
    /// classic `textLabel` fills the content view (`[16, 0, 343, 52]`,
    /// intrinsic 20.5) and the row is **52** (separator stride 52,
    /// contentSize 1560/30). `defaultContentConfiguration()` stays 53
    /// (`defaultRowHeight`; tableview_grouped / SceneBuilder fixtures).
    func testPlainDefaultLabelFillsContentViewOnIOS() {
        let source = DefaultListSource()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let table = UITableView(frame: window.bounds, style: .plain)
        table.dataSource = source
        window.addSubview(table)
        window.layoutIfNeeded()

        let cell = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        XCTAssertEqual(cell.frame.height, 52, accuracy: 0.001)
        XCTAssertEqual(cell.contentView.frame.height, 52, accuracy: 0.001)
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 1, section: 0))!.frame.minY,
                       52, accuracy: 0.001)
        XCTAssertEqual(cell.textLabel.frame, CGRect(x: 16, y: 0, width: 343, height: 52))
        XCTAssertEqual(cell.textLabel.intrinsicContentSize.height, 20.5, accuracy: 0.001)
        XCTAssertEqual(table.contentSize.height, 156, accuracy: 0.001)
    }

    /// MEASURED rowprobe grouped_classic vs grouped_config, iPhone SE 2x /
    /// iOS 26.1: classic grouped is also 52, but `defaultContentConfiguration()`
    /// (tableview_grouped / Focus) is 53. Grouped automaticDimension stays 53.
    func testGroupedDefaultRowStays53OnIOS() {
        let source = DefaultListSource()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let table = UITableView(frame: window.bounds, style: .insetGrouped)
        table.dataSource = source
        window.addSubview(table)
        window.layoutIfNeeded()

        let cell = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        XCTAssertEqual(cell.frame.height, 53, accuracy: 0.001)
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 1, section: 0))!.frame.minY,
                       53, accuracy: 0.001)
    }

    /// MEASURED Tabs t200, iPhone SE 2x / iOS 26.1: a plain table under a
    /// nav (adjustedContentInset.top 64) has a top hairline on row 0 at
    /// cell y=0. A plain table with no inset does not.
    func testPlainFirstRowHasTopSeparatorWhenUnderlappingOnIOS() {
        let source = DefaultListSource()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let table = UITableView(frame: window.bounds, style: .plain)
        table.dataSource = source
        window.addSubview(table)
        window.layoutIfNeeded()
        XCTAssertTrue(table.cellForRow(at: IndexPath(row: 0, section: 0))!.topSeparatorView.isHidden)

        table.contentInset.top = 64
        table.layoutIfNeeded()
        XCTAssertFalse(table.cellForRow(at: IndexPath(row: 0, section: 0))!.topSeparatorView.isHidden)
        XCTAssertTrue(table.cellForRow(at: IndexPath(row: 1, section: 0))!.topSeparatorView.isHidden)
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 0, section: 0))!.topSeparatorView.frame.minY,
                       0, accuracy: 0.001)
    }

    /// MEASURED Forms t200.dark, iPhone SE 2x / iOS 26.1: `.grouped` cells
    /// with a nil background paint secondarySystemGroupedBackground
    /// (28, 28, 30). Light both resolve to white so light captures do not
    /// move; Catalyst keeps systemBackground.
    func testGroupedCellUsesSecondarySystemGroupedBackgroundOnIOSDark() {
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark,
                                                      displayScale: 2)
        defer {
            UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                          displayScale: 2)
        }
        let source = DefaultListSource()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.overrideUserInterfaceStyle = .dark
        let table = UITableView(frame: window.bounds, style: .grouped)
        table.dataSource = source
        window.addSubview(table)
        window.layoutIfNeeded()
        let cell = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        XCTAssertNotNil(cell.backgroundColor)
        if case .semantic(let name) = cell.backgroundColor!.storage {
            XCTAssertEqual(name, "secondarySystemGroupedBackground")
        } else {
            XCTFail("expected semantic secondarySystemGroupedBackground")
        }
        let c = cell.backgroundColor!.resolvedCGColor(with: UITraitCollection.current)
        XCTAssertEqual(c.red, 28.0 / 255.0, accuracy: 0.002)
        XCTAssertEqual(c.green, 28.0 / 255.0, accuracy: 0.002)
        XCTAssertEqual(c.blue, 30.0 / 255.0, accuracy: 0.002)
    }

    func testGroupedCellKeepsSystemBackgroundOnCatalyst() {
        OpenUIKitRuntime.systemFontCut = .macOS
        let source = DefaultListSource()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let table = UITableView(frame: window.bounds, style: .grouped)
        table.dataSource = source
        window.addSubview(table)
        window.layoutIfNeeded()
        let cell = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        if case .semantic(let name) = cell.backgroundColor!.storage {
            XCTAssertEqual(name, "systemBackground")
        } else {
            XCTFail("expected semantic systemBackground")
        }
    }

    /// MEASURED TableEditor t900, iPhone SE 2x: content view at x 40 width
    /// 292, delete control [15, 18, 26, 26] in a 62 pt row, reorder at
    /// x 332 width 27.
    func testEditModeInsetsAndControlsOnIOS() {
        let source = SubtitleListSource()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let table = UITableView(frame: window.bounds, style: .plain)
        table.dataSource = source
        table.delegate = source
        window.addSubview(table)
        window.layoutIfNeeded()
        table.setEditing(true, animated: false)
        window.layoutIfNeeded()

        let cell = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        XCTAssertEqual(cell.contentView.frame.origin.x, 40, accuracy: 0.001)
        XCTAssertEqual(cell.contentView.frame.width, 292, accuracy: 0.001)
        XCTAssertEqual(cell.textLabel.frame.origin.x, 16, accuracy: 0.001)
        let edit = cell._editControl
        XCTAssertEqual(edit?.isHidden, false)
        XCTAssertEqual(edit?.frame, CGRect(x: 15, y: 18, width: 26, height: 26))
        let reorder = cell._reorderControl!
        XCTAssertEqual(reorder.isHidden, false)
        XCTAssertEqual(reorder.frame.origin.x, 332, accuracy: 0.001)
        XCTAssertEqual(reorder.frame.width, 27, accuracy: 0.001)
        XCTAssertEqual(reorder.frame.height, 62, accuracy: 0.001)

        // MEASURED editredprobe, iPhone SE 2x / iOS 26.1: disc fill is the
        // captured sRGB of UIColor.systemRed, (255, 56, 60), not the
        // pre-sRGB-reencode (235, 75, 70).
        let fill = UITableViewCellEditControl.fill.resolvedCGColor(
            with: UITraitCollection(userInterfaceStyle: .light))
        XCTAssertEqual(fill.red, 255.0 / 255.0, accuracy: 1e-9)
        XCTAssertEqual(fill.green, 56.0 / 255.0, accuracy: 1e-9)
        XCTAssertEqual(fill.blue, 60.0 / 255.0, accuracy: 1e-9)
    }

    /// MEASURED TableEditor t900.dark / t3800.dark, SE 2x: reorder bars
    /// are `.tertiaryLabel` source-over (70,70,73) on black, (111,111,115)
    /// on selected systemGray4. Light over white stays (197,197,199).
    func testReorderInkIsTertiaryLabelOnIOS() {
        let dark = UITraitCollection(userInterfaceStyle: .dark, displayScale: 2)
        let light = UITraitCollection(userInterfaceStyle: .light, displayScale: 2)
        let d = UITableViewCellReorderControl.ink.resolvedCGColor(with: dark)
        XCTAssertEqual(d.red, 0.921569, accuracy: 0.001)
        XCTAssertEqual(d.green, 0.921569, accuracy: 0.001)
        XCTAssertEqual(d.blue, 0.960784, accuracy: 0.001)
        XCTAssertEqual(d.alpha, 0.298039, accuracy: 0.001)
        let l = UITableViewCellReorderControl.ink.resolvedCGColor(with: light)
        XCTAssertEqual(l.red, 0.235294, accuracy: 0.001)
        XCTAssertEqual(l.alpha, 0.298039, accuracy: 0.001)
        OpenUIKitRuntime.systemFontCut = .macOS
        let c = UITableViewCellReorderControl.ink.resolvedCGColor(with: light)
        XCTAssertEqual((c.red * 255).rounded(), 197)
        XCTAssertEqual(c.alpha, 1, accuracy: 1e-9)
    }
}

// MARK: - iOS row insert/delete spring (TableEditor t1350 / t2350)

#if !os(Linux)
@MainActor
#endif
final class TableViewIOSRowAnimationTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        OpenUIKitRuntime.animationTime = 0
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 375, height: 667),
                                     scale: 2)
    }
    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        OpenUIKitRuntime.animationTime = 0
        super.tearDown()
    }

    private func makeList(_ titles: [String]) -> (UIWindow, UITableView, SubtitleListSource) {
        let source = SubtitleListSource()
        source.titles = titles
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let table = UITableView(frame: window.bounds, style: .plain)
        table.dataSource = source
        table.delegate = source
        window.addSubview(table)
        window.layoutIfNeeded()
        return (window, table, source)
    }

    /// MEASURED rowanimprobe, iPhone SE 2x, iOS 26.1: `.fade` delete keeps
    /// the departing cell in place (Charlie frame y 124 throughout) and
    /// springs its opacity 1 → 0; neighbours spring up by one row height.
    /// CASpringAnimation mass 1, stiffness 438.649, damping 41.888, D 0.441.
    func testFadeDeleteSpringsOpacityInPlaceAndSlidesNeighbours() {
        let (window, table, source) = makeList(["Alpha", "Bravo", "Charlie", "Delta"])
        let charlie = table.cellForRow(at: IndexPath(row: 2, section: 0))!
        let delta = table.cellForRow(at: IndexPath(row: 3, section: 0))!
        let charlieFrame = charlie.frame
        let deltaOld = delta.frame

        source.titles.remove(at: 2)
        table.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .fade)

        XCTAssertEqual(charlie.alpha, 0)
        XCTAssertEqual(charlie.frame, charlieFrame)
        let fade = charlie.animations.first { $0.property == .alpha }
        XCTAssertNotNil(fade)
        XCTAssertEqual(fade!.duration, UITableView.iOSRowAnimationDuration, accuracy: 0.001)
        if case let .spring(z, v) = fade!.timing {
            XCTAssertEqual(z, UITableView.iOSRowAnimationDamping, accuracy: 0.001)
            XCTAssertEqual(v, 0, accuracy: 0.001)
        } else {
            XCTFail("delete opacity must be the measured ζ=1 spring")
        }
        if case let .scalar(from) = fade!.from { XCTAssertEqual(from, 1) }

        XCTAssertEqual(delta.frame.minY, deltaOld.minY - charlieFrame.height, accuracy: 0.001)
        let move = delta.animations.first { $0.property == .position }
        XCTAssertNotNil(move, "Delta must spring from its old slot into Charlie's")
        XCTAssertEqual(move!.duration, UITableView.iOSRowAnimationDuration, accuracy: 0.001)

        OpenUIKitRuntime.animationTime = 0.5
        window.tick(timestamp: 0.5)
        XCTAssertNil(charlie.superview, "the departing cell is removed after the spring")
        XCTAssertTrue(delta.animations.isEmpty)
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 2, section: 0))?.textLabel.text, "Delta")
    }

    /// MEASURED rowanimprobe insert of Zero: the new cell is already at the
    /// destination with opacity 1 and no CAAnimation; neighbours spring down
    /// by one row height (Alpha from y 0 to y 62).
    func testAutomaticInsertLeavesNewCellAtRestAndSlidesNeighbours() {
        let (_, table, source) = makeList(["Alpha", "Bravo", "Charlie"])
        let alpha = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        let alphaOld = alpha.frame

        source.titles.insert("Zero", at: 0)
        table.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)

        let zero = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        XCTAssertEqual(zero.textLabel.text, "Zero")
        XCTAssertEqual(zero.alpha, 1)
        XCTAssertEqual(zero.frame.minY, alphaOld.minY, accuracy: 0.001)
        XCTAssertNil(zero.animations.first { $0.property == .alpha },
                     "the inserted cell does not fade")

        XCTAssertTrue(table.cellForRow(at: IndexPath(row: 1, section: 0)) === alpha)
        XCTAssertEqual(alpha.frame.minY, alphaOld.minY + zero.frame.height, accuracy: 0.001)
        XCTAssertNotNil(alpha.animations.first { $0.property == .position })
    }

    /// MEASURED TableEditor t2350: a row that the insert pushes off the
    /// bottom stays in the hierarchy mid-flight (Juliet still in the golden
    /// dump) instead of being retired at dest y.
    func testInsertKeepsARowSpringingOffTheBottom() {
        let titles = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot",
                      "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima"]
        let (_, table, source) = makeList(titles)
        let leaving = table.visibleCells.max { $0.frame.minY < $1.frame.minY }!
        let leavingText = leaving.textLabel.text
        let oldY = leaving.frame.minY

        source.titles.insert("Zero", at: 0)
        table.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)

        XCTAssertEqual(leaving.superview, table, "\(leavingText ?? "?") must stay while it springs off")
        XCTAssertGreaterThan(leaving.frame.minY, oldY)
        XCTAssertNotNil(leaving.animations.first { $0.property == .position })
        XCTAssertNil(leaving.animations.first { $0.property == .bounds },
                     "dest fully off-screen must not spring height from 52")
        XCTAssertFalse(table.visibleCells.contains { $0 === leaving },
                       "off-screen dest is not in the visible map")
    }

    /// MEASURED clipprobe, iPhone SE 2x, iOS 26.1: a 62 pt row whose dest
    /// straddles the visible bottom (Lima dest y 620, visBottom 667) and
    /// whose old slot is fully below it springs bounds 52 → 62 (additive
    /// dH = −10) so the top stays at the old slot. Position Δy = 57 =
    /// (62+52)/2. Fully on-screen neighbours keep height 62.
    func testClippedLastRowSpringsHeightFrom52() {
        let titles = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot",
                      "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima"]
        let (_, table, source) = makeList(titles)
        source.titles.remove(at: 2)
        table.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .fade)

        let lima = table.cellForRow(at: IndexPath(row: 10, section: 0))
            ?? table.subviews.compactMap { $0 as? UITableViewCell }
                .first { $0.textLabel.text == "Lima" }
        XCTAssertNotNil(lima, "Lima must stay as a sliding-in tile")
        XCTAssertEqual(lima?.textLabel.text, "Lima")
        guard let lima else { return }
        XCTAssertEqual(lima.frame.height, 62, accuracy: 0.001)
        let boundsAnim = lima.animations.first { $0.property == .bounds }
        XCTAssertNotNil(boundsAnim, "clipped last row must spring bounds.size")
        if case let .rect(from) = boundsAnim?.from {
            XCTAssertEqual(from.height, UITableView.iOSClippedRowSpringHeight, accuracy: 0.001)
        } else {
            XCTFail("bounds from-value must be a rect of height 52")
        }
        if case let .rect(to) = boundsAnim?.to {
            XCTAssertEqual(to.height, 62, accuracy: 0.001)
        }
        let pos = lima.animations.first { $0.property == .position }
        XCTAssertNotNil(pos)
        if case let .point(p0) = pos?.from, case let .point(p1) = pos?.to {
            XCTAssertEqual(abs(p0.y - p1.y), (62 + 52) / 2, accuracy: 0.001)
        }

        let delta = table.cellForRow(at: IndexPath(row: 2, section: 0))
        XCTAssertEqual(delta?.textLabel.text, "Delta")
        XCTAssertNil(delta?.animations.first { $0.property == .bounds },
                     "fully on-screen Delta must not spring height")
    }

    /// `.none` stays a snap even under the iOS cut — it was not on the
    /// display-tick recording.
    func testNoneStillSnapsOnIOS() {
        let (_, table, source) = makeList(["Alpha", "Bravo", "Charlie"])
        let charlie = table.cellForRow(at: IndexPath(row: 2, section: 0))!
        source.titles.remove(at: 2)
        table.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .none)
        XCTAssertNil(charlie.superview)
        XCTAssertEqual(table.visibleCells.count, 2)
        XCTAssertTrue(table.visibleCells.allSatisfy { $0.animations.isEmpty })
    }

    func testRTLMirrorsDisclosureAndValue1Labels() {
        // MEASURED /tmp/rtlprobe + NavFlow t200.rtl, iPhone SE 2x / iOS 26.1:
        // disclosure abs.x 16; value1 primary sits on the leading (right)
        // edge. Unspecified cells (every existing test) stay LTR.
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.semanticContentAttribute = .forceRightToLeft
        cell.accessoryType = .disclosureIndicator
        cell.textLabel.text = "Notifications"
        cell.detailTextLabel?.text = "On"
        cell.frame = CGRect(x: 0, y: 0, width: 375, height: 44)
        cell.layoutIfNeeded()
        XCTAssertEqual(cell._accessoryGlyphView.frame.origin.x, 16, accuracy: 0.51)
        XCTAssertGreaterThan(cell.textLabel.frame.origin.x, cell.detailTextLabel!.frame.origin.x)
        XCTAssertGreaterThan(cell.textLabel.frame.origin.x, 200)
    }

    /// MEASURED TableEditor t2350.ax1, iPhone SE 2x / iOS 26.1.
    func testEditModeChromeGrowsAtAccessibilityLarge() {
        let savedTraits = UITraitCollection.current
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            preferredContentSizeCategory: .large)
        defer { UITraitCollection.current = savedTraits }

        let source = SubtitleListSource()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.traitOverrides.preferredContentSizeCategory = .accessibilityLarge
        let table = UITableView(frame: window.bounds, style: .plain)
        table.dataSource = source
        table.delegate = source
        window.addSubview(table)
        window.layoutIfNeeded()
        table.setEditing(true, animated: false)
        window.layoutIfNeeded()

        let cell = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        XCTAssertEqual(cell.bounds.height, 117, accuracy: 0.01)
        XCTAssertEqual(cell.contentView.frame.origin.x, 55, accuracy: 0.001)
        XCTAssertEqual(cell.textLabel.frame.origin.x, 16, accuracy: 0.001)
        let edit = cell._editControl
        XCTAssertEqual(edit?.frame, CGRect(x: 16, y: 33, width: 39, height: 38))
        let reorder = cell._reorderControl!
        XCTAssertEqual(reorder.frame.origin.x, 318, accuracy: 0.001)
        XCTAssertEqual(reorder.frame.width, 41, accuracy: 0.001)
        XCTAssertEqual(reorder.frame.height, 117, accuracy: 0.001)
    }

    /// MEASURED TableEditor t200.xxxl / t900.xxxl, iPhone SE 2x / iOS 26.1:
    /// cell **83**, primary y **11**, detail y **42.5**; edit control
    /// **[14.5, 21, 34.5, 34.5]**, content x **47.5**, reorder width **36.5**.
    func testPlainSubtitleRowAndEditChromeAtXxxxl() {
        let savedTraits = UITraitCollection.current
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            preferredContentSizeCategory: .large)
        defer { UITraitCollection.current = savedTraits }

        let source = SubtitleListSource()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.traitOverrides.preferredContentSizeCategory = .extraExtraExtraLarge
        let table = UITableView(frame: window.bounds, style: .plain)
        table.dataSource = source
        table.delegate = source
        window.addSubview(table)
        window.layoutIfNeeded()

        let cell = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        XCTAssertEqual(cell.bounds.height, 83, accuracy: 0.01)
        XCTAssertEqual(cell.textLabel.frame.origin.y, 11, accuracy: 0.01)
        XCTAssertEqual(cell.detailTextLabel!.frame.origin.y, 42.5, accuracy: 0.01)
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 1, section: 0))!.frame.minY,
                       83, accuracy: 0.01)

        table.setEditing(true, animated: false)
        window.layoutIfNeeded()
        let editing = table.cellForRow(at: IndexPath(row: 0, section: 0))!
        XCTAssertEqual(editing.contentView.frame.origin.x, 47.5, accuracy: 0.001)
        XCTAssertEqual(editing.textLabel.frame.origin.x, 16, accuracy: 0.001)
        let edit = editing._editControl
        XCTAssertEqual(edit?.frame, CGRect(x: 14.5, y: 21, width: 34.5, height: 34.5))
        let reorder = editing._reorderControl!
        XCTAssertEqual(reorder.frame.origin.x, 322.5, accuracy: 0.001)
        XCTAssertEqual(reorder.frame.width, 36.5, accuracy: 0.001)
        XCTAssertEqual(reorder.frame.height, 83, accuracy: 0.001)
    }

    /// MEASURED NavFlow t200.ax1, iPhone SE 2x / iOS 26.1: value1
    /// disclosure **20×28.5**, contentView 307, "Automatic" compressed to
    /// 105 against Appearance, "1.2 GB" width 0, label y **3**.
    func testValue1DisclosureAndDetailCompressionAtAccessibilityLarge() {
        let savedTraits = UITraitCollection.current
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            preferredContentSizeCategory: .large)
        defer { UITraitCollection.current = savedTraits }

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.traitOverrides.preferredContentSizeCategory = .accessibilityLarge
        let table = UITableView(frame: window.bounds, style: .insetGrouped)
        let source = NavFlowValue1Source()
        table.dataSource = source
        table.delegate = source
        window.addSubview(table)
        window.layoutIfNeeded()

        let appearance = table.cellForRow(at: IndexPath(row: 1, section: 0))!
        XCTAssertEqual(appearance.bounds.width, 343, accuracy: 0.01)
        XCTAssertEqual(appearance.contentView.bounds.width, 307, accuracy: 0.01)
        XCTAssertEqual(appearance._accessoryGlyphView.frame.size,
                       CGSize(width: 20, height: 28.5))
        XCTAssertEqual(appearance.textLabel.frame.origin.y, 3, accuracy: 0.01)
        XCTAssertEqual(appearance.detailTextLabel!.frame.origin.x, 194, accuracy: 1.5)
        XCTAssertEqual(appearance.detailTextLabel!.frame.width, 105, accuracy: 2)

        let manage = table.cellForRow(at: IndexPath(row: 0, section: 1))!
        XCTAssertEqual(manage.detailTextLabel!.frame.width, 0, accuracy: 0.5)
        XCTAssertEqual(manage.detailTextLabel!.frame.maxX, 299, accuracy: 1.5)
    }

    /// MEASURED Ledger t200.ax1 / t200.xxxl, iPhone SE 2x / iOS 26.1:
    /// disclosure accessory **20×28.5** at ax1 (contentView 307 in a 343
    /// cell) and **14×19.5** at xxxl (contentView 313). `.large` stays 10.5×14.
    func testDisclosureSizeGrowsWithDynamicType() {
        let saved = OpenUIKitRuntime.systemFontCut
        let savedTraits = UITraitCollection.current
        OpenUIKitRuntime.systemFontCut = .iOS
        defer {
            OpenUIKitRuntime.systemFontCut = saved
            UITraitCollection.current = savedTraits
        }
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            preferredContentSizeCategory: .large)
        XCTAssertEqual(UITableViewCell.disclosureSize.width, 10.5, accuracy: 1e-9)
        XCTAssertEqual(UITableViewCell.disclosureSize.height, 14, accuracy: 1e-9)

        let ax = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            preferredContentSizeCategory: .accessibilityLarge)
        XCTAssertEqual(UITableViewCell.disclosureSize(compatibleWith: ax).width,
                       20, accuracy: 1e-9)
        XCTAssertEqual(UITableViewCell.disclosureSize(compatibleWith: ax).height,
                       28.5, accuracy: 1e-9)

        let xxxl = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            preferredContentSizeCategory: .extraExtraExtraLarge)
        XCTAssertEqual(UITableViewCell.disclosureSize(compatibleWith: xxxl).width,
                       14, accuracy: 1e-9)
        XCTAssertEqual(UITableViewCell.disclosureSize(compatibleWith: xxxl).height,
                       19.5, accuracy: 1e-9)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.traitOverrides.preferredContentSizeCategory = .accessibilityLarge
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.accessoryType = .disclosureIndicator
        window.addSubview(cell)
        cell.frame = CGRect(x: 0, y: 0, width: 343, height: 92)
        cell.layoutIfNeeded()
        XCTAssertEqual(cell._accessoryGlyphView.frame.width, 20, accuracy: 0.01)
        XCTAssertEqual(cell._accessoryGlyphView.frame.height, 28.5, accuracy: 0.01)
        XCTAssertEqual(cell.contentView.frame.width, 307, accuracy: 0.01)
    }

    /// MEASURED Ledger t200.landscape, iPhone SE 2x / iOS 26.1:
    /// inset-grouped header label abs.x **40** = card 20 + iOSMargin 20
    /// (window 667 ≥ 390). Portrait 375 stays 32; 393 portrait keeps
    /// inner 16 so realapp_focus_settings does not move.
    func testInsetGroupedHeaderUsesSystemMarginInner() {
        let saved = OpenUIKitRuntime.systemFontCut
        let savedTraits = UITraitCollection.current
        OpenUIKitRuntime.systemFontCut = .iOS
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            verticalSizeClass: .compact, userInterfaceIdiom: .phone)
        defer {
            OpenUIKitRuntime.systemFontCut = saved
            UITraitCollection.current = savedTraits
        }
        let wide = UITableView(frame: CGRect(x: 0, y: 0, width: 667, height: 375),
                               style: .insetGrouped)
        XCTAssertEqual(wide.insetGroupedSideInset, 20)
        XCTAssertEqual(wide.groupedHeaderLabelX, 40, accuracy: 1e-9)
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            userInterfaceIdiom: .phone)
        let narrow = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 667),
                                 style: .insetGrouped)
        XCTAssertEqual(narrow.groupedHeaderLabelX, 32, accuracy: 1e-9)
        let phone393 = UITableView(frame: CGRect(x: 0, y: 0, width: 393, height: 852),
                                  style: .insetGrouped)
        XCTAssertEqual(phone393.insetGroupedSideInset, 20)
        XCTAssertEqual(phone393.groupedHeaderLabelX, 36, accuracy: 1e-9)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class NavFlowValue1Source: UITableViewDataSource, UITableViewDelegate {
    let sections: [(String, [(String, String)])] = [
        ("General", [
            ("Notifications", "On"),
            ("Appearance", "Automatic"),
            ("Downloads", "Wi-Fi"),
        ]),
        ("Storage", [
            ("Manage Downloads", "1.2 GB"),
            ("Clear Cache", ""),
        ]),
    ]
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].1.count
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        let item = sections[indexPath.section].1[indexPath.row]
        cell.textLabel.text = item.0
        cell.detailTextLabel?.text = item.1
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 44 }
}
