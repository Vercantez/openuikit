import CoreBluetooth
import CoreFoundation
import Dispatch
import Foundation

private func requireUnsupported(_ error: Error?) {
    guard let error = error as? CBError else {
        fatalError("expected typed CBError, got \(String(describing: error))")
    }
    precondition(error.code == .operationNotSupported)
    precondition(error.errorCode == CBError.operationNotSupported.rawValue)
    precondition(CBError.errorDomain == CBErrorDomain)
}

private final class CentralProbe: NSObject, CBCentralManagerDelegate {
    let queue = DispatchQueue(label: "corebluetooth.runtime.central")
    let stateLock = NSLock()
    var state: CBManagerState?
    var stateSemaphore = DispatchSemaphore(value: 0)
    var manager: CBCentralManager?

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        stateLock.lock()
        state = central.state
        stateLock.unlock()
        stateSemaphore.signal()
    }
}

private final class PeripheralManagerProbe: NSObject, CBPeripheralManagerDelegate {
    let queue = DispatchQueue(label: "corebluetooth.runtime.peripheral")
    let lock = NSLock()
    var stateSemaphore = DispatchSemaphore(value: 0)
    var advertisingSemaphore = DispatchSemaphore(value: 0)
    var addServiceSemaphore = DispatchSemaphore(value: 0)
    var publishSemaphore = DispatchSemaphore(value: 0)
    var advertisingError: (any Error)?
    var addServiceError: (any Error)?
    var publishError: (any Error)?
    var manager: CBPeripheralManager?

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        _ = peripheral
        stateSemaphore.signal()
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
        _ = peripheral
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
        lock.lock()
        addServiceError = error
        lock.unlock()
        addServiceSemaphore.signal()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didPublishL2CAPChannel PSM: CBL2CAPPSM,
        error: (any Error)?
    ) {
        _ = (peripheral, PSM)
        lock.lock()
        publishError = error
        lock.unlock()
        publishSemaphore.signal()
    }
}

private func exerciseConstants() {
    precondition(!CBErrorDomain.isEmpty)
    precondition(!CBATTErrorDomain.isEmpty)
    precondition(CBAdvertisementDataLocalNameKey == "CBAdvertisementDataLocalNameKey")
    precondition(CBAdvertisementDataManufacturerDataKey == "CBAdvertisementDataManufacturerDataKey")
    precondition(CBAdvertisementDataServiceDataKey == "CBAdvertisementDataServiceDataKey")
    precondition(CBAdvertisementDataServiceUUIDsKey == "CBAdvertisementDataServiceUUIDsKey")
    precondition(CBAdvertisementDataOverflowServiceUUIDsKey == "CBAdvertisementDataOverflowServiceUUIDsKey")
    precondition(CBAdvertisementDataTxPowerLevelKey == "CBAdvertisementDataTxPowerLevelKey")
    precondition(CBAdvertisementDataIsConnectable == "CBAdvertisementDataIsConnectable")
    precondition(CBAdvertisementDataSolicitedServiceUUIDsKey == "CBAdvertisementDataSolicitedServiceUUIDsKey")
    precondition(CBCentralManagerOptionShowPowerAlertKey == "CBCentralManagerOptionShowPowerAlertKey")
    precondition(CBCentralManagerOptionRestoreIdentifierKey == "CBCentralManagerOptionRestoreIdentifierKey")
    precondition(CBCentralManagerOptionDeviceAccessForMedia == "CBCentralManagerOptionDeviceAccessForMedia")
    precondition(CBCentralManagerScanOptionAllowDuplicatesKey == "CBCentralManagerScanOptionAllowDuplicatesKey")
    precondition(CBCentralManagerScanOptionSolicitedServiceUUIDsKey == "CBCentralManagerScanOptionSolicitedServiceUUIDsKey")
    precondition(CBConnectPeripheralOptionNotifyOnConnectionKey == "CBConnectPeripheralOptionNotifyOnConnectionKey")
    precondition(CBConnectPeripheralOptionNotifyOnDisconnectionKey == "CBConnectPeripheralOptionNotifyOnDisconnectionKey")
    precondition(CBConnectPeripheralOptionNotifyOnNotificationKey == "CBConnectPeripheralOptionNotifyOnNotificationKey")
    precondition(CBConnectPeripheralOptionStartDelayKey == "CBConnectPeripheralOptionStartDelayKey")
    precondition(CBConnectPeripheralOptionEnableTransportBridgingKey == "CBConnectPeripheralOptionEnableTransportBridgingKey")
    precondition(CBConnectPeripheralOptionRequiresANCS == "CBConnectPeripheralOptionRequiresANCS")
    precondition(CBConnectPeripheralOptionEnableAutoReconnect == "CBConnectPeripheralOptionEnableAutoReconnect")
    precondition(CBCentralManagerRestoredStatePeripheralsKey == "CBCentralManagerRestoredStatePeripheralsKey")
    precondition(CBCentralManagerRestoredStateScanServicesKey == "CBCentralManagerRestoredStateScanServicesKey")
    precondition(CBCentralManagerRestoredStateScanOptionsKey == "CBCentralManagerRestoredStateScanOptionsKey")
    precondition(CBPeripheralManagerOptionShowPowerAlertKey == "CBPeripheralManagerOptionShowPowerAlertKey")
    precondition(CBPeripheralManagerOptionRestoreIdentifierKey == "CBPeripheralManagerOptionRestoreIdentifierKey")
    precondition(CBPeripheralManagerRestoredStateServicesKey == "CBPeripheralManagerRestoredStateServicesKey")
    precondition(CBPeripheralManagerRestoredStateAdvertisementDataKey == "CBPeripheralManagerRestoredStateAdvertisementDataKey")
    precondition(CBUUIDCharacteristicExtendedPropertiesString == "2900")
    precondition(CBUUIDCharacteristicUserDescriptionString == "2901")
    precondition(CBUUIDClientCharacteristicConfigurationString == "2902")
    precondition(CBUUIDServerCharacteristicConfigurationString == "2903")
    precondition(CBUUIDCharacteristicFormatString == "2904")
    precondition(CBUUIDCharacteristicAggregateFormatString == "2905")
    precondition(CBUUIDCharacteristicValidRangeString == "2906")
    precondition(CBUUIDL2CAPPSMCharacteristicString == "ABDD3056-28FA-441D-A470-55A75A52553A")
    precondition(!CBUUIDCharacteristicObservationScheduleString.isEmpty)
    let psm: CBL2CAPPSM = 0x0080
    precondition(psm == 128)
    precondition(CBConnectionEventMatchingOption.peripheralUUIDs.rawValue == "peripheralUUIDs")
    precondition(CBConnectionEventMatchingOption.serviceUUIDs.rawValue == "serviceUUIDs")
    precondition(
        CBConnectionEventMatchingOption(rawValue: "peripheralUUIDs")
            == CBConnectionEventMatchingOption.peripheralUUIDs
    )
    precondition(
        CBConnectionEventMatchingOption.peripheralUUIDs
            != CBConnectionEventMatchingOption.serviceUUIDs
    )
    var hasher = Hasher()
    hasher.combine(CBConnectionEventMatchingOption.serviceUUIDs)
    _ = hasher.finalize()
}

