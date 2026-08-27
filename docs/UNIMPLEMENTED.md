# UNIMPLEMENTED

Every stub in this project must **abort loudly** with a message naming this file
and its own entry here. Nothing silently no-ops. If you find a stub that returns
quietly, that is a bug, not a shortcut.

Message format:

```
machorun: UNIMPLEMENTED: <short name> (<file>:<line>) — see docs/UNIMPLEMENTED.md#<anchor>
```

This file was seeded from the design study (`docs/PLAN.md`) before any loader
code existed, and revised on 2026-08-26 once the loader ran the corpus. Entries
that turned out to be implemented are marked **DONE** with what was actually
built rather than deleted, because the prediction is part of the record. Every
remaining entry corresponds to a live stub that aborts loudly.
**Do not delete an entry without deleting the stub.**

---

## Loader

### `lc-unixthread` — **DONE**
Parsed (`ARM_THREAD_STATE64` only; any other flavor aborts naming it) and
entered: `src/main.c` builds Darwin's kernel-style entry stack
(`[argc][argv][NULL][envp][NULL][apple][NULL]`) and branches to `pc`.
Ungradeable by construction — macOS SIGKILLs the only fixture — so this is
verified by inspection, not by the oracle.

### `lc-main-stacksize`
`LC_MAIN.stacksize != 0` (set by `-Wl,-stack_size`). Requires running `main` on
a separately `mmap`ed stack. Measured 0 in every fixture.

### `fat-binary` — **DONE**
`FAT_MAGIC`/`FAT_CIGAM` and their 64-bit forms, big-endian `fat_arch` table,
`CPU_TYPE_ARM64` non-arm64e slice selected, every file offset taken relative to
the slice. `fat` PASSes with output byte-identical to `printf`, which is
what makes a slice-selection bug detectable.

### `arm64e`
`cpusubtype & 0xFF == 2`. Pointer authentication, `DYLD_CHAINED_PTR_ARM64E`
(format 1) with signed pointers. **Deliberately out of scope** — Linux/arm64 may
not expose PAC at all and the signing keys are process-scoped. Reject at the
front door.

### `chained-ptr-format`
Formats 6 (`64_OFFSET`) and 2 (`64`) are implemented; every other format aborts
naming the number **and** the format's name. Still true that every binary in the
corpus uses 6 exclusively, so format 2 is implemented but untested by the oracle.

### `chained-import-format`
Formats 1 (`DYLD_CHAINED_IMPORT`) and 2 (`_ADDEND`) are implemented; 3
(`_ADDEND64`) aborts. Only format 1 appears in the corpus, so 2 is likewise
implemented but oracle-untested.

### `chained-start-multi`
`DYLD_CHAINED_PTR_START_MULTI` (`page_start & 0x8000`). On arm64 a chain cannot
cross a 16 KiB page (max reach `4095 * 4 = 16380`), so this should never appear;
abort if it does, because it means an assumption is wrong.

### `dyld-stub-binder`
Still true, with one change of location. The stub lives in the **loader**
(`mr_stub_binder_trap`, `src/resolve.c`), not in libSystem, because ld64.lld-18
segfaults in `StubHelperSection::writeTo` when the dylib it is linking also
defines `dyld_stub_binder`. Lazy binding is performed eagerly at load time
(PLAN.md §I.6); `05c` and `07c` exercise real lazy streams and pass, so the
eager assumption holds for everything measured. If this abort fires, it did not.

### `export-trie-reexport`
`EXPORT_SYMBOL_FLAGS_REEXPORT` (0x08) and `EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER`
(0x10) in an export trie: both abort naming the symbol. Not needed while our
libSystem is a single flat dylib. Note the *load-command* side,
`LC_REEXPORT_DYLIB`, is handled to the extent of being searched during
resolution, but a re-exporting dylib's trie entries are not chased.

### `page-size-64k`
Host page size > 16384. `__TEXT` (`r-x`) and `__DATA_CONST` (`rw-`) are 16 KiB
apart and would share one 64 KiB page, so they cannot be given distinct
protections. Refuse at startup naming the page size. Fallback path described in
PLAN.md I.4 (~60 lines, loses W^X).

### `darwin-path-unmapped`
An absolute Darwin path (`/usr/lib/...`, `/System/Library/...`) with no entry in
the prefix map. Hard error naming the path. This is the entry that grows as
frameworks are added, and its frequency is an honest progress metric.

---

## libSystem

### `tlv-thread-atexit`
`__cxa_thread_atexit` / `_tlv_atexit` — C++ `thread_local` with non-trivial
destructors. `_tlv_atexit` is exported and aborts. Not in the corpus.

### `libcxx-subset`
`darwin/usr/lib/libc++.1.dylib` is **not** libc++. 83 exported symbols against
the real thing's several thousand. It is:

* the operator `new`/`delete` family, the `__cxa_guard_*` trio and
  `std::terminate` (`darwin/src/libcxx.c`) — what `cxx_init` leaves
  undefined once the headers are inlined; measured, its whole libc++ import list
  is `__ZdlPv`;
* the out-of-line surface `vendor/quartz` reaches (`darwin/src/libcxx_std.cpp`)
  — `std::basic_string<char>`'s non-inline members, `__sort` for the arithmetic
  types, `to_string`, `__next_prime`.

Any other libc++ symbol fails as an undefined symbol naming itself, which is the
intended failure: it is a name you can look up in LLVM's `libcxx/src/`.

Three specific limits, in the order they are likely to bite:

1. **`__cxa_guard_acquire` is single-threaded.** It does not block a second
   thread on an in-progress initialisation. Nothing in the corpus initialises a
   function-local static from two threads.
2. **No iostreams, no locale, no `std::regex`, no `std::filesystem`, no
   `std::thread`.** Those are the largest .cpp files in libc++'s `src/` and none
   is reachable by explicit instantiation of a header template.
3. **No libc++abi at all**, so no exceptions: `__cxa_throw`,
   `__cxa_allocate_exception` and the `std::logic_error` family are absent, and
   `vendor/quartz` is compiled `-fno-exceptions` for that reason. See
   `unwind-compact`, which is the actual wall.

The general fix is to build LLVM 18's libc++ *sources* as a Mach-O dylib, the
way `vendor/objc4` is built. That is a real project and has not been attempted;
until then, growing `libcxx_std.cpp` by explicit instantiation is the cheap path
and keeps our copies bit-identical to the headers they are compiled against.

### `tbd-reexports` — FIXED 2026-08-27; the .tbd used to be short
A `.tbd` must vend everything the dylib vends, **and a dylib vends what it
re-exports**. `scripts/gen_tbd.sh` generated from `nm` alone and did not follow
`LC_REEXPORT_DYLIB`, so `libc++.1.tbd` listed its own 105 symbols and none of
libc++abi's 367 — even though `libc++.1.dylib` re-exports libc++abi exactly as
on Darwin.

`___gxx_personality_v0` was among the missing. **Anything built on Linux against
this SDK therefore could not bind it two-level and fell through to
`-undefined dynamic_lookup` — a FLAT bind, decided by load order**, which is the
exact defect class `duplicate-definitions` exists to remove. Found by
swiftcore-build while trying to relink libswiftCore against these stubs; the
relink would have silently traded one wrong bind for another.

**Merged INLINE, not as a `reexported-libraries:` stanza, because that is what
Apple does** — measured on the host SDK: `MacOSX.sdk/usr/lib/libc++.tbd` has no
such stanza and lists `__gxx_personality_v0` directly in its own `exports:`.
That is why `-lc++` on macOS yields a two-level bind naming libc++. The closure
is depth-limited at 4 for the same reason `src/resolve.c`'s `lookup_in` is.

Result, verified on a Linux-built C++ guest that throws: `___cxa_throw` and
`___gxx_personality_v0` *(from libc++)*, `__Unwind_Resume` *(from libSystem)* —
identical to what Apple's shipped libswiftCore records, and it runs.

### `duplicate-definitions` — CHECKED, hard, since 2026-08-27
Two dylibs defining the same symbol is **not an error** to the linker or the
loader. It is a coin toss decided by load order, and it has cost this project
twice: `swift_retain`/`swift_release` defined in libSystem beat the real
libswiftCore, which is why `-lswiftCore` before `-lSystem` was once load-bearing;
and `syspatch.c`'s `malloc_type` shim beat machorun's own for a week
(`malloc-type-zones` above).

`scripts/gen_tbd.sh` CHECK 4 is an all-pairs sweep over **every dylib present in
`darwin/usr/lib`**, not only the ones it emits stubs for. That scope is the whole
point: the overlap that prompted it was between `libc++abi.dylib` and
`libswiftcompat.dylib`, and libswiftcompat is staged from `~/swiftcore-macho` so
it is not in `DYLIBS` and never will be. A check scoped to `DYLIBS` would have
reported clean about four libraries and said nothing about the fifth — exactly
how `check_stale` missed `libc++abi` when it arrived.

**THE DANGEROUS CLASS IS ZEROFILL-VERSUS-REAL, and the check labels it.** A
symbol in `(__DATA,__common)` is a PLACEHOLDER — `otool -s` says "no contents in
the file" — put there to satisfy a link. Two real definitions are a mess; a
placeholder shadowing a real implementation is a jump through NULL waiting for a
link order to change.

The instance it was built for: `libswiftcompat.dylib` defined the four
`__cxxabiv1::*_type_info` vtables as zerofill, and `libswiftCore.dylib` imports
all four `(dynamically looked up)` — flat, so first-loaded wins.
`__gxx_personality_v0` matches a `catch` by dispatching through exactly those
vtables. It was safe only because `libc++abi` happened to load first, measured
with `MACHORUN_VERBOSE`. **The shim's own comment was right when written** —
*"nothing in a `-fno-exceptions` runtime dispatches through them"* — and adding a
real libc++abi invalidated it from another repository. Fixed by deletion in
`~/swiftcore-macho`, not by correcting it in two places.

**If this check fires on a STAGED artifact**, run `scripts/stage_swiftcore.sh`
before believing it: a stale copy carries duplicates the source no longer has,
and every git-level check says you are current.

### `weak-definition-gaps` — a missing symbol that binds to NULL instead of failing
A `<weak-def-coalesce>` bind is **not** an optional symbol. It says "one
definition of this is shared across the program and the linker does not care
which image supplies it" — the mechanism behind C++ inline functions, template
instantiations and the *replaceable* `operator new`/`delete`. Real dyld always
finds one, because libc++ defines them. Here a miss means our libc++ subset is
short a definition, and until 2026-08-27 the loader bound it to NULL in
silence: no report, no entry here, and a branch through zero at some
unpredictable later moment.

`src/resolve.c` now prints a `WEAK-DEFINITION GAP` line, once per distinct
symbol, naming the image that wanted it. **A line of that output is a bug
report, not a warning** — find the definition and add it to `darwin/src/`.

The one this was found by: Apple's shipped `libswiftCore` binds
`__ZnwmSt19__type_descriptor_t` and `__ZdlPvSt19__type_descriptor_t` — Apple's
*typed* `operator new`/`delete`, whose extra argument is a type descriptor for
their typed-memory-operations work — and imports **no untyped form at all**. Our
own Linux-built libswiftCore imports `__Znwm` and `__ZdlPvm` instead, so the gap
existed only for Apple's binaries, which is exactly the case the project exists
to support. Both are now defined in `darwin/src/libcxx.c`. The array and aligned
typed forms are deliberately still absent: nothing we run imports them, and the
new report means the first binary that does will say so.

### `malloc-type-zones` — one heap, one zone, and the type token is ignored
`darwin/src/objcsupport.c` implements Apple's `malloc_type_*` family by
forwarding to glibc and discarding the `malloc_type_id_t`. That is exact rather
than approximate — the token steers a per-type heap for diagnostics and carries
no allocation semantics — but two things about the family are genuinely absent:

* **there is one zone.** `malloc_default_zone()` returns a token and every
  `malloc_type_zone_*` call routes to the same glibc heap. A program that
  treats a zone as a separate arena (mass-free by zone, introspection,
  `malloc_zone_batch_malloc`) would notice. objc4 and libswiftCore do not: they
  only ever use the default zone.
* **`malloc_type_free` does not check the token.** Apple's can detect a free
  through the wrong type; ours cannot.

The **size rules were measured against Apple's libmalloc**, because no header
states them, and `tests/src/malloc_type.c` pins every one of them:
`aligned_alloc` and `..._zone_malloc_with_options_internal` return NULL when the
alignment exceeds 16 and the size is not a multiple of it; `zone_memalign`,
`posix_memalign` and `valloc` have no such rule.

**This family did not exist here until 2026-08-27, and its absence cost the
project its longest bug.** A missing libSystem symbol is not neutral — someone
fills it, somewhere nobody tests. `~/swift-macho-linux/spike/syspatch.c`
supplied its own `malloc_type_zone_malloc_with_options_internal` with four
parameters instead of five, so the argument it forwarded to `malloc` as the size
was the **alignment**: `mov x0, x1; b _malloc`, sixteen bytes whatever was
asked for, and every caller wrote its whole object over the neighbours. That was
the entirety of "46 UIKit scenes fail with nondeterministic memory corruption" —
22 glibc heap aborts, 19 SIGSEGVs on wild addresses, 9 silent failures, no two
alike, because a heap overflow of arbitrary size onto arbitrary neighbours never
fails the same way twice. It was invisible from its own behaviour: it returned a
valid pointer every time and the damage surfaced elsewhere, later, as somebody
else's crash.

### `libm-ulp` — a MEASURED agreement, not a guarantee
`darwin/src/math.c` forwards 113 math symbols to glibc's libm. Apple's Libm and
glibc's libm are different implementations, and IEEE 754 pins only `+ - * /` and
`sqrt` — it says nothing about `sin`, `cos`, `tan`, `pow`, `exp`, `log` or their
float forms. A guest that computes with any of those may therefore get a
different last bit under machorun than on macOS, and no amount of loader fidelity
changes that.

What is measured: `tests/bin/quartz` draws through `QZContextRotateCTM`
(cos/sin, very likely via the `__sincos_stret` aggregate ABI) and its PNG is
**byte-identical** on both sides, as are all nine per-stage checksums. That is
one workload agreeing, not a proof of agreement. The fixture is structured so
that if it ever stops agreeing, stdout names the stage.

