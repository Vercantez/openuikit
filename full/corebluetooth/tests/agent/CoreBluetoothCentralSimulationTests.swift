@_spi(OpenUIKitHost) import CoreBluetooth
import Dispatch
import Foundation

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
