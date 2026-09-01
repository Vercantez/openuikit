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
  vCard 3.0 subset coding, change-history event types, and `CNError`.
- Process-local **in-memory** contact graph. After `requestAccess(for:)`,
  save/fetch/enumerate/predicates/groups behave deterministically inside this
  process.
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
  service names follow the documented Apple string contract.
- Name and mailing-address formatting are portable joins, not Apple locale
  tables.
- `requestAccess` grants this process-local sandbox only. The completion
  runs off the calling stack (non-reentrant).

## Fail-closed boundaries

- **privacy:** There is no TCC prompt. Status starts `.notDetermined`. Fetch
  and save throw `CNError.authorizationDenied` until `requestAccess`. Granting
  access authorizes only this process-local sandbox; it is not an Apple
  privacy decision.
- **host-store:** No AddressBook, iCloud, CardDAV, or Exchange database is
  attached. The only container is a local in-memory container. Unify is
  identity. Limited/restricted Apple entitlement states are not fabricated as
  successful host grants.
- **in-memory:** Data does not persist across process restart. Thumbnail data
  is the original image bytes (no Apple image pipeline). Unfetched keys do
  not raise `NSException` (unavailable on Linux).

## Still deferred / oracle

See `oracle-questions.tsv` for Darwin probes: TCC prompt timing, completion
queue, unified linked-contact identity, exact extended kinship label
payloads, unattested `CNError` raw values (`parentContainerNotWritable`,
client-identifier, change-history, vCard), locale name/address formatting,
and Apple-identical vCard bytes.
