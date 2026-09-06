import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// People picker. Darwin subclasses `UINavigationController` and presents
/// the system contact list. Linux stores configuration, including
/// predicates, and delivers delegate callbacks through host hooks. It never
/// lists or invents address-book people.
@preconcurrency @MainActor
#if canImport(UIKit)
open class ABPeoplePickerNavigationController: UINavigationController {
#else
open class ABPeoplePickerNavigationController: NSObject {
#endif
    public override init() {
        super.init()
    }

    open var addressBook: ABAddressBook?

    open var displayedProperties: [NSNumber]?

    open unowned(unsafe) var peoplePickerDelegate: (any ABPeoplePickerNavigationControllerDelegate)?

    open var predicateForEnablingPerson: NSPredicate? {
        get { _predicateForEnablingPerson }
        set { _predicateForEnablingPerson = abuiCopyPredicate(newValue) }
    }

    open var predicateForSelectionOfPerson: NSPredicate? {
        get { _predicateForSelectionOfPerson }
        set { _predicateForSelectionOfPerson = abuiCopyPredicate(newValue) }
    }

    open var predicateForSelectionOfProperty: NSPredicate? {
        get { _predicateForSelectionOfProperty }
        set { _predicateForSelectionOfProperty = abuiCopyPredicate(newValue) }
    }

    private var _predicateForEnablingPerson: NSPredicate?
    private var _predicateForSelectionOfPerson: NSPredicate?
    private var _predicateForSelectionOfProperty: NSPredicate?

    /// Darwin Cancel. Never selects a person.
    open func hostCancel() {
        peoplePickerDelegate?.peoplePickerNavigationControllerDidCancel(self)
    }

    /// Delivers `didSelectPerson`. The record is the caller's handle, not
    /// a Linux-invented contact.
    open func hostSelectPerson(_ person: ABRecord) {
        peoplePickerDelegate?.peoplePickerNavigationController(self, didSelectPerson: person)
    }

    open func hostSelectPerson(
        _ person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) {
        peoplePickerDelegate?.peoplePickerNavigationController(
            self,
            didSelectPerson: person,
            property: property,
            identifier: identifier
        )
    }

    /// Queries the deprecated should-continue API. Default is `false`
    /// (fail-closed: do not push a property list).
    @discardableResult
    open func hostShouldContinue(afterSelecting person: ABRecord) -> Bool {
        peoplePickerDelegate?.peoplePickerNavigationController(
            self,
            shouldContinueAfterSelectingPerson: person
        ) ?? false
    }

    @discardableResult
    open func hostShouldContinue(
        afterSelecting person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) -> Bool {
        peoplePickerDelegate?.peoplePickerNavigationController(
            self,
            shouldContinueAfterSelectingPerson: person,
            property: property,
            identifier: identifier
        ) ?? false
    }
}

@preconcurrency @MainActor
public protocol ABPeoplePickerNavigationControllerDelegate: NSObjectProtocol {
    func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        didSelectPerson person: ABRecord
    )

    func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        didSelectPerson person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    )

    func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        shouldContinueAfterSelectingPerson person: ABRecord
    ) -> Bool

    func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        shouldContinueAfterSelectingPerson person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) -> Bool

    func peoplePickerNavigationControllerDidCancel(
        _ peoplePicker: ABPeoplePickerNavigationController
    )
}

extension ABPeoplePickerNavigationControllerDelegate {
    public func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        didSelectPerson person: ABRecord
    ) {
        _ = peoplePicker
        _ = person
    }

    public func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        didSelectPerson person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) {
        _ = peoplePicker
        _ = person
        _ = property
        _ = identifier
    }

    public func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        shouldContinueAfterSelectingPerson person: ABRecord
    ) -> Bool {
        _ = peoplePicker
        _ = person
        return false
    }

    public func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        shouldContinueAfterSelectingPerson person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) -> Bool {
        _ = peoplePicker
        _ = person
        _ = property
        _ = identifier
        return false
    }

    public func peoplePickerNavigationControllerDidCancel(
        _ peoplePicker: ABPeoplePickerNavigationController
    ) {
        _ = peoplePicker
    }
}
