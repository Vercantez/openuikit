# The full OpenUIKit module, built as Mach-O on Linux and scored

**Date:** 2026-08-26. **Question:** the vendored render *slice* rendered one
scene pixel-identically ([ISA_MASK_VERDICT.md](ISA_MASK_VERDICT.md)). Does the
**whole** module build and run, and how much of the 108-scene golden suite does
it actually render?

**Answer: the whole module builds, and every frame it renders is byte-identical
to the same code running natively on macOS.** What stops the rest is one
runtime bug, not missing UIKit.

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

<!-- SCOREBOARD -->

## 4. What blocks the rest — one bug, and it is not UIKit

Of the scenes that do not render, the overwhelming majority die at the **same
instruction**: `libswiftCore+0x2dce0`, inside `_swift_initClassMetadataImpl`,
on a fault address of the form `0x2aaa_xxxx_xxxx`.

That address shape is the whole diagnosis. `0x2aaa…` is `0xaaaa…` with **bit 47
cleared** — a glibc `brk`-heap pointer truncated by Apple's 47-bit isa mask.
Verified arithmetically: the faulting instruction is `ldr w10, [x19, #0x4]`, and
`(0xaaaaf544387c | 1<<47) & 0x7ffffffffff8` is exactly the `x19` that faulted.

So this is the **heap half** of the isa-mask problem. `ISA_MASK_VERDICT.md` §5
recorded that the predicted glibc-heap residual "did not materialise" — that was
true for the slice and is **wrong for the full module**. The slice instantiated
few classes at runtime; the full module instantiates many, and runtime class
metadata is `malloc`'d. machorun's `fix/map-below-isa-mask` arena places
**images** below 2^47 and cannot move the C heap.

**Correction recorded rather than quietly fixed**, because it changes the
roadmap: the guest-malloc-arena work is not optional polish, it is what unblocks
the rest of the suite.

### The measurement that pins it, and one that failed

`RLIMIT_STACK=unlimited` flips Linux to the legacy bottom-up mmap layout
process-wide, which puts the PIE — and therefore `brk` and the whole C heap —
near `0x5555…`, **below 2^47**. Running the suite that way is a measurement, not
a fix (machorun's own commit rejects the same trick for image placement, and the
reasons carry over: it is a property of how the process was invoked, it lapses
across a re-exec, and it moves every unrelated allocation).

An attempt to do better — a bump allocator over an arena at 64 GiB, in a second
libSystem umbrella — **failed, and is recorded as failed**: overriding `malloc`
in the umbrella while machorun's `libSystem.real` keeps calling glibc's
internally means two allocators share one heap, and glibc aborts with
*"malloc(): corrupted top size"*. The interception has to happen inside
machorun's own libSystem, which is where the guest-arena work already lives.
`full/shims/lowheap.c` is kept for the next person with that result in its
header.

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
