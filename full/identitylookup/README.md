# IdentityLookup (Linux starting point)

This directory is a fail-closed portable `IdentityLookup` module for the
OpenUIKit Linux platform, seeded from the Xcode 26.1 iPhoneOS public surface
(150 exact IDs). Isolated host compilation produces `libIdentityLookup.dylib`
with Foundation only. Linux splits `HTTPURLResponse` into
`FoundationNetworking`; that module is imported as the Foundation overlay
split, not as an extra Apple framework. `NSExtensionContext`, `ExtensionFoundation.AppExtension`,
and Core Data `NSManagedObject` are not imported: this module does not publish
lookalikes of those foreign types.

Linux has no Message Filter extension host, SMS/Call Classification UI, Live
Caller ID PIR service, or Settings pane. Network deferral and Live Caller ID
mutations never report success.

## What is real

- `ILClassificationAction` raw values match pinned `dotnet/macios` `[Native]`
  order: `none = 0`, `reportNotJunk = 1`, `reportJunk = 2`,
  `reportJunkAndBlockSender = 3`.
- `ILMessageFilterAction` is `none = 0`, `allow = 1`, `junk = 2`,
  `promotion = 3`, `transaction = 4`. The overlay `static var filter` aliases
  `.junk` (historical ObjC `ILMessageFilterActionFilter`).
- `ILMessageFilterSubAction` is `none = 0`, transactional family
  `10000...10008`, promotional family `20000...20002`.
- `ILMessageFilterError.Code` is `system = 1` through
  `redundantNetworkDeferral = 5` (no case `0`).
- `ILMessageFilterErrorDomain` is the string `ILMessageFilterErrorDomain`.
- Communication, classification, filter-query, capabilities, and network
  response objects store caller fields and round-trip Linux NSSecureCoding
  keys. Darwin archive layouts are unobserved.
- `ILMessageFilterQueryResponse` defaults `action` and `subAction` to `.none`.
- `LiveCallerIDLookupExtensionContext` is a `Hashable` / `Codable` value type.
- `LiveCallerIDLookupManager.status(forExtensionWithIdentifier:)` is always
  `.disabled`.
- `NSSet` typealiases for Live Lookup store property sets are Foundation `NSSet`.

## Fail-closed boundaries

- `deferQueryRequestToNetwork` completes immediately with
  `ILMessageFilterError.invalidNetworkURL` (no `ILMessageFilterNetworkURL`, no
  daemon).
- `openSettings()`, `reset(forExtensionWithIdentifier:)`,
  `refreshPIRParameters(forExtensionWithIdentifier:)`, and
  `refreshExtensionContext(forExtensionWithIdentifier:)` throw
  `ILMessageFilterError.system` (async; declared, not awaited by the isolated
  runner).
- `LiveCallerIDLookupProtocol` does not inherit `AppExtension`;
  `LiveCallerIDLookupExtensionConfiguration` does not inherit
  `AppExtensionConfiguration`.
- `LiveLookupStoreCoreDataFrameworkManagedObject` is deferred: `NSManagedObject`
  is CoreData-owned.
- `extensionPointName` is the empty string until an Apple-oracle probe records
  the Darwin literal.
- No fabricated Apple network, PIR, or classification-service success.

## Depth pass 2026-09

Implemented **143** of 150 exact IDs (6 `declared` async methods, 1 CoreData
`deferred` typealias). Nondeferred count 149, above the medium-full floor of
75.

Top-5 `implemented` evidence distribution:

1. `testMessageFilterSubActionRawValues` — 18 rows (enum table)
2. `testMessageFilterErrorStruct` — 14 rows (error overlay table)
3. `testMessageFilterActionRawValues` — 11 rows (enum table)
4. `testClassificationActionRawValues` — 9 rows (enum table)
5. `testMessageFilterErrorCodeRawValues` — 9 rows (enum table)

No non-enum test is cited by more than 7 implemented rows.

## Tests

`tests/agent/IdentityLookupLoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/*Tests.swift` holds the sealed focused tests.
`tests/agent/IdentityLookupDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`). `swiftc` is Swift 6.2.4 / linux and the sealed gate compiles with a clean product tree.
