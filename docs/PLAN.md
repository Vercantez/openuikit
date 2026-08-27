# PLAN — machorun

Design study, 2026-08-25. Companion to `docs/MACHO_NOTES.md`, which contains the
measurements this design rests on. **No loader code exists yet**; this document
is what the next phase builds against.

Every claim here that is a number came from measuring a real binary on the macOS
oracle or a real container on Linux. Where I am guessing, I say so.

---

## Part I — Loader design

### I.0 Shape of the thing

`machorun` is a **Linux/aarch64 ELF PIE executable** that maps a Mach-O image
into its own address space and jumps into it.

```
$ machorun ./hello arg1 arg2
```

Not a `binfmt_misc` handler, not a `ptrace` supervisor, not a separate address
space. One process, two object formats coexisting: our ELF (glibc, the loader)
and the guest Mach-O images. They share one heap, one thread pool, one FILE*
table — because our `libSystem.B.dylib` forwards into the same glibc that
`machorun` itself is linked against.

That sharing is the whole bet, and it is what makes this tractable where syscall
emulation is not.

**Why PIE matters (measured):** a non-PIE aarch64 ELF links at `0x400000`, which
is inside the guest's `__PAGEZERO` (`[0, 4 GiB)`). Linux places PIE executables
well above 4 GiB. Assert at startup that `&main > 0x100000000` and fail loudly
otherwise.

### I.1 Module decomposition

```
src/
  macho.c        parse: header, load commands, segments, sections. Pure, no mmap.
  image.c        struct image: base, slide, segments, deps, init state, exports
  map.c          segment mapping, PAGEZERO reservation, mprotect, page-size policy
  fixups_chained.c   LC_DYLD_CHAINED_FIXUPS walker
  fixups_classic.c   LC_DYLD_INFO_ONLY opcode interpreters (rebase/bind/lazy/export)
  trie.c         export trie: build + lookup (shared by both fixup paths)
  resolve.c      path expansion (@rpath/@loader_path/@executable_path + prefix map),
                 dylib dedup by install-name, two-level symbol lookup
  tlv.c          __thread_vars registration (the loader half; runtime half is libSystem)
  init.c         initialiser ordering (depth-first, deps first), objc notify hooks
  entry.c        apple[], libSystem bootstrap call, LC_MAIN invocation, exit
  main.c         argv handling, MACHORUN_* env, diagnostics
```

`image_load(path, flags) -> image*` must be **re-entrant from day one**, because
`dlopen` is a libSystem function that calls back into it (measured: `dl.c`
imports `_dlopen` from libSystem).

### I.2 Load sequence

```
 1. parse the main executable (thin arm64 only; reject fat, reject arm64e)
 2. check kernel page size vs segment alignment          -> §I.4
 3. reserve __PAGEZERO                                   -> §I.3
 4. choose load base; map segments                       -> §I.3
 5. recursively resolve + load LC_LOAD_DYLIB graph       -> §I.5
      (breadth of graph first: everything mapped before anything is bound)
 6. apply fixups to every image, leaves first            -> §I.6
 7. mprotect SG_READ_ONLY segments to r--
 8. register TLV templates, patch __thread_vars          -> §I.8
 9. __machorun_libsystem_bootstrap(argc, argv, envp, apple)
10. objc callbacks: run libobjc's initialiser, then feed it every image  -> §I.9
11. run initialisers, dependencies first, main executable last  -> §I.9
12. build apple[]; call LC_MAIN entry as main(argc,argv,envp,apple)  -> §I.10
13. exit(rc)
```

Step 5 completing before step 6 is not optional: a bind in image A can name a
symbol in image B, and B's exports trie must be readable.

### I.3 Mapping segments

For each `LC_SEGMENT_64` other than `__PAGEZERO`:

```c
// vmaddr/fileoff measured to always be multiples of 0x4000 (see MACHO_NOTES §1)
void *addr = (void*)(load_base + seg->vmaddr - preferred_base);

if (seg->filesize > 0)
    mmap(addr, seg->filesize, prot_from(initprot),
         MAP_PRIVATE|MAP_FIXED, fd, seg->fileoff);

if (seg->vmsize > round_up(seg->filesize, pagesize))
    mmap(addr + round_up(seg->filesize, pagesize),
         seg->vmsize - round_up(seg->filesize, pagesize),
         prot, MAP_PRIVATE|MAP_ANONYMOUS|MAP_FIXED, -1, 0);
```

Three measured cases the code must not get wrong:

- `filesize == 0 && vmsize > 0` (`libgreet.dylib`'s `__DATA`, `fileoff` is also
  `0`): **anonymous only**. Mapping the file at offset 0 here would silently map
  the mach header into `__DATA`.
