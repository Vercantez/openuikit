# An Objective-C facade for OpenUIKit — prototype, measured

**Question.** OpenUIKit runs Swift apps on Linux. Can it run **Objective-C**
apps on Linux too, given that Swift's ObjC interop does not exist off Darwin
and cannot be made to (docs/OBJC_RUNTIME.md)?

**Answer: yes, and the design is not exotic.** Four classes — `UIView`,
`UILabel`, `UIButton`, `UIViewController` — are implemented end to end, an
Objective-C program that subclasses `UIView` and overrides `layoutSubviews`
and `drawRect:` renders through the engine, and its PNG is **byte-identical**
to the same screen built in Swift. On Linux against libobjc2 + gnustep-base,
and on macOS against Apple's runtime, from one unmodified facade source.

```
Objective-C app  (real @interface, real objc_msgSend, ARC)
      |  ObjCFacade/               clang -fobjc-runtime=gnustep-2.2
      v
  plain C ABI    (@_cdecl over opaque handles, no @objc anywhere)
      |  Sources/OpenUIKitC/ + Sources/COpenUIKitABI/
      v
OpenUIKit's Swift engine
```

Neither side needs the other's internals. That is the whole trick: the wall in
docs/OBJC_RUNTIME.md is that a Swift interop stdlib needs an Objective-C
`Foundation`/`CoreFoundation` which does not exist on Linux. A C ABI needs
neither, so the wall is not in the path.

**Proof:** `scripts/objc_facade_verify.sh` (Docker, one container, both halves,
byte diff) and `Tests/OpenUIKitCTests/ABITests.swift` (22 tests, in the normal
`swift test` gate, no Objective-C needed).

---

## What was built

| | file | size |
|---|---|---|
| Shared ABI types (the callback vtable) | `Sources/COpenUIKitABI/include/openuikit_abi_types.h` | 119 lines |
| C ABI entry points (Swift, `@_cdecl`) | `Sources/OpenUIKitC/` | 878 lines, **73 entry points** |
| ObjC facade (clang) | `ObjCFacade/UIKitFacade.m` + headers | 535 lines, **67 methods** |
| Swift→ObjC dispatch | `ObjCFacade/OpenUIKitBridge.m` | 138 lines, **6 hooks** |
| ObjC proof app | `ObjCFacade/ProofApp.m` | 220 lines |
| Swift twin (the render being diffed against) | `Sources/objcparity/main.swift` | 158 lines |
| ABI tests | `Tests/OpenUIKitCTests/ABITests.swift` | 22 tests |

Toolchain, built from source in `ObjCFacade/Dockerfile` because Ubuntu 24.04
packages none of it usefully (it ships gnustep-base 1.29 on **GCC's** libobjc,
which has no ARC and no non-fragile ivars):

| | version |
|---|---|
| base image | `swift:6.2-noble` — the same image `scripts/linux_verify.sh` uses |
| libobjc2 | **v2.2.1** (ABI `gnustep-2.2`) |
| gnustep-make | **2.9.3** (`--with-library-combo=ng-gnu-gnu`) |
| gnustep-base | **1.31.1** |
| clang | Ubuntu 18.1.3 |
| Swift | 6.2.4 |

The whole image builds in about 4 minutes on an M-series Mac. Nothing is
installed on the host.

---

## The ownership rule

Bridges rot at the ownership boundary, so there is exactly **one** rule, and it
is one Objective-C programmers already know.

### 1. Across the boundary: the Core Foundation Create Rule, verbatim

* A function with **`_create`** in its name returns a handle you **own (+1)**.
  `openuikit_release()` balances it.
* **Every other** handle-returning function returns a **borrowed (+0)** handle,
  valid only while something else keeps the object alive.

No exceptions, and the name carries the rule, so a reviewer can check a new
entry point without reading its body. `openuikit_view_superview`,
`openuikit_view_subview_at`, `openuikit_button_title_label` and
`openuikit_viewcontroller_view` are all +0; only the four `*_create` functions
are +1.

The facade takes exactly one +1 in `-init` and drops it in `-dealloc`.

### 2. Back the other way: Swift never owns an Objective-C object

A Swift object stores at most one **`peer`** — an unowned raw pointer to the
ObjC object fronting it, installed by `openuikit_set_peer`. Swift never
retains, releases or messages it except through the hook vtable.

