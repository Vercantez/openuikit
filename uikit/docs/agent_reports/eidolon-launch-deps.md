# Eidolon runtime dependency measurements

Date: 2026-09-07. Corpus: `artsy/eidolon` commit
`44486ed9149f16b3eb3a5e687f99ae078309f4fe`. Compiler: Apple Swift 6.2.1
(`swiftlang-6.2.1.4.8 clang-1700.4.4.1`), default
`arm64-apple-macosx26.0` host target, Swift 4 language mode. The app project
sets `SWIFT_VERSION = 4.0` in its four build configurations.

All ten runtime Swift dependency modules emit from unchanged sources on the
Apple host. The first isolated app-called reactive UI operation fails:
`OpenUIKit.UIButton.rx.tap` requires `UIButton` to inherit from `NSButton`.
No first-screen score follows from these measurements; score is **N/A**.

## Pins and source census

Nine repositories were fetched at immutable commits resolved from the locked
CocoaPods versions. `Sources/EidolonDependencies/PROVENANCE.json` carries
repository URLs, full commits, locked versions, upstream licenses/podspecs,
and a SHA256 for every copied file. All copied files were compared byte for
byte with their upstream checkout. No dependency source was modernized.

The tree contains **314 canonical Swift files**, **18 additional identical
materializations** of RxSwift shared Platform sources for disjoint SwiftPM
targets, and **four Objective-C runtime units**. The materializations are
explicitly identified with `upstream_path` in provenance; there are 332
physical Swift files, not 332 unique upstream units.

| Repository | Lock version | Immutable commit |
|---|---|---|
| RxSwift | 4.1.2 | `3e848781c7756accced855a6317a4c2ff5e8588b` |
| Moya | 11.0.0 | `0b90f7ee8dcc378fe48db18c8b281e8792244de9` |
| SwiftyJSON | 4.0.0 | `de309166a48a9dfc51d5bc4c55c0664d981de311` |
| Alamofire | 4.6.0 | `bc973c5311ce3db3f01a9fcde027fb11fa2254bf` |
| Result | 3.2.4 | `7477584259bfce2560a19e06ad9f71db441fff11` |
| Action | 3.5.0 | `9c413d35c3b0f14dd2a817c866415afd9a40e4db` |
| RxOptional | 3.3.0 | `2ae1c01d2a725ebbc7b75c8c1fc3623a54084b94` |
| NSObjectRx | 4.2.0 | `772b9c70cb59c51e9664f82037660fb97bfa621d` |
| Reachability | 4.1.0 | `06beeead15401a312622959654a2e9ec8cfa2cb9` |

The ladder census counts Quick and Nimble as load-bearing across the entire
checkout. Both have zero production imports and 49 `KioskTests` imports;
the launch graph does not require their test-only source. Production imports
include RxSwift 58, Moya 18, Action 17, SwiftyJSON 14, RxOptional 9, RxCocoa 7,
Alamofire 2, NSObject_Rx 2, Result 1, and Reachability 1. These are import-site
counts in production Swift, not an inferred runtime call graph.

The production Podfile asks for Stripe 14.0.1, while its lock records 12.1.0;
that inconsistency is an independent service-resolution input wall. The
pure Swift dependencies above follow the lock. No `pod update` was used.

## Compiler measurements

`xcrun swiftc -swift-version 4 -parse-as-library -emit-module` compiled each
module using the real macOS SDK. Dependent modules used only the previously
emitted pinned modules. RxCocoa used upstream's `SWIFT_PACKAGE` branch and a
Clang module map over the unchanged `RxCocoaRuntime.h`. Moya Core and its
RxSwift subspec were compiled together with upstream's `COCOAPODS` define.
Compiler warnings are retained in scratch logs; an exit-zero module-emission
check is not a link, execution, or guest ABI check.

| Module | Swift sources in measured invocation | Result | Elapsed seconds |
|---|---:|---|---:|
| RxSwift | 149 | emits module, exit 0 | 93.911 |
| RxCocoa | 56 | emits module, exit 0 | 54.45 |
| MoyaCore | 22 | emits module, exit 0 | 36.048 |
| MoyaRxSwift | 25 | emits module, exit 0 | 15.132 |
| Action | 7 | emits module, exit 0 | 9.021 |
| RxOptional | 7 | emits module, exit 0 | 7.635 |
| NSObjectRx | 2 | emits module, exit 0 | 3.07 |
| SwiftyJSON | 1 | emits module, exit 0 | 2.779 |
| Result | 2 | emits module, exit 0 | 0.504 |
| Alamofire | 17 | emits module, exit 0 | 6.271 |
| Reachability | 1 | emits module, exit 0 | 0.478 |

The four `RxCocoa/Runtime/*.m` sources separately passed
`xcrun clang -fsyntax-only -fobjc-arc -fmodules` against the host SDK (exit 0).
This is a syntax check, not an Objective-C runtime behavior claim.

Machine-readable commands, counts, warning counts, and diagnostics are in
`eidolon-launch-deps.json`; `${UIKIT}` denotes this package directory and
`${PROBE_BUILD}` denotes `/tmp/eidolon-launch-deps/build`. Full compiler logs
remain in that scratch directory. The source argument lists in the JSON
record the exact measured input set.

