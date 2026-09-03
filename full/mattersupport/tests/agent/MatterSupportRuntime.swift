@_spi(OpenUIKitHost) import MatterSupport
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private func requireUnavailable(
    _ body: () async throws -> Void,
    operation: String
) async {
    do {
        try await body()
        fatalError("expected fail-closed throw for \(operation)")
    } catch let error as NSError {
        precondition(
            error.domain == "MatterSupport.linux.unavailable",
            "unexpected domain \(error.domain) for \(operation)"
        )
        precondition(error.code == 1, "unexpected code \(error.code) for \(operation)")
        precondition(
            !String(reflecting: type(of: error)).hasPrefix("MatterSupport."),
            "fail-closed error must be Foundation.NSError, not a module-local public error type"
        )
    } catch {
        fatalError("wrong error type \(error) for \(operation)")
    }
}

private func roundTrip<T: Codable & Equatable>(_ value: T) -> T {
    let data = try! JSONEncoder().encode(value)
    return try! JSONDecoder().decode(T.self, from: data)
}

private func assertHomeRoomTopology() {
    var home = MatterAddDeviceRequest.Home(displayName: "Main")
    precondition(home.displayName == "Main")
    home.displayName = "Cottage"
    precondition(home.displayName == "Cottage")
    precondition(home != MatterAddDeviceRequest.Home(displayName: "Main"))
    precondition(home == MatterAddDeviceRequest.Home(displayName: "Cottage"))
    var hasher = Hasher()
    home.hash(into: &hasher)
    _ = home.hashValue
    _ = hasher.finalize()
    precondition(roundTrip(home) == home)

    var room = MatterAddDeviceRequest.Room(displayName: "Kitchen")
    precondition(room.displayName == "Kitchen")
    room.displayName = "Hall"
    precondition(room.displayName == "Hall")
    precondition(room != MatterAddDeviceRequest.Room(displayName: "Kitchen"))
    room.hash(into: &hasher)
    _ = room.hashValue
    precondition(roundTrip(room) == room)

    var topology = MatterAddDeviceRequest.Topology(
        ecosystemName: "OpenUIKit",
        homes: [MatterAddDeviceRequest.Home(displayName: "Main")]
    )
    precondition(topology.ecosystemName == "OpenUIKit")
    precondition(topology.homes.count == 1)
    topology.ecosystemName = "Garden"
    topology.homes.append(MatterAddDeviceRequest.Home(displayName: "Shed"))
    precondition(topology.homes.map(\.displayName) == ["Main", "Shed"])
    precondition(
        topology
            != MatterAddDeviceRequest.Topology(ecosystemName: "Garden", homes: [])
    )
    topology.hash(into: &hasher)
    _ = topology.hashValue
    precondition(roundTrip(topology) == topology)
}

private func assertDeviceCriteria() {
    let uuid = UUID()
    let key = Data([0x01, 0x02, 0x03, 0x04])
    let cases: [MatterAddDeviceRequest.DeviceCriteria] = [
        .allDevices,
        .fabricNode(rootPublicKey: key, nodeID: 99),
        .serialNumber("SN-1"),
        .commissioningID(uuid),
        .vendorID(0xFFF1),
        .productID(0x1234),
        .all([.vendorID(1), .productID(2)]),
        .any([.serialNumber("A"), .serialNumber("B")]),
        .not(.allDevices),
    ]
    precondition(Set(cases).count == cases.count)
    precondition(MatterAddDeviceRequest.DeviceCriteria.allDevices == .allDevices)
    precondition(
        MatterAddDeviceRequest.DeviceCriteria.vendorID(1) != .vendorID(2)
    )
    precondition(
        MatterAddDeviceRequest.DeviceCriteria.fabricNode(rootPublicKey: key, nodeID: 99)
            == .fabricNode(rootPublicKey: Data([0x01, 0x02, 0x03, 0x04]), nodeID: 99)
    )
    precondition(
        MatterAddDeviceRequest.DeviceCriteria.not(.allDevices)
            != .not(.serialNumber("x"))
    )
    var hasher = Hasher()
    for item in cases {
        item.hash(into: &hasher)
        _ = item.hashValue
        precondition(roundTrip(item) == item)
    }
    _ = hasher.finalize()
}

