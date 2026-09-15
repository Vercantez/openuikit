import Foundation
import Matter

// Wave-8 leftover conversion: Apple-oracle legacy enum spellings, callback
// typealias containers, and protocol containers. Every test is top-level,
// synchronous, and takes no arguments. All inputs are local values; control
// returns to the caller inline with no queue hops or waiting.

// MARK: - Apple-oracle legacy enum spellings (Xcode 26.1 pinned)

func testTimeSynchronizationLegacySourceAliasesWave8() {
    mtrRequire(MTRTimeSynchronizationTimeSource.nonFabricSntp == .nonMatterSNTP, "nonFabricSntp aliases nonMatterSNTP")
    mtrRequire(MTRTimeSynchronizationTimeSource.nonFabricNtp == .nonMatterNTP, "nonFabricNtp aliases nonMatterNTP")
    mtrRequire(MTRTimeSynchronizationTimeSource.fabricSntp == .matterSNTP, "fabricSntp aliases matterSNTP")
    mtrRequire(MTRTimeSynchronizationTimeSource.fabricNtp == .matterNTP, "fabricNtp aliases matterNTP")
    mtrRequire(MTRTimeSynchronizationTimeSource.mixedNtp == .mixedNTP, "mixedNtp aliases mixedNTP")
    mtrRequire(MTRTimeSynchronizationTimeSource.nonFabricSntpNts == .nonMatterSNTPNTS, "nonFabricSntpNts aliases nonMatterSNTPNTS")
    mtrRequire(MTRTimeSynchronizationTimeSource.nonFabricNtpNts == .nonMatterNTPNTS, "nonFabricNtpNts aliases nonMatterNTPNTS")
    mtrRequire(MTRTimeSynchronizationTimeSource.fabricSntpNts == .matterSNTPNTS, "fabricSntpNts aliases matterSNTPNTS")
    mtrRequire(MTRTimeSynchronizationTimeSource.fabricNtpNts == .matterNTPNTS, "fabricNtpNts aliases matterNTPNTS")
    mtrRequire(MTRTimeSynchronizationTimeSource.mixedNtpNts == .mixedNTPNTS, "mixedNtpNts aliases mixedNTPNTS")
    mtrRequire(MTRTimeSynchronizationTimeSource.ptp == .PTP, "ptp aliases PTP")
    mtrRequire(MTRTimeSynchronizationTimeSource.gnss == .GNSS, "gnss aliases GNSS")
    mtrCheck(MTRTimeSynchronizationTimeSource.nonFabricSntp, 4, "nonFabricSntp raw")
    mtrCheck(MTRTimeSynchronizationTimeSource.nonFabricNtp, 5, "nonFabricNtp raw")
    mtrCheck(MTRTimeSynchronizationTimeSource.fabricSntp, 6, "fabricSntp raw")
    mtrCheck(MTRTimeSynchronizationTimeSource.fabricNtp, 7, "fabricNtp raw")
    mtrCheck(MTRTimeSynchronizationTimeSource.mixedNtp, 8, "mixedNtp raw")
    mtrCheck(MTRTimeSynchronizationTimeSource.nonFabricSntpNts, 9, "nonFabricSntpNts raw")
    mtrCheck(MTRTimeSynchronizationTimeSource.nonFabricNtpNts, 10, "nonFabricNtpNts raw")
    mtrCheck(MTRTimeSynchronizationTimeSource.fabricSntpNts, 11, "fabricSntpNts raw")
    mtrCheck(MTRTimeSynchronizationTimeSource.fabricNtpNts, 12, "fabricNtpNts raw")
    mtrCheck(MTRTimeSynchronizationTimeSource.mixedNtpNts, 13, "mixedNtpNts raw")
    mtrCheck(MTRTimeSynchronizationTimeSource.ptp, 15, "ptp raw")
    mtrCheck(MTRTimeSynchronizationTimeSource.gnss, 16, "gnss raw")
}

