# The Objective-C runtime question — tested, then shipped

Real UIKit leans on the ObjC runtime for target-action (`#selector`), KVO,
`UIAppearance`, and optional-protocol dispatch (`respondsToSelector:`).
This file records what we measured when asking whether OpenUIKit should adopt
one, and what shipped instead.

**Status (2026-08-25, M12; Task B verdict added).** Selector target-action is
implemented, and the API works on macOS *and* Linux. The question of whether
Linux could have the *real* thing instead is now closed, with measurements:
see "[Task B: a custom Linux stdlib with `SWIFT_OBJC_INTEROP=1`](#task-b-a-custom-linux-stdlib-with-swift_objc_interop1)".
The short answer is that it configures, would build in tens of minutes, and
would then have nothing to link against — an interop stdlib needs an
Objective-C `Foundation` and `CoreFoundation` that do not exist on Linux.

**Update (2026-08-25, M14+): that wall has a door, and it is not `@objc`.**
Objective-C *apps* can run on OpenUIKit on Linux — not by giving Swift an ObjC
runtime, but by putting a plain C ABI between the two worlds and writing the
`UIView`/`UILabel`/`UIButton`/`UIViewController` classes as **real Objective-C**
compiled against libobjc2 + gnustep-base. An ObjC app that subclasses `UIView`,
overrides `layoutSubviews` and `drawRect:`, and wires `@selector`
target-action renders a screen **byte-identical** to the Swift equivalent.
Design, ownership rule, limits and cost-to-finish: **docs/OBJC_FACADE.md**.
Nothing in *this* file changes — Swift-side `@objc` is still impossible off
Darwin, and the facade never uses it.

```swift
// macOS: verbatim UIKit.
button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
view.addGestureRecognizer(
    UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))

// Both platforms: same call, portable spelling of the selector.
button.addTarget(self, action: .named("buttonTapped"), for: .touchUpInside)
```

There is no ObjC runtime under it and no compiler flag on top of it. `#selector`
itself still does not compile off Darwin — that is a Swift limitation, measured
below, not one we can lift. What an app author must do differently from real
UIKit is in "[What an app author must change](#what-an-app-author-must-change)"
— read that section, it is the number that matters.

## How much do real apps depend on it?

Counted over the census corpus (eidolon, DuckDuckGo iOS, ios-oss):

| | `#selector` | `@objc` | `perform`/`responds(to:)` | `.appearance()` |
|---|---|---|---|---|
| eidolon | 8 | 30 | 0 | 0 |
| DuckDuckGo iOS | 189 | 148 | 24 | 8 |
| ios-oss | 163 | 165 | 35 | 0 |

~360 `#selector` uses — comparable to the alerts cluster (332). Real, but not
dominant. Most `NSNotificationCenter` observer registrations (ios-oss has
~780) need no ObjC runtime; corelibs-foundation covers them on Linux.

---

## What shipped

`Sources/OpenUIKit/UISelector.swift` (+ the new API on `UIControl` and
`UIGestureRecognizer`). Three pieces:

### 1. `Selector` — a per-platform type seam

```swift
#if canImport(ObjectiveC)
public typealias Selector = ObjectiveC.Selector      // the platform's real SEL
#else
public struct Selector: Hashable, ExpressibleByStringLiteral { … }
#endif
```

