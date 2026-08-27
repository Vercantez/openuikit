# machorun SDK gaps found while porting swift-foundation's `URL` (#58)

Two headers machorun's staged SDK does not ship, each of which stops any C
module that reaches it. **These stubs are a local unblock; the real fix belongs
in machorun's `sdk/`.**

| header | why it is reached | severity |
|---|---|---|
| `complex.h` | clang's own `/usr/lib/swift/clang/include/tgmath.h` includes it **unconditionally** | blocks *any* C module reaching `tgmath.h` |
| `sys/attr.h` | the SDK's **own** `/usr/lib/swift/_FoundationCShims/io_shims.h:22` includes it | the sysroot is internally inconsistent — it ships a module whose header it cannot satisfy |

The second is the more serious: machorun stages `_FoundationCShims` and then
cannot compile it. Nothing had noticed because nothing in the render path builds
a C module that reaches those headers.

## A third gap, not a header — and NOT the version skew it announces itself as

**Diagnosed 2026-08-27, and the outer message is misleading.** The top-level
error reads:

    failed to build module 'Synchronization'; this SDK is not supported by the
    compiler (the SDK is built with 'Apple Swift version 6.2.1', while this
    compiler is 'Swift version 6.2.4'). Please select a toolchain which matches
    the SDK.

That is **not the cause**. Reading the inner diagnostic (`-Rmodule-interface-rebuild`)
gives the real one:

    Darwin.swiftmodule/arm64e-apple-macos.swiftinterface:5:19:
    error: underlying Objective-C module 'Darwin' not found

The chain is: something imports `Synchronization` → `Synchronization.swiftinterface`
does `import Darwin` → `Darwin.swiftinterface` needs the **Clang** module
`Darwin` → **that module is not declared anywhere in the sysroot.**

**machorun's staged SDK declares exactly ONE Clang module.** Its
`usr/include/module.modulemap` is 330 bytes:

    module ObjectiveC [system] { ... }

A real macOS SDK's `usr/include/module.modulemap` declares dozens by reference,
including line 38: `extern module Darwin "Darwin.modulemap"` — and that
`Darwin.modulemap` is 4,551 bytes with **49 submodules** covering the C standard
library and POSIX.

**So this is a missing MODULE DECLARATION, not a toolchain mismatch, and the
fix is a modulemap rather than a downgrade.** Most of the headers it would
cover are already staged; what is missing is the declaration that groups them
into `module Darwin`.

**And the removed-`.swiftmodule` trick is NOT available here.** It was correct
for `os`, where "we have no `os_log` at runtime" makes `canImport(os) == false`
*true*. `Synchronization` is different: the port genuinely uses `Mutex`, so
making `canImport` report false would be a lie — the build-time predicate
contradicting the runtime fact, which is the §6 inversion rather than a fix.

## The original note on os/Darwin (superseded in part by the above)

`os.swiftmodule` and `Darwin.swiftmodule` in the staged SDK **cannot be built by
our compiler**: the interfaces were produced by *Apple Swift 6.2.1* and the
container runs *Swift 6.2.4*, which refuses with "this SDK is not supported by
the compiler". Latent until now because nothing in the render path imports
`os` or `Darwin`.

Worked around by building the port against a private sysroot with those two
`.swiftmodule` directories removed, so `canImport(os)` and `canImport(Darwin)`
are **false** and upstream's platform `#if` chain selects another branch. That
is the SDK-level lever rather than a source patch — and it is honest, since we
have no `os_log` at runtime either.

## Before walking the module chain, consider whether it is the right direction

`Darwin` is necessary but not sufficient — `_DarwinFoundation1` needs a Clang
module too, and the chain length is unknown. Before extending it, measure this
first (already done, recorded here):

**29 of the 34 FoundationEssentials files that `import Darwin` have a
`#elseif canImport(Glibc)` branch.** Only 5 do not (`UUID_Wrappers.swift` among
them). So there are two routes, and they are not equally sized:

- **(A) Walk the chain.** Declare Clang modules for `Darwin`,
  `_DarwinFoundation1`, and whatever follows, so Apple's Swift overlays build.
  Chain length unknown. And these overlays describe *Apple's real libc*, while
  our sysroot stages 71 curated headers — so they may compile and still describe
  a surface we do not have.
- **(B) Let upstream's own platform branch handle it.** Make `canImport(Darwin)`
  false and the `canImport(Glibc)` branch is selected — which 29 of 34 files
  already support, leaving 5 to deal with.

