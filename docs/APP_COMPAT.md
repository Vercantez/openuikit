# App compatibility — measured, then prioritized

**Goal: run and test real UIKit apps on OpenUIKit instead of stock UIKit.**

This file replaces guesswork with a census. `Tools/apicensus/census.py` scans
real open-source UIKit apps, counts every UIKit symbol they reference, and
diffs against what OpenUIKit exports — so the roadmap is ordered by what apps
actually use, not by UIKit's alphabet.

**Where this stands at the M15 tip (2026-08-25):** **97.1% effective
coverage** of what four real apps reference, 474 uses (2.9%) of
genuinely-missing types left, and a *screen* from a shipping app rendering
with **99.2%** of its source unmodified (97.7% at M13; M15's Foundation
coexistence retired five of the fourteen adapted lines and M15's `@MainActor`
isolation retired four more). The file is written newest-last within
each topic; if you want only the current picture, read **"Current measurement
— M13 wrap-up, at the M14 tip"**, **"The punch list, re-ranked at the M14
tip"**, **"Missing MEMBERS of types we already export"** and
**"`@MainActor` isolation: shipped (M15)"**, then
docs/REAL_APP_TEST.md. Everything else is the record of how the number got
there, and the superseded sections are marked as such.

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

## Objective-C apps: a working facade (prototype)

The census counts Swift call sites, but the goal is "run real UIKit apps", and
some of them are Objective-C. A prototype facade — real ObjC `@interface`s over
a `@_cdecl` C ABI, no `@objc` anywhere — puts `UIView`, `UILabel`, `UIButton`
and `UIViewController` in reach of an Objective-C app on **Linux**, with ObjC
subclasses overriding `layoutSubviews`/`drawRect:` and dispatching
`@selector` target-action through the ObjC runtime. Its render is
byte-identical to the Swift equivalent's. Extrapolated cost of the full
facade, from this file's ranked type list: ~750 C entry points for the top 20
types (71% of all uses), ~2,200 for everything OpenUIKit exports — which is
why the recommendation is to generate it. Full report: **docs/OBJC_FACADE.md**.

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
- ~~**No notifications.**~~ **CLOSED by the controls2 cluster** (see the next
  section): OpenUIKit declares a portable `NotificationCenter` and posts the
  app-lifecycle notifications. The keyboard names are declared but nothing
  posts them — there is no system keyboard.

Also landed and cheap, outside the four clusters: `UIImage(named:/
contentsOfFile:/data:)` with PNG+JPEG decode via the `stb_image` copy already
inside CQuartz (`patches/quartz/005-image-io-memory.patch` — OpenUIKit
contains no decoding code of its own), `UIBezierPath`, and app-side drawing
(`UIView.draw(_:)`, `UIGraphicsImageRenderer`, `UIGraphicsGetCurrentContext()`,
`UIColor.setFill()/setStroke()`).

## Current measurement — after M13 (2026-08-25, all four clusters merged)

Four clusters shipped in M13 and are merged here: **collection view**,
**bars & appearance**, **menus & actions + delegate protocols**, and
**controls2**. Merged gates: `swift build` clean, **108/108 fixture scenes**
(96 → 108), **9/9 scroll traces**, **711 tests** (544 → 711), 0 failures.
`Sources/OpenUIKit` now declares **170** public `UI`/`NS`/`CA` type names
(111 at the M12 tip).

**Caveat on this re-measurement, stated up front:** the corpus is still not
vendored in this environment, so `Tools/apicensus/run.sh` could not re-scan
the apps. What was re-run is the half that does not need them — the `--ours`
list was regenerated from `Sources/OpenUIKit` at this merge commit and the
committed per-type use counts in `Tools/apicensus/census-latest.json` were
reclassified against it. Those counts are a property of the corpus and did
not change, so this reproduces `census.py`'s arithmetic exactly; only the
per-app file counts and the `missing_members_of_implemented` list are stale.
`census-latest.json` is therefore left as M12 wrote it — rerun the full
script with the checkouts to refresh it.

**Four-app corpus (16,343 uses, 220 distinct UIKit types referenced —
112 implemented, 108 missing):**

