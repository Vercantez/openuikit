@_spi(OpenUIKitHost) import SharedWithYouCore
import Foundation

private final class RecordingHandler: NSObject, SWCollaborationActionHandler {
    var startActions: [SWStartCollaborationAction] = []
    var updateActions: [SWUpdateCollaborationParticipantsAction] = []
    var lastCoordinator: SWCollaborationCoordinator?

    func collaborationCoordinator(
        _ coordinator: SWCollaborationCoordinator,
        handle action: SWStartCollaborationAction
    ) {
        lastCoordinator = coordinator
        startActions.append(action)
    }

    func collaborationCoordinator(
        _ coordinator: SWCollaborationCoordinator,
        handle action: SWUpdateCollaborationParticipantsAction
    ) {
        lastCoordinator = coordinator
        updateActions.append(action)
    }
}

func testSWCollaborationActionHandlerProtocol() {
    let handler = RecordingHandler()
    let coordinator = SWCollaborationCoordinator.shared
    SharedWithYouCoreHostControl.resetSharedCoordinator()
    coordinator.actionHandler = handler
    precondition((coordinator.actionHandler as AnyObject?) === handler)
    SharedWithYouCoreHostControl.resetSharedCoordinator()
}

func testSWCollaborationActionHandlerHandleStart() {
    SharedWithYouCoreHostControl.resetSharedCoordinator()
    let handler = RecordingHandler()
    let coordinator = SWCollaborationCoordinator.shared
    coordinator.actionHandler = handler
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("handler.start")
    )
    let action = SharedWithYouCoreHostControl.makeStartCollaborationAction(metadata: metadata)
    SharedWithYouCoreHostControl.deliverStartAction(action, on: coordinator)
    precondition(handler.startActions.count == 1)
    precondition(handler.startActions[0] === action)
    precondition(handler.lastCoordinator === coordinator)
    precondition(handler.updateActions.isEmpty)
    SharedWithYouCoreHostControl.resetSharedCoordinator()
}

func testSWCollaborationActionHandlerHandleUpdate() {
    SharedWithYouCoreHostControl.resetSharedCoordinator()
    let handler = RecordingHandler()
    let coordinator = SWCollaborationCoordinator.shared
    coordinator.actionHandler = handler
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("handler.update")
    )
    let action = SharedWithYouCoreHostControl.makeUpdateCollaborationParticipantsAction(
        metadata: metadata,
        addedIdentities: [SWPerson.Identity(rootHash: Data([0x01]))]
    )
    SharedWithYouCoreHostControl.deliverUpdateAction(action, on: coordinator)
    precondition(handler.updateActions.count == 1)
    precondition(handler.updateActions[0] === action)
    precondition(handler.startActions.isEmpty)
    SharedWithYouCoreHostControl.resetSharedCoordinator()
}
