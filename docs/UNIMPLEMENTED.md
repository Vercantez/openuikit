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
the slice. `10_fat` PASSes with output byte-identical to `03_printf`, which is
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
  `std::terminate` (`darwin/src/libcxx.c`) — what `05b_cxx_init` leaves
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

### `libm-ulp` — a MEASURED agreement, not a guarantee
`darwin/src/math.c` forwards 113 math symbols to glibc's libm. Apple's Libm and
glibc's libm are different implementations, and IEEE 754 pins only `+ - * /` and
`sqrt` — it says nothing about `sin`, `cos`, `tan`, `pow`, `exp`, `log` or their
float forms. A guest that computes with any of those may therefore get a
different last bit under machorun than on macOS, and no amount of loader fidelity
changes that.

What is measured: `tests/bin/15_quartz` draws through `QZContextRotateCTM`
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

### `pthread-attr`
`pthread_create` with a non-NULL `pthread_attr_t` aborts: Darwin's attribute
struct is compiled into the guest and its layout is not glibc's. Same for
`pthread_mutex_init` with attributes. The static initialisers
(`PTHREAD_MUTEX_INITIALIZER`, `PTHREAD_ONCE_INIT`) *are* handled, by keeping a
glibc object inside Darwin's opaque bytes and using the signature word to tell
"Apple-initialised" from "adopted".

### `printf-family-gaps`
Our formatter implements the `%[flags][width][.prec][length]` grammar for
`diuxXospcf/e/g/a` and delegates only float conversion to glibc (through a
non-variadic prototype). Covered in anger by `11_varargs`, which is what caught
`%#o` dropping its leading zero. `%n` aborts. The `scanf` family, `syslog`,
`err`/`warn` and `NSLog` are absent entirely — they are variadic, so they can
never be forwarders, and none is in the corpus. Wide characters (`%ls`, `wprintf`)
are absent: `wchar_t` is 4 bytes on both systems, but nothing exercises it.

### `mach-ipc`
`mach_msg`, `mach_port_allocate`, `task_for_pid` and `task_info` abort naming
themselves. Anything requiring real cross-process Mach IPC (XPC, launchd,
distributed notifications) is **deliberately out of scope**.

What *is* implemented, in `darwin/src/mach.c` and covered by `12_mach`:
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

### `dirent`
`opendir`/`readdir`/`closedir` are absent. `struct dirent` differs between the
two systems in both size and field layout, exactly like `struct stat`, so this
is a translation to be written rather than a forward to be added. Nothing in
the corpus enumerates a directory.

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
(`scripts/build_objc4.sh`, 4 patches). `09_objc` passes byte-identically and 41
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

### `dlopen-dlsym`
`dlsym(RTLD_DEFAULT, name)` **is** implemented (`mr_dlsym_default`,
`src/resolve.c`): it is the flat search the binder already does, with Darwin's
leading underscore added for you. It deliberately does not fall back to the
host, so a guest asking for a symbol we lack gets NULL rather than a same-named
glibc symbol.

Everything else aborts naming itself: `dlopen`, `dlclose`, `dladdr`, and
`dlsym` with `RTLD_NEXT` / `RTLD_SELF` / `RTLD_MAIN_ONLY` or a real handle.
`RTLD_NEXT` and friends need a notion of "the calling image", i.e. walking back
to the caller's return address. `dladdr` would have to describe *guest* images;
forwarding it to glibc would describe the loader's own ELF world, which is a
different program.

`dlopen` is the larger piece and `mr_image_load` was written re-entrant for it.
Beyond loading, it must also deliver a `mapped` notification for the new image
before running its initialisers — `src/objc_notify.c` has the machinery but
only ever delivers the startup batch. Measured cost of not having it:
`tests/objc44/042-dlopen` and (until `dlsym` landed) `025-internal-symbols`.
That test is one of the two reasons the retired `~/objc4-linux` is still on
disk — see `unwind-compact` below for the other.

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

### `swift-interop`
`swift_retain` / `swift_release` are defined in `darwin/src/objcsupport.c` as
loud aborts. objc4 refers to them so a Swift-stable class can be retained
without a message send; on Darwin the reference is delay-init and resolves only
if `libswiftCore` is loaded, but `ld64.lld-18` does not implement `-delay_init`,
so the reference is a plain undefined and something has to define it. They are
reachable only for an object whose class `isSwiftStable()`, which cannot exist
without a Swift stdlib. `docs/OBJC4_MACHO.md` §8 lists what a Swift binary would
need.

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
`docs/OBJC4_MACHO.md` §9.3. Nothing aborts, which is the problem.*

objc4 packs the class pointer into the isa word and the `class_rw_t` pointer
into `class_t::bits`, and Darwin sizes both fields from a *known* Mach VM
ceiling. Linux/aarch64's user VA width is a **kernel configuration**
(39/42/48/52-bit) and is not fixed across machines. `patches-macho/0001` widens
both fields against a measured 48-bit host:

| field | our value | pointer bits | headroom |
|---|---|---|---|
| `ISA_MASK` | `0x007ffffffffffff8` | 3..54 | 7 bits |
| `FAST_DATA_MASK` | `0x0f00fffffffffff8` | 3..47 | **none** |

