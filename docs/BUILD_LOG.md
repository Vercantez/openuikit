# Build log — what configured, what built, what ran, what broke

Machine: 64-vCPU Graviton4, Ubuntu 24.04 aarch64, stock swift.org
`swift-6.2.4-RELEASE` Linux toolchain at `/opt/swift624`, Ubuntu `llvm-18`,
`ld64.lld` 18.1.3. Source: `swiftlang/swift` at tag `swift-6.2.4-RELEASE`
(commit `ee343b46`), kept pristine; all edits via `scripts/apply_patches.py`.

**Result: `libswiftCore.dylib`, Mach-O arm64, built on Linux, and a Swift
program linked against it runs to completion under machorun.**

```
$ machorun /tmp/hello
hello from Swift on machorun
sorted: [1, 2, 3]
$ echo $?
0
```

---

## 0. The box was not provisioned as briefed

`cmake`, `ninja`, `clang`, `lld`, and every `-dev` package were absent — only
`libllvm18`/`libclang` runtime libs were installed (pulled in by the Swift
toolchain). One `apt-get install` fixed it; a stale index 404 on a *recommended*
package (`libheif-plugin-aomenc`) required `--no-install-recommends`. Noted
because "installed: …" in the brief was not true and cost the first 20 minutes.

## 1. The reframing that made this tractable

`stdlib/public/core/CMakeLists.txt:293-294` sets `swift_core_framework_depends`
and `swift_core_private_link_libraries` to empty, and appends to the latter only
for Windows and Haiku. **libswiftCore links no Foundation and no
CoreFoundation.** Confirmed against the built artifact: its only
`LC_LOAD_DYLIB`s are libSystem, libobjc, libc++.

Of the 19 distinct `NS*` identifiers the runtime source reaches, the only hard
class references are `NSObject` (which objc4 itself provides) and `NSBundle`;
everything else — `NSString`, `NSArray`, `NSDictionary`, `NSError`, `NSNull`,
`NSProxy` — is reached through `objc_lookUpClass("…")` at run time.

