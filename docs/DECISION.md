# The Foundation architecture decision

**Date:** 2026-08-26
**Status:** decided, and the decisive risk is retired by a working build.

---

## 0. The decision in one paragraph

Build Foundation as **option D — our own Foundation over a CoreFoundation we
control — using swift-corelibs-foundation's CoreFoundation C sources as that CF
layer, with its stubbed-out Objective-C toll-free-bridging macros restored.** The
Objective-C `NS*` classes and the Swift overlay are ours. Deployment mode is the
**Darwin one (ObjC runtime)**, which is not a corelibs build option but is what
our stack already is.

Options A, B and C are ruled out, each for a specific measured reason, in §4.

The load-bearing reason this is tractable at all: **the Swift standard library's
dependency on Foundation is a runtime contract, not a link-time one.** It is 128
selectors, 6 class names, and 4 C functions found by `dlsym`. All of it is ours
to satisfy. §1 is the measurement; §2 is the proof that satisfying it works.

---

## 1. What libswiftCore actually requires of Foundation

Everything here is measured against
`~/swiftcore-macho/artifacts/swift-macosx/arm64/libswiftCore.dylib` — the Swift
6.2.4 stdlib built for `arm64-apple-macos` on Linux.

### 1.1 It links no Foundation and no CoreFoundation

```
$ otool -L libswiftCore.dylib
    /usr/lib/libSystem.B.dylib
    /usr/lib/libobjc.A.dylib
    /usr/lib/libc++.1.dylib
```

Of 185 undefined symbols, the only `NS` ones are `_OBJC_CLASS_$_NSObject` and
`_OBJC_METACLASS_$_NSObject`, **which objc4 itself provides**. There is not one
undefined `CF*` symbol. Every `CFString`-named entry point the stdlib uses
(`_stdlib_binary_CFStringGetLength`, `_swift_stdlib_CFStringHashNSString`, …) is
*defined inside libswiftCore* and implemented with `objc_msgSend`.

This is the fact that makes the whole project possible, and it is the opposite of
the situation that killed the Linux-target experiment in
`~/uikit/docs/OBJC_RUNTIME.md`.

### 1.2 Six classes, re-parented at runtime

`swift_stdlib_connectNSBaseClasses` (disassembled) looks up exactly six classes
with `objc_lookUpClass` and calls `class_setSuperclass` to re-parent the stdlib's
own base classes onto them:

| looked up | becomes superclass of |
|---|---|
| `NSArray` | `__SwiftNativeNSArrayBase` |
| `NSMutableArray` | `__SwiftNativeNSMutableArrayBase` |
| `NSDictionary` | `__SwiftNativeNSDictionaryBase` |
| `NSSet` | `__SwiftNativeNSSetBase` |
| `NSString` | `__SwiftNativeNSStringBase` |
| `NSEnumerator` | `__SwiftNativeNSEnumeratorBase` |

If any lookup fails the function returns 0, and the caller
(`String._bridgeToObjectiveCImpl`) takes a `_fatalErrorMessage` path. So all six
must exist before any bridging happens.

**These six must have no ivars.** `class_setSuperclass` preserves the subclass's
ivar offsets only if the new superclass has the same instance size as the old one
(`NSObject`, 8 bytes). This is not a simplification we chose — it is *why Apple
makes them class clusters*, and any Foundation on this stack inherits the
constraint. Storage must live in concrete subclasses.

### 1.3 128 selectors

`__TEXT,__objc_methname` in libswiftCore is 2,293 bytes — 128 selectors. That is
the entire Objective-C surface the stdlib touches. The interesting ones:

- **CF identification:** `_cfTypeID`
- **class identification SPI:** `isNSString__`, `isNSArray__`, `isNSDictionary__`,
  `isNSSet__`, `isNSNumber__`, `isNSData__`, `isNSDate__`, `isNSValue__`,
  `isNSTimeZone__`, `isNSOrderedSet__`, `isNSObject__`, `isNSCFConstantString__`
