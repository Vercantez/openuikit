# Vision (Linux starting point)

This is a clean-room Linux starting implementation of Apple's public `Vision`
module, seeded from the Xcode 26.1 iPhoneOS symbol graph. It is not Apple
behavioral parity, it is not wired into the shared guest package, and a
passing isolated host gate is not integrated Linux success.

## What is real

- Geometry: `VNPoint`, `VNVector`, `VNCircle`, and the `VNImage*` /
  `VNNormalized*` mapping helpers (including ROI and face-landmark projection
  through `SIMD2<Float>`). `VNGeometryUtils.boundingCircle(for:)` is a true
  minimum enclosing circle (pairs + acute circumcircles), not a bounding-box
  approximation.
- Configuration surface used by the 20-app corpus: `VNImageRequestHandler` /
  `VNSequenceRequestHandler` (`Data` / `URL` only), barcode/face/rectangle/text
  /saliency requests, and surrounding observation constructors.
- Fail-closed handler `perform`: empty data, missing URL, cancel, unsupported
  revision, and missing Apple models throw typed `VNError` cases after
  invoking completion handlers.

## Fail-closed / unobserved ABI

`VNErrorDomain` is a documented Linux-only fallback (`declared`). `VNErrorCode`
cases that the runtime actually throws are `implemented` as fail-closed case
identity; integer payloads are not claimed as Apple `VNError.h` ABI.
`VNErrorCode.turiCoreErrorCode` is omitted (deferred) rather than assigned
an invented `10000`.

`CGImage` / `CIImage` / `CVPixelBuffer` / `CMSampleBuffer` handler overloads
are absent, not substituted with module-local types of those names. Core ML,
video processing, 3D pose, and pixel-buffer accessors remain unavailable.

## Tests

- `tests/agent/VisionRuntime.swift` is the isolated-gate runtime: geometry,
  MEC cases, identifier tables, observation constructors, request
  configuration, and fail-closed `perform`. Prints `VISION_AGENT_RUNTIME_OK`.
- `tests/agent/VisionDependencyIdentity.swift` is a future EC2 client. That
  run must build guest CoreGraphics, CoreImage, and Foundation first, compile
  Vision against their `-I/-L` paths, link this file with `libVision.dylib`,
  pass real `CoreGraphics.CGPoint`/`CGRect` values through public observation
  APIs, keep deferred CIImage/CGImage handler overloads absent, run with
  `LD_LIBRARY_PATH`, and confirm `VISION_DEPENDENCY_IDENTITY_OK` plus that
  `libVision.dylib` is loaded. No local Docker.
