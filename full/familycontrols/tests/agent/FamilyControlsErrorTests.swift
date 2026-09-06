import Foundation
@_spi(OpenUIKitHost) import FamilyControls

/// Table-driven `FamilyControlsError` cases and raw values from api-digester
/// declaration order (`restricted = 0` ... `authenticationMethodUnavailable = 7`).
func testErrorCases() {
    let table: [(FamilyControlsError, Int)] = [
        (.restricted, 0),
        (.unavailable, 1),
        (.invalidAccountType, 2),
        (.invalidArgument, 3),
        (.authorizationConflict, 4),
        (.authorizationCanceled, 5),
        (.networkError, 6),
        (.authenticationMethodUnavailable, 7),
    ]
    precondition(Set(table.map(\.0)).count == 8)
    precondition(Set(table.map(\.1)).count == 8)
    for (value, raw) in table {
        precondition(value.rawValue == raw)
        precondition(FamilyControlsError(rawValue: raw) == value)
        precondition(value.errorCode == raw)
    }
    typealias Raw = FamilyControlsError.RawValue
    precondition((table[0].1 as Raw) == 0)
}

func testErrorRawValueInit() {
    precondition(FamilyControlsError(rawValue: 0) == .restricted)
    precondition(FamilyControlsError(rawValue: 7) == .authenticationMethodUnavailable)
    precondition(FamilyControlsError(rawValue: 8) == nil)
    precondition(FamilyControlsError(rawValue: -1) == nil)
}

func testErrorInequality() {
    precondition(FamilyControlsError.restricted != .unavailable)
    precondition(FamilyControlsError.unavailable != .invalidAccountType)
    precondition(FamilyControlsError.networkError != .authorizationCanceled)
    precondition(!(FamilyControlsError.restricted != .restricted))
    precondition(FamilyControlsError.invalidArgument == .invalidArgument)
}

func testErrorHash() {
    var hasher = Hasher()
    FamilyControlsError.restricted.hash(into: &hasher)
    FamilyControlsError.unavailable.hash(into: &hasher)
    FamilyControlsError.networkError.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(FamilyControlsError.restricted.hashValue == FamilyControlsError.restricted.hashValue)
}

func testErrorDescription() {
    precondition(FamilyControlsError.restricted.errorDescription == "FamilyControlsError.restricted")
    precondition(FamilyControlsError.unavailable.errorDescription == "FamilyControlsError.unavailable")
    precondition(FamilyControlsError.invalidAccountType.errorDescription == "FamilyControlsError.invalidAccountType")
    precondition(FamilyControlsError.invalidArgument.errorDescription == "FamilyControlsError.invalidArgument")
    precondition(FamilyControlsError.authorizationConflict.errorDescription == "FamilyControlsError.authorizationConflict")
    precondition(FamilyControlsError.authorizationCanceled.errorDescription == "FamilyControlsError.authorizationCanceled")
    precondition(FamilyControlsError.networkError.errorDescription == "FamilyControlsError.networkError")
    precondition(
        FamilyControlsError.authenticationMethodUnavailable.errorDescription
            == "FamilyControlsError.authenticationMethodUnavailable"
    )
}

func testErrorNSErrorSurface() {
    precondition(FamilyControlsError.errorDomain == "FamilyControls.FamilyControlsError")
    let error = FamilyControlsError.unavailable
    precondition(error.errorCode == 1)
    let info = error.errorUserInfo
    precondition(info[NSLocalizedDescriptionKey] as? String == error.errorDescription)
    let ns = error as NSError
    precondition(ns.domain == FamilyControlsError.errorDomain)
    precondition(ns.code == 1)
}

func testErrorLocalizedDefaults() {
    let error = FamilyControlsError.restricted
    precondition(error.failureReason == nil)
    precondition(error.recoverySuggestion == nil)
    precondition(error.helpAnchor == nil)
}

func testErrorLocalizedDescription() {
    let error = FamilyControlsError.unavailable
    precondition(!error.localizedDescription.isEmpty)
    precondition(error.localizedDescription.contains("unavailable") || error.localizedDescription == error.errorDescription)
}
