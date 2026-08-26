# STATUS — 2026-08-25

**Precompiled Mach-O binaries, built by Apple's toolchain on macOS, execute on
Linux/arm64 under `machorun`.** Eighteen of the eighteen runnable fixtures
produce output byte-identical to the same bytes running natively on macOS —
stdout, stderr and exit status.

```
$ scripts/difftest.sh
FIXTURE                  RUNG  FIXUPS   VERDICT
01_exit_raw              a     classic  XFAIL       raw Darwin svc -- permanent, by design
01b_exit_unixthread      a     none     NO-ORACLE   macOS SIGKILLs it, so it cannot be graded
02_main_ret              b     chained  PASS
02c_main_ret_classic     b     classic  PASS
03_printf                c     chained  PASS
03c_printf_classic       c     classic  PASS
04_malloc                d     chained  PASS
05_mod_init              e     chained  PASS
05c_mod_init_classic     e     classic  PASS
05b_cxx_init             e'    chained  PASS
06_tls                   f     chained  PASS
07_dylib                 g     chained  PASS
07c_dylib_classic        g     classic  PASS
08_pthread               h     chained  PASS
09_objc                  i     chained  XFAIL       needs libobjc -- the one real wall
11_varargs               j     chained  PASS
11c_varargs_classic      j     classic  PASS
12_mach                  k     chained  PASS
13_errno                 l     chained  PASS
14_utility               m     chained  PASS
10_fat                   x     chained  PASS
                                        pass 18  fail 0  xfail 2  no-oracle 1
```

Both fixup formats, both initialiser section forms, both entry-point forms.

## What that sentence is and is not

**Is:** the loader maps segments, applies chained and classic fixups, resolves
a two-level dependency graph, patches TLV descriptors, runs initialisers in
dependency order and calls `main`; and our own `libSystem.B.dylib` — a Mach-O
dylib *built on Linux* — serves the guest's calls out of glibc. No Darwin
syscall is emulated anywhere. The core bet holds for everything in the corpus.

Rungs (j) through (m) are about the userland rather than the loader: the
places where "forward it to glibc" is not a translation but a *different
program*. The Darwin arm64 variadic ABI, `errno` numbering, `O_*` flag values
and `struct stat`'s layout are all measured in `docs/ABI.md`, and
`scripts/abi_naive_probe.sh` disables each translation in turn to show what
breaks without it — a SIGSEGV at fault address `0x4d2` (which is 1234, the
first argument of `printf("int=%d\n", 1234)`), `ENOTEMPTY` reported as 39 where
the guest's own constant is 66, an `O_CREAT` that performs a truncate, and a
12-byte file whose `st_size` reads 471711007, and — for `<ctype.h>`, which
Darwin *inlines into the guest* as a lookup in a 3208-byte table we have to
supply — every character in the ASCII range classifying as nothing at all,
without the guest ever calling a function of ours to get that wrong answer.

Rung (m) is not a mechanism, it is a shape: `14_utility` is a representative
hand-built utility (ctype, setlocale, getopt, qsort, strftime, fgets, the
strtol idiom), written to answer "what would the next binary need" by
measurement. It was seven symbols short when first run, and those seven became
`darwin/src/ctype.c`.

**Is not:** arbitrary macOS software. The corpus is C and minimal C++ against a
libSystem surface of 242 exports drawing 116 symbols from glibc. Objective-C does not run. C++ *exceptions* do
not run and are not even attempted — `05b_cxx_init` has non-trivial
constructors and destructors but never throws, so Apple's compact
`__unwind_info` remains untouched.

## Verified beyond the fixture list

- **Slide.** `MACHORUN_NO_PREFERRED_BASE=1` forces every executable off its
  preferred `0x100000000` base. All 18 still pass, so nothing depends on
  `slide == 0` — the class of "used the preferred base where the load base was
  meant" bugs is closed by test rather than by inspection.
- **argv / apple[].** `argc`, `argv[1..]`, `envp` and
  `apple[0]=executable_path=...` all arrive at `main`.
- **A missing symbol is a sentence, not a fault**: symbol, wanting image,
  searched image, and nearby names in that image's trie.
- **A guest fault is a sentence too**: signal, pc, and which image at what
  offset. A raw `svc #0x80` within four instructions of the fault is
  recognised and explained on the spot, which is how rung (a) reports itself.
- **Each translation earns its keep.** `scripts/abi_naive_probe.sh` rebuilds
  libSystem four times with one translation disabled each time and diffs the
  result against the macOS baseline. If a variant ever comes out identical,
  that code is not load-bearing and should be deleted.
- **Guests get no host fallback.** Only images out of `darwin/` may resolve
  through `dlsym`. A fixture's missing import is therefore always reported as a
  gap in our userland, never silently satisfied by a same-named glibc symbol.

## Ranked next blockers

1. **ObjC (`09_objc`).** The one genuine wall. See `docs/UNIMPLEMENTED.md`
   §`objc-callbacks` — reading `~/objc4-linux` changed the recommended
   approach: it replaced Mach-O image discovery with ELF discovery rather than
   shimming it, so "rebuild objc4 as Mach-O" undoes the port's central change.
   The registration seam it *does* expose is format-agnostic, which points at a
   hybrid (ELF libobjc + an ELF-backed dylib mechanism in machorun + a
   foreign-image registration entry point in objc4-linux). Piece 3 is a change
   to a sibling project.
2. **C++ exceptions.** Needs libc++abi plus an unwinder that reads
   `__TEXT,__unwind_info`. Not `.eh_frame`, so libgcc's unwinder cannot be
   forwarded to. No fixture throws yet, so this is currently untested *and*
   unimplemented — the corpus should grow a throwing fixture before anyone
   claims C++ works.
3. **`dlopen`/`dlsym`.** `mr_image_load` was written re-entrant for this, and
   nothing else is needed structurally, but no fixture exercises it so it is
   unwritten. Cheap and worth doing before the surface grows.
4. **libSystem breadth.** 242 exports covers the corpus. Measured against real
   binaries rather than guessed at: a representative hand-built utility now
   resolves completely, and `/bin/echo`-class BSD tools are ~6-20 symbols away
   (`err`/`warn`, `getopt_long`, `fdopen`, `realpath$DARWIN_EXTSN`,
   `malloc_type_malloc`, `__chkstk_darwin`). Apple's *shipping* system binaries
   are a different matter and not a symbol problem at all: `/bin/ls`,
   `/bin/echo` and `/usr/bin/true` are all `x86_64 + arm64e` universal binaries
   with **no plain arm64 slice**, so PAC — explicitly out of scope — blocks them
   before breadth does. Everything beyond it
   is a `nm -u` away from being known; each new framework surface is
   incremental, and the honest metric is the length of that table.
5. **64 KiB-page kernels.** Detected and refused with a specific message. The
   copy-in fallback in PLAN §I.4 is ~60 lines and unwritten.
