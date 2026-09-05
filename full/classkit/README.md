# ClassKit (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`ClassKit` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and pinned `dotnet/macios` bindings. It is not
wired into the shared guest package; that integration is a later
central-review step.

## What is real

- `CLSBinaryValueType`, `CLSContextType`, `CLSError.Code`, and
  `CLSProgressReportingCapability.Kind` use the pinned macios/API-digester
  raw values (`trueFalse = 0` … `correctIncorrect = 3`; `none = 0` …
  `custom = 17`; `none = 0` … `invalidAccountCredentials = 10`;
  `duration = 0` … `score = 4`).
- `CLSContextTopic`, `CLSErrorUserInfoKey`, and `CLSPredicateKeyPath` are
  string newtypes. Topic and error-userInfo payloads use ObjC constant
  names; predicate key paths use the public property names so a process-local
  tree can be queried.
- `CLSError` is a `CustomNSError` overlay over `CLSErrorCodeDomain` with
  stored `userInfo`, `==` on code plus userInfo, hashing by code, and
  `Code ~= Error` pattern matching.
- `CLSContext` is a process-local curriculum tree: parent/child,
  identifier paths (main app context excluded), become/resign active,
  navigation children, progress-reporting capabilities, metadata, and
  `createNewActivity()`. Nesting deeper than eight levels, duplicate
  sibling identifiers, and re-parenting are no-ops.
- `CLSActivity` is a start/stop state machine with clamped `progress`
  (`0...1`), `addProgressRange` taking `max(progress, end)`, accumulated
  `duration`, and primary/additional activity items.
- `CLSBinaryItem`, `CLSQuantityItem`, and `CLSScoreItem` store their
  documented fields.
- `CLSObject` stamps `dateCreated` / `dateLastModified` and round-trips
  through `NSSecureCoding`.
- `CLSDataStore.shared` owns a main app context. `portableContexts(matchingIdentifierPath:)`
  walks or asks `CLSDataStoreDelegate` to create missing nodes.

Host-compiled sources import Foundation only. The identity probe
`tests/agent/ClassKitDependencyIdentity.swift` imports `ClassKit` and
`Foundation` for the later EC2 integration build.

## Fail-closed boundaries

Linux has no ClassKit daemon, Schoolwork, managed Apple ID, or education
entitlement.

- `CLSDataStore.save(completion:)` always delivers `CLSError.classKitUnavailable`
  and never claims a successful Apple persist. The completion runs before
  `save` returns.
- `fetchActivity(for:)` throws `classKitUnavailable`.
- `completeAllAssignedActivities(matching:)` is a no-op (there are no
  assignments).
- `CLSContextProvider.updateDescendants(of:)` is declared; a conforming
  type may throw `classKitUnavailable`. Nothing invents a catalog.
- `CLSContext.thumbnail` (`CGImage`) is deferred: CoreGraphics is not a
  seeded dependency.
- `NSUserActivity.contextIdentifierPath` / `isClassKitDeepLink` are
  deferred: `NSUserActivity` is not in Linux Foundation.

## Deferred

- `CLSContext.thumbnail`
- `NSUserActivity.contextIdentifierPath`
- `NSUserActivity.isClassKitDeepLink`

Apple's save-completion queue, progress-range union rule, exact
`CLSContextTopic` / `CLSPredicateKeyPath` Darwin NSString bytes, and
errors for illegal `addChildContext` remain oracle questions.

Run the sealed host gate with:

```sh
bash full/classkit/tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Implemented **193** identifiers, declared **5** (async overlays that the
host runner cannot await), deferred **3**. Nondeferred total **198** of
201 (lane floor 101).

Top-5 implemented evidence distribution:

1. `testEnumRawValues` — 57 (Int enum cases, raw values, Hashable/Equatable)
2. `testTypedConstants` — 35 (string newtypes and C constants)
3. `testCLSErrorBridging` — 26 (CLSError overlay)
4. `testBinaryItem` / `testContextInit` / `testContextProperties` — 7 each
5. `testActivityLifecycle` / `testDataStoreShared` — 5 each

Enum/option-set members and C constants share table-driven value tests.
No other single test is cited by more than 40% of the remaining
implemented rows (`testCLSErrorBridging` is 26/101 ≈ 26%).
