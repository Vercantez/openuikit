# ContactsUI (Linux starting point)

`ContactsUI.swift` and the sibling sources produce `ContactsUI.swiftmodule`
and `libContactsUI.dylib`.

The isolated host gate compiles this module with Foundation only. Declarations
that require Contacts, UIKit, or SwiftUI are `#if canImport` gated so this
module never introduces lookalike `CNContact`, `UIViewController`,
`UIApplicationShortcutIcon`, or `SwiftUI.Color` types.

## What is real when dependencies are linked

- `CNContactPickerViewController` and `CNContactViewController` subclass
  `UIKit.UIViewController` and take `Contacts.CNContact` values.
- `descriptorForRequiredKeys()` returns `CNContact.descriptorForAllComparatorKeys()`,
  a real Contacts `CNKeyDescriptor`, not a ContactsUI helper type.
- `ContactAccessButton` is a `SwiftUI.View` only on the SwiftUI route. `body`
  is `EmptyView`. Style uses `SwiftUI.Color`.
- `UIApplicationShortcutIcon(contact:)` is an overlay on UIKit's type.
- Host presentation (`reportSelection`, `reportCompletion`, `presentPicker`,
  `reportApproval`) is `@_spi(OpenUIKitHost)`.

## Fail-closed

- `ContactsUIPortable.limitedAccessUIAvailable` is `false`. Approval never
  invents Apple Limited Access identifiers.
- `ContactsUIPortable.systemContactStoreAvailable` is `false`. Completion does
  not persist to an Apple address book.
- SwiftUI `contactAccessPicker` does not present Apple privacy UI.

The isolated Foundation gate does **not** prove integrated Contacts/UIKit/SwiftUI
success. `tests/agent/ContactsUIDependencyIdentity.swift` is the future EC2
client: it imports real Contacts, UIKit, and SwiftUI, passes `CNMutableContact`
through public APIs, checks both controllers are `UIViewController` subclasses,
and loads `libContactsUI.dylib`.

## Oracle

See `oracle-questions.tsv`.
