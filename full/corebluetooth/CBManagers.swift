import Foundation
@preconcurrency import Dispatch
import CoreFoundation

@available(iOS 8.0, *)
open class CBPeer: NSObject {
    let _identifier: UUID

    open var identifier: UUID { _identifier }

    init(identifier: UUID) {
        _identifier = identifier
        super.init()
    }
}

@available(iOS 6.0, *)
open class CBCentral: CBPeer {
    let _maximumUpdateValueLength: Int

    open var maximumUpdateValueLength: Int { _maximumUpdateValueLength }

    init(identifier: UUID, maximumUpdateValueLength: Int = 20) {
        _maximumUpdateValueLength = maximumUpdateValueLength
        super.init(identifier: identifier)
    }

    @_spi(OpenUIKitHost)
    public convenience init(hostIdentifier identifier: UUID, maximumUpdateValueLength: Int = 20) {
        self.init(identifier: identifier, maximumUpdateValueLength: maximumUpdateValueLength)
    }
}

@available(iOS 5.0, *)
open class CBPeripheral: CBPeer {
    weak var _delegate: (any CBPeripheralDelegate)?
    var _name: String?
    var _state: CBPeripheralState = .disconnected
    var _services: [CBService]?
    var _rssi: NSNumber?
    var _canSendWriteWithoutResponse = false
    var _ancsAuthorized = false
    var _queue: DispatchQueue?
    var _simulated: CBHostSimulatedPeripheral?
    weak var _centralManager: CBCentralManager?

    open weak var delegate: (any CBPeripheralDelegate)? {
        get { _delegate }
        set { _delegate = newValue }
    }

    open var name: String? { _name }
    open var state: CBPeripheralState { _state }
    open var services: [CBService]? { _services }
    open var rssi: NSNumber? { _rssi }
    open var canSendWriteWithoutResponse: Bool { _canSendWriteWithoutResponse }
    open var ancsAuthorized: Bool { _ancsAuthorized }

    init(identifier: UUID, queue: DispatchQueue?) {
        _queue = queue
        super.init(identifier: identifier)
    }

    @_spi(OpenUIKitHost)
    public convenience init(hostIdentifier identifier: UUID, queue: DispatchQueue?) {
        self.init(identifier: identifier, queue: queue)
    }

    func _attachSimulated(_ simulated: CBHostSimulatedPeripheral, manager: CBCentralManager) {
        _simulated = simulated
        _centralManager = manager
        _queue = manager._queue
        _name = simulated.name
        _rssi = simulated.rssi
        _ancsAuthorized = simulated.ancsAuthorized
    }