### 3. The consequence, which is the part that would rot if left implicit

> **The Objective-C object graph must dominate the Swift one.**
> If Swift object A retains Swift object B, then A's peer must retain B's peer.

Otherwise B's peer dies while B is still alive and still being laid out, and
the unowned back-pointer dangles. In practice this is one line: the facade's
`-addSubview:` keeps an `NSMutableArray` mirroring Swift's `subviews`. UIKit
does the same thing internally, so it is not even a divergence.

**It is checked, not just written down.** `openuikit_clear_peer` (called from
`-dealloc`) reports a violation when a peer dies while a **live** ObjC
superview still owns its Swift view; `OPENUIKIT_ABI_STRICT=1` makes that
fatal. `ProofApp.m` ends with a deliberate violation — parenting a view through
the raw C ABI, bypassing the retaining `-addSubview:` — and asserts the bridge
catches it. A guard-rail nobody has watched fail is not a guard-rail.

### 4. Target-action targets are unowned

`openuikit_control_add_target_action` holds the target peer unowned, exactly
like UIKit's weak target. The facade must unregister from the target's
`-dealloc` if the control can outlive it. This is the one place the prototype
is *not* self-checking, and it is the first thing to fix in a real facade.

---

## Bidirectional dispatch: how it went

**It works, and it is the cleanest part of the design.** The Swift engine holds
**one C function pointer per override point** — six of them, for the whole
framework. Each is a one-line `objc_msgSend` on the ObjC side, so the
**Objective-C runtime** does the polymorphism:

```
Swift  OUKView.layoutSubviews()      -> hooks.layout_subviews(peer)
ObjC   ouk_layout_subviews(peer)     -> [(id)peer layoutSubviews]
                                     -> -[CardView layoutSubviews]   (the app's override)
ObjC   [super layoutSubviews]        -> -[UIView layoutSubviews]     (the facade's base)
                                     -> openuikit_view_super_layout_subviews(handle)
Swift  OUKView.oukSuperLayoutSubviews() -> super.layoutSubviews()    (OpenUIKit's own)
```

Three properties worth stating plainly:

* **The vtable does not grow with the facade.** Adding `UIScrollView` or
  `UITableViewCell` adds zero hook entries — the ObjC runtime already knows how
  to find their overrides. A design that registered a callback per class would
  have been a per-class tax forever.
* **`super` works and does not recurse.** `super.layoutSubviews()` reaches
  OpenUIKit's implementation, never the override, so a subclass that does not
  override still gets correct engine behaviour and one that does can call up.
  `testOverrideCanCallSuperWithoutRecursing` pins this.
* **Target-action is *better* on this side of the bridge.** A Swift target must
  hand-write an `ActionTable` because Swift off Darwin has no by-name dispatch
  (docs/OBJC_RUNTIME.md). An Objective-C target writes
  `@selector(buttonTapped:)` and needs **nothing** — it has a runtime. Compare
  `ProofApp.m`'s `Screen` with `objcparity`'s `Screen`: same screen, and only
  the Swift one carries a dispatch table.

### Where it is ugly, honestly

1. **Every peered view pays a round trip per layout pass**, even when the ObjC
   subclass overrides nothing: Swift calls the hook, ObjC `objc_msgSend`s,
   `-[UIView layoutSubviews]` calls straight back into Swift. Structurally that
   is one indirect call plus one message send plus one C call per view per
   layout pass. **This is not measured** — the proof app renders one frame. The
   fix is mechanical and a generator would emit it: at `-init`, ask the runtime
   whether the instance's class actually overrides `layoutSubviews`
   (`class_getMethodImplementation` vs `UIView`'s) and only then call
   `openuikit_set_peer`; an unpeered view skips the hook entirely, which
   `testUnpeeredViewsUseTheEngineImplementation` already covers.
2. **Constructors that take arguments break the inheritance chain.**
   `-initWithFrame:` calls an overridable `-createOpenUIKitHandle`, which works
   for every class whose Swift constructor is nullary. `UIButton(type:)` is not,
   and Objective-C cannot pass state into a method that runs before `self`
   exists — so `+buttonWithType:` has to make the Swift object first and hand it
   over +1 through a private `_initWithHandle:frame:`. Every such class needs
   that shape. It is two extra lines, but it is two extra lines a human will
   get wrong.
3. **`-drawRect:` on a `UILabel` subclass never fires.** OpenUIKit's `UILabel`
   overrides `drawContent(in:bounds:)`, not `draw(_:)`, so the app-facing draw
   hook is bypassed for labels (and any other content view that does the same).
   Real UIKit calls `-[UILabel drawRect:]`. Divergence, recorded here and worth
   an entry in docs/KNOWN_GAPS.md if the facade is pursued.
4. **Objects the *engine* creates cannot be subclassed or given identity.**
   `openuikit_button_title_label` returns a real handle and all its setters
   work, but the Swift object is a plain `UIButtonLabel`, not one of
   OpenUIKitC's peerable subclasses, so `openuikit_set_peer` refuses it (and
   says so — `testPeeringANonPeerableObjectIsReportedNotIgnored`). An ObjC
   `-titleLabel` therefore cannot return a stable, overridable object. Fixing
   this properly means the peer slot moving into `OpenUIKit.UIView` itself
   rather than living in `OpenUIKitC`'s subclasses.

