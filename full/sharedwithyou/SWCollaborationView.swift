import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Delegate for collaboration-button popover presentation.
public protocol SWCollaborationViewDelegate: NSObjectProtocol {
    func collaborationViewDidDismissPopover(_ collaborationView: SWCollaborationView)
    func collaborationViewShouldPresentPopover(_ collaborationView: SWCollaborationView) -> Bool
    func collaborationViewWillPresentPopover(_ collaborationView: SWCollaborationView)
}

extension SWCollaborationViewDelegate {
    public func collaborationViewDidDismissPopover(_ collaborationView: SWCollaborationView) {
        _ = collaborationView
    }

    public func collaborationViewShouldPresentPopover(
        _ collaborationView: SWCollaborationView
    ) -> Bool {
        _ = collaborationView
        return true
    }

    public func collaborationViewWillPresentPopover(_ collaborationView: SWCollaborationView) {
        _ = collaborationView
    }
}

/// Collaboration button / popover host.
///
/// Darwin presents CloudKit sharing UI. Linux stores header fields and
/// never presents a popover: `dismissPopover` only runs the completion.
open class SWCollaborationView: UIView {
    public weak var cloudSharingControllerDelegate: (any UICloudSharingControllerDelegate)?
    public weak var cloudSharingDelegate: (any UICloudSharingControllerDelegate)?
    public weak var delegate: (any SWCollaborationViewDelegate)?
    public var activeParticipantCount: Int = 0
    public var headerTitle: String = ""
    public var headerSubtitle: String = ""
    public var headerImage: UIImage = UIImage()
    public var manageButtonTitle: String = ""

    private let itemProvider: NSItemProvider
    var hostShowsManageButton: Bool = false
    var hostContentView: UIView?

    public init(itemProvider: NSItemProvider) {
        self.itemProvider = itemProvider
        super.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        self.itemProvider = NSItemProvider()
        super.init(frame: frame)
    }

    /// Stores the detail list content. Darwin would embed it in the popover.
    public func setContent(_ detailViewListContentView: UIView) {
        hostContentView = detailViewListContentView
    }

    /// Stores the manage-button visibility flag. No button is shown on Linux.
    public func setShowManageButton(_ showManageButton: Bool) {
        hostShowsManageButton = showManageButton
    }

    /// Linux never presents a popover, so this only runs `completion`.
    public func dismissPopover(_ completion: (() -> Void)? = nil) {
        completion?()
    }
}
