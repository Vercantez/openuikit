# RUNTIME — Swift, C-interop and drawing, running under machorun

**Date:** 2026-08-26. **Question the SPIKE left open:** rung 4 *compiles* but
does not *run*, because "the Swift runtime dylib does not exist as a file on
either operating system." **Answer: it does exist, machorun's loader can host
it, and a Swift program now draws under machorun byte-for-byte identical to
native macOS.**

```
build/macos/quartz_swift_macos.png   sha256 96aa747a…  (Apple swiftc, native)
build/linux/quartz_swift_linux.png   sha256 96aa747a…  (Linux swiftc, machorun)
machorun/tests/expected/15_quartz.png sha256 96aa747a… (the C fixture baseline)
```

All three are the same 26 861-byte PNG. The Swift program, the C program, macOS
and Linux all agree to the byte.

---

## 1. The SPIKE's central premise was wrong

The SPIKE looked at the macOS shared cache (arm64e) and the x86_64
back-deployment copies and concluded no arm64 `libswiftCore.dylib` exists. It
missed the **iOS Simulator runtime**, which runs plain arm64 (no PAC):

```
…/iOS 26.1.simruntime/…/RuntimeRoot/usr/lib/swift/libswiftCore.dylib
    arm64 Mach-O, 8.78 MB, Swift 6.2, LC_BUILD_VERSION IOSSIMULATOR,
    LC_DYLD_CHAINED_FIXUPS ptr-format 6 / import-format 1  (both machorun-supported)
```

`libswiftObjectiveC.dylib` and `libswift_Concurrency.dylib` are there too. These
stage into a machorun guest root as-is; nothing is un-signed or rewritten.

## 2. What runs

| probe | what it exercises | under machorun |
|---|---|---|
| `libspike` / `spike_main` | pure Swift → Int | **PASS** (already did) |
| `hello` | `print`, String interpolation, `[Int]`, `map`, `reduce`, closures | **PASS** |
| `objc_probe` / `objc_main` | `@objc` `NSObject` subclass, `#selector`, `responds(to:)`, message send | **PASS** — `objc_probe=3`, identical to macOS |
| `quartz_draw` / `quartz_main` | **Swift stdlib + Swift→C interop + quartz rasteriser + PNG** | **PASS — byte-identical PNG** |

The quartz program is the Swift twin of `machorun/tests/src/15_quartz.c`: nine
drawing stages (flat + alpha fills, cubic bezier, dashed round-cap stroke,
linear + radial gradients, a `cos/sin` rotation, an even-odd clip) with per-stage
FNV-1a checksums. Every stage checksum matches macOS exactly.

## 3. No ABI surprise at the Swift→C boundary

`QZRect` (four doubles) and `QZPoint` (two doubles) are passed **by value**
across the Swift→C Darwin boundary. On arm64 these are homogeneous-float
aggregates carried in `v0–v3` / `v0–v1`; Swift's Clang importer emits the AAPCS64
HFA calling convention and the pixels come out identical to the C fixture. The
struct-by-value CGRect-like case the task flagged as a risk is a non-event here —
the byte-identical PNG is the proof.

## 4. What it took: runtime provisioning, not compiler work

machorun's loader mapped the 8.78 MB `libswiftCore` and ran all its
initializers on the first try. Getting from there to a running program was a
ladder of **userland gaps**, each fixed in a shim staged into the guest root —
machorun's own source was never touched. The shims are two *umbrella* dylibs:
each renames machorun's real dylib to `*.real.dylib` and `LC_REEXPORT_DYLIB`s it
(machorun searches a bound image's reexport deps but does not chase per-symbol
trie reexports), adding only the missing symbols.

- **`spike/fckstub.c` → Foundation / CoreFoundation stubs.** The sim
  `libswiftCore` lists both frameworks as ordinary `LC_LOAD_DYLIB`s and imports
  exactly 8 symbols from them, all on error/String-bridging paths a drawing
  program never reaches. Loud-abort stubs, so they exist for binding and shout
  if ever entered.

