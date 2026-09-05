# Contacts (Linux starting point)

This directory is a clean-room Linux port of Apple's public `Contacts`
module, seeded from the iPhoneOS 26.1 SDK graphs. It produces module
`Contacts` and `libContacts.dylib`.

The isolated host gate (`bash tests/acceptance/test_host.sh`) compiles
against the **toolchain** Foundation. It is not an integrated Linux/EC2
guest-Foundation result. A future EC2 run must build guest Foundation
first, build this module with those `-I/-L` paths, and execute
`tests/agent/ContactsDependencyIdentity.swift`.

## What is real

- Public types used by the 20-app corpus: `CNContact` / `CNMutableContact`,
  `CNContactStore`, `CNSaveRequest`, `CNContactFetchRequest`, labeled values,
  phone/postal/social/IM/relation values, groups, containers, formatters,
  vCard 3.0 (RFC 2426) coding, change-history event types, and `CNError`.
- Documented **local directory** store at
  `$HOME/.local/share/openuikit/contacts/` (override with
  `OPENUIKIT_CONTACTS_DIRECTORY`). The file is `store.json`. This is not a
  system address book.
- After `requestAccess(for:)`, save/fetch/enumerate/predicates/groups behave
  deterministically against that directory. Status starts `.notDetermined`
  and becomes `.authorized` or `.denied` (documented
  `_setPortableAuthorizationDecision` test hook).
- `CNSaveRequest.execute` is transactional: every operation is validated
  against a snapshot, then all mutations and history events are installed
  together or the complete prior state is restored.
- The store lock is released before `CNContactStoreDidChange` is posted and
  before any `requestAccess` completion. Custom `NSPredicate.evaluate`
  closures run only after candidates are copied out from under the lock.
- Store predicates are a tagged `NSPredicate` subclass (`kind` on the
  object). There is no global `ObjectIdentifier` table.
- `CNKeyDescriptor` is `NSObjectProtocol & NSCopying & NSSecureCoding`.
  Linux `String` cannot satisfy those class bounds, so `NSString` conforms
  and callers pass `CNContactGivenNameKey as NSString`.
- Property keys, standard labels (`_$!<Home>!$_`, `iPhone`, …), and IM/social
  service names follow the documented Apple string contract. Phone/email
  labels use the exact public payloads (`iPhone`, `_$!<Mobile>!$_`, `iCloud`).
- Name formatting joins prefix/given/middle/family/suffix (family-name-first
  reverses given/family), then nickname, then organization.
- Mailing-address formatting uses `isoCountryCode` layouts the host Locale
  can express (US `city, ST ZIP`, GB street/city/postcode, JP country-first).
- `requestAccess` grants this local-directory sandbox only. The completion
  runs off the calling stack (non-reentrant).

## Fail-closed boundaries

- **privacy:** There is no TCC prompt. Status starts `.notDetermined`. Fetch
  and save throw `CNError.authorizationDenied` until `requestAccess`. Granting
  access authorizes only this process's documented directory; it is not an
  Apple privacy decision. The test hook can force `.denied`.
- **host-store:** No AddressBook, iCloud, CardDAV, or Exchange database is
  attached. The only writable container is the local directory container.
  Unknown container identifiers throw `parentContainerNotWritable`. Unify is
  identity. `CNContactPickerViewController` throws `featureNotAvailable`
  (ContactsUI/UIKit is not present).
- **in-memory:** Thumbnail data equals `imageData` bytes (no Apple image
  pipeline). Unfetched keys report `isKeyAvailable == false` and throw
  `CNError.unauthorizedKeys` from `requireKeyAvailable` (Linux has no
  recoverable `NSException`). Property getters also record that error.

## Depth pass 2026-09

Wave-1 left 532 implemented / 12 declared / 169 deferred. The first depth
commit (`fd739cdd`) reached 712 implemented / 1 declared / 0 deferred /
1 not-applicable, but merge refused it: every implemented evidence cell
was a source/runtime path (`full/contacts/…swift;full/contacts/tests/agent/ContactsRuntime.swift`)
instead of `test:full/contacts/tests/agent/<File>Tests.swift#testName`.

This ledger repair keeps the same honest statuses and cites real focused
tests:

- After: implemented **712** / declared **1** / deferred **0** / not-applicable **1**
  (`CNContact.id` Identifiable overlay is UUID, not ObjectIdentifier;
  generic `CNLabeledValue` `init(coder:)` is `declared` —
  `source:full/contacts/CNTypes.swift#CNLabeledValue` — because Linux
  `NSKeyedArchiver` cannot archive that generic class).
- Top-5 implemented evidence distribution (712 rows):
  1. `ContactsConstantsTests.swift#testPublicStringConstants` — 308 (table-driven C string constants)
  2. `ContactsEnumTests.swift#testEnumRawValues` — 97 (enum cases plus synthesized `!=` / hash / `rawValue`)
  3. `ContactsHistoryTests.swift#testChangeHistoryEventsAndVisitor` — 42
  4. `ContactsContactTests.swift#testContactPropertiesAndKeys` — 34
  5. `ContactsContactTests.swift#testMutableContactSetters` — 28
- No non-constant/non-enum test exceeds 40% of the remaining 307 implemented rows
  (largest remaining citation is history visitor at 13.7%).
- Local directory store with `store.json`, reload SPI, and transactional
  `execute`.
- Authorization `.notDetermined` → `.authorized` / `.denied`.
- `enumerateContacts` honors predicate, `sortOrder`, `unifyResults`
  (identity), and `mutableObjects`.
- `CNError.recordDoesNotExist`, `validationMultipleErrors` (with
  `CNErrorUserInfoValidationErrorsKey` / affected ids / keyPaths), and
  `unauthorizedKeys` on unfetched key access.
- vCard 3.0 round trip: N/FN/TEL;TYPE=/EMAIL;TYPE=/ADR;TYPE=/ORG/BDAY/PHOTO/NOTE/URL.
- Gate: `bash full/contacts/tests/acceptance/test_host.sh` (Linux host, no docker).
  Schema-v1 compiles `ContactsRuntime.swift` only; that file concatenates the
  same `test*` functions the coverage ledger cites.

Still not claimed: Apple TCC UI, iCloud/CardDAV unify identity, Apple
locale name tables, Apple-identical vCard bytes, Darwin raw values for
newer `CNError` cases, ImageIO thumbnail downsampling.

See `oracle-questions.tsv`.
