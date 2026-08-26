# SPIKE — Swift → Mach-O on Linux

**Date:** 2026-08-26. **Question:** can a Linux-hosted Swift toolchain build a
Mach-O dylib for `arm64-apple-macos`, so Swift — eventually OpenUIKit — can
join the machorun stack?

**Answer: yes, and further than expected.** Four of the four rungs are clear on
the *build* side, including Objective-C interop. Three of four are clear on the
*run* side. The one wall is not a compiler problem at all: it is that the Swift
runtime dylib does not exist as a file anywhere, on either operating system.

Oracle host: macOS 26.5, Apple Swift 6.2.1, arm64. Target bed: Ubuntu noble in
Docker, Swift 6.2.4, arm64 native — no CPU emulation.

---

## The ladder

| # | | build | run |
|---|---|---|---|
| 1 | trivial pure Swift → Mach-O object | **PASS** | — |
| 2 | link a Mach-O dylib with `ld64.lld-18` | **PASS** | — |
| 3 | run it under machorun, matching macOS | **PASS** | `spike_answer=42` |
| 4 | `@objc` / `#selector` in this configuration | **PASS** | **WALL** — no `libswiftCore.dylib` |
| + | breadth: generics, protocols, collections, closures, async | **PASS** | **WALL** — same one |

`scripts/difftest.sh`, run on the Mac:

```
spike_main     PASS  (exit 0)
               spike_answer=42
objc_main      PASS  (exit 0)
               objc: class=SpikeObjC.SpikeCounter sel=bump responds=true value=3
               objc_probe=3
breadth_main   PASS  (exit 0)
               View Rect(0.0, 0.0, 100.0, 50.0); View Rect(0.0, 0.0, 5.0, 5.0); View Rect(10.0, 0.0, 5.0, 5.0); View Rect(20.0, 0.0, 5.0, 5.0) edges=[0, 1, 2, 3]
               hits=2 responds(layout)=true
               breadth_probe=5
```

Both columns of that test run **natively on macOS**. `build/macos/*` is Apple
swiftc + Apple ld + Apple SDK; `build/linux/*` is the Linux toolchain's output,
copied over unmodified and executed — `ld64.lld-18` already emits a
linker-signed adhoc signature, so nothing was re-signed. Same source, same
machine, two toolchains, byte-identical output.

`scripts/run_machorun.sh`, in the container:

```
---- spike_main
spike_answer=42                                                   exit=0
---- objc_main
machorun: cannot find dylib '/usr/lib/swift/libswiftCore.dylib'   exit=72
---- breadth_main
machorun: cannot find dylib '/usr/lib/swift/libswiftCore.dylib'   exit=72
```

---

## 1. The version skew never happened

The predicted risk was Swift 6.2.1 (Xcode) vs 6.2.4 (container) desyncing the
binary `.swiftmodule` format. It cannot: **the macOS SDK ships zero binary
`.swiftmodule` files.** All 214 module descriptions in
`$(xcrun --show-sdk-path)/usr/lib/swift` are textual `.swiftinterface`,
compiled `-enable-library-evolution`. `Swift.swiftmodule/` contains exactly
four files — an `arm64e-apple-macos` and an `x86_64-apple-macos` interface plus
their `.swiftdoc`.

So the Linux compiler recompiles them. After one build, `scratch/modcache`
holds freshly built `Swift`, `_Concurrency`, `_StringProcessing` and
`SwiftOnoneSupport` binary modules, plus `SwiftShims`/`_SwiftConcurrencyShims`
`.pcm`s built from the **Linux** resource dir. 15 s cold, ~17 MB. The
resilience mechanism `.swiftinterface` exists for is doing exactly its job.

Two details worth keeping:

- `-print-target-info` reports `moduleTriple: arm64-apple-macos` on **both**
  compilers, but the SDK only ships `arm64e-apple-macos.swiftinterface`. The
  compiler falls back arm64 → arm64e for module lookup. It works, it is not
  something we configured, and it is the kind of thing that could change.
