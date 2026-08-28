# The APP LADDER — 20 open-source iOS apps ranked by distance-from-runnable

Measured 2026-08-27. Tooling in this directory, corpus SHAs pinned in
`scratch/ladder-corpus/PINS.txt`, raw output in the JSON files beside this one.
**Measurement only — nothing was built, nothing was fixed.**

---

## 0. What "runnable" means here, so nobody over-reads the ladder

The path this ladder scores is the **RealApp path scaled up**: an app is
**recompiled from source** against OpenUIKit + the ported FoundationEssentials
with our Mach-O toolchain, producing a Darwin Mach-O guest that runs under
machorun on Linux.

It is **NOT** running App-Store binaries. That needs the ObjC facade shipped as
a real `UIKit.framework` dylib with ObjC metadata (docs/OBJC_FACADE.md) — a
different and farther project. Where an app in this corpus is Objective-C
source, it lands on *that* road, not this one, and the ladder says so.

Two build routes exist and per-app feasibility differs:

| | route (a) — Linux cross-swiftc | route (b) — Apple toolchain on the Mac |
|---|---|---|
| the story | no Apple hardware anywhere | Apple toolchain, our runtime target |
| hard limit | Swift `#selector` / `@objc` **cannot compile** (stdlib ABI, docs/OBJC_RUNTIME.md); the user rejected a source rewriter, so an app must already be written with `Selector.named()` / closures / `UIAction` | no `#selector` limit |
| everything else | identical | identical |

Both routes are scored. The `SEL` column is the only difference between them.

---

## 1. The corpus — 20 apps, every SHA pinned

All cloned `--depth 1 --single-branch` by `clone_corpus.sh`; **20 of 20
succeeded, 0 failed**, and the failure case writes a `FAILED` row rather than
silently shrinking the denominator. 3.1 GB, 28,380 Swift files, 5,551,038 Swift
lines.

The four census apps are first because they are the **instrument control**, not
because they rank well.

| app | SHA | app | SHA |
|---|---|---|---|
| artsy/eidolon | `44486ed` | Ranchero-Software/NetNewsWire | `3b378e7` |
| duckduckgo/iOS | `7b3f601` | TelegramMessenger/Telegram-iOS | `6ad963e` |
| kickstarter/ios-oss | `2f2dabb` | videolan/vlc-ios | `12cd503` |
| Automattic/pocket-casts-ios | `3b27afc` | nextcloud/ios | `8104883` |
| wikimedia/wikipedia-ios | `2f334df` | Automattic/simplenote-ios | `9b1bb17` |
| wordpress-mobile/WordPress-iOS | `8d89c36` | weiran/Hackers | `83016de` |
| signalapp/Signal-iOS | `eec0a2f` | artsy/eigen | `8d61cf9` |
| mozilla-mobile/firefox-ios | `b0799c3` | element-hq/element-ios | `36a1788` |
| mozilla-mobile/focus-ios | `a283252` | ProtonMail/ios-mail | `701463f` |
| mastodon/mastodon-ios | `ea5ef8e` | home-assistant/iOS | `2ada5dd` |

---

## 2. Instrument check — the controls reproduce the record

Every number below comes from an existing instrument, re-cut per app. Run on
the four census apps, the results reproduce what is already recorded:

| quantity | recorded | re-run 2026-08-27 | |
|---|---|---|---|
| UIKit SDK types (Catalyst headers) | 737 | **737** | exact |
| OpenUIKit exported `UI`/`NS`/`CA` types, **derived from `Sources/OpenUIKit`, not from the doc** | 180 (M14 tip) | **180** | exact |
| distinct UIKit types referenced / implemented / missing | 220 / 116 / 104 | **220 / 116 / 104** | exact |
| frequency-weighted coverage | 91.5 % (14,954 / 16,343) | **91.5 %** (14,915 / 16,301) | −42 uses, HEAD drift |
| per-app Swift files (eidolon / ddg / ios-oss / pocket-casts) | 159 / 1197 / 2053 / 1690 | 159 / 1197 / **2055** / **1692** | drift, as `census/README.md` predicts |
| SwiftUI view-declaring files / View types | 661 / 722 | **663 / 725** | drift |
| eidolon SwiftUI | ZERO | **ZERO** | exact |
| model-layer references | 18,024 | **18,044**; family shares identical to 0.1 pt | drift |

`ladder_census.py`'s per-app re-cut is **byte-equal to `census.py`** on the
controls (file counts, distinct types, and 16,301 = 16,301 total uses) and
**byte-equal to `swiftui_census.py`** on all nine of its counters. So the
ladder's per-app numbers are the same instrument, not a lookalike.

