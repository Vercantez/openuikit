// UITableView tests (M10): cell reuse (the core invariant: only visible
// rows are ever instantiated, recycled cells come back through
// dequeueReusableCell), measured chrome metrics (row/header/footer
// geometry from golden/tableview_*), sticky plain headers, selection via
// the real touch pipeline, and UITableViewController wiring.
import XCTest
import Foundation
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect
private typealias IndexPath = OpenUIKit.IndexPath

// MARK: - Helpers

/// Counts live/total instances so reuse can be proven.
private final class CountingCell: UITableViewCell {
    static var created = 0
    required init(style: CellStyle = .default, reuseIdentifier: String? = nil) {
        CountingCell.created += 1
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
}

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

final class TableViewReuseTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        CountingCell.created = 0
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
}

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
