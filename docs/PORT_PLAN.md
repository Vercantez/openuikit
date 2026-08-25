# Port plan

Phased plan for building Apple's objc4 on Linux/aarch64, then x86-64. Read
`docs/PORT_MAP.md` first — the classification and the measurements that justify
these phases are there, not repeated here.

Effort estimates are in **focused engineering days**, and they are guesses
except where a measurement pins them. They are stated so they can be wrong in
public.

---

## Phase 0 — Build scaffolding *(2–3 days)*

Nothing in `vendor/objc4` compiles today. Measured, on the files classified
CLEAN:

```
vendor/objc4/runtime/isa.h:129:5: error: unknown architecture for packed isa
vendor/objc4/runtime/objc.h:32:10: fatal error: 'Availability.h' file not found
```

**Deliverables**

- `scripts/apply-patches.sh` + `patches/` — the mechanism the README promises.
  Every change to vendor lands as a numbered patch with a one-line rationale.
  Verify re-appliability by making the script idempotent from a clean checkout.
- `compat/` shim headers: `TargetConditionals.h` (all `TARGET_OS_*` = 0,
  `TARGET_OS_LINUX` = 1), `Availability.h`, `AvailabilityMacros.h`,
  `objc-probes.h` (empty dtrace macros), `os/overflow.h` (`__builtin_*_overflow`),
  `_simple.h`, `CrashReporterClient.h`, `Block.h` / `Block_private.h`.
- `patches/0001-config-linux-branch.patch` — the `objc-config.h` Linux branch
  listed in PORT_MAP §6.2.
- `-D__arm64__=1` in the build, plus a `static_assert` that it is set. This is
  the highest-consequence one-line change in the project (PORT_MAP §2.7): 43
  sites take the wrong branch without it, silently, including the `cache_t`
  layout that C and assembly must agree on.
- A `Makefile`/`CMakeLists` that builds one `.mm` at a time so progress is
  measurable, and a Docker wrapper (`scripts/linux-build.sh`).
- `harness/` skeleton: `run-macos.sh` (system runtime) and `run-linux.sh`
  (our `libobjc.so`), plus `scripts/diff-test.sh` that runs one test on both and
  diffs. **Build this before any runtime code** — the project's whole claim to
  correctness rests on it.

**Exit criterion:** every file classified CLEAN in PORT_MAP §1 compiles to a
`.o` on Linux aarch64. That is 34 files / ~8,200 lines and includes
`objc-weak.mm`, `objc-sync.mm`, `objc-initialize.mm`, `objc-loadmethod.mm`,
`objc-references.mm`, `objc-typeencoding.mm` and all the LLVM containers.

---

## Phase 1 — MVP: "a class exists and responds to a selector" *(10–15 days)*

The minimum viable milestone. Concretely, this program, compiled with stock
clang on Linux, links against our `libobjc.so`, runs, and prints the same thing
as the same source built on macOS against the system runtime:

```objc
// tests/000-mvp.m
@interface Greeter { Class isa; }
+ (id)alloc;
- (const char *)greeting;
@end
@implementation Greeter
+ (id)alloc { return class_createInstance(self, 0); }
- (const char *)greeting { return "hello"; }
@end

int main(void) {
    Class c = objc_getClass("Greeter");
    printf("class=%s\n", class_getName(c));
    printf("responds=%d\n", (int)class_respondsToSelector(c, sel_registerName("greeting")));
    id g = [Greeter alloc];
    printf("says=%s\n", [g greeting]);
    return 0;
}
```

That single program requires, in order:

1. **`objc-os.h` Linux branch.** Replace `#error unknown OS`. Provide
   `headerType` as our own opaque ELF image record, `nanoseconds()` via
   `clock_gettime(CLOCK_MONOTONIC)`, `strdupIfMutable` with
   `_dyld_is_memory_immutable` stubbed to `false`, `_objc_asprintf` → `asprintf`.
   Keep the `explicit_atomic`, `LoadExclusive`, `CompareAndSwap` and
   `word_align` machinery unchanged — it is already portable.
2. **`Threading` = pthreads.** Already written by Apple
   (`Threading/pthreads.h`, 245 lines, 37 `pthread_*` calls, with
   `#if !_OBJC_PTHREAD_IS_DARWIN` branches in place). Select it and verify
   `objc-lockdebug.mm` still builds.
3. **`runtime/objc-elf.mm`** — the new file. Per-image section table keyed by
   `_dyld_section_location_kind`; `dl_iterate_phdr` + on-disk `Elf64_Shdr` scan
   to populate it (PORT_MAP §3.3(b), measured working); `_objc_register_image`;
   an `__attribute__((constructor(101)))` entry that scans all mapped images and
   calls the existing `map_images()` / `load_images()` **unchanged**.
