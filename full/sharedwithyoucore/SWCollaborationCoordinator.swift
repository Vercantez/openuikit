import Foundation

/// Receives start-collaboration and participant-update actions from
/// `SWCollaborationCoordinator`.
///
/// Darwin delivers those actions from the Shared with You daemon. Linux
/// never synthesizes incoming actions; host tests inject them through
/// `@_spi(OpenUIKitHost)`.
public protocol SWCollaborationActionHandler: NSObjectProtocol {
    func collaborationCoordinator(
        _ coordinator: SWCollaborationCoordinator,
        handle action: SWStartCollaborationAction
    )

    func collaborationCoordinator(
        _ coordinator: SWCollaborationCoordinator,
        handle action: SWUpdateCollaborationParticipantsAction
    )
}

/// Process-wide coordinator for Shared with You collaboration actions.
///
/// `shared` is a process-local singleton. Setting `actionHandler` does not
/// subscribe to an Apple daemon. Incoming-action delivery is host-injected
/// and fail-closed when the handler is `nil`.
open class SWCollaborationCoordinator: NSObject {
    private static let sharedInstance = SWCollaborationCoordinator()

    open class var shared: SWCollaborationCoordinator { sharedInstance }

    public weak var actionHandler: (any SWCollaborationActionHandler)?

    private override init() {
        super.init()
    }

    internal func host_deliver(_ action: SWStartCollaborationAction) {
        actionHandler?.collaborationCoordinator(self, handle: action)
    }

    internal func host_deliver(_ action: SWUpdateCollaborationParticipantsAction) {
        actionHandler?.collaborationCoordinator(self, handle: action)
    }
}
