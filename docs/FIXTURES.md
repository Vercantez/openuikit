# The fixture ladder

Twenty-five Mach-O programs (plus two dylibs they load), built once by Apple's
toolchain on macOS and committed as bytes.

> **These binaries must keep coming from Xcode, and `sdk/` must never be used to
> rebuild them.** Since 2026-08-26 this repository can compile and link a Mach-O
> guest entirely on Linux against its own SDK, which makes rebuilding the corpus
> *possible* for the first time and no less wrong. The fixtures are the
> precompiled Darwin binaries the whole project exists to run: their value is
> that somebody else's linker chose their layout, their fixup format, their
> import list and their initialiser sections. Relink them with `ld64.lld`
> against our own `.tbd` stubs and the suite would prove that our linker agrees
> with our loader, which is not a fact anyone needs.
> `tests/build_fixtures.sh` refuses to run off Darwin for this reason.
> `scripts/gen_tbd.sh`'s completeness check depends on it too: the corpus is a
> meaningful test of whether our stubs are complete only *because* Apple's
> linker chose those 223 imports.
>
> The one program built on both sides is `sdk/tests/abi_probe.c`, and it is
> deliberately not in `tests/bin` — its entire point is to be compiled twice and
> diffed. See `sdk/PROVENANCE.md` §5. Each one is run natively on macOS to record what it does, then run
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
tests/src/              fixture sources
tests/bin/              the committed Mach-O binaries and dylibs
tests/expected/         recorded macOS behaviour (+ PROVENANCE stamp, + PNGs)
tests/meta/             otool -l and a per-binary structural summary
tests/manifest.tsv      the machine-readable index the harness walks
tests/draw_manifest.tsv the same, for the three fixtures whose result is a PNG
harness/pngdiff.c       says WHERE two PNGs differ, not just that they do
```

Run it:

```
harness/run_macos.sh            re-verify the oracle on this Mac
harness/run_macos.sh --record   (re-)record baselines — Darwin only
harness/run_linux.sh            run the corpus under machorun in Docker
scripts/difftest.sh             both of the above, then the scoreboard

scripts/quartz_pixel.sh         the same, for the DRAWING fixtures (n, o, p)
scripts/quartz_pixel.sh --record  (re-)record their baselines — Darwin only

scripts/stage_swiftcore.sh      stage the cross-built Swift runtime, once
scripts/swift_gate.sh           the same again, for the SWIFT fixture (q)
scripts/swift_gate.sh --record  (re-)record its baseline — Darwin only
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

### (m) `14_utility` — a representative hand-built utility
`tests/src/14_utility.c` · chained

Every other rung isolates one mechanism. This one deliberately does not: it is
the shape of program milestone 1 is *for*, and it exists to answer "what would
the next binary need" by measurement. Written first, run second: it was seven
symbols short, and those seven became `darwin/src/ctype.c`.

The interesting import is not a function:

```
__DefaultRuneLocale     ___maskrune
```

Darwin's `<ctype.h>` does not call `isdigit()`; it inlines
`_DefaultRuneLocale.__runetype[c] & _CTYPE_D` into the guest's own
instructions. A 3208-byte data table — layout *and* contents — is therefore
part of the ABI. `scripts/gen_rune_table.sh` records Apple's actual bytes; the
fixture prints all twelve classes over all 128 ASCII characters, so one wrong
bit is one wrong column. `scripts/abi_naive_probe.sh rune` empties the table
and everything classifies as nothing, with no function of ours ever called.

It also covers `setlocale` (we have exactly one locale and say so, rather than
pretending a change took), `getopt` over a synthetic `argv` — Darwin's does not
permute and glibc's does, so forwarding would change which arguments a program
sees — `qsort` calling back into guest code, `strftime`/`gmtime_r`/`timegm`
over a `struct tm` that is byte-identical on both systems, `fgets`, and the
`strtol` idiom. That last one is what caught the divergence in §9 of
`docs/ABI.md`: `strtol("zz")` sets `EINVAL` on Darwin and leaves `errno` alone
on Linux.