- **tagged-string SPI:** `newTaggedNSStringWithASCIIBytes_:length_:`,
  `newIndirectTaggedNSStringWithConstantNullTerminatedASCIIBytes_:length_:`
- **`__SwiftValue` boxing:** `_swiftValue`, `_swiftTypeMetadata`, `_swiftTypeName`
- **NSError bridging:** `_domain`, `_code`, `_userInfo`, `domain`, `code`, `userInfo`
- **string primitives:** `length`, `characterAtIndex:`, `getCharacters:range:`,
  `_fastCStringContents:`, `_fastCharacterContents`, `compare:options:range:locale:`,
  `decomposedStringWithCanonicalMapping`, …
- **collection primitives:** `count`, `objectAtIndex:`, `objectForKey:`, `member:`,
  `countByEnumeratingWithState:objects:count:`, `getObjects:andKeys:count:`, …

128 is a small, closed, enumerable number. That is the good news of this scope.

### 1.4 Four CoreFoundation functions, resolved by `dlsym`

This one is easy to miss and would have been a late surprise. The `swift_once`
initialiser behind `_swift_stdlib_isNSString` does:

```
dlsym(RTLD_DEFAULT, "CFStringGetTypeID")
dlsym(RTLD_DEFAULT, "CFGetTypeID")
dlsym(RTLD_DEFAULT, "CFStringHashNSString")
dlsym(RTLD_DEFAULT, "CFStringHashCString")
```

and then **calls the pointers unconditionally** — no null check. So a real
CoreFoundation exporting these must be loaded, or the stdlib jumps to NULL.
`isNSString(obj)` is `CFGetTypeID(obj) == CFStringGetTypeID()`.

Two of the four (`CFStringHashNSString`, `CFStringHashCString`) are Apple-private
CF SPI. **Both exist in corelibs' CF** (`CFString.c:1185`, `:1195`, declared in
`include/ForFoundationOnly.h`). That is a meaningful point in corelibs' favour as
the CF layer.

### 1.5 The conformance the stdlib deliberately withholds

`String : _ObjectiveCBridgeable` **does not appear anywhere in libswiftCore's
`.swiftinterface`**, though the `_ObjectiveCBridgeable` protocol does, and so does
`public func String._bridgeToObjectiveCImpl() -> AnyObject`.

So the stdlib ships the entire bridging *engine* and none of the *conformance*
that starts it. Foundation-on-this-stack is therefore two separable halves:

1. Objective-C classes answering the runtime contract (§1.2–§1.4)
2. a Swift overlay declaring the conformances

Both are ours to write, and neither needs Apple's closed Foundation.

---

## 2. The proof

`scripts/run_tests.sh`, run under machorun, diffed against baselines captured
natively on **macOS 26.5.2 arm64 with Apple's real Foundation**
(`scripts/oracle_macos.sh`):

```
==> t1_objc (Objective-C against the slice)
PASS      t1_objc
==> t2_bridge (Swift <-> ObjC bridging)
PASS      t2_bridge

pass 2  fail 0  no-oracle 0
```

Both are true differentials: the same sources compile on both sides (`t1_objc.m`
picks up Apple's headers via `__has_include`; `t2_bridge.swift` is ordinary
Foundation API). Byte-identical output.

`t2_bridge` is the test the brief asked for, and it passes:

```swift
let s = "hi" as NSString          // nsstring.length=2
let a = NSArray(array: [1, 2, 3]) // nsarray.count=3
```

plus the reverse direction (`NSString as String`), a non-ASCII round trip
(`"café"`), `String` elements bridged inside an `NSArray`, and `is`/`as!` dynamic
casts across the bridge.

What is built: `libFoundationSlice.dylib` (Objective-C — NSString, NSArray,
NSMutableArray, NSDictionary, NSSet, NSEnumerator, NSNumber, and the four CF
functions) and `libFoundation.dylib` (the Swift overlay), both **Darwin Mach-O
arm64, produced on Linux** with `clang`/`swiftc -target arm64-apple-macos13.0`
and `ld64.lld-18`, against machorun's SDK, Apple's objc4 and our libswiftCore.