| | uses | share | was (M12) |
|---|---|---|---|
| **We implement it** | 14,829 | **90.7%** | 83.0% |
| Foundation provides free on Linux (`NSCoder` 379, `NSObject` 175, `NSString` 137, `NSValue` 13) | 704 | 4.3% | 4.3% |
| Out of scope (`UINib` 126, `UIStoryboard` 61, `UIStoryboardSegue` 22, `UIWebView` 2) | 211 | 1.3% | 1.3% |
| **Actual work remaining** | **599** | **3.7%** | 11.4% |

**Effective coverage: 96.3%** (was 88.5%). M13's four clusters moved **42
types and 1,257 uses** from `missing` to `implemented`, led by
`UIBarButtonItem` (270), `UICollectionView` (222),
`UIActivityViewController` (84), `UIKeyCommand` (81),
`UICollectionViewCell` (78) and `UIAction` (69).

What was left at that commit, ranked by how many apps need it:
`UIVisualEffectView` (20, 3 apps) + `UIBlurEffect` (12, 3) — the blur
divergence this file has carried since M12 — `UIApplicationShortcutItem`
(18, 3), the haptics generators (`UIImpactFeedbackGenerator` 15,
`UISelectionFeedbackGenerator` 7, both 3 apps and both trivially stubbable),
`NSTextAttachment` (13, 3), `UIViewControllerTransitionCoordinator` (7, 3),
then the two-app entries led by `UIFontMetrics` (66 — Dynamic Type),
`UIPasteboard` (32), `UIImagePickerController` (17), `NSItemProvider` (16)
and `UIPointerInteraction` (12).

> **Superseded.** `UIFontMetrics` and the Dynamic Type cluster shipped in M14.
> The current numbers and the current punch list are the next section.

## Current measurement — M13 wrap-up, at the M14 tip (2026-08-25)

Re-measured at `HEAD` on `master` with M13's four clusters *and* M14 merged.
`Sources/OpenUIKit` now declares **180** public `UI`/`NS`/`CA` type names
(170 at the M13 merge, 111 at M12, 63 before it).

**Same caveat as the M13 re-measurement, and for the same reason:** the four
app checkouts are not vendored in this environment, so `census.py` could not
re-scan them. What was regenerated from source is the `--ours` half — every
public `UI`/`NS`/`CA` type in `Sources/OpenUIKit` at this commit — and the
committed per-type use counts in `Tools/apicensus/census-latest.json` were
reclassified against it. Those counts are a property of the corpus and did
not change, so this reproduces `census.py`'s arithmetic exactly; only the
per-app file counts and `missing_members_of_implemented` are stale, and
`census-latest.json` is left as M12 wrote it.

**Four-app corpus (16,343 uses, 220 distinct UIKit types referenced —
116 implemented, 104 missing):**

| | uses | share | M13 merge | M12 |
|---|---|---|---|---|
| **We implement it** | 14,954 | **91.5%** | 90.7% | 83.0% |
| Foundation provides free on Linux (`NSCoder` 379, `NSObject` 175, `NSString` 137, `NSValue` 13) | 704 | 4.3% | 4.3% | 4.3% |
| Out of scope (`UINib` 126, `UIStoryboard` 61, `UIStoryboardSegue` 22, `UIWebView` 2) | 211 | 1.3% | 1.3% | 1.3% |
| **Actual work remaining** | **474** | **2.9%** | 3.7% | 11.4% |

**Effective coverage: 97.1%** (96.3% at the M13 merge, 88.5% at M12).

The +0.8 is M14's Dynamic Type cluster: four newly exported types are
referenced by the corpus — `UIFontMetrics` (66 uses, 2 apps),
`UITraitPreferredContentSizeCategory` (55), `UITraitHorizontalSizeClass` (2)
and `UITraitUserInterfaceStyle` (2) — **125 uses closed**. Six more
(`UIContentSizeCategory`, `UIAccessibilityTraits`, `UITraitDefinition`,
`UITraitChangeRegistration`, `UITraitDisplayScale`,
`UITraitVerticalSizeClass`) the corpus does not name, so they score zero here
while still being what makes the other four usable.

## The punch list, re-ranked at the M14 tip

Clustered from the **96 genuinely-missing types (474 uses)** left after
Foundation and the out-of-scope four are removed. "apps" is the largest
number of corpus apps any type in the cluster appears in.

The ranking rule is the census's own — **apps first, then uses** — because a
cluster at 0.2% of uses can still be the reason an app does not launch. Both
orderings are given, since they disagree sharply at the top now.