**(B) IS NOT AUTOMATICALLY THE ANSWER, AND THE REASON IS THE §6 TEST.** The
removed-`.swiftmodule` trick is only honest when the predicate it falsifies is
*actually false at runtime*. That test passed for `os` (we have no `os_log`) and
failed for `Synchronization` (the port genuinely uses `Mutex`). For `Darwin` it
is **genuinely ambiguous**: the guest is a Darwin-ABI Mach-O binary whose libc is
machorun's `libSystem` forwarding to glibc. So *neither* `canImport(Darwin)` nor
`canImport(Glibc)` is cleanly true — we are a Darwin ABI over a glibc
implementation, which is a configuration upstream does not model.

**That is a design decision, not a build fix**, and it should be taken
deliberately rather than by whichever `.swiftmodule` happens to be present. It
also decides the shape of every future Swift port here, not just this one.

### RULING (team-lead, 2026-08-27): route (A). Walk the chain.

**And it is not a fresh decision — it follows the `ioctl` contract settled the
same day: everything above libSystem speaks Darwin.** One namespace in, because
a wrapper that cannot classify its own input is guessing.

Route (B) violates exactly that. It makes upstream code take the **Glibc**
branch — emitting glibc constants and glibc struct layouts — **through a
libSystem whose entire job is translating Darwin→glibc.** Double translation
where the two happen to agree, silent divergence where they do not:
`SOL_SOCKET` 65535 vs 1, `sigset_t` 4 bytes vs 128, `F_GETLK` meaning
`F_SETLKW`. Every wrapper in that layer assumes its caller spoke Darwin.

**So the ambiguity above dissolves, in the direction of `canImport(Darwin)`
being TRUE.** The framing "a Darwin ABI over a glibc implementation" is right,
but the predicate asks **which ABI the compiler should emit against**, not which
libc ultimately services the call. Our guest is a Darwin-ABI Mach-O. The Darwin
branch is the true one — and falsifying it would be a lie in the
`Synchronization` sense, not honest in the `os` sense, because Darwin *is* what
we present whereas `os_log` genuinely is not there.

**Sizing note for whoever walks it.** The objection to (A) — those overlays
describe Apple's real libc while we stage 71 curated headers — is a **sizing**
problem, not a direction problem, and a module declaring an unstaged header is a
*nameable gap*, the category being retired rather than a wrong turn. Size it the
way everything else here was sized: **by what the 34 importing files actually
reference, not by what Apple's modulemap declares.** That is the `~171 of 737`
move at module granularity. Apple's references 51 headers where we stage 16; the
number that matters is how many of those 51 the importers actually touch.
Anything genuinely unstaged is a real machorun gap belonging on this list beside
`complex.h` and `sys/attr.h` — **name it, do not route around it.**

The 29-of-34 measurement above is **retained deliberately**, not superseded: it
is the fallback's size should (A) turn out to be unbounded.

---

## CHAIN WALK (swiftcore-build, 2026-08-27): the chain is depth 2 and it TERMINATES

Measured by reading the `.swiftinterface` files, before building anything.

`Darwin.swiftmodule/arm64e-apple-macos.swiftinterface` opens with its own
dependency list, so the chain does not have to be discovered by compiling:

```swift
@_exported import Darwin              // the Clang module
@_exported import _Builtin_float
@_exported import _DarwinFoundation1
@_exported import _DarwinFoundation2
@_exported import _DarwinFoundation3
import Darwin.Mach.message            // a SUBMODULE, not a module
@_exported import sys_types
```

**Depth 2, and it closes.** `_DarwinFoundation1/2/3` import only their own
submodules and `Swift` — no further Swift modules — so the chain terminates one
level down rather than being unbounded. Each demands *named submodules*:

| overlay | submodules it imports |
|---|---|
| `Darwin` | `Mach.message` |
| `_DarwinFoundation1` | `._errno`, `._math` |
| `_DarwinFoundation2` | `._stdio`, `._time`, `.sys_time.timeval` |
| `_DarwinFoundation3` | `.pthread`, `._signal`, `.unistd` |

### `gen_darwin_modulemap.sh` as written cannot satisfy this

It emits **one flat** `module Darwin { header … }`. `import Darwin.Mach.message`
and `import _DarwinFoundation1._errno` name submodules, which a flat module
cannot provide, and the four overlays need four *separate* top-level modules
rather than one. **The generator's approach — generate against the target
sysroot rather than copying Apple's — is right; its output shape is not.**
A correct generator has to mirror Apple's module *structure* while pruning to
staged headers, not flatten it.

Two more facts about the members:
- **`sys_types` has no `.swiftmodule` in the sysroot at all**, so
  `@_exported import sys_types` cannot resolve via an overlay. It is a *Clang*
  module, declared in Apple's `DarwinFoundation2.modulemap` — satisfiable, but
  only by a modulemap.
- **`_Builtin_float` is in no Apple modulemap.** It is compiler-provided; it
  needs nothing staged.

### SIZING: 227 headers, and 6 real gaps — not 305

