# Measured UIKit blocking-type families

Follow-up: [triple-column display-mode resolution](uikit-blocking-types4.md)
closes the measured wider-mode state question; expanded rendering remains open.

Branch: `agent/uikit-blocking-types`. Measurements: 2026-09-07 (America/Chicago),
iOS 26.1 / 23B86. Census files retain the requested `2026-09-16` series suffix.

## Census result

| Metric | Before | After |
| --- | ---: | ---: |
| Blocking types | 66 | 54 |
| Blocking uses | 487 | 280 |
| Stub-able types | 40 | 39 |
| Stub-able uses | 143 | 138 |
| Genuine gap uses | 630 | 418 |
| Frequency-weighted UIKit coverage | 95.677883% | 95.860884% |
| Effective UIKit coverage | 99.456175% | 99.639176% |

Demand stays 20 apps, 25,371 Swift files, 361 distinct referenced types and
115,846 references. Thirteen missing declarations are supplied, covering
212 references (207 blocking, five stub-able). This is the existing textual
census's definition of coverage, not a claim that those apps launch or that
all members/rendering of these types are complete. Partial behavior below
remains open rather than being presented as full fidelity.

The highest-use remaining row, `NSToolbarItem` (85 uses), is Catalyst/macOS
demand and cannot be validated by the requested iOS simulator. In-flight
Simplenote, Focus browser and Hackers app sources were not changed.

## Measurements and implementation

| Family | Missing types / uses supplied | Real iOS observations and implemented rule |
| --- | ---: | --- |
| Swipe | 1 / 54 | SE @2x: direction bits 1/2/4/8; default right, one finger. Per-finger primary/secondary thresholds are `50*(1-.94*t)` / `50*(1-.98*t)`, with 24 ±0.001 pt boundary samples at t=0,.1,.2,.3,.4,.5. At .1 s thresholds are 45.3/45.1 pt; at .5 s 26.5/25.5. .500 s succeeds, .501 fails; zero opposite movement, discrete target action. |
| Split view | 2 / 54 | iPad A16 820×1180 @2x and SE 375×667 @2x: lazy assignment without premature child containment, legacy direct children vs modern navigation wrapping, SE column nesting/collapse, weak delegate and detail routing. Primary defaults 320 pt (legacy/double) / 280 (triple), supplementary 320; fraction .4×820=328, explicit min/max samples 400/300; SE column width 375. |
| Collection controller + invalidation | 3 / 26 | iPhone16 @3x: wrapper and collection [0,0,393,852], autoresizing 18, self delegates; replacement detaches old collection while controller retains initial layout. Nil before loading stays unloaded; nil after loading removes collection permanently until assigned again. First/return appearances clear selection after nonanimated willAppear or before animated didAppear. Contexts have false flags, nil lists and zero adjustments; deduplication preserves insertion order. Flow defaults true/true, bounds contexts suppress metrics and set attributes only for changed bounds. Offset (20,30)+(3,4)→(23,34), size (500,1200)+(10,20)→(510,1220), next layout restores (500,1200). |
| Coordinates | 1 / 14 | SE @2x: protocol conversions preserve nonzero bounds and 90° rotation. Custom NSObject spaces receive zero forwarded calls: (8,9)→(55,85), inverse (−39,−67), matching hierarchy-root conversion. Explicit cast branches avoid an Apple Swift 6.2.1 release optimizer ownership crash without changing compiler flags or semantics. |
| Edit menu | 4 / 50 | iPhone16 @3x: arrow values 0…4, opaque unique nil identifiers, copied mutable identifiers, unchanged fractional source points, weak ownership, DBL_MAX sentinel. Detached requests invoke no delegate; attached unsuccessful requests and reload query once. No successful presentation is fabricated. |
| Input view / audio capability | 2 / 14 | iPhone16 @3x: styles 0/1, frames 140×70 and 300×80 preserved, self-sizing false/true, intrinsic (−1,−1), fitting equals bounds. Absent optional click capability is disabled. No click playback or archive-decoding success is fabricated. |

