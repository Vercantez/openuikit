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

### `os-unfair-lock`
`os_unfair_lock_lock`/`unlock` abort. The lock is a 4-byte struct compiled into
the guest, so a side table keyed by address is needed; nothing in the corpus
uses it.

### `pthread-attr`
`pthread_create` with a non-NULL `pthread_attr_t` aborts: Darwin's attribute
struct is compiled into the guest and its layout is not glibc's. Same for
`pthread_mutex_init` with attributes. The static initialisers
(`PTHREAD_MUTEX_INITIALIZER`, `PTHREAD_ONCE_INIT`) *are* handled, by keeping a
glibc object inside Darwin's opaque bytes and using the signature word to tell
"Apple-initialised" from "adopted".

### `printf-family-gaps`
Our formatter implements the `%[flags][width][.prec][length]` grammar for
`diuxXospcf/e/g` and delegates only float conversion to glibc (through a
non-variadic prototype). `%n` aborts. The `scanf` family, `syslog`, `err`/
`warn` and `NSLog` are absent entirely — they are variadic, so they can never
be forwarders, and none is in the corpus.

### `mach-ipc`
`mach_msg` and anything requiring real cross-process Mach IPC (XPC, launchd,
distributed notifications). **Deliberately out of scope.** The bounded Mach list
we *do* implement is in PLAN.md II.2 bucket C; this is everything past it.

### `objc-callbacks`
`_dyld_objc_register_callbacks` / `_dyld_objc_notify_register` until the ObjC
rung (M9). The exact struct shape is version-coupled to whichever `libobjc` we
ship and must be read out of that source.

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