Apple's real `CFStringGetTypeID()` is 7 and our slice returns 7 — the type-ID
numbering we took from corelibs' `CFRuntime_Internal.h` matches Apple's.

### 2.1 Four walls hit, and what each one teaches

These are the substance of the scope; each is a thing the full build would have
hit later and more expensively.

**(a) `+[__StringStorage newTaggedNSStringWithASCIIBytes_:length_:]`
unrecognized selector.** Bridging a *short ASCII* string sends this Apple-private
SPI to the stdlib's own class, which inheritance routes to `NSString`. The stdlib
does **not** check `respondsToSelector:`, so the method must exist. Reading the
call site: a non-nil result is used *as the bridged object with no tag checking*,
so returning an ordinary +1 string is valid — real tagged pointers are a
performance question, not a correctness one. Returning **nil** is not safe: it
takes Apple's back-deployment path (`_StringGuts.grow(16)` then recurse), which
did not terminate on our stack.

**(b) The class-cluster allocator.** Swift does not emit `+alloc`; it emits
`objc_allocWithZone`, which objc4 only routes to a custom **`+allocWithZone:`**.
Overriding only `+alloc` silently produced instances of the *abstract* class,
surfacing as `-[NSArray initWithObjects:count:] unrecognized selector`. Every
cluster class needs both.

**(c) `swift_bridge` needs a fully-qualified name.** For `-isEqualToString:` to
import as `isEqual(to: String)` the way it does on macOS, `NSString` needs
`__attribute__((swift_bridge("Swift.String")))`. With the bare `"String"`,
ClangImporter **silently ignores the attribute** — no diagnostic, the signature is
just quietly wrong. Apple does not put this in the header at all; it is injected
by `Foundation.framework/Headers/Foundation.apinotes` as `SwiftBridge:
Swift.String`. The full Foundation should ship an apinotes file rather than
scatter attributes.

**(d) The address-space wall — see §3.** This one is not ours.

---

## 3. A dependency on machorun: libswiftCore's inlined `ISA_MASK`

**This is the most important cross-cutting finding and it belongs to machorun,
not to Foundation.**

libswiftCore has Apple's arm64 `ISA_MASK = 0x00007ffffffffff8` (47 bits) inlined
into `swift_unknownObjectRetain`, `swift_unknownObjectRelease`,
`swift_getObjectType` and others, where it masks an isa and then reads
`class->bits` at `+0x20`.

machorun maps images with `mmap(NULL, …)`, and aarch64 Linux allocates top-down
from 2^48, so classes land at `0xffff…`. Masking truncates them. Measured:

```
NSString class      = 0xffff86413c88
raw isa word        = 0x100ffff86413cd9
isa & ISA_MASK      = 0x7fff86413cd8     <-- wrong, bit 47 lost
```

and Swift then faults reading `0x7fff86413cd8 + 0x20`. Symptom: `SIGSEGV` in
`swift_unknownObjectRetain` / `swift_getObjectType`.

objc4 does not hit this because machorun already patches it
(`patches-macho/0001-wide-va-isa-layout.patch`) to the wide 52-bit arm64e isa
layout. **libswiftCore cannot be patched the same way** — the mask is baked into
compiled code in many places, and rebuilding the stdlib with a custom mask would
fork it from upstream permanently.

**Workaround in use:** `ulimit -s unlimited` switches Linux to the legacy
bottom-up mmap layout, which allocates from `TASK_SIZE/3` upward. Classes then
land at `0x4000…`, below 2^47, and both runtimes agree. Measured: with it, both
tests pass; without it, `t2_bridge` dies with SIGSEGV. `scripts/run_tests.sh`
sets it.

**The real fix belongs in machorun:** map images below 2^47 explicitly rather
than relying on a process-wide `ulimit`. `src/map.c` already reserves
`[0x10000, 0x100000000)` for `__PAGEZERO` and already prefers `im->preferred_base`
when free; it needs a deliberate placement policy for the `mmap(NULL)` fallback
instead of taking whatever the kernel returns. Filed as a dependency, not fixed
here — `~/machorun` is read-only for this scope.

