@_spi(OpenUIKitHost) import CoreBluetooth
import Foundation

func testCBManagerStateCases() {
    let cases: [(CBManagerState, Int)] = [
        (.unknown, 0),
        (.resetting, 1),
        (.unsupported, 2),
        (.unauthorized, 3),
        (.poweredOff, 4),
        (.poweredOn, 5),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBManagerState(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBManagerState.unknown != .poweredOn)
    precondition(CBManagerState(rawValue: 99) == nil)
}

func testCBCentralManagerStateCases() {
    let cases: [(CBCentralManagerState, Int)] = [
        (.unknown, 0),
        (.resetting, 1),
        (.unsupported, 2),
        (.unauthorized, 3),
        (.poweredOff, 4),
        (.poweredOn, 5),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBCentralManagerState(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBCentralManagerState.unknown != .poweredOn)
}

func testCBPeripheralManagerStateCases() {
    let cases: [(CBPeripheralManagerState, Int)] = [
        (.unknown, 0),
        (.resetting, 1),
        (.unsupported, 2),
        (.unauthorized, 3),
        (.poweredOff, 4),
        (.poweredOn, 5),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBPeripheralManagerState(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBPeripheralManagerState.unknown != .poweredOn)
}

func testCBManagerAuthorizationCases() {
    let cases: [(CBManagerAuthorization, Int)] = [
        (.notDetermined, 0),
        (.restricted, 1),
        (.denied, 2),
        (.allowedAlways, 3),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBManagerAuthorization(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBManagerAuthorization.denied != .allowedAlways)
}

func testCBPeripheralManagerAuthorizationStatusCases() {
    let cases: [(CBPeripheralManagerAuthorizationStatus, Int)] = [
        (.notDetermined, 0),
        (.restricted, 1),
        (.denied, 2),
        (.authorized, 3),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBPeripheralManagerAuthorizationStatus(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBPeripheralManagerAuthorizationStatus.denied != .authorized)
}

func testCBPeripheralStateCases() {
    let cases: [(CBPeripheralState, Int)] = [
        (.disconnected, 0),
        (.connecting, 1),
        (.connected, 2),
        (.disconnecting, 3),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBPeripheralState(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBPeripheralState.disconnected != .connected)
}

func testCBCharacteristicWriteTypeCases() {
    let cases: [(CBCharacteristicWriteType, Int)] = [
        (.withResponse, 0),
        (.withoutResponse, 1),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBCharacteristicWriteType(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBCharacteristicWriteType.withResponse != .withoutResponse)
}

func testCBPeripheralManagerConnectionLatencyCases() {
    let cases: [(CBPeripheralManagerConnectionLatency, Int)] = [
        (.low, 0),
        (.medium, 1),
        (.high, 2),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBPeripheralManagerConnectionLatency(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBPeripheralManagerConnectionLatency.low != .high)
}

func testCBConnectionEventCases() {
    let cases: [(CBConnectionEvent, Int)] = [
        (.peerDisconnected, 0),
        (.peerConnected, 1),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(CBConnectionEvent(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBConnectionEvent.peerConnected != .peerDisconnected)
}
