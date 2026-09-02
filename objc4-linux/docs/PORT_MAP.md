# Port map: `vendor/objc4/runtime` → Linux/ELF

Every file under `vendor/objc4/runtime`, classified by what stands between it
and a Linux build. Nothing here is asserted from reading Apple's source alone —
the Darwin/ELF claims in §3 and §5 were produced by compiling and running
programs on both sides and diffing the output. Commands are given so they can
be re-run.

**Which objc4 is this.** The vendored tree carries no version string. It is
identified by feature markers: a `runtime/Threading/` package with
`OBJC_THREADING_{NONE,DARWIN,PTHREADS,C11THREADS}` back-ends (2022 copyright),
`objc-malloc-instance.h` and `InitWrappers.h` (2023), `_dyld_objc_callbacks_v4`
with `_objc_patch_root_of_class`, `_dyld_lookup_section_info`, `class_rx_t`
pointer signing, and TPRO. That places it at roughly objc4-9xx, macOS 14/15
vintage — several years newer than the objc4-818.2 that every public "buildable
objc4" fork is based on. **This matters: the newest tree is the easiest one to
port**, for reasons in §4.

Totals: **107 files, 48,327 lines** in `runtime/`. By class:

| class | files | lines | share |
|---|---:|---:|---:|
| CLEAN — compiles as-is | 34 | 8,204 | 17% |
| SHIM — small compatibility header | 30 | 25,565 | 53% |
| REWRITE — Mach-O/dyld logic needing an ELF equivalent | 9 | 4,131 | 9% |
| DEFER — stub initially | 34 | 10,427 | 21% |

The 53% SHIM share is dominated by four enormous files (`objc-runtime-new.mm`,
`objc-runtime-new.h`, `NSObject.mm`, `objc-object.h` = 17,679 lines) that are
*mostly* portable C++ with a handful of Darwin call sites each. Line count is a
bad proxy for work here; §2's API census is the honest measure.

---

## 1. The table

`?` in the "Darwin surface" column means none found.

### 1.1 Core runtime (`.mm`)

| file | lines | Darwin surface | class |
|---|---:|---|---|
| `objc-runtime-new.mm` | 9889 | `_dyld_objc_notify_mapped_info`, `_dyld_objc_mark_image_mutable`, `_dyld_get_prog_image_header`, `dyld_image_header_containing_address`, `dyld_image_path_containing_address`, `_dyld_get_image_uuid`, `_dyld_get_dlopen_image_header`, `dyld_shared_cache_some_image_overridden`, `dyld_program_sdk_at_least`, `dyld_get_active_platform`, `malloc_zone_malloc_with_options`, `getSectionData` | SHIM |
| `NSObject.mm` | 2807 | `_Block_copy`, `malloc_size`, `os_lock_handoff_s` (comment only), `objc_thread_self` | SHIM |
| `objc-cache.mm` | 1658 | `task_restartable_ranges_register/synchronize`, `mach_task_self`, `task_threads`, `thread_get_state`, `mach_port_deallocate`, `vm_deallocate`, hand-rolled MIG stub, `pthread_mach_thread_np`, `sys_icache_invalidate` | REWRITE |
| `objc-exception.mm` | 1236 | `__cxa_*`, `_Unwind_*`, `__gxx_personality_v0`, `execinfo.h`, alt-handlers | SHIM |
| `objc-class.mm` | 1179 | `dyld_image_path_containing_address` (2) | SHIM |
| `objc-runtime.mm` | 1139 | `dladdr`, plus `sliceRequiresGC()` — an on-disk Mach-O/fat parser (lines 830–1080) | DEFER (GC block) + SHIM (rest) |
| `objc-os.mm` | 1124 | `_dyld_objc_register_callbacks`, `_objc_init`, `map_images`/`load_images`/`unmap_image`, `getsegmentdata`, `section$start$__TEXT$__init_offsets`, `_dyld_is_memory_immutable`, `environ`/`_NSGetEnviron` | **REWRITE** |
| `objc-initialize.mm` | 850 | ? | CLEAN |
| `objc-block-trampolines.mm` | 613 | `vm_allocate`, `vm_remap`, `mach_task_self`, `getsectiondata` on `__TEXT,__objc_trampolines` | **REWRITE** (or DEFER) |
| `maptable.mm` | 532 | ? | CLEAN |
| `hashtable2.mm` | 530 | ? | CLEAN |
| `objc-weak.mm` | 509 | ? | CLEAN |
| `objc-layout.mm` | 503 | ? | CLEAN |
| `objc-sync.mm` | 493 | ? (uses `_objc_fetch_pthread_data`, already abstracted) | CLEAN |
| `objc-opt.mm` | 492 | 17× `getSectionData(...)` + shared-cache `objc_opt_t` reader | **REWRITE** |
| `objc-typeencoding.mm` | 367 | ? | CLEAN |
| `objc-loadmethod.mm` | 367 | ? | CLEAN |
| `objc-errors.mm` | 358 | `os/reason_private.h`, `os/variant_private.h`, `sandbox/private.h`, `_simple.h`, `CRSetCrashLogMessage`, `abort_with_reason`, `os_fault_with_payload`, `_simple_asl_log` | SHIM |
| `objc-lockdebug.mm` | 329 | ? | CLEAN |
| `objc-references.mm` | 272 | ? | CLEAN |
| `objc-accessors.mm` | 165 | ? | CLEAN |
| `objc-sel.mm` | 157 | `_dyld_get_objc_selector` (preopt selector table) | SHIM |
| `objc-zalloc.mm` | 129 | ? | CLEAN |
| `objc-auto.mm` | 114 | GC-compat export stubs only | DEFER |
| `Protocol.mm` | 98 | ? | CLEAN |
| `Object.mm` | 77 | ? | CLEAN |
| `objc-load.mm` | 33 | ? (empty shell) | CLEAN |
| `objc-file.mm` | 25 | ? (two `#include`s) | CLEAN |
| `objc-magicsel.m` | 35 | ? | CLEAN |
| `objc-test-env.c` | 32 | ? | CLEAN |
| `dummy-library-mac-i386.c` | 356 | i386 dylib stub for 10.x compat | DEFER (delete) |

