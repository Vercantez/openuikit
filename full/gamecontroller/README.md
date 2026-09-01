# GameController (Linux starting point)

This directory is a clean-room Linux port of Apple's public `GameController`
module, reconstructed from the sealed Xcode 26.1 iPhoneOS symbol graphs. It is
not wired into the shared guest package.

## What is real

- In-memory snapshot controllers from `GCController.withExtendedGamepad()` and
  `withMicroGamepad()`. Elements accept `setValue`, fire value-changed handlers,
  and can be captured or serialized through the portable snapshot helpers.
- Deterministic constants: input names, product categories, notification names,
  HID `GCKeyCode` values, haptics locality tokens, and `GCPoint2` helpers.
- The classic profile types (`GCGamepad`, `GCExtendedGamepad`, `GCMicroGamepad`,
  DualShock / DualSense / Xbox subclasses), keyboard/mouse types, physical-input
  protocols, and `GCPhysicalInputElementCollection`.

## Fail-closed boundaries

- `GCController.controllers()`, `GCController.current`, `GCKeyboard.coalesced`,
  and `GCMouse.current` / `mice()` are empty. This host has no HID device graph.
- `startWirelessControllerDiscovery` completes immediately without publishing
  devices.
- `GCVirtualController.connect` returns an error. Linux has no GameController
  HID injection service.
- `GCDeviceHaptics.supportedLocalities` is empty and there is no CoreHaptics
  engine.
- DualSense adaptive-trigger setters record the requested software `mode` but
  leave `status == .unknown` and do not claim a physical effect.
- `GCMotion` reports no IMU (`hasAttitude` and related flags are `false`).
- SwiftUI view helpers, typed `NotificationCenter.MessageIdentifier` overlays,
  UIKit scene activation, and `UIBezierPath` virtual-controller chrome are not
  available on this Linux Foundation/UIKit-less toolchain.

## Deferred / oracle

See `oracle-questions.tsv` for Apple-oracle probes (exact NSString payloads,
Apple snapshot binary layout, analog pressed threshold, DualSense hardware
status codes).