- `warning: Could not read SDKSettings.json` on every invocation. Harmless
  here; a real sysroot would carry one.

## 2. What is staged, exactly

`scripts/stage_darwin_swift.sh` + `scripts/stage_objc_module.sh` build
`scratch/sysroot` (gitignored). **15 MB total.**

| what | from | size |
|---|---|---|
| `usr/include` (356 headers), `usr/lib/*.tbd` (7) | `~/machorun/sdk` — no Apple headers | 3.1 MB |
| `usr/lib/swift/` — 214 `.swiftinterface`, 94 `.tbd`, 0 binary modules | Xcode macOS SDK | 12 MB |
| `usr/include/objc/{NSObject,NSObjCRuntime,Protocol}.h` | `~/machorun/vendor/objc4` (Apple OSS) | 60 KB |
| `usr/include/module.modulemap` — module `ObjectiveC` | **ours** | 10 lines |
| `usr/include/ObjectiveC.apinotes` | Xcode macOS SDK | 437 lines |
| `usr/lib/swift/macosx-static/libswiftCompatibility*.a`, arm64-thinned | Xcode toolchain | 64 KB |

Nothing from Xcode's *compiler* is staged — no `swiftc`, no clang, no resource
dir. The Apple dependency is 12 MB of text plus one 437-line YAML file.

The compatibility archives turned out to be **unusable** and are not linked:
they reference `pthread_mutexattr_init`, `pthread_rwlock_*` and `dispatch_once`,
none of which machorun's `libSystem.tbd` exports. They are back-deployment
shims for macOS < 12 and this target is `macos11`+, so
`-runtime-compatibility-version none` costs nothing *here* — but it is a real
gap if anything ever needs them. They are staged so the next person can see
what they cost rather than rediscovering it.

## 3. Objective-C interop is real, and that is the prize

One diagnostic settles it. The same file, `@objc public class NotAnNSObject {}`:

```
arm64-apple-macos11   error: only classes that inherit from NSObject can be declared '@objc'
aarch64-linux-gnu     error: Objective-C interoperability is disabled
```

The Darwin target is arguing about *which* classes may be `@objc`. The Linux
target does not have the feature. This is the thing the ELF approach in
`~/uikit/docs/OBJC_RUNTIME.md` could not buy.

Made concrete in `spike/objc_probe.swift`: an `NSObject` subclass with `@objc`
members, `#selector`, `responds(to:)`, `class_getName`, `sel_getName`, Swift
`String` interpolation and `print`. It compiles on Linux, links to a Mach-O
dylib carrying `__objc_classlist` / `__objc_selrefs` / `__objc_imageinfo`, and
prints output identical to the Apple-built oracle.

`spike/breadth.swift` goes further and also passes: protocols with `AnyObject`
constraints, generics, `Equatable`/`CustomStringConvertible` conformances,
`[String: (View) -> Void]`, escaping closures with captured mutable state,
`sorted(by:)`, key paths, `enum: CaseIterable`, `open dynamic` methods,
`@available`, and `async`/`withCheckedThrowingContinuation`. No stdlib
interface holes found.

Two things had to be right for that:

- **`ObjectiveC.apinotes` is load-bearing.** objc4's published `NSObject.h`
  carries no nullability annotations — and, measured, *Apple's own SDK copy of
  that header is byte-for-byte the same on that point*: `- (instancetype)init`
  is line 66 of both. All of the nullability Swift sees comes from the YAML
  sidecar. Without it `View()` imports as `View!` and idiomatic Swift stops
  compiling. It is data, not code, and could be reimplemented clean-room.
- **`-Xfrontend -disable-objc-attr-requires-foundation-module`**, because we
  deliberately have no Foundation. The Swift stdlib's own interface is built
  with the same flag.

## 4. Two loud failures worth carrying into machorun

**(a) Every Darwin-targeted Swift image needs libobjc, even with no `@objc` in
it.** `libspike.swift` is one line, `func spikeAnswer() -> Int32 { 42 }`, and
its dylib still carries `__objc_imageinfo`. machorun aborted with
`UNIMPLEMENTED: objc-callbacks` until the dylib was linked `-lobjc`. Correct
behaviour by the loader; a permanent fact about Swift on Darwin.