### 1.2 Internal headers

| file | lines | Darwin surface | class |
|---|---:|---|---|
| `objc-runtime-new.h` | 3232 | `__arm64__` (3), ptrauth wrappers, `malloc_size` | SHIM |
| `objc-object.h` | 1751 | `dyld_image_header_containing_address` (2, in the "is this IMP ours" fast path), `TARGET_OS_SIMULATOR` isa layout | SHIM |
| `objc-internal.h` | 1520 | `<mach-o/loader.h>`, `struct mach_header` in ~8 public SPI signatures, `TARGET_OS_*` | SHIM |
| `objc-private.h` | 1331 | `header_info` built on `headerType`/`_dyld_section_location_info_t`, `dyld_image_path_containing_address` | **REWRITE** (struct `header_info` only) |
| `objc-os.h` | 532 | **`#error unknown OS` for `!TARGET_OS_MAC`** — the single hard gate; 25 Darwin `#include`s; `getSectionData`; `headerType`/`segmentType` typedefs; `sdkIsAtLeast`; `_dyld_is_memory_immutable` | **REWRITE** |
| `objc-abi.h` | 532 | `TARGET_OS_OSX && __i386__` legacy symbols, fixup-dispatch decls | SHIM |
| `objc-config.h` | 377 | 18 `TARGET_OS_*` sites, `<TargetConditionals.h>`, `HAVE_ASPRINTF`, `HAVE_CLOCK_GETTIME_NSEC_NP`, `OBJC_THREADING_PACKAGE` | **REWRITE** (in the sense of "needs a real Linux branch", not new logic) |
| `objc-ptrauth.h` | 362 | 91 `ptrauth_*` uses — **all inside `__has_feature(ptrauth_calls)` guards**; measured `__has_feature(ptrauth_calls)==0` on Linux aarch64 clang 17, and `<ptrauth.h>` exists there | CLEAN |
| `objc-gdb.h` | 290 | debugger-facing symbol declarations | CLEAN |
| `arm64-asm.h` | 247 | `$0` macro args (Darwin `as` dialect), `.quad`/`.long`, ptrauth macros | SHIM |
| `NSObject-internal.h` | 177 | ? | CLEAN |
| `isa.h` | 175 | **`#error unknown architecture for packed isa`** on Linux (see §5.1); `TARGET_OS_SIMULATOR`/`TARGET_OS_OSX` isa-mask selection | SHIM |
| `objc-weak.h` | 153 | ? | CLEAN |
| `objc-zalloc.h` | 130 | ? | CLEAN |
| `objc-locks.h` | 91 | ? | CLEAN |
| `InitWrappers.h` | 84 | ? | CLEAN |
| `NSObject-private.h` | 74 | ? | CLEAN |
| `objc-block-trampolines.h` | 75 | `TargetConditionals` | SHIM |
| `objc-opt.h` | 70 | shared-cache `objc_opt_t` | DEFER |
| `objc-file.h` | 65 | `foreach_data_segment()` — walks Mach-O load commands | **REWRITE** (or delete; see §3) |
| `objc-env.h` | 58 | X-macro list of `OBJC_*` env vars | CLEAN |
| `objc-vm.h` | 57 | `<mach/vm_param.h>`, `MACH_VM_MAX_ADDRESS`; **already has an `#elif __arm64__` fallback** defining `PAGE_SIZE`/`OBJC_VM_MAX_ADDRESS` by hand | SHIM |
| `objc-malloc-instance.h` | 48 | `malloc_type_private.h` behind `_MALLOC_TYPE_ENABLED`; falls back to `calloc` | CLEAN |
| `DenseMapExtras.h` | 48 | ? | CLEAN |
| `objc-references.h` | 42 | ? | CLEAN |
| `objc-test-env.h` | 38 | ? | CLEAN |
| `objc-load.h` | 37 | `struct mach_header *` in one signature | SHIM |
| `objc-initialize.h` | 45 | ? | CLEAN |
| `objc-loadmethod.h` | 45 | ? | CLEAN |
| `objc-sync.h` | 59 | ? | CLEAN |
| `objcrt.h` | 25 | Windows `HMODULE`, `objc_sections` struct — **dead code, and the single most useful thing in the tree** (see §4.1) | DEFER (keep as design template) |
| `objc-class.h`, `objc-runtime.h`, `hashtable.h` | 2 each | one-line forwarders | CLEAN |

### 1.3 Public headers (shipped to clients)

| file | lines | Darwin surface | class |
|---|---:|---|---|
| `runtime.h` | 1910 | `<TargetConditionals.h>`, `<Availability.h>`, `OBJC_AVAILABLE` | SHIM |
| `message.h` | 315 | `OBJC_AVAILABLE` | SHIM |
| `objc-api.h` | 324 | `TARGET_OS_*` in availability macros | SHIM |
| `objc.h` | 243 | `<Availability.h>`, `<malloc/malloc.h>` (guarded) | SHIM |
| `objc-auto.h` | 259 | GC API | DEFER |
| `NSObject.h` | 115 | ? | CLEAN |
| `objc-exception.h` | 86 | ? | CLEAN |
| `Protocol.h` | 50 | ? | CLEAN |
| `Object.h` | 38 | ? | CLEAN |
| `NSObjCRuntime.h` | 34 | `<TargetConditionals.h>` | SHIM |
| `maptable.h` | 206 | `__ptrauth` on callback fn-ptr fields (guarded) | CLEAN |
| `hashtable2.h` | 274 | `__ptrauth` on callback fn-ptr fields (guarded) | CLEAN |
| `OldClasses.subproj/List.h` | 37 | ? | CLEAN |

