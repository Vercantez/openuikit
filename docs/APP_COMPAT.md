# App compatibility — measured, then prioritized

**Goal: run and test real UIKit apps on OpenUIKit instead of stock UIKit.**

This file replaces guesswork with a census. `Tools/apicensus/census.py` scans
real open-source UIKit apps, counts every UIKit symbol they reference, and
diffs against what OpenUIKit exports — so the roadmap is ordered by what apps
actually use, not by UIKit's alphabet.

## Measurement (2026-08-25)

Corpus: three large production apps, all code-based or mostly code-based —
Artsy **eidolon** (159 Swift files), **DuckDuckGo iOS** (1,197), Kickstarter
**ios-oss** (2,053). 10,162 UIKit symbol references total.

Real UIKit's surface, for reference: **737 types** (530 ObjC classes + 208
protocols, counted from the SDK headers). OpenUIKit exports 44 of those names
— **6% by raw type count**. That number is misleading, and here is the number
that matters:

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

## The punch list, ordered by demand

| cluster | uses | notes |
|---|---|---|
| **Attributed text** | 560 | `NSAttributedString` + rendering it: the *type* is Foundation, the *layout and drawing* are ours. Paragraph styles, attachments, `UIFontDescriptor`. Interacts with the text engine's harvested-ink model. |
| **App lifecycle / environment** | 543 | `UIApplication`, `UIApplicationDelegate`, `UIResponder` (a real base class + responder chain), `UIScreen`, `UIDevice`. Currently the host boots a "UIApplication-lite"; apps expect the real entry point. |
| **Alerts** | 332 | `UIAlertController` + `UIAlertAction` (alert and action-sheet styles). |
| **Collection view** | 212 | `UICollectionView`, cells, `UICollectionViewFlowLayout`, data source/delegate. Reuse machinery can follow `UITableView`'s. |
| **Bars & appearance** | 181 | `UIBarButtonItem`, `UIToolbar`, `UINavigationBarAppearance`, `UITabBarAppearance`. |
| **Misc controls** | 106 | `UIActivityIndicatorView`, `UISlider`, `UISegmentedControl`, `UIRefreshControl`, `UISearchBar`, `UIPageControl`, `UIStepper`, `UIPickerView`. |
| **Custom transitions** | 64 | `UIViewControllerAnimatedTransitioning` + context/delegate, `UIPresentationController`. Our sheet/nav transitions should be re-expressed through this API. |
| **Share sheet** | 57 | `UIActivityViewController` — system UI; likely a stub. |
| **Long tail** | 479 | 84 types: `UIKeyCommand`, `UIAction`, `UIMenu`, `UIPasteboard`, `UIPageViewController`, `UIContextMenuConfiguration`, … |

Also missing and cheap, not in the clusters above: **`UIImage` cannot load a
file** (`UIImage(named:)`, PNG/JPEG decode). `stb_image` is already vendored
inside CQuartz, so this is mostly plumbing. **`UIBezierPath`** and app-side
drawing (`draw(_ rect:)`, `UIGraphicsImageRenderer`) are likewise thin
wrappers over machinery that already exists in quartz.

## Method notes / caveats

- The census is regex-based over Swift sources; it counts *type* references
  well and members roughly. It undercounts protocol conformances written
  indirectly and overcounts symbols in dead code.
- Type coverage ≠ API coverage. We may export `UIView` while missing members
  a given app needs (`safeAreaLayoutGuide` is a known example). The
  `missing_members_of_implemented` section of the census JSON tracks this and
  should be reviewed per cluster as it is implemented.
- The corpus skews toward large, older apps (one still uses `UIWebView`).
  Adding a couple of modern code-based apps would sharpen the ranking.

## Definition of done for this phase

A real, code-based open-source app compiles against OpenUIKit and renders its
first screen — headless via `openrender`, live via `openhost`, and identically
on Linux. Everything implemented on the way keeps its oracle fixtures, so
"runs real apps" never trades away "matches real UIKit."
