# xcodeproj ingest (`Tools/ingest/xcodeproj_to_package.py`)

A Linux agent gets a real iOS app as `project.pbxproj`, not `Package.swift`.
This branch adds an OpenStep parser (no Xcode, no `plistlib`) that turns
one application target into an OpenUIKit package plus a source manifest.

No rendering rule changed. Catalyst **124/124**, iOS suite **112/113**
(known `corner_radius`), real-app screens unchanged.

## Pins (`scratch/ladder-corpus`, not committed)

| app | checkout | SHA | project |
|---|---|---|---|
| Firefox Focus (Blockzilla) | mozilla-mobile/focus-ios | `a2832521c1daa0c23419c73705ae043ed60c9791` | `focus-ios/Blockzilla.xcodeproj` |
| Hackers | weiran/Hackers | `83016de256ef5418f76ec53182d25e302a519234` | `Hackers.xcodeproj` |
| Pocket Casts | automattic/pocket-casts-ios | `3b27afc6e69d56b5d7eb67579fa5e622fbeaed10` | `podcasts.xcodeproj` |

Third app is Pocket Casts (the real-app xib/storage oracle). Pins match
`full/ladder/corpus-pins-2026-08-27.tsv`.

## What was measured

### OpenStep `project.pbxproj`

Three committed-size pbxproj files plus the MiniApp fixture parse with the
in-tree scanner (comments, quoted strings, octal / `\U` escapes, duplicate
keys rejected). Hackers and Pocket Casts use
`PBXFileSystemSynchronizedRootGroup`; Focus still uses explicit
`PBXSourcesBuildPhase` file lists. Xcode 16 omits `package =` on unique
`XCSwiftPackageProductDependency` names — recovery is from
`XCLocalSwiftPackageReference` Package.swift products (Hackers) and from
`PBXFileReference lastKnownFileType = wrapper` that holds Package.swift
(Focus `BlockzillaPackage`; there is no `XCLocalSwiftPackageReference`
for it).

### Info.plist / xcconfig (Pocket Casts)

`podcasts/podcasts-Info.plist` has `CFBundleIdentifier =
$(PRODUCT_BUNDLE_IDENTIFIER)`. The value is not in target `buildSettings`.
Project Debug/Release use Xcode 16
`baseConfigurationReferenceAnchor` + `baseConfigurationReferenceRelativePath`
on the `config` synchronized root → `config/PocketCasts.debug.xcconfig`
`#include`s `PocketCasts.base.xcconfig`, which sets
`PRODUCT_BUNDLE_IDENTIFIER_ROOT = au.com.shiftyjelly.podcasts`. After
following that include chain, bundle id is
`au.com.shiftyjelly.podcasts`. Display name is `Pocket Casts`.

Focus Debug: `org.mozilla.ios.Focus` / `Firefox Focus`.
Hackers: `com.weiranzhang.Hackers` / `Hackers`.

### Counts (application target only; tests / UI tests dropped)

| app | Swift | ObjC | xcassets | nibs | strings | json | ingest exit |
|---|---|---|---|---|---|---|---|
| Blockzilla | 131 | 0 | 1 | 1 | 255 | 6 | 0 |
| Hackers | 9 (`App/*.swift`, not `Extensions/` / UITesting) | 0 | 2 | 0 | 0 | 1 | 0 |
| podcasts | 1138 | 4 (first: `podcasts/SJCommonUtils.m`) | 36 | 161 | 30 | 30 | **2** (hard stop) |

Resources are copied into `Sources/<Target>/Resources/` as
`*.xcassets` (named-color reader), `nibs/` (source `.xib`/`.storyboard`;
`ibtool --compile` is macOS-only), `Localization/` (`.strings` / `.lproj`),
`json/`, plus `ingest-info.json` (bundle id, display name).

Hard stop (exit 2, no `Package.swift` unless `--allow-gaps`): CocoaPods,
Carthage, `.m`/`.mm` in the selected target, mixed Swift+ObjC in that
target. Pocket Casts is the mixed-target proof. Focus and Hackers have
none of those.

### Generated `Package.swift`

Path dependency `.package(name: "OpenUIKit", path: …)` — SwiftPM identifies
a path package by the directory name (`uikit` / `work`); the `name:`
argument is what `.product(..., package: "OpenUIKit")` matches (measured:
without `name:`, Linux said `unknown package 'OpenUIKit'; valid packages
are: 'work'`).

Application targets emit `.executable` + `.executableTarget` because
Pocket Casts has `podcasts/main.swift`. SwiftPM 5.4+ then classifies the
target as executable and refuses a `.library` product (Linux
`swift:6.2-noble`: `library product 'podcasts' should not contain
executable targets`). MiniApp / Focus / Hackers use `@main` rather than
`main.swift` and reached `no such module` either way; apps are still
emitted as executables.

Unsafe flags: `-default-isolation MainActor`, `-disable-availability-checking`.
OpenUIKit products an ingested package can depend on: UIKit, OpenUIKit,
SwiftUI, Symbols, DeveloperToolsSupport. Combine is an in-tree target, not
a product.

Local packages are copied to `LocalPackages/` for inspection and **not**
rewritten onto OpenUIKit products. Hackers' local packages are
`swift-tools-version: 6.4` / `.iOS(.v26)` — Linux Swift 6.2 cannot load
them.

## Ladder classification

