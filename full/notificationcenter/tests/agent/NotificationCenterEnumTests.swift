import Foundation
import NotificationCenter

func testNCUpdateResultRawValues() {
    precondition(NCUpdateResult.newData.rawValue == 0)
    precondition(NCUpdateResult.noData.rawValue == 1)
    precondition(NCUpdateResult.failed.rawValue == 2)
    precondition(NCUpdateResult(rawValue: 0) == .newData)
    precondition(NCUpdateResult(rawValue: 1) == .noData)
    precondition(NCUpdateResult(rawValue: 2) == .failed)
    precondition(NCUpdateResult(rawValue: 3) == nil)
    precondition(NCUpdateResult.newData != .noData)
    precondition(NCUpdateResult.noData != .failed)
    precondition(NCUpdateResult.newData != .failed)
    precondition(NCUpdateResult.noData == NCUpdateResult(rawValue: 1))
    precondition(
        NCUpdateResult.newData.hashValue == NCUpdateResult.newData.hashValue
    )
    precondition(
        NCUpdateResult.failed.hashValue == NCUpdateResult.failed.hashValue
    )
    var first = Hasher()
    NCUpdateResult.newData.hash(into: &first)
    var second = Hasher()
    NCUpdateResult.newData.hash(into: &second)
    precondition(first.finalize() == second.finalize())
    var third = Hasher()
    NCUpdateResult.failed.hash(into: &third)
    _ = third.finalize()
    let asSet: Set<NCUpdateResult> = [.newData, .noData, .failed]
    precondition(asSet.count == 3)
}

func testNCWidgetDisplayModeRawValues() {
    precondition(NCWidgetDisplayMode.compact.rawValue == 0)
    precondition(NCWidgetDisplayMode.expanded.rawValue == 1)
    precondition(NCWidgetDisplayMode(rawValue: 0) == .compact)
    precondition(NCWidgetDisplayMode(rawValue: 1) == .expanded)
    precondition(NCWidgetDisplayMode(rawValue: -1) == nil)
    precondition(NCWidgetDisplayMode(rawValue: 2) == nil)
    precondition(NCWidgetDisplayMode.compact != .expanded)
    precondition(NCWidgetDisplayMode.expanded != .compact)
    precondition(
        NCWidgetDisplayMode.compact.hashValue
            == NCWidgetDisplayMode.compact.hashValue
    )
    precondition(
        NCWidgetDisplayMode.expanded.hashValue
            == NCWidgetDisplayMode.expanded.hashValue
    )
    var first = Hasher()
    NCWidgetDisplayMode.compact.hash(into: &first)
    var second = Hasher()
    NCWidgetDisplayMode.compact.hash(into: &second)
    precondition(first.finalize() == second.finalize())
    var third = Hasher()
    NCWidgetDisplayMode.expanded.hash(into: &third)
    _ = third.finalize()
    let asSet: Set<NCWidgetDisplayMode> = [.compact, .expanded]
    precondition(asSet.count == 2)
}
