import Foundation
@_spi(OpenUIKitHost) import IdentityLookupUI

private final class ProbeClassificationViewController: ILClassificationUIExtensionViewController {
    var overrideRequest: ILClassificationRequest?
    var overrideResponseAction: ILClassificationAction = .reportJunk

    override func prepare(for request: ILClassificationRequest) {
        overrideRequest = request
        super.prepare(for: request)
    }

    override func classificationResponse(for request: ILClassificationRequest) -> ILClassificationResponse {
        _ = request
        return ILClassificationResponse(action: overrideResponseAction)
    }
}

func testClassificationUIExtensionViewControllerClass() {
    let controller = ILClassificationUIExtensionViewController()
    let asViewController: UIViewController = controller
    precondition(asViewController === controller)
    precondition(type(of: controller) == ILClassificationUIExtensionViewController.self)
    precondition(controller.hostPreparedRequest == nil)
    precondition(controller.hostLastClassificationResponse == nil)
    precondition(controller.hostPhase == .idle)
    precondition(controller.extensionContext.isReadyForClassificationResponse == false)
}

func testExtensionContext() {
    let controller = ILClassificationUIExtensionViewController()
    let context = controller.extensionContext
    precondition(type(of: context) == ILClassificationUIExtensionContext.self)
    precondition(controller.extensionContext === context)
    precondition(context.isReadyForClassificationResponse == false)
    context.isReadyForClassificationResponse = true
    precondition(controller.extensionContext.isReadyForClassificationResponse == true)
    precondition(controller.extensionContext === context)
    let other = ILClassificationUIExtensionViewController()
    precondition(other.extensionContext !== context)
    precondition(other.extensionContext.isReadyForClassificationResponse == false)
}

func testPrepareForClassificationRequest() {
    let controller = ProbeClassificationViewController()
    let request = ILClassificationRequest()
    precondition(controller.hostPhase == .idle)
    controller.prepare(for: request)
    precondition(controller.overrideRequest === request)
    precondition(controller.hostPreparedRequest === request)
    precondition(controller.hostPhase == .prepared)
    precondition(controller.extensionContext.isReadyForClassificationResponse == false)
    let second = ILClassificationRequest()
    controller.prepare(for: second)
    precondition(controller.hostPreparedRequest === second)
    precondition(controller.overrideRequest === second)
    precondition(controller.hostPhase == .prepared)
    controller.extensionContext.isReadyForClassificationResponse = true
    let third = ILClassificationRequest()
    controller.prepare(for: third)
    precondition(controller.hostPreparedRequest === third)
    precondition(controller.extensionContext.isReadyForClassificationResponse == true)
}

func testClassificationResponseForRequest() {
    let controller = ILClassificationUIExtensionViewController()
    let request = ILClassificationRequest()
    let response = controller.classificationResponse(for: request)
    precondition(response.action == .none)
    precondition(controller.hostLastClassificationResponse === response)
    controller.extensionContext.isReadyForClassificationResponse = true
    let readyResponse = controller.classificationResponse(for: request)
    precondition(readyResponse.action == .none)
    precondition(controller.hostLastClassificationResponse === readyResponse)
    let probe = ProbeClassificationViewController()
    probe.overrideResponseAction = .reportJunk
    let overridden = probe.classificationResponse(for: request)
    precondition(overridden.action == .reportJunk)
    probe.overrideResponseAction = .reportNotJunk
    precondition(probe.classificationResponse(for: request).action == .reportNotJunk)
    probe.overrideResponseAction = .reportJunkAndBlockSender
    precondition(probe.classificationResponse(for: request).action == .reportJunkAndBlockSender)
    let baseAfterPrepare = ILClassificationUIExtensionViewController()
    baseAfterPrepare.prepare(for: request)
    precondition(baseAfterPrepare.classificationResponse(for: request).action == .none)
}