    open func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        _whenConnected { peripheral in
            let templates = _CBFilterUUIDs(
                peripheral._simulated?.services ?? [],
                uuids: serviceUUIDs,
                uuid: { $0.uuid }
            )
            let materialized = templates.map { template in
                peripheral._materializeService(template)
            }
            peripheral._services = materialized
            peripheral._delegate?.peripheral(peripheral, didDiscoverServices: nil)
        } orFail: { delegate, peripheral, error in
            delegate.peripheral(peripheral, didDiscoverServices: error)
        }
    }

    open func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService) {
        _whenConnected(service: service) { peripheral, owned in
            let templates = _CBFilterUUIDs(
                owned._hostService?.includedServices ?? [],
                uuids: includedServiceUUIDs,
                uuid: { $0.uuid }
            )
            let materialized = templates.map { template in
                peripheral._materializeService(template)
            }
            owned._includedServices = materialized
            peripheral._delegate?.peripheral(
                peripheral,
                didDiscoverIncludedServicesFor: owned,
                error: nil
            )
        } orFail: { delegate, peripheral, error in
            delegate.peripheral(peripheral, didDiscoverIncludedServicesFor: service, error: error)
        }
    }

    open func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) {
        _whenConnected(service: service) { peripheral, owned in
            let templates = _CBFilterUUIDs(
                owned._hostService?.characteristics ?? [],
                uuids: characteristicUUIDs,
                uuid: { $0.uuid }
            )
            let materialized = templates.map { template -> CBCharacteristic in
                let characteristic = CBCharacteristic(
                    uuid: template.uuid,
                    properties: template.properties,
                    value: template.value
                )
                characteristic._service = owned
                characteristic._hostCharacteristic = template
                return characteristic
            }
            owned._characteristics = materialized
            peripheral._delegate?.peripheral(
                peripheral,
                didDiscoverCharacteristicsFor: owned,
                error: nil
            )
        } orFail: { delegate, peripheral, error in
            delegate.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        }
    }

    open func discoverDescriptors(for characteristic: CBCharacteristic) {
        _whenConnected(characteristic: characteristic) { peripheral, owned in
            let templates = owned._hostCharacteristic?.descriptors ?? []
            let materialized = templates.map { template -> CBDescriptor in
                let descriptor = CBDescriptor(uuid: template.uuid, value: template.value)
                descriptor._characteristic = owned
                descriptor._hostDescriptor = template
                return descriptor
            }
            owned._descriptors = materialized
            peripheral._delegate?.peripheral(
                peripheral,
                didDiscoverDescriptorsFor: owned,
                error: nil
            )
        } orFail: { delegate, peripheral, error in
            delegate.peripheral(peripheral, didDiscoverDescriptorsFor: characteristic, error: error)
        }
    }

    open func readValue(for characteristic: CBCharacteristic) {
        _whenConnected(characteristic: characteristic) { peripheral, owned in
            guard owned.properties.contains(.read) else {
                peripheral._delegate?.peripheral(
                    peripheral,
                    didUpdateValueFor: owned,
                    error: CBATTError(.readNotPermitted)
                )
                return
            }
            owned._value = owned._hostCharacteristic?.value
            peripheral._delegate?.peripheral(peripheral, didUpdateValueFor: owned, error: nil)
        } orFail: { delegate, peripheral, error in
            delegate.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
        }
    }

    open func readValue(for descriptor: CBDescriptor) {
        _whenConnected(descriptor: descriptor) { peripheral, owned in
            owned._value = owned._hostDescriptor?.value ?? owned._value
            peripheral._delegate?.peripheral(peripheral, didUpdateValueFor: owned, error: nil)
        } orFail: { delegate, peripheral, error in
            delegate.peripheral(peripheral, didUpdateValueFor: descriptor, error: error)
        }
    }

    open func writeValue(
        _ data: Data,
        for characteristic: CBCharacteristic,
        type: CBCharacteristicWriteType
    ) {
        let maxLength = maximumWriteValueLength(for: type)
        switch type {
        case .withResponse:
            _whenConnected(characteristic: characteristic) { peripheral, owned in
                if data.count > maxLength {
                    peripheral._delegate?.peripheral(
                        peripheral,
                        didWriteValueFor: owned,
                        error: CBError(.invalidParameters)
                    )
                    return
                }
                guard owned.properties.contains(.write) else {
                    peripheral._delegate?.peripheral(
                        peripheral,
                        didWriteValueFor: owned,
                        error: CBATTError(.writeNotPermitted)
                    )
                    return
                }
                owned._value = data
                owned._hostCharacteristic?.value = data
                peripheral._delegate?.peripheral(peripheral, didWriteValueFor: owned, error: nil)
            } orFail: { delegate, peripheral, error in
                delegate.peripheral(peripheral, didWriteValueFor: characteristic, error: error)
            }
        case .withoutResponse:
            guard _state == .connected, _simulated != nil else { return }
            guard data.count <= maxLength else { return }
            guard characteristic.properties.contains(.writeWithoutResponse) else { return }
            _CBDispatch(_queue) { [weak self] in
                guard let self, self._state == .connected else { return }
                characteristic._value = data
                characteristic._hostCharacteristic?.value = data
                self._canSendWriteWithoutResponse = false
                self._delegate?.peripheralIsReady(toSendWriteWithoutResponse: self)
                self._canSendWriteWithoutResponse = true
            }
        }
    }

    open func writeValue(_ data: Data, for descriptor: CBDescriptor) {
        _whenConnected(descriptor: descriptor) { peripheral, owned in
            owned._value = data
            owned._hostDescriptor?.value = data
            peripheral._delegate?.peripheral(peripheral, didWriteValueFor: owned, error: nil)
        } orFail: { delegate, peripheral, error in
            delegate.peripheral(peripheral, didWriteValueFor: descriptor, error: error)
        }
    }

    open func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        _whenConnected(characteristic: characteristic) { peripheral, owned in
            let canNotify = owned.properties.contains(.notify)
                || owned.properties.contains(.indicate)
            guard canNotify else {
                owned._isNotifying = false
                peripheral._delegate?.peripheral(
                    peripheral,
                    didUpdateNotificationStateFor: owned,
                    error: CBError(.invalidParameters)
                )
                return
            }
            owned._isNotifying = enabled
            peripheral._delegate?.peripheral(
                peripheral,
                didUpdateNotificationStateFor: owned,
                error: nil
            )
            if enabled, let payload = owned._hostCharacteristic?.notifyPayload {
                owned._value = payload
                owned._hostCharacteristic?.value = payload
                peripheral._delegate?.peripheral(peripheral, didUpdateValueFor: owned, error: nil)
            }
        } orFail: { delegate, peripheral, error in
            delegate.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
        }
    }

    open func readRSSI() {
        _whenConnected { peripheral in
            let rssi = peripheral._simulated?.rssi ?? 0
            peripheral._rssi = rssi
            peripheral._delegate?.peripheral(peripheral, didReadRSSI: rssi, error: nil)
            peripheral._delegate?.peripheralDidUpdateRSSI(peripheral, error: nil)
        } orFail: { delegate, peripheral, error in
            delegate.peripheral(peripheral, didReadRSSI: 0, error: error)
        }
    }

    open func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        guard _state == .connected, let simulated = _simulated else { return 0 }
        switch type {
        case .withResponse:
            return simulated.maximumWriteWithResponse
        case .withoutResponse:
            return simulated.maximumWriteWithoutResponse
        }
    }

    open func openL2CAPChannel(_ PSM: CBL2CAPPSM) {
        _ = PSM
        _notify { delegate, peripheral in
            delegate.peripheral(peripheral, didOpen: nil, error: _CBUnsupportedError())
        }
    }

    @_spi(OpenUIKitHost)
    public func _hostSetName(_ name: String?) {
        _name = name
        _simulated?.name = name
        _notify { delegate, peripheral in
            delegate.peripheralDidUpdateName(peripheral)
        }
    }

    @_spi(OpenUIKitHost)
    public func _hostInvalidateServices(_ services: [CBService]) {
        _notify { delegate, peripheral in
            delegate.peripheral(peripheral, didModifyServices: services)
        }
    }

    private func _materializeService(_ template: CBHostSimulatedService) -> CBService {
        if let existing = _services?.first(where: { $0._hostService === template }) {
            return existing
        }
        let service = CBService(uuid: template.uuid, primary: template.isPrimary)
        service._peripheral = self
        service._hostService = template
        return service
    }

    private func _notify(_ body: @escaping (any CBPeripheralDelegate, CBPeripheral) -> Void) {
        _CBDispatch(_queue) { [weak self] in
            guard let self, let delegate = self._delegate else { return }
            body(delegate, self)
        }
    }

    private func _fail(_ error: CBError, _ body: @escaping (any CBPeripheralDelegate, CBPeripheral, CBError) -> Void) {
        _notify { delegate, peripheral in
            body(delegate, peripheral, error)
        }
    }

    private func _connectionError() -> CBError {
        _state == .connected ? _CBUnsupportedError() : CBError(.notConnected)
    }

    private func _whenConnected(
        _ body: @escaping (CBPeripheral) -> Void,
        orFail: @escaping (any CBPeripheralDelegate, CBPeripheral, CBError) -> Void
    ) {
        guard _state == .connected, _simulated != nil else {
            _fail(_connectionError(), orFail)
            return
        }
        _CBDispatch(_queue) { [weak self] in
            guard let self, self._state == .connected else { return }
            body(self)
        }
    }

    private func _whenConnected(
        service: CBService,
        _ body: @escaping (CBPeripheral, CBService) -> Void,
        orFail: @escaping (any CBPeripheralDelegate, CBPeripheral, CBError) -> Void
    ) {
        guard _state == .connected, _simulated != nil else {
            _fail(_connectionError(), orFail)
            return
        }
        guard service._peripheral === self else {
            _fail(CBError(.invalidHandle), orFail)
            return
        }
        _CBDispatch(_queue) { [weak self] in
            guard let self, self._state == .connected else { return }
            body(self, service)
        }
    }

    private func _whenConnected(
        characteristic: CBCharacteristic,
        _ body: @escaping (CBPeripheral, CBCharacteristic) -> Void,
        orFail: @escaping (any CBPeripheralDelegate, CBPeripheral, CBError) -> Void
    ) {
        guard _state == .connected, _simulated != nil else {
            _fail(_connectionError(), orFail)
            return
        }
        _CBDispatch(_queue) { [weak self] in
            guard let self, self._state == .connected else { return }
            body(self, characteristic)
        }
    }

    private func _whenConnected(
        descriptor: CBDescriptor,
        _ body: @escaping (CBPeripheral, CBDescriptor) -> Void,
        orFail: @escaping (any CBPeripheralDelegate, CBPeripheral, CBError) -> Void
    ) {
        guard _state == .connected, _simulated != nil else {
            _fail(_connectionError(), orFail)
            return
        }
        _CBDispatch(_queue) { [weak self] in
            guard let self, self._state == .connected else { return }
            body(self, descriptor)
        }
    }
}