Nothing in `math.c` rounds, clamps or "fixes up" a result to make the two agree.
If they diverge, the divergence must show.

Not forwarded, because clang lowers them to a single arm64 instruction for an
Apple target and no call is emitted: `sqrt`, `fabs`, `floor`, `ceil`, `round`,
`trunc`, `rint`, `nearbyint`, `copysign`, `fma`, `fmax`, `fmin`. They are
exported anyway, for a guest built `-fno-builtin`.

### `os-unfair-lock` — **DONE**
Implemented in the four bytes the guest gives us (Darwin stores an owning
thread port there, so the struct cannot be widened): 0 is unlocked, a locked
lock holds the owner's token, and `lock`/`trylock`/`unlock`/`assert_owner`/
`assert_not_owner` are the atomic operations on it. **Contention yields rather
than futex-waits**, so under heavy contention this burns CPU and gives no
fairness guarantee — a performance difference, not a correctness one.
Recursive acquisition by the owner aborts, which is what Darwin does too.
No fixture contends on one yet.

The owner token is a per-thread sequential id (`mr_thread_token()`), **not**
anything derived from `pthread_self()`. Deriving it is what made this lock
report other threads' acquisitions as its own on Graviton3; see
`os-unfair-lock-owner` for the measurements and
`scripts/stress_unfair_lock.sh` for the gate that keeps it fixed.

### `pthread-attr`
`pthread_create` with a non-NULL `pthread_attr_t` aborts: Darwin's attribute
struct is compiled into the guest and its layout is not glibc's. Same for
`pthread_mutex_init` with attributes. The static initialisers
(`PTHREAD_MUTEX_INITIALIZER`, `PTHREAD_ONCE_INIT`) *are* handled, by keeping a
glibc object inside Darwin's opaque bytes and using the signature word to tell
"Apple-initialised" from "adopted".

### `large-allocations-above-2^47` — a hole in the heap guarantee, not in malloc_size
`mr_constrain_heap()` puts glibc's main arena below 2^47 and VERIFIES it, which
is what makes Swift's 47-bit isa mask safe (see `#isa-va-width`). The
verification checks `brk`. Allocations at or above glibc's 32 MiB
`M_MMAP_THRESHOLD` are **not** brk: they come from `mmap`, and on this kernel
they land at `0xffff_xxxx_xxxx` — back above the ceiling the whole heap fix
exists to stay under. Measured, by existential-fix:

```
req=  32505856  ptr=0x10032e02180   brk,  below the limit
req=  33554432  ptr=0xffffbbe7f010  mmap, ABOVE it
req= 268435456  ptr=0xffffade7f010  mmap, ABOVE it
```

**The check cannot see the case it does not cover**, which is the part worth
naming: `mr_constrain_heap()` probes a 64-byte allocation, that allocation is
necessarily brk, so the probe passes and says nothing about the mmap path. A
verification whose blind spot is exactly the uncovered case reads as
reassurance.

Not a live bug today: nothing on the render path allocates 32 MiB in one block,
and the isa mask applies to CLASS pointers, which are metadata (64 KiB pool
refills) and objc4 class pairs (a few hundred bytes) — never buffers. It
becomes one the first time a guest puts something the runtimes mask into a
large allocation.

Why it is not simply fixed: `M_MMAP_THRESHOLD` cannot be raised past glibc's
`HEAP_MAX_SIZE/2`, which is the 32 MiB we already request — we sit on the cap,
so there is no headroom to buy. Closing it properly means intercepting large
allocations, which is the guest-malloc arena that was considered and rejected
(it changes pointer ownership, and `malloc_size`, `realloc` and objc4's
`try_free` all depend on that not changing). Recorded rather than fixed, and
the honest statement of the guarantee is: **the main arena is below 2^47;
single allocations at or above 32 MiB are not.**

### `opaque-abi-class` — the whole family `posix-spawn` belongs to
Darwin and glibc disagree about the size of most "opaque" C library types, and
the disagreement runs **both ways**. Wherever machorun hands a glibc object to a
guest — or hands the guest's storage to glibc — the two sizes have to be
compared first. Measured 2026-08-27: Darwin from Apple's own headers on macOS
26.5.2, glibc by `sizeof` in the test-bed image. 24 of the 43 values checked
differ.

| type | Darwin | glibc | forwarded today | if forwarded naively |
|---|---:|---:|---|---|
| `struct stat` | 144 | 128 | **yes**, translated | — `stat_l2d()` converts field by field |
| `pthread_mutex_t` | 64 | 48 | via `adopt()` | fits |
| `pthread_cond_t` | 48 | 48 | no | fits **by coincidence**, layout still differs |
| `pthread_rwlock_t` | 200 | 56 | no | fits |
| `pthread_once_t` | 16 | 4 | via `adopt()` | fits |
| `pthread_attr_t` | 64 | 64 | no (aborts) | same size, different layout |
| `struct dirent` | 1048 | 280 | no | **fits and is still wrong** — see below |
| `glob_t` | 88 | 72 | no | fits, layout differs |
| `posix_spawnattr_t` | 8 | 336 | no | **overflows by 328** |
| `posix_spawn_file_actions_t` | 8 | 80 | no | **overflows by 72** |
| `sem_t` | 4 | 32 | no | **overflows by 28** |
| `regex_t` | 32 | 64 | no | **overflows by 32** |
| `jmp_buf` | 192 | 312 | no | **overflows by 120** |
| `sigjmp_buf` | 196 | 312 | no | **overflows by 116** |
| `sigset_t` | 4 | 128 | no | **overflows by 124** |
| `ucontext_t` | 880 | 4560 | no | **overflows by 3680** |
| `dev_t` / `mode_t` / `nlink_t` | 4 / 2 / 2 | 8 / 4 / 4 | inside `struct stat` | width mismatch, translated |

**Nothing in the overflow block is forwarded today.** `stat`/`fstat`/`lstat` are
the only members of this class libSystem exports at all, and they are properly
translated. So this is a landmine map, not a bug list — and the landmines are
close, because CF's 28 libc symbols and libdispatch's link step are the next
things to close.

Three distinct failure modes, worth separating because only one of them looks
like a bug:

1. **Overflow.** The guest reserves Darwin's size, glibc writes its own. Every
   symbol resolves, the link is clean, the call returns success, and the excess
   lands on whatever the guest had next. `posix_spawnattr_t` is 8 against 336.
2. **Layout.** The object fits, and the guest reads the wrong bytes out of it.
   `struct dirent` is the live example: `d_type` is at 20 on Darwin and 18 in
   glibc, `d_name` at 21 against 19. A forwarded `readdir()` returns wrong file
   types and truncated names rather than failing — for CFTimeZone that is wrong
   or missing zones, with no error anywhere.
3. **Coincidence.** `pthread_cond_t` is 48 bytes on both. A forwarder would
   appear to work, and would still be wrong the moment either side changes or a
   guest passes a statically-initialised one.

**What to do instead**, in the order of preference the tree already demonstrates:

* **Translate**, like `stat_l2d()` in `darwin/src/posix.c`. Correct for anything
  the guest reads fields out of — `struct stat`, `struct dirent`.
* **Adopt**, like `adopt()` in `darwin/src/libsystem.c`. Keep a glibc object
  inside Darwin's larger footprint and use a signature word to tell
  Apple-initialised from adopted. Only valid when glibc's is smaller.
* **Indirect**, which is what the `posix_spawn` pair needs: Darwin's 8 bytes are
  already a pointer to a library-owned allocation, so store the glibc object's
  address there. Cheaper than either of the above.
* **Abort**, like `pthread_create` with a non-NULL attr. Always available, and
  better than any of the above done wrong.

**The tripwire.** `sdk/tests/glibc_abi_probe.c` pins every number in the table
above with `_Static_assert`, and is the only file in the repository compiled by
the host compiler against **real glibc headers** — `scripts/build.sh` runs it on
the Linux branch. That matters more than it sounds: everything under
`darwin/src/` is built `-nostdinc` for `arm64-apple-macos`, so `posix.c`'s
`_Static_assert(sizeof(struct linux_stat) == 128)` proves our *mirror* is 128
bytes and proves nothing about glibc. Had glibc's layout moved, that assertion
would have kept passing while `stat()` returned nonsense. The probe closes that,
and fails the build on any movement rather than waiting for someone to remember.

### `posix-spawn` — absent, and the obvious forwarder would smash the guest's stack
Not implemented at all: `nm -g darwin/usr/lib/libSystem.B.dylib | grep spawn` is
empty and `sdk/` ships no `spawn.h`, so nothing here can currently compile
against it. That is the safe state, and this entry exists so the next person
does not leave it by the shortest route.

CoreFoundation reaches `posix_spawn` and six `posix_spawn_file_actions_*` from
`CFPlatform.c:2291`, in CF's **generic POSIX** branch, and
`~/foundation-macho/docs/CF_TRIAGE.md` §53 records that "glibc has all of it".
That is true of the *functions* and false of the *ABI*, which is the trap:

| | `posix_spawnattr_t` | `posix_spawn_file_actions_t` |
|---|---|---|
| Darwin (`typedef void *`) | **8** bytes | **8** bytes |
| glibc (a struct) | **336** bytes | **80** bytes |

Measured rather than read off a header: the Darwin typedefs are in Apple's own
`spawn.h`, and the glibc sizes are `sizeof` in the test-bed container.

A guest compiled against Darwin's header writes `posix_spawnattr_t attr;` and
reserves **8 bytes**. Forward `posix_spawnattr_init(&attr)` straight to glibc
and glibc writes **336** into it — a 328-byte overrun of a guest stack slot,
with no diagnostic, from a call that returns 0 for success. `file_actions` is
the same bug at 80 against 8. Every symbol resolves, the link is clean, and the
corruption is silent, which is the worst combination this project has a name
for.

The shape of the fix is already in the tree. Darwin's contract is that those 8
bytes hold *a pointer to an opaque allocation the library owns*, which makes
this **easier** than the `pthread_mutex_t` case `adopt()` handles in
`darwin/src/libsystem.c`, not harder: there is no Apple-initialised static form
to detect, so there is nothing to overlay and no signature word to check.
Allocate the glibc object, keep its address in the guest's 8 bytes, free it in
`posix_spawnattr_destroy` / `posix_spawn_file_actions_destroy`.

A declaration-only `spawn.h` exists on the Foundation track
(`~/foundation-macho/scripts/cf_shims.sh`) purely to make CF's 86 files compile
for a link-surface census. That is a legitimate measurement instrument and a
terrible SDK: a header that declares a function with nothing behind it links
clean and fails at load. It must not be staged into `sdk/` — `#swift-interop`
is what an unbacked promise costs when it is found from the other end.

### `printf-family-gaps`
Our formatter implements the `%[flags][width][.prec][length]` grammar for
`diuxXospcf/e/g/a` and delegates only float conversion to glibc (through a
non-variadic prototype). Covered in anger by `varargs`, which is what caught
`%#o` dropping its leading zero. `%n` aborts. The `scanf` family, `syslog`,
`err`/`warn` and `NSLog` are absent entirely — they are variadic, so they can
never be forwarders, and none is in the corpus. Wide characters (`%ls`, `wprintf`)
are absent: `wchar_t` is 4 bytes on both systems, but nothing exercises it.

### `mach-ipc`
`mach_msg`, `mach_port_allocate`, `task_for_pid` and `task_info` abort naming
themselves. Anything requiring real cross-process Mach IPC (XPC, launchd,
distributed notifications) is **deliberately out of scope**.

> **PORTING AGAINST THIS SYSROOT? FEATURE-DETECTING MACH DOES NOT WORK.**
> `sdk/usr/include/mach/` is complete, because it is Apple's, and every
> convention in the ecosystem reads a present header as a present capability:
> `check_include_files(mach/mach.h HAVE_MACH)`, `__has_include(<mach/mach_time.h>)`
> and autoconf's `AC_CHECK_HEADER` all answer **yes** here. **Force Mach off
> explicitly** — `-DHAVE_MACH=0` or the port's equivalent — rather than letting
> detection decide. Measured near-misses in swift-corelibs-libdispatch alone:
> its CMake would have enabled the entire Mach backend, and its firehose
> subsystem is reached only because `__has_include(<mach/mach_time.h>)`
> succeeds. Note too that libdispatch's checked-in `config/config.h` is a
> *Darwin* config (`HAVE_MACH 1`) that `internal.h` falls back to when no
> generated config is found first — so Mach can arrive from the source tree
> with no configure step at all.
>
> **Why the headers are not simply removed**, which was proposed and measured:
> `mach/` is not a separable capability tree. It is woven into Darwin's own C
> library header graph, so moving it out of the default include root breaks
> ordinary code that has nothing to do with Mach. Transitive `mach/` headers
> reached from a single `#include`, measured against this sysroot:
>
> | header | `mach/` headers pulled |
> |---|---:|
> | `<stdlib.h>` | 2 (via `sys/wait.h` → `sys/signal.h` → `arm/_mcontext.h`) |
> | `<sys/mount.h>` | 8 |
> | `<dispatch/dispatch.h>` | 14 |
> | `<mach-o/loader.h>` | 20 |
> | `<malloc/malloc.h>` | 56 |
>
> `<stdlib.h>` alone settles it. Fourteen non-`mach/` staged headers include
> `mach/` directly, among them `dispatch/`'s own public headers and
> `bsm/audit.h`, which `sys/mount.h` needs for CFLocale. objc4 for its part
> pulls **83 of the 85** staged `mach/` rows transitively, because
> `mach/mach.h` is an umbrella — so an opt-in set would not be a small one even
> for its single intended consumer.
>
> **And the promise is not unbacked.** Unlike a `.tbd` advertising a symbol
> nothing defines, 34 Mach entry points here are real, and `mach` grades them
> byte-for-byte against macOS. The four that are not implemented are *exported*
> and abort with their own name and reason on first use. So a port that switches
> the Mach backend on fails **loudly at first call** rather than silently — late,
> but named. That is why the remedy here is a documented rule rather than a
> header move.
>
> **A narrower split was measured too, and it does not help either.** Of the 85
> staged `mach/` headers, **56 are reachable from ordinary non-`mach/` headers**
> and only 29 are pure Mach API. `mach/port.h` — which defines `MACH_PORT_NULL`
> and `MACH_PORT_DEAD` — is among the required 56: it is reached by
> `sys/mount.h`, by `<malloc/malloc.h>` via `malloc/_platform.h`, by
> `bsm/audit.h`, by `os/workgroup_base.h`, and by `dispatch/dispatch.h` itself.
>
> **So `MACH_PORT_NULL macro redefined` is not a placement bug here.** Verified
> against Apple's own MacOSX15.4 SDK: its `dispatch/source.h` includes
> `<mach/port.h>` and `<mach/message.h>` exactly as ours does, and a program
> including only `<dispatch/dispatch.h>` gets `MACH_PORT_NULL` defined. **Our
> sysroot behaves identically to Apple's**, which is the property we want. A
> build that hits that redefinition is compiling libdispatch's *Linux* no-Mach
> shim (`src/shims/mach.h`) — placeholders for a platform with no Mach headers
> at all — against a **Darwin** target that legitimately has them. The
> conflation to undo belongs to the port: "Mach types exist" and "the Mach IPC
> backend is available" are different questions, and `HAVE_MACH=0` answers the
> second by suppressing the first. Guard the shim (`#ifndef MACH_PORT_NULL`), or
> let the real Mach *types* through and disable the backend features
> individually. Removing the headers would break `dispatch/dispatch.h` before it
> fixed anything.

