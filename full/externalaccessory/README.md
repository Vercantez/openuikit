# ExternalAccessory (Linux starting point)

This directory is a fail-closed portable `ExternalAccessory` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

Coverage: **122 implemented / 2 declared / 124 total** (fully nondeferred,
above the medium-full floor of 62).

## What is real

- `EABluetoothAccessoryPickerError` / `EABluetoothAccessoryPickerErrorDomain`
  with sequential `NSInteger` codes corroborated by the pinned dotnet-macios
  bindings and API-digester child order (`alreadyConnected = 0` …
  `resultFailed = 3`). Typed construction, `userInfo`, equality, hashing,
  `NSError` bridging, and `~=` matching are exercised.
- Wi-Fi unconfigured accessory enums with documented raw values
  (`EAWiFiUnconfiguredAccessoryBrowserState` 0…3,
  `EAWiFiUnconfiguredAccessoryConfigurationStatus` 0…2) and
  `EAWiFiUnconfiguredAccessoryProperties` bit flags (`1 << 0/1/2`) plus
  OptionSet/SetAlgebra witnesses.
- Notification names and user-info keys using TBD export names
  (`EAAccessoryDidConnectNotification`, `EAAccessoryKey`, …).
  `EAConnectionIDNone` is `0`.
- `EAAccessoryManager.shared()` is a singleton. `connectedAccessories` is
  empty. Local-notification registration never posts connect/disconnect
  events. The Bluetooth picker fail-closes with `resultFailed` on the
  caller thread.
- `EASession.init(accessory:forProtocol:)` always returns `nil` (no MFi
  session daemon, no invented streams).
- `EAWiFiUnconfiguredAccessoryBrowser` searching fail-closes to
  `.wiFiUnavailable` and configuration fail-closes with `.failed`.
  `unconfiguredAccessories` stays empty.

## Fail-closed boundaries

Linux has no External Accessory daemon, MFi protocol transport, Bluetooth
accessory picker UI, Wireless Accessory Configuration daemon, or UIKit
configuration sheet.

- No accessory is ever connected. `connectedAccessories` is `[]`.
- Session I/O streams are never vended. Public session init returns `nil`.
- The Bluetooth picker does not present UI and does not succeed.
- WAC search never reports found/removed accessories.
- `UIViewController` is a typealias to `NSObject` because UIKit is not a
  declared dependency. Configuration UI is ignored.
- Delegate-queue hops are unobserved. Fail-closed callbacks are delivered
  synchronously so the sealed runner (no run loop) can observe them.

Apple's `-init` is unsupported on `EAAccessory`, `EAAccessoryManager`, and
`EASession`. Tests construct accessory/session records through
`@_spi(OpenUIKitHost)` without registering them as connected hardware.

## Depth pass 2026-09

Fresh seed: no prior sources, coverage, or agent tests. After this pass:
**122 implemented / 2 declared / 0 deferred**.

The two `declared` rows are
`EAWiFiUnconfiguredAccessoryBrowserDelegate.accessoryBrowser(_:didFindUnconfiguredAccessories:)`
and `didRemoveUnconfiguredAccessories`. The browser never invents WAC
discoveries, so those required protocol methods are declared and unused.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 21 | `EAWiFiEnumTests.swift#testEAWiFiUnconfiguredAccessoryPropertiesAlgebra` |
| 12 | `EABluetoothAccessoryPickerErrorTests.swift#testEABluetoothAccessoryPickerErrorCodes` |
| 11 | `EAAccessoryManagerTests.swift#testEAAccessoryHostPropertyStorage` |
| 9 | `EAWiFiEnumTests.swift#testEAWiFiUnconfiguredAccessoryBrowserStateRawValues` |
| 9 | `EABluetoothAccessoryPickerErrorTests.swift#testEABluetoothAccessoryPickerErrorConstruction` |

`testEABluetoothAccessoryPickerErrorCodes` and the Wi-Fi enum/member tests
are table-driven enum/option-set value tests. The algebra test covers
SetAlgebra/OptionSet witnesses for one option-set type. The remaining
implemented rows stay well under the 40% bulk-relabel bound.

The sealed host gate was run as
`bash full/externalaccessory/tests/acceptance/test_host.sh` and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ExternalAccessory lane=medium-full symbols=124
FRAMEWORK_FANOUT_REFERENCE_OK
EXTERNALACCESSORY_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ExternalAccessory dylib=libExternalAccessory.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). That campaign token
is the host-inventory stamp; the sealed framework gate prints the four lines
above. The sealed gate was not weakened.