This affects **anything Swift** on machorun, not just Foundation, so it should be
fixed before the full build starts.

---

## 4. Why not A, B or C

### A. corelibs-foundation in `DEPLOYMENT_RUNTIME_OBJC` — **not a build mode**

The brief's central question. The answer is that ObjC-runtime mode is not
something corelibs can be configured into; it is vestigial dead code from Apple's
internal tree.

1. **The build never defines it.** `DEPLOYMENT_RUNTIME_SWIFT` is passed in
   `CMakeLists.txt:178,230` and `Package.swift:89,144`. `DEPLOYMENT_RUNTIME_OBJC`
   is defined *nowhere* in the build system.
2. **CF force-defines the other one.**
   `Sources/CoreFoundation/internalInclude/CoreFoundation_Prefix.h:10`:
   ```c
   #ifndef DEPLOYMENT_RUNTIME_SWIFT
   #define DEPLOYMENT_RUNTIME_SWIFT 1
   #endif
   ```
3. **The ObjC dispatch is stubbed with no live branch.**
   `internalInclude/CFInternal.h:954-958`:
   ```c
   #define CF_OBJC_FUNCDISPATCHV(typeID, obj, ...) do { } while (0)
   #define CF_OBJC_RETAINED_FUNCDISPATCHV(typeID, obj, ...) do { } while (0)
   #define CF_OBJC_CALLV(obj, ...) (0)
   #define CF_IS_OBJC(typeID, obj) (0)
   ```
   Unconditional — no `#if` anywhere. Compare the Swift ones immediately above,
   which have a real `#if DEPLOYMENT_RUNTIME_SWIFT` / `#else` pair. Apple stripped
   CF's toll-free-bridging dispatch when open-sourcing it.

So "build corelibs in ObjC mode" is ruled out **as stated**. But the investigation
turned up the thing that makes option D cheap, so this is a productive negative:

> **294 Objective-C dispatch call sites survive intact across 19 CF source files**
> (`CFString.c` 51, `CFURL.c` 35, `CFStream.c` 28, `CFDictionary.c` 22,
> `CFArray.c` 19, `CFSet.c` 18, …), and the supporting machinery —
> `__CFRuntimeObjCClassTable`, `_SetCFRuntimeObjcClass`, `__CFISAForTypeID`,
> `_CFRuntimeBridgeClasses` — is still there. Apple neutered the **macros**, not
> the **call sites**.

Restoring toll-free bridging in corelibs' CF is therefore a **~5-macro patch**
against a codebase that is otherwise waiting for it, not a rewrite. `CFGetTypeID`
is the canonical example: `CFRuntime.c:735` still reads
`CFTYPE_OBJC_FUNCDISPATCH0(CFTypeID, cf, _cfTypeID);` — exactly the dispatch our
slice implements by hand in one line, and exactly what §1.4 requires.

Separately, corelibs' **Swift** Foundation is not reusable wholesale here: in
Swift-runtime mode its `NSString`, `NSArray` etc. are *Swift classes* that would
collide with the Objective-C ones the stdlib demands. Its pure value types are
reusable (§6).

### B. corelibs in Swift mode + a rebuilt libswiftCore — **self-defeating**

This requires rebuilding the stdlib with ObjC interop **off**. Two problems, and
the second is fatal to the project:

1. The `arm64-apple-macos` target implies ObjC interop; turning it off means
   fighting the compiler on a configuration Apple neither supports nor tests — and
   we would be discarding a libswiftCore that already works.
2. **It destroys `@objc` and `#selector`.** That interop is the entire reason for
   choosing a Darwin stack, and OpenUIKit depends on it
   (`NSStringFromClass` 343 uses, `NSSelectorFromString` 338 uses in `~/uikit`).
   Trading it away to get Foundation would break the thing Foundation is *for*.

