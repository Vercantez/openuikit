# Unimplemented

Every hole in the port, with the mechanism that is missing and what happens
when you hit it.

The rule this project holds itself to: **no silent stubs.** A feature we have
not ported either aborts with file/line/function through
`objc4linux_unimplemented()` (`compat/objc4linux/unimplemented.h`), or is a
deliberate behavioural choice documented here with its cost stated. Nothing
quietly returns a plausible-looking wrong answer.

Status: **it runs.** ELF image discovery is implemented (A1 below is now a
description of how, not of a hole), and the differential corpus is
**43/43 PASS** against the real macOS objc4 — classes, selectors, dispatch,
categories, protocols, ivars, properties, ARC, weak references, associated
objects, exceptions, `@synchronized`, multi-image programs, `dlopen`ed
images, and eight-thread contention.

What is still missing is listed below, ranked. The largest single item is
`imp_implementationWithBlock` (B2): it aborts loudly and needs trampoline
assembly that is not even in the vendored tree.

---

## A. Loud aborts — reaching these kills the process with a message

These are `objc4linux_unimplemented()` calls in
`compat/src/objc4linux-compat.cpp`.

### A1. Image discovery — IMPLEMENTED

*This section used to describe the central hole in the port. It is now a
description of the mechanism, kept here because the limits below are real.*

`compat/src/objc4linux-elf.cpp` implements the whole dyld image-discovery
surface: `_dyld_objc_register_callbacks`, `_dyld_lookup_section_info`,
`_dyld_get_prog_image_header`, `dyld_image_header_containing_address`,
`dyld_image_path_containing_address`, `_dyld_get_dlopen_image_header`,
`_dyld_is_memory_immutable`. `dl_iterate_phdr(3)` supplies the image list and
load bias; each image's on-disk ELF section header table supplies the
Objective-C section bounds, because ELF section headers are not mapped at run
time.

Remaining limits:

* **`_dyld_get_image_uuid` returns false.** The ELF analogue is
  `PT_NOTE`/`NT_GNU_BUILD_ID` and is not wired up. Used only for
  duplicate-class diagnostics, which therefore print less detail.

* **`dlopen` discovery depends on symbol interposition.** libobjc defines
  `dlopen`/`dlclose` and forwards through `RTLD_NEXT`. That works iff libobjc
  precedes libc in the caller's global symbol lookup order — which a normal
  `clang … -lobjc` link produces, and which `tests/042-dlopen.m` measures. A
  program that arranges otherwise silently gets no discovery; the escape
  hatch is the exported `objc4linux_scan_images()`, which is idempotent and
  always safe to call.

* **`dlmopen` namespaces are not handled.** `dl_iterate_phdr` only walks the
  base namespace.

* **An image with more than 16 `PT_LOAD` segments** has the rest ignored for
  address-containment queries. Nothing a normal toolchain produces comes
  close.

### A2. Mach

`mach_task_self`, `task_threads`, `thread_get_state`, `mach_port_deallocate`,
`vm_allocate`, `vm_deallocate`, `vm_protect`, `vm_remap`,
`pthread_mach_thread_np`, `task_restartable_ranges_register`,
`task_restartable_ranges_synchronize`.

No Linux equivalent is drop-in. The features that need them are disabled (B1,
B2), so these should be unreachable; they abort so that we find out if they
are not.

### A3. Mach-O section access

`getsectiondata`, `getsegmentdata`, `getsectbynamefromheader_64`.

Only reachable from `objc-block-trampolines.mm`, which is unported (B2). The
two live callers were replaced rather than emulated: `addHeader()` no longer
probes for a `__OBJC` segment (nothing on ELF can emit one), and
`_headerForAddress()` now tests the image's `PT_LOAD` ranges via
`objc4linux_image_contains_address()`. Both in `patches/0006`.

### A4. Swift refcounting without libswiftCore