---

## What the prototype found in the engine

**`UIView.superview` is a strong reference.** UIKit's is not. With
`subviews` strong as well, every OpenUIKit view hierarchy is a reference cycle
and is never deallocated — the parent stays allocated after its last external
owner lets go.

This surfaced immediately, because the bridge's first ownership check was
"did this peer die while its Swift view still has a superview?", and that fired
on *every* orderly teardown. The check now asks whether the superview still has
a **live peer**, which is precise either way, but the underlying leak is real
and is not the bridge's:

```swift
// Sources/OpenUIKit/UIView.swift:113
public internal(set) var superview: UIView?      // strong
public internal(set) var subviews: [UIView] = [] // strong
```

Left unfixed here deliberately: making `superview` weak is a change to engine
semantics with a hot-path cost (`layoutIfNeeded` walks the chain on every
call), it belongs to whoever owns the view module, and it is not needed for the
bridge to work. It is a genuine bug for long-running apps, which is exactly
what an ObjC app on Linux would be.

**Second finding, and a happy one:** gnustep-base's
`<Foundation/NSGeometry.h>` already declares `CGFloat`, `struct CGPoint`,
`struct CGSize` and `struct CGRect` — `NSPoint`/`NSSize`/`NSRect` are typedefs
*of them*. So the Objective-C side gets CoreGraphics geometry free on Linux,
exactly as the Swift side does from corelibs-foundation (docs/PORTABILITY.md).
Only the `CGRectMake` free-function family is missing, and `UIGeometry.h`
supplies eight of them in 25 lines; GNUstep's `libs-corebase` would supply the
rest. **The facade's entire portability seam is those free functions** — the
`.m` files are byte-identical between the Linux and macOS builds.

---

## The proof

`scripts/objc_facade_verify.sh`, one container, everything from source:

```
--- run: Objective-C app
objc: layout passes = 1                    <- the ObjC override ran
objc: status = action fired, sender tag 7  <- @selector dispatch changed rendered text
objc: card superview identity = OK         <- +0 handle -> the original ObjC object
objc: card subview count = 2
objc: ABI violations = 0
objc: vc loadView=1 viewDidLoad=1 viewWidth=200
objc: deliberate ownership violation detected = 1   <- the guard-rail fires on demand
--- run: Swift twin
swift: layout passes = 1
swift: status = action fired, sender tag 7
==> diffing the Objective-C render against the Swift render
objc.png  6b802ecf98a3e2b695ec3c5e84351c820ffb6661ae1d84fb948f231eced2a1d7  (123626 bytes)
swift.png 6b802ecf98a3e2b695ec3c5e84351c820ffb6661ae1d84fb948f231eced2a1d7  (123626 bytes)
byte-identical
OBJC FACADE VERIFIED
```

The target-action result is *in the pixels* — the status label's text is
written by the selector callback — so a dispatch failure is a pixel difference,
not a silent pass. Same technique as `scripts/linux_selector_verify.sh`.

`ldd` on the ObjC binary, which is the architecture in one line:

```
libOpenUIKitC.so   libobjc.so.4.6 (libobjc2)   libgnustep-base.so.1.31
libswiftCore.so    libdispatch.so   libBlocksRuntime.so
```

