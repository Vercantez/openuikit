# Contacts (Linux starting point)

This directory is a clean-room Linux port of Apple's public `Contacts`
module, seeded from the iPhoneOS 26.1 SDK graphs. It produces module
`Contacts` and `libContacts.dylib`.

## What is real

- Public types used by the 20-app corpus: `CNContact` / `CNMutableContact`,
  `CNContactStore`, `CNSaveRequest`, `CNContactFetchRequest`, labeled values,
  phone/postal/social/IM/relation values, groups, containers, formatters,
  vCard 3.0 subset coding, change-history event types, and `CNError`.
- Process-local **in-memory** contact graph. After `requestAccess(for:)`,
  save/fetch/enumerate/predicates/groups behave deterministically inside this
  process. `CNContactStoreDidChange` is posted on save.
- Property keys, standard labels (`_$!<Home>!$_`, `iPhone`, …), and IM/social
  service names follow the documented Apple string contract.
- Name and mailing-address formatting are portable joins, not Apple locale
  tables.

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

See `oracle-questions.tsv` for Darwin probes: TCC prompt timing, unified
linked-contact identity, exact kinship label payloads, `parentContainerNotWritable`
raw value, locale name/address formatting, and Apple-identical vCard bytes.
