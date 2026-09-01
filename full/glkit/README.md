# GLKit Linux starting point

This directory is a clean-room Linux implementation of Apple's public `GLKit`
surface, seeded from the Xcode 26.1 iPhoneOS SDK symbol graph.

## What is real

- **GLKMath** vector, matrix, quaternion, projection, and matrix-stack APIs are
  implemented from the public inline C headers. Layout is column-major. Identity
  constants, invert (failing closed to identity when singular), look-at,
  perspective/ortho/frustum, and quaternion rotation are exercised by
  `tests/agent/GLKitRuntime.swift`.
- **Enumerations**, **GLKTextureLoaderError**, and CPU-side effect property
  state (`GLKBaseEffect`, lights, material, fog, textures, transforms) are
  source-compatible and store values without pretending a shader compiled.
- **GLKVertexAttributeParametersFromModelIO** maps public Model I/O vertex
  format bits onto GLES type/size/normalized parameters.

## Fail-closed boundaries

Linux has no EAGL context and this isolated compile does not link OpenGLES,
UIKit, Model I/O, or CoreGraphics. Stand-in types keep signatures compiling.

- `GLKTextureLoader` always throws `GLKTextureLoaderError.invalidEAGLContext`.
- `GLKMesh` / `newMeshes(from:sourceMeshes:)` throw `GLKModelError.gpuUnavailable`.
- `prepareToDraw()`, `GLKSkyboxEffect.draw()`, and `GLKView` drawable bind/delete
  are no-ops. `snapshot` returns an empty `UIImage`.
- Option-key and error-domain *strings* currently equal the public symbol names;
  they are not claimed to match Apple's binary constant payloads.

## Still deferred / oracle

See `oracle-questions.tsv`. Singular-matrix invert payloads, NSString formatting
of matrices, default light colors, and exact Model I/O packed-format mapping
need an Apple-runtime probe before they can be treated as parity.
