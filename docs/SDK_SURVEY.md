# The SDK surface, measured

**The question.** `scripts/build_objc4.sh` needs `-isysroot` pointing at Apple's
macOS SDK. That is a **non-redistributable build input** — `docs/OBJC4_MACHO.md`
§7 lists it as the single biggest thing that got *harder* when objc4 moved from
ELF to Mach-O, and `docs/UNIMPLEMENTED.md#objc-sdk-dependency` records that the
build is therefore reproducible on a machine with Xcode and not otherwise. The
milestone replaces it with our own **header-only + `.tbd`-only SDK**. This
document is the inventory that milestone needs. It writes no SDK.

**The headline, and it is better than expected.**

> Of the **355** distinct C/Darwin headers our builds actually open, **351** are
> obtainable from Apple's own open-source releases (10 of them via a generation
> step from source that *is* published), and the remaining **4** are pure macro
> machinery that between them contribute exactly **71** macros anything else
> references. **The "genuinely only in the Xcode SDK, and not writable" category
> is empty.**
>
> The other **734** headers are Apple's libc++, and they are replaceable
> wholesale: objc4 built against **stock LLVM 18 libc++** scores **41/44** on the
> differential corpus and produces a byte-identical `09_objc` — the same numbers
> as the Apple-SDK build, measured, not assumed.
>
> `ld64.lld-18` reads hand-written tbd-v4 files. A guest compiled and linked
> **entirely on Linux**, against `.tbd` files generated mechanically from our own
> dylibs, with **zero** Apple headers, runs correctly under machorun. The
> fallback to stub `.dylib`s is not needed.

Everything below is measured on 2026-08-26. Reproduction commands are in §7.

---

## 0. Method, and what it does not cover

**Headers were measured, not read off `#include` lines.** Every compile that
this project performs was re-run with `clang -MD`, and the dependency files were
unioned. `-MD` records the files the preprocessor actually *opened*, so a header
guarded out by an `#if` does not appear, and one reached only through six levels
of indirection does.

Two sysroots are involved, because two machines compile:

| what we build | where | sysroot | how measured |
|---|---|---|---|
| `libobjc.A.dylib` from `vendor/objc4` | Linux, `machorun-testbed:24.04` | `build/sdk/MacOSX.sdk` — staged `usr/include` from **MacOSX15.4.sdk** (Command Line Tools) | `DARWIN_CLANG=` wrapper adding `-MD`, then union of `build/objc4-macho-obj/*.d` |
| `libSystem.B.dylib`, `libc++.1.dylib` | Linux, same container | **none** (`-nostdinc`) | same wrapper |
| `tests/bin/*` (21 fixtures) | macOS, Apple clang 17 | Xcode **MacOSX26.1.sdk** | `clang -M` over `tests/src/*` |
| `tests/objc44/*` (44 corpus binaries) | macOS, Apple clang 17 | Xcode **MacOSX26.1.sdk** | `clang -M` over `~/objc4-linux/tests/*.m` |

So the union spans two SDK revisions, 15.4 and 26.1. That is a feature — a
header set that satisfies both is less likely to be pinned to one Xcode.

**What this survey does *not* establish.** It does not build an SDK and does not
prove one works. The acceptance test for the next agent is unchanged and
unambiguous: `scripts/build_objc4.sh` against the new sysroot, then
`scripts/difftest.sh` and `scripts/objc44.sh` at **19 pass / 1 xfail / 1
no-oracle** and **41/44**. Nothing here should be taken as a substitute for that
run.

---

## 1. Which headers are actually reached

### 1.1 The counts

`libSystem.B.dylib` and `libc++.1.dylib` are built with `-nostdinc`, and the
measurement confirms what the script claims: they open **zero** SDK headers and
**zero** clang resource headers. The complete dependency set is three files of
our own.

```
darwin/src/dsys.h   darwin/src/errno_table.h   darwin/src/rune_table.h
```

**The SDK dependency is entirely objc4's, plus the fixtures'.**

| build | total files opened | SDK headers | of which `c++/v1` | of which C/Darwin | clang resource | `vendor/objc4-priv` | objc4's own |
|---|---|---|---|---|---|---|---|
| objc4 (32 TUs) | 1,157 | **1,056** | 712 | **344** | 19 | 19 (of 25 vendored) | 63 |
| fixtures + objc44 (61 sources) | 861 | **791** | 512 | **279** | 22 | — | — |
| **union (by relative path)** | | **1,089** | **734** | **355** | | | |

(The objc4 row's 63 are 55 distinct files, reached through both `vendor/objc4/runtime/`
and the `build/objc4-macho-gen/include/objc/` symlink tree the build script creates.)

The two halves of the SDK surface behave completely differently and are treated
separately from here on:

* **`usr/include/c++/v1/**` — 734 headers, 67% of the surface.** Apple's libc++.
  Not Darwin at all. §2.5 measures replacing it.
* **the other 355.** The actual Darwin C surface. §2.1–§2.4 classify it.

The 19 `vendor/objc4-priv/` headers that are reached (of 25 vendored) are already
hand-written clean-room declarations — 900 lines total, no Apple licence blocks
— and are not part of this problem. They are the model for §2.4's answer:

```
_simple.h  Block_private.h  CrashReporterClient.h  crt_externs.h
mach-o/dyld_priv.h  malloc_private.h  objc-probes.h  os/bsd.h
os/feature_private.h  os/linker_set.h  os/lock_private.h  os/reason_private.h
os/variant_private.h  ptrauth.h  Rosetta/Rosetta.h  Rosetta/Traps.h
sandbox/private.h  sys/reason.h  System/pthread_machdep.h
```

(The 6 vendored-but-unreached ones — `kern/restartable.h`,
`malloc_type_private.h`, `objc-shared-cache.h`, `os/thread_self_restrict.h` and
friends — are reached only in configurations `patches-macho/` turns off. Keep
them; they cost nothing and they document the SPI objc4 would want back.)

### 1.2 The 355 C/Darwin headers, grouped by directory

Attribution is by path match against Apple's published sources (§2.1). A `*`
marks a header **not** found by path in any open-source release; all 20 of those
are accounted for individually in §2.2–§2.4.

