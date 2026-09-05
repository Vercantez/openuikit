@_exported import Foundation
@preconcurrency import Dispatch

// MARK: - Error domains

/// Apple's public `NS_ERROR_ENUM` domain name for `CBError`.
public let CBErrorDomain = "CBErrorDomain"

/// Apple's public `NS_ERROR_ENUM` domain name for `CBATTError`.
public let CBATTErrorDomain = "CBATTErrorDomain"

// MARK: - Advertisement data keys

/// Process-local dictionary keys. Apple binary payloads are unobserved in
/// this seed; clients must compare against these constants, not literals.
public let CBAdvertisementDataLocalNameKey = "CBAdvertisementDataLocalNameKey"
public let CBAdvertisementDataManufacturerDataKey = "CBAdvertisementDataManufacturerDataKey"
public let CBAdvertisementDataServiceDataKey = "CBAdvertisementDataServiceDataKey"
public let CBAdvertisementDataServiceUUIDsKey = "CBAdvertisementDataServiceUUIDsKey"
public let CBAdvertisementDataOverflowServiceUUIDsKey = "CBAdvertisementDataOverflowServiceUUIDsKey"
public let CBAdvertisementDataTxPowerLevelKey = "CBAdvertisementDataTxPowerLevelKey"
public let CBAdvertisementDataIsConnectable = "CBAdvertisementDataIsConnectable"
public let CBAdvertisementDataSolicitedServiceUUIDsKey = "CBAdvertisementDataSolicitedServiceUUIDsKey"

// MARK: - Central manager option keys

public let CBCentralManagerOptionShowPowerAlertKey = "CBCentralManagerOptionShowPowerAlertKey"
public let CBCentralManagerOptionRestoreIdentifierKey = "CBCentralManagerOptionRestoreIdentifierKey"
public let CBCentralManagerOptionDeviceAccessForMedia = "CBCentralManagerOptionDeviceAccessForMedia"
public let CBCentralManagerScanOptionAllowDuplicatesKey = "CBCentralManagerScanOptionAllowDuplicatesKey"
public let CBCentralManagerScanOptionSolicitedServiceUUIDsKey = "CBCentralManagerScanOptionSolicitedServiceUUIDsKey"
public let CBConnectPeripheralOptionNotifyOnConnectionKey = "CBConnectPeripheralOptionNotifyOnConnectionKey"
public let CBConnectPeripheralOptionNotifyOnDisconnectionKey = "CBConnectPeripheralOptionNotifyOnDisconnectionKey"
public let CBConnectPeripheralOptionNotifyOnNotificationKey = "CBConnectPeripheralOptionNotifyOnNotificationKey"
public let CBConnectPeripheralOptionStartDelayKey = "CBConnectPeripheralOptionStartDelayKey"
public let CBConnectPeripheralOptionEnableTransportBridgingKey = "CBConnectPeripheralOptionEnableTransportBridgingKey"
public let CBConnectPeripheralOptionRequiresANCS = "CBConnectPeripheralOptionRequiresANCS"
public let CBConnectPeripheralOptionEnableAutoReconnect = "CBConnectPeripheralOptionEnableAutoReconnect"
public let CBCentralManagerRestoredStatePeripheralsKey = "CBCentralManagerRestoredStatePeripheralsKey"
public let CBCentralManagerRestoredStateScanServicesKey = "CBCentralManagerRestoredStateScanServicesKey"
public let CBCentralManagerRestoredStateScanOptionsKey = "CBCentralManagerRestoredStateScanOptionsKey"

// MARK: - Peripheral manager option keys

public let CBPeripheralManagerOptionShowPowerAlertKey = "CBPeripheralManagerOptionShowPowerAlertKey"
public let CBPeripheralManagerOptionRestoreIdentifierKey = "CBPeripheralManagerOptionRestoreIdentifierKey"
public let CBPeripheralManagerRestoredStateServicesKey = "CBPeripheralManagerRestoredStateServicesKey"
public let CBPeripheralManagerRestoredStateAdvertisementDataKey = "CBPeripheralManagerRestoredStateAdvertisementDataKey"

// MARK: - GATT assigned-number strings (Bluetooth SIG 16-bit UUIDs)

public let CBUUIDCharacteristicExtendedPropertiesString = "2900"
public let CBUUIDCharacteristicUserDescriptionString = "2901"
public let CBUUIDClientCharacteristicConfigurationString = "2902"
public let CBUUIDServerCharacteristicConfigurationString = "2903"
public let CBUUIDCharacteristicFormatString = "2904"
public let CBUUIDCharacteristicAggregateFormatString = "2905"
public let CBUUIDCharacteristicValidRangeString = "2906"

