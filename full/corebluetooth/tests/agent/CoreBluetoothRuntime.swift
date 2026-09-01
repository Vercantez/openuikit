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

private func exerciseConstants() {
    precondition(CBErrorDomain == "CBErrorDomain")
    precondition(CBATTErrorDomain == "CBATTErrorDomain")
    precondition(CBUUIDCharacteristicExtendedPropertiesString == "2900")
    precondition(CBUUIDCharacteristicUserDescriptionString == "2901")
    precondition(CBUUIDClientCharacteristicConfigurationString == "2902")
    precondition(CBUUIDServerCharacteristicConfigurationString == "2903")
    precondition(CBUUIDCharacteristicFormatString == "2904")
    precondition(CBUUIDCharacteristicAggregateFormatString == "2905")
    precondition(CBUUIDCharacteristicValidRangeString == "2906")
    precondition(CBUUIDL2CAPPSMCharacteristicString == "ABDD3056-28FA-441D-A470-55A75A52553A")
    let psm: CBL2CAPPSM = 0x0080
    precondition(psm == 128)
    let supplied = CBConnectionEventMatchingOption(rawValue: "host-supplied")
    precondition(supplied.rawValue == "host-supplied")
    precondition(
        CBConnectionEventMatchingOption.peripheralUUIDs
            != CBConnectionEventMatchingOption.serviceUUIDs
    )
    var hasher = Hasher()
    hasher.combine(supplied)
    _ = hasher.finalize()
}

private func exerciseErrors() {
    precondition(CBError.unknown.rawValue == 0)
    precondition(CBError.notConnected.rawValue == 3)
    precondition(CBError.unkownDevice.rawValue == 12)
    precondition(CBError.unknownDevice.rawValue == 12)
    precondition(CBError.Code.unknownDevice == .unkownDevice)
    precondition(CBError.operationNotSupported.rawValue == 13)
    precondition(CBError.tooManyLEPairedDevices.rawValue == 16)
    precondition(CBError.Code(rawValue: 13) == .operationNotSupported)
    precondition(CBError.Code(rawValue: 99) == nil)

    let typed = CBError(.notConnected, userInfo: ["reason": "linux"])
    precondition(typed.code == .notConnected)
    precondition(typed.errorCode == 3)
    precondition(typed.userInfo["reason"] as? String == "linux")
    precondition(typed.errorUserInfo["reason"] as? String == "linux")
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
    precondition(typedCBError(from: fresh)?.userInfo["k"] as? String == "v")

    let att = CBATTError(.readNotPermitted, userInfo: ["att": 2])
    precondition(CBATTError.readNotPermitted ~= att)
    precondition(CBATTError.errorDomain == CBATTErrorDomain)
    assertTypedOriginCBATTError(att, key: "att", intValue: 2)
    let freshATT = NSError(domain: CBATTErrorDomain, code: CBATTError.readNotPermitted.rawValue, userInfo: ["att": 2])
    precondition((freshATT as? CBATTError) == nil)
    precondition(CBATTError.readNotPermitted ~= freshATT)
    precondition(rehydrateCBATTError(from: freshATT)?.code == .readNotPermitted)
    _ = typed.hashValue
    _ = att.hashValue
    var hasher = Hasher()
    typed.hash(into: &hasher)
    CBError.Code.notConnected.hash(into: &hasher)
    att.hash(into: &hasher)
    _ = hasher.finalize()
}

private func exerciseEnumsAndOptionSets() {
    precondition(CBManagerState.unsupported.rawValue == 2)
    precondition(CBManagerState(rawValue: 5) == .poweredOn)
    precondition(CBCentralManagerState.unsupported.rawValue == 2)
    precondition(CBPeripheralManagerState.unsupported.rawValue == 2)
    precondition(CBManagerAuthorization.denied.rawValue == 2)
    precondition(CBPeripheralManagerAuthorizationStatus.denied.rawValue == 2)
    precondition(CBPeripheralState.disconnected.rawValue == 0)
    precondition(CBCharacteristicWriteType.withResponse != .withoutResponse)
    precondition(CBPeripheralManagerConnectionLatency.medium.rawValue == 1)
    precondition(CBConnectionEvent.peerConnected.rawValue == 1)
    var hasher = Hasher()
    CBManagerState.unsupported.hash(into: &hasher)
    _ = CBManagerState.unsupported.hashValue

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
    precondition(CBCharacteristicProperties.authenticatedSignedWrites.rawValue == 0x40)

    var permissions: CBAttributePermissions = [.readable]
    permissions.insert(.writeable)
    _ = permissions.union(.readEncryptionRequired)
    _ = permissions.intersection(.readable)
    _ = permissions.subtracting(.writeable)
    _ = permissions.symmetricDifference(.readable)
    _ = permissions.isSubset(of: [.readable, .writeable])
    _ = permissions.isSuperset(of: .readable)
    _ = permissions.isDisjoint(with: .writeEncryptionRequired)
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
    _ = hasher.finalize()
}

