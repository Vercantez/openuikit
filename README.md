# objc4-linux

A port of **Apple's Objective-C runtime** (`objc4`) to Linux/ELF.

Not a reimplementation, and not GNUstep's `libobjc2`. This is Apple's actual
runtime source — the one whose ABI Swift's compiler emits — made to build and
run on Linux.

## Why

Swift's `swiftc` already emits Apple-objc4 class metadata and ELF
`objc_classlist` sections when built with `-enable-objc-interop`, on Linux, on
a stock toolchain. What is missing is a runtime that understands that metadata.
`libobjc2` cannot: it implements the GNUstep ABI, a structurally different
`struct objc_class`, and it does not ship the private `<objc/objc-internal.h>`
surface the Swift runtime calls (notably `objc_readClassPair`, which is not
weak-linked). Apple's objc4 *is* that runtime, and it already contains every
one of those symbols.

Measured evidence for all of the above lives in the sibling project
`~/uikit` (`docs/OBJC_RUNTIME.md`, `Tools/objcshim/stdlib_interop_probe.sh`).

## Scope, honestly

**In scope:** objc4 building and running on Linux/aarch64 (then x86-64) —
class and metaclass realization, selector registration, message dispatch and
caching, categories, protocols, ivars and properties, ARC entry points, weak
references, associated objects, exceptions, and image discovery via ELF
instead of Mach-O.

**Explicitly out of scope:** Foundation, CoreFoundation, and any bridging
layer. Those are separate problems (GNUstep's `libs-base` and `libs-corebase`
are the candidates) and this project does not pretend to solve them.

**The honest caveat about the motivating goal:** a working objc4 on Linux is
*necessary but not sufficient* for Swift ObjC interop there. Building the
Swift stdlib with interop also requires an Objective-C Foundation and
CoreFoundation whose *internals* match what Swift's bridging code expects
(`_CFStringGetCStringPtr`, `__SwiftValue`, `_SwiftNativeNSArrayBase`).
GNUstep provides those APIs with different internals. That step is not
attempted here and its cost is unknown until this one exists. This project is
worth doing on its own merits — portable Objective-C with Apple's semantics
does not currently exist — and Swift interop is a possible follow-on, not a
promise.

## Method: differential testing against the real runtime

The same discipline that built `~/uikit`: **never hand-verify, always diff
against the real thing.**

macOS has real objc4. Every behaviour we implement gets a test program that
compiles and runs against **both** the system runtime on macOS and our port on
Linux, and the outputs must match exactly. Class layouts, method resolution
order, `+load`/`+initialize` timing, category override precedence, edge cases
in `respondsToSelector:` — all of it is measured from the real runtime rather
than read from documentation.

```
tests/       behaviour tests, each runnable on both sides
harness/     runners: macOS (system runtime) and Linux (our libobjc.so)
scripts/     build + differential-compare entry points
vendor/objc4 Apple's source (APSL 2.0), unmodified where possible
patches/     our diffs against vendor, one per concern, documented
```

Vendored objc4 stays pristine; every change lands as a reviewable patch so
upstream drops can be re-applied.

## Status

**It runs.** On Linux/aarch64, with our `libobjc.so` and no Foundation:

```
44 tests: 44 PASS, 0 FAIL, 0 SKIPPED
```

Every one of those is the same source file compiled twice — once against
Apple's shipping runtime on macOS 26.1/arm64, once against ours on Ubuntu
24.04/aarch64 — with the two outputs required to be byte-identical. That
number has been **independently re-verified from a clean clone**; the audit,
including what it found outside the corpus, is `docs/STATUS.md`.

What the 44 cover: root classes and metaclass chains, selector registration
and uniquing, message dispatch and the method cache, `+load` and `+initialize`
ordering, categories (including collision precedence), protocols, ivars and
non-fragile layout, properties, dynamic class creation and disposal, ARC entry
points, autorelease pools, weak references, associated objects, type
encodings, method resolution and forwarding, `@synchronized`, exceptions —
including throwing out of `+initialize` and out of a method resolver, which
unwinds through the hand-written assembly — **multi-image programs**, images
arriving by **`dlopen` after startup**, and eight threads contending on all of
the above.

The mechanism that made it run: `dl_iterate_phdr(3)` plus each image's on-disk
ELF section header table, feeding objc4's existing `map_images`/`load_images`
unchanged. Section names are the Mach-O ones with `__` stripped —
`objc_classlist`, `objc_selrefs`, `objc_catlist` and the rest — and `swiftc
-Xfrontend -enable-objc-interop` emits the same ones (re-measured on swiftc
6.2.4: `objc_classlist`, `objc_imageinfo`, identical to clang's), which is the
whole point.

```
./scripts/build_linux.sh              # clean checkout -> libobjc.so, in Docker
./scripts/build_linux.sh inventory    # per-translation-unit PASS/FAIL + link + load
./scripts/difftest.sh                 # both sides, byte-compare, print the table
```

**What does not work**, ranked, with measurements rather than adjectives:

* **Tagged pointers are enabled and broken.** `SUPPORT_TAGGED_POINTERS=1` is
  compiled in, but the same source that prints `class=TR` / `dispatch=42` on
  macOS prints `class=(nil)` and then segfaults here, and
  `_objc_registerTaggedPointerClass` lands the class in a different table
  slot. Nothing in the corpus touches them.
* **`imp_implementationWithBlock` aborts loudly** — the trampoline assembly is
  not in the vendored tree and has to be written from scratch.
* **The method cache never frees garbage.** Now quantified: ~8.7 KB leaked per
  cache invalidation, unbounded. A swizzling workload that costs macOS 4.7 MB
  of peak RSS costs this port 177 MB.
* **x86-64 is not started** — CMake accepts the arch, warns, and builds with
  no messenger at all.
* **The corpus reaches 44% of the exported surface.** 175 public entry points
  are never touched by any test. Full ARC codegen, objc4's own `NSObject`, and
  ARC return-value elision were all untested; all three were probed during the
  audit and match macOS byte for byte, but they passed by luck, not by test.

Read `docs/STATUS.md` for the audit and the ranked roadmap, and
`docs/UNIMPLEMENTED.md` for every hole, every disabled feature with its cost,
and the assumptions that could still be silently wrong. See also
`docs/PORT_MAP.md`, `docs/PORT_PLAN.md`, `docs/ABI_DIVERGENCE.md` and
`docs/TESTING.md`.

On the motivating goal: the ELF section names Clang and Swift emit **do**
agree, which was the load-bearing bet. But an interop-enabled Swift file will
not link against this runtime yet — it references
`OBJC_CLASS_$__TtCs12_SwiftObject`, and the Linux-shipped `libswiftCore.so`
contains zero ObjC class symbols and zero `objc_*` imports. Swift interop
needs the standard library rebuilt with interop, which needs a Foundation that
does not exist. `docs/STATUS.md` §5 has the measurements.

## Licence

Apple's objc4 is APSL 2.0 (`vendor/objc4/APPLE_LICENSE`). Our patches and
harness follow suit to keep the combined work coherent.