@available(iOS 11.0, *)
open class CBL2CAPChannel: NSObject {
    let _peer: CBPeer
    let _psm: CBL2CAPPSM
    let _inputStream: InputStream
    let _outputStream: OutputStream

    open var peer: CBPeer! { _peer }
    open var psm: CBL2CAPPSM { _psm }
    open var inputStream: InputStream! { _inputStream }
    open var outputStream: OutputStream! { _outputStream }

    init(peer: CBPeer, psm: CBL2CAPPSM, inputStream: InputStream, outputStream: OutputStream) {
        _peer = peer
        _psm = psm
        _inputStream = inputStream
        _outputStream = outputStream
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostPeer peer: CBPeer,
        psm: CBL2CAPPSM,
        inputStream: InputStream,
        outputStream: OutputStream
    ) {
        self.init(peer: peer, psm: psm, inputStream: inputStream, outputStream: outputStream)
    }
}

@available(iOS 10.0, *)
open class CBManager: NSObject {
    var _state: CBManagerState = .unknown

    open class var authorization: CBManagerAuthorization { .denied }
    open var authorization: CBManagerAuthorization { .denied }
    open var state: CBManagerState { _state }
}

@available(iOS 5.0, *)
open class CBCentralManager: CBManager {
    public struct Feature: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let extendedScanAndConnect = Feature(rawValue: 1 << 0)
    }

    let _queue: DispatchQueue?
    private let _lock = NSLock()
    private weak var _delegate: (any CBCentralManagerDelegate)?
    private var _isScanning = false
    private weak var _stateRecipient: AnyObject?
    private let _adapter: CBHostSimulatedAdapter?
    private let _options: [String: Any]?
    private var _didRestore = false
    private var _scanGeneration = 0
    private var _reportedScanIdentifiers = Set<UUID>()
    private var _knownPeripherals: [UUID: CBPeripheral] = [:]
    private var _connectionEventOptions: [CBConnectionEventMatchingOption: Any]?
    private var _connectionEventsRegistered = false

    open weak var delegate: (any CBCentralManagerDelegate)? {
        get {
            _lock.lock()
            defer { _lock.unlock() }
            return _delegate
        }
        set {
            _lock.lock()
            _delegate = newValue
            _lock.unlock()
            _emitStateIfNeeded()
        }
    }

    open var isScanning: Bool {
        _lock.lock()
        defer { _lock.unlock() }
        return _isScanning
    }

    public convenience override init() {
        self.init(delegate: nil, queue: nil, options: nil)
    }

    public convenience init(delegate: (any CBCentralManagerDelegate)?, queue: DispatchQueue?) {
        self.init(delegate: delegate, queue: queue, options: nil)
    }

    public init(
        delegate: (any CBCentralManagerDelegate)?,
        queue: DispatchQueue?,
        options: [String: Any]? = nil
    ) {
        _queue = queue
        _adapter = CBHostSimulation.adapter
        _options = options
        super.init()
        // Linux has no radio to query. The documented machine is
        // `.unknown` → `.unsupported`, or `.unknown` → the simulated
        // adapter's state (typically `.poweredOn`). Settle before init
        // returns so `state` is readable without draining a queue.
        _state = _adapter?.state ?? .unsupported
        self.delegate = delegate
    }

    open class func supports(_ features: Feature) -> Bool {
        _ = features
        return false
    }

    open func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]? = nil) {
        _lock.lock()
        let poweredOn = _state == .poweredOn && _adapter != nil
        if !poweredOn {
            _isScanning = false
            _lock.unlock()
            return
        }
        _scanGeneration += 1
        let generation = _scanGeneration
        _reportedScanIdentifiers.removeAll()
        _isScanning = true
        let allowDuplicates = _CBOptionFlag(options, key: CBCentralManagerScanOptionAllowDuplicatesKey)
        let adapter = _adapter
        _lock.unlock()

        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._deliverScan(
                generation: generation,
                serviceUUIDs: serviceUUIDs,
                allowDuplicates: allowDuplicates,
                adapter: adapter
            )
        }
    }

    open func stopScan() {
        _lock.lock()
        _isScanning = false
        _scanGeneration += 1
        _lock.unlock()
    }

    open func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral] {
        guard let adapter = _adapter, _state == .poweredOn else { return [] }
        return identifiers.compactMap { identifier in
            adapter.peripherals.first(where: { $0.identifier == identifier }).map {
                self._peripheral(for: $0)
            }
        }
    }

    open func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral] {
        guard _adapter != nil, _state == .poweredOn else { return [] }
        _lock.lock()
        let connected = _knownPeripherals.values.filter { $0._state == .connected }
        _lock.unlock()
        return connected.filter { peripheral in
            let advertised = (peripheral._simulated?.advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
            let gatt = peripheral._simulated?.services.map(\.uuid) ?? []
            return serviceUUIDs.contains { wanted in
                advertised.contains(where: { $0 == wanted }) || gatt.contains(where: { $0 == wanted })
            }
        }
    }

    open func connect(_ peripheral: CBPeripheral, options: [String: Any]? = nil) {
        _ = options
        guard _state == .poweredOn, _adapter != nil else {
            peripheral._state = .disconnected
            _CBDispatch(_queue) { [weak self] in
                guard let self else { return }
                self._currentDelegate()?.centralManager(
                    self,
                    didFailToConnect: peripheral,
                    error: _CBUnsupportedError()
                )
            }
            return
        }
        if peripheral._state == .connected || peripheral._state == .connecting {
            return
        }
        let simulated = peripheral._simulated
            ?? _adapter?.peripherals.first(where: { $0.identifier == peripheral.identifier })
        guard let simulated, simulated.connectable else {
            peripheral._state = .disconnected
            _CBDispatch(_queue) { [weak self] in
                guard let self else { return }
                self._currentDelegate()?.centralManager(
                    self,
                    didFailToConnect: peripheral,
                    error: CBError(.connectionFailed)
                )
            }
            return
        }
        peripheral._attachSimulated(simulated, manager: self)
        peripheral._state = .connecting
        _lock.lock()
        _knownPeripherals[peripheral.identifier] = peripheral
        _lock.unlock()
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            guard peripheral._state == .connecting else { return }
            peripheral._state = .connected
            peripheral._canSendWriteWithoutResponse = true
            let delegate = self._currentDelegate()
            delegate?.centralManager(self, didConnect: peripheral)
            if self._connectionEventsRegistered {
                delegate?.centralManager(self, connectionEventDidOccur: .peerConnected, for: peripheral)
            }
            if peripheral._ancsAuthorized {
                delegate?.centralManager(self, didUpdateANCSAuthorizationFor: peripheral)
            }
        }
    }

    open func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        switch peripheral._state {
        case .disconnected:
            return
        case .connecting:
            peripheral._state = .disconnected
            _CBDispatch(_queue) { [weak self] in
                guard let self else { return }
                self._currentDelegate()?.centralManager(
                    self,
                    didFailToConnect: peripheral,
                    error: CBError(.operationCancelled)
                )
            }
        case .connected, .disconnecting:
            peripheral._state = .disconnecting
            _CBDispatch(_queue) { [weak self] in
                guard let self else { return }
                peripheral._state = .disconnected
                peripheral._canSendWriteWithoutResponse = false
                let delegate = self._currentDelegate()
                let error: (any Error)? = nil
                delegate?.centralManager(self, didDisconnectPeripheral: peripheral, error: error)
                delegate?.centralManager(
                    self,
                    didDisconnectPeripheral: peripheral,
                    timestamp: CFAbsoluteTimeGetCurrent(),
                    isReconnecting: false,
                    error: error
                )
                if self._connectionEventsRegistered {
                    delegate?.centralManager(
                        self,
                        connectionEventDidOccur: .peerDisconnected,
                        for: peripheral
                    )
                }
            }
        }
    }

    open func registerForConnectionEvents(options: [CBConnectionEventMatchingOption: Any]? = nil) {
        _lock.lock()
        _connectionEventOptions = options
        _connectionEventsRegistered = true
        _lock.unlock()
    }

    private func _currentDelegate() -> (any CBCentralManagerDelegate)? {
        _lock.lock()
        defer { _lock.unlock() }
        return _delegate
    }

    private func _peripheral(for simulated: CBHostSimulatedPeripheral) -> CBPeripheral {
        _lock.lock()
        if let existing = _knownPeripherals[simulated.identifier] {
            existing._attachSimulated(simulated, manager: self)
            _lock.unlock()
            return existing
        }
        _lock.unlock()
        let peripheral = CBPeripheral(identifier: simulated.identifier, queue: _queue)
        peripheral._attachSimulated(simulated, manager: self)
        _lock.lock()
        _knownPeripherals[simulated.identifier] = peripheral
        _lock.unlock()
        return peripheral
    }

    private func _advertisedServiceUUIDs(_ advertisement: [String: Any]) -> [CBUUID] {
        var uuids: [CBUUID] = []
        if let listed = advertisement[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            uuids.append(contentsOf: listed)
        }
        if let overflow = advertisement[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] {
            uuids.append(contentsOf: overflow)
        }
        if let solicited = advertisement[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID] {
            uuids.append(contentsOf: solicited)
        }
        return uuids
    }

    private func _deliverScan(
        generation: Int,
        serviceUUIDs: [CBUUID]?,
        allowDuplicates: Bool,
        adapter: CBHostSimulatedAdapter?
    ) {
        guard let adapter else { return }
        let matches = adapter.peripherals.filter { simulated in
            guard let wanted = serviceUUIDs, !wanted.isEmpty else { return true }
            let advertised = _advertisedServiceUUIDs(simulated.advertisementData)
            return wanted.contains { needle in
                advertised.contains(where: { $0 == needle })
            }
        }
        let deliveries = allowDuplicates ? matches + matches : matches
        for simulated in deliveries {
            _lock.lock()
            let scanning = _isScanning && _scanGeneration == generation
            let already = _reportedScanIdentifiers.contains(simulated.identifier)
            if scanning && (allowDuplicates || !already) {
                _reportedScanIdentifiers.insert(simulated.identifier)
            }
            _lock.unlock()
            guard scanning else { return }
            if !allowDuplicates && already { continue }
            let peripheral = _peripheral(for: simulated)
            _currentDelegate()?.centralManager(
                self,
                didDiscover: peripheral,
                advertisementData: simulated.advertisementData,
                rssi: simulated.rssi
            )
        }
    }

    private func _emitStateIfNeeded() {
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._lock.lock()
            let delegate = self._delegate
            let recipient = delegate as AnyObject?
            let already = recipient != nil && recipient === self._stateRecipient
            self._stateRecipient = recipient
            let shouldRestore = !self._didRestore
                && self._options?[CBCentralManagerOptionRestoreIdentifierKey] != nil
            if shouldRestore {
                self._didRestore = true
            }
            let restored = self._adapter?.restoredCentralState
            self._lock.unlock()
            guard let delegate else { return }
            if shouldRestore {
                let dictionary = restored ?? [
                    CBCentralManagerRestoredStatePeripheralsKey: [CBPeripheral](),
                    CBCentralManagerRestoredStateScanServicesKey: [CBUUID](),
                    CBCentralManagerRestoredStateScanOptionsKey: [String: Any](),
                ]
                delegate.centralManager(self, willRestoreState: dictionary)
            }
            guard !already else { return }
            delegate.centralManagerDidUpdateState(self)
        }
    }
}

