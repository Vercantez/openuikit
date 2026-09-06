import Foundation
import AVRouting

func testEventReasonRawValuesAndHashable() {
    let rows: [(AVCustomRoutingEventReason, Int)] = [
        (.activate, 0),
        (.deactivate, 1),
        (.reactivate, 2),
    ]
    for (value, raw) in rows {
        precondition(value.rawValue == raw)
        precondition(AVCustomRoutingEventReason(rawValue: raw) == value)
        precondition(value == AVCustomRoutingEventReason(rawValue: raw))
        precondition(!(value != AVCustomRoutingEventReason(rawValue: raw)!))
    }
    precondition(AVCustomRoutingEventReason(rawValue: 3) == nil)
    precondition(AVCustomRoutingEventReason(rawValue: -1) == nil)
    precondition(AVCustomRoutingEventReason.activate != .deactivate)
    precondition(AVCustomRoutingEventReason.deactivate != .reactivate)
    precondition(AVCustomRoutingEventReason.activate != .reactivate)

    var hasher = Hasher()
    AVCustomRoutingEventReason.activate.hash(into: &hasher)
    let hashed = hasher.finalize()
    precondition(AVCustomRoutingEventReason.activate.hashValue == AVCustomRoutingEventReason.activate.hashValue)
    precondition(hashed == hashed)
    precondition(
        Set([
            AVCustomRoutingEventReason.activate,
            .deactivate,
            .reactivate,
            .activate,
        ]).count == 3
    )
}
