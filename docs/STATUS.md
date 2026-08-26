# STATUS — 2026-08-25 (§9, §10, §11 all 2026-08-26)

**Independent verification.** Everything below was re-measured by an agent that
did not write the loader, from a **fresh clone into an empty directory**. Where
a number repeats an earlier report it is because it was re-run, not because it
was copied. Where an earlier claim did not survive contact, it is corrected in
place and the correction is called out.

Oracle host: macOS 26.5.2 (25F84), arm64, Apple clang 17.0.0, ld-1230.1.
Target: Ubuntu 24.04 aarch64 in Docker, native on the same Apple-silicon host —
no CPU emulation anywhere in this project.

> **Since this verification (2026-08-26), now merged to `master`:
> Objective-C runs.** Apple's objc4 now builds as a Mach-O
> `darwin/usr/lib/libobjc.A.dylib` on Linux with **4 patches** (the ELF port in
> `~/objc4-linux` needs 9), machorun implements dyld's own ObjC image-notify
> protocol in `src/objc_notify.c`, and `09_objc` **PASSes** byte-identically —
> so the `XFAIL` on its row below, and "the one real wall" in §"Ranked next
> blockers", are both superseded. 41 of `~/objc4-linux`'s 44 differential tests
> pass against the same committed macOS baselines; the 3 that do not are the
> pre-existing `unwind-compact` and `dlopen` gaps, already ranked #2 and #3
> below. Full accounting, including what got *harder*, in
> **`docs/OBJC4_MACHO.md`**.
>
> **Re-measured on merge (2026-08-26), from `rm -rf build darwin/usr` and a
> full rebuild of the loader, the Darwin userland and libobjc inside the
> container:** `scripts/difftest.sh` → `pass 19 fail 0 xfail 1 xpass 0 skipped
> 0 no-oracle 1 drift 0`, with the oracle re-verified natively on macOS in the
> same run. `scripts/objc44.sh` → `41/44 PASS`, failing exactly
> `038-exceptions`, `044-exception-through-uncached` and `042-dlopen`, each
> with its documented loud abort. Both numbers were produced by this rebuild,
> not carried over.
>
> **`~/objc4-linux` is retired** as of the same date — its README carries the
> notice. It is not deleted: it is still the only tree that runs all 44, and
> the two gaps that must close before it can go are `unwind-compact` and
> `dlopen-dlsym`. The findings of its `PORT_MAP.md` / `PORT_PLAN.md` that hold
> regardless of file format are carried forward in `docs/OBJC4_MACHO.md` §9 and
> in `docs/UNIMPLEMENTED.md` (`isa-va-width`, `objc-load-ordering`).
>
> The table below is left exactly as that clean-clone run recorded it, because
> editing a verification record in place would destroy the thing it is for.
>
> **Since then (2026-08-26): Xcode is no longer a build input.** `sdk/` is this
> repository's own header-only, `.tbd`-only SDK — 355 headers, of which 336 are
> vendored from eleven pinned `apple-oss-distributions` releases (all
> redistributable) or produced by running xnu's own published generator, and
> **19 are clean-room headers of ours**. `scripts/build_objc4.sh` now defaults
> `-isysroot` to it, and `docs/UNIMPLEMENTED.md#objc-sdk-dependency` is closed.
> Apple's libc++ — 67% of the old header surface — is gone entirely; the build
> uses stock LLVM 18 libc++ with three `-D` flags, pinned in
> `harness/Dockerfile`. `sdk/PROVENANCE.md` is the accounting.
>
> Re-measured after that switch, in the container, from a rebuild:
> **32 objects / 0 failures**; `scripts/objc44.sh` → **41/44** with the same
> three failures; `scripts/difftest.sh` → **19 pass / 0 fail / 1 xfail / 1
> no-oracle**, unchanged; and a new `scripts/sdk_abi_probe.sh` → **149 lines,
> byte-identical to the macOS oracle**.
>
> That last one is a new kind of test and it earned its place immediately. It
> prints the *ABI* rather than behaviour — `struct stat`'s size and every field
> offset, 46 `errno` values, 14 `O_*` values, `sizeof(va_list)`, and the first
> bytes of `_DefaultRuneLocale` — built twice, by Apple's clang against Apple's
> SDK on macOS and by clang-18 against `sdk/` alone on Linux, the second linked
> by `ld64.lld-18` against `.tbd` stubs generated from our own dylibs and run
> under `build/machorun`. **A guest can now be built end to end on Linux**,
> which was not previously possible.
>
> §5's "156 of 242 exports are compiled and untested" is unchanged in kind, but
> the numbers moved: `libSystem.B.dylib` now exports 320, and its `.tbd` carries
> 342 — the extra 22 being symbols the *loader* defines, listed in
> `darwin/loader-exports.txt` and checked on every build.
>
> **One finding worth carrying into §8.** Assembling `sdk/` turned up a failure
> mode this document's mutation testing could not have found, because it lives
> in the headers rather than in the code: xnu's published `sys/cdefs.h` and
> `mach/arm/vm_param.h` gate per-product settings on `XNU_PLATFORM_<name>`,
> which Apple's header-install step resolves with `unifdef`. With none selected,
> `MACH_VM_MAX_ADDRESS_RAW` silently becomes the embedded 64 GB value instead of
> macOS's 128 TB and **nothing fails to compile**. `sdk/patches/` fixes it and
> `sdk_abi_probe` guards against the next one, but only for what the probe
> prints. `docs/UNIMPLEMENTED.md#sdk-published-vs-installed` has the detail.
>
> **That last sentence was too generous, and §9 is the measurement that
> corrects it.** The probe did not print `MACH_VM_MAX_ADDRESS_RAW`, so the one
> failure it was written for was the one failure it could not see. Forcing that
> constant to the embedded value passed `build_objc4`, `gen_tbd`,
> `sdk_abi_probe` and the 44-test corpus. It now prints it, and the mutation now
> fails.

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

