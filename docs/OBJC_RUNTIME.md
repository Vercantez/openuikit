# The Objective-C runtime question — tested, then shipped

Real UIKit leans on the ObjC runtime for target-action (`#selector`), KVO,
`UIAppearance`, and optional-protocol dispatch (`respondsToSelector:`).
This file records what we measured when asking whether OpenUIKit should adopt
one, and what shipped instead.

**Status (2026-08-25, M12).** Selector target-action is implemented, and the
API works on macOS *and* Linux:

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

### 1. `Selector` — a per-platform type, and the library's only conditional

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

This `#if canImport` is the only conditional compilation in `OpenUIKit`, and
it is deliberate: the *type* is the seam, everything above it is shared.

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

- **GNUstep `libobjc2`** — the right *runtime* (ObjC 2.0, ARC, blocks,
  non-fragile ivars, portable, packaged). It consumes the class metadata Swift
  emits, and would give genuine `objc_msgSend`. It does not help: the party
  that crashes is `libswiftCore.so`, and libobjc2 cannot change how that
  library reads metadata. Not attempted further, for that reason.
- The only fix is a Linux `libswiftCore` built with interop — i.e. a Swift
  standard-library fork, tracked forever against upstream. That is the same
  conclusion as the original assessment, now with the exact mechanism.

Also ruled out, unchanged:

- **Darling** — a Darwin *emulation layer* (Mach-O loader, dyld, Mach traps)
  for running macOS **binaries**. We compile from source. It is the right
  project for running *precompiled* iOS apps — a different product.
- **Apple's `objc4`** — open source but welded to Darwin (Mach, dyld, malloc
  zones). Porting is a research project.

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
