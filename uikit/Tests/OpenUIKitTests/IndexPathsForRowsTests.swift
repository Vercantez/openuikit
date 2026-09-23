import XCTest
@testable import OpenUIKit

/// `UITableView.indexPathsForRows(in:)` — NetNewsWire RSCore
/// UITableView+RSCore.swift:26/39. MEASURED iPhone 16 / iOS 26.1:
/// Tools/oracle2/indexpathsforrowsprobe/transcript-ios26.1.txt.
@MainActor
final class IndexPathsForRowsTests: XCTestCase {
    private final class DS: NSObject, UITableViewDataSource {
        let rows: [Int]
        init(_ rows: [Int]) { self.rows = rows }
        func numberOfSections(in tableView: UITableView) -> Int { rows.count }
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows[section] }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
    }

    private func table(_ rows: [Int], header: CGFloat) -> (UITableView, DS) {
        let t = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 200), style: .plain)
        let ds = DS(rows)
        t.dataSource = ds
        t.rowHeight = 44
        t.sectionHeaderHeight = header
        t.sectionFooterHeight = 0
        t.reloadData()
        t.layoutIfNeeded()
        return (t, ds)
    }

    private func fmt(_ ips: [IndexPath]?) -> String {
        guard let ips else { return "nil" }
        return "[" + ips.map { "\($0.section).\($0.row)" }.joined(separator: " ") + "]"
    }

    // (rect, measured result) for the plain 10 x 44 pt table.
    private let measuredTenRows: [(CGRect, String)] = [
        (CGRect(x: 0, y: 0, width: 320, height: 200), "[0.0 0.1 0.2 0.3 0.4]"),
        (CGRect(x: 0, y: 44, width: 320, height: 44), "[0.1]"),
        (CGRect(x: 0, y: 43.5, width: 320, height: 1), "[0.0]"),
        (CGRect(x: 0, y: 88, width: 320, height: 0), "[0.2]"),
        (CGRect(x: 0, y: 44, width: 0, height: 44), "[0.1 0.2]"),
        (CGRect(x: 400, y: 0, width: 10, height: 10), "[]"),
        (CGRect(x: 0, y: 1000, width: 320, height: 100), "[]"),
        (CGRect(x: 0, y: -50, width: 320, height: 60), "[0.0]"),
        (.zero, "[0.0]"),
        (.null, "[]"),
        (.infinite, "[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]"),
        (CGRect(x: 0, y: 43.5, width: 320, height: 1.5), "[0.0 0.1]"),
        (CGRect(x: 0, y: 43.5, width: 320, height: 1.51), "[0.0 0.1]"),
        (CGRect(x: 0, y: 43, width: 320, height: 2), "[0.0 0.1]"),
        (CGRect(x: 0, y: 43, width: 320, height: 1.99), "[0.0]"),
        (CGRect(x: 0, y: 10, width: 320, height: 34.99), "[0.0]"),
        (CGRect(x: 0, y: 10, width: 320, height: 35), "[0.0 0.1]"),
        (CGRect(x: 0, y: 10, width: 320, height: 35.01), "[0.0 0.1]"),
        (CGRect(x: 0, y: 0, width: 320, height: 0.5), "[0.0]"),
        (CGRect(x: 0, y: 43.99, width: 320, height: 0.02), "[0.0]"),
        (CGRect(x: 0, y: 44, width: 0.5, height: 44), "[0.1]"),
        (CGRect(x: 0, y: 44, width: 320, height: 44.5), "[0.1]"),
        (CGRect(x: 0, y: 44, width: 320, height: 45), "[0.1 0.2]"),
        (CGRect(x: 319, y: 0, width: 10, height: 10), "[0.0]"),
        (CGRect(x: 320, y: 0, width: 10, height: 10), "[]"),
        (CGRect(x: -10, y: 0, width: 10, height: 10), "[]"),
        (CGRect(x: -10, y: 0, width: 10.5, height: 10), "[0.0]"),
        (CGRect(x: 100, y: 0, width: 0, height: 0), "[0.0]"),
        (CGRect(x: 500, y: 0, width: 0, height: 0), "[]"),
    ]

    func testPlainTenRowsMatchesMeasuredTranscript() {
        let (t, ds) = table([10], header: 0)
        XCTAssertEqual(t.rectForRow(at: IndexPath(row: 1, section: 0)), CGRect(x: 0, y: 44, width: 320, height: 44))
        for (rect, expected) in measuredTenRows {
            XCTAssertEqual(fmt(t.indexPathsForRows(in: rect)), expected, "\(rect)")
        }
        _ = ds
    }

    func testTwoSectionsAndEmptyTable() {
        let (t, ds) = table([2, 3], header: 28)
        // measured: rows 0.0 0.1 1.0 1.1 1.2 at y 0 44 88 132 176 (no header views)
        XCTAssertEqual(t.rectForRow(at: IndexPath(row: 0, section: 1)).minY, 88)
        XCTAssertEqual(fmt(t.indexPathsForRows(in: CGRect(x: 0, y: 0, width: 320, height: 200))), "[0.0 0.1 1.0 1.1 1.2]")
        XCTAssertEqual(fmt(t.indexPathsForRows(in: CGRect(x: 0, y: 88, width: 320, height: 0))), "[1.0]")
        XCTAssertEqual(fmt(t.indexPathsForRows(in: CGRect(x: 0, y: 44, width: 0, height: 44))), "[0.1 1.0]")
        let (e, eds) = table([0], header: 0)
        XCTAssertEqual(fmt(e.indexPathsForRows(in: .infinite)), "[]")
        XCTAssertEqual(fmt(e.indexPathsForRows(in: .zero)), "[]")
        _ = (ds, eds)
    }
}
