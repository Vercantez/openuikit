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

## The punch list, ordered by demand

| cluster | uses | notes |
|---|---|---|
| **Attributed text** | 560 | `NSAttributedString` + rendering it: the *type* is Foundation, the *layout and drawing* are ours. Paragraph styles, attachments, `UIFontDescriptor`. Interacts with the text engine's harvested-ink model. |
| **App lifecycle / environment** | 543 | `UIApplication`, `UIApplicationDelegate`, `UIResponder` (a real base class + responder chain), `UIScreen`, `UIDevice`. Currently the host boots a "UIApplication-lite"; apps expect the real entry point. |
| **Alerts** | 332 | `UIAlertController` + `UIAlertAction` (alert and action-sheet styles). |
| **Collection view** | 212 | `UICollectionView`, cells, `UICollectionViewFlowLayout`, data source/delegate. Reuse machinery can follow `UITableView`'s. |
| **Bars & appearance** | 181 | `UIBarButtonItem`, `UIToolbar`, `UINavigationBarAppearance`, `UITabBarAppearance`. |
| **Misc controls** | 106 | `UIActivityIndicatorView`, `UISlider`, `UISegmentedControl`, `UIPageControl` **done** (oracle fixtures `control_activity` / `control_slider` / `control_segmented` / `control_pagecontrol` / `control_dark`); `UIRefreshControl`, `UISearchBar`, `UIStepper`, `UIPickerView` remain — see docs/KNOWN_GAPS.md for the measured head start on `UIStepper`. |
| **Custom transitions** | 64 | `UIViewControllerAnimatedTransitioning` + context/delegate, `UIPresentationController`. Our sheet/nav transitions should be re-expressed through this API. |
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
