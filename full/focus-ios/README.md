# focus-ios current port census — exact sources, real SnapKit, and OpenUIKit #94

**Reproduce:** `full/focus-ios/build_census.sh [OUTDIR]`
**Pins (by commit):** focus-ios `a2832521` · SnapKit `250529be` · OpenUIKit `81e1e05`
(built fresh from a clone; `~/uikit` is read-only and is never written).

Phase 1 reported 1,066 literal `error:` lines over **104 of 179** files and said
so as a lower bound. With the module walls cleared the same census reaches **182
files**. The old instrument then reported 2,922 lines, but that included Swift's
rendered copy of every diagnostic (and even `error:` text in source snippets).
Replaying the saved logs through the corrected primary-diagnostic parser gives
**1,454** initially, **1,262** after OpenUIKit #94 milestone 1, **1,116** after
compiling real SnapKit under the explicit exclusion below, **1,025** after the
controller/layout increment at OpenUIKit `9c2aace`, **832** after the
application-shell, table, shortcut/activity, and process-local pasteboard
increments through OpenUIKit `4be65c9`, **751** after the Focus UIHelpers
increment at OpenUIKit `1ae41f9`, and **747** after the UIView coder increment
at OpenUIKit `325c3d9`, then **739** after the named-asset API increment at
OpenUIKit `81e1e05`. SnapKit removed 146 primary diagnostics overall; the
controller increment removed another 91 net; the eight subsequent OpenUIKit
commits through the coder increment removed another 278 net, and the asset
increment removed another eight across the target and broad rows. All runs use
`-wmo`; the deliberately
broad 182-file source inventory remains the saturation denominator (and is not
the Xcode target inventory; see below).

```
STAGE                PRIMARY DIAGNOSTICS   what it means
stub-Glean                     0   \
stub-FocusAppServices          0    |  six stub modules, all compile clean
stub-WebKit                    0    |  against OpenUIKit
stub-Sentry                    0    |
stub-Fuzi                      0    |
stub-MobileCoreServices        0   /
snapkit                        0   REAL upstream source, 36/37 files (see below)
target-UIHelpers               0   \
target-DesignSystem           18    |  focus-ios's own SPM targets,
target-Widget                  6    |  vs OpenUIKit
target-Licenses                4    |
target-AppShortcuts            1    |
target-Onboarding              1    |
target-UIComponents            0   /
app                          709   broad saturated census, 182 files, -wmo
                          ------
TOTAL                        739
```

## What was built, and why each shape

| module | shape | why |
|---|---|---|
| **Glean** | **no-op** | Measured: 48 call paths, all `record`/`add`/`set`, **not one reads a value back**. Write-only telemetry can be silent without any screen or state differing. |
| **FocusAppServices** (Nimbus) | **mirrors the app's own defaults**, rest dies loudly | NOT a no-op, because the app *branches* on what it returns. The values come from `focus-ios/nimbus.fml.yaml` — `bold-tip-title: default: true` — which is also what real Nimbus returns with no server reached. Offline, these ARE the real answers. `getAvailableExperiments`/`optIn`/`optOut` trap: returning `[]` would assert the user is enrolled in nothing, which this build cannot know. |
| **WebKit** | **8 inert-but-real + 20 die-loudly** | The launch path constructs a `WKWebView` (traced) but hides its container until URL submission. So the first screen needs a web view that *exists*, not one that *works*. `load()` is inert rather than fake-successful — a silent success would put the URL bar into browsing mode over a blank page. |
| **Sentry** | no-op, **except `crash()`** | Write-only, like Glean. `crash()` is a deliberate crash trigger behind a debug button; a no-op would make that button lie. |
| **Fuzi** | **all die loudly** | Its entire job is to *return parsed content*. An empty document would hand the app a search engine with no name and no URL template that it would treat as valid. |
| **MobileCoreServices** | UTI constants | iOS-only, absent from the macOS SDK. A measurement enabler, stated as such. |
| **SnapKit** | **the REAL upstream source, recompiled** | MIT, pure Swift over `NSLayoutConstraint`. 36 of 37 upstream Swift files compile into the real module. `Debugging.swift` is excluded by the narrow, pinned rule below; it contributes diagnostic descriptions, not layout behavior or DSL API. |

## The OpenUIKit compatibility increments

OpenUIKit `9c2aace` implements behavior rather than name-only declarations:
bottom-up constraint updates, controller-bracketed layout callbacks, legacy
trait delivery, content-container propagation, transition-coordinator shape,
and lazy `UIViewController.init(nibName:bundle:)`. The nil/nil initializer is
the ordinary programmatic path; explicit nib requests fail loudly only if the
base `loadView()` must decode them, while subclasses that build a view themselves
continue to work.

The increment passes 773 OpenUIKit tests (2 skipped), including eight focused
controller/layout controls. Its 19 nib-initializer call sites remove 57 primary
diagnostics from the broad app row; the other controller types and members bring
the measured net reduction to 91 while also exposing some downstream errors.