### 1.4 LLVM-vendored containers — all CLEAN

`llvm-DenseMap.h` (1313), `llvm-MathExtras.h` (486), `llvm-DenseSet.h` (293),
`llvm-DenseMapInfo.h` (216), `llvm-type_traits.h` (204), `llvm-AlignOf.h` (171),
`PointerUnion.h` (237). 2,920 lines, plain C++, zero Darwin surface.

### 1.5 Threading package — Apple already did this work

| file | lines | class | note |
|---|---:|---|---|
| `Threading/threading.h` | 65 | CLEAN | dispatches on `OBJC_THREADING_PACKAGE` |
| `Threading/pthreads.h` | 245 | **CLEAN** | 37 `pthread_*` calls; `#if !_OBJC_PTHREAD_IS_DARWIN` branches already present |
| `Threading/c11threads.h` | 235 | CLEAN | `<threads.h>` |
| `Threading/mixins.h` | 259 | CLEAN | |
| `Threading/tls.h` | 105 | CLEAN | |
| `Threading/lockdebug.h` | 146 | CLEAN | |
| `Threading/nothreads.h` | 144 | CLEAN | |
| `Threading/darwin.h` | 264 | DEFER | `os_unfair_lock`, direct TSD — not used on Linux |

`objc-config.h` already selects `OBJC_THREADING_C11THREADS` when `<threads.h>`
exists and `OBJC_THREADING_PTHREADS` when `<pthread.h>` does. On Linux both
exist; pick pthreads explicitly. **The entire locking layer is already ported.**

### 1.6 Assembly

| file | lines | class | note |
|---|---:|---|---|
| `Messengers.subproj/objc-msg-arm64.s` | 868 | **REWRITE** | see §3.4 — the only messenger we need |
| `retain-release-helpers-arm64.s` | 498 | REWRITE | same asm-dialect issues |
| `objc-blocktramps-arm64.s` | 144 | DEFER | needs `imp_implementationWithBlock` |
| `objc-sel-table.s` | 51 | DEFER | shared-cache placeholder; replace with an empty stub |
| `Messengers.subproj/objc-msg-x86_64.s` | 1382 | DEFER | phase 2 (x86-64) |
| `objc-blocktramps-x86_64.s` | 1173 | DEFER | |
| `Messengers.subproj/objc-msg-arm.s` | 907 | DEFER (delete) | armv7 |
| `Messengers.subproj/objc-msg-i386.s` | 1087 | DEFER (delete) | |
| `Messengers.subproj/objc-msg-simulator-i386.s` | 993 | DEFER (delete) | |
| `Messengers.subproj/objc-msg-simulator-x86_64.s` | 1270 | DEFER (delete) | |
| `objc-blocktramps-arm.s` | 282 | DEFER (delete) | |
| `objc-blocktramps-i386.s` | 1102 | DEFER (delete) | |
| `Messengers.subproj/objc-msg-win32.m` | 525 | DEFER (evidence only) | see §4.1 |

### 1.7 Build/tooling artefacts — DEFER, not code

`objc-probes.d` (59, dtrace), `Module/ObjectiveC.modulemap` (41),
`Module/ObjectiveC.apinotes` (437), `ModulePrivate/*` (41).
`objc-probes.d` generates `objc-probes.h`, which `objc-os.h` includes
unconditionally — on Linux, replace with a header of empty
`OBJC_RUNTIME_*_ENABLED()`/probe macros. (SystemTap SDT could provide real
probes later; not worth it now.)

---

## 2. Darwin API census, with named replacements

Counts are identifier occurrences across all of `runtime/`, from
`grep -rhoE` over the tree.

### 2.1 Mach

| symbol | n | used by | Linux replacement |
|---|---:|---|---|
| `mach_header` / `mach_header_64` | 37 | `objc-os.h` typedefs, `objc-internal.h` SPI, `objc-runtime-new.mm` | `struct objc_image_t*` of our own — an opaque per-image cookie. Keep the *name* `headerType` so call sites don't change; typedef it to our ELF image record. |
| `mach_task_self` | 10 | `objc-cache.mm`, `objc-block-trampolines.mm` | n/a — the calls that need it go away with their features |
| `task_restartable_ranges_register` / `_synchronize` | 10 | `objc-cache.mm` cache GC | `rseq(2)` is the semantic analogue but not drop-in (aborts on preemption, needs a compiler-emitted critical section). **Phase 1: don't free cache garbage.** Phase 3: `tgkill(SIGRTMIN)` + read `ucontext_t->uc_mcontext.pc` in the handler — that is the direct equivalent of `thread_get_state`, and it is what replaces the fallback path too. |
| `task_threads` + hand-rolled MIG (`mach_msg*`, ~15 syms) | 25 | `objc-cache.mm` `_collecting_in_critical()` | iterate `/proc/self/task/*` for the tid list; PC via the `tgkill`+`ucontext` scheme above. `/proc/<pid>/stat` field 30 (`kstkeip`) is **not** usable — it reads 0 without `CAP_SYS_ADMIN`. |
| `thread_get_state(ARM_THREAD_STATE64)` | 1 | `objc-cache.mm` `_get_pc_for_thread` | as above |
| `vm_allocate` / `vm_remap` / `vm_deallocate` | 5 | `objc-block-trampolines.mm` (aliasing one RX text page at many RW data pages) | `memfd_create(2)` + `ftruncate` + two `mmap`s of the same fd (one `PROT_READ|PROT_EXEC`, one `PROT_READ|PROT_WRITE`). This is the standard W^X dual-mapping trick and is an exact functional match for `vm_remap`. |
| `mach_error_string` | 3 | error paths in the above | `strerror(errno)` |
| `mach/vm_param.h` `MACH_VM_MAX_ADDRESS` | 1 | `objc-vm.h` | the file **already** has an `#elif __arm64__` fallback (`PAGE_SIZE 16384`, `OBJC_VM_MAX_ADDRESS 0x00007ffffffffff8`). On Linux aarch64 the page size is 4K or 16K and `TASK_SIZE` is typically `0x0000_1000_0000_0000` (48-bit VA). Get it at runtime from `sysconf(_SC_PAGESIZE)`; set `OBJC_VM_MAX_ADDRESS` to `0x0000ffffffffffffULL` (52-bit VA safe). **This feeds the packed-isa `shiftcls` width — getting it wrong corrupts every isa.** |
| `sys_icache_invalidate` (`libkern/OSCacheControl.h`) | 1 | `objc-cache.mm` | `__builtin___clear_cache(begin, end)` |

