import Foundation
import IdentityDocumentServices

func testWebPresentmentRawRequestStoresTypeAndData() {
    let payload = Data("cbor-bytes".utf8)
    var raw = IdentityDocumentWebPresentmentRawRequest(
        requestType: .iso18013MobileDocument,
        requestData: payload
    )
    precondition(raw.requestType == .iso18013MobileDocument)
    precondition(raw.requestData == payload)
    raw.requestData = Data()
    precondition(raw.requestData.isEmpty)
}

func testRawRequestTypeIso18013Case() {
    let type = IdentityDocumentWebPresentmentRawRequest.RequestType.iso18013MobileDocument
    precondition(type == .iso18013MobileDocument)
}

func testRawRequestTypeEquality() {
    let a = IdentityDocumentWebPresentmentRawRequest.RequestType.iso18013MobileDocument
    let b = IdentityDocumentWebPresentmentRawRequest.RequestType.iso18013MobileDocument
    precondition(a == b)
}

func testRawRequestTypeInequality() {
    let a = IdentityDocumentWebPresentmentRawRequest.RequestType.iso18013MobileDocument
    precondition(!(a != a))
}

func testRawRequestTypeHash() {
    var hasher = Hasher()
    IdentityDocumentWebPresentmentRawRequest.RequestType.iso18013MobileDocument.hash(into: &hasher)
    _ = hasher.finalize()
    let value = IdentityDocumentWebPresentmentRawRequest.RequestType.iso18013MobileDocument.hashValue
    precondition(value == IdentityDocumentWebPresentmentRawRequest.RequestType.iso18013MobileDocument.hashValue)
}

func testValidatorInitExists() {
    let validator = IdentityDocumentWebPresentmentRawRequestValidator()
    _ = validator
}

func testValidatorEmptyDataThrowsInvalidRequest() {
    let validator = IdentityDocumentWebPresentmentRawRequestValidator()
    let origin = URL(string: "https://verifier.example")!
    do {
        _ = try validator.validateISO18013MobileDocumentRequest(Data(), origin: origin)
        preconditionFailure("empty request must fail closed")
    } catch IdentityDocumentPresentmentError.invalidRequest {
        ()
    } catch {
        preconditionFailure("expected invalidRequest, got \(error)")
    }
}

func testValidatorNonHttpsOriginThrowsInvalidRequest() {
    let validator = IdentityDocumentWebPresentmentRawRequestValidator()
    let origin = URL(string: "http://verifier.example")!
    do {
        _ = try validator.validateISO18013MobileDocumentRequest(Data([0x01]), origin: origin)
        preconditionFailure("http origin must fail closed")
    } catch IdentityDocumentPresentmentError.invalidRequest {
        ()
    } catch {
        preconditionFailure("expected invalidRequest, got \(error)")
    }
}

func testValidatorHttpsPayloadThrowsNotEntitled() {
    let validator = IdentityDocumentWebPresentmentRawRequestValidator()
    let origin = URL(string: "https://verifier.example/presentment")!
    do {
        _ = try validator.validateISO18013MobileDocumentRequest(Data([0xA1]), origin: origin)
        preconditionFailure("Linux must not parse ISO 18013-5 successfully")
    } catch IdentityDocumentPresentmentError.notEntitled {
        ()
    } catch {
        preconditionFailure("expected notEntitled, got \(error)")
    }
}
