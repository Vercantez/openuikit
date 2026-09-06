# DeviceDiscoveryExtension

Linux starting point for Apple's public `DeviceDiscoveryExtension` module,
reconstructed from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated
host-gate success is not integrated Linux discovery success, and this module
is not wired into the shared guest package.

Coverage: **173 implemented / 0 declared / 0 deferred / 173 total**
(fully nondeferred, above the leaf-full floor of 139).

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**173 implemented / 0 declared / 0 deferred**.

Top-5 implemented evidence distribution:

| Citations | Share | Evidence |
| ---: | ---: | --- |
| 19 | 11.0% | `DDErrorTests.swift#testDDErrorCodeRawValues` |
| 9 | 5.2% | `DDErrorTests.swift#testDDErrorInitUserInfoAndCustomNSError` |
| 8 | 4.6% | `DDDeviceCategoryTests.swift#testDDDeviceCategoryRawValues` |
| 6 | 3.5% | `DDDeviceStateTests.swift#testDDDeviceStateRawValues` |
| 5 | 2.9% | `DDDeviceEventTests.swift#testDDDeviceEventTypeRawValues` |

`testDDErrorCodeRawValues` is a table-driven enum-member and static `DDError.*`
code test (including the C `DDErrorDomain` token family). Category, state, and
event-type tests are table-driven enum value tests. No non-enum test is cited
by more than 9 implemented rows (well under 40% of the remaining rows).

## What is real

- `DDError` / `DDErrorDomain` / `DDError.Code` with the NS_ERROR_ENUM integers
  corroborated by pinned dotnet-macios (`success = 0`, `unknown = 350000` …
  `permission = 350006`). `next` is implemented as `350007` (C auto-increment);
  macios skipped that sentinel — see oracle questions. Typed construction,
  `userInfo`, equality, hashing, `NSError` bridging, and `~=` matching are
  exercised. Foundation's default `hashValue` witness traps (`__HALT`) on this
  toolchain, so Hashable members are provided locally.
- Nested device enums with documented raw values: `DDDevice.Category` (0…6),
  `MediaPlaybackState` (0…2), `Protocol` (0…1), `WiFiAwareServiceRole`
  (subscriber = 10, publisher = 20), top-level `DDDeviceState` (0 / 10 / 20 /
  25 / 30), and `DDDeviceEvent.EventType` (0 / 40 / 41 / 42).
- `DDDeviceSupports` option-set algebra with bits `1<<1`, `1<<2`, `1<<3`.
- `DDDeviceProtocolString` newtype with `invalid` / `dial` constants (raw
  strings are the C export names until Darwin bytes are observed).
- `ToString` helpers return the ObjC enumerator spelling from the pinned USR.
- `DDDevice` stores initializer arguments and every public property. Networking
  fields (`networkEndpoint`, `txtRecord`) are retained locally.
- `DDDeviceEvent` retains event type and the same `DDDevice` instance.
- `DDDiscoverySession.report` appends events in order for host observation
  (`@_spi(OpenUIKitHost) reportedEvents`) and does not talk to a daemon.
- `DDDiscoveryExtension` default `didReceiveEvent` is a no-op. Default
  `configuration` wraps `self`. `accept(connection:)` returns `false`.

Clients outside this module cannot write `DDDevice.Protocol` (Swift reserves
`.Protocol` for metatypes). The nested type still exists; `DDDeviceProtocol`
is a same-module typealias for Linux call sites.

## Fail-closed boundaries

Linux has no DeviceDiscovery daemon, accessory-setup UI, DIAL stack, Wi-Fi
Aware, Bluetooth HID pairing, discovery entitlement, or NSXPC extension host.

- `startDiscovery` on the host fixture records a call and reports no devices.
- `accept(connection:)` always returns `false`.
- Assigning `networkEndpoint` / `txtRecord` / `ssid` does not browse, pair,
  advertise, or open a Network path.
- Isolated-host lookalikes for `UTType`, `NWEndpoint`, `NWTXTRecord`,
  `AppExtension`, `AppExtensionConfiguration`, and `NSXPCConnection` compile
  out when those modules are on the link line. They are not ports of those
  frameworks.
- `DDErrorOutType` is `UnsafeMutablePointer<NSError?>` because
  `AutoreleasingUnsafeMutablePointer` does not exist on Linux Swift.

## Environment and gate

`git rev-parse HEAD` at the start of this seed was
`cbb368eeea236bbc0479fefa599190972ac8cfca`. `swiftc` is Swift 6.2.4, target
`x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
because `scratch/ladder-corpus/focus-ios` is absent from this snapshot.
The sealed framework gate does not require that checkout. The pod booted
from `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` rather than
campaign `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree (`products=clean`).

`bash full/devicediscoveryextension/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=DeviceDiscoveryExtension lane=leaf-full symbols=173
FRAMEWORK_FANOUT_REFERENCE_OK
DEVICEDISCOVERYEXTENSION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=DeviceDiscoveryExtension dylib=libDeviceDiscoveryExtension.dylib
```
