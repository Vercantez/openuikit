# UNIMPLEMENTED

Every stub in this project must **abort loudly** with a message naming this file
and its own entry here. Nothing silently no-ops. If you find a stub that returns
quietly, that is a bug, not a shortcut.

Message format:

```
machorun: UNIMPLEMENTED: <short name> (<file>:<line>) — see docs/UNIMPLEMENTED.md#<anchor>
```

This file is seeded from the design study (`docs/PLAN.md`), before any loader
code exists. Entries are predictions of where stubs will be needed; each becomes
real when the corresponding stub is written, and is deleted when it is
implemented. **Do not delete an entry without deleting the stub.**

---

## Loader

### `lc-unixthread`
`LC_UNIXTHREAD` entry points. Measured: the only `LC_UNIXTHREAD` arm64 Mach-O on
a full macOS 26 install is `/usr/lib/dyld` itself, and the modern toolchain will
not emit one for userland code. Blocks: nothing we can build. Cost to fix: ~20
lines (`flavor`, `count`, `arm_thread_state64_t.pc`).

### `lc-main-stacksize`
`LC_MAIN.stacksize != 0` (set by `-Wl,-stack_size`). Requires running `main` on
a separately `mmap`ed stack. Measured 0 in every fixture.

### `fat-binary`
`0xcafebabe` / `0xbebafeca` universal binaries. Needs a slice selector. All
fixtures are thin arm64. Cost to fix: ~40 lines.

### `arm64e`
`cpusubtype & 0xFF == 2`. Pointer authentication, `DYLD_CHAINED_PTR_ARM64E`
(format 1) with signed pointers. **Deliberately out of scope** — Linux/arm64 may
not expose PAC at all and the signing keys are process-scoped. Reject at the
front door.

### `chained-ptr-format`
Chained pointer formats other than 6 (`64_OFFSET`) and 2 (`64`). Every binary
measured used format 6 exclusively. Abort naming the format number.

### `chained-import-format`
`DYLD_CHAINED_IMPORT_ADDEND` (2) and `_ADDEND64` (3). Only format 1 observed.

### `chained-start-multi`
`DYLD_CHAINED_PTR_START_MULTI` (`page_start & 0x8000`). On arm64 a chain cannot
cross a 16 KiB page (max reach `4095 * 4 = 16380`), so this should never appear;
abort if it does, because it means an assumption is wrong.

### `dyld-stub-binder`
The `dyld_stub_binder` GOT slot is bound to a stub that aborts. Lazy binding is
performed eagerly at load time instead (see PLAN.md I.6). If this abort ever
fires, the eager assumption was wrong for that binary.

### `export-trie-reexport`
`EXPORT_SYMBOL_FLAGS_REEXPORT` (0x08) and `EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER`
(0x10) in an export trie. Not needed while our libSystem is a single flat dylib.

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
destructors. Not in the milestone-1 fixtures.

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
