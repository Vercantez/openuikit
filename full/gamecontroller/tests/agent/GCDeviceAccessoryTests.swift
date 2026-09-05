import Foundation
import Dispatch
import GameController

func testBatteryLightHapticsTypes() {
    let color = GCColor(red: 0.1, green: 0.2, blue: 0.3)
    let battery = GCDeviceBattery(level: 0, state: .unknown)
    precondition(battery.batteryLevel == 0)
    precondition(battery.batteryState == .unknown)
    let light = GCDeviceLight(color: color)
    precondition(light.color.red == color.red)
    let haptics = GCDeviceHaptics()
    precondition(haptics.supportedLocalities.isEmpty)
    let activation = GCGameControllerActivationContext()
    precondition(activation.previousApplicationBundleID == nil)
    _ = GCDeviceBattery.self
    _ = GCDeviceLight.self
    _ = GCDeviceHaptics.self
    _ = GCGameControllerActivationContext.self
}
