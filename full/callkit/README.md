# CallKit (Linux starting point)

This directory is a fail-closed portable `CallKit` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph and pinned `dotnet/macios` CallKit bindings. It
is not wired into the shared guest package; a passing isolated host gate is
not integrated Linux success.

The GitHub App installation for this promotion run could not fetch
`github.com/Vercantez/openuikit-linux-platform` (`cursor/port-callkit-to-linux-869c`,
legacy PR #22). The lane was therefore built from the monorepo seed plus
macios declaration evidence. The monorepo `reference/` dossier was kept
(generator SHA-256 `2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`).

## What is real

- Error domains match the pinned macios `[ErrorDomain]` strings. Enum raw
  values match the pinned `[Native]` bindings (`CXError.Code.unknownError = 0`
  through `missingVoIPBackgroundMode = 3`, incoming/request/directory/NSE
  codes, `CXCallEndedReason.failed = 1`, handle and DTMF types, translation
  engines `default = 0` / `custom = 1`).
- `CustomNSError` overlays preserve `domain` / `code` / `userInfo` through
  `as NSError`. `~=` matches typed errors and `NSError` domain/code. This is
  not Apple `_BridgedStoredNSError`; a fresh `NSError(domain:code:)` does not
  become `CXError`.
- Process-local call registry with **atomic full-transaction preflight**.
  Ownership is per UUID: actions route to the provider that owns the call.
  A start action is accepted only when exactly one live provider exists,
  never via a process-global last-provider pointer. Empty transactions,
  unknown UUIDs, duplicate starts, missing group targets, and maximum call
  groups reject with no registry mutation.
- `CXProviderDelegate` `perform` / `providerDidBegin` / `providerDidReset`
  hop asynchronously onto the delegate queue (`nil` uses a dedicated serial
  queue). Tests occupy that queue to prove non-inline delivery.
- `CXCallDirectoryExtensionContext` stores sequential blocking and
  identification numbers in-process. `completeRequest`, reload, enabled
  status, and `openSettings` fail-closed with `noExtensionFound`.

## Fail-closed boundaries

- No telephony daemon, system call UI, PushKit NSE, or Settings pane.
  `CXProvider.reportNewIncomingVoIPPushPayload` throws
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
`CALLKIT_AGENT_RUNTIME_OK`.
