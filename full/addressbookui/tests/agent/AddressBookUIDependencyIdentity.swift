import Foundation
import AddressBookUI

#if canImport(AddressBook)
import AddressBook
#endif
#if canImport(UIKit)
import UIKit
#endif

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest AddressBook/UIKit
// success.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest AddressBook, Foundation, and UIKit (and their dylibs).
// 2. Build AddressBookUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports AddressBookUI and every dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `ADDRESSBOOKUI_DEPENDENCY_IDENTITY_OK`.

func addressBookUIDependencyIdentityProbe() {
    let predicate = NSPredicate(value: true)
    precondition(type(of: predicate) == NSPredicate.self)
    precondition(!String(reflecting: type(of: predicate)).hasPrefix("AddressBookUI."))

    let picker = ABPeoplePickerNavigationController()
    picker.predicateForEnablingPerson = predicate
    precondition(picker.predicateForEnablingPerson?.evaluate(with: nil) == true)

    let numbers = [NSNumber(value: Int32(12))]
    picker.displayedProperties = numbers
    precondition(picker.displayedProperties == numbers)

    let formatted = ABCreateStringWithAddressDictionary(
        ["Street": "1 Identity Way", "City": "Cupertino"],
        false
    )
    precondition(formatted.contains("1 Identity Way"))
    precondition(ABPersonGivenNameProperty == "givenName")

    print("ADDRESSBOOKUI_DEPENDENCY_IDENTITY_OK")
}

addressBookUIDependencyIdentityProbe()
