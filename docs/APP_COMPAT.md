# App compatibility — measured, then prioritized

**Goal: run and test real UIKit apps on OpenUIKit instead of stock UIKit.**

This file replaces guesswork with a census. `Tools/apicensus/census.py` scans
real open-source UIKit apps, counts every UIKit symbol they reference, and
diffs against what OpenUIKit exports — so the roadmap is ordered by what apps
actually use, not by UIKit's alphabet.

## Baseline measurement (2026-08-25, before M12)

Corpus: three large production apps, all code-based or mostly code-based —
Artsy **eidolon** (159 Swift files), **DuckDuckGo iOS** (1,197), Kickstarter
**ios-oss** (2,053). 10,162 UIKit symbol references total.

Real UIKit's surface, for reference: **737 types** (530 ObjC classes + 208
protocols, counted from the SDK headers). OpenUIKit exported 44 of *those*
names — **6% by raw type count**. (That 44 counts only names that also exist
in the SDK header list; the 63 quoted later in this file is the count of all
public `UI`/`NS`/`CA`-prefixed types OpenUIKit declares, which includes
internal-facing ones UIKit has no equivalent for. Two different questions, two
different methods — the later one is used consistently from here on.) The raw
type count is misleading either way, and here is the number that matters:

| | uses | share |
|---|---|---|
| **We implement it** | 7,133 | **70.2%** |
| Foundation provides free on Linux (`NSObject`, `NSString`, `NSCoder`, `NSValue`) | 400 | 3.9% |
| Out of scope (`UIStoryboard`, `UIStoryboardSegue`, `UIWebView`) | 95 | 0.9% |
| **Actual work remaining** | **2,534** | **24.9%** |

**Effective coverage: 74.8%** of what real apps touch, excluding storyboards
(a deliberate non-goal — code-based UI is the target) and counting Foundation
types that already exist off Darwin.

A small vocabulary does most of the work: apps reference ~171 distinct UIKit
types, not 737. That is why the punch list is tractable.

## Selector target-action: shipped (M12)

The census counted **~360 `#selector` uses** across the corpus and the earlier
verdict was that none of them were addressable off Darwin. That changed:
`UIControl.addTarget(_:action:for:)`, `removeTarget(_:action:for:)`,
`UIGestureRecognizer.init(target:action:)` and `addTarget(_:action:)` now
exist and work on **both** macOS and Linux, with no ObjC runtime and no
compiler flags. Full design, measurements and limits: docs/OBJC_RUNTIME.md.

Precisely how much of the ~360 that covers:

| where the selector goes | corpus share (approx.) | status |
|---|---|---|
| `UIControl.addTarget(_:action:for:)` | the large majority | **works, both platforms** |
| `UIGestureRecognizer(target:action:)` / `addTarget(_:action:)` | second largest | **works, both platforms** |
| `UIBarButtonItem(…target:action:)` | — | blocked on the type ("Bars & appearance", 181 uses) |
| `NotificationCenter.addObserver(_:selector:name:)` | — | blocked on the type ("App lifecycle", 543 uses) |
| `Timer.scheduledTimer(…selector:)` | — | not implemented |
| `UIAppearance`, KVO | — | not implemented (portable answers in docs/OBJC_RUNTIME.md) |

So the *dispatch mechanism* is no longer the blocker for any of them — the
remaining ones are blocked on their host types, and each becomes a one-line
addition once that type lands.

Two source-level costs remain, and they are the honest number:

1. **Every selector target writes a name → method table** (`ActionTable` +
   a two-line `SelectorDispatching` conformance, one line per action). Real
   UIKit needs none of it; without `objc_msgSend` nothing else can supply it,
   and this applies on macOS too because OpenUIKit's classes are not
   `NSObject` subclasses.
2. **On Linux `@objc` and `#selector` do not compile at all** (a Swift
   compiler/stdlib limitation, measured in docs/OBJC_RUNTIME.md). The
   portable spelling is `Selector.named("buttonTapped")`, which also compiles
   on Darwin — so one source can serve both platforms, at the cost of a
   mechanical `#selector(x)` → `Selector.named("x")` rewrite of those ~360
   sites and dropping `@objc`.

On macOS alone, `@objc func buttonTapped()` + `#selector(buttonTapped)` is
verbatim UIKit source; only a 1-argument action's sender must be retyped from
`UIButton` to `AnyObject`.

## Current measurement — after M12 (2026-08-25)

Re-run at the M12 tip with all four clusters merged
(`Tools/apicensus/census-latest.json`, reproduced from scratch at this commit;
the JSON and the tables below agree to the digit). The corpus also grew by one
app — **pocket-casts-ios** (1,690 Swift files) — so the headline is reported
both ways to keep the comparison honest.

**Like-for-like, same three apps, same 10,162 uses:**

| | before M12 | after M12 |
|---|---|---|
| distinct types implemented | 38 / 171 | **63 / 171** |
| frequency-weighted coverage | 70.2% | **85.4%** |

