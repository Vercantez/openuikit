# focus-ios port census — exact sources, real SnapKit, and OpenUIKit #94

**Reproduce broad saturation:** `full/focus-ios/build_census.sh [OUTDIR]`

**Reproduce the exact Xcode main-target row:**
`full/focus-ios/build_exact_main_census.sh --output-root NEW_ABSOLUTE_PATH
--expected-support-commit COMMIT --expected-support-tree TREE
--expected-uikit-commit COMMIT --expected-uikit-tree TREE
[--baseline-primary PREVIOUS_EXACT_MAIN_PRIMARY_TSV]`

The exact driver consumes the checked-in `focus-main-sources.json` contract:
131 target references = 129 byte-attested physical Swift inputs plus the two
reported generated-missing contracts. It does not synthesize those two files
and does not substitute the older 182-source saturation inventory. Its target
is fixed and attested as `arm64-apple-macos15.0`, the FoundationEssentials and
guest-packaging deployment floor; a caller-supplied lower target is refused.
The legacy broad instrument retains its historical macOS 13 default. Every run
uses a nonexistent output root, a no-hardlink UIKit clone, fresh SwiftPM/module
caches, clean commit/tree pins for support, Focus, SnapKit, and UIKit, and
before/after source attestations. `exact-main-primary.tsv` is a sorted,
fresh-root-independent primary-diagnostic stream for bytewise subsystem deltas;
`exact-main-result.tsv` records its count, normalized SHA-256, and raw compiler
log SHA-256. With `--baseline-primary`, `exact-main-delta.tsv` is a sorted
multiset report: it records added/removed primary rows and preserves duplicates
rather than collapsing repeated diagnostics into a set.

This host census compiles against the native macOS Foundation selected by the
SwiftPM UIKit build. It therefore measures UIKit and adjunct-framework compile
walls; it is not runtime evidence for the standalone Foundation guest facade.
Foundation behavior and the one-identity UIKit/Foundation boundary are proven
separately by the fresh cross-target Apple differential and service gates under
`full/foundation/tests/`.
**Pins (by commit):** focus-ios `a2832521` · SnapKit 5.7.0 `e74fe2a9` · OpenUIKit `5ce928c`
(built fresh from a clone; `~/uikit` is read-only and is never written).

## Source-unchanged compatibility policy

Focus is an immutable upstream input. Port work must not patch, overlay,
rewrite, or replace application or package source files. Missing Apple APIs
belong in source-compatible framework modules exposed under their original
module names; graph, resource, generated-source, and linker compatibility
belong in the build/runtime layers. Every proof must attest the exact upstream
bytes it consumes and label any separately generated build artifact. SwiftUI
and the other Apple first-party imports are therefore framework-port work, not
permission to translate their call sites inside Focus.

The corpus-wide priority list is generated in
[`../framework-roadmap/FRAMEWORK-ROADMAP.md`](../framework-roadmap/FRAMEWORK-ROADMAP.md).
Focus's exact 28-file SwiftUI boundary and staged acceptance gates are in
[`../swiftui/ROADMAP.md`](../swiftui/ROADMAP.md). OpenUIKit `5ce928c` now
implements the first exact two-file widget runtime slice and the seven-source
DesignSystem compile/renderer slice. The widget is independently proven as an
arm64 Mach-O guest under Linux machorun; this is not a claim that full SwiftUI,
Onboarding, WidgetKit, or the complete app executes yet.

## SwiftUI S1.5 census checkpoint

The raw-`swiftc` census now supplies one separately labelled, normalized
compile-only `Bundle.module` accessor to each exact target whose pinned source
resolves that member. This models the generated support the Linux build plan
must provide; it does not claim the pinned package manifest makes stock SwiftPM
generate every one of these accessors. The generated files live under the
output directory and are additional compiler inputs; no Focus source is
copied, edited, or overlaid.

Before and after all compiler processes, the census requires Focus commit
`a2832521`, a clean ordinary worktree, the exact 227-file tracked Swift
inventory, byte equality with every corresponding Git blob, and a matching
subject manifest. The byte comparison also catches source hidden from ordinary
status by ignore, assume-unchanged, or skip-worktree flags.
The pinned Swift subject digest is
`96e2b5eda3ba03f7c5963b06500ceb05d59777f37c4e61006be37ce0424398bd`.
This clears the artificial resource-accessor wall and exposes the real next
target boundary:

```text
target-UIHelpers               0
target-DesignSystem            0
target-Widget                  0
target-AppShortcuts            0
target-UIComponents            0
target-Licenses                3
target-Onboarding             64
app                          696   broad saturated census, 182 files, -wmo
                          ------
TOTAL                        763
```

The larger total is not a compatibility regression: the old raw target stage
reported one `no such module 'DesignSystem'` diagnostic and stopped, whereas
it now compiles the real DesignSystem and Widget modules and exposes all 64
Onboarding diagnostics. The independently comparable broad-app row fell from
724 at the initial local SwiftUI slice (`3cde5ad`) to 696 at S1.5, a net 28
diagnostics removed. The exact saved classification is
[`census-swiftui-s15-2026-08-28.txt`](census-swiftui-s15-2026-08-28.txt)
(SHA-256 `667821b62719a422997f4b364a5c71d082fbc4568ae000b049f59311e75a1f03`).

SnapKit now comes from the exact 5.7.0 revision named by Focus's
[`Package.resolved`](https://github.com/mozilla-mobile/focus-ios/blob/a2832521c1daa0c23419c73705ae043ed60c9791/focus-ios/Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved),
not the former diagnostic checkout of upstream `main`. At that isolated
correction checkpoint the census had an exact zero delta: SnapKit remained 0,
the broad app row remained 709, and the total remained 739 primary diagnostics.
The historical UIKit-core checkpoint below also includes the later size-class,
pointer, exact view-initializer, and Onboarding UIKit-core increments. The
SwiftUI S1.5 checkpoint above supersedes it as the current count.

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
OpenUIKit `81e1e05`, **729** after the size-class trait increment at OpenUIKit
`c166f96`, **721** after the pointer increment at OpenUIKit `26e0698`, and
**678** after the exact `UIView`/`NSCoder` initializer model at OpenUIKit
`0bba80a`, and **654** after the Focus Onboarding UIKit-core increment at
OpenUIKit `4c82757`. SnapKit removed 146 primary diagnostics overall; the
controller increment removed another 91 net; the eight subsequent OpenUIKit
commits through the coder increment removed another 278 net, and the asset
increment removed another eight across the target and broad rows. The
size-class increment removes eight missing-member errors plus two dependent
`.regular` inference errors, with no new diagnostics. The pointer increment
then removes exactly eight diagnostics with none added. Comparing the
initializer run to that pointer checkpoint, 75 diagnostic instances disappear
and 32 downstream instances become visible, for a net reduction of 43. The
Onboarding increment then removes exactly 24 diagnostic instances and exposes
none. These are diagnostic-set deltas, not claims that each removed diagnostic
corresponds to one independent API.
All runs use `-wmo`; the deliberately broad 182-file source inventory remains
the saturation denominator (and is not the Xcode target inventory; see below).

```text
STAGE                PRIMARY DIAGNOSTICS   what it means
stub-Glean                     0   \
stub-FocusAppServices          0    |  five remaining census-only modules
webkit                         0    |  reusable five-source production module
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
app                          624   broad saturated census, 182 files, -wmo
                          ------
TOTAL                        654
```

## What was built, and why each shape

| module | shape | why |
|---|---|---|
| **Glean** | **no-op** | Measured: 48 call paths, all `record`/`add`/`set`, **not one reads a value back**. Write-only telemetry can be silent without any screen or state differing. |
| **FocusAppServices** (Nimbus) | **mirrors the app's own defaults**, rest dies loudly | NOT a no-op, because the app *branches* on what it returns. The values come from `focus-ios/nimbus.fml.yaml` — `bold-tip-title: default: true` — which is also what real Nimbus returns with no server reached. Offline, these ARE the real answers. `getAvailableExperiments`/`optIn`/`optOut` trap: returning `[]` would assert the user is enrolled in nothing, which this build cannot know. |
| **WebKit** | **production module + independent guest dylib** | The former Focus-only placeholder is gone. [`../webkit/webkit_guest_sources.txt`](../webkit/webkit_guest_sources.txt) names the reusable five-source framework surface. Configuration, controllers, rules, stores, request/response metadata and policy callbacks retain real state. With no engine linked, allowed navigation fails provisionally with `WKPortableError.engineUnavailable`; it never fabricates fetch, JavaScript, history, commit, finish, or rendering success. The core package emits this as `libWebKit.dylib`. |
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

OpenUIKit `325c3d9` first cleared Focus's real one-source `UIComponents` target
with a provisional coder bridge. Its unchanged `AsyncImageView.swift` emits as
a module with a zero-byte diagnostic log. The later exact initializer model
supersedes that bridge and closes the inherited `AsyncImageView()` corner; see
below.

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

[`package_resources.py`](package_resources.py) now supplies the explicit,
fail-closed staging step for the pinned package slice: five resource roots,
124 files, and 314,632 bytes retain their exact catalog hierarchy and are
verified before and after use. Its generated `Bundle.module` accessor traps at
runtime rather than pretending Foundation bundle discovery is wired. The four
shipping DesignSystem sources still emit cleanly against the pinned OpenUIKit
commit, while [`PACKAGE_RESOURCES.md`](PACKAGE_RESOURCES.md) records the raw
PDF/SVG, `actool`, bundle-layout, Widget, Licenses, and Linux-execution limits.

OpenUIKit `c166f96` adds UIKit-measured partial size-class collections and
value-based `traitsFrom` merging, then propagates the axes through screens,
detached views/controllers, windows, and attached hierarchies. Explicit host
axes win; otherwise each screen or window uses the documented portable 600 pt
per-axis approximation. A screen/window-disagreement regression ensures a
window classifies its own bounds rather than inheriting already-resolved screen
axes. The change passes 842 native tests (2 skipped), strict release
compilation, and the Foundation-hidden 95-source Linux gate. It removes all
eight Focus size-class member errors and the two downstream inference errors;
automatic resize delivery and Apple's idiom/multitasking policy remain out of
scope.

OpenUIKit `26e0698` adds the Focus-used pointer surface: pointer interactions,
regions, styles, effects and shapes, a weak delegate, interaction/view
retargeting, and `UIButton.isPointerInteractionEnabled`. The implementation
preserves descriptor and lifecycle state but does not pretend Linux has an
Apple cursor compositor. It passes eight focused pointer tests, 850 native
tests overall (2 skipped), strict release compilation, the Foundation-hidden
96-source Mach-O gate, and the 13-check UIHelpers guest. The Focus census moves
from 699 broad-app / 729 total diagnostics to 691 / 721, exactly eight fewer
with no new diagnostics.

OpenUIKit `0bba80a` then replaces the provisional coder bridge with the exact
framework initializer shape: `UIView.init(frame:)` is a non-default designated
initializer, `UIView.init()` is a distinct convenience initializer, and
subclasses inherit the required `UIView.init?(coder: NSCoder)`.
Foundation-visible builds alias OpenUIKit's `NSCoder` to Foundation's exact
type; Foundation-hidden builds and the app shim share one OpenUIKit fallback
identity. The unchanged `AsyncImageView.swift` now supports the inherited
zero-argument construction used by `ShortcutView` without a source overlay.

That model is propagated through OpenUIKit's framework, demo, renderer, and
test subclasses, and includes UIKit-measured zero-frame geometry for the
affected controls. It passes 855 native tests (2 skipped), strict release
compilation, a Foundation-hidden 96-source Mach-O build, and all 13 UIHelpers
guest checks under Linux `machorun`. It still does not claim archive, nib, or
storyboard decoding. The census moves to 648 broad-app / 678 total diagnostics;
missing types remain 64 distinct / 154 uses across the pointer and initializer
checkpoints.

OpenUIKit `4c82757` adds the exact remaining UIKit surfaces in Focus's
non-SwiftUI Onboarding core: the inherited
`UIStackView.init(arrangedSubviews:)` convenience initializer and
margin-relative arrangement/fitting, weak `CALayerDelegate` layout dispatch
through `UIView.layoutSublayers(of:)`, UIKit's orientation-mask/raw-value
model, and controller orientation/status-bar policy override points. Layout is
deliberately synchronous and there is still no `CALayoutManager`, Core
Animation transaction scheduler, actual host rotation, or rendered system
status bar.

The exact unchanged ten-source UIKit/core Onboarding closure now emits a module
with zero errors; its only diagnostics are two upstream warnings where Focus
exposes `Combine.Published.Publisher` without importing Combine in those source
files. An independent uncontended OpenUIKit run passes all 864 tests with two
expected skips, and strict release compilation passes. Repeated validation also
passes the Foundation-hidden 96-source Mach-O build and all 13 Linux UIHelpers
guest checks. A wall-clock-only rasterizer smoke budget can exceed ten seconds
when this host is loaded; that check is outside the changed code path, while all
functional assertions remain green.

The fresh saturated census moves from 648 broad-app / 678 total diagnostics to
624 / 654. A message-multiset comparison removes exactly 24 instances and adds
zero: the stack initializer roots and their inference cascades, plus the
orientation, status-style, and layer-layout surfaces. The saved
[`census-2026-08-28.txt`](census-2026-08-28.txt) has SHA-256
`8cb485a23dd47cd442653a3d322030e418ce49ba3cad90baa4e98c9553045665`.

## Exact AppShortcuts dependency proof

The separate [`appshortcuts_proof.py`](appshortcuts_proof.py) consumes the
pinned dependency graph in order: 11 unchanged `UIHelpers` sources, the exact
unchanged `UIComponents/AsyncImageView.swift`, the four-source `DesignSystem`
production subset plus its generated `Bundle.module` accessor, and five
unchanged `AppShortcuts` sources. Against OpenUIKit `0bba80a`, all four modules
emit with zero-byte diagnostic logs. The three SwiftUI preview-only
`DesignSystem` sources remain individually pinned and explicitly excluded.
There is no source overlay, patched Focus file, adaptation setting, or generated
adaptation output; the full fail-closed contract is recorded in
[`appshortcuts-proof.md`](appshortcuts-proof.md).

This is Apple-toolchain, macOS-targeted module emission, not a linked app or a
Linux-executed guest. The raw census now also emits the generated DesignSystem
resource accessor, so its real DesignSystem prerequisite and the unchanged
AppShortcuts target both emit with zero diagnostics. Neither result is evidence
that arbitrary `.xcodeproj` files can be passed to `xcodebuild` on Linux.

## The one SnapKit vendoring exclusion

[`snapkit-exclusions.json`](snapkit-exclusions.json) records exactly one rule:
`Sources/Debugging.swift` at SHA-256
`6af70d54a6e6fb112d87f8adb93caead0bc2afc472e4bbb04347bf591be3b3e3`.
That file overrides `NSLayoutConstraint.description` from an extension through
NSObject/Objective-C dispatch. A pure-Swift OpenUIKit superclass cannot expose
that override point. The file defines no constraint construction, installation,
update, or `.snp` API; omitting it loses only SnapKit's custom debug string.

[`snapkit_sources.py`](snapkit_sources.py) refuses rather than widening this
rule silently. It requires Focus commit `a2832521` and the clean, tracked workspace
lock at SHA-256
`632a0df0276ba7828f456ae3964f158fb7115d05f175ddf637abdd7ab4a4633b`,
parses its one exact SnapKit 5.7.0 pin, and requires the dependency checkout to
be that same `e74fe2a9` commit. It also requires both reviewed source-set
digests, the approved exclusion path and bytes, and a clean tracked/disk source
inventory; rejects symlinks; records every included source hash; isolates Git
pin checks from ambient `GIT_*` redirection and global/system configuration;
and brackets `swiftc` with matching before/after attestations. The current
denominator and subject are:

```
37 discovered = 36 included + 1 excluded
all source digest:      17335843f47647248c46f95493241753548b14a52ff70e5c0d77ec485c510ba8
included source digest: a56f18961b549a4a90d925520db8d177cec2e734a2381eefb6a191b59bdfdc6e
```

`python3 full/focus-ios/test_snapkit_sources.py -v` supplies positive coverage
and negative controls for Focus and SnapKit pin drift, workspace-lock byte and
parsed-pin drift, a rehashed lock that differs from pinned HEAD, source-digest
and excluded-byte drift, staged-only lock drift, scope expansion, dirty tracked
sources, and untracked sources (including ignored files), plus ambient Git
repository redirection.

## The saturated census

```
MISSING TYPES     63 distinct / 152 occurrences
                  39 Apple-framework names / 91 uses    <- real gap
                  23 other / 60 · 1 app symbol / 1

MISSING MEMBERS   154 total
                  49 distinct on Apple types / 81 uses  <- the #94 list
                   0 distinct SnapKit DSL   /   0 uses  <- real module loaded
```

Top of the **member** list, which is what no type census could see:

| uses | type | members |
|---|---|---|
| 14 | `UITextField` | `attributedPlaceholder`, `autocapitalizationType`, `caretRect`, `clearButtonMode`, … |
| 9 | `UIButton` | `contentEdgeInsets`, `contentHorizontalAlignment`, `semanticContentAttribute`, `titleEdgeInsets` |
| 8 | `WKWebView` | `addObserver`, `backForwardList`, `hasOnlySecureContent`, `observe`, `reloadFromOrigin` |
| 6 | `UIView` | `canPerformAction`, `snapshotView`, `userInterfaceLayoutDirection` |
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
   is 654 primary diagnostics.
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
