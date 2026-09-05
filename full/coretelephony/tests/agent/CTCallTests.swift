import CoreTelephony
import Foundation

func testCallStateConstants() {
    let rows: [(String, String)] = [
        (CTCallStateDialing, "dialing"),
        (CTCallStateIncoming, "incoming"),
        (CTCallStateConnected, "connected"),
        (CTCallStateDisconnected, "disconnected"),
    ]
    let values = rows.map(\.0)
    precondition(Set(values).count == rows.count)
    for (value, expected) in rows {
        precondition(value == expected)
        precondition(!value.isEmpty)
    }
}

func testCTCallSnapshot() {
    let call = CTCall()
    precondition(call.callID.isEmpty)
    precondition(call.callState.isEmpty)
    precondition(call.callState != CTCallStateConnected)
}

func testCTCallCenterFailClosed() {
    let center = CTCallCenter()
    precondition(center.currentCalls == nil)
    var fired = false
    center.callEventHandler = { _ in fired = true }
    precondition(center.callEventHandler != nil)
    precondition(!fired)
    center.callEventHandler = nil
    precondition(center.callEventHandler == nil)
}
