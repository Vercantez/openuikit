# CarKey (Linux starting point)

This directory is a fail-closed portable `CarKey` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph. It is not wired into the shared guest package;
that integration is a separate central review step.

Coverage: **114 implemented / 0 declared / 0 deferred / 114 total**
(fully implemented, above the leaf-full floor of 92).

## What is real

- `CarKeyErrorCode` as a PascalCase Swift `Error`/`Equatable`/`Hashable`
  enum matching the API-digester child order (`Internal` …
  `FeatureNotSupported`). No integer raw values are claimed; the graph has
  no `RawRepresentable` witnesses.
- `FunctionIdentifier`, `ActionIdentifier`, and `FunctionStatus` as `Int`
  `RawRepresentable` + `Hashable` wrappers with both `init(_:)` and
  `init(rawValue:)`. `ExecutionStatus` is `RawRepresentable` + `Sendable`
  only (no public `Equatable`/`Hashable` in the graph).
- `CarKeyRemoteControlSession.ContinuationStrategy` (`.automatic` /
  `.manual`) equality and hashing.
- Remote keyless-entry action value types store `functionID`, `actionID`,
  and `recipientVehicleID` from `init(functionID:actionID:vehicleID:)`.
- `VehicleReport` stores identifier, connection flag, supported functions,
  per-function status, and proprietary `Data`. Lookups for unlisted
  function ids throw `FunctionUnknown`.
- `Attestation` stores `appBundleIdentifier`, `nonce`, `signedData`, and
  `signature` (Linux constructor only; hardware `sign` never succeeds).
- Inactive-session methods throw `SessionNotActive`. Launch-event
  registration throws `FeatureNotSupported`. Request `stop()` /
  `confirm(_:)` throw `RequestNotInProgress`. Configurable
  `eventStream` finishes with no events.
- `CarKeyRemoteControlSessionDelegate` required methods plus the protocol
  extension default for `didCreateKey`.

## Fail-closed boundaries

Linux has no CarKey daemon, Wallet/CarKey entitlement, Secure Element,
vehicle UWB/NFC/BLE radio, or paired digital key.

- `CarKeyRemoteControl.start(delegate:subscriptionRange:with:)` is async
  and throws `FeatureNotSupported` without producing a session (covered by
  async test `testAsyncStartFailsClosed`).
- `ExecutionRequest.results()` (all three request types) is async and
  throws `RequestNotInProgress` (covered by async
  `testAsyncOneShotResultsFailsClosed`, `testAsyncEnduringResultsFailsClosed`,
  `testAsyncConfigurableResultsFailsClosed`).
- `sign(data:forVehicle:)` never returns an attestation.
- Delegate callbacks are never delivered by the session. Tests invoke
  delegate methods directly.
- `CarKeyRemoteControlSession.init()` and request `init()` are Linux-only
  so fail-closed instance methods can be exercised. Apple's session type
  has no public designated initializer.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**110 implemented / 4 declared / 0 deferred**.

## Wave 13 async conversion (2026-09-18)

Before: 110 implemented / 4 declared / 0 deferred / 114 total.
After: 114 implemented / 0 declared / 0 deferred / 114 total.

The sealed host runner is now `@main async` and awaits top-level
`func test*() async`, so all 4 leftover `declared` rows converted to
`implemented`: `CarKeyRemoteControl.start` (throws `FeatureNotSupported`
immediately, no suspension) plus the three `ExecutionRequest.results()`
variants (each throws `RequestNotInProgress` immediately). New
`tests/agent/CarKeyAsyncTests.swift` holds the four async tests, each
calling its identifier and asserting the fail-closed error with
`precondition` (no `DispatchQueue.main`, `RunLoop`, or semaphores).
The overlay OVERRIDE is not applicable: zero SwiftUI View-modifier rows
in this surface. Top citation share is 13/114 = 11.4%
(`testCarKeyErrorCodeCases`), well under the 40% bulk-relabel bound.

