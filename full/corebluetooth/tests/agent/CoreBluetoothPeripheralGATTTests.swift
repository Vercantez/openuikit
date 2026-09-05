@_spi(OpenUIKitHost) import CoreBluetooth
import Dispatch
import Foundation

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