> **Superseded in part, 2026-08-26.** Steps 1–3 below are **done** and the
> first bullet's conclusion was **wrong in an interesting way** — see
> `docs/OBJC4_MACHO.md` §5 and `docs/UNIMPLEMENTED.md#objc-callbacks`, both of
> which keep the withdrawn recommendation on the record rather than deleting
> it. Rebuilding objc4 as Mach-O did undo the ELF port's central change, and
> that turned out to be the *cheap* direction, because the thing being undone
> was compensation for running in the wrong format. Step 4 (C++ exceptions) and
> steps 5–7 stand unchanged. The text below is left as written.

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

---

## 9. Second independent verification (2026-08-26) — the SDK

Re-measured by a second agent that wrote neither the loader nor `sdk/`, from a
**fresh `git clone` into an empty directory**, with the Linux side run in a
container started `--network none` and with **only the clone mounted**. Every
number below was produced by that run. Where the previous report did not
survive contact it is corrected here rather than in place.

### 9.1 The numbers reproduce — with one correction to how you get them

| gate | result | notes |
|---|---|---|
| `scripts/difftest.sh`, fresh clone, nothing else run | **18 pass / 1 FAIL / 1 xfail / 1 no-oracle**, exit 1 | see below |
| `scripts/build.sh everything` first, then `difftest.sh` | **19 pass / 0 fail / 1 xfail / 1 no-oracle**, exit 0 | matches the claim |
| `scripts/build_objc4.sh` against `sdk/` | **32 objects, 0 failures** | matches |
| `scripts/objc44.sh` | **41/44**, failing exactly `038-exceptions`, `042-dlopen`, `044-exception-through-uncached` | matches |
| `scripts/gen_tbd.sh` | 342 + 420 + 14 symbols; **69 binaries import 223 distinct symbols, 0 unresolved** | matches |
| `scripts/sdk_abi_probe.sh` | byte-identical to the macOS oracle | matches; now **163** lines, not 149 — see §9.4 |
| `scripts/sdk_stage.sh` restage from upstream | **355 headers reproduce byte-for-byte** | new measurement |

**The one discrepancy, and it is in the instructions rather than in the code.**
`harness/run_linux.sh` builds the loader by calling `scripts/build_linux.sh`,
which is `scripts/build.sh all` — and `all` deliberately stops short of objc4,
because 32 Objective-C++ TUs is about a minute and difftest invokes it on every
run. So on a tree where `libobjc.A.dylib` has never been built, `09_objc` gets a
red **FAIL** with `cannot find dylib '/usr/lib/libobjc.A.dylib'`, and difftest
exits 1. §1's "the clone needs nothing from the host but Docker" is still true;
"`$ git clone && scripts/difftest.sh`" is not the whole gate. It is
**`scripts/build.sh everything` and then `scripts/difftest.sh`**, and the README
now says so.

### 9.2 Is the build genuinely Apple-SDK-free? — yes, and it was attacked

- The test-bed image was rebuilt from the committed `harness/Dockerfile` and
  searched: **no `MacOSX*.sdk`, no `.tbd` file, no `/Applications`** anywhere in
  it. Ubuntu clang 18.1.3 and Ubuntu LLD 18.1.3, both from `apt`.
- `scripts/build.sh everything` was then run with `--network none` and only the
  clone bind-mounted, and produced the loader, both dylibs, `libobjc.A.dylib`
  (32 objects, 0 failures) and all three `.tbd`s. No fetch, no host path.
- The only smuggling vector that exists is `build/sdk/MacOSX.sdk` — a staged
  copy of Apple's headers that the assembling agent kept as an *oracle*, and
  which `harness/run_linux.sh` would mount along with the rest of the tree. It
  is under the gitignored `build/`, so **a clone does not have it**, and this
  verification ran on a clone that did not.
