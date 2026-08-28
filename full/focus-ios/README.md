# focus-ios phase 3 — real SnapKit loads, and its 226-error wall is gone

**Reproduce:** `full/focus-ios/build_census.sh [OUTDIR]`
**Pins (by commit):** focus-ios `a2832521` · SnapKit `250529be` · OpenUIKit `ef5986d`
(built fresh from a clone; `~/uikit` is read-only and is never written).

Phase 1 measured 1,066 errors over **104 of 179** files and said so as a lower
bound. With the module walls cleared the same census reaches **182 files** and
initially reported **2,922**. OpenUIKit #94 milestone 1 reduced that to **2,538**.
Compiling real SnapKit after the one explicit diagnostic-file exclusion reduces
the current result to **2,246**. All runs use `-wmo`; 182 shipping files remain
the app denominator.

```
STAGE                     ERRORS   what it means
stub-Glean                     0   \
stub-FocusAppServices          0    |  six stub modules, all compile clean
stub-WebKit                    0    |  against OpenUIKit
stub-Sentry                    0    |
stub-Fuzi                      0    |
stub-MobileCoreServices        0   /
snapkit                        0   REAL upstream source, 36/37 files (see below)
target-UIHelpers              42   \
target-DesignSystem           44    |  focus-ios's own SPM targets,
target-Widget                 12    |  vs OpenUIKit
target-Licenses                8    |
target-AppShortcuts            2    |
target-Onboarding              2    |
target-UIComponents            2   /
app                         2134   the saturated app census, 182 files, -wmo
                          ------
TOTAL                       2246
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
MISSING TYPES     87 distinct / 436 occurrences
                  55 Apple-framework names / 280 uses   <- real gap
                  31 other / 154 · 1 app symbol / 2

MISSING MEMBERS   518 total
                  89 distinct on Apple types / 338 uses <- the #94 list
                   0 distinct SnapKit DSL   /   0 uses  <- real module loaded
```

Top of the **member** list, which is what no type census could see:

| uses | type | members |
|---|---|---|
| 88 | `UITableView` | `allowsMultipleSelection`, `backgroundView`, `beginUpdates`, `deleteRows`, `deleteSections`, … |
| 40 | `CALayer` | `anchorPoint`, `backgroundColor`, `frame`, `insertSublayer`, `maskedCorners`, `position`, … |
| 28 | `UIView` | `canPerformAction`, `layoutSublayers`, `snapshotView`, `transition`, `updateConstraints`, … |
| 28 | `UITextField` | `attributedPlaceholder`, `autocapitalizationType`, `caretRect`, `clearButtonMode`, … |
| 18 | `UIViewController` | `preferredContentSize`, `traitCollectionDidChange`, `viewDidLayoutSubviews`, `viewWillTransition` |
| 18 | `UINavigationBar` | `appearance`, `setBackgroundImage`, `shadowImage`, `titleTextAttributes` |
| 16 | `UIButton` | `imageView`, `setImage` |
| 16 | `WKWebView` | `addObserver`, `backForwardList`, `hasOnlySecureContent`, `observe`, `reloadFromOrigin` |

Heaviest **missing types**: `UIPasteboard` 26, `CAGradientLayer` 22, `CATransaction` 14,
`UIPageViewController` 14, `UIDropInteraction` 8. (`UIApplication`, `UIColor`,
`UIFont`, `UIViewController` also appear in the "cannot find type" list — those
are cases where an *extension* on the type failed to resolve, not the type
itself missing; they are in the member list above where they belong.)

## Instrument notes — three of my own bugs, each caught by a number that could not survive

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
   the previous 21 distinct / 226 `.snp` errors are now 0 / 0.

**Caveat, stated rather than discovered later:** the census targets
`arm64-apple-macos13.0`, because that is what OpenUIKit builds. One consequence
is visible in the output (`NSView.alpha` — an AppKit type resolving where iOS
code expects UIKit). Counts here are still a **lower bound** for the iOS target.

## What is NOT here

No OpenUIKit change was made and none is proposed here. The 89 members, 55
types, the `@MainActor` class and the optionality mismatches are **#94**, and go
through the gated `~/uikit` oracle process.
