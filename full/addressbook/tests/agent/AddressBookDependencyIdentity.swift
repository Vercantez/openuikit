import AddressBook
import CoreFoundation
import Foundation

/// Identity probe for a later clean EC2 integration build against real
/// CoreFoundation. Isolated `tests/acceptance/test_host.sh` does not compile
/// this file.
func addressBookDependencyIdentityProbe() {
    let domain: CFString = ABAddressBookErrorDomain
    _ = CFStringGetLength(domain)
    let book = ABAddressBookCreate().takeRetainedValue()
    let person = ABPersonCreate().takeRetainedValue()
    _ = ABRecordSetValue(person, kABPersonFirstNameProperty, "Ada" as CFString, nil)
    _ = ABAddressBookAddRecord(book, person, nil)
    _ = ABAddressBookGetPersonCount(book)
    let status = ABAddressBookGetAuthorizationStatus()
    _ = status.rawValue
}

#if ADDRESSBOOK_IDENTITY_MAIN
addressBookDependencyIdentityProbe()
print("ADDRESSBOOK_DEPENDENCY_IDENTITY_OK")
#endif
