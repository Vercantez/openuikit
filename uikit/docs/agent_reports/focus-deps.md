# Focus deps — APP LADDER rung 1 dependency rows

mozilla-mobile/focus-ios **`a2832521c1daa0c23419c73705ae043ed60c9791`**.
Worktree branch `agent/focus-deps`. Sources never patched. No
`Package.resolved`. Did not touch `scripts/vendor_pins.sh`, `env/`, or
`scripts/env/`.

No rendering rule changed. Catalyst **124/124**. iOS suite **112/113**
(known `corner_radius` 99.411). Real-app floors held
**99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 /
82.17 / 99.86 / 99.734 / 85.393**. Linux `swift:6.2-noble` `openrender`
green.

## What was measured

Focus `Package.resolved` pins (corpus, never patched):

| dep | pin | identity |
|---|---|---|
| SnapKit | 5.7.0 `e74fe2a978d1216c3602b129447c7301573cc2d8` | SPM |
| glean-swift | 58.0.0 `724814f167bf42e33fafa856f7d19fc752beca2c` | **binary xcframework** |
| sentry-cocoa | 8.20.0 `b847a202a517a90763e8fd0656d8028aeee7b78d` | 33.5 % ObjC |
| Fuzi | 3.1.3 `f08c8323da21e985f3772610753bcfc652c2103f` | libxml2 |

Clones: `scratch/ladder-corpus/deps/{SnapKit,Glean,Sentry,Fuzi}` per
`clone_deps.sh`. mozilla/glean v58 Swift (`Glean.initialize`, FFI
`gleanInitialize`, `HttpPingUploader`) does not compile on Linux. The
guest/corelibs `Glean` module carries the **names Blockzilla uses**.

Ingest of Blockzilla (`Tools/ingest/xcodeproj_to_package.py`):

| | `no_port` |
|---|---|
| focus-e2e after harness-stub products | **14** (SnapKit, Fuzi, Sentry, UIHelpers, FocusAppServices, AppShortcuts, WebKit, LocalAuthentication, SafariServices, AudioToolbox, CoreHaptics, Network, PassKit, StoreKit) |
| this branch | **11** — SnapKit, Fuzi, Sentry gone |

Remaining 11 are local packages (UIHelpers, AppShortcuts),
FocusAppServices, and Apple frameworks this branch does not port.

## 1. SnapKit

**Before (macOS vs OpenUIKit UIKit):** `/tmp/snapkit-ouik` compiled 36/37
DSL files; the only miss was Debugging.swift
`non-'@objc' property 'description' declared in 'NSLayoutConstraint'
cannot be overridden from extension`.

**Rule:** `NSLayoutConstraint: NSObject` and `UILayoutGuide: NSObject`
(UIKit's identity; associated objects at LayoutConstraintItem.swift:82
need an NSObject host). `UIViewController.topLayoutGuide` /
`bottomLayoutGuide` vend a view-backed `UILayoutSupport` so
Tests.swift:722 compiles (length = `safeAreaInsets` of an unattached VC
= 0). Linux associated objects: `OpenUIKitObjectiveC` (not a target
named `ObjectiveC` — that made `canImport(ObjectiveC)` true in OpenUIKit
and compiled `@objc` with interop disabled; MEASURED swift:6.2-noble
openrender).

**After:** unmodified SnapKit 5.7.0 in `Sources/SnapKit/` against the
OpenUIKit `UIKit` product (`canImport(UIKit)` is true on macOS). Darwin
includes Debugging.swift. Linux **excludes** Debugging.swift only:
`type(of: object).description()` needs `AnyObject.Type.description()`
which Darwin has via NSObject and Linux does not (MEASURED
Debugging.swift:153). Not a SnapKit source patch.

Darwin `swift test --filter SnapKitTests`: **31/31** upstream tests
pass, plus 2 OpenUIKit helpers. Linux `swift build --target SnapKit`
green. Ingest emits
`.product(name: "SnapKit", package: "OpenUIKit", condition: .when(platforms: [.linux]))`.

## 2. Glean

**Before:** RealAppProbe Settings-only stub (`setUploadEnabled`,
`SettingsScreen.setAsDefaultBrowserPressed.add()`,
`ShowSearchSuggestions.changedFromSettings.record`). glean-swift 58.0.0
is a `.binaryTarget` zip. mozilla/glean v58 Swift does not compile on
Linux.

**After:** `Sources/RealAppProbe/FocusModules/Glean/Glean.swift` carries
`Glean.initialize(uploadEnabled:configuration:buildInfo:)`,
`handleCustomUrl`, metric types with in-process storage, and the
GleanMetrics nested types Blockzilla names at a2832521
(`App`, `Browser`, `BrowserSearch`, `BrowserMenu`,
`DefaultBrowserOnboarding`, `MozillaProducts`, `Onboarding`,
`Preferences`, `Search`, `SearchSuggestions`, `SettingsScreen`,
`Shortcuts`, `ShowSearchSuggestions`, `Siri`, `TrackingProtection`,
`UrlInteraction`, `Webview`, `GleanBuild.info`). No network, no FFI.
Darwin+Linux `swift build --target Glean` green. `GleanTests` on Darwin
pass. Guest already compiles this path (`FocusModules/Glean`).