func testThermostatAdjustModeLegacyAliasesWave8() {
    mtrRequire(MTRThermostatSetpointAdjustMode.heatSetpoint == .heat, "heatSetpoint aliases heat")
    mtrRequire(MTRThermostatSetpointAdjustMode.coolSetpoint == .cool, "coolSetpoint aliases cool")
    mtrRequire(MTRThermostatSetpointAdjustMode.heatAndCoolSetpoints == .both, "heatAndCoolSetpoints aliases both")
    mtrCheck(MTRThermostatSetpointAdjustMode.heatSetpoint, 0, "heatSetpoint raw")
    mtrCheck(MTRThermostatSetpointAdjustMode.coolSetpoint, 1, "coolSetpoint raw")
    mtrCheck(MTRThermostatSetpointAdjustMode.heatAndCoolSetpoints, 2, "heatAndCoolSetpoints raw")
}

func testWiFiVersionLegacyTypeAliasesWave8() {
    mtrRequire(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211a == .A, "type80211a aliases A")
    mtrRequire(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211b == .B, "type80211b aliases B")
    mtrRequire(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211g == .G, "type80211g aliases G")
    mtrRequire(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211n == .N, "type80211n aliases N")
    mtrRequire(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211ac == .ac, "type80211ac aliases ac")
    mtrRequire(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211ax == .ax, "type80211ax aliases ax")
    mtrCheck(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211a, 0, "type80211a raw")
    mtrCheck(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211b, 1, "type80211b raw")
    mtrCheck(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211g, 2, "type80211g raw")
    mtrCheck(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211n, 3, "type80211n raw")
    mtrCheck(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211ac, 4, "type80211ac raw")
    mtrCheck(MTRWiFiNetworkDiagnosticsWiFiVersionType.type80211ax, 5, "type80211ax raw")
}

// MARK: - Callback typealias containers

func testWave8StatusCompletionAliases() {
    var first: (any Error)?? = .some(nil)
    var second: (any Error)?? = .some(nil)
    let legacy: MTRStatusCompletion = { first = $0 }
    let modern: StatusCompletion = { second = $0 }
    legacy(nil)
    modern(MTRError(.invalidState) as any Error)
    mtrRequire(first! == nil, "MTRStatusCompletion passes nil")
    mtrRequire((second! as? MTRError)?.code == .invalidState, "StatusCompletion passes error")
}

func testWave8ValuesHandlerAliases() {
    var legacyValue: Any? = nil
    var modernValue: Any? = nil
    var responseCount = 0
    let legacy: MTRValuesHandler = { value, _ in legacyValue = value; responseCount += 1 }
    let modern: ResponseHandler = { value, _ in modernValue = value; responseCount += 1 }
    let deviceResponse: MTRDeviceResponseHandler = { values, _ in
        responseCount += (values?.count ?? 0)
    }
    legacy(7 as Any, nil)
    modern("v" as Any, nil)
    deviceResponse([["k": 1], ["k": 2]], nil)
    mtrRequire((legacyValue as? Int) == 7, "MTRValuesHandler passes value")
    mtrRequire((modernValue as? String) == "v", "ResponseHandler passes value")
    mtrRequire(responseCount == 4, "all three handlers ran")
}

