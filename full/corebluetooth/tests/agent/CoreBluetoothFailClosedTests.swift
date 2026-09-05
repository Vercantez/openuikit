@_spi(OpenUIKitHost) import CoreBluetooth
import Dispatch
import Foundation

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
