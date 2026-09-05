# GLKit (dependency-correct starting point)

This directory is a clean-room Linux starting point for Apple's public `GLKit`
module. It is not Apple behavioral parity, it is not wired into the shared
guest package, and a green isolated host gate is **not** integrated Linux
success.

## Isolated compile (this environment)

Importable here: `Foundation` only (plus Dispatch/CoreFoundation).

Not importable as guest modules:

- `OpenGLES`
- `UIKit`
- `CoreGraphics`
- `ModelIO`

GLKit therefore does **not** define module-local `EAGLContext`,
`EAGLSharegroup`, `CGImage`, `UIImage`, `UIView`, `UIViewController`, or
`MDL*` types, and it does not re-export an OpenGLES typedef/constant overlay
(`GLboolean`, `GL_TEXTURE_2D`, …). GLES C widths used on the host are
`UInt8` / `Int32` / `UInt32` / `Float`. When OpenGLES is importable it is
`@_exported`.

What compiles and is tested here is the target-owned CPU math
(`GLKVector*`, `GLKMatrix*`, `GLKQuaternion*`, `GLKMatrixStack`), enumerations,
CPU-side effect property storage, `NSStringFromGLK*` formatters, identifier-
as-string constants, and fail-closed texture-loader completions that do not
name missing dependency types. Coverage for every API that names a
dependency nominal type is `deferred`.

`GLKView : UIKit.UIView`, `GLKViewController : UIKit.UIViewController`,
`GLKTextureLoader(sharegroup:)`, CGImage entry points, and `GLKMesh` Model I/O
initializers are behind `#if canImport` of the real modules so a later EC2
run can compile them against actual `-I`/`-L` dependency dylibs.

## Fail-closed / not claimed

- No EAGL drawable, shader `prepareToDraw`, or GPU texture/mesh upload is
  fabricated. `prepareToDraw` / `GLKSkyboxEffect.draw` are inert CPU no-ops.
- `GLKView.snapshot` does not return an empty `UIImage`; the method is omitted
  on this host and fail-closes with `fatalError` when compiled against UIKit
  (pixel readback is unimplemented).
- Texture-loader completions are dispatched off the caller, onto the provided
  queue, and invoked exactly once. A nil queue uses a host global queue; that
  default is not claimed as Apple's. Sync and async file/data/URL/name/cube
  overloads throw or complete with `GLKTextureLoaderError.invalidEAGLContext`
  (raw value 17).
- Option-key, error-domain, and `NSStringFromGLK*` payloads compile as
  identifier-as-string / local formatters and are **not** claimed to match
  Apple's binary constants. Tests assert this port's strings, not Apple's.
- Effect property **defaults** (light colors, `useConstantColor`, fog, material)
  are unobserved and are not invented from OpenGL ES 1.1 folklore. Assigned
  values round-trip.
- `GLKMatrix4Invert` of the identity and of a diagonal scale is tested.
  Singular-matrix payloads stay an oracle question.
- `GLKVertexAttributeParametersFromModelIO` is not compiled here (needs
  ModelIO) and does not invent a packed-format mapping.

## Depth pass 2026-09

Corpus: `reference/corpus-summary.json` records one Telegram-iOS hit
(`RMIntroViewController.h`). `scratch/ladder-corpus` is not present in this
VM, so ranking used the pinned summary plus the public math/effect/texture
surface those intro views typically call.

| | before | after |
|---|---:|---:|
| implemented | 209 | 491 |
| declared | 282 | 0 |
| deferred | 59 | 59 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Focused `tests/agent/*Tests.swift` count: 62 unique `test*` functions.
Every `implemented` row cites `test:full/glkit/tests/agent/<File>Tests.swift#testName`.

Top-5 evidence distribution (implemented rows → test):

1. `testGLKTextureLoaderErrorCodes` — 45 (error-code / enum-member table; allowed to share)
2. `testGLKEffectMaterialFogTexture` — 23
3. `testGLKMatrixStackTransforms` — 16
4. `testGLKEffectLights` — 16
5. `testGLKTextureLoaderErrorBridging` — 15

## Future EC2 probe

`tests/agent/GLKitDependencyIdentity.swift` is **not** part of the isolated
gate. It is the later EC2 client: it imports OpenGLES, UIKit, CoreGraphics,
ModelIO, and GLKit; passes real `EAGLContext` / `EAGLSharegroup`,
`CGImage` / `UIImage`, `UIView` / `UIViewController`, and
`MDLAsset` / `MDLMesh` values through public APIs; proves inheritance and
nominal identity; proves texture callbacks; `dlopen`s `libGLKit.dylib` and
inspects `NEEDED` / exported symbols; and prints
`GLKIT_DEPENDENCY_IDENTITY_OK` only after assertions pass.

Do not claim integrated Linux success until that cold build uses the real
dependency modules, builds and load-tests `libGLKit.dylib`, and passes the
identity/ABI probe.

## Oracle

See `oracle-questions.tsv`.
