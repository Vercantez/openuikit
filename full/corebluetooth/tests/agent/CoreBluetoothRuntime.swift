@_spi(OpenUIKitHost) import CoreBluetooth
import CoreFoundation
import Dispatch
import Foundation

private func requireUnsupported(_ error: Error?) {
    guard let error = error as? CBError else {
        fatalError("expected typed CBError, got \(String(describing: error))")
    }
    precondition(error.code == .operationNotSupported)
}

private func nsError(_ error: any Error) -> NSError {
    error as NSError
}

private func rehydrateCBError(from nsError: NSError) -> CBError? {
    guard nsError.domain == CBErrorDomain, let code = CBError.Code(rawValue: nsError.code) else {
        return nil
    }
    return CBError(code, userInfo: nsError.userInfo)
}

private func rehydrateCBATTError(from nsError: NSError) -> CBATTError? {
    guard nsError.domain == CBATTErrorDomain, let code = CBATTError.Code(rawValue: nsError.code) else {
        return nil
    }
    return CBATTError(code, userInfo: nsError.userInfo)
}

private func typedCBError(from error: any Error) -> CBError? {
    if let typed = error as? CBError {
        return typed
    }
    return rehydrateCBError(from: error as NSError)
}

private func typedCBATTError(from error: any Error) -> CBATTError? {
    if let typed = error as? CBATTError {
        return typed
    }
    return rehydrateCBATTError(from: error as NSError)
}

/// Typed-origin `CustomNSError` may remain recoverable with `as?` after
/// `as NSError`, or it may collapse to a plain NSError. Both are accepted;
/// this is not Apple `_BridgedStoredNSError`.
private func assertTypedOriginCBError(_ typed: CBError, key: String, stringValue: String) {
    let bridged = nsError(typed)
    precondition(bridged.domain == CBErrorDomain)
    precondition(bridged.code == typed.errorCode)
    precondition(bridged.userInfo[key] as? String == stringValue)
    if let preserved = bridged as? CBError {
        precondition(preserved.code == typed.code)
        precondition(preserved.userInfo[key] as? String == stringValue)
    } else {
        let rebuilt = rehydrateCBError(from: bridged)
        precondition(rebuilt?.code == typed.code)
        precondition(rebuilt?.userInfo[key] as? String == stringValue)
    }
    precondition(typed.code ~= bridged)
    precondition(typedCBError(from: bridged)?.code == typed.code)
    precondition(typedCBError(from: bridged)?.userInfo[key] as? String == stringValue)
}

private func assertTypedOriginCBATTError(_ typed: CBATTError, key: String, intValue: Int) {
    let bridged = nsError(typed)
    precondition(bridged.domain == CBATTErrorDomain)
    precondition(bridged.code == typed.errorCode)
    precondition(bridged.userInfo[key] as? Int == intValue)
    if let preserved = bridged as? CBATTError {
        precondition(preserved.code == typed.code)
        precondition(preserved.userInfo[key] as? Int == intValue)
    } else {
        let rebuilt = rehydrateCBATTError(from: bridged)
        precondition(rebuilt?.code == typed.code)
        precondition(rebuilt?.userInfo[key] as? Int == intValue)
    }
    precondition(typed.code ~= bridged)
    precondition(typedCBATTError(from: bridged)?.code == typed.code)
}

private final class CentralStateProbe: NSObject, CBCentralManagerDelegate {
    let queue: DispatchQueue
    let queueKey: DispatchSpecificKey<String>
    let queueToken: String
    let lock = NSLock()
    var count = 0
    var states: [CBManagerState] = []
    var inlineDuringInit = false
    var initReturned = false
    var disconnectCount = 0
    var failCount = 0
    var failInline = false
    var connectReturned = false
    let stateSemaphore = DispatchSemaphore(value: 0)
    let failSemaphore = DispatchSemaphore(value: 0)

    init(queue: DispatchQueue, key: DispatchSpecificKey<String>, token: String) {
        self.queue = queue
        self.queueKey = key
        self.queueToken = token
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        precondition(DispatchQueue.getSpecific(key: queueKey) == queueToken)
        lock.lock()
        if !initReturned {
            inlineDuringInit = true
        }
        count += 1
        states.append(central.state)
        lock.unlock()
        stateSemaphore.signal()
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        _ = (central, peripheral)
        requireUnsupported(error)
        precondition(DispatchQueue.getSpecific(key: queueKey) == queueToken)
        lock.lock()
        if !connectReturned {
            failInline = true
        }
        failCount += 1
        lock.unlock()
        failSemaphore.signal()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        _ = (central, peripheral, error)
        lock.lock()
        disconnectCount += 1
        lock.unlock()
        stateSemaphore.signal()
    }
}

private final class PeripheralStateProbe: NSObject, CBPeripheralManagerDelegate {
    let queue: DispatchQueue
    let queueKey: DispatchSpecificKey<String>
    let queueToken: String
    let lock = NSLock()
    var count = 0
    var initReturned = false
    var inlineDuringInit = false
    let stateSemaphore = DispatchSemaphore(value: 0)
    let advertisingSemaphore = DispatchSemaphore(value: 0)
    let addSemaphore = DispatchSemaphore(value: 0)
    var advertisingError: (any Error)?
    var addError: (any Error)?

    init(queue: DispatchQueue, key: DispatchSpecificKey<String>, token: String) {
        self.queue = queue
        self.queueKey = key
        self.queueToken = token
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        _ = peripheral
        precondition(DispatchQueue.getSpecific(key: queueKey) == queueToken)
        lock.lock()
        if !initReturned {
            inlineDuringInit = true
        }
        count += 1
        lock.unlock()
        stateSemaphore.signal()
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
        _ = peripheral
        precondition(DispatchQueue.getSpecific(key: queueKey) == queueToken)
        lock.lock()
        advertisingError = error
        lock.unlock()
        advertisingSemaphore.signal()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: (any Error)?
    ) {
        _ = (peripheral, service)
        precondition(DispatchQueue.getSpecific(key: queueKey) == queueToken)
        lock.lock()
        addError = error
        lock.unlock()
        addSemaphore.signal()
    }
}

private func drain(_ queue: DispatchQueue) {
    queue.sync {}
}


private final class SimulatedCentralProbe: NSObject, CBCentralManagerDelegate {
    let queueKey: DispatchSpecificKey<String>
    let queueToken: String
    let lock = NSLock()
    var states: [CBManagerState] = []
    var restored: [[String: Any]] = []
    var discoveries: [(CBPeripheral, [String: Any], NSNumber)] = []
    var connected: [CBPeripheral] = []
    var failed: [(CBPeripheral, (any Error)?)] = []
    var disconnected: [(CBPeripheral, (any Error)?)] = []
    var disconnectedTimed: Int = 0
    var connectionEvents: [CBConnectionEvent] = []
    var ancs: [CBPeripheral] = []
    var initReturned = false
    var inlineDuringInit = false
    let stateSemaphore = DispatchSemaphore(value: 0)
    let discoverSemaphore = DispatchSemaphore(value: 0)
    let connectSemaphore = DispatchSemaphore(value: 0)
    let failSemaphore = DispatchSemaphore(value: 0)
    let disconnectSemaphore = DispatchSemaphore(value: 0)

    init(key: DispatchSpecificKey<String>, token: String) {
        self.queueKey = key
        self.queueToken = token
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        precondition(DispatchQueue.getSpecific(key: queueKey) == queueToken)
        lock.lock()
        if !initReturned { inlineDuringInit = true }
        states.append(central.state)
        lock.unlock()
        stateSemaphore.signal()
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        _ = central
        lock.lock()
        restored.append(dict)
        lock.unlock()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        _ = central
        lock.lock()
        discoveries.append((peripheral, advertisementData, RSSI))
        lock.unlock()
        discoverSemaphore.signal()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        lock.lock()
        connected.append(peripheral)
        lock.unlock()
        connectSemaphore.signal()
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        lock.lock()
        failed.append((peripheral, error))
        lock.unlock()
        failSemaphore.signal()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        lock.lock()
        disconnected.append((peripheral, error))
        lock.unlock()
        disconnectSemaphore.signal()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: (any Error)?
    ) {
        _ = (peripheral, timestamp, isReconnecting, error)
        lock.lock()
        disconnectedTimed += 1
        lock.unlock()
    }

    func centralManager(
        _ central: CBCentralManager,
        connectionEventDidOccur event: CBConnectionEvent,
        for peripheral: CBPeripheral
    ) {
        _ = peripheral
        lock.lock()
        connectionEvents.append(event)
        lock.unlock()
    }

    func centralManager(
        _ central: CBCentralManager,
        didUpdateANCSAuthorizationFor peripheral: CBPeripheral
    ) {
        lock.lock()
        ancs.append(peripheral)
        lock.unlock()
    }
}