### 2.2 dyld

| symbol | n | used by | Linux replacement |
|---|---:|---|---|
| `_dyld_objc_register_callbacks` (v4: `map_images`, `load_images`, `unmap_image`, `_objc_patch_root_of_class`) | 1 | `objc-os.mm:927` | **Our own loader shim.** No Linux equivalent exists; §3.5. |
| `_dyld_objc_notify_mapped_info` | 11 | `map_images` signature | our `struct objc_mapped_image { const objc_image_t *mh; const char *path; objc_section_info_t sectionLocationMetadata; ... }` — same shape, so signatures don't change |
| `_dyld_lookup_section_info` / `_dyld_section_location_info_t` / `_dyld_section_location_kind` (18 kind constants) | ~45 | `objc-os.h:getSectionData`, `objc-opt.mm` (17 call sites) | **The single tightest seam in the whole port.** Reimplement `getSectionData<T>()` against a per-image table of (start,end) built once at registration. §3.3. |
| `_dyld_get_prog_image_header` | 2 | `map_images_nolock` sizing heuristic | `dl_iterate_phdr` first callback, or `getauxval(AT_PHDR)` |
| `dyld_image_header_containing_address` | 5 | `_headerForAddress`, `objc-object.h` "is this IMP libobjc's?" | `dladdr(3)` → `dli_fbase` |
| `dyld_image_path_containing_address` | 6 | `class_getImageName`, `header_info::fname()` | `dladdr(3)` → `dli_fname` |
| `_dyld_get_dlopen_image_header` | 1 | `objc_getClass` hooks | `dlinfo(handle, RTLD_DI_LINKMAP, ..)` → `l_addr` |
| `_dyld_get_image_uuid` | 2 | duplicate-class diagnostics | ELF build-id: `PT_NOTE` → `NT_GNU_BUILD_ID`, reachable via `dl_iterate_phdr` |
| `_dyld_is_memory_immutable` | 2 | `strdupIfMutable`/`freeIfMutable` in `objc-os.h` | conservative stub returning `false` (always copy) for phase 1; later, an address-range check against `PT_LOAD` segments lacking `PF_W`, cached at registration |
| `dyld_program_sdk_at_least` + `dyld_platform_version_*` | 15 | `sdkIsAtLeast()` bug-compat gates | `#define sdkIsAtLeast(...) 1` — there is no legacy Linux ABI to be bug-compatible with. Take the modern branch everywhere. |
| `dyld_get_active_platform` | 1 | one 10.11 workaround | as above |
| `dyld_shared_cache_some_image_overridden`, `_dyld_for_each_objc_class`, `_dyld_for_each_objc_protocol`, `_dyld_for_objc_header_opt_ro/rw`, `_dyld_get_shared_cache_range`, `_dyld_objc_class_count`, `_dyld_get_objc_selector` | ~15 | shared-cache preoptimization | `SUPPORT_PREOPT 0`. There is no shared cache. `objc-opt.mm` already carries a complete `#if !SUPPORT_PREOPT` fallback body. |
| `_dyld_objc_mark_image_mutable` | 13 | TPRO / `__DATA_CONST` write-enable | `mprotect(2)` on the containing page range, or a no-op if we link the objc sections writable (we do — measured, §3.2: `objc_classlist` lands in the RW `PT_LOAD`) |
| `gdb_objc_realized_classes`, `gdb_objc_class_changed` | 16 | debugger hooks | keep as-is; they are plain global symbols |
| `section$start$__TEXT$__init_offsets` | 1 | `objc-os.mm:static_init()` | Not needed. `static_init()` exists because libc calls `_objc_init` *before* dyld runs libobjc's C++ initializers. On Linux we control initialization order via `__attribute__((constructor(101)))`; delete the whole function and let normal `.init_array` run. |

### 2.3 malloc

| symbol | n | Linux replacement |
|---|---:|---|
| `malloc_size` | 9 | `malloc_usable_size(3)` (glibc, `<malloc.h>`). **Not identical** — it may return more than requested. `NSObject.mm` uses it only for `class_getInstanceSize`-adjacent diagnostics and `objc_isUniquelyReferenced` sizing; verify each site. |
| `malloc_zone_t`, `malloc_default_zone`, `malloc_zone_batch_malloc`, `malloc_zone_malloc_with_options` | 6 | `SUPPORT_ZONES 0` is already the config for non-OSX. `objc-runtime-new.mm:9761` (`malloc_zone_malloc_with_options(NULL, ..., MALLOC_ZONE_MALLOC_OPTION_CLEAR)`) → `calloc(1, n)`. |
| `malloc_type_calloc` / `malloc_type_private.h` | 3 | already behind `#if _MALLOC_TYPE_ENABLED`; falls through to `calloc(1, size)`. **CLEAN.** |
| `posix_memalign`, `calloc`, `realloc`, `free` | 227 | already POSIX |

### 2.4 `os_*` / libSystem private

