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
