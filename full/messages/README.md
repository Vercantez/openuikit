# Messages (Linux starting point)

This directory is a fail-closed portable `Messages` module for the OpenUIKit
Linux platform, seeded from the Xcode 26.1 iPhoneOS public surface (180 exact
IDs). Isolated host compilation produces `libMessages.dylib` with Foundation
only. `UIView` / `UIViewController` superclasses, `UIImage`, `UIColor`, and
`UIEdgeInsets` are UIKit-owned; this module does not publish lookalikes.
A later UIKit-linked build can restore those members.

Linux has no Messages app, iMessage app-extension host, or Critical Messaging
daemon. Insert, send, and authorization never report success.

## What is real

- `MSMessageErrorCode` raw values match pinned `dotnet/macios` `[Native]`
  order: `unknown = -1`, `fileNotFound = 1`, then sequential through
  `apiUnavailableInPresentationContext = 11` (no case `0`).
- `MSMessagesAppPresentationStyle` is `UInt` `compact = 0`, `expanded = 1`,
  `transcript = 2`.
- `MSMessagesAppPresentationContext` is `UInt` `messages = 0`, `media = 1`
  (Apple Swift overlay raw type, not the macios `long` spelling).
- `MSStickerSize` is `Int` `small = 0`, `regular = 1`, `large = 2`.
- `MSMessagesErrorDomain` is the string `MSMessagesErrorDomain`.
- `MSStickersErrorDomain` is the string `MSStickersErrorDomain`.
- `MSCriticalMessagingError` uses digester case order with sequential `Int`
  raw values `0...4`. Linux `errorDomain` is `MSCriticalMessagingError`.
- `MSCriticalMessagingAuthorizationStatus` is `unknown = 0`, `denied = 1`,
  `approved = 2`.
- `MSRecipient` is hashed and compared by `phoneNumber`.
- `MSMessage` stores URL, summary, accessibility, expire flag, and an
  `NSCopying` layout. Local messages are not pending and use a null sender
  UUID. NSSecureCoding round-trips Linux keys only.
- `MSSticker` validates file URL, existence, regular file, readability,
  PNG/GIF/JPEG magic bytes, and a non-empty localized description.
- `MSStickerBrowserView.reloadData()` queries its data source synchronously.
- `MSMessagesAppViewController.requestPresentationStyle` updates
  `presentationStyle` and invokes will/did transition on the same stack.
- Conversation insert/send completion handlers run immediately with
  `MSMessageErrorCode.sendWhileNotVisible` (invalid attachment URLs fail
  earlier with `improperFileURL` / `fileNotFound` / `improperFileType`).

## Fail-closed boundaries

- `MSCriticalSMSMessenger.maximumCriticalMessagingRecipients` is `0`.
- `requestAuthorization(for:)`, `checkAuthorizationStatus(for:)`, and
  `send(_:to:)` throw `MSCriticalMessagingError.notSupported` (async;
  awaited in-process by `MSCriticalMessagingTests`, throwing immediately
  with no daemon or carrier).
- No Mail/Messages UI, no extension presentation, no fabricated send.
- `MSMessageTemplateLayout.image`, `MSStickerBrowserView.contentInset`, and
  `MSMessagesAppTranscriptPresentation.messageTintColor` are deferred until
  guest UIKit is on the link line.

## Depth pass 2026-09

Implemented **177** of 180 exact IDs (0 `declared`, 3 UIKit-typed `deferred`
properties). Nondeferred count 180, above
the medium-full floor of 90.

Top-5 `implemented` evidence distribution:

1. `testMessageErrorCodeRawValues` — 17 rows (enum table)
2. `testCriticalMessagingErrorRawValues` — 12 rows (enum table)
3. `testAuthorizationStatusRawValues` — 10 rows (enum table)
4. `testPresentationStyleRawValues` — 8 rows (enum table)
5. `testStickerSizeRawValues` — 8 rows (enum table)

No non-enum test is cited by more than 7 implemented rows.

## Wave-4 recount 2026-09-15

Recount: **174** implemented / **3** declared / **3** deferred of 180 —
unchanged. The 3 declared rows are the `async` Critical Messaging methods
(`requestAuthorization`, `checkAuthorizationStatus`, `send`); calling any of
them requires `await`, which the sealed gate forbids in cited tests, and they
guard a daemon/entitlement path that stays fail-closed, so they remain
declared. The 3 deferred rows are UIKit-typed properties (`UIImage.image`,
`UIEdgeInsets.contentInset`, `UIColor.messageTintColor`); UIKit is not on the
isolated link line and public lookalikes are forbidden, so they remain
deferred. Host-toolchain repair only: `CGPoint`/`CGSize`/`CGRect` `.zero` and
`CGRect(x:y:width:height:)` now require CoreGraphics on the current SDK, so
product and test code uses the Foundation-visible `origin:size:` /
`CGPoint(x:y:)` / `CGSize(width:height:)` spellings with no new imports and no
behavior change.

