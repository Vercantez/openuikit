# CarKey (Linux starting point)

This directory is a fail-closed portable `CarKey` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph. It is not wired into the shared guest package;
that integration is a separate central review step.

Coverage: **110 implemented / 4 declared / 0 deferred / 114 total**
(fully nondeferred, above the leaf-full floor of 92).

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
  and throws `FeatureNotSupported` without producing a session. It is
  `declared` because the sealed runner cannot `await`.
- `ExecutionRequest.results()` (all three request types) is async and
  throws `RequestNotInProgress`. Also `declared`.
- `sign(data:forVehicle:)` never returns an attestation.
- Delegate callbacks are never delivered by the session. Tests invoke
  delegate methods directly.
- `CarKeyRemoteControlSession.init()` and request `init()` are Linux-only
  so fail-closed instance methods can be exercised. Apple's session type
  has no public designated initializer.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**110 implemented / 4 declared / 0 deferred**.

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

The sealed host gate was run as `bash full/carkey/tests/acceptance/test_host.sh`.

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs campaign
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). That campaign token
is the host-inventory stamp; the sealed framework gate prints the
deliverable / reference / runtime / host markers. The gate compiles with
a clean product tree (`products=clean`).