**libSystem must implement:** Apple's rune table as static data (statically
initialised, because the guest's own constructors are entitled to call
`isdigit`), `__maskrune`/`__tolower`/`__toupper` and the out-of-line `is*`
family, `setlocale` for C and a refusal for anything else, BSD `getopt` with
our own `optarg`/`optind`, the time surface, and a `strtol` family that sets
`EINVAL` where Darwin's does.

---

### (y) `26_malloc_type` — Apple's typed allocator, and the size argument
`tests/src/26_malloc_type.c` · chained

**This rung exists because its absence cost the project its longest bug.**
machorun's libSystem had no `malloc_type_*` family at all, so a sibling repo
supplied its own `malloc_type_zone_malloc_with_options_internal` with four
parameters instead of five. The real signature is
`(zone, align, size, options, type_id)`, so the argument it forwarded to
`malloc` as the size was the **alignment** — it compiled to `mov x0, x1;
b _malloc`, sixteen bytes whatever was asked for, and every caller wrote its
whole object over the neighbours. One wrong register was the entirety of the
"46 UIKit scenes fail with nondeterministic memory corruption" wall.

Three design decisions, each of which the bug would have defeated otherwise:

* **Every request uses a size and an alignment that differ, and neither is 16.**
  A wrong-argument bug in this family is invisible whenever the two coincide,
  and 16 is both the usual alignment and a plausible size — the one value that
  hides the bug rather than showing it. No requested size here can be produced
  by accident from the alignment, the count, the options word or the zone
  pointer.
* **`malloc_size` is checked BEFORE anything is written.** The broken version
  returned a perfectly valid pointer every single time; the damage surfaced
  somewhere else, later, as somebody else's crash. A fixture that only wrote and
  looked for a crash would be testing the heap's luck. The guard blocks and the
  full-size fill are a second layer, for a block that is honestly reported and
  still too small.
* **The negative cases are checked too**, because an implementation that
  succeeds where macOS returns NULL diverges in the permissive direction, which
  nothing downstream notices. Those rules are **measured, not read** — no header
  states them: `aligned_alloc` and `..._zone_malloc_with_options_internal`
  return NULL when the alignment exceeds 16 and the size is not a multiple of
  it, while `zone_memalign`, `posix_memalign` and `valloc` have no such rule.

Teeth demonstrated rather than predicted: rebuilding `darwin/src/objcsupport.c`
with the four-parameter form reproduces `mov x0, x1; b _malloc` exactly
(confirmed with `otool`, not assumed), and the fixture reports
`wanted 6144, got 40` — 40 being what glibc makes of a 32-byte request — plus
the negative case, for five failures against a clean oracle.

**Loader must implement:** nothing. This is entirely a `darwin/src/` rung; it is
here because the family is libSystem surface and a hole in libSystem does not
stay empty.

---

### (z) `27_unwind` — unwinding a real stack through compact `__unwind_info`
`tests/src/27_unwind.c` · chained

**It WALKS, it does not link.** Every unwind symbol resolved perfectly for as
long as the unwinder was a set of aborting stubs, so a link test would have
passed throughout — the same trap that hid the `std::__sort` recursion, where
the symbol existed and the body was an infinite loop.

Apple's binaries carry no `.eh_frame`. `__TEXT,__unwind_info` is a compressed
two-level page table whose leaves are 32-bit encodings of a frame's shape. To
name `level1` as the caller of `level2`, libunwind has to find the right
second-level page by binary search, decode the encoding, work out where `x29`
and `x30` were spilled, and restore them. Getting the page lookup or the
register mask wrong still produces AN answer — just the wrong frame.

**THE macOS ORACLE REJECTED THE FIRST VERSION AND WAS RIGHT**, which is the most
useful thing this rung has produced. It matched frames by calling
`_Unwind_FindEnclosingFunction` and comparing against `&level1/&level2/&level3`,
and it failed on macOS against Apple's own libunwind, naming none of the three.
**Compact unwind COMPRESSES**: consecutive functions with identical encodings
share one entry, so the reported `start_ip` is the start of the RUN, not of the
function — and three adjacent one-line functions are exactly the case that
merges. `_Unwind_FindEnclosingFunction` is not a function-identity oracle on any
platform, and a test built on that assumption tests the wrong thing everywhere.

What replaced it is exact and immune to merging: each level records its own
`__builtin_return_address(0)` on the way down, and the walk must report those
same addresses on the way out. Comparing the unwinder against the compiler's own
idea of the return address cannot be passed by accident.

