# NearbyInteraction (Linux starting point)

This directory is a fail-closed portable `NearbyInteraction` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

Coverage: **158 implemented / 0 declared / 0 deferred / 158 total**
(fully nondeferred, above the leaf-full floor of 127).

## What is real

- `NIError` / `NIErrorDomain` / `NIError.Code` with the NS_ERROR_ENUM integers
  corroborated by the pinned dotnet-macios bindings (`unsupportedPlatform =
  -5889` … `activeExtendedDistanceSessionsLimitExceeded = -5880`). Typed
  construction, `userInfo`, equality, hashing, `NSError` bridging, and `~=`
  matching are exercised.
- DL-TDoA, removal-reason, and vertical-direction enums with documented raw
  values, plus `NIAlgorithmConvergenceStatus` and `Reason` (string raw values
  matching the TBD-exported `NIAlgorithmConvergenceStatusReason*` names).
- Configuration objects store and copy their fields: peer tokens, camera /
  extended-distance flags, DL-TDoA `networkIdentifier`. `NSSecureCoding`
  round-trips those value fields.
- `NISession` is constructible. `isSupported` is `false`. `deviceCapabilities`
  and discovery-token capabilities are all `false`. `run(_:)` fail-closes
  with `unsupportedPlatform` on the caller thread, then clears
  `configuration`. `worldTransform(for:)` returns `nil`. `pause()` /
  `invalidate()` / `setARSession(_:)` do not invent ranging.

## Fail-closed boundaries

Linux has no U1/U2 radio, Nearby Interaction daemon, Nearby Interaction
entitlement, privacy prompt, or ARKit world-tracking.

- `NISession.run(_:)` never calls `sessionDidStartRunning`, never emits
  nearby objects or DL-TDoA measurements, and never claims a peer is present.
- Accessory `init(data:)` / `init(accessoryData:bluetoothPeerIdentifier:)`
  always throw `invalidConfiguration`. The Apple accessory blob is
  unobserved; this port does not invent a parser.
- `setARSession` accepts `NSObject` because ARKit is not a declared
  dependency. Camera assistance stays off.
- Delegate-queue hops are unobserved. Fail-closed invalidation is delivered
  synchronously so the sealed runner (no run loop) can observe it.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**158 implemented / 0 declared / 0 deferred**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 23 | `NearbyInteractionErrorTests.swift#testNIErrorCodes` |
| 13 | `NearbyInteractionConvergenceTests.swift#testNIAlgorithmConvergenceStatusReasonRawValues` |
| 10 | `NearbyInteractionEnumTests.swift#testNINearbyObjectVerticalDirectionEstimateRawValues` |
| 10 | `NearbyInteractionDelegateTests.swift#testNISessionDelegateCallbacks` |
| 9 | `NearbyInteractionObjectTests.swift#testNIDLTDOAMeasurementProperties` |

`testNIErrorCodes` is a table-driven enum-member and static `NIError.*`
code test. `testNIAlgorithmConvergenceStatusReasonRawValues` and
`testNINearbyObjectVerticalDirectionEstimateRawValues` are table-driven
enum/constant value tests. Delegate and construction tests cover distinct
non-enum families and stay well under the 40% bulk-relabel bound.

The sealed host gate was run as `bash full/nearbyinteraction/tests/acceptance/test_host.sh`
and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=NearbyInteraction lane=leaf-full symbols=158
FRAMEWORK_FANOUT_REFERENCE_OK
NEARBYINTERACTION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=NearbyInteraction dylib=libNearbyInteraction.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). That campaign token
is the host-inventory stamp; the sealed framework gate prints the four lines
above.