The next six commits preserve that standard: delegate initialization and launch
shell behavior, shortcut/activity URLs, table editing/reuse/initializer
compatibility, and a thread-safe process-local pasteboard are implemented and
tested, not merely declared. The final pasteboard source is also compiled as
part of the 92-file Foundation-free OpenUIKit Mach-O target and its 11-check
guest oracle runs under `machorun` on Linux. The pasteboard increment alone
removes 12 of the 13 previous broad-census `UIPasteboard` diagnostics.

OpenUIKit `1ae41f9` then clears all 21 diagnostics in Focus's real 11-source
`UIHelpers` package target and emits `UIHelpers.swiftmodule`. The implemented
surfaces include stateful button images, single-line label shrinking, legacy
image contexts, image alpha drawing, explicit `CALayer` trees and axial
`CAGradientLayer`, orientation/text-input descriptions, and interruption-safe
`UIView.transition`. A real-iOS simulator oracle fixes the observable values;
824 native tests pass (2 skipped). A Foundation-invisible build compiles all 94
OpenUIKit Swift sources; `full/scripts/run_uihelpers.sh` then executes 13
behavioral checks under Linux `machorun` across delegate reflection, button
state/layout, gradient ordering/removal, nested legacy image contexts,
`CALayer.render(in:)`, alpha drawing, animation interruption, orientation, and
text-input mode. The checked-in runner supplies the required read-only
OpenUIKit resources and refuses a stale guest root or renderer. A separate
gradient scene is byte-identical to the native render. This increment removes
21 target diagnostics and 60 broad-app diagnostics; it also exposes additional
downstream diagnostics, so those reductions need not add linearly.

OpenUIKit `325c3d9` adds the designated, non-required
`UIView.init?(coder: AnyObject)` bridge needed by code-only subclasses whose
concrete `init?(coder: NSCoder)` calls `super`. Focus's real one-source
`UIComponents` package target now emits a 52,628-byte module with a zero-byte
diagnostic log; the broad app row falls by three and the total by four. The
change passes 827 native tests (2 skipped), strict-concurrency compilation, and
the same Foundation-invisible 94-source Linux Mach-O build. It deliberately
does not claim nib/storyboard support: the opaque token is ignored, the
initializer always produces a zero-frame view, and UIKit's separate inherited
`Subclass()` initializer corner remains open for Focus's `AsyncImageView`.

OpenUIKit `81e1e05` adds the bundle-selecting `UIImage` and `UIColor` named
asset initializers used by Focus's `DesignSystem`. The portable subset loads
loose PNG/JPEG scale variants and raw universal sRGB color sets, including
luminosity light/dark entries. Explicit bundles are isolated; path traversal,
non-finite scales, malformed alpha, gamut-qualified entries, compiled catalogs,
and unsupported vector formats have fail-closed tests. The change passes 834
native tests (2 skipped), strict-concurrency compilation, and the
Foundation-invisible 95-source Linux Mach-O build plus its 13-check guest.

The untouched seven-source target row falls from 22 to 18 diagnostics, exactly
removing the four overload errors. With the three preview-only SwiftUI files
excluded and a generated `Bundle.module` accessor, Focus's four shipping
`DesignSystem` sources emit a module with a zero-byte diagnostic log. That is a
source/module milestone, not a runtime-image claim: the pinned package omits
the catalogs from `Package.swift`, and all 44 payloads behind its 24 forced
image names are still vector PDF/SVG. The Linux builder must stage resources
explicitly and rasterize or decode those vectors before the force unwraps are
safe at runtime; [`../../uikit/docs/NAMED_ASSETS.md`](../../../uikit/docs/NAMED_ASSETS.md)
records the precise boundary.

## The one SnapKit vendoring exclusion

[`snapkit-exclusions.json`](snapkit-exclusions.json) records exactly one rule:
`Sources/Debugging.swift` at SHA-256
`6af70d54a6e6fb112d87f8adb93caead0bc2afc472e4bbb04347bf591be3b3e3`.
That file overrides `NSLayoutConstraint.description` from an extension through
NSObject/Objective-C dispatch. A pure-Swift OpenUIKit superclass cannot expose
that override point. The file defines no constraint construction, installation,
update, or `.snp` API; omitting it loses only SnapKit's custom debug string.

[`snapkit_sources.py`](snapkit_sources.py) refuses rather than widening this
rule silently. It requires the exact repository commit and approved path, checks
the excluded bytes, requires a clean tracked/disk source inventory, rejects
symlinks, records every included source hash, and brackets `swiftc` with matching
before/after attestations. The current denominator and subject are:

```
37 discovered = 36 included + 1 excluded
included source digest: 33004a4b0f0a7361f526c54e7384d42519e967d304e30938deb4ff98152e9a7f
```

`python3 full/focus-ios/test_snapkit_sources.py -v` supplies positive coverage
and negative controls for pin drift, byte drift, scope expansion, dirty tracked
sources, and untracked sources.

## The saturated census

