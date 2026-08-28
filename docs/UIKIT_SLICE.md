# UIKIT SLICE — OpenUIKit compiled to Mach-O on Linux, run under machorun

**Date:** 2026-08-26. **Question:** can a real slice of OpenUIKit (Swift, uses
classes, protocols, generics) be built as an `arm64-apple-macos` Mach-O on
Linux and render one of its own golden scenes under machorun? **Answer: it
BUILDS and LOADS in full; it RUNS up to a specific, named Swift-runtime gap and
does not yet produce the PNG.** The wall is runtime-provisioning in the Swift
stdlib, not OpenUIKit, not the compiler, and — measured below — **not
Foundation.**

Target scene: `boxes_basic` (a nested UIView tree, background colors + frames;
golden is real UIKit output, `~/uikit/golden/boxes_basic.png`, 640×480 @2×).

## 1. What was vendored, and why it is a real slice

`slice/src/` is a flattened one-module vendoring of OpenUIKit's render core
(provenance in each file header; `~/uikit` is never edited):

- **OpenCoreGraphics, verbatim** (9 files): `Geometry`, `Canvas`, `Backend`,
  `QuartzBackend`, `Rasterizer`(+Effects), `CanvasEffects`, `CanvasTextBlend`,
  `PNG`. This is the drawing engine; `QuartzBackend` draws through the same
  `libquartz` that already runs as Mach-O under machorun.
- **UIKit render core**: `UIView`+`CALayer`, `UIColor`+`UITraitCollection`,
  `RenderPass` (`UIRenderer`), `UIResponder`, `UIKitCore`, all **kept verbatim
  on the pixel path**. `UIView`/`UIResponder`/`UIKitCore` were trimmed to the
  render-relevant members (the AutoLayout / safe-area / gesture / controller /
  window / text / font subsystems, and their Foundation-typed API, were cut —
  none are on the `boxes_basic` path). Trims are labelled `VENDOR-EDIT`.
- Small shims: `SliceStubs` (UIContentSizeCategory, an inert SystemColors),
  `MiniAnimation` (the value enums UIView's observers name; recordAnimation is a
  no-op with no active `UIView.animate` context — exactly what the real one is),
  `FreestandingShims` (TimeInterval = Double).

`boxes_render.swift` builds the scene EXACTLY as `~/uikit`'s SceneBuilder does
(scene-sized `host` UIView wrapping a 0×0 `container` root; colored views are
the container's subviews at their real frames; `UIRenderer.render(host,
scale: 2)`), then PNG-encodes the bitmap. A C `main` writes the file.

## 2. Build side — settled, and the answer is good

`scripts/build_slice2.sh` (runs in `swift-macho-spike:noble`):

- The whole slice compiles to an `arm64-apple-macos` Mach-O **dylib** on Linux
  and links with `ld64.lld-18`. No source errors, no undefined symbols.
- It **loads under machorun** with every symbol resolved (all image
  initializers run, objc registers the classes).

## 3. Foundation verdict — the render slice needs ZERO Foundation

Measured, not assumed:

- In the staged sysroot `canImport(Foundation)` and `canImport(CoreGraphics)`
  are both **false** (no Foundation/CoreGraphics module is staged), so the whole
  slice compiles down OpenCoreGraphics' and UIView's **`#else` freestanding
  branches** — its own `CGRect`/`CGPoint`/`CGColor`/`CGAffineTransform`. The
  geometry, color, layer and render-pass path is Foundation-free.
- At the time this slice result was measured (after M15 and before table API
  commit `064c774`), the FULL OpenUIKit hard-required Foundation only for the
  **names** `IndexPath` / `NSRange` / `TimeInterval`, declared solely under
  `#if canImport(Foundation)` in `FoundationTypes.swift`. Those names are used
  by the table/collection/text/timer files — **not** by the view/color/render
  core. So: a UIKit *render* slice is Foundation-free; a full app additionally
  needs those ~3 typealiases (trivially shimmable, as `FreestandingShims` shows)
  plus real Foundation for its own model layer. None of it is corelibs-shaped
  Swift-Foundation; it was three type names. Since `064c774`, UITableView's
  section-editing surface also names `IndexSet`; the current Foundation-free
  full build supplies a narrow value implementation in
  `full/shims/FoundationNames.swift`.

## 4. Run side — how far it gets, and the exact wall

