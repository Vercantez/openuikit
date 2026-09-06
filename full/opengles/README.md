# OpenGLES (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public `OpenGLES`
Clang overlay, seeded from the Xcode 26.1 iPhoneOS 26.1 SDK. It produces one
nominal Swift module, `OpenGLES`, and a loadable `libOpenGLES.dylib`. It is a
**legacy-adapter** for a deprecated GPU API. It is not Apple behavioral parity
and it is not wired into the shared guest package.

## What is real

- Khronos scalar types (`GLenum`, `GLuint`, `GLfloat`, `GLsync`, …) with the
  widths recorded in the symbol graph.
- 1087 `GL_*` tokens with the numeric values from the public Linux GLES 1/2/3
  headers. Six Apple overlay spellings without an EXT/OES suffix
  (`GL_BGRA`, `GL_UNSIGNED_SHORT_*_REV`, `GL_UNSIGNED_INT_OES`,
  `GL_OES_VERSION_1_0` / `1_1`) use the documented Khronos aliases.
- `EAGLRenderingAPI` raw values 1 / 2 / 3, version macros 1.0, `EAGLGetVersion`,
  identifier-as-string drawable keys, and a CPU-side `EAGLContext` /
  `EAGLSharegroup` / `EAGLDrawable` overlay.
- A software GLES state machine: enable/disable, viewport/scissor/clear color,
  blend/depth/stencil masks, name generation, buffer data + map/unmap, texture
  parameters and `glTexImage2D` metadata, framebuffer completeness, ES1 matrix
  stacks (identity / translate / scale / rotate / frustum / ortho / push/pop
  with overflow and underflow errors), `glGetString` / implementation limits,
  and CPU fences that are already signaled because there is no GPU queue.

## Fail-closed / not invented

- `presentRenderbuffer`, `renderbufferStorage(from:)`, and `texImageIOSurface`
  return `false`. There is no CAEAGLLayer compositor or IOSurface on this host.
- `glCompileShader` / `glLinkProgram` leave `GL_COMPILE_STATUS` /
  `GL_LINK_STATUS` as `GL_FALSE`. There is no GLSL compiler.
- `glDrawArrays` / `glDrawElements` / `glReadPixels` / `glClear` on framebuffer 0
  record `GL_INVALID_OPERATION` or `GL_INVALID_FRAMEBUFFER_OPERATION`.
- Unimplemented GPU commands with a current context also record
  `GL_INVALID_OPERATION`. Calls with no current context do the same.
- Drawable string keys compile as identifier-as-string and are **not** claimed
  to match Apple's CFSTR payloads.
- `MAX_TEXTURE_SIZE` is this port's software limit (2048). `MAX_LIGHTS` (8) and
  matrix stack depths (16 / 2 / 2) follow GLES 1.1 specification minima, not an
  Apple GPU.

## Still deferred

No public-surface identifier is deferred: all 1587 exact IDs are `implemented`
with a focused `test*` function. Remaining Apple questions live in
`oracle-questions.tsv`.

Isolated compile (this environment) can import `Foundation` and
`CoreFoundation`. `IOSurface.framework` is not a declared dependency; the C
`IOSurfaceRef` parameter is an `OpaquePointer`.

Run the immutable host gate:

```sh
bash tests/acceptance/test_host.sh
```

Host gate markers from this run:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=OpenGLES lane=legacy-adapter symbols=1587
FRAMEWORK_FANOUT_REFERENCE_OK
OPENGLES_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=OpenGLES dylib=libOpenGLES.dylib
```

`swiftc` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` failed earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`) and therefore did not print the campaign inventory stamp. The sealed gate compiled a clean product tree (no `.build` / `build` / `scratch` under `full/opengles/`).

## Depth pass 2026-09

Campaign `ios26.1-fwseed-r10`, lane `legacy-adapter`, framework `OpenGLES`
(1587 IDs). Starting commit `2abc9defd72942e7a24dcc79779ea5c50e67d75c`.

| | implemented | declared | deferred |
|---|---:|---:|---:|
| Seed | 0 | 0 | n/a (no coverage yet) |
| After this pass | **1587** | **0** | **0** |

Nondeferred 1587. Every `implemented` row cites
`test:full/opengles/tests/agent/<File>Tests.swift#testName` for a real
top-level synchronous no-argument `func testName()`.

Top-5 evidence distribution (implemented rows → test):

1. `testGLESConstantsTexture` — 192 (C `GL_*` texture tokens; table-driven)
2. `testGLESConstantsPixel` — 175 (C `GL_*` pixel/type tokens; table-driven)
3. `testGLESConstantsMisc` — 157 (remaining C `GL_*` tokens; table-driven)
4. `testGLESConstantsBuffer` — 138 (C `GL_*` buffer tokens; table-driven)
5. `testGLESConstantsDepthStencil` — 71 (C `GL_*` depth/stencil tokens; table-driven)

## Oracle

See `oracle-questions.tsv`.
