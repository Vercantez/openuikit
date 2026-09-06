import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testPHASEAssetErrorCodeRawValues() {
    let rows: [(PHASEAssetError.Code, Int)] = [
        (.failedToLoad, 1_346_920_801),
        (.invalidEngineInstance, 1_346_920_802),
        (.badParameters, 1_346_920_803),
        (.alreadyExists, 1_346_920_804),
        (.generalError, 1_346_920_805),
        (.memoryAllocation, 1_346_920_806),
    ]
    for (code, raw) in rows {
        expect(code.rawValue == raw, "raw \(raw)")
        expect(PHASEAssetError.Code(rawValue: raw) == code, "init \(raw)")
    }
    expect(PHASEAssetError.failedToLoad == .failedToLoad, "static failedToLoad")
    expect(PHASEAssetError.invalidEngineInstance == .invalidEngineInstance, "static invalidEngine")
    expect(PHASEAssetError.badParameters == .badParameters, "static badParameters")
    expect(PHASEAssetError.alreadyExists == .alreadyExists, "static alreadyExists")
    expect(PHASEAssetError.generalError == .generalError, "static generalError")
    expect(PHASEAssetError.memoryAllocation == .memoryAllocation, "static memory")
}

func testPHASEAssetErrorDomain() {
    expect(PHASEAssetErrorDomain == "PHASEAssetErrorDomain", "domain")
    expect(PHASEAssetError.errorDomain == PHASEAssetErrorDomain, "errorDomain")
}

func testPHASEAssetErrorUserInfo() {
    let error = PHASEAssetError(.alreadyExists, userInfo: ["k": "v"])
    expect(error.code == .alreadyExists, "code")
    expect(error.errorCode == 1_346_920_804, "errorCode")
    expect(error.userInfo["k"] as? String == "v", "userInfo")
    expect(error.errorUserInfo["k"] as? String == "v", "errorUserInfo")
    expect(error.localizedDescription.isEmpty == false, "description")
}

func testPHASEAssetErrorHashable() {
    let a = PHASEAssetError(.failedToLoad)
    let b = PHASEAssetError(.failedToLoad, userInfo: ["z": 1])
    expect(a == b, "eq")
    expect(a != PHASEAssetError(.badParameters), "neq")
    var hasher = Hasher()
    a.hash(into: &hasher)
    PHASEAssetError.Code.failedToLoad.hash(into: &hasher)
    _ = hasher.finalize()
    expect(a.hashValue == b.hashValue, "hashValue")
}

func testPHASEAssetErrorPatternMatch() {
    let error: any Error = PHASEAssetError(.badParameters)
    expect(PHASEAssetError.Code.badParameters ~= error, "match")
    expect(!(PHASEAssetError.Code.failedToLoad ~= error), "nonmatch")
}
