import Foundation
import PermissionKit

func testCommunicationLimitsCurrentSingleton() {
    precondition(CommunicationLimits.current === CommunicationLimits.current)
}

func testCommunicationLimitsCurrentType() {
    let limits: CommunicationLimits = .current
    precondition(type(of: limits) == CommunicationLimits.self)
}

func testCommunicationLimitsUpdatesStreamType() {
    let updates: AsyncStream<PermissionResponse<CommunicationTopic>> = CommunicationLimits.current.updates
    precondition(type(of: updates) == AsyncStream<PermissionResponse<CommunicationTopic>>.self)
}

func testCommunicationLimitsIsKnownHandleReturnsFalse() async {
    let handle = CommunicationHandle(value: "+15555550100", kind: .phoneNumber)
    let known = await CommunicationLimits.current.isKnownHandle(handle)
    precondition(known == false)
}

func testCommunicationLimitsKnownHandlesReturnsEmpty() async {
    let handles: Set<CommunicationHandle> = [
        CommunicationHandle(value: "+15555550100", kind: .phoneNumber),
        CommunicationHandle(value: "a@example.com", kind: .emailAddress)
    ]
    let known = await CommunicationLimits.current.knownHandles(in: handles)
    precondition(known.isEmpty)
}

func testCommunicationLimitsAskInViewControllerThrowsNotEnabled() async {
    let question = PermissionQuestion(handle: CommunicationHandle(value: "+15555550100", kind: .phoneNumber))
    let viewController = UIViewController()
    do {
        try await CommunicationLimits.current.ask(question, in: viewController)
        preconditionFailure("ask(_:in:) should throw communicationLimitsNotEnabled")
    } catch let error as AskError {
        switch error {
        case .communicationLimitsNotEnabled: break
        default: preconditionFailure("expected communicationLimitsNotEnabled")
        }
    } catch {
        preconditionFailure("unexpected error type from ask(_:in:)")
    }
}