| symbol | n | Linux replacement |
|---|---:|---|
| `os_unfair_lock*` (incl. `os_unfair_recursive_lock`) | 12 | confined to `Threading/darwin.h`; `Threading/pthreads.h` already provides the pthread implementations |
| `os_feature_enabled_simple` | 5 | read the `objc4.plist` defaults as compile-time constants; or getenv |
| `os_variant_allows_internal_security_policies`, `os_variant_has_internal_diagnostics` | 4 | `return false` |
| `os_fault_with_payload`, `abort_with_reason`, `os/reason_private.h` | 4 | `abort(3)` after writing the message to `stderr` |
| `_simple_asl_log`, `<_simple.h>` | 2 | `write(2)` to `STDERR_FILENO`. Must stay malloc-free and objc-free — `_objc_inform` runs in contexts where `objc_msgSend` must not recurse; that is exactly why `objc-os.h` marks `syslog`/`vsyslog` `UNAVAILABLE_ATTRIBUTE`. Do **not** substitute `syslog`. |
| `CRSetCrashLogMessage` / `CrashReporterClient.h` | 2 | a plain global `const char *__objc_crash_message` in a section named `objc_crashinfo` (`gdb`/`lldb` can read it; `abrt`/`systemd-coredump` cannot — accepted loss) |
| `os_add_overflow` / `os_mul_overflow` / `os/overflow.h` | 4 | `__builtin_add_overflow` / `__builtin_mul_overflow` |
| `os_fastpath` | 1 | `__builtin_expect` (`objc-os.h` already defines `fastpath`/`slowpath`) |
| `sandbox/private.h` | 1 | delete |
| `Rosetta/Rosetta.h`, `Rosetta/Traps.h` | 2 | `OBJC_USE_ROSETTA 0` |
| `os/thread_self_restrict.h` (TPRO) | 1 | delete; no equivalent |
| `dispatch/dispatch.h` | 1 | one `dispatch_once` in `objc-exception.mm`; `pthread_once` or a `std::atomic` flag |

### 2.5 pthread

Already handled by `Threading/pthreads.h` (37 `pthread_*` calls). The only
Darwin-specific pthread use outside it is `pthread_mach_thread_np` in
`objc-cache.mm` (goes away with cache GC) and
`<System/pthread_machdep.h>` in `objc-os.h` (direct TSD slots; the pthreads
back-end uses `pthread_getspecific` instead).

### 2.6 `TargetConditionals`

21 `#include <TargetConditionals.h>` and ~80 `TARGET_OS_*` sites. Provide our own
`compat/TargetConditionals.h` defining every `TARGET_OS_*` to 0 except a new
`TARGET_OS_LINUX 1`. **Do not define `TARGET_OS_MAC 1` to "get through"** —
`objc-os.h`'s `#if TARGET_OS_MAC` block pulls 25 Darwin headers.

### 2.7 The one that will bite silently

`__arm64__` — **43 occurrences across 16 files**. Measured:

```
$ docker run --rm swift:6.2-noble bash -c 'echo | clang -dM -E - | grep -E "__arm64__|__aarch64__"'
#define __aarch64__ 1
$ echo | clang -target arm64-apple-macos13 -dM -E - | grep -E "__arm64__|__aarch64__"
#define __aarch64__ 1
#define __arm64__ 1
```

`__arm64__` is an Apple-only predefine. Every `#if __arm64__` in objc4 takes the
**wrong branch** on Linux aarch64 — silently, with no diagnostic, selecting the
x86-64 or generic cache-mask storage, the wrong `CACHE_IMP_ENCODING`, the wrong
`SEL_HASH_SHIFT_XOR`, and a mismatched asm/C view of `cache_t`. The C side and
the `.s` side would disagree about the layout of the structure `objc_msgSend`
reads. Fix: `-D__arm64__=1` in the build, asserted by a `static_assert`.

The same trap exists for `__arm64e__` (4) — correctly absent — and `__x86_64__`
(29), which *is* defined on both platforms, so it is safe.

---

## 3. Image discovery, end to end

### 3.1 Darwin, as it actually works in this tree

1. `libSystem` calls `_objc_init()` before any library initializer
   (`objc-os.mm:900`).
2. `_objc_init` builds a `_dyld_objc_callbacks_v4 { 4, map_images, load_images,
   unmap_image, _objc_patch_root_of_class }` and hands it to
   `_dyld_objc_register_callbacks()`.
3. dyld calls `map_images(count, infos[], makeImageMutable)`
   (`objc-runtime-new.mm:3547`) with an array of
   `_dyld_objc_notify_mapped_info { mh, path, sectionLocationMetadata, ... }`,
   bottom-up.
4. `map_images_nolock` (`objc-os.mm:325`) calls `addHeader()` per image, which
   allocates a `header_info` holding an offset to the `mach_header` and an
   offset to dyld's `_dyld_section_location_info_t`.
5. `_read_images` asks each `header_info` for its sections. Every such request
   funnels through **exactly one function**:
   `getSectionData<T>(mhdr, info, kind, &outCount)` in `objc-os.h:427`, which
   calls `_dyld_lookup_section_info(mhdr, info, kind)`. There are **17 call
   sites in `objc-opt.mm`** (`classlist`, `nlclslist`, `catlist`, `catlist2`,
   `nlcatlist`, `protolist`, `selrefs`, `messagerefs`, `classrefs`, `superrefs`,
   `protocolrefs`, `stublist`, `hasForkOkSection`, `hasRawISASection`,
   `_getObjcImageInfo`) and **4 more** in `objc-runtime-new.mm`.
6. `_read_images` then registers selectors, fixes up class refs, remaps classes,
   realizes non-lazy classes, attaches categories, and registers protocols.
7. `load_images` runs `+load` for non-lazy classes/categories.

**The important structural fact:** in this objc4 vintage, objc4 no longer parses
Mach-O itself for its own metadata. dyld pre-computes section locations and
hands them over. Older objc4 (818.2 and before, which every public fork uses)
called `getsectiondata()` and walked load commands inline at dozens of sites.
Apple's refactor for their own convenience is what makes this port tractable —
**there is one function to reimplement, not thirty**.