func testWave8DeviceHandlerAliases() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(9), controller: controller)
    var connectedID: Int = -1
    var reported: [Any] = []
    var scheduledDelay: Int = -1
    var getterCalled = false
    var errorSeen = false
    let connection: MTRDeviceConnectionCallback = { base, _ in
        connectedID = (base as? MTRDevice)?.nodeID.intValue ?? -1
    }
    let report: MTRDeviceReportHandler = { reported = $0 }
    let reschedule: MTRDeviceResubscriptionScheduledHandler = { _, delay in
        scheduledDelay = delay.intValue
    }
    let getter: MTRDeviceControllerGetterHandler = { _, _ in getterCalled = true }
    let failure: MTRDeviceErrorHandler = { _ in errorSeen = true }
    connection(device, nil)
    report([1, "two"])
    reschedule(MTRError(.invalidState) as any Error, NSNumber(value: 30))
    getter(controller, nil)
    failure(MTRError(.invalidState) as any Error)
    mtrRequire(connectedID == 9, "MTRDeviceConnectionCallback passes device")
    mtrRequire(reported.count == 2, "MTRDeviceReportHandler passes reports")
    mtrRequire(scheduledDelay == 30, "MTRDeviceResubscriptionScheduledHandler passes delay")
    mtrRequire(getterCalled, "MTRDeviceControllerGetterHandler runs")
    mtrRequire(errorSeen, "MTRDeviceErrorHandler runs")
}

func testWave8CommissioningHandlerAliases() {
    var logEntries: [(MTRLogType, String, String)] = []
    var readyArgs: [(Any, Int)] = []
    var chainLengths: [Int] = []
    var establishedCount = 0
    let log: MTRLogCallback = { logEntries.append(($0, $1, $2)) }
    let ready: MTRAsyncCallbackReadyHandler = { readyArgs.append(($0, $1)) }
    let chain: MTRNOCChainGenerationCompleteHandler = { noc, icac, rcac, _, _ in
        chainLengths = [noc?.count ?? -1, icac?.count ?? -1, rcac?.count ?? -1]
    }
    let window: MTRDeviceOpenCommissioningWindowHandler = { payload, _ in
        logEntries.append((.detail, "window", payload == nil ? "nil" : "payload"))
    }
    let legacyEstablished: MTRSubscriptionEstablishedHandler = { establishedCount += 1 }
    let modernEstablished: SubscriptionEstablishedHandler = { establishedCount += 1 }
    log(.error, "tag", "message")
    ready("token" as Any, 3)
    chain(Data([0x01]), Data([0x02, 0x03]), nil, nil, nil)
    window(nil, nil)
    legacyEstablished()
    modernEstablished()
    mtrRequire(logEntries.count == 2, "MTRLogCallback and window handler ran")
    mtrRequire(logEntries[0].0 == .error && logEntries[0].1 == "tag", "MTRLogCallback passes fields")
    mtrRequire(readyArgs.count == 1 && readyArgs[0].1 == 3, "MTRAsyncCallbackReadyHandler passes cookie")
    mtrRequire(chainLengths == [1, 2, -1], "MTRNOCChainGenerationCompleteHandler passes chains")
    mtrRequire(establishedCount == 2, "subscription established handlers run")
}

func testWave8ByteAliases() {
    let csr: MTRCSRDERBytes = Data([0x30, 0x01])
    let der: MTRCertificateDERBytes = Data([0x30, 0x02, 0x03])
    let tlv: MTRCertificateTLVBytes = Data([0x15])
    let raw: MTRTLVBytes = Data()
    mtrRequire(csr.count == 2 && der.count == 3, "DER byte aliases hold bytes")
    mtrRequire(tlv == Data([0x15]) && raw.isEmpty, "TLV byte aliases hold bytes")
    mtrRequire((csr as Data).count == 2, "MTRCSRDERBytes is Data")
}

// MARK: - Protocol containers

private final class Wave8PairingStub: NSObject, MTRDevicePairingDelegate {}
private final class Wave8ControllerDelegateStub: NSObject, MTRDeviceControllerDelegate {}
private final class Wave8BrowserStub: NSObject, MTRCommissionableBrowserDelegate {}
private final class Wave8AttestationStub: NSObject, MTRDeviceAttestationDelegate {}

