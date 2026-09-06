# AccessorySetupKit (Linux starting point)

This directory is a fail-closed portable `AccessorySetupKit` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

Coverage: **277 implemented / 0 declared / 277 total** (fully nondeferred,
above the medium-full floor of 139).

## What is real

- `ASError` / `ASErrorDomain` with the pinned dotnet-macios `NS_ERROR_ENUM`
  codes (`success = 0`, `unknown = 1`, `activationFailed = 100`,
  `connectionFailed = 150`, `discoveryTimeout = 200`, `extensionNotFound = 300`,
  `invalidated = 400`, `invalidRequest = 450`, `pickerAlreadyActive = 500`,
  `pickerRestricted = 550`, `userCancelled = 700`, `userRestricted = 750`).
  Typed construction, `userInfo`, equality, hashing, `NSError` bridging, and
  `~=` matching are exercised.
- Session event, accessory state, discovery range, and Wi-Fi Aware role enums
  with those same `[Native]` raw values, plus `Hashable` / `Equatable`.
- Option sets: `ASAccessory.RenameOptions.ssid = 1 << 0`,
  `SupportOptions` bits `1 << 1/2/3`, picker setup bits `1 << 0/1/2`, and
  `ASPickerDisplaySettings.Options.filterDiscoveryResults = 1 << 0`, including
  OptionSet/SetAlgebra witnesses.
- `ASBluetoothCompanyIdentifier` (`UInt16` newtype) and
  `ASPickerDisplaySettings.DiscoveryTimeout` (`TimeInterval` newtype) with
  named short/medium/long/unbounded constants.
- `ASDiscoveryDescriptor` property storage plus local manufacturer/service
  data mask matching, name-substring compare, and SSID/prefix matching.
- `ASPropertyCompareString` stores string + `NSString.CompareOptions`.
- `ASAccessorySession` local activate → `.activated`, invalidate →
  `.invalidated`. `accessories` is always empty.

## Fail-closed boundaries

Linux has no Accessory Setup daemon, Bluetooth/Wi-Fi Aware picker UI,
pairing entitlement, or UIKit image pipeline.

- `showPicker` / `updatePicker` / `finishPickerDiscovery` complete with
  `ASError.pickerRestricted` after activate, or `ASError.invalidated` if the
  session is idle or already invalidated.
- `finishAuthorization`, `failAuthorization`, `removeAccessory`,
  `renameAccessory`, and `updateAuthorization` fail with `invalidRequest`
  (no picker-authorized accessory exists).
- No accessory is ever discovered or authorized. `accessories` is `[]`.
- `UIImage` and `CBUUID` are typealiases to `NSObject` because UIKit and
  CoreBluetooth are not declared dependencies.
- Event-handler queue hops are unobserved. Fail-closed and activate events
  are delivered synchronously so the sealed runner (no run loop) can observe
  them.

Apple's `-init` is unsupported on `ASAccessory` and `ASAccessoryEvent`.
Tests construct records through `@_spi(OpenUIKitHost)`.

## Depth pass 2026-09

Fresh seed: no prior sources, coverage, or agent tests. After this pass:
**277 implemented / 0 declared / 0 deferred**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 21 | `ASOptionSetTests.swift#testASAccessoryRenameOptionsAlgebra` |
| 21 | `ASOptionSetTests.swift#testASAccessorySupportOptionsAlgebra` |
| 21 | `ASOptionSetTests.swift#testASPickerDisplayItemSetupOptionsAlgebra` |
| 21 | `ASOptionSetTests.swift#testASPickerDisplaySettingsOptionsAlgebra` |
| 19 | `ASEnumTests.swift#testASAccessoryEventTypeRawValues` |

The four 21-citation tests are OptionSet/SetAlgebra witnesses for one type
each. `testASAccessoryEventTypeRawValues` is a table-driven enum/member value
test. Remaining implemented rows stay well under the 40% bulk-relabel bound.

The sealed host gate was run as
`bash full/accessorysetupkit/tests/acceptance/test_host.sh` and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AccessorySetupKit lane=medium-full symbols=277
FRAMEWORK_FANOUT_REFERENCE_OK
ACCESSORYSETUPKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AccessorySetupKit dylib=libAccessorySetupKit.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). That campaign token is
the host-inventory stamp; the sealed framework gate prints the four lines
above. The sealed gate was not weakened.