```
### sys/  (106)   sources: xnu×91, libpthread×12, unmatched×2, Libc×1
    __endian.h _endian.h _posix_availability.h* _pthread/_pthread_attr_t.h _pthread/_pthread_cond_t.h
    _pthread/_pthread_condattr_t.h _pthread/_pthread_key_t.h _pthread/_pthread_mutex_t.h
    _pthread/_pthread_mutexattr_t.h _pthread/_pthread_once_t.h _pthread/_pthread_rwlock_t.h
    _pthread/_pthread_rwlockattr_t.h _pthread/_pthread_t.h _pthread/_pthread_types.h _select.h _symbol_aliasing.h*
    _types.h _types/_blkcnt_t.h _types/_blksize_t.h _types/_caddr_t.h _types/_clock_t.h _types/_ct_rune_t.h
    _types/_dev_t.h _types/_errno_t.h _types/_fd_clr.h _types/_fd_copy.h _types/_fd_def.h _types/_fd_isset.h
    _types/_fd_set.h _types/_fd_setsize.h _types/_fd_zero.h _types/_filesec_t.h _types/_fsblkcnt_t.h
    _types/_fsfilcnt_t.h _types/_fsid_t.h _types/_fsobj_id_t.h _types/_gid_t.h _types/_id_t.h _types/_in_addr_t.h
    _types/_in_port_t.h _types/_ino64_t.h _types/_ino_t.h _types/_int16_t.h _types/_int32_t.h _types/_int64_t.h
    _types/_int8_t.h _types/_intptr_t.h _types/_key_t.h _types/_mach_port_t.h _types/_mbstate_t.h _types/_mode_t.h
    _types/_nlink_t.h _types/_null.h _types/_o_dsync.h _types/_o_sync.h _types/_off_t.h _types/_os_inline.h
    _types/_pid_t.h _types/_posix_vdisable.h _types/_ptrdiff_t.h _types/_rsize_t.h _types/_rune_t.h
    _types/_s_ifmt.h _types/_seek_set.h _types/_sigaltstack.h _types/_sigset_t.h _types/_size_t.h
    _types/_ssize_t.h _types/_suseconds_t.h _types/_time_t.h _types/_timespec.h _types/_timeval.h
    _types/_timeval64.h _types/_u_char.h _types/_u_int.h _types/_u_int16_t.h _types/_u_int32_t.h
    _types/_u_int64_t.h _types/_u_int8_t.h _types/_u_short.h _types/_ucontext.h _types/_uid_t.h
    _types/_uintptr_t.h _types/_useconds_t.h _types/_uuid_t.h _types/_va_list.h _types/_wchar_t.h _types/_wint_t.h
    appleapiopts.h cdefs.h errno.h fcntl.h mman.h param.h qos.h resource.h select.h signal.h stat.h stdio.h
    syslimits.h syslog.h time.h types.h unistd.h wait.h

### mach/  (85)   sources: xnu×72, unmatched×10, cctools×3
    arm/_structs.h arm/boolean.h arm/exception.h arm/kern_return.h arm/processor_info.h arm/rpc.h
    arm/thread_state.h arm/thread_status.h arm/vm_param.h arm/vm_types.h boolean.h clock_priv.h* clock_types.h
    dyld_kernel.h error.h exception_types.h host_info.h host_notify.h host_priv.h* host_security.h*
    host_special_ports.h kern_return.h kmod.h mach.h mach_error.h mach_host.h* mach_init.h mach_interface.h
    mach_port.h* mach_time.h mach_traps.h mach_types.h mach_voucher_types.h machine.h machine/_structs.h
    machine/boolean.h machine/exception.h machine/kern_return.h machine/processor_info.h machine/rpc.h
    machine/thread_state.h machine/thread_status.h machine/vm_param.h machine/vm_types.h memory_object_types.h
    message.h mig.h mig_errors.h mig_strncpy_zerofill_support.h ndr.h notify.h policy.h port.h processor.h*
    processor_info.h processor_set.h* rpc.h semaphore.h shared_region.h std_types.h sync_policy.h task.h*
    task_info.h task_inspect.h task_policy.h task_special_ports.h thread_act.h* thread_info.h thread_policy.h
    thread_special_ports.h thread_status.h thread_switch.h time_value.h vm_attributes.h vm_behavior.h vm_inherit.h
    vm_map.h* vm_page_size.h vm_param.h vm_prot.h vm_purgable.h vm_region.h vm_statistics.h vm_sync.h vm_types.h

### (root)  (61)   sources: Libc×47, xnu×5, unmatched×3, libunwind×2, libpthread×2, dyld×1, Libm×1
    Availability.h AvailabilityInternal.h AvailabilityInternalLegacy.h* AvailabilityMacros.h
    AvailabilityVersions.h* Block.h TargetConditionals.h* ___wctype.h __libunwind_config.h __wctype.h __xlocale.h
    _abort.h _bounds.h _ctermid.h _ctype.h _inttypes.h _locale.h _locale_posix2008.h _mb_cur_max.h _printf.h
    _static_assert.h _stdio.h _stdlib.h _string.h _strings.h _time.h _types.h _wchar.h _wctype.h _xlocale.h
    alloca.h assert.h crt_externs.h ctype.h dlfcn.h errno.h execinfo.h fcntl.h gethostuuid.h getopt.h inttypes.h
    libunwind.h limits.h locale.h math.h nl_types.h pthread.h runetype.h sched.h stddef.h stdint.h stdio.h
    stdlib.h string.h strings.h syslog.h time.h unistd.h wchar.h wctype.h xlocale.h

### dispatch/  (14)   sources: libdispatch×14
    base.h block.h data.h dispatch.h dispatch_swift_shims.h group.h io.h object.h once.h queue.h semaphore.h
    source.h time.h workloop.h

### arm/  (11)   sources: xnu×11
    _endian.h _limits.h _mcontext.h _param.h _types.h arch.h endian.h limits.h param.h signal.h types.h

### os/  (11)   sources: libdispatch×6, xnu×3, unmatched×1, libplatform×1
    availability.h* base.h clock.h lock.h object.h overflow.h workgroup.h workgroup_base.h workgroup_interval.h
    workgroup_object.h workgroup_parallel.h

### _types/  (10)   sources: Libc×10
    _intmax_t.h _locale_t.h _nl_item.h _uint16_t.h _uint32_t.h _uint64_t.h _uint8_t.h _uintmax_t.h _wctrans_t.h
    _wctype_t.h

### libkern/  (9)   sources: libplatform×5, xnu×4
    OSAtomic.h OSAtomicDeprecated.h OSAtomicQueue.h OSByteOrder.h OSCacheControl.h OSSpinLockDeprecated.h
    _OSByteOrder.h arm/OSByteOrder.h arm/_OSByteOrder.h

### xlocale/  (9)   sources: Libc×9
    ___wctype.h _ctype.h _inttypes.h _stdio.h _stdlib.h _string.h _time.h _wchar.h _wctype.h

### machine/  (8)   sources: xnu×8
    _endian.h _mcontext.h _types.h endian.h limits.h param.h signal.h types.h

### mach_debug/  (7)   sources: xnu×7
    hash_info.h ipc_info.h lockgroup_info.h mach_debug_types.h page_info.h vm_info.h zone_info.h

### mach-o/  (6)   sources: cctools×5, dyld×1
    dyld.h fat.h getsect.h ldsyms.h loader.h nlist.h

### malloc/  (5)   sources: libmalloc×5
    _malloc.h _malloc_type.h _platform.h _ptrcheck.h malloc.h

### objc/  (4)   sources: unmatched×4  -- these are objc4's own, already in vendor/objc4
    message.h* objc-api.h* objc.h* runtime.h*

### secure/  (4)   sources: Libc×4
    _common.h _stdio.h _string.h _strings.h

### pthread/  (3)   sources: libpthread×3
    pthread_impl.h qos.h sched.h

### architecture/  (1)   sources: xnu×1
    byte_order.h

### uuid/  (1)   sources: xnu×1
    uuid.h
```

