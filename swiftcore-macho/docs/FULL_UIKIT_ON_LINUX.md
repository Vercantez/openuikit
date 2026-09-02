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
# THE ~/machorun MOUNT IS NOT OPTIONAL -- see below.
docker run --rm -v ~/swift-macho-linux:/w -v ~/uikit:/uikit:ro \
    -v ~/machorun:/machorun:ro -w /w -e QUARTZ_REBUILD=1 \
    swift-macho-spike:noble bash full/scripts/build_full.sh

# render all 108 scenes, one process per scene
bash full/scripts/run_suite.sh                 # LOW_HEAP=1 for the measurement above

# macOS reference render of the SAME code, then the three-way scoreboard
swift build -c release --product openrender --scratch-path /tmp/ub   # in ~/uikit
OPENUIKIT_BACKEND=quartz /tmp/ub/release/openrender render /tmp/mac_out fixtures/scenes/*.json
python3 full/scripts/score.py ~/swift-macho-linux/build/full/suite /tmp/mac_out ~/uikit/golden
```

**`-v ~/machorun:/machorun:ro` was missing from this block, and following the
instructions as written produced a silent no-op** (found 2026-08-27). The guest
root is staged from `MACHORUN=/machorun`; without the mount that path does not
exist, so every `-nt` freshness test compares against a missing file and is
FALSE, and the loader copy *and* the `libSystem`/`libc++` umbrella rebuild are
both skipped — with no error and exit 0. The build then links against whatever
`scratch/mrroot_full` already contained, which is how a guest root ends up half
one machorun version and half another. `build_full.sh` now **refuses** when the
mount is absent rather than trusting the reader to have the right command line.
`QUARTZ_REBUILD=1` is likewise needed for a rebuild: `libquartz.dylib` is
otherwise only built when the file is missing.

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

## 7. The run loop — "renders a frame" becomes "runs"

The first of §6's three missing process-layer pieces. Built and verified;
launch-by-name and bundle are not done.

### OpenUIKit already had the seam

`UIWindow.tick(timestamp:)` says it in its own comment — *"there is no run
loop, so this tick IS the run-loop turn"* — and one call advances scroll
deceleration, navigation transitions (**which is what fires
`viewDidAppear`**), sheet settling, `UIView.animate` completions, caret blink,
scheduled `Timer`s and time-based gesture recognisers. None of that was
reimplemented. What was added is a host that feeds the seam **real** time
instead of a value set by hand.

### Built so CFRunLoop can drive it, not compete with it

On iOS, UIKit's main loop sits *on* CFRunLoop rather than replacing it, and
foundation-scope is building CFRunLoop's epoll path now. So the only two things
a host must supply — *what time is it* and *wait until* — sit behind a
`HostFrameSource` protocol. `MonotonicFrameSource` answers with
`clock_gettime(CLOCK_MONOTONIC)` and `nanosleep`. A CFRunLoop-backed source
would answer `wait` by blocking in `CFRunLoopRunInMode`; nothing else changes,
and the loop body stays one line: `tick`.

### Verified over wall time, with teeth on both sides (3/3 runs)

```
monotonic : fired=yes turns=30  animation-clock=0.500s  WALL=0.500s   PASS
synthetic : fired=yes turns=31  animation-clock=0.517s  WALL=0.000s   detected
both completed the animation; wall times differ by 15613x             PASS
viewDidAppear: before-loop=not fired  after=FIRED  animated=true
               turns=21  WALL=0.355s                                  PASS
```

**The negative control is not a strawman.** `SyntheticFrameSource` is precisely
what `openrender` does today: advance the clock by hand, never wait. The
animation *completes* under it — so a test that only asked "did the completion
handler fire" would pass while measuring nothing. Only elapsed real seconds
separate the two, and the wall clock is read **directly** rather than through
the frame source, so a source that lies about time cannot also fake the
measurement. 30 turns for 0.5 s is 60 Hz, the rate UIKit's display link runs at.

And `viewDidAppear` now fires **because the lifecycle reaches it**: a
`pushViewController(animated: true)` with nothing nudged afterwards, the
callback arriving mid-loop after 0.355 s of real time. `RealApp.swift` currently
works around its absence by calling `presentPickerNow()` by hand.

### Still open in §6

- **Launch by name.** `UIApplicationMain` takes a delegate *instance*; real iOS
  discovers it by name through the ObjC runtime, which we have.
- **Bundle.** No `NSBundle`, nothing reads `Info.plist`. This is the piece most
  likely to want Foundation — and per §6, a nearly-empty Foundation is worse
  than none, so if bundle mechanics genuinely need it, that is a finding and the
  work waits on the real thing rather than a fake one.

## 8. Launch by name — the delegate crosses as a string

Real UIKit never receives an app delegate object. `@main` on a
`UIApplicationDelegate` synthesises

```swift
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv,
                  nil, NSStringFromClass(AppDelegate.self))
```

so the delegate crosses the boundary as a **string**, and UIKit does
`NSClassFromString` → `[[cls alloc] init]` → install. OpenUIKit's entry point
took the instance (`UIApplicationMain(delegate: MyAppDelegate())`), which is
the gap §6 named as the second of the three process-layer pieces.

### Which runtime can answer, measured rather than assumed

objc4 was the obvious candidate — we have it, it is what UIKit uses, and the
binary really does carry an `__objc_classlist` (178 entries). But OpenUIKit's
classes are **not** NSObject subclasses and carry no `@objc`
(`Sources/OpenUIKit/UISelector.swift` states this as a design rule), so what
ObjC knows about them is decided by the Swift compiler's Darwin class emission,
not by intent. Asked directly in the guest:

```
objc4 : registered classes=270
        objc_getClass("_TtC9OpenUIKit6UIView")            = FOUND
        objc_getClass("_TtC11render_full16ProbeAppDelegate") = FOUND
```

**objc4 does know them.** That is a real capability and worth recording — the
`NSStringFromClass`/`NSClassFromString` round trip a real app performs would
resolve under machorun today.

It is still not what `UIApplicationMain` should use, for a reason that has
nothing to do with lookup: ObjC can only `alloc` these classes. `SwiftObject`'s
`+alloc` reaches `swift_allocObject` with the right size and then the Swift
initialiser body never runs, so every stored property holds whatever the
allocator left there. It would "work" on a delegate whose properties are all
`Optional` and be silently wrong on any other — the exact false-green shape this
project keeps finding. So discovery goes through the Swift runtime's own
`__swift5_types` records.

### The gap that measuring found

`_typeByName` accepts two spellings and rejects the one that matters:

```
name form : raw=yes  resolved=yes   mangled          "11render_full16ProbeAppDelegateC"
name form : raw=yes  resolved=yes   qualified source "render_full.ProbeAppDelegate"
name form : raw=no   resolved=yes   NSStringFromClass "_TtC11render_full16ProbeAppDelegate"
name form : raw=no   resolved=no    bare class name  "ProbeAppDelegate"
```

The `_TtC` form — *the* form a real `@main` supplies — does not resolve.
`swiftMangling(fromObjCClassName:)` re-spells it; both manglings carry the same
length-prefixed components, so this is a re-spelling and not a guess, and
anything more elaborate than module + class returns nil rather than a wrong
answer.

### Discovery and instantiation are separate problems

Only the second is short, and it is where the missing NSObject actually bites.
`UIApplicationDelegate` refines `NSObjectProtocol` in real UIKit, so a
conforming class necessarily **has** an `init`; a Swift metatype offers no way
to call an initialiser that no protocol requires. Two words in `~/uikit` close
it for unmodified app source:

1. `UIResponder.init()` becomes `public required init() {}`
2. `UIApplicationDelegate` gains `init()`

after which `class AppDelegate: UIResponder, UIApplicationDelegate { var window: UIWindow? }`
— a subclass adding only defaulted stored properties — **inherits** the required
initialiser and satisfies the requirement with no app-side syntax at all. It is
spelled locally as `InstantiableAppDelegate` only because `~/uikit` is read-only
in this tree; the mechanism is identical either way.

### Result, 3/3 runs

```
launch  : delegate=ProbeAppDelegate  didFinishLaunching=yes  init-ran=yes   PASS
run     : root appeared at launch=yes  pushed-before-loop=not fired  after=FIRED
run     : turns=22  wall=0.357s  applicationState=active                    PASS
control : unknown class name                     -> rejected                PASS
control : non-delegate class (name resolves=yes) -> rejected at conformance PASS
control : nil delegate name                      -> rejected                PASS
```

The delegate is named **only as a string** on the launch path, in the
`NSStringFromClass` spelling. `init-ran` is a sentinel set by `init()` and
nothing else, because the interesting wrong answer (`alloc` without `init`)
produces an object of the right class with an uninitialised body. The
non-delegate control separates "the name did not resolve" from "the conformance
was not checked" — both must fail, and for different reasons.

**This test's own first bug is worth recording.** The `run` assertion originally
watched the window's *root* controller, which appears at `makeKeyAndVisible`
with no animation — so it had already fired before any loop ran, and the loop
proved nothing. It now pushes a controller `animated: true` after launch, which
can only complete on the clock, and requires `wall > 0.05 s`.

### An unrelated break, found because everything stopped loading

`render_full` stopped loading entirely — every mode, including the 108-scene
suite — with

```
machorun: undefined symbol '_$ss042_stdlib_isOSVersionAtLeastOrVariantVersion...'
```

Attribution, from the emitted assembly rather than from guessing:
`swift_task_deinitOnExecutorMainActorBackDeploy`, the back-deployment thunk the
compiler generates for a **`@MainActor`-isolated deinit**. `~/uikit`'s M15
commits put the UI classes under `-default-isolation MainActor`, which gives
them isolated deinits — so a build that had been loading for weeks stopped
loading with no change on this side.

Three details make this worth a section:

- **The sysroot does not warn you.** `libswiftCore.tbd` *advertises* the symbol,
  so the link is clean and the failure is deferred to load time in the guest.
  Same `.tbd`-disagrees-with-dylib class as `pthread_main_np`, inverted: there
  the `.tbd` advertised too little, here too much.
- **`nm` says the symbol is not there and `grep` says it is** — chained-fixup
  imports do not appear in `nm` output. The attribution above came from
  `-S` assembly, after `llvm-objdump` produced no disassembly at all and a
  per-file bisect with its errors suppressed produced a confident empty answer.
- **Only the question was missing, not the answer.** The thunk asks "is the OS
  new enough to have `swift_task_deinitOnExecutor`?" and that function *is*
  present (`libswift_Concurrency.dylib` exports it).

`full/shims/swiftcorepatch.c` forwards the six-argument form to the
three-argument `_stdlib_isOSVersionAtLeast` that libswiftCore already exports,
which is what Apple's own implementation does off macCatalyst — the "variant"
triple describes the iOS-on-macOS variant of a zippered binary, and nothing here
is zippered. It is linked **into the executable** rather than into a
libswiftCore umbrella: `llvm-install-name-tool` cannot rewrite Apple's
libswiftCore at all (it carries `LC_SEGMENT_SPLIT_INFO`, cmd `0x1e`), so the
rename that pattern needs is unavailable for that one library. An object file
outranks a `.tbd`, so the linker resolves it locally and emits no import.

Expect this file to grow: swiftc here is 6.2.x and the staged runtime is an
older Apple build, so anything the newer compiler emits a direct call to may be
missing.

**CORRECTED 2026-08-27 — this is not general version skew, it is the price of
running Apple's binary.** machorun's OWN libswiftCore (9.9 MB, zero reexports,
real code) exports **both** forms natively — the 6-argument one at `0x1d4774`
and the 3-argument one at `0x28890`. Apple's staged *simulator* libswiftCore
exports only the 3-argument form. So the shim is needed **specifically because
this build stages Apple's shipped runtime**, which is the entire point of the
§9 result; our own source-built runtime would never have hit it. A load failure
on that symbol therefore means *a different libswiftCore is staged*, not that
the toolchain drifted.

**And a second copy of this shim was found shadowing a symbol that exists.**
`spike/swiftcorepatch.c` hardcoded `return 1` for **both** entry points —
including the 3-argument one both runtimes implement — and its header said it
was built into an umbrella that reexports the real library. A definition in an
umbrella silently beats the reexport (§9). It was never staged (verified: zero
reexports in `scratch/mrroot`, no `libswiftCor.dylib` sibling, and this build's
own failure on the missing 6-arg symbol proves no umbrella was in place), but
`build_swiftcore_umbrella.sh` writes into the very directory `build_full.sh`
copies the guest root from — so running it would have put `return 1` over a
working implementation underneath the 108-scene suite. Deleted, with the
umbrella script pointed at the single shared implementation.

## 9. The 46-scene wall was ours, and the scoreboard that hid it

Re-running the 108-scene suite as a regression gate for §8 scored **59 ok / 47
crashed / 2 hung**. Three wrong explanations were eliminated before the right
one, and the order is the lesson.

**It was not the availability shim.** Forcing `swiftcorepatch.c` to answer
`false` — the back-deploy fallback, isolated deinit run inline — left 15/15
still crashing.

**It was not launch-by-name.** Removing both new driver files from the binary
left 15/15 still crashing.

Both of those arms were run against a **broken baseline**, so both conclusions
were right and neither was earned.

**The guest root was two machorun versions at once.** `build_full.sh` rebuilds
the libSystem/libc++ umbrellas from machorun's *current* dylib on every run —
deliberately — but staged the **loader** only when the root directory did not
exist. The staged loader was an hour older than the dylibs wrapped around it.
The first symptom was not an error: it was a plausible-looking scoreboard.
Only later did the mismatch turn loud, the newer libSystem wanting
`_mr_report_backtrace` from a loader too old to export it. **The loud failure
is what made the quiet one findable.**

**And the actual bug was in this repo.** machorun's `0f39750` names it:
`spike/syspatch.c` defined `malloc_type_zone_malloc_with_options_internal` with
FOUR parameters. It takes FIVE, and `size` is the THIRD
(`malloc/malloc.h:192`), so the argument forwarded to `malloc` as the size was
the **alignment**:

```
_malloc_type_zone_malloc_with_options_internal:
    mov x0, x1
    b   _malloc
```

Every allocation through that entry point got a block the size of its own
alignment — sixteen bytes, whatever was asked for — and the caller wrote its
whole object over the neighbours. That was the entirety of the "46 UIKit scenes
fail with nondeterministic memory corruption" wall: 22 glibc heap aborts, 19
SIGSEGVs on wild addresses, 9 silent failures, no two alike, because a heap
overflow of arbitrary size onto arbitrary neighbours never fails the same way
twice. Only Apple's *shipped* libswiftCore reaches that entry point — ours
calls plain `malloc` — which is why it read as a property of the runtime.

The family is now **deleted** here rather than corrected here. The umbrella
reexports machorun's libSystem, machorun defines all fourteen correctly, and a
definition in the umbrella **shadows** the reexport — so a fixed copy here
would be a second implementation that silently wins, and re-adding one later
would reinstate the bug rather than collide with the fix. Verified by symbol
count: the built umbrella exports zero `malloc_type` symbols.

`spike/syspatch.c` and `spike/cxxpatch.cpp` were also missing from the
umbrella's rebuild guard, so editing either changed nothing until the root was
wiped by hand — a fix present in source and absent from the artifact under
measurement.

### Restored, and measured three ways

Suite: `rendered_ok=108 crashed=0 hung=0`, one process per scene, current
loader, coherent root. Decoded RGBA, never PNG bytes:

| comparison | identical |
|---|---|
| **A) Linux/machorun vs macOS-native** — isolates this stack | **162 / 162** |
| B) macOS-native vs real-UIKit golden — OpenUIKit's own fidelity | 12 / 162 |
| C) Linux/machorun vs real-UIKit golden — headline | 12 / 162 |

**B and C are identical, frame for frame and delta for delta.** Every
difference from the golden is OpenUIKit's own fidelity against real UIKit,
contributed equally on macOS and on Linux; the Mach-O/machorun stack
contributes **zero**. Arm A is the number that belongs to this project, and it
is exact.

The macOS-native reference had to be rebuilt to say any of this — no such
render survived on disk, and without it only arm C is available, which cannot
tell "our stack is wrong" from "OpenUIKit approximates UIKit here".

## 10. Bundle — and it does not need Foundation

The third and last piece of the process layer. §6 named it as the one most
likely to need Foundation, with the standing instruction that if it genuinely
did, it should say so plainly and wait on #47/#51 rather than get a fake.

**It does not.** Foundation's `PropertyListSerialization` is the real API, but
reading `Info.plist` needs a *parser*, and a parser is self-contained — whereas
the Foundation module's mere **visibility** flips 33 `canImport` guards in
OpenUIKit onto a path this sysroot cannot satisfy (§9's guard now enforces
that). There is precedent in OpenUIKit for exactly this trade: `NotificationCenter`
is its own portable type that deliberately shadows Foundation's, with the
tradeoff written up in that file.

### Scope is the measured one, not the specification

Every `Info.plist` in reach is XML — the six `.app` fixtures in
`~/uikit/Tools/oracle2`, plus macOS's own Calculator.app and Safari.app as a
sanity check. So the reader covers the element set those files actually use:
`dict`, `key`, `string`, `array`, `integer`, `real`, `true`/`false`, `data`,
self-closing forms, the five entities, comments and the DOCTYPE.

**Binary plists are a NAMED GAP, not an assumed-away one.** Shipped iOS apps
ship `bplist00`, there is no fixture here, and a reader that returned an empty
dictionary for one would make an app look *misconfigured* rather than
*unsupported*. So the parser detects the magic first and reports the format.

### Two layouts, both real, both from fixtures that predate the code

```
iOS (flat)   Foo.app/Foo              Foo.app/Info.plist       Foo.app/<res>
macOS        Foo.app/Contents/MacOS/Foo   .../Contents/Info.plist  .../Contents/Resources/<res>
```

`SheetProbe.app` is flat, `Oracle2.app` has `Contents/`. Both are oracle
fixtures built for an unrelated purpose, so neither was shaped to fit this code.
Discovery is pure string work on the executable path — no directory probing, so
it cannot be fooled by a missing-file answer.

### The faithful API is absent, and the obvious substitute is wrong

`_NSGetExecutablePath` — what real UIKit uses — is **not** among machorun's
libSystem exports (the same grep finds `getprogname`, `readlink`, `getcwd`).
And `/proc/self/exe` is not merely unavailable, it is **incorrect**: the ELF
process is the *loader*, so that link names machorun rather than the guest
Mach-O mapped inside it. Reaching for it would have produced a confident wrong
answer. So the path comes from `argv[0]` resolved against `getcwd`, and
`Bundle.main` reports *how* it was found.

### Verified by running the same binary from two places

```
/w/build/full/Probe.app/probe -> argv[0] -> …/Probe.app/probe
                                 id=com.openuikit.bundleprobe  layout=flat
                                 resource resolved THROUGH the bundle   PASS
./Probe.app/probe             -> same, resolved via getcwd              PASS
./render_full                 -> Bundle.main nil, "not inside a .app"   PASS
```

That the *same binary* answers differently from the two locations is what makes
this a property of the environment rather than of the code. **nil is the correct
answer for an unbundled executable** — a Bundle that answered anyway by falling
back to a search path is the exact failure this piece exists to remove.

Parser teeth on both sides: a binary plist named as unsupported, a `<key>` with
no value rejected, **and** a positive control (entities, comment, DOCTYPE,
nested array) parsed correctly — without which "rejects everything" would score
full marks.

### One incident worth keeping

`String.contains(_:)` has a `RegexComponent` overload that lives in
`_StringProcessing`. Using it made the guest demand
`libswift_StringProcessing.dylib` **at load time** and the binary stopped
running entirely — this build disables that module by design. Splitting on `/`
asks the same question with the stdlib alone. A stdlib method that looks
free can drag in a dylib, and the failure lands at load rather than at compile.

### Regression

`rendered_ok=108 crashed=0 hung=0`; arm A 162/162 identical to macOS-native, and
162/162 identical to the pre-bundle Linux run. The process layer is complete:
**bundle, launch, run loop.**

## 11. The model layer — measured, and it is bigger than the UI layer

Everything proven so far is the **presentation half**. `~/uikit/docs/APP_COMPAT.md`
established that real apps touch a small UIKit vocabulary and that OpenUIKit
covers ~75% of it. That census cannot say anything about the other half, and
the reason is structural rather than an oversight:

```python
SYMBOL_RE = re.compile(r'\b((?:UI|NS|CA)[A-Z][A-Za-z0-9_]*)\b')
```

filtered against UIKit's SDK headers. `URLSession`, `JSONDecoder`, `Date`,
`Data`, `FileManager`, `Codable`, `UserDefaults` match none of that. **The
model layer was invisible to the instrument, not absent from the apps.**

Same corpus, same weighting, Foundation's alphabet
(`~/swift-macho-linux/full/census/`):

| | |
|---|---|
| corpus | eidolon, DuckDuckGo iOS, ios-oss, pocket-casts-ios — 5,257 Swift files |
| **model-layer references** | **18,024** |
| UIKit references (existing census) | 10,162 |
| files importing Foundation | **1,762** |
| files importing UIKit | 1,282 |

**The model layer is roughly 1.8× the UI layer by symbol count, and Foundation
is imported by more files than UIKit.** The half we have not started is the
larger half.

### By family

| family | uses | share |
|---|---|---|
| files (`URL`, `FileManager`, `Bundle`) | 3,525 | 19.6% |
| collections (`Data`, `NSNumber`, `UUID`, `Error`) | 2,887 | 16.0% |
| dates (`Date`, `Calendar`, `DateFormatter`) | 2,636 | 14.6% |
| concurrency (`DispatchQueue`, `Task`, `Timer`, `RunLoop`) | 1,827 | 10.1% |
| notification (`NotificationCenter`) | 1,750 | 9.7% |
| persistence (`UserDefaults`, `NSCoding`, Core Data) | 1,716 | 9.5% |
| json/coding (`Codable`, `JSONDecoder`) | 1,435 | 8.0% |
| text/format (`Locale`, `NSAttributedString`, formatters) | 1,148 | 6.4% |
| networking (`URLSession`, `URLRequest`) | 814 | 4.5% |

### Against what exists today

Foundation-macho currently emits **20 ObjC classes**: `NSURL` plus 19
`__NSCF*` CoreFoundation bridge classes.

> **CORRECTION 2026-08-27 — "emits" is weaker than it reads, and my wording
> caused a wrong inference downstream.** Those 20 names were harvested from
> **seven object files**; `ns-classes.txt` says so itself ("a name here means
> the compiler emitted `_OBJC_CLASS_$_<name>` as a DEFINED symbol"). At the
> time of writing **foundation-macho builds no dylib at all**, and CF waits on
> libdispatch, which waits on 29 libSystem symbols. So the middle row below is
> *compiled objects*, not loadable plumbing — and a task brief reasonably read
> my sentence as "the plumbing already exists" and ranked the bucket as
> cheapest-first on that basis. **A true statement whose natural reading
> overstates readiness is the same failure as a number that lies**, and it is
> the one shape I had not caught in my own output.

| status | uses | share |
|---|---|---|
| have, or in flight (#45 `_Concurrency`, #47 libdispatch/CFRunLoop, OpenUIKit's own `NotificationCenter`, `Bundle` from #56) | 5,635 | 31.3% |
| **a CF bridge class exists, the Swift-facing API does not** | 7,511 | 41.7% |
| nothing at all | 4,878 | 27.1% |

**The middle row is the interesting one.** `URL` alone is 2,844 uses and
`NSURL` is emitted — but Swift's `URL` struct and its API are a different
artifact from the ObjC class. Most of that 41.7% is plumbing without a surface,
which is a different kind of work from the 27.1% that has nothing at all.

Biggest single items with nothing behind them: `UserDefaults` (1,186),
`FileManager` (333), `URLRequest` (317), `UUID` (307), and the whole `Codable`
family (`Decodable` 294, `CodingKeys` 292, `Decoder` 253, `Codable` 141,
`JSONDecoder` 113).

### Two things outside Foundation entirely

`SwiftUI` is imported by **993 files across 3 of the 4 apps**, and `Combine` by
260 across 3. Neither is Foundation and neither exists here in any form. The
UIKit/Foundation framing of "what a real app needs" does not cover them, and
nothing in this project currently plans to.

### Honest imprecision

Identifier matching cannot tell `Foundation.Data` from an app's own `Data`. The
NS*-prefixed names are unambiguous; the curated Swift names are common words
and over-count somewhat, so families and rankings are solid while individual
counts are order-of-magnitude.

**A wider alphabet was tried and rejected on measurement.** Scraping
Foundation's `.swiftinterface` for public type names swept in `Message`,
`Category`, `Field`, `Language`, `Currency`, `Style` — which matched
*app-defined* types and inflated "nothing at all" by ~2,900 uses. It looked
like a more thorough census and was a less accurate one. Corpus is HEAD
shallow clones, so counts drift slightly from the 2026-08-25 census (eidolon
159 = 159 exactly; pocket-casts-ios 1,826 vs 1,690).

## 12. SwiftUI + Combine — scoping a first-class target, and one refusal

The user made SwiftUI and Combine first-class targets. This is the scope, with
no implementation attached.

### What this instrument cannot match — stated before it was run

The model-layer census worked because Foundation's alphabet is mostly
`NS*`-prefixed and unambiguous. **SwiftUI's is not**, and the failure mode here
would be worse than a wrong number: it would be a confident one.

- **The type names collide badly.** `Text`, `Image`, `List`, `Group`,
  `Section`, `Path`, `Alignment`, `State`, `Binding`, `Environment`, `Color`,
  `Font`, `Shape` — every one is a plausible app-defined type. §11 already
  proved this shape when scraping `.swiftinterface` swept in `Message`,
  `Category`, `Currency` and inflated a gap by ~2,900 uses of *app* code.
  SwiftUI is that hazard concentrated.
- **Most of the API is not type names at all.** It is modifiers — method calls
  on opaque types — and apps define their own freely. **Measured, not assumed:**
  the first non-test SwiftUI view in the corpus (pocket-casts `MainTabView.swift`)
  contains exactly one modifier call, `.trackScrollOffset()`, and it is
  **app-defined**. A modifier census would have scored it as SwiftUI surface.
- **The rest is syntax**: `some View`, result builders, the implicit
  `@ViewBuilder` on `body`. Not identifiers, not countable.

**So no SwiftUI "API use count" is produced.** Measuring the model layer with
the wrong alphabet under-reported it; measuring SwiftUI with this one would
over-report it. Same error, opposite sign.

### What IS unambiguous, and what it says

Only the `@`-prefixed attributes, the `: View` / `some View` syntax, and a few
Combine names nobody reuses:

| app | files | imports SwiftUI | declares a View | View types | imports Combine |
|---|---|---|---|---|---|
| eidolon | 159 | 0 | 0 | 0 | 0 |
| DuckDuckGo iOS | 1,202 | 265 | 177 | 232 | 115 |
| ios-oss | 2,070 | 113 | 60 | 67 | 38 |
| pocket-casts-ios | 1,826 | 615 | 424 | 423 | 107 |
| **total** | 5,257 | **993** | **661** | **722** | **260** |

**This corrects my own earlier figure.** I reported "993 files import SwiftUI".
Only **661 actually declare a View**, and 32 of the imports are in test files.
993 was adoption-flavoured and wrong; 661 view-bearing files with 722 View types
is the real shape. `eidolon` has *zero* — it is a 2014-era pure-UIKit app, so
this is 3 of 4, and the split is generational rather than stylistic.

Structure: 2,099 `some View`, 862 `body` declarations, 81 custom `ViewModifier`
types, 397 previews. State plumbing, all unambiguous: `@State` 563,
`@Published` 544, `@ViewBuilder` 536, `@Environment` 301, `@EnvironmentObject`
250, `@ObservedObject` 189, `@Binding` 109, `@StateObject` 84. Combine:
`ObservableObject` 195, `AnyCancellable` 175, `AnyPublisher` 171.

**A third framework showed up unasked:** `@Observable` (39) and `@Bindable` (8)
are the **Observation** framework, not SwiftUI and not Combine — and it is
macro-based, so it is a compile-time expansion problem rather than a runtime
one. It has no `.swiftinterface` at the expected SDK path, so it is unsized here.

### Size, by the project's own counting method

Counting a framework's OWN declared types is legitimate — the rejected use was
*matching* those names against app source. Different question, different hazard.

| framework | public types |
|---|---|
| **UIKit** | **737** (530 classes + 208 protocols) |
| SwiftUI | 794 (672 structs, 78 protocols) |
| SwiftUICore | 556 |
| Combine | 123 |

The UIKit figure reproduces `APP_COMPAT.md`'s 737 exactly, which is the control
that makes the comparison legitimate rather than two numbers from two methods.

**The target is ~1,473 types against UIKit's 737 — about 2×.** (Exported-symbol
counts say 8×, but that comparison is meaningless: UIKit is ObjC and its methods
live in ObjC metadata rather than the export table, while every Swift generic
specialization is a symbol. Types are the comparable unit.)

### The number that made UIKit tractable does not exist for SwiftUI

`APP_COMPAT.md`'s decisive finding was not 737. It was that **apps reference
only ~171 distinct UIKit types**, which is why the punch list was finite. The
equivalent number for SwiftUI is exactly what the collisions above make
unmeasurable by text. **Getting it requires a semantic index** — building the
corpus and reading the compiler's index store, or swift-syntax with type
resolution — not a regex. Until then, "how much of SwiftUI do apps actually
use" is *unknown*, and it is the single number that would most change the
estimate.

### The oracle — and this is the part with no precedent

Every prior port had a reference: libdispatch, libc++, CoreFoundation and objc4
are open source. UIKit was not, and was solved by **oracle harvesting**: render
on real UIKit, capture PNG plus layout JSON, diff pixels with tolerance and
structural gates. SwiftUI has no source either, so the same question arises —
and it splits into three layers, only two of which are already solved.

1. **Rendered pixels.** Transfers *directly*. A SwiftUI view hosted in a
   `UIHostingController` on Mac Catalyst renders to pixels like anything else,
   and `Tools/oracle2` already does exactly this. No new invention.
2. **Resulting view tree and geometry.** Also transfers — a hosted SwiftUI view
   produces a real UIKit hierarchy with frames, dumpable as the existing layout
   JSON already is.
3. **Update semantics — when `body` re-runs, what is invalidated, whether
   `@State` identity survives a re-render.** Not visible in a frame or a tree.
   This is `AttributeGraph`'s behaviour: a **private** framework
   (`/System/Library/PrivateFrameworks`, 576 exported symbols, a `.tbd` in the
   SDK but no headers), referenced 913 times across SwiftUICore's exports.

Layer 3 is *measurable* — instrument `body` with a counter, drive a scripted
sequence of state mutations, record `(view identity → evaluation)` in order.
The project already has an oracle of exactly this kind: `openrender scrolltrace`
captures a time series rather than a picture. So the oracle *form* exists; the
harness does not.

**But here is the finding, and it is a "we don't know yet" rather than a gap.**
For UIKit, the observable output *was* the contract — a pixel is a promise. For
SwiftUI, the pixels are a contract and **the incremental re-evaluation
behaviour is not**. Apple does not specify when or how often `body` runs; it is
an implementation detail that moves between OS releases. So an evaluation-trace
oracle would be pinning *unspecified* behaviour, and a reimplementation that
matched it would be matching an implementation detail rather than a contract.

The consequence is concrete and uncomfortable: **a naive implementation that
re-evaluates every `body` on every change would pass a pixel oracle and a tree
oracle completely, and be unusably slow on a real app — and no oracle we know
how to build would catch it.** SwiftUI's entire value is the incremental
update, and that is the one property we currently have no way to validate
against the real thing. That question should be answered before anyone commits
to an implementation strategy, because it decides whether "correct" is even
definable here.
