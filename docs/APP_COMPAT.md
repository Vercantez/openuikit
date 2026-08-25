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

## Re-measurement after the M12 merge (2026-08-25)

Re-run with all four M12 clusters merged (`Tools/apicensus/census-latest.json`).
The corpus also grew by one app — **pocket-casts-ios** (1,690 Swift files) —
so the headline number is reported both ways to keep the comparison honest.

**Like-for-like, same three apps, same 10,162 uses:**

| | before M12 | after M12 |
|---|---|---|
| distinct types implemented | 38 / 171 | **63 / 171** |
| frequency-weighted coverage | 70.2% | **85.4%** |

**+15.2 points** from the four clusters. OpenUIKit now exports 132 public type
names (was 82).

**Four-app corpus (16,343 uses), the number the command now prints:**

| | uses | share |
|---|---|---|
| **We implement it** | 13,572 | **83.0%** |
| Foundation provides free on Linux (`NSObject`, `NSString`, `NSCoder`, `NSValue`) | 704 | 4.3% |
| Out of scope (`UIStoryboard`, `UIStoryboardSegue`, `UIWebView`, `UINib`) | 211 | 1.3% |
| **Actual work remaining** | **1,856** | **11.4%** |

**Effective coverage: 88.5%.** The next cluster is unambiguous: after the
Foundation and storyboard/nib rows, the top of the punch list is
`UIBarButtonItem` (270 uses, all 4 apps) and the `UICollectionView` family
(~423 uses across 7 types, all 4 apps).

## The punch list, ordered by demand

| cluster | uses | notes |
|---|---|---|
| ~~**Attributed text**~~ | 560 | **DONE (M12).** `NSAttributedString` / `NSMutableAttributedString` / `NSParagraphStyle` / `UIFontDescriptor` are portable OpenUIKit types (they SHADOW Foundation's rather than bridging — docs/KNOWN_GAPS.md), with per-run layout and drawing in `AttributedTextLayout` and `attributedText` on `UILabel` / `UITextField` / `UITextView`. Six `attrtext_*` oracle fixtures. Still open: attributed truncation, attachments, underline patterns. |
| ~~**App lifecycle / environment**~~ | 543 | **DONE (M12).** `UIResponder` is the real base class with UIKit's exact chain; `UIApplication` + `UIApplicationDelegate` + a minimal scene layer; host-driven `UIScreen`; documented-fixed `UIDevice`. `openhost --app` boots through `UIApplicationMain` and a real app delegate. No run loop, so the host drives the transitions — docs/KNOWN_GAPS.md "App lifecycle / environment". |
| ~~**Alerts**~~ | ~~332~~ | **DONE (M12)** — `UIAlertController` + `UIAlertAction`, both styles, measured against real iOS 26.1 (`Tools/oracle2/alertprobe`); fixtures `alert_basic` / `alert_destructive` / `alert_actionsheet` / `alert_dark`. |
| **Collection view** | 212 | `UICollectionView`, cells, `UICollectionViewFlowLayout`, data source/delegate. Reuse machinery can follow `UITableView`'s. |
| **Bars & appearance** | 181 | `UIBarButtonItem`, `UIToolbar`, `UINavigationBarAppearance`, `UITabBarAppearance`. |
| **Misc controls** | 106 | `UIActivityIndicatorView`, `UISlider`, `UISegmentedControl`, `UIPageControl` **done** (oracle fixtures `control_activity` / `control_slider` / `control_segmented` / `control_pagecontrol` / `control_dark`); `UIRefreshControl`, `UISearchBar`, `UIStepper`, `UIPickerView` remain — see docs/KNOWN_GAPS.md for the measured head start on `UIStepper`. |
| ~~**Custom transitions**~~ | ~~64~~ | **DONE (M12)** — `UIPresentationController`, `UIViewControllerAnimatedTransitioning` + context + transitioning delegate, `UINavigationControllerDelegate`. The sheet presentation and push/pop now run through it (`_UIPageSheetAnimator` / `_UINavigationSlideAnimator`). No interactive transitioning — see docs/KNOWN_GAPS.md. |
| **Share sheet** | 57 | `UIActivityViewController` — system UI; likely a stub. |
| **Long tail** | 479 | 84 types: `UIKeyCommand`, `UIAction`, `UIMenu`, `UIPasteboard`, `UIPageViewController`, `UIContextMenuConfiguration`, … |

Also missing and cheap, not in the clusters above — **all four now done**
(2026-08-25):

- **Image loading**: `UIImage(named:)` / `(contentsOfFile:)` / `(data:)` with
  PNG+JPEG decode, `@2x`/`@3x` scale suffixes, `pngData()` /
  `jpegData(compressionQuality:)`. The decoder is the `stb_image` copy
  already vendored inside CQuartz, reached through an additive C API that
  hands over STRAIGHT (non-premultiplied) RGBA8
  (`patches/quartz/005-image-io-memory.patch`) — OpenUIKit contains no
  decoding code of its own. `UIImage(named:)` resolves against
  `OpenUIKitRuntime.imageSearchPaths`, empty by default: the library
  hardcodes no host paths.
- **`UIBezierPath`**: full construction/arcs/transforms plus
  `fill()`/`stroke()`/`addClip()` on the current context, backed by
  OpenCoreGraphics `Path`.
- **App-side drawing**: `UIView.draw(_ rect:)` (rendered through the
  existing layer-contents path, invalidated by `setNeedsDisplay()`),
  `UIGraphicsImageRenderer`, `UIGraphicsGetCurrentContext()` returning the
  `Canvas`, `UIColor.setFill()/setStroke()`.

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