private func assertRequestSurface() {
    precondition(MatterAddDeviceRequest.isSupported == false)
    let topology = MatterAddDeviceRequest.Topology(
        ecosystemName: "Eco",
        homes: [MatterAddDeviceRequest.Home(displayName: "Home")]
    )
    var request = MatterAddDeviceRequest(
        topology: topology,
        showing: .allDevices,
        shouldScanNetworks: true
    )
    precondition(request.topology.ecosystemName == "Eco")
    precondition(request.showDeviceCriteria == .allDevices)
    precondition(request.shouldScanNetworks == true)
    request.showDeviceCriteria = .vendorID(7)
    request.shouldScanNetworks = false
    request.topology = MatterAddDeviceRequest.Topology(ecosystemName: "Other", homes: [])
    precondition(request.showDeviceCriteria == .vendorID(7))
    precondition(request.shouldScanNetworks == false)
    precondition(request.topology.ecosystemName == "Other")

    let other = MatterAddDeviceRequest(
        topology: request.topology,
        showing: .vendorID(7),
        shouldScanNetworks: false
    )
    precondition(request == other)
    precondition(
        request
            != MatterAddDeviceRequest(
                topology: request.topology,
                showing: .allDevices,
                shouldScanNetworks: false
            )
    )
    var hasher = Hasher()
    request.hash(into: &hasher)
    _ = request.hashValue
    _ = hasher.finalize()
    precondition(roundTrip(request) == request)
}

private func assertCredentialsAndScanResults() {
    let credential = MatterAddDeviceExtensionRequestHandler.DeviceCredential(
        certificationDeclaration: Data("cd".utf8),
        deviceAttestationCertificate: Data("dac".utf8),
        productAttestationIntermediateCertificate: Data("pai".utf8)
    )
    precondition(credential.certificationDeclaration == Data("cd".utf8))
    precondition(credential.deviceAttestationCertificate == Data("dac".utf8))
    precondition(
        credential.productAttestationIntermediateCertificate == Data("pai".utf8)
    )
    precondition(
        credential
            != MatterAddDeviceExtensionRequestHandler.DeviceCredential(
                certificationDeclaration: Data("x".utf8),
                deviceAttestationCertificate: Data("dac".utf8),
                productAttestationIntermediateCertificate: Data("pai".utf8)
            )
    )
    var hasher = Hasher()
    credential.hash(into: &hasher)
    _ = credential.hashValue
    precondition(roundTrip(credential) == credential)

    let wifi = MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
        ssid: Data("net".utf8),
        rssi: -40
    )
    precondition(wifi.ssid == Data("net".utf8))
    precondition(wifi.rssi == -40)
    precondition(
        wifi
            != MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
                ssid: Data("net".utf8),
                rssi: -50
            )
    )
    wifi.hash(into: &hasher)
    _ = wifi.hashValue
    precondition(roundTrip(wifi) == wifi)

    let thread = MatterAddDeviceExtensionRequestHandler.ThreadScanResult(
        networkName: "ThreadNet",
        panID: 0x1234,
        extendedPANID: 0xAABBCCDDEEFF0011,
        channel: 15,
        extendedAddress: Data([0x0A, 0x0B]),
        rssi: -70,
        version: 3,
        linkQualityIndicator: 200
    )
    precondition(thread.networkName == "ThreadNet")
    precondition(thread.panID == 0x1234)
    precondition(thread.extendedPANID == 0xAABBCCDDEEFF0011)
    precondition(thread.channel == 15)
    precondition(thread.extendedAddress == Data([0x0A, 0x0B]))
    precondition(thread.rssi == -70)
    precondition(thread.version == 3)
    precondition(thread.linkQualityIndicator == 200)
    precondition(
        thread
            != MatterAddDeviceExtensionRequestHandler.ThreadScanResult(
                networkName: "Other",
                panID: 1,
                extendedPANID: 2,
                channel: 3,
                extendedAddress: Data(),
                rssi: 0,
                version: 0,
                linkQualityIndicator: 0
            )
    )
    thread.hash(into: &hasher)
    _ = thread.hashValue
    precondition(roundTrip(thread) == thread)
    _ = hasher.finalize()
}

