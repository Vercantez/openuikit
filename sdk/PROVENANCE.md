# sdk/ — where every byte came from, and what we wrote ourselves

`scripts/build_objc4.sh` used to need `-isysroot` pointing at Apple's macOS SDK.
That was a **non-redistributable build input**: `docs/OBJC4_MACHO.md` §7 called it
the single biggest thing that got harder when objc4 moved from ELF to Mach-O,
and `docs/UNIMPLEMENTED.md` recorded that the build was reproducible on a machine
with Xcode and not otherwise.

This directory replaces it. **Xcode is no longer a build input.**

```
sdk/
  MANIFEST.tsv        379 rows: header path -> where it comes from
  SOURCES.tsv         11 pinned apple-oss-distributions releases + licences
  CHECKSUMS.sha256    sha256 of every upstream file, with its upstream path
  patches/            2 patches, each explaining what the published tree dropped
  local/              19 clean-room headers of ours (4,396 lines)
  tests/              the ABI probe, and its macOS baseline
  usr/include/        379 headers, 3.4 MB -- COMMITTED
  usr/lib/*.tbd       3 stubs + 3 symlinks -- GENERATED, gitignored
```

Regenerate with `scripts/sdk_stage.sh`; re-derive the stubs with
`scripts/gen_tbd.sh`; prove it against Apple's SDK with `scripts/sdk_abi_probe.sh`.

---

## 1. The census

| source | headers | licence | redistributable |
|---|---:|---|---|
| **xnu** | 220 | APSL 2.0 | yes |
| **Libc** | 74 | APSL 2.0 | yes |
| **libdispatch** | 21 | Apache 2.0 | yes |
| **libpthread** | 19 | APSL 2.0 | yes |
| **libplatform** | 6 | APSL 2.0 | yes |
| **libmalloc** | 5 | APSL 2.0 | yes |
| **cctools** | 5 | APSL 2.0 | yes |
| **libunwind** | 2 | Apache 2.0 w/ LLVM exception | yes |
| **dyld** | 2 | APSL 2.0 | yes |
| **libclosure** | 1 | APSL 2.0 | yes |
| **xnu, via its own published generator** | 1 | APSL 2.0 | yes |
| **objc4** (`vendor/objc4/runtime/`) | 4 | APSL 2.0 | yes |
| **ours, clean-room** (`sdk/local/`) | 19 | this project's | — |
| | **379** | | |

Exact tags are in `sdk/SOURCES.tsv`. Per-file sha256 with the upstream path is in
`sdk/CHECKSUMS.sha256`; `scripts/sdk_stage.sh --verify` re-fetches and checks them.

### The 356th header, and the shape of hole it was

`_assert.h` was added on 2026-08-26. It is worth a paragraph because it is an
example of the closure being measured against **one** consumer and therefore
being complete only for that consumer.

`sdk/usr/include/assert.h` is Apple's real Libc header, and its `NDEBUG` branch
reads:

```c
#ifdef NDEBUG
#define	assert(e)	((void)0)
#else
#include <_assert.h>
```

`vendor/objc4` is compiled `-DNDEBUG`, so nothing in this repository had ever
taken the second branch: `assert.h` was staged, its own `#include` dangled, and
no build noticed. `vendor/quartz` compiles `third_party/stb_*.h`, which include
`<assert.h>` unconditionally, and three translation units failed with
`'_assert.h' file not found, did you mean 'assert.h'?`.

Adding the row is the whole fix (`Libc:include/_assert.h`, same pinned tag; the
restage changed exactly one line of `CHECKSUMS.sha256` and added exactly one
file). The transferable part is the lesson: **a staged header set is only closed
over the preprocessor branches its consumers actually take.** A second consumer
with different `-D` flags is the cheapest way to find the next one, which is an
argument for hosting more than one library here rather than a cost of doing so.

The header alone would only have moved the failure: the non-`NDEBUG` branch
calls `__assert_rtn`, which `libSystem.B.dylib` did not export either. It does
now (`darwin/src/posix.c`), reproducing Libc's exact message text — a guest's
stderr is compared byte-for-byte against macOS, so "Assertion failed: (e),
function f, file x.c, line 12." is an ABI string and not a nicety.