Validation on this host: product `swiftc -warnings-as-errors` dylib build
OK; all 34 distinct cited tests (30 sync + 4 async) compiled and ran with
marker-only `CARKEY_AGENT_RUNTIME_OK` output (runner generated from
`implemented` rows exactly as `tests/acceptance/test_host.sh` does, with
`Darwin` shimmed for `Glibc` on this macOS host only — no repo file
changed for that).

## Wave 11 leftover re-examination (2026-09-15)

Before: 110 implemented / 4 declared / 0 deferred / 114 total.
After: 110 implemented / 4 declared / 0 deferred / 114 total (no change).

All 4 leftover `declared` rows were re-examined and must stay `declared`:
each mangling contains `Ya` (async) — `CarKeyRemoteControl.start` plus the
three `ExecutionRequest.results()` variants. They compile (product builds
clean under `-warnings-as-errors`) and fail closed (`FeatureNotSupported` /
`RequestNotInProgress` without suspending), but no honest sync test can call
them: the sealed runner only invokes top-level synchronous no-argument
`func test*()`, and the coverage contract bans `await`, semaphores,
`DispatchQueue.main`, and `RunLoop` in cited tests. The overlay OVERRIDE is
not applicable: this surface contains zero SwiftUI View-modifier rows.

Validation on this host: product `swiftc -warnings-as-errors` dylib build
OK; all 30 distinct cited tests compiled and ran with marker-only
`CARKEY_AGENT_RUNTIME_OK` output (runner generated from `implemented` rows
exactly as `tests/acceptance/test_host.sh` does; `Glibc` shimmed to `Darwin`
for this macOS host only — no repo file changed for that). The full
host-gate script itself cannot pass in this isolated worktree for a
pre-existing environmental reason: the shared deliverable validator requires
`full/framework-roadmap/framework-roadmap.json`, which this worktree does not
materialize (its sha256 matches the main-repo file byte-for-byte), and the
contract forbids creating files outside `full/carkey/` to backfill it.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 13 | `CarKeyErrorTests.swift#testCarKeyErrorCodeCases` |
| 8 | `CarKeyIdentifierTests.swift#testFunctionStatus` |
| 8 | `CarKeyIdentifierTests.swift#testActionIdentifier` |
| 8 | `CarKeyIdentifierTests.swift#testFunctionIdentifier` |
| 7 | `CarKeyIdentifierTests.swift#testContinuationStrategy` |

`testCarKeyErrorCodeCases` is a table-driven enum-member test. The
identifier/status tests cover distinct `RawRepresentable` wrappers
(inits, equality, hashing) and stay well under the 40% bulk-relabel bound
on remaining implemented rows.

The sealed host gate was run as `bash full/carkey/tests/acceptance/test_host.sh`
and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=CarKey lane=leaf-full symbols=114
FRAMEWORK_FANOUT_REFERENCE_OK
CARKEY_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CarKey dylib=libCarKey.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs campaign
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). That campaign token
is the host-inventory stamp; the sealed framework gate prints the
deliverable / reference / runtime / host markers. The gate compiles with
a clean product tree (`products=clean`).

## Wave 12 leftover re-examination (2026-09-15)

Before: 110 implemented / 4 declared / 0 deferred / 114 total.
After: 110 implemented / 4 declared / 0 deferred / 114 total (no change).

All 4 leftover `declared` rows re-verified as unconvertible: every mangling
contains `Ya` (async) — `CarKeyRemoteControl.start` plus the three
`ExecutionRequest.results()` variants. They compile clean
(`swiftc -warnings-as-errors` dylib build OK on Apple Swift 6.2.1,
BUILD_EXIT=0) and fail closed without suspending, but no honest sync test
can call them under the coverage contract (no `await`, semaphores,
`DispatchQueue.main`, or `RunLoop` in cited tests; sealed runner only
invokes top-level sync no-argument `func test*()`). The overlay OVERRIDE is
not applicable: zero SwiftUI View-modifier rows in this surface
(`grep -i swiftui|overlay` on coverage.tsv returns nothing). Top citation
share is 13/110 = 11.8% (`testCarKeyErrorCodeCases`), well under the 40%
bulk-relabel bound. No product, coverage, oracle, manifest, or test file
needed changes; only this README section was added.
