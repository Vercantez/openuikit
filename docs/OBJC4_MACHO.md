# Apple's objc4, built as Mach-O, on Linux

**Result: 4 patches, down from the ELF port's 9. `09_objc` passes. 41 of 44 on
the differential corpus, and all 3 failures are machorun gaps that predate this
work — none is attributable to objc4 or to the Mach-O route.**

The question this answers, in the user's words: *"I'd like to maintain less not
more."* `~/objc4-linux` is Apple's objc4 ported to **ELF**, 44/44 against the
real runtime, and it cost 9 patches to Apple's source. If machorun can load
Mach-O — and it can, 19 fixtures byte-identically — then objc4 should be
buildable in **its own native format**, and most of those 9 patches should
evaporate, because most of them exist only to make Mach-O source survive an ELF
toolchain.

That is what happened. Below is the accounting, and the two facts that did not
evaporate.

---

## 1. The patch ledger

`patches-macho/` versus `~/objc4-linux/patches/`.

| ELF port's patch | Mach-O | Why |
|---|---|---|
| 0001 config: 5 hunks | **1 hunk survives** | `SUPPORT_PREOPT` still has to be 0 — there is no dyld shared cache. The other four hunks (`CACHE_MASK_STORAGE`, `CONFIG_USE_PREOPT_CACHES`, `HAVE_ASPRINTF`, `OBJC_THREADING_PACKAGE`) are already right because `TARGET_OS_OSX` is 1. |
| 0002 objc-os.h Linux branch (12 KB) | **gone** | The whole point of that patch was to write a Linux sibling for a `#if TARGET_OS_MAC` block that ends in `#error unknown OS`. As Mach-O we take Apple's block. |
| 0003 isa 48-bit addresses | **survives, all 3 hunks** | See §2. Not about the file format at all. |
| 0004 asm named macro params (10 KB) | **gone** | `objc-msg-arm64.s` assembles **verbatim**. Apple's `.macro`/`$0`/`.endmacro` dialect is what clang's integrated assembler speaks for a Darwin target. `scripts/gen-elf-asm.py` is not needed and neither is its output. |
| 0005 ELF inline-asm dialect | **partly survives** | The dialect half is gone — `.cstring`, `.section __DATA,__const` and `l_` labels are native. The `_collecting_in_critical` half survives as patch 0004; see §3. |
| 0006 objc-os.mm Linux | **gone** | Mach-O image discovery is restored, not replaced. |
| 0007 preopt fallback completion | **survives** | A consequence of `SUPPORT_PREOPT 0`, not of the format. Apple never compiles that configuration, so two functions genuinely have no definition. |
| 0008 ELF symbol naming | **gone** | `__asm__("_objc_release")` is the *correct* spelling on Mach-O. It was only wrong on ELF. |
| 0009 BOOL is bool | **gone** | clang predefines `__OBJC_BOOL_IS_BOOL=1` for `arm64-apple-macos`. |
| `-D__arm64__=1 -D__arm64=1` (43 `#if` sites, incl. `cache_t` layout) | **gone** | `__arm64__` and `__arm64` are Apple predefines. For an Apple target clang defines them. |

Measured, first thing, inside the container:

```
$ clang -target arm64-apple-macos11 -isysroot /sdk/MacOSX.sdk -dM -E -x objective-c /dev/null
#define TARGET_OS_MAC 1
#define TARGET_OS_OSX 1
#define __OBJC_BOOL_IS_BOOL 1
#define __arm64 1
#define __arm64__ 1
```

Four of the nine were **the same bug**: Mach-O source compiled by a toolchain
that had been told it was building for Linux. Building for Darwin deletes them
without a line of thought.

### The four that remain

```
patches-macho/0001-wide-va-isa-layout.patch          isa.h, objc-object.h, objc-runtime-new.h
patches-macho/0002-no-shared-cache.patch             objc-config.h  (SUPPORT_PREOPT 0)
patches-macho/0003-preopt-fallback-completion.patch  objc-opt.mm    (2 missing definitions)
patches-macho/0004-no-restartable-ranges.patch       objc-config.h, objc-cache.mm
```

