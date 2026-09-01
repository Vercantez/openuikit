import Foundation
import MatterSupport

private func requireUnsupported(_ error: Error, operation: String) {
    guard let error = error as? MatterSupportError else {
        fatalError("expected MatterSupportError, got \(error)")
    }
    precondition(error.operation == operation, "unexpected operation \(error.operation)")
}

private func roundTrip<T: Codable & Equatable>(_ value: T) -> T {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    do {
        let data = try encoder.encode(value)
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Codable round-trip failed: \(error)")
    }
}

private func assertHashable<T: Hashable>(_ a: T, equals b: T) {
    precondition(a == b)
    precondition(!(a != b))
    precondition(a.hashValue == b.hashValue)
    precondition(a.hashValue == a.hashValue)
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
        precondition(roundTrip(home) == home)

        let room = MatterAddDeviceRequest.Room(displayName: "Office")
        precondition(room.displayName == "Office")
        assertHashable(room, equals: MatterAddDeviceRequest.Room(displayName: "Office"))
        precondition(room != MatterAddDeviceRequest.Room(displayName: "Lab"))
        precondition(roundTrip(room) == room)

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
        precondition(roundTrip(topology) == topology)

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
            precondition(roundTrip(criteria) == criteria)
        }
        precondition(
            MatterAddDeviceRequest.DeviceCriteria.allDevices
                != MatterAddDeviceRequest.DeviceCriteria.vendorID(1)
        )

        var request = MatterAddDeviceRequest(
            topology: topology,
            showing: .allDevices
        )
        precondition(request.topology == topology)
        precondition(request.setupPayload == nil)
        precondition(request.showDeviceCriteria == .allDevices)
        precondition(request.shouldScanNetworks == true)

        let scanned = MatterAddDeviceRequest(
            topology: topology,
            setupPayload: nil,
            showing: .not(.serialNumber("paired")),
            shouldScanNetworks: false
        )
        precondition(scanned.shouldScanNetworks == false)
        precondition(scanned.showDeviceCriteria == .not(.serialNumber("paired")))
        precondition(request != scanned)
        assertHashable(request, equals: MatterAddDeviceRequest(topology: topology, showing: .allDevices))
        precondition(roundTrip(request) == request)
        precondition(roundTrip(scanned) == scanned)

        let payload = MTRSetupPayload()
        request.setupPayload = payload
        precondition(request.setupPayload === payload)
        let samePayload = request
        assertHashable(request, equals: samePayload)
        var otherPayloadRequest = request
        otherPayloadRequest.setupPayload = MTRSetupPayload()
        precondition(request != otherPayloadRequest)
        let decodedDroppingPayload = roundTrip(request)
        precondition(decodedDroppingPayload.setupPayload == nil)

        do {
            try await request.perform()
            fatalError("perform() must fail closed")
        } catch {
            requireUnsupported(error, operation: "MatterAddDeviceRequest.perform")
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
        precondition(roundTrip(credential) == credential)

        let wifi = MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
            ssid: Data("openuikit".utf8),
            rssi: -40,
            security: [.WPA2Personal, .WPA3Personal],
            band: [.band2G4, .band5G]
        )
        precondition(wifi.rssi == -40)
        precondition(wifi.security.contains(.WPA2Personal))
        precondition(wifi.band.contains(.band5G))
        assertHashable(wifi, equals: wifi)
        precondition(roundTrip(wifi) == wifi)

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
        precondition(roundTrip(thread) == thread)

        let wifiDefault = MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation.defaultSystemNetwork
        let wifiNetwork = MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation.network(
            ssid: Data("ssid".utf8),
            credentials: Data("secret".utf8)
        )
        precondition(wifiDefault == .defaultSystemNetwork)
        precondition(wifiDefault != wifiNetwork)
        assertHashable(wifiDefault, equals: .defaultSystemNetwork)
        assertHashable(wifiNetwork, equals: .network(ssid: Data("ssid".utf8), credentials: Data("secret".utf8)))
        precondition(roundTrip(wifiDefault) == wifiDefault)
        precondition(roundTrip(wifiNetwork) == wifiNetwork)

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
        precondition(roundTrip(threadDefault) == threadDefault)
        precondition(roundTrip(threadNetwork) == threadNetwork)

        let handler = MatterAddDeviceExtensionRequestHandler()
        let rooms = await handler.rooms(in: home)
        precondition(rooms.isEmpty)
        await handler.configureDevice(named: "Lamp", in: room)

        do {
            try await handler.validateDeviceCredential(credential)
            fatalError("validateDeviceCredential must fail closed")
        } catch {
            requireUnsupported(error, operation: "validateDeviceCredential")
        }
        do {
            _ = try await handler.selectWiFiNetwork(from: [wifi])
            fatalError("selectWiFiNetwork must fail closed")
        } catch {
            requireUnsupported(error, operation: "selectWiFiNetwork")
        }
        do {
            _ = try await handler.selectThreadNetwork(from: [thread])
            fatalError("selectThreadNetwork must fail closed")
        } catch {
            requireUnsupported(error, operation: "selectThreadNetwork")
        }
        do {
            try await handler.commissionDevice(
                in: home,
                onboardingPayload: "MT:AAAA",
                commissioningID: commissioningID
            )
            fatalError("commissionDevice must fail closed")
        } catch {
            requireUnsupported(error, operation: "commissionDevice")
        }

        let probe = ProbeHandler()
        let probeRooms = await probe.rooms(in: home)
        precondition(probeRooms == [MatterAddDeviceRequest.Room(displayName: "Kitchen")])
        await probe.configureDevice(named: "Overridden", in: nil)

        print("MATTERSUPPORT_AGENT_RUNTIME_OK")
}

await runMatterSupportRuntime()
