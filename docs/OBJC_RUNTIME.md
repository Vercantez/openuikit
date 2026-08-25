# The Objective-C runtime question — tested, 2026-08-25

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