What *is* implemented, in `darwin/src/mach.c` and covered by `mach`:
`mach_task_self` / `mach_task_self_` / `mach_host_self` / `mach_thread_self`,
`mach_port_deallocate` / `mach_port_mod_refs`, `vm_allocate` / `vm_deallocate` /
`vm_protect` and their `mach_vm_*` twins, `host_page_size` / `getpagesize` /
`vm_page_size`, `mach_absolute_time` / `mach_continuous_time` /
`mach_approximate_time` / `mach_timebase_info`, and `mach_error_string` /
`mach_error`.

### `mach-ports-are-fiction`
There is no Mach kernel under machorun, so a `mach_port_t` is a name in *our*
table: `mach_task_self_` is a fixed value, `mach_host_self_` another, and
`mach_thread_self()` mints one per thread from a counter. Two calls on one
thread agree and two threads disagree, which is the only property portable code
relies on. `mach_port_deallocate` validates the name and returns
`KERN_INVALID_NAME` for one we never handed out, rather than blanket success.
Anything that treats a port as a capability to *send* to hits `mach_msg`, which
aborts.

### `mach-timebase-unit`
`mach_absolute_time` returns nanoseconds and `mach_timebase_info` reports
`numer = denom = 1`. Real Apple silicon has a 24 MHz counter and reports 125/3.
The pair is self-consistent, so any program that multiplies by `numer/denom`
before believing a duration is correct — one that hardcodes the ratio was
already wrong on Intel Macs. Programs that use the raw counter as a
*fingerprint* of tick rate will see a difference.

### `vm-protect-max`
`vm_protect(set_maximum = TRUE)` aborts. Linux has no maximum-protection
concept, so a ceiling can be neither raised nor lowered, and silently ignoring
the flag would let a guest believe it had locked memory down.

### `errno-untranslatable`
54 of the 87 errno names common to both systems have different values
(`docs/ABI.md` §4); the table in `darwin/src/errno_table.h` is generated from a
measurement of both platforms by `scripts/gen_errno_table.sh`. A Linux errno
with **no** Darwin twin is reported to the guest as its negative, so it is
visibly not a valid Darwin errno instead of silently aliasing one. Nothing in
the corpus produces such an errno; if one shows up in the wild it will be
recognisable rather than plausible.

### `open-flags-unmappable`
`O_SHLOCK`, `O_EXLOCK`, `O_EVTONLY` and `O_SYMLINK` have no Linux equivalent
and abort. Dropping them would perform a different operation than the caller
asked for — the same class of bug as forwarding the flag word raw, which turns
Darwin's `O_CREAT` into Linux's `O_TRUNC` (measured; see
`scripts/abi_naive_probe.sh flags`).

### `stat-birthtime`
`struct stat` is translated field by field between Darwin's 144-byte layout and
Linux's 128-byte one. Linux's `struct stat` has **no** birth time — `statx`
does — so `st_birthtimespec` is filled from `st_ctim`. That is a lie of
precision rather than of kind: a zero would date every file to 1970, which is
worse. Using `statx` when available is the fix and is unwritten.

### `dirent` — **DONE**
`opendir`/`readdir`/`closedir`/`rewinddir`/`dirfd` translate rather than
forward: `struct dirent` is 1048 bytes on Darwin and 280 on glibc, and differs
in field layout as well as size, exactly like `struct stat`. Graded by
`tests/bin/dirent`.

### `sigaction-siginfo` — the three-argument handler form is refused
`sigaction` translates four things and installs a trampoline
(`darwin/src/posix.c`): the signal number in **both** directions, the 16-vs-152
byte struct, the `sigset_t` embedded in it by value, and all seven `sa_flags`
bits — **not one of which agrees** with Linux, with the low ones colliding with
live Linux flags rather than with unused bits. Graded by `tests/bin/sigaction`
(rung ab).

