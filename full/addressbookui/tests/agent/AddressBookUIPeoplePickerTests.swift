import Foundation
import AddressBookUI

final class RecordingPeoplePickerDelegate: NSObject, ABPeoplePickerNavigationControllerDelegate {
    var cancelled = 0
    var selectedPeople: [NSString] = []
    var selectedProperties: [(ABPropertyID, ABMultiValueIdentifier)] = []
    var continuePerson = false
    var continueProperty = false

    func peoplePickerNavigationControllerDidCancel(
        _ peoplePicker: ABPeoplePickerNavigationController
    ) {
        _ = peoplePicker
        cancelled += 1
    }

    func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        didSelectPerson person: ABRecord
    ) {
        _ = peoplePicker
        selectedPeople.append(person as! NSString)
    }

    func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        didSelectPerson person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) {
        _ = peoplePicker
        selectedPeople.append(person as! NSString)
        selectedProperties.append((property, identifier))
    }

    func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        shouldContinueAfterSelectingPerson person: ABRecord
    ) -> Bool {
        _ = peoplePicker
        _ = person
        return continuePerson
    }

    func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        shouldContinueAfterSelectingPerson person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) -> Bool {
        _ = peoplePicker
        _ = person
        _ = property
        _ = identifier
        return continueProperty
    }
}

final class DefaultPeoplePickerDelegate: NSObject, ABPeoplePickerNavigationControllerDelegate {}

func testPeoplePickerStoresAddressBook() {
    let picker = ABPeoplePickerNavigationController()
    precondition(picker.addressBook == nil)
    let book = "picker-book" as NSString
    picker.addressBook = book
    precondition((picker.addressBook as? NSString) === book)
}

func testPeoplePickerDisplayedProperties() {
    let picker = ABPeoplePickerNavigationController()
    precondition(picker.displayedProperties == nil)
    let properties = [
        NSNumber(value: Int32(12)),
        NSNumber(value: Int32(20)),
    ]
    picker.displayedProperties = properties
    precondition(picker.displayedProperties == properties)
    picker.displayedProperties = []
    precondition(picker.displayedProperties?.isEmpty == true)
}

func testPeoplePickerStoresPredicates() {
    let picker = ABPeoplePickerNavigationController()
    precondition(picker.predicateForEnablingPerson == nil)
    precondition(picker.predicateForSelectionOfPerson == nil)
    precondition(picker.predicateForSelectionOfProperty == nil)

    let enabling = NSPredicate(value: true)
    let selectPerson = NSPredicate { _, _ in true }
    let selectProperty = NSPredicate(value: false)
    picker.predicateForEnablingPerson = enabling
    picker.predicateForSelectionOfPerson = selectPerson
    picker.predicateForSelectionOfProperty = selectProperty
    precondition(picker.predicateForEnablingPerson?.evaluate(with: nil) == true)
    precondition(picker.predicateForSelectionOfPerson?.evaluate(with: nil) == true)
    precondition(picker.predicateForSelectionOfProperty?.evaluate(with: nil) == false)

    picker.predicateForEnablingPerson = nil
    precondition(picker.predicateForEnablingPerson == nil)
}

func testPeoplePickerDelegateCancel() {
    let delegate = RecordingPeoplePickerDelegate()
    let picker = ABPeoplePickerNavigationController()
    picker.peoplePickerDelegate = delegate
    picker.hostCancel()
    precondition(delegate.cancelled == 1)
    precondition(delegate.selectedPeople.isEmpty)
    picker.peoplePickerDelegate = nil
}

func testPeoplePickerDidSelectPerson() {
    let delegate = RecordingPeoplePickerDelegate()
    let picker = ABPeoplePickerNavigationController()
    let person = "selected-person" as NSString
    picker.peoplePickerDelegate = delegate
    picker.hostSelectPerson(person)
    precondition(delegate.selectedPeople == [person])
    picker.peoplePickerDelegate = nil
}

func testPeoplePickerDidSelectPersonProperty() {
    let delegate = RecordingPeoplePickerDelegate()
    let picker = ABPeoplePickerNavigationController()
    let person = "property-person" as NSString
    picker.peoplePickerDelegate = delegate
    picker.hostSelectPerson(person, property: 12, identifier: 3)
    precondition(delegate.selectedPeople == [person])
    precondition(delegate.selectedProperties.count == 1)
    precondition(delegate.selectedProperties[0].0 == 12)
    precondition(delegate.selectedProperties[0].1 == 3)
    picker.peoplePickerDelegate = nil
}

func testPeoplePickerShouldContinuePerson() {
    let delegate = RecordingPeoplePickerDelegate()
    let picker = ABPeoplePickerNavigationController()
    let person = "continue-person" as NSString
    picker.peoplePickerDelegate = delegate
    precondition(picker.hostShouldContinue(afterSelecting: person) == false)
    delegate.continuePerson = true
    precondition(picker.hostShouldContinue(afterSelecting: person) == true)
    picker.peoplePickerDelegate = nil
}

func testPeoplePickerShouldContinueProperty() {
    let delegate = RecordingPeoplePickerDelegate()
    let picker = ABPeoplePickerNavigationController()
    let person = "continue-property" as NSString
    picker.peoplePickerDelegate = delegate
    precondition(
        picker.hostShouldContinue(afterSelecting: person, property: 20, identifier: 1) == false
    )
    delegate.continueProperty = true
    precondition(
        picker.hostShouldContinue(afterSelecting: person, property: 20, identifier: 1) == true
    )
    picker.peoplePickerDelegate = nil
}

func testPeoplePickerOptionalDelegateDefaults() {
    let delegate = DefaultPeoplePickerDelegate()
    let picker = ABPeoplePickerNavigationController()
    let person = "default-person" as NSString
    picker.peoplePickerDelegate = delegate
    picker.hostCancel()
    picker.hostSelectPerson(person)
    precondition(picker.hostShouldContinue(afterSelecting: person) == false)
    precondition(
        picker.hostShouldContinue(afterSelecting: person, property: 12, identifier: 0) == false
    )
    picker.peoplePickerDelegate = nil
}
