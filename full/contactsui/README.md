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
(826 nondeferred, floor 85).

Coverage after this repair (per-identifier modifier recording): **136 implemented / 0 declared / 21 deferred / 0 unavailable / 690 not-applicable**
(136 nondeferred, floor 85). 78 walked `View` modifiers now record their
arguments on `ContactAccessButton` and each cites its own
`ContactsUIViewModifierTests.swift#testModifier…` function. 690 remaining
`s:7SwiftUI4ViewPAAE…` rows stay `not-applicable` (`SwiftUI cross-import overlay; owned by the SwiftUI lane`). 21 TipKit/AppIntents members stay deferred.

Top-5 implemented evidence (136 implemented rows; enum members share one
table-driven test; no other test exceeds 40% of the remaining 126 rows):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 10 | 7.4% | `ContactsUICaptionTests.swift#testCaptionCases` (table-driven Caption enum / raw values / Equatable / Hashable) |
| 2 | 1.5% | `ContactsUIAccessButtonTests.swift#testAccessButtonInit` |
| 2 | 1.5% | `ContactsUIAccessButtonTests.swift#testAccessButtonBody` |
| 2 | 1.5% | `ContactsUIStyleTests.swift#testStyleAutomatic` |
| 1 | 0.7% | 120 other focused tests, one identifier each (picker/editor families plus 78 modifier tests) |

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

## Depth pass 2026-09 (wave 8)

SDK DEPTH second pass. Keeps the first-pass picker / editor / access-button
sources and focused tests green, then implements host-driven picker /
editor / access-button families on the Contacts lookalikes.

Coverage before the wave-8 N/A relabel: **58 implemented / 768 declared / 21 deferred / 0 unavailable / 0 not-applicable**
(826 nondeferred, floor 85).

Coverage after the N/A relabel (commit `1a0a1680`): **58 implemented / 78 declared / 21 deferred / 0 unavailable / 690 not-applicable**
(136 nondeferred, floor 85). 690 `s:7SwiftUI4ViewPAAE…` rows are
`not-applicable` with note `SwiftUI cross-import overlay; owned by the SwiftUI lane`.
78 identity modifiers that `linuxExerciseIdentityModifiers()` actually
walks stay `declared` (a no-op is not Apple layout; they compile in
`ContactsUIViewSurface.swift`). 21 TipKit/AppIntents synthesized members
stay deferred. The campaign brief estimated ~150 SwiftUI overlay
re-exports; the pinned graph has 768 `View` PAAE members plus 21
TipKit/AppIntents members.

Coverage before this family-by-family depth continuation (`8a9b09d0`): **58 implemented / 78 declared / 21 deferred / 0 unavailable / 690 not-applicable**.

Coverage after this continuation: **136 implemented / 0 declared / 21 deferred / 0 unavailable / 690 not-applicable**
(136 nondeferred, floor 85). The 78 walked `View` modifiers now record their
arguments on `ContactAccessButton`; each identifier has its own synchronous
`testModifier…` function. 690 remaining SwiftUI.View PAAE members stay
`not-applicable`. 21 TipKit/AppIntents members stay deferred.

Top-5 implemented evidence (enum members share one table-driven
test; no other single test exceeds 40% of the remaining 126 implemented rows):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 10 | 7.4% | `ContactsUICaptionTests.swift#testCaptionCases` (table-driven Caption enum / raw values / Equatable / Hashable) |
| 2 | 1.5% | `ContactsUIAccessButtonTests.swift#testAccessButtonInit` |
| 2 | 1.5% | `ContactsUIAccessButtonTests.swift#testAccessButtonBody` |
| 2 | 1.5% | `ContactsUIStyleTests.swift#testStyleAutomatic` |
| 1 | 0.7% | 120 other focused tests, one identifier each (e.g. `ContactsUIPickerTests.swift#testPickerDidSelectContact`) |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`dd4c8bca7e8735289928bbd1abd44f4b35815308` matched.

Wave-8 host-driven family depth (this continuation):