- Every `xcrun` in the repository is on the **macOS oracle side** and is
  unreachable from any Linux build path: `tests/build_fixtures.sh` (which
  refuses to run off Darwin), `scripts/gen_errno_table.sh` and
  `scripts/gen_rune_table.sh` (nothing invokes them; their outputs are committed
  as `darwin/src/{errno_table,rune_table}.h`), and `scripts/sdk_abi_probe.sh
  --record`, which exits unless `uname -s` is `Darwin`.
- `scripts/build_objc4.sh` still honours `OBJC4_SDK` pointing at a real
  `MacOSX.sdk`. That is a documented differential-check escape hatch, it
  defaults to `sdk/`, and nothing in the repository sets it.

**No header in `sdk/usr/include` comes from Apple's Xcode SDK.** Restaging the
tree from the eleven pinned `apple-oss-distributions` releases reproduces all
355 files byte-for-byte: 332 upstream, 19 clean-room from `sdk/local/`, 4 from
`vendor/objc4`. `sdk/MANIFEST.tsv` has a row for each of the 355 and the census
in `sdk/PROVENANCE.md` §1 adds up.

**The `.tbd` stubs are generated, not maintained.** They are gitignored,
`scripts/gen_tbd.sh` re-derives them from `darwin/usr/lib/*.dylib` on every
build, and its three checks all pass. They cannot drift, because there is
nothing committed to drift from.

### 9.3 What the suite still cannot catch, and what was fixed

Two mutations were introduced into `sdk/usr/include` and the whole gate was run
against each.

| mutation | before | after |
|---|---|---|
| `sys/errno.h`: `EAGAIN` 35 → 36 | **caught** by `sdk_abi_probe` | caught |
| `sys/cdefs.h`: un-select `XNU_PLATFORM_MacOSX` (the `$UNIX2003` half) | caught, but only *downstream* — `build_objc4` linked cleanly (`-undefined dynamic_lookup`), then `gen_tbd` check 2 failed and `objc44` went to **0/44** | caught by `sdk_abi_probe` directly |
| `mach/arm/vm_param.h`: `MACH_VM_MAX_ADDRESS_RAW` 128 TB → 64 GB | **SURVIVED EVERYTHING** — `build_objc4` 32/0, `gen_tbd` all three checks, `sdk_abi_probe` identical, `objc44` 41/44 | caught by `sdk_abi_probe` |

The third row is the headline. It is the *exact* failure `sdk/PROVENANCE.md`
§3.2 and the README present as the thing this milestone found and fixed, and
until this verification nothing in the repository could have found it again.
`sdk/tests/abi_probe.c` now prints `MACH_VM_{MIN,MAX}_ADDRESS{,_RAW}`,
`VM_{MIN,MAX}_ADDRESS`, `__DARWIN_ONLY_{UNIX_CONFORMANCE,64_BIT_INO_T,VERS_1050}`
and the two `__DARWIN_SUF_*` strings; the baseline was re-recorded **on the
macOS oracle** and is **163 lines, byte-identical** from `sdk/` on Linux.

Three more defects were found and fixed:

1. **`scripts/sdk_stage.sh --verify` could not fail.** It re-staged the tree and
   *overwrote* `sdk/CHECKSUMS.sha256` before verifying, then compared that file
   against a second fetch of the same bytes. Measured: poison one row, run
   `--verify` with a cold cache, and it prints `all upstream files match their
   pinned tag` while silently deleting the poisoned row. A moved upstream tag
   would have been recorded as the new truth. It now force-re-fetches every one
   of the 332 files, treats the committed record as **read-only**, and dies with
   a diff. Re-tested both ways: honest tree passes, poisoned tree fails and the
   poison is still there afterwards.
2. **`CHECKSUMS.sha256` was not reproducible.** `sort -k3` used the caller's
   collation, so a restage on a differently-configured machine produced an
   18-line diff in which every hash was identical and only the order moved. Now
   `LC_ALL=C sort`, and the file has been regenerated in that order.
3. **`scripts/objc44.sh` was not executable** (mode 644) although the README
   documents it as a command.

### 9.4 What `sdk/` does **not** cover

This is the section the SDK milestone did not have, and a reader will want it
before trying to build anything real against `sdk/`.

| | Apple's `MacOSX26.1.sdk` | `sdk/` |
|---|---:|---:|
| `usr/include` headers | 3,470 | **355** (10%) |
| `usr/lib/*.tbd` | 529 | **3** (+3 symlinks) |
| `System/Library/Frameworks` | 294 | **0** |

The 355 are the set `vendor/objc4` and the ABI probe actually reach, plus their
transitive includes. Concretely, and measured by compiling a one-line TU against
`sdk/`, these do **not** exist and a guest that includes them will not build:

