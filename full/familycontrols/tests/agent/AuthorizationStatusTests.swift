import Foundation
@_spi(OpenUIKitHost) import FamilyControls

/// Table-driven `AuthorizationStatus` cases (`notDetermined = 0`, `denied = 1`,
/// `approved = 2`). Linux never reports `.approved` from AuthorizationCenter.
func testStatusCases() {
    let table: [(AuthorizationStatus, Int)] = [
        (.notDetermined, 0),
        (.denied, 1),
        (.approved, 2),
    ]
    precondition(Set(table.map(\.0)).count == 3)
    precondition(Set(table.map(\.1)).count == 3)
    for (value, raw) in table {
        precondition(value.rawValue == raw)
        precondition(AuthorizationStatus(rawValue: raw) == value)
    }
    typealias Raw = AuthorizationStatus.RawValue
    precondition((table[1].1 as Raw) == 1)
}

func testStatusRawValueInit() {
    precondition(AuthorizationStatus(rawValue: 0) == .notDetermined)
    precondition(AuthorizationStatus(rawValue: 1) == .denied)
    precondition(AuthorizationStatus(rawValue: 2) == .approved)
    precondition(AuthorizationStatus(rawValue: 3) == nil)
    precondition(AuthorizationStatus(rawValue: -1) == nil)
}

func testStatusDescription() {
    precondition(AuthorizationStatus.notDetermined.description == "notDetermined")
    precondition(AuthorizationStatus.denied.description == "denied")
    precondition(AuthorizationStatus.approved.description == "approved")
}

func testStatusInequality() {
    precondition(AuthorizationStatus.notDetermined != .denied)
    precondition(AuthorizationStatus.denied != .approved)
    precondition(!(AuthorizationStatus.denied != .denied))
    precondition(AuthorizationStatus.approved == .approved)
}

func testStatusHash() {
    var hasher = Hasher()
    AuthorizationStatus.notDetermined.hash(into: &hasher)
    AuthorizationStatus.denied.hash(into: &hasher)
    AuthorizationStatus.approved.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(AuthorizationStatus.denied.hashValue == AuthorizationStatus.denied.hashValue)
}

func testStatusCodable() {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for status in [AuthorizationStatus.notDetermined, .denied, .approved] {
        let data = try! encoder.encode(status)
        let decoded = try! decoder.decode(AuthorizationStatus.self, from: data)
        precondition(decoded == status)
    }
}