private func exerciseUUIDs() {
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

    precondition(CBUUID(string: "180a").uuidString == "180A")
    precondition(CBUUID(string: "abcdef01-2345-6789-abcd-ef0123456789").uuidString == full.uuidString)
    precondition(
        CBUUID(string: "0000180A00001000800000805F9B34FB").uuidString == "180A"
    )

    precondition(CBUUID._hostData(fromString: "180A") == Data([0x18, 0x0A]))
    precondition(CBUUID._hostData(fromString: "18-0A") == nil)
    precondition(CBUUID._hostData(fromString: "0x180A") == nil)
    precondition(CBUUID._hostData(fromString: "ZZZZ") == nil)
    precondition(CBUUID._hostData(fromString: "180") == nil)
    precondition(CBUUID._hostData(fromString: "180AA") == nil)
    precondition(CBUUID._hostData(fromString: " 180A") == nil)
    precondition(CBUUID._hostData(fromString: "180A ") == nil)
    precondition(CBUUID._hostData(fromString: "{180A}") == nil)
    precondition(CBUUID._hostData(fromString: "") == nil)
    precondition(CBUUID._hostData(fromString: "180A-") == nil)
    precondition(CBUUID._hostData(fromString: "GGGG") == nil)
    precondition(CBUUID._hostData(fromString: "0000180A-0000-1000-8000") == nil)
    precondition(CBUUID._hostData(fromString: "0000180A-0000-1000-8000-00805F9B34FB-00") == nil)
    precondition(CBUUID._hostData(fromBytes: Data([0x18])) == nil)
    precondition(CBUUID._hostData(fromBytes: Data([0x18, 0x0A, 0x00])) == nil)
    precondition(CBUUID._hostData(fromBytes: Data(count: 15)) == nil)
    precondition(CBUUID._hostData(fromBytes: Data(count: 17)) == nil)
    precondition(CBUUID._hostData(fromBytes: Data()) == nil)
    precondition(CBUUID._hostData(fromBytes: Data([0x18, 0x0A])) == Data([0x18, 0x0A]))
}

private func exerciseMutableGATT() {
    let serviceUUID = CBUUID(string: "180F")
    let otherServiceUUID = CBUUID(string: "180A")
    let charUUID = CBUUID(string: "2A19")
    let descUUID = CBUUID(string: CBUUIDClientCharacteristicConfigurationString)

    let descriptor = CBMutableDescriptor(type: descUUID, value: Data([0x00, 0x00]))
    let otherDescriptor = CBMutableDescriptor(type: CBUUID(string: "2901"), value: "name")
    let characteristic = CBMutableCharacteristic(
        type: charUUID,
        properties: [.read, .notify],
        value: Data([0x64]),
        permissions: [.readable]
    )
    let otherCharacteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A29"),
        properties: [.read],
        value: nil,
        permissions: [.readable]
    )
    precondition(characteristic.uuid == charUUID)
    precondition(characteristic.value == Data([0x64]))
    precondition(characteristic.permissions.contains(.readable))
    precondition(characteristic.subscribedCentrals == nil)
    precondition(characteristic.isBroadcasted == false)
    precondition(characteristic.isNotifying == false)

    characteristic.descriptors = [descriptor]
    precondition(descriptor.characteristic === characteristic)
    otherCharacteristic.descriptors = [descriptor]
    precondition(descriptor.characteristic === otherCharacteristic)
    precondition(characteristic.descriptors == nil || !(characteristic.descriptors ?? []).contains(where: { $0 === descriptor }))
    otherCharacteristic.descriptors = [otherDescriptor]
    precondition(descriptor.characteristic == nil)
    precondition(otherDescriptor.characteristic === otherCharacteristic)

    let service = CBMutableService(type: serviceUUID, primary: true)
    let otherService = CBMutableService(type: otherServiceUUID, primary: false)
    precondition(service.isPrimary)
    precondition(!otherService.isPrimary)
    precondition(service.peripheral == nil)
    service.characteristics = [characteristic]
    precondition(characteristic.service === service)
    otherService.characteristics = [characteristic]
    precondition(characteristic.service === otherService)
    precondition(service.characteristics == nil || !(service.characteristics ?? []).contains(where: { $0 === characteristic }))
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

