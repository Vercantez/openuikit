import Foundation
@_spi(OpenUIKitHost) import IdentityDocumentServicesUI

private struct ProbeWebRequest: IdentityDocumentWebPresentmentRequest {}

private final class ProbeDelegate: IdentityDocumentWebPresentmentControllerDelegate {
    var rawRequestCalls = 0
    var rawRequests: [IdentityDocumentWebPresentmentRawRequest] = []

    func rawRequestsForWebPresentmentController(
        _ webPresentmentController: IdentityDocumentWebPresentmentController
    ) -> [IdentityDocumentWebPresentmentRawRequest] {
        _ = webPresentmentController
        rawRequestCalls += 1
        return rawRequests
    }
}

private final class ProbeAnchorProvider:
    IdentityDocumentPresentmentControllerPresentationContextProviding
{
    var anchorCalls = 0
    var anchor: IdentityDocumentPresentationAnchor?

    func presentationAnchorForPresentmentController(
        _ presentmentController: any IdentityDocumentPresentmentControlling
    ) -> IdentityDocumentPresentationAnchor? {
        _ = presentmentController
        anchorCalls += 1
        return anchor
    }
}

func testIdentityDocumentPresentmentControllingProtocol() {
    let controller = IdentityDocumentWebPresentmentController()
    let asProtocol: any IdentityDocumentPresentmentControlling = controller
    _ = asProtocol
}

func testIdentityDocumentWebPresentmentControllerClass() {
    let controller = IdentityDocumentWebPresentmentController()
    precondition(type(of: controller) == IdentityDocumentWebPresentmentController.self)
    let asProtocol: any IdentityDocumentPresentmentControlling = controller
    _ = asProtocol
    precondition(controller.delegate == nil)
    precondition(controller.presentationContextProvider == nil)
    precondition(controller.hostPhase == .idle)
    precondition(controller.hostLastOrigin == nil)
    precondition(controller.hostLastRequestCount == 0)
}

func testIdentityDocumentWebPresentmentControllerInit() {
    let first = IdentityDocumentWebPresentmentController()
    let second = IdentityDocumentWebPresentmentController()
    precondition(first !== second)
    precondition(first.delegate == nil)
    precondition(second.delegate == nil)
    precondition(first.hostPhase == .idle)
    precondition(second.hostPhase == .idle)
}

func testIdentityDocumentWebPresentmentControllerDelegate() {
    let controller = IdentityDocumentWebPresentmentController()
    precondition(controller.delegate == nil)
    let probe = ProbeDelegate()
    controller.delegate = probe
    precondition(controller.delegate === probe)
    let other = IdentityDocumentWebPresentmentController()
    precondition(other.delegate == nil)
    other.delegate = probe
    precondition(other.delegate === probe)
    precondition(controller.delegate === probe)
    controller.delegate = nil
    precondition(controller.delegate == nil)
    precondition(other.delegate === probe)
}

func testIdentityDocumentWebPresentmentControllerPresentationContextProvider() {
    let controller = IdentityDocumentWebPresentmentController()
    precondition(controller.presentationContextProvider == nil)
    let probe = ProbeAnchorProvider()
    controller.presentationContextProvider = probe
    precondition(controller.presentationContextProvider === probe)
    let other = IdentityDocumentWebPresentmentController()
    precondition(other.presentationContextProvider == nil)
    controller.presentationContextProvider = nil
    precondition(controller.presentationContextProvider == nil)
}

