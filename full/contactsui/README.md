# ContactsUI

Linux starting point for Apple's public `ContactsUI` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. The platform branch
`cursor/port-contactsui-to-linux-c564` (legacy PR #15) was not fetchable with
this run's GitHub token, so this is a content reconstruction, not a byte copy
of that branch. Isolated host-gate success is not integrated Linux success.

## Reference dossier

Kept the monorepo `full/contactsui/reference/` (generator
`scripts/framework-fanout/generate_seed.py`, SHA256
`2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`,
iPhoneOS 26.1 / Xcode 17B55). The platform branch `reference/` could not be
compared (`unavailable`).

## What is real

`libContactsUI.dylib` compiles from Foundation only.

- `ContactAccessButton` stores `queryString`, ignored email/phone sets, and an
  optional approval callback. The callback is not invoked until host SPI
  delivers the fail-closed empty identifier list.
- `ContactAccessButton.Caption` (`defaultText`, `email`, `phone`) with
  synthesized `Hashable` / `Equatable`. Linux `String` raw values equal the
  case names; Apple bytes are unobserved (`declared`).
- `ContactAccessButton.Style.automatic` and CGFloat padding/width. The Darwin
  initializer's `Color?` parameter is gated on SwiftUI.
- `CNContactPickerViewController` and `CNContactViewController` as `NSObject`
  hosts (not `UIViewController` lookalikes). Display flags, predicates,
  `displayedPropertyKeys`, and `highlightProperty(withKey:identifier:)`
  round-trip. No address book is presented.
- `contactPickerDidCancel` dispatches through `any CNContactPickerDelegate`.
- Linux fluent no-ops on `ContactAccessButton` for a Foundation-typed subset
  of Darwin `View` modifiers (`hidden()`, `padding(_:)`, …). They return
  `ContactAccessButton`, record a host tag, and are `declared`, not Apple
  `SwiftUI.View` identity.

## Fail-closed boundaries

Linux has no Contacts authorization, picker UI, or limited-access grant sheet.

- Host SPI `reportPickerCancel` never fabricates a `CNContact` selection.
- Host SPI `reportViewControllerCompletion` records completion without a saved
  contact. The Darwin `didCompleteWith` callback is compiled only when Contacts
  is imported, and then it is invoked with `nil`.
- `invokeAccessApproval` always delivers `[]`.
- `CNContact`-typed controller inits, `CNMutableContact.id`, and
  `UIApplicationShortcutIcon.init(contact:)` are absent until those modules
  exist. No module-local `CNContact` / `UIViewController` / `SwiftUI.Color`
  stand-ins.
- `ContactAccessButton` is a SwiftUI `View` only inside `#if canImport(SwiftUI)`.

## Still open

See `oracle-questions.tsv` for Caption raw bytes, Style color defaults,
descriptor identity, picker cancel queue, and approval-callback timing.

`tests/agent/ContactsUIRuntime.swift` is the isolated host probe
(`CONTACTSUI_AGENT_RUNTIME_OK`).
`tests/agent/ContactsUIDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Contacts, Foundation, UIKit, and SwiftUI
first and prints `CONTACTSUI_DEPENDENCY_IDENTITY_OK` only after assertions
pass.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
