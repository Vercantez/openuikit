@_spi(OpenUIKitHost) import SoundAnalysis
import Foundation

private func snExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testErrorCodeRawValues() {
    let rows: [(SNError.Code, Int)] = [
        (.unknownError, 1),
        (.operationFailed, 2),
        (.invalidFormat, 3),
        (.invalidModel, 4),
        (.invalidFile, 5),
    ]
    snExpect(rows.count == 5, "SNError.Code has five documented cases")
    for (code, raw) in rows {
        snExpect(code.rawValue == raw, "raw value \(raw)")
        snExpect(SNError.Code(rawValue: raw) == code, "init(rawValue:) \(raw)")
    }
    snExpect(SNError.unknownError == .unknownError, "SNError.unknownError")
    snExpect(SNError.operationFailed == .operationFailed, "SNError.operationFailed")
    snExpect(SNError.invalidFormat == .invalidFormat, "SNError.invalidFormat")
    snExpect(SNError.invalidModel == .invalidModel, "SNError.invalidModel")
    snExpect(SNError.invalidFile == .invalidFile, "SNError.invalidFile")
    snExpect(SNError.Code(rawValue: 99)?.rawValue == 99, "unknown codes remain constructible")
}

func testErrorCodeHashable() {
    var hasher = Hasher()
    SNError.Code.invalidFile.hash(into: &hasher)
    _ = hasher.finalize()
    snExpect(
        SNError.Code.invalidFile.hashValue == SNError.invalidFile.hashValue,
        "Code hashValue matches SNError.invalidFile.hashValue"
    )
    snExpect(
        SNError.Code.unknownError.hashValue != SNError.Code.invalidFile.hashValue,
        "distinct codes hash distinctly"
    )
}

func testErrorDomainConstant() {
    snExpect(SNErrorDomain == "SNErrorDomain", "exported domain string")
    snExpect(SNError.errorDomain == SNErrorDomain, "CustomNSError.errorDomain")
    snExpect(SNError(.unknownError).errorUserInfo.isEmpty, "default userInfo empty")
}

func testErrorUserInfo() {
    let info: [String: Any] = [NSLocalizedDescriptionKey: "probe"]
    let error = SNError(.invalidFormat, userInfo: info)
    snExpect(error.code == .invalidFormat, "code")
    snExpect(error.errorCode == 3, "errorCode")
    snExpect(error.userInfo[NSLocalizedDescriptionKey] as? String == "probe", "userInfo")
    snExpect(error.errorUserInfo[NSLocalizedDescriptionKey] as? String == "probe", "errorUserInfo")
}

func testErrorHashableEquatable() {
    let left = SNError(.invalidModel)
    let right = SNError(.invalidModel, userInfo: ["x": 1])
    let other = SNError(.invalidFile)
    snExpect(left == right, "equality is by code")
    snExpect(left != other, "inequality")
    snExpect(!(left != right), "!= false when codes match")
    snExpect(left.hashValue == right.hashValue, "hashValue follows code")
    var hasher = Hasher()
    left.hash(into: &hasher)
    _ = hasher.finalize()
}

func testErrorPatternMatch() {
    let error: any Error = SNError(.operationFailed)
    snExpect(SNError.Code.operationFailed ~= error, "Code ~= SNError")
    snExpect(!(SNError.Code.invalidFile ~= error), "non-matching code")
    snExpect(!(SNError.Code.unknownError ~= NSError(domain: "x", code: 1)), "foreign error")
}

func testErrorLocalizedDescription() {
    let custom = SNError(.unknownError, userInfo: [NSLocalizedDescriptionKey: "custom"])
    snExpect(custom.localizedDescription == "custom", "userInfo description")
    let fallback = SNError(.unknownError)
    snExpect(fallback.localizedDescription.contains("1"), "fallback mentions code")
}
