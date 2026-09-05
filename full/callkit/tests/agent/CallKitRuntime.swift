@_spi(OpenUIKitHost) import CallKit
import Foundation

private final class SmokeDelegate: NSObject, CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        _ = provider
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        _ = provider
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        _ = provider
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        _ = provider
        action.fulfill()
    }
}

private func request(_ controller: CXCallController, _ transaction: CXTransaction) -> (any Error)? {
    var result: (any Error)?
    controller.requestTransaction(transaction) { error in
        result = error
    }
    return result
}

private func runCallKitRuntimeTests() {
    CallKitHostControl.resetRegistry()

    precondition(CXErrorDomain == "CXErrorDomain")
    precondition(CXError.invalidArgument.rawValue == 2)
    precondition(CXErrorCodeIncomingCallError.callUUIDAlreadyExists.rawValue == 2)
    precondition(CXErrorCodeRequestTransactionError.emptyTransaction.rawValue == 3)
    precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound.rawValue == 1)
    precondition(CXErrorCodeNotificationServiceExtensionError.invalidClientProcess.rawValue == 1)
    precondition(CXCallEndedReason.failed.rawValue == 1)
    precondition(CXHandle.HandleType.phoneNumber.rawValue == 2)

    let provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "OpenUIKit"))
    let delegate = SmokeDelegate()
    provider.setDelegate(delegate, queue: nil)
    let controller = CXCallController()
    let uuid = UUID()
    var incoming: (any Error)?
    provider.reportNewIncomingCall(uuid: uuid, update: CXCallUpdate()) { error in
        incoming = error
    }
    precondition(incoming == nil)
    precondition(request(controller, CXTransaction(action: CXAnswerCallAction(callUUID: uuid))) == nil)
    precondition(request(controller, CXTransaction(action: CXEndCallAction(callUUID: uuid))) == nil)

    var voip: (any Error)?
    CXProvider.reportNewIncomingVoIPPushPayload([:]) { error in
        voip = error
    }
    precondition(CXErrorCodeNotificationServiceExtensionError.invalidClientProcess ~= voip!)

    var settings: (any Error)?
    CXCallDirectoryManager.sharedInstance.openSettings { error in
        settings = error
    }
    precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound ~= settings!)

    CallKitHostControl.resetRegistry()
    print("CALLKIT_AGENT_RUNTIME_OK")
}

runCallKitRuntimeTests()
