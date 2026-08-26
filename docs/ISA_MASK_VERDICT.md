# The isa-mask verdict — measured, and a rendered UIKit scene

**Date:** 2026-08-26. **Question:** releasing a class-bound protocol existential
SIGSEGVs inside our self-built `libswiftCore`. Is the bug in OUR core-only
build, in machorun's loader, or in the ABI between them?

**Answer: machorun's loader, and it is already fixed.** With the loader fix and
our STOCK, UNPATCHED `libswiftCore`, the OpenUIKit render slice renders
`boxes_basic` **pixel-identical to real UIKit output**.

```
golden  ~/uikit/golden/boxes_basic.png                     640x480 RGBA  (real UIKit)
linux   ~/swift-macho-linux/build/slice/boxes_linux.png    640x480 RGBA  (Linux-built Mach-O, machorun)
-> decoded both to raw RGBA and compared: IDENTICAL, all 1,228,800 bytes. 3/3 runs.
```

That is real OpenUIKit source, compiled to `arm64-apple-macos` Mach-O **on
Linux**, linked against a Swift standard library **cross-built on Linux**,
executed by machorun on Linux/arm64, agreeing with Apple's UIKit to the pixel.

## 1. The measurement

Same `png_probe` binary in every cell. No `ulimit -s unlimited` anywhere — that
workaround masks the bug and would have produced a false pass.

| `libswiftCore` | narrow-mask sites | machorun master | machorun `fix/map-below-isa-mask` |
|---|---|---|---|
| ours, stock (`ff9ff833`) | 48 | **SIGSEGV** at `swift_getObjectType` | **all 9 cases pass** |
| ours, wide-mask (`dcea65ab`) | 0 | all 9 pass | all 9 pass |
| Apple's staged iOS-sim (`d6603da9`) | 9 | **SIGSEGV** at `swift_initClassMetadataImpl` | all 9 pass |

Every passing cell matches the native-macOS oracle value for value:
`plainclass=5 existential=3 arrayslice=200 string=11 anyobject=7
anyexistential=13 userarrayslice=33 genericclass=25 unowned=18`.

The two fixes are **independently sufficient, not complementary**. The loader
fix is the more general one: it also fixes Apple's runtime, which patching our
dylib cannot.

## 2. The mechanism

`libswiftCore` does not call a function to strip an isa's flag bits; the mask is
compiled in. Ours targets **arm64-apple-macos**, whose objc4 `ISA_MASK` is
`0x00007ffffffffff8` — 47 bits. aarch64 Linux serves `mmap(NULL, …)` top-down
from near 2^48, so machorun mapped every dylib at `0xffff…`, and the mask
silently cleared bit 47:

```
_swift_getObjectType:
  331ea8   ldr  x8, [x19]                 ; load the isa
  331eac   and  x0, x8, #0x7ffffffffff8   ; Apple's 47-bit mask
  331eb0   cbz  x0, …
  331eb4   ldrb w8, [x0, #0x20]           ; <-- SIGSEGV
```

Observed: pc `0xffff8659deb4`, fault `0x7fff875881d8`. The fault address is the
bit-47-stripped truncation of a real class in a dylib — `0xffffa86f20a0 &
0x7ffffffffff8 == 0x7fffa86f20a0`. Classes in the *executable* survived by luck,
because `MH_EXECUTE` lands at `0x100000000`, already below the ceiling.

## 3. Three corrections to the record

**(a) The faulting function was never `swift_unknownObjectRelease`.** It is
`swift_getObjectType` (`libswiftCore` `0x331e84`–`0x331f18`, fault at
`0x331eb4`). In `p_existential` the crash happens at the `bl
_swift_getObjectType` twelve instructions *before* the `bl
_swift_unknownObjectRelease` — the release never runs. At `-Onone`, existential
*construction* calls `swift_getObjectType`. The trigger is any isa-decoding
site, not the release path specifically.

**(b) It never faulted "on a stack address."** `0x7fff…` looks like a stack
pointer and is not: it is a truncated image pointer. That misread sent the
original diagnosis toward refcounting.

