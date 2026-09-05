import Foundation
@_spi(OpenUIKitHost) import SensorKit

func skExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testSRErrorCodes() {
    let rows: [(SRError.Code, Int)] = [
        (.invalidEntitlement, 0),
        (.noAuthorization, 1),
        (.dataInaccessible, 2),
        (.fetchRequestInvalid, 3),
        (.promptDeclined, 4),
    ]
    for (code, raw) in rows {
        skExpect(code.rawValue == raw, "SRError.Code \(code) raw \(code.rawValue)")
        skExpect(SRError.Code(rawValue: raw) == code, "round-trip \(raw)")
        skExpect(code != SRError.Code(rawValue: raw + 10), "inequality")
        skExpect(code.hashValue == raw, "hashValue")
        var hasher = Hasher()
        code.hash(into: &hasher)
        _ = hasher.finalize()
    }
    skExpect(SRErrorDomain == "SRErrorDomain", "domain spelling")
}

func testSRErrorBridging() {
    let error = SRError(.noAuthorization, userInfo: ["k": "v"])
    skExpect(error.code == .noAuthorization, "code")
    skExpect(error.errorCode == 1, "errorCode")
    skExpect(SRError.errorDomain == SRErrorDomain, "errorDomain")
    skExpect(error.errorUserInfo["k"] as? String == "v", "errorUserInfo")
    skExpect(error.userInfo["k"] as? String == "v", "userInfo")
    skExpect(error.hashValue == 1, "hashValue")
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    skExpect(error == SRError(.noAuthorization), "equality by code")
    skExpect(error != SRError(.invalidEntitlement), "inequality")
    skExpect(SRError.invalidEntitlement == .invalidEntitlement, "shortcut invalidEntitlement")
    skExpect(SRError.noAuthorization == .noAuthorization, "shortcut noAuthorization")
    skExpect(SRError.dataInaccessible == .dataInaccessible, "shortcut dataInaccessible")
    skExpect(SRError.fetchRequestInvalid == .fetchRequestInvalid, "shortcut fetchRequestInvalid")
    skExpect(SRError.promptDeclined == .promptDeclined, "shortcut promptDeclined")
    skExpect(SRError.Code.noAuthorization ~= error, "pattern match")
    skExpect(!error.localizedDescription.isEmpty, "localizedDescription")
}

func testAuthorizationStatus() {
    let rows: [(SRAuthorizationStatus, Int)] = [
        (.notDetermined, 0),
        (.authorized, 1),
        (.denied, 2),
    ]
    for (value, raw) in rows {
        skExpect(value.rawValue == raw, "auth \(raw)")
        skExpect(SRAuthorizationStatus(rawValue: raw) == value, "round-trip")
        skExpect(value != .authorized || raw == 1, "inequality path")
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
}

func testDeletionReason() {
    let rows: [(SRDeletionReason, Int)] = [
        (.userInitiated, 0),
        (.lowDiskSpace, 1),
        (.ageLimit, 2),
        (.noInterestedClients, 3),
        (.systemInitiated, 4),
    ]
    for (value, raw) in rows {
        skExpect(value.rawValue == raw, "deletion \(raw)")
        skExpect(SRDeletionReason(rawValue: raw) == value, "round-trip")
        skExpect(value != .ageLimit || raw == 2, "inequality")
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
}

func testMediaEventType() {
    skExpect(SRMediaEventType.onScreen.rawValue == 1, "onScreen")
    skExpect(SRMediaEventType.offScreen.rawValue == 2, "offScreen")
    skExpect(SRMediaEventType(rawValue: 1) == .onScreen, "round-trip")
    skExpect(SRMediaEventType.onScreen != .offScreen, "inequality")
    _ = SRMediaEventType.onScreen.hashValue
    var hasher = Hasher()
    SRMediaEventType.offScreen.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSRARKITSupported() {
    skExpect(SR_ARKIT_SUPPORTED == 0, "Linux has no ARKit")
}
