# Eidolon ladder rung: pinned source, dependencies, and measured launch walls

**Date:** 2026-09-07. **Branch:** `agent/eidolon-launch`. **Route:** (b), Apple toolchain → Mach-O guest → `machorun`.

**Partial rung: the real AppDelegate has not launched. First-screen golden, layout and pixel score are N/A → N/A.** No replacement kiosk screen, sample network response or blank image is counted as a launch. The frozen §9 census remains **NEAR / =B 6 (NIB 3, DEP 1, MOD 1, FW 1)**; its declaration inventory is not a build or pixel score.

## Corpus and ingest

`artsy/eidolon` is pinned to commit **44486ed9149f16b3eb3a5e687f99ae078309f4fe**, tree **0ed18d46bbf1dfec16eb83b1df129eeeb48fa0c4**. The authorized `.cursor/scratch-corpus-pins.json` entry and `.cursor/clone-pinned-repo.sh` verify both identities under `scratch/ladder-corpus/eidolon`. No vendor pin is advanced.

The actual PBX target is `Kiosk`: **109 present Swift + 3 Objective-C**, with no missing Swift files. The ladder's 159 Swift files include 50 test files. Quick and Nimble are test dependencies, not first-screen runtime dependencies. `Sources/Eidolon` carries an isolated generated **library** package. All **117 upstream source/header files** are byte-identical, including `@UIApplicationMain`; SHA-256 values are in its `PROVENANCE.json`. The first ingest carried 116 files; the later header scan recovered `PodsBridgingHeader.h`, imported by the bridge but absent from PBX source entries. Resources and the upstream MIT license are carried separately.

Ingest now supports independent PBX target selection and module identity (`--library --module-name Eidolon`), preserves measured `SWIFT_VERSION=4.0`, follows existing local quoted header includes, and supplies header search paths for the preserved Clang directory tree. It does not install a broken Eidolon app target in the renderer's default graph. The upstream application entry point is preserved; a successfully compiled library entry-point/link arrangement is still unproven.

| measurement | before → after | denominator / limitation |
|---|---|---|
| App source inventory | repository-wide 159 → target 109 Swift, 3 ObjC | 5 headers after transitive include repair; 117 identical files |
| Ingest inventory | 1 CocoaPods gap / 30 unprovided rows → 1 / 17 | Product availability, not semantic compiler errors or complete dependency behavior |
| Apple Swift 6.2.1 syntax parse | 109 inputs → 0 errors | `-frontend -parse -swift-version 4`; not type-checking |
| Isolated import probes | 31 measured → 17 resolve / 14 fail | Unique probe module names prevent self-import false positives |
| Resolved module origins | 10 vendored runtime + 3 service adapters + UIKit port + 3 SDK | `-Rmodule-loading` trace; Foundation/QuartzCore/SystemConfiguration SDK resolution is not guest implementation credit |
| Full app Swift type-check | 109 inputs → importer stops at Artsy_UILabels | One surfaced missing-import diagnostic hides downstream semantics; no claim that 108 files compile |
| Original ObjC syntax | 3 inputs → 1 passes / 2 fail | StubResponses passes; Stripe/Stripe.h and external ISO8601DateFormatter pod module missing |

The three original ObjC units and Swift bridging header remain part of the generated package. No app half was silently removed. See [ObjC measurements](eidolon-launch-objc.md) and [dependency census](eidolon-launch-deps.md).

## Pinned runtime dependencies

Nine repositories supply ten runtime Swift modules under `Sources/EidolonDependencies`. **368 upstream-derived files** match their recorded SHA-256 values; **332 are Swift files: 314 canonical files plus 18 byte-identical module-local materializations of RxSwift's shared Platform sources**. Those materializations avoid overlapping SwiftPM source directories. Podfile.lock versions were resolved to immutable commits, and the commits, copied podspecs, full licenses and source hashes are carried. No tag is a persistent source identity. `THIRD_PARTY_LICENSES/EidolonDependencies.md` indexes the full license copies.

