# The fixture ladder

Twenty Mach-O programs (plus two dylibs they load), built once by Apple's
toolchain on macOS and committed as bytes. Each one is run natively on macOS to record what it does, then run
under `machorun` on Linux/arm64. Same bytes, both sides. Outputs must match
exactly — stdout, stderr and exit status.

The ladder is ordered by what the loader has to support, simplest first, so it
doubles as the loader's roadmap. Everything below rung *n* must keep passing
when you start rung *n+1*.

Rungs (a) through (i) are about the **loader**. Rungs (j), (k) and (l) are
about the **userland**: they hold still while the loader is not the variable,
and probe the places where Darwin and Linux disagree about what a C call means.
The measurements behind them are in `docs/ABI.md`.

```
tests/src/         fixture sources
tests/bin/         the committed Mach-O binaries and dylibs
tests/expected/    recorded macOS behaviour (+ PROVENANCE stamp)
tests/meta/        otool -l and a per-binary structural summary
tests/manifest.tsv the machine-readable index the harness walks
```

Run it:

```
harness/run_macos.sh            re-verify the oracle on this Mac
harness/run_macos.sh --record   (re-)record baselines — Darwin only
harness/run_linux.sh            run the corpus under machorun in Docker
scripts/difftest.sh             both of the above, then the scoreboard
```

---

## Two structural axes that split the corpus

Both were measured, not assumed, on 2026-08-25 with Apple clang 17 /
ld-1230.1 / macOS 26.5.2.

### 1. Chained fixups vs classic dyld opcodes

The deployment target alone flips it:

| `-target` | fixups | load commands |
|---|---|---|
| `arm64-apple-macos11` | classic | `LC_DYLD_INFO_ONLY` (rebase/bind/lazy-bind/export opcode streams) |
| `arm64-apple-macos12`+ | chained | `LC_DYLD_CHAINED_FIXUPS` + `LC_DYLD_EXPORTS_TRIE` |

Everything Xcode has produced this decade is chained; `LC_DYLD_INFO_ONLY` is
what you meet in older binaries. The corpus carries **11 chained and 6 classic**
images so neither path can rot. Four sources are built **both** ways (`02`,
`03`, `05`, `07`), so a fixup-format bug shows up as an exact pair: the
chained fixture passes and its classic twin does not, or the reverse. That
pairing is what turns "it fails" into "it fails *here*".

For the chained images the concrete shape is:

```
imports_format   1  DYLD_CHAINED_IMPORT
pointer_format   6  DYLD_CHAINED_PTR_64_OFFSET   (4-byte stride, target is a
                                                  vmoffset from the load base)
page_size        0x4000                           (16K pages — arm64 macOS)
```

One gotcha worth stating plainly: `-Wl,-undefined,dynamic_lookup` drags the
linker *back* to `LC_DYLD_INFO_ONLY` even at `macos12`. `-Wl,-U,_symbol` does
not. The dylib fixtures use `-U` so the chained/classic axis stays controlled
by `-target` alone.

### 2. How initialisers are stored — and this one bites

The same `-target` lever silently changes where constructors live:

| `-target` | section | type | contents |
|---|---|---|---|
| `macos11` | `__DATA_CONST,__mod_init_func` | `0x09 S_MOD_INIT_FUNC_POINTERS` | absolute pointers, rebased at load |
| `macos12`+ | `__TEXT,__init_offsets` | `0x16 S_INIT_FUNC_OFFSETS` | `uint32` offsets from the mach_header, read-only, no fixups |

**A loader that only knows `__mod_init_func` runs zero constructors on a
modern binary and reports no error.** It just silently does nothing. That is
why rung (e) ships as two fixtures built from one source: `05_mod_init`
(offsets) and `05c_mod_init_classic` (pointers).

---

## The ladder

### (a) `01_exit_raw` — no libSystem calls at all
`tests/src/01_exit_raw.s` · classic · **xfail, on purpose**

