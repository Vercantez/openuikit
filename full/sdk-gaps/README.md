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

## A third gap, not a header

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