`SA_SIGINFO` is the one flag that **aborts instead of mapping**. Honouring it
changes the handler's signature to `(int, siginfo_t *, void *)`, and Darwin's
`siginfo_t` is 104 bytes where glibc's is 128, with different fields — so it
needs a second struct translation, plus a `ucontext_t` for which no mapping
exists at all (it carries the machine's register file). Mapping the bit and
handing the guest a Linux `siginfo` would be the dishonest option; nothing has
asked, because libdispatch installs a one-argument `sa_handler`.

### `sigaction-darwin-only-signals` — `SIGEMT` and `SIGINFO` cannot be installed
Darwin has 31 signals, Linux has no counterpart for `SIGEMT` (7) or `SIGINFO`
(29). `sigaction` on either returns `EINVAL` rather than arming the guest for
something it never asked about — the same choice `mr_sigset_d2l` makes when it
drops them from a mask.

macOS returns 0 for the same call, so this is a real divergence that no wrapper
can reconcile, and it is therefore **absent from `sigaction`**: a fixture
that must match its oracle byte for byte cannot contain a case where the two
systems legitimately differ. Same reason `POLLWRBAND` is absent from `poll`.

### `sigaction-sysroot` — there was never a header gap here
Recorded because it was reported twice as a missing declaration and is not one.
`struct sigaction` is fully defined at `sdk/usr/include/sys/signal.h:385`, and
`sigaction()` is prototyped at `sdk/usr/include/signal.h:87`. A translation unit
that includes only `<sys/signal.h>` sees the struct and not the function —
**and that is exactly what Apple's own SDK does**, verified by compiling the
same two-line probe against both. The fix for a consumer hitting this is
`#include <signal.h>`, not staging a header.

### `fcntl-nosigpipe` — a Darwin facility Linux does not have
`F_GETNOSIGPIPE` (74) and `F_SETNOSIGPIPE` (73) ask a descriptor not to raise
`SIGPIPE`. **Linux has no per-fd equivalent** — it suppresses `SIGPIPE` per-send
with `MSG_NOSIGNAL` or process-wide with `SIG_IGN`, never per-descriptor. Both
return `ENOTSUP` rather than succeeding as a no-op, because a silent success
would leave the guest believing a write to a closed pipe cannot raise a signal.

macOS answers both, so this is a real divergence no wrapper can reconcile and it
is therefore **absent from `fcntl_madvise`** — the same reason `POLLWRBAND` is
absent from `poll` and `SIGEMT` from `sigaction`.

### `sysctl-mibs` — three MIBs, and nothing to forward to
`sysctl` is implemented rather than forwarded, which is unusual enough to record
why: `sys/sysctl.h` no longer exists in glibc 2.39, Linux's `sysctl(2)` was
removed from the kernel and returns `ENOSYS`, and Darwin's is an unrelated BSD
MIB API. The symbol survives in `libc.so.6` only as a compat stub — exactly the
shape that lets a link succeed and a call quietly do nothing.

`CTL_KERN` with `KERN_OSTYPE`, `KERN_OSRELEASE` and `KERN_OSVERSION` answer
`"Darwin"`, `"machorun"` and `"machorun"`. libdispatch's single use is
`KERN_OSVERSION` into `_dispatch_build`, which reaches crash reports and nothing
else, so a fixed answer is a real answer rather than a stub pretending to be one
— and it deliberately does **not** return a plausible macOS build number, so
nobody reads a crash report and believes it came from a Mac.

Every other MIB **aborts**. An unimplemented MIB and a nonexistent one are
different facts, and only one of them should look like a normal failure.

### `libdispatch-init` — **DONE**, and recorded because the crash is far from the cause
`libdispatch_init()` is `DISPATCH_EXPORT` — an ordinary exported function, **not
a constructor**. On Darwin, libSystem is an umbrella with libdispatch as a
sub-library and **libSystem's own initialiser calls it**. Nothing in this stack
was, so every function pointer that init assigns stayed NULL.

Measured init sections: `libswiftCore` 1, `libSystem` 1, `libquartz` 1,
**`libdispatch` 0**. The symptom was `SIGSEGV at pc 0x0` inside `_dispatch_time`
— a call through a null pointer rather than a bad address, with the argument
register holding exactly the nanoseconds the caller passed.

`__machorun_libsystem_bootstrap` now makes the call, which is the position
`src/main.c` documents as *"Darwin's libSystem initializer"*: after every image
is mapped and bound, before any guest initialiser. Both halves matter — mapped,
because `mr_dlsym_default` searches loaded images; before, because a guest
initialiser touching a dispatch queue would otherwise find the NULL.

Looked up by name rather than linked: libSystem does not depend on libdispatch
(the dependency runs the other way) and a link would be a cycle.
`mr_dlsym_default` is the loader's flat search over guest images and does not
fall back to the host, so a process without libdispatch gets NULL and nothing
happens.

**Not gradeable as a fixture**, which is why it is here: on macOS the real
libSystem calls the real libdispatch's init, not a stub's, so a fixture with a
stand-in would diverge from its oracle. Proved directly instead — a guest dylib
exporting `libdispatch_init` reports **yes** before `main`, and **no** with the
call removed. The whole 34-fixture corpus covers the NULL path, since none of
them loads libdispatch.

**A libdispatch `dlopen`'d later is not covered:** the bootstrap has already run.
Nothing does that today; the honest fix if something ever does is for the loader
to make the call on load rather than for this to poll.

### `no-dynamic-symbol` — a fifth hazard family: same name, nothing to bind to
The four ABI-crossing families are struct layout, constant value, scalar-typedef
width, and variadic convention. `pthread_atfork` is none of them and is not
forwardable anyway.

Its prototype is identical on both systems — three function pointers, no
struct, no constant — so it lands squarely on the "safe to forward" pile by
every check we have. glibc's header declares it, the man page documents it, and
**glibc does not export it from `libc.so`**: it lives in `libc_nonshared.a` as a
static wrapper over `__register_atfork`, so `dlsym` finds nothing and a forward
fails at **runtime**, not at link:

    machorun: undefined symbol '_glibc_pthread_atfork'

Measured with positive controls so an empty answer could not be the instrument:
`nm -D --defined-only libc.so.6` finds `pthread_atfork` **zero** times and
`__register_atfork` once, while `malloc`, `getresuid` and `geteuid` are all
found. `darwin/src/posix.c` builds the door over `__register_atfork` with a
NULL DSO handle, which means "never unregister" — correct, since libSystem is
never unloaded.

**The general rule: a header declaration is not evidence that a dynamic symbol
exists.** Only `nm -D` on the shared object is.

### `nsgetexecutablepath` — **DONE**, and the wrong answer is a valid path
`_NSGetExecutablePath` must name the **guest**. The obvious Linux
implementation, `readlink("/proc/self/exe")`, returns **machorun** — under this
loader the process genuinely is machorun, and the Mach-O is something we mapped
rather than something the kernel exec'd.

CoreFoundation takes the directory of this answer to locate the main bundle, so
a `/proc/self/exe` implementation returns a real, existing, readable path and
points CF at the wrong directory, with every bundle-relative lookup then failing
a long way from the cause. `src/resolve.c` exports
`mr_guest_executable_path()`, which is the only place that knows.

It is **`realpath`-resolved**, because dyld hands the guest an absolute path and
we are given whatever was on the command line — the harness invokes
`./execpath`, and a relative answer resolves against the process's cwd later
rather than against the executable.

Two contract details measured on the oracle rather than assumed: **`bufsize` is
not updated on success** (a 4096-byte buffer holding a 112-character path comes
back still saying 4096; Apple writes it only on the failure path), and the
failure path *does* write the required size. `tests/bin/execpath` grades all
of it, and catches the `/proc/self/exe` version specifically — with the loader
patched to use it, the fixture fails on `names this executable`.

### `pthread-getugid-np` — Darwin FAILS here, and so do we
Recommended as "return `geteuid()`/`getegid()` — Linux has no per-thread ugid
override, so that literally *is* the correct implementation". That reasons from
what Linux can supply. Measured on the oracle, macOS 26.5.2, ordinary
unprivileged thread:

    pthread_getugid_np(&u, &g)  ->  rc = -1, errno = ESRCH, u and g untouched

So on real Darwin this SPI does not answer for an ordinary thread at all, and
every caller — CoreFoundation included — is already on its failure path there.
Returning 0 with the effective ids would be **more useful** and would send CF
down a branch it never takes on a Mac. We return `-1`/`ESRCH` and leave the
outputs alone, because a caller that ignores the `-1` must see what it would
have seen.

### `osspinlock-recursive` — we abort where Darwin hangs
`OSSpinLock` is backed by `os_unfair_lock`, and the two are compatible **by
measurement rather than by luck**: both are a 4-byte word whose unlocked state
is zero (`OS_SPINLOCK_INIT` and `OS_UNFAIR_LOCK_INIT` are both `{0}`), so a lock
initialised through either spelling is valid for the other. Writing a second
spin loop would mean maintaining a second synchronisation primitive to get
wrong, when `libsystem.c` already has one exercised by
`tests/bin/21_unfair_lock_firsttouch` and a 300-run threading gate.

**One observable difference:** recursive acquisition **aborts** here and **hangs
forever** on Darwin. Apple deprecated `OSSpinLock` precisely because it has no
owner tracking and no priority donation, so a recursive or preempted holder
deadlocks. Aborting is a divergence in the safe direction — it cannot be
mistaken for correct behaviour, where a hang can be mistaken for slow work.

It is therefore **absent from `osatomic`**: a fixture that must match its
oracle byte-for-byte cannot contain a case where one side hangs. Same reason
`POLLWRBAND` is absent from `28_poll` and `SIGEMT` from `29_sigaction`.

### `rlimit-rotated` — **DONE**, and the struct needed translating after all
Two of the seven `RLIMIT_*` numbers move, which is what makes them look safe.
Measured both sides:

    CPU 0  FSIZE 1  DATA 2  STACK 3  CORE 4     agree
    RLIMIT_NOFILE   Darwin 8   Linux 7          differ
    RLIMIT_AS       Darwin 5   Linux 9          differ

Both collisions are with **live** limits rather than unused slots: Darwin's
`NOFILE` (8) is Linux's `RLIMIT_MEMLOCK`, and Darwin's `AS` (5) is Linux's
`RLIMIT_RSS`. A forwarded `getrlimit(RLIMIT_NOFILE)` does not fail — it returns
how much memory the process may lock, **as a file-descriptor count**.
CoreFoundation asks for `NOFILE`.

**And `struct rlimit` needed translating too, which I got wrong first and only
found because a negative control PASSED.** The layout agrees — 16 bytes on
both, `rlim_t` 8 on both — so every size check passes. The *value* does not:

    RLIM_INFINITY   Darwin 0x7fffffffffffffff   Linux 0xffffffffffffffff

A guest testing `rlim_cur == RLIM_INFINITY` compares against **Darwin's**
spelling, so an unlimited Linux resource reads as a specific enormous **finite**
number and every "is this capped?" test answers wrongly. It is the
`sockaddr_in` shape inverted: there an identical size hid a different layout,
here an identical layout hides a different value. **Nothing structural catches
either.**

The two bugs also concealed each other: forwarding the raw resource number gave
Linux's `MEMLOCK`, which is unlimited, which the fixture then read as *finite*
because the sentinels disagree — so the control passed while both were broken.
`tests/bin/rlimit` now reads an actually-unlimited resource (`RLIMIT_AS`, which
is unlimited on both) so the sentinel is discriminated on its own.

### `pthread-scope-off-by-one` — **DONE**
    PTHREAD_SCOPE_SYSTEM    Darwin 1   glibc 0
    PTHREAD_SCOPE_PROCESS   Darwin 2   glibc 1

Third instance of that spacing after `SIG_BLOCK` and the detach state, and it
fails in the direction that looks fine. Linux implements only `SCOPE_SYSTEM`, so
a forwarded Darwin `SCOPE_SYSTEM` (1) arrives as glibc's `SCOPE_PROCESS` and is
refused with `ENOTSUP` — **the guest asks for the one scope Linux supports and
is told it is unsupported.** `getscope` translates back, because a set without
its get is a one-way mapping nothing can check.

`writev` by contrast is a **genuine** plain forward: `struct iovec` is 16 bytes
on both with `iov_base` at 0 and `iov_len` at 8, measured rather than assumed.
That is unusual enough here to be the exception that needs evidence.

### `environ-two-arrays` — **DONE**, and it was latent before anything wrote
`environ` is a **variable** the guest reads directly; `getenv` is a **call**.
They had different backing: `environ` was set at bootstrap from the loader's
`envp`, and `getenv` forwards to glibc, which reads **glibc's** array. At
startup both hold the same contents, so every read agrees and nothing looks
wrong.

**The divergence appears only after the first write** — which is the worst
possible lifetime for a defect, because the code that breaks is never the code
that introduced it. Adding `setenv` as a plain forward would have activated it:
glibc's array would grow a variable the guest's `environ` walk never sees. Two
environments, one name, each internally consistent — the two-reference-counts
shape, with no size or constant differing and nothing structural to catch it.

The family now operates on **one** environment (glibc's), and `environ` is
re-pointed after every mutation. **The re-point is not decoration:** glibc's
`setenv` *reallocates* the array when it grows, changing the value of glibc's
`environ`, so a pointer cached at bootstrap is correct exactly until the first
`setenv` and then points at freed memory. The guest reads `environ` as a
variable, so there is no read to intercept — re-syncing on write is the only
point of control, and it suffices because libSystem is the only path by which a
guest can mutate anything.

`putenv` stores the **caller's** buffer rather than copying, on both systems, so
it stays a forward: copying would look tidier and would break a caller that
later modifies its own buffer to change the value, which is legal.

`tests/bin/environ` checks **agreement rather than values** — it never prints an
environment variable's contents, since a container and a Mac share almost none
of theirs. The `environ` **walk** is the half that would have failed; `getenv`
alone passes with two separate environments, because `getenv` and `setenv` were
always talking to the same one. Proved: reverting to the two-array arrangement
gives `getenv:ok environ-walk:NO`.

### `pagesize-two-answers` — `getpagesize()` and `sysconf(_SC_PAGESIZE)` disagree
Found while implementing `HW_MEMSIZE`, and reported rather than fixed because
the right answer is a design decision rather than a defect to patch quietly.

    getpagesize()            16384   darwin/src/mach.c, hard-coded MR_DARWIN_PAGE
    sysconf(_SC_PAGESIZE)     4096   translated straight through to the host's

On macOS/arm64 both are 16384 and the question does not arise. Under machorun
they differ, so **a guest asking the same question through two APIs gets two
answers**. `getpagesize()` returning Darwin's value is defensible — a guest's
Mach-O segments are 16K-aligned and 16384 is a multiple of the host's 4096, so
alignment computed from it is always valid. But anything COUNTING pages with
it under-counts by four.

`HW_MEMSIZE` is deliberately computed as host-pages × host-page-size, because
the question it answers is how much memory the machine has; using 16384 would
over-report by 4×. `tests/src/sysctl.c` asserts against the `sysconf` value
for that reason and says so at the call site.

The fix is to pick one and make the other agree. Not done here because
`MR_DARWIN_PAGE` is load-bearing for image mapping and `sysconf` has a recorded
oracle (`tests/bin/sysconf`), so changing either is a decision with a blast
radius rather than a one-line correction.

### `ioctl-request-encoding` — one namespace in, and why that is not a preference
Darwin encodes an `ioctl` request as direction|size|group|number (`FIONREAD` is
`0x4004667f`, `FIONBIO` `0x8004667e`); Linux uses small opaque numbers for the
legacy socket and tty requests (`FIONREAD` is `0x541b`). Nothing about the two
spaces corresponds, so a forward asks the kernel for an unrelated operation
**through a pointer**.

**`ioctl` accepts DARWIN request numbers only.** It briefly accepted both, on
the `signalfd` precedent — *this file is the boundary, and Linux shim code
compiled for a Darwin target speaks Linux*. **That precedent does not extend,
and the reason is the whole argument:** for `signalfd` the SYMBOL determines the
namespace, because `signalfd` exists only on Linux, so any call to it is shim
code by construction. `ioctl` exists on **both** systems, so the symbol implies
nothing — and `0x541b` is a perfectly well-formed Darwin request that simply is
not allocated. A wrapper accepting both could never know which it received.
That is guessing, and the rule in `darwin/src/posix.c` is to bail rather than
guess.

It stopped being theoretical when CoreFoundation arrived: `CFSocket.c` does
`#define ioctlsocket(a,b,c) ioctl(a,b,c)` and passes Darwin numbers, while
libdispatch's epoll backend passes Linux ones. Two namespaces, one symbol, no
discriminator.

**What Linux-origin callers must do instead — and one of the two has no Darwin
`ioctl` at all**, which is why a bare "speak Darwin above libSystem" rule is not
implementable without the note below:

| question | Darwin | Linux |
|---|---|---|
| bytes readable | `FIONREAD` (ioctl) | `SIOCINQ` (ioctl) |
| bytes unsent | `SO_NWRITE` (**getsockopt**) | `SIOCOUTQ` (ioctl) |

Darwin has no `FIONWRITE`; it answers "how much is still unsent" through
`getsockopt`, and Linux has no `SO_NWRITE` and answers through `ioctl`. **The
same question sits on different API surfaces**, which is not a constant mismatch
and cannot be fixed by renumbering. So `SIOCINQ` becomes `FIONREAD`, and
`SIOCOUTQ` becomes `getsockopt(SOL_SOCKET, SO_NWRITE)` — which
`darwin/src/posix.c` then translates *back* onto Linux's `ioctl`. A
cross-surface translation looks exotic and is exactly what a boundary is for.

**A corollary for anyone staging headers:** under this contract nothing above
libSystem should define Linux request numbers at all. A `FIONREAD` defined under
`#ifndef` in an overlay gives a constant whose value depends on which header a
translation unit reached first — the `nfds_t` two-widths problem again, with a
nondeterministic selector.

### `not-a-plain-forward` — six symbols that look like forwards and are not
Measured 2026-08-27 against Apple's SDK and glibc 2.39, after a consumer's
census classified all of these as "plain POSIX, present in glibc". Four of that
list genuinely are — `madvise` (the five common advice values agree),
`pwrite` (non-variadic, `off_t` 8 on both), `pthread_attr_init` and
`pthread_attr_destroy` (`pthread_attr_t` is 64 bytes on both). **These six are
not, and none is implemented.**

**`fcntl` — three independent disqualifications, and the second is the worst
collision found anywhere in this file.** The five commands a run loop uses
agree; the other five are *rotated into each other*:

| cmd | Darwin | glibc | | cmd | Darwin | glibc |
|---|---|---|---|---|---|---|
| `F_DUPFD` | 0 | 0 | | `F_GETLK` | **7** | 5 |
| `F_GETFD` | 1 | 1 | | `F_SETLK` | **8** | 6 |
| `F_SETFD` | 2 | 2 | | `F_SETLKW` | **9** | 7 |
| `F_GETFL` | 3 | 3 | | `F_GETOWN` | **5** | 9 |
| `F_SETFL` | 4 | 4 | | `F_SETOWN` | **6** | 8 |

Darwin's `F_GETLK` (7) is glibc's `F_SETLKW`, so a guest **asking** whether a
lock is held instead **acquires** it and blocks indefinitely — a query becomes a
hang. Darwin's `F_SETLK` (8) is glibc's `F_SETOWN`, so a `struct flock *` is
read as a pid. Darwin's `F_GETOWN` (5) is glibc's `F_GETLK`, and `F_GETOWN`
takes no third argument — so glibc writes 32 bytes through whatever register
was there. Separately, `struct flock` is **24 bytes on Darwin against 32**, so
even a correctly numbered `F_GETLK` overflows. And `fcntl` is variadic, so it
also carries the Darwin-arm64 varargs problem below.

**`dprintf`** is variadic — same reason `printf` has its own formatter here
rather than a forward. It must route through that.

**`sysctl`** cannot be forwarded in either direction. `sys/sysctl.h` **no longer
exists in glibc 2.39**, Linux's `sysctl(2)` was removed from the kernel and
returns `ENOSYS`, and Darwin's is an unrelated BSD MIB API (`CTL_HW`/`HW_NCPU`
integer arrays). The `sysctl` symbol survives in `libc.so.6` as a compat stub,
which is what would let a link succeed and a call do nothing. It wants
implementing per-MIB the way `sysconf` already is; the MIB set should come from
a real consumer rather than a guess.

**`pthread_attr_setschedpolicy` silently makes threads real-time.**
`SCHED_OTHER` is **1 on Darwin and 0 on glibc**; `SCHED_FIFO` is **4 against
1**; `SCHED_RR` is 2 on both and is the only one that agrees. A guest asking for
the *normal* scheduler is handed glibc's `SCHED_FIFO`.

**`pthread_attr_setschedparam`**: `struct sched_param` is 8 bytes on Darwin and
4 on glibc.

**`pthread_get_stackaddr_np` is inverted, not merely renamed.** glibc's nearest
equivalent, `pthread_attr_getstack`, returns the stack's LOW address; Darwin's
returns the HIGH one. Measured on macOS: `stackaddr` `0x16b79c000` with a local
at `0x16b799fd8`, i.e. below it, and `stackaddr - stacksize` giving the low
bound. An alias would be off by exactly the stack size — a pointer that looks
entirely reasonable and is at the wrong end of the right region.

**The general point, since this is the second census to arrive mis-sorted:**
"exists in glibc under the same name" is not the same claim as "has the same
ABI", and the four hazard families in `docs/ABI.md` are exactly the ways the two
come apart — struct size, constant value, scalar-typedef width, and variadic
convention. `fcntl` manages three of the four at once.

### `signal-surface-remaining` — what is still not exported
`sigaction`, `pthread_kill`, `kill` and `raise` translate. Still absent, and
each would need the same signal-number translation rather than a forward:
`signal(3)` (a `sigaction` wrapper on both systems, so it is cheap), `sigaltstack`
(`stack_t` is a third struct to compare), `sigqueue`, `killpg`, `psignal`,
`strsignal` (Apple's own strings, like `strerror`), and `sigwaitinfo`/
`sigtimedwait` (both return a `siginfo_t`, so they are blocked behind the same
thing `SA_SIGINFO` is).

**A note for anyone staging declarations for these.** A staged declaration
carrying a `GLIBCSYM` asm label binds **straight through to glibc and bypasses
the wrapper entirely** — the symbol resolves, the call succeeds, and the
translation never runs. That nearly happened to the `sigset_t` wrapper via a
labelled `signalfd`. The rule: `GLIBCSYM` means "this ABI is identical on both
sides"; anything listed in this section or translated in `darwin/src/posix.c`
gets a plain declaration.

### `poll-band` — a kernel difference, not a mapping we are missing
`poll` and `ppoll` translate three things (`darwin/src/posix.c`): `nfds_t`'s
width, the two flags Darwin and Linux number differently, and — for `ppoll` —
the `sigset_t`. One difference sits underneath all of that and no mapping
reaches it.

Darwin's `poll` is kqueue-backed and treats `POLLWRBAND` on an ordinary pipe as
satisfied by plain writability, answering `0x0100`. Linux answers `0`, because a
pipe has no write band. Measured on both, 2026-08-27. We report Linux's answer
under Darwin's name, because the alternative is inventing a readiness the
kernel never reported.

The same shape shows up on character devices in the other direction: Darwin
answers `POLLNVAL` for `/dev/null` and `/dev/zero`, where Linux answers
`POLLOUT`. That one cost `tests/src/poll.c` its first baseline, which is why
the fixture polls pipes.

Neither is reachable from an oracle-matching fixture, so both are recorded here
instead. `POLLRDHUP` is Linux-only and has no Darwin spelling; it is rejected
rather than passed through, since `0x2000` is outside Darwin's vocabulary.

`pipe2` is also absent: its flags word carries `O_NONBLOCK` and `O_CLOEXEC`,
which are among the ten `open` flags that differ, so it needs `open`'s
translation rather than a forward. Nothing has asked for it.

### `strerror-text`
`strerror` returns Apple's own strings, recorded from macOS into
`darwin/src/errno_table.h` by the generator. Numbers past Darwin's `ELAST`
produce Darwin's `"Unknown error: %d"` format. `strerror_l`, `strerror_r`'s
GNU variant and the `sys_errlist` array are absent.

### `locale-c-only`
`setlocale` accepts `"C"` and `"POSIX"` and returns NULL for everything else,
including `""`. That is a documented POSIX failure rather than a stub, and it
is deliberate: the alternative is to accept `en_US.UTF-8` and then classify
characters with a C-locale table, which is a lie a program cannot detect.
`localeconv`, `newlocale`/`uselocale` and the `*_l` function family are absent.
`_DefaultRuneLocale` is Apple's own C-locale table, recorded by
`scripts/gen_rune_table.sh`; there is no second table to switch to.

### `wide-chars`
`mbtowc`, `mbrtowc`, `wcwidth`, `wprintf` and the rest are absent. `wchar_t` is
4 bytes on both systems and `MB_CUR_MAX` is 1 in the C locale, so this is
tractable, but nothing in the corpus needs it and an untested implementation
would be worse than an honest absence.

### `getopt-long`
`getopt` is implemented (BSD semantics: it does not permute `argv`).
`getopt_long` and `getopt_long_only` are not — they need `struct option`, whose
layout is compiled into the guest. Two of the BSD utilities surveyed for rung
(m) want it.

### `err-warn`
`err`, `errx`, `warn`, `warnx` and `errc` are absent, and they are the single
most common gap in the BSD utilities surveyed. They are variadic, so they must
be written over the Darwin `va_list` like the printf family rather than
forwarded.

### `objc-callbacks` — **DONE**
`_dyld_objc_register_callbacks`, `_dyld_lookup_section_info` and the image
identity SPI are implemented in `src/objc_notify.c`, and
`darwin/usr/lib/libobjc.A.dylib` is Apple's objc4 built as Mach-O on Linux
(`scripts/build_objc4.sh`, 4 patches). `objc` passes byte-identically and 41
of `~/objc4-linux`'s 44 differential tests pass against the same macOS
baselines. Full accounting in `docs/OBJC4_MACHO.md`.

**The hybrid recommended in the previous version of this entry was wrong, and
the record of why is worth keeping.** It observed correctly that objc4-linux
*replaced* Mach-O image discovery rather than shimming it —
`compat/src/objc4linux-elf.cpp` walks `dl_iterate_phdr(3)` and on-disk ELF
section headers and hands objc4 a synthetic `struct mach_header_64` to cast
back. From that it concluded that rebuilding as Mach-O "undoes the port's
central change, so it is the expensive path", and proposed an ELF-backed Darwin
dylib plus a `objc4linux_register_foreign_image()` entry point in the sibling
project.

The error was treating that ELF layer as an asset. It was compensation for
running Mach-O source in the wrong format, and it is exactly what building as
Mach-O deletes. The three pieces it called for turned out to be:

1. *An ELF-backed Darwin dylib.* Not needed. The dylib is a real Mach-O, so
   `__objc_empty_cache` — the data import the entry rightly flagged, since every
   guest class points at it — binds through the ordinary two-level namespace to
   the runtime's own object. The identity problem it worried about does not
   arise.
2. *A foreign-image registration entry point in objc4-linux.* Not needed, and
   no change to the sibling project was made. objc4's existing
   `_dyld_objc_register_callbacks` path is the entry point; machorun implements
   the dyld side of it.
3. *Ordering.* Correct, and it was the one piece that survived: `mr_objc_note_image`
   is the hook, and it now calls `init` (load_images/`+load`) immediately before
   each image's own initialisers, with `mapped` delivered for every loaded image
   synchronously inside registration, as dyld does.

Two things the entry could not have predicted, both recorded in
`docs/OBJC4_MACHO.md`: `mapped`'s third argument is a *block*
(`void (^)(uint32_t)`) that objc4 calls to regain write access to a
`__DATA_CONST` we have already protected — passing NULL faults at the block's
`invoke` slot; and Darwin's `malloc_size` returns 0 for a pointer it does not
own, which objc4 uses as an ownership test, and glibc's `malloc_usable_size`
does not.

### `build-provenance` — what a gate can and cannot see about a local artefact
`scripts/check_stale.sh` now compares the **content** of an artefact's declared
source set against a stamp recorded when it was built, falling back to mtime
when no stamp exists. That closes the case mtime structurally cannot see: the
tree moving SIDEWAYS rather than forwards. A branch switch, a revert, a rebase,
or a build run while the working tree still held conflict markers all leave an
artefact newer than its sources while being built from different content.

**What is still not covered, stated so nobody reads more into the gate than is
there.** A stamp records that the SOURCES have not changed since the build. It
does not record that the build succeeded, that the compiler was the same one,
or that the environment matched — and it is written by `build.sh` immediately
after a successful build precisely because a stamp written at any other moment
is a lie that reads exactly like the truth. The input set is declared per
artefact in `TARGETS`, deliberately over-approximate: a false stale costs one
rebuild, a false fresh costs an afternoon.

Stamps live in `build/`, which is gitignored, so they do not travel. A fresh
clone gets the mtime check, which is the correct degradation — a clone has no
dylibs either, and that is MISSING rather than stale.

### `dyld-program-sdk-at-least` — correct today, and here is when it stops
`dyld_program_sdk_at_least()` returns 1 for every query. **That is the correct
answer for every binary this project can build**, measured rather than assumed:
every fixture carries `sdk 26.1` in `LC_BUILD_VERSION` (the SDK, not the
`macos11`/`macos12` deployment target), and the newest constant any caller asks
about is macOS 10.13 (2017), with `dyld_fall_2020_os_versions` (2020-09) the
newest wildcard date. An exact implementation returns 1 for all of them, so
**no fixture could distinguish the two** — which is why this is documented
rather than reimplemented. A change nobody can test is a change made on
speculation.

objc4 really does call it with the specific-platform constants
(`dyld_platform_version_macOS_10_11` and friends), so this is a live path, not
dead code.

**It becomes wrong the moment machorun runs a guest built against an OLD SDK**
— an app shipped years ago, which is exactly the kind of binary the project
exists to run. objc4 and libswiftCore would then take modern-behaviour branches
the binary was not written for, silently. The exact implementation needs the
program's `LC_BUILD_VERSION` (which `src/image.c` currently skips) plus, for the
`0xffffffff` wildcard-platform constants, dyld's own table mapping each
platform's version to a release DATE. The same-platform comparison is
unambiguous; **the date table must be copied, not guessed.**

### `dlopen-dlsym` — **DONE.** dlopen, dladdr and every dlsym handle
`dlopen` over guest Mach-O images, `dladdr`, and `dlsym` with `RTLD_DEFAULT`,
`RTLD_NEXT`, `RTLD_SELF`, `RTLD_MAIN_ONLY` and real handles all work. The objc4
corpus is **44/44**; rungs (af) `dlopen` and (ah) `dladdr` cover them
against real dyld.

**`dlopen`** is the startup sequence from `src/main.c` performed on demand for
one image — load, fixups, protect, TLV, objc `map_images` **for the new images
only**, then initialisers. The handle is the `mr_image *`. Resolution happens
BEFORE the is-it-loaded question, because a guest's spelling is almost never the
image table's; `dlclose` does not unload and says so.

**`dladdr` reads LC_SYMTAB, not the export trie**, and that is the difference
between working and looking like it works. Measured on macOS: `dladdr` on a
static, non-exported function returns its name. The trie carries only what an
image vends, so a trie-based implementation returns `dli_sname = NULL` — or,
worse, the nearest *exported* symbol below it, which is a wrong name with a
plausible address — for exactly the addresses a crash report cares about.
Measured details that are easy to get backwards: `dli_sname` has **no leading
underscore**, `dli_saddr` is the symbol's live address exactly, and the return
is **1/0**, not `-1`, with `dlerror()` left unset.

**THE THREE REMAINING GAPS WERE ONE GAP.** `dladdr`, the scoped `dlsym` handles
and `dlopen`'s `@loader_path` were all unimplemented for the same reason:
machorun had no notion of **the calling image**. The loader only ever sees its
own frames, so asking it there is asking the wrong process. Asking in
`libSystem.B.dylib` — a Mach-O we build, which the guest calls directly — makes
`__builtin_return_address(0)` the guest's own return address in the guest's own
image. **Nothing has to be walked**, and the notion that blocked three entries
turned out to cost one line at the right layer.

`RTLD_SELF` searches the caller's image and everything after it in load order;
`RTLD_NEXT` starts after the caller. That one-image difference is the whole
distinction, and a lookup ignoring scope passes every other case.

**`@loader_path` now resolves against the caller, and so does `@rpath`.**
`libSystem`'s `dlopen` passes `__builtin_return_address(0)` to the loader, which
turns it into an image with `mr_image_containing` — the same one line that
answers `dladdr` and the scoped `dlsym` handles. It decides three things, not
one: `@loader_path/` is the caller's directory, `@rpath/` searches the
**caller's** `LC_RPATH`s before the main executable's, and a relative path is
tried against the caller's directory before the cwd. `@executable_path`
deliberately does **not** move — it means the main executable from every image,
which is the only reason Darwin has both spellings.

The wrong answer here was never a crash. Resolving against the main executable
finds *a different file of the same name* and returns a valid handle to it: a
plugin gets the host app's copy of its own dependency, and nothing looks broken
until the two copies disagree about something. `tests/bin/loader_path` is
therefore built as four images in two directories, with two libraries
deliberately **sharing a basename**, so the correct answer and the old one are
both non-NULL and different. Teeth: restoring `MR.main_image` fails exactly 3 of
its 12 checks — the three that depend on the caller, and no others.

**Not covered, and named:** a `dlopen` whose *target* is missing now returns
`NULL` (below), but one whose target loads and whose **dependency** is missing
still aborts. Unwinding a partially-loaded graph needs a teardown path the
loader does not have — it never unmaps anything — so that is a real gap rather
than an oversight.

#### `dlopen` of an absent library returns NULL rather than aborting

A load command and a `dlopen` disagree about what "not found" means, and
machorun answered both the same way. An unresolvable `LC_LOAD_DYLIB` is fatal:
the program was linked against it and cannot run. An unresolvable `dlopen` is an
**answer** — "is this optional framework present?" is how CoreFoundation picks a
branch, and it asks about libraries it fully expects to be absent.
`mr_image_load` printed its tried-list and `_exit(72)`ed, which is right for its
own callers and wrong for that one.

Found by `tests/bin/loader_path`, whose last case `dlopen`s a library that is in
neither directory. The `dlopen` fixture never reached it: every path it names
exists, and `RTLD_NOLOAD` returns before the load.

**And the failure was invisible, which was the second finding.** On its first
Linux run the fixture reported exit 72 with **no stdout at all**, having already
passed eleven checks — because `_exit` does not flush and the guest shares the
loader's `stdout`. `mr_die` has always flushed for exactly this reason; two bare
`_exit` sites had been missed — `src/image.c`'s missing-dylib report and
`src/resolve.c`'s undefined-symbol report. Both now flush `stdout` before
writing to `stderr`. This is not confined to startup: a bind can fail during a
`dlopen`, long after the guest has printed.

### `blocks-byref`
`darwin/src/objcsupport.c` implements the Blocks runtime — `_Block_copy`,
`_Block_release` and the `_NSConcrete*Block` class objects — directly rather
than forwarding to Ubuntu's `libBlocksRuntime`, because `_NSConcreteStackBlock`
is a *data* symbol: a forwarding copy would be a different object than the one
clang's codegen compares against.

`_Block_object_assign` handles `BLOCK_FIELD_IS_OBJECT` and
`BLOCK_FIELD_IS_BLOCK` and **aborts on `BLOCK_FIELD_IS_BYREF`** — a `__block`
variable capture, whose byref header has a layout nothing here has measured.
objc4's own blocks never use one, so this is reachable only from a guest block.

`_Block_has_signature` / `_Block_signature` / `_Block_use_stret` return "no
signature", which makes `imp_implementationWithBlock` take the
register-return path unconditionally. Nothing in either corpus calls it.

### `swift-interop` — **DONE**, and the fix is where it is for a reason
`swift_retain` / `swift_release` used to be loud aborts in
`darwin/src/objcsupport.c`, i.e. exports of `libSystem.B.dylib`. That was
correct only while no Swift runtime could exist. machorun resolves a
flat-lookup bind by returning the **first** definition in load order, and
libSystem loads before `libswiftCore.dylib`, so once a real Swift runtime was
staged, objc4's fast-path refcounting still bound to the diagnostic abort with
the real implementation sitting one image away. The only workaround was to put
`-lswiftCore` ahead of `-lSystem` on the guest's link line.

They now live in **the loader** (`src/resolve.c`, listed `#internal` in
`darwin/loader-exports.txt`), which `mr_resolve_symbol` reaches only after every
loaded image has been searched and come up empty. A real libswiftCore therefore
wins by construction in any link order, and a guest without one still gets a
sentence rather than a jump through NULL.

Deleting them outright was not an option: `ld64.lld-18` has no `-delay_init`,
so objc4's two references are ordinary binds that must resolve at load time
even for a guest with no Swift runtime at all, and every Objective-C fixture
would have failed to load. `scripts/swift_gate.sh` links its fixture in **both**
dylib orders and requires both to pass, which is what stops this regressing.

### `swift-compat` — a guest must link `libswiftcompat.dylib` by hand
The `libswiftCore.dylib` we run (cross-built on Linux by `~/swiftcore-macho`)
imports 29 symbols machorun's self-hosted Darwin userland does not carry:
compiler-rt's 128-bit division, `getline` / `flockfile` / `strtod_l` and
friends, `getsectiondata`, `_NSGetMachExecuteHeader`, the availability checks,
and four `__cxxabiv1` `type_info` vtables. They are supplied by a separate
`libswiftcompat.dylib` which **the guest** has to name on its link line —
libswiftCore carries no `LC_LOAD_DYLIB` for it.

The measured consequence: a Swift binary built by **Apple's own toolchain** does
not run here, even though its three dependencies (`libSystem.B`, `libobjc.A`,
`/usr/lib/swift/libswiftCore.dylib`) are exactly the install names machorun's
prefix map already serves. It fails at load with

```
machorun: undefined symbol '__ZTVN10__cxxabiv117__class_type_infoE'
  wanted by:  darwin/usr/lib/swift/libswiftCore.dylib
```

because nothing pulled the compat dylib in. That is why rung (q) is the one
fixture whose two sides run two binaries built from one source rather than the
same committed bytes; `scripts/swift_gate.sh`'s header says so in place.

Two ways to close it, neither done: give libswiftCore an `LC_LOAD_DYLIB` on
libswiftcompat at link time (a `~/swiftcore-macho` change), or fold the 29 into
`darwin/src/` so machorun's own libSystem carries them (a machorun change, and
the one that would make Apple-built Swift binaries simply work).

### `tsd-direct-dynamic-key`
`_pthread_getspecific_direct` / `_pthread_setspecific_direct` serve the reserved
key block (0..257) and **abort** for anything above it. On Darwin the reserved
and dynamic keys are one flat array, so the direct SPI can also read a key that
came from `pthread_key_create`; here the dynamic half is glibc's and has no slot
to point at. objc4 uses slot 0 and 40..49 and nothing else, so this has never
been reached. Closing it means implementing the dynamic half ourselves instead
of delegating to glibc — see the TSD section header in
`darwin/src/objcsupport.c` for what that delegation buys and what it costs.

One deliberate divergence in the same area, measured rather than assumed:
`pthread_getspecific()` on an **out-of-range** key returns garbage on Darwin
(the fast path is a raw indexed load off the thread struct, and POSIX makes an
invalid key undefined behaviour) and **NULL** here. A differential probe of the
whole key ABI — first dynamic key, exhaustion count and code, the `EINVAL`
boundaries of `pthread_key_init_np` and `pthread_key_delete`, un-adopted
reserved keys, and destructor re-runs at thread exit — agrees line for line on
macOS and under machorun apart from that one. Reproducing an out-of-bounds read
is not parity worth having.

### `objc-cache-never-collects` — a LEAK, not a stub
`patches-macho/0004`. `_collecting_in_critical()` returns TRUE unconditionally,
meaning "a reader may be active, do not free", so `cache_collect()` never
reclaims and **every method-cache reallocation leaks the old bucket array**.

Both of Darwin's answers to "is a thread inside the cache scan right now?" are
unavailable: `task_restartable_ranges_synchronize()` needs XNU (Linux's
`rseq(2)` aborts rather than restarts), and the fallback needs `task_threads()`
+ `thread_get_state()`, which is real Mach IPC. The Linux-native version --
walk `/proc/self/task`, signal each thread, sample `uc_mcontext.pc` in the
handler -- is implementable and unwritten.

Returning FALSE instead would be a use-after-free, so the polarity is the safe
one. `~/objc4-linux` made the identical choice and quantified the cost: ~8.7 KB
per invalidation, and a swizzling workload costing macOS 4.7 MB peak RSS costs
177 MB here.

### `malloc-zones-are-one-heap`
`malloc_default_zone()` returns a token, and every `malloc_zone_*` call routes
to glibc's single heap. A program that treats a zone as a separate arena --
mass-free by zone, zone introspection, `malloc_zone_from_ptr` -- would notice;
objc4 only ever uses the default zone. `malloc_zone_malloc` aborts if handed a
zone pointer we did not mint, so "someone created a zone" is visible rather
than silent.

Note `malloc_size` is **not** `malloc_usable_size` and is implemented
separately in `darwin/src/libsystem.c`: Darwin returns 0 for a pointer no zone
owns and callers use that as an ownership test. See `docs/OBJC4_MACHO.md` §5.

### `objc-sdk-dependency` — **DONE**
`scripts/build_objc4.sh` used to need a macOS SDK's `usr/include` and refused to
run without one, which meant `darwin/usr/lib/libobjc.A.dylib` was reproducible
on a machine with Xcode and not otherwise. **It no longer is.** `OBJC4_SDK`
defaults to `sdk/` — this repository's own header-only, `.tbd`-only SDK — and
Xcode is not a build input to anything any more.

355 headers: 332 vendored from eleven pinned `apple-oss-distributions` releases
(all redistributable), 1 produced by running xnu's own published generator,
4 from `vendor/objc4`, and **19 clean-room headers of ours** in `sdk/local/`.
Apple's libc++ — 67% of the old surface — is gone entirely: the build uses stock
LLVM 18 libc++ with three `-D` flags, and `harness/Dockerfile` pins it.
`sdk/PROVENANCE.md` is the full accounting, including what each clean-room
header omits versus Apple's.

Measured after the switch: **32 objects / 0 failures**, `scripts/objc44.sh`
**41/44** with the same three failures, `scripts/difftest.sh` unchanged at
**19 pass / 1 xfail / 1 no-oracle**, and a new `scripts/sdk_abi_probe.sh` whose
149 lines of struct offsets, `errno` values and `_DefaultRuneLocale` bytes are
**byte-identical** between Apple's SDK on macOS and ours on Linux.

Two things the survey got wrong, both found by compiling:

* **`math.h` is a genuine category-(c) header.** The survey headlined that the
  only-in-Xcode category was empty; it is off by one. Apple's published Libm is
  a 2002 drop whose `Source/math.h` dispatches to 32-bit `architecture/*/math.h`
  and `#error`s on `__arm64__`. Clean-roomed from ISO C99 §7.12 instead.
* **A published header is not an installed header**, and the difference is not
  always loud. See `sdk-published-vs-installed` below.

### `sdk-published-vs-installed` — a silent-wrongness risk, now guarded
Apple's header-install step transforms source-release headers, and nothing in a
published tree does it for us. Two transforms bit while assembling `sdk/`:

1. **`//Begin-Libc` regions.** Libc's own `xcodescripts/headers.sh` deletes
   them; skip it and `_ctype.h` arrives with `#include "xlocale_private.h"` and
   28 of 32 objc4 TUs stop dead. `scripts/sdk_stage.sh` reproduces the rule.
2. **`XNU_PLATFORM_<name>` selection.** xnu's headers carry every Apple
   product's settings behind `#ifdef`; Apple resolves them with `unifdef`. With
   none defined, `sys/cdefs.h` leaves `__DARWIN_ONLY_UNIX_CONFORMANCE` undefined
   and every `__DARWIN_ALIAS`'d libc function gets renamed — 7 `$UNIX2003`
   symbols nothing exports — **and** `mach/arm/vm_param.h` silently drops
   `MACH_VM_MAX_ADDRESS_RAW` from 128 TB to the embedded 64 GB value.
   `sdk/patches/0002-xnu-platform-macosx.patch` selects MacOSX in the header,
   where it cannot be forgotten on a command line.

The first failed loudly. **The second did not**, and would not have: nothing
fails to compile, the number is just wrong. That is the risk
`docs/SDK_SURVEY.md` §6.1 named, and `scripts/sdk_abi_probe.sh` now exists to
catch its next instance — but the probe only covers what it prints. A field
offset or constant it does not name can still move silently. Add to it when
adding to the SDK.

Apple's `unifdef` pass over Libc headers is deliberately *not* reproduced (its
inputs are build flags we do not have). If that ever stops being harmless, it
will show up as a compile error or as an `sdk_abi_probe` diff.

