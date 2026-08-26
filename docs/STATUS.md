# STATUS — 2026-08-25

**Independent verification.** Everything below was re-measured by an agent that
did not write the loader, from a **fresh clone into an empty directory**. Where
a number repeats an earlier report it is because it was re-run, not because it
was copied. Where an earlier claim did not survive contact, it is corrected in
place and the correction is called out.

Oracle host: macOS 26.5.2 (25F84), arm64, Apple clang 17.0.0, ld-1230.1.
Target: Ubuntu 24.04 aarch64 in Docker, native on the same Apple-silicon host —
no CPU emulation anywhere in this project.

---

## 1. Does it reproduce?

Yes, exactly.

```
$ git clone <repo> /tmp/clean && cd /tmp/clean
$ scripts/difftest.sh

FIXTURE                  RUNG  FIXUPS   VERDICT
01_exit_raw              a     classic  XFAIL      raw Darwin svc -- permanent, by design
01b_exit_unixthread      a     none     NO-ORACLE  macOS SIGKILLs it; nothing to diff against
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
09_objc                  i     chained  XFAIL      needs libobjc -- the one real wall
11_varargs               j     chained  PASS
11c_varargs_classic      j     classic  PASS
12_mach                  k     chained  PASS
13_errno                 l     chained  PASS
14_utility               m     chained  PASS
10_fat                   x     chained  PASS
--------------------------------------------------------------------------------
pass 18  fail 0  xfail 2  xpass 0  skipped 0  no-oracle 1  drift 0
```

The clone needs nothing from the host but Docker: `tests/bin/` (the Apple-built
Mach-O fixtures) and `tests/expected/` (the macOS baselines) are committed, and
the loader and our dylibs are built inside the container by the run itself.
Three consecutive runs gave identical numbers.

### Count the denominator honestly

21 manifest rows. One (`01b_exit_unixthread`) has no macOS baseline because
macOS itself will not execute it, so it cannot be graded. **Of the 20 gradeable
fixtures, 18 pass and 2 are documented XFAILs.**

Both earlier statements of this were wrong in opposite directions and are
corrected here: the README said "18 of 19 runnable fixtures" and this file said
"eighteen of the eighteen runnable fixtures" — the second by quietly dropping
the two XFAILs out of the denominator. The number is 18 of 20.

## 2. Are the baselines really from macOS?

Four independent reasons to believe so, in increasing order of strength.

1. **The gate exists and is real.** `harness/run_macos.sh` exits 64 on anything
   but Darwin, and `--record` exists nowhere else; `harness/run_linux.sh`
   refuses `--record` outright; `scripts/difftest.sh` refuses to grade unless
   `tests/expected/PROVENANCE` says `os: Darwin`; and the container gets
   `tests/expected` mounted **read-only**, so the rule is enforced by the
   kernel and not by good intentions.
2. **Git ordering vouches for rungs (a)–(i).** Those baselines were committed
   in `5e7cba9` at 21:12:23, **23 minutes before the loader's first commit**
   `c66bae5` at 21:35:44. They cannot have been fitted to a loader that did not
   exist. (This argument does *not* extend to `11`–`14`, committed at 22:03 and
   22:17, after the loader worked. For those, only reasons 3 and 4 apply.)
3. **The oracle was re-verified live during this run.** `difftest.sh` on macOS
   re-executes every fixture natively and compares before it grades anything:
   `ok 20, drift 0`. A baseline fabricated anywhere else would have surfaced as
   BASELINE-DRIFT, never as PASS.
4. **Re-run by hand, outside the harness.** Six fixtures including all four of
   the late ones (`03_printf`, `11_varargs`, `12_mach`, `13_errno`,
   `14_utility`, `09_objc`) were executed directly on macOS with the harness
   out of the picture. stdout, stderr and exit status are byte-identical to the
   committed baselines.

## 3. Can the suite fail? — mutation testing

A suite that cannot fail proves nothing. Nineteen mutations were introduced one
at a time into the loader and the userland, each rebuilt from source in the
container and graded against the unmodified macOS baselines. **Fifteen were
caught; four were not.** The four survivors are the honest map of where the
corpus is thin.