Two observations worth flagging before the classification:

* **`sys/` is 106 headers and 86 of them are `sys/_types/*` and
  `sys/_pthread/*`** — one typedef per file. Darwin's C library is unusually
  fragmented, which inflates the count and *deflates* the difficulty: they are
  three lines each and they are all in xnu.
* **`mach/` is 85 headers, and objc4 references exactly 3 Mach routines**
  (`mach_task_self_`, `vm_allocate`, `vm_remap`). The whole corpus references 10.
  The size of `mach/` is `<mach/mach.h>`'s transitive closure, not our
  requirement. That matters for §2.3.

### 1.3 The libc++ half, summarised

712 (objc4) ∪ 512 (fixtures) = **734** distinct paths under `usr/include/c++/v1/`.
By subdirectory, from the objc4 side: `__algorithm` 198, `__type_traits` 116,
`__iterator` 41, `__memory` 31, `__functional` 26, `__utility` 23, `__concepts`
22, `__math` 20, `__fwd` 20, `__format` 17, `__atomic` 16, then a long tail.

The public headers objc4 names directly are ordinary: `algorithm atomic bit
cassert cinttypes cstddef cstdint cstdlib cstring functional initializer_list
iterator limits map new type_traits unordered_map utility vector`. Only
`05b_cxx_init.cpp` on the fixture side pulls in iostreams.

---

## 2. Classification

### 2.1 Method

Three independent signals, because "I think that's open source" is not a
measurement:

1. **Path match against Apple's published trees.** The full recursive git trees
   of `apple-oss-distributions/{xnu, Libc, libpthread, libplatform, libdispatch,
   libmalloc, libclosure, dyld, cctools, libunwind, Libm}` were fetched (none
   truncated; xnu alone is 6,072 blobs) and each of our 355 relative paths was
   matched by suffix.
