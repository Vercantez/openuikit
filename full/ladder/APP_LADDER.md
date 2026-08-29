# The APP LADDER — 20 open-source iOS apps ranked by distance-from-runnable

Measured 2026-08-27. Tooling in this directory, corpus SHAs pinned in
`scratch/ladder-corpus/PINS.txt`, raw output in the JSON files beside this one.
**Measurement only — nothing was built, nothing was fixed.**

**Port-roadmap update (2026-08-28):** the scores below remain the frozen
baseline, but “out of scope” is no longer the project policy. The
source-unchanged [`Apple framework port roadmap`](../framework-roadmap/FRAMEWORK-ROADMAP.md)
now tracks all 135 observed Apple first-party modules, and the measured
[`SwiftUI port contract`](../swiftui/ROADMAP.md) defines its first Focus slice.
Those artifacts are plans and contracts. OpenUIKit `3cde5ad` implements the
first exact two-file Focus SwiftUI widget slice, but full SwiftUI, WebKit, and
the other listed frameworks are not thereby implemented or runnable.

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

### The number to hold in mind while reading everything below

**220 distinct UIKit types referenced across the four census apps, 116
implemented, 104 missing — and frequency-weighted coverage is 91.5 %.** The
missing 104 are the demand **tail**, and two consequences run through this
whole document:

* A missing-type *count* means little on its own. What matters is which tail
  entries are **walls**: a missing `UICollectionViewCompositionalLayout` puts
  cells nowhere, a missing `UIImpactFeedbackGenerator` is a no-op with no
  hardware behind it either way. So §4 and §5.1 split every app's tail into
  **BLOCKING** and **STUB-ABLE** (`classify_gaps.py` — judgement, and labelled
  as judgement).
* A dependency is a **demand row of its own**, not a build-shape footnote. It
  must itself compile against this stack, so an app whose own code is perfectly
  UIKit-shaped is still bounded by its worst load-bearing dependency. The 30
  heaviest were cloned and pushed through the same instruments (§5.2). This is
  what moved eidolon off the route-(a) NEAR rung.

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
| in-tree vs external module | `.target(name:)` / `.library(name:)` in any in-tree `Package.swift`, `PRODUCT_NAME` in any `project.pbxproj`, or a directory of that name | the directory rule over-matches, so an external dep in a same-named folder reads as in-tree. **The external list is a FLOOR.** |
| dependency class | the dep cloned and run through `ladder_census.py` itself | says what a dep DEMANDS, never whether it builds; and only 30 deps were cloned, so `DEP = ?` is a hole, not a pass |
| blocking vs stub-able | **judgement**, applied by rule in `classify_gaps.py` | it is an opinion about each type; three calls that could go either way are named in that file's docstring |
| size | file and line counts including blanks and comments | — |

**Two walks, two denominators, on purpose.** UIKit counts use apicensus's
`SKIP_DIRS` (Tests excluded) so they are comparable to the record; model,
SwiftUI and selector counts use the census scripts' skip set (Tests included).
Every table names which. NetNewsWire's "99,999 Swift lines" is not a cap: `wc -l`
over the same file set gives 99,303 newlines and the walk sees 696 files —
99,303 + 696 = 99,999, because the convention is `count("\n") + 1` per file.
Checked because a round number is exactly the shape of a saturated metric.

### Three instrument defects found by spot-check, and what each would have said

Recorded because each produced a confident, plausible, wrong table before it
was caught — and two of the three were caught only because a number failed to
move when it should have.

1. **The dep census read demo apps and documentation as library code.**
   Alamofire's `watchOS Example/ContentView.swift` and GRDB's
   `Documentation/DemoApps/` each declare `struct X: View`, which classified
   two pure-Swift libraries as **SwiftUI-bound**. Kingfisher's `Demo/` did the
   same *on top of a real SwiftUI surface*, so the false positive sat invisibly
   beside a true one. Fixed by an explicit skip list, passed only for the dep
   run — the 20-app numbers are unchanged, because a demo app inside an app
   repo is part of the app.
2. **A re-run that changed nothing, because it never ran.** The corrected dep
   census was piped to `head -3`; SIGPIPE killed Python before it wrote its
   JSON, and the classifier then re-read the *stale* file and printed an
   identical table. Caught by `md5` of the output before and after, not by
   reading the numbers. See `stale-artifact-invisible-to-every-check`.