Measured on the test kernel (`6.12.76-linuxkit`, arm64): default `mmap`
returns `0xffff88f9e000`, `malloc` `0xaaaabf7f82a0`, and an `mmap` hint of
`0x10000000000000` (2^52) is **ignored**, returning `0xffff88f9d000`. So on
this kernel no user address exceeds 48 bits and `FAST_DATA_MASK` holds exactly.

What is not guaranteed: on a kernel built for 52-bit VAs, Linux hands out
addresses above 2^48 only when an `mmap` hint asks for one -- but if a guest
ever gets a `class_rw_t` up there, `FAST_DATA_MASK` truncates it and every
object pointing at that class is corrupt, silently.

objc4's own `STATIC_ASSERT` does **not** cover this. It checks `ISA_MASK`
against the SDK's `MACH_VM_MAX_ADDRESS` -- a compile-time fact about Darwin --
and it is what forced `patches-macho/0001` to exist at all. There is no
equivalent check against the *host kernel's* ceiling, and there cannot be one
at compile time.

The fix, when it is needed, is a startup assertion in `src/objc_notify.c` that
every image and heap address fits `FAST_DATA_MASK`, aborting loudly rather than
corrupting. The ELF port's alternative -- force `SUPPORT_NONPOINTER_ISA 0` --
is deliberately **not** taken: it costs performance and changes
`objc_debug_isa_class_mask`, which Swift reads.

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

### `unwind-compact`
`_Unwind_*` over Apple's `__TEXT,__unwind_info` compact-unwind format. Not
`.eh_frame`, so glibc/libgcc's unwinder cannot be forwarded to. Blocks C++
exceptions (M8).

Measured cost: `tests/objc44/038-exceptions` and
`tests/objc44/044-exception-through-uncached`. With `dlopen-dlsym` these are
the only 3 of the 44 that machorun does not pass, and therefore the two gates
on *deleting* the retired `~/objc4-linux` rather than merely leaving it
retired -- it is the only tree that runs the whole corpus.

---

## Fixture corpus and harness

Owned by `tests/`, `harness/`, `scripts/difftest.sh`. See `docs/FIXTURES.md`
for the full ladder. These are not stubs — they are gaps in *test coverage*,
which is the same kind of dishonesty if left unstated.

### `fixture-raw-syscall` — permanent wall
*`01_exit_raw`, graded `XFAIL` forever.*

A binary executing `svc #0x80` with a BSD syscall number in `x16` cannot be
supported by the replace-libSystem bet. On Linux/arm64 `svc` traps to the
Linux kernel, which reads the number from `x8` under Linux numbering. Fixing
it means seccomp trapping or static rewriting — the Darwin-syscall-emulation
road this project chose not to take. The fixture stays in the corpus so the
boundary appears in every test run instead of being forgotten.

### `fixture-unixthread-no-oracle`
*`01b_exit_unixthread`, graded `NO-ORACLE`.*

Correction to the `lc-unixthread` entry above: the modern toolchain **will**
emit `LC_UNIXTHREAD` for userland code — `clang -target arm64-apple-macos11
-nostdlib -e _start -static` does it, and the fixture is committed at
`tests/bin/01b_exit_unixthread` with its full `otool -l` in
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
does: stdin; `argv` beyond `argv[0]`; environment variables; signals;
`fork`/`exec`; file and socket I/O; `dlopen`/`dlsym`; C++ exceptions;
`LC_MAIN.stacksize != 0`; `LC_REEXPORT_DYLIB`; weak and weak-defined symbols;
two-level-namespace *misses*; `__DATA,__objc_catlist` (ld64 merges same-image
categories into the class, so the corpus never produces one).

Each is a rung that does not exist yet. Adding one means adding a fixture,
recording it on macOS, and listing it in `tests/manifest.tsv` — not asserting
it works.

### `fixture-nonreproducible`
Rebuilding a fixture from identical sources yields different bytes (fresh
`LC_UUID`, fresh ad-hoc code signature). The committed binaries in `tests/bin/`
are the reference; `tests/build_fixtures.sh` exists for auditability, not as
part of the test loop. If you rebuild, commit the new binaries and the
re-recorded baselines together, in one commit, and say why.

### `fixture-concurrency`
`08_pthread` is the only concurrency test and is deliberately deterministic
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
`tests/bin/15_quartz` exercises nine drawing stages and calls **34 of
libquartz's 507 exported symbols** directly (`nm -u tests/bin/15_quartz | grep
_QZ`). What those 34 reach internally is more than 34, but it is not measured
and should not be guessed at. Untested and therefore unverified no matter how
green the PNG diff is: the whole Core Animation layer
tree (`QZLayer*`, `QZAnimation*`, the replicator and transform layers), text and
font loading (`stb_truetype`), image decode (`stb_image`), PDF output, patterns,
shadings, CMYK and Display P3 colour, blend modes other than normal, and
transparency layers.

Those are not stubs — they are compiled and exported and presumably work, since
upstream scores 97.46/100 against Apple's frameworks with all of them. They are
simply not covered *here*, which is a different claim. Adding coverage means
adding drawing stages to `tests/src/15_quartz.c`, rebuilding the fixture on
macOS, and re-recording with `scripts/quartz_pixel.sh --record` — not asserting
that a passing PNG generalises.