2. **Licence marker in the SDK copy itself.** Over the 344 headers the objc4
   build reaches: `@APPLE_OSREFERENCE_LICENSE_HEADER` (xnu's APSL form) **212**,
   `@APPLE_LICENSE_HEADER` (APSL) **74**, Apache-2.0 **24**, BSD **15**, no
   licence grant at all **19**. The 19 with no grant are exactly the MIG output
   and a handful of xnu `bsd/arm/*` files that carry only a copyright line
   upstream too.
3. **Content drift.** 24 load-bearing headers were fetched from the matched
   open-source path and line-diffed against the SDK copy. **19 of 24 are ≥90%
   line-identical**; 14 are 100%.

| header | open-source path | % of SDK lines present verbatim |
|---|---|---|
| `stdio.h`, `string.h`, `errno.h`, `ctype.h`, `stdlib.h`, `time.h`, `runetype.h`, `stdint.h`, `_abort.h`, `_bounds.h` | `Libc:include/…` | **100%** |
| `libkern/OSAtomic.h`, `os/lock.h`, `malloc/_ptrcheck.h`, `mach-o/getsect.h` | `libplatform`, `libmalloc`, `cctools` | **100%** |
| `mach/mach_time.h`, `sys/stat.h`, `mach/message.h`, `sys/_types.h`, `mach/mach.h`, `mach/vm_param.h`, `dispatch/dispatch.h` | xnu / libdispatch | **100%** |
| `mach-o/loader.h` | `cctools:include/mach-o/loader.h` | 99.2% |
| `sys/mman.h` | `xnu:bsd/sys/mman.h` | 99.3% |
| `sys/cdefs.h` | `xnu:bsd/sys/cdefs.h` | 98% |
| `unistd.h` | `Libc:include/unistd.h` | 98.2% |
| `dlfcn.h` | `dyld:include/dlfcn.h` | 98.1% |
| `pthread.h` | `libpthread:include/pthread/pthread.h` | 99% |
| `malloc/malloc.h` | `libmalloc:include/malloc/malloc.h` | 94% |
| `Block.h` | `xnu:libkern/libkern/Block.h` | 89% |
| `malloc/_malloc_type.h` | `libmalloc:include/malloc/_malloc_type.h` | 77% |
| `libunwind.h` | `libunwind:libunwind/include/libunwind.h` | 66% |
| `Availability.h` | `xnu:EXTERNAL_HEADERS/Availability.h` | **47%** |

Two traps this exposed, and the next agent should not re-fall into them:

* **`sys/cdefs.h` exists in both `Libc` and `xnu`.** Libc's is a **124-line
  wrapper**; xnu's `bsd/sys/cdefs.h` is the real 1,432-line one and is the 98%
  match. A naive "first repo that has the basename" attribution picks the wrong
  file. The same applies to `stdio.h`/`string.h` (Libc's `include/`, not xnu's
  `bsd/sys/` or `libsyscall/mach/`) and `os/lock.h` (libplatform's
  `include/os/`, not its `include/exclavekit/os/`).
* **`Availability.h` at 47% means xnu's `EXTERNAL_HEADERS` copy is a stale
  snapshot** (420 lines against the SDK's 625), not that the header is
  unavailable. See §2.4 — the whole availability family is better clean-roomed
  than vendored.

### 2.2 Category (a): obtainable from Apple's open-source releases

**335 of 355 headers match a published path directly.** By upstream project:

| project | headers | licence | what it supplies here |
|---|---|---|---|
| **xnu** | 203 | APSL 2.0 | `sys/*` (91), `mach/*` (72), `arm/*` (11), `machine/*` (8), `mach_debug/*` (7), `libkern/*` (4), `architecture/byte_order.h`, `uuid/uuid.h`, `Block.h`, `Availability{,Internal,Macros}.h` |
| **Libc** | 71 | APSL 2.0 | the C library surface: `stdio.h`, `stdlib.h`, `string.h`, `ctype.h`, `runetype.h`, `time.h`, `locale.h`, `_types/*` (10), `xlocale/*` (9), `secure/*` (4), `_*.h` internals |
| **libdispatch** | 20 | Apache-2.0 | `dispatch/*` (14), `os/{base,object,workgroup*}.h` |
| **libpthread** | 17 | APSL 2.0 | `pthread.h`, `sched.h`, `pthread/*` (3), `sys/_pthread/*` (12) |
| **cctools** | 8 | APSL 2.0 | `mach-o/{loader,nlist,fat,getsect,ldsyms}.h`, `mach/machine.h` and friends |
| **libplatform** | 6 | APSL 2.0 | `os/lock.h`, `libkern/OSAtomic*.h`, `libkern/OSSpinLockDeprecated.h` |
| **libmalloc** | 5 | APSL 2.0 | `malloc/*` |
| **libunwind** | 2 | Apache-2.0 w/ LLVM exception | `libunwind.h`, `__libunwind_config.h` |
| **dyld** | 2 | APSL 2.0 | `dlfcn.h`, `mach-o/dyld.h` |
| **Libm** | 1 | APSL 2.0 | `math.h` |

All of these licences permit redistribution. **This tree can be vendored into
the repository.**

Three more are category (a) with a **generation step from published source**:

* **`sys/_posix_availability.h` and `sys/_symbol_aliasing.h`** are not blobs in
  xnu — they are *outputs* of `xnu:bsd/sys/make_posix_availability.sh` and
  `xnu:bsd/sys/make_symbol_aliasing.sh`, both present. Run the scripts.
* **`objc/{objc,runtime,message,objc-api}.h`** (reached by the fixture side) are
  **objc4's own**, already at `vendor/objc4/runtime/` and already exposed
  through the `build/objc4-macho-gen/include/objc/` symlink tree that
  `scripts/build_objc4.sh` builds. Nothing new is required; the SDK just needs
  to point at them.

### 2.3 The 10 MIG-generated `mach/` headers

```
mach/clock_priv.h   mach/host_priv.h    mach/host_security.h  mach/mach_host.h
mach/mach_port.h    mach/processor.h    mach/processor_set.h  mach/task.h
mach/thread_act.h   mach/vm_map.h
```

These carry no licence block because they are not written by hand — they are
**MIG output**. Every one of the 10 `.defs` inputs is published, twice over
(`xnu:osfmk/mach/<name>.defs` and `xnu:libsyscall/mach/<name>.defs`, both
verified present).

Two routes, and the second is cheaper:

1. **Run MIG.** `bootstrap_cmds` (which contains `migcom`) is Apple open source,
   so the generated headers would be an APSL derivative and redistributable.
   Cost: porting a Mach-specific code generator to Linux.
2. **Hand-write them**, exactly as `vendor/objc4-priv/` already does for 25
   SPI headers. The 10 headers declare **237** routines between them. Measured
   references: **6 from objc4's source** (`mach_port_deallocate`, `task_threads`,
   `thread_get_state`, `vm_allocate`, `vm_deallocate`, `vm_remap`) and **41 more
   named anywhere in the other reached SDK headers**, for a union of **47**. And
   of the 237, the *linked* corpus references only 10 Mach symbols in total
   (§3.2). The types they need (`kern_return_t`, `mach_port_t`, `vm_prot_t`,
   `vm_address_t`, `thread_state_t`, …) all come from non-MIG `mach/*` headers
   that xnu does publish.

**Recommendation: hand-write.** It matches an existing, working precedent in this
repo, it is ~50 declarations rather than a tool port, and a missing declaration
is a compile error rather than a silent divergence.

### 2.4 Category (b): trivially writable clean-room — and category (c) is empty

Four headers match **nothing** in any Apple open-source release:

| header | SDK size | what it is |
|---|---|---|
| `TargetConditionals.h` | 534 lines / 18 KB | `TARGET_OS_*`, `TARGET_CPU_*`, `TARGET_RT_*` |
| `AvailabilityVersions.h` | 466 lines / 28 KB | `__MAC_10_4` … `__MAC_15_4`, `MAC_OS_VERSION_*`, and the iOS/tvOS/watchOS/visionOS equivalents |
| `AvailabilityInternalLegacy.h` | 4,346 lines / **414 KB** | the pre-`__API_AVAILABLE` `__OSX_AVAILABLE_STARTING` expansion matrix |
| `os/availability.h` | 294 lines / 15 KB | `API_AVAILABLE`, `API_DEPRECATED`, `API_UNAVAILABLE` |

And three more that match only a **stale** xnu `EXTERNAL_HEADERS` snapshot
(`Availability.h` is 47% line-identical, §2.1), so they belong here in practice:
`Availability.h` (625 lines), `AvailabilityInternal.h` (536), `AvailabilityMacros.h`
(3,985).

Together those seven files are **10,786 lines / 782 KB** and define **2,648
macros**. The measurement that matters:

> Of those 2,648 macros, **63** are referenced by the other 337 reached SDK
> headers and **23** by objc4's own source. The union is **71**.
>
> — 35 version constants (`__MAC_10_9`, `MAC_OS_X_VERSION_10_12`, …)
> — 22 availability attributes (`__API_AVAILABLE`, `__OSX_AVAILABLE_STARTING`,
>    `__SPI_AVAILABLE`, `DEPRECATED_ATTRIBUTE`, `API_UNAVAILABLE`, …)
> — 8 `TARGET_*` (`TARGET_OS_MAC`, `TARGET_OS_OSX`, `TARGET_OS_IPHONE`,
>    `TARGET_OS_SIMULATOR`, `TARGET_OS_EMBEDDED`, `TARGET_OS_MACCATALYST`,
>    `TARGET_OS_WIN32`, `TARGET_CPU_ARM64`)
> — 6 others (`__OS_AVAILABILITY`, `__OS_AVAILABILITY_MSG`, `__IOS_PROHIBITED`,
>    `__{TV,WATCH,VISION}_OS_VERSION_MIN_REQUIRED`)

782 KB of generated matrix collapses to **71 macros**, and every availability
attribute may legitimately expand to nothing — we are not shipping a public API
whose availability anyone checks. `docs/OBJC4_MACHO.md` §1 already records the
five predefines that have to come out right (`TARGET_OS_MAC=1`, `TARGET_OS_OSX=1`,
`__OBJC_BOOL_IS_BOOL=1`, `__arm64__`, `__arm64`), and clang supplies the last
three itself for an Apple target.

**Therefore the category the task asked me to enumerate precisely — "genuinely
only in the Xcode SDK" — is empty.** There is no header we need whose *content*
is unobtainable. The closest thing to a category-(c) item is the 25
Apple-internal SPI headers in `vendor/objc4-priv/`, and that bridge was crossed
in the previous milestone: 900 hand-written lines, no Apple text, already
committed. `ptrauth.h` is in that tree too and is not an Apple-SDK header at all
— it is a **clang resource header** that Ubuntu's `clang-18` does not ship.

### 2.5 The libc++ half — measured, not argued

67% of the SDK surface is Apple's libc++. The question is whether stock LLVM
libc++ substitutes. Measured, in the test container, in four steps:

**Step 1 — naive substitution fails, for a nameable reason.**
`-nostdinc++ -isystem /usr/lib/llvm-18/include/c++/v1` produces **22 of 28 C++
TUs failing**, all with the same root cause:

```
/usr/lib/llvm-18/include/c++/v1/cstring:63 -> string.h:61 -> SDK string.h:58
  _string.h:176:48: error: unknown type name 'rsize_t'
      errno_t memset_s(void *_LIBC_SIZE(__smax) __s, rsize_t __smax, ...)
```

LLVM's libc++ `__config` defines `__STDC_WANT_LIB_EXT1__ 1` (confirmed with
`-dM -E`); Apple's SDK `_string.h` gates `memset_s` on it and pulls
`sys/_types/_rsize_t.h`, which under a non-modules build takes a branch that
does not fire. Apple's *own* libc++ is configured not to trip this.

