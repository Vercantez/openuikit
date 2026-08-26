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

### `objc-callbacks`
`_dyld_objc_register_callbacks` / `_dyld_objc_notify_register`. Still the top
blocker, but the shape of the work changed once `~/objc4-linux` was read
(2026-08-26), and PLAN.md's recommended first move -- "build objc4 as a Mach-O
dylib on Linux" -- now looks like the *wrong* one.

What is actually there: objc4-linux did not keep Mach-O image discovery and
shim it. It **replaced** it. `compat/src/objc4linux-elf.cpp` enumerates images
with `dl_iterate_phdr(3)`, reads the on-disk ELF *section header* table to find
`objc_classlist` and friends (the Mach-O names with `__` stripped, so they are
valid C identifiers), and hands objc4 a synthetic per-image record:

```c
struct ElfImage {
    struct mach_header_64         hdr;      /* MUST be first: objc4 casts back */
    _dyld_section_location_info_s sections;
    uintptr_t                     base;
    ...
};
```

Rebuilding that as Mach-O means undoing the port's central change, so it is the
expensive path. The cheap path is that the same file already contains the
*whole* registration seam and it is image-format agnostic:
`objc4linux_scan_images()` builds `_dyld_objc_notify_mapped_info[]` from those
records and calls `gCallbacks.mapped(...)` then `gCallbacks.init(...)`, with
callbacks registered through a v4 `_dyld_objc_register_callbacks`.

So the plausible route is a hybrid, and it needs three pieces, none of which
exists yet:

1. **An ELF-backed Darwin dylib in machorun.** `/usr/lib/libobjc.A.dylib`
   resolves to a marker that names a host `.so`; the loader `dlopen`s it and
   resolves that image's symbols with `dlsym`. This matters more than it
   sounds: `__objc_empty_cache` is a *data* import that every guest class
   structure points at, so a forwarding thunk dylib would give the guest a
   different object than the runtime's own and break cache identity. Binding
   straight to the ELF symbol is the only correct answer.
2. **A foreign-image registration entry point in objc4-linux**, e.g.
   `objc4linux_register_foreign_image(mh, path, sections)`, filling the same
   `_dyld_section_location_info_s` from a *Mach-O* section table instead of an
   ELF one, then driving the existing mapped/init path. That is a change to a
   sibling project, not to this one.
3. **Ordering**: `mapped` must run before the image's own initialisers,
   because `+load` is dispatched from inside `map_images`. machorun's
   `mr_run_initialisers` has the hook point (`mr_objc_note_image`) but nothing
   to call.

Until all three exist, any image carrying `__objc_imageinfo` aborts naming this
entry. It does not fault inside an unregistered class, which is the failure
mode worth having.

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