| # | cluster | uses | apps | notes |
|---|---|---|---|---|
| 1 | **Materials / blur (glass)** | 37 | 3 | `UIVisualEffectView` 20, `UIBlurEffect` 12, `UIGlassEffect` 3, `UIVisualEffect` 1, `UIVibrancyEffect` 1. The oldest open divergence in the project and **the single largest source of remaining pixel error**: every platter in the framework — alert card, sheet grabber, tab-bar platter, bar-button capsules, `UIPageControl` background — is a flat colour fitted over a neutral base. Correct on a flat backdrop (residual < 1.5 counts), wrong in hue over a saturated one. Closing it is a real backdrop-sampling blur in the compositor, not a type declaration. |
| 2 | **Home-screen shortcuts** | 31 | 3 | `UIApplicationShortcutItem` 18, `UIApplicationShortcutIcon` 8, `UIMutableApplicationShortcutItem` 5. Pure value types plus one `UIApplication` property; no pixels, no oracle needed. The cheapest three-app entry on the list. |
| 3 | **Haptics** | 30 | 3 | `UIImpactFeedbackGenerator` 15, `UINotificationFeedbackGenerator` 8, `UISelectionFeedbackGenerator` 7. No portable hardware to drive, so the honest shape is a no-op that records calls (and is therefore testable). Compile-blocker removal, nothing more. |
| 4 | **TextKit attachments** | 17 | 3 | `NSTextAttachment` 13, plus one-off `NSTextContainer` / `NSLayoutManager` / `NSTextStorage`. The first one is real work — an inline image box the data-driven text engine must lay out and the run painter must draw. The other three are TextKit-1 plumbing we deliberately do not have. |
| 5 | **Transition coordinator + interactive transitions** | 13 | 3 | `UIViewControllerTransitionCoordinator` 7, `UIPercentDrivenInteractiveTransition` 3, `UIViewControllerInteractiveTransitioning` 3. Sits directly on M12's presentation/transitioning API and M7.5's interactive back-swipe, both of which already exist; this is the public handle onto them. |

By **uses** instead, the two-app entries outrank items 2–5 and would reorder
the list: **drag & drop** (62 across 12 types — `UIDropSession` 11,
`UICollectionViewDropProposal` 11, `UIDragItem` 10, `UIDragSession` 8),
**pointer / hover** (33 across 4), `UIPasteboard` (32, a single type and no
system pasteboard to talk to off-device), **table extras** (31 — swipe
actions 17, diffable data sources 14), **system pickers** (25 —
`UIImagePickerController` 17, `UIDocumentPickerViewController` 4; system UI
we cannot reproduce, so a compiling stub that reports "unavailable"), and
`NSItemProvider` + activity items (18).

One-app clusters, in demand order: **cell content configuration** (26 —
`UIContentConfiguration` 18), `UIPageViewController` (22), **edit menu /
`UIMenuController`** (18), **compositional layout** (11 — the tail of the
shipped collection-view cluster), **search controller** (11 —
`UISearchController` 8, on top of the `UISearchBar` controls2 already
shipped), `UIPinchGestureRecognizer` (9), `UIViewPropertyAnimator` (7, 2
apps), `UISceneConfiguration` (5), `UIImageAsset` (5).

The unclustered tail is **24 types / 29 uses**, and every one of them appears
in exactly one app: five types at 2 references
(`UILocalizedIndexedCollation`, `UIPrintInteractionController`,
`UICollectionViewListCell`, `UIDropProposal`,
`UIDocumentInteractionControllerDelegate`) and nineteen at 1. At this point
the type census has very little left to say — which is itself the finding,
and the reason "Missing MEMBERS of types we already export" below and
docs/REAL_APP_TEST.md now matter more than anything in this table. The
largest single item anywhere in this document is not a type at all:
`UIView.setAnimationsEnabled` + `performWithoutAnimation`, **100 corpus
uses**, one global flag and one wrapper of work.

## What M13 shipped — collection view (2026-08-25)

The census's #1 cluster: **collection view** (498 uses across 23 types,
all four apps). `UICollectionView`, `UICollectionViewCell`,
`UICollectionReusableView`, `UICollectionViewLayout` +
`UICollectionViewFlowLayout`, `UICollectionViewLayoutAttributes` and the
`UICollectionViewDataSource` / `UICollectionViewDelegate` /
`UICollectionViewDelegateFlowLayout` trio — the last of which also clears
three of the "delegate protocols" cluster's 51 collection-view uses.