**Step 2 — one define fixes it.** `-D__STDC_WANT_LIB_EXT1__=0`: **28/28 compile,
0 errors.**

**Step 3 — but the link is not free, and that is worth knowing.** The resulting
`libobjc.A.dylib` carries one undefined symbol the Apple-libc++ build does not:

```
machorun: undefined symbol '__ZNSt3__122__libcpp_verbose_abortEPKcz'
  wanted by:  darwin/usr/lib/libobjc.A.dylib
```

`std::__1::__libcpp_verbose_abort` is LLVM 18's hardening handler. Apple's SDK
libc++ is built with a different hardening configuration and never emits it.
Adding `-D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_NONE` and
`-D'_LIBCPP_VERBOSE_ABORT(...)=__builtin_trap()'` removes it; the only remaining
delta against the Apple-libc++ build is that `_abort` is **no longer** imported.

**Step 4 — the behaviour is identical.** With those three defines:

```
== compiled 32 objects, 0 failures
09_objc under machorun            stdout IDENTICAL to the macOS baseline, exit 0
objc4 differential corpus under machorun: 41/44 PASS
  failing: 038-exceptions  042-dlopen  044-exception-through-uncached
```

The same 41, and the same 3 failures, with the same causes
(`unwind-compact` ×2, `dlopen-dlsym` ×1). **Apple's libc++ headers are not a
dependency.** The `libobjc.A.dylib` in `darwin/usr/lib/` was restored to the
Apple-SDK build afterwards (SHA-256 verified); nothing in the tree changed.

Flags to carry forward, exactly:

```
-nostdinc++ -isystem <llvm>/include/c++/v1
-D__STDC_WANT_LIB_EXT1__=0
-D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_NONE
-D'_LIBCPP_VERBOSE_ABORT(...)=__builtin_trap()'
```

Two ways to ship it, and the trade is real:

* **Depend on `libc++-18-dev`** (an apt package in the testbed). Zero bytes
  vendored; the SDK is not self-contained and the build now depends on the
  distro's libc++ revision.
* **Vendor LLVM's `libc++/include` into `usr/include/c++/v1`.** Apache-2.0 with
  LLVM exception, redistributable, and the SDK becomes genuinely
  self-describing. Costs ~5 MB in the repo.

Given *"I'd like to maintain less not more"*, start with the apt package and
pin the version in the Dockerfile. Vendor only if the SDK ever needs to work
outside our own container.

---

## 3. Which symbols the `.tbd` files must export

### 3.1 What we link against

Across all **69** committed Mach-O binaries (`tests/bin/*`, `tests/objc44/*`),
`otool -L` names exactly **three** system dylibs (counts are load-command
occurrences, so the fat fixture contributes twice):

| dylib | binaries that load it |
|---|---|
| `/usr/lib/libSystem.B.dylib` | 69 |
| `/usr/lib/libobjc.A.dylib` | 47 |
| `/usr/lib/libc++.1.dylib` | 1 (`05b_cxx_init`) |

plus four `@rpath` test dylibs that are part of the corpus, not the SDK
(`lib07greet.dylib`, `lib07greet_classic.dylib`, `lib041-multi-image.dylib`,
`lib042-dlopen-dlopen.dylib`).

**The `.tbd` surface is three files.** Apple's `MacOSX26.1.sdk/usr/lib` ships
331 of them; we need three, and `libSystem.tbd`/`libobjc.tbd` as symlinks.

Note also what is **not** consumed today: the Linux side links with
`-undefined dynamic_lookup` and no `-lSystem`, so `scripts/build_darwin.sh` and
`scripts/build_objc4.sh` currently read **zero** `.tbd` files. The `.tbd` half
of this SDK is not replacing something that exists — it is new capability, and
its purpose is to let guest programs be *built on Linux* at all (§4.3).

### 3.2 The numbers

| dylib | exports (`nm -gU`) | undefined (`nm -u`) |
|---|---|---|
| `libSystem.B.dylib` | **320** | 127 |
| `libobjc.A.dylib` | **420** | 139 |
| `libc++.1.dylib` | **14** | 6 |