### The 357th through 366th, and the same lesson from a third consumer

CoreFoundation asks for two headers nothing here had needed: `CFLocale` includes
`sys/mount.h` and `CFTimeZone` includes `dirent.h`. Neither was staged, and
neither is one file — the include closure pulled in ten rows in total
(`dirent.h`, `sys/dirent.h`, `sys/mount.h`, `sys/attr.h`, `sys/ucred.h`,
`sys/queue.h`, `bsm/audit.h`, and `sys/_types/_{graftdmg_un,mount_t,vnode_t}.h`),
all from the already-pinned xnu and Libc tags. The restage added exactly those
ten files and changed no existing header, which is the offline integrity check
this tree relies on.

`struct statfs` is the reason this got a differential rather than a compile
check. It is one of the `$INODE64`-variant structures, so a sysroot that got
`__DARWIN_ONLY_64_BIT_INO_T` or the xnu platform selection wrong would produce a
*differently shaped* `statfs` and still compile — the same silent-wrong-value
family as §2.1. So `sdk/tests/abi_probe.c` now probes `struct statfs` and
`struct dirent`, and the baseline recorded against **Apple's** SDK matches ours
byte-for-byte: `sizeof struct statfs` 2168, `sizeof struct dirent` 1048, and
every offset in both, 188 lines identical.

Third consumer, third gap, and the pattern from `_assert.h` holds exactly:
objc4 found none of these because it includes none of them.

### The 367th through 376th: `kinfo_proc`, `tzhead`, and a closure found by diffing Apple

`CFUtilities` wants `struct kinfo_proc` and `KERN_PROC_PID`; `CFTimeZone` wants
`struct tzhead`. Those live in `sys/sysctl.h` and `tzfile.h`, and the closure
around them brought `sys/proc.h`, `sys/event.h`, `sys/lock.h`, `sys/vm.h`,
`sys/socket.h`, `netinet/in.h`, `search.h` and `spawn.h` — ten rows, all from
the already-pinned xnu and Libc tags. Two upstream paths are worth recording
because they are not where one would guess: Darwin's `tzfile.h` is
`Libc:stdtime/FreeBSD/tzfile.h`, and the public `spawn.h` is
`xnu:libsyscall/wrappers/spawn/spawn.h`, not anything under `Libc/include`.

**The closure was computed by diffing Apple, not by iterating on errors.**
Compiling the target headers against Apple's SDK with `-H` lists the 134
headers it pulls; three of them (`sys/event.h`, `sys/lock.h`, `sys/vm.h`) were
absent here. That is one measurement instead of a restage-per-error loop, and
it also proves the closure is *Apple's*, not merely one that happens to compile.

`struct kinfo_proc` is the reason this needed a differential rather than a
compile check, and it is the sharpest case yet for that rule: 648 bytes of
nested `extern_proc` and `eproc` with embedded `timeval`, `rusage`, `pcred` and
`ucred`. A hand-written version — or a subtly different xnu revision — would
compile clean and be wrong somewhere in the middle. `abi_probe` now baselines it
against Apple's SDK: sizes for `kinfo_proc`/`extern_proc`/`eproc`/`tzhead`,
offsets including `extern_proc.p_comm` at 243 and `eproc.e_ucred` at 120, and
the `CTL_KERN`/`KERN_PROC`/`KERN_PROC_PID` constants. 212 lines identical.

**`spawn.h` is staged and deliberately unimplemented.** `posix_spawn` is
declared and defined nowhere, so a guest that calls it fails at load with a
named undefined symbol — the same late-but-loud shape as `mach_msg`. This is
NOT the declaration-only census shim, and it must not become a forward:
`posix_spawnattr_t` is 8 bytes on Darwin and 336 in glibc, so forwarding
destroys 328 bytes of guest stack and returns success
(`docs/UNIMPLEMENTED.md#posix-spawn`).

### The three with no oracle: the QoS private headers