private func exerciseErrors() {
    precondition(CBError.unknown.rawValue == 0)
    precondition(CBError.invalidParameters.rawValue == 1)
    precondition(CBError.invalidHandle.rawValue == 2)
    precondition(CBError.notConnected.rawValue == 3)
    precondition(CBError.outOfSpace.rawValue == 4)
    precondition(CBError.operationCancelled.rawValue == 5)
    precondition(CBError.connectionTimeout.rawValue == 6)
    precondition(CBError.peripheralDisconnected.rawValue == 7)
    precondition(CBError.uuidNotAllowed.rawValue == 8)
    precondition(CBError.alreadyAdvertising.rawValue == 9)
    precondition(CBError.connectionFailed.rawValue == 10)
    precondition(CBError.connectionLimitReached.rawValue == 11)
    precondition(CBError.unkownDevice.rawValue == 12)
    precondition(CBError.unknownDevice.rawValue == 12)
    precondition(CBError.Code.unknownDevice == .unkownDevice)
    precondition(CBError.operationNotSupported.rawValue == 13)
    precondition(CBError.peerRemovedPairingInformation.rawValue == 14)
    precondition(CBError.encryptionTimedOut.rawValue == 15)
    precondition(CBError.tooManyLEPairedDevices.rawValue == 16)
    precondition(CBError.Code(rawValue: 13) == .operationNotSupported)
    precondition(CBError.Code(rawValue: 99) == nil)

    let typed = CBError(.notConnected, userInfo: ["reason": "linux"])
    precondition(typed.code == .notConnected)
    precondition(typed.errorCode == 3)
    precondition(typed.userInfo["reason"] as? String == "linux")
    precondition(typed.errorUserInfo["reason"] as? String == "linux")
    precondition(typed == CBError(.notConnected, userInfo: ["reason": "linux"]))
    precondition(typed != CBError(.unknown))
    precondition(CBError.notConnected ~= typed)
    precondition(!(CBError.unknown ~= typed))
    _ = typed.hashValue
    _ = typed.localizedDescription
    _ = CBError.Code.notConnected.hashValue
    var hasher = Hasher()
    typed.hash(into: &hasher)
    CBError.Code.notConnected.hash(into: &hasher)

    precondition(CBATTError.success.rawValue == 0)
    precondition(CBATTError.invalidHandle.rawValue == 1)
    precondition(CBATTError.readNotPermitted.rawValue == 2)
    precondition(CBATTError.writeNotPermitted.rawValue == 3)
    precondition(CBATTError.invalidPdu.rawValue == 4)
    precondition(CBATTError.insufficientAuthentication.rawValue == 5)
    precondition(CBATTError.requestNotSupported.rawValue == 6)
    precondition(CBATTError.invalidOffset.rawValue == 7)
    precondition(CBATTError.insufficientAuthorization.rawValue == 8)
    precondition(CBATTError.prepareQueueFull.rawValue == 9)
    precondition(CBATTError.attributeNotFound.rawValue == 10)
    precondition(CBATTError.attributeNotLong.rawValue == 11)
    precondition(CBATTError.insufficientEncryptionKeySize.rawValue == 12)
    precondition(CBATTError.invalidAttributeValueLength.rawValue == 13)
    precondition(CBATTError.unlikelyError.rawValue == 14)
    precondition(CBATTError.insufficientEncryption.rawValue == 15)
    precondition(CBATTError.unsupportedGroupType.rawValue == 16)
    precondition(CBATTError.insufficientResources.rawValue == 17)
    let att = CBATTError(.readNotPermitted)
    precondition(CBATTError.readNotPermitted ~= att)
    precondition(CBATTError.errorDomain == CBATTErrorDomain)
    precondition(att != CBATTError(.success))
    _ = att.hashValue
    _ = att.localizedDescription
    _ = CBATTError.Code.success.hashValue
    att.hash(into: &hasher)
    CBATTError.Code.success.hash(into: &hasher)
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
    precondition(CBCharacteristicWriteType.withResponse.rawValue == 0)
    precondition(CBCharacteristicWriteType.withoutResponse.rawValue == 1)
    precondition(CBPeripheralManagerConnectionLatency.medium.rawValue == 1)
    precondition(CBConnectionEvent.peerConnected.rawValue == 1)
    precondition(CBManagerState.unknown != CBManagerState.unsupported)
    _ = CBManagerState.unsupported.hashValue
    var hasher = Hasher()
    CBManagerState.unsupported.hash(into: &hasher)
    CBCentralManagerState.poweredOff.hash(into: &hasher)
    CBPeripheralManagerState.poweredOn.hash(into: &hasher)
    CBManagerAuthorization.denied.hash(into: &hasher)
    CBPeripheralManagerAuthorizationStatus.denied.hash(into: &hasher)
    CBPeripheralState.connected.hash(into: &hasher)
    CBCharacteristicWriteType.withResponse.hash(into: &hasher)
    CBConnectionEvent.peerDisconnected.hash(into: &hasher)
    CBPeripheralManagerConnectionLatency.low.hash(into: &hasher)

    var properties: CBCharacteristicProperties = [.read, .notify]
    precondition(properties.contains(.read))
    precondition(!properties.contains(.write))
    precondition(!properties.isEmpty)
    properties.insert(.write)
    precondition(properties.contains(.write))
    _ = properties.remove(.notify)
    _ = properties.update(with: .indicate)
    let unioned = CBCharacteristicProperties.read.union(.write)
    precondition(unioned.contains(.read) && unioned.contains(.write))
    let intersected = unioned.intersection(.read)
    precondition(intersected == .read)
    let subtracted = unioned.subtracting(.write)
    precondition(subtracted == .read)
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
    precondition(CBCharacteristicProperties.authenticatedSignedWrites.rawValue == 0x40)
    precondition(CBCharacteristicProperties.notifyEncryptionRequired.rawValue == 0x100)
    precondition(CBCharacteristicProperties.indicateEncryptionRequired.rawValue == 0x200)
    precondition(CBCharacteristicProperties.writeWithoutResponse.rawValue == 0x04)
    precondition(CBCharacteristicProperties.indicate.rawValue == 0x20)
    precondition(CBCharacteristicProperties.read != CBCharacteristicProperties.write)
    precondition(CBCharacteristicProperties.read.isStrictSubset(of: [.read, .write]))
    precondition(CBCharacteristicProperties([.read, .write]).isStrictSuperset(of: .read))

    var permissions: CBAttributePermissions = [.readable]
    permissions.insert(.writeable)
    precondition(permissions.contains(.readable) && permissions.contains(.writeable))
    precondition(CBAttributePermissions.readEncryptionRequired.rawValue == 0x04)
    precondition(CBAttributePermissions.writeEncryptionRequired.rawValue == 0x08)
    _ = permissions.union(.readEncryptionRequired)
    _ = permissions.intersection(.readable)
    _ = permissions.subtracting(.writeable)
    _ = permissions.symmetricDifference(.readable)
    _ = permissions.isSubset(of: [.readable, .writeable, .readEncryptionRequired])
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
    precondition(CBAttributePermissions.readable != .writeable)

    var feature = CBCentralManager.Feature()
    feature.insert(.extendedScanAndConnect)
    precondition(feature.contains(.extendedScanAndConnect))
    precondition(CBCentralManager.Feature.extendedScanAndConnect.rawValue == 1)
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
    precondition(!CBCentralManager.Feature.extendedScanAndConnect.isStrictSubset(of: .extendedScanAndConnect))
    _ = CBCentralManager.Feature.extendedScanAndConnect.isStrictSuperset(of: [])
    precondition(CBCentralManager.Feature() != .extendedScanAndConnect)
    _ = hasher.finalize()
}