`ladder_census.py`'s model number uses only the curated `FAMILIES` alphabet,
not `model_census.py`'s 416-name superset: 17,758 vs 18,044 on the controls,
**98.4 %**. The 286-use difference is NS*-prefixed Foundation header names that
belong to no family.

### What each instrument cannot see — carried with every number

| number | produced by | blind to |
|---|---|---|
| UIKit uses / missing types | `\b((?:UI\|NS\|CA)[A-Z]\w*)\b` filtered against the 737 SDK header names | types reached only by inference; indirect conformances; anything in a string. Line comments are stripped, **block comments are not**. Over-counts dead code. |
| model-layer uses | Foundation's ObjC header names + curated Swift value types | cannot distinguish `Foundation.Data` from an app's `Data`. **Families and rankings solid; individual counts order-of-magnitude.** |
| SwiftUI share | unambiguous signals only (`: View`, `some View`, `var body:`, `@State`-family) | **no API-use count is produced, deliberately** — see `swiftui_census.py`'s docstring. `import SwiftUI` over-counts adoption and is reported separately. |
| UIKit-first share | `class X: …UIView/UIViewController/…` — the mirror of `: View`, unambiguous the same way | a UIKit view built by composition without subclassing; a subclass of an app's own base class |
| `#selector` classification | what else is on the **same line** | a site whose wiring is on another line lands in `unclassified` — so `unclassified` is a **floor on both categories, not a residue** |
| build shape | file existence + line grep | `pod '` counts declared pods, not the resolved transitive set; SPM pins and direct URLs are different denominators and are reported separately |
| size | file and line counts including blanks and comments | — |

**Two walks, two denominators, on purpose.** UIKit counts use apicensus's
`SKIP_DIRS` (Tests excluded) so they are comparable to the record; model,
SwiftUI and selector counts use the census scripts' skip set (Tests included).
Every table names which. NetNewsWire's "99,999 Swift lines" is not a cap: `wc -l`
over the same file set gives 99,303 newlines and the walk sees 696 files —
99,303 + 696 = 99,999, because the convention is `count("\n") + 1` per file.
Checked because a round number is exactly the shape of a saturated metric.

### One blindness found by spot-check, not assumed

**The model census's networking family cannot see a third-party network stack.**
eidolon scores **1 Foundation-networking reference** and imports Moya (32
files), RxSwift (87), SwiftyJSON (14) and Alamofire (2). ios-oss scores 128 and
imports ReactiveSwift (434) and Apollo (35). Read a low networking-family score
as "low *Foundation* networking", **never** as "offline-capable". `NETLIBS` in
`score_ladder.py` corrects for this in the `NET` subscore.

---

## 3. The ladder

Rubric in `score_ladder.py`: eight subscores, each an **ordinal bucket 0–3 of a
measured quantity**, thresholds written in the script rather than chosen per
app. The composite is a plain sum with **no weights**, because nothing in this
project measures the relative cost of "one more Apple framework" against "one
more missing UIKit type". **Read the subscores; the total only orders apps into
bands.**

`UI` SwiftUI share of view-declaring files · `OBJC` ObjC share of source lines ·
`NIB` nib-bound Swift files · `UIK` genuinely-missing UIKit uses · `MOD`
distinct imported modules · `FW` distinct non-UIKit/Foundation Apple frameworks
· `NET` Foundation networking + third-party stack · `SIZE` Swift files ·
`SEL` `#selector` sites (route (a) only).

Two **gates** override the sum, because they are not degrees:
SwiftUI-majority (the framework does not exist here) and ObjC-majority (that
app is on the facade road, not this one).