private final class SimulatedPeripheralProbe: NSObject, CBPeripheralDelegate {
    let lock = NSLock()
    var discoverServices: Int = 0
    var discoverIncluded: Int = 0
    var discoverChars: Int = 0
    var discoverDescs: Int = 0
    var updates: [Data?] = []
    var writes: Int = 0
    var notifyStates: [Bool] = []
    var descriptorUpdates: Int = 0
    var descriptorWrites: Int = 0
    var rssiReads: [NSNumber] = []
    var rssiLegacy: Int = 0
    var names: Int = 0
    var modified: Int = 0
    var readyWithoutResponse: Int = 0
    var l2capErrors: Int = 0
    let serviceSemaphore = DispatchSemaphore(value: 0)
    let includedSemaphore = DispatchSemaphore(value: 0)
    let charSemaphore = DispatchSemaphore(value: 0)
    let descSemaphore = DispatchSemaphore(value: 0)
    let valueSemaphore = DispatchSemaphore(value: 0)
    let writeSemaphore = DispatchSemaphore(value: 0)
    let notifySemaphore = DispatchSemaphore(value: 0)
    let rssiSemaphore = DispatchSemaphore(value: 0)
    let nameSemaphore = DispatchSemaphore(value: 0)
    let readySemaphore = DispatchSemaphore(value: 0)
    let l2capSemaphore = DispatchSemaphore(value: 0)
    let modifySemaphore = DispatchSemaphore(value: 0)

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        _ = (peripheral, error)
        lock.lock()
        discoverServices += 1
        lock.unlock()
        serviceSemaphore.signal()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: (any Error)?
    ) {
        _ = (peripheral, service, error)
        lock.lock()
        discoverIncluded += 1
        lock.unlock()
        includedSemaphore.signal()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: (any Error)?
    ) {
        _ = (peripheral, service, error)
        lock.lock()
        discoverChars += 1
        lock.unlock()
        charSemaphore.signal()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        _ = (peripheral, characteristic, error)
        lock.lock()
        discoverDescs += 1
        lock.unlock()
        descSemaphore.signal()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        _ = (peripheral, error)
        lock.lock()
        updates.append(characteristic.value)
        lock.unlock()
        valueSemaphore.signal()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        _ = (peripheral, characteristic, error)
        lock.lock()
        writes += 1
        lock.unlock()
        writeSemaphore.signal()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        _ = (peripheral, error)
        lock.lock()
        notifyStates.append(characteristic.isNotifying)
        lock.unlock()
        notifySemaphore.signal()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: (any Error)?
    ) {
        _ = (peripheral, descriptor, error)
        lock.lock()
        descriptorUpdates += 1
        lock.unlock()
        valueSemaphore.signal()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor descriptor: CBDescriptor,
        error: (any Error)?
    ) {
        _ = (peripheral, descriptor, error)
        lock.lock()
        descriptorWrites += 1
        lock.unlock()
        writeSemaphore.signal()
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?) {
        _ = (peripheral, error)
        lock.lock()
        rssiReads.append(RSSI)
        lock.unlock()
        rssiSemaphore.signal()
    }

    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: (any Error)?) {
        _ = (peripheral, error)
        lock.lock()
        rssiLegacy += 1
        lock.unlock()
    }

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        _ = peripheral
        lock.lock()
        names += 1
        lock.unlock()
        nameSemaphore.signal()
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        _ = (peripheral, invalidatedServices)
        lock.lock()
        modified += 1
        lock.unlock()
        modifySemaphore.signal()
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        _ = peripheral
        lock.lock()
        readyWithoutResponse += 1
        lock.unlock()
        readySemaphore.signal()
    }

    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: (any Error)?) {
        _ = channel
        requireUnsupported(error)
        lock.lock()
        l2capErrors += 1
        lock.unlock()
        l2capSemaphore.signal()
    }
}

private final class SimulatedManagerProbe: NSObject, CBPeripheralManagerDelegate {
    let lock = NSLock()
    var stateCount = 0
    var restored: [[String: Any]] = []
    var advertisingError: (any Error)?
    var didStartAdvertising = false
    var added: [(CBService, (any Error)?)] = []
    var subscribed: Int = 0
    var unsubscribed: Int = 0
    var reads: [CBATTRequest] = []
    var writes: [[CBATTRequest]] = []
    var ready = 0
    var l2capPublish = 0
    var l2capUnpublish = 0
    var l2capOpen = 0
    var initReturned = false
    var inlineDuringInit = false
    let stateSemaphore = DispatchSemaphore(value: 0)
    let advertisingSemaphore = DispatchSemaphore(value: 0)
    let addSemaphore = DispatchSemaphore(value: 0)
    let subscribeSemaphore = DispatchSemaphore(value: 0)
    let readSemaphore = DispatchSemaphore(value: 0)
    let writeSemaphore = DispatchSemaphore(value: 0)
    let readySemaphore = DispatchSemaphore(value: 0)
    let l2capSemaphore = DispatchSemaphore(value: 0)

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        _ = peripheral
        lock.lock()
        if !initReturned { inlineDuringInit = true }
        stateCount += 1
        lock.unlock()
        stateSemaphore.signal()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        _ = peripheral
        lock.lock()
        restored.append(dict)
        lock.unlock()
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
        _ = peripheral
        lock.lock()
        advertisingError = error
        didStartAdvertising = true
        lock.unlock()
        advertisingSemaphore.signal()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: (any Error)?
    ) {
        lock.lock()
        added.append((service, error))
        lock.unlock()
        addSemaphore.signal()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        _ = (central, characteristic)
        lock.lock()
        subscribed += 1
        lock.unlock()
        subscribeSemaphore.signal()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        _ = (central, characteristic)
        lock.lock()
        unsubscribed += 1
        lock.unlock()
        subscribeSemaphore.signal()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        _ = peripheral
        lock.lock()
        reads.append(request)
        lock.unlock()
        readSemaphore.signal()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        _ = peripheral
        lock.lock()
        writes.append(requests)
        lock.unlock()
        writeSemaphore.signal()
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        _ = peripheral
        lock.lock()
        ready += 1
        lock.unlock()
        readySemaphore.signal()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didPublishL2CAPChannel PSM: CBL2CAPPSM,
        error: (any Error)?
    ) {
        _ = PSM
        requireUnsupported(error)
        lock.lock()
        l2capPublish += 1
        lock.unlock()
        l2capSemaphore.signal()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didUnpublishL2CAPChannel PSM: CBL2CAPPSM,
        error: (any Error)?
    ) {
        _ = PSM
        requireUnsupported(error)
        lock.lock()
        l2capUnpublish += 1
        lock.unlock()
        l2capSemaphore.signal()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didOpen channel: CBL2CAPChannel?,
        error: (any Error)?
    ) {
        _ = (channel, error)
        lock.lock()
        l2capOpen += 1
        lock.unlock()
        l2capSemaphore.signal()
    }
}

private func makeSimulatedFixture() -> (CBHostSimulatedAdapter, UUID, CBUUID, CBUUID) {
    let battery = CBUUID(string: "180F")
    let level = CBUUID(string: "2A19")
    let overflow = CBUUID(string: "180A")
    let solicited = CBUUID(string: "1800")
    let identifier = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    let descriptor = CBHostSimulatedDescriptor(
        uuid: CBUUID(string: CBUUIDClientCharacteristicConfigurationString),
        value: Data([0x00, 0x00])
    )
    let characteristic = CBHostSimulatedCharacteristic(
        uuid: level,
        properties: [.read, .write, .writeWithoutResponse, .notify],
        value: Data([0x64]),
        descriptors: [descriptor],
        notifyPayload: Data([0x63])
    )
    let included = CBHostSimulatedService(
        uuid: CBUUID(string: "1800"),
        isPrimary: false
    )
    let service = CBHostSimulatedService(
        uuid: battery,
        isPrimary: true,
        characteristics: [characteristic],
        includedServices: [included]
    )
    let advertisement = CBHostSimulatedPeripheral.advertisementDictionary(
        localName: "sim-battery",
        manufacturerData: Data([0xFF, 0xFF, 0x01]),
        serviceUUID: battery,
        serviceData: Data([0x64]),
        overflowUUID: overflow,
        solicitedUUID: solicited,
        txPower: -42,
        isConnectable: true
    )
    let peripheral = CBHostSimulatedPeripheral(
        identifier: identifier,
        name: "sim-battery",
        rssi: NSNumber(value: -55),
        advertisementData: advertisement,
        services: [service],
        connectable: true,
        ancsAuthorized: true
    )
    let adapter = CBHostSimulatedAdapter(
        state: .poweredOn,
        peripherals: [peripheral],
        restoredCentralState: [
            CBCentralManagerRestoredStatePeripheralsKey: [CBPeripheral](),
            CBCentralManagerRestoredStateScanServicesKey: [battery],
            CBCentralManagerRestoredStateScanOptionsKey: [String: Any](),
        ],
        restoredPeripheralState: [
            CBPeripheralManagerRestoredStateServicesKey: [CBMutableService](),
            CBPeripheralManagerRestoredStateAdvertisementDataKey: [String: Any](),
        ]
    )
    return (adapter, identifier, battery, level)
}

private func assertAdvertisementKeys(_ advertisement: [String: Any]) {
    let keys = [
        CBAdvertisementDataLocalNameKey,
        CBAdvertisementDataManufacturerDataKey,
        CBAdvertisementDataServiceDataKey,
        CBAdvertisementDataServiceUUIDsKey,
        CBAdvertisementDataOverflowServiceUUIDsKey,
        CBAdvertisementDataTxPowerLevelKey,
        CBAdvertisementDataIsConnectable,
        CBAdvertisementDataSolicitedServiceUUIDsKey,
    ]
    for key in keys {
        precondition(advertisement[key] != nil, "missing advertisement key \(key)")
    }
    precondition(advertisement[CBAdvertisementDataLocalNameKey] as? String == "sim-battery")
    precondition(advertisement[CBAdvertisementDataIsConnectable] as? NSNumber == true)
}

private func withSimulatedAdapter(
    _ body: (
        CBHostSimulatedAdapter,
        UUID,
        CBUUID,
        CBUUID,
        DispatchQueue,
        DispatchSpecificKey<String>
    ) -> Void
) {
    let (adapter, identifier, battery, level) = makeSimulatedFixture()
    CBHostSimulation.install(adapter)
    defer { CBHostSimulation.remove() }
    let queueKey = DispatchSpecificKey<String>()
    let queue = DispatchQueue(label: "corebluetooth.tests.simulated")
    queue.setSpecific(key: queueKey, value: "sim-token")
    body(adapter, identifier, battery, level, queue, queueKey)
}

