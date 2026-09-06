import Foundation
import DockKit

func testBatteryStateProperties() {
    let state = DockAccessory.BatteryState(
        name: "main",
        batteryLevel: 0.42,
        chargeState: .charging,
        lowBattery: false
    )
    precondition(state.name == "main")
    precondition(state.batteryLevel == 0.42)
    precondition(state.chargeState == .charging)
    precondition(state.lowBattery == false)
}

func testBatteryStateEqualityAndHash() {
    let a = DockAccessory.BatteryState(
        name: "pack",
        batteryLevel: 0.1,
        chargeState: .notCharging,
        lowBattery: true
    )
    let b = DockAccessory.BatteryState(
        name: "pack",
        batteryLevel: 0.1,
        chargeState: .notCharging,
        lowBattery: true
    )
    let c = DockAccessory.BatteryState(
        name: "pack",
        batteryLevel: 0.2,
        chargeState: .notCharging,
        lowBattery: true
    )
    precondition(a == b)
    precondition(a != c)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}
