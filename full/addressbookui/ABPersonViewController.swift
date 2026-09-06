import Foundation

/// Person inspector. Darwin subclasses `UIViewController` and presents
/// the system contact card. Isolated Linux subclasses `NSObject`
/// because UIKit is not on the host-gate link line. The controller stores
/// configuration and the highlighted item. Default actions (call,
/// message, mail) are never performed.
@preconcurrency @MainActor
open class ABPersonViewController: NSObject {
    public private(set) var highlightedProperty: ABPropertyID?
    public private(set) var highlightedIdentifier: ABMultiValueIdentifier?

    /// Documented Darwin default is YES. Linux stores the flag; it never
    /// performs the action buttons the flag would reveal.
    open var allowsActions: Bool = true

    /// Documented Darwin default is NO.
    open var allowsEditing: Bool = false

    /// Documented Darwin default is NO.
    open var shouldShowLinkedPeople: Bool = false

    open var addressBook: ABAddressBook?

    /// ObjC `ABRecordRef` overlay. Callers must assign before reading.
    open var displayedPerson: ABRecord!

    open var displayedProperties: [NSNumber]?

    open unowned(unsafe) var personViewDelegate: (any ABPersonViewControllerDelegate)?

    public override init() {
        super.init()
    }

    open func setHighlightedItemForProperty(
        _ property: ABPropertyID,
        withIdentifier identifier: ABMultiValueIdentifier
    ) {
        highlightedProperty = property
        highlightedIdentifier = identifier
    }

    /// Queries the required delegate. Linux never performs Apple's default
    /// action regardless of the returned value.
    @discardableResult
    open func hostShouldPerformDefaultAction() -> Bool {
        guard let person = displayedPerson else { return false }
        let property = highlightedProperty ?? 0
        let identifier = highlightedIdentifier ?? 0
        return personViewDelegate?.personViewController(
            self,
            shouldPerformDefaultActionForPerson: person,
            property: property,
            identifier: identifier
        ) ?? false
    }
}

@preconcurrency @MainActor
public protocol ABPersonViewControllerDelegate: NSObjectProtocol {
    func personViewController(
        _ personViewController: ABPersonViewController,
        shouldPerformDefaultActionForPerson person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) -> Bool
}
