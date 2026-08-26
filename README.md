# foundation-macho

**A full Foundation for the Darwin-Mach-O-on-Linux stack** — so real iOS/macOS
apps (which lean on Foundation everywhere) can build and run on Linux under
machorun, alongside our objc4, libswiftCore, quartz and OpenUIKit.

## The pieces that already exist (we do NOT start from scratch)
- **swift-corelibs-foundation** (Apache 2.0) — Apple's own open Foundation,
  Swift + a vendored CoreFoundation (C). The natural base: it is Swift, and we
  can now build Swift as Darwin Mach-O (see ~/swiftcore-macho).
- **GNUstep-base** (LGPL) — a 30-year mature Objective-C Foundation. Different
  internals; built for the GNUstep runtime (libobjc2), not Apple's objc4.

## THE ARCHITECTURAL DECISION (scope this FIRST — it decides success)
Foundation's hard part is not method count; it is the Swift <-> ObjC <->
CoreFoundation BRIDGING internals, which the Swift stdlib expects to match
Apple's EXACTLY (_SwiftValue, _CFStringGetCStringPtr, toll-free bridging).

Our stack is a DARWIN environment (Apple objc4 as Mach-O, libswiftCore built
for the arm64-apple-macos target). So we need a Foundation whose bridging
matches DEPLOYMENT_RUNTIME_OBJC (the Darwin mode), NOT the
DEPLOYMENT_RUNTIME_SWIFT mode corelibs-foundation normally uses on Linux. The
central question: can corelibs-foundation be built in ObjC-runtime mode against
our objc4 + libswiftCore, or does that path assume Apple's closed Foundation?
If corelibs cannot, is GNUstep-base-against-objc4 viable, or do we build a
CoreFoundation-based Foundation ourselves? This choice is the whole project.

## Method
Scope-and-prove before the big build: pick the base, build CoreFoundation +
a MINIMAL Foundation slice (NSString, NSArray, NSObject) as Darwin Mach-O,
and prove `String <-> NSString` bridging works correctly for Swift code run
under machorun — differential vs macOS. Only then build out the full surface.
Census the target apps' actual Foundation use to prioritise (like we did for
UIKit). Honest walls are results.

## Status

**Decided, and the decisive risk is retired (2026-08-26).**

`String <-> NSString` bridging **works**. A minimal Foundation slice —
NSString, NSArray, NSMutableArray, NSDictionary, NSSet, NSEnumerator,
NSNumber, plus a Swift overlay — builds as **Darwin Mach-O arm64 on Linux**
and passes two differential tests byte-for-byte against real macOS 26.5.2
Foundation:

```
$ scripts/run_tests.sh
PASS      t1_objc      # ObjC API + CFGetTypeID toll-free dispatch
PASS      t2_bridge    # "hi" as NSString -> 2 ; NSArray(array:[1,2,3]) -> 3
pass 2  fail 0  no-oracle 0
```

The reframing that made it tractable: **libswiftCore's dependency on
Foundation is a runtime contract, not a link-time one** — 128 selectors, 6
classes found by `objc_lookUpClass`, and 4 CoreFoundation functions found by
`dlsym`. It links no Foundation and no CoreFoundation at all. All of it is
ours to satisfy.

**The decision:** our own Foundation (Objective-C `NS*` class clusters + a
Swift overlay) over swift-corelibs-foundation's CoreFoundation with its
Objective-C toll-free-bridging macros restored — Apple stripped the *macros*
when open-sourcing CF but left **294 dispatch call sites intact**. Full
reasoning, and why corelibs-in-ObjC-mode / corelibs-in-Swift-mode /
GNUstep-base are each ruled out, in **`docs/DECISION.md`**. Build plan in
`docs/PLAN.md`.

**A loader bug this scope found, now fixed:** libswiftCore has Apple's
47-bit arm64 `ISA_MASK` inlined, while machorun mapped images above 2^47 —
so Swift truncated every class pointer and faulted. Fixed in machorun
`a1718a4`, which places every image below 2^47; re-verified here with the
workaround removed. It affected all Swift on machorun, not just Foundation.
DECISION §3.

Requires machorun at or after `a1718a4`. The TLS-destructor fix is also in,
so Swift classes and generics run.
