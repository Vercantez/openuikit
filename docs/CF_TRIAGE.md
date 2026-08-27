# CoreFoundation build triage

**Date:** 2026-08-26. Measured on the `foundation-build` box
(`i-07f1ebf1cbe27f04d`, c8g.16xlarge), against
swift-corelibs-foundation `release/6.2`, cross-compiled
`-target arm64-apple-macos13.0` against machorun's staged Darwin sysroot.

---

## 0. The headline

**The 81-failure number is stale, and the shape of the problem is not what the
file list suggests.**

| state | pass | fail |
|---|---|---|
| as briefed | 5 | 81 |
| actual baseline on the box (`~/cfbuild`) | **59** | **27** |
| after declaration-only header shims (`~/cfbuild5`) | **69** | **17** |

86 `.c` files total. The baseline was verified independently of `PASS.txt` /
`FAIL.txt`: 59 of the 86 `log/*.err` files are zero-length and 27 are not, which
matches exactly.

**Of the 27 real failures, 26 were a missing header and one was a struct field
name.** Not one was a porting problem in CF's own logic. Adding
declaration-only shims — no implementations, several deliberately
wrong-but-parseable — cleared 10 of them, including **CFRunLoop, which needed a
two-line `AbsoluteTime` typedef**.

**But a compile census is the wrong instrument for the real question**, and
stopping there would have been misleading. See §3: the work is at the *link*
line, not the compile line.

---

## 1. Root-cause table (the 27 real failures)

| # | root cause | files | what fixing it takes | needed for our target? |
|---|---|---|---|---|
| 1 | **ICU headers** `_foundation_unicode/*.h` absent | **15** | Not a shim job. corelibs does not vendor ICU: `CMakeLists.txt:86-93` `FetchContent`s **`apple/swift-foundation-icu` tag 0.0.9**, which supplies the `_foundation_unicode/` prefix and a symbol-renamed static ICU. Fetch and cross-build it as Mach-O. | **Deferrable.** This is the formatters/collation cluster. App census: 2 uses each of Locale/Calendar/DateFormatter across `~/uikit`. |
| 2 | **Darwin/POSIX headers absent from the staged sysroot** | **11** | Mechanical. 8 headers: `sys/uio.h`, `spawn.h`, `net/if.h`, `sys/sysctl.h`, `mach-o/arch.h`, `mach/clock.h`, `mach/mach_syscalls.h`, `sysdir.h` — then a short second chain (`sys/un.h`, `net/if_dl.h`, `net/if_types.h`, `arpa/inet.h`, `libproc.h`, `vproc.h`, `mach/mach_vm.h`). Declarations only; measured to clear the files. | **Yes**, and cheap. |
| 3 | **`struct dirent` has no `d_fileno`** | **1** | One line. Our clean-room `dirent.h` defines `d_ino`; Darwin also exposes the legacy alias `d_fileno`, used once (`CFFileUtilities.c:1130`). Add the alias to the sysroot header. | **Yes** — CFFileUtilities backs FileManager (474 uses). |

Cause 2 broken down by the API actually reached, so the size is honest rather
than a header count:

| header | files | API surface CF actually uses |
|---|---|---|
| `sys/sysctl.h` | 3 | `sysctl` ×10, `sysctlbyname` ×1; consts `CTL_{KERN,VM,HW}`, `KERN_{PROC,MAXFILESPERPROC}`, `HW_{NCPU,AVAILCPU,MEMSIZE}` |
| `mach-o/arch.h` | 2 | `NXArchInfo`, `NXGetLocalArchInfo`, `NXFindBestFatArch` — and the byte-order enum **already exists** in our `mach-o/fat.h` |
| `sysdir.h` | 1 | 4 symbols (`sysdir_start_/get_next_search_path_enumeration` + 2 typedefs) |
| `spawn.h` | 1 | `posix_spawn` + 6 `posix_spawn_file_actions_*`. Note the failing include is at `CFPlatform.c:2291`, in CF's **generic POSIX** branch — glibc has all of it |
| `sys/uio.h` | 1 | `struct iovec` ×1, `writev` ×1 |
| `mach/clock.h` | 1 | CFRunLoop. Header was never the real issue — see §3 |
| `mach/mach_syscalls.h` | 1 | **vestigial** — CFXMLPreferencesDomain reaches no `mach_*`/`host_*` API behind it |
| `net/if.h` | 1 | **vestigial** — `uuid.c` includes it and reaches no `if_*` API |

### Files that should not be in the build list — but are not failing either

`CFWindowsUtilities`, `CFTimeZone_WindowsMapping`, `CFBundle_ResourceFork` and
`CFPlugIn` are all in **PASS.txt**. They compile to effectively empty
translation units because their contents sit behind `TARGET_OS_WIN32` (or
equivalent) guards that are false for us.

So they are not 4 failures to fix; they are 4 rows of **false green** inflating
the pass count. Excluding them from the build list is correct and should be done
explicitly, with the reason recorded, so nobody later reads a 69/86 as more
progress than it is. Real denominator: **82**.

---

## 2. The structural reason all of this appeared at once

Every failing include is guarded on `TARGET_OS_MAC`, which is **true for us**:
we compile `-target arm64-apple-macos13.0`, so `TargetConditionals.h` reports a
Mac. CF therefore takes its **Darwin** branch everywhere — and the Darwin branch
is entitled to Mach, `sysctl`, `sysdir` and `NXArchInfo`, none of which a Linux
kernel has.

That is a per-subsystem choice, not one global switch:

- **File/dir/process/system-info** — the Darwin branch is thin and the APIs have
  direct glibc equivalents. Shim the header, implement against glibc. Cheap.
- **Mach-O bundle parsing** (`CFBundle_Binary`, `CFBundle_Grok`) — keep the
  Darwin branch. We really are Mach-O; this code is *correct* for us and only
  wanted `NXArchInfo`. Both now compile.
- **CFRunLoop** — the one place where the Darwin branch wants the kernel itself.
  §3.

---

## 3. The finding that matters: the work is at the link line

A compile census cannot see this, and reporting 69/86 without it would have
overstated where we are.

Linking every object that compiled: **951 undefined symbols, 844 not exported by
machorun's `libSystem.B.dylib` (which exports 439), of which 188 are neither
CF-internal nor satisfied anywhere.**

| category | count | note |
|---|---|---|
| `CF*` defined by the 17 files that did not compile | 37 | resolves for free once §1 causes 1–2 land |
| **libc / pthread / dirent / locale** | **46** | `opendir`/`readdir`/`getpwuid`/`fcntl`/`setenv`/`strtol_l`/`snprintf_l`/`pthread_*`… ordinary C library that libSystem has simply not exported yet. Mechanical, and machorun has done exactly this twice before (objc4, libswiftCore). |
| **Mach kernel** | **9** | the real wall — see below |
| dyld / Mach-O introspection | 8 | `_dyld_get_image_name`, `getsectbynamefromheader_64`, … machorun already implements several |
| Swift Foundation class metadata | 6 | an artefact of the census configuration — see §4 |
| swift runtime | 3 | same artefact |
| dispatch vouchers | 2 | `voucher_mach_msg_adopt/revert` |

### The 9 Mach symbols

Of the 17 Mach APIs CF reaches, machorun's libSystem **already has 8**
(`mach_absolute_time`, `mach_msg`, `mach_port_allocate`, `mach_port_mod_refs`,
`mach_task_self_`, `mach_timebase_info`, `mach_error_string`, `vm_page_size`).
Missing:

```
mach_port_construct   mach_port_destruct   mach_port_extract_member
mach_port_insert_member   mach_port_type
mk_timer_create   mk_timer_arm   mk_timer_cancel   mk_timer_destroy
```

`mk_timer_*` are **Mach kernel timer objects** — a port you arm with a deadline
and then receive a message on. There is no Linux analogue; it would have to be
emulated (`timerfd` plus a port abstraction that `mach_msg` can wait on),
inside machorun's libSystem, and it is the beating heart of `CFRunLoop`.

**So CFRunLoop compiles and will not link.** That is the honest status, and it
is the single most important thing in this document. The alternative — taking
corelibs' **Linux** CFRunLoop path (dispatch + epoll) while everything else
stays Darwin — is a genuine architectural fork and needs deciding on its own
merits, not by accident.

This matters disproportionately because the app census puts **RunLoop at 319
uses and Timer at 411** — third and fourth behind URL and Data.

---

## 4. A caveat about the census configuration

The census compiles with **`-DDEPLOYMENT_RUNTIME_SWIFT`**, which is *not* the
mode `docs/DECISION.md` chose. Two consequences, both visible in the numbers:

1. The 6 `$s15SwiftFoundation…` symbols (`__NSCFType`, `NSNumber`, `NSNull`,
   `NSMutableData`, `__NSCFBoolean`, `_NSCFConstantString`) plus 3 `swift_*` are
   CF's constant objects binding their isa to corelibs' **Swift** classes via
   `STATIC_CLASS_REF`. Under the chosen ObjC mode those become **our** ObjC
   classes and these 9 symbols disappear.