**+15.2 points** from the four clusters. Counting public `class`/`struct`/
`enum`/`protocol`/`typealias` declarations in `Sources/OpenUIKit` whose name
starts `UI`/`NS`/`CA`, OpenUIKit went from **63 to 111** exported UIKit-shaped
type names over the milestone.

**Four-app corpus (5,099 Swift files, 16,343 uses, 220 distinct UIKit types
referenced — 70 implemented, 150 missing), the number the command now prints:**

| | uses | share |
|---|---|---|
| **We implement it** | 13,572 | **83.0%** |
| Foundation provides free on Linux (`NSObject` 175, `NSString` 137, `NSCoder` 379, `NSValue` 13) | 704 | 4.3% |
| Out of scope (`UINib` 126, `UIStoryboard` 61, `UIStoryboardSegue` 22, `UIWebView` 2) | 211 | 1.3% |
| **Actual work remaining** | **1,856** | **11.4%** |

**Effective coverage: 88.5%.**

Reproduce with `Tools/apicensus/run.sh <dir-of-app-checkouts>`, which
regenerates **both** inputs from source rather than trusting a stale list —
the 737 SDK type names come from the Mac Catalyst UIKit headers, the 111
"ours" names from `Sources/OpenUIKit` — and rewrites
`Tools/apicensus/census-latest.json`. Verified 2026-08-25 to reproduce the
committed JSON byte-for-byte at this commit. The corpus is not vendored; clone
`artsy/eidolon`, `duckduckgo/iOS`, `kickstarter/ios-oss` and
`Automattic/pocket-casts-ios` into one directory.

## What M12 shipped

Four clusters, all merged on master, all oracle-backed. 15 new fixture scenes
(81 → **96**), 150 rendered frames.

"uses closed" is measured on the four-app corpus: the total references to
types that moved from `missing` to `implemented` between `d3ab657` and HEAD.
Together they account for **2,139 of the four-app corpus's 16,343 uses**
(+13.1 points), and for the whole of the 70.2 → 85.4 move on the shared
three-app corpus.

| cluster | uses closed | biggest types | fixtures |
|---|---|---|---|
| App lifecycle / environment | 805 | `UIApplication` 500, `UIDevice` 95, `UIScreen` 90, `UIResponder` 73 | (no pixel surface; `openhost --app` boots through `UIApplicationMain`) |
| Attributed text | 713 | `NSAttributedString` 591, `NSMutableAttributedString` 72, `UIFontDescriptor` 22 | `attrtext_runs` / `_paragraph` / `_kern_baseline` / `_underline_strike` / `_dark` / `_fields` |
| Alerts + custom transitions | 514 | `UIAlertController` 219, `UIAlertAction` 194, `UIPresentationController` 34 | `alert_basic` / `_destructive` / `_actionsheet` / `_dark` |
| Image / drawing / controls | 107 | `UIActivityIndicatorView` 74, `UIGraphicsImageRenderer` 16 | `control_activity` / `_slider` / `_segmented` / `_pagecontrol` / `_dark` |

(The four clusters were *chosen* on the three-app punch list, where they were
worth 560 / 543 / 396 / 106 uses. The table above is what they turned out to
be worth once pocket-casts-ios joined the corpus.)

Details per cluster are in docs/ROADMAP.md (M12) and the scope/divergence
notes in docs/KNOWN_GAPS.md. Three divergences are worth surfacing here
because they change what an app sees:

- **No `UIVisualEffectView`, so nothing blurs.** Alert cards, button pills,
  the sheet grabber, the tab-bar platter and the `UIPageControl` background
  are measured FLAT equivalents fitted over neutral bases. Correct on a flat
  backdrop (residual < 1.5 counts), wrong in hue over a saturated one.
- **`NSAttributedString` and friends SHADOW Foundation's types.** They are
  declared in OpenUIKit because the library imports no Foundation. An app that
  imports both needs a one-line file-scope `typealias` to disambiguate, and a
  Foundation attributed string cannot be handed to a `UILabel`.
- **No notifications.** `NotificationCenter` is Foundation. Apps that observe
  `UIApplication.didBecomeActiveNotification` or the keyboard notifications
  instead of implementing the delegate hear nothing — 90 uses in the corpus,
  the largest single missing-member group after app-local noise.

Also landed and cheap, outside the four clusters: `UIImage(named:/
contentsOfFile:/data:)` with PNG+JPEG decode via the `stb_image` copy already
inside CQuartz (`patches/quartz/005-image-io-memory.patch` — OpenUIKit
contains no decoding code of its own), `UIBezierPath`, and app-side drawing
(`UIView.draw(_:)`, `UIGraphicsImageRenderer`, `UIGraphicsGetCurrentContext()`,
`UIColor.setFill()/setStroke()`).

## The punch list, re-ranked on the four-app census

Clustered from the 150 missing types (1,856 uses). "apps" is the largest
number of corpus apps any type in the cluster appears in — a 4 means every app
needs it.

