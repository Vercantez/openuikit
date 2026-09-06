# AddressBook (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`AddressBook` C overlay, seeded from the Xcode 26.1 iPhoneOS symbol graph.
It produces one nominal Swift module, `AddressBook`, and a loadable
`libAddressBook.dylib`. It is a **legacy-adapter** for a deprecated contacts
API. It is not an Apple behavioral oracle and it is not wired into the shared
guest package.

## What is real

- Overlay types: `ABAddressBook` / `ABRecord` / `ABMultiValue` as `CFTypeRef`
  aliases, `ABAuthorizationStatus`, `ABPersonImageFormat`, property/record
  integer aliases, and completion/callback aliases.
- Documented integer ABI: property types (`kABStringPropertyType` … multi-mask
  256), record types, sort/composite-name formats, source types including
  `kABSourceTypeSearchableMask`, error codes 0/1, invalid IDs `-1`, and image
  formats 0/2.
- Label and dictionary payloads using the documented `_$!<Label>!$_` form,
  `iPhone`, and Contacts-successor service tokens (`AIM`, `Twitter`, …).
- In-process records: create person/group/source, `ABRecordSetValue` /
  `CopyValue` / `RemoveValue`, composite names (person vs organization vs
  group), localized English property names, and `ABPersonGetTypeOfProperty`.
- Mutable multi-values: add/insert/replace/remove, identifiers, first-index,
  copy-on-write `CreateMutableCopy`.
- Isolated in-memory address book: add/remove/save/revert, unsaved-change
  tracking, counts, lookup by record ID, default local source, name search,
  and sort-by-first/last.
- Groups with membership and sorted member arrays.
- vCard 3.0 subset round-trip (`N`/`FN`/`TEL`/`EMAIL`/`ADR`/`BDAY`/`NOTE`/`URL`/
  `ORG`/`TITLE`/`NICKNAME`/`PHOTO`).
- Image data store/copy/remove. Both image formats return the stored bytes.

## Fail-closed / not invented

- `ABAddressBookGetAuthorizationStatus()` is always `.denied`. Linux has no
  Contacts daemon and does not invent a privacy grant.
- `ABAddressBookRequestAccessWithCompletion` invokes the handler **inline**
  with `granted=false` and `kABOperationNotPermittedByUserError`. It never
  becomes `.authorized`.
- External change callbacks can be registered and unregistered but are never
  fired.
- Create still returns an isolated empty book so record APIs are usable; it
  does not read a host address book (evolution-data-server, GNOME Contacts,
  or Apple's store).
- Thumbnails are not resampled. Localized labels strip `_$!<…>!$_` and do not
  invent Apple locale tables.
- Person property IDs are Linux-stable sequential values in public header
  order; Apple dylib integers are unobserved.

## Still deferred

No public-surface identifier is deferred: all 225 exact IDs are `implemented`
or `declared` (typealiases). Remaining Apple questions live in
`oracle-questions.tsv`.

Run the immutable host gate:

```sh
bash tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Campaign `ios26.1-fwseed-r9`, lane `legacy-adapter`, framework `AddressBook`
(225 IDs). Starting commit `a15391648a4fd5a92038c7465b26208c67eb87ed`.
Branch `cursor/port-addressbook-to-linux-d448`.

Coverage honesty repair (merge refused `b805b6bba3da` for
`CFNumber?` → `NSNumber` coercion in `AddressBookConstantTests`, and for
lumped runtime evidence rather than per-family `*Tests.swift#testName`):

| | implemented | declared | deferred |
|---|---:|---:|---:|
| Seed | 0 | 0 | n/a (no coverage yet) |
| Before evidence repair (`b805b6bba3da`) | 211 | 14 | 0 |
| After focused `*Tests.swift#testName` ledger | **211** | **14** | **0** |

Nondeferred 225. Every `implemented` row cites
`test:full/addressbook/tests/agent/<File>Tests.swift#testName` for a real
top-level synchronous `func testName()` that exercises that identifier.
Typealiases stay `declared` with `source:full/addressbook/AddressBook.swift#Symbol`.
`kABPersonKindPerson` / `kABPersonKindOrganization` are read with
`unsafeBitCast(..., to: NSNumber.self)` (Linux CFNumber is not `NSNumber`).
`ABAddressBookErrorDomain` is cited by `testAuthorizationFailClosed`, not the
shared constant catalog.

Top-5 implemented evidence distribution (211 rows):

1. `AddressBookConstantTests.swift#testConstantCatalog` — 129 (61.1%) — table-driven enums, option-set members, C `kAB*`/`err*` constants (allowed shared value test)
2. `AddressBookStoreTests.swift#testAddressBookCopyArrays` — 6 (2.8%)
3. `AddressBookRecordTests.swift#testMultiValueMutate` — 6 (2.8%)
4. `AddressBookRecordTests.swift#testMultiValueCreateAndRead` — 6 (2.8%)
5. `AddressBookConstantTests.swift#testPersonImageFormatHashableAndEquatable` — 6 (2.8%)

No non-enum test exceeds 40% of the remaining implemented rows (82 after the
catalog; largest is 6 rows / 7.3%).

Public surface implemented for real on Linux:

- In-memory address book, records, groups, sources, multi-values, composite
  names, comparison/sort, vCard 3.0 subset, image bytes.
- Fail-closed authorization and never-fired external callbacks as documented
  above.

Unresolved behavioral questions: see `oracle-questions.tsv`.

Environment note: `.cursor/verify-cloud-environment.sh` did not print
`CURSOR_SWIFT_ENVIRONMENT_OK` in this VM because `scratch/ladder-corpus/focus-ios`
is missing. `swiftc` is Swift 6.2.4 / `x86_64-unknown-linux-gnu`. The sealed
gate ran directly on this Linux host. Host gate output:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AddressBook lane=legacy-adapter symbols=225
FRAMEWORK_FANOUT_REFERENCE_OK
ADDRESSBOOK_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AddressBook dylib=libAddressBook.dylib
```