### `mach-thread-state`
`sdk/local/mach/thread_act.h` declares `thread_get_state` and
`darwin/src/mach.c` does not implement it. objc4's `objc-cache.mm` needs the
declaration to compile: `_get_pc_for_thread()` reads `ARM_THREAD_STATE64` to
decide whether a thread is inside a cache-reading function.

Today this costs nothing, and that is measured rather than hoped:
`_collecting_in_critical()` is unreachable in this configuration, the optimiser
drops its caller, and the resulting `libobjc.A.dylib` does not import
`_thread_get_state` at all. `scripts/gen_tbd.sh`'s check 3 re-verifies that on
every build. A guest that really calls it gets machorun's normal
undefined-symbol abort naming `_thread_get_state`.

Implementing it means reading another thread's register state, which on Linux is
`ptrace(PTRACE_GETREGSET)` against a stopped thread — a real capability with
real permission requirements, not a shim. It stays unimplemented until something
needs it. `thread_set_state` is not even declared.

### `isa-va-width` — a silent-corruption risk, not a stub
*Inherited from `~/objc4-linux/docs/PORT_PLAN.md`'s second-riskiest unknown; see
`docs/OBJC4_MACHO.md` §9.3. The 47-bit half of this is now closed by placement
and checked at startup; the objc4 52-bit-kernel half below still aborts nowhere,
which is the part that remains a risk.*