**(c) `ArraySlice`, `unowned` and existential release were one bug, and the
owner was machorun.** `docs/UIKIT_SLICE.md` §4 guessed "one root cause, several
faces" correctly but attributed it to our stdlib build. Our build is fine.

## 4. Two previously-unexplained walls were also this bug

Apple's staged iOS-simulator `libswiftCore` carries the **wide** iOS mask
(`0x007ffffffffffff8`, bits 3–54) at 48 sites, which tolerates a `0xffff…`
address. Its 9 residual **narrow** sites are all inside
`_swift_initClassMetadataImpl` / `_swift_updateClassMetadataImpl` — so it dies
only when instantiating class metadata at runtime. Measured: it fails
`p_genericclass` (`Box<T>`) at **`libswiftCore` image offset `0x2dce0`**.

That single offset closes two open items:

- `~/swift-macho-linux/docs/RUNTIME.md` §5 — "non-prespecialized generic class
  metadata crashes in `swift_initClassMetadataImpl`; `[Int]` works, `[Double]`
  dies." Same function, same cause.
- `~/swift-macho-linux/docs/UIKIT_SLICE.md` §4 — the sim runtime's unexplained
  "later draw faults in `libswiftCore@0x2dce0`." **Byte-for-byte the same
  offset.**

Both were the loader placing images above 2^47, not a stdlib gap. Neither
runtime was ever "missing" anything.

## 5. The malloc/heap prediction did not materialise

It was predicted that mapping images low would be necessary but not sufficient,
because `libswiftCore` takes metadata from `malloc` and glibc's brk arena sits
at `0xaaab…`, above 2^47. Not reached on any path measured here: with the loader
fix and the stock runtime, `ArraySlice` over a user class
(`__ContiguousArrayStorage<Elem>`), runtime-instantiated generic class metadata
(`Box<Elem>`, `Box<Int32>`), `AnyObject`, non-class-bound existentials, `String`
and `unowned` **all pass**, and a full scene renders. If a future path does
allocate class metadata from the heap, the wide-mask dylib is the ready answer;
it is not on the critical path today and should not gate the loader merge.

## 6. Reproducing

```sh
# probe: 9 isa-decode cases, graded against native macOS
docker run --rm -v ~/swift-macho-linux:/w -w /w swift-macho-spike:noble \
    bash scripts/build_pngprobe.sh
docker run --rm -v ~/swift-macho-linux:/w -w /w/build/slice \
    -e MACHORUN_ROOT=/w/scratch/mrroot swift-macho-spike:noble \
    /w/scratch/mrroot/machorun ./png_probe        # expect: ALL OK, exit 0

# the render, and the pixel diff against real UIKit output
docker run --rm -v ~/swift-macho-linux:/w -w /w swift-macho-spike:noble \
    bash scripts/build_slice2.sh
docker run --rm -v ~/swift-macho-linux:/w -w /w/build/slice \
    -e MACHORUN_ROOT=/w/scratch/mrroot swift-macho-spike:noble \
    /w/scratch/mrroot/machorun ./slice_main /w/build/slice/boxes_linux.png
python3 tools/pngdiff.py ~/uikit/golden/boxes_basic.png \
    ~/swift-macho-linux/build/slice/boxes_linux.png
```

`tools/pngdiff.py` decodes both PNGs to raw RGBA (the vendored encoder stores
uncompressed, so the *files* differ — 9,486 vs 1,229,438 bytes — while the
pixels are identical). `tests/png_probe.swift` is the 9-case probe, kept here so
the regression outlives the scratch tree it was found in.

## 7. Open, and owned by machorun

The staged sysroot `libSystem.tbd` still **advertises** `swift_*`. In
system-first link order two-level binding sends `_swift_release` to libSystem,
whose stub was removed, and the guest dies at load:

```
machorun: undefined symbol '_swift_release'  wanted by: ./libpngprobe.dylib
```

Dropping `swift_*` from that `.tbd` is the clean fix. Linking swiftcore-first is
only a workaround, and it is the reason every script here passes `-lswiftCore`
before `-lSystem`.