5 new fixture scenes: `collection_flow_grid`,
`collection_flow_lines`, `collection_sections`, `collection_horizontal`,
`collection_dark`. The flow layout's geometry was PROBED rather than guessed
(`scripts/flow_probe.sh`, 20 configurations against real UIKit) because two
of its rules are not derivable from the documentation — see docs/ROADMAP.md
(M13) and docs/KNOWN_GAPS.md.

The prerequisite the punch list called out was done first: the reuse
machinery moved out of `UITableView` into `Sources/OpenUIKit/UIReuse.swift`
and both containers now drive one implementation, with every `tableview_*`
fixture and table test unchanged as the regression bar.

Still open inside the cluster: `UICollectionViewCompositionalLayout`,
`NSCollectionLayoutSection` and `UICollectionViewDiffableDataSource`, plus
animated batch updates.

## What M13 shipped — menus & actions + delegate protocols (2026-08-25)

Clusters **#3 (menus & actions)** and most of **#4 (delegate protocols)**,
plus the share-sheet stub from **#5**.
The census is NOT re-run here (it needs the corpus checkouts), so the tables
above still show these as missing; what is measurable without the corpus is
the list of census symbols that move from `missing` to `implemented`, and
their `uses` column adds to **439** of the four-app corpus's 16,343:

| symbol | uses | symbol | uses |
|---|---|---|---|
| `UIActivityViewController` | 84 | `UIMenuElement` | 11 |
| `UIKeyCommand` | 81 | `UIPopoverPresentationControllerDelegate` | 10 |
| `UIAction` | 69 | `UIAdaptivePresentationControllerDelegate` | 9 |
| `UIMenu` | 49 | `UISearchBar` | 9 |
| `UIContextMenuConfiguration` | 23 | `UIActivityItemSource` | 9 |
| `UITextFieldDelegate` | 20 | `UITargetedPreview` | 6 |
| `UITextViewDelegate` | 15 | `UIPopoverPresentationController` | 6 |
| `UIGestureRecognizerDelegate` | 14 | `UISearchBarDelegate` | 3 |
| `UISheetPresentationControllerDelegate` | 14 | `UIContextMenuInteraction` (+delegate, +2 animating) | 6 |

Also added, outside the census's type list: `UICommand`,
`UIDeferredMenuElement`, `UIInteraction`, `UIControl.addAction(_:for:)`,
`UIButton(primaryAction:)` / `.menu` / `.showsMenuAsPrimaryAction` /
`performPrimaryAction()`, `UIResponder.keyCommands`,
`UIWindow.performKeyCommand(input:modifierFlags:)`, `UIActivity`,
`UIPopoverArrowDirection`, `UIModalPresentationStyle.popover`, and the
remaining `UIScrollViewDelegate` members (including a HONOURED
`scrollViewWillEndDragging` retarget).

Oracle status, stated plainly: the menu's geometry and colours are measured
by a new probe (`Tools/oracle2/menuprobe` + `scripts/menu_probe_sim.sh`,
17 configurations on real iOS 26.1), but **there is no fixture scene** —
iOS 26 draws the menu platter in the render server, where neither oracle can
capture it. The measurements are locked in by
`Tests/OpenUIKitTests/MenuTests.swift` instead, whose every expected number
comes from the probe. Full argument and the divergence list:
docs/KNOWN_GAPS.md "Menus, actions & delegate protocols".

Still missing from cluster #4 after this: the `UICollectionView` delegate /
data-source trio (owned by the collection-view cluster).

## What the "controls2" cluster shipped (2026-08-25, after M12)

The remaining controls plus the compile-blockers that are not types. **The
census was NOT re-run** (the corpus is not vendored and no checkout was
available in this environment), so no new coverage percentage is claimed
here; what follows is the list of punch-list entries this cluster closes,
with their four-app use counts from the table below.