objc4 packs the class pointer into the isa word and the `class_rw_t` pointer
into `class_t::bits`, and Darwin sizes both fields from a *known* Mach VM
ceiling. Linux/aarch64's user VA width is a **kernel configuration**
(39/42/48/52-bit) and is not fixed across machines.

| field | our value | pointer bits | headroom | source |
|---|---|---|---|---|
| `ISA_MASK` | `0x007ffffffffffff8` | 3..54 | 7 bits | `patches-macho/0001` |
| `FAST_DATA_MASK` | `0x0f007ffffffffff8` | 3..46 | none needed | **stock objc4** |
| `DEBUG_DATA_MASK` | `0x00007ffffffffff8` | 3..46 | — | **stock objc4** |

The `FAST_DATA_MASK` row used to read `0x0f00fffffffffff8`, bits 3..47,
**headroom none** — a widened value from `patches-macho/0001`, and the sharpest
hazard in this section, because `class_rw_t` is a *heap* pointer and the heap
sat above 2^47. Both halves of that are gone: the loader now confines images
**and** the heap below 2^47, so stock objc4 holds and the hunk was deleted
rather than documented better. `DEBUG_DATA_MASK` is once again bit-identical to
Apple's.

`ISA_MASK` stays patched, and not for the reason that patch used to give. It is
not about Linux at all — objc4 rejects the alternative at **compile time**.
Reverting it selects plain-arm64's 33-bit `shiftcls` (`0x0000000ffffffff8`, a
64 GiB ceiling: the iOS *device* layout), and `objc-runtime-new.mm:260`'s own
`STATIC_ASSERT` then fails against a macOS target's 128 TiB
`OBJC_VM_MAX_ADDRESS`. Apple never ships plain-arm64-non-e on macOS; real macOS
arm64 libobjc is arm64e and takes the same branch this patch selects. So that
hunk makes us **match** Apple's shipping runtime rather than diverge from it,
and the measured VA width is why the layout works for us, not why it is
required.

Measured on the test kernel (`6.12.76-linuxkit`, arm64): default `mmap`
returns `0xffff88f9e000`, `malloc` `0xaaaabf7f82a0`, and an `mmap` hint of
`0x10000000000000` (2^52) is **ignored**, returning `0xffff88f9d000`. So on
this kernel no user address exceeds 48 bits.

**Do not read that paragraph as reassurance.** "No user address exceeds 48
bits" is true, and it is about the wrong number. objc4's widened masks are 48-
and 55-bit, so 48 bits is enough for *them*; libswiftCore's inlined mask is
**47** bits, and `malloc 0xaaaabf7f82a0` -- the very address quoted above as
evidence that everything is fine -- has bit 47 set. It is the counterexample,
not the proof. Everything from here down is about that 47-bit mask.

What is not guaranteed for objc4's own masks: on a kernel built for 52-bit VAs,
Linux hands out addresses above 2^48 only when an `mmap` hint asks for one --
but if a guest ever gets a `class_rw_t` up there, `FAST_DATA_MASK` truncates it
and every object pointing at that class is corrupt, silently.

#### The 47-bit mask, and the two places a high address comes from

libswiftCore is compiled with Apple's macOS/arm64 `ISA_MASK`
(`0x00007ffffffffff8`, bits 3..46) inlined at 48 sites, and it cannot be
widened without forking the standard library. So machorun places things where
that mask can address them. There are two independent sources of high
addresses, and fixing one does nothing for the other:

1. **Mapped images.** `mmap(NULL, ...)` is served top-down from near 2^48, so
   every dylib landed at `0xffff_xxxx_xxxx`. Fixed by the arena in `src/map.c`,
   which places every image below 2^47; `tests/bin/isa_mask` asserts it.

2. **The heap**, which the image arena does not reach. A generic class's
   metadata *is* the class its instances point at, and libswiftCore builds it
   at run time. `nm -u libswiftCore.dylib` lists `_malloc`, `_calloc`,
   `_posix_memalign` and **no `mmap` at all**, so that metadata comes from
   glibc. Linux puts a PIE at `2*TASK_SIZE/3` and brk follows the image, so the
   main arena sat at `0xaaab_xxxx_xxxx` -- above 2^47 -- and no *mmap* policy
   could move it. Fixed by linking the loader non-PIE at `MR_LOADER_BASE`
   (1 TiB) so brk starts low, plus `mr_constrain_heap()`'s two `mallopt` calls;
   `src/main.c` re-checks the result at startup.

The heap half stayed hidden for a long time because libswiftCore's first 64 KiB
of metadata come from `InitialAllocationPool`, a **static array in its own
`__DATA`**, which the image arena already places low. Any small Swift program
therefore passes no matter how wrong the heap policy is. Measured with images
already mapped low: a guest instantiating 900 distinct generic classes died with
`SIGSEGV at libswiftCore+0x332898, fault address 0x2aab1d407ec8`, which is the
ordinary main-arena address `0xaaab1d407ec8` with bit 47 cleared. The same
binary exits 0 with the loader linked low.

