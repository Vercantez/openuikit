import Foundation
import ProximityReader

func testMobileDocumentRequestIdentity() {
    func checkRequest<R: MobileDocumentRequest>(_ value: R, _ other: R) where R.Response: Hashable {
        precondition(value == value)
        precondition(value != other || value == other)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = R.Response.self
    }
    let first = MobilePhotoIDDataRequest(retainedElements: [.givenName])
    let second = MobilePhotoIDDataRequest(retainedElements: [.familyName])
    checkRequest(first, second)
    func responseMetatype<R: MobileDocumentRequest>(_ type: R.Type) -> R.Response.Type {
        R.Response.self
    }
    precondition(responseMetatype(MobilePhotoIDDataRequest.self) == MobilePhotoIDDataRequest.Response.self)
    let response = MobilePhotoIDDataRequest.Response(
        documentElements: MobilePhotoIDDataRequest.Response.DocumentElements(documentNumber: "P9")
    )
    precondition(response.documentElements.documentNumber == "P9")
    _ = response.hashValue
    let boxed: any MobileDocumentRequest = first
    precondition((boxed as? MobilePhotoIDDataRequest) == first)
}

func testMobileDocumentDataProtocols() {
    let dataRequest = MobilePhotoIDDataRequest(retainedElements: [.givenName])
    let asDataRequest: any MobileDocumentDataRequest = dataRequest
    _ = asDataRequest
    precondition((asDataRequest as? MobilePhotoIDDataRequest) == dataRequest)
    var anyOf = MobileDocumentAnyOfDataRequest()
    anyOf.addRequest(dataRequest)
    precondition(anyOf != MobileDocumentAnyOfDataRequest())

    let dataResponse = MobilePhotoIDDataRequest.Response(
        documentElements: MobilePhotoIDDataRequest.Response.DocumentElements()
    )
    let asDataResponse: any MobileDocumentDataResponse = dataResponse
    _ = asDataResponse
    precondition((asDataResponse as? MobilePhotoIDDataRequest.Response) == dataResponse)
    _ = dataResponse.hashValue

    let rawRequest = MobilePhotoIDRawDataRequest(retainedElements: [.givenName])
    let asRawRequest: any MobileDocumentRawDataRequest = rawRequest
    _ = asRawRequest
    precondition((asRawRequest as? MobilePhotoIDRawDataRequest) == rawRequest)
    var anyOfRaw = MobileDocumentAnyOfRawDataRequest()
    anyOfRaw.addRequest(rawRequest)
    precondition(anyOfRaw != MobileDocumentAnyOfRawDataRequest())
    let rawResponse = MobilePhotoIDRawDataRequest.Response(
        responseData: Data([0x05]),
        sessionTranscript: Data([0x06])
    )
    precondition(rawResponse.responseData == Data([0x05]))
}