Entry is `_start` via `LC_MAIN`. Writes to fd 1 and exits with `svc #0x80`,
syscall number in `x16`, BSD numbering (`write`=4, `exit`=1). libSystem is
linked but never called. macOS: prints `raw syscall ok`, exits 7.

Load commands: `LC_SEGMENT_64`×3, `LC_DYLD_INFO_ONLY`, `LC_SYMTAB`,
`LC_DYSYMTAB`, `LC_LOAD_DYLINKER`, `LC_UUID`, `LC_BUILD_VERSION`,
`LC_SOURCE_VERSION`, `LC_MAIN`, `LC_FUNCTION_STARTS`, `LC_DATA_IN_CODE`,
`LC_CODE_SIGNATURE`, `LC_LOAD_DYLIB`.

**Loader must implement:** nothing new — and that is the point. This fixture
marks the boundary of the README's core bet. On Linux/arm64 `svc` traps to the
Linux kernel, which takes its syscall number from `x8` and uses Linux
numbering; Darwin's `x16` + BSD numbers land somewhere arbitrary. Supporting it
would need seccomp-based trapping or binary rewriting, i.e. exactly the
Darwin-syscall-emulation road this project chose not to take. Kept as a
permanent, labelled wall — see `docs/UNIMPLEMENTED.md`.

### (a′) `01b_exit_unixthread` — static, `LC_UNIXTHREAD`
same source · no fixups · **no oracle**

Built `-static`: no `LC_LOAD_DYLINKER`, no dyld, no fixups, and entry is an
`LC_UNIXTHREAD` register-state block instead of `LC_MAIN`.

Load commands: `LC_SEGMENT_64`×3, `LC_UNIXTHREAD`, `LC_SYMTAB`, `LC_UUID`,
`LC_SOURCE_VERSION`. That is the whole list.

macOS 11+ on arm64 **refuses to exec this** — the kernel SIGKILLs it (exit 137)
because every arm64 macOS binary must go through dyld. So there is no baseline
and it can never be graded PASS; the harness reports `NO-ORACLE`. It stays in
the corpus because `LC_UNIXTHREAD` is a real entry form the loader's parser
must handle, and because a parse-only fixture is still a test.

**Loader must implement:** `LC_UNIXTHREAD` entry (`arm_thread_state64_t`, `pc`
field), and segment mapping with no dynamic linking at all.

### (b) `02_main_ret` / `02c_main_ret_classic` — LC_MAIN, return a value
`tests/src/02_main_ret.c` · chained + classic

`int main(int argc, char **argv) { return 40 + argc; }`. Exits 41. **Zero
undefined symbols** — libSystem is loaded but nothing is bound. The smallest
possible end-to-end run.

**Loader must implement:** parse the mach_header and load commands; map
`__PAGEZERO` / `__TEXT` / `__DATA_CONST` / `__DATA` / `__LINKEDIT` with the
right protections at a slid base; apply the (empty) fixup set; call
`entry(argc, argv, envp, apple)` at `LC_MAIN.entryoff + base`; exit with the
return value. `apple[]` must at minimum be a NUL-terminated array whose first
entry is the executable path — libSystem's startup reads it.

### (c) `03_printf` / `03c_printf_classic` — first libSystem dependency
`tests/src/03_printf.c` · chained + classic

Undefined: `_printf _puts _fflush ___stdoutp`.

Note `___stdoutp`: it is a **data** import, not a function. Our
`libSystem.B.dylib` has to export it as a real `FILE *` object, and the loader
has to bind data symbols through the GOT, not only branch targets through
stubs.

Sections: `__TEXT,__stubs` (`0x80000408` = `S_SYMBOL_STUBS` +
`PURE_INSTRUCTIONS|SOME_INSTRUCTIONS`), `__DATA_CONST,__got`
(`0x06 S_NON_LAZY_SYMBOL_POINTERS`). The **classic** variant additionally has
`__DATA,__la_symbol_ptr` (`0x07 S_LAZY_SYMBOL_POINTERS`) — chained fixups
abolish lazy binding entirely, so the two variants exercise genuinely
different code paths.