- `<signal.h>`, `<setjmp.h>`, `<dirent.h>`, `<complex.h>`, `<semaphore.h>`,
  `<regex.h>`, `<glob.h>`, `<fnmatch.h>`, `<langinfo.h>`, `<termios.h>`,
  `<poll.h>`, `<grp.h>`, `<pwd.h>`, `<utime.h>`, `<ftw.h>`, `<iconv.h>`.
  (`<sys/signal.h>` *is* staged; the C-standard spelling `<signal.h>` is not.)
- All of networking: `<netdb.h>`, `<sys/socket.h>`, `<netinet/*>`, `<arpa/*>`.
- `<sys/sysctl.h>`, `<sys/event.h>` (kqueue), `<sys/mount.h>`.
- `usr/include/c++/v1` — **deliberate**, and the one absence that is a decision
  rather than a gap: stock LLVM 18 libc++ with three `-D` flags substitutes for
  it, and `harness/Dockerfile` pins it.
- Every framework. There is no `CoreFoundation`, no `Foundation`, no
  `Objective-C` above `libobjc` itself. §7's steps 5–7 are unaffected by this
  milestone.
- Every `.tbd` except `libSystem.B`, `libobjc.A` and `libc++.1` — because those
  are the only three dylibs we implement. A guest that links anything else has
  nothing to link against.
- The MIG `__Request__*`/`__Reply__*` message structs, every availability
  *diagnostic*, and the `math.h` extensions listed in `sdk/PROVENANCE.md` §2.

Two smaller honesty notes on the provenance record itself:

- The 19 clean-room and 4 objc4 headers carry **no checksum row**, by design —
  git is the only thing vouching for them. That is stated in
  `CHECKSUMS.sha256`'s own header and is fine, but it means `--verify` covers
  332 of 355 files, not all of them.
- There is still **no offline check** that the committed `sdk/usr/include`
  matches `CHECKSUMS.sha256`, and there cannot be a naive one: the sums are of
  *pristine upstream* files, while 12 staged headers have their `//Begin-Libc`
  regions removed and 2 are patched. The available offline check is
  `scripts/sdk_stage.sh` followed by `git status sdk/usr/include`, which was run
  here and is clean.
- `--verify` re-stages `sdk/usr/include` as a side effect, so it is destructive
  on a dirty tree. Measured harmless on a clean one.

---

## 10. A precompiled Darwin binary draws (2026-08-26) — quartz as Mach-O

`docs/QUARTZ_MACHO.md` is the full accounting. The scoreboard entry:

| | |
|---|---|
| patches to `~/quartz`'s source | **0** (`patches-quartz/` is empty) |
| translation units | 37 compiled, 0 failures |
| `libquartz.dylib` | 507 exports, 65 undefined — 48 libSystem, 16 libc++, 1 `dyld_stub_binder` |
| fixture | `tests/bin/15_quartz`, plain C, **no Objective-C** |
| macOS, natively | 26861-byte PNG, sha256 `96aa747a85f6c35f…` |
| machorun on Linux | 26861-byte PNG, sha256 `96aa747a85f6c35f…` |
| per-stage checksums (9) | identical |
| regressions | none: 19 / 1 / 1 and 41/44 unchanged |

### What it cost on our side of the boundary

Zero patches to quartz moved the work into `darwin/` and `sdk/`, which is where
this project wants it. Three holes, none of which any previous consumer could
have found:

* **libm did not exist.** Darwin has no `-lm`; `libSystem.B.dylib` re-exports
  `libsystem_m.dylib`, so a guest that calls `cos()` has an undefined `_cos`
  against libSystem and nothing else. `darwin/src/math.c` is now 113 forwarded
  symbols. quartz reaches 13.
* **`libc++.1.dylib` was 14 symbols.** It is now 83, because LLVM 18's headers
  carry `extern template` declarations for `std::basic_string<char>`'s
  non-inline members, `__sort`, `to_string` and `__next_prime`, and on Linux the
  dylib that holds those copies is an ELF. Nine of the twelve are recovered by
  *explicit instantiation* rather than reimplementation, so they are LLVM's own
  code from LLVM's own headers.
* **`sdk/` was missing `_assert.h`.** `assert.h`'s `#include` of it sits behind
  `#ifndef NDEBUG`, `vendor/objc4` compiles `-DNDEBUG`, so the dangling include
  had been invisible since the SDK was assembled.

### The one that belongs in §8's spirit rather than §10's

`RTLD_DEFAULT` searches the **global scope**, so `src/resolve.c` can only reach
glibc libraries the loader itself has in `DT_NEEDED`. The loader's own C calls
nothing in libm, `--as-needed` dropped `libm.so.6`, and the first guest to call
`sin()` failed with a message naming libSystem rather than the loader. Fixed
with `-Wl,--no-as-needed -lm`; **the general form of this bug will recur for
every future forwarder**, and the symptom will always name the wrong layer.