Reproducible sources, raw transcripts and README limits are carried under
`Tools/oracle2/{swipeprobe,splitviewprobe,collectionblockingprobe,collectionlifecycleprobe,coordinatespaceprobe,editmenuprobe,inputviewprobe}`;
edit-menu/input-view JSON is under `fixtures/oracles/`. Each family has its
own simulator script and focused tests. Library constants cite those samples.

## Remaining behavioral limits

- Split's expanded floating-sidebar pixels, safe areas, backdrop/separator,
  inspector and interactive/adaptive behavior remain
  open. Wider triple-column display-mode resolution is measured in the follow-up
  linked above; column geometry remains open. The basic container is not asserted to match expanded iPad pixels.
- Edit-menu horizontal rendering, three private gestures, eight suggested
  system-menu groups and successful presentation/animation lifecycle remain
  unsupported. Descriptors and measured nonpresenting requests are supplied.
- Input keyboard presentation/material/self-sizing needs a host backend;
  audio remains silent, coder initialization fails closed.
- Collection self-sizing/partial cache updates, decoration layout, archive
  initialization, interactive reordering and layout-to-layout navigation
  remain open. Selection clearing is guarded by the iOS cut.
- Swipe does not add trackpad input. Coordinates cover UIView/custom-space
  conversion, not new UIScreen coordinate-space objects.

The unmatched rendering samples are also recorded in `scoreboard/open.txt`.
No score-fitting, golden edits, pin edits, package-resolution commits or
changes to the app ladder's classification/scoring rules were made.

## Census reproduction

From `uikit/`, run `scripts/blocking_types_census.sh /tmp/new-census-output`.
This reruns `full/ladder/remeasure-2026-09-16.sh` and all its census/classifier/
audit scripts. The original direct run reproduced the 630-use gap but exposed
ignored Simplenote probe files: manifests 1→3 and raw nib-walk Swift files
351→358 despite unchanged pinned HEAD. The wrapper checks out that frozen
HEAD into a temporary shared clone, symlinks the other unchanged repositories,
and uses `find -H` only to preserve normal directory traversal through those
command-line symlinks. It does not change filters, scores, counts or rubric.
The complete audit then passes: all 50 pins, non-UIKit demand, import/nib/SDK
invariants and model-band sums. Per-app deltas remain the instrument's
cumulative comparison against its 2026-09-14 baseline; this report's before
column is the original 2026-09-16 UIKit census. Only regenerated JSONs and
this follow-up row are changed under `full/ladder/`.

## Validation

- 82 focused/nearby tests pass, including 58 new-family tests and 24 existing
  collection behavior/reuse/flow tests.
- Six named collection scenes pass using fresh suite captures and
  `SKIP_CAPTURE=1 scripts/oracle_flow.sh /tmp/flow-uikit-blocking-types ...`.
- Catalyst: **124/124 before and after**.
- Fresh iOS 26.1 suite: **112/113 before and after**, every scene's numeric
  score unchanged. Sole existing miss: `corner_radius`, 99.411 vs 99.5.
  Baseline was rendered with the saved untouched release binary against the
  same fresh 113 simulator goldens; no stashing over other agents' work.
- All **14 scored real-app screens** have exactly the same scores before and
  after. The carried browser golden is absent in both runs, and is not counted
  as a new pass.
- Linux `swift:6.2-noble` release `openrender`: **pass**, final integrated
  build 215.04 s. Foundation-hidden guest compile: **pass**, 66 s,
  `GUEST_ROUTE_COMPILE_OK openuikit=146 opencoregraphics=12`.

Representative retained app scores: history 99.137; settings light/dark
98.535/98.548; storage 99.740; XS/XXXL/AX1 98.720/98.334/97.549; iPad
settings/history/storage 99.650/99.860/99.734; Focus settings/home
98.823/99.287; Hackers feed 94.662; Ledger 99.610.

The required merge-check proof uses `ALLOW_PATHS='^full/ladder/[^/]+\.json$|^full/ladder/APP_LADDER\.md$'` for the
user-authorized regenerated census files; the checker otherwise rejects
any path outside `uikit/`. No `ALLOW_DROP` or threshold override is used.