| module | app-locked version | Apple Swift 6.2.1 / Swift 4 module inputs | measured result |
|---|---|---:|---|
| RxSwift | 4.1.2 | 149 | module emitted |
| RxCocoa | 4.1.2 | 56 | macOS module emitted; 4 ObjC runtime units syntax-check |
| Moya | 11.0.0 | 25 | Core + RxSwift emitted with upstream COCOAPODS condition |
| Action | 3.5.0 | 7 | module emitted |
| RxOptional | 3.3.0 | 7 | module emitted |
| NSObject_Rx | 4.2.0 | 2 | module emitted |
| SwiftyJSON | 4.0.0 | 1 | module emitted |
| Result | 3.2.4 | 2 | module emitted |
| Alamofire | 4.6.0 | 17 | module emitted |
| Reachability | 4.1.0 | 1 | module emitted |

These are Darwin products, not claimed guest ports. The unchanged RxCocoa source selects `NSButton+Rx` on the macOS target used by route (b). An actual OpenUIKit `UIButton.rx.tap` type-check fails with **“property 'tap' requires that 'UIButton' inherit from 'NSButton'”**. Eidolon calls it in `ChooseAuctionViewController.swift:34`, `ListingsCollectionViewCell.swift:141`, and `SaleArtworkDetailsViewController.swift:241`. The upstream UIButton extension is inside `#if os(iOS)`. No fake reactive implementation or source-condition rewrite was substituted.

## Services and launch harness

`Sources/EidolonServiceShims` supplies Keys, ARAnalytics, Stripe and `EidolonLaunchCompat`, with exact app-called signatures verified against the locked headers/call sites. Stripe is explicitly the **12.1.0 locked interface**, while the tracked Podfile requests **14.0.1**. Its token callback returns nil plus a nonnil unavailable error; it cannot create a token. Analytics remains disabled and retains no identities or events. CardFlight's callback signature could not be recovered from the app's `completion:nil` call alone, so there is **no invented CardFlight shim**.

Empty credentials are unsafe for this measurement: `APIKeys.swift:31` selects successful bundled sample responses for key/secret lengths below 2. `StubResponses.m` also selects stubbing based on the private-font header. Keys therefore supplies explicit unavailable markers, and `EidolonLaunchCompat` refuses **before AppDelegate initialization**, whose stored property constructs the network provider. The harness does not claim that markers themselves disable networking.

The RealAppProbe addition is a **preflight harness**, not a completed real-delegate adapter. `openrender eidolon-launch <outdir>` invokes it, exits 2 with `EIDOLON_UNAVAILABLE score=N/A`, and creates no directory or PNG. It does not add an unrendered screen to `realAppVariants`. Four tests on Darwin and Linux establish **0 constructor calls, 1 token failure callback, 0 tokens**, unavailable credentials, and disabled analytics. See [service evidence](eidolon-launch-services.md).

## Native oracle and compiled storyboards

Xcode **26.1 (17B55)**, iPhoneSimulator SDK **26.1**, installed iOS runtime **26.1 (23B86)**. The native oracle suffix is `-eidolon-launch-oracle`. The original app is an **iPad landscape kiosk**; an iPhone settings fixture would not establish its first screen.

`scripts/compile_realapp_nibs.sh` compiles **3/3** original inputs: Auction and Fulfillment storyboards and KeypadView.xib. The branch carries **59 NIBArchive files + 2 plists, 223,716 bytes**, with source/artifact hashes under `fixtures/realapp/eidolon/nibs`. Auction has 12 XML scenes; Fulfillment 20; 183 XML custom-class occurrences represent 48 distinct names, including the First Responder placeholder.

An executed port probe against those artifacts measures:

- `UIStoryboard(name: "Auction", bundle: ...).instantiateInitialViewController()` returns **nil**.
- AppViewController, ActionButton and ListingsCountdownManager have **no registered factories**.
- Direct controller/view/Keypad NIB loads produce base UIViewController/UIView fallback objects, with **10 / 17 / 12 unhandled entries**. These are decoder results, not an app screen.

