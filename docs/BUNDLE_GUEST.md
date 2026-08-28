# Foundation.Bundle guest execution

Measured 2026-08-28.  This is a Focus launch-path vertical slice, not a claim
that Foundation's Bundle surface is complete.

## Result

A Swift executable imports `Foundation.Bundle` from this repository's real
`libFoundation.dylib`, is packaged in a flat iOS-style
`FocusBundleProbe.app`, and runs as arm64 Darwin Mach-O under machorun on
Linux.  It resolves `launch_probe.txt` through
`Bundle.main.path(forResource:ofType:)`, opens the returned path, reads 23
bytes, and agrees byte-for-byte with the same source run against Apple's
Foundation on macOS 26.5.2:

```
bundle=FocusBundleProbe.app
resource=launch_probe.txt
bytes=23
content=focus-bundle-oracle-v1
missing=nil
PASS
```

Run both sides:

```
scripts/oracle_macos.sh
scripts/run_bundle_guest.sh
```

The guest runner also proves two negative controls.  Replacing the resource
with known-wrong bytes exits 73 and prints
`ORACLE_FAIL content=focus-bundle-oracle-MUTATED`.  Removing only
`/usr/lib/libFoundation.dylib` from an isolated guest root exits 72 at the
loader with `cannot find dylib '/usr/lib/libFoundation.dylib'` and names the
probe as its requirer.

## Why this implementation, rather than CFBundle

The two existing Foundation tracks were audited first:

* `~/swift-macho-linux/full/foundation` has a real, executing
  FoundationEssentials port and URL/JSON guest oracles.  FoundationEssentials
  intentionally does not provide the `Bundle` class or a module named
  `Foundation`.
* This repository has the open-source CoreFoundation Bundle sources in its
  full-CF build, but that is not yet a usable production CoreFoundation dylib.
  `scripts/build_cf_probes.sh t18` currently reaches
  `CFBundleGetMainBundle()` and then aborts at the loud `getsegbyname` stub.
  The staged `CoreFoundation.framework/CoreFoundation` is a one-symbol
  declarations placeholder.  Calling either of those a working Bundle would
  be false.

The smallest honest slice therefore implements main-executable discovery and
resource path lookup in the Swift Foundation overlay.  It uses
`_NSGetExecutablePath`, whose machorun implementation reports the mapped main
Mach-O rather than Linux's `/proc/self/exe` (which would name the loader).
`access(2)` validates positive and missing-resource results.  No host
Foundation code participates in the guest.

## Artifact identity and closure

The measured source state began at:

```
foundation-macho  b4e6df1286d788d5e2194e92ff8d4a3212e5a5c9
machorun           e6b1745bef09ac8f1e2d6e6c83f7c70d6dbe49a5
swiftcore-macho    12cf3901286f1b81aab0075f19296ddfcc0452dc
Swift compiler     6.2.4 RELEASE, aarch64-unknown-linux-gnu
```

`tests/baselines/t22_bundle_inputs.sha256` content-pins 21 source, executable,
loader, runner and dylib inputs.  `tests/baselines/t22_bundle_closure.tsv` pins every
direct and recursive load command: eight distinct dylibs, all checked present
under the exact guest root before execution. The runner discovers that closure
recursively from the load commands rather than relying on a handwritten image
list. The executable has 35 undefined
imports and Foundation has 71; successful loading/execution resolves them from
that closure.  The runner separately checks that the app imports the Bundle
symbols, `libFoundation.dylib` defines them, and the declarations-only
Foundation placeholder is absent.

The executable's direct loads are:

```
/usr/lib/swift/libswiftCore.dylib
/usr/lib/libFoundation.dylib
/usr/lib/libFoundationSlice.dylib
/usr/lib/libswiftcompat.dylib
/usr/lib/libSystem.B.dylib
/usr/lib/libobjc.A.dylib
```

The current deterministic SHA-256 values for the app and implementation are:

```
ea284853d663b18d56a3d9b1ff9076a6fb00c950d724862ca09ea19f2602c5fc  FocusBundleProbe
9661e9521716503babaaa110c55afc40784bc3a246ccf88ac76c8f3812167637  libFoundation.dylib
```

The content pins cover the dylib copies machorun actually loads, and the runner
first requires those bytes to match the link-time copies. They intentionally
fail after a substrate or source change.  They
must be refreshed only after rerunning the Apple differential and both guest
controls; a silent root upgrade is not the same experiment.

## Generalisation boundaries

This executable is linked through the port's explicit `-lFoundation` route,
whose install name is `/usr/lib/libFoundation.dylib`. Ordinary Xcode output
normally requests
`/System/Library/Frameworks/Foundation.framework/Foundation`; that guest-root
location is still a declarations placeholder. Consequently this milestone is
not yet proof that an otherwise-unmodified Xcode linker command reaches the
implementation.

The Swift `Bundle` here is also a narrow source-compatibility type, not yet the
Apple Objective-C `NSBundle` class hierarchy. It is a final pure-Swift class
and cannot currently cross APIs expecting `NSObject`/`NSBundle` ABI. Resource
lookup intentionally accepts only the simple relative name/directory grammar
needed by Focus; nil/empty-name enumeration, symlink containment, and Apple's
broader path semantics remain unimplemented.

## Exact scope and next Focus wall

Implemented and executed:

* `Bundle.main`
* `bundlePath` and `resourcePath`
* `path(forResource:ofType:)`
* `path(forResource:ofType:inDirectory:)`
* flat iOS `.app` executable/resource layout
* missing-resource `nil`

Not implemented: Info.plist dictionaries and bundle identifiers, localisation,
`Bundle(for:)`, arbitrary bundle initialisers, app-store receipt paths, or
URL-valued APIs.  The code recognises the conventional macOS
`Contents/MacOS`/`Contents/Resources` shape, but only the Focus-relevant flat
iOS layout is oracle-tested here.

The next Bundle-shaped Focus launch blocker is
`Bundle.main.url(forResource:withExtension:)`, followed by
`String(contentsOf:)` for WebView's bundled JavaScript.  The real URL
implementation already executes in FoundationEssentials under machorun, but it
is not yet composed into this module named Foundation.  That module/runtime
composition, plus `object(forInfoDictionaryKey:)`/`bundleIdentifier` for
AppDelegate, is the next bounded Foundation milestone.