The output covers `%d %u %x %ld %s %c %% %5d %-5d %05d %.3f` so a
half-implemented `printf` forwarder gets caught.

**Loader must implement:** dependency resolution for `/usr/lib/libSystem.B.dylib`
(redirected to our own build), symbol lookup in a two-level namespace, GOT
binds, stub/`__la_symbol_ptr` binding (classic path may bind eagerly rather
than implement `dyld_stub_binder` lazily — but then say so). Darwin's arm64
variadic ABI differs from AAPCS64: variadic arguments go on the stack, 8-byte
aligned, never in `v0`–`v7`. If our `printf` forwards to glibc's, that
mismatch is the first thing that will break.

### (d) `04_malloc` — the allocator surface
`tests/src/04_malloc.c` · chained

Undefined: `_malloc _calloc _realloc _free _strdup _strlen _posix_memalign
_printf _puts ___stack_chk_fail ___stack_chk_guard`.

`___stack_chk_guard` is another data import — the stack protector cookie.

Nothing is printed that depends on an address, so the output is identical
under any allocator. Ends with a churn loop (128 mixed allocations, partial
free, realloc-to-9000, full free) to catch a forwarder that works once.

**Loader must implement:** nothing structurally new. This rung is about
`libSystem`'s completeness, and it is the first fixture where "forward to
glibc" is doing real work.

### (e) `05_mod_init` / `05c_mod_init_classic` — static initialisers
`tests/src/05_mod_init.c` · chained + classic

Three constructors with priorities 101, 102 and default, plus a destructor.
The output asserts the ordering:

```
ctor 101 order=1
ctor 102 order=2
ctor default order=3
main order=4
dtor order=5
```

Sections: chained → `__TEXT,__init_offsets` (`0x16`); classic →
`__DATA_CONST,__mod_init_func` (`0x09`). See the warning above.

**Loader must implement:** both initialiser section forms; call each with the
Darwin initialiser signature `(int argc, char **argv, char **envp,
char **apple)`; run them **before** the `LC_MAIN` entry and in file order;
route `__attribute__((destructor))` through `__cxa_atexit` / `__cxa_finalize`
with a per-image `___dso_handle`, and actually run atexit handlers on normal
exit.

### (e′) `05b_cxx_init` — C++ globals
`tests/src/05b_cxx_init.cpp` · chained · **xfail: needs libc++**

Two namespace-scope objects with non-trivial ctors/dtors, plus a guarded
function-local static and a `std::string`. Destructors must run in reverse
construction order after `main`.

**Loader must implement:** as (e), plus `libc++.1.dylib` and
`libc++abi.dylib` shipped as Mach-O — including `__cxa_guard_acquire` /
`__cxa_guard_release` for the local static. Blocked until those exist.

### (f) `06_tls` — thread-local storage
`tests/src/06_tls.c` · chained

Undefined: `_printf __tlv_bootstrap`. Sections:

```
__DATA,__thread_vars   0x13  S_THREAD_LOCAL_VARIABLES
__DATA,__thread_data   0x11  S_THREAD_LOCAL_REGULAR
__DATA,__thread_bss    0x12  S_THREAD_LOCAL_ZEROFILL
```

The mach_header also gains the `MH_HAS_TLV_DESCRIPTORS` flag.

Darwin does not use ELF TLS relocations. Each `_Thread_local` variable gets a
three-word descriptor in `__thread_vars`:

```c
struct tlv_descriptor {
    void *(*thunk)(struct tlv_descriptor *);
    unsigned long key;
    unsigned long offset;
};
```

Generated code loads the descriptor address, loads `thunk` from word 0, and
calls it with the descriptor in `x0`; the thunk returns this thread's address
for that variable. Before first use the thunk is bound to `__tlv_bootstrap`,
which allocates the thread's TLV image on demand.