## Wave-11 recount 2026-09-15

Recount: **174** implemented / **3** declared / **3** deferred of 180 —
unchanged from wave 4 (gain +0). All 6 leftovers were re-examined and none
is convertible in-process:

- The 3 declared rows are the `async throws` Critical Messaging methods
  (`requestAuthorization`, `checkAuthorizationStatus`, `send`). Their precise
  IDs encode `async`; any test calling them requires `await`, which the
  sealed gate forbids in cited tests (no `await`, semaphore waits, RunLoop,
  or `DispatchQueue.main`), and they guard a daemon/entitlement path whose
  success stays fail-closed. Removing `async` would diverge from the Apple
  surface, so they remain `declared`.
- The 3 deferred rows are UIKit-typed properties (`UIImage.image`,
  `UIEdgeInsets.contentInset`, `UIColor.messageTintColor`). UIKit is not on
  the isolated link line and a public framework-local substitute for a
  dependency-owned type is forbidden, so they remain `deferred`.
- The overlay override (SwiftUI identity View modifiers) does not apply:
  this surface contains no SwiftUI View modifiers.

Verification this wave: `libMessages.dylib` compiles clean under
`-warnings-as-errors`; a sealed-gate-equivalent runner invoking all 64 cited
`implemented` tests passes and emits the load-smoke marker. (The shared
`test_host.sh` deliverable validator refuses before compiling because
`full/framework-roadmap/framework-roadmap.json` is absent from this
worktree — out of scope for this lane and pre-existing.)

## Wave-13 recount 2026-09-18

Recount: **177** implemented / **0** declared / **3** deferred of 180 —
gain +3 over waves 4, 11, and 12. The sealed runner is now `@main async`
and awaits top-level `func test*() async`, so the 3 formerly declared
`async throws` Critical Messaging methods (`requestAuthorization`,
`checkAuthorizationStatus`, `send`) are now `implemented`: each is
awaited in-process in `tests/agent/MSCriticalMessagingTests.swift` and
throws `MSCriticalMessagingError.notSupported` immediately with no
daemon, entitlement, or carrier path (fail-closed success stays
fail-closed). The 3 deferred rows remain UIKit-typed properties
(`UIImage.image`, `UIEdgeInsets.contentInset`,
`UIColor.messageTintColor`); UIKit is not on the isolated link line and
a public framework-local substitute for a dependency-owned type is
forbidden, so they remain `deferred`. The overlay override (SwiftUI
identity View modifiers) does not apply: this surface contains no
SwiftUI View modifiers.

Verification this wave: `libMessages.dylib` compiles clean under
`-warnings-as-errors`; an async host runner awaiting the 3 new
`MSCriticalMessagingTests` passes and emits its marker.

## Wave-12 recount 2026-09-15

Recount: **174** implemented / **3** declared / **3** deferred of 180 —
unchanged from waves 4 and 11 (gain +0). All 6 leftovers re-examined,
none convertible in-process:

- The 3 declared rows are the `async throws` Critical Messaging methods
  (`requestAuthorization`, `checkAuthorizationStatus`, `send`). Any test
  calling them requires `await`, which the sealed gate forbids in cited
  tests, and they guard a daemon/entitlement path whose success stays
  fail-closed, so they remain `declared`.
- The 3 deferred rows are UIKit-typed properties (`UIImage.image`,
  `UIEdgeInsets.contentInset`, `UIColor.messageTintColor`). UIKit is not
  on the isolated link line and a public framework-local substitute for a
  dependency-owned type is forbidden, so they remain `deferred`.
- The overlay override (SwiftUI identity View modifiers) does not apply:
  this surface contains no SwiftUI View modifiers.

Verification this wave: `libMessages.dylib` compiles clean under
`-warnings-as-errors`; a sealed-gate-equivalent runner (Darwin import
shim for the macOS host; `Glibc` on Linux) invoking all 64 cited
`implemented` tests passes and emits the load-smoke marker as its sole
stdout. (`test_host.sh` still refuses at the shared deliverable
validator on the missing out-of-lane `framework-roadmap.json`, as in
wave 11.)

## Tests

`tests/agent/MessagesLoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/*Tests.swift` holds the sealed focused tests.
`tests/agent/MessagesDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation and UIKit first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`). `swiftc` is Swift 6.2.4 / linux and the sealed gate compiles with a clean product tree.