All four say the same kind of thing: *this is not a Mac*. None says *this is
not Mach-O*. That is the shape you want, because it is the irreducible set.

---

## 2. The one fact a Mach-O build cannot hide: the address space

This is where the experiment nearly ended, and it is worth stating precisely
because it is the only place the ELF port's work transferred *unchanged*.

objc4 packs the class pointer into the isa word. For `__arm64__` without
pointer authentication it uses a **33-bit `shiftcls`** field, and the comment in
`isa.h` says why: `/*MACH_VM_MAX_ADDRESS 0x1000000000*/`. That is embedded
Darwin's ceiling.

Measured in the test container:

```
text/data  0xaaaad2440014
malloc-48  0xaaaaff7b62a0
malloc-4M  0xffffb132f010
mmap       0xffffb191d000
widest significant bit: 48
fits ISA_MASK 0x0000000ffffffff8 (36-bit): 0
fits FAST_DATA_MASK 0x0f007ffffffffff8 ptr field (47-bit): 0
```

Neither mask holds a Linux/aarch64 pointer. The ELF port found this and widened
both (its `patches/0003`). The Mach-O build finds it too — and finds it *better*,
because objc4's own `STATIC_ASSERT` fires at compile time:

```
objc-runtime-new.mm:260: error: '_static_assert' declared as an array with a negative size
```

That assert is `(~ISA_MASK & OBJC_VM_MAX_ADDRESS) == 0 || ISA_MASK + sizeof(void*) == OBJC_VM_MAX_ADDRESS`,
with `OBJC_VM_MAX_ADDRESS` coming from the SDK's `MACH_VM_MAX_ADDRESS`
(`0x00007FFFFE000000`). It is *Apple's own check* catching us, which incidentally
tells you something: Apple ships macOS libobjc as **arm64e**, where
`__has_feature(ptrauth_calls)` selects the 52-bit `shiftcls_and_sig` field and
the assert passes. The plain-arm64 branch we are forced onto (machorun rejects
arm64e — PAC keys are process-scoped and Linux may not expose PAC at all) is the
one Apple only ships for embedded and the simulator.

So patch 0001 adds `|| OBJC_MACHORUN` to the same disjunction Apple already
wrote for the simulator, which has the same problem for the same reason. It is
not a hack; it is the case Apple's own conditional was designed to express.

**This is the honest cost of the Mach-O route being a Linux route.** It has
nothing to do with the file format, so no amount of Mach-O fidelity removes it.

---

## 3. Where the ELF port was right by accident

`HAVE_TASK_RESTARTABLE_RANGES` in `objc-config.h`:

```c
#if TARGET_OS_SIMULATOR || defined(__i386__) || defined(__arm__) || !TARGET_OS_MAC
#   define HAVE_TASK_RESTARTABLE_RANGES 0
```

On Linux, `!TARGET_OS_MAC` made this 0 for free and the ELF port never had to
think about it. Building as Mach-O turns `TARGET_OS_MAC` on and the accident
stops working:

```
objc[421]: task_restartable_ranges_register failed (result 0x2e: (os/kern) not supported)
```

Restartable ranges are an XNU service that rewinds a thread preempted inside
`objc_msgSend`'s cache scan, so freed buckets cannot be read after free. Linux's
`rseq(2)` is the semantic analogue but *aborts* rather than restarts. The
fallback path is `task_threads()` + `thread_get_state()` — real Mach IPC, which
machorun aborts on by design.

So patch 0004 takes the conservative branch — `_collecting_in_critical()`
returns TRUE, "a reader may be active, do not free" — which is **the same
choice, for the same reason, that `~/objc4-linux` made in its `patches/0005`**.
The cost is identical and is a leak: every method-cache reallocation leaks the
old bucket array. `~/objc4-linux` quantified it at ~8.7 KB per invalidation,
177 MB peak RSS on a swizzling workload that costs macOS 4.7 MB. That number
carries over unchanged.

The lesson generalises: **`TARGET_OS_LINUX` is not the same predicate as "this
kernel is not XNU"**, and the ELF port conflated them harmlessly. A Mach-O port
has to separate them, which is more thought but a more accurate model.