@available(iOS 6.0, *)
open class CBPeripheralManager: CBManager {
    private let _queue: DispatchQueue?
    private let _lock = NSLock()
    private weak var _delegate: (any CBPeripheralManagerDelegate)?
    private var _isAdvertising = false
    private weak var _stateRecipient: AnyObject?
    private let _adapter: CBHostSimulatedAdapter?
    private let _options: [String: Any]?
    private var _didRestore = false
    private var _services: [CBMutableService] = []
    private var _pendingATT: [ObjectIdentifier: CBATTRequest] = [:]
    var _hostLastATTResult: CBATTError.Code?

    open weak var delegate: (any CBPeripheralManagerDelegate)? {
        get {
            _lock.lock()
            defer { _lock.unlock() }
            return _delegate
        }
        set {
            _lock.lock()
            _delegate = newValue
            _lock.unlock()
            _emitStateIfNeeded()
        }
    }

    open var isAdvertising: Bool {
        _lock.lock()
        defer { _lock.unlock() }
        return _isAdvertising
    }

    public convenience override init() {
        self.init(delegate: nil, queue: nil, options: nil)
    }

    public convenience init(delegate: (any CBPeripheralManagerDelegate)?, queue: DispatchQueue?) {
        self.init(delegate: delegate, queue: queue, options: nil)
    }