4. **`getSectionData<T>()` reimplemented** in `objc-os.h` against that table.
   This is the whole seam — 21 call sites keep their signatures.
5. **`objc-opt.mm`** — `SUPPORT_PREOPT 0`; the `#if !SUPPORT_PREOPT` fallback
   bodies already exist. Delete the `objc_headeropt_ro_t` reader.
6. **`objc-msg-arm64-elf.s`** — dialect translation per PORT_MAP §3.4, plus real
   `.cfi_*` directives. Ship it *without* the fast paths first if that helps:
   an `objc_msgSend` that always calls `lookUpImpOrForward` is correct and
   slow, and correctness is the milestone.
7. **`objc-cache.mm`** — cut `_collecting_in_critical()` down to
   `return FALSE` and make `cache_collect()` never free. **Label this a leak in
   the source and in `docs/KNOWN_GAPS.md`.** It is a stub, not a feature.
8. **`objc-errors.mm`** — `write(2)` to `stderr`. Not `syslog`: `objc-os.h`
   deliberately marks `syslog`/`vsyslog` unavailable because they can re-enter
   `objc_msgSend`.
9. **`objc-runtime-new.mm`** — replace the dyld helpers with the §2.2
   substitutes (`dladdr` for the two `dyld_image_*_containing_address` uses,
   `sdkIsAtLeast(...) → 1`, `calloc` for `malloc_zone_malloc_with_options`).
   No structural change; this file's 9,889 lines are almost entirely portable.
10. **`objc-exception.mm`** — `SUPPORT_ALT_HANDLERS 0`, keep everything else.
    It already targets the Itanium C++ ABI (`__cxa_*`, `_Unwind_*`,
    `__gxx_personality_v0`), which Linux provides via `libc++abi` +
    `libunwind`. Link one of them and register `__objc_personality_v0`.

**What is explicitly stubbed in phase 1** (each labelled in code and in
`KNOWN_GAPS.md`): cache garbage collection, `imp_implementationWithBlock`,
`objc_setAssociatedObject`'s edge cases around weak, tagged pointers, and all
shared-cache preoptimization.

**Exit criterion:** `tests/000-mvp.m` produces byte-identical output on macOS
and Linux, run by `scripts/diff-test.sh`.

---

## Phase 2 — The behaviour suite *(10–15 days)*

Turn on Apple's own tests. `vendor/objc4/test/` has **265 files** written
against this exact runtime. They are the oracle; do not invent replacements.

Order of attack, roughly by dependency:

| group | tests | what it forces |
|---|---|---|
| classes & selectors | `classes.m`, `getClassList.m`, `addMethod.m`, `addMethods.m`, `sel*.m` | selector uniquing, class registration |
| `+load` / `+initialize` | `03-load-parallel.m`, `04-load-image-notification.m`, `05-*`, `load*.m`, `initialize*.m` | `load_images` ordering, non-lazy class lists, the ELF `.init_array` ordering question |
| categories | `category*.m`, `protocol*.m` | `catlist`/`nlcatlist` discovery, override precedence |
| ivars & properties | `ivar*.m`, `properties*.m`, `accessors*.m`, `layout*.m` | non-fragile ivar layout, `objc-layout.mm` |
| ARC & weak | `arr*.m`, `ARCLayouts.m`, `weak*.m`, `06-ARCLayoutsWithoutWeak.m` | `objc-weak.mm`, side tables, autorelease pools |
| associated objects | `association*.m` | `objc-references.mm` |
| exceptions | `exc*.m`, `exceptions*.m` | unwinding through `objc_msgSend` — the CFI work from phase 1 gets its real test here |
| `@synchronized` | `synchronized*.m` | `objc-sync.mm` |

**The tests are the deliverable**, and each is a measured claim. A test that
fails and is *precisely described* in `KNOWN_GAPS.md` is a better outcome than a
test quietly skipped.

**Exit criterion:** a published pass/fail table over all 265, with every failure
either fixed or explained in one sentence naming the mechanism.

---

## Phase 3 — Real programs *(8–12 days)*

Phase 2 tests are small and single-image. Phase 3 is about the things only
multi-image, long-running, multithreaded programs expose.

- **`dlopen` after startup.** Phase 1's constructor only sees images mapped at
  start. Add the interposition or the `objc-elf-init.o` stub (PORT_MAP §3.5).
  Test: `04-load-image-notification.m`, `bundle*.m`.
- **Cache garbage collection for real.** Replace the phase-1 leak with the
  `tgkill(SIGRTMIN)` + `ucontext_t->uc_mcontext.pc` scan described in PORT_MAP
  §2.1, or evaluate `rseq(2)`. Measure the leak first so the fix has a number
  attached to it.
