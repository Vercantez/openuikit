import Foundation
import AddressBookUI

final class RecordingPersonViewDelegate: NSObject, ABPersonViewControllerDelegate {
    var lastPerson: NSString?
    var lastProperty: ABPropertyID = -1
    var lastIdentifier: ABMultiValueIdentifier = -1
    var allowDefaultAction = false

    func personViewController(
        _ personViewController: ABPersonViewController,
        shouldPerformDefaultActionForPerson person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) -> Bool {
        _ = personViewController
        lastPerson = person as? NSString
        lastProperty = property
        lastIdentifier = identifier
        return allowDefaultAction
    }
}

func testPersonViewControllerAllowsActions() {
    let controller = ABPersonViewController()
    precondition(controller.allowsActions == true)
    controller.allowsActions = false
    precondition(controller.allowsActions == false)
}

func testPersonViewControllerAllowsEditing() {
    let controller = ABPersonViewController()
    precondition(controller.allowsEditing == false)
    controller.allowsEditing = true
    precondition(controller.allowsEditing == true)
}

func testPersonViewControllerShouldShowLinkedPeople() {
    let controller = ABPersonViewController()
    precondition(controller.shouldShowLinkedPeople == false)
    controller.shouldShowLinkedPeople = true
    precondition(controller.shouldShowLinkedPeople == true)
}

func testPersonViewControllerAddressBook() {
    let controller = ABPersonViewController()
    precondition(controller.addressBook == nil)
    let book = "person-book" as NSString
    controller.addressBook = book
    precondition((controller.addressBook as? NSString) === book)
}

func testPersonViewControllerDisplayedPerson() {
    let controller = ABPersonViewController()
    let person = "card-person" as NSString
    controller.displayedPerson = person
    precondition((controller.displayedPerson as? NSString) === person)
}

func testPersonViewControllerDisplayedProperties() {
    let controller = ABPersonViewController()
    precondition(controller.displayedProperties == nil)
    let properties = [NSNumber(value: Int32(0)), NSNumber(value: Int32(1))]
    controller.displayedProperties = properties
    precondition(controller.displayedProperties == properties)
}

func testPersonViewControllerHighlight() {
    let controller = ABPersonViewController()
    precondition(controller.highlightedProperty == nil)
    precondition(controller.highlightedIdentifier == nil)
    controller.setHighlightedItemForProperty(20, withIdentifier: 4)
    precondition(controller.highlightedProperty == 20)
    precondition(controller.highlightedIdentifier == 4)
    controller.setHighlightedItemForProperty(12, withIdentifier: -1)
    precondition(controller.highlightedProperty == 12)
    precondition(controller.highlightedIdentifier == -1)
}

func testPersonViewControllerDelegateDefaultAction() {
    let delegate = RecordingPersonViewDelegate()
    let controller = ABPersonViewController()
    let person = "action-person" as NSString
    controller.displayedPerson = person
    controller.personViewDelegate = delegate
    controller.setHighlightedItemForProperty(12, withIdentifier: 7)
    precondition(controller.hostShouldPerformDefaultAction() == false)
    precondition(delegate.lastPerson === person)
    precondition(delegate.lastProperty == 12)
    precondition(delegate.lastIdentifier == 7)
    delegate.allowDefaultAction = true
    precondition(controller.hostShouldPerformDefaultAction() == true)
    controller.personViewDelegate = nil
}