    public init(
        delegate: (any CBPeripheralManagerDelegate)?,
        queue: DispatchQueue?,
        options: [String: Any]? = nil
    ) {
        _queue = queue
        _adapter = CBHostSimulation.adapter
        _options = options
        super.init()
        _state = _adapter?.state ?? .unsupported
        self.delegate = delegate
    }

    open class func authorizationStatus() -> CBPeripheralManagerAuthorizationStatus {
        .denied
    }

    open func startAdvertising(_ advertisementData: [String: Any]?) {
        _ = advertisementData
        guard _state == .poweredOn, _adapter != nil else {
            _lock.lock()
            _isAdvertising = false
            _lock.unlock()
            _CBDispatch(_queue) { [weak self] in
                guard let self else { return }
                self._currentDelegate()?.peripheralManagerDidStartAdvertising(
                    self,
                    error: _CBUnsupportedError()
                )
            }
            return
        }
        _lock.lock()
        if _isAdvertising {
            _lock.unlock()
            _CBDispatch(_queue) { [weak self] in
                guard let self else { return }
                self._currentDelegate()?.peripheralManagerDidStartAdvertising(
                    self,
                    error: CBError(.alreadyAdvertising)
                )
            }
            return
        }
        _isAdvertising = true
        _lock.unlock()
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._currentDelegate()?.peripheralManagerDidStartAdvertising(self, error: nil)
        }
    }

    open func stopAdvertising() {
        _lock.lock()
        _isAdvertising = false
        _lock.unlock()
    }

    open func add(_ service: CBMutableService) {
        guard _state == .poweredOn, _adapter != nil else {
            _CBDispatch(_queue) { [weak self] in
                guard let self else { return }
                self._currentDelegate()?.peripheralManager(
                    self,
                    didAdd: service,
                    error: _CBUnsupportedError()
                )
            }
            return
        }
        _lock.lock()
        _services.append(service)
        _lock.unlock()
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._currentDelegate()?.peripheralManager(self, didAdd: service, error: nil)
        }
    }

    open func remove(_ service: CBMutableService) {
        _lock.lock()
        _services.removeAll { $0 === service }
        _lock.unlock()
    }

    open func removeAllServices() {
        _lock.lock()
        _services.removeAll()
        _lock.unlock()
    }

    open func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        _lock.lock()
        _pendingATT.removeValue(forKey: ObjectIdentifier(request))
        _hostLastATTResult = result
        _lock.unlock()
        if result == .success, let value = request.value {
            if let mutable = request.characteristic as? CBMutableCharacteristic {
                mutable.value = value
            } else {
                request.characteristic._value = value
            }
        }
    }

    open func updateValue(
        _ value: Data,
        for characteristic: CBMutableCharacteristic,
        onSubscribedCentrals centrals: [CBCentral]?
    ) -> Bool {
        guard _state == .poweredOn, _adapter != nil else { return false }
        characteristic.value = value
        let subscribers = characteristic._subscribedCentrals ?? []
        let targets: [CBCentral]
        if let centrals, !centrals.isEmpty {
            targets = subscribers.filter { subscriber in
                centrals.contains(where: { $0 === subscriber })
            }
            if targets.isEmpty && !subscribers.isEmpty {
                return false
            }
        } else {
            targets = subscribers
        }
        if let maxLength = targets.map(\.maximumUpdateValueLength).min(), value.count > maxLength {
            _CBDispatch(_queue) { [weak self] in
                guard let self else { return }
                self._currentDelegate()?.peripheralManagerIsReady(toUpdateSubscribers: self)
            }
            return false
        }
        return true
    }

    open func setDesiredConnectionLatency(
        _ latency: CBPeripheralManagerConnectionLatency,
        for central: CBCentral
    ) {
        _ = (latency, central)
    }

    open func publishL2CAPChannel(withEncryption encryptionRequired: Bool) {
        _ = encryptionRequired
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._currentDelegate()?.peripheralManager(
                self,
                didPublishL2CAPChannel: 0,
                error: _CBUnsupportedError()
            )
        }
    }

    open func unpublishL2CAPChannel(_ PSM: CBL2CAPPSM) {
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._currentDelegate()?.peripheralManager(
                self,
                didUnpublishL2CAPChannel: PSM,
                error: _CBUnsupportedError()
            )
        }
    }

    @_spi(OpenUIKitHost)
    public func _hostInjectReadRequest(
        _ request: CBATTRequest
    ) {
        _lock.lock()
        _pendingATT[ObjectIdentifier(request)] = request
        _lock.unlock()
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._currentDelegate()?.peripheralManager(self, didReceiveRead: request)
        }
    }

    @_spi(OpenUIKitHost)
    public func _hostInjectWriteRequests(_ requests: [CBATTRequest]) {
        for request in requests {
            _lock.lock()
            _pendingATT[ObjectIdentifier(request)] = request
            _lock.unlock()
        }
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._currentDelegate()?.peripheralManager(self, didReceiveWrite: requests)
        }
    }

    @_spi(OpenUIKitHost)
    public func _hostSubscribe(_ central: CBCentral, to characteristic: CBMutableCharacteristic) {
        var subscribers = characteristic._subscribedCentrals ?? []
        if !subscribers.contains(where: { $0 === central }) {
            subscribers.append(central)
        }
        characteristic._subscribedCentrals = subscribers
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._currentDelegate()?.peripheralManager(
                self,
                central: central,
                didSubscribeTo: characteristic
            )
        }
    }

    @_spi(OpenUIKitHost)
    public func _hostUnsubscribe(_ central: CBCentral, from characteristic: CBMutableCharacteristic) {
        characteristic._subscribedCentrals?.removeAll { $0 === central }
        if characteristic._subscribedCentrals?.isEmpty == true {
            characteristic._subscribedCentrals = nil
        }
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._currentDelegate()?.peripheralManager(
                self,
                central: central,
                didUnsubscribeFrom: characteristic
            )
        }
    }

    @_spi(OpenUIKitHost)
    public var _hostATTResult: CBATTError.Code? {
        _lock.lock()
        defer { _lock.unlock() }
        return _hostLastATTResult
    }

    @_spi(OpenUIKitHost)
    public func _hostOpenL2CAPChannel(_ channel: CBL2CAPChannel?, error: (any Error)?) {
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._currentDelegate()?.peripheralManager(self, didOpen: channel, error: error)
        }
    }

    private func _currentDelegate() -> (any CBPeripheralManagerDelegate)? {
        _lock.lock()
        defer { _lock.unlock() }
        return _delegate
    }

    private func _emitStateIfNeeded() {
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._lock.lock()
            let delegate = self._delegate
            let recipient = delegate as AnyObject?
            let already = recipient != nil && recipient === self._stateRecipient
            self._stateRecipient = recipient
            let shouldRestore = !self._didRestore
                && self._options?[CBPeripheralManagerOptionRestoreIdentifierKey] != nil
            if shouldRestore {
                self._didRestore = true
            }
            let restored = self._adapter?.restoredPeripheralState
            self._lock.unlock()
            guard let delegate else { return }
            if shouldRestore {
                let dictionary = restored ?? [
                    CBPeripheralManagerRestoredStateServicesKey: [CBMutableService](),
                    CBPeripheralManagerRestoredStateAdvertisementDataKey: [String: Any](),
                ]
                delegate.peripheralManager(self, willRestoreState: dictionary)
            }
            guard !already else { return }
            delegate.peripheralManagerDidUpdateState(self)
        }
    }
}