3. **`productName` in `project.pbxproj` names EXTERNAL packages, not in-tree
   targets.** Using it as an "is this module in-tree?" signal silently deleted
   SnapKit, NextcloudKit, RealmSwift, ObjectMapper and HAKit from the very
   dependency list `deps.py` exists to produce. `PRODUCT_NAME` (a real target's
   build setting) is kept; `productName` is gone.

Two threshold corrections followed from #1: `if net:` had made SwiftSoup — an
HTML parser with one incidental URL-family reference — "networking-bound", and
`if view_bearing_files:` needed a floor. Both now require evidence
proportional to the library's size.

### One blindness found by spot-check, not assumed

**The model census's networking family cannot see a third-party network stack.**
eidolon scores **1 Foundation-networking reference** and imports Moya (32
files), RxSwift (87), SwiftyJSON (14) and Alamofire (2). ios-oss scores 128 and
imports ReactiveSwift (434) and Apollo (35). Read a low networking-family score
as "low *Foundation* networking", **never** as "offline-capable". `NETLIBS` in
`score_ladder.py` corrects for this in the `NET` subscore.

---

## 3. The ladder

Rubric in `score_ladder.py`: nine subscores, each an **ordinal bucket 0–3 of a
measured quantity**, thresholds written in the script rather than chosen per
app. The composite is a plain sum with **no weights**, because nothing in this
project measures the relative cost of "one more Apple framework" against "one
more missing UIKit type". **Read the subscores; the total only orders apps into
bands.** Bands scale with the column count (route (b) max 27 → NEAR ≤ 9,
MID ≤ 16; route (a) max 30 → NEAR ≤ 11, MID ≤ 19) rather than being retuned.

`UI` SwiftUI share of view-declaring files · `OBJC` ObjC share of source lines ·
`NIB` nib-bound Swift files · `UIK` genuinely-missing UIKit uses ·
**`DEP` worst LOAD-BEARING external dependency class** · `MOD` distinct
imported modules · `FW` distinct non-UIKit/Foundation Apple frameworks ·
`NET` Foundation networking + third-party stack · `SIZE` Swift files ·
`SEL` `#selector` sites, **app's own plus its load-bearing deps'** (route (a)
only).

Three **gates** override the sum, because they are not degrees: SwiftUI-majority
(the framework was unavailable when this baseline was scored), ObjC-majority
(that app is on the facade road, not this one), and **a SwiftUI/Combine-bound
load-bearing dependency** (same wall, one level down).

**`DEP = ?` means no external dependency of that app was among the 30
measured.** `?` scores 0, so those three rows (NetNewsWire, simplenote-ios,
vlc-ios) are **floors, not clean sheets** — each has external deps that were
simply not in the measured set.

