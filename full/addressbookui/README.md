# AddressBookUI (Linux starting point)

This directory is a fail-closed portable `AddressBookUI` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph (66 exact IDs). It is not wired into the shared
guest package; that integration is a separate central review step.

Isolated host compilation produces `libAddressBookUI.dylib` with Foundation
only. Darwin's `UIViewController` / `UINavigationController` superclasses are
UIKit-owned; this starting point subclasses `NSObject`. AddressBook's Clang
overlay typealiases (`ABAddressBook` = `CFTypeRef`, `ABRecord` = `CFTypeRef`,
`ABPropertyID` / `ABMultiValueIdentifier` = `Int32`) are used when AddressBook
is not on the link line; they compile out when the real module is imported.
They are not invented record classes.

## Depth pass 2026-09

Implemented **66 / 66** exact public identifiers (`declared` 0, `deferred` 0,
`unavailable` 0, `not-applicable` 0). Nondeferred floor is 53.

Top-5 implemented evidence (of 66 rows; C `ABPerson*Property` constants share one
table-driven value test; 40% cap on the remaining 43 rows is 17):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 23 | 34.8% of all / exempt constant table | `AddressBookUIPropertyTests.swift#testPersonPropertyConstants` |
| 3 | 7.0% of remaining | `AddressBookUINewPersonTests.swift#testNewPersonViewControllerDelegateCompleteNil` |
| 3 | 7.0% of remaining | `AddressBookUIPeoplePickerTests.swift#testPeoplePickerStoresPredicates` |
| 3 | 7.0% of remaining | `AddressBookUIPersonViewTests.swift#testPersonViewControllerDelegateDefaultAction` |
| 3 | 7.0% of remaining | `AddressBookUIUnknownPersonTests.swift#testUnknownPersonViewControllerDelegateResolve` |

No non-constant test exceeds 40% of the remaining implemented rows.

## What is real

- `ABPerson*Property` strings are the documented CNContact-equivalent keys
  (`givenName`, `familyName`, `phoneNumbers`, …). `ABPersonRelatedNamesProperty`
  is `relatedNames`.
- `ABCreateStringWithAddressDictionary` formats AddressBook dictionary keys
  `Street`, `City`, `State`, `ZIP`, `Country`, and `CountryCode` into a
  deterministic US-style string. `addCountryName` appends `Country`, or
  `CountryCode` when `Country` is absent. Extra keys and `NSNull` values are
  ignored. This is not Apple's locale-sensitive layout.
- The four controllers store public configuration: address-book handles,
  displayed person/group, displayed properties, predicates (copied),
  action/editing flags, highlight identifiers, alternate name, and message.
- Documented Darwin defaults that Linux can store without inventing UI:
  `allowsActions = true`, `allowsEditing = false`,
  `shouldShowLinkedPeople = false`, `allowsAddingToAddressBook = false`.
- Host hooks (`hostCancel`, `hostSelectPerson`, `hostComplete`, `hostResolve`,
  `hostShouldPerformDefaultAction`) deliver delegate callbacks on the calling
  context. They never invent a selected or saved person.

## Fail-closed boundaries

Linux has no Contacts daemon, TCC prompt, or Address Book chrome.

- Controllers never present UI and never write `ABRecord` objects.
- Picker predicates are stored, not evaluated against a people list.
- `allowsActions == true` never performs call, mail, or message.
- `allowsAddingToAddressBook == true` never persists a person.
- Completing new-person / unknown-person with `nil` is cancel. A non-nil
  person is a caller-provided handle, not a Linux-created contact.
- Isolated host does not inherit UIKit view-controller classes.

## Tests

`tests/agent/AddressBookUILoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/*Tests.swift` holds the sealed focused tests.
`tests/agent/AddressBookUIDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest AddressBook, Foundation, and UIKit first.

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
missing from this snapshot. The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a
host-inventory token; the sealed framework gate compiles with a clean product
tree.

Run `bash tests/acceptance/test_host.sh` from this directory, or
`bash full/addressbookui/tests/acceptance/test_host.sh` from the repo root.
Keep generated products out of the tree.
