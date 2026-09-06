# Ladder census #3 — 2026-09-16

Measurement-only rerun at `a17b016727114d84ba851de57589aeb111d0b4be`, against the frozen 2026-09-14 artifacts. The requested suffix is 2026-09-16; the execution environment date is 2026-09-06.

## Before / after

| Measurement | 09-14 | 09-16 |
|---|---:|---:|
| OpenUIKit declaration names | 279 | 411 |
| Weighted UIKit coverage | 94.0619% | 95.6779% |
| Effective UIKit coverage | 98.0042% | 99.4562% |
| Genuine missing UIKit uses | 2,312 | 630 |
| Blocking types / uses | 98 / 1,364 | 66 / 487 |
| Stub-able types / uses | 76 / 948 | 40 / 143 |
| Model ABSENT uses | 2,983 | 1,033 |
| Model ABSENT share | 2.279% | 0.789% |
| Route (b) NEAR / MID / FAR | 3 / 6 / 11 | 3 / 6 / 11 |
| Route (a) NEAR / MID / FAR | 1 / 0 / 19 | 1 / 0 / 19 |

Nine apps improve one point: focus-ios, mastodon-ios, Signal-iOS, firefox-ios, NetNewsWire, WordPress-iOS, nextcloud-ios, pocket-casts-ios, wikipedia-ios. All changes are UIK; no band changes. Focus has zero remaining genuine UIKit gaps. Declaration coverage does not establish full browser functionality or a complete app build.

## Enumerated

20 pinned apps, 30 pinned dependencies; all 50 HEADs verified without fetch or clone. 25,371 UIKit-walk Swift files, 115,846 UIKit uses, 361 distinct demanded UIKit names; 737 SDK names, 411 OpenUIKit declarations (+132, no removals). All app non-UIKit demand, dependency non-UIKit demand, and full imports match the dated baseline. SDK/nib rows match after sorting.

208 coverage ledgers (197 before), all with implemented identifiers; 128,252 implemented identifiers (92,152 before). 27 existing ledgers changed status totals and 11 were added. 76 HEAVY names, 72 supplied; AppKit, MobileCoreServices, SystemConfiguration and WatchKit remain unsupplied. FW/MOD do not move: these buckets cannot see depth once a module has one implemented identifier.

41 guest Foundation manifest files / 154 textual declarations; 466 model-ledger names; 12 Combine/os product names. Audited 86 names directly in `uikit/Sources`: 77 declared, nine absent. All named types across the expanded 16 wall clusters are present, with behavioral/platform limits recorded per cluster. The nine supplemental absences: NSToolbarItem, UICollectionViewController, UICollectionViewLayoutInvalidationContext, UICoordinateSpace, UIEditMenuInteraction, UIScrollEdgeElementContainerInteraction, UISplitViewController, UISwipeGestureRecognizer, UITextItem.

## Model audit

Preserved the unchanged instrument's raw output. It falsely credits 2,453 uses to implemented ledger supply because NetworkCoder.Decoder / NetworkCoder.Encoder are associated types sharing Codable protocol names. A separate reviewed artifact records the precise surface/coverage rows and restores those uses to baseline IN-FLIGHT. Reviewed LEDGER-IMPLEMENTED remains 1,376; IN-FLIGHT remains 12,397. Model band totals reconcile to 130,883 in both raw and reviewed outputs.

Guest supply moves URLComponents (572) to GUEST-ORACLE, URLSession/query/authentication family (1,209) and keyed archivers (169) to GUEST-FOUNDATION, plus NSValue (608) from CF-BRIDGE-ONLY. Alamofire becomes Foundation-heavy rather than networking-bound; it is not load-bearing for any measured app, so no DEP score changes.

## Next rungs

All nine route-(b) NEAR/MID apps are covered in the prepared §9.6, with their top three remaining BLOCKING UIKit rows or an explicit fewer-than-three result. Focus, eidolon and simplenote have none; ios-oss has only UICollectionViewController (1 use). Their next steps concern actual build/resource/dependency/service boundaries. Remaining shared UIKit priorities are swipe recognition, collection-view controllers, split-view controllers and edit-menu interaction.

## Validation and delivery status

All instruments completed successfully. Checked pinned denominators, unchanged demand, score sums and both route distributions, gap conservation, model-band conservation, the source-name audit, and shell syntax. The declaration output also exactly matches the canonical apicensus regex. No Sources, scene, golden, package or runtime implementation changed. Pixel/simulator/Catalyst/real-app/Linux-build gates were not rerun for this measurement-only report, matching the prior ladder-census2 report; no build or pixel results are claimed.

The full §9 and dated artifact set are prepared in `/tmp/ladder-census3-2026-09-16/`; `/tmp/ladder-census3-full-ladder.patch` is the concrete proposed `full/ladder/` update. The requested `full/ladder/` destination conflicts with the brief's explicit ban on writes outside `uikit/`. Those changes have not been applied, committed, or pushed while that scope question is pending. Existing dated files remain unchanged.