| app | UI | OBJC | NIB | UIK | DEP | MOD | FW | NET | SIZE | **=B** | SEL | **=A** | verdict (b) Apple tc | verdict (a) Linux swiftc |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **focus-ios** | 2 | 0 | 0 | 1 | 0 | 1 | 2 | 0 | 0 | **6** | 2 | **8** | **NEAR** | **NEAR** |
| **eidolon** | 0 | 0 | 3 | **0** | 2 | 1 | 0 | 1 | 0 | **7** | 3 | 10 | **NEAR** | FAR — `#selector` wall |
| Hackers | 3 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 8 | 1 | 9 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| eigen | 1 | 3 | 1 | 1 | 1 | 0 | 1 | 0 | 0 | 8 | 2 | 10 | FAR — ObjC-majority (facade) | FAR — ObjC-majority (facade) |
| ProtonMail-ios | 3 | 0 | 0 | 1 | 0 | 2 | 2 | 0 | 2 | 10 | 2 | 12 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| simplenote-ios | 1 | 2 | 2 | 1 | **?** | 1 | 2 | 0 | 1 | 10 | 3 | 13 | MID | FAR — `#selector` wall |
| vlc-ios | 1 | 3 | 2 | 2 | **?** | 1 | 2 | 0 | 0 | 11 | 3 | 14 | FAR — ObjC-majority (facade) | FAR — ObjC-majority (facade) |
| mastodon-ios | 3 | 0 | 0 | 2 | 0 | 2 | 2 | 3 | 1 | 13 | 2 | 15 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| NetNewsWire | 2 | 1 | 2 | 2 | **?** | 2 | 2 | 2 | 1 | 14 | 3 | 17 | MID | FAR — `#selector` wall |
| ios-oss | 1 | 0 | 1 | 1 | 2 | 2 | 2 | 2 | 3 | 14 | 3 | 17 | MID | FAR — `#selector` wall |
| Telegram-iOS | 0 | 2 | 0 | 3 | 0 | 3 | 3 | 1 | 3 | 15 | 3 | 18 | MID | FAR — `#selector` wall |
| duckduckgo-ios | 3 | 0 | 1 | 2 | 0 | 2 | 3 | 2 | 2 | 15 | 3 | 18 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| Signal-iOS | 1 | 0 | 0 | 3 | 1 | 2 | 3 | 3 | 3 | 16 | 3 | 19 | MID | FAR — `#selector` wall |
| firefox-ios | 1 | 0 | 0 | 3 | 0 | 3 | 3 | 3 | 3 | 16 | 3 | 19 | MID | FAR — `#selector` wall |
| element-ios | 3 | 3 | 2 | 1 | 0 | 2 | 3 | 0 | 3 | 17 | 3 | 20 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| pocket-casts-ios | 3 | 0 | 2 | 2 | 0 | 2 | 3 | 3 | 2 | 17 | 3 | 20 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| WordPress-iOS | 2 | 1 | 1 | 2 | 0 | 3 | 3 | 3 | 3 | 18 | 3 | 21 | FAR | FAR — `#selector` wall |
| home-assistant-ios | 3 | 0 | 0 | 2 | 2 | 3 | 3 | 3 | 2 | 18 | 3 | 21 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |
| nextcloud-ios | 2 | 1 | 2 | 2 | **3** | 2 | 3 | 2 | 1 | 18 | 3 | 21 | FAR — SwiftUI-bound dep | FAR — SwiftUI-bound dep |
| wikipedia-ios | 3 | 2 | 2 | 2 | 2 | 1 | 2 | 2 | 2 | 18 | 3 | 21 | FAR — SwiftUI-majority | FAR — SwiftUI-majority |

**Route (b) — Apple toolchain: NEAR 2, MID 6, FAR 12.**
**Route (a) — Linux cross-swiftc: NEAR 1, MID 0, FAR 19.**

### What the dependency column changed, and it changed the top of the ladder

