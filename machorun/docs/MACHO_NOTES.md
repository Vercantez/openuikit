# MACHO_NOTES — arm64 Mach-O as Apple's current toolchain actually emits it

Everything below was **measured**, not recited. Host: macOS 26.5.2 (25F84), Apple
clang 17.0.0 (clang-1700.4.4.1), arm64, SDK MacOSX 26.5, host page size 16384.
Measurement tool: `scripts/machodump.py` (reproduces every hex value quoted here).
Date: 2026-08-25.

The reference binaries were built in a scratch dir with, e.g.:

```sh
SDK=$(xcrun --show-sdk-path)
clang -target arm64-apple-macos14 -isysroot $SDK -o hello hello.c
```

---

## 0. The single most load-bearing measurement: the deployment target picks the fixup format

```
-target arm64-apple-macos11  ->  LC_DYLD_INFO_ONLY        (classic opcode streams)
-target arm64-apple-macos12  ->  LC_DYLD_CHAINED_FIXUPS + LC_DYLD_EXPORTS_TRIE
-target arm64-apple-macos13  ->  chained
-target arm64-apple-macos14  ->  chained
-target arm64-apple-macos15  ->  chained
-target arm64-apple-macos26  ->  chained
no -target at all (defaults to macos26) -> chained
```

`-Wl,-no_fixup_chains` forces the classic form at any deployment target.

**Consequence for the fixture corpus:** the same `.c` compiled at `macos11` vs
`macos14` gives us the two loader code paths for free, from one source file.
This is the cheapest possible differential lever and the fixture ladder should
use it (see PLAN.md, ladder rung F2/F2c).

Everything else in this document is stated for the **chained** form first,
because that is what a default build produces today. The classic form is
documented in §6 because binaries in the wild (and anything targeting macOS 11 /
iOS 14) still use it.

---

## 1. Segment layout

`hello.c` (a `printf` and a loop), `-target arm64-apple-macos14`:

```
LC_SEGMENT_64 __PAGEZERO     vm=0x000000000+0x100000000  file=0+0          prot=0/0    flags=0x0
LC_SEGMENT_64 __TEXT         vm=0x100000000+0x4000       file=0+16384      prot=r-x/r-x flags=0x0
LC_SEGMENT_64 __DATA_CONST   vm=0x100004000+0x4000       file=16384+16384  prot=rw-/rw- flags=0x10 (SG_READ_ONLY)
LC_SEGMENT_64 __LINKEDIT     vm=0x100008000+0x4000       file=32768+664    prot=r--/r-- flags=0x0
```

With globals and initialisers (`ctors.c`) a `__DATA` appears between
`__DATA_CONST` and `__LINKEDIT`:

```
LC_SEGMENT_64 __DATA         vm=0x100008000+0x4000       file=32768+16384  prot=rw-/rw- flags=0x0
LC_SEGMENT_64 __LINKEDIT     vm=0x10000c000+0x4000       file=49152+1048   prot=r--/r--
```

Measured invariants across all eight binaries I built (executables, a dylib, an
ObjC binary, a C++ binary, a 3000-pointer/200 KB-bss binary):

| property | measured value |
|---|---|
| segment `vmaddr` alignment | always a multiple of `0x4000` |
| segment `fileoff` alignment | always a multiple of `0x4000` |
| executable base (`__TEXT.vmaddr`) | `0x100000000` (= `__PAGEZERO.vmsize`) |
| dylib base (`__TEXT.vmaddr`) | `0x0`, no `__PAGEZERO` |
| `mach_header` location | file offset 0, i.e. `__TEXT.vmaddr + 0` |
| `__DATA_CONST` segment flags | `0x10` = `SG_READ_ONLY` |
| `__DATA_CONST` initprot | `rw` (3), **not** `r` — see below |
| pointer format everywhere | `6` = `DYLD_CHAINED_PTR_64_OFFSET` |

**Exception, measured 2026-09-03 on x86_64 (not emitted by this toolchain):**
dylibs extracted from the macOS dyld shared cache (`ipsw dyld extract`) keep
the cache's packing. `libswiftObjectiveC.dylib` `__DATA_CONST vmaddr
0x7ff843287720` — not page-aligned, and the TEXT-to-DATA gap is tens of
megabytes. Apple's `dsc_extractor.bundle` SIGBUSes on macOS 26.5.2 caches, so
these files cannot be rebuilt as standalone dylibs. machorun maps them by
copy (`src/map.c`); the fixtures are `cache_layout_packed` (contiguous
stand-in) and `cache_layout_sparse` (TEXT-to-DATA 0x22256720) — FIXTURES.md g′.

### `__PAGEZERO`

`vmsize = 0x100000000` (4 GiB), `filesize = 0`, `maxprot = initprot = 0`. It is
purely a hole: nothing may be mapped in `[0, 4 GiB)` so that any null/small-int
deref faults. Dylibs have none.

### `__DATA_CONST` and `SG_READ_ONLY`

`initprot` is `rw` so the loader can write fixups into it, and the `SG_READ_ONLY`
segment flag (0x10) tells the loader **to `mprotect` it read-only once fixups are
applied**. This is where `__got`, `__mod_init_func` (classic), `__cfstring`,
`__objc_classlist`, `__objc_imageinfo` live. Losing the mprotect is a hardening
regression, not a correctness one — note it, do it anyway, it is one syscall.

### Zero-fill tails

The 200 KB-bss binary:

```
__DATA  vm=0x100008000+0x3c000  file=32768+32768
   sect __data    addr=0x100008000 size=0x5dc0 off=32768
   sect __common  addr=0x100010000 size=0x30d40 off=0        flags=0x1 (S_ZEROFILL)