**(b) machorun's `libSystem` exports `_swift_retain` / `_swift_release`, and
that silently poisons any Swift link.** These are the loud-abort stubs of
`docs/UNIMPLEMENTED.md#swift-interop` in `darwin/src/objcsupport.c`, and
`libSystem.tbd` advertises them. Mach-O's two-level namespace records the
*first* dylib on the link line that exports a symbol, so `-lSystem` before
`-lswiftCore` binds Swift's own retain to libSystem. On macOS that resolves to
nothing, the lazy stub is left at 0, and the process takes `EXC_BAD_ACCESS` at
address 0 the first time it retains an object — with a backtrace that points at
your own code, not at the linker. Reordering to `-lswiftCore … -lSystem` fixes
it, and `scripts/build_linux.sh` carries the reason.

This one is worth fixing in machorun rather than working around: as long as the
`.tbd` claims those symbols, every Swift guest is one link-order mistake away
from a null-jump. Restricting them to a non-exported definition, or removing
them from the `.tbd` once a real `libswiftCore` exists, would close it.

## 5. The wall: `libswiftCore.dylib` is not a file

```
machorun: cannot find dylib '/usr/lib/swift/libswiftCore.dylib'
```

Measured facts behind that:

- On this Mac, `/usr/lib/swift/libswiftCore.dylib` **does not exist on disk**.
  `dyld_info` reads it out of the shared cache: `[arm64e]`, minOS 26.5,
  zippered macOS/Catalyst.
- It is **arm64e only**. There is no `dyld_shared_cache_arm64`; asking
  `dyld_info -arch arm64` still returns the arm64e image. machorun rejects
  arm64e at the front door on purpose
  (`docs/UNIMPLEMENTED.md#arm64e`: PAC, `DYLD_CHAINED_PTR_ARM64E`, process-scoped
  signing keys) and that decision looks right — un-signing an arm64e image to
  run under a non-PAC loader is a project, not a patch.
- The only `libswiftCore.dylib` files that *do* exist in Xcode are the
  back-deployment copies in
  `…/XcodeDefault.xctoolchain/usr/lib/swift-5.0/macosx/`. That one is
  **x86_64**, because back deployment targets macOS 10.9–10.14, which was Intel.
  The `iphonesimulator` and `appletvsimulator` copies are x86_64 too. There is
  no arm64 Swift runtime dylib anywhere on this machine.

So the gap is 41 undefined symbols for the small `@objc` probe, in three groups:

- **ObjC runtime** — `_objc_msgSend`, `_objc_retain`, `_OBJC_CLASS_$_NSObject`,
  `_class_getName`, `_sel_getName`, `__objc_empty_cache`. **machorun already
  has all of these**, from objc4 built as `darwin/usr/lib/libobjc.A.dylib`.
- **Swift runtime entry points** — `swift_retain`, `swift_beginAccess`,
  `swift_bridgeObjectRetain`, `swift_isaMask`, `swift_getObjCClassFromMetadata`,
  `swift_getObjectType`. Missing.
- **Swift stdlib types and metadata** — `String` and its metadata, `print`,
  `DefaultStringInterpolation`, `Int32` metadata, protocol witness tables,
  `_allocateUninitializedArray`. Missing.

Encouraging detail for whoever builds it: the shared-cache `libswiftCore`'s
**non-lazy** dependencies are only `libc++.1`, `libSystem.B`, `libobjc.A` and
`libswiftPrespecialized`. Foundation and CoreFoundation are `upward delay-init`
and `delay-init` — bound only if used. machorun already provides three of those
four. A Foundation-free `libswiftCore` is not obviously unreasonable.

## 6. Recommendation

**Provisioning the Darwin stdlib is enough to build. It is not enough to run.**
A full cross *toolchain* is **not** needed — the stock `swift:6.2-noble` image
already is one. What is needed is one artifact: `libswiftCore.dylib` as an
**arm64 (not arm64e) Mach-O**, plus `libswiftObjectiveC.dylib` and, if you want
`async`, `libswift_Concurrency.dylib`.