The ObjC link line never mentions Swift; `libOpenUIKitC.so` records the Swift
runtime as `DT_NEEDED` and that is the entire coupling.

**And on macOS, unchanged.** The same three `.m` files compile with Apple's
clang against Apple's Objective-C runtime and Apple's Foundation, and produce a
PNG byte-identical to the macOS Swift twin
(`826367e7…`). Nothing in the facade is GNUstep-specific;
`OpenUIKitBridge.m` dispatches through `-methodForSelector:` rather than
`objc_msgSend` directly precisely so both runtimes' calling conventions are
satisfied.

---

## How big is the full facade?

Measured against OpenUIKit's actual surface (`public`/`open` member
declarations under `Sources/OpenUIKit`, 215 public types, **1,893 members**)
and the census's ranked type list (`Tools/apicensus/census-latest.json`,
16,343 uses across four real apps).

The four prototype classes carry **73 C entry points / 67 ObjC methods** and
cover roughly a quarter of their own types' 172 public members. Holding that
density:

| target | types | public members | C entry points | ObjC methods | est. hand-written lines |
|---|---:|---:|---:|---:|---:|
| **this prototype** | 4 | 172 (≈40 wrapped) | 73 | 67 | ≈1,700 |
| **census top 20** (≈71% of all uses) | 20 | 650 | ≈750 | ≈750 | ≈10,000 |
| **everything OpenUIKit exports** | 215 | 1,893 | ≈2,200 | ≈2,200 | ≈30,000 |

("C entry points" exceeds "members" because a read/write property is two
functions and every getter that returns a string or a rect needs an
out-parameter form.) Line estimates use the prototype's own measured density:
7.8 lines per entry point in `EntryPoints.swift`, 5.3 per method in
`UIKitFacade.m`, both including the doc comments this repo expects.

**Top-20 is the number that matters**: ~750 entry points and ~10,000 lines buys
71% of everything four real apps touch. That is a milestone-sized piece of
work, not a research project — but it is also ~10,000 lines of code whose every
line is the same three lines.

---

## Recommendation: generate it

**Hand-write the runtime, generate the wrappers.** Concretely:

* **Keep hand-written** (~900 lines, and they are the whole design): the
  ownership rule and its checker, the peer slot, the hook vtable, the six
  dispatch shims, the string/rect marshalling conventions, `UIColor`, the
  geometry shim, and the ownership-mirroring `-addSubview:`. None of this
  repeats; all of it is where the thinking is.
* **Generate** the per-member wrappers on both sides from one description. Every
  one of the 67 ObjC methods written for this prototype is literally "unwrap
  arguments, call one C function, wrap result", and every one of the 73 C entry
  points is "resolve handle, call one Swift member". Three arguments for
  generating:
  1. **Consistency is the correctness property.** The ownership rule is enforced
     by *naming discipline* across ~2,200 functions. A generator cannot forget
     to name a +1 function `_create`; a human reviewing pull request 40 of 60
     can.
  2. **The description already exists.** `Tools/apicensus/census.py` parses the
     Swift API surface today, and it is what produced the 1,893 number above.
     Emitting `.h`/`.m`/`@_cdecl` from the same parse is a much smaller program
     than the 30,000 lines it replaces.
  3. **Drift is otherwise guaranteed.** OpenUIKit's Swift API is still moving
     (M14). Hand-written glue would need a matching edit per API change forever;
     generated glue is a re-run plus whatever the gate says.
* **Do not generate** the four rough edges listed above — argument-taking
  constructors, engine-created objects, `UILabel`'s draw path, and target
  unregistration. Those need decisions, and a generator that guesses at them
  produces plausible code that is wrong.

The one prerequisite before scaling: **move the peer slot into
`OpenUIKit.UIView`** (and `UIResponder`) rather than `OpenUIKitC`'s subclasses.
That is a handful of lines in the engine, it removes limitation 4 entirely, and
it means the generator emits no subclasses at all — just wrappers.

---

## Reproducing

```sh
docker build -t openuikit-objc-facade:noble ObjCFacade    # ~4 min, from source
scripts/objc_facade_verify.sh                             # build + run + byte diff
swift test --filter OpenUIKitCTests                       # 22 ABI tests, no ObjC needed
```

The image name and the single container name (`ouk-objc-facade-verify`) are
fixed, so the script never touches anything else running on the host.