The original Xcode workspace build in an unchanged temporary copy exits **65** at missing `Pods-Kiosk.debug.xcconfig`. The initial missing CocoaPods-keys tooling was repaired under `/tmp` at the app's Gemfile.lock versions. CocoaPods' own compatibility check confirms the Stripe mismatch and private-locked versus OSS-selected font mismatch. The locked CardFlight-v4 **4.3.1** podspec source repository independently returns **exit 128, “Repository not found.”** Its availability cannot be repaired by a build flag. No new font or Stripe version was silently selected. See [oracle evidence](eidolon-launch-oracle.md).

## Remaining blockers by class

| blocker | measured state after this rung |
|---|---|
| NIB | 3/3 resources compile; actual initial-storyboard API returns nil; required app factories are absent; direct nib fallback has 10/17/12 unhandled entries. |
| DEP platform branches | All ten host modules emit, but UIButton.rx.tap requires NSButton on the macOS route. Full app import census still lacks 14 modules. |
| DEP native source access | Locked CardFlight-v4 4.3.1 repository returns 128 / Repository not found. Exact unavailable callback signature remains unmeasured. |
| Build metadata | Stripe 14.0.1 request vs 12.1.0 lock; default OSS fonts vs locked private Artsy+UIFonts. Original workspace has no Pods configuration. |
| MOD dialect | Swift 4 retained without app edits. Native iOS UIKit probe passes in Swift 4; Swift 5 obsoletes UIApplicationLaunchOptionsKey. |
| FW / UIKit compatibility | Actual OpenUIKit Swift 4 probe lacks UIApplicationLaunchOptionsKey and UIWebView (2 errors); native UIKit26.1 probe resolves both. No WebView behavior invented. |
| ObjC interfaces | Missing locked Stripe header and external ISO8601DateFormatter module stop 2/3 original units. Two existing forced-facade declaration errors are recorded separately from direct app imports. |
| Services | Three measured service adapters fail closed. Preflight blocks app construction; original demo fallback is not used as account/network evidence. |
| Guest wiring | Current full/scripts/build_full.sh does not compile Eidolon or these dependency/service modules. No Mach-O Eidolon executable exists to run with machorun; no full/ or pin edits authorized or made. |
| First-screen fidelity | App launch, iOS golden and matching port render not reached. compare_realapp pixel score **N/A**; no fake blank capture or guessed score. |

## Reproduce

All commands begin in `uikit/`, except the explicitly requested merge proof.

```sh
bash ../.cursor/clone-pinned-repo.sh --lock ../.cursor/scratch-corpus-pins.json --id eidolon --repo-root ..
python3 Tools/ingest/xcodeproj_to_package.py ../scratch/ladder-corpus/eidolon/Kiosk.xcodeproj --target Kiosk --allow-gaps --library --module-name Eidolon --out /tmp/eidolon-launch-library
python3 -m unittest discover -s Tools/ingest -p 'test*.py'
swift build -c release -j 4 --target Action
swift build -c release -j 4 --target Moya
swift test --filter EidolonServiceShimTests
./.build/release/openrender eidolon-launch /tmp/eidolon-launch-unavailable
```

The generated source-manifest and carried reports record commands, pins and diagnostics; temporary logs are not the sole evidence. The app source copies preserve upstream whitespace. The full external corpus exposes two preexisting Pocket Casts ingest assertions that expect old AutomatticTracks/mixed-target behavior; local fixture checks pass and those unrelated assertions are unchanged.

## Validation and merge proof

Final validation results are appended below after completion. No rendering rule, glyph table, golden PNG, existing layout dump, guest Foundation source list or vendor pin changes in this branch.

