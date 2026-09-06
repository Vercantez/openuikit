import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testPHASESoundEventErrorCodeRawValues() {
    let rows: [(PHASESoundEventError.Code, Int)] = [
        (.notFound, 1_346_925_665),
        (.badData, 1_346_925_666),
        (.invalidInstance, 1_346_925_667),
        (.apiMisuse, 1_346_925_668),
        (.systemNotInitialized, 1_346_925_669),
        (.outOfMemory, 1_346_925_670),
    ]
    for (code, raw) in rows {
        expect(code.rawValue == raw, "raw \(raw)")
        expect(PHASESoundEventError.Code(rawValue: raw) == code, "init \(raw)")
    }
    expect(PHASESoundEventError.notFound == .notFound, "static notFound")
    expect(PHASESoundEventError.badData == .badData, "static badData")
    expect(PHASESoundEventError.invalidInstance == .invalidInstance, "static invalidInstance")
    expect(PHASESoundEventError.apiMisuse == .apiMisuse, "static apiMisuse")
    expect(PHASESoundEventError.systemNotInitialized == .systemNotInitialized, "static uninit")
    expect(PHASESoundEventError.outOfMemory == .outOfMemory, "static oom")
}

func testPHASESoundEventErrorDomain() {
    expect(PHASESoundEventErrorDomain == "PHASESoundEventErrorDomain", "domain")
    expect(PHASESoundEventError.errorDomain == PHASESoundEventErrorDomain, "errorDomain")
}

func testPHASESoundEventErrorUserInfo() {
    let error = PHASESoundEventError(.notFound, userInfo: [NSLocalizedDescriptionKey: "missing"])
    expect(error.code == .notFound, "code")
    expect(error.errorCode == 1_346_925_665, "errorCode")
    expect(error.userInfo[NSLocalizedDescriptionKey] as? String == "missing", "userInfo")
    expect(error.localizedDescription == "missing", "localized")
}

func testPHASESoundEventErrorHashable() {
    let a = PHASESoundEventError(.apiMisuse)
    let b = PHASESoundEventError(.apiMisuse, userInfo: ["n": 2])
    expect(a == b, "eq")
    expect(a != PHASESoundEventError(.notFound), "neq")
    var hasher = Hasher()
    a.hash(into: &hasher)
    PHASESoundEventError.Code.apiMisuse.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPHASESoundEventErrorPatternMatch() {
    let error: any Error = PHASESoundEventError(.systemNotInitialized)
    expect(PHASESoundEventError.Code.systemNotInitialized ~= error, "match")
    expect(!(PHASESoundEventError.Code.outOfMemory ~= error), "nonmatch")
}
