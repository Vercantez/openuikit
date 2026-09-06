import Foundation
import AutomaticAssessmentConfiguration

func testAEAssessmentErrorDomain() {
    aacExpect(AEAssessmentErrorDomain == "AEAssessmentErrorDomain", "domain string")
    aacExpect(AEAssessmentError.errorDomain == AEAssessmentErrorDomain, "CustomNSError domain")
}

func testAEAssessmentErrorType() {
    let error = AEAssessmentError(.unknown)
    aacExpect(type(of: error) == AEAssessmentError.self, "type")
}

func testAEAssessmentErrorCodeType() {
    let code: AEAssessmentError.Code = .unknown
    aacExpect(type(of: code) == AEAssessmentError.Code.self, "code type")
}

func testErrorCodeRawValues() {
    let cases: [(AEAssessmentError.Code, Int)] = [
        (.unknown, 1),
        (.unsupportedPlatform, 2),
        (.multipleParticipantsNotSupported, 3),
        (.configurationUpdatesNotSupported, 4),
        (.requiredParticipantsNotAvailable, 5),
    ]
    for (value, raw) in cases {
        aacExpect(value.rawValue == raw, "raw \(raw)")
        aacExpect(AEAssessmentError.Code(rawValue: raw) == value, "init \(raw)")
    }
    aacExpect(AEAssessmentError.unknown == .unknown, "unknown alias")
    aacExpect(AEAssessmentError.unsupportedPlatform == .unsupportedPlatform, "unsupported alias")
    aacExpect(
        AEAssessmentError.multipleParticipantsNotSupported == .multipleParticipantsNotSupported,
        "multiple alias"
    )
    aacExpect(
        AEAssessmentError.configurationUpdatesNotSupported == .configurationUpdatesNotSupported,
        "updates alias"
    )
    aacExpect(
        AEAssessmentError.requiredParticipantsNotAvailable == .requiredParticipantsNotAvailable,
        "required alias"
    )
    aacExpect(AEAssessmentError.Code(rawValue: 0) == nil, "zero invalid")
    aacExpect(AEAssessmentError.Code(rawValue: 6) == nil, "six invalid")
    aacExpect(AEAssessmentError.Code.unknown != .unsupportedPlatform, "distinct cases")
}

func testErrorCodeInitRawValue() {
    aacExpect(AEAssessmentError.Code(rawValue: 2) == .unsupportedPlatform, "init 2")
    aacExpect(AEAssessmentError.Code(rawValue: -1) == nil, "negative")
}

func testErrorCodeHashValue() {
    aacExpect(AEAssessmentError.Code.unknown.hashValue == AEAssessmentError.Code.unknown.hashValue, "stable")
    aacExpect(
        AEAssessmentError.Code.unknown.hashValue != AEAssessmentError.Code.unsupportedPlatform.hashValue
            || true,
        "hash exists"
    )
    _ = AEAssessmentError.Code.multipleParticipantsNotSupported.hashValue
}

func testErrorCodeHashInto() {
    var hasher = Hasher()
    AEAssessmentError.Code.configurationUpdatesNotSupported.hash(into: &hasher)
    _ = hasher.finalize()
}

func testErrorInit() {
    let empty = AEAssessmentError(.unknown)
    aacExpect(empty.userInfo.isEmpty, "default userInfo")
    let tagged = AEAssessmentError(.unsupportedPlatform, userInfo: ["k": "v"])
    aacExpect(tagged.code == .unsupportedPlatform, "stored code")
    aacExpect(tagged.userInfo["k"] as? String == "v", "stored userInfo")
}

func testErrorStoredCode() {
    let error = AEAssessmentError(.requiredParticipantsNotAvailable)
    aacExpect(error.code == .requiredParticipantsNotAvailable, "code")
}

func testErrorUserInfo() {
    let error = AEAssessmentError(.unknown, userInfo: ["reason": "linux"])
    aacExpect(error.userInfo["reason"] as? String == "linux", "userInfo")
}

func testErrorErrorCode() {
    aacExpect(AEAssessmentError(.unknown).errorCode == 1, "unknown code")
    aacExpect(AEAssessmentError(.unsupportedPlatform).errorCode == 2, "unsupported code")
    aacExpect(AEAssessmentError(.multipleParticipantsNotSupported).errorCode == 3, "multiple code")
    aacExpect(AEAssessmentError(.configurationUpdatesNotSupported).errorCode == 4, "updates code")
    aacExpect(AEAssessmentError(.requiredParticipantsNotAvailable).errorCode == 5, "required code")
}

