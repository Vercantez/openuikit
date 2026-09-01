import Foundation
import MatterSupport

private func requireThrown(_ body: () async throws -> Void) async {
    do {
        try await body()
        fatalError("expected fail-closed throw")
    } catch {
        _ = error
    }
}

private func assertHashable<T: Hashable>(_ a: T, equals b: T) {
    precondition(a == b)
    precondition(!(a != b))
    precondition(a.hashValue == b.hashValue)
}

private final class ProbeHandler: MatterAddDeviceExtensionRequestHandler {
    override func rooms(in home: MatterAddDeviceRequest.Home?) async -> [MatterAddDeviceRequest.Room] {
        _ = home
        return [MatterAddDeviceRequest.Room(displayName: "Kitchen")]
    }

    override func configureDevice(named name: String, in room: MatterAddDeviceRequest.Room?) async {
        _ = (name, room)
    }
}

func runMatterSupportRuntime() async {
    precondition(MatterAddDeviceRequest.isSupported == false)

    let home = MatterAddDeviceRequest.Home(displayName: "Apartment")
    let otherHome = MatterAddDeviceRequest.Home(displayName: "Cottage")
    precondition(home.displayName == "Apartment")
    assertHashable(home, equals: MatterAddDeviceRequest.Home(displayName: "Apartment"))
    precondition(home != otherHome)

    let room = MatterAddDeviceRequest.Room(displayName: "Office")
    precondition(room.displayName == "Office")
    assertHashable(room, equals: MatterAddDeviceRequest.Room(displayName: "Office"))
    precondition(room != MatterAddDeviceRequest.Room(displayName: "Lab"))

    let topology = MatterAddDeviceRequest.Topology(
        ecosystemName: "OpenUIKit",
        homes: [home, otherHome]
    )
    precondition(topology.ecosystemName == "OpenUIKit")
    precondition(topology.homes.count == 2)
    assertHashable(
        topology,
        equals: MatterAddDeviceRequest.Topology(
            ecosystemName: "OpenUIKit",
            homes: [home, otherHome]
        )
    )
    precondition(topology != MatterAddDeviceRequest.Topology(ecosystemName: "Other", homes: []))

    let commissioningID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    let criteriaCases: [MatterAddDeviceRequest.DeviceCriteria] = [
        .allDevices,
        .vendorID(0xFFF1),
        .productID(0x1234),
        .serialNumber("SN-1"),
        .commissioningID(commissioningID),
        .fabricNode(rootPublicKey: Data([0x01, 0x02]), nodeID: 9),
        .not(.vendorID(1)),
        .any([.vendorID(1), .productID(2)]),
        .all([.vendorID(1), .serialNumber("X")]),
    ]
    for criteria in criteriaCases {
        assertHashable(criteria, equals: criteria)
    }
    precondition(
        MatterAddDeviceRequest.DeviceCriteria.allDevices
            != MatterAddDeviceRequest.DeviceCriteria.vendorID(1)
    )

    let request = MatterAddDeviceRequest(
        topology: topology,
        showing: .allDevices
    )
    precondition(request.topology == topology)
    precondition(request.showDeviceCriteria == .allDevices)
    precondition(request.shouldScanNetworks == true)

    let scanned = MatterAddDeviceRequest(
        topology: topology,
        showing: .not(.serialNumber("paired")),
        shouldScanNetworks: false
    )
    precondition(scanned.shouldScanNetworks == false)
    precondition(scanned.showDeviceCriteria == .not(.serialNumber("paired")))
    precondition(request != scanned)
    assertHashable(request, equals: MatterAddDeviceRequest(topology: topology, showing: .allDevices))

    await requireThrown {
        try await request.perform()
    }

    let credential = MatterAddDeviceExtensionRequestHandler.DeviceCredential(
        certificationDeclaration: Data([0xCD]),
        deviceAttestationCertificate: Data([0xDA]),
        productAttestationIntermediateCertificate: Data([0x50])
    )
    precondition(credential.certificationDeclaration == Data([0xCD]))
    precondition(credential.deviceAttestationCertificate == Data([0xDA]))
    precondition(credential.productAttestationIntermediateCertificate == Data([0x50]))
    assertHashable(
        credential,
        equals: MatterAddDeviceExtensionRequestHandler.DeviceCredential(
            certificationDeclaration: Data([0xCD]),
            deviceAttestationCertificate: Data([0xDA]),
            productAttestationIntermediateCertificate: Data([0x50])
        )
    )

    let wifi = MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
        ssid: Data("openuikit".utf8),
        rssi: -40
    )
    precondition(wifi.ssid == Data("openuikit".utf8))
    precondition(wifi.rssi == -40)
    assertHashable(wifi, equals: wifi)

    let thread = MatterAddDeviceExtensionRequestHandler.ThreadScanResult(
        networkName: "ThreadNet",
        panID: 0x1234,
        extendedPANID: 0xAABBCCDDEEFF0011,
        channel: 15,
        extendedAddress: Data([0x0A, 0x0B]),
        rssi: -70,
        version: 4,
        linkQualityIndicator: 3
    )
    precondition(thread.networkName == "ThreadNet")
    precondition(thread.panID == 0x1234)
    precondition(thread.extendedPANID == 0xAABBCCDDEEFF0011)
    precondition(thread.channel == 15)
    precondition(thread.version == 4)
    precondition(thread.linkQualityIndicator == 3)
    assertHashable(thread, equals: thread)

    let wifiDefault = MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation.defaultSystemNetwork
    let wifiNetwork = MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation.network(
        ssid: Data("ssid".utf8),
        credentials: Data("secret".utf8)
    )
    precondition(wifiDefault == .defaultSystemNetwork)
    precondition(wifiDefault != wifiNetwork)
    assertHashable(wifiDefault, equals: .defaultSystemNetwork)
    assertHashable(wifiNetwork, equals: .network(ssid: Data("ssid".utf8), credentials: Data("secret".utf8)))

    let threadDefault = MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation.defaultSystemNetwork
    let threadNetwork = MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation.network(
        extendedPANID: 0x1122334455667788
    )
    precondition(threadDefault == .defaultSystemNetwork)
    precondition(threadDefault != threadNetwork)
    assertHashable(threadDefault, equals: .defaultSystemNetwork)
    assertHashable(
        threadNetwork,
        equals: .network(extendedPANID: 0x1122334455667788)
    )

    let handler = MatterAddDeviceExtensionRequestHandler()
    let rooms = await handler.rooms(in: home)
    precondition(rooms.isEmpty)
    await handler.configureDevice(named: "Lamp", in: room)

    await requireThrown {
        try await handler.validateDeviceCredential(credential)
    }
    await requireThrown {
        _ = try await handler.selectWiFiNetwork(from: [wifi])
    }
    await requireThrown {
        _ = try await handler.selectThreadNetwork(from: [thread])
    }
    await requireThrown {
        try await handler.commissionDevice(
            in: home,
            onboardingPayload: "MT:AAAA",
            commissioningID: commissioningID
        )
    }

    let probe = ProbeHandler()
    let asBase: MatterAddDeviceExtensionRequestHandler = probe
    let probeRooms = await asBase.rooms(in: home)
    precondition(probeRooms == [MatterAddDeviceRequest.Room(displayName: "Kitchen")])
    await asBase.configureDevice(named: "Overridden", in: nil)

    print("MATTERSUPPORT_AGENT_RUNTIME_OK")
}

await runMatterSupportRuntime()