**Our dylibs already satisfy the entire corpus.** The 69 binaries import 227
distinct symbols; resolved against our exports:

| from | imports | missing from our dylib |
|---|---|---|
| `libSystem` | 99 | **1** (`dyld_stub_binder`) |
| `libobjc` | 116 | **0** |
| `libc++` | 1 | **0** |

That is the whole reason this milestone is tractable: **we own the definition
side**, so the `.tbd` is a mechanical projection of something we already build,
not a transcription of Apple's.

The 127 undefined symbols in `libSystem.B.dylib` are glibc — `-undefined
dynamic_lookup` binds them flat, machorun resolves them through `dlsym`. They
are not a `.tbd` concern in either direction.

### 3.3 The 22 symbols a mechanical generator would miss

`libobjc.A.dylib` has 139 undefined symbols. 117 are exported by
`libSystem.B.dylib`. The other **22 are defined by the loader itself** — the
ELF PIE — not by any dylib:

```
src/objc_notify.c  (21)
  _dyld_lookup_section_info        _dyld_objc_register_callbacks
  _dyld_get_prog_image_header      _dyld_get_dlopen_image_header
  _dyld_get_image_uuid             _dyld_is_memory_immutable
  _dyld_image_header_containing_address   _dyld_image_path_containing_address
  _dyld_get_active_platform        _dyld_program_sdk_at_least
  _dyld_shared_cache_some_image_overridden
  _dyld_fall_2018_os_versions      _dyld_fall_2020_os_versions
  _dyld_platform_version_macOS_10_11   _dyld_platform_version_macOS_10_12
  _dyld_platform_version_macOS_10_13   _dyld_platform_version_iOS_10_0
  _dyld_platform_version_tvOS_10_0     _dyld_platform_version_watchOS_3_0
  _dyld_platform_version_bridgeOS_2_0
  getsegmentdata

src/resolve.c, src/fixups_{classic,chained}.c, darwin/src/libsystem.c
  dyld_stub_binder
```

On Darwin these live in `libdyld.dylib`, which `libSystem.B.tbd`
**re-exports** — Apple's file lists 39 re-exported `/usr/lib/system/*.dylib`.
Here there is no `libdyld.dylib`; the loader *is* dyld.

**Consequence for the generator:** `libSystem.tbd` cannot be produced purely by
`nm` over `libSystem.B.dylib`. It is

```
nm(libSystem.B.dylib)  ∪  a hand-maintained loader-exports list  =  320 + 22 = 342
```

and the loader-exports list wants a check that keeps it honest — see §6.4.

---

## 4. The `.tbd` format, measured against `ld64.lld-18`

### 4.1 What Apple ships

`MacOSX26.1.sdk/usr/lib/libSystem.B.tbd` — **tbd-version 4**, YAML, document
tag `--- !tapi-tbd`:

```yaml
--- !tapi-tbd
tbd-version:     4
targets:         [ x86_64-macos, x86_64-maccatalyst, arm64-macos,
                   arm64-maccatalyst, arm64e-macos, arm64e-maccatalyst ]
install-name:    '/usr/lib/libSystem.B.dylib'
current-version: 1356
reexported-libraries:
  - targets:   [ … ]
    libraries: [ '/usr/lib/system/libcache.dylib', … 39 of them … ]
exports:
  - targets:   [ … ]
    symbols:   [ … ]
...
```

337 KB for `libSystem.B.tbd`; 16 KB for `libobjc.A.tbd`. `libSystem.tbd` and
`libobjc.tbd` are symlinks to the `.B`/`.A` files.

### 4.2 Does `ld64.lld-18` accept a hand-written `.tbd`? Yes.

Ubuntu LLD 18.1.3, arm64 container. Each row is a link of the same object
against a `.tbd` varying one thing:

| # | variation | result |
|---|---|---|
| 1 | full tbd-v4, quoted scalars, `...` terminator, `-L<dir> -lfoo` | **OK** |
| 2 | **no `...` document terminator** | **FAIL** — `could not load TAPI file …: unsupported file type` |
| 3 | no `current-version` / `compatibility-version` | **OK** |
| 4 | unquoted scalars, compact spacing | **OK** |
| 5 | `objc-classes` + `objc-ivars` + `weak-symbols` + `thread-local-symbols` stanzas | **OK** |
| 6 | `--- !tapi-tbd-v3` with `archs:`/`platform:` | **OK** |
| 7 | multiple targets incl. `x86_64-macos` and `arm64e-macos` | **OK** |
| 8 | `reexported-libraries:` resolving through a second `.tbd` | **OK** (also OK with `-syslibroot`) |
| 9 | `.tbd` named by **direct path** on the command line | **OK** |
| 10 | `-syslibroot <sdk> -L/usr/lib -lfoo` | **OK** |
| 11 | a symbol the object needs that the `.tbd` does **not** export | **correctly refused** |

**There is exactly one hard requirement: the `...` YAML document-end marker.**
Omit it and LLVM's TextAPI reader rejects the file as "unsupported file type" —
a misleading message that costs an hour if you have not seen it. Everything else
is optional or flexible.

Row 11 matters as much as row 1: lld is *strict*, so a `.tbd` that under-declares
fails at link time rather than at run time. That is the property that makes a
generated `.tbd` safe.

The linked output is correct in shape: two-level namespace, `LC_LOAD_DYLIB` with
the `.tbd`'s `install-name`, and per-library binding —

```
(undefined) external _foo       (from libv1)
(undefined) external _foo_data  (from libv1)
(undefined) external dyld_stub_binder (from libSystem)
```

**No fallback to stub `.dylib`s is required.** That contingency in the task
brief can be closed.

### 4.3 End to end: a guest built entirely on Linux, run under machorun

The decisive test. `.tbd` files generated mechanically from **our** dylibs, a
guest with **no Apple headers at all**, linked by `ld64.lld-18`, run by
`build/machorun`:

```
== generating tbds from our own dylibs
   libSystem.tbd:  320 symbols,  5,576 bytes
   libobjc.tbd:    420 symbols, 11,076 bytes
   libc++.tbd:      14 symbols,    493 bytes

== compile + link on Linux, headers = none, libs = .tbd only
hello: Mach-O 64-bit arm64 executable, flags:<NOUNDEFS|DYLDLINK|TWOLEVEL|PIE>
       LC_LOAD_DYLIB  /usr/lib/libSystem.B.dylib
  (undefined) external _free _malloc _printf _strcmp dyld_stub_binder (from libSystem)

== run it under machorun
hello from a Linux-linked Mach-O: A argc=1 cmp=0
   exit=0
```

