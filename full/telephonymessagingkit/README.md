# TelephonyMessagingKit (Linux starting point)

This directory is a fail-closed portable `TelephonyMessagingKit` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift
surface from the sealed symbol graph and API digester. It is not wired into the
shared guest package; that integration is a separate central review step.

Coverage: **957 implemented / 24 declared / 981 total** (above the leaf-full
floor of 785 nondeferred identifiers).

## What is real

- `TelephonyMessagingSession.shared` with a stable `UUID` identity,
  `isConfiguredForCarrierMessaging == false`, empty `cellularServices`, and an
  empty `cellularServiceStateUpdates` stream.
- `CellularServiceID` / `CellularServiceState` equality, hashing, and Codable
  round trips. Linux stores a UUID behind a host SPI initializer.
- SMS/MMS/RCS value types: handles, message IDs, content parts, file-transfer
  metadata, group context, business cards/carousels/menus, suggested actions,
  and request/result payloads. Memberwise host SPI initializers exist where the
  census only listed `init(from:)`.
- Enums with distinct cases, `Equatable`/`Hashable`/`Codable` where the graph
  records those conformances, and `LocalizedError` text on the four `Error`
  types (`errorDescription`, `failureReason`, `recoverySuggestion`,
  `helpAnchor == nil`).
- `MMSMessage.totalSize` as the sum of part `data.count` in
  `UnitInformationStorage.bytes`.
- `RCSHandle.phoneNumber` returns `nil` for empty/whitespace input and
  `.uri(URI(rawValue: trimmed))` otherwise.
- `RCSService.Business.Card.FontStyle` as an `OptionSet` with bits
  `1 << 0 ... 1 << 2` (`bold`, `italics`, `underline`) plus the synthesized
  set-algebra operations.
- `isViable(for:)` is always `false`. Throwing `AsyncSequence` getters throw
  immediately rather than hanging.

## Fail-closed boundaries

Linux has no telephony daemon, baseband, carrier-messaging entitlement, or
RCS/MMS/SMS stack.

- `SMSService` mutating APIs and notification getters throw
  `SMSService.Error.notSupported`.
- `MMSService` mutating APIs and notification getters throw
  `MMSService.Error.mmsNotConfiguredForCarrier`.
- `RCSService` mutating APIs (send/upload/download/group chat/capabilities)
  throw `RCSService.Error.serviceUnavailable`. `configuration(for:)` is
  synchronous `throws` and uses the same error. `revokeMessage` never returns
  a success `Bool`.
- `RCSService.Business.themeColor` is always `nil`.
- Isolated-host stand-ins named `UTType`, `CGColor`, and
  `CLLocationCoordinate2D` exist only when those modules cannot be imported.
  They are not Foundation-owned types and are not used as Darwin ABI.

The 24 `declared` rows are the `async throws` service methods. The sealed
runner is synchronous and has no run loop, so those methods are compiled and
anchored in product sources but not awaited.

## Depth pass 2026-09

Fresh seed: no prior sources, coverage, or tests. After this pass:
**957 implemented / 24 declared**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 86 | `RCSBusinessTests.swift#testRCSBusinessProfile` |
| 63 | `RCSMessageTests.swift#testRCSMessageContentFamilies` |
| 59 | `RCSBusinessTests.swift#testRCSBusinessActions` |
| 56 | `RCSRequestTests.swift#testRCSConfigurationAndRequests` |
| 47 | `RCSRequestTests.swift#testRCSGroupAndCapabilityRequests` |

Enum cases share table-driven tests in `EnumTests.swift`. Option-set members
`bold` / `italics` / `underline` share `testFontStyleRawValues`. No other
single test is cited by more than 10% of the remaining implemented rows
(40% bulk-relabel bound).

The sealed host gate was run as `bash full/telephonymessagingkit/tests/acceptance/test_host.sh`
and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=TelephonyMessagingKit lane=leaf-full symbols=981
FRAMEWORK_FANOUT_REFERENCE_OK
TELEPHONYMESSAGINGKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=TelephonyMessagingKit dylib=libTelephonyMessagingKit.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`). The campaign
inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token: the toolchain is Swift 6.2.4 / linux and the
sealed gate compiles with a clean product tree.

Unresolved behavioral questions are listed in `oracle-questions.tsv`.
