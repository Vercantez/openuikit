# ContactsUI

Linux starting point for Apple's public `ContactsUI` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success
is not integrated Linux success.

## Depth pass 2026-09

SDK depth for `ContactsUI` in `full/contactsui/` (847 IDs). Wave-1 started at
29 implemented / 77 declared / 741 deferred. This pass targets picker and
view-controller families nondeferred and a useful Linux starting point that
paints a grouped contact table from the port's Contacts-shaped API.

The first depth commit marked **592 implemented / 234 declared / 21 deferred**,
but every implemented row cited product files plus `ContactsUIRuntime.swift`
instead of `test:full/contactsui/tests/agent/<File>Tests.swift#testName`.
Identity `View` modifiers were also bulk-labeled implemented from a no-op
walk. This repair keeps picker / editor / access-button / overlay behavior
as `implemented` only where a focused test exercises that identifier, and
reclassifies the rest to `declared`.

Coverage after the ledger repair: **58 implemented / 768 declared / 21 deferred / 847 total**
(826 nondeferred, floor 85). 21 TipKit/AppIntents synthesized members stay
deferred. No non-enum test is cited by more than 2 implemented rows (3.4%).

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 10 | 17.2% | `ContactsUICaptionTests.swift#testCaptionCases` (table-driven Caption enum / raw values / Equatable / Hashable) |
| 2 | 3.4% | `ContactsUIAccessButtonTests.swift#testAccessButtonInit` |
| 2 | 3.4% | `ContactsUIAccessButtonTests.swift#testAccessButtonBody` |
| 2 | 3.4% | `ContactsUIStyleTests.swift#testStyleAutomatic` |
| 1 | 1.7% | 42 other focused tests, one identifier each (e.g. `ContactsUIOverlayTests.swift#testMutableContactId`) |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`5cc42895aa4277d0ed2103050b64be03fe813c3e` matched.

`origin/agent/fw-contactsui` did not exist; this pass publishes that branch
from the Cursor-created work branch.

### What is real

- `CNContactPickerViewController` stores `displayedPropertyKeys` and the three
  picker predicates. Documented host SPI scripts cancel and selection:
  `reportPickerSelection(_:contact:)`, `…contacts:`, `…property:`,
  `…properties:`. A failing enabling or selection predicate is fail-closed
  (no `didSelect`).
- Portable predicate formats used by the Contacts corpus / Darwin picker
  docs — `givenName == %@`, `emailAddresses.@count > 0`,
  `key == %@`, `BEGINSWITH[cd]` / `CONTAINS[cd]` — are compiled to
  `NSPredicate(block:)` by `ContactsUIHostControl.predicate(format:argument:)`.
  swift-corelibs-foundation does not parse `NSPredicate(format:)`.
- `CNContactViewController` inits `init(for:)`, `init(forContact:)`,
  `init(forNewContact:)`, `init(forUnknownContact:)` plus
  `contactStore`, `parentGroup`, `parentContainer`,
  `allowsEditing` / `allowsActions` / `shouldShowLinkedContacts`,
  `displayedPropertyKeys`, `message`, `alternateName`,
  `highlightProperty(withKey:identifier:)`, and
  `descriptorForRequiredKeys()`.
- Grouped-table **section model**: name header, optional message row, phone /
  email / address rows with localized labels. Host SPI
  `linuxContactSections` is the observation path.
- `CNContactPickerDelegate` / `CNContactViewControllerDelegate` optional
  methods have Swift default implementations. `didComplete(with:)` is
  invoked with `nil` on fail-closed completion.
  `shouldPerformDefaultAction(for:)` defaults to `false`.
- `ContactAccessButton` stores query / ignore sets, caption, and style
  (including `imageColor`). `body` is `EmptyView`. Approval and
  `contactAccessPicker(isPresented:completionHandler:)` always deliver `[]`.
- `UIApplicationShortcutIcon(contact:)` on the UIKit lookalike stores the
  contact identifier. It does not produce Apple shortcut artwork.
- Linux identity `View` modifiers on `ContactAccessButton` compile as `Self`
  no-ops (`ContactsUIViewSurface.swift`). They are **declared**, not
  implemented: a no-op is not Apple layout and is not a focused behavioral
  test.

### Fail-closed boundaries

- No Contacts TCC, address book, picker chrome, or limited-access grant sheet.
- Host SPI never fabricates a selection the caller did not pass in.
- `CNContactViewController` does not save through `contactStore`.
- `ContactAccessButton.approvalCallback` is not auto-invoked.
- Isolated-host Contacts / UIKit / SwiftUI types in
  `ContactsUILookalikes.swift` compile out when those modules are imported.
  They are not a Linux Contacts port.

### Contacts port runtime gaps

`full/contacts` is being deepened in parallel. This module programs against
that declared API (`CNContact` name/phone/email/postal properties,
`CNContactProperty`, `CNContactStore`, `CNGroup`, `CNContainer`,
`CNKeyDescriptor`, `CNLabeledValue`). Isolated-host gaps versus that port:

- No `requestAccess`, in-memory save/fetch graph, or `CNStorePredicate`.
- No vCard, unify, or `CNContactStoreDidChange`.
- Picker predicates use the portable format interpreter, not Contacts store
  predicates and not Darwin KVC `NSPredicate(format:)`.

### Drawing / oracle gap

`uikit/scripts/conformance_flow.sh` is present in this worktree. This pass
did **not** measure iOS 26.1 `CNContactViewController` chrome on the SE 2x:
there is no ContactsUI conformance app, and this Linux host cannot run the
simulator capture side (`SKIP_CAPTURE=1` still needs goldens). The grouped
section model is the portable substitute; pixel chrome is listed as a gap.

### Tests

Focused checks live in `tests/agent/*Tests.swift` as top-level `func test*()`.
The schema-v1 host gate compiles only `tests/agent/ContactsUIRuntime.swift`,
which inlines those same functions and prints `CONTACTSUI_AGENT_RUNTIME_OK`.

```
FRAMEWORK_FANOUT_REFERENCE_OK
CONTACTSUI_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ContactsUI dylib=libContactsUI.dylib
```

Run `bash tests/acceptance/test_host.sh` from this directory (or
`bash full/contactsui/tests/acceptance/test_host.sh` from the repo root).
Keep generated products out of the tree.
