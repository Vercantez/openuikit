# ARKit

Linux starting implementation of Apple's public `ARKit` Swift surface, reconstructed from the pinned Xcode 26.1 iPhoneOS symbol graphs. This directory is **not** wired into the shared guest package; that integration is a later central-review step.

## What is real

- `ARError` / `ARErrorDomain`, configuration classes, `ARSession`, anchors, frames, cameras, raycast queries, skeletons, reference images/objects, world maps, and coaching overlay **types** compile into `libARKit.dylib`.
- `ARConfiguration.isSupported` and every concrete subclass report **`false`**.
- `ARSession.run(_:options:)` stores the requested configuration, does not start tracking, leaves `currentFrame` nil, and notifies the delegate with `ARError.unsupportedConfiguration` (code 100, domain `com.apple.arkit.error`).
- Raycasts, tracked raycasts, world-map export, reference-object creation, high-resolution capture, geo availability, and reference-image validation fail closed (empty results, `nil`, or typed `ARError`).
- User-created `ARAnchor` values can be added and removed locally. They never appear in a live frame because no frame is produced.
- `ARCoachingOverlayView` is an `NSObject` stand-in (no UIKit). `isActive` stays `false`.
- Option sets, blend-shape locations, skeleton joint names, and tracking enumerations are source-compatible constants.

## Fail-closed boundaries

Linux has no TrueDepth/LiDAR camera, IMU world tracking, geo localization, or ARKit privacy prompts. This module **does not** invent camera images, plane detections, face meshes, body skeletons, world maps, or collaboration data.

Deferred until SceneKit, SpriteKit, Metal, AVFoundation, CoreVideo, CoreLocation, Vision, and UIKit are on the compile graph:

- `ARSCNView`, `ARSKView`, and their delegates
- `ARSCNFaceGeometry` / `ARSCNPlaneGeometry` / `SCNDebugOptions`
- Metal matte generation and geometry GPU buffers
- `CVPixelBuffer` / `AVCapture*` / `CMSampleBuffer` members
- `CLLocationCoordinate2D` geo-anchor initializers
- UIKit orientation projection helpers

## simd stand-in

Darwin `import simd` is unavailable on this host. `simd_float3`, `simd_float4x4`, and `simd_float3x3` in this module are portable stand-ins so ARKit signatures can compile. They are not extra Apple ARKit symbols.

## Tests

`tests/agent/ARKitRuntime.swift` exercises unsupported configurations, fail-closed `ARSession.run`, empty raycasts, error codes, option sets, blend shapes, and coaching inactivity, then prints `ARKIT_AGENT_RUNTIME_OK`.

Run:

```sh
bash tests/acceptance/test_host.sh
```
