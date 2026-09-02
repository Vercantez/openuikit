import Darwin
import Foundation
import UIKit

private let bundleIdentifier = "com.openuikit.presentationtableprobe.successor"

@MainActor
private final class ProbeTableDataSource: NSObject, UITableViewDataSource {
    var items: [String]

    init(_ items: [String]) {
        self.items = items
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "probe-cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
            ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}

@MainActor
private final class Transcript {
    private var lines: [String] = []
    private var failures: [String] = []

    func fact(_ key: String, _ value: String) {
        lines.append("\(key)=\(value)")
    }

    func check(_ key: String, _ condition: @autoclosure () -> Bool) {
        let passed = condition()
        lines.append("\(key)=\(passed ? "true" : "false")")
        if !passed { failures.append(key) }
    }

    func finish() -> Int32 {
        var final = ["ORACLE_BEGIN"]
        final.append(contentsOf: lines)
        final.append("oracle.status=\(failures.isEmpty ? "PASS" : "FAIL")")
        if !failures.isEmpty {
            final.append("oracle.failures=\(failures.joined(separator: ","))")
        }
        final.append("ORACLE_END")
        let output = final.joined(separator: "\n") + "\n"
        let documents = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask)[0]
        try! output.write(
            to: documents.appendingPathComponent("presentationtableprobe.txt"),
            atomically: true,
            encoding: .utf8
        )
        FileHandle.standardOutput.write(Data(output.utf8))
        fflush(stdout)
        return failures.isEmpty ? 0 : 1
    }
}

@MainActor
private func requireCells(_ table: UITableView, count: Int) -> [UITableViewCell] {
    table.layoutIfNeeded()
    return (0..<count).map { row in
        guard let cell = table.cellForRow(at: IndexPath(row: row, section: 0)) else {
            fatalError("expected visible cell at row \(row)")
        }
        return cell
    }
}

@MainActor
private func makeTable(dataSource: ProbeTableDataSource, in root: UIView) -> UITableView {
    let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 240),
                            style: .plain)
    table.dataSource = dataSource
    table.rowHeight = 44
    table.estimatedRowHeight = 0
    table.contentInsetAdjustmentBehavior = .never
    root.addSubview(table)
    table.reloadData()
    table.layoutIfNeeded()
    return table
}

@MainActor
private func recordModalAndPopoverFacts(_ transcript: Transcript) {
    transcript.fact("modal.raw.coverVertical", "\(UIModalTransitionStyle.coverVertical.rawValue)")
    transcript.fact("modal.raw.flipHorizontal", "\(UIModalTransitionStyle.flipHorizontal.rawValue)")
    transcript.fact("modal.raw.crossDissolve", "\(UIModalTransitionStyle.crossDissolve.rawValue)")
    transcript.fact("modal.raw.partialCurl", "\(UIModalTransitionStyle.partialCurl.rawValue)")

    let controller = UIViewController()
    transcript.fact("modal.default", "\(controller.modalTransitionStyle.rawValue)")
    controller.modalTransitionStyle = .crossDissolve
    transcript.fact("modal.roundtrip.crossDissolve", "\(controller.modalTransitionStyle.rawValue)")
    controller.modalTransitionStyle = .partialCurl
    transcript.fact("modal.roundtrip.partialCurl", "\(controller.modalTransitionStyle.rawValue)")
    controller.modalTransitionStyle = .coverVertical
    transcript.fact("modal.roundtrip.coverVertical", "\(controller.modalTransitionStyle.rawValue)")

    let presented = UIViewController()
    presented.modalPresentationStyle = .popover
    guard let popover = presented.popoverPresentationController else {
        transcript.check("popover.controller.nonNil", false)
        return
    }
    transcript.check("popover.controller.nonNil", true)
    transcript.check("popover.background.defaultNil", popover.backgroundColor == nil)

    let exact = UIColor(red: 0.125, green: 0.25, blue: 0.5, alpha: 0.75)
    popover.backgroundColor = exact
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    let converted = popover.backgroundColor?.getRed(
        &red, green: &green, blue: &blue, alpha: &alpha
    ) ?? false
    transcript.check("popover.background.convertedRGB", converted)
    transcript.fact(
        "popover.background.rgba",
        String(format: "%.6f,%.6f,%.6f,%.6f", red, green, blue, alpha)
    )
    popover.backgroundColor = nil
    transcript.check("popover.background.resetNil", popover.backgroundColor == nil)
}