private func exerciseUUIDs() {
    let short = CBUUID(string: "180A")
    precondition(short.uuidString == "180A")
    precondition(short.data.count == 2)
    precondition(short.data == Data([0x18, 0x0A]))

    let expanded = CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB")
    precondition(expanded.uuidString == "180A")
    precondition(short == expanded)
    precondition(short.isEqual(expanded))

    let thirtyTwo = CBUUID(string: "0000180A")
    precondition(thirtyTwo.data.count == 2 || thirtyTwo.data.count == 4)
    precondition(thirtyTwo == short)

    let full = CBUUID(string: "ABCDEF01-2345-6789-ABCD-EF0123456789")
    precondition(full.data.count == 16)
    precondition(full.uuidString == "ABCDEF01-2345-6789-ABCD-EF0123456789")
    precondition(full != short)

    let fromData = CBUUID(data: Data([0x18, 0x0A]))
    precondition(fromData == short)

    let nsuuid = UUID(uuidString: "0000180A-0000-1000-8000-00805F9B34FB")!
    let fromNS = CBUUID(nsuuid: nsuuid)
    precondition(fromNS == short)
    let fromNS2 = CBUUID(NSUUID: nsuuid)
    precondition(fromNS2 == short)

    let cf = CFUUIDCreateFromUUIDBytes(
        nil,
        CFUUIDBytes(
            byte0: 0x00, byte1: 0x00, byte2: 0x18, byte3: 0x0A,
            byte4: 0x00, byte5: 0x00, byte6: 0x10, byte7: 0x00,
            byte8: 0x80, byte9: 0x00, byte10: 0x00, byte11: 0x80,
            byte12: 0x5F, byte13: 0x9B, byte14: 0x34, byte15: 0xFB
        )
    )!
    let fromCF = CBUUID(cfuuid: cf)
    precondition(fromCF == short)
    let fromCF2 = CBUUID(CFUUID: cf)
    precondition(fromCF2 == short)

    let desc = CBUUID(string: CBUUIDCharacteristicUserDescriptionString)
    precondition(desc.uuidString == "2901")
    _ = short.hash
    _ = short.description
}