**Reading a fault address here.** A truncated pointer looks like something it
is not: `0x7fff8a2c6010` reads like a stack address and is actually the image
pointer `0xffff8a2c6010` with bit 47 stripped, and `0x2aab…` is a heap pointer
the same way. If a fault address is the real one minus `0x800000000000`, this
is the bug and not memory corruption. That misread cost real time.

**What aborts, and where.** Three checks, because each covers a case the others
cannot see:

| check | in | catches |
|---|---|---|
| loader text below `MR_ISA_LIMIT` | `check_host()` | a build that lost `-Ttext-segment` |
| `sbrk(0)` and a `malloc(64)` probe | `mr_constrain_heap()` | the main arena starting high, or either `mallopt` being refused |
| a `malloc(64)` probe on the first guest thread | `mr_thread_trampoline()` in `darwin/src/libsystem.c` | a **secondary** arena — created lazily in the thread that first needs one, so it cannot exist when the loader's own probe runs |

The third is not belt-and-braces. `M_ARENA_MAX` carries most of the weight here:
measured on glibc 2.39 with 16 threads x 201 allocations, the two `mallopt`
calls give **0** allocations at or above 2^47, and removing them with nothing
else changed gives **3216 of 3216** -- every secondary thread allocates from an
mmap'd arena at `0xffff_xxxx_xxxx`. A refusal is therefore fatal, not logged.

`mallopt(M_ARENA_MAX, …)` cannot in fact fail on glibc: `__libc_mallopt`
returns 0 only for an unrecognised parameter, so that abort guards against a
future libc rather than a live risk. `M_MMAP_THRESHOLD` **can** be refused --
`do_set_mmap_threshold` rejects anything above `HEAP_MAX_SIZE/2`, which is
exactly the 32 MiB we ask for. We sit on that boundary deliberately: raising the
constant would silently turn the knob off rather than widen it.

**There is no residue any more, and the one there used to be was a mistake.**
This section previously recorded that a single allocation at or above glibc's
32 MiB `M_MMAP_THRESHOLD` cap still came from `mmap` and still landed above
2^47, and argued it was safe because no class object is 32 MiB. The argument was
true and the conclusion was wrong: **a hole in a guarantee is not made safe by
writing it down**, and it sat inside the one check the whole isa-mask fix rests
on. Measured: 1 MiB low, and 32 MiB / 64 MiB / 256 MiB / 1 GiB all at
`0xffff_xxxx_xxxx`.

`mallopt(M_MMAP_MAX, 0)` closes it -- that forbids `malloc` from using `mmap`
at all, where `M_MMAP_THRESHOLD` alone could not, because glibc caps the
threshold at exactly the 32 MiB in question. Every size up to 1 GiB now lands
below the limit, each verified by writing to the whole block so the memory is
demonstrably real.

The cost, named rather than buried: a large block the guest frees returns to the
brk free list instead of being `munmap`'d, so RSS can stay high after a big
free. That is a retention cost, and it buys the property that no allocation can
be handed to Swift as an unaddressable class pointer.

**And the check now covers the case it used to be blind to.** The old probe
allocated 64 bytes and concluded the heap was low -- verifying only the case it
was written for, since small allocations were never in doubt. `mr_constrain_heap()`
now probes a second time at 33 MiB, on the far side of the old boundary. Teeth
verified by removing `M_MMAP_MAX` and nothing else: the loader aborts at startup
naming the size and the address, in a configuration where the *old* probe still
passed.

objc4's own `STATIC_ASSERT` does **not** cover this. It checks `ISA_MASK`
against the SDK's `MACH_VM_MAX_ADDRESS` -- a compile-time fact about Darwin --
and it is what forced `patches-macho/0001` to exist at all. There is no
equivalent check against the *host kernel's* ceiling, and there cannot be one
at compile time.

The fix for the remaining `FAST_DATA_MASK` case, when it is needed, is a startup
assertion in `src/objc_notify.c` that every image and heap address fits it,
aborting loudly rather than corrupting. `mr_constrain_heap()` and `check_host()`
already do exactly this shape of check against the tighter 47-bit limit, so the
pattern is in the tree to copy. The ELF port's alternative -- force
`SUPPORT_NONPOINTER_ISA 0` -- is deliberately **not** taken: it costs
performance and changes `objc_debug_isa_class_mask`, which Swift reads.

### `objc-load-ordering`
*Also inherited; `docs/OBJC4_MACHO.md` §9.2 has the full account.*

The Darwin contract -- `_objc_init()` before any initialiser, `map_images` for
a batch, then `load_images` -- is **restored** here rather than approximated,
because we own the loader (`src/main.c`, `src/objc_notify.c`). `+load` precedes
every initialiser in its own image by construction. That was `~/objc4-linux`'s
riskiest unknown, and it is the one thing being Mach-O genuinely deletes rather
than relocates.

What remains untested is ordering *across* images. `docs/STATUS.md` §3 records
that the mutation "initialiser dependency order reversed" **survived** -- no
fixture image has more than one dependency, so there is no order to get wrong
-- and `tests/objc44/041-multi-image` is a two-image program. The contract is
implemented; the dependency sort is not differentially tested. Closing this is
a fixture with a diamond dependency graph, not code.

### `unwind-compact` — **DONE.** Exceptions throw, unwind and are caught
**C++ and Objective-C exceptions work.** LLVM 18.1.8's libunwind and libc++abi
are compiled from `vendor/libunwind` and `vendor/libcxxabi`, **both pristine,
zero patches**, and the loader supplies the half only dyld can know:
`_dyld_find_unwind_sections` and `_dyld_register_func_for_remove_image`
(`src/unwind.c`). `tests/src/throw.cpp` (rung ac) throws across frames and
is caught by type, and `tests/objc44/038-exceptions` and
`044-exception-through-uncached` now pass — objc44 went from **41/44 to 43/44**,
with only `042-dlopen` left.

**THE LAYOUT MATCHES DARWIN'S, AND THAT WAS NOT THE FIRST ATTEMPT.** Verified
against Apple's SHIPPED `libswiftCore` with `nm -m`, which is the authority:
`__Unwind_Resume` is *from libSystem* and `___gxx_personality_v0` is *from
libc++*. So:

* **libunwind is inside `libSystem.B.dylib`** — on macOS `libunwind.dylib` is a
  sub-library of the libSystem umbrella and libSystem re-exports it.
* **libc++abi is its own `/usr/lib/libc++abi.dylib`**, `libc++.1.dylib`
  re-exports it, and `libobjc.A.dylib` LINKS against it as Apple's does.

The first arrangement put libc++abi inside libSystem, reasoning that
`038-exceptions` loads only libobjc and libSystem so nothing else could be
found. It worked for objc4 and **failed for C++ guests**: a guest linking
`-lc++` binds `__ZNSt13runtime_errorD1Ev` two-level against `libc++.1.dylib`,
and ours had nothing to re-export, so the symbol was present in the process and
unreachable from the only library allowed to answer. *"Put it where the current
consumer will find it"* is the reasoning that produced the bug; reproducing
Darwin's shape is what fixed it.

**THE ONE DELIBERATE DEVIATION IS GONE, on its own exit condition.**
`libSystem.B.dylib` used to also re-export `libc++abi.dylib`, which macOS does
not do, so that `~/swiftcore-macho`'s source-built `libswiftCore` — which
carried a stale two-level bind for `___gxx_personality_v0` naming libSystem —
still loaded. swiftcore-build relinked it (`cc58d4f`) and the bind now reads
*from libc++*, as Apple's shipped one does, so the `-reexport_library` and
`gen_tbd.sh`'s `tbd_skips_reexport` exception were deleted together in one
commit. **machorun's layout now matches Darwin's with no deviations.**

Checked by content on the artifact actually staged, not on a successful build:

```
nm -m darwin/usr/lib/swift/libswiftCore.dylib | grep gxx_personality
    (undefined) external ___gxx_personality_v0 (from libc++)
otool -l darwin/usr/lib/libSystem.B.dylib | grep LC_REEXPORT_DYLIB
    (nothing)
```

**And the `.tbd` fix turned out to do more than the one symbol.** Six further
imports in libswiftCore moved off flat binds at the same time — the four
`__cxxabiv1::*_type_info` vtables, `__ZdlPvmSt11align_val_t` and
`___cxa_demangle` — which are *exactly* the six that `libswiftcompat` had been
shadowing (`duplicate-definitions` above). Deleting them from the shim fixed
the process that exists; making libswiftCore **name the library it wants** means
it cannot be shadowed on them by load order at all, even by a shim that
reintroduced them. Two fixes from opposite ends of the same defect.

**What upstream took back, and what it improved.** `operator new`/`delete` and
the `__cxa_guard_*` trio now come from libc++abi rather than
`darwin/src/libcxx.c`. That was forced by measurement, not tidiness: libc++abi
itself calls `operator delete[]`, and the objc44 corpus does not load
`libc++.1.dylib`, so all 44 failed with *"undefined symbol `__ZdaPv`, wanted by
libc++abi.dylib"*. Both replacements are better than what they replace — the
operators now THROW `std::bad_alloc` instead of aborting, and **the guards are
thread-safe**, closing limit 1 of `libcxx-subset` below, which said in as many
words *"if that changes, this needs to grow rather than be trusted"*.

`darwin/src/libcxx.c` now holds exactly one thing upstream LLVM 18 lacks:
Apple's TYPED `operator new`/`delete` (`__ZnwmSt19__type_descriptor_t`), which
Apple's shipped libswiftCore binds two-level from libc++.

**`pthread_mach_thread_np` is implemented and this closes the sweep.**
foundation-scope's audit covered ICU (zero references, structurally) and our
libc++ but could not reach libunwind or libc++abi. Measured on both:
libunwind's entire external surface is three `pthread_rwlock` calls, two
`_dyld_*` calls and plain libc — no Mach anything. **libc++abi's `cxa_guard`
does need it**, for `PlatformThreadID()`, as a thread IDENTITY and never as a
port to send on — so `mach_thread_self()`'s name is exactly right and
`darwin/src/mach.c` translates rather than stubs. It is limited to the CURRENT
thread and bails loudly otherwise, because our port names live in thread-local
storage and inventing one for another thread would break the single property
callers depend on.

**Still absent, and named rather than rounded off:** `cxa_thread_atexit.cpp`
(needs `__cxa_thread_atexit_impl`, see `tlv-thread-atexit`), and the Objective-C
side is only as good as objc4's own — `objc_exception_throw` works because
objc4 builds on `__cxa_throw`, not because anything here reimplements it.

**Two things a future implementor should know**, both learned the hard way.
`_Unwind_FindEnclosingFunction` is *not* a function-identity oracle: compact
unwind COMPRESSES, so consecutive functions with identical encodings share one
entry and it reports the start of the RUN. And `_Unwind_GetIP` returns a RETURN
address, so any lookup on it needs `ip - 1` or it names the following function.

---

## Fixture corpus and harness

Owned by `tests/`, `harness/`, `scripts/difftest.sh`. See `docs/FIXTURES.md`
for the full ladder. These are not stubs — they are gaps in *test coverage*,
which is the same kind of dishonesty if left unstated.

### `fixture-raw-syscall` — permanent wall
*`exit_raw`, graded `XFAIL` forever.*

A binary executing `svc #0x80` with a BSD syscall number in `x16` cannot be
supported by the replace-libSystem bet. On Linux/arm64 `svc` traps to the
Linux kernel, which reads the number from `x8` under Linux numbering. Fixing
it means seccomp trapping or static rewriting — the Darwin-syscall-emulation
road this project chose not to take. The fixture stays in the corpus so the
boundary appears in every test run instead of being forgotten.

### `fixture-unixthread-no-oracle`
*`exit_unixthread`, graded `NO-ORACLE`.*

Correction to the `lc-unixthread` entry above: the modern toolchain **will**
emit `LC_UNIXTHREAD` for userland code — `clang -target arm64-apple-macos11
-nostdlib -e _start -static` does it, and the fixture is committed at
`tests/bin/exit_unixthread` with its full `otool -l` in
`tests/meta/`. Its only load commands are `LC_SEGMENT_64`×3,
`LC_UNIXTHREAD`, `LC_SYMTAB`, `LC_UUID`, `LC_SOURCE_VERSION`.

What is true is that **macOS cannot run it**: macOS 11+ on arm64 SIGKILLs any
executable without `LC_LOAD_DYLINKER` (exit 137). So there is no baseline and
differential testing can never grade it `PASS`. It is a parse-only fixture; if
the loader runs it, verify by inspection against the recorded `otool -l` and
say so honestly rather than claiming a PASS the harness cannot back.

### `fixture-arm64e`
No pointer-authentication fixture exists, so `DYLD_CHAINED_PTR_ARM64E` and
`__auth_got` are untested by the corpus. This is not merely unbuilt: macOS does
not run third-party `arm64e` userland binaries, so **no oracle is obtainable**
and the `arm64e` rejection path can only ever be unit-tested, never
differentially tested. Consistent with the `arm64e` entry above treating it as
out of scope.

### `fixture-coverage-gaps`
Not exercised by any fixture, therefore unverified no matter what the loader
does: stdin; environment variables; signals; `fork`/`exec`; socket I/O;
`dlopen`/`dlsym`; C++ exceptions; `LC_MAIN.stacksize != 0`;
`LC_REEXPORT_DYLIB`; weak and weak-defined symbols; two-level-namespace
*misses*.

Each is a rung that does not exist yet. Adding one means adding a fixture,
recording it on macOS, and listing it in `tests/manifest.tsv` — not asserting
it works.

**Two entries left this list on 2026-08-26** and the reason the second one did
is worth keeping:

* **`argv` beyond `argv[0]`, and file output.** The three drawing fixtures
  take their output path from `argv[1]` and write a PNG through
  `fopen`/`fwrite`, so both are now on the critical path to a graded artefact.