**Loader must implement:** recognise the three section types; register a TLV
template (initialised bytes from `__thread_data`, zeroes for `__thread_bss`);
export `__tlv_bootstrap` and a `tlv_get_addr`; allocate a per-thread image
lazily, keyed per image, and free it at thread exit. Nothing about ELF TLS
carries over — this is a from-scratch mechanism.

### (g) `07_dylib` / `07c_dylib_classic` — two images
`tests/src/07_dylib_main.c` + `tests/src/07_dylib_lib.c` · chained + classic

The executable carries `LC_RPATH = @loader_path` and an `LC_LOAD_DYLIB` for
`@rpath/lib07greet.dylib`; the dylib carries `LC_ID_DYLIB`. Both must sit in
`tests/bin/` together.

Undefined in the exe: `_greet _greet_via_callback _greet_counter _greet_name
_printf _puts`. Undefined in the dylib: `_exe_callback` (plus `_printf`).

Four distinct things in one fixture:
* a function import across images,
* a **data** import (`greet_counter`, a plain GOT slot, no stub), read *and*
  written from the executable, with the dylib observing the write,
* a **reverse** import — the dylib calls `exe_callback`, which the executable
  exports (linked `-Wl,-export_dynamic`), so the main image's exports have to
  be published into the lookup namespace,
* initialiser ordering across images: `lib ctor` prints before `exe ctor`.

**Loader must implement:** `@rpath` / `@loader_path` / `@executable_path`
expansion against `LC_RPATH`; a load graph with de-duplication by install
name; two-level namespace binding (each import names its source dylib by
ordinal); exporting the main executable's symbols; and running each image's
initialisers in dependency order, dependencies first.

### (h) `08_pthread` — threads and per-thread TLS
`tests/src/08_pthread.c` · chained

Undefined: `_pthread_create _pthread_join _pthread_mutex_lock
_pthread_mutex_unlock _pthread_once __tlv_bootstrap _printf
___stack_chk_fail ___stack_chk_guard`.

Four threads, each incrementing its own `_Thread_local` copy from 5, a
mutex-guarded shared counter, and a `pthread_once`. Threads are joined in
order and all printing happens from `main`, so the output is deterministic:

```
thread 1 tls=6 … thread 4 tls=9
shared=10
once_count=1
main tls=5
```

`main tls=5` is the real assertion: main's own TLS copy must be untouched by
the workers.

**Loader must implement:** `pthread_*` forwarding, plus the hard part — TLV
images allocated per thread on first touch, and `PTHREAD_MUTEX_INITIALIZER` /
`PTHREAD_ONCE_INIT` static initialisers that must be layout-compatible between
what Apple's headers baked into the fixture at compile time and what our
libSystem does at run time. That struct layout is compiled into the binary and
cannot be changed later.

### (i) `09_objc` — Objective-C
`tests/src/09_objc.m` · chained · **xfail: needs libobjc**

Deliberately Foundation-free — links `libobjc.A.dylib` and `libSystem` only,
using a root class. That aims it squarely at `~/objc4-linux`.

Undefined: `_objc_msgSend _objc_getClass _object_getClass _object_dispose
_class_createInstance _class_getName _class_respondsToSelector
_sel_registerName _sel_getName __objc_empty_cache _printf` — note
`__objc_empty_cache`, a data import from libobjc that every class structure
points at.

Sections the other fixtures never produce:

```
__TEXT,__objc_stubs  __TEXT,__objc_methlist  __TEXT,__objc_classname
__TEXT,__objc_methname  __TEXT,__objc_methtype
__DATA_CONST,__objc_classlist  __DATA_CONST,__objc_imageinfo
__DATA,__objc_const  __DATA,__objc_selrefs (0x10000005)
__DATA,__objc_classrefs  __DATA,__objc_ivar  __DATA,__objc_data
```

`__objc_selrefs` carries `S_ATTR_NO_DEAD_STRIP | S_LITERAL_POINTERS`: its
slots start as pointers into `__TEXT,__objc_methname` and are **rewritten by
libobjc at image-load time** to uniqued `SEL` values. The fixture asserts that
uniquing worked (`sel-uniqued=1`).

