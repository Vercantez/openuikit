// UITableView.indexPathsForRows(in:) — NetNewsWire RSCore
// UITableView+RSCore.swift:26/39 (`indexPathsForRows(in: safeAreaLayoutGuide.layoutFrame)`).
//
// swiftc -target arm64-apple-ios26.1-simulator -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
//   main.swift -o probe && xcrun simctl spawn <device> ./probe
import UIKit

final class DS: NSObject, UITableViewDataSource {
    let rows: [Int]
    init(_ rows: [Int]) { self.rows = rows }
    func numberOfSections(in tableView: UITableView) -> Int { rows.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows[section] }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
}

func fmt(_ ips: [IndexPath]?) -> String {
    guard let ips else { return "nil" }
    return "[" + ips.map { "\($0.section).\($0.row)" }.joined(separator: " ") + "]"
}

func run(_ style: UITableView.Style, _ rows: [Int], header: CGFloat?) {
    let t = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 200), style: style)
    let ds = DS(rows)
    t.dataSource = ds
    t.rowHeight = 44
    if let header { t.sectionHeaderHeight = header; t.sectionFooterHeight = 0 }
    t.reloadData()
    t.layoutIfNeeded()
    print("style=\(style.rawValue) rows=\(rows) header=\(header.map { "\($0)" } ?? "default") contentSize=\(t.contentSize)")
    for s in 0..<rows.count {
        for r in 0..<rows[s] { print("  rect \(s).\(r) = \(t.rectForRow(at: IndexPath(row: r, section: s)))") }
    }
    let rects: [CGRect] = [
        CGRect(x: 0, y: 0, width: 320, height: 200),
        CGRect(x: 0, y: 44, width: 320, height: 44),
        CGRect(x: 0, y: 43.5, width: 320, height: 1),
        CGRect(x: 0, y: 88, width: 320, height: 0),
        CGRect(x: 0, y: 44, width: 0, height: 44),
        CGRect(x: 400, y: 0, width: 10, height: 10),
        CGRect(x: 0, y: 1000, width: 320, height: 100),
        CGRect(x: 0, y: -50, width: 320, height: 60),
        .zero,
        .null,
        .infinite,
        // discriminate the bottom edge near a row boundary (row 1 starts at 44)
        CGRect(x: 0, y: 43.5, width: 320, height: 1.5),
        CGRect(x: 0, y: 43.5, width: 320, height: 1.51),
        CGRect(x: 0, y: 43, width: 320, height: 2),
        CGRect(x: 0, y: 43, width: 320, height: 1.99),
        CGRect(x: 0, y: 10, width: 320, height: 34.99),
        CGRect(x: 0, y: 10, width: 320, height: 35),
        CGRect(x: 0, y: 10, width: 320, height: 35.01),
        CGRect(x: 0, y: 0, width: 320, height: 0.5),
        CGRect(x: 0, y: 43.99, width: 320, height: 0.02),
        CGRect(x: 0, y: 44, width: 0.5, height: 44),
        CGRect(x: 0, y: 44, width: 320, height: 44.5),
        CGRect(x: 0, y: 44, width: 320, height: 45),
        // x edges (bounds width 320)
        CGRect(x: 319, y: 0, width: 10, height: 10),
        CGRect(x: 320, y: 0, width: 10, height: 10),
        CGRect(x: -10, y: 0, width: 10, height: 10),
        CGRect(x: -10, y: 0, width: 10.5, height: 10),
        CGRect(x: 100, y: 0, width: 0, height: 0),
        CGRect(x: 500, y: 0, width: 0, height: 0),
    ]
    for rect in rects { print("  in \(rect) -> \(fmt(t.indexPathsForRows(in: rect)))") }
    _ = ds
}

run(.plain, [10], header: 0)
run(.plain, [2, 3], header: 28)
run(.plain, [0], header: 0)
run(.grouped, [2, 2], header: nil)
