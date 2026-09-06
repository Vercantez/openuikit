import Foundation
import AddressBookUI

final class RecordingNewPersonDelegate: NSObject, ABNewPersonViewControllerDelegate {
    var completedPerson: ABRecord??
    var callCount = 0

    func newPersonViewController(
        _ newPersonView: ABNewPersonViewController,
        didCompleteWithNewPerson person: ABRecord?
    ) {
        _ = newPersonView
        completedPerson = person
        callCount += 1
    }
}

func testNewPersonViewControllerStoresAddressBook() {
    let controller = ABNewPersonViewController()
    precondition(controller.addressBook == nil)
    let book = "address-book" as NSString
    controller.addressBook = book
    precondition((controller.addressBook as? NSString) === book)
    controller.addressBook = nil
    precondition(controller.addressBook == nil)
}

func testNewPersonViewControllerStoresDisplayedPerson() {
    let controller = ABNewPersonViewController()
    precondition(controller.displayedPerson == nil)
    let person = "displayed-person" as NSString
    controller.displayedPerson = person
    precondition((controller.displayedPerson as? NSString) === person)
    controller.displayedPerson = nil
    precondition(controller.displayedPerson == nil)
}

func testNewPersonViewControllerStoresParentGroup() {
    let controller = ABNewPersonViewController()
    precondition(controller.parentGroup == nil)
    let group = "parent-group" as NSString
    controller.parentGroup = group
    precondition((controller.parentGroup as? NSString) === group)
}

func testNewPersonViewControllerDelegateCompleteNil() {
    let delegate = RecordingNewPersonDelegate()
    let controller = ABNewPersonViewController()
    controller.newPersonViewDelegate = delegate
    precondition((controller.newPersonViewDelegate as AnyObject?) === delegate)
    controller.hostComplete(with: nil)
    precondition(delegate.callCount == 1)
    switch delegate.completedPerson {
    case .some(.none):
        break
    default:
        preconditionFailure("expected nil person on cancel")
    }
    controller.newPersonViewDelegate = nil
}

func testNewPersonViewControllerDelegateCompletePerson() {
    let delegate = RecordingNewPersonDelegate()
    let controller = ABNewPersonViewController()
    let person = "new-person" as NSString
    controller.newPersonViewDelegate = delegate
    controller.hostComplete(with: person)
    precondition(delegate.callCount == 1)
    precondition((delegate.completedPerson! as? NSString) === person)
    controller.newPersonViewDelegate = nil
}