The 30 names in `full/ladder/dep-classes-2026-08-27.json` only:
Alamofire, AlamofireImage, Apollo, CocoaLumberjack, DifferenceKit, GRDB,
HAKit, Interstellar, KeychainAccess, Kingfisher, Lottie, Moya, NextcloudKit,
Nimble, Nuke, ObjectMapper, PromiseKit, Quick, ReactiveSwift, RealmSwift,
RxSwift, SDWebImage, SVProgressHUD, Sentry, SnapKit, Starscream,
SwiftProtobuf, SwiftSoup, SwiftyJSON, SwipeCellKit. Anything else is
`unmeasured`, not guessed.

## Per-app no-port list and Linux `swift:6.2-noble`

`docker run --rm -v … swift:6.2-noble`: OpenUIKit `openrender` release
**green** (link complete, 203.29 s). Generated packages then `swift build`
as far as the port allows. First-wave `no such module` (emit-module of the
app target after OpenUIKit itself built):

### Blockzilla (exit 0, 21 no_port)

Linux: `Blockzilla/AppDelegate.swift:6:8: error: no such module 'Glean'`.

Why: remote SPM `Glean` (mozilla glean-swift), class `unmeasured`, no
OpenUIKit product. AppDelegate then imports Sentry, Combine, Onboarding,
AppShortcuts — those were not reached.

Also reported (not the first compiler error): SnapKit (remote, UIKit-bound),
Fuzi (remote, unmeasured), Sentry (remote, ObjC), FocusAppServices (remote,
unmeasured), local BlockzillaPackage products UIHelpers / DesignSystem /
Onboarding / AppShortcuts / Licenses (tools 5.5, copied, not linked),
Combine (not a package product), WebKit, Intents, IntentsUI,
LocalAuthentication, SafariServices, AudioToolbox, CoreHaptics, Network,
PassKit, StoreKit.

### Hackers (exit 0, 10 no_port)

Linux: `App/AppDelegate.swift:8:8: error: no such module 'Data'`.

Why: local SPM `Data` (`swift-tools-version 6.4` / iOS 26), copied to
`LocalPackages/Data`, not linked. AppDelegate then imports Shared — not
reached. Combine and WebKit also have no port.

Local products the target lists: Data, Settings, Comments, Domain,
Networking, Feed, WhatsNew, Authentication (Features/Domain/Data/Networking
packages). Shared and DesignSystem are local packages in the pbxproj but
not direct app-target products; they are treated as in-tree, not
Apple-framework gaps.

### podcasts (exit 2; `--allow-gaps` to emit)

Hard stop:

- 4 Objective-C sources (first `podcasts/SJCommonUtils.m`)
- mixed target: 1138 Swift + 4 ObjC

Linux (emitted anyway): `podcasts/ABTest/ABTestProvider.swift:1:8: error:
no such module 'AutomatticTracks'`.

Why: Xcode 16 `packageProductDependencies` is only `XcodeTarget_podcasts`
(implicit). `AutomatticTracks` is recovered from the import line; it is
not a local package product, not a sibling PBX target, and not one of the
30 ladder deps. Kingfisher / Lottie / DifferenceKit / SwipeCellKit / Sentry
are classified from that 30-name table. Combine is not a package product.
Apple frameworks without a port include AuthenticationServices, CarPlay,
AVFoundation, AVKit, WebKit, WidgetKit, Network, CryptoKit, NaturalLanguage,
StoreKit, and the rest of the 33 framework/SPM rows plus the unmeasured
imports (`PocketCastsDataModel`, `Firebase`, `GoogleCast`, …).

### MiniApp fixture (committed)

Linux: `MiniApp/AppDelegate.swift:2:8: error: no such module 'SnapKit'`
(UIKit-bound, no port). `import UIKit` resolved. WebKit is next and also
has no port.

## Tests

`python3 Tools/ingest/test_xcodeproj_to_package.py` — 33 tests: OpenStep
parser, xcconfig include overlay, MiniApp fixture (target pick, resources,
Info.plist, SnapKit/WebKit no_port, executable Package.swift, `--json`
stdout), and the three pbxproj files when `scratch/ladder-corpus` is
present (pins, Blockzilla sources/SPM classes, Hackers synchronized App/
+ local tools 6.4, Pocket Casts xibs / ObjC mixed stop / xcconfig bundle
id / AutomatticTracks no_port).

## Gates (this branch does not paint)

- Catalyst `openrender render` + `compare.py`: **124/124**
- `SKIP_CAPTURE=1 scripts/ios_suite.sh /tmp/ios_suite`: **112/113**
  (`corner_radius` 99.411, same miss)
- `openrender realapp` vs `/tmp/golden_realapp_ios` @3x: **99.137 /
  98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.192 /
  99.760 / 99.689 / 85.393**
- Linux `swift:6.2-noble` `openrender` green
- No `Package.resolved` committed

## Open questions

- Pocket Casts sibling modules (`PocketCastsDataModel`, `PocketCastsServer`,
  `PocketCastsUtils`) look like local Swift packages elsewhere in the
  checkout; they are not `XCLocalSwiftPackageReference` on
  `podcasts.xcodeproj` and were not guessed.
- `ibtool --compile` of the copied `.xib`s is macOS-only; Linux gets the
  source XML in `Resources/nibs/`.
- Rewriting a local Package.swift so its targets depend on the OpenUIKit
  `UIKit` product is out of scope (Hackers tools 6.4 would still not load
  on Swift 6.2).
