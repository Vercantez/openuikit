# PushToTalk (Linux starting point)

This directory is a fail-closed portable `PushToTalk` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

Coverage: **154 implemented / 0 declared / 0 deferred / 154 total**
(fully nondeferred, above the leaf-full floor of 124).

## What is real

- `PTChannelError` / `PTChannelErrorDomain` / `PTChannelError.Code` with the
  NS_ERROR_ENUM integers corroborated by the pinned dotnet-macios bindings
  (`unknown = 0` … `transmissionNotAllowed = 9`). Typed construction,
  `userInfo`, equality, hashing, `NSError` bridging, and `~=` matching are
  exercised.
- `PTInstantiationError` / `PTInstantiationErrorDomain` /
  `PTInstantiationError.Code` (`unknown = 0` …
  `instantiationAlreadyInProgress = 5`). The public factory always fails
  with `invalidPlatform`.
- Join, leave, transmit-source, service-status, and transmission-mode enums
  with the documented `[Native]` raw values.
- `PTChannelDescriptor` and `PTParticipant` store `name` and an optional
  image object. `PTPushResult` exposes `leaveChannel` and
  `activeRemoteParticipant(_:)`.
- Host-constructed `PTChannelManager` records join/leave/transmit requests
  and keeps `activeChannelUUID == nil`. Descriptor, participant, status,
  mode, and accessory-button setters complete with `channelNotFound`.

## Fail-closed boundaries

Linux has no Push To Talk daemon, `push-to-talk` background mode, PushKit
token, CallKit/PTT entitlement, or `AVAudioSession`.

- `PTChannelManager.channelManager(delegate:restorationDelegate:)` never
  returns a manager. The completion handler runs inline with
  `PTInstantiationError.invalidPlatform`.
- `requestJoinChannel`, `leaveChannel`, `requestBeginTransmitting`, and
  `stopTransmitting` never deliver success callbacks and never invent an
  Apple failure code.
- Audio-session activate/deactivate and ephemeral push-token callbacks are
  never sent by the manager. Host tests call those protocol methods on a
  probe only to exercise the Swift surface.
- UIKit and AVFoundation are not declared dependencies. `UIImage` and
  `AVAudioSession` are `NSObject` typealiases so selectors type-check.
  Images are never decoded; no real audio session is mixed.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**154 implemented / 0 declared / 0 deferred**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 22 | `PushToTalkErrorTests.swift#testPTChannelErrorCodes` |
| 14 | `PushToTalkErrorTests.swift#testPTInstantiationErrorCodes` |
| 9 | `PushToTalkErrorTests.swift#testPTChannelErrorConstructionAndUserInfo` |
| 9 | `PushToTalkErrorTests.swift#testPTInstantiationErrorConstructionAndUserInfo` |
| 9 | `PushToTalkEnumTests.swift#testPTChannelLeaveReasonRawValues` |

`testPTChannelErrorCodes` and `testPTInstantiationErrorCodes` are
table-driven enum-member and static `PT*Error.*` code tests.
`testPTChannelLeaveReasonRawValues` is a table-driven enum/constant value
test. Construction tests cover distinct non-enum error families and stay
well under the 40% bulk-relabel bound.

The sealed host gate was run as `bash full/pushtotalk/tests/acceptance/test_host.sh`.

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing; Cursor Build
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` vs campaign seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). That campaign token
is the host-inventory stamp; the sealed framework gate prints the four
framework markers and was not weakened. Swift 6.2.4 / linux compiled
`libPushToTalk.dylib`.

See `oracle-questions.tsv` for domain-string identity, factory queue/error
priority, join-failure callback timing, image copy semantics, audio-session
identity, and channel restoration order.
