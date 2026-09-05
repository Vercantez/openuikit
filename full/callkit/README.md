# CallKit (Linux starting point)

This directory is a fail-closed portable `CallKit` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph and pinned `dotnet/macios` CallKit bindings. It
is not wired into the shared guest package; a passing isolated host gate is
not integrated Linux success.

## What is real

- Error domains match the pinned macios `[ErrorDomain]` strings. Enum raw
  values match the pinned `[Native]` bindings (`CXError.Code.unknownError = 0`
  through `missingVoIPBackgroundMode = 3`, incoming/request/directory/NSE
  codes, `CXCallEndedReason.failed = 1`, handle and DTMF types, translation
  engines `default = 0` / `custom = 1`).
- `CustomNSError` overlays preserve `domain` / `code` / `userInfo` through
  `as NSError`. `~=` matches typed errors and `NSError` domain/code. This is
  not Apple `_BridgedStoredNSError`; a fresh `NSError(domain:code:)` does not
  become `CXError`. Hash / equality / `init(_:userInfo:)` are exercised.
- Process-local call registry with **atomic full-transaction preflight**.
  Ownership is per UUID: actions route to the provider that owns the call.
  A start action is accepted only when exactly one live provider exists,
  never via a process-global last-provider pointer. Empty transactions,
  unknown UUIDs, duplicate starts, missing group targets, and maximum call
  groups reject with no registry mutation. A failed action completes the
  request with `invalidAction`.
- Delegate `perform` / `providerDidBegin` / `providerDidReset` and request
  completions run **inline on the calling thread**. Linux has no CallKit
  daemon or guest main run loop; Darwin hop ordering remains an oracle
  question.
- `CXAction.timeoutDate` in the past causes `provider(_:timedOutPerforming:)`
  then `fail()` instead of `perform`.
- `NSSecureCoding` round-trips `CXHandle`, `CXAction` subclasses, and
  `CXTransaction` (including nested start-call actions).
- `CXCallDirectoryExtensionContext` stores sequential blocking and
  identification numbers in-process. `completeRequest`, reload, enabled
  status, and `openSettings` fail-closed with `noExtensionFound`.

## Fail-closed boundaries

- No telephony daemon, system call UI, PushKit NSE, or Settings pane.
  `CXProvider.reportNewIncomingVoIPPushPayload` completes with
  `invalidClientProcess`.
- `CXProviderDelegate.provider(_:didActivate:)` /
  `provider(_:didDeactivate:)` are omitted: the isolated host gate cannot
  `import AVFoundation`, and a module-local `AVAudioSession` would collide
  with the first-party type. Those exact IDs are `deferred`.
- `CXCallDirectoryPhoneNumberMax` compiles as `Int64.max`. Apple's exact
  payload is unobserved in the sealed seed; the row is `declared`.
- Translation languages are stored strings; no Apple translation engine runs.

## Tests

`tests/agent/CallKitRuntime.swift` is the host-gate probe and prints
`CALLKIT_AGENT_RUNTIME_OK`. Focused `*Tests.swift` files are the coverage
evidence anchors.

## Depth pass 2026-09

Coverage before this pass: **313 implemented / 51 declared / 2 deferred /
0 unavailable / 0 not-applicable**.

Coverage after this pass: **363 implemented / 1 declared / 2 deferred /
0 unavailable / 0 not-applicable**.

Raised to `implemented`: NSCoder round-trips for actions and
`CXTransaction`, `CustomNSError` / `_BridgedStoredNSError` overlay members
(equality, hash, `userInfo`, `init(_:userInfo:)`), and
`provider(_:timedOutPerforming:)` via a past-`timeoutDate` state machine.

Still `declared`: `CXCallDirectoryPhoneNumberMax` (integer payload
unobserved). Still `deferred`: audio-session delegate methods (no
`AVAudioSession` in the isolated gate).

Top-5 evidence distribution among the 363 `implemented` rows:

1. `CXCallDirectoryErrorTests.swift#testCallDirectoryManagerErrorCodeRawValues` — 12 (3.3%)
2. `CXRequestTransactionErrorTests.swift#testRequestTransactionErrorCodeRawValues` — 12 (3.3%)
3. `CXIncomingCallErrorTests.swift#testIncomingCallErrorCodeRawValues` — 11 (3.0%)
4. `CXCallDirectoryErrorTests.swift#testCallDirectoryManagerErrorInitUserInfoAndCustomNSError` — 10 (2.8%)
5. `CXIncomingCallErrorTests.swift#testIncomingCallErrorInitUserInfoAndCustomNSError` — 10 (2.8%)

Enum/option-set members share table-driven raw-value tests. No other single
test is cited by more than 40% of implemented rows.