5,576 bytes against Apple's 337,439. The generator is nine lines of shell around
`llvm-nm-18 --defined-only --extern-only --format=just-symbols`.

### 4.4 One driver quirk, since it will otherwise waste a day

`clang -target arm64-apple-macos11 -isysroot <sdk> -fuse-ld=ld64.lld-18` **fails**:

```
ld64.lld-18: error: must specify -platform_version
ld64.lld-18: error: missing or unsupported -arch arm64
```

Clang's Darwin driver on a Linux host does not synthesise `-arch` or
`-platform_version` for `ld64.lld`. Two working forms, both measured:

```sh
# via the driver
clang -target arm64-apple-macos11 -isysroot $SDK -fuse-ld=/usr/bin/ld64.lld-18 \
      -Wl,-arch,arm64 -Wl,-platform_version,macos,11.0,11.0 -o prog prog.c -lSystem

# or compile and link separately, which is what our scripts already do
clang -target arm64-apple-macos11 -isysroot $SDK -c prog.c -o prog.o
ld64.lld-18 -arch arm64 -platform_version macos 11.0 11.0 \
            -syslibroot $SDK -L/usr/lib -lSystem -o prog prog.o
```

Header lookup through `-isysroot` alone works for compilation (`-fsyntax-only`
finds `$SDK/usr/include/stdio.h`). And the sysroot needs **no** `SDKSettings.json`
and no `SDKSettings.plist`: `build/sdk/MacOSX.sdk` contains only `usr/include`
and builds objc4 today.

---

## 5. Recommended layout and generation pipeline

### 5.1 Layout

```
vendor/darwin-headers/          upstream, vendored, pinned by tag  [redistributable]
  xnu/  Libc/  libpthread/  libplatform/  libdispatch/  libmalloc/
  libclosure/  dyld/  cctools/  libunwind/  Libm/
  PROVENANCE                    repo -> tag -> commit sha, one line each

vendor/darwin-headers-local/    what upstream does not publish  [ours, hand-written]
  TargetConditionals.h          71 macros total across these 7
  Availability.h  AvailabilityInternal.h  AvailabilityInternalLegacy.h
  AvailabilityMacros.h  AvailabilityVersions.h  os/availability.h
  mach/{task,thread_act,vm_map,mach_port,mach_host,host_priv,host_security,
        processor,processor_set,clock_priv}.h        the 10 MIG stand-ins

vendor/objc4-priv/              unchanged, already in tree      [ours, 900 lines]

sdk/MachorunOS.sdk/             generated -- gitignored, built by a script
  usr/include/                  staged from the three trees above + objc4's objc/*
  usr/lib/
    libSystem.B.tbd   libSystem.tbd -> libSystem.B.tbd
    libobjc.A.tbd     libobjc.tbd   -> libobjc.A.tbd
    libc++.1.tbd      libc++.tbd    -> libc++.1.tbd
```

`usr/include/c++/v1` is **absent by design** — the build uses
`-nostdinc++ -isystem $(llvm-config-18 --includedir)/c++/v1` per §2.5. Add the
directory only if the SDK must work outside our container.

### 5.2 Pipeline

```
scripts/sdk_fetch.sh     # git clone --depth 1 --branch <pinned tag> the 11 repos
                         # into vendor/darwin-headers/, write PROVENANCE
scripts/sdk_stage.sh     # copy the 355 measured paths into sdk/.../usr/include,
                         # run xnu's make_posix_availability.sh and
                         # make_symbol_aliasing.sh, overlay
                         # vendor/darwin-headers-local/ last so it wins
scripts/gen_tbd.sh       # llvm-nm-18 --defined-only --extern-only over
                         # darwin/usr/lib/*.dylib, plus darwin/loader-exports.txt
                         # (the 22 from 3.3), emit tbd-v4 -- REMEMBER THE `...`
```

Three properties this pipeline should have, all cheap:

* **Stage by explicit manifest, not by `cp -R`.** The 355 paths are known; copying
  whole trees drags in kernel-only headers that will compile and then mean the
  wrong thing.
* **`sdk_stage.sh` fails loudly on a missing path**, in the house style. A header
  that silently does not get staged becomes a confusing compile error 400 files
  later.
* **`gen_tbd.sh` runs after `build_darwin.sh` / `build_objc4.sh`, never before.**
  The dylibs are the source of truth; a stale `.tbd` is a lie the linker will
  believe.

### 5.3 Order of work

1. `gen_tbd.sh` + the 22-symbol loader list. Self-contained, already proven end
   to end (§4.3), and immediately useful — it is what lets anything be built on
   Linux.
2. The libc++ flags (§2.5). Three defines, deletes 67% of the surface, already
   proven at 41/44.
3. `sdk_fetch.sh` / `sdk_stage.sh` for the 335 upstream headers.
4. The 7 clean-room availability/target headers (71 macros).
5. The 10 MIG stand-ins.
6. Delete `OBJC4_SDK` from `scripts/build_objc4.sh` and close
   `docs/UNIMPLEMENTED.md#objc-sdk-dependency`.

Steps 1 and 2 are independently valuable and land without touching a header.

---

## 6. What would block a fully self-hosted build

### 6.1 The headers are ABI, not just declarations — this is the real risk

`docs/ABI.md` is the reason to be careful. Darwin and Linux disagree on
`struct stat` (144 bytes vs 128, almost every field moved), on 54 of 87 shared
`errno` values, on 10 of 13 `O_*` flags, and Darwin's `<ctype.h>` *inlines* a
lookup into a 3,208-byte `_DefaultRuneLocale` that is therefore part of the ABI.
Those facts live **in the headers**. A vendored header from a different xnu
revision than the SDK that built our fixtures could move a field and nothing
would fail loudly.

Today the exposure is bounded, because the corpus is compiled on macOS against
Apple's SDK and only `libobjc.A.dylib` is compiled against ours. The moment
anything else is built on Linux, the exposure is total.