| shipped | punch-list line it closes | uses |
|---|---|---|
| `NotificationCenter` + `Notification` + `Notification.Name` + `OperationQueue`, with the five app-lifecycle notifications actually POSTED | "the notification-name group", the largest genuinely-missing member group | ~90 |
| `UILayoutGuide` in the cassowary solver, `UIView.safeAreaInsets` / `safeAreaLayoutGuide` / `layoutMarginsGuide` / `readableContentGuide` / `layoutMargins` / `preservesSuperviewLayoutMargins`, `UIViewController.additionalSafeAreaInsets`, `safeAreaInsetsDidChange` | `safeAreaLayoutGuide`, the doc's own named example of "a missing MEMBER of a type we DO export" | in "virtually every modern constraint set" |
| `Timer` + `RunLoop` on the host clock (both the closure and the selector forms) | the `Timer.scheduledTimer(…selector:)` row of the selector table above — "not implemented" | — |
| `UIRefreshControl` with pull-to-refresh | tail entry | 12 |
| `UIStepper` | tail entry (metrics were already probed) | 22 |
| `UISearchBar` (+ `UISearchTextField`, `UISearchBarDelegate`) | the "search" tail cluster | 23 |
| `UIPickerView` (+ its data-source / delegate protocols) | tail entry | — |

Two new fixtures: `constraints_safearea` (100.0 %) and
`control_refresh` (99.4 %). Three of the four controls could NOT be goldened,
and the reasons are properties of the oracle rather than shortcuts — a
private material that `layer.render(in:)` draws as nothing (`UISearchBar`), a
SwiftUI hosting view that renders nothing at all (`UIStepper`), and a
`CAGradientLayer` that turns the whole capture into a translucent wash
(`UIPickerView`). Each is replaced by unit tests that replay real UIKit's own
numbers, and each is written up in docs/KNOWN_GAPS.md with the probe route
that would close it (the windowed oracle, which needs an active display
session, or a Simulator drag).

`UIDatePicker` was deferred and nothing was built: it is a formatter and a
calendar on top of the picker wheel, and both are Foundation. The wheel it
would sit on is now measured exactly.

Three of the newly declared types SHADOW Foundation's — `NotificationCenter`,
`Notification` and `Timer`, exactly like `NSAttributedString` before them.
An app importing both needs a one-line file-scope `typealias`;
docs/KNOWN_GAPS.md states the full tradeoff.

## The punch list as it stood at M12 — HISTORICAL

> **Superseded** by "The punch list, re-ranked at the M14 tip" above. Kept
> because it is the ranking M13's four clusters were *chosen* from, and the
> strike-throughs are the record of what closing them cost.

Clustered from the 150 missing types (1,856 uses). "apps" is the largest
number of corpus apps any type in the cluster appears in — a 4 means every app
needs it.

| # | cluster | uses | apps | notes |
|---|---|---|---|---|
| 1 | ~~**Collection view**~~ **SHIPPED (M13)** | 498 | 4 | `UICollectionView` 222, `UICollectionViewCell` 78, `UICollectionViewLayout` 41, `UICollectionViewFlowLayout` 30, data source/delegate 51 — all of that now exists. The reuse machinery was lifted out of `UITableView` into `Sources/OpenUIKit/UIReuse.swift` first, and both containers drive it. Still open in the TAIL of this cluster: `UICollectionViewCompositionalLayout`, `NSCollectionLayoutSection` and `UICollectionViewDiffableDataSource`, plus animated batch updates (docs/KNOWN_GAPS.md "UICollectionView"). |
| 2 | ~~**Bars & appearance** (6 types)~~ **SHIPPED (M13)** | ~~322~~ | 4 | `UIBarButtonItem`, `UINavigationItem`, `UIToolbar`, `UIBarAppearance` + the navigation-bar / toolbar / tab-bar subclasses, and `UIBarTitleTextAttributes`. See "What M13 shipped" below. |
| 3 | ~~**Menus & actions** (9 types)~~ **SHIPPED (M13)** | ~~252~~ | 2 | `UIKeyCommand` 81, `UIAction` 69, `UIMenu` 49, `UIContextMenuConfiguration` 23. Concentrated in two apps but dense there, and `UIAction` is how modern code-based UI wires buttons at all. |
| 4 | ~~**Delegate protocols** (14 types)~~ **SHIPPED (M13)** | ~~144~~ | 4 | `UITextFieldDelegate` 20, `UITextViewDelegate` 15, `UIGestureRecognizerDelegate` 14, the collection-view trio 51, the presentation-controller delegates 23. Mostly *declarations that do not exist yet* — an app fails to compile on the conformance before any behaviour is missing. Cheapest points on the list. |
| 5 | **Share / system UI** (5 types) | 130 | 3 | `UIActivityViewController` 84 **SHIPPED (M13, as a stub)**; `UIImagePickerController` 17 and `NSItemProvider` 16 still open. System UI we cannot reproduce; the honest shape is a compiling stub that reports "unavailable". |

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
The unclustered tail is 47 types / 199 uses. **`UIStepper` (22), the
"search" cluster (23), `UIRefreshControl` (12) and `UIPickerView` are now
IMPLEMENTED** — see "What the controls2 cluster shipped" below.

