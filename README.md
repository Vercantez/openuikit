# machorun

**Run precompiled Mach-O binaries on Linux/arm64.**

A Mach-O loader and Darwin userland for Linux — Darling's goal, ARM64-first,
built around a different trade: *replace* libSystem rather than emulate Darwin
syscalls.

## Why this, and why now

Three of the hard pieces already exist in sibling projects:

| piece | where | state |
|---|---|---|
| Objective-C runtime | **here**, `darwin/usr/lib/libobjc.A.dylib` | Apple's real objc4 built as **Mach-O on Linux**, 4 patches, **41/44** differential tests vs Apple's shipping runtime |
| UIKit | `~/uikit` (OpenUIKit) | pixel-exact vs real UIKit, 108/108 oracle scenes |
| Quartz 2D + CoreAnimation | `~/quartz` | 97.5/100 vs Apple's frameworks |
| **Mach-O loader + Darwin userland** | **here** | **the missing piece** |

Each row is true on its own terms. Read downward, the table used to overpromise
badly, and one of the three reasons is now gone. It said `~/objc4-linux`, a
44/44 port of Apple's objc4 to **ELF** — a different format and a different
runtime from the one a precompiled Darwin binary carries. That project is now
**retired**: the same objc4 drop builds here as a Mach-O dylib with 4 patches
instead of 9, and `docs/OBJC4_MACHO.md` is the accounting. It is retired rather
than deleted because it is still the only tree that runs all 44 tests; the two
gaps are an unwinder over `__TEXT,__unwind_info` and guest `dlopen`, and
neither is about Objective-C.