Two smaller traps the fixture had to survive, both measured:

* **`walk()` must be `noinline`.** It is `static` and called once, so at `-O1`
  clang inlines it into `level3`; then two levels record the SAME return address
  and the frames under test shift by one. The tell was `ra[0] == ra[1]`, which is
  impossible unless a frame vanished.
* **`ip - 1` before any lookup.** `_Unwind_GetIP` returns a return address and
  the byte after a call can belong to the next function — the same off-by-one
  `src/crash.c` had.

**Teeth demonstrated by two mutations of `src/unwind.c`**, each with the defect
confirmed present in the built loader (source marker plus a changed md5) before
the result was trusted — a mutant that did not take reads exactly like a fixture
with no teeth:

| mutation | result |
|---|---|
| drop the image slide | SIGSEGV at `0x12f74`, an unslid section address |
| swap the two sections | exit 1, no crash, three named failures |

The second matters more. A wrong answer that does not crash is the failure mode
this rung exists for. The CFA-monotonic check is labelled in the source as NOT
the tell: under the second mutation the walk stops at frame 0, so it has nothing
to compare and reports "yes" on a build where three other checks fail. It is
kept for the opposite case — a decoder producing plausible pcs while mis-reading
frame sizes — and the label is there so nobody rediscovers why it never fires.

**Loader must implement:** `_dyld_find_unwind_sections` — given any address,
the mach header of the containing image and the live addresses and lengths of
its `__TEXT,__eh_frame` and `__TEXT,__unwind_info`. Live addresses: a section
header's `addr` is where the linker wanted it and every image here is slid. A
zero `dwarf_section` is normal rather than a gap — Apple's linker emits compact
unwind for everything it can express and none of this corpus has an
`__eh_frame`. Also `_dyld_register_func_for_remove_image`, which is honestly a
no-op: nothing is ever unmapped here, so the callback would have nothing to
report.

---

### (ac) `30_throw` — an exception that is really thrown and really caught
`tests/src/30_throw.cpp` · chained

Rung (z) proved the UNWINDER decodes Apple's compact `__unwind_info`. It says
nothing about throwing, because walking a stack and unwinding one are different
jobs: `__cxa_throw` allocates an exception and calls `_Unwind_RaiseException`,
and `__gxx_personality_v0` then decides AT EACH FRAME whether a handler matches
by parsing that frame's LSDA and comparing `type_info`. A fixture that links, or
that throws and catches inside one function, exercises none of it.

So every case throws across at least one frame boundary, and the interesting
ones are about SELECTION rather than success:

* catch by exact type, with an intermediate frame in between
* catch by BASE class when a derived is thrown — needs `private_typeinfo`'s
  hierarchy walk rather than a pointer compare
* **a handler that must NOT match**, so the exception passes through it and is
  caught further out. **This is the case that matters**: a personality routine
  that said "yes" to everything would pass every other case here and fail only
  this one.
* destructors running during unwinding, IN ORDER — the cleanup phase rather
  than the handler phase
* rethrow from inside a catch, reusing the in-flight exception object
* `std::runtime_error`'s `what()`, i.e. the vtable survived the trip

**Why the destructor ORDER string is printed and not just a count.** "It did
not crash" is not evidence: an unwinder that skips cleanup frames still delivers
the exception to the right handler and looks perfect. The order catches a
cleanup phase that visits frames in the wrong sequence; the count catches one
that skips them entirely.

