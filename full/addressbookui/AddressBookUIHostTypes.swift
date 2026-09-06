import CoreFoundation
import Foundation

#if canImport(AddressBook)
@_exported import AddressBook
#endif

// Isolated host: AddressBook's Clang overlay typealiases so public AddressBookUI
// signatures type-check. These are CFTypeRef / Int32, the same overlay
// `full/addressbook` publishes, not invented record classes. When AddressBook is
// on the link line, this block compiles out.

#if !canImport(AddressBook)
public typealias ABAddressBook = CFTypeRef
public typealias ABRecord = CFTypeRef
public typealias ABMultiValueIdentifier = Int32
public typealias ABPropertyID = Int32
#endif