---

## 4. What replaced the patches: headers, not source changes

The public macOS SDK is not Apple's internal SDK. Of the 46 headers
`~/objc4-linux/compat/` had to write, **21 the public SDK already has** — the
real `<mach-o/loader.h>`, `<mach/mach.h>`, `<malloc/malloc.h>`,
`<TargetConditionals.h>` and so on, where the ELF port had hand-written stubs.

The 25 it does not have are in `vendor/objc4-priv/`, and they are almost all
genuinely Apple-internal (`*_private.h`) plus `<ptrauth.h>`, which is a *clang
resource* header Ubuntu's clang does not ship:

```
Block_private.h  CrashReporterClient.h  Rosetta/{Rosetta,Traps}.h
System/pthread_machdep.h  _simple.h  crt_externs.h  kern/restartable.h
mach-o/dyld_priv.h  malloc_private.h  malloc_type_private.h
objc-probes.h  objc-shared-cache.h  os/{bsd,feature_private,linker_set,
lock_private,reason_private,thread_self_restrict,variant_private}.h
ptrauth.h  sandbox/private.h  sys/reason.h
```

**These are not patches.** objc4's source is unchanged by them; they are the
part of Apple's build environment we do not have. That distinction matters for
the maintenance question: a header that only *declares* SPI is re-checked
against a new objc4 drop by compiling, and the compiler tells you. A patch
against source has to be re-applied by hand.

Two of them are worth calling out because they are where the ELF port's
assumptions had to be reversed rather than reused:

* `os/linker_set.h` — the ELF version emits `__start_objc_dupclass` /
  `__stop_objc_dupclass` and renames the section to a valid C identifier,
  because that is ELF's facility. The Mach-O version keeps Apple's section name
  `__DATA,__objc_dupclass` and uses ld64's `section$start$…` symbols. Same
  feature, opposite mechanism.
* `System/pthread_machdep.h` — the ELF version is an empty stub, because on
  Linux objc4 selects `Threading/pthreads.h`. As Mach-O it selects
  `Threading/darwin.h`, which uses Darwin's **direct TSD** (`_pthread_getspecific_direct`,
  reserved keys 40–49). Those are inlines reading `TPIDRRO_EL0` on a real Mac;
  here they are declarations, and `darwin/src/objcsupport.c` owns a real
  per-thread slot array behind one glibc key. That is one indirection more than
  Darwin and identical semantics.

`~/objc4-linux/compat/mach-o/dyld_priv.h` transferred **essentially unchanged**,
which is the single most reusable artefact in that project: it is Apple's
declarations, and they are the same declarations either way.

---

## 5. The loader side: restoring dyld's protocol, not inventing a seam

`docs/UNIMPLEMENTED.md` §`objc-callbacks` recommended a hybrid — an ELF-backed
dylib mechanism plus a new `objc4linux_register_foreign_image()` entry point in
the sibling project. **That recommendation is now withdrawn**, and it was based
on a correct observation with the wrong conclusion.

The observation: `~/objc4-linux` did not shim Mach-O image discovery, it
*replaced* it — `dl_iterate_phdr(3)`, on-disk ELF section headers, and a
synthetic per-image record whose first member is a fake `struct mach_header_64`
for objc4 to cast back to. The conclusion drawn was "rebuilding as Mach-O undoes
the port's central change, so it is the expensive path."

It is the *cheap* path, because the thing being undone was compensation for
running in the wrong format. `src/objc_notify.c` is 300 lines and implements
dyld's actual protocol:

1. Someone calls `_objc_init()`. On macOS that is **libSystem's initializer**,
   not a constructor in libobjc — verified against the dylib we build, which has
   neither `__mod_init_func` nor `__TEXT,__init_offsets`. `src/main.c` calls it
   at the same point.
2. `_objc_init()` calls `_dyld_objc_register_callbacks(&v4)`.
3. We call `mapped` for every already-loaded image carrying `__objc_imageinfo`,
   **synchronously inside the registration call**, as dyld does.