`pthread/qos_private.h`, `sys/qos_private.h` (libpthread) and
`pthread/priority_private.h` (xnu) are the only headers here that **cannot be
checked against Apple's SDK**, because Apple does not ship them — verified
absent from MacOSX15.4. Everything else in this tree is provable by compiling
the same source both sides; these are not, so they get
`sdk/tests/qos_probe.c` instead, which substitutes three weaker checks for the
one strong one:

1. **against the public header they extend.** Apple ships `sys/qos.h`, and the
   private headers add to its `qos_class_t` rather than replacing it, so every
   shared enumerator must agree. A mismatched revision shows up here.
2. **cross-project.** The QoS values are libpthread's and the encoding that
   consumes them is xnu's — two separately versioned projects that must agree
   or Apple's own build breaks. `_pthread_priority_make_from_thread_qos()`
   encodes one-hot at `SHIFT + qos - 1`, so every representable class has to
   land inside `_PTHREAD_PRIORITY_QOS_CLASS_MASK`, and the class mask must not
   overlap the relative-priority field beside it.
3. **pinned constants**, so upstream drift fails the build.

Why this earns a whole probe: `_PTHREAD_PRIORITY_QOS_CLASS_SHIFT` is 8, which
makes an 8-bit mask the natural guess, and the real
`_PTHREAD_PRIORITY_QOS_CLASS_MASK` is `0x003fff00` — **fourteen** bits. A port
that invented `0x0000ff00` would mis-encode every queue priority silently,
because nothing checks an encoding against a value it produced itself. Teeth
verified by substituting exactly that guess: the probe fails with
`4194048U == 65280U`.

**One limitation, stated rather than hidden.** `THREAD_QOS_LAST` is *used* by
`priority_private.h:232` and *defined* in no published Apple source — not
`osfmk/mach/thread_policy.h`, not `osfmk/kern/kern_types.h`. It lives in a
kernel-private header. So the three `static inline` encoders in that file
compile, because nothing instantiates them, but cannot be called from a guest.
libdispatch does not call them; a port that does gets an undeclared-identifier
error at its own call site, which is at least loud.

Still absent, and it needs a decision rather than a row: **`netdb.h` is not in
xnu or Libc.** Darwin's lives in `Libinfo`, which is not one of the 11 pinned
releases, so staging it means adding a twelfth upstream source.

**No header in this tree was copied from Apple's Xcode SDK.** A staged copy of
MacOSX15.4's `usr/include` exists at `build/sdk/` on the machine this was
assembled on, and it was used the way this project uses macOS everywhere else —
**as an oracle to diff against**, never as a source. Every use of it is a
measurement reported below.

### Licence markers, counted in the staged tree

```
@APPLE_OSREFERENCE_LICENSE_HEADER   211   (xnu's APSL 2.0 form)
@APPLE_LICENSE_HEADER                77   (APSL)
Apache License                       23
BSD "Redistribution and use..."      51
none, copyright line only             9   Block.h, stdint.h, machine/limits.h,
                                          os/{clock,workgroup_base}.h,
                                          arm/{_limits,_param,_types,signal}.h
```

The nine carry only a copyright line upstream too; they inherit their
repository's licence. `machine/limits.h` says of itself "This file is public
domain."

---

## 2. The 19 clean-room headers, and exactly what each omits

Each file's own header comment carries the long form. This is the index.

### 2.1 The availability family (7 files)

`TargetConditionals.h`, `Availability.h`, `AvailabilityInternal.h`,
`AvailabilityInternalLegacy.h`, `AvailabilityMacros.h`,
`AvailabilityVersions.h`, `os/availability.h`.

