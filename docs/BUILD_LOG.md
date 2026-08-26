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
dereferences it. Disassembly of our own artifact, fault site marked:

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