**Recommendation — and this is the one new test this milestone should buy:** a
fixture that prints the ABI, not behaviour. `sizeof(struct stat)` and
`offsetof` for every field; every `E*` value; every `O_*` value; `sizeof(va_list)`;
the first 64 bytes of `_DefaultRuneLocale`. Build it twice — on macOS against
Apple's SDK, on Linux against ours — and require byte-identical output. It is
one source file, it turns "the headers probably agree" into a diff, and it is
exactly the method this project already uses everywhere else.

### 6.2 Revision skew, and pinning

The drift sample (§2.1) found the open-source trees are *newer* than the SDK in
places (`mach/message.h` 1,659 lines vs 952 — a superset, fine) and *older* in
others (`Availability.h` 420 vs 625 — stale, which is why §2.4 clean-rooms it).
`apple-oss-distributions` repositories track tags like `xnu-11215.x.x`.
**Pin tags, record them in `PROVENANCE`, and never track `main`.** A silent
upstream bump is the failure mode most likely to produce a mystery in six
months.

### 6.3 The fixtures stay Apple-built, and should

`tests/build_fixtures.sh` refuses to run off Darwin, on purpose: the fixtures are
the reference bytes and must come from the real Xcode linker. **This SDK does not
change that and must not be used to change it.** Rebuilding the corpus with
`ld64.lld` would delete the property that makes the whole scoreboard mean
anything. The SDK's job is new guest programs, not the oracle.

### 6.4 The loader-exports list has no test behind it

The 22 symbols in §3.3 are discovered today by `nm -u libobjc.A.dylib` minus our
libSystem's exports. Written into a static file, that list can rot: a loader
change that renames or drops one would produce a `.tbd` that promises a symbol
nothing defines, and the failure would surface at *run* time, in a guest, as an
undefined-symbol abort. Cheap guard: have `gen_tbd.sh` recompute the set and
diff it against the committed list, failing loudly on a difference. Same shape
as `scripts/gen_errno_table.sh`.

### 6.5 Smaller, named

* **`ptrauth.h` is a clang resource header, not an SDK header**, and Ubuntu's
  `clang-18` does not ship it. Already vendored in `vendor/objc4-priv/`. If the
  container ever moves to a newer clang, re-check whether it can be dropped.
* **`libunwind.h` drifts 66%** between Apple's SDK and
  `apple-oss-distributions/libunwind`. objc4 uses very little of it; verify by
  compiling rather than by reading.
* **`malloc/_malloc_type.h` drifts 77%** — libmalloc's published revision is
  ahead of the 15.4 SDK. Same remedy.
* **The clang driver will not link on Linux without `-Wl,-arch` and
  `-Wl,-platform_version`** (§4.4). Bake it into whatever wrapper guests use, so
  nobody rediscovers it.
* **The `...` terminator** (§4.2). Say it in a comment in `gen_tbd.sh`, because
  the error message does not.
* **`10_fat` needs `lipo`.** `llvm-lipo-18` is in the container; not a header or
  a `.tbd` issue, but it is on the path to building anything fat on Linux.

---

## 7. Reproducing every number here

```sh
# --- header sets --------------------------------------------------------
# objc4: a clang wrapper that appends -MD, then union the .d files
printf '#!/bin/sh\nexec clang "$@" -MD\n' > build/survey/clangmd.sh
chmod +x build/survey/clangmd.sh
docker run --rm --platform linux/arm64 -v "$PWD:/work" -w /work \
   -e OBJC4_SDK=/work/build/sdk/MacOSX.sdk \
   -e DARWIN_CLANG=/work/build/survey/clangmd.sh \
   machorun-testbed:24.04 bash scripts/build_objc4.sh
cat build/objc4-macho-obj/*.d | tr ' ' '\n' | sed 's/\\$//' \
   | grep -v '^$\|:$\|\.o$\|\.mm$\|\.m$\|\.c$\|\.s$' | sort -u     # 1,157

# libSystem: -nostdinc, so the answer is three files
docker run --rm --platform linux/arm64 -v "$PWD:/work" -w /work machorun-testbed:24.04 \
  bash -c 'for f in libsystem posix mach ctype objcsupport libcxx; do
      clang -target arm64-apple-macos11 -nostdinc -std=gnu11 -w -MD -MF /tmp/$f.d \
            -c darwin/src/$f.c -o /tmp/$f.o; done; cat /tmp/*.d'

# fixtures + objc44, on the macOS oracle
SDK=$(xcrun --sdk macosx --show-sdk-path)
for f in tests/src/*.c; do $(xcrun -f clang) -target arm64-apple-macos12 -isysroot $SDK -M $f; done
for f in ~/objc4-linux/tests/*.m; do $(xcrun -f clang) -target arm64-apple-macos13 \
        -isysroot $SDK -I ~/objc4-linux/tests -M $f; done

# --- classification -----------------------------------------------------
for r in xnu Libc libpthread libplatform libdispatch libmalloc libclosure \
         dyld cctools libunwind Libm; do
  curl -sS "https://api.github.com/repos/apple-oss-distributions/$r/git/trees/main?recursive=1"
done                        # then suffix-match each relative path

# --- libc++ substitution ------------------------------------------------
# 28/28 compile, 41/44 corpus, 09_objc byte-identical
apt-get install -y libc++-18-dev libc++abi-18-dev
DARWIN_CLANG=<wrapper adding -nostdinc++ -isystem /usr/lib/llvm-18/include/c++/v1
             -D__STDC_WANT_LIB_EXT1__=0
             -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_NONE
             -D'_LIBCPP_VERBOSE_ABORT(...)=__builtin_trap()'>
bash scripts/build_objc4.sh && bash scripts/objc44.sh

# --- symbols ------------------------------------------------------------
nm -gU darwin/usr/lib/libSystem.B.dylib | awk '{print $NF}' | sort -u   # 320
nm -u  darwin/usr/lib/libobjc.A.dylib   | awk '{print $NF}' | sort -u   # 139
for f in tests/bin/* tests/objc44/*; do nm -m "$f" 2>/dev/null; done \
  | awk '/undefined/{...}'                                             # 227 imports

# --- .tbd ---------------------------------------------------------------
build/survey/tbd/probe_tbd.sh     build/survey/tbd/probe_tbd2.sh   # the matrix
build/survey/tbd/e2e.sh                                            # generate+link+run
build/survey/tbd/driver.sh                                         # the -Wl, quirk
```

Working files from this survey are under `build/survey/` (gitignored): the raw
dependency unions, the licence scan, the open-source path match, and the four
`.tbd` probe scripts.