**Loader must implement:** everything above, plus the dyld↔objc handshake.
Real dyld calls the runtime's `map_images` / `load_images` callbacks
(registered through `_dyld_objc_register_callbacks`) after mapping and fixups
but before initialisers. A loader that only maps segments and applies fixups
crashes here, because no class ever gets registered. Expect this to fail until
libobjc is ported — that failure is the fixture doing its job.

### (j) `11_varargs` / `11c_varargs_classic` — the Darwin variadic ABI
`tests/src/11_varargs.c` · chained and classic

`03_printf` proves the easy half of varargs. This is the one that catches a
`printf` that walks the Darwin `va_list` *almost* right.

The divergence, measured (`docs/ABI.md` §1): Darwin/arm64 passes **every**
variadic argument on the stack, one 8-byte slot each, in declaration order, and
`va_list` is a bare `char *` of 8 bytes. Linux/aarch64 passes the first eight
integer variadics in x1-x7 and the first eight FP variadics in v0-v7, and
`va_list` is a 32-byte struct over two register save areas. A libSystem that
hands its `va_list` to glibc's `vprintf` dies with SIGSEGV at fault address
`0x4d2` — which is 1234, the first argument of `printf("int=%d\n", 1234)`.

So the fixture uses: twelve integer arguments and twelve doubles (past what
AAPCS64 would have kept in registers), interleaved int/double/pointer in one
list (the register-file split Darwin does not make), default promotions,
`long long`/`size_t`/`intmax_t` length modifiers, `*` width and precision,
`%#o` and the flag set, `%e`/`%g`/`%.10f`, a `long double` (**8 bytes on
Darwin, 16 on Linux** — a second, independent reason the family cannot be
forwarded), the guest's own variadic functions consuming with `va_arg`, a
`va_list` handed from the guest into our `vsnprintf`, `va_copy` walked twice,
and `snprintf` truncation and sizing semantics.

Built in both fixup formats on purpose: the variadic ABI is a property of
libSystem, not of the fixup encoding, and the pair says so.

**libSystem must implement:** the whole `printf` family over the Darwin
`va_list`, with only finished bytes crossing to glibc. This fixture is what
caught `%#o` dropping its leading zero.

### (k) `12_mach` — the Mach APIs
`tests/src/12_mach.c` · chained

The README's bet says Mach is "a bounded list, not a kernel ABI". This is the
bound, for plain C: `mach_task_self` (a *data* symbol, `_mach_task_self_`, not a
function — `nm -u` says so), `mach_thread_self`, `mach_port_deallocate`,
`vm_allocate`/`vm_protect`/`vm_deallocate`, `mach_absolute_time`,
`mach_continuous_time`, `mach_timebase_info` and `mach_error_string`.

Nothing prints a raw port name, address or timestamp — those are legitimately
different on the two platforms. What must be identical is the *behaviour*:
success codes, 16 KiB alignment, zero-fill, read-back of memory we own, two
allocations being disjoint, monotonicity, a 120 ms sleep measuring inside
[100 ms, 3 s] after conversion through the timebase, and Apple's exact error
strings.

**libSystem must implement:** `vm_allocate` over `mmap`, over-mapping and
trimming so the result is 16 KiB-aligned even on a 4 KiB-page kernel;
`mach_absolute_time` over `clock_gettime`, with `mach_timebase_info` reporting
the unit it actually returns. Ports are names in our own table — see
`docs/UNIMPLEMENTED.md#mach-ports-are-fiction`.

### (l) `13_errno` — the numbers that are not the same
`tests/src/13_errno.c` · chained

Three translations, each of which changes behaviour and not just presentation:

- **errno.** 54 of the 87 errno names common to both systems have different
  values, and the dangerous ones are *swapped*: `EAGAIN` is 35 on Darwin and 11
  on Linux, `EDEADLK` is 11 on Darwin and 35 on Linux. The fixture's headline
  case is `rmdir` on a non-empty directory: `ENOTEMPTY` is 66 to the guest and
  39 to glibc.
