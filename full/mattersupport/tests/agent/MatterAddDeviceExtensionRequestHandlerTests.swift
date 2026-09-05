@_spi(OpenUIKitHost) import MatterSupport
import Foundation

private final class RecordingHandler: MatterAddDeviceExtensionRequestHandler {
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
        if let first = threadScanResults.first {
            return .network(extendedPANID: first.extendedPANID)
        }
        return .defaultSystemNetwork
    }
}

func testHandlerClassAndInit() {
    let first = MatterAddDeviceExtensionRequestHandler()
    let second = MatterAddDeviceExtensionRequestHandler()
    precondition(first == first)
    precondition(first != second)
    var hasher = Hasher()
    first.hash(into: &hasher)
    _ = first.hashValue
    _ = hasher.finalize()
    let asObject: NSObject = first
    precondition(asObject === first)
}

func testHandlerRoomsReturnsEmpty() {
    let handler = MatterAddDeviceExtensionRequestHandler()
    matterSupportAwait {
        let rooms = await handler.rooms(
            in: MatterAddDeviceRequest.Home(displayName: "H")
        )
        precondition(rooms.isEmpty)
        let nilHomeRooms = await handler.rooms(in: nil)
        precondition(nilHomeRooms.isEmpty)
    }

    let probe = RecordingHandler()
    let asBase: MatterAddDeviceExtensionRequestHandler = probe
    let home = MatterAddDeviceRequest.Home(displayName: "Villa")
    matterSupportAwait {
        let rooms = await asBase.rooms(in: home)
        precondition(rooms.map(\.displayName) == ["OverrideRoom"])
        precondition(probe.roomsSeen == home)
    }
}

func testHandlerConfigureDeviceNoOp() {
    let handler = MatterAddDeviceExtensionRequestHandler()
    matterSupportAwait {
        await handler.configureDevice(
            named: "Lamp",
            in: MatterAddDeviceRequest.Room(displayName: "Kitchen")
        )
        await handler.configureDevice(named: "Lamp", in: nil)
    }

    let probe = RecordingHandler()
    let asBase: MatterAddDeviceExtensionRequestHandler = probe
    matterSupportAwait {
        await asBase.configureDevice(
            named: "Plug",
            in: MatterAddDeviceRequest.Room(displayName: "Den")
        )
        precondition(probe.configuredName == "Plug")
        precondition(probe.configuredRoom?.displayName == "Den")
    }
}

func testHandlerValidateCredentialFailsClosed() {
    let handler = MatterAddDeviceExtensionRequestHandler()
    let credential = MatterAddDeviceExtensionRequestHandler.DeviceCredential(
        certificationDeclaration: Data(),
        deviceAttestationCertificate: Data(),
        productAttestationIntermediateCertificate: Data()
    )
    matterSupportRequireUnavailable(operation: "validateDeviceCredential") {
        try await handler.validateDeviceCredential(credential)
    }

    let probe = RecordingHandler()
    let asBase: MatterAddDeviceExtensionRequestHandler = probe
    matterSupportAwait {
        try! await asBase.validateDeviceCredential(credential)
        precondition(probe.validated)
    }
}

func testHandlerCommissionDeviceFailsClosed() {
    let handler = MatterAddDeviceExtensionRequestHandler()
    matterSupportRequireUnavailable(operation: "commissionDevice") {
        try await handler.commissionDevice(
            in: nil,
            onboardingPayload: "MT:AAAA",
            commissioningID: UUID()
        )
    }

    let probe = RecordingHandler()
    let asBase: MatterAddDeviceExtensionRequestHandler = probe
    let home = MatterAddDeviceRequest.Home(displayName: "Villa")
    matterSupportAwait {
        try! await asBase.commissionDevice(
            in: home,
            onboardingPayload: "MT:PAYLOAD",
            commissioningID: UUID()
        )
        precondition(probe.commissionedPayload == "MT:PAYLOAD")
    }
}