private func assertNetworkAssociations() {
    let wifiDefault = MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation
        .defaultSystemNetwork
    let wifiCreds = MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation.network(
        ssid: Data("ssid".utf8),
        credentials: Data("psk".utf8)
    )
    let wifiCredsSame = MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation.network(
        ssid: Data("ssid".utf8),
        credentials: Data("psk".utf8)
    )
    precondition(wifiDefault == .defaultSystemNetwork)
    precondition(wifiCreds == wifiCredsSame)
    precondition(wifiDefault != wifiCreds)
    precondition(
        wifiCreds
            != MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation.network(
                ssid: Data("ssid".utf8),
                credentials: Data("other".utf8)
            )
    )
    var hasher = Hasher()
    wifiDefault.hash(into: &hasher)
    wifiCreds.hash(into: &hasher)
    _ = wifiDefault.hashValue
    precondition(roundTrip(wifiDefault) == wifiDefault)
    precondition(roundTrip(wifiCreds) == wifiCreds)

    let threadDefault = MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation
        .defaultSystemNetwork
    let threadPAN = MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation.network(
        extendedPANID: 42
    )
    precondition(threadDefault == .defaultSystemNetwork)
    precondition(threadPAN == .network(extendedPANID: 42))
    precondition(threadDefault != threadPAN)
    precondition(threadPAN != .network(extendedPANID: 43))
    threadDefault.hash(into: &hasher)
    _ = threadPAN.hashValue
    precondition(roundTrip(threadDefault) == threadDefault)
    precondition(roundTrip(threadPAN) == threadPAN)
    _ = hasher.finalize()
}

private func assertHandlerIdentityAndDefaults() async {
    let first = MatterAddDeviceExtensionRequestHandler()
    let second = MatterAddDeviceExtensionRequestHandler()
    precondition(first == first)
    precondition(first != second)
    var hasher = Hasher()
    first.hash(into: &hasher)
    _ = first.hashValue
    _ = hasher.finalize()

    let rooms = await first.rooms(in: MatterAddDeviceRequest.Home(displayName: "H"))
    precondition(rooms.isEmpty)
    await first.configureDevice(
        named: "Lamp",
        in: MatterAddDeviceRequest.Room(displayName: "Kitchen")
    )

    let credential = MatterAddDeviceExtensionRequestHandler.DeviceCredential(
        certificationDeclaration: Data(),
        deviceAttestationCertificate: Data(),
        productAttestationIntermediateCertificate: Data()
    )
    await requireUnavailable(
        { try await first.validateDeviceCredential(credential) },
        operation: "validateDeviceCredential"
    )
    await requireUnavailable(
        {
            try await first.commissionDevice(
                in: nil,
                onboardingPayload: "MT:AAAA",
                commissioningID: UUID()
            )
        },
        operation: "commissionDevice"
    )

    let wifi = MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
        ssid: Data("x".utf8),
        rssi: -30
    )
    await requireUnavailable(
        { _ = try await first.selectWiFiNetwork(from: [wifi]) },
        operation: "selectWiFiNetwork"
    )
    let thread = MatterAddDeviceExtensionRequestHandler.ThreadScanResult(
        networkName: "n",
        panID: 1,
        extendedPANID: 2,
        channel: 3,
        extendedAddress: Data(),
        rssi: -1,
        version: 1,
        linkQualityIndicator: 1
    )
    await requireUnavailable(
        { _ = try await first.selectThreadNetwork(from: [thread]) },
        operation: "selectThreadNetwork"
    )
}

private final class ProbeHandler: MatterAddDeviceExtensionRequestHandler {
    var roomsSeen: MatterAddDeviceRequest.Home?
    var configuredName: String?
    var configuredRoom: MatterAddDeviceRequest.Room?
    var commissionedPayload: String?
    var selectedWiFiCount: Int = -1
    var selectedThreadCount: Int = -1
    var validated: Bool = false

    override func rooms(
        in home: MatterAddDeviceRequest.Home?
    ) async -> [MatterAddDeviceRequest.Room] {
        roomsSeen = home
        return [MatterAddDeviceRequest.Room(displayName: "OverrideRoom")]
    }

    override func configureDevice(
        named name: String,
        in room: MatterAddDeviceRequest.Room?
    ) async {
        configuredName = name
        configuredRoom = room
    }

    override func commissionDevice(
        in home: MatterAddDeviceRequest.Home?,
        onboardingPayload: String,
        commissioningID: UUID
    ) async throws {
        _ = home
        _ = commissioningID
        commissionedPayload = onboardingPayload
    }

    override func validateDeviceCredential(
        _ deviceCredential: MatterAddDeviceExtensionRequestHandler.DeviceCredential
    ) async throws {
        _ = deviceCredential
        validated = true
    }