2. `-Wno-everything` is on, so "pass" means *parses and codegens*, not *correct*.

Neither invalidates the triage — the header and Mach findings are
mode-independent — but the link surface **will** shift when we switch modes, and
the census should be re-run under the real configuration before anyone plans
against the 188.

---

## 5. What this says about the plan

`docs/PLAN.md` M2 estimated CoreFoundation at 3–4 weeks. That still looks right,
but the *composition* is different from what was assumed:

- **Not** a long tail of porting problems in CF's logic. There are none.
- **Mostly** filling out machorun's `libSystem` — 46 libc symbols and 8
  dyld/Mach-O ones — which is well-trodden work.
- **Plus** roughly 20 header shims, which is a day.
- **Plus one genuine research item**: `mk_timer_*`/`mach_port_*` for CFRunLoop,
  or a decision to take the Linux RunLoop path instead. This should be scoped
  and decided *before* M2 starts, because it is the only part with unknown
  depth, and it gates RunLoop and Timer.
- **ICU stays deferred**, and the measurement supports that: it is 15 of the 17
  remaining failures and touches almost nothing the target apps use.

Recommended immediate next step: **re-run the census in ObjC mode with the
shims committed**, then scope the RunLoop decision on its own. Both are small
and both remove guesswork from M2.

---

## Reproducing

`scripts/cf_shims.sh` writes the declaration-only shims into the sysroot's
`-idirafter` directory. They are a **measurement instrument, not an
implementation** — nothing in them is linkable, and several are deliberately
wrong-but-parseable to reveal what lies behind an `#include`. Do not mistake
them for progress on cause 2.

```sh
bash scripts/cf_shims.sh                                    # on the build box
sed -e 's|cfbuild|cfbuild5|' -e 's|-DDISPATCH_APPLY_AUTO|-Dd_fileno=d_ino \
  -include $HOME/work/cfextra/CFShimCarbon.h -DDISPATCH_APPLY_AUTO|' \
  ~/cf_census.sh > ~/cf_census5.sh && bash ~/cf_census5.sh
```

---

# Part 2 — the link edge (2026-08-26, later)

The milestone is a **linked** `libCoreFoundation.dylib` that loads under
machorun, not a higher compile count. This is how far that got and exactly where
it stops.

## 6. ObjC mode builds — and reaches parity with Swift mode

`docs/DECISION.md` §4A said corelibs' ObjC path is dead code. That is right about
`DEPLOYMENT_RUNTIME_OBJC` and its stubbed dispatch macros, but it understated
what is reachable. Building with **`-DDEPLOYMENT_RUNTIME_SWIFT=0`** — "neither
Swift-runtime nor Apple-internal" — reaches **69 pass / 17 fail, identical to
Swift mode**, at a cost of four small reconstructions:

| gap | what it is |
|---|---|
| `libkern/OSTypes.h` | `CFBase.h:69` takes the Darwin branch when Swift mode is off and wants Apple's libkern header. 8 typedefs. |
| `_CFThreadRef`, `_CFThreadAttributes`, `_CFThreadSpecificKey` | Defined only in `ForSwiftFoundationOnly.h`, which ObjC mode does not include — yet CF names these types in its own internals regardless. A corelibs **layering bug invisible in the only mode Apple builds**. 3 typedefs. |
| `AbsoluteTime` | CarbonCore type CFRunLoop still names. 2 lines. |
| **`__kCFAllocatorTypeID_CONST`** | **Used at `CFRuntime.c:1720`, defined NOWHERE in the open-source tree.** It sits in the `#else` of `#if DEPLOYMENT_RUNTIME_SWIFT` (`CFRuntime.c:1542-1737`) — the branch holding the *real* CF deallocation path. Swift mode never compiles it because `CFRelease` there just forwards to `swift_release`. Reconstructed as `_kCFRuntimeIDCFAllocator` (2). |

That last one is the sharpest evidence yet for the decision: **corelibs' non-Swift
CF path is not merely unbuilt, it is incomplete by omission.** Each such gap is a
judgement call, and they must be recorded as reconstructions rather than
silently defined.

**ObjC mode is the better base for us regardless**, because it drops the Swift
coupling entirely: 58 `$s15SwiftFoundation…`/`swift_*` references in Swift mode
→ **0**, once `-fcf-runtime-abi=objc` is also set (see §7).

## 7. A link-level wall that is not a symbol: `__cfstring` alignment

First link attempt failed with **`symbol l__unnamed_cfstring_.N at misaligned
offset`**, not undefined symbols. Cause: the census inherited
`-fcf-runtime-abi=swift`, which changes the constant-CFString record layout;
`ld64.lld` rejects the resulting `__DATA,__cfstring` entries.

`-fcf-runtime-abi=objc` fixes it **and** is the correct flag for our mode — it is
also what redirects constant strings from `_$s15SwiftFoundation19_NSCFConstantStringCN`
to `___CFConstantStringClassReference`, an ObjC symbol our Foundation supplies.
One flag, two problems, and it would have been invisible from a compile census.

## 8. Where it stops: 174 undefined symbols

With all 69 ObjC-mode objects linked against libSystem + libobjc, the link now
fails **only** on undefined symbols — the tractable kind:

| category | count | note |
|---|---|---|
| `CF*` defined by the 17 ICU-blocked files | 77 | free once ICU lands |
| **libdispatch** | **21** | **new structural dependency — see below** |
| libc / pthread / dirent / locale | 40 | libSystem gaps; mechanical |
| dyld / Mach-O introspection | 10 | `_dyld_image_count`, `getsectbynamefromheader_64`, … |
| **Mach kernel** | **9** | `mach_port_{construct,destruct,extract_member,insert_member,type}`, `mk_timer_{create,arm,cancel,destroy}` |
| OSAtomic / OSMemoryBarrier | 5 | trivial, real implementations via `__atomic` builtins |
| misc (`__exp10`, `__udivti3`, personality) | 3 | trivial |
| ICU direct, NXArchInfo, vouchers | 6 | |

### The new finding: CoreFoundation needs libdispatch

CF depends on GCD structurally — `dispatch_source_create`,
`dispatch_source_set_timer`, `dispatch_semaphore_*`, `dispatch_async`,
`dispatch_once`, plus the CF-private `_dispatch_main_queue_callback_4CF` and
`_dispatch_get_main_queue_port_4CF` that wire GCD into CFRunLoop.

**machorun's libSystem exports exactly one dispatch symbol**
(`dispatch_queue_get_label`). CF needs 21.

This was not in the M2 estimate and it is not small: it means
**swift-corelibs-libdispatch has to be built as Darwin Mach-O** before CF can
link. It also interacts with the RunLoop decision — the `_4CF` entry points exist
precisely to let CFRunLoop and the dispatch main queue share a thread, so
"emulate Mach ports" vs "take the Linux RunLoop" is now partly a question about
which libdispatch we have.

## 9. Revised sequencing for M2

Three hard prerequisites, none of which is CF itself:

1. **libdispatch as Mach-O** (new; blocks the link outright)
2. **ICU** via `apple/swift-foundation-icu` 0.0.9 (unblocks 17 files and 77 symbols)
3. **9 Mach symbols** in libSystem, or the Linux-RunLoop fork

then ~40 libc exports and a handful of trivia. The compile side is essentially
solved; **none of the remaining work is in CF's own code.**

Estimate impact: M2's 3–4 weeks did not account for libdispatch. Treat CF as
**gated on a libdispatch port** and re-plan accordingly — that is the honest
read, and it is better to know now than at the link line in week three.

## 10. Reproducing part 2

Private working dir on the build box, `~/fnd-link` (not the shared scratchpad):

```sh
bash ~/fnd-link/cf_census_objc2.sh          # ObjC mode, -fcf-runtime-abi=objc
clang -target arm64-apple-macos13.0 -isysroot $SDK -fuse-ld=lld \
  -B /usr/lib/llvm-18/bin -nostdlib -dynamiclib \
  -install_name /usr/lib/libCoreFoundation.dylib -Wl,--error-limit=0 \
  -L$SDK/usr/lib obj2/*.o -lSystem -lobjc -o libCoreFoundation.dylib
```

Loader for any load test must be built from machorun
`fix/map-below-isa-mask` (tip `79b4530`, which includes the heap fix `9659e73`),
not master.

---

# Part 3 — the census re-run in the real configuration

Part 1 and Part 2 both used a census that was wrong in two ways: it built
`-DDEPLOYMENT_RUNTIME_SWIFT` (not the mode we chose) and `-Wno-everything` (so
"pass" meant "codegens"). `scripts/cf_census.sh` is the corrected instrument.
**These are the numbers to plan against; the earlier ones are superseded.**

