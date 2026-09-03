import Foundation
import Matter
import MatterSupport

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation or guest-Matter
// success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Matter and Foundation modules and dylibs.
// 2. Build MatterSupport with those modules on `-I` / `-L` (so `canImport(Matter)`
//    is true and the canonical MTR* signatures compile).
// 3. Link this file as a client that imports MatterSupport and Matter.
// 4. Pass actual Matter.MTRSetupPayload and commissioning security/band values
//    through MatterSupport public APIs.
// 5. Exercise handler subclass and existential override dispatch.
// 6. Verify perform fails closed.
// 7. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 8. Confirm `MATTERSUPPORT_DEPENDENCY_IDENTITY_OK` and that
//    `libMatterSupport.dylib` was loaded.
//
// This file is not compiled by the isolated host gate. It must not introduce
// MatterSupport-owned MTRSetupPayload / MTRNetworkCommissioningWiFi* lookalikes.

private let eventTimeout = DispatchTimeInterval.seconds(5)

private func assertNotMatterSupportType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("MatterSupport."))
}

private func requireUnavailable(_ body: () async throws -> Void) async {
    do {
        try await body()
        fatalError("expected fail-closed throw")
    } catch let error as NSError {
        assertNotMatterSupportType(error)
        precondition(error.domain == "MatterSupport.linux.unavailable")
        precondition(error.code == 1)
    } catch {
        fatalError("unexpected error type \(error)")
    }
}

private final class IdentityHandler: MatterAddDeviceExtensionRequestHandler {
    override func rooms(
        in home: MatterAddDeviceRequest.Home?
    ) async -> [MatterAddDeviceRequest.Room] {
        _ = home
        return [MatterAddDeviceRequest.Room(displayName: "IdentityRoom")]
    }
}

func matterSupportDependencyIdentityMain() async {
    let data = Data("matter-identity".utf8)
    let uuid = UUID()
    let home = MatterAddDeviceRequest.Home(displayName: "IdentityHome")
    assertNotMatterSupportType(data)
    assertNotMatterSupportType(uuid)
    precondition(type(of: data) == Data.self)
    precondition(type(of: uuid) == UUID.self)

    let payload = MTRSetupPayload()
    assertNotMatterSupportType(payload)
    precondition(type(of: payload) == MTRSetupPayload.self)

    let topology = MatterAddDeviceRequest.Topology(
        ecosystemName: "IdentityEco",
        homes: [home]
    )
    var request = MatterAddDeviceRequest(
        topology: topology,
        setupPayload: payload,
        showing: .commissioningID(uuid),
        shouldScanNetworks: false
    )
    precondition(request.setupPayload === payload)
    request.setupPayload = nil
    precondition(request.setupPayload == nil)
    await requireUnavailable { try await request.perform() }

    let wifi = MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
        ssid: data,
        rssi: -35,
        security: MTRNetworkCommissioningWiFiSecurity(),
        band: MTRNetworkCommissioningWiFiBand()
    )
    assertNotMatterSupportType(wifi.security)
    assertNotMatterSupportType(wifi.band)

    let asBase: MatterAddDeviceExtensionRequestHandler = IdentityHandler()
    let rooms = await asBase.rooms(in: home)
    precondition(rooms.map(\.displayName) == ["IdentityRoom"])
    await requireUnavailable {
        try await asBase.commissionDevice(
            in: home,
            onboardingPayload: "MT:IDENTITY",
            commissioningID: uuid
        )
    }

    print("MATTERSUPPORT_DEPENDENCY_IDENTITY_OK")
}

let identitySemaphore = DispatchSemaphore(value: 0)
Task {
    await matterSupportDependencyIdentityMain()
    identitySemaphore.signal()
}
precondition(
    identitySemaphore.wait(timeout: .now() + eventTimeout) == .success,
    "MatterSupport dependency-identity probe timed out"
)