```

`vmsize (0x3c000) > filesize (0x8000)`. The tail must be anonymous zero memory.
Also measured: `libgreet.dylib`'s `__DATA` is `file=0+0` with only a `__common`
section — a segment with `filesize == 0` must **not** be `mmap`ed from the file
at offset 0; it is purely anonymous.

### `__LINKEDIT`

`filesize` is not page-rounded (664, 1048, 100992 measured). It contains, in
order: the chained-fixups blob, the exports trie, function starts, data-in-code,
the symbol table, string table, indirect symbol table, and the code signature.
For `hello`: `__LINKEDIT file=32768+664`, and `LC_CODE_SIGNATURE off=33024
size=408` — `33024 + 408 == 32768 + 664`. **The code signature lives inside
`__LINKEDIT`**, so mapping `__LINKEDIT` maps the signature too, at zero cost.

---

## 2. Sections that matter to the loader

Section `flags & SECTION_TYPE` (low 8 bits), measured values:

| section | flags | type | meaning for us |
|---|---|---|---|
| `__TEXT,__text` | `0x80000400` | `S_REGULAR` + `PURE_INSTRUCTIONS\|SOME_INSTRUCTIONS` | code |
| `__TEXT,__stubs` | `0x80000408` | `S_SYMBOL_STUBS` | `reserved2 = 12` (stub size), `reserved1` = indirect-symtab index |
| `__TEXT,__stub_helper` | `0x80000400` | — | **classic only**; absent in chained builds |
| `__TEXT,__init_offsets` | `0x00000016` | `S_INIT_FUNC_OFFSETS` | **modern initialiser list** — see §5 |
| `__TEXT,__cstring` | `0x00000002` | `S_CSTRING_LITERALS` | — |
| `__DATA_CONST,__got` | `0x00000006` | `S_NON_LAZY_SYMBOL_POINTERS` | bind targets |
| `__DATA_CONST,__mod_init_func` | `0x00000009` | `S_MOD_INIT_FUNC_POINTERS` | **classic** initialiser list |
| `__DATA,__la_symbol_ptr` | `0x00000007` | `S_LAZY_SYMBOL_POINTERS` | **classic only** |
| `__DATA,__thread_vars` | `0x00000013` | `S_THREAD_LOCAL_VARIABLES` | TLV descriptors, §7 |
| `__DATA,__thread_data` | `0x00000011` | `S_THREAD_LOCAL_REGULAR` | TLV initial image |
| `__DATA,__thread_bss` | `0x00000012` | `S_THREAD_LOCAL_ZEROFILL` | TLV zero tail |
| `__DATA,__common` | `0x00000001` | `S_ZEROFILL` | bss |
| `__DATA,__objc_selrefs` | `0x10000005` | `S_LITERAL_POINTERS` + `S_ATTR_NO_DEAD_STRIP` | objc |
| `__DATA_CONST,__objc_classlist` | `0x10000000` | `S_REGULAR` + `NO_DEAD_STRIP` | objc |

---

## 3. Entry point: LC_MAIN vs LC_UNIXTHREAD

**Measured, and this is a bigger deal than it looks.**

```
hello_m14:  LC_MAIN entryoff=0x460 stacksize=0x0
nm hello_m14:  0x100000460 (__TEXT,__text) external _main
```

`entryoff` points **directly at `main`**. There is no `start`/`crt1.o` stub in a
modern Mach-O executable — Apple removed it. `ctors_m14`: `entryoff=0x59c`,
`nm` says `_main` is at `0x10000059c`. Same in every executable I built.

Disassembling `_main` in `hello_m14` confirms the calling convention is plain
AAPCS64 — it immediately spills `w0, x1, x2, x3`:

```
100000460: sub  sp, sp, #0x50
100000468: add  x29, sp, #0x40
100000470: stur w0,  [x29, #-0x8]     ; argc
100000474: stur x1,  [x29, #-0x10]    ; argv
100000478: stur x2,  [x29, #-0x18]    ; envp
10000047c: str  x3,  [sp, #0x20]      ; apple
```

So the loader's job at the end is literally:

```c
int rc = ((int(*)(int, char**, char**, char**))(base + entryoff))(argc, argv, envp, apple);
exit(rc);
```

`stacksize` is 0 unless `-Wl,-stack_size` was used; when nonzero it is the main
thread stack size the loader must arrange.

**`LC_UNIXTHREAD` on arm64 is rare but *not* extinct — corrected.** My first pass
claimed the toolchain could not emit one, because my `-target arm64-apple-macos14
-static -nostdlib` attempt failed to link. That conclusion was wrong, and the
fixture corpus disproves it: `tests/bin/exit_unixthread` was built with
`-target arm64-apple-macos11 -nostdlib -e _start -static` and has exactly
`LC_SEGMENT_64`x3, `LC_UNIXTHREAD` (flavor `ARM_THREAD_STATE64`), `LC_SYMTAB`,
`LC_UUID`, `LC_SOURCE_VERSION` — no `LC_LOAD_DYLINKER` at all.

What *is* true, and I re-verified it: **macOS refuses to exec it.** Running
`tests/bin/exit_unixthread` on this Mac gives exit 137 (SIGKILL), because
macOS 11+ on arm64 requires every executable to go through dyld. So there can
be no oracle baseline for it and it can never be graded PASS — it is a
parse-only fixture.

Survey of the real system: `/sbin/launchd` uses `LC_MAIN`; the only
`LC_UNIXTHREAD` arm64 Mach-O shipped by macOS is `/usr/lib/dyld` itself
(arm64e, `cmdsize=288`, all registers zero except `pc`).

**Decision: `LC_MAIN` is the path that matters; parse `LC_UNIXTHREAD` too** —
it is ~20 lines (`flavor`, `count`, `arm_thread_state64_t`, take `pc`) and the
corpus contains a fixture for it. Just do not expect a differential test to
grade it.

---

## 4. Chained fixups — the concrete format

Header at `LC_DYLD_CHAINED_FIXUPS.dataoff`. Measured for `hello_m14`
(`dataoff=32768 datasize=96`):

```
dyld_chained_fixups_header {
  uint32 fixups_version   = 0
  uint32 starts_offset    = 32     // -> dyld_chained_starts_in_image
  uint32 imports_offset   = 80
  uint32 symbols_offset   = 84
  uint32 imports_count    = 1
  uint32 imports_format   = 1      // DYLD_CHAINED_IMPORT
  uint32 symbols_format   = 0      // 0 = uncompressed strings
}
```

All offsets are **relative to the header**, not the file.

### `dyld_chained_starts_in_image` (at header + `starts_offset`)

```
uint32 seg_count               = 4        // == number of LC_SEGMENT_64, in order
uint32 seg_info_offset[4]      = [0,0,24,0]   // 0 == "this segment has no fixups"
```

`seg_count` matches the segment count including `__PAGEZERO` and `__LINKEDIT`;
the array is indexed by segment index, and `0` means skip. For `ctors_m14`
(5 segments) it is `[0,0,24,48,0]` — `__DATA_CONST` and `__DATA`.

### `dyld_chained_starts_in_segment` (at starts_in_image + `seg_info_offset[i]`)

Measured for `hello_m14` `__DATA_CONST`:

```
uint32 size            = 24
uint16 page_size       = 0x4000        // 16 KiB — see §9
uint16 pointer_format  = 6             // DYLD_CHAINED_PTR_64_OFFSET
uint64 segment_offset  = 0x4000        // offset of segment from the IMAGE BASE,
                                       // not a vmaddr and not a file offset
uint32 max_valid_pointer = 0           // only used by 32-bit formats
uint16 page_count      = 1
uint16 page_start[1]   = [0]
```

For the 200 KB binary, `__DATA` gave `page_count=2, page_start=[0,0]`.

`page_start[i]` is the byte offset **within page `i`** of the first chained
pointer on that page.

- `0xFFFF` = `DYLD_CHAINED_PTR_START_NONE` — no fixups on this page, skip it.
- bit `0x8000` set = `DYLD_CHAINED_PTR_START_MULTI` — the value is an index into
  an overflow list of starts that follows `page_start[]`, terminated by an entry
  with `0x8000` set. Only ever needed for 32-bit formats where the 12-bit `next`
  cannot span a page; I did **not** observe it in any arm64 binary and the
  arithmetic below shows why: max reach `4095 * 4 = 16380 < 16384`. A chain
  therefore **never crosses a page boundary** on arm64. Handle MULTI by
  aborting loudly at first, and only implement if a real binary trips it.

### The pointer itself: `DYLD_CHAINED_PTR_64_OFFSET` (format 6)

Every arm64 (non-`arm64e`) binary I measured uses format 6 exclusively. The
64-bit word at the chain position is not a pointer — it is a record:

```
bit 63     : bind      (1 = bind, 0 = rebase)
bits 51-62 : next      (12 bits) — distance to the next link, in units of 4 bytes.
                        next == 0 terminates the chain.

if bind == 1:                          if bind == 0:
  bits  0-23 : ordinal  (24)             bits  0-35 : target   (36)
  bits 24-31 : addend   ( 8)             bits 36-43 : high8    ( 8)
  bits 32-50 : reserved (19)             bits 44-50 : reserved ( 7)
```

`_OFFSET` in the name means **`target` is an offset from the image load
address**, not a vmaddr. (Plain `DYLD_CHAINED_PTR_64`, format 2, stores an
unslid vmaddr instead, and is what dyld-shared-cache-external images use. We
should still implement it — 3 extra lines — because it is trivially different.)

Final stored value:

```
rebase:  *p = load_base + target + ((uint64)high8 << 56)
bind:    *p = resolve(imports[ordinal]) + addend
```

`high8` carries pointer-authentication-adjacent tagging (ObjC tagged pointers,
`__objc` metadata bits). Measured `high8 = 0` in every fixup in every binary I
built, but it must be honoured.

**Verified decodings** (raw word -> meaning, cross-checked against
`xcrun dyld_info -fixups`):

```
ctors_m14 @0x100004000  raw=0x8010000000000000  BIND   ordinal=0 (___cxa_atexit) addend=0 next=2
ctors_m14 @0x100004008  raw=0x8000000000000001  BIND   ordinal=1 (_printf)       addend=0 next=0
ctors_m14 @0x100008008  raw=0x0010000000008000  REBASE target=0x8000 high8=0 next=2
                          ^ this is `int *px = &x;` with _x at 0x100008000, base 0x100000000
ctors_m14 @0x100008010  raw=0x8000000000000001  BIND   ordinal=1 (_printf) next=0
                          ^ this is `int (*pf)(...) = printf;`
big       __DATA         page_count=2, page_start=[0,0]  (one chain per page, as predicted)
```

`next=2` means the next link is 8 bytes on; `next=6` means 24 bytes on
(observed in `__thread_vars`, whose descriptors are 24 bytes).

### Walking a chain

```
for each segment i with seg_info_offset[i] != 0:
    for page in 0 .. page_count-1:
        s = page_start[page]
        if s == 0xFFFF: continue
        p = load_base + segment_offset + page*page_size + s
        loop:
            raw = *p
            apply(raw, p)
            if next(raw) == 0: break
            p += next(raw) * 4
```

Note the walk is over **mapped memory**, after the segments are in place, and it
writes in place. It needs `__DATA_CONST` to still be writable — hence
`initprot=rw` plus the `SG_READ_ONLY` mprotect afterwards.

### Imports (at header + `imports_offset`), format 1 = `DYLD_CHAINED_IMPORT`

One `uint32` per import:

```
bits  0-7  : lib_ordinal    (1-based index into the LC_LOAD_DYLIB commands,
                             in load-command order; 0 = this-image,
                             0xFE = weak lookup, 0xFF = flat lookup)
bit   8    : weak_import
bits  9-31 : name_offset    (from header + symbols_offset, NUL-terminated)
```

Measured `usegreet_m14` (`LC_LOAD_DYLIB` order: `@rpath/libgreet.dylib`, then
`/usr/lib/libSystem.B.dylib`):

```
import[0]: lib_ordinal=1 weak=0 name=_greet        -> libgreet
import[1]: lib_ordinal=1 weak=0 name=_greet_count  -> libgreet   (a DATA symbol via __got)
import[2]: lib_ordinal=2 weak=0 name=_printf       -> libSystem
```

Formats 2 (`_ADDEND`, adds an `int32` addend field) and 3 (`_ADDEND64`) exist;
I never saw them emitted for these inputs. Abort loudly on them until observed.

### The big win: chained fixups delete lazy binding

`hello` (macos11, classic) has `__TEXT,__stub_helper` and `__DATA,__la_symbol_ptr`,
and binds `dyld_stub_binder`. `hello_m14` (chained) has **neither**, and its
stub is:

```
__TEXT,__stubs:
  10000052c: adrp x16, 4        ; -> 0x100004000  (__DATA_CONST,__got)
  100000530: ldr  x16, [x16]
  100000534: br   x16
```

The stub reads `__got` directly. `__got` was bound eagerly by the chain walk.
**`dyld_stub_binder` is not referenced at all by a chained-fixups binary.**
That removes an entire hard subsystem from the milestone-1 loader.

---

## 5. Initialisers

Two forms, and the modern one is *not* `__mod_init_func`.

### Modern: `__TEXT,__init_offsets` (`S_INIT_FUNC_OFFSETS`, flags `0x16`)

`ctors_m14`:

```
__TEXT,__init_offsets  addr=0x100000634 size=0xc
contents: 00000548 00000564 000005f4      (three uint32 LE)

nm:  0x100000548 t _c1
     0x100000564 t _c2
     0x1000005f4 t ___GLOBAL_init_65535
```

They are **32-bit offsets from the mach_header**, not pointers. Consequences:
the section lives in read-only `__TEXT`, needs **no rebase**, and cannot be
overwritten by an attacker. Call order is array order.

Observed order: `_c1` (`constructor(101)`), `_c2` (`constructor(102)`), then
`___GLOBAL_init_65535` (the default-priority group, which is where `__cxa_atexit`
registration for the C++/`destructor` machinery lands). So the linker has already
sorted by priority — **the loader must not re-sort, just walk the array**.

Oracle output of `./ctors`:

```
ctor1
ctor2
main 7 0x18ef9497c
dtor1
```

(`dtor1` runs at exit via `__cxa_atexit`, which is an import — so our libSystem
owns atexit ordering, not the loader.)

### Classic: `__DATA_CONST,__mod_init_func` (`S_MOD_INIT_FUNC_POINTERS`, flags `0x9`)

`ctors` (macos11): three 8-byte pointers at `0x100004008`, each with a **rebase**
fixup. Confirmed by the classic rebase opcode stream (§6).

### Ordering across images

dyld runs initialisers **depth-first, dependencies before dependents**. Measured
with `usegreet` (an executable linking `libgreet.dylib`, which has a constructor):

```
libgreet init          <- dylib initialiser
greet a 1              <- main
greet b 2
count=2
```

So: for each image in dependency order (leaf-first), run its initialisers, then
the main executable's, then call `main`. Cycles are broken by marking an image
"initialising" and not recursing into it again.

---

## 6. Classic `LC_DYLD_INFO_ONLY` opcode streams

`ctors` (macos11): `rebase=49152+16 bind=49168+40 lazy=49208+40 export=49248+72`.
Raw bytes, decoded by hand and cross-checked against `xcrun dyld_info -fixups`:

### Rebase stream (16 bytes)

```
11 22 08 53 23 00 52 41 51 00 00 00 00 00 00 00

11  REBASE_OPCODE_SET_TYPE_IMM(0x10) | 1           -> REBASE_TYPE_POINTER
22  SET_SEGMENT_AND_OFFSET_ULEB(0x20) | seg=2, uleb 0x08   -> 0x100004008 (__mod_init_func)
53  DO_REBASE_IMM_TIMES(0x50) | 3                  -> rebase 3 pointers, advance 24
23  SET_SEGMENT_AND_OFFSET_ULEB | seg=3, uleb 0x00 -> 0x100008000 (__la_symbol_ptr)
52  DO_REBASE_IMM_TIMES | 2                        -> 2 pointers
41  ADD_ADDR_IMM_SCALED(0x40) | 1                  -> advance 1*8 = 8   -> 0x100008018
51  DO_REBASE_IMM_TIMES | 1                        -> 1 pointer (_px = &_x)
00  REBASE_OPCODE_DONE
```

A rebase adds the slide to the pointer already stored in the file.

### Bind stream (40 bytes)

```
11 40 '_printf\0' 51 73 20 90 40 'dyld_stub_binder\0' 72 00 90 00

11  BIND_OPCODE_SET_DYLIB_ORDINAL_IMM(0x10) | 1     -> libSystem
40  SET_SYMBOL_TRAILING_FLAGS_IMM(0x40) | flags=0   -> "_printf"
51  SET_TYPE_IMM(0x50) | 1                          -> BIND_TYPE_POINTER
73  SET_SEGMENT_AND_OFFSET_ULEB(0x70) | seg=3, uleb 0x20 -> 0x100008020
90  DO_BIND
40  ... "dyld_stub_binder"
72  seg=2, uleb 0x00                                -> 0x100004000 (__got)
90  DO_BIND
00  BIND_OPCODE_DONE
```

### Lazy bind stream (40 bytes)

```
73 00  11  40 '___cxa_atexit\0' 90 00
73 08  11  40 '_printf\0'       90 00
```

Each lazy entry is a self-contained mini-program terminated by `DONE`. The
`__stub_helper` entry for a symbol pushes the **byte offset of that entry within
the lazy stream** and jumps to the common helper, which loads
`dyld_stub_binder` from `__got` and branches to it. Measured `__stub_helper`:

```
100000690: adrp x17, 8 ; add x17, #0x8      ; -> 0x100008008 (the la_symbol_ptr)
100000698: stp  x16, x17, [sp, #-0x10]!
10000069c: adrp x16, 4 ; ldr x16, [x16]     ; -> dyld_stub_binder from __got
1000006a4: br   x16
1000006a8: ldr  w16, 0x1000006b0            ; per-symbol lazy-stream offset
1000006ac: b    0x100000690
1000006b0: .long 0                          ; <- the offset (0 for ___cxa_atexit)
```

**Design shortcut worth taking:** for classic binaries we do not have to
implement lazy binding at all. The lazy stream describes exactly the same set of
bindings as the lazy pointers; we can **bind all lazy entries eagerly at load
time** and never provide a working `dyld_stub_binder`. Downside: no lazy-resolve
latency win (irrelevant), and no `DYLD_BIND_AT_LAUNCH`-style symbol-not-found
deferral (fixtures should not depend on that). We must still *bind* the
`dyld_stub_binder` GOT slot to something, because the classic bind stream asks
for it; bind it to a stub in our libSystem that `abort()`s with a clear message —
if it is ever entered, we have a bug, and we will know immediately.

### Export trie (`LC_DYLD_EXPORTS_TRIE` in modern builds; `export_off` in classic)

Raw for `libgreet_m14.dylib` (`dataoff=32864 datasize=40`):

```
00 01 5f 67 72 65 65 74 00 14 | 00 00 00 00 04 00 80 80 02 | 00 03 00 f8 09 |
01 5f 63 6f 75 6e 74 00 0e | 00 00 00 00 00 00 00
```

Decoded:

```
node@0:  terminal_size=0, child_count=1, edge="_greet" -> child at +0x14
node@20: terminal_size=4 { flags=0 (uleb), address=0x4f8 (uleb) }, child_count=1,
         edge="_count" -> child at +0x0e
node@14: terminal_size=... { flags=0, address=0x8000 }, child_count=0
```

i.e. `_greet @ 0x4f8` and `_greet_count @ 0x8000`, both offsets from the image
base. Structure per node:

```
uleb terminal_size
  if terminal_size:  uleb flags; then payload depending on flags:
     EXPORT_SYMBOL_FLAGS_REEXPORT (0x08)       : uleb ordinal, cstring importedName
     EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER(0x10): uleb stubOffset, uleb resolverOffset
     otherwise                                  : uleb address (image-base-relative)
  (skip terminal_size bytes from after the terminal_size uleb)
uint8 child_count
  child_count x { cstring edge_substring; uleb child_node_offset_from_trie_start }
```

Note the shared-prefix compression: `_greet` and `_greet_count` share a node.
A naive "walk the trie collecting all names" is fine for us (our dylibs are
small); the fast path is prefix-matching a lookup name against edges.

---

## 7. TLS / thread-local variables

`tls.c`: `__thread int t1 = 5; _Thread_local long t2;`

```
mach_header flags = 0xa00085
  0x000001 MH_NOUNDEFS  0x000004 MH_DYLDLINK  0x000080 MH_TWOLEVEL
  0x200000 MH_PIE       0x800000 MH_HAS_TLV_DESCRIPTORS   <- the tell

__DATA,__thread_vars  addr=0x100008000 size=0x30  flags=0x13 (S_THREAD_LOCAL_VARIABLES)
__DATA,__thread_data  addr=0x100008030 size=0x04  flags=0x11 (S_THREAD_LOCAL_REGULAR)
__DATA,__thread_bss   addr=0x100008038 size=0x08  flags=0x12 (S_THREAD_LOCAL_ZEROFILL)

nm: 0x100008000 _t1              (__DATA,__thread_vars)
    0x100008030 _t1$tlv$init     (__DATA,__thread_data)
    0x100008018 _t2              (__DATA,__thread_vars)
    0x100008038 _t2$tlv$init     (__DATA,__thread_bss)

imports: _printf, __tlv_bootstrap     (both from libSystem)
```

### The descriptor

24 bytes, three words. Raw contents (still chained, unrelocated):

```
_t1 @0x100008000:  [0] 0x8030000000000001  -> BIND ordinal=1 (__tlv_bootstrap), next=6
                   [1] 0x0000000000000000  -> key
                   [2] 0x0000000000000000  -> offset
_t2 @0x100008018:  [0] 0x8000000000000001  -> BIND ordinal=1 (__tlv_bootstrap), next=0
                   [1] 0x0000000000000000  -> key
                   [2] 0x0000000000000008  -> offset
```

```c
struct tlv_descriptor {
    void*    (*thunk)(struct tlv_descriptor*);  // bound to __tlv_bootstrap
    unsigned long key;                          // pthread key, filled in by the loader
    unsigned long offset;                       // byte offset into the image's TLV block
};
```

`_t1.offset = 0` and `_t2.offset = 8`, and `__thread_data` starts at `0x8030`
with `__thread_bss` immediately after at `0x8038`. So **the per-thread block is
the concatenation `[__thread_data || __thread_bss]`**, the template for the
`__thread_data` part is in the file, the `__thread_bss` part is zero, and
`offset` indexes into that block.

### The access sequence

Disassembly of `main` in `tls_m14`:

```
1000005b0: adrp x0, 8 ; add x0, x0, #0x0     ; x0 = &descriptor for _t1
1000005b8: ldr  x8, [x0]                     ; x8 = descriptor->thunk
1000005bc: blr  x8                           ; returns &t1-for-this-thread in x0
1000005c4: ldr  w8, [x0]
...
1000005d4: adrp x0, 8 ; add x0, x0, #0x18    ; x0 = &descriptor for _t2
1000005dc: ldr  x8, [x0]
1000005e0: blr  x8
```

The ABI is: **`x0` in = descriptor address, `x0` out = the variable's address for
the calling thread; all other registers preserved** (this is why real
implementations write it in assembly — the C compiler will clobber more than the
contract allows if the slow path is inlined).

### What the loader has to do

1. Note `MH_HAS_TLV_DESCRIPTORS`, find `__thread_vars` / `__thread_data` /
   `__thread_bss`.
2. Register a per-image TLV template: `{ file_bytes_of___thread_data,
   thread_data_size, thread_bss_size }`, and get a `pthread_key_t` for it
   (`pthread_key_create` with a destructor that frees the block).
3. Walk `__thread_vars` in 24-byte strides and for each descriptor write
   `thunk = tlv_get_addr` (our implementation) and `key = the image's key`.
   The `offset` field already holds the right value from the file.

Step 3 is the pragmatic choice: it means the `__tlv_bootstrap` bind can be
satisfied by any placeholder (we overwrite it), and there is no lazy
first-touch bootstrap to get right. The alternative — export a real
`__tlv_bootstrap` that self-installs on first call — is what dyld does and can
come later if `dlopen` forces it.

`tlv_get_addr(desc)` in our libSystem is then:

```
block = pthread_getspecific(desc->key)
if (!block) block = allocate_and_init_from_template(desc->key), pthread_setspecific
return block + desc->offset
```

C++ `thread_local` with non-trivial constructors/destructors adds
`_tlv_atexit` / `__cxa_thread_atexit` on top. Not in the milestone-1 fixtures;
record in UNIMPLEMENTED.md and abort loudly.

Oracle: `./tlsbin` prints `5 6`.

---

## 8. Dylibs, install names, `@rpath`

`libgreet.dylib` built with `-install_name @rpath/libgreet.dylib`:

```
filetype=6 (MH_DYLIB)  flags=0x100085 (MH_NOUNDEFS|MH_DYLDLINK|MH_TWOLEVEL|MH_NO_REEXPORTED_DYLIBS)
no __PAGEZERO;  __TEXT.vmaddr = 0x0
LC_ID_DYLIB  @rpath/libgreet.dylib
```

The consumer `usegreet_m14`:

```
LC_LOAD_DYLIB  @rpath/libgreet.dylib
LC_LOAD_DYLIB  /usr/lib/libSystem.B.dylib
LC_RPATH       @executable_path
```

Load-command payloads are `{ uint32 cmd; uint32 cmdsize; uint32 name_offset; ... }`
with the string inline at `cmd_start + name_offset`, NUL-terminated, padded to
`cmdsize`.

**Path expansion rules the loader must implement** (in this order, for each
`LC_LOAD_DYLIB` path):

| prefix | expands to |
|---|---|
| `@executable_path/` | dirname of the main executable |
| `@loader_path/` | dirname of the image containing this `LC_LOAD_DYLIB` |
| `@rpath/` | try each `LC_RPATH` of the loading image, then of the main executable, in order; each `LC_RPATH` may itself start with `@executable_path`/`@loader_path` |
| absolute (`/usr/lib/...`) | **redirect into our own darwin/ tree** — see below |

**The same rules apply to a `dlopen` path, with "the image containing this
`LC_LOAD_DYLIB`" read as "the image that called `dlopen`".** That is not a
restatement: it is a different image, discoverable only from the caller's
return address, and getting it wrong is silent — see `tests/bin/loader_path`
and `docs/FIXTURES.md` rung (ai). `@executable_path` still means the main
executable in both cases, which is the only reason the two spellings differ.

The redirect is the entire point of the project. `/usr/lib/libSystem.B.dylib`
does not exist on Linux and, notably, **does not exist as a file on macOS
either** (`ls /usr/lib/libSystem.B.dylib` -> no such file; it lives only in the
dyld shared cache). So there is no "fall back to the real thing" temptation:
a prefix-map from Darwin absolute paths to `$MACHORUN_ROOT/darwin/...` is the
only resolution strategy, and it is honest.

Ordinal numbering for binds: `lib_ordinal` is the **1-based index of the
`LC_LOAD_DYLIB`-family command in load-command order**, counting
`LC_LOAD_DYLIB`, `LC_LOAD_WEAK_DYLIB`, `LC_REEXPORT_DYLIB`,
`LC_LOAD_UPWARD_DYLIB`, `LC_LAZY_LOAD_DYLIB` together. Verified against
`usegreet_m14` above. Special values: `0` = `BIND_SPECIAL_DYLIB_SELF`,
`-1/0xFF` = flat lookup, `-2/0xFE` = weak lookup (bind to 0 if missing).

Two-level namespace (`MH_TWOLEVEL`, set on everything measured) means a bind
must be resolved **in the named dylib and its re-exports only**, not by a global
search. Re-exports matter a lot for us: real `libSystem.B.dylib` re-exports ~40
`/usr/lib/system/*.dylib`. Our replacement can be a single flat dylib exporting
everything, which sidesteps re-export chasing for milestone 1 — but
`LC_REEXPORT_DYLIB` support is still needed the moment we ship
`Foundation` -> `CoreFoundation`-style splits.

`dlopen`/`dlsym`/`dlclose`/`dlerror` are ordinary imports from libSystem
(measured), so `dlopen` is *our* function and it re-enters *our* loader. Design
the loader as a library with a re-entrant `image_load(path)` from day one.

---

## 9. Page size: 16K Mach-O vs 4K Linux

This is the item the brief singles out, so here are the actual numbers.

**Measured, macOS side:** every segment `vmaddr` and `fileoff` in every binary I
built is a multiple of `0x4000` (16 KiB). `__TEXT` is at `base+0`, `__DATA_CONST`
at `base+0x4000`, `__DATA` at `base+0x8000`.

**Measured, Linux side** (arm64 container, native, no emulation):

```
$ docker run --rm --platform linux/arm64 ubuntu:24.04 sh -c \
    'getconf PAGESIZE; uname -m; uname -r; cat /proc/sys/vm/mmap_min_addr; cat /proc/sys/vm/overcommit_memory'
4096
aarch64
6.12.76-linuxkit
32768
1
```

**Can Apple's toolchain emit something with 4K segments?** I tried:

```
clang -target arm64-apple-macos14 -Wl,-segalign,0x1000 -o hello_4k hello.c
  -> links fine, produces __TEXT@+0x1000, __DATA_CONST@+0x1000,
     chained starts_in_segment page_size = 0x1000
  -> ./hello_4k  =>  exit 137 (SIGKILL)
```

**macOS itself refuses to run it.** arm64 macOS requires 16 KiB segment
alignment. So a Mach-O that runs on the oracle is *always* ≥16K-aligned.

Cache-extracted dylibs are the other side of that fact: they do **not** run
on the oracle (dyld SIGKILLs unaligned segments) and they are still files
the loader has to map. See the §1 exception and FIXTURES.md (g′).

### What this means

- **16K-aligned segments on a 4K-page Linux: no problem.** 16384 is a multiple
  of 4096, so `mmap(MAP_FIXED, len, off)` with 16K-aligned `addr` and `off` is
  legal, and `mprotect` at 16K boundaries is exact. **This is the common case
  and it is free.**
- The chained-fixups `page_size` field (`0x4000`) is a property of the *tables*,
  not of `mmap`. The chain walk iterates in 16 KiB steps regardless of what the
  kernel's page size is. Do not conflate the two — this is the easiest bug to
  write here.
- **The reverse case is the real hazard: a 64 KiB-page Linux kernel.** RHEL /
  CentOS Stream on aarch64, and several Ampere/server distros, ship
  `CONFIG_ARM64_64K_PAGES`. There, `mmap` `addr`/`offset` must be 64K-aligned,
  and 16K-aligned segments cannot be placed. Worse — and this is the part that
  is not just an alignment fix — `__TEXT` (`r-x`) at `base+0` and `__DATA_CONST`
  (`rw-`) at `base+0x4000` land in the **same 64 KiB page**, so they physically
  cannot be given different protections.

  Mitigation ladder, cheapest first:
  1. Detect `sysconf(_SC_PAGESIZE) > 0x4000` at startup and **refuse with a
     clear message** naming the kernel page size. (Milestone-1 answer.)
  2. Fall back to `mmap` one anonymous RW region for the whole image and
     `pread` each segment's file bytes into it, then `mprotect` at 64K
     granularity with the **union** of the protections of the segments in each
     64K page (so `__TEXT`+`__DATA_CONST` become `rwx`). Correct, loses W^X,
     loses page-cache sharing. Perfectly acceptable as a compatibility path.
  3. There is no option 3. Do not try to relocate segments apart.

  Risk assessment: **nuisance, not blocker**, because our own CI target
  (Ubuntu arm64 on Docker Desktop, measured 4096) is 4K, and mitigation 2 is
  maybe 60 lines. But it must be detected explicitly rather than silently
  producing a broken mapping.

### `__PAGEZERO` on Linux

`vm.mmap_min_addr = 32768`, so we cannot map from address 0. Plan:

- Reserve `[65536, 0x100000000)` with
  `mmap(PROT_NONE, MAP_PRIVATE|MAP_ANONYMOUS|MAP_NORESERVE|MAP_FIXED_NOREPLACE)`.
  4 GiB of PROT_NONE VA costs nothing in RSS; `overcommit_memory=1` measured, and
  `MAP_NORESERVE` covers the strict-overcommit case.
- The bottom 32 KiB stays unmapped by the kernel anyway, which gives us the
  null-deref-faults property we actually wanted.
- **`machorun` itself must be built PIE** so the Linux loader places it high
  (aarch64 PIE base is well above 4 GiB) and it never collides with the
  reservation. A non-PIE ELF links at `0x400000`, inside `__PAGEZERO`. Assert
  this at startup by checking our own `&main` is above 4 GiB.

### Slide

Preferred base is `0x100000000` for executables. Try `MAP_FIXED_NOREPLACE` there
first: **slide = 0** is the simplest possible case and everything (chained
`_OFFSET` targets, `__init_offsets`, exports-trie addresses) is already
image-base-relative, so slide costs nothing. If the address is taken, pick any
16K-aligned base and set `slide = actual_base - preferred_base`. Dylibs have
preferred base 0, so they are always slid.

For milestone 1, load at the preferred base and record ASLR as a later
hardening step — but write every fixup as `load_base + x`, never
`preferred_base + x`, so slide is correct by construction from day one.

### 9a. Where a slid image may be placed — the 47-bit ceiling

**Added 2026-08-26.** The advice above says nothing about *where* a slid image
goes, because until Swift ran here nothing cared. Something does now, and it is
not negotiable.

Apple's arm64 runtimes pack flags into an object's isa field and mask them off
before dereferencing it. The Swift standard library does **not** call a function
to do that — the mask is compiled in:

```
$ objdump --macho -d libswiftCore.dylib | grep -c 'and.*#0x7ffffffffff8'
48           including inside swift_getObjectType, swift_unknownObjectRetain,
             swift_unknownObjectRelease and the dynamic-cast machinery
```

`0x00007ffffffffff8` keeps bits 3..46. An image at or above 2^47 therefore has
its class pointers **silently truncated**, and the runtime faults on an address
it computed itself, inside libswiftCore, with a fault address that reads like
heap corruption.

That is exactly what aarch64 Linux produced. `mmap(NULL, …)` is served top-down
from near 2^48, so, measured before the fix:

| image | load base | after `& 0x7ffffffffff8` |
|---|---|---|
| the executable | `0x100000000` | unchanged — safe, by luck of the preferred base |
| `libSystem.B.dylib` | `0xffff9413e000` | `0x7fff9413e000` — **bit 47 gone** |
| `libswiftCore.dylib` | `0xffff92d54000` | `0x7fff92d54000` — **bit 47 gone** |

A Swift program reaching any class in a **dylib** — every stdlib, Foundation and
UIKit class — died with `SIGSEGV in libswiftCore+0x332898, fault address
0x7fff8a2c6010`, the truncation of a real class at `0xffff8a2c6010`. Programs
whose classes were all in the executable ran fine, which is how this survived
the first Swift fixture.

**macOS never has the problem**: its user address space is 47 bits. That is *why*
Apple could bake the mask into a compiler.

objc4 is unaffected here only because `patches-macho/0001` widens it to the
52-bit arm64e `shiftcls` layout. libswiftCore cannot be treated the same way —
the mask is in compiled code in many places, and a private mask would fork the
standard library from upstream permanently. So the loader meets Swift where it
is.

`src/map.c` now places images itself, from an arena at 8 GiB walking up with
`MAP_FIXED_NOREPLACE`, and **fails loudly** rather than falling back to
`mmap(NULL, …)`: a fallback would trade a clear error here for a segfault inside
the standard library later. The preferred base is honoured only when it also
satisfies the ceiling.

`ulimit -s unlimited` also makes the symptom disappear — it flips Linux to the
legacy bottom-up mmap layout process-wide — and is worth writing down because it
is what someone bisecting this will stumble onto. It is not a fix: it is a
property of how machorun was invoked, it lapses across a re-exec, and it moves
every unrelated allocation too.

`tests/bin/isa_mask` (rung r) asserts the invariant on both hosts, and
section (4) of `swift_class` asserts that Swift survives it — one is *where*,
the other is *whether*. Verified against the pre-fix loader: `printf` and
`strtod` report `below_2_47=no` there and `yes` on macOS, so difftest fails.

---

## 10. `LC_CODE_SIGNATURE` — what if we ignore it?

`hello_m14`: `LC_CODE_SIGNATURE off=33024 size=408`, and `codesign -dvvv` says
`flags=0x20002(adhoc,linker-signed)`, `hashes=9+0`, sha256, `CDHash=5155...`.
The linker ad-hoc-signs every arm64 binary automatically.

Measured behaviour:

- `codesign --remove-signature hello_m14` -> still runs on macOS (`hello 1`),
  but `apple[]` loses the `executable_cdhash=` and `executable_boothash=`
  entries.
- Flipping a byte inside `__TEXT` padding -> still runs on macOS.

**On Linux there is nothing to do.** The signature is a blob inside `__LINKEDIT`
which we already map and never look at. The kernel doing the enforcement is
XNU's AMFI; Linux has no such thing. Cost of ignoring: zero.

The only leakage is `apple[]`: whether `executable_cdhash` / `executable_boothash`
appear depends on signing state. **Fixtures must not assert on `apple[]` beyond
`apple[0]`** — I measured the entry count changing from 12 to 10 purely by
stripping the signature.

---

## 11. `apple[]` and the entry environment

Measured on macOS by having `main` print its fourth argument:

```
apple[0]=executable_path=./hello        <- exactly as invoked, not resolved
apple[1]=
apple[2]=
apple[3]=
apple[4]=ptr_munge=
apple[5]=main_stack=
apple[6]=executable_file=0x1a01000011,0x103db89c     <- fsid,inode
apple[7]=dyld_file=0x1a01000011,0xfffffff000a955c
apple[8]=executable_cdhash=e8a02af688c40c851f3485fe4113fce904bb2cee
apple[9]=executable_boothash=cf8f4107aa8fad7bce79d7c147fc5e57992f8131
apple[10]=th_port=
apple[11]=security_config=0x0
```

NUL-terminated `char*` array, `key=value` strings, terminated by a NULL pointer.
Note apple[1..3] are empty strings, not absent — the slots exist.

Consumers in the real world: `_NSGetExecutablePath` and CoreFoundation's main
bundle read `executable_path=`; libpthread reads `ptr_munge=` and `main_stack=`;
libmalloc reads `MallocNanoZone`-ish config; `th_port=` is the main thread's
mach port. **All of those consumers are code we are replacing**, so we choose
what we need.

Loader plan: synthesise

```
apple[0] = "executable_path=<argv[0] as given>"
apple[1] = NULL
```

and grow only when a fixture demands it. `argv`/`envp` are passed straight
through from the Linux process. `environ`, `_NSGetArgc/_NSGetArgv/_NSGetEnviron`
and `__progname` are libSystem state, so the loader must call a private
bootstrap entry point in our libSystem (`__machorun_libsystem_bootstrap(argc,
argv, envp, apple)`) **before** running any initialiser.

---

## 12. What the fixtures actually import

Derived from `nm -u` on binaries I built (chained, macos14):

| fixture | undefined symbols |
|---|---|
| `hello.c` | `_printf` |
| `ctors.c` | `_printf`, `___cxa_atexit` |
| `tls.c` | `_printf`, `__tlv_bootstrap` |
| `libgreet.dylib` | `_printf` |
| `usegreet.c` | `_greet`, `_greet_count`, `_printf` |
| `dl.c` (dlopen) | `_dlopen`, `_dlsym`, `_dlclose`, `_dlerror`, `_printf` |
| `wide.c` (malloc/pthread/mmap/stdio/time) | `_malloc`, `_free`, `_printf`, `_fprintf`, `___stderrp`, `_strlen`, `___strcpy_chk`, `_pthread_create`, `_pthread_join`, `_mmap`, `_munmap`, `_getpid`, `_time` |
| `cpp.cpp` (libc++, exceptions) | `_printf`, `_strlen`, `___stack_chk_fail`, `___stack_chk_guard`, `___cxa_atexit`, `___cxa_throw`, `___cxa_begin_catch`, `___cxa_end_catch`, `___cxa_allocate_exception`, `___cxa_free_exception`, `___gxx_personality_v0`, `__Unwind_Resume`, `__Znwm`, `__ZdlPv`, `__ZTIi`, several `std::__1::basic_string` symbols, `__ZSt9terminatev` (from `/usr/lib/libc++.1.dylib` + libSystem) |
| `objcbin.m` (Foundation) | `_objc_msgSend`, `_objc_opt_new`, `_objc_retain`, `_objc_retainAutorelease`, `_objc_storeStrong`, `_objc_autoreleasePoolPush/Pop`, `__objc_empty_cache`, `_OBJC_CLASS_$_NSObject`, `_OBJC_METACLASS_$_NSObject`, `_OBJC_CLASS_$_NSConstantArray`, `_OBJC_CLASS_$_NSConstantIntegerNumber`, `___CFConstantStringClassReference`, `_printf` |

Two observations that shape the libSystem design:

1. **The tail is short and the head is boring.** A `hello world` needs exactly
   one symbol. Even a fixture that touches malloc, pthreads, mmap, stdio and
   time needs 13, of which 12 are a `#define` away from glibc.
2. **Data imports are real.** `___stderrp` (a `FILE**`), `___stack_chk_guard`,
   `__objc_empty_cache`, `_OBJC_CLASS_$_NSObject` are all *data* binds through
   `__got`. Our dylibs must export data symbols, not just functions, and our
   symbol-resolution path must not assume "an import is a function".
3. `___strcpy_chk` and `___stack_chk_fail/guard` come from the compiler's
   fortify/stack-protector lowering, not from anything the user wrote. They will
   show up in almost every non-trivial fixture; put them in the first cut.

### The Darwin `_` prefix

Every Mach-O symbol carries a leading underscore that ELF does not. `_printf` in
Mach-O is `printf` in glibc. **The forwarding layer must strip exactly one
leading underscore** — and note the collisions: `__tlv_bootstrap` (Mach-O) is
`_tlv_bootstrap`, and `___cxa_atexit` is `__cxa_atexit`. Get this wrong once and
half the symbol table silently misses.

---

## 13. ObjC image registration (what `objcbin` implies)

`objcbin` has `__DATA_CONST,__objc_imageinfo`, `__objc_classlist`,
`__DATA,__objc_selrefs`, `__objc_classrefs`, `__objc_data`, `__objc_const`, and
`__TEXT,__objc_stubs`/`__objc_methlist`/`__objc_methname`/`__objc_classname`.
Chained fixups already rebase/bind all of the pointers inside them.

What fixups *cannot* do is the runtime work: registering classes into the
runtime's class table, uniquing selectors in `__objc_selrefs`, attaching
categories, fixing up `__objc_classrefs` to the canonical class objects. That is
`libobjc`'s `map_images`.

The mechanism is a callback registration: `libobjc`'s initialiser calls
`_dyld_objc_register_callbacks` (modern) / `_dyld_objc_notify_register`
(older), handing dyld `{ mapped, init, unmapped }` (plus `patch_class` and
`mapped2` in newer versions), and dyld calls `mapped(count, paths[], mhdrs[])`
whenever images with ObjC content appear. **Our loader must provide those
symbols from our libSystem and drive the callbacks.** This is a small,
well-defined interface — but its exact shape is version-coupled to whichever
`libobjc` we ship, and `~/objc4-linux` is currently an ELF build, so a Mach-O
rebuild is a prerequisite. Treat the ABI shape as an open question to be
*measured* against our own objc4 source rather than assumed.

Ordering constraint: `mapped` must run **before** any `+load` and before the
image's own C initialisers, since `+load` is dispatched from inside `map_images`.

---

## 14. Load commands: the full triage list

Measured across all binaries. `!` = must implement for milestone 1.

| command | value | action |
|---|---|---|
| `LC_SEGMENT_64` | `0x19` | ! map |
| `LC_DYLD_CHAINED_FIXUPS` | `0x80000034` | ! apply |
| `LC_DYLD_EXPORTS_TRIE` | `0x80000033` | ! for dylibs we load |
| `LC_DYLD_INFO_ONLY` | `0x80000022` | ! classic path |
| `LC_SYMTAB` | `0x02` | needed for `dlsym` fallback / diagnostics; not for binding |
| `LC_DYSYMTAB` | `0x0b` | indirect symbol table; only needed if we ever rewrite stubs |
| `LC_LOAD_DYLIB` | `0x0c` | ! resolve + load |
| `LC_LOAD_WEAK_DYLIB` | `0x80000018` | ! load; missing is OK, binds become 0 |
| `LC_REEXPORT_DYLIB` | `0x8000001f` | needed once we split frameworks |
| `LC_ID_DYLIB` | `0x0d` | ! identity for dedup |
| `LC_RPATH` | `0x8000001c` | ! `@rpath` expansion |
| `LC_LOAD_DYLINKER` | `0x0e` | ignore (it always says `/usr/lib/dyld`) |
| `LC_MAIN` | `0x80000028` | ! entry |
| `LC_UNIXTHREAD` | `0x05` | abort loudly (dyld-only on arm64) |
| `LC_UUID` | `0x1b` | record for diagnostics |
| `LC_BUILD_VERSION` | `0x32` | record (platform 1 = macOS; iOS = 2, simulator = 7) |
| `LC_SOURCE_VERSION` | `0x2a` | ignore |
| `LC_FUNCTION_STARTS` | `0x26` | ignore (backtrace only) |
| `LC_DATA_IN_CODE` | `0x29` | ignore |
| `LC_CODE_SIGNATURE` | `0x1d` | ignore (§10) |

Header for `hello_m14`: `magic=0xfeedfacf cputype=0x0100000c (CPU_TYPE_ARM64)
cpusubtype=0x0 (ARM64_ALL) filetype=2 (MH_EXECUTE) ncmds=17 flags=0x200085`.
`cpusubtype = 2` would be `ARM64E` — reject it with a clear message, because
arm64e means pointer authentication and `DYLD_CHAINED_PTR_ARM64E` (format 1),
which Linux/arm64 hardware may not even support (`PAC` is optional and the
signing keys are process-scoped). Fat/universal binaries start with
`0xcafebabe` / `0xbebafeca` and need a slice-selection front end; all my test
builds were thin.

---

## 15. Oracle outputs recorded (macOS, native)

```
./hello arg1        -> "hello 2" + 12 apple[] lines, exit 0
./ctors             -> "ctor1\nctor2\nmain 7 0x...\ndtor1", exit 0     (pointer value varies!)
./tlsbin            -> "5 6", exit 0
./usegreet          -> "libgreet init\ngreet a 1\ngreet b 2\ncount=2", exit 0
./dl                -> "libgreet init\ngreet dl 1", exit 0
./cppbin            -> "G ctor\na\nb\ncaught 42\nG dtor", exit 0
./objcbin           -> "hi world\nn=2", exit 0
./big               -> "1 7", exit 0
./hello_4k          -> SIGKILL (exit 137) — macOS rejects 4K segment alignment
```

Note `ctors` prints a pointer and `hello` prints `apple[]` — both are
**address-dependent and environment-dependent** and must not be byte-compared.
The fixture corpus should avoid printing raw addresses, or normalise them.

---

## 16. The variadic ABI mismatch — Darwin arm64 is not AAPCS64

Flagged by the fixture corpus (`docs/FIXTURES.md`, rung c); I measured both
sides to confirm it, because it invalidates the most attractive assumption in
the whole project ("`_printf` is a one-line forwarder to glibc's `printf`").

Same source, `void caller(void){ sink("f", 1, 2L, 3.5, "s"); }`, `-O1`:

**Darwin arm64 (`clang -target arm64-apple-macos14`):**

```
_caller:
   sub  sp, sp, #0x30
   adrp x8, l_.str.1 ; add x8, x8, ...      ; "s"
   mov  x9, #0x400c000000000000             ; 3.5 as raw BITS in an X register
   stp  x9, x8, [sp, #0x10]                 ; -> [sp+0x10] = 3.5, [sp+0x18] = "s"
   mov  w8, #0x2
   mov  w9, #0x1
   stp  x9, x8, [sp]                        ; -> [sp+0x00] = 1,   [sp+0x08] = 2
   adrp x0, l_.str ; add x0, x0, ...        ; only the FORMAT is in a register
   bl   _sink
```

**Linux aarch64 (`gcc -O1`, ubuntu:24.04 arm64 container):**

```
caller:
   adrp x3, ... ; add x3, x3, #0x0          ; "s"   -> x3
   fmov d0, #3.5                            ; 3.5   -> d0  (a VECTOR register)
   mov  x2, #0x2                            ; 2     -> x2
   mov  w1, #0x1                            ; 1     -> w1
   adrp x0, ... ; add x0, x0, #0x0          ; format-> x0
   bl   sink
```

And the `va_list` types are different objects entirely:

| | Darwin arm64 | Linux aarch64 |
|---|---|---|
| variadic args | **all on the stack**, one 8-byte slot each, doubles as raw bits | first 8 integer in `x1..x7`, first 8 FP in `v0..v7`, rest on the stack |
| `sizeof(va_list)` | **8** (a plain `char*`) | **32** (`{__stack, __gr_top, __vr_top, __gr_offs, __vr_offs}`) |
| `va_start` | `x29 + 0x10`, i.e. a pointer to the incoming stack args | initialises the 5-field register-save-area cursor |

(`_Static_assert(sizeof(va_list)==8)` compiles clean on Darwin arm64; the
container printed `linux va_list size=32 align=8`.)

### What this means

A Mach-O guest calling `_printf` puts its arguments **on the stack**. glibc's
`printf` looks for them **in registers**. A forwarder that does
`va_start(ap, fmt); return vprintf(fmt, ap);` hands glibc an 8-byte `char*`
where it expects a 32-byte cursor struct. It will not fail cleanly; it will
print garbage or fault.

The saving grace: **our `libSystem.B.dylib` is itself compiled
`-target arm64-apple-macos11`**, so its `printf(const char*, ...)` receives the
Darwin convention *correctly*. The break is only at the moment we try to hand
that `va_list` onward to glibc.

Options, in the order I would try them:

1. **Implement the printf family ourselves** over the Darwin `va_list`, using
   glibc only for output (`fwrite`/`write`). A formatter is a known quantity
   (~400 lines) and it makes the mismatch disappear rather than papering over
   it. This is the recommended answer for `printf`/`fprintf`/`sprintf`/
   `snprintf`/`vsnprintf`/`asprintf`.
2. **Repack per call site by parsing the format string** and rebuilding a Linux
   `va_list` (or just calling glibc's `printf` with the right registers loaded).
   This needs a format parser anyway, so it collapses into option 1 with extra
   fragility.
3. **For fixed-shape variadics** — `open(path, flags, mode)`, `fcntl`, `ioctl`,
   `execl` — a Darwin-compiled shim reads the one or two stack slots with
   `va_arg` and calls glibc's function with ordinary register arguments. Cheap
   and correct, but must be written per function.

The affected surface is wider than `printf`: `scanf` family, `syslog`, `err`/
`warn`, `open`/`fcntl`/`ioctl`, `execl*`, `NSLog`, and any Objective-C variadic
method reached through `objc_msgSend`. **A variadic function is never a
one-line forwarder.** Every one of them needs an entry in the symbol table with
a deliberate strategy attached.

Note this is also why `printf`'s format coverage
(`%d %u %x %ld %s %c %% %5d %-5d %05d %.3f`) is well chosen: it catches a
half-implemented formatter at the first rung that needs one.

---

## Appendix — reproducing every number above

```sh
SDK=$(xcrun --show-sdk-path)
M="-target arm64-apple-macos14 -isysroot $SDK"   # chained fixups
C="-target arm64-apple-macos11 -isysroot $SDK"   # classic LC_DYLD_INFO_ONLY

clang $M -o hello        hello.c
clang $C -o hello_classic hello.c
clang $M -o ctors        ctors.c
clang $M -o tlsbin       tls.c
clang $M -dynamiclib -install_name @rpath/libgreet.dylib -o libgreet.dylib libgreet.c
clang $M -o usegreet     usegreet.c -L. -lgreet -Wl,-rpath,@executable_path
clang $M -o wide         wide.c
clang++ $M -o cppbin     cpp.cpp
clang $M -fobjc-arc -framework Foundation -o objcbin objcbin.m
clang $M -Wl,-segalign,0x1000 -o hello_4k hello.c     # links; macOS SIGKILLs it

../scripts/machodump.py hello ctors tlsbin libgreet.dylib usegreet
xcrun dyld_info -fixups -imports -exports hello       # independent cross-check
```

Sources, verbatim:

```c
/* hello.c */
#include <stdio.h>
int main(int argc, char **argv, char **envp, char **apple) {
    printf("hello %d\n", argc);
    for (int i = 0; apple && apple[i]; i++) printf("apple[%d]=%s\n", i, apple[i]);
    return 0;
}

/* ctors.c */
#include <stdio.h>
__attribute__((constructor(101))) static void c1(void){ printf("ctor1\n"); }
__attribute__((constructor(102))) static void c2(void){ printf("ctor2\n"); }
__attribute__((destructor))       static void d1(void){ printf("dtor1\n"); }
static int x = 7;
int *px = &x;                          /* rebase */
extern int printf(const char*,...);
int (*pf)(const char*,...) = printf;   /* bind   */
int main(void){ printf("main %d %p\n", *px, (void*)pf); return 0; }

/* tls.c */
#include <stdio.h>
__thread int t1 = 5;
_Thread_local long t2;
int main(void){ t2 = t1 + 1; printf("%d %ld\n", t1, t2); return 0; }

/* libgreet.c */
#include <stdio.h>
int greet_count = 0;
void greet(const char *w){ greet_count++; printf("greet %s %d\n", w, greet_count); }
__attribute__((constructor)) static void libinit(void){ printf("libgreet init\n"); }

/* usegreet.c */
#include <stdio.h>
extern void greet(const char*);
extern int greet_count;
int main(void){ greet("a"); greet("b"); printf("count=%d\n", greet_count); return 0; }
```

`wide.c`, `cpp.cpp`, `objcbin.m` and `big.c` (3000 cross-referencing pointers +
a 200 KB bss array, used to produce a multi-page fixup chain) are described in
§12 and §1 respectively; their exact text does not matter, only the import sets
and section layouts they produce.

Linux side:

```sh
docker run --rm --platform linux/arm64 ubuntu:24.04 sh -c \
  'getconf PAGESIZE; uname -m; uname -r; cat /proc/sys/vm/mmap_min_addr'
# 4096 / aarch64 / 6.12.76-linuxkit / 32768
```
