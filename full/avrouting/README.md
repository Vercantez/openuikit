# AVRouting

Linux starting point for Apple's public `AVRouting` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph. Isolated host-gate
success is not AirPlay, Bluetooth route discovery, a routing-picker UI,
or Darwin playback arbitration.

## Depth pass 2026-09

This is a fresh seed: **38 exact public identifiers**, floor 31
nondeferred (`ceil(80% of 38)`). Every identifier is `implemented` with
a focused top-level synchronous `func test*()`. Enum cases and
synthesized `Hashable` / `Equatable` / `init(rawValue:)` members share
one table-driven value test.

Coverage after this pass: **38 implemented / 0 declared / 0 deferred /
0 unavailable / 0 not-applicable**.

Top-5 implemented evidence distribution (38 implemented rows; enum
family sharing is allowed; no other test exceeds 40% of the remaining
30 rows):

| rows | share | evidence |
| ---: | ---: | --- |
| 8 | enum family | `AVCustomRoutingEventReasonTests.swift#testEventReasonRawValuesAndHashable` |
| 1 | 3.3% of remaining | `AVCustomRoutingControllerTests.swift#testCustomRoutingControllerAuthorizedRoutesDidChangeName` |
| 1 | 3.3% of remaining | `AVCustomDeviceRouteTests.swift#testCustomDeviceRouteIsNSObjectSubclass` |
| 1 | 3.3% of remaining | `AVCustomDeviceRouteTests.swift#testCustomDeviceRouteBluetoothIdentifierStored` |
| 1 | 3.3% of remaining | `AVCustomDeviceRouteTests.swift#testCustomDeviceRouteNetworkEndpointAlwaysNil` |

The remaining twenty-six implemented rows each have their own test
(action-item / partial-IP / event / controller / delegate / playback
arbiter).

Environment: `swiftc` reports Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` did
not emit `CURSOR_SWIFT_ENVIRONMENT_OK` because
`scratch/ladder-corpus/focus-ios` is absent on this VM. The sealed gate
compiles with a clean product tree (`products=clean`). Active Cursor
Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`343270ce44481a5ae11b87a6e0713e396ada1ef2` matched.

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token, not printed by the sealed framework gate.

## What is real

- `AVCustomRoutingEventReason` is an `Int` enum: `activate = 0`,
  `deactivate = 1`, `reactivate = 2` (pinned macios Native order).
  Synthesized `==` / `!=`, `hashValue`, `hash(into:)`, and
  `init?(rawValue:)` are exercised.
- `AVCustomRoutingPartialIP` copies `address` and `mask` `Data` at
  `init(address:mask:)`. No length validation is invented.
- `AVCustomRoutingActionItem.overrideTitle` and `.type` round-trip.
  Isolated-host `UTType` is an identifier-string overlay; it compiles
  out when UniformTypeIdentifiers is importable.
- `AVCustomDeviceRoute.bluetoothIdentifier` is stored when a Linux-only
  initializer supplies a `UUID`. `networkEndpoint` is always `nil`.
- `AVCustomRoutingController.knownRouteIPs` and `customActionItems`
  are process-local arrays. `setActive` / `isRouteActive` keep a
  process-local active set by object identity. `authorizedRoutes` is
  always empty. `delegate` is weak.
- `AVCustomRoutingController.authorizedRoutesDidChange` is
  `NSNotification.Name("AVCustomRoutingControllerAuthorizedRoutesDidChangeNotification")`.
- `AVRoutingPlaybackArbiter.shared()` is a singleton. The preferred
  participant pointer is weak.

## Fail-closed boundaries

- Linux never presents a routing picker and never talks to an AirPlay /
  Bluetooth / media-routing daemon.
- `authorizedRoutes` is always `[]`. `setActive` does not invent
  authorization or route audio.
- `networkEndpoint` is always `nil`.
- The controller never posts `authorizedRoutesDidChange` and never
  invokes the delegate. Tests call delegate methods directly.
- `AVRoutingPlaybackArbiter` does not change external-playback
  ownership.

## Still deferred / unobserved

See `oracle-questions.tsv` for Darwin `UTType` defaults, Network
endpoint identity, `setActive` authorization gating and notification
queues, the async-vs-completion-handler `handle` overlay, PartialIP
validation, playback-participant class bounds, and hidden TBD
notification names.

Focused checks live in `tests/agent/*Tests.swift` as top-level
`func test*()`. The sealed gate prints `AVROUTING_AGENT_RUNTIME_OK`
after calling each cited test once.

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AVRouting lane=leaf-full symbols=38
FRAMEWORK_FANOUT_REFERENCE_OK
AVROUTING_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVRouting dylib=libAVRouting.dylib
```

Run `bash full/avrouting/tests/acceptance/test_host.sh` from the repo
root. Keep generated products out of the tree.
