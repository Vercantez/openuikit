@_spi(OpenUIKitHost) import SharedWithYouCore
import Foundation

private final class RecordingHandler: NSObject, SWCollaborationActionHandler {
    var startCount = 0
    var updateCount = 0

    func collaborationCoordinator(
        _ coordinator: SWCollaborationCoordinator,
        handle action: SWStartCollaborationAction
    ) {
        _ = coordinator
        _ = action
        startCount += 1
    }

    func collaborationCoordinator(
        _ coordinator: SWCollaborationCoordinator,
        handle action: SWUpdateCollaborationParticipantsAction
    ) {
        _ = coordinator
        _ = action
        updateCount += 1
    }
}

func testSWCollaborationCoordinatorClass() {
    let coordinator = SWCollaborationCoordinator.shared
    swcRequireType(coordinator, as: SWCollaborationCoordinator.self)
}

func testSWCollaborationCoordinatorShared() {
    let first = SWCollaborationCoordinator.shared
    let second = SWCollaborationCoordinator.shared
    precondition(first === second)
}

func testSWCollaborationCoordinatorActionHandler() {
    SharedWithYouCoreHostControl.resetSharedCoordinator()
    let coordinator = SWCollaborationCoordinator.shared
    precondition(coordinator.actionHandler == nil)
    let handler = RecordingHandler()
    coordinator.actionHandler = handler
    precondition(coordinator.actionHandler === handler)
    coordinator.actionHandler = nil
    precondition(coordinator.actionHandler == nil)
}