### C. GNUstep-base against objc4 — **wrong contract, and no Swift half**

GNUstep-base is a mature Objective-C Foundation, but it was built to a different
private contract:

- It does not implement `-_cfTypeID`, so `CFGetTypeID`-based identification (§1.4)
  fails.
- It does not implement the `isNS*__` SPI or the tagged-string SPI, so bridging
  aborts on an unrecognized selector (measured: that is exactly how wall (a)
  presented).
- It exports no `CFGetTypeID` / `CFStringGetTypeID` / `CFStringHashNSString` /
  `CFStringHashCString` to satisfy the `dlsym` set.
- Its classes are not ivar-less clusters shaped for `class_setSuperclass`.
- It has **no Swift overlay at all**, so §1.5 is still entirely on us.

We would be writing the same bridging layer regardless, but on top of an
unfamiliar 30-year codebase built for libobjc2's ABI, and taking on LGPL
obligations that Apache-2.0 corelibs does not carry. The mismatch is the same one
that made libobjc2 unusable for Swift.

### D. Our own Foundation over a CF we control — **recommended**

Against the brief's three criteria:

- **(i) Does `String <-> NSString` bridging actually work?** Yes — built, run, and
  matching macOS byte-for-byte (§2). This is the only option where that is a
  measurement rather than a hope.
- **(ii) How much Apple-closed-source does it assume?** None. corelibs' CF is
  Apache 2.0; objc4 is Apple open source; the `NS*` classes and Swift overlay are
  ours; the four `dlsym` symbols and the private selector contract are all
  satisfiable by us and all now enumerated (§1.3, §1.4).
- **(iii) Effort?** §6. Larger than A-if-A-had-worked, but A does not work, and D
  reuses corelibs' 98K lines of CF rather than starting from zero.

---

## 5. The architecture

```
  Swift application code
        |  import Foundation
  ┌─────────────────────────────────────────┐
  │ Foundation (Swift overlay)   ← OURS     │  _ObjectiveCBridgeable conformances,
  │                                         │  Swift value types (Data/Date/URL/…)
  ├─────────────────────────────────────────┤
  │ Foundation (Objective-C)     ← OURS     │  NS* class clusters, toll-free
  │                                         │  bridged onto CF, ivar-less bases
  ├─────────────────────────────────────────┤
  │ CoreFoundation               ← corelibs │  98K lines, Apache 2.0, plus the
  │                              + our patch│  ~5 restored ObjC dispatch macros
  ├─────────────────────────────────────────┤
  │ libobjc (Apple objc4)  │ libswiftCore   │  both already built as Mach-O
  ├─────────────────────────────────────────┤
  │ libSystem.B.dylib                       │
  ├─────────────────────────────────────────┤
  │ machorun (Mach-O loader on Linux)       │
  └─────────────────────────────────────────┘
```

The two-half split (ObjC classes + Swift overlay) is not our invention — it is
Apple's, and §1.5 shows the stdlib is built expecting exactly it.

---

## 6. Effort to a full Foundation

Sized against the census in §7, and against what the slice actually cost. The
slice — 7 classes, the bridging contract, and 4 CF functions — took roughly a day
including all four walls. That is the calibration point.

