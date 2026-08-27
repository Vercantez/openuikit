# The full OpenUIKit module, built as Mach-O on Linux and scored

**Date:** 2026-08-26. **Question:** the vendored render *slice* rendered one
scene pixel-identically ([ISA_MASK_VERDICT.md](ISA_MASK_VERDICT.md)). Does the
**whole** module build and run, and how much of the 108-scene golden suite does
it actually render?

**Answer: 108 of 108. Three consecutive full runs, zero crashes, zero hangs,
zero flippers; all 162 frames byte-identical to the same code running natively
on macOS in every run; 108/108 passing the project's own gate.**

That is with the SOURCE-BUILT Swift runtime. With Apple's staged
iOS-simulator `libswiftCore` the same binaries manage only 51–65 depending on
the run, with nondeterministic memory corruption — so **the Swift runtime, not
the loader and not OpenUIKit, was the discriminator.** Both numbers are below,
because the difference between them is the finding.

The 4 remaining failures are a single named category: a crash in `libquartz`'s
gradient shading. `OPENUIKIT_BACKEND=swift` renders all four, which localises it
to the quartz path rather than to the runtime or the loader.

## 1. The build — no vendoring, no VENDOR-EDITs

`~/uikit` is bind-mounted **read-only** and compiled in place, so there is no
vendored copy to drift and no per-file provenance to track:

| target | files | source |
|---|---|---|
| `OpenCoreGraphics` | 9 | `~/uikit`, verbatim |
| `OpenUIKit` | 91 (incl. `AutoLayout/`) | `~/uikit`, verbatim |
| `CQuartz` | 37 C++ TUs | `~/uikit`, verbatim |
| `CPortableIO`, `CSTBTrueType` | 2 C TUs | `~/uikit`, verbatim |
| scene builder | 1 (76 KB) | `~/uikit/Sources/openrender/SceneBuilder.swift`, verbatim |

Exactly **two** files are not `~/uikit`'s, and both are replacements for
Foundation-facing code rather than reimplementations of UIKit:

- **`full/shims/FoundationNames.swift`** — `IndexPath`, `NSRange`,
  `NSRangePointer`, `NSMakeRange`, `TimeInterval`. Not invented: lifted
  **verbatim from OpenUIKit's own git history** (`ec1d318^`), which is where
  they lived until M15 replaced them with typealiases to Foundation's.
  `Sources/OpenUIKit/FoundationTypes.swift` is entirely inside
  `#if canImport(Foundation)`, and the staged Darwin sysroot has no
  `Foundation.swiftmodule`, so that file compiles to nothing and these names
  are simply undefined. Every *other* Foundation-conditional site in the
  library already has a working `#else` branch. M15's own commit message says
  why this is a hole and not a dependency: they "were declared by OpenUIKit
  only because the library imported no Foundation."