* **`__DATA,__objc_catlist`.** The old text said ld64 merges same-image
  categories into the class so the corpus never produces one, and for `objc`
  that is exactly what happens — its `Counter (Doubling)` category leaves no
  `__objc_catlist` at all. `objc_shapes` produces one anyway, plus an
  `__objc_nlcatlist`, both 8 bytes, one entry each. The difference is that its
  category **implements `+load`**: a category with a `+load` cannot be merged
  away, because `+load` has to be called as a separate thing at a defined point
  in the load order. So the correct statement is not "ld64 merges categories"
  but "ld64 merges categories it is allowed to merge", and `+load` is the lever
  that stops it. That is now covered, and `docs/FIXTURES.md` rung (p) lists the
  other four sections no earlier fixture produced.

### `fixture-nonreproducible`
Rebuilding a fixture from identical sources yields different bytes (fresh
`LC_UUID`, fresh ad-hoc code signature). The committed binaries in `tests/bin/`
are the reference; `tests/build_fixtures.sh` exists for auditability, not as
part of the test loop. If you rebuild, commit the new binaries and the
re-recorded baselines together, in one commit, and say why.

### `fixture-concurrency`
`pthread` is the only concurrency test and is deliberately deterministic
(fixed join order, all printing from `main`). It detects gross breakage in
`pthread_create`/`join`/`mutex`/`once` and per-thread TLV allocation. It
cannot detect races. Do not read a PASS there as "threading works".

### `quartz-surface`
`darwin/usr/lib/libquartz.dylib` exports 507 symbols and **all of them work**
— it is `vendor/quartz` compiled, not a stub layer, so there is no abort in it
to document. Two limits are worth recording anyway, because neither is visible
from the export list:

1. **It is `QZ*`, not `CG*`.** Nothing here answers
   `CGBitmapContextCreate`, `CGContextFillRect` or any other CoreGraphics
   symbol, and no `CoreGraphics.framework` exists in `darwin/`. A guest linked
   against Apple's CoreGraphics will fail to resolve every one of its imports,
   by name. Bridging `CG*` onto `QZ*` is a separate piece of work with its own
   ABI questions (`CGFloat` is `double` on arm64 and `QZFloat` already is;
   `CFTypeRef` retain/release semantics are not; `CGColorSpaceRef` is a real
   CoreFoundation object and `QZColorSpaceRef` is not).
2. **`-fno-exceptions`.** Quartz never throws, but libc++'s bounds and
   allocation checks do, and with this flag they become
   `_LIBCPP_VERBOSE_ABORT` — a loud trap rather than a `std::length_error` a
   caller could catch. On macOS, code built the ordinary way would get the
   exception. Nothing in the drawing paths reaches one; a guest that manages to
   would crash here and unwind there. See `unwind-compact`.

### `quartz-fixture-coverage`
The three drawing fixtures together call **36 of libquartz's 507 exported
symbols** directly — 34 from `quartz`, 8 from `objc_quartz`, 18 from
`objc_shapes`, overlapping heavily
(`nm -u tests/bin/1[567]* | grep _QZ | sort -u | wc -l`). Adding Objective-C on
top therefore bought exactly **two** further exports
(`QZContextAddRoundedRect`, `QZContextFillEllipseInRect`) and nothing else, and
that is worth stating rather than letting a rung count imply otherwise: rungs
(o) and (p) are a test of *dispatch*, not of drawing coverage. What those 36
reach internally is more than 36, but it is not measured and should not be
guessed at. Untested and therefore unverified no matter how green the PNG diff
is: the whole Core Animation layer
tree (`QZLayer*`, `QZAnimation*`, the replicator and transform layers), text and
font loading (`stb_truetype`), image decode (`stb_image`), PDF output, patterns,
shadings, CMYK and Display P3 colour, blend modes other than normal, and
transparency layers.

Those are not stubs — they are compiled and exported and presumably work, since
upstream scores 97.46/100 against Apple's frameworks with all of them. They are
simply not covered *here*, which is a different claim. Adding coverage means
adding drawing stages to `tests/src/quartz.c`, rebuilding the fixture on
macOS, and re-recording with `scripts/quartz_pixel.sh --record` — not asserting
that a passing PNG generalises.

### `objc-drawing-coverage`
What rungs (o) and (p) do **not** reach, listed so the next reader does not
have to infer it from what they do:

* **No ARC, no exceptions, no `NSObject`.** Both fixtures are Foundation-free
  root-class programs, exactly like `objc`. `-retain`/`-release`/
  `-autorelease`, `@try`/`@throw` and everything that needs a real base class
  are covered — where they are covered at all — by `tests/objc44/`, and the
  exception cases there are the two that fail (`unwind-compact`).
* **No dynamic runtime mutation on the drawing path.**
  `class_addMethod`/`method_exchangeImplementations`/`objc_allocateClassPair`
  are `tests/objc44/013`–`024`; no *pixel* depends on one, so a bug that only
  shows up when an IMP is swizzled mid-render would not be caught here.
* **One image.** Every class, category and protocol in both fixtures lives in
  the executable. Categories or `+load` in a *dylib*, and therefore the
  cross-image half of `objc-load-ordering`, are still untested by anything that
  draws.
* **No message to `nil`, no forwarding.** `-forwardInvocation:`/
  `+resolveInstanceMethod:` are not reached; a `nil` receiver returning a
  `QZRect` (the HFA-return path stage 4 relies on) is not exercised either.
* **`+initialize` ordering is asserted for one interleaving.** The printed
  order is the one this scene's construction sequence produces. A different
  first-touch order is a different test, and there is only the one.

### `cross-image-cxx-init-unpinned` — exercised, but not pinned

The drawing fixtures were expected to be the first thing in the corpus to test
**C++ static-initialiser ordering across two dylibs**, because `libquartz.dylib`
is 37 C++ translation units and the guest is a separate image. They do exercise
it, and they do not pin it. Both halves are measured.

**What runs.** `libquartz.dylib` is the only image in the process that has an
initialiser section at all — `__DATA_CONST,__mod_init_func`, five entries
(`machorun -v` prints each one). Disassembling them names the translation units:

    __GLOBAL__sub_I_pkg_anim.cpp        -> __ZL7g_anims
    __GLOBAL__sub_I_pkg_color_p3.cpp
    __GLOBAL__sub_I_pkg_pattern.cpp     -> __ZL5g_pat
    __GLOBAL__sub_I_pkg_pdf.cpp         -> __ZL9g_writers
    __GLOBAL__sub_I_pkg_timing.cpp      -> __ZL9g_anim_tf

`libSystem.B.dylib`, `libc++.1.dylib`, `libobjc.A.dylib` and each of the three
fixtures have **no** initialiser section — the loader says so by name rather
than silently finding nothing. The observed order is dependency-first:
libquartz's five constructors, then libobjc's `load_images`, then the guest's
`load_images` (its six `+load` methods), then the guest's own initialisers
(none). That is dyld's order.

**What is not pinned, and how that was measured.** A mutation was put into
`src/init.c` behind an environment variable that skips every
`S_MOD_INIT_FUNC_POINTERS` entry — i.e. *none* of libquartz's five constructors
run — and the three drawing fixtures were run against the committed macOS
baselines with the loader and libquartz both rebuilt clean:

| | `quartz` | `objc_quartz` | `objc_shapes` |
|---|---|---|---|
| control | PNG identical, stdout identical | identical | identical |
| all 5 constructors suppressed | **PNG identical, stdout identical** | **identical** | **identical** |

So the mutation **survives**. The reason is that the four named globals are
file-scope `std::vector`/`std::map` registries for animation, patterns, PDF
writers and timing functions: zero-initialised `.bss` is already a valid empty
container, nothing in `quartz-fixture-coverage`'s 36 exports reads them, and
the constructors are therefore observationally dead in these three programs.

`docs/STATUS.md`'s "cross-image initialiser ordering is UNTESTED" is thus half
closed: the *discovery and invocation* path is now exercised by a real
multi-dylib program, but **no pixel and no line of stdout depends on a
cross-image constructor having run**, and no fixture asserts the *order* of one
against a `+load` or against another image's constructor. A loader that ran
dependency initialisers in the wrong order, or not at all, would still score
19/1/1 and 3/3 here.

Closing it needs a fixture whose output depends on a constructor in a dylib —
the smallest honest version is a second dylib of our own, alongside
`libdylib_greet.dylib`, with a file-scope object whose constructor prints and whose
value the executable reads, plus a `+load` in that same dylib so the two
orderings are asserted against each other. That also closes the "One image"
bullet in `objc-drawing-coverage` and the cross-image half of
`objc-load-ordering`.

### `os-unfair-lock-owner` — **FIXED 2026-08-26**, verified on Graviton3

The owner token is no longer derived from `pthread_self()`. `mr_thread_token()`
(`darwin/src/objcsupport.c`) hands each thread a sequential id from an atomic
counter on first use and caches it in a private slot of the direct-TSD array —
index 64, one past the 64 slots `_pthread_getspecific_direct` and
`_pthread_setspecific_direct` will address, so no guest can read or clobber it
and no TSD destructor runs over it. Both `unfair_token()` (`libsystem.c`) and
`self_token()` (`objcsupport.c`) now call it. Sequential ids cannot collide by
construction, which is the property no hash of a 64-bit pointer into 32 bits
can offer.

Two more defects fell out of the fix:

* `self_token()` used to OR in `0x80000000` while `unfair_token()` did not, so
  the recursive lock's owner check compared against a word `os_unfair_lock_lock`
  had written in a *different* encoding. The two agreed only when bit 39 of the
  TCB pointer happened to be set — which it always was on the hosts we ran, so
  the recursion path appeared to work by luck. They are one function now.
* `dtsd_slots()` created its glibc key under a plain `if (!ready)`, safe only
  because objc4 touches TSD from the single-threaded `_objc_init`. Once a lock
  can be the first thing a brand-new thread touches, that race would hand one
  thread two slot arrays over its life, hence two tokens. It is a three-state
  atomic now.

Rejected: a raw `svc` `gettid`. A kernel tid is unique among *live* threads but
is reused after one exits; a counter is unique over the whole process, and it
keeps `exit_raw` as the project's only raw syscall.

**Measured on a c7g.2xlarge (Neoverse-V1, Ubuntu 24.04, 4 KB pages) — same box,
same build, the fix applied by patch between the two columns:**

| | before | after |
|---|---|---|
| `scripts/objc44.sh` | 24/44 | **41/44** (5 consecutive runs, no variance) |
| `004-dispatch-basic` ×100 | 37 ok / 63 failed | **500/500 ok** |
| `043-threads` ×100 | 44 ok / 56 failed | **100/100 ok** |
| `037-synchronized` ×100 | 61 ok / 39 failed | **100/100 ok** |
| `scripts/difftest.sh` | 19 pass | 19 pass, 0 fail, 1 xfail, 0 drift |
| `scripts/quartz_pixel.sh --linux` | 3/3 byte-identical | 3/3 byte-identical |

41/44 is parity with Apple silicon; the three failures are `038-exceptions`,
`044-exception-through-uncached` (`unwind-compact`) and `042-dlopen`
(`dlopen-dlsym`), all unrelated to this and all loud.

The regression gate is `scripts/stress_unfair_lock.sh`, which
`scripts/objc44.sh` now runs at the end of a full corpus pass: 100 runs of each
of the three threaded fixtures, about 1.5 s, since these fixtures cost ~5 ms
each. It is a loop rather than a test case because the bug's failure rate was a
coin flip — a single green run of `004` proved nothing, which is precisely how
this survived on Apple silicon. Pre-fix the gate reports `37/100 ok` and prints
the "recursive acquisition by the owning thread" line, so it is known to fail on
the bug it guards and not merely known to pass.

**The original evidence is kept below as the record of how this was found, and
of the three approaches that did not work.** Anyone tempted to make the token
cheaper by deriving it from an address again should read it first.

---

`libSystem`'s `os_unfair_lock_lock` intermittently aborts with "recursive
acquisition by the owning thread" on AWS Graviton3 (Neoverse-V1, Ubuntu 24.04,
4 KB pages). NONDETERMINISTIC: the same objc4 fixture exits 0/71 in an
alternating pattern (measured: `0 0 71 0 71 0 71 71` across 8 runs). objc4
locks heavily during class realization, so the whole differential corpus drops
to ~24/44 on Graviton vs 41/44 on Apple Silicon; the single-threaded loader
fixtures are unaffected (19/19 on both).

Root cause (hypothesis, to confirm): the owner token our `os_unfair_lock`
stores/compares is derived from a thread-identity source (TSD / a
mach_thread_self-equivalent) that returns a different or colliding value on
Neoverse than on Apple silicon — so an unowned or other-thread lock reads as
already-owned by the caller. The Apple-silicon test kernel masked it.

Not a Graviton incompatibility and not isa-va-width (that hypothesis was wrong
— the address mask holds, the failure is a lock-owner mismatch). A specific,
fixable bug in our Darwin userland. Fix: make the owner token a correct,
per-thread, non-colliding value and initialise the lock word to the true
"unlocked" sentinel; add a multi-arch CI gate so this cannot regress silently.
The loader/codegen/Mach-O path itself is verified working on real Graviton.


**UPDATE 2026-08-26, measured on Graviton3 with instrumentation:** the failing
`os_unfair_lock_lock` always has `me == expect`, both equal `fold(pthread_self())`
of the *current* thread — the lock word already holds the acquiring thread's own
token. The fixture source is single-threaded, so objc4 spins up a worker thread
and the two threads' 32-bit tokens COLLIDE ~50% of runs (intermittent = ASLR of
the two TCBs). NOT fixed by: (a) gettid — `_glibc_gettid` does not resolve
through the loader's glibc boundary, returns garbage; (b) `__thread` caching —
TLV is not wired for our own userland dylibs, so it collapses to one shared slot
(constant token); (c) xor-folding the full pointer — reduced but did not
eliminate the collision. Correct fix: a token UNIQUE per thread by construction —
a real kernel tid via raw arm64 svc (bypassing the broken glibc boundary), or a
sequential id from an atomic counter stored in the WORKING Darwin TSD
(objcsupport.c `_pthread_getspecific_direct`, which objc4 already uses). The
loader/codegen/Mach-O path and the single-threaded drawing path are unaffected
on Graviton (19/19 fixtures, quartz PNGs byte-identical).

*(The second option is the one that was built, on the same instance type that
produced these numbers. See the top of this entry.)*
