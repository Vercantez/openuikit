# C ABI divergences between Darwin/arm64 and Linux/AArch64

Not runtime bugs. These are places where the **C compiler** targets a
different ABI on the two platforms, which shows up in Objective-C type
encodings and therefore in the differential corpus. Recorded here so that the
harness's decision to pin or not pin each one is visible.

All values measured with Apple clang 17 (`-target arm64-apple-macos13`) and
clang 18 (`-target aarch64-unknown-linux-gnu`).

| thing | Darwin/arm64 | Linux/AArch64 | how the corpus handles it |
|---|---|---|---|
| plain `char` signedness | signed | **unsigned** (`__CHAR_UNSIGNED__=1`) | **pinned**: both runners pass `-fsigned-char` |
| `BOOL` | `bool` (`__OBJC_BOOL_IS_BOOL=1`) | clang says `0` → `signed char` | **changed in the port**: `patches/0009` forces `bool` |
| `long double` | 8 bytes (alias for `double`) | **16 bytes** (IEEE binary128) | **not pinned, not diffable**: recorded here |
| `@encode(long double)` | `D` | `D` | identical; nothing to do |

## plain `char`

`@encode(char)` is `"c"` on Darwin and `"C"` on Linux, and that letter appears
in every method type string, ivar type and property attribute string that
mentions a `char`. Four corpus tests (016, 017, 018, 033) diverged on it.

It is a compiler fact, not a runtime fact — objc4 copies the string clang
emitted. Pinning `-fsigned-char` on **both** sides is the same kind of control
as the already-pinned `-O0` and `-fno-objc-arc`: it removes a difference that
is not the runtime, so the diff measures the runtime. Verified to be a no-op
on the Darwin side — re-recording the whole oracle with the flag added changed
exactly one line, and that line was the `long double` edit below.

A real Linux Objective-C program is of course free to use unsigned `char`; the
runtime handles either.

## `BOOL`

clang predefines `__OBJC_BOOL_IS_BOOL=0` for a Linux triple, because it has no
opinion about a runtime it does not ship with. This project supplies that
runtime, so it is our call, and the call is `bool`:

* Every modern Apple target — arm64 macOS, iOS, tvOS, watchOS — uses `bool`.
  Only 32-bit and x86_64 macOS keep the historical `signed char`, for binary
  compatibility that does not exist on Linux.
* `@encode(BOOL)` becomes `"B"` and property attributes read `"TB"`, matching
  the arm64 Darwin oracle.
* Swift's `ObjCBool` bridging assumes one-byte `bool` semantics on arm64, and
  Swift interop is the motivating goal.

Implemented as a `TARGET_OS_LINUX` branch in `runtime/objc.h`
(`patches/0009-objc-h-bool-is-bool-on-linux.patch`) that takes precedence over
the `__OBJC_BOOL_IS_BOOL` check.

## `long double`

Darwin/arm64 defines `long double` as a synonym for `double`; the AArch64
Procedure Call Standard defines it as IEEE binary128. `sizeof(long double)` is
therefore **8 on Darwin and 16 on Linux**, and no compiler flag changes it
(`-mlong-double-64` exists only for x86 and PowerPC).

Both platforms encode it as `'D'`, so nothing the runtime does is affected —
`method_copyArgumentType`, property attributes and `class_getInstanceSize` all
behave identically. `tests/033-type-encoding.m` therefore asserts the
relationship (`sizeof(long double) >= sizeof(double)`) rather than the number,
with the two measured values recorded here. Diffing the number would report a
compiler fact as a runtime failure forever.
