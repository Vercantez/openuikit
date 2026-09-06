import DeviceDiscoveryUI
import Foundation
import UIKit
@_spi(OpenUIKitHost) import DeviceDiscoveryUI

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest UIKit success. This
// file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation and UIKit (and their dylibs).
// 2. Build DeviceDiscoveryUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports DeviceDiscoveryUI and every
//    declared dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `DEVICEDISCOVERYUI_DEPENDENCY_IDENTITY_OK` and that
//    `libDeviceDiscoveryUI.dylib` was loaded.

private struct HostListener: ListenerProvider {}

private func assertNotDeviceDiscoveryUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("DeviceDiscoveryUI."))
}

func assertFoundationIdentity() {
    let access = DDDevicePairingAccess.default
    assertNotDeviceDiscoveryUIType(Data())
    assertNotDeviceDiscoveryUIType(Date())
    precondition(access == .default)
    _ = Foundation.UUID()
}

func assertUIKitIdentity() {
    let controller = DDDevicePairingViewController(
        listenerProvider: HostListener(),
        access: .permanent
    )
    precondition(controller is UIViewController)
    controller.viewDidLoad()
    precondition(DeviceDiscoveryUIHostControl.viewDidLoadCount(of: controller) == 1)
    precondition(DeviceDiscoveryUIHostControl.advertisingAttempted(of: controller) == false)
}

func deviceDiscoveryUIDependencyIdentityMain() {
    assertFoundationIdentity()
    assertUIKitIdentity()
    print("DEVICEDISCOVERYUI_DEPENDENCY_IDENTITY_OK")
}
