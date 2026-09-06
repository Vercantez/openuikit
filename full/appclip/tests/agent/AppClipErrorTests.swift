import AppClip
import Foundation

func testErrorDomainConstant() {
    precondition(APActivationPayloadErrorDomain == "APActivationPayloadErrorDomain")
}

func testErrorCodeRawValues() {
    precondition(APActivationPayloadError.Code.disallowed.rawValue == 1)
    precondition(APActivationPayloadError.Code.doesNotMatch.rawValue == 2)
    precondition(APActivationPayloadError.disallowed == .disallowed)
    precondition(APActivationPayloadError.doesNotMatch == .doesNotMatch)
    precondition(APActivationPayloadError.Code.disallowed != .doesNotMatch)
    precondition(APActivationPayloadError.Code(rawValue: 1) == .disallowed)
    precondition(APActivationPayloadError.Code(rawValue: 2) == .doesNotMatch)
    precondition(APActivationPayloadError.Code(rawValue: 0) == nil)
    precondition(APActivationPayloadError.Code(rawValue: 3) == nil)
    precondition(APActivationPayloadError.Code(rawValue: -1) == nil)
    _ = APActivationPayloadError.Code.self
}

func testCustomNSErrorDomain() {
    precondition(APActivationPayloadError.errorDomain == APActivationPayloadErrorDomain)
    let typed: APActivationPayloadError.Type = APActivationPayloadError.self
    precondition(typed.errorDomain == "APActivationPayloadErrorDomain")
}

func testCustomNSErrorUserInfo() {
    let error = APActivationPayloadError(.disallowed, userInfo: ["k": "v"])
    precondition(error.errorUserInfo["k"] as? String == "v")
}

func testCustomNSErrorCode() {
    let error = APActivationPayloadError(.doesNotMatch)
    precondition(error.errorCode == 2)
}

func testErrorCodePatternMatch() {
    let error: any Error = APActivationPayloadError(.doesNotMatch)
    precondition(APActivationPayloadError.Code.doesNotMatch ~= error)
    precondition(!(APActivationPayloadError.Code.disallowed ~= error))
    do {
        throw APActivationPayloadError(.disallowed)
    } catch let error as APActivationPayloadError where error.code == .disallowed {
        precondition(APActivationPayloadError.Code.disallowed ~= error)
    } catch {
        preconditionFailure("expected Code.disallowed pattern match")
    }
}

func testBridgedErrorUserInfo() {
    let error = APActivationPayloadError(.disallowed, userInfo: ["bridged": 7])
    precondition(error.errorUserInfo["bridged"] as? Int == 7)
}

func testErrorEquality() {
    let left = APActivationPayloadError(.disallowed)
    let right = APActivationPayloadError(.disallowed)
    let other = APActivationPayloadError(.doesNotMatch)
    precondition(left == right)
    precondition(!(left == other))
}

func testBridgedErrorCode() {
    let error = APActivationPayloadError(.doesNotMatch)
    precondition(error.code == .doesNotMatch)
    precondition(error.code.rawValue == 2)
}

func testErrorHashInto() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    APActivationPayloadError(.disallowed).hash(into: &hasherA)
    APActivationPayloadError(.disallowed).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testBridgedUserInfo() {
    let empty = APActivationPayloadError(.disallowed)
    precondition(empty.userInfo.isEmpty)
    let filled = APActivationPayloadError(
        .doesNotMatch,
        userInfo: [NSLocalizedDescriptionKey: "host"]
    )
    precondition(filled.userInfo[NSLocalizedDescriptionKey] as? String == "host")
}

func testBridgedErrorCodeProperty() {
    let error = APActivationPayloadError(.disallowed)
    precondition(error.errorCode == 1)
    let nsError = error as NSError
    precondition(nsError.code == 1)
    precondition(nsError.domain == APActivationPayloadErrorDomain)
}

func testErrorHashValue() {
    let a = APActivationPayloadError(.doesNotMatch)
    let b = APActivationPayloadError(.doesNotMatch, userInfo: ["x": 1])
    precondition(a.hashValue == b.hashValue)
    var seen: Set<Int> = []
    seen.insert(a.hashValue)
    seen.insert(b.hashValue)
    precondition(seen.count == 1)
}

func testErrorInitUserInfo() {
    let defaulted = APActivationPayloadError(.disallowed)
    precondition(defaulted.userInfo.isEmpty)
    precondition(defaulted.code == .disallowed)
    let custom = APActivationPayloadError(.doesNotMatch, userInfo: ["n": 2])
    precondition(custom.userInfo["n"] as? Int == 2)
    precondition(custom.code == .doesNotMatch)
}

func testErrorStructIdentity() {
    func bridgedDomain<E: Foundation._BridgedStoredNSError>(_: E.Type) -> String {
        E._nsErrorDomain
    }
    precondition(bridgedDomain(APActivationPayloadError.self) == APActivationPayloadErrorDomain)
    _ = APActivationPayloadError.self
}

func testOverlayErrorDomain() {
    precondition(APActivationPayloadError.errorDomain == APActivationPayloadErrorDomain)
    precondition(APActivationPayloadError._nsErrorDomain == APActivationPayloadErrorDomain)
}

func testErrorInequality() {
    let disallowed = APActivationPayloadError(.disallowed)
    let mismatch = APActivationPayloadError(.doesNotMatch)
    precondition(disallowed != mismatch)
    precondition(!(disallowed != APActivationPayloadError(.disallowed)))
}

func testCodeHashValue() {
    precondition(
        APActivationPayloadError.Code.disallowed.hashValue
            == APActivationPayloadError.Code.disallowed.hashValue
    )
    var seen: Set<APActivationPayloadError.Code> = []
    seen.insert(.disallowed)
    seen.insert(.disallowed)
    seen.insert(.doesNotMatch)
    precondition(seen.count == 2)
}

func testCodeHashInto() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    APActivationPayloadError.Code.doesNotMatch.hash(into: &hasherA)
    APActivationPayloadError.Code.doesNotMatch.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testLocalizedDescriptionNonempty() {
    let error = APActivationPayloadError(.disallowed)
    precondition(!error.localizedDescription.isEmpty)
}