Apple's seven are **10,786 lines / 782 KB** defining **2,648 macros**, and
`docs/SDK_SURVEY.md` §2.4 measured that only **71** of those macros are
referenced by anything we compile. Three of the seven match nothing upstream;
three more match only a stale xnu `EXTERNAL_HEADERS` snapshot (`Availability.h`
is 47% line-identical to the SDK's).

**The one design decision.** Every availability *attribute* expands to nothing.
Apple's machinery exists to emit `__attribute__((availability(...)))`, which is a
compile-time **diagnostic**: it changes no code generation, no symbol name, no
struct layout, no calling convention. machorun ships no public API whose
availability anyone checks.

**What survives is the arithmetic.** `__MAC_10_13` and its 1,051 siblings keep
their real values, because vendored headers compare against them inside `#if`
and a wrong number there *does* change what compiles. Those values are generated
by `sdk/local/gen_availability.py` from the encoding rule (macOS 10.0–10.9 is
`major*100 + minor*10 + patch`; everything else is `major*10000 + minor*100 +
patch` — which is why `__MAC_10_6` is 1060 but `__MAC_10_13` is 101300).

**Verified, not asserted.** Of the 262 constants our generated files and Apple's
SDK both define, **0 mismatch**. The 62 Apple defines that we do not are
bridgeOS patch releases and DriverKit 20+, none referenced by anything here.

**Omitted versus Apple's:** every deprecation and unavailability warning; the
`API_*_BEGIN/_END` scoped forms are accepted and ignored rather than applied to a
region; the Swift-availability plumbing is accepted and ignored;
`TargetConditionals.h` drops the pre-clang-3 fallback ladder (we require
`__is_target_os`) and the remaining internal-platform flags (`TARGET_OS_RTKIT`,
`TARGET_OS_EXCLAVEKIT`, `TARGET_OS_UIKITFORMAC`).

**`TARGET_OS_*`: five macros added, and where their values come from.**
CoreFoundation is the third consumer of this sysroot, and it found a gap the
first two could not: it compiles with `-Wundef-prefix=TARGET_OS` promoted to an
**error** and tests platform macros with `#if`, so a macro we omit fails all 86
CF translation units rather than quietly evaluating to 0.

- `TARGET_OS_NANO` **is** Apple's, and was wrongly on the omit-list above. It is
  not an internal-platform flag but a deprecated alias: Apple's header documents
  it as *"DEPRECATED: Same as `TARGET_OS_WATCH`"* and defines it as exactly that,
  behind the same `#ifndef` we now use.
- `TARGET_OS_WASI`, `TARGET_OS_ANDROID`, `TARGET_OS_BSD`, `TARGET_OS_CYGWIN` are
  **not Apple's at all** — verified, zero definitions of each in Apple's
  `TargetConditionals.h`. They are swift-corelibs-foundation's own additions for
  selecting a non-Darwin branch. On a Darwin target the correct value is not
  "unknown" but **0**, so they join the existing not-Darwin block.

Verified rather than asserted, by `sdk/tests/target_os_probe.c`, which
`scripts/sdk_abi_probe.sh` now compiles on **both** sides: on macOS against
**Apple's own SDK**, so a value we assert that Apple disagrees with fails the
build there (green against MacOSX15.4 and MacOSX26.1); and on Linux against
`sdk/` alone with no `-D`, which is the half that reproduces CF's build
condition. It is compile-only — `#if` for every macro under `-Werror` catches a
**missing** one, and `_Static_assert` on the target-decided values catches a
**wrong** one. The wrong-value case is the dangerous one: it compiles clean and
silently selects CF's WASI or Android branch.

**The probe also covers the other constants only the preprocessor sees.**
`sdk/tests/abi_probe.c` diffs everything a program can *print*; it structurally
cannot see a constant that `#if` consumes and discards, because by then the
decision is already taken. That blind spot has cost this project twice, both
under §3's `0002-xnu-platform-macosx.patch`: `__DARWIN_ONLY_UNIX_CONFORMANCE`
going undefined renamed every `__DARWIN_ALIAS`'d libc function (surfacing as 7
undefined `$UNIX2003` symbols in libobjc), and `MACH_VM_MAX_ADDRESS` silently
dropping to the **embedded 64 GiB** value instead of macOS's 128 TiB, with
nothing failing to compile. Until now both were guarded only by that patch and
nothing asserted the outcome — the patch said what we did, and nothing said what
it had to achieve. The probe now asserts `MACH_VM_MAX_ADDRESS`,
`__DARWIN_ONLY_UNIX_CONFORMANCE`, `__DARWIN_ONLY_64_BIT_INO_T`, and the
`TARGET_CPU_*` / `TARGET_RT_*` halves of `TargetConditionals.h`.
`MACH_VM_MAX_ADDRESS` is load-bearing twice over: objc4 sizes `ISA_MASK` and
`FAST_DATA_MASK` against it (`docs/UNIMPLEMENTED.md#isa-va-width`), so a wrong
value there does not fail — it changes which isa layout compiles.

