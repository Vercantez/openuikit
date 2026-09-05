@_spi(OpenUIKitHost) import TipKit
import Foundation

func testTipsStatusCases() {
    let pending = Tips.Status.pending
    let available = Tips.Status.available
    let closed = Tips.Status.invalidated(.tipClosed)
    precondition(pending == .pending)
    precondition(pending != available)
    precondition(available != closed)
    precondition(closed == .invalidated(.tipClosed))
    var hasher = Hasher()
    pending.hash(into: &hasher)
    _ = pending.hashValue
    _ = available.hashValue
}

func testInvalidationReasonCases() {
    let cases: [Tips.InvalidationReason] = [
        .actionPerformed,
        .displayCountExceeded,
        .displayDurationExceeded,
        .tipClosed,
    ]
    precondition(Set(cases).count == 4)
    precondition(Tips.InvalidationReason.actionPerformed != .displayCountExceeded)
    precondition(Tips.InvalidationReason.displayDurationExceeded != .tipClosed)
    var hasher = Hasher()
    Tips.InvalidationReason.actionPerformed.hash(into: &hasher)
    _ = Tips.InvalidationReason.tipClosed.hashValue
}