| app | UI | OBJC | NIB | UIK | MOD | FW | NET | SIZE | **=B** | SEL | **=A** | verdict (b) Apple tc | verdict (a) Linux swiftc |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **eidolon** | 0 | 0 | 3 | **0** | 1 | 0 | 1 | 0 | **5** | 1 | **6** | **NEAR** | **NEAR** |
| **focus-ios** | 2 | 0 | 0 | 1 | 1 | 2 | 0 | 0 | **6** | 2 | **8** | **NEAR** | **NEAR** |
| eigen | 1 | 3 | 1 | 1 | 0 | 1 | 0 | 0 | 7 | 2 | 9 | FAR — ObjC-majority (facade) | FAR — ObjC-majority (facade) |
| Hackers | 3 | 0 | 1 | 1 | 1 | 1 | 1 | 0 | 8 | 1 | 9 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| ProtonMail-ios | 3 | 0 | 0 | 1 | 2 | 2 | 0 | 2 | 10 | 2 | 12 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| **simplenote-ios** | 1 | 2 | 2 | 1 | 1 | 2 | 0 | 1 | **10** | 3 | 13 | **MID** | FAR — `#selector` wall |
| vlc-ios | 1 | 3 | 2 | 2 | 1 | 2 | 0 | 0 | 11 | 3 | 14 | FAR — ObjC-majority (facade) | FAR — ObjC-majority (facade) |
| **ios-oss** | 1 | 0 | 1 | 1 | 2 | 2 | 2 | 3 | **12** | 3 | 15 | **MID** | FAR — `#selector` wall |
| mastodon-ios | 3 | 0 | 0 | 2 | 2 | 2 | 3 | 1 | 13 | 2 | 15 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| NetNewsWire | 2 | 1 | 2 | 2 | 2 | 2 | 2 | 1 | 14 | 3 | 17 | MID | FAR — `#selector` wall |
| Signal-iOS | 1 | 0 | 0 | 3 | 2 | 3 | 3 | 3 | 15 | 3 | 18 | MID | FAR — `#selector` wall |
| Telegram-iOS | 0 | 2 | 0 | 3 | 3 | 3 | 1 | 3 | 15 | 3 | 18 | MID | FAR — `#selector` wall |
| duckduckgo-ios | 3 | 0 | 1 | 2 | 2 | 3 | 2 | 2 | 15 | 3 | 18 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| nextcloud-ios | 2 | 1 | 2 | 2 | 2 | 3 | 2 | 1 | 15 | 3 | 18 | MID | FAR — `#selector` wall |
| home-assistant-ios | 3 | 0 | 0 | 2 | 3 | 3 | 3 | 2 | 16 | 2 | 18 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| firefox-ios | 1 | 0 | 0 | 3 | 3 | 3 | 3 | 3 | 16 | 3 | 19 | FAR | FAR — `#selector` wall |
| wikipedia-ios | 3 | 2 | 2 | 2 | 1 | 2 | 2 | 2 | 16 | 3 | 19 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| element-ios | 3 | 3 | 2 | 1 | 2 | 3 | 0 | 3 | 17 | 3 | 20 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| pocket-casts-ios | 3 | 0 | 2 | 2 | 2 | 3 | 3 | 2 | 17 | 3 | 20 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| WordPress-iOS | 2 | 1 | 1 | 2 | 3 | 3 | 3 | 3 | 18 | 3 | 21 | FAR | FAR — `#selector` wall |

**Route (b) — Apple toolchain: NEAR 2, MID 6, FAR 12.**
**Route (a) — Linux cross-swiftc: NEAR 2, MID 0, FAR 18.** Route (a) collapses
because **only 2 of 20 apps have ≤ 10 `#selector` sites** (eidolon 8, Hackers
3); the corpus total is **5,680 `#selector` and 13,380 `@objc`**.

### The headline the ladder does not show

**No app in this corpus is close to runnable, and in no app is UIKit the
reason.** Effective UIKit coverage ranges **87.5 % – 100.0 %** across all
twenty. The 12 FAR verdicts are 8 × SwiftUI, 3 × ObjC-majority, and 1 × sheer
mass — not one is "OpenUIKit is missing too much".

### Is SwiftUI so universal that the ladder is padding?

Not quite, and the number is worth stating precisely rather than as an
impression. **UIKit-first** (SwiftUI < 25 % of view-declaring files **and**
ObjC < 30 % of source lines) is **6 of 20**: eidolon (0.0 %), Telegram-iOS
(7.6 %), Signal-iOS (13.7 %), ios-oss (21.2 %), simplenote-ios (21.5 %),
firefox-ios (23.2 %) — with focus-ios just outside at 26.1 %. **8 of 20 are
SwiftUI-majority**, and only **1 of 20 has zero SwiftUI at all** (eidolon,
a 2014-era app). The split is generational, exactly as the SwiftUI census
found: the floor is real, but it is a floor, and the newest apps in the corpus
are the SwiftUI-heaviest.

---

## 4. Per-app gap tables — the top five, with each one's gate named

### 4.1 eidolon (Artsy auction kiosk) — B 5 / A 6, **NEAR on both routes**

159 Swift files, 13,949 lines. 39 UIKit-subclass files, **0 SwiftUI**,
3 ObjC files (46 lines).

