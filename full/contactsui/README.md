# ContactsUI (Linux starting point)

`ContactsUI.swift` and the sibling sources in this directory produce
`ContactsUI.swiftmodule` and `libContactsUI.dylib`.

## What is real

- `CNContactPickerViewController` stores `displayedPropertyKeys` and the three
  public predicates. A host calls `presentPicker()`, `reportCancel()`, or
  `reportSelection(...)`. Disabled or non-selectable contacts fail closed with
  `ContactsUIPortableError` and do not fire the delegate.
- `CNContactViewController` keeps the supplied `CNContact`, mode
  (existing / unknown / new), display flags, and highlighted property. Hosts
  call `reportCompletion(contact:)` and `shouldPerformDefaultAction(for:)`.
  `descriptorForRequiredKeys()` returns a portable key-descriptor.
- `CNContactPickerDelegate` and `CNContactViewControllerDelegate` use optional
  default implementations, matching the Objective-C optional methods.
- `ContactAccessButton` records query string, ignore lists, style, caption, and
  a subset of SwiftUI-named modifiers for a host renderer. `body` is
  `ContactAccessUnavailableView`.
- `UIApplicationShortcutIcon(contact:)` stores the contact identifier.
- Bridging `CNContact` / `CNMutableContact` / `CNContactStore` / `CNGroup` /
  `CNContainer` / `CNContactProperty` types exist only when the Contacts module
  cannot be imported. They hold caller-supplied identity and never wrap a
  system address book.

## Fail-closed boundaries

- `ContactsUIPortable.limitedAccessUIAvailable` is `false`. Approval callbacks
  receive host-supplied identifiers only; the default is an empty array.
- `ContactsUIPortable.systemContactStoreAvailable` is `false`. Completing a
  contact view controller does not persist to Apple's store.
- Predicate format strings are unavailable in swift-corelibs-foundation.
  Block predicates are evaluated; missing predicates enable/select.
- SwiftUI `View` extensions (`contactAccessPicker` on `View`, TipKit, and
  App Intents modifiers) are deferred. Generic SwiftUI protocol witnesses on
  `ContactAccessButton` that need SwiftUI types are not applicable on Linux.

## Still deferred / oracle

See `oracle-questions.tsv` for `CNMutableContact.id` vs `identifier`, caption
raw values, picker delegate overload behavior, and unknown-contact editing
defaults.
