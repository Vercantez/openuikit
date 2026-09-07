# Simplenote route (b): dependency wave and measured launch blockers

**Partial rung, not a successful app launch.** Automattic/simplenote-ios
`9b1bb17d8ec224a709d306e0ec34cee38bc7d933`, branch `agent/simplenote-launch`.
The app has not reached 0 errors or launched from `SPAppDelegate`. No
replacement notes screen, rewritten app classes, or empty service modules
are counted as success. Corpus sources and dependency checkouts are unpatched.

This branch carries five pinned source dependencies (30 Swift files), the
measured `UIImage` Objective-C identity needed by Gridicons, and ingest/NIB
compiler improvements. All copied dependency files have SHA-256 hashes in
`Sources/SimplenoteDependencies/PROVENANCE.json`; licenses are in
`THIRD_PARTY_LICENSES`. New targets are Darwin-only and are not added to the
guest builder or the existing RealAppProbe launch list.

## Waves and denominators

Machine: Apple Swift 6.2.1, arm64 Darwin. iOS oracle: iPhone 16 simulator,
iOS 26.1, private `OpenUIKit-ImageProbe-simplenote-launch` device.
The machine-readable source, resource, dependency and import census is
[simplenote-launch-census.json](simplenote-launch-census.json).

| wave | before → after | what the count actually measures |
|---|---|---|
| Ingest | 229 referenced Swift → **228 present + 1 missing** | Missing `Simplenote/Credentials/SPCredentials.swift`. The existing tool silently skipped this file when copying but still printed 229. It now reports both counts and the missing path. |
| Other compiled languages | **50 Objective-C + 12 C** | Separate from the 228 Swift denominator; no ObjC files silently credited as compiled. Intent-definition and CoreData-model inputs remain separate resources. |
| Raw ingest | **2 gaps / 24 unprovided modules → 2 / 19** | Five source dependency products added. This is an ingest inventory, not a Swift error count. Darwin-only support is marked in module metadata and generated package dependencies. |
| Initial Swift compiler invocation | **1 blocking import diagnostic / 228 input files** | `MagicLinkInvalidView.swift:3`: no module `Gridicons`. Semantic diagnostics are hidden behind the importer; this is not "227 files compile". |
| Four source dependencies | **0 errors / 28 upstream Swift files** | SimplenoteFoundation 11, Endpoints 10, Interlinks 1, Search 6. Source branches are selected for macOS; Foundation uses Apple CoreData/AppKit here. |
| Gridicons | **3 unique source diagnostics / 2 files → 0** | Two `@objc` return-type errors (`Gridicons.swift:10,17`) plus missing `Bundle.module` (`GridiconsGenerated.swift:430`). NSObject identity and explicit resource copying fix these without modifying either upstream source. One additional SwiftPM resource accessor is generated. |
| Final app Swift invocation | **1 blocking import diagnostic / 228 input files** | Now `NSUserActivity+Simplenote.swift:4`: no module `MobileCoreServices`. Full app semantic-error census remains blocked. |
| Isolated import probes | **18/21 imports resolve; 3 fail** | Each probe uses a distinct `-module-name SimplenoteImportCensus` so a file named Simperium.swift cannot silently import itself. Missing: Simperium, AutomatticTracks, MobileCoreServices. Resolution of an Apple SDK import is not a guest implementation claim. |
| Actual mixed app target | **1 SwiftPM graph diagnostic** | All present 228 Swift, 50 ObjC and 12 C source files copied unchanged to an isolated library target: `contains mixed language source files; feature not supported`. |
| ObjC facade boundary | **1 error on unchanged SPNavigationController.h** | `cannot find interface declaration for 'UINavigationController', superclass of 'SPNavigationController'`. Route (b) has an ObjC runtime; it does not thereby have these ObjC UIKit interfaces. |
| NIB compiler | **Pocket Casts-only entry point → 26/26 compiled inputs** | 25 XIB files plus `LaunchScreen.storyboard`. No successful runtime instantiations or launch pixels are claimed. |
| App launch | **not reached → not reached** | No fabricated 0-error count or first-screen screenshot. |

The actual entry point is `Simplenote/Supporting Files/main.m`, which passes
`SPAppDelegate` to `UIApplicationMain`. It is not a Swift `@UIApplicationMain`
app. `SPAppDelegate.m` imports `Simplenote-Swift.h` and constructs
`TagListViewController`, `SPNoteListViewController`, `SPNavigationController`
and `SPSidebarContainerViewController` in `setupDefaultWindow`. **27 of the
50 ObjC translation units import the generated Swift header.** The Swift
bridging header imports the ObjC app classes in turn. A split or staged driver
must preserve that two-way interface; removing the ObjC half would remove the
real delegate and notes list. This branch does not install a broken app target
in the main manifest.

