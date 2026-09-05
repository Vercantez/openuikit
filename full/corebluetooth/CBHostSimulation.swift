import Foundation
@preconcurrency import Dispatch

/// Process-local simulated Bluetooth adapter. Linux has no radio; tests and
/// hosts install this hook to exercise CoreBluetooth without fabricating a
/// real controller, TCC grant, or Apple restore cache.
@_spi(OpenUIKitHost)
public final class CBHostSimulatedDescriptor: NSObject {
    public let uuid: CBUUID
    public var value: Any?

    public init(uuid: CBUUID, value: Any? = nil) {
        self.uuid = uuid
        self.value = value
    }
}

@_spi(OpenUIKitHost)
public final class CBHostSimulatedCharacteristic: NSObject {
    public let uuid: CBUUID
    public var properties: CBCharacteristicProperties
    public var value: Data?
    public var descriptors: [CBHostSimulatedDescriptor]
    public var notifyPayload: Data?

    public init(
        uuid: CBUUID,
        properties: CBCharacteristicProperties,
        value: Data? = nil,
        descriptors: [CBHostSimulatedDescriptor] = [],
        notifyPayload: Data? = nil
    ) {
        self.uuid = uuid
        self.properties = properties
        self.value = value
        self.descriptors = descriptors
        self.notifyPayload = notifyPayload
    }
}

@_spi(OpenUIKitHost)
public final class CBHostSimulatedService: NSObject {
    public let uuid: CBUUID
    public var isPrimary: Bool
    public var characteristics: [CBHostSimulatedCharacteristic]
    public var includedServices: [CBHostSimulatedService]

    public init(
        uuid: CBUUID,
        isPrimary: Bool,
        characteristics: [CBHostSimulatedCharacteristic] = [],
        includedServices: [CBHostSimulatedService] = []
    ) {
        self.uuid = uuid
        self.isPrimary = isPrimary
        self.characteristics = characteristics
        self.includedServices = includedServices
    }
}

@_spi(OpenUIKitHost)
public final class CBHostSimulatedPeripheral: NSObject {
    public let identifier: UUID
    public var name: String?
    public var rssi: NSNumber
    public var advertisementData: [String: Any]
    public var services: [CBHostSimulatedService]
    public var connectable: Bool
    public var ancsAuthorized: Bool
    public var maximumWriteWithoutResponse: Int
    public var maximumWriteWithResponse: Int

    public init(
        identifier: UUID,
        name: String?,
        rssi: NSNumber,
        advertisementData: [String: Any],
        services: [CBHostSimulatedService],
        connectable: Bool = true,
        ancsAuthorized: Bool = false,
        maximumWriteWithoutResponse: Int = 20,
        maximumWriteWithResponse: Int = 512
    ) {
        self.identifier = identifier
        self.name = name
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.services = services
        self.connectable = connectable
        self.ancsAuthorized = ancsAuthorized
        self.maximumWriteWithoutResponse = maximumWriteWithoutResponse
        self.maximumWriteWithResponse = maximumWriteWithResponse
    }

    /// Advertisement dictionary containing every public `CBAdvertisementData*`
    /// key. Values are host-supplied; constant *payloads* remain process-local.
    public static func advertisementDictionary(
        localName: String,
        manufacturerData: Data,
        serviceUUID: CBUUID,
        serviceData: Data,
        overflowUUID: CBUUID,
        solicitedUUID: CBUUID,
        txPower: Int,
        isConnectable: Bool
    ) -> [String: Any] {
        [
            CBAdvertisementDataLocalNameKey: localName,
            CBAdvertisementDataManufacturerDataKey: manufacturerData,
            CBAdvertisementDataServiceDataKey: [serviceUUID: serviceData],
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataOverflowServiceUUIDsKey: [overflowUUID],
            CBAdvertisementDataTxPowerLevelKey: NSNumber(value: txPower),
            CBAdvertisementDataIsConnectable: NSNumber(value: isConnectable),
            CBAdvertisementDataSolicitedServiceUUIDsKey: [solicitedUUID],
        ]
    }
}

@_spi(OpenUIKitHost)
public final class CBHostSimulatedAdapter: NSObject {
    public var state: CBManagerState
    public var peripherals: [CBHostSimulatedPeripheral]
    public var restoredCentralState: [String: Any]?
    public var restoredPeripheralState: [String: Any]?
    public var simulatedCentral: CBCentral

    public init(
        state: CBManagerState = .poweredOn,
        peripherals: [CBHostSimulatedPeripheral] = [],
        restoredCentralState: [String: Any]? = nil,
        restoredPeripheralState: [String: Any]? = nil,
        simulatedCentral: CBCentral? = nil
    ) {
        self.state = state
        self.peripherals = peripherals
        self.restoredCentralState = restoredCentralState
        self.restoredPeripheralState = restoredPeripheralState
        self.simulatedCentral = simulatedCentral
            ?? CBCentral(hostIdentifier: UUID(), maximumUpdateValueLength: 20)
    }
}

@_spi(OpenUIKitHost)
public enum CBHostSimulation {
    private static let lock = NSLock()
    private static var _adapter: CBHostSimulatedAdapter?

    public static var adapter: CBHostSimulatedAdapter? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _adapter
        }
        set {
            lock.lock()
            _adapter = newValue
            lock.unlock()
        }
    }

    public static func install(_ adapter: CBHostSimulatedAdapter) {
        self.adapter = adapter
    }

    public static func remove() {
        adapter = nil
    }
}

func _CBOptionFlag(_ options: [String: Any]?, key: String) -> Bool {
    guard let value = options?[key] else { return false }
    if let flag = value as? Bool { return flag }
    if let number = value as? NSNumber { return number.boolValue }
    return false
}

func _CBUUIDListContains(_ haystack: [CBUUID]?, _ needle: CBUUID) -> Bool {
    haystack?.contains(where: { $0 == needle }) ?? false
}

func _CBFilterUUIDs<T>(_ items: [T], uuids: [CBUUID]?, uuid: (T) -> CBUUID) -> [T] {
    guard let uuids, !uuids.isEmpty else { return items }
    return items.filter { candidate in
        uuids.contains(where: { $0 == uuid(candidate) })
    }
}