So the wall `~/uikit/docs/OBJC_RUNTIME.md` §3 hit for the *Linux-target* stdlib
("a successfully-built interop libswiftCore.so would still have nothing to link
against") **does not apply to the Darwin target**. Foundation here is a
compile-time *declarations* problem, and a 130-line clean-room umbrella closes
it.

## 2. The sysroot

`scripts/stage_sdk.sh` assembles `~/work/sdk/MacOSX.sdk` — 1,364 headers,
7 `.tbd`s:

| source | what |
|---|---|
| machorun `sdk/usr` | 375 Darwin C headers + `libSystem.B.tbd`, `libobjc.A.tbd`, `libc++.1.tbd` |
| machorun `vendor/objc4/runtime` | `NSObject.h`, `objc-internal.h`, `objc-abi.h`, … (Apple open source) |
| machorun `vendor/objc4-priv` | clean-room private SPI (`TargetConditionals.h`, `mach-o/dyld_priv.h`, `os/*`) |
| swift-corelibs-foundation `Sources/CoreFoundation/include` | 83 CoreFoundation headers (Apple open source) |
| LLVM 18 | libc++ headers at `usr/include/c++/v1` |
| **ours, clean-room** | `Foundation/Foundation.h`, `setjmp.h`, `signal.h`, `MacTypes.h` |

Two findings while staging:

* **swift-corelibs-foundation's `CoreFoundation.h` is not Apple's.** It appends
  `ForSwiftFoundationOnly.h` (corelibs' private bridge to its Swift Foundation,
  drags in `fts.h`/`dirent.h`) and `CFURLPriv.h` (drags in `sys/mount.h`).
  Neither is in the real framework umbrella and neither is reachable from the
  Swift stdlib. Dropping those two `#include`s removed three of the six
  reached-but-missing headers — better than fabricating filesystem headers to
  satisfy code we never compile.
* Only **six** headers were reached-but-missing at all, found by iterating the
  compiler rather than by reading `#include` lines.

Smoke test before touching CMake: an ObjC++ TU importing
`<Foundation/Foundation.h>`, `<CoreFoundation/CoreFoundation.h>` and
`<objc/objc-internal.h>` compiles to a Mach-O arm64 object.

## 3. Configure — **exit 0**

`scripts/configure.sh`. Stdlib-only, no compiler bootstrap
(`SWIFT_INCLUDE_TOOLS=OFF`), consuming the installed 6.2.4 toolchain as
`SWIFT_NATIVE_{SWIFT,CLANG}_TOOLS_PATH`. Confirms OBJC_RUNTIME.md §2: build
scope was never the problem.

```
-- Building Swift standard library and overlays for SDKs: OSX
--   Architectures: arm64
--   arm64 triple: arm64-apple-macosx
--   Module triple: arm64-apple-macos
```

Speed bumps, all trivial: `libedit-dev` missing; `Clang_DIR` and
`SWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE` unused; `SWIFT_INCLUDE_APINOTES=ON` needed
because `stdlib/public/Platform` depends on `copy_apinotes` whenever
`BUILD_STANDALONE` is false, while `add_subdirectory(apinotes)` is gated
separately.

Concurrency was turned **off** for this pass — see §6.

## 4. The walls, in the order they appeared

| # | wall | category | fix |
|---|---|---|---|
| 1 | `include(DarwinSDKs)` is reachable only from the Darwin-*host* branch, so `SWIFT_SDKS=OSX` on Linux configures a build with no targets | patch a conditional | patch 1 |
| 2 | `configure_sdk_darwin` shells to `defaults` and `xcodebuild` for SDK version strings | patch a conditional | patch 2 |
| 3 | 79 compile errors: no C++ stdlib in the sysroot | supply headers | stage LLVM 18 libc++ |
| 4 | `NSString.decomposedStringWithCanonicalMapping` unknown | supply a header | add to our Foundation.h |
| 5 | `LLVM_ATTRIBUTE_WEAK` undefined + every `_dyld_lookup_section_info` call ambiguous | latent upstream bug | patch 3 |
| 6 | build invokes `${Swift_BINARY_DIR}/bin/swiftc`, which does not exist | patch a conditional | patch 4 |
| 7 | link command is ELF: `-fuse-ld=gold`, `-shared`, `-soname`, output `libswiftCore.**so**` | **not fixed in CMake** | `scripts/link_dylib.sh` |
| 8 | 30 undefined symbols at link | supply implementations | `libswiftcompat.dylib` |
| 9 | SIGSEGV in `swift::addImageDynamicReplacementBlockCallback` | wrong image-registration path | patch 5 |
| 10 | abort in machorun's `swift_release` stub | **link order** | see §5 |
| 11 | `tls_init_once() failed to set destructor` | machorun limitation | open |

Wall 5 is worth spelling out because it is a real upstream portability bug that
only a non-Apple SDK exposes. `ImageInspectionMachO.cpp` re-declares
`_dyld_lookup_section_info` weakly under `#if OBJC_ADDLOADIMAGEFUNC2_DEFINED`.
machorun's objc4 is newer than the SDK Swift 6.2.4 targets and *does* define
that macro, so we enter a branch Apple's own build skips — and the
re-declaration sits at C++ namespace scope while our `dyld_priv.h` declares the
same function inside `__BEGIN_DECLS`. The two are therefore *overloads*, not
re-declarations, and every call is ambiguous. Without `extern "C"` the fallback
would emit a call to a mangled name that cannot exist.

Wall 7 is the one thing not fixed properly. `CMAKE_SHARED_LIBRARY_SUFFIX` and
the SONAME flag come from `Modules/Platform/Linux.cmake`; no Swift-level
variable overrides them, and the honest fixes are either a
`CMAKE_SYSTEM_NAME=Darwin` toolchain file (which changes host-tool detection
project-wide) or per-target property overrides in `AddSwiftStdlib.cmake`.
`scripts/link_dylib.sh` performs the link from exactly the object list ninja
assembled, so the artifact is reproducible; making `ninja` emit it directly is
the first thing a follow-up should do.

## 5. The artifact

`scripts/verify.sh`:

```
Mach-O 64-bit arm64 dynamically linked shared library
  flags: NOUNDEFS|DYLDLINK|TWOLEVEL|NO_REEXPORTED_DYLIBS|APP_EXTENSION_SAFE
  LC_BUILD_VERSION present; cputype 16777228 (arm64, NOT arm64e); filetype 6 (MH_DYLIB)

install name  /usr/lib/swift/libswiftCore.dylib
deps          /usr/lib/libSystem.B.dylib, /usr/lib/libobjc.A.dylib, /usr/lib/libc++.1.dylib

30,723 exported symbols
    544  swift_* runtime entry points
 30,137  mangled $s Swift symbols
     23  Objective-C classes

spot checks, all present:
  _swift_retain          _swift_release            _swift_allocObject
  _swift_deallocObject   _swift_getTypeByMangledName
  _swift_conformsToProtocol  _swift_dynamicCast    _swift_once
  _swift_getGenericMetadata  _swift_errorRetain    _swift_bridgeObjectRetain
  _OBJC_CLASS_$__TtCs12_SwiftObject
  _OBJC_METACLASS_$__TtCs12_SwiftObject
```

**The 30-symbol gap.** Of 186 undefined imports, 156 are satisfied by the
sysroot's `.tbd`s. The other 30 are what machorun's self-hosted userland does
not yet carry, and `sdk/compat/swiftcompat.c` supplies all 29 real ones
(`dyld_stub_binder` is the loader's own):

* **compiler-rt 128-bit division** (4) — `__divti3`, `__udivti3`, `__modti3`,
  `__umodti3`. Real implementations; they cannot be written as `a / b` on
  `__int128` because clang lowers that back into a call to the same function.
* **libc gaps** (6) — `getline`, `flockfile`, `funlockfile`, `strtod_l`,
  `strtof_l`, `strtold_l`.
* **Mach-O / dyld** (3) — `getsectiondata` (real: walks the load commands),
  `_NSGetMachExecuteHeader`, `_dyld_is_objc_constant`.
* **availability** (3) — `__isPlatformVersionAtLeast` and friends.
* **misc Darwin** (4) — `dispatch_once_f` (real), `malloc_zone_from_ptr`,
  `pthread_get_stackaddr_np`, `pthread_get_stacksize_np`.
* **libc++/libc++abi** (9) — `__libcpp_verbose_abort`,
  `thread::hardware_concurrency`, `operator+(const char*, const string&)`,
  sized-aligned `operator delete`, `__cxa_demangle`, and the four
  `__cxxabiv1` `type_info` vtables. Only the vtables are bind-only stubs; the
  runtime is built `-fno-exceptions` and nothing dispatches through them.

Note a discrepancy worth remembering: the `.tbd` files **over-promise relative
to the built dylibs**. `_dyld_get_image_header` is absent from machorun's
libSystem entirely (it exports only the `_NSGetArgc`/`Argv`/`Environ`/`Progname`
family), so link-time success is not by itself evidence of run-time success.

## 6. Running it

`scripts/run_under_machorun.sh`. Two non-obvious requirements:

**Link order is load-bearing.** machorun resolves binds by flat lookup in load
order, and its `libSystem.B.dylib` exports its own `swift_release`
*diagnostic stub* — a placeholder from before there was a real libswiftCore to
load (machorun `docs/UNIMPLEMENTED.md#swift-interop`). With `-lSystem` first,
objc4's fast-path refcounting binds to that stub and the program aborts the
instant any Swift object is released:

```
machorun/libSystem: swift_release: a Swift-stable object reached objc4's
fast-path refcounting, but no libswiftCore is loaded under machorun.
```

With `-lswiftCore` first — same objects, same libraries, different
`LC_LOAD_DYLIB` order — it binds to the real implementation and the program
runs. Removing that stub now that a real libswiftCore exists is a machorun-side
change this work has earned.

**Image registration must take the legacy path** (patch 5, opt-in via
`SWIFTCORE_MACHO_LEGACY_IMAGE_REG=1`). With `objc_addLoadImageFunc2`, Swift asks
`_dyld_lookup_section_info` for each section's location; machorun exports that
symbol but its answer is not what Swift's inspector expects, and the runtime
faults in `addImageDynamicReplacementBlockCallback` walking the result. The
older `objc_addLoadImageFunc` + `getsectiondata` path derives the same sections
from the Mach-O header and needs nothing from the loader.

### What works

```
hello from Swift on machorun
sorted: [1, 2, 3]                        exit 0
```

String literals, `print`, `Array.sorted()`, string interpolation, ARC.

### What does not, yet

A program using classes, generics, protocol existentials and dictionaries
aborts before `main`:

```
tls_init_once() failed to set destructor
```

That is machorun's libSystem, not our stdlib: the Swift runtime's
`SwiftTLSContext` wants a pthread key with a destructor and machorun's TLS
implementation cannot register one. It is the next thing to fix, and it is on
the loader side.

## 7. Reproducing

```sh
scripts/stage_sdk.sh                      # sysroot from machorun + open source
python3 scripts/apply_patches.py          # 4 patches (+1 opt-in)
SWIFTCORE_MACHO_LEGACY_IMAGE_REG=1 python3 scripts/apply_patches.py
scripts/configure.sh -DSWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY=OFF \
                     -DSWIFT_ENABLE_DISPATCH=OFF -DSWIFT_INCLUDE_APINOTES=ON
ninja -C ~/work/build -j64 swiftCore-macosx-arm64   # fails at the ELF link edge
scripts/link_dylib.sh -Wl,-undefined,dynamic_lookup # …so link it ourselves
scripts/verify.sh
scripts/build_compat.sh
scripts/run_under_machorun.sh /tmp/hello.swift
```

Total wall-clock on 64 cores: configure ~10 s, full stdlib build ~4 min.

---

## 8. Wall 12 (found 2026-08-26, after the box was released): the isa mask

A teammate exercising the OpenUIKit slice against this stdlib reported faults in
`swift_unknownObjectRetain`/`Release` "on a stack-region isa", with plain classes
and class-bound existentials passing but non-class-bound existentials failing.
That is fully explained, and it is our bug, not theirs.

machorun patches objc4's isa layout because the **host** is Linux, whose user
addresses are 48 bits wide (`machorun/patches-macho/0001-wide-va-isa-layout.patch`):

```
machorun objc4:  ISA_MASK 0x007ffffffffffff8    bits 3..54
libswiftCore:    ISA_MASK 0x00007ffffffffff8    bits 3..46   (Apple arm64 macOS)
```

Swift hardcodes Apple's value — `SWIFT_ABI_ARM64_OBJC_ISA_MASK` in
`include/swift/ABI/System.h` — and bakes it into **48** AND/ANDS-immediate
instructions. machorun maps guest images above 2^47 (a crash pc from our own
first run: `0xfe3de57774bc` = 2^47.99), so the narrower mask strips bit 47:

```
0x0000fe3de57774b8  ->  0x00007e3de57774b8
```

which is not a class, and the next instruction (`ldrb w9, [x8, #0x20]`)
dereferences it.

**Correction (from the slice agent's later measurement, ebf123d):** the faulting
function is `swift_getObjectType` at `+0x331eb4`, not `swift_unknownObjectRelease`.
Every isa-decoding site has the identical `and`/`ldrb [x, #0x20]` shape, and at
-Onone existential *construction* calls `swift_getObjectType`, so the trigger is
any isa decode rather than the release path specifically. The first diagnosis
inherited an offset second-hand and did not verify it. Relatedly, the truncated
value was never "a stack address": `0x00007e3d...` merely looks like a stack
pointer, and reading it as one is what pointed the original investigation at
refcounting. The mechanism below is unaffected; the attribution was wrong.

Disassembly of our own artifact, showing the shape:

```
_swift_unknownObjectRelease:
  3328bc   ldr   x8, [x0]
  3328c0   and   x8, x8, #0x7ffffffffff8     <- Apple's 44-bit mask
  3328c4   ldrb  w9, [x8, #0x20]             <- faults here
```

`swift_retain`/`swift_release` never read the isa; only the `unknownObject`
family does. That is exactly why plain classes and (optimizer-devirtualised)
class-bound existentials pass while `AnyObject` and non-class-bound existentials
fault — the trigger is the *calling convention*, not the unowned back-reference.

**Fix.** Patch 6 widens the constant for a rebuild. Both masks are contiguous
runs of ones starting at bit 3, so both encode as AArch64 64-bit logical
immediates with `N=1, immr=61`, differing only in `imms` (43 vs 51) — six bits
per instruction, same length. `scripts/widen_isa_mask.py` therefore applies the
identical change in place:

```
$ python3 scripts/widen_isa_mask.py \
      artifacts/swift-macosx/arm64/libswiftCore.dylib \
      artifacts/libswiftCore.machorun-wideisa.dylib
  AND-immediate sites widened: 48
  data words widened:          1      (_swift_isaMask)
```

Zero narrow sites remain; exports (30,723) and dependencies unchanged.

**Caveat.** Patch 6's anchor string has *not* been verified against the source
tree — the build box was released before this was found. `apply_patches.py`
asserts each anchor matches exactly once, so it will fail loudly rather than
silently no-op if the constant lives elsewhere in 6.2.4.

**This makes the artifact machorun-specific**, in the same way and for the same
reason machorun's objc4 is: it encodes a 48-bit host VA. A libswiftCore for real
Darwin must keep Apple's mask. Keep both files distinct.

---

## 9. Does the wide mask generalize? Apple already answered this

The architecture question was whether stage-time widening of Apple's shipped
Swift dylibs is a standing policy, or whether keeping every guest address below
2^47 is the real fix. **Apple's own shipped binaries settle it**, and no build
box was needed to find out.

### The measurement

`/Library/Developer/CoreSimulator/.../iOS 26.1.simruntime/.../libswiftCore.dylib`,
Mach-O arm64, `LC_BUILD_VERSION platform 7` (iOS Simulator):

| | isa-mask sites | value |
|---|---|---|
| Apple's shipped arm64 simulator build | **48** | `0x007ffffffffffff8` — **already wide** |
| ours, built for `arm64-apple-macos` | **48** | `0x00007ffffffffff8` — narrow |

**The same 48 sites, and Apple's are already wide.** objc4 says why, in a
comment predating all of this:

> ARM64 simulators have a larger address space, so use the ARM64e scheme even
> when simulators build for ARM64-not-e.

machorun *is* a simulator in the only sense that matters: a Darwin userland
hosted inside a larger address space. Apple has a supported configuration for
exactly that, and it widens the mask rather than confining the address space.
So widening is not a hack we invented; it is the Apple-sanctioned answer for
hosted runtimes, and machorun's objc4 patch already picked it.

**Consequence: stage-time patching of Apple's Swift dylibs is a non-problem.**
The binaries we would ever stage are simulator runtimes, and their isa masks are
already correct. Nothing to rewrite. The narrow mask appears only in device and
macOS-native builds — which is precisely what we accidentally produced by
targeting `arm64-apple-macos`.

**So the fix for our own output is the target, not the binary.** Patch 6 is a
stand-in for "build to the simulator ABI"; `widen_isa_mask.py` is a stand-in for
patch 6 when there is no build machine. None of the three should become a
standing policy for other people's binaries.

**And the loader fix is strictly more general — this is the argument for it.**
Widening repairs *our* runtime but *cannot* repair Apple's, because Apple's
residual narrow sites are the 9 data-bits masks below, and widening those is
corruption, not a fix. `widen_isa_mask.py` refuses them by design. So the
wide-mask route leaves Apple's shipped runtime permanently broken under
machorun, while mapping guests below 2^47 repairs both at once. The slice
agent's 2x2 measured exactly that (ebf123d): ours-stock and Apple's-sim both
SIGSEGV on machorun master and both pass 9/9 on `fix/map-below-isa-mask`, while
ours-widened passes on either. Independently sufficient, but only one of them
is general. **Take the loader fix; keep widening as the fallback for a runtime
we build and cannot re-target.**

### The premise was false: surveyed, not sampled

Task #42 was assigned on the premise that *"Apple's SHIPPED Swift dylibs all
have the narrow mask inlined."* Measured across the whole iOS 26.1 simulator
runtime with `scripts/survey_isa_masks.py` (which reuses the rewriter's own
decoder and classifier, so survey and tool cannot disagree):

```
binary                                    wide  narrowISA  narrowDATA  unclass
libswiftCore.dylib                          48          0           9        0
libswift_Concurrency.dylib                   0          0           0        0
libswiftFoundation.dylib                     0          0           0        0
libswiftUIKit.dylib                          0          0           0        0
libswiftDarwin.dylib                         0          0           0        0
libswiftObjectiveC.dylib                     0          0           0        0
libswiftDispatch.dylib                       0          0           0        0
UIKit.framework/UIKit                        0          0           0        0
Foundation.framework/Foundation              1          0           0        0
libobjc.A.dylib                            256          0           0        0
--- ours, arm64-apple-macos ---
libswiftCore.dylib                           0         48           0        0
libswiftCore.machorun-wideisa.dylib         48          0           0        0
```

**Not one narrow isa site anywhere in Apple's shipped simulator runtime.**
libobjc carries 256 wide sites; the Swift overlays inline no isa masking at all
and delegate to libswiftCore/libobjc. The narrow mask is a *macOS-target*
property, and the only binary in the world that has it here is the one we built
by targeting `arm64-apple-macos`.

So stage-time widening as a standing policy is not merely unnecessary — across
an entire staged runtime **there is nothing to widen**, and the only narrow
sites that exist are the 9 our tool must refuse. That closes the generality
question: it cannot be the architecture, because it has no work to do on the
binaries it was proposed for, and the one thing it *could* touch there is the
thing it must not.

### The trap, found the same way

The value `0x00007ffffffffff8` is **not only** the isa mask. objc4's
`DEBUG_DATA_MASK` is the same constant on non-device targets and masks a
completely different field — `class_data_bits_t` at offset `0x20` of an
`objc_class`, yielding a `class_rw_t*`. Apple's simulator build has **9** such
sites, all in `_swift_initClassMetadataImpl` / `_swift_updateClassMetadataImpl`.

An immediate-only rewriter would silently corrupt all nine. `widen_isa_mask.py`
therefore classifies every candidate by dataflow — scanning back to the start of
the containing function for the nearest load that defines the masked register —
and rewrites only `ldr Xs, [Xb]` (offset 0, the isa), refusing `ldr Xs, [Xb, #0x20]`
(the data bits) and anything it cannot classify:

```
$ widen_isa_mask.py <apple's shipped libswiftCore> /tmp/out --dry-run
  narrow candidates : 9
    DATA_BITS     : 9
  already wide      : 48
  !! DATA_BITS at 0x2dc88 src=[x,0x20] in _swift_initClassMetadataImpl
  ... (9 total)
  -> ISA sites widened: 0
```

A fixed instruction window is not sufficient for classification: the runtime
keeps the isa in a callee-saved register across calls, and
`-[_TtCs12_SwiftObject hash]` masks a value loaded fourteen instructions
earlier. Function-scoped backward search handles both that and the tight
`ldr; and` form the data-bits sites use.

**And those 9 sites are a real, separate incompatibility.** machorun widened
`FAST_DATA_MASK`/`DEBUG_DATA_MASK` to `0x0000fffffffffff8` while Apple's
simulator build masks with `0x00007ffffffffff8`, so a `class_rw_t` above 2^47
loses bit 47 — in `_swift_initClassMetadataImpl`, which is exactly where the
slice agent observed Apple's shipped simulator libswiftCore crash (`@0x2dce0`,
inside the `0x2dc88`–`0x2e2d8` range above). Same class of bug, different
constant, independently confirmed.

That one is cheaper to fix on the loader side: leave `DEBUG_DATA_MASK` at
Apple's value and keep objc4's own `class_rw_t` allocations below 2^47. That is
a far narrower requirement than "every guest address below 2^47" — it constrains
one allocator that machorun already controls, rather than the whole address
space.

### Verification

| test | result |
|---|---|
| our build | 48/48 classified ISA, 0 refused, 48 widened + `_swift_isaMask` |
| idempotency | re-run on the widened output: 0 candidates, 48 already wide, **byte-identical** |
| Apple's shipped arm64 build | 48 already wide, 9 correctly refused as `DATA_BITS` |

Manifests (`--manifest`) record sha256 before/after, per-site vmaddr, function
and classification, so a staged artifact can be told from a stock one without
disassembling it.

---

## 10. How much of this needed the build box

The lead's instinct was that we reach for big machines where disassembly would
do. The honest tally, by wall:

| walls | needed the box? |
|---|---|
| 1–7 (configure, headers, codegen, link edge) | **Yes.** These are compile and build-system walls; you cannot hit them without building. |
| 8 (30 undefined symbols) | No — `nm` on the artifact. |
| 9 (image-registration SIGSEGV) | Diagnosis no (symbolization); fix yes (rebuild). |
| 10 (swift_release stub / link order) | No — relink only. |
| 11 (TLS destructors) | No — runtime, loader-side. |
| 12 (isa mask) + §9 above | **No box at all.** Pure local disassembly, including the answer to the architecture question. |

So the pattern is not "we over-provision" so much as "the box is needed to
*produce* the artifact, and rarely needed afterwards." Seven walls genuinely
required a build; everything after the artifact existed was answerable from the
artifact. Wall 12 and this entire section were found on a laptop after the box
was already terminated — including the decisive evidence, which was sitting in
Apple's shipped simulator runtime the whole time.

The cheap habit worth keeping: **before provisioning, check whether the question
is about a binary we already have.**

---

## 11. Where `class_rw_t` comes from, and why it lands below 2^47

`DEBUG_DATA_MASK` masks `class_data_bits_t` at `objc_class+0x20` to yield a
`class_rw_t*` — a pointer objc4 **allocates at runtime**. So the sub-2^47
constraint binds the guest *heap*, not only image placement. Asked whether that
holds by design or by luck. **By design, and it is already closed in machorun's
`fix/map-below-isa-mask` (a1718a4).** Recorded here because the question will
recur and the mechanism is not obvious.

### The allocation path

`objc::zalloc<class_rw_t>()` (`objc-zalloc.h`) dispatches on
`sizeof(T) % 16 == 0`: either straight `::calloc`, or a slab allocator whose
refill mallocs. Both bottom out in the guest's `malloc`, and machorun's
libSystem forwards every one of those to glibc (`glibc_malloc`, via
`darwin/src/objcsupport.c` and `libcxx.c`). **There is no private objc arena.**
So `class_rw_t` is a glibc heap pointer, and its address is whatever glibc's
main arena hands out.

### Why it is low, in three parts

The decisive one is **link-time, not mmap policy**, and `src/map.c` explains
why: on aarch64 Linux puts a PIE at `2*TASK_SIZE/3` (`0xaaaa_xxxx_xxxx`) and
**brk follows the image**, so the main arena inherits an address above 2^47 that
no mmap policy can move. `scripts/build.sh` therefore links the loader
`-no-pie -Wl,-Ttext-segment=0x10000000000` (2^40) so brk starts below the limit.
Then `mr_constrain_heap()` adds `mallopt(M_ARENA_MAX, 1)` — a second thread
would otherwise get an mmap'd arena, measured at `0xffffb4000b70` — and
`mallopt(M_MMAP_THRESHOLD, 32 MiB)`, glibc's own maximum, keeping ordinary
allocations in brk.

**machorun-isamask's original concern was correct and was not merely unreached.**
`src/map.c`'s own comment records the crash it caused: fault address
`0x2aaab6c04ea8`, which is `0xaaaab6c04ea8` — "a perfectly ordinary glibc
main-arena address" — with bit 47 cleared. It was hit, diagnosed and fixed.

### Headroom, and the one residue

`MR_LOADER_BASE = 0x10000000000` (2^40), `MR_ISA_LIMIT = 0x800000000000` (2^47):
brk would have to grow **~139.7 TiB** on a single arena before it could cross.
Not a realistic exhaustion path.

The honest residue, documented in machorun rather than fixed: **a single
allocation ≥ 32 MiB still goes to mmap and still lands high.** The argument is
that no class object is 32 MiB — the sizes at issue are Swift's 64 KiB metadata
pool refills and objc4's few-hundred-byte class pairs — and a guest asking for
32 MiB is asking for a buffer, not a class. That holds.

### The assertion already exists

`mr_constrain_heap()` is called from `main.c:166`, before `find_darwin_root()`
and before any guest allocation (ordering matters: `M_ARENA_MAX` only binds
arenas that do not exist yet). It calls `sbrk(0)` and `malloc(64)` and
`mr_die()`s if either is at or above `MR_ISA_LIMIT`, with a message that names
the mask, the consequence and the fix. It verifies rather than trusts.

**One soft spot worth hardening.** If `mallopt(M_ARENA_MAX, 1)` is *refused*,
the code logs a warning and continues — and the startup probe runs before any
guest thread exists, so a secondary arena created later is never checked. With
zero margin that is the one path where a truncation could still occur silently.
Cheap fix: re-probe once on the guest's first secondary thread (one
`malloc`/`free`) and die on a high answer.

**Stale doc:** `machorun/docs/UNIMPLEMENTED.md#isa-va-width` still says
"Nothing aborts, which is the problem." `mr_constrain_heap()` now does.

### What a wider scan did and did not show

Scanning every `and`/`ands` immediate with a contiguous run of ones from bit 3
across the simulator and device (`iphoneos`, `appletvos`) Swift runtimes found
**no pointer-field mask tighter than 2^47**, so `MR_ISA_LIMIT = 2^47` is the
binding constraint among Apple binaries we might stage. That scan is noisy,
though — most matches are ordinary alignment masks, and `survey_isa_masks.py`'s
`kind` label is only meaningful for a mask already known to be a pointer mask.
The trustworthy result is the targeted one in §9, which matches the two known
constants exactly.

## 12. The shim was shadowing libc++abi, and one of the shadows was armed

`libswiftcompat.dylib` exists to fill the gap between our cross-built
libswiftCore and machorun's userland. A gap shrinks. When machorun grew a real
`/usr/lib/libc++abi.dylib` (LLVM 18.1.8, pristine) and a real `pthread_main_np`,
ten of our definitions stopped being fills and became **duplicates** — and
libswiftCore binds most of them flat, so a duplicate is resolved by load order
rather than by which one is correct.

swift-loader-fixes flagged six by sweeping the *shipped* dylib. Against the
*source* there were **ten**, because the shipped artifact was stale:

| | exports | has the shadows |
|---|---|---|
| `darwin/usr/lib/libswiftcompat.dylib` (staged) | 29 | 6 |
| `artifacts/concurrency/libswiftcompat.dylib` (built, never staged) | 44 | **10** |
| source at `sdk/compat/swiftcompat.c` | 44 | 10 |

The second row is the finding. `artifacts/concurrency/` has exactly the layout
`machorun scripts/stage_swiftcore.sh` expects, so the 44-symbol build was one
`stage_swiftcore.sh artifacts/concurrency` away from being installed — not a
hypothetical future regression, a worse artifact already sitting in a staging
directory.

### The four extra shadows, worst first

- **`pthread_main_np` → `return 1`**, commented "single-threaded executor".
  machorun's records the main thread at bootstrap and compares `pthread_self`
  (`darwin/src/posix.c:1482`). A constant 1 makes **every** thread answer "yes,
  I am the main thread", which silently breaks every `@MainActor` assertion and
  libdispatch's main-queue check. Never reached only because it was never
  staged.
- **`malloc_type_malloc`** — a second copy of the family whose *first* duplicate
  cost this project a week (machorun's umbrella-shadows-reexport defect).
- `__cxa_pure_virtual`, and a fifth vtable (`__vmi_class_type_info`) that
  swift-loader-fixes' sweep could not see because it was not in the stale build.

### The hazard is worse than "resolved by load order"

Linking `libswiftcompat` ahead of `libc++abi` makes **ld64 itself** pick the
shim and emit a **two-level** bind naming it. Such a guest is wired to the
zerofill vtables deterministically; it is not a matter of luck at load time.

Measured with machorun's own `tests/src/30_throw.cpp` — whose load-bearing case
is "catch a `Derived` as a `Base &`", which needs libc++abi's hierarchy walk
*through* `__si_class_type_info`'s vtable rather than a pointer compare — linked
shim-first:

```
shim WITH the vtables:  SIGSEGV, pc 0x0, no output at all
shim WITHOUT them:      exit 0, all six cases ok, matches the macOS baseline
```

### Why nothing had failed yet, stated exactly

machorun's `scripts/swift_gate.sh` passes with the shadowing shim and without
it, in **both** of its link orders. Instantiating Swift classes never dispatches
through a type_info vtable; only a throw does. The gate was not weak — it was
measuring something else, which is the harder case to notice.

### What changed

Ten symbols deleted from `sdk/compat/swiftcompat.c` (44 → 34 exports). Deleted,
not corrected: two definitions of one symbol is the defect, and a corrected
duplicate is still a duplicate.

Two guards, both with demonstrated teeth:

- `scripts/build_compat.sh` now **refuses to build** a shim whose exports
  intersect machorun's userland, naming each collision and the library that owns
  it. It also refuses to grade if it cannot find machorun's dylibs, rather than
  passing vacuously.
- `scripts/check_shim_shadowing.sh` builds a mutant with the four vtables
  restored and requires the real shim to PASS `30_throw` *and* the mutant to
  DIE. It refuses to grade if the mutant's vtable is not zerofill or if the
  mutant stops winning the link — either would make the control inert.

### Two side effects worth recording

- The new shim strictly improves `libswift_Concurrency`'s link closure:
  **5 → 0** unsatisfied symbols (`clock_getres`, `memset_s`, `os_release`,
  `voucher_adopt`, `voucher_copy`), which the stale 29-symbol build left open.
- `libswiftCore` has **2** genuinely unsatisfied imports against the current
  userland, unchanged by any of this and pre-existing:
  `_dyld_image_path_containing_address` and `_dyld_program_sdk_at_least`, both
  two-level from libSystem.

### The build no longer needs the AWS box

`scripts/build_compat_docker.sh` builds this artifact locally in
`machorun-swift:6.2.4` using swift.org's clang and Ubuntu's `ld64.lld-18`, with
machorun's SDK for headers and `.tbd`s. Still no Xcode and no Apple toolchain.
It checks `swiftcompat.c` by md5 on the far side of the bind mount, because a
mount that silently truncates would produce a shim that compiles fine and
quietly drops whichever symbols fell off the end.

## 13. `__gxx_personality_v0` binds from libSystem because a `.tbd` loses a reexport

swift-loader-fixes asked for a relink: our `libswiftCore.dylib` two-level-binds
`___gxx_personality_v0` naming **libSystem**, where Apple's shipped one names
**libc++**. To keep the Swift gate green they made machorun's
`libSystem.B.dylib` re-export `libc++abi.dylib` — a deliberate deviation macOS
does not have, recorded with an exit condition.

**The relink is not the blocker.** Measured on the current tree:

| | `libc++.1.dylib` (the dylib) | `libc++.1.tbd` (what the linker reads) |
|---|---|---|
| `LC_REEXPORT_DYLIB /usr/lib/libc++abi.dylib` | **yes**, exactly like Darwin | — |
| symbols advertised | 105 own **+ 367 re-exported** | **105 own only** |

`scripts/gen_tbd.sh` generates from `nm` of the built dylib and does not follow
`LC_REEXPORT_DYLIB`, so all 367 re-exported symbols — `___gxx_personality_v0`
among them — are invisible at link time. Apple's own
`MacOSX.sdk/usr/lib/libc++.tbd` does **not** use a `reexported-libraries:`
stanza either; it lists the re-exported symbols **inline in its own `exports:`**.
That is why linking `-lc++` on macOS yields a two-level bind naming libc++.

So a relink today, with the stdlib's real library set
(`-lSystem -lobjc -lc++`, no `-lc++abi`, `-undefined dynamic_lookup`), produces:

```
current tbds:        ___gxx_personality_v0 (dynamically looked up)   <- a FLAT bind
libc++.tbd patched:  ___gxx_personality_v0 (from libc++)             <- Apple's answer
```

A flat bind would satisfy "no longer names libSystem" while reintroducing
exactly the defect class §12 was about: a symbol whose provider is decided by
load order. **Sequence matters — the tbd fix must land before the relink, or the
rebuild is spent producing the wrong answer.** Patching `libc++.tbd` to
advertise the symbol was verified end to end: the bind moves to libc++ and
`30_throw` still runs clean against the macOS baseline.

**Cost of the relink, stated plainly.** libswiftCore's object files died with
the Graviton box and the swift-6.2.4 source is not local, so this is a full
stdlib cross-build, not a link step: either a new box (~$3) or a source fetch
plus hours of local Docker CPU. Worth doing once, after the tbd fix.

## 14. Both guards from §12 were themselves defective, and one caught itself

Two follow-ups, both found after §12 landed, both about the guards rather than
the thing they guard.

**The symbol reader was hardcoded to a path that does not exist off the build
image.** `build_compat.sh` defaulted `NM` to `/usr/lib/llvm-18/bin/llvm-nm`,
which is absent on the macOS host. Measured: it dies with exit 127, so the
warned failure mode — *an empty symbol list read as "no overlap", a green build
reporting that it checked nothing* — **did not apply**. But the diagnostic names
a path and reads like a missing library, and the safety rode entirely on
`errexit` propagating out of a pipeline inside a `for` loop; one `|| true` in a
refactor would have converted it into the silent case.

It now preflights the reader **by content**: the tool must list more than 50
external symbols from a dylib known to be full of them, because *a tool that
runs and prints nothing is exactly as dangerous as one that is absent*. It falls
back through `llvm-nm`, `llvm-nm-18`, `nm` (macOS `nm` accepts the same flags and
returns the identical 367 symbols for libc++abi), and **refuses with exit 2** if
none work. Verified on four inputs: absent default → falls back; present but
silent → falls back; working `nm` → accepted; nothing available → refuses.

**The negative control was asserting something other than what it claimed, and
its own inertness check caught it.** The mutant was built with
`-install_name /usr/lib/libswiftcompat.dylib`, which looks right and is wrong:
machorun resolves a two-level bind **by install name**, so the guest loaded
whatever was *staged* at that path and the mutant file on disk was never in the
process. The control was therefore an assertion about machorun's staged tree,
not about the file it had just built — and it passed only while the staged shim
still carried the vtables.

The moment swift-loader-fixes staged the fixed shim, the mutant stopped dying of
zerofill and started dying of `undefined symbol` (exit 73). The script's own
`NO-OP` branch reported *"this check can no longer detect the defect it was
written for"* rather than a pass. **That is the branch earning its place**: the
exciting reading was "the loader now defends against this", and the true reading
was "my control is inert".

Fixed by giving the mutant its own install name (`@rpath/libshadowmutant.dylib`,
found via `-rpath`) so it is genuinely the image in the process. It now reports
`vtable from libshadowmutant` and SIGSEGVs on its own account, independent of
what is staged — which is what it always claimed to be doing.

**The generalisation:** §12's finding was that a *shim* silently deferred to
another image. Both defects here are the same shape one level up — a *check*
silently deferring to a tool or an artifact it did not verify it was actually
using. Verify the instrument by content, not by name, and have every negative
control assert that it is still reaching the code it was written for.

## 15. The denominator rule, applied to my own sweep — and a refusal that could not fire

Team-lead made a rule standing after §14: *a sweep that reports "clean" without
reporting how many things it compared is indistinguishable from one that
compared none.* Applied to `build_compat.sh`'s overlap check, it found three
defects in a guard that had been passing.

**It enumerated instead of discovering.** Four hardcoded names with
`[ -f ] || continue`. Two failure modes, both reporting success: a **missing**
library is skipped silently (grade three of four, print "disjoint"), and a
**new** library is never looked at. It now discovers every `*.dylib` under
`MRLIB`. The denominator went from 4 to **6** — `libquartz.dylib` (507 symbols)
and `libswiftCore.dylib` (30,723) had never been in the comparison. Still
disjoint, but nobody could have known that.

**It printed a verdict without its denominator.** The success line now reads:

```
exports: 34  -- disjoint from machorun's userland
graded against 6 dylib(s), 32711 distinct symbols:
   libSystem.B.dylib     589 …  libc++abi.dylib   367 …  libswiftCore.dylib 30723 …
```

**And the refusal written for the truncation hazard could never fire.** A third
refusal was meant to catch a dylib that reads as zero symbols — a *failed read*,
not an empty library, which is precisely the shape of the macOS bind-mount
truncation this project has been warned about. Testing it with a dylib truncated
to 40 bytes: exit **1**, no output at all. Under `set -o pipefail`, nm exiting
nonzero killed the script inside the collection loop, **before** the refusal that
was written to report it. The guard was unreachable from the day it was written.

The fix is a `|| true` that is load-bearing rather than lazy: absorb nm's failure
so the empty read becomes a *count*, which the refusal can then grade. Verified
on four inputs — empty `MRLIB` → refusal 1; only `libc++.1` present → refusal 2,
naming what is absent; one dylib truncated to 40 bytes → refusal 3; the real
tree → builds, 34 exports, disjoint across all 6.

**The pattern, third instance today.** §12 was a shim deferring to another image.
§14 was a check deferring to a tool and an artifact it never verified. This is a
check whose failure path was shadowed by the shell's own error handling. Each
time the component was doing something other than what its name claimed, and
each time only *running the failure case* showed it. **A refusal that has never
been observed to fire is a comment.**

## 16. The relink: `__gxx_personality_v0` now names libc++, and six flat binds went with it

§13 established that the relink was blocked on a `.tbd` bug rather than on the
rebuild. swift-loader-fixes fixed `gen_tbd.sh` to vend what a dylib re-exports
(machorun `559356b`, `libc++.1.tbd` 105 → 472 symbols), and this is the rebuild.

**Verified the precondition before paying for the box**, with the stdlib's own
library set rather than a C++ guest — `-lSystem -lobjc -lc++`, no `-lc++abi`,
`-undefined dynamic_lookup` — and only then provisioned. Result:

```
                                        before the tbd fix      after
___gxx_personality_v0                    (from libSystem)        (from libc++)
__ZTVN10__cxxabiv117__class_type_infoE   (dynamically looked up)  (from libc++)
__ZTVN10__cxxabiv119__pointer_type_infoE (dynamically looked up)  (from libc++)
__ZTVN10__cxxabiv120__function_type_infoE(dynamically looked up)  (from libc++)
__ZTVN10__cxxabiv120__si_class_type_infoE(dynamically looked up)  (from libc++)
__ZdlPvmSt11align_val_t                  (dynamically looked up)  (from libc++)
___cxa_demangle                          (dynamically looked up)  (from libc++)
```

**The line that was asked for is the first one. The more valuable result is the
other six.** They are the exact symbols §12 was about, and they are no longer
resolved by load order at all — libswiftCore names the library it wants.
Deleting the duplicates from the shim fixed the current process; this makes the
whole class unreachable *for this image*, which is a stronger property than "no
duplicate happens to exist right now".

**Neutrality proved rather than assumed.** The relinked library's export set is
**identical** to both prior builds — 30,723 symbols, `diff` reports 0 differing
— and `libswift_Concurrency` resolves against it exactly as before (435
undefined, 59 outside libswiftCore either way). So substituting it into the
staging directories cannot change the Swift surface. `18_swift_class` passes
under machorun in **both** link orders against the macOS baseline.

**Cost: $0.80.** c8g.16xlarge for 16 minutes. Configure ~10 s, 173 objects, the
stdlib build about four minutes. Two configure flags were missing from §7's
recipe for a concurrency-enabled build and are recorded here:
`-DSWIFT_PATH_TO_LIBDISPATCH_SOURCE=$W/libdispatch -DSWIFT_INCLUDE_APINOTES=ON`.
The errors changed *kind* at each step, which is the tell that each fix landed
rather than masked the previous one.

### One thing I did not do, and why

`libswift_Concurrency.dylib` still carries **three flat vtable binds**
(`__class_`, `__si_class_`, and `__vmi_class_type_info`) because it was built
against the old `.tbd`s. Rebuilding it needs a new patch: with
`SWIFT_PATH_TO_LIBDISPATCH_SOURCE` set, ninja wants a
`stdlib/public/Concurrency/dispatch` directory that only exists if libdispatch
was built; without it, `StdlibOptions.cmake:225` refuses with *"Concurrency
requires libdispatch on non-Darwin hosts"*. That is patch-8 work, not a flag.

It is **latent rather than live** — libswift_Concurrency is not staged — so I
stopped rather than open a new patch on a metered box. The blocker is named here
so the next attempt starts from the cause.

### A measurement I threw away

While checking the relinked library's unsatisfied imports I extracted the
`.tbd`-advertised symbol set with a hand-rolled regex, and it reported ~180
symbols unsatisfied — including `_malloc`, `_memcpy` and `_objc_msgSend`, which
are obviously present. The regex mis-parsed the `.tbd` format. **A list that
looks like a finding and is an artifact of a bad parse is the same failure as a
sweep with no denominator**, so it was discarded rather than reported, and the
closure was measured against the built dylibs instead — the method already
validated in §12.

## 17. The staging-directory enumeration: 19 trees, 1 gate, and a fixed bug still live in 4 of them

§12 found a newer-and-worse artefact parked where a staging script would read it.
Team-lead's question was the right generalisation: **which artefact directories
exist, and which gate looks at each one?** Nobody knew that denominator. Now:

```
roots examined:                    5
shell scripts scanned:           107     (292 skipped by named exclusions)
scripts that copy a built binary: 11
individual copy sites:            26
directories holding 2+ dylibs:    19
directories any gate looks at:     1
```

`scripts/enumerate_staging.sh` is the sweep; it prints that denominator every
run, and it *discovers* both the copy sites and the destination trees rather
than grading a list — because every gate we have grades a list someone happened
to write down, which is the failure mode itself.

### The result

`machorun/darwin/usr/lib` is the one gated tree (`check_stale.sh`, which grades
6 paths; `gen_tbd.sh` CHECK 4; objc44 and swift_gate run its dylibs). Everything
else is ungated. Most of that is harmless — build output dirs and fixture bins.
**Five are not.**

`~/swift-macho-linux/scratch/` holds **five independent full copies** of
machorun's Darwin userland — `mrroot`, `mrroot2`, `mrroot_full`, `mrroot_isa`,
`mrroot_prefix` — each a runtime tree that guests are actually executed against
via `MACHORUN_ROOT`. Measured against machorun's current `darwin/usr/lib`:

```
scratch/mrroot_full     5/5 dylibs differ
scratch/mrroot_isa      5/5 dylibs differ
scratch/mrroot_prefix   5/5 dylibs differ
scratch/mrroot          5/5 dylibs differ
scratch/mrroot2         5/5 dylibs differ
--> 5 of 5 are stale, and no gate looks at any of them
```

**And the staleness is not cosmetic.** Resolving `malloc_type_malloc` *by symbol*
in each — not by file offset, since a byte at an address is not proof it is the
same function:

```
machorun/darwin/usr/lib   b  ... symbol stub for: _glibc_malloc   <- current, correct
scratch/mrroot_isa        b  ... symbol stub for: _malloc         <- pre-fix
scratch/mrroot_prefix     b  ... symbol stub for: _malloc         <- pre-fix
scratch/mrroot            b  ... symbol stub for: _malloc         <- pre-fix
scratch/mrroot2           b  ... symbol stub for: _malloc         <- pre-fix
scratch/mrroot_full       (does not define the symbol at all)     <- older still
```

**The malloc_type defect that cost this project a week is still live, on disk, in
four runtime trees, right now.** swift-loader-fixes warned about `mrroot`
specifically; the sweep found three more they had not checked, and confirmed
theirs.

`run_machorun.sh` does `rm -rf` and re-copies, so a tree is fresh *while it runs*
— the rot is in the copies left behind between runs, which the next reader
reasonably assumes are current. Every git-level check says the tree is current,
because these directories are not in git.

### Two recommendations, in order of value

1. **Delete the four unused roots, keep one.** Five copies of a userland is five
   things to keep fresh; `run_machorun.sh` rebuilds its own on every run, so the
   leftovers have no consumer. Deletion beats freshening, for the same reason
   deleting the duplicate symbols beat correcting them.
2. **Point `check_stale.sh` at discovered trees, not a list.** It grades 6
   hardcoded paths. A copy tree it has never heard of is the case it cannot see.

### A fourth instance of one bug, caught by the rule this time

Measuring those trees, my first loop printed **`0 of 0 copy-trees are stale`** —
a `find -maxdepth 3` that could not reach a path four levels down, so the body
never executed. That is the **fourth** zero tonight produced by a loop that did
not run (a zsh `[ "$a" \< "$b" ]` that errored, a refusal shadowed by
`set -o pipefail`, a `.tbd` regex whose character class omitted uppercase and so
reported 6 gated paths as 2, and this).

The difference is that this one announced itself: **because the count was
printed next to the verdict, `0 of 0` was obviously not `0 of 5`.** Every earlier
instance printed only the verdict and read as good news. That is the denominator
rule paying for itself inside the sweep written to apply it.

Worth naming the direction: **all four bad measurements erred toward a smaller,
tidier, more reassuring number.** None of them ever invented a problem.