- `vmsize > filesize` (`big`'s `__DATA`: `0x3c000` vs `0x8000`): file part then
  anonymous zero tail. The bytes between `filesize` and the next page boundary
  are zeroed by `mmap` already; do not double-map them.
- `__DATA_CONST` has `initprot = rw` but segment `flags & SG_READ_ONLY (0x10)`.
  Map it `rw`, apply fixups, then `mprotect` to `r--` in step 7.

Whole-image reservation first: `mmap(NULL, total_vmsize, PROT_NONE, MAP_PRIVATE|
MAP_ANONYMOUS|MAP_NORESERVE)` to claim a contiguous range, then `MAP_FIXED` each
segment over it. This makes the "did the preferred base collide" question a
single check and guarantees inter-segment gaps stay unmapped.

**Base selection.** Executables prefer `0x100000000` (measured). Try
`MAP_FIXED_NOREPLACE` there; on success **slide is 0** and everything is
trivially correct. On failure take whatever the kernel gives and record
`slide = actual - preferred`. Dylibs have `preferred = 0`, so they always slide.

Write every fixup as `load_base + x`, never `preferred_base + x`. Chained
`_OFFSET` targets, `__init_offsets` entries and export-trie addresses are all
already image-base-relative, so this costs nothing and makes ASLR free later.

**`__PAGEZERO`.** Measured `vm.mmap_min_addr = 32768` on the target container,
so we cannot start at 0. Reserve `[65536, 0x100000000)` `PROT_NONE`,
`MAP_ANONYMOUS|MAP_NORESERVE|MAP_FIXED_NOREPLACE`. 4 GiB of VA, zero RSS.
The kernel's own low-address ban covers the rest. If the reservation fails,
warn but continue — its only job is to make null derefs fault, and glibc will
not hand out sub-4-GiB addresses anyway on a PIE process.

### I.4 Page size — the explicit policy

Measured facts (MACHO_NOTES §9):

- Every segment Apple's arm64 toolchain emits is 16 KiB-aligned in both `vmaddr`
  and `fileoff`.
- A 4 KiB-aligned build **is** producible (`-Wl,-segalign,0x1000`) but macOS
  itself `SIGKILL`s it, so it can never be an oracle-validated fixture.
- Target Linux container: `getconf PAGESIZE` = **4096**.

Policy:

| kernel page size | behaviour |
|---|---|
| 4096 | native path. 16 KiB is a multiple of 4 KiB, so `mmap`/`mprotect` are exact. Free. |
| 16384 | native path, also exact. |
| 65536 | **detect and refuse in milestone 1**, with a message naming the page size and pointing at this section. `__TEXT` (`r-x`) and `__DATA_CONST` (`rw-`) are 16 KiB apart and therefore share one 64 KiB page — they cannot be given distinct protections. Later fallback: one anonymous RW image, `pread` segment bytes in, `mprotect` each 64 KiB page with the *union* of its segments' protections (effectively `rwx` across the `__TEXT`/`__DATA_CONST` boundary). Correct, loses W^X and page-cache sharing. ~60 lines. |

Separately and importantly: the chained-fixups `page_size` field
(measured `0x4000`) is a property of the **fixup tables**, not of the kernel.
The chain walk iterates in `starts->page_size` steps no matter what
`sysconf(_SC_PAGESIZE)` says. Conflating the two is the single easiest bug to
write in this project; the two values get different type names in the code
(`macho_page_size_t` vs `host_page_size_t`) so the compiler catches it.

### I.5 Resolving and loading dependencies

Path expansion, in order, per MACHO_NOTES §8:

```
@executable_path/ -> dirname(main executable)
@loader_path/     -> dirname(the image holding this LC_LOAD_DYLIB; for a
                     dlopen, the image that CALLED it)
@rpath/           -> each LC_RPATH of the loading image, then of the main
                     executable, in order; each may itself be @-prefixed
absolute          -> prefix map into our tree
```

The prefix map is the project's core mechanism:

```
/usr/lib/libSystem.B.dylib                    -> $MACHORUN_ROOT/darwin/usr/lib/libSystem.B.dylib
/usr/lib/libobjc.A.dylib                      -> $MACHORUN_ROOT/darwin/usr/lib/libobjc.A.dylib
/usr/lib/libc++.1.dylib                       -> $MACHORUN_ROOT/darwin/usr/lib/libc++.1.dylib
/System/Library/Frameworks/Foundation.framework/Versions/C/Foundation
                                              -> $MACHORUN_ROOT/darwin/System/.../Foundation
```

i.e. a literal mirrored tree rooted at `$MACHORUN_ROOT/darwin`, so the map is
"strip nothing, prepend the root". `MACHORUN_ROOT` defaults to the directory
containing the `machorun` binary. An unmapped absolute Darwin path is a **hard
error naming the path** — never a silent skip. This is the file that grows as we
add frameworks, and its length is an honest progress metric.

There is no fallback-to-the-real-thing temptation to resist: measured,
`/usr/lib/libSystem.B.dylib` does not exist as a file even **on macOS** (it lives
only in the dyld shared cache).

Dedup by resolved `LC_ID_DYLIB` install name, not by path — the same dylib
reached via `@rpath` and via an absolute path is one image.

`LC_LOAD_WEAK_DYLIB` (measured present in a plain `-lgreet` link): a missing one
is not an error; its binds resolve to `NULL`.

### I.6 Applying fixups

Two interpreters over one shared "write a pointer at address `p`" primitive.

**Chained** (`LC_DYLD_CHAINED_FIXUPS`, the default at deployment target ≥ macOS 12):
walk `starts_in_image -> starts_in_segment -> page_start[] -> chain`, exactly as
in MACHO_NOTES §4. Implement `DYLD_CHAINED_PTR_64_OFFSET` (format 6, the only
one observed) and `DYLD_CHAINED_PTR_64` (format 2, three extra lines — target is
an unslid vmaddr rather than an image offset). Every other format `abort()`s
with the format number. Import formats 2/3 (`_ADDEND`, `_ADDEND64`) likewise.

**Classic** (`LC_DYLD_INFO_ONLY`, deployment target ≤ macOS 11 or
`-Wl,-no_fixup_chains`): the three opcode interpreters. Decoded byte-for-byte in
MACHO_NOTES §6, which doubles as the unit-test vector.

**Lazy binding is not implemented.** Instead, the lazy stream is interpreted
eagerly at load time — it names exactly the same set of `(address, symbol)` pairs
that lazy resolution would eventually produce. The `dyld_stub_binder` GOT slot
is still bound (the classic bind stream demands it) but to a function in our
libSystem that prints "machorun: dyld_stub_binder entered — this is a loader
bug" and aborts. If we ever see that message, the eager assumption was wrong and
we will know precisely when.

For chained binaries the question does not arise at all: measured, a
chained-fixups binary has no `__stub_helper`, no `__la_symbol_ptr`, and never
references `dyld_stub_binder` — its `__stubs` load straight from `__got`.

**Symbol resolution** (`resolve.c`), two-level namespace (`MH_TWOLEVEL` set on
everything measured):

```
lib_ordinal 1..n  -> the n-th LC_LOAD_DYLIB-family command of THIS image;
                     look up in that image's export trie, then its LC_REEXPORT_DYLIBs
lib_ordinal 0     -> this image
lib_ordinal 0xFF  -> flat: search all loaded images in load order
lib_ordinal 0xFE  -> weak: as flat, but NULL if absent
weak_import bit   -> NULL if absent, no error
```

Not-found with none of the escape hatches = **hard error naming the symbol and
the dylib it was expected in**. This is the error message that will do most of
the work during bring-up, so make it good: symbol, expecting image, searched
image, and the nearest few names in that image's trie.

### I.7 Exports

Export tries (`LC_DYLD_EXPORTS_TRIE`, or `export_off` in `LC_DYLD_INFO_ONLY`)
are parsed once per image into a flat hash table on load. Our dylibs are small
enough that eager slurping beats prefix-walking, and it makes `dlsym` and the
diagnostics above trivial. Format and a decoded example in MACHO_NOTES §6.

Re-export entries (`EXPORT_SYMBOL_FLAGS_REEXPORT`, flag `0x08`) carry a dylib
ordinal plus an optional renamed symbol and must chain to another image.
Milestone 1 can `abort()` on them if our libSystem is a single flat dylib —
which is the recommended shape (§II.1) precisely to defer this.

### I.8 TLS / TLV

Split between loader and libSystem, per MACHO_NOTES §7.

Loader half, after fixups, for each image with `MH_HAS_TLV_DESCRIPTORS`:

1. Compute the per-thread template: bytes of `__thread_data` from the file,
   followed by `__thread_bss`-many zero bytes. (Measured: `__thread_data` at
   `0x8030` size 4, `__thread_bss` at `0x8038` size 8, and descriptor offsets
   `0` and `8` index into their concatenation.)
2. `pthread_key_create(&key, machorun_tlv_free)` — one key per image.
3. Walk `__thread_vars` in 24-byte strides; for each descriptor write
   `desc->thunk = machorun_tlv_get_addr` and `desc->key = key`. Leave
   `desc->offset` as the file had it.

libSystem half, `machorun_tlv_get_addr(desc)`: `pthread_getspecific(desc->key)`,
allocate-and-copy-template on first touch, return `block + desc->offset`.

ABI, measured from the call site: **`x0` in = descriptor address, `x0` out = the
address of the variable for the calling thread, all other registers preserved.**
That register-preservation contract is why real implementations write the entry
in assembly with a fast path; write ours as a small `.S` with a C slow path from
the start rather than discovering the clobber the hard way.

Patching the descriptors directly means the `__tlv_bootstrap` import can be
satisfied by any placeholder — we overwrite the slot. That is deliberately
simpler than dyld's self-installing-on-first-call scheme, and it is enough until
`dlopen` of a TLS-using dylib forces the lazier form.

`__cxa_thread_atexit` / `_tlv_atexit` (C++ `thread_local` with non-trivial
destructors) is **not** in scope for milestone 1: record in
`docs/UNIMPLEMENTED.md`, abort loudly.

### I.9 Initialisers and ObjC registration

Order (measured with `usegreet` linking a dylib that has a constructor:
`libgreet init` precedes all `main` output):

```
for each image, depth-first over LC_LOAD_DYLIB, dependencies before dependents:
    if already initialised or currently initialising: skip   (breaks cycles)
    mark initialising
    recurse into dependencies
    run this image's initialisers
    mark initialised
finally: the main executable's initialisers
```

Per image, initialisers come from whichever of these exists:

- `__TEXT,__init_offsets` (`S_INIT_FUNC_OFFSETS`, flags `0x16`) — **modern**.
  An array of `uint32` **offsets from the mach header**, not pointers, in
  read-only `__TEXT`, needing no rebase. Measured in `ctors_m14`:
  `[0x548, 0x564, 0x5f4]` = `_c1`, `_c2`, `___GLOBAL_init_65535`. The linker has
  already sorted by `constructor(priority)`; **walk the array in order, do not
  re-sort.**
- `__DATA_CONST,__mod_init_func` (`S_MOD_INIT_FUNC_POINTERS`, flags `0x9`) —
  **classic**, 8-byte pointers, each with a rebase fixup.

Initialisers are called with `(argc, argv, envp, apple)` on Darwin (the same
four arguments as `main`); C constructors ignore them but some libraries do not.
Pass them.

**ObjC image registration** (MACHO_NOTES §13). Before running normal
initialisers, our libSystem must expose `_dyld_objc_register_callbacks` /
`_dyld_objc_notify_register`; `libobjc`'s own initialiser calls it, and our
loader then invokes the `mapped(count, paths[], mach_headers[])` callback for
every already-loaded image and for every image loaded later. `+load` methods are
dispatched from inside `map_images`, so `mapped` must precede the image's own C
initialisers.

The exact callback struct is version-coupled to whichever `libobjc` we ship.
`~/objc4-linux` currently produces `build/linux-aarch64/libobjc.so` — an **ELF**.
A Mach-O build of it is a hard prerequisite for the ObjC rung, and the callback
ABI must be *read out of that source*, not assumed from a dyld version.

### I.10 Entry

Measured (MACHO_NOTES §3): `LC_MAIN.entryoff` points **directly at `main`** —
modern Mach-O executables have no `crt1.o` `start` stub, and `main` receives its
four arguments in `x0..x3` per plain AAPCS64.

```c
apple[0] = "executable_path=<argv[0] exactly as given>";
apple[1] = NULL;

__machorun_libsystem_bootstrap(argc, argv, envp, apple);   // sets environ,
                                                           // _NSGetArgv, __progname
run_all_initialisers();

int rc = ((int(*)(int,char**,char**,char**))(load_base + entryoff))
             (argc, argv, envp, apple);
exit(rc);
```

`argv`/`envp` pass straight through from the Linux process. `apple[]` grows only
when a fixture demands an entry; measured, macOS supplies 10–12 entries and the
count **changes with signing state**, so fixtures must not assert on anything
past `apple[0]`.

`LC_MAIN.stacksize` is 0 in every binary measured; when nonzero the main thread
stack must be that size, which for us means running `main` on a separately
`mmap`ed stack. Defer; abort loudly if nonzero.

`LC_UNIXTHREAD`: abort loudly. It is dyld-only on arm64 (measured: the sole
`LC_UNIXTHREAD` arm64 Mach-O on a full macOS 26 install is `/usr/lib/dyld`
itself), and the modern toolchain cannot readily emit one.

---

## Part II — The libSystem replacement

### II.1 Shape

**One flat `darwin/usr/lib/libSystem.B.dylib`**, built on Linux with
`clang -target arm64-apple-macos11 -c` + `ld64.lld-18 -dylib`, exporting
everything, `LC_ID_DYLIB` = `/usr/lib/libSystem.B.dylib`.

Real libSystem re-exports ~40 `/usr/lib/system/*.dylib` (measured from
`MacOSX.sdk/usr/lib/libSystem.tbd`: `libsystem_c`, `libsystem_kernel`,
`libsystem_pthread`, `libsystem_malloc`, `libsystem_m`, `libdispatch`,
`libdyld`, ...). Flattening them into one dylib means milestone 1 never has to
implement `LC_REEXPORT_DYLIB` chasing. Nothing in a client binary can tell the
difference — measured, clients only ever name `/usr/lib/libSystem.B.dylib` in
their `LC_LOAD_DYLIB`.

Build the dylib at the **macOS 11 deployment target** so *our* dylibs use the
classic `LC_DYLD_INFO_ONLY` form if that turns out easier for `ld64.lld` to emit
correctly — but verify both, since we control it and the guest does not care.

### II.2 The three buckets

Derived from `nm -u` across the fixtures I built (MACHO_NOTES §12).

**Bucket A — pure forwarders to glibc.** A one-line macro each. The only work is
stripping exactly one leading underscore from the Mach-O name. **Variadic
functions are excluded from this bucket** — see §II.5; `printf` is *not* here
despite appearances.

```
_puts _putchar _fputs _fwrite _fflush _fopen _fclose
_malloc _calloc _realloc _free _strlen _strcpy _strcmp _strncmp _memcpy _memset
_memmove _abort _exit _atoi _strtol _qsort _getpid _time _clock_gettime
_close _read _write _lseek _stat _fstat _unlink _mkdir _getcwd
_pthread_create _pthread_join _pthread_mutex_* _pthread_cond_* _pthread_key_*
_pthread_self _pthread_getspecific _pthread_setspecific
_sqrt _pow _sin _cos _fabs ... (libm)
```

(`_open` is *variadic* on both platforms and belongs in §II.5, not here.
`_dlopen/_dlsym/_dlclose/_dlerror` look like bucket A but are bucket B — they
must drive *our* loader over Mach-O images, not glibc's over ELF.)

Data forwarders matter too and are easy to forget: `___stderrp`, `___stdoutp`,
`___stdinp` are `FILE**` in Darwin (`stderr` is `(*__stderrp)`), so they must be
exported as **pointer variables** initialised to glibc's `stderr`/`stdout`/`stdin`.
`___stack_chk_guard` likewise. Fixture `printf` imports `___stdoutp` and
`malloc` imports `___stack_chk_guard`, so both land at rungs (c) and (d) —
early.

**Bucket B — needs real implementation.** Darwin-specific semantics or a
different ABI.

| symbol | why |
|---|---|
| `___cxa_atexit`, `_atexit`, `___cxa_finalize` | ordering must interleave correctly with our loader's teardown; measured to be what makes `__attribute__((destructor))` fire |
| `__tlv_bootstrap`, `machorun_tlv_get_addr`, `_tlv_atexit` | §I.8; special register-preserving ABI |
| `_dlopen/_dlsym/_dlclose/_dlerror` | must drive **our** loader over Mach-O images, not glibc's over ELF. Darwin `dlsym` takes the **unprefixed** name (`dlsym(h,"greet")` for symbol `_greet`) — measured working on macOS — so the underscore is added on the way in |
| `_dyld_objc_register_callbacks`, `_dyld_objc_notify_register` | §I.9 |
| `__dyld_get_image_header`, `__dyld_image_count`, `__dyld_get_image_name`, `__dyld_get_image_vmaddr_slide` | image introspection over our image list; used by objc and CF |
| `__NSGetExecutablePath`, `__NSGetArgc`, `__NSGetArgv`, `__NSGetEnviron`, `_environ`, `___progname` | fed by `__machorun_libsystem_bootstrap` |
| `_getsectbyname`, `_getsectiondata`, `_getsegmentdata` (libmacho) | section lookup by name; objc and CF both use these |
| `___strcpy_chk`, `___memcpy_chk`, `___sprintf_chk`, `___stack_chk_fail` | fortify/stack-protector lowering; measured in a trivial `strcpy` fixture, so they appear early |
| `_os_unfair_lock_lock/unlock` | trivially a futex/pthread mutex, but ubiquitous in Apple code |
| `___error` | Darwin's `errno` is `(*__error())`; must return `&errno` |

**Bucket C — Mach APIs.** The bounded list the README promises. Measured: **none
of the C, C++, or Foundation-lite fixtures import a single `mach_*` symbol.**
They only start appearing once real Apple framework binaries are in play. The
expected first arrivals, and the Linux primitive underneath:

| Mach API | Linux implementation |
|---|---|
| `_mach_task_self` / `mach_task_self_` | return a fixed fake port constant |
| `_mach_thread_self` | per-thread fake port from a counter |
| `_vm_allocate` / `_vm_deallocate` | `mmap`/`munmap` |
| `_vm_protect` | `mprotect` |
| `_vm_copy`, `_vm_read`, `_vm_write` | `memcpy` (same address space) |
| `_mach_absolute_time` | `clock_gettime(CLOCK_MONOTONIC)` |
| `_mach_timebase_info` | return `{1,1}` (nanoseconds) |
| `_host_page_size` | `sysconf(_SC_PAGESIZE)` — **not** 16384 |
| `_semaphore_create/_signal/_wait` | POSIX semaphores |
| `_mach_port_allocate/_deallocate/_insert_right` | a table of fake ports |
| `_task_info`, `_host_statistics` | `/proc` or plausible constants |

The honest note: `mach_msg` and real IPC are **not** on this list and are not
milestone-1 work. Anything that genuinely needs cross-process Mach messaging
(XPC, launchd, distributed notifications) is out of scope, and a stub that
aborts loudly is the correct behaviour.

### II.3 The underscore rule

Mach-O carries a leading `_` that ELF does not. `_printf` -> `printf`.
**Strip exactly one.** The traps, all measured in real fixtures:

```
_printf            -> printf
__tlv_bootstrap    -> _tlv_bootstrap      (two underscores in, one out)
___cxa_atexit      -> __cxa_atexit
___stderrp         -> __stderrp           (a Darwin name, not a glibc one — bucket B)
__ZNSt3__1...      -> _ZNSt3__1...        (C++ mangled, and note Darwin libc++ is
                                           namespace std::__1 — same as libc++ on
                                           Linux, but NOT the same as libstdc++)
```

Getting this wrong once silently misses half the symbol table, so the forwarding
layer is generated from an explicit table, never from string munging at runtime.

### II.4 Variadic functions are never forwarders

Measured on both sides (MACHO_NOTES §16), and this is the finding that most
changes the shape of libSystem:

| | Darwin arm64 | Linux aarch64 |
|---|---|---|
| variadic args | **all on the stack**, 8-byte slots, doubles as raw bits | `x1..x7` + `v0..v7`, overflow on the stack |
| `sizeof(va_list)` | **8** (a `char*`) | **32** (a 5-field cursor struct) |

`va_start(ap, fmt); vprintf(fmt, ap);` inside our Darwin-compiled libSystem
hands glibc an 8-byte pointer where it expects a 32-byte struct. It does not
fail cleanly — it prints garbage or faults.

Our libSystem is compiled `-target arm64-apple-macos11`, so it *receives* the
Darwin convention correctly. The break is only at the hand-off into glibc.

**Strategy per shape:**

- **printf family** (`printf`, `fprintf`, `sprintf`, `snprintf`, `asprintf`,
  and their `v*` forms): implement the formatter ourselves over the Darwin
  `va_list`, using glibc only for output (`fwrite`/`write`). ~400 lines of
  well-understood code, and it removes the mismatch rather than hiding it.
  This lands at **rung (c)**, the third fixture — so it is early work, not
  deferred work.
- **Fixed-shape variadics** (`open(path, flags, mode)`, `fcntl`, `ioctl`,
  `execl*`): a Darwin-compiled shim reads the one or two slots with `va_arg`
  and calls glibc with ordinary register arguments. Cheap, but per function.
- **scanf family, `syslog`, `err`/`warn`, `NSLog`**: same problem, deferred
  until a fixture needs them; abort loudly until then.

The symbol table that generates our forwarders therefore carries a **strategy
column** (`FORWARD` / `VARIADIC_OWN` / `VARIADIC_SHIM` / `IMPL`), and
`FORWARD` on a variadic signature is a build-time error. That check is worth
more than the code it guards.

### II.5 Building our dylibs on Linux

Already verified (README, 2026-08-25): `clang -target arm64-apple-macos11 -c`
emits Mach-O objects and stock Ubuntu `ld64.lld-18` links dylibs that macOS's own
`otool`/`file`/`nm` accept. Use `apt-get install lld-18` — Swift's *bundled* lld
is patched to refuse macOS linking.

The differential lever available to us here is unusually good: **our
Linux-built `libSystem.B.dylib` can be validated on the macOS oracle** by
checking that `otool -l`, `nm -m` and `dyld_info -exports` produce the structure
we expect. That catches ld64.lld divergences long before they become mysterious
loader crashes.

---

## Part III — Known hard parts, ranked by risk

Ranked by `P(blocks the project) x cost-if-hit`. "Blocker" means the approach is
wrong; "nuisance" means it costs days.

### 1. ObjC/Swift runtime image registration — **highest risk**

- **Why it is hard:** the loader/runtime interface (`_dyld_objc_register_callbacks`
  and friends) is a private, version-coupled ABI. `map_images` must run before
  `+load`, `__objc_selrefs` uniquing must happen before any `objc_msgSend`, and
  the whole thing has to agree with whichever objc4 we ship. Swift adds its own
  metadata sections and a second registration protocol on top.
- **Blocker if:** objc4 cannot be built as Mach-O on Linux at all (it currently
  builds as `libobjc.so`, ELF — confirmed), or its Linux port has diverged from
  the dyld interface in ways that cannot be reconciled.
- **Nuisance if:** it is "just" a matter of rebuilding objc4 with
  `-target arm64-apple-macos11` and wiring three callbacks. Given that
  `~/objc4-linux` already passes 44/44 differential tests against Apple's
  shipping runtime, the runtime *semantics* are known-good; only the packaging
  and the loader handshake are new. That is the optimistic and, I think, likely
  case — but it is the one item where I would not be surprised by a week.
- **De-risk cheaply:** before writing loader code, try building `libobjc` as a
  Mach-O dylib on Linux and `otool -l` it on the Mac. One afternoon, and it
  converts the largest unknown into a known.

### 2. The variadic ABI mismatch — **certain to bite, at the third fixture**

- **Not a probability, a certainty**: measured (MACHO_NOTES §16, PLAN II.4).
  Darwin arm64 passes variadic arguments on the stack with an 8-byte `va_list`;
  Linux aarch64 passes them in registers with a 32-byte `va_list`. `printf`
  cannot forward to glibc's `printf`.
- **Blocker if:** nothing. There is a correct answer (own the formatter) and it
  is bounded.
- **Nuisance if:** we discover it by debugging garbage output at rung (c)
  instead of designing for it. That is the failure mode this entry exists to
  prevent — the symptom (wrong characters in `printf` output) looks like a
  loader bug and would send someone hunting through fixup code for a day.
- Ranked second not because it is deep but because it is **early and
  certain**, and because the naive design ("libSystem is a table of
  one-line forwarders") is wrong in a way that is not obvious from reading
  `nm -u`.

### 3. Page size — **low technical risk, must be explicit**

- Measured: our target container is 4 KiB, Apple's segments are 16 KiB, 16 is a
  multiple of 4, so the common case is **free**. macOS itself refuses to run a
  4 KiB-aligned binary, so the dangerous direction cannot be produced by a
  fixture the oracle accepts.
- **Blocker if:** we must deploy on a 64 KiB-page kernel *and* something depends
  on `__TEXT` staying non-writable. Nothing in our test plan does.
- **Nuisance if:** we merely need the copy-in fallback (~60 lines) plus
  union-protection. That is the realistic worst case.
- The genuine risk here is not the kernel — it is **writing code that conflates
  the Mach-O fixup page size (`0x4000`, a table property) with the host page
  size**. Mitigated by distinct types and by never calling `sysconf` inside
  `fixups_chained.c`.

### 4. TLS/TLV — **medium risk, well-understood**

- Fully measured: descriptor layout, the `[__thread_data || __thread_bss]`
  template, the `x0`-in/`x0`-out ABI, `MH_HAS_TLV_DESCRIPTORS`.
- **Blocker if:** something needs Darwin TLV and glibc TLS to interoperate in
  the *same* variable, which cannot happen — they are disjoint mechanisms and
  our guest only uses the Darwin one.
- **Nuisance if:** the register-preservation contract bites (write the entry in
  asm), or `dlopen`-of-a-TLS-dylib forces lazy descriptor installation, or C++
  `thread_local` destructors force `__cxa_thread_atexit`. All bounded, all days
  not weeks.
- One sharp edge: our `tlv_get_addr` calls `pthread_getspecific`, which is glibc
  code that itself uses glibc TLS via `TPIDR_EL0`. Fine — one thread pointer,
  two consumers, no conflict — but worth an explicit test with a guest thread
  created via our `_pthread_create` forwarder touching a guest `__thread` var.

### 5. `dyld_stub_binder` and lazy binding — **now a nuisance, was a hazard**

- **Measured away.** Chained-fixups binaries (the default at deployment target
  ≥ macOS 12) have no `__stub_helper`, no `__la_symbol_ptr`, and never bind
  `dyld_stub_binder`; their `__stubs` load straight from `__got`. For classic
  binaries we bind the lazy stream eagerly, which produces the identical set of
  bindings.
- **Blocker if:** a binary depends on a symbol being *unresolvable until first
  call* (`-undefined dynamic_lookup` plus a genuinely absent symbol). Fixtures
  must not do that; real frameworks occasionally do.
- **Nuisance if:** we eventually want the real thing — a register-preserving asm
  trampoline that reads the pushed lazy-stream offset. Half a day.

### 6. Code signing — **not a risk**

- Measured: the signature is a blob inside `__LINKEDIT` that we already map and
  never read. Linux has no AMFI. Removing the signature on macOS still runs.
- The only observable effect is the presence/absence of `executable_cdhash` and
  `executable_boothash` in `apple[]` — which is why fixtures must not assert on
  `apple[]` past index 0.

### 7. Things I found that were not on the list

**a. `LC_MAIN` points at `main`, not at a `start` stub.** (Measured.) There is
no crt1 to lean on: the loader is fully responsible for the C runtime — argc/argv
plumbing, `environ`, `atexit`/`__cxa_atexit` registration, and `exit(main(...))`.
Cheap, but it must be *known*, because "just jump to the entry point" is the
wrong mental model. **Nuisance.**

**b. `__init_offsets` replaced `__mod_init_func`.** (Measured.) A loader written
from a 2015 Mach-O tutorial will find no `__mod_init_func` in a modern binary and
silently run zero initialisers — a *silent wrong answer*, the worst failure mode.
Both must be implemented and the "neither present" case must be distinguished
from "present and empty". **Nuisance, but a trap.**

**c. Data imports.** `___stderrp`, `___stack_chk_guard`, `_greet_count`,
`__objc_empty_cache`, `_OBJC_CLASS_$_NSObject` are all *data* binds through
`__got` (measured). A resolver that assumes imports are functions will produce
garbage rather than an error. **Nuisance, but a trap.**

**d. C++ / libc++ / exception unwinding.** `cpp.cpp` pulls in
`/usr/lib/libc++.1.dylib` plus `___gxx_personality_v0`, `__Unwind_Resume`,
`___cxa_throw`, and `LC_LOAD_DYLIB` on libc++. Darwin's libc++ is
`std::__1`-namespaced exactly like Linux libc++, so a forwarding shim is
plausible — but **unwinding is not forwardable**: `_Unwind_*` walks
`__TEXT,__unwind_info` (Apple's compact unwind format), which is *not*
`.eh_frame`. Either we ship Apple's `libunwind` built as Mach-O, or we implement
the compact-unwind reader. **Blocker for the C++-exceptions rung, nuisance for
everything below it** — and the reason C++ sits above TLS on the ladder rather
than next to it.

**e. `dlopen` re-entrancy.** `dlopen` is a libSystem symbol (measured) that must
call back into our loader while the loader may be mid-initialisation. Designing
`image_load` re-entrant from the start is nearly free; retrofitting it is not.
**Nuisance if planned for, days if not.**

**f. arm64e.** `cpusubtype == 2` means pointer authentication and chained
pointer format 1 with signed pointers. Linux/arm64 hardware may not expose PAC,
and the signing keys are process-scoped. Reject arm64e at the front door with a
clear message. **Out of scope, and saying so is the correct answer.**

**g. Fat/universal binaries.** `0xcafebabe` header, needs a slice selector.
All fixtures are thin. ~40 lines whenever we want it. **Nuisance.**

---

## Part IV — Milestones, tied to the fixture ladder

Each rung is: a fixture built once on the macOS oracle, its stdout/stderr/exit
status recorded, then run under `machorun` on Linux with a byte-exact diff. A
rung is not done until that diff is clean.

**The corpus already exists.** It was built concurrently with this study and is
committed as bytes under `tests/bin/`, indexed by `tests/manifest.tsv`, and
documented in `docs/FIXTURES.md`. Its rungs (a)–(i) are the ladder; the M
numbering below maps onto them. Its independent measurements agree with mine on
every overlapping fact (`imports_format=1`, `pointer_format=6`,
`page_size=0x4000`, the deployment-target axis, `__init_offsets` vs
`__mod_init_func`), which is the best evidence either of us has that the numbers
are right.

Rungs are cumulative — every earlier fixture must keep passing.

| M | rung / fixture | what the loader gains | what libSystem gains |
|---|---|---|---|
| **M0** | *(done)* `libtest.dylib` toolchain probe; corpus built and baselined | — | — |
| **M1** | (b) `main_ret`, `main_ret_classic` — `LC_MAIN`, exit status = `main`'s return, **zero undefined symbols** | header + LC parse, segment map, `__PAGEZERO`, base selection, chained fixups (fmt 6), `LC_MAIN` -> `main`, `apple[0]`, `exit(rc)` | loads but binds nothing; `__machorun_libsystem_bootstrap` |
| **M2** | (b) the `02c` classic variant | rebase/bind/lazy opcode interpreters, eager lazy binding, `dyld_stub_binder` abort-stub | — |
| **M3** | (c) `printf`, `printf_classic` — `_printf _puts _fflush ___stdoutp` | dylib resolution + prefix map, export trie, two-level lookup, GOT binds **including data symbols**, `__la_symbol_ptr` on the classic path | **our own printf formatter** (II.4 — not a forwarder), `___stdoutp` as a data export |
| **M4** | (d) `malloc` — allocator surface + `___stack_chk_guard` | nothing structurally new | ~15 bucket-A forwarders, `___stack_chk_guard`/`___stack_chk_fail` |
| **M5** | (e) `mod_init`, `mod_init_classic` — ctor priorities 101/102/default + dtor | `__init_offsets` **and** `__mod_init_func`, init ordering, Darwin init signature `(argc,argv,envp,apple)`, `SG_READ_ONLY` mprotect | `___cxa_atexit` / `___cxa_finalize` / `___dso_handle`, atexit on normal exit |
| **M6** | (f) `tls` | `__thread_vars` patching, TLV templates, per-image pthread key | `machorun_tlv_get_addr` (asm entry) |
| **M7** | (g) `dylib`, `dylib_classic` — `@rpath` dylib, data import, **reverse import back into the exe** | dependency graph, path expansion, dedup, `lib_ordinal` resolution, cross-image init ordering | — |
| **M8** | (h) `pthread` — create/join/mutex/once + per-thread TLV | TLV allocation on non-main threads | pthread forwarders |
| **M9** | (e′) `cxx_init` — C++ ctors/dtors, guarded local statics; then exceptions | `LC_REEXPORT_DYLIB`, `__unwind_info` | Mach-O `libc++.1.dylib` + `libc++abi` + `libunwind` with **compact-unwind** support |
| **M10** | (i) `objc` — Foundation-free ObjC: classes, selrefs, `objc_msgSend` | objc notify callbacks, image registration **before** `+load` | Mach-O build of `~/objc4-linux`'s `libobjc.A.dylib` |
| — | (a) `exit_raw` | **permanent XFAIL.** Raw `svc #0x80` with BSD numbers in `x16`. Supporting it is the syscall-emulation road this project chose not to take. Kept as a labelled wall. | — |
| — | (a′) `exit_unixthread` | `LC_UNIXTHREAD` parse + map with no dynamic linking. **NO-ORACLE** — macOS SIGKILLs it (verified, exit 137), so it can never be graded PASS. | — |

Note the reordering versus my first draft: the corpus puts **`printf` at rung
(c)**, third. Combined with II.4, that means the printf formatter is
**milestone-3 work, not milestone-5 work** — the single most schedule-relevant
consequence of the variadic finding.

Constraints on the corpus, measured and non-negotiable:

- No raw pointers in fixture output (an early draft of my own `ctors.c` printed
  `%p`; the committed `mod_init` correctly does not).
- No assertions on `apple[]` past index 0 — measured to vary with signing state
  (12 entries signed, 10 unsigned).
- Build fixup-format-sensitive fixtures at **both** `macos11` and `macos14`; the
  corpus does this for rungs (b), (c), (e) and (g).
- Assert on exit status and stderr, not just stdout. The corpus does.
- Beware `-Wl,-undefined,dynamic_lookup`: the corpus found it silently drags the
  linker back to `LC_DYLD_INFO_ONLY` even at `macos12`+. Use `-Wl,-U,_symbol`
  instead so the chained/classic axis stays controlled by `-target` alone.

### First-cut estimate

Engineering days, one focused implementer, stated as ranges because that is
honest. M1–M8 is the part I would bet on; M9–M10 has a genuine unknown in each.

The corpus being already built and baselined removes a real chunk of work from
every line below — each milestone starts with a runnable failing test rather
than with writing one.

| milestone | estimate | confidence |
|---|---|---|
| M1 `main_ret` chained — first end-to-end run | 3–5 d | high — everything is measured, no unknowns. This is the "it runs" moment. |
| M2 `02c` classic fixups | 1–2 d | high — opcode streams decoded byte-for-byte in MACHO_NOTES §6, which doubles as the test vector |
| M3 `printf` + our own formatter | 3–6 d | medium — the loader half is a day; the printf formatter (II.4) is the rest, and it is unavoidable |
| M4 `malloc` libSystem breadth | 2–4 d | high — mechanical, but the data-export and underscore traps cost a day of confusion once |
| M5 `mod_init` initialisers + atexit | 2–3 d | high |
| M6 `tls` | 2–4 d | medium — asm entry, and one thread-interaction case I expect to find something in |
| M7 `dylib` dependency graph + `@rpath` | 3–5 d | high — the path/ordinal/dedup rules are fiddly, not deep |
| M8 `pthread` | 1–2 d | high — mostly falls out of M6 |
| **subtotal M1–M8** | **17–31 d** | the tractable core, and the honest deliverable of "run a Mach-O on Linux" |
| M9 `cxx_init` + exceptions | 5–15 d | **low** — compact-unwind is the unknown; the range is wide on purpose |
| M10 `objc` | 5–20 d | **low** — dominated by whether objc4 builds clean as Mach-O |
| *(beyond the corpus)* Foundation-lite, `dlopen` | 10–30 d | very low — framework work, not loader work, and where scope discipline matters most |

**Recommended first action, before any loader code:** de-risk M10. Try
`clang -target arm64-apple-macos11` + `ld64.lld-18` on `~/objc4-linux` (which
today produces `build/linux-aarch64/libobjc.so`, an ELF) and see whether a
Mach-O `libobjc.A.dylib` comes out that macOS's `otool`/`nm` accept. One
afternoon, and it converts the project's largest unknown into a fact — the same
move that started this project.

**Second cheap de-risk:** write the printf formatter (II.4) early and test it
*on macOS* against the real `printf` using `printf`'s format string. It has
no dependency on the loader existing, it removes the second-ranked risk, and it
can be done in parallel.

---

## Open questions I could not settle by measurement

1. The exact `_dyld_objc_register_callbacks` struct shape for whichever objc4
   we ship. Must be read from that source, not assumed. (§I.9)
2. Whether `ld64.lld-18` emits `LC_DYLD_CHAINED_FIXUPS` or only the classic
   form, and whether its export tries are byte-compatible with what dyld expects.
   Our loader reads both, so this is a build-side question — but it decides
   whether our own dylibs exercise the same code path as guest binaries.
3. Whether Apple's `libunwind` compiles for Linux/arm64 as Mach-O, or whether
   the compact-unwind reader must be written from scratch. (§III.6d)
4. Whether any real framework binary uses chained pointer formats other than 6,
   or import formats other than 1. Every binary I built used 6/1 exclusively,
   and so did every binary in the fixture corpus; that is still not a proof
   about Apple-shipped code.
5. Whether Darwin's `qsort_r`, `atexit` ordering and `pthread_once` semantics
   differ from glibc's in ways a fixture would catch. I did not test these;
   they are the kind of thing that produces a one-line output diff at rung (d)
   or (h) and costs an hour to find.