## Missing MEMBERS of types we already export — re-checked at the M14 tip

This is a separate 2,930-use pool, and the member scanner is noisier than the
type scanner: the top entries are `UILabel.lens` (297), `UIButton.lens` (217)
and `UIFont.ksr_*` — Kickstarter's own lens library and font extensions, not
UIKit at all. Filtering app-local extensions left ~477 uses of genuinely
missing members at M12. Each was re-checked against `Sources/OpenUIKit` at
this commit:

| member | uses | status at HEAD |
|---|---|---|
| `UIView.setAnimationsEnabled` | 92 | **still missing** — now the largest single gap in the pool, and a cheap one: a global flag the animation engine consults when opening a transaction |
| the notification-name group | ~90 | **closed** (controls2) — `NotificationCenter`, `Notification.Name` and the five posted app-lifecycle names |
| `systemLayoutSizeFitting` + `UIView.layoutFittingCompressedSize` | 24 | **closed** (M14, `UIViewCompat.swift` / `UIStackView.swift`) |
| `UIFont.preferredFont` | 21 | **closed** (M14, `UIFontMetrics.swift`) |
| `UIAppearance` proxies (`UINavigationBar.appearance` 11, `UITableView.appearance` 6) | 17 | **still missing** — needs a portable answer, sketched in docs/OBJC_RUNTIME.md |
| `UIView.addKeyframe` | 12 | **still missing** — keyframe animations |
| `UIView.performWithoutAnimation` | 8 | **still missing** — falls out of `setAnimationsEnabled` |
| `UIFont.monospacedDigitSystemFont` | 8 | **still missing** — needs the monospaced-digit metrics harvested |

So the member pool went from ~477 to ~**340** genuinely-missing uses, and
**`setAnimationsEnabled` + `performWithoutAnimation` (100 uses) is the single
best-value item left anywhere in this document** — larger than any missing
*type* cluster, and one flag plus one wrapper of work.

## Method notes / caveats

- The census is regex-based over Swift sources; it counts *type* references
  well and members roughly. It undercounts protocol conformances written
  indirectly and overcounts symbols in dead code.
- Type coverage ≠ API coverage. We may export `UIView` while missing members
  a given app needs (`safeAreaLayoutGuide` WAS the known example; the
  controls2 cluster implemented it). The
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

## Definition of done for this phase — REACHED at the screen level (M14)

A real, code-based open-source app compiles against OpenUIKit and renders its
first screen — headless via `openrender`, live via `openhost`, and identically
on Linux. Everything implemented on the way keeps its oracle fixtures, so
"runs real apps" never trades away "matches real UIKit."

**Outcome (2026-08-25). Full write-up: docs/REAL_APP_TEST.md.**

A screen from **Automattic/pocket-casts-ios** — its options-picker sheet,
four files, 605 lines — was vendored into `Sources/RealAppProbe` and compiled
against OpenUIKit. It renders headlessly (`openrender realapp`, three
configurations), live (`openhost --app pocketcasts`, with the app's own touch
handling, switch action and tap-to-dismiss driven by real touches), and
**byte-identically on Linux** (`scripts/linux_realapp_verify.sh`: 13/13 frames
across the headless renders and the scripted live replay).

**14 of the 605 lines had to change — 97.7 % unmodified** *(5 and 99.2 % after
M15 closed both the Foundation row and the `@MainActor` row — see "M15"
below)*, and the 258-line view controller (all of the Auto Layout) compiles
byte-for-byte. The ledger as first measured, by reason:
`NSCoder`/Foundation collision 5, `@MainActor` isolation 4, `#selector`/`@objc`
4, harness access level 1 — the first two rows are **0** after M15, leaving 5.
**None of the 14 was a missing UIKit member** — every one is a language or
runtime incompatibility.

The cost that does not show up in that ratio is the 246 lines of scaffolding
(the app's theme system re-expressed, a `SelectorDispatching` table, a `UIKit`
module alias) — see the report.

So the honest statement of where this stands:

- **rendering a real code-based screen: done**, for this class of screen;
- **compiling a whole app: not close**, and the reasons are now specific
  and ranked (docs/REAL_APP_TEST.md "Blocked on"): Foundation
  interoperability (`NSCoder` alone appears in 344 of the corpus's 5,099
  files), selector dispatch, ~~`@MainActor`~~ *(closed in M15)*, asset
  catalogs, xibs. Only the last is out of scope by choice.

The next milestone this suggests is **not** more UIKit types. It is
`import Foundation` alongside OpenUIKit, which would let an app's model layer,
theme system and string tables compile untouched.

## M15: Foundation coexistence — done (2026-08-25)

**`import Foundation` next to `import OpenUIKit` now compiles.** That was the
#1 item above and it is closed for the geometry types, `IndexPath`, `NSRange`
and `TimeInterval`, which is what unblocks `NSCoder` (344 files), `NSObject`
(175), `NSString` (137) and `NSValue` (13) — the 704 uses, **4.3 %** of the
corpus, that this table has been listing as "Foundation provides free on
Linux". They are free *now*; before M15 the file that wanted them could not
also mention a `CGRect`.

The insight was that the collision was never missing API — it was duplicate
NAMES — so the fix was subtraction. OpenUIKit stopped declaring rivals and
started re-exporting Foundation's own types (`typealias`, so lookup resolves
to one declaration), keeping UIKit's conveniences as extensions the way real
UIKit does. Design and the measured reasons: docs/PORTABILITY.md "M15: the
library imports Foundation, and there is exactly one `CGRect`".

**Evidence, not assertion:**

| | before | after |
|---|---|---|
| `private typealias X = OpenUIKit.X` lines in `Tests/` | 178 | **27** (151 deleted, across 40 files) |
| a test file that imports Foundation *and* uses UIKit geometry unqualified | impossible | `Tests/OpenUIKitTests/FoundationCoexistenceTests.swift` |
| oracle scenes / scroll traces / unit tests | 108 / 9 / 732 | 108 / 9 / **738** |
| Linux frames byte-identical to macOS | 162/162 | **162/162** |