private func exerciseMutableGATT() {
    let serviceUUID = CBUUID(string: "180F")
    let charUUID = CBUUID(string: "2A19")
    let descUUID = CBUUID(string: CBUUIDClientCharacteristicConfigurationString)

    let descriptor = CBMutableDescriptor(type: descUUID, value: Data([0x00, 0x00]))
    precondition(descriptor.uuid == descUUID)
    precondition((descriptor.value as? Data) == Data([0x00, 0x00]))
    precondition(descriptor.characteristic == nil)

    let characteristic = CBMutableCharacteristic(
        type: charUUID,
        properties: [.read, .notify],
        value: Data([0x64]),
        permissions: [.readable]
    )
    characteristic.descriptors = [descriptor]
    precondition(characteristic.uuid == charUUID)
    precondition(characteristic.properties.contains(.read))
    precondition(characteristic.value == Data([0x64]))
    precondition(characteristic.permissions.contains(.readable))
    precondition(characteristic.descriptors?.count == 1)
    precondition(characteristic.subscribedCentrals == nil)
    precondition(!characteristic.isNotifying)
    precondition(!characteristic.isBroadcasted)
    precondition(descriptor.characteristic === characteristic)
    characteristic.properties = [.read, .notify, .indicate]
    characteristic.value = Data([0x32])
    precondition(characteristic.value == Data([0x32]))

    let service = CBMutableService(type: serviceUUID, primary: true)
    service.characteristics = [characteristic]
    precondition(service.uuid == serviceUUID)
    precondition(service.isPrimary)
    precondition(service.peripheral == nil)
    precondition(service.characteristics?.count == 1)
    precondition(characteristic.service === service)
    service.includedServices = []
    precondition(service.includedServices?.isEmpty == true)
    _ = service.uuid
    _ = characteristic.service
    _ = descriptor.characteristic
}