Apple's Darwin-family modulemaps reference **618** headers of which we stage 313
— but that is the wrong number, and it is the one that makes route (A) look
unbounded. Sized the way DECISION.md sizes everything else — **by what the four
overlays in the chain actually demand** — it is 227 headers across the three
`DarwinFoundation*.modulemap` files, of which **9** are absent, and three
categories of those are not gaps at all:

- **i386 variants** (`libkern/i386/_OSByteOrder.h`, `mach/i386/_structs.h`, and
  the `i386/*` set) — we are arm64-only; omit the `module i386` submodules.
- **`_modules/*.h` (6)** — these belong to *other* top-level modules
  (`os_availability`, `sys_cdefs`, `sys_qos`, `TargetConditionals`,
  `sys_appleapiopts`), not to the chain.
- **`float.h`, `iso646.h`, `stddef.h`** — members of
  `_c_standard_library_obsolete`, a module Apple marks
  `requires found_incompatible_headers__check_search_paths`, i.e. deliberately
  unbuildable. It exists to error when search paths are wrong. Omit it.

**What is genuinely missing, verified by hand rather than by the loop that
produced the list:**

| header | in machorun `sdk/`? | verdict |
|---|---|---|
| `fenv.h` | no | **real machorun gap** |
| `machine/_limits.h` | no | **real machorun gap** |
| `setjmp.h` | no | **real machorun gap** |
| `sys/_types/_offsetof.h` | no | **real machorun gap** |
| `tgmath.h` | no | **real machorun gap** |
| `pthread/pthread.h` | no | **real machorun gap** |
| `signal.h` | **YES** | not a gap — *re-stage* |

**`signal.h` is the one to notice, and I nearly filed it in the wrong repo.**
It is absent from `scratch/sysroot_fe3` and present in machorun's `sdk/`. The
sysroot is a *reduced* copy — **361 headers against machorun's 402** — so a
header missing here is not evidence of a machorun gap. Checking both sides
before filing is what separates these two lists, and the naive measurement would
have sent someone to the wrong repository for one of seven.

**So route (A) needs six headers in machorun and a submodule-aware generator.
That is bounded, and it is a much smaller number than 305.**

### REFINED: eight of the nine demanded submodules are already fully staged

The 227-header figure is still too coarse. The chain does not demand whole
modulemaps — it demands **nine named submodules**. Checking each one's headers
individually against `scratch/sysroot_fe3`:

| submodule | headers | missing |
|---|---|---|
| `Darwin.Mach.message` | 1 | — |
| `_DarwinFoundation1._errno` | 3 | — |
| `_DarwinFoundation1._math` | 1 | — |
| `_DarwinFoundation2._stdio` | 8 | — |
| `_DarwinFoundation2._time` | 4 | — |
| `_DarwinFoundation2.sys_time` | 1 | — |
| `_DarwinFoundation3.unistd` | 4 | — |
| `_DarwinFoundation3.pthread` | 3 | **`pthread/pthread.h`** |
| `_DarwinFoundation3._signal` | 11 | **`signal.h`** — machorun HAS it |

**Eight of nine are complete today. The blocking set is two headers, one of
which is not a gap at all.**

So the five other "real machorun gaps" recorded above — `fenv.h`,
`machine/_limits.h`, `setjmp.h`, `sys/_types/_offsetof.h`, `tgmath.h` — sit in
modules the chain **never asks for** (`_fenv`, `_limits`, `_setjmp`, and
`tgmath`'s module). A pruning generator omits those modules entirely and the
chain does not notice. They remain worth staging eventually — `tgmath.h` in
particular, since clang's own includes `complex.h` unconditionally — but **they
do not block this.**

### What route (A) actually costs, then

1. **One new header in machorun**: `pthread/pthread.h`.
2. **One re-stage**: `signal.h`, which machorun already ships and
   `scratch/sysroot_*` simply does not copy. Worth fixing at the staging step
   rather than per-sysroot — the sysroot is 361 headers against machorun's 402
   and nothing reconciles them.
3. **A submodule-aware generator.** The right shape is to **prune Apple's
   modulemaps rather than flatten or copy them**: drop `header` lines whose
   file is absent, drop modules left empty, keep the structure. That satisfies
   both constraints in this document at once — never names an absent header,
   and preserves the submodule names the interfaces import.

**One caveat stated rather than buried: "every header staged" is a necessary
condition, not a sufficient one.** A submodule whose own headers are present can
still fail to compile if those headers `#include` something absent — which is
exactly how `complex.h` and `sys/attr.h` were found. The measurement above bounds
the work; it does not prove the modules build. The next step is to generate the
pruned modulemap and compile `import Darwin` against it, which needs no
swift-foundation checkout and is the cheapest possible test of the whole chain.
