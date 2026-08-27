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