| gap | measurement | note |
|---|---|---|
| **missing UIKit types** | **0 uses, 0 types** | **Verified by grep, not inferred**: `UIVisualEffectView\|UIPasteboard\|UICollectionViewCompositionalLayout\|UIImpactFeedbackGenerator\|UIPageViewController\|UISearchController\|NSTextAttachment\|UIViewControllerTransitionCoordinator\|UIViewPropertyAnimator` over eidolon's Swift returns **nothing**. Its whole 99-use "missing" column is `NSObject` 32 + `NSString` 14 + `NSCoder` 5 + `NSValue` 1 (Foundation) and `UIStoryboard` 32 + `UIStoryboardSegue` 13 + `UIWebView` 2 (out of scope). |
| **storyboards** | 26 of 159 files carry `@IBOutlet`; `Auction.storyboard` + `Fulfillment.storyboard` + `KeypadView.xib` | **This is the app's blocker.** `UIStoryboardExtensions.swift` loads both storyboards by name; they are the two flows. Storyboards are out of scope *by choice* — so eidolon is NEAR only if that choice is revisited, or 16 % of its files are rewritten. |
| **model layer** | 308 Foundation references; **1** Foundation-networking | but **145 files import a third-party network/reactive stack** — RxSwift 87, Moya 32, SwiftyJSON 14, RxCocoa 7, Alamofire 2, RxOptional 11, RxBlocking 5, Action 20. Every one must compile too. |
| **route (a)** | **8 `#selector` sites, all UI-wiring, 0 deep**; 25 `@objc` | The smallest `#selector` surface in the corpus after Hackers. Eight hand edits to `Selector.named()`, no rewriter needed. |
| **build** | **CocoaPods, 37 declared pods, no SPM at all**; 1 xcodeproj + 1 xcworkspace | Includes **`Stripe 14.0.1` and `CardFlight-v4` — closed-source binary SDKs** — plus a `cocoapods-keys` plugin that needs 11 API keys before the project will even resolve. Several pods are ObjC (`Artsy+UILabels`, `ORStackView`, `FLKAutoLayout`, `ARAnalytics`, `ARTiledImageView`). |
| **frameworks** | **1** non-UIKit/Foundation Apple framework — the lowest in the corpus | the only app here that does not drag in WebKit / AVFoundation / CoreData / MapKit / … |

**Verdict in one line:** the *cleanest UIKit demand in the corpus, and the
worst build*. Its UIKit gap is literally zero; its blockers are storyboards,
CocoaPods with two binary SDKs, and a reactive stack larger than the app.

### 4.2 focus-ios (Firefox Focus) — B 6 / A 8, **NEAR on both routes**

227 Swift files, 24,139 lines. 51 UIKit-subclass files vs 18 SwiftUI, **0 ObjC,
0 nib-bound files**.

| gap | measurement | note |
|---|---|---|
| **missing UIKit types** | **88 uses / 35 types**, effective coverage 93.4 % | Ranked: `UIPasteboard` 21, `UIPageViewController` 7, `NSItemProvider` 6, `UIViewControllerTransitionCoordinator` 4, `UIDropInteraction` 4, `UIViewPropertyAnimator` 4, then a 29-type tail at ≤ 3 each — drag/drop (5 types), pointer (5), print (3), diffable data source (2). **The single largest item is one type.** |
| **SwiftUI** | 18 view-declaring files, 26.1 % | **Confined and checked**: `Onboarding/SwiftUI Onboarding` (5), `InternalSettings` (6), `DesignSystem/Preview Files` (3), Widgets (2), Licenses (1). The browser chrome itself is UIKit. |
| **WebKit** | **6 files import WebKit, 4 use `WKWebView`** | **The decisive blocker, and it is not UIKit.** A browser without a web view has no content area. WebKit is an entire unbuilt framework and nothing in this project plans for one. |
| **model layer** | 956 references, 42 Foundation-networking, **0 third-party network libs** | genuinely small; the network work is inside WebKit |
| **route (a)** | 77 `#selector` (73 wiring, 1 deep, 3 unclassified); 86 `@objc` | 77 mechanical edits — over the 10-site line but nothing structural |
| **build** | **plain SPM** (`BlockzillaPackage` + `ContentBlockerGen`) + 1 xcodeproj, **no Pods, no Bazel, no submodules**; 35 modules; 6 direct SPM URLs | the *easiest build in the corpus* |
| **assets** | 8 `.xcassets`, **633 `.strings`**, 1 storyboard | asset catalogs and localization are both live |

**Verdict in one line:** *the best build and the cleanest UI shape in the
corpus, blocked on one framework nobody has scoped.* If WebKit could be stubbed
to a blank content view, focus-ios is the app to try first.

### 4.3 eigen (Artsy) — B 7 / A 9, gated **FAR: ObjC-majority**

140 Swift files (12,940 lines) against **193 `.m`/`.mm` files (19,038 lines) =
59.5 % of source**. UIKit gap 21 uses / 13 types, effective coverage 96.3 %;
23 modules and 5 heavy frameworks — the lowest dependency load after eidolon;
only 3 nib-bound Swift files; 29 `#selector`.