private func poweredOnCentral(
    queue: DispatchQueue,
    queueKey: DispatchSpecificKey<String>
) -> (CBCentralManager, SimulatedCentralProbe) {
    let probe = SimulatedCentralProbe(key: queueKey, token: "sim-token")
    let manager = CBCentralManager(
        delegate: probe,
        queue: queue,
        options: [
            CBCentralManagerOptionRestoreIdentifierKey: "linux-sim",
            CBCentralManagerOptionShowPowerAlertKey: false,
            CBCentralManagerOptionDeviceAccessForMedia: false,
        ]
    )
    probe.lock.lock()
    probe.initReturned = true
    probe.lock.unlock()
    precondition(probe.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    drain(queue)
    return (manager, probe)
}

// MARK: - CoreBluetoothConstantsTests.swift
func testAdvertisementDataKeys() {
    let keys: [(String, String)] = [
        (CBAdvertisementDataLocalNameKey, "CBAdvertisementDataLocalNameKey"),
        (CBAdvertisementDataManufacturerDataKey, "CBAdvertisementDataManufacturerDataKey"),
        (CBAdvertisementDataServiceDataKey, "CBAdvertisementDataServiceDataKey"),
        (CBAdvertisementDataServiceUUIDsKey, "CBAdvertisementDataServiceUUIDsKey"),
        (CBAdvertisementDataOverflowServiceUUIDsKey, "CBAdvertisementDataOverflowServiceUUIDsKey"),
        (CBAdvertisementDataTxPowerLevelKey, "CBAdvertisementDataTxPowerLevelKey"),
        (CBAdvertisementDataIsConnectable, "CBAdvertisementDataIsConnectable"),
        (CBAdvertisementDataSolicitedServiceUUIDsKey, "CBAdvertisementDataSolicitedServiceUUIDsKey"),
    ]
    for (value, expected) in keys {
        precondition(value == expected)
        precondition(!value.isEmpty)
    }
}

func testCentralManagerOptionKeys() {
    let keys: [String] = [
        CBCentralManagerOptionShowPowerAlertKey,
        CBCentralManagerOptionRestoreIdentifierKey,
        CBCentralManagerOptionDeviceAccessForMedia,
        CBCentralManagerScanOptionAllowDuplicatesKey,
        CBCentralManagerScanOptionSolicitedServiceUUIDsKey,
        CBCentralManagerRestoredStatePeripheralsKey,
        CBCentralManagerRestoredStateScanServicesKey,
        CBCentralManagerRestoredStateScanOptionsKey,
    ]
    for key in keys {
        precondition(!key.isEmpty)
        precondition(key.hasPrefix("CB"))
    }
}

func testConnectPeripheralOptionKeys() {
    let keys: [String] = [
        CBConnectPeripheralOptionNotifyOnConnectionKey,
        CBConnectPeripheralOptionNotifyOnDisconnectionKey,
        CBConnectPeripheralOptionNotifyOnNotificationKey,
        CBConnectPeripheralOptionStartDelayKey,
        CBConnectPeripheralOptionEnableTransportBridgingKey,
        CBConnectPeripheralOptionRequiresANCS,
        CBConnectPeripheralOptionEnableAutoReconnect,
    ]
    for key in keys {
        precondition(!key.isEmpty)
        precondition(key.hasPrefix("CBConnectPeripheralOption"))
    }
}

func testPeripheralManagerOptionKeys() {
    let keys: [String] = [
        CBPeripheralManagerOptionShowPowerAlertKey,
        CBPeripheralManagerOptionRestoreIdentifierKey,
        CBPeripheralManagerRestoredStateServicesKey,
        CBPeripheralManagerRestoredStateAdvertisementDataKey,
    ]
    for key in keys {
        precondition(!key.isEmpty)
        precondition(key.hasPrefix("CBPeripheralManager"))
    }
}

func testCBUUIDCharacteristicStrings() {
    precondition(CBUUIDCharacteristicExtendedPropertiesString == "2900")
    precondition(CBUUIDCharacteristicUserDescriptionString == "2901")
    precondition(CBUUIDClientCharacteristicConfigurationString == "2902")
    precondition(CBUUIDServerCharacteristicConfigurationString == "2903")
    precondition(CBUUIDCharacteristicFormatString == "2904")
    precondition(CBUUIDCharacteristicAggregateFormatString == "2905")
    precondition(CBUUIDCharacteristicValidRangeString == "2906")
    precondition(CBUUIDL2CAPPSMCharacteristicString == "ABDD3056-28FA-441D-A470-55A75A52553A")
    precondition(!CBUUIDCharacteristicObservationScheduleString.isEmpty)
}

func testErrorDomainConstants() {
    precondition(CBErrorDomain == "CBErrorDomain")
    precondition(CBATTErrorDomain == "CBATTErrorDomain")
}

func testCBL2CAPPSMAlias() {
    let psm: CBL2CAPPSM = 0x0080
    precondition(psm == 128)
    let typed: UInt16 = psm
    precondition(typed == 128)
}

func testConnectionEventMatchingOptionValues() {
    let supplied = CBConnectionEventMatchingOption(rawValue: "host-supplied")
    precondition(supplied.rawValue == "host-supplied")
    precondition(
        CBConnectionEventMatchingOption.peripheralUUIDs
            != CBConnectionEventMatchingOption.serviceUUIDs
    )
    precondition(!CBConnectionEventMatchingOption.peripheralUUIDs.rawValue.isEmpty)
    precondition(!CBConnectionEventMatchingOption.serviceUUIDs.rawValue.isEmpty)
    _ = supplied.hashValue
    var hasher = Hasher()
    supplied.hash(into: &hasher)
    CBConnectionEventMatchingOption.peripheralUUIDs.hash(into: &hasher)
    _ = hasher.finalize()
}

// MARK: - CoreBluetoothErrorTests.swift
func testCBErrorCodes() {
    let cases: [(CBError.Code, Int)] = [
        (.unknown, 0),
        (.invalidParameters, 1),
        (.invalidHandle, 2),
        (.notConnected, 3),
        (.outOfSpace, 4),
        (.operationCancelled, 5),
        (.connectionTimeout, 6),
        (.peripheralDisconnected, 7),
        (.uuidNotAllowed, 8),
        (.alreadyAdvertising, 9),
        (.connectionFailed, 10),
        (.connectionLimitReached, 11),
        (.unkownDevice, 12),
        (.operationNotSupported, 13),
        (.peerRemovedPairingInformation, 14),
        (.encryptionTimedOut, 15),
        (.tooManyLEPairedDevices, 16),
    ]
    for (code, raw) in cases {
        precondition(code.rawValue == raw)
        precondition(CBError.Code(rawValue: raw) == code)
        _ = code.hashValue
        var hasher = Hasher()
        code.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBError.Code(rawValue: 99) == nil)
    precondition(CBError.Code.unknownDevice == .unkownDevice)
    precondition(CBError.unknown == .unknown)
    precondition(CBError.invalidParameters == .invalidParameters)
    precondition(CBError.invalidHandle == .invalidHandle)
    precondition(CBError.notConnected == .notConnected)
    precondition(CBError.outOfSpace == .outOfSpace)
    precondition(CBError.operationCancelled == .operationCancelled)
    precondition(CBError.connectionTimeout == .connectionTimeout)
    precondition(CBError.peripheralDisconnected == .peripheralDisconnected)
    precondition(CBError.uuidNotAllowed == .uuidNotAllowed)
    precondition(CBError.alreadyAdvertising == .alreadyAdvertising)
    precondition(CBError.connectionFailed == .connectionFailed)
    precondition(CBError.connectionLimitReached == .connectionLimitReached)
    precondition(CBError.unkownDevice == .unkownDevice)
    precondition(CBError.unknownDevice == .unkownDevice)
    precondition(CBError.operationNotSupported == .operationNotSupported)
    precondition(CBError.peerRemovedPairingInformation == .peerRemovedPairingInformation)
    precondition(CBError.encryptionTimedOut == .encryptionTimedOut)
    precondition(CBError.tooManyLEPairedDevices == .tooManyLEPairedDevices)
}

func testCBErrorOverlay() {
    let typed = CBError(.notConnected, userInfo: ["reason": "linux"])
    precondition(typed.code == .notConnected)
    precondition(typed.errorCode == 3)
    precondition(typed.userInfo["reason"] as? String == "linux")
    precondition(typed.errorUserInfo["reason"] as? String == "linux")
    precondition(CBError.errorDomain == CBErrorDomain)
    precondition(!typed.userInfo.keys.contains(NSLocalizedDescriptionKey))
    precondition(typed == CBError(.notConnected, userInfo: ["reason": "linux"]))
    precondition(typed != CBError(.unknown))
    precondition(
        CBError(.notConnected, userInfo: ["x": 1])
            != CBError(.notConnected, userInfo: ["x": "1"])
    )
    precondition(typed.hashValue == CBError(.notConnected, userInfo: ["other": 1]).hashValue)
    precondition(CBError.notConnected ~= typed)
    precondition(!(CBError.unknown ~= typed))
    assertTypedOriginCBError(typed, key: "reason", stringValue: "linux")
    let fresh = NSError(domain: CBErrorDomain, code: CBError.notConnected.rawValue, userInfo: ["k": "v"])
    precondition((fresh as? CBError) == nil)
    precondition(CBError.notConnected ~= fresh)
    let freshRebuilt = rehydrateCBError(from: fresh)
    precondition(freshRebuilt?.code == .notConnected)
    precondition(freshRebuilt?.userInfo["k"] as? String == "v")
    var hasher = Hasher()
    typed.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(!typed.localizedDescription.isEmpty)
}

func testCBATTErrorCodes() {
    let cases: [(CBATTError.Code, Int)] = [
        (.success, 0x00),
        (.invalidHandle, 0x01),
        (.readNotPermitted, 0x02),
        (.writeNotPermitted, 0x03),
        (.invalidPdu, 0x04),
        (.insufficientAuthentication, 0x05),
        (.requestNotSupported, 0x06),
        (.invalidOffset, 0x07),
        (.insufficientAuthorization, 0x08),
        (.prepareQueueFull, 0x09),
        (.attributeNotFound, 0x0A),
        (.attributeNotLong, 0x0B),
        (.insufficientEncryptionKeySize, 0x0C),
        (.invalidAttributeValueLength, 0x0D),
        (.unlikelyError, 0x0E),
        (.insufficientEncryption, 0x0F),
        (.unsupportedGroupType, 0x10),
        (.insufficientResources, 0x11),
    ]
    for (code, raw) in cases {
        precondition(code.rawValue == raw)
        precondition(CBATTError.Code(rawValue: raw) == code)
        _ = code.hashValue
        var hasher = Hasher()
        code.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBATTError.Code(rawValue: 99) == nil)
    precondition(CBATTError.success == .success)
    precondition(CBATTError.invalidHandle == .invalidHandle)
    precondition(CBATTError.readNotPermitted == .readNotPermitted)
    precondition(CBATTError.writeNotPermitted == .writeNotPermitted)
    precondition(CBATTError.invalidPdu == .invalidPdu)
    precondition(CBATTError.insufficientAuthentication == .insufficientAuthentication)
    precondition(CBATTError.requestNotSupported == .requestNotSupported)
    precondition(CBATTError.invalidOffset == .invalidOffset)
    precondition(CBATTError.insufficientAuthorization == .insufficientAuthorization)
    precondition(CBATTError.prepareQueueFull == .prepareQueueFull)
    precondition(CBATTError.attributeNotFound == .attributeNotFound)
    precondition(CBATTError.attributeNotLong == .attributeNotLong)
    precondition(CBATTError.insufficientEncryptionKeySize == .insufficientEncryptionKeySize)
    precondition(CBATTError.invalidAttributeValueLength == .invalidAttributeValueLength)
    precondition(CBATTError.unlikelyError == .unlikelyError)
    precondition(CBATTError.insufficientEncryption == .insufficientEncryption)
    precondition(CBATTError.unsupportedGroupType == .unsupportedGroupType)
    precondition(CBATTError.insufficientResources == .insufficientResources)
}

func testCBATTErrorOverlay() {
    let att = CBATTError(.readNotPermitted, userInfo: ["att": 2])
    precondition(att.code == .readNotPermitted)
    precondition(att.errorCode == 2)
    precondition(att.userInfo["att"] as? Int == 2)
    precondition(att.errorUserInfo["att"] as? Int == 2)
    precondition(CBATTError.errorDomain == CBATTErrorDomain)
    precondition(CBATTError.readNotPermitted ~= att)
    precondition(att == CBATTError(.readNotPermitted, userInfo: ["att": 2]))
    precondition(att != CBATTError(.success))
    precondition(att.hashValue == CBATTError(.readNotPermitted, userInfo: ["other": 1]).hashValue)
    assertTypedOriginCBATTError(att, key: "att", intValue: 2)
    let freshATT = NSError(
        domain: CBATTErrorDomain,
        code: CBATTError.readNotPermitted.rawValue,
        userInfo: ["att": 2]
    )
    precondition((freshATT as? CBATTError) == nil)
    precondition(CBATTError.readNotPermitted ~= freshATT)
    precondition(rehydrateCBATTError(from: freshATT)?.code == .readNotPermitted)
    var hasher = Hasher()
    att.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(!att.localizedDescription.isEmpty)
}

// MARK: - CoreBluetoothEnumTests.swift
func testCBManagerStateCases() {
    let cases: [(CBManagerState, Int)] = [
        (.unknown, 0),
        (.resetting, 1),
        (.unsupported, 2),
        (.unauthorized, 3),
        (.poweredOff, 4),
        (.poweredOn, 5),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBManagerState(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBManagerState.unknown != .poweredOn)
    precondition(CBManagerState(rawValue: 99) == nil)
}

func testCBCentralManagerStateCases() {
    let cases: [(CBCentralManagerState, Int)] = [
        (.unknown, 0),
        (.resetting, 1),
        (.unsupported, 2),
        (.unauthorized, 3),
        (.poweredOff, 4),
        (.poweredOn, 5),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBCentralManagerState(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBCentralManagerState.unknown != .poweredOn)
}

func testCBPeripheralManagerStateCases() {
    let cases: [(CBPeripheralManagerState, Int)] = [
        (.unknown, 0),
        (.resetting, 1),
        (.unsupported, 2),
        (.unauthorized, 3),
        (.poweredOff, 4),
        (.poweredOn, 5),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBPeripheralManagerState(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBPeripheralManagerState.unknown != .poweredOn)
}

func testCBManagerAuthorizationCases() {
    let cases: [(CBManagerAuthorization, Int)] = [
        (.notDetermined, 0),
        (.restricted, 1),
        (.denied, 2),
        (.allowedAlways, 3),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBManagerAuthorization(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBManagerAuthorization.denied != .allowedAlways)
}

func testCBPeripheralManagerAuthorizationStatusCases() {
    let cases: [(CBPeripheralManagerAuthorizationStatus, Int)] = [
        (.notDetermined, 0),
        (.restricted, 1),
        (.denied, 2),
        (.authorized, 3),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBPeripheralManagerAuthorizationStatus(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBPeripheralManagerAuthorizationStatus.denied != .authorized)
}

func testCBPeripheralStateCases() {
    let cases: [(CBPeripheralState, Int)] = [
        (.disconnected, 0),
        (.connecting, 1),
        (.connected, 2),
        (.disconnecting, 3),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBPeripheralState(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBPeripheralState.disconnected != .connected)
}

func testCBCharacteristicWriteTypeCases() {
    let cases: [(CBCharacteristicWriteType, Int)] = [
        (.withResponse, 0),
        (.withoutResponse, 1),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBCharacteristicWriteType(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBCharacteristicWriteType.withResponse != .withoutResponse)
}

func testCBPeripheralManagerConnectionLatencyCases() {
    let cases: [(CBPeripheralManagerConnectionLatency, Int)] = [
        (.low, 0),
        (.medium, 1),
        (.high, 2),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBPeripheralManagerConnectionLatency(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBPeripheralManagerConnectionLatency.low != .high)
}

func testCBConnectionEventCases() {
    let cases: [(CBConnectionEvent, Int)] = [
        (.peerDisconnected, 0),
        (.peerConnected, 1),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBConnectionEvent(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBConnectionEvent.peerConnected != .peerDisconnected)
}

// MARK: - CoreBluetoothOptionSetTests.swift
func testCBCharacteristicPropertiesMembers() {
    let members: [(CBCharacteristicProperties, UInt)] = [
        (.broadcast, 1 << 0),
        (.read, 1 << 1),
        (.writeWithoutResponse, 1 << 2),
        (.write, 1 << 3),
        (.notify, 1 << 4),
        (.indicate, 1 << 5),
        (.authenticatedSignedWrites, 1 << 6),
        (.extendedProperties, 1 << 7),
        (.notifyEncryptionRequired, 1 << 8),
        (.indicateEncryptionRequired, 1 << 9),
    ]
    for (member, raw) in members {
        precondition(member.rawValue == raw)
        precondition(CBCharacteristicProperties(rawValue: raw) == member)
    }
    precondition(CBCharacteristicProperties.read != .write)
    precondition(CBCharacteristicProperties.authenticatedSignedWrites.rawValue == 0x40)
}

func testCBCharacteristicPropertiesAlgebra() {
    var properties: CBCharacteristicProperties = [.read, .notify]
    precondition(properties.contains(.read))
    properties.insert(.write)
    _ = properties.remove(.notify)
    _ = properties.update(with: .indicate)
    let unioned = CBCharacteristicProperties.read.union(.write)
    precondition(unioned.intersection(.read) == .read)
    precondition(unioned.subtracting(.write) == .read)
    precondition(unioned.isSuperset(of: .read))
    precondition(CBCharacteristicProperties.read.isSubset(of: unioned))
    precondition(CBCharacteristicProperties.read.isDisjoint(with: .write))
    precondition(unioned.symmetricDifference(.read) == .write)
    var mutable = CBCharacteristicProperties.read
    mutable.formUnion(.write)
    mutable.formIntersection(.write)
    mutable.formSymmetricDifference(.notify)
    mutable.subtract(.notify)
    _ = CBCharacteristicProperties([.read, .write])
    _ = CBCharacteristicProperties()
    _ = CBCharacteristicProperties(arrayLiteral: .broadcast, .extendedProperties)
    precondition(CBCharacteristicProperties.read.isStrictSubset(of: [.read, .write]))
    precondition(CBCharacteristicProperties([.read, .write]).isStrictSuperset(of: .read))
    precondition(CBCharacteristicProperties().isEmpty)
    precondition(!CBCharacteristicProperties.read.isEmpty)
}

func testCBAttributePermissionsMembers() {
    let members: [(CBAttributePermissions, UInt)] = [
        (.readable, 1 << 0),
        (.writeable, 1 << 1),
        (.readEncryptionRequired, 1 << 2),
        (.writeEncryptionRequired, 1 << 3),
    ]
    for (member, raw) in members {
        precondition(member.rawValue == raw)
        precondition(CBAttributePermissions(rawValue: raw) == member)
    }
    precondition(CBAttributePermissions.readable != .writeable)
}

func testCBAttributePermissionsAlgebra() {
    var permissions: CBAttributePermissions = [.readable]
    permissions.insert(.writeable)
    _ = permissions.union(.readEncryptionRequired)
    _ = permissions.intersection(.readable)
    _ = permissions.subtracting(.writeable)
    _ = permissions.symmetricDifference(.readable)
    _ = permissions.isSubset(of: [.readable, .writeable])
    _ = permissions.isSuperset(of: .readable)
    _ = permissions.isDisjoint(with: .writeEncryptionRequired)
    _ = permissions.contains(.readable)
    _ = permissions.isEmpty
    _ = CBAttributePermissions()
    _ = CBAttributePermissions(arrayLiteral: .readable)
    _ = CBAttributePermissions([.readable, .writeable])
    var permMut = CBAttributePermissions.readable
    permMut.formUnion(.writeable)
    permMut.formIntersection(.writeable)
    permMut.formSymmetricDifference(.readable)
    permMut.subtract(.readable)
    _ = permMut.remove(.writeable)
    _ = permMut.update(with: .readable)
    precondition(CBAttributePermissions.readable.isStrictSubset(of: [.readable, .writeable]))
    precondition(CBAttributePermissions([.readable, .writeable]).isStrictSuperset(of: .readable))
}

func testCBCentralManagerFeatureMembers() {
    precondition(CBCentralManager.Feature.extendedScanAndConnect.rawValue != 0)
    precondition(
        CBCentralManager.Feature(rawValue: CBCentralManager.Feature.extendedScanAndConnect.rawValue)
            == .extendedScanAndConnect
    )
    precondition(CBCentralManager.Feature() != .extendedScanAndConnect)
}

func testCBCentralManagerFeatureAlgebra() {
    var feature = CBCentralManager.Feature()
    feature.insert(.extendedScanAndConnect)
    precondition(feature.contains(.extendedScanAndConnect))
    _ = feature.union(.extendedScanAndConnect)
    _ = feature.intersection(.extendedScanAndConnect)
    _ = feature.subtracting(.extendedScanAndConnect)
    _ = feature.symmetricDifference(.extendedScanAndConnect)
    _ = feature.isSubset(of: .extendedScanAndConnect)
    _ = feature.isSuperset(of: [])
    _ = feature.isDisjoint(with: [])
    _ = feature.isEmpty
    _ = CBCentralManager.Feature(arrayLiteral: .extendedScanAndConnect)
    _ = CBCentralManager.Feature([.extendedScanAndConnect])
    var featMut = CBCentralManager.Feature.extendedScanAndConnect
    featMut.formUnion([])
    featMut.formIntersection(.extendedScanAndConnect)
    featMut.formSymmetricDifference([])
    featMut.subtract([])
    _ = featMut.remove(.extendedScanAndConnect)
    _ = featMut.update(with: .extendedScanAndConnect)
    precondition(CBCentralManager.Feature().isEmpty)
    precondition(CBCentralManager.Feature().isStrictSubset(of: .extendedScanAndConnect))
    precondition(CBCentralManager.Feature.extendedScanAndConnect.isStrictSuperset(of: []))
}

// MARK: - CoreBluetoothUUIDTests.swift
func testCBUUIDStringAndData() {
    let short = CBUUID(string: "180A")
    precondition(short.uuidString == "180A")
    precondition(short.data == Data([0x18, 0x0A]))
    precondition(CBUUID(data: short.data).uuidString == "180A")
    precondition(CBUUID(data: Data([0x0A, 0x18])).uuidString == "0A18")
    precondition(CBUUID(data: Data([0x0A, 0x18])) != short)

    let expanded = CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB")
    precondition(expanded.uuidString == "180A")
    precondition(expanded.data == Data([0x18, 0x0A]))
    precondition(short == expanded)

    let thirtyTwo = CBUUID(string: "0000180A")
    precondition(thirtyTwo.uuidString == "180A")
    let wide32 = CBUUID(string: "12345678")
    precondition(wide32.data == Data([0x12, 0x34, 0x56, 0x78]))
    precondition(wide32.uuidString == "12345678")
    precondition(CBUUID(data: wide32.data).uuidString == "12345678")

    let full = CBUUID(string: "ABCDEF01-2345-6789-ABCD-EF0123456789")
    precondition(full.data.count == 16)
    precondition(full.uuidString == "ABCDEF01-2345-6789-ABCD-EF0123456789")
    precondition(CBUUID(data: full.data).uuidString == full.uuidString)
    precondition(CBUUID(string: "ABCDEF0123456789ABCDEF0123456789").uuidString == full.uuidString)
    precondition(CBUUID(string: "180a").uuidString == "180A")
    precondition(CBUUID._hostData(fromString: "180A") == Data([0x18, 0x0A]))
    precondition(CBUUID._hostData(fromString: "ZZZZ") == nil)
    precondition(CBUUID._hostData(fromBytes: Data([0x18, 0x0A])) == Data([0x18, 0x0A]))
}

func testCBUUIDNSUUIDAndCFUUID() {
    let short = CBUUID(string: "180A")
    let nsuuid = UUID(uuidString: "0000180A-0000-1000-8000-00805F9B34FB")!
    precondition(CBUUID(nsuuid: nsuuid) == short)
    precondition(CBUUID(NSUUID: nsuuid) == short)

    let cf = CFUUIDCreateFromUUIDBytes(
        nil,
        CFUUIDBytes(
            byte0: 0x00, byte1: 0x00, byte2: 0x18, byte3: 0x0A,
            byte4: 0x00, byte5: 0x00, byte6: 0x10, byte7: 0x00,
            byte8: 0x80, byte9: 0x00, byte10: 0x00, byte11: 0x80,
            byte12: 0x5F, byte13: 0x9B, byte14: 0x34, byte15: 0xFB
        )
    )!
    precondition(CBUUID(cfuuid: cf) == short)
    precondition(CBUUID(CFUUID: cf) == short)
}

// MARK: - CoreBluetoothGATTModelTests.swift
func testMutableCharacteristicModel() {
    let charUUID = CBUUID(string: "2A19")
    let characteristic = CBMutableCharacteristic(
        type: charUUID,
        properties: [.read, .notify],
        value: Data([0x64]),
        permissions: [.readable]
    )
    precondition(characteristic.uuid == charUUID)
    let asCharacteristic: CBCharacteristic = characteristic
    precondition(asCharacteristic.value == Data([0x64]))
    precondition(characteristic.permissions.contains(.readable))
    precondition(characteristic.properties.contains(.read))
    precondition(characteristic.subscribedCentrals == nil)
    precondition(characteristic.isBroadcasted == false)
    precondition(characteristic.isNotifying == false)
    characteristic.value = Data([0x01])
    characteristic.permissions = [.readable, .writeable]
    characteristic.properties = [.read, .write]
    precondition(characteristic.value == Data([0x01]))
}

func testMutableDescriptorOwnership() {
    let descriptor = CBMutableDescriptor(
        type: CBUUID(string: CBUUIDClientCharacteristicConfigurationString),
        value: Data([0x00, 0x00])
    )
    let otherDescriptor = CBMutableDescriptor(type: CBUUID(string: "2901"), value: "name")
    let characteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A19"),
        properties: [.read],
        value: nil,
        permissions: [.readable]
    )
    let otherCharacteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A29"),
        properties: [.read],
        value: nil,
        permissions: [.readable]
    )
    precondition(descriptor.characteristic === characteristic)
    let asDescriptor: CBDescriptor = descriptor
    precondition(asDescriptor.value as? Data == Data([0x00, 0x00]))
    otherCharacteristic.descriptors = [descriptor]
    precondition(descriptor.characteristic === otherCharacteristic)
    otherCharacteristic.descriptors = [otherDescriptor]
    precondition(descriptor.characteristic == nil)
    precondition(otherDescriptor.characteristic === otherCharacteristic)
    precondition(otherDescriptor.value as? String == "name")
}

func testMutableServiceOwnership() {
    let serviceUUID = CBUUID(string: "180F")
    let otherServiceUUID = CBUUID(string: "180A")
    let characteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A19"),
        properties: [.read],
        value: Data([0x64]),
        permissions: [.readable]
    )
    let otherCharacteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A29"),
        properties: [.read],
        value: nil,
        permissions: [.readable]
    )
    let service = CBMutableService(type: serviceUUID, primary: true)
    let otherService = CBMutableService(type: otherServiceUUID, primary: false)
    precondition(service.isPrimary)
    let asService: CBService = service
    precondition(asService.uuid == serviceUUID)
    precondition(!otherService.isPrimary)
    precondition(service.peripheral == nil)
    precondition(service.uuid == serviceUUID)
    service.characteristics = [characteristic]
    precondition(characteristic.service === service)
    otherService.characteristics = [characteristic]
    precondition(characteristic.service === otherService)
    otherService.characteristics = [otherCharacteristic]
    precondition(characteristic.service == nil)
    precondition(otherCharacteristic.service === otherService)

    let included = CBMutableService(type: CBUUID(string: "1800"), primary: false)
    service.includedServices = [included]
    otherService.includedServices = [included]
    precondition(!(service.includedServices ?? []).contains(where: { $0 === included }))
    precondition((otherService.includedServices ?? []).contains(where: { $0 === included }))
    otherService.includedServices = []
    service.includedServices = [included]
    precondition((service.includedServices ?? []).contains(where: { $0 === included }))
    service.includedServices = nil
    precondition(service.includedServices == nil)
}

func testCBAttributeAndPeerIdentity() {
    let service = CBMutableService(type: CBUUID(string: "180F"), primary: true)
    let attribute: CBAttribute = service
    precondition(attribute.uuid == CBUUID(string: "180F"))
    let peer = CBPeripheral(hostIdentifier: UUID(), queue: nil)
    let asPeer: CBPeer = peer
    precondition(asPeer.identifier == peer.identifier)
    precondition(peer.identifier != UUID())
}

func testCBL2CAPChannelIdentity() {
    let peer = CBPeripheral(hostIdentifier: UUID(), queue: nil)
    let input = InputStream(data: Data([0x00]))
    let output = OutputStream.toMemory()
    let channel = CBL2CAPChannel(
        hostPeer: peer,
        psm: 0x0080,
        inputStream: input,
        outputStream: output
    )
    precondition(channel.peer.identifier == peer.identifier)
    precondition(channel.psm == 0x0080)
    _ = channel.inputStream
    _ = channel.outputStream
}

func testCBATTRequestModel() {
    let central = CBCentral(hostIdentifier: UUID(), maximumUpdateValueLength: 20)
    precondition(central.maximumUpdateValueLength == 20)
    precondition(central.identifier != UUID())
    let characteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A19"),
        properties: [.read, .write],
        value: Data([0x01]),
        permissions: [.readable, .writeable]
    )
    let request = CBATTRequest(
        hostCentral: central,
        characteristic: characteristic,
        offset: 4,
        value: Data([0x02])
    )
    precondition(request.central === central)
    precondition(request.characteristic === characteristic)
    precondition(request.offset == 4)
    precondition(request.value == Data([0x02]))
    request.value = Data([0x03])
    precondition(request.value == Data([0x03]))
}

// MARK: - CoreBluetoothFailClosedTests.swift
func testManagerAuthorizationAndUnsupportedState() {
    precondition(CBManager.authorization == .denied)
    let manager = CBCentralManager()
    precondition(manager.authorization == .denied)
    precondition(manager.state == .unsupported)
    let peripheral = CBPeripheralManager()
    precondition(peripheral.state == .unsupported)
    precondition(CBPeripheralManager.authorizationStatus() == .denied)
}

func testCentralManagerFailClosedLifecycle() {
    precondition(!CBCentralManager.supports(.extendedScanAndConnect))
    // Exercises centralManagerDidUpdateState on the fail-closed queue.
    let queueKey = DispatchSpecificKey<String>()
    let queue = DispatchQueue(label: "corebluetooth.tests.central.failclosed")
    queue.setSpecific(key: queueKey, value: "central-token")
    let first = CentralStateProbe(queue: queue, key: queueKey, token: "central-token")
    let asDelegate: (any CBCentralManagerDelegate)? = first
    precondition(asDelegate != nil)
    let manager = CBCentralManager(delegate: first, queue: queue)
    first.lock.lock()
    first.initReturned = true
    first.lock.unlock()
    precondition(first.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    drain(queue)
    first.lock.lock()
    precondition(first.count == 1)
    first.lock.unlock()
    precondition(manager.state == .unsupported)
    precondition(!manager.isScanning)

    let second = CentralStateProbe(queue: queue, key: queueKey, token: "central-token")
    second.lock.lock()
    second.initReturned = true
    second.lock.unlock()
    manager.delegate = second
    precondition(second.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    second.lock.lock()
    precondition(second.count == 1)
    second.lock.unlock()
    manager.delegate = nil
    drain(queue)

    weak var weakProbe: CentralStateProbe?
    do {
        let transient = CentralStateProbe(queue: queue, key: queueKey, token: "central-token")
        transient.lock.lock()
        transient.initReturned = true
        transient.lock.unlock()
        weakProbe = transient
        manager.delegate = transient
        _ = transient.stateSemaphore.wait(timeout: .now() + 2)
    }
    drain(queue)
    precondition(weakProbe == nil)

    let twoArg = CBCentralManager(delegate: nil, queue: queue)
    precondition(twoArg.state == .unsupported)
}

func testCentralManagerFailClosedScanAndRetrieve() {
    let manager = CBCentralManager()
    manager.scanForPeripherals(withServices: [CBUUID(string: "180A")], options: nil)
    precondition(!manager.isScanning)
    manager.stopScan()
    precondition(manager.retrievePeripherals(withIdentifiers: [UUID()]).isEmpty)
    precondition(manager.retrieveConnectedPeripherals(withServices: [CBUUID(string: "180F")]).isEmpty)
    manager.registerForConnectionEvents(
        options: [CBConnectionEventMatchingOption.serviceUUIDs: [CBUUID(string: "180A")]]
    )
}

func testCentralManagerFailClosedConnectAndCancel() {
    // Exercises didFailToConnect / operationNotSupported and cancel without disconnect.
    let queueKey = DispatchSpecificKey<String>()
    let queue = DispatchQueue(label: "corebluetooth.tests.central.connect")
    queue.setSpecific(key: queueKey, value: "central-token")
    let probe = CentralStateProbe(queue: queue, key: queueKey, token: "central-token")
    let manager = CBCentralManager(delegate: probe, queue: queue)
    probe.lock.lock()
    probe.initReturned = true
    probe.lock.unlock()
    precondition(probe.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)

    let peer = CBPeripheral(hostIdentifier: UUID(), queue: queue)
    precondition(peer.state == .disconnected)
    manager.cancelPeripheralConnection(peer)
    drain(queue)
    probe.lock.lock()
    precondition(probe.disconnectCount == 0)
    probe.lock.unlock()

    manager.connect(peer)
    probe.lock.lock()
    probe.connectReturned = true
    let failInlineAtReturn = probe.failInline
    probe.lock.unlock()
    precondition(!failInlineAtReturn)
    precondition(probe.failSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    probe.lock.lock()
    precondition(probe.failCount == 1)
    precondition(!probe.failInline)
    probe.lock.unlock()
    precondition(peer.state == .disconnected)
}

func testPeripheralManagerFailClosedLifecycle() {
    // Exercises peripheralManagerDidUpdateState on the fail-closed queue.
    let queueKey = DispatchSpecificKey<String>()
    let queue = DispatchQueue(label: "corebluetooth.tests.peripheral.failclosed")
    queue.setSpecific(key: queueKey, value: "peripheral-token")
    let first = PeripheralStateProbe(queue: queue, key: queueKey, token: "peripheral-token")
    let asDelegate: (any CBPeripheralManagerDelegate)? = first
    precondition(asDelegate != nil)
    let manager = CBPeripheralManager(delegate: first, queue: queue)
    first.lock.lock()
    first.initReturned = true
    first.lock.unlock()
    precondition(first.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    first.lock.lock()
    precondition(first.count == 1)
    first.lock.unlock()
    precondition(manager.state == .unsupported)
    precondition(!manager.isAdvertising)

    let second = PeripheralStateProbe(queue: queue, key: queueKey, token: "peripheral-token")
    second.lock.lock()
    second.initReturned = true
    second.lock.unlock()
    manager.delegate = second
    precondition(second.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    second.lock.lock()
    precondition(second.count == 1)
    second.lock.unlock()
    let convenience = CBPeripheralManager()
    precondition(convenience.state == .unsupported)
}

func testPeripheralManagerFailClosedAddAndAdvertise() {
    // Exercises peripheralManagerDidStartAdvertising and didAdd fail-closed.
    let queueKey = DispatchSpecificKey<String>()
    let queue = DispatchQueue(label: "corebluetooth.tests.peripheral.add")
    queue.setSpecific(key: queueKey, value: "peripheral-token")
    let probe = PeripheralStateProbe(queue: queue, key: queueKey, token: "peripheral-token")
    let manager = CBPeripheralManager(delegate: probe, queue: queue)
    probe.lock.lock()
    probe.initReturned = true
    probe.lock.unlock()
    precondition(probe.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)

    manager.startAdvertising([CBAdvertisementDataLocalNameKey: "linux-port"])
    precondition(probe.advertisingSemaphore.wait(timeout: .now() + 2) == .success)
    probe.lock.lock()
    requireUnsupported(probe.advertisingError)
    probe.lock.unlock()
    precondition(!manager.isAdvertising)
    manager.stopAdvertising()

    let service = CBMutableService(type: CBUUID(string: "180F"), primary: true)
    manager.add(service)
    precondition(probe.addSemaphore.wait(timeout: .now() + 2) == .success)
    probe.lock.lock()
    requireUnsupported(probe.addError)
    probe.lock.unlock()
    manager.remove(service)
    manager.removeAllServices()
    let characteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A19"),
        properties: [.read],
        value: Data([1]),
        permissions: [.readable]
    )
    precondition(!manager.updateValue(Data([2]), for: characteristic, onSubscribedCentrals: nil))
}

// MARK: - CoreBluetoothCentralSimulationTests.swift
func testSimulatedCentralRestoreAndPoweredOn() {
    // Exercises willRestoreState before centralManagerDidUpdateState.
    withSimulatedAdapter { adapter, identifier, battery, level, queue, queueKey in
        _ = (adapter, identifier, battery, level)
        let probe = SimulatedCentralProbe(key: queueKey, token: "sim-token")
        let manager = CBCentralManager(
            delegate: probe,
            queue: queue,
            options: [
                CBCentralManagerOptionRestoreIdentifierKey: "linux-sim",
                CBCentralManagerOptionShowPowerAlertKey: false,
                CBCentralManagerOptionDeviceAccessForMedia: false,
            ]
        )
        probe.lock.lock()
        probe.initReturned = true
        probe.lock.unlock()
        precondition(probe.stateSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        drain(queue)
        precondition(manager.state == .poweredOn)
        precondition(manager.authorization == .denied)
        precondition(CBManager.authorization == .denied)
        probe.lock.lock()
        precondition(probe.states == [.poweredOn])
        precondition(probe.restored.count == 1)
        let restored = probe.restored[0]
        probe.lock.unlock()
        precondition(restored[CBCentralManagerRestoredStatePeripheralsKey] != nil)
        precondition(restored[CBCentralManagerRestoredStateScanServicesKey] != nil)
        precondition(restored[CBCentralManagerRestoredStateScanOptionsKey] != nil)
    }
}

func testSimulatedScanDiscoveries() {
    // Exercises didDiscover / advertisementData / rssi callbacks.
    withSimulatedAdapter { _, identifier, battery, _, queue, queueKey in
        let (manager, probe) = poweredOnCentral(queue: queue, queueKey: queueKey)
        manager.scanForPeripherals(
            withServices: [battery],
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true,
                CBCentralManagerScanOptionSolicitedServiceUUIDsKey: [CBUUID(string: "1800")],
            ]
        )
        precondition(manager.isScanning)
        precondition(probe.discoverSemaphore.wait(timeout: .now() + 2) == .success)
        precondition(probe.discoverSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        probe.lock.lock()
        let discoveries = probe.discoveries
        probe.lock.unlock()
        precondition(discoveries.count == 2)
        precondition(discoveries[0].0.identifier == identifier)
        precondition(discoveries[0].0 === discoveries[1].0)
        assertAdvertisementKeys(discoveries[0].1)
        precondition(discoveries[0].2 == NSNumber(value: -55))
        manager.stopScan()
        precondition(!manager.isScanning)
        let retrieved = manager.retrievePeripherals(withIdentifiers: [identifier])
        precondition(retrieved.count == 1)
        precondition(retrieved[0] === discoveries[0].0)
    }
}

func testSimulatedConnectDisconnectAndANCS() {
    // Exercises didConnect, didDisconnectPeripheral, connectionEventDidOccur,
    // didUpdateANCSAuthorizationFor, and didFailToConnect for unknown peers.
    withSimulatedAdapter { _, identifier, battery, _, queue, queueKey in
        let (manager, probe) = poweredOnCentral(queue: queue, queueKey: queueKey)
        manager.registerForConnectionEvents(
            options: [
                .peripheralUUIDs: [identifier],
                .serviceUUIDs: [battery],
            ]
        )
        manager.scanForPeripherals(withServices: [battery], options: nil)
        precondition(probe.discoverSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        probe.lock.lock()
        let peripheral = probe.discoveries[0].0
        probe.lock.unlock()
        precondition(peripheral.name == "sim-battery")
        precondition(peripheral.state == .disconnected)
        manager.connect(
            peripheral,
            options: [
                CBConnectPeripheralOptionNotifyOnConnectionKey: true,
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
                CBConnectPeripheralOptionNotifyOnNotificationKey: true,
                CBConnectPeripheralOptionStartDelayKey: 0,
                CBConnectPeripheralOptionEnableTransportBridgingKey: false,
                CBConnectPeripheralOptionRequiresANCS: true,
                CBConnectPeripheralOptionEnableAutoReconnect: false,
            ]
        )
        precondition(peripheral.state == .connecting)
        precondition(probe.connectSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        drain(queue)
        precondition(peripheral.state == .connected)
        precondition(peripheral.ancsAuthorized)
        // Delegate: didConnect, connectionEventDidOccur, didUpdateANCSAuthorizationFor.
        probe.lock.lock()
        precondition(probe.connectionEvents.contains(.peerConnected))
        precondition(probe.ancs.count == 1)
        probe.lock.unlock()
        precondition(
            manager.retrieveConnectedPeripherals(withServices: [battery])
                .contains(where: { $0 === peripheral })
        )

        manager.cancelPeripheralConnection(peripheral)
        precondition(probe.disconnectSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        drain(queue)
        precondition(peripheral.state == .disconnected)
        // Delegate: didDisconnectPeripheral, timestamp overlay.
        probe.lock.lock()
        precondition(probe.disconnectedTimed == 1)
        precondition(probe.connectionEvents.contains(.peerDisconnected))
        probe.lock.unlock()

        let unknown = CBPeripheral(hostIdentifier: UUID(), queue: queue)
        manager.connect(unknown)
        precondition(probe.failSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        probe.lock.lock()
        let lastFail = probe.failed.last?.1 as? CBError
        probe.lock.unlock()
        precondition(lastFail?.code == .connectionFailed)
    }
}

// MARK: - CoreBluetoothPeripheralGATTTests.swift
private func connectedSimulatedPeripheral(
    queue: DispatchQueue,
    queueKey: DispatchSpecificKey<String>,
    battery: CBUUID
) -> (CBCentralManager, SimulatedCentralProbe, CBPeripheral, SimulatedPeripheralProbe) {
    let (manager, centralProbe) = poweredOnCentral(queue: queue, queueKey: queueKey)
    manager.scanForPeripherals(withServices: [battery], options: nil)
    precondition(centralProbe.discoverSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    centralProbe.lock.lock()
    let peripheral = centralProbe.discoveries[0].0
    centralProbe.lock.unlock()
    let gattProbe = SimulatedPeripheralProbe()
    peripheral.delegate = gattProbe
    manager.connect(peripheral)
    precondition(centralProbe.connectSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    drain(queue)
    precondition(peripheral.state == .connected)
    return (manager, centralProbe, peripheral, gattProbe)
}

func testSimulatedDiscoverServicesAndCharacteristics() {
    // Exercises didDiscoverServices, didDiscoverCharacteristicsFor,
    // didDiscoverIncludedServicesFor.
    withSimulatedAdapter { _, _, battery, level, queue, queueKey in
        let (_, _, peripheral, gattProbe) = connectedSimulatedPeripheral(
            queue: queue,
            queueKey: queueKey,
            battery: battery
        )
        precondition(peripheral.delegate === gattProbe)
        let typedDelegate: (any CBPeripheralDelegate)? = peripheral.delegate
        precondition(typedDelegate != nil)
        peripheral.discoverServices([battery])
        precondition(gattProbe.serviceSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        let service = peripheral.services?.first
        precondition(service?.uuid == battery)
        precondition(service?.isPrimary == true)
        precondition(service?.peripheral === peripheral)

        peripheral.discoverIncludedServices(nil, for: service!)
        precondition(gattProbe.includedSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        precondition(service?.includedServices?.first?.uuid == CBUUID(string: "1800"))

        peripheral.discoverCharacteristics([level], for: service!)
        precondition(gattProbe.charSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        let characteristic = service?.characteristics?.first
        precondition(characteristic?.uuid == level)
        precondition(characteristic?.service === service)
        precondition(peripheral.services != nil)
    }
}

func testSimulatedReadWriteNotify() {
    // Exercises didUpdateValueFor, didWriteValueFor, didUpdateNotificationStateFor,
    // peripheralIsReady(toSendWriteWithoutResponse:).
    withSimulatedAdapter { _, _, battery, level, queue, queueKey in
        let (_, _, peripheral, gattProbe) = connectedSimulatedPeripheral(
            queue: queue,
            queueKey: queueKey,
            battery: battery
        )
        precondition(peripheral.canSendWriteWithoutResponse)
        precondition(peripheral.maximumWriteValueLength(for: .withResponse) == 512)
        precondition(peripheral.maximumWriteValueLength(for: .withoutResponse) == 20)
        peripheral.discoverServices([battery])
        precondition(gattProbe.serviceSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        let service = peripheral.services!.first!
        peripheral.discoverCharacteristics([level], for: service)
        precondition(gattProbe.charSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        let characteristic = service.characteristics!.first!

        peripheral.readValue(for: characteristic)
        precondition(gattProbe.valueSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        precondition(characteristic.value == Data([0x64]))

        peripheral.writeValue(Data([0x10]), for: characteristic, type: .withResponse)
        precondition(gattProbe.writeSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        precondition(characteristic.value == Data([0x10]))

        peripheral.writeValue(Data([0x11]), for: characteristic, type: .withoutResponse)
        precondition(gattProbe.readySemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        precondition(characteristic.value == Data([0x11]))
        peripheral.writeValue(Data(count: 21), for: characteristic, type: .withoutResponse)
        drain(queue)
        precondition(characteristic.value == Data([0x11]))

        peripheral.setNotifyValue(true, for: characteristic)
        precondition(gattProbe.notifySemaphore.wait(timeout: .now() + 2) == .success)
        precondition(gattProbe.valueSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        precondition(characteristic.isNotifying == true)
        precondition(characteristic.value == Data([0x63]))
    }
}

func testSimulatedDescriptorsRSSIAndName() {
    // Exercises didDiscoverDescriptorsFor, didUpdateValueFor, didWriteValueFor,
    // didReadRSSI, peripheralDidUpdateRSSI, peripheralDidUpdateName, didModifyServices.
    withSimulatedAdapter { _, _, battery, level, queue, queueKey in
        let (_, _, peripheral, gattProbe) = connectedSimulatedPeripheral(
            queue: queue,
            queueKey: queueKey,
            battery: battery
        )
        peripheral.discoverServices([battery])
        precondition(gattProbe.serviceSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        let service = peripheral.services!.first!
        peripheral.discoverCharacteristics([level], for: service)
        precondition(gattProbe.charSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        let characteristic = service.characteristics!.first!

        peripheral.discoverDescriptors(for: characteristic)
        precondition(gattProbe.descSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        let descriptor = characteristic.descriptors?.first
        precondition(descriptor?.uuid == CBUUID(string: CBUUIDClientCharacteristicConfigurationString))
        peripheral.readValue(for: descriptor!)
        precondition(gattProbe.valueSemaphore.wait(timeout: .now() + 2) == .success)
        peripheral.writeValue(Data([0x01, 0x00]), for: descriptor!)
        precondition(gattProbe.writeSemaphore.wait(timeout: .now() + 2) == .success)

        peripheral.readRSSI()
        precondition(gattProbe.rssiSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        precondition(peripheral.rssi == NSNumber(value: -55))
        gattProbe.lock.lock()
        precondition(gattProbe.rssiLegacy == 1)
        gattProbe.lock.unlock()

        peripheral._hostSetName("renamed")
        precondition(gattProbe.nameSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        precondition(peripheral.name == "renamed")
        peripheral._hostInvalidateServices([service])
        precondition(gattProbe.modifySemaphore.wait(timeout: .now() + 2) == .success)
    }
}

func testSimulatedPeripheralL2CAP() {
    // Exercises openL2CAPChannel / didOpen fail-closed.
    withSimulatedAdapter { _, _, battery, _, queue, queueKey in
        let (_, _, peripheral, gattProbe) = connectedSimulatedPeripheral(
            queue: queue,
            queueKey: queueKey,
            battery: battery
        )
        peripheral.openL2CAPChannel(0x0080)
        precondition(gattProbe.l2capSemaphore.wait(timeout: .now() + 2) == .success)
        gattProbe.lock.lock()
        precondition(gattProbe.l2capErrors == 1)
        gattProbe.lock.unlock()
    }
}

// MARK: - CoreBluetoothPeripheralManagerSimulationTests.swift
func testSimulatedPeripheralManagerRestoreAndAdd() {
    // Exercises willRestoreState then didAdd on the simulated adapter.
    withSimulatedAdapter { adapter, _, battery, level, queue, _ in
        _ = adapter
        let probe = SimulatedManagerProbe()
        let manager = CBPeripheralManager(
            delegate: probe,
            queue: queue,
            options: [
                CBPeripheralManagerOptionRestoreIdentifierKey: "linux-pm",
                CBPeripheralManagerOptionShowPowerAlertKey: false,
            ]
        )
        probe.lock.lock()
        probe.initReturned = true
        probe.lock.unlock()
        precondition(probe.stateSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        precondition(manager.state == .poweredOn)
        probe.lock.lock()
        precondition(probe.restored.count == 1)
        let restored = probe.restored[0]
        probe.lock.unlock()
        precondition(restored[CBPeripheralManagerRestoredStateServicesKey] != nil)
        precondition(restored[CBPeripheralManagerRestoredStateAdvertisementDataKey] != nil)

        let localService = CBMutableService(type: battery, primary: true)
        let localChar = CBMutableCharacteristic(
            type: level,
            properties: [.read, .write, .notify],
            value: Data([0x01]),
            permissions: [.readable, .writeable]
        )
        localService.characteristics = [localChar]
        manager.add(localService)
        precondition(probe.addSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        probe.lock.lock()
        precondition(probe.added.last?.1 == nil)
        probe.lock.unlock()
        manager.remove(localService)
        manager.removeAllServices()
    }
}

func testSimulatedPeripheralManagerAdvertising() {
    // Exercises startAdvertising / isAdvertising / alreadyAdvertising.
    withSimulatedAdapter { _, _, _, _, queue, _ in
        let probe = SimulatedManagerProbe()
        let manager = CBPeripheralManager(delegate: probe, queue: queue, options: [
            CBPeripheralManagerOptionRestoreIdentifierKey: "linux-pm-adv",
        ])
        probe.lock.lock()
        probe.initReturned = true
        probe.lock.unlock()
        precondition(probe.stateSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)

        manager.startAdvertising([CBAdvertisementDataLocalNameKey: "linux-pm"])
        precondition(probe.advertisingSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        precondition(manager.isAdvertising)
        probe.lock.lock()
        precondition(probe.didStartAdvertising)
        precondition(probe.advertisingError == nil)
        probe.lock.unlock()
        manager.startAdvertising(nil)
        precondition(probe.advertisingSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        probe.lock.lock()
        let secondAdv = probe.advertisingError as? CBError
        probe.lock.unlock()
        precondition(secondAdv?.code == .alreadyAdvertising)
        manager.stopAdvertising()
        precondition(!manager.isAdvertising)
    }
}

func testSimulatedATTReadWriteAndSubscribe() {
    // Exercises didSubscribeTo, didUnsubscribeFrom, didReceiveRead, didReceiveWrite,
    // peripheralManagerIsReady(toUpdateSubscribers:).
    withSimulatedAdapter { adapter, _, battery, level, queue, _ in
        let probe = SimulatedManagerProbe()
        let manager = CBPeripheralManager(delegate: probe, queue: queue, options: [
            CBPeripheralManagerOptionRestoreIdentifierKey: "linux-pm-att",
        ])
        probe.lock.lock()
        probe.initReturned = true
        probe.lock.unlock()
        precondition(probe.stateSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)

        let localService = CBMutableService(type: battery, primary: true)
        let localChar = CBMutableCharacteristic(
            type: level,
            properties: [.read, .write, .notify],
            value: Data([0x01]),
            permissions: [.readable, .writeable]
        )
        localService.characteristics = [localChar]
        manager.add(localService)
        precondition(probe.addSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)

        let central = adapter.simulatedCentral
        precondition(central.maximumUpdateValueLength == 20)
        manager._hostSubscribe(central, to: localChar)
        precondition(probe.subscribeSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        precondition(localChar.subscribedCentrals?.contains(where: { $0 === central }) == true)
        precondition(manager.updateValue(Data([0x22]), for: localChar, onSubscribedCentrals: [central]))
        precondition(localChar.value == Data([0x22]))
        precondition(!manager.updateValue(Data(count: 64), for: localChar, onSubscribedCentrals: [central]))
        precondition(probe.readySemaphore.wait(timeout: .now() + 2) == .success)

        let read = CBATTRequest(
            hostCentral: central,
            characteristic: localChar,
            offset: 0,
            value: nil
        )
        manager._hostInjectReadRequest(read)
        precondition(probe.readSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        read.value = Data([0x33])
        manager.respond(to: read, withResult: .success)
        precondition(manager._hostATTResult == .success)
        precondition(localChar.value == Data([0x33]))

        let write = CBATTRequest(
            hostCentral: central,
            characteristic: localChar,
            offset: 0,
            value: Data([0x44])
        )
        manager._hostInjectWriteRequests([write])
        precondition(probe.writeSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)
        manager.respond(to: write, withResult: .success)
        precondition(localChar.value == Data([0x44]))

        manager._hostUnsubscribe(central, from: localChar)
        precondition(probe.subscribeSemaphore.wait(timeout: .now() + 2) == .success)
        manager.setDesiredConnectionLatency(.low, for: central)
    }
}

func testSimulatedPeripheralManagerL2CAP() {
    // Exercises didPublishL2CAPChannel, didUnpublishL2CAPChannel, didOpen.
    withSimulatedAdapter { _, _, _, _, queue, _ in
        let probe = SimulatedManagerProbe()
        let manager = CBPeripheralManager(delegate: probe, queue: queue, options: [
            CBPeripheralManagerOptionRestoreIdentifierKey: "linux-pm-l2cap",
        ])
        probe.lock.lock()
        probe.initReturned = true
        probe.lock.unlock()
        precondition(probe.stateSemaphore.wait(timeout: .now() + 2) == .success)
        drain(queue)

        let peer = CBPeripheral(hostIdentifier: UUID(), queue: queue)
        let channel = CBL2CAPChannel(
            hostPeer: peer,
            psm: 0x0080,
            inputStream: InputStream(data: Data([0x00])),
            outputStream: OutputStream.toMemory()
        )
        manager.publishL2CAPChannel(withEncryption: false)
        precondition(probe.l2capSemaphore.wait(timeout: .now() + 2) == .success)
        manager.unpublishL2CAPChannel(0x0080)
        precondition(probe.l2capSemaphore.wait(timeout: .now() + 2) == .success)
        manager._hostOpenL2CAPChannel(channel, error: CBError(.operationNotSupported))
        precondition(probe.l2capSemaphore.wait(timeout: .now() + 2) == .success)
        probe.lock.lock()
        precondition(probe.l2capPublish == 1)
        precondition(probe.l2capUnpublish == 1)
        precondition(probe.l2capOpen == 1)
        probe.lock.unlock()
    }
}

testAdvertisementDataKeys()
testCentralManagerOptionKeys()
testConnectPeripheralOptionKeys()
testPeripheralManagerOptionKeys()
testCBUUIDCharacteristicStrings()
testErrorDomainConstants()
testCBL2CAPPSMAlias()
testConnectionEventMatchingOptionValues()
testCBErrorCodes()
testCBErrorOverlay()
testCBATTErrorCodes()
testCBATTErrorOverlay()
testCBManagerStateCases()
testCBCentralManagerStateCases()
testCBPeripheralManagerStateCases()
testCBManagerAuthorizationCases()
testCBPeripheralManagerAuthorizationStatusCases()
testCBPeripheralStateCases()
testCBCharacteristicWriteTypeCases()
testCBPeripheralManagerConnectionLatencyCases()
testCBConnectionEventCases()
testCBCharacteristicPropertiesMembers()
testCBCharacteristicPropertiesAlgebra()
testCBAttributePermissionsMembers()
testCBAttributePermissionsAlgebra()
testCBCentralManagerFeatureMembers()
testCBCentralManagerFeatureAlgebra()
testCBUUIDStringAndData()
testCBUUIDNSUUIDAndCFUUID()
testMutableCharacteristicModel()
testMutableDescriptorOwnership()
testMutableServiceOwnership()
testCBAttributeAndPeerIdentity()
testCBL2CAPChannelIdentity()
testCBATTRequestModel()
testManagerAuthorizationAndUnsupportedState()
testCentralManagerFailClosedLifecycle()
testCentralManagerFailClosedScanAndRetrieve()
testCentralManagerFailClosedConnectAndCancel()
testPeripheralManagerFailClosedLifecycle()
testPeripheralManagerFailClosedAddAndAdvertise()
testSimulatedCentralRestoreAndPoweredOn()
testSimulatedScanDiscoveries()
testSimulatedConnectDisconnectAndANCS()
testSimulatedDiscoverServicesAndCharacteristics()
testSimulatedReadWriteNotify()
testSimulatedDescriptorsRSSIAndName()
testSimulatedPeripheralL2CAP()
testSimulatedPeripheralManagerRestoreAndAdd()
testSimulatedPeripheralManagerAdvertising()
testSimulatedATTReadWriteAndSubscribe()
testSimulatedPeripheralManagerL2CAP()
print("CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean")
print("COREBLUETOOTH_AGENT_RUNTIME_OK")