## Dependency pins and build scope

All 12 resolved dependencies were cloned under the authorized external
`scratch/ladder-corpus/deps/<identity>` paths and checked out at the exact
revisions from the app's existing resolution file. That resolution file is
not committed. Full revisions and URLs are in the census JSON.

| dependency | pin | outcome |
|---|---|---|
| SimplenoteFoundation | `2731e4d28c42d394ddc62cd864d9f7ff96759228` | 11 unchanged files vendored; Darwin target compiles. **CoreData/AppKit SDK dependency remains.** |
| SimplenoteEndpoints | `3d1c0a5db39ca798a7de10e7faeef8ae66e941e6` | 10 unchanged files vendored; Darwin target compiles. Network behavior not exercised. |
| SimplenoteInterlinks | `be3827a5bf05c5349ed62126c3e1dc60a2a6cee6` | 1 unchanged file vendored; compiles against the vendored Foundation target. |
| SimplenoteSearch | `499d2809d169fcbeb9ff75568d9f1f937f290ffc` | 6 unchanged files vendored; Darwin target compiles. |
| Gridicons | `c904cb73e26e86463a78e1335c6f4fd54a9e9223` | 2 unchanged files + 399 resource files vendored; compiles against our UIKit/SwiftUI. Runtime PDF asset rendering not proven. |
| Simperium | `5561a15a4836efe5d068a366b60599b7b794af70` | Cloned, inspected. Package product is a **binary XCFramework**, not a source target; repository contains ObjC source. No service shim or guest build completed. |
| AutomatticTracks | `4d7d7138a9f2b36c3fd4618aa488ed9e8de2f726` | Cloned, inspected. Split Swift/ObjC subtargets with Sentry/Sodium/UIDeviceIdentifier dependencies. No fail-closed shim completed. |
| Sentry | `5421f94cc859eb65f5ae3866165a053aa634431e` | Cloned; existing Focus Sentry shim is not newly credited as a full implementation of this pin. |
| Sodium | `4f9164a0a2c9a6a7ff53a2833d54a5c79c957342` | Cloned; Darwin manifest selects Clibsodium.xcframework. Not built. |
| UIDeviceIdentifier | `4699794b08bb79a4d77785edaba6ea739e298e4b` | Cloned; ObjC target. Not built. |
| ZIPFoundation | `f6a22e7da26314b38bf9befce34ae8e4b2543090` | Cloned; not a direct app product/import in this target census. Not built. |
| ScreenObject | `5a62548524a0ad65d8e2e5d4f665981c48066253` | Cloned; UI-test dependency, not credited as an app runtime dependency. Not built. |

**Conditional-source blocker:** SimplenoteFoundation's
`UITableView+ResultsController.swift` is enclosed in `#if os(iOS)`; on this
Darwin macOS route it is inactive. The unchanged app calls
`ResultsTableAnimations` in `TagListViewController.swift:758` and
`performBatchChanges` in `SPNoteListViewController+Extensions.swift:142`.
Successful macOS compilation of the dependency does not supply those APIs.
A route-compatible implementation/target arrangement is still required; no
source-condition rewrite was made or passed off as real upstream code.

## Measured UIImage rule

The standalone simulator probe imports UIKit and ObjectiveC, creates two
`UIImage()` objects, and declares an `@objc` static factory returning UIImage.
It was compiled with `xcrun --sdk iphonesimulator swiftc -target
arm64-apple-ios26.1-simulator` and run via `simctl spawn` on the private device.
Output:

```
uiimage-superclass=NSObject
nsobject=true size=(0.0, 0.0) scale=1.0
same-equal=true distinct-empty-equal=true
objc-factory=true
```

OpenUIKit's `UIImage` now inherits `NSObject` (Foundation on host/corelibs,
ObjectiveC on the Foundation-hidden guest). The empty convenience initializer
is an override. This is a class ABI change, not a pixel-model constant; a
runtime font-cut check cannot select a superclass. Both renderer cuts remain
byte-identical in the tests below. Two new tests check the measured empty-image
geometry and actually invoke the factory through Objective-C `perform`.

**Open sample:** iOS considers distinct empty UIImages equal. The inherited
NSObject implementation uses identity equality. Content/scale/rendering-mode
equality is not measured enough to implement; recorded in `scoreboard/open.txt`.

## NIB/storyboard rows