func testIdentityDocumentWebPresentmentControllerPerformRequests() {
    let controller = IdentityDocumentWebPresentmentController()
    let origin = URL(string: "https://rp.example/presentment")!
    let delegate = ProbeDelegate()
    let anchors = ProbeAnchorProvider()
    anchors.anchor = UIWindow()
    controller.delegate = delegate
    controller.presentationContextProvider = anchors
    do {
        _ = try controller.performRequests([], origin: origin)
        preconditionFailure("Linux must not invent a web-presentment response")
    } catch IdentityDocumentServicesUIUnavailable.linuxHost(let operation) {
        precondition(operation == "performRequests")
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
    precondition(controller.hostPhase == .failed)
    precondition(controller.hostLastOrigin == origin)
    precondition(controller.hostLastRequestCount == 0)
    precondition(delegate.rawRequestCalls == 0)
    precondition(anchors.anchorCalls == 0)

    let secondOrigin = URL(string: "https://rp.example/other")!
    do {
        _ = try controller.performRequests(
            [ProbeWebRequest(), ProbeWebRequest()],
            origin: secondOrigin
        )
        preconditionFailure("Linux must not invent a web-presentment response")
    } catch IdentityDocumentServicesUIUnavailable.linuxHost(let operation) {
        precondition(operation == "performRequests")
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
    precondition(controller.hostLastOrigin == secondOrigin)
    precondition(controller.hostLastRequestCount == 2)
    precondition(delegate.rawRequestCalls == 0)
    precondition(anchors.anchorCalls == 0)
}

func testIdentityDocumentWebPresentmentControllerDelegateProtocol() {
    let controller = IdentityDocumentWebPresentmentController()
    let probe: any IdentityDocumentWebPresentmentControllerDelegate = ProbeDelegate()
    controller.delegate = probe
    precondition(controller.delegate === probe)
}

func testRawRequestsForWebPresentmentController() {
    let controller = IdentityDocumentWebPresentmentController()
    let probe = ProbeDelegate()
    precondition(probe.rawRequestsForWebPresentmentController(controller).isEmpty)
    precondition(probe.rawRequestCalls == 1)
    let raw = IdentityDocumentWebPresentmentRawRequest(
        requestType: .iso18013MobileDocument,
        requestData: Data([0x01, 0x02])
    )
    probe.rawRequests = [raw]
    let requests = probe.rawRequestsForWebPresentmentController(controller)
    precondition(requests.count == 1)
    precondition(requests[0].requestType == .iso18013MobileDocument)
    precondition(requests[0].requestData == Data([0x01, 0x02]))
    controller.delegate = probe
    let origin = URL(string: "https://rp.example/presentment")!
    do {
        _ = try controller.performRequests([], origin: origin)
        preconditionFailure("Linux must not invent a web-presentment response")
    } catch IdentityDocumentServicesUIUnavailable.linuxHost(let operation) {
        precondition(operation == "performRequests")
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
    precondition(probe.rawRequestCalls == 2)
}

func testIdentityDocumentPresentmentControllerPresentationContextProvidingProtocol() {
    let controller = IdentityDocumentWebPresentmentController()
    let probe: any IdentityDocumentPresentmentControllerPresentationContextProviding =
        ProbeAnchorProvider()
    controller.presentationContextProvider = probe
    precondition(controller.presentationContextProvider === probe)
}

func testPresentationAnchorForPresentmentController() {
    let controller = IdentityDocumentWebPresentmentController()
    let probe = ProbeAnchorProvider()
    let missing = probe.presentationAnchorForPresentmentController(controller)
    precondition(missing == nil)
    precondition(probe.anchorCalls == 1)
    let window = UIWindow()
    probe.anchor = window
    let found = probe.presentationAnchorForPresentmentController(controller)
    precondition(found === window)
    precondition(type(of: found!) == IdentityDocumentPresentationAnchor.self)
    precondition(probe.anchorCalls == 2)
    controller.presentationContextProvider = probe
    let origin = URL(string: "https://rp.example/presentment")!
    do {
        _ = try controller.performRequests([], origin: origin)
        preconditionFailure("Linux must not invent a web-presentment response")
    } catch IdentityDocumentServicesUIUnavailable.linuxHost(let operation) {
        precondition(operation == "performRequests")
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
    precondition(probe.anchorCalls == 2)
}
