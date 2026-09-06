@_spi(OpenUIKitHost) import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testPHASEErrorCodeRawValues() {
    expect(PHASEError.Code.initializeFailed.rawValue == 1_346_913_633, "initializeFailed")
    expect(PHASEError.Code.invalidObject.rawValue == 1_346_913_634, "invalidObject")
    expect(PHASEError.Code(rawValue: 1_346_913_633) == .initializeFailed, "init initializeFailed")
    expect(PHASEError.Code(rawValue: 1_346_913_634) == .invalidObject, "init invalidObject")
    expect(PHASEError.Code(rawValue: 0) == nil, "unknown nil")
    expect(PHASEError.initializeFailed == .initializeFailed, "static initializeFailed")
    expect(PHASEError.invalidObject == .invalidObject, "static invalidObject")
}

func testPHASEErrorDomain() {
    expect(PHASEErrorDomain == "PHASEErrorDomain", "domain constant")
    expect(PHASEError.errorDomain == PHASEErrorDomain, "CustomNSError.domain")
    expect(PHASEError._nsErrorDomain == PHASEErrorDomain, "bridged domain")
}

func testPHASEErrorUserInfo() {
    let error = PHASEError(.initializeFailed, userInfo: [NSLocalizedDescriptionKey: "x"])
    expect(error.code == .initializeFailed, "code")
    expect(error.errorCode == 1_346_913_633, "errorCode")
    expect(error.userInfo[NSLocalizedDescriptionKey] as? String == "x", "userInfo")
    expect(error.errorUserInfo[NSLocalizedDescriptionKey] as? String == "x", "errorUserInfo")
    expect(error.localizedDescription == "x", "localizedDescription")
}

func testPHASEErrorHashable() {
    let left = PHASEError(.initializeFailed)
    let right = PHASEError(.initializeFailed, userInfo: ["a": 1])
    let other = PHASEError(.invalidObject)
    expect(left == right, "eq by code")
    expect(left != other, "neq")
    expect(!(left != right), "not neq")
    expect(left.hashValue == right.hashValue, "hashValue")
    var hasher = Hasher()
    left.hash(into: &hasher)
    PHASEError.Code.initializeFailed.hash(into: &hasher)
    _ = hasher.finalize()
    expect(PHASEError.Code.initializeFailed.hashValue != PHASEError.Code.invalidObject.hashValue, "code hash")
}

func testPHASEErrorPatternMatch() {
    let error: any Error = PHASEError(.invalidObject)
    expect(PHASEError.Code.invalidObject ~= error, "match")
    expect(!(PHASEError.Code.initializeFailed ~= error), "nonmatch")
}

func testPHASEErrorFallbackDescription() {
    let error = PHASEError(.invalidObject)
    expect(error.localizedDescription.isEmpty == false, "fallback description")
}
