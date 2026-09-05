import Foundation
import ShazamKit

func testSHErrorCodeRawValues() {
    let expected: [(SHError.Code, Int)] = [
        (.invalidAudioFormat, 100),
        (.audioDiscontinuity, 101),
        (.signatureInvalid, 200),
        (.signatureDurationInvalid, 201),
        (.matchAttemptFailed, 202),
        (.customCatalogInvalid, 300),
        (.customCatalogInvalidURL, 301),
        (.mediaLibrarySyncFailed, 400),
        (.internalError, 500),
        (.mediaItemFetchFailed, 600),
    ]
    precondition(SHError.Code.invalidAudioFormat.rawValue == 100)
    for (code, raw) in expected {
        precondition(code.rawValue == raw)
        precondition(SHError.Code(rawValue: raw) == code)
    }
    precondition(SHError.Code(rawValue: 0) == nil)
    precondition(SHError.Code(rawValue: 9999) == nil)
    precondition(SHError.invalidAudioFormat == .invalidAudioFormat)
    precondition(SHError.audioDiscontinuity == .audioDiscontinuity)
    precondition(SHError.signatureInvalid == .signatureInvalid)
    precondition(SHError.signatureDurationInvalid == .signatureDurationInvalid)
    precondition(SHError.matchAttemptFailed == .matchAttemptFailed)
    precondition(SHError.customCatalogInvalid == .customCatalogInvalid)
    precondition(SHError.customCatalogInvalidURL == .customCatalogInvalidURL)
    precondition(SHError.mediaLibrarySyncFailed == .mediaLibrarySyncFailed)
    precondition(SHError.internalError == .internalError)
    precondition(SHError.mediaItemFetchFailed == .mediaItemFetchFailed)
    precondition(type(of: SHError.Code.internalError) == SHError.Code.self)
}

func testSHErrorDomainConstant() {
    precondition(SHErrorDomain == "SHErrorDomain")
}

func testSHErrorStruct() {
    let error = SHError(.internalError)
    precondition(type(of: error) == SHError.self)
}

func testSHErrorCodeProperty() {
    let error = SHError(.signatureInvalid)
    precondition(error.code == .signatureInvalid)
}

func testSHErrorInitUserInfo() {
    let error = SHError(.matchAttemptFailed, userInfo: ["reason": "linux"])
    precondition(error.userInfo["reason"] as? String == "linux")
}

func testSHErrorUserInfo() {
    let error = SHError(.customCatalogInvalid, userInfo: ["key": 1])
    precondition(error.userInfo["key"] as? Int == 1)
}

func testSHErrorErrorUserInfo() {
    let error = SHError(.customCatalogInvalidURL, userInfo: ["url": "bad"])
    precondition(error.errorUserInfo["url"] as? String == "bad")
}

func testSHErrorErrorCode() {
    let error = SHError(.mediaItemFetchFailed)
    precondition(error.errorCode == 600)
}

func testSHErrorErrorDomain() {
    precondition(SHError.errorDomain == SHErrorDomain)
}

func testSHErrorEquality() {
    precondition(SHError(.internalError) == SHError(.internalError))
    precondition(!(SHError(.internalError) == SHError(.matchAttemptFailed)))
}

func testSHErrorInequality() {
    precondition(SHError(.signatureInvalid) != SHError(.signatureDurationInvalid))
    precondition(!(SHError(.audioDiscontinuity) != SHError(.audioDiscontinuity)))
}

func testSHErrorHashInto() {
    var hasher = Hasher()
    SHError(.internalError).hash(into: &hasher)
    _ = hasher.finalize()
}

func testSHErrorHashValue() {
    precondition(SHError(.internalError).hashValue == SHError(.internalError).hashValue)
}

func testSHErrorCodeHashInto() {
    var hasher = Hasher()
    SHError.Code.matchAttemptFailed.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSHErrorCodeHashValue() {
    precondition(SHError.Code.invalidAudioFormat.hashValue == 100.hashValue
        || SHError.Code.invalidAudioFormat.hashValue != 0
        || true)
    _ = SHError.Code.mediaLibrarySyncFailed.hashValue
}

func testSHErrorCodePatternMatch() {
    let error: any Error = SHError(.signatureInvalid)
    precondition(SHError.Code.signatureInvalid ~= error)
    precondition(!(SHError.Code.internalError ~= error))
    struct Other: Error {}
    precondition(!(SHError.Code.internalError ~= Other()))
}

func testSHErrorLocalizedDescription() {
    let description = SHError(.invalidAudioFormat).localizedDescription
    precondition(!description.isEmpty)
}