public protocol CBCentralManagerDelegate: NSObjectProtocol {
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any])
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    )
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: (any Error)?
    )
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    )
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: (any Error)?
    )
    func centralManager(
        _ central: CBCentralManager,
        connectionEventDidOccur event: CBConnectionEvent,
        for peripheral: CBPeripheral
    )
    func centralManager(
        _ central: CBCentralManager,
        didUpdateANCSAuthorizationFor peripheral: CBPeripheral
    )
}

extension CBCentralManagerDelegate {
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        _ = (central, dict)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        _ = (central, peripheral, advertisementData, RSSI)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        _ = (central, peripheral)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        _ = (central, peripheral, error)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        _ = (central, peripheral, error)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: (any Error)?
    ) {
        _ = (central, peripheral, timestamp, isReconnecting, error)
    }

    public func centralManager(
        _ central: CBCentralManager,
        connectionEventDidOccur event: CBConnectionEvent,
        for peripheral: CBPeripheral
    ) {
        _ = (central, event, peripheral)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didUpdateANCSAuthorizationFor peripheral: CBPeripheral
    ) {
        _ = (central, peripheral)
    }
}

public protocol CBPeripheralDelegate: NSObjectProtocol {
    func peripheralDidUpdateName(_ peripheral: CBPeripheral)
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService])
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?)
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: (any Error)?
    )
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: (any Error)?
    )
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    )
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    )
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: (any Error)?
    )
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: (any Error)?
    )
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: (any Error)?
    )
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor descriptor: CBDescriptor,
        error: (any Error)?
    )
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral)
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: (any Error)?)
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: (any Error)?)
}