func testHandlerSelectWiFiNetworkFailsClosed() {
    let handler = MatterAddDeviceExtensionRequestHandler()
    let wifi = MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
        ssid: Data("x".utf8),
        rssi: -30
    )
    matterSupportRequireUnavailable(operation: "selectWiFiNetwork") {
        _ = try await handler.selectWiFiNetwork(from: [wifi])
    }

    let probe = RecordingHandler()
    let asBase: MatterAddDeviceExtensionRequestHandler = probe
    matterSupportAwait {
        let association = try! await asBase.selectWiFiNetwork(from: [wifi])
        precondition(association == .defaultSystemNetwork)
        precondition(probe.selectedWiFiCount == 1)
    }
}

func testHandlerSelectThreadNetworkFailsClosed() {
    let handler = MatterAddDeviceExtensionRequestHandler()
    let thread = MatterAddDeviceExtensionRequestHandler.ThreadScanResult(
        networkName: "n",
        panID: 1,
        extendedPANID: 0xAABB,
        channel: 3,
        extendedAddress: Data(),
        rssi: -1,
        version: 1,
        linkQualityIndicator: 1
    )
    matterSupportRequireUnavailable(operation: "selectThreadNetwork") {
        _ = try await handler.selectThreadNetwork(from: [thread])
    }

    let probe = RecordingHandler()
    let asBase: MatterAddDeviceExtensionRequestHandler = probe
    matterSupportAwait {
        let association = try! await asBase.selectThreadNetwork(from: [thread])
        precondition(association == .network(extendedPANID: 0xAABB))
        precondition(probe.selectedThreadCount == 1)
    }
}

func testDeviceCredentialStorage() {
    var credential = MatterAddDeviceExtensionRequestHandler.DeviceCredential(
        certificationDeclaration: Data("cd".utf8),
        deviceAttestationCertificate: Data("dac".utf8),
        productAttestationIntermediateCertificate: Data("pai".utf8)
    )
    precondition(credential.certificationDeclaration == Data("cd".utf8))
    precondition(credential.deviceAttestationCertificate == Data("dac".utf8))
    precondition(credential.productAttestationIntermediateCertificate == Data("pai".utf8))
    credential.certificationDeclaration = Data("cd2".utf8)
    let same = MatterAddDeviceExtensionRequestHandler.DeviceCredential(
        certificationDeclaration: Data("cd2".utf8),
        deviceAttestationCertificate: Data("dac".utf8),
        productAttestationIntermediateCertificate: Data("pai".utf8)
    )
    let other = MatterAddDeviceExtensionRequestHandler.DeviceCredential(
        certificationDeclaration: Data("x".utf8),
        deviceAttestationCertificate: Data("dac".utf8),
        productAttestationIntermediateCertificate: Data("pai".utf8)
    )
    precondition(credential == same)
    precondition(credential != other)
    precondition(credential.hashValue == same.hashValue)
    var hasher = Hasher()
    credential.hash(into: &hasher)
    _ = hasher.finalize()
}

func testDeviceCredentialCodable() {
    let credential = MatterAddDeviceExtensionRequestHandler.DeviceCredential(
        certificationDeclaration: Data("cd".utf8),
        deviceAttestationCertificate: Data("dac".utf8),
        productAttestationIntermediateCertificate: Data("pai".utf8)
    )
    precondition(matterSupportRoundTrip(credential) == credential)
    let object = matterSupportJSONObject(credential)
    precondition(object["certificationDeclaration"] != nil)
    precondition(object["deviceAttestationCertificate"] != nil)
    precondition(object["productAttestationIntermediateCertificate"] != nil)
}

func testWiFiScanResultStorage() {
    let wifi = MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
        ssid: Data("net".utf8),
        rssi: -40
    )
    precondition(wifi.ssid == Data("net".utf8))
    precondition(wifi.rssi == -40)
    let same = MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
        ssid: Data("net".utf8),
        rssi: -40
    )
    let other = MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
        ssid: Data("net".utf8),
        rssi: -50
    )
    precondition(wifi == same)
    precondition(wifi != other)
    precondition(wifi.hashValue == same.hashValue)
    var hasher = Hasher()
    wifi.hash(into: &hasher)
    _ = hasher.finalize()
}

