# TouchController (Linux starting point)

This directory is a clean-room Linux port of Apple's public `TouchController`
module, reconstructed from the sealed Xcode 26.1 iPhoneOS symbol graphs. It
produces module `TouchController` and `libTouchController.dylib`. It is not
wired into the shared guest package.

The isolated host gate (`bash tests/acceptance/test_host.sh`) compiles against
toolchain Foundation only. UIKit, Metal, MetalKit, CoreGraphics, and
GameController are not Swift modules on this host. This port does **not**
ship lookalike substitutes for those types.

Environment:

`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`

`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`). `swiftc` is
Swift 6.2.4 / linux and the sealed gate compiles with a clean product tree.
The active Cursor Build is `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21`
rather than campaign seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`.
Starting commit `26f5086c5b31ba816742f18d3096152cd32280f4` matched.

## What is real

- Integer enums use the pinned `dotnet/macios` `[Native]` declaration order:
  `TCColliderShape`, `TCControlLayoutAnchor`,
  `TCControlLayoutAnchorCoordinateSystem`, `TCThrottle.Orientation`,
  `TCControlLabel.Role`, and the nested `TCControlContents` shape/direction
  enumerations, including `!=`, `hashValue`, `hash(into:)`, and
  `init(rawValue:)`.
- `TCControlLabel` presets use the sibling GameController `GCInput*` strings
  (`"Button A"`, `"Left Thumbstick"`, `"Direction Pad"`, …). Custom
  `init(name:role:)` stores both fields. Presets are stable singletons.
- Descriptors are mutable `NSObject` value holders with documented Linux
  defaults (relative/center for buttons, bottom-left dpad/thumbstick, vertical
  snapping throttle, `sampleCount == 1`).
- Layout resolves `position` from parent size, control size, anchor, and
  offset. `absolute` offset is points; `relative` offset is a fraction of
  parent size. Colliders: axis-aligned rect, circle inscribed in the box,
  left half, right half.
- `TCTouchController` add/remove, typed collections, z-index hit testing,
  multi-index touch routing, switch toggle-on-release-inside, throttle
  `baseValue` clamp to `[0, 1]`, and a conventional
  `automaticallyLayoutControls(for:)` packing are real in-memory state
  machines.
- Content factories return CPU placeholders with the requested `CGSize`.
  They do not rasterize SF Symbols or upload GPU textures.

## Fail-closed boundaries

- `TCTouchController.isSupported` is `false`. `connect()` does not set
  `isConnected` and does not publish a `GCController`.
- Metal-typed APIs (`device`, `render(using:)`, pixel formats, `MTLTexture`
  image initializers), `MTKView` descriptor initializers, `CGImage`/`CGColor`
  members, and `UIImage` initializers are **unavailable**. Those modules are
  not isolated-host dependencies, and this framework does not invent
  substitutes.
- System-image factories succeed as size placeholders only; they do not
  claim a rendered glyph.

## Depth pass 2026-09

Exact public IDs: **302**. Nondeferred floor for `medium-full` is 151.

- Implemented **283** / declared **0** / unavailable **19** / deferred **0**.
- Top-5 implemented evidence distribution (283 rows):
  1. `TCEnumTests.swift#testEnumRawValuesAndHashable` — 67 (table-driven enums)
  2. `TCDescriptorTests.swift#testDirectionPadDescriptorDefaultsAndMutation` — 21
  3. `TCControlLabelTests.swift#testControlLabelPresets` — 18
  4. `TCDirectionPadTests.swift#testAddDirectionPadCopiesDescriptor` — 17
  5. `TCDescriptorTests.swift#testThrottleDescriptorDefaultsAndMutation` — 17
- Enum/option-set members share one table-driven value test. No other
  single test exceeds 40% of the remaining implemented rows (largest
  remaining citation is 21 / 216 ≈ 10%).
- Gate: `bash full/touchcontroller/tests/acceptance/test_host.sh`.
