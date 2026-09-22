// tablebatchprobe — UITableView.performBatchUpdates(_:completion:) ordering.
//
// The Apple side of OpenUIKitTests' TableViewBatchUpdatesTests. Records, for
// a table in and out of a window: when the updates block runs relative to
// the call, whether the rows are updated when the call returns, when the
// completion runs (synchronously or on a later run-loop turn) and its
// `finished` argument. run.sh builds this for the iOS 26.1 simulator against
// Apple's UIKit and writes transcript-ios26.1.txt.
import UIKit

final class Source: NSObject, UITableViewDataSource {
    var rows = 2
    func tableView(_ t: UITableView, numberOfRowsInSection s: Int) -> Int { rows }
    func tableView(_ t: UITableView, cellForRowAt i: IndexPath) -> UITableViewCell {
        let c = UITableViewCell(style: .default, reuseIdentifier: nil)
        c.textLabel?.text = "row \(i.row)"
        return c
    }
}

var lines: [String] = []
func log(_ s: String) { lines.append(s) }

@MainActor func scenario(_ name: String, inWindow: Bool, animated: Bool) {
    log("-- \(name)")
    let source = Source()
    let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), style: .plain)
    table.dataSource = source
    var window: UIWindow?
    if inWindow {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        w.addSubview(table)
        w.isHidden = false
        window = w
    }
    table.reloadData()
    table.layoutIfNeeded()
    log("before rows=\(table.numberOfRows(inSection: 0)) visible=\(table.visibleCells.count)")
    var turn = 0
    let body = {
        table.performBatchUpdates({
            log("updates block (turn \(turn))")
            source.rows = 3
            table.insertRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
        }, completion: { finished in
            log("completion finished=\(finished) (turn \(turn)) rows=\(table.numberOfRows(inSection: 0))")
        })
    }
    if animated { body() } else { UIView.performWithoutAnimation(body) }
    log("returned rows=\(table.numberOfRows(inSection: 0)) visible=\(table.visibleCells.count)")
    for t in 1...40 {
        turn = t
        RunLoop.main.run(until: Date().addingTimeInterval(0.025))
    }
    log("end rows=\(table.numberOfRows(inSection: 0)) visible=\(table.visibleCells.count)")
    _ = window
}

MainActor.assumeIsolated {
    scenario("no window, animated", inWindow: false, animated: true)
    scenario("window, animated", inWindow: true, animated: true)
    scenario("window, performWithoutAnimation", inWindow: true, animated: false)
    scenario("no window, performWithoutAnimation", inWindow: false, animated: false)
}
print("# tablebatchprobe — iOS \(UIDevice.current.systemVersion)")
for l in lines { print(l) }