- **`imp_implementationWithBlock`.** `memfd_create` + dual `mmap` replacing
  `vm_remap` (PORT_MAP §2.1). Needs `libBlocksRuntime` or `-fblocks` with
  clang's runtime.
- **Fork safety.** `_objc_atfork_prepare/parent/child` and `forEachOrderedLock`
  are already written and portable; wire them to `pthread_atfork`.
- **Relative method lists.** PORT_MAP §5.3 flags this as unmeasured. Settle it
  *here* by comparing linked images on both platforms, not `.o` files. If ELF
  and Mach-O disagree on the encoding, phase 2's selector tests will have been
  passing for the wrong reason.
- **Tagged pointers.** `SUPPORT_TAGGED_POINTERS` is on for LP64. The tag
  encoding interacts with `OBJC_VM_MAX_ADDRESS`, which we are choosing by hand
  on Linux (PORT_MAP §2.1). Verify against `taggedPointers*.m`.

**Exit criterion:** a non-trivial multi-image, multithreaded ObjC program (build
one from the test corpus) runs identically on both platforms under repeated
execution.

---

## Phase 4 — x86-64 *(5–8 days)*

Mostly a repeat of phase 1 step 6 for `objc-msg-x86_64.s`, plus:

- `CACHE_MASK_STORAGE_OUTLINED` instead of `HIGH_16_BIG_ADDRS` — a genuinely
  different `cache_t` layout, so phase 2's suite must be re-run in full, not
  spot-checked.
- `SUPPORT_FIXUP` is 0 off macOS/x86-64, so `__objc_msgrefs` stays absent.
- The isa mask differs (`0x00007ffffffffff8`); revisit the
  `OBJC_VM_MAX_ADDRESS` choice for x86-64 Linux.

Docker on this arm64 host runs x86-64 under emulation, which is slow but
sufficient for correctness. Performance numbers from that setup are worthless
and should not be reported.

---

## Phase 5 — Performance *(open-ended)*

Not attempted before phase 3 is green. The interesting numbers are
`objc_msgSend` hit-rate/latency versus macOS on the same silicon, and startup
cost of the `dl_iterate_phdr` + file-mmap image scan versus dyld's precomputed
table (which we can never match, since dyld does that work at cache-build time).

---

## Riskiest unknown

**The `+load` / static-initializer ordering contract.**

On Darwin, `libSystem` calls `_objc_init()` *before* any library initializer
runs, and dyld then calls `map_images` for a whole batch of images bottom-up,
followed by `load_images`. objc4 depends on this so hard that it hand-rolls its
own C++ static-constructor pass (`static_init()` reading
`section$start$__TEXT$__init_offsets`) because it is running *earlier than its
own initializers*. The comment at `objc-os.mm:712` says so directly.

On Linux there is no such privileged position. `libobjc.so`'s constructor runs
in `.init_array` alongside everything else, ordered by the dynamic linker's
dependency sort with `constructor(priority)` as the only lever — and priorities
are only ordered *within* one image. Consequences we cannot yet bound:

- A C++ static initializer in some other library that touches an ObjC class may
  run before we have realized it.
- `+load` on Darwin is guaranteed to run before *any* initializer in an image
  that uses ObjC. On Linux we can only guarantee it runs before initializers
  that happen to be sorted after ours.
- `map_images` being called twice with no intervening `load_images` is a case
  objc4 handles explicitly (`objc-os.mm:345`, the WINE workaround). Our scan
  loop may produce sequences dyld never produces, hitting paths that have only
  ever been exercised by that one bug report.

This is a **semantics** risk, not a porting risk: it does not stop anything
compiling, it produces intermittent, ordering-dependent failures in exactly the
programs that are hardest to reduce. Phase 2's `+load` group is where it
surfaces, and it may force phase 3's `objc-elf-init.o` stub to become mandatory
rather than optional.

**Second riskiest:** `OBJC_VM_MAX_ADDRESS` and the packed-isa `shiftcls` width.
Darwin picks the isa bitfield layout from the known Mach VM ceiling. Linux
aarch64 VA size is a kernel config (39/42/48/52-bit) and is *not* fixed across
machines. Choose too small a `shiftcls` and a class allocated above the assumed
ceiling corrupts every object pointing at it — silently, and only on some
kernels. The safe move is to force `SUPPORT_NONPOINTER_ISA 0` for phase 1 and
revisit with measurement; that costs performance and changes
`objc_debug_isa_class_mask`, which Swift reads.

---

## Total

Roughly **35–55 focused days** to the end of phase 3 on aarch64 — a working,
test-verified Apple objc4 on Linux — with phase 4 and 5 on top. The two risks
above are the ones that could move that materially, and neither is discovered by
reading; they are discovered by phase 2.
