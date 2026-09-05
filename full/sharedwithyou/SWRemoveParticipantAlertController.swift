import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Alert controller that would confirm removing a collaboration participant.
///
/// Darwin presents a system alert tied to CloudKit sharing. Linux constructs
/// the controller and never presents it.
open class SWRemoveParticipantAlertController: UIViewController {
    public let participant: SWPerson
    public let highlight: SWCollaborationHighlight

    public init(participant: SWPerson, highlight: SWCollaborationHighlight) {
        self.participant = participant
        self.highlight = highlight
        super.init(nibName: nil, bundle: nil)
    }
}