## Isolated route (b) wall

The app calls `.rx.tap` in `Kiosk/ListingsCollectionViewCell.swift:141`,
`Kiosk/Sale Artwork Details/SaleArtworkDetailsViewController.swift:241`, and
`Kiosk/Admin/ChooseAuctionViewController.swift:34`.

The following scratch probe imports the real OpenUIKit module and the
unchanged pinned reactive modules:

```swift
import OpenUIKit
import RxSwift
import RxCocoa

@MainActor func eidolonTap(_ button: OpenUIKit.UIButton) {
    _ = button.rx.tap
}
```

Typechecking exits **1** with exactly one error:

```text
EidolonRxTapProbe.swift:6:19: error: property 'tap' requires that 'UIButton' inherit from 'NSButton'
RxCocoa/macOS/NSButton+Rx.swift:14:1: note: where 'Base' = 'UIButton'
```

The rule is directly visible in unchanged upstream
`RxCocoa/iOS/UIButton+Rx.swift:9`: `tap` is enclosed in `#if os(iOS)`.
The Apple-toolchain Mach-O guest route targets macOS, so it selects the
AppKit `NSButton` operator. Importing a package product named `UIKit` does
not change `os(macOS)` to `os(iOS)`. No adapter, source rewrite, replacement
Rx event engine, or fabricated event delivery was added.

## App import and full-source probes

Each of the **31 unique production Swift imports** was independently
checked with a distinct `EidolonImportProbe_<module>` module name. This
avoids a probe importing itself and falsely reporting success. The compiler
used the emitted dependency modules, the separately built service modules,
and the root package's release module directory and C module maps.

**17 imports resolve; 14 do not.** A combined success probe with
`-Rmodule-loading` and `-emit-loaded-module-trace` exits 0 and confirms all
17 exact module source/load paths (recorded in the JSON). The three SDK
modules resolve from **MacOSX26.1.sdk**; UIKit resolves from the OpenUIKit
release module directory. Resolution identities are:

| Origin | Count | Modules |
|---|---:|---|
| Vendored upstream Swift | 10 | Action, Alamofire, Moya, NSObject_Rx, Reachability, Result, RxCocoa, RxOptional, RxSwift, SwiftyJSON |
| Fail-closed service modules | 3 | ARAnalytics, Keys, Stripe |
| OpenUIKit package | 1 | UIKit |
| Actual Apple SDK | 3 | Foundation, QuartzCore, SystemConfiguration |

The unresolved imports are ARCollectionViewMasonryLayout, ARTiledImageView,
Artsy_UIButtons, Artsy_UIFonts, Artsy_UILabels, CardFlight,
DZNWebViewController, ECPhoneNumberFormatter, FLKAutoLayout, ORStackView,
SDWebImage, SVProgressHUD, UIImageViewAligned, and XNGMarkdownParser.

A second invocation passed **all 109 unchanged production Swift files**
from `Sources/Eidolon/Sources/Eidolon` to Swift 4 `-typecheck
-parse-as-library -module-name EidolonWholeAppProbe`. It exits **1** at:

```text
Kiosk/Admin/AdminPanelViewController.swift:2:8: error: no such module 'Artsy_UILabels'
```

This is the actual full source set, not 109 successful compilation units.
Import failure hides the remaining semantic errors; no semantic pass count
can be inferred. No placeholder modules or bridging-header substitutions
were supplied to bypass the diagnostic. The 31 isolated probes distinguish
a missing import from the independently measured RxCocoa UIKit constraint.
Full commands and per-import origin/exit results are carried in
`eidolon-launch-deps.json` under `app_import_census`; scratch logs are under
`/tmp/eidolon-launch-deps/import-census/`.

## Blocker table

| blocker | measured state after dependency pass |
|---|---|
| CocoaPods source acquisition | Nine runtime repositories, ten Swift module identities, all copied at full immutable commits with license/provenance evidence. |
| Remaining production imports | 17/31 resolve: 10 vendored, 3 service shims, 1 OpenUIKit facade, 3 real SDK modules. Full109 typecheck stops at missing Artsy_UILabels before a semantic denominator can be measured. |
| Old Swift language version | All ten host modules emit in the app's Swift 4 mode; no modern-Swift source edit is necessary for this host module check. |
| Reactive UIKit platform branch | `OpenUIKit.UIButton.rx.tap` fails with the `NSButton` inheritance constraint. All three app samples use the iOS operator that is inactive for the macOS guest target. |
| Objective-C runtime | Four unchanged RxCocoa runtime units pass host syntax checking; guest swizzling, dynamic delegate-proxy dispatch, KVO, associated-object behavior, and linkage have not been established by that check. |
| Guest framework/load list | Host compilation uses real Foundation, AppKit, and SystemConfiguration. No guest Foundation completeness, AppKit replacement, SystemConfiguration support, or permitted dylib load list is claimed. |
| Oracle and first screen | N/A for this dependency pass. Neither module emission nor the failing tap probe is a valid screen capture or comparison. |

This pass adds vendored dependencies and measurements. It changes no
OpenUIKit rendering rule, service behavior, corpus source, guest pin, or
external vendor pin. Root integration owns the package targets, license
index, launch report, regression gates, commits, and merge proof.