The ladder's NIB=2 is a bucket, not two resource files. Ingest lists 25 XIBs
and one storyboard. The existing `scripts/compile_realapp_nibs.sh` only
accepted Pocket Casts' checkout and compiled three hard-coded files. Its
original default remains; the new explicit-source form is:

```
scripts/compile_realapp_nibs.sh --out /tmp/simplenote-launch-nibs <xib-or-storyboard> ...
```

All 26 app resources compile with ibtool. A storyboard produces a
`.storyboardc` directory; XIBs produce `.nib` outputs. Nothing was written
into existing fixture/golden files. Compilation does not register custom
classes, connect app IBOutlet properties, load a CoreData model, or launch
`SPAppDelegate`. `LaunchScreen.storyboard` is a launch-screen resource;
`setupDefaultWindow` creates the initial controller hierarchy programmatically.
Authentication/onboarding still refer to app XIB classes that need runtime
instantiation after the mixed app can compile.

## Remaining blockers by class

| class | measured boundary / remaining work |
|---|---|
| Mixed build graph | 228 Swift + 50 ObjC + 12 C; SwiftPM single target rejected. Staged Swift/Clang driver or a valid split with generated-header handling is absent. |
| Objective-C UIKit ABI | UINavigationController missing from current facade at the first navigation header; actual delegate also needs UIWindow/UIApplication protocols and controller/table/text interfaces. Full missing-member count is **not yet measured**. |
| Services | Simperium and AutomatticTracks imports missing. Exact fail-closed Swift and ObjC signatures still need implementation; no account/network success is fabricated. |
| Apple module | MobileCoreServices is absent on the host package path. Other SDK imports can resolve on the Mac without being guest ports. |
| Dependency platform branches | SimplenoteFoundation's iOS-only table helpers are inactive on macOS; CoreData/AppKit remain SDK-backed. |
| Generated app material | The generated SPCredentials.swift path is absent (a public SPCredentials-demo.swift exists); intent-generated classes, CoreData model compilation and Swift header generation are not yet integrated. |
| Resources | 26 compiled outputs; custom-class instantiation, Gridicons PDF assets and app bundle identity remain unproven. |
| Guest wiring | New dependency targets are Darwin-only and not added to full/scripts/build_full.sh; no changes outside uikit or pin advances. |
| Oracle launch | No first-screen iOS golden and no app launch; score **N/A**. |

## Validation

Final validation results are recorded below. The requested
`docs/agent_reports/focus-guest-linux.md` was absent in the starting checkout.
While this branch waited for the shared merge lock, the operator merged it
onto main (`3e9bada0`). The report has now been read and this branch rebased
onto that main. The only conflict was the fidelity-table insertion; both
rows were preserved. Native Linux remains **14** headless screens plus
**10** live frames, distinct from the newly available **15-screen Mach-O
guest**. A separate copy of the support tree in `uikit-linux` built and
verified the final source through that full guest route.

| check | result |
|---|---|
| Darwin release openrender | green; baseline 211.76 s, rebuilt with UIImage for fresh suite |
| Darwin source dependency targets | Gridicons / SimplenoteInterlinks (+Foundation) / Endpoints / Search: all 0 errors in the main package |
| UIKit image tests | **47/47** across UIImageCompatibility, SystemImage, SystemImageSourceCompatibility, ImageView and the 2 new identity tests, including ObjC runtime invocation |
| Ingest tests | **39/39**, corpus-enabled, no skips |
| NIB compiler | `zsh -n` green; **26/26** outputs; no golden changes |
| Catalyst | **124/124** before and after; all **178/178 PNGs byte-identical** |
| Fresh iOS suite | **112/113**, only `corner_radius` below bar; `/tmp/suite-simplenote-launch` |
| Darwin real-app 3x | **15/15 PNGs byte-identical** before/after; all existing comparison floors hold |
| Real-app pixel floors | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.170 / 99.860 / 99.734 / 85.393 |
| Stock swift:6.2-noble release openrender | green (272.59 s; pre-UIImage baseline); final source also built by Linux verification below |
| Linux realapp verification after UIImage | **14/14 headless, 10/10 live**, `REAL-APP SCREEN VERIFIED ON LINUX`; builds release tools and test bundle with Swift 6.2.4 |
| Foundation-hidden guest library after UIImage | **GUEST_ROUTE_CHECK_OK**, OpenUIKit=139 / OpenCoreGraphics=12, 70 s |