`swift_retain`/`swift_release` are weak-undefined on ELF (the honest analogue
of Darwin's `-delay_init`). If an object whose class `isSwiftStable()` reaches
`swiftRetain` while libswiftCore is absent, `_objc_fatal` fires with both
pointer values. That should be impossible; the check is there because the
alternative is a jump to address 0.

---

## B. Disabled features — no abort, but a real cost

### B1. Method cache garbage is never freed — this is a LEAK

`patches/0005`, `objc-cache.mm`.

`_collecting_in_critical()` answers "is any thread currently reading cache
buckets?", so freed buckets cannot be read after free. Darwin answers it with
`task_restartable_ranges_synchronize()` or with `task_threads()` +
`thread_get_state()` to sample every thread's PC. Neither exists here:

* `rseq(2)` is the semantic analogue of restartable ranges but **aborts**
  rather than restarts and needs a compiler-emitted critical-section
  descriptor.
* The thread-PC scan is implementable — enumerate `/proc/self/task`, signal
  each thread, read `uc_mcontext.pc` in the handler — but is not written.
  Note `/proc/<pid>/stat` field 30 reads 0 without `CAP_SYS_ADMIN` and is
  **not** usable for this.

We return `TRUE` unconditionally: "a reader may be active, do not free". That
is the conservative direction — returning `FALSE` would be a use-after-free.
**Every cache reallocation therefore leaks the old bucket array.** The
`collectALot` path, which spins until it is safe, is also short-circuited to
`return` since the spin would never terminate.

Not measured yet: how large the leak is for a realistic program. Measure it
before fixing it, so the fix has a number attached.

### B2. `imp_implementationWithBlock` / block trampolines — the largest remaining hole

MEASURED failure: `imp_implementationWithBlock()` aborts before it reaches
any of the memory-mapping code, at

    objc[10]: couldn't dlopen libobjc-trampolines.dylib

Two separate things are missing, and the second is the expensive one:

1. **The mapping.** Darwin aliases one RX text page onto many RW data pages
   with `vm_remap`. The Linux equivalent is `memfd_create(2)` + `ftruncate` +
   two `mmap`s of the same fd (one `PROT_READ|PROT_EXEC`, one
   `PROT_READ|PROT_WRITE`). Mechanical.

2. **The trampolines themselves.** The pages Darwin maps come from a
   *separate dylib*, `/usr/lib/libobjc-trampolines.dylib`, built from
   `objc-blocktramps-arm64.s` — which is **not in the vendored tree at all**.
   Porting this means writing that assembly from scratch, per architecture,
   with the exact page layout `TrampolinePointerWrapper` asserts against.

Anything that hits this dies loudly and immediately, which is the intended
behaviour. What hits it: `imp_implementationWithBlock`, and therefore ARC
block-based method installation and some KVO/proxy patterns.

### B3. Shared-cache preoptimization

`SUPPORT_PREOPT 0`, `CONFIG_USE_PREOPT_CACHES 0` (`patches/0001`). There is no
dyld shared cache, so the correct answer to every preopt query is "no". Apple's
`#if !SUPPORT_PREOPT` fallback bodies cover almost all of it; `patches/0007`
adds the two definitions Apple never needed because they never build that
configuration (`getSharedCachePreoptimizedProtocol`, `hasSharedCacheDyldInfo`).

### B4. Fork-safety lock auditing is not type-enforced

`patches/0002`. objc4 shadows `pthread_mutex_t`/`pthread_rwlock_t` with
`UNAVAILABLE_ATTRIBUTE` aliases so that direct use of an unaudited lock is a
compile error. That works on Darwin because `pthread_mutex_t` is a typedef of
`__darwin_pthread_mutex_t`. In glibc it is a union type in its own right, and
Apple's own `OBJC_THREADING_PTHREADS` back-end uses it directly — shadowing it
makes the threading package itself unavailable. So the audit is off on Linux.
The `_objc_atfork_*` handlers and `forEachOrderedLock` are still there and
still portable; nothing stops a future lock from being added outside them.

### B5. Crash-reporter message

`compat/CrashReporterClient.h`. `CRSetCrashLogMessage` stores into a global
`__objc_crash_message`. gdb/lldb can read it; `systemd-coredump` and `abrt`
cannot. `abort_with_reason` and `os_fault_with_payload` write namespace/code
and the message to stderr instead of producing a structured crash report.

### B6. dtrace probes

`compat/objc-probes.h`. All 28 probes compile to nothing; every
`_ENABLED()` is 0. SystemTap SDT could provide real ones later.

### B7. `_dyld_is_memory_immutable` always returns false

So `strdupIfMutable` always copies. Correct but wasteful. The real answer is
an address-range check against `PT_LOAD` segments lacking `PF_W`, cached at
image registration — i.e. it depends on A1.

### B8. `os_feature_enabled_simple` reads the environment

Darwin reads `objc4.plist` through the os_feature service. We read
`OBJC_FEATURE_<name>` from the environment and otherwise take the caller's
compiled-in default. Different plumbing, same defaults.

---

## C. Assumptions that could be wrong — these are the dangerous ones

### C1. Unwinding through `SAVE_REGS` frames — FIXED, epilogue still bare

*This section used to predict a failure. The prediction was right, the failure
was worse than expected, and it is now fixed. Kept because the remaining gap
is real.*

`scripts/gen-elf-asm.py` emits `.cfi_startproc`/`.cfi_endproc` around every
`ENTRY`/`END_ENTRY` pair, which is correct and complete for the `NoFrame`
functions — `objc_msgSend`, `objc_msgLookup`, `objc_msgSendSuper2` and friends
never move SP and never spill LR, so the default rule (CFA = SP+0, return
address in x30) is exactly right.

It was **not** complete for `_objc_msgSend_uncached`,
`_objc_msgLookup_uncached` and `_method_invoke`, which build a real frame in
`SAVE_REGS`. MEASURED consequence: `@throw` from `+initialize` did not
terminate with a bad message, it **hung** — the unwinder computed the CFA from
the default rule, read a "return address" out of the register spill area, and
walked in a circle. `patches/0004` now emits `.cfi_def_cfa_offset`,
`.cfi_offset 29/30` and `.cfi_def_cfa_register 29` for that frame, and
`tests/044-exception-through-uncached.m` covers throwing from `+initialize`,
from `+resolveInstanceMethod:`, and through six nested `@finally` blocks.

**Still bare:** the epilogue. `RESTORE_REGS` emits no CFI for `mov sp, fp` /
`ldp fp, lr, [sp], #16`, so the CFA rule stays fp-relative across two
instructions where fp already holds the caller's value. Safe for synchronous
unwinding — RESTORE_REGS is followed immediately by a tail call or a `ret`, so
there is no call site in that window and no throw can originate there — but an
**asynchronous** unwind, i.e. a profiler sampling exactly those two
instructions, gets a wrong frame.

### C2. The 48-bit address assumption

`patches/0003`, `compat/mach/vm_param.h`.

MEASURED on Ubuntu 24.04 aarch64, 4K pages, ASLR on
(`docs/measurements/va_layout.c`): every user address is 48 bits — text at
`0x0000aaaa…`, heap/mmap/libraries at `0x0000ffff…`. Darwin's arm64 ceiling is
2^47, so **routine Linux addresses sit above the range Apple's masks assume.**

Consequences, all of which are now patched but none of which is runtime-tested:

* `OBJC_VM_MAX_ADDRESS` = `0x0000fffffffffff8` instead of `0x00007ffffffffff8`.
* `FAST_DATA_MASK` widened from `0x0f007ffffffffff8` to `0x0f00fffffffffff8`.
  Apple's value would have silently truncated bit 47 of every `class_rw_t`
  pointer.
* The packed isa uses the arm64e-shaped 52-bit `shiftcls_and_sig` field
  (`ISA_MASK 0x007ffffffffffff8`) rather than embedded Darwin's 33-bit
  `shiftcls`, which assumes a 2^36 ceiling.
* `CACHE_MASK_STORAGE_HIGH_16_BIG_ADDRS` rather than `..._HIGH_16`; the
  bucket field is 48 bits, which fits `OBJC_VM_MAX_ADDRESS` exactly.

**What is still assumed:** that no address exceeds 2^48. A kernel built with
`CONFIG_ARM64_VA_BITS_52` can hand out 52-bit addresses, but only to a process
that asks via an `mmap` hint above 2^48, which nothing here does. If that
assumption breaks, objects are corrupted silently and only on some kernels.

`objc_debug_isa_class_mask` — which Swift and lldb read — is
`0x0000fffffffffff8` as a result, not Darwin's value. Anything that hardcodes
the Darwin constant will be wrong against this runtime.

### C3. `+load` and static-initializer ordering

On Darwin, libSystem calls `_objc_init()` *before* any library initializer, and
objc4 hand-rolls its own C++ static-constructor pass (`static_init()` reading
`section$start$__TEXT$__init_offsets`) because it runs earlier than its own
initializers. `patches/0006` makes that pass a no-op on Linux: our constructor
runs from `.init_array` like everyone else's, *after* our own static
constructors, so there is nothing left for us to run.

That is safe here, and the reason is measured rather than assumed:
`readelf -x .init_array libobjc.so` shows exactly **two** entries, both from
the toolchain (`frame_dummy` from crtbegin, `init_have_lse_atomics` from
compiler-rt). objc4 contributes zero static constructors — its release-build
discipline forbids them, and `static_init()` exists on Darwin only because
libSystem calls `_objc_init()` before dyld would have run them. There is
nothing left for us to run.

`_objc_init()` is then driven from a `constructor(101)` in
`compat/src/objc4linux-elf.cpp`. A priority puts the function in
`.init_array.00101`, which the linker script places **before** plain
`.init_array`, so it is the first thing that runs in libobjc; and glibc
initializes an object only after all of its dependencies, so every image that
links `-lobjc` initializes after us.

**What that reproduces:** Darwin's guarantee that `+load` runs before any
other image's initializers, for every image that links libobjc. Measured by
`tests/041-multi-image.m` (library `+load` before executable `+load`, both
before `main`).

**What it does not reproduce:** ordering against an image that uses
Objective-C *without* linking libobjc, or one the dynamic linker happens to
sort before us. On Darwin dyld knows which images contain Objective-C; on
Linux the link order is the only lever. `docs/PORT_PLAN.md` calls this the
riskiest unknown in the project. It is now a narrower unknown, not a
resolved one.

### C4. `issetugid` is approximated, in the permissive direction

`compat/objc4linux/darwin-cdefs.h`. Darwin/BSD have a dedicated syscall for
"did this process start setuid/setgid?"; glibc does not, so we compare real
and effective ids. A process that started setuid and then dropped privileges
reads as clean here but as tainted on Darwin. objc4 uses this only to decide
whether to honour `OBJC_*` environment variables — so **this errs toward
honouring them.** Note the direction.

### C5. `malloc_size` — one difference fixed, one still live

`compat/malloc/malloc.h`, implemented in `compat/src/objc4linux-elf.cpp`.

**Fixed:** Darwin returns 0 for a pointer malloc does not own; glibc's
`malloc_usable_size` decodes the chunk header regardless. objc4's `try_free()`
depends on the Darwin behaviour to tell heap metadata from constant data
compiled into an image, and `objc_disposeClassPair()` was calling `free()` on
a compiled-in ivar name and dying in `munmap_chunk()`. `malloc_size` now
answers 0 for any address inside a loaded ELF image. Measured by
`tests/023-dynamic-class.m`.

**Still live:** for a real heap pointer, glibc reports the *usable* size,
rounded up to the allocator's bin, where Darwin reports the requested size.
objc4 uses the number for `objc_isUniquelyReferenced` sizing and diagnostics,
never for ivar layout, so over-reporting is safe at today's call sites. Every
new use must be re-checked.

**Also assumed:** that `try_free`'s argument is either heap or inside an
image. A pointer to the stack or to an anonymous `mmap` would still reach
`malloc_usable_size`. objc4 never does that.

### C6. `os_unfair_lock` semantics are weaker

`compat/os/lock_private.h` maps it to a `PTHREAD_MUTEX_NORMAL` mutex. Both are
futex-backed, but `os_unfair_lock` records the owning thread and traps on
unlock-by-wrong-thread, where a NORMAL pthread mutex is undefined behaviour.
In practice this is unused — Linux selects `OBJC_THREADING_PTHREADS`, and Apple
already wrote that back-end (`runtime/Threading/pthreads.h`).

### C7. Relative ("small") method lists — MEASURED: not emitted

`docs/PORT_MAP.md` §5.3 flagged this as the way selector tests could pass for
the wrong reason. Settled by measurement rather than reasoning.

A small method list stores each selector as a 32-bit PC-relative offset to a
selref, which on ELF/aarch64 would be an `R_AARCH64_PREL32` relocation from
the method list into `objc_selrefs`. `readelf -r` on a compiled ObjC object
shows the method lists live in `.rela.data` and that section contains **only
`R_AARCH64_ABS64`** — absolute pointers. The only `PREL32` relocations in the
whole object are in `.rela.eh_frame`. clang 18 targeting
`aarch64-unknown-linux-gnu` with `-fobjc-runtime=macosx-10.15` therefore emits
**large, pointer-based method lists**, and `-fobjc-relative-method-lists` is
not even a recognised argument.

So the small-method-list path in `objc-runtime-new.mm` is dead code on Linux
today. That is the safe answer — it cannot be silently wrong — but it is a
*current-toolchain* fact, not a guarantee. If a future clang starts emitting
them on ELF, `method_t::getSmallDescription()` and the `selrefs` fixup order
both need re-measuring before they can be trusted.

---

## D. Deleted, not ported

* `dummy-library-mac-i386.c` — a 10.x i386 dylib compatibility stub, excluded
  from the build.
* `objc-msg-x86_64.s`, `objc-msg-arm.s`, `objc-msg-i386.s`, the simulator
  messengers, `objc-blocktramps-*.s`, `objc-sel-table.s` — not built.
  x86-64 is `docs/PORT_PLAN.md` phase 4.
* `Messengers.subproj/objc-msg-win32.m` and `objcrt/` — dead Windows code.
  Kept in vendor as the design template for image registration
  (`docs/PORT_MAP.md` §4.1).
