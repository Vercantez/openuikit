// UITableView.performBatchUpdates(_:completion:) against the iOS 26.1
// simulator (Tools/oracle2/tablebatchprobe/transcript-ios26.1.txt, iPhone 16):
//
//   * the updates block runs synchronously inside the call, and the table
//     reports the new row count (and visible cells) when the call returns;
//   * the completion is never called synchronously;
//   * in a window with animations: completion(true) after the row animation;
//   * no window, animated: completion(false) on the next run-loop turn;
//   * performWithoutAnimation (window or not): completion(true) next turn.
//
// SimplenoteFoundation's unchanged UITableView+ResultsController.swift calls
// it (the iOS branch the iOS-target route now compiles).
import XCTest
import Foundation
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
private final class BatchSource: NSObject, UITableViewDataSource {
    var rows = 2
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel.text = "row \(indexPath.row)"
        return cell
    }
}

#if !os(Linux)
@MainActor
#endif
final class TableViewBatchUpdatesTests: XCTestCase {
    private var savedTime = 0.0

    override func setUp() {
        super.setUp()
        savedTime = OpenUIKitRuntime.animationTime
        OpenUIKitRuntime.animationTime = 0
    }

    override func tearDown() {
        UIView._stepAnimationCompletions(to: .greatestFiniteMagnitude)
        OpenUIKitRuntime.animationTime = savedTime
        super.tearDown()
    }

    private func make(inWindow: Bool) -> (UIWindow?, UITableView, BatchSource) {
        let source = BatchSource()
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), style: .plain)
        table.dataSource = source
        var window: UIWindow?
        if inWindow {
            let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
            w.addSubview(table)
            window = w
        }
        table.reloadData()
        table.layoutIfNeeded()
        XCTAssertEqual(table.numberOfRows(inSection: 0), 2)
        return (window, table, source)
    }

    /// Runs the probe's update; returns the completion log.
    private func batch(_ table: UITableView, _ source: BatchSource,
                       log: @escaping (String) -> Void) {
        table.performBatchUpdates({
            log("updates")
            source.rows = 3
            table.insertRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
        }, completion: { finished in
            log("completion finished=\(finished) rows=\(table.numberOfRows(inSection: 0))")
        })
        log("returned rows=\(table.numberOfRows(inSection: 0)) visible=\(table.visibleCells.count)")
    }

    func testWindowAnimatedCompletesTrueAfterTheRowAnimation() {
        let (window, table, source) = make(inWindow: true)
        var events: [String] = []
        batch(table, source) { events.append($0) }
        XCTAssertEqual(events, ["updates", "returned rows=3 visible=3"])
        OpenUIKitRuntime.animationTime = UITableView.iOSRowAnimationDuration - 0.05
        window!.tick(timestamp: OpenUIKitRuntime.animationTime)
        XCTAssertEqual(events.count, 2, "completion waits for the row animation")
        OpenUIKitRuntime.animationTime = UITableView.iOSRowAnimationDuration + 0.01
        window!.tick(timestamp: OpenUIKitRuntime.animationTime)
        XCTAssertEqual(events.last, "completion finished=true rows=3")
    }

    func testNoWindowAnimatedCompletesFalseOnTheNextTurn() {
        let (_, table, source) = make(inWindow: false)
        var events: [String] = []
        batch(table, source) { events.append($0) }
        XCTAssertEqual(events, ["updates", "returned rows=3 visible=3"])
        UIView._stepAnimationCompletions(to: OpenUIKitRuntime.animationTime)
        XCTAssertEqual(events.last, "completion finished=false rows=3")
    }

    func testWithoutAnimationCompletesTrueOnTheNextTurn() {
        for inWindow in [true, false] {
            let (_, table, source) = make(inWindow: inWindow)
            var events: [String] = []
            UIView.performWithoutAnimation { batch(table, source) { events.append($0) } }
            XCTAssertEqual(events, ["updates", "returned rows=3 visible=3"], "inWindow=\(inWindow)")
            UIView._stepAnimationCompletions(to: OpenUIKitRuntime.animationTime)
            XCTAssertEqual(events.last, "completion finished=true rows=3", "inWindow=\(inWindow)")
        }
    }

    func testNilBlocksAreAllowed() {
        let (_, table, _) = make(inWindow: false)
        table.performBatchUpdates(nil, completion: nil)
        XCTAssertEqual(table.numberOfRows(inSection: 0), 2)
    }
}
