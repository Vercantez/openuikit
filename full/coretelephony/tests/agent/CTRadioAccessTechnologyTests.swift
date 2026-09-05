import CoreTelephony
import Foundation

func testRadioAccessTechnologyConstants() {
    let rows: [(String, String)] = [
        (CTRadioAccessTechnologyGPRS, "CTRadioAccessTechnologyGPRS"),
        (CTRadioAccessTechnologyEdge, "CTRadioAccessTechnologyEdge"),
        (CTRadioAccessTechnologyWCDMA, "CTRadioAccessTechnologyWCDMA"),
        (CTRadioAccessTechnologyHSDPA, "CTRadioAccessTechnologyHSDPA"),
        (CTRadioAccessTechnologyHSUPA, "CTRadioAccessTechnologyHSUPA"),
        (CTRadioAccessTechnologyCDMA1x, "CTRadioAccessTechnologyCDMA1x"),
        (CTRadioAccessTechnologyCDMAEVDORev0, "CTRadioAccessTechnologyCDMAEVDORev0"),
        (CTRadioAccessTechnologyCDMAEVDORevA, "CTRadioAccessTechnologyCDMAEVDORevA"),
        (CTRadioAccessTechnologyCDMAEVDORevB, "CTRadioAccessTechnologyCDMAEVDORevB"),
        (CTRadioAccessTechnologyeHRPD, "CTRadioAccessTechnologyeHRPD"),
        (CTRadioAccessTechnologyLTE, "CTRadioAccessTechnologyLTE"),
        (CTRadioAccessTechnologyNRNSA, "CTRadioAccessTechnologyNRNSA"),
        (CTRadioAccessTechnologyNR, "CTRadioAccessTechnologyNR"),
    ]
    let values = rows.map(\.0)
    precondition(Set(values).count == rows.count)
    for (value, expected) in rows {
        precondition(value == expected)
    }
}

func testRadioAccessTechnologyNotifications() {
    precondition(
        NSNotification.Name.CTRadioAccessTechnologyDidChange.rawValue
            == "CTRadioAccessTechnologyDidChangeNotification"
    )
    precondition(
        NSNotification.Name.CTServiceRadioAccessTechnologyDidChange.rawValue
            == "CTServiceRadioAccessTechnologyDidChangeNotification"
    )
    precondition(
        NSNotification.Name.CTRadioAccessTechnologyDidChange
            != NSNotification.Name.CTServiceRadioAccessTechnologyDidChange
    )
}
