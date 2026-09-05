@_spi(OpenUIKitHost) import CallKit
import Foundation

private final class ObserverProbe: NSObject, CXCallObserverDelegate {
    var calls: [CXCall] = []

    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        _ = callObserver
        calls.append(call)
    }
}

private final class FulfillingDelegate: NSObject, CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        _ = provider
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        _ = provider
        action.fulfill()
    }
}

func testCXCallObserverSetDelegateAndCalls() {
    CallKitHostControl.resetRegistry()
    let observer = CXCallObserver()
    let probe = ObserverProbe()
    observer.setDelegate(probe, queue: nil)
    precondition(observer.calls.isEmpty)
    precondition(type(of: observer) == CXCallObserver.self)

    let provider = CXProvider(configuration: CXProviderConfiguration())
    let fulfilling = FulfillingDelegate()
    provider.setDelegate(fulfilling, queue: nil)
    let uuid = UUID()
    provider.reportNewIncomingCall(uuid: uuid, update: CXCallUpdate()) { _ in }
    precondition(observer.calls.contains(where: { $0.uuid == uuid }))
    precondition(probe.calls.contains(where: { $0.uuid == uuid }))
}

func testCXCallObserverDelegateIdentity() {
    let delegate: any CXCallObserverDelegate = ObserverProbe()
    _ = delegate
}

func testCXCallEquality() {
    CallKitHostControl.resetRegistry()
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let fulfilling = FulfillingDelegate()
    provider.setDelegate(fulfilling, queue: nil)
    let uuid = UUID()
    provider.reportNewIncomingCall(uuid: uuid, update: CXCallUpdate()) { _ in }
    let first = CXCallObserver().calls.first { $0.uuid == uuid }
    let second = CXCallObserver().calls.first { $0.uuid == uuid }
    precondition(first != nil && second != nil)
    precondition(first!.isEqual(second!))
    precondition(first!.hash == second!.hash)
}