- **`O_*` flags.** Ten of thirteen differ, and Darwin's `O_CREAT` (0x0200) *is*
  Linux's `O_TRUNC`. Forwarding the flag word performs a different operation:
  the fixture's `open(O_WRONLY|O_CREAT|O_TRUNC)` fails `ENOENT`.
- **`struct stat`.** 144 bytes against 128, `st_mode` and `st_nlink` 16-bit
  against 32-bit, `st_size` at offset 96 against 48. Copying the bytes gives a
  12-byte file an `st_size` of 471711007.

It also pins the errno *protocol*: `errno = 0` before a successful call must
still read 0 afterwards, the `strtol`/`ERANGE` idiom must work, and a value the
guest writes must persist. Those three are what force errno to be bracketed in
both directions rather than merely translated on the way out.

**libSystem must implement:** a per-thread Darwin errno slot behind `__error()`,
translation tables generated from a measurement of both platforms
(`scripts/gen_errno_table.sh`), `open` flag translation with a loud refusal for
the unmappable ones, `struct stat` field-by-field translation, and `strerror`
with Apple's own text.

---

### (x) `10_fat` — universal binary
`lipo` of an x86_64 build and the arm64 `03_printf` · chained

Off-ladder; it tests structure, not a new runtime capability. `FAT_MAGIC`
(`0xcafebabe`), two real slices, big-endian `fat_arch` records.

Its recorded baseline is byte-identical to `03_printf`'s, because macOS picks
the arm64 slice and then behaves exactly like the thin binary. That is the
design: **any** difference under machorun is a slice-selection bug and nothing
else. The x86_64 slice is a genuine build rather than padding, so a loader
that simply takes the first slice will fail loudly instead of accidentally
working.

`tests/meta/10_fat.summary.txt` says so explicitly — `otool` merges all slices
in its output, so the load-command and section lists there are the union
across architectures, not what the loader will see after selection.

**Loader must implement:** detect `FAT_MAGIC`/`FAT_CIGAM` (and the 64-bit
variants), read the `fat_arch` table as big-endian, select
`CPU_TYPE_ARM64`/`CPU_SUBTYPE_ARM64_ALL`, and treat that slice's offset as the
origin of the Mach-O — every file offset in the slice is relative to it, which
is the classic place to get an off-by-`fat_arch.offset` bug.

---

## What the harness guarantees

`tests/expected/` is the oracle's output and nothing else may write it.

1. `harness/run_macos.sh` refuses to start on any non-Darwin host, so
   `--record` does not exist on Linux. Verified: it exits 64 inside the
   container.
2. Recording stamps `tests/expected/PROVENANCE` with the OS, kernel, macOS
   build, clang and ld that produced the baselines. `scripts/difftest.sh`
   reads that stamp and refuses to grade at all unless it says `Darwin`.
3. `harness/run_linux.sh` bind-mounts `tests/expected` into the container
   **read-only**, so the rule is enforced by the kernel rather than by good
   intentions. Verified: writes and deletes both fail with `EROFS`.
4. Every `difftest.sh` run re-executes the corpus natively on macOS first and
   compares against the baselines. A mismatch is reported as
   `BASELINE-DRIFT`, and the affected fixture can then never be scored `PASS`
   in that run. Re-recording is a deliberate, separate, committable act.

Verdicts: `PASS` `FAIL` `XFAIL` `XPASS` `SKIPPED` `NO-ORACLE` `BASELINE-DRIFT`.
`XPASS` matters — it means a documented wall has fallen and the manifest is now
lying.

## Rebuilding

```
tests/build_fixtures.sh              rebuild everything (macOS only)
tests/build_fixtures.sh 06_tls       rebuild one
harness/run_macos.sh --record        re-record after any rebuild
```

Rebuilding produces different bytes (fresh `LC_UUID` and ad-hoc code
signature) even from identical sources. Since the binaries are committed, the
normal state is not to rebuild; if you do, commit the new binaries and the
re-recorded baselines together and say why.
