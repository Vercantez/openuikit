# PushKit (Linux starting point)

This directory is a leaf-full port of Apple's public `PushKit` Swift surface
from the Xcode 26.1 iPhoneOS seed. It produces module `PushKit` and
`libPushKit.dylib`. It is not wired into the shared guest package; that
integration belongs to central review.

## What is real

- `PKPushType` is a `RawRepresentable` `String` newtype with `Hashable`,
  `Equatable`, `Sendable`, `init(rawValue:)`, and the public constants
  `voIP`, `complication`, and `fileProvider`.
- `PKPushCredentials` and `PKPushPayload` are `NSObject` subclasses with the
  documented getters. They have no public initializer (matching Apple's
  `DisableDefaultCtor` shape). Host tests construct them through
  `@_spi(OpenUIKitHost)`.
- `PKPushRegistry` is a process-local registry: `init(queue:)`, weak
  `delegate`, stored `desiredPushTypes`, and `pushToken(for:)`.
- `PKPushRegistryDelegate` includes the required credentials callback and
  the optional invalidation / incoming-push requirements. Optional ObjC
  witnesses are defaulted via protocol extensions. The completion-handler
  and `async` incoming-push presentations share one precise ID in the graph;
  the default completion witness forwards to `async`.

## Fail-closed boundaries

Linux has no Apple Push Notification service, no VoIP entitlement broker, and
no device push identity. Therefore:

- Assigning `desiredPushTypes` never mints a token and never calls
  `pushRegistry(_:didUpdate:for:)`.
- `pushToken(for:)` returns `nil` unless a host has installed credentials for
  a type that is still desired.
- Incoming Apple pushes are not received. Host SPI may deliver a locally
  constructed `PKPushPayload` onto the callback queue for dispatch tests.
- Removing a type invalidates only a previously cached host token; there is
  no APNs deregistration.
- TBD-only symbols (`PKPushTypeUserNotifications`, `PKPublicChannel`,
  `PKUserNotificationsRemoteNotificationServiceConnection`) are not part of
  this module.

## Still deferred / oracle-owned

Exact Darwin `NSString` payloads for the `PKPushType` constants, token
lifetime across APNs rotation, CallKit "must report incoming call" coupling,
and which incoming-push overlay Apple dispatches when both exist are recorded
in `oracle-questions.tsv`. This starting point uses C export names as raw
values and refuses fabricated Apple-service success.

## Gate

```sh
bash full/pushkit/tests/acceptance/test_host.sh
```
