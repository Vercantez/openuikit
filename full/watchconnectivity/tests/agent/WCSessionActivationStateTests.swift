import Foundation
import WatchConnectivity

func testWCSessionActivationStateRawValues() {
    precondition(WCSessionActivationState.notActivated.rawValue == 0)
    precondition(WCSessionActivationState.inactive.rawValue == 1)
    precondition(WCSessionActivationState.activated.rawValue == 2)
    precondition(WCSessionActivationState(rawValue: 0) == .notActivated)
    precondition(WCSessionActivationState(rawValue: 1) == .inactive)
    precondition(WCSessionActivationState(rawValue: 2) == .activated)
    precondition(WCSessionActivationState(rawValue: 3) == nil)
    precondition(WCSessionActivationState.notActivated != .activated)
    precondition(WCSessionActivationState.inactive != .notActivated)
    precondition(!(WCSessionActivationState.activated != .activated))

    _ = WCSessionActivationState.notActivated.hashValue
    precondition(
        WCSessionActivationState.inactive.hashValue ==
            WCSessionActivationState.inactive.hashValue
    )
    precondition(
        WCSessionActivationState.notActivated.hashValue !=
            WCSessionActivationState.activated.hashValue
    )
    var hasher = Hasher()
    WCSessionActivationState.inactive.hash(into: &hasher)
    _ = hasher.finalize()
}