| check | result |
|---|---|
| Darwin release openrender | green; baseline 751.73 s, integrated release 429.19 s |
| Pinned dependency SwiftPM | Action graph green (RxSwift/RxCocoa/ObjC runtime), Moya green; remaining isolated module evidence in dependency report |
| Catalyst | **124/124 before and after; 178/178 PNGs byte-identical** |
| Fresh private iOS26.1 suite | **112/113**, sole existing corner_radius 99.411; **113/113 rendered PNGs byte-identical** to baseline binary |
| Real-app3x | **15/15 PNGs byte-identical**, all existing floors hold; 14 available goldens scored, browser golden absent in this machine's /tmp directory |
| Stock Linux release | **exit0**, swift:6.2-noble, 389.98 s; copied Darwin build symlink warning does not affect the successfully linked Linux executable |
| Service boundary tests | standalone Darwin **4/4**, Linux Swift6.2.4 **4/4**; integrated test result below |
| Ingest fixture tests | **22 passed /20 corpus-dependent skipped**,42 discovered; independent recursive-header/dialect audit2/2 |
| Source/resource integrity | app117/117, dependencies368/368, compiled NIB/plist artifacts61/61 hashes verified |
| CLI unavailable launch | **exit2**, EIDOLON_UNAVAILABLE score=N/A; no output directory or PNG |

Machine-readable render hashes and scores are in `eidolon-launch-validation.json`.
The unchanged real-app scores are **99.137 /98.535 /98.548 /99.740 /98.720 /98.334 /97.549 /99.650 /98.823 /99.287 /99.860 /99.734 /94.662 /99.610** in comparator order (browser missing). They measure existing app screens, not Eidolon.

The integrated main-package `swift test -j 4 --filter EidolonServiceShimTests`
completes with **4/4 XCTest tests, 0 failures**. Its separate Swift Testing
runner discovers0 tests, which is not added to the XCTest count. The complete
test bundle links successfully with the new Darwin dependency products.
SwiftPM release targets **Action, Moya, RxOptional, NSObject_Rx, SwiftyJSON,
Reachability** all complete; Action/Moya cover RxSwift, RxCocoa,
RxCocoaRuntime, Result and Alamofire transitively. These host builds preserve
the previously measured platform and SDK limitations.

For the requested CHECK_ONLY proof, the checker’s existing `ALLOW_PATHS`
mechanism is exported as **`^\.cursor/scratch-corpus-pins\.json$`**, matching
only the additional corpus-lock file explicitly authorized by this brief.
The checker itself is unchanged; no broader scope exception or pin-file
exception is used. The command is then run from the repository root:

```sh
CHECK_ONLY=1 bash uikit/scripts/agent_merge.sh agent/eidolon-launch
```


A direct generated-package build found one additional ingest graph defect:
SwiftPM resolved the `libkern` product name even though its dependency had
`.when(platforms: [.linux])`; Darwin exports `OpenUIKitLibkern` instead.
The same manifest inspection found StoreKit's platform-dependent product name.
Those Linux-only references now live inside `#if os(Linux)` in the generated
manifest, so Darwin does not resolve them. The 42-test ingest run remains
22 passed/20 skipped. Reusing the monorepo scratch build for a standalone
Clang target produced a build-description target-name error; the subsequent
full generated-package attempt uses its own clean scratch directory, keeping
that driver/cache issue separate from app compiler diagnostics.

The clean standalone generated-package build now resolves the product graph
and compiles the original `StubResponses.m`. It stops on the same two measured
external inputs: `ISO8601DateFormatter` module not found and `Stripe/Stripe.h`
not found. This is an actual SwiftPM library build attempt, not merely a source
parse. Its log is `/tmp/eidolon-launch-generated-full.log`.

The first merge-check attempt found only a fidelity-table conflict after main
advanced to `21a78014` (Hackers pill placement). The branch was rebased onto that
main, preserving both table rows. The local byte-identity figures above describe
the pre-rebase candidate versus its own baseline. The inherited main change
improves Hackers 94.662→98.235; it is not credited to Eidolon. The rerun below
checks the actual rebased merged tree.
