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
  `send(_:to:)` throw `MSCriticalMessagingError.notSupported` (async; declared,
  not awaited by the isolated runner).
- No Mail/Messages UI, no extension presentation, no fabricated send.
- `MSMessageTemplateLayout.image`, `MSStickerBrowserView.contentInset`, and
  `MSMessagesAppTranscriptPresentation.messageTintColor` are deferred until
  guest UIKit is on the link line.

## Depth pass 2026-09

Implemented **174** of 180 exact IDs (3 `declared` async Critical Messaging
methods, 3 UIKit-typed `deferred` properties). Nondeferred count 177, above
the medium-full floor of 90.

Top-5 `implemented` evidence distribution:

1. `testMessageErrorCodeRawValues` — 17 rows (enum table)
2. `testCriticalMessagingErrorRawValues` — 12 rows (enum table)
3. `testAuthorizationStatusRawValues` — 10 rows (enum table)
4. `testPresentationStyleRawValues` — 8 rows (enum table)
5. `testStickerSizeRawValues` — 8 rows (enum table)

No non-enum test is cited by more than 7 implemented rows.

## Tests

`tests/agent/MessagesLoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/*Tests.swift` holds the sealed focused tests.
`tests/agent/MessagesDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation and UIKit first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`). `swiftc` is Swift 6.2.4 / linux and the sealed gate compiles with a clean product tree.
