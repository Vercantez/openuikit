import AVRouting
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest Foundation success.
// This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation.
// 2. Build AVRouting with that module on `-I` / `-L`.
// 3. Link this file as a client that imports AVRouting and Foundation.
// 4. Pass genuine Foundation.Data, UUID, and NSNotification.Name
//    values through public AVRouting APIs.
// 5. Confirm authorizedRoutes stays empty and networkEndpoint stays nil.
// 6. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 7. Confirm `AVROUTING_DEPENDENCY_IDENTITY_OK`.

private func assertNotAVRoutingType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("AVRouting."))
}

func assertFoundationIdentity() {
    let address = Data([192, 168, 10, 0])
    let mask = Data([255, 255, 255, 0])
    assertNotAVRoutingType(address)
    precondition(type(of: address) == Data.self)

    let partial = AVCustomRoutingPartialIP(address: address, mask: mask)
    precondition(partial.address == address)
    precondition(partial.mask == mask)

    let uuid = UUID()
    assertNotAVRoutingType(uuid)
    let route = AVCustomDeviceRoute(bluetoothIdentifier: uuid)
    precondition(route.bluetoothIdentifier == uuid)
    precondition(route.networkEndpoint == nil)

    let name: NSNotification.Name = AVCustomRoutingController.authorizedRoutesDidChange
    assertNotAVRoutingType(name)
    precondition(name.rawValue == "AVCustomRoutingControllerAuthorizedRoutesDidChangeNotification")

    _ = Foundation.URL.self
    _ = Foundation.NSError.self
}

func avroutingDependencyIdentityMain() {
    assertFoundationIdentity()
    print("AVROUTING_DEPENDENCY_IDENTITY_OK")
}