```
MISSING TYPES     68 distinct / 159 occurrences
                  44 Apple-framework names / 98 uses    <- real gap
                  23 other / 60 · 1 app symbol / 1

MISSING MEMBERS   156 total
                  49 distinct on Apple types / 84 uses  <- the #94 list
                   0 distinct SnapKit DSL   /   0 uses  <- real module loaded
```

Top of the **member** list, which is what no type census could see:

| uses | type | members |
|---|---|---|
| 14 | `UITextField` | `attributedPlaceholder`, `autocapitalizationType`, `caretRect`, `clearButtonMode`, … |
| 8 | `UITraitCollection` | `horizontalSizeClass`, `verticalSizeClass` |
| 8 | `WKWebView` | `addObserver`, `backForwardList`, `hasOnlySecureContent`, `observe`, `reloadFromOrigin` |
| 7 | `UIView` | `canPerformAction`, `layoutSublayers`, `snapshotView`, `userInterfaceLayoutDirection` |
| 7 | `UIBarButtonItem` | `accessibilityIdentifier` |
| 7 | `UINavigationBar` | `setBackgroundImage`, `shadowImage`, `titleTextAttributes` |
| 6 | `CAGradientLayer` | `add`, `animation`, `drawsAsynchronously`, `mask`, `removeAnimation` |
| 5 | `CALayer` | `maskedCorners` |

Heaviest **missing types**: `CATransaction` 7, `UIPageViewController` 7, and
`UIDropInteraction` 4. (`UIApplication`, `UIColor`,
`UIFont`, `UIViewController` also appear in the "cannot find type" list — those
are cases where an *extension* on the type failed to resolve, not the type
itself missing; they are in the member list above where they belong.) The one
remaining `UIPasteboard` entry comes from a source that imports SwiftUI but not
UIKit: iOS SwiftUI re-exports UIKit and the source typechecks against the iOS
simulator SDK, while macOS SwiftUI does not. It is a target artifact, not a
remaining pasteboard declaration gap.

## Instrument notes — five bugs, each caught by a number that could not survive

1. **`$(find ...)` unquoted split paths containing spaces.** focus-ios has
   `Preview Files/` and `SwiftUI Onboarding/`. The split fragments arrived as
   `unexpected input file` errors *inside the census*, and DesignSystem read as
   3 errors when it has 44. Fixed with a NUL-safe read; the tell was an error
   kind that named a directory rather than a symbol.
2. **A test file inside `BlockzillaPackage/Tests/` slipped past the
   `/focus-ios-tests/` exclusion** and halted the whole app census on
   `no such module 'XCTest'` — 182 shipping files reported as 2 errors.
3. **`import SnapKit` halted the app census** while SnapKit itself failed. Both 2
   and 3 are the *same shape as phase 1's 4-error false green*: an unrelated
   early failure making the subject look almost clean. The census retains a
   visibly reported name-only fallback for a failed SnapKit build, but does not
   emit it when the real module succeeds. The current run loads the real module:
   the previous 21 distinct / 113 `.snp` primary diagnostics are now 0 / 0.
4. **Counting the substring `error:` counted every Swift diagnostic twice.**
   The compiler renders a location-bearing primary line and a second
   `` `- error:`` marker under the source; source snippets can themselves
   contain `error:` parameter labels. [`diagnostics.py`](diagnostics.py) now
   accepts only location-bearing primary lines. Its controls include both
   duplicate-rendering and source-text false positives. The saved current run
   is 751 primary diagnostics.
5. **The broad `find` inventory is not the Blockzilla target.** The Xcode source
   phase has 131 Swift references: 129 exist and two generated sources
   (`Metrics.swift`, `AppNimbus.swift`) are absent from this checkout. The broad
   pass reaches 182 files only by coincidence: it adds four files belonging to
   Widgets, FocusIntent, OpenInFocus, and ContentBlocker, omits the two generated
   sources and Intents code generation, and compiles all 49 package files into
   the app module instead of importing their products. Those extra targets
   contribute 20 primary diagnostics plus one duplicate-`@main` diagnostic.
   This census remains useful for saturation, but an executable build must use
   a pinned Xcode/Package-derived source and resource inventory. That exact
   source inventory is now recorded and fail-closed in
   [`focus-main-sources.json`](focus-main-sources.json), and the two open-source
   generated inputs can now be reproduced and byte-attested by
   [`generated_sources.py`](generated_sources.py); they are not yet integrated
   into an executable target build.

**Caveat, stated rather than discovered later:** the census targets
`arm64-apple-macos13.0`, because that is what OpenUIKit builds. One consequence
is visible in the output (`NSView.alpha` — an AppKit type resolving where iOS
code expects UIKit). Counts here are still a **lower bound** for the iOS target.

## What is still not here

This is a compile census, not yet an application link. The next build instrument
must consume the recorded exact target graph, integrate the two reconstructed
generated Swift inputs, replace the remaining proprietary Intents generation
with a measured compatible source, compile package products as separate modules,
and then measure the resulting Mach-O link/import surface. Combine and SwiftUI
currently resolve from Apple's macOS SDK during this census; neither complete
framework is yet present in the durable Linux guest root.
