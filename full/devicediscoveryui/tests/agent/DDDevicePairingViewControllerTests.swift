import Foundation
@_spi(OpenUIKitHost) import DeviceDiscoveryUI

private struct HostListenerA: ListenerProvider {}
private struct HostListenerB: ListenerProvider {}

func testPairingViewControllerType() {
    precondition(
        String(describing: DDDevicePairingViewController.self)
            == "DDDevicePairingViewController"
    )
    let controller = DDDevicePairingViewController(
        listenerProvider: HostListenerA(),
        access: .default
    )
    precondition(type(of: controller) == DDDevicePairingViewController.self)
}

func testPairingViewControllerIsSupported() {
    precondition(DDDevicePairingViewController.isSupported(HostListenerA()) == false)
    precondition(DDDevicePairingViewController.isSupported(HostListenerB()) == false)
}

func testPairingViewControllerInit() {
    let defaulted = DDDevicePairingViewController(
        listenerProvider: HostListenerA(),
        access: .default
    )
    precondition(DeviceDiscoveryUIHostControl.pairingAccess(of: defaulted) == .default)
    precondition(DeviceDiscoveryUIHostControl.viewDidLoadCount(of: defaulted) == 0)
    precondition(DeviceDiscoveryUIHostControl.advertisingAttempted(of: defaulted) == false)

    let permanent = DDDevicePairingViewController(
        listenerProvider: HostListenerB(),
        access: .permanent
    )
    precondition(DeviceDiscoveryUIHostControl.pairingAccess(of: permanent) == .permanent)
    precondition(DeviceDiscoveryUIHostControl.advertisingAttempted(of: permanent) == false)
}

func testPairingViewControllerViewDidLoad() {
    let controller = DDDevicePairingViewController(
        listenerProvider: HostListenerA(),
        access: .permanent
    )
    precondition(DeviceDiscoveryUIHostControl.viewDidLoadCount(of: controller) == 0)
    controller.viewDidLoad()
    precondition(DeviceDiscoveryUIHostControl.viewDidLoadCount(of: controller) == 1)
    precondition(DeviceDiscoveryUIHostControl.advertisingAttempted(of: controller) == false)
    controller.viewDidLoad()
    precondition(DeviceDiscoveryUIHostControl.viewDidLoadCount(of: controller) == 2)
    precondition(DeviceDiscoveryUIHostControl.advertisingAttempted(of: controller) == false)
}