**The corpus check earned its keep here.** The fixture named three symbols our
libc++ did not have the moment it existed — `std::runtime_error`'s constructor
and destructor, and `std::current_exception`. Those are what real code throws,
so the library grew (`vendor/libcxx`'s `exception.cpp` and `stdexcept.cpp`)
rather than the fixture shrinking. Weakening a test to fit the implementation is
backwards.

**Loader must implement:** nothing new beyond rung (z)'s
`_dyld_find_unwind_sections`. What this rung needs is `LC_REEXPORT_DYLIB`
chasing, which `src/resolve.c`'s `lookup_in` already did — the gap was that our
`libc++.1.dylib` had nothing to chase.

---

### (ae) `32_dlopen` — loading a dylib at run time
`tests/src/32_dlopen.c` + `tests/src/32plug.c` · chained

Until this rung, machorun could load only what a binary's load commands named.
It is what took the objc4 corpus from **43/44 to 44/44**.

**Mapping an image is the easy part and proves almost nothing**, so the plugin
carries one of each thing the rest of the sequence exists for: an exported
function (the export trie must be reachable THROUGH A HANDLE, a different lookup
from the flat `RTLD_DEFAULT` search that already worked), a `__mod_init_func`
(initialisers must run, and before `dlopen` returns), a `__thread` variable (TLV
descriptors for an image arriving after the process is threaded), and a call
into libSystem (a bind in the NEW image against an OLD one). **A fixture that
only checked `dlopen(...) != NULL` would pass with three of those four broken.**

Identity is checked twice, because Darwin returns the same handle for the same
image and does not re-run its initialisers — an implementation that reloads
produces two copies of the plugin's state, invisible until something depends on
identity, and objc4 depends on it hard.

**Teeth, by three mutations of `src/image.c`, each confirmed in the built loader
before the result was trusted — and one of them PASSED:**

| mutation | result |
|---|---|
| skip `mr_run_initialisers` | FAIL on the initialiser and TLV cases |
| skip `mr_objc_note_new_images` | **passes here** — this fixture has no ObjC; `042-dlopen` catches it, on machorun's own "load_images before map_images" invariant |
| fixups oldest-first | **passes, and correctly** — `mr_image_load` maps the whole graph before anything is bound, so the iteration order is cosmetic |

The third is worth keeping visible: **a mutation that passes because the
property is not a property is not a missing test.** Recording it stops someone
later "fixing" an ordering that never mattered.

**Loader must implement:** `mr_dlopen` — the startup sequence for one image on
demand, with the objc notification scoped to the new images only. And resolve
the path BEFORE asking whether it is loaded: the caller's spelling is almost
never the image table's.

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

### (n) `15_quartz` — the drawing rung, and the one fixture off the ladder

Plain C, no Objective-C. Links `/usr/lib/libquartz.dylib` (our Mach-O build of
`~/quartz`) plus libSystem and nothing else. Creates a 256×256 bitmap context,
draws nine stages, writes a PNG.

**It is not in `tests/manifest.tsv` and `scripts/difftest.sh` does not grade
it.** Two structural reasons, neither of which is worth a special case in the
shared harness:

* its result is a **file**, not stdout; and
* its macOS run needs `DYLD_LIBRARY_PATH`, because its install name is the
  absolute Darwin path `/usr/lib/libquartz.dylib`, which exists on neither host.

`scripts/quartz_pixel.sh` is its differential and follows the same rules as
`difftest.sh` — it re-executes the macOS oracle every run rather than trusting
the committed baseline, and it writes `tests/expected/` only under `--record`,
only on macOS.

The absolute install name is deliberate and `@rpath` was rejected: `@rpath`
resolves against the same repository layout on both hosts, so **both** runs
would load the same file and the Linux run would silently not be testing the
Linux build. On Linux, machorun's prefix map turns the absolute path into
`darwin/usr/lib/libquartz.dylib`; on macOS, `DYLD_LIBRARY_PATH` substitutes the
leaf name against an Apple-clang build of the same vendored sources.

What each stage is for, and which one matters most:

| stage | exercises |
|---|---|
| 1 background | flat fill, premultiplied store |
| 2 rects | integer-boundary coverage, no AA decisions |
| 3 alpha-rects | source-over with fractional coverage |
| 4 bezier-fill | cubic flattening tolerance |
| 5 dashed-stroke | the stroke converter, round caps and joins |
| 6 linear-gradient | per-scanline interpolation under a rect clip |
| 7 radial-gradient | the same through a sqrt, under an ellipse clip |
| **8 rotated** | **the only stage that reaches a transcendental** |
| 9 eo-clip | even-odd winding |

Stage 8 is `QZContextRotateCTM`, i.e. `cos`/`sin`, i.e. Apple's Libm on one side
and glibc's on the other through `darwin/src/math.c` — very likely via the
`__sincos_stret` aggregate ABI. IEEE 754 pins nothing about either function, so
that is the stage a divergence would appear in first. The fixture prints an
FNV-1a of the whole framebuffer after **every** stage precisely so that such a
divergence is localised on stdout before the PNG is compared.

Measured 2026-08-26: all nine checksums identical, PNG byte-identical
(26,861 bytes). `docs/QUARTZ_MACHO.md` §3 states the limit that result does
*not* remove.

---

### (o) `16_objc_quartz` — the smallest program in which Objective-C draws
`tests/src/16_objc_quartz.m` · chained · 128×128

`15_quartz` proved the rasteriser under machorun with **no** Objective-C in it.
`09_objc` proved Objective-C under machorun with **no** drawing in it. Neither
proved they compose, and this is the fixture that does: one root class, two
ivars, one `+` constructor, one `-drawInContext:`, two message sends, two
filled ellipses, one PNG.

It is deliberately trivial because its job is to be a **bisection point** for
`17_objc_shapes`. If 17 fails and 16 passes, the bug is in what 17 adds. If 16
fails, nothing about 17's pixel diff is worth reading yet.

Three images, which is one more than anything below rung (n) loads:
`/usr/lib/libquartz.dylib`, `/usr/lib/libobjc.A.dylib`,
`/usr/lib/libSystem.B.dylib`. 19 undefined symbols. Foundation-free, like
`09_objc`: a root class with its own `Class isa`, instances from
`class_createInstance`.

The second blob is drawn through an explicitly cast `objc_msgSend` rather than
bracket syntax, and it is a *different colour and size* on purpose — an
identical second ellipse would leave stage 3's checksum equal to stage 2's, and
a stage that cannot move is a stage that cannot fail.

**Loader must implement:** nothing structurally new over (i) and (n)
*together* — which is the point. It is the first fixture that needs both at
once.

### (p) `17_objc_shapes` — Objective-C in anger, and the milestone
`tests/src/17_objc_shapes.m` · chained · 256×256

The picture is produced by polymorphic message dispatch. Take any one of these
away and the image changes:

| mechanism | where it reaches a pixel |
|---|---|
| protocol | `<Drawable>`: required methods, an `@optional` one, a `readonly` property. The scene loop is typed `id<Drawable>` and by no class |
| root class | `Shape` owns its `Class isa`; no NSObject, no CoreFoundation |
| ivars | declared in the `@interface` braces, plus one the compiler creates for `@property inset` |
| properties | `tag` over an explicit `_tag`, `inset` over a synthesised `_inset`; the category uses dot syntax, i.e. a real accessor send |
| inheritance | `Shape` → `Circle` → `Ring`, three levels |
| `[super …]` | `-[Ring drawInContext:]` — **`objc_msgSendSuper2`, which no other fixture in the corpus imports** |
| subclass ivars | `Vane` adds `_angle` on top of `Shape`'s layout, so non-fragile-ivar `instanceStart` arithmetic is load bearing |
| overriding | four `-drawInContext:` implementations, chosen by the isa pointer |
| category | `Shape (Badge)` adds `-badgeInContext:` to an already-compiled class; every shape gets a badge from it |
| `+load` | six of them (five classes and the category), printed before `main` |
| `+initialize` | inherited from `Shape`, fired lazily, so the print order records **when** each class was first touched — `+initialize Vane` appears between stages 4 and 5 |
| `objc_msgSend` | called through an explicit cast as well as by bracket syntax, including a `QZRect` return |

Sections **no earlier fixture produces**: `__DATA_CONST,__objc_nlclslist`,
`__objc_nlcatlist` (the `+load` non-lazy lists), `__objc_protolist`,
`__DATA,__objc_protorefs` and `__DATA,__objc_superrefs`. New undefined symbols:
`_objc_msgSendSuper2` and `_class_conformsToProtocol`. 36 undefined in total.

Two ABI assertions worth naming, because both are silent when wrong and neither
is caught by an exit status:

* **`QZRect` through `objc_msgSend`.** Four doubles is a homogeneous float
  aggregate, so AAPCS64 returns it in `d0`–`d3`, *not* through the `x8`
  indirect-result register — and arm64 has no `objc_msgSend_stret` to fall back
  to. Stage 4 fetches every shape's `-insetFrame` that way and strokes it, so a
  mistake misplaces every outline. `+shapeWithFrame:tag:` passes one the other
  way, by value.
* **The transcendental.** Stage 5, `-[Vane drawInContext:]`, is the only code
  in the fixture that reaches `cos`/`sin` (`QZContextRotateCTM`). Two vanes at
  two angles, so one lucky argument cannot make it agree by accident. It is in
  its own stage, last, with its own checksum, for the reason `15_quartz`'s
  stage 8 is: see `docs/QUARTZ_MACHO.md` §3.

Six probe pixels are printed after every stage, each aimed at the output of a
*different object* — the plain `Shape`, its category badge, the `Circle`, the
`RoundedBox`, the `Ring`'s annulus (the `[super]` path) and the first `Vane` —
so a single wrong dispatch shows up as a colour and not only as a moved hash.

**Determinism.** No time, no random, no locale-dependent formatting, no
environment, no address is ever printed, and nothing iterates a hash table: the
collection is a fixed-size C array walked in insertion order. Every coordinate
and colour is a literal.

**Loader must implement:** everything at (i) and (n), plus category attachment
and `+load` ordering across classes *and* categories in one image, protocol
metadata, and `objc_msgSendSuper2`.

Measured 2026-08-26: all five stage checksums identical, PNG byte-identical
(11,909 bytes), exit 0 / 0.

### (r) `19_isa_mask` — where the loader PUT things
`tests/src/19_isa_mask.c` · chained · in `tests/manifest.tsv`, graded by `difftest.sh`

The only fixture that tests an address rather than a behaviour, and the only one
whose oracle passes for a reason that is a property of the *platform* rather
than of the program.

libswiftCore has Apple's 47-bit isa mask — `and x8, x8, #0x7ffffffffff8` —
compiled into `swift_getObjectType`, `swift_unknownObjectRetain` and 45 other
places, so a class at or above 2^47 is truncated and the runtime faults on
a pointer it computed itself. aarch64 Linux serves `mmap(NULL, …)` top-down from
near 2^48, so machorun loaded every dylib at `0xffff…`, and every Swift program
that touched a class outside its own executable died. macOS cannot reproduce it:
its user address space is 47 bits, which is exactly why Apple could bake the
mask into a compiler. `docs/MACHO_NOTES.md` §9a has the measurements.

**It prints predicates, never addresses.** macOS has libSystem in the dyld shared
cache and machorun has it in an arena at 8 GiB; those addresses are not
comparable and never will be, but `below_2_47` and `mask_preserves` are. Five
probes, one per image region — `main`, a `__cstring` literal, a `__DATA` global,
and `printf` and `strtod` from libSystem — plus a worked example applying the
mask to a known-bad address, so a reader can see what the failure looks like
without reproducing it.

Stack and heap addresses are deliberately **not** probed. Under machorun those
come from glibc and legitimately sit above 2^47; nothing masks them, and
asserting on them would be inventing a requirement.

**Loader must implement:** a deliberate placement policy, and a loud failure
rather than a fallback when it cannot honour one — `src/map.c`. Verified against
the pre-fix loader: `printf` and `strtod` report `below_2_47=no` there, so the
fixture FAILs, which is the whole reason it exists.

Measured 2026-08-26: stdout byte-identical (285 bytes), exit 0 / 0.

### (q) `18_swift_class` — Swift, and the rung that is graded twice
`tests/src/18_swift_class.swift` · chained · `scripts/swift_gate.sh`

The first fixture whose runtime is the **Swift standard library** rather than
libSystem, libobjc or libquartz. It is deliberately narrow. Everything in it
exists to reach the Swift runtime's per-thread context, because that is the
thing machorun could not do:

| mechanism | why it is here |
|---|---|
| a `final class` with stored properties and a method | class metadata is instantiated lazily on first use, and that path goes through `SwiftTLSContext` |
| a generic function over a user protocol | the witness table for each concrete conformance is built on demand, same path |
| a generic constrained by `Comparable` | forces a conformance lookup the program did not emit itself |
| protocol existentials (`[Shape]`) | the boxed form, as opposed to a witness table passed at the call site |
| a three-level class hierarchy with overrides | vtable dispatch, `Animal` → `Dog` → `Puppy` |
| `is` downcasts | `swift_dynamicCast` against the metadata built above |
| an array of class instances, then `removeAll()` | ARC traffic through the path objc4 routes to `swift_retain` / `swift_release` |
| `as AnyObject` + `type(of:)` on a String and an Array | reaches `__SwiftValue` and the storage classes, which live in **libswiftCore.dylib** rather than in this executable — see rung (r) |

**What used to happen.** Every one of those aborted before `main` with
`tls_init_once() failed to set destructor`. `SwiftTLSContext::get()` adopts
pthread key **100** — Apple's reserved `__PTK_FRAMEWORK_SWIFT_KEY0` — with
`pthread_key_init_np`, and libSystem bound-checked that key against 64. Behind
it sat a second bug that only appeared once the first was fixed: libSystem's
own `swift_release` diagnostic stub won the flat-namespace lookup against the
real one. `docs/UNIMPLEMENTED.md#swift-interop` has both.

**It is graded twice, on purpose.** The gate links the same object file in both
dylib orders — `-lSystem` first and `-lswiftCore` first — and requires both to
pass. The second bug was invisible in the `-lswiftCore`-first order, which is
exactly how it survived long enough to be written down as a load-bearing
workaround. One link order would have graded a fixed loader and a broken one
the same.

**Determinism.** No time, no random, no locale-dependent formatting, no address
printed, and nothing iterates a `Set` or `Dictionary` — every collection walked
is an `Array` in insertion order.

**The one deviation from the corpus rule**, stated because it weakens what a
pass means. Every other fixture is a committed Mach-O built by Apple's
toolchain, and both sides run the same bytes. This one cannot be yet: our
cross-built libswiftCore imports 29 symbols machorun's userland does not carry,
they live in `libswiftcompat.dylib`, and a guest must link that explicitly — so
an Apple-built Swift binary fails to load here (measured;
`docs/UNIMPLEMENTED.md#swift-compat`). Until that closes, the two sides run two
binaries built from one source, and what is compared is the program's behaviour
rather than the loader's handling of one specific set of bytes.

**Loader must implement:** everything at (i), plus a Darwin pthread-key
namespace in which reserved keys are slot indices addressed identically by
`pthread_getspecific` and `_pthread_getspecific_direct`, `pthread_key_init_np`
over the full reserved block, and thread-exit destructors for it.

Measured 2026-08-26: stdout byte-identical (318 bytes), stderr empty on both
sides, exit 0 / 0, in both link orders.

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

### …and the same four, for the drawing fixtures

`scripts/quartz_pixel.sh` grades rungs (n), (o) and (p) from
`tests/draw_manifest.tsv`. It is a separate runner because those fixtures'
headline artefact is a **file** and their macOS run needs `DYLD_LIBRARY_PATH`;
teaching the shared harness either would put a fixture-specific special case
into the thing that grades every other fixture. It obeys the same four rules,
and all four were re-verified on 2026-08-26:

1. `--record` dies with *"only runs on macOS: the baseline is the oracle's"* on
   any non-Darwin host. Verified inside the container: exit 1.
2. The macOS side is **re-executed every run**; the committed baseline is
   compared against it, never substituted for it. That comparison now covers
   `stdout` and the exit status as well as the PNG — see the note below, which
   is what strengthening it found.
3. `tests/expected` is bind-mounted into the container **read-only, on top of**
   the writable `/work` mount (Docker applies binds in destination-path order,
   so the deeper one wins for that subtree). Verified: create, append and
   delete all fail with `Read-only file system`.
4. An oracle that has moved is `BASELINE-DRIFT`, and such a fixture can never
   be scored `PASS` in that run — even if the Linux side matched it byte for
   byte, which is exactly the case rule 2 caught.

**The PNG comparison is exact, and a failure is diagnosable.** Bytes must be
identical; `cmp` alone would then say "differ at byte 4137" and stop, because
everything after the IHDR is deflate-compressed and one wrong pixel moves every
byte downstream. So on a mismatch the runner builds `harness/pngdiff.c` (stb,
already vendored with quartz — nothing is installed on the oracle host) and
prints: the count of differing pixels, **how many differ by more than one level
in any channel**, the bounding box in bitmap coordinates, the largest delta per
channel including alpha, and the first eight differing pixels with both RGBA
values. Zero differing pixels with differing file bytes is itself a finding and
is reported as one — the rasteriser agreed and the *encoder* did not.

The split at ±1 is the first question worth asking: a large count that is
entirely ±1 is a rounding or libm-ulp story, a small count with large deltas is
a wrong shape. Verified by injecting a fault (`Ring`'s hole factor 0.30 → 0.32,
rebuilt with Apple's clang, run through the Linux side against the committed
baseline): `136 of 65536 differing, 132 by >1 level, bounding box x 44..71
y 137..160` — the ring, and nothing else.

> **One correction this strengthening produced, on the day it was written.**
> Rule 2 previously compared only the PNG for `15_quartz`, and
> `tests/expected/15_quartz.stdout` turned out to have been recorded by a hand
> run that passed `oracle.png` as `argv[1]` rather than by `--record`. Its last
> line therefore read `wrote oracle.png` where every harness run on both hosts
> produces `wrote 15_quartz.png`. All nine stage checksums, the exit status and
> the PNG were and are identical on macOS and under machorun; the stale line
> was latent because `--linux` mode is the only mode that reads that file, and
> `both` mode does not. Re-recorded from the macOS oracle through `--record`;
> the PNG bytes did not change.

### …and for rung (q), which is graded by behaviour rather than by bytes

`scripts/swift_gate.sh` grades `18_swift_class`. It is a third runner for one
reason and it is not the artefact: the fixture cannot be a committed
Apple-built Mach-O, because our libswiftCore's compat gap means an Apple-built
Swift binary does not load here at all (`docs/UNIMPLEMENTED.md#swift-compat`).
So the gate BUILDS both sides from one source — Apple's `swiftc` for the
oracle, the swift.org Linux toolchain cross-targeting `arm64-apple-macos` for
the machorun side — and compares what the two programs do.

Rules 1, 2 and 4 hold unchanged: `--record` refuses to run off Darwin, the
oracle is rebuilt and re-executed every run rather than trusted, and an oracle
that has moved is `BASELINE-DRIFT` and can never be scored `PASS`. Rule 3 holds
too — `tests/expected` is bind-mounted read-only over `/work`, same as the
other two runners.

Two things it does that the others do not:

* **It links the fixture twice**, in both dylib orders, and requires both to
  pass. That is not thoroughness for its own sake: the `swift_release`-shadowing
  bug was invisible in the `-lswiftCore`-first order, so a single-order gate
  would have scored a broken loader green. Verified by running the gate against
  the pre-fix loader: `system-first FAIL exit 71`, `swiftcore-first PASS`.
* **It suppresses the implicit `_Concurrency` and `_StringProcessing` imports
  on both sides.** Swift imports those into every file by default; the stdlib
  we cross-build is core-only and has neither. Suppressing them only on the
  Linux side would let the oracle quietly use more standard library than the
  thing it is grading.

Verified 2026-08-26 by building the gate's own failure modes: against the
pre-fix loader both orders `FAIL exit 134` at `tls_init_once`; against a loader
with only the TSD fix, `system-first FAIL exit 71` and `swiftcore-first PASS`;
against the fixed loader, both `PASS`.

## Rebuilding

```
tests/build_fixtures.sh              rebuild everything (macOS only)
tests/build_fixtures.sh 06_tls       rebuild one
harness/run_macos.sh --record        re-record after any rebuild

tests/build_fixtures.sh 15_quartz    also builds the macOS oracle libquartz
tests/build_fixtures.sh 17_objc_shapes   likewise (rungs n, o and p all need it)
scripts/quartz_pixel.sh --record     re-record ALL the drawing fixtures
scripts/quartz_pixel.sh --record 17_objc_shapes   just one (macOS only; PNG too)

scripts/stage_swiftcore.sh           stage the cross-built Swift runtime (rung q)
scripts/swift_gate.sh --record       re-record rung (q)'s baseline (macOS only)
scripts/swift_gate.sh                run both sides and compare
```

Rebuilding produces different bytes (fresh `LC_UUID` and ad-hoc code
signature) even from identical sources. Since the binaries are committed, the
normal state is not to rebuild; if you do, commit the new binaries and the
re-recorded baselines together and say why.