| # | cluster | uses | apps | notes |
|---|---|---|---|---|
| 1 | **Collection view** (23 types) | 498 | 4 | `UICollectionView` 222, `UICollectionViewCell` 78, `UICollectionViewLayout` 41, `UICollectionViewFlowLayout` 30, data source/delegate 51. Reuse machinery exists inside `UITableView` and must be lifted into a shared layer first (docs/KNOWN_GAPS.md). Compositional layout + diffable data source are in the tail of this cluster. |
| 2 | **Bars & appearance** (6 types) | 322 | 4 | `UIBarButtonItem` 270 — the single largest missing type after Foundation and nibs, and the one that makes `UINavigationItem` real. Then `UINavigationBarAppearance` 33, `UIToolbar` 12, `UITabBarAppearance`. Today the nav bar shows `vc.title` and a back button and nothing else. |
| 3 | **Menus & actions** (9 types) | 252 | 2 | `UIKeyCommand` 81, `UIAction` 69, `UIMenu` 49, `UIContextMenuConfiguration` 23. Concentrated in two apps but dense there, and `UIAction` is how modern code-based UI wires buttons at all. |
| 4 | **Delegate protocols** (14 types) | 144 | 4 | `UITextFieldDelegate` 20, `UITextViewDelegate` 15, `UIGestureRecognizerDelegate` 14, the collection-view trio 51, the presentation-controller delegates 23. Mostly *declarations that do not exist yet* — an app fails to compile on the conformance before any behaviour is missing. Cheapest points on the list. |
| 5 | **Share / system UI** (5 types) | 130 | 3 | `UIActivityViewController` 84, `UIImagePickerController` 17, `NSItemProvider` 16. System UI we cannot reproduce; the honest shape is a compiling stub that reports "unavailable". |

Below the top five, in demand order: **Dynamic Type** — `UIFontMetrics` (66)
plus `UITraitPreferredContentSizeCategory` (55, sitting in the unclustered
tail because it appears in only one app) plus the `UIFont.preferredFont`
member (21), together ~142 uses and arguably top-3 if counted as one cluster
— then **drag & drop** (65), **materials/blur** (34 — the fix for the
divergence above), **pointer/hover** (33), `UIPasteboard` (32), **haptics**
(30, trivially stubbable), **home-screen shortcuts** (26), **search** (23),
`UIPageViewController` (22), `UIStepper` (22 — metrics already probed,
docs/KNOWN_GAPS.md), **table extras** (swipe actions/diffable, 21), **TextKit
attachments** (17), **transition coordinator** (13), `UIRefreshControl` (12).
The unclustered tail is 47 types / 199 uses.

**Members of types we already have** are a separate 2,930-use pool, and the
member scanner is noisier than the type scanner: the top entries are
`UILabel.lens` (297), `UIButton.lens` (217) and `UIFont.ksr_*` — Kickstarter's
own lens library and font extensions, not UIKit at all. Filtering app-local
extensions leaves ~477 uses of genuinely missing members, led by
`UIView.setAnimationsEnabled` (92), the notification-name group (~90),
`UIFont.preferredFont` (21), `systemLayoutSizeFitting` +
`UIView.layoutFittingCompressedSize` (24), `UIView.addKeyframe` (12),
`UIAppearance` proxies (`UINavigationBar.appearance` 11, `UITableView.appearance` 6),
`UIView.performWithoutAnimation` (8) and `UIFont.monospacedDigitSystemFont` (8).

## Method notes / caveats

- The census is regex-based over Swift sources; it counts *type* references
  well and members roughly. It undercounts protocol conformances written
  indirectly and overcounts symbols in dead code.
- Type coverage ≠ API coverage. We may export `UIView` while missing members
  a given app needs (`safeAreaLayoutGuide` is a known example). The
  `missing_members_of_implemented` section of the census JSON tracks this and
  should be reviewed per cluster as it is implemented.
- **The member census does not distinguish UIKit members from app-defined
  extensions on UIKit types** (new caveat, 2026-08-25). Over half of that
  pool's 2,930 uses are one app's `lens`/`ksr_*` extensions. Any ranking built
  on member counts must be filtered against our own sources first, as the
  paragraph above does; the type counts are unaffected.
- The corpus skews toward large, older apps (one still uses `UIWebView`).
  Adding a couple of modern code-based apps would sharpen the ranking.
- Coverage is weighted by *reference count*, which rewards ubiquitous types
  (`UIView`, `UIColor`) over pivotal-but-rare ones. A cluster at 1% of uses
  can still be the reason an app does not launch. Read the punch list with
  the "apps" column, not only the "uses" column.

## Definition of done for this phase

A real, code-based open-source app compiles against OpenUIKit and renders its
first screen — headless via `openrender`, live via `openhost`, and identically
on Linux. Everything implemented on the way keeps its oracle fixtures, so
"runs real apps" never trades away "matches real UIKit."

Not reached yet: no corpus app compiles end to end. The blockers, in the order
they bite, are exactly items 4, 2 and 1 above — missing delegate protocols
(compile errors before anything runs), `UIBarButtonItem` (every screen's
chrome), and `UICollectionView`.