### Killed

| mutation | fixtures that failed |
|---|---|
| classic bind stream not walked | **all 18** |
| classic lazy-bind stream not walked | **all 18** |
| chained binds not written | 12 |
| `__TEXT,__init_offsets` ignored | 3 (`05_mod_init`, `05b_cxx_init`, `07_dylib`) |
| chained rebases not applied | 2 (`07_dylib`, `14_utility`) |
| classic rebase does not add the slide | 2 (`07c_dylib_classic`, `13_errno`) |
| `__mod_init_func` ignored | 2 (`05c_mod_init_classic`, `07c_dylib_classic`) |
| TLV initial-value copy removed | 2 (`06_tls`, `08_pthread`) |
| `DYLD_CHAINED_PTR_64_OFFSET` uses `slide` instead of `load_base` | 1 (`14_utility`) |
| TLV descriptor `offset` ignored | 1 (`06_tls`) |
| Linux→Darwin `errno` map replaced by identity | 1 (`13_errno`) |
| `O_*` flags passed through untranslated | 1 (`13_errno`) |
| `struct stat` `st_mode` not translated | 1 (`13_errno`) |
| one bit cleared in `_DefaultRuneLocale` (`_CTYPE_A`) | 1 (`14_utility`) |
| fat slice selection disabled | 1 (`10_fat`) |

Two of these are worth reading twice. Breaking the **classic** bind or
lazy-bind interpreter fails every fixture including the chained ones, because
`ld64.lld` emits `LC_DYLD_INFO_ONLY` for the dylibs *we* build — so our own
`libSystem.B.dylib` is bound through the classic path on every single test. And
clearing a single bit of the 3208-byte rune table is caught by exactly one
fixture, which is the entire reason `14_utility` prints all 128 characters in
twelve classes: one wrong bit shows up as one wrong column.

### Survived — real coverage holes

| mutation nothing noticed | what that means |
|---|---|
| chained bind inline `addend8` dropped | no chained bind in the corpus carries a non-zero inline addend |
| classic bind `addend` dropped | likewise for `BIND_OPCODE_SET_ADDEND_SLEB` |
| classic **weak-bind** stream skipped entirely | no fixture weak-binds anything |
| Darwin→Linux `errno` map replaced by identity | only the l2d direction is ever observed |
| initialiser dependency order reversed | no image in the corpus has more than one dependency |

The last one is arguably not a hole in the loader but in the corpus: with at
most one dependency there is no order to get wrong. The first four are code
that is compiled, shipped, and never executed under test.

## 4. What else was checked

- **Slide.** All 20 gradeable fixtures were re-run with
  `MACHORUN_NO_PREFERRED_BASE=1`, which forces every executable off its
  preferred `0x100000000` base: 18 match, and the 2 that do not are the same
  two XFAILs. Nothing depends on `slide == 0`.
  *(A first attempt at this reported `14_utility` failing under slide. That was
  contamination — `darwin/usr/` is a gitignored build product, so a mutated
  `libSystem` survived the `git checkout` that restored its source. Re-run after
  a clean rebuild it passes. Recorded because the trap is easy to fall into
  twice.)*
- **A broken build no longer reports success.** Appending `this is not c;` to
  `src/main.c` produced `pass 0 ... skipped 20` — **and exit status 0**. A CI
  gate on that exit code would have gone green on a tree that does not compile.
  `scripts/difftest.sh` now exits 2 when anything was skipped, with the reason
  printed. This was the one integrity defect found in the harness itself.
- **Determinism.** Three consecutive full runs, identical results.
- **Nothing stubs silently.** `mr_unimplemented` prints what, why, and a
  pointer to `docs/UNIMPLEMENTED.md`, then `_exit(71)`. There are 17 call sites
  and no path that returns a plausible-looking wrong answer instead.
- **Each ABI translation earns its keep.** `scripts/abi_naive_probe.sh` rebuilds
  libSystem five times, each with one translation disabled, and diffs against
  the macOS baseline. All five diverge — varargs with a SIGSEGV at fault address
  `0x4d2` (1234, the first argument of `printf("int=%d\n", 1234)`), `errno` and
  `O_*` and `struct stat` on `13_errno`, and the rune table on `14_utility`. It
  leaves the tree clean.