### What this does not establish

1. It is **`QZ*`, not `CG*`**. No `CoreGraphics.framework` exists here and a
   guest linked against Apple's resolves none of its imports.
2. **34 of 507 exports are exercised** by `15_quartz`, and **36** by all three
   drawing fixtures together — rungs (o) and (p) added two.
   The Core Animation layer tree, text,
   image decode, PDF, patterns, shadings, CMYK, P3 and non-normal blend modes
   are compiled and untested here.
   (`docs/UNIMPLEMENTED.md#quartz-fixture-coverage`.)
3. **One libm workload agreed.** IEEE 754 says nothing about `sin`, `cos`,
   `pow` or `exp`; the fixture is structured so that the stage which would
   disagree names itself on stdout. (`docs/UNIMPLEMENTED.md#libm-ulp`.)

### Effect on §7

§7 step 7 — "then, and only then, CoreGraphics/CoreAnimation (`~/quartz`)" —
turns out to have been **in the wrong order**, and cheaply so. The engine
underneath CoreGraphics runs today, before Foundation, before UIKit, and without
any Objective-C at all, because it is portable C++ and does not need the ObjC
runtime to rasterise. What §7 step 7 really describes is the *CoreGraphics
facade over it*, which is still unwritten and still after steps 5–6.

§7's `~/uikit` bullet is reported to be stronger than "swiftc on Linux emits
ELF": `swiftc -target arm64-apple-macos11` on Linux is said to fail with
*"unable to load standard library for target"*, i.e. it cannot emit Mach-O at
all, for any input. **That is second-hand here and was not re-measured for this
section** — `harness/Dockerfile`'s testbed has no swiftc, so there was nothing
to run it on. It should be re-measured and recorded properly before anything is
planned around it.

> **Re-measured, and half of it was wrong — see §11.5.** The error message is
> real and reproduces exactly. The inference drawn from it does not: swiftc on
> Linux emits perfectly good arm64 **Mach-O** objects when told `-parse-stdlib`.
> What is missing is a Darwin standard *library* (`/usr/lib/swift/` has `linux`
> and `embedded`, no `macosx`), not Mach-O code generation. The conclusion for
> OpenUIKit is unchanged; the cost model is not.

If it holds, OpenUIKit cannot be built as a Mach-O dylib by any amount of work
on this side, and needs either Swift-to-Mach-O to become possible or machorun to
gain ELF-dylib bridging. Either way it is why this milestone went through
`~/quartz`, which is C++ and therefore buildable by the same
`clang -target arm64-apple-macos11` route that objc4 already uses.

---

## 11. Third independent verification (2026-08-26) — the drawing milestone

Re-measured by a third agent that wrote neither the loader, nor `sdk/`, nor the
quartz port, from a **fresh `git clone` into an empty directory**, with the
Linux build run in a container started `--network none` and with only the clone
mounted. Every number below was produced by that run. §10 is left as its author
wrote it; where it did not survive contact the correction is here.

The headline: **it reproduces, and the drawing gate can fail.** The one claim
that did *not* survive is not about the loader at all — it is the Swift scoping
fact, and it was wrong in a way that matters (§11.5).

### 11.1 The gates reproduce, from a clone

| gate | result | exit |
|---|---|---|
| `scripts/build.sh everything`, `--network none`, clone-only mount | loader, 4 dylibs, 4 `.tbd`s; **32 objc4 objects / 0 failures**, **37 quartz objects / 0 failures**, 0 quartz patches, 4 objc4 patches | 0 |
| `scripts/difftest.sh` after that build | **19 pass / 0 fail / 1 xfail / 0 xpass / 0 skipped / 1 no-oracle / 0 drift** | 0 |
| `scripts/objc44.sh` (in the container) | **41/44**, failing exactly `038-exceptions`, `042-dlopen`, `044-exception-through-uncached`, each with its documented loud abort | 1 |
| `scripts/quartz_pixel.sh` (macOS host, drives docker) | **pass 3 / fail 0 / baseline-drift 0** | 0 |

```
                      macOS, natively            machorun on Linux/arm64
15_quartz             26861  96aa747a85f6c35f    26861  96aa747a85f6c35f
16_objc_quartz         2678  32a7e67a4139e108     2678  32a7e67a4139e108
17_objc_shapes        11909  a7ca5744d100b911    11909  a7ca5744d100b911
stage checksums       identical (9 / 3 / 5)      exit 0 / 0 everywhere
```

Two virgin-clone behaviours, measured on a second clone that had never been
built:

* `scripts/difftest.sh` alone gives **18 pass / 1 FAIL / 1 xfail / 1 no-oracle**,
  exit 1, with `09_objc` red for want of a `libobjc.A.dylib` nobody built. That
  is exactly what §9.1 and the README say, re-confirmed.