## 3. Sentry

**Before:** ingest `no_port` Sentry (ObjC class).

**After:** fail-closed `Sources/Sentry/Sentry.swift` with Focus
signatures from sentry-cocoa 8.20.0 `SentrySDK.h` `NS_SWIFT_NAME`:
`start(configureOptions:)`, `capture(message:/error:/exception:)`,
`configureScope`, `crash()` no-op (`isEnabled` stays false). Linux
corelibs has no `NSException` (MEASURED Sentry.swift:99); the module
vends a local `NSException` on Linux only. Darwin uses Foundation's.
`SentryTests` pass on Darwin. Linux `swift build --target Sentry` green.

## 4. `import os.log` (Nimbus)

**Before (focus-e2e):** `NimbusWrapper.swift:5 no such module 'os.log'`.
A SwiftPM target named `"os.log"` compiles as **`os_log`**. Generated
package excluded that one file.

**After:** `Sources/os/include/module.modulemap` clang submodules
`os.log` / `os.signpost` on the Linux `os` target (`publicHeadersPath`).
MEASURED swift:6.2-noble OSTests `import os.log` still fails — SwiftPM
does not surface clang submodules of a Swift overlay the way the SDK
does. Ingest therefore rewrites generated copies
`import os.log` / `import os.signpost` → `import os` (the `os` product
already exports `Logger` / `OSLog` / `os_log`). Corpus unpatched.
NimbusWrapper no longer needs a generated-package exclude.

## 5. libkern (vendored Deferred)

**Before:** `Deferred/ReadWriteLock.swift` `import Foundation` only,
then `OSAtomicCompareAndSwap32Barrier` (5) and `OSSpinLockLock/Unlock`
(2). Darwin Foundation re-exports libkern; Linux does not.

**After:** Swift-only `Sources/libkern/Libkern.swift` (process mutex,
not lock-free; not a C symbol that would collide with Darwin libSystem).
Product `libkern` on Linux, `OpenUIKitLibkern` on Darwin. Ingest
prepends `import libkern` on generated copies that name those symbols.
`LibkernTests`: 1000 concurrent CAS → 1000; spinlock serializes to 1000.
Linux `swift build --target libkern` green.

## 6. Fuzi (libxml2)

**Before:** ingest `no_port` Fuzi.

**After:** unmodified Fuzi 3.1.3 in `Sources/Fuzi/`. Darwin `import
libxml2` is the SDK. Linux `CLibXML2` systemLibrary (pkg-config
`libxml-2.0`); umbrella includes `xpathInternals.h` because Ubuntu
noble's `xmlXPathRegisterNs` lives there (MEASURED Queryable.swift:291).
`LinuxCFString.swift` is **not** upstream: corelibs has no
`CFStringConvertIANACharSetNameToEncoding` (MEASURED Document.swift:36);
unrecognized IANA names fall back to UTF-8, which is Focus OpenSearch.
`FuziTests` parse an OpenSearch-shaped document. Linux
`swift build --target Fuzi` green (`libxml2-dev`).

## OpenUIKit gained

- `NSLayoutConstraint` / `UILayoutGuide` inherit `NSObject`
- `UIViewController.topLayoutGuide` / `bottomLayoutGuide`
- Linux `OpenUIKitObjectiveC` associated-object store (UIKit
  `@_exported`)
- Products: SnapKit, Sentry, Fuzi, libkern
- Glean surface Focus actually calls
- Ingest ports + linux-conditioned `.product` lines + libkern / os.log
  copy rewrites

## Guest route

Glean is already under `Sources/RealAppProbe/FocusModules/Glean` (guest
builder picks it up). SnapKit / Sentry / Fuzi / libkern are OpenUIKit
package products; ingest emits them linux-conditioned. `full/` wiring
for those products on the guest load list is the operator's pin advance
(this branch does not edit `full/`). Clang `os.log` did not resolve in
SwiftPM; ingest rewrite is the corelibs path.

## Gates

- Catalyst: **124/124** (`/tmp/gate-focus-deps`)
- iOS suite: **112/113** `SKIP_CAPTURE=1` `/tmp/suite-focus-deps`
  (`corner_radius`)
- Real-app 3x: floors unchanged vs `/tmp/golden_realapp_ios`
- Darwin: SnapKit 31/31, Glean/Sentry/Libkern/Fuzi/OS tests, Auto Layout
  tests, ingest 37 tests
- Linux `swift:6.2-noble`: `openrender` release; SnapKit, Fuzi, Sentry,
  libkern, Glean, os targets
- No `Package.resolved`
