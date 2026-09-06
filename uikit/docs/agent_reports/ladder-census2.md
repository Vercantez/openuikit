# ladder-census2 — APP LADDER re-measure against current main

Measurement only. No `uikit/Sources` change. Corpus pins frozen at
`scratch/ladder-corpus/PINS.txt` (08-27). Dated outputs in
`full/ladder/*-2026-09-14.*` beside the baseline; the 08-27 files were not
overwritten. Full write-up: `full/ladder/APP_LADDER.md` §8.

## Before / after (route b)

| | 2026-08-27 | 2026-09-14 |
|---|---|---|
| OpenUIKit `UI*`/`NS*`/`CA*` types | 180 | **279** |
| Weighted UIKit coverage | 88.1 % | **94.1 %** |
| Effective coverage | 95.7 % | **98.0 %** |
| Gap uses | 4,925 | **2,312** |
| Blocking types / uses | 135 / 3,234 | **98 / 1,364** |
| Model ABSENT share | 10.8 % | **2.3 %** |
| Route (b) NEAR / MID / FAR | 2 / 6 / 12 | **3 / 6 / 11** |
| Route (a) NEAR / MID / FAR | 1 / 0 / 19 | **1 / 0 / 19** |

Band movers: **simplenote-ios MID → NEAR** (MOD 1→0, FW 2→0);
**WordPress-iOS FAR → MID** (MOD 3→2, FW 3→0). focus-ios 6→3, still the
only route-(a) NEAR. Every other `=B` drop is UIK/DEP/MOD/FW; UI/OBJC/NIB/
SIZE/NET/SEL did not move (pins frozen).

## What was enumerated

20 apps, 30 deps, 197 `coverage.tsv` (197/197 have ≥1 `implemented`; 0
missing `framework.json`), 76 HEAVY names (72 supplied; unsupplied:
`AppKit`, `MobileCoreServices`, `SystemConfiguration`, `WatchKit`), 737
SDK types, 279 OpenUIKit types, 41 guest Foundation files / 128 types, 55
§4 wall names.

## Method (ledgers as SUPPLY)

A coverage row counts as supplied **only** if status is `implemented`.
FW/MOD: a module is supplied iff ≥1 implemented identifier, or it is an
OpenUIKit package product. `UIKit`/`Foundation`/`SwiftUI` stay in the MOD
denominator; the SwiftUI-majority gate still fires. `dep_class.py`:
Combine import is no longer the wall; networking-bound is the unsupplied
URLSession remainder (`URLSessionDataTask` / `URLComponents` still
absent). Apollo, HAKit, Moya → Foundation-heavy; Alamofire stays
networking-bound.

## §4's 16 walls in `uikit/Sources`

Implemented (named type): coordinator, pasteboard, property animator, page
VC, compositional layout. Partial: blur (`UIGlassEffect` absent), haptics
(only `UIImpactFeedbackGenerator`), shortcuts (no mutable), diffable
(table yes, collection/swipe no), search (no delegate), scene (no
`UIOpenURLContext`). Absent: `NSItemProvider` in OpenUIKit (guest
Foundation has it), TextKit, pickers, `UIAccessibilityCustomAction`, drag &
drop.

## Next rungs (current 6 MID)

Signal `UIGlassEffect` 44; firefox `UICollectionViewListCell` 19; ios-oss
`UIPinchGestureRecognizer` 9; NetNewsWire `NSToolbarItem` 48; Telegram
`UIPinchGestureRecognizer` 34; WordPress `NSTextAttachment` 37.

## Pixel gates

Not re-run. No OpenUIKit source, no scene, no quartz change.
