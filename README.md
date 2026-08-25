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

Bootstrapping. See `docs/PORT_PLAN.md`.

## Licence

Apple's objc4 is APSL 2.0 (`vendor/objc4/APPLE_LICENSE`). Our patches and
harness follow suit to keep the combined work coherent.
