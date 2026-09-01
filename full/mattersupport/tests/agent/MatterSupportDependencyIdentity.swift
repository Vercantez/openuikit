// Future clean EC2 dependency-identity probe. The isolated host gate does not
// compile this file: it has no Matter module, and a passing host gate is not
// integrated Linux success.
//
// EC2 procedure (no local Docker):
// 1. Build guest Matter and Foundation modules and dylibs.
// 2. Build MatterSupport with those -I and -L paths (canImport(Matter) true).
// 3. Link this client against MatterSupport and its dependencies.
// 4. Run with LD_LIBRARY_PATH covering those dylibs.
// 5. Assert MATTERSUPPORT_DEPENDENCY_IDENTITY_OK and that libMatterSupport.dylib
//    was loaded (e.g. /proc/self/maps).

import Foundation
import Matter
import MatterSupport

private func requireThrown(_ body: () async throws -> Void) async {
    do {
        try await body()
        fatalError("expected fail-closed throw")
    } catch {
        _ = error
    }
}

private final class IdentityHandler: MatterAddDeviceExtensionRequestHandler {
    var configuredName: String?

    override func rooms(in home: MatterAddDeviceRequest.Home?) async -> [MatterAddDeviceRequest.Room] {
        _ = home
        return [MatterAddDeviceRequest.Room(displayName: "Lab")]
    }

    override func configureDevice(named name: String, in room: MatterAddDeviceRequest.Room?) async {
        _ = room
        configuredName = name
    }
}

private protocol HandlerExistential {
    func rooms(in home: MatterAddDeviceRequest.Home?) async -> [MatterAddDeviceRequest.Room]
    func configureDevice(named name: String, in room: MatterAddDeviceRequest.Room?) async
}

extension MatterAddDeviceExtensionRequestHandler: HandlerExistential {}

func runMatterSupportDependencyIdentity() async {
    let topology = MatterAddDeviceRequest.Topology(
        ecosystemName: "OpenUIKit",
        homes: [MatterAddDeviceRequest.Home(displayName: "Apartment")]
    )

    let payload = Matter.MTRSetupPayload()
    var request = MatterAddDeviceRequest(
        topology: topology,
        setupPayload: payload,
        showing: .allDevices,
        shouldScanNetworks: true
    )
    precondition(request.setupPayload === payload)
    request.setupPayload = payload
    precondition(request.setupPayload === payload)

    let security = Matter.MTRNetworkCommissioningWiFiSecurity(rawValue: 1 << 3)
    let band = Matter.MTRNetworkCommissioningWiFiBand(rawValue: 1 << 2)
    let wifi = MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
        ssid: Data("openuikit".utf8),
        rssi: -40,
        security: security,
        band: band
    )
    precondition(wifi.security.rawValue == security.rawValue)
    precondition(wifi.band.rawValue == band.rawValue)
    precondition(wifi.ssid == Data("openuikit".utf8))
    precondition(wifi.rssi == -40)

    await requireThrown {
        try await request.perform()
    }

    let subclass = IdentityHandler()
    let asBase: MatterAddDeviceExtensionRequestHandler = subclass
    let rooms = await asBase.rooms(in: topology.homes.first)
    precondition(rooms == [MatterAddDeviceRequest.Room(displayName: "Lab")])
    await asBase.configureDevice(named: "Lamp", in: nil)
    precondition(subclass.configuredName == "Lamp")

    let existential: any HandlerExistential = subclass
    let existentialRooms = await existential.rooms(in: nil)
    precondition(existentialRooms == [MatterAddDeviceRequest.Room(displayName: "Lab")])
    await existential.configureDevice(named: "Existential", in: nil)
    precondition(subclass.configuredName == "Existential")

    print("MATTERSUPPORT_DEPENDENCY_IDENTITY_OK")
}

await runMatterSupportDependencyIdentity()
