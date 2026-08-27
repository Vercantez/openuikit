# The full OpenUIKit module, built as Mach-O on Linux and scored

**Date:** 2026-08-26. **Question:** the vendored render *slice* rendered one
scene pixel-identically ([ISA_MASK_VERDICT.md](ISA_MASK_VERDICT.md)). Does the
**whole** module build and run, and how much of the 108-scene golden suite does
it actually render?

**Answer: the whole module builds; 62 of 108 scenes render; every one of the
110 frames is byte-identical to the same code running natively on macOS, and
all 56 first-attempt scenes pass the project's own gate.** What stops the
remaining 46 is memory corruption in the runtime substrate — not missing UIKit,
not fonts, not `_Concurrency`.

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

### Scenes

```
total scenes in fixtures/scenes                     108
rendered on the first attempt                        56   (110 PNG frames)
rendered within 2 retries                           +6    -> 62 / 108
fail persistently (3 attempts each)                  46
```

The retry column is not padding, it is the finding: **the failures are
nondeterministic**. One scene run five times produced "corrupted double-linked
list", a SIGSEGV at `0x10024000000`, "corrupted double-linked list", a SIGSEGV
at `0x10102464c45df`, and "free(): invalid pointer" — five runs, four distinct
failures. Any single-run number is a sample, so both are quoted.

### Fidelity of what did render

```
A) Linux/machorun vs macOS-native OpenUIKit    110 / 110  BYTE-IDENTICAL
B) macOS-native   vs real-UIKit golden          12 / 110  pixel-identical
C) Linux/machorun vs real-UIKit golden          12 / 110  pixel-identical

Tools/compare/compare.py -- the PROJECT'S OWN gate (tolerances + structural
blob/geometry checks + layout.json):
   macOS-native render     56 / 56 scenes pass
   Linux/machorun render   56 / 56 scenes pass
```

**A is the number that measures this stack, and it is perfect.** B and C being
equal is the proof: every deviation from the real-UIKit golden is inherited
from OpenUIKit-on-macOS, and *none* is introduced by compiling to Mach-O on
Linux and running under machorun. The bare "12/110 pixel-identical" is
glyph-rasterisation residue the project already tolerates by design — quoted
because it is the strictest possible reading, not because it is a defect here.

### The 46 that do not render

Categorised from the first-attempt run, by what the process actually said:

| signature | scenes |
|---|---|
| glibc heap-corruption abort (`double free or corruption`, `corrupted double-linked list`, `free(): invalid size`, `malloc_consolidate(): invalid chunk size`, `_int_malloc` assertion) | 22 |
| SIGSEGV on a wild address (`0xffeea114fffecb2e`, `0x10102464c45df`, …) | 19 |
| `os_unfair_lock_unlock: this thread does not own the lock` (objc4 lock state corrupted) | 2 |
| no diagnostic line — flaky, rendered when re-run alone | 9 |

Every one of these is **memory corruption**, detected at different points. Not
one is a missing UIKit capability, a missing font, or a `_Concurrency` gap:
`label_basic` and `label_dark` render text and pass the gate, and the
dispatch/voucher stubs never fired. The persistent 46 cluster on the
chrome-heavy scenes — `attrtext_*`, `button_*`, `collection_*`, `navbar_*`,
`navitem_*`, `tabbar_*`, `tableview_*`, `toolbar_*`, `control_*`,
`constraints_*`, `gradient_*` — i.e. the scenes that build the largest object
graphs, which is what a corruption bug would be expected to hit first.



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