Verified to have teeth rather than merely to pass: substituting the embedded
`0x0000000FFFFFF000` fails with *"MACH_VM_MAX_ADDRESS must be macOS's 128 TiB
value"*, and flipping the conformance assertion fails likewise. The values are
hard-coded on purpose — compiled against Apple's SDK on the oracle side, a
number Apple moves fails the build there and gets reported, which is this repo's
rule everywhere else: drift is noticed, not absorbed.

### 2.2 `sys/_symbol_aliasing.h`

Upstream *does* publish its generator, `xnu:bsd/sys/make_symbol_aliasing.sh` —
but that script's first act is to run `<sdk>/usr/local/libexec/availability.pl`,
which ships only in Apple's **internal** SDK. It is in neither the public SDK nor
any published repository, so the generator cannot be run. Ours is generated by
`sdk/local/gen_availability.py` from the same version table as
`AvailabilityVersions.h`.

Its contract is simple and fully reproduced: `__DARWIN_ALIAS_STARTING_MAC___MAC_10_6(x)`
expands to `x` when the deployment target is at least 10.6 and to nothing
otherwise, which is what selects the `$UNIX2003` / `$INODE64` symbol variants.

Its sibling `sys/_posix_availability.h` **is** category (a): the published
`make_posix_availability.sh` runs, and its output is **byte-identical** to
Apple's SDK copy. `sdk_stage.sh` runs it rather than shipping a transcription.

### 2.3 The 10 MIG stand-ins

`mach/{clock_priv,host_priv,host_security,mach_host,mach_port,processor,processor_set,task,thread_act,vm_map}.h`

Apple's copies carry no licence block because nobody wrote them — they are MIG
output. All ten `.defs` inputs are published in xnu, but running MIG means
porting a Mach-specific code generator to Linux. `docs/SDK_SURVEY.md` §2.3
measured the alternative: the ten headers declare **237** routines, the whole
test corpus links against **10** Mach symbols, and objc4's source names **6**.
So they are hand-written, exactly as `vendor/objc4-priv/` already is for 25 SPI
headers.

**The rule these files follow:** a routine is declared only if
`darwin/usr/lib/libSystem.B.dylib` exports it. A Mach routine we have not
implemented is *absent*, so calling it is an undeclared-identifier error at
compile time rather than a missing symbol at load time.

**The one exception is written down where it lives:** `mach/thread_act.h`
declares `thread_get_state`, which we do not implement, because objc4's
`objc-cache.mm` needs the declaration to compile. That is safe and *measured*:
the resulting `libobjc.A.dylib` does not import `_thread_get_state`, because the
caller is unreachable and the optimiser drops it. `scripts/gen_tbd.sh` re-checks
that on every build.

**Omitted versus MIG's output:** the `__Request__*_t` / `__Reply__*_t` message
structs, the `*_MSG_COUNT` constants, the AUTOTEST function tables, and every
routine we do not implement. None of that is ABI here: those structs are the
on-the-wire form of a Mach RPC, and machorun does no Mach RPC —
`darwin/src/mach.c` services these calls directly.

### 2.4 `math.h` — a correction to the survey

`docs/SDK_SURVEY.md` headlined that *"the genuinely-only-in-the-Xcode-SDK
category is empty."* **It is off by one, and `math.h` is the one.**

The survey put `math.h` in category (a) on a path match against
`apple-oss-distributions/Libm`. Staging it and compiling disproved that, loudly:

```
sdk/usr/include/math.h:32:2: error: Unknown architecture
```

Libm's published `Source/math.h` is a five-line dispatcher to
`architecture/{ppc,i386,arm}/math.h`, all three of them 2002-era files for
32-bit architectures. `__arm64__` is not `__arm__`, so it falls through to its
own `#error`. Libm has shipped no release since; the modern 802-line `math.h`
comes from Apple's closed libm. A search of all eleven fetched trees finds four
`math.h` files and no other.

It is also the *easiest possible* category-(c) header, because `<math.h>` is not
Apple's interface — it is ISO C99 §7.12, and clang implements essentially all of
it as builtins. Ours is written from the standard.

**Omitted versus Apple's 802 lines:** the `__sincos`/`__sinpi`/`__cospi`/
`__tanpi`/`__exp10` family beyond the four we declare; every availability
annotation; the BSD-compatibility block (`j0`/`j1`/`jn`/`y0`/`y1`/`yn`, `gamma`,
`significand`, `drem`, and the `struct exception`/`matherr` machinery); `_Float16`
and `__float128` overloads.

---

## 3. Published tree ≠ installed header — the two transforms, and why

A header in a source release is not the header Apple installs into an SDK. Two
differences bit, and both are reproduced explicitly rather than papered over.

### 3.1 `//Begin-Libc` regions (12 headers)

Libc marks the regions that exist only while Libc itself is being built, and its
own install step deletes them:

```
Libc/xcodescripts/headers.sh:407  for i in `... grep -l '^//Begin-Libc'`; do
                                      ed - $i < strip-header.ed
Libc/xcodescripts/strip-header.ed g/^\/\/Begin-Libc$/.,/^\/\/End-Libc$/d
```

Skip it and `_ctype.h` arrives with `#include "xlocale_private.h"` at the top —
a file in no SDK — and **28 of 32 objc4 TUs stop dead**. `sdk_stage.sh`
reproduces exactly that rule, on exactly that trigger.

Apple's `headers.sh` also runs `unifdef` with arguments from
`generate_features.pl`. That pass is **not** reproduced: its inputs are
build-configuration flags we do not have, and its effect is to delete
preprocessor branches a compiler evaluates to the same answer anyway. Where that
stopped being true, it produced §3.2, which is the honest way for it to fail.

### 3.2 `sdk/patches/` — two patches

**`0001-dyld-exclavekit-unavailable.patch`.** Apple's release process deletes
`#ifndef __OPEN_SOURCE__` regions. In `mach-o/dyld.h` that region is the whole
definition of `DYLD_EXCLAVEKIT_UNAVAILABLE`; the eight declarations that *use*
the macro were not deleted with it. dyld-1378's `mach-o/dyld.h` therefore does
not compile on its own — `expected function body after function declarator`,
eight times.

**`0002-xnu-platform-macosx.patch`, and this one is the interesting one.** xnu's
published headers carry the settings for *every* Apple product, each behind
`#ifdef XNU_PLATFORM_<name>`; Apple's install step resolves them with `unifdef`.
Nothing in a published tree does that for us, and with no `XNU_PLATFORM_`
defined the results are **silently wrong**:

* `sys/cdefs.h` leaves `__DARWIN_ONLY_UNIX_CONFORMANCE` undefined, so
  `__DARWIN_SUF_UNIX03` becomes `"$UNIX2003"` and every `__DARWIN_ALIAS`'d libc
  function is renamed. Measured on `libobjc.A.dylib`: **7 undefined symbols that
  nothing anywhere exports** — `_open$UNIX2003`, `_close$UNIX2003`,
  `_write$UNIX2003`, `_fsync$UNIX2003`, `_pread$UNIX2003`, `_nanosleep$UNIX2003`,
  `_strerror$UNIX2003`.
* `mach/arm/vm_param.h` drops `MACH_VM_MAX_ADDRESS_RAW` to the embedded value
  `0x0000000FC0000000` (64 GB) instead of macOS's `0x00007FFFFE000000` (128 TB).
  **Nothing would have failed to compile.** The number would just have been
  wrong.