private func exerciseCentralManager() {
    precondition(CBManager.authorization == .denied)
    precondition(!CBCentralManager.supports(.extendedScanAndConnect))

    let queueKey = DispatchSpecificKey<String>()
    let queue = DispatchQueue(label: "corebluetooth.runtime.central")
    queue.setSpecific(key: queueKey, value: "central-token")
    let first = CentralStateProbe(queue: queue, key: queueKey, token: "central-token")
    let manager = CBCentralManager(delegate: first, queue: queue)
    first.lock.lock()
    first.initReturned = true
    let inlineAtReturn = first.inlineDuringInit
    first.lock.unlock()
    precondition(inlineAtReturn == false)
    precondition(first.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    drain(queue)
    first.lock.lock()
    let firstCount = first.count
    let firstInline = first.inlineDuringInit
    first.lock.unlock()
    precondition(firstCount == 1)
    precondition(!firstInline)
    precondition(manager.state == .unsupported)
    precondition(!manager.isScanning)

    manager.scanForPeripherals(withServices: [CBUUID(string: "180A")], options: nil)
    precondition(!manager.isScanning)
    manager.stopScan()
    precondition(manager.retrievePeripherals(withIdentifiers: [UUID()]).isEmpty)
    precondition(manager.retrieveConnectedPeripherals(withServices: [CBUUID(string: "180F")]).isEmpty)
    manager.registerForConnectionEvents(
        options: [CBConnectionEventMatchingOption.serviceUUIDs: [CBUUID(string: "180A")]]
    )

    let second = CentralStateProbe(queue: queue, key: queueKey, token: "central-token")
    second.lock.lock()
    second.initReturned = true
    second.lock.unlock()
    manager.delegate = second
    precondition(second.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    drain(queue)
    second.lock.lock()
    let secondCount = second.count
    second.lock.unlock()
    first.lock.lock()
    let firstAfterReplace = first.count
    first.lock.unlock()
    precondition(secondCount == 1)
    precondition(firstAfterReplace == 1)

    manager.delegate = nil
    drain(queue)
    let restored = CentralStateProbe(queue: queue, key: queueKey, token: "central-token")
    restored.lock.lock()
    restored.initReturned = true
    restored.lock.unlock()
    manager.delegate = restored
    precondition(restored.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    restored.lock.lock()
    precondition(restored.count == 1)
    restored.lock.unlock()

    let peer = CBPeripheral(hostIdentifier: UUID(), queue: queue)
    precondition(peer.state == .disconnected)
    _ = peer.identifier
    manager.cancelPeripheralConnection(peer)
    drain(queue)
    restored.lock.lock()
    let disconnects = restored.disconnectCount
    restored.lock.unlock()
    precondition(disconnects == 0)

    manager.connect(peer)
    restored.lock.lock()
    restored.connectReturned = true
    let failInlineAtReturn = restored.failInline
    restored.lock.unlock()
    precondition(!failInlineAtReturn)
    precondition(restored.failSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    drain(queue)
    restored.lock.lock()
    let fails = restored.failCount
    let failInline = restored.failInline
    restored.lock.unlock()
    precondition(fails == 1)
    precondition(!failInline)
    precondition(peer.state == .disconnected)

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

    let convenience = CBCentralManager()
    precondition(convenience.state == .unsupported)
    let twoArg = CBCentralManager(delegate: nil, queue: queue)
    precondition(twoArg.state == .unsupported)
}

private func exercisePeripheralManager() {
    precondition(CBPeripheralManager.authorizationStatus() == .denied)
    let queueKey = DispatchSpecificKey<String>()
    let queue = DispatchQueue(label: "corebluetooth.runtime.peripheral")
    queue.setSpecific(key: queueKey, value: "peripheral-token")
    let first = PeripheralStateProbe(queue: queue, key: queueKey, token: "peripheral-token")
    let manager = CBPeripheralManager(delegate: first, queue: queue)
    first.lock.lock()
    first.initReturned = true
    let inlineAtReturn = first.inlineDuringInit
    first.lock.unlock()
    precondition(!inlineAtReturn)
    precondition(first.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    drain(queue)
    first.lock.lock()
    precondition(first.count == 1)
    precondition(!first.inlineDuringInit)
    first.lock.unlock()
    precondition(manager.state == .unsupported)
    precondition(!manager.isAdvertising)

    manager.startAdvertising([CBAdvertisementDataLocalNameKey: "linux-port"])
    precondition(first.advertisingSemaphore.wait(timeout: .now() + 2) == .success)
    first.lock.lock()
    let advertisingError = first.advertisingError
    first.lock.unlock()
    requireUnsupported(advertisingError)
    precondition(!manager.isAdvertising)
    manager.stopAdvertising()

    let second = PeripheralStateProbe(queue: queue, key: queueKey, token: "peripheral-token")
    second.lock.lock()
    second.initReturned = true
    second.lock.unlock()
    manager.delegate = second
    precondition(second.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    drain(queue)
    second.lock.lock()
    precondition(second.count == 1)
    second.lock.unlock()
    first.lock.lock()
    precondition(first.count == 1)
    first.lock.unlock()

    let service = CBMutableService(type: CBUUID(string: "180F"), primary: true)
    manager.add(service)
    precondition(second.addSemaphore.wait(timeout: .now() + 2) == .success)
    second.lock.lock()
    let addError = second.addError
    second.lock.unlock()
    requireUnsupported(addError)
    manager.remove(service)
    manager.removeAllServices()
    let characteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A19"),
        properties: [.read],
        value: Data([1]),
        permissions: [.readable]
    )
    precondition(!manager.updateValue(Data([2]), for: characteristic, onSubscribedCentrals: nil))
    let convenience = CBPeripheralManager()
    precondition(convenience.state == .unsupported)
}

exerciseConstants()
exerciseErrors()
exerciseEnumsAndOptionSets()
exerciseUUIDs()
exerciseMutableGATT()
exerciseCentralManager()
exercisePeripheralManager()
print("COREBLUETOOTH_AGENT_RUNTIME_OK")