private func exerciseCentralManager() {
    precondition(CBManager.authorization == .denied)
    precondition(!CBCentralManager.supports(.extendedScanAndConnect))
    precondition(!CBCentralManager.supports([]))

    let probe = CentralProbe()
    let manager = CBCentralManager(
        delegate: probe,
        queue: probe.queue,
        options: [CBCentralManagerOptionShowPowerAlertKey: false]
    )
    probe.manager = manager
    precondition(probe.stateSemaphore.wait(timeout: .now() + 2) == .success)
    probe.stateLock.lock()
    let state = probe.state
    probe.stateLock.unlock()
    precondition(state == .unsupported)
    precondition(manager.state == .unsupported)
    precondition(manager.authorization == .denied)
    precondition(manager.delegate === probe)
    precondition(!manager.isScanning)

    manager.scanForPeripherals(
        withServices: [CBUUID(string: "180A")],
        options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
    )
    precondition(!manager.isScanning)
    manager.stopScan()
    precondition(!manager.isScanning)
    precondition(manager.retrievePeripherals(withIdentifiers: [UUID()]).isEmpty)
    precondition(manager.retrieveConnectedPeripherals(withServices: [CBUUID(string: "180F")]).isEmpty)
    manager.registerForConnectionEvents(
        options: [CBConnectionEventMatchingOption.serviceUUIDs: [CBUUID(string: "180A")]]
    )

    let convenience = CBCentralManager()
    precondition(convenience.state == .unsupported)
    let twoArg = CBCentralManager(delegate: nil, queue: probe.queue)
    precondition(twoArg.state == .unsupported)
    twoArg.delegate = probe
    _ = twoArg
}

private func exercisePeripheralManager() {
    precondition(CBPeripheralManager.authorizationStatus() == .denied)

    let probe = PeripheralManagerProbe()
    let manager = CBPeripheralManager(
        delegate: probe,
        queue: probe.queue,
        options: [CBPeripheralManagerOptionShowPowerAlertKey: false]
    )
    probe.manager = manager
    precondition(probe.stateSemaphore.wait(timeout: .now() + 2) == .success)
    precondition(manager.state == .unsupported)
    precondition(manager.authorization == .denied)
    precondition(!manager.isAdvertising)

    manager.startAdvertising([
        CBAdvertisementDataLocalNameKey: "linux-port",
        CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "180F")],
    ])
    precondition(probe.advertisingSemaphore.wait(timeout: .now() + 2) == .success)
    probe.lock.lock()
    let advertisingError = probe.advertisingError
    probe.lock.unlock()
    requireUnsupported(advertisingError)
    precondition(!manager.isAdvertising)
    manager.stopAdvertising()

    let service = CBMutableService(type: CBUUID(string: "180F"), primary: true)
    manager.add(service)
    precondition(probe.addServiceSemaphore.wait(timeout: .now() + 2) == .success)
    probe.lock.lock()
    let addError = probe.addServiceError
    probe.lock.unlock()
    requireUnsupported(addError)
    manager.remove(service)
    manager.removeAllServices()

    manager.publishL2CAPChannel(withEncryption: true)
    precondition(probe.publishSemaphore.wait(timeout: .now() + 2) == .success)
    probe.lock.lock()
    let publishError = probe.publishError
    probe.lock.unlock()
    requireUnsupported(publishError)
    manager.unpublishL2CAPChannel(0x0080)

    let characteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A19"),
        properties: [.read],
        value: Data([1]),
        permissions: [.readable]
    )
    precondition(!manager.updateValue(Data([2]), for: characteristic, onSubscribedCentrals: nil))

    let convenience = CBPeripheralManager()
    precondition(convenience.state == .unsupported)
    let twoArg = CBPeripheralManager(delegate: nil, queue: probe.queue)
    twoArg.delegate = probe
    _ = twoArg
}

exerciseConstants()
exerciseErrors()
exerciseEnumsAndOptionSets()
exerciseUUIDs()
exerciseMutableGATT()
exerciseCentralManager()
exercisePeripheralManager()
print("COREBLUETOOTH_AGENT_RUNTIME_OK")
