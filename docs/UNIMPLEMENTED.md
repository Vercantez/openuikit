# Unimplemented

Every hole in the port, with the mechanism that is missing and what happens
when you hit it.

The rule this project holds itself to: **no silent stubs.** A feature we have
not ported either aborts with file/line/function through
`objc4linux_unimplemented()` (`compat/objc4linux/unimplemented.h`), or is a
deliberate behavioural choice documented here with its cost stated. Nothing
quietly returns a plausible-looking wrong answer.

Status as of the build-system phase: **all 32 translation units compile,
`libobjc.so` links with no unresolved symbols, and it `dlopen`s.** It does not
yet *do* anything, because image discovery is not implemented — see A1.

---

## A. Loud aborts — reaching these kills the process with a message

These are `objc4linux_unimplemented()` calls in
`compat/src/objc4linux-compat.cpp`.

### A1. Image discovery — the one that matters

| symbol | consequence |
|---|---|
| `_dyld_objc_register_callbacks` | `_objc_init()` aborts. Nothing is ever discovered. |
| `_dyld_lookup_section_info` | `getSectionData<T>()` aborts. No `objc_classlist`, no `objc_selrefs`, nothing. |
| `_dyld_get_prog_image_header` | `map_images_nolock`'s sizing heuristic aborts. |
| `dyld_image_header_containing_address` | `_headerForAddress()` and the "is this IMP libobjc's?" fast path abort. |
| `_dyld_get_dlopen_image_header` | the `objc_getClass` hook aborts. |
| `_dyld_get_image_uuid` | duplicate-class diagnostics abort. |

**This is the central missing piece, not a corner case.** On Darwin, dyld
pre-computes per-image section locations and calls `map_images`/`load_images`.
Linux has no such notification and ELF section headers are not mapped at
runtime, only program headers.

The design is settled and measured (`docs/PORT_MAP.md` §3.3: `dl_iterate_phdr`
for the image list plus an on-disk `Elf64_Shdr` scan for section bounds, with
linker-synthesised `__start_`/`__stop_` symbols as a fast path). The code —
`runtime/objc-elf.mm` — is not written. It is `docs/PORT_PLAN.md` phase 1
step 3.

Everything else in this document is small next to this.

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

Only reachable from `objc-block-trampolines.mm`, which is unported (B2).

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

### B2. `imp_implementationWithBlock` / block trampolines

`objc-block-trampolines.mm` compiles but its `vm_allocate`/`vm_remap` calls
abort. Darwin aliases one RX text page onto many RW data pages; the exact
Linux equivalent is `memfd_create(2)` + `ftruncate` + two `mmap`s of the same
fd. Not written.

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

### C1. Unwinding through `SAVE_REGS` frames has no CFI

`scripts/gen-elf-asm.py` emits `.cfi_startproc`/`.cfi_endproc` around every
`ENTRY`/`END_ENTRY` pair. That is **correct and complete** for the `NoFrame`
functions — `objc_msgSend`, `objc_msgLookup`, `objc_msgSendSuper2` and friends
never move SP and never spill LR, so the default rule (CFA = SP+0, return
address in x30) is exactly right.

It is **not** complete for the functions that go through `SAVE_REGS`:
`_objc_msgSend_uncached`, `_objc_msgLookup_uncached`, `_method_invoke`. Those
subtract from SP and spill x0–x8/q0–q7/fp/lr, and no
`.cfi_def_cfa_offset`/`.cfi_offset` is emitted for them. An exception thrown
from inside a method resolver or from `+initialize` will unwind with a wrong
CFA.

This needs hand-written CFI inside `SAVE_REGS`/`RESTORE_REGS`. It will show up
as failures in `vendor/objc4/test/exc*.m`.

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

That fixes the load failure (`undefined symbol:
section$end$__TEXT$__init_offsets`) but does **not** fix the underlying
ordering problem: on Darwin `+load` is guaranteed to run before *any*
initializer in an image that uses Objective-C; on Linux we can only be ordered
against initializers the dynamic linker happens to sort after ours.
`docs/PORT_PLAN.md` calls this the riskiest unknown in the project and it is
still unknown.

### C4. `issetugid` is approximated, in the permissive direction

`compat/objc4linux/darwin-cdefs.h`. Darwin/BSD have a dedicated syscall for
"did this process start setuid/setgid?"; glibc does not, so we compare real
and effective ids. A process that started setuid and then dropped privileges
reads as clean here but as tainted on Darwin. objc4 uses this only to decide
whether to honour `OBJC_*` environment variables — so **this errs toward
honouring them.** Note the direction.

### C5. `malloc_size` over-reports

`compat/malloc/malloc.h`. Darwin's `malloc_size` returns the allocated block
size; glibc's `malloc_usable_size` returns the *usable* size, which may be
larger (rounded to the allocator's bin). objc4 uses it for
`objc_isUniquelyReferenced` sizing and diagnostics, not for ivar layout, so
over-reporting is safe at today's call sites. Every new use must be re-checked.

### C6. `os_unfair_lock` semantics are weaker

`compat/os/lock_private.h` maps it to a `PTHREAD_MUTEX_NORMAL` mutex. Both are
futex-backed, but `os_unfair_lock` records the owning thread and traps on
unlock-by-wrong-thread, where a NORMAL pthread mutex is undefined behaviour.
In practice this is unused — Linux selects `OBJC_THREADING_PTHREADS`, and Apple
already wrote that back-end (`runtime/Threading/pthreads.h`).

### C7. Relative ("small") method lists — still unmeasured

`docs/PORT_MAP.md` §5.3 flagged this and nothing here settles it. On Darwin,
small method lists encode selectors as a 32-bit offset to a selref. Whether
ELF gets the same encoding, and whether the offsets are computed the same way,
must be measured against **linked images**, not `.o` files. If they disagree,
every selector lookup is wrong — and phase 2's selector tests would pass for
the wrong reason.

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
