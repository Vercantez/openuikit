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
