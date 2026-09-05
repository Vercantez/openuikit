@_spi(OpenUIKitHost) import CallKit
import Dispatch
import Foundation

private final class FulfillingDelegate: NSObject, CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        _ = provider
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        _ = provider
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        _ = provider
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        _ = provider
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        _ = provider
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        _ = provider
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        _ = provider
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        _ = provider
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetTranslatingCallAction) {
        _ = provider
        action.fulfill()
    }
}

private func request(_ controller: CXCallController, _ transaction: CXTransaction) -> (any Error)? {
    var result: (any Error)?
    var count = 0
    controller.requestTransaction(transaction) { error in
        result = error
        count += 1
    }
    precondition(count == 1)
    return result
}

func testCXCallControllerInitAndObserver() {
    CallKitHostControl.resetRegistry()
    let controller = CXCallController()
    precondition(type(of: controller) == CXCallController.self)
    precondition(type(of: controller.callObserver) == CXCallObserver.self)
    let queued = CXCallController(queue: DispatchQueue(label: "CallKit.test.controller"))
    precondition(queued.callObserver.calls.isEmpty)
}

func testCXCallControllerEmptyAndUnknownTransactionErrors() {
    CallKitHostControl.resetRegistry()
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let delegate = FulfillingDelegate()
    provider.setDelegate(delegate, queue: nil)
    let controller = CXCallController()
    let empty = request(controller, CXTransaction(actions: []))
    precondition(CXErrorCodeRequestTransactionError.emptyTransaction ~= empty!)
    let unknown = request(controller, CXTransaction(action: CXEndCallAction(callUUID: UUID())))
    precondition(CXErrorCodeRequestTransactionError.unknownCallUUID ~= unknown!)
}

func testCXCallControllerAtomicRejectedStartPair() {
    CallKitHostControl.resetRegistry()
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let delegate = FulfillingDelegate()
    provider.setDelegate(delegate, queue: nil)
    let controller = CXCallController()
    let uuid = UUID()
    let startA = CXStartCallAction(callUUID: uuid, handle: CXHandle(type: .generic, value: "a"))
    let startB = CXStartCallAction(callUUID: uuid, handle: CXHandle(type: .generic, value: "b"))
    let error = request(controller, CXTransaction(actions: [startA, startB]))
    precondition(CXErrorCodeRequestTransactionError.callUUIDAlreadyExists ~= error!)
    precondition(!controller.callObserver.calls.contains(where: { $0.uuid == uuid }))
}

func testCXCallControllerMaximumCallGroupsAndMissingGroupTarget() {
    CallKitHostControl.resetRegistry()
    let configuration = CXProviderConfiguration()
    configuration.maximumCallGroups = 2
    let provider = CXProvider(configuration: configuration)
    let delegate = FulfillingDelegate()
    provider.setDelegate(delegate, queue: nil)
    let controller = CXCallController()
    let first = UUID()
    let second = UUID()
    precondition(
        request(
            controller,
            CXTransaction(action: CXStartCallAction(callUUID: first, handle: CXHandle(type: .generic, value: "1")))
        ) == nil
    )
    precondition(
        request(
            controller,
            CXTransaction(action: CXStartCallAction(callUUID: second, handle: CXHandle(type: .generic, value: "2")))
        ) == nil
    )
    let grouped = CXSetGroupCallAction(callUUID: first, callUUIDToGroupWith: second)
    precondition(request(controller, CXTransaction(action: grouped)) == nil)
    precondition(CallKitHostControl.groupID(for: first) == CallKitHostControl.groupID(for: second))
    let ungroup = CXSetGroupCallAction(call: first, callUUIDToGroupWith: nil)
    precondition(request(controller, CXTransaction(action: ungroup)) == nil)
    let third = UUID()
    let maxed = request(
        controller,
        CXTransaction(action: CXStartCallAction(callUUID: third, handle: CXHandle(type: .generic, value: "3")))
    )
    precondition(CXErrorCodeRequestTransactionError.maximumCallGroupsReached ~= maxed!)
    let missing = CXSetGroupCallAction(callUUID: first, callUUIDToGroupWith: UUID())
    let missingError = request(controller, CXTransaction(action: missing))
    precondition(CXErrorCodeRequestTransactionError.unknownCallUUID ~= missingError!)
}

func testCXCallControllerTwoProvidersRejectUnownedStart() {
    CallKitHostControl.resetRegistry()
    let first = CXProvider(configuration: CXProviderConfiguration())
    let second = CXProvider(configuration: CXProviderConfiguration())
    let firstDelegate = FulfillingDelegate()
    let secondDelegate = FulfillingDelegate()
    first.setDelegate(firstDelegate, queue: nil)
    second.setDelegate(secondDelegate, queue: nil)
    let controller = CXCallController()
    let error = request(
        controller,
        CXTransaction(action: CXStartCallAction(callUUID: UUID(), handle: CXHandle(type: .generic, value: "x")))
    )
    precondition(CXErrorCodeRequestTransactionError.unknownCallProvider ~= error!)
    let owned = UUID()
    var incoming: (any Error)?
    first.reportNewIncomingCall(uuid: owned, update: CXCallUpdate()) { error in
        incoming = error
    }
    precondition(incoming == nil)
    precondition(request(controller, CXTransaction(action: CXAnswerCallAction(call: owned))) == nil)
    precondition(controller.callObserver.calls.contains(where: { $0.uuid == owned && $0.hasConnected }))
}

func testCXCallSnapshotProperties() {
    CallKitHostControl.resetRegistry()
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let delegate = FulfillingDelegate()
    provider.setDelegate(delegate, queue: nil)
    let controller = CXCallController()
    let uuid = UUID()
    provider.reportNewIncomingCall(uuid: uuid, update: CXCallUpdate()) { _ in }
    let call = controller.callObserver.calls.first { $0.uuid == uuid }
    precondition(call != nil)
    precondition(call?.uuid == uuid)
    precondition(call?.isOutgoing == false)
    precondition(call?.isOnHold == false)
    precondition(call?.hasConnected == false)
    precondition(call?.hasEnded == false)
    precondition(type(of: call!) == CXCall.self)
}
