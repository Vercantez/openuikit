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

Each row is true on its own terms. Read downward, the table overpromises: those
are three *different* runtimes and ABIs — Apple-objc4-on-ELF, Swift-on-ELF, and
a GNUstep-ABI Objective-C facade — and machorun needs Mach-O with Apple's ObjC
ABI. Composing them is not the last 10%; `docs/STATUS.md` §7 sets out what it
actually costs.

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

**Mach-O binaries built by Apple's toolchain execute on Linux/arm64.** Of the
20 gradeable fixtures, **18 pass and 2 are documented XFAILs** — pass meaning
stdout, stderr *and* exit status are byte-identical to the same bytes running
natively on macOS. (A 21st fixture has no baseline because macOS itself refuses
to execute it.) The corpus covers both fixup formats, both initialiser section
forms, TLV, dylib graphs with `@rpath`, data and reverse imports, pthreads, fat
binaries — and the userland rungs: the Darwin arm64 variadic ABI, the Mach
APIs, the errno / `O_*` / `struct stat` divergences, and a representative
hand-built utility that uses ctype, getopt, qsort, strftime and fgets the way
real programs do. Objective-C is the one remaining wall.

Re-measured from a fresh clone by an agent that did not write the loader, along
with the things a green suite does not by itself establish (`docs/STATUS.md`):

- **The suite can fail.** 19 mutations were introduced one at a time into the
  loader and the userland; **15 were caught, 4 were not**. The four survivors —
  bind addends in either fixup format, the weak-bind stream, and the
  Darwin→Linux `errno` direction — are shipped code that no test executes.
- **The baselines are Darwin's.** The rungs (a)–(i) baselines were committed 23
  minutes *before* the loader's first commit, so they cannot have been fitted to
  it; every run re-executes the fixtures natively on macOS before grading; and
  they were re-run by hand outside the harness as well.
- **Coverage is narrower than the scoreboard suggests.** `libSystem.B.dylib`
  exports 242 symbols and the fixtures reference 86 of them. The other 156 are
  compiled and untested.
- **Distance to real software is a number now, not an opinion.** Unmodified
  Homebrew `gsed` — a binary nobody here compiled — parses, maps and resolves
  its dependency graph under `machorun` and stops at the first of **37** libc
  symbols we do not yet export, naming it. Apple's own `/bin/ls` and
  `/usr/bin/true` are arm64e-only, so PAC blocks them before breadth does.
- **The siblings above do not yet compose.** `objc4-linux` is ELF and replaced
  Mach-O image discovery rather than shimming it; OpenUIKit is a Swift engine
  whose Objective-C facade targets the GNUstep ABI, not Apple's. Loading a
  precompiled UIKit app needs four bounded things from machorun and three
  unbuilt ones above it — `docs/STATUS.md` §7 costs them individually.

Verification also found and fixed one defect in the harness itself: with a
loader that failed to compile, `scripts/difftest.sh` printed `skipped 20` and
exited **0**. It now exits 2 when anything did not run.

The bet holds so far, but not for free. Four things about the C ABI genuinely
differ and had to be measured and translated rather than assumed
(`docs/ABI.md`): Darwin passes **every** variadic argument on the stack with an
8-byte `va_list` where Linux uses x1-x7/v0-v7 and a 32-byte one; 54 of 87 shared
`errno` names have different values, with `EAGAIN` and `EDEADLK` holding each
other's numbers; 10 of 13 `O_*` flags differ, and Darwin's `O_CREAT` **is**
Linux's `O_TRUNC`; and `struct stat` is 144 bytes against 128 with almost every
field moved. `scripts/abi_naive_probe.sh` disables each translation in turn and
shows what breaks — starting with a SIGSEGV at fault address `0x4d2`, which is
1234, the first argument of `printf("int=%d\n", 1234)`. A fifth is not a
translation at all: Darwin's `<ctype.h>` *inlines* a lookup in a 3208-byte
`_DefaultRuneLocale` into the guest, so that table's layout and contents are
part of the ABI and are recorded from Apple rather than reconstructed.

See `docs/STATUS.md` for the scoreboard and the ranked blockers, `docs/ABI.md`
for the measured ABI boundary, `docs/PLAN.md` for the design,
`docs/UNIMPLEMENTED.md` for every stub that aborts.

```sh
scripts/build.sh          # loader (ELF PIE) + darwin/*.dylib (Mach-O, on Linux)
scripts/difftest.sh       # macOS oracle vs machorun-on-Linux, one row per fixture
scripts/abi_naive_probe.sh # what breaks if the userland forwards naively
build/machorun ./prog     # run one
```