/// Apple's public documentation records this 128-bit L2CAP PSM characteristic.
public let CBUUIDL2CAPPSMCharacteristicString = "ABDD3056-28FA-441D-A470-55A75A52553A"

/// Process-local identity only; Apple's binary payload is unobserved.
public let CBUUIDCharacteristicObservationScheduleString = "CBUUIDCharacteristicObservationScheduleString"

// MARK: - Typealiases

public typealias CBL2CAPPSM = UInt16

// MARK: - Connection-event matching

public struct CBConnectionEventMatchingOption: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Process-local identity; Apple's bridged NSDictionary raw string is unobserved.
    public static let peripheralUUIDs = CBConnectionEventMatchingOption(rawValue: "peripheralUUIDs")
    /// Process-local identity; Apple's bridged NSDictionary raw string is unobserved.
    public static let serviceUUIDs = CBConnectionEventMatchingOption(rawValue: "serviceUUIDs")
}

// MARK: - Manager and peripheral state

public enum CBManagerState: Int, Hashable, Sendable {
    case unknown = 0
    case resetting = 1
    case unsupported = 2
    case unauthorized = 3
    case poweredOff = 4
    case poweredOn = 5
}

@available(iOS, introduced: 5.0, deprecated: 10.0, message: "Use CBManagerState instead")
public enum CBCentralManagerState: Int, Hashable, Sendable {
    case unknown = 0
    case resetting = 1
    case unsupported = 2
    case unauthorized = 3
    case poweredOff = 4
    case poweredOn = 5
}

@available(iOS, introduced: 6.0, deprecated: 10.0, message: "Use CBManagerState instead")
public enum CBPeripheralManagerState: Int, Hashable, Sendable {
    case unknown = 0
    case resetting = 1
    case unsupported = 2
    case unauthorized = 3
    case poweredOff = 4
    case poweredOn = 5
}

public enum CBManagerAuthorization: Int, Hashable, Sendable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case allowedAlways = 3
}

@available(iOS, introduced: 7.0, deprecated: 13.0, message: "Use CBManagerAuthorization instead")
public enum CBPeripheralManagerAuthorizationStatus: Int, Hashable, Sendable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorized = 3
}

public enum CBPeripheralState: Int, Hashable, Sendable {
    case disconnected = 0
    case connecting = 1
    case connected = 2
    case disconnecting = 3
}

public enum CBCharacteristicWriteType: Int, Hashable, Sendable {
    case withResponse = 0
    case withoutResponse = 1
}

public enum CBPeripheralManagerConnectionLatency: Int, Hashable, Sendable {
    case low = 0
    case medium = 1
    case high = 2
}

public enum CBConnectionEvent: Int, Hashable, Sendable {
    case peerDisconnected = 0
    case peerConnected = 1
}

// MARK: - Option sets

public struct CBCharacteristicProperties: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let broadcast = CBCharacteristicProperties(rawValue: 1 << 0)
    public static let read = CBCharacteristicProperties(rawValue: 1 << 1)
    public static let writeWithoutResponse = CBCharacteristicProperties(rawValue: 1 << 2)
    public static let write = CBCharacteristicProperties(rawValue: 1 << 3)
    public static let notify = CBCharacteristicProperties(rawValue: 1 << 4)
    public static let indicate = CBCharacteristicProperties(rawValue: 1 << 5)
    public static let authenticatedSignedWrites = CBCharacteristicProperties(rawValue: 1 << 6)
    public static let extendedProperties = CBCharacteristicProperties(rawValue: 1 << 7)
    public static let notifyEncryptionRequired = CBCharacteristicProperties(rawValue: 1 << 8)
    public static let indicateEncryptionRequired = CBCharacteristicProperties(rawValue: 1 << 9)
}

public struct CBAttributePermissions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let readable = CBAttributePermissions(rawValue: 1 << 0)
    public static let writeable = CBAttributePermissions(rawValue: 1 << 1)
    public static let readEncryptionRequired = CBAttributePermissions(rawValue: 1 << 2)
    public static let writeEncryptionRequired = CBAttributePermissions(rawValue: 1 << 3)
}

// MARK: - Errors

