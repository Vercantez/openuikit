# The approach

Build `libswiftCore.dylib` as **Darwin Mach-O, arm64**, on a **Linux host**,
from swift.org 6.2.4 source, with no Xcode and no Apple toolchain.

## Why this is not the dead end we already hit

`~/uikit/docs/OBJC_RUNTIME.md` §"Task B" measured a different experiment and
killed it: building the **Linux-target** stdlib with `SWIFT_OBJC_INTEROP=1`.
That fails for a reason that has nothing to do with build systems — a
Linux-target interop stdlib needs an Objective-C `NSString`/`NSArray`/
`NSDictionary` to link against, and none exists (swift-corelibs-foundation is
written in Swift; GNUstep is the wrong class ABI).

This is the **Darwin-target** stdlib, which is interop-native by design. It is
exactly what Xcode builds every day. The only unusual thing is the host.

That reframing moves the problem from "write an ObjC Foundation" to "supply a
Darwin sysroot and defeat the build system's host==Darwin assumptions", and
those are ordinary engineering.

## What each side supplies

| piece | where it comes from |
|---|---|
| `swiftc`, `clang`, `ld64.lld` | stock swift.org 6.2.4 Linux toolchain — its LLVM already has the arm64 Mach-O backend and understands `arm64-apple-macos` |
| Darwin C headers (355) | machorun's self-hosted `sdk/` (`~/machorun/docs/SDK_SURVEY.md`) |
| `libSystem.B.tbd`, `libobjc.A.tbd` | machorun's `sdk/usr/lib` |
| objc4 headers (`NSObject.h`, `objc-internal.h`, …) | `~/machorun/vendor/objc4` — Apple's own open source |
| CoreFoundation headers (83) | swift-corelibs-foundation `Sources/CoreFoundation/include` — Apple's own open source |
| libc++ headers | stock LLVM 18 (`SDK_SURVEY` §2.5 measured this as a drop-in for Apple's) |
| `Foundation/Foundation.h` | **clean-room** — the one piece with no open-source original |
| `setjmp.h`, `signal.h`, `MacTypes.h` | **clean-room** — reached by CF, absent from machorun's SDK because objc4 never opened them |

## The load-bearing measurement

`stdlib/public/core/CMakeLists.txt` leaves `swift_core_framework_depends`
**empty** on Darwin, and `swift_core_private_link_libraries` gets entries only
for Windows and Haiku. **libswiftCore links no Foundation and no
CoreFoundation.** Of the 19 distinct `NS*` identifiers the runtime reaches, all
but `NSObject` (whose class comes from objc4) are resolved with
`objc_lookUpClass` at run time.

So Foundation is a **compile-time declarations** problem, not a link problem —
which is why a hand-written umbrella header can close it and why the wall
OBJC_RUNTIME.md hit does not apply here.

## Order of work

1. Stage the sysroot (`scripts/stage_sdk.sh`), smoke-test it by compiling one
   ObjC++ TU that imports Foundation + CoreFoundation + objc-internal.
2. Configure stdlib-only against the stock toolchain (`scripts/configure.sh`) —
   `SWIFT_INCLUDE_TOOLS=OFF`, so no compiler bootstrap, no LLVM build.
3. Build `swiftCore-macosx-arm64`. Core first; Concurrency and the overlays are
   separate libraries and a partial with a precise wall is a real result.
4. Verify the artifact is Mach-O arm64 and exports the `swift_` runtime surface.
5. If reachable, link a trivial Swift Mach-O against it and run it under
   machorun.

Vendored source stays a pristine git checkout; every edit is applied by
`scripts/apply_patches.py` (idempotent, anchor-asserted) and captured as a diff
by `scripts/snapshot_patches.sh`. Honest walls beat forced success.