extension CBPeripheralDelegate {
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        _ = peripheral
    }

    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        _ = (peripheral, invalidatedServices)
    }

    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?) {
        _ = (peripheral, RSSI, error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        _ = (peripheral, error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: (any Error)?
    ) {
        _ = (peripheral, service, error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: (any Error)?
    ) {
        _ = (peripheral, service, error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        _ = (peripheral, characteristic, error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        _ = (peripheral, characteristic, error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        _ = (peripheral, characteristic, error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        _ = (peripheral, characteristic, error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: (any Error)?
    ) {
        _ = (peripheral, descriptor, error)
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor descriptor: CBDescriptor,
        error: (any Error)?
    ) {
        _ = (peripheral, descriptor, error)
    }

    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        _ = peripheral
    }

    public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: (any Error)?) {
        _ = (peripheral, channel, error)
    }

    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: (any Error)?) {
        _ = (peripheral, error)
    }
}

public protocol CBPeripheralManagerDelegate: NSObjectProtocol {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any])
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?)
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: (any Error)?
    )
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    )
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    )
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest)
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest])
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager)
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didPublishL2CAPChannel PSM: CBL2CAPPSM,
        error: (any Error)?
    )
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didUnpublishL2CAPChannel PSM: CBL2CAPPSM,
        error: (any Error)?
    )
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didOpen channel: CBL2CAPChannel?,
        error: (any Error)?
    )
}

extension CBPeripheralManagerDelegate {
    public func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        _ = (peripheral, dict)
    }

    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
        _ = (peripheral, error)
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: (any Error)?
    ) {
        _ = (peripheral, service, error)
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        _ = (peripheral, central, characteristic)
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        _ = (peripheral, central, characteristic)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        _ = (peripheral, request)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        _ = (peripheral, requests)
    }

    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        _ = peripheral
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didPublishL2CAPChannel PSM: CBL2CAPPSM,
        error: (any Error)?
    ) {
        _ = (peripheral, PSM, error)
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didUnpublishL2CAPChannel PSM: CBL2CAPPSM,
        error: (any Error)?
    ) {
        _ = (peripheral, PSM, error)
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didOpen channel: CBL2CAPChannel?,
        error: (any Error)?
    ) {
        _ = (peripheral, channel, error)
    }
}