    override func selectWiFiNetwork(
        from wifiScanResults: [MatterAddDeviceExtensionRequestHandler.WiFiScanResult]
    ) async throws -> MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation {
        selectedWiFiCount = wifiScanResults.count
        return .defaultSystemNetwork
    }

    override func selectThreadNetwork(
        from threadScanResults: [MatterAddDeviceExtensionRequestHandler.ThreadScanResult]
    ) async throws -> MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation {
        selectedThreadCount = threadScanResults.count
        return .defaultSystemNetwork
    }
}

private func assertHandlerOverrideDispatch() async {
    let probe = ProbeHandler()
    let asBase: MatterAddDeviceExtensionRequestHandler = probe
    let home = MatterAddDeviceRequest.Home(displayName: "Villa")
    let rooms = await asBase.rooms(in: home)
    precondition(rooms.map(\.displayName) == ["OverrideRoom"])
    precondition(probe.roomsSeen == home)

    await asBase.configureDevice(
        named: "Plug",
        in: MatterAddDeviceRequest.Room(displayName: "Den")
    )
    precondition(probe.configuredName == "Plug")
    precondition(probe.configuredRoom?.displayName == "Den")

    try! await asBase.commissionDevice(
        in: home,
        onboardingPayload: "MT:PAYLOAD",
        commissioningID: UUID()
    )
    precondition(probe.commissionedPayload == "MT:PAYLOAD")

    try! await asBase.validateDeviceCredential(
        MatterAddDeviceExtensionRequestHandler.DeviceCredential(
            certificationDeclaration: Data([1]),
            deviceAttestationCertificate: Data([2]),
            productAttestationIntermediateCertificate: Data([3])
        )
    )
    precondition(probe.validated)

    let wifi = try! await asBase.selectWiFiNetwork(
        from: [
            MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
                ssid: Data("a".utf8),
                rssi: -20
            )
        ]
    )
    precondition(wifi == .defaultSystemNetwork)
    precondition(probe.selectedWiFiCount == 1)

    let thread = try! await asBase.selectThreadNetwork(
        from: [
            MatterAddDeviceExtensionRequestHandler.ThreadScanResult(
                networkName: "t",
                panID: 1,
                extendedPANID: 2,
                channel: 3,
                extendedAddress: Data(),
                rssi: 0,
                version: 1,
                linkQualityIndicator: 1
            )
        ]
    )
    precondition(thread == .defaultSystemNetwork)
    precondition(probe.selectedThreadCount == 1)
}

private func assertPerformFailsClosed() async {
    let request = MatterAddDeviceRequest(
        topology: MatterAddDeviceRequest.Topology(ecosystemName: "Eco", homes: []),
        showing: .allDevices,
        shouldScanNetworks: true
    )
    await requireUnavailable({ try await request.perform() }, operation: "perform")
}

private func assertConcurrentPerform() async {
    let request = MatterAddDeviceRequest(
        topology: MatterAddDeviceRequest.Topology(ecosystemName: "Eco", homes: []),
        showing: .allDevices,
        shouldScanNetworks: true
    )
    await withTaskGroup(of: String.self) { group in
        for _ in 0..<8 {
            group.addTask {
                do {
                    try await request.perform()
                    fatalError("perform must not succeed")
                } catch let error as NSError {
                    return error.domain
                } catch {
                    fatalError("unexpected \(error)")
                }
            }
        }
        var count = 0
        for await domain in group {
            precondition(domain == "MatterSupport.linux.unavailable")
            count += 1
        }
        precondition(count == 8)
    }
}

func matterSupportRuntimeMain() async {
    assertHomeRoomTopology()
    assertDeviceCriteria()
    assertRequestSurface()
    assertCredentialsAndScanResults()
    assertNetworkAssociations()
    await assertHandlerIdentityAndDefaults()
    await assertHandlerOverrideDispatch()
    await assertPerformFailsClosed()
    await assertConcurrentPerform()
    print("MATTERSUPPORT_AGENT_RUNTIME_OK")
}

let runtimeSemaphore = DispatchSemaphore(value: 0)
Task {
    await matterSupportRuntimeMain()
    runtimeSemaphore.signal()
}
precondition(
    runtimeSemaphore.wait(timeout: .now() + eventTimeout) == .success,
    "MatterSupport runtime probe timed out"
)