**Why the gate fires:** its Swift half cannot be recompiled in isolation
because the majority of the app is Objective-C. That is the **facade** road
(docs/OBJC_FACADE.md — ~750 C entry points for the top-20 types covering 71 %
of uses, ~10k lines; ~2,200 entry points / ~30k lines for everything). eigen is
the **best-shaped candidate on that road** in this corpus: small, low
dependency count, low UIKit gap. It also carries 34 CocoaPods and a React
Native bridge (`React`, `ReactAppDependencyProvider`).

### 4.4 Hackers — B 8 / A 9, gated **FAR: SwiftUI-majority**

150 Swift files, 31,130 lines, **0 ObjC, 1 nib-bound file, 3 `#selector` sites
— the lowest in the corpus**. UIKit gap is **3 uses / 2 types**
(`UIPasteboard` 2, `UIImpactFeedbackGenerator` 1). Clean multi-module SPM
(6 manifests, 6 pins), 29 modules.

**Why the gate fires:** 31 view-declaring files vs 4 UIKit-subclass files =
**88.6 % SwiftUI**. Everything else about this app is ideal. It is the single
best argument in the corpus for the SwiftUI decision: a small, modern, clean,
pure-SPM app that this stack cannot run **for exactly one reason**.

### 4.5 simplenote-ios — B 10 / A 13, **MID (b)** / FAR (a)

351 Swift files (33,225 lines) + 51 ObjC files (9,558 lines, 22.3 %).
21.5 % SwiftUI, 26 nib-bound files (7.4 %), 28 xib/storyboards.
UIKit gap **81 uses / 27 types**, effective coverage 94.4 %: `UIContextualAction`
12, `UIPasteboard` 10, `UIApplicationShortcutItem` 7, `UIBlurEffect` 6,
`UIMenuController` 5. Model layer 903 references, 36 Foundation-networking,
0 third-party network libs — but it syncs through **Simperium** (ObjC) and
CoreData (10 files). Route (a) dies on **103 `#selector` / 410 `@objc`**.
Build is clean: 1 SPM manifest, 1 xcodeproj, no Pods.

---

## 5. THE UNION PUNCH LIST — what unlocks the most apps

### 5.1 UIKit types — the roadmap ordering

At 4 apps the corpus referenced 220 distinct UIKit types. **At 20 apps it is
361 of 737 (49 %)** — so the vocabulary is *not* saturated at four apps and the
"~171 distinct types" framing should be read as a per-app figure, not a corpus
ceiling. But the shape holds where it matters: **108 types are referenced by
≥ 10 of the 20 apps, and only 25 of those 108 are missing.**

Union: **115,846 UIKit uses, 88.1 % weighted coverage, 95.7 % effective**
(Foundation-free 8,381 + out-of-scope 440 removed), leaving a **4,925-use gap
across 233 missing types**.

Ranked by **how many of the 20 apps each unlocks** — the census's own rule,
because a type at 0.1 % of uses can still be why an app does not launch:

| # | type / cluster | apps | uses | note |
|---|---|---|---|---|
| 1 | `UIViewControllerTransitionCoordinator` | **18** | 141 | with `UIPercentDrivenInteractiveTransition` (5 apps) and `UIViewControllerInteractiveTransitioning`. **Sits directly on M7.5's interactive back-swipe and M12's presentation API, both of which already exist** — this is the public handle onto them. Highest app-reach in the corpus and among the cheapest. |
| 2 | `UIPasteboard` | **17** | 409 | one type; no system pasteboard off-device, so the honest shape is a process-local one |
| 3 | **materials / blur** — `UIVisualEffectView` 17/384, `UIBlurEffect` 16/265, `UIGlassEffect` 7/79, `UIVisualEffect` 5/35 | **17** | **763** | the oldest open divergence and the largest source of remaining pixel error. Real work: backdrop-sampling blur in the compositor. |
| 4 | **haptics** — `UIImpactFeedbackGenerator` 16/100, `UINotificationFeedbackGenerator` 11/75, `UISelectionFeedbackGenerator` 11/21 | **16** | 196 | no hardware to drive; a call-recording no-op is the honest and testable shape. Pure compile-blocker removal. |
| 5 | **home-screen shortcuts** — `UIApplicationShortcutItem` 16/77, `UIApplicationShortcutIcon` 11/29, `UIMutableApplicationShortcutItem` | **16** | ~110 | value types plus one `UIApplication` property. No pixels, no oracle. |
| 6 | `NSItemProvider` (+ activity items) | 13 | 103 | |
| 7 | `NSTextAttachment` (+ TextKit-1 `NSTextContainer` 8, `NSTextStorage` 5) | 12 | 168 | the attachment is real work — an inline image box the text engine must lay out |
| 8 | `UIViewPropertyAnimator` (+ `UIViewImplicitlyAnimating`, `UISpringTimingParameters`) | 11 | ~160 | sits on M6's frame-exact spring animator |
| 9 | **table/collection extras** — swipe actions (`UIContextualAction` 10/67, `UISwipeActionsConfiguration` 10/67), diffable (`NSDiffableDataSourceSnapshot` 9, `UITableViewDiffableDataSource` 7, `UICollectionViewDiffableDataSource` 7) | 10 | ~290 | the named tail of the shipped collection-view cluster |
| 10 | `UIPageViewController` (+ its data-source / delegate) | 10 | ~207 | |
| 11 | **search controller** — `UISearchController` 10/128, `UISearchResultsUpdating` 9/35, `UISearchControllerDelegate` 8/20 | 10 | 183 | on top of the `UISearchBar` already shipped |
| 12 | **system pickers** — `UIDocumentPickerViewController` 10/51 + delegate 10/22, `UIImagePickerController` 9/75 | 10 | 148 | system UI we cannot reproduce; a compiling stub that reports "unavailable" |
| 13 | `UIAccessibilityCustomAction` | 9 | 87 | |
| 14 | `UISceneConfiguration` / `UIOpenURLContext` / `UIUserActivityRestoring` | 9 | 51 | the scene-lifecycle surface, adjacent to #56's process layer |
| 15 | **drag & drop** — `UIDropSession` 8/61, `UIDragItem` 7/41, `UIDragSession` 7/27, + 6 more | 8 | ~230 | |
| 16 | **compositional layout** — `NSCollectionLayoutSection` 8/51, `NSCollectionLayoutSize` 7/59, `NSCollectionLayoutItem` 7/30, `NSCollectionLayoutGroup` 7/27, `UICollectionViewCompositionalLayout` 8/31 | 8 | 198 | |