## 5. How much of the userland is actually tested?

`libSystem.B.dylib` exports **242 symbols. 86 are referenced by at least one
fixture. 156 — 64% — are compiled but never called by any test.** They may well
be right; nothing here says they are. This is the single biggest gap between
"the suite is green" and "the userland works", and it is a bigger gap than the
mutation survivors.

Also unexercised by any fixture, and therefore unverified regardless of what
the loader does: stdin, `argv` beyond `argv[0]`, environment variables,
signals, `fork`/`exec`, sockets, `dlopen`/`dlsym`, C++ exceptions,
`LC_MAIN.stacksize != 0`, `LC_REEXPORT_DYLIB`, weak and weak-defined symbols,
two-level-namespace misses, and `__DATA,__objc_catlist`.

## 6. Distance to the stated goal

The goal on the tin is *run precompiled Mach-O binaries*. Every fixture in the
corpus was built by Apple's toolchain — but it was built **for this project**,
against the surface this project provides. The interesting question is what
happens to a binary nobody here compiled.

Measured, on four unmodified Homebrew arm64 binaries:

| binary | dylibs it wants | undefined symbols | not exported by our libSystem |
|---|---|---|---|
| `gsed` | libSystem only | 111 | **37** |
| `jq` | libSystem + `libonig.5` | 140 | 70 |
| `rg` | libSystem + `libpcre2-8` + `libiconv.2` | 141 | 90 |
| `gawk` | libSystem + 4 Homebrew dylibs + **CoreFoundation** | 288 | — |

`gsed` is the closest thing to a real target: the loader parses it, maps it,
resolves its dependency graph and stops at the first symbol it cannot supply,
naming it (`____mb_cur_max`). The remaining 37 are ordinary libc breadth —
`fdopen$DARWIN_EXTSN`, `getopt_long`, `setvbuf`, `ungetc`, `popen`, the
`mbrtowc`/`wcrtomb` multibyte family, `nl_langinfo`, `uselocale`, the seven
`acl_*` entry points, `__chkstk_darwin`. None of it is architecturally hard;
all of it is unwritten. `jq` stops earlier and for a different reason — a
non-system dylib we would have to build ourselves.

Apple's own shipping binaries are not a breadth problem at all. `/bin/echo`,
`/bin/ls` and `/usr/bin/true` are all `x86_64 + arm64e` universal binaries with
**no plain arm64 slice**, so PAC — explicitly out of scope — blocks them before
any symbol does.

**Revised estimate.** "Precompiled third-party CLI tools that link only
libSystem" is close: tens of symbols, days not months, and each one is a `nm -u`
away from being known rather than guessed. "Precompiled *Apple* binaries" needs
arm64e/PAC and is a different project. "Arbitrary App Store apps" additionally
needs FairPlay and dozens of private frameworks, and remains what the README
says it is — Darling's decade, and not milestone 1.

## 7. The sibling projects do not currently compose

The README's front table is true project by project and misleading read
downward. What follows was established by reading the siblings (not by re-running
their suites) and it changes the estimate materially.

- **`~/objc4-linux` is Apple's objc4 built as an ELF `libobjc.so`**, and it did
  not shim Mach-O image discovery — it **replaced** it, enumerating images with
  `dl_iterate_phdr` and ELF section names. Rebuilding it as a Mach-O dylib
  undoes the port's central change, and drags in libc++/libc++abi as Mach-O plus
  an unwinder for `__TEXT,__unwind_info`, none of which exists here.
- **`~/uikit` (OpenUIKit) is a Swift engine.** Its Objective-C support is a
  *source-level facade* — four classes, `UIView`/`UILabel`/`UIButton`/
  `UIViewController` — compiled with `-fobjc-runtime=gnustep-2.2` against
  **libobjc2 + gnustep-base**. That is a different `struct objc_class` from
  Apple's, which is the ABI a precompiled Darwin binary carries. And swiftc on
  Linux emits ELF; the verified "Linux produces Mach-O" result is about
  `clang -target arm64-apple-macos11`, which is a claim about C, not Swift.

