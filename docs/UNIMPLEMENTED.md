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
`darwin/usr/lib/libc++.1.dylib` is **not** libc++. It is the operator
new/delete family, the `__cxa_guard_*` trio, and `std::terminate` — which is
exactly what `05b_cxx_init` leaves undefined once the headers are inlined
(measured: its whole libc++ import list is `__ZdlPv`). Any other libc++ symbol
fails as an undefined symbol naming itself. `__cxa_guard_acquire` is
single-threaded: it does not block a second thread on an in-progress
initialisation.

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

### `objc-sdk-dependency`
`scripts/build_objc4.sh` needs a macOS SDK's `usr/include` (18 MB from
`MacOSX15.sdk`) and refuses to run without one. It is a *compile-time* input
only -- nothing Apple ships is linked or redistributed -- but it does mean
`darwin/usr/lib/libobjc.A.dylib` is reproducible on a machine with Xcode and
not otherwise. The 25 headers the public SDK lacks are vendored in
`vendor/objc4-priv/`; they are Apple-internal SPI declarations plus clang's own
`<ptrauth.h>`, and they change no objc4 source.

### `unwind-compact`
`_Unwind_*` over Apple's `__TEXT,__unwind_info` compact-unwind format. Not
`.eh_frame`, so glibc/libgcc's unwinder cannot be forwarded to. Blocks C++
exceptions (M8).

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