Three ways to get it, ranked:

1. **Build the Swift 6.2.4 stdlib from source for `arm64-apple-macos`, in the
   container, machorun-style.** This is the same shape of work machorun already
   did for objc4: vendor the sources, drive `clang-18` / `swiftc-6.2.4` /
   `ld64.lld-18` from a script, patch what does not compile, keep the patch
   count honest. It is strictly bigger than objc4 — objc4 is ~30 C++ TUs and
   took 4 patches, whereas the stdlib is a C++ runtime of comparable size *plus*
   several hundred Swift sources that must be compiled with exactly the right
   resilience flags, *plus* gyb code generation. **Estimate: 1–3 weeks.** The
   payoff is that it also deletes the Xcode dependency in §2 — a stdlib we built
   comes with its own `.swiftinterface`, so `scratch/sysroot` stops needing
   Apple's.
2. **Build it on macOS from swift.org source with `build-script`, targeting
   arm64, and stage the resulting dylib** the way §2 stages the interfaces.
   Much less novel work — this is a supported configuration — but hours of build
   time, tens of GB, and it keeps a large Apple-toolchain dependency.
   **Estimate: 1–2 days, mostly waiting.** Good as a *bring-up* step: it would
   unblock rungs 4-run immediately and tell you whether machorun's loader can
   host the Swift runtime at all, before anyone spends three weeks on option 1.
3. **Extract from the dyld shared cache.** `/usr/lib/dsc_extractor.bundle`
   exists and would work mechanically, but yields arm64e. Dead end unless
   machorun reverses its arm64e decision, which it should not.

The honest sequencing is **2 then 1**: use the macOS-built dylib to answer
"does machorun's loader survive the Swift runtime?" in a day, and only then
decide whether to pay for a self-hosted build.

One escape hatch measured and rejected for our purposes: **Embedded Swift
works.** `-target arm64-apple-none-macho -enable-experimental-feature Embedded`
emits a Mach-O object on Linux with no runtime dylib at all. It cannot be used
with the Darwin SDK stdlib (`module 'Swift' cannot be imported in embedded Swift
mode`), and it has no Objective-C interop, no existentials and no reflection —
so it cannot express UIKit-shaped dynamic dispatch. Worth knowing it exists.

## 7. What this means for OpenUIKit

The compile-side question is settled and the answer is good. OpenUIKit's Swift
can be built on Linux, for Darwin, as Mach-O, **with real Objective-C interop**
— `@objc`, `#selector`, `NSObject` subclassing, `dynamic`, message sends — and
the breadth probe says the language does not run out from under you at
generics, protocols, collections, closures or async.

Three consequences:

- The remaining work is **runtime provisioning, not compiler work**. That is a
  much better place to be than the ELF dead end, and it is bounded: one dylib.
- The `libSystem` `_swift_retain` collision in §4(b) will bite the moment a real
  `libswiftCore` shows up, and should be fixed first — it is a ten-minute
  change that saves a day of debugging a null jump.
- OpenUIKit would talk to `~/quartz` and `libobjc` through the same Mach-O
  boundary the rest of the stack already uses, with no Swift-side special
  casing, because the ObjC interop is genuine rather than emulated.

---

## Reproducing

```
scripts/stage_darwin_swift.sh          # macOS: build scratch/sysroot
scripts/stage_objc_module.sh           # macOS: add the ObjectiveC module
docker build -t swift-macho-spike:noble harness/
docker run --rm -v ~/swift-macho-linux:/w -w /w swift-macho-spike:noble \
    bash scripts/build_linux.sh        # the whole Linux side
scripts/build_macos.sh                 # macOS: the oracle
scripts/difftest.sh                    # macOS: the differential
scripts/run_machorun.sh spike_main objc_main breadth_main
```

`scratch/mrroot` is a copy of `~/machorun/darwin` plus `build/machorun`; this
repository never writes into `~/machorun`.