On Darwin `Selector` **is** the ObjC selector, so `#selector(...)` produces
one and `sel_getName` recovers its name. Off Darwin it is a name-carrying
struct. Both expose `actionName` ("buttonTapped", "valueChanged:") and
`actionArity` (the trailing-colon count, ObjC's rule).

`Selector.named("buttonTapped")` is the **portable spelling** and compiles on
both platforms. (`Selector("buttonTapped")` means the same thing, but Darwin's
compiler warns "no method declared with Objective-C selector" on a string
literal, since it cannot see a table it does not own; `named` launders the
string through a variable.)

This `#if canImport` is the selector subsystem's platform-dependent type seam:
the *type* varies by platform while the dispatch model above it is shared.

### 2. `SelectorDispatching` — name → method, supplied by the target

Swift has no by-name method dispatch, and OpenUIKit's classes are not
`NSObject` subclasses, so `perform(_:)` does not exist even on Darwin. The
target supplies the table:

```swift
final class MyViewController: UIViewController, SelectorDispatching {
    static let actions: ActionTable<MyViewController> = [
        .action("buttonTapped",  MyViewController.buttonTapped),
        .action("switchChanged:", MyViewController.switchChanged),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
}
```

`ActionEntry.action(_:_:)` is overloaded on UIKit's three action shapes —
`()`, `(sender)`, `(sender, event)` — and takes an *unapplied method
reference*, so each binding is one line and type-checked. A `(sender)` entry
whose sender is the wrong class is a no-op, as in UIKit.

A send that finds no method is not a crash (we have no runtime to raise
`unrecognized selector` from). It is silent, and reported through
`SelectorDispatch.onUnresolved` — which the tests install.

### 3. The UIKit API

| UIKit | OpenUIKit |
|---|---|
| `UIControl.addTarget(_:action:for:)` | same, target held **weakly** |
| `UIControl.removeTarget(_:action:for:)` | same; `nil` matches any target/action; unnamed event bits survive |
| `UIGestureRecognizer.init(target:action:)` | same |
| `UIGestureRecognizer.addTarget(_:action:)` / `removeTarget(_:action:)` | same |
| `UIControl.sendActions(for:)` | fires closure *and* selector registrations |

The closure API (`addTarget(for:_:)`, `UITapGestureRecognizer { … }`) is
unchanged and remains the better Swift API; DemoApp still uses it. Selector
registrations whose weak target has deallocated are pruned before each send,
so a dead target is silent rather than a diagnostic.

### Proof

- `Tests/OpenUIKitTests/SelectorDispatchTests.swift` — 27 tests (23 of them
  portable, 4 Darwin-only): the name
  layer, the table, weak-target semantics, `removeTarget` bit arithmetic,
  real touches through `UIWindow` into buttons / switches / tap recognizers,
  and (Darwin only) that genuine `@objc` + `#selector` source drives all of it
  and that `#selector(Target.valueChanged(_:)) == Selector.named("valueChanged:")`.
- `Sources/DemoApp/SelectorApp.swift` — a screen wired **entirely** with
  selectors, no closures: two buttons, a switch on `.valueChanged`, a tap
  recognizer and a long-press recognizer. `openhost --app selectors`.
- `scripts/selector_interaction.json` + `scripts/linux_selector_verify.sh` —
  replays that screen headlessly on both operating systems and diffs the
  recorded frames byte for byte. A selector that failed to fire would change
  the rendered counter, so identical bytes prove identical dispatch.

---

## What an app author must change

This is the honest cost. Everything below is a *source* difference from a real
UIKit app; there are no runtime behaviour differences in what is implemented.

**On macOS — three changes.**

1. **The dispatch table.** The `SelectorDispatching` conformance above: two
   lines plus one line per action. Real UIKit needs none of it. This is the
   irreducible cost of not having `objc_msgSend`, and it applies on macOS too
   because OpenUIKit's classes are not `NSObject` subclasses.
2. **`@objc` needs the Foundation module loaded.** A *scoped* import —
   `import struct Foundation.Data` — satisfies the compiler without pulling
   CoreGraphics' `CGSize`/`CGRect` in to collide with OpenUIKit's. A plain
   `import Foundation` **does** collide, so a real app ported as-is will hit
   ambiguity errors on `CGRect(x:y:width:height:)` and friends. (That
   collision is a general app-compat problem, not a selector one — `Selector`
   itself is fine either way, since OpenUIKit's is a typealias to the very
   type Foundation re-exports. Measured.)
3. **A 1-argument action's sender must be typed `AnyObject`.** `@objc`
   requires ObjC-representable parameters, and OpenUIKit's controls are pure
   Swift classes. So real UIKit's
   `@objc func tapped(_ sender: UIButton)` must be written
   `@objc func tapped(_ sender: AnyObject)` and downcast. Zero-argument
   actions — the common case — are verbatim.

So on macOS `#selector(buttonTapped)` and `@objc func buttonTapped()` are
**literally UIKit source**, and the 1-argument form needs its parameter
retyped.

**On Linux — one more, and it is the big one.**

`@objc` and `#selector` do not compile at all:

```
error: Objective-C interoperability is disabled
error: '#selector' can only be used with the Objective-C runtime
```

So off Darwin the same selectors are spelled `Selector.named("buttonTapped")`
and the `@objc` attributes are dropped. `Selector.named` also compiles on
Darwin, so **an app that wants one source for both platforms writes the string
form everywhere and never writes `@objc`** — the API shape stays UIKit's, only
the selector literal changes. `SelectorApp.swift` shows both: genuine
`#selector` under `#if canImport(ObjectiveC)`, the string form otherwise, and
the same call sites either way.

**Coverage against the census.** Of the ~360 `#selector` uses in the corpus,
the *call-site* API (`addTarget(_:action:for:)`, `init(target:action:)`,
`addTarget(_:action:)`, `removeTarget`) now exists and works on both
platforms — that is the whole `UIControl`/`UIGestureRecognizer` share of them,
which is where the large majority sit. What is **not** covered:
`#selector` uses that feed `NotificationCenter.addObserver(_:selector:name:)`,
`UIBarButtonItem(title:style:target:action:)`, `Timer.scheduledTimer(…
selector:)`, and `UIAppearance`/KVO — the first two because those types are
not implemented yet (see docs/APP_COMPAT.md's "Bars & appearance" and "App
lifecycle" clusters), the last two for the reasons at the bottom of this file.
And on Linux, none of those ~360 sites compile *as written*; they compile
after the mechanical `#selector(x)` → `Selector.named("x")` rewrite plus the
dispatch table.

---

## Why not a real ObjC runtime: the measurement

`Tools/objcshim/verify.sh` and `Tools/objcshim/interop_limits.sh` reproduce
everything below inside stock `swift:6.2-noble`.

### What works

`@objc` and `#selector` **do** compile and run on Linux, with (a) a module
named `ObjectiveC` declaring a **pointer-shaped** `Selector`, (b) a ~110-line
C stub (`objc_stub.c`) providing `_objc_empty_cache`, `objc_opt_self`,
`OBJC_CLASS_$__TtCs12_SwiftObject` + metaclass, and the whole
`swift_unknownObject{Retain,Release,Weak*,Unowned*}` family (absent from Linux
swiftCore, which is built without interop; for a pure-Swift object graph they
are their native counterparts), archived as `libobjc.a`, and (c)
`-Xfrontend -enable-objc-interop -Xfrontend -disable-objc-attr-requires-foundation-module`.
`verify.sh` prints the recovered names, correctly mangled:

```
recovered: tapped
recovered: valueChanged:
```

### Why it cannot be used anyway

`-enable-objc-interop` also changes the **class metadata layout** the compiler
emits. Measured (`interop_limits.sh`; the emitted IR for `class Root`, address
point at field `[3]`, annotated):

```
interop OFF: <{ ptr, ptr, ptr,  i64 Kind, ptr Superclass,
                i32 Flags, i32, i32, i16, i16, i32, i32, ptr Description, … }>
interop ON : <{ ptr, ptr, ptr,  i64 Kind, ptr Superclass,
                ptr CacheData0, ptr CacheData1, i64 Data,
                i32 Flags, i32, i32, i16, i16, i32, i32, ptr Description, … }>
```

Three extra words — the Objective-C class header. The `libswiftCore.so` that
ships with Swift for Linux is built with `SWIFT_OBJC_INTEROP=0` and reads
`Flags`/`InstanceSize`/`Description` at the *non*-interop offsets. So it reads
garbage. A program with **no `@objc` anywhere** — `class Root`, `final class
Leaf: Root, P` — prints `Leaf / true / true` built without interop and
**segfaults on the very first line**, `type(of:)`, built with it. A variant
that reaches the protocol cast first symbolicates as:

```
0  swift::TargetMetadata<InProcess>::isCanonicalStaticallySpecializedGenericMetadata()
1  swift_checkMetadataState
2  swift_conformsToProtocolMaybeInstantiateSuperclasses
3  swift_conformsToProtocol
4  dynamic_cast_existential_1_conditional
```

— the runtime walking the superclass chain into metadata it cannot parse.

Every runtime operation that touches a class descriptor — protocol conformance
checks (`as? SomeProtocol`), `type(of:)`, reflection, generic instantiation,
key paths — is undefined behaviour. Only plain class-to-class downcasts, which
just walk `Superclass` pointers, survive. `verify.sh` passes solely because
its test program does nothing but read a selector name.

**This is a Swift standard library mismatch, not an ObjC runtime gap**, which
kills the "Tier 2" idea outright:

- **GNUstep `libobjc2`** — a good ObjC 2.0 runtime, and the *wrong* one. An
  earlier revision of this file claimed it "consumes the class metadata Swift
  emits". **That was wrong**; it is measured false below, in "Task B".
- The only fix is a Linux `libswiftCore` built with interop — i.e. a Swift
  standard-library fork, tracked forever against upstream. **That was tested
  too, in Task B below. It does not work either**, and the reason is not cost.

Also ruled out, unchanged:

- **Darling** — a Darwin *emulation layer* (Mach-O loader, dyld, Mach traps)
  for running macOS **binaries**. We compile from source. It is the right
  project for running *precompiled* iOS apps — a different product.
- **Apple's `objc4`** — open source but welded to Darwin (Mach, dyld, malloc
  zones). Porting is a research project.

---

### Macro shadowing: also dead

An obvious escape is to define user macros named `selector` and `objc` so the
UIKit spelling compiles off Darwin. **Declaring** them is accepted, but the
builtins win at every *use* site:

```
error: '#selector' can only be used with the Objective-C runtime
error: Objective-C interoperability is disabled
```

(Measured with a real swift-syntax macro plugin on Linux.) Both names are
compiler-reserved. This is why no `@UIAction`-style macro was shipped: a macro
can generate the dispatch table, but it **cannot** make `@objc` or `#selector`
compile on Linux, so it would not buy source compatibility — only save the
one-line-per-action table. That remains a clean, optional future step; it is
deliberately deferred because it would add a `swift-syntax` dependency to a
package that currently has none, for a boilerplate saving rather than a
capability. Until then, the manual table above is the documented path.

The obvious next escape — a **source rewriter** that turns `#selector(x)` into
`Selector.named("x")` before the compiler sees it — was scoped and rejected for
a separate, sharper reason: getting the selector *string* right means
reimplementing Swift's ObjC name inference, prepositions and all, and a
rewriter that gets it wrong produces an action that silently never fires rather
than a compile error. The measured rule and the exact trap are in
"[Appendix: the `#selector` mangling oracle](#appendix-the-selector-mangling-oracle)".

## Task B: a custom Linux stdlib with `SWIFT_OBJC_INTEROP=1`

"[Why it cannot be used anyway](#why-it-cannot-be-used-anyway)" ends on *"the
only fix is a Linux `libswiftCore` built with interop"*. That sentence was an
**inference**. This section is what happened when it was actually tried, on
2026-08-25, on a 64-core Graviton4 running Ubuntu 24.04 aarch64 with the stock
Swift 6.2.4 toolchain — the same version the containers use.

**Verdict: no. Not "expensive" — impossible without also writing an
Objective-C Foundation for Linux.** Reproduce the whole thing with
`Tools/objcshim/stdlib_interop_probe.sh` (~8 minutes, mostly download).

### 1. The build system accepts the flag. That is the trap, not the opening.

`SWIFT_STDLIB_ENABLE_OBJC_INTEROP` is an ordinary user-settable CMake cache
option. Only its *default* is Darwin-derived (`swift/CMakeLists.txt:676-685`),
so `-DSWIFT_STDLIB_ENABLE_OBJC_INTEROP=TRUE` for a LINUX SDK is not rejected
anywhere — **configure exits 0**.

But the flag is consumed only in the negative, in exactly two places:

| file | when interop is OFF |
|---|---|
| `stdlib/cmake/modules/SwiftSource.cmake:627` | adds `-Xfrontend -disable-objc-interop` (Swift half) |
| `stdlib/cmake/modules/AddSwiftStdlib.cmake:352` | adds `-DSWIFT_OBJC_INTEROP=0` (C++ half) |

and the C++ default is `__APPLE__`-derived, not flag-derived
(`include/swift/Runtime/Config.h:92-98`):

```c
#ifndef SWIFT_OBJC_INTEROP
#ifdef __APPLE__
#define SWIFT_OBJC_INTEROP 1
#else
#define SWIFT_OBJC_INTEROP 0
#endif
#endif
```

So turning the option ON stops passing `=0` and passes nothing — and on Linux
`__APPLE__` is undefined. Diffing the two generated `build.ninja` files makes
this concrete:

```
baseline: '-DSWIFT_OBJC_INTEROP=0' on 109 C++ compile lines
interop : '-DSWIFT_OBJC_INTEROP='  on   0 C++ compile lines
baseline: '-disable-objc-interop'  on  25 Swift compile lines
interop : '-disable-objc-interop'  on   0 Swift compile lines
```

The Swift half flips; the C++ half silently does not. **Setting the flag alone
moves today's metadata mismatch from between two libraries to inside one** —
strictly worse than the status quo. The minimum honest patch is to make the ON
branch pass `-DSWIFT_OBJC_INTEROP=1`, plus `-DSWIFT_HAS_ISA_MASKING=0` (Config.h
derives isa masking from `SWIFT_OBJC_INTEROP && 64-bit`, and would otherwise
apply Darwin's isa mask on Linux). Two lines. They are not the problem.

### 2. Build scope is *not* the problem either — stdlib-only works

This was the expected cost driver and it evaporated. A **stdlib-only** build
against the shipped toolchain configures clean (**exit 0**), with no compiler
bootstrap, no LLVM build, no cmark and no tablegen:

- `SWIFT_INCLUDE_TOOLS=OFF`, `SWIFT_ENABLE_SWIFT_IN_SWIFT=OFF`
- `SWIFT_NATIVE_SWIFT_TOOLS_PATH` / `SWIFT_NATIVE_CLANG_TOOLS_PATH` →
  the stock `swift-6.2.4-RELEASE` toolchain
- cmark and llvm-tblgen are gated on `SWIFT_INCLUDE_TOOLS`
  (`CMakeLists.txt:912`, `SwiftSharedCMakeConfig.cmake:54-86`)

Four speed bumps, all one-liners: an *installed* LLVMConfig (Ubuntu
`llvm-18-dev`) does not define `LLVM_BUILD_LIBRARY_DIR` / `LLVM_LIBRARY_DIRS` /
`LLVM_TOOLS_BINARY_DIR` the way a build-tree one does; `zlib1g-dev`; and
`SWIFT_PATH_TO_LIBDISPATCH_SOURCE` wants a corelibs-libdispatch checkout.

So "you would have to build a whole Swift toolchain" was never true. Tens of
minutes, not hours. The kill is cleaner than a cost argument.

### 3. The wall: an interop stdlib needs an Objective-C Foundation

The stdlib contains ten Objective-C / Objective-C++ translation units. They are
compiled on Linux **today** — they just preprocess to nothing, because their
entire bodies sit inside `#if SWIFT_OBJC_INTEROP`. Turn interop on and the
bodies become live. Forcing `-DSWIFT_OBJC_INTEROP=1` onto the C++ half and
compiling them, **10 of 10 fail immediately**:

```
SwiftObject.mm                      'objc/NSObject.h' file not found
ErrorObject.mm                      'objc/objc.h' file not found
SwiftValue.mm                       'objc/objc.h' file not found
ReflectionMirrorObjC.mm             'objc/runtime.h' file not found
ObjCRuntimeGetImageNameFromClass.mm 'objc/runtime.h' file not found
Reflection.mm                       'objc/runtime.h' file not found
OptionalBridgingHelper.mm           'objc/runtime.h' file not found
FoundationHelpers.mm                'CoreFoundation/CoreFoundation.h' file not found
SwiftNativeNSObject.mm              'Foundation/Foundation.h' file not found
Availability.mm                     'TargetConditionals.h' file not found
```

libobjc2 ships `objc/objc.h`, `objc/runtime.h` and `objc/message.h`, so it can
satisfy six of those includes *textually* (while still being the wrong ABI —
see §4). It ships **no** `objc/NSObject.h` and no `objc/objc-internal.h`.
`CoreFoundation/`, `Foundation/` and `TargetConditionals.h` have no Linux
equivalent at all: swift-corelibs-foundation is written in *Swift*, and the
only ObjC Foundation on Linux is GNUstep-base, whose `NSString`/`NSNumber`
internals and CF-bridging are not what these files expect.

And that is only the C++ half. On the Swift side, `stdlib/public/core` carries
**188 `#if _runtime(_ObjC)` sites across 48 files** — `StringBridge`,
`DictionaryBridging`, `SetBridging`, `CocoaArray`, `BridgeObjectiveC`,
`StringStorageBridge` — all of which begin compiling and must then *link*
against an `NSString`, `NSArray` and `NSDictionary` that do not exist.

**So a successfully-built interop `libswiftCore.so` would still have nothing to
link against.** Finishing the build is not a thing that can happen, which is why
this measurement stops at the wall rather than burning hours proving it twice.

### 4. libobjc2 is the wrong ABI — the correction

The claim that libobjc2 "consumes the class metadata Swift emits" is false, and
this is the evidence:

- **Struct layout.** Swift IRGen emits Apple `objc4` class layout — the
  interop-ON metadata measured further up this file, `{isa/Kind, Superclass,
  CacheData[2], Data, Flags, …}`, *is* objc4's `objc_class`. libobjc2's
  `struct objc_class` (`libobjc2/class.h:46`) is the GNUstep ABI:
  `{isa, super_class, name, version, info, instance_size, ivars, methods,
  dtable, subclass_list, sibling_class, protocols, …}`. Different fields,
  different order, different meaning. This is not a gap to be filled; it is a
  different data structure.
- **Swift has never heard of GNUstep.** `grep -rli gnustep lib/IRGen include/swift stdlib`
  over the 6.2.4 tree returns **zero hits**. Swift's ObjC interop is objc4-only
  and hardcoded; there is no `-fobjc-runtime=` equivalent.
- **Discovery mismatch.** IRGen does emit ELF section names
  (`GenDecl.cpp:1024-1046` maps `__objc_classlist` → ELF `objc_classlist`), but
  libobjc2 discovers classes through its own GNUstep-v2 sections and an
  `__objc_init` constructor. Neither side reads the other's.
- **API surface.** Of the 71 ObjC symbols the Swift runtime references, libobjc2
  covers the public ObjC-2.0 API fine (msgSend, `class_*`, `sel_*`,
  `protocol_*`, ARC, weak refs, associated objects, autorelease pools). The
  **30** it lacks are Apple's *private* `<objc/objc-internal.h>` surface:
  `_objc_realizeClassFromSwift`, `_objc_supportsLazyRealization`,
  `_objc_setClassCopyFixupHandler`, `objc_setHook_getClass` /
  `getImageName` / `lazyClassNamer`, `objc_addLoadImageFunc`,
  `objc_constructInstance` / `objc_destructInstance`,
  `objc_isUniquelyReferenced`, `objc_debug_isa_class_mask`,
  `_objc_empty_cache`, `class_getImageName`, `object_isClass`, and
  **`objc_readClassPair`**. Most are reached through `SWIFT_RUNTIME_WEAK_CHECK`
  and degrade gracefully. `objc_readClassPair` does not: `SwiftObject.mm:1418`
  calls it unconditionally, with an assert, and it is *the* mechanism by which
  a statically-emitted Swift class gets registered with the runtime.

The only runtime that fits Swift-emitted metadata is Apple's `objc4`, which is
welded to Darwin (Mach, dyld, malloc zones). Porting it is the Darling problem —
a research project, explicitly out of scope here.

### 5. What this settles

`Selector.named("...")` plus a registry the target owns is **not a workaround
for a missing feature**. It is the only viable design on Linux, and that is now
measured rather than assumed:

| escape route | status |
|---|---|
| `#selector` / `@objc` off Darwin | compiler refuses; not a library choice |
| user macros named `selector` / `objc` | builtins win at every use site (below) |
| `-enable-objc-interop` on stock Linux | compiles, then segfaults: metadata layout vs shipped libswiftCore |
| GNUstep libobjc2 | wrong class ABI; Swift has no GNUstep support at all |
| custom stdlib, `SWIFT_OBJC_INTEROP=1` | configures and would build — with nothing to link against |
| Apple objc4 on Linux | Darling-scale port; out of scope |

Even in the counterfactual where it all worked, adoption would require every
Linux user to install a **non-standard Swift toolchain** — a forked
`libswiftCore.so` tracked forever against upstream, for a source-compatibility
convenience. Against that, one library-owned `Selector` struct and a generated
table is not a compromise; it is the better engineering.

### Appendix: the `#selector` mangling oracle

`Tools/objcshim/selector_oracle.swift` (+ `.expected`) asks the real macOS
compiler what selector 49 different declarations produce, so the string passed
to `Selector.named(...)` can be checked against truth rather than memory. Run
it with `swiftc -O Tools/objcshim/selector_oracle.swift -o /tmp/o && /tmp/o`.

The rules it establishes:

1. No parameters → the base name. `zeroArg` → `zeroArg`.
2. Each parameter contributes one `:`. An empty (`_`) label contributes an
   empty piece: `x(_:b:_:)` → `x:b::`.
3. If the **first** argument label is non-empty, it is folded into the first
   piece, sentence-cased — and `With` is inserted **only if neither** the base
   name's last word **nor** the label's first word is a preposition:

   | declaration | selector |
   |---|---|
   | `func handlePan(gesture:)` | `handlePanWithGesture:` |
   | `func set(value:)` | `setWithValue:` |
   | `func insert(at:)` | `insertAt:` — "at" is a preposition |
   | `func move(from:to:)` | `moveFrom:to:` — "from" is a preposition |
   | `func startWith(url:)` | `startWithUrl:` — base ends in "with" |
   | `init(thing:)` | `initWithThing:` |

4. Sentence-casing uppercases the first character only, and leaves the rest:
   `deF` → `DeF`, `URLString` → `URLString`, `_lead` → `_lead`.
5. Properties: getter = the ObjC property name; setter = `set` + sentence-cased
   name + `:`. `url` → `setUrl:` (**not** `setURL:`), `ABC` → `setABC:`,
   `_lead` → `set_lead:`.
6. `@objc(custom)` replaces the computed name outright. `@IBAction` behaves
   exactly like `@objc`.

Rule 3's preposition clause is why a mechanical `#selector` → `Selector.named`
source rewriter was **not** shipped: a naive transformer emits
`insertWithAt:` for `insert(at:)`, and the failure mode is a selector that
silently never fires, not a compile error. Anything doing that transformation
must consult Swift's preposition list (`PartsOfSpeech.def`), and at that point
it is reimplementing `AbstractFunctionDecl::getObjCSelector`.

---

## Packaging: no flags, no poisoned dependency

The original worry was that `.unsafeFlags` would be required and would make
OpenUIKit unusable as an SPM dependency (SPM permits `unsafeFlags` in a root
package but refuses a dependency that uses them). **It is not required.**
`Package.swift` needs no `swiftSettings`, no `linkerSettings`, and no
`.when(platforms:)` for this feature:

- macOS gets `Selector` from `import ObjectiveC`, which costs nothing.
- Linux gets OpenUIKit's own `Selector`; the library never emits ObjC interop
  code, so no `-lobjc`, no shim target, no frontend flags.
- An app that wants literal `@objc` on Darwin adds a scoped
  `import struct Foundation.Data` — a source change in the app, not a build
  setting.

So the feature is on by default on both platforms and the package remains
clean for downstream consumers. There is nothing to make opt-in.

## The related runtime-flavoured features

Their portable answers, unchanged: **KVO** → explicit observer registry or
`didSet` (real KVO isa-swizzles at runtime); **`UIAppearance`** → a typed
appearance-proxy struct per class (real UIKit records setters through
`NSInvocation` forwarding); **optional protocol methods** → protocol
extensions with default implementations. All three are the same shape as the
selector answer: replace a runtime lookup with a table we own.
