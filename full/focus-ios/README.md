# focus-ios phase 4 — real SnapKit plus controller launch compatibility

**Reproduce:** `full/focus-ios/build_census.sh [OUTDIR]`
**Pins (by commit):** focus-ios `a2832521` · SnapKit `250529be` · OpenUIKit `9c2aace`
(built fresh from a clone; `~/uikit` is read-only and is never written).

Phase 1 reported 1,066 literal `error:` lines over **104 of 179** files and said
so as a lower bound. With the module walls cleared the same census reaches **182
files**. The old instrument then reported 2,922 lines, but that included Swift's
rendered copy of every diagnostic (and even `error:` text in source snippets).
Replaying the saved logs through the corrected primary-diagnostic parser gives
**1,454** initially, **1,262** after OpenUIKit #94 milestone 1, **1,116** after
compiling real SnapKit under the explicit exclusion below, and **1,025** after
the controller/layout increment at OpenUIKit `9c2aace`. SnapKit removed 146
primary diagnostics overall; the controller increment removed another 91 net.
All runs use `-wmo`; the deliberately broad 182-file source inventory remains
the saturation denominator (and is not the Xcode target inventory; see below).

```
STAGE                PRIMARY DIAGNOSTICS   what it means
stub-Glean                     0   \
stub-FocusAppServices          0    |  six stub modules, all compile clean
stub-WebKit                    0    |  against OpenUIKit
stub-Sentry                    0    |
stub-Fuzi                      0    |
stub-MobileCoreServices        0   /
snapkit                        0   REAL upstream source, 36/37 files (see below)
target-UIHelpers              21   \
target-DesignSystem           22    |  focus-ios's own SPM targets,
target-Widget                  6    |  vs OpenUIKit
target-Licenses                4    |
target-AppShortcuts            1    |
target-Onboarding              1    |
target-UIComponents            1   /
app                          969   broad saturated census, 182 files, -wmo
                          ------
TOTAL                       1025
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

## The OpenUIKit controller increment

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
MISSING TYPES     81 distinct / 207 occurrences
                  53 Apple-framework names / 135 uses   <- real gap
                  27 other / 71 · 1 app symbol / 1

MISSING MEMBERS   244 total
                  81 distinct on Apple types / 162 uses <- the #94 list
                   0 distinct SnapKit DSL   /   0 uses  <- real module loaded
```

Top of the **member** list, which is what no type census could see:

| uses | type | members |
|---|---|---|
| 44 | `UITableView` | `allowsMultipleSelection`, `backgroundView`, `beginUpdates`, `deleteRows`, `deleteSections`, … |
| 20 | `CALayer` | `anchorPoint`, `backgroundColor`, `frame`, `insertSublayer`, `maskedCorners`, `position`, … |
| 14 | `UITextField` | `attributedPlaceholder`, `autocapitalizationType`, `caretRect`, `clearButtonMode`, … |
| 12 | `UIView` | `canPerformAction`, `layoutSublayers`, `snapshotView`, `transition`, `userInterfaceLayoutDirection` |
| 9 | `UINavigationBar` | `appearance`, `setBackgroundImage`, `shadowImage`, `titleTextAttributes` |
| 8 | `UIButton` | `imageView`, `setImage` |
| 8 | `UITraitCollection` | `horizontalSizeClass`, `verticalSizeClass` |
| 8 | `WKWebView` | `addObserver`, `backForwardList`, `hasOnlySecureContent`, `observe`, `reloadFromOrigin` |

Heaviest **missing types**: `UIPasteboard` 13, `CAGradientLayer` 11, `CATransaction` 7,
`UIPageViewController` 7, `UIDropInteraction` 4. (`UIApplication`, `UIColor`,
`UIFont`, `UIViewController` also appear in the "cannot find type" list — those
are cases where an *extension* on the type failed to resolve, not the type
itself missing; they are in the member list above where they belong.)

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
   is 1,025 primary diagnostics, not 2,064 substrings.
5. **The broad `find` inventory is not the Blockzilla target.** The Xcode source
   phase has 131 Swift references: 129 exist and two generated sources
   (`Metrics.swift`, `AppNimbus.swift`) are absent from this checkout. The broad
   pass reaches 182 files only by coincidence: it adds four files belonging to
   Widgets, FocusIntent, OpenInFocus, and ContentBlocker, omits the two generated
   sources and Intents code generation, and compiles all 49 package files into
   the app module instead of importing their products. Those extra targets
   contribute 20 primary diagnostics plus one duplicate-`@main` diagnostic.
   This census remains useful for saturation, but an executable build must use
   a pinned Xcode/Package-derived source and resource inventory.

**Caveat, stated rather than discovered later:** the census targets
`arm64-apple-macos13.0`, because that is what OpenUIKit builds. One consequence
is visible in the output (`NSView.alpha` — an AppKit type resolving where iOS
code expects UIKit). Counts here are still a **lower bound** for the iOS target.

## What is still not here

This is a compile census, not yet an application link. The next build instrument
must replace the broad source pass with the exact target graph, restore its two
generated Swift inputs, compile package products as separate modules, and then
measure the resulting Mach-O link/import surface. Combine and SwiftUI currently
resolve from Apple's macOS SDK during this census; neither is yet present in the
durable Linux guest root.
