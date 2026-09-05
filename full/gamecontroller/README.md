# GameController (Linux starting point)

This directory is a clean-room Linux port of Apple's public `GameController`
module, reconstructed from the sealed Xcode 26.1 iPhoneOS symbol graphs. It is
not wired into the shared guest package.

The isolated host gate (`bash tests/acceptance/test_host.sh`) compiles against
toolchain Foundation and Dispatch only. It is not evidence of an integrated
Linux guest stack with UIKit or CoreServices.

## Depth pass 2026-09

### Coverage ledger repair

The merge-refused revision `5790e784` reported **1102 implemented** / 9 deferred /
11 unavailable / 146 not-applicable, but every implemented row cited only the
file path `tests/agent/GameControllerRuntime.swift` (not
`test:full/gamecontroller/tests/agent/<File>Tests.swift#testName`).

After splitting the runtime probe into focused `*Tests.swift` functions and
reclassifying compile-only rows:

**1043 implemented** / **58 declared** / **10 deferred** / **11 unavailable** /
**146 not-applicable** (1268 IDs). Nondeferred 1101 remains well above the
large-partitioned floor of 127.

Top-5 implemented evidence (by row count):

1. `GCKeyCodeTests.swift#testHIDKeyCodeValues` — 138 (13.2%) — table-driven HID constants
2. `GCKeyNameTests.swift#testHIDKeyNameStrings` — 134 (12.8%) — table-driven `GCKey*` strings
3. `GCLiveInputTests.swift#testLiveInputAndPhysicalElementProtocols` — 99 (9.5%)
4. `GCSnapshotTests.swift#testSnapshotRoundTrip` — 98 (9.4%)
5. `GCEnumTests.swift#testEnumAndOptionSetMembers` — 86 (8.2%) — table-driven enums/option-sets

No non-enum / non-constant test exceeds 9.5% of implemented rows (40% cap would
be 417). `UIScene.ConnectionOptions.gameControllerActivationContext` moved from
a false `implemented` to **deferred** (UIKit overlay). Protocol witnesses with
no public instance (`GCSwitchElement`, `GCPhysicalInputSource`) and typealiases
are **declared**.

The input model is a **simulated device source**. This container has no
`/dev/input` (no `js*` joystick nodes), so Linux evdev/joystick reading is a
documented gap rather than a claimed HID stack.

### What the simulated source does

- `GCSimulatedInput.attach` publishes a non-snapshot `GCController` into
  `GCController.controllers()`, sets `GCController.current`, and posts
  `GCControllerDidConnect` / `GCControllerDidBecomeCurrent`.
- Detach posts `DidStopBeingCurrent` / `DidDisconnect`.
- `GCController.withExtendedGamepad()` / `withMicroGamepad()` remain software
  snapshots and stay off the connected list.
- `startWirelessControllerDiscovery(completionHandler:)` completes once,
  asynchronously, without publishing devices.
- DualSense / DualShock / Xbox / directional / extended / micro factories set
  `vendorName` and `productCategory`.
- `GCKeyboard.coalesced` and `GCMouse.current` / `mice()` come from the same
  registry. Key codes match HID usage values (`keyA` = 0x04, `escape` = 0x29).
- `GCMotion` attitude / rotationRate / acceleration / gravity /
  userAcceleration are written by `GCSimulatedInput.applyMotion`.
- `GCDevicePhysicalInput` / `GCControllerLiveInput` bind iOS 16 element
  collections from the profile, enqueue ordered states, and expose
  `nextInputState()` plus `inputStates` (`AsyncStream`) in enqueue order.
- `GCPhysicalInputProfile.elements` / `buttons` / `axes` / `dpads` are keyed by
  the `GCInput*` name constants. `capture()` copies; `setStateFromPhysicalInput`
  copies element values. `lastEventTimestamp` updates on `setValue`.
- Analog face/trigger buttons vs digital d-pad buttons: digital `setValue`
  snaps to 0/1; `isPressed` is `value > 0`. Axis/dpad coupling is dead-zone-free.
- `GCVirtualController.connect` is fail-closed; `setValue` / `setPosition` /
  `updateConfiguration` store configuration locally.
- `GCEventViewController` stays deferred until real UIKit is imported.

### Fail-closed boundaries

- Battery, light, and haptics remain `nil` on simulated devices. There is no
  physical accessory power, LED, or CoreHaptics engine.
  `GCDeviceHaptics.createEngine(withLocality:)` is **unavailable** (no
  `CHHapticEngine` type).
- Wireless discovery never invents HID devices.
- DualSense adaptive-trigger setters record software `mode` with
  `status == .unknown`.
- Snapshot `NSData` helpers use a documented little-endian layout, not Apple's
  packed ABI.
- `NSValue(GCPoint2:)` packs two IEEE-754 halves into a `UInt64` because Linux
  Foundation cannot encode Swift structs via `objCType`.
- UIKit overlays (`GCEventViewController`, `GCEventInteraction`,
  `GCGameControllerSceneDelegate`, `UIBezierPath` on virtual elements) remain
  omitted unless UIKit can be imported. SwiftUI `View` handlers are
  not-applicable.

## What is real (wave-2 baseline, still true)

- In-memory snapshot controllers from `GCController.withExtendedGamepad()` and
  `withMicroGamepad()`. Element `setValue` updates state synchronously and
  dispatches value-changed handlers on `GCDevice.handlerQueue`.
- HID `GCKeyCode` numeric values, `GCPoint2` helpers, DualSense software trigger
  `mode` recording, and `GCProductCategoryHID` on snapshots.
- When the real UIKit module is present: `GCEventViewController` subclasses
  `UIKit.UIViewController`, `GCEventInteraction` conforms to
  `UIKit.UIInteraction`, `GCGameControllerSceneDelegate` exposes
  `scene(_:didActivateGameControllerWith:)`, and
  `GCVirtualController.ElementConfiguration.path` is a `UIKit.UIBezierPath?`.
- When the real CoreServices module is present, GameController imports and
  touches it (`kUTTypeData`).

## Deferred / oracle

See `oracle-questions.tsv` for Apple-oracle probes (exact NSString payloads,
Apple snapshot binary layout, analog pressed threshold, DualSense hardware
status codes, coalesced-keyboard identity).

`tests/agent/GameControllerDependencyIdentity.swift` is a future clean-EC2
probe. That run must build guest Foundation, Dispatch, UIKit, and CoreServices
modules and dylibs first, compile GameController with their `-I` and `-L`
paths, link a client that imports those modules, pass real dependency values
through public APIs, run with `LD_LIBRARY_PATH`, print
`GAMECONTROLLER_DEPENDENCY_IDENTITY_OK` only after assertions, and confirm
`libGameController.dylib` was loaded. It is not executed by the isolated gate.

## Gates and markers

Expected standalone markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
GAMECONTROLLER_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=GameController dylib=libGameController.dylib
```