func testWiFiScanResultCodable() {
    let wifi = MatterAddDeviceExtensionRequestHandler.WiFiScanResult(
        ssid: Data("net".utf8),
        rssi: -40
    )
    precondition(matterSupportRoundTrip(wifi) == wifi)
    let object = matterSupportJSONObject(wifi)
    precondition(object["rssi"] as? Int == -40)
    precondition(object["ssid"] != nil)
    precondition(object["security"] == nil)
    precondition(object["band"] == nil)
}

func testThreadScanResultStorage() {
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
    let same = MatterAddDeviceExtensionRequestHandler.ThreadScanResult(
        networkName: "ThreadNet",
        panID: 0x1234,
        extendedPANID: 0xAABBCCDDEEFF0011,
        channel: 15,
        extendedAddress: Data([0x0A, 0x0B]),
        rssi: -70,
        version: 3,
        linkQualityIndicator: 200
    )
    let other = MatterAddDeviceExtensionRequestHandler.ThreadScanResult(
        networkName: "Other",
        panID: 1,
        extendedPANID: 2,
        channel: 3,
        extendedAddress: Data(),
        rssi: 0,
        version: 0,
        linkQualityIndicator: 0
    )
    precondition(thread == same)
    precondition(thread != other)
    precondition(thread.hashValue == same.hashValue)
    var hasher = Hasher()
    thread.hash(into: &hasher)
    _ = hasher.finalize()
}

func testThreadScanResultCodable() {
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
    precondition(matterSupportRoundTrip(thread) == thread)
    let object = matterSupportJSONObject(thread)
    precondition(object["networkName"] as? String == "ThreadNet")
    precondition(object["panID"] as? Int == 0x1234)
    precondition(object["channel"] as? Int == 15)
    precondition(object["version"] as? Int == 3)
    precondition(object["linkQualityIndicator"] as? Int == 200)
}

func testWiFiNetworkAssociationCases() {
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
    precondition(wifiDefault.hashValue == MatterAddDeviceExtensionRequestHandler
        .WiFiNetworkAssociation.defaultSystemNetwork.hashValue)
    var hasher = Hasher()
    wifiDefault.hash(into: &hasher)
    wifiCreds.hash(into: &hasher)
    _ = hasher.finalize()
}

func testWiFiNetworkAssociationCodable() {
    let wifiDefault = MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation
        .defaultSystemNetwork
    let wifiCreds = MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation.network(
        ssid: Data("ssid".utf8),
        credentials: Data("psk".utf8)
    )
    precondition(matterSupportRoundTrip(wifiDefault) == wifiDefault)
    precondition(matterSupportRoundTrip(wifiCreds) == wifiCreds)
    let defaultJSON = matterSupportJSONObject(wifiDefault)
    precondition(defaultJSON["kind"] as? String == "defaultSystemNetwork")
    let credsJSON = matterSupportJSONObject(wifiCreds)
    precondition(credsJSON["kind"] as? String == "ssidCredentials")
}

func testThreadNetworkAssociationCases() {
    let threadDefault = MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation
        .defaultSystemNetwork
    let threadPAN = MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation.network(
        extendedPANID: 42
    )
    precondition(threadDefault == .defaultSystemNetwork)
    precondition(threadPAN == .network(extendedPANID: 42))
    precondition(threadDefault != threadPAN)
    precondition(threadPAN != .network(extendedPANID: 43))
    precondition(
        threadDefault.hashValue
            == MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation
            .defaultSystemNetwork.hashValue
    )
    var hasher = Hasher()
    threadDefault.hash(into: &hasher)
    _ = threadPAN.hashValue
    _ = hasher.finalize()
}

func testThreadNetworkAssociationCodable() {
    let threadDefault = MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation
        .defaultSystemNetwork
    let threadPAN = MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation.network(
        extendedPANID: 42
    )
    precondition(matterSupportRoundTrip(threadDefault) == threadDefault)
    precondition(matterSupportRoundTrip(threadPAN) == threadPAN)
    let defaultJSON = matterSupportJSONObject(threadDefault)
    precondition(defaultJSON["kind"] as? String == "defaultSystemNetwork")
    let panJSON = matterSupportJSONObject(threadPAN)
    precondition(panJSON["kind"] as? String == "extendedPANID")
    precondition((panJSON["extendedPANID"] as? NSNumber)?.uint64Value == 42)
}