### 3.2 The ELF analogue — measured, not assumed

Probe: `scratch-probe/probe.m` — a root class with `+load`, a category with
`+load`, a subclass with a property, a protocol, a `@protocol()` reference, a
class reference and message sends. Compiled two ways from the *same source*:

```
# Linux/ELF, aarch64, clang 17 (swift:6.2-noble container)
clang -c -fobjc-runtime=macosx-10.15 probe.m -o probe_apple.o && readelf -SW probe_apple.o
# macOS/Mach-O oracle, Apple clang 17
clang -c -target arm64-apple-macos13 probe.m -o probe_macho.o && otool -l probe_macho.o
```

**First result: `clang -fobjc-runtime=macosx-*` targeting `aarch64-unknown-linux-gnu`
compiles clean and emits Apple-ABI Objective-C metadata into ELF sections.** No
patched compiler. Section-name correspondence, measured both sides:

| Mach-O (oracle) | ELF (measured) |
|---|---|
| `__DATA,__objc_classlist` | `objc_classlist` |
| `__DATA,__objc_nlclslist` | `objc_nlclslist` |
| `__DATA,__objc_catlist` | `objc_catlist` |
| `__DATA,__objc_nlcatlist` | `objc_nlcatlist` |
| `__DATA,__objc_protolist` | `objc_protolist` |
| `__DATA,__objc_protorefs` | `objc_protorefs` |
| `__DATA,__objc_classrefs` | `objc_classrefs` |
| `__DATA,__objc_selrefs` | `objc_selrefs` |
| `__DATA,__objc_imageinfo` | `objc_imageinfo` |
| `__TEXT,__objc_methname` / `__objc_classname` / `__objc_methtype` | *(merged into `.rodata.str1.1`)* |
| `__DATA,__objc_const` / `__objc_data` / `__objc_ivar` | *(merged into `.data`)* |

The rule is "strip the leading `__`". This is the same transform the sibling
repo found in Swift IRGen (`GenDecl.cpp:1024–1046`, `__objc_classlist` →
`objc_classlist`). **Clang-ObjC and swiftc therefore emit the same ELF section
names and can share one discovery path.** That was the question worth answering
and the answer is yes.

Two consequences the table understates:

- The `__TEXT,__objc_methname` cstring section **does not exist on ELF** —
  selector name strings land in `.rodata.str1.1`. They are still in a
  non-writable `PT_LOAD`, so `strdupIfMutable`'s intent survives, but any code
  that identifies a string as a selector *by its section* will not work.
- `__objc_superrefs`, `__objc_msgrefs`, `__objc_fork_ok`, `__objc_rawisa` and
  `__objc_stublist` were not emitted by this probe. `msgrefs` is fixup dispatch
  (`SUPPORT_FIXUP` is already 0 off x86-64 macOS); `fork_ok`/`rawisa`/`stublist`
  are Apple toolchain features. `getSectionData` returning NULL for these is the
  correct and already-handled behaviour.

**Honest gap:** I could not reproduce Swift itself emitting `objc_classlist` on
a stock Linux toolchain, because stock `swift-corelibs-foundation`'s `NSObject`
is a Swift class, so `-Xfrontend -enable-objc-interop` refuses with *"only
classes that inherit from NSObject can be declared '@objc'"*. The Swift half of
the claim rests on the sibling repo's IRGen reading plus the clang measurement
above, not on a Swift binary I produced.

### 3.3 What replaces `_dyld_lookup_section_info`

Sections survive linking. Measured on a shared library built from two ObjC
objects:

```
[28] objc_classlist  PROGBITS 0000000000020558 ... WA
Section to Segment mapping:
  02  .fini_array .init_array .dynamic .got .got.plt .data .tm_clone_table
      objc_protolist objc_classrefs objc_selrefs objc_protorefs
      objc_classlist objc_nlclslist objc_catlist objc_nlcatlist .bss
```

They concatenate across objects and land inside the writable `PT_LOAD` — so
`_dyld_objc_mark_image_mutable` has nothing to do.

Two mechanisms were tested for finding them at runtime; **both work**.

**(a) Linker-generated encapsulation symbols.** Because `objc_classlist` is a
valid C identifier, GNU ld and lld synthesize `__start_objc_classlist` /
`__stop_objc_classlist`. Measured, in an executable linked from the two probe
objects:

```
__start_objc_classlist=0xaaaac2760578 __stop_objc_classlist=0xaaaac2760590  n=3
```

Three classes — `Base`, `Derived`, `Other`. Correct. Cost: zero. Limitation:
this only finds *your own* image's sections, so it requires each ObjC image to
register itself, and clang emits **no** registration constructor for the Apple
runtime on ELF (verified: `readelf -SW probe_apple.o` shows no `.init_array`).

**(b) `dl_iterate_phdr` + on-disk section headers.** ELF section headers are not
mapped at runtime — only program headers are — so the section table must be read
from the file. `dl_iterate_phdr` gives `dlpi_name` and `dlpi_addr`; `mmap` the
file, walk `e_shoff`, and the runtime address of a section is
`dlpi_addr + sh_addr`. Measured (`scratch-probe/elfscan.c`):

```
image: /src/libprobe.so                          base=0xffffaf890000
   objc_imageinfo     sh_addr=0x156a size=16 -> runtime 0xffffaf89156a
   objc_classlist     sh_addr=0x20560 size=24 -> runtime 0xffffaf8b0560
   objc_nlclslist     sh_addr=0x20578 size=16 -> runtime 0xffffaf8b0578
   ...
```

Works for images the runtime never cooperated with — including prebuilt
`swiftc` output. Cost: one open+mmap+scan per image at load. Requires the file
to still exist on disk (true except for `memfd`/deleted-file cases).