4. `mr_objc_note_image()` — the hook point `mr_run_initialisers` already had —
   calls `init` for an image immediately before its own initialisers. That is
   `load_images()`, and `+load` is dispatched from inside it.

`_dyld_lookup_section_info()` is the entire image-discovery seam, and this is
where the bet pays: it is a straight walk of load commands machorun already
parsed. Nothing is faked, because the images really are Mach-O.

### The two things that were not obvious

**`makeImageMutable` is a block.** `mapped`'s third argument is
`void (^)(uint32_t)`, and objc4 calls it to get write access to a
`__DATA_CONST` we have already `mprotect`ed read-only. Passing NULL is a
`SIGSEGV at ldr x8, [x21, #0x10]` — offset 0x10 of a block is its `invoke`
pointer. The loader is plain C, so `src/objc_notify.c` hand-builds a
`BLOCK_IS_GLOBAL` block to the Blocks ABI.

**`malloc_size` is not `malloc_usable_size`.** This one is sharp enough to be
worth remembering beyond this experiment. Darwin's `malloc_size(p)` returns
**0** for a pointer no malloc zone owns, and callers use it as an ownership
test. objc4 is such a caller — `objc-runtime-new.h`:

```c
static inline void try_free(const void *p)
{ if (p && malloc_size(p)) free((void *)p); }
```

That is how `free_class()` tells a `class_ro_t` the compiler emitted into
`__DATA_CONST` from one the runtime allocated. glibc's `malloc_usable_size`
does no validation whatsoever: it reads the chunk-header word before the
pointer and returns whatever is there, which for image data is a plausible
non-zero number. Result, measured:

```
023-dynamic-class: munmap_chunk(): invalid pointer
  #6 free()   #7 libobjc+0x166e4 = free_class(objc_class*)+0x1f8
```

`darwin/src/libsystem.c` now answers the ownership question itself, via
`mr_addr_in_image()`. This is not an objc4 special case — it is what the
documented Darwin behaviour *is*, and any guest using `malloc_size` as an
ownership test now gets it right.

---

## 6. Results

### `09_objc`

```
=== stdout diff (macOS baseline vs machorun/Linux)   IDENTICAL
=== stderr diff                                      IDENTICAL
=== exit status   macOS: 0   machorun: 0
```

The full fixture corpus is unregressed: **19 PASS**, 1 permanent XFAIL
(`01_exit_raw`, raw `svc`), 1 NO-ORACLE. `09_objc` moves from `xfail` to `pass`
in `tests/manifest.tsv`.

### The 44-test differential corpus — 41/44

Same sources, same committed macOS baselines, binaries compiled on macOS by
Apple's clang. All 44 were first verified to reproduce their baseline
**natively on macOS** (44/44), so a Linux-side mismatch cannot be a build
difference.

```
objc4 differential corpus under machorun: 41/44 PASS
```

Passing: root classes and metaclass chains, selector registration and uniquing,
dispatch and the method cache, `+load` and `+initialize` ordering, categories
including collision precedence, protocols, ivars and non-fragile layout,
properties, dynamic class creation **and disposal**, ARC entry points,
autorelease pools, weak references, associated objects, type encodings, method
resolution and forwarding, `@synchronized`, `super`/IMP, **multi-image
programs**, and **eight threads contending on all of it**.

The three failures, and what each actually is:

| test | cause | machorun entry |
|---|---|---|
| `038-exceptions` | `__cxa_allocate_exception` → needs an unwinder over `__TEXT,__unwind_info` | `unwind-compact` (pre-existing, ranked #2) |
| `044-exception-through-uncached` | same | same |
| `042-dlopen` | `dlopen` of a guest Mach-O at run time | `dlopen-dlsym` (pre-existing, ranked #3) |

**None is attributable to objc4, to the Mach-O build, or to the dyld seam.**
Both were already on `docs/STATUS.md`'s ranked blocker list before this work
started, and both block plain C++ just as much as they block Objective-C.

`025-internal-symbols` was a fourth failure until `dlsym(RTLD_DEFAULT, …)` was
implemented — 30 lines in `src/resolve.c`, since it is the flat search the
binder already does.

---

## 7. What this costs to maintain, versus the ELF port

The user's criterion is maintenance, so state it directly.

**Fewer things to keep true.** 4 patches instead of 9, and the four that remain
are all "this is not a Mac" rather than "this is not Mach-O". Deleted outright:
a Python Mach-O→ELF assembly translator (`gen-elf-asm.py`, 9.7 KB of patch plus
the script), a hand-written 223-line Linux OS block in `objc-os.h`, an ELF
reimplementation of `getSectionData`, an ELF image-discovery layer built on
`dl_iterate_phdr` and on-disk section headers, and a synthetic `mach_header_64`
that exists only so objc4 can cast it back.

**The reusable half of the ELF port survives.** `mach-o/dyld_priv.h` transfers
unchanged, and the whole differential corpus transfers unchanged — it is the
same 44 sources against the same baselines. That project's *measurement* work
is not wasted by retiring its *port* work.

**What gets harder.** Three things, honestly:

1. **A macOS SDK is now a build input.** `scripts/build_objc4.sh` needs
   `$SDK/usr/include` (18 MB from `MacOSX15.sdk`). The ELF port needed no
   Apple SDK at all — its `compat/` tree was self-contained. This is the single
   biggest new dependency and it is not redistributable, so the build is
   reproducible on a machine with Xcode and not otherwise. The script fails
   loudly when the SDK is absent rather than degrading.
2. **libobjc's surface lands on libSystem.** `nm -u libobjc.A.dylib` is 145
   symbols. `darwin/src/objcsupport.c` is ~600 lines of new Darwin userland:
   direct TSD, the recursive-lock SPI, malloc zones, a minimal Blocks runtime,
   `__chkstk_darwin`, BSD string/random functions, structured abort. The ELF
   port needed none of it — it got glibc's versions by being ELF. This is a
   real transfer of work from "patch objc4" to "grow libSystem", and it is only
   a win because libSystem is *ours*, has a differential test behind every
   translation, and was going to have to grow for anything beyond C anyway.
3. **The two remaining corpus failures are now on machorun's critical path.**
   Exceptions and `dlopen` were "someday" items; with objc4 in the picture they
   are the last 3 tests.

**Recommendation: retire the ELF port, keep the Mach-O one — but not yet.**

The Mach-O route is strictly better on the stated criterion: less patched
source, and the patches that remain are the ones nobody can delete. Retiring
`~/objc4-linux` should wait for two things, because 41/44 is not 44/44:

* an unwinder over `__TEXT,__unwind_info` (also unblocks C++ exceptions
  generally — this is not objc-specific work), and
* `dlopen` for guest images, which `mr_image_load` was already written
  re-entrant for.

Until then the honest position is that **the ELF port is still the only thing
that runs the whole corpus**, and it costs nothing to keep a working 44/44
sitting in a sibling directory while machorun closes two gaps it wanted closed
anyway.

---

## 8. What a Swift binary would additionally need

All-Mach-O is the route to `#selector` working on Linux, so: what is left after
this?

The compiler side is fine and was never the problem. `swiftc -target
arm64-apple-macos13 -enable-objc-interop` emits Apple objc4 metadata into
Mach-O sections this seam already reads — `__objc_classlist`, `__objc_selrefs`,
`__objc_imageinfo` — and `~/objc4-linux` measured that swiftc's *ELF* section
names agree too. That was the load-bearing bet and it holds.

What is missing, in the order it would bite:

1. **`libswiftCore.dylib` as a Mach-O on Linux.** This is the wall, and it is a
   much bigger one than objc4. The stdlib is not 90 translation units of C++
   against a header set; it needs a Swift runtime (metadata, generics,
   reflection, refcounting) and the Swift toolchain has to be persuaded to
   target `arm64-apple-macos` while linking against a libSystem that is not
   Apple's. `~/objc4-linux/docs/STATUS.md` §5 measured that the Linux-shipped
   `libswiftCore.so` contains **zero** ObjC class symbols and zero `objc_*`
   imports — an interop-enabled stdlib does not exist and has to be built.
2. **`swift_retain` / `swift_release` for real.** They resolve today, as loud
   aborts in `darwin/src/objcsupport.c`, and are reachable only for a class
   that `isSwiftStable()`. The moment a real Swift class exists they must be
   the stdlib's. Note Apple gets this reference through ld64's `-delay_init`,
   which `ld64.lld-18` does not implement — so on this toolchain it is a plain
   undefined symbol that something must define, and "something" has to become
   the real stdlib rather than our abort.
3. **`OBJC_CLASS_$__TtCs12_SwiftObject`.** Every interop-enabled Swift class
   roots here. It comes from the stdlib; there is nothing objc4 can do about it.
4. **C++/ObjC exceptions.** Swift's error handling does not unwind, but any
   Foundation-shaped code path does, and `038`/`044` already show that wall.
   The compact-unwind unwinder is on the critical path for Swift too.
5. **Foundation and CoreFoundation, whose *internals* match.** The caveat
   `~/objc4-linux`'s README states remains exactly true and is not improved by
   this experiment: Swift's bridging calls `_CFStringGetCStringPtr`,
   `__SwiftValue`, `_SwiftNativeNSArrayBase`. GNUstep provides those APIs with
   different internals. This is unsolved and its cost is still unknown.

The useful update is narrower than "Swift works": **the runtime half of Swift
ObjC interop is no longer the blocker.** Apple's objc4 now runs on Linux in
Apple's own format, with Apple's own dispatch assembly, driven through Apple's
own dyld protocol, and it agrees with the real runtime on 41 of 44 measured
behaviours. What remains is the standard library and Foundation — and those were
always the larger problem.

---

## 9. Inherited from the retired ELF port

**Status of `~/objc4-linux`, as of 2026-08-26: RETIRED, not deleted.** Its
README carries the notice and the reasons. It stays on disk because it is still
the only thing that runs the whole corpus — the three tests it passes and we do
not are `038-exceptions`, `044-exception-through-uncached` and `042-dlopen`,
i.e. `unwind-compact` and `dlopen-dlsym`. When those two land and
`scripts/objc44.sh` reads 44/44, that directory has no unique content left.

The rest of it is not deleted either, it is *here*. Three findings in its
`docs/PORT_MAP.md` and `docs/PORT_PLAN.md` are about objc4 and about Linux, not
about ELF, so they survived the change of format intact and would otherwise
have to be rediscovered. Recorded so that nobody does.

### 9.1 Which objc4 this is, and why the newest tree is the easiest to port

`~/objc4-linux/docs/PORT_MAP.md` §"Which objc4 is this" — the vendored tree
(shared verbatim; `vendor/objc4` here is the same drop) carries no version
string and is identified by feature markers: a `runtime/Threading/` package
with `OBJC_THREADING_{NONE,DARWIN,PTHREADS,C11THREADS}` back-ends,
`objc-malloc-instance.h`, `InitWrappers.h`, `_dyld_objc_callbacks_v4` with
`_objc_patch_root_of_class`, `_dyld_lookup_section_info`, `class_rx_t` pointer
signing, TPRO. That is **objc4-9xx, macOS 14/15 vintage** — several years newer
than the objc4-818.2 that every public "buildable objc4" fork is based on.

The counter-intuitive consequence, and the reason both ports were tractable:

> In this vintage objc4 **no longer parses Mach-O for its own metadata**. dyld
> pre-computes section locations and hands them over via
> `_dyld_lookup_section_info` — 17 call sites in `objc-opt.mm` and 4 more in
> `objc-runtime-new.mm`, all of them funnelling through that one function.
> Older objc4 called `getsectiondata()` and walked load commands inline at
> dozens of sites.

Apple's refactor for their own convenience is what makes the seam a seam.
**There is one function to reimplement, not thirty** — that is exactly why
`src/objc_notify.c` is 300 lines (§5). If a future drop is *older*, or if Apple
reverts that refactor, this cost estimate does not transfer.

### 9.2 The `+load` / static-initialiser ordering contract — resolved by being Mach-O

`~/objc4-linux/docs/PORT_PLAN.md` names this its **riskiest unknown**, and it
is worth reading because it is the clearest case of the Mach-O route removing a
problem rather than moving it.

The contract on Darwin: `libSystem` calls `_objc_init()` *before any library
initialiser runs*, dyld then calls `map_images` for a batch of images bottom-up
and `load_images` after. objc4 depends on that privileged position so hard that
it hand-rolls its own C++ static-constructor pass (`static_init()`, reading
`section$start$__TEXT$__init_offsets`) because it is running earlier than its
own initialisers. The comment at `objc-os.mm:712` says so.

On ELF there is no privileged position: `libobjc.so`'s constructor runs in
`.init_array` alongside everything else, ordered by the dynamic linker's
dependency sort, with `constructor(priority)` as the only lever — and
priorities only order *within* one image. The port could therefore not
guarantee that `+load` ran before any initialiser in an image that uses ObjC,
only before initialisers that happened to sort after its own; and its
`dl_iterate_phdr` scan could produce `map_images` sequences dyld never
produces, reaching paths only ever exercised by one WINE bug report
(`objc-os.mm:345`). Its assessment: a **semantics** risk, invisible at compile
time, surfacing as intermittent ordering-dependent failures in exactly the
programs that are hardest to reduce.

**Under machorun that risk is structural, not statistical, and it is closed.**
The privileged position exists again because we own the loader:
`src/main.c` calls `_objc_init()` at libSystem-initialiser time (verified: the
dylib we build has neither `__mod_init_func` nor `__TEXT,__init_offsets`, so
`_objc_init` genuinely is not a constructor), the whole already-loaded batch
gets `mapped` synchronously inside `_dyld_objc_register_callbacks`, and
`mr_objc_note_image()` calls `init` for an image immediately before that
image's own initialisers. `+load` therefore precedes every initialiser in its
image, by construction.

What is **not** closed is the ordering *across* images, and the honest bound is
`docs/STATUS.md` §3: the mutation "initialiser dependency order reversed"
**survived** — no fixture image has more than one dependency, so there is no
order to get wrong. `tests/objc44/041-multi-image` is the only multi-image
evidence and it is a two-image program. Do not read "the contract is restored"
as "the ordering is tested".

### 9.3 The packed-isa `shiftcls` versus Linux's VA width — still live

`~/objc4-linux/docs/PORT_PLAN.md` calls this its second-riskiest unknown and
states it exactly right:

> Darwin picks the isa bitfield layout from the known Mach VM ceiling. Linux
> aarch64 VA size is a kernel config (39/42/48/52-bit) and is *not* fixed
> across machines. Choose too small a `shiftcls` and a class allocated above
> the assumed ceiling corrupts every object pointing at it — silently, and only
> on some kernels.

§2 above is the Mach-O half of this story and reports the good news: objc4's
own `STATIC_ASSERT` catches the *too-small* case at compile time, so
`patches-macho/0001` had to be written before anything would build. That is a
compile-time gate on `ISA_MASK` versus the SDK's `MACH_VM_MAX_ADDRESS`.

**It is not a gate on the host kernel, and the ELF port's framing is the one
that stays true.** The masks we ship were chosen against a *measured* 48-bit
host (`0xffffb132f010`, bit 47 set):

| field | our value | pointer bits |
|---|---|---|
| `ISA_MASK` (`shiftcls_and_sig`) | `0x007ffffffffffff8` | 3..54 |
| `FAST_DATA_MASK` (`class_rw_t`) | `0x0f00fffffffffff8` | 3..47 |

`FAST_DATA_MASK` has **exactly** the 48 bits that were measured and no margin.
Nothing checks it at run time and nothing can check it at compile time, because
the ceiling it depends on is the kernel's, not the SDK's. See
`docs/UNIMPLEMENTED.md#isa-va-width` for the bound and what would have to
change. The ELF port's own recommendation — force `SUPPORT_NONPOINTER_ISA 0`
and revisit with measurement — was **not** taken here, deliberately: it costs
performance and changes `objc_debug_isa_class_mask`, which Swift reads.
