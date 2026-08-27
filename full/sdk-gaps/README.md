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
