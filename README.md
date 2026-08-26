# machorun

**Run precompiled Mach-O binaries on Linux/arm64.**

A Mach-O loader and Darwin userland for Linux — Darling's goal, ARM64-first,
built around a different trade: *replace* libSystem rather than emulate Darwin
syscalls.

## Why this, and why now

Three of the hard pieces already exist in sibling projects:

| piece | where | state |
|---|---|---|
| Objective-C runtime | `~/objc4-linux` | Apple's real objc4, running on Linux, **44/44 differential tests vs Apple's shipping runtime** |
| UIKit | `~/uikit` (OpenUIKit) | pixel-exact vs real UIKit, 108/108 oracle scenes |
| Quartz 2D + CoreAnimation | `~/quartz` | 97.5/100 vs Apple's frameworks |
| **Mach-O loader + Darwin userland** | **here** | **the missing piece** |

Verified before starting (2026-08-25): **Linux can produce Mach-O.**
`clang -target arm64-apple-macos11 -c` emits Mach-O objects (magic
`cf fa ed fe`) and stock `ld64.lld-18` links dylibs — and macOS's own `otool`,
`file` and `nm` accept the result as a valid arm64 Mach-O shared library.
Note Swift's *bundled* lld is patched to refuse macOS linking; use Ubuntu's
`lld-18`.

## Why not Darling

Darling is the inspiration, not a dependency. It is **x86-64 only** — ARM64
runtime/ABI support is still an open issue upstream (as of 2026-08). Since
iOS binaries are arm64 and this runs on arm64 Linux, **no CPU emulation is
needed at all** — the work is loader and ABI, not instruction translation.
Darling carries a decade of x86-64 macOS assumptions we would have to unpick.

Its source remains valuable as a reference, particularly its Darwin header
shims and its `dyld` reimplementation.

## The core bet: replace libSystem, don't emulate syscalls

Darling emulates Mach traps and Darwin syscalls beneath Apple's own
`libSystem`. We do the opposite: **ship our own `libSystem.B.dylib`**, built
on Linux as Mach-O, whose functions forward to glibc. A binary that calls
`_printf`, `_malloc`, `_pthread_create` then lands in our code, and no
syscall translation happens.

This works because we control what the app links against. It breaks for
binaries that inline raw syscalls or reach for Mach APIs
(`mach_task_self`, `vm_allocate`) — those get implemented on top of Linux
primitives, which is a bounded list rather than a whole kernel ABI.

## Scope

**Milestone 1 (the tractable one):** binaries *you* build with Apple's
toolchain, linking a framework surface we provide. Simple, self-contained,
and each new framework is incremental.

**Not milestone 1:** arbitrary App Store apps. They are FairPlay-encrypted
and link dozens of private frameworks. That is Darling's decade, and pretending
otherwise would set a dishonest bar.

## Method: differential testing against macOS

Same discipline as the sibling projects, and it applies unusually well here:
**macOS runs the binary natively.** Every test is a Mach-O built once, run on
macOS to record expected output, then run under `machorun` on Linux — outputs
must match exactly. Never "it looked right"; always a diff against the real
platform executing the same bytes.

## Layout

```
src/        the loader: Mach-O parsing, mapping, fixups, TLS, entry
include/    public interface
darwin/     our Mach-O dylibs (libSystem and friends) built on Linux
tests/      Mach-O fixtures + expected macOS output
harness/    run-on-macOS / run-on-linux runners and the differ
scripts/    build + difftest entry points
docs/       design, ABI notes, status
```

## Status

**Mach-O binaries built by Apple's toolchain execute on Linux/arm64.** 13 of 14
runnable fixtures are byte-identical to the same bytes running natively on
macOS, covering both fixup formats, initialisers, TLV, dylib graphs with
`@rpath`, data and reverse imports, pthreads, and fat binaries. Objective-C is
the one remaining wall.

See `docs/STATUS.md` for the scoreboard and the ranked blockers, `docs/PLAN.md`
for the design, `docs/UNIMPLEMENTED.md` for every stub that aborts.

```sh
scripts/build.sh          # loader (ELF PIE) + darwin/*.dylib (Mach-O, on Linux)
scripts/difftest.sh       # macOS oracle vs machorun-on-Linux, one row per fixture
build/machorun ./prog     # run one
```