So there are three runtimes here — Apple-objc4-on-ELF, Swift-on-ELF, and a
GNUstep-ABI facade — and machorun needs Mach-O with Apple's ObjC ABI. **The
composition is the unbuilt part, and it is larger than any of the three pieces.**

### What loading an Objective-C UIKit binary would actually take

In order, each blocking the next:

1. **`/usr/lib/libobjc.A.dylib` that machorun can bind against.** The
   recommended shape (`docs/UNIMPLEMENTED.md` §`objc-callbacks`) is a hybrid:
   an **ELF-backed Darwin dylib** mechanism in machorun — a Mach-O image whose
   exports forward into a real `.so` — rather than a Mach-O rebuild of objc4.
   Note `__objc_empty_cache` is a **data** import that every guest class
   structure points at, so function forwarding alone is not enough; data
   imports must resolve to the ELF object's actual addresses.
2. **A foreign-image registration entry point in objc4-linux**, e.g.
   `objc4linux_register_foreign_image(mh, path, sections)`, feeding the same
   `_dyld_objc_notify_mapped_info` path its ELF scanner already builds. This is
   a change to a sibling project, not to this one.
3. **dyld's ObjC hooks in the loader**: `_dyld_objc_register_callbacks` /
   `_dyld_objc_notify_register`, with `map_images` and `load_images` called
   before any initialiser. The hook point exists (`mr_objc_note_image`); today
   it is a loud abort.
4. **C++ exceptions**, for `objc_exception_throw` and for anything above it.
   Needs libc++abi plus an unwinder that reads Apple's compact
   `__TEXT,__unwind_info` — not `.eh_frame`, so libgcc's unwinder cannot simply
   be forwarded to. No fixture throws yet, so this is both unimplemented and
   untested.
5. **Foundation and CoreFoundation.** objc4-linux excludes them by design and
   OpenUIKit's facade routes around them through a C ABI. A precompiled UIKit
   app does not route around them: it will reference `NSString`, `NSArray`,
   `CFRunLoop` directly. This is the step with no sibling project behind it.
6. **UIKit as a Mach-O dylib exporting Apple's symbols.** A precompiled app
   binds `_OBJC_CLASS_$_UIView` and friends by name and messages them by
   selector. OpenUIKit's facade exports four classes with its own layouts;
   Apple's UIKit exports on the order of a thousand. Non-fragile ivars help —
   objc4 fixes ivar offsets up at runtime — but the class *surface* is the work.
7. **Then**, and only then, CoreGraphics/CoreAnimation (`~/quartz`) and a
   display path for `UIScreen`.

Steps 1–4 are machorun's, are bounded, and are the ones worth costing. Steps
5–7 are a different project the size of the ones already in the table.

## 8. Ranked next blockers

1. **libSystem breadth, measured against binaries we did not build.** `gsed` is
   37 symbols away and the list is enumerated above. This is the cheapest way to
   turn "runs our fixtures" into "runs software", and it is now a checklist
   rather than an opinion.
2. **Close the four mutation survivors.** A fixture with a non-zero bind addend,
   one that weak-binds, one that observes the Darwin→Linux `errno` direction,
   and one image with two dependencies. Four small fixtures buy back four pieces
   of untested shipped code.
3. **ObjC (`09_objc`)** — steps 1–4 of §7.
4. **C++ exceptions** — also step 4, and blocking on its own.
5. **`dlopen`/`dlsym`.** `mr_image_load` was written re-entrant for it; nothing
   else is needed structurally, but no fixture exercises it so it is unwritten.
6. **64 KiB-page kernels.** Detected and refused with a specific message. The
   copy-in fallback in `PLAN` §I.4 is ~60 lines and unwritten.

### Smaller, found while verifying

- The "cannot find dylib" message explains that the path "is not a file on
  macOS either — it lives in the dyld shared cache". That is true for
  `/usr/lib/...` and false for the `/opt/homebrew/...` path that `jq` asks for,
  where the dylib is an ordinary file. The message should branch on the prefix.