func testWave8CommissioningDelegateProtocols() {
    let pairing: Any = Wave8PairingStub()
    let delegate: Any = Wave8ControllerDelegateStub()
    let browser: Any = Wave8BrowserStub()
    let attestation: Any = Wave8AttestationStub()
    mtrRequire(pairing is any MTRDevicePairingDelegate, "MTRDevicePairingDelegate conformance")
    mtrRequire(delegate is any MTRDeviceControllerDelegate, "MTRDeviceControllerDelegate conformance")
    mtrRequire(browser is any MTRCommissionableBrowserDelegate, "MTRCommissionableBrowserDelegate conformance")
    mtrRequire(attestation is any MTRDeviceAttestationDelegate, "MTRDeviceAttestationDelegate conformance")
    let pairingExistential: any MTRDevicePairingDelegate = Wave8PairingStub()
    let delegateExistential: any MTRDeviceControllerDelegate = Wave8ControllerDelegateStub()
    mtrRequire((pairingExistential as AnyObject) is Wave8PairingStub, "MTRDevicePairingDelegate existential holds stub")
    mtrRequire((delegateExistential as AnyObject) is Wave8ControllerDelegateStub, "MTRDeviceControllerDelegate existential holds stub")
}

private class Wave8MemoryStorage: NSObject, MTRStorage {
    var box: [String: Data] = [:]
    func storageData(forKey key: String) -> Data? { box[key] }
    func setStorageData(_ value: Data, forKey key: String) -> Bool {
        box[key] = value
        return true
    }
    func removeStorageData(forKey key: String) -> Bool {
        box.removeValue(forKey: key) != nil
    }
}
private final class Wave8PersistentStub: Wave8MemoryStorage, MTRPersistentStorageDelegate {}
private final class Wave8ControllerStorageStub: NSObject, MTRDeviceControllerStorageDelegate {}
private final class Wave8KeypairStub: NSObject, MTRKeypair {
    func signMessageECDSA_RAW(_ message: Data) -> Data { message }
    func signMessageECDSA_DER(_ message: Data) -> Data { message }
}

func testWave8StorageKeypairProtocols() {
    let memory = Wave8MemoryStorage()
    mtrRequire(memory.setStorageData(Data([0xAA]), forKey: "k"), "MTRStorage stores bytes")
    mtrRequire(memory.storageData(forKey: "k") == Data([0xAA]), "MTRStorage reads bytes")
    mtrRequire(memory.removeStorageData(forKey: "k"), "MTRStorage removes bytes")
    mtrRequire(memory.storageData(forKey: "k") == nil, "MTRStorage removal sticks")
    let persistent: Any = Wave8PersistentStub()
    mtrRequire(persistent is any MTRPersistentStorageDelegate, "MTRPersistentStorageDelegate conformance")
    mtrRequire(persistent is any MTRStorage, "MTRPersistentStorageDelegate refines MTRStorage")
    let storageStub: Any = Wave8ControllerStorageStub()
    mtrRequire(storageStub is any MTRDeviceControllerStorageDelegate, "MTRDeviceControllerStorageDelegate conformance")
    let keypair = Wave8KeypairStub()
    let keypairAny: Any = keypair
    mtrRequire(keypairAny is any MTRKeypair, "MTRKeypair conformance")
    mtrRequire(keypair.signMessageECDSA_RAW(Data([0x01])) == Data([0x01]), "MTRKeypair RAW stub echoes")
    mtrRequire(keypair.signMessageECDSA_DER(Data([0x02])) == Data([0x02]), "MTRKeypair DER stub echoes")
}

private final class Wave8NOCIssuerStub: NSObject, MTRNOCChainIssuer {}
private final class Wave8OperationalIssuerStub: NSObject, MTROperationalCertificateIssuer {}
private final class Wave8OTAStub: NSObject, MTROTAProviderDelegate {}
private final class Wave8DeviceDelegateStub: NSObject, MTRDeviceDelegate {
    var seen: [MTRDeviceState] = []
    func device(_ device: MTRDevice, stateChanged state: MTRDeviceState) {
        _ = device
        seen.append(state)
    }
    func device(_ device: MTRDevice, receivedAttributeReport attributeReport: [[String: Any]]) {
        _ = (device, attributeReport)
    }
    func device(_ device: MTRDevice, receivedEventReport eventReport: [[String: Any]]) {
        _ = (device, eventReport)
    }
}