- **`full/driver/main.swift`** — replaces `Sources/openrender/main.swift` and
  `SceneIO.swift`, the only two files in that target that touch Foundation
  ("All Foundation use is isolated here", per `SceneIO.swift`'s own header).
  Each Foundation call becomes a facility OpenUIKit already ships:
  `Data(contentsOf:)`→`ResourceIO.readFile`, `Data.write(to:)`→`cpio_write_file`,
  `FileHandle.standardError`→`cpio_log_stderr`, `ProcessInfo…environment`→
  `cpio_getenv`, `JSONSerialization`→`JSONValue.parse` (OpenUIKit's MiniJSON).

Two build-side findings worth keeping:

- **machorun's staged `libquartz` is too old.** It is an earlier sync of
  `~/quartz` and does not export the straight-alpha codec entry points
  (`QZImageDecodeRGBA`, `QZImageFreeRGBA`, `QZImageEncodePNG`,
  `QZImageEncodeJPEG`) that `Sources/OpenUIKit/ImageCodec.swift` calls. The
  build compiles `libquartz` from `~/uikit`'s own `Sources/CQuartz` with
  machorun's exact flags, so header and implementation stay in step.
- **The `CQuartz` module name needed no source edit.** The slice had a
  `VENDOR-EDIT` changing `import CQuartz` to `import Quartz` because machorun's
  SDK names the module differently. Dropping machorun's quartz headers from a
  private sysroot copy and letting `~/uikit`'s own
  `Sources/CQuartz/include/module.modulemap` supply the module removes that
  edit entirely.

## 2. `@MainActor` is real, and it cost 22 symbols

OpenUIKit's UI classes carry `@MainActor` the way real UIKit's do, so the
module must be compiled with `_Concurrency` and the guest must load
`libswift_Concurrency.dylib`. That dylib imports 458 symbols; 436 already exist
in machorun's userland. The missing 22 — measured with `nm`, not guessed — are
in `full/shims/concpatch.c` (20, libSystem-owned) and `full/shims/conccxx.cpp`
(2, libc++-owned).

**Which library each symbol comes from is not a choice.** These images use
two-level namespace binding, so an import names its defining library and a
definition anywhere else is invisible. `dyld_info -fixups` gives the mapping;
putting `__cxa_pure_virtual` in libSystem produced exactly the error that says
so — *"looked in: libc++.1.dylib"*.

Following the house rule, the dispatch/voucher/signpost entry points are **loud
aborts**: a renderer that runs one scene synchronously never enqueues onto a
queue, and if that assumption is ever wrong it must say so rather than quietly
producing a different picture. None of them fired. The genuinely trivial ones
(`memset_s`, `qos_class_self`, `clock_getres`, typed `operator new`) are real
implementations.

One more gap surfaced and answered itself: the Swift runtime calls
`dlopen("…/CoreFoundation", RTLD_NOLOAD)`. machorun's `dlopen` is a deliberate
loud bail, which killed the process. `RTLD_NOLOAD` asks *"is this already
loaded?"* — so **NULL is the correct answer**, not a stub. That is the only
behavioural change in the shim, and it is a truthful one.

## 3. The scoreboard

Reporting one "N/108 identical" number would be misleading: a frame can differ
from the real-UIKit golden either because OpenUIKit is not bit-exact against
UIKit, or because this stack disagrees with the same code natively. Those have
different owners, so `full/scripts/score.py` measures them separately.

### Scenes — 108/108, after the std::__sort fix (machorun 5f28325)

```
run 1 / run 2 / run 3                        108 / 108 / 108
ALWAYS PASS                                  108      the capability floor
ALWAYS FAIL                                    0
FLIPPED                                        0      address sensitivity GONE

A) Linux/machorun vs macOS-native      162 / 162 frames byte-identical, each run
   silent-corruption sweep             486 frames across 3 runs, 0 differing
B) macOS-native   vs real-UIKit golden  12 / 162 pixel-identical
C) Linux/machorun vs real-UIKit golden  12 / 162 pixel-identical   (B == C)

Tools/compare/compare.py                108 / 108 scenes pass
```

Zero flippers is the result worth stating separately: the earlier 51-65 band had
14 scenes that were not reproducible either way, and that address sensitivity is
now entirely absent rather than merely reduced. B == C still holds exactly, so
every remaining deviation from the real-UIKit golden is inherited from
OpenUIKit-on-macOS and none is introduced by the Mach-O path.

The 486-frame sweep matters because of what it caught last time: one frame in
322 previously rendered *successfully and wrong*. Zero now, across three runs.

### Scenes — the earlier 104/108, with the source-built runtime

```
total scenes                                        108
render                                              104   (158 PNG frames)
fail                                                  4   gradient_basic / _dark /
                                                          _in_stack / _multi, all
                                                          deterministic, all in
                                                          libquartz shading

A) Linux/machorun vs macOS-native OpenUIKit    158 / 158  BYTE-IDENTICAL
Tools/compare/compare.py                       104 / 104  scenes pass
```

Every frame that renders is byte-identical to the same code built and run
natively on macOS, and every scene that renders passes the project's own gate.
No silently-wrong frame in this configuration — the one recorded below happened
under Apple's runtime.

### Scenes — with Apple's staged runtime, three full runs

A single 108-scene pass cannot be quoted as a measurement here: the failures are
address-dependent, so the suite was run three times end to end.

```
run 1                                                59 / 108
run 2                                                55 / 108
run 3                                                58 / 108

ALWAYS PASS (rendered in all three)                  51    <- the capability floor
ALWAYS FAIL (failed in all three)                    43    <- the wall
FLIPPED     (passed in some, failed in others)       14    <- residual address sensitivity
union that rendered at least once                    65    <- the ceiling
```

**Fourteen scenes — 13 % of the suite — are not reproducible either way.** So the
honest statement is a band, 51 to 65, not a point. Quoting any single run's
number would have been quoting a die roll: the three runs differ by 4, and
`label_sizes` alone reads ok / FAIL / ok.

Flippers, since these are the informative rows: `alert_dark`, `button_basic`,
`button_dark`, `collection_dark`, `demo_settings`, `hit_testing`, `label_align`,
`label_multiline`, `label_sizes`, `label_truncate`, `modal_sheet`,
`modal_sheet_grabber`, `navbar_inline`, `textfield_basic`.

### Fidelity of what did render

```
A) Linux/machorun vs macOS-native OpenUIKit    321 / 322 frames byte-identical
                                                 1 frame RENDERED BUT WRONG
B) macOS-native   vs real-UIKit golden          12 / 109 pixel-identical
C) Linux/machorun vs real-UIKit golden          12 / 109 pixel-identical

Tools/compare/compare.py -- the PROJECT'S OWN gate (tolerances + structural
blob/geometry checks + layout.json):
   macOS-native render     56 / 56 scenes pass
   Linux/machorun render   56 / 56 scenes pass
```

**A is the number that measures this stack.** B and C being equal is the proof
that every deviation from the real-UIKit golden is inherited from
OpenUIKit-on-macOS and none is introduced by compiling to Mach-O on Linux. The
bare "12/109 pixel-identical" is glyph-rasterisation residue the project already
tolerates by design; it is quoted because it is the strictest possible reading.

### The corruption is NOT fail-stop — a rendered frame can be wrong

One frame in 322, `collection_dark` in run 1, **rendered successfully and
differed from the macOS render by 6,957 pixels at up to 97 per channel**. The
same scene was byte-identical in run 3 and crashed on four consecutive fresh
attempts afterwards. One scene, three outcomes: crash, correct, silently wrong.

This is the single most important caveat on the whole scoreboard. **"Rendered ok"
is not a pass.** A count of exit-zero scenes would have reported that run as
59/108 with no hint that one of the 59 was garbage. Only diffing every frame
against a native render catches it, which is what comparison A is for and why it
reads 321/322 rather than 322/322. Any future gate over this stack must diff
pixels, not check exit codes.

## 4. What blocks the rest — and a harness bug that cost an evening

### The mask that fires is FAST_DATA_MASK, not the isa mask

The dominant failure is `libswiftCore+0x2dce0`, inside
`_swift_initClassMetadataImpl`, faulting on addresses shaped `0x2aaa_xxxx_xxxx`
— `0xaaaa_xxxx_xxxx` with bit 47 cleared. The truncating instruction and the
load that feeds it are:

```
2dc84   ldr  x8, [x28, #0x20]              ; objc_class + 0x20 == class_data_bits_t
2dc88   and  x19, x8, #0x7ffffffffff8      ; FAST_DATA_MASK, not ISA_MASK
...
2dce0   ldr  w10, [x19, #0x4]              ; <-- SIGSEGV
```

Offset `+0x20` is `class_data_bits_t`, so the 47-bit constant here is
**FAST_DATA_MASK / DEBUG_DATA_MASK**, yielding `class_rw_t*` — which objc4
**mallocs**. Same 47-bit ceiling as [ISA_MASK_VERDICT.md](ISA_MASK_VERDICT.md),
different field, different allocation. This is worth stating precisely because
it rules out the tempting fix: widening those sites in Apple's runtime would
corrupt `class_rw_t` decoding rather than repair anything. machorun's
`patches-macho/0001` header says the same thing.

### It was already fixed upstream; the harness was stale

machorun master has both halves: `9659e73` *"loader: link low, because the heap
is the other half of the isa mask"* (with `mr_constrain_heap()` in `src/map.c`:
two `mallopt` calls plus a probe that **verifies** rather than trusts), and
`b497429` *"objc4: run Apple's stock class_rw_t masks, now that the heap fits
under them"*.

The guest root used for the first suite run had been staged **before** those
landed, so it faithfully reproduced a bug that had been fixed hours earlier.
That is a harness defect, not a finding. `build_full.sh` now stages the loader,
libobjc and both umbrellas from a read-only bind mount of `~/machorun` on
**every** run, so the staleness cannot recur — and the two umbrellas were
collapsed into one layer each (`spike/syspatch.c` + `full/shims/concpatch.c`
over machorun's current `libSystem`), because stacking a new umbrella on a
copied old one is exactly how the stale layer survived.

### A measurement that was invalid, recorded as invalid

`RLIMIT_STACK=unlimited` was used as a cheap proxy for "put the heap below
2^47", on the theory that it flips Linux to the legacy bottom-up mmap layout.
**It does not move the heap.** Checked directly:

```
default          [heap] aaab02458000-aaab02479000
--ulimit stack=-1 [heap] aaab104bf000-aaab104e0000
```

`brk` follows the PIE, which aarch64 Linux places at `0xaaaa…` regardless of
the stack rlimit; the flag changes `mmap` placement only. The 108-scene A/B run
on it (49 vs 49, one scene swapped each way) therefore measured nothing and is
discarded. The single scene that appeared to improve in an earlier spot check
was ASLR luck — these faults depend on whether the truncated address happens to
be mapped, so they are **flaky run to run**, which is itself worth knowing when
reading any single result.

### Two hypotheses, one eliminated by measurement

**Eliminated: the `malloc_size` ownership hole.** `darwin/src/libsystem.c:480`
answers Darwin's "is this pointer mine?" contract with `if (mr_addr_in_image(p))
return 0; else return glibc_malloc_usable_size(p)`, which validates nothing
outside mapped guest images — and `munmap_chunk(): invalid pointer`, the exact
message that comment says it fixed for objc4's `try_free`, reappears in the
suite. So a `free()` probe was built into the libSystem umbrella, logging any
free whose chunk header is implausible or whose pointer lies inside an image.
Run against `tabbar_basic`, a deterministic repro: **no suspect frees at all**
before the abort. The ownership test is not the cause.

**Not the shim's own DATA blobs either.** `concpatch.c` defines
`_dispatch_main_q` and `_dispatch_source_type_timer` as 256-byte guesses at
opaque Darwin structs we have no header for — precisely the reasoning that
produces opaque-pointer ABI bugs. Rebuilt at 65536 bytes, 256× larger, and five
failing scenes failed identically. Ruled out before handing anyone a substrate
hypothesis.

**Remaining: a write past an allocation.** The abort distribution is dominated by
glibc metadata damage (`smallbin double linked list corrupted`, `unaligned tcache
chunk detected`, `corrupted size vs. prev_size`, `malloc(): mismatching next`)
rather than by bad frees, and a silently-wrong rendered frame is what an
overwrite of live data looks like when it happens to miss the allocator's
bookkeeping. That is the opaque-pointer ABI class machorun's
`docs/UNIMPLEMENTED.md` catalogues. The obvious suspects are *not* it: our
libSystem forwards no `setjmp`/`longjmp`, no `sem_*`, no `glob`/`regex`, no
locale or `iconv`, and no `opendir`/`readdir`. `fopen` is the only opaque-type
forward on the render path, and `FILE*` crosses as a pointer. So it is a type not
yet enumerated.

### Two machorun defects found while hunting, neither of them the corruption

**1. `malloc_size` returns 0 for mmap-backed allocations.** A/B with the same
probe binary and loader, only `libSystem` differing:

```
pre-a8aafaf   (ownership by elimination)            0 of 10 misreported
post-a8aafaf  (ownership established positively)    4 of 10 misreported
```

Every misreport is an allocation at or above glibc's 32 MiB mmap threshold:
those live outside `brk`, `mr_addr_in_glibc_heap` answers "not ours", and
`malloc_size` returns 0 for memory `malloc` just handed back. `a8aafaf`'s own
comment predicts this case; what it does not say is that it has a live consumer.
objc4's `try_free` is `if (p && malloc_size(p)) free(p)`, so a block of 32 MiB
or more is now **never freed** — a leak rather than corruption, which is the
safe direction, but silent. Anything using `malloc_size` to *size* a buffer
rather than to test ownership gets 0 instead of the length.

**2. Allocations past the mmap threshold land ABOVE 2^47.** From the same run:

```
req=  32505856   ptr=0x10032e02180    below 2^47, brk
req=  33554432   ptr=0xffffbbe7f010   ABOVE 2^47, mmap
req= 268435456   ptr=0xffffade7f010   ABOVE 2^47, mmap
```

`mr_constrain_heap()` constrains `brk` and verifies `brk`. Allocations past the
threshold are not `brk`, so they sit back above the isa/data-mask ceiling the
entire heap fix exists to stay under. Nothing on the render path allocates
32 MiB in one block today, so this is not the corruption hunted here — it is a
hole in the guarantee, and it becomes someone's bug the first time a guest
allocates a large buffer and objc4 or libswiftCore masks a pointer into it.

### The bucket array is zeroed, not freed

`MALLOC_PERTURB_` discriminates the two, and it is worth knowing which: glibc
fills freed memory with the perturb byte, so a freed block reads `0xa5a5…` under
`MALLOC_PERTURB_=165`. objc4's corrupted DenseMap buckets still read
`0x0 0x0 0x0 0x0`. **The array was never freed.** It is memory that reads as
zeros where `EmptyKey` should be — which is what a never-initialised allocation
looks like, or one whose initialising write went somewhere else.

### The threshold, and what it points at

Regenerating the reproducer at varying instantiation counts against Apple's
runtime gives a sharp boundary:

```
N=4    pass          N=160   os_unfair_lock_unlock bail
N=16   pass          N=192   same
N=64   pass          N=256   same
N=128  pass          N=900   objc4 "Hash table corrupted"
```

It is therefore **not** a structural disagreement between the runtime and
objc4 — that would fail at N=1. It is a threshold, and it sits where
libswiftCore's static 64 KiB `InitialAllocationPool` is exhausted and the
metadata allocator falls through to `swift_slowAlloc` → `malloc`. 128
instantiations × 2 metadata records each is the right order for 64 KiB.

Two further readings narrow it:

**The lock word is not corrupted.** A wrapper recording every value ever seen
in a lock word at unlock saw exactly one unlock, holding `0x00000001` — a valid
first-thread token. So `os_unfair_lock_unlock: this thread does not own the
lock` is an **unbalanced unlock**, not memory damage. Worth stating plainly,
because those failures read as corruption and are not.

**With the check bypassed, a metadata pointer of 1.** The guest then dies at
the first instruction of
`TargetMetadata<InProcess>::isCanonicalStaticallySpecializedGenericMetadata()`,
`ldr x8, [x0]`, with `this == 0x1`. `MetadataResponse` is a two-field struct
(`Metadata*`, `MetadataState`) returned in x0/x1, and small integers are what
the state field holds.

**The faulting value is the `type` ARGUMENT, and 1 is a valid state.** Traced
through the disassembly rather than guessed:

```
_swift_checkMetadataState:                    ; (MetadataRequest x0, const Metadata *type x1)
  34a7c   mov x8, x1        ; x8   = type
  34a80   str x0, [sp,#8]   ; spill the request
  34a84   add x1, sp, #8
  34a88   mov x0, x8        ; x0   = type
  34a8c   bl  performOnMetadataCache<MetadataResponse>(...)
performOnMetadataCache:
  34ab4   mov x20, x0       ; x20  = type
  34ab8   bl  isCanonicalStaticallySpecializedGenericMetadata()   ; faults, x0 == 1
```

So `type == 1`. Swift's `MetadataState` values are `Complete` 0x00,
`NonTransitiveComplete` **0x01**, `LayoutComplete` 0x3F, `Abstract` 0xFF — so 1
is not garbage that happens to be small, it is *exactly what the state half of a
`MetadataResponse` holds*. A `MetadataResponse` is `{Metadata*, MetadataState}`
returned in x0/x1, and here the **state has ended up in the pointer slot** and
flowed into `swift_checkMetadataState` as `type`.

`swift_checkMetadataState` itself is **byte-identical in both runtimes** (same
instruction sequence, ours at 0x2f9378), and the guest binary is the same in
both tests — only the runtime dylib changes. So the difference is in what the
runtime *returns*, not in how the guest calls it.

**Hypothesis, not result:** past the pool, the metadata allocator's malloc path
yields metadata the runtime mis-reads. It would explain the threshold, the
pointer of 1, and why the source-built runtime — a different build of that same
allocator — is unaffected, and it demotes the objc4 DenseMap damage at N=900 to
a downstream symptom.

**Image-initialiser ordering is eliminated.** A documented untested risk
(`UNIMPLEMENTED.md#objc-load-ordering`) and a plausible fit for a table that is
used before it is constructed. Measured: under machorun, `libobjc.A.dylib` is
objc-processed before `libswiftCore.dylib` runs its initialiser, **identically
for both runtimes**. No inversion. The threshold predicted this independently —
an ordering bug would fail at N=1.

### What remains, and what it is not

With the guest root staged from live `~/machorun`, the `0x2dce0`
FAST_DATA_MASK crash disappears completely — it accounted for 42 of the 59
failures before. What replaces it is a **different and unrelated** class of
failure: nondeterministic heap corruption (see the taxonomy in §3), spread
across many detection points and many code addresses. That is the next wall,
and it belongs to the runtime substrate rather than to OpenUIKit.

An earlier attempt to move the heap by hand — a bump allocator over a 64 GiB
arena in a second libSystem umbrella — **failed, and is kept as failed**:
overriding `malloc` in the umbrella while machorun's `libSystem.real` keeps
calling glibc's internally puts two allocators on one heap, and glibc aborts
with *"malloc(): corrupted top size"*. `full/shims/lowheap.c` retains that
result in its header so the next person does not repeat it.

## 5. Reproducing

```sh
# build: ~/uikit read-only, everything else in ~/swift-macho-linux
docker run --rm -v ~/swift-macho-linux:/w -v ~/uikit:/uikit:ro -w /w \
    swift-macho-spike:noble bash full/scripts/build_full.sh

# render all 108 scenes, one process per scene
bash full/scripts/run_suite.sh                 # LOW_HEAP=1 for the measurement above

# macOS reference render of the SAME code, then the three-way scoreboard
swift build -c release --product openrender --scratch-path /tmp/ub   # in ~/uikit
OPENUIKIT_BACKEND=quartz /tmp/ub/release/openrender render /tmp/mac_out fixtures/scenes/*.json
python3 full/scripts/score.py ~/swift-macho-linux/build/full/suite /tmp/mac_out ~/uikit/golden
```

Fonts: `run_suite.sh` copies `SFNS*.ttf` from the host macOS into
`scratch/fonts` and passes `OPENUIKIT_FONT_DIR`, exactly as `~/uikit`'s own
`scripts/linux_verify.sh` does — Apple's fonts are not redistributable, and
without them glyphs missing from the harvested ink table do not draw at all.

---

## 6. From 108 scenes to a real app — a measured inventory

A scene renders one frame from a description. An app has a lifecycle. This
section is what was measured by taking `~/uikit`'s existing real-app harness —
**unmodified source files from a shipping iOS app** (Automattic/pocket-casts) —
and building and running them as Mach-O under machorun.

### The headline: it renders, pixel-identical

```
realapp_history_light.png    IDENTICAL   (1,339,344 px)
realapp_settings_light.png   IDENTICAL
realapp_settings_dark.png    IDENTICAL
```

Linux/machorun against the macOS-native render of the same source. The lifecycle
that produced them is the real one: `UIScreen._hostConfigure`, a `UIWindow`, a
`rootViewController`, `makeKeyAndVisible`, a modal presentation with
`animated: true`, and the animation clock advanced past the 0.4 s transition.

### Foundation: one name, and a cliff

The sharpest result, because it is counter-intuitive both ways.

**The app source itself needs exactly ONE Foundation name: `NSCoder`** — for the
`required init?(coder:)` UIKit forces on every `UIView` subclass, which the app
never calls. `OptionAction.swift` even writes `import Foundation` and uses
*nothing* from it; with no Foundation module present, that vestigial line is the
only error in the entire target.

**But a module named `Foundation` cannot be small.** Its mere existence flips
OpenUIKit's 33 `#if canImport(Foundation)` guards *and* OpenCoreGraphics', which
then demand Foundation's own `IndexPath`, `NSRange`, `NSRangePointer`,
`TimeInterval`, `CGFloat`, `CGPoint`, `CGSize`, `CGRect`. A nearly-empty
Foundation is **worse than none** — it switches the library onto a path it
cannot satisfy.

So the options are: no Foundation module (library freestanding, app's one import
unsatisfied), or a real one. Nothing in between. The measurement here used a
Foundation containing only `NSCoder` on an **app-only include path**, invisible
to the library — which is not a trick but the real configuration: the library
builds freestanding, the app builds against Foundation.

### Present and exercised

| | |
|---|---|
| `UIApplication`, `UIApplicationMain(delegate:launchOptions:)` | present |
| `UIApplicationDelegate` | present |
| `UIScreen` / `UIWindow` / `rootViewController` / `makeKeyAndVisible` | present, exercised |
| modal presentation + transition animation | present, exercised |
| `UIWindow.tick(timestamp:)` — the frame driver | present |
| `UIEvent` / `sendEvent` — event plumbing | present |
| resource loading | present, but a **search path** (`imageSearchPaths`), not a bundle |

### Absent — measured, zero occurrences in `Sources/OpenUIKit`

- **`NSBundle` / `Bundle`** — no bundle machinery of any kind.
- **`Info.plist`** — nothing reads one.
- **`principalClassName` / `delegateClassName`** — `UIApplicationMain` takes a
  delegate *instance*, so there is no ObjC-runtime discovery of the app delegate
  by name. A real iOS binary is launched by name from its Info.plist.
- **A run loop.** `RealApp.swift` says so in its own comment: *"openrender has no
  run loop, so `viewDidAppear` never fires on its own"*, and it advances
  `OpenUIKitRuntime.animationTime` by hand. Frames are driven, not awaited.

### One machorun gap found on the way

`pthread_main_np` is needed by the app path and never by the render path. The
link fails with *undefined symbol*, and the obvious reading — machorun lacks it —
is **wrong**: `spike/syspatch.c:285` provides it and the libSystem umbrella
exports it at `0xcbc`. What is missing is the SDK `.tbd` **advertising** it, so a
guest cannot link a symbol the dylib genuinely has. The mirror image of the stale
`swift_*` `.tbd` entries, which promised symbols the dylib no longer had. Fix is
one line in machorun's sdk generation; worked around here by linking the umbrella
directly.

### Honest unknowns — not measured, do not assume

- **A real app's model layer.** The vendored slice is UI-only. Networking, JSON,
  dates, file IO and persistence are where a real app would actually exercise
  Foundation, and none of that was touched. This is the largest unknown.
- **Event delivery end to end.** `UIEvent`/`sendEvent` exist and were never
  driven under machorun; the interactive path is the SDL host, which was not
  built here.
- **Time-driven animation.** The clock was set by hand. A real run loop
  advancing frames over wall time was never exercised.
- **Exceptions.** Everything is built `-fno-exceptions` and machorun has no
  compact-unwind unwinder; a real app that throws is untested territory.