- **`spike/cxxpatch.cpp` → `libc++.1.dylib` umbrella (+5 symbols).**
  `__libcpp_verbose_abort`, `__cxa_demangle`, `__gxx_personality_v0` (abort/EH,
  stubbed), `std::thread::hardware_concurrency` (real), and
  `operator+(const char*, string)` (real, via explicit template instantiation
  from the same LLVM-18 headers, so it is libc++'s own code).

- **`spike/syspatch.c` → `libSystem.B.dylib` umbrella (+47 symbols).** The
  interesting ones:
  - **`_dyld_lookup_section_info` — the crux.** machorun's loader implements
    this with an *objc-only* `dyld_section_kind` enum (0 = `__objc_classlist`).
    The sim `libswiftCore` was built against a newer `dyld_priv.h` whose enum
    puts Swift sections **first** (measured from libswiftCore's own callback
    symbols: 0 = `__swift5_protos`, 1 = `__swift5_proto`, 2 = `__swift5_types`,
    3 = `__swift5_replace`, 4 = `__swift5_replac2`, 5 = `__swift5_acfuncs`).
    Both objc4 and libswiftCore call the *same* function with *incompatible*
    enums, so one static table cannot serve both. The shim disambiguates by the
    **caller's return address** → its mach header → `LC_ID_DYLIB`: `libswift*`
    gets the Swift enum, everything else the objc enum. Without this, Swift's
    conformance/type-metadata registration reads objc sections as Swift records
    and dies with a wild pointer.
  - **`dispatch_once_f` — per-token, not a shared lock.** The Swift runtime
    nests `swift_once` on *different* tokens; a single global mutex deadlocks the
    instant the once-body enters a second once. A per-token CAS state machine
    (`0 → RUNNING → DONE=~0l`) has no cross-token lock. (This one cost a
    `print`-hangs-forever afternoon.)
  - **reserved-key TLS.** `libswiftCore`'s `tls_init_once` claims Darwin
    reserved pthread key **100** and registers a destructor with
    `pthread_key_init_np(100, …)`; machorun caps direct-TSD at 64 and returns
    `EINVAL`, so Swift aborts *"tls_init_once() failed to set destructor."* The
    shim services keys ≥ 100 out of a `__thread` array and delegates normal keys
    to glibc (machorun's `_glibc_` bridge). This is what unblocked both the
    `@objc` probe and the full drawing.
  - **real `pthread_get_stackaddr_np` / `_stacksize_np`.** A faked 8 MB stack
    whose high end is a round-up of the current SP lands *above* the real
    mapping; Swift then treats heap metadata as a stack scratch buffer and writes
    past the stack top — a SIGSEGV in `swift_initClassMetadataImpl`. The shim
    reports the true bounds via glibc `pthread_getattr_np`.
  - **`getsectiondata`, `_NSGetMachExecuteHeader`, `malloc_type_*`, the
    `strtod_l` family, compiler-rt `__divti3`/`__udivti3`/…**, and the dyld
    shared-cache SPIs (`_dyld_find_protocol_conformance`, …) stubbed to *"no
    preoptimized data"* — which is the **truth** under machorun, so Swift falls
    back to scanning the sections `getsectiondata` hands it.

## 5. One wall left, and the workaround

Runtime instantiation of a **non-prespecialized generic class metadata** still
crashes in `swift_initClassMetadataImpl`. Concretely: `[Int]` is prespecialized
in the shipped stdlib and works; `[Double]` is not, must be instantiated at
runtime, and dies. The nine-stage fixture wants `[Double]` gradient/dash arrays,
so it uses raw `UnsafeMutablePointer<Double>` buffers instead — which touch no
storage-class metadata — and the drawing itself, the point of the program, runs
to a byte-identical PNG. This is the next runtime-provisioning item, not a
compiler problem, and it does not touch the interop or rasterisation result.

## 6. Reproducing

```
# once: build machorun and the image
(cd ~/machorun && scripts/build.sh everything)          # build/machorun, darwin/*.dylib, libquartz
docker build -t swift-macho-spike:noble harness/         # now includes libc++-18-dev

# macOS: stage the SDK interfaces + ObjectiveC module (as in the SPIKE)
scripts/stage_darwin_swift.sh
scripts/stage_objc_module.sh

# the runtime + the drawing
mkdir -p scratch/real && cp ~/machorun/darwin/usr/lib/{libSystem.B,libc++.1}.dylib scratch/real/
docker run --rm -v "$PWD:/w" -w /w swift-macho-spike:noble bash scripts/build_runtime_shims.sh
scripts/stage_swift_runtime.sh                           # macOS: assemble scratch/mrroot
docker run --rm -v "$PWD:/w" -w /w swift-macho-spike:noble bash scripts/build_quartz.sh
scripts/build_quartz_macos.sh                            # macOS: the oracle PNG
scripts/run_quartz.sh                                    # machorun + byte-for-byte diff
```

`scratch/` and `build/` are gitignored; `scratch/mrroot` is a copy of
`~/machorun/darwin` plus the loader plus the staged runtime — this repository
never writes into `~/machorun`.