**Proposal: (b) as the general path, (a) as the fast path.** Build, per image, a
table indexed by `_dyld_section_location_kind` holding `{start, size}`, and
reimplement `getSectionData<T>()` to index it. `header_info::dyldInfo()` returns
a pointer to that table instead of dyld's. All 21 call sites and every signature
in `objc-private.h`/`objc-opt.mm` are untouched.

### 3.4 The messenger

`objc-msg-arm64.s` is architecture-portable but **assembler-dialect-specific**.
It needs, mechanically:

- `.macro ENTRY /* name */ … $0 … .endmacro` → `.macro ENTRY name … \name … .endm`.
  Apple's `as` dialect with `$0` positional args is MachO-only in clang's
  integrated assembler.
- Leading underscores: `_objc_msgSend` → `objc_msgSend`.
- `adrp x17, sym@PAGE` / `add x17, x17, sym@PAGEOFF` → `adrp x17, sym` /
  `add x17, x17, :lo12:sym`, and GOT-indirect (`:got:` / `:got_lo12:`) for
  anything that must go through the PLT/GOT in a shared object.
- `.private_extern` → `.hidden`; `.globl` unchanged.
- Local labels `Lfoo` → `.Lfoo`.
- `.section __TEXT,__objc_methname,cstring_literals` → `.section .rodata.str1.1,"aMS",@progbits,1`;
  `.section __DATA,__objc_selrefs,literal_pointers,no_dead_strip` →
  `.section objc_selrefs,"aw",@progbits` + `.protected`/`SHF_GNU_RETAIN`.
- `.section __LD,__compact_unwind,regular,debug` + the `UNWIND` macro → real
  `.cfi_startproc`/`.cfi_endproc`/`.cfi_def_cfa` directives emitting
  `.eh_frame`. **This is not optional**: without it, a C++ or ObjC exception
  thrown through `objc_msgSend` cannot unwind, and `_Unwind_RaiseException`
  calls `std::terminate`.
- `.subsections_via_symbols` → delete.
- `objc_restartableRanges` (the `RestartableEntry` table at line 65) → keep the
  symbol so `objc-cache.mm` still links; the table is unused when cache GC is
  off.

The x86-64 messenger has the same class of problem plus `%rip`-relative vs
absolute addressing and a different unwind story.

### 3.5 Replacing dyld's notify hook

There is no `_dyld_objc_register_callbacks` on Linux. `glibc` gives us
`dl_iterate_phdr` for images already loaded and `_dl_debug_state` (an
`rtld`-internal breakpoint hook, not a stable API) for later ones. The workable
design, in order of preference:

1. **At `_objc_init` time**, `dl_iterate_phdr` over everything already mapped,
   build `objc_mapped_image` records for images with an `objc_imageinfo`
   section, and call the existing `map_images()` / `load_images()` unchanged.
2. **For `dlopen`**, interpose `dlopen`/`dlclose` in `libobjc.so` (they are
   PLT-resolved, so a definition in libobjc wins for anything linked after it)
   and re-scan on the way out. Fragile if the caller uses `dlvsym`/`RTLD_NEXT`.
3. **Preferred long-term**: an `objc-elf-init.o` stub — a tiny `.init_array`
   constructor that reads its own `__start_/__stop_` symbols and calls
   `_objc_register_image()`. This is mechanism (a) from §3.3, is exactly what
   Apple's Windows path did (§4.1), and is what `libobjc2` does today. It needs
   the stub to be on the link line of every ObjC image, which we control for our
   own builds and can plausibly get for `swiftc` via autolinking, but *not* for
   an arbitrary prebuilt `.so`.

The honest position: **(1)+(2) covers everything but is slightly fragile; (3) is
clean but requires cooperation.** Ship (1) first — it is all the MVP needs.

---

## 4. Prior art

### 4.1 Apple's own non-Mach-O path — in this very tree

`vendor/objc4/runtime/objcrt.h` (25 lines, still shipped, entirely dead) is the
Windows/PE image-registration interface:

```c
typedef struct {
    int count;  // number of pointer pairs that follow
    void *modStart;      void *modEnd;
    void *protoStart;    void *protoEnd;
    void *iiStart;       void *iiEnd;
    void *selrefsStart;  void *selrefsEnd;
    void *clsrefsStart;  void *clsrefsEnd;
} objc_sections;

OBJC_EXPORT void *_objc_init_image(HMODULE image, const objc_sections *sects);
OBJC_EXPORT void  _objc_load_image(HMODULE image, void *hinfo);
OBJC_EXPORT void  _objc_unload_image(HMODULE image, void *hinfo);
```

This is the design §3.3(a) and §3.5(3) arrive at independently: on a platform
where the loader cannot enumerate an arbitrary image's sections, each image
hands the runtime its own `(start, end)` pairs at load time, and the runtime
keys everything off an opaque image handle. Apple shipped exactly that, and the
`objc_sections` layout maps one-for-one onto `__start_/__stop_` symbol pairs.
`objcrt/objcrt.vcproj`, `objc.sln`, `prebuild.bat` and `version.bat` are the
remains of the build. **Reusable as a design template and as the argument that
the runtime's core does not assume Mach-O.**

`Messengers.subproj/objc-msg-win32.m` (525 lines) is the matching messenger:
MSVC `__declspec(naked)` i386 inline asm, `#define isa 0 / cache 32 / mask 0 /
occupied 4 / buckets 8` — the *old* runtime's `objc_cache`, not `cache_t`. It is
evidence, not code. Nothing in it survives to arm64.

### 4.2 Darling — [`darlinghq/darling-objc4`](https://github.com/darlinghq/darling-objc4)