| area | scope | basis | estimate |
|---|---|---|---|
| **CoreFoundation** | corelibs' 88 files / 98K lines, built as Darwin Mach-O; restore the 5 ObjC dispatch macros; `__CFRuntimeObjCClassTable` registration for each bridged class | already Linux-clean and Apache 2.0; the 294 call sites are intact; the Mach-O cross-build recipe is proven | **3–4 weeks** |
| **Value + collection classes** | NSString/NSArray/NSDictionary/NSSet/NSNumber/NSData/NSDate/NSValue/NSNull/NSError as ivar-less clusters toll-free bridged over CF | the slice is the template; the contract is fully enumerated (§1.3) | **3–4 weeks** |
| **The bridging layer** | `_ObjectiveCBridgeable` for String/Int/Double/Bool/Array/Dictionary/Set/Data/Date/URL…; `__SwiftValue` boxing; NSError↔Error; lazy (non-copying) NSString→String via `_bridgeCocoaString`; apinotes for `SwiftBridge` | **highest risk per line**, but the risk is now retired in the small: the mechanism is proven end-to-end | **3–4 weeks** |
| **OS-facing classes** | FileManager, Bundle, RunLoop, Timer, Notification/NotificationCenter, Process, Pipe, Thread, Operation/OperationQueue, UserDefaults, URL/URLSession | mostly corelibs Swift sources, portable once CF is up; RunLoop and Process are the hard ones and both touch machorun's syscall surface | **4–6 weeks** |
| **Formatters + ICU** | DateFormatter, NumberFormatter, Locale, Calendar, CharacterSet, collation | 21 CF files touch ICU; needs ICU as a Mach-O dylib or a shim. **Deprioritise** — see §7 | **3–4 weeks, deferrable** |

**Total ≈ 16–22 engineer-weeks** to a Foundation that runs real app code, with
formatters/ICU deferrable out of the critical path.

Sequencing note: **do §3 (machorun's address-space fix) first.** It is small, it
is not ours, and every Swift-object code path is exposed to it.

---

## 7. What to build first — the app census

Foundation API actually used across `~/uikit` (Swift sources):

```
2084 IndexPath        405 Date              50 Operation
 794 URL              319 RunLoop           36 OperationQueue
 681 Data             308 Notification      22 UUID
 547 JSONSerialization161 NotificationCenter20 Bundle
 474 FileManager       89 Process            2 Locale
 457 DispatchQueue     64 Measurement        2 DateFormatter
 411 Timer             55 Pipe               2 Calendar
```

Two things fall out of this:

1. **Formatters, Locale and Calendar are nearly unused (2 uses each).** They are
   the ICU-shaped part of Foundation and the most painful to port. Deferring them
   costs almost nothing, and that removes ICU from the critical path entirely.
2. **The real surface is IndexPath, URL, Data, JSONSerialization, FileManager,
   Timer, RunLoop, Notification.** JSONSerialization and IndexPath are pure
   computation with no OS coupling and should come early. RunLoop and Timer are
   the genuinely hard ones and should be scheduled with slack.

---

## 8. Compute for the full build

- **CoreFoundation (98K lines C):** the heavy item. On the 64-vCPU Graviton4 used
  for the stdlib, a full CF build is minutes, not hours; it is far smaller than
  the Swift stdlib, which already succeeded on that box.
- **Swift Foundation overlay:** Swift compile times dominate. `-O` whole-module
  over ~50K lines wants **16–32 vCPU and 32–64 GB RAM**.
- **Recommendation:** the same **Graviton4 (`c7g.8xlarge`–`c7g.16xlarge`, 32–64
  GB)** class of box as `~/swiftcore-macho` used. Nothing here needs a bigger
  machine than the stdlib did.
- **Scoping and iteration need no cloud at all.** Everything in this document was
  produced in Docker on the Apple-silicon host, arm64-native, no emulation. Keep
  the tight loop local and use the big box only for full rebuilds.

---

## 9. Open risks

1. **§3 must be fixed properly.** `ulimit -s unlimited` is a workaround that
   happens to work; a deliberate mapping policy in machorun is the fix.
2. **Lazy NSString→String bridging is not done.** The slice copies eagerly. The
   zero-copy path needs `_bridgeCocoaString`, which is `@usableFromInline
   internal` and returns the internal `_StringGuts` — reachable by `@_silgen_name`
   but not nameable from another module. Needs a real answer, not a workaround.
3. **Tagged-pointer strings are not implemented.** Correct without them (measured),
   but every short string currently heap-allocates. Performance, not correctness.
4. **`__SwiftValue` boxing is unimplemented.** Needed the moment a non-bridged
   Swift value crosses into an `NSArray`/`NSDictionary`.
5. **Thread safety.** The slice has none. CF brings its own locking; our `NS*`
   layer must not undo it.
