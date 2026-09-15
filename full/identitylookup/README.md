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
- `ILMessageFilterQueryHandling` and `ILMessageFilterCapabilitiesQueryHandling`
  expose both the ObjC completion-handler selector and the Swift `async`
  overlay. The completion twin completes synchronously in-process; the
  `async` overlay bridges it via checked continuation. Fail-closed defaults
  answer `.none` / empty capabilities.
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
- `extensionPointName` is the Apple-oracle pinned Darwin literal
  `"com.apple.live-lookup"` (`xcrun swiftc`, Xcode 26.1). Linux has no
  extension host; the constant is for identifier comparison only.
- No fabricated Apple network, PIR, or classification-service success.

## Depth pass 2026-09

Implemented **145** of 150 exact IDs (4 `declared` async methods, 1 CoreData
`deferred` typealias). Nondeferred count 149, above the medium-full floor of
75.

Wave 10: Apple-oracle probe (`xcrun swiftc`, Xcode 26.1) pinned
`extensionPointName` to `"com.apple.live-lookup"`; the answered oracle
question was removed (7 remain). Implemented/declared/deferred counts are
unchanged at 145/4/1: the 4 `declared` rows are `async throws` manager
methods that cannot be invoked from the sealed runner's synchronous
no-argument tests without `await`, and the 1 `deferred` row is a
CoreData-owned `NSManagedObject` lookalike this port is forbidden to publish.

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