```
PASS=60  FAIL=22  EMPTY=4   (denominator 82, empty TUs excluded)
warnings across passing files: 11
```

## 11. Two corrections to Part 1, one of them mine to own

**`CFPlugIn` is NOT false green. I was wrong.** It defines **81 real symbols**
(`CFPlugInCreate`, `CFPlugInAddInstanceForFactory`, …). I put it on the
false-green list by pattern-matching its name against the Windows-only files
instead of checking what it defines. It is a real, functional translation unit
and belongs in the build.

The genuinely empty set is four, and includes one I had missed:

```
CFBundle_ResourceFork   CFBundle_Tables   CFTimeZone_WindowsMapping   CFWindowsUtilities
```

The denominator is still 82, but by coincidence — the membership was wrong in
both directions.

**The detector needed `--extern-only`.** A TU whose contents are entirely
`#if`'d out still emits the local assembler temp `ltmp0`, so a plain
`--defined-only` count is 1 and an empty TU sails through. Measured: without
`--extern-only` the check reported `EMPTY=0` while four files really were empty.
An instrument built to catch false green was itself producing false green.

## 12. What `-Wno-everything` was hiding

Dropping it moved five files from pass to fail, and the reason matters: they
were **calling undeclared functions**, which C99 and later do not permit and
which older compilers "resolved" as implicit-int. These were being *miscompiled*,
not merely compiled with warnings:

| file | undeclared call |
|---|---|
| `CFString` | `MAX` |
| `CFRunLoop` | `mach_port_construct` |
| `CFStream` | `_CFThreadSetName` |
| `CFUtilities` | `mach_vm_region` |
| `CFBundle_Binary`, `CFBundle_Grok` | `_NSGetMachExecuteHeader` |

So the earlier "69 passing" included files whose call sites would have passed
arguments wrongly and truncated return values. The honest count is lower and
means more.

It also surfaced a real sysroot gap: CF makes `-Wundef-prefix=TARGET_OS` an
**error**, and machorun's `TargetConditionals.h` defines 16 of the 18
`TARGET_OS_*` macros CF references — missing `WASI`, `ANDROID`, `BSD`, `CYGWIN`,
`NANO`. With `-Wno-everything` all 86 files silently passed that check; without
it, all 86 fail. The census predefines them; **the real fix belongs in
machorun's `TargetConditionals.h`.**

## 13. Corrected link surface

189 undefined symbols. The shape differs from Part 2 because CFRunLoop and four
others no longer compile, so their symbols moved from "provided" to "missing":

| category | count |
|---|---|
| `CF*` from the 22 failing files | 147 |
| libc / pthread / locale / dirent | 28 |
| libdispatch | 5 |
| OSAtomic | 4 |
| ICU / NX / vouchers / misc | 4 |
| dyld | 1 |

The libdispatch count looks smaller only because the heaviest dispatch consumers
(CFRunLoop, CFStream) are among the 22. §14 measures it properly.

## 14. The RunLoop fork: evidence for the decision

Measured against the build in which CFRunLoop *did* compile:

- **All 9 Mach symbols are in `CFRunLoop` and nowhere else.** Nothing else in
  CoreFoundation touches Mach ports. Replacing CFRunLoop's implementation
  removes the entire Mach dependency — a clean cut, not a partial one.
- **libdispatch is spread across 16 files**: CFRunLoop (13 symbols), CFStream
  (7), CFSortFunctions (4, `dispatch_apply` for parallel sort), CFBundle,
  CFURL, CFNumber, CFStorage, CFBasicHash and others (1 each).

