import Foundation

/// Unknown-person card. Darwin subclasses `UIViewController` and can
/// create or match an address-book person. Isolated Linux subclasses
/// `NSObject` because UIKit is not on the host-gate link line. The
/// controller stores configuration. It never adds a person to an address
/// book and never invents a resolved record.
@preconcurrency @MainActor
open class ABUnknownPersonViewController: NSObject {
    public override init() {
        super.init()
    }

    /// Documented Darwin default is YES. Linux stores the flag; it never
    /// performs the action buttons.
    open var allowsActions: Bool = true

    /// Documented Darwin default is NO. Linux never writes a new record
    /// even if the caller sets this to `true`.
    open var allowsAddingToAddressBook: Bool = false

    open var alternateName: String?

    open var message: String?

    open var addressBook: ABAddressBook?

    /// ObjC `ABRecordRef` overlay. Callers must assign before reading.
    open var displayedPerson: ABRecord!

    open unowned(unsafe) var unknownPersonViewDelegate: (any ABUnknownPersonViewControllerDelegate)?

    /// Stands in for Darwin "create new" / "add to existing" resolution.
    /// `person` is the caller's record or `nil` (cancel). Linux never
    /// persists.
    open func hostResolve(to person: ABRecord?) {
        unknownPersonViewDelegate?.unknownPersonViewController(self, didResolveToPerson: person)
    }

    /// Queries the optional default-action method. Default is `false`.
    @discardableResult
    open func hostShouldPerformDefaultAction() -> Bool {
        guard let person = displayedPerson else { return false }
        return unknownPersonViewDelegate?.unknownPersonViewController(
            self,
            shouldPerformDefaultActionForPerson: person,
            property: 0,
            identifier: 0
        ) ?? false
    }
}

@preconcurrency @MainActor
public protocol ABUnknownPersonViewControllerDelegate: NSObjectProtocol {
    func unknownPersonViewController(
        _ unknownCardViewController: ABUnknownPersonViewController,
        didResolveToPerson person: ABRecord?
    )

    func unknownPersonViewController(
        _ personViewController: ABUnknownPersonViewController,
        shouldPerformDefaultActionForPerson person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) -> Bool
}

extension ABUnknownPersonViewControllerDelegate {
    public func unknownPersonViewController(
        _ personViewController: ABUnknownPersonViewController,
        shouldPerformDefaultActionForPerson person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) -> Bool {
        _ = personViewController
        _ = person
        _ = property
        _ = identifier
        return false
    }
}