- **CNContactPickerViewController.** `displayedPropertyKeys` and the three
  predicates are evaluated with a real NSPredicate-subset interpreter over
  `CNContact` snapshot keys (`givenName == %@`, `emailAddresses.@count > 0`,
  `key == %@`, `BEGINSWITH[cd]` / `CONTAINS[cd]` / `ENDSWITH[cd]`, collection
  `CONTAINS` / `==` over phone and email arrays, `AND` / `OR` compounds with
  `AND` binding tighter). Host SPI scripts contact / property / multiple
  selection. Every picker test asserts what the delegate received. A failing
  predicate is fail-closed: no `didSelect`, picker stays visible, no hide
  notification.
- **CNContactViewController.** `forContact` / `forNewContact` /
  `forUnknownContact` modes, `allowsEditing` (empty phone section only while
  editing), `allowsActions` (gates `shouldPerformDefaultAction` without asking
  the delegate), `displayedPropertyKeys` section filter, `contactStore` /
  `shouldShowLinkedContacts` (linked count is always 0). Host SPI
  `reportViewControllerCompletion(_:contact:)` delivers the caller-owned
  contact on Done or `nil` on Cancel; Linux never writes `contactStore`.
- **ContactAccessButton / ContactAccessPickerModel.** Stores `queryString` /
  `ignoredEmails` / `ignoredPhoneNumbers` / approval callback. Host SPI and
  `contactAccessPicker` always deliver `[]`.
- **CNContactPicker\* notifications.** Block observers (no `#selector`).
  Show from `reportPickerDidShow`; hide only after a successful dismiss.

`bash full/contactsui/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_REFERENCE_OK
CONTACTSUI_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ContactsUI dylib=libContactsUI.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

### What is real

- `CNContactPickerViewController` stores `displayedPropertyKeys` and the three
  picker predicates. Documented host SPI scripts appear / cancel / selection:
  `reportPickerDidShow`, `reportPickerCancel`,
  `reportPickerSelection(_:contact:)`, `…contacts:`, `…property:`,
  `…properties:`. A failing enabling or selection predicate is fail-closed
  (no `didSelect`, picker stays visible if it was shown).
- TBD notification names
  `CNContactPickerViewControllerPickerDidShowNotification` and
  `…DidHideNotification` are posted only from that host SPI. Linux never
  presents picker chrome, so it never posts them from `viewDidAppear`.
- Portable predicate formats used by the Contacts corpus / Darwin picker
  docs — `givenName == %@`, `emailAddresses.@count > 0`,
  `key == %@`, `BEGINSWITH[cd]` / `CONTAINS[cd]` / `ENDSWITH[cd]`,
  collection `CONTAINS` / `==` over phone and email arrays, and `AND` / `OR`
  compounds — are compiled to `NSPredicate(block:)` by
  `ContactsUIHostControl.predicate(format:arguments:)`.
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
  methods have Swift default implementations. Host SPI
  `reportViewControllerCompletion(_:contact:)` invokes `didComplete(with:)`
  with the caller-owned contact or `nil` on cancel. `allowsActions == false`
  makes `shouldPerformDefaultAction(for:)` return `false` without asking
  the delegate; the protocol default is also `false`.
- `ContactAccessButton` stores query / ignore sets, caption, and style
  (including `imageColor`). `body` is `EmptyView`. Approval and
  `contactAccessPicker(isPresented:completionHandler:)` always deliver `[]`.
  SPI `ContactAccessPickerModel` is the fail-closed sheet model (no grant
  identifiers).
- `UIApplicationShortcutIcon(contact:)` on the UIKit lookalike stores the
  contact identifier. It does not produce Apple shortcut artwork.
- Linux identity `View` modifiers on `ContactAccessButton` compile as
  argument-recording lookalikes (`ContactsUIViewSurface.swift`). The 78
  walked modifiers are `implemented` with per-identifier tests. Remaining
  synthesized SwiftUI.View PAAE members are **not-applicable** (owned by
  the SwiftUI lane). None of those remaining overlay rows are `implemented`.

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
