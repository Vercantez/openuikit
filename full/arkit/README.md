# ARKit

Linux starting implementation of Apple's public `ARKit` Swift surface, reconstructed from the pinned Xcode 26.1 iPhoneOS symbol graphs. This directory is **not** wired into the shared guest package; that integration is a later central-review step.

## What is real

- `ARError` / `ARErrorDomain` with documented numeric codes (100–107, 200–202, 300–304, 400–401, 500–501).
- Every `ARConfiguration` subclass stores its public properties and copies them via `NSCopying`. `isSupported` is **false** unless `ARKitTestHook.installSimulatedDevice()` is called. `supportedVideoFormats` stays empty.
- `ARSession.run(_:options:)` validates the configuration: unsupported → `ARError.unsupportedConfiguration` (100); simulated device with camera denied → `cameraUnauthorized` (103). Otherwise it drives the documented **simulated frame source** (`ARSimulatedFrameSource`): one deterministic frame per run/add/remove, camera look-at `(0, 1.2, 1.5) → origin`, intrinsics `fx=fy=640`, image `640×480`, optional horizontal plane of extent `(2, 0, 2)`.
- Delegate order per simulated frame: `session(_:didUpdate:)` frame, then `didAdd`, then `didUpdate` anchors, then `didRemove`.
- `ARCamera.projectionMatrix(for:viewportSize:zNear:zFar:)` is the pinhole OpenGL matrix from intrinsics (exact `2fx/w`, `2fy/h`, principal-point columns, `-(f+n)/(f-n)`, `-2fn/(f-n)`), times a Z orientation rotation. `viewMatrix(for:)` is that rotation times the rigid inverse of the camera transform.
- Legacy `hitTest` and `raycast` intersect simulated planes with the documented result types (`existingPlaneUsingExtent` / `UsingGeometry` clip to extent; `estimatedHorizontalPlane` is `y=0`).
- `ARAnchor` subclasses, `ARPlaneGeometry` (quad layout), `ARFaceGeometry`, skeletons, reference images/objects, coaching overlay, and SceneKit/SpriteKit view stand-ins compile into `libARKit.dylib`.
- `ARReferenceImage` can be built from the host `CGImage` stand-in with a physical width. Bundle loads stay fail-closed.

## Fail-closed boundaries

Linux has no TrueDepth/LiDAR camera, IMU world tracking, geo localization, or ARKit privacy prompts. Without the test hook, `run` never invents a frame. Even with the hook:

- `currentWorldMap` / world-map export → `invalidWorldMap`
- high-resolution capture, reference-object creation, collaboration, geo availability/location → typed `ARError`
- `ARSCNView` / `ARSKView` / `ARCoachingOverlayView` are `NSObject` stand-ins (no UIKit/SceneKit renderer). Hit-tests forward to the session frame; node maps return `nil`.
- Metal matte/geometry buffers are empty host objects, not GPU resources.
- `capturedImage` is an empty `CVPixelBuffer` stand-in, never camera pixels.
- `ARFaceGeometry(blendShapes:)` returns `nil` (no Apple face topology).
- `ARSkeleton.JointName(_: VNRecognizedPointKey)` returns `nil`.

## simd and host stand-ins

Darwin `import simd` is unavailable. `simd_float3` / `simd_float4x4` in this module are portable stand-ins. `UIInterfaceOrientation`, `CGImage`, `CGAffineTransform`, `CVPixelBuffer`, `CLLocationCoordinate2D`, Metal/SceneKit/SpriteKit/`AVCapture*` types are likewise host stand-ins so the sealed gate can compile the public surface without importing those modules. They are not extra Apple ARKit symbols.

## Tests

`tests/agent/ARKitRuntime.swift` exercises unsupported configurations, the simulated session/anchor/raycast path, projection/view matrices, `NSSecureCoding` for `ARAnchor`, SceneKit/SpriteKit stand-ins, and fail-closed I/O, then prints `ARKIT_AGENT_RUNTIME_OK`.

Run:

```sh
bash tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Wave-2 starting point was 526 implemented / 267 declared / 82 deferred. The first depth commit finished the session/configuration/anchor model with a documented simulated frame source, but merge review refused **874** `implemented` rows because evidence was a file path (`tests/agent/ARKitRuntime.swift`) rather than `test:full/arkit/tests/agent/<File>Tests.swift#testName`.

This repair split the runtime probe into 63 top-level synchronous `func test*()` functions across focused `*Tests.swift` files. Coverage is **874 implemented / 1 declared / 0 deferred** (875 IDs). The remaining declared row is `ARGeometrySource`'s overlapping `UInt8` subscript (`source:full/arkit/ARGeometry.swift#ARGeometrySource`).

Top-5 `implemented` evidence citations:

1. `testBlendShapeLocationValues` — 57 (table-driven C blend-shape constants)
2. `testARErrorCodesAndDomain` — 48 (table-driven `ARError.Code` / domain constants)
3. `testOtherConfigurationCopies` — 42 (non-world configuration property/copy family)
4. `testGeoTrackingEnumCases` — 32 (geo state/accuracy/reason enums)
5. `testSpecializedAnchors` — 30 (image/object/face/geo/mesh/probe/app-clip anchors)

No non-constant test is cited by more than 42 of 608 remaining implemented rows (6.9%, under the 40% bulk-relabel cap). `ARKitRuntime.swift` concatenates the suite so the sealed schema-v1 gate still prints `ARKIT_AGENT_RUNTIME_OK`.

Exact gate markers from `bash full/arkit/tests/acceptance/test_host.sh` on this Linux host (Swift 6.2.4):

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
ARKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ARKit dylib=libARKit.dylib
```

Unresolved behavioral questions (see `oracle-questions.tsv`): Apple delegate queue/async timing, exact `ARSCNDebugOptions` bit values, projection orientation convention versus a live iPhone camera buffer, and whether `getCurrentWorldMap` on a tracking session without a saved map is `invalidWorldMap` or another code.