That second bullet is precisely the risk `docs/SDK_SURVEY.md` §6.1 named, found
in the first tree we staged, and it is why §5 below exists.

---

## 4. The `.tbd` stubs

`scripts/gen_tbd.sh` generates `sdk/usr/lib/*.tbd` **from our own dylibs**, so
the exported surface is by construction exactly what we implement. Apple's
`libSystem.B.tbd` is 337 KB; ours is 12 KB.

```
libSystem.B.tbd    342 symbols   12,459 bytes
libobjc.A.tbd      420 symbols   18,632 bytes
libc++.1.tbd        14 symbols      741 bytes
```

`libSystem`'s 342 is `nm(libSystem.B.dylib)`'s 320 plus the **22** symbols
defined by *the loader* — the `_dyld_*` image-notify surface and
`dyld_stub_binder`. On Darwin those live in `libdyld.dylib`, which Apple's
`libSystem.B.tbd` re-exports; here there is no `libdyld.dylib`, because the
loader **is** dyld. They are listed in `darwin/loader-exports.txt`.

A static list can rot, so the generator refuses to let it. Three checks, each a
hard failure:

1. every name in `loader-exports.txt` is really defined by `build/machorun`
   (with a `=<elf-name>` annotation for the one case where the loader satisfies
   a Mach-O name under a different ELF name: `dyld_stub_binder` is special-cased
   in `src/resolve.c` and bound to `mr_stub_binder_trap`);
2. the list is *exactly* the set of symbols our dylibs import and none of our
   dylibs export, minus the `_glibc_*` flat-bind boundary;
3. every symbol imported by all **69** committed Mach-O binaries in `tests/bin`
   and `tests/objc44` is exported by one of the stubs. Currently 223 distinct
   imports, **0 unresolved**.

`sdk/usr/lib` is gitignored: the dylibs are the source of truth and a stale
`.tbd` is a lie the linker will believe. `scripts/build.sh all` regenerates it.

**The one format trap**, since the error message does not say it: a tbd-v4 file
must end with the YAML document-end marker `...`. Omit it and LLVM's TextAPI
reader rejects the file as `unsupported file type`.

---

## 5. What proves this SDK is right

Four results, all re-runnable.

| what | result |
|---|---|
| `scripts/build_objc4.sh` against `sdk/` | **32 objects, 0 failures** |
| `scripts/objc44.sh` | **41/44**, same three failures as before (`038-exceptions`, `042-dlopen`, `044-exception-through-uncached` — compact unwind ×2, dlopen ×1) |
| `scripts/difftest.sh` | **19 pass / 0 fail / 1 xfail / 1 no-oracle**, unchanged |
| `scripts/sdk_abi_probe.sh` | **163 lines, byte-identical to the macOS oracle** |

> **Corrected 2026-08-26 by independent verification (`docs/STATUS.md` §9).**
> The probe was 149 lines and did **not** print `MACH_VM_MAX_ADDRESS_RAW` — so
> the single failure §3.2 below describes as the reason this SDK needs a probe
> was the one failure the probe could not see. Forcing that constant back to the
> embedded 64 GB value passed all four rows of this table. It is printed now,
> together with `MACH_VM_{MIN,MAX}_ADDRESS`, `VM_{MIN,MAX}_ADDRESS`, the three
> `__DARWIN_ONLY_*` conformance settings and the two `__DARWIN_SUF_*` suffix
> strings, and the mutation now fails. Baseline re-recorded on the oracle.

The last one is the new one, and it is the test `docs/SDK_SURVEY.md` §6.1 asked
this milestone to buy. `sdk/tests/abi_probe.c` prints the ABI rather than
behaviour — `sizeof(struct stat)` and every field offset, 46 `errno` values, 14
`O_*` values, `sizeof(va_list)`, `struct tm`'s layout, and the first bytes of
`_DefaultRuneLocale`, the 3,208-byte table Darwin's `<ctype.h>` inlines a lookup
into and which `docs/ABI.md` therefore calls part of the ABI. It is built twice:

* on macOS, by Apple's clang against Apple's SDK, run natively — **the oracle**;
* on Linux, by clang-18 against `sdk/` alone, linked by `ld64.lld-18` against
  `sdk/usr/lib/*.tbd` alone, run under `build/machorun` — **the answer**.

The two outputs must be byte-identical, and are. That single run also happens to
be the end-to-end proof of the `.tbd` half: the Linux side sees no Apple header
and no Apple library.

The Linux side never writes the baseline. A mismatch is a failure to report.

---

## 6. What this does **not** change: the fixtures stay Apple-built

`tests/bin/*` and `tests/objc44/*` were compiled and linked **on macOS by
Apple's toolchain, on purpose**. They are the *precompiled Darwin binaries the
whole project exists to run*. `tests/build_fixtures.sh` refuses to run off
Darwin for exactly this reason.

**This SDK must not be used to rebuild them.** Relinking the corpus with
`ld64.lld` against our own stubs would delete the only property that makes the
scoreboard mean anything: that the bytes under test came from somewhere other
than us. A green suite over binaries we produced ourselves would prove that our
linker agrees with our loader, which is not a fact anybody needs.

The SDK's job is **new guest programs built on Linux** — a capability that did
not exist before this milestone — and the objc4 build. It is not the oracle, and
`scripts/gen_tbd.sh`'s check 3 depends on the corpus staying Apple-built: it is
only a meaningful completeness test *because* Apple's linker chose those imports.

`sdk/tests/abi_probe.c` is the deliberate exception, and it is not in
`tests/bin`: its entire point is to be compiled on both sides.

---

## 7. Known skew, and the one pin that is not "newest"

`sdk/SOURCES.tsv` pins the newest release of every repository except
**libmalloc**, which is pinned to `libmalloc-715.140.5`. In `libmalloc-792` and
later, `malloc_zone_malloc_options_t` moved from Apple-internal SPI into the
public `malloc/malloc.h`. `vendor/objc4-priv/malloc_private.h` hand-declares
that enum — it had to, because the SDK objc4 was ported against did not have it
— so the newer header gives objc4 the same enumerators twice and
`objc-runtime-new.mm` stops compiling. Teaching the shim to stand down is not
available: it is an `enum`, so there is no macro to test with `#ifdef`.

715.140.5 is the last release before the move, and pinning it also closes the
survey's other libmalloc note (`malloc/_malloc_type.h` was 77% line-identical to
the 15.4 SDK because the published revision had run ahead).

**Never track a branch.** `scripts/sdk_stage.sh --verify` re-fetches every
upstream file and checks it against `CHECKSUMS.sha256`, so a moved tag is a loud
failure rather than a mystery six months from now.

> **That was not true until 2026-08-26.** `--verify` re-staged the tree and
> *overwrote* `CHECKSUMS.sha256` before verifying, then compared the file it had
> just written against a second fetch of the same bytes. Measured: poison one
> row, run `--verify` on a cold cache, and it printed `all upstream files match
> their pinned tag` while silently deleting the poisoned row — a moved tag would
> have been recorded as the new truth. It now force-re-fetches all 333 files,
> treats the committed record as read-only, and dies with a diff. Re-tested both
> ways.
>
> Two limits remain, and they are limits rather than bugs. `--verify` covers
> **356 of 379** files: the 19 clean-room and 4 objc4 headers live in this
> repository and only git vouches for them. And there is no purely-offline check
> that the committed `sdk/usr/include` matches these sums, because the sums are
> of *pristine upstream* while 12 staged headers have their `//Begin-Libc`
> regions removed (§3.1) and 2 are patched (§3.2). The offline check that does
> work is `scripts/sdk_stage.sh` followed by `git status sdk/usr/include`;
> measured 2026-08-26, a restage of a clean checkout reproduces all 379 headers
> byte-for-byte.
>
> `CHECKSUMS.sha256` is also sorted with `LC_ALL=C` now. Without it a restage on
> a differently-configured machine moved 18 rows without changing a hash, which
> makes the record unverifiable by diff.
