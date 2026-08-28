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
| Quartz 2D + CoreAnimation | **here**, `darwin/usr/lib/libquartz.dylib` | `~/quartz` built as **Mach-O on Linux**, **0 patches**; three precompiled fixtures — one plain C, two Objective-C — draw **byte-identical PNGs** on both platforms |
| UIKit | `~/uikit` (OpenUIKit) | pixel-exact vs real UIKit, 108/108 oracle scenes — and **not usable here**, see below |
| **Mach-O loader + Darwin userland** | **here** | **the missing piece** |

Each row is true on its own terms. Read downward, the table used to overpromise
badly, and two of the three reasons are now gone.

It said `~/objc4-linux`, a 44/44 port of Apple's objc4 to **ELF** — a different
format and a different runtime from the one a precompiled Darwin binary carries.
That project is now **retired**: the same objc4 drop builds here as a Mach-O
dylib with 4 patches instead of 9, and `docs/OBJC4_MACHO.md` is the accounting.
It is retired rather than deleted because it is still the only tree that runs
all 44 tests; the two gaps are an unwinder over `__TEXT,__unwind_info` and guest
`dlopen`, and neither is about Objective-C.

It also said `~/quartz`, whose 97.5/100 is measured on macOS against Apple's own
frameworks and said nothing about Linux. That row moved here too:
`scripts/build_quartz.sh` builds it as `/usr/lib/libquartz.dylib` on Linux with
**zero patches to its source**, and `tests/bin/quartz` — a plain C Mach-O
compiled by Apple's clang, no Objective-C anywhere in it — writes the **same
26,861-byte PNG, byte for byte**, run natively on macOS and run under machorun
on Linux. `docs/QUARTZ_MACHO.md` is the accounting, including the three holes
that opened in *our* userland to make it work (libm, libc++'s out-of-line
members, and a header the SDK's `-DNDEBUG`-only closure could not see).

**The remaining row still does not compose, and the reason has been measured
rather than repeated.** The claim in circulation was "swiftc on Linux cannot
emit Mach-O". That is **false**, and `docs/STATUS.md` §11.5 is the measurement:
on the official `swift:6.2-noble` image, arm64, offline,
`swiftc -parse-stdlib -target arm64-apple-macos11 -c` produces a perfectly good
arm64 Mach-O object (`cf fa ed fe`), with an ELF for the Linux triple as a
control. The Swift **backend is not the wall**.

The wall is the **standard library**. `/usr/lib/swift/` on Linux carries `linux`
and `embedded` and no `macosx`, so without `-parse-stdlib` the same command dies
with *"unable to load standard library for target 'arm64-apple-macos11'"* — and
any source that names `Int`, `String` or `print`, which is all of OpenUIKit,
cannot be type-checked for a Darwin triple at all. That is a distribution and
ABI problem, not a code-generation one; it is not something machorun can fix
from this side; and closing it means either cross-building `libswiftCore` for
`arm64-apple-macos` on Linux (which needs a Darwin SDK this repository
deliberately does not have) or giving machorun ELF-dylib bridging. On top of
which OpenUIKit's Objective-C facade targets the **GNUstep** ABI, not Apple's,
which is a second, independent wall.

**So OpenUIKit is not part of this and cannot be today.** What runs is
`~/quartz`, the C++ engine OpenUIKit itself sits on. `docs/STATUS.md` §7 sets
out what the rest costs — with step 1 of its list, a `libobjc.A.dylib` machorun
can bind against, now done.

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
vendor/     Apple's objc4 (pristine) + the SDK-private headers it needs,
            and ~/quartz (pristine) -- see each PROVENANCE.md
patches-macho/  the 4 patches objc4 needs to build as Mach-O on Linux
patches-quartz/ the 0 patches quartz needs -- empty, and that is the measurement
tests/      Mach-O fixtures + expected macOS output, and the 44-test objc4 corpus
harness/    run-on-macOS / run-on-linux runners and the differ
scripts/    build + difftest entry points
docs/       design, ABI notes, status
```

## Status

**Mach-O binaries built by Apple's toolchain execute on Linux/arm64.** Of the
21 gradeable fixtures, **20 pass and 1 is a permanent XFAIL** (`exit_raw`,
raw `svc` — the deliberate boundary of the replace-libSystem bet) — pass
meaning stdout, stderr *and* exit status are byte-identical to the same bytes
running natively on macOS. (A 22nd fixture has no baseline because macOS itself
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

**On two different arm64 microarchitectures.** The same 19/1/1, the same 41/44
and the same three byte-identical PNGs on an AWS **Graviton3** (c7g, Neoverse-V1,
Ubuntu 24.04, 4 KB pages), building natively there with no macOS in the build.
Getting there cost one real bug: `os_unfair_lock` identified a lock's owner by
half of a `pthread_self()` pointer, two threads collided in the surviving bits
about half the time on Graviton, and a normal acquisition then read as recursive
acquisition by the owner. Apple silicon had never collided, so a suite that runs
each fixture once could not see it. `docs/STATUS.md` §12 is the write-up;
`scripts/stress_unfair_lock.sh` is the gate, and it is verified to fail on the
bug rather than merely to pass without it.

**And a precompiled Darwin binary now DRAWS.** `~/quartz` — the portable
Quartz 2D + Core Animation reimplementation, C++17, 507-symbol `QZ*` C API —
builds as `darwin/usr/lib/libquartz.dylib` on Linux with **zero patches to its
source**, 37 translation units, 0 failures. `tests/bin/quartz` is a plain C
Mach-O with **no Objective-C in it at all**, compiled by Apple's clang against
Apple's SDK, that calls `QZBitmapContextCreate`, draws nine stages (fills,
alpha compositing, cubic Béziers, dashed strokes, linear and radial gradients, a
rotation, an even-odd clip) and writes a PNG:

**And so does a precompiled *Objective-C* Darwin binary.** `objc_quartz` is
the smoke test — one root class, one ivar, one message, one ellipse — and
`objc_shapes` is the milestone: a protocol, a root class, three levels of
inheritance with `[super]` (`objc_msgSendSuper2`), a category on an
already-compiled class, six `+load`s, lazy `+initialize`, an `objc_msgSend` with
a four-double HFA return, and a **polymorphic draw loop typed by the protocol**,
so which `-drawInContext:` runs is decided by each object's `isa` and by nothing
the compiler could have known. Every pixel in it comes out of a message send.

```
                      macOS, natively            machorun on Linux/arm64
quartz             26861  96aa747a85f6c35f    26861  96aa747a85f6c35f
objc_quartz         2678  32a7e67a4139e108     2678  32a7e67a4139e108
objc_shapes        11909  a7ca5744d100b911    11909  a7ca5744d100b911
stage checksums       identical (9 / 3 / 5)      exit 0 / 0 everywhere
```

`scripts/quartz_pixel.sh` runs both sides — it re-executes the macOS oracle
every time rather than trusting the committed baseline — and each fixture prints
a checksum of the whole framebuffer after every stage, so a divergence is
localised to a drawing stage on stdout before the PNG is even compared; if it
still gets to the PNG, `harness/pngdiff.c` localises it to a rectangle of
pixels.

The two sides are genuinely two different builds, which is the point: the oracle
loads an Apple-clang `libquartz.dylib` (388832 bytes) and Apple's own shipping
`libobjc`, while Linux loads a clang-18 Mach-O `libquartz.dylib` (388480 bytes,
different sha256) and our Mach-O build of objc4. Same source, two toolchains,
two operating systems, identical bytes out.

Zero patches to quartz did not mean zero work; it moved the work to our side of
the boundary, which is where the project wants it. `libSystem.B.dylib` had **no
libm at all** (Darwin has no `-lm` — libSystem re-exports `libsystem_m.dylib`),
`libc++.1.dylib` had 14 symbols against the 12 out-of-line `std::string`,
`__sort`, `to_string` and `__next_prime` entries LLVM's headers declare and
refuse to inline, and the SDK was missing `_assert.h` because every previous
consumer compiled `-DNDEBUG`. `docs/QUARTZ_MACHO.md` is the accounting,
including the two limits a green PNG does not remove: this is `QZ*` and not
`CG*`, and glibc's libm agreeing with Apple's Libm on one workload is not a
proof that it always will.

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
- **Coverage is narrower than the scoreboard suggests, and hosting quartz made
  it narrower still.** `libSystem.B.dylib` exported 242 symbols then and exports
  **441** now (libm alone is 113 of them); the fixture corpus grew by three in
  the same period. **89** exports are referenced by at least one fixture, so
  **352 — 80% — are compiled and never called by any test**, against 64% before.
  `libobjc.A.dylib` exports 418 and `tests/objc44/` reaches 116;
  `libquartz.dylib` exports 507 and the drawing fixtures reach 36. This is still
  the single biggest gap between "the suite is green" and "the userland works",
  and it got wider, not narrower.
- **Distance to real software is a number now, not an opinion.** Unmodified
  Homebrew `gsed` — a binary nobody here compiled — parses, maps and resolves
  its dependency graph under `machorun` and stops at the first of **37** libc
  symbols we do not yet export, naming it. Apple's own `/bin/ls` and
  `/usr/bin/true` are arm64e-only, so PAC blocks them before breadth does.
- **The siblings above do not yet compose.** That verification listed
  `objc4-linux` first, because it was ELF and had *replaced* Mach-O image
  discovery rather than shimming it. That one is now closed the other way
  round: the ELF port is retired and objc4 is built here as Mach-O, which is
  step 1 of `docs/STATUS.md` §7. `~/quartz` composed too, and out of order —
  §7 put CoreGraphics/CoreAnimation last, at step 7, and the engine underneath
  it turned out to run today, before Foundation and without any Objective-C at
  all, because it is portable C++. OpenUIKit did not and cannot: see the Swift
  measurement above. §7's steps 5–7 are otherwise untouched and are still the
  larger half.

A third verification (`docs/STATUS.md` §11) attacked the drawing gate rather
than the loader, and it holds: a **one-pixel, one-channel, one-level** change to
quartz's rasteriser fails the differential and `pngdiff` names the pixel;
breaking category attachment in objc4 fails `objc_shapes` while
`objc_quartz` stays byte-identical, which is exactly the bisection the smoke
fixture exists for; and making a class's own method list invisible — so
overrides fall through to the superclass — moves the **framebuffer checksum**,
proving the picture really is produced by dynamic dispatch. A baseline with one
byte flipped is reported as `BASELINE-DRIFT` and cannot be scored PASS even when
Linux matches the live oracle.

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
`.tbd`-only SDK: **356 headers = 332** from eleven **pinned**
`apple-oss-distributions` releases (all redistributable) **+ 1** produced by
running xnu's own published generator **+ 4** from objc4 itself **+ 19
clean-room headers we wrote**. `sdk/CHECKSUMS.sha256` pins 333 of them; the
other 23 are vouched for by git alone, by design. (Earlier statements of this
census in this file and in `docs/STATUS.md` §9 did not add up — 337+4+19 is 360,
and 332+19+4 is 355. The figures above are re-counted from `sdk/MANIFEST.tsv`.)
Apple's libc++ — 67% of the old surface — is gone, replaced by stock
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
all 333 files, treats the committed record as read-only, and dies with a diff.
And `sort -k3` without `LC_ALL=C` made that record non-reproducible: a restage on
another machine moved 18 rows without changing a single hash.

**What `sdk/` does not cover.** It is 356 headers against Apple's 3,470, three
`.tbd` stubs against 529, and **zero** of Apple's 294 frameworks — the set
`vendor/objc4` and the ABI probe actually reach, and no more. There is no
`<signal.h>` (only `<sys/signal.h>`), no `<setjmp.h>`, `<dirent.h>`,
`<complex.h>`, `<semaphore.h>`, `<regex.h>`, `<termios.h>` or `<poll.h>`; no
networking at all; no `<sys/sysctl.h>` or kqueue; no CoreFoundation and no
Foundation. `usr/include/c++/v1` is absent on purpose. `docs/STATUS.md` §9.4 is
the measured list.

## What runs end to end today — and what it does not

**Runs.** A precompiled arm64 Mach-O executable, built on macOS by Apple's clang
against Apple's SDK and **never relinked**, is mapped and fixed up by our loader
on Linux/arm64; binds against our Mach-O `libSystem.B.dylib`, our Mach-O build of
Apple's objc4, our Mach-O build of LLVM's libc++ out-of-line members, and
`~/quartz` built as a Mach-O dylib from **unpatched** sources; registers its
classes, categories and protocols through dyld's own ObjC image-notify protocol;
runs `+load` before `main`; dispatches `objc_msgSend` and `objc_msgSendSuper2`
polymorphically over a heterogeneous collection; rasterises through a CPU
rasteriser that reaches libm; encodes a PNG; and writes a file whose bytes are
**identical** to the bytes the same binary writes on macOS.

**Does not cover.** None of this is implied by the green, and all of it is
measured rather than guessed:

- **`QZ*`, not `CG*`.** There is no `CoreGraphics.framework`, no
  `CoreFoundation`, no `Foundation`, no `UIKit`. A binary linked against Apple's
  frameworks resolves none of its imports.
- **Swift runs; OpenUIKit does not yet.** This bullet used to read *"No Swift
  and no OpenUIKit. Not a machorun gap and not fixable here — the Linux Swift
  toolchain ships no Darwin standard library."* The premise was true of the
  *shipped* toolchain and wrong as a conclusion: `~/swiftcore-macho` cross-built
  `libswiftCore.dylib` as a Darwin arm64 Mach-O **on Linux** from swift.org
  6.2.4 source, and rung (q) — `scripts/swift_gate.sh` — runs Swift classes,
  generics, protocol existentials, dynamic casts and ARC under machorun with
  output byte-identical to macOS. What OpenUIKit still lacks is **Foundation**
  and a `CG*`/`UIKit` surface, not a Swift runtime. Two narrower holes are named
  in `docs/UNIMPLEMENTED.md`: an *Apple-built* Swift binary still does not load
  here (`#swift-compat`), and Swift code that unwinds hits the same
  compact-unwind wall as `objc44`'s three failures.
- **No C++/ObjC exceptions and no `dlopen`** — the three `objc44` failures. Both
  are loud aborts, never silent wrong answers.
- **80% of `libSystem`, 72% of `libobjc` and 93% of `libquartz` are exported,
  compiled, and untested here.**
- **No window, no display, no compositor.** "Draws" means "rasterises to a
  bitmap and writes a PNG". There is no `UIScreen` path and nothing puts a pixel
  on a screen.
- **No arm64e/PAC, no FairPlay, no App Store app**, and no unmodified
  third-party binary yet: `gsed` is still 37 libc symbols away.

See `docs/STATUS.md` for the scoreboard and the ranked blockers, `docs/ABI.md`
for the measured ABI boundary, `docs/OBJC4_MACHO.md` for Apple's objc4 as
Mach-O (and §9 for what was inherited from the retired ELF port),
`docs/QUARTZ_MACHO.md` for `~/quartz` as Mach-O and the pixel differential,
`sdk/PROVENANCE.md` for where every header came from and what each clean-room
one omits, `docs/SDK_SURVEY.md` for the measurement that preceded it (and its
corrections), `docs/PLAN.md` for the design, `docs/UNIMPLEMENTED.md` for every
stub that aborts.

```sh
scripts/build.sh everything # loader (ELF PIE) + darwin/*.dylib + libobjc + libquartz + sdk/*.tbd
scripts/build.sh            # the same minus objc4 and quartz, ~2 minutes of C++
scripts/sdk_stage.sh        # regenerate sdk/usr/include from its 11 pinned sources
scripts/sdk_stage.sh --verify  # re-fetch all 333 and check the COMMITTED sha256s
scripts/gen_tbd.sh          # sdk/usr/lib/*.tbd from our own dylibs, and 3 checks
                            #   LINUX ONLY. On macOS it REFUSES and prints the docker
                            #   line, because BSD comm would make it report a FALSE
                            #   regression rather than a result (#95).
scripts/gen_tbd.sh --check  # ^ those checks ONLY, writing nothing. RUN IT AS A GATE:
                            #   CHECK 3 otherwise runs only inside build.sh, where its
                            #   output scrolls past, and it was silently inert for two
                            #   days without any gate run being able to notice.
scripts/difftest.sh         # macOS oracle vs machorun-on-Linux, one row per fixture
scripts/objc44.sh           # the 44-test objc4 differential corpus (run INSIDE the container)
scripts/stress_unfair_lock.sh  # the lock-owner regression gate; objc44.sh ends with it
scripts/quartz_pixel.sh     # the 3 drawing fixtures, macOS vs machorun -- the PNGs must match
scripts/stage_swiftcore.sh  # stage the cross-built libswiftCore (external input; once)
scripts/swift_gate.sh       # rung (q): Swift classes+generics, macOS vs machorun, BOTH link orders
scripts/sdk_abi_probe.sh    # sdk/ vs Apple's SDK, on the ABI, byte for byte
scripts/abi_naive_probe.sh  # what breaks if the userland forwards naively
build/machorun ./prog       # run one
```

**On a fresh clone, run `scripts/build.sh everything` first** — inside the
container, since `darwin/`, `libobjc` and the `.tbd`s are Linux Mach-O build
products. `scripts/difftest.sh` builds the loader and the two small dylibs for
you but deliberately *not* objc4 or quartz (a minute of Objective-C++ and
another of C++ on every run), so on a tree where `libobjc.A.dylib` has never
been built `objc` is a red **FAIL**, not the documented PASS. That is
measured, not theorised: `git clone && scripts/difftest.sh` gives **19 pass /
1 fail**; with `build.sh everything` first it gives **20 pass / 0 fail /
1 xfail / 1 no-oracle**.

`scripts/quartz_pixel.sh` is separate from `difftest.sh` for structural reasons
(its artefact is a file, and its macOS side needs `DYLD_LIBRARY_PATH`), and it
runs from the **macOS host**: it executes the oracle natively and drives Docker
for the Linux half.
