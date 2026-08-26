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
Bootstrapping. Depends on: the TLS-destructor loader fix in ~/machorun
(in progress) so Swift classes run; libswiftCore from ~/swiftcore-macho.
See docs/PLAN.md.