Darling runs **Mach-O binaries** on Linux via its own `mldr` loader and a port
of `dyld`, plus Mach-O wrappers around ELF libraries bound by a
`dyld_elf_stub_binder`
([blog](https://blog.darlinghq.org/2018/07/mach-o-linking-and-loading-tricks.html),
[loader wiki](https://wiki.darlinghq.org/documentation:loader)). Their objc4
therefore keeps Mach-O and keeps dyld; it solves a *different* problem —
"run Apple binaries" rather than "build Linux binaries". Reusable: their
`objc-os.h` Linux branch shows which Darwin headers can be satisfied by
substitutes, their Mach/`libkern` shims, and above all the evidence that objc4's
class-realization core runs correctly off Darwin. Not reusable: the entire image
path, because ours must consume ELF.

### 4.3 The buildable-objc4 forks

[`showxu/objc4`](https://github.com/showxu/objc4),
[`zox01/objc4`](https://github.com/zox01/objc4),
[`jadite/objc4`](https://github.com/jadite/objc4) — all objc4-781/818.2, all
*macOS* projects that stub out Apple-internal headers to get a debuggable build
in Xcode. Their value is the catalogue of private headers they had to fake
(`os/lock_private.h`, `os/feature_private.h`, `_simple.h`,
`CrashReporterClient.h`, `pthread_machdep.h`) — the same set §2.4 must supply.
They contain no non-Darwin work.

### 4.4 `libobjc2` — [gnustep/libobjc2](https://github.com/gnustep/libobjc2)

Wrong ABI (established in the sibling repo's `docs/OBJC_RUNTIME.md` §4), but
its **ELF mechanics** are directly instructive: per-image `__objc_init`
constructor in `.init_array`, `__start_/__stop_` section encapsulation symbols,
and its handling of `.eh_frame`-based ObjC exceptions on ELF. Read those three
things; take nothing else.

### 4.5 Not found

No pre-existing objc4→ELF port. Searches for one return only the macOS
buildable forks, Darling (Mach-O), and libobjc2 (different ABI). This appears to
be new work.

---

## 5. Measured starting state

### 5.1 Nothing compiles today

```
$ docker run --rm -v "$PWD":/src -w /src swift:6.2-noble bash -c '
    clang++ -std=gnu++20 -fobjc-runtime=macosx-10.15 -c vendor/objc4/runtime/objc-weak.mm \
      -Ivendor/objc4/runtime -Iscratch-probe/shim -o /tmp/o.o'
vendor/objc4/runtime/isa.h:129:5: error: unknown architecture for packed isa
vendor/objc4/runtime/objc.h:32:10: fatal error: 'Availability.h' file not found
```

Identical for `objc-typeencoding.mm`, `objc-sync.mm`, `objc-zalloc.mm`,
`hashtable2.mm` — i.e. for the files classified CLEAN. **Even the clean files
need the shim directory before they build**, because everything transitively
includes `objc-private.h` → `objc-os.h`. The first error is `__arm64__` (§2.7),
the second is the missing `Availability.h`. `objc-os.h`'s `#error unknown OS`
sits behind both.

### 5.2 Test suite

`vendor/objc4/test/` contains **265 files** — Apple's own behavioural test
suite for this exact runtime (`04-load-image-notification.m`,
`addMethod.m`, `arr-weak-error.m`, `ARCLayouts.m`, …). This is the differential
oracle: each test that runs on macOS against the system runtime and on Linux
against ours, with matching output, is a measured claim. It should be the
harness's primary corpus rather than tests we invent.

### 5.3 Open risk not yet measured

**Relative ("small") method lists.** On Darwin these encode selectors as a
32-bit offset to a selref rather than a pointer, and the runtime's
`method_t::small` path depends on the layout. The probe object showed 9
`R_AARCH64_PREL32` relocations on ELF and the macOS oracle showed a *large*
method list (`entsize=0x18, count=3`) for the same source, so the two are
plausibly not agreeing — but `-f[no-]objc-relative-method-lists` is not a valid
flag on this clang, and the decision is made at link time on Darwin
(`ld -objc_relative_method_lists`), so a `.o`-level comparison does not settle
it. **Must be re-measured against linked images before phase 3.** If ELF gets
relative method lists and the relative offsets are computed differently, every
selector lookup is wrong.

---

## 6. What to change, and where

The port is not spread evenly. Ranked by leverage:

1. `objc-os.h` (532) — replace `#error unknown OS` with a Linux branch, and
   `getSectionData` with the ELF table lookup. **This one file unblocks the other
   106.**
2. `objc-config.h` (377) — a real `TARGET_OS_LINUX` branch: `SUPPORT_PREOPT 0`,
   `SUPPORT_ZONES 0`, `SUPPORT_GC_COMPAT 0`, `SUPPORT_MESSAGE_LOGGING 0`,
   `HAVE_TASK_RESTARTABLE_RANGES 0`, `OBJC_USE_ROSETTA 0`,
   `CONFIG_USE_PREOPT_CACHES 0`, `HAVE_ASPRINTF 1`,
   `HAVE_CLOCK_GETTIME_NSEC_NP 0`, `OBJC_THREADING_PACKAGE OBJC_THREADING_PTHREADS`.
3. A new `compat/` shim dir: `TargetConditionals.h`, `Availability.h`,
   `AvailabilityMacros.h`, `objc-probes.h`, `os/overflow.h`, `_simple.h`,
   `CrashReporterClient.h`, `Block.h`/`Block_private.h`.
4. A new `runtime/objc-elf.mm` — image registration, section table,
   `_objc_register_image`, the `dl_iterate_phdr` scan.
5. `Messengers.subproj/objc-msg-arm64-elf.s` — dialect translation of
   `objc-msg-arm64.s` plus CFI.
6. `objc-opt.mm` (492) — take the `#if !SUPPORT_PREOPT` path; delete the
   shared-cache reader.
7. `objc-cache.mm` (1658) — excise the Mach thread-scan; leak cache garbage for
   now.
8. `objc-errors.mm` (358) — `stderr` instead of ASL/CrashReporter.

Everything else is either already portable or deferred.
