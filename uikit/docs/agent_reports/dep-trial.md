# Dependency trial — Hackers' real SPM set on Linux corelibs

Third-party dependencies are the next Linux blocker (the ladder names
RxSwift, Alamofire, GRDB, Kingfisher, Lottie; only focus-ios is
dependency-free). This round did **not** close an iOS-oracle pixel gap
and did **not** port a dependency. It measured Hackers' actual graph on
`docker exec uikit-linux` (`swift:6.2-noble`, Swift **6.2.4**,
`aarch64-unknown-linux-gnu`, corelibs-Foundation), one package at a time.

Pin: weiran/Hackers `83016de256ef5418f76ec53182d25e302a519234` under
`scratch/ladder-corpus/Hackers`. Ingest:
`python3 Tools/ingest/xcodeproj_to_package.py` → exit **0**, 9 Swift,
10 no_port (8 local SPM tools 6.4 + Combine + WebKit). Worktree tarred
to `/work-dep-trial`; `/src` in the container is still main.

No rendering rule changed. Catalyst **124/124**. FeedView with the
harness stubs still matches the committed golden
(`scripts/goldens_restore.sh` / `/tmp/golden_realapp_ios`) at
**85.393**. FeedView with the real packages does not compile.

## Hackers' actual dependency set

Not RxSwift/Alamofire/GRDB/Kingfisher/Lottie. Two remotes plus six
local packages (all `swift-tools-version: 6.4` / `.iOS(.v26)`):

| package | origin | what FeedView touches |
|---|---|---|
| **SwiftSoup** `from: 2.13.4` (resolved **2.13.9**) | Data | no — scraper only |
| **VariableBlur** `exact: 1.3.0` | DesignSystem | no — header blur, not the feed List |
| Domain | local | yes (`import Domain`) |
| Networking | local | no (via Data → Shared) |
| Data | local | no (via Shared `DependencyContainer`) |
| Shared | local | yes |
| DesignSystem | local | yes (`PostDisplayView`, `ThumbnailView`) |
| Features/Feed | local | the vendored FeedView **is** this package |

App-target products from ingest: Data, Settings, Comments, Domain,
Networking, Feed, WhatsNew, Authentication. Shared and DesignSystem are
local packages in the pbxproj but not direct app-target products.

## Per package (Linux corelibs)

Unmodified `swift package dump-package` on every local package:

```
package '…' is using Swift tools version 6.4.0 but the installed version is 6.2.4
```

That is the first wall. Everything below is a `/tmp` measurement copy
with `swift-tools-version: 6.2` (iOS 26 platform still dumped). Not a
port; the copies were not committed.

### Domain (Foundation only)

- Resolve after the tools rewrite: **yes**.
- Compile as written: **no**. 8 diagnostics, one API:
  `AttributedString.inlinePresentationIntent = .stronglyEmphasized /
  .emphasized / .code` in `CommentHTMLParser+{Formatting,Blocks}.swift`.
  `NSRegularExpression` in `CommentHTMLParser.swift` **compiled** (corelibs
  has it; the guest Foundation still does not — do not add it).
- Exclude the five `CommentHTMLParser*` files (Feed does not call them):
  **yes**, `swift build --target Domain` complete.
- Real `DefaultVotingStateProvider.init(voteUseCase:)` has no empty
  `init()`. The harness stub's `DefaultVotingStateProvider()` therefore
  cannot swap onto the real type.

### Networking (Foundation + URLSession)

- Resolve after the tools rewrite: **yes**.
- Compile as written: **no**. First diagnostic:
  `'URLSession' is unavailable: This type has moved to the FoundationNetworking
  module. Import that module to use it.` Then `URLRequest`,
  `URLSessionDelegate`, `URLSessionTaskDelegate`,
  `URLSessionConfiguration.default`,
  `NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData`,
  `HTTPCookieStorage.shared`, `URLSession.data` (55 `error:` lines, all
  that split).
- One added line `import FoundationNetworking` in `/tmp`: **yes**,
  NetworkManager + FormEncoder complete (2.25 s). Darwin Foundation
  re-exports these; Linux corelibs does not.

