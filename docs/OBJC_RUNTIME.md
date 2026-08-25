# The Objective-C runtime question — tested, 2026-08-25

> **CORRECTION (same day).** The verdict below ("do not adopt an ObjC
> runtime, the compiler blocks it") was **wrong**, and the evidence for it was
> self-inflicted. `@objc` and `#selector` *do* compile and run on Linux. The
> earlier `swift-frontend` crash came from a shim that declared `Selector` as a
> String-shaped struct where the compiler expects a pointer-shaped one — not
> from a compiler limitation. See "What actually works" at the end; the
> analysis of Darling vs libobjc2 still stands, but the conclusion changed.

Real UIKit leans on the ObjC runtime for target-action (`#selector`), KVO,
`UIAppearance`, and optional-protocol dispatch (`respondsToSelector:`).
OpenUIKit uses none of it: `UIControl` takes closures, and every protocol is a
plain Swift protocol. This file records what we measured when asking whether
we should adopt an ObjC runtime to improve app compatibility.

## How much do real apps depend on it?

Counted over the census corpus (eidolon, DuckDuckGo iOS, ios-oss):

| | `#selector` | `@objc` | `perform`/`responds(to:)` | `.appearance()` |
|---|---|---|---|---|
| eidolon | 8 | 30 | 0 | 0 |
| DuckDuckGo iOS | 189 | 148 | 24 | 8 |
| ios-oss | 163 | 165 | 35 | 0 |

~360 `#selector` uses — comparable to the alerts cluster (332). Real, but not
dominant. Most `NSNotificationCenter` observer registrations (ios-oss has
~780) need no ObjC runtime; corelibs-foundation covers them on Linux.

## The decisive constraint: it is a *compiler* limitation, not a library one

Tested inside `swift:6.2-noble` (Swift 6.2.4, aarch64-linux):

1. Plain `@objc` → `error: Objective-C interoperability is disabled`.
2. With `-Xfrontend -enable-objc-interop` → `@objc` is **accepted**; `#selector`
   then fails with `error: import the 'ObjectiveC' module to use '#selector'`.
3. Building a Swift module literally named `ObjectiveC` (declaring `Selector`,
   `ObjCBool`) and importing it alongside Foundation →
   **the compiler crashes with signal 11**, in
   `swift::irgen::…storeAsBytes(…)` inside `GenObjC.cpp`, while emitting IR.

So ObjC interop off-Darwin is not merely unsupported, it is broken at the
IRGen level: the frontend expects Apple runtime metadata layouts that do not
exist. **No library we ship can fix this.** `#selector` cannot compile on
Linux today, whatever runtime is present.

## Evaluating the candidates

**GNUstep `libobjc2`** — the right *runtime*: modern ObjC 2.0 (ARC, blocks,
associated objects, non-fragile ivars), portable, and packaged on Ubuntu
(`libgnustep-base-dev`; note `libobjc-N-dev` is GCC's older ObjC 1.0 runtime,
not this). But the runtime is not our blocker — the compiler is. Using it
would require patching `swiftc` to emit libobjc2-compatible metadata instead
of Apple's, i.e. maintaining a Swift compiler fork. That is a far larger and
more fragile commitment than the problem justifies.

**Darling** — the wrong tool for this job. Darling is a Darwin *emulation
layer* (Mach-O loader, dyld, Mach traps, XNU syscall emulation) for running
macOS **binaries** on Linux. We do not load macOS binaries; we compile apps
from source against a portable library. Adopting it would reintroduce exactly
the Darwin dependencies this project removed, and would make "portable" mean
"emulated Darwin," which is the opposite of the goal. It is the right project
if you ever want to run *precompiled* iOS/macOS apps — a different product.

**Apple's `objc4`** — open source but welded to Darwin (Mach, dyld, malloc
zones). Porting is a research project.

## What we should build instead

`objc_msgSend` solves **binary** compatibility with precompiled ObjC code —
something we will never need, since we recompile from source. What apps
actually need is **source-level selector dispatch**, which is achievable in
pure Swift:

1. **Closures (today).** `addTarget(for:_:)`. Portable, type-safe, zero
   runtime. Cost: a mechanical edit per call site.
2. **A Swift macro.** `@Action func tapped()` generates a name → closure table
   on the type, plus a `Sel("tapped")` lookup, giving
   `addTarget(self, action: Sel("tapped"), for:)` — UIKit's shape without ObjC.
   Macros are pure Swift and work on Linux.
3. **A source rewriter** mapping `#selector(x)` → `Sel("x")` and `@objc` →
   `@Action` in the build pipeline. With (2), unmodified app source compiles
   everywhere. This is the only path to drop-in compatibility on Linux, and
   notably it is a build-time tool, not a runtime.

Related runtime-flavoured features and their portable answers: **KVO** →
explicit observer registry or `didSet` (real KVO isa-swizzles at runtime);
**`UIAppearance`** → a typed appearance-proxy struct per class (real UIKit
records setters through `NSInvocation` forwarding); **optional protocol
methods** → protocol extensions with default implementations.

## Verdict

Do not adopt an ObjC runtime. Build the macro (and, if drop-in source
compatibility becomes the blocker, the rewriter). Revisit only if the goal
changes from "run app *source*" to "run app *binaries*" — at which point the
answer is Darling, and it is a different project.


## What actually works (measured, reproducible)

`Tools/objcshim/verify.sh` compiles and RUNS this inside stock
`swift:6.2-noble`, printing the recovered selector names:

```
recovered: tapped
recovered: valueChanged:
```

Note the correct ObjC mangling (the trailing colon on the one-argument
selector) — the compiler is doing real selector generation, not a fallback.

The entire cost is three small pieces, no compiler patch and no ObjC runtime:

1. **`Tools/objcshim/ObjectiveC.swift`** (~10 lines) — a module literally named
   `ObjectiveC` declaring `Selector` as a **pointer-shaped** struct (this is
   the part I got wrong the first time) plus `ObjCBool`.
2. **`Tools/objcshim/objc_stub.c`** (~20 lines) — the handful of runtime
   symbols Swift's interop codegen references: `_objc_empty_cache`,
   `objc_opt_self`, `OBJC_CLASS_$__TtCs12_SwiftObject` and its metaclass,
   plus `swift_unknownObjectRetain/Release` (absent from Linux swiftCore,
   which is built without interop; identity is correct for a pure-Swift
   object graph). Archived as `libobjc.a` to satisfy the autolinker's
   `-lobjc`.
3. **Two existing flags**: `-Xfrontend -enable-objc-interop` and
   `-Xfrontend -disable-objc-attr-requires-foundation-module`.

Crucially, `sel.ptr` resolves to the selector **name string**, because the
stub's `sel_registerName` returns its argument and the literal lives in the
binary. So `String(cString:)` recovers `"valueChanged:"` at runtime — which is
all a source-level dispatch scheme needs.

### Two tiers now available

- **Tier 1 (proven, ~30 lines):** `#selector` compiles everywhere and yields a
  name. `UIControl.addTarget(_:action:for:)` can take a real `Selector`, read
  the name, and dispatch through a registry we own. This gives apps UIKit's
  actual API shape with no runtime.
- **Tier 2 (plausible, unproven):** Swift also emits real ObjC class metadata
  and `...FTo` method thunks on Linux (visible in the link symbols). Linking
  GNUstep **libobjc2**, which consumes that metadata, would give genuine
  `objc_msgSend` dispatch, `respondsToSelector:`, and a base for KVO and
  `UIAppearance`. This is now a much smaller step than previously assessed,
  because the compiler side is already emitting what a runtime would need.

### What this does not change

Darling remains the wrong tool for *this* project (it is a Darwin emulation
layer for running macOS **binaries**; we compile from source). And
`objc_msgSend` is still not required for Tier 1. What changed is that the
door to Tier 2 is open, and Tier 1 is nearly free.
