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

    open func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        _ = serviceUUIDs
        _fail { $0.peripheral($1, didDiscoverServices: _CBUnsupportedError()) }
    }

    open func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService) {
        _ = includedServiceUUIDs
        _fail { $0.peripheral($1, didDiscoverIncludedServicesFor: service, error: _CBUnsupportedError()) }
    }

    open func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) {
        _ = characteristicUUIDs
        _fail { $0.peripheral($1, didDiscoverCharacteristicsFor: service, error: _CBUnsupportedError()) }
    }

    open func discoverDescriptors(for characteristic: CBCharacteristic) {
        _fail { $0.peripheral($1, didDiscoverDescriptorsFor: characteristic, error: _CBUnsupportedError()) }
    }

    open func readValue(for characteristic: CBCharacteristic) {
        _fail { $0.peripheral($1, didUpdateValueFor: characteristic, error: _CBUnsupportedError()) }
    }

    open func readValue(for descriptor: CBDescriptor) {
        _fail { $0.peripheral($1, didUpdateValueFor: descriptor, error: _CBUnsupportedError()) }
    }

    open func writeValue(
        _ data: Data,
        for characteristic: CBCharacteristic,
        type: CBCharacteristicWriteType
    ) {
        _ = data
        switch type {
        case .withResponse:
            _fail { $0.peripheral($1, didWriteValueFor: characteristic, error: _CBUnsupportedError()) }
        case .withoutResponse:
            break
        }
    }

    open func writeValue(_ data: Data, for descriptor: CBDescriptor) {
        _ = data
        _fail { $0.peripheral($1, didWriteValueFor: descriptor, error: _CBUnsupportedError()) }
    }

    open func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        _ = enabled
        characteristic._isNotifying = false
        _fail { $0.peripheral($1, didUpdateNotificationStateFor: characteristic, error: _CBUnsupportedError()) }
    }

    open func readRSSI() {
        _fail { $0.peripheral($1, didReadRSSI: 0, error: _CBUnsupportedError()) }
    }

    open func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        _ = type
        return 0
    }

    open func openL2CAPChannel(_ PSM: CBL2CAPPSM) {
        _ = PSM
        _fail { $0.peripheral($1, didOpen: nil, error: _CBUnsupportedError()) }
    }

    private func _fail(_ body: @escaping (any CBPeripheralDelegate, CBPeripheral) -> Void) {
        _CBDispatch(_queue) { [weak self] in
            guard let self, let delegate = self._delegate else { return }
            body(delegate, self)
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
}

@available(iOS 10.0, *)
open class CBManager: NSObject {
    open class var authorization: CBManagerAuthorization { .denied }
    open var authorization: CBManagerAuthorization { .denied }
    open var state: CBManagerState { .unsupported }
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

    private let _queue: DispatchQueue?
    private let _lock = NSLock()
    private weak var _delegate: (any CBCentralManagerDelegate)?
    private var _isScanning = false
    private weak var _stateRecipient: AnyObject?

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
        super.init()
        _ = options
        self.delegate = delegate
    }

    open class func supports(_ features: Feature) -> Bool {
        _ = features
        return false
    }

    open func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]? = nil) {
        _ = (serviceUUIDs, options)
        _lock.lock()
        _isScanning = false
        _lock.unlock()
    }

    open func stopScan() {
        _lock.lock()
        _isScanning = false
        _lock.unlock()
    }

    open func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral] {
        _ = identifiers
        return []
    }

    open func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral] {
        _ = serviceUUIDs
        return []
    }

    open func connect(_ peripheral: CBPeripheral, options: [String: Any]? = nil) {
        _ = options
        peripheral._state = .disconnected
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._lock.lock()
            let delegate = self._delegate
            self._lock.unlock()
            delegate?.centralManager(
                self,
                didFailToConnect: peripheral,
                error: _CBUnsupportedError()
            )
        }
    }

    open func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        _ = peripheral
    }

    open func registerForConnectionEvents(options: [CBConnectionEventMatchingOption: Any]? = nil) {
        _ = options
    }

    private func _emitStateIfNeeded() {
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._lock.lock()
            let delegate = self._delegate
            let recipient = delegate as AnyObject?
            let already = recipient != nil && recipient === self._stateRecipient
            self._stateRecipient = recipient
            self._lock.unlock()
            guard !already, let delegate else { return }
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
        super.init()
        _ = options
        self.delegate = delegate
    }

    open class func authorizationStatus() -> CBPeripheralManagerAuthorizationStatus {
        .denied
    }

    open func startAdvertising(_ advertisementData: [String: Any]?) {
        _ = advertisementData
        _lock.lock()
        _isAdvertising = false
        _lock.unlock()
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._lock.lock()
            let delegate = self._delegate
            self._lock.unlock()
            delegate?.peripheralManagerDidStartAdvertising(self, error: _CBUnsupportedError())
        }
    }

    open func stopAdvertising() {
        _lock.lock()
        _isAdvertising = false
        _lock.unlock()
    }

    open func add(_ service: CBMutableService) {
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self._lock.lock()
            let delegate = self._delegate
            self._lock.unlock()
            delegate?.peripheralManager(self, didAdd: service, error: _CBUnsupportedError())
        }
    }

    open func remove(_ service: CBMutableService) {
        _ = service
    }

    open func removeAllServices() {}

    open func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        _ = (request, result)
    }

    open func updateValue(
        _ value: Data,
        for characteristic: CBMutableCharacteristic,
        onSubscribedCentrals centrals: [CBCentral]?
    ) -> Bool {
        _ = (value, characteristic, centrals)
        return false
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
            self.delegate?.peripheralManager(
                self,
                didPublishL2CAPChannel: 0,
                error: _CBUnsupportedError()
            )
        }
    }

    open func unpublishL2CAPChannel(_ PSM: CBL2CAPPSM) {
        _CBDispatch(_queue) { [weak self] in
            guard let self else { return }
            self.delegate?.peripheralManager(
                self,
                didUnpublishL2CAPChannel: PSM,
                error: _CBUnsupportedError()
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
            self._lock.unlock()
            guard !already, let delegate else { return }
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