### SwiftSoup (remote, ladder class Foundation-heavy)

- Resolve: **yes** (`from: 2.13.4` → **2.13.9**, 0.99 s fetch).
- Compile against corelibs Foundation: **yes**. 61 library files + a
  one-line `SwiftSoup.parse` / `document.text()` consumer, 0 errors.
  This is the only ladder-classified third-party Hackers actually uses,
  and it is **not** a Linux compile blocker on the corelibs route.

### Data (Domain + Networking + SwiftSoup + WebKit + StoreKit)

Onion, after Domain-feed + Networking-fn + SwiftSoup (otherwise the
build never reaches Data's own sources):

1. `import os` / `Logger` / `OSAllocatedUnfairLock` — no such module
   `os` (PostRepository+Parsing, SupportPurchaseRepository).
2. `import WebKit` — no such module (SettingsRepository;
   `WKWebsiteDataStore.default().removeData`).
3. `import StoreKit` — no such module (SupportPurchaseRepository;
   `Product.products`, `Transaction.latest`, `StoreKitError`).
4. After excluding Settings + SupportPurchase and stubbing `os` in
   `/tmp`: SwiftSoup parse path **compiles**. Remaining:
   `NSUbiquitousKeyValueStore` (BookmarksRepository,
   ReadStatusRepository), `RelativeDateTimeFormatter` (SearchRepository
   `.unitsStyle = .full`). `JSONDecoder` compiled.

### VariableBlur 1.3.0 (DesignSystem)

- As-is (toolchain SwiftUI): `no such module 'SwiftUI'`.
- Sources copied into a trial package depending on OpenUIKit products
  `SwiftUI` + `UIKit` + `OpenCoreGraphics` (`--build-path` reused the
  `/work-dep-trial` graph): SwiftUI/UIKit/`UIViewRepresentable` /
  `UIVisualEffectView` / `UIBlurEffect` / `NSClassFromString` /
  `CALayer.filters` / `didMoveToWindow` / `traitCollectionDidChange`
  **resolved**. First miss: `import CoreImage.CIFilterBuiltins`. Then
  `import QuartzCore`. After skipping those two imports in `/tmp`:
  `NSSelectorFromString` not in scope; `NSObject` has no `perform`;
  `CGImage` not in scope (came in via CoreImage); `CGFloat as NSNumber`
  does not coerce. `String.contains("VisualEffectSubview")` typechecked
  on corelibs (guest GATE_B would still refuse the String overload).

### Shared (Domain + Data + Networking + UIKit + SwiftUI + Combine)

Cannot SPM-depend on the OpenUIKit **package** and keep products named
`Domain` / `Shared`: `multiple packages declare targets with a
conflicting name`. Ingest's "do not rewrite third-party Package.swift
onto OpenUIKit products" is also a graph-identity fact.

Renamed-target trial (`HackersDomain` + `HackersShared`, OpenUIKit
UIKit/SwiftUI products, Data/Combine/StoreKit/SafariServices files
dropped so the UIKit surface could be reached):

- `import LinkPresentation` (ContentSharePresenter)
- `ProcessInfo.isiOSAppOnMac` (DeviceLayout.swift:24 and :34)
- `NSUbiquitousKeyValueStore` (ReadStatusController)
- `NotificationCenter.default.post` — `ambiguous use of 'default'`
  (VotingViewModel.swift:221; OpenUIKit vs corelibs Foundation)
- Combine files never reached: Combine is an in-tree target, **not** a
  package product (ingest already classified it no_port).

Also not compiled in that slice, measured from imports: SafariServices
(`SFSafariViewController`), StoreKit (`ReviewPromptController`), Data.

### DesignSystem / Features/Feed

Not a separate successful compile. DesignSystem needs Shared +
VariableBlur + `import MessageUI` (`MFMailComposeViewController`) +
`import ImageIO` (`ThumbnailView`). Features/Feed is already the
vendored FeedView against harness stubs.

## FeedView vs the committed golden

`OPENUIKIT_REALAPP_SCALE=3 OPENUIKIT_FORCE_IOS=1 OPENUIKIT_FONT_DIR=/agent/fonts
./.build/release/openrender realapp /tmp/app-dep-trial` inside
`uikit-linux`, then `Tools/compare/compare_realapp.py --golden
/tmp/golden_realapp_ios --out /tmp/app-dep-trial --scale 3`.

| screen | score | vs floor |
|---|---|---|
| realapp_history_light | **99.137** | held |
| realapp_settings_light | **98.535** | held |
| realapp_settings_dark | **98.548** | held |
| realapp_storage_light | **99.469** | held |
| realapp_settings_light_xs | **98.639** | held |
| realapp_settings_light_xxxl | **98.133** | held |
| realapp_settings_light_ax1 | **97.516** | held |
| realapp_settings_light_ipad | **99.511** | held |
| realapp_focus_settings_light | **82.170** | held (symbols-harvest 82.170) |
| realapp_history_light_ipad | **99.760** | held |
| realapp_storage_light_ipad | **99.689** | held |
| **realapp_hackers_feed_light** | **85.393** / MAE 13.931 / blob 149.7 | **held** (floor 84.4) |

That is the **harness stub** path (fixed sample posts, no SwiftSoup, no
VariableBlur, stub Domain/Shared/DesignSystem). The real Domain package
cannot replace the stub: `CommentHTMLParser` needs
`inlinePresentationIntent`, and `DefaultVotingStateProvider` is not a
drop-in. Real Shared cannot replace the stub: Data, Combine-as-product,
SafariServices, StoreKit, LinkPresentation, `isiOSAppOnMac`. Real
SwiftSoup compiles but is not on the FeedView import list. So FeedView
does **not** render on Linux with the real dependency instead of the
stub; the stub path is unchanged.

## Ranked gaps (20-app corpus `scratch/ladder-corpus`)

Grep of `.swift`/`.m`/`.mm`/`.h` across the 20 pinned apps, skipping
`.git` / Pods / Carthage. Count is **apps**, not files. Rank is "how
many ladder apps name this API" — the ones this trial actually failed
on, plus the ladder names the brief cited for context.

| rank | missing API / module | apps / 20 | who in this trial | what unblocking it would reach |
|---|---|---|---|---|
| 1 | `#selector` / `@objc` | **20** / 20 | Hackers `App/PostCommentsSheet.swift`; VariableBlur `NSSelectorFromString` + `NSObject.perform` | every ladder app |
| 2 | `WebKit` / `WKWebView` | **19** | Data `SettingsRepository` | browsers + Pocket Casts + Focus + … |
| 2 | `URLSession` | **19** | Networking (corelibs: one `import FoundationNetworking` compiled it) | almost the whole corpus |
| 4 | `NSRegularExpression` | **18** | Domain CommentHTMLParser (**compiles on corelibs**; guest still missing) | guest route, not this container |
| 5 | `import Combine` and Combine **as a package product** | **17** | Shared SessionService / ToastPresenter / FeedViewModel | any ingested package outside RealAppProbe |
| 6 | SafariServices | **16** | Shared `LinkOpener` / `SFSafariViewController` | 16 apps |
| 7 | `NSClassFromString` | **15** | VariableBlur (this **compiled** against OpenUIKit) | — not a miss here |
| 8 | StoreKit | **14** | Data `SupportPurchaseRepository` | 14 apps |
| 9 | `import os` / `Logger(` | **13** | Data parsing + SupportPurchase | 13 apps |
| 9 | `UIViewRepresentable` | **13** | VariableBlur (compiled past it) | — not a miss here |
| 11 | MessageUI | **12** | DesignSystem `MailView` | 12 apps |
| 11 | `WKWebsiteDataStore` | **12** | Data SettingsRepository | subset of WebKit |
| 13 | CoreImage / `CIFilter` | **11** | VariableBlur `CIFilterBuiltins` | 11 apps |
| 14 | `OSAllocatedUnfairLock` | **8** | Data SupportPurchase | 8 apps |
| 14 | ImageIO | **8** | DesignSystem `ThumbnailView` | 8 apps |
| 16 | `HTTPCookieStorage` | **7** | Networking (with FoundationNetworking) | 7 apps |
| 17 | `NSUbiquitousKeyValueStore` | **6** | Data Bookmarks / Shared ReadStatus | 6 apps |
| 17 | `RelativeDateTimeFormatter` | **6** | Data SearchRepository | 6 apps |
| 17 | LinkPresentation | **6** | Shared `ContentSharePresenter` | Hackers, Telegram, firefox, wikipedia, Pocket Casts, duckduckgo |
| 20 | **SwiftSoup** | **5** | Data | **compiles on corelibs 2.13.9** — not a Linux compile gap |
| 20 | Alamofire | **5** | not a Hackers dep | WordPress, eidolon, home-assistant, mastodon, nextcloud |
| 22 | GRDB / Kingfisher | **4** | not a Hackers dep | see corpus list |
| 24 | `inlinePresentationIntent` | **2** | Domain HTML parser | Hackers + Pocket Casts |
| 25 | Lottie | **8** | not a Hackers dep | 8 apps (brief's `#selector` wall) |
| 26 | RxSwift | **1** | not a Hackers dep | eidolon only in this corpus |
| 26 | VariableBlur | **1** | DesignSystem | Hackers only |
| 26 | `ProcessInfo.isiOSAppOnMac` | **1** | Shared DeviceLayout | Hackers only |
| — | `AttributedString.inlinePresentationIntent` | 2 | Domain | same as InlinePresentationIntent |
| — | `NotificationCenter.default` ambiguity | not grepped | Shared VotingViewModel vs OpenUIKit | needs a named-center rule, not guessed |

Highest-leverage **small** next steps that this trial actually compiled
against, not a port:

1. **Re-export `FoundationNetworking` from the Linux `Foundation`
   overlay / document `import FoundationNetworking`** — unblocks
   URLSession in 19/20 apps on corelibs (one line made Networking
   green). Guest still has no URLSession; that is a different route.
2. **Export Combine as an OpenUIKit package product** — 17/20 apps
   `import Combine`; ingested packages cannot `.product(name: "Combine")`
   today. RealAppProbe only sees it because it lives in the same graph.
3. **SwiftSoup is done on corelibs.** Five apps can take the real
   package once their other walls fall. Do not stub it.

Do **not** add `NSRegularExpression`, `DateFormatter`,
`RelativeDateTimeFormatter`, or `_StringProcessing` to the guest
Foundation. Domain's regex compiled here only because this container
is corelibs.

## Gates

| gate | result |
|---|---|
| Catalyst `openrender render` + `compare.py` in `uikit-linux` | **124/124** |
| iOS suite `SKIP_CAPTURE=1` | **112/113** (`corner_radius` 99.411, known) |
| Linux `swift:6.2-noble` `openrender` release | green, 181.99 s |
| real-app vs `/tmp/golden_realapp_ios` @3x | **no drop**; Hackers **85.393** |
| `python3 Tools/ingest/test_xcodeproj_to_package.py` with `LADDER_CORPUS` | **33/33** |
| `Package.resolved` | not committed |

## Open questions

- Guest compile of real Domain (`NSRegularExpression`,
  `inlinePresentationIntent`) was not run; this brief was the corelibs
  route.
- VariableBlur's private `CAFilter` (`NSClassFromString("CAFilter")`
  spelled backwards) is an Apple-runtime trick; OpenUIKit has
  `CALayer.filters` but no `NSSelectorFromString` /
  `NSObject.perform(_:with:)`.
- `NotificationCenter.default` ambiguity on Linux when a file imports
  both OpenUIKit and Foundation — measured, not modelled.
- Rewriting a local Package.swift so its targets depend on the OpenUIKit
  `UIKit` product still collides on target names (`Domain`, `Shared`)
  with RealAppProbe. An ingested app package sitting *next to* OpenUIKit
  does not have that collision (ingest already emits that shape).