**What did not move, and why** (each measured — details in
`Sources/OpenUIKit/FoundationTypes.swift`): `NSAttributedString`
(corelibs-Foundation *traps* when a plain Swift value is stored as an
attribute twice, and every UIKit attribute value is one), `NotificationCenter`
(no portable selector-form observer exists off Darwin, and that is the
spelling apps use most), `Timer`/`RunLoop` (they run on the scripted host
clock; Foundation's run on `Date`, which would end byte-identical rendering),
and `CGAffineTransform` (Linux Foundation has none, so keeping ours costs
nothing there — it clashes only on Darwin).

That leaves the remaining four blockers from the real-app ledger: selector
dispatch, `@MainActor`, asset catalogs, xibs.

Earlier blockers in the punch-list ordering — items 4, 2 and 1 (delegate
protocols, `UIBarButtonItem`, `UICollectionView`) — are all closed as of M13.

## What M13 shipped — bars & appearance (2026-08-25)

The whole #2 cluster, oracle-backed. **8 new exported types** and **5 new fixture
scenes**:

| type | corpus uses | notes |
|---|---|---|
| `UIBarButtonItem` | 270 | all five UIKit initializers (`title:style:target:action:`, `barButtonSystemItem:target:action:`, `image:style:target:action:`, `customView:`, plain), `isEnabled`, `tintColor`, `width`, `style`. Target-action goes through the M12 selector machinery, and the sender UIKit hands the action is the ITEM. |
| `UINavigationBarAppearance` | 33 | plus `UIBarAppearance`, `UIToolbarAppearance`, `UITabBarAppearance`, `UIBarTitleTextAttributes`. `configureWith{Default,Opaque,Transparent}Background`, `backgroundColor`, `shadowColor`, `titleTextAttributes`, `largeTitleTextAttributes`; wired to `standardAppearance` / `scrollEdgeAppearance` / `compactAppearance` on the bar AND per-item on `UINavigationItem`. |
| `UIToolbar` | 12 | `items`, `setItems(_:animated:)`, `barTintColor`, `tintColor`, `isTranslucent`, appearance objects; plus `UINavigationController.toolbar` / `isToolbarHidden` / `setToolbarHidden(_:animated:)` driven by the top controller's `toolbarItems`. |
| `UINavigationItem` | — | `title`, `titleView`, `prompt`, `left`/`rightBarButtonItem(s)` (+ the animated setters), `backBarButtonItem`, `backButtonTitle`, `hidesBackButton`, `largeTitleDisplayMode`, per-item appearances. Reachable as `UIViewController.navigationItem`, created lazily and seeded from `title` exactly like UIKit — which is how every real app configures a bar. |

Fixtures (all routed to real iOS in the Simulator through the new `"ios": true`
scene key — Mac Catalyst is not ground truth for iOS 26's glass bars):
`navitem_buttons` (leading + trailing items, a system item, a disabled item),
`navitem_titleview` (custom title view over a transparent bar),
`navitem_dark` (dark mode, a template-image item, a per-item tint),
`navbar_appearance` (opaque background + shadow hairline + custom title text
attributes), `toolbar_basic` (flexible and fixed spaces, two bars).

Two divergences are worth surfacing here because they change what an app sees
(full detail in docs/KNOWN_GAPS.md "Bars & appearance"):

- **Bar buttons are glass platters, and ours are flat.** Correct over a flat
  neutral backdrop (over white the platter is invisible apart from its
  measured shadow), wrong in hue over a saturated one — the same
  `UIVisualEffectView` gap the alert card and tab-bar platter already carry.
- **No SF Symbols.** Measured, only `.edit` and `.save` render as text on
  iOS 26 and are exact; `.done` is the prominent (tint-filled) checkmark and
  every other system item is a hand-fitted vector of the measured size. No
  golden gates those vectors.

One guessed constant was replaced by measurement: the inline navigation bar's
zone split was 20 + 44 with the title centred at y 42; real iOS 26 is 10 + 54
with the centre at **32**. `barHeight` stays 64, so nothing below the bar
moved.

## `@MainActor` isolation: shipped (M15, 2026-08-25)

Punch-list blocker **#3** in docs/REAL_APP_TEST.md, and the cheapest large win
on that list: `@MainActor` appears **641 times across 270** of the corpus's
5,099 Swift files, and the count only goes up as apps move toward the Swift 6
language mode, where main-actor isolation is the default expectation.

The problem was not that apps call something OpenUIKit lacks. It is that real
UIKit annotates its classes `@MainActor`, so an app can write

```swift
let action: @MainActor () -> Void        // and call it from a touch handler
@MainActor func reload() { tableView.reloadData() }
nonisolated func hashValue() -> Int
```

and have it type-check. Against classes with *no* isolation the same code is a
concurrency error — which is why 4 of the real-app harness's 14 changed lines
were annotations that had to be deleted rather than adapted.

**What is annotated now** mirrors the iOS SDK: `UIResponder` and every
subclass, `UIControl`, `UIGestureRecognizer`, `UIScreen`, `UIDevice`, the
touch/event types, the presentation and transitioning types, the bar-item and
bar-appearance types, the Auto Layout types, and **every delegate /
data-source protocol** (the SDK annotates those too, and it is forced anyway —
a `@MainActor` witness cannot satisfy a nonisolated requirement).

**What is deliberately left nonisolated** — because it is legal off the main
actor in real UIKit too, and because isolating it would constrain any future
threading of the renderer: all of `OpenCoreGraphics`, the glyph-run painter
(`UILabel.drawGlyphLine`/`drawGlyph`, spelled `nonisolated static`), the
Cassowary solver, the font engine, `UIColor`/`UIImage`/`UIFont`/
`UIBezierPath`/`UIGraphicsImageRenderer`, and the Foundation shapes
(`NSAttributedString`, `Timer`, `NotificationCenter`, …).

Two boundaries are crossed on purpose, both with `MainActor.assumeIsolated`
(a *checked* assertion that traps off-main) and never `nonisolated(unsafe)`:
timer/notification delivery to a `SelectorDispatching` target, and the
top-level code in each tool's `main.swift`. Full reasoning, the
strict-concurrency numbers and the measured zero perf cost are in
docs/KNOWN_GAPS.md "Actor isolation".

**Result for app source:** the harness's real-app ledger goes **14 changed
lines → 10**, 97.7 % → **98.3 %** unmodified, and the entire `@MainActor`
category disappears from it. Renders are unchanged: 108/108 scenes, 9/9 scroll
traces, 737 tests (5 new, `ActorIsolationTests`), 162/162 byte-identical
macOS-vs-Linux frames, and 13/13 for
the real-app screen.