The runtime is the self-built macOS-arm64 core-only `libswiftCore` from
`~/swiftcore-macho` (the one machorun's `swift_gate.sh` validated), staged into
the guest root, linked **swiftcore-first** with `libswiftcompat.dylib` and the
implicit `_Concurrency`/`_StringProcessing` imports disabled (core-only runtime).

Staged probes (`slice/boxes_render.swift`, driven by `slice_main.c`) — each PASSES:

| probe | exercises | result |
|---|---|---|
| pure Swift Int | — | 42 |
| `[UInt8]` alloc/append | prespecialized Array | ok |
| build UIView tree | **UIView + CALayer + UIColor classes**, addSubview | ok |
| `Array<CGPoint>` | non-prespecialized struct-Array metadata | ok |
| `Array<Path.Element>` | generic Array over a custom enum | ok |
| Bitmap + `pngData()` | `[UInt8]` + the PNG encoder | ok (136 bytes) |

So classes, the UIView object graph, generic Array metadata and PNG all run —
the class/generic-metadata wall the machorun TLS fix targeted is **gone**.

**Then it stops, at two runtime gaps in the self-built stdlib:**

1. **`ArraySlice` faults.** Even `arr[a..<b].count` SIGSEGVs (isolated in
   `slice/probe/png_probe.swift`); full-array iteration is fine. Worked around
   in the vendored `PNG.swift` by integer-indexed copies (byte-identical) — that
   got the PNG probe to pass.
2. **Class-bound protocol existential RELEASE faults.** `let b: P = Impl();
   b.f()` then release → SIGSEGV **inside `libswiftCore`'s
   `swift_unknownObjectRelease`** (offset ~0x331e–0x332c), faulting on a stack
   address, while a plain native-class release works. This is what stops the
   render: `Canvas.backend` is a `CanvasBackend` existential, and constructing a
   `Canvas` (needed before any draw) releases one. Minimal reproducer in
   `png_probe.swift` (`p_existential`).

**One root cause, several symptoms.** Making `Canvas.backend` a CONCRETE
`QuartzBackend` (not the existential) moved the wall from Canvas construction to
an `unowned`-reference operation — which faults at the SAME `libswiftCore`
offset. ArraySlice, existential release and `unowned` all land in
`swift_unknownObjectRelease`, the unknown-object (ObjC-compatible) release path
that existentials, `unowned`/`weak` side-tables and slice storage share. It is
one runtime bug with several faces. Compiling the slice against the SELF-BUILT
`Swift.swiftinterface` instead of Xcode's did **not** change it, which rules out
a compile-time interface/ABI mismatch and confirms the fault is in the runtime's
release path (or in how machorun's objc handles the release it delegates to).

Link-order note confirming the setup is right: in **system-first** order
`_swift_release` is undefined at load (the machorun fix removed libSystem's stale
stub, but the sysroot `libSystem.tbd` still advertises it, so two-level binding
sends it to libSystem) — i.e. Swift guests MUST link swiftcore-first here, and
the slice does.

(The iOS-**simulator** `libswiftCore` used earlier in `docs/RUNTIME.md` has a
DIFFERENT frontier: PNG and Canvas construction succeed there, but a later draw
faults in `libswiftCore@0x2dce0`, and non-prespecialized generic metadata / the
concurrency runtime were walls before `@MainActor` was stripped. Two runtimes,
two different stdlib gaps; neither renders a full scene yet.)

## 5. Remaining distance to a rendered scene, and to a whole app

- **To render `boxes_basic`:** close the two self-built-stdlib gaps above —
  `ArraySlice` and `swift_unknownObjectRelease` (existential/bridged release).
  Both are runtime-provisioning (swiftcore-build / machorun), NOT OpenUIKit,
  compiler or Foundation work. The build, the load, the object model and the
  render *logic* are all already proven; a fixed release path should let the
  existing bytes render, and the result is then a byte diff against
  `~/uikit/golden/boxes_basic.png`.
- **To a whole iOS app:** at this milestone, on top of the above, the
  `IndexPath`/`NSRange`/`TimeInterval` typealiases (3 lines) for the full
  module; current OpenUIKit additionally needs the Foundation-free `IndexSet`
  described in §3. Then `_Concurrency` if
  `@MainActor`/`async` are wanted (a second runtime dylib + its libSystem
  symbols), and the text/font stack for labels. No new *compiler* capability is
  required — §2/§3 show OpenUIKit's Swift already lowers to loadable Mach-O.

## Reproducing

```
# runtime already staged into scratch/mrroot (self-built libswiftCore + shims)
docker run --rm -v "$PWD:/w" -w /w swift-macho-spike:noble bash scripts/build_slice2.sh
docker run --rm -v "$PWD:/w" -w /w/build/slice -e MACHORUN_ROOT=/w/scratch/mrroot \
    swift-macho-spike:noble /w/scratch/mrroot/machorun ./slice_main out.png
# the two isolated stdlib-gap reproducers:
docker run --rm -v "$PWD:/w" -w /w swift-macho-spike:noble bash scripts/build_pngprobe.sh
docker run --rm -v "$PWD:/w" -w /w/build/slice -e MACHORUN_ROOT=/w/scratch/mrroot \
    swift-macho-spike:noble /w/scratch/mrroot/machorun ./png_probe
```
