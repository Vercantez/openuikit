import DeviceActivity
import Foundation

func testDeviceActivityAuthorizationFailClosed() {
    deviceActivityReset()
    deviceActivityRequire(!DeviceActivityAuthorization.isAuthorized, "not authorized")
    deviceActivityRequire(
        !DeviceActivityAuthorization.isAuthorized("com.example.app"),
        "bundle not authorized"
    )
    deviceActivityRequire(
        DeviceActivityAuthorization.authorizedClientIdentifiers.isEmpty,
        "no clients"
    )
    deviceActivityRequire(!DeviceActivityAuthorization.sharingEnabled, "sharing off")
    deviceActivityRequire(!DeviceActivityAuthorization.isOverridden, "default override")
    let instance = DeviceActivityAuthorization()
    deviceActivityRequire(
        String(describing: type(of: instance)).contains("DeviceActivityAuthorization"),
        "constructed authorization"
    )
}

func testDeviceActivityAuthorizationOverride() {
    deviceActivityReset()
    DeviceActivityAuthorization.isOverridden = true
    deviceActivityRequire(DeviceActivityAuthorization.isAuthorized, "override authorizes")
    deviceActivityRequire(
        DeviceActivityAuthorization.isAuthorized("com.example.app"),
        "bundle override"
    )
    DeviceActivityAuthorization.isOverridden = false
    deviceActivityRequire(!DeviceActivityAuthorization.isAuthorized, "override cleared")
}

func testDeviceActivityMonitorCallbacksAreInert() {
    let monitor = DeviceActivityMonitor()
    monitor.intervalDidStart(for: DeviceActivityName("a"))
    monitor.intervalDidEnd(for: DeviceActivityName("a"))
    monitor.intervalWillStartWarning(for: DeviceActivityName("a"))
    monitor.intervalWillEndWarning(for: DeviceActivityName("a"))
    monitor.eventDidReachThreshold(
        DeviceActivityEvent.Name("e"),
        activity: DeviceActivityName("a")
    )
    monitor.eventWillReachThresholdWarning(
        DeviceActivityEvent.Name("e"),
        activity: DeviceActivityName("a")
    )
    final class Probe: DeviceActivityMonitor {
        var started = 0
        override func intervalDidStart(for activity: DeviceActivityName) {
            started += 1
            super.intervalDidStart(for: activity)
        }
    }
    let probe = Probe()
    probe.intervalDidStart(for: DeviceActivityName("a"))
    deviceActivityRequire(probe.started == 1, "subclass override")
}
