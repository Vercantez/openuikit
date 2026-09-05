@_spi(OpenUIKitHost) import CoreBluetooth
import Dispatch
import Foundation

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