The other two rows still do not compose: OpenUIKit is a Swift engine whose
Objective-C facade targets the **GNUstep** ABI, not Apple's, and swiftc on
Linux emits ELF. `docs/STATUS.md` §7 sets out what closing that costs — with
step 1 of its list, a `libobjc.A.dylib` machorun can bind against, now done.

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
darwin/     our Mach-O dylibs (libSystem and friends) built on Linux
sdk/        our header-only + .tbd-only SDK -- replaces Apple's, see PROVENANCE.md
vendor/     Apple's objc4 (pristine) + the SDK-private headers it needs
patches-macho/  the 4 patches objc4 needs to build as Mach-O on Linux
tests/      Mach-O fixtures + expected macOS output, and the 44-test objc4 corpus
harness/    run-on-macOS / run-on-linux runners and the differ
scripts/    build + difftest entry points
docs/       design, ABI notes, status
```

## Status

**Mach-O binaries built by Apple's toolchain execute on Linux/arm64.** Of the
20 gradeable fixtures, **19 pass and 1 is a permanent XFAIL** (`01_exit_raw`,
raw `svc` — the deliberate boundary of the replace-libSystem bet) — pass
meaning stdout, stderr *and* exit status are byte-identical to the same bytes
running natively on macOS. (A 21st fixture has no baseline because macOS itself
refuses to execute it.) The corpus covers both fixup formats, both initialiser
section forms, TLV, dylib graphs with `@rpath`, data and reverse imports,
pthreads, fat binaries — and the userland rungs: the Darwin arm64 variadic ABI,
the Mach APIs, the errno / `O_*` / `struct stat` divergences, and a
representative hand-built utility that uses ctype, getopt, qsort, strftime and
fgets the way real programs do.

**Objective-C is no longer the wall.** Apple's objc4 builds as a Mach-O
`darwin/usr/lib/libobjc.A.dylib` **on Linux** with 4 patches, driven through
dyld's own image-notify protocol rather than a bespoke seam, and scores
**41/44** on a differential corpus run against Apple's shipping runtime. The 3
failures are C++ exceptions (×2) and `dlopen` (×1) — pre-existing loader gaps
that block plain C++ equally, and neither is attributable to objc4.
`docs/OBJC4_MACHO.md` is the accounting, including what got *harder*.

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
- **The siblings above do not yet compose.** That verification listed
  `objc4-linux` first, because it was ELF and had *replaced* Mach-O image
  discovery rather than shimming it. That one is now closed the other way
  round: the ELF port is retired and objc4 is built here as Mach-O, which is
  step 1 of `docs/STATUS.md` §7. OpenUIKit remains a Swift engine whose
  Objective-C facade targets the GNUstep ABI, not Apple's, and swiftc on Linux
  emits ELF. §7's steps 5–7 are untouched and are still the larger half.

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

**Xcode is no longer a build input.** `sdk/` is our own header-only,
`.tbd`-only SDK: 355 headers, of which 336 come from eleven **pinned**
`apple-oss-distributions` releases (all redistributable) or from running xnu's
own published generator, 4 from objc4 itself, and **19 are clean-room headers we
wrote**. Apple's libc++ — 67% of the old surface — is gone, replaced by stock
LLVM 18 with three `-D` flags. `scripts/build_objc4.sh` takes `-isysroot sdk/` by
default, and everything above was re-measured after the switch: **32 objects, 0
failures; 41/44; 19 pass / 1 xfail / 1 no-oracle.**

That also buys a capability that did not exist before: **a guest can be compiled
and linked entirely on Linux** — no Apple header, no Apple library — and run
under machorun. `scripts/sdk_abi_probe.sh` does exactly that with a program that
prints the *ABI* rather than behaviour (`struct stat`'s field offsets, 46 `errno`
values, 14 `O_*` values, `sizeof(va_list)`, the first bytes of
`_DefaultRuneLocale`), and requires it to be **byte-identical** to the same
source built by Apple's clang against Apple's SDK and run natively on macOS. It
is: 149 lines, no diff.

The fixtures in `tests/bin/` **stay Apple-built**, and this SDK must not be used
to change that. They are the precompiled Darwin bytes the whole project exists to
run; relinking them with `ld64.lld` against our own stubs would prove only that
our linker agrees with our loader. `sdk/PROVENANCE.md` §6 says so at length.

Assembling the SDK also found a failure mode worth naming, because it is the
kind a green suite cannot catch: xnu's published headers gate per-product
settings on `XNU_PLATFORM_<name>`, which Apple's install step resolves with
`unifdef`. With none selected, `MACH_VM_MAX_ADDRESS_RAW` silently becomes the
embedded 64 GB value instead of macOS's 128 TB, and **nothing fails to compile**.
`sdk/patches/` fixes it.

The sentence that used to end that paragraph — "the ABI probe exists to catch
the next one" — did not survive independent verification, and the correction is
the most useful thing in `docs/STATUS.md` §9. The probe did not *print*
`MACH_VM_MAX_ADDRESS_RAW`, so forcing that constant back to the embedded value
passed `build_objc4` (32 objects), `gen_tbd` (all three checks), the probe
itself, **and** the 44-test corpus at 41/44. Nothing in the repository noticed.
It prints it now, along with the `__DARWIN_ONLY_*` conformance settings and the
`__DARWIN_SUF_*` suffixes, the baseline was re-recorded on the macOS oracle, and
the mutation now fails. The probe is **163 lines**, still byte-identical.

Two more things that verification broke and are now fixed:
`scripts/sdk_stage.sh --verify` *could not fail* — it rewrote
`sdk/CHECKSUMS.sha256` from a fresh fetch and then compared that file against a
second fetch of the same bytes, so a poisoned row was silently erased and a
moved upstream tag would have been recorded as the new truth. It now re-fetches
all 332 files, treats the committed record as read-only, and dies with a diff.
And `sort -k3` without `LC_ALL=C` made that record non-reproducible: a restage on
another machine moved 18 rows without changing a single hash.

**What `sdk/` does not cover.** It is 355 headers against Apple's 3,470, three
`.tbd` stubs against 529, and **zero** of Apple's 294 frameworks — the set
`vendor/objc4` and the ABI probe actually reach, and no more. There is no
`<signal.h>` (only `<sys/signal.h>`), no `<setjmp.h>`, `<dirent.h>`,
`<complex.h>`, `<semaphore.h>`, `<regex.h>`, `<termios.h>` or `<poll.h>`; no
networking at all; no `<sys/sysctl.h>` or kqueue; no CoreFoundation and no
Foundation. `usr/include/c++/v1` is absent on purpose. `docs/STATUS.md` §9.4 is
the measured list.

See `docs/STATUS.md` for the scoreboard and the ranked blockers, `docs/ABI.md`
for the measured ABI boundary, `docs/OBJC4_MACHO.md` for Apple's objc4 as
Mach-O (and §9 for what was inherited from the retired ELF port),
`sdk/PROVENANCE.md` for where every header came from and what each clean-room
one omits, `docs/SDK_SURVEY.md` for the measurement that preceded it (and its
corrections), `docs/PLAN.md` for the design, `docs/UNIMPLEMENTED.md` for every
stub that aborts.

```sh
scripts/build.sh everything # loader (ELF PIE) + darwin/*.dylib + libobjc + sdk/*.tbd
scripts/build.sh            # the same minus objc4, which is a minute of C++
scripts/sdk_stage.sh        # regenerate sdk/usr/include from its 11 pinned sources
scripts/sdk_stage.sh --verify  # re-fetch all 332 and check the COMMITTED sha256s
scripts/gen_tbd.sh          # sdk/usr/lib/*.tbd from our own dylibs, and 3 checks
scripts/difftest.sh         # macOS oracle vs machorun-on-Linux, one row per fixture
scripts/objc44.sh           # the 44-test objc4 differential corpus under machorun
scripts/sdk_abi_probe.sh    # sdk/ vs Apple's SDK, on the ABI, byte for byte
scripts/abi_naive_probe.sh  # what breaks if the userland forwards naively
build/machorun ./prog       # run one
```

**On a fresh clone, run `scripts/build.sh everything` first** — inside the
container, since `darwin/`, `libobjc` and the `.tbd`s are Linux Mach-O build
products. `scripts/difftest.sh` builds the loader and the two small dylibs for
you but deliberately *not* objc4 (a minute of Objective-C++ on every run), so on
a tree where `libobjc.A.dylib` has never been built `09_objc` is a red **FAIL**,
not the documented PASS. That is measured, not theorised: `git clone &&
scripts/difftest.sh` gives **18 pass / 1 fail**; with `build.sh everything`
first it gives **19 pass / 0 fail / 1 xfail / 1 no-oracle**.