public struct CBError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknown = 0
        case invalidParameters = 1
        case invalidHandle = 2
        case notConnected = 3
        case outOfSpace = 4
        case operationCancelled = 5
        case connectionTimeout = 6
        case peripheralDisconnected = 7
        case uuidNotAllowed = 8
        case alreadyAdvertising = 9
        case connectionFailed = 10
        case connectionLimitReached = 11
        case unkownDevice = 12
        case operationNotSupported = 13
        case peerRemovedPairingInformation = 14
        case encryptionTimedOut = 15
        case tooManyLEPairedDevices = 16

        public static var unknownDevice: Code { .unkownDevice }
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { CBErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let unknown = Code.unknown
    public static let invalidParameters = Code.invalidParameters
    public static let invalidHandle = Code.invalidHandle
    public static let notConnected = Code.notConnected
    public static let outOfSpace = Code.outOfSpace
    public static let operationCancelled = Code.operationCancelled
    public static let connectionTimeout = Code.connectionTimeout
    public static let peripheralDisconnected = Code.peripheralDisconnected
    public static let uuidNotAllowed = Code.uuidNotAllowed
    public static let alreadyAdvertising = Code.alreadyAdvertising
    public static let connectionFailed = Code.connectionFailed
    public static let connectionLimitReached = Code.connectionLimitReached
    public static let unkownDevice = Code.unkownDevice
    public static var unknownDevice: Code { .unkownDevice }
    public static let operationNotSupported = Code.operationNotSupported
    public static let peerRemovedPairingInformation = Code.peerRemovedPairingInformation
    public static let encryptionTimedOut = Code.encryptionTimedOut
    public static let tooManyLEPairedDevices = Code.tooManyLEPairedDevices

    public static func == (lhs: CBError, rhs: CBError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension CBError.Code {
    public static func ~= (match: CBError.Code, error: any Error) -> Bool {
        if let typed = error as? CBError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == CBErrorDomain && nsError.code == match.rawValue
    }
}

public struct CBATTError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case success = 0x00
        case invalidHandle = 0x01
        case readNotPermitted = 0x02
        case writeNotPermitted = 0x03
        case invalidPdu = 0x04
        case insufficientAuthentication = 0x05
        case requestNotSupported = 0x06
        case invalidOffset = 0x07
        case insufficientAuthorization = 0x08
        case prepareQueueFull = 0x09
        case attributeNotFound = 0x0A
        case attributeNotLong = 0x0B
        case insufficientEncryptionKeySize = 0x0C
        case invalidAttributeValueLength = 0x0D
        case unlikelyError = 0x0E
        case insufficientEncryption = 0x0F
        case unsupportedGroupType = 0x10
        case insufficientResources = 0x11

        public var hashValue: Int { rawValue }
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { CBATTErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let success = Code.success
    public static let invalidHandle = Code.invalidHandle
    public static let readNotPermitted = Code.readNotPermitted
    public static let writeNotPermitted = Code.writeNotPermitted
    public static let invalidPdu = Code.invalidPdu
    public static let insufficientAuthentication = Code.insufficientAuthentication
    public static let requestNotSupported = Code.requestNotSupported
    public static let invalidOffset = Code.invalidOffset
    public static let insufficientAuthorization = Code.insufficientAuthorization
    public static let prepareQueueFull = Code.prepareQueueFull
    public static let attributeNotFound = Code.attributeNotFound
    public static let attributeNotLong = Code.attributeNotLong
    public static let insufficientEncryptionKeySize = Code.insufficientEncryptionKeySize
    public static let invalidAttributeValueLength = Code.invalidAttributeValueLength
    public static let unlikelyError = Code.unlikelyError
    public static let insufficientEncryption = Code.insufficientEncryption
    public static let unsupportedGroupType = Code.unsupportedGroupType
    public static let insufficientResources = Code.insufficientResources

    public static func == (lhs: CBATTError, rhs: CBATTError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension CBATTError.Code {
    public static func ~= (match: CBATTError.Code, error: any Error) -> Bool {
        if let typed = error as? CBATTError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == CBATTErrorDomain && nsError.code == match.rawValue
    }
}

func _CBUnsupportedError() -> CBError {
    CBError(.operationNotSupported)
}

/// Hop asynchronously onto `queue`, or `DispatchQueue.main` when `queue` is
/// nil. The body never runs inline in the caller.
func _CBDispatch(_ queue: DispatchQueue?, _ body: @escaping () -> Void) {
    (queue ?? DispatchQueue.main).async {
        body()
    }
}