* `scripts/quartz_pixel.sh` alone gives **3/3 PASS, exit 0** on a virgin clone.
  Unlike `difftest.sh` it *is* self-sufficient: its container script builds the
  loader, `darwin/`, objc4 and quartz itself before running anything. Worth
  knowing, and not previously written down.

### 11.2 The two sides are genuinely two different builds

A pixel-identity result is only interesting if the two runs are not secretly the
same artefact. Measured on the clone:

| | oracle (macOS) | machorun (Linux) |
|---|---|---|
| `libquartz.dylib` | `build/quartz-macos/`, Apple clang++ 17 against Apple's SDK | `darwin/usr/lib/`, clang-18 against `sdk/`, linked by `ld64.lld-18` |
| size / sha256 | 388832 `f88a801dda58af87…` | 388480 `4284f43215b85706…` |
| ObjC runtime | Apple's shipping `libobjc` in the dyld shared cache | our Mach-O build of Apple's objc4 |

`DYLD_PRINT_LIBRARIES` confirms the oracle loads `build/quartz-macos/libquartz.dylib`
and not `/usr/lib/...`; nothing is installed on the macOS host. The oracle
library's own `otool -L` is `libquartz` + `libc++.1` + `libSystem.B` and it has
**zero** undefined `_CG*`/`_CA*`/`_CF*`/`_NS*` symbols, so no Apple framework is
in the comparison. (`QuartzCore` shows up in `DYLD_PRINT_LIBRARIES` output — it
also shows up for `02_main_ret`, which draws nothing. It is dyld's own baseline
set on this OS, immediately "moved to delayed", and not a dependency of anything
here.)

### 11.3 Can the drawing gate fail? — four mutations, four kills

The PNG comparison was attacked directly. Each mutation was applied to the
*Linux* side only and graded with `scripts/quartz_pixel.sh --linux`, i.e.
against the **committed macOS baseline**, so a mutation that both sides shared
could not hide.

| # | mutation | where | result |
|---|---|---|---|
| M1 | AA scanline sampled one row down (`ys = y + 1 + (s+0.5)/ss`) | `vendor/quartz/src/qz_raster.cpp` | **FAIL**, exit 1. Diverges at stage 2; 4246 of 65536 pixels differ, bbox y 10..255 |
| M2 | **one pixel, one channel, one level**: `if (x==100 && y==100) p[0]++` | same file | **FAIL**, exit 1. `differing pixels: 1 of 65536 (0.0015%)`, bbox `x 100..100 y 100..100`, `max channel delta: R=1` |
| M3 | `attachCategories()` returns immediately | `vendor/objc4/runtime/objc-runtime-new.mm` | `16_objc_quartz` **PASS**, `17_objc_shapes` **FAIL** |
| M4 | a non-root class's own method list is invisible, so every override falls through to the superclass | same file | `16_objc_quartz` **PASS**, `17_objc_shapes` **FAIL** |

M2 is the answer to "would a one-pixel change actually fail?". It fails, and
`harness/pngdiff.c` localises it to the single pixel and even classifies it
correctly as a ±1 story rather than a wrong shape. The PNG comparison is real.

M3 and M4 are the answer to "is the ObjC fixture genuinely exercising ObjC?".
Both are caught, and the bisection `16_objc_quartz` was built to provide works
exactly as its header claims: the smoke fixture, which has one root class and no
inheritance and no category, stays byte-identical under both, so the failure is
localised to what `17` adds before anything is read.

They are caught in the right *place*, too:

* M3 diverges on stdout at `responds Circle.badgeInContext:=0` — before a pixel
  is drawn — then dies loudly at `-[Shape badgeInContext:]: unrecognized
  selector`, exit 71 against the oracle's 0.
* M4 diverges at `stage 2 polymorphic fnv1a=2da484f8…` against the baseline's
  `5e1180647bb7a073`. That is a **framebuffer** checksum: the picture changed
  because the override did not dispatch. `item 1 shape` where the baseline says
  `item 1 circle` confirms it. So yes — the overridden method really is
  dispatched dynamically, and the pixels really do depend on it.

The tree was restored and re-verified clean after each mutation.

### 11.4 The baselines are Darwin's — and Linux cannot write them

For the drawing fixtures, **the git-ordering argument of §2 does not apply**:
`tests/expected/15_quartz.png` was committed in `9253385` together with the
fixture, long after the loader existed, and `16`/`17` in `567dfbc`. What vouches
for them instead, all re-measured:

1. **The fixtures are Apple's.** `tests/bin/{15,16,17}` carry `LC_BUILD_VERSION
   platform 1 (macOS), sdk 26.1` — Apple's Xcode SDK, which does not exist on
   the Linux side of this project at all.
2. **The oracle is re-executed every run.** `scripts/quartz_pixel.sh` in `both`
   mode ran the three binaries natively on macOS and compared before grading:
   `oracle vs baseline matches committed baseline`, three times.
3. **Re-run by hand, outside the harness.** All three were executed directly on
   macOS with the harness out of the picture: PNG and stdout byte-identical to
   the committed baselines.
4. **A tampered baseline cannot be scored PASS.** One byte of
   `tests/expected/15_quartz.png` was flipped and the full gate re-run. Verdict
   `BASELINE-DRIFT`, exit 1, *even though Linux matched the live oracle exactly*
   — and `pngdiff` correctly reported "pixels IDENTICAL, the file bytes differ
   but the image does not… that is a PNG ENCODER difference". A mismatch is
   reported, never absorbed.
5. **Linux physically cannot record.** In the container: `quartz_pixel.sh
   --record`, `harness/run_macos.sh --record` and `harness/run_linux.sh
   --record` all refuse on `uname -s`, and `tests/expected` is bind-mounted
   read-only *on top of* the writable `/work` mount, so `printf >>`, `touch` and
   `cp` onto a baseline all fail with `Read-only file system`. The baseline's
   sha256 is unchanged afterwards. Enforced by the kernel, not by policy.

### 11.5 The correction that matters: **"Swift cannot emit Mach-O on Linux" is false**

§10 and `docs/QUARTZ_MACHO.md` §7.5 both flag the OpenUIKit scoping claim as
second-hand and ask for it to be re-measured. It was, first-hand, on the
official `swift:6.2-noble` image, `--platform linux/arm64`, `--network none`:

```
$ swiftc --version
Swift version 6.2.4 (swift-6.2.4-RELEASE)   Target: aarch64-unknown-linux-gnu

$ swiftc -target arm64-apple-macos11 -c t.swift
<unknown>:0: error: unable to load standard library for target 'arm64-apple-macos11'

$ swiftc -parse-stdlib -target arm64-apple-macos11 -c bare.swift -o bare.o
$ od -t x1 -N 8 bare.o
 cf fa ed fe 0c 00 00 01           # Mach-O 64-bit object arm64
$ swiftc -parse-stdlib -target aarch64-unknown-linux-gnu -c bare.swift -o l.o
 7f 45 4c 46 02 01 01 03           # ELF, as a control
```

**The Swift compiler on Linux emits perfectly good arm64 Mach-O objects.** The
backend is not the wall. The wall is that the Linux toolchain ships no Darwin
**standard library**: `/usr/lib/swift/` contains `linux` and `embedded` and no
`macosx`, so any source that names `Int`, `String` or `print` — which is all of
OpenUIKit — cannot be type-checked for a Darwin triple.

That is a distribution and ABI problem, not a code-generation one, and it
changes the shape of the work:

* It is **not** fixed by anything machorun does.
* It **could** be fixed by cross-building the Swift standard library and runtime
  for `arm64-apple-macos` on Linux. That needs a Darwin SDK (which this
  repository deliberately does not have — `sdk/` is 356 headers against Apple's
  3,470 and zero frameworks), a Mach-O link of `libswiftCore` itself, and then
  `libswiftCore`'s own demands on libSystem, `libobjc` and Foundation, most of
  which are unimplemented here. `docs/UNIMPLEMENTED.md#swift-interop` is the
  near end of that list.
* It could also be sidestepped by copying Apple's `libswiftCore.dylib` and
  `.swiftinterface`s from macOS, which would end the self-hosting property and
  is therefore not a route this repository can take.
* Or by machorun gaining **ELF-dylib bridging**, so a Mach-O guest could bind
  against an ELF OpenUIKit. That is the option that does not need Apple's bits,
  and `docs/UNIMPLEMENTED.md#objc-callbacks` already contains a withdrawn design
  for the mechanism.

And it is not the only wall in front of OpenUIKit: its Objective-C facade is
compiled `-fobjc-runtime=gnustep-2.2`, a different `struct objc_class` from the
one a precompiled Darwin binary carries. Fixing the stdlib would not fix that.

**So: OpenUIKit is not part of this milestone and cannot be, today.** What runs
is `~/quartz` — the C++ engine OpenUIKit itself sits on — and nothing above it.

### 11.6 Self-hosting still holds, with quartz in the tree

- The test-bed image was searched: **no `MacOSX*.sdk`, no `.tbd`, no
  `/Applications`, no `xcrun`, no `xcodebuild`, no `swiftc`.** Ubuntu clang
  18.1.3 and Ubuntu LLD 18.1.3.
- `scripts/build.sh everything` with `--network none` and only the clone
  mounted: 39 seconds, all four dylibs, all four `.tbd`s, `0 unresolved`.
  DNS resolution inside that container fails, as it should.
- `scripts/build_quartz.sh` takes `-isysroot $ROOT/sdk` and nothing else.
  `vendor/quartz` contains no `__APPLE__` conditional, no Apple header, no
  absolute host path.