func testWave8IssuerOTADeviceProtocols() {
    let noc: Any = Wave8NOCIssuerStub()
    let issuer: Any = Wave8OperationalIssuerStub()
    let ota: Any = Wave8OTAStub()
    mtrRequire(noc is any MTRNOCChainIssuer, "MTRNOCChainIssuer conformance")
    mtrRequire(issuer is any MTROperationalCertificateIssuer, "MTROperationalCertificateIssuer conformance")
    mtrRequire(ota is any MTROTAProviderDelegate, "MTROTAProviderDelegate conformance")
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(4), controller: controller)
    let deviceDelegate = Wave8DeviceDelegateStub()
    let deviceDelegateAny: Any = deviceDelegate
    mtrRequire(deviceDelegateAny is any MTRDeviceDelegate, "MTRDeviceDelegate conformance")
    let existential: any MTRDeviceDelegate = deviceDelegate
    existential.device(device, stateChanged: .reachable)
    mtrRequire(deviceDelegate.seen == [.reachable], "MTRDeviceDelegate state dispatch reaches stub")
}

private final class Wave8ControllerClientStub: NSObject, MTRDeviceControllerClientProtocol {}
private final class Wave8ControllerServerStub: NSObject, MTRDeviceControllerServerProtocol {}
private final class Wave8XPCDeviceControllerClientStub: NSObject, MTRXPCClientProtocol_MTRDeviceController {}
private final class Wave8XPCDeviceControllerServerStub: NSObject, MTRXPCServerProtocol_MTRDeviceController {}

func testWave8ControllerXPCProtocols() {
    let client: Any = Wave8ControllerClientStub()
    let server: Any = Wave8ControllerServerStub()
    let xpcClient: Any = Wave8XPCDeviceControllerClientStub()
    let xpcServer: Any = Wave8XPCDeviceControllerServerStub()
    mtrRequire(client is any MTRDeviceControllerClientProtocol, "MTRDeviceControllerClientProtocol conformance")
    mtrRequire(server is any MTRDeviceControllerServerProtocol, "MTRDeviceControllerServerProtocol conformance")
    mtrRequire(xpcClient is any MTRXPCClientProtocol_MTRDeviceController, "MTRXPCClientProtocol_MTRDeviceController conformance")
    mtrRequire(xpcServer is any MTRXPCServerProtocol_MTRDeviceController, "MTRXPCServerProtocol_MTRDeviceController conformance")
}

private final class Wave8XPCClientStub: NSObject, MTRXPCClientProtocol {}
private final class Wave8XPCDeviceClientStub: NSObject, MTRXPCClientProtocol_MTRDevice {}
private final class Wave8XPCServerStub: NSObject, MTRXPCServerProtocol {}
private final class Wave8XPCDeviceServerStub: NSObject, MTRXPCServerProtocol_MTRDevice {}

func testWave8DeviceXPCProtocols() {
    let client: Any = Wave8XPCClientStub()
    let deviceClient: Any = Wave8XPCDeviceClientStub()
    let server: Any = Wave8XPCServerStub()
    let deviceServer: Any = Wave8XPCDeviceServerStub()
    mtrRequire(client is any MTRXPCClientProtocol, "MTRXPCClientProtocol conformance")
    mtrRequire(deviceClient is any MTRXPCClientProtocol_MTRDevice, "MTRXPCClientProtocol_MTRDevice conformance")
    mtrRequire(server is any MTRXPCServerProtocol, "MTRXPCServerProtocol conformance")
    mtrRequire(deviceServer is any MTRXPCServerProtocol_MTRDevice, "MTRXPCServerProtocol_MTRDevice conformance")
}
