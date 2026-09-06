import Foundation
@_spi(OpenUIKitHost) import IdentityDocumentServicesUI

private struct ProbeView: View, Sendable {
    var body: EmptyView { EmptyView() }
}

private func makeMarkedRequest() -> ISO18013MobileDocumentRequest {
    ISO18013MobileDocumentRequest(
        presentmentRequests: [
            ISO18013MobileDocumentRequest.PresentmentRequest(
                documentRequestSets: [
                    ISO18013MobileDocumentRequest.DocumentRequestSet(
                        requests: [
                            ISO18013MobileDocumentRequest.DocumentRequest(
                                documentType: "org.iso.18013.5.mDL",
                                namespaces: [
                                    "org.iso.18013.5.1": [
                                        "family_name": ISO18013MobileDocumentRequest.ElementInfo(
                                            isRetaining: false
                                        )
                                    ]
                                ]
                            )
                        ]
                    )
                ],
                isMandatory: true
            )
        ],
        requestAuthentications: []
    )
}

func testISO18013MobileDocumentRequestContextType() {
    let context = ISO18013MobileDocumentRequestContext.hostMakeContext()
    precondition(type(of: context) == ISO18013MobileDocumentRequestContext.self)
    precondition(context.hostPhase == .idle)
    precondition(context.hostSendAttemptCount == 0)
    precondition(context.hostCancelCount == 0)
    precondition(context.requestingWebsiteOrigin == nil)
    precondition(context.request.presentmentRequests.isEmpty)
}

func testISO18013MobileDocumentRequestContextRequestingWebsiteOrigin() {
    let empty = ISO18013MobileDocumentRequestContext.hostMakeContext()
    precondition(empty.requestingWebsiteOrigin == nil)
    let origin = URL(string: "https://rp.example")!
    let withOrigin = ISO18013MobileDocumentRequestContext.hostMakeContext(
        requestingWebsiteOrigin: origin
    )
    precondition(withOrigin.requestingWebsiteOrigin == origin)
    precondition(empty.requestingWebsiteOrigin == nil)
    let other = URL(string: "https://rp.example/other")!
    let second = ISO18013MobileDocumentRequestContext.hostMakeContext(
        requestingWebsiteOrigin: other
    )
    precondition(second.requestingWebsiteOrigin == other)
    precondition(withOrigin.requestingWebsiteOrigin == origin)
}

func testISO18013MobileDocumentRequestContextRequest() {
    let empty = ISO18013MobileDocumentRequestContext.hostMakeContext()
    precondition(empty.request.presentmentRequests.isEmpty)
    precondition(empty.request.requestAuthentications.isEmpty)
    let request = makeMarkedRequest()
    let context = ISO18013MobileDocumentRequestContext.hostMakeContext(request: request)
    precondition(context.request.presentmentRequests.count == 1)
    precondition(context.request.presentmentRequests[0].isMandatory == true)
    let sets = context.request.presentmentRequests[0].documentRequestSets
    precondition(sets.count == 1)
    precondition(sets[0].requests[0].documentType == "org.iso.18013.5.mDL")
    precondition(
        sets[0].requests[0].namespaces["org.iso.18013.5.1"]?["family_name"]?.isRetaining
            == false
    )
    precondition(empty.request.presentmentRequests.isEmpty)
}

func testISO18013MobileDocumentRequestContextCancel() {
    let context = ISO18013MobileDocumentRequestContext.hostMakeContext()
    precondition(context.hostPhase == .idle)
    context.cancel()
    precondition(context.hostPhase == .cancelled)
    precondition(context.hostCancelCount == 1)
    context.cancel()
    precondition(context.hostPhase == .cancelled)
    precondition(context.hostCancelCount == 2)
    let copy = context
    copy.cancel()
    precondition(context.hostCancelCount == 3)
    precondition(copy.hostPhase == .cancelled)
    do {
        try context.sendResponse { _ in
            preconditionFailure("handler must not run after cancel")
        }
        preconditionFailure("cancelled sendResponse must throw")
    } catch IdentityDocumentServicesUIUnavailable.linuxHost(let operation) {
        precondition(operation == "sendResponse.cancelled")
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
    precondition(context.hostSendAttemptCount == 0)
}

func testISO18013MobileDocumentRequestContextSendResponse() {
    let context = ISO18013MobileDocumentRequestContext.hostMakeContext()
    do {
        try context.sendResponse { _ in
            preconditionFailure("handler must not run without a presentment session")
        }
        preconditionFailure("Linux must not invent a presentment raw request")
    } catch IdentityDocumentServicesUIUnavailable.linuxHost(let operation) {
        precondition(operation == "sendResponse")
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
    precondition(context.hostPhase == .sendAttempted)
    precondition(context.hostSendAttemptCount == 1)
    do {
        try context.sendResponse { _ in
            preconditionFailure("handler must not run on a second sendResponse")
        }
        preconditionFailure("second sendResponse must throw")
    } catch IdentityDocumentServicesUIUnavailable.linuxHost(let operation) {
        precondition(operation == "sendResponse.requestInProgress")
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
    precondition(context.hostSendAttemptCount == 1)
}

func testISO18013MobileDocumentRequestSceneType() {
    let scene = ISO18013MobileDocumentRequestScene<ProbeView> { _ in ProbeView() }
    precondition(type(of: scene) == ISO18013MobileDocumentRequestScene<ProbeView>.self)
    let asScene: any IdentityDocumentRequestScene = scene
    _ = asScene
}

func testISO18013MobileDocumentRequestSceneBodyTypealias() {
    precondition(
        ISO18013MobileDocumentRequestScene<ProbeView>.Body.self
            == IdentityDocumentHostRequestScene.self
    )
}

func testISO18013MobileDocumentRequestSceneInit() {
    var received: ISO18013MobileDocumentRequestContext?
    let scene = ISO18013MobileDocumentRequestScene<ProbeView> { context in
        received = context
        return ProbeView()
    }
    let rendered = scene.hostRenderContent()
    precondition(type(of: rendered) == ProbeView.self)
    precondition(received != nil)
    precondition(received?.hostPhase == .idle)
    received?.cancel()
    precondition(scene.hostContext.hostPhase == .cancelled)
}

func testISO18013MobileDocumentRequestSceneBody() {
    let scene = ISO18013MobileDocumentRequestScene<ProbeView> { _ in ProbeView() }
    let body = scene.body
    precondition(type(of: body) == IdentityDocumentHostRequestScene.self)
    let asScene: any AppExtensionScene = body
    _ = asScene
}