@MainActor
private func recordDirectMoveFacts(_ transcript: Transcript, root: UIView) {
    let source = ProbeTableDataSource(["A", "B", "C", "D"])
    let table = makeTable(dataSource: source, in: root)
    let before = requireCells(table, count: 4)
    let beforeFrames = before.map(\.frame)
    table.selectRow(at: IndexPath(row: 0, section: 0),
                    animated: false, scrollPosition: .none)

    source.items = ["B", "C", "A", "D"]
    table.moveRow(at: IndexPath(row: 0, section: 0),
                  to: IndexPath(row: 2, section: 0))
    table.layoutIfNeeded()

    let after = requireCells(table, count: 4)
    transcript.check("table.direct.identity.A.0to2", after[2] === before[0])
    transcript.check("table.direct.identity.B.1to0", after[0] === before[1])
    transcript.check("table.direct.identity.C.2to1", after[1] === before[2])
    transcript.check("table.direct.identity.D.3to3", after[3] === before[3])
    transcript.check("table.direct.frame.A.slot0to2", after[2].frame == beforeFrames[2])
    transcript.check("table.direct.frame.B.slot1to0", after[0].frame == beforeFrames[0])
    transcript.check("table.direct.frame.C.slot2to1", after[1].frame == beforeFrames[1])
    transcript.check("table.direct.frame.D.slot3to3", after[3].frame == beforeFrames[3])
    transcript.fact(
        "table.direct.visibleOrder",
        after.map { $0.textLabel?.text ?? "nil" }.joined(separator: ",")
    )
    transcript.fact(
        "table.direct.selection",
        table.indexPathForSelectedRow.map { "\($0.section):\($0.row)" } ?? "nil"
    )
    table.removeFromSuperview()
}

@MainActor
private func recordBatchMoveFacts(_ transcript: Transcript, root: UIView) {
    let source = ProbeTableDataSource(["A", "B", "C", "D"])
    let table = makeTable(dataSource: source, in: root)
    let before = requireCells(table, count: 4)
    let beforeFrames = before.map(\.frame)
    table.selectRow(at: IndexPath(row: 2, section: 0),
                    animated: false, scrollPosition: .none)

    table.beginUpdates()
    source.items = ["A", "D", "B", "C"]
    table.moveRow(at: IndexPath(row: 3, section: 0),
                  to: IndexPath(row: 1, section: 0))
    table.endUpdates()
    table.layoutIfNeeded()

    let after = requireCells(table, count: 4)
    transcript.check("table.batch.identity.A.0to0", after[0] === before[0])
    transcript.check("table.batch.identity.D.3to1", after[1] === before[3])
    transcript.check("table.batch.identity.B.1to2", after[2] === before[1])
    transcript.check("table.batch.identity.C.2to3", after[3] === before[2])
    transcript.check("table.batch.frame.A.slot0to0", after[0].frame == beforeFrames[0])
    transcript.check("table.batch.frame.D.slot3to1", after[1].frame == beforeFrames[1])
    transcript.check("table.batch.frame.B.slot1to2", after[2].frame == beforeFrames[2])
    transcript.check("table.batch.frame.C.slot2to3", after[3].frame == beforeFrames[3])
    transcript.fact(
        "table.batch.visibleOrder",
        after.map { $0.textLabel?.text ?? "nil" }.joined(separator: ",")
    )
    transcript.fact(
        "table.batch.selection",
        table.indexPathForSelectedRow.map { "\($0.section):\($0.row)" } ?? "nil"
    )
    table.removeFromSuperview()
}

@main
@MainActor
final class ProbeAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        _ = application
        _ = launchOptions
        precondition(Bundle.main.bundleIdentifier == bundleIdentifier)
        let transcript = Transcript()
        recordModalAndPopoverFacts(transcript)

        let root = UIViewController()
        root.view.backgroundColor = .white
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = root
        self.window = window
        window.makeKeyAndVisible()
        root.view.layoutIfNeeded()

        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        recordDirectMoveFacts(transcript, root: root.view)
        recordBatchMoveFacts(transcript, root: root.view)
        UIView.setAnimationsEnabled(animationsWereEnabled)

        transcript.fact(
            "table.invalidBehavior",
            "NOT_MEASURED_UNCATCHABLE_NSException_RISK"
        )
        let status = transcript.finish()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            Darwin.exit(status)
        }
        return true
    }
}
