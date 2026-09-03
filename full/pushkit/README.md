# PushKit

Linux starting point for Apple's public `PushKit` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph plus `dotnet/macios` declaration
evidence (`src/pushkit.cs`). This directory is not wired into the shared guest
package. A passing isolated host gate is not integrated Linux success and is
not APNs, VoIP, or Apple-identity success.

The GitHub App on this promotion run cannot fetch
`github.com/Vercantez/openuikit-linux-platform` (404). The lane is therefore
implemented from the sealed monorepo seed rather than copied from fan-out
PR #10. The monorepo `reference/` dossier is the one kept
(`generatorSHA256=2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`).

## What is real

The public Swift surface compiles to `libPushKit.dylib`.

- `PKPushType` is a `RawRepresentable` / `Hashable` struct. Named lets are
  `voIP`, `complication`, and `fileProvider`. Linux raw values are the macios
  Field identifiers (`PKPushTypeVoIP`, `PKPushTypeComplication`,
  `PKPushTypeFileProvider`); Apple's NSString payloads are unobserved.
- `PKPushCredentials` and `PKPushPayload` are `NSObject` subclasses with no
  public default initializer (macios `DisableDefaultCtor`). Host tests
  construct in-process instances through `@_spi(OpenUIKitHost)`
  `PushKitHostControl`. Those objects are not APNs credentials or payloads.
- `PKPushRegistry` stores `delegate` (weak) and `desiredPushTypes`, and
  captures a callback queue at `init(queue:)`.
- `PKPushRegistryDelegate` has the required `didUpdate` method plus empty
  defaults for invalidation and both incoming-push spellings (deprecated
  iOS 8 path, iOS 11+ completion-handler, and the canonical `async` overlay).

## Fail-closed boundaries

Linux has no Apple Push service, VoIP entitlement, PKService daemon, or
Watch complication push path. The implementation never fabricates a device
token, incoming APNs payload, or successful registration.

- Setting `desiredPushTypes` records the set and does nothing else. It does
  not call `didUpdate` or `didInvalidate`.
- `pushToken(for:)` is always `nil`.
- Host-test SPI may hop a locally constructed credentials/payload object
  onto the registry callback queue with `DispatchQueue.async` (never `sync`)
  so tests can prove non-inline delegate delivery. That hop does not install
  a token and does not claim Apple delivery. Completions are exactly-once.
- Nil `init(queue:)` uses a private serial queue labeled
  `PushKit.PKPushRegistry.callback`. Whether Darwin uses the main queue or a
  private queue for nil is an open oracle question.
- TBD-only symbols (`PKPublicChannel`,
  `PKUserNotificationsRemoteNotificationServiceConnection`,
  `PKPushIncomingCallReportedNotification`, `PKNonMacTokenName`,
  `PKPushTypeUserNotifications`) are out of scope: they are not on the
  sealed public surface.
- `PKVoIPPushMetadata` / `didReceiveIncomingVoIPPush` appear in later macios
  bindings (iOS 26.4) and are absent from this iPhoneOS 26.1 seed.

## Still open

See `oracle-questions.tsv` for NSString payloads, nil-queue identity,
entitlement failure callbacks, incoming-push selector choice, and the TBD
`PKPushTypeUserNotifications` constant.

`tests/agent/PushKitRuntime.swift` is the isolated host probe
(`PUSHKIT_AGENT_RUNTIME_OK`).

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
