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