An initial test build was invalidated by editing its test input while SwiftPM
was running. A clean incremental rerun completed and passed both tests; that
invalidated invocation is not counted as a test result. No existing rendering
rules or golden files changed. The dedicated `uikit-linux` container also built the copied branch in
`/work-simplenote-launch` using the generated Docker leg of
`linux_realapp_verify.sh`: **14/14 headless and 10/10 live** match the Mac
reference (the existing gate checks Ledger formatter output for presence).
The live replay uses the same copied font directory as the standard script.
All **429** vendored-file SHA-256 hashes were checked, and the corpus git
status remains clean. The first CHECK_ONLY stopped at the documentation
conflict; after rebasing, its second invocation merged cleanly and passed
the gates. Final merge-check and full-guest results follow below.

## Cold guest integration repair after the main rebase

A complete source rebuild exposed **2 Blockzilla errors** that the library-only
check cannot detect: BrowserViewController.swift:1193 could not see
`UIDropSession.loadObjects`, and URLBar.swift:1137 passed
`Foundation.NSItemProvider` to `OpenUIKit.UIDragItem`. The incoming Focus guest
branch still had its earlier drag protocols in FocusLaunchCompat; current
main instead has the richer UIDragDrop implementation, whose loading method
is excluded while Foundation is hidden. This was an integration boundary,
not an application-source change.

The final app-facing UIKit shim (Foundation visible, CoreGraphics absent,
Darwin target) now aliases the library's provider and supplies the existing
local-object/provider loading rule with Foundation.Progress. An SPI getter
exposes the library's already implemented local representation lookup. The
Foundation-hidden provider's file initializer is failable and returns nil,
preserving the previous FoundationGuest file-provider policy. Native Darwin
and native Linux branches are unchanged. No Foundation family or source-list
pin was added.

The cold full guest build then reaches `FOCUS_GUEST_BUILT` with **0 errors**.
The verifier inside the dedicated `/tmp/simplenote-launch-support` copy in
`uikit-linux` reports:

```
FOCUS_GUEST_BOUNDARY_OK sync=specific group=notify,reuse,timeout plist=bridge percent=utf8 archive=refused
FOCUS_REAL_APPDELEGATE_LAUNCHED root=BrowserViewController
Fuzi: all 64 default-plugin reference lines match the native parser
rendered 15 screens; existing screens byte-identical 14/14 (including Ledger)
REAL-APP SCREEN VERIFIED ON LINUX
```

This restores the existing Focus guest; **Simplenote itself is still blocked**
as enumerated above. No copied upstream application file was patched. The
first copied-support build required moving aside a non-relocatable libxml2
CMake cache; only this task's private build output was moved.

After the rebase: iOS replay **112/113, zero passing-scene drops**; image
suites **47/47**; DragDrop + image identity **10/10**; guest library check
**61 s, GUEST_ROUTE_CHECK_OK**. The second CHECK_ONLY passed Catalyst,
real-app floors, test-bundle build, all its conformance comparisons, and both
Docker build steps. The final CHECK_ONLY included the guest overlay in the
committed candidate; its completion is recorded below.

The exact final source was rebuilt and verified again after the last comment
edit. The host and private Linux support copy have the same `guest_subject.py`
source/resource digest:
`5b4dad00a7d964ebe989e6c1b84a089c0f4108231493436664321594bc0adb47`.
This final run also completed `FOCUS_GUEST_BUILT`, the boundary and real-delegate
checks, Fuzi **64/64**, and **15 screens / 14 original screens byte-identical**.
The build and verifier log is `/tmp/simplenote-launch-full-guest-final.log`;
its process exited **0**.

The final merge check completed **707 unique conformance comparisons**, with
no passing-scene drops and no failures of the board's regression rules.
Scores differ from the recorded board by at most **−0.001 / +0.003** points;
this is not a claim that all conformance PNGs are identical.

Final command, invoked from the monorepo root:

```
CHECK_ONLY=1 uikit/scripts/agent_merge.sh agent/simplenote-launch
```

The candidate merged cleanly onto the checker's main (`1e03a29f`). Catalyst
**124/124**, guest-library compilation, test-bundle compilation, real-app
floors, all **707** conformance comparisons, and both Docker build steps
completed. The first clean Linux release build took **176.28 s**. The log
`/tmp/simplenote-launch-merge-check-final.log` ends with
`checks passed (CHECK_ONLY)`.

**Runner cleanup issue:** the process nevertheless exits **128**. The existing
script aborts its temporary merge at line 287, then its EXIT trap (line 96)
tries `git merge --abort` again under `set -e`. The second abort has no
`MERGE_HEAD` and stops cleanup. This is recorded separately from the passed
verification stages; no checker logic or operator lock was changed to hide
the exit status. Only this report was amended after the final source checks.
