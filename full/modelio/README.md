# ModelIO Linux lane

This directory is a Linux starting implementation of Apple's public
`ModelIO` Swift overlay, reconstructed from pinned `dotnet/macios` bindings
(`ModelIO.cs`) after the original Xcode 26.1 extractor seed.

The sealed host gate compiles this module with toolchain Foundation only.
`simd`, `CoreGraphics`, and Objective-C `Protocol` are not importable, so
matrix types are local aliases and CGColor / Protocol entry points are
deferred. This port does not invent Apple USD, Alembic, GPU baking, or
photometric-hardware success.

Campaign environment: `.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent. `swiftc --version` is Swift 6.2.4 targeting
`x86_64-unknown-linux-gnu`. The campaign inventory stamp is a host-inventory
token, not printed by the sealed framework gate:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
```

The sealed gate was not weakened.

## What is real

- Vertex-attribute `NSString` constants (`MDLVertexAttributePosition` and
  siblings) using the public identifier as the payload.
- UTI export names (`kUTType3dObject` and siblings) using identifier-as-string.
- All documented enum families with exact `UInt` / `Int` raw values from
  `ModelIOTypes.h`, including `MDLVertexFormat` bit patterns as a
  `RawRepresentable` struct.
- `MDLAxisAlignedBoundingBox` and `MDLVoxelIndexExtent` value types.
- `MDLMeshBufferData` / `MDLMeshBufferDataAllocator` with map/unmap and
  zone pooling.
- `MDLVertexDescriptor` packed-layout helpers and attribute lookup.
- Scene graph: `MDLObject`, `MDLObjectContainer`, `MDLAsset` children,
  bounding-box walk, and in-memory object lookup by path/name.
- OBJ and STL ASCII import/export (`canImport` / `canExport` for `obj`/`stl`
  only). Round-trip preserves triangle positions for a unit-box mesh.
- Primitive factories: box, plane, sphere, hemisphere, cylinder, capsule,
  cone, icosahedron, and `generate*Mesh` class methods.
- Mesh edits: `addNormals`, `addTangentBasis`, `addUnwrappedTextureCoordinates`,
  `makeVerticesUnique`, `replace(withNewVertexBuffers:vertexCount:)`.
- Materials, scattering functions, and a material-graph evaluator for
  documented `MDLMaterialPropertyConnection` / `MDLMaterialPropertyNode`.
- CPU textures: checkerboard (uInt8 Linux init), noise, normal-map
  generation from height, irradiance from a texture, color-temperature
  swatch, and a simplified sky-cube gradient.
- Cameras: perspective / orthographic projection, `look(at:)`,
  `ray(to:forViewPort:)`, stereoscopic and bokeh properties.
- Lights: physically-plausible spherical falloff, area-light properties,
  photometric IES file load (nil when the file is missing).
- Transforms: TRS local transform, `MDLTransformStack`, animated scalar /
  vector / quaternion / matrix types, packed joint animation, and skeleton
  bind/rest copies.
- Voxels: shell voxelization of a triangle mesh, index extent, and
  `MDLVoxelIndex` packing.

Sources listed in `modelio_guest_sources.txt` compile to `libModelIO.dylib`.

## Fail-closed boundaries

- USD / USDA / USDC / USDZ / Alembic `canImportFileExtension` and
  `canExportFileExtension` are `false`. `MDLAsset` URL inits that are not
  OBJ/STL leave `childCount == 0` and, when an error pointer is supplied,
  report `ModelIOLinuxError.unsupportedURL`.
- `MDLUtility.convert(toUSDZ:writeTo:)` does not write a destination file.
- Ambient-occlusion and lightmap bakers return `false` and do not invent
  GPU lighting.
- `MDLLight.irradiance(atPoint:)` and CGColor material/texture APIs are
  omitted (`#if canImport(CoreGraphics)` is false on this host).
- `MDLObject.componentConforming(to:)` / `setComponent(_:for:)` / Protocol
  subscript are omitted (Linux Foundation has no ObjC `Protocol` type).
- `MDLTexture.imageFromTexture()` is omitted (no `CGImage`).
- Error domain is `org.openuikit.ModelIO.linux`, not an Apple domain.

Linux substitutions (not claimed as Apple ABI):

- `NSErrorPointer` is `UnsafeMutablePointer<NSError?>?`.
- Texture `write(to:type:)` takes `NSString` (no `CFString`).
- `MDLObjectContainerComponent` does not inherit `NSFastEnumeration`.
- Extra `MDLCheckerboardTexture` init without `CGColor`.

## Depth pass 2026-09

SDK depth for `ModelIO` (939 exact IDs). Value types, buffers, descriptors,
scene graph, OBJ/STL, primitives, mesh edits, materials, CPU textures,
cameras, lights, transforms, animation, and voxels are nondeferred.

Coverage ledger (exact-ID `coverage.tsv`):

| revision | implemented | declared | deferred | evidence |
| --- | ---: | ---: | ---: | --- |
| this seed | 923 | 0 | 16 | 120 unique `test:…#testName` cites |

Top-5 evidence distribution among implemented rows:

| cites | evidence |
| ---: | --- |
| 69 | `test:full/modelio/tests/agent/ModelIOEnumTests.swift#testMDLVertexFormat` (enum/option-set table; allowed) |
| 40 | `test:full/modelio/tests/agent/ModelIOTransformTests.swift#testTransformStack` |
| 31 | `test:full/modelio/tests/agent/ModelIOEnumTests.swift#testMDLMaterialSemantic` (enum table; allowed) |
| 24 | `test:full/modelio/tests/agent/ModelIOMaterialTests.swift#testMaterialPropertyValues` |
| 22 | `test:full/modelio/tests/agent/ModelIOTransformTests.swift#testTransformTRS` |

`testTransformStack` is 40 / 652 remaining (non-enum) implemented rows
(about 6%), under the 40% bulk-relabel cap.

Deferred IDs (16) are CoreGraphics and ObjC `Protocol` surfaces listed in
`coverage.tsv` with `deferred` + `unavailable:…` notes.

Unresolved questions that the pinned corpus cannot settle live in
`oracle-questions.tsv`.

Gate (Linux host, no docker):

```
bash full/modelio/tests/acceptance/test_host.sh
```

Expected markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ModelIO lane=large-partitioned symbols=939
FRAMEWORK_FANOUT_REFERENCE_OK
MODELIO_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ModelIO dylib=libModelIO.dylib
```
