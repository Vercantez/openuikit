# Artifacts

Built on Ubuntu 24.04 aarch64 with the stock swift.org `swift-6.2.4-RELEASE`
Linux toolchain. **No Xcode, no Apple toolchain, no macOS.** Reproduce with the
sequence in `../docs/BUILD_LOG.md` §7.

## THERE ARE EXACTLY TWO STAGING SOURCES HERE, AND THIS IS THE LIST

`machorun scripts/stage_swiftcore.sh <dir>` will install from any directory
shaped like the table below. **Nothing gates what sits in one.** On 2026-08-27 a
`libswiftcompat.dylib` with a `pthread_main_np` that returned a constant 1 was
parked in one of these, one command from installation, and every freshness check
passed because it was *newer* than what was deployed rather than older
(`../docs/BUILD_LOG.md` §12). So the directories are enumerated here, and adding
a third without adding a row is the mistake this list exists to prevent.

| directory | stageable | contents |
|---|---|---|
| `.` (this one) | **yes** — the canonical source; matches what machorun has staged | `swift-macosx/`, `libswiftcompat.dylib` |
| `concurrency/` | **yes** | the same, plus `libswift_Concurrency.dylib` |

`libswiftCore.dylib` is **byte-identical in both** and its export set is
identical to every earlier build (30,723 symbols, 0 differing), so which one you
stage from cannot change the Swift surface.

`libswiftCore.machorun-wideisa.dylib` is **not** a staging source: it is a
one-off with the isa mask rewritten, kept for the §8 analysis.

## What each file is

| file | what |
|---|---|
| `swift-macosx/arm64/libswiftCore.dylib` | the Swift standard library, Mach-O 64-bit **arm64**, install name `/usr/lib/swift/libswiftCore.dylib`, 30,723 exported symbols |
| `swift-macosx/Swift.swiftmodule/arm64-apple-macos.*` | the matching module / interface, so `swiftc -target arm64-apple-macos` can compile against it |
| `libswiftcompat.dylib` | **34 symbols** — the gap between libswiftCore/libswift_Concurrency's imports and machorun's self-hosted Darwin userland (see `../sdk/compat/swiftcompat.c`). It is asserted **disjoint** from that userland at build time; ten symbols were deleted on 2026-08-27 when they stopped being a gap and became duplicates |
| `concurrency/.../libswift_Concurrency.dylib` | still linked against the **old** `.tbd`s — three `__cxxabiv1` vtables are flat (`dynamically looked up`) rather than `from libc++`. Latent, not live: it is not staged. See §16 |

## The `__gxx_personality_v0` relink (2026-08-27)

`libswiftCore.dylib` was rebuilt after machorun's `gen_tbd.sh` learned to vend
what a dylib **re-exports** (machorun `559356b`). Six imports moved from a
load-order-dependent binding to a two-level one naming libc++:

```
                                        before                  after
__ZTVN10__cxxabiv117__class_type_infoE   (dynamically looked up)  (from libc++)
__ZTVN10__cxxabiv119__pointer_type_infoE (dynamically looked up)  (from libc++)
__ZTVN10__cxxabiv120__function_type_infoE(dynamically looked up)  (from libc++)
__ZTVN10__cxxabiv120__si_class_type_infoE(dynamically looked up)  (from libc++)
__ZdlPvmSt11align_val_t                  (dynamically looked up)  (from libc++)
___cxa_demangle                          (dynamically looked up)  (from libc++)
___gxx_personality_v0                    (from libSystem)         (from libc++)
```

The last line was the ask — Apple's shipped libswiftCore names libc++, ours
named libSystem. The other six are the larger win: **libswiftCore can no longer
be shadowed on those symbols by load order at all**, because it now names the
library it wants. Deleting them from the shim fixed today's process; this makes
the class of bug unreachable for this image.

## To use

Put `libswiftCore.dylib` at `darwin/usr/lib/swift/` and `libswiftcompat.dylib`
at `darwin/usr/lib/` under a machorun tree — or just run
`machorun scripts/stage_swiftcore.sh /path/to/this/dir`, which does both and
checks the format first.

Guests must still link **`-lswiftCore` before `-lSystem`**;
`../scripts/run_under_machorun.sh` explains why.