**Items 1, 4 and 5 together reach 18, 16 and 16 of 20 apps for what the M14
punch list already calls "no pixels, no oracle needed" and "trivially
stubbable".** That is the cheapest reach-per-line anywhere in this document.

Full ranked list: `uikit-union-2026-08-27.json`.

### 5.2 Model surface — 130,883 references across 20 apps

Supply bands derived from what is actually on disk or recorded (see
`model_supply.py`'s docstring for how each name was placed), **not asserted**:

| band | uses | share | biggest members (apps/uses) |
|---|---|---|---|
| **PROVEN** (oracle passes, host and guest) | 18,684 | 14.3 % | `URL` (20/18,684) — the single most-referenced model name in the corpus, and the one thing that is proven |
| **IN-FLIGHT** (#77 json-oracle) | 12,966 | 9.9 % | `Codable` 18/3,131 · `CodingKeys` 17/3,074 · `Decoder` 15/1,589 · `JSONDecoder` 18/756 · `JSONSerialization` 19/569 |
| **COMPILED-UNVERIFIED** (in the 202-file FoundationEssentials compile; 0 errors and nothing else) | 39,967 | 30.5 % | `Data` 20/14,871 · `Date` 20/9,001 · `Error` 20/7,645 · `TimeInterval` 20/3,025 · `UUID` 19/2,459 · `Calendar` 19/1,060 · `Locale` 19/812 |
| **SUBSTRATE-PRESENT** (#45 `_Concurrency`, #47 libdispatch, both closed) | 9,203 | 7.0 % | `Task` 19/5,347 · `DispatchQueue` 20/3,510 |
| **OPENUIKIT-SHADOWS** (OpenUIKit declares its own) | 17,390 | 13.3 % | `NSAttributedString` 18/8,385 · `NotificationCenter` 20/3,581 · `Notification` 18/2,736 · `Timer` 18/1,068 |
| **STUBBED** (#69) | 3,467 | 2.6 % | `FileManager` 20/1,799 · `Bundle` 20/1,615 |
| **CF-BRIDGE-ONLY** (foundation-macho emits `NSURL` + 19 `__NSCF*`: plumbing, no Swift surface) | 13,642 | 10.4 % | `NSCoder` 20/4,098 · `NSNumber` 19/3,711 · `NSString` 20/1,798 · `NSError` 19/1,644 |
| **ICU-BLOCKED** (#48) | 1,478 | 1.1 % | `DateFormatter` 19/790 · `NumberFormatter` 17/208 |
| **ABSENT** | 14,086 | 10.8 % | see below |

**The ABSENT list, ranked by app-reach — this is the model punch list:**

| # | item | apps | uses |
|---|---|---|---|
| 1 | **`UserDefaults`** | **20 / 20** | 2,586 |
| 2 | **the `URLSession` family** — `URLRequest` 19/1,346, `URLSession` 19/892, `URLComponents` 18/572, `URLQueryItem` 17/615, `HTTPURLResponse` 17/509, `URLResponse` 15/255, `URLSessionConfiguration` 15/118, `URLError` 9/374, + 9 more | **19 / 20** | **~4,900** |
| 3 | `CharacterSet` | 20 / 20 | 430 |
| 4 | `NSPredicate` | 18 / 20 | 938 |
| 5 | `NSRegularExpression` | 18 / 20 | 403 |
| 6 | `Thread`, `NSLock`, `Operation`, `OperationQueue` (corelibs, not FoundationEssentials) | 17 / 20 | ~1,000 |
| 7 | `NSNotification` (the ObjC half; the Swift half is OpenUIKit's) | 16 / 20 | 593 |
| 8 | `IndexSet` | 13 / 20 | 364 |
| 9 | `NSKeyedArchiver` / `NSKeyedUnarchiver` / `NSSecureCoding` / `NSCoding` | 12 / 20 | ~410 |
| 10 | `NSCache` | 12 / 20 | 48 |
| 11 | CoreData (`NSManagedObjectContext` 638 in 6 apps) | 6 / 20 | ~1,200 |

**`UserDefaults` is referenced by every app in the corpus and has nothing
behind it. It is the single highest-reach missing name in the whole
measurement — higher than any UIKit type.** Second is networking, at 19 of 20
apps and ~4,900 uses; and the third-party-stack spot-check above means even
apps that *look* offline are usually not.

**Two things the band table cannot tell you.** "COMPILED-UNVERIFIED" means 0
compile errors and nothing more — only `URL` has been run against an oracle,
and this project's own record is that a clean compile has repeatedly meant less
than it looked like. And "OPENUIKIT-SHADOWS" is not free: a shadowing
`NSAttributedString` cannot be handed to Foundation's, which is a divergence
the app sees, not one the library hides.

### 5.3 Build capability — measured, and it is the biggest gap of the three

| capability | apps needing it | evidence |
|---|---|---|
| **asset catalogs** (`.xcassets`) | **20 / 20** | 1–42 catalogs each; `.xcassets` is currently unread, only loose `@2x`/`@3x` resolve |
| **`.xcodeproj` interpretation** | **19 / 20** | only ProtonMail-ios has none |
| **localization** (`.strings`) | **17 / 20** | 2 – 8,059 files (firefox-ios) |
| **multi-module SPM in-tree** | **15 / 20** | 1 – 45 manifests. Every app is 23–837 imported modules, not one target. |
| **xib / storyboard** | 13 / 20 have nib-bound Swift; 19 / 20 ship the files | out of scope by choice — and it is *why* eidolon, pocket-casts and wikipedia carry a hard floor |
| **CocoaPods resolution** | 5 / 20 | eidolon (37 pods, incl. 2 binary SDKs + a keys plugin), eigen (34), element-ios (25), Signal-iOS (16), vlc-ios (7) |
| **git submodules** | 4 / 20 | Telegram 14, Signal 2, duckduckgo 1, element 1 |
| **Bazel** | 1 / 20 | Telegram-iOS (812 BUILD files, `MODULE.bazel` + `WORKSPACE`) |
| **Tuist** | 1 / 20 | ios-oss |

**The ordering this implies.** Asset catalogs (20/20) and the multi-module SPM
graph (15/20, and *every* app is a module graph) outrank every UIKit type on
the punch list. Nothing about them needs an oracle.

### 5.4 So: the single ordering the user asked for

1. **`UserDefaults`** — 20/20 apps, nothing behind it, no oracle needed.
2. **Asset catalogs** — 20/20 apps, self-contained, no oracle needed.
3. **`URLSession` family** — 19/20 apps, ~4,900 uses. The largest single project
   on this list, and the one nothing can route around.
4. **`UIViewControllerTransitionCoordinator` + haptics + shortcuts** — 18, 16
   and 16 of 20 apps, all cheap, none needing pixels.
5. **JSON/Codable landing** (#77, in flight) — 18/20 apps, 12,966 uses.
6. **`FileManager`** (#69, stubbed) — 20/20 apps, 3,419 uses.
7. **Materials / blur** — 17/20 apps, and the largest remaining *pixel* error.
8. Then the type tail: `UIPasteboard`, `NSItemProvider`, `NSTextAttachment`,
   `UIViewPropertyAnimator`, table/collection extras, search, pickers.

Route (a) additionally needs **every one of an app's `#selector` sites already
written portably** — and at 5,680 sites across the corpus, that selects apps
rather than being fixed by work on our side.

---

## 6. Named unknowns — measured NOT, and why

Recorded rather than guessed, following the sysdir precedent.

1. **Whether any of these apps compiles.** Nothing was built. Every number here
   is textual. A clean census is not a clean build, and the gap between them is
   where this project has repeatedly found its real work.
2. **The SwiftUI API-use count.** Still unobtainable by text, for the collision
   reasons in `swiftui_census.py`. It needs a semantic index (compiler index
   store, or swift-syntax with type resolution). It remains the single number
   that would most change any SwiftUI estimate.
3. **What is inside the in-tree modules.** Every app is 23–837 imported
   modules, and the census walks *all* Swift under the clone, so in-tree module
   code is counted — but no attempt was made to separate "the app target" from
   "its 40 local packages", nor to determine which modules are reachable from
   the iOS app target. NetNewsWire imports `AppKit` in 132 files because it is a
   Mac app too; those files are in the denominator.
4. **Third-party dependency compilability.** `NETLIBS` detects that a network
   stack exists; nothing measures whether RxSwift, ReactiveSwift, GRDB, Realm,
   SwiftProtobuf, Lottie or `proton_app_uniffi` (a Rust FFI module) could be
   built for this target. For eidolon and eigen, closed-source binary pods
   (`Stripe`, `CardFlight-v4`) make the answer "no" without further work.
5. **Non-Swift, non-ObjC code.** C/C++/Rust in the dependency graph was not
   counted. Telegram's `third-party/`, Signal's `LibSignalClient` and
   `SignalRingRTC`, VLC's `VLCKit`, ProtonMail's uniffi module are all in this
   class.
6. **WebKit, AVFoundation, CoreData, MapKit and 60 more.** The `FW` subscore
   counts *how many* heavy Apple frameworks an app imports (0 for eidolon, 52
   for Telegram) and says **nothing** about what any one of them would cost.
   WebKit alone decides focus-ios, firefox-ios and duckduckgo-ios.
7. **Whether an app's UI is reachable at all without its network.** Not
   measured. An app that compiles and launches to an empty screen is not a
   result, and no instrument here distinguishes that case.
8. **Test targets.** Counted in the model/SwiftUI walk, excluded from the UIKit
   walk. Nothing here says whether an app's tests could run.
9. **Binary property lists.** A real `.ipa` path needs them; #56 named the gap
   and the parser reports the format rather than pretending. Every Info.plist
   in this corpus was assumed XML and not checked.
10. **`@objc` beyond `#selector`.** 13,380 `@objc` sites were counted and
    classified only coarsely: `@objc dynamic` 321, `@objc protocol` 203,
    `@objc(Name)` 785, `@objcMembers` 305 — leaving ~11,700 plain `@objc`
    unclassified. Which of them are *load-bearing* (KVO, ObjC subclassing,
    NSCoding) versus incidental was not determined, and route (a) needs that
    answer per app. Corpus-wide the `#selector` classification is 4,361 wiring /
    58 deep / 1,265 unclassified, and per §2 the unclassified are a floor on
    both, not a residue.

---

## 7. Reproducing

```sh
full/ladder/clone_corpus.sh scratch/ladder-corpus            # pins SHAs
# instrument control: must reproduce 737 / 180 / 220 / 116 / 104 / 91.5%
~/uikit/Tools/apicensus/run.sh <dir-with-the-four-census-apps>
full/ladder/ladder_census.py scratch/ladder-corpus \
    uikit_sdk_types.txt openuikit_types.txt ladder-census-2026-08-27.json
full/ladder/union_and_imports.py scratch/ladder-corpus \
    uikit_sdk_types.txt openuikit_types.txt \
    uikit-union-2026-08-27.json imports-full-2026-08-27.json
full/ladder/score_ladder.py ladder-census-2026-08-27.json \
    imports-full-2026-08-27.json nibdeps.tsv ladder-scores-2026-08-27.json
full/ladder/model_supply.py ladder-census-2026-08-27.json model-supply-2026-08-27.json
```

`nibdeps.tsv` comes from `full/ladder/nibdeps.sh <corpus>`, which measures how
many `.swift` files are **bound** to a nib rather than how many `.xib` files
sit in the tree — an app can ship 160 xibs and be code-based where it matters,
or ship 3 and load its whole UI from them (eidolon does the latter).

**Every committed JSON here was regenerated by the committed scripts and the
ladder re-scored from that output unchanged** — no number in this document
comes from a one-off inline pass that no script reproduces.

`uikit_sdk_types.txt` (737) and `openuikit_types.txt` (180) are regenerated by
the two greps at the top of `~/uikit/Tools/apicensus/run.sh` — **from the SDK
headers and from `Sources/OpenUIKit`, never from a doc.**

Outputs: `ladder-census-2026-08-27.json` (per-app raw),
`ladder-scores-2026-08-27.json` (the ladder), `model-supply-2026-08-27.json`,
`uikit-union-2026-08-27.json`, `imports-full-2026-08-27.json`, `nibdeps.tsv`.