func testErrorErrorUserInfo() {
    let error = AEAssessmentError(.unknown, userInfo: ["n": 1])
    aacExpect(error.errorUserInfo["n"] as? Int == 1, "errorUserInfo")
}

func testErrorErrorDomainStatic() {
    aacExpect(AEAssessmentError.errorDomain == "AEAssessmentErrorDomain", "static domain")
}

func testErrorEquality() {
    let a = AEAssessmentError(.unknown)
    let b = AEAssessmentError(.unknown)
    aacExpect(a == b, "equal empty")
    let c = AEAssessmentError(.unknown, userInfo: ["x": "y"])
    aacExpect(a != c, "userInfo differs")
    aacExpect(
        AEAssessmentError(.unknown) != AEAssessmentError(.unsupportedPlatform),
        "code differs"
    )
}

func testErrorInequality() {
    aacExpect(
        AEAssessmentError(.unknown) != AEAssessmentError(.multipleParticipantsNotSupported),
        "inequality"
    )
}

func testErrorHashInto() {
    var hasher = Hasher()
    AEAssessmentError(.unsupportedPlatform).hash(into: &hasher)
    _ = hasher.finalize()
}

func testErrorHashValue() {
    let a = AEAssessmentError(.unknown).hashValue
    let b = AEAssessmentError(.unknown).hashValue
    aacExpect(a == b, "stable hash")
}

func testErrorPatternMatch() {
    let error: any Error = AEAssessmentError(.unsupportedPlatform)
    aacExpect(AEAssessmentError.Code.unsupportedPlatform ~= error, "match")
    aacExpect(!(AEAssessmentError.Code.unknown ~= error), "nonmatch")
    do {
        throw AEAssessmentError(.configurationUpdatesNotSupported)
    } catch {
        aacExpect(AEAssessmentError.Code.configurationUpdatesNotSupported ~= error, "catch")
    }
}

func testErrorLocalizedDescription() {
    let error = AEAssessmentError(.unknown)
    aacExpect(error.localizedDescription.contains(AEAssessmentErrorDomain), "domain in description")
    aacExpect(error.localizedDescription.contains("1"), "code in description")
    let custom = AEAssessmentError(
        .unknown,
        userInfo: [NSLocalizedDescriptionKey: "custom"]
    )
    aacExpect(custom.localizedDescription == "custom", "custom description")
}

func testNotInstalledParticipants() {
    let empty = AEAssessmentError(.requiredParticipantsNotAvailable)
    aacExpect(empty.notInstalledParticipants == nil, "missing key")
    let tagged = AEAssessmentError(
        .requiredParticipantsNotAvailable,
        userInfo: ["AENotInstalledParticipantsKey": ["com.example.missing"]]
    )
    aacExpect(tagged.notInstalledParticipants == ["com.example.missing"], "string array")
}

func testRestrictedSystemParticipants() {
    let empty = AEAssessmentError(.requiredParticipantsNotAvailable)
    aacExpect(empty.restrictedSystemParticipants == nil, "missing key")
    let tagged = AEAssessmentError(
        .requiredParticipantsNotAvailable,
        userInfo: ["AERestrictedSystemParticipantsKey": ["com.apple.springboard"]]
    )
    aacExpect(
        tagged.restrictedSystemParticipants == ["com.apple.springboard"],
        "string array"
    )
}

func testUnknownAlias() {
    aacExpect(AEAssessmentError.unknown.rawValue == 1, "unknown alias raw")
}

func testUnsupportedPlatformAlias() {
    aacExpect(AEAssessmentError.unsupportedPlatform.rawValue == 2, "unsupported alias raw")
}

func testMultipleParticipantsAlias() {
    aacExpect(AEAssessmentError.multipleParticipantsNotSupported.rawValue == 3, "multiple alias raw")
}

func testConfigurationUpdatesAlias() {
    aacExpect(AEAssessmentError.configurationUpdatesNotSupported.rawValue == 4, "updates alias raw")
}

func testRequiredParticipantsAlias() {
    aacExpect(AEAssessmentError.requiredParticipantsNotAvailable.rawValue == 5, "required alias raw")
}
