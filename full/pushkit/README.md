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
  documented getters. `PKPushCredentials.token` is `Foundation.Data`. They have
  no public initializer (matching Apple's `DisableDefaultCtor` shape). Host
  tests construct them through `@_spi(OpenUIKitHost)`.
- `PKPushRegistry` is a process-local registry: `init(queue:)`, weak
  `delegate`, stored `desiredPushTypes`, and `pushToken(for:)`.
- `PKPushRegistryDelegate` includes the required credentials callback and
  the optional invalidation / incoming-push requirements. Optional ObjC
  witnesses are defaulted via protocol extensions. The completion-handler
  and `async` incoming-push presentations share one precise ID in the graph;
  the default completion witness forwards to `async`.

## Linux-local `PKPushType` raw values

The pinned graphs do not record Darwin `NSString` payloads for
`PKPushType.voIP`, `.complication`, or `.fileProvider`. Those constants remain
source-compatible, but their `rawValue` strings are a **Linux-local fallback**,
not Apple-observed bytes. Coverage lists the three constants as `declared`.
Compare typed constants (`.voIP == .voIP`), not guessed literals.

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

## Isolated gate vs future EC2

`tests/acceptance/test_host.sh` compiles this module in isolation against the
toolchain Foundation. **That is not an integrated Linux-guest success claim.**

`tests/agent/PushKitDependencyIdentity.swift` is a probe for a future clean
EC2 run. That run must build the real guest Foundation module and dylib (plus
the platform Dispatch/runtime) first, build PushKit with those `-I`/`-L`
paths, link a client that imports both, pass `Foundation.Data` through public
`PKPushCredentials.token` / payload dictionary / `pushToken(for:)` APIs, run
with `LD_LIBRARY_PATH`, emit `PUSHKIT_DEPENDENCY_IDENTITY_OK`, and confirm
`libPushKit.dylib` is loaded. No local Docker.

## Still deferred / oracle-owned

Exact Darwin `NSString` payloads for the `PKPushType` constants, token
lifetime across APNs rotation, CallKit "must report incoming call" coupling,
and which incoming-push overlay Apple dispatches when both exist are recorded
in `oracle-questions.tsv`.

## Gate

```sh
bash tests/acceptance/test_host.sh
```
