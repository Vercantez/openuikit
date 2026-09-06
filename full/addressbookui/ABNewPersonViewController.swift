import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// New-contact editor. Darwin subclasses `UIViewController` and presents
/// the system create-person sheet. Linux stores configuration and delivers
/// the required delegate completion through a host hook. It never writes
/// an `ABRecord` into an address book.
@preconcurrency @MainActor
#if canImport(UIKit)
open class ABNewPersonViewController: UIViewController {
#else
open class ABNewPersonViewController: NSObject {
#endif
    public override init() {
        super.init()
    }

    open var addressBook: ABAddressBook?

    open var displayedPerson: ABRecord?

    open var parentGroup: ABRecord?

    open unowned(unsafe) var newPersonViewDelegate: (any ABNewPersonViewControllerDelegate)?

    /// Stands in for Darwin Done / Cancel dismissal. `person` is the
    /// caller's record, never one this controller created. Passing `nil`
    /// is cancel; Linux never persists a new contact.
    open func hostComplete(with person: ABRecord?) {
        newPersonViewDelegate?.newPersonViewController(self, didCompleteWithNewPerson: person)
    }
}

@preconcurrency @MainActor
public protocol ABNewPersonViewControllerDelegate: NSObjectProtocol {
    func newPersonViewController(
        _ newPersonView: ABNewPersonViewController,
        didCompleteWithNewPerson person: ABRecord?
    )
}
