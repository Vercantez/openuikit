import CoreTelephony
import Dispatch
import Foundation

private func ctWaitOnce(_ semaphore: DispatchSemaphore, seconds: Double = 2) {
    precondition(semaphore.wait(timeout: .now() + seconds) == .success)
}

private func ctWaitQuiet(_ semaphore: DispatchSemaphore, seconds: Double = 0.25) {
    precondition(semaphore.wait(timeout: .now() + seconds) == .timedOut)
}

func testRestrictedStateEnum() {
    precondition(CTCellularDataRestrictedState(rawValue: 0) == .restrictedStateUnknown)
    precondition(CTCellularDataRestrictedState(rawValue: 1) == .restricted)
    precondition(CTCellularDataRestrictedState(rawValue: 2) == .notRestricted)
    precondition(CTCellularDataRestrictedState(rawValue: 99) == nil)
    precondition(CTCellularDataRestrictedState.restricted != .notRestricted)
    precondition(
        CTCellularDataRestrictedState.restricted.hashValue
            != CTCellularDataRestrictedState.notRestricted.hashValue
    )
    var hasher = Hasher()
    CTCellularDataRestrictedState.notRestricted.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCellularDataRestrictedState() {
    let data = CTCellularData()
    precondition(data.restrictedState == .restrictedStateUnknown)
}

func testCellularDataRestrictionNotifier() {
    let data = CTCellularData()
    let first = DispatchSemaphore(value: 0)
    var hits = 0
    var seen: CTCellularDataRestrictedState?
    var inline = false
    let handler: CellularDataRestrictionDidUpdateNotifier = { state in
        hits += 1
        seen = state
        inline = true
        first.signal()
    }
    data.cellularDataRestrictionDidUpdateNotifier = handler
    precondition(!inline)
    ctWaitOnce(first)
    precondition(hits == 1)
    precondition(seen == .restrictedStateUnknown)
    ctWaitQuiet(first)

    var secondHits = 0
    data.cellularDataRestrictionDidUpdateNotifier = { _ in
        secondHits += 1
    }
    ctWaitQuiet(DispatchSemaphore(value: 0), seconds: 0.25)
    precondition(secondHits == 0)
    precondition(hits == 1)

    data.cellularDataRestrictionDidUpdateNotifier = nil
    let again = DispatchSemaphore(value: 0)
    var thirdHits = 0
    data.cellularDataRestrictionDidUpdateNotifier = { _ in
        thirdHits += 1
        again.signal()
    }
    ctWaitOnce(again)
    precondition(thirdHits == 1)
}
