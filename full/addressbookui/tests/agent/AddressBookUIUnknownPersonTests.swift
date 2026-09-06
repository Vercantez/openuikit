import Foundation
import AddressBookUI

final class RecordingUnknownPersonDelegate: NSObject, ABUnknownPersonViewControllerDelegate {
    var resolved: ABRecord??
    var defaultActionCalls = 0
    var allowDefaultAction = false

    func unknownPersonViewController(
        _ unknownCardViewController: ABUnknownPersonViewController,
        didResolveToPerson person: ABRecord?
    ) {
        _ = unknownCardViewController
        resolved = person
    }

    func unknownPersonViewController(
        _ personViewController: ABUnknownPersonViewController,
        shouldPerformDefaultActionForPerson person: ABRecord,
        property: ABPropertyID,
        identifier: ABMultiValueIdentifier
    ) -> Bool {
        _ = personViewController
        _ = person
        _ = property
        _ = identifier
        defaultActionCalls += 1
        return allowDefaultAction
    }
}

final class DefaultUnknownPersonDelegate: NSObject, ABUnknownPersonViewControllerDelegate {
    func unknownPersonViewController(
        _ unknownCardViewController: ABUnknownPersonViewController,
        didResolveToPerson person: ABRecord?
    ) {
        _ = unknownCardViewController
        _ = person
    }
}

func testUnknownPersonViewControllerAllowsActions() {
    let controller = ABUnknownPersonViewController()
    precondition(controller.allowsActions == true)
    controller.allowsActions = false
    precondition(controller.allowsActions == false)
}

func testUnknownPersonViewControllerAllowsAddingToAddressBook() {
    let controller = ABUnknownPersonViewController()
    precondition(controller.allowsAddingToAddressBook == false)
    controller.allowsAddingToAddressBook = true
    precondition(controller.allowsAddingToAddressBook == true)
}

func testUnknownPersonViewControllerAlternateName() {
    let controller = ABUnknownPersonViewController()
    precondition(controller.alternateName == nil)
    controller.alternateName = "Ada Lovelace"
    precondition(controller.alternateName == "Ada Lovelace")
    controller.alternateName = nil
    precondition(controller.alternateName == nil)
}

func testUnknownPersonViewControllerMessage() {
    let controller = ABUnknownPersonViewController()
    precondition(controller.message == nil)
    controller.message = "Shared this contact"
    precondition(controller.message == "Shared this contact")
}

func testUnknownPersonViewControllerAddressBook() {
    let controller = ABUnknownPersonViewController()
    precondition(controller.addressBook == nil)
    let book = "unknown-book" as NSString
    controller.addressBook = book
    precondition((controller.addressBook as? NSString) === book)
}

func testUnknownPersonViewControllerDisplayedPerson() {
    let controller = ABUnknownPersonViewController()
    let person = "unknown-person" as NSString
    controller.displayedPerson = person
    precondition((controller.displayedPerson as? NSString) === person)
}

func testUnknownPersonViewControllerDelegateResolve() {
    let delegate = RecordingUnknownPersonDelegate()
    let controller = ABUnknownPersonViewController()
    controller.unknownPersonViewDelegate = delegate
    controller.hostResolve(to: nil)
    switch delegate.resolved {
    case .some(.none):
        break
    default:
        preconditionFailure("expected nil resolve on cancel")
    }
    let person = "resolved-person" as NSString
    controller.hostResolve(to: person)
    precondition((delegate.resolved! as? NSString) === person)
    controller.unknownPersonViewDelegate = nil
}

func testUnknownPersonViewControllerShouldPerformDefaultAction() {
    let delegate = RecordingUnknownPersonDelegate()
    let controller = ABUnknownPersonViewController()
    let person = "action-unknown" as NSString
    controller.displayedPerson = person
    controller.unknownPersonViewDelegate = delegate
    precondition(controller.hostShouldPerformDefaultAction() == false)
    precondition(delegate.defaultActionCalls == 1)
    delegate.allowDefaultAction = true
    precondition(controller.hostShouldPerformDefaultAction() == true)
    controller.unknownPersonViewDelegate = nil
}

func testUnknownPersonViewControllerOptionalDefaultAction() {
    let delegate = DefaultUnknownPersonDelegate()
    let controller = ABUnknownPersonViewController()
    let person = "default-unknown" as NSString
    controller.displayedPerson = person
    controller.unknownPersonViewDelegate = delegate
    precondition(controller.hostShouldPerformDefaultAction() == false)
    controller.unknownPersonViewDelegate = nil
}