**Decision (team lead's call, and the evidence supports it): take corelibs'
Linux dispatch+epoll RunLoop. Do not build Mach port emulation now.** The Mach
surface is confined to exactly the file being replaced, so the fork buys out the
whole unknown-depth item. What must match Apple is CFRunLoop's exported API and
semantics, not its mechanism — we are building this CoreFoundation, and apps
call `CFRunLoopRun()`, not `mk_timer_create()`.

**One correction to the reasoning for it:** the fork does **not** avoid
libdispatch. Only 13 of the dispatch references are CFRunLoop's; 8 other files
need GCD regardless. libdispatch is unavoidable on either branch of the RunLoop
decision, so it should be sequenced first on its own merits.

### Deferral trigger for Mach port emulation

Re-open this decision when **any** of these becomes true — not "later":

1. We run **Apple's shipped CoreFoundation or Foundation binary** rather than our
   own. Their CFRunLoop calls `mk_timer_*` directly and we cannot substitute an
   implementation we do not compile.
2. A **guest calls Mach port APIs directly** — `mach_port_allocate`, `mach_msg`
   on a port it owns, XPC, or anything built on Mach IPC.
3. A dependency needs `_dispatch_get_main_queue_port_4CF` /
   `_dispatch_main_queue_callback_4CF` with **real port semantics**, i.e. the
   libdispatch we port turns out to be the Darwin one rather than the Linux one.
4. Measured behavioural divergence in timer coalescing or run-loop ordering that
   an epoll implementation cannot reproduce and something depends on.

Until then the epoll RunLoop is the supported path and Mach emulation stays
unbuilt.

---

# Part 4 — ICU measured, and the corrected M2 estimate

## 15. ICU: headers unblock 13 of 15 files immediately

`apple/swift-foundation-icu` 0.0.9 (corelibs' own FetchContent route; no
substitute hand-rolled). 252 MB, 198 headers under
`icuSources/include/_foundation_unicode/`, and all eight headers CF asked for
are present.

**Adding the header path alone compiles 13 of the 15 ICU-blocked files.** The
other two fail on gaps that have nothing to do with ICU — `CFLocale` wants
`sys/mount.h`, `CFTimeZone` wants `dirent.h`, both sysroot items owned
elsewhere.

Those 13 files **define 152 `CF*` symbols**, which is the largest single block of
the link gap, and they **require 133 distinct ICU entry points**:

| family | syms | | family | syms |
|---|---|---|---|---|
| `ucal_` | 22 | | `ucol_` | 8 |
| `udat_` | 21 | | `ureldatefmt_` | 4 |
| `unum_` | 17 | | `udtitvfmt_` | 4 |
| `uregex_` | 16 | | `udatpg_` | 4 |
| `ucnv_` | 15 | | `utrans_`, `ulistfmt_`, `ufieldpositer_` | 3 each |
| `uloc_` | 8 | | `uenum_`, others | 2 each |

So ICU splits cleanly into two pieces of very different size: **the headers are
free and unblock 13 files today**; the **library is a real C++ cross-build**.

### What the ICU build actually is

- **470 C++ files, ~338K lines** (common 157K, i18n 176K, io 5.6K).
- **Data is vendored**, as `icuSources/common/icu_packaged_main_data.{0..3}.inc.h`
  — roughly 20 MB compiled in as C arrays, with `USE_PACKAGE_DATA=1`. There is
  no external `.dat` to fetch and `stubdata/` is excluded from the build. Good
  news: the port is self-contained.
- `U_DISABLE_RENAMING=1`, so symbols are plain `ucal_open` etc. The
  `_foundation_unicode/` prefix is an include-path convention, not a symbol
  rename. (Worth stating because "symbol-renamed ICU" is the usual shorthand and
  it is the opposite of what this configuration does.)
- `MAC_OS_X_VERSION_MIN_REQUIRED=101500` is already set, so the tree expects to
  be built for Darwin.

## 16. Delivered: the small unblocked items

Real implementations, in `src/compat/`, not measurement stubs:

- **`OSAtomic.c`** — all 5 symbols CF reaches, via `__atomic` builtins.
  Verified at runtime, including that increment/decrement/add return the **new**
  value (Darwin's do) and that a *failed* CAS leaves the target unchanged.
- **`MachOArch.c`** — `NXGetLocalArchInfo`, `NXFindBestFatArch` (exact
  `(cputype, cpusubtype)` match, then a `_ALL` subtype fallback, with
  `CPU_SUBTYPE_MASK` capability bits excluded from the comparison), and
  `__exp10`.

### A bug worth recording, because it compiled clean

`__exp10` written the obvious way — `return pow(10.0, x);` — compiles to:

```
0000000000000078 <___exp10>:
      78: 14000000    b  0x78 <___exp10>
```

clang recognises `pow(10, x)` as the `exp10` idiom and tail-calls `__exp10`,
which *is this function*. An unconditional branch to itself: an infinite hang.

It produced **no warning and zero undefined symbols** — the symbol table looked
*healthier* than the correct version, which references `pow`. A volatile
function pointer defeats the pattern match. This is the same shape as the
`ltmp0` false-green in §11: the metric that should have caught it pointed the
wrong way.

## 17. Corrected M2 estimate

The original 3–4 weeks for CoreFoundation assumed the work was in CF. It is not
— "not one of the 27 failures was a porting problem in CF's own logic" still
holds. The work is in everything CF sits on.

| item | owner | estimate |
|---|---|---|
| **libdispatch as Darwin Mach-O** | swiftcore-build (#47) | **gates the CF link entirely** |
| ICU cross-build (470 C++ files, data vendored) | ours | **1.5–2.5 wk** |
| Sysroot headers: `dirent.h`, `sys/socket.h`, `sys/mount.h`, `pwd.h`, `asl.h`, `libc.h`, + the 5 `TARGET_OS_*` macros | machorun | 2–3 d |
| ~28–40 libc/pthread/locale exports in libSystem | machorun | 3–5 d |
| CF proper: restore the 5 ObjC dispatch macros, wire `_CFRuntimeBridgeClasses`, take the epoll RunLoop | ours | **2–3 wk** |
| OSAtomic / NX / `__exp10` | ours | **done** |

**CF to a linked, loading dylib: 5–7 weeks**, of which 3.5–5.5 are ours and the
rest is on machorun's and swiftcore-build's tracks. That is up from 3–4, and the
increase is almost entirely libdispatch and ICU — two dependencies that were
invisible until the link line.

The **whole-Foundation** figure in `DECISION.md` §6 (16–22 weeks) should be read
as **19–26**, with the same caveat: the growth is in the substrate, not in
Foundation.

Sequencing that follows: **ICU is the best next use of our own time**, because
it is fully unblocked, it is the largest single block of the link gap, and it
does not depend on libdispatch landing.

---

# Part 5 — ICU built as Darwin Mach-O, and where it stops

## 18. The build: 469/469, in 33 seconds

`scripts/build_icu.sh` cross-builds **apple/swift-foundation-icu 0.0.9** —
corelibs' own dependency, not a substitute — to Darwin Mach-O arm64 on Linux.

```
sources: 469   jobs: 16
compiled: 469 / 469
libicucore.a   40,831,720 bytes
exported ICU entry points: 658
```

**456 of the 469 files needed no intervention at all.** The build took 33s on 16
cores, which is why this was done locally in Docker rather than on a provisioned
box — a c8g would have been latency and spend for a 33-second compile. That was
a deviation from the approved plan and is called out rather than buried.

What the other 13 needed, all small:

| gap | files | fix |
|---|---|---|
| `os/log.h` | 5 | Apple's os_log diagnostics. Macros expand to nothing — this is diagnostic-only code and we do not want a link dependency for it. |
| `glob.h`, `langinfo.h`, `tzfile.h`, `NSSystemDirectories.h`, `dirent.h` | 5 | declaration-only shims |
| **no single-precision math at all** | 1 | see below |
| `-fno-rtti` (mine) | 22 | see below |
| `U_TIMEZONE_PACKAGE` quoting (mine) | 1 | see below |

### Three traps, two of them mine

**`-fno-rtti` is not a free size win.** I added it reflexively; 22 files then
failed on `dynamic_cast`/`typeid` in the calendar, collation and timezone code.
Upstream's CMakeLists sets neither `-fno-rtti` nor `-fno-exceptions`, and that is
deliberate.

**`U_TIMEZONE_PACKAGE` must arrive as a string literal.** Passed through a nested
shell the quotes are stripped and `udata.cpp` fails with *"use of undeclared
identifier 'icutz44l'"* — which reads like a missing symbol, not a quoting bug.

**machorun's `math.h` declares NO single-precision variants at all** — `expf`,
`sinf`, `cosf`, `powf`, `sqrtf`, every one absent. libc++'s `<cmath>` imports
them with `using ::atan2f _LIBCPP_USING_IF_EXISTS`, so the absence is **silent**
until something references one, and then the error surfaces inside libc++'s
`<complex>` as *"reference to unresolved using declaration"* rather than at the
use site. ICU reaches only `expf`. This is a machorun sysroot gap and the fix
belongs there.

## 19. The oracle: real locale data, on macOS

The differential oracle is a **native macOS build of the same ICU source** (469/469
in 40s), not Apple's shipped `libicucore` — whose ICU version differs, which
would make any diff meaningless.

```
icu.version=72.1
uloc.display_de_in_en=German
ucal.year=2009  month=1  day=13  hour=23  minute=31  dow=6
udat.en_US=Feb 13, 2009 at 11:31:30 PM
udat.de_DE_longdate=13. Februar 2009
unum.en_US=1,234,567.891
unum.de_DE=1.234.567,891
unum.currency_en_US=$42.50
ucol.de_ae_before_z=1
ustr.tr_lower_I=ı
```

Every line prints a **value**, not a status, because the specific risk in a
338K-line cross-build with 20 MB of vendored data is that it links and then
formats wrongly. `13. Februar 2009`, `1.234.567,891` and the Turkish dotless `ı`
are the load-bearing ones: root-locale fallback would print English months, a
`.` group separator, and `i`. They prove the vendored data is actually wired up.

One bug found in the test itself: **`udat_open` takes `timeStyle` FIRST**, then
`dateStyle`. `(UDAT_LONG, UDAT_NONE)` yields a long *time* and no date — still
deterministic, still diffs clean, and silently stops testing month names, which
was the entire point of that case.

## 20. Where it stops: 43 symbols, none of them ICU's

`libicucore.a` has 3,997 undefined symbols; **libSystem and libc++ satisfy all
but 43.**

| bucket | count | note |
|---|---|---|
| **C++ ABI / libc++abi** | 14 | `__cxa_pure_virtual`, `__dynamic_cast`, `__cxa_free_exception`, `__dso_handle`, the `__cxxabiv1::*_class_type_info` vtables, `length_error`/`bad_array_new_length` |
| **libc++ `std::`** | 17 | `mutex`, `condition_variable`, `locale`, `ios_base`, `basic_istream`/`ostream`, `__call_once` |
| **libc (libSystem gap)** | 11 | `bsearch` `closedir` `div` `dlclose` `getprogname` `opendir` `readdir` `strncat` `strnlen` `timezone` `tzname` |

**So the ICU port is done and the test does not run yet.** The blocker is not
ICU: machorun's `libc++.1.dylib` exports **83 symbols**, a minimal stub built for
libswiftCore's `basic_string` needs, with **no libc++abi at all**. ICU is the
first real C++ consumer on this stack and it needs a genuine C++ runtime.

I did not stub these to manufacture a green run. A `__cxa_pure_virtual` that
returns instead of aborting, or a `std::mutex` that does not lock, would produce
a passing differential over a broken library — the exact failure mode this
project has been bitten by repeatedly.

### New dependency, sized

**A fuller libc++/libc++abi as Darwin Mach-O** — 31 symbols across the two
buckets. That is a bounded job (libc++abi is ~30 source files) and it sits
alongside libdispatch as a substrate dependency rather than a Foundation one. It
is also very likely needed by anything else C++-heavy on this stack, so it
belongs with machorun's owners rather than here.

The 11 libc symbols are the same libSystem gap already routed; `opendir`,
`readdir`, `closedir` and `dirent.h` are the **third** consumer of that one gap
(CFTimeZone, CFLocale, now ICU), which argues for fixing it once, properly, in
the sysroot.

## 21. Estimate delta

ICU's own cross-build is **done, not 1.5–2.5 weeks** — the vendored data and the
456/469 clean-compile rate made it a day, not a fortnight. That is a real
reduction. But it is partly offset by the libc++/libc++abi port it uncovered,
which was not in any estimate.

Net for M2: unchanged at **5–7 weeks**, with the composition shifted — less ICU,
more substrate. The pattern from §17 holds and is now three-for-three: **every
correction to this estimate has moved work out of Foundation and into the things
Foundation stands on.**

---

# Part 6 — correcting the selector counts, and what #51 actually needs

## 22. The overlap claim was wrong. Retracted.

I reported that CF's 151 selectors "overlap heavily" with libswiftCore's 128,
and that one set of `NS*` implementations therefore satisfies both consumers.
**I never computed the intersection.** I recognised six names in both lists and
generalised. Computed:

```
libswiftCore selectors : 124   (128 strings in __objc_methname; 4 are property
                                type-encodings like T@"NSString",R,C, not selectors)
CoreFoundation         : 151
UNION                  : 253
SHARED BY BOTH         :  22
```

Twenty-two, about 15%. That is a **modest** overlap. "One implementation
satisfies both" is true only in the sense that one library can implement 253
methods.

**What survives, at the strength the evidence supports:** the 22 shared
selectors are almost exactly the class-cluster primitives — `length`,
`characterAtIndex:`, `getCharacters:range:`, `count`, `objectForKey:`, `member:`,
`addObject:`, `insertObject:atIndex:`, `removeObjectAtIndex:`, `_cfTypeID`. Both
consumers independently bottom out on the same primitive set. That is real and
useful: a correct class-cluster implementation serves both. It is *not* evidence
that the two want the same surface, and it is much weaker support for the
architecture than claimed.

The architecture is still right for the reasons in `DECISION.md` that were
measured properly. None of them depended on this.

## 23. Both selector counts have measurement bias, in opposite directions

Neither 151 nor the ground-truth alternative is the number to plan against yet.

**151 is a lower bound with a receiver-typing bias.** It was harvested from
clang's "instance method not found" warnings, which fire only for messages to
*typed* pointers like `(NSArray *)`. CF's `CFTYPE_OBJC_FUNCDISPATCH0/1` casts to
`id`, and clang permits any method on `id` silently. So the 151 systematically
excludes everything CF sends to `id` — which is why `isEqual:`, `hash`,
`copyWithZone:`, `objectAtIndex:`, `description`, `retain` and `release` are all
absent despite CF certainly messaging them.

**The `__objc_methname` harvest gave 57, and that is a floor from a partial
build.** Extracting emitted selectors from the compiled objects is the right
instrument — it is what produced libswiftCore's number and has no typing bias.
But 13 files still fail to compile in that configuration, and they are exactly
the heaviest dispatch consumers: CFArray, CFAttributedString, CFCalendar,
CFCharacterSet, CFData, CFDate, CFString. Only 7 objects emitted selectors at
all, which briefly looked like evidence that the restoration was inert.

It is not. **The restoration is live**, confirmed two ways: the preprocessed
expansion at `CFArrayGetCount` is
`if (_CFIsObjCDispatch(...)) return (CFIndex)[(NSArray *)array count];`, and
`CFDictionary.o` emits 17 real selectors with `_objc_msgSend` undefined, which
only happens when a message is actually generated. The missing selectors are
missing files, not missing dispatch. (Worth noting the near-miss: "only 7 of 69
objects emit selectors" is a alarming-looking number that meant nothing, and the
check that resolved it was `nm` finding no `CFArrayGetCount` in `CFArray.o` —
because there was no `CFArray.o`.)

## 24. What #51 needs first

Those 13 files fail on Foundation **types**, not classes: `NSMakeRange`,
`NSCalendarUnit`, `NSRange`, `NSUInteger`, `CFStreamError` bridging. So the
first deliverable of #51 is not the method declarations at all — it is the
**type** surface CF needs, without which the census cannot even be taken.

Order that follows:

1. Foundation types header (`NSRange`, `NSMakeRange`, `NSUInteger`,
   `NSCalendarUnit`, …) — unblocks the last 13 files.
2. Re-harvest the selector set from `__objc_methname` across all 82 objects.
   That is the real denominator, with no receiver-typing bias, and it is the
   number to plan against. Expect it to exceed 151.
3. `@interface` declarations for those methods — real signatures, because
   `@class`-only forward declarations compile with 78 "return type defaults to
   `id`" warnings, which is clang guessing the message-send ABI.
4. Class registration (`_CFRuntimeBridgeClasses`), which is a correctness
   prerequisite — see §9 in the false-green record.

I am not writing headers against a number I have already had to correct once.

## 25. #51 step 1: the type header, and a circularity worth naming

`include/CFFoundationTypes.h` supplies the Foundation **types** CF's dispatch
call sites name — `NSRange`, `NSMakeRange` (19 call sites), `unichar`,
`NSCalendarUnit`, `NSStringCompareOptions`, `NSTimeZoneNameStyle`. Measured
effect: **69 → 73 of 82** compiling with live ObjC dispatch.

The 9 that remain split cleanly, and the split is the useful part:

| blocked on | files | owner |
|---|---|---|
| **missing method signatures** — `id` cast to a non-pointer | CFCalendar, CFDate, CFStream, CFString | ours, step 3 |
| Darwin system types (`struct kinfo_proc`, `struct tzhead`) | CFUtilities, CFTimeZone | machorun sysroot |
| assorted (shim defects, an `NSString` redefinition, a Mach macro) | CFSocket, CFRunLoop, CFURLAccess | mixed |

**The four in the first row are the same defect as the 78 warnings**, surfacing
where C refuses to look away. `CF_OBJC_FUNCDISPATCHV(typeID, CFTimeInterval,
obj, msg)` expands to `return (CFTimeInterval)[obj msg];`. With only a `@class`
declaration the message's return type defaults to `id`, and casting a pointer to
`double` is a hard error rather than a warning. Same for `CFRange`,
`CFStreamError`, and CFString's integer assignment.

That is worth stating plainly because it is *evidence for* the design decision
rather than an obstacle to it: real `@interface` declarations are not a
nicety, they are what makes eight of these call sites express the right ABI.

### The circularity

Getting the true selector denominator requires all 82 files to compile;
compiling four of them requires the method declarations; writing the method
declarations is what the denominator was supposed to size. **This is iterative,
not one-shot**, and pretending otherwise would produce another number needing
retraction:

1. types header (done — 73/82)
2. `@interface` declarations seeded from the 151 warning-harvested selectors,
   which is a biased lower bound but a fine *starting* set
3. compile, harvest `__objc_methname` across all 82 — the unbiased number
4. close the gap between 2 and 3, repeat until the harvest stops growing

The number to report as "CF's selector surface" is the fixed point of that
loop, not any single measurement along the way. I will say which step produced
any figure I quote.

## 26. #51 step 2: the surface splits public/private, and that decides the method

Before writing 151 `@interface` declarations, a question worth answering: where
does each signature's ground truth come from? `scripts/verify_sigs.py` checks
each selector against Apple's real Foundation headers on this machine.

**86 of 151 are in Apple's public headers. 65 are not.**

That split is not a curiosity — it determines how each half gets reconstructed,
and the two halves have *different and complementary* sources of truth:

| half | count | source of truth |
|---|---|---|
| **public** | 86 | documented API. Write clean-room, then **verify** against Apple's header. |
| **private / SPI** | 65 | absent from every public header — but CF is the **caller**, so its call sites pass typed arguments and `CF_OBJC_FUNCDISPATCHV` carries the return type as a macro argument. |

The private half is **better** determined than it first appears, not worse. For
`-_cfTypeID`, `-__addObject:forKey:`, `-_fastCStringContents:`,
`-_getValue:forType:` there is no header to consult, but there is something
stronger: the code that calls them, with the types spelled out at the call site.

### On using Apple's headers at all

They are a **reference to verify against, never a source to generate from**.
This project's clean-room standard is stated in
`~/swiftcore-macho/sdk/foundation/Foundation.h` ("nothing here is copied from
Apple headers") and there is no reason to weaken it for convenience — so
`docs/cf-census/cf-objc-public-private.txt` records *which* selectors are public
and private, and deliberately does not reproduce Apple's declaration text.

The reason to check at all is the hazard class this project has been cataloguing
all night: **a wrong Objective-C signature is the `posix_spawnattr_t` bug moved
from C to ObjC.** The message compiles, the selector matches, `objc_msgSend`
dispatches — and the argument or return register is wrong. It fails silently and
at a distance. Neither half may be guessed.

## 27. #51 step 2a: the four blocked files compile, and the loop is running

`include/CFFoundationInterfaces.h` declares the methods the type header alone
could not unblock. **77 of 82**, up from 73 — CFCalendar, CFDate, CFStream and
CFString now compile with live ObjC dispatch.

### Census curve

| step | passing |
|---|---|
| 0 — `@class` forward declarations only | 69 / 82 |
| 1 — `CFFoundationTypes.h` (types) | 73 / 82 |
| 2a — `CFFoundationInterfaces.h` (first methods) | **77 / 82** |

The 5 remaining are **not** method-signature problems: `struct tzhead`
(CFTimeZone) and `struct kinfo_proc` (CFUtilities) are machorun's sysroot,
CFSocket is a defect in my own `arpa/inet.h` shim, and CFRunLoop/CFURLAccess are
a Mach macro and an `NSString` redefinition.

### Why the signatures are trustworthy

Each is cited to its evidence in the header, and the two halves have different
sources:

- `NSDate.timeIntervalSinceReferenceDate` / `timeIntervalSinceDate:` — **public**,
  verified against Apple's `NSDate.h:20,30`.
- `NSString.length` — **public**, verified against `NSString.h:109`.
- `NSCalendar._minimumRangeOfUnit:` / `_maximumRangeOfUnit:` /
  `_rangeOfUnit:inUnit:forAT:` — **private SPI**, read off CF's call sites at
  `CFCalendar.c:1071,1124,2996`, which spell out every parameter type.
- `NSInputStream/NSOutputStream._cfStreamError` — **private SPI**,
  `CFStream.c:899,904`. Note this returns a **struct by value**, so guessing
  `id` would have selected the wrong `objc_msgSend` variant entirely rather than
  merely the wrong value.

### The loop's next iteration is measurable

Warnings went 98 → 309, and that is the instrument working rather than a
regression: with a real `@interface`, every method *not* declared on those
classes now warns **by name**. The unknown-method set is **155** — slightly up
from 151, because receivers that were previously untyped now report.

So each iteration's remaining work is enumerated by the compiler, and the
convergence curve to report is the one on *that* number, not on the census.
Next iteration starts from 155.

### A fourth total wipeout, same cause as the other three

The first version of this header assumed CF's own headers would already be
included, and **said so in a comment instead of checking**. It is force-included,
so it lands before everything: `CFRange`, `CFTimeInterval` and `CFStreamError`
did not exist yet and all 86 files failed with "expected a type".

That is the fourth time tonight a header change took the census to zero, and all
four have the same shape — an assumption about the include environment asserted
rather than verified: a duplicate `mach_port_context_t`, a duplicate `div_t`, an
include path that shadowed the sysroot, and now an ordering assumption. The
header is self-contained now, and the comment records why rather than restating
the assumption.

## 28. #51 iteration 1: the convergence curve, with the compile count alongside

| step | compiling | unknown methods | warnings |
|---|---|---|---|
| 0 — `@class` only | 69 / 82 | — | — |
| 1 — types header | 73 / 82 | 151 | 98 |
| 2a — hand-written declarations | 77 / 82 | 155 | 309 |
| **2b — derived + reconciled** | **77 / 82** | **50** | 101 |

**The compile count held at 77 while the unknown-method set fell 155 → 50.** That
pairing is the whole point of reporting both: a harvest that flattens *because
files stopped compiling* looks identical, in the harvest column alone, to one
that flattens because the set is closing. Here the build did not degrade, so the
drop is real. The 5 remaining failures are unchanged and none is signature-
related — `struct tzhead`, `struct kinfo_proc`, a defect in my own `arpa/inet.h`
shim, a Mach macro, and an `NSString` redefinition.

Iteration 2 starts from 50.

### What produced the drop

`scripts/derive_interfaces.py` recovers signatures from CF's own dispatch macros,
then `scripts/reconcile.py` applies the public/private rule:

```
  private-adopted      52     call site is authoritative; nothing else exists
  public-reconciled    12     Foundation's declared type replaces CF's local one
  public-unreviewed    52     MARKED, not silently adopted
  unclassified          7     surfaced only after receivers became typed
```

The 52 marked `PUBLIC, UNREVIEWED` are the honest residue: derived signatures
that dispatch correctly but whose declared type I have not reconciled against
Foundation's contract. They are flagged in the header rather than quietly
shipped, because that is precisely the `- (CFIndex)count` vs `NSUInteger count`
distinction from §27 — invisible until a consumer other than CoreFoundation
arrives.

### Two more wipeouts, and a rule that finally generalises

Iteration 1 cost two more total-zero events, bringing tonight's count to **six**:

5. **Categories need a full `@interface`.** Emitting `@interface NSArray
   (CFDerived)` against a `@class` forward declaration fails with "cannot define
   category for undefined class". Classes already declared get a category; the
   rest need a real interface.
6. **A generated header referenced types it did not include** — `CFNumberType`,
   then `NSTimeInterval`. The second is the more interesting: *reconciling a
   signature to Foundation's spelling requires Foundation's typedef.* Renaming
   `CFTimeInterval` to `NSTimeInterval` introduced a name that did not exist.

And one near-miss that was worse than a wipeout: the derivation regex used
`\(([^)]*)\)` for parameter types, which stops at the first `)` and mangles
function-pointer types — `(void (*)(const void *, void *))` became `(void (*)`.
That emitted **syntactically invalid declarations**, which is strictly worse than
deriving nothing, because a malformed header breaks all 86 files rather than
leaving one method undeclared. The generator now extracts balanced parentheses
and **validates its own output**, refusing to emit anything whose parentheses do
not balance.

All six wipeouts share one shape, and it is now stated as a rule rather than a
tally: **a header must include what it references and may assume nothing about
where it lands.** Force-inclusion means "before everything", including before the
headers whose types you are using. Six times tonight that was assumed instead of
arranged.

The consolation is that the census is a good instrument precisely because it
fails this loudly: 77 → 0 on a three-line change is a fault report delivered
immediately, not a slow degradation. That property is worth preserving as the
header grows.

## 29. Reconciling the public half: 25 differences, only 7 of them real

`scripts/check_public.py` reports, for each `PUBLIC, UNREVIEWED` declaration,
what Apple's header declares. It is deliberately built to be **incapable of
generating** — it emits a verdict per selector, never a declaration — because
the clean-room line is easiest to blur exactly here, while reconciling generated
output against those headers. The declaration text comes from our generator;
Apple's header only confirms or corrects the type.

```
agree 18    differ 25    no-reference 9
```

The 25 differences all *look* alarming and mostly are not. Rather than eyeball
them, the types were measured on macOS:

| type pair | measured | verdict |
|---|---|---|
| `CFIndex` / `NSInteger` | 8 bytes, both **signed** | equivalent |
| `CFIndex` / `NSUInteger` | 8 bytes, signed vs **unsigned** | **real difference** |
| `Boolean` / `BOOL` | 1 byte, both **unsigned** | equivalent |
| `CFComparisonResult` / `NSComparisonResult` | 8 bytes, both signed | equivalent |
| `CFStreamStatus` / `NSStreamStatus` | 8 bytes, signed vs **unsigned** | **real difference** |
| `CFStringRef` / `id` / `CFTypeRef` / `void const *` | 8 bytes | equivalent |

**So 18 of the 25 are equivalent spellings, and only 7 are genuine signedness
differences**: `count`, `length`, `firstWeekday`, `minimumDaysInFirstWeek`,
`countForObject:` (`CFIndex` → `NSUInteger`) and `streamStatus` on both stream
classes (`CFStreamStatus` → `NSStreamStatus`).

### Measuring corrected two of my instincts

- I expected `Boolean` vs `BOOL` to be a problem. It is not — both are one
  unsigned byte on this platform. Had I "fixed" it I would have churned 8
  declarations for nothing.
- I did **not** expect `CFStreamStatus` vs `NSStreamStatus` to be one. It is:
  CF's is signed, Foundation's unsigned. That is the same class of bug as
  `count`, and I would have missed it by inspection because the two names look
  like a straight rename.

Which is the point of measuring rather than reading: the pair that looked
suspicious was fine, and the pair that looked like a rename was not. Nine
selectors have no public reference at all (`invertedSet`, `bytes`,
`streamError`, `localeIdentifier`, `mutableString`, …) — those are SPI wearing
public-looking names, and the call site governs them.

## 30. The silent set is closed, and the compile count went DOWN for someone else's reason

**All 52 `PUBLIC, UNREVIEWED` declarations are adjudicated. That count is now
zero.** Every declaration carries its verdict:

```
private-adopted      52    call site authoritative; nothing else exists
public-equivalent    39    measured equivalent; CF's spelling kept
public-reconciled    16    Foundation's declared type; a real signedness difference
public-no-reference   9    SPI wearing a public-looking name
unclassified          7
```

The silent set was closed before the loud one, because 50 unknown methods
announce themselves as warnings while a wrong declared type announces nothing —
and stays invisible for exactly as long as CoreFoundation is the only consumer.

A process note on how the first attempt at this went wrong: the equivalent/
no-reference sets were first built by hand from a `head -25` of the check output,
which left 21 selectors still unadjudicated while *reporting* the set as closed.
Rebuilding them from the full output fixed it. Sampling the output of a tool
built to be exhaustive is a good way to lose the exhaustiveness.

### Census: 77 → 75, and the drop is not ours

| step | compiling | unknown methods |
|---|---|---|
| 2b — derived + reconciled | 77 / 82 | 50 |
| **3 — adjudicated + machorun master SDK** | **75 / 82** | 50 |

Two files advanced and three regressed:

- **advanced** — CFTimeZone is past `struct tzhead` (now a method-signature
  error) and CFUtilities is past `struct kinfo_proc` (now `struct
  proc_bsdshortinfo`). machorun's headers did what they were meant to.
- **regressed** — CFSocket, CFSocketStream and `uuid` now fail on
  **`sys/constrained_ctypes.h` file not found**. That header is referenced by
  `sdk/usr/include/sys/socket.h`, added in machorun `bde36bf` — the same commit
  that shipped `kinfo_proc` and `tzhead` — and it is **not shipped**.

So the compile count fell for a reason that has nothing to do with the
declarations, which is precisely the discrimination the paired columns exist to
provide. Reported without it, "75/82, down from 77" would have looked like the
adjudication broke something.

### The typedef coupling is now a mechanism, not a note

Reconciling a signature to Foundation's *spelling* requires Foundation's
*typedef* to exist. That took the census to zero **twice** — `NSTimeInterval`,
then `NSStreamStatus` — so `scripts/reconcile.py` now refuses to run if any
target type in its table is undeclared in `CFFoundationTypes.h`:

```
reconcile: target type(s) not declared in CFFoundationTypes.h: NSNoSuchType
           add the typedef before reconciling a signature to it.
```

Verified by negative control — the guard was deliberately fed a bogus type and
observed to fire, rather than assumed to work. **A note I forgot twice is not a
safeguard.** That is the same lesson as "a comment asserting an invariant is not
a mechanism enforcing one", arrived at the expensive way.

## 31. Iteration 2, and a Docker bind mount that silently truncates files

| step | compiling | unknown methods |
|---|---|---|
| 0 — `@class` only | 69 / 82 | — |
| 1 — types header | 73 / 82 | 151 |
| 2a — hand-written | 77 / 82 | 155 |
| 2b — derived + reconciled (iter 1) | 77 / 82 | 50 |
| 3 — machorun master SDK | 75 / 82 | 50 |
| **4 — iteration 2** | **75 / 82** | **31** |

**155 → 50 → 31**, with the compile count flat. The remaining 31 are dominated by
the genuinely underivable: 19 `CF_OBJC_CALLV` (no return type at the call site)
and 12 `FUNCDISPATCHV` with untyped arguments.

### A third reason a curve flattens

We had named two — the set closed, or the build broke. Iteration 2 found a third:
**the tool hit its limit.** The first run derived only 4 of 50 and the curve
looked converged. It was not; my parser could not read those call sites.

Worse, **the diagnostic lied**. It reported "call site not a recognised dispatch
macro" for sites that were perfectly well recognised `CF_OBJC_FUNCDISPATCHV`
calls whose *arguments* were untyped expressions (`range:NSMakeRange(a, b)`
rather than `range:(NSRange)r`). That message sent me to implement multi-line
macro joining — which was never the problem and changed nothing. Once the
diagnostic distinguished "unrecognised" from "recognised but untypeable", the
fix was obvious: infer the type from the callee (`NSMakeRange` → `NSRange`),
which is reading CF's own code rather than guessing. **4 → 24 declarations.**

A diagnostic that names the wrong cause is worse than one that says only
"failed", because it directs the repair. That is the same lesson machorun
recorded about error messages that prescribe a remedy which happens to work.

### `cp` from a macOS Docker bind mount silently truncated a header

The eighth and last census wipeout was not a code defect at all.

```
host file                    14845 bytes
read through the bind mount  14845 bytes   <- correct
cp'd into the container      12205 bytes   <- SILENTLY TRUNCATED
```

The copy stopped mid-line, inside a comment, producing "unterminated /* comment"
across all 86 files. Every instinct said generator bug — and the generator was
fine; the file on disk was complete and so was the mount's view of it. Only
comparing the three sizes found it.

`docker cp` (which goes through the daemon rather than the mount) transfers all
14845 bytes and the build is clean. This is the same family as the already-recorded
"do not run high-exec-rate loops over the macOS bind mount", and it is worse,
because a short read produces a *plausible-looking* file rather than an error.

**Copy build inputs into the container with `docker cp`, or verify the byte
count afterwards.** A mount that reads correctly under `sed` and truncates under
`cp` will not announce itself.

## 32. What the last 31 are, and why tooling should stop here

The harvest is at **31**, from 155. They are not a homogeneous tail — they split
into two groups with different prospects, which is the distinction that decides
whether more tool work pays:

**Colon-only selectors (4)** — `_addComponents::::`,
`_composeAbsoluteTime:::`, `_decomposeAbsoluteTime:::`, `_diffComponents:::::`.
These have **unnamed parameter labels**, and the deriver's
`re.findall(r'(\w+):')` cannot express an empty label. A closeable tool gap.

**No return type at the call site (27)** — `absoluteURL`, `scheme`, `host`,
`port`, `user`, `password`, `query`, `fragment`, `localizedDescription`,
`localizedFailureReason`, `localizedRecoverySuggestion`, `_cfTypeID`,
`_cfMutableCopy`, `_fastCStringContents:`, `_getCString:maxLength:encoding:`,
`getBuffer:length:`, `setTolerance:`, `open`,
`enumerateKeysAndObjectsWithOptions:usingBlock:`, … These reach CF through
`CF_OBJC_CALLV`, which carries no return type; the type lives in the *caller's*
assignment target, one scope up.

**Tooling should stop here.** The second group is where the evidence is thinnest
and judgement matters most — precisely the place not to mechanise. A tool that
inferred a return type by walking back to a variable declaration would be
guessing with extra steps, and a guessed Objective-C signature is the
`posix_spawnattr_t` hazard in ObjC clothing. 27 declarations written by hand,
each citing its call site and its assignment context, is both faster and more
trustworthy than the parser that would produce them.

The tool earned its keep: **147 of 178 call sites derived mechanically**, with
every one citing its source. The last 31 are the residue it was never the right
instrument for.

### Curve, complete

| step | compiling | unknown |
|---|---|---|
| 0 — `@class` only | 69 / 82 | — |
| 1 — types header | 73 / 82 | 151 |
| 2a — hand-written | 77 / 82 | 155 |
| 2b — derived + reconciled | 77 / 82 | 50 |
| 3 — machorun master SDK | 75 / 82 | 50 |
| 4 — iteration 2 | 75 / 82 | **31** |

`155 → 50 → 31`, compile count never moved for a reason inside this work. The
one drop, 77 → 75, was machorun's `constrained_ctypes.h` regression, and the
second column is what made that attributable rather than suspicious.

## 33. CORRECTION: the last 31 are tool gaps, not evidence gaps

**§32 is wrong and this supersedes it.** I claimed 27 of the remaining 31 reach
CF through `CF_OBJC_CALLV`, which "carries no return type — the type lives in
the caller's assignment target, one scope up", and concluded that mechanising
further would be "guessing with extra steps". I then recommended stopping the
tooling on that basis, and that recommendation was accepted.

I never checked the call sites. Classifying all 31 by how they are actually
invoked:

```
14  CF_OBJC_CALLV
13  CF_OBJC_FUNCDISPATCHV
 3  CF_SWIFT_FUNCDISPATCHV
 1  CFTYPE_OBJC_FUNCDISPATCH0
```

**Every one has a determinable return type, and none requires looking one scope
up:**

- The 14 `CF_OBJC_CALLV` sites carry the type **as a cast on the same line** —
  `scheme = (CFStringRef) CF_OBJC_CALLV((NSURL *)anURL, scheme);`,
  `(CFNumberRef) ... port`, `(Boolean) ... isFileReferenceURL`. The deriver
  simply never looked left of the macro.
- The 13 `CF_OBJC_FUNCDISPATCHV` sites carry it **explicitly as a macro
  argument**, as they always did. They failed on *unnamed parameter labels*
  (`_addComponents::::`), which is a regex limitation.
- The 3 `CF_SWIFT_FUNCDISPATCHV` sites use a macro the tool was never taught.
- `_cfTypeID` is `CFTYPE_OBJC_FUNCDISPATCH0`, also explicit.

So the residue is **entirely tool gaps** — three small ones — and contains no
absence of evidence at all.

### What went wrong in the reasoning

I formed the "no return type at the call site" claim from the deriver's own
failure message, which said `CF_OBJC_CALLV: return type from context`. That
message was **my own text**, written when I built the tool, encoding an
assumption I had never verified. I then treated my tool's output as evidence
about CoreFoundation, and built an architectural recommendation on it.

That is the same shape as the diagnostic that lied in §31 — except that time the
misleading message cost an afternoon of misdirected implementation, and this
time it produced a *conclusion* that was accepted and recorded. A tool's
explanation of why it failed is a claim by its author, not a measurement.

The conclusion "write these 31 by hand" may still be reasonable — 31 is small,
and hand-written declarations with citations are trustworthy. But it should be
chosen because it is *cheap*, not because the evidence is missing. It is not
missing. And the general principle I offered — knowing where to stop
mechanising — was sound in the abstract and applied here to a case that did not
warrant it.

## 34. The three tool fixes, and the retraction vindicated

§33 said the residue was tool gaps, not evidence gaps. Three fixes tested that:

1. **Look left of `CF_OBJC_CALLV` for the cast** — the return type was on the
   same line all along.
2. **Allow empty parameter labels** — `_addComponents::::` is four unnamed
   arguments; filtering empty labels out silently turned it into a one-argument
   selector and failed the arity check.
3. **Recognise `CF_SWIFT_FUNCDISPATCHV`** — a different dispatch mechanism,
   now reported accurately instead of as "unrecognised macro".

| step | compiling | unknown |
|---|---|---|
| 0 — `@class` only | 69 / 82 | — |
| 1 — types header | 73 / 82 | 151 |
| 2a — hand-written | 77 / 82 | 155 |
| 2b — derived + reconciled | 77 / 82 | 50 |
| 3 — machorun master SDK | 75 / 82 | 50 |
| 4 — iteration 2 | 75 / 82 | 31 |
| **5 — three tool fixes** | **75 / 82** | **18** |

**155 → 50 → 31 → 18**, 157 declarations across 24 classes, every one citing its
call site. Had I acted on §32 the tool would have been put down at 31 with the
work handed to hand-writing on a false premise.

### A ninth wipeout, from the fix itself

Widening the `CALLV` receiver pattern to accept `id` produced
`@interface id : NSObject` — redefining objc's `id` and taking the census to
zero. `CF_OBJC_CALLV((id)other, _cfMutableCopy)` has an **untyped receiver**:
there is no class to declare the method on, so the right output is a report, not
a declaration.

The generator now refuses to emit an `@interface` for anything that is not an
`NS`-prefixed class, in the same spirit as the balanced-paren check: *a
generator that declines to emit is safe; one that emits garbage is not.* That
guard has now caught two distinct classes of malformed output.

### `unknown-method set: 0` was the wipeout, not success

The failing run reported **zero** unknown methods — which reads as total
convergence and was total failure: nothing compiled, so nothing warned.

This is the sharpest vindication of the paired columns in the whole exercise.
Read alone, "unknown methods: 0" is the number this entire loop was driving
toward. Only `PASS=0` alongside it says what actually happened. The standing
rule — treat zero or unchanged as suspect, not only improvements — was written
for exactly this and still nearly caught me by surprise.

## 35. Class registration: mechanism added, registration deliberately NOT done

`scripts/patch_cf_objc.py` now also restores `_CFRuntimeBridgeClasses`, the
function corelibs is missing:

```c
CF_PRIVATE void _CFRuntimeBridgeClasses(CFTypeID typeID, const char *classname) {
    Class cls = objc_lookUpClass(classname);
    if (cls) _SetCFRuntimeObjcClass((uintptr_t)cls, typeID);
}
```

Verified present: `__CFRuntimeBridgeClasses` is a defined symbol in `CFRuntime.o`,
and the census holds at 75/82 with 18 unknown methods.

**Nothing calls it, and that is deliberate. Class registration is NOT done.**
`CF_IS_OBJC` still works by accident, exactly as before, and this section should
not be read as having closed that hole.

Three reasons for stopping at the mechanism:

1. **Partial registration is worse than none.** The accidental correctness holds
   only while the table is uniformly empty: every native instance gets
   `_cfisa = 0` and every foreign object has a real isa. Register *some* types
   and the unregistered ones invert — their own instances start reading as
   foreign ObjC objects and CF messages structs. So this is all-or-nothing per
   type, and "add a few call sites to make progress" is the one approach
   guaranteed to be wrong.

2. **The classes to register do not exist yet.** Apple binds `_kCFRuntimeIDCFString`
   to `__NSCFString`, `CFArray` to `__NSCFArray`, and so on — the concrete
   bridge classes that wrap a CF object. Our Foundation has no `__NSCF*` classes,
   so `objc_lookUpClass` would return nil for every one and the function would
   correctly do nothing. Registration is downstream of the `NS*` implementation,
   not a precursor to it.

3. **It cannot be verified at runtime yet.** CoreFoundation does not link — that
   is blocked on libdispatch (#47) — so there is no way to observe whether
   registration makes `CF_IS_OBJC` right on purpose. Landing an unverifiable
   change to the one mechanism whose current correctness is accidental is
   precisely the wrong risk to take.

### The test this needs, when CF links

Not "does it compile". Construct both cases and assert the predicate:

- a **native CF object** (`CFStringCreateWithCString`) — `CF_IS_OBJC` must be
  **false**, and its `_cfisa` must equal `__CFISAForTypeID(_kCFRuntimeIDCFString)`
- a **foreign ObjC object** (our `NSString` subclass) — `CF_IS_OBJC` must be
  **true**
- an **unregistered type**, to prove the inversion hazard is understood rather
  than merely described

Both halves, on both sides — the counter-practice this project already uses for
negative controls. A test that only checks the native case would pass today,
with the table empty, and prove nothing about registration at all.

## 36. Class registration: the guard, and a correction to §35's premise

§35 said registration was all-or-nothing per type because "the accidental
correctness holds only while the table is uniformly empty: register *some*
types and the unregistered ones invert". **That is wrong, and measuring it is
what found the real defect.**

`_CFRuntimeCreateInstance` sets `memory->_cfisa = __CFISAForTypeID(typeID)`
(CFRuntime.c:550) — it initialises the instance from *the very slot* that
`CF_IS_OBJC` later compares against. So a CF-created instance matches its own
type's slot whether or not that type was ever registered. Registered and
unregistered types are each **self-consistent**; unregistered types do not
invert when a neighbour registers.

The hazard is **temporal**, not partial. An instance created *before* its type
is registered keeps `_cfisa = 0` while the slot later holds a class, and CF then
reads that instance as foreign and messages a struct. Registration must
therefore happen in `__CFInitialize`, before any instance exists. The checker
enforces exactly that as `MISPLACED`.

### The one category that is inconsistent today: constant strings

Objects whose `_cfisa` does *not* come from the table are the real exposure, and
there is exactly one such category. Measured, not reasoned:

* `__CONSTANT_CFSTRINGS__` is defined for our target (`clang -E`, and the census
  already passes `-fconstant-cfstrings`), so `CFSTR` takes the compiler-builtin
  path, not `STATIC_CLASS_REF`.
* In `CFRuntime.o`, **every** `__cfstring` entry's isa slot relocates against
  `___CFConstantStringClassReference` (`llvm-objdump -r --section=__cfstring`).
* `CFRuntime.o` **defines** that symbol — `S ___CFConstantStringClassReference`
  — as corelibs' zeroed `int[24]` (CFRuntime.c:286).

Nonzero isa, zero slot ⇒ `CF_IS_OBJC(_kCFRuntimeIDCFString, CFSTR("x"))` is
**already true**, and restoring the dispatch macros armed it. CF would message
a zeroed array as a class. On macOS the same address is a real ObjC class:

```
CFSTR isa  == &__CFConstantStringClassReference  -> __NSCFConstantString
provided by /System/.../CoreFoundation      [s length] == 5
```

So the fix is not registration — it is that our Foundation must supply
`___CFConstantStringClassReference` as a real class **and CF's placeholder
definition must go**. Two definitions in two dylibs would split constant strings
across two "classes" silently. Checked as `CONSTANT_STRING`.

### A hypothesis measurement killed

The four static CF objects (`kCFBooleanTrue/False`, `kCFNull`, the allocators)
looked like the same bypass — their initialisers name a class outright,
`INIT_CFRUNTIME_BASE_WITH_CLASS(__NSCFBoolean, _kCFRuntimeIDCFBoolean)`. They
are not. `STATIC_CLASS_REF` expands to `NULL` in our configuration
(ForFoundationOnly.h:790), confirmed by compiling a probe TU and finding **no
undefined ObjC class reference** in `CFNumber.o` or `CFBase.o`. Those objects
get `_cfisa = 0` and stay consistent with the empty table. Reading the `#if`
ladder would have been ambiguous; the object file was not.

### `scripts/check_registration.py` — refuses, does not warn

Derives the BRIDGED set from CF's own source: a type is bridged iff it appears
as the first argument of `CF_IS_OBJC` / `CF_OBJC_[RETAINED_]FUNCDISPATCHV`.
**19 of CF's 56 typeIDs.** `docs/cf-registration.tsv` adjudicates all 56 and
names the class for each bridged one; the checker fails on disagreement in
either direction, so the table cannot invent membership and cannot omit it.

Seven refusal modes: `UNADJUDICATED`, `STALE`, `CONTRADICTED`, `UNREGISTERED`,
`MISSING_CLASS`, `MISPLACED`, `CONSTANT_STRING`.

Teeth demonstrated on both sides, per standing practice:

| control | result |
|---|---|
| today's real state | REFUSES, 39 problems (19 MISSING_CLASS, 19 UNREGISTERED, 1 CONSTANT_STRING) |
| synthesised complete state (19 calls in `__CFInitialize`, 19 classes listed) | **exit 0** |
| one call moved out of `__CFInitialize` | REFUSES, 1 MISPLACED |
| object that does not define the constant-string symbol | check silent |
| `--objdir` absent | reports NOT MEASURED — never reads as clean |

The `CFTYPE_IS_OBJC` path (behind `CFGetTypeID`/`CFEqual`/`CFHash`) is
deliberately *not* evidence of bridging: it applies to every type but compares
against that type's own slot, so unregistered types stay self-consistent under
it. Eight dispatch sites pass a local variable and cannot be attributed by the
tool; it prints them rather than dropping them. All eight are in CFBag,
CFDictionary, CFSet and CFRuntime, whose types are already BRIDGED by resolved
sites elsewhere, so they add no members — adjudicated here, not in the tool.

**Registration is still NOT wired up.** The 19 `__NSCF*` classes do not exist,
so all 19 would be `objc_lookUpClass` → nil. The refusal list *is* the work
order for the NS* implementations, and this is the same call as §35 for a
better-measured reason.
