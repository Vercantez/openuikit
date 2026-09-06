import Foundation
import IdentityDocumentServices

func testElementInfoIsRetaining() {
    var info = ISO18013MobileDocumentRequest.ElementInfo(isRetaining: true)
    precondition(info.isRetaining == true)
    info.isRetaining = false
    precondition(info.isRetaining == false)
}

func testDocumentRequestStoresTypeAndNamespaces() {
    let element = ISO18013MobileDocumentRequest.ElementInfo(isRetaining: true)
    let request = ISO18013MobileDocumentRequest.DocumentRequest(
        documentType: "org.iso.18013.5.mDL",
        namespaces: ["org.iso.18013.5.1": ["family_name": element]]
    )
    precondition(request.documentType == "org.iso.18013.5.mDL")
    precondition(request.namespaces["org.iso.18013.5.1"]?["family_name"]?.isRetaining == true)
}

func testDocumentRequestSetStoresRequests() {
    let document = ISO18013MobileDocumentRequest.DocumentRequest(
        documentType: "org.iso.18013.5.mDL",
        namespaces: [:]
    )
    var set = ISO18013MobileDocumentRequest.DocumentRequestSet(requests: [document])
    precondition(set.requests.count == 1)
    precondition(set.requests[0].documentType == "org.iso.18013.5.mDL")
    set.requests = []
    precondition(set.requests.isEmpty)
}

func testPresentmentRequestMandatoryFlag() {
    let set = ISO18013MobileDocumentRequest.DocumentRequestSet(requests: [])
    var presentment = ISO18013MobileDocumentRequest.PresentmentRequest(
        documentRequestSets: [set],
        isMandatory: true
    )
    precondition(presentment.documentRequestSets.count == 1)
    precondition(presentment.isMandatory == true)
    presentment.isMandatory = false
    precondition(presentment.isMandatory == false)
}

func testRequestAuthenticationEmptyCertificateChain() {
    var authentication = ISO18013MobileDocumentRequest.RequestAuthentication(
        authenticationCertificateChain: []
    )
    precondition(authentication.authenticationCertificateChain.isEmpty)
    authentication.authenticationCertificateChain = []
    precondition(authentication.authenticationCertificateChain.count == 0)
}

func testISO18013MobileDocumentRequestRoundTrip() {
    let element = ISO18013MobileDocumentRequest.ElementInfo(isRetaining: false)
    let document = ISO18013MobileDocumentRequest.DocumentRequest(
        documentType: "org.iso.18013.5.mDL",
        namespaces: ["org.iso.18013.5.1": ["given_name": element]]
    )
    let set = ISO18013MobileDocumentRequest.DocumentRequestSet(requests: [document])
    let presentment = ISO18013MobileDocumentRequest.PresentmentRequest(
        documentRequestSets: [set],
        isMandatory: true
    )
    let authentication = ISO18013MobileDocumentRequest.RequestAuthentication(
        authenticationCertificateChain: []
    )
    var request = ISO18013MobileDocumentRequest(
        presentmentRequests: [presentment],
        requestAuthentications: [authentication]
    )
    precondition(request.presentmentRequests.count == 1)
    precondition(request.presentmentRequests[0].isMandatory == true)
    precondition(request.requestAuthentications.count == 1)
    request.presentmentRequests = []
    precondition(request.presentmentRequests.isEmpty)
}

func testISO18013MobileDocumentResponseStoresData() {
    let payload = Data([0xA0, 0x01, 0x02])
    let response = ISO18013MobileDocumentResponse(responseData: payload)
    precondition(response.responseData == payload)
}

func testISO18013MobileDocumentResponseConformsToWebPresentment() {
    let response = ISO18013MobileDocumentResponse(responseData: Data())
    let asProtocol: any IdentityDocumentWebPresentmentResponse = response
    _ = asProtocol
}

func testISO18013MobileDocumentRequestConformsToWebPresentment() {
    let request = ISO18013MobileDocumentRequest(
        presentmentRequests: [],
        requestAuthentications: []
    )
    let asProtocol: any IdentityDocumentWebPresentmentRequest = request
    _ = asProtocol
}