**eidolon was NEAR on both routes on the app-only count. It is not.** Its own
source has 8 `#selector` sites; **RxSwift/RxCocoa, which 87 of its 159 files
import, has 157** — so the real route-(a) figure is **165**, over the wall.
(All 157 are RxSwift's: Moya, Quick, Nimble and SwiftyJSON contribute zero.)
`focus-ios` is now the **only** app NEAR on route (a), and it gets there by
having no load-bearing external dependency at all among the measured set.

Corpus totals for route (a): **5,680 `#selector` in app source and 13,380
`@objc`**; **only 2 of 20 apps have ≤ 10 sites of their own** (eidolon 8,
Hackers 3), and one of those two loses the property to a dependency.

### The headline the ladder does not show

**No app in this corpus is close to runnable, and in no app is UIKit the
reason.** Effective UIKit coverage ranges **87.5 % – 100.0 %** across all
twenty. The 12 FAR verdicts are **8 × SwiftUI-majority, 2 × ObjC-majority,
1 × SwiftUI-bound load-bearing dependency (nextcloud-ios) and 1 × sheer mass
(WordPress-iOS)** — not one is "OpenUIKit is missing too much". Split by the
§5.1 test, the corpus's whole remaining UIKit debt is **135 blocking types /
3,234 uses**, against 90 types / 1,691 uses that can be honest no-ops.

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

Every table now carries two extra rows the first version lacked: the app's
missing-type tail **split BLOCKING vs STUB-ABLE** (`classify_gaps.py` —
judgement, per the test in that file's docstring), and its **load-bearing
external dependencies** with the worst class.

Corpus-wide the split is **135 blocking types / 3,234 uses** against
**90 stub-able types / 1,691 uses**, 0 unclassified. So roughly **a third of
the missing-type demand can be a no-op**, and the shape of the tail is very
different per app: focus-ios is 22 stub-able types against 13 blocking,
wikipedia-ios is 12 against 53.

### 4.1 focus-ios (Firefox Focus) — B 6 / A 8, **NEAR on both routes; the only route-(a) NEAR**

227 Swift files, 24,139 lines. 51 UIKit-subclass files vs 18 SwiftUI, **0 ObjC,
0 nib-bound files**.

| gap | measurement | note |
|---|---|---|
| **missing UIKit — BLOCKING** | **13 types / 29 uses** | `UIPageViewController` 7, `UIViewControllerTransitionCoordinator` 4, `UIViewPropertyAnimator` 4, `UIMenuItem` 3, `UIMenuController` 2, `UITableViewDiffableDataSource` 2, then 7 singletons. **Twenty-nine uses is the whole real UIKit debt of this app.** |
| **missing UIKit — STUB-ABLE** | **22 types / 59 uses** | `UIPasteboard` 21, `NSItemProvider` 6, drag/drop 5 types, pointer 5 types, shortcuts, printing, `UIImagePickerController`. Two thirds of its gap is a no-op. |
| **dependencies** | **0 load-bearing** among the 30 measured; `Sentry` (2 of 227 files) and `SnapKit` (7) are peripheral | **The only app in the corpus with no load-bearing external dependency measured.** This is why it is the sole route-(a) NEAR: nothing else brings `#selector` in with it. |
| **SwiftUI** | 18 view-declaring files, 26.1 % | **Confined and checked**: `Onboarding/SwiftUI Onboarding` (5), `InternalSettings` (6), `DesignSystem/Preview Files` (3), Widgets (2), Licenses (1). The browser chrome itself is UIKit. |
| **WebKit** | **6 files import WebKit, 4 use `WKWebView`** | **The decisive blocker, and it is not UIKit.** A browser without a web view has no content area. WebKit remains unbuilt, but is now an explicit first-party-framework port target. |
| **model layer** | 956 references, 42 Foundation-networking, **0 third-party network libs** | genuinely small; the network work is inside WebKit |
| **route (a)** | 77 `#selector` (73 wiring, 1 deep, 3 unclassified) + **0 from deps**; 86 `@objc` | 77 mechanical edits — over the 10-site line but nothing structural, and nothing inherited |
| **build** | **plain SPM** (`BlockzillaPackage` + `ContentBlockerGen`) + 1 xcodeproj, **no Pods, no Bazel, no submodules**; 35 modules; 6 direct SPM URLs | the *easiest build in the corpus* |
| **assets** | 8 `.xcassets`, **633 `.strings`**, 1 storyboard | asset catalogs and localization are both live |

**Verdict in one line:** *the best build, the cleanest UI shape and the only
dependency-free app in the corpus, blocked on a framework now scoped but not
yet implemented.*
If WebKit could be stubbed to a blank content view, focus-ios is the app to try
first — and its entire blocking UIKit debt is 13 types.

### 4.2 eidolon (Artsy auction kiosk) — B 7 / A 10, **NEAR (b) / FAR (a)**

159 Swift files, 13,949 lines. 39 UIKit-subclass files, **0 SwiftUI**,
3 ObjC files (46 lines).

| gap | measurement | note |
|---|---|---|
| **missing UIKit types** | **0 uses, 0 types — 0 blocking, 0 stub-able** | **Verified by grep, not inferred**: `UIVisualEffectView\|UIPasteboard\|UICollectionViewCompositionalLayout\|UIImpactFeedbackGenerator\|UIPageViewController\|UISearchController\|NSTextAttachment\|UIViewControllerTransitionCoordinator\|UIViewPropertyAnimator` over eidolon's Swift returns **nothing**. Its whole 99-use "missing" column is `NSObject` 32 + `NSString` 14 + `NSCoder` 5 + `NSValue` 1 (Foundation) and `UIStoryboard` 32 + `UIStoryboardSegue` 13 + `UIWebView` 2 (out of scope). |
| **dependencies** | **5 load-bearing measured** — RxSwift (87 files), Moya (32), SwiftyJSON (14), Quick (49), Nimble (49); worst class **networking-bound** (Moya) | **This is what demotes the app.** RxSwift is UIKit-bound and 117k lines; Moya sits on `URLSession`, which is ABSENT. |
| **route (a)** | **8 own `#selector` + 157 from RxSwift = 165** | The app's own surface is 8 sites, all UI-wiring, 0 deep — the smallest in the corpus after Hackers. **RxCocoa's 157 are the wall**, and all 157 are RxSwift's: Moya, Quick, Nimble and SwiftyJSON contribute zero. |
| **storyboards** | 26 of 159 files carry `@IBOutlet`; `Auction.storyboard` + `Fulfillment.storyboard` + `KeypadView.xib` | `UIStoryboardExtensions.swift` loads both storyboards by name; they are the two flows. Storyboards are out of scope *by choice* — so eidolon is NEAR (b) only if that choice is revisited, or 16 % of its files are rewritten. |
| **model layer** | 308 Foundation references; **1** Foundation-networking | but **145 files import a third-party network/reactive stack**. Every one must compile too. |
| **build** | **CocoaPods, 37 declared pods, no SPM at all**; 1 xcodeproj + 1 xcworkspace | Includes **`Stripe 14.0.1` and `CardFlight-v4` — closed-source binary SDKs** — plus a `cocoapods-keys` plugin that needs 11 API keys before the project will even resolve. Several pods are ObjC (`Artsy+UILabels`, `ORStackView`, `FLKAutoLayout`, `ARAnalytics`, `ARTiledImageView`). |
| **frameworks** | **0** non-UIKit/Foundation Apple frameworks — the lowest in the corpus | the only app here that does not drag in WebKit / AVFoundation / CoreData / MapKit / … |

**Verdict in one line:** the *cleanest UIKit demand in the corpus — literally
zero — and the worst everything-else*. Storyboards, CocoaPods with two binary
SDKs, and a reactive stack that is larger than the app and brings 157
`#selector` sites of its own.

### 4.3 Hackers — B 8 / A 9, gated **FAR: SwiftUI-majority**

150 Swift files, 31,130 lines, **0 ObjC, 1 nib-bound file, 3 `#selector` sites
— the lowest in the corpus, and 0 from deps**. UIKit gap is **3 uses / 2
types, both STUB-ABLE** (`UIPasteboard` 2, `UIImpactFeedbackGenerator` 1) —
**zero blocking types, the only app in the corpus with a UIKit debt of
literally nothing that matters.** Clean multi-module SPM (6 manifests, 6 pins),
29 modules, 1 measured dep (`SwiftSoup`, Foundation-heavy, not load-bearing).

**Why the gate fires:** 31 view-declaring files vs 4 UIKit-subclass files =
**88.6 % SwiftUI**. Everything else about this app is ideal. It is the single
best argument in the corpus for the SwiftUI decision: a small, modern, clean,
pure-SPM app with no blocking UIKit gap and no dependency problem, that this
stack cannot run **for exactly one reason**.

### 4.4 eigen (Artsy) — B 8 / A 10, gated **FAR: ObjC-majority**

140 Swift files (12,940 lines) against **193 `.m`/`.mm` files (19,038 lines) =
59.5 % of source**. UIKit gap 21 uses / 13 types — **10 blocking / 16 uses**
(`UIPageViewController` 4, `UISplitViewController` 2, blur 4) against
**3 stub-able / 5 uses**. 23 modules and 5 heavy frameworks — the lowest
dependency load after eidolon; only 3 nib-bound Swift files; **29 own
`#selector` + 0 from deps** (its 3 load-bearing deps — Nimble, Quick,
Interstellar — carry none).

**Why the gate fires:** its Swift half cannot be recompiled in isolation
because the majority of the app is Objective-C. That is the **facade** road
(docs/OBJC_FACADE.md — ~750 C entry points for the top-20 types covering 71 %
of uses, ~10k lines; ~2,200 entry points / ~30k lines for everything). eigen is
the **best-shaped candidate on that road** in this corpus: small, low
dependency count, low UIKit gap, and the *lowest inherited `#selector` count of
any app with real dependencies*. It also carries 34 CocoaPods and a React
Native bridge (`React`, `ReactAppDependencyProvider`).

### 4.5 simplenote-ios — B 10 / A 13, **MID (b)** / FAR (a)

351 Swift files (33,225 lines) + 51 ObjC files (9,558 lines, 22.3 %).
21.5 % SwiftUI, 26 nib-bound files (7.4 %), 28 xib/storyboards.
UIKit gap **81 uses / 27 types**, effective coverage 94.4 %, splitting
**16 blocking / 48 uses** (`UIContextualAction` 12, `UIBlurEffect` 6,
`UIMenuController` 5, `UIViewControllerTransitionCoordinator` 4) against
**11 stub-able / 33 uses** (`UIPasteboard` 10, shortcuts 10, haptics 3).
Model layer 903 references, 36 Foundation-networking, 0 third-party network
libs — but it syncs through **Simperium** (ObjC) and CoreData (10 files).
Route (a) dies on **103 `#selector` / 410 `@objc`**. Build is clean: 1 SPM
manifest, 1 xcodeproj, no Pods.

**Read its `DEP = ?` as a hole, not a pass.** None of simplenote's external
deps (Simperium, Gridicons, AutomatticTracks, ZIPFoundation) were in the 30
measured, so its B = 10 is a floor and its MID could be a FAR.

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

#### The same list, split BLOCKING vs STUB-ABLE (judgement — `classify_gaps.py`)

The whole point of the tail framing in §0: **135 of the 225 genuinely-missing
types are blocking (3,234 uses); 90 are stub-able (1,691 uses); 0
unclassified.** Roughly a third of the remaining demand can be a compiling
no-op — and it is not the third you would guess from the use counts, because
the two highest-reach entries land on opposite sides.

**STUB-ABLE, by app-reach** — a no-op, a call recorder, or an honest
"unavailable" leaves screens and state correct:

| type / cluster | apps | uses |
|---|---|---|
| `UIPasteboard` (process-local is real and correct) | **17** | 409 |
| haptics — `UIImpactFeedbackGenerator` 16, `UINotificationFeedbackGenerator` 11, `UISelectionFeedbackGenerator` 11 | **16** | 196 |
| home-screen shortcuts — `UIApplicationShortcutItem` 16, `UIApplicationShortcutIcon` 11 | **16** | ~110 |
| `NSItemProvider` | 13 | 103 |
| system pickers — `UIDocumentPickerViewController` 10 + delegate 10, `UIImagePickerController` 9 | 10 | 148 |
| `UIAccessibilityCustomAction` | 9 | 87 |
| scene lifecycle — `UISceneConfiguration` 9, `UIUserActivityRestoring` 9, `UIOpenURLContext` 7 | 9 | 51 |
| drag & drop — `UIDropSession` 8, `UIDragItem` 7, + 9 more | 8 | ~230 |
| pointer / hover — `UIPointerInteraction` 6, + 4 more | 6 | ~67 |
| printing, pencil, scribble, find, focus, UIKit Dynamics | ≤ 5 | ~70 |

**BLOCKING, by app-reach** — a no-op changes what appears, drops rows, or
wedges the app:

| type / cluster | apps | uses |
|---|---|---|
| `UIViewControllerTransitionCoordinator` | **18** | 141 |
| materials / blur — `UIVisualEffectView` 17, `UIBlurEffect` 16, `UIGlassEffect` 7 | **17** | 763 |
| `NSTextAttachment` + TextKit (`NSTextContainer` 8, `NSTextStorage` 5, `NSLayoutManager` 4) | 12 | 168 |
| `UIViewPropertyAnimator` | 11 | 151 |
| `UIPageViewController` + delegate/data-source | 10 | ~207 |
| search controller — `UISearchController` 10, `UISearchResultsUpdating` 9 | 10 | 183 |
| swipe actions — `UIContextualAction` 10, `UISwipeActionsConfiguration` 10 | 10 | 134 |
| `UISwipeGestureRecognizer` / `UIPinchGestureRecognizer` | 10 | 118 |
| diffable data sources — snapshot 9, table 7, collection 7 | 9 | 153 |
| compositional layout — `NSCollectionLayout*` 8 + `UICollectionViewCompositionalLayout` 8 | 8 | 198 |
| text input — `UITextPosition` 7, `UITextRange` 4, `UITextInput` 4 | 7 | ~100 |
| menus — `UIMenuController` 7, `UIMenuItem` 6, `UIEditMenuInteraction` 5 | 7 | 119 |
| cell content configuration — `UIContentConfiguration` 2, `UIListContentConfiguration` 5, `UIBackgroundConfiguration` 5 | 5 | ~93 |

**The re-ordering this produces.** Of the six highest-reach missing types,
**three are stub-able** (`UIPasteboard` 17, haptics 16, shortcuts 16) and
**three are blocking** (`UIViewControllerTransitionCoordinator` 18, blur 17/16).
So the cheapest genuine unlock is *transition coordinator plus the three
stub clusters* — 18/17/16/16-app reach for work that is one type of real
plumbing and three files of honest no-ops.

### 5.2 External dependencies — the demand row the first version treated as build shape

`clone_deps.sh` clones the 30 heaviest external dependencies (selection rule in
that script: imported by ≥ 2 apps, or by ≥ 25 files in one app); `deps.py`
separates in-tree modules from external ones; `dep_class.py` pushes each dep
through **`ladder_census.py` itself** and classifies it by measurement. 30 of 30
cloned, 0 failed. Pins in `dep-pins-2026-08-27.tsv`.

| class | n | deps |
|---|---|---|
| **Foundation-heavy** — mostly covered by the FoundationEssentials port | 11 | SwiftSoup, GRDB, SwiftyJSON, SwiftProtobuf, Nimble, Quick, Starscream, ReactiveSwift, ObjectMapper, Interstellar, PromiseKit |
| **UIKit-bound** — needs OpenUIKit's surface, which exists | 6 | KeychainAccess, SnapKit, AlamofireImage, **RxSwift**, SwipeCellKit, DifferenceKit |
| **ObjC** — the facade road, not this one | 5 | **Sentry** (33.5 %), SDWebImage (99.7 %), CocoaLumberjack (75.1 %), RealmSwift (46.5 %), SVProgressHUD (98.3 %) |
| **SwiftUI/Combine-bound** — the wall | 4 | Lottie, Kingfisher, Nuke, NextcloudKit |
| **networking-bound** — sits on `URLSession`, which is ABSENT | 4 | **Alamofire** (910 refs), Apollo, HAKit, Moya |
| pure-Swift portable | 0 | — |

**Zero of the thirty are pure-Swift portable.** Every heavy dependency in this
corpus needs something this stack does not yet fully have.

**Route (a): 19 of 30 deps have zero `#selector`.** The eleven that do not,
ranked: **RxSwift 157**, Sentry 67, Kingfisher 7, SwipeCellKit 7, GRDB 4,
ReactiveSwift 3, HAKit 3, Lottie 2, Nuke 2, AlamofireImage 1, DifferenceKit 1.

**Does fixing one dep unlock several apps? Mostly no, and that is the finding.**
Unlike UIKit types, the dependency graph is **per-app**: the heaviest deps are
single-app (proton_app_uniffi 533 files, ReactiveSwift 434, LibSignalClient 417,
ApolloAPI 309, PromiseKit 249). Only four measured deps are load-bearing in more
than one app — **GRDB** (Signal-iOS 183 files, home-assistant 160), Kingfisher,
Lottie and Alamofire. So the dependency row selects *which app to try*; it is
not a shared roadmap the way the UIKit and Foundation punch lists are.

**The one dependency-shaped item that IS shared** is the class, not the
library: **`URLSession`**. Four measured deps are networking-bound and every one
of them is blocked on the same absent surface — which is already §5.3 item 3.

### 5.3 Model surface — 130,883 references across 20 apps

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

### 5.4 Build capability — measured, and it is the biggest gap of the four

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

### 5.5 So: the single ordering the user asked for

1. **`UserDefaults`** — 20/20 apps, nothing behind it, no oracle needed.
2. **Asset catalogs** — 20/20 apps, self-contained, no oracle needed.
3. **`URLSession` family** — 19/20 apps, ~4,900 uses. The largest single project
   on this list, and the one nothing can route around.
4. **`UIViewControllerTransitionCoordinator` + haptics + shortcuts** — 18, 16
   and 16 of 20 apps, all cheap, none needing pixels.
5. **JSON/Codable landing** (#77, in flight) — 18/20 apps, 12,966 uses.
6. **`FileManager`** (#69, stubbed) — 20/20 apps, 3,419 uses.
7. **Materials / blur** — 17/20 apps, and the largest remaining *pixel* error.
8. Then the blocking type tail: `NSTextAttachment`, `UIViewPropertyAnimator`,
   `UIPageViewController`, search controller, swipe actions, diffable data
   sources, compositional layout.
9. And, cheap and separable, the **stub-able** clusters: `UIPasteboard` (17/20),
   `NSItemProvider` (13/20), pickers (10/20), drag & drop (8/20), pointer
   (6/20), printing/pencil/find/focus. 90 types and 1,691 uses of honest
   no-ops.

Route (a) additionally needs **every one of an app's `#selector` sites already
written portably — its dependencies' included**. At 5,680 sites in app source
and RxSwift alone carrying 157, that selects apps rather than being fixed by
work on our side. **19 of the 30 measured dependencies are `#selector`-clean;
the eleven that are not are led by RxSwift 157 and Sentry 67.**

**What the dependency row does NOT give you.** Unlike the UIKit and Foundation
lists, it is not a shared roadmap: the heaviest deps are single-app, and only
four (GRDB, Kingfisher, Lottie, Alamofire) are load-bearing in more than one.
Fixing a dependency picks an app; it does not move the field. The exception is
the class rather than the library — four measured deps are networking-bound and
all four are blocked on the same absent `URLSession`, which is already item 3.

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
4. **Third-party dependency compilability.** 30 deps were cloned, censused and
   classified (§5.2), which says what each one *demands* — it does **not** say
   whether any of them builds. And the 30 are not the whole set: the biggest
   single-app deps were **not** measured because they are not public libraries
   (`proton_app_uniffi`, a Rust FFI module, 533 files; `LibSignalClient` 417;
   `BrowserServicesKit` 246; `WordPressAPI` 119; `Glean`). Three apps
   (NetNewsWire, simplenote-ios, vlc-ios) have **no** dep in the measured set
   at all and carry `DEP = ?`. For eidolon and eigen, closed-source binary pods
   (`Stripe`, `CardFlight-v4`) make the answer "no" without further work, and
   there is no source to census.
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
10. **Whether a dep's `#selector` sites are reachable from the app.** RxSwift's
    157 are counted whole; some live in RxCocoa target-action bindings the app
    may never touch. Dead-code reachability was not computed, so the
    dep-inclusive `SEL` figure is an upper bound in the same way the app-only
    one was a lower bound.
11. **`@objc` beyond `#selector`.** 13,380 `@objc` sites were counted and
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
    imports-full-2026-08-27.json nibdeps.tsv dep-classes-2026-08-27.json \
    ladder-scores-2026-08-27.json
full/ladder/model_supply.py ladder-census-2026-08-27.json model-supply-2026-08-27.json
full/ladder/classify_gaps.py ladder-census-2026-08-27.json \
    uikit-union-2026-08-27.json gap-classes-2026-08-27.json

# dependency demand row
full/ladder/clone_deps.sh scratch/ladder-deps                      # pins SHAs
full/ladder/deps.py scratch/ladder-corpus imports-full-2026-08-27.json \
    deps-2026-08-27.json
full/ladder/ladder_census.py scratch/ladder-deps \
    uikit_sdk_types.txt openuikit_types.txt deps-census-2026-08-27.json \
    "Demo,Demos,demo,Example,Examples,example,examples,Sample,Samples,\
TestSamples,Documentation,Playground,Playgrounds,fastlane,Scripts,\
watchOS Example,Test,Tests,IntegrationTests,UITests,Benchmarks"
full/ladder/dep_class.py deps-census-2026-08-27.json deps-2026-08-27.json \
    dep-classes-2026-08-27.json ladder-census-2026-08-27.json
```

**The 5th argument to `ladder_census.py` is load-bearing and only for deps** —
without it the census reads a library's demo app as library code (§2 defect 1).
The 20-app corpus run passes no extra skips.

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
`uikit-union-2026-08-27.json`, `imports-full-2026-08-27.json`, `nibdeps.tsv`,
`gap-classes-2026-08-27.json` (blocking/stub-able),
`deps-2026-08-27.json` (in-tree vs external), `deps-census-2026-08-27.json`,
`dep-classes-2026-08-27.json`, `dep-pins-2026-08-27.tsv`.