- Every `xcrun` in the repository is still on the oracle side only:
  `build_quartz_macos.sh`, `tests/build_fixtures.sh`, `sdk_abi_probe.sh
  --record`, and the two committed-output table generators. All refuse off
  Darwin.
- `scripts/vendor_quartz.sh --verify`: **71 files match `CHECKSUMS.sha256`**.
  It was attacked the way `sdk_stage.sh --verify` was in §9.3 — poison one byte,
  re-run — and it fails with a diff, exits 1, and leaves the poison in place
  rather than recording it as the new truth. `--diff` against `~/quartz` is
  empty: the vendored tree is byte-identical to upstream, and upstream was not
  modified.

### 11.7 Numbers in the prose that had drifted

Measured on this build; the docs said otherwise and have been corrected.

| claim | said | measured |
|---|---|---|
| `sdk/usr/include` census | README: "356 headers, of which 337 … 4 from objc4 … 19 clean-room" (sums to 360) | **356** = 332 upstream + **1 generated** + 4 objc4 + 19 clean-room; `CHECKSUMS.sha256` covers **333** of them |
| §9's census | "355 … 332 + 19 + 4" (sums to 355, omits the generated header) | same 356 as above |
| `libSystem.B.dylib` exports | README §5: 242, of which 86 referenced | **441** exported, **89** referenced by at least one fixture — **352 (80%) compiled and untested** |
| `libSystem.B.tbd` symbols | README: 342 | **463** (441 exports + 22 loader-defined, `darwin/loader-exports.txt`) |
| `libobjc.A.dylib` exports | — | **418**, of which **116** are reached by `tests/objc44/` and 13 by the drawing fixtures (a subset) |
| `libquartz.dylib` exports | 507, 34 exercised | **507**, **36** exercised by the three drawing fixtures together |

The libSystem row is the one to read twice. Hosting quartz nearly doubled the
export surface (libm alone is 113 symbols) while the fixture corpus grew by
three, so **the single biggest gap between "green" and "correct" got wider, not
narrower** — 64% untested became 80% untested. That is the honest cost of the
milestone and it belongs next to the pixel result, not below it.

### 11.8 Two harness nits, and what this verification did *not* find

Found:

1. When the Linux side produces no PNG, `scripts/quartz_pixel.sh:272` runs
   `wc -c` on a missing file and lets bash's `No such file or directory` onto
   stderr before printing the row. Cosmetic — the verdict is still a correct
   FAIL with the reason printed — but it is noise on exactly the run a reader is
   trying to diagnose.
2. `scripts/objc44.sh` exits **1** on 41/44, which is right, but the three
   failures are its *documented* expected state. There is no XFAIL concept in
   that runner, so "the corpus is where we left it" and "the corpus regressed"
   are the same exit code. `difftest.sh` distinguishes these; `objc44.sh` cannot.

Not found, and worth saying explicitly: **no discrepancy in any headline
number.** Every figure in §10 and in `docs/QUARTZ_MACHO.md` reproduced. The
mutation survivors of §3 were not re-tested here and are assumed to stand; the
coverage limits in `docs/UNIMPLEMENTED.md#quartz-fixture-coverage` and
`#objc-drawing-coverage` were re-measured and are exactly right (36 of 507).

### 11.9 What now runs end to end, and what it does not cover

**Runs.** A precompiled arm64 Mach-O executable, built on macOS by Apple's
clang against Apple's SDK, never relinked, is mapped and fixed up by our loader
on Linux/arm64; binds against our Mach-O `libSystem.B.dylib`, our Mach-O build
of Apple's objc4, our Mach-O build of LLVM's libc++ out-of-line members, and
`~/quartz` built as a Mach-O dylib from unpatched sources; registers its
classes, categories and protocols through dyld's ObjC image-notify protocol;
runs `+load` before `main`; dispatches `objc_msgSend` and `objc_msgSendSuper2`
polymorphically over a heterogeneous collection; rasterises through a CPU
rasteriser that reaches libm; encodes a PNG; and writes a file whose bytes are
**identical** to the bytes the same binary writes on macOS.

**Does not cover**, and none of this is implied by the green:

* **`QZ*`, not `CG*`.** There is no `CoreGraphics.framework`, no
  `CoreFoundation`, no `Foundation`, no `UIKit`. A binary linked against Apple's
  frameworks resolves none of its imports.
* **No Swift, no OpenUIKit** — §11.5.
* **No exceptions and no `dlopen`** — the three `objc44` failures, both loud.
* **80% of libSystem, 72% of libobjc and 93% of libquartz are untested here** —
  §11.7.
* **No window, no display, no compositor.** "Draws" means "rasterises to a
  bitmap and writes a PNG". There is no `UIScreen` path and nothing puts a pixel
  on a screen.
* **No arm64e, no FairPlay, no App Store app.** Unchanged from §6.
