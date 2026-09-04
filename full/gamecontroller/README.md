# GameController (Linux starting point)

This directory is a clean-room Linux port of Apple's public `GameController`
module, reconstructed from the sealed Xcode 26.1 iPhoneOS symbol graphs. It is
not wired into the shared guest package.

The isolated host gate (`bash tests/acceptance/test_host.sh`) compiles against
toolchain Foundation and Dispatch only. It is not evidence of an integrated
Linux guest stack with UIKit or CoreServices.

## What is real

- In-memory snapshot controllers from `GCController.withExtendedGamepad()` and
  `withMicroGamepad()`. Element `setValue` updates state synchronously and
  dispatches value-changed handlers on `GCDevice.handlerQueue`.
- Wireless discovery and `GCVirtualController.connect` completions are
  delivered asynchronously, exactly once, on an internal service queue. Linux
  still publishes no HID devices and virtual connect is fail-closed.
- HID `GCKeyCode` numeric values (`keyA` = 0x04, `escape` = 0x29), `GCPoint2`
  make/equal/zero helpers, DualSense software trigger `mode` recording, empty
  `controllers()`, and `GCProductCategoryHID` wiring on snapshot devices.
- When the real UIKit module is present: `GCEventViewController` subclasses
  `UIKit.UIViewController`, `GCEventInteraction` conforms to
  `UIKit.UIInteraction`, `GCGameControllerSceneDelegate` exposes
  `scene(_:didActivateGameControllerWith:)`, and
  `GCVirtualController.ElementConfiguration.path` is a `UIKit.UIBezierPath?`.
- When the real CoreServices module is present, GameController imports and
  touches it (`kUTTypeData`).

## Fail-closed boundaries

- `GCController.controllers()`, `GCController.current`, `GCKeyboard.coalesced`,
  and `GCMouse.current` / `mice()` are empty. This host has no HID device graph.
- `startWirelessControllerDiscovery` completes without publishing devices.
- `GCVirtualController.connect` returns an error. Linux has no GameController
  HID injection service.
- `GCDeviceHaptics.supportedLocalities` is empty and there is no CoreHaptics
  engine.
- DualSense adaptive-trigger setters record the requested software `mode` but
  leave `status == .unknown` and do not claim a physical effect.
- `GCMotion` reports no IMU (`hasAttitude` and related flags are `false`).
- UIKit overlays are omitted unless UIKit can be imported. They are not
  replaced with `NSObject` or a module-local `UIViewController` /
  `UIInteraction` / `UIScene` / `UIBezierPath`.
- Snapshot `NSData` helpers round-trip a Linux-portable layout; that is not
  Apple's packed ABI.
- `GCInput*` / `GCKey*` / product-category / notification raw strings are
  compiled declarations without Apple payload evidence.

## Deferred / oracle

See `oracle-questions.tsv` for Apple-oracle probes (exact NSString payloads,
Apple snapshot binary layout, analog pressed threshold, DualSense hardware
status codes).

`tests/agent/GameControllerDependencyIdentity.swift` is a future clean-EC2
probe. That run must build guest Foundation, Dispatch, UIKit, and CoreServices
modules and dylibs first, compile GameController with their `-I` and `-L`
paths, link a client that imports those modules, pass real dependency values
through public APIs, run with `LD_LIBRARY_PATH`, print
`GAMECONTROLLER_DEPENDENCY_IDENTITY_OK` only after assertions, and confirm
`libGameController.dylib` was loaded. It is not executed by the isolated gate.
